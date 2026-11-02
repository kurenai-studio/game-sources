import { defineConfig } from "vite";

const repo = "sir-flaps-a-lot";

export default defineConfig({
  base: process.env.GITHUB_ACTIONS === "true" ? `/${repo}/` : "/",
});
