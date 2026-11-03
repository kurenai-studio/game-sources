import { clueNeighbors, reveal, toggleFlag, type Game } from './engine';

export interface Deduction {
  action: 'reveal' | 'flag';
  floor: number;
  index: number;
  rule: 'single' | 'subset';
  sources: { floor: number; index: number }[];
}
interface Constraint {
  cells: number[];
  mines: number;
  sources: Deduction['sources'];
}
export interface SolveResult {
  solved: boolean;
  game: Game;
  steps: Deduction[];
  reason: 'solved' | 'stuck' | 'contradiction' | 'limit';
}

/** Uses visible clues, flags and the published floor mine totals; never reads hidden mine values. */
export function nextDeduction(game: Game): Deduction | 'contradiction' | null {
  if (game.status === 'lost') return 'contradiction';
  if (game.status === 'won') return null;
  const size = game.config.width * game.config.height;
  const constraints: Constraint[] = [];
  let invalid = false;
  const add = (positions: { floor: number; index: number }[], count: number, sources: Deduction['sources']) => {
    const hidden: number[] = [];
    for (const p of positions) {
      const cell = game.cells[p.floor][p.index];
      if (cell.flagged) count--;
      else if (!cell.revealed) hidden.push(p.floor * size + p.index);
    }
    if (count < 0 || count > hidden.length) invalid = true;
    if (hidden.length) constraints.push({ cells: hidden, mines: count, sources });
  };
  game.cells.forEach((floor, f) => {
    add(floor.map((_, index) => ({ floor: f, index })), game.config.mines, []);
    floor.forEach((cell, i) => {
      if (cell.revealed) add(clueNeighbors(game, f, i), cell.adjacent, [{ floor: f, index: i }]);
    });
  });
  if (invalid) return 'contradiction';
  const deduction = (constraint: Constraint, rule: Deduction['rule']): Deduction | null => {
    if (constraint.mines !== 0 && constraint.mines !== constraint.cells.length) return null;
    const id = constraint.cells[0];
    return { action: constraint.mines === 0 ? 'reveal' : 'flag', floor: Math.floor(id / size), index: id % size, rule, sources: constraint.sources };
  };
  for (const c of constraints) {
    const next = deduction(c, 'single');
    if (next) return next;
  }
  for (const a of constraints) {
    for (const b of constraints) {
      if (a === b || a.cells.length >= b.cells.length || !a.cells.every(id => b.cells.includes(id))) continue;
      const difference = { cells: b.cells.filter(id => !a.cells.includes(id)), mines: b.mines - a.mines, sources: [...a.sources, ...b.sources] };
      if (difference.mines < 0 || difference.mines > difference.cells.length) return 'contradiction';
      const next = deduction(difference, 'subset');
      if (next) return next;
    }
  }
  return null;
}

/** A bounded logical proof on a copy. Stuck means no supported deduction, never permission to guess. */
export function solve(input: Game): SolveResult {
  const game: Game = structuredClone(input);
  const steps: Deduction[] = [];
  const limit = game.config.width * game.config.height * game.config.floors * 2;
  for (let turn = 0; turn < limit; turn++) {
    if (game.status === 'won') return { solved: true, game, steps, reason: 'solved' };
    const next = nextDeduction(game);
    if (next === 'contradiction') return { solved: false, game, steps, reason: 'contradiction' };
    if (!next) return { solved: false, game, steps, reason: 'stuck' };
    const changed = next.action === 'flag' ? toggleFlag(game, next.floor, next.index) : reveal(game, next.floor, next.index);
    if (!changed || game.status === 'lost') return { solved: false, game, steps, reason: 'contradiction' };
    steps.push(next);
  }
  return { solved: game.status === 'won', game, steps, reason: game.status === 'won' ? 'solved' : 'limit' };
}
