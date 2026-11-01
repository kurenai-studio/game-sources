import type { TraceEntry } from "@algomind/level-contract";
import type { Direction } from "./level-model";

const OPPOSITE: Record<Direction, Direction> = {
  north: "south",
  east: "west",
  south: "north",
  west: "east",
};

/**
 * The breadcrumbs a run has dropped by the end of `trace`: each MARKED step marks the cell the
 * automaton stands on (a cell keeps its first) with an arrow to the cell behind it.
 */
export function crumbsOf(trace: readonly TraceEntry[]): { x: number; y: number; dir: Direction }[] {
  const crumbs: { x: number; y: number; dir: Direction }[] = [];
  for (const t of trace) {
    if (t.event !== "MARKED") continue;
    const [x, y] = t.position;
    if (!crumbs.some((c) => c.x === x && c.y === y))
      crumbs.push({ x, y, dir: OPPOSITE[t.direction] });
  }
  return crumbs;
}

/** The distinct cells entered by the end of `trace`, with the start cell first. */
export function visitedOf(
  start: [number, number],
  trace: readonly TraceEntry[],
): [number, number][] {
  const seen = new Set<string>([start.join(",")]);
  const cells: [number, number][] = [start];
  for (const t of trace) {
    const key = t.position.join(",");
    if (seen.has(key)) continue;
    seen.add(key);
    cells.push([t.position[0], t.position[1]]);
  }
  return cells;
}
