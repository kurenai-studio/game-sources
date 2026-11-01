import { describe, expect, it } from "vitest";
import { goodPassword, makeAuth } from "./support/services.js";

async function failure(promise: Promise<unknown>) {
  try {
    await promise;
  } catch (error) {
    const e = error as { getStatus(): number; getResponse(): { code?: string; message?: string } };
    return { status: e.getStatus(), ...e.getResponse() };
  }
  throw new Error("expected a failure");
}

describe("register", () => {
  it("creates a PLAYER, signs them in, and lowercases the email", async () => {
    const { auth, db } = makeAuth();
    const session = await auth.register("  Player@Example.COM ", goodPassword());
    expect(session.user.role).toBe("PLAYER");
    expect(session.user.email).toBe("player@example.com");
    expect(session.user.mustChangePassword).toBe(false);
    expect(session.accessToken.length).toBeGreaterThan(20);
    expect(db.user.rows).toHaveLength(1);
  });

  it("refuses a weak password (422) without creating the account", async () => {
    const { auth, db } = makeAuth();
    expect(await failure(auth.register("a@example.com", "short"))).toMatchObject({
      status: 422,
      code: "WEAK_PASSWORD",
    });
    expect(db.user.rows).toHaveLength(0);
  });

  it("refuses a second account with the same email (409)", async () => {
    const { auth } = makeAuth();
    await auth.register("a@example.com", goodPassword());
    expect(await failure(auth.register("A@example.com", goodPassword()))).toMatchObject({
      status: 409,
      code: "EMAIL_TAKEN",
    });
  });
});

describe("login", () => {
  it("returns tokens for the right password", async () => {
    const { auth } = makeAuth();
    const password = goodPassword();
    await auth.register("a@example.com", password);
    const session = await auth.login("a@example.com", password);
    expect(session.refreshToken.length).toBeGreaterThan(20);
    expect(session.expiresIn).toBeGreaterThan(0);
  });

  it("gives the same answer for a wrong password and an unknown email", async () => {
    const { auth } = makeAuth();
    await auth.register("a@example.com", goodPassword());
    const wrong = await failure(auth.login("a@example.com", "not-the-password-xx"));
    const unknown = await failure(auth.login("nobody@example.com", "not-the-password-xx"));
    expect(wrong).toEqual(unknown);
    expect(wrong).toMatchObject({ status: 401, code: "INVALID_CREDENTIALS" });
  });
});

describe("refresh tokens", () => {
  it("rotates: the old token stops working and the new one works", async () => {
    const { auth } = makeAuth();
    const first = await auth.register("a@example.com", goodPassword());
    const second = await auth.refresh(first.refreshToken);
    expect(second.refreshToken).not.toBe(first.refreshToken);
    expect(await failure(auth.refresh(first.refreshToken))).toMatchObject({ status: 401 });
  });

  it("treats reuse of a spent token as theft and revokes the whole session", async () => {
    const { auth } = makeAuth();
    const first = await auth.register("a@example.com", goodPassword());
    const second = await auth.refresh(first.refreshToken);
    await failure(auth.refresh(first.refreshToken)); // the reuse
    // The newest token of that session no longer works either.
    expect(await failure(auth.refresh(second.refreshToken))).toMatchObject({ status: 401 });
  });

  it("rejects a token that was never issued", async () => {
    const { auth } = makeAuth();
    expect(await failure(auth.refresh("not-a-real-token"))).toMatchObject({ status: 401 });
  });

  it("logout revokes the session, and is quiet for an unknown token", async () => {
    const { auth } = makeAuth();
    const session = await auth.register("a@example.com", goodPassword());
    await auth.logout(session.refreshToken);
    expect(await failure(auth.refresh(session.refreshToken))).toMatchObject({ status: 401 });
    await expect(auth.logout("unknown-token")).resolves.toBeUndefined();
  });
});

describe("change password", () => {
  it("refuses a wrong current password with 422, not 401", async () => {
    const { auth } = makeAuth();
    const session = await auth.register("a@example.com", goodPassword());
    expect(
      await failure(auth.changePassword(session.user.id, "wrong-current-password", goodPassword())),
    ).toMatchObject({ status: 422, code: "CURRENT_PASSWORD_INCORRECT" });
  });

  it("refuses the same password and a weak one", async () => {
    const { auth } = makeAuth();
    const password = goodPassword();
    const session = await auth.register("a@example.com", password);
    expect(await failure(auth.changePassword(session.user.id, password, password))).toMatchObject({
      status: 422,
    });
    expect(await failure(auth.changePassword(session.user.id, password, "short"))).toMatchObject({
      status: 422,
      code: "WEAK_PASSWORD",
    });
  });

  it("sets the new password, ends every other session, and returns a fresh one", async () => {
    const { auth } = makeAuth();
    const password = goodPassword();
    const first = await auth.register("a@example.com", password);
    const other = await auth.login("a@example.com", password);
    const next = goodPassword();
    const fresh = await auth.changePassword(first.user.id, password, next);
    expect(await failure(auth.refresh(other.refreshToken))).toMatchObject({ status: 401 });
    await expect(auth.refresh(fresh.refreshToken)).resolves.toBeDefined();
    await expect(auth.login("a@example.com", next)).resolves.toBeDefined();
    expect(await failure(auth.login("a@example.com", password))).toMatchObject({ status: 401 });
  });
});

describe("a suspended account", () => {
  async function suspended() {
    const made = makeAuth();
    const password = goodPassword();
    const session = await made.auth.register("s@example.com", password);
    (made.db.user.rows[0] as { status: string }).status = "SUSPENDED";
    return { ...made, password, session };
  }

  it("cannot sign in, and is told so only with the right password", async () => {
    const { auth, password } = await suspended();
    expect(await failure(auth.login("s@example.com", password))).toMatchObject({
      status: 403,
      code: "ACCOUNT_SUSPENDED",
    });
    expect(await failure(auth.login("s@example.com", "wrong-password-here"))).toMatchObject({
      status: 401,
      code: "INVALID_CREDENTIALS",
    });
  });

  it("cannot refresh a session it had before", async () => {
    const { auth, session } = await suspended();
    expect(await failure(auth.refresh(session.refreshToken))).toMatchObject({ status: 401 });
  });
});

describe("last active", () => {
  it("is recorded when a session starts", async () => {
    const { auth, db } = makeAuth();
    const password = goodPassword();
    await auth.register("l@example.com", password);
    const first = (db.user.rows[0] as { lastActiveAt?: Date }).lastActiveAt;
    expect(first).toBeInstanceOf(Date);
    await new Promise((resolve) => setTimeout(resolve, 5));
    await auth.login("l@example.com", password);
    const second = (db.user.rows[0] as { lastActiveAt?: Date }).lastActiveAt!;
    expect(second.getTime()).toBeGreaterThan(first!.getTime());
  });
});
