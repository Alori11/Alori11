import { Request, Response, NextFunction } from 'express';
import { usersService } from './users.service';
import {
  sendSuccess,
  sendNoContent,
  sendError,
  paginationMeta,
} from '../../utils/response';
import type { UpdateProfileDto, ChangePasswordDto, PaginationQueryDto } from './users.schema';

export const getProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const user = await usersService.getUserById(req.user!.userId);
    sendSuccess(res, user, 'Profile retrieved');
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as UpdateProfileDto;
    const user = await usersService.updateProfile(req.user!.userId, dto);
    sendSuccess(res, user, 'Profile updated successfully');
  } catch (error) {
    next(error);
  }
};

export const changePassword = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as ChangePasswordDto;
    await usersService.changePassword(req.user!.userId, dto);
    sendSuccess(res, null, 'Password changed successfully. Please log in again.');
  } catch (error) {
    next(error);
  }
};

export const updateFCMToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { fcmToken } = req.body;
    const result = await usersService.updateFCMToken(req.user!.userId, fcmToken);
    sendSuccess(res, result, 'FCM token updated');
  } catch (error) {
    next(error);
  }
};

export const deleteAccount = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { password } = req.body;
    if (!password) {
      sendError(res, 'Password is required to delete account', 400);
      return;
    }
    await usersService.deleteAccount(req.user!.userId, password);
    sendNoContent(res);
  } catch (error) {
    next(error);
  }
};

export const getAllUsers = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { page, limit, search } = req.query as unknown as PaginationQueryDto;
    const { users, total } = await usersService.getAllUsers(page, limit, search);
    sendSuccess(res, users, 'Users retrieved', paginationMeta(total, page, limit));
  } catch (error) {
    next(error);
  }
};
