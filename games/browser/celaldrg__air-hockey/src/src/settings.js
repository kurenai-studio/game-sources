// Match setup choices and their validation (pure).
import { LEVELS, GOAL_OPTIONS } from './game.js';

export const MODES = Object.freeze(['cpu', 'pvp']);

/**
 * @typedef {{mode: 'cpu' | 'pvp', level: 'easy' | 'medium' | 'hard', goalsToWin: number}} Settings
 */

/**
 * Turns untrusted stored data into valid settings (defaults: computer, medium, 7).
 * @param {unknown} raw
 * @returns {Settings}
 */
export function normalizeSettings(raw) {
  const r = raw && typeof raw === 'object' ? raw : {};
  return {
    mode: MODES.includes(r.mode) ? r.mode : 'cpu',
    level: LEVELS.includes(r.level) ? r.level : 'medium',
    goalsToWin: GOAL_OPTIONS.includes(r.goalsToWin) ? r.goalsToWin : 7,
  };
}
