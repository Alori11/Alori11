import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { json, urlencoded } from 'body-parser';

import { env } from './config/env';
import { connectDatabase, disconnectDatabase } from './config/database';
import { redis } from './config/redis';
import { logger } from './utils/logger';
import { errorMiddleware, notFoundHandler } from './middleware/error.middleware';
import { generalLimiter } from './middleware/rateLimiter.middleware';

// Route imports
import authRoutes from './modules/auth/auth.routes';
import usersRoutes from './modules/users/users.routes';
import vehiclesRoutes from './modules/vehicles/vehicles.routes';
import devicesRoutes from './modules/devices/devices.routes';
import trackingRoutes from './modules/tracking/tracking.routes';
import geofencingRoutes from './modules/geofencing/geofencing.routes';
import maintenanceRoutes from './modules/maintenance/maintenance.routes';
import alertsRoutes from './modules/alerts/alerts.routes';

const app = express();

// ─── Security Middleware ────────────────────────────────────────────────────────
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"], // Required for swagger-ui
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
  crossOriginEmbedderPolicy: false,
}));

app.use(cors({
  origin: env.CORS_ORIGIN === '*' ? '*' : env.CORS_ORIGIN.split(','),
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  credentials: true,
  maxAge: 86400,
}));

// ─── Body Parsing ───────────────────────────────────────────────────────────────
app.use(json({ limit: '10mb' }));
app.use(urlencoded({ extended: true, limit: '10mb' }));

// ─── Rate Limiting ──────────────────────────────────────────────────────────────
app.use(generalLimiter);

// ─── Request Logging ────────────────────────────────────────────────────────────
app.use((req, _res, next) => {
  logger.debug(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });
  next();
});

// ─── Health Check ───────────────────────────────────────────────────────────────
app.get('/health', async (_req, res) => {
  const dbStatus = await import('./config/database')
    .then(({ prisma }) => prisma.$queryRaw`SELECT 1`.then(() => 'ok').catch(() => 'error'));

  res.json({
    status: 'ok',
    version: process.env.npm_package_version || '1.0.0',
    environment: env.NODE_ENV,
    timestamp: new Date().toISOString(),
    services: {
      database: dbStatus,
      redis: redis.getClient().status === 'ready' ? 'ok' : 'error',
    },
  });
});

// ─── Swagger UI ─────────────────────────────────────────────────────────────────
if (env.NODE_ENV !== 'production') {
  const setupSwagger = async () => {
    const { default: swaggerUi } = await import('swagger-ui-express');
    const swaggerSpec = {
      openapi: '3.0.0',
      info: {
        title: 'Carchip API',
        version: '1.0.0',
        description: 'Carchip Vehicle Tracking Platform API',
        contact: {
          name: 'Carchip Support',
          email: 'support@carchip.com',
        },
      },
      servers: [
        { url: '/api/v1', description: 'Current server' },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          },
        },
      },
      security: [{ bearerAuth: [] }],
    };
    app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
    logger.info('Swagger UI available at /api/docs');
  };
  setupSwagger().catch((err) => logger.warn('Swagger setup failed:', err));
}

// ─── API Routes ─────────────────────────────────────────────────────────────────
const API_PREFIX = '/api/v1';

app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/users`, usersRoutes);
app.use(`${API_PREFIX}/vehicles`, vehiclesRoutes);
app.use(`${API_PREFIX}/devices`, devicesRoutes);
app.use(`${API_PREFIX}/tracking`, trackingRoutes);
app.use(`${API_PREFIX}/geofences`, geofencingRoutes);
app.use(`${API_PREFIX}/maintenance`, maintenanceRoutes);
app.use(`${API_PREFIX}/alerts`, alertsRoutes);

// ─── 404 Handler ────────────────────────────────────────────────────────────────
app.use(notFoundHandler);

// ─── Global Error Handler ───────────────────────────────────────────────────────
app.use(errorMiddleware);

// ─── Graceful Shutdown ──────────────────────────────────────────────────────────
const gracefulShutdown = async (signal: string) => {
  logger.info(`Received ${signal}, initiating graceful shutdown...`);
  try {
    await disconnectDatabase();
    await redis.disconnect();
    logger.info('Graceful shutdown completed');
    process.exit(0);
  } catch (error) {
    logger.error('Error during shutdown:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Unhandled promise rejections
process.on('unhandledRejection', (reason: unknown) => {
  logger.error('Unhandled Promise Rejection:', reason);
});

// Uncaught exceptions
process.on('uncaughtException', (error: Error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

// ─── Start Server ───────────────────────────────────────────────────────────────
const PORT = parseInt(env.PORT, 10);

const startServer = async () => {
  try {
    await connectDatabase();
    app.listen(PORT, '0.0.0.0', () => {
      logger.info(`Carchip API server running on port ${PORT} [${env.NODE_ENV}]`);
      logger.info(`Health check: http://localhost:${PORT}/health`);
      if (env.NODE_ENV !== 'production') {
        logger.info(`API Docs: http://localhost:${PORT}/api/docs`);
      }
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app;
