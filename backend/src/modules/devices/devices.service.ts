import { DeviceStatus } from '@prisma/client';
import { prisma } from '../../config/database';
import { whatsGPSService } from '../../services/whatsgps/whatsgps.service';
import {
  AppError,
  ConflictError,
  NotFoundError,
  ForbiddenError,
} from '../../middleware/error.middleware';
import { logger } from '../../utils/logger';
import type { PairDeviceDto, UpdateDeviceDto } from './devices.schema';

class DevicesService {
  /**
   * Pair a GPS device to the user's account by IMEI
   */
  async pairDevice(userId: string, dto: PairDeviceDto) {
    // Check if IMEI already registered
    const existing = await prisma.device.findUnique({
      where: { imei: dto.imei },
    });

    if (existing) {
      if (existing.userId === userId) {
        throw new ConflictError('This device is already paired to your account');
      }
      throw new ConflictError('This device IMEI is already registered to another account');
    }

    // Validate IMEI with WhatsGPS
    const isValidIMEI = await whatsGPSService.validateIMEI(dto.imei);
    if (!isValidIMEI) {
      throw new AppError('Device IMEI not found in tracking system. Please verify the IMEI.', 400);
    }

    // Fetch device info from WhatsGPS
    let deviceInfo;
    try {
      deviceInfo = await whatsGPSService.getDeviceByIMEI(dto.imei);
    } catch {
      // Proceed with basic info if detailed fetch fails
      deviceInfo = null;
    }

    const device = await prisma.device.create({
      data: {
        imei: dto.imei,
        name: dto.name || deviceInfo?.name || `Device ${dto.imei.slice(-4)}`,
        userId,
        status: deviceInfo?.status === 'online' ? DeviceStatus.ACTIVE : DeviceStatus.INACTIVE,
        signal: deviceInfo?.signal,
        battery: deviceInfo?.battery,
        lastSeen: deviceInfo?.lastUpdate ? new Date(deviceInfo.lastUpdate) : null,
      },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true },
        },
      },
    });

    logger.info(`Device paired: IMEI=${dto.imei}, userId=${userId}`);
    return device;
  }

  /**
   * Unpair/remove a device from user's account
   */
  async unpairDevice(userId: string, deviceId: string): Promise<void> {
    const device = await prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) throw new NotFoundError('Device');
    if (device.userId !== userId) throw new ForbiddenError('Access denied');

    await prisma.device.delete({ where: { id: deviceId } });
    logger.info(`Device unpaired: id=${deviceId}, userId=${userId}`);
  }

  /**
   * List all devices belonging to the user
   */
  async listUserDevices(userId: string) {
    const devices = await prisma.device.findMany({
      where: { userId },
      include: {
        vehicle: {
          select: {
            id: true,
            make: true,
            model: true,
            year: true,
            plateNumber: true,
            color: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Enrich with live status from WhatsGPS (best effort)
    const enriched = await Promise.all(
      devices.map(async (device) => {
        try {
          const status = await whatsGPSService.getDeviceStatus(device.imei);
          return {
            ...device,
            liveStatus: {
              online: status.online,
              signal: status.signal,
              battery: status.battery,
              lastSeen: status.lastSeen,
            },
          };
        } catch {
          return {
            ...device,
            liveStatus: null,
          };
        }
      })
    );

    return enriched;
  }

  /**
   * Get a single device by ID (must belong to user)
   */
  async getDevice(userId: string, deviceId: string) {
    const device = await prisma.device.findUnique({
      where: { id: deviceId },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true, color: true },
        },
      },
    });

    if (!device) throw new NotFoundError('Device');
    if (device.userId !== userId) throw new ForbiddenError('Access denied');

    // Get live status
    let liveStatus = null;
    try {
      liveStatus = await whatsGPSService.getDeviceStatus(device.imei);
    } catch {
      // Non-critical
    }

    // Sync status in background
    if (liveStatus) {
      prisma.device
        .update({
          where: { id: deviceId },
          data: {
            status: liveStatus.online ? DeviceStatus.ACTIVE : DeviceStatus.INACTIVE,
            signal: liveStatus.signal,
            battery: liveStatus.battery ?? null,
            lastSeen: new Date(liveStatus.lastSeen),
          },
        })
        .catch((err) => logger.warn('Failed to sync device status:', err));
    }

    return { ...device, liveStatus };
  }

  /**
   * Update device details
   */
  async updateDevice(userId: string, deviceId: string, dto: UpdateDeviceDto) {
    const device = await prisma.device.findUnique({ where: { id: deviceId } });
    if (!device) throw new NotFoundError('Device');
    if (device.userId !== userId) throw new ForbiddenError('Access denied');

    if (dto.vehicleId) {
      const vehicle = await prisma.vehicle.findUnique({
        where: { id: dto.vehicleId },
      });
      if (!vehicle || vehicle.userId !== userId) {
        throw new AppError('Vehicle not found or access denied', 404);
      }
    }

    return prisma.device.update({
      where: { id: deviceId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.vehicleId !== undefined && { vehicleId: dto.vehicleId }),
      },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true },
        },
      },
    });
  }
}

export const devicesService = new DevicesService();
