import type { Request } from "express";

export type AuthRole = "ADMIN" | "PLAYER";

/** What clients see about the signed-in user. */
export type AuthUser = {
  id: string;
  email: string;
  role: AuthRole;
  mustChangePassword: boolean;
};

export type AuthSession = {
  accessToken: string;
  refreshToken: string;
  /** Access token lifetime in seconds. */
  expiresIn: number;
  user: AuthUser;
};

/** The request after JwtAuthGuard has run. */
export type AuthenticatedRequest = Request & { user: AuthUser };
