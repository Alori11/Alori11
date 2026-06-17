import jwt, { SignOptions, JwtPayload } from 'jsonwebtoken';
import { env } from '../config/env';

export interface TokenPayload {
  userId: string;
  email: string;
  role: string;
}

export interface RefreshTokenPayload {
  userId: string;
}

export interface DecodedToken extends JwtPayload, TokenPayload {}

export const signAccessToken = (payload: TokenPayload): string => {
  const options: SignOptions = {
    expiresIn: env.JWT_EXPIRES_IN as string,
    algorithm: 'HS256',
    issuer: 'carchip-api',
    audience: 'carchip-client',
  };
  return jwt.sign(payload, env.JWT_SECRET, options);
};

export const signRefreshToken = (payload: RefreshTokenPayload): string => {
  const options: SignOptions = {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN as string,
    algorithm: 'HS256',
    issuer: 'carchip-api',
    audience: 'carchip-client',
  };
  return jwt.sign(payload, env.JWT_REFRESH_SECRET, options);
};

export const verifyAccessToken = (token: string): DecodedToken => {
  return jwt.verify(token, env.JWT_SECRET, {
    issuer: 'carchip-api',
    audience: 'carchip-client',
  }) as DecodedToken;
};

export const verifyRefreshToken = (token: string): RefreshTokenPayload & JwtPayload => {
  return jwt.verify(token, env.JWT_REFRESH_SECRET, {
    issuer: 'carchip-api',
    audience: 'carchip-client',
  }) as RefreshTokenPayload & JwtPayload;
};

export const decodeToken = (token: string): DecodedToken | null => {
  try {
    return jwt.decode(token) as DecodedToken;
  } catch {
    return null;
  }
};

export const generateTokenPair = (
  user: { id: string; email: string; role: string }
): { accessToken: string; refreshToken: string } => {
  const accessToken = signAccessToken({
    userId: user.id,
    email: user.email,
    role: user.role,
  });

  const refreshToken = signRefreshToken({ userId: user.id });

  return { accessToken, refreshToken };
};
