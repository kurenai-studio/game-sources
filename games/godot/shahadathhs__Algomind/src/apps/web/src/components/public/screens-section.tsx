import { GameScreen, type GameScreenState } from "@/components/public/game-screen";
import { LevelsScreen } from "@/components/public/levels-screen";
import { Caption } from "@/components/ui/caption";
import { ScreenFrame } from "@/components/ui/screen-frame";
import { Section } from "@/components/ui/section";

const SCREENS: { title: string; state: GameScreenState | "levels" }[] = [
  { title: "Levels", state: "levels" },
  { title: "Building", state: "ready" },
  { title: "Failed", state: "failed" },
  { title: "Solved", state: "solved" },
];

export function ScreensSection() {
  return (
    <Section id="screens" reveal>
      <Caption as="h2">The screens</Caption>
      <ul className="mt-8 grid grid-cols-2 gap-x-4 gap-y-8 lg:grid-cols-4 lg:gap-x-6">
        {SCREENS.map((screen) => (
          <li key={screen.title}>
            <figure>
              <ScreenFrame size="sm">
                {screen.state === "levels" ? <LevelsScreen /> : <GameScreen state={screen.state} />}
              </ScreenFrame>
              <figcaption className="mt-3 text-xs tracking-[2px] text-mute uppercase">
                {screen.title}
              </figcaption>
            </figure>
          </li>
        ))}
      </ul>
    </Section>
  );
}
