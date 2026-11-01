import { SetMetadata } from "@nestjs/common";
import type { AuthRole } from "./auth.types.js";

export const IS_PUBLIC = "auth:public";
export const ROLES = "auth:roles";
export const ALLOW_PASSWORD_CHANGE = "auth:allow-password-change";

/** Skips JwtAuthGuard. Only matters if that guard is ever registered globally. */
export const Public = () => SetMetadata(IS_PUBLIC, true);

/** Roles RolesGuard accepts for the route. */
export const Roles = (...roles: AuthRole[]) => SetMetadata(ROLES, roles);

/** Lets an admin who still has to change the password use this route (AdminGuard). */
export const AllowPasswordChange = () => SetMetadata(ALLOW_PASSWORD_CHANGE, true);
