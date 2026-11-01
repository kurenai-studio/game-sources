import { UnprocessableEntityException } from "@nestjs/common";
import { ApiProperty } from "@nestjs/swagger";
import { z } from "zod";
import { MAX_PASSWORD_LENGTH } from "./password-policy.js";
import type { AuthRole } from "./auth.types.js";

// Request bodies are validated with zod; the classes below only describe them for OpenAPI.
export const loginSchema = z.object({
  email: z.string().min(1).max(254),
  password: z.string().min(1).max(MAX_PASSWORD_LENGTH),
});
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
export const registerSchema = z.object({
  email: z.string().trim().min(3).max(254).regex(EMAIL_PATTERN, "must be an email address"),
  password: z.string().max(MAX_PASSWORD_LENGTH),
});
export const refreshSchema = z.object({ refreshToken: z.string().min(1).max(512) });
export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1).max(MAX_PASSWORD_LENGTH),
  newPassword: z.string().max(MAX_PASSWORD_LENGTH),
});

/** Parses a request body or throws 422 in the standard error format with field-level issues. */
export function parseBody<T>(schema: z.ZodType<T>, body: unknown): T {
  const parsed = schema.safeParse(body);
  if (parsed.success) return parsed.data;
  throw new UnprocessableEntityException({
    code: "VALIDATION_FAILED",
    message: "The request body is invalid.",
    issues: parsed.error.issues.map((issue) => ({
      path: issue.path.join("."),
      code: issue.code.toUpperCase(),
      message: issue.message,
    })),
  });
}

export class LoginBody {
  @ApiProperty({ example: "admin@example.com" })
  email!: string;
  @ApiProperty()
  password!: string;
}

export class RegisterBody {
  @ApiProperty({ example: "player@example.com" })
  email!: string;
  @ApiProperty({ description: "At least 12 characters." })
  password!: string;
}

export class RefreshBody {
  @ApiProperty()
  refreshToken!: string;
}

export class ChangePasswordBody {
  @ApiProperty()
  currentPassword!: string;
  @ApiProperty({ description: "At least 12 characters, different from the current password." })
  newPassword!: string;
}

export class AuthUserResponse {
  @ApiProperty()
  id!: string;
  @ApiProperty()
  email!: string;
  @ApiProperty({ enum: ["ADMIN", "PLAYER"] })
  role!: AuthRole;
  @ApiProperty()
  mustChangePassword!: boolean;
}

export class AuthSessionResponse {
  @ApiProperty({ description: "Signed JWT, sent as `Authorization: Bearer <token>`." })
  accessToken!: string;
  @ApiProperty({ description: "Opaque; single use. Send it to /auth/refresh for a new pair." })
  refreshToken!: string;
  @ApiProperty({ description: "Access token lifetime in seconds." })
  expiresIn!: number;
  @ApiProperty({ type: AuthUserResponse })
  user!: AuthUserResponse;
}
