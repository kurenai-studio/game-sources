// Smoke test: serves dist/, loads the game in Chromium, starts it, checks for errors, saves screenshots.
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright'); // preinstalled globally (CJS resolution)
import http from 'node:http';
import { readFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, extname } from 'node:path';

const types = { '.html': 'text/html', '.js': 'text/javascript' };
const server = http.createServer((req, res) => {
  const p = join('dist', req.url === '/' ? 'index.html' : req.url.split('?')[0]);
  if (!existsSync(p)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'content-type': types[extname(p)] || 'application/octet-stream' });
  res.end(readFileSync(p));
}).listen(8123);

mkdirSync('test/shots', { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
const errors = [];
page.on('pageerror', e => errors.push(e.message));
page.on('console', m => m.type() === 'error' && errors.push(m.text()));
await page.goto('http://localhost:8123/');
await page.waitForTimeout(800);
await page.screenshot({ path: 'test/shots/01-menu.png' });
await page.mouse.click(480, 270);
await page.waitForTimeout(800);
await page.screenshot({ path: 'test/shots/02-game.png' });
const state = await page.evaluate(() => window.__gameState);
await browser.close();
server.close();
console.log('state:', JSON.stringify(state));
if (errors.length) { console.error('ERRORS:\n' + errors.join('\n')); process.exit(1); }
console.log('SMOKE OK');
