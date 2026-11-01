import { HeroRun } from "@/components/public/hero-run";
import { runFrames, screenData, staticFrameIndex } from "@/components/public/game-screen/frames";

/** The hero's game screen: drawn on the server, and played once in the browser (see HeroRun). */
export function HeroScreen() {
  return <HeroRun frames={runFrames()} data={screenData()} staticIndex={staticFrameIndex()} />;
}
