import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import { validateBody, validateParams } from '../../middleware/validate.middleware';
import {
  pairDevice,
  unpairDevice,
  listDevices,
  getDevice,
  updateDevice,
} from './devices.controller';
import { pairDeviceSchema, updateDeviceSchema, deviceIdParamSchema } from './devices.schema';

const router = Router();

router.use(authMiddleware);

/**
 * @route   GET /api/v1/devices
 * @desc    List all user's paired devices
 */
router.get('/', listDevices);

/**
 * @route   POST /api/v1/devices/pair
 * @desc    Pair a new GPS device by IMEI
 */
router.post('/pair', validateBody(pairDeviceSchema), pairDevice);

/**
 * @route   GET /api/v1/devices/:id
 * @desc    Get device details
 */
router.get('/:id', validateParams(deviceIdParamSchema), getDevice);

/**
 * @route   PUT /api/v1/devices/:id
 * @desc    Update device name or vehicle assignment
 */
router.put('/:id', validateParams(deviceIdParamSchema), validateBody(updateDeviceSchema), updateDevice);

/**
 * @route   DELETE /api/v1/devices/:id
 * @desc    Unpair device
 */
router.delete('/:id', validateParams(deviceIdParamSchema), unpairDevice);

export default router;
