import { describe, expect, it } from 'vitest';
import { BoardGesture, DoubleTap } from './gestures';
import { startGame, toggleFlag, chord, clueNeighbors } from './engine';
import { campaign } from './campaign';

const tile = { floor: 1, index: 8 };
describe('board gestures', () => {
  it('reveals only on primary pointer release and flags only once on hold', () => {
    const gesture = new BoardGesture();
    expect(gesture.down(1, 20, 20, 0, tile)).toBeUndefined();
    expect(gesture.up(1)).toEqual({ type: 'tap', tile });
    gesture.down(1, 20, 20, 0, tile);
    expect(gesture.hold()).toEqual({ type: 'flag', tile });
    expect(gesture.hold()).toBeUndefined();
    expect(gesture.up(1)).toBeUndefined();
  });
  it('does not reveal after right click, cancellation, background tap or unrelated release', () => {
    const gesture = new BoardGesture();
    expect(gesture.down(1, 20, 20, 2, tile)).toEqual({ type: 'flag', tile });
    expect(gesture.up(1)).toBeUndefined();
    gesture.down(1, 20, 20, 0, tile);
    expect(gesture.up(2)).toBeUndefined();
    gesture.cancel();
    expect(gesture.up(1)).toBeUndefined();
    gesture.down(1, 20, 20, 0);
    expect(gesture.up(1)).toBeUndefined();
  });
  it('never turns a drag into a tap or hold, even after dragging back', () => {
    const gesture = new BoardGesture();
    gesture.down(1, 20, 20, 0, tile);
    expect(gesture.move(1, 30, 20)).toEqual({ type: 'rotate', delta: 10 });
    gesture.move(1, 20, 20);
    expect(gesture.hold()).toBeUndefined();
    expect(gesture.up(1)).toBeUndefined();
  });
  it('suppresses taps until all pinch pointers have been released', () => {
    const gesture = new BoardGesture();
    gesture.down(1, 10, 10, 0, tile);
    gesture.down(2, 20, 10, 0, tile);
    expect(gesture.move(2, 30, 10)).toEqual({ type: 'zoom', ratio: 2 });
    expect(gesture.hold()).toBeUndefined();
    expect(gesture.up(2)).toBeUndefined();
    expect(gesture.move(1, 15, 10)).toBeUndefined();
    expect(gesture.up(1)).toBeUndefined();
    gesture.down(3, 10, 10, 0, tile);
    expect(gesture.up(3)).toEqual({ type: 'tap', tile });
  });
  it('handles coincident pinch coordinates without invalid zoom values', () => {
    const gesture = new BoardGesture();
    gesture.down(1, 10, 10, 0, tile);
    gesture.down(2, 10, 10, 0, tile);
    expect(gesture.move(2, 20, 10)).toEqual({ type: 'zoom', ratio: 1 });
  });
});

const clue = { ...tile, revealed: true };
function tapClue(gesture: BoardGesture, time: number, target = clue, pointer = 1) {
  gesture.down(pointer, 20, 20, 0, target);
  return gesture.up(pointer, time);
}

describe('double-click / double-tap chording', () => {
  it('chords on the second tap of the same revealed clue, including changing touch IDs', () => {
    const gesture = new BoardGesture();
    expect(tapClue(gesture, 100, clue, 11)).toEqual({ type: 'tap', tile: clue });
    expect(tapClue(gesture, 350, clue, 12)).toEqual({ type: 'chord', tile: clue });
    expect(tapClue(gesture, 450, clue, 13)?.type).toBe('tap');
  });

  it('never treats revealing a hidden tile then tapping its new number as a chord', () => {
    const gesture = new BoardGesture();
    expect(tapClue(gesture, 100, { ...tile, revealed: false })?.type).toBe('tap');
    expect(tapClue(gesture, 200)?.type).toBe('tap');
    expect(tapClue(gesture, 300)?.type).toBe('chord');
  });

  it('does not combine different tiles, floors or taps more than 400ms apart', () => {
    const gesture = new BoardGesture();
    tapClue(gesture, 100);
    expect(tapClue(gesture, 150, { ...clue, index: 9 })?.type).toBe('tap');
    expect(tapClue(gesture, 200, { ...clue, floor: 0, index: 9 })?.type).toBe('tap');
    expect(tapClue(gesture, 601, { ...clue, floor: 0, index: 9 })?.type).toBe('tap');
  });

  it.each(['drag', 'pinch', 'hold', 'right-click', 'cancel', 'background'] as const)('clears the double-tap after %s', interruption => {
    const gesture = new BoardGesture();
    tapClue(gesture, 100);
    if (interruption === 'cancel') gesture.cancel();
    else if (interruption === 'right-click') { gesture.down(1, 20, 20, 2, clue); gesture.up(1, 150); }
    else if (interruption === 'background') { gesture.down(1, 20, 20, 0); gesture.up(1, 150); }
    else {
      gesture.down(1, 20, 20, 0, clue);
      if (interruption === 'drag') gesture.move(1, 50, 20);
      else if (interruption === 'hold') gesture.hold();
      else { gesture.down(2, 40, 20, 0, clue); gesture.up(2, 150); }
      gesture.up(1, 160);
    }
    expect(tapClue(gesture, 200)?.type).toBe('tap');
  });
});

describe('double-tap input integration', () => {
  it('requires two eligible pointer clicks in the HTML board detector', () => {
    const detector = new DoubleTap();
    expect(detector.tap(tile, 100, false)).toBe(false);
    expect(detector.tap(tile, 150, true)).toBe(false);
    expect(detector.tap(tile, 200, true)).toBe(true);
    detector.tap(tile, 250, true);
    detector.reset();
    expect(detector.tap(tile, 300, true)).toBe(false);
    expect(detector.tap(tile, 350, false)).toBe(false);
    expect(detector.tap(tile, 400, true)).toBe(false);
  });

  it.each(['first-steps', 'look-up'])('opens unflagged neighbors with the existing %s clue rules', id => {
    const level = campaign.find(level => level.id === id)!;
    const game = startGame(level.config);
    const index = id === 'look-up' ? 8 : game.cells[0].findIndex((cell, i) => cell.revealed && cell.adjacent > 0
      && clueNeighbors(game, 0, i).some(p => !game.cells[p.floor][p.index].revealed && !game.cells[p.floor][p.index].mine));
    expect(index).toBeGreaterThanOrEqual(0);
    const targets = clueNeighbors(game, 0, index);
    const hiddenSafe = targets.filter(p => !game.cells[p.floor][p.index].revealed && !game.cells[p.floor][p.index].mine);
    expect(hiddenSafe.length).toBeGreaterThan(0);
    const gesture = new BoardGesture();
    const target = { floor: 0, index, revealed: true };
    tapClue(gesture, 100, target);
    expect(tapClue(gesture, 200, target)?.type).toBe('chord');
    expect(chord(game, 0, index)).toBe(false);
    for (const p of targets) if (game.cells[p.floor][p.index].mine) toggleFlag(game, p.floor, p.index);
    expect(chord(game, 0, index)).toBe(true);
    expect(hiddenSafe.every(p => game.cells[p.floor][p.index].revealed)).toBe(true);
    expect(game.status).not.toBe('lost');
  });
});
