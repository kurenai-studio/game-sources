import { Module } from "@nestjs/common";
import { AdminSeedService } from "./admin-seed.service.js";
import { AuthController } from "./auth.controller.js";
import { AuthService } from "./auth.service.js";
import { AdminGuard } from "./guards/admin.guard.js";
import { JwtAuthGuard } from "./guards/jwt-auth.guard.js";
import { RolesGuard } from "./guards/roles.guard.js";
import { PasswordService } from "./password.service.js";
import { RateLimiter } from "./rate-limiter.js";
import { TokenService } from "./token.service.js";

/**
 * Import this module to protect routes: `@UseGuards(JwtAuthGuard, AdminGuard)` for admin routes,
 * or `@UseGuards(JwtAuthGuard, RolesGuard)` with `@Roles(...)`. No guard is registered globally.
 */
@Module({
  controllers: [AuthController],
  providers: [
    AuthService,
    PasswordService,
    TokenService,
    RateLimiter,
    AdminSeedService,
    JwtAuthGuard,
    RolesGuard,
    AdminGuard,
  ],
  exports: [TokenService, PasswordService, RateLimiter, JwtAuthGuard, RolesGuard, AdminGuard],
})
export class AuthModule {}
export { AdminGuard, JwtAuthGuard, RolesGuard };
export { AllowPasswordChange, Public, Roles } from "./decorators.js";
export type { AuthenticatedRequest, AuthRole, AuthUser } from "./auth.types.js";
