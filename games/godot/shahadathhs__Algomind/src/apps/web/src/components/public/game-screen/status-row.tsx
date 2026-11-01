import { CommandIcon } from "@/components/ui/command-icon";
import { TileGraphic } from "@/components/ui/tile-graphic";
import { TILE_TONE } from "@/lib/tile-variants";
import type { GameScreenState } from "../game-screen-view";
import { TEXT } from "./svg-text";

/** The row under the top bar: the goal and command count, or a plain-language result. */
export function StatusRow({
  state,
  count,
  budget,
}: {
  state: GameScreenState;
  /** The commands on the tape. */
  count: number;
  budget: number;
}) {
  if (state === "failed" || state === "solved") {
    const failed = state === "failed";
    return (
      <g>
        <TileGraphic look="depth" x={20} y={98} w={20} h={20} variant="signal" chamfer={4}>
          <CommandIcon
            kind={failed ? "fail" : "check"}
            cx={30}
            cy={108}
            size={13}
            tone={TILE_TONE.signal}
          />
        </TileGraphic>
        <text
          x={50}
          y={108}
          dy="0.35em"
          fontSize={13}
          letterSpacing={1}
          className="fill-ink"
          {...TEXT}
        >
          {failed ? "THE AUTOMATON TRIED TO MOVE INTO A" : "LEVEL SOLVED"}
        </text>
        {failed && (
          <text
            x={50}
            y={126}
            dy="0.35em"
            fontSize={13}
            letterSpacing={1}
            className="fill-ink"
            {...TEXT}
          >
            WALL
          </text>
        )}
      </g>
    );
  }
  return (
    <g>
      <text
        x={20}
        y={108}
        dy="0.35em"
        fontSize={13}
        letterSpacing={1}
        className="fill-ink"
        {...TEXT}
      >
        REACH THE TARGET
      </text>
      <text
        x={370}
        y={108}
        dy="0.35em"
        fontSize={13}
        letterSpacing={1}
        textAnchor="end"
        className="fill-mute"
        {...TEXT}
      >
        {`${count} / ${budget} COMMANDS`}
      </text>
    </g>
  );
}
