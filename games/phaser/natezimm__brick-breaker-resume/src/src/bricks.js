import { GAME_CONSTANTS, THEMES } from './constants.js';
import { getGameState } from './state.js';
import { calculateBrickLayout } from './brickLayout.js';
import { createBrickElement, createGhostElement } from './brickDom.js';

const PARTICLE_COUNT = 12;
const PARTICLE_LIFETIME = 700;
const WORD_LIFETIME = 1500;

function isPaper() {
  return document.documentElement?.dataset?.theme === THEMES.LIGHT;
}

function addTransient(element, lifetime) {
  document.body.appendChild(element);
  window.setTimeout(() => element.remove(), lifetime);
}

function createBrickExplosion(domBrick, record, ball) {
  if (
    !domBrick ||
    typeof domBrick.getBoundingClientRect !== 'function' ||
    typeof document === 'undefined'
  ) {
    return;
  }

  const rect = domBrick.getBoundingClientRect();
  const centerX = rect.left + rect.width / 2;
  const centerY = rect.top + rect.height / 2;
  const color =
    domBrick.style?.getPropertyValue?.('--brick-color') ||
    domBrick.style?.backgroundColor ||
    '#ffffff';
  const paper = isPaper();

  for (let i = 0; i < PARTICLE_COUNT; i++) {
    const particle = document.createElement('span');
    const angle = (Math.PI * 2 * i) / PARTICLE_COUNT;
    const distance = 18 + Math.random() * 28;

    particle.className = 'brick-particle';
    particle.style.left = `${centerX + (Math.random() - 0.5) * rect.width * 0.6}px`;
    particle.style.top = `${centerY}px`;
    particle.style.setProperty('--particle-color', color);
    particle.style.setProperty(
      '--particle-x',
      `${Math.cos(angle) * distance}px`
    );
    particle.style.setProperty(
      '--particle-y',
      `${Math.sin(angle) * distance}px`
    );
    particle.style.setProperty(
      '--particle-spin',
      `${Math.round(Math.random() * 360)}deg`
    );

    addTransient(particle, PARTICLE_LIFETIME);
  }

  if (!paper) {
    const ring = document.createElement('span');
    ring.className = 'brick-ring';
    ring.style.left = `${centerX}px`;
    ring.style.top = `${centerY}px`;
    ring.style.setProperty('--particle-color', color);
    ring.style.setProperty('--ring-size', `${Math.max(rect.width, 28)}px`);
    addTransient(ring, PARTICLE_LIFETIME);
  }

  const text = domBrick.textContent;
  if (!text) return;

  // The broken word stays readable for a moment: it rises off the glass wall,
  // or drops off the printed page.
  const word = document.createElement('span');
  word.className = 'brick-word';
  word.textContent = text;
  word.style.left = `${centerX}px`;
  word.style.top = `${centerY}px`;
  if (record?.font) {
    word.style.font = record.font;
    word.style.lineHeight = '1';
  }
  if (paper) {
    const drift = (ball?.body?.velocity?.x ?? 0) * 0.18;
    word.style.setProperty(
      '--fall-x',
      `${Math.round(drift + (Math.random() - 0.5) * 80)}px`
    );
    word.style.setProperty(
      '--fall-spin',
      `${Math.round((Math.random() - 0.5) * 220)}deg`
    );
  }
  addTransient(word, WORD_LIFETIME);
}

function getBrickContainer() {
  let container = document.getElementById('gameBrickContainer');
  if (!container) {
    container = document.createElement('div');
    container.id = 'gameBrickContainer';
    container.style.position = 'absolute';
    container.style.top = '0';
    container.style.left = '0';
    container.style.width = '100%';
    container.style.height = '100%';
    container.style.pointerEvents = 'none'; // Click through to canvas
    container.style.zIndex = '5'; // Above canvas, below controls/modals if needed
    document.getElementById('app')?.appendChild(container) ||
      document.body.appendChild(container);
  }

  return container;
}

/**
 * @param {Object} [details] layout extras: height, kind, font, letterSpacing,
 *   rowIndex, colIndex, wordIndex
 */
export function createBrick(
  scene,
  x,
  y,
  text,
  brickWidth,
  color,
  isLastInRow = false,
  state = getGameState(scene),
  details = {}
) {
  const height = details.height ?? GAME_CONSTANTS.BRICK_HEIGHT;
  const record = { ...details, x, y, width: brickWidth, height, text, color };

  const brickDiv = createBrickElement(record);
  getBrickContainer().appendChild(brickDiv);

  const brick = scene.add.rectangle(x, y, brickWidth, height, 0x000000, 0);
  brick.setOrigin(0, 0);

  scene.physics.add.existing(brick, true);
  state.bricksGroup.add(brick);

  brick.setData('domBrick', brickDiv);
  brick.setData('record', record);

  brick.setData(
    'row',
    details.rowIndex ??
      Math.floor(
        (y - GAME_CONSTANTS.MARGIN_TOP) /
          (height + GAME_CONSTANTS.BRICK_PADDING)
      )
  );
  brick.setData('isLastInRow', isLastInRow);

  return brick;
}

export async function createBricksFromResume(
  scene,
  state = getGameState(scene)
) {
  const { bricks, totalRows, mode } = await calculateBrickLayout();

  const container = getBrickContainer();
  container.textContent = '';
  container.dataset.layout = mode;

  state.totalRows = totalRows;

  bricks.forEach((brickData) => {
    // Words broken before a theme switch stay broken in the new layout.
    if (state.brokenWords?.has(brickData.wordIndex)) {
      if (mode === 'typeset') {
        container.appendChild(createGhostElement(brickData));
      }
      return;
    }

    createBrick(
      scene,
      brickData.x,
      brickData.y,
      brickData.text,
      brickData.width,
      brickData.color,
      brickData.isLastInRow,
      state,
      brickData
    );
  });

  state.bricksCreated = true;
}

/**
 * Lays the remaining bricks out again for the active theme. Calls queue up, so
 * the last theme chosen is the one left on screen.
 */
export function rebuildBricks(scene, state = getGameState(scene)) {
  if (!scene || !state?.bricksGroup) return Promise.resolve();
  if (!state.bricksCreated && !state.rebuildingBricks) return Promise.resolve();

  const rebuild = async () => {
    // Keeps the win check quiet while the wall is briefly empty.
    state.bricksCreated = false;
    state.bricksGroup.clear?.(true, true);
    await createBricksFromResume(scene, state);
  };

  const queued = (state.rebuildingBricks ?? Promise.resolve())
    .then(rebuild)
    .catch((error) => {
      console.warn('Could not rebuild bricks:', error);
    })
    .then(() => {
      if (state.rebuildingBricks === queued) state.rebuildingBricks = null;
    });
  state.rebuildingBricks = queued;

  return queued;
}

export function handleBrickCollision(
  scene,
  ball,
  brick,
  state = getGameState(scene)
) {
  const domBrick = brick.getData('domBrick');
  const record = brick.getData('record');

  if (domBrick) {
    createBrickExplosion(domBrick, record, ball);
    if (record && isPaper() && domBrick.parentNode) {
      domBrick.parentNode.insertBefore(createGhostElement(record), domBrick);
    }
    domBrick.remove(); // Standard DOM removal
  }

  if (record) {
    if (record.wordIndex !== undefined)
      state.brokenWords?.add(record.wordIndex);
    if (typeof record.color === 'number') state.lastHitColor = record.color;
  }

  const row = brick.getData('row');
  const points = (state.totalRows - row) * 10;
  state.incrementScore(points);

  brick.destroy(); // Phaser object destruction
}
