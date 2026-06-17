import { Request, Response, NextFunction } from 'express';
import { vehiclesService } from './vehicles.service';
import { sendSuccess, sendCreated, sendNoContent } from '../../utils/response';
import type { CreateVehicleDto, UpdateVehicleDto } from './vehicles.schema';

export const createVehicle = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const vehicle = await vehiclesService.createVehicle(req.user!.userId, req.body as CreateVehicleDto);
    sendCreated(res, vehicle, 'Vehicle created successfully');
  } catch (error) {
    next(error);
  }
};

export const listVehicles = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const vehicles = await vehiclesService.listUserVehicles(req.user!.userId);
    sendSuccess(res, vehicles, 'Vehicles retrieved');
  } catch (error) {
    next(error);
  }
};

export const getVehicle = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const vehicle = await vehiclesService.getVehicle(req.user!.userId, req.params.id);
    sendSuccess(res, vehicle, 'Vehicle retrieved');
  } catch (error) {
    next(error);
  }
};

export const updateVehicle = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const vehicle = await vehiclesService.updateVehicle(
      req.user!.userId,
      req.params.id,
      req.body as UpdateVehicleDto
    );
    sendSuccess(res, vehicle, 'Vehicle updated');
  } catch (error) {
    next(error);
  }
};

export const deleteVehicle = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    await vehiclesService.deleteVehicle(req.user!.userId, req.params.id);
    sendNoContent(res);
  } catch (error) {
    next(error);
  }
};
