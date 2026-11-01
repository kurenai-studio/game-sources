import {
  type CanActivate,
  type ExecutionContext,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { PrismaService } from "../../../core/prisma/prisma.service.js";
import { accountSuspended, toAuthUser } from "../auth.service.js";
import type { AuthenticatedRequest } from "../auth.types.js";
import { IS_PUBLIC } from "../decorators.js";
import { TokenService } from "../token.service.js";

/**
 * Requires a valid `Authorization: Bearer` access token and attaches the current user to the
 * request. The user is read from the database on every request, so a password change or a
 * removed account takes effect at once instead of when the token expires.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly tokens: TokenService,
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (
      this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [
        context.getHandler(),
        context.getClass(),
      ])
    ) {
      return true;
    }
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const header = request.headers.authorization;
    const match = typeof header === "string" ? /^Bearer (\S+)$/.exec(header) : null;
    if (!match?.[1]) {
      throw new UnauthorizedException({
        code: "UNAUTHORIZED",
        message: "Authentication is required.",
      });
    }
    const userId = await this.tokens.verifyAccessToken(match[1]);
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new UnauthorizedException({
        code: "UNAUTHORIZED",
        message: "Authentication is required.",
      });
    }
    if (user.status === "SUSPENDED") throw accountSuspended();
    request.user = toAuthUser(user);
    return true;
  }
}
