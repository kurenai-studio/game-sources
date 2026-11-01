import { TileGraphic } from "@/components/ui/tile-graphic";
import type { ScreenData } from "./screen-data";
import { SvgCaption, TEXT } from "./svg-text";

export function Stats({ data }: { data: ScreenData }) {
  const solved = data.stats;
  const stats = [
    { value: `${solved.used} / ${solved.limit}`, label: "COMMANDS" },
    { value: String(solved.steps), label: "STEPS" },
    { value: String(solved.best), label: "BEST" },
  ];
  return (
    <g>
      <SvgCaption x={20} y={640}>
        RESULT
      </SvgCaption>
      {stats.map((stat, i) => (
        <TileGraphic
          look="depth"
          key={stat.label}
          x={20 + i * 120}
          y={650}
          w={110}
          h={50}
          variant="ghost"
        >
          <text
            x={75 + i * 120}
            y={673}
            textAnchor="middle"
            fontSize={22}
            className="fill-ink"
            {...TEXT}
          >
            {stat.value}
          </text>
          <text
            x={75 + i * 120}
            y={691}
            textAnchor="middle"
            fontSize={9}
            letterSpacing={1.5}
            className="fill-mute"
            {...TEXT}
          >
            {stat.label}
          </text>
        </TileGraphic>
      ))}
    </g>
  );
}
