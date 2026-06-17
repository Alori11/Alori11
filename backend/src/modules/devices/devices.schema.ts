import { z } from 'zod';

export const pairDeviceSchema = z.object({
  imei: z
    .string()
    .regex(/^\d{15}$/, 'IMEI must be exactly 15 digits')
    .min(15)
    .max(15),
  name: z.string().min(1).max(100).optional(),
});

export const updateDeviceSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  vehicleId: z.string().uuid('Invalid vehicle ID').optional().nullable(),
});

export const deviceIdParamSchema = z.object({
  id: z.string().uuid('Invalid device ID'),
});

export const imeiParamSchema = z.object({
  imei: z.string().regex(/^\d{15}$/, 'IMEI must be exactly 15 digits'),
});

export type PairDeviceDto = z.infer<typeof pairDeviceSchema>;
export type UpdateDeviceDto = z.infer<typeof updateDeviceSchema>;
