import { AppConfig } from "../../src/core/config/app-config.js";
import { loadEnv } from "../../src/core/config/env.js";
import { AuthService } from "../../src/modules/auth/auth.service.js";
import { PasswordService } from "../../src/modules/auth/password.service.js";
import { TokenService } from "../../src/modules/auth/token.service.js";
import { FakeDb } from "./fake-db.js";

/** A throwaway signing key made for the run; never a real secret. */
const TEST_SECRET = `test-${Math.random().toString(36).slice(2)}-${"x".repeat(40)}`;

export function makeAuth() {
  const config = new AppConfig(
    loadEnv({
      NODE_ENV: "test",
      DATABASE_URL: "postgresql://unused",
      JWT_ACCESS_SECRET: TEST_SECRET,
    }),
  );
  const db = new FakeDb();
  const passwords = new PasswordService();
  const tokens = new TokenService(config);
  const auth = new AuthService(db.asPrisma(), passwords, tokens);
  return { db, passwords, tokens, auth };
}

/** A password that passes the policy, made fresh for each use. */
export const goodPassword = () => `pw-${Math.random().toString(36).slice(2)}-long-enough`;
