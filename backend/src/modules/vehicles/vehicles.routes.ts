import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import { validateBody, validateParams } from '../../middleware/validate.middleware';
import {
  createVehicle,
  listVehicles,
  getVehicle,
  updateVehicle,
  deleteVehicle,
} from './vehicles.controller';
import {
  createVehicleSchema,
  updateVehicleSchema,
  vehicleIdParamSchema,
} from './vehicles.schema';

const router = Router();

router.use(authMiddleware);

/**
 * @route   GET /api/v1/vehicles
 * @desc    List user's vehicles
 */
router.get('/', listVehicles);

/**
 * @route   POST /api/v1/vehicles
 * @desc    Create a new vehicle
 */
router.post('/', validateBody(createVehicleSchema), createVehicle);

/**
 * @route   GET /api/v1/vehicles/:id
 * @desc    Get vehicle details
 */
router.get('/:id', validateParams(vehicleIdParamSchema), getVehicle);

/**
 * @route   PUT /api/v1/vehicles/:id
 * @desc    Update vehicle
 */
router.put('/:id', validateParams(vehicleIdParamSchema), validateBody(updateVehicleSchema), updateVehicle);

/**
 * @route   DELETE /api/v1/vehicles/:id
 * @desc    Delete vehicle
 */
router.delete('/:id', validateParams(vehicleIdParamSchema), deleteVehicle);

export default router;
