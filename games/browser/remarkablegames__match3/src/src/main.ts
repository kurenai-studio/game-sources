import './style.css';

import {
  playInvalid,
  playLose,
  playMatch,
  playSelect,
  playSwap,
  playWin,
} from './audio';
import { EMOJIS, type GameMode, GRID_SIZE } from './constants';
import {
  advanceLevel,
  applyGravity,
  areAdjacent,
  checkEndConditions,
  clearMatches,
  createGameState,
  createPlayableGrid,
  findMatches,
  hasValidMoves,
  swapTiles,
  updateTimer,
  useMove,
} from './game';
import { attachInputHandlers } from './input';
import {
  createRenderer,
  createVisuals,
  type Renderer,
  type VisualTile,
} from './renderer';
import type { GameState, Particle, Position } from './types';

const ANIMATION_SPEED = 0.25;
const MATCH_DELAY = 250;

let state: GameState = createGameState('levels');
let renderer: Renderer;
let visuals: VisualTile[][] = createVisuals(GRID_SIZE);
let particles: Particle[] = [];
let needsRender = true;
let lastDisplayedTimeLeft: number | null = null;

/**
 * Spawns a small burst of rainbow particles at the given screen position.
 */
function spawnParticles(x: number, y: number, count = 8): void {
  for (let i = 0; i < count; i += 1) {
    const angle = (Math.PI * 2 * i) / count;
    const speed = 2 + Math.random() * 3;
    particles.push({
      hue: Math.random() * 360,
      life: 0.5 + Math.random() * 0.3,
      maxLife: 0.8,
      radius: 3 + Math.random() * 3,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      x,
      y,
    });
  }
}

/**
 * Lerp helper.
 */
function lerp(current: number, target: number, factor: number): number {
  return current + (target - current) * factor;
}

/**
 * Updates visual interpolation and particle simulation each frame.
 */
function updateAnimations(deltaTime: number): boolean {
  let active = false;
  for (let row = 0; row < GRID_SIZE; row += 1) {
    for (let col = 0; col < GRID_SIZE; col += 1) {
      const v = visuals[row][col];
      v.offsetX = lerp(v.offsetX, 0, ANIMATION_SPEED);
      v.offsetY = lerp(v.offsetY, 0, ANIMATION_SPEED);
      v.scale = lerp(v.scale, 1, ANIMATION_SPEED);
      v.opacity = lerp(v.opacity, 1, ANIMATION_SPEED);
      if (
        Math.abs(v.offsetX) > 0.01 ||
        Math.abs(v.offsetY) > 0.01 ||
        Math.abs(v.scale - 1) > 0.001 ||
        Math.abs(v.opacity - 1) > 0.001
      ) {
        active = true;
      }
    }
  }

  particles = particles.filter((particle) => {
    particle.x += particle.vx;
    particle.y += particle.vy;
    particle.vy += 0.1;
    particle.life -= deltaTime;
    return particle.life > 0;
  });

  return active || particles.length > 0;
}

/**
 * Schedules match clearing, gravity, and fall animations with a short delay so the player can see each cascade.
 */
function processMatchesSequence(): Promise<void> {
  return new Promise((resolve) => {
    function step(combo: number): void {
      const matches = findMatches(state.grid);
      if (matches.length === 0) {
        state.busy = false;
        checkEndConditions(state);

        if (state.won && state.mode === 'levels') {
          advanceLevel(state);
          visuals = createVisuals(GRID_SIZE);
          needsRender = true;
          resolve();
          return;
        }

        needsRender = true;
        if (state.gameOver && state.won) {
          playWin();
        } else if (state.gameOver && !state.won) {
          playLose();
        }
        resolve();
        return;
      }

      playMatch(combo);

      const centerX =
        renderer.boardX +
        (matches.reduce((sum, pos) => sum + pos.col, 0) / matches.length) *
          renderer.tileSize +
        renderer.tileSize / 2;
      const centerY =
        renderer.boardY +
        (matches.reduce((sum, pos) => sum + pos.row, 0) / matches.length) *
          renderer.tileSize +
        renderer.tileSize / 2;
      spawnParticles(centerX, centerY, Math.min(matches.length, 12));

      const { score } = clearMatches(state.grid, matches, combo);
      state.score += score;
      needsRender = true;

      // Shrink removed tiles visually.
      for (const position of matches) {
        const v = visuals[position.row][position.col];
        v.scale = 0.1;
        v.opacity = 0.1;
      }

      setTimeout(() => {
        const movements = applyGravity(state.grid);
        const movedPositions = new Set<string>();

        for (const movement of movements) {
          const v = visuals[movement.to.row][movement.to.col];
          v.offsetX = (movement.fromCol - movement.to.col) * renderer.tileSize;
          v.offsetY = (movement.fromRow - movement.to.row) * renderer.tileSize;
          v.scale = 1;
          v.opacity = movement.isNew ? 0 : 1;
          movedPositions.add(
            `${String(movement.to.row)},${String(movement.to.col)}`,
          );
        }

        // Ensure any newly spawned tile that did not move is visible.
        for (let row = 0; row < GRID_SIZE; row += 1) {
          for (let col = 0; col < GRID_SIZE; col += 1) {
            if (
              state.grid[row][col] !== -1 &&
              visuals[row][col].opacity === 0.1 &&
              !movedPositions.has(`${String(row)},${String(col)}`)
            ) {
              visuals[row][col].scale = 1;
              visuals[row][col].opacity = 1;
            }
          }
        }

        step(combo + 1);
      }, MATCH_DELAY);
    }

    step(1);
  });
}

/**
 * Attempts to swap two adjacent tiles and resolves matches if the move is valid.
 */
async function handleTileSelection(position: Position): Promise<void> {
  if (state.busy || state.gameOver) {
    return;
  }

  if (!state.selected) {
    state.selected = position;
    playSelect();
    needsRender = true;
    return;
  }

  const selected = state.selected;
  if (selected.row === position.row && selected.col === position.col) {
    state.selected = null;
    needsRender = true;
    return;
  }

  if (!areAdjacent(selected, position)) {
    state.selected = position;
    playSelect();
    needsRender = true;
    return;
  }

  state.busy = true;
  state.selected = null;
  playSwap();

  // Apply the logical swap first so the emojis move to their new positions.
  swapTiles(state.grid, selected, position);

  // Animate swap offsets.
  const dx = (position.col - selected.col) * renderer.tileSize;
  const dy = (position.row - selected.row) * renderer.tileSize;
  const v1 = visuals[selected.row][selected.col];
  const v2 = visuals[position.row][position.col];
  v1.offsetX = dx;
  v1.offsetY = dy;
  v2.offsetX = -dx;
  v2.offsetY = -dy;

  // Wait briefly for the swap animation.
  await new Promise((resolve) => {
    setTimeout(resolve, MATCH_DELAY);
  });

  const matches = findMatches(state.grid);
  if (matches.length === 0) {
    // Invalid swap: swap back.
    playInvalid();
    swapTiles(state.grid, selected, position);
    v1.offsetX = dx;
    v1.offsetY = dy;
    v2.offsetX = -dx;
    v2.offsetY = -dy;
    await new Promise((resolve) => {
      setTimeout(resolve, MATCH_DELAY);
    });
    state.busy = false;
    return;
  }

  useMove(state);
  await processMatchesSequence();

  // If no valid moves remain, reshuffle the board while preserving progress.
  if (!hasValidMoves(state.grid)) {
    state.grid = createPlayableGrid(GRID_SIZE, GRID_SIZE);
    visuals = createVisuals(GRID_SIZE);
  }
}

/**
 * Resets the game with the same or a new mode.
 */
function startGame(mode: GameMode): void {
  state = createGameState(mode);
  visuals = createVisuals(GRID_SIZE);
  particles = [];
  needsRender = true;
  lastDisplayedTimeLeft = null;
}

/**
 * Main animation loop.
 */
function loop(lastTime: number): void {
  requestAnimationFrame((time) => {
    const deltaTime = Math.min((time - lastTime) / 1000, 0.1);
    updateTimer(state, deltaTime);
    const animationsActive = updateAnimations(deltaTime);
    const displayedTimeLeft =
      state.timeLeft !== null ? Math.ceil(state.timeLeft) : null;
    const timerTicked = displayedTimeLeft !== lastDisplayedTimeLeft;
    if (needsRender || animationsActive || timerTicked) {
      renderer.render(state, visuals, particles);
      needsRender = false;
      lastDisplayedTimeLeft = displayedTimeLeft;
    }
    loop(time);
  });
}

/**
 * Initializes the game and mounts it into the provided element.
 */
function initGame(container: HTMLElement): void {
  renderer = createRenderer(container, () => {
    needsRender = true;
  });
  visuals = createVisuals(GRID_SIZE);

  function markDirty(): void {
    needsRender = true;
  }

  attachInputHandlers(
    () => state,
    renderer.screenToGrid,
    (position) => {
      void handleTileSelection(position);
      markDirty();
    },
    () => {
      startGame(state.mode);
      markDirty();
    },
    markDirty,
  );

  // Add simple mode buttons.
  const controls = document.createElement('div');
  controls.className = 'controls';

  const modes: GameMode[] = ['levels', 'time', 'endless'];
  for (const mode of modes) {
    const button = document.createElement('button');
    button.textContent =
      mode === 'levels'
        ? 'Levels'
        : mode === 'time'
        ? 'Time Attack'
        : 'Endless';
    button.type = 'button';
    button.addEventListener('click', () => {
      startGame(mode);
    });
    controls.appendChild(button);
  }

  container.appendChild(controls);

  requestAnimationFrame((time) => {
    loop(time);
  });
}

const app = document.querySelector<HTMLDivElement>('#app');
if (app) {
  initGame(app);
}

export { EMOJIS, startGame };
