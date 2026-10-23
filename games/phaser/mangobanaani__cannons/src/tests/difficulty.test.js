import { describe, it, expect } from 'vitest';
import { DIFFICULTIES, getAIName, getDifficultyConfig } from '../src/game/utils/difficulty.js';

describe('difficulty', () => {
  it('has three difficulty levels', () => {
    expect(Object.keys(DIFFICULTIES)).toEqual(['easy', 'medium', 'hard']);
  });

  it('easy has higher error than hard', () => {
    expect(DIFFICULTIES.easy.errorFactor).toBeGreaterThan(DIFFICULTIES.hard.errorFactor);
  });

  it('hard AI learns from misses', () => {
    expect(DIFFICULTIES.hard.learns).toBe(true);
    expect(DIFFICULTIES.easy.learns).toBe(false);
  });

  it('getAIName returns a string', () => {
    const name = getAIName('medium');
    expect(typeof name).toBe('string');
    expect(name.length).toBeGreaterThan(0);
  });

  it('getDifficultyConfig falls back to medium', () => {
    const config = getDifficultyConfig('unknown');
    expect(config).toEqual(DIFFICULTIES.medium);
  });

  it('each difficulty has named opponents', () => {
    for (const key of Object.keys(DIFFICULTIES)) {
      expect(DIFFICULTIES[key].names.length).toBeGreaterThan(0);
    }
  });

  it('wind compensation increases with difficulty', () => {
    expect(DIFFICULTIES.easy.windCompensation).toBeLessThan(DIFFICULTIES.medium.windCompensation);
    expect(DIFFICULTIES.medium.windCompensation).toBeLessThan(DIFFICULTIES.hard.windCompensation);
  });
});
