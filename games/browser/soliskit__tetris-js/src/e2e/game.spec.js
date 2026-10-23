import { test, expect } from './fixtures.js';
import {
  BOARD_COLOR,
  PieceColors,
  boardCells,
  canvasHasDrawing,
  cellsOf,
  continueSavedGame,
  expectLabel,
  filledCount,
  isChromium,
  rowsExcept,
  savedGame
} from './helpers.js';

// Shape of a set of cells, independent of where it is on the board.
function shapeOf(cells) {
  const minRow = Math.min(...cells.map(([r]) => r));
  const minColumn = Math.min(...cells.map(([, c]) => c));
  return JSON.stringify(cells.map(([r, c]) => [r - minRow, c - minColumn]).sort());
}
const minColumn = cells => Math.min(...cells.map(([, c]) => c));
const minRow = cells => Math.min(...cells.map(([r]) => r));

test.describe('start and game over', () => {
  test('the start screen offers New Game on an empty board, with no pieces and no Game Over [STA-1] [DSP-5] [DSP-8]', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('#newGameButton')).toBeVisible();
    await expect(page.locator('#continueGameButton')).toBeHidden();
    await expect(page.locator('#keyHint')).toHaveText('Return: New Game');
    await expect(page.locator('#playPauseButton')).toBeHidden();
    await expect(page.locator('#gameOverMessage')).toBeHidden();
    await expect(page.locator('#announcer')).toHaveAttribute('role', 'status');
    await expect(page.locator('#announcer')).toHaveText('');
    await expect(page.locator('#score')).toHaveText('Score: 0');
    await expect(page.locator('#highScore')).toHaveText('High Score: 0');
    expect(await canvasHasDrawing(page, 'tetris')).toBe(false);
    for (const id of ['heldPreview', 'next0', 'next1', 'next2']) expect(await canvasHasDrawing(page, id), id).toBe(false);
  });

  test('the New Game button starts a game with a piece at the top [STA-1] [PCE-3] [PLY-8] [DSP-5]', async ({ page }) => {
    await page.goto('/');
    await page.locator('#newGameButton').click();
    await expect(page.locator('#menuControls')).toBeHidden();
    await expect(page.locator('#playPauseButton')).toBeVisible();
    await expectLabel(page, 'Pause');
    await expect.poll(() => filledCount(page)).toBe(4);
    const cells = (await boardCells(page)).flatMap((row, r) => row.map((value, c) => value && [r, c]).filter(Boolean));
    expect(cells).toHaveLength(4);
    expect(minRow(cells)).toBeLessThanOrEqual(1);
    await expect.poll(() => canvasHasDrawing(page, 'next0')).toBe(true);
    expect(await canvasHasDrawing(page, 'heldPreview')).toBe(false);
  });

  test('topping out ends the game and forgets the saved game [STA-3] [DSP-5]', async ({ page }) => {
    await continueSavedGame(page, savedGame({ piece: PieceColors.yellow, board: rowsExcept([...Array(18).keys()].map(i => i + 2), [0]) }));
    await page.keyboard.press('KeyP');
    await page.keyboard.press('Space'); // locks at the top, the next piece has no room
    await expect(page.locator('#newGameButton')).toBeVisible();
    await expect(page.locator('#playPauseButton')).toBeHidden();
    await expect(page.locator('#continueGameButton')).toBeHidden();
    await expect(page.locator('#keyHint')).toHaveText('Return: New Game');
    await page.keyboard.press('Enter');
    await expect(page.locator('#playPauseButton')).toBeVisible();
    await expect.poll(() => filledCount(page)).toBe(4);
  });

  test('at game over only the locked blocks show, under Game Over, until a new game starts [DSP-8] [STA-3]', async ({ page }) => {
    // The O piece locks at the top left; the next one has no room, as (1, 4) is taken.
    await continueSavedGame(page, savedGame({
      piece: PieceColors.yellow,
      board: [[1, 4], ...rowsExcept([...Array(18).keys()].map(i => i + 2), [9])],
      position: { row: 0, column: 0 }
    }));
    await page.keyboard.press('KeyP');
    await page.keyboard.press('Space');
    await expect(page.locator('#gameOverMessage')).toBeVisible();
    await expect(page.locator('#gameOverMessage')).toHaveText('Game Over');
    // Screen readers hear it from the status message, not the overlay.
    await expect(page.locator('#announcer')).toHaveText('Game Over');
    await expect(page.locator('#gameOverMessage')).toHaveAttribute('aria-hidden', 'true');
    // 18 rows of 9, the block at (1, 4) and the locked O: the piece with no room is not drawn over them.
    await expect.poll(() => filledCount(page)).toBe(18 * 9 + 1 + 4);
    for (const id of ['heldPreview', 'next0', 'next1', 'next2']) expect(await canvasHasDrawing(page, id), id).toBe(false);
    await page.keyboard.press('Enter');
    await expect(page.locator('#gameOverMessage')).toBeHidden();
    await expect(page.locator('#announcer')).toHaveText('');
    await expect.poll(() => filledCount(page)).toBe(4);
    await expect.poll(() => canvasHasDrawing(page, 'next0')).toBe(true);
  });

  test('New Game on the pause screen asks first, then gives up the game and starts another [STA-1] [DSP-5] [INP-1]', async ({ page }) => {
    const dialog = page.locator('#newGameDialog');
    const cancel = page.locator('#cancelNewGameButton');
    const confirm = page.locator('#confirmNewGameButton');
    await continueSavedGame(page, savedGame({ piece: PieceColors.purple, score: 300 }));
    await expect(page.locator('#score')).toHaveText('Score: 300');
    await expect(page.locator('#newGameButton')).toBeVisible();
    await expect(page.locator('#continueGameButton')).toBeHidden();
    await expect(page.locator('#keyHint')).toHaveText('Return: New Game    P: Resume');
    await expect(page.locator('#gameOverMessage')).toBeHidden();
    await expect(dialog).toBeHidden();
    await page.locator('#newGameButton').click();
    // It asks first, with Cancel focused, so a second Enter keeps the game.
    await expect(dialog).toBeVisible();
    await expect(dialog).toHaveAttribute('role', 'alertdialog');
    await expect(dialog).toHaveAccessibleName('Start a new game?');
    await expect(dialog).toHaveAccessibleDescription('This game will be lost.');
    await expect(cancel).toBeFocused();
    await expect(page.locator('#score')).toHaveText('Score: 300');
    await confirm.click();
    await expect(dialog).toBeHidden();
    await expectLabel(page, 'Pause');
    await expect(page.locator('#score')).toHaveText('Score: 0');
    await expect(page.locator('#menuControls')).toBeHidden();
    await expect.poll(() => filledCount(page)).toBe(4);
    // Enter asks too, and every way of closing the question but New Game keeps the game.
    await page.keyboard.press('KeyP');
    await expectLabel(page, 'Resume');
    const kept = await boardCells(page);
    for (const [how, answer] of [
      ['Enter on Cancel', () => page.keyboard.press('Enter')],
      ['Cancel', () => cancel.click()],
      ['Escape', () => page.keyboard.press('Escape')],
      ['a click outside it', () => page.mouse.click(5, 5)],
      ['a close request from the browser, such as the back gesture', () => dialog.evaluate(element => element.dispatchEvent(new Event('cancel', { cancelable: true })))]
    ]) {
      await page.keyboard.press('Enter');
      await expect(dialog, how).toBeVisible();
      await expect(cancel, how).toBeFocused();
      await answer();
      await expect(dialog, how).toBeHidden();
      await expectLabel(page, 'Resume');
      expect(await boardCells(page), how).toEqual(kept);
    }
    // The arrow keys move between the buttons, and the selected one is always highlighted.
    await page.keyboard.press('Enter');
    await expect(dialog).toBeVisible();
    await expect(cancel).toHaveCSS('outline-style', 'solid');
    await page.keyboard.press('ArrowRight');
    await expect(confirm).toBeFocused();
    await expect(confirm).toHaveCSS('outline-style', 'solid');
    await page.keyboard.press('ArrowLeft');
    await expect(cancel).toBeFocused();
    // Enter on New Game gives the game up.
    await page.keyboard.press('ArrowRight');
    await page.keyboard.press('Enter');
    await expect(dialog).toBeHidden();
    await expectLabel(page, 'Pause');
  });

  test('with a controller, left and right move between the New Game dialog\'s buttons, A presses the selected one and B cancels [INP-4] [STA-1]', async ({ page }) => {
    // A standard mapping controller the test presses buttons on.
    await page.addInitScript(() => {
      const pad = { connected: true, buttons: Array.from({ length: 16 }, () => ({ pressed: false })), axes: [0, 0] };
      Object.defineProperty(window, 'testPad', { value: pad });
      Object.defineProperty(navigator, 'getGamepads', { value: () => [pad], configurable: true });
    });
    const frames = () => page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    const push = async button => {
      await page.evaluate(index => { window.testPad.buttons[index].pressed = true; }, button);
      await frames();
      await page.evaluate(index => { window.testPad.buttons[index].pressed = false; }, button);
      await frames();
    };
    const [A, B, VIEW, LEFT, RIGHT] = [0, 1, 8, 14, 15];
    const dialog = page.locator('#newGameDialog');
    const cancel = page.locator('#cancelNewGameButton');
    const confirm = page.locator('#confirmNewGameButton');
    await continueSavedGame(page, savedGame({ piece: PieceColors.purple, score: 300 }));
    const kept = await boardCells(page);
    // A presses Cancel, selected and highlighted as the dialog opens.
    await push(VIEW);
    await expect(dialog).toBeVisible();
    await expect(cancel).toBeFocused();
    await expect(cancel).toHaveCSS('outline-style', 'solid');
    await push(RIGHT);
    await expect(confirm).toBeFocused();
    await push(LEFT);
    await expect(cancel).toBeFocused();
    await push(A);
    await expect(dialog).toBeHidden();
    await expectLabel(page, 'Resume');
    expect(await boardCells(page)).toEqual(kept);
    // B cancels whichever is selected.
    await push(VIEW);
    await push(RIGHT);
    await expect(confirm).toBeFocused();
    await push(B);
    await expect(dialog).toBeHidden();
    await expectLabel(page, 'Resume');
    // With none selected, A presses nothing, and a move selects Cancel.
    await push(VIEW);
    await expect(dialog).toBeVisible();
    await cancel.evaluate(button => button.blur());
    await push(A);
    await expect(dialog).toBeVisible();
    await push(RIGHT);
    await expect(cancel).toBeFocused();
    // A on New Game gives the game up.
    await push(RIGHT);
    await expect(confirm).toBeFocused();
    await push(A);
    await expect(dialog).toBeHidden();
    await expectLabel(page, 'Pause');
    await expect(page.locator('#score')).toHaveText('Score: 0');
  });
});

test.describe('playing with the keyboard', () => {
  test('the hold box is a button that Tab reaches, and with keyboard focus Enter or Space hold while playing [INP-6] [PLY-7]', async ({ page }) => {
    test.skip(!isChromium(page), 'Safari only moves focus to buttons with Tab when its settings ask it to');
    const hold = page.locator('#heldPreview');
    const leftmostColumn = async () => Math.min(...(await boardCells(page)).flatMap(row => row.flatMap((value, column) => (value ? [column] : []))));
    await page.goto('/');
    await expect(hold).toHaveAttribute('role', 'button');
    await expect(hold).toHaveAttribute('aria-label', 'Hold');
    await expect(hold).toHaveAttribute('aria-keyshortcuts', 'H');
    await page.keyboard.press('Enter');
    await expect.poll(() => filledCount(page)).toBe(4);
    await page.keyboard.press('Tab');
    await expect(hold).toBeFocused();
    await page.keyboard.press('Enter');
    await expect.poll(() => canvasHasDrawing(page, 'heldPreview')).toBe(true);
    // Space holds too, here a second hold that does nothing, rather than a hard drop that would lock a piece.
    await page.keyboard.press('Space');
    await page.waitForTimeout(300);
    expect(await filledCount(page)).toBe(4);
    // Other keys keep their game actions.
    const column = await leftmostColumn();
    await page.keyboard.press('ArrowLeft');
    await expect.poll(leftmostColumn).toBe(column - 1);
    // Hold only works while playing, so on the pause screen Enter still asks for a new game.
    await page.keyboard.press('KeyP');
    await expect(hold).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page.locator('#newGameDialog')).toBeVisible();
  });

  test('clicked with a mouse, the hold box holds and Space still hard drops [INP-6] [INP-3] [PLY-7]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    await expect.poll(() => filledCount(page)).toBe(4);
    await page.locator('#heldPreview').click();
    await expect.poll(() => canvasHasDrawing(page, 'heldPreview')).toBe(true);
    await expect(page.locator('#heldPreview')).not.toBeFocused();
    await page.keyboard.press('Space');
    await expect.poll(() => filledCount(page)).toBe(8);
  });

  test('Enter and Space on the focused hold box are kept from the browser\'s default action [INP-3] [INP-6]', async ({ page }) => {
    test.skip(!isChromium(page), 'Safari only moves focus to buttons with Tab when its settings ask it to');
    const hold = page.locator('#heldPreview');
    await page.goto('/');
    await page.keyboard.press('Enter');
    await expect.poll(() => filledCount(page)).toBe(4);
    await page.keyboard.press('Tab');
    await expect(hold).toBeFocused();
    // Listening after the game, on the hold box itself, sees what the game did with each key.
    await hold.evaluate(canvas => {
      window.holdKeys = [];
      canvas.addEventListener('keydown', event => window.holdKeys.push([event.key, event.defaultPrevented]));
    });
    await page.keyboard.press('Enter');
    await page.keyboard.press('Space');
    expect(await page.evaluate(() => window.holdKeys)).toEqual([['Enter', true], [' ', true]]);
  });

  test('a click inside the New Game dialog, away from its buttons, keeps the question open [STA-1]', async ({ page }) => {
    const dialog = page.locator('#newGameDialog');
    await continueSavedGame(page, savedGame({ piece: PieceColors.purple, score: 300 }));
    const kept = await boardCells(page);
    await page.keyboard.press('Enter');
    await expect(dialog).toBeVisible();
    // On the question, and on the padding around the dialog's content,
    // halfway down, clear of the rounded corners, which are outside it.
    await page.locator('#newGameQuestion').click();
    const content = page.locator('.dialog-content');
    const { height } = await content.boundingBox();
    await content.click({ position: { x: 10, y: height / 2 } });
    await page.waitForTimeout(300);
    await expect(dialog).toBeVisible();
    await expectLabel(page, 'Resume');
    expect(await boardCells(page)).toEqual(kept);
  });

  test('gravity moves the piece down, and pause stops it [PLY-2] [STA-2] [INP-1]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    await expect.poll(() => filledCount(page)).toBe(4);
    const piece = async () => (await boardCells(page)).flatMap((row, r) => row.map((value, c) => value && [r, c]).filter(Boolean));
    const start = minRow(await piece());
    await expect.poll(async () => minRow(await piece()), { timeout: 3000 }).toBeGreaterThan(start);
    await page.keyboard.press('KeyP');
    await expectLabel(page, 'Resume');
    const paused = await boardCells(page);
    await page.waitForTimeout(1500);
    expect(await boardCells(page)).toEqual(paused);
    await page.keyboard.press('Escape');
    await expectLabel(page, 'Pause');
  });

  test('move, rotate, soft drop, hard drop and hold keys all work [INP-1] [PLY-1] [PLY-3] [PLY-4] [PLY-7]', async ({ page }) => {
    await continueSavedGame(page, savedGame({ piece: PieceColors.purple }));
    await page.keyboard.press('KeyP');
    const t = () => cellsOf(page, PieceColors.purple);
    expect(minColumn(await t())).toBe(3);
    await page.keyboard.press('ArrowLeft');
    await expect.poll(async () => minColumn(await t())).toBe(2);
    await page.keyboard.press('KeyD');
    await expect.poll(async () => minColumn(await t())).toBe(3);
    await page.keyboard.press('KeyA');
    await expect.poll(async () => minColumn(await t())).toBe(2);
    await page.keyboard.press('ArrowRight');
    await expect.poll(async () => minColumn(await t())).toBe(3);

    const before = shapeOf(await t());
    await page.keyboard.press('KeyW');
    await expect.poll(async () => shapeOf(await t())).not.toBe(before);
    await page.keyboard.press('KeyZ'); // back the other way
    await expect.poll(async () => shapeOf(await t())).toBe(before);
    await page.keyboard.press('ArrowUp');

    // Held down, the piece falls five rows within 1.4s, where gravity's row
    // every 0.7s manages three at most. Checked often, so the key is let go
    // long before the piece reaches the floor, however slow the browser.
    const top = minRow(await t());
    await page.keyboard.down('ArrowDown');
    await expect.poll(async () => minRow(await t()), { timeout: 1400, intervals: [25] }).toBeGreaterThanOrEqual(top + 5);
    await page.keyboard.up('ArrowDown');
    expect(await t()).toHaveLength(4);

    await page.keyboard.press('Space'); // hard drop
    await expect.poll(async () => (await t()).length).toBe(8);
    expect((await t()).filter(([r]) => r >= 17)).toHaveLength(4);

    await page.keyboard.press('KeyH');
    await expect.poll(() => canvasHasDrawing(page, 'heldPreview')).toBe(true);
  });

  test('Space hard drops even when an on screen button has focus, and does not press it [INP-1] [INP-3]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    await expect.poll(() => filledCount(page)).toBe(4);
    await page.locator('#playPauseButton').focus();
    await page.keyboard.press('Space');
    await expect.poll(() => filledCount(page)).toBe(8);
    await page.waitForTimeout(300);
    expect(await page.locator('#playPauseButton').getAttribute('aria-label')).toBe('Pause');
  });

  test('clearing a line updates the score and high score [SCO-1] [SCO-3] [DSP-5]', async ({ page }) => {
    await continueSavedGame(page, savedGame({
      piece: PieceColors.cyan,
      rotationState: 1,
      position: { row: 0, column: 7 }, // vertical in column 9
      board: rowsExcept([19], [9])
    }));
    await page.keyboard.press('KeyP');
    await page.keyboard.press('Space');
    await expect(page.locator('#score')).toHaveText('Score: 100');
    await expect(page.locator('#highScore')).toHaveText('High Score: 100');
    expect(await cellsOf(page, BOARD_COLOR)).toHaveLength(0);
  });

  test('a paused game can be continued after reloading the page [STA-4] [DSP-5]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    await page.keyboard.press('Space');
    await page.keyboard.press('KeyP');
    await expectLabel(page, 'Resume');
    const board = await boardCells(page);
    await page.reload();
    await expect(page.locator('#continueGameButton')).toBeVisible();
    await expect(page.locator('#keyHint')).toContainText('C: Continue');
    await page.locator('#continueGameButton').click();
    await expectLabel(page, 'Resume');
    await expect.poll(() => boardCells(page)).toEqual(board);
    await page.locator('#playPauseButton').click();
    await expectLabel(page, 'Pause');
  });

  test('a game paused in another tab can be continued here [STA-4] [DSP-5]', async ({ page, context }) => {
    await page.goto('/');
    await expect(page.locator('#continueGameButton')).toBeHidden();
    const otherTab = await context.newPage();
    await otherTab.goto('/');
    await otherTab.keyboard.press('Enter');
    await otherTab.keyboard.press('Space');
    await otherTab.keyboard.press('KeyP');
    await expectLabel(otherTab, 'Resume');
    const board = await boardCells(otherTab);
    await expect(page.locator('#continueGameButton')).toBeVisible();
    await expect(page.locator('#keyHint')).toContainText('C: Continue');
    await page.locator('#continueGameButton').click();
    await expectLabel(page, 'Resume');
    await expect.poll(() => boardCells(page)).toEqual(board);
  });

  test('a high score set in another tab shows here too [DSP-5] [SCO-3]', async ({ page, context }) => {
    await page.goto('/');
    await expect(page.locator('#highScore')).toHaveText('High Score: 0');
    const otherTab = await context.newPage();
    await otherTab.goto('/');
    await otherTab.evaluate(() => localStorage.setItem('tetris.highScore', '4200'));
    await expect(page.locator('#highScore')).toHaveText('High Score: 4200');
  });

  test('hiding the page pauses the game [STA-5]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    await expectLabel(page, 'Pause');
    await page.evaluate(() => {
      Object.defineProperty(document, 'visibilityState', { value: 'hidden', configurable: true });
      document.dispatchEvent(new Event('visibilitychange'));
    });
    await expectLabel(page, 'Resume');
  });
});

test.describe('layout', () => {
  async function checkFits(page) {
    const layout = await page.evaluate(() => {
      const board = document.getElementById('tetris').getBoundingClientRect();
      const pause = document.getElementById('playPauseButton').getBoundingClientRect();
      const held = document.getElementById('heldPreview').getBoundingClientRect();
      return {
        scrollHeight: document.documentElement.scrollHeight,
        scrollWidth: document.documentElement.scrollWidth,
        width: innerWidth,
        height: innerHeight,
        ratio: board.height / board.width,
        pauseBottom: pause.bottom,
        heldTop: held.top,
        boardWidth: board.width
      };
    });
    expect(layout.scrollHeight).toBeLessThanOrEqual(layout.height);
    expect(layout.scrollWidth).toBeLessThanOrEqual(layout.width);
    expect(layout.pauseBottom).toBeLessThanOrEqual(layout.height);
    expect(layout.heldTop).toBeGreaterThanOrEqual(0);
    expect(layout.ratio).toBeCloseTo(2, 1);
    expect(layout.boardWidth).toBeGreaterThan(150);
  }

  test('the game fits the screen without scrolling [DSP-1] [APP-4]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    await checkFits(page);
  });

  test('the game fits other portrait phone sizes too [DSP-1]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    for (const size of [{ width: 375, height: 667 }, { width: 390, height: 844 }, { width: 430, height: 839 }]) {
      await page.setViewportSize(size);
      await checkFits(page);
    }
  });

  test('the board keeps one size at the start, while playing, paused and at game over [DSP-1]', async ({ page }) => {
    const boardSize = () => page.evaluate(() => {
      const { width, height } = document.getElementById('tetris').getBoundingClientRect();
      return { width, height };
    });
    await page.goto('/');
    const start = await boardSize();
    await page.keyboard.press('Enter');
    await expectLabel(page, 'Pause');
    expect(await boardSize()).toEqual(start);
    await page.keyboard.press('KeyP');
    await expectLabel(page, 'Resume');
    expect(await boardSize()).toEqual(start);
    await page.keyboard.press('KeyP');
    for (let i = 0; i < 30 && !(await page.locator('#gameOverMessage').isVisible()); i++) await page.keyboard.press('Space');
    await expect(page.locator('#gameOverMessage')).toBeVisible();
    expect(await boardSize()).toEqual(start);
  });

  test('the board canvas is drawn at full screen resolution [DSP-2]', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Enter');
    await expect.poll(() => page.evaluate(() => {
      const canvas = document.getElementById('tetris');
      return canvas.width === Math.round(canvas.getBoundingClientRect().width * devicePixelRatio);
    })).toBe(true);
  });
});
