import { expect, test, type Page } from '@playwright/test';
import { boot, collectErrors, metrics } from './helpers';

/**
 * The audio unlock handshake, in a real browser.
 *
 * The last uncovered claim in §2, and the one whose failure is hardest to see. An
 * `AudioContext` that never leaves `suspended` throws nothing, logs nothing and
 * renders identically - the game plays, the fish move, the score climbs, and there
 * is no sound. Every other bug in this engine has the same shape: a `contextCtor`
 * that came back null on an old WebView, a `resume()` that lost its race with a
 * tab switch, WebKit's undocumented `interrupted` state after a phone call, a
 * mixer that started at zero and stayed there. All of them are silence and none of
 * them is an error.
 *
 * So no assertion here is "it did not throw". Every one of them is either the
 * context's own state or `AudioEngine.voicesPlayed`, which counts voices that
 * actually reached a mixer track - the closest thing to a microphone a headless
 * probe has.
 *
 * ## What this adds, because it is less than it looks
 *
 * The plan for this said the handshake had no browser coverage at all, and that
 * turned out to be half wrong, which is worth writing down rather than quietly
 * working around. `smoke.spec.ts` already patches `AudioContext` to catch the
 * instance, asserts it reaches `running`, asserts `navigator.audioSession` is set
 * to `playback`, suspends it by hand and asserts a tap brings it back. **The state
 * machine was covered.**
 *
 * What nothing covered is the failure the plan actually described: a game that
 * runs, whose context says `running`, and which makes no sound. Every assertion
 * in `smoke.spec.ts` passes on an engine whose mixer never opened, whose bed deals
 * onto tracks that do not exist, or whose `contextCtor` handed back something that
 * accepts every call and plays nothing - because a state is not a sound.
 * `voicesPlayed` is, and it did not exist until now.
 *
 * So the three tests below are about audibility, and they take the page lifecycle
 * route (`visibilitychange`) rather than calling `suspend()` directly, because that
 * is the path a backgrounded WebView actually takes and it is the one `main.ts`
 * wires up.
 */

test('makes no sound until it is touched, and then makes some', async ({ page }) => {
  const errors = collectErrors(page);
  await page.goto('/?seed=4242');

  // Before any gesture nothing has played, and nothing can have.
  //
  // This used to assert there was no context at all (`audioState: 'none'`), on the
  // grounds that the engine builds one inside `unlock` and nothing in the boot path
  // should be calling it early. The boot path now does, deliberately: the moment
  // the studio ident clears, `main.ts` asks for the water, so that a desktop launch
  // - or any launch on a page the player has already touched - opens on a title
  // screen with a bed under it instead of a silent one. Where the browser says no,
  // which is here and on every phone, the ask costs nothing and leaves the context
  // sitting in `suspended`.
  //
  // So the claim is `unlocked`, which is the engine's own record of whether a
  // context has ever actually been allowed to run, and it is the one the shell
  // draws its corner button from. A `suspended` context is not a sound.
  const cold = await metrics(page);
  expect(cold.audioUnlocked).toBe(false);

  // ...and the proof that a suspended context is not a quiet one: the voice count
  // is not moving. `tick` is guarded on the context actually running, so a bed
  // that is dealing voices is a bed somebody could hear. The handful the count
  // opens at are the held ones - the pad, the shimmer, the ring - which are
  // connected once when the graph is built and are silent inside a context that
  // has never been allowed to start. A wait rather than a poll, because the claim
  // here is that nothing happens, and nothing takes a while to observe.
  await page.waitForTimeout(1000);
  expect((await metrics(page)).audioVoices).toBe(cold.audioVoices);

  // `boot` presses the title button, which is a real gesture on a real element,
  // and is the path every session takes.
  await boot(page, 4242);
  const started = await metrics(page);
  expect(started.audioState).toBe('running');
  expect(started.audioRunning).toBe(true);

  // ...and the graph is not merely running, it is being played. Polled rather than
  // sampled after a fixed wait, because every scheduler in this engine is Poisson
  // by design - the bed deals about two bubbles a second in act I and the interval
  // is redrawn after every one, so *how many arrive in two seconds* is a draw and
  // not a number. Waiting for the count to pass a floor asks the question this test
  // is actually asking; asserting on a fixed window asks the scheduler for a
  // guarantee it exists specifically not to give.
  await expect
    .poll(async () => Number((await metrics(page)).audioVoices), { timeout: 20_000 })
    .toBeGreaterThan(20);
  expect(errors).toEqual([]);
});

/** Backgrounds or foregrounds the page the way an OS does, and waits for the handler. */
async function setHidden(page: Page, hidden: boolean): Promise<void> {
  await page.evaluate((value) => {
    // `document.hidden` is what `main.ts` reads, and it is not derived from
    // `visibilityState` once either has been redefined - overriding only the
    // second is how this test first failed, against code that was correct.
    Object.defineProperty(document, 'hidden', { value, configurable: true });
    Object.defineProperty(document, 'visibilityState', {
      value: value ? 'hidden' : 'visible',
      configurable: true,
    });
    document.dispatchEvent(new Event('visibilitychange'));
  }, hidden);
}

/**
 * The WebView case, which is the one the whole handshake was written for: a
 * context taken away while the game is in the background, and what it takes to get
 * it back.
 *
 * The design here is deliberate and is the reason this test is shaped the way it
 * is. Backgrounding a *run* does not just park the audio graph, it pauses the
 * game - and coming back does **not** unpause it, because a player returning to a
 * game that is already moving has lost however much of it happened while they were
 * looking at their notifications. So the sound stays off until they say they are
 * ready, and the assertion in the middle of this test is that it stays off: a
 * resume that fired on its own would be a bug in the other direction.
 *
 * `resume()` goes through `ensureRunning`, which is where WebKit's `interrupted`
 * recovery lives, and it is asynchronous. A resume that quietly failed would leave
 * a game that plays in silence for the rest of the session with no way back short
 * of a reload.
 */
test('gives the sound back when the player comes back, and not before', async ({ page }) => {
  const errors = collectErrors(page);
  await boot(page, 4242);
  await page.waitForTimeout(1200);
  const before = Number((await metrics(page)).audioVoices);
  expect(before).toBeGreaterThan(0);

  // Backgrounded. The engine parks the graph rather than tearing it down, so the
  // bed the player was standing in is still there when they come back.
  await setHidden(page, true);
  await expect.poll(async () => (await metrics(page)).audioState, { timeout: 5000 }).toBe(
    'suspended',
  );
  expect((await metrics(page)).mode).toBe('paused');

  // Foregrounded, and still silent, because the run is still paused.
  await setHidden(page, false);
  await page.waitForTimeout(500);
  expect((await metrics(page)).audioState).toBe('suspended');
  const parked = Number((await metrics(page)).audioVoices);

  // ...and now the player says so.
  await page.keyboard.press('Escape');
  await expect.poll(async () => (await metrics(page)).audioState, { timeout: 5000 }).toBe(
    'running',
  );
  // The proof is not the state, it is that voices start arriving again - polled,
  // for the reason the first test gives. This is where that lesson was learnt: a
  // fixed 2.5 s window and a floor of five was asking whether a Poisson process at
  // 2.2/s would deliver more than five events in two and a half seconds, which is
  // very nearly a coin toss, and it came up tails on the run that mattered.
  await expect
    .poll(async () => Number((await metrics(page)).audioVoices), { timeout: 20_000 })
    .toBeGreaterThan(parked + 20);
  expect(errors).toEqual([]);
});

/**
 * The handshake is idempotent, which it has to be: `main.ts` calls `unlock()` from
 * a capture-phase `pointerdown` listener on the document, so it runs on *every*
 * touch for the whole session - and it must not rebuild the graph, restart the
 * bed, or spend anything doing nothing. Browsers also cap how many contexts a page
 * may hold, so a handshake that built one per tap would work for a minute and then
 * stop making sound at all.
 */
test('survives being unlocked on every touch for the rest of the session', async ({ page }) => {
  const errors = collectErrors(page);
  // Counted at the constructor, which is the only place the answer is unambiguous.
  // The first draft of this test asserted on `voicesPlayed` instead and could not
  // have worked: a rebuild routes six voices and the bed deals three to six on its
  // own in the same window, so the signal and the noise were the same size. A
  // browser gives out one `AudioContext` per unlock or it does not.
  await page.addInitScript(() => {
    const w = window as typeof window & { __contexts?: number };
    w.__contexts = 0;
    const Native = window.AudioContext;
    window.AudioContext = class extends Native {
      constructor() {
        super();
        w.__contexts = (w.__contexts ?? 0) + 1;
      }
    } as typeof AudioContext;
  });
  await boot(page, 4242);
  await page.waitForTimeout(600);

  for (let i = 0; i < 12; i++) {
    await page.mouse.click(120 + i * 8, 500 + i * 6);
  }
  expect((await metrics(page)).audioState).toBe('running');
  // One, after thirteen gestures. `main.ts` calls `unlock()` from a capture-phase
  // `pointerdown` on the document, so it runs on every touch for the whole session,
  // and a second context would mean two chords, two beds and two of everything -
  // audible immediately and impossible to attribute later.
  expect(await page.evaluate(() => (window as typeof window & { __contexts?: number }).__contexts))
    .toBe(1);
  expect(errors).toEqual([]);
});

/**
 * An iPhone older than iOS 17, which is the one phone `navigator.audioSession`
 * cannot reach: its Web Audio obeys the silent switch, and the only way out is a
 * media element playing. See `SilentLoop`.
 *
 * Chromium cannot be told to have a silent switch, so this cannot hear the fix -
 * it holds the part a browser can show: the loop is started by the tap that starts
 * the game, it is a real unmuted element (a muted one does not move WebKit's
 * session), and it stops when the game is backgrounded, which is what keeps the
 * page off the lock screen's Now Playing card.
 */
test.describe('on an iPhone that cannot declare a session', () => {
  test.use({
    userAgent:
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
  });

  test('plays a silent loop under the game, and stops it when the game is put away', async ({
    page,
  }) => {
    const errors = collectErrors(page);
    await page.addInitScript(() => {
      const w = window as typeof window & { __loops?: HTMLMediaElement[] };
      w.__loops = [];
      const play = HTMLMediaElement.prototype.play;
      HTMLMediaElement.prototype.play = function (this: HTMLMediaElement) {
        if (!w.__loops!.includes(this)) w.__loops!.push(this);
        return play.call(this);
      };
    });
    const loop = () =>
      page.evaluate(() => {
        const el = (window as typeof window & { __loops?: HTMLMediaElement[] }).__loops?.[0];
        return el === undefined
          ? null
          : {
              count: (window as typeof window & { __loops?: HTMLMediaElement[] }).__loops!.length,
              playing: !el.paused,
              loop: el.loop,
              muted: el.muted,
              volume: el.volume,
              wav: el.src.startsWith('data:audio/wav'),
            };
      });

    await page.goto('/?seed=4242');
    await page.waitForTimeout(800);
    // Nobody has touched the page: whatever was asked for, nothing is playing.
    expect((await loop())?.playing ?? false).toBe(false);

    await boot(page, 4242);
    await expect.poll(async () => (await loop())?.playing, { timeout: 5000 }).toBe(true);
    expect(await loop()).toMatchObject({
      count: 1,
      loop: true,
      muted: false,
      volume: 1,
      wav: true,
    });

    await setHidden(page, true);
    await expect.poll(async () => (await loop())?.playing, { timeout: 5000 }).toBe(false);

    await setHidden(page, false);
    await page.keyboard.press('Escape');
    await expect.poll(async () => (await loop())?.playing, { timeout: 5000 }).toBe(true);
    // Still the one element, after every gesture in between.
    expect((await loop())?.count).toBe(1);
    expect(errors).toEqual([]);
  });
});
