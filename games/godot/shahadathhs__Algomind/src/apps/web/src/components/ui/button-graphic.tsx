import { CommandIcon, type IconKind } from "@/components/ui/command-icon";
import { TileGraphic } from "@/components/ui/tile-graphic";
import type { Look } from "@/lib/look";
import { TILE_TONE } from "@/lib/tile-variants";

type Props = {
  x: number;
  y: number;
  w: number;
  h: number;
  label: string;
  icon?: IconKind;
  /** The one primary action of a drawn screen (yellow). Others are outlined. */
  primary?: boolean;
  fontSize?: number;
  look?: Look;
};

/** A button or command tile drawn in SVG: icon and label centered on a chamfered tile. */
export function ButtonGraphic({
  x,
  y,
  w,
  h,
  label,
  icon,
  primary,
  fontSize = 12,
  look = "flat",
}: Props) {
  const variant = primary ? "signal" : "ghost";
  const tone = TILE_TONE[variant];
  const spacing = 1;
  const iconSize = Math.round(fontSize * 1.5);
  // Approximate text width; the labels are short capitals in a condensed face.
  const textWidth = label.length * (fontSize * 0.56 + spacing);
  const total = (icon ? iconSize + 7 : 0) + textWidth;
  const left = x + (w - total) / 2;
  const cy = y + h / 2;
  return (
    <TileGraphic x={x} y={y} w={w} h={h} variant={variant} look={look}>
      {icon && (
        <CommandIcon kind={icon} cx={left + iconSize / 2} cy={cy} size={iconSize} tone={tone} />
      )}
      <text
        x={left + (icon ? iconSize + 7 : 0)}
        y={cy}
        dy="0.35em"
        fontSize={fontSize}
        letterSpacing={spacing}
        className={tone}
        strokeWidth={0}
      >
        {label}
      </text>
    </TileGraphic>
  );
}
