import { test, expect } from './fixtures.js';
import { BOARD_COLOR, PieceColors, boardTouch, canvasHasDrawing, cellsOf, continueSavedGame, isChromium, rowsExcept, savedGame } from './helpers.js';

test.skip(({ hasTouch }) => !hasTouch, 'touch gestures run on the phone sized project');

const minColumn = cells => Math.min(...cells.map(([, c]) => c));
const minRow = cells => Math.min(...cells.map(([r]) => r));
const shapeOf = cells => {
  const r0 = minRow(cells);
  const c0 = minColumn(cells);
  return JSON.stringify(cells.map(([r, c]) => [r - r0, c - c0]).sort());
};

async function playSaved(page, options) {
  await continueSavedGame(page, savedGame(options));
  await page.keyboard.press('KeyP');
}

test('tapping the board rotates the piece, even with a little finger wobble [INP-5]', async ({ page }) => {
  await playSaved(page, { piece: PieceColors.purple, position: { row: 5, column: 3 } });
  const touch = await boardTouch(page);
  const t = () => cellsOf(page, PieceColors.purple);
  const first = shapeOf(await t());
  await touch.down(5, 15);
  await touch.up();
  await expect.poll(async () => shapeOf(await t())).not.toBe(first);
  const second = shapeOf(await t());
  await touch.down(5, 15);
  await touch.moveBy(6 / touch.cell, 3 / touch.cell, 2); // about 6px of wobble
  await touch.up();
  await expect.poll(async () => shapeOf(await t())).not.toBe(second);
});

// Use native mouse pointer events for exact CSS-pixel coordinates on both
// engines. The existing gesture tests separately exercise Chromium touch.
for (const { name, distances, rotates, cancel = false } of [
  { name: 'below 10 pixels', distances: [9], rotates: true },
  { name: 'exactly 10 pixels', distances: [10], rotates: true },
  { name: 'above 10 pixels', distances: [11], rotates: false },
  { name: 'exactly 10 pixels and back', distances: [10, 0], rotates: true },
  { name: 'beyond 10 pixels and back', distances: [11, 0], rotates: false },
  { name: 'cancelled at exactly 10 pixels', distances: [10], rotates: false, cancel: true }
]) {
  test(`a pointer gesture ${name} preserves the tap boundary [INP-5]`, async ({ page }) => {
    await playSaved(page, { piece: PieceColors.purple, position: { row: 5, column: 3 } });
    const first = shapeOf(await cellsOf(page, PieceColors.purple));
    const box = await page.locator('#tetris').boundingBox();
    const start = { x: Math.round(box.x + box.width / 2), y: Math.round(box.y + box.height / 2) };
    await page.evaluate(() => {
      window.boundaryEvents = [];
      const board = document.getElementById('tetris');
      for (const type of ['pointerdown', 'pointermove']) {
        board.addEventListener(type, event => {
          window.boundaryEvents.push({ type, x: event.clientX, y: event.clientY, pointerId: event.pointerId });
        });
      }
    });
    await page.mouse.move(start.x, start.y);
    await page.mouse.down();
    for (const distance of distances) await page.mouse.move(start.x + distance, start.y);
    const delivered = await page.evaluate(() => {
      const down = window.boundaryEvents.find(event => event.type === 'pointerdown');
      return window.boundaryEvents.filter(event => event.type === 'pointermove' && event.pointerId === down.pointerId)
        .filter(event => window.boundaryEvents.indexOf(event) > window.boundaryEvents.indexOf(down))
        .map(event => Math.hypot(event.x - down.x, event.y - down.y));
    });
    expect(delivered).toEqual(distances);
    // Movement alone must not rotate. This also proves the boundary move
    // reached the page before the up/cancel event.
    expect(shapeOf(await cellsOf(page, PieceColors.purple))).toBe(first);
    if (cancel) {
      const pointerId = await page.evaluate(() => window.boundaryEvents.find(event => event.type === 'pointerdown').pointerId);
      await page.locator('#tetris').dispatchEvent('pointercancel', { pointerId });
    }
    await page.mouse.up();
    if (rotates) await expect.poll(async () => shapeOf(await cellsOf(page, PieceColors.purple))).not.toBe(first);
    else expect(shapeOf(await cellsOf(page, PieceColors.purple))).toBe(first);
  });
}

test('tapping the hold box holds the piece [INP-5] [PLY-7]', async ({ page }) => {
  await playSaved(page, { piece: PieceColors.purple });
  await page.locator('#heldPreview').tap();
  await expect.poll(() => canvasHasDrawing(page, 'heldPreview')).toBe(true);
});

test('dragging sideways moves one column per cell dragged [INP-5]', async ({ page }) => {
  await playSaved(page, { piece: PieceColors.purple, position: { row: 5, column: 3 } });
  const touch = await boardTouch(page);
  await touch.down(4, 12);
  await touch.moveBy(2.6, 0, 13);
  await expect.poll(async () => minColumn(await cellsOf(page, PieceColors.purple))).toBe(6);
  await touch.moveBy(-2.6, 0, 13);
  await expect.poll(async () => minColumn(await cellsOf(page, PieceColors.purple))).toBe(3);
  await touch.up();
});

test('dragging down soft drops one row per cell dragged [INP-5] [PLY-3]', async ({ page }) => {
  await playSaved(page, { piece: PieceColors.purple, position: { row: 2, column: 3 } });
  const touch = await boardTouch(page);
  await touch.down(4, 8);
  await touch.moveBy(0, 3.2, 12);
  await expect.poll(async () => minRow(await cellsOf(page, PieceColors.purple))).toBeGreaterThanOrEqual(5);
  await touch.up();
});

test('a dragged piece is never drawn over locked blocks [INP-5] [PCE-6]', async ({ page }) => {
  await playSaved(page, {
    piece: PieceColors.yellow,
    position: { row: 6, column: 4 },
    board: rowsExcept([...Array(16).keys()].map(i => i + 4), [0, 1, 2, 3, 4, 5])
  });
  const touch = await boardTouch(page);
  await touch.down(5, 7);
  await touch.moveBy(1.4, 0, 7);
  const rightEdge = await page.evaluate(() => {
    const canvas = document.getElementById('tetris');
    const size = canvas.width / 10;
    const pixels = canvas.getContext('2d').getImageData(0, Math.floor(size * 7.5), canvas.width, 1).data;
    let last = -1;
    for (let x = 0; x < canvas.width; x++) {
      const [r, g, b] = pixels.slice(x * 4, x * 4 + 3);
      if (r > 200 && g > 170 && b < 90) last = x;
    }
    return last / size;
  });
  expect(rightEdge).toBeLessThanOrEqual(6);
  expect(await cellsOf(page, BOARD_COLOR)).toHaveLength(64);
  await touch.up();
});

test('after pushing into a wall, dragging back responds within a cell [INP-5]', async ({ page }) => {
  await playSaved(page, {
    piece: PieceColors.yellow,
    position: { row: 6, column: 4 },
    board: rowsExcept([...Array(16).keys()].map(i => i + 4), [0, 1, 2, 3, 4, 5])
  });
  const touch = await boardTouch(page);
  await touch.down(5, 7);
  await touch.moveBy(3, 0, 15); // three cells into the wall
  expect(minColumn(await cellsOf(page, PieceColors.yellow))).toBe(4);
  await touch.moveBy(-0.6, 0, 3);
  await expect.poll(async () => minColumn(await cellsOf(page, PieceColors.yellow))).toBe(3);
  await touch.up();
});

test('a drag that outlives its piece leaves the next piece alone [INP-5]', async ({ page }) => {
  await playSaved(page, { piece: PieceColors.purple, position: { row: 17, column: 3 } });
  const touch = await boardTouch(page);
  await touch.down(4, 10);
  await touch.moveBy(0, 1.2, 3); // onto the floor
  await expect.poll(async () => (await cellsOf(page, PieceColors.purple)).filter(([r]) => r < 4).length, { timeout: 3000 }).toBe(4);
  const topPiece = async () => (await cellsOf(page, PieceColors.purple)).filter(([r]) => r < 6);
  const spawned = await topPiece();
  await touch.moveBy(3, 5, 10); // would move it 3 columns and drop it 5 rows
  await page.waitForTimeout(100);
  const after = await topPiece();
  expect(after).toHaveLength(4);
  expect(minColumn(after)).toBe(minColumn(spawned));
  expect(minRow(after) - minRow(spawned)).toBeLessThanOrEqual(1); // at most one gravity step
  await touch.up();
});

test('a piece pushed against a ledge slides in once it drops below it [INP-5]', async ({ page }) => {
  await playSaved(page, {
    piece: PieceColors.yellow,
    position: { row: 2, column: 4 },
    board: rowsExcept([0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5]) // a ledge in columns 6 to 9
  });
  const touch = await boardTouch(page);
  await touch.down(5, 4);
  await touch.moveBy(1.4, 0, 7); // pushes into the ledge: blocked
  expect(minColumn(await cellsOf(page, PieceColors.yellow))).toBe(4);
  await touch.moveBy(0, 5, 10); // soft drop below the ledge
  await touch.moveBy(0.2, 0, 1); // still pushing right
  await expect.poll(async () => minColumn(await cellsOf(page, PieceColors.yellow))).toBe(5);
  await touch.up();
});

async function centerOf(page, selector) {
  const box = await page.locator(selector).boundingBox();
  return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
}

// Safari zooms on a double tap that lands on something it does not take to be
// clickable, which only click and mouse button listeners make an element.
test('the board listens for clicks, so Safari takes quick taps there as clicks rather than a double tap to zoom [DSP-4]', async ({ page }) => {
  test.skip(!isChromium(page), 'only Chromium can send real touch events');
  await page.addInitScript(() => {
    window.listenedFor = [];
    const addEventListener = EventTarget.prototype.addEventListener;
    EventTarget.prototype.addEventListener = function (type, ...rest) {
      window.listenedFor.push(`${this.id ?? ''} ${type}`);
      return addEventListener.call(this, type, ...rest);
    };
  });
  await page.goto('/');
  expect(await page.evaluate(() => window.listenedFor)).toContain('tetris click');
  // Clickable, it would otherwise flash on every tap.
  expect(await page.evaluate(() => getComputedStyle(document.getElementById('tetris')).webkitTapHighlightColor)).toBe('rgba(0, 0, 0, 0)');
});

test('two quick taps turn the piece twice, and no more [INP-5] [DSP-4]', async ({ page }) => {
  test.skip(!isChromium(page), 'only Chromium can send real touch events');
  await playSaved(page, { piece: PieceColors.purple, position: { row: 5, column: 3 } });
  const board = await centerOf(page, '#tetris');
  await page.touchscreen.tap(board.x, board.y);
  await page.touchscreen.tap(board.x, board.y);
  // Turned twice, the T points down.
  const pointingDown = shapeOf([[0, 0], [0, 1], [0, 2], [1, 1]]);
  await expect.poll(async () => shapeOf(await cellsOf(page, PieceColors.purple))).toBe(pointingDown);
  // The click that follows each tap, a moment later, turns it no further.
  await page.waitForTimeout(500);
  expect(shapeOf(await cellsOf(page, PieceColors.purple))).toBe(pointingDown);
});

test('a quick tap on the hold box right after one on the board still holds [INP-5] [PLY-7]', async ({ page }) => {
  test.skip(!isChromium(page), 'only Chromium can send real touch events');
  await playSaved(page, { piece: PieceColors.purple });
  const board = await centerOf(page, '#tetris');
  const held = await centerOf(page, '#heldPreview');
  await page.touchscreen.tap(board.x, board.y);
  await page.touchscreen.tap(held.x, held.y);
  await expect.poll(() => canvasHasDrawing(page, 'heldPreview')).toBe(true);
});

test('if Safari zooms in anyway, its gestures are let through so the player can zoom back out [DSP-4]', async ({ page }) => {
  await page.goto('/');
  // No test browser here really zooms (Chromium ignores a simulated pinch or
  // double tap), so Safari zooming in is stood in for by the scale the page reads.
  await page.evaluate(() => {
    let scale = 1;
    Object.defineProperty(visualViewport, 'scale', { get: () => scale, configurable: true });
    window.zoomTo = value => {
      scale = value;
      visualViewport.dispatchEvent(new Event('resize'));
    };
  });
  const zoomState = () => page.evaluate(() => {
    const gesture = new Event('gesturestart', { cancelable: true });
    document.dispatchEvent(gesture);
    return {
      htmlTouchAction: getComputedStyle(document.documentElement).touchAction,
      boardTouchAction: getComputedStyle(document.getElementById('tetris')).touchAction,
      pinchCancelled: gesture.defaultPrevented
    };
  });
  await page.evaluate(() => window.zoomTo(2));
  expect(await zoomState()).toEqual({ htmlTouchAction: 'auto', boardTouchAction: 'auto', pinchCancelled: false });
  // Zoomed back out, zooming is blocked again.
  await page.evaluate(() => window.zoomTo(1));
  expect(await zoomState()).toEqual({ htmlTouchAction: 'none', boardTouchAction: 'none', pinchCancelled: true });
});

test('a page that opens already zoomed in, as Safari keeps the zoom on reload, lets the player zoom back out [DSP-4]', async ({ page }) => {
  // Stands in for Safari's restored zoom, as no test browser here really zooms.
  // No resize event comes, so the page has to notice the zoom as it starts.
  await page.addInitScript(() => {
    Object.defineProperty(visualViewport, 'scale', { get: () => 2, configurable: true });
    visualViewport.addEventListener = () => {};
  });
  await page.goto('/');
  expect(await page.evaluate(() => {
    const gesture = new Event('gesturestart', { cancelable: true });
    document.dispatchEvent(gesture);
    return { zoomed: document.documentElement.classList.contains('zoomed'), pinchCancelled: gesture.defaultPrevented };
  })).toEqual({ zoomed: true, pinchCancelled: false });
});
