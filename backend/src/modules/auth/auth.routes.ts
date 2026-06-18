import { Router } from 'express';
import { authLimiter, otpLimiter } from '../../middleware/rateLimiter.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { authMiddleware } from '../../middleware/auth.middleware';
import {
  register,
  login,
  phoneLogin,
  verifyOTP,
  refreshToken,
  logout,
  getMe,
  googleLogin,
} from './auth.controller';
import {
  registerSchema,
  loginSchema,
  phoneLoginSchema,
  verifyOTPSchema,
  refreshTokenSchema,
  googleLoginSchema,
} from './auth.schema';

const router = Router();

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register new user with email/password
 * @access  Public
 */
router.post('/register', authLimiter, validateBody(registerSchema), register);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login with email/password
 * @access  Public
 */
router.post('/login', authLimiter, validateBody(loginSchema), login);

/**
 * @route   POST /api/v1/auth/phone-login
 * @desc    Request OTP for phone login
 * @access  Public
 */
router.post('/phone-login', otpLimiter, validateBody(phoneLoginSchema), phoneLogin);

/**
 * @route   POST /api/v1/auth/verify-otp
 * @desc    Verify OTP and get tokens
 * @access  Public
 */
router.post('/verify-otp', authLimiter, validateBody(verifyOTPSchema), verifyOTP);

/**
 * @route   POST /api/v1/auth/refresh
 * @desc    Refresh access token
 * @access  Public
 */
router.post('/refresh', validateBody(refreshTokenSchema), refreshToken);

/**
 * @route   POST /api/v1/auth/logout
 * @desc    Logout and invalidate tokens
 * @access  Private
 */
router.post('/logout', authMiddleware, logout);

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', authMiddleware, getMe);

/**
 * @route   POST /api/v1/auth/google
 * @desc    Login or register via Google OAuth
 * @access  Public
 */
router.post('/google', authLimiter, validateBody(googleLoginSchema), googleLogin);

export default router;
