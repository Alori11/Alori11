import { AlertType } from '@prisma/client';
import { prisma } from '../../config/database';
import { paginationMeta } from '../../utils/response';

export interface AlertsQueryOptions {
  page: number;
  limit: number;
  vehicleId?: string;
  type?: AlertType;
  read?: boolean;
}

class AlertsService {
  /**
   * List alerts for a user with pagination and filters
   */
  async listAlerts(userId: string, options: AlertsQueryOptions) {
    const { page, limit, vehicleId, type, read } = options;
    const skip = (page - 1) * limit;

    const where = {
      userId,
      ...(vehicleId && { vehicleId }),
      ...(type && { type }),
      ...(read !== undefined && { read }),
    };

    const [alerts, total] = await Promise.all([
      prisma.alert.findMany({
        where,
        include: {
          vehicle: {
            select: { id: true, make: true, model: true, plateNumber: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.alert.count({ where }),
    ]);

    return { alerts, meta: paginationMeta(total, page, limit) };
  }

  /**
   * Mark a single alert as read
   */
  async markAsRead(userId: string, alertId: string) {
    const alert = await prisma.alert.findFirst({
      where: { id: alertId, userId },
    });

    if (!alert) return null;

    return prisma.alert.update({
      where: { id: alertId },
      data: { read: true },
    });
  }

  /**
   * Mark all alerts as read (optionally filtered by vehicleId)
   */
  async markAllAsRead(userId: string, vehicleId?: string): Promise<number> {
    const result = await prisma.alert.updateMany({
      where: {
        userId,
        read: false,
        ...(vehicleId && { vehicleId }),
      },
      data: { read: true },
    });
    return result.count;
  }

  /**
   * Delete a specific alert
   */
  async deleteAlert(userId: string, alertId: string): Promise<boolean> {
    const alert = await prisma.alert.findFirst({
      where: { id: alertId, userId },
    });
    if (!alert) return false;

    await prisma.alert.delete({ where: { id: alertId } });
    return true;
  }

  /**
   * Delete all read alerts
   */
  async deleteReadAlerts(userId: string): Promise<number> {
    const result = await prisma.alert.deleteMany({
      where: { userId, read: true },
    });
    return result.count;
  }

  /**
   * Get unread alert count
   */
  async getUnreadCount(userId: string): Promise<number> {
    return prisma.alert.count({
      where: { userId, read: false },
    });
  }

  /**
   * Create an alert programmatically
   */
  async createAlert(
    userId: string,
    vehicleId: string | null,
    type: AlertType,
    message: string,
    metadata?: Record<string, unknown>
  ) {
    return prisma.alert.create({
      data: {
        userId,
        vehicleId,
        type,
        message,
        metadata,
      },
    });
  }
}

export const alertsService = new AlertsService();
