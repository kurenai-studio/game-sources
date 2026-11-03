import { DEG } from './core/geometry';

export const TILE = 32;
export const VIEW_W = 1280;
export const VIEW_H = 720;

/**
 * The game is laid out in 1280x720 logical pixels but rendered at the size it is actually shown
 * (up to 2x), so it stays sharp on large and high-density screens instead of being stretched.
 */
export const RENDER_SCALE = (() => {
  if (typeof window === 'undefined') return 1;
  const shown = Math.min(window.innerWidth / VIEW_W, window.innerHeight / VIEW_H) * (window.devicePixelRatio || 1);
  return Math.min(2, Math.max(1, Math.ceil(shown * 4) / 4));
})();

/** Body text: a clean monospace. Both faces ship with the game (see main.ts). */
export const FONT = '"JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace';
/** Headings and labels: a condensed display face. */
export const DISPLAY_FONT = '"Barlow Condensed", "Arial Narrow", sans-serif';

/** Colour coding stays strict for readability: blue for you, red for hostiles, yellow for civilians. */
export const COLORS = {
  void: 0x07090c,
  floor: 0x342b22,
  floorDark: 0x191613,
  deck: 0x6b5236,
  wall: 0x3b424d,
  wallEdge: 0x9aa6b8,
  plywood: 0x6f5232,
  plywoodEdge: 0xc79c68,
  interior: 0x7d776d,
  interiorEdge: 0xd6cfc2,
  tile: 0x6f706c,
  concrete: 0x45484c,
  screed: 0x55595e,
  grass: 0x2c4224,
  water: 0x1b4a63,
  glass: 0x9fd3ff,
  stone: 0x8a8f96,
  barrier: 0x6e5236,
  barrierStripe: 0xd4a017,
  furniture: 0x3d342b,
  furnitureEdge: 0x6a5a48,
  door: 0xb98552,
  doorEdge: 0xe0b07a,
  suspect: 0xef4444,
  civilian: 0xfacc15,
  cardboard: 0xc8a46a,
  laser: 0xff3b3b,
  visionWarm: 0xffc070,
} as const;

export const VISION = {
  halfFov: 30 * DEG,
  rangeLit: 680,
  /** In dark rooms the operator sees as far as their weapon light reaches. */
  rangeDark: 320,
  peripheral: 56,
  sweepStep: 0.8 * DEG,
  /** How dark remembered-but-not-visible areas are. */
  rememberedShade: 0.62,
  /** How much vision fades towards the edge of its range, in lit and dark areas. */
  falloffLit: 0.45,
  falloffDark: 0.8,
};

export const MOVE = {
  walk: 115,
  sprint: 205,
  radius: 10,
  /** Seconds between footsteps. */
  stepWalk: 0.5,
  stepSprint: 0.3,
};

/** Noise radii in px. Enemy AI will listen for these; for now they drive the on-screen ripples. */
export const NOISE = {
  /** Walking is quiet: only heard from right next to you. */
  walkStep: 70,
  sprintStep: 280,
  doorOpen: 110,
  doorClose: 110,
  reload: 70,
};

export const REACH = 64;
