import { Request, Response, NextFunction } from 'express';
import { geofencingService } from './geofencing.service';
import { sendSuccess, sendCreated, sendNoContent } from '../../utils/response';
import type { CreateGeofenceDto, UpdateGeofenceDto } from './geofencing.schema';

export const createGeofence = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const geofence = await geofencingService.createGeofence(
      req.user!.userId,
      req.body as CreateGeofenceDto
    );
    sendCreated(res, geofence, 'Geofence created');
  } catch (error) {
    next(error);
  }
};

export const listGeofences = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const vehicleId = req.query.vehicleId as string | undefined;
    const geofences = await geofencingService.listGeofences(req.user!.userId, vehicleId);
    sendSuccess(res, geofences, 'Geofences retrieved');
  } catch (error) {
    next(error);
  }
};

export const getGeofence = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const geofence = await geofencingService.getGeofence(req.user!.userId, req.params.id);
    sendSuccess(res, geofence, 'Geofence retrieved');
  } catch (error) {
    next(error);
  }
};

export const updateGeofence = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const geofence = await geofencingService.updateGeofence(
      req.user!.userId,
      req.params.id,
      req.body as UpdateGeofenceDto
    );
    sendSuccess(res, geofence, 'Geofence updated');
  } catch (error) {
    next(error);
  }
};

export const deleteGeofence = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    await geofencingService.deleteGeofence(req.user!.userId, req.params.id);
    sendNoContent(res);
  } catch (error) {
    next(error);
  }
};
