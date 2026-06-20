import { Request, Response, NextFunction } from 'express';
import { alertsService, AlertsQueryOptions } from './alerts.service';
import { sendSuccess, sendError, sendNoContent } from '../../utils/response';
import { AlertType } from '@prisma/client';
import { z } from 'zod';

const alertsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  vehicleId: z.string().uuid().optional(),
  type: z.nativeEnum(AlertType).optional(),
  read: z.coerce.boolean().optional(),
});

export const listAlerts = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const parsed = alertsQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      sendError(res, 'Invalid query parameters', 422, parsed.error.errors);
      return;
    }

    const { alerts, meta } = await alertsService.listAlerts(
      req.user!.userId,
      parsed.data as AlertsQueryOptions
    );
    sendSuccess(res, alerts, 'Alerts retrieved', 200, meta);
  } catch (error) {
    next(error);
  }
};

export const getUnreadCount = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const count = await alertsService.getUnreadCount(req.user!.userId);
    sendSuccess(res, { count }, 'Unread count retrieved');
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const alert = await alertsService.markAsRead(req.user!.userId, req.params.id);
    if (!alert) {
      sendError(res, 'Alert not found', 404);
      return;
    }
    sendSuccess(res, alert, 'Alert marked as read');
  } catch (error) {
    next(error);
  }
};

export const markAllAsRead = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const vehicleId = req.body?.vehicleId as string | undefined;
    const count = await alertsService.markAllAsRead(req.user!.userId, vehicleId);
    sendSuccess(res, { count }, `${count} alerts marked as read`);
  } catch (error) {
    next(error);
  }
};

export const deleteAlert = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const deleted = await alertsService.deleteAlert(req.user!.userId, req.params.id);
    if (!deleted) {
      sendError(res, 'Alert not found', 404);
      return;
    }
    sendNoContent(res);
  } catch (error) {
    next(error);
  }
};

export const deleteReadAlerts = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const count = await alertsService.deleteReadAlerts(req.user!.userId);
    sendSuccess(res, { count }, `${count} read alerts deleted`);
  } catch (error) {
    next(error);
  }
};
