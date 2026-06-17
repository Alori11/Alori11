import rateLimit from 'express-rate-limit';
import { sendError } from '../utils/response';
import { Request, Response } from 'express';

const rateLimitHandler = (req: Request, res: Response): void => {
  sendError(res, 'Too many requests. Please try again later.', 429);
};

// General API rate limiter: 100 requests per 15 minutes
export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
  skip: (req: Request) => req.ip === '127.0.0.1',
});

// Auth rate limiter: 10 requests per 15 minutes
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
  skipSuccessfulRequests: false,
});

// OTP rate limiter: 5 OTP requests per hour
export const otpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req: Request, res: Response): void => {
    sendError(res, 'Too many OTP requests. Please wait before requesting another.', 429);
  },
  keyGenerator: (req: Request) => req.body?.phone || req.ip || 'unknown',
});

// Tracking rate limiter: 200 requests per minute (more generous for real-time data)
export const trackingLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});
