import { expect, test, type Page } from '@playwright/test';

function watchRuntime(page: Page): string[] {
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(`pageerror: ${error.message}`));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(`console: ${message.text()}`);
  });
  page.on('requestfailed', (request) => {
    if (!request.url().startsWith('data:'))
      errors.push(`requestfailed: ${request.url()} ${request.failure()?.errorText ?? ''}`);
  });
  return errors;
}

async function waitForGame(page: Page): Promise<void> {
  await page.waitForFunction(() => window.__game?.getSnapshot().phase === 'running');
}

test.describe('desktop playable flow', () => {
  test.beforeEach(({ isMobile }) => {
    test.skip(isMobile, 'Desktop-only scenario');
  });

  test('real keyboard input shoots, damages, kills, and opens the chamber', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1');
    await expect(page.locator('#game-title')).toContainText('MOURNWELL');
    await page.locator('#primary-action').click();
    await waitForGame(page);

    const initialX = await page.evaluate(() => window.__game.getSnapshot().player.x);
    await page.keyboard.down('d');
    await page.waitForFunction((startX) => window.__game.getSnapshot().player.x > startX + 25, initialX);
    await page.keyboard.up('d');
    const movedX = await page.evaluate(() => window.__game.getSnapshot().player.x);
    expect(movedX).toBeGreaterThan(initialX + 25);

    await page.keyboard.press('Escape');
    await page.waitForFunction(() => window.__game.getSnapshot().phase === 'paused');
    const pausedAt = await page.evaluate(() => window.__game.getSnapshot().run.elapsedMs);
    await page.waitForTimeout(220);
    expect(await page.evaluate(() => window.__game.getSnapshot().run.elapsedMs)).toBe(pausedAt);
    await page.keyboard.press('p');
    await page.waitForFunction(() => window.__game.getSnapshot().phase === 'running');

    await page.evaluate(() => window.__game.test?.reset({ seed: 'E2E-SHOT-0001', fixture: 'single-enemy' }));
    await waitForGame(page);
    await page.keyboard.down('ArrowRight');
    await page.waitForFunction(() => window.__game.getSnapshot().counts.playerProjectiles > 0);
    await page.waitForFunction(() => window.__game.getSnapshot().run.kills === 1);
    await page.keyboard.up('ArrowRight');
    await page.waitForFunction(() => window.__game.getSnapshot().room.doorsOpen);
    const snapshot = await page.evaluate(() => window.__game.getSnapshot());
    expect(snapshot.counts.enemies).toBe(0);
    expect(snapshot.run.damageDealt).toBeGreaterThanOrEqual(18);
    expect(snapshot.room.cleared).toBe(true);
    expect(runtimeErrors).toEqual([]);
  });

  test('a real movement pickup changes inventory, HUD, and combat attributes', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1');
    await page.evaluate(() => window.__game.test?.reset({ seed: 'E2E-LOOT-0002', fixture: 'loot' }));
    await waitForGame(page);
    const before = await page.evaluate(() => window.__game.getSnapshot());
    await page.keyboard.down('d');
    await page.waitForFunction(() =>
      window.__game.getSnapshot().inventory.some((item) => item.id === 'iron-lament'),
    );
    await page.keyboard.up('d');
    const after = await page.evaluate(() => window.__game.getSnapshot());
    expect(after.summary.attributes.attack).toBeGreaterThan(before.summary.attributes.attack);
    await expect(page.locator('#inventory')).toContainText('Iron Lament');
    await expect(page.locator('#stats')).toContainText(after.summary.attributes.attack.toFixed(1));
    expect(runtimeErrors).toEqual([]);
  });

  test('death and boss victory both reach their complete result flows', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1');
    await page.evaluate(() => window.__game.test?.reset({ seed: 'E2E-DEATH-0003', fixture: 'death' }));
    await waitForGame(page);
    await page.evaluate(() => window.__game.test?.damagePlayer(20));
    await page.waitForFunction(() => window.__game.getSnapshot().phase === 'dead');
    await expect(page.locator('#result-overlay')).toBeVisible();
    await expect(page.locator('#result-title')).toContainText('vessel broke');
    await page.locator('#menu-button').click();
    await page.waitForFunction(() => window.__game.getSnapshot().phase === 'menu');

    await page.evaluate(() => window.__game.test?.reset({ seed: 'EMBER-CENSUS-17', fixture: 'boss' }));
    await waitForGame(page);
    await page.keyboard.down('ArrowRight');
    await page.waitForFunction(() => window.__game.getSnapshot().phase === 'victory', null, {
      timeout: 8_000,
    });
    await page.keyboard.up('ArrowRight');
    await expect(page.locator('#result-overlay')).toBeVisible();
    await expect(page.locator('#result-title')).toContainText('Silence');
    await expect(page.locator('#toast')).toHaveClass(/is-hidden/, { timeout: 4_000 });
    await page.screenshot({
      path: test.info().outputPath('demo-victory.png'),
      fullPage: true,
    });
    expect(runtimeErrors).toEqual([]);
  });

  test('the toll bell trades resolve for a burst that clears a weak chamber', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1');
    await page.evaluate(() => window.__game.test?.reset({ seed: 'E2E-BELL-0005', fixture: 'single-enemy' }));
    await waitForGame(page);
    const before = await page.evaluate(() => window.__game.getSnapshot());
    expect(before.counts.enemies).toBe(1);
    expect(before.bell.ready).toBe(true);
    await page.keyboard.press('Space');
    await page.waitForFunction(() => window.__game.getSnapshot().run.kills === 1);
    const after = await page.evaluate(() => window.__game.getSnapshot());
    expect(after.bell.tolls).toBe(1);
    expect(after.summary.hp).toBe(before.summary.hp - before.bell.cost);
    expect(after.bell.readyInMs).toBeGreaterThan(0);
    await expect(page.locator('#bell-button')).toContainText('s');
    // a second press during the cooldown does nothing
    await page.keyboard.press('Space');
    await page.waitForTimeout(150);
    const again = await page.evaluate(() => window.__game.getSnapshot());
    expect(again.bell.tolls).toBe(1);
    expect(again.summary.hp).toBe(after.summary.hp);
    await page.waitForFunction(() => window.__game.getSnapshot().room.doorsOpen);
    expect(runtimeErrors).toEqual([]);
  });

  test('unpausing and restarting in the same frame keeps the game loop alive', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1');
    await page.evaluate(() => window.__game.test?.reset({ seed: 'E2E-RACE-0007', fixture: 'single-enemy' }));
    await waitForGame(page);
    await page.evaluate(async () => {
      await window.__game.test?.pause();
      void window.__game.test?.resume();
      await window.__game.test?.reset({ seed: 'E2E-RACE-0007', fixture: 'single-enemy' });
    });
    await page.waitForFunction(() => window.__game.getSnapshot().run.elapsedMs > 300);
    expect(runtimeErrors).toEqual([]);
  });

  test('beating the first Tollmother opens the well down to Depth II', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1');
    await page.evaluate(() => window.__game.test?.reset({ seed: 'E2E-DESCENT-0006', fixture: 'descent' }));
    await waitForGame(page);
    await page.keyboard.down('ArrowRight');
    await page.waitForFunction(() => {
      const snapshot = window.__game.getSnapshot();
      return snapshot.room.cleared && snapshot.counts.pickups > 0;
    });
    await page.keyboard.up('ArrowRight');
    expect((await page.evaluate(() => window.__game.getSnapshot())).phase).toBe('running');
    await page.waitForTimeout(800);
    await page.keyboard.down('w');
    await page.waitForFunction(() => window.__game.getSnapshot().floor === 2, null, { timeout: 15_000 });
    await page.keyboard.up('w');
    await waitForGame(page);
    const below = await page.evaluate(() => window.__game.getSnapshot());
    expect(below.floor).toBe(2);
    expect(below.run.kills).toBeGreaterThanOrEqual(1);
    expect(below.room.kind).toBe('start');
    await expect(page.locator('#floor-label')).toContainText('DEPTH II');
    expect(runtimeErrors).toEqual([]);
  });

  test('renders a busy combat room and the Tollmother without errors', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1');
    await page.screenshot({
      path: test.info().outputPath('demo-title.png'),
      fullPage: true,
    });
    await page.evaluate(() => window.__game.test?.reset({ seed: 'ASH-CANTICLE-2048', fixture: 'normal' }));
    await waitForGame(page);
    await page.evaluate(async () => {
      await window.__game.test?.grantItem('twin-rune');
      await window.__game.test?.grantItem('quickwick');
    });
    await expect(page.locator('#toast')).toHaveClass(/is-hidden/, { timeout: 4_000 });
    await page.evaluate(async () => {
      await window.__game.test?.spawnEnemy('siltling', { x: 330, y: 220, hp: 120 });
      await window.__game.test?.spawnEnemy('wickspitter', { x: 650, y: 210, hp: 150 });
      await window.__game.test?.spawnEnemy('knellguard', { x: 680, y: 370, hp: 180 });
    });
    await page.keyboard.down('ArrowUp');
    await page.waitForTimeout(240);
    await page.keyboard.up('ArrowUp');
    await page.screenshot({
      path: test.info().outputPath('demo-combat.png'),
      fullPage: true,
    });
    await page.evaluate(() => window.__game.test?.reset({ seed: 'LAST-TOLL-2048', fixture: 'normal' }));
    expect((await page.evaluate(() => window.__game.getSnapshot())).player).toMatchObject({
      active: true,
      visible: true,
      renderable: true,
    });
    await expect(page.locator('#toast')).toHaveClass(/is-hidden/, { timeout: 4_000 });
    await page.evaluate(() => window.__game.test?.spawnEnemy('tollmother', { x: 720, y: 170, hp: 920 }));
    await expect(page.locator('#boss-meter')).toBeVisible();
    expect((await page.evaluate(() => window.__game.getSnapshot())).player.active).toBe(true);
    await page.screenshot({ path: test.info().outputPath('demo-boss.png'), fullPage: true });
    const bossFrame = await page.evaluate(() => window.__game.getSnapshot());
    expect([bossFrame.summary.hp, bossFrame.player.x, bossFrame.player.y].every(Number.isFinite)).toBe(true);
    expect(bossFrame.player).toMatchObject({ active: true, visible: true, renderable: true });
    await page.waitForFunction(() => window.__game.getSnapshot().summary.hp < 100, null, {
      timeout: 8_000,
    });
    const postImpact = await page.evaluate(() => window.__game.getSnapshot());
    expect(postImpact.summary.hp).toBeGreaterThan(0);
    expect(postImpact.player).toMatchObject({ active: true, visible: true, renderable: true });
    expect(runtimeErrors).toEqual([]);
  });
});

test.describe('mobile multi-touch flow', () => {
  test.beforeEach(({ isMobile }) => {
    test.skip(!isMobile, 'Mobile-only scenario');
  });

  test('simultaneous touch joysticks truly move and cast', async ({ page }) => {
    const runtimeErrors = watchRuntime(page);
    await page.goto('/?qa=1&mobile=1');
    await page.locator('#primary-action').click();
    await waitForGame(page);
    await expect(page.locator('#touch-controls')).toBeVisible();
    await expect(page.locator('#toast')).toHaveClass(/is-hidden/, { timeout: 4_000 });
    await page.evaluate(() => window.__game.test?.grantItem('quickwick'));
    await expect(page.locator('#toast')).toHaveClass(/is-hidden/, { timeout: 4_000 });
    const statCard = await page.locator('.stat-card').boundingBox();
    const soundButton = await page.locator('#sound-button').boundingBox();
    expect(statCard?.width).toBeGreaterThan(160);
    expect(soundButton?.y ?? 0).toBeGreaterThanOrEqual((statCard?.y ?? 0) + (statCard?.height ?? 0) - 1);
    const move = await page.locator('#move-pad').boundingBox();
    const shoot = await page.locator('#shoot-pad').boundingBox();
    expect(move).not.toBeNull();
    expect(shoot).not.toBeNull();
    if (!move || !shoot) throw new Error('Touch control geometry is unavailable');
    const before = await page.evaluate(() => window.__game.getSnapshot().player);
    const cdp = await page.context().newCDPSession(page);
    const movePoint = {
      x: move.x + move.width * 0.82,
      y: move.y + move.height / 2,
      radiusX: 8,
      radiusY: 8,
      force: 1,
      id: 1,
    };
    const shootPoint = {
      x: shoot.x + shoot.width / 2,
      y: shoot.y + shoot.height * 0.18,
      radiusX: 8,
      radiusY: 8,
      force: 1,
      id: 2,
    };
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [movePoint, shootPoint] });
    await page.waitForFunction(
      (startX) =>
        window.__game.getSnapshot().player.x > startX + 18 &&
        window.__game.getSnapshot().counts.playerProjectiles > 0,
      before.x,
    );
    await page.evaluate(async () => {
      await window.__game.test?.spawnEnemy('siltling', { x: 620, y: 230, hp: 120 });
      await window.__game.test?.spawnEnemy('wickspitter', { x: 360, y: 190, hp: 150 });
    });
    await page.waitForFunction(() => window.__game.getSnapshot().counts.enemies === 2);
    await page.screenshot({
      path: test.info().outputPath('demo-mobile.png'),
      fullPage: true,
    });
    await page.evaluate(() => window.__game.test?.clearRoom());
    await page.waitForFunction(() => {
      const snapshot = window.__game.getSnapshot();
      return snapshot.counts.enemies === 0 && snapshot.counts.enemyProjectiles === 0;
    });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForFunction(() => {
      const knobs = document.querySelectorAll('.touch-pad__knob');
      if (knobs.length !== 2) return false;
      for (let index = 0; index < knobs.length; index += 1) {
        const knob = knobs.item(index);
        if (!(knob instanceof HTMLElement)) return false;
        const transform = getComputedStyle(knob).transform;
        if (transform !== 'none' && transform !== 'matrix(1, 0, 0, 1, 0, 0)') return false;
      }
      return true;
    });
    await page.waitForTimeout(180);
    const released = await page.evaluate(() => window.__game.getSnapshot().player.x);
    await page.waitForTimeout(220);
    const stopped = await page.evaluate(() => window.__game.getSnapshot().player.x);
    expect(Math.abs(stopped - released)).toBeLessThan(8);

    await page.locator('#pause-button').click();
    await page.waitForFunction(() => window.__game.getSnapshot().phase === 'paused');
    await page.setViewportSize({ width: 844, height: 390 });
    await page.waitForFunction(() => {
      const canvas = document.querySelector('canvas');
      return canvas?.width === 960 && canvas.height === 540;
    });
    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForFunction(() => {
      const canvas = document.querySelector('canvas');
      return canvas?.width === 540 && canvas.height === 720;
    });
    await page.locator('#resume-button').click();
    await page.waitForFunction(() => window.__game.getSnapshot().phase === 'running');
    expect(runtimeErrors).toEqual([]);
  });
});
