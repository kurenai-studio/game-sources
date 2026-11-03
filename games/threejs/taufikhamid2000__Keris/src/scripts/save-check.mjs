// Headless check of browser progress saving (desktop, touch, bad storage).
// Usage: node scripts/save-check.mjs [url]   (needs a running server, e.g. npm run build && npm start)
import { chromium } from "playwright";

const url = process.argv[2] || "http://localhost:3000";
const KEY = "keris:save";
const fails = [];
const check = (ok, msg) => {
  console.log(`${ok ? "PASS" : "FAIL"}  ${msg}`);
  if (!ok) fails.push(msg);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const b = await chromium.launch({ args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });

async function open(ctx, path = "") {
  const pg = await ctx.newPage();
  const errs = [];
  pg.on("console", (m) => m.type() === "error" && errs.push(m.text()));
  pg.on("pageerror", (x) => errs.push(String(x)));
  await pg.goto(url + path, { waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 90000 });
  await sleep(500);
  return { pg, errs };
}
const reload = async (pg) => {
  await pg.reload({ waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 30000 });
  await sleep(500);
};
const stored = (pg) => pg.evaluate((k) => JSON.parse(localStorage.getItem(k) || "null"), KEY);
const text = (pg) => pg.evaluate(() => document.body.innerText);
const dbg = (pg) => pg.evaluate(() => window.__keris.debug());
const playing = (pg) => pg.waitForFunction(() => window.__keris.debug().phase === "playing", null, { timeout: 15000 });
const btn = (pg, name) => pg.getByRole("button", { name, exact: false }).first();

// ---------------------------------------------------------------- desktop flow
{
  console.log("\n== desktop: progress, settings, reset ==");
  const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
  const { pg, errs } = await open(ctx);
  let t = await text(pg);
  check(/Begin/.test(t) && !/Continue/.test(t), "fresh browser: Begin shown, no Continue");
  check((await stored(pg)) === null, "nothing written before the player does anything");

  await btn(pg, "Begin").click();
  await pg.keyboard.press("Space"); // skip the first-run intro
  await playing(pg);
  const s1 = await stored(pg);
  check(s1?.version === 2 && s1.checkpoint === "start" && s1.missions["malacca-1511"].attempts === 1, "mission start writes checkpoint and attempt under keris:save");

  await reload(pg);
  t = await text(pg);
  check(/Continue/.test(t) && /New game/.test(t) && /Checkpoint: mission start/.test(t), "after reload: Continue + New game + checkpoint shown");

  // kapitan checkpoint saved, restored on Continue
  await btn(pg, "Continue").click();
  await playing(pg);
  await pg.evaluate(() => window.__keris.start("kapitan"));
  await playing(pg);
  check((await stored(pg)).checkpoint === "kapitan", "kapitan checkpoint saved");
  await reload(pg);
  check(/Checkpoint: the Kapitan is down/.test(await text(pg)), "title shows the kapitan checkpoint");
  await btn(pg, "Continue").click();
  await playing(pg);
  let d = await dbg(pg);
  check(d.objective === "escape" && d.guards.some((g) => g.target && g.dead), "Continue restores: Kapitan down, objective is escape");
  check(d.guards.filter((g) => !g.dead).every((g) => g.state === "patrol"), "no guard alert state restored (all patrol)");

  // finish from the checkpoint
  await pg.evaluate(() => {
    const e = window.__keris.debug().exit;
    window.__keris.debugAlertAt(e.x, 0, e.z);
  });
  await pg.waitForFunction(() => window.__keris.debug().phase === "won", null, { timeout: 20000 });
  await sleep(300);
  t = await text(pg);
  check(/Time \d+:\d\d/.test(t) && !/New best/.test(t), "win screen shows time and rating; checkpoint run sets no best");
  const s2 = await stored(pg);
  check(s2.missions["malacca-1511"].completed === true && s2.checkpoint === "start", "win marks mission complete and resets checkpoint");

  // seed bests, reload, see them on title
  await pg.evaluate((k) => {
    const x = JSON.parse(localStorage.getItem(k));
    x.missions["malacca-1511"].bestTime = 187;
    x.missions["malacca-1511"].bestRating = 3;
    localStorage.setItem(k, JSON.stringify(x));
  }, KEY);
  await reload(pg);
  check(/Best: 3:07 · \*\*\* Ghost/.test(await text(pg)), "best time and rating shown on title");

  // settings persist and apply
  await btn(pg, "Settings").click();
  await pg.locator("select[aria-label='Quality']").selectOption("low");
  await pg.locator("input[aria-label='Invert vertical look']").check();
  await pg.locator("input[aria-label='Look sensitivity']").fill("2");
  await sleep(1500);
  const s3 = await stored(pg);
  check(s3.settings.quality === "low" && s3.settings.invertY === true && s3.settings.lookSens === 2, "settings written to storage");
  await btn(pg, "Close").click();
  await pg.waitForFunction(() => window.__keris);
  d = await dbg(pg);
  check(d.quality === "low", "quality override applied immediately on the title screen");
  await reload(pg);
  d = await dbg(pg);
  check(d.quality === "low", "quality override applied on load after reload");
  await btn(pg, "New game").click();
  await playing(pg);
  const pitch0 = (await dbg(pg)).camPitch;
  await pg.evaluate(() => window.__keris.look(0, 100));
  const pitch1 = (await dbg(pg)).camPitch;
  check(pitch1 < pitch0 - 0.1, `invert + 2x sensitivity applied to look (pitch ${pitch0.toFixed(2)} -> ${pitch1.toFixed(2)})`);

  // ?quality= wins for the session without touching the saved value
  await pg.goto("about:blank");
  const { pg: pq } = await open(ctx, "/?quality=high");
  d = await dbg(pq);
  check(d.quality === "high", "?quality=high beats saved low");
  check((await stored(pq)).settings.quality === "low", "saved quality value untouched by the param");
  await btn(pq, "Settings").click();
  check(await pq.locator("select[aria-label='Quality']").isDisabled(), "quality select disabled while the URL param forces it");
  await pq.close();

  // export / import
  await pg.goto(url, { waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 60000 });
  await btn(pg, "Settings").click();
  await pg.locator("summary").click();
  await btn(pg, "Export").click();
  const code = await pg.locator("textarea").inputValue();
  check(/^[A-Za-z0-9+/]+=*$/.test(code) && JSON.parse(Buffer.from(code, "base64").toString()).version === 2, "export gives a base64 JSON code");
  await pg.locator("textarea").fill("not a code");
  await btn(pg, "Import").click();
  check(/not valid/.test(await text(pg)), "invalid import code is rejected");

  // reset with confirm
  await btn(pg, "Reset progress").click();
  check(/Erase your checkpoint/.test(await text(pg)), "reset asks for confirmation");
  await btn(pg, "Cancel").click();
  check((await stored(pg)).checkpoint !== null, "cancel keeps progress");
  await btn(pg, "Reset progress").click();
  await btn(pg, "Yes, reset").click();
  const s4 = await stored(pg);
  check(s4.checkpoint === null && Object.keys(s4.missions).length === 0 && s4.settings.quality === "low", "reset clears progress and bests, keeps settings");
  await btn(pg, "Close").click();
  t = await text(pg);
  check(/Begin/.test(t) && !/Continue/.test(t) && !/Best:/.test(t), "after reset: Begin again, no Continue or Best");
  // import restores
  await btn(pg, "Settings").click();
  await pg.locator("summary").click();
  await pg.locator("textarea").fill(code);
  await btn(pg, "Import").click();
  await btn(pg, "Close").click();
  check(/Continue/.test(await text(pg)), "importing the exported code restores progress");

  check(errs.length === 0, `no console errors ${JSON.stringify(errs)}`);
  await ctx.close();
}

// ---------------------------------------------------------------- bad storage never crashes
const cases = [
  ["corrupt JSON", () => localStorage.setItem("keris:save", "{{{ not json")],
  ["wrong shape", () => localStorage.setItem("keris:save", JSON.stringify({ version: 1, checkpoint: 7, settings: "x", missions: [] }))],
  ["newer version", () => localStorage.setItem("keris:save", JSON.stringify({ version: 99, checkpoint: "kapitan" }))],
  [
    "storage blocked",
    () => {
      const boom = () => {
        throw new DOMException("blocked", "SecurityError");
      };
      for (const m of ["getItem", "setItem", "removeItem"]) Storage.prototype[m] = boom;
    },
  ],
];
for (const [name, init] of cases) {
  console.log(`\n== ${name} ==`);
  const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
  await ctx.addInitScript(init);
  const { pg, errs } = await open(ctx);
  const t = await text(pg);
  check(/Begin/.test(t) && !/Continue/.test(t), "falls back to defaults (Begin, no Continue)");
  await btn(pg, "Begin").click();
  await pg.keyboard.press("Space"); // skip the first-run intro
  await playing(pg);
  await pg.evaluate(() => window.__keris.pause());
  check((await dbg(pg)).phase === "paused", "game plays normally");
  check(errs.length === 0, `no console errors ${JSON.stringify(errs)}`);
  await ctx.close();
}

// ---------------------------------------------------------------- touch UI
{
  console.log("\n== touch 667x375 ==");
  const ctx = await b.newContext({ viewport: { width: 667, height: 375 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  await ctx.addInitScript(
    (k) => {
      if (!localStorage.getItem(k))
        localStorage.setItem(
          k,
          JSON.stringify({ version: 1, checkpoint: "kapitan", missions: { "malacca-1511": { completed: true, attempts: 3, bestTime: 245, bestRating: 2 } }, settings: { quality: "auto", lookSens: 1, invertY: false } }),
        );
    },
    KEY,
  );
  const { pg, errs } = await open(ctx);
  const t = await text(pg);
  check(/Continue/.test(t) && /Best: 4:05/.test(t), "touch title shows Continue and best stats");
  check((await dbg(pg)).quality === "low", "auto quality still low on touch");
  await btn(pg, "Settings").tap();
  await sleep(300);
  const ok = await pg.evaluate(() => {
    const p = document.querySelector(".overlay.settings .panel");
    const r = p.getBoundingClientRect();
    const fits = r.left >= 0 && r.right <= innerWidth && r.top >= 0 && r.bottom <= innerHeight + 1;
    return fits || (p.scrollHeight > p.clientHeight && getComputedStyle(p).overflowY !== "hidden");
  });
  check(ok, "settings panel fits the phone viewport or scrolls");
  await btn(pg, "Close").tap();
  await btn(pg, "Continue").tap();
  await playing(pg);
  check((await dbg(pg)).objective === "escape", "touch Continue restores the kapitan checkpoint");
  check((await pg.locator(".tbtn").count()) === 7, "touch controls render after Continue");
  check(errs.length === 0, `no console errors ${JSON.stringify(errs)}`);
  await ctx.close();
}

await b.close();
console.log(fails.length ? `\n${fails.length} FAILED` : "\nall passed");
process.exit(fails.length ? 1 : 0);
