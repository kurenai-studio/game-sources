import { useId } from "react";
import { TileMarks } from "@/components/ui/tile-marks";
import { tileShapes } from "@/lib/board-tiles";
import { DepthBoardGraphic } from "@/components/ui/depth-board-graphic";
import { type BoardData, DIR_ANGLE, hasPoint, samePoint } from "@/lib/board";
import { chamferPath, round2 } from "@/lib/geometry";
import type { Look } from "@/lib/look";

type Props = {
  board: BoardData;
  /** Top-left corner and side length of the board in the parent SVG's units. */
  x?: number;
  y?: number;
  size: number;
  /** "depth" draws the extruded board of the public site; the default is the flat board. */
  look?: Look;
};

const GAP = 2;

/**
 * The board, drawn from data: square cells with a 2-unit gap, hatched walls, a target (ring and
 * dot; none on a sweep board), trail cells with a square marker, breadcrumbs (an ink arrow toward
 * the cell behind), a yellow-striped wall for a failure, and the automaton (a chamfered block with
 * a wedge showing its facing). Meaning never rests on color alone.
 */
export function BoardGraphic({ board, x = 0, y = 0, size, look = "flat" }: Props) {
  const uid = useId().replace(/[^a-zA-Z0-9]/g, "");
  if (look === "depth") return <DepthBoardGraphic board={board} x={x} y={y} size={size} />;
  const hatchId = `hatch${uid}`;
  const stripeId = `stripe${uid}`;
  const cell = (size - GAP * (board.width - 1)) / board.width;
  const at = (p: { x: number; y: number }) => ({
    px: round2(x + p.x * (cell + GAP)),
    py: round2(y + p.y * (cell + GAP)),
  });
  const side = round2(cell);

  const crumbAt = (p: { x: number; y: number }) => board.crumbs?.find((c) => samePoint(c, p));
  const cells = [];
  for (let cy = 0; cy < board.height; cy++) {
    for (let cx = 0; cx < board.width; cx++) {
      const p = { x: cx, y: cy };
      const { px, py } = at(p);
      const mid = { x: px + cell / 2, y: py + cell / 2 };
      const key = `${cx}-${cy}`;
      if (board.hitWall && samePoint(board.hitWall, p)) {
        cells.push(
          <rect key={key} x={px} y={py} width={side} height={side} fill={`url(#${stripeId})`} />,
        );
      } else if (hasPoint(board.walls, p)) {
        cells.push(
          <rect key={key} x={px} y={py} width={side} height={side} fill={`url(#${hatchId})`} />,
        );
      } else if (board.goal && samePoint(board.goal, p)) {
        cells.push(
          <g key={key}>
            <rect x={px} y={py} width={side} height={side} className="fill-signal" />
            <circle
              cx={round2(mid.x)}
              cy={round2(mid.y)}
              r={round2(cell * 0.28)}
              className="fill-none stroke-ink"
              strokeWidth={round2(cell * 0.06)}
            />
            <circle
              cx={round2(mid.x)}
              cy={round2(mid.y)}
              r={round2(cell * 0.09)}
              className="fill-ink"
            />
          </g>,
        );
      } else if (crumbAt(p)) {
        const dir = crumbAt(p)!.dir;
        const s = cell * 0.26;
        cells.push(
          <g key={key}>
            <rect
              x={px}
              y={py}
              width={side}
              height={side}
              className={hasPoint(board.trail, p) ? "fill-trail" : "fill-floor"}
            />
            <path
              d={`M${-s} ${-s * 0.28}H${s * 0.1}V${-s * 0.8}L${s} 0L${s * 0.1} ${s * 0.8}V${s * 0.28}H${-s}Z`}
              className="fill-ink"
              transform={`translate(${round2(mid.x)} ${round2(mid.y)}) rotate(${DIR_ANGLE[dir]})`}
            />
          </g>,
        );
      } else if (hasPoint(board.trail, p)) {
        const m = cell * 0.17;
        cells.push(
          <g key={key}>
            <rect x={px} y={py} width={side} height={side} className="fill-trail" />
            <rect
              x={round2(mid.x - m / 2)}
              y={round2(mid.y - m / 2)}
              width={round2(m)}
              height={round2(m)}
              className="fill-signal stroke-ink"
              strokeWidth={round2(cell * 0.025)}
            />
          </g>,
        );
      } else {
        cells.push(
          <rect key={key} x={px} y={py} width={side} height={side} className="fill-floor" />,
        );
      }
    }
  }

  const a = at(board.automaton);
  const block = cell * 0.74;
  const bx = a.px + (cell - block) / 2;
  const by = a.py + (cell - block) / 2;
  const mx = a.px + cell / 2;
  const my = a.py + cell / 2;
  const wedge = block * 0.46;

  return (
    <g>
      <defs>
        <pattern
          id={hatchId}
          width={10}
          height={10}
          patternUnits="userSpaceOnUse"
          patternTransform="rotate(45)"
        >
          <rect width={10} height={10} className="fill-wall" />
          <rect width={4} height={10} className="fill-wall-hatch" />
        </pattern>
        <pattern
          id={stripeId}
          width={12}
          height={12}
          patternUnits="userSpaceOnUse"
          patternTransform="rotate(45)"
        >
          <rect width={12} height={12} className="fill-signal" />
          <rect width={5} height={12} className="fill-ink" />
        </pattern>
      </defs>
      {cells}
      <TileMarks
        shapes={tileShapes(board)}
        place={(tx, ty) => [x + tx * (cell + GAP), y + ty * (cell + GAP)]}
        unit={cell}
      />
      <path d={chamferPath(bx, by, block, block, block * 0.22)} className="fill-ink" />
      <path
        d={`M${round2(mx + wedge * 0.5)} ${round2(my)}L${round2(mx - wedge * 0.4)} ${round2(my - wedge * 0.5)}V${round2(my + wedge * 0.5)}Z`}
        className="fill-signal"
        transform={`rotate(${DIR_ANGLE[board.automaton.dir]} ${round2(mx)} ${round2(my)})`}
      />
    </g>
  );
}
