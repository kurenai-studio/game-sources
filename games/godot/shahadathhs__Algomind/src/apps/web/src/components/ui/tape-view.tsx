import { TAPE_HEIGHT, TapeGraphic } from "@/components/ui/tape-graphic";
import type { Look } from "@/lib/look";
import type { TapeTile } from "@/lib/tape";

const WIDTH = 300;

/** A standalone tape as an inline SVG that scales to its container's width. */
export function TapeView({
  tiles,
  head,
  label,
  className = "block h-auto w-full",
  look = "flat",
}: {
  tiles: readonly TapeTile[];
  /** See TapeGraphic: omit for the editing state, or the index of the tile under the read-head. */
  head?: number;
  /** Accessible name describing the program. */
  label: string;
  className?: string;
  look?: Look;
}) {
  return (
    <svg
      viewBox={`0 -12 ${WIDTH} ${TAPE_HEIGHT + 12}`}
      role="img"
      aria-label={label}
      className={className}
    >
      <TapeGraphic tiles={tiles} width={WIDTH} head={head} look={look} />
    </svg>
  );
}
