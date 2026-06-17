import { prisma } from '../../config/database';
import { whatsGPSService } from '../../services/whatsgps/whatsgps.service';
import { geofencingService } from '../geofencing/geofencing.service';
import { ForbiddenError, NotFoundError, AppError } from '../../middleware/error.middleware';
import { logger } from '../../utils/logger';
import { WhatsGPSLocation, WhatsGPSTrip } from '../../services/whatsgps/whatsgps.types';

export interface LiveLocationResponse {
  vehicleId: string;
  deviceId: string;
  imei: string;
  location: WhatsGPSLocation;
  vehicle: {
    make: string;
    model: string;
    plateNumber: string;
  };
}

class TrackingService {
  /**
   * Get live location for a vehicle
   */
  async getLiveLocation(userId: string, vehicleId: string): Promise<LiveLocationResponse> {
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
      include: {
        device: {
          select: { id: true, imei: true, status: true },
        },
      },
    });

    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');
    if (!vehicle.device) {
      throw new AppError('No GPS device is paired to this vehicle', 400);
    }

    const location = await whatsGPSService.getLocation(vehicle.device.imei);

    // Check geofences asynchronously (fire and forget)
    geofencingService
      .evaluateGeofences(userId, vehicleId, location.lat, location.lng)
      .catch((err) => logger.warn('Geofence evaluation error:', err));

    return {
      vehicleId,
      deviceId: vehicle.device.id,
      imei: vehicle.device.imei,
      location,
      vehicle: {
        make: vehicle.make,
        model: vehicle.model,
        plateNumber: vehicle.plateNumber,
      },
    };
  }

  /**
   * Get trip history for a vehicle
   */
  async getHistory(
    userId: string,
    vehicleId: string,
    from: Date,
    to: Date
  ): Promise<{ trips: WhatsGPSTrip[]; savedTrips: object[] }> {
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
      include: {
        device: { select: { imei: true } },
      },
    });

    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    // Validate date range (max 30 days)
    const diffMs = to.getTime() - from.getTime();
    const diffDays = diffMs / (1000 * 60 * 60 * 24);
    if (diffDays > 30) {
      throw new AppError('Date range cannot exceed 30 days', 400);
    }

    if (diffMs < 0) {
      throw new AppError('Start date must be before end date', 400);
    }

    // Fetch from WhatsGPS and from local DB in parallel
    const [liveTrips, savedTrips] = await Promise.all([
      vehicle.device
        ? whatsGPSService.getHistory(vehicle.device.imei, from, to).catch(() => [])
        : Promise.resolve([]),
      prisma.tripHistory.findMany({
        where: {
          vehicleId,
          startTime: { gte: from },
          endTime: { lte: to },
        },
        orderBy: { startTime: 'desc' },
      }),
    ]);

    // Persist new trips from WhatsGPS to local DB
    if (liveTrips.length > 0 && vehicle.device) {
      this.persistTrips(vehicleId, liveTrips).catch((err) =>
        logger.warn('Trip persistence error:', err)
      );
    }

    return { trips: liveTrips, savedTrips };
  }

  /**
   * Save WhatsGPS trips to local database
   * Uses createMany with skipDuplicates based on vehicleId + startTime uniqueness.
   * Duplicate detection is done by checking existing records first.
   */
  private async persistTrips(vehicleId: string, trips: WhatsGPSTrip[]): Promise<void> {
    const validTrips = trips.filter((t) => t.startTime && t.endTime);
    if (validTrips.length === 0) return;

    const startTimes = validTrips.map((t) => new Date(t.startTime));

    // Find existing trips to avoid duplicates
    const existing = await prisma.tripHistory.findMany({
      where: {
        vehicleId,
        startTime: { in: startTimes },
      },
      select: { startTime: true },
    });

    const existingTimes = new Set(existing.map((e) => e.startTime.toISOString()));

    const newTrips = validTrips.filter(
      (t) => !existingTimes.has(new Date(t.startTime).toISOString())
    );

    if (newTrips.length === 0) return;

    await prisma.tripHistory.createMany({
      data: newTrips.map((trip) => ({
        vehicleId,
        startTime: new Date(trip.startTime),
        endTime: new Date(trip.endTime),
        startLat: trip.startLat,
        startLng: trip.startLng,
        endLat: trip.endLat,
        endLng: trip.endLng,
        distance: trip.distance,
        duration: trip.duration,
        maxSpeed: trip.maxSpeed,
        avgSpeed: trip.avgSpeed,
      })),
      skipDuplicates: true,
    });

    logger.debug(`Persisted ${newTrips.length} new trips for vehicle ${vehicleId}`);
  }

  /**
   * Get last known location from local DB
   */
  async getLastKnownLocation(userId: string, vehicleId: string) {
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    const lastTrip = await prisma.tripHistory.findFirst({
      where: { vehicleId },
      orderBy: { startTime: 'desc' },
    });

    return lastTrip
      ? {
          lat: lastTrip.endLat ?? lastTrip.startLat,
          lng: lastTrip.endLng ?? lastTrip.startLng,
          timestamp: lastTrip.endTime ?? lastTrip.startTime,
          source: 'database',
        }
      : null;
  }
}

export const trackingService = new TrackingService();
