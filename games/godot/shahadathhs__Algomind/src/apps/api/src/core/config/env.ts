import { z } from "zod";

/** Fixed signing key for development and tests only. Production must set its own (see the refine below). */
const DEV_JWT_SECRET = "algomind-development-only-signing-key-not-secret";

const schema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    PORT: z.coerce.number().int().min(1).max(65535).default(8000),
    DATABASE_URL: z
      .string({ error: "is required (run `make env` for local development)" })
      .min(1, "is required (run `make env` for local development)"),
    CORS_ORIGINS: z.string().default("http://localhost:3000"),
    JWT_ACCESS_SECRET: z.string().min(32, "must be at least 32 characters").optional(),
    ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().min(60).max(86_400).default(900),
    REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().min(1).max(90).default(7),
    SUPER_ADMIN_EMAIL: z.string().trim().min(1).optional(),
    SUPER_ADMIN_PASS: z.string().min(1).optional(),
    // Number of reverse proxies in front of the API (1 on Render); 0 means clients connect directly.
    // Create the starter campaign (4 worlds, 5 chapters, 19 published levels) on startup: true always
    // adds what is missing, false never does. Unset: always outside production, and in production
    // only while the database has no levels at all (so a fresh install is playable).
    SEED_STARTER_CAMPAIGN: z.enum(["true", "false", "1", "0"]).optional(),
    TRUST_PROXY: z.coerce.number().int().min(0).max(10).default(0),
    // Tell the web app to refresh its public pages after a publish or unpublish. Both are needed.
    WEB_REVALIDATE_URL: z.url().optional(),
    REVALIDATE_SECRET: z.string().min(16, "must be at least 16 characters").optional(),
    // The contact details the contact page starts with, used once while the stored row does not exist.
    // After that the dashboard's Contact page is the place to change them. All optional.
    CONTACT_NAME: z.string().trim().max(80).optional(),
    CONTACT_EMAIL: z.string().trim().max(120).optional(),
    CONTACT_GITHUB: z.string().trim().max(200).optional(),
    CONTACT_WEBSITE: z.string().trim().max(200).optional(),
    CONTACT_ISSUES: z.string().trim().max(200).optional(),
  })
  .refine((e) => e.NODE_ENV !== "production" || e.JWT_ACCESS_SECRET !== undefined, {
    path: ["JWT_ACCESS_SECRET"],
    message: "is required in production (at least 32 characters)",
  });

export type Env = {
  nodeEnv: "development" | "test" | "production";
  port: number;
  databaseUrl: string;
  corsOrigins: string[];
  jwtAccessSecret: string;
  accessTokenTtlSeconds: number;
  refreshTokenTtlDays: number;
  superAdminEmail?: string;
  superAdminPass?: string;
  trustProxy: number;
  seedStarterCampaign: "always" | "when-empty" | "never";
  webRevalidateUrl?: string;
  revalidateSecret?: string;
  /** The contact details to seed the first time; fields that are not set stay empty. */
  contact: { name?: string; email?: string; github?: string; website?: string; issues?: string };
};

/** Parses and validates the environment. Throws a readable error on bad configuration. */
export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  // An empty value (`NAME=` in .env) counts as unset.
  const cleaned = Object.fromEntries(Object.entries(source).filter(([, v]) => v !== ""));
  const parsed = schema.safeParse(cleaned);
  if (!parsed.success) {
    const problems = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Invalid environment: ${problems}`);
  }
  const d = parsed.data;
  return {
    nodeEnv: d.NODE_ENV,
    port: d.PORT,
    databaseUrl: d.DATABASE_URL,
    corsOrigins: d.CORS_ORIGINS.split(",")
      .map((o) => o.trim())
      .filter(Boolean),
    jwtAccessSecret: d.JWT_ACCESS_SECRET ?? DEV_JWT_SECRET,
    accessTokenTtlSeconds: d.ACCESS_TOKEN_TTL_SECONDS,
    refreshTokenTtlDays: d.REFRESH_TOKEN_TTL_DAYS,
    superAdminEmail: d.SUPER_ADMIN_EMAIL,
    superAdminPass: d.SUPER_ADMIN_PASS,
    trustProxy: d.TRUST_PROXY,
    webRevalidateUrl: d.WEB_REVALIDATE_URL,
    revalidateSecret: d.REVALIDATE_SECRET,
    contact: {
      name: d.CONTACT_NAME,
      email: d.CONTACT_EMAIL,
      github: d.CONTACT_GITHUB,
      website: d.CONTACT_WEBSITE,
      issues: d.CONTACT_ISSUES,
    },
    seedStarterCampaign:
      d.SEED_STARTER_CAMPAIGN === undefined
        ? d.NODE_ENV === "production"
          ? "when-empty"
          : "always"
        : d.SEED_STARTER_CAMPAIGN === "true" || d.SEED_STARTER_CAMPAIGN === "1"
          ? "always"
          : "never",
  };
}
