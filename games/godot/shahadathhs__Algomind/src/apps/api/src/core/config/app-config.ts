import { type Env, loadEnv } from "./env.js";

/** Typed, validated configuration. Injected wherever settings are needed. */
export class AppConfig {
  readonly nodeEnv: Env["nodeEnv"];
  readonly port: number;
  readonly databaseUrl: string;
  readonly corsOrigins: string[];
  readonly jwtAccessSecret: string;
  readonly accessTokenTtlSeconds: number;
  readonly refreshTokenTtlDays: number;
  readonly superAdminEmail?: string;
  readonly superAdminPass?: string;
  readonly trustProxy: number;
  readonly seedStarterCampaign: "always" | "when-empty" | "never";
  readonly webRevalidateUrl?: string;
  readonly revalidateSecret?: string;
  readonly contact: Env["contact"];

  constructor(env: Env) {
    this.nodeEnv = env.nodeEnv;
    this.port = env.port;
    this.databaseUrl = env.databaseUrl;
    this.corsOrigins = env.corsOrigins;
    this.jwtAccessSecret = env.jwtAccessSecret;
    this.accessTokenTtlSeconds = env.accessTokenTtlSeconds;
    this.refreshTokenTtlDays = env.refreshTokenTtlDays;
    this.superAdminEmail = env.superAdminEmail;
    this.superAdminPass = env.superAdminPass;
    this.trustProxy = env.trustProxy;
    this.seedStarterCampaign = env.seedStarterCampaign;
    this.webRevalidateUrl = env.webRevalidateUrl;
    this.contact = env.contact;
    this.revalidateSecret = env.revalidateSecret;
  }

  static fromEnvironment(): AppConfig {
    return new AppConfig(loadEnv());
  }
}
