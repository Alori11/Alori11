import admin from 'firebase-admin';
import { env } from '../../config/env';
import { logger } from '../../utils/logger';

let firebaseApp: admin.app.App | null = null;

const initializeFirebase = (): admin.app.App => {
  if (firebaseApp) return firebaseApp;

  if (admin.apps.length > 0) {
    firebaseApp = admin.apps[0] as admin.app.App;
    return firebaseApp;
  }

  const privateKey = env.FCM_PRIVATE_KEY.replace(/\\n/g, '\n');

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.FCM_PROJECT_ID,
      privateKey,
      clientEmail: env.FCM_CLIENT_EMAIL,
    }),
  });

  logger.info('Firebase Admin SDK initialized');
  return firebaseApp;
};

export interface FCMNotification {
  title: string;
  body: string;
  imageUrl?: string;
}

export interface FCMData {
  [key: string]: string;
}

class FCMService {
  private messaging: admin.messaging.Messaging;

  constructor() {
    const app = initializeFirebase();
    this.messaging = admin.messaging(app);
  }

  /**
   * Send push notification to a specific device token
   */
  async sendToDevice(
    token: string,
    notification: FCMNotification,
    data?: FCMData
  ): Promise<string | null> {
    try {
      const message: admin.messaging.Message = {
        token,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: data
          ? Object.fromEntries(
              Object.entries(data).map(([k, v]) => [k, String(v)])
            )
          : undefined,
        android: {
          notification: {
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const messageId = await this.messaging.send(message);
      logger.debug(`FCM notification sent, messageId: ${messageId}`);
      return messageId;
    } catch (error: unknown) {
      const fcmError = error as { code?: string; message?: string };
      // Handle invalid/expired tokens gracefully
      if (
        fcmError.code === 'messaging/invalid-registration-token' ||
        fcmError.code === 'messaging/registration-token-not-registered'
      ) {
        logger.warn(`Invalid FCM token: ${token}`);
        return null;
      }
      logger.error('Failed to send FCM notification:', error);
      throw error;
    }
  }

  /**
   * Send push notification to multiple device tokens
   */
  async sendToMultipleDevices(
    tokens: string[],
    notification: FCMNotification,
    data?: FCMData
  ): Promise<admin.messaging.BatchResponse> {
    if (tokens.length === 0) {
      return { successCount: 0, failureCount: 0, responses: [] };
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: data
          ? Object.fromEntries(
              Object.entries(data).map(([k, v]) => [k, String(v)])
            )
          : undefined,
        android: {
          notification: {
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await this.messaging.sendEachForMulticast(message);
      logger.debug(
        `FCM multicast: ${response.successCount} sent, ${response.failureCount} failed`
      );
      return response;
    } catch (error) {
      logger.error('Failed to send FCM multicast:', error);
      throw error;
    }
  }

  /**
   * Send push notification to a topic
   */
  async sendToTopic(
    topic: string,
    notification: FCMNotification,
    data?: FCMData
  ): Promise<string> {
    try {
      const message: admin.messaging.Message = {
        topic,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: data
          ? Object.fromEntries(
              Object.entries(data).map(([k, v]) => [k, String(v)])
            )
          : undefined,
      };

      const messageId = await this.messaging.send(message);
      logger.debug(`FCM topic notification sent to ${topic}, messageId: ${messageId}`);
      return messageId;
    } catch (error) {
      logger.error(`Failed to send FCM topic notification to ${topic}:`, error);
      throw error;
    }
  }

  /**
   * Subscribe tokens to a topic
   */
  async subscribeToTopic(tokens: string[], topic: string): Promise<void> {
    try {
      await this.messaging.subscribeToTopic(tokens, topic);
      logger.debug(`Subscribed ${tokens.length} tokens to topic: ${topic}`);
    } catch (error) {
      logger.error(`Failed to subscribe to topic ${topic}:`, error);
    }
  }

  /**
   * Unsubscribe tokens from a topic
   */
  async unsubscribeFromTopic(tokens: string[], topic: string): Promise<void> {
    try {
      await this.messaging.unsubscribeFromTopic(tokens, topic);
      logger.debug(`Unsubscribed ${tokens.length} tokens from topic: ${topic}`);
    } catch (error) {
      logger.error(`Failed to unsubscribe from topic ${topic}:`, error);
    }
  }
}

export const fcmService = new FCMService();
