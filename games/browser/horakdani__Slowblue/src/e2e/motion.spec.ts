import { expect, test } from '@playwright/test';
import { collectErrors } from './helpers';

/**
 * Slowblue: the one thing no unit test can see - a rock that moves, on a screen.
 *
 * `tests/motion.test.ts` proves the geometry: an aperture never closes below what
 * it was authored at, a drift never leaves the envelope the sweep is shown, and
 * the whole thing is a pure function of the simulation clock. None of that says
 * the rock is *drawn* where it collides. That question needs a real frame, a real
 * canvas and a running loop, and this is the only harness in the repo that has
 * all three.
 *
 * It was written after the first device playthrough of the rebuilt act V came
 * back with "there are background elements that disappear", which is exactly the
 * shape of a leaked canvas transform - and `RockPaint` had just learned to
 * translate the canvas under a moving mass.
 */
test('a moving rock is drawn where it collides, and puts the canvas back', async ({ page }) => {
  const errors = collectErrors(page);
  await page.goto('/?act=reentry&seed=12345');
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');

  /*
   * Section 4 of act V is the campaign's first breathing gap, and section 25 its
   * first walking mass. Both are minutes into the act at the deorbit's pace, so
   * the course is rebuilt from that section directly - the shell still believes
   * it is at station one, which is untrue and irrelevant to a question about
   * pixels.
   *
   * Slowblue: 20 was the walking mass before act V's second pass added fifteen
   * sections in front of it. A section index into an act that is being rebuilt is
   * a fragile thing to hard-code, and the alternative - searching the script for
   * the first `motion` - would make the test agree with whatever the level file
   * says rather than with what it is supposed to say. The two assertions below
   * are what catch a stale number: both sections have to actually move.
   */
  const sample = async (section: number): Promise<{ dx: number; drawn: number }> =>
    page.evaluate((from: number) => {
      const w = window.__slowblue!.world;
      w.reset(12345, from);
      for (let i = 0; i < 60; i++) window.__slowblue!.advance(1 / 60);
      let dx = 0;
      for (const s of w.obstacles.sections) {
        if (s.motion === null) continue;
        for (const b of s.blobs) dx = Math.max(dx, Math.abs(b.x - (b.hx ?? b.x)));
      }
      return { dx, drawn: w.obstacles.sections.length };
    }, section);

  const aperture = await sample(4);
  const drift = await sample(25);
  // Both sections actually moved: a test that passes because nothing budged is a
  // test that would have passed before the feature existed.
  expect(aperture.dx, 'the deorbit aperture opened').toBeGreaterThan(1);
  expect(drift.dx, 'the aurora plume walked').toBeGreaterThan(1);

  /*
   * The transform is the whole point. `paintStone` wraps every moving mass in
   * save/translate/restore, four times over - the shadow batch, the body, the
   * fringe and the crest light - and a single unbalanced pair would leave the
   * canvas shifted for everything drawn after it that frame: the haze, the rings,
   * the swarm, the HUD. Reading it back after a full frame is the only way to
   * know all four pairs closed.
   */
  const transform = await page.evaluate(() => {
    const canvas = document.querySelector('canvas');
    const ctx = canvas!.getContext('2d')!;
    const m = ctx.getTransform();
    return { a: m.a, b: m.b, c: m.c, d: m.d, e: m.e, f: m.f };
  });
  expect(transform.e, 'the canvas was left translated in x').toBe(0);
  expect(transform.f, 'the canvas was left translated in y').toBe(0);
  expect(errors).toEqual([]);
});

/**
 * ...and the same question about the third predator silhouette.
 *
 * `tests/ember.test.ts` proves the shard is a shard, that it tumbles independently
 * of its heading, and that every fragment in act V is released *behind* the swarm.
 * All of that is arithmetic on a fake canvas. Whether the thing draws at all on a
 * real one - two additive batches, a gradient wake, a stroked bow shock and a
 * composite operation it has to put back - is a question only a frame can answer,
 * and `Ember.ts` is the newest renderer in the repo.
 */
test('act V s fragments arrive from behind and draw without leaving the canvas dirty', async ({
  page,
}) => {
  const errors = collectErrors(page);
  await page.goto('/?act=reentry&seed=4242');
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');

  /*
   * Section 13 is the night side's ember: the first thing to hunt this swarm since
   * act II. Forty seconds of run is enough for the trigger line to be crossed and
   * for the fragment to burn most of the way down.
   *
   * The one thing this loop has to do besides advance is **keep the swarm up**.
   * A passive act V swarm is swept away in seconds, and a station restart clears
   * the predators - the first version of this test measured exactly one frame of
   * ember and looked like a rendering fault. So it holds the swarm off the strand
   * line with the same stroke the scripted bot uses, and nothing else.
   */
  const seen = await page.evaluate(() => {
    const w = window.__slowblue!.world;
    w.reset(4242, 13);
    const forms = new Set<string>();
    let drawnFrames = 0;
    for (let i = 0; i < 60 * 40; i++) {
      const c = w.swarm.centroid(0);
      if (c.count > 0 && w.behindFraction(w.worldToScreenY(c.y)) > 0.5) {
        w.injectStroke(c.x, c.y, c.x, c.y + w.direction * 90, 1 / 60);
      }
      window.__slowblue!.advance(1 / 60);
      for (const p of w.predators.predators) forms.add(p.form);
      if (w.predators.predators.length > 0) drawnFrames++;
    }
    const canvas = document.querySelector('canvas');
    const m = canvas!.getContext('2d')!.getTransform();
    return {
      forms: [...forms],
      drawnFrames,
      composite: canvas!.getContext('2d')!.globalCompositeOperation,
      e: m.e,
      f: m.f,
    };
  });

  expect(seen.forms, 'act V drew somebody else s animal').toEqual(['ember']);
  expect(seen.drawnFrames, 'no fragment was ever on screen').toBeGreaterThan(60);
  // The wake and the sparks are drawn with `lighter`, and a batch that forgot to
  // put it back would make everything after it in the frame - the swarm, the
  // rings, the HUD - add instead of cover.
  expect(seen.composite, 'the ember left the canvas in additive mode').toBe('source-over');
  expect(seen.e).toBe(0);
  expect(seen.f).toBe(0);
  expect(errors).toEqual([]);
});
