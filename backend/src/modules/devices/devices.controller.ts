import { Request, Response, NextFunction } from 'express';
import { devicesService } from './devices.service';
import { sendSuccess, sendCreated, sendNoContent } from '../../utils/response';
import type { PairDeviceDto, UpdateDeviceDto } from './devices.schema';

export const pairDevice = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as PairDeviceDto;
    const device = await devicesService.pairDevice(req.user!.userId, dto);
    sendCreated(res, device, 'Device paired successfully');
  } catch (error) {
    next(error);
  }
};

export const unpairDevice = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    await devicesService.unpairDevice(req.user!.userId, req.params.id);
    sendNoContent(res);
  } catch (error) {
    next(error);
  }
};

export const listDevices = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const devices = await devicesService.listUserDevices(req.user!.userId);
    sendSuccess(res, devices, 'Devices retrieved');
  } catch (error) {
    next(error);
  }
};

export const getDevice = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const device = await devicesService.getDevice(req.user!.userId, req.params.id);
    sendSuccess(res, device, 'Device retrieved');
  } catch (error) {
    next(error);
  }
};

export const updateDevice = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const dto = req.body as UpdateDeviceDto;
    const device = await devicesService.updateDevice(req.user!.userId, req.params.id, dto);
    sendSuccess(res, device, 'Device updated');
  } catch (error) {
    next(error);
  }
};
