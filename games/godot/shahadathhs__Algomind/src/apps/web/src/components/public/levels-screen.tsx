import { ButtonGraphic } from "@/components/ui/button-graphic";
import { CommandIcon } from "@/components/ui/command-icon";
import { TileGraphic } from "@/components/ui/tile-graphic";
import { SCREEN_HEIGHT, SCREEN_WIDTH } from "@/components/public/game-screen";
import { LANDING_WORLD } from "@/lib/landing-level";
import { TILE_TONE, type TileVariant } from "@/lib/tile-variants";

type LevelState = "solved" | "current" | "locked" | "download";

const VARIANT: Record<LevelState, TileVariant> = {
  solved: "solid",
  current: "signal",
  locked: "faint",
  download: "dashed",
};

const TILE = 58;
const GAP = 10;
const PER_ROW = 5;
const TEXT = { strokeWidth: 0 } as const;

type Placed = { number: number; state: LevelState; x: number; y: number };

/**
 * The state of level `index` (zero-based) in the world: the first three are solved, the next is
 * current, the last two are not downloaded, and the rest are locked. It shows the four states the
 * game has; it is an illustration, not anyone's progress.
 */
function stateOf(index: number, total: number): LevelState {
  if (index < 3) return "solved";
  if (index === 3) return "current";
  return index >= total - 2 ? "download" : "locked";
}

/** Tile positions and chapter captions for the real world: its chapters and level numbers. */
function layout() {
  const total = LANDING_WORLD.chapters.reduce((sum, chapter) => sum + chapter.levels, 0);
  const tiles: Placed[] = [];
  const captions: { text: string; y: number }[] = [];
  let y = 188;
  let n = 0;
  LANDING_WORLD.chapters.forEach((chapter, c) => {
    captions.push({ text: `CHAPTER ${c + 1} · ${chapter.title.toUpperCase()}`, y });
    for (let i = 0; i < chapter.levels; i += 1) {
      tiles.push({
        number: LANDING_WORLD.first + n,
        state: stateOf(n, total),
        x: 20 + (i % PER_ROW) * (TILE + GAP),
        y: y + 14 + Math.floor(i / PER_ROW) * (TILE + GAP),
      });
      n += 1;
    }
    y += 14 + Math.ceil(chapter.levels / PER_ROW) * (TILE + GAP) + 18;
  });
  return { tiles, captions, bottom: y };
}

const { tiles, captions, bottom } = layout();
const count = (state: LevelState) => tiles.filter((t) => t.state === state).length;
const current = tiles.find((t) => t.state === "current")!;

const LEGEND: { state: LevelState; label: string }[] = [
  { state: "solved", label: `${count("solved")} SOLVED` },
  { state: "current", label: `${count("current")} CURRENT` },
  { state: "locked", label: `${count("locked")} LOCKED` },
  { state: "download", label: `${count("download")} NOT DOWNLOADED` },
];

/** The world screen: the real world's chapters with a tile per level, in four states that each
 * carry a shape or icon as well as a look. */
export function LevelsScreen({ className }: { className?: string }) {
  return (
    <svg
      viewBox={`0 0 ${SCREEN_WIDTH} ${SCREEN_HEIGHT}`}
      role="img"
      aria-label={`World ${LANDING_WORLD.number}, ${LANDING_WORLD.title}: ${tiles.length} level tiles in ${captions.length} chapters. ${count("solved")} are solved, one is current, ${count("locked")} are locked and ${count("download")} are not downloaded. A Play level ${current.number} button sits at the bottom.`}
      className={className ?? "block h-auto w-full"}
    >
      <TileGraphic look="depth" x={20} y={22} w={40} h={40} variant="ghost" chamfer={8}>
        <CommandIcon kind="back" cx={40} cy={42} size={18} tone={TILE_TONE.ghost} />
      </TileGraphic>
      <text x={20} y={104} fontSize={10} letterSpacing={2} className="fill-mute" {...TEXT}>
        {`WORLD ${String(LANDING_WORLD.number).padStart(2, "0")}`}
      </text>
      <text x={20} y={138} fontSize={32} letterSpacing={0.5} className="fill-ink" {...TEXT}>
        {LANDING_WORLD.title.toUpperCase()}
      </text>
      <text x={20} y={160} fontSize={9} letterSpacing={1} className="fill-mute" {...TEXT}>
        {LANDING_WORLD.summary.toUpperCase().replace(/\.$/, "")}
      </text>
      {captions.map((caption) => (
        <text
          key={caption.text}
          x={20}
          y={caption.y + 6}
          fontSize={9}
          letterSpacing={2}
          className="fill-mute"
          {...TEXT}
        >
          {caption.text}
        </text>
      ))}
      {tiles.map((tile) => {
        const variant = VARIANT[tile.state];
        return (
          <TileGraphic
            look="depth"
            key={tile.number}
            x={tile.x}
            y={tile.y}
            w={TILE}
            h={TILE}
            variant={variant}
            chamfer={12}
          >
            {tile.state === "download" ? (
              <CommandIcon
                kind="download"
                cx={tile.x + TILE / 2}
                cy={tile.y + TILE / 2}
                size={22}
                tone={TILE_TONE.dashed}
              />
            ) : (
              <text
                x={tile.x + TILE / 2}
                y={tile.y + TILE / 2}
                dy="0.35em"
                textAnchor="middle"
                fontSize={20}
                className={TILE_TONE[variant]}
                {...TEXT}
              >
                {String(tile.number).padStart(2, "0")}
              </text>
            )}
          </TileGraphic>
        );
      })}
      {LEGEND.map((item, i) => {
        const y = bottom + 6 + i * 24;
        return (
          <g key={item.state}>
            <TileGraphic
              look="depth"
              x={20}
              y={y}
              w={14}
              h={14}
              variant={VARIANT[item.state]}
              chamfer={3}
              line={1.5}
            />
            <text
              x={44}
              y={y + 7}
              dy="0.35em"
              fontSize={10}
              letterSpacing={1.5}
              className="fill-ink"
              {...TEXT}
            >
              {item.label}
            </text>
          </g>
        );
      })}
      <text
        x={20}
        y={bottom + 6 + LEGEND.length * 24 + 18}
        fontSize={10}
        letterSpacing={1.5}
        className="fill-mute"
        {...TEXT}
      >
        OFFLINE. CONNECT TO GET NEW LEVELS.
      </text>
      <ButtonGraphic
        look="depth"
        x={20}
        y={714}
        w={350}
        h={56}
        label={`PLAY LEVEL ${String(current.number).padStart(2, "0")}`}
        primary
        fontSize={15}
      />
    </svg>
  );
}
