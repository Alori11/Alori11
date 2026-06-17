import { Request, Response, NextFunction } from 'express';
import { maintenanceService } from './maintenance.service';
import { sendSuccess, sendCreated, sendNoContent } from '../../utils/response';
import type { CreateMaintenanceDto, UpdateMaintenanceDto, MaintenanceQueryDto } from './maintenance.schema';

export const createRecord = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const record = await maintenanceService.createRecord(
      req.user!.userId,
      req.body as CreateMaintenanceDto
    );
    sendCreated(res, record, 'Maintenance record created');
  } catch (error) {
    next(error);
  }
};

export const listRecords = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const query = req.query as unknown as MaintenanceQueryDto;
    const { records, meta } = await maintenanceService.listRecords(req.user!.userId, query);
    sendSuccess(res, records, 'Maintenance records retrieved', meta);
  } catch (error) {
    next(error);
  }
};

export const getRecord = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const record = await maintenanceService.getRecord(req.user!.userId, req.params.id);
    sendSuccess(res, record, 'Maintenance record retrieved');
  } catch (error) {
    next(error);
  }
};

export const updateRecord = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const record = await maintenanceService.updateRecord(
      req.user!.userId,
      req.params.id,
      req.body as UpdateMaintenanceDto
    );
    sendSuccess(res, record, 'Maintenance record updated');
  } catch (error) {
    next(error);
  }
};

export const deleteRecord = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    await maintenanceService.deleteRecord(req.user!.userId, req.params.id);
    sendNoContent(res);
  } catch (error) {
    next(error);
  }
};

export const getUpcomingMaintenance = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const records = await maintenanceService.getUpcomingMaintenance(req.user!.userId);
    sendSuccess(res, records, 'Upcoming maintenance retrieved');
  } catch (error) {
    next(error);
  }
};
