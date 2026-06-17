import { z } from 'zod';

export const createGeofenceSchema = z.object({
  vehicleId: z.string().uuid('Invalid vehicle ID'),
  name: z.string().min(1, 'Name is required').max(100),
  lat: z
    .number()
    .min(-90, 'Latitude must be between -90 and 90')
    .max(90, 'Latitude must be between -90 and 90'),
  lng: z
    .number()
    .min(-180, 'Longitude must be between -180 and 180')
    .max(180, 'Longitude must be between -180 and 180'),
  radius: z
    .number()
    .min(50, 'Radius must be at least 50 meters')
    .max(50000, 'Radius cannot exceed 50,000 meters'),
  active: z.boolean().default(true),
});

export const updateGeofenceSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  lat: z.number().min(-90).max(90).optional(),
  lng: z.number().min(-180).max(180).optional(),
  radius: z.number().min(50).max(50000).optional(),
  active: z.boolean().optional(),
});

export const geofenceIdParamSchema = z.object({
  id: z.string().uuid('Invalid geofence ID'),
});

export type CreateGeofenceDto = z.infer<typeof createGeofenceSchema>;
export type UpdateGeofenceDto = z.infer<typeof updateGeofenceSchema>;
