import {
  type CanActivate,
  type ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import type { AuthenticatedRequest, AuthRole } from "../auth.types.js";
import { ROLES } from "../decorators.js";

/** Run after JwtAuthGuard. Allows the route when the user has one of the @Roles(...) roles. */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<AuthRole[] | undefined>(ROLES, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!roles?.length) return true;
    const { user } = context.switchToHttp().getRequest<Partial<AuthenticatedRequest>>();
    if (!user) {
      throw new UnauthorizedException({
        code: "UNAUTHORIZED",
        message: "Authentication is required.",
      });
    }
    if (!roles.includes(user.role)) {
      throw new ForbiddenException({
        code: "FORBIDDEN",
        message: "You do not have access to this resource.",
      });
    }
    return true;
  }
}
