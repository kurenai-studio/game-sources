import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { defineConfig } from "prisma/config";

// Prisma does not read .env itself. Load the repository's .env when it exists (local development);
// in CI and containers DATABASE_URL comes from the environment.
const envFile = resolve(process.cwd(), "../../.env");
if (existsSync(envFile)) process.loadEnvFile(envFile);

// `prisma generate` does not connect, so a placeholder without credentials keeps it working
// where no database is configured (type checks, image builds).
export default defineConfig({
  schema: "prisma/schema",
  migrations: { path: "prisma/migrations" },
  datasource: {
    url: process.env.DATABASE_URL ?? "postgresql://algomind@localhost:5432/algomind",
  },
});
