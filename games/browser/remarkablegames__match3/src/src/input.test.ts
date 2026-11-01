import { createGameState } from './game';
import { attachInputHandlers } from './input';

describe('attachInputHandlers', () => {
  it('ignores touches on buttons so mobile taps still trigger their click handlers', () => {
    const state = createGameState('levels');
    const onSelectTile = vi.fn();
    const onRestart = vi.fn();
    const onDirty = vi.fn();

    const cleanup = attachInputHandlers(
      () => state,
      () => null,
      onSelectTile,
      onRestart,
      onDirty,
    );

    const button = document.createElement('button');
    document.body.appendChild(button);

    const event = new TouchEvent('touchstart', {
      bubbles: true,
      cancelable: true,
    });

    button.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
    expect(onSelectTile).not.toHaveBeenCalled();
    expect(onRestart).not.toHaveBeenCalled();
    expect(onDirty).not.toHaveBeenCalled();

    cleanup();
    document.body.removeChild(button);
  });

  it('uses the latest state so a new game is not repeatedly restarted', () => {
    let state = createGameState('levels');
    state.gameOver = true;

    const onSelectTile = vi.fn();
    const onRestart = vi.fn(() => {
      state = createGameState('levels');
    });
    const onDirty = vi.fn();

    const cleanup = attachInputHandlers(
      () => state,
      () => ({ row: 0, col: 0 }),
      onSelectTile,
      onRestart,
      onDirty,
    );

    document.dispatchEvent(
      new MouseEvent('mousedown', { clientX: 10, clientY: 10 }),
    );
    expect(onRestart).toHaveBeenCalledTimes(1);
    expect(onSelectTile).not.toHaveBeenCalled();

    document.dispatchEvent(
      new MouseEvent('mousedown', { clientX: 10, clientY: 10 }),
    );
    expect(onRestart).toHaveBeenCalledTimes(1);
    expect(onSelectTile).toHaveBeenCalledTimes(1);

    cleanup();
  });
});
