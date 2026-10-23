import { test, expect } from './fixtures.js';
import { PieceColors, continueSavedGame, cellsOf, savedGame } from './helpers.js';

// Audit migration, DECISIONS.md rows D72d and D72e (F28 TE2, Confirmed Defect
// at synthetic scope): in Chromium, a touch lift 60 px from touch-down with no
// move event in between counted as a tap, although the tap rule allows only
// 10 px. The with-move case and a real phone were not part of the finding, and
// WebKit was not run. test.fail marks the test as an expected failure while
// the defect's fix is unapproved; the fix's pull request removes the mark.
// Ported from the audit scratch script d72-F28-TE2-run.mjs; the byte-identical
// original and its checksum live in
// docs/tetris-audit/test-migration-provenance/. Deviations from the original:
// no window.__g hook (the test reads what the page shows, per the owner's
// touch-test choice), the repository's @playwright/test and saved-game
// helpers replace playwright-core and the hand-started server, and rotation
// is detected by the piece's rendered shape instead of counting rotate
// actions inside the app.

test.skip(({ browserName, hasTouch }) => browserName !== 'chromium' || !hasTouch, 'simulated touch runs on the Chromium phone project only');

const minColumn = cells => Math.min(...cells.map(([, c]) => c));
const minRow = cells => Math.min(...cells.map(([r]) => r));
// Normalized shape: translation by gravity does not change it, rotation does.
const shapeOf = cells => {
  const r0 = minRow(cells);
  const c0 = minColumn(cells);
  return JSON.stringify(cells.map(([r, c]) => [r - r0, c - c0]).sort());
};

test('a touch lift far from touch-down with no move event is not a tap [INP-5]', async ({ page }) => {
  test.fail(true, 'F28 TE2 (D72d, D72e): Chromium counts a 60 px touch lift with no move event as a tap; the fix PR removes this mark');
  await continueSavedGame(page, savedGame({ piece: PieceColors.purple, position: { row: 5, column: 3 } }));
  await page.keyboard.press('KeyP');

  const first = shapeOf(await cellsOf(page, PieceColors.purple));
  const box = await page.locator('#tetris').boundingBox();
  const cx = box.x + box.width / 2, cy = box.y + box.height / 2;

  // Real touch down through the DevTools Protocol, no move event, then a
  // synthetic pointerup 60 px away: the TE2 sequence from the finding.
  const cdp = await page.context().newCDPSession(page);
  // Trial-D variant: reuse the pointer id the browser assigns to the real touch-down.
  await page.evaluate(() => document.getElementById('tetris').addEventListener('pointerdown', (e) => { window.__downId = e.pointerId; }, { once: true }));
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: cx, y: cy, id: 1 }] });
  await page.evaluate(({ x, y }) => {
    document.getElementById('tetris').dispatchEvent(new PointerEvent('pointerup', { pointerId: window.__downId, pointerType: 'touch', clientX: x + 60, clientY: y, bubbles: true }));
  }, { x: cx, y: cy });

  await page.waitForTimeout(300);
  const after = shapeOf(await cellsOf(page, PieceColors.purple));
  if (after !== first) {
    console.log('KNOWN DEFECT STILL PRESENT: F28 TE2 (D72d, D72e) - the 60 px lift with no move event counted as a tap and rotated the piece');
  }
  expect(after).toBe(first);
});
