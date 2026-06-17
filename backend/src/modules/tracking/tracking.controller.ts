import { Request, Response, NextFunction } from 'express';
import { trackingService } from './tracking.service';
import { sendSuccess } from '../../utils/response';

export const getLiveLocation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const data = await trackingService.getLiveLocation(
      req.user!.userId,
      req.params.vehicleId
    );
    sendSuccess(res, data, 'Live location retrieved');
  } catch (error) {
    next(error);
  }
};

export const getHistory = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { from, to } = req.query as { from: string; to: string };
    const data = await trackingService.getHistory(
      req.user!.userId,
      req.params.vehicleId,
      new Date(from),
      new Date(to)
    );
    sendSuccess(res, data, 'Trip history retrieved');
  } catch (error) {
    next(error);
  }
};

export const getLastKnownLocation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const data = await trackingService.getLastKnownLocation(
      req.user!.userId,
      req.params.vehicleId
    );
    sendSuccess(res, data, 'Last known location retrieved');
  } catch (error) {
    next(error);
  }
};
