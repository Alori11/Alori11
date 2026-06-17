import { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service';
import { sendSuccess, sendCreated, sendError } from '../../utils/response';
import type {
  RegisterDto,
  LoginDto,
  PhoneLoginDto,
  VerifyOTPDto,
  RefreshTokenDto,
} from './auth.schema';

export const register = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as RegisterDto;
    const result = await authService.register(dto);
    sendCreated(res, result, 'Registration successful');
  } catch (error) {
    next(error);
  }
};

export const login = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as LoginDto;
    const result = await authService.login(dto);
    sendSuccess(res, result, 'Login successful');
  } catch (error) {
    next(error);
  }
};

export const phoneLogin = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as PhoneLoginDto;
    await authService.phoneLogin(dto);
    sendSuccess(res, null, 'OTP sent successfully');
  } catch (error) {
    next(error);
  }
};

export const verifyOTP = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as VerifyOTPDto;
    const result = await authService.verifyOTP(dto);
    const message = result.isNewUser ? 'Account created successfully' : 'Login successful';
    sendSuccess(res, result, message);
  } catch (error) {
    next(error);
  }
};

export const refreshToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as RefreshTokenDto;
    const result = await authService.refreshToken(dto);
    sendSuccess(res, result, 'Token refreshed successfully');
  } catch (error) {
    next(error);
  }
};

export const logout = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { refreshToken: token } = req.body;
    await authService.logout(userId, token);
    sendSuccess(res, null, 'Logged out successfully');
  } catch (error) {
    next(error);
  }
};

export const getMe = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { prisma } = await import('../../config/database');
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        isVerified: true,
        fcmToken: true,
        createdAt: true,
        updatedAt: true,
        _count: {
          select: {
            vehicles: true,
            devices: true,
            alerts: true,
          },
        },
      },
    });

    if (!user) {
      sendError(res, 'User not found', 404);
      return;
    }

    sendSuccess(res, user, 'Profile retrieved');
  } catch (error) {
    next(error);
  }
};
