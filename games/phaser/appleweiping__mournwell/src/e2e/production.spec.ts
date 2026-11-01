import { expect, test, type Page } from '@playwright/test';

function watchRuntime(page: Page): string[] {
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(`pageerror: ${error.message}`));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(`console: ${message.text()}`);
  });
  page.on('requestfailed', (request) => {
    if (!request.url().startsWith('data:')) {
      errors.push(`requestfailed: ${request.url()} ${request.failure()?.errorText ?? ''}`);
    }
  });
  return errors;
}

test('production artifact starts a real run and exposes no mutation controls', async ({ page }) => {
  const runtimeErrors = watchRuntime(page);
  await page.goto('/');
  await expect(page.locator('#game-title')).toContainText('MOURNWELL');
  const bridge = await page.evaluate(async () => {
    await window.__game.ready();
    return {
      qaControlsEnabled: window.__game.build.qaControlsEnabled,
      hasTestControls: 'test' in window.__game,
      phase: window.__game.getSnapshot().phase,
    };
  });
  expect(bridge).toEqual({ qaControlsEnabled: false, hasTestControls: false, phase: 'menu' });

  await page.locator('#primary-action').click();
  await page.waitForFunction(() => window.__game.getSnapshot().phase === 'running');
  const before = await page.evaluate(() => window.__game.getSnapshot());
  expect(before.dungeon.rooms.length).toBeGreaterThanOrEqual(5);
  expect(before.dungeon.rooms.length).toBeLessThanOrEqual(8);

  await page.keyboard.down('d');
  await page.waitForFunction((startX) => window.__game.getSnapshot().player.x > startX + 20, before.player.x);
  await page.keyboard.up('d');
  await page.keyboard.down('ArrowUp');
  await page.waitForFunction(() => window.__game.getSnapshot().counts.playerProjectiles > 0);
  await page.keyboard.up('ArrowUp');
  expect(runtimeErrors).toEqual([]);
});
