import { Body, Controller, Get, HttpCode, Post, Req, UseGuards } from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from "@nestjs/swagger";
import type { Request } from "express";
import {
  AuthSessionResponse,
  AuthUserResponse,
  ChangePasswordBody,
  changePasswordSchema,
  LoginBody,
  loginSchema,
  parseBody,
  RegisterBody,
  registerSchema,
  RefreshBody,
  refreshSchema,
} from "./auth.dto.js";
import { AuthService, normalizeEmail } from "./auth.service.js";
import type { AuthenticatedRequest, AuthSession, AuthUser } from "./auth.types.js";
import { JwtAuthGuard } from "./guards/jwt-auth.guard.js";
import { RateLimiter, tooManyRequests } from "./rate-limiter.js";

const WINDOW_MS = 15 * 60 * 1000;

@ApiTags("auth")
@Controller("auth")
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly limiter: RateLimiter,
  ) {}

  @Post("register")
  @HttpCode(201)
  @ApiOperation({
    summary: "Create a player account and sign in.",
    description: "Accounts are optional: the game is fully playable without one.",
  })
  @ApiResponse({ status: 201, type: AuthSessionResponse })
  @ApiResponse({ status: 409, description: "An account with this email already exists." })
  @ApiResponse({ status: 422, description: "The email is not valid or the password is too weak." })
  @ApiResponse({ status: 429, description: "Too many attempts; see Retry-After." })
  register(@Body() body: RegisterBody, @Req() req: Request): Promise<AuthSession> {
    this.limit(`register:${req.ip}`, 10); // before validating, so bad payloads are throttled too
    const { email, password } = parseBody(registerSchema, body);
    return this.auth.register(email, password);
  }

  @Post("login")
  @HttpCode(200)
  @ApiOperation({ summary: "Sign in with email and password." })
  @ApiOkResponse({ type: AuthSessionResponse })
  @ApiResponse({ status: 401, description: "The email or password is incorrect." })
  @ApiResponse({ status: 429, description: "Too many attempts; see Retry-After." })
  async login(@Body() body: LoginBody, @Req() req: Request): Promise<AuthSession> {
    const { email, password } = parseBody(loginSchema, body);
    const normalized = normalizeEmail(email);
    this.limit(`login:${req.ip}:${normalized}`, 10);
    this.limit(`login-ip:${req.ip}`, 60);
    const session = await this.auth.login(normalized, password);
    this.limiter.reset(`login:${req.ip}:${normalized}`);
    return session;
  }

  @Post("refresh")
  @HttpCode(200)
  @ApiOperation({
    summary: "Exchange a refresh token for a new pair (rotation).",
    description:
      "The presented token is revoked. Presenting an already-used token revokes the whole session family.",
  })
  @ApiOkResponse({ type: AuthSessionResponse })
  @ApiResponse({ status: 401, description: "The refresh token is unknown, expired, or reused." })
  @ApiResponse({ status: 429, description: "Too many attempts; see Retry-After." })
  refresh(@Body() body: RefreshBody, @Req() req: Request): Promise<AuthSession> {
    const { refreshToken } = parseBody(refreshSchema, body);
    this.limit(`refresh:${req.ip}`, 60);
    return this.auth.refresh(refreshToken);
  }

  @Post("logout")
  @HttpCode(204)
  @ApiOperation({ summary: "Revoke the refresh token's session. Idempotent." })
  @ApiNoContentResponse({ description: "The session is revoked (or already was)." })
  async logout(@Body() body: RefreshBody): Promise<void> {
    const { refreshToken } = parseBody(refreshSchema, body);
    await this.auth.logout(refreshToken);
  }

  @Post("change-password")
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: "Change the password and start a fresh session.",
    description:
      "Revokes every other refresh token of the user and clears mustChangePassword. " +
      "A wrong current password is 422, not 401.",
  })
  @ApiOkResponse({ type: AuthSessionResponse })
  @ApiResponse({ status: 401, description: "Missing, invalid, or expired access token." })
  @ApiResponse({ status: 422, description: "Wrong current password or a weak new password." })
  @ApiResponse({ status: 429, description: "Too many attempts; see Retry-After." })
  changePassword(
    @Body() body: ChangePasswordBody,
    @Req() req: AuthenticatedRequest,
  ): Promise<AuthSession> {
    const { currentPassword, newPassword } = parseBody(changePasswordSchema, body);
    this.limit(`password:${req.user.id}:${req.ip}`, 10);
    return this.auth.changePassword(req.user.id, currentPassword, newPassword);
  }

  @Get("me")
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "The signed-in user." })
  @ApiOkResponse({ type: AuthUserResponse })
  @ApiResponse({ status: 401, description: "Missing, invalid, or expired access token." })
  me(@Req() req: AuthenticatedRequest): AuthUser {
    return req.user;
  }

  private limit(key: string, max: number): void {
    const result = this.limiter.hit(key, max, WINDOW_MS);
    if (!result.allowed) throw tooManyRequests(result.retryAfterSeconds);
  }
}
