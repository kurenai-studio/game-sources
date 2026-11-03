// Headless check of the intro cutscene: desktop + phone viewports, skip (keys and touch), first-run only, replay, reset, reduced motion.
// Usage: node scripts/intro-check.mjs [url] [outDir]   (needs a running server, e.g. npm run build && npm start)
import { chromium } from "playwright";

const url = process.argv[2] || "http://localhost:3000";
const out = process.argv[3] || "docs";
const fails = [];
const check = (ok, msg) => {
  console.log(`${ok ? "PASS" : "FAIL"}  ${msg}`);
  if (!ok) fails.push(msg);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const b = await chromium.launch({ args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });

async function open(ctx) {
  const pg = await ctx.newPage();
  const errs = [];
  pg.on("console", (m) => m.type() === "error" && errs.push(m.text()));
  pg.on("pageerror", (x) => errs.push(String(x)));
  await pg.goto(url, { waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 90000 });
  await sleep(500);
  return { pg, errs };
}
const phase = (pg) => pg.evaluate(() => window.__keris.debug().phase);
const seen = (pg) => pg.evaluate(() => JSON.parse(localStorage.getItem("keris:save") || "null")?.seenIntro);
const text = (pg) => pg.evaluate(() => document.body.innerText);
const seek = async (pg, t) => {
  await pg.evaluate((x) => window.__keris.debugIntroSeek(x), t);
  await sleep(700);
};
const waitPhase = (pg, p) => pg.waitForFunction((x) => window.__keris.debug().phase === x, p, { timeout: 15000 });
const reload = async (pg) => {
  await pg.reload({ waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 30000 });
  await sleep(500);
};

// ---------------------------------------------------------------- desktop
{
  console.log("\n== desktop 1280x720 ==");
  const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
  const { pg, errs } = await open(ctx);
  await pg.getByRole("button", { name: "Begin" }).click();
  await waitPhase(pg, "intro");
  check(true, "first Begin plays the intro instead of starting");
  await seek(pg, 2.5);
  await pg.screenshot({ path: `${out}/intro-1.png` });
  await seek(pg, 12);
  check(/guns may turn on the town/.test(await text(pg)), "caption 3 shown mid-intro");
  await pg.screenshot({ path: `${out}/intro-2.png` });
  await seek(pg, 20);
  await pg.screenshot({ path: `${out}/intro-3.png` });
  check(await pg.getByRole("button", { name: "Skip" }).isVisible(), "Skip button visible");
  await pg.keyboard.press("Escape");
  await waitPhase(pg, "playing");
  check((await seen(pg)) === true, "skip with Escape starts the mission and records seenIntro");

  await reload(pg);
  check(/Continue/.test(await text(pg)), "second load: title with Continue, no intro");
  await pg.getByRole("button", { name: "New game" }).click();
  await waitPhase(pg, "playing");
  check(true, "New game starts straight into the mission");

  await reload(pg);
  await pg.getByRole("button", { name: "Settings" }).click();
  await pg.getByRole("button", { name: "Replay intro" }).click();
  await waitPhase(pg, "intro");
  check(true, "Replay intro plays from Settings");
  for (const key of ["Space", "Enter"]) {
    await pg.keyboard.press(key);
    await waitPhase(pg, "title");
    check(true, `${key} skips the replay and returns to the title`);
    await pg.getByRole("button", { name: "Settings" }).click();
    await pg.getByRole("button", { name: "Replay intro" }).click();
    await waitPhase(pg, "intro");
  }
  await pg.getByRole("button", { name: "Skip" }).click();
  await waitPhase(pg, "title");
  check(true, "Skip button works");
  check((await seen(pg)) === true, "replay leaves seenIntro set");

  await pg.getByRole("button", { name: "Settings" }).click();
  await pg.getByRole("button", { name: "Replay intro" }).click();
  await waitPhase(pg, "intro");
  await seek(pg, 21.9);
  await waitPhase(pg, "title");
  check(true, "intro ends on its own at the end of the timeline");

  await pg.getByRole("button", { name: "Settings" }).click();
  await pg.getByRole("button", { name: "Reset progress" }).click();
  await pg.getByRole("button", { name: "Yes, reset" }).click();
  check((await seen(pg)) === false, "Reset progress clears seenIntro");
  await pg.getByRole("button", { name: "Close" }).click();
  await pg.getByRole("button", { name: "Begin" }).click();
  await waitPhase(pg, "intro");
  check(true, "after reset the intro plays again");
  check(errs.length === 0, `no console errors ${JSON.stringify(errs)}`);
  await ctx.close();
}

// ---------------------------------------------------------------- old v1 save
{
  console.log("\n== existing saves ==");
  const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
  const pg0 = await ctx.newPage();
  await pg0.goto(url, { waitUntil: "domcontentloaded" });
  await pg0.evaluate(() =>
    localStorage.setItem(
      "keris:save",
      JSON.stringify({ version: 1, checkpoint: "kapitan", missions: { "malacca-1511": { completed: true, attempts: 3, bestTime: 245, bestRating: 2 } }, settings: { quality: "auto", lookSens: 1, invertY: false } }),
    ),
  );
  await pg0.close();
  const { pg } = await open(ctx);
  const t = await text(pg);
  check(/Continue/.test(t) && /Best: 4:05/.test(t), "v1 save loads with Continue and best time");
  await pg.getByRole("button", { name: "New game" }).click();
  await waitPhase(pg, "playing");
  check(true, "player with a v1 save is not forced through the intro");
  await ctx.close();
}

// ---------------------------------------------------------------- phone
for (const s of [
  { name: "landscape", w: 844, h: 390 },
  { name: "portrait", w: 390, h: 844 },
]) {
  console.log(`\n== phone ${s.name} ${s.w}x${s.h} ==`);
  const ctx = await b.newContext({ viewport: { width: s.w, height: s.h }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  const { pg, errs } = await open(ctx);
  // the existing rotate prompt covers the title in portrait, so start in landscape and rotate during the intro
  if (s.name === "portrait") await pg.setViewportSize({ width: s.h, height: s.w });
  await pg.locator("text=Tap to play").tap();
  await waitPhase(pg, "intro");
  if (s.name === "portrait") {
    await pg.evaluate(() => document.fullscreenElement && document.exitFullscreen()).catch(() => {});
    await sleep(300);
    await pg.setViewportSize({ width: s.w, height: s.h });
    await sleep(500);
  }
  await seek(pg, 12);
  await pg.screenshot({ path: `${out}/intro-mobile-${s.name}.png` });
  const r = await pg.evaluate(() => {
    const q = (c) => document.querySelector(c)?.getBoundingClientRect();
    return { cap: q(".intro-caption"), sk: q(".intro-skip"), w: innerWidth, h: innerHeight, rotate: !!document.querySelector(".overlay.rotate") };
  });
  check(r.cap.left >= 0 && r.cap.right <= r.w && r.cap.bottom <= r.h, "caption fits the viewport");
  check(r.sk.right <= r.w && r.sk.top >= 0 && r.sk.height >= 36, "Skip button on screen and tappable");
  check(!r.rotate, "rotate prompt does not hide the intro");
  if (s.name === "landscape") {
    await pg.locator(".intro").tap({ position: { x: 100, y: 150 } });
    await waitPhase(pg, "playing");
    check(true, "tap anywhere skips on touch");
  } else {
    await pg.locator(".intro-skip").tap();
    await sleep(500);
    const p = await phase(pg);
    check(p === "playing" || p === "paused", `Skip button works in portrait (phase ${p})`);
  }
  check(errs.length === 0, `no console errors ${JSON.stringify(errs)}`);
  await ctx.close();
}

// ---------------------------------------------------------------- reduced motion
{
  console.log("\n== reduced motion ==");
  const ctx = await b.newContext({ viewport: { width: 1280, height: 720 }, reducedMotion: "reduce" });
  const { pg } = await open(ctx);
  await pg.getByRole("button", { name: "Begin" }).click();
  await waitPhase(pg, "intro");
  await seek(pg, 3);
  await pg.screenshot({ path: `${out}/intro-reduced.png` });
  await seek(pg, 11.9);
  await waitPhase(pg, "playing");
  check(true, "reduced-motion version ends on its shorter (12s) timeline");
  await ctx.close();
}

await b.close();
console.log(fails.length ? `\n${fails.length} FAILED` : "\nall passed");
process.exit(fails.length ? 1 : 0);
