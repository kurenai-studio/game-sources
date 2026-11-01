import { BoardView } from "@/components/ui/board-view";
import { Caption } from "@/components/ui/caption";
import { PrimaryButton } from "@/components/ui/primary-button";
import { SecondaryButton } from "@/components/ui/secondary-button";
import type { BoardData } from "@/lib/board";
import { DIFFICULTY_LABEL } from "@/lib/campaign";
import { parNote, resultText, shareCaption, type Share } from "@/lib/share";

/**
 * A shared result: the level's board as the puzzle (no solution), the numbers, and the two ways
 * on. It holds no player: the link carries a result, not a name.
 */
export function ShareCard({ share, board }: { share: Share; board: BoardData | null }) {
  const note = parNote(share);
  return (
    <div className="grid items-start gap-8 sm:grid-cols-[minmax(0,380px)_1fr] sm:gap-12">
      {board && (
        <BoardView
          look="depth"
          board={board}
          label={`The board of ${share.title}. Move the automaton to the target.`}
        />
      )}
      <div className={board ? "" : "sm:col-span-2"}>
        <Caption>{shareCaption(share)}</Caption>
        <h1 className="mt-2 text-[clamp(30px,11.4vw,44px)] leading-none tracking-[1px] uppercase sm:text-[56px]">
          {share.title}
        </h1>
        <p className="mt-3 text-xs font-bold tracking-[2px] text-mute uppercase">
          {DIFFICULTY_LABEL[share.difficulty]}
        </p>
        <p className="mt-6 text-lg leading-normal font-semibold tracking-[0.3px]">
          {resultText(share)}
        </p>
        {note && <p className="mt-1 text-base font-semibold text-mute">{note}</p>}
        <p className="mt-6 max-w-[460px] text-base leading-normal font-semibold text-mute">
          This is the board to solve. The program that solved it is not shown.
        </p>
        <div className="mt-8 flex flex-col items-start gap-4 sm:flex-row sm:flex-wrap sm:items-center">
          <PrimaryButton href="/play" className="w-full sm:w-auto">
            Play in the browser
          </PrimaryButton>
          <SecondaryButton href="/download">Download for Android</SecondaryButton>
        </div>
      </div>
    </div>
  );
}
