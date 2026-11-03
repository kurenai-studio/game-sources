// Mapping between table units and canvas pixels (pure, no DOM).
import { WIDTH, LENGTH } from './table.js';

/** Space drawn around the table for the rim and the goal pockets. */
export const MARGIN = 0.07;
export const VIEW_WIDTH = WIDTH + 2 * MARGIN;
export const VIEW_HEIGHT = LENGTH + 2 * MARGIN;

/**
 * @typedef {{scale: number, ox: number, oy: number, width: number, height: number}} View
 */

/**
 * Size of the largest canvas with the table's proportions that fits a box.
 * @param {number} boxWidth CSS pixels.
 * @param {number} boxHeight CSS pixels.
 * @returns {{width: number, height: number}}
 */
export function fitCanvas(boxWidth, boxHeight) {
  const scale = Math.max(0, Math.min(boxWidth / VIEW_WIDTH, boxHeight / VIEW_HEIGHT));
  return { width: Math.floor(scale * VIEW_WIDTH), height: Math.floor(scale * VIEW_HEIGHT) };
}

/**
 * Computes the view transform for a canvas of the given CSS size: table
 * units are multiplied by `scale` and shifted by (ox, oy).
 * @param {number} width
 * @param {number} height
 * @returns {View}
 */
export function computeView(width, height) {
  const scale = Math.min(width / VIEW_WIDTH, height / VIEW_HEIGHT);
  return {
    scale,
    ox: (width - WIDTH * scale) / 2,
    oy: (height - LENGTH * scale) / 2,
    width,
    height,
  };
}

/**
 * Converts a canvas pixel position to table units.
 * @param {View} view
 * @param {number} px
 * @param {number} py
 * @returns {{x: number, y: number}}
 */
export function toTable(view, px, py) {
  return { x: (px - view.ox) / view.scale, y: (py - view.oy) / view.scale };
}

/**
 * Converts table units to canvas pixels.
 * @param {View} view
 * @param {number} x
 * @param {number} y
 * @returns {{x: number, y: number}}
 */
export function toCanvas(view, x, y) {
  return { x: view.ox + x * view.scale, y: view.oy + y * view.scale };
}
