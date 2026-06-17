import { AlertType } from '@prisma/client';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { fcmService } from '../../services/fcm/fcm.service';
import { ForbiddenError, NotFoundError } from '../../middleware/error.middleware';
import { logger } from '../../utils/logger';
import type { CreateGeofenceDto, UpdateGeofenceDto } from './geofencing.schema';

const GEOFENCE_STATE_PREFIX = 'geofence:state:';

/**
 * Haversine formula to compute distance between two lat/lng points in meters
 */
function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371000; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lng2 - lng1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) ** 2 +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

class GeofencingService {
  /**
   * Create a geofence
   */
  async createGeofence(userId: string, dto: CreateGeofenceDto) {
    // Verify vehicle belongs to user
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: dto.vehicleId },
    });
    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    return prisma.geofence.create({
      data: {
        userId,
        vehicleId: dto.vehicleId,
        name: dto.name,
        lat: dto.lat,
        lng: dto.lng,
        radius: dto.radius,
        active: dto.active,
      },
    });
  }

  /**
   * List geofences (all for user, or filtered by vehicle)
   */
  async listGeofences(userId: string, vehicleId?: string) {
    return prisma.geofence.findMany({
      where: {
        userId,
        ...(vehicleId && { vehicleId }),
      },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get geofence by ID
   */
  async getGeofence(userId: string, geofenceId: string) {
    const geofence = await prisma.geofence.findUnique({
      where: { id: geofenceId },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true },
        },
      },
    });

    if (!geofence) throw new NotFoundError('Geofence');
    if (geofence.userId !== userId) throw new ForbiddenError('Access denied');

    return geofence;
  }

  /**
   * Update a geofence
   */
  async updateGeofence(userId: string, geofenceId: string, dto: UpdateGeofenceDto) {
    const geofence = await prisma.geofence.findUnique({ where: { id: geofenceId } });
    if (!geofence) throw new NotFoundError('Geofence');
    if (geofence.userId !== userId) throw new ForbiddenError('Access denied');

    return prisma.geofence.update({
      where: { id: geofenceId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.lat !== undefined && { lat: dto.lat }),
        ...(dto.lng !== undefined && { lng: dto.lng }),
        ...(dto.radius !== undefined && { radius: dto.radius }),
        ...(dto.active !== undefined && { active: dto.active }),
      },
    });
  }

  /**
   * Delete a geofence
   */
  async deleteGeofence(userId: string, geofenceId: string): Promise<void> {
    const geofence = await prisma.geofence.findUnique({ where: { id: geofenceId } });
    if (!geofence) throw new NotFoundError('Geofence');
    if (geofence.userId !== userId) throw new ForbiddenError('Access denied');

    await prisma.geofence.delete({ where: { id: geofenceId } });
    // Clean up state cache
    await redis.del(`${GEOFENCE_STATE_PREFIX}${geofenceId}`);
  }

  /**
   * Evaluate all active geofences for a vehicle's current position
   * Creates alerts and sends push notifications on enter/exit events
   */
  async evaluateGeofences(
    userId: string,
    vehicleId: string,
    currentLat: number,
    currentLng: number
  ): Promise<void> {
    const geofences = await prisma.geofence.findMany({
      where: { userId, vehicleId, active: true },
    });

    if (geofences.length === 0) return;

    // Get user's FCM token for notifications
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });

    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
      select: { make: true, model: true, plateNumber: true },
    });

    await Promise.all(
      geofences.map(async (geofence) => {
        const distance = haversineDistance(
          currentLat,
          currentLng,
          geofence.lat,
          geofence.lng
        );

        const isInside = distance <= geofence.radius;
        const stateKey = `${GEOFENCE_STATE_PREFIX}${geofence.id}`;

        // Get previous state
        const previousState = await redis.get(stateKey);
        const wasInside = previousState === 'inside';

        // Store current state
        await redis.set(stateKey, isInside ? 'inside' : 'outside', 300);

        // Detect transitions
        if (isInside && !wasInside) {
          // Entered geofence
          await this.createGeofenceAlert(
            userId,
            vehicleId,
            geofence.name,
            AlertType.GEOFENCE_ENTER,
            vehicle,
            user?.fcmToken
          );
        } else if (!isInside && wasInside) {
          // Exited geofence
          await this.createGeofenceAlert(
            userId,
            vehicleId,
            geofence.name,
            AlertType.GEOFENCE_EXIT,
            vehicle,
            user?.fcmToken
          );
        }
      })
    );
  }

  private async createGeofenceAlert(
    userId: string,
    vehicleId: string,
    geofenceName: string,
    type: AlertType,
    vehicle: { make: string; model: string; plateNumber: string } | null,
    fcmToken?: string | null
  ): Promise<void> {
    const vehicleLabel = vehicle
      ? `${vehicle.make} ${vehicle.model} (${vehicle.plateNumber})`
      : 'Your vehicle';

    const action = type === AlertType.GEOFENCE_ENTER ? 'entered' : 'exited';
    const message = `${vehicleLabel} has ${action} geofence: ${geofenceName}`;

    await prisma.alert.create({
      data: {
        userId,
        vehicleId,
        type,
        message,
        metadata: { geofenceName, action },
      },
    });

    // Send push notification
    if (fcmToken) {
      await fcmService
        .sendToDevice(
          fcmToken,
          { title: 'Geofence Alert', body: message },
          { type, vehicleId, geofenceName }
        )
        .catch((err) => logger.warn('FCM send failed:', err));
    }

    logger.info(`Geofence alert created: ${type} for vehicle ${vehicleId}`);
  }
}

export const geofencingService = new GeofencingService();
