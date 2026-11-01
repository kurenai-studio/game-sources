import { BoardGraphic } from "@/components/ui/board-graphic";
import { TapeGraphic } from "@/components/ui/tape-graphic";
import type { BoardData } from "@/lib/board";
import type { TapeTile } from "@/lib/tape";
import { Commands } from "./game-screen/commands";
import { Controls } from "./game-screen/controls";
import type { ScreenData } from "./game-screen/screen-data";
import { StatusRow } from "./game-screen/status-row";
import { Stats } from "./game-screen/stats";
import { SvgCaption } from "./game-screen/svg-text";
import { TopBar } from "./game-screen/top-bar";

export const SCREEN_WIDTH = 390;
export const SCREEN_HEIGHT = 800;

export type GameScreenState = "ready" | "running" | "failed" | "solved";

/** What one drawn screen shows: the board, the tape and the read-head. */
export type Frame = {
  board: BoardData;
  tiles: TapeTile[];
  head?: number;
  label: string;
};

/**
 * A game screen drawn as one SVG (390 by 800 units) from the same parts the real renderer uses:
 * board, tape, command tiles, and buttons. Shown flat, never inside a device bezel. It takes plain
 * data, so it can also run in the browser (the landing page's demo) without the level solver.
 */
export function GameScreenView({
  state,
  frame,
  data,
  count,
  className,
}: {
  state: GameScreenState;
  frame: Frame;
  data: ScreenData;
  /** The commands on the tape, for the counter. */
  count: number;
  className?: string;
}) {
  return (
    <svg
      viewBox={`0 0 ${SCREEN_WIDTH} ${SCREEN_HEIGHT}`}
      role="img"
      aria-label={frame.label}
      className={className ?? "block h-auto w-full"}
    >
      <TopBar data={data} />
      <StatusRow state={state} count={count} budget={data.budget} />
      <BoardGraphic look="depth" board={frame.board} x={20} y={136} size={350} />
      <SvgCaption x={20} y={516}>
        PROGRAM
      </SvgCaption>
      <TapeGraphic look="depth" tiles={frame.tiles} x={20} y={526} width={350} head={frame.head} />
      {state === "solved" ? <Stats data={data} /> : <Commands />}
      <Controls state={state} />
    </svg>
  );
}
