import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import {
  listAlerts,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteAlert,
  deleteReadAlerts,
} from './alerts.controller';

const router = Router();

router.use(authMiddleware);

/**
 * @route   GET /api/v1/alerts
 * @desc    List alerts with pagination and filters
 * @query   page, limit, vehicleId, type, read
 */
router.get('/', listAlerts);

/**
 * @route   GET /api/v1/alerts/unread-count
 * @desc    Get count of unread alerts
 */
router.get('/unread-count', getUnreadCount);

/**
 * @route   PUT /api/v1/alerts/mark-all-read
 * @desc    Mark all alerts as read
 */
router.put('/mark-all-read', markAllAsRead);

/**
 * @route   DELETE /api/v1/alerts/read
 * @desc    Delete all read alerts
 */
router.delete('/read', deleteReadAlerts);

/**
 * @route   PUT /api/v1/alerts/:id/read
 * @desc    Mark single alert as read
 */
router.put('/:id/read', markAsRead);

/**
 * @route   DELETE /api/v1/alerts/:id
 * @desc    Delete a specific alert
 */
router.delete('/:id', deleteAlert);

export default router;
