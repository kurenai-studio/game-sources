// Plays the game headlessly: perfect play on job 1, sloppy play on job 2. Saves screenshots and fails on JS errors.
import { createRequire } from 'node:module';
import http from 'node:http';
import { readFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, extname } from 'node:path';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const types = { '.html': 'text/html', '.js': 'text/javascript', '.woff2': 'font/woff2' };
const server = http.createServer((req, res) => {
  const p = join('dist', req.url === '/' ? 'index.html' : decodeURIComponent(req.url.split('?')[0]));
  if (!existsSync(p)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'content-type': types[extname(p)] || 'application/octet-stream' });
  res.end(readFileSync(p));
}).listen(8124);

mkdirSync('test/shots', { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
const shot = (n) => page.screenshot({ path: `test/shots/${n}.png` });
const wait = (ms) => page.waitForTimeout(ms);

await page.goto('http://localhost:8124/');
await wait(1800);
await shot('01-title');
await page.keyboard.down('ShiftLeft'); await page.keyboard.down('ShiftRight');
await wait(60);
await page.keyboard.up('ShiftLeft'); await page.keyboard.up('ShiftRight');
await wait(900);

// Reads what shift is needed for the current layer: compare ghost row with the target row.
const needed = () => page.evaluate(() => {
  const s = window.__game.scene.getScene('game');
  if (!s || !s.sys.isActive() || s.phase !== 'align') return null;
  const cur = s.current, tgt = s.target[s.r];
  const fi = (a) => a.indexOf(true);
  return { d: fi(tgt) - fi(cur), r: s.r };
});
const tap = async (code) => { await page.keyboard.down(code); await wait(30); await page.keyboard.up(code); await wait(40); };

async function playJob(sloppy) {
  let lastR = -1;
  for (let guard = 0; guard < 400; guard++) {
    const scene = await page.evaluate(() => window.__gameState?.scene || (window.__game.scene.getScene('game').sys.isActive() ? 'game' : ''));
    const n = await needed();
    if (!n) {
      const res = await page.evaluate(() => window.__game.scene.getScene('results').sys.isActive());
      if (res) return;
      await wait(60); continue;
    }
    if (n.r === lastR) { await wait(60); continue; }
    lastR = n.r;
    let d = n.d;
    if (sloppy && n.r % 3 === 1) d += 2;     // deliberately misalign some layers
    for (let i = 0; i < Math.abs(d); i++) await tap(d < 0 ? 'ShiftLeft' : 'ShiftRight');
    if (n.r === 3 || n.r === 9) await shot((sloppy ? '04-job2-midprint' : '02-job-midprint') + '-' + n.r + '-' + Date.now() % 1000);
    await page.keyboard.down('ShiftLeft'); await page.keyboard.down('ShiftRight');   // drop
    await wait(40);
    await page.keyboard.up('ShiftLeft'); await page.keyboard.up('ShiftRight');
    await wait(100);
  }
  throw new Error('job did not finish');
}


await playJob(false);
await wait(2600);
await shot('03-results-job1');
const r1 = await page.evaluate(() => window.__gameState);
await page.keyboard.down('ShiftLeft'); await page.keyboard.down('ShiftRight'); await wait(50);
await page.keyboard.up('ShiftLeft'); await page.keyboard.up('ShiftRight');
await wait(900);
await playJob(true);
await wait(2600);
await shot('05-results-job2');
const r2 = await page.evaluate(() => window.__gameState);
await page.keyboard.down('ShiftLeft'); await page.keyboard.down('ShiftRight'); await wait(50);
await page.keyboard.up('ShiftLeft'); await page.keyboard.up('ShiftRight');
await wait(900);
await playJob(false);
await wait(2600);
await shot('06-results-job3'); await wait(1500); await shot('07-liftoff');
const r3 = await page.evaluate(() => window.__gameState);
console.log('job3', JSON.stringify(r3));
await browser.close(); server.close();
console.log('job1', JSON.stringify(r1), 'job2', JSON.stringify(r2));
if (errors.length) { console.error('ERRORS:\n' + errors.join('\n')); process.exit(1); }
console.log('PLAY OK');
