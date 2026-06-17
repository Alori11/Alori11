import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt';
import { sendError } from '../utils/response';
import { logger } from '../utils/logger';
import { prisma } from '../config/database';
import { Role } from '@prisma/client';

export const authMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      sendError(res, 'No authorization token provided', 401);
      return;
    }

    const token = authHeader.substring(7);

    if (!token) {
      sendError(res, 'Invalid authorization header format', 401);
      return;
    }

    const decoded = verifyAccessToken(token);

    // Optionally verify user still exists and is active
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, email: true, role: true, isVerified: true },
    });

    if (!user) {
      sendError(res, 'User not found', 401);
      return;
    }

    req.user = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };

    next();
  } catch (error: unknown) {
    logger.debug('Auth middleware error:', error);

    if (error instanceof Error) {
      if (error.name === 'TokenExpiredError') {
        sendError(res, 'Token has expired', 401);
        return;
      }
      if (error.name === 'JsonWebTokenError') {
        sendError(res, 'Invalid token', 401);
        return;
      }
    }

    sendError(res, 'Authentication failed', 401);
  }
};

export const requireRole = (...roles: Role[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      sendError(res, 'Unauthorized', 401);
      return;
    }

    if (!roles.includes(req.user.role as Role)) {
      sendError(res, 'Insufficient permissions', 403);
      return;
    }

    next();
  };
};

export const optionalAuth = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      next();
      return;
    }

    const token = authHeader.substring(7);
    const decoded = verifyAccessToken(token);

    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role as Role,
    };
  } catch {
    // Silently ignore invalid tokens for optional auth
  }

  next();
};
