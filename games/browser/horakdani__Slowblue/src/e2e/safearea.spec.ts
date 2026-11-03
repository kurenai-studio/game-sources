import { expect, test, type Page } from '@playwright/test';
import { boot, metrics } from './helpers';

/**
 * Does anything the player has to touch or read sit under the cutout?
 *
 * The CSS has said `env(safe-area-inset-*)` since the first week and nobody has
 * ever seen it work, because the only way to see it work is to hold a phone with
 * a notch. Chromium emulates a viewport, a device pixel ratio and touch, but it
 * does not emulate a Dynamic Island, so the insets in this suite have always been
 * zero and every safe-area rule in the game has been, in test terms, dead code.
 *
 * That is what the custom properties in `index.html` are for. The four insets are
 * declared once, seeded from `env()`, and everything that dodges the cutout hangs
 * off them - so a test can write real device geometry into them and measure what
 * moves. The numbers below are the actual CSS-pixel insets those devices report.
 *
 * Two mechanisms are checked, because there are two. The DOM chrome dodges the
 * notch through the stylesheet; the canvas HUD dodges it through
 * `Renderer.setInsets`, fed by the `#safe-probe` element. A change that moves one
 * and not the other is exactly the bug this is here for.
 */

interface Cutout {
  name: string;
  top: number;
  right: number;
  bottom: number;
  left: number;
  /** Turned sideways, for the geometry that only happens sideways. */
  viewport?: { width: number; height: number };
}

const CUTOUTS: readonly Cutout[] = [
  // iPhone 14/15/16 Pro, portrait. The deepest top inset in circulation.
  { name: 'Dynamic Island, portrait', top: 59, right: 0, bottom: 34, left: 0 },
  // iPhone X..13, portrait. The notch proper.
  { name: 'notch, portrait', top: 47, right: 0, bottom: 34, left: 0 },
  // The same phone turned sideways, where the large insets are the side ones and
  // the home indicator is a thin bar rather than a deep one.
  {
    name: 'notch, landscape',
    top: 0,
    right: 59,
    bottom: 21,
    left: 59,
    viewport: { width: 844, height: 390 },
  },
  // Android with the three-button bar: no cutout at the top worth dodging, and a
  // navigation bar at the bottom that is deeper than any iPhone's indicator.
  { name: 'Android navigation bar', top: 24, right: 0, bottom: 48, left: 0 },
  // The flat slab. Every inset zero is the case the other four must not break.
  { name: 'no cutout', top: 0, right: 0, bottom: 0, left: 0 },
];

async function wear(page: Page, cutout: Cutout): Promise<void> {
  await page.evaluate((c) => {
    const root = document.documentElement.style;
    root.setProperty('--safe-t', `${c.top}px`);
    root.setProperty('--safe-r', `${c.right}px`);
    root.setProperty('--safe-b', `${c.bottom}px`);
    root.setProperty('--safe-l', `${c.left}px`);
    // The canvas half of the plumbing only re-reads the probe on a resize, which
    // is also the only moment a real phone changes its insets (rotation).
    window.dispatchEvent(new Event('resize'));
  }, cutout);
}

/**
 * Everything that must clear the cutout, and nothing that must not.
 *
 * The canvas is deliberately absent: `viewport-fit=cover` is the whole point of
 * it, and the water is supposed to run under the island and behind the home
 * indicator. What may not is anything with a target or a word in it.
 */
const CHROME = ['.ui-panel', '.ui-corner-pause', '.ui-corner-mix', '.ui-mix'];

async function offenders(page: Page, cutout: Cutout): Promise<string[]> {
  return page.evaluate(
    ({ c, selectors }) => {
      const bad: string[] = [];
      const vw = window.innerWidth;
      const vh = window.innerHeight;
      // Half a pixel: a fractional layout on a 3x display is not an offence.
      const slack = 0.5;
      for (const selector of selectors) {
        for (const el of document.querySelectorAll(selector)) {
          const r = el.getBoundingClientRect();
          if (r.width === 0 || r.height === 0) continue;
          if (getComputedStyle(el).display === 'none') continue;
          if (r.left < c.left - slack) bad.push(`${selector} left ${r.left.toFixed(1)}`);
          if (r.top < c.top - slack) bad.push(`${selector} top ${r.top.toFixed(1)}`);
          if (r.right > vw - c.right + slack) bad.push(`${selector} right ${r.right.toFixed(1)}`);
          // A panel taller than the space left over is a scroll, not an overlap:
          // the shell scrolls, and the padding keeps the last row reachable.
          if (r.bottom > vh - c.bottom + slack && r.height < vh - c.top - c.bottom) {
            bad.push(`${selector} bottom ${r.bottom.toFixed(1)}`);
          }
        }
      }
      return bad;
    },
    { c: cutout, selectors: CHROME },
  );
}

test.describe('safe area on real cutout geometries', () => {
  for (const cutout of CUTOUTS) {
    test(`the shell and the run clear the ${cutout.name}`, async ({ page }) => {
      if (cutout.viewport !== undefined) await page.setViewportSize(cutout.viewport);
      await page.goto('/?seed=12345');
      await page.waitForFunction(() => window.__slowblue !== undefined);
      await wear(page, cutout);

      // The plumbing first: if the probe does not report the geometry, nothing
      // below is measuring what it claims to.
      const probe = await page.evaluate(() => {
        const cs = getComputedStyle(document.getElementById('safe-probe')!);
        return {
          top: parseFloat(cs.paddingTop),
          right: parseFloat(cs.paddingRight),
          bottom: parseFloat(cs.paddingBottom),
          left: parseFloat(cs.paddingLeft),
        };
      });
      expect(probe).toEqual({
        top: cutout.top,
        right: cutout.right,
        bottom: cutout.bottom,
        left: cutout.left,
      });

      // ...and the canvas has the same idea of the cutout as the stylesheet.
      const m = await metrics(page);
      expect([m.insetTop, m.insetRight, m.insetBottom, m.insetLeft]).toEqual([
        cutout.top,
        cutout.right,
        cutout.bottom,
        cutout.left,
      ]);

      // The title screen, which is the first thing anyone sees.
      await expect(page.locator('.ui-title')).toBeVisible();
      expect(await offenders(page, cutout)).toEqual([]);

      // The run, where the two corner buttons live.
      await page.locator('button.ui-btn.primary').first().click();
      await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
      await expect(page.locator('.ui-corner-pause')).toBeVisible();
      expect(await offenders(page, cutout)).toEqual([]);

      // The mixer drawer is the one panel pinned to three edges at once, so it is
      // the one most likely to be caught by a bottom inset.
      await page.locator('.ui-corner-mix').click();
      await expect(page.locator('.ui-mix')).toBeVisible();
      expect(await offenders(page, cutout)).toEqual([]);
    });
  }

  test('the pause button moves with the cutout rather than ignoring it', async ({ page }) => {
    await boot(page);
    const btn = page.locator('.ui-corner-pause');

    await wear(page, { name: 'flat', top: 0, right: 0, bottom: 0, left: 0 });
    const flat = (await btn.boundingBox())!;

    await wear(page, CUTOUTS[0]);
    const island = (await btn.boundingBox())!;

    // Not just "inside the safe area" - actually displaced by the inset. A rule
    // that resolved to zero would pass the containment check on every geometry.
    expect(island.y - flat.y).toBeCloseTo(CUTOUTS[0].top, 1);
    expect(island.x).toBeCloseTo(flat.x, 1);
  });
});
