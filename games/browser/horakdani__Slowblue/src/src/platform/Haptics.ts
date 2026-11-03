/**
 * Slowblue: every buzz the game has, named, in one table, behind one seam.
 *
 * Two problems, one file. The first is that the millisecond patterns were written
 * out at the eleven places that fired them, so "what does a caught ring feel like"
 * was a question you answered by reading a switch statement, and two cues that
 * were meant to feel the same only did by coincidence. The second is that
 * `navigator.vibrate` is one answer and not the only one: iOS Safari has never
 * implemented it, so on a large share of the phones this game is played on, all
 * eleven of those calls are no-ops. Any host with a real haptic engine is one
 * call away from replacing it - but only if there is a single place to hand it to.
 *
 * So: a cue is a name, the table says what that name feels like, and a driver
 * turns that into whatever the host can actually do. The web driver replays the
 * pattern; an engine-backed one would read `impact` instead and call its own engine,
 * because Core Haptics and the Android `HapticFeedbackConstants` do not take
 * millisecond arrays - they take a weight. Carrying both in the table is what
 * makes the swap a driver, not a rewrite: a driver reads whichever column its
 * host understands - the weight to choose a generator, the pattern to put the
 * pulses back where the table wanted them.
 *
 * There is deliberately no Haptics *setting* in front of this, and there was one
 * once. What it turned off is a few milliseconds of buzz on a hit; what it cost
 * was a row in a list that every player scrolled past to reach something else. A
 * phone that does not want to buzz says so at the OS level, and `navigator
 * .vibrate` - like any engine that could sit behind this seam - is already a no-op
 * there, which is the answer that switch was duplicating.
 */

/** What a cue feels like, in the two vocabularies that exist. */
export interface HapticCue {
  /**
   * Web: on/off milliseconds, the `navigator.vibrate` pattern.
   *
   * Frozen and shared. These used to be array literals at the call sites, which
   * meant `handleEvents` allocated a fresh array every time a fish was rescued -
   * small, but it was on the one path the zero-GC rule is about.
   */
  readonly pattern: readonly number[];
  /**
   * For an engine-backed driver: the weight a platform haptic engine takes instead of a pattern.
   *
   * The names are the intersection of what iOS (`UIImpactFeedbackGenerator`,
   * `UINotificationFeedbackGenerator`) and Android (`HapticFeedbackConstants`)
   * both express, and the vocabulary native haptic APIs take.
   */
  readonly impact: 'light' | 'medium' | 'heavy' | 'success' | 'warning';
}

/**
 * The dictionary. Every buzz in the game is one of these eleven.
 *
 * The scale is the design: a rescue is the lightest thing the hand can feel
 * because it happens constantly, a bite is the heaviest single knock because it
 * is the only thing in the game that hurts, and the two endings are the only cues
 * allowed three pulses - the hand should be able to tell an act ending from a
 * ring going by without looking.
 */
export const HAPTIC_CUES = {
  /** A fish reaches the ring. The most frequent cue in the game, so the smallest. */
  rescue: { pattern: [18], impact: 'light' },
  /** The shoal comes back together after being scattered. Relief, not reward. */
  reform: { pattern: [14, 40, 22], impact: 'medium' },
  /** A hunter connects. The one knock that means something went wrong. */
  bite: { pattern: [26, 30, 14], impact: 'heavy' },
  /** A station is cleared mid-act. A tick, not an event. */
  level: { pattern: [12], impact: 'light' },
  /** A ring is completed. */
  ring: { pattern: [12, 26, 16], impact: 'medium' },
  /** A ring closed without the shoal in it. The only warning-weight cue. */
  ringLost: { pattern: [40, 60, 40], impact: 'warning' },
  /**
   * The station begins again, in the four acts where a failure does that instead
   * of ending the run.
   *
   * Two pulses rather than one, because the hand has to be able to tell it from
   * `level` without looking: those two are the only cues that mean "you are at
   * the start of a station", and they mean opposite things about how you got
   * there. Medium rather than warning - `ringLost` owns that weight, and a
   * restart is a setback the game has already decided to forgive.
   */
  restart: { pattern: [22, 50, 22], impact: 'medium' },
  /** The act's last section falls. */
  complete: { pattern: [20, 60, 20, 60, 40], impact: 'success' },
  /** One act of a campaign hands over to the next, with no screen in between. */
  actHandover: { pattern: [20, 60, 20], impact: 'success' },
  /** Seven acts, trench floor to trench floor. The longest thing the hand gets. */
  circuitClosed: { pattern: [20, 60, 20, 60, 40], impact: 'success' },
  /** Any run ending at all, under whatever else the ending is saying. */
  runEnd: { pattern: [35], impact: 'medium' },
} as const satisfies Record<string, HapticCue>;

export type HapticCueName = keyof typeof HAPTIC_CUES;

/** The seam. A shell with a real haptic engine implements this and hands it over. */
export interface HapticsDriver {
  play(cue: HapticCue): void;
}

/**
 * The web driver: `navigator.vibrate`, guarded twice.
 *
 * The feature test is not enough on its own. Some Android WebViews expose the
 * method and throw out of it when the page has never been interacted with, and a
 * thrown haptic must not be able to take a frame's event handling with it.
 */
export const webHaptics: HapticsDriver = {
  play(cue: HapticCue): void {
    if (typeof navigator === 'undefined' || typeof navigator.vibrate !== 'function') return;
    try {
      // `vibrate` does not accept a readonly array in the DOM types and does not
      // hold onto the one it is given, so this cast is the whole cost of keeping
      // the table immutable.
      navigator.vibrate(cue.pattern as number[]);
    } catch {
      /* a phone that will not buzz is still a phone that plays */
    }
  },
};

let driver: HapticsDriver = webHaptics;

/** Hands the game's haptics to another driver (the tests do). The one call a host has to make. */
export function setHapticsDriver(next: HapticsDriver): void {
  driver = next;
}

/** Fires a named cue. Everything in the game that buzzes goes through here. */
export function haptic(name: HapticCueName): void {
  driver.play(HAPTIC_CUES[name]);
}
