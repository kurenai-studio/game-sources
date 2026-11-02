// Regression: a Shift whose keyup never arrives (macOS/Windows do this when both Shifts are down)
// must not turn the next single Shift press into a drop.
import { createRequire } from 'node:module';
import http from 'node:http';
import { readFileSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.woff2': 'font/woff2' };
const server = http.createServer((req, res) => {
  const p = join('dist', req.url === '/' ? 'index.html' : req.url.split('?')[0]);
  if (!existsSync(p)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'content-type': types[extname(p)] || 'application/octet-stream' }); res.end(readFileSync(p));
}).listen(8126);
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
const wait = (ms) => page.waitForTimeout(ms);
await page.goto('http://localhost:8126/');
await wait(1500);
await page.keyboard.press('Enter');
await page.waitForFunction(() => { const s = window.__game.scene.getScene('game'); return s.sys.isActive() && s.current && s.phase === 'align'; }, null, { timeout: 20000 });
await wait(300);
const state = () => page.evaluate(() => { const s = window.__game.scene.getScene('game'); return { r: s.r, phase: s.phase, cur: s.current.map(Number).join('') }; });
const s0 = await state();
// chord drop where the left Shift keyup is "lost": left stays down
await page.keyboard.down('ShiftLeft'); await page.keyboard.down('ShiftRight'); await wait(30); await page.keyboard.up('ShiftRight');
await page.waitForFunction((r0) => { const s = window.__game.scene.getScene('game'); return s.r === r0 + 1 && s.phase === 'align'; }, s0.r, { timeout: 20000 });
await wait(150);
const s1 = await state();
await page.keyboard.down('ShiftRight'); await wait(20); await page.keyboard.up('ShiftRight');   // single right Shift
await wait(100);
const s2 = await state();
await browser.close(); server.close();
console.log(JSON.stringify({ s0, s1, s2 }));
const ok = s1.r === s0.r + 1 && s2.r === s1.r && s2.phase === 'align' && s2.cur !== s1.cur;
console.log(ok ? 'STUCK-SHIFT OK' : 'STUCK-SHIFT FAIL');
process.exit(ok ? 0 : 1);
