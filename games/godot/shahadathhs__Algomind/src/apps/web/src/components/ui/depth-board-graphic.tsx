import { TileMarks } from "@/components/ui/tile-marks";
import { tileShapes } from "@/lib/board-tiles";
import type { ReactNode } from "react";
import { type BoardData, hasPoint, samePoint } from "@/lib/board";
import { BoardProjection, DIR_VECTOR, type Pt, UNIT, Z } from "@/lib/board-projection";

/** Class names written out in full so Tailwind finds them; the colors are the depth tokens. */
const SURFACE = {
  plate: {
    top: "fill-plate",
    front: "fill-plate-front",
    side: "fill-plate-side",
    edge: "stroke-plate-edge",
  },
  floor: {
    top: "fill-floor",
    front: "fill-floor-front",
    side: "fill-floor-side",
    edge: "stroke-floor-edge",
  },
  trail: {
    top: "fill-trail",
    front: "fill-trail-front",
    side: "fill-trail-side",
    edge: "stroke-trail-edge",
  },
  goal: {
    top: "fill-signal",
    front: "fill-signal-front",
    side: "fill-signal-side",
    edge: "stroke-signal-edge",
  },
  wall: {
    top: "fill-wall",
    front: "fill-wall-front",
    side: "fill-wall-side",
    edge: "stroke-wall-edge",
  },
  auto: {
    top: "fill-ink",
    front: "fill-ink-front",
    side: "fill-ink-side",
    edge: "stroke-ink-edge",
  },
} as const;
type Surface = (typeof SURFACE)[keyof typeof SURFACE];

const INSET = 0.035;
const pts = (list: readonly Pt[]) =>
  list.map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join(" ");
const cellFootprint = (x: number, y: number, inset = INSET, side = 1): Pt[] => [
  [x + inset, y + inset],
  [x + side - inset, y + inset],
  [x + side - inset, y + side - inset],
  [x + inset, y + side - inset],
];

/** The side faces the camera sees, then the top with a lit edge; one extruded piece. */
function prism(
  view: BoardProjection,
  footprint: readonly Pt[],
  z0: number,
  z1: number,
  surface: Surface,
  id: string,
): ReactNode {
  const area = footprint.reduce((sum, p, i) => {
    const q = footprint[(i + 1) % footprint.length]!;
    return sum + p[0] * q[1] - q[0] * p[1];
  }, 0);
  const ring = area < 0 ? [...footprint].reverse() : footprint;
  const faces: ReactNode[] = [];
  ring.forEach((a, i) => {
    const b = ring[(i + 1) % ring.length]!;
    const [dx, dy] = [b[0] - a[0], b[1] - a[1]];
    const len = Math.hypot(dx, dy);
    const [nx, ny] = [dy / len, -dx / len];
    if (!view.sees((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, nx, ny)) return;
    const quad = [
      view.project(a[0], a[1], z1),
      view.project(b[0], b[1], z1),
      view.project(b[0], b[1], z0),
      view.project(a[0], a[1], z0),
    ];
    faces.push(
      <polygon
        key={`${id}f${i}`}
        points={pts(quad)}
        className={nx > 0.3 ? surface.side : surface.front}
      />,
    );
  });
  const top = ring.map(([x, y]) => view.project(x, y, z1));
  return (
    <g key={id}>
      {faces}
      <polygon points={pts(top)} className={`${surface.top} ${surface.edge}`} strokeWidth={1} />
    </g>
  );
}

/** A soft shadow: stacked translucent copies of the shape, growing outward. */
function softShadow(points: readonly Pt[], spread: number, id: string, alpha = 0.4): ReactNode {
  const layers = 5;
  const cx = points.reduce((s, p) => s + p[0], 0) / points.length;
  const cy = points.reduce((s, p) => s + p[1], 0) / points.length;
  return (
    <g key={id} className="fill-shadow">
      {Array.from({ length: layers }, (_, i) => {
        const grow = (spread * (layers - i)) / layers;
        const grown = points.map(([x, y]) => {
          const d = Math.hypot(x - cx, y - cy) || 1;
          return [x + ((x - cx) / d) * grow, y + ((y - cy) / d) * grow] as const;
        });
        return <polygon key={i} points={pts(grown)} fillOpacity={alpha / layers} />;
      })}
    </g>
  );
}

/** The depth board's drawing space: where it sits, so a caller can fit it into a viewBox. */
export function depthBoardBounds(board: BoardData) {
  return new BoardProjection(board.width, board.height).bounds();
}

/**
 * The board in the depth look: an extruded board on a plate, drawn from the same data as the flat
 * board. The camera is fixed and depends on the board size. Fitted and centered in the square at
 * (x, y) with side `size`. Meaning never rests on color alone: the target keeps its ring, a passed
 * cell its marker, a failed wall its stripes, the automaton its wedge.
 */
export function DepthBoardGraphic({
  board,
  x = 0,
  y = 0,
  size,
}: {
  board: BoardData;
  x?: number;
  y?: number;
  size: number;
}) {
  const view = new BoardProjection(board.width, board.height);
  const box = view.bounds();
  const scale = size / Math.max(box.width, box.height);
  const move = `translate(${(x + (size - box.width * scale) / 2 - box.x * scale).toFixed(2)} ${(y + (size - box.height * scale) / 2 - box.y * scale).toFixed(2)}) scale(${scale.toFixed(4)})`;
  const shadowOf = (footprint: readonly Pt[], dx = 0.2, dy = 0.14) =>
    footprint.map(([fx, fy]) => view.project(fx + dx, fy + dy, Z.floor));

  const margin = 0.3;
  const plate: Pt[] = [
    [-margin, -margin],
    [board.width + margin, -margin],
    [board.width + margin, board.height + margin],
    [-margin, board.height + margin],
  ];
  const under: ReactNode[] = [
    softShadow(
      plate.map(([px, py]) => view.project(px + 0.1, py + 0.35, Z.plate)),
      UNIT * 0.22,
      "plate-shadow",
    ),
    prism(view, plate, Z.plate, 0, SURFACE.plate, "plate"),
  ];
  const marks: ReactNode[] = [];
  const shadows: ReactNode[] = [];
  const items: { depth: number; node: ReactNode }[] = [];

  for (let cy = 0; cy < board.height; cy++) {
    for (let cx = 0; cx < board.width; cx++) {
      const p = { x: cx, y: cy };
      const key = `${cx}-${cy}`;
      const wall = hasPoint(board.walls, p);
      const hit = board.hitWall !== undefined && samePoint(board.hitWall, p);
      if (wall || hit) {
        shadows.push(softShadow(shadowOf(cellFootprint(cx, cy)), UNIT * 0.1, `ws${key}`, 0.4));
        const lines: ReactNode[] = [];
        for (let c = 0.1; c < 1.95; c += hit ? 0.34 : 0.28) {
          const a = view.project(cx + Math.max(0, c - 1), cy + c - Math.max(0, c - 1), Z.wall);
          const b = view.project(cx + Math.min(c, 1), cy + c - Math.min(c, 1), Z.wall);
          lines.push(
            <line
              key={c}
              x1={a[0].toFixed(1)}
              y1={a[1].toFixed(1)}
              x2={b[0].toFixed(1)}
              y2={b[1].toFixed(1)}
              className={hit ? "stroke-signal" : "stroke-wall-hatch"}
              strokeWidth={UNIT * (hit ? 0.17 : 0.1)}
            />,
          );
        }
        items.push({
          depth: view.depth(cx + 0.5, cy + 0.5),
          node: (
            <g key={`w${key}`}>
              {prism(view, cellFootprint(cx, cy), 0, Z.wall, SURFACE.wall, `wp${key}`)}
              {lines}
            </g>
          ),
        });
        continue;
      }
      const isGoal = board.goal !== undefined && samePoint(board.goal, p);
      const passed = hasPoint(board.trail, p);
      const surface = isGoal ? SURFACE.goal : passed ? SURFACE.trail : SURFACE.floor;
      const height = isGoal ? Z.goal : Z.floor;
      under.push(prism(view, cellFootprint(cx, cy), 0, height, surface, `c${key}`));
      const at = (px: number, py: number) => view.project(px, py, height);
      if (isGoal) {
        const ring = Array.from({ length: 40 }, (_, i) => {
          const a = (i / 40) * Math.PI * 2;
          return at(cx + 0.5 + Math.cos(a) * 0.27, cy + 0.5 + Math.sin(a) * 0.27);
        });
        const dot = Array.from({ length: 40 }, (_, i) => {
          const a = (i / 40) * Math.PI * 2;
          return at(cx + 0.5 + Math.cos(a) * 0.1, cy + 0.5 + Math.sin(a) * 0.1);
        });
        marks.push(
          <g key={`g${key}`}>
            <polygon
              points={pts(ring)}
              className="fill-none stroke-on-signal"
              strokeWidth={UNIT * 0.07}
            />
            <polygon points={pts(dot)} className="fill-on-signal" />
          </g>,
        );
      } else if (passed) {
        const crumb = board.crumbs?.find((c) => samePoint(c, p));
        if (crumb) {
          const [vx, vy] = DIR_VECTOR[crumb.dir];
          const [sx, sy] = [-vy * 0.17, vx * 0.17];
          const [mx, my] = [cx + 0.5, cy + 0.5];
          const arrow = [
            at(mx + vx * 0.34, my + vy * 0.34),
            at(mx - vx * 0.2 + sx, my - vy * 0.2 + sy),
            at(mx - vx * 0.2 - sx, my - vy * 0.2 - sy),
          ];
          marks.push(<polygon key={`m${key}`} points={pts(arrow)} className="fill-ink" />);
        } else {
          const marker = cellFootprint(cx + 0.4, cy + 0.4, 0, 0.2).map(([mx, my]) => at(mx, my));
          marks.push(
            <polygon
              key={`m${key}`}
              points={pts(marker)}
              className="fill-signal stroke-ink"
              strokeWidth={1.2}
            />,
          );
        }
      }
    }
  }

  const a = board.automaton;
  const onGoal = board.goal !== undefined && samePoint(board.goal, a);
  const base = onGoal ? Z.goal : Z.floor;
  const [lo, hi, cut] = [0.17, 0.83, 0.14];
  const body: Pt[] = [
    [a.x + lo, a.y + lo],
    [a.x + hi - cut, a.y + lo],
    [a.x + hi, a.y + lo + cut],
    [a.x + hi, a.y + hi],
    [a.x + lo, a.y + hi],
  ];
  const [dx, dy] = DIR_VECTOR[a.dir];
  const [sx, sy] = [-dy, dx];
  const top = base + Z.automaton;
  const wedge = [
    [a.x + 0.5 + dx * 0.27, a.y + 0.5 + dy * 0.27],
    [a.x + 0.5 - dx * 0.1 + sx * 0.2, a.y + 0.5 - dy * 0.1 + sy * 0.2],
    [a.x + 0.5 - dx * 0.1 - sx * 0.2, a.y + 0.5 - dy * 0.1 - sy * 0.2],
  ].map(([wx, wy]) => view.project(wx!, wy!, top + 0.003));
  shadows.push(
    softShadow(
      shadowOf(cellFootprint(a.x + 0.17, a.y + 0.17, 0, 0.66)),
      UNIT * 0.12,
      "auto-shadow",
      0.42,
    ),
  );
  items.push({
    depth: view.depth(a.x + 0.5, a.y + 0.5),
    node: (
      <g key="auto">
        {prism(view, body, base, top, SURFACE.auto, "auto-body")}
        <polygon points={pts(wedge)} className="fill-signal" />
      </g>
    ),
  });
  items.sort((p, q) => p.depth - q.depth);

  return (
    <g transform={move}>
      {under}
      {shadows}
      {marks}
      <TileMarks
        shapes={tileShapes(board)}
        place={(tx, ty) => view.project(tx, ty, Z.floor)}
        unit={UNIT}
      />
      {items.map((item) => item.node)}
    </g>
  );
}
