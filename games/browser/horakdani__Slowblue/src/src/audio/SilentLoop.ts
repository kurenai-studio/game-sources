/**
 * A media element playing nothing, so that an older iPhone plays the game.
 *
 * WebKit puts Web Audio in the same audio-session category as a ringtone: the
 * hardware silent switch mutes it. iOS 17 gave pages `navigator.audioSession`,
 * and `setAudioSession` in `AudioEngine` asks it for `playback`, which is the
 * whole fix where it exists. Where it does not, the one thing a page can do that
 * moves WebKit's session into the category the switch does not touch is to play
 * an `HTMLMediaElement` - and once that session is active, Web Audio rides in it.
 * So this plays half a second of silence on a loop for as long as the game wants
 * to be heard. It is the long-standing workaround, and it is only ever built on
 * the one platform that needs it: everywhere else a looping media element is a
 * cost with no upside, and on Android it can earn a media notification.
 *
 * Three details that each break it on their own, so they are written down:
 *
 *   * the element must not be `muted` and its volume must not be zero - WebKit
 *     only switches category for media it believes is audible, so the silence
 *     has to be in the samples, not in the element;
 *   * the first `play()` must happen inside a real gesture; after that one, the
 *     same element may be started again without one, which is what lets `resume`
 *     bring it back after the tab returns;
 *   * it is paused whenever the game parks, because a playing media element is
 *     what puts a page on the lock screen's Now Playing card.
 */
export class SilentLoop {
  private el: HTMLAudioElement | null = null;
  /** True once a `play()` has actually resolved, not merely been asked for. */
  private playing = false;
  private readonly enabled: boolean;

  constructor() {
    this.enabled = needsSilentLoop();
  }

  /** Whether this platform gets the loop at all. For the tests and the debug surface. */
  get active(): boolean {
    return this.enabled;
  }

  /**
   * Plays the loop if the game is audible, pauses it if not. Safe to call on every
   * touch: a loop already playing is left alone.
   *
   * The `playing` flag rather than `el.paused`, because `paused` goes false the
   * moment `play()` is *called*. A first attempt from a `pointerdown` - which on a
   * touch screen is not a gesture, and is rejected - would otherwise make the
   * `touchend` right behind it believe the loop was already running.
   */
  hold(audible: boolean): void {
    if (!this.enabled) return;
    if (!audible) {
      this.release();
      return;
    }
    const el = this.element();
    if (el === null || (this.playing && !el.paused)) return;
    try {
      void el.play().then(
        () => {
          this.playing = true;
        },
        () => {
          this.playing = false;
        },
      );
    } catch {
      this.playing = false;
    }
  }

  release(): void {
    this.playing = false;
    if (this.el !== null && !this.el.paused) this.el.pause();
  }

  dispose(): void {
    this.release();
    if (this.el !== null) {
      this.el.removeAttribute('src');
      this.el.load();
      this.el = null;
    }
  }

  private element(): HTMLAudioElement | null {
    if (this.el !== null) return this.el;
    if (typeof document === 'undefined') return null;
    const el = document.createElement('audio');
    el.src = silentWavDataUri();
    el.loop = true;
    el.preload = 'auto';
    el.setAttribute('playsinline', '');
    el.setAttribute('x-webkit-airplay', 'deny');
    el.disableRemotePlayback = true;
    this.el = el;
    return el;
  }
}

/**
 * iOS and iPadOS without the Audio Session API.
 *
 * iPadOS reports itself as a Mac, so a touch-capable "Macintosh" counts; no Mac
 * has a touch screen. Every iOS browser is WebKit underneath, so this covers
 * Chrome and Firefox on an iPhone as well as Safari - which is exactly the set
 * that was silent.
 */
export function needsSilentLoop(): boolean {
  const nav = globalThis.navigator as (Navigator & { audioSession?: unknown }) | undefined;
  if (nav === undefined || typeof document === 'undefined') return false;
  if (nav.audioSession !== undefined) return false;
  const ua = nav.userAgent ?? '';
  return /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && (nav.maxTouchPoints ?? 0) > 1);
}

/**
 * Half a second of 8 kHz, 8-bit mono silence as a WAV data URI.
 *
 * Built rather than pasted, because a base64 blob in the source is something
 * nobody can review. Unsigned 8-bit PCM is silent at 128, not 0 - a buffer of
 * zeros would be a full-scale DC offset, inaudible on most speakers and not on all.
 */
export function silentWavDataUri(): string {
  const rate = 8000;
  const samples = rate / 2;
  const bytes = new Uint8Array(44 + samples);
  const view = new DataView(bytes.buffer);
  const ascii = (at: number, s: string): void => {
    for (let i = 0; i < s.length; i++) bytes[at + i] = s.charCodeAt(i);
  };
  ascii(0, 'RIFF');
  view.setUint32(4, 36 + samples, true);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, true); // fmt chunk size
  view.setUint16(20, 1, true); // PCM
  view.setUint16(22, 1, true); // mono
  view.setUint32(24, rate, true);
  view.setUint32(28, rate, true); // byte rate: one byte per sample
  view.setUint16(32, 1, true); // block align
  view.setUint16(34, 8, true); // bits per sample
  ascii(36, 'data');
  view.setUint32(40, samples, true);
  bytes.fill(128, 44);
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return `data:audio/wav;base64,${btoa(bin)}`;
}
