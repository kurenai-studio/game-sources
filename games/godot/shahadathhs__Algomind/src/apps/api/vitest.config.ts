import { defineConfig } from "vitest/config";

// Unit tests of the rules that must not break: publish gates, authorization, sessions, and the
// progress merge. They need no database; real PostgreSQL behavior is checked by the CI job that
// applies the migrations to an empty database and boots the API.
export default defineConfig({
  // The seed tests run the exact solver on every campaign level; a CI runner is slower than a laptop.
  test: { include: ["test/**/*.test.ts"], environment: "node", testTimeout: 60_000 },
});
