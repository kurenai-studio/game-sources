import type { BoardTiles, Dir, Point } from "@/lib/board";

/**
 * The tiles of the later worlds as shapes in board units (a cell is 1 by 1, the origin its top-left
 * corner). The renderers of the flat and the depth board map the points to their own space and draw
 * the shapes the same way. The shapes follow the game (apps/game/scripts/ui/*_draw.gd): ice is a
 * thin outline with two glints, a belt two chevrons, a key a ring with a shaft and a tooth, a shut
 * door a block with a keyhole, a crate a square with a strap, a dock four corner brackets, a switch
 * a plate with a lever, a shut gate a block with bars, a teleporter two rings, a guard a diamond
 * with a ring and a dot on a dotted route. A pair carries the same number of pips on both of its
 * cells, so the pairing is never only a color.
 */
export type Pt = readonly [number, number];

/** How a shape is painted: ink, the quiet hatch color, ink on an ink block, or the floor color. */
export type Tone = "ink" | "soft" | "onink" | "floor";

export type Shape = {
  /** A filled polygon, or an open or closed line. */
  kind: "fill" | "line";
  points: Pt[];
  tone: Tone;
  /** Line width in cells. */
  width?: number;
  closed?: boolean;
};

const VECTOR: Record<Dir, Pt> = { N: [0, -1], E: [1, 0], S: [0, 1], W: [-1, 0] };
const RING_STEPS = 20;

function box(x0: number, y0: number, x1: number, y1: number): Pt[] {
  return [
    [x0, y0],
    [x1, y0],
    [x1, y1],
    [x0, y1],
  ];
}

function ring(cx: number, cy: number, r: number): Pt[] {
  return Array.from({ length: RING_STEPS }, (_, i) => {
    const a = (i / RING_STEPS) * Math.PI * 2;
    return [cx + Math.cos(a) * r, cy + Math.sin(a) * r] as Pt;
  });
}

/** Moves a shape of the unit cell onto the cell at `at`. */
function onCell(at: Point, shapes: Shape[]): Shape[] {
  return shapes.map((s) => ({
    ...s,
    points: s.points.map(([x, y]) => [at.x + x, at.y + y] as Pt),
  }));
}

function pips(count: number, index: number, tone: Tone): Shape[] {
  if (count < 2) return [];
  return Array.from({ length: index + 1 }, (_, n) => {
    const cx = 0.5 + (n - index / 2) * 0.16;
    return { kind: "fill", points: box(cx - 0.05, 0.81, cx + 0.05, 0.91), tone } as Shape;
  });
}

function ice(): Shape[] {
  return [
    { kind: "line", points: box(0.1, 0.1, 0.9, 0.9), tone: "soft", width: 0.04, closed: true },
    {
      kind: "line",
      points: [
        [0.28, 0.5],
        [0.5, 0.28],
      ],
      tone: "soft",
      width: 0.06,
    },
    {
      kind: "line",
      points: [
        [0.44, 0.74],
        [0.74, 0.44],
      ],
      tone: "soft",
      width: 0.06,
    },
  ];
}

function belt(dir: Dir): Shape[] {
  const [dx, dy] = VECTOR[dir];
  const [ax, ay] = [-dy, dx];
  return [-0.14, 0.14].map((offset) => {
    const back = [0.5 + dx * (offset - 0.1), 0.5 + dy * (offset - 0.1)];
    return {
      kind: "line",
      tone: "ink",
      width: 0.09,
      points: [
        [back[0]! + ax * 0.22, back[1]! + ay * 0.22],
        [0.5 + dx * (offset + 0.1), 0.5 + dy * (offset + 0.1)],
        [back[0]! - ax * 0.22, back[1]! - ay * 0.22],
      ],
    } as Shape;
  });
}

function key(count: number, index: number): Shape[] {
  return [
    { kind: "fill", points: ring(0.34, 0.46, 0.17), tone: "ink" },
    { kind: "fill", points: ring(0.34, 0.46, 0.075), tone: "floor" },
    { kind: "fill", points: box(0.48, 0.42, 0.82, 0.5), tone: "ink" },
    { kind: "fill", points: box(0.72, 0.5, 0.8, 0.64), tone: "ink" },
    ...pips(count, index, "ink"),
  ];
}

function shutBlock(count: number, index: number, bars: boolean): Shape[] {
  const block: Shape = { kind: "fill", points: box(0.1, 0.1, 0.9, 0.9), tone: "ink" };
  const detail: Shape[] = bars
    ? [0.28, 0.5, 0.72].map(
        (x) =>
          ({ kind: "fill", points: box(x - 0.04, 0.2, x + 0.04, 0.8), tone: "onink" }) as Shape,
      )
    : [
        { kind: "fill", points: ring(0.5, 0.4, 0.1), tone: "onink" },
        {
          kind: "fill",
          points: [
            [0.45, 0.46],
            [0.55, 0.46],
            [0.58, 0.68],
            [0.42, 0.68],
          ],
          tone: "onink",
        },
      ];
  return [block, ...detail, ...pips(count, index, "onink")];
}

function crate(cx: number, cy: number, size: number): Shape[] {
  const half = size / 2;
  const inner = half * 0.78;
  return [
    { kind: "fill", points: box(cx - half, cy - half, cx + half, cy + half), tone: "ink" },
    { kind: "fill", points: box(cx - inner, cy - inner, cx + inner, cy + inner), tone: "floor" },
    {
      kind: "fill",
      points: box(cx - inner, cy - size * 0.07, cx + inner, cy + size * 0.07),
      tone: "ink",
    },
  ];
}

function dock(count: number, index: number): Shape[] {
  const out: Shape[] = [];
  for (const [fx, fy] of [
    [false, false],
    [true, false],
    [false, true],
    [true, true],
  ] as const) {
    const [sx, sy] = [fx ? -1 : 1, fy ? -1 : 1];
    const corner: Pt = [fx ? 0.86 : 0.14, fy ? 0.86 : 0.14];
    out.push({
      kind: "fill",
      points: box(corner[0], corner[1], corner[0] + sx * 0.2, corner[1] + sy * 0.06),
      tone: "ink",
    });
    out.push({
      kind: "fill",
      points: box(corner[0], corner[1], corner[0] + sx * 0.06, corner[1] + sy * 0.2),
      tone: "ink",
    });
  }
  return [...out, ...pips(count, index, "ink")];
}

function plate(count: number, index: number): Shape[] {
  return [
    { kind: "line", points: box(0.18, 0.18, 0.82, 0.82), tone: "ink", width: 0.05, closed: true },
    { kind: "fill", points: box(0.3, 0.46, 0.7, 0.52), tone: "ink" },
    { kind: "fill", points: box(0.27, 0.38, 0.45, 0.6), tone: "ink" },
    ...pips(count, index, "ink"),
  ];
}

function openGate(count: number, index: number): Shape[] {
  return [
    { kind: "fill", points: box(0.1, 0.4, 0.22, 0.6), tone: "ink" },
    { kind: "fill", points: box(0.78, 0.4, 0.9, 0.6), tone: "ink" },
    ...pips(count, index, "ink"),
  ];
}

function portal(count: number, index: number): Shape[] {
  const c: Pt = count > 1 ? [0.5, 0.45] : [0.5, 0.5];
  return [
    { kind: "line", points: ring(c[0], c[1], 0.32), tone: "ink", width: 0.06, closed: true },
    { kind: "line", points: ring(c[0], c[1], 0.17), tone: "ink", width: 0.06, closed: true },
    ...pips(count, index, "ink"),
  ];
}

/** The route of a guard as a dotted line, and the diamond on its first cell. */
function guard(cells: Point[], loop: boolean): Shape[] {
  const centers = cells.map((c) => [c.x + 0.5, c.y + 0.5] as Pt);
  const route: Pt[] = loop && centers.length > 0 ? [...centers, centers[0]!] : centers;
  const first = cells[0];
  if (!first) return [];
  const [cx, cy] = [first.x + 0.5, first.y + 0.5];
  return [
    { kind: "line", points: route, tone: "soft", width: 0.06 },
    ...centers.map(
      (c) => ({ kind: "fill", points: ring(c[0], c[1], 0.05), tone: "soft" }) as Shape,
    ),
    {
      kind: "fill",
      points: [
        [cx, cy - 0.34],
        [cx + 0.34, cy],
        [cx, cy + 0.34],
        [cx - 0.34, cy],
      ],
      tone: "ink",
    },
    { kind: "line", points: ring(cx, cy, 0.17), tone: "onink", width: 0.05, closed: true },
    { kind: "fill", points: ring(cx, cy, 0.07), tone: "onink" },
  ];
}

/** Every tile of the board as shapes, floor tiles first and guards last. */
export function tileShapes(board: BoardTiles): Shape[] {
  const out: Shape[] = [];
  for (const p of board.ice ?? []) out.push(...onCell(p, ice()));
  for (const b of board.belts ?? []) out.push(...onCell(b, belt(b.dir)));
  const locks = board.locks ?? [];
  locks.forEach((l, i) => {
    out.push(...onCell(l.key, key(locks.length, i)));
    out.push(...onCell(l.door, shutBlock(locks.length, i, false)));
  });
  const deliveries = board.deliveries ?? [];
  deliveries.forEach((d, i) => {
    out.push(...onCell(d.dock, dock(deliveries.length, i)));
    out.push(...onCell(d.item, [...crate(0.5, 0.44, 0.5), ...pips(deliveries.length, i, "ink")]));
  });
  const switches = board.switches ?? [];
  switches.forEach((s, i) => {
    out.push(...onCell(s.switch, plate(switches.length, i)));
    out.push(
      ...onCell(
        s.gate,
        s.open ? openGate(switches.length, i) : shutBlock(switches.length, i, true),
      ),
    );
  });
  const teleports = board.teleports ?? [];
  teleports.forEach((t, i) => {
    out.push(...onCell(t.a, portal(teleports.length, i)));
    out.push(...onCell(t.b, portal(teleports.length, i)));
  });
  for (const g of board.patrols ?? []) out.push(...guard(g.cells, g.pattern === "loop"));
  return out;
}
