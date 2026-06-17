import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import {
  AppError,
  ConflictError,
  NotFoundError,
  UnauthorizedError,
} from '../../middleware/error.middleware';
import { logger } from '../../utils/logger';
import type { UpdateProfileDto, ChangePasswordDto } from './users.schema';

class UsersService {
  /**
   * Get user by ID
   */
  async getUserById(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        isVerified: true,
        fcmToken: true,
        createdAt: true,
        updatedAt: true,
        _count: {
          select: {
            vehicles: true,
            devices: true,
            alerts: { where: { read: false } },
          },
        },
      },
    });

    if (!user) throw new NotFoundError('User');
    return user;
  }

  /**
   * Update user profile
   */
  async updateProfile(userId: string, dto: UpdateProfileDto) {
    if (dto.phone) {
      const existingPhone = await prisma.user.findFirst({
        where: {
          phone: dto.phone,
          NOT: { id: userId },
        },
      });
      if (existingPhone) {
        throw new ConflictError('Phone number already in use');
      }
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.phone && { phone: dto.phone }),
        ...(dto.avatarUrl && { avatarUrl: dto.avatarUrl }),
        ...(dto.fcmToken !== undefined && { fcmToken: dto.fcmToken }),
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        isVerified: true,
        fcmToken: true,
        updatedAt: true,
      },
    });

    return updated;
  }

  /**
   * Change password
   */
  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true },
    });

    if (!user || !user.passwordHash) {
      throw new AppError('No password set for this account', 400);
    }

    const currentPasswordValid = await bcrypt.compare(
      dto.currentPassword,
      user.passwordHash
    );

    if (!currentPasswordValid) {
      throw new UnauthorizedError('Current password is incorrect');
    }

    const newPasswordHash = await bcrypt.hash(dto.newPassword, 12);

    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: newPasswordHash,
        refreshToken: null, // Force re-login on all devices
      },
    });

    logger.info(`Password changed for user: ${userId}`);
  }

  /**
   * Update FCM token for push notifications
   */
  async updateFCMToken(userId: string, fcmToken: string) {
    return prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
      select: { id: true, fcmToken: true },
    });
  }

  /**
   * Delete user account and all associated data
   */
  async deleteAccount(userId: string, password: string): Promise<void> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true, email: true },
    });

    if (!user) throw new NotFoundError('User');

    if (user.passwordHash) {
      const passwordValid = await bcrypt.compare(password, user.passwordHash);
      if (!passwordValid) {
        throw new UnauthorizedError('Password is incorrect');
      }
    }

    // Cascade delete will handle related records
    await prisma.user.delete({ where: { id: userId } });
    logger.info(`Account deleted for user: ${userId}`);
  }

  /**
   * Get all users (admin only)
   */
  async getAllUsers(page: number, limit: number, search?: string) {
    const skip = (page - 1) * limit;

    const where = search
      ? {
          OR: [
            { name: { contains: search, mode: 'insensitive' as const } },
            { email: { contains: search, mode: 'insensitive' as const } },
            { phone: { contains: search } },
          ],
        }
      : {};

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
          isVerified: true,
          createdAt: true,
          _count: {
            select: { vehicles: true, devices: true },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.user.count({ where }),
    ]);

    return { users, total };
  }
}

export const usersService = new UsersService();
