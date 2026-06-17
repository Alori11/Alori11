import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse, InternalAxiosRequestConfig } from 'axios';
import { env } from '../../config/env';
import { redis } from '../../config/redis';
import { logger } from '../../utils/logger';

const WHATSGPS_TOKEN_CACHE_KEY = 'whatsgps:auth:token';

let isRefreshing = false;
let refreshQueue: Array<(token: string) => void> = [];

const processQueue = (token: string) => {
  refreshQueue.forEach((cb) => cb(token));
  refreshQueue = [];
};

const getStoredToken = async (): Promise<string | null> => {
  return redis.get(WHATSGPS_TOKEN_CACHE_KEY);
};

export const whatsGPSClient: AxiosInstance = axios.create({
  baseURL: env.WHATSGPS_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request interceptor: inject cached auth token
whatsGPSClient.interceptors.request.use(
  async (config: InternalAxiosRequestConfig): Promise<InternalAxiosRequestConfig> => {
    // Skip auth header for login endpoint
    if (config.url?.includes('/auth/login')) {
      return config;
    }

    const token = await getStoredToken();
    if (token && config.headers) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }

    return config;
  },
  (error) => {
    logger.error('WhatsGPS request interceptor error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor: handle token expiry and errors
whatsGPSClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  async (error) => {
    const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean };

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // Queue request until token is refreshed
        return new Promise<AxiosResponse>((resolve) => {
          refreshQueue.push((token: string) => {
            if (originalRequest.headers) {
              originalRequest.headers['Authorization'] = `Bearer ${token}`;
            }
            resolve(whatsGPSClient(originalRequest));
          });
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        // Re-authenticate
        const authResponse = await axios.post(
          `${env.WHATSGPS_BASE_URL}/auth/login`,
          {
            username: env.WHATSGPS_USERNAME,
            password: env.WHATSGPS_PASSWORD,
          },
          { timeout: 10000 }
        );

        const { token, expiresAt } = authResponse.data;

        // Calculate TTL
        const expiryMs = new Date(expiresAt).getTime() - Date.now();
        const ttlSeconds = Math.max(Math.floor(expiryMs / 1000) - 60, 300); // Refresh 1 min before expiry

        await redis.set(WHATSGPS_TOKEN_CACHE_KEY, token, ttlSeconds);

        processQueue(token);

        if (originalRequest.headers) {
          originalRequest.headers['Authorization'] = `Bearer ${token}`;
        }

        return whatsGPSClient(originalRequest);
      } catch (refreshError) {
        logger.error('WhatsGPS token refresh failed:', refreshError);
        processQueue('');
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    // Log API errors
    if (error.response) {
      logger.error('WhatsGPS API error:', {
        status: error.response.status,
        data: error.response.data,
        url: error.config?.url,
      });
    } else if (error.request) {
      logger.error('WhatsGPS no response received:', { url: error.config?.url });
    }

    return Promise.reject(error);
  }
);
