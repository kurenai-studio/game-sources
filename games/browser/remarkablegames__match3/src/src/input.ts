import { GRID_SIZE } from './constants';
import type { GameState, Position } from './types';

/**
 * Callback invoked when the user selects a tile.
 */
export type SelectTileCallback = (position: Position) => void;

/**
 * Callback invoked when the user restarts the game.
 */
export type RestartCallback = () => void;

/**
 * Callback invoked whenever any input changes and the renderer should redraw.
 */
export type DirtyCallback = () => void;

/**
 * Attaches mouse, touch, and keyboard handlers to the document.
 */
export function attachInputHandlers(
  getState: () => GameState,
  convertScreenToGrid: (x: number, y: number) => Position | null,
  onSelectTile: SelectTileCallback,
  onRestart: RestartCallback,
  onDirty: DirtyCallback,
): () => void {
  function handlePointer(x: number, y: number): void {
    const state = getState();
    if (state.cursor !== null) {
      state.cursor = null;
      onDirty();
    }
    if (state.gameOver) {
      onRestart();
      return;
    }
    const position = convertScreenToGrid(x, y);
    if (position) {
      onSelectTile(position);
    }
  }

  function onMouseDown(event: MouseEvent): void {
    handlePointer(event.clientX, event.clientY);
  }

  function onTouchStart(event: TouchEvent): void {
    if (event.target instanceof HTMLElement && event.target.closest('button')) {
      return;
    }
    event.preventDefault();
    const touch = event.touches[0];
    handlePointer(touch.clientX, touch.clientY);
  }

  function showCursor(state: GameState): Position {
    state.cursor ??= {
      col: Math.floor(GRID_SIZE / 2),
      row: Math.floor(GRID_SIZE / 2),
    };
    return state.cursor;
  }

  function moveCursor(
    state: GameState,
    deltaRow: number,
    deltaCol: number,
  ): void {
    const cursor = showCursor(state);
    state.cursor = {
      col: Math.max(0, Math.min(GRID_SIZE - 1, cursor.col + deltaCol)),
      row: Math.max(0, Math.min(GRID_SIZE - 1, cursor.row + deltaRow)),
    };
    onDirty();
  }

  function onKeyDown(event: KeyboardEvent): void {
    const state = getState();
    switch (event.key) {
      case 'ArrowUp':
        moveCursor(state, -1, 0);
        break;
      case 'ArrowDown':
        moveCursor(state, 1, 0);
        break;
      case 'ArrowLeft':
        moveCursor(state, 0, -1);
        break;
      case 'ArrowRight':
        moveCursor(state, 0, 1);
        break;
      case 'Enter':
      case ' ': {
        if (state.gameOver) {
          onRestart();
        } else {
          onSelectTile(showCursor(state));
        }
        break;
      }
      case 'Escape':
        state.selected = null;
        onDirty();
        break;
      default:
        return;
    }
    event.preventDefault();
  }

  document.addEventListener('mousedown', onMouseDown);
  document.addEventListener('touchstart', onTouchStart, { passive: false });
  document.addEventListener('keydown', onKeyDown);

  return () => {
    document.removeEventListener('mousedown', onMouseDown);
    document.removeEventListener('touchstart', onTouchStart);
    document.removeEventListener('keydown', onKeyDown);
  };
}
