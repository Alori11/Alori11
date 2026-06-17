import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import { validateBody, validateParams } from '../../middleware/validate.middleware';
import {
  createGeofence,
  listGeofences,
  getGeofence,
  updateGeofence,
  deleteGeofence,
} from './geofencing.controller';
import {
  createGeofenceSchema,
  updateGeofenceSchema,
  geofenceIdParamSchema,
} from './geofencing.schema';

const router = Router();

router.use(authMiddleware);

/**
 * @route   GET /api/v1/geofences
 * @desc    List geofences (optionally filtered by ?vehicleId=)
 */
router.get('/', listGeofences);

/**
 * @route   POST /api/v1/geofences
 * @desc    Create a geofence
 */
router.post('/', validateBody(createGeofenceSchema), createGeofence);

/**
 * @route   GET /api/v1/geofences/:id
 * @desc    Get a specific geofence
 */
router.get('/:id', validateParams(geofenceIdParamSchema), getGeofence);

/**
 * @route   PUT /api/v1/geofences/:id
 * @desc    Update a geofence
 */
router.put('/:id', validateParams(geofenceIdParamSchema), validateBody(updateGeofenceSchema), updateGeofence);

/**
 * @route   DELETE /api/v1/geofences/:id
 * @desc    Delete a geofence
 */
router.delete('/:id', validateParams(geofenceIdParamSchema), deleteGeofence);

export default router;
