"use client";

import { useEffect, useState } from "react";
import { GameScreenView } from "@/components/public/game-screen-view";
import type { ScreenData } from "@/components/public/game-screen/screen-data";
import type { RunFrame } from "@/components/public/game-screen/frames";

/** Time each tile takes to land on the tape, and each step of the run (never over 250 ms). */
const BUILD_MS = 150;
const STEP_MS = 250;
/** A pause between the finished program and Run, and before the demo starts. */
const BEFORE_RUN_MS = 400;
const START_MS = 400;

/**
 * The landing page's demo: the program is built tile by tile and run to the target, once, then it
 * rests on the solved screen. It starts from the frame the server drew (`staticIndex`), which is also
 * all anyone sees without JavaScript or with reduced motion. Nothing loops.
 */
export function HeroRun({
  frames,
  data,
  staticIndex,
}: {
  frames: RunFrame[];
  data: ScreenData;
  staticIndex: number;
}) {
  const [index, setIndex] = useState(staticIndex);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const timers: number[] = [];
    let at = START_MS;
    frames.forEach((frame, i) => {
      timers.push(window.setTimeout(() => setIndex(i), at));
      const next = frames[i + 1];
      if (frame.state === "ready" && next?.state === "running") at += BEFORE_RUN_MS;
      at += frame.state === "ready" ? BUILD_MS : STEP_MS;
    });
    return () => timers.forEach((timer) => window.clearTimeout(timer));
  }, [frames]);

  const shown = frames[index]!;
  return <GameScreenView state={shown.state} frame={shown.frame} data={data} count={shown.count} />;
}
