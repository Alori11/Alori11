import { Router } from 'express';
import { authMiddleware, requireRole } from '../../middleware/auth.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import {
  getProfile,
  updateProfile,
  changePassword,
  updateFCMToken,
  deleteAccount,
  getAllUsers,
} from './users.controller';
import {
  updateProfileSchema,
  changePasswordSchema,
  updateFCMTokenSchema,
  paginationQuerySchema,
} from './users.schema';
import { Role } from '@prisma/client';

const router = Router();

// All user routes require authentication
router.use(authMiddleware);

/**
 * @route   GET /api/v1/users/profile
 * @desc    Get current user profile
 */
router.get('/profile', getProfile);

/**
 * @route   PUT /api/v1/users/profile
 * @desc    Update user profile
 */
router.put('/profile', validateBody(updateProfileSchema), updateProfile);

/**
 * @route   PUT /api/v1/users/change-password
 * @desc    Change password
 */
router.put('/change-password', validateBody(changePasswordSchema), changePassword);

/**
 * @route   PUT /api/v1/users/fcm-token
 * @desc    Update Firebase Cloud Messaging token
 */
router.put('/fcm-token', validateBody(updateFCMTokenSchema), updateFCMToken);

/**
 * @route   DELETE /api/v1/users/account
 * @desc    Delete user account
 */
router.delete('/account', deleteAccount);

/**
 * @route   GET /api/v1/users
 * @desc    Get all users (admin only)
 */
router.get('/', requireRole(Role.ADMIN), validateQuery(paginationQuerySchema), getAllUsers);

export default router;
