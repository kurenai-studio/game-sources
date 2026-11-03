import { describe, expect, it } from 'vitest';
import { restoreGame, startGame } from './engine';
import { campaign, createLevel } from './campaign';
import { solve } from './solver';

describe('curated no-guess campaign', () => {
  it('contains unique fixed-opening levels covering all three playable chapters', () => {
    expect(new Set(campaign.map(level => level.id)).size).toBe(campaign.length);
    expect(campaign.filter(level => level.chapter === 'classic')).toHaveLength(2);
    expect(campaign.filter(level => level.chapter === 'layered')).toHaveLength(2);
    expect(campaign.filter(level => level.chapter === 'connected').map(level => level.config.vertical)).toEqual(['above', 'below', 'both']);
    for (const level of campaign) {
      expect(level.config.generatorVersion).toBe(1);
      expect(level.config.firstReveal).toHaveLength(level.config.floors);
      expect(level.lesson.length).toBeGreaterThan(40);
    }
  });

  for (const level of campaign) {
    it(`${level.id} is reproducible, resumable and logically solvable without guessing`, () => {
      const game = createLevel(level);
      expect(game.status).toBe('playing');
      expect(createLevel(level)).toEqual(game);
      expect(restoreGame(structuredClone(game))).toEqual(game);
      for (const floor of game.cells) expect(floor.filter(cell => cell.mine)).toHaveLength(level.config.mines);
      const result = solve(game);
      expect(result.solved).toBe(true);
      expect(result.reason).toBe('solved');
      expect(result.game.status).toBe('won');
      expect(result.steps.length).toBeGreaterThan(0);
      expect(result.game.cells.flat().every(cell => cell.mine || cell.revealed)).toBe(true);
      expect(game.status).toBe('playing');
    });
  }

  it('Connected introduces visible arrows and proofs that actually cross floors', () => {
    for (const level of campaign.filter(level => level.chapter === 'connected')) {
      const game = createLevel(level);
      expect(game.cells.flat().some(cell => cell.revealed && cell.clueType !== 'local')).toBe(true);
    }
    for (const [id, required] of [
      ['look-up', ['above']], ['look-down', ['below']], ['hidden-connections', ['above', 'below']],
    ] as const) {
      const game = createLevel(campaign.find(level => level.id === id)!);
      const result = solve(game);
      for (const direction of required) {
        expect(result.steps.some(step => step.sources.some(source =>
          source.floor !== step.floor && game.cells[source.floor][source.index].clueType === direction,
        ))).toBe(true);
      }
    }
  });

  it('the combined Connected challenge needs both directional rule sets with the supported solver', () => {
    const level = campaign.find(level => level.id === 'hidden-connections')!;
    expect(solve(createLevel(level)).solved).toBe(true);
    // Same mine seed/openings; replacing either direction with local clues leaves the solver stuck.
    for (const vertical of ['above', 'below'] as const) {
      const result = solve(startGame({ ...level.config, vertical }));
      expect(result).toMatchObject({ solved: false, reason: 'stuck' });
    }

  });
});
