// Observe the real page and guard with test-only access to its private manager.
// No test hook is shipped to players.
import { test, expect } from './fixtures.js';
import { savedGame, PieceColors } from './helpers.js';

const cause = 'The game stopped because of an internal error.';

async function openPage(page) {
  await page.route('**/script.js', async route => {
    const response = await route.fetch();
    await route.fulfill({ response, body: `${await response.text()}\nwindow.testGame = gameManager;` });
  });
  await page.goto('/');
  await page.waitForFunction(() => window.testGame);
  await page.evaluate(() => new Promise(requestAnimationFrame));
}

async function fault(page, options = {}) {
  return page.evaluate(options => {
    const game = window.testGame;
    if (options.startBeforeDraw) game.handleAction('newGame');
    if (options.frozenRecord) Object.freeze(game.faults);
    if (options.cappedRecord) game.faults.push(...Array.from({ length: 20 }, () => ({ reason: 'earlier' })));
    const report = console.error;
    const draw = window.requestAnimationFrame;
    if (options.refuseConsole) console.error = () => { throw new Error('report refused'); };
    if (options.refuseDraw) window.requestAnimationFrame = callback => {
      window.requestAnimationFrame = draw;
      throw new Error('draw refused');
    };
    try {
      game.guard(() => { throw new Error('injected engine failure'); });
    } finally {
      console.error = report;
      window.requestAnimationFrame = draw;
    }
    return { state: game.state, faults: game.faults.map(f => f.reason), gravity: game.gameLoopTask, lock: game.lockDelayTask };
  }, options);
}

async function expectCause(page) {
  await expect(page.locator('#gameOverMessage')).toBeVisible();
  await expect(page.locator('#gameOverMessage')).toHaveText(cause);
  await expect(page.locator('#gameOverMessage')).toHaveAttribute('aria-hidden', 'true');
  await expect(page.locator('#announcer')).toHaveAttribute('role', 'status');
  await expect(page.locator('#announcer')).toHaveText(cause);
}

for (const timing of ['after playing draw', 'before playing draw']) {
  test(`engine fault ${timing} explains the stop and preserves reports [SAF-3] [F25]`, async ({ page }, testInfo) => {
    const reports = [];
    page.on('console', message => { if (message.type() === 'error') reports.push(message.text()); });
    await openPage(page);
    if (timing === 'after playing draw') {
      await page.locator('#newGameButton').click();
      await expect(page.locator('#playPauseButton')).toBeVisible();
    }
    const result = await fault(page, { startBeforeDraw: timing === 'before playing draw' });
    expect(result.state).toBe('gameOver');
    expect(result.gravity).toBeNull();
    expect(result.lock).toBeNull();
    expect(result.faults).toContain('unexpected error');
    expect(reports.some(text => text.includes('Tetris stopped safely: unexpected error Error: injected engine failure'))).toBe(true);
    await expectCause(page);
    await page.screenshot({ path: testInfo.outputPath('engine-fault.png') });
  });
}

for (const recovery of ['reset throws', 'timer registration throws', 'Continue missing', 'Continue refused', 'Continue read fails', 'Continue load throws']) {
  test(`${recovery} does not clear the engine fault notice [SAF-3]`, async ({ page }) => {
    await openPage(page);
    await fault(page);
    await page.evaluate(recovery => {
      const game = window.testGame;
      if (recovery === 'reset throws') game.resetGameSession = () => { throw new Error('reset failed'); };
      if (recovery === 'timer registration throws') game.scheduler.setTimeout = () => { throw new Error('registration failed'); };
      if (recovery === 'Continue load throws') game.loadGameSession = () => { throw new Error('load failed'); };
      if (recovery === 'Continue refused') {
        localStorage.setItem('tetris.isSessionSaved', 'true');
        localStorage.setItem('tetris.savedGameSession', 'not JSON');
        game.storageChanged();
      }
      if (recovery === 'Continue read fails') game.storage.getItem = () => { throw new Error('read failed'); };
      game.handleAction(recovery.startsWith('Continue') ? 'continueGame' : 'newGame');
    }, recovery);
    await expectCause(page);
  });
}

for (const recovery of ['New Game', 'Continue']) {
  test(`completed ${recovery} clears the old engine fault notice [SAF-3]`, async ({ page }) => {
    await openPage(page);
    await fault(page);
    await expectCause(page);
    await page.evaluate(({ recovery, saved }) => {
      const game = window.testGame;
      if (recovery === 'Continue') {
        for (const [key, value] of Object.entries(saved)) localStorage.setItem(key, value);
        game.storageChanged();
      }
      game.handleAction(recovery === 'Continue' ? 'continueGame' : 'newGame');
    }, { recovery, saved: savedGame({ piece: PieceColors.purple }) });
    await expect(page.locator('#gameOverMessage')).toBeHidden();
    await expect(page.locator('#announcer')).toHaveText('');
    expect(await page.evaluate(() => window.testGame.state)).toBe(recovery === 'Continue' ? 'paused' : 'playing');
  });
}

for (const option of ['cappedRecord', 'frozenRecord', 'refuseConsole', 'refuseDraw']) {
  test(`${option} keeps independent notice and report attempts [SAF-3]`, async ({ page }) => {
    const reports = [];
    page.on('console', message => { if (message.type() === 'error') reports.push(message.text()); });
    await openPage(page);
    const result = await fault(page, { [option]: true });
    expect(result.state).toBe('gameOver');
    if (option !== 'frozenRecord') expect(result.faults).toContain('unexpected error');
    if (option !== 'refuseConsole') expect(reports.some(text => text.includes('Tetris stopped safely:'))).toBe(true);
    // If requesting a frame was refused, a resize is the independent retry.
    if (option === 'refuseDraw') await page.setViewportSize({ width: 420, height: 900 });
    await expectCause(page);
    await page.evaluate(() => window.testGame.handleAction('newGame'));
    await expect(page.locator('#gameOverMessage')).toBeHidden();
  });
}

test('repeated fault-over checks keep one notice without repeated announcements [SAF-3]', async ({ page }) => {
  await openPage(page);
  await fault(page);
  await expectCause(page);
  await page.evaluate(() => {
    window.announcementChanges = 0;
    new MutationObserver(records => { window.announcementChanges += records.length; })
      .observe(document.getElementById('announcer'), { childList: true });
  });
  for (let i = 0; i < 3; i++) {
    await fault(page);
    await page.evaluate(() => new Promise(requestAnimationFrame));
  }
  await expectCause(page);
  expect(await page.evaluate(() => window.announcementChanges)).toBe(0);
  await expect(page.locator('#gameOverMessage')).toHaveCount(1);
});
