import { useId } from "react";
import { CommandIcon } from "@/components/ui/command-icon";
import { TileGraphic } from "@/components/ui/tile-graphic";
import type { Look } from "@/lib/look";
import { stepLabel, type TapeTile } from "@/lib/tape";
import { TILE_TONE, type TileVariant } from "@/lib/tile-variants";

export const TAPE_HEIGHT = 84;
const TILE = 52;
const PITCH = 62;
const TOP = 8;

const VARIANT: Record<TapeTile["state"], TileVariant> = {
  executed: "solid",
  current: "signal",
  failed: "signal",
  upcoming: "outline",
  empty: "dashed",
};

type Props = {
  tiles: readonly TapeTile[];
  /** Top-left corner and width of the strip in the parent SVG's units. Height is TAPE_HEIGHT. */
  x?: number;
  y?: number;
  width: number;
  /**
   * "start": left-aligned, no read-head (editing). A number: the index of the tile that sits under
   * the fixed read-head at the center of the strip (a run in progress).
   */
  head?: number;
  look?: Look;
};

/**
 * The program tape: a strip of instruction tiles under a fixed yellow read-head, with step numbers.
 * The read-head's triangle sits just above the strip, so leave 12 units free above `y`.
 */
export function TapeGraphic({ tiles, x = 0, y = 0, width, head, look = "flat" }: Props) {
  const clipId = `tape${useId().replace(/[^a-zA-Z0-9]/g, "")}`;
  const first = head === undefined ? x + 12 : x + width / 2 - TILE / 2 - head * PITCH;
  const center = x + width / 2;

  return (
    <g>
      <defs>
        <clipPath id={clipId}>
          <rect x={x} y={y} width={width} height={TAPE_HEIGHT} />
        </clipPath>
      </defs>
      <rect x={x} y={y} width={width} height={TAPE_HEIGHT} className="fill-strip" />
      {look === "depth" && (
        <>
          {/* The trough: a soft shadow along the top edge and a lit lower edge. */}
          <g className="fill-shadow">
            {[0, 1, 2, 3, 4].map((i) => (
              <rect
                key={i}
                x={x}
                y={y + i * 2}
                width={width}
                height={2}
                fillOpacity={0.32 * (1 - i / 5)}
              />
            ))}
          </g>
          <rect
            x={x}
            y={y + TAPE_HEIGHT - 1}
            width={width}
            height={1}
            className="fill-on-ink"
            fillOpacity={0.14}
          />
        </>
      )}
      <g clipPath={`url(#${clipId})`}>
        {tiles.map((tile, i) => {
          const tx = first + i * PITCH;
          if (tx > x + width || tx + TILE < x) return null;
          const variant = VARIANT[tile.state];
          const tone = TILE_TONE[variant];
          const ty = y + TOP;
          return (
            <g key={i}>
              <TileGraphic
                x={tx}
                y={ty}
                w={TILE}
                h={TILE}
                variant={variant}
                chamfer={11}
                look={look}
              >
                {tile.state === "failed" && (
                  <CommandIcon
                    kind="fail"
                    cx={tx + TILE / 2}
                    cy={ty + TILE / 2}
                    size={26}
                    tone={tone}
                  />
                )}
                {tile.state !== "failed" && tile.command && (
                  <CommandIcon
                    kind={tile.command}
                    cx={tx + TILE / 2}
                    cy={ty + TILE / 2}
                    size={26}
                    tone={tone}
                  />
                )}
                {tile.state === "empty" && tile.plus && (
                  <CommandIcon
                    kind="plus"
                    cx={tx + TILE / 2}
                    cy={ty + TILE / 2}
                    size={22}
                    tone={tone}
                  />
                )}
              </TileGraphic>
              {tile.step !== undefined && (
                <text
                  x={tx + TILE / 2}
                  y={ty + TILE + 14}
                  textAnchor="middle"
                  fontSize={11}
                  letterSpacing={1}
                  strokeWidth={0}
                  className={
                    tile.state === "current" || tile.state === "failed" ? "fill-ink" : "fill-mute"
                  }
                >
                  {stepLabel(tile.step)}
                </text>
              )}
            </g>
          );
        })}
      </g>
      {head !== undefined && (
        <>
          <rect x={center - 1.5} y={y - 1} width={3} height={TOP + 1} className="fill-signal" />
          <path
            d={`M${center - 8} ${y - 11}H${center + 8}L${center} ${y - 1}Z`}
            className="fill-signal"
          />
        </>
      )}
    </g>
  );
}
