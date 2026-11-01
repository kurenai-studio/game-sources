// A smoke test of the social API against a running API and its local database: profiles, boards,
// the daily challenge, badges, sharing, reports, and the admin routes. It makes throwaway players
// (and one throwaway admin, by promoting a player in the local database) and deletes them at the end.
//
//   make api-smoke                      (API at http://localhost:8000/v1; API_BASE_URL overrides)
//
// Needs the local database container (make db-up) for the one admin promotion and the cleanup.
import { execFileSync } from "node:child_process";
import { solve } from "../packages/level-contract/dist/index.js";

const BASE = (process.env.API_BASE_URL ?? "http://localhost:8000/v1").replace(/\/$/, "");
const stamp = Date.now();
let failures = 0;
const check = (name, ok, extra = "") => {
  if (!ok) failures += 1;
  console.log(`${ok ? "ok  " : "FAIL"} ${name}${extra ? " :: " + extra : ""}`);
};
async function call(method, path, body, token) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      "content-type": "application/json",
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  let json = null;
  try {
    json = await res.json();
  } catch {}
  return { status: res.status, json };
}
const sql = (q) =>
  execFileSync("docker", [
    "exec",
    "algomind-db-1",
    "psql",
    "-U",
    "algomind",
    "-d",
    "algomind",
    "-tAc",
    q,
  ])
    .toString()
    .trim();
async function player(tag) {
  const email = `smoke-${tag}-${stamp}@example.test`;
  const password = "Smoke-pass-12345!";
  const r = await call("POST", "/auth/register", { email, password });
  return { email, token: r.json.accessToken, id: r.json.user?.id };
}
async function levelProgram(slug) {
  const lv = await call("GET", `/levels/${slug}`);
  const level = lv.json.content;
  return {
    version: lv.json.levelVersion,
    program: solve(level).program,
    par: lv.json.par.commands,
  };
}
const A = await player("a"),
  B = await player("b"),
  C = await player("c");
check("three players registered", A.token && B.token && C.token);

// ---- profile
let r = await call("GET", "/me/profile", null, A.token);
check(
  "profile default: not opted in, rank Novice",
  r.status === 200 && r.json.leaderboardOptIn === false && r.json.rank.name === "Novice",
);
r = await call("PUT", "/me/profile", { leaderboardOptIn: true }, A.token);
check(
  "opt-in without a name or hidden mode is refused",
  r.status === 422 && r.json.code === "NAME_REQUIRED",
);
r = await call("PUT", "/me/profile", { displayName: "admin" }, A.token);
check("reserved name refused", r.status === 422 && r.json.code === "NAME_NOT_ALLOWED");
r = await call("PUT", "/me/profile", { displayName: "ab" }, A.token);
check("too-short name refused", r.status === 422 && r.json.code === "NAME_INVALID");
r = await call(
  "PUT",
  "/me/profile",
  { displayName: `Smoke ${stamp % 10000}`, leaderboardOptIn: true },
  A.token,
);
const nameA = r.json.displayName;
check(
  "name and opt-in saved",
  r.status === 200 && r.json.leaderboardOptIn === true && nameA?.startsWith("Smoke"),
);
r = await call("PUT", "/me/profile", { displayName: nameA.toUpperCase() }, B.token);
check(
  "same name differing only in case is taken",
  r.status === 409 && r.json.code === "NAME_TAKEN",
);
r = await call("PUT", "/me/profile", { hideName: true, leaderboardOptIn: true }, B.token);
check(
  "hidden-name opt-in works without a name",
  r.status === 200 && r.json.hideName === true && r.json.leaderboardOptIn === true,
);

// ---- submissions and points
const first = await levelProgram("first-step"),
  count = await levelProgram("beside-the-wall");
const sub = async (who, slug, p, extra = {}) =>
  call(
    "POST",
    "/me/submissions",
    { levelSlug: slug, levelVersion: p.version, program: p.program, ...extra },
    who.token,
  );
r = await sub(A, "first-step", first);
check("A submits first-step", r.status === 200 && r.json.awarded > 0, `awarded ${r.json.awarded}`);
check(
  "the first submission earns the First clear badge",
  (r.json.achievements ?? []).some((b) => b.slug === "first-clear"),
  JSON.stringify(r.json.achievements),
);
await sub(A, "beside-the-wall", count);
await sub(B, "first-step", first);
await sub(C, "first-step", first);

// ---- boards
r = await call("GET", "/leaderboards/points?period=all");
const names = r.json.entries.map((e) => e.name);
check(
  "points board shows opted-in players only",
  names.includes(nameA) &&
    names.includes("Anonymous") &&
    r.json.entries.every((e) => e.publicId) &&
    !JSON.stringify(r.json).includes("@"),
  names.join(", "),
);
check(
  "the points board never shows an email or account id",
  !JSON.stringify(r.json).includes(A.id) && !JSON.stringify(r.json).includes(A.email),
);
const top = r.json.entries.find((e) => e.name === nameA);
check(
  "A (more points) ranks above B",
  top &&
    r.json.entries.findIndex((e) => e.name === nameA) <
      r.json.entries.findIndex((e) => e.name === "Anonymous"),
);
r = await call("GET", "/leaderboards/points?period=week", null, A.token);
check(
  "weekly board and the caller's own place",
  r.status === 200 && r.json.me?.entry.you === true && r.json.me.around.length >= 1,
);
r = await call("GET", "/leaderboards/points?period=month");
check("monthly board", r.status === 200 && r.json.total >= 2);
r = await call("GET", "/leaderboards/levels/first-step", null, B.token);
check(
  "level board: A and B (C opted out), B knows its place",
  r.json.total === 2 && r.json.me?.entry.you === true,
  `total ${r.json.total}`,
);
r = await call("GET", "/leaderboards/levels/not-a-level");
check("unknown level board is 404", r.status === 404);
r = await call("GET", "/leaderboards/points?limit=1&offset=1");
check("paging works", r.json.entries.length === 1 && r.json.entries[0].rank === 2);

// ---- daily
r = await call("GET", "/daily");
const d = r.json;
check(
  "daily: today and three upcoming days",
  d.today && d.upcoming.length === 3 && /^\d{4}-\d{2}-\d{2}$/.test(d.serverDate),
  d.today?.levelSlug,
);
const lvl = await levelProgram(d.today.levelSlug);
r = await sub(A, d.today.levelSlug, lvl, { dailyDate: d.serverDate });
check(
  "daily result counts and starts a streak",
  r.json.daily?.accepted === true && r.json.daily.streak.current === 1,
  JSON.stringify(r.json.daily),
);
check(
  "a daily solve earns the Daily start badge",
  (r.json.achievements ?? []).some((b) => b.slug === "daily-first"),
  JSON.stringify(r.json.achievements),
);
r = await sub(B, d.today.levelSlug, lvl, { dailyDate: "2020-01-01" });
check(
  "a claim for a date outside the window does not count (the solve still scores)",
  r.status === 200 && r.json.daily?.accepted === false,
);
r = await sub(B, "first-step", first, { dailyDate: d.serverDate });
check(
  "a claim for a level that is not that day's challenge does not count",
  r.json.daily?.accepted === false,
);
r = await call("GET", "/me/daily", null, A.token);
check("my daily: result and streak", r.json.result && r.json.streak.current === 1);
r = await call("GET", `/leaderboards/daily/${d.serverDate}`, null, A.token);
check("daily board", r.json.total === 1 && r.json.me?.entry.slots > 0);
r = await call("GET", `/levels/${d.today.levelSlug}`);
check("a daily-pool level is fetchable by slug", r.status === 200);
r = await call("GET", "/campaign");
check(
  "the campaign does not list pool levels",
  !JSON.stringify(r.json).includes(d.today.levelSlug) && r.json.worlds.length === 3,
);

// ---- achievements
r = await call("GET", "/me/achievements", null, A.token);
const earned = r.json.items.filter((b) => b.earnedAt).map((b) => b.slug);
check(
  "achievements list with earned flags",
  r.json.items.length >= 12 && earned.includes("first-clear") && earned.includes("daily-first"),
  earned.join(", "),
);

// ---- share
r = await call(
  "POST",
  "/me/share",
  { kind: "daily", levelSlug: d.today.levelSlug, date: d.serverDate },
  A.token,
);
check(
  "share link for a daily result",
  r.status === 200 && /^[0-9a-z]{8}$/.test(r.json.code),
  r.json.path,
);
const code = r.json.code;
const again = await call(
  "POST",
  "/me/share",
  { kind: "daily", levelSlug: d.today.levelSlug, date: d.serverDate },
  A.token,
);
check("the same share is the same code", again.json.code === code);
r = await call("GET", `/share/${code}`);
check(
  "public card: level, slots, par; no name, no email, no id",
  r.status === 200 &&
    r.json.levelSlug === d.today.levelSlug &&
    r.json.slots > 0 &&
    !JSON.stringify(r.json).includes(A.id) &&
    !JSON.stringify(r.json).includes("@") &&
    !JSON.stringify(r.json).includes(nameA),
);
r = await call("POST", "/me/share", { kind: "level", levelSlug: "stairs" }, C.token);
check("sharing a result you do not have is refused", r.status === 409);
r = await call("GET", "/share/zzzzzzzz");
check("unknown share code is 404", r.status === 404);

// ---- report + admin (a throwaway admin made from a throwaway player)
const root = await player("admin");
sql(`UPDATE "User" SET role='ADMIN', "mustChangePassword"=false WHERE id='${root.id}'`);
const adm = await call("POST", "/auth/login", { email: root.email, password: "Smoke-pass-12345!" });
const T = adm.json.accessToken;
check("throwaway admin signs in", !!T);
const aPublic = (await call("GET", "/me/profile", null, A.token)).json.publicId;
r = await call(
  "POST",
  "/leaderboards/report",
  { publicId: aPublic, reason: "smoke test" },
  B.token,
);
check("a player can report a name", r.status === 200);
r = await call("GET", "/admin/reports", null, T);
const rep = r.json.items.find((x) => x.target?.publicId === aPublic);
check(
  "admin sees the open report with the player's name",
  !!rep && rep.target.displayName === nameA,
);
r = await call("POST", `/admin/reports/${rep.id}/resolve`, { action: "hide" }, T);
check("admin hides the player", r.status === 200 && r.json.status === "ACTIONED");
r = await call("GET", "/leaderboards/points?period=all");
check("a hidden player is gone from the boards", !r.json.entries.some((e) => e.name === nameA));
r = await call("PUT", `/admin/players/${A.id}/leaderboard-hidden`, { hidden: false }, T);
check("admin can show the player again", r.status === 200);
r = await call("GET", "/leaderboards/points?period=all");
check(
  "and they are back",
  r.json.entries.some((e) => e.name === nameA),
);
r = await call("GET", "/admin/daily/pool", null, T);
check("admin: pool list", r.json.items.filter((l) => l.pool).length >= 15);
const poolSlug = r.json.items.find((l) => l.pool).slug;
const tomorrow = new Date(Date.now() + 5 * 864e5).toISOString().slice(0, 10);
r = await call("PUT", `/admin/daily/${tomorrow}`, { levelSlug: poolSlug }, T);
check("admin schedules a day", r.status === 200);
r = await call("GET", `/admin/daily?from=${tomorrow}&days=1`, null, T);
check(
  "the scheduled day reads back as scheduled",
  r.json.items[0].levelSlug === poolSlug && r.json.items[0].source === "scheduled",
);
r = await call("PUT", `/admin/daily/${tomorrow}`, { levelSlug: "stairs" }, T);
check("a campaign level cannot be scheduled", r.status === 409);
r = await call("DELETE", `/admin/daily/${tomorrow}`, null, T);
check("admin clears the day", r.status === 200);
r = await call("PUT", "/admin/daily/pool/stairs", { pool: true }, T);
check("a campaign level cannot join the pool", r.status === 409 && r.json.code === "IN_CAMPAIGN");
r = await call("GET", "/admin/achievements", null, T);
check(
  "admin: badges with earned counts",
  r.json.items.length >= 12 && r.json.items.find((b) => b.slug === "first-clear").earnedBy >= 3,
);
r = await call(
  "POST",
  "/admin/achievements",
  {
    slug: `smoke-${stamp}`,
    title: "Smoke badge",
    description: "Made by the smoke test.",
    rule: { type: "levels_solved", value: 2 },
  },
  T,
);
check("admin creates a badge", r.status === 201 || r.status === 200, String(r.status));
const badge = r.json;
r = await call("PUT", `/admin/achievements/${badge.id}`, { active: false }, T);
check("admin switches it off", r.status === 200 && r.json.active === false);
r = await call(
  "POST",
  "/admin/achievements",
  {
    slug: `bad-${stamp}`,
    title: "Bad",
    description: "bad rule here",
    rule: { type: "nonsense", value: 1 },
  },
  T,
);
check("an unknown rule type is refused", r.status === 422);
r = await call("GET", "/admin/level-stats", null, T);
const fs = r.json.items.find((s) => s.slug === "first-step");
check(
  "admin: level stats count solvers",
  fs && fs.solvers >= 3 && fs.par === 2 && fs.atPar >= 3,
  JSON.stringify(fs),
);
check(
  "level stats include pool levels",
  r.json.items.some((s) => s.pool),
);
r = await call("GET", "/admin/level-stats", null, A.token);
check("a player cannot read admin stats", r.status === 403);
r = await call("GET", "/admin/reports", null);
check("admin routes need a token", r.status === 401);

// ---- privacy: export covers the new data, and deleting an account removes it everywhere
r = await call("GET", `/admin/players/${A.id}/export`, null, T);
check(
  "admin export includes daily results, badges, and share links",
  r.status === 200 &&
    r.json.dailyResults?.length >= 1 &&
    r.json.badges?.length >= 2 &&
    r.json.shareLinks?.length >= 1,
  r.status,
);
check("the export also carries the leaderboard choices", r.json.account?.leaderboardOptIn === true);
const delBefore = await call("GET", `/share/${code}`);
check("A's share link works before deletion", delBefore.status === 200);
await call("POST", "/leaderboards/report", { publicId: aPublic, reason: "smoke test" }, C.token);
r = await fetch(`${BASE}/me`, {
  method: "DELETE",
  headers: { "content-type": "application/json", authorization: `Bearer ${A.token}` },
  body: JSON.stringify({ password: "Smoke-pass-12345!" }),
});
check("A deletes their own account", r.status === 204, String(r.status));
const delAfter = await call("GET", `/share/${code}`);
check("deleting the account removes the share link", delAfter.status === 404);
r = await call("GET", "/leaderboards/points?period=all");
check("and the player leaves every board", !r.json.entries.some((e) => e.name === nameA));
check(
  "no report about the deleted player is left",
  sql(`SELECT count(*) FROM "Report" WHERE "targetPublic" = '${aPublic}'`) === "0",
);

// cleanup of everything the smoke made
sql(`DELETE FROM "User" WHERE email LIKE 'smoke-%-${stamp}@example.test'`);
sql(`DELETE FROM "Achievement" WHERE slug LIKE 'smoke-${stamp}'`);
sql(`DELETE FROM "Report" WHERE reason = 'smoke test'`);
console.log(failures === 0 ? "\nALL OK" : `\n${failures} FAILED`);
process.exit(failures ? 1 : 0);
