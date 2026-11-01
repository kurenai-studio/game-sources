import "reflect-metadata";
import type { ExecutionContext } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { describe, expect, it } from "vitest";
import { AdminCampaignController } from "../src/modules/campaign/admin-campaign.controller.js";
import { AuditController } from "../src/modules/audit/audit.controller.js";
import { AdminGuard } from "../src/modules/auth/guards/admin.guard.js";
import { JwtAuthGuard } from "../src/modules/auth/guards/jwt-auth.guard.js";
import { ClientVersionsController } from "../src/modules/client-versions/client-versions.controller.js";
import { AdminLevelsController } from "../src/modules/levels/admin-levels.controller.js";
import { MeController } from "../src/modules/me/me.controller.js";
import { goodPassword, makeAuth } from "./support/services.js";

function contextFor(request: Record<string, unknown>): ExecutionContext {
  return {
    getHandler: () => () => undefined,
    getClass: () => class {},
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

async function status(run: () => unknown): Promise<number> {
  try {
    await run();
    return 200;
  } catch (error) {
    return (error as { getStatus(): number }).getStatus();
  }
}

async function setup() {
  const { auth, db, tokens } = makeAuth();
  const reflector = new Reflector();
  const jwt = new JwtAuthGuard(tokens, db.asPrisma(), reflector);
  const admin = new AdminGuard(reflector);
  const session = await auth.register("player@example.com", goodPassword());
  return { auth, db, tokens, jwt, admin, session };
}

describe("JwtAuthGuard", () => {
  it("refuses a request with no token (401)", async () => {
    const { jwt } = await setup();
    expect(await status(() => jwt.canActivate(contextFor({ headers: {} })))).toBe(401);
  });

  it("refuses a malformed header and a garbage token (401)", async () => {
    const { jwt } = await setup();
    expect(
      await status(() => jwt.canActivate(contextFor({ headers: { authorization: "Token x" } }))),
    ).toBe(401);
    expect(
      await status(() =>
        jwt.canActivate(contextFor({ headers: { authorization: "Bearer garbage" } })),
      ),
    ).toBe(401);
  });

  it("refuses an expired token (401)", async () => {
    const { jwt, tokens, session } = await setup();
    const expired = await tokens.signAccessToken(
      { userId: session.user.id, role: "PLAYER" },
      new Date(Date.now() - 24 * 3_600_000),
    );
    expect(
      await status(() =>
        jwt.canActivate(contextFor({ headers: { authorization: `Bearer ${expired}` } })),
      ),
    ).toBe(401);
  });

  it("accepts a valid token and attaches the user", async () => {
    const { jwt, session } = await setup();
    const request: Record<string, unknown> = {
      headers: { authorization: `Bearer ${session.accessToken}` },
    };
    expect(await status(() => jwt.canActivate(contextFor(request)))).toBe(200);
    expect(request.user).toMatchObject({ email: "player@example.com", role: "PLAYER" });
  });

  it("refuses a valid token whose account no longer exists (401)", async () => {
    const { jwt, db, session } = await setup();
    db.user.rows.length = 0;
    expect(
      await status(() =>
        jwt.canActivate(
          contextFor({ headers: { authorization: `Bearer ${session.accessToken}` } }),
        ),
      ),
    ).toBe(401);
  });
});

describe("AdminGuard", () => {
  const user = (over: Record<string, unknown>) => ({
    user: { id: "u", email: "a@example.com", role: "ADMIN", mustChangePassword: false, ...over },
  });

  it("refuses a request that was never authenticated (401)", async () => {
    const { admin } = await setup();
    expect(await status(() => admin.canActivate(contextFor({})))).toBe(401);
  });

  it("refuses a PLAYER (403)", async () => {
    const { admin } = await setup();
    expect(await status(() => admin.canActivate(contextFor(user({ role: "PLAYER" }))))).toBe(403);
  });

  it("refuses an admin who still has the seeded password (403)", async () => {
    const { admin } = await setup();
    let body: { code?: string } = {};
    try {
      admin.canActivate(contextFor(user({ mustChangePassword: true })));
    } catch (error) {
      body = (error as { getResponse(): { code?: string } }).getResponse();
    }
    expect(body.code).toBe("PASSWORD_CHANGE_REQUIRED");
  });

  it("lets a settled admin through", async () => {
    const { admin } = await setup();
    expect(await status(() => admin.canActivate(contextFor(user({}))))).toBe(200);
  });
});

describe("routes are guarded", () => {
  const guardsOf = (controller: unknown): unknown[] =>
    (Reflect.getMetadata("__guards__", controller as object) as unknown[] | undefined) ?? [];

  it("every admin controller requires a signed-in admin", () => {
    for (const controller of [
      AdminLevelsController,
      AdminCampaignController,
      AuditController,
      ClientVersionsController,
    ]) {
      const guards = guardsOf(controller);
      expect(guards, controller.name).toContain(JwtAuthGuard);
      expect(guards, controller.name).toContain(AdminGuard);
    }
  });

  it("the account routes require a signed-in user", () => {
    expect(guardsOf(MeController)).toContain(JwtAuthGuard);
  });
});
