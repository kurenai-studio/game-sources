// Intro cutscene: pure timeline, caption sequencing, camera path and skip handling. No DOM or three.js,
// so everything is unit tested in intro.test.ts. The engine drives the camera from cameraAt(); the UI shows captionAt().

export type Vec3 = [number, number, number];

export interface Caption {
  start: number;
  end: number;
  text: string;
}

/** Full version: a slow fly-over of the harbour and town at dusk, about 22 seconds. */
export const INTRO_DURATION = 22;
export const INTRO_CAPTIONS: Caption[] = [
  { start: 0.8, end: 4.6, text: "Malacca, July 1511." },
  { start: 5.4, end: 9.6, text: "A Portuguese fleet lies in the roads." },
  { start: 10.4, end: 14.8, text: "Their battery commands the bridge, and its guns may turn on the town." },
  { start: 15.4, end: 18.8, text: "The elder Hang Tuah has chosen you, Pendekar." },
  { start: 19.0, end: 21.2, text: "Silence the Kapitan. Leave by the jetty." },
];

/** prefers-reduced-motion version: a still view with the same captions, shorter, fading in and out. */
export const REDUCED_DURATION = 12;
export const REDUCED_CAPTIONS: Caption[] = [
  { start: 0.6, end: 2.8, text: "Malacca, July 1511." },
  { start: 2.8, end: 5.0, text: "A Portuguese fleet lies in the roads." },
  { start: 5.0, end: 7.4, text: "Their battery commands the bridge, and its guns may turn on the town." },
  { start: 7.4, end: 9.6, text: "The elder Hang Tuah has chosen you, Pendekar." },
  { start: 9.6, end: 11.6, text: "Silence the Kapitan. Leave by the jetty." },
];

/** seconds a caption takes to fade in and out */
export const CAPTION_FADE = 0.6;
/** seconds of fade from/to black at the very start and end */
export const EDGE_FADE = 0.9;

export function introDuration(reduced: boolean): number {
  return reduced ? REDUCED_DURATION : INTRO_DURATION;
}
export function introCaptions(reduced: boolean): Caption[] {
  return reduced ? REDUCED_CAPTIONS : INTRO_CAPTIONS;
}

export interface CaptionView {
  index: number;
  text: string;
  /** 0..1 */
  opacity: number;
}

/** The caption to show at time t with its fade opacity, or null between captions. */
export function captionAt(t: number, reduced = false): CaptionView | null {
  const caps = introCaptions(reduced);
  for (let i = 0; i < caps.length; i++) {
    const c = caps[i];
    if (t < c.start || t >= c.end) continue;
    const fade = Math.min(CAPTION_FADE, (c.end - c.start) / 2);
    const o = Math.min((t - c.start) / fade, (c.end - t) / fade, 1);
    return { index: i, text: c.text, opacity: Math.max(0, o) };
  }
  return null;
}

/** Black overlay alpha: 1 at the very start, 0 in the middle, back to 1 at the end. */
export function fadeAt(t: number, reduced = false): number {
  const d = introDuration(reduced);
  const a = Math.min(Math.max(t / EDGE_FADE, 0), 1);
  const b = Math.min(Math.max((d - t) / EDGE_FADE, 0), 1);
  return 1 - Math.min(a, b);
}

// ---------------------------------------------------------------- camera path

export interface CamKey {
  /** normalised time 0..1 */
  u: number;
  pos: Vec3;
  look: Vec3;
}

// World layout (see level.ts): the town is about +-33 wide with the player start in the south-west corner (+z),
// the jetty and harbour lie to the north (-z) and the foreign carrack rides at anchor around (-26, -85).
// The last key matches the gameplay camera at the mission start so the cut into play is seamless.
export const CAMERA_KEYS: CamKey[] = [
  { u: 0, pos: [22, 4.5, -64], look: [-26, 6, -85] },
  { u: 0.22, pos: [10, 5.5, -54], look: [-24, 6, -82] },
  { u: 0.5, pos: [1, 8.5, -32], look: [0, 4, -2] },
  { u: 0.75, pos: [-14, 17, 6], look: [-6, 3, 8] },
  { u: 1, pos: [-34.8, 3.4, 35.4], look: [-31.2, 1.55, 31.8] },
];
/** the still frame used by the reduced-motion version: the town and harbour from the jetty side */
export const STILL_KEY: CamKey = { u: 0, pos: [8, 9, -34], look: [-4, 4, -8] };

const smooth = (x: number) => x * x * (3 - 2 * x);
const mix = (a: Vec3, b: Vec3, k: number): Vec3 => [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k];

export interface CamPose {
  pos: Vec3;
  look: Vec3;
}

/** Camera pose at time t. Eased between keys; the reduced version is a fixed pose. */
export function cameraAt(t: number, reduced = false, keys: CamKey[] = CAMERA_KEYS): CamPose {
  if (reduced) return { pos: STILL_KEY.pos, look: STILL_KEY.look };
  const u = Math.min(Math.max(t / INTRO_DURATION, 0), 1);
  if (u <= keys[0].u) return { pos: keys[0].pos, look: keys[0].look };
  for (let i = 1; i < keys.length; i++) {
    const a = keys[i - 1];
    const b = keys[i];
    if (u <= b.u) {
      const k = smooth((u - a.u) / (b.u - a.u));
      if (k >= 1) return { pos: b.pos, look: b.look };
      return { pos: mix(a.pos, b.pos, k), look: mix(a.look, b.look, k) };
    }
  }
  const last = keys[keys.length - 1];
  return { pos: last.pos, look: last.look };
}

// ---------------------------------------------------------------- playback state

export interface IntroState {
  t: number;
  reduced: boolean;
  skipped: boolean;
  /** finished by reaching the end or by skipping; the caller reacts to this exactly once */
  done: boolean;
}

export function startIntro(reduced = false): IntroState {
  return { t: 0, reduced, skipped: false, done: false };
}

export function advanceIntro(s: IntroState, dt: number): IntroState {
  if (s.done) return s;
  const t = s.t + (Number.isFinite(dt) && dt > 0 ? dt : 0);
  return t >= introDuration(s.reduced) ? { ...s, t: introDuration(s.reduced), done: true } : { ...s, t };
}

export function skipIntro(s: IntroState): IntroState {
  return s.done ? s : { ...s, skipped: true, done: true };
}

/** Keys that skip the cutscene. */
export function isSkipKey(code: string): boolean {
  return code === "Escape" || code === "Space" || code === "Enter" || code === "NumpadEnter";
}
