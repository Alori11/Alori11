import { prisma } from '../../config/database';
import { ForbiddenError, NotFoundError } from '../../middleware/error.middleware';
import { paginationMeta } from '../../utils/response';
import { logger } from '../../utils/logger';
import type {
  CreateMaintenanceDto,
  UpdateMaintenanceDto,
  MaintenanceQueryDto,
} from './maintenance.schema';

class MaintenanceService {
  /**
   * Create a maintenance record
   */
  async createRecord(userId: string, dto: CreateMaintenanceDto) {
    // Verify vehicle belongs to user
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: dto.vehicleId },
      select: { id: true, userId: true },
    });
    if (!vehicle) throw new NotFoundError('Vehicle');
    if (vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    const record = await prisma.maintenanceRecord.create({
      data: {
        vehicleId: dto.vehicleId,
        type: dto.type,
        date: new Date(dto.date),
        mileage: dto.mileage,
        notes: dto.notes,
        cost: dto.cost,
        nextDueDate: dto.nextDueDate ? new Date(dto.nextDueDate) : null,
        nextDueMileage: dto.nextDueMileage,
      },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true },
        },
      },
    });

    logger.info(`Maintenance record created: vehicleId=${dto.vehicleId}, type=${dto.type}`);
    return record;
  }

  /**
   * List maintenance records for user's vehicles
   */
  async listRecords(userId: string, query: MaintenanceQueryDto) {
    const { vehicleId, type, upcoming, page, limit } = query;
    const skip = (page - 1) * limit;

    // Base condition: must belong to user
    const vehicleWhere = {
      userId,
      ...(vehicleId && { id: vehicleId }),
    };

    const userVehicleIds = await prisma.vehicle
      .findMany({
        where: vehicleWhere,
        select: { id: true },
      })
      .then((v) => v.map((x) => x.id));

    const now = new Date();
    const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const where = {
      vehicleId: { in: userVehicleIds },
      ...(type && { type }),
      ...(upcoming && {
        OR: [
          { nextDueDate: { lte: thirtyDaysFromNow } },
          { nextDueMileage: { not: null } },
        ],
      }),
    };

    const [records, total] = await Promise.all([
      prisma.maintenanceRecord.findMany({
        where,
        include: {
          vehicle: {
            select: { id: true, make: true, model: true, plateNumber: true },
          },
        },
        orderBy: { date: 'desc' },
        skip,
        take: limit,
      }),
      prisma.maintenanceRecord.count({ where }),
    ]);

    return { records, meta: paginationMeta(total, page, limit) };
  }

  /**
   * Get a single maintenance record
   */
  async getRecord(userId: string, recordId: string) {
    const record = await prisma.maintenanceRecord.findUnique({
      where: { id: recordId },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true, userId: true },
        },
      },
    });

    if (!record) throw new NotFoundError('Maintenance record');
    if (record.vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    return record;
  }

  /**
   * Update a maintenance record
   */
  async updateRecord(userId: string, recordId: string, dto: UpdateMaintenanceDto) {
    const record = await prisma.maintenanceRecord.findUnique({
      where: { id: recordId },
      include: { vehicle: { select: { userId: true } } },
    });

    if (!record) throw new NotFoundError('Maintenance record');
    if (record.vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    return prisma.maintenanceRecord.update({
      where: { id: recordId },
      data: {
        ...(dto.type && { type: dto.type }),
        ...(dto.date && { date: new Date(dto.date) }),
        ...(dto.mileage !== undefined && { mileage: dto.mileage }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(dto.cost !== undefined && { cost: dto.cost }),
        ...(dto.nextDueDate !== undefined && {
          nextDueDate: dto.nextDueDate ? new Date(dto.nextDueDate) : null,
        }),
        ...(dto.nextDueMileage !== undefined && { nextDueMileage: dto.nextDueMileage }),
      },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true },
        },
      },
    });
  }

  /**
   * Delete a maintenance record
   */
  async deleteRecord(userId: string, recordId: string): Promise<void> {
    const record = await prisma.maintenanceRecord.findUnique({
      where: { id: recordId },
      include: { vehicle: { select: { userId: true } } },
    });

    if (!record) throw new NotFoundError('Maintenance record');
    if (record.vehicle.userId !== userId) throw new ForbiddenError('Access denied');

    await prisma.maintenanceRecord.delete({ where: { id: recordId } });
  }

  /**
   * Get upcoming/overdue maintenance across all user vehicles
   */
  async getUpcomingMaintenance(userId: string) {
    const vehicles = await prisma.vehicle.findMany({
      where: { userId },
      select: { id: true },
    });

    const vehicleIds = vehicles.map((v) => v.id);
    const now = new Date();
    const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const records = await prisma.maintenanceRecord.findMany({
      where: {
        vehicleId: { in: vehicleIds },
        nextDueDate: { lte: thirtyDaysFromNow },
      },
      include: {
        vehicle: {
          select: { id: true, make: true, model: true, plateNumber: true },
        },
      },
      orderBy: { nextDueDate: 'asc' },
    });

    return records.map((r) => ({
      ...r,
      isOverdue: r.nextDueDate ? r.nextDueDate < now : false,
      daysUntilDue: r.nextDueDate
        ? Math.floor((r.nextDueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
        : null,
    }));
  }
}

export const maintenanceService = new MaintenanceService();
