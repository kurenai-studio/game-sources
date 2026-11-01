import { COLORS, GAME_CONSTANTS } from './constants.js';

/**
 * Paper layout: sets the résumé as a typeset page where every word is a
 * brick. The same font strings are used to measure here and to render in the
 * DOM, so a brick's box always matches the word inside it.
 */

export const TYPESET_FAMILIES = Object.freeze({
  serif: "'Newsreader Variable', 'Iowan Old Style', Charter, Georgia, serif",
  sans: "Inter, ui-sans-serif, system-ui, -apple-system, 'Segoe UI', sans-serif",
});

// Sizes are CSS pixels at scale 1. `height` is the brick height, `gap` the
// space between lines, `tracking` is letter spacing in em.
const STYLES = Object.freeze({
  name: { family: 'serif', weight: 600, size: 54, height: 54, gap: 4 },
  contact: { family: 'sans', weight: 400, size: 13, height: 18, gap: 4 },
  heading: {
    family: 'sans',
    weight: 600,
    size: 11.5,
    height: 16,
    gap: 4,
    tracking: 0.12,
  },
  role: { family: 'serif', weight: 600, size: 16.5, height: 21, gap: 3 },
  date: {
    family: 'serif',
    weight: 400,
    italic: true,
    size: 14.5,
    height: 21,
    gap: 3,
  },
  bullet: { family: 'serif', weight: 400, size: 15, height: 19, gap: 3 },
  body: { family: 'serif', weight: 400, size: 15, height: 19, gap: 3 },
});

const SCALE_STEP = 0.04;
const MIN_SCALE_WIDE = 0.76;
const WIDE_VIEWPORT = 900;
const MAX_CONTENT_WIDTH = 1400;
const RULE_SEGMENT = 110;
const RULE_GAP = 2;
const RULE_HIT_HEIGHT = 6;
const BULLET = '•';

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function fontFor(style, size) {
  const italic = style.italic ? 'italic ' : '';
  return `${italic}${style.weight} ${size}px ${TYPESET_FAMILIES[style.family]}`;
}

/** Font shorthands to load before measuring, one per face the page uses. */
export function getTypesetFontSpecs() {
  return [STYLES.body, STYLES.role, STYLES.date].map((style) =>
    fontFor(style, style.size)
  );
}

function splitWords(text) {
  return text.split(/\s+/).filter((word) => word.length > 0);
}

/**
 * @param {Array<{text: string, kind: string}>} elements classified résumé entries
 * @param {{width: number, height: number, scale?: number,
 *   measure: (text: string, font: string) => number}} options
 */
export function layoutTypeset(elements, { width, height, measure, scale = 1 }) {
  const side = clamp(width * 0.06, 16, 96);
  const contentWidth = Math.min(width - side * 2, MAX_CONTENT_WIDTH);
  const left = (width - contentWidth) / 2;
  const right = left + contentWidth;
  const maxY = height * GAME_CONSTANTS.MAX_BRICK_HEIGHT_RATIO;
  const padX = 2;

  const bricks = [];
  let dots = 0;
  let y = clamp(height * 0.03, GAME_CONSTANTS.MARGIN_TOP, 26);
  let row = 0;
  let wordIndex = 0;
  let truncated = false;

  const metricsFor = (kind) => {
    const style = STYLES[kind];
    // The name shrinks with the column so it stays on one line on a phone.
    const baseSize =
      kind === 'name' ? Math.min(style.size, contentWidth * 0.118) : style.size;
    const ratio = baseSize / style.size;
    const size = Math.round(baseSize * scale * 100) / 100;
    const font = fontFor(style, size);
    const letterSpacing = style.tracking ? style.tracking * size : 0;

    return {
      font,
      letterSpacing,
      height: Math.round(style.height * ratio * scale),
      gap: Math.max(2, Math.round(style.gap * scale)),
      space: measure(' ', font) + letterSpacing,
      widthOf: (word) => measure(word, font) + letterSpacing * word.length,
    };
  };

  const place = (word, kind, metrics, x, wordWidth) => {
    const index = wordIndex++;
    if (y + metrics.height > maxY) {
      truncated = true;
      return;
    }
    bricks.push({
      x: x - padX,
      y,
      width: wordWidth + padX * 2,
      height: metrics.height,
      text: word,
      kind,
      font: metrics.font,
      letterSpacing: metrics.letterSpacing,
      color: COLORS.INK,
      rowIndex: row,
      wordIndex: index,
      isLastInRow: false,
    });
  };

  const newLine = (metrics) => {
    y += metrics.height + metrics.gap;
    row++;
  };

  /**
   * Flows tokens left to right, wrapping at the right margin. Returns the x
   * where the line ended so a caller can keep setting on the same line.
   */
  const flow = (tokens, kind, { startX = left, wrapX = left } = {}) => {
    const metrics = metricsFor(kind);
    let x = startX;

    tokens.forEach((token, tokenIndex) => {
      const wordWidth = metrics.widthOf(token.text);
      if (tokenIndex > 0) x += token.gapBefore ?? metrics.space;
      if (x + wordWidth > right + 0.5 && x > wrapX) {
        newLine(metrics);
        x = wrapX;
      }
      place(token.text, kind, metrics, x, wordWidth);
      x += wordWidth;
    });

    return { x, metrics };
  };

  const toTokens = (text) => splitWords(text).map((word) => ({ text: word }));

  for (let index = 0; index < elements.length; index++) {
    const element = elements[index];
    const previous = elements[index - 1];

    if (element.kind === 'name') {
      const { metrics } = flow(toTokens(element.text), 'name');
      newLine(metrics);
      continue;
    }

    if (element.kind === 'contact') {
      // Contact details arrive as separate entries; set them as one line.
      const itemGap = 16 * scale;
      const tokens = [];
      while (elements[index]?.kind === 'contact') {
        toTokens(elements[index].text).forEach((token, tokenIndex) => {
          tokens.push(
            tokenIndex === 0 && tokens.length > 0
              ? { ...token, gapBefore: itemGap }
              : token
          );
        });
        index++;
      }
      index--;
      const { metrics } = flow(tokens, 'contact');
      newLine(metrics);
      y += 2 * scale;
      // The rule under the contact line is in play like everything else on
      // the page: a row of thin bricks, each drawn as a stroke through the
      // middle of its hit area. They are keyed apart from the words.
      if (y + RULE_HIT_HEIGHT <= maxY) {
        const count = Math.max(1, Math.round(contentWidth / RULE_SEGMENT));
        const segment = (contentWidth - RULE_GAP * (count - 1)) / count;
        for (let piece = 0; piece < count; piece++) {
          bricks.push({
            x: left + piece * (segment + RULE_GAP),
            y,
            width: segment,
            height: RULE_HIT_HEIGHT,
            text: '',
            kind: 'rule',
            color: COLORS.INK,
            rowIndex: row,
            wordIndex: `rule-${piece}`,
            isLastInRow: false,
          });
        }
        row++;
      }
      y += RULE_HIT_HEIGHT + 10 * scale;
      continue;
    }

    if (element.kind === 'heading') {
      if (previous && previous.kind !== 'contact' && previous.kind !== 'name') {
        y += 9 * scale;
      }
      const { metrics } = flow(toTokens(element.text), 'heading');
      newLine(metrics);
      continue;
    }

    if (element.kind === 'role') {
      if (previous && previous.kind !== 'heading') y += 5 * scale;

      const [title = '', ...rest] = element.text.split('\t');
      const dateTokens = toTokens(rest.join(' '));
      const rowBeforeTitle = row;
      const { x: titleEnd, metrics } = flow(toTokens(title), 'role');

      if (dateTokens.length > 0) {
        const dateMetrics = metricsFor('date');
        const dateWidth = dateTokens.reduce(
          (total, token, tokenIndex) =>
            total +
            dateMetrics.widthOf(token.text) +
            (tokenIndex > 0 ? dateMetrics.space : 0),
          0
        );
        const fitsBesideTitle =
          row === rowBeforeTitle && titleEnd + 24 + dateWidth <= right;

        if (!fitsBesideTitle) newLine(metrics);
        flow(dateTokens, 'date', {
          startX: fitsBesideTitle ? right - dateWidth : left,
        });
      }
      newLine(metrics);
      continue;
    }

    if (element.kind === 'bullet') {
      const metrics = metricsFor('bullet');
      const indent = Math.round(15 * scale);
      // The dot is in play too, keyed apart from the words like the rule.
      if (y + metrics.height <= maxY) {
        bricks.push({
          x: left,
          y,
          width: metrics.widthOf(BULLET) + padX * 2,
          height: metrics.height,
          text: BULLET,
          kind: 'dot',
          font: metrics.font,
          letterSpacing: 0,
          color: COLORS.INK,
          rowIndex: row,
          wordIndex: `dot-${dots}`,
          isLastInRow: false,
        });
      }
      dots++;
      flow(toTokens(element.text), 'bullet', {
        startX: left + indent,
        wrapX: left + indent,
      });
      newLine(metrics);
      continue;
    }

    const { metrics } = flow(toTokens(element.text), 'body');
    newLine(metrics);
  }

  const lastInRow = new Map();
  bricks.forEach((brick) => lastInRow.set(brick.rowIndex, brick));
  lastInRow.forEach((brick) => {
    brick.isLastInRow = true;
  });

  const totalRows = bricks.reduce(
    (rows, brick) => Math.max(rows, brick.rowIndex + 1),
    0
  );

  return { bricks, totalRows, truncated, scale };
}

/**
 * Picks the largest type scale at which the whole résumé fits above the play
 * area. Narrow screens never shrink the type; they show as much as fits.
 */
export function fitTypeset(elements, viewport) {
  const minScale = viewport.width >= WIDE_VIEWPORT ? MIN_SCALE_WIDE : 1;
  let layout;

  for (let scale = 1; scale >= minScale - 0.001; scale -= SCALE_STEP) {
    layout = layoutTypeset(elements, { ...viewport, scale });
    if (!layout.truncated) break;
  }

  return layout;
}
