import { whatsGPSClient } from './whatsgps.client';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import { logger } from '../../utils/logger';
import {
  WhatsGPSAuthResponse,
  WhatsGPSDevice,
  WhatsGPSDeviceStatus,
  WhatsGPSListResponse,
  WhatsGPSLocation,
  WhatsGPSTrip,
} from './whatsgps.types';
import { AppError } from '../../middleware/error.middleware';

const CACHE_KEYS = {
  authToken: 'whatsgps:auth:token',
  location: (imei: string) => `whatsgps:location:${imei}`,
  device: (imei: string) => `whatsgps:device:${imei}`,
  deviceList: 'whatsgps:devices:list',
};

const CACHE_TTL = {
  location: 30,       // 30 seconds for real-time location
  device: 300,        // 5 minutes for device info
  deviceList: 120,    // 2 minutes for device list
  authToken: 3600,    // 1 hour for auth token (actual expiry tracked separately)
};

class WhatsGPSService {
  /**
   * Authenticate with WhatsGPS API and cache token
   */
  async authenticate(): Promise<WhatsGPSAuthResponse> {
    try {
      const response = await whatsGPSClient.post<WhatsGPSAuthResponse>('/auth/login', {
        username: env.WHATSGPS_USERNAME,
        password: env.WHATSGPS_PASSWORD,
        apiKey: env.WHATSGPS_API_KEY,
      });

      const { token, expiresAt } = response.data;

      // Calculate and store with proper TTL
      const expiryMs = new Date(expiresAt).getTime() - Date.now();
      const ttlSeconds = Math.max(Math.floor(expiryMs / 1000) - 60, 300);

      await redis.set(CACHE_KEYS.authToken, token, ttlSeconds);

      logger.info('WhatsGPS authentication successful');
      return response.data;
    } catch (error) {
      logger.error('WhatsGPS authentication failed:', error);
      throw new AppError('Failed to authenticate with WhatsGPS', 503);
    }
  }

  /**
   * Get device details by IMEI
   */
  async getDeviceByIMEI(imei: string): Promise<WhatsGPSDevice> {
    const cacheKey = CACHE_KEYS.device(imei);

    // Check cache first
    const cached = await redis.getJSON<WhatsGPSDevice>(cacheKey);
    if (cached) return cached;

    try {
      const response = await whatsGPSClient.get<WhatsGPSDevice>(`/devices/${imei}`);
      const device = response.data;

      await redis.setJSON(cacheKey, device, CACHE_TTL.device);
      return device;
    } catch (error: unknown) {
      const axiosError = error as { response?: { status: number } };
      if (axiosError.response?.status === 404) {
        throw new AppError(`Device with IMEI ${imei} not found in WhatsGPS`, 404);
      }
      logger.error(`Failed to get device ${imei}:`, error);
      throw new AppError('Failed to retrieve device from WhatsGPS', 503);
    }
  }

  /**
   * Get all devices associated with the WhatsGPS account
   */
  async getDeviceList(): Promise<WhatsGPSDevice[]> {
    const cacheKey = CACHE_KEYS.deviceList;

    const cached = await redis.getJSON<WhatsGPSDevice[]>(cacheKey);
    if (cached) return cached;

    try {
      const response = await whatsGPSClient.get<WhatsGPSListResponse<WhatsGPSDevice>>('/devices');
      const devices = response.data.data || [];

      await redis.setJSON(cacheKey, devices, CACHE_TTL.deviceList);
      return devices;
    } catch (error) {
      logger.error('Failed to get device list:', error);
      throw new AppError('Failed to retrieve device list from WhatsGPS', 503);
    }
  }

  /**
   * Get real-time location for a device (cached 30s)
   */
  async getLocation(imei: string): Promise<WhatsGPSLocation> {
    const cacheKey = CACHE_KEYS.location(imei);

    const cached = await redis.getJSON<WhatsGPSLocation>(cacheKey);
    if (cached) return cached;

    try {
      const response = await whatsGPSClient.get<WhatsGPSLocation>(`/devices/${imei}/location`);
      const location = response.data;

      await redis.setJSON(cacheKey, location, CACHE_TTL.location);
      return location;
    } catch (error: unknown) {
      const axiosError = error as { response?: { status: number } };
      if (axiosError.response?.status === 404) {
        throw new AppError(`No location data available for device ${imei}`, 404);
      }
      logger.error(`Failed to get location for device ${imei}:`, error);
      throw new AppError('Failed to retrieve location from WhatsGPS', 503);
    }
  }

  /**
   * Get trip history for a device between timestamps
   */
  async getHistory(imei: string, from: Date, to: Date): Promise<WhatsGPSTrip[]> {
    try {
      const response = await whatsGPSClient.get<WhatsGPSListResponse<WhatsGPSTrip>>(
        `/devices/${imei}/history`,
        {
          params: {
            from: from.toISOString(),
            to: to.toISOString(),
          },
        }
      );

      return response.data.data || [];
    } catch (error) {
      logger.error(`Failed to get history for device ${imei}:`, error);
      throw new AppError('Failed to retrieve trip history from WhatsGPS', 503);
    }
  }

  /**
   * Get current device status (online/offline, signal, battery)
   */
  async getDeviceStatus(imei: string): Promise<WhatsGPSDeviceStatus> {
    try {
      const response = await whatsGPSClient.get<WhatsGPSDeviceStatus>(`/devices/${imei}/status`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to get status for device ${imei}:`, error);
      throw new AppError('Failed to retrieve device status from WhatsGPS', 503);
    }
  }

  /**
   * Send a command to a device (lock, unlock, etc.)
   */
  async sendCommand(imei: string, command: string, params?: Record<string, unknown>): Promise<void> {
    try {
      await whatsGPSClient.post(`/devices/${imei}/commands`, { command, ...params });
      logger.info(`Command ${command} sent to device ${imei}`);
    } catch (error) {
      logger.error(`Failed to send command to device ${imei}:`, error);
      throw new AppError('Failed to send command to device', 503);
    }
  }

  /**
   * Invalidate location cache for a device
   */
  async invalidateLocationCache(imei: string): Promise<void> {
    await redis.del(CACHE_KEYS.location(imei));
  }

  /**
   * Validate that an IMEI exists in WhatsGPS
   */
  async validateIMEI(imei: string): Promise<boolean> {
    try {
      await this.getDeviceByIMEI(imei);
      return true;
    } catch {
      return false;
    }
  }
}

export const whatsGPSService = new WhatsGPSService();
