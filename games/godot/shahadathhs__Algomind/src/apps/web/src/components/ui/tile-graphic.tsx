import type { ReactNode } from "react";
import { chamferOutline, chamferPath, insetChamfer } from "@/lib/geometry";
import type { Look } from "@/lib/look";
import { TILE_FILL, TILE_INNER_FILL, type TileVariant } from "@/lib/tile-variants";

/** The face and lip of a key, by variant (class names in full so Tailwind finds them). */
const KEY: Partial<Record<TileVariant, { face: string; lip: string }>> = {
  solid: { face: "fill-ink", lip: "fill-ink-lip" },
  signal: { face: "fill-signal", lip: "fill-signal-lip" },
  outline: { face: "fill-tile", lip: "fill-tile-lip" },
  ghost: { face: "fill-tile", lip: "fill-tile-lip" },
  faint: { face: "fill-tile", lip: "fill-tile-lip" },
};
const SHADOW_LAYERS = 4;

type Props = {
  x: number;
  y: number;
  w: number;
  h: number;
  variant: TileVariant;
  /** Chamfer size; defaults to 0.2 of the shorter side, as in the design guide. */
  chamfer?: number;
  /** Outline thickness for the outlined variants. */
  line?: number;
  /** "depth" draws a key with a lip and a soft shadow; the default is the flat tile. */
  look?: Look;
  children?: ReactNode;
};

/** A tile drawn in SVG: a rectangle with the top-right corner cut. Children draw on top of it. */
export function TileGraphic({
  x,
  y,
  w,
  h,
  variant,
  chamfer,
  line = 2,
  look = "flat",
  children,
}: Props) {
  const c = chamfer ?? Math.round(Math.min(w, h) * 0.2);
  const inner = TILE_INNER_FILL[variant];

  let shape: ReactNode;
  const key = KEY[variant];
  if (look === "depth" && key) {
    // The lip stays under the face; the face is the tile minus the lip, so the key keeps its box.
    const lip = Math.max(2, Math.min(4, Math.round(h * 0.07)));
    const face = h - lip;
    shape = (
      <g opacity={variant === "faint" ? 0.55 : undefined}>
        <g className="fill-shadow">
          {Array.from({ length: SHADOW_LAYERS }, (_, i) => {
            const grow = ((SHADOW_LAYERS - i) * 5) / SHADOW_LAYERS;
            return (
              <path
                key={i}
                d={chamferPath(x - grow, y + lip * 1.8 - grow, w + 2 * grow, face + 2 * grow, c)}
                fillOpacity={0.26 / SHADOW_LAYERS}
              />
            );
          })}
        </g>
        <path d={chamferPath(x, y + lip, w, face, c)} className={key.lip} />
        <path d={chamferPath(x, y, w, face, c)} className={key.face} />
      </g>
    );
  } else if (variant === "dashed") {
    shape = (
      <path
        d={chamferPath(x + 1, y + 1, w - 2, h - 2, insetChamfer(c, 1))}
        className="fill-none stroke-slot"
        strokeWidth={2}
        strokeDasharray="5 4"
      />
    );
  } else if (inner) {
    const { outer, inner: innerPath } = chamferOutline(x, y, w, h, c, line);
    shape = (
      <>
        <path d={outer} className={TILE_FILL[variant]} />
        <path d={innerPath} className={inner} />
      </>
    );
  } else {
    shape = <path d={chamferPath(x, y, w, h, c)} className={TILE_FILL[variant]} />;
  }

  return (
    <g>
      {shape}
      {children}
    </g>
  );
}
