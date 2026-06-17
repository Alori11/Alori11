import { z } from 'zod';

const currentYear = new Date().getFullYear();

export const createVehicleSchema = z.object({
  make: z.string().min(1, 'Make is required').max(100),
  model: z.string().min(1, 'Model is required').max(100),
  year: z
    .number()
    .int()
    .min(1900, 'Year must be after 1900')
    .max(currentYear + 2, `Year cannot exceed ${currentYear + 2}`),
  plateNumber: z.string().min(1, 'Plate number is required').max(20).toUpperCase(),
  color: z.string().max(50).optional(),
  deviceId: z.string().uuid('Invalid device ID').optional().nullable(),
});

export const updateVehicleSchema = z.object({
  make: z.string().min(1).max(100).optional(),
  model: z.string().min(1).max(100).optional(),
  year: z
    .number()
    .int()
    .min(1900)
    .max(currentYear + 2)
    .optional(),
  plateNumber: z.string().min(1).max(20).toUpperCase().optional(),
  color: z.string().max(50).optional().nullable(),
  deviceId: z.string().uuid().optional().nullable(),
});

export const vehicleIdParamSchema = z.object({
  id: z.string().uuid('Invalid vehicle ID'),
});

export type CreateVehicleDto = z.infer<typeof createVehicleSchema>;
export type UpdateVehicleDto = z.infer<typeof updateVehicleSchema>;
