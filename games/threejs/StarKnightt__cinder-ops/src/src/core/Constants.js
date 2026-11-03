/* Cinder Ops — every tunable number lives here.
 *
 * Design brief
 *   Promise: lone operator clearing a sunlit dust block under fire.
 *   Feeling: tense, weighty, precise — CS2 gunfeel, not arena twitch.
 *   Primary verb: aim and fire.
 *   Secondary: move, sprint, crouch, ADS, reload, push cover.
 *   Core loop: take a street segment, win the gunfight, advance toward extract.
 *   Progression: rooms/streets clear, remaining hostiles drop, extract unlocks.
 *   Fail: health hits 0 → restart at spawn.
 *   Skill: peek timing, recoil control, using cover and sun shadows.
 *   Non-goals: vehicles, killstreaks, CoD maps/brands/characters, external assets.
 *
 * Core loop contract
 *   Player aims and shoots to clear the Ashline block while incoming fire
 *   creates risk; a downed hostile is progress, death restarts the raid.
 *
 * Level plan
 *   Format: authored street canyon with one optional market cut-through.
 *   Start: service alley, 8s of quiet, lamp + dumpster cover.
 *   First decision: push the checkpoint or cut through the market.
 *   First threat: two militia at the sandbag line.
 *   Landmark: burning van, comms mast, warehouse doors.
 *   Escalation: 2 → 3 → 3 hostiles, tighter cover, more lamps in the eyes.
 *   Recovery: dark shop recess after the van.
 *   Extract: warehouse bay at the far end.
 *
 * Visual bar (Counter-Strike 2, quality only — original world)
 *   Daytime sun, warm dust plaster, readable hard-surface architecture,
 *   smooth AK viewmodel, thin military HUD, no stat cards.
 */

export const PLAYER_CONFIG = {
  HEALTH: 100,
  ARMOR: 50,
  GRACE: 8,
  EYE: 1.64,
  CROUCH_EYE: 1.18,
  RADIUS: 0.34,
  HEADROOM: 0.16,
  // c31 feel pass (refs/kimi-feel-autopsy.md fix 2/6): 3.35 walk was slower
  // than CS2's *walk*; CS2 AK run is ~4.9 m/s. Strafe/back drag removed,
  // accel raised so the throttle feels instant (95% of wish in ~88 ms).
  WALK: 5.0,
  SPRINT: 7.2,
  CROUCH: 2.4,
  ACCEL: 34,
  BRAKE: 22,
  // 2.2 froze velocity mid-jump; 9 allows reduced air strafing (kimi runs
  // full ground accel airborne — this stays deliberately below that).
  AIR_STEER: 9,
  STRAFE: 1.0,
  BACK: 0.85,
  JUMP: 4.6,
  // 18 -> 15: same jump impulse, slightly floatier and more readable arc.
  GRAVITY: 15,
  // Auto-step (CS2 ~18u ≈ 0.23m). 0.30 clears pallets, curb lips, plank decks
  // without eating stall tables (0.93m) or crate stacks (0.55m — those jump).
  STEP: 0.30,
  // Edge-trigger + cooldown: no hold-Space bunny hop. Impulse is still one-shot.
  JUMP_COOL: 0.16,
  // CS2 feel: m_yaw 0.022°/count × sens 2.0 = 0.044°/count ≈ 0.000768 rad/count.
  // User multiplier ([ / ] keys) scales this; ADS keeps the standard ~0.56 ratio.
  MOUSE: 0.00077,
  ADS_MOUSE: 0.00043,
  PITCH_MAX: 1.5533, // ±89°

  BOB: 0.018,
  // 8 pumped ±8° whenever a strafe cancelled sprint; kimi uses +4.
  SPRINT_FOV: 4,
  // CS2-style ADS punch-in: ~11 deg off the 68 base keeps the crosshair the
  // focus instead of magnifying the viewmodel into a wall of gun.
  ADS_FOV: -11,
  // Exponential response rate for the FOV zoom lerp (Player._applyCamera).
  FOV_LERP: 15,
};

/* Weapon roster (refs/weapons-plan.md §1/§4). Single source of truth: every
 * gameplay number for all four weapons lives here. Enemy HP is 90; damage
 * math is tuned against that (AK 3 body close / 4 far, sniper 1-shot body,
 * shotgun ≤6 m 1-shot with ≥6 pellets, pistol 4 body = finisher).
 *
 * zoom.stages semantics: hold-ADS single stage for everything except the
 * sniper, whose RMB *click* cycles hip → stage0 → stage1 → hip (CS2 style).
 * Rifle stage is 57 = 68 + the calibrated −11 ADS punch-in (the plan's 55
 * predates the −13→−11 ADS_FOV calibration; c20 framing is preserved). */
export const WEAPONS = {
  rifle: {
    name: 'AK-47', slot: 1,
    mag: 30, reserve: 90, rpm: 720, auto: true,
    damage: 34, headMult: 1.9, falloff: [{ range: 18, mult: 0.75 }], range: 72,
    reload: 1.85, reloadStyle: 'mag',
    raise: 0.75, moveMult: 1.0,
    spread: {
      hip: 0.012, ads: 0.0022, move: 0.018,
      perShot: 0.0058, max: 0.052, recover: 0.075,
      air: 0.020, crouchMult: 0.62, adsMult: 0.42,
    },
    recoil: { y: 0.0125, x: 0.0048, driftAfter: 6 },
    /* fovKick 0.55 -> 0.25 (autopsy fix 8): sustained hip fire was pumping
     * the projection + viewmodel scale nearly every frame. */
    vmKick: 0.035, vmRot: 0.055, fovKick: 0.25,
    zoom: { stages: [57], time: 0.22, overlay: false },
    pellets: 1, flash: 1.0, tracer: 'warm',
  },
  sniper: {
    name: 'Longshot', slot: 2,
    mag: 5, reserve: 10, rpm: 50, auto: false,
    damage: 115, headMult: 2.2, falloff: [], range: 72,
    reload: 2.8, reloadStyle: 'mag',
    raise: 1.0, moveMult: 0.7, scopedMoveMult: 0.5,
    spread: {
      hip: 0.08, ads: 0.0005, move: 0.03,
      perShot: 0.004, max: 0.020, recover: 0.15,
      air: 0.012, crouchMult: 0.55, adsMult: 0.12,
    },
    recoil: { y: 0.045, x: 0.002, unscopeOnFire: true },
    vmKick: 0.175, vmRot: 0.20, fovKick: 2.2,
    zoom: { stages: [40, 25], time: 0.10, overlay: true, hideViewmodel: true },
    pellets: 1, flash: 1.3, tracer: 'bright',
  },
  shotgun: {
    name: 'Rampart', slot: 2,
    mag: 8, reserve: 24, rpm: 67, auto: false,
    damage: 12, headMult: 1.5,
    falloff: [{ range: 8, mult: 1.0 }, { range: 22, mult: 0.25 }, { range: 26, mult: 0 }],
    range: 30,
    reload: 0.55, reloadStyle: 'shell',
    raise: 0.85, moveMult: 0.9,
    spread: {
      hip: 0.035, ads: 0.030, move: 0.006,
      perShot: 0.008, max: 0.025, recover: 0.12,
      air: 0.025, crouchMult: 0.80, adsMult: 0.85,
    },
    recoil: { y: 0.030, x: 0.006 },
    vmKick: 0.115, vmRot: 0.165, fovKick: 2.6,
    zoom: { stages: [62], time: 0.18, overlay: false },
    pellets: 8, flash: 1.6, tracer: 'warm',
  },
  pistol: {
    name: 'Vektor', slot: 3,
    mag: 12, reserve: 36, rpm: 400, auto: false,
    damage: 26, headMult: 2.0, falloff: [{ range: 15, mult: 0.8 }], range: 50,
    reload: 1.6, reloadStyle: 'mag',
    raise: 0.45, moveMult: 1.05,
    spread: {
      hip: 0.0035, ads: 0.0025, move: 0.010,
      perShot: 0.008, max: 0.028, recover: 0.027,
      air: 0.015, crouchMult: 0.70, adsMult: 0.55,
    },
    recoil: { y: 0.010, x: 0.003 },
    vmKick: 0.048, vmRot: 0.090, fovKick: 0.85,
    zoom: { stages: [60], time: 0.16, overlay: false },
    pellets: 1, flash: 0.6, tracer: 'faint2nd',
  },
};

/* Piecewise damage falloff walk over WEAPONS[id].falloff.
 * One entry = CS2-style step (×mult beyond range). Multiple entries =
 * control points with linear interpolation between them (shotgun pellets:
 * full ≤8 m → ×0.25 at 22 m → 0 past 26 m). Empty = no falloff. */
export function falloffMult(falloff, dist) {
  if (!falloff || falloff.length === 0) return 1;
  if (falloff.length === 1) return dist > falloff[0].range ? falloff[0].mult : 1;
  if (dist <= falloff[0].range) return falloff[0].mult;
  for (let i = 1; i < falloff.length; i++) {
    const a = falloff[i - 1], b = falloff[i];
    if (dist <= b.range) {
      const t = (dist - a.range) / (b.range - a.range);
      return a.mult + (b.mult - a.mult) * t;
    }
  }
  return falloff[falloff.length - 1].mult;
}

/* Supply chests (c35). Same plaza / Suq crate spots as the old heavy
 * pickups — beacons stay, contents are HP / armor. y is the pedestal
 * origin (floor). PickupSystem owns the box; the world pass has none. */
export const PICKUP_TAKE_RANGE = 1.2;
export const PICKUP_PROMPT_RANGE = 4;
export const CHEST_REFILL = 45;
export const CHEST_HP = 50;
export const CHEST_ARMOR = 50;
export const PICKUPS = [
  { id: 'health', name: 'Med chest', x: 10.8, y: 0, z: 50.5, hp: CHEST_HP, armor: 0 },
  { id: 'armor', name: 'Armor chest', x: 17.0, y: 0, z: 30.0, hp: 0, armor: CHEST_ARMOR },
];

/* Enemy loadout variety (plan §8). Suq holders E1/E6 are shotgunners with a
 * distance-gated damage model: dangerous to push, safe to poke from range.
 * AI stays yaw-track+shoot; a "close rush" behavior needs pathing/collision
 * work deferred to a future movement pass. */
export const ENEMY_LOADOUTS = {
  rifle: {
    damage: 9, rpm: 420, mag: 30,
    burstMin: 3, burstMax: 5, burstDt: [0.11, 0.15], burstGap: [0.80, 1.50],
    reload: [2.0, 2.9],
  },
  shotgun: {
    rpm: 60, near: 8, far: 14, dmgNear: 18, dmgFar: 6, mag: 8,
    burstMin: 1, burstMax: 1, burstDt: [0.90, 1.10], burstGap: [0.20, 0.40],
    reload: [2.2, 2.8],
  },
};

export const ENEMY_CONFIG = {
  HEALTH: 90,
  SPEED: 1.55,
  DAMAGE: 9,
  RPM: 420,
  SIGHT: 30,
  COUNT: 8,
};

export const WORLD = {
  SEED: 18441,
  STREET_HALF: 4.2,
  LENGTH: 92,
  GRAVITY: 18,
  FOG_COLOR: 0xe2d2b4,
  FOG_DENSITY: 0.0115,
  // Ashline Bazaar footprint: Main street x -7..+5, block row x +5..+13,
  // Suq alley x +13..+21. Blocks are solid colliders, so a box clamp is valid.
  MAIN_HALF: 6.0,
  BLOCK_MIN_X: 5,
  BLOCK_MAX_X: 13,
  SUQ_MIN_X: 13,
  SUQ_MAX_X: 21,
  PLAY_X: [-6.9, 20.9],
  PLAY_Z: [1.2, 90],
};

export const CAMERA = {
  FOV: 68,
  NEAR: 0.04,
  FAR: 220,
};

export const COLORS = {
  AMBIENT: 0xc8b898,
  SUN: 0xf0d6b0,
  SODIUM: 0xd4a060,
  FIRE: 0xe86828,
  INTERIOR: 0xd4b888,
  NEON: 0xb89458,
};

export const TIER = {
  high: { dpr: 1, shadow: 4096, aniso: 8 },
  medium: { dpr: 1, shadow: 1536, aniso: 4 },
  low: { dpr: 0.85, shadow: 1024, aniso: 2 },
};

/* Opt-in GPU quality. Cinematic IS today's locked showcase path
 * (4096 PCFSoft + 4× MSAA + full post). Competitive only drops
 * shadow map SIZE and MSAA count — lighting values stay locked. */
export const QUALITY = {
  cinematic: { id: 'cinematic', shadow: TIER.high.shadow, msaa: 4, fast: false },
  competitive: { id: 'competitive', shadow: 2048, msaa: 2, fast: true },
};

/* Sun-shadow ortho fallback. c25 retargets the sun at the look point and
 * fits a view AABB + must-cover casters (Game._fitSunShadow). These numbers
 * are only used if that fit fails the span sanity check. */
export const SHADOW = {
  LEFT: -50, RIGHT: 50, TOP: 60, BOTTOM: -60, NEAR: 4, FAR: 200, RADIUS: 1,
};

export function readSafeInsets() {
  const s = getComputedStyle(document.documentElement);
  return {
    top: parseInt(s.getPropertyValue('--ogp-safe-top-inset')) || 0,
    bottom: parseInt(s.getPropertyValue('--ogp-safe-bottom-inset')) || 0,
  };
}

const _insets = typeof document !== 'undefined' ? readSafeInsets() : { top: 0, bottom: 0 };

export const SAFE_ZONE = {
  TOP_PX: Math.max(75, _insets.top),
  BOTTOM_PX: _insets.bottom,
};
