import { GAME_CONSTANTS, COLORS, THEMES, THEME_LOOKS } from './constants.js';
import { fitTypeset, getTypesetFontSpecs } from './typeset.js';

const ALLOWED_ASSET_PATHS = Object.freeze([
  'assets/resume.json',
  './assets/resume.json',
]);

const FONT_LOAD_TIMEOUT = 1500;
const MAX_HEADING_LENGTH = 40;

/**
 * @typedef {Object} BrickLayoutRecord
 * @property {number} x
 * @property {number} y
 * @property {number} width
 * @property {number} height
 * @property {string} text
 * @property {number} color
 * @property {number} rowIndex
 * @property {number | string} wordIndex position of the word in the résumé, stable across layouts; the typeset rule and bullet dots use `rule-N` and `dot-N`
 * @property {boolean} isLastInRow
 * @property {string} kind name | contact | rule | heading | role | date | dot | bullet | body
 * @property {string} [font] CSS font shorthand (typeset layout only)
 * @property {number} [letterSpacing] pixels (typeset layout only)
 */

/**
 * @typedef {Object} BrickLayout
 * @property {BrickLayoutRecord[]} bricks
 * @property {number} totalRows
 * @property {'wall' | 'typeset'} mode
 */

function isAllowedAssetPath(path) {
  return ALLOWED_ASSET_PATHS.includes(path);
}

function isHeading(text) {
  return (
    text.length <= MAX_HEADING_LENGTH &&
    /[A-Z]/.test(text) &&
    !/\d/.test(text) &&
    text === text.toUpperCase()
  );
}

/**
 * Labels each résumé entry with the part it plays on the page, so layouts can
 * give the name, headings, and job titles their own treatment.
 */
export function classifyElements(elements) {
  let seenHeading = false;

  return elements.map((element, index) => {
    const text = typeof element?.text === 'string' ? element.text : '';
    let kind = 'body';

    if (index === 0) {
      kind = 'name';
    } else if (element?.tag === 'li') {
      kind = 'bullet';
    } else if (isHeading(text)) {
      kind = 'heading';
      seenHeading = true;
    } else if (text.includes('\t')) {
      kind = 'role';
    } else if (!seenHeading) {
      kind = 'contact';
    }

    return { ...element, text, kind };
  });
}

/** The layout the active theme calls for; the document theme is the source of truth. */
export function getLayoutMode() {
  const theme =
    typeof document !== 'undefined'
      ? document.documentElement?.dataset?.theme
      : undefined;

  return theme === THEMES.LIGHT ? THEME_LOOKS[THEMES.LIGHT].layout : 'wall';
}

function createMeasurer() {
  const context =
    typeof document !== 'undefined'
      ? document.createElement('canvas').getContext?.('2d')
      : null;

  if (context && typeof context.measureText === 'function') {
    return (text, font) => {
      context.font = font;
      return context.measureText(text).width;
    };
  }

  // No canvas text metrics (tests, very old browsers): estimate from the size.
  return (text, font) => {
    const size = parseFloat(/([\d.]+)px/.exec(font)?.[1] ?? '16');
    return text.length * size * 0.5;
  };
}

async function loadTypesetFonts() {
  if (typeof document === 'undefined' || !document.fonts?.load) return;

  let timer;
  const timeout = new Promise((resolve) => {
    timer = setTimeout(resolve, FONT_LOAD_TIMEOUT);
  });

  try {
    await Promise.race([
      Promise.all(
        getTypesetFontSpecs().map((font) => document.fonts.load(font))
      ),
      timeout,
    ]);
  } catch {
    // Fall back to whichever face the browser renders; measuring uses the same stack.
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Wall layout: every word is a fixed-height brick and each row is stretched
 * to fill the width.
 */
function layoutWall(elements) {
  const {
    MARGIN_TOP,
    BRICK_HEIGHT,
    BRICK_PADDING,
    BASE_BRICK_WIDTH,
    MAX_BRICK_HEIGHT_RATIO,
  } = GAME_CONSTANTS;
  const rightEdge = window.innerWidth - 10;
  let x = 10;
  let y = MARGIN_TOP;
  let totalRows = 0;
  let wordIndex = 0;

  const bricksByRow = new Map();

  elements.forEach((el) => {
    const words = el.text.split(/\s+/).filter((w) => w.length > 0);
    words.forEach((word) => {
      const index = wordIndex++;
      const brickWidth = word.length * BASE_BRICK_WIDTH + 10;

      if (x + brickWidth > rightEdge) {
        x = 10;
        y += BRICK_HEIGHT + BRICK_PADDING;
      }
      if (y + BRICK_HEIGHT > window.innerHeight * MAX_BRICK_HEIGHT_RATIO)
        return;

      const rowIndex = Math.floor(
        (y - MARGIN_TOP) / (BRICK_HEIGHT + BRICK_PADDING)
      );
      totalRows = Math.max(totalRows, rowIndex + 1);
      const rowColor =
        COLORS.BRICK_COLORS[rowIndex % COLORS.BRICK_COLORS.length];

      if (!bricksByRow.has(rowIndex)) {
        bricksByRow.set(rowIndex, []);
      }
      bricksByRow.get(rowIndex).push({
        x,
        y,
        width: brickWidth,
        originalWidth: brickWidth,
        text: word,
        color: rowColor,
        rowIndex,
        wordIndex: index,
        kind: el.kind,
      });

      x += brickWidth + BRICK_PADDING;
    });
  });

  const justifiedBricks = [];

  bricksByRow.forEach((bricksInRow) => {
    const lastBrickData = bricksInRow[bricksInRow.length - 1];
    const currentRightEdge = lastBrickData.x + lastBrickData.width;
    const spaceRemaining = rightEdge - currentRightEdge;
    const extraPerBrick =
      spaceRemaining > 0 ? spaceRemaining / bricksInRow.length : 0;

    bricksInRow.forEach((data, index) => {
      justifiedBricks.push({
        x: data.x + extraPerBrick * index,
        y: data.y,
        width: data.originalWidth + extraPerBrick,
        height: BRICK_HEIGHT,
        text: data.text,
        color: data.color,
        rowIndex: data.rowIndex,
        colIndex: index,
        wordIndex: data.wordIndex,
        kind: data.kind,
        isLastInRow: index === bricksInRow.length - 1,
      });
    });
  });

  return { bricks: justifiedBricks, totalRows, mode: 'wall' };
}

async function loadResumeElements() {
  const assetPath = 'assets/resume.json';

  if (!isAllowedAssetPath(assetPath)) {
    console.error('Security: Attempted to load unauthorized asset path');
    return [];
  }

  const response = await fetch(assetPath);
  if (!response.ok) {
    throw new Error(`Failed to load resume data: ${response.status}`);
  }

  return classifyElements(await response.json());
}

async function layoutElements(elements, mode) {
  if (mode === 'typeset') {
    await loadTypesetFonts();
    const { bricks, totalRows } = fitTypeset(elements, {
      width: window.innerWidth,
      height: window.innerHeight,
      measure: createMeasurer(),
    });
    return { bricks, totalRows, mode };
  }

  return layoutWall(elements);
}

/**
 * Loads resume.json and lays its words out as bricks for the active theme.
 * @param {{mode?: 'wall' | 'typeset'}} [options]
 * @returns {Promise<BrickLayout>}
 */
export async function calculateBrickLayout({ mode = getLayoutMode() } = {}) {
  return layoutElements(await loadResumeElements(), mode);
}

/**
 * Lays the résumé out in several modes from one request. The start screen
 * uses this to show both looks side by side.
 * @param {Array<'wall' | 'typeset'>} modes
 * @returns {Promise<BrickLayout[]>}
 */
export async function calculateBrickLayouts(modes) {
  const elements = await loadResumeElements();
  return Promise.all(modes.map((mode) => layoutElements(elements, mode)));
}

/**
 * Converts a hex color number to a CSS color string.
 * @param {number} hex - Hex color number (e.g., 0xf44336)
 * @returns {string} CSS color string (e.g., '#f44336')
 */
export function hexToCss(hex) {
  return '#' + hex.toString(16).padStart(6, '0');
}
