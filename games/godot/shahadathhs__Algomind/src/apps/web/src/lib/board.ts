export type Dir = "N" | "E" | "S" | "W";
export type Point = { x: number; y: number };
export type Command =
  "move" | "left" | "right" | "inc" | "mark" | "repeat" | "until" | "if" | "proc" | "call";

/** Everything the board renderer needs. Cells are addressed from the top-left, x to the right. */
export type BoardData = {
  width: number;
  height: number;
  walls: Point[];
  /** The target cell. Absent on a board whose goal is to visit every cell: it draws no target. */
  goal?: Point;
  automaton: Point & { dir: Dir };
  /** Cells the automaton has passed (the visited cells on a sweep board). */
  trail?: Point[];
  /** Breadcrumbs: a marked cell and the direction its arrow points (to the cell behind). */
  crumbs?: (Point & { dir: Dir })[];
  /** The wall that stopped a failed run. */
  hitWall?: Point;
} & BoardTiles;

/** The tiles of the later worlds, drawn on the floor. Each is optional; absent means none. */
export type BoardTiles = {
  /** Ice: a move onto it slides on. */
  ice?: Point[];
  /** Belts: they carry the automaton one cell the way they point. */
  belts?: (Point & { dir: Dir })[];
  /** Keys and the doors they open (shown shut). */
  locks?: { key: Point; door: Point }[];
  /** Crates and the docks they belong on. */
  deliveries?: { item: Point; dock: Point }[];
  /** Switches and the gates they flip; `open` is a gate that starts open. */
  switches?: { switch: Point; gate: Point; open?: boolean }[];
  /** Teleporter pairs. */
  teleports?: { a: Point; b: Point }[];
  /** Guards: the route of each, drawn from its first cell. */
  patrols?: { pattern: "back_and_forth" | "loop"; cells: Point[] }[];
};

const DIR_OF: Record<string, Dir> = { north: "N", east: "E", south: "S", west: "W" };

type Json = Record<string, unknown>;

function pointOf(value: unknown): Point | null {
  if (!Array.isArray(value) || value.length !== 2) return null;
  const [x, y] = value as unknown[];
  return Number.isInteger(x) && Number.isInteger(y) ? { x: x as number, y: y as number } : null;
}

function listOf<T>(value: unknown, read: (item: unknown) => T | null): T[] | undefined {
  if (!Array.isArray(value)) return undefined;
  const out = value.map(read);
  return out.some((item) => item === null) || out.length === 0 ? undefined : (out as T[]);
}

function pairOf(item: unknown, a: string, b: string): { a: Point; b: Point; raw: Json } | null {
  if (typeof item !== "object" || item === null) return null;
  const raw = item as Json;
  const [pa, pb] = [pointOf(raw[a]), pointOf(raw[b])];
  return pa && pb ? { a: pa, b: pb, raw } : null;
}

/** The tiles of a level's content (any fields that are malformed are left out). */
export function tilesOf(content: Json): BoardTiles {
  const out: BoardTiles = {};
  out.ice = listOf(content.ice, pointOf);
  out.belts = listOf(content.belts, (item) => {
    if (typeof item !== "object" || item === null) return null;
    const cell = pointOf((item as Json).cell);
    const dir = DIR_OF[String((item as Json).direction)];
    return cell && dir ? { ...cell, dir } : null;
  });
  out.locks = listOf(content.locks, (item) => {
    const pair = pairOf(item, "key", "door");
    return pair && { key: pair.a, door: pair.b };
  });
  out.deliveries = listOf(content.deliveries, (item) => {
    const pair = pairOf(item, "item", "dock");
    return pair && { item: pair.a, dock: pair.b };
  });
  out.switches = listOf(content.switches, (item) => {
    const pair = pairOf(item, "switch", "gate");
    return pair && { switch: pair.a, gate: pair.b, open: pair.raw.open === true };
  });
  out.teleports = listOf(content.teleports, (item) => {
    const pair = pairOf(item, "a", "b");
    return pair && { a: pair.a, b: pair.b };
  });
  out.patrols = listOf(content.patrols, (item) => {
    if (typeof item !== "object" || item === null) return null;
    const cells = listOf((item as Json).cells, pointOf);
    const pattern = (item as Json).pattern === "loop" ? "loop" : "back_and_forth";
    return cells ? { pattern, cells } : null;
  });
  for (const key of Object.keys(out) as (keyof BoardTiles)[]) {
    if (out[key] === undefined) delete out[key];
  }
  return out;
}

/** Clockwise angle of the direction wedge, with east as zero. */
export const DIR_ANGLE: Record<Dir, number> = { E: 0, S: 90, W: 180, N: 270 };

export const COMMAND_LABEL: Record<Command, string> = {
  move: "MOVE",
  left: "LEFT",
  right: "RIGHT",
  inc: "COUNT",
  mark: "MARK",
  repeat: "REPEAT",
  until: "UNTIL",
  if: "IF",
  proc: "PROC",
  call: "CALL",
};

export function samePoint(a: Point, b: Point): boolean {
  return a.x === b.x && a.y === b.y;
}

export function hasPoint(list: readonly Point[] | undefined, p: Point): boolean {
  return list?.some((q) => samePoint(q, p)) ?? false;
}

/** A short plain-language description of a board, for the accessible name of its drawing. */
export function describeBoard(board: BoardData): string {
  const walls = board.walls.length === 1 ? "1 wall" : `${board.walls.length} walls`;
  const goal = board.goal ? "one target" : "no target, every cell to be visited";
  const extras = [
    board.ice && "ice",
    board.belts && "belts",
    board.locks && "keys and doors",
    board.deliveries && "crates",
    board.switches && "switches and gates",
    board.teleports && "teleporters",
    board.patrols && "guards",
  ].filter(Boolean);
  const more = extras.length > 0 ? ` It also has ${extras.join(", ")}.` : "";
  return `Board of ${board.width} by ${board.height} cells with ${walls} and ${goal}.${more}`;
}
