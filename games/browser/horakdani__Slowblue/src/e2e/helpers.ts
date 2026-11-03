import { expect, type Page } from '@playwright/test';

export type Metrics = Record<string, number | string | boolean | null>;

export async function metrics(page: Page): Promise<Metrics> {
  return page.evaluate(() => window.__slowblue!.metrics());
}

/**
 * Whether this run is allowed to rewrite the tracked screenshots in `docs/screens/`.
 *
 * `e2e/capture.spec.ts` is two things at once - a smoke test for mid-run
 * rendering, and the only thing that regenerates the eleven numbered screens the
 * README shows - and only the first of those belongs in `npm run verify`. It
 * rewrote all eleven on every run, so a verify that changed nothing still left
 * eleven modified binaries in the tree and every real diff had them in it.
 *
 * The smoke test still runs every time; the writing is what waits to be asked.
 * `npm run screens` asks.
 */
export const WRITING_SCREENS = process.env.SLOWBLUE_SCREENS === '1';

/**
 * A screenshot into `docs/screens/`, taken only when this run was asked for one.
 *
 * The frame is still *rendered* either way - `page.screenshot` is not what these
 * assertions are about - so the spec keeps exactly the timing it had.
 */
export async function shootScreen(page: Page, path: string): Promise<void> {
  if (WRITING_SCREENS) await page.screenshot({ path });
}

export function collectErrors(page: Page): string[] {
  const errors: string[] = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(`console: ${msg.text()}`);
  });
  page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
  return errors;
}

/**
 * Opens the game and starts a run *through the shell*, the way a player does.
 * Driving `__slowblue.start` instead would skip the one screen every session goes
 * through, which is exactly the screen most likely to break.
 */
export async function boot(page: Page, seed = 12345): Promise<void> {
  await page.goto(`/?seed=${seed}`);
  await start(page);
}

/**
 * Opens one act on its own, through the `?act=` door, and starts it.
 *
 * This is not the campaign: a run reached this way advances no circuit and
 * touches no record, which is the whole point of the door. It is how the suite
 * gets to acts IV-VII without flying the six in front of them, and how it reaches
 * the endings that only exist when an act is *not* handing over to another one.
 */
export async function bootAct(page: Page, act: string, seed = 12345): Promise<void> {
  await page.goto(`/?act=${act}&seed=${seed}`);
  await start(page);
}

async function start(page: Page): Promise<void> {
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await expect(page.locator('.ui-title')).toBeVisible();
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  await page.waitForFunction(() => (window.__slowblue!.metrics().time as number) > 0.2);
}

/**
 * Clears one station the way flying its last section does.
 *
 * The event and the bookkeeping have to happen in one evaluate, for the same
 * reason `completeAct` does: `score` is a pure function of state that `World.step`
 * recomputes every frame, so points written into `earned` only become score once a
 * step runs. `value` is the *next* station's index, which is what the sim itself
 * puts on this event - `main.ts` writes the campaign's checkpoint straight off it,
 * so a helper that shifted the number by one would be testing arithmetic the game
 * does not do.
 */
export async function clearStation(page: Page, station: number, bonus = 0): Promise<void> {
  await page.evaluate(
    ({ index, points }) => {
      const w = window.__slowblue!.world;
      w.run.earned += points;
      w.run.noteLevel(index);
      w.run.recomputeScore(w.shoalCount);
      w.events.push({ type: 'level', x: w.width * 0.5, y: w.cameraY, value: index + 1 });
    },
    { index: station, points: bonus },
  );
  // The checkpoint is written when the render loop drains the event queue, not
  // when it is pushed. One frame.
  await page.waitForFunction((next) => window.__slowblue!.metrics().station === next, station + 1);
}

/**
 * Ends the act the way clearing its last section does, optionally having earned
 * something first.
 *
 * The bonus and the completion have to happen in one evaluate. `score` is a pure
 * function of state that `World.step` recomputes every frame, so points written
 * into `earned` only become score once a step runs - and whether a step lands
 * between two separate evaluates is a coin toss.
 */
export async function completeAct(page: Page, bonus = 0): Promise<void> {
  await page.evaluate((points) => {
    const w = window.__slowblue!.world;
    w.run.earned += points;
    w.events.push({ type: 'complete', x: w.width * 0.5, y: w.cameraY, value: 5 });
    // Completion is worth points of its own, and the recompute goes after it for
    // the same reason it does in `World.step`: otherwise the act banks a score
    // that does not include finishing it.
    w.run.complete();
    w.run.recomputeScore(w.shoalCount);
  }, bonus);
}
