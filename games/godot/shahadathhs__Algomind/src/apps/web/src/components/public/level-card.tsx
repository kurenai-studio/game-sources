import { BoardView } from "@/components/ui/board-view";
import { type CampaignLevel, DIFFICULTY_LABEL } from "@/lib/campaign";

/** One level: its board, number, title, difficulty, and command limit. No solution is shown. */
export function LevelCard({ level }: { level: CampaignLevel }) {
  const number = String(level.number).padStart(2, "0");
  return (
    <li className="deferred view-pop lift lift-board">
      <BoardView
        look="depth"
        board={level.board}
        label={`Level ${level.number}, ${level.title}. Move the automaton to the target.`}
      />
      <p className="mt-3 flex items-baseline gap-3">
        <span className="text-sm tracking-[2px] text-mute tabular-nums">{number}</span>
        <span className="text-xl leading-tight tracking-[0.5px] uppercase">{level.title}</span>
      </p>
      <p className="mt-1 text-xs font-bold tracking-[2px] text-mute uppercase">
        {DIFFICULTY_LABEL[level.difficulty]} · Max {level.maxCommands} commands
        {level.boardCount > 1 && ` · ${level.boardCount} boards`}
      </p>
    </li>
  );
}
