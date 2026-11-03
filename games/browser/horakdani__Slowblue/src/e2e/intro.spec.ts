import { expect, test } from '@playwright/test';
import { collectErrors } from './helpers';

test('the digitalTULPA ident owns startup, then hands control to the title', async ({ page }) => {
  const errors = collectErrors(page);
  await page.goto('/?intro=full');

  const intro = page.locator('#digitaltulpa-intro');
  const stage = page.locator('#stage');
  await expect(intro).toBeVisible();
  await expect(stage).toHaveAttribute('inert', '');
  await expect(intro.locator('.tulpa-logo')).toBeVisible();
  await expect(intro.locator('.wordmark span')).toHaveCount(12);

  await expect(intro).toHaveCount(0, { timeout: 8000 });
  await expect(stage).not.toHaveAttribute('inert', '');
  await expect(page.locator('.ui-title')).toBeVisible();
  expect(errors).toEqual([]);
});

/**
 * The keystroke that skips has to be *eaten*.
 *
 * The title screen is prepared underneath the ident and starts a run on Space. Until
 * the intro captured the event and stopped it, one press both dismissed the ident and
 * dropped the player straight into act I, having never seen the title screen at all.
 */
test('any key skips the ident without starting a run underneath it', async ({ page }) => {
  const errors = collectErrors(page);
  await page.goto('/?intro=full');

  const intro = page.locator('#digitaltulpa-intro');
  await expect(intro).toBeVisible();
  await page.keyboard.press('Space');

  await expect(intro).toHaveCount(0, { timeout: 2000 });
  await expect(page.locator('.ui-title')).toBeVisible();
  await expect(page.locator('#stage')).not.toHaveAttribute('inert', '');
  expect(await page.evaluate(() => window.__slowblue?.metrics().mode)).toBe('attract');
  expect(errors).toEqual([]);
});

test('a touch skips the ident too, and the title is left usable', async ({ page }) => {
  const errors = collectErrors(page);
  await page.goto('/?intro=full');

  const intro = page.locator('#digitaltulpa-intro');
  await expect(intro).toBeVisible();
  await intro.click({ position: { x: 40, y: 40 } });

  await expect(intro).toHaveCount(0, { timeout: 2000 });
  expect(await page.evaluate(() => window.__slowblue?.metrics().mode)).toBe('attract');
  await expect(page.locator('.ui-title')).toBeVisible();
  expect(errors).toEqual([]);
});

/**
 * The ident is scoped out of `settings.reducedMotion`, on purpose.
 *
 * That setting seeds itself from `prefers-reduced-motion`, iOS puts Reduce Motion one
 * tap into Accessibility, and the ident used to consult it - so most phones got a logo
 * that appeared and vanished in 1.2 seconds instead of the performance. The setting
 * still governs everything in the game that moves a screenful at a time; it no longer
 * governs a seven-second fade. This locks that down from both directions at once.
 */
test('the ident plays in full even where the game is asked for less motion', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/?intro=1');
  await page.evaluate(() => {
    const stored = JSON.parse(localStorage.getItem('tide.settings') ?? '{}') as Record<
      string,
      unknown
    >;
    stored.reducedMotion = true;
    localStorage.setItem('tide.settings', JSON.stringify(stored));
  });
  await page.goto('/?intro=1');

  const intro = page.locator('#digitaltulpa-intro');
  await expect(intro).toBeVisible();
  await expect(intro).not.toHaveClass(/is-reduced/);
  // The eye performance is the thing the quiet variant drops, so it is the thing worth
  // asserting: a full-length ident with no `eyes-scripted` on it is the old symptom.
  await expect(intro).toHaveClass(/eyes-scripted/);
  await expect(intro).toHaveCount(0, { timeout: 8000 });

  // ...and the quiet variant is still reachable, because it is worth being able to see.
  await page.goto('/?intro=reduced');
  const still = page.locator('#digitaltulpa-intro');
  await expect(still).toHaveClass(/is-reduced/, { timeout: 1200 });
  // And it is the whole mark. Every entrance in `ident.css` hides its own part with a
  // backwards `both` fill, and the still cancels those animations wholesale rather than
  // rule by rule - so a part left out of that kill list is not un-animated in the still,
  // it is missing from it. The mouth sits at `scaleX(0)` until 2.72s, which is a
  // zero-width box, which is exactly what Playwright calls invisible.
  await expect(still.locator('.mouth')).toBeVisible();
});
