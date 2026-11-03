import { expect, test } from '@playwright/test';
import { boot } from './helpers';

/**
 * Slowblue: how loud the game actually is, measured at the last node before the
 * speakers.
 *
 * Nothing in this repo measured the output level until a player reported that the
 * game was far too quiet in a browser. The bed was settling near -45 dBFS RMS with
 * peaks near -30: every voice had been mixed against every other and none against
 * the room it would be played in, so the whole game sat 15 to 20 dB under any page
 * a browser plays. This pins the level to a band, and the band is wide on purpose -
 * it exists to catch a master gain that is off by a factor of three, not to argue
 * about two decibels. The upper bound is the clipping guard: it is what the limiter
 * behind the compressor is for.
 *
 * The tap is installed before the page loads and sits on whatever is connected to
 * `destination`, so it reads what the converter is given and not what a voice
 * intended to say.
 */
test('the bed is audible, and nothing reaches the converter hot enough to clip', async ({ page }) => {
  await page.addInitScript(() => {
    const w = window as unknown as {
      __taps: AnalyserNode[];
      __level: () => { rms: number; peak: number };
    };
    w.__taps = [];
    const connect = AudioNode.prototype.connect as (this: AudioNode, ...a: unknown[]) => unknown;
    AudioNode.prototype.connect = function (this: AudioNode, ...args: unknown[]): unknown {
      if (args[0] === this.context.destination && !w.__taps.some((t) => t.context === this.context)) {
        const tap = this.context.createAnalyser();
        tap.fftSize = 2048;
        tap.smoothingTimeConstant = 0;
        connect.call(this, tap);
        w.__taps.push(tap);
      }
      return connect.apply(this, args);
    } as typeof AudioNode.prototype.connect;
    w.__level = () => {
      const buf = new Float32Array(2048);
      let sum = 0;
      let peak = 0;
      for (const tap of w.__taps) {
        tap.getFloatTimeDomainData(buf);
        for (const v of buf) {
          sum += v * v;
          peak = Math.max(peak, Math.abs(v));
        }
      }
      return { rms: Math.sqrt(sum / buf.length), peak };
    };
  });

  await boot(page);
  const vp = page.viewportSize()!;
  // The bed fades in over a few seconds under the first touch; read it settled.
  await page.mouse.move(vp.width * 0.5, vp.height * 0.7);
  await page.mouse.down();
  await page.mouse.move(vp.width * 0.6, vp.height * 0.5, { steps: 6 });
  await page.mouse.up();
  await page.waitForTimeout(7000);

  let sumSq = 0;
  let n = 0;
  let peak = 0;
  for (let i = 0; i < 40; i++) {
    const l = await page.evaluate(() => (window as unknown as { __level: () => { rms: number; peak: number } }).__level());
    sumSq += l.rms * l.rms;
    n++;
    peak = Math.max(peak, l.peak);
    await page.waitForTimeout(100);
  }
  const db = (x: number): number => 20 * Math.log10(Math.max(x, 1e-9));
  const rmsDb = db(Math.sqrt(sumSq / n));
  const peakDb = db(peak);
  console.log(`[loudness] settled bed: rms ${rmsDb.toFixed(1)} dBFS, peak ${peakDb.toFixed(1)} dBFS`);

  expect(rmsDb, 'the bed is too quiet to hear at a comfortable volume').toBeGreaterThan(-30);
  expect(rmsDb, 'the bed is too loud for a game about patience').toBeLessThan(-8);
  expect(peakDb, 'the limiter is not holding').toBeLessThan(-0.5);
});
