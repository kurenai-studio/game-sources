import { Key } from "@/components/ui/key";
import { Caption } from "@/components/ui/caption";
import { Section } from "@/components/ui/section";
import { TextLink } from "@/components/ui/text-link";
import { groupByAct } from "@/lib/acts";
import { getCampaign, levelCount } from "@/lib/campaign";

/** The worlds of the published campaign: the idea each one teaches and how many levels it holds. */
export async function WorldsSection() {
  const campaign = await getCampaign();
  // Without the live campaign there is nothing true to list, so the section is left out.
  if (campaign.status !== "available" || campaign.worlds.length === 0) return null;
  return (
    <Section id="worlds" reveal>
      <Caption>The worlds</Caption>
      <h2 className="mt-4 max-w-[760px] text-[32px] leading-[1.02] tracking-[0.5px] uppercase sm:text-[40px]">
        One idea at a time.
      </h2>
      <p className="mt-4 max-w-[560px] text-base leading-normal font-semibold text-mute">
        Each world teaches one idea of programming. The levels get harder inside it, and the next
        world builds on the last.
      </p>
      {groupByAct(campaign.worlds).map(({ act, worlds }) => (
        <div key={act.title} className="mt-10">
          <h3 className="text-sm leading-none tracking-[2px] text-ink uppercase">{act.title}</h3>
          <p className="mt-2 text-[13px] font-semibold tracking-[0.3px] text-mute">{act.text}</p>
          <ul className="mt-3 grid gap-x-8 gap-y-2 sm:grid-cols-2 lg:grid-cols-3">
            {worlds.map((world) => (
              <li
                key={world.id}
                className="view-rise lift flex items-start gap-4 border-t-2 border-ink py-5"
              >
                <Key tone="ink" className="flex-none">
                  <span
                    aria-hidden="true"
                    className="tile flex h-12 w-12 items-center justify-center bg-ink text-xl text-on-ink tabular-nums"
                  >
                    {String(world.number).padStart(2, "0")}
                  </span>
                </Key>
                <div>
                  <h4 className="text-xl leading-none tracking-[1px] uppercase">{world.title}</h4>
                  <p className="mt-2 text-[13px] leading-normal font-semibold tracking-[0.3px] text-mute">
                    {world.summary}
                  </p>
                  <p className="mt-2 text-xs font-bold tracking-[2px] text-mute uppercase">
                    {`${levelCount(world)} levels`}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </div>
      ))}
      <div className="mt-6">
        <TextLink href="/levels">See all levels</TextLink>
      </div>
    </Section>
  );
}
