import { test } from 'node:test';
import assert from 'node:assert/strict';
import { emptyStats, normalizeStats, recordResult } from '../src/stats.js';

test('results are recorded per level without mutating the input', () => {
  const start = emptyStats();
  const a = recordResult(start, 'hard', true);
  const b = recordResult(a, 'hard', false);
  const c = recordResult(b, 'easy', true);
  assert.deepEqual(start.hard, { wins: 0, losses: 0 });
  assert.deepEqual(c, { easy: { wins: 1, losses: 0 }, medium: { wins: 0, losses: 0 }, hard: { wins: 1, losses: 1 } });
  assert.deepEqual(recordResult(c, 'nope', true), c);
});

test('broken stored data is cleaned up', () => {
  assert.deepEqual(normalizeStats(null), emptyStats());
  assert.deepEqual(normalizeStats('x'), emptyStats());
  const n = normalizeStats({ easy: { wins: 2, losses: -1 }, hard: { wins: 1.5, losses: '3' }, extra: 1 });
  assert.deepEqual(n, { easy: { wins: 2, losses: 0 }, medium: { wins: 0, losses: 0 }, hard: { wins: 0, losses: 0 } });
});
