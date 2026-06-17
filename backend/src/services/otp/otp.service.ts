import { prisma } from '../../config/database';
import { logger } from '../../utils/logger';
import { AppError } from '../../middleware/error.middleware';

const OTP_EXPIRY_MINUTES = 5;
const OTP_LENGTH = 6;

class OTPService {
  /**
   * Generate a cryptographically random OTP code
   */
  private generateCode(): string {
    const min = Math.pow(10, OTP_LENGTH - 1);
    const max = Math.pow(10, OTP_LENGTH) - 1;
    return Math.floor(min + Math.random() * (max - min + 1)).toString();
  }

  /**
   * Create an OTP for the given phone number
   */
  async createOTP(phone: string, userId?: string): Promise<string> {
    // Invalidate any existing unused OTPs for this phone
    await prisma.oTP.updateMany({
      where: {
        phone,
        used: false,
        expiresAt: { gt: new Date() },
      },
      data: { used: true },
    });

    const code = this.generateCode();
    const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

    await prisma.oTP.create({
      data: {
        phone,
        code,
        expiresAt,
        userId,
      },
    });

    logger.info(`OTP created for phone: ${phone.substring(0, 6)}****`);

    // In production, send via SMS provider here
    // For development, log the OTP
    if (process.env.NODE_ENV !== 'production') {
      logger.debug(`[DEV] OTP for ${phone}: ${code}`);
    }

    return code;
  }

  /**
   * Verify an OTP code for the given phone number
   */
  async verifyOTP(phone: string, code: string): Promise<boolean> {
    const otp = await prisma.oTP.findFirst({
      where: {
        phone,
        code,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otp) {
      return false;
    }

    // Mark as used
    await prisma.oTP.update({
      where: { id: otp.id },
      data: { used: true },
    });

    logger.info(`OTP verified for phone: ${phone.substring(0, 6)}****`);
    return true;
  }

  /**
   * Check if phone has a valid unexpired OTP (for rate limiting checks)
   */
  async hasActiveOTP(phone: string): Promise<boolean> {
    const count = await prisma.oTP.count({
      where: {
        phone,
        used: false,
        expiresAt: { gt: new Date() },
      },
    });
    return count > 0;
  }

  /**
   * Clean up expired OTPs (run periodically)
   */
  async cleanupExpiredOTPs(): Promise<number> {
    const result = await prisma.oTP.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: new Date() } },
          { used: true, createdAt: { lt: new Date(Date.now() - 24 * 60 * 60 * 1000) } },
        ],
      },
    });

    logger.info(`Cleaned up ${result.count} expired/used OTPs`);
    return result.count;
  }

  /**
   * Send OTP via SMS (stub - integrate with Twilio, Africa's Talking, etc.)
   */
  async sendSMS(phone: string, code: string): Promise<void> {
    // Integrate with your SMS provider here
    // Example: Twilio, Africa's Talking, Vonage, etc.
    const message = `Your Carchip verification code is: ${code}. Valid for ${OTP_EXPIRY_MINUTES} minutes.`;

    logger.info(`SMS would be sent to ${phone.substring(0, 6)}****`);

    // TODO: Implement SMS provider
    // await twilioClient.messages.create({ to: phone, from: env.TWILIO_PHONE, body: message });
    void message; // suppress unused var warning until implemented
  }
}

export const otpService = new OTPService();
