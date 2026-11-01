import { describe, expect, it } from "vitest";
import {
  deletePlayerSchema,
  displayNameBodySchema,
  listPlayersQuerySchema,
} from "../src/modules/players/players.schemas.js";

describe("player list query", () => {
  it("has sensible defaults and refuses unknown sorts", () => {
    expect(listPlayersQuerySchema.parse({})).toMatchObject({
      sort: "lastActive",
      order: "desc",
      page: 1,
      pageSize: 25,
    });
    expect(listPlayersQuerySchema.safeParse({ sort: "password" }).success).toBe(false);
    expect(listPlayersQuerySchema.safeParse({ pageSize: "1000" }).success).toBe(false);
  });
});

describe("display name", () => {
  const ok = (displayName: unknown) => displayNameBodySchema.safeParse({ displayName }).success;

  it("accepts plain names and null (which clears the name)", () => {
    expect(ok("Ada")).toBe(true);
    expect(ok("Ada Lovelace-2")).toBe(true);
    expect(ok("Zoë")).toBe(true);
    expect(ok(null)).toBe(true);
  });

  it("refuses markup, symbols, and lengths outside 2 to 24", () => {
    expect(ok("<b>x</b>")).toBe(false);
    expect(ok("a")).toBe(false);
    expect(ok("x".repeat(25))).toBe(false);
    expect(ok(" .hidden")).toBe(false);
    expect(ok("name@example.com")).toBe(false);
  });
});

describe("delete confirmation", () => {
  it("needs the email typed", () => {
    expect(deletePlayerSchema.safeParse({}).success).toBe(false);
    expect(deletePlayerSchema.safeParse({ confirmEmail: "a@example.com" }).success).toBe(true);
  });
});
