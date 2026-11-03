// Pure helpers for touch controls, device detection and quality tiers. No DOM or three.js,
// so they are unit tested in touch.test.ts.

export interface JoystickOut {
  /** strafe, -1 (left) .. 1 (right) */
  x: number;
  /** forward, -1 (back) .. 1 (forward) */
  y: number;
  /** 0..1 after deadzone rescale */
  mag: number;
  /** pushed (nearly) to the edge */
  run: boolean;
}

export const JOY_DEADZONE = 0.18;
export const JOY_RUN_AT = 0.92;

/**
 * Turn a thumb offset from the joystick centre into a movement vector.
 * dx/dy are screen pixels (y grows downward); screen-up becomes forward (+y).
 * Inside the deadzone the output is zero; outside it the magnitude is rescaled to 0..1.
 */
export function joystickVector(dx: number, dy: number, radius: number, deadzone = JOY_DEADZONE, runAt = JOY_RUN_AT): JoystickOut {
  const zero: JoystickOut = { x: 0, y: 0, mag: 0, run: false };
  if (!(radius > 0)) return zero;
  const len = Math.hypot(dx, dy);
  const raw = Math.min(1, len / radius);
  if (raw <= deadzone || len === 0) return zero;
  const mag = (raw - deadzone) / (1 - deadzone);
  const ux = dx / len;
  const uy = -dy / len;
  return { x: ux * mag, y: uy * mag, mag, run: raw >= runAt };
}

/** Clamp a thumb offset to the joystick radius (for drawing the knob). */
export function clampToRadius(dx: number, dy: number, radius: number): { x: number; y: number } {
  const len = Math.hypot(dx, dy);
  if (len <= radius || len === 0) return { x: dx, y: dy };
  return { x: (dx / len) * radius, y: (dy / len) * radius };
}

/**
 * Scale a drag (in px) to the "mouse pixel" units Game.look() expects.
 * Desktop look() uses 0.0022 rad/px, so sens 1 is one mouse-pixel per screen-pixel.
 * Each axis is capped so a glitchy event cannot spin the camera.
 */
export function lookDelta(dx: number, dy: number, sens = 1.6, invertY = false, maxStep = 120): { dx: number; dy: number } {
  const c = (v: number) => Math.max(-maxStep, Math.min(maxStep, v));
  return { dx: c(dx * sens), dy: c(dy * sens * (invertY ? -1 : 1)) };
}

export interface TouchEnv {
  /** matchMedia("(pointer: coarse)") */
  coarse: boolean;
  /** matchMedia("(pointer: fine)") */
  fine: boolean;
  /** "ontouchstart" in window */
  hasTouchStart: boolean;
  maxTouchPoints: number;
  /** query string, e.g. window.location.search */
  search?: string;
}

/** Feature-detected touch device (no UA sniffing). ?touch=1 / ?touch=0 forces it for testing. */
export function isTouchDevice(env: TouchEnv): boolean {
  const force = new URLSearchParams(env.search ?? "").get("touch");
  if (force === "1") return true;
  if (force === "0") return false;
  if (env.coarse) return true;
  // a touchscreen laptop reports a fine primary pointer and should keep keyboard + mouse
  return (env.hasTouchStart || env.maxTouchPoints > 0) && !env.fine;
}

export type Quality = "low" | "high";

/** ?quality=low|high in the URL, or null. It beats any saved preference for that session. */
export function qualityFromUrl(search = ""): Quality | null {
  const q = new URLSearchParams(search).get("quality");
  return q === "low" || q === "high" ? q : null;
}

/** ?quality=low|high wins, then a saved override ("low"/"high"), otherwise touch devices get low and everything else high. */
export function pickQuality(touch: boolean, search = "", pref: Quality | "auto" = "auto"): Quality {
  return qualityFromUrl(search) ?? (pref === "low" || pref === "high" ? pref : touch ? "low" : "high");
}

export interface QualitySettings {
  pixelRatioCap: number;
  antialias: boolean;
  shadowMapSize: number;
  /** cheap hard-edged shadows instead of PCF soft */
  basicShadows: boolean;
  fogNear: number;
  fogFar: number;
  /** how many of the lantern point lights are real lights (the glowing bulbs always stay) */
  lampLights: number;
}

export const QUALITY: Record<Quality, QualitySettings> = {
  high: { pixelRatioCap: 2, antialias: true, shadowMapSize: 2048, basicShadows: false, fogNear: 30, fogFar: 170, lampLights: 17 },
  low: { pixelRatioCap: 1.5, antialias: false, shadowMapSize: 1024, basicShadows: true, fogNear: 20, fogFar: 105, lampLights: 5 },
};

export function pixelRatioFor(q: Quality, devicePixelRatio: number): number {
  const dpr = devicePixelRatio > 0 ? devicePixelRatio : 1;
  return Math.min(dpr, QUALITY[q].pixelRatioCap);
}

/** Evenly pick `n` of `total` indices (used to keep lantern lights spread across the map). */
export function spreadIndices(total: number, n: number): Set<number> {
  const out = new Set<number>();
  if (n >= total) {
    for (let i = 0; i < total; i++) out.add(i);
    return out;
  }
  for (let i = 0; i < n; i++) out.add(Math.floor(((i + 0.5) * total) / n));
  return out;
}
