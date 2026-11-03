import { test, expect } from '@playwright/test';

async function waitForWorld(page) {
  await page.goto('/');
  await page.waitForFunction(() => window.__skyisles && window.__skyisles.getState, null, { timeout: 60_000 });
  // skip the title screen (audio stays off; no gesture needed for rendering)
  await page.evaluate(() => window.__skyisles.start());
  await page.waitForTimeout(1500);
}

test.describe('Sky Isles', () => {
  test('loads without console errors and renders non-uniform pixels', async ({ page }) => {
    const errors = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    page.on('pageerror', (err) => errors.push(String(err)));
    await waitForWorld(page);

    const canvas = page.locator('canvas#scene');
    await expect(canvas).toBeVisible();

    // a rich pastel scene compresses poorly: screenshot must be sizable
    const shotA = await page.screenshot();
    expect(shotA.length).toBeGreaterThan(30_000);

    // the world is alive: two frames apart must differ (clouds drift, leaves fall)
    await page.waitForTimeout(800);
    const shotB = await page.screenshot();
    expect(shotB.equals(shotA)).toBeFalsy();

    // non-uniform pixels straight from the canvas (render + readback in one
    // synchronous task, so no preserveDrawingBuffer is needed)
    const varied = await page.evaluate(() => {
      const { renderer, scene, camera } = window.__skyisles.world;
      renderer.render(scene, camera);
      const c = renderer.domElement;
      const g = document.createElement('canvas');
      g.width = 64;
      g.height = 64;
      const ctx = g.getContext('2d');
      ctx.drawImage(c, 0, 0, 64, 64);
      const data = ctx.getImageData(0, 0, 64, 64).data;
      const first = `${data[0]},${data[1]},${data[2]}`;
      let different = 0;
      for (let i = 4; i < data.length; i += 4) {
        if (`${data[i]},${data[i + 1]},${data[i + 2]}` !== first) different++;
      }
      return different;
    });
    expect(varied).toBeGreaterThan(200);
    expect(errors).toEqual([]);
  });

  test('getState exposes the core game state', async ({ page }) => {
    await waitForWorld(page);
    const state = await page.evaluate(() => window.__skyisles.getState());
    expect(state.chimesUnlocked).toBe(0);
    expect(state.portalOpen).toBe(false);
    expect(state.onBonusIsland).toBe(false);
    expect(typeof state.playerPos.x).toBe('number');
    expect(state.playerPos.y).toBeGreaterThan(-40);
    expect(state.muralOrder).toHaveLength(5);
  });

  test('playing all 5 chimes in mural order opens the portal', async ({ page }) => {
    await waitForWorld(page);
    const order = await page.evaluate(() => window.__skyisles.getState().muralOrder);

    // a wrong note first: progress resets, portal stays shut
    await page.evaluate((idx) => window.__skyisles.playChime(idx), (order[0] + 1) % 5);
    let state = await page.evaluate(() => window.__skyisles.getState());
    expect(state.portalOpen).toBe(false);
    expect(state.chimesUnlocked).toBe(0);

    for (const idx of order) {
      await page.evaluate((i) => window.__skyisles.playChime(i), idx);
    }
    state = await page.evaluate(() => window.__skyisles.getState());
    expect(state.chimesUnlocked).toBe(5);
    expect(state.portalOpen).toBe(true);

    // walk into the portal -> bonus star island
    await page.evaluate(() => {
      const s = window.__skyisles.getState();
      window.__skyisles.teleport(s.portalPos.x, s.portalPos.y, s.portalPos.z);
    });
    await expect
      .poll(async () => page.evaluate(() => window.__skyisles.getState().onBonusIsland), { timeout: 10_000 })
      .toBe(true);
    const bonus = await page.evaluate(() => window.__skyisles.getState());
    expect(bonus.playerPos.y).toBeGreaterThan(80);
  });

  test('teleport moves the player and fall respawns at last ground', async ({ page }) => {
    await waitForWorld(page);
    await page.evaluate(() => window.__skyisles.teleport(26, 6.5, -14)); // tree isle
    await page.waitForTimeout(400);
    let state = await page.evaluate(() => window.__skyisles.getState());
    expect(Math.abs(state.playerPos.x - 26)).toBeLessThan(1.5);
    expect(Math.abs(state.playerPos.z - -14)).toBeLessThan(1.5);

    // drop into the void -> respawn back near the tree isle (last grounded)
    await page.evaluate(() => window.__skyisles.teleport(0, -50, 0));
    await expect
      .poll(async () => page.evaluate(() => window.__skyisles.getState().playerPos.y), { timeout: 10_000 })
      .toBeGreaterThan(-40);
    state = await page.evaluate(() => window.__skyisles.getState());
    expect(Math.abs(state.playerPos.x - 26)).toBeLessThan(3);
  });
});
