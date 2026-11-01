import type { LevelContent } from "./admin-api";

export type Cell = [number, number];
export type Belt = NonNullable<LevelContent["belts"]>[number];

/** The tools that place the tiles of the later worlds; "erase" removes whatever is on a cell. */
export type TileTool =
  "ice" | "belt" | "lock" | "delivery" | "switch" | "teleport" | "guard" | "erase";

export const TILE_TOOLS: { id: TileTool; label: string; hint: string }[] = [
  { id: "ice", label: "Ice", hint: "Select cells to make them ice or floor again." },
  {
    id: "belt",
    label: "Belt",
    hint: "Select a cell to place a belt and again to turn it: north, east, south, west, none.",
  },
  { id: "lock", label: "Key and door", hint: "Select the key's cell, then the door's." },
  { id: "delivery", label: "Crate and dock", hint: "Select the crate's cell, then the dock's." },
  { id: "switch", label: "Switch and gate", hint: "Select the switch's cell, then the gate's." },
  { id: "teleport", label: "Teleporter", hint: "Select one end, then the other." },
  {
    id: "guard",
    label: "Guard",
    hint: "Select the cells of its route in order, next to each other, then finish the route.",
  },
  { id: "erase", label: "Erase tile", hint: "Select a cell to remove the tile on it." },
];

const PAIR_FIELDS = {
  lock: { field: "locks", a: "key", b: "door" },
  delivery: { field: "deliveries", a: "item", b: "dock" },
  switch: { field: "switches", a: "switch", b: "gate" },
  teleport: { field: "teleports", a: "a", b: "b" },
} as const;

const BELT_ORDER: (Belt["direction"] | null)[] = ["north", "east", "south", "west", null];

function same(a: Cell, b: Cell): boolean {
  return a[0] === b[0] && a[1] === b[1];
}

type Pair = Record<string, unknown>;

function pairsOf(content: LevelContent, field: string): Pair[] {
  return ((content as Record<string, unknown>)[field] as Pair[] | undefined) ?? [];
}

/** What the cell holds: a short word and one letter for the grid, or null for a bare cell. */
export function tileAt(
  content: LevelContent,
  x: number,
  y: number,
): { word: string; mark: string } | null {
  const at: Cell = [x, y];
  if (content.ice?.some((c) => same(c, at))) return { word: "ice", mark: "~" };
  const belt = content.belts?.find((b) => same(b.cell, at));
  if (belt) {
    return {
      word: `belt ${belt.direction}`,
      mark: { north: "^", east: ">", south: "v", west: "<" }[belt.direction],
    };
  }
  for (const [name, spec] of Object.entries(PAIR_FIELDS)) {
    for (const pair of pairsOf(content, spec.field)) {
      if (same(pair[spec.a] as Cell, at))
        return {
          word: WORDS[name as keyof typeof WORDS][0],
          mark: MARKS[name as keyof typeof MARKS][0],
        };
      if (same(pair[spec.b] as Cell, at))
        return {
          word: WORDS[name as keyof typeof WORDS][1],
          mark: MARKS[name as keyof typeof MARKS][1],
        };
    }
  }
  const guard = content.patrols?.findIndex((p) => p.cells.some((c) => same(c, at))) ?? -1;
  if (guard >= 0) return { word: "guard route", mark: "x" };
  return null;
}

const WORDS = {
  lock: ["key", "door"],
  delivery: ["crate", "dock"],
  switch: ["switch", "gate"],
  teleport: ["teleporter end", "teleporter end"],
} as const;
const MARKS = {
  lock: ["k", "d"],
  delivery: ["c", "b"],
  switch: ["s", "g"],
  teleport: ["o", "o"],
} as const;

/** True when a tile of any kind stands on the cell (a wall, the start or the goal may not). */
export function hasTile(content: LevelContent, x: number, y: number): boolean {
  return tileAt(content, x, y) !== null;
}

/** Removes every tile that uses the cell: an ice cell, a belt, a whole pair, or a whole guard. */
export function eraseTile(content: LevelContent, x: number, y: number): LevelContent {
  const at: Cell = [x, y];
  const next: Record<string, unknown> = { ...content };
  const drop = (field: string, keep: (entry: never) => boolean) => {
    const list = ((content as Record<string, unknown>)[field] as never[] | undefined) ?? [];
    const kept = list.filter(keep);
    if (kept.length === list.length) return;
    if (kept.length === 0) delete next[field];
    else next[field] = kept;
  };
  drop("ice", ((c: Cell) => !same(c, at)) as never);
  drop("belts", ((b: Belt) => !same(b.cell, at)) as never);
  for (const spec of Object.values(PAIR_FIELDS)) {
    drop(
      spec.field,
      ((p: Pair) => !same(p[spec.a] as Cell, at) && !same(p[spec.b] as Cell, at)) as never,
    );
  }
  drop("patrols", ((p: { cells: Cell[] }) => !p.cells.some((c) => same(c, at))) as never);
  return next as LevelContent;
}

function setList<K extends keyof LevelContent>(
  content: LevelContent,
  field: K,
  list: unknown[],
): LevelContent {
  const next = { ...content } as Record<string, unknown>;
  if (list.length === 0) delete next[field];
  else next[field] = list;
  return next as LevelContent;
}

/** Ice on a bare floor cell, or off again. A belt on the cell is replaced. */
export function toggleIce(content: LevelContent, x: number, y: number): LevelContent {
  const at: Cell = [x, y];
  const ice = content.ice ?? [];
  if (ice.some((c) => same(c, at))) {
    return setList(
      content,
      "ice",
      ice.filter((c) => !same(c, at)),
    );
  }
  if (hasTile(content, x, y) && !content.belts?.some((b) => same(b.cell, at))) return content;
  return setList(eraseTile(content, x, y), "ice", [...(eraseTile(content, x, y).ice ?? []), at]);
}

/** A belt on a bare cell, turned a quarter on each selection, and removed after west. */
export function cycleBelt(content: LevelContent, x: number, y: number): LevelContent {
  const at: Cell = [x, y];
  const belts = content.belts ?? [];
  const here = belts.find((b) => same(b.cell, at));
  if (!here && hasTile(content, x, y)) return content;
  const next = BELT_ORDER[(BELT_ORDER.indexOf(here?.direction ?? null) + 1) % BELT_ORDER.length]!;
  const rest = belts.filter((b) => !same(b.cell, at));
  return setList(content, "belts", next ? [...rest, { cell: at, direction: next }] : rest);
}

/** Adds a pair of two different bare cells. */
export function addPair(
  content: LevelContent,
  tool: keyof typeof PAIR_FIELDS,
  a: Cell,
  b: Cell,
): LevelContent {
  const spec = PAIR_FIELDS[tool];
  if (same(a, b) || hasTile(content, b[0], b[1])) return content;
  return setList(content, spec.field, [
    ...pairsOf(content, spec.field),
    { [spec.a]: a, [spec.b]: b },
  ]);
}

/** True when the cell may be the first of a pair or the start of a route: no tile, not a wall. */
export function isBare(content: LevelContent, x: number, y: number): boolean {
  return !hasTile(content, x, y) && !content.board.walls.some(([wx, wy]) => wx === x && wy === y);
}

/** Adds a guard whose route is `cells` (each next to the one before). */
export function addGuard(
  content: LevelContent,
  cells: Cell[],
  pattern: "back_and_forth" | "loop",
): LevelContent {
  if (cells.length < 2) return content;
  return setList(content, "patrols", [...(content.patrols ?? []), { pattern, cells }]);
}

/** True when `next` is beside the last cell of a route in progress (or the route is empty). */
export function continuesRoute(route: Cell[], next: Cell): boolean {
  const last = route[route.length - 1];
  return !last || Math.abs(last[0] - next[0]) + Math.abs(last[1] - next[1]) === 1;
}

/** Every tile as a line of the side list, with what removes or changes it. */
export type TileEntry = { key: string; label: string; remove: LevelContent };

export function tileEntries(content: LevelContent): TileEntry[] {
  const out: TileEntry[] = [];
  const cell = (c: Cell) => `(${c[0] + 1}, ${c[1] + 1})`;
  if (content.ice?.length) {
    out.push({
      key: "ice",
      label: `Ice on ${content.ice.length} cell${content.ice.length === 1 ? "" : "s"}`,
      remove: setList(content, "ice", []),
    });
  }
  (content.belts ?? []).forEach((b, i) =>
    out.push({
      key: `belt${i}`,
      label: `Belt at ${cell(b.cell)}, carries ${b.direction}`,
      remove: eraseTile(content, b.cell[0], b.cell[1]),
    }),
  );
  for (const [name, spec] of Object.entries(PAIR_FIELDS)) {
    pairsOf(content, spec.field).forEach((p, i) => {
      const w = WORDS[name as keyof typeof WORDS];
      const a = p[spec.a] as Cell;
      out.push({
        key: `${spec.field}${i}`,
        label: `${w[0]} ${cell(a)} and ${w[1]} ${cell(p[spec.b] as Cell)}${spec.field === "switches" && p.open ? ", gate starts open" : ""}`,
        remove: eraseTile(content, a[0], a[1]),
      });
    });
  }
  (content.patrols ?? []).forEach((g, i) =>
    out.push({
      key: `guard${i}`,
      label: `Guard, ${g.pattern === "loop" ? "ring" : "back and forth"}, ${g.cells.length} cells from ${cell(g.cells[0]!)}`,
      remove: eraseTile(content, g.cells[0]![0], g.cells[0]![1]),
    }),
  );
  return out;
}

/** Sets whether the gate of switch pair `index` starts open. */
export function setGateOpen(content: LevelContent, index: number, open: boolean): LevelContent {
  const list = (content.switches ?? []).map((s, i) => {
    if (i !== index) return s;
    const { open: _drop, ...rest } = s;
    return open ? { ...rest, open: true } : rest;
  });
  return setList(content, "switches", list);
}

/** Sets the pattern of guard `index`. */
export function setGuardPattern(
  content: LevelContent,
  index: number,
  pattern: "back_and_forth" | "loop",
): LevelContent {
  return setList(
    content,
    "patrols",
    (content.patrols ?? []).map((g, i) => (i === index ? { ...g, pattern } : g)),
  );
}

/** What a tool in progress remembers: the first cell of a pair, or the cells of a route so far. */
export type TileState = { pending: Cell | null; route: Cell[] };

export const NO_TILE_STATE: TileState = { pending: null, route: [] };

/** Applies a tile tool to a cell: places, turns or erases, or remembers a first cell. */
export function applyTileTool(
  content: LevelContent,
  tool: TileTool,
  x: number,
  y: number,
  state: TileState,
): { content: LevelContent; state: TileState } {
  const at: Cell = [x, y];
  if (tool === "erase") return { content: eraseTile(content, x, y), state: NO_TILE_STATE };
  if (tool === "ice") return { content: toggleIce(content, x, y), state: NO_TILE_STATE };
  if (tool === "belt") return { content: cycleBelt(content, x, y), state: NO_TILE_STATE };
  if (tool === "guard") {
    if (!isBare(content, x, y) || state.route.some((c) => same(c, at))) return { content, state };
    if (!continuesRoute(state.route, at)) return { content, state };
    return { content, state: { pending: null, route: [...state.route, at] } };
  }
  if (!state.pending) {
    return isBare(content, x, y)
      ? { content, state: { pending: at, route: [] } }
      : { content, state };
  }
  const next = isBare(content, x, y) ? addPair(content, tool, state.pending, at) : content;
  return { content: next, state: next === content ? state : NO_TILE_STATE };
}

/** Drops every tile that has a cell outside a board of this size (after the board shrinks). */
export function dropOutside(content: LevelContent, width: number, height: number): LevelContent {
  const inside = (c: Cell) => c[0] < width && c[1] < height;
  const next: Record<string, unknown> = { ...content };
  const keep = (field: string, test: (entry: never) => boolean) => {
    const list = (next[field] as never[] | undefined) ?? [];
    const kept = list.filter(test);
    if (kept.length === list.length) return;
    if (kept.length === 0) delete next[field];
    else next[field] = kept;
  };
  keep("ice", ((c: Cell) => inside(c)) as never);
  keep("belts", ((b: Belt) => inside(b.cell)) as never);
  for (const spec of Object.values(PAIR_FIELDS)) {
    keep(
      spec.field,
      ((p: Pair) => inside(p[spec.a] as Cell) && inside(p[spec.b] as Cell)) as never,
    );
  }
  keep("patrols", ((p: { cells: Cell[] }) => p.cells.every(inside)) as never);
  return next as LevelContent;
}
