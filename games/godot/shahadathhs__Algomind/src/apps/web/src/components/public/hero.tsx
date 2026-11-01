import { HeroScreen } from "@/components/public/hero-screen";
import { Container } from "@/components/ui/container";
import { DownloadIcon } from "@/components/ui/download-icon";
import { PrimaryButton } from "@/components/ui/primary-button";
import { ScreenFrame } from "@/components/ui/screen-frame";
import { TextLink } from "@/components/ui/text-link";
import { releaseMeta, type ReleaseState } from "@/lib/releases";

/** Facts under the button: version and size from the latest release, or a plain notice. */
function metaLine(state: ReleaseState | null): string {
  if (state === null) return "Checking the latest version";
  return state.status === "available"
    ? releaseMeta(state.release).join(" · ")
    : "No release available yet";
}

/** `release` is null while the latest release is still being read. */
export function Hero({ release }: { release: ReleaseState | null }) {
  return (
    <section>
      <Container className="grid items-start gap-10 pt-6 pb-14 lg:grid-cols-[1fr_300px] lg:gap-16 lg:pt-8 lg:pb-[72px]">
        <div className="lg:pt-[72px]">
          <h1 className="rise max-w-[560px] text-[clamp(30px,11.4vw,44px)] leading-[0.98] tracking-[1px] uppercase sm:text-[64px]">
            A programming puzzle for Android.
          </h1>
          <p
            className="rise mt-6 mb-8 max-w-[520px] text-lg leading-normal font-semibold tracking-[0.5px] text-mute"
            style={{ ["--i" as string]: 1 }}
          >
            Build a program from instruction tiles, run it, and guide the automaton to the target.
            Offline first. No ads. No purchases.
          </p>
          <div className="rise" style={{ ["--i" as string]: 2 }}>
            <PrimaryButton href="/download" icon={<DownloadIcon />} className="w-full sm:w-auto">
              Download for Android
            </PrimaryButton>
          </div>
          <p
            className="rise mt-5 text-xs font-bold tracking-[2px] text-mute uppercase"
            style={{ ["--i" as string]: 3 }}
          >
            {metaLine(release)}
          </p>
          <div className="mt-3">
            <TextLink href="/how-to-play">How to play</TextLink>
          </div>
        </div>
        <div className="parallax">
          <ScreenFrame>
            <HeroScreen />
          </ScreenFrame>
        </div>
      </Container>
    </section>
  );
}
