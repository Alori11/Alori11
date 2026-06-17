import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import { validateBody, validateParams, validateQuery } from '../../middleware/validate.middleware';
import {
  createRecord,
  listRecords,
  getRecord,
  updateRecord,
  deleteRecord,
  getUpcomingMaintenance,
} from './maintenance.controller';
import {
  createMaintenanceSchema,
  updateMaintenanceSchema,
  maintenanceIdParamSchema,
  maintenanceQuerySchema,
} from './maintenance.schema';

const router = Router();

router.use(authMiddleware);

/**
 * @route   GET /api/v1/maintenance/upcoming
 * @desc    Get upcoming/overdue maintenance across all vehicles
 */
router.get('/upcoming', getUpcomingMaintenance);

/**
 * @route   GET /api/v1/maintenance
 * @desc    List maintenance records (filterable by vehicleId, type, upcoming)
 */
router.get('/', validateQuery(maintenanceQuerySchema), listRecords);

/**
 * @route   POST /api/v1/maintenance
 * @desc    Create maintenance record
 */
router.post('/', validateBody(createMaintenanceSchema), createRecord);

/**
 * @route   GET /api/v1/maintenance/:id
 * @desc    Get single maintenance record
 */
router.get('/:id', validateParams(maintenanceIdParamSchema), getRecord);

/**
 * @route   PUT /api/v1/maintenance/:id
 * @desc    Update maintenance record
 */
router.put('/:id', validateParams(maintenanceIdParamSchema), validateBody(updateMaintenanceSchema), updateRecord);

/**
 * @route   DELETE /api/v1/maintenance/:id
 * @desc    Delete maintenance record
 */
router.delete('/:id', validateParams(maintenanceIdParamSchema), deleteRecord);

export default router;
