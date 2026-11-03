/**
 * Render quality tier. Replaces Bay Ride's platform.ts TIER (F:\bay-ride\src\platform.ts) with only
 * the settings the reused modules read, plus the renderer/post ones main.ts needs. Desktop values
 * are Bay Ride's own. The phone values are Bay Ride's phone tier, and Balloon Ride has not re-tuned
 * them yet.
 *
 * `?mobile=1` / `?mobile=0` forces a tier. `?tier=key:value,...` overrides single settings, e.g.
 * `?tier=msaa:0,shadow:1024`.
 */
const params = new URLSearchParams(typeof location === "undefined" ? "" : location.search);
const ua = typeof navigator === "undefined" ? "" : navigator.userAgent;
const mm = (q: string) => typeof matchMedia === "function" && matchMedia(q).matches;
const HANDHELD = /iPhone|iPad|iPod|Android|Mobile|Silk|Kindle/.test(ua) || (mm("(pointer: coarse)") && mm("(hover: none)"));
const forced = params.get("mobile");
export const PHONE = forced === "1" ? true : forced === "0" ? false : HANDHELD;

export interface Tier {
  /** Pixel ratio cap. */
  dpr: number;
  /** Scene MSAA samples (0 = SMAA in post). */
  msaa: number;
  /** Sun shadow map size. */
  shadow: number;
  /** Paint (Kuwahara) filter strength, 0 = off. */
  paint: number;
  /** Bloom resolution as a share of the output. */
  bloom: number;
  /** Adaptive scene resolution: start, floor, ceiling. */
  res: [number, number, number];
  /** Scene pass in one two-target draw (no normal-pass twins). */
  singlePass: boolean;
  /** Without MSAA, alpha-cut cards cut at half coverage instead of dithering. */
  alphaCut: boolean;
  /** Sun shadow filter tap spread (1 = desktop). */
  shadowSpread: number;
  /** Leaf cards per tree crown (1 = desktop). */
  treeCards: number;
  /** Icosphere detail of each leaf clump's solid mass. */
  treeMass: number;
  /** Trees drawn in the water mirror (1 = yes). */
  reflTrees: number;
  /** Ink width follows the frame height below 1080p. */
  fineLines: boolean;
  /** Balloon Ride: flora draw distances and the near card-tree cap (1 = desktop). */
  flora: number;
}

const DESKTOP: Tier = {
  dpr: 1.5, msaa: 4, shadow: 2048, paint: 0.85, bloom: 0.5, res: [1, 0.75, 1],
  singlePass: false, alphaCut: false, shadowSpread: 1, treeCards: 1, treeMass: 1, reflTrees: 1, fineLines: false, flora: 1,
};

const PHONE_TIER: Tier = {
  dpr: 1.75, msaa: 0, shadow: 1024, paint: 0.85, bloom: 0.25, res: [0.9, 0.8, 1],
  singlePass: true, alphaCut: true, shadowSpread: 1.75, treeCards: 0.35, treeMass: 0, reflTrees: 0, fineLines: true, flora: 0.55,
};

function overrides(t: Tier): Tier {
  const s = params.get("tier");
  if (!s) return t;
  const o: Record<string, unknown> = { ...t };
  for (const kv of s.split(",")) {
    const [k, v] = kv.split(":");
    if (!(k in o) || v === undefined) continue;
    const cur = o[k];
    if (Array.isArray(cur)) o[k] = v.split("/").map(Number);
    else if (typeof cur === "number") o[k] = Number(v);
    else if (typeof cur === "boolean") o[k] = v === "1" || v === "true";
  }
  return o as unknown as Tier;
}

export const TIER: Tier = overrides(PHONE ? PHONE_TIER : DESKTOP);
