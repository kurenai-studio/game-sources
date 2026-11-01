import type { Pt, Shape, Tone } from "@/lib/board-tiles";
import { round2 } from "@/lib/geometry";

const FILL: Record<Tone, string> = {
  ink: "fill-ink",
  soft: "fill-wall-hatch",
  onink: "fill-on-ink",
  floor: "fill-floor",
};
const STROKE: Record<Tone, string> = {
  ink: "stroke-ink",
  soft: "stroke-wall-hatch",
  onink: "stroke-on-ink",
  floor: "stroke-floor",
};

/**
 * Draws tile shapes (board units) into SVG. `place` maps a point in board units to the drawing
 * space; `unit` is how many drawing units one cell is wide, which sets the line widths.
 */
export function TileMarks({
  shapes,
  place,
  unit,
}: {
  shapes: Shape[];
  place: (x: number, y: number) => Pt;
  unit: number;
}) {
  return (
    <g aria-hidden="true">
      {shapes.map((shape, i) => {
        const points = shape.points
          .map(([x, y]) => place(x, y))
          .map(([px, py]) => `${round2(px)},${round2(py)}`)
          .join(" ");
        if (shape.kind === "fill") {
          return <polygon key={i} points={points} className={FILL[shape.tone]} />;
        }
        const Tag = shape.closed ? "polygon" : "polyline";
        return (
          <Tag
            key={i}
            points={points}
            className={`fill-none ${STROKE[shape.tone]}`}
            strokeWidth={round2((shape.width ?? 0.05) * unit)}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        );
      })}
    </g>
  );
}
