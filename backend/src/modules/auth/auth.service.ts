import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { generateTokenPair, verifyRefreshToken } from '../../utils/jwt';
import { otpService } from '../../services/otp/otp.service';
import { logger } from '../../utils/logger';
import {
  AppError,
  ConflictError,
  NotFoundError,
  UnauthorizedError,
} from '../../middleware/error.middleware';
import type {
  RegisterDto,
  LoginDto,
  PhoneLoginDto,
  VerifyOTPDto,
  RefreshTokenDto,
} from './auth.schema';

const BCRYPT_ROUNDS = 12;
const BLACKLIST_PREFIX = 'token:blacklist:';

class AuthService {
  /**
   * Register a new user with email/password
   */
  async register(dto: RegisterDto) {
    const existingUser = await prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser) {
      throw new ConflictError('User with this email already exists');
    }

    if (dto.phone) {
      const existingPhone = await prisma.user.findUnique({
        where: { phone: dto.phone },
      });
      if (existingPhone) {
        throw new ConflictError('User with this phone number already exists');
      }
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        name: dto.name,
        email: dto.email,
        phone: dto.phone,
        passwordHash,
        isVerified: false,
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isVerified: true,
        createdAt: true,
      },
    });

    const tokens = generateTokenPair(user);

    // Store refresh token hash
    const refreshTokenHash = await bcrypt.hash(tokens.refreshToken, 10);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken: refreshTokenHash },
    });

    logger.info(`New user registered: ${user.email}`);

    return { user, ...tokens };
  }

  /**
   * Login with email and password
   */
  async login(dto: LoginDto) {
    const user = await prisma.user.findUnique({
      where: { email: dto.email },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        passwordHash: true,
        isVerified: true,
        createdAt: true,
      },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedError('Invalid email or password');
    }

    const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedError('Invalid email or password');
    }

    const tokens = generateTokenPair(user);

    // Store refresh token hash
    const refreshTokenHash = await bcrypt.hash(tokens.refreshToken, 10);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken: refreshTokenHash },
    });

    logger.info(`User logged in: ${user.email}`);

    const { passwordHash: _, ...userWithoutPassword } = user;
    return { user: userWithoutPassword, ...tokens };
  }

  /**
   * Initiate phone login by sending OTP
   */
  async phoneLogin(dto: PhoneLoginDto): Promise<void> {
    // Find or create user with this phone
    let user = await prisma.user.findUnique({
      where: { phone: dto.phone },
    });

    const code = await otpService.createOTP(dto.phone, user?.id);
    await otpService.sendSMS(dto.phone, code);

    logger.info(`OTP sent to phone: ${dto.phone.substring(0, 6)}****`);
  }

  /**
   * Verify OTP and issue tokens
   */
  async verifyOTP(dto: VerifyOTPDto) {
    const isValid = await otpService.verifyOTP(dto.phone, dto.code);

    if (!isValid) {
      throw new UnauthorizedError('Invalid or expired OTP');
    }

    // Find or create user
    let user = await prisma.user.findUnique({
      where: { phone: dto.phone },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isVerified: true,
        createdAt: true,
      },
    });

    const isNewUser = !user;

    if (!user) {
      user = await prisma.user.create({
        data: {
          name: `User ${dto.phone.slice(-4)}`,
          email: `${dto.phone.replace(/\+/g, '')}@phone.carchip.local`,
          phone: dto.phone,
          isVerified: true,
        },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
          isVerified: true,
          createdAt: true,
        },
      });
    } else if (!user.isVerified) {
      await prisma.user.update({
        where: { id: user.id },
        data: { isVerified: true },
      });
      user = { ...user, isVerified: true };
    }

    const tokens = generateTokenPair(user);

    const refreshTokenHash = await bcrypt.hash(tokens.refreshToken, 10);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken: refreshTokenHash },
    });

    return { user, isNewUser, ...tokens };
  }

  /**
   * Refresh access token using refresh token
   */
  async refreshToken(dto: RefreshTokenDto) {
    let decoded;
    try {
      decoded = verifyRefreshToken(dto.refreshToken);
    } catch {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        role: true,
        refreshToken: true,
        isVerified: true,
      },
    });

    if (!user || !user.refreshToken) {
      throw new UnauthorizedError('Refresh token not found');
    }

    // Verify the stored refresh token matches
    const tokenValid = await bcrypt.compare(dto.refreshToken, user.refreshToken);
    if (!tokenValid) {
      throw new UnauthorizedError('Refresh token mismatch');
    }

    // Check if token is blacklisted
    const isBlacklisted = await redis.exists(`${BLACKLIST_PREFIX}${dto.refreshToken.substring(0, 20)}`);
    if (isBlacklisted) {
      throw new UnauthorizedError('Token has been revoked');
    }

    const tokens = generateTokenPair({
      id: user.id,
      email: user.email,
      role: user.role,
    });

    // Rotate refresh token
    const newRefreshHash = await bcrypt.hash(tokens.refreshToken, 10);
    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken: newRefreshHash },
    });

    return tokens;
  }

  /**
   * Logout: invalidate refresh token
   */
  async logout(userId: string, refreshToken?: string): Promise<void> {
    // Clear stored refresh token
    await prisma.user.update({
      where: { id: userId },
      data: { refreshToken: null },
    });

    // Blacklist the refresh token for 7 days
    if (refreshToken) {
      const key = `${BLACKLIST_PREFIX}${refreshToken.substring(0, 20)}`;
      await redis.set(key, '1', 7 * 24 * 60 * 60);
    }

    logger.info(`User logged out: ${userId}`);
  }
}

export const authService = new AuthService();
