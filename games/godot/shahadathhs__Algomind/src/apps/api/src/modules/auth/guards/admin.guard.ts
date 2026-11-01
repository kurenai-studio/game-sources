import {
  type CanActivate,
  type ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import type { AuthenticatedRequest } from "../auth.types.js";
import { ALLOW_PASSWORD_CHANGE } from "../decorators.js";

/**
 * For /v1/admin/*: use as `@UseGuards(JwtAuthGuard, AdminGuard)`. Requires the ADMIN role, and
 * refuses with PASSWORD_CHANGE_REQUIRED while the seeded password has not been changed.
 */
@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const { user } = context.switchToHttp().getRequest<Partial<AuthenticatedRequest>>();
    if (!user) {
      throw new UnauthorizedException({
        code: "UNAUTHORIZED",
        message: "Authentication is required.",
      });
    }
    if (user.role !== "ADMIN") {
      throw new ForbiddenException({
        code: "FORBIDDEN",
        message: "You do not have access to this resource.",
      });
    }
    const allowed = this.reflector.getAllAndOverride<boolean>(ALLOW_PASSWORD_CHANGE, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (user.mustChangePassword && !allowed) {
      throw new ForbiddenException({
        code: "PASSWORD_CHANGE_REQUIRED",
        message: "Change the password before using the dashboard.",
      });
    }
    return true;
  }
}
