// Headless mobile check: touch emulation at two landscape sizes plus portrait.
// Usage: node scripts/mobile-check.mjs [url] [outDir]   (needs a running server, e.g. npm run build && npm start)
import { chromium } from "playwright";

const url = process.argv[2] || "http://localhost:3000";
const out = process.argv[3] || "docs";
const sizes = [
  { name: "667x375", w: 667, h: 375 },
  { name: "844x390", w: 844, h: 390 },
];
const fails = [];
const check = (ok, msg) => {
  console.log(`${ok ? "PASS" : "FAIL"}  ${msg}`);
  if (!ok) fails.push(msg);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const b = await chromium.launch({ args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });

for (const s of sizes) {
  console.log(`\n== ${s.name} ==`);
  const ctx = await b.newContext({ viewport: { width: s.w, height: s.h }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  const pg = await ctx.newPage();
  const errs = [];
  pg.on("console", (m) => m.type() === "error" && errs.push(m.text()));
  pg.on("pageerror", (e) => errs.push(String(e)));
  const cdp = await ctx.newCDPSession(pg);
  const pts = new Map();
  const send = (type) => cdp.send("Input.dispatchTouchEvent", { type, touchPoints: [...pts].map(([id, p]) => ({ x: p.x, y: p.y, id })) });
  const down = async (id, x, y) => (pts.set(id, { x, y }), send("touchStart"));
  const move = async (id, x, y) => (pts.set(id, { x, y }), send("touchMove"));
  const up = async (id) => {
    await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [...pts].filter(([k]) => k !== id).map(([k, p]) => ({ x: p.x, y: p.y, id: k })) });
    pts.delete(id);
  };
  const tapCenter = async (sel) => {
    const r = await pg.locator(sel).boundingBox();
    const id = 9;
    await down(id, r.x + r.width / 2, r.y + r.height / 2);
    await sleep(60);
    await up(id);
  };
  const dbg = () => pg.evaluate(() => window.__keris.debug());

  await pg.goto(url, { waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 30000 });
  await sleep(1500);
  const env = await pg.evaluate(() => ({ coarse: matchMedia("(pointer: coarse)").matches, text: document.body.innerText }));
  check(env.coarse, "pointer: coarse matches under emulation");
  check(!/desktop game/i.test(env.text), "no desktop-only block");
  check(/Tap to play/.test(env.text), "tap-to-play screen shown");
  const d0 = await dbg();
  check(d0.quality === "low", `auto quality is low on touch (got ${d0.quality})`);
  check(d0.pixelRatio <= 1.5, `pixel ratio capped (got ${d0.pixelRatio} at dpr 2)`);
  await pg.screenshot({ path: `${out}/mobile-title-${s.name}.png` });

  await pg.locator("text=Tap to play").tap();
  await pg.locator(".intro-skip").tap(); // skip the first-run intro
  await pg.waitForFunction(() => window.__keris.debug().phase === "playing", null, { timeout: 10000 });
  check((await pg.locator(".tbtn").count()) === 7, "touch controls rendered (6 action buttons + pause)");
  check((await pg.locator(".joy-hint").count()) === 1, "joystick zone rendered");
  const fits = await pg.evaluate(() => [...document.querySelectorAll(".tbtn, .topleft, .compass")].every((e) => { const r = e.getBoundingClientRect(); return r.left >= 0 && r.top >= 0 && r.right <= innerWidth && r.bottom <= innerHeight; }));
  check(fits, "HUD and buttons fit inside the viewport");
  const noScroll = await pg.evaluate(() => document.documentElement.scrollWidth <= innerWidth && document.documentElement.scrollHeight <= innerHeight);
  check(noScroll, "page does not scroll");

  // joystick: drag up past the edge (forward + run), then release
  await pg.evaluate(() => window.__keris.look(0, 0));
  const p0 = (await dbg()).player;
  await down(1, 90, s.h - 80);
  await move(1, 90, s.h - 80 - 70);
  const t0 = Date.now();
  while (Date.now() - t0 < 12000) {
    const p = (await dbg()).player;
    if (Math.hypot(p.x - p0.x, p.z - p0.z) > 2) break;
    await sleep(150);
  }
  const p1 = (await dbg()).player;
  const moved = Math.hypot(p1.x - p0.x, p1.z - p0.z);
  check(moved > 2, `joystick moved the player ${moved.toFixed(1)} m`);
  check(await pg.locator(".joy-base.run").count() === 1, "stick at the edge shows run state");
  await up(1);
  await sleep(400);
  const p2 = (await dbg()).player;
  await sleep(500);
  const p3 = (await dbg()).player;
  check(Math.hypot(p3.x - p2.x, p3.z - p2.z) < 0.05, "releasing the stick stops the player");

  // look drag on the right side
  const y0 = (await dbg()).camYaw;
  await down(2, s.w - 200, 120);
  for (let i = 1; i <= 8; i++) await move(2, s.w - 200 + i * 15, 120 + i * 3);
  await up(2);
  await sleep(200);
  const y1 = (await dbg()).camYaw;
  check(Math.abs(y1 - y0) > 0.1, `drag rotated the camera (${y0.toFixed(2)} -> ${y1.toFixed(2)} rad)`);

  // multi-touch: hold stick + drag look + tap crouch at once
  const before = await dbg();
  await down(1, 90, s.h - 80);
  await move(1, 90, s.h - 80 - 40);
  await down(2, s.w - 220, 100);
  const crouchBox = await pg.locator('[data-act="KeyC"]').boundingBox();
  await down(3, crouchBox.x + crouchBox.width / 2, crouchBox.y + crouchBox.height / 2);
  await sleep(60);
  await up(3);
  for (let i = 1; i <= 8; i++) await move(2, s.w - 220 + i * 12, 100);
  await sleep(1200);
  const mid = await dbg();
  await up(1);
  await up(2);
  check(mid.crouched !== before.crouched, "crouch button toggled while stick and look were held");
  check(Math.hypot(mid.player.x - before.player.x, mid.player.z - before.player.z) > 0.3, "player kept moving during multi-touch");
  check(Math.abs(mid.camYaw - before.camYaw) > 0.05, "camera kept rotating during multi-touch");
  await tapCenter('[data-act="KeyC"]'); // un-crouch

  // buttons
  await pg.evaluate(() => {
    const g = window.__keris;
    window.__presses = [];
    const orig = g.pressKey.bind(g);
    g.pressKey = (c) => (window.__presses.push(c), orig(c));
  });
  const b0 = await dbg();
  await tapCenter('[data-act="KeyV"]');
  check((await dbg()).eagle !== b0.eagle, "Mata Helang button toggles vision");
  await tapCenter('[data-act="KeyV"]');
  await tapCenter('[data-act="KeyQ"]');
  await sleep(200);
  check((await dbg()).knives === b0.knives - 1, "knife throw button throws a knife");
  await tapCenter('[data-act="KeyC"]');
  check((await dbg()).crouched === true, "crouch button toggles crouch");
  await tapCenter('[data-act="KeyC"]');
  const y = (await dbg()).player.y;
  await tapCenter('[data-act="Space"]');
  let peak = y;
  for (let i = 0; i < 12; i++) {
    peak = Math.max(peak, (await dbg()).player.y);
    await sleep(40);
  }
  check(peak > y + 0.15, `jump button lifts the player (${(peak - y).toFixed(2)} m)`);
  await tapCenter('[data-act="KeyE"]');
  await tapCenter('[data-act="KeyF"]');
  const presses = await pg.evaluate(() => window.__presses);
  check(presses.includes("KeyE") && presses.includes("KeyF"), `takedown and carry buttons dispatch E and F (${presses.join(",")}); outcome needs a guard nearby so not asserted`);

  await pg.screenshot({ path: `${out}/mobile-gameplay-${s.name}.png` });

  // pause button
  await tapCenter(".pause-btn");
  await sleep(300);
  check((await dbg()).phase === "paused", "pause button pauses");
  await pg.screenshot({ path: `${out}/mobile-paused-${s.name}.png` });
  await pg.locator("text=Resume").tap();
  await sleep(300);
  check((await dbg()).phase === "playing", "resume returns to play");

  // portrait (leave fullscreen first so the window can be resized)
  await pg.evaluate(() => document.fullscreenElement && document.exitFullscreen()).catch(() => {});
  await sleep(300);
  await pg.setViewportSize({ width: s.h, height: s.w });
  await sleep(600);
  const rot = await pg.locator(".rotate").count();
  check(rot === 1, "portrait shows the rotate prompt");
  check((await dbg()).phase === "paused", "portrait pauses the game");
  if (s.name === "667x375") await pg.screenshot({ path: `${out}/mobile-portrait.png` });
  await pg.setViewportSize({ width: s.w, height: s.h });
  await sleep(400);
  check((await pg.locator(".rotate").count()) === 0, "rotating back hides the prompt");

  check(errs.length === 0, `no console errors ${JSON.stringify(errs)}`);
  await ctx.close();
}

// ?quality=high override and desktop (non-touch) context keep desktop behaviour
{
  const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
  const pg = await ctx.newPage();
  await pg.goto(url, { waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 30000 });
  const d = await pg.evaluate(() => window.__keris.debug());
  check(d.quality === "high", "desktop defaults to high quality");
  check(/Begin/.test(await pg.evaluate(() => document.body.innerText)) && (await pg.locator(".tbtn").count()) === 0, "desktop shows Begin and no touch controls");
  await ctx.close();
  const c2 = await b.newContext({ viewport: { width: 844, height: 390 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  const p2 = await c2.newPage();
  await p2.goto(`${url}/?quality=high`, { waitUntil: "networkidle" });
  await p2.waitForFunction(() => window.__keris, null, { timeout: 30000 });
  const d2 = await p2.evaluate(() => window.__keris.debug());
  check(d2.quality === "high" && d2.pixelRatio === 2, "?quality=high overrides on mobile");
  await c2.close();
}

await b.close();
console.log(fails.length ? `\n${fails.length} FAILED` : "\nall passed");
process.exit(fails.length ? 1 : 0);
