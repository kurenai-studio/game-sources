/** Global game constants. Tweak these to re-balance feel without touching logic. */

/** Internal resolution the game is designed at. Scaled to fit any screen. */
export const GAME_WIDTH = 960;
export const GAME_HEIGHT = 540;

/** Y position of the floor the fighters stand on. */
export const GROUND_Y = GAME_HEIGHT - 70;

/** Gravity pulling fighters back down after a jump (pixels/sec^2). */
export const GRAVITY_Y = 1500;

/** How close (px) two fighters can get before they stop overlapping. */
export const BODY_WIDTH = 70;

/** Prefix every asset/content path with Vite's base so it works in dev,
 *  static web builds, and inside the Capacitor native shell. */
export function assetPath(relative: string): string {
  return `${import.meta.env.BASE_URL}${relative}`.replace(/\/{2,}/g, "/");
}
