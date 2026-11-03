import { expect, test, type Page } from '@playwright/test';
import { collectErrors } from './helpers';

/**
 * Slowblue: every station of every act, shot.
 *
 * This is the spec that exists because a test can say "something was drawn" and
 * be wrong about whether anyone can see it. The Cliff backdrop passed a
 * draws-geometry test twice: once while it was rendering entirely off-screen, and
 * once while it had a hard visible edge running across the middle of the flyable
 * course. Both times the assertion that would have caught it was a person looking
 * at the frame.
 *
 * So this writes the frames out. It asserts what a machine honestly can - that
 * the frame is not empty, not uniform, and not the wrong act's palette - and it
 * leaves `docs/screens/acts/` behind for the half a machine cannot.
 */

/** Every act, and the stations in it. Read off the game rather than restated. */
const ACTS = ['water', 'air', 'thin', 'orbit', 'reentry', 'rain', 'home'];

interface Frame {
  /** Mean luminance 0..255, and the spread around it. */
  mean: number;
  spread: number;
  /** Fraction of sampled pixels that differ from the frame's most common colour. */
  variety: number;
  /**
   * The largest luminance step between two adjacent rows that happens *across the
   * whole width at once*, and where it was.
   *
   * This is the number that catches a live gradient clipped by the rectangle that
   * draws it - the class the estuary's shafts were the first case of (§18), and
   * which act II then turned out to have two more of: the anvil's light band
   * ending at its own brightest stop, and the squall's break starting a fifth of a
   * screen inside its own radius.
   *
   * Coherence is what makes it specific. A cloud silhouette's top edge is also a
   * large row step and is the picture doing its job; what it cannot be is the same
   * step at the same y in every column, because it is a shape and shapes have
   * sides. Only something drawn edge to edge can do that.
   */
  seam: number;
  seamAt: number;
  /**
   * The seam number, transposed: the largest luminance step between two adjacent
   * *columns* that happens down the whole height at once, and where it was.
   *
   * The two are the same defect on the two axes and the suite only ever had one of
   * them. `seam` scans rows for a step every column agrees on, so it is blind by
   * construction to a step every row agrees on - and act V's aurora shipped seven
   * full-height rectangles filled with a live vertical gradient, hard-sided, both
   * sides in shot, reading **11.07** here against a campaign that reads 0 to 4.69.
   * Its `seam` at the same moment was 3.05, in the middle of the field.
   *
   * Reported as a *prominence* rather than as a magnitude, and that is what makes
   * it specific rather than just large. A radial gradient laid across the frame -
   * the plasma's shock, the well's pull - also steps in the same direction in every
   * column it covers, and steps by a lot; what it cannot do is step much more at
   * one column than at the columns ten pixels either side of it, because it is a
   * ramp and a ramp has no place in it. An edge does exactly that. So this is the
   * step at a column minus the mean of the steps at ±10, which reads near zero on a
   * ramp however steep and reads the full height of the jump on an edge.
   */
  rib: number;
  ribAt: number;
  /**
   * How much picture there is in each third of the play field: the mean, over the
   * rows of a band, of the luminance spread *along* a row.
   *
   * This is the one thing none of the numbers above can say. `spread` and
   * `variety` are taken over the whole frame, and the whole frame always contains
   * the station banner, the HUD rail and the shoal - so a backdrop that has left
   * the picture entirely still scores healthily on both. Act II shipped two
   * stations that way and no guard in the suite was in a position to notice: the
   * spray's late image is bare gradient from the banner to the bottom sixteenth,
   * and the cliff's headland fades to a single thread.
   *
   * Horizontal spread is what separates the two cases, because a background fill
   * in this game is *always* a vertical gradient - `drawBackground` builds one and
   * every backdrop layers more of them on top. A gradient and nothing else has
   * zero spread along any row of it, whatever it is doing down the frame. A crest,
   * a cloud, a cliff face, a rain streak or a bird cannot: they are shapes, and a
   * shape puts different colours side by side.
   *
   * Three bands rather than one number, because the failure is local. The spray's
   * late frame has a flock in the bottom third and a banner in the top one, and
   * the whole of its middle is empty - averaged over the frame that reads as a
   * picture.
   *
   * It is reported and **not asserted on**, and that is a measured conclusion
   * rather than caution. The campaign has stations whose whole subject is
   * emptiness, and they read exactly like a station that has lost its picture:
   * the deorbit's late bands are 0.74/0.84/2.53, the salt line's 11.39/0.71/3.48,
   * the Karman line's total is lower than the broken spray's was. No floor
   * separates those from the defect, no ratio against the opening frame does
   * either - the passage legitimately sheds three quarters of its content by its
   * own late image - and a threshold tuned until it happened to would be a
   * threshold that had been told the answer. So this is an instrument for the
   * person reading the report, in the same position as the seam number's own
   * admission: it says where to look, and the looking is still the assertion.
   */
  bands: [number, number, number];
}

/**
 * Reads the canvas back and reduces it to four numbers.
 *
 * `mean` catches a frame that is black or blown out. `spread` catches a frame
 * that is one flat colour - the failure mode of a backdrop that drew nothing and
 * left the sky fill behind. `variety` catches a frame that is a gradient and
 * nothing else, which is what "the backdrop is off-screen" actually looks like.
 * `bands` catches the same emptiness when it is confined to part of the frame,
 * which is what "the backdrop has drained out of the bottom" looks like.
 */
async function frame(page: Page): Promise<Frame> {
  return page.evaluate(() => {
    const canvas = document.querySelector('canvas#game') as HTMLCanvasElement;
    const ctx = canvas.getContext('2d')!;
    const { width, height } = canvas;
    const data = ctx.getImageData(0, 0, width, height).data;
    let sum = 0;
    let sumSq = 0;
    let n = 0;
    const buckets = new Map<number, number>();
    // Every 7th pixel on both axes: enough to characterise a frame, cheap enough
    // to run 42 times.
    for (let y = 0; y < height; y += 7) {
      for (let x = 0; x < width; x += 7) {
        const i = (y * width + x) * 4;
        const l = (data[i]! * 299 + data[i + 1]! * 587 + data[i + 2]! * 114) / 1000;
        sum += l;
        sumSq += l * l;
        n++;
        const key = (data[i]! >> 3) * 1024 + (data[i + 1]! >> 3) * 32 + (data[i + 2]! >> 3);
        buckets.set(key, (buckets.get(key) ?? 0) + 1);
      }
    }
    const mean = sum / n;
    const commonest = Math.max(...buckets.values());

    // The seam pass, over the picture rather than the chrome: below the banner and
    // inside the HUD rail, because a line of text is a full-width step too.
    const lum = (i: number): number =>
      (data[i]! * 299 + data[i + 1]! * 587 + data[i + 2]! * 114) / 1000;
    const x0 = Math.round(width * 0.05);
    const x1 = Math.round(width * 0.85);
    const y0 = Math.round(height * 0.25);
    const y1 = Math.round(height * 0.95);
    let seam = 0;
    let seamAt = 0;
    for (let y = y0; y < y1 - 1; y++) {
      let agree = 0;
      let count = 0;
      let delta = 0;
      for (let x = x0; x < x1; x += 2) {
        const d = lum(((y + 1) * width + x) * 4) - lum((y * width + x) * 4);
        // Below this the row is noise rather than an edge, and counting it would
        // let a smooth gradient's own slope reach full agreement.
        if (Math.abs(d) > 0.35) agree += d > 0 ? 1 : -1;
        delta += d;
        count++;
      }
      if (Math.abs(agree) / count > 0.85 && Math.abs(delta / count) > seam) {
        seam = Math.abs(delta / count);
        seamAt = y / height;
      }
    }
    // The seam pass again, down the other axis, over the same play field. Every
    // column's mean step is kept rather than just the winner, because the number
    // that separates an edge from a ramp is local: it is how much this column
    // steps against how much its neighbours do.
    const step: number[] = [];
    const coherent: boolean[] = [];
    for (let x = x0; x < x1 - 1; x++) {
      let agree = 0;
      let count = 0;
      let delta = 0;
      for (let y = y0; y < y1; y += 2) {
        const d = lum((y * width + x + 1) * 4) - lum((y * width + x) * 4);
        if (Math.abs(d) > 0.35) agree += d > 0 ? 1 : -1;
        delta += d;
        count++;
      }
      step.push(Math.abs(delta / count));
      coherent.push(Math.abs(agree) / count > 0.85);
    }
    let rib = 0;
    let ribAt = 0;
    for (let i = 0; i < step.length; i++) {
      if (!coherent[i]) continue;
      const near =
        (step[Math.max(0, i - 10)]! + step[Math.min(step.length - 1, i + 10)]!) / 2;
      if (step[i]! - near > rib) {
        rib = step[i]! - near;
        ribAt = (x0 + i) / width;
      }
    }

    // The band pass, over the same play field the seam pass uses - below the
    // banner and inside the HUD rail, so neither is mistaken for scenery.
    const bands: number[] = [];
    for (let b = 0; b < 3; b++) {
      const by0 = Math.round(y0 + ((y1 - y0) * b) / 3);
      const by1 = Math.round(y0 + ((y1 - y0) * (b + 1)) / 3);
      let rows = 0;
      let total = 0;
      for (let y = by0; y < by1; y += 3) {
        let s = 0;
        let sq = 0;
        let c = 0;
        for (let x = x0; x < x1; x += 3) {
          const l = lum((y * width + x) * 4);
          s += l;
          sq += l * l;
          c++;
        }
        const m = s / c;
        total += Math.sqrt(Math.max(0, sq / c - m * m));
        rows++;
      }
      bands.push(total / rows);
    }

    return {
      mean,
      spread: Math.sqrt(sumSq / n - mean * mean),
      variety: 1 - commonest / n,
      seam,
      seamAt,
      rib,
      ribAt,
      bands: bands as [number, number, number],
    };
  });
}

/**
 * The floor under the column step, and why it is nine.
 *
 * Where the measurement put it. All eighty-four frames - forty-two stations at
 * their opening and forty-two at their late image - read **0.00 to 5.97** after
 * act V's curtains were fixed, and a twenty-six sample sweep of act V never got
 * past 6.29; the defect this was written for read 11.07 and 10.05. So there is
 * half again in hand below it and a quarter above, and nothing was tuned to clear
 * it.
 *
 * The top of the field is the plasma's wake at 5.97, and it is worth knowing what
 * that is because it is not a defect: three of the thirty-four streaks land within
 * two CSS pixels of each other and stack into what reads as one ruled line down the
 * frame. A hash coincidence in the loudest picture in the game - measured, named,
 * and left alone.
 */
const RIB_FLOOR = 9;

test('shoots every station of all seven acts', async ({ page }) => {
  test.setTimeout(300_000);
  const errors = collectErrors(page);
  // Through the dev door, so nothing here advances a circuit or touches a record.
  await page.goto('/?act=water&seed=7');
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');

  const report: string[] = [];
  for (const act of ACTS) {
    const stations = await page.evaluate((key) => {
      window.__slowblue!.jump(key, 0, 7);
      return window.__slowblue!.world.act.levels.map((l) => l.key);
    }, act);

    for (let i = 0; i < stations.length; i++) {
      await page.evaluate(
        ([key, station]) => window.__slowblue!.jump(key as string, station as number, 7),
        [act, i] as [string, number],
      );
      // Long enough for the palette crossfade to land and the course to build.
      await page.waitForTimeout(900);
      await page.evaluate(() => window.__slowblue!.advance(2.5));
      await page.waitForTimeout(250);

      const f = await frame(page);
      report.push(
        `${act}/${i + 1} ${stations[i]}  mean=${f.mean.toFixed(1)} spread=${f.spread.toFixed(1)} variety=${f.variety.toFixed(3)} seam=${f.seam.toFixed(2)}@${f.seamAt.toFixed(3)}h rib=${f.rib.toFixed(2)}@${f.ribAt.toFixed(3)}w bands=${f.bands.map((b) => b.toFixed(2)).join('/')}`,
      );
      await page.screenshot({
        path: `docs/screens/acts/${act}-${i + 1}-${stations[i]}.png`,
      });

      // A station that is one flat colour is a station whose backdrop did not
      // draw, whatever its unit test says.
      expect(f.spread, `${act}/${stations[i]} is flat`).toBeGreaterThan(1.5);
      expect(f.variety, `${act}/${stations[i]} has no content`).toBeGreaterThan(0.02);
      // ...and one that is black or white is a station nobody can play.
      expect(f.mean, `${act}/${stations[i]} is black`).toBeGreaterThan(1.2);
      expect(f.mean, `${act}/${stations[i]} is blown out`).toBeLessThan(232);
      // ...and one with a line drawn edge to edge across it is a station with a
      // `fillRect` through a live gradient in it.
      //
      // Ten is where the measurement put it, not where it would be nice to be. All
      // forty-two read between 2.3 and 6.9 on this frame, and the anvil's own
      // defect - the one this was written for - read 14.0 before it was fixed and
      // 4.3 after. So there is clear air on both sides and nothing was tuned to
      // clear it.
      //
      // It is a floor rather than a proof. The squall's break, the second seam
      // found in the same pass, was only 3.9 and sat inside the family: a
      // campaign-wide magnitude cannot catch a faint one, and no threshold that
      // could would survive the acts that are legitimately lumpy. What this
      // guards against is a *large* new one going in unseen, which is what
      // happened here - the anvil shipped with a full-width line across it and
      // every test in the suite passed.
      expect(f.seam, `${act}/${stations[i]} has a seam at ${f.seamAt.toFixed(3)}h`).toBeLessThan(10);
      // ...and the same thing down the other axis, which is what act V's aurora
      // was: seven full-height rectangles through a live gradient, every sampled
      // row of the frame agreeing on the sign of the step at both of their sides.
      expect(
        f.rib,
        `${act}/${stations[i]} has a hard column edge at ${f.ribAt.toFixed(3)}w`,
      ).toBeLessThan(RIB_FLOOR);
    }
  }
  console.log(report.join('\n'));
  expect(errors).toEqual([]);
});

/**
 * Slowblue: ...and every station again, at the end of itself.
 *
 * The pass above shoots each station on its opening frame, which is half of it.
 * A station moves its floor, its light and its cloud deck across most of a screen
 * over its own `progress` - `jet` alone takes its troposphere from 0.66h to 0.92h
 * - so a defect that is off the bottom of the frame at the opening is a defect no
 * guard in this suite has ever been in a position to see. Both of act II's were
 * found by looking at the late image by hand, and the nacreous lens below was
 * found the same way one act later.
 *
 * The late image cannot be reached by playing. Act III restarts the station on
 * failure and act IV does not, but either way a scripted hand is long dead to the
 * hunters before a station's own progress gets past a third - measured, sweeping
 * act III: twenty-six samples of forced advance never took `jet` past 0.55 and
 * never took `nacre` past 0.18. So it is reached the way the dev door reaches
 * anything: `reset` at the station's last section, which is the same course the
 * player would have arrived at, built from the same seed.
 *
 * Same instrument and the same two floors as the opening pass, for the same
 * reason: all forty-two read **2.09 to 6.66** on the seam here, against 2.3 to 6.9
 * there, and 0.00 to 5.97 on the column step across both passes. Nothing was tuned
 * to clear either.
 */
test('shoots every station again at its late image', async ({ page }) => {
  test.setTimeout(300_000);
  const errors = collectErrors(page);
  await openRun(page);

  const report: string[] = [];
  for (const act of ACTS) {
    const stations = await page.evaluate((key) => {
      window.__slowblue!.jump(key, 0, 7);
      const w = window.__slowblue!.world;
      return w.act.levels.map((level, i) => ({
        key: level.key,
        // The last section that belongs to this station, in the act's own script.
        last: w.act.script.reduce((acc, entry, idx) => (entry.level === i ? idx : acc), 0),
      }));
    }, act);

    for (let i = 0; i < stations.length; i++) {
      await page.evaluate(
        ([key, station]) => window.__slowblue!.jump(key as string, station as number, 7),
        [act, i] as [string, number],
      );
      await page.evaluate((section) => window.__slowblue!.world.reset(7, section), stations[i]!.last);
      await page.waitForTimeout(900);
      await page.evaluate(() => window.__slowblue!.advance(2.5));
      await page.waitForTimeout(250);

      const f = await frame(page);
      report.push(
        `${act}/${i + 1} ${stations[i]!.key} late  mean=${f.mean.toFixed(1)} spread=${f.spread.toFixed(1)} variety=${f.variety.toFixed(3)} seam=${f.seam.toFixed(2)}@${f.seamAt.toFixed(3)}h rib=${f.rib.toFixed(2)}@${f.ribAt.toFixed(3)}w bands=${f.bands.map((b) => b.toFixed(2)).join('/')}`,
      );
      await page.screenshot({
        path: `docs/screens/acts-late/${act}-${i + 1}-${stations[i]!.key}.png`,
      });

      const where = `${act}/${stations[i]!.key} late`;
      expect(f.spread, `${where} is flat`).toBeGreaterThan(1.5);
      expect(f.variety, `${where} has no content`).toBeGreaterThan(0.02);
      expect(f.mean, `${where} is black`).toBeGreaterThan(1.2);
      expect(f.mean, `${where} is blown out`).toBeLessThan(232);
      expect(f.seam, `${where} has a seam at ${f.seamAt.toFixed(3)}h`).toBeLessThan(10);
      expect(
        f.rib,
        `${where} has a hard column edge at ${f.ribAt.toFixed(3)}w`,
      ).toBeLessThan(RIB_FLOOR);
    }
  }
  console.log(report.join('\n'));
  expect(errors).toEqual([]);
});

/**
 * Slowblue: the umbra's cities, counted - which is really act IV's planet, asked
 * whether it is in the frame.
 *
 * The seam guard above catches a *line* that should not be there. This catches the
 * opposite and the harder one: geometry that is drawn correctly and is off the
 * bottom of the picture. Act IV shipped that way. Every station passed `render`,
 * `spread`, `variety`, `mean` and `seam`, and the planet, the band of air along
 * its limb, the weather on its day side and all twenty-six of these cities were
 * below the frame for the first four stations of six, because the `rise` those
 * stations passed never reached the 0.538 at which the limb crosses the bottom
 * edge. An absence is not a seam. Nothing in the suite could have said so.
 *
 * The cities are the canary rather than the subject. They hang off `limbY` like
 * everything else on that planet, they sit in the *narrowest* strip of it - a band
 * between a twenty-seventh and a fourteenth of the screen at this station - and they
 * are warm on a frame that is otherwise the darkest in the game, so they are both
 * the first thing to leave the picture if the mapping moves and the easiest thing
 * to count when it has not.
 *
 * Sixty is a floor under a measurement, not a target: it read **0** at all three
 * sections before - not few, none - and reads **164 to 177** after.
 *
 * Like every picture assertion in this file it assumes the renderer is on its top
 * quality rung, which is where `drawBackground` stops calling `drawBackdrop` at
 * all: below 0.5 there is no act IV backdrop to count cities in, and the flatness
 * assertions above would go first.
 */
test('keeps act IV’s planet in the frame, counted at the umbra', async ({ page }) => {
  test.setTimeout(120_000);
  const errors = collectErrors(page);
  await openRun(page);

  const sections = await page.evaluate(() => {
    // Station 3 of act IV, and every section the act's script gives it.
    window.__slowblue!.jump('orbit', 2, 7);
    const w = window.__slowblue!.world;
    return w.act.script.map((e, i) => (e.level === 2 ? i : -1)).filter((i) => i >= 0);
  });
  expect(sections.length, 'the umbra has no sections').toBeGreaterThan(0);

  const report: string[] = [];
  for (const section of sections) {
    await page.evaluate(() => window.__slowblue!.jump('orbit', 2, 7));
    await page.evaluate((s) => window.__slowblue!.world.reset(7, s), section);
    await page.waitForTimeout(900);
    await page.evaluate(() => window.__slowblue!.advance(2.5));
    await page.waitForTimeout(250);

    // Warm pixels low in the frame. By hue rather than by brightness, because a
    // star is white and a city is not, and the swarm - which is also warm - is
    // never this far down. The HUD rail is outside the same 0.05..0.85 the seam
    // pass uses.
    const lamps = await page.evaluate(() => {
      const canvas = document.querySelector('canvas#game') as HTMLCanvasElement;
      const { width, height } = canvas;
      const data = canvas.getContext('2d')!.getImageData(0, 0, width, height).data;
      let n = 0;
      for (let y = Math.round(height * 0.88); y < height; y++) {
        for (let x = Math.round(width * 0.05); x < width * 0.85; x++) {
          const i = (y * width + x) * 4;
          if (data[i]! > data[i + 2]! + 12 && data[i]! > 40) n++;
        }
      }
      return n;
    });
    report.push(`orbit/umbra s${String(section)}  lamps=${String(lamps)}`);
    expect(lamps, `the umbra drew no cities at section ${String(section)}`).toBeGreaterThan(60);
  }
  console.log(report.join('\n'));
  expect(errors).toEqual([]);
});

/**
 * Slowblue: ...and the salt line's plankton, counted - act VII's version of the same
 * question, which is whether the thing a station is *for* is in the frame.
 *
 * The umbra drew its cities off the bottom of the picture. This one never drew its
 * subject at all: `render/Homecoming.ts` says the salt line has "the first living
 * things the campaign has had since the estuary - plankton, drifting up past the
 * swarm", the design's handover sentence is *where fresh water meets salt, the
 * gold reappears as small living forms*, and what the station actually contained
 * was the receding surface, the caustics under it and marine snow. Nothing in the
 * suite could have said so: the frame is not flat, not black, not uniform and has
 * no seam in it. Its middle third read 2.78 / 1.72 / 1.80, which is the range the
 * campaign's *empty* stations read.
 *
 * Counted in the middle band, below the swarm's own water and above the decor's:
 * warm-of-hue and bright, which on this station's teal is what an additive cream
 * body is and what nothing else in that band is. Sixty is not the floor here that
 * it was at the umbra - this is bright water, so a lit body is a *ratio* rather
 * than a colour - and the honest reading of the three sections is that the first
 * one had something in the band already: **248, 0, 0** before and **601, 332, 256**
 * after. So the two later sections are the canary and the first one is not, and
 * the floor is under the smallest real reading with room to spare.
 */
test('keeps act VII’s plankton in the salt line’s water, counted', async ({ page }) => {
  test.setTimeout(120_000);
  const errors = collectErrors(page);
  await openRun(page);

  const sections = await page.evaluate(() => {
    window.__slowblue!.jump('home', 0, 7);
    const w = window.__slowblue!.world;
    return w.act.script.map((e, i) => (e.level === 0 ? i : -1)).filter((i) => i >= 0);
  });
  expect(sections.length, 'the salt line has no sections').toBeGreaterThan(0);

  const report: string[] = [];
  for (const section of sections) {
    await page.evaluate(() => window.__slowblue!.jump('home', 0, 7));
    await page.evaluate((s) => window.__slowblue!.world.reset(7, s), section);
    await page.waitForTimeout(900);
    await page.evaluate(() => window.__slowblue!.advance(2.5));
    await page.waitForTimeout(250);

    const bodies = await page.evaluate(() => {
      const canvas = document.querySelector('canvas#game') as HTMLCanvasElement;
      const { width, height } = canvas;
      const data = canvas.getContext('2d')!.getImageData(0, 0, width, height).data;
      let n = 0;
      // The middle band of the play field, inside the HUD rail: the swarm sits
      // above it and the rings and the kelp below.
      for (let y = Math.round(height * 0.5); y < height * 0.74; y++) {
        for (let x = Math.round(width * 0.05); x < width * 0.85; x++) {
          const i = (y * width + x) * 4;
          const l = (data[i]! * 299 + data[i + 1]! * 587 + data[i + 2]! * 114) / 1000;
          if (data[i]! > data[i + 2]! * 0.45 && l > 100) n++;
        }
      }
      return n;
    });
    report.push(`home/brackish s${String(section)}  bodies=${String(bodies)}`);
    expect(bodies, `the salt line is empty water at section ${String(section)}`).toBeGreaterThan(
      150,
    );
  }
  console.log(report.join('\n'));
  expect(errors).toEqual([]);
});

/**
 * Plays one act's ending and shoots a frame per movement.
 *
 * Off the film's own phase rather than off a wall-clock mark, and that
 * distinction is the same one `main.ts` had to make about the handover: films
 * advance on `frameDt`, which is a fixed step plus the frame's cost, so any
 * schedule written in real seconds lands somewhere else on every device. Asking
 * the film where it is cannot drift.
 */
async function shootEnding(
  page: Page,
  act: string,
  into: string,
  report: string[],
): Promise<Frame[]> {
  // The act's last station, which is the one its ending belongs to.
  const last = await page.evaluate((key) => {
    window.__slowblue!.jump(key, 0, 4242);
    return window.__slowblue!.world.act.levels.length - 1;
  }, act);
  await page.evaluate(
    ([key, station]) => window.__slowblue!.jump(key as string, station as number, 4242),
    [act, last] as [string, number],
  );
  await page.waitForTimeout(1000);

  // Finish the act where the player would have. The film starts on the
  // `complete` event exactly as it does in a real run.
  await page.evaluate(() => {
    const w = window.__slowblue!.world;
    w.events.push({ type: 'complete', x: w.width * 0.5, y: w.cameraY, value: 5 });
    w.run.complete();
  });

  const seen = new Set<string>();
  const shots: Frame[] = [];
  // Long enough for the longest film plus its tail, sampled fine enough to
  // catch the shortest movement (the breach, at just over half a second).
  for (let i = 0; i < 260; i++) {
    const m = await page.evaluate(() => window.__slowblue!.metrics());
    const kind = m.film as string | null;
    const phase = m.filmPhase as string | null;
    if (kind !== null && phase !== null && !seen.has(phase)) {
      seen.add(phase);
      const f = await frame(page);
      shots.push(f);
      report.push(
        `${act}/${kind}/${phase}  mean=${f.mean.toFixed(1)} spread=${f.spread.toFixed(1)} variety=${f.variety.toFixed(3)}`,
      );
      await page.screenshot({ path: `${into}/${act}-${String(seen.size)}-${phase}.png` });
    }
    await page.waitForTimeout(120);
    if (m.filmHandedOver === true && seen.size > 2) break;
  }

  // Every film has at least three movements - `Karman` is the sparest, and
  // deliberately: it is the one ending in the game made out of an absence - and
  // every one of them has to be a picture: not flat, not black, not blown out.
  // Exactly the bar the stations are held to, because an ending nobody can see
  // is worse than no ending.
  expect(seen.size, `${act} played no film`).toBeGreaterThanOrEqual(3);
  for (let i = 0; i < shots.length; i++) {
    const f = shots[i]!;
    const where = `${act} movement ${i + 1}`;
    expect(f.spread, `${where} is flat`).toBeGreaterThan(1.5);
    expect(f.mean, `${where} is black`).toBeGreaterThan(1.2);
    expect(f.mean, `${where} is blown out`).toBeLessThan(232);
  }
  // ...and the film really replaces the frame rather than sitting on it: the
  // last movement does not look like the first.
  expect(
    Math.abs(shots.at(-1)!.mean - shots[0]!.mean) +
      Math.abs(shots.at(-1)!.variety - shots[0]!.variety) * 100,
    `${act}'s ending never changes the picture`,
  ).toBeGreaterThan(1);
  return shots;
}

/** Opens the game with a run in progress, through the dev door. */
async function openRun(page: Page): Promise<void> {
  await page.goto('/?act=water&seed=4242');
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
}

/**
 * Slowblue: every ending, movement by movement.
 *
 * Seven acts, seven films, and not one of them is reachable by a unit test in
 * the only way that matters. `tests/films.test.ts` can prove that a film drew
 * finite geometry, that the ice stopped when the air did, and that the last
 * frame lands on act I's own shoal - and it proved all three while the frame was
 * capable of being unreadable, because a recording canvas has no idea what
 * anything looks like.
 */
test('shoots every movement of all seven endings', async ({ page }) => {
  test.setTimeout(300_000);
  const errors = collectErrors(page);
  await openRun(page);
  const report: string[] = [];
  for (const act of ACTS) await shootEnding(page, act, 'docs/screens/films', report);
  console.log(report.join('\n'));
  expect(errors).toEqual([]);
});
