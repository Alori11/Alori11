export interface WhatsGPSDevice {
  imei: string;
  name: string;
  status: 'online' | 'offline';
  lastUpdate: string;
  signal: number;
  battery?: number;
  model?: string;
  simCard?: string;
}

export interface WhatsGPSLocation {
  imei: string;
  lat: number;
  lng: number;
  speed: number;
  heading: number;
  altitude: number;
  satellites: number;
  ignition: boolean;
  timestamp: string;
  address?: string;
  accuracy?: number;
  odometer?: number;
}

export interface WhatsGPSTripPoint {
  lat: number;
  lng: number;
  timestamp: string;
  speed: number;
  heading?: number;
  ignition?: boolean;
}

export interface WhatsGPSTrip {
  startTime: string;
  endTime: string;
  startLat: number;
  startLng: number;
  endLat: number;
  endLng: number;
  distance: number;
  duration: number;
  maxSpeed?: number;
  avgSpeed?: number;
  points: WhatsGPSTripPoint[];
}

export interface WhatsGPSAuthResponse {
  token: string;
  expiresAt: string;
  tokenType?: string;
}

export interface WhatsGPSDeviceStatus {
  imei: string;
  online: boolean;
  lastSeen: string;
  signal: number;
  battery?: number;
  ignition?: boolean;
  speed?: number;
}

export interface WhatsGPSApiError {
  code: number;
  message: string;
  details?: unknown;
}

export interface WhatsGPSListResponse<T> {
  data: T[];
  total: number;
  page?: number;
  limit?: number;
}
