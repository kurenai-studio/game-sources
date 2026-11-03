import { describe, expect, it } from 'vitest';
import { createGame, startGame, type Game } from './engine';
import { nextDeduction, solve } from './solver';

function fixture(): Game {
  const game = createGame({ width: 3, height: 2, floors: 1, mines: 1, seed: 'constraint-fixture' });
  game.started = [true];
  game.status = 'playing';
  game.cells[0][3].mine = true;
  game.cells[0][0].revealed = game.cells[0][1].revealed = true;
  game.cells[0][0].adjacent = game.cells[0][1].adjacent = 1;
  return game;
}

describe('visible-information deduction solver', () => {
  it('deduces safe cells by subtracting overlapping constraints', () => {
    expect(nextDeduction(fixture())).toMatchObject({ action: 'reveal', floor: 0, index: 2, rule: 'subset' });
  });

  it('flags forced mines and reveals forced-safe neighbors from single constraints', () => {
    const game = fixture();
    game.config.mines = 2;
    game.cells[0][0].adjacent = game.cells[0][1].adjacent = 2;
    expect(nextDeduction(game)).toMatchObject({ action: 'flag', index: 3, rule: 'single' });
    game.config.mines = 1;
    game.cells[0][0].adjacent = 0;
    game.cells[0][1].adjacent = 1;
    expect(nextDeduction(game)).toMatchObject({ action: 'reveal', index: 3, rule: 'single' });
  });

  it('never inspects hidden mine values to select its next action', () => {
    const game = fixture();
    for (const cell of game.cells[0]) if (!cell.revealed) Object.defineProperty(cell, 'mine', { get() { throw new Error('hidden information read'); } });
    expect(nextDeduction(game)).toMatchObject({ action: 'reveal', index: 2 });
  });

  it('stops rather than guessing an ambiguous board', () => {
    const game = createGame({ width: 3, height: 3, floors: 1, mines: 1, seed: 'ambiguous' });
    const result = solve(game);
    expect(result).toMatchObject({ solved: false, reason: 'stuck', steps: [] });
    expect(game.status).toBe('ready');
  });

  it('rejects an overflagged visible constraint', () => {
    const game = fixture();
    game.cells[0][3].flagged = game.cells[0][4].flagged = true;
    expect(nextDeduction(game)).toBe('contradiction');
    expect(solve(game).reason).toBe('contradiction');
  });

  it('does not mutate the supplied puzzle', () => {
    const game = startGame({ width: 5, height: 5, floors: 1, mines: 3, seed: 'campaign-0', firstReveal: [12], generatorVersion: 1 });
    const snapshot = structuredClone(game);
    solve(game);
    expect(game).toEqual(snapshot);
  });

  it('treats a lost board as a contradiction and an already won board as solved', () => {
    const game = fixture();
    game.status = 'lost';
    expect(solve(game)).toMatchObject({ solved: false, reason: 'contradiction' });
    game.status = 'won';
    expect(solve(game)).toMatchObject({ solved: true, reason: 'solved', steps: [] });
  });
});
