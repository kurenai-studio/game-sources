import { createHash, randomBytes } from "node:crypto";
import { Injectable, UnauthorizedException } from "@nestjs/common";
import { errors, jwtVerify, SignJWT } from "jose";
import { AppConfig } from "../../core/config/app-config.js";

const ISSUER = "algomind-api";

export type AccessClaims = { userId: string; role: string };

/** Signs and verifies access tokens, and makes and hashes opaque refresh tokens. */
@Injectable()
export class TokenService {
  private readonly key: Uint8Array;

  constructor(private readonly config: AppConfig) {
    this.key = new TextEncoder().encode(config.jwtAccessSecret);
  }

  get accessTtlSeconds(): number {
    return this.config.accessTokenTtlSeconds;
  }

  get refreshTtlMs(): number {
    return this.config.refreshTokenTtlDays * 86_400_000;
  }

  /** `now` is a parameter so tests can mint an already-expired token. */
  signAccessToken(claims: AccessClaims, now: Date = new Date()): Promise<string> {
    const issuedAt = Math.floor(now.getTime() / 1000);
    return new SignJWT({ role: claims.role })
      .setProtectedHeader({ alg: "HS256" })
      .setSubject(claims.userId)
      .setIssuer(ISSUER)
      .setIssuedAt(issuedAt)
      .setExpirationTime(issuedAt + this.config.accessTokenTtlSeconds)
      .sign(this.key);
  }

  /** The user id the token was issued for. Throws 401 for anything invalid or expired. */
  async verifyAccessToken(token: string): Promise<string> {
    try {
      const { payload } = await jwtVerify(token, this.key, {
        algorithms: ["HS256"],
        issuer: ISSUER,
      });
      if (!payload.sub) throw new Error("missing subject");
      return payload.sub;
    } catch (error) {
      if (error instanceof errors.JWTExpired) {
        throw new UnauthorizedException({
          code: "TOKEN_EXPIRED",
          message: "The access token has expired.",
        });
      }
      throw new UnauthorizedException({
        code: "UNAUTHORIZED",
        message: "Authentication is required.",
      });
    }
  }

  /** 32 random bytes, URL-safe. Only its hash is ever stored. */
  newRefreshToken(): string {
    return randomBytes(32).toString("base64url");
  }

  hashRefreshToken(token: string): string {
    return createHash("sha256").update(token).digest("hex");
  }
}
