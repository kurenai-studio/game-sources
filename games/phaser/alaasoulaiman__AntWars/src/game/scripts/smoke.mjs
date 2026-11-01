// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Smoke run for slice 1. Serves the game on 127.0.0.1 only (never 0.0.0.0), opens it in the installed Google Chrome
// at an iPhone viewport (390 x 844 CSS px, device scale 3, touch), plays a scripted run with a held thumb stick,
// counts console errors and failed requests, samples frame times and writes numbered screenshots to ../_proof/.
//   node scripts/smoke.mjs              the built dist/ through vite preview: play until round 2 is under way
//   node scripts/smoke.mjs --round 8    the built dist/ as a practice run from round 8 (elites, breathers, death)
//   node scripts/smoke.mjs --dev        the dev server that START_HERE.bat runs: a boot check
// SMOKE_THUMB_X_FRAC moves the thumb across the canvas (0.75 = the right half; the stick works anywhere since feel round 1).
// SMOKE_SHOT_FROM starts the screenshot numbers there, so a new run numbers its shots after the last ones in _proof.
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';
import { build as viteBuild, createServer, preview } from 'vite';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
// SMOKE_PROOF_DIR sends a dry run's screenshots and record somewhere else, so only proof runs land in _proof.
const proof = process.env.SMOKE_PROOF_DIR ? path.resolve(process.env.SMOKE_PROOF_DIR) : path.resolve(root, '..', '_proof');
const argv = process.argv.slice(2);
const dev = argv.includes('--dev');
const desktop = argv.includes('--desktop');
const roundArg = argv.includes('--round') ? Number(argv[argv.indexOf('--round') + 1]) : null;
const startRound = Number.isInteger(roundArg) && roundArg >= 1 ? roundArg : null;
const long = argv.includes('--long');
const growth = argv.includes('--growth');
/** Slice 3: the Colony flow (the title, the ladder switch, a death that banks, the nest, a stronger next run, Pure). */
const colonyFlow = argv.includes('--colony');
/** Slice 3, M3: the juice in the real game and the mute switch held across a reload. */
const juiceFlow = argv.includes('--juice');
/**
 * Slice 4: SMOKE_S4=econ (a real run to round 8 that buys the damage line three times by taps, the steps read off the
 * card, the predator speed bands read at rounds 4 and 5), SMOKE_S4=boss with --round 10 (the Scythe Mantis appears,
 * one sweep's hit measured against the cap, then it dies), SMOKE_S4=elements with --round 14 (frost and spark picked
 * through the game's own pick, a shock puddle on a kill, the mutated ant, frames with 20 alive and the elements on).
 */
const s4 = argv.includes('--slice4') ? process.env.SMOKE_S4 || 'econ' : null;
/**
 * Lane G7, M1: the installable app (the worker takes over, Chrome's install check and its reading of the manifest, a
 * reload with no network, a second real build at the same address and the tap on the new version line).
 */
const pwaFlow = argv.includes('--pwa');
/** Lane G7, M2: the title on a fresh phone (the How to play card by itself once, GOT IT, a reload, its button, Play). */
const titleFlow = argv.includes('--title');
/**
 * Lane G7, M3: the daily challenge. Player A taps DAILY on a fixed day (?debug&day=, SMOKE_DAY, 2026-10-25 by default),
 * stands still and takes every pick by its first card to round 4, then dies (a Daily death screen); a fresh phone
 * (player B) plays the same day the same way; then a fresh phone on the next day. A and B must meet the same spawns
 * and offers through round 3, the next day others.
 */
const dailyFlow = argv.includes('--daily');
// Lane G9: two real level ups and a break sheet, each read twice 3 s apart with the cards up, shot, tapped, read again.
const pauseFlow = argv.includes('--pause');
// Lane N1, M2: the stats tab on the phone (runStatsFlow).
const statsFlow = argv.includes('--stats');
// Lane N1, M3: the thumb stick's base stays where the first touch landed (runStickFlow).
const stickFlow = argv.includes('--stick');
const SMOKE_DAY = process.env.SMOKE_DAY || '2026-10-25';
/** The last round players A and B compare (3 by default; a teeth run may stop after round 1). */
const DAILY_UNTIL = Number(process.env.SMOKE_DAILY_UNTIL ?? 3);
const LONG_MS = Number(process.env.SMOKE_LONG_MS ?? 480_000);
/** The round the long bot must reach (4 in slice 1; slice 2 runs it to 26 in segments joined by the run save). */
const LONG_TARGET = Number(process.env.SMOKE_LONG_TARGET ?? 4);
const mode = desktop ? 'desktop' : dev ? 'dev' : long ? 'long' : growth ? 'growth' : colonyFlow ? 'colony' : juiceFlow ? 'juice' : pwaFlow ? 'pwa' : titleFlow ? 'title' : dailyFlow ? 'daily' : pauseFlow ? 'pause' : statsFlow ? 'stats' : stickFlow ? 'stick' : s4 ? `slice4${s4}` : startRound ? `round${startRound}` : 'build';
// SMOKE_TAG renames the output files, so a side check never overwrites a main run's evidence.
const fileTag = process.env.SMOKE_TAG || mode;
const PLAY_LIMIT_MS = 100_000;
const PRACTICE_MS = 26_000;
mkdirSync(proof, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (...a) => console.log(`[smoke ${new Date().toISOString()}]`, ...a);

let server;
let base;
if (dev) {
  server = await createServer({ root, server: { host: '127.0.0.1', port: 5174, strictPort: true }, logLevel: 'warn' });
  await server.listen();
  base = 'http://127.0.0.1:5174/';
} else {
  // SMOKE_PORT and SMOKE_OUTDIR let a long bot serve a frozen copy of a build on its own port while the next build runs.
  const port = Number(process.env.SMOKE_PORT ?? 4173);
  const outDir = process.env.SMOKE_OUTDIR || null;
  server = await preview({ root, ...(outDir ? { build: { outDir } } : {}), preview: { host: '127.0.0.1', port, strictPort: true }, logLevel: 'warn' });
  base = `http://127.0.0.1:${port}/`;
}
// The read only hook window.__antwars exists only with ?debug (VG2 note 6). SMOKE_QUERY adds more flags.
const extraQuery = process.env.SMOKE_QUERY ? `&${process.env.SMOKE_QUERY}` : '';
const url = startRound ? `${base}?debug&round=${startRound}${extraQuery}` : `${base}?debug${extraQuery}`;
log('serving', url, dev ? '(dev server)' : '(built dist via vite preview)');

// Lean flags keep the whole headless Chrome (all its processes) near a 500 MB budget.
const chromeArgs = [
  '--renderer-process-limit=1',
  '--disable-gpu-shader-disk-cache',
  '--disable-features=Translate,OptimizationHints,MediaRouter,CalculateNativeWinOcclusion,AudioServiceOutOfProcess',
];
// Lane G7: Chrome refuses to install from a private window (its install check says in-incognito), so the installable
// app flow runs in a fresh profile on disk (a temp folder, deleted at the end) instead of Playwright's private context.
const pwaProfile = pwaFlow ? path.join(tmpdir(), `playwright_chromiumdev_profile-antwars-g7-${process.pid}`) : null;
const browser = pwaFlow ? null : await chromium.launch({ channel: 'chrome', headless: true, args: chromeArgs });
// Slice 2: the long bot runs in segments joined by the run save. SMOKE_STATE_IN loads the phone storage a segment left
// (Playwright storageState, written to SMOKE_STATE_OUT at the end), so the next one opens on the title with Continue.
const stateIn = process.env.SMOKE_STATE_IN && existsSync(process.env.SMOKE_STATE_IN) ? process.env.SMOKE_STATE_IN : undefined;
const stateOut = process.env.SMOKE_STATE_OUT || null;
/** The long bot stops 3 s into the break after this round (the save has settled), so the next segment continues it. */
const stopAfter = process.env.SMOKE_STOP_AFTER ? Number(process.env.SMOKE_STOP_AFTER) : null;
const phoneOptions = {
  viewport: { width: 390, height: 844 },
  screen: { width: 390, height: 844 },
  deviceScaleFactor: 3,
  isMobile: true,
  hasTouch: true,
  userAgent:
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
};
const context = desktop
  ? await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, isMobile: false, hasTouch: false })
  : pwaFlow
    ? await chromium.launchPersistentContext(pwaProfile, { channel: 'chrome', headless: true, args: chromeArgs, ...phoneOptions })
    : await browser.newContext({ storageState: stateIn, ...phoneOptions });
const page = pwaFlow && context.pages().length > 0 ? context.pages()[0] : await context.newPage();
// Lane G7, M2: the How to play card opens by itself on a phone's first title. Every other flow plays as a phone that
// has seen it (their checks are their own screens); the title flow starts on a fresh phone and closes it with a tap.
if (!titleFlow) {
  await context.addInitScript(() => {
    try {
      if (localStorage.getItem('antwars.howto.v1') === null) localStorage.setItem('antwars.howto.v1', '1');
    } catch {
      // A page with no storage (about:blank) has nothing to set.
    }
  });
}
const errors = [];
const warnings = [];
const httpErrors = [];
page.on('console', (m) => {
  if (m.type() === 'error') errors.push(m.text());
  else if (m.type() === 'warning') warnings.push(m.text());
});
page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
page.on('requestfailed', (r) => httpErrors.push(`failed: ${r.url()} ${r.failure()?.errorText ?? ''}`));
page.on('response', (r) => {
  if (r.status() >= 400) httpErrors.push(`http ${r.status()}: ${r.url()}`);
});

const snap = () => page.evaluate(() => (window.__antwars ? window.__antwars.snapshot() : null));
const shotFrom = Number(process.env.SMOKE_SHOT_FROM ?? 1);
let shot = Number.isInteger(shotFrom) && shotFrom >= 1 ? shotFrom - 1 : 0;
const shots = [];
const shotNames = new Set();
const screenshot = async (name) => {
  shot += 1;
  const file = path.join(proof, `${String(shot).padStart(2, '0')}_${fileTag}_${name}.png`);
  await page.screenshot({ path: file });
  shots.push(file);
  shotNames.add(name);
  log('screenshot', file);
};

// VG2 note 6: without ?debug the page must expose no hook at all.
let hookWithoutDebug = null;
if (growth) {
  await page.goto(base, { waitUntil: 'load' });
  await sleep(1500);
  hookWithoutDebug = await page.evaluate(() => typeof window.__antwars);
  log('hook without ?debug:', hookWithoutDebug);
}
const t0 = Date.now();
await page.goto(url, { waitUntil: 'load' });
await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
const env = await page.evaluate(() => {
  const g = window.__antwars.game;
  const c = document.createElement('canvas');
  const gl = c.getContext('webgl');
  const ext = gl && gl.getExtension('WEBGL_debug_renderer_info');
  return {
    renderer: g.renderer.type === 2 ? 'WEBGL' : g.renderer.type === 1 ? 'CANVAS' : String(g.renderer.type),
    gpu: ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : 'unknown',
    gameSize: `${g.scale.width}x${g.scale.height}`,
    canvasCss: `${g.canvas.style.width} x ${g.canvas.style.height}`,
    dpr: window.devicePixelRatio,
    inner: `${window.innerWidth}x${window.innerHeight}`,
  };
});
const bootMs = Date.now() - t0;
log('booted in', bootMs, 'ms', JSON.stringify(env));
await sleep(600);
await screenshot('boot');

const cdp = desktop ? null : await context.newCDPSession(page);
const touch = (type, points) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points });
// By default the thumb goes down a quarter of the way across the canvas and low, where a left thumb rests.
const rect = await page.evaluate(() => {
  const r = window.__antwars.game.canvas.getBoundingClientRect();
  return { x: r.x, y: r.y, w: r.width, h: r.height };
});
const thumbFrac = Number(process.env.SMOKE_THUMB_X_FRAC ?? 0.25);
const THUMB = { x: Math.round(rect.x + rect.w * thumbFrac), y: Math.round(rect.y + rect.h * 0.78) };
let sawMovingWhileHeld = false;
/** The farthest the ant got (world units) inside the first 300 ms of a held stick: proof the thumb moves it, not just a flag. */
let antMovedByThumb = 0;
/** Holds the stick toward (dx, dy) CSS px for ms (a touch on the phone, a mouse drag on the desktop), then lets go. */
async function hold(dx, dy, ms) {
  const before = await snap();
  if (desktop) {
    await page.mouse.move(THUMB.x, THUMB.y);
    await page.mouse.down();
    await page.mouse.move(THUMB.x + dx, THUMB.y + dy, { steps: 4 });
  } else {
    await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 1 }]);
    await sleep(40);
    await touch('touchMove', [{ x: THUMB.x + dx, y: THUMB.y + dy, id: 1 }]);
  }
  await sleep(300);
  const mid = await snap();
  if (mid && mid.moving === true) sawMovingWhileHeld = true;
  if (before && mid) antMovedByThumb = Math.max(antMovedByThumb, Math.hypot(mid.antX - before.antX, mid.antY - before.antY));
  const end = Date.now() + ms - 300;
  while (Date.now() < end) {
    await sleep(250);
    if (desktop) await page.mouse.move(THUMB.x + dx + (Math.random() - 0.5), THUMB.y + dy);
    else await touch('touchMove', [{ x: THUMB.x + dx + (Math.random() - 0.5), y: THUMB.y + dy, id: 1 }]);
  }
  if (desktop) await page.mouse.up();
  else await touch('touchEnd', []);
}

let maxRound = 0;
let sawBreak = false;
const kindsSeen = { armyAnt: 0, wasp: 0, spider: 0, termite: 0, beetle: 0, antlion: 0, centipede: 0, ember: 0, moth: 0, mantis: 0, hornet: 0 };
const timeline = [];
const note = async (label) => {
  const s = await snap();
  const k = await page.evaluate(() => (window.__antwars ? window.__antwars.kinds() : null));
  if (k) for (const key of Object.keys(kindsSeen)) kindsSeen[key] = Math.max(kindsSeen[key], k[key] ?? 0);
  if (s) {
    maxRound = Math.max(maxRound, s.round);
    if (s.phase === 'break') sawBreak = true;
    timeline.push({ t: +((Date.now() - t0) / 1000).toFixed(1), label, phase: s.phase, round: s.round, alive: s.alive, left: s.left, hp: s.hp, nectar: s.nectar, kills: s.kills, kinds: k });
  }
  return s;
};

async function sampleFrames(ms) {
  return page.evaluate(
    (ms) =>
      new Promise((resolve) => {
        const loop = window.__antwars.game.loop;
        const orig = loop.callback;
        const work = [];
        loop.callback = (time, delta) => {
          const a = performance.now();
          orig(time, delta);
          work.push(performance.now() - a);
        };
        const deltas = [];
        let last = performance.now();
        const end = last + ms;
        const stats = (a) => {
          const s = [...a].sort((x, y) => x - y);
          const pick = (q) => s[Math.min(s.length - 1, Math.floor(q * s.length))];
          const mean = s.reduce((x, y) => x + y, 0) / Math.max(1, s.length);
          return { n: s.length, mean: +mean.toFixed(2), p50: +pick(0.5).toFixed(2), p95: +pick(0.95).toFixed(2), max: +s[s.length - 1].toFixed(2) };
        };
        const tick = (now) => {
          deltas.push(now - last);
          last = now;
          if (now < end) requestAnimationFrame(tick);
          else {
            loop.callback = orig;
            resolve({
              rafDelta: stats(deltas.slice(1)),
              stepWork: stats(work),
              heapMB: performance.memory ? +(performance.memory.usedJSHeapSize / 1048576).toFixed(1) : null,
            });
          }
        };
        requestAnimationFrame(tick);
      }),
    ms,
  );
}

/** Sums the memory of the Chrome processes this run launched (they share the Playwright temp profile). */
function chromeMemoryMB() {
  try {
    const ps =
      "$p = Get-CimInstance Win32_Process -Filter \"Name='chrome.exe'\" | Where-Object { $_.CommandLine -like '*playwright_chromiumdev_profile*' }; " +
      "'{0} {1} {2}' -f @($p).Count, ($p | Measure-Object -Property WorkingSetSize -Sum).Sum, ($p | Measure-Object -Property PrivatePageCount -Sum).Sum";
    const out = execFileSync('powershell.exe', ['-NoProfile', '-Command', ps], { encoding: 'utf8', timeout: 20_000, windowsHide: true });
    const [count, ws, priv] = out.trim().split(/\s+/).map(Number);
    return { processes: count, workingSetMB: Math.round(ws / 1048576), privateMB: Math.round(priv / 1048576) };
  } catch (e) {
    return { error: String(e).slice(0, 200) };
  }
}

let frames = null;
let longRun = null;
let restart = { tried: false, ok: null };
let relaunch = null;
let memory = null;
const takeSample = async () => {
  frames = await sampleFrames(5000);
  memory = chromeMemoryMB();
  log('frame sample', JSON.stringify(frames), 'chrome memory', JSON.stringify(memory));
};

const pattern = [
  [0, -70, 2600], [70, 0, 2000], [0, 70, 2600], [-70, 0, 2000],
  [50, -50, 1800], [-50, 50, 1800], [0, -70, 1500], [0, 70, 1500],
];

const hudNow = () => page.evaluate(() => (window.__antwars && window.__antwars.hud ? window.__antwars.hud() : null));
/** Lane G9: the run, the HUD and every live predator, dart and shot, read in one call (one frame's state). */
const yardRead = () =>
  page.evaluate(() => {
    const a = window.__antwars;
    return a ? { snap: a.snapshot(), hud: a.hud ? a.hud() : null, yard: a.yard ? a.yard() : null } : { snap: null, hud: null, yard: null };
  });
/** Lane G9: what a pick sheet must leave alone, as plain data (the run's counts and places, the Yard's clock, the HUD's countdown). */
const heldState = (r) => {
  const s = r.snap;
  return {
    phase: s.phase, round: s.round, alive: s.alive, left: s.left, hp: s.hp, nectar: s.nectar, kills: s.kills, breakLeft: s.breakLeft,
    antX: s.antX, antY: s.antY, xp: s.xp, level: s.level, yardMs: s.yardMs, spawns: Array.isArray(s.spawns) ? s.spawns.length : null,
    puddles: s.elements ? s.elements.puddles : null, burning: s.elements ? s.elements.burning : null, hunters: s.hunters,
    yard: r.yard, countdown: r.hud ? r.hud.countdown : null,
  };
};
/** A HUD point in game units to a CSS point on the page. */
function gameCss(gx, gy) {
  const [GW] = env.gameSize.split('x').map(Number);
  const k = rect.w / GW;
  return { x: rect.x + gx * k, y: rect.y + gy * k };
}
/**
 * A short still tap (60 ms, no move) at a CSS point, with its own finger id. The two events carry their own times, 60 ms
 * apart, as a real finger's do: a busy page that takes the second event late must not turn the tap into a slow press.
 */
async function tapAt(p, id = 5) {
  const ts = Date.now() / 1000;
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: p.x, y: p.y, id }], timestamp: ts });
  await sleep(60);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [], timestamp: ts + 0.06 });
  await sleep(150);
}
/**
 * Slice 3: every run opens on the title. Taps PLAY (once the title's read guard has passed) and waits for the run to
 * leave the title; a long bot segment that loads a save taps CONTINUE in its own loop instead.
 */
async function passTitle() {
  let s = await snap();
  if (!s || s.phase !== 'title') return { tapped: false, phase: s ? s.phase : null };
  await sleep(450);
  const h = await hudNow();
  if (!h || !h.title || !h.title.shown) return { tapped: false, phase: s.phase };
  await tapAt(gameCss(h.title.play.x, h.title.play.y));
  const end = Date.now() + 3000;
  s = await snap();
  while (Date.now() < end && s && s.phase === 'title') {
    await sleep(100);
    s = await snap();
  }
  const r = { tapped: true, phase: s ? s.phase : null, ladder: s ? s.ladder : null };
  log('title play', JSON.stringify(r));
  return r;
}
const picksTaken = [];
/** Slice 2: takes the waiting pick by a tap on card i of the sheet, once the sheet's read guard has passed. */
async function tapPick(i = 0) {
  let h = await hudNow();
  if (!h || !h.pick || !h.pick.shown || h.pick.cards.length === 0) return null;
  if (h.pick.readyIn > 0) {
    await sleep(h.pick.readyIn + 40);
    h = await hudNow();
    if (!h.pick.shown || h.pick.cards.length === 0) return null;
  }
  let card = h.pick.cards[Math.min(i, h.pick.cards.length - 1)];
  // Let a frame or two pass first: a screenshot just before can stall the page past the 300 ms a tap allows.
  await sleep(250);
  // Slice 3: read the sheet again right before the tap. A round that ended meanwhile moves the sheet up and a new level
  // re-arms its read guard (both by design), so the tap goes where the card is now, once the guard is over.
  for (let k = 0; k < 3; k++) {
    const h2 = await hudNow();
    if (!h2 || !h2.pick || !h2.pick.shown || h2.pick.cards.length === 0) return null;
    const same = h2.pick.cards.find((c) => c.id === card.id) ?? h2.pick.cards[Math.min(i, h2.pick.cards.length - 1)];
    card = same;
    if (h2.pick.readyIn <= 0) break;
    await sleep(h2.pick.readyIn + 60);
  }
  // Lane G9: the guard and the card are read in the same call as the run, right before the tap. On 04bf6d4 the round ran
  // on behind the sheet, and a round that ended between the bot's last read and its tap moved the sheet up and re-armed
  // its guard with the same pick waiting (VG8 note 4, the tap at 288 and 300 ms; tapMs is the bot's whole tap call, a
  // 60 ms press by the event clock), so the tap missed and was not marked raced. Now the Yard holds still under the sheet.
  let pre = await yardRead();
  for (let k = 0; k < 3 && pre.hud && pre.hud.pick.shown && pre.hud.pick.readyIn > 0; k++) {
    await sleep(pre.hud.pick.readyIn + 60);
    pre = await yardRead();
  }
  if (!pre.hud || !pre.hud.pick.shown || pre.hud.pick.cards.length === 0) return null;
  card = pre.hud.pick.cards.find((c) => c.id === card.id) ?? pre.hud.pick.cards[Math.min(i, pre.hud.pick.cards.length - 1)];
  const before = pre.snap;
  const tapStart = Date.now();
  await tapAt(gameCss(card.x, card.y));
  const tapMs = Date.now() - tapStart;
  const after = await snap();
  const r = {
    id: card.id,
    title: h.pick.title,
    level: before.level,
    stackBefore: before.stacks[card.id],
    stackAfter: after.stacks[card.id],
    pendingBefore: before.pending,
    pendingAfter: after.pending,
    hpBefore: before.hp,
    hpAfter: after.hp,
    maxHpAfter: after.maxHp,
    tapMs,
  };
  // The pick applied when its power's stack rose by one. The waiting count usually falls by one too, but a pick that
  // arrives in the same moment (Royal Jelly at a rush's end) keeps it level; that is still an applied pick.
  r.ok = r.stackAfter === r.stackBefore + 1 && r.pendingAfter <= r.pendingBefore;
  if (!r.ok) {
    // Slice 4: a tap that met a new pick (Royal Jelly, a boss) lands inside the sheet's 300 ms read guard, which that
    // pick re-arms by design. Such a tap is marked raced (the loop takes the pick on its next pass); any other failed
    // tap still fails the check.
    await sleep(400);
    const later = await snap();
    r.pendingLater = later ? later.pending : null;
    r.raced = r.stackAfter === r.stackBefore && later !== null && later.pending > r.pendingBefore;
  }
  picksTaken.push(r);
  log('pick', JSON.stringify(r));
  return r;
}
let huntRun = null;
let juiceRun = null;
let pauseRun = null;
/**
 * Lane G9: a pick sheet is up. Reads the Yard twice 3 s apart with a shot each (the same clock, the same Yard), takes
 * every waiting pick (a chained sheet keeps the Yard held), then reads it again 1 s after the last tap.
 */
async function holdAndTap(label) {
  const r = { label };
  await sleep(200);
  const a = await yardRead();
  await screenshot(`${label}_cards_up_a`);
  await sleep(3000);
  const b = await yardRead();
  await screenshot(`${label}_cards_up_b`);
  const sa = heldState(a);
  const sb = heldState(b);
  r.a = { phase: sa.phase, round: sa.round, yardMs: sa.yardMs, breakLeft: sa.breakLeft, countdown: sa.countdown, hp: sa.hp, nectar: sa.nectar, kills: sa.kills, ant: [sa.antX, sa.antY], foes: sa.yard ? sa.yard.foes.length : null, pending: a.snap.pending };
  r.b = { phase: sb.phase, round: sb.round, yardMs: sb.yardMs, breakLeft: sb.breakLeft, countdown: sb.countdown, hp: sb.hp, nectar: sb.nectar, kills: sb.kills, ant: [sb.antX, sb.antY], foes: sb.yard ? sb.yard.foes.length : null, pending: b.snap.pending };
  r.same = JSON.stringify(sa) === JSON.stringify(sb);
  r.frozen = a.snap.frozen === true && b.snap.frozen === true;
  r.picks = [];
  r.chainHeld = true;
  for (let k = 0; k < 4; k++) {
    const p = await tapPick(0);
    if (!p) break;
    r.picks.push({ id: p.id, ok: p.ok, pendingAfter: p.pendingAfter, tapMs: p.tapMs });
    if (p.pendingAfter > 0) {
      // A chained sheet: the next offer is up at once and the Yard is still held at the same clock.
      await sleep(150);
      const c = await yardRead();
      if (!(c.snap.frozen === true && c.snap.yardMs === sb.yardMs)) r.chainHeld = false;
    } else break;
  }
  await sleep(1000);
  const c = await yardRead();
  await screenshot(`${label}_after_tap`);
  r.c = { phase: c.snap.phase, yardMs: c.snap.yardMs, breakLeft: c.snap.breakLeft, countdown: c.hud ? c.hud.countdown : null, frozen: c.snap.frozen, pending: c.snap.pending };
  r.resumed = c.snap.frozen === false && c.snap.yardMs > sb.yardMs;
  r.ok = r.same && r.frozen && r.picks.length > 0 && r.picks.every((x) => x.ok) && r.chainHeld && r.resumed;
  log('held sheet', JSON.stringify(r));
  return r;
}
/**
 * Lane G9c (design note, 2026-10-25): a sheet in a break with the ant in the nest. A real tap on the shop's damage card under
 * the cards is refused and changes nothing (the nectar, the lines, the perks, the waiting pick, NEXT ROUND IN, the Yard
 * clock), read twice 3 s apart with a shot each; after the pick the countdown runs on from the same number and the same
 * card's tap buys.
 */
async function buyUnderSheet() {
  let s = await snap();
  // A break with time left to walk in and look: a short one is played out and the next one taken.
  const end = Date.now() + 90_000;
  let k = 0;
  while (Date.now() < end && s && s.phase !== 'dead' && !(s.phase === 'break' && s.breakLeft >= 9 && s.pending === 0)) {
    if (s.phase === 'break') await sleep(250);
    else {
      const [dx, dy, ms] = pattern[k % pattern.length];
      k += 1;
      await hold(dx, dy, Math.min(ms, 1400));
    }
    await clearPicks();
    s = await snap();
  }
  if (!s || s.phase !== 'break') return { ok: false, phase: s ? s.phase : null };
  s = await walkNest(true, 6000);
  if (!s || s.phase !== 'break' || !s.inNest || s.shop !== 'open') return { ok: false, reason: 'not in the open shop', phase: s ? s.phase : null, shop: s ? s.shop : null };
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    g.nectar = Math.max(g.nectar, 5000);
    g.queuePicks(1, 'ROYAL JELLY: A FREE PICK');
  });
  await sleep(450);
  const read = async () => {
    const x = await yardRead();
    const v = x.snap;
    return {
      phase: v.phase, round: v.round, nectar: v.nectar, spent: v.spent, lines: v.lines, owned: v.owned, pending: v.pending, offer: v.offer,
      breakLeft: v.breakLeft, yardMs: v.yardMs, frozen: v.frozen, inNest: v.inNest, shop: v.shop, ant: [v.antX, v.antY],
      countdown: x.hud ? x.hud.countdown : null, sheet: x.hud ? x.hud.pick.shown : null, shopShown: x.hud ? x.hud.cards : null,
    };
  };
  const shown = (t) => {
    const m = /^NEXT ROUND IN ([0-9]+)$/.exec(t || '');
    return m ? Number(m[1]) : null;
  };
  const card = await shopCard('damage');
  const r = { card: card ? { x: card.x, y: card.y, price: card.price, line: card.line } : null };
  if (!card) return { ...r, ok: false, reason: 'no damage card' };
  r.a = await read();
  await screenshot('buy_under_sheet_cards_up_a');
  await tapAt(gameCss(card.x, card.y), 6);
  await sleep(2500);
  await tapAt(gameCss(card.x, card.y), 6);
  await sleep(200);
  r.b = await read();
  await screenshot('buy_under_sheet_cards_up_b');
  const cardB = await shopCard('damage');
  r.cardB = cardB ? { price: cardB.price, line: cardB.line } : null;
  // Two taps on the card 2.5 s apart under the cards: nothing bought, nothing moved, the same number on the countdown.
  r.refused =
    r.a.phase === 'break' && r.a.sheet === true && r.a.shopShown === true && r.a.shop === 'open' && r.a.frozen === true &&
    JSON.stringify(r.a) === JSON.stringify(r.b) && !!r.cardB && r.cardB.price === r.card.price && r.cardB.line === r.card.line;
  r.numbers = [shown(r.a.countdown), shown(r.b.countdown)];
  const p = await tapPick(0);
  r.picked = !!p && p.ok;
  const tTap = Date.now();
  await sleep(1000);
  r.c = await read();
  r.c.wallS = +((Date.now() - tTap) / 1000).toFixed(2);
  r.numbers.push(shown(r.c.countdown));
  // After the pick the countdown runs on from the value it stood at (no refill, no jump), then the same card buys.
  const drop = r.b.breakLeft - r.c.breakLeft;
  r.resumed = r.c.phase === 'break' && r.c.frozen === false && r.c.yardMs > r.b.yardMs && drop > 0 && drop <= r.c.wallS + 0.5;
  const price = priceOf(r.card.price);
  await tapAt(gameCss(card.x, card.y), 6);
  await sleep(250);
  r.d = await read();
  await screenshot('buy_under_sheet_after_tap_bought');
  r.bought = r.d.lines.damage === r.b.lines.damage + 1 && price !== null && Math.abs(r.b.nectar - r.d.nectar - price) < 1e-6 && r.d.spent === r.b.spent + price;
  r.ok = r.refused && r.numbers[0] !== null && r.numbers[0] === r.numbers[1] && r.picked && r.resumed && r.bought;
  log('buy under the sheet', JSON.stringify(r));
  return r;
}
/** Counts the juice frame by frame inside the page: rings out, numbers up, shakes by length, the vignette. */
const installJuiceWatch = () =>
  page.evaluate(() => {
    const w = { frames: 0, maxRings: 0, maxFloats: 0, shakes: {}, floatsRose: 0, floatsFaded: 0, vignetteFrames: 0, last: new Map() };
    window.__g5juice = w;
    const tick = () => {
      const g = window.__antwars.game.scene.getScene('game');
      const hud = window.__antwars.game.scene.getScene('hud');
      if (g && g.rings) {
        w.frames += 1;
        w.maxRings = Math.max(w.maxRings, g.rings.filter((r) => r.visible).length);
        const vis = g.floats.filter((t) => t.visible);
        w.maxFloats = Math.max(w.maxFloats, vis.length);
        for (const t of vis) {
          const prev = w.last.get(t);
          if (prev && prev.text === t.text) {
            if (t.y < prev.y - 0.5) w.floatsRose += 1;
            if (t.alpha < prev.alpha - 0.01) w.floatsFaded += 1;
          }
          w.last.set(t, { y: t.y, alpha: t.alpha, text: t.text });
        }
        const sh = g.cameras.main.shakeEffect;
        if (sh && sh.isRunning) w.shakes[String(sh.duration)] = (w.shakes[String(sh.duration)] || 0) + 1;
        if (hud && hud.vignette && hud.vignette.visible) w.vignetteFrames += 1;
      }
      if (w.frames < 100000) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  });
/** Slice 3, M3: the mute switch (title, reload, held), then a round with the juice counted and the frame time sampled. */
async function runJuiceFlow() {
  const r = { ok: false };
  let h = await waitTitle();
  r.before = { muted: h.mute.muted, icon: h.mute.icon, stored: await readKey('antwars.mute.v1') };
  await tapAt(gameCss(h.mute.x, h.mute.y));
  await sleep(250);
  h = await hudNow();
  r.afterTap = { muted: h.mute.muted, icon: h.mute.icon, stored: await readKey('antwars.mute.v1') };
  await page.reload({ waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  h = await waitTitle();
  r.afterReload = { muted: h.mute.muted, icon: h.mute.icon, stored: await readKey('antwars.mute.v1') };
  await screenshot('title_muted');
  // Sound back on, then a second reload: the switch holds both ways.
  await tapAt(gameCss(h.mute.x, h.mute.y));
  await sleep(250);
  await page.reload({ waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  h = await waitTitle();
  r.soundBack = { muted: h.mute.muted, icon: h.mute.icon, stored: await readKey('antwars.mute.v1') };
  r.muteHolds =
    r.before.muted === false && r.afterTap.muted === true && r.afterTap.icon === 'sound_off' && r.afterTap.stored === '1' &&
    r.afterReload.muted === true && r.afterReload.icon === 'sound_off' && r.soundBack.muted === false && r.soundBack.stored === '0';
  // A run: the first touch (Play) unlocks WebAudio; the juice is counted while the ant fights round 1 and 2.
  await installJuiceWatch();
  await tapAt(gameCss(h.title.play.x, h.title.play.y));
  await sleep(300);
  r.audioState = await page.evaluate(() => {
    const s = window.__antwars.game.sound;
    return s && s.context ? s.context.state : 'none';
  });
  // The big hit first: once a predator is out, the ant stands, every standing volley crits (Build.critChance is the real
  // field) and the predator is set 220 units off the ant; its hit must bring the 70 ms shake.
  const bigEnd = Date.now() + 15_000;
  r.bigHit = null;
  while (Date.now() < bigEnd && !r.bigHit) {
    const placed = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const p = g.predators.getChildren().find((q) => q.active && g.time.now >= q.spawnUntil);
      if (!p) return false;
      g.build.critChance = 1;
      p.body.reset(g.ant.x + 220, g.ant.y);
      return true;
    });
    if (placed) {
      await sleep(900);
      r.bigHit = { shakes: await page.evaluate(() => ({ ...window.__g5juice.shakes })) };
    } else await sleep(200);
  }
  await page.evaluate(() => {
    window.__antwars.game.scene.getScene('game').build.critChance = 0.1;
  });
  let i = 0;
  const end = Date.now() + 22_000;
  let s = await snap();
  while (Date.now() < end && s && s.phase !== 'dead') {
    const [dx, dy, ms] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, Math.min(ms, 1400));
    await clearPicks();
    await sleep(1200);
    s = await snap();
    if (i === 3) await screenshot('juice_round');
    if (i === 4 && !frames) await takeSample();
  }
  // Low health: the harness sets health to a fifth; the vignette must show (and the HUD readout say so).
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    g.hp = Math.round(g.build.maxHp * 0.2);
  });
  await sleep(500);
  const hv = await hudNow();
  await screenshot('low_health');
  const w = await page.evaluate(() => {
    const x = window.__g5juice;
    return { frames: x.frames, maxRings: x.maxRings, maxFloats: x.maxFloats, shakes: x.shakes, floatsRose: x.floatsRose, floatsFaded: x.floatsFaded, vignetteFrames: x.vignetteFrames };
  });
  r.juice = { ...w, vignetteNow: hv.vignette, kills: (await snap()).kills };
  r.ok =
    r.muteHolds && w.maxRings >= 1 && w.maxFloats >= 1 && w.floatsRose > 10 && w.floatsFaded > 10 && !!r.bigHit && !!r.bigHit.shakes['70'] &&
    hv.vignette === true && w.vignetteFrames > 0;
  log('juice', JSON.stringify(r));
  return r;
}
/** Waits until a predator of this kind is out of its hole (or the time runs out); returns its snapshot row. */
async function waitHunter(kind, ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const s = await snap();
    if (!s || s.phase === 'dead') return null;
    if (s.pending > 0) await clearPicks();
    const h = s.hunters.find((x) => x.kind === kind);
    if (h) {
      const ok = await page.evaluate((k) => {
        const g = window.__antwars.game.scene.getScene('game');
        return g.predators.getChildren().some((p) => p.active && p.kind === k && g.time.now >= p.spawnUntil);
      }, kind);
      if (ok) return h;
    }
    await sleep(200);
  }
  return null;
}
/**
 * Slice 3, M2 in the real game (practice runs with ?debug&assist, so the ant lives): a beetle takes half from the
 * front and all from behind; an antlion pulls a still ant into its pit; a centipede turns slowly while the ant runs.
 */
async function runHunt(kind) {
  const r = { kind, ok: false };
  const first = await waitHunter(kind, 60_000);
  r.found = !!first;
  if (!first) {
    log('hunt', JSON.stringify(r));
    return r;
  }
  if (kind === 'beetle') {
    // Front: the ant stands; the beetle walks at it face first. The other predators are cleared off so the darts go to it.
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      for (const p of g.predators.getChildren()) if (p.active && p.kind !== 'beetle') p.disableBody(true, true);
      g.queued = 0;
      const b = g.predators.getChildren().find((p) => p.active && p.kind === 'beetle');
      b.body.reset(g.ant.x + 300, g.ant.y);
      b.heading = Math.PI;
      g.hitLog.length = 0;
    });
    await sleep(1600);
    const front = (await snap()).lastHits.filter((h) => h.kind === 'beetle');
    await screenshot('beetle_front');
    // Behind: the harness turns the beetle's back to the ant (it turns round at 90 degrees a second), the ant fires on.
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const b = g.predators.getChildren().find((p) => p.active && p.kind === 'beetle');
      b.body.reset(g.ant.x + 260, g.ant.y);
      b.heading = 0;
      g.hitLog.length = 0;
    });
    await sleep(700);
    const back = (await snap()).lastHits.filter((h) => h.kind === 'beetle');
    r.front = { hits: front.length, factors: [...new Set(front.map((h) => h.factor))], sample: front.slice(0, 3) };
    r.back = { hits: back.length, factors: [...new Set(back.map((h) => h.factor))], sample: back.slice(0, 3) };
    r.ok =
      front.length >= 2 && front.every((h) => h.factor === 0.5 && Math.abs(h.dealt - h.raw / 2) < 1e-6) &&
      back.length >= 1 && back.some((h) => h.factor === 1 && Math.abs(h.dealt - h.raw) < 1e-6);
  } else if (kind === 'antlion') {
    // The ant is set down 150 units from a live antlion's pit with no stick: the pull alone must draw it in. A control
    // 300 units out (past the pull) must not move.
    const pits = await page.evaluate(() => window.__antwars.pits());
    const pit = pits[first.pit];
    const place = (d) =>
      page.evaluate(
        ([px, py, dd]) => {
          const g = window.__antwars.game.scene.getScene('game');
          for (const p of g.predators.getChildren()) if (p.active && p.kind !== 'antlion') p.disableBody(true, true);
          g.queued = 0;
          g.ant.body.reset(px - dd, py);
        },
        [pit.x, pit.y, d],
      );
    const dist = async () => {
      const s = await snap();
      return +Math.hypot(s.antX - pit.x, s.antY - pit.y).toFixed(1);
    };
    await place(300);
    await sleep(100);
    const c0 = await dist();
    await sleep(1000);
    const c1 = await dist();
    await place(150);
    await sleep(50);
    const d0 = await dist();
    await sleep(500);
    const d1 = await dist();
    await screenshot('antlion_pull');
    await sleep(500);
    const d2 = await dist();
    r.pit = pit;
    r.control = { from: c0, after1s: c1, moved: +(c0 - c1).toFixed(1) };
    r.pull = { from: d0, after500ms: d1, after1000ms: d2, pulledIn: +(d0 - d2).toFixed(1) };
    // pitPull(150) is 97.5 a second and grows inward, so about 50 units in the first half second.
    r.ok = Math.abs(r.control.moved) < 3 && d0 - d1 >= 35 && d1 - d2 > 0 && d2 < d0 - 70;
  } else if (kind === 'centipede') {
    // The ant runs across the centipede's path; its heading is sampled every frame inside the page for 3 s.
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      for (const p of g.predators.getChildren()) if (p.active && p.kind !== 'centipede') p.disableBody(true, true);
      g.queued = 0;
      const c = g.predators.getChildren().find((p) => p.active && p.kind === 'centipede');
      c.body.reset(g.ant.x + 320, g.ant.y);
      c.heading = Math.PI;
      // Sampled on the Yard's own steps (its postupdate event): the turn per step over that step's clock (capped at 50 ms
      // as the Yard caps it), so a page frame that holds two steps or none cannot fake a fast or a slow turn.
      const w = { rates: [], speeds: [], segs: 0, last: null };
      window.__g5turn = w;
      const onStep = (_time, delta) => {
        if (!c.active || w.rates.length >= 400) {
          g.events.off('postupdate', onStep);
          return;
        }
        if (w.last !== null) {
          let d = c.heading - w.last;
          while (d > Math.PI) d -= 2 * Math.PI;
          while (d < -Math.PI) d += 2 * Math.PI;
          const dt = Math.min(delta, 50) / 1000;
          if (dt > 0) w.rates.push(Math.abs(d) / dt);
          w.speeds.push(Math.hypot(c.body.velocity.x, c.body.velocity.y));
        }
        w.last = c.heading;
        w.segs = c.segPos.length;
      };
      g.events.on('postupdate', onStep);
    });
    await hold(0, -70, 1500);
    await screenshot('centipede');
    await hold(0, 70, 1500);
    const w = await page.evaluate(() => window.__g5turn);
    const deg = (x) => +((x * 180) / Math.PI).toFixed(1);
    const sorted = [...w.rates].sort((a, b) => a - b);
    const sp = [...w.speeds].sort((a, b) => a - b);
    r.turn = {
      frames: w.rates.length,
      maxDegPerS: deg(sorted[sorted.length - 1] ?? 0),
      p90DegPerS: deg(sorted[Math.floor(sorted.length * 0.9)] ?? 0),
      medianSpeed: +(sp[Math.floor(sp.length / 2)] ?? 0).toFixed(1),
      segments: w.segs,
    };
    const hits = (await snap()).lastHits.filter((h) => h.kind === 'centipede');
    r.bodyHits = hits.filter((h) => h.body).length;
    // At most 70 degrees a second (a frame of 50 ms caps at 3.5 degrees), but turning: over 30 at its fastest.
    r.ok = r.turn.frames >= 60 && r.turn.maxDegPerS <= 70 * 1.05 && r.turn.maxDegPerS >= 30 && r.turn.segments === 7 && r.turn.medianSpeed >= 150;
  }
  log('hunt', JSON.stringify(r));
  return r;
}
let growthRun = null;
let colonyRun = null;
let s4Run = null;

/** Slice 4: the live predators' spawn speeds and their speeds this frame, read from the game. */
const liveSpeeds = () =>
  page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    const out = [];
    for (const p of g.predators.getChildren()) {
      if (p.active && g.time.now >= p.spawnUntil) out.push({ kind: p.kind, speed: +p.speed.toFixed(2), v: +Math.hypot(p.body.velocity.x, p.body.velocity.y).toFixed(1) });
    }
    return out;
  });
/** The shop card for a line or a perk as the HUD shows it: its middle, its plain line and its price text. */
const shopCard = async (id) => {
  const h = await hudNow();
  return h && h.shop ? h.shop.find((c) => c.id === id) ?? null : null;
};
const priceOf = (text) => {
  const m = String(text).match(/([0-9][0-9,]*)\s*$/);
  return m ? Number(m[1].replace(/,/g, '')) : null;
};
/** The slice 4 kiting loop: a thumb that circles the nest during a round, as the long bot does. */
function makeSteer() {
  const NEST = { x: 720, y: 1170 };
  let down = false;
  let lastDir = null;
  const steer = async (dx, dy) => {
    const len = Math.hypot(dx, dy) || 1;
    const ux = dx / len;
    const uy = dy / len;
    if (down && lastDir && ux * lastDir.x + uy * lastDir.y < 0.97) {
      await touch('touchEnd', []);
      down = false;
    }
    if (!down) {
      await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 1 }]);
      down = true;
    }
    await touch('touchMove', [{ x: THUMB.x + ux * 60, y: THUMB.y + uy * 60, id: 1 }]);
    lastDir = { x: ux, y: uy };
  };
  const letGo = async () => {
    if (down) await touch('touchEnd', []);
    down = false;
    lastDir = null;
  };
  const kite = async (s, tick) => {
    const rx = s.antX - NEST.x;
    const ry = s.antY - NEST.y;
    const r = Math.hypot(rx, ry) || 1;
    const pull = ((380 - r) / 380) * 1.5;
    if (tick % 6 < 4) await steer(-ry / r + (rx / r) * pull, rx / r + (ry / r) * pull);
    else await letGo();
  };
  return { steer, letGo, kite, NEST };
}

/** Slice 4, econ: a real run from the title to round 8 that buys the damage line three times by taps on its card. */
/** Lane G9: drops a waiting pick through the debug hook (a flow that measures the bare dart takes no power). */
const dropPicks = () =>
  page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    if (g.pending <= 0) return false;
    g.pending = 0;
    g.offer = [];
    return true;
  });
async function runS4Econ() {
  const r = { buys: [], speeds: {}, rounds: [], shotShop: false, ok: false };
  const { steer, letGo, kite, NEST } = makeSteer();
  const end = Date.now() + 420_000;
  let tick = 0;
  let current = 0;
  while (Date.now() < end) {
    tick += 1;
    const s = await snap();
    if (!s || s.phase === 'dead') break;
    if (s.round >= 8 && s.phase === 'active' && r.buys.length >= 3) break;
    // Lane G9: a waiting pick now holds the Yard until a tap, so this flow drops its picks through the debug hook; the
    // base dart the buys are measured on stays clear of the powers, as before.
    if (s.pending > 0) await dropPicks();
    if (s.phase === 'active') {
      if (s.round !== current) {
        current = s.round;
        r.rounds.push({ round: s.round, nectar: s.nectar, earned: s.earned, spent: s.spent });
      }
      // The speed bands: round 4 (slow) and round 6 (the mix; round 5 is a termite rush), every army ant and ember ant of
      // the round read as it lives (a few at one moment can all share a tier by chance).
      if (s.round === 4 || s.round === 6) {
        const key = `round${s.round}`;
        const sp = (await liveSpeeds()).filter((x) => x.kind === 'armyAnt' || x.kind === 'ember');
        const was = r.speeds[key] || { n: 0, speeds: [], maxV: 0 };
        const all = new Set([...was.speeds, ...sp.map((x) => x.speed)]);
        r.speeds[key] = { n: was.n + sp.length, speeds: [...all].sort((a, b) => a - b), maxV: Math.max(was.maxV, ...sp.map((x) => x.v), 0) };
      }
      await kite(s, tick);
    } else if (s.phase === 'break') {
      if (!s.inNest) await steer(NEST.x - s.antX, NEST.y - s.antY);
      else if (r.buys.length < 3 && s.shop === 'open') {
        await letGo();
        const before = await shopCard('damage');
        const price = before ? priceOf(before.price) : null;
        if (before && price !== null && s.nectar >= price) {
          await tapAt(gameCss(before.x, before.y), 6);
          await sleep(250);
          const after = await snap();
          const card = await shopCard('damage');
          const b = {
            round: s.round, lineBefore: before.line, priceText: before.price, price, lineAfter: card ? card.line : null,
            damageBefore: s.damage, damageAfter: after.damage, baseBefore: s.baseDamage, baseAfter: after.baseDamage,
            nectarBefore: +s.nectar.toFixed(2), nectarAfter: +after.nectar.toFixed(2),
            level: after.lines.damage, spentAfter: after.spent,
          };
          b.ok = after.lines.damage === s.lines.damage + 1 && Math.abs(s.nectar - after.nectar - price) < 1e-6;
          r.buys.push(b);
          log('s4 buy', JSON.stringify(b));
          if (!r.shotShop) {
            r.shotShop = true;
            await screenshot('shop_steps');
          }
        }
      } else await letGo();
    }
    await sleep(200);
  }
  await letGo();
  // Every buy gave less than the last and the card said so: "+30 damage, next +27" and so on. The card's step goes on
  // the base dart (before the powers multiply), so the base dart is what is measured; the dart after the powers is logged.
  const steps = r.buys.map((b) => +(b.baseAfter - b.baseBefore).toFixed(6));
  r.dartSteps = r.buys.map((b) => +(b.damageAfter - b.damageBefore).toFixed(3));
  r.steps = steps;
  const cardSays = r.buys.map((b) => Number((b.lineBefore.match(/^\+([0-9.]+) damage/) || [])[1]));
  r.cardSays = cardSays;
  const last = await snap();
  r.final = { round: last.round, phase: last.phase, earned: last.earned, spent: last.spent, lines: last.lines };
  const s4 = r.speeds.round4;
  const s5 = r.speeds.round6;
  r.ok =
    r.buys.length >= 3 && r.buys.every((b) => b.ok) &&
    steps.length >= 3 && steps[0] > steps[1] && steps[1] > steps[2] &&
    steps.every((d, i) => d === cardSays[i]) &&
    !!s4 && s4.n >= 3 && s4.speeds.length === 1 && s4.speeds[0] === 125 && !!s5 && s5.speeds.length >= 2 && Math.max(...s5.speeds) <= 235 &&
    last.round >= 8;
  log('s4 econ', JSON.stringify(r));
  return r;
}

/** Slice 4, boss: the Scythe Mantis of round 10 appears, one of its sweeps is measured against the cap, then it dies. */
async function runS4Boss() {
  const r = { ok: false };
  const end = Date.now() + 60_000;
  let s = await snap();
  while (Date.now() < end && !(s && s.boss && s.boss.kind === 'mantis')) {
    await sleep(200);
    s = await snap();
  }
  r.appeared = s && s.boss ? { kind: s.boss.kind, name: s.boss.name, hp: s.boss.hp, maxHp: s.boss.maxHp, round: s.round } : null;
  if (!r.appeared) {
    log('s4 boss', JSON.stringify(r));
    return r;
  }
  await sleep(1200);
  await screenshot('boss_mantis');
  // The cap: the ant set 100 units in front of the mantis, damage on for one sweep; the game's own sweep and cap decide.
  const stage = () =>
    page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const m = g.predators.getChildren().find((p) => p.active && p.kind === 'mantis');
      if (!m) return null;
      for (const p of g.predators.getChildren()) if (p.active && p.kind !== 'mantis') p.disableBody(true, true);
      g.ant.body.reset(m.x + Math.cos(m.heading) * 100, m.y + Math.sin(m.heading) * 100);
      g.assist = false;
      g.graceUntil = 0;
      g.hurtLog.length = 0;
      return { hp: g.hp, maxHp: g.build.maxHp };
    });
  const before = await stage();
  let hit = null;
  let arcShot = false;
  const capEnd = Date.now() + 6000;
  while (Date.now() < capEnd && !hit) {
    const st = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const m = g.predators.getChildren().find((p) => p.active && p.kind === 'mantis');
      return { windup: m ? m.windupAt > 0 : false, hurts: g.hurtLog.slice(), hp: g.hp };
    });
    if (st.windup && !arcShot) {
      arcShot = true;
      await screenshot('mantis_sweep');
    }
    const h = st.hurts.find((x) => x.raw === 160);
    if (h) hit = { ...h, hpAfter: st.hp };
    await sleep(60);
  }
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    g.assist = true;
  });
  r.cap = { before, hit, arcShown: arcShot };
  // Then it dies: the ant stays near it (the harness puts it back 140 units off) and the assisted darts do the rest.
  const killEnd = Date.now() + 50_000;
  let gone = false;
  while (Date.now() < killEnd) {
    s = await snap();
    if (!s || s.phase === 'dead') break;
    if (!s.boss) {
      gone = true;
      break;
    }
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const m = g.predators.getChildren().find((p) => p.active && p.kind === 'mantis');
      if (m && Math.hypot(g.ant.x - m.x, g.ant.y - m.y) > 220) g.ant.body.reset(m.x - Math.cos(m.heading) * 140, m.y - Math.sin(m.heading) * 140);
    });
    await sleep(400);
  }
  const k = await page.evaluate(() => window.__antwars.kinds());
  const hits = (await snap()).lastHits.filter((x) => x.kind === 'mantis').length;
  r.died = { gone, mantisAlive: k ? k.mantis : null, dartHitsLogged: hits, round: s ? s.round : null, phase: s ? s.phase : null };
  await sleep(600);
  await screenshot('boss_down');
  r.ok =
    !!r.appeared && r.appeared.maxHp === 14630 && !!hit && hit.raw === 160 && hit.capped === 120 && hit.taken === 120 &&
    hit.maxHp === 600 && !!before && before.hp - hit.hpAfter >= 120 && gone && r.died.mantisAlive === 0;
  log('s4 boss', JSON.stringify(r));
  return r;
}

/**
 * Slice 4, hunters (--round 11): an ember ant set beside a still ant bursts on its own fuse (damage on for that one
 * burst), and a dusk moth's heading is read on the game's own steps: it jinks, never more than 75 degrees off the ant.
 */
async function runS4Hunters() {
  const r = { ok: false };
  const waitKind = async (kind, ms) => {
    const end = Date.now() + ms;
    while (Date.now() < end) {
      const found = await page.evaluate((k) => {
        const g = window.__antwars.game.scene.getScene('game');
        return g.predators.getChildren().some((p) => p.active && p.kind === k && g.time.now >= p.spawnUntil);
      }, kind);
      if (found) return true;
      const sn = await snap();
      if (!sn || sn.phase === 'dead') return false;
      await sleep(150);
    }
    return false;
  };
  r.emberFound = await waitKind('ember', 60_000);
  if (r.emberFound) {
    const before = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const e = g.predators.getChildren().find((p) => p.active && p.kind === 'ember');
      for (const p of g.predators.getChildren()) if (p.active && p !== e) p.disableBody(true, true);
      g.queued = 0;
      e.body.reset(g.ant.x + 30, g.ant.y);
      g.assist = false;
      g.graceUntil = 0;
      g.hurtLog.length = 0;
      g.burstLog.length = 0;
      return { hp: g.hp, maxHp: g.build.maxHp };
    });
    const end = Date.now() + 4000;
    let burst = null;
    let fuseSeen = false;
    while (Date.now() < end && !burst) {
      const st = await page.evaluate(() => {
        const g = window.__antwars.game.scene.getScene('game');
        const e = g.predators.getChildren().find((p) => p.active && p.kind === 'ember');
        return { fuse: e ? e.fuseAt > 0 : false, bursts: g.burstLog.slice(), hurts: g.hurtLog.slice(), hp: g.hp };
      });
      if (st.fuse) fuseSeen = true;
      if (st.bursts.length > 0) burst = { ...st.bursts[0], hurts: st.hurts, hpAfter: st.hp };
      await sleep(50);
    }
    await page.evaluate(() => {
      window.__antwars.game.scene.getScene('game').assist = true;
    });
    r.ember = { before, fuseSeen, burst };
  }
  // The moth: sampled on the game's steps (a hook on the scene's update), its heading against the way to the ant.
  r.mothFound = await waitKind('moth', 60_000);
  if (r.mothFound) {
    r.moth = await page.evaluate(
      () =>
        new Promise((resolve) => {
          const g = window.__antwars.game.scene.getScene('game');
          const m = g.predators.getChildren().find((p) => p.active && p.kind === 'moth');
          const offs = [];
          const heads = [];
          let drift = 0;
          let prevTo = null;
          const t0 = g.time.now;
          // The scene's own postupdate event fires after its update each step (Phaser holds the update method itself).
          const onStep = () => {
            if (!m.active) {
              if (g.time.now - t0 > 3000) finish();
              return;
            }
            // The 75 degree rule holds when the moth turns: read the offset on the steps where its heading changed
            // (between turns the ant moves, so the angle drifts; that drift is logged as maxDriftDeg).
            // The game turned on the positions of the step before (the bodies move after its update), so a new heading is
            // read against the way to the ant one step back.
            const offOf = (to) => {
              let off = (m.heading - to) % (2 * Math.PI);
              if (off > Math.PI) off -= 2 * Math.PI;
              if (off < -Math.PI) off += 2 * Math.PI;
              return Math.abs(off) * (180 / Math.PI);
            };
            const toNow = Math.atan2(g.ant.y - m.y, g.ant.x - m.x);
            if (heads.length > 0 && prevTo !== null && Math.abs(m.heading - heads[heads.length - 1]) > 1e-6) offs.push(offOf(prevTo));
            drift = Math.max(drift, offOf(toNow));
            heads.push(m.heading);
            prevTo = toNow;
            if (g.time.now - t0 > 3000) finish();
          };
          let done = false;
          const finish = () => {
            if (done) return;
            done = true;
            g.events.off('postupdate', onStep);
            let changes = 0;
            for (let i = 1; i < heads.length; i++) if (Math.abs(heads[i] - heads[i - 1]) > 1e-6) changes += 1;
            resolve({ steps: heads.length, headingChanges: changes, turnsRead: offs.length, maxOffDeg: offs.length ? +Math.max(...offs).toFixed(1) : null, maxDriftDeg: +drift.toFixed(1), flying: m.flying, speed: m.speed });
          };
          g.events.on('postupdate', onStep);
          setTimeout(finish, 6000);
        }),
    );
  }
  const e = r.ember;
  r.ok =
    !!e && e.fuseSeen && !!e.burst && e.burst.fuse === true && e.burst.antTook === 110 &&
    e.burst.hurts.some((h) => h.raw === 110 && h.capped === 110) &&
    !!r.moth && r.moth.steps >= 60 && r.moth.headingChanges >= 2 && r.moth.turnsRead >= 2 && r.moth.maxOffDeg !== null && r.moth.maxOffDeg <= 75.01 && r.moth.flying === true;
  log('s4 hunters', JSON.stringify(r));
  return r;
}

/**
 * VG5 F1 (--round 12): Fire Venom and Spark Venom, two army ants of 1 health 40 units apart in front of a still ant. The
 * dart kills its target, the spark kills the neighbour, whose Flame Burst reaches the target: that target must die once.
 * Every killPredator call is counted, with whether its predator was still up; the kills and the beads must rise by two.
 */
async function runS4DoubleKill() {
  const r = { ok: false, trials: [] };
  // The practice round has to be under way (its plan set) before the stage.
  const startEnd = Date.now() + 15_000;
  let s0 = await snap();
  while (Date.now() < startEnd && !(s0 && s0.phase === 'active')) {
    await sleep(200);
    s0 = await snap();
  }
  await sleep(800);
  const picked = await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    const take = (id) => {
      g.pending = Math.max(1, g.pending);
      g.offer = [id];
      return g.pickPower(id);
    };
    const out = { fire: take('fire'), spark: take('spark') };
    g.pending = 0;
    g.offer = [];
    // The spark and the Flame Burst are one in five rolls since the design note of 2026-10-24: pin the roll so the chain happens.
    g.chance = () => 0;
    // Count every kill call, and the ones made on a predator already down.
    if (!g.__killWrap) {
      g.__killWrap = { calls: 0, onDown: 0, beads: 0 };
      const orig = g.killPredator;
      g.killPredator = function (p) {
        g.__killWrap.calls += 1;
        if (!p.active) g.__killWrap.onDown += 1;
        return orig.call(this, p);
      };
      // Beads are pulled in and collected within moments, so count them as they are dropped.
      const origDrop = g.spawnPickup;
      g.spawnPickup = function (kind, x, y, value) {
        if (kind === 'bead') g.__killWrap.beads += 1;
        return origDrop.call(this, kind, x, y, value);
      };
    }
    return out;
  });
  r.picked = picked;
  for (let trial = 0; trial < 3; trial++) {
    const before = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      for (const p of g.predators.getChildren()) if (p.active) p.disableBody(true, true);
      g.queued = 0;
      // Clear the beads so a new bead is easy to count.
      for (const k of g.pickups) k.img.destroy();
      g.pickups.length = 0;
      const ax = g.ant.x;
      const ay = g.ant.y;
      const a = g.spawnPredator(g.plan, 'armyAnt', { x: ax + 200, y: ay });
      const b = g.spawnPredator(g.plan, 'armyAnt', { x: ax + 240, y: ay });
      const live = g.predators.getChildren().filter((p) => p.active);
      for (const p of live) {
        p.spawnUntil = 0;
        p.hp = 1;
        p.maxHp = 1;
        p.speed = 0;
      }
      g.fireCooldown = 0;
      g.__killWrap.calls = 0;
      g.__killWrap.onDown = 0;
      g.__killWrap.beads = 0;
      return { spawned: a && b, live: live.length, kills: g.kills, beads: 0 };
    });
    // Hold both still for the shot (no movement), then read what one shot did.
    const end = Date.now() + 3000;
    let after = null;
    while (Date.now() < end) {
      after = await page.evaluate(() => {
        const g = window.__antwars.game.scene.getScene('game');
        for (const p of g.predators.getChildren()) if (p.active) p.body.setVelocity(0, 0);
        return { alive: g.predators.countActive(true), kills: g.kills, beads: g.__killWrap.beads, calls: g.__killWrap.calls, onDown: g.__killWrap.onDown };
      });
      if (after.alive === 0) break;
      await sleep(50);
    }
    await sleep(300);
    const fin = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      return { kills: g.kills, beads: g.__killWrap.beads, calls: g.__killWrap.calls, onDown: g.__killWrap.onDown };
    });
    const t = { before, killsDelta: fin.kills - before.kills, beadsDelta: fin.beads - before.beads, calls: fin.calls, onDown: fin.onDown };
    r.trials.push(t);
    log('s4 doublekill trial', JSON.stringify(t));
  }
  r.ok = picked.fire && picked.spark && r.trials.length === 3 && r.trials.every((t) => t.before.spawned && t.killsDelta === 2 && t.beadsDelta === 2);
  log('s4 doublekill', JSON.stringify(r));
  return r;
}

/**
 * Design note, 2026-10-24 (--round 12 or 16): the seconds from a round's start to 20 alive, read on the game's own clock while
 * the ant holds its fire (assist keeps it alive), so the spawn pace alone fills the Yard.
 */
async function runS4Fill() {
  const r = await page.evaluate(
    () =>
      new Promise((resolve) => {
        const g = window.__antwars.game.scene.getScene('game');
        let t0 = null;
        let most = 0;
        const t = setInterval(() => {
          g.fireCooldown = 99;
        }, 30);
        const onStep = () => {
          g.fireCooldown = 99;
          if (t0 === null && g.phase === 'active') t0 = g.time.now;
          if (t0 === null) return;
          const alive = g.predators.countActive(true);
          most = Math.max(most, alive);
          if (alive >= 20 || g.time.now - t0 > 20000) {
            g.events.off('postupdate', onStep);
            clearInterval(t);
            resolve({ round: g.round, gap: g.plan ? g.plan.spawnGap : null, cap: g.plan ? g.plan.aliveCap : null, secondsTo20: alive >= 20 ? +((g.time.now - t0) / 1000).toFixed(2) : null, most });
          }
        };
        g.events.on('postupdate', onStep);
      }),
  );
  r.ok = r.secondsTo20 !== null && r.secondsTo20 < 7;
  log('s4 fill', JSON.stringify(r));
  return r;
}

/**
 * Design note, 2026-10-24 (--round 6): a predator held 30 units past the right edge of the view is never aimed at or hit while
 * the ant stands; moved 60 units inside, it is shot within a moment.
 */
async function runS4View() {
  const r = { ok: false };
  const startEnd = Date.now() + 15_000;
  let s0 = await snap();
  while (Date.now() < startEnd && !(s0 && s0.phase === 'active')) {
    await sleep(200);
    s0 = await snap();
  }
  await sleep(600);
  const place = (inside) =>
    page.evaluate((ins) => {
      const g = window.__antwars.game.scene.getScene('game');
      for (const p of g.predators.getChildren()) if (p.active && !p.__target) p.disableBody(true, true);
      g.queued = 0;
      let t = g.predators.getChildren().find((p) => p.active && p.__target);
      const v = g.cameras.main.worldView;
      const x = ins ? v.x + v.width - 60 : v.x + v.width + 15 + 30;
      if (!t) {
        g.spawnPredator(g.plan, 'armyAnt', { x, y: g.ant.y });
        t = g.predators.getChildren().find((p) => p.active && !p.__target);
        t.__target = true;
      }
      t.body.reset(x, g.ant.y);
      t.spawnUntil = 0;
      t.speed = 0;
      t.hp = 1e7;
      t.maxHp = 1e7;
      g.hitLog.length = 0;
      return { x: Math.round(x), viewRight: Math.round(v.x + v.width), antX: Math.round(g.ant.x), dist: Math.round(x - g.ant.x) };
    }, inside);
  const hold = async (ms) => {
    const end = Date.now() + ms;
    while (Date.now() < end) {
      await page.evaluate(() => {
        const g = window.__antwars.game.scene.getScene('game');
        const t = g.predators.getChildren().find((p) => p.active && p.__target);
        if (t) t.body.setVelocity(0, 0);
      });
      await sleep(100);
    }
    return page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const t = g.predators.getChildren().find((p) => p.active && p.__target);
      return { hits: g.hitLog.length, hpLost: t ? 1e7 - t.hp : null };
    });
  };
  r.outside = { ...(await place(false)), ...(await hold(2500)) };
  r.inside = { ...(await place(true)), ...(await hold(1500)) };
  r.ok = r.outside.dist <= 600 && r.outside.hits === 0 && r.outside.hpLost === 0 && r.inside.hits > 0 && r.inside.hpLost > 0;
  log('s4 view', JSON.stringify(r));
  return r;
}

/**
 * Design note, 2026-10-24 (--round 14): with all three elements, on the game's own seeded roll, count for 10 s the dart hits
 * and kills that rolled and what fired: each effect near one in five.
 */
async function runS4Procs() {
  const r = { ok: false };
  const startEnd = Date.now() + 15_000;
  let s0 = await snap();
  while (Date.now() < startEnd && !(s0 && s0.phase === 'active')) {
    await sleep(200);
    s0 = await snap();
  }
  // All three elements, and more darts a volley (two Front Fangs, two Fork Darts) so the hits come fast.
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    for (const id of ['frost', 'spark', 'fire', 'fang', 'fang', 'fork', 'fork']) {
      g.pending = Math.max(1, g.pending);
      g.offer = [id];
      g.pickPower(id);
    }
    g.pending = 0;
    g.offer = [];
  });
  const stage = (hp, n) =>
    page.evaluate(
      ([health, count]) => {
        const g = window.__antwars.game.scene.getScene('game');
        g.queued = 0;
        const have = g.predators.getChildren().filter((p) => p.active).length;
        for (let i = have; i < count; i++) {
          const a = (i / count) * Math.PI * 2;
          g.spawnPredator(g.plan, 'armyAnt', { x: g.ant.x + Math.cos(a) * 170, y: g.ant.y + Math.sin(a) * 170 });
        }
        for (const p of g.predators.getChildren()) {
          if (!p.active) continue;
          p.spawnUntil = 0;
          p.speed = 0;
          if (p.hp > health) p.hp = health;
          p.body.setVelocity(0, 0);
        }
      },
      [hp, n],
    );
  const zero = () =>
    page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      for (const k of Object.keys(g.procs)) g.procs[k] = 0;
    });
  // Hits: six foes that do not die, 20 s of fire.
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    for (const p of g.predators.getChildren()) if (p.active) p.disableBody(true, true);
  });
  await stage(1e9, 6);
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    for (const p of g.predators.getChildren()) if (p.active) p.hp = 1e9;
  });
  await zero();
  for (let t = 0; t < 80; t++) {
    await stage(1e9, 6);
    await sleep(250);
  }
  const hitPart = (await snap()).elements.procs;
  // Kills: foes of 1 health kept topped up to six, 20 s.
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    for (const p of g.predators.getChildren()) if (p.active) p.disableBody(true, true);
  });
  await zero();
  for (let t = 0; t < 80; t++) {
    await stage(1, 6);
    await sleep(250);
  }
  const killPart = (await snap()).elements.procs;
  const rate = (n, of) => (of > 0 ? +(n / of).toFixed(3) : null);
  r.hits = { n: hitPart.hits, slow: hitPart.slow, burn: hitPart.burn, spark: hitPart.spark };
  r.kills = { n: killPart.kills, puddle: killPart.puddle, steam: killPart.steam, burst: killPart.burst };
  r.rates = {
    slow: rate(hitPart.slow, hitPart.hits),
    burn: rate(hitPart.burn, hitPart.hits),
    spark: rate(hitPart.spark, hitPart.hits),
    puddle: rate(killPart.puddle, killPart.kills),
    steam: rate(killPart.steam, killPart.kills),
    burst: rate(killPart.burst, killPart.kills),
  };
  const near = (x) => x !== null && x >= 0.12 && x <= 0.28;
  r.ok = hitPart.hits >= 120 && killPart.kills >= 100 && Object.values(r.rates).every(near);
  log('s4 procs', JSON.stringify(r));
  return r;
}

/**
 * Design note, 2026-10-24 (--round 6): two Front Fangs (three darts a volley) on one tough army ant held still in front of the
 * ant: frame by frame, at most one number over it, and that number the total of its hits so far.
 */
async function runS4Numbers() {
  const r = { ok: false };
  const startEnd = Date.now() + 15_000;
  let s0 = await snap();
  while (Date.now() < startEnd && !(s0 && s0.phase === 'active')) {
    await sleep(200);
    s0 = await snap();
  }
  await sleep(600);
  r.result = await page.evaluate(
    () =>
      new Promise((resolve) => {
        const g = window.__antwars.game.scene.getScene('game');
        for (const id of ['fang', 'fang']) {
          g.pending = Math.max(1, g.pending);
          g.offer = [id];
          g.pickPower(id);
        }
        g.pending = 0;
        g.offer = [];
        for (const p of g.predators.getChildren()) if (p.active) p.disableBody(true, true);
        g.queued = 0;
        g.spawnPredator(g.plan, 'armyAnt', { x: g.ant.x, y: g.ant.y - 160 });
        const t = g.predators.getChildren().find((p) => p.active);
        t.spawnUntil = 0;
        t.speed = 0;
        t.hp = 1e7;
        t.maxHp = 1e7;
        const t0 = g.time.now;
        let most = 0;
        let frames = 0;
        let shownValue = null;
        const onStep = () => {
          t.body.setVelocity(0, 0);
          frames += 1;
          // Numbers shown over the target: visible, a plain number, within 90 units of it (tagged or not).
          const mine = g.floats.filter((f) => f.visible && /^[0-9]+$/.test(f.text) && Math.hypot(f.x - t.x, f.y - t.y) < 90);
          most = Math.max(most, mine.length);
          if (mine.length === 1) shownValue = Number(mine[0].text);
          if (g.time.now - t0 > 2500) {
            g.events.off('postupdate', onStep);
            resolve({ frames, mostAtOnce: most, shown: shownValue, dealt: +(1e7 - t.hp).toFixed(3), darts: g.build.darts });
          }
        };
        g.events.on('postupdate', onStep);
      }),
  );
  const x = r.result;
  r.ok = x.darts === 3 && x.mostAtOnce === 1 && x.dealt > 0 && Math.abs(x.shown - x.dealt) <= 1;
  log('s4 numbers', JSON.stringify(r));
  return r;
}

/** Slice 4, pace (--round 13): the fast band, every army ant at the cap, read from the live game twice, 3 s apart. */
async function runS4Pace() {
  const r = { ok: false, samples: [] };
  const end = Date.now() + 40_000;
  while (Date.now() < end && r.samples.length < 2) {
    const sp = (await liveSpeeds()).filter((x) => x.kind === 'armyAnt');
    if (sp.length >= 3) {
      r.samples.push({ n: sp.length, speeds: [...new Set(sp.map((x) => x.speed))].sort((p, q) => p - q), maxV: Math.max(...sp.map((x) => x.v)) });
      await sleep(3000);
    } else await sleep(250);
  }
  const all = await liveSpeeds();
  r.others = [...new Set(all.filter((x) => x.kind !== 'armyAnt').map((x) => `${x.kind} ${x.speed}`))];
  r.ok = r.samples.length === 2 && r.samples.every((x) => x.speeds.length === 1 && x.speeds[0] === 235 && x.maxV <= 235.01);
  log('s4 pace', JSON.stringify(r));
  return r;
}

/** Slice 4, hornet (--round 20): the Brood Hornet appears, calls wasps out of itself, fires its fan, and dies. */
async function runS4Hornet() {
  const r = { ok: false };
  const end = Date.now() + 60_000;
  let s = await snap();
  while (Date.now() < end && !(s && s.boss && s.boss.kind === 'hornet')) {
    await sleep(200);
    s = await snap();
  }
  r.appeared = s && s.boss ? { kind: s.boss.kind, maxHp: s.boss.maxHp, round: s.round } : null;
  if (!r.appeared) {
    log('s4 hornet', JSON.stringify(r));
    return r;
  }
  // Watch it for 14 s with the ant kept out of its reach: the calls for wasps and the stings in flight.
  const watchEnd = Date.now() + 14_000;
  let maxWasps = 0;
  let maxStings = 0;
  let calls = 0;
  let shot = false;
  while (Date.now() < watchEnd) {
    const st = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const h = g.predators.getChildren().find((p) => p.active && p.kind === 'hornet');
      let wasps = 0;
      for (const p of g.predators.getChildren()) if (p.active && p.kind === 'wasp') wasps += 1;
      let stings = 0;
      for (const q of g.shots.getChildren()) if (q.active && !q.web) stings += 1;
      return { calls: h ? h.broodCalls : null, wasps, stings };
    });
    if (st.calls === null) break;
    calls = Math.max(calls, st.calls);
    maxWasps = Math.max(maxWasps, st.wasps);
    maxStings = Math.max(maxStings, st.stings);
    if (!shot && st.stings >= 3) {
      shot = true;
      await screenshot('hornet_fan');
    }
    await sleep(120);
  }
  r.watch = { calls, maxWasps, maxStings };
  // Then it dies: the ant goes close and the assisted darts do the rest.
  const killEnd = Date.now() + 60_000;
  let gone = false;
  while (Date.now() < killEnd) {
    s = await snap();
    if (!s || s.phase === 'dead') break;
    if (!s.boss) {
      gone = true;
      break;
    }
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const h = g.predators.getChildren().find((p) => p.active && p.kind === 'hornet');
      if (h && Math.hypot(g.ant.x - h.x, g.ant.y - h.y) > 260) g.ant.body.reset(h.x - 180, h.y);
    });
    await sleep(400);
  }
  r.gone = gone;
  await sleep(500);
  await screenshot('hornet_down');
  r.ok = !!r.appeared && r.appeared.maxHp === 32520 && calls >= 1 && calls <= 8 && maxWasps >= 2 && maxStings >= 3 && gone;
  log('s4 hornet', JSON.stringify(r));
  return r;
}

/** Slice 4, elements: frost and spark through the game's own pick, a shock puddle on a kill, the mutated ant, frames. */
async function runS4Elements() {
  const r = { ok: false };
  const pick = (id) =>
    page.evaluate((pid) => {
      const g = window.__antwars.game.scene.getScene('game');
      g.pending = Math.max(1, g.pending);
      g.offer = [pid];
      return g.pickPower(pid);
    }, id);
  await sleep(2500);
  // The design note of 2026-10-24 made every effect a one in five roll; this flow pins the roll to fire every time (the procs flow
  // measures the real rate).
  await page.evaluate(() => {
    window.__antwars.game.scene.getScene('game').chance = () => 0;
  });
  r.picked = { frost: await pick('frost'), spark: await pick('spark') };
  for (let i = 0; i < 3; i++) r.picked[`shell${i + 1}`] = await pick('shell');
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    g.pending = 0;
    g.offer = [];
  });
  // The snapshot is rebuilt once a frame: let a frame or two pass before reading what the picks did.
  await sleep(150);
  const s0 = await snap();
  r.after = { elements: { fire: s0.elements.fire, frost: s0.elements.frost, spark: s0.elements.spark }, combos: s0.elements.combos, look: s0.look, maxHp: s0.maxHp };
  // A shock puddle appears on a kill: watch the kills and the puddles together.
  const end = Date.now() + 20_000;
  let puddle = null;
  let killsAt = s0.kills;
  while (Date.now() < end && !puddle) {
    const s = await snap();
    if (!s || s.phase === 'dead') break;
    const near = s.elements.puddles.find((q) => Math.abs(q.x - s.antX) < 300 && Math.abs(q.y - s.antY) < 600 && q.left > 2);
    if (near && s.kills > killsAt) puddle = { kills: s.kills, first: near, count: s.elements.puddles.length, comboHits: s.elements.comboHits.puddle, ant: { x: s.antX, y: s.antY } };
    killsAt = Math.min(killsAt, s.kills);
    await sleep(80);
  }
  r.puddle = puddle;
  if (puddle) await screenshot('combo_puddle');
  // It runs out after 3 s: a puddle laid now is gone 3.4 s later unless a new kill laid another.
  await sleep(1500);
  const sMid = await snap();
  r.puddleLater = { puddles: sMid.elements.puddles.length, comboHits: sMid.elements.comboHits.puddle, sparks: sMid.elements.sparks };
  // Fire as well: all three combos on, the ant at its most mutated; then frames with 20 alive.
  r.picked.fire = await pick('fire');
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    g.pending = 0;
    g.offer = [];
  });
  await sleep(2500);
  await screenshot('mutated_ant');
  let s = await snap();
  const aliveEnd = Date.now() + 25_000;
  while (Date.now() < aliveEnd && s && s.alive < 20) {
    // Lane G9: a level up now holds the Yard until a tap; this flow drops it, so the spawns go on to 20 alive.
    await dropPicks();
    await sleep(250);
    s = await snap();
  }
  r.aliveBefore = s ? s.alive : null;
  await takeSample();
  const s2 = await snap();
  r.aliveAfter = s2 ? s2.alive : null;
  r.fieldsAfter = s2 ? { puddles: s2.elements.puddles.length, steams: s2.elements.steams, burning: s2.elements.burning, blind: s2.elements.blind, sparks: s2.elements.sparks, comboHits: s2.elements.comboHits, look: s2.look } : null;
  r.frames = frames;
  r.ok =
    // Since the picks were trimmed (design note, 2026-10-24) three Hearty Shells give 840, under the first plate at 900.
    r.picked.frost && r.picked.spark && r.after.combos.puddle && r.after.maxHp === 840 && r.after.look.plates === 0 && r.after.look.aura.length === 2 &&
    !!puddle && puddle.first.left > 2 && puddle.comboHits >= 0 && r.picked.fire &&
    r.aliveBefore !== null && r.aliveBefore >= 20 && !!frames && frames.rafDelta.p95 < 20 && !!r.fieldsAfter && r.fieldsAfter.sparks > 0;
  log('s4 elements', JSON.stringify(r));
  return r;
}
const COLONY_KEY = 'antwars.colony.v1';
const readKey = (key) =>
  page.evaluate((k) => {
    try {
      return localStorage.getItem(k);
    } catch {
      return 'unreadable';
    }
  }, key);
/** Waits for the title with its buttons up and its read guard passed; returns the HUD readout. */
async function waitTitle(ms = 8000) {
  const end = Date.now() + ms;
  let h = await hudNow();
  while (Date.now() < end && !(h && h.title && h.title.shown)) {
    await sleep(100);
    h = await hudNow();
  }
  await sleep(400);
  return hudNow();
}
/** Opens the nest from the death screen (its Nest button) or from the title, and waits out its read guard. */
async function openNestFrom(h) {
  if (h.death && h.death.shown) {
    const end0 = Date.now() + 4000;
    while (Date.now() < end0 && !(h.death && h.death.ready)) {
      await sleep(100);
      h = await hudNow();
    }
    await tapAt(gameCss(h.death.nest.x, h.death.nest.y));
  }
  else await tapAt(gameCss(h.title.nest.x, h.title.nest.y));
  const end = Date.now() + 3000;
  let n = await hudNow();
  while (Date.now() < end && !(n && n.nest && n.nest.shown)) {
    await sleep(100);
    n = await hudNow();
  }
  await sleep(400);
  return hudNow();
}
/** Plays the stick pattern until the run holds at least this much nectar (or the time runs out). */
async function earnNectar(min, ms) {
  let i = 0;
  const end = Date.now() + ms;
  let s = await snap();
  while (Date.now() < end && s && s.phase !== 'dead' && s.nectar < min) {
    const [dx, dy, t] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, Math.min(t, 1500));
    await clearPicks();
    await sleep(700);
    s = await snap();
  }
  return s;
}
/**
 * The real death path: the harness sets the ant's health to 1 and puts one live predator on it; its bite (the Yard's own
 * overlap and hurt) ends the run. Waits for the death screen.
 */
async function dieNow() {
  const end = Date.now() + 12000;
  let s = await snap();
  while (Date.now() < end && s && s.phase !== 'active') {
    await sleep(150);
    s = await snap();
  }
  let placed = 0;
  while (Date.now() < end && s && s.phase !== 'dead') {
    placed = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const p = g.predators.getChildren().find((q) => q.active && q.kind !== 'anteater');
      if (!p) return 0;
      g.hp = 1;
      g.graceUntil = 0;
      p.spawnUntil = 0;
      p.biteReadyAt = 0;
      p.body.reset(g.ant.x + 4, g.ant.y);
      return 1;
    });
    await sleep(placed ? 250 : 400);
    s = await snap();
  }
  await sleep(1400);
  return snap();
}
/** Slice 3, M1 and M4: the title and its ladder switch, a death that banks, the nest, a stronger start, Pure starts weak. */
async function runColonyFlow() {
  const r = { ok: false };
  let h = await waitTitle();
  let s = await snap();
  r.title = { shown: !!h && h.title.shown, ladder: s.ladder, contShown: h.title.contShown, line: h.title.line, ladderText: h.title.ladder.text };
  await screenshot('title');
  // The ladder switch: Colony to Pure and back, read from the snapshot and the button's own text.
  await tapAt(gameCss(h.title.ladder.x, h.title.ladder.y));
  await sleep(250);
  const toPure = { snap: (await snap()).ladder, text: (await hudNow()).title.ladder.text, stored: await readKey('antwars.ladder.v1') };
  await screenshot('title_pure');
  await tapAt(gameCss(h.title.ladder.x, h.title.ladder.y));
  await sleep(250);
  const back = { snap: (await snap()).ladder, text: (await hudNow()).title.ladder.text, stored: await readKey('antwars.ladder.v1') };
  r.switch = { toPure, back, ok: toPure.snap === 'pure' && toPure.text === 'LADDER: PURE' && back.snap === 'colony' && back.text === 'LADDER: COLONY' };
  // A Colony run on a fresh colony: the base ant, then earn some nectar and die.
  await tapAt(gameCss(h.title.play.x, h.title.play.y));
  await sleep(300);
  s = await snap();
  r.firstRun = { phase: s.phase, ladder: s.ladder, damage: s.damage, maxHp: s.maxHp, speed: s.speed, bank: s.bank };
  s = await earnNectar(500, 70_000);
  const before = await snap();
  const dead = await dieNow();
  const stored = await readKey(COLONY_KEY);
  h = await hudNow();
  r.death = {
    phase: dead.phase,
    round: dead.round,
    nectarAtDeath: before.nectar,
    banked: dead.banked,
    bank: dead.bank,
    stored,
    deathShown: !!h && !!h.death && h.death.shown,
    deathText: h && h.death ? h.death.text : null,
  };
  let storedBank = null;
  try {
    storedBank = JSON.parse(stored).bank;
  } catch {
    storedBank = null;
  }
  r.death.ok = dead.phase === 'dead' && dead.banked !== null && dead.banked >= 400 && dead.bank === dead.banked && storedBank === dead.bank;
  await screenshot('death');
  // The nest: from the death screen's Nest button (M4) or, without it, from the title after a reload.
  if (!(h && h.death && h.death.shown && h.death.nest)) {
    await page.reload({ waitUntil: 'load' });
    await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
    h = await waitTitle();
  }
  r.nestFrom = h.death && h.death.shown ? 'death' : 'title';
  let n = await openNestFrom(h);
  const bank0 = (await snap()).bank;
  r.nest = { shown: n.nest.shown, bank0, bankText: n.nest.bank, cards: n.nest.cards.map((c) => ({ id: c.id, line: c.line, count: c.count, price: c.price })) };
  await screenshot('nest');
  const buys = [];
  for (const i of [0, 1]) {
    n = await hudNow();
    const card = n.nest.cards[i];
    const a = await snap();
    await tapAt(gameCss(card.x, card.y));
    await sleep(250);
    const b = await snap();
    buys.push({ id: card.id, bankBefore: a.bank, bankAfter: b.bank, paid: a.bank - b.bank, levelBefore: a.colonyLevels[card.id], levelAfter: b.colonyLevels[card.id] });
  }
  n = await hudNow();
  r.buys = buys;
  r.buysOk = buys.length === 2 && buys[0].paid === 200 && buys[1].paid === 250 && buys.every((b) => b.levelAfter === b.levelBefore + 1);
  r.nestAfter = n.nest.cards.slice(0, 2).map((c) => ({ id: c.id, line: c.line, count: c.count, price: c.price }));
  await screenshot('nest_bought');
  if (r.nestFrom === 'death') {
    // Back returns to the death screen at once (no second guard), with the bank as it is now; then the nest again.
    await tapAt(gameCss(n.nest.back.x, n.nest.back.y));
    await sleep(300);
    const hb = await hudNow();
    r.back = { deathShown: hb.death.shown, ready: hb.death.ready, nestShown: hb.nest.shown, text: hb.death.text };
    r.backOk = hb.death.shown && hb.death.ready && !hb.nest.shown;
    n = await openNestFrom(hb);
  }
  // PLAY from the nest: the next run starts with the upgrades on (a measured number, not a flag).
  await tapAt(gameCss(n.nest.play.x, n.nest.play.y));
  const endStart = Date.now() + 6000;
  s = await snap();
  while (Date.now() < endStart && s && s.phase !== 'intro' && s.phase !== 'active') {
    await sleep(100);
    s = await snap();
  }
  await sleep(300);
  s = await snap();
  r.secondRun = { phase: s.phase, ladder: s.ladder, damage: s.damage, maxHp: s.maxHp, hp: s.hp, speed: s.speed, colonyLevels: s.colonyLevels };
  // The design note of 2026-10-24 halved the nest's steps: one Barbed Stinger is +4, one Royal Diet +12.5 (600 + 12.5 rounds to 613).
  r.stronger = (s.phase === 'intro' || s.phase === 'active') && s.ladder === 'colony' && s.damage === r.firstRun.damage + 4 && s.maxHp === r.firstRun.maxHp + 13 && s.hp === s.maxHp;
  await screenshot('second_run');
  // Pure starts weak: a reload, the switch to Pure on the title, Play: the bare ant although the colony holds upgrades.
  await page.reload({ waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  h = await waitTitle();
  await tapAt(gameCss(h.title.ladder.x, h.title.ladder.y));
  await sleep(300);
  h = await hudNow();
  await tapAt(gameCss(h.title.play.x, h.title.play.y));
  await sleep(400);
  s = await snap();
  const hud = await hudNow();
  r.pure = { phase: s.phase, ladder: s.ladder, damage: s.damage, maxHp: s.maxHp, speed: s.speed, colonyLevels: s.colonyLevels, hudLadder: hud ? hud.ladderLine : null };
  r.pureWeak = s.ladder === 'pure' && s.damage === 150 && s.maxHp === 600 && s.speed === 250 && s.colonyLevels.stinger === 1 && s.colonyLevels.diet === 1;
  await sleep(2600);
  await screenshot('pure_run');
  // Back to Colony for the next flows of this page.
  r.ok = r.title.shown && r.switch.ok && r.death.ok && r.buysOk && r.stronger && r.pureWeak && r.nestFrom === 'death' && r.backOk === true;
  log('colony', JSON.stringify(r));
  return r;
}
let bossRun = null;
let stillRun = null;
const RUN_KEY = 'antwars.run.v1';
const readRunSave = () =>
  page.evaluate((key) => {
    try {
      return localStorage.getItem(key);
    } catch {
      return 'unreadable';
    }
  }, RUN_KEY);
/** Times every freeze a pick sheet brings, frame by frame inside the page (window.__g4.freezes, in ms). */
const installWatch = () =>
  page.evaluate(() => {
    const w = { freezes: [], frozenNow: false };
    window.__g4 = w;
    let at = 0;
    const tick = () => {
      const s = window.__antwars && window.__antwars.snapshot();
      if (s) {
        if (s.frozen && !w.frozenNow) at = performance.now();
        if (!s.frozen && w.frozenNow) w.freezes.push(+(performance.now() - at).toFixed(1));
        w.frozenNow = s.frozen;
      }
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  });
const readFreezes = () => page.evaluate(() => (window.__g4 ? [...window.__g4.freezes] : []));
/** Slice 2, M2: steer into the nearest rock and keep pushing; the ant must stop at its edge and never pass inside. */
async function hitRock() {
  const rocks = await page.evaluate(() => (window.__antwars.rocks ? window.__antwars.rocks() : []));
  let s = await snap();
  if (!s || rocks.length === 0) return { ok: false, reason: 'no rocks' };
  const rock = [...rocks].sort((a, b) => Math.hypot(a.x - s.antX, a.y - s.antY) - Math.hypot(b.x - s.antX, b.y - s.antY))[0];
  const r = { rock, startDist: +Math.hypot(rock.x - s.antX, rock.y - s.antY).toFixed(1), contact: false, minGap: Infinity, pushMoved: null };
  const steer = async () => {
    const dx = rock.x - s.antX;
    const dy = rock.y - s.antY;
    const len = Math.hypot(dx, dy) || 1;
    await touch('touchMove', [{ x: THUMB.x + (dx / len) * 60, y: THUMB.y + (dy / len) * 60, id: 1 }]);
  };
  const gap = () => Math.hypot(s.antX - rock.x, s.antY - rock.y) - rock.r;
  await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 1 }]);
  const end = Date.now() + 9000;
  while (Date.now() < end && s && s.phase !== 'dead') {
    await steer();
    await sleep(100);
    s = await snap();
    r.minGap = Math.min(r.minGap, gap());
    if (s.rockContact) {
      r.contact = true;
      break;
    }
  }
  if (r.contact) {
    const a = s;
    for (let k = 0; k < 8; k++) {
      await steer();
      await sleep(100);
      s = await snap();
      r.minGap = Math.min(r.minGap, gap());
    }
    r.pushMoved = +Math.hypot(s.antX - a.antX, s.antY - a.antY).toFixed(1);
    r.stillTouching = s.rockContact;
    await screenshot('rock');
  }
  await touch('touchEnd', []);
  r.minGap = +r.minGap.toFixed(1);
  // The ant's centre never comes nearer the rock's edge than its own radius (16 units), give or take the rounding.
  r.ok = r.contact && r.minGap >= 13 && r.pushMoved !== null && r.pushMoved <= 12 && r.stillTouching === true;
  log('rock', JSON.stringify(r));
  return r;
}
/** Slice 2, M3: the run saves when a round is cleared. Waits for the break, lets the beads land, reads the save back. */
async function waitForSave() {
  const end = Date.now() + 45_000;
  let s = await snap();
  while (Date.now() < end && s && s.phase !== 'break' && s.phase !== 'dead') {
    await sleep(250);
    s = await snap();
    if (s && s.pending > 0) await clearPicks();
  }
  if (!s || s.phase !== 'break') return { ok: false, phase: s ? s.phase : null };
  await clearPicks();
  await sleep(2000);
  const at = await snap();
  const raw = await readRunSave();
  let saved = null;
  try {
    saved = JSON.parse(raw);
  } catch {
    saved = null;
  }
  const r = { round: at.round, phase: at.phase, bytes: raw ? raw.length : 0, saved };
  r.ok =
    !!saved && at.phase === 'break' && saved.round === at.round && saved.level === at.level && saved.xp === at.xp &&
    saved.nectar === at.nectar && saved.hp === at.hp && saved.pending === at.pending;
  log('save', JSON.stringify(r));
  return r;
}
/**
 * VG3 note 6: in the break a waiting pick sits high and the shop shows below it, both in reach. The ant walks into the
 * nest, the harness queues a pick through the Yard's own queuePicks (the Royal Jelly path), then the pick takes a tap.
 */
async function shopUnderSheet() {
  let s = await snap();
  // Since the tuning of 2026-10-24 (horde spawns twice as often) round 1 can end while the earlier checks run, so this break may be
  // nearly over: then the ant plays the next round out with the stick and the check runs in the following break.
  if (s && s.phase === 'break' && s.breakLeft < 9) {
    const end = Date.now() + 70_000;
    let i = 0;
    while (Date.now() < end && s && s.phase === 'break') {
      await sleep(200);
      s = await snap();
    }
    while (Date.now() < end && s && s.phase === 'active') {
      const [dx, dy, ms] = pattern[i % pattern.length];
      i += 1;
      await hold(dx, dy, Math.min(ms, 1400));
      await clearPicks();
      await sleep(700);
      s = await snap();
    }
    await clearPicks();
    s = await snap();
  }
  if (!s || s.phase !== 'break') return { ok: false, phase: s ? s.phase : null };
  s = await walkNest(true, 6000);
  if (!s || s.phase !== 'break' || !s.inNest) return { ok: false, reason: 'not in the nest', phase: s ? s.phase : null };
  await page.evaluate(() => window.__antwars.game.scene.getScene('game').queuePicks(1, 'ROYAL JELLY: A FREE PICK'));
  await sleep(450);
  const h = await hudNow();
  const [, GH] = env.gameSize.split('x').map(Number);
  const r = {
    pickShown: h.pick.shown,
    shopCards: h.cards,
    pickBottom: h.pick.cards.length ? Math.max(...h.pick.cards.map((c) => c.y)) + 56 : null,
    // Slice 4: the shop is a grid of four rows now (layout.ts shopLayout gridTop).
    shopTop: GH - 4 * (104 + 12) - 28,
  };
  await screenshot('shop_under_pick');
  const picked = await tapPick(0);
  const after = await hudNow();
  const afterSnap = await snap();
  r.picked = !!picked && picked.ok;
  r.shopAfter = after.cards;
  r.phaseAfter = afterSnap ? afterSnap.phase : null;
  // After the pick the shop still shows while the break lasts (the countdown may have run out meanwhile).
  r.ok = r.pickShown && r.shopCards && r.pickBottom !== null && r.pickBottom < r.shopTop && r.picked && (r.phaseAfter !== 'break' || r.shopAfter);
  log('shop under the sheet', JSON.stringify(r));
  return r;
}
/** Slice 2, M3: mid run (the next round under way) a reload shows the title with Continue; a tap brings the run back. */
async function reloadAndContinue() {
  const end = Date.now() + 25_000;
  let s = await snap();
  while (Date.now() < end && s && s.phase === 'break') {
    await sleep(200);
    s = await snap();
  }
  const mid = s;
  await sleep(1500);
  await note('mid run, before the reload');
  growthRun.freezes = await readFreezes();
  const raw = await readRunSave();
  const midSnap = await snap();
  await page.reload({ waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  await installWatch();
  await sleep(600);
  const t = await snap();
  const h = await hudNow();
  const r = { midRound: midSnap.round, midPhase: midSnap.phase, midKills: midSnap.kills, startedNext: !!mid && mid.phase === 'active', titlePhase: t.phase, title: h ? h.title : null };
  await screenshot('title_continue');
  if (!h || !h.title || !h.title.shown) {
    r.ok = false;
    log('resume', JSON.stringify(r));
    return r;
  }
  await tapAt(gameCss(h.title.cont.x, h.title.cont.y));
  await sleep(500);
  const c = await snap();
  const saved = JSON.parse(raw);
  r.saved = saved;
  r.restored = { phase: c.phase, round: c.round, level: c.level, xp: c.xp, nectar: c.nectar, hp: c.hp, maxHp: c.maxHp, owned: c.owned, stacks: c.stacks, pending: c.pending, kills: c.kills };
  const sameStacks = Object.keys(saved.stacks).every((k) => saved.stacks[k] === c.stacks[k]) && Object.keys(c.stacks).length === Object.keys(saved.stacks).length;
  r.ok =
    t.phase === 'title' && r.startedNext && c.phase === 'break' && c.round === saved.round && c.level === saved.level &&
    c.xp === saved.xp && c.nectar === saved.nectar && c.hp === saved.hp && c.pending === saved.pending && sameStacks &&
    JSON.stringify([...c.owned].sort()) === JSON.stringify([...saved.owned].sort());
  log('resume', JSON.stringify(r));
  await screenshot('continued');
  return r;
}
/** Takes every waiting pick (the flows that test other things clear the sheet so the shop can show). */
async function clearPicks(max = 6) {
  for (let n = 0; n < max; n++) {
    const s = await snap();
    if (!s || s.pending === 0 || s.phase === 'dead') return;
    if (!(await tapPick(0))) return;
  }
}
let breakCheck = null;
let spawnCheck = null;
let dragTest = null;
const NEST_AT = { x: 720, y: 1170 };
/** The CSS point at the middle of shop card i (the HUD lays the cards out from the game size, as HudScene does). */
function cardCss(i) {
  const [GW, GH] = env.gameSize.split('x').map(Number);
  const k = rect.w / GW;
  const cw = 340;
  const ch = 104;
  const gap = 12;
  const top = GH - 3 * (ch + gap) - 28;
  return { x: rect.x + (GW - cw - 12 + cw / 2) * k, y: rect.y + (top + i * (ch + gap) + ch / 2) * k };
}
/** Steers with the thumb toward the nest (inward) or away from it until the ant is inside (or outside) the nest. */
async function walkNest(inward, maxMs) {
  let s = await snap();
  if (!s || s.inNest === inward) return s;
  await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 1 }]);
  const end = Date.now() + maxMs;
  while (s && s.phase !== 'dead' && s.inNest !== inward && Date.now() < end) {
    let dx = NEST_AT.x - s.antX;
    let dy = NEST_AT.y - s.antY;
    if (!inward) {
      dx = -dx;
      dy = -dy;
    }
    const len = Math.hypot(dx, dy);
    const ux = len > 1 ? dx / len : 0;
    const uy = len > 1 ? dy / len : -1;
    await touch('touchMove', [{ x: THUMB.x + ux * 60, y: THUMB.y + uy * 60, id: 1 }]);
    await sleep(100);
    s = await snap();
  }
  if (!inward) await sleep(250);
  await touch('touchEnd', []);
  await sleep(150);
  return snap();
}
/** Polish 1 in the real game: a drag that starts on shop card i takes the stick (the ant moves) and never buys. */
async function dragFromCard(i, s1) {
  const p = cardCss(i);
  const dx = NEST_AT.x - s1.antX;
  const dy = NEST_AT.y - s1.antY;
  const len = Math.hypot(dx, dy);
  // Toward the nest's middle, so the ant stays in the shop.
  const ux = len > 1 ? dx / len : 0;
  const uy = len > 1 ? dy / len : -1;
  await touch('touchStart', [{ x: p.x, y: p.y, id: 4 }]);
  await sleep(40);
  await touch('touchMove', [{ x: p.x + ux * 30, y: p.y + uy * 30, id: 4 }]);
  await sleep(60);
  await touch('touchMove', [{ x: p.x + ux * 60, y: p.y + uy * 60, id: 4 }]);
  await sleep(350);
  const mid = await snap();
  await touch('touchEnd', []);
  await sleep(200);
  const s2 = await snap();
  const r = {
    card: i,
    moved: +Math.hypot(mid.antX - s1.antX, mid.antY - s1.antY).toFixed(1),
    ownedBefore: s1.owned,
    ownedAfter: s2.owned,
    nectarBefore: s1.nectar,
    nectarAfter: s2.nectar,
    shopAfter: s2.shop,
  };
  r.ok = r.moved >= 20 && s2.owned.length === s1.owned.length && s2.nectar >= s1.nectar;
  log('card drag', JSON.stringify(r));
  return r;
}
/** Polish 2 in the real game: round 1 starts with the ant on its spawn in the nest, and no locked line shows. */
async function checkSpawn() {
  const end = Date.now() + 8000;
  let s = await snap();
  while (s && s.phase !== 'active' && Date.now() < end) {
    await sleep(100);
    s = await snap();
  }
  await sleep(400);
  s = await snap();
  const h = await hudNow();
  const c = { phase: s ? s.phase : null, round: s ? s.round : null, inNest: s ? s.inNest : null, shop: s ? s.shop : null, hud: h };
  c.ok = !!s && s.phase === 'active' && s.round === 1 && s.inNest === true && s.shop === 'closed' && !!h && h.locked === false;
  log('spawn check', JSON.stringify(c));
  return c;
}
/**
 * Feel round 1 in the real game, at the first break: the countdown shows on the HUD, the thumb walks the ant into the
 * nest, the countdown keeps running with the shop open, the next round starts by itself at zero with the ant still in
 * the shop, and in that round the nest shows the locked line and no cards.
 */
async function checkBreak(first) {
  const NEST = { x: 720, y: 1170 };
  // Slice 2: a waiting pick takes the shop's place, so take it first.
  await clearPicks();
  const c = { firstLeft: +first.breakLeft.toFixed(2), round: first.round };
  const tFirst = Date.now();
  const h0 = await hudNow();
  c.countdownText = h0 ? h0.countdown : null;
  const m = c.countdownText ? /^NEXT ROUND IN (\d+)$/.exec(c.countdownText) : null;
  c.countdownOk = !!m && Number(m[1]) >= 1 && Number(m[1]) <= 15;
  await screenshot('countdown');
  let s = await snap();
  if (s && !s.inNest) {
    // The cards stay hidden until the ant stands in the nest, so the thumb (on the right half when asked) is free to steer.
    await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 1 }]);
    const end = Date.now() + 7000;
    while (s && s.phase === 'break' && !s.inNest && Date.now() < end) {
      const dx = NEST.x - s.antX;
      const dy = NEST.y - s.antY;
      const len = Math.hypot(dx, dy) || 1;
      await touch('touchMove', [{ x: THUMB.x + (dx / len) * 60, y: THUMB.y + (dy / len) * 60, id: 1 }]);
      await sleep(100);
      s = await snap();
    }
    await touch('touchEnd', []);
  }
  await sleep(150);
  await clearPicks();
  s = await snap();
  c.walkedIn = !!s && s.phase === 'break' && s.inNest;
  c.runsInShop = false;
  if (c.walkedIn && s.breakLeft > 2.6) {
    const a = s;
    const ta = Date.now();
    await sleep(2000);
    const b = await snap();
    const tb = Date.now();
    const hb = await hudNow();
    const drop = a.breakLeft - b.breakLeft;
    const wall = (tb - ta) / 1000;
    c.inShop = { leftA: +a.breakLeft.toFixed(2), leftB: +b.breakLeft.toFixed(2), shopA: a.shop, shopB: b.shop, cards: hb ? hb.cards : null, dropS: +drop.toFixed(2), wallS: +wall.toFixed(2) };
    c.runsInShop = a.shop === 'open' && b.shop === 'open' && b.phase === 'break' && !!hb && hb.cards === true && Math.abs(drop - wall) <= 0.5;
    await screenshot('shop_open_countdown');
  }
  // Polish 1: a drag that starts on a card moves the ant and never buys; then back into the shop if it stepped out.
  const sd = await snap();
  if (sd && sd.phase === 'break' && sd.shop === 'open') {
    c.cardDrag = await dragFromCard(0, sd);
    const back = await walkNest(true, 4000);
    c.backInShop = !!back && back.phase === 'break' && back.shop === 'open';
  }
  // Wait for the expected start, then assert the last countdown value before it was zero (no jump, no pause).
  let last = null;
  let started = null;
  const endWait = Date.now() + 20_000;
  while (Date.now() < endWait) {
    const x = await snap();
    if (!x) break;
    if (x.phase === 'break') last = x;
    else {
      started = x;
      break;
    }
    await sleep(100);
  }
  c.waitedS = +((Date.now() - tFirst) / 1000).toFixed(2);
  c.lastBreakLeft = last ? +last.breakLeft.toFixed(3) : null;
  c.lastBreakShop = last ? last.shop : null;
  c.startedRound = started ? started.round : null;
  c.startedPhase = started ? started.phase : null;
  c.startsAtZero =
    !!started && started.phase === 'active' && started.round === c.round + 1 && last !== null && last.breakLeft <= 0.35 && Math.abs(c.waitedS - c.firstLeft) <= 1.0;
  c.startedWithShopOpen = !!last && last.shop === 'open';
  // Polish 2: the round found the ant in the shop, so no line yet; it shows once the ant leaves and walks back in.
  await sleep(600);
  const f0 = await snap();
  const fh = await hudNow();
  c.found = f0 ? { phase: f0.phase, round: f0.round, inNest: f0.inNest, shop: f0.shop, hud: fh } : null;
  c.foundNoLine = !!f0 && f0.phase === 'active' && f0.inNest && f0.shop === 'closed' && !!fh && fh.locked === false && fh.cards === false;
  await walkNest(false, 4000);
  await walkNest(true, 4000);
  await sleep(300);
  const ls = await snap();
  const lh = await hudNow();
  c.locked = ls ? { phase: ls.phase, round: ls.round, inNest: ls.inNest, shop: ls.shop, hud: lh } : null;
  c.lockedOk = !!ls && ls.phase === 'active' && ls.inNest && ls.shop === 'locked' && !!lh && lh.locked === true && lh.cards === false && lh.countdown === '';
  await screenshot('shop_locked');
  log('break check', JSON.stringify(c));
  return c;
}

/** Lane G7, M1: the worker as the page sees it, its version (asked by message), the caches and what they keep. */
const workerInfo = () =>
  page.evaluate(async () => {
    const reg = await navigator.serviceWorker.getRegistration();
    const ctl = navigator.serviceWorker.controller;
    const version = ctl
      ? await new Promise((res) => {
          const ch = new MessageChannel();
          ch.port1.onmessage = (e) => res(e.data);
          ctl.postMessage({ type: 'version' }, [ch.port2]);
          setTimeout(() => res(null), 3000);
        })
      : null;
    const keys = await caches.keys();
    const kept = [];
    for (const k of keys) for (const q of await (await caches.open(k)).keys()) kept.push(new URL(q.url).pathname);
    const meta = document.querySelector('meta[name="antwars-build"]');
    return {
      scope: reg ? reg.scope : null,
      active: reg && reg.active ? reg.active.state : null,
      waiting: !!(reg && reg.waiting),
      controlled: !!ctl,
      version,
      caches: keys,
      kept: kept.sort(),
      page: window.__antwars.pwa(),
      build: meta ? meta.getAttribute('content') : null,
      online: navigator.onLine,
    };
  });

/**
 * Lane G7, M1: the installable app. The first visit: the worker registers, keeps the build and takes the page over.
 * Chrome's own install check and its reading of the manifest (DevTools protocol). A reload with no network at all,
 * every response from the worker. Then a second real build (one marker in its page) served at the same address: the
 * title shows the new version line, a tap on it reloads into the new version and the old cache goes.
 */
async function runPwa() {
  const r = { ok: false };
  await page.waitForFunction(() => window.__antwars.pwa().registered, null, { timeout: 15_000 });
  await page.waitForFunction(() => navigator.serviceWorker.controller !== null, null, { timeout: 20_000 });
  r.first = await workerInfo();
  log('pwa first visit', JSON.stringify(r.first));
  // The title shows the running build's stamp once the worker has answered.
  for (let i = 0; i < 20; i++) {
    const hb = await hudNow();
    r.stampFirst = hb ? hb.title.build : null;
    if (r.stampFirst) break;
    await sleep(150);
  }
  r.installabilityErrors = (await cdp.send('Page.getInstallabilityErrors')).installabilityErrors;
  const man = await cdp.send('Page.getAppManifest');
  let parsed = null;
  try {
    parsed = man.data ? JSON.parse(man.data) : null;
  } catch {
    parsed = null;
  }
  r.manifest = {
    url: man.url,
    errors: man.errors,
    name: parsed ? parsed.name : null,
    shortName: parsed ? parsed.short_name : null,
    display: parsed ? parsed.display : null,
    orientation: parsed ? parsed.orientation : null,
    startUrl: parsed ? parsed.start_url : null,
    themeColor: parsed ? parsed.theme_color : null,
    backgroundColor: parsed ? parsed.background_color : null,
    icons: parsed ? parsed.icons : [],
  };
  log('pwa install check', JSON.stringify({ installabilityErrors: r.installabilityErrors, manifestUrl: man.url, manifestErrors: man.errors }));
  // Every icon the manifest names loads and has the size it says.
  r.icons = await page.evaluate(
    (icons) =>
      Promise.all(
        icons.map(
          (i) =>
            new Promise((res) => {
              const im = new Image();
              im.onload = () => res({ src: i.src, sizes: i.sizes, purpose: i.purpose, w: im.naturalWidth, h: im.naturalHeight });
              im.onerror = () => res({ src: i.src, error: true });
              im.src = i.src;
            }),
        ),
      ),
    r.manifest.icons,
  );
  await screenshot('pwa_title');
  // No network at all: the server is shut down and the browser is offline; the page reloads, every response comes from
  // the worker, the title is back.
  await server.close();
  await context.setOffline(true);
  const offlineResponses = [];
  const onResp = (res) => offlineResponses.push({ url: res.url().replace(base, './'), status: res.status(), fromWorker: res.fromServiceWorker() });
  page.on('response', onResp);
  const errorsBefore = errors.length;
  const httpBefore = httpErrors.length;
  await page.reload({ waitUntil: 'load' }).catch((e) => {
    r.offlineReloadError = String(e).slice(0, 300);
  });
  r.offlineBooted = await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 }).then(
    () => true,
    () => false,
  );
  await sleep(1500);
  page.off('response', onResp);
  if (!r.offlineBooted) {
    r.offlineDiag = { url: page.url(), title: await page.title().catch(() => null), errors: errors.slice(errorsBefore), http: httpErrors.slice(httpBefore), responses: offlineResponses };
    log('pwa offline reload did not boot', JSON.stringify(r.offlineDiag).slice(0, 2000));
  }
  const oh = await hudNow();
  const offSnap = await snap();
  r.offline = {
    online: await page.evaluate(() => navigator.onLine),
    phase: offSnap ? offSnap.phase : null,
    titleShown: !!oh && oh.title.shown,
    responses: offlineResponses,
    allFromWorker: offlineResponses.length > 0 && offlineResponses.every((x) => x.fromWorker && x.status === 200),
    newErrors: errors.length - errorsBefore,
    newHttpErrors: httpErrors.length - httpBefore,
  };
  await screenshot('offline_title');
  log('pwa offline reload', JSON.stringify(r.offline));
  await context.setOffline(false);
  // A second real build of the same source, one marker in its page, served at the same address.
  const distB = process.env.SMOKE_DIST_B || path.join(tmpdir(), 'antwars_g7_distB');
  await viteBuild({
    root,
    logLevel: 'warn',
    build: { outDir: distB, emptyOutDir: true },
    plugins: [{ name: 'antwars-second-build', transformIndexHtml: (html) => html.replace('</head>', '  <meta name="antwars-build" content="b" />\n  </head>') }],
  });
  const swB = readFileSync(path.join(distB, 'sw.js'), 'utf8').match(/const VERSION = "([0-9a-f]+)"/);
  r.versionA = r.first.version ? r.first.version.version : null;
  r.versionB = swB ? swB[1] : null;
  const port = Number(new URL(base).port);
  server = await preview({ root, build: { outDir: distB }, preview: { host: '127.0.0.1', port, strictPort: true }, logLevel: 'warn' });
  // The player opens the game again: the kept version opens, the browser finds the new worker, it installs and waits.
  await page.reload({ waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  let uh = null;
  const until = Date.now() + 25_000;
  while (Date.now() < until) {
    uh = await hudNow();
    if (uh && uh.update && uh.update.shown) break;
    await sleep(250);
  }
  r.before = await workerInfo();
  r.line = uh ? uh.update : null;
  await screenshot('update_line');
  log('pwa update waiting', JSON.stringify({ line: r.line, before: r.before }));
  if (uh && uh.update && uh.update.shown) {
    const loaded = page.waitForEvent('load', { timeout: 20_000 }).then(
      () => true,
      (e) => {
        r.loadError = String(e).slice(0, 200);
        return false;
      },
    );
    await tapAt(gameCss(uh.update.x, uh.update.y));
    r.reloaded = await loaded;
    await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
    await sleep(1200);
    r.after = await workerInfo();
    const ah = await hudNow();
    r.afterLine = ah ? ah.update : null;
    r.afterTitle = !!ah && ah.title.shown;
    for (let i = 0; i < 20; i++) {
      const hb = await hudNow();
      r.stampAfter = hb ? hb.title.build : null;
      if (r.stampAfter && r.stampAfter !== r.stampFirst) break;
      await sleep(150);
    }
    await screenshot('updated_title');
    log('pwa after the tap', JSON.stringify({ reloaded: r.reloaded, after: r.after, afterLine: r.afterLine }));
  }
  rmSync(distB, { recursive: true, force: true });
  const icon = (w) => r.icons.some((i) => !i.error && i.w === w && i.h === w);
  r.checks = {
    firstControlled: r.first.controlled && r.first.active === 'activated' && !!r.versionA,
    keptEveryFile: r.first.kept.length >= 7 && r.first.caches.length === 1,
    installable: Array.isArray(r.installabilityErrors) && r.installabilityErrors.length === 0,
    manifestRead:
      r.manifest.errors.length === 0 && r.manifest.name === 'Ant Wars' && r.manifest.display === 'standalone' && r.manifest.orientation === 'portrait',
    icons: icon(192) && icon(512),
    offlineReload: r.offlineBooted === true && r.offline.allFromWorker && r.offline.titleShown && r.offline.newErrors === 0 && r.offline.newHttpErrors === 0,
    newVersionBuilt: !!r.versionB && r.versionB !== r.versionA,
    lineShown: !!r.line && r.line.shown && !!r.before && r.before.waiting,
    reloadedIntoNew:
      r.reloaded === true && !!r.after && r.after.build === 'b' && !!r.after.version && r.after.version.version === r.versionB &&
      r.after.caches.length === 1 && r.after.caches[0] === `antwars-${r.versionB}`,
    lineGone: !!r.afterLine && r.afterLine.shown === false && r.afterTitle === true,
    stampShown: !!r.versionA && !!r.versionB && r.stampFirst === `build ${r.versionA.slice(0, 7)}` && r.stampAfter === `build ${r.versionB.slice(0, 7)}`,
  };
  r.ok = Object.values(r.checks).every(Boolean);
  log('pwa checks', JSON.stringify(r.checks));
  return r;
}
let pwaRun = null;

/**
 * Lane G7, M2: the title on a fresh phone. The How to play card opens by itself and holds the title under it (a tap
 * where PLAY sits does nothing); GOT IT closes it and the phone remembers; a reload shows the title without the card;
 * the How to play button opens it again; PLAY starts a run.
 */
async function runTitleFlow() {
  const r = { ok: false };
  let h = await waitTitle();
  const end = Date.now() + 4000;
  while (Date.now() < end && !(h && h.howto && h.howto.shown)) {
    await sleep(100);
    h = await hudNow();
  }
  r.first = { titleShown: !!h && h.title.shown, cardShown: !!h && h.howto.shown, lines: h ? h.howto.lines : [], stored: await readKey('antwars.howto.v1') };
  await sleep(500);
  await screenshot('howto_card');
  await tapAt(gameCss(h.title.play.x, h.title.play.y));
  await sleep(400);
  const s1 = await snap();
  h = await hudNow();
  r.playUnderCard = { phase: s1.phase, cardShown: h.howto.shown };
  if (h.howto.readyIn > 0) await sleep(h.howto.readyIn + 40);
  await tapAt(gameCss(h.howto.close.x, h.howto.close.y));
  await sleep(500);
  h = await hudNow();
  r.closed = { cardShown: h.howto.shown, stored: await readKey('antwars.howto.v1'), phase: (await snap()).phase };
  await sleep(300);
  await screenshot('title');
  await page.reload({ waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  await waitTitle();
  await sleep(600);
  h = await hudNow();
  r.reload = { titleShown: h.title.shown, cardShown: h.howto.shown };
  await tapAt(gameCss(h.title.howto.x, h.title.howto.y));
  await sleep(450);
  h = await hudNow();
  r.reopened = h.howto.shown;
  if (h.howto.readyIn > 0) await sleep(h.howto.readyIn + 40);
  await tapAt(gameCss(h.howto.close.x, h.howto.close.y));
  await sleep(450);
  h = await hudNow();
  r.reclosed = !h.howto.shown;
  await sleep(400);
  await tapAt(gameCss(h.title.play.x, h.title.play.y));
  const until = Date.now() + 3000;
  let s = await snap();
  while (Date.now() < until && s.phase === 'title') {
    await sleep(100);
    s = await snap();
  }
  r.played = s.phase;
  r.checks = {
    cardFirst: r.first.titleShown && r.first.cardShown && r.first.lines.length === 4 && r.first.stored === null,
    titleHeldUnderCard: r.playUnderCard.phase === 'title' && r.playUnderCard.cardShown,
    gotItCloses: !r.closed.cardShown && r.closed.stored === '1' && r.closed.phase === 'title',
    onceOnly: r.reload.titleShown && !r.reload.cardShown,
    buttonReopens: r.reopened === true && r.reclosed === true,
    playStarts: r.played === 'intro' || r.played === 'active',
  };
  r.ok = Object.values(r.checks).every(Boolean);
  log('title flow', JSON.stringify(r));
  return r;
}
let titleRun = null;

/** Lane N1, M2: the HUD's readouts and every card that shows now, each tested against the stats button and panel as drawn. */
const statsClear = () =>
  page.evaluate(() => {
    const hud = window.__antwars.game.scene.getScene('hud');
    const st = hud.readout().stats;
    const rectOf = (o) => {
      const b = o.getBounds();
      return { x: Math.round(b.x), y: Math.round(b.y), w: Math.round(b.width), h: Math.round(b.height) };
    };
    const hit = (a, b) => a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    const things = [
      ['round', hud.roundText],
      ['ladder line', hud.aliveText],
      ['health', hud.hpText],
      ['level', hud.levelText],
      ['sound', hud.muteBtn],
      ['nectar', hud.nectarText],
      ['nectar bead', hud.nectarIcon],
      ['boss', hud.bossText],
      ['countdown', hud.breakText],
      ['nest line', hud.nestHint],
    ]
      .filter(([, o]) => o && o.visible && o.text !== '')
      .map(([n, o]) => [n, rectOf(o)]);
    for (const c of hud.cards) if (c.bg.visible) things.push([`shop ${c.perk || c.line}`, rectOf(c.bg)]);
    for (const c of hud.pickCards) if (c.bg.visible) things.push([`pick ${c.id}`, rectOf(c.bg)]);
    const button = { x: st.button.x, y: st.button.y, w: st.button.w, h: st.button.h };
    const panel = { x: st.panel.x, y: st.panel.y, w: st.panel.w, h: st.panel.h };
    return {
      button: st.button.shown ? button : null,
      panel: st.panel.shown ? panel : null,
      checked: things.map(([n]) => n),
      underButton: st.button.shown ? things.filter(([, b]) => hit(button, b)).map(([n]) => n) : [],
      underPanel: st.panel.shown ? things.filter(([, b]) => hit(panel, b)).map(([n]) => n) : [],
    };
  });
const statsDamage = (h) => {
  const row = h && h.stats ? h.stats.rows.find((x) => x.group === 'stat' && x.id === 'damage') : null;
  return row ? row.value : null;
};
/** Lane N1, M2: a still tap on the middle of a HUD box (game units), then a short wait for the next frames. */
const tapBox = async (b) => {
  await tapAt(gameCss(b.x + b.w / 2, b.y + b.h / 2));
  await sleep(250);
  return hudNow();
};
/**
 * Lane N1, M2: the stats tab on the phone viewport. No tab on the title; in round 1 a tap on STATS
 * opens the panel with the live dart damage (the game's own build), a level up pick that changes the damage changes
 * its row, the x closes it, Tab toggles it, a drag that starts on the open panel moves nothing while a drag below it
 * moves the ant; in the break the panel sits beside the shop's cards and steps aside for a pick's cards; every readout
 * and card stays clear of it; the death screen shows no tab.
 */
async function runStatsFlow() {
  const r = { ok: false };
  let h = await waitTitle();
  r.title = { shown: !!h && h.title.shown, button: h.stats.button.shown, panel: h.stats.panel.shown };
  r.play = await passTitle();
  let s = await snap();
  const startBy = Date.now() + 8000;
  while (Date.now() < startBy && s && s.phase !== 'active') {
    await sleep(100);
    s = await snap();
  }
  // The ROUND 1 banner shows over the panel for 1.5 s (banners stay on top); the shot waits it out.
  await sleep(1800);
  s = await snap();
  h = await hudNow();
  r.round = { phase: s.phase, round: s.round, button: h.stats.button.shown, panel: h.stats.panel.shown, buttonBox: h.stats.button };
  // A tap on the button opens the panel: its dart is the game's own (snapshot damage, the Yard's build).
  h = await tapBox(h.stats.button);
  s = await snap();
  r.opened = { open: h.stats.open, shown: h.stats.panel.shown, dart: h.stats.dart, gameDamage: s.damage, row: statsDamage(h), rows: h.stats.rows.length, panel: h.stats.panel };
  await screenshot('stats_open_round');
  r.clearOpen = await statsClear();
  await takeSample();
  // Play until a level up; the panel stays open beside the round's cards (they sit low, under it).
  let i = 0;
  const lvlBy = Date.now() + 45_000;
  while (Date.now() < lvlBy && s && s.phase !== 'dead' && !(s.pending > 0 && s.offer.length > 0)) {
    const [dx, dy, ms] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, Math.min(ms, 1500));
    await sleep(500);
    s = await snap();
  }
  h = await hudNow();
  r.cards = { sheet: h.pick.shown, panel: h.stats.panel.shown, offer: s.offer ? [...s.offer] : [] };
  if (h.pick.shown) {
    await sleep(350);
    await screenshot('stats_with_cards');
    r.clearCards = await statsClear();
    // A pick that changes the dart (Strong Jaw, Front Fang or Echo Sting); if none is offered, the harness puts Strong
    // Jaw on the sheet through the debug hook, and the tap itself goes through the HUD and the game as any pick does.
    const dmgPowers = ['jaw', 'fang', 'echo'];
    r.forced = !s.offer.some((id) => dmgPowers.includes(id));
    if (r.forced) {
      await page.evaluate(() => {
        const g = window.__antwars.game.scene.getScene('game');
        g.offer = ['jaw', ...g.offer.filter((id) => id !== 'jaw')].slice(0, 3);
      });
      await sleep(400);
    }
    h = await hudNow();
    const idx = h.pick.cards.findIndex((c) => dmgPowers.includes(c.id));
    const before = { row: statsDamage(h), damage: (await snap()).damage };
    const pick = await tapPick(Math.max(0, idx));
    await sleep(400);
    h = await hudNow();
    s = await snap();
    r.afterPick = { id: pick ? pick.id : null, applied: !!pick && pick.ok, rowBefore: before.row, rowAfter: statsDamage(h), damageBefore: before.damage, damageAfter: s.damage, dart: h.stats.dart, open: h.stats.open, shown: h.stats.panel.shown };
    await screenshot('stats_after_pick');
    await clearPicks();
  }
  // The x closes the panel.
  h = await hudNow();
  await tapAt(gameCss(h.stats.close.x, h.stats.close.y));
  await sleep(250);
  h = await hudNow();
  r.closed = { open: h.stats.open, shown: h.stats.panel.shown, button: h.stats.button.shown };
  await screenshot('stats_closed');
  // Tab on a keyboard opens and closes it as the button does.
  await page.keyboard.press('Tab');
  await sleep(200);
  const tabOpen = (await hudNow()).stats.open;
  await page.keyboard.press('Tab');
  await sleep(200);
  const tabShut = (await hudNow()).stats.open;
  r.tab = { opened: tabOpen, closedAgain: tabShut === false };
  // Open again; a drag that starts on the panel moves nothing and never takes the stick.
  h = await tapBox(h.stats.button);
  await clearPicks();
  h = await hudNow();
  const P = h.stats.panel;
  const p0 = gameCss(P.x + P.w / 2, P.y + Math.min(P.h / 2, 220));
  const b0 = await snap();
  await touch('touchStart', [{ x: p0.x, y: p0.y, id: 7 }]);
  await sleep(40);
  let stickOnPanel = false;
  for (let k = 1; k <= 6; k++) {
    await touch('touchMove', [{ x: p0.x + k * 25, y: p0.y + k * 18, id: 7 }]);
    await sleep(80);
    stickOnPanel = stickOnPanel || (await page.evaluate(() => window.__antwars.game.scene.getScene('hud').stick.active));
  }
  const m0 = await snap();
  await touch('touchEnd', []);
  await sleep(250);
  h = await hudNow();
  r.dragOnPanel = {
    start: p0,
    moved: +Math.hypot(m0.antX - b0.antX, m0.antY - b0.antY).toFixed(1),
    moving: m0.moving,
    stick: stickOnPanel,
    stillOpen: h.stats.open,
    phase: m0.phase,
    frozen: m0.frozen,
  };
  // A drag below the panel, where a thumb rests, moves the ant.
  const b1 = await snap();
  await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 8 }]);
  await sleep(40);
  await touch('touchMove', [{ x: THUMB.x, y: THUMB.y - 70, id: 8 }]);
  await sleep(500);
  const m1 = await snap();
  await touch('touchEnd', []);
  await sleep(200);
  r.dragElsewhere = { start: { x: THUMB.x, y: THUMB.y }, moved: +Math.hypot(m1.antX - b1.antX, m1.antY - b1.antY).toFixed(1), moving: m1.moving, frozen: m1.frozen };
  // The break: walk into the nest with the panel open; it sits beside the shop's cards.
  s = await snap();
  const brkBy = Date.now() + 60_000;
  i = 0;
  while (Date.now() < brkBy && s && s.phase !== 'break' && s.phase !== 'dead') {
    const [dx, dy, ms] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, Math.min(ms, 1200));
    await clearPicks();
    await sleep(400);
    s = await snap();
  }
  if (s && s.phase === 'break') {
    s = await walkNest(true, 9000);
    await clearPicks();
    await sleep(300);
    h = await hudNow();
    r.inBreak = { phase: s.phase, inNest: s.inNest, shop: s.shop, cards: h.cards, open: h.stats.open, shown: h.stats.panel.shown, row: statsDamage(h) };
    await screenshot('stats_open_break');
    r.clearBreak = await statsClear();
    // Design note, 2026-10-30: with a long mid run list the panel stays half wide and above the ant, its text at 0.8 or
    // more, the list folded rather than shrunk. The run is filled through the game's own buys (the nest's shop is open
    // here) and picks.
    r.midRun = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      g.nectar = 1e6;
      const bought = [];
      for (const id of ['damage', 'damage', 'rate', 'health', 'speed']) bought.push(g.tryBuyLine(id));
      for (const id of ['twin', 'chitin']) bought.push(g.tryBuy(id));
      const picked = [];
      for (const id of ['jaw', 'jaw', 'glands', 'eye', 'shell', 'fang', 'fury', 'stance', 'fork']) {
        g.pending = 1;
        g.offer = [id];
        picked.push(g.pickPower(id));
      }
      return { bought, picked };
    });
    await sleep(500);
    const mid = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const hud = window.__antwars.game.scene.getScene('hud');
      const st = hud.readout().stats;
      const cam = g.cameras.main;
      const lines = hud.statsLines
        .filter((t) => t.visible)
        .map((t) => {
          const b = t.getBounds();
          return { text: t.text, x: +b.x.toFixed(1), y: +b.y.toFixed(1), right: +b.right.toFixed(1), bottom: +b.bottom.toFixed(1) };
        });
      return { open: st.open, panel: st.panel, level: st.level, hidden: st.hidden, rows: st.rows.length, H: g.scale.height, ant: { x: +(g.ant.x - cam.worldView.x).toFixed(1), y: +(g.ant.y - cam.worldView.y).toFixed(1) }, lines };
    });
    mid.panelBottom = mid.panel.y + mid.panel.h;
    mid.antTop = mid.ant.y - 16;
    mid.overlap = +(mid.panelBottom - mid.antTop).toFixed(1);
    mid.inside = mid.lines.every((l) => l.x >= mid.panel.x - 1 && l.right <= mid.panel.x + mid.panel.w + 1 && l.bottom <= mid.panelBottom + 1);
    mid.damageWhole = mid.lines.every((l) => !/(^| )a$/.test(l.text) && !/^(dart|shot)/.test(l.text));
    r.mid = mid;
    await screenshot('stats_open_mid_run');
    // A pick's cards in the break sit high, over the panel's place: the panel steps aside, open, and comes back after the tap.
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      g.queuePicks(1, 'ROYAL JELLY: A FREE PICK');
    });
    await sleep(400);
    h = await hudNow();
    r.breakSheet = { sheet: h.pick.shown, open: h.stats.open, shown: h.stats.panel.shown };
    await screenshot('stats_break_sheet');
    r.clearSheet = await statsClear();
    await tapPick(0);
    await sleep(400);
    h = await hudNow();
    r.breakSheet.after = { sheet: h.pick.shown, open: h.stats.open, shown: h.stats.panel.shown };
  }
  // The death screen shows no tab.
  s = await snap();
  const actBy = Date.now() + 20_000;
  while (Date.now() < actBy && s && s.phase === 'break') {
    await sleep(200);
    s = await snap();
  }
  await dieNow();
  await sleep(300);
  h = await hudNow();
  s = await snap();
  r.death = { phase: s.phase, button: h.stats.button.shown, panel: h.stats.panel.shown };
  await screenshot('stats_death');
  const none = (c) => !!c && c.underButton.length === 0 && c.underPanel.length === 0;
  r.checks = {
    noTabOnTitle: r.title.shown && !r.title.button && !r.title.panel,
    buttonInRound: r.round.phase === 'active' && r.round.button && !r.round.panel,
    buttonTapTarget: r.round.buttonBox.w >= 81.2 && r.round.buttonBox.h >= 81.2,
    opensWithLiveDart: r.opened.open && r.opened.shown && r.opened.dart === r.opened.gameDamage && typeof r.opened.row === 'string' && r.opened.row.startsWith(`${r.opened.gameDamage} a dart`),
    clearWhenOpen: none(r.clearOpen) && r.clearOpen.checked.includes('health') && r.clearOpen.checked.includes('sound'),
    besideRoundCards: !!r.clearCards && r.cards.sheet && r.cards.panel && none(r.clearCards) && r.clearCards.checked.some((n) => n.startsWith('pick ')),
    pickChangesDamage: !!r.afterPick && r.afterPick.applied && r.afterPick.rowAfter !== r.afterPick.rowBefore && r.afterPick.dart === r.afterPick.damageAfter && r.afterPick.damageAfter !== r.afterPick.damageBefore,
    closeX: !r.closed.open && !r.closed.shown && r.closed.button,
    tabToggles: r.tab.opened === true && r.tab.closedAgain,
    dragOnPanelMovesNothing: r.dragOnPanel.stillOpen && !r.dragOnPanel.stick && r.dragOnPanel.moved < 2 && !r.dragOnPanel.moving,
    dragElsewhereMoves: r.dragElsewhere.moved >= 20,
    besideShop: !!r.inBreak && r.inBreak.shop === 'open' && r.inBreak.cards && r.inBreak.shown && none(r.clearBreak) && r.clearBreak.checked.some((n) => n.startsWith('shop ')),
    midRunSmall:
      !!r.mid && r.midRun.bought.every(Boolean) && r.midRun.picked.every(Boolean) && r.mid.open && r.mid.panel.shown && r.mid.rows >= 15 &&
      r.mid.panel.w === 360 && r.mid.panel.scale >= 0.8 && r.mid.overlap <= 0 && r.mid.inside && r.mid.damageWhole,
    asideForBreakCards: !!r.breakSheet && r.breakSheet.sheet && r.breakSheet.open && !r.breakSheet.shown && none(r.clearSheet) && !!r.breakSheet.after && r.breakSheet.after.shown,
    noTabOnDeath: r.death.phase === 'dead' && !r.death.button && !r.death.panel,
  };
  r.ok = Object.values(r.checks).every(Boolean);
  log('stats flow', JSON.stringify(r));
  return r;
}
let statsRun = null;

/** Lane N1, M3: the stick as the HUD holds it and the ant as the Yard moves it, read from the scenes (any build has these). */
const stickNow = () =>
  page.evaluate(() => {
    const hud = window.__antwars.game.scene.getScene('hud');
    const g = window.__antwars.game.scene.getScene('game');
    const ro = hud.readout();
    return {
      pointerId: hud.thumb.pointerId,
      baseX: hud.thumb.baseX,
      baseY: hud.thumb.baseY,
      knob: ro.stick ? { x: ro.stick.knobX, y: ro.stick.knobY } : null,
      active: hud.stick.active,
      x: +hud.stick.x.toFixed(4),
      y: +hud.stick.y.toFixed(4),
      antX: +g.ant.x.toFixed(1),
      antY: +g.ant.y.toFixed(1),
      rot: +g.ant.rotation.toFixed(3),
      phase: g.phase,
      frozen: g.snap ? g.snap.frozen : null,
    };
  });
/**
 * Lane N1, M3 (design note, 2026-10-29: the stick stays where the first touch landed, for the whole touch): the
 * thumb stick on the phone. A press in the bottom third, then a drag far up and to the right past the ring: the base
 * stays where the press landed, the knob sits on the ring and the ant runs up and to the right; the thumb comes back
 * inside the ring, right of the first touch: the ant runs right (a trailing base would have sent it back down and
 * left); a lift ends the stick; a press elsewhere puts a new base there.
 */
async function runStickFlow() {
  const r = { ok: false };
  let s = await snap();
  const by = Date.now() + 8000;
  while (Date.now() < by && s && s.phase !== 'active') {
    await sleep(100);
    s = await snap();
  }
  await sleep(1800);
  const [GW] = env.gameSize.split('x').map(Number);
  const unitsPerPx = GW / rect.w;
  const toGame = (p) => ({ x: +((p.x - rect.x) * unitsPerPx).toFixed(2), y: +((p.y - rect.y) * unitsPerPx).toFixed(2) });
  const ringPx = 92 / unitsPerPx;
  const p1 = { x: Math.round(rect.x + rect.w * 0.28), y: Math.round(rect.y + rect.h * 0.82) };
  r.press = { css: p1, game: toGame(p1), bottomThird: p1.y > rect.y + (rect.h * 2) / 3, ringPx: +ringPx.toFixed(2) };
  await touch('touchStart', [{ x: p1.x, y: p1.y, id: 3 }]);
  await sleep(60);
  const at1 = await stickNow();
  // Far up and to the right, four and a half ring radii out, in five steps.
  const far = { x: p1.x + 3.2 * ringPx, y: p1.y - 3.2 * ringPx };
  for (let i = 1; i <= 5; i++) {
    await touch('touchMove', [{ x: p1.x + ((far.x - p1.x) * i) / 5, y: p1.y + ((far.y - p1.y) * i) / 5, id: 3 }]);
    await sleep(60);
  }
  await sleep(150);
  const f0 = await stickNow();
  await sleep(400);
  const f1 = await stickNow();
  await screenshot('stick_far');
  // Back inside the ring, right of the first touch.
  const back = { x: p1.x + 0.6 * ringPx, y: p1.y };
  await touch('touchMove', [{ x: back.x, y: back.y, id: 3 }]);
  await sleep(150);
  const b0 = await stickNow();
  await sleep(300);
  const b1 = await stickNow();
  await screenshot('stick_back_inside_ring');
  await touch('touchEnd', []);
  await sleep(250);
  const lifted = await stickNow();
  // A new press elsewhere: a new base where it lands, and the ant runs toward its thumb.
  const p2 = { x: Math.round(rect.x + rect.w * 0.7), y: Math.round(rect.y + rect.h * 0.7) };
  await touch('touchStart', [{ x: p2.x, y: p2.y, id: 4 }]);
  await sleep(60);
  const at2 = await stickNow();
  await touch('touchMove', [{ x: p2.x, y: p2.y - 0.8 * ringPx, id: 4 }]);
  await sleep(300);
  const n1 = await stickNow();
  await screenshot('stick_new_base');
  await touch('touchEnd', []);
  await sleep(200);
  const g1 = toGame(p1);
  const g2 = toGame(p2);
  const farDist = Math.hypot(toGame(far).x - g1.x, toGame(far).y - g1.y);
  r.atPress = at1;
  r.far = { css: { x: +far.x.toFixed(1), y: +far.y.toFixed(1) }, radii: +(farDist / 92).toFixed(2), f0, f1, antMoved: { dx: +(f1.antX - f0.antX).toFixed(1), dy: +(f1.antY - f0.antY).toFixed(1) } };
  r.back = { b0, b1, antMoved: { dx: +(b1.antX - b0.antX).toFixed(1), dy: +(b1.antY - b0.antY).toFixed(1) } };
  r.lifted = lifted;
  r.second = { css: p2, game: g2, at2, n1 };
  const near = (a, b) => Math.abs(a - b) < 0.6;
  const knobOnRing = f1.knob === null ? null : Math.abs(Math.hypot(f1.knob.x - f1.baseX, f1.knob.y - f1.baseY) - 92) < 0.6;
  r.checks = {
    pressInBottomThird: r.press.bottomThird,
    // Phaser numbers its own pointers (not the touch ids sent): a finger holds the stick when its id is not -1.
    baseAtFirstTouch: at1.pointerId !== -1 && near(at1.baseX, g1.x) && near(at1.baseY, g1.y),
    farPastRing: r.far.radii > 4,
    baseStaysPut: f0.baseX === at1.baseX && f0.baseY === at1.baseY && f1.baseX === at1.baseX && f1.baseY === at1.baseY && b1.baseX === at1.baseX && b1.baseY === at1.baseY,
    knobOnRing: knobOnRing === true,
    runsUpAndRight: f1.active && f1.x > 0.69 && f1.y < -0.69 && r.far.antMoved.dx > 20 && r.far.antMoved.dy < -20 && Math.abs(f1.rot + Math.PI / 4) < 0.05,
    backRunsRight: b1.active && b1.x > 0.99 && Math.abs(b1.y) < 0.01 && r.back.antMoved.dx > 15 && Math.abs(r.back.antMoved.dy) < 6,
    liftEnds: lifted.pointerId === -1 && !lifted.active,
    newBaseThere: at2.pointerId !== -1 && near(at2.baseX, g2.x) && near(at2.baseY, g2.y) && n1.baseX === at2.baseX && n1.baseY === at2.baseY,
    newRunsUp: n1.active && Math.abs(n1.x) < 0.01 && n1.y < -0.99,
    yardRunning: !f1.frozen && !b1.frozen && !n1.frozen,
  };
  r.ok = Object.values(r.checks).every(Boolean);
  log('stick flow', JSON.stringify(r));
  return r;
}
let stickRun = null;

/** A YYYY-MM-DD day as the title shows it (Oct 25). */
function dayName(day) {
  const [, m, d] = day.split('-').map(Number);
  return `${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1]} ${d}:`;
}

/** The day after a YYYY-MM-DD day, for the next day's phone. */
function nextDay(day) {
  const [y, m, d] = day.split('-').map(Number);
  const t = new Date(Date.UTC(y, m - 1, d + 1));
  return `${t.getUTCFullYear()}-${String(t.getUTCMonth() + 1).padStart(2, '0')}-${String(t.getUTCDate()).padStart(2, '0')}`;
}

/**
 * Lane G7, M3: one player's Daily run on a fresh phone at a fixed day. Opens the title at ?debug&day=, taps DAILY, stands
 * still at the nest (the holes in reach are then the same for every player) and takes each pick by its first card,
 * until the round after untilRound starts (every spawn of rounds 1 to untilRound done). With die, the ant is then set
 * to 1 health and the next bite ends the run: the Daily death screen.
 */
async function dailyRun(player, day, untilRound, die, rollTo = null) {
  const r = { player, day };
  await page.evaluate(() => {
    try {
      localStorage.clear();
    } catch {
      // Nothing stored.
    }
  });
  await page.goto(`${base}?debug&day=${day}`, { waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  let h = await waitTitle();
  r.titleSub = h.title.daily.sub;
  r.stored0 = await readKey('antwars.daily.v1');
  if (rollTo) {
    // The phone's day turns over while the title stays open (an installed app back from the background has no reload).
    await page.evaluate((d) => history.replaceState(null, '', `?debug&day=${d}`), rollTo);
    await sleep(500);
    h = await hudNow();
    r.titleSubAfterRoll = h.title.daily.sub;
  }
  if (player === 'A') await screenshot('daily_title');
  await tapAt(gameCss(h.title.daily.x, h.title.daily.y));
  let s = await snap();
  const leave = Date.now() + 3000;
  while (s.phase === 'title' && Date.now() < leave) {
    await sleep(100);
    s = await snap();
  }
  r.start = { phase: s.phase, daily: s.daily, ladder: s.ladder, damage: s.damage, maxHp: s.maxHp };
  const end = Date.now() + 240_000;
  let hudShot = false;
  while (Date.now() < end) {
    s = await note(`daily ${player}`);
    if (!s || s.phase === 'dead') break;
    if (s.pending > 0 && s.offer.length > 0) await tapPick(0);
    if (!hudShot && s.phase === 'active' && s.round === untilRound && s.alive >= 2) {
      const hh = await hudNow();
      r.hudLine = hh ? hh.ladderLine : null;
      if (player === 'A') await screenshot('daily_hud');
      hudShot = true;
    }
    if (s.phase === 'active' && s.round > untilRound) break;
    await sleep(200);
  }
  s = await snap();
  r.reached = { round: s.round, phase: s.phase, level: s.level, hp: s.hp, kills: s.kills };
  r.spawns = s.spawns.filter((e) => e.round <= untilRound);
  r.offers = s.offers.filter((o) => o.round <= untilRound).map((o) => o.offer);
  if (die && s.phase !== 'dead') {
    // The ant holds its fire and keeps 1 health: the next predator to reach it ends the run with a real bite.
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      g.hp = 1;
      g.graceUntil = 0;
      g.fireCooldown = 1e9;
      g.echoes = [];
    });
    const until = Date.now() + 20_000;
    s = await snap();
    while (s.phase !== 'dead' && Date.now() < until) {
      await sleep(200);
      s = await snap();
    }
    r.diedBy = s.phase === 'dead' ? 'a bite at 1 health' : null;
    let dh = await hudNow();
    const ready = Date.now() + 4000;
    while (Date.now() < ready && !(dh && dh.death && dh.death.ready)) {
      await sleep(150);
      dh = await hudNow();
    }
    r.death = { phase: s.phase, text: dh ? dh.death.text : '', ready: !!dh && dh.death.ready, record: s.record };
    r.stored = await readKey('antwars.daily.v1');
    if (player === 'A') await screenshot('daily_death');
  }
  log(`daily ${player}`, JSON.stringify({ ...r, spawns: r.spawns.length, offers: r.offers }));
  return r;
}

/** Lane G7, M3: players A and B on one day, C on the next; the same run for A and B, another for C. */
/**
 * Lane G7, M3: a Daily run closed and continued. Player D plays the day standing still to the break after round 1, the
 * page reloads (Safari closed and opened again), the title offers CONTINUE for the saved Daily run, and the continued
 * run must meet in round 2 the same spawns, from the same holes, as player A's run that was never closed.
 */
async function dailyContinueRun(day) {
  const r = { player: 'D', day };
  await page.evaluate(() => {
    try {
      localStorage.clear();
    } catch {
      // Nothing stored.
    }
  });
  await page.goto(`${base}?debug&day=${day}`, { waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  let h = await waitTitle();
  await tapAt(gameCss(h.title.daily.x, h.title.daily.y));
  let s = await snap();
  const end = Date.now() + 120_000;
  while (Date.now() < end) {
    s = await note('daily D');
    if (!s || s.phase === 'dead') break;
    if (s.pending > 0 && s.offer.length > 0) await tapPick(0);
    if (s.phase === 'break' && s.round === 1) break;
    await sleep(200);
  }
  await sleep(1500);
  r.beforeClose = { phase: s.phase, round: s.round, level: s.level, offers: s.offers.map((o) => o.offer) };
  await page.reload({ waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  h = await waitTitle();
  s = await snap();
  r.saved = s.saved;
  r.contShown = !!h && h.title.contShown;
  await tapAt(gameCss(h.title.cont.x, h.title.cont.y));
  const back = Date.now() + 3000;
  s = await snap();
  while (s.phase === 'title' && Date.now() < back) {
    await sleep(100);
    s = await snap();
  }
  r.resumed = { phase: s.phase, round: s.round, daily: s.daily, ladder: s.ladder, level: s.level };
  const until = Date.now() + 120_000;
  while (Date.now() < until) {
    s = await note('daily D continued');
    if (!s || s.phase === 'dead') break;
    if (s.pending > 0 && s.offer.length > 0) await tapPick(0);
    if (s.phase === 'active' && s.round > 2) break;
    await sleep(200);
  }
  r.spawns2 = s.spawns.filter((e) => e.round === 2).map((e) => `${e.round}:${e.kind}:${e.hole}`);
  r.offersAfter = s.offers.map((o) => o.offer);
  log('daily D', JSON.stringify(r));
  return r;
}

/** VG7: the ant holds its fire at 1 health until a predator's bite ends the run, then the death screen's buttons show. */
async function dieByBite() {
  let s = await snap();
  const start = Date.now() + 20_000;
  while (Date.now() < start && !(s && s.phase === 'active' && s.alive >= 1)) {
    await sleep(150);
    s = await snap();
  }
  await page.evaluate(() => {
    const g = window.__antwars.game.scene.getScene('game');
    g.hp = 1;
    g.graceUntil = 0;
    g.fireCooldown = 1e9;
    g.echoes = [];
  });
  const end = Date.now() + 25_000;
  s = await snap();
  while (Date.now() < end && s.phase !== 'dead') {
    await sleep(200);
    s = await snap();
  }
  let h = await hudNow();
  const ready = Date.now() + 4000;
  while (Date.now() < ready && !(h && h.death && h.death.ready)) {
    await sleep(150);
    h = await hudNow();
  }
  return { phase: s.phase, daily: s.daily, today: s.today, text: h ? h.death.text : '', ready: !!h && h.death.ready, again: h ? h.death.again : null };
}

/** VG7: a tap on PLAY AGAIN; both scenes restart, and the new run is read once it is under way. */
async function tapPlayAgain(at) {
  await tapAt(gameCss(at.x, at.y));
  await sleep(300);
  let s = await snap();
  const end = Date.now() + 6000;
  while (Date.now() < end && !(s && (s.phase === 'intro' || s.phase === 'active'))) {
    await sleep(150);
    s = await snap();
  }
  await sleep(400);
  s = await snap();
  const h = await hudNow();
  return { phase: s ? s.phase : null, daily: s ? s.daily : null, today: s ? s.today : null, ladder: s ? s.ladder : null, hudLine: h ? h.ladderLine : null };
}

/**
 * VG7: PLAY AGAIN on a death screen. A Daily run dies on its day and PLAY AGAIN plays that day again; it dies again, the
 * day turns over on the death screen (after midnight), and PLAY AGAIN plays the new day's challenge, never a fresh run
 * of yesterday's; a normal run's PLAY AGAIN stays a normal run.
 */
async function runDailyAgain(day) {
  const next = nextDay(day);
  const label = (d) => dayName(d).slice(0, -1);
  const r = { day, next };
  await page.evaluate(() => {
    try {
      localStorage.clear();
    } catch {
      // Nothing stored.
    }
  });
  await page.goto(`${base}?debug&day=${day}`, { waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  let h = await waitTitle();
  await tapAt(gameCss(h.title.daily.x, h.title.daily.y));
  r.first = await dieByBite();
  r.again1 = await tapPlayAgain(r.first.again);
  r.second = await dieByBite();
  // The phone's day turns over while the death screen is up.
  await page.evaluate((d) => history.replaceState(null, '', `?debug&day=${d}`), next);
  await sleep(300);
  await screenshot('again_death_after_midnight');
  r.again2 = await tapPlayAgain(r.second.again);
  await screenshot('again_today_daily');
  // A normal run: the title, PLAY, a death, PLAY AGAIN.
  await page.goto(`${base}?debug&day=${next}`, { waitUntil: 'load' });
  await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
  h = await waitTitle();
  await tapAt(gameCss(h.title.play.x, h.title.play.y));
  r.normal = await dieByBite();
  r.again3 = await tapPlayAgain(r.normal.again);
  r.checks = {
    sameDayReplays:
      r.first.phase === 'dead' && r.first.daily === day && r.first.text.includes(`DAILY CHALLENGE, ${label(day)}`) &&
      r.again1.daily === day && r.again1.ladder === 'pure' && typeof r.again1.hudLine === 'string' && r.again1.hudLine.startsWith('DAILY'),
    afterMidnightPlaysToday:
      r.second.phase === 'dead' && r.second.daily === day && r.again2.today === next && r.again2.daily === next &&
      r.again2.ladder === 'pure' && typeof r.again2.hudLine === 'string' && r.again2.hudLine.startsWith('DAILY'),
    normalStaysNormal:
      r.normal.phase === 'dead' && r.normal.daily === null && r.again3.daily === null && typeof r.again3.hudLine === 'string' && !r.again3.hudLine.startsWith('DAILY'),
  };
  r.ok = Object.values(r.checks).every(Boolean);
  log('daily again', JSON.stringify(r));
  return r;
}

async function runDaily() {
  // VG7: SMOKE_DAILY_AGAIN runs only the PLAY AGAIN checks (a day that turns over on the death screen).
  if (process.env.SMOKE_DAILY_AGAIN) return runDailyAgain(SMOKE_DAY);
  // SMOKE_DAILY_CONTINUE_AGAINST names a finished --daily record: only player D runs, against that record's player A.
  const against = process.env.SMOKE_DAILY_CONTINUE_AGAINST;
  if (against) {
    const A = JSON.parse(readFileSync(against, 'utf8')).dailyResult.A;
    const D = await dailyContinueRun(SMOKE_DAY);
    const a2 = A.spawns.filter((e) => e.round === 2).map((e) => `${e.round}:${e.kind}:${e.hole}`);
    const r = { day: SMOKE_DAY, D, spawnsA2: a2 };
    r.checks = {
      savedAsDaily: !!D.saved && D.saved.daily === SMOKE_DAY && D.saved.ladder === 'pure' && D.saved.round === 1 && D.contShown,
      continuesAsDaily: D.resumed.phase === 'break' && D.resumed.round === 1 && D.resumed.daily === SMOKE_DAY && D.resumed.ladder === 'pure',
      sameRound2Spawns: a2.length >= 6 && JSON.stringify(D.spawns2) === JSON.stringify(a2),
      // The offers drawn before the close and after Continue, end to end, are the first offers of A's unbroken run.
      sameOffersAcross: D.beforeClose.offers.length + D.offersAfter.length >= 2 && JSON.stringify(D.beforeClose.offers.concat(D.offersAfter)) === JSON.stringify(A.offers.slice(0, D.beforeClose.offers.length + D.offersAfter.length)),
    };
    r.ok = Object.values(r.checks).every(Boolean);
    log('daily continue checks', JSON.stringify(r.checks));
    return r;
  }
  const A = await dailyRun('A', SMOKE_DAY, DAILY_UNTIL, true);
  const B = await dailyRun('B', SMOKE_DAY, DAILY_UNTIL, false);
  // C opens on the same day, the day turns over with the title open, then C taps DAILY: the next day's run.
  const C = await dailyRun('C', SMOKE_DAY, 1, false, nextDay(SMOKE_DAY));
  const seq = (x, upTo) => x.spawns.filter((e) => e.round <= upTo).map((e) => `${e.round}:${e.kind}:${e.hole}`);
  const r = {
    day: SMOKE_DAY,
    A,
    B,
    C,
    spawnsA: seq(A, DAILY_UNTIL),
    spawnsB: seq(B, DAILY_UNTIL),
  };
  const deathText = A.death ? A.death.text : '';
  r.checks = {
    dailyStarts: A.start.phase === 'intro' && A.start.daily === SMOKE_DAY && A.start.ladder === 'pure' && A.start.damage === 150 && A.start.maxHp === 600,
    titleShowsDate: /^Oct 25: the same run for everyone today/.test(A.titleSub) || SMOKE_DAY !== '2026-10-25',
    reachedRound3: A.reached.round >= DAILY_UNTIL + 1 && B.reached.round >= DAILY_UNTIL + 1 && (DAILY_UNTIL >= 3 || !!process.env.SMOKE_DAILY_UNTIL),
    hudFlagsDaily: typeof A.hudLine === 'string' && A.hudLine.startsWith('DAILY'),
    sameSpawns: r.spawnsA.length >= 6 && JSON.stringify(r.spawnsA) === JSON.stringify(r.spawnsB),
    sameOffers: A.offers.length >= 1 && JSON.stringify(A.offers) === JSON.stringify(B.offers),
    nextDayDiffers: C.start.daily === nextDay(SMOKE_DAY) && JSON.stringify(seq(A, 1)) !== JSON.stringify(seq(C, 1)) && JSON.stringify(A.offers[0]) !== JSON.stringify(C.offers[0]),
    rollsOverWhileOpen: C.titleSub.startsWith(dayName(SMOKE_DAY)) && typeof C.titleSubAfterRoll === 'string' && C.titleSubAfterRoll.startsWith(dayName(nextDay(SMOKE_DAY))) && C.start.daily === nextDay(SMOKE_DAY),
    deathScreenDaily: !!A.death && A.death.phase === 'dead' && deathText.includes('DAILY CHALLENGE') && /NEW DAILY BEST: ROUND \d+/.test(deathText),
    bestKeptForDay: !!A.stored && JSON.parse(A.stored).day === SMOKE_DAY && JSON.parse(A.stored).best === A.death.record.best,
  };
  // The first offers on Oct 25 2026 are pinned by daily.test.ts; taking the first card each time, the live game must draw them.
  if (SMOKE_DAY === '2026-10-25') {
    const pinned = [['honeydew', 'lucky', 'needle'], ['fork', 'fury', 'eye'], ['echo', 'eye', 'fury']];
    r.checks.offersMatchPin = JSON.stringify(A.offers.slice(0, 3)) === JSON.stringify(pinned.slice(0, Math.min(3, A.offers.length)));
  }
  r.ok = Object.values(r.checks).every(Boolean);
  log('daily checks', JSON.stringify(r.checks));
  return r;
}
let dailyResult = null;

// Slice 3: the title opens every run (not a practice run, and not the colony flow, which works the title itself).
let titlePass = null;
// Lane G9, M4: a practice run that starts on a termite rush records the rush frame by frame as the page sees it: the
// count at its start, every bite's raw value (only termites bite in a rush) and the most health a termite had.
const RUSH_EXPECT = { 5: { total: 40, bite: 8, multiShot: false }, 15: { total: 48, bite: 9, multiShot: false }, 35: { total: 56, bite: 10, multiShot: true } };
let rushRun = null;
if (startRound && RUSH_EXPECT[startRound]) {
  await page.evaluate((round) => {
    const w = { round, maxLeft: 0, termiteHpMax: 0, bites: [] };
    window.__g9rush = w;
    const tick = () => {
      const a = window.__antwars;
      const s = a && a.snapshot();
      if (s && s.round === round && s.phase === 'active') {
        w.maxLeft = Math.max(w.maxLeft, s.left);
        const y = a.yard ? a.yard() : null;
        if (y) for (const f of y.foes) if (f.kind === 'termite') w.termiteHpMax = Math.max(w.termiteHpMax, f.hp);
        for (const h of s.hurts) if (!w.bites.includes(h.raw)) w.bites.push(h.raw);
      }
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }, startRound);
}
/**
 * Lane N1 (design note, 2026-10-29: every round speeds up alike once the ramp begins): from
 * round 6 no round spawns slower than the horde gap of its number. A practice run's first round is watched frame by
 * frame inside the page: each new entry of the snapshot's spawn log is stamped with the Yard's clock (yardMs, which a
 * pick sheet stops), so the gaps are read on the game's own clock, on any build (5304e3e too). gap: the round plan's
 * spawn gap now (curve.ts roundPlan); before: the gap on 5304e3e. A spawn lands on the first frame its timer runs out,
 * so a measured gap is the plan's gap rounded up to a whole frame; the check reads the median of the first ten.
 */
const PACE_EXPECT = {
  5: { kind: 'breather', gap: 0.3, before: 0.3 },
  10: { kind: 'boss', gap: 0.315124704862, before: 1.5 },
  15: { kind: 'breather', gap: 0.243837489558, before: 0.27 },
  20: { kind: 'boss', gap: 0.188676801268, before: 1.5 },
  25: { kind: 'boss', gap: 0.145994512169, before: 1.5 },
  35: { kind: 'breather', gap: 0.1, before: 0.243 },
};
let paceRun = null;
if (startRound && PACE_EXPECT[startRound]) {
  await page.evaluate((round) => {
    const w = { round, seen: 0, stamps: [], frames: 0, frameMsSum: 0, last: 0, maxAlive: 0 };
    window.__n1pace = w;
    const tick = (t) => {
      if (w.last > 0 && w.frames < 3000) {
        w.frames += 1;
        w.frameMsSum += t - w.last;
      }
      w.last = t;
      const a = window.__antwars;
      const s = a && a.snapshot();
      if (s && Array.isArray(s.spawns)) {
        if (s.round === round && s.phase === 'active') w.maxAlive = Math.max(w.maxAlive, s.alive);
        while (w.seen < s.spawns.length) {
          const e = s.spawns[w.seen];
          w.seen += 1;
          if (e.round === round && w.stamps.length < 120) w.stamps.push({ kind: e.kind, yardMs: s.yardMs, alive: s.alive });
        }
      }
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }, startRound);
}
if (!colonyFlow && !juiceFlow && !pwaFlow && !titleFlow && !dailyFlow && !statsFlow && !(long && stateIn)) titlePass = await passTitle();

if (dev || desktop) {
  await note('dev boot');
  await hold(0, -70, 2500);
  await note('after a held stick');
  await sleep(2500);
  await note('dev end');
  await screenshot('round1');
} else if (long) {
  // A bot plays a whole run: it kites a loop around the nest during rounds, walks home in breaks and buys perks
  // with real taps on the shop cards. It is a steady, unskilled player, not a good one.
  const [GW, GH] = env.gameSize.split('x').map(Number);
  const k = rect.w / GW;
  const css = (gx, gy) => ({ x: rect.x + gx * k, y: rect.y + gy * k });
  const NEST = { x: 720, y: 1170 };
  const cw = 340;
  const ch = 104;
  const gap = 12;
  const cardX = GW - cw - 12;
  const cardTop = GH - 3 * (ch + gap) - 28;
  const cardAt = (i) => css(cardX + cw / 2, cardTop + i * (ch + gap) + ch / 2);
  // Lane G8: each perk's card cell, price and buys a run can make (Thick Chitin sells three times).
  const ORDER = [['twin', 1, 2000, 1], ['chitin', 0, 2500, 3], ['quick', 2, 3000, 1]];
  const countOf = (list, id) => list.filter((x) => x === id).length;
  let down = false;
  let lastDir = null;
  const steer = async (dx, dy) => {
    const len = Math.hypot(dx, dy) || 1;
    const ux = dx / len;
    const uy = dy / len;
    if (down && lastDir && ux * lastDir.x + uy * lastDir.y < 0.97) {
      await touch('touchEnd', []);
      down = false;
    }
    if (!down) {
      await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 1 }]);
      down = true;
    }
    await touch('touchMove', [{ x: THUMB.x + ux * 60, y: THUMB.y + uy * 60, id: 1 }]);
    lastDir = { x: ux, y: uy };
  };
  const letGo = async () => {
    if (down) await touch('touchEnd', []);
    down = false;
    lastDir = null;
  };
  const heap = () => page.evaluate(() => (performance.memory ? +(performance.memory.usedJSHeapSize / 1048576).toFixed(1) : null));
  const rounds = [];
  const purchases = [];
  let current = null;
  let tick = 0;
  const heapStart = await heap();
  let continued = null;
  let breakSeenAt = null;
  let blessingSeen = null;
  const huntersSeen = { beetle: null, antlion: null, centipede: null, ember: null, moth: null };
  // Slice 4: each boss seen and downed, the speed bands at rounds 4 and 13, every line bought, the ledger by round.
  const bossesSeen = [];
  let bossNow = null;
  const bandSpeeds = {};
  const lineBuys = [];
  const ledgerByRound = [];
  const LINE_ORDER = ['damage', 'rate', 'health', 'speed', 'darts'];
  let lineTurn = 0;
  while (Date.now() - t0 < LONG_MS) {
    tick += 1;
    const s = await snap();
    if (!s) break;
    const t = +((Date.now() - t0) / 1000).toFixed(1);
    if (s.phase === 'title') {
      // A segment after the first opens on the title: Continue brings the saved run back.
      const h = await hudNow();
      if (h && h.title && h.title.shown) {
        await sleep(350);
        await tapAt(gameCss(h.title.cont.x, h.title.cont.y));
        const c = await snap();
        continued = { saved: s.saved, phase: c.phase, round: c.round, level: c.level, nectar: c.nectar, hp: c.hp, owned: c.owned };
        continued.ok = c.phase === 'break' && !!s.saved && c.round === s.saved.round && c.level === s.saved.level;
        log('continued', JSON.stringify(continued));
      }
      await sleep(200);
      continue;
    }
    if (s.phase === 'break') {
      if (breakSeenAt === null) breakSeenAt = Date.now();
      if (stopAfter !== null && s.round >= stopAfter && Date.now() - breakSeenAt > 3000 && s.pending === 0) {
        log('segment ends in the break after round', s.round);
        break;
      }
    } else breakSeenAt = null;
    // Slice 4: every boss has its own shot below; this one stays the Anteater's.
    if (s.boss && s.boss.kind === 'anteater' && !shotNames.has('anteater_long')) await screenshot('anteater_long');
    // Slice 3: the first Queen's Blessing seen and the first sight of each new predator, for the record.
    if (s.blessing && !blessingSeen) {
      blessingSeen = { round: s.round, kind: s.blessing, t };
      log('blessing seen', JSON.stringify(blessingSeen));
      await screenshot('blessing');
    }
    if (s.boss && (!bossNow || bossNow.kind !== s.boss.kind)) {
      bossNow = { kind: s.boss.kind, round: s.round, maxHp: s.boss.maxHp, t, down: null };
      bossesSeen.push(bossNow);
      log('boss seen', JSON.stringify(bossNow));
      if (!shotNames.has(`boss_${s.boss.kind}_long`)) await screenshot(`boss_${s.boss.kind}_long`);
    } else if (!s.boss && bossNow && bossNow.down === null) {
      bossNow.down = { round: s.round, t, phase: s.phase };
      log('boss down', JSON.stringify(bossNow));
      bossNow = null;
    }
    for (const br of [4, 13]) {
      if (s.round === br && s.phase === 'active' && !bandSpeeds[br] && current && t - current.start > 3 && s.alive >= 3) {
        const sp = (await liveSpeeds()).filter((x) => x.kind === 'armyAnt');
        if (sp.length >= 2) bandSpeeds[br] = { n: sp.length, speeds: [...new Set(sp.map((x) => x.speed))].sort((a, b) => a - b), maxV: Math.max(...sp.map((x) => x.v)) };
      }
    }
    for (const hk of ['beetle', 'antlion', 'centipede', 'ember', 'moth']) {
      if (!huntersSeen[hk] && s.hunters && s.hunters.some((x) => x.kind === hk)) {
        huntersSeen[hk] = s.round;
        log('first', hk, 'in round', s.round);
        if (hk !== 'antlion') await screenshot(`${hk}_long`);
      }
    }
    if (s.round >= 26 && s.phase === 'active' && !shotNames.has('round26') && current && t - current.start > 8) await screenshot('round26');
    maxRound = Math.max(maxRound, s.round);
    if (s.moving && down) sawMovingWhileHeld = true;
    if (s.phase === 'active' && (!current || current.round !== s.round)) {
      current = { round: s.round, start: t, end: null, hpStart: s.hp, maxHp: s.maxHp, nectarStart: s.nectar };
      rounds.push(current);
      ledgerByRound.push({ round: s.round, earned: +s.earned.toFixed(1), spent: s.spent, held: +s.nectar.toFixed(1), lines: { ...s.lines } });
      log('round', s.round, 'started at', t, 's, hp', s.hp, '/', s.maxHp, 'nectar', s.nectar, 'owned', s.owned.join(','));
    }
    if (s.phase === 'break') {
      sawBreak = true;
      if (current && current.end === null) {
        current.end = t;
        current.seconds = +(t - current.start).toFixed(1);
        current.hpEnd = s.hp;
        current.nectarEnd = s.nectar;
      }
    }
    if (s.phase === 'dead') {
      if (current && current.end === null) {
        current.end = t;
        current.seconds = +(t - current.start).toFixed(1);
        current.died = true;
      }
      break;
    }
    if (s.pending > 0 && s.offer.length > 0) {
      await letGo();
      await tapPick(0);
      continue;
    }
    if (s.phase === 'active') {
      const rx = s.antX - NEST.x;
      const ry = s.antY - NEST.y;
      const r = Math.hypot(rx, ry) || 1;
      const pull = ((380 - r) / 380) * 1.5;
      if (tick % 6 < 4) await steer(-ry / r + (rx / r) * pull, rx / r + (ry / r) * pull);
      else await letGo();
      if (s.round >= 3 && !frames && current && t - current.start > 5) {
        await letGo();
        await takeSample();
      }
      if (s.round === 6 && !shotNames.has('round6')) await screenshot('round6');
    } else if (s.phase === 'break') {
      if (!s.inNest) await steer(NEST.x - s.antX, NEST.y - s.antY);
      else {
        await letGo();
        // Slice 4: the repeatable lines, in turn, whenever no perk is affordable (a perk buy waits for its price).
        const perkDue = ORDER.some(([id, , price, max]) => countOf(s.owned, id) < max && s.nectar >= price);
        // The first segment keeps its drag test first; a continued segment (all perks maybe owned) buys lines at once.
        if (!perkDue && (dragTest || stateIn)) {
          let boughtLine = false;
          for (let k = 0; k < LINE_ORDER.length && !boughtLine; k++) {
            const id = LINE_ORDER[(lineTurn + k) % LINE_ORDER.length];
            const card = await shopCard(id);
            const price = card ? priceOf(card.price) : null;
            if (!card || price === null || card.price === 'MAX' || /^Opens/.test(card.line) || s.nectar < price) continue;
            await tapAt(gameCss(card.x, card.y), 7);
            await sleep(150);
            const after = await snap();
            const b = { id, round: s.round, t, line: card.line, price, ok: after.lines[id] === s.lines[id] + 1, nectarBefore: +s.nectar.toFixed(1), nectarAfter: +after.nectar.toFixed(1) };
            lineBuys.push(b);
            log('line buy', JSON.stringify(b));
            lineTurn = (lineTurn + k + 1) % LINE_ORDER.length;
            boughtLine = true;
          }
          if (boughtLine) {
            await sleep(200);
            continue;
          }
        }
        for (const [id, i, price, max] of ORDER) {
          if (countOf(s.owned, id) < max && s.nectar >= price) {
            if (!dragTest) {
              // Polish 1: a drag from this card, affordable now, must move the ant and must not buy it.
              dragTest = await dragFromCard(i, s);
              dragTest.price = price;
              dragTest.affordable = s.nectar >= price;
              break;
            }
            const p = cardAt(i);
            await touch('touchStart', [{ x: p.x, y: p.y, id: 2 }]);
            await sleep(60);
            await touch('touchEnd', []);
            await sleep(150);
            const after = await snap();
            const bought = { id, round: s.round, t, ok: countOf(after.owned, id) === countOf(s.owned, id) + 1, nectarBefore: s.nectar, nectarAfter: after.nectar, maxHpAfter: after.maxHp };
            purchases.push(bought);
            log('purchase', JSON.stringify(bought));
            if (!shotNames.has('shop_bought')) await screenshot('shop_bought');
            break;
          }
        }
      }
    }
    await sleep(200);
  }
  await letGo();
  const ledgerEnd = await snap();
  longRun = {
    rounds, purchases, continued, heapStart, heapEnd: await heap(), runSave: await readRunSave(), blessingSeen, huntersSeen,
    bossesSeen, bandSpeeds, lineBuys, ledgerByRound,
    ledgerEnd: ledgerEnd ? { round: ledgerEnd.round, earned: +ledgerEnd.earned.toFixed(1), spent: ledgerEnd.spent, held: +ledgerEnd.nectar.toFixed(1), lines: ledgerEnd.lines } : null,
  };
  const end = await note('long end');
  if (end && end.phase === 'dead') {
    await sleep(700);
    await screenshot('death');
    // The best round must survive a relaunch: reload the page and read it back from storage.
    const recorded = end.record ? end.record.best : null;
    await page.reload({ waitUntil: 'load' });
    await page.waitForFunction(() => window.__antwars && window.__antwars.snapshot() !== null, null, { timeout: 15_000 });
    // The best round lives under its ladder's key (slice 3): Pure keeps the slice 1 key, Colony its own.
    const bestKey = end.ladder === 'colony' ? 'antwars.bestRound.colony.v1' : 'antwars.bestRound.v1';
    const stored = await page.evaluate((key) => {
      try {
        return localStorage.getItem(key);
      } catch {
        return 'unreadable';
      }
    }, bestKey);
    relaunch = { recorded, stored, ok: recorded !== null && stored === String(recorded) };
    log('relaunch', JSON.stringify(relaunch));
  } else await screenshot('long_end');
} else if (growth) {
  // Slice 2 in about 60 s: real kills reach a level up, the pick sheet takes a tap while the Yard holds behind it (lane G9),
  // the ant runs into a rock and stops at its edge, and a reload mid run comes back through Continue.
  await installWatch();
  growthRun = { pick: null, behindSheet: null, rock: null, save: null, resume: null };
  let i = 0;
  while (Date.now() - t0 < 50_000 && !growthRun.pick) {
    const [dx, dy, ms] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, ms);
    if (i === 2) await screenshot('round1_play');
    const end = Date.now() + 1500;
    while (Date.now() < end) {
      const s = await snap();
      if (!s || s.phase === 'dead') break;
      if (s.pending > 0 && s.offer.length > 0) break;
      await sleep(100);
    }
    const s = await note('stood still');
    if (!s || s.phase === 'dead') break;
    if (s.pending > 0) {
      // Lane G9: the Yard holds still behind the sheet until the tap: a held stick moves nothing with the cards up.
      await sleep(700);
      const ra = await yardRead();
      const a = ra.snap;
      const hA = ra.hud;
      await touch('touchStart', [{ x: THUMB.x, y: THUMB.y, id: 1 }]);
      await sleep(40);
      await touch('touchMove', [{ x: THUMB.x, y: THUMB.y - 70, id: 1 }]);
      await sleep(400);
      const rb = await yardRead();
      const b = rb.snap;
      await touch('touchEnd', []);
      await sleep(100);
      growthRun.behindSheet = {
        sheetUp: !!hA && hA.pick.shown,
        frozenA: a.frozen,
        frozenB: b.frozen,
        moved: +Math.hypot(b.antX - a.antX, b.antY - a.antY).toFixed(1),
        yardMsA: a.yardMs,
        yardMsB: b.yardMs,
        sameYard: JSON.stringify(heldState(ra)) === JSON.stringify(heldState(rb)),
        pendingStill: b.pending,
      };
      const bs = growthRun.behindSheet;
      bs.ok = bs.sheetUp && bs.frozenA && bs.frozenB && bs.moved === 0 && bs.yardMsA === bs.yardMsB && bs.sameYard && b.pending > 0;
      log('behind the sheet', JSON.stringify(growthRun.behindSheet));
      await screenshot('pick_sheet');
      growthRun.pick = await tapPick(0);
    }
  }
  if (growthRun.pick) {
    await sleep(300);
    await takeSample();
  }
  await clearPicks();
  growthRun.rock = await hitRock();
  await clearPicks();
  growthRun.save = await waitForSave();
  if (growthRun.save && growthRun.save.ok) {
    growthRun.shopUnderSheet = await shopUnderSheet();
    growthRun.resume = await reloadAndContinue(growthRun.save);
  }
} else if (pauseFlow) {
  // Lane G9 on the phone viewport: play until two real level ups have each held the Yard, then a sheet in a break (the
  // scene's own queuePicks, the path the Royal Jelly pickup takes) shows the countdown standing still.
  await installWatch();
  pauseRun = { sheets: [], breakSheet: null, freezes: [] };
  let i = 0;
  while (Date.now() - t0 < 150_000 && pauseRun.sheets.length < 2) {
    const [dx, dy, ms] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, ms);
    const s = await snap();
    if (!s || s.phase === 'dead') break;
    if (s.pending > 0 && s.offer.length > 0) pauseRun.sheets.push(await holdAndTap(`levelup${pauseRun.sheets.length + 1}`));
  }
  let s = await snap();
  for (let k = 0; k < 120 && s && s.phase !== 'break' && s.phase !== 'dead'; k++) {
    const [dx, dy, ms] = pattern[k % pattern.length];
    await hold(dx, dy, ms);
    await clearPicks();
    s = await snap();
  }
  if (s && s.phase === 'break') {
    await sleep(1200);
    await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      g.queuePicks(1, 'ROYAL JELLY: A FREE PICK');
    });
    await sleep(100);
    // Mute and the save under the sheet: Mute toggles both ways, and the run save follows within half a second (it runs
    // on the scene clock, which a sheet never stops), holding the waiting pick for Continue.
    const mh = await hudNow();
    await tapAt(gameCss(mh.mute.x, mh.mute.y));
    const m1 = await hudNow();
    await tapAt(gameCss(mh.mute.x, mh.mute.y));
    const m2 = await hudNow();
    await sleep(700);
    let saved = null;
    try {
      saved = JSON.parse(await readRunSave());
    } catch {
      saved = null;
    }
    const held = await snap();
    pauseRun.underSheet = { muteOn: m1.mute.muted === true, muteOff: m2.mute.muted === false, savedPending: saved ? saved.pending : null, savedRound: saved ? saved.round : null, held: held.frozen, pending: held.pending };
    pauseRun.underSheet.ok = pauseRun.underSheet.muteOn && pauseRun.underSheet.muteOff && pauseRun.underSheet.savedPending === 1 && held.frozen === true;
    log('under the sheet', JSON.stringify(pauseRun.underSheet));
    // Lane G9c: under the break's cards NEXT ROUND IN stands on the same number with the Yard, and runs on
    // from it after the tap.
    pauseRun.breakSheet = await holdAndTap('break');
    const bsh = pauseRun.breakSheet;
    const shown = (t) => {
      const m = /^NEXT ROUND IN ([0-9]+)$/.exec(t || '');
      return m ? Number(m[1]) : null;
    };
    bsh.numbers = [shown(bsh.a.countdown), shown(bsh.b.countdown), shown(bsh.c.countdown)];
    const [na, nb, nc] = bsh.numbers;
    bsh.ok = bsh.ok && bsh.a.phase === 'break' && bsh.b.phase === 'break' && na !== null && na === nb && bsh.a.breakLeft === bsh.b.breakLeft && bsh.c.breakLeft < bsh.b.breakLeft && nc !== null && nc <= nb && nc >= nb - 3;
    // Lane G9c: with the ant in the nest a buy under the cards is refused, and goes through after the tap.
    pauseRun.buyHeld = await buyUnderSheet();
  }
  pauseRun.freezes = await readFreezes();
  log('pause run', JSON.stringify({ sheets: pauseRun.sheets.map((x) => x.ok), breakSheet: pauseRun.breakSheet ? pauseRun.breakSheet.ok : null, freezes: pauseRun.freezes }));
} else if (statsFlow) {
  statsRun = await runStatsFlow();
} else if (stickFlow) {
  stickRun = await runStickFlow();
} else if (pwaFlow) {
  pwaRun = await runPwa();
} else if (titleFlow) {
  titleRun = await runTitleFlow();
} else if (dailyFlow) {
  dailyResult = await runDaily();
} else if (s4) {
  s4Run =
    s4 === 'boss' ? await runS4Boss() : s4 === 'elements' ? await runS4Elements() : s4 === 'hunters' ? await runS4Hunters() : s4 === 'hornet' ? await runS4Hornet() : s4 === 'pace' ? await runS4Pace() : s4 === 'doublekill' ? await runS4DoubleKill() : s4 === 'fill' ? await runS4Fill() : s4 === 'view' ? await runS4View() : s4 === 'procs' ? await runS4Procs() : s4 === 'numbers' ? await runS4Numbers() : await runS4Econ();
} else if (colonyFlow) {
  colonyRun = await runColonyFlow();
} else if (juiceFlow) {
  juiceRun = await runJuiceFlow();
} else if (startRound && process.env.SMOKE_HUNT) {
  huntRun = await runHunt(process.env.SMOKE_HUNT);
} else if (startRound && process.env.SMOKE_STILL) {
  // VG3 collateral 1: the ant never moves and the round must still clear; a predator sitting on the ant is hit at
  // point blank. Every 250 ms the harness counts predators within 26 units of the ant's centre.
  stillRun = { round: startRound, cleared: false, moved: null, maxOnAnt: 0, samplesWithOnAnt: 0, samples: 0 };
  const s0 = await snap();
  let s = s0;
  const countOnAnt = () =>
    page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      return g.predators.getChildren().filter((p) => p.active && Math.hypot(p.x - g.ant.x, p.y - g.ant.y) < 26).length;
    });
  // The pile VG3 found: once 6 predators are out, the harness sets them on the ant (body.reset, 20 units round it, the
  // spacing their crowd push keeps) and watches whether a still ant clears them. Before the fix none died.
  const pileBy = Date.now() + 15_000;
  while (Date.now() < pileBy && s && s.phase !== 'dead' && !(s.phase === 'active' && s.alive >= 6)) {
    await sleep(100);
    s = await snap();
  }
  if (s && s.phase === 'active' && s.alive >= 6) {
    const placed = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      const live = g.predators.getChildren().filter((p) => p.active).slice(0, 6);
      live.forEach((p, i) => {
        const a = (i * Math.PI) / 3;
        p.body.reset(g.ant.x + Math.cos(a) * 20, g.ant.y + Math.sin(a) * 20);
        p.spawnUntil = 0;
      });
      return live.length;
    });
    const k0 = (await snap()).kills;
    const onAnt0 = await countOnAnt();
    await sleep(2500);
    const k1 = (await snap()).kills;
    const onAnt1 = await countOnAnt();
    stillRun.pile = { placed, onAntAtStart: onAnt0, onAntAfter2500ms: onAnt1, killsIn2500ms: k1 - k0 };
    log('pile on the ant', JSON.stringify(stillRun.pile));
  }
  const end = Date.now() + 50_000;
  while (Date.now() < end && s && s.phase !== 'dead') {
    if (s.pending > 0) await clearPicks();
    await sleep(250);
    s = await note('still');
    const onAnt = await page.evaluate(() => {
      const g = window.__antwars.game.scene.getScene('game');
      return g.predators.getChildren().filter((p) => p.active && Math.hypot(p.x - g.ant.x, p.y - g.ant.y) < 26).length;
    });
    stillRun.samples += 1;
    if (onAnt > 0) stillRun.samplesWithOnAnt += 1;
    stillRun.maxOnAnt = Math.max(stillRun.maxOnAnt, onAnt);
    if (s && s.phase === 'break') break;
  }
  stillRun.cleared = !!s && s.phase === 'break' && s.round === startRound;
  stillRun.moved = s ? +Math.hypot(s.antX - s0.antX, s.antY - s0.antY).toFixed(1) : null;
  stillRun.kills = s ? s.kills : null;
  stillRun.seconds = +((Date.now() - t0) / 1000).toFixed(1);
  log('still', JSON.stringify(stillRun));
  await screenshot('still_cleared');
} else if (startRound && startRound % 25 === 0) {
  // Slice 2, M2: the Anteater round. The ant stands in the nest and shoots; the Anteater walks from the far hole round
  // the rocks to the nest and eats nectar there (the harness gives the run 2,000 nectar to eat). Its big bar shows.
  bossRun = { spawned: false, reached: false };
  // One short step off the nest's middle with the stick, then the ant stands and shoots.
  await hold(70, 0, 500);
  const end = Date.now() + 60_000;
  let s = await snap();
  while (Date.now() < end && s && s.phase !== 'dead' && !s.boss) {
    await sleep(200);
    s = await snap();
  }
  bossRun.spawned = !!s && !!s.boss;
  if (bossRun.spawned) {
    bossRun.first = s.boss;
    await page.evaluate(() => {
      window.__antwars.game.scene.getScene('game').nectar = 2000;
    });
    await sleep(1500);
    await takeSample();
    while (Date.now() < end && s && s.phase !== 'dead' && s.boss && !s.boss.eating) {
      await clearPicks();
      await sleep(250);
      s = await snap();
    }
    bossRun.reached = !!s && !!s.boss && s.boss.eating;
    if (bossRun.reached) {
      const a = await snap();
      await sleep(2200);
      const b = await snap();
      const h = await page.evaluate(() => window.__antwars.game.scene.getScene('hud').bossText.text);
      bossRun.eat = { nectarA: a.nectar, nectarB: b.nectar, eaten: a.nectar - b.nectar, bossAt: a.boss, barText: h, hp: b.boss ? b.boss.hp : null, maxHp: b.boss ? b.boss.maxHp : null };
      await screenshot('anteater');
    }
  }
  // Two gulps of 250 in 2.2 s, less what the ant earns meanwhile (10 a hit, the beads of the termites it kills).
  bossRun.ok = bossRun.spawned && bossRun.reached && !!bossRun.eat && bossRun.eat.eaten >= 250 && /EATING YOUR NECTAR/.test(bossRun.eat.barText) && bossRun.first.maxHp === 87300;
  log('anteater', JSON.stringify(bossRun));
} else if (startRound) {
  let i = 0;
  while (Date.now() - t0 < PRACTICE_MS) {
    const [dx, dy, ms] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, ms);
    // Check for a death before the next press: a press on the death screen is a "tap to play again".
    const held = await note(`held ${dx},${dy} for ${ms} ms`);
    if (!held || held.phase === 'dead') break;
    // Lane G9: a pick sheet now holds the Yard until a tap, so the practice bot takes its picks as the default run does.
    await clearPicks();
    if (i === 3) await screenshot('practice');
    await sleep(1500);
    const s = await note('stood still 1.5 s');
    if (!s || s.phase === 'dead') break;
    if (i === 3 && !frames) await takeSample();
  }
  const s = await note('practice end');
  if (s && s.phase === 'dead') {
    await sleep(700);
    await screenshot('death');
    // PLAY AGAIN (it shows once the 1.2 s guard is over): both scenes restart, a fresh ant at the nest, no title.
    const endGuard = Date.now() + 4000;
    let dh = await hudNow();
    while (Date.now() < endGuard && !(dh && dh.death && dh.death.ready)) {
      await sleep(100);
      dh = await hudNow();
    }
    await tapAt(gameCss(dh.death.again.x, dh.death.again.y), 3);
    await sleep(900);
    const again = await note('after tap to play again');
    restart = {
      tried: true,
      ok: !!again && (again.phase === 'intro' || again.phase === 'active') && again.kills === 0 && again.hp === again.maxHp,
      phase: again?.phase,
      hp: again?.hp,
      kills: again?.kills,
    };
    log('restart', JSON.stringify(restart));
    await screenshot('restarted');
  } else await screenshot('practice_end');
} else {
  // A scripted 30 s and more: hold a direction, stand and shoot, around a loop, until round 2 is under way.
  // First, untouched: round 1 starts with the ant on its spawn in the nest (polish 2: no locked line there).
  spawnCheck = await checkSpawn();
  let i = 0;
  while (Date.now() - t0 < PLAY_LIMIT_MS) {
    const [dx, dy, ms] = pattern[i % pattern.length];
    i += 1;
    await hold(dx, dy, ms);
    const held = await note(`held ${dx},${dy} for ${ms} ms`);
    if (!held || held.phase === 'dead') break;
    if (i === 2) await screenshot('round1_play');
    await sleep(1500);
    await clearPicks();
    const s = await note('stood still 1.5 s');
    if (!s || s.phase === 'dead') break;
    if (s.phase === 'break' && !breakCheck) breakCheck = await checkBreak(s);
    if (s.round >= 2 && s.phase === 'active' && Date.now() - t0 > 30_000) {
      await takeSample();
      await screenshot('round2');
      break;
    }
  }
}
if (startRound && RUSH_EXPECT[startRound]) {
  rushRun = await page.evaluate(() => (window.__g9rush ? { ...window.__g9rush, bites: [...window.__g9rush.bites] } : null));
  const e = RUSH_EXPECT[startRound];
  if (rushRun) {
    rushRun.expect = e;
    rushRun.ok = rushRun.maxLeft === e.total && rushRun.bites.length > 0 && rushRun.bites.every((b) => b === e.bite) && (e.multiShot ? rushRun.termiteHpMax > 1 : rushRun.termiteHpMax === 1);
  }
  log('rush', JSON.stringify(rushRun));
}
if (startRound && PACE_EXPECT[startRound]) {
  const w = await page.evaluate(() => (window.__n1pace ? { ...window.__n1pace, stamps: [...window.__n1pace.stamps] } : null));
  const e = PACE_EXPECT[startRound];
  paceRun = { round: startRound, expect: e, spawned: w ? w.stamps.length : 0, maxAlive: w ? w.maxAlive : null };
  if (w && w.frames > 0) {
    // A boss round spawns its boss first; the gaps that count are its escort's. The first ten gaps come before the
    // crowd reaches the 20 alive cap (where a spawn waits for a kill), so the gap alone sets them.
    const queue = e.kind === 'boss' ? w.stamps.slice(1) : w.stamps;
    const gaps = [];
    for (let i = 1; i < queue.length && gaps.length < 10; i++) gaps.push(+((queue[i].yardMs - queue[i - 1].yardMs) / 1000).toFixed(4));
    const sorted = [...gaps].sort((x, y) => x - y);
    const frameS = w.frameMsSum / w.frames / 1000;
    paceRun.frameMs = +(frameS * 1000).toFixed(2);
    paceRun.boss = e.kind === 'boss' ? (w.stamps[0] ? w.stamps[0].kind : null) : null;
    paceRun.escortKinds = [...new Set(queue.map((x) => x.kind))];
    paceRun.gaps = gaps;
    paceRun.median = sorted.length > 0 ? sorted[Math.floor(sorted.length / 2)] : null;
    // A spawn lands on the first frame its timer runs out: the gap, rounded up to a whole frame (4 ms spare). The gap on
    // 5304e3e sits past the window at every round the lane checks (1.5 s at round 10, 0.27 s and a frame at round 15).
    paceRun.window = [+(e.gap - 0.005).toFixed(4), +(e.gap + frameS + 0.004).toFixed(4)];
    paceRun.ok =
      gaps.length === 10 && paceRun.median >= paceRun.window[0] && paceRun.median <= paceRun.window[1] && w.maxAlive <= 20 &&
      (e.kind !== 'boss' || paceRun.escortKinds.every((k) => k === 'termite'));
  } else paceRun.ok = false;
  log('pace', JSON.stringify(paceRun));
}
if (!frames) await takeSample();
const final = await note('final');
const result = {
  mode,
  url,
  env,
  bootMs,
  seconds: +((Date.now() - t0) / 1000).toFixed(1),
  maxRound,
  sawBreak,
  sawMovingWhileHeld,
  antMovedByThumb: +antMovedByThumb.toFixed(1),
  thumbXFrac: thumbFrac,
  spawnCheck,
  breakCheck,
  dragTest,
  kindsSeen,
  final,
  frames,
  memory,
  consoleErrors: errors,
  consoleWarnings: warnings,
  httpErrors,
  screenshots: shots,
  timeline,
  longRun,
  restart,
  relaunch,
  growthRun,
  titlePass,
  colonyRun,
  huntRun,
  juiceRun,
  s4Run,
  hookWithoutDebug,

  bossRun,
  stillRun,
  picksTaken,
  pwaRun,
  titleRun,
  dailyResult,
  pauseRun,
  rushRun,
  paceRun,
  statsRun,
  stickRun,
};
writeFileSync(path.join(proof, `smoke_${fileTag}.json`), JSON.stringify(result, null, 2));

if (stateOut) {
  await context.storageState({ path: stateOut });
  log('storage state written', stateOut);
}
if (browser) await browser.close();
else await context.close();
if (pwaProfile) rmSync(pwaProfile, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 });
await server.close();

const checks = {
  noConsoleErrors: errors.length === 0,
  noHttpErrors: httpErrors.length === 0,
  frameP95Under20ms: frames.rafDelta.p95 < 20,
  // The stick flow (lane N1, M3) reads the stick and the ant itself (stickBaseStays below) and holds no pattern.
  stickMoves: process.env.SMOKE_STILL || process.env.SMOKE_HUNT || colonyFlow || juiceFlow || s4 || pwaFlow || titleFlow || dailyFlow || stickFlow ? true : sawMovingWhileHeld,

  thumbMovesAnt: long || process.env.SMOKE_STILL || process.env.SMOKE_HUNT || colonyFlow || s4 || pwaFlow || titleFlow || dailyFlow || stickFlow ? true : antMovedByThumb >= 20,
  stillAntClearsRound: process.env.SMOKE_STILL ? !!stillRun && stillRun.cleared && stillRun.moved !== null && stillRun.moved < 2 : true,
  stillAntClearsPile: process.env.SMOKE_STILL ? !!stillRun && !!stillRun.pile && stillRun.pile.onAntAtStart >= 5 && stillRun.pile.onAntAfter2500ms <= 1 : true,
  countdownVisible: mode === 'build' ? !!breakCheck && breakCheck.countdownOk : true,
  countdownRunsInShop: mode === 'build' ? !!breakCheck && breakCheck.runsInShop : true,
  roundStartsAtZero: mode === 'build' ? !!breakCheck && breakCheck.startsAtZero && breakCheck.startedWithShopOpen : true,
  shopLockedInRound: mode === 'build' ? !!breakCheck && breakCheck.lockedOk : true,
  spawnNoLine: mode === 'build' ? !!spawnCheck && spawnCheck.ok : true,
  roundFoundNoLine: mode === 'build' ? !!breakCheck && breakCheck.foundNoLine : true,
  dragFromCardMoves: mode === 'build' ? !!breakCheck && !!breakCheck.cardDrag && breakCheck.cardDrag.ok && breakCheck.backInShop === true : true,
  dragNeverBuys: long && !stateIn ? !!dragTest && dragTest.ok && dragTest.affordable === true : true,
  reached: dev || desktop || colonyFlow || juiceFlow || pwaFlow || titleFlow || statsFlow || stickFlow ? maxRound >= 0 : dailyFlow ? maxRound >= (process.env.SMOKE_DAILY_AGAIN ? 0 : 3) : long ? maxRound >= LONG_TARGET : startRound ? maxRound >= startRound : maxRound >= 2,
  shopBuys: long ? longRun !== null && (stateIn ? true : longRun.purchases.length > 0) && longRun.purchases.every((p) => p.ok) : true,
  restartWorks: restart.tried ? restart.ok === true : true,
  bestSurvivesRelaunch: relaunch ? relaunch.ok === true : true,
  segmentContinued: long && stateIn ? !!longRun && !!longRun.continued && longRun.continued.ok === true : true,
  elites: startRound && startRound >= 8 && startRound % 5 !== 0 && !process.env.SMOKE_HUNT && !s4 ? kindsSeen.wasp + kindsSeen.spider > 0 : true,
  termites: startRound && startRound % 5 === 0 && startRound % 25 !== 0 && !s4 ? kindsSeen.termite > 0 : true,
  levelUpPick: growth ? !!growthRun && !!growthRun.pick && growthRun.pick.ok : true,
  // Lane G9: a sheet holds the Yard until a tap can count (the 300 ms read guard, less a frame), the first one for the
  // whole behind the sheet test (over a second); the Yard stands still behind it.
  sheetHoldsUntilTap: growth ? !!growthRun && Array.isArray(growthRun.freezes) && growthRun.freezes.length > 0 && growthRun.freezes.every((f) => f >= 250) && Math.max(...growthRun.freezes) >= 1000 : true,
  yardHoldsBehindSheet: growth ? !!growthRun && !!growthRun.behindSheet && growthRun.behindSheet.ok : true,
  rushScales: startRound && RUSH_EXPECT[startRound] ? !!rushRun && rushRun.ok === true : true,
  // Lane N1: the round's spawns come at the round plan's gap, never slower than the horde from round 6.
  paceRamp: startRound && PACE_EXPECT[startRound] ? !!paceRun && paceRun.ok === true : true,
  // Lane N1, M2: the stats tab on the phone (runStatsFlow's own checks).
  statsTab: statsFlow ? !!statsRun && statsRun.ok === true : true,
  // Lane N1, M3: the stick's base stays where the first touch landed (runStickFlow's own checks).
  stickBaseStays: stickFlow ? !!stickRun && stickRun.ok === true : true,
  pauseHolds: pauseFlow ? !!pauseRun && pauseRun.sheets.length >= 2 && pauseRun.sheets.every((x) => x.ok) && !!pauseRun.breakSheet && pauseRun.breakSheet.ok && !!pauseRun.underSheet && pauseRun.underSheet.ok : true,
  buyRefusedUnderSheet: pauseFlow ? !!pauseRun && !!pauseRun.buyHeld && pauseRun.buyHeld.ok : true,
  rockBlocks: growth ? !!growthRun && !!growthRun.rock && growthRun.rock.ok : true,
  saveAtBreak: growth ? !!growthRun && !!growthRun.save && growthRun.save.ok : true,
  continueRestores: growth ? !!growthRun && !!growthRun.resume && growthRun.resume.ok : true,
  everyPickApplied: picksTaken.every((p) => p.ok || p.raced === true),
  shopShowsUnderPick: growth ? !!growthRun && !!growthRun.shopUnderSheet && growthRun.shopUnderSheet.ok : true,
  anteaterEatsNectar: startRound && startRound % 25 === 0 ? !!bossRun && bossRun.ok : true,
  debugHookGated: growth ? hookWithoutDebug === 'undefined' : true,
  titlePlays: titlePass ? titlePass.phase !== 'title' : true,
  colonyFlow: colonyFlow ? !!colonyRun && colonyRun.ok === true : true,
  hunter: process.env.SMOKE_HUNT ? !!huntRun && huntRun.ok === true : true,
  juiceAndMute: juiceFlow ? !!juiceRun && juiceRun.ok === true : true,
  slice4: s4 ? !!s4Run && s4Run.ok === true : true,
  longLinesBought: long ? !!longRun && longRun.lineBuys.every((b) => b.ok) : true,
  installableOffline: pwaFlow ? !!pwaRun && pwaRun.ok === true : true,
  titleAndHowTo: titleFlow ? !!titleRun && titleRun.ok === true : true,
  dailyChallenge: dailyFlow ? !!dailyResult && dailyResult.ok === true : true,

};

const pass = Object.values(checks).every(Boolean);
log('RESULT', JSON.stringify({ mode, seconds: result.seconds, maxRound, sawBreak, finalPhase: final?.phase, kindsSeen, errors: errors.length, httpErrors: httpErrors.length, warnings: warnings.length, rafP95: frames.rafDelta.p95, stepMean: frames.stepWork.mean, memory, checks }));
log(pass ? 'VERDICT PASS' : 'VERDICT FAIL');
process.exit(pass ? 0 : 1);
