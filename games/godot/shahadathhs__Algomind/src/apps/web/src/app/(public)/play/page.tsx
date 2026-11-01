import type { Metadata } from "next";
import { PlayFrame } from "@/components/public/play-frame";
import { Caption } from "@/components/ui/caption";
import { Container } from "@/components/ui/container";
import { SecondaryButton } from "@/components/ui/secondary-button";
import { TextLink } from "@/components/ui/text-link";
import { readPlayBuild } from "@/lib/play-build";
import { pageMetadata } from "@/lib/seo";

const DESCRIPTION =
  "Try Algomind in your browser. It is the same game as the Android app, running from its web export.";

export const metadata: Metadata = pageMetadata({
  title: "Play in your browser",
  shareTitle: "Play Algomind in your browser",
  description: DESCRIPTION,
  path: "/play",
});

const DIFFERENCES = [
  "It runs offline with the levels bundled in this version.",
  "There is no account and no sync.",
  "Progress stays in this browser; clearing site data erases it.",
  "The first visit downloads about 10 MB, then it is cached.",
];

const IN_THE_APP = [
  "New levels arrive without an update.",
  "Optional account to keep progress across devices.",
  "Vibration feedback on your phone.",
];

export default function PlayPage() {
  const build = readPlayBuild();
  return (
    <Container className="pt-6 pb-16 sm:pb-24">
      <div className="max-w-[680px]">
        <h1 className="text-[40px] leading-none tracking-[1px] uppercase sm:text-[56px]">
          Play in your browser
        </h1>
        <p className="mt-5 text-lg leading-normal font-semibold tracking-[0.3px] text-mute">
          The same game as the Android app, from its web export. Progress stays in this browser. The
          app is the better way to play.
        </p>
      </div>
      <div className="mt-10 grid gap-12 md:grid-cols-[minmax(0,360px)_minmax(0,1fr)] md:gap-10 lg:grid-cols-[minmax(0,430px)_minmax(0,1fr)] lg:gap-16">
        <div>
          {build.available ? (
            <PlayFrame executable={build.executable} sizes={build.sizes} />
          ) : (
            <p role="status" className="text-base font-semibold text-mute">
              The browser version is not available right now.
            </p>
          )}
          <noscript>
            <p className="mt-4 text-base font-semibold text-mute">
              The browser version needs JavaScript.
            </p>
          </noscript>
        </div>
        <aside className="flex max-w-[520px] flex-col gap-10">
          <div>
            <Caption as="h2">This is a try-out</Caption>
            <p className="mt-3 text-lg leading-normal font-semibold text-mute">
              The browser version is a way to see the game before you install it. The Android app is
              the real game.
            </p>
            <div className="mt-6">
              <SecondaryButton href="/download">Get the Android app</SecondaryButton>
            </div>
          </div>
          <div>
            <Caption as="h2">What differs here</Caption>
            <ul className="mt-3 space-y-1.5 text-base leading-normal font-semibold text-mute">
              {DIFFERENCES.map((line) => (
                <li key={line}>{`– ${line}`}</li>
              ))}
            </ul>
          </div>
          <div>
            <Caption as="h2">In the app</Caption>
            <ul className="mt-3 space-y-1.5 text-base leading-normal font-semibold text-mute">
              {IN_THE_APP.map((line) => (
                <li key={line}>{`– ${line}`}</li>
              ))}
            </ul>
          </div>
          <div className="flex flex-wrap gap-x-8">
            <TextLink href="/how-to-play">How to play</TextLink>
            <TextLink href="/levels">Levels</TextLink>
          </div>
        </aside>
      </div>
    </Container>
  );
}
