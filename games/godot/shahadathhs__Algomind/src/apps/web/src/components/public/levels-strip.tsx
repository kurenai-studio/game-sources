import { BoardView } from "@/components/ui/board-view";
import { Caption } from "@/components/ui/caption";
import { Section } from "@/components/ui/section";
import { TextLink } from "@/components/ui/text-link";
import type { BoardData } from "@/lib/board";
import { getCampaign, type CampaignState } from "@/lib/campaign";
import { SAMPLE_LEVELS } from "@/lib/sample-levels";

const SHOWN = 5;

type Shown = { id: string; title: string; board: BoardData; real: boolean };

/** Five levels spread evenly over the published campaign, or the static samples when it is down. */
function levelsToShow(campaign: CampaignState): Shown[] {
  if (campaign.status === "available") {
    const all = campaign.worlds.flatMap((w) => w.chapters.flatMap((c) => c.levels));
    if (all.length >= SHOWN) {
      return Array.from({ length: SHOWN }, (_, i) => {
        const level = all[Math.round((i * (all.length - 1)) / (SHOWN - 1))]!;
        return { id: level.slug, title: level.title, board: level.board, real: true };
      });
    }
  }
  return SAMPLE_LEVELS.map((s) => ({ id: s.id, title: s.title, board: s.board, real: false }));
}

export async function LevelsStrip() {
  const shown = levelsToShow(await getCampaign());
  return (
    <Section id="levels" reveal>
      <Caption>Levels</Caption>
      <h2 className="mt-4 max-w-[760px] text-[32px] leading-[1.02] tracking-[0.5px] uppercase sm:text-[40px]">
        New levels arrive without an app update.
      </h2>
      <p className="mt-4 max-w-[520px] text-base leading-normal font-semibold text-mute">
        Levels are published to the game online, and downloaded levels stay playable offline.
      </p>
      <ul className="mt-10 grid grid-cols-2 gap-x-5 gap-y-6 sm:grid-cols-5">
        {shown.map((level, i) => (
          <li
            key={level.id}
            className={`view-pop lift lift-board ${i === shown.length - 1 ? "hidden sm:block" : ""}`}
          >
            <BoardView
              look="depth"
              board={level.board}
              label={`${level.real ? "Level" : "Sample level"} ${level.title}. Move the automaton to the target.`}
            />
          </li>
        ))}
      </ul>
      <div className="mt-6">
        <TextLink href="/levels">See all levels</TextLink>
      </div>
    </Section>
  );
}
