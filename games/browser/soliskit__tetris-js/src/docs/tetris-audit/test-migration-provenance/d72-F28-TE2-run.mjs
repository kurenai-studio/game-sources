import { chromium } from 'playwright-core';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', args: ['--no-sandbox'], headless: true });
async function open() { const ctx = await browser.newContext({ serviceWorkers: 'block', viewport: { width: 430, height: 932 }, deviceScaleFactor: 2, hasTouch: true }); const page = await ctx.newPage(); await page.goto('http://localhost:4181/'); await page.waitForFunction(() => window.__g); await sleep(400); const cdp = await ctx.newCDPSession(page); await page.evaluate(() => { window.__g.handleAction('newGame'); window.__g.stopGameLoop(); }); await sleep(300); return { ctx, page, cdp }; }
const touch = (cdp, type, pts) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map(([x, y, id]) => ({ x, y, id })) });
const rot = page => page.evaluate(() => JSON.stringify(window.__g.currentTetromino.rotation ?? window.__g.currentTetromino.rotationState ?? window.__g.currentTetromino.position));
const state = page => page.evaluate(() => { const t = window.__g.currentTetromino; return JSON.stringify({ kind: t.kind ?? t.type, rot: t.rotation ?? t.rotationState ?? t.orientation, pos: t.position, shapeKey: JSON.stringify(t.shape ?? t.cells ?? '') .slice(0,60) }); });
const rect = await (async () => { const { page } = await open(); return page.evaluate(() => { const r = document.getElementById('tetris').getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height }; }); })();
const cx = rect.x + rect.w / 2, cy = rect.y + rect.h / 2;
console.log('board rect', JSON.stringify(rect));
// pick a piece that rotates visibly: force a T by checking state change over rotate action in each case
async function trial(label, fn) {
  const { ctx, page, cdp } = await open();
  await page.evaluate(() => { window.__rotCount = 0; const o = window.__g.handleAction.bind(window.__g); window.__g.handleAction = a => { if (a === 'rotate') window.__rotCount++; return o(a); }; });
  const before = await state(page); await fn(page, cdp); await sleep(200);
  const n = await page.evaluate(() => window.__rotCount); console.log(label, '-> rotate actions:', n); await ctx.close(); return n;
}
await trial('A control: CDP touchStart then touchEnd at the same point (a tap)', async (p, c) => { await touch(c, 'touchStart', [[cx, cy, 1]]); await touch(c, 'touchEnd', []); });
await trial('B control: CDP touchStart, touchMove 60 px right, touchEnd (a drag)', async (p, c) => { await touch(c, 'touchStart', [[cx, cy, 1]]); await touch(c, 'touchMove', [[cx + 60, cy, 1]]); await touch(c, 'touchEnd', []); });
await trial('C TE2 case: touchStart, NO move, pointerup dispatched 60 px away (synthetic)', async (p, c) => { await touch(c, 'touchStart', [[cx, cy, 1]]); await p.evaluate(({ x, y }) => { const el = document.getElementById('tetris'); el.dispatchEvent(new PointerEvent('pointerup', { pointerId: 1, pointerType: 'touch', clientX: x + 60, clientY: y, bubbles: true })); }, { x: cx, y: cy }); });
await trial('D: pointerId check - same as C but pointerId read from the real pointerdown', async (p, c) => { await p.evaluate(() => { window.__pid = null; document.getElementById('tetris').addEventListener('pointerdown', e => { window.__pid = e.pointerId; }, true); }); await touch(c, 'touchStart', [[cx, cy, 1]]); await sleep(100); await p.evaluate(({ x, y }) => { const el = document.getElementById('tetris'); el.dispatchEvent(new PointerEvent('pointerup', { pointerId: window.__pid, pointerType: 'touch', clientX: x + 60, clientY: y, bubbles: true })); }, { x: cx, y: cy }); });
await browser.close();
