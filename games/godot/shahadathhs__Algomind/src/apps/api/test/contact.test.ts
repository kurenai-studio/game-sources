import { describe, expect, it } from "vitest";
import { AppConfig } from "../src/core/config/app-config.js";
import { loadEnv } from "../src/core/config/env.js";
import { contactInputSchema } from "../src/modules/contact/contact.schemas.js";
import { contactSeed } from "../src/modules/contact/contact.defaults.js";

const base = {
  NODE_ENV: "test",
  DATABASE_URL: "postgresql://u:p@localhost:5432/db",
  JWT_ACCESS_SECRET: "x".repeat(40),
};

describe("the contact details", () => {
  it("start from the CONTACT_* settings and hold nothing else", () => {
    const config = new AppConfig(
      loadEnv({
        ...base,
        CONTACT_NAME: "Ada Lovelace",
        CONTACT_EMAIL: "ada@example.com",
        CONTACT_GITHUB: "https://github.com/ada",
      }),
    );
    expect(contactSeed(config)).toEqual({
      displayName: "Ada Lovelace",
      email: "ada@example.com",
      github: "https://github.com/ada",
      website: "",
      issues: "",
      note: "",
    });
  });

  it("start with a neutral name and no address when nothing is set", () => {
    const seed = contactSeed(new AppConfig(loadEnv(base)));
    expect(seed.displayName).toBe("The Algomind developer");
    expect([seed.email, seed.github, seed.website, seed.issues]).toEqual(["", "", "", ""]);
  });

  it("accept a full edit, trimmed, and empty optional fields", () => {
    const parsed = contactInputSchema.parse({
      displayName: "  Ada  ",
      email: "ada@example.com",
      github: "https://github.com/ada",
      website: "",
      issues: "",
      note: "",
    });
    expect(parsed.displayName).toBe("Ada");
    expect(contactInputSchema.safeParse({ ...parsed, email: "" }).success).toBe(true);
  });

  it.each([
    ["a missing name", { displayName: "" }],
    ["an email without an at sign", { email: "ada.example.com" }],
    ["a plain http link", { website: "http://example.com" }],
    ["a script link", { github: "javascript:alert(1)" }],
    ["a link with spaces", { website: "https://exa mple.com" }],
    ["an unknown field", { phone: "123" }],
    ["a long note", { note: "x".repeat(281) }],
  ])("refuse %s", (_label, patch) => {
    const valid = {
      displayName: "Ada",
      email: "",
      github: "",
      website: "",
      issues: "",
      note: "",
    };
    expect(contactInputSchema.safeParse({ ...valid, ...patch }).success).toBe(false);
  });
});
