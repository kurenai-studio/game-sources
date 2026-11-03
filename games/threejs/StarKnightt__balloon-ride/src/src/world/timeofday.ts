// Copied from F:\bay-ride\src\world\timeofday.ts (Bay Ride). Adapted: four presets (sunrise, golden, sunset, blue), no lighthouse, water look folded in.
import * as THREE from "three";
import { G } from "../render/materials";
import { TOD_GRADE } from "../render/todUniforms";
import type { Post } from "../render/post";
import type { SunShadow } from "../render/lightpasses";

/**
 * Time of day: sunrise → golden hour → sunset → blue hour (T cycles them, golden is the default).
 * Each preset is a flat table of light / sky / cloud / water / grade values; the current state is
 * interpolated between presets and written into the shared uniforms (`G`, the grade pass, the
 * bloom pass).
 *
 * Derived from Bay Ride's six presets: sunrise = its morning (moved to the east), golden and
 * sunset unchanged, blue = its dusk. Noon and night dropped (balloons fly at dawn and dusk).
 *
 * Bearings: azimuth = atan2(x, z) in degrees; east (+X) is 90°. The sun rises in the east and the
 * evening sun sits low in the west-south-west.
 */
export const PRESETS = ["sunrise", "golden", "sunset", "blue"] as const;
export type Preset = (typeof PRESETS)[number];

type RGB = [number, number, number];
interface Look {
  az: number; // key light azimuth (the sun; the moon at night), degrees
  el: number; // true elevation of that light (sky glow, disk, clouds, shadows)
  shadeMin: number; // shading light never goes lower than this (keeps flat ground readable)
  /** 0…1: lit faces take the light's own hue and shade goes cool (low sun, moonlight). */
  keyHue: number;
  sun: RGB; shadow: RGB; rim: RGB;
  zenith: RGB; mid: RGB; horizon: RGB; fog: RGB; fogD: number;
  glow: RGB; glowA: number; glowB: number;
  haze: RGB; hazeA: number;
  hgl: RGB; hglA: number; hglF: number;
  cTop: RGB; cMid: RGB; cLow: RGB; cRim: RGB; cRimK: number; cBack: number; cUnder: RGB; cUnderA: number;
  /** Cirrus colour and strength. */
  wisp: RGB; wispA: number;
  disk: RGB; stars: number; night: number;
  world: RGB; far: RGB; farHaze: number;
  grade: RGB; sat: number;
  bloomS: number; bloomR: number; bloomT: number;
  moonAz: number; moonEl: number; moon: RGB;
  /** Water: body colours, reflection tint, glitter strength / colour, 0…1 glitter follows the moon. */
  wShallow: RGB; wDeep: RGB; wRefl: RGB; glint: number; glintCol: RGB; glintMoon: number;
  /** Glitter path width (facet slope spread) and the broad sheen under the light. */
  gSpread: number; gSheen: number;
  /** 1 at blue hour only: the twilight sky still lights the water (WATER_TOD). */
  dusk: number;
  evening: number;
  birds: number; // share of seabirds aloft
  /** 0…1 morning mist lying in the valleys (Balloon Ride: sunrise only). */
  mist: number;
}

/** Values the water (and lit windows) read for the current time of day. */
export interface WaterLook {
  shallow: THREE.Color;
  deep: THREE.Color;
  reflTint: THREE.Color;
  glitter: number;
  night: number;
}

/**
 * Time-of-day values only the water reads (Bay Ride's water/look.ts, folded in here). uDusk is 1 at
 * blue hour and 0 at every other preset, blended through the transitions.
 */
export const WATER_TOD = {
  uDusk: { value: 0 },
};

/** sRGB hex → linear (what `new THREE.Color(hex)` stores), optionally scaled. */
const hx = (hex: string, k = 1): RGB => {
  const c = new THREE.Color(hex);
  return [c.r * k, c.g * k, c.b * k];
};

const DEG = Math.PI / 180;

/**
 * Bay Ride's fog densities suit a ~1 km bay. The balloon sees ~6 km of countryside, so the same
 * per-preset densities are scaled down here (main.ts also deepens the haze's height scale, uFogH).
 */
export const FOG_SCALE = 0.4;

// Art direction: painted anime summer seaside. Saturated gradient skies, big sunlit cumulus with
// lavender shadow sides, warm rim light; the sea goes from clear turquoise shallows to deep blue,
// gold and rose at sunset, indigo with a moon path at night.
const LOOKS: Record<Preset, Look> = {
  // Sunrise (Bay Ride's morning, moved to the east): low peach key, long cool shadows, a pale teal
  // sky over a warm cream horizon.
  sunrise: {
    az: 78, el: 9, shadeMin: 15, keyHue: 0.15,
    sun: hx("#ffd9b4", 0.98), shadow: hx("#7b8ac4"), rim: hx("#ffd2a8", 1.35),
    zenith: hx("#208ca3"), mid: hx("#55b5ca"), horizon: hx("#f2dccc"), fog: hx("#dedfe2"), fogD: 0.001,
    glow: [1.0, 0.82, 0.62], glowA: 0.24, glowB: 0.36,
    haze: [0.97, 0.9, 0.86], hazeA: 0.5,
    hgl: hx("#ffd2b0"), hglA: 0.38, hglF: 8,
    // Balloon Ride: a real step from the peach-lit tops to a cool lilac-grey shade (the old mid tone
    // sat next to the top's value, so a front-lit puff read as one flat cream cut-out).
    cTop: [1.0, 0.89, 0.77], cMid: [0.68, 0.71, 0.82], cLow: [0.4, 0.45, 0.6], cRim: [1.0, 0.86, 0.72], cRimK: 0.6, cBack: 0.35,
    cUnder: [1.0, 0.8, 0.68], cUnderA: 0.25,
    wisp: [1.0, 0.93, 0.88], wispA: 0.5, disk: [1.7, 1.5, 1.2], stars: 0, night: 0,
    world: [1.02, 0.98, 0.94], far: [0.94, 0.95, 1.04], farHaze: 0.26,
    grade: [1.02, 1.0, 0.98], sat: 0.98,
    bloomS: 0.3, bloomR: 0.5, bloomT: 0.95,
    moonAz: -78, moonEl: 24, moon: [0.86, 0.88, 0.92],
    wShallow: hx("#86cfc6"), wDeep: hx("#326c9c"), wRefl: [1.0, 0.97, 0.95], glint: 0.55, glintCol: [1.0, 0.9, 0.78], glintMoon: 0,
    gSpread: 0.15, gSheen: 0.12,
    dusk: 0,
    evening: 0.25,
    birds: 1,
    mist: 1,
  },
  // Amber hour: deep teal-blue zenith over a gold sky, cream-gold clouds, warm water.
  golden: {
    az: -100, el: 12, shadeMin: 9, keyHue: 0.45,
    sun: hx("#ffca8e", 1.0), shadow: hx("#55708e"), rim: hx("#ffbe74", 1.7),
    zenith: hx("#4479aa"), mid: hx("#a6c0d0"), horizon: hx("#f8dcbc"), fog: hx("#f2d8bc"), fogD: 0.0013,
    glow: [1.0, 0.74, 0.42], glowA: 0.32, glowB: 0.5,
    haze: [1.0, 0.89, 0.76], hazeA: 0.4,
    hgl: hx("#ffc68e"), hglA: 0.62, hglF: 5,
    cTop: [1.0, 0.88, 0.66], cMid: [0.84, 0.72, 0.62], cLow: [0.62, 0.56, 0.6], cRim: [1.0, 0.82, 0.5], cRimK: 0.9, cBack: 0.7,
    cUnder: [1.0, 0.76, 0.48], cUnderA: 0.7,
    wisp: [1.0, 0.86, 0.66], wispA: 0.45, disk: [1.6, 1.3, 0.82], stars: 0, night: 0,
    world: [1.03, 0.99, 0.93], far: [1.0, 0.94, 0.98], farHaze: 0.22,
    grade: [1.02, 1.0, 0.98], sat: 1.04,
    bloomS: 0.26, bloomR: 0.5, bloomT: 1.05,
    moonAz: 0, moonEl: -30, moon: [0, 0, 0],
    wShallow: hx("#9aa088"), wDeep: hx("#3a5462"), wRefl: [1.12, 0.98, 0.84], glint: 1.0, glintCol: [1.0, 0.84, 0.56], glintMoon: 0,
    gSpread: 0.14, gSheen: 0.16,
    dusk: 0,
    evening: 0.8,
    birds: 1,
    mist: 0,
  },
  // Sun on the horizon: cool grey-violet cloud bodies with orange-gold undersides and rims.
  sunset: {
    az: -112, el: 4.5, shadeMin: 6, keyHue: 0.45,
    sun: hx("#ffa676", 0.92), shadow: hx("#5f5596"), rim: hx("#ff9448", 2.1),
    zenith: hx("#2c5078"), mid: hx("#c08ca4"), horizon: hx("#ffab68"), fog: hx("#8a76a2"), fogD: 0.0008,
    glow: [1.0, 0.6, 0.28], glowA: 0.4, glowB: 0.55,
    haze: [1.0, 0.66, 0.42], hazeA: 0.38,
    hgl: hx("#ff8a5c"), hglA: 0.6, hglF: 5,
    cTop: [0.46, 0.33, 0.38], cMid: [0.3, 0.22, 0.3], cLow: [0.18, 0.14, 0.23], cRim: [1.0, 0.62, 0.28], cRimK: 0.9, cBack: 0.7,
    cUnder: [1.0, 0.5, 0.2], cUnderA: 0.95,
    wisp: [1.0, 0.62, 0.48], wispA: 0.45, disk: [2.0, 1.55, 1.05], stars: 0, night: 0.3,
    world: [0.94, 0.84, 0.8], far: [0.5, 0.4, 0.62], farHaze: 0.2,
    grade: [1.02, 0.98, 0.96], sat: 1.05,
    bloomS: 0.3, bloomR: 0.45, bloomT: 1.05,
    moonAz: 0, moonEl: -30, moon: [0, 0, 0],
    wShallow: hx("#9a90a2"), wDeep: hx("#2a3868"), wRefl: [1.05, 0.9, 0.85], glint: 1.0, glintCol: [1.0, 0.66, 0.38], glintMoon: 0,
    gSpread: 0.12, gSheen: 0.14,
    dusk: 0,
    evening: 0.95,
    birds: 0.5,
    mist: 0,
  },
  // Blue hour (Bay Ride's dusk): dark slate clouds with thin pink rims, the first stars high up,
  // windows lit, water that still holds the twilight.
  blue: {
    az: -116, el: -3, shadeMin: 18, keyHue: 0.4,
    sun: hx("#535d96"), shadow: hx("#40497a"), rim: hx("#ff9a6a", 0.7),
    zenith: hx("#141a46"), mid: hx("#3a4c7c"), horizon: hx("#dd8e6c"), fog: hx("#343c66"), fogD: 0.0009,
    glow: [1.0, 0.55, 0.35], glowA: 0.18, glowB: 0.12,
    haze: [0.56, 0.45, 0.56], hazeA: 0.3,
    hgl: hx("#ff9a60"), hglA: 0.55, hglF: 14,
    cTop: [0.3, 0.27, 0.4], cMid: [0.2, 0.2, 0.33], cLow: [0.11, 0.12, 0.23], cRim: [1.0, 0.5, 0.6], cRimK: 0.95, cBack: 0.6,
    cUnder: [0.9, 0.42, 0.5], cUnderA: 0.55,
    wisp: [0.16, 0.13, 0.22], wispA: 0.25, disk: [0, 0, 0], stars: 0.45, night: 1,
    world: [0.4, 0.44, 0.64], far: [0.32, 0.34, 0.56], farHaze: 0.3,
    grade: [0.97, 0.98, 1.04], sat: 1.05,
    bloomS: 0.6, bloomR: 0.55, bloomT: 0.85,
    moonAz: -62, moonEl: 11, moon: [0.95, 0.88, 0.72],
    wShallow: hx("#6e78ae"), wDeep: hx("#4e4e92"), wRefl: [1.0, 1.0, 1.0], glint: 0.25, glintCol: [1.0, 0.62, 0.45], glintMoon: 0,
    gSpread: 0.12, gSheen: 0.1,
    dusk: 1,
    evening: 1.0,
    birds: 0,
    mist: 0,
  },
};

/** a→b by k, written into `out` (reused every frame: no per-frame allocation). */
function mix(a: Look, b: Look, k: number, out: Look): Look {
  const o = out as unknown as Record<string, number | RGB>;
  for (const key of Object.keys(a) as (keyof Look)[]) {
    const x = a[key], y = b[key];
    if (Array.isArray(x)) {
      const r = o[key] as RGB, yy = y as RGB;
      for (let i = 0; i < 3; i++) r[i] = x[i] + (yy[i] - x[i]) * k;
    } else o[key] = (x as number) + ((y as number) - (x as number)) * k;
  }
  return out;
}

const cloneLook = (l: Look): Look => {
  const o = { ...l } as unknown as Record<string, number | RGB>;
  for (const k in o) if (Array.isArray(o[k])) o[k] = [...(o[k] as RGB)] as RGB;
  return o as unknown as Look;
};

const dirFrom = (v: THREE.Vector3, azDeg: number, elDeg: number) => {
  const a = azDeg * DEG, e = elDeg * DEG;
  return v.set(Math.sin(a) * Math.cos(e), Math.sin(e), Math.cos(a) * Math.cos(e));
};

/** Seconds for a preset transition, and for the full timelapse (sunrise → blue). */
const TRANSITION = 3;
const TIMELAPSE = 60;

export function parsePreset(s: string | null | undefined): Preset | null {
  if (!s) return null;
  const k = s.toLowerCase().replace(/[^a-z]/g, "");
  if (k === "goldenhour") return "golden";
  if (k === "bluehour" || k === "dusk") return "blue";
  if (k === "morning" || k === "dawn") return "sunrise";
  return (PRESETS as readonly string[]).includes(k) ? (k as Preset) : null;
}

/** The look the game opens in, read from the URL by the same rules as main.ts (the loader paints it). */
export function bootPreset(search: string = location.search): Preset {
  const q = new URLSearchParams(search);
  if (q.get("timelapse") === "1") return "sunrise";
  return parsePreset(q.get("tod") ?? q.get("time")) ?? "golden";
}

export class TimeOfDay {
  private readonly looks: Look[] = PRESETS.map((p) => LOOKS[p]);
  private from: Look;
  private to: Look;
  private k = 1;
  private idx: number;
  private cur: Look;
  private lapse: boolean;
  private lapseT = 0;
  /** Scratch look the transitions/timelapse blend into. */
  private readonly blend: Look;
  private lapseDone = false;
  private dirty = true;
  private readonly shadowDir = new THREE.Vector3();
  private readonly listeners: ((p: Preset) => void)[] = [];
  private readonly _water: WaterLook = {
    shallow: new THREE.Color(), deep: new THREE.Color(), reflTint: new THREE.Color(), glitter: 0, night: 0,
  };

  constructor(private post: Post, private shadow: SunShadow, start: Preset, timelapse = false) {
    this.idx = PRESETS.indexOf(start);
    this.cur = this.from = this.to = this.looks[this.idx];
    this.blend = cloneLook(this.looks[0]);
    this.lapse = timelapse;
    if (this.lapse) this.idx = 0;
    this.apply(this.lapse ? this.looks[0] : this.cur);
  }

  get preset(): Preset {
    return PRESETS[this.idx];
  }
  get evening(): number {
    return this.cur.evening;
  }
  get birds(): number {
    return this.cur.birds;
  }
  get night(): number {
    return this.cur.night;
  }
  /** Water colours, reflection tint, glitter strength and the night flag. */
  get water(): WaterLook {
    const w = this._water, l = this.cur;
    w.shallow.setRGB(...l.wShallow);
    w.deep.setRGB(...l.wDeep);
    w.reflTint.setRGB(...l.wRefl);
    w.glitter = l.glint;
    w.night = l.night;
    return w;
  }

  onChange(fn: (p: Preset) => void): void {
    this.listeners.push(fn);
  }

  /** Next preset (wraps blue → sunrise), with a smooth transition from wherever we are now. */
  cycle(): void {
    this.set(PRESETS[(this.idx + 1) % PRESETS.length]);
  }

  set(p: Preset, instant = false): void {
    this.lapse = false;
    this.idx = PRESETS.indexOf(p);
    // `cur` may be the scratch blend: freeze a copy as the start of the new transition.
    this.from = cloneLook(this.cur);
    this.to = this.looks[this.idx];
    this.k = instant ? 1 : 0;
    if (instant) this.cur = this.to;
    this.dirty = true;
    for (const fn of this.listeners) fn(p);
  }

  /** Continuous 0…3 position along sunrise → … → blue. */
  private along(s: number): Look {
    const n = this.looks.length - 1;
    const i = Math.min(n - 1, Math.floor(s));
    const f = s - i;
    return mix(this.looks[i], this.looks[i + 1], f * f * (3 - 2 * f) * 0.35 + f * 0.65, this.blend);
  }

  update(dt: number): void {
    const n = this.looks.length - 1;
    if (this.lapse && !this.lapseDone) {
      this.lapseT += dt;
      const s = Math.min(n, Math.max(0, ((this.lapseT - 2) / (TIMELAPSE - 4)) * n));
      this.cur = this.along(s);
      this.idx = Math.min(n, Math.round(s));
      if (s >= n) {
        this.lapseDone = true;
        this.cur = this.looks[n];
      }
      this.dirty = true;
    } else if (this.k < 1) {
      this.k = Math.min(1, this.k + dt / TRANSITION);
      const e = this.k * this.k * (3 - 2 * this.k);
      this.cur = this.k >= 1 ? this.to : mix(this.from, this.to, e, this.blend);
      this.dirty = true;
    }
    if (this.dirty) {
      this.apply(this.cur);
      this.dirty = false;
    }
  }

  private apply(l: Look): void {
    dirFrom(G.uSkySun.value, l.az, l.el);
    dirFrom(G.uSunDir.value, l.az, Math.max(l.el, l.shadeMin));
    // Shadows follow the true light but never from below the horizon.
    this.shadow.dir = dirFrom(this.shadowDir, l.az, Math.max(l.el, 3));
    G.uSunColor.value.setRGB(...l.sun);
    G.uShadowTint.value.setRGB(...l.shadow);
    G.uRimColor.value.setRGB(...l.rim);
    G.uSkyZenith.value.setRGB(...l.zenith);
    G.uSkyMid.value.setRGB(...l.mid);
    G.uSkyHorizon.value.setRGB(...l.horizon);
    G.uFogColor.value.setRGB(...l.fog);
    G.uFogDensity.value = l.fogD * FOG_SCALE;
    G.uMist.value = l.mist;
    G.uSunGlow.value.setRGB(...l.glow);
    G.uSunGlowAmt.value.set(l.glowA, l.glowB);
    G.uHaze.value.setRGB(...l.haze);
    G.uHazeAmt.value = l.hazeA;
    G.uHorizGlow.value.setRGB(...l.hgl);
    G.uHorizGlowK.value.set(l.hglA, l.hglF);
    G.uCloudTop.value.setRGB(...l.cTop);
    G.uCloudMid.value.setRGB(...l.cMid);
    G.uCloudLow.value.setRGB(...l.cLow);
    G.uCloudRim.value.setRGB(...l.cRim);
    G.uCloudK.value.set(l.cRimK, l.cBack, l.cUnderA);
    G.uCloudUnder.value.setRGB(...l.cUnder);
    G.uKeyHue.value = l.keyHue;
    G.uWisp.value.setRGB(...l.wisp);
    G.uWispAmt.value = l.wispA;
    G.uSunDisk.value.setRGB(...l.disk);
    G.uStars.value = l.stars;
    G.uNight.value = l.night;
    G.uWorldTint.value.setRGB(...l.world);
    G.uFarTint.value.setRGB(...l.far);
    G.uFarHaze.value = l.farHaze;
    dirFrom(G.uMoonDir.value, l.moonAz, l.moonEl);
    G.uMoonCol.value.setRGB(...l.moon);
    G.uGlint.value = l.glint;
    G.uGlintDir.value.copy(G.uSkySun.value).lerp(G.uMoonDir.value, l.glintMoon).normalize();
    G.uGlintCol.value.setRGB(...l.glintCol);
    G.uGlintShape.value.set(l.gSpread, l.gSheen);
    // Clouds are lit by the sun (even just below the horizon at dusk), by the moon at night.
    G.uCloudLight.value.copy(G.uGlintDir.value);
    G.uWaterShallow.value.setRGB(...l.wShallow);
    G.uWaterDeep.value.setRGB(...l.wDeep);
    G.uWaterRefl.value.setRGB(...l.wRefl);
    WATER_TOD.uDusk.value = l.dusk;
    TOD_GRADE.uGradeMul.value.setRGB(...l.grade);
    TOD_GRADE.uSat.value = l.sat;
    this.post.bloom.strength = l.bloomS;
    this.post.bloom.radius = l.bloomR;
    this.post.bloom.threshold = l.bloomT;
  }
}
