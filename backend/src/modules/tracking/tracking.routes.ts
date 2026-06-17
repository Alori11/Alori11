import { Router } from 'express';
import { Request, Response, NextFunction } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import { trackingLimiter } from '../../middleware/rateLimiter.middleware';
import { trackingService } from './tracking.service';
import { sendSuccess, sendError } from '../../utils/response';
import { z } from 'zod';

const router = Router();

router.use(authMiddleware);

const historyQuerySchema = z.object({
  from: z.string().datetime({ message: 'from must be an ISO datetime string' }),
  to: z.string().datetime({ message: 'to must be an ISO datetime string' }),
});

/**
 * @route   GET /api/v1/tracking/:vehicleId/live
 * @desc    Get live location for a vehicle
 */
router.get(
  '/:vehicleId/live',
  trackingLimiter,
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const data = await trackingService.getLiveLocation(
        req.user!.userId,
        req.params.vehicleId
      );
      sendSuccess(res, data, 'Live location retrieved');
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/tracking/:vehicleId/history
 * @desc    Get trip history for a vehicle
 * @query   from - ISO datetime string
 * @query   to - ISO datetime string
 */
router.get(
  '/:vehicleId/history',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parsed = historyQuerySchema.safeParse(req.query);
      if (!parsed.success) {
        const errors = parsed.error.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        sendError(res, 'Invalid query parameters', 422, errors);
        return;
      }

      const { from, to } = parsed.data;
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
  }
);

/**
 * @route   GET /api/v1/tracking/:vehicleId/last-known
 * @desc    Get last known location from database
 */
router.get(
  '/:vehicleId/last-known',
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const data = await trackingService.getLastKnownLocation(
        req.user!.userId,
        req.params.vehicleId
      );
      sendSuccess(res, data, 'Last known location retrieved');
    } catch (error) {
      next(error);
    }
  }
);

export default router;
