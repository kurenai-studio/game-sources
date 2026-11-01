import { expect, test } from '@playwright/test';

const startGame = async (page, look = 'Glass') => {
  await page.getByRole('button', { name: `Play on ${look}` }).click();
  await expect(page.locator('#startOverlay')).toHaveClass(/hidden/);
  // The engine is loaded on demand once the chosen look has swept across, so
  // the canvas can take a few seconds when several browsers start at once.
  await expect(page.locator('canvas')).toBeVisible({ timeout: 15_000 });
};

test.describe('brick breaker resume', () => {
  test('loads the start screen with both looks side by side', async ({
    page,
  }) => {
    await page.goto('/');

    await expect(page).toHaveTitle(/Resume Brick Breaker/);
    await expect(
      page.getByRole('heading', { name: 'Resume Brick Breaker' })
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: 'Play on Paper' })
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: 'Play on Glass' })
    ).toBeVisible();

    // The same résumé, laid out once per look.
    const paper = page.locator('#brickContainerLight');
    const glass = page.locator('#brickContainerDark');
    await expect(paper).toHaveAttribute('data-layout', 'typeset');
    await expect(glass).toHaveAttribute('data-layout', 'wall');
    await expect(paper.locator('.brick--name').first()).toHaveText('Nathan');
    await expect(glass.locator('.overlay-brick').first()).toHaveText('Nathan');

    await expect(
      page.getByRole('button', { name: 'Show high score' })
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: 'Open settings' })
    ).toBeVisible();
  });

  test('each side of the start screen starts the game in its look', async ({
    page,
  }) => {
    await page.goto('/');
    await startGame(page, 'Paper');

    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
    await expect(page.locator('#gameBrickContainer')).toHaveAttribute(
      'data-layout',
      'typeset'
    );

    await page.goto('/');
    await startGame(page, 'Glass');

    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
    await expect(page.locator('#gameBrickContainer')).toHaveAttribute(
      'data-layout',
      'wall'
    );
  });

  test('shows lives, score, and best score in the HUD', async ({ page }) => {
    await page.goto('/');
    await startGame(page);

    await expect(page.locator('#hudLives .hud-pip')).toHaveCount(5);
    await expect(page.locator('#hudLives')).toHaveAttribute(
      'aria-label',
      '5 lives left'
    );
    await expect(page.locator('#hudScoreValue')).toHaveText('0');
  });

  test('switches between light and dark from the settings menu', async ({
    page,
  }) => {
    await page.goto('/');
    await startGame(page);

    await page.getByRole('button', { name: 'Open settings' }).click();
    await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible();
    await expect(page.getByRole('radio', { name: /Dark/ })).toBeChecked();

    // The radio sits under its card; click the card as a player would.
    await page.locator('.theme-option', { hasText: 'Light' }).click();
    await expect(page.getByRole('radio', { name: /Light/ })).toBeChecked();
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
    await expect(page.locator('#gameBrickContainer')).toHaveAttribute(
      'data-layout',
      'typeset'
    );

    await page.locator('.theme-option', { hasText: 'Dark' }).click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
    await expect(page.locator('#gameBrickContainer')).toHaveAttribute(
      'data-layout',
      'wall'
    );
  });

  test('opens game utility modals', async ({ page }) => {
    await page.goto('/');

    await startGame(page);

    await page.getByRole('button', { name: 'Open settings' }).click();
    await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible();
    await expect(page.getByText('Sound Effects')).toBeVisible();
    await page.getByRole('button', { name: 'Close settings' }).click();
    await expect(
      page.getByRole('heading', { name: 'Settings' })
    ).not.toBeVisible();

    await page.getByRole('button', { name: 'Show high score' }).click();
    await expect(
      page.getByRole('heading', { name: 'High Score' })
    ).toBeVisible();
    await expect(page.locator('#highScoreValue')).toContainText('0');
  });

  test('starts the Phaser canvas and exposes game controls', async ({
    page,
  }) => {
    await page.goto('/');

    await startGame(page);
    await expect(
      page.getByRole('button', { name: /Pause game|Resume game/ })
    ).toBeVisible();
  });
});
