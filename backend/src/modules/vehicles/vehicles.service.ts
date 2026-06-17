import { prisma } from '../../config/database';
import {
  AppError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../middleware/error.middleware';
import { logger } from '../../utils/logger';
import type { CreateVehicleDto, UpdateVehicleDto } from './vehicles.schema';

class VehiclesService {
  /**
   * Create a new vehicle for the user
   */
  async createVehicle(userId: string, dto: CreateVehicleDto) {
    // Check for duplicate plate number for this user
    const existingPlate = await prisma.vehicle.findFirst({
      where: { userId, plateNumber: dto.plateNumber },
    });

    if (existingPlate) {
      throw new ConflictError(`Vehicle with plate ${dto.plateNumber} already exists`);
    }

    // If deviceId provided, verify it belongs to user and is unassigned
    if (dto.deviceId) {
      const device = await prisma.device.findUnique({
        where: { id: dto.deviceId },
      });

      if (!device) throw new NotFoundError('Device');
      if (device.userId !== userId) throw new ForbiddenError('Device not owned by user');
      if (device.vehicleId) {
        throw new ConflictError('Device is already assigned to another vehicle');
      }
    }

    const vehicle = await prisma.vehicle.create({
      data: {
        make: dto.make,
        model: dto.model,
        year: dto.year,
        plateNumber: dto.plateNumber,
        color: dto.color,
        userId,
        ...(dto.deviceId && {
          device: { connect: { id: dto.deviceId } },
        }),
      },
      include: {
        device: {
          select: {
            id: true,
            imei: true,
            name: true,
            status: true,
            signal: true,
            battery: true,
            lastSeen: true,
          },
        },
      },
    });

    logger.info(`Vehicle created: id=${vehicle.id}, userId=${userId}`);
    return vehicle;
  }

  /**
   * Get all vehicles for a user
   */
  async listUserVehicles(userId: string) {
    return prisma.vehicle.findMany({
      where: { userId },
      include: {
        device: {
          select: {
            id: true,
            imei: true,
            name: true,
            status: true,
            signal: true,
            battery: true,
            lastSeen: true,
          },
        },
        _count: {
          select: {
            maintenanceRecords: true,
            alerts: { where: { read: false } },
            trips: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get single vehicle by ID
   */
  async getVehicle(userId: string, vehicleId: string) {
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
      include: {
        device: {
          select: {
            id: true,
            imei: true,
            name: true,
            status: true,
            signal: true,
            battery: true,
            lastSeen: true,
          },
        },
        geofences: {
          select: { id: true, name: true, active: true },
        },
        _count: {
          select: {
            maintenanceRecords: true,
            alerts: true,
            trips: true,
          },
        },
      },
    });

    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    return vehicle;
  }

  /**
   * Update a vehicle
   */
  async updateVehicle(userId: string, vehicleId: string, dto: UpdateVehicleDto) {
    const vehicle = await prisma.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    if (dto.plateNumber && dto.plateNumber !== vehicle.plateNumber) {
      const existingPlate = await prisma.vehicle.findFirst({
        where: { userId, plateNumber: dto.plateNumber, NOT: { id: vehicleId } },
      });
      if (existingPlate) {
        throw new ConflictError(`Vehicle with plate ${dto.plateNumber} already exists`);
      }
    }

    // Handle device assignment change
    if (dto.deviceId !== undefined) {
      if (dto.deviceId) {
        const device = await prisma.device.findUnique({ where: { id: dto.deviceId } });
        if (!device) throw new NotFoundError('Device');
        if (device.userId !== userId) throw new ForbiddenError('Device not owned by user');
        if (device.vehicleId && device.vehicleId !== vehicleId) {
          throw new ConflictError('Device is already assigned to another vehicle');
        }
      }
    }

    return prisma.vehicle.update({
      where: { id: vehicleId },
      data: {
        ...(dto.make && { make: dto.make }),
        ...(dto.model && { model: dto.model }),
        ...(dto.year && { year: dto.year }),
        ...(dto.plateNumber && { plateNumber: dto.plateNumber }),
        ...(dto.color !== undefined && { color: dto.color }),
        ...(dto.deviceId !== undefined && {
          device: dto.deviceId
            ? { connect: { id: dto.deviceId } }
            : { disconnect: true },
        }),
      },
      include: {
        device: {
          select: { id: true, imei: true, name: true, status: true },
        },
      },
    });
  }

  /**
   * Delete a vehicle
   */
  async deleteVehicle(userId: string, vehicleId: string): Promise<void> {
    const vehicle = await prisma.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    await prisma.vehicle.delete({ where: { id: vehicleId } });
    logger.info(`Vehicle deleted: id=${vehicleId}, userId=${userId}`);
  }
}

export const vehiclesService = new VehiclesService();
