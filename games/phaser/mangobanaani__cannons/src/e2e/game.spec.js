import { test, expect } from '@playwright/test';

function gameState(page) {
  return page.evaluate(() => {
    const game = window.game;
    if (!game) return null;
    const scenes = game.scene.scenes;
    const active = scenes.find(s => s.scene.isActive());
    if (!active) return null;
    const state = { scene: active.scene.key };
    if (active.scene.key === 'GameScene') {
      state.roundActive = active.roundActive;
      state.playerAngle = active.playerCannon?.angle;
      state.playerPower = active.playerCannon?.power;
      state.playerHp = active.playerCannon?.targetHp;
      state.aiHp = active.aiCannon?.targetHp;
      state.playerCooldown = active.playerCooldown;
      state.windCurrent = active.windSystem?.current;
      state.weaponIndex = active.weaponSystem?.currentIndex;
    }
    return state;
  });
}

async function waitForGameScene(page, timeout = 10000) {
  await page.waitForFunction(
    () => {
      const game = window.game;
      if (!game) return false;
      const active = game.scene.scenes.find(s => s.scene.isActive());
      return active && active.scene.key === 'GameScene' && active.roundActive;
    },
    { timeout }
  );
}

test.describe('Cannons v2 E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(500);
  });

  test('menu loads with difficulty selection', async ({ page }) => {
    const menu = page.locator('text=CANNONS');
    await expect(menu).toBeVisible();
    const easyBtn = page.locator('text=Easy');
    await expect(easyBtn).toBeVisible();
  });

  test('start game transitions to canvas', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    const canvas = page.locator('[data-testid="game-canvas"] canvas');
    await expect(canvas).toBeVisible({ timeout: 5000 });
  });

  test('game scene initializes with active round', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);
    const state = await gameState(page);
    expect(state.scene).toBe('GameScene');
    expect(state.roundActive).toBe(true);
  });

  test('adjust angle with ArrowUp', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);

    const before = await gameState(page);
    const initialAngle = before.playerAngle;

    for (let i = 0; i < 10; i++) {
      await page.keyboard.press('ArrowUp');
    }
    await page.waitForTimeout(100);

    const after = await gameState(page);
    expect(after.playerAngle).toBeGreaterThan(initialAngle);
  });

  test('adjust power with ArrowRight', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);

    const before = await gameState(page);
    const initialPower = before.playerPower;

    for (let i = 0; i < 10; i++) {
      await page.keyboard.press('ArrowRight');
    }
    await page.waitForTimeout(100);

    const after = await gameState(page);
    expect(after.playerPower).toBeGreaterThan(initialPower);
  });

  test('fire projectile with Space triggers cooldown', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);

    await page.keyboard.press('Space');
    await page.waitForTimeout(100);

    const state = await gameState(page);
    expect(state.playerCooldown).toBeGreaterThan(0);
  });

  test('switch weapon with number keys', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);

    await page.keyboard.press('Digit2');
    await page.waitForTimeout(100);

    const state = await gameState(page);
    expect(state.weaponIndex).toBe(1);
  });

  test('wind system is active', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);

    const state = await gameState(page);
    expect(state.windCurrent).toBeDefined();
    expect(typeof state.windCurrent).toBe('number');
  });

  test('HUD displays in game', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);
    await page.waitForTimeout(500);

    const wind = page.locator('text=WIND');
    await expect(wind).toBeVisible();

    const you = page.locator('text=YOU');
    await expect(you).toBeVisible();
  });

  test('difficulty selection works', async ({ page }) => {
    await page.click('text=Hard');
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);

    const state = await gameState(page);
    expect(state.scene).toBe('GameScene');
  });

  test('game over triggers on cannon destruction', async ({ page }) => {
    await page.click('text=[ START GAME ]');
    await waitForGameScene(page);

    // Force all rounds won by player
    await page.evaluate(() => {
      const game = window.game;
      const scene = game.scene.scenes.find(s => s.scene.isActive());
      if (scene && scene.scene.key === 'GameScene') {
        scene.matchManager.playerScore = 2;
        scene.aiCannon.targetHp = 0;
        scene.onCannonDestroyed(scene.aiCannon, 'player');
      }
    });

    await page.waitForTimeout(2000);
    const victory = page.locator('text=VICTORY');
    await expect(victory).toBeVisible({ timeout: 5000 });
  });
});
