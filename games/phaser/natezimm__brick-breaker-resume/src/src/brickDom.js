import { hexToCss } from './brickLayout.js';

/**
 * DOM rendering shared by the start overlay and the running game, so both
 * draw a layout record identically. Everything on the page is a brick.
 */

function applyBox(element, { x, y, width, height }) {
  element.style.left = `${x}px`;
  element.style.top = `${y}px`;
  element.style.width = `${width}px`;
  element.style.height = `${height}px`;
}

function applyType(element, { font, letterSpacing }) {
  if (!font) return;
  element.style.font = font;
  element.style.lineHeight = '1';
  if (letterSpacing) element.style.letterSpacing = `${letterSpacing}px`;
}

/** @param {import('./brickLayout.js').BrickLayoutRecord} brick */
export function createBrickElement(brick) {
  const element = document.createElement('div');
  element.className = 'overlay-brick';
  if (brick.kind) element.classList.add(`brick--${brick.kind}`);
  element.textContent = brick.text;

  applyBox(element, brick);
  applyType(element, brick);

  if (typeof brick.color === 'number') {
    element.style.setProperty('--brick-color', hexToCss(brick.color));
  }
  // Stagger inputs for the entrance animation.
  element.style.setProperty('--row', String(brick.rowIndex ?? 0));
  element.style.setProperty(
    '--col',
    String(brick.colIndex ?? Math.round(brick.x / 90))
  );

  return element;
}

/** The faint impression a word leaves on the page after it is knocked off. */
export function createGhostElement(brick) {
  const element = document.createElement('div');
  element.className = 'brick-ghost';
  if (brick.kind) element.classList.add(`brick--${brick.kind}`);
  element.textContent = brick.text;

  applyBox(element, brick);
  applyType(element, brick);

  return element;
}

/**
 * Fills a container with a layout. Words in `brokenWords` are skipped; the
 * typeset page keeps their impression.
 * @returns {import('./brickLayout.js').BrickLayoutRecord[]} the bricks that were skipped
 */
export function renderLayout(container, layout, { onBrick, brokenWords } = {}) {
  container.textContent = '';
  container.dataset.layout = layout.mode;

  layout.bricks.forEach((brick) => {
    if (brokenWords?.has(brick.wordIndex)) {
      if (layout.mode === 'typeset') {
        container.appendChild(createGhostElement(brick));
      }
      return;
    }

    const element = createBrickElement(brick);
    container.appendChild(element);
    onBrick?.(brick, element);
  });
}
