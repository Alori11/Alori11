import { z } from 'zod';
import { MaintenanceType } from '@prisma/client';

export const createMaintenanceSchema = z.object({
  vehicleId: z.string().uuid('Invalid vehicle ID'),
  type: z.nativeEnum(MaintenanceType, { errorMap: () => ({ message: 'Invalid maintenance type' }) }),
  date: z.string().datetime({ message: 'Date must be a valid ISO datetime' }),
  mileage: z.number().int().min(0).optional(),
  notes: z.string().max(1000).optional(),
  cost: z.number().min(0).optional(),
  nextDueDate: z.string().datetime({ message: 'Next due date must be a valid ISO datetime' }).optional(),
  nextDueMileage: z.number().int().min(0).optional(),
});

export const updateMaintenanceSchema = z.object({
  type: z.nativeEnum(MaintenanceType).optional(),
  date: z.string().datetime().optional(),
  mileage: z.number().int().min(0).optional().nullable(),
  notes: z.string().max(1000).optional().nullable(),
  cost: z.number().min(0).optional().nullable(),
  nextDueDate: z.string().datetime().optional().nullable(),
  nextDueMileage: z.number().int().min(0).optional().nullable(),
});

export const maintenanceIdParamSchema = z.object({
  id: z.string().uuid('Invalid maintenance record ID'),
});

export const maintenanceQuerySchema = z.object({
  vehicleId: z.string().uuid().optional(),
  type: z.nativeEnum(MaintenanceType).optional(),
  upcoming: z.coerce.boolean().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export type CreateMaintenanceDto = z.infer<typeof createMaintenanceSchema>;
export type UpdateMaintenanceDto = z.infer<typeof updateMaintenanceSchema>;
export type MaintenanceQueryDto = z.infer<typeof maintenanceQuerySchema>;
