import type { Metadata } from "next";
import { connection } from "next/server";
import { DownloadBand } from "@/components/public/download-band";
import { WorldSection } from "@/components/public/world-section";
import { Container } from "@/components/ui/container";
import { Section } from "@/components/ui/section";
import { TextLink } from "@/components/ui/text-link";
import { groupByAct } from "@/lib/acts";
import { getCampaign, levelCount } from "@/lib/campaign";
import { pageMetadata } from "@/lib/seo";

const DESCRIPTION =
  "How Algomind's levels are organised: worlds that each teach one idea, chapters inside them, and the levels you unlock in order.";

export const metadata: Metadata = pageMetadata({
  title: "Levels",
  shareTitle: "Algomind levels",
  description: DESCRIPTION,
  path: "/levels",
});

// Rendered per request, not prerendered at build, so a build made while the API is down or asleep
// never serves "could not be loaded". The campaign fetch still caches for a minute.
export default async function LevelsPage() {
  await connection();
  const campaign = await getCampaign();
  const worlds = campaign.status === "available" ? campaign.worlds : [];
  const total = worlds.reduce((sum, world) => sum + levelCount(world), 0);
  return (
    <>
      <Container className="pt-6 pb-12 sm:pb-16">
        <h1 className="rise text-[clamp(30px,11.4vw,44px)] leading-none tracking-[1px] uppercase sm:text-[56px]">
          Levels.
        </h1>
        <p className="mt-5 max-w-[620px] text-lg leading-normal font-semibold tracking-[0.5px] text-mute">
          Levels are grouped into worlds, and each world teaches one idea. A world is split into
          chapters, and you unlock the levels in order.
        </p>
        {campaign.status === "available" && worlds.length === 0 && (
          <p className="mt-6 max-w-[680px] text-base leading-normal font-semibold text-mute">
            No levels have been published yet.
          </p>
        )}
        {campaign.status === "unavailable" && (
          <p className="mt-6 max-w-[680px] text-base leading-normal font-semibold text-mute">
            The levels could not be loaded right now. Try again in a minute.
          </p>
        )}
        <nav aria-label="Worlds" className="mt-8">
          <p className="text-xs font-bold tracking-[2px] text-mute uppercase">
            {`${worlds.length} worlds · ${total} levels`}
          </p>
          <div className="mt-3 grid gap-x-10 gap-y-4 sm:grid-cols-2 lg:grid-cols-3">
            {groupByAct(worlds).map(({ act, worlds: inAct }) => (
              <div key={act.title}>
                <p className="text-xs font-bold tracking-[2px] text-ink uppercase">{act.title}</p>
                <ul className="mt-1 grid gap-y-1">
                  {inAct.map((world) => (
                    <li key={world.id}>
                      <TextLink href={`#world-${world.number}`}>
                        {`${String(world.number).padStart(2, "0")} ${world.title}`}
                      </TextLink>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </nav>
      </Container>
      {worlds.map((world) => (
        <Section key={world.id} id={`world-${world.number}`}>
          <WorldSection world={world} />
        </Section>
      ))}
      <DownloadBand />
    </>
  );
}
