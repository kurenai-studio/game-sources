// Pure input helpers: which player a pointer controls, where a finger aims
// and which way the keyboard pushes each mallet.
import { HALF } from './table.js';

/** Distance a touch aim is shifted so the finger does not hide the mallet. */
export const TOUCH_OFFSET = 0.11;
/** Keyboard mallet speed in table units per second. */
export const KEY_SPEED = 2.6;

const ARROWS = { ArrowUp: [0, -1], ArrowDown: [0, 1], ArrowLeft: [-1, 0], ArrowRight: [1, 0] };
const WASD = { KeyW: [0, -1], KeyS: [0, 1], KeyA: [-1, 0], KeyD: [1, 0] };

/**
 * True if the key code moves a mallet.
 * @param {string} code KeyboardEvent.code
 * @returns {boolean}
 */
export function isMoveKey(code) {
  return code in ARROWS || code in WASD;
}

/**
 * Which player a pointer at table height `y` controls: in two-player mode
 * each half belongs to its player, otherwise every pointer is yours.
 * @param {'cpu' | 'pvp'} mode
 * @param {number} y
 * @returns {0 | 1}
 */
export function sideForPointer(mode, y) {
  return mode === 'pvp' && y < HALF ? 1 : 0;
}

/**
 * Mallet target for a pointer. Touches aim a little ahead of the finger,
 * away from the player holding it.
 * @param {number} x
 * @param {number} y
 * @param {0 | 1} side
 * @param {boolean} isTouch
 * @returns {{x: number, y: number}}
 */
export function pointerAim(x, y, side, isTouch) {
  if (!isTouch) return { x, y };
  return { x, y: y + (side === 0 ? -TOUCH_OFFSET : TOUCH_OFFSET) };
}

/** Sums the unit directions of the pressed keys found in `map`. */
function sumKeys(pressed, map) {
  let dx = 0;
  let dy = 0;
  for (const code of pressed) {
    const d = map[code];
    if (d) {
      dx += d[0];
      dy += d[1];
    }
  }
  return { dx, dy };
}

/**
 * Keyboard movement per player for `dt` seconds. Against the computer both
 * arrows and WASD move your mallet; with two players the arrows move the
 * bottom mallet and WASD the top one (directions as seen on screen).
 * @param {Iterable<string>} pressed Pressed KeyboardEvent.code values.
 * @param {'cpu' | 'pvp'} mode
 * @param {number} dt
 * @returns {Array<{dx: number, dy: number}>} Index = player side.
 */
export function keyboardMoves(pressed, mode, dt) {
  const codes = [...pressed];
  const arrows = sumKeys(codes, ARROWS);
  const wasd = sumKeys(codes, WASD);
  const scale = (v) => ({ dx: Math.sign(v.dx) * KEY_SPEED * dt, dy: Math.sign(v.dy) * KEY_SPEED * dt });
  if (mode === 'pvp') return [scale(arrows), scale(wasd)];
  return [scale({ dx: arrows.dx + wasd.dx, dy: arrows.dy + wasd.dy }), { dx: 0, dy: 0 }];
}
