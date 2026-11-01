import { CommandIcon } from "@/components/ui/command-icon";
import { TileGraphic } from "@/components/ui/tile-graphic";
import { TILE_TONE } from "@/lib/tile-variants";
import type { ScreenData } from "./screen-data";
import { TEXT } from "./svg-text";

export function TopBar({ data }: { data: ScreenData }) {
  return (
    <g>
      <TileGraphic look="depth" x={20} y={22} w={40} h={40} variant="ghost" chamfer={8}>
        <CommandIcon kind="back" cx={40} cy={42} size={18} tone={TILE_TONE.ghost} />
      </TileGraphic>
      <text
        x={195}
        y={37}
        fontSize={10}
        letterSpacing={2}
        textAnchor="middle"
        className="fill-mute"
        {...TEXT}
      >
        {`LEVEL ${data.levelNumber}`}
      </text>
      <text
        x={195}
        y={62}
        fontSize={22}
        letterSpacing={0.5}
        textAnchor="middle"
        className="fill-ink"
        {...TEXT}
      >
        {data.levelTitle}
      </text>
      <text x={328} y={56} fontSize={20} textAnchor="middle" className="fill-ink" {...TEXT}>
        ?
      </text>
      <g className="fill-ink" {...TEXT}>
        <rect x={346} y={44} width={22} height={3.5} />
        <rect x={346} y={51} width={22} height={3.5} />
        <rect x={346} y={58} width={22} height={3.5} />
      </g>
    </g>
  );
}
