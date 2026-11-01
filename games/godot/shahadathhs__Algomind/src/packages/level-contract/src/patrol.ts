import type { Level, Patrol, Position } from "./types.js";

/**
 * The index into `cells` that a patrol stands on after `step` steps (0 is the start of a run).
 * Back and forth: 0, 1, ..., n-1, n-2, ..., 1, 0, 1, ... (a period of 2 (n - 1)). Loop: 0, 1, ...,
 * n-1, 0, ... (a period of n). Pure and deterministic.
 */
export function patrolIndex(patrol: Patrol, step: number): number {
  const n = patrol.cells.length;
  if (patrol.pattern === "loop") return step % n;
  const period = 2 * (n - 1);
  const t = step % period;
  return t < n ? t : period - t;
}

/** The cell a patrol stands on after `step` steps. */
export function patrolCell(patrol: Patrol, step: number): Position {
  return patrol.cells[patrolIndex(patrol, step)]!;
}

/** The cells of every patrol of the level after `step` steps, in the order of `level.patrols`. */
export function patrolCells(level: Pick<Level, "patrols">, step: number): Position[] {
  return (level.patrols ?? []).map((patrol) => patrolCell(patrol, step));
}

/**
 * The cell where a patrol meets the automaton in one step, or null. The automaton goes from `from` to
 * `to` (the same cell for a turn, INC or MARK) as the step count goes from `step` to `step + 1`. They
 * meet when a patrol stands on `to` afterwards, or when they swap cells (the patrol was on `to` and
 * is now on `from`).
 */
export function patrolMeeting(
  level: Pick<Level, "patrols">,
  from: Position,
  to: Position,
  step: number,
): Position | null {
  for (const patrol of level.patrols ?? []) {
    const now = patrolCell(patrol, step + 1);
    if (now[0] === to[0] && now[1] === to[1]) return to;
    const before = patrolCell(patrol, step);
    const moved = from[0] !== to[0] || from[1] !== to[1];
    if (
      moved &&
      before[0] === to[0] &&
      before[1] === to[1] &&
      now[0] === from[0] &&
      now[1] === from[1]
    ) {
      return to;
    }
  }
  return null;
}
