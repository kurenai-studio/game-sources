// Visual QA capture for Sky Isles. Not part of the build.
// Starts a vite dev server (unless one is already on :4182), then screenshots
// desktop + mobile views of the key vistas into shots/.
import { chromium, devices } from '@playwright/test';
import { spawn } from 'node:child_process';
import { mkdirSync } from 'node:fs';

const PORT = 4185;
const PAGE_URL = `http://127.0.0.1:${PORT}/`;
const OUT = new URL('../shots/', import.meta.url).pathname;
mkdirSync(OUT, { recursive: true });

async function serverUp() {
  try {
    const res = await fetch(PAGE_URL);
    return res.ok;
  } catch {
    return false;
  }
}

let server = null;
if (!(await serverUp())) {
  server = spawn('npx', ['vite', '--port', String(PORT), '--strictPort'], {
    cwd: new URL('..', import.meta.url).pathname,
    stdio: 'ignore'
  });
  for (let i = 0; i < 60; i++) {
    await new Promise((r) => setTimeout(r, 1000));
    if (await serverUp()) break;
  }
}

const VIEWS = [
  {
    name: 'desktop-home.png',
    context: { viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 },
    spot: { pos: [0, 0.5, 3.5], orbit: [Math.PI, 0.32, 10] }
  },
  {
    name: 'mobile-home.png',
    context: { ...devices['iPhone 15 Pro Max'] },
    spot: { pos: [0, 0.5, 3.5], orbit: [-1.08, 0.58, 9] }
  },
  {
    name: 'desktop-tree.png',
    context: { viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 },
    spot: { pos: [26, 5.5, -14], orbit: [2.4, 0.3, 11] }
  },
  {
    name: 'desktop-temple.png',
    context: { viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 },
    spot: { pos: [-24, 10.5, -20], orbit: [0.6, 0.35, 12] }
  },
  {
    name: 'desktop-koi-waterfall.png',
    context: { viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 },
    // camera sits beyond the lip, slightly raised, looking back at the isle
    // so the full ribbon is framed against the cloud sea
    spot: { pos: [14, 8.5, 23.5], orbit: [-1.17, 0.35, 13] }
  },
  {
    name: 'desktop-bonus-stars.png',
    context: { viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 },
    spot: { pos: [1.5, 90.6, 1.5], orbit: [2.6, 0.25, 8], unlock: true }
  }
];

let failed = false;
for (const view of VIEWS) {
  const browser = await chromium.launch();
  const context = await browser.newContext(view.context);
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (err) => errors.push(String(err)));
  page.on('console', (msg) => { if (msg.type() === 'error') errors.push(msg.text()); });

  await page.goto(PAGE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.__skyisles && window.__skyisles.getState, null, { timeout: 60_000 });
  await page.evaluate((spot) => {
    const S = window.__skyisles;
    S.start();
    if (spot.unlock) {
      for (const idx of S.getState().muralOrder) S.playChime(idx);
      const s = S.getState();
      S.teleport(s.portalPos.x, s.portalPos.y, s.portalPos.z);
    } else {
      S.teleport(...spot.pos);
    }
    S.setOrbit(...spot.orbit);
  }, view.spot);
  await page.waitForTimeout(2500);
  await page.screenshot({ path: OUT + view.name });
  console.log(JSON.stringify({ shot: view.name, errors }));
  if (errors.length) failed = true;
  await browser.close();
}

if (server) server.kill();
if (failed) process.exitCode = 1;
