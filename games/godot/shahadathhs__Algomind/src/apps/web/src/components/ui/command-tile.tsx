import { CommandIcon } from "@/components/ui/command-icon";
import { TileGraphic } from "@/components/ui/tile-graphic";
import type { Command } from "@/lib/board";
import { TILE_TONE } from "@/lib/tile-variants";

/** One command tile (outlined, icon only) as a small inline SVG. Decorative: label it in text. */
export function CommandTile({ command, size = 56 }: { command: Command; size?: number }) {
  return (
    <svg viewBox="0 0 56 56" width={size} height={size} aria-hidden="true" className="shrink-0">
      <TileGraphic look="depth" x={0} y={0} w={56} h={56} variant="outline" chamfer={12}>
        <CommandIcon kind={command} cx={28} cy={28} size={28} tone={TILE_TONE.outline} />
      </TileGraphic>
    </svg>
  );
}
