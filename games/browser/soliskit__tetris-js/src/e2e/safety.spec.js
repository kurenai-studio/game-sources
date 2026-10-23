// Fault injection in the real page: corrupted saves, drawing errors and
// blocked storage must never crash or freeze the game.

import { test, expect } from './fixtures.js';
import { expectLabel, filledCount, savedGame, PieceColors, trackErrors } from './helpers.js';

const good = savedGame({ piece: PieceColors.purple });
const broken = {
  'text that is not JSON': '{"gameBoard": [',
  'a save missing its upcoming pieces': JSON.stringify({ ...JSON.parse(good['tetris.savedGameSession']), nextTetrominos: undefined }),
  'a save with the piece inside locked blocks': (() => {
    const data = JSON.parse(good['tetris.savedGameSession']);
    data.gameBoard[1][4] = { isFilled: true, color: PieceColors.red };
    return JSON.stringify(data);
  })()
};

for (const [name, text] of Object.entries(broken)) {
  test(`continuing ${name} is refused and New Game still works [SAF-1]`, async ({ page }) => {
    const errors = trackErrors(page);
    await page.addInitScript(value => {
      if (sessionStorage.getItem('seeded')) return;
      sessionStorage.setItem('seeded', '1');
      localStorage.setItem('tetris.isSessionSaved', 'true');
      localStorage.setItem('tetris.savedGameSession', value);
    }, text);
    await page.goto('/');
    await expect(page.locator('#continueGameButton')).toBeVisible();
    await page.locator('#continueGameButton').click();
    await expect(page.locator('#continueGameButton')).toBeHidden();
    await expect(page.locator('#newGameButton')).toBeVisible();
    await page.locator('#newGameButton').click();
    await expectLabel(page, 'Pause');
    await expect.poll(() => filledCount(page)).toBe(4);
    expect(errors).toEqual([]);
  });
}

test('an error while drawing does not stop the game from drawing [SAF-5]', async ({ page }) => {
  const logged = [];
  page.on('console', message => { if (message.type() === 'error') logged.push(message.text()); });
  await page.addInitScript(() => {
    const fill = CanvasRenderingContext2D.prototype.fill;
    window.failNextDraw = false;
    CanvasRenderingContext2D.prototype.fill = function (...args) {
      if (window.failNextDraw) {
        window.failNextDraw = false;
        throw new Error('injected drawing failure');
      }
      return fill.apply(this, args);
    };
  });
  await page.goto('/');
  await page.keyboard.press('Enter');
  await expect.poll(() => filledCount(page)).toBe(4);
  await page.evaluate(() => { window.failNextDraw = true; });
  await page.keyboard.press('Space');
  await expect.poll(() => filledCount(page)).toBe(8);
  expect(logged.filter(text => text.includes('Tetris drawing error'))).toHaveLength(1);
});

test('the game plays normally when storage is blocked [SAF-2]', async ({ page }) => {
  const errors = trackErrors(page);
  await page.addInitScript(() => {
    Storage.prototype.getItem = () => { throw new DOMException('blocked', 'SecurityError'); };
    Storage.prototype.setItem = () => { throw new DOMException('full', 'QuotaExceededError'); };
  });
  await page.goto('/');
  await page.keyboard.press('Enter');
  await expectLabel(page, 'Pause');
  for (let i = 0; i < 3; i++) await page.keyboard.press('Space');
  await expect.poll(() => filledCount(page)).toBe(16);
  await page.keyboard.press('KeyP');
  await expectLabel(page, 'Resume');
  await page.keyboard.press('KeyP');
  await expectLabel(page, 'Pause');
  expect(errors).toEqual([]);
});
