import {
  COMMAND_BUDGET,
  FAILED_BOARD,
  LEVEL_NUMBER,
  LEVEL_TITLE,
  RUN_BOARDS,
  FAILED_PROGRAM,
  READY_BOARD,
  READY_COUNT,
  RUNNING_BOARD,
  RUNNING_STEP,
  SOLUTION,
  SOLVED_BOARD,
  SOLVED_STATS,
} from "@/lib/sample-screens";
import { tapeFromProgram } from "@/lib/tape";
import type { Frame, GameScreenState } from "../game-screen-view";
import type { ScreenData } from "./screen-data";

export function frameFor(state: GameScreenState): Frame {
  switch (state) {
    case "ready":
      return {
        board: READY_BOARD,
        tiles: tapeFromProgram(SOLUTION.slice(0, READY_COUNT), { emptySlot: "plus" }),
        label: `Game screen while building: ${READY_COUNT} instructions on the tape and a Run button.`,
      };
    case "running":
      return {
        board: RUNNING_BOARD,
        tiles: tapeFromProgram(SOLUTION, { current: RUNNING_STEP }),
        head: RUNNING_STEP,
        label: `Game screen while running: the tape is under the read-head at step ${RUNNING_STEP + 1} and the automaton is on its way to the target.`,
      };
    case "failed":
      return {
        board: FAILED_BOARD,
        tiles: tapeFromProgram(FAILED_PROGRAM, {
          current: FAILED_PROGRAM.length - 1,
          failed: true,
        }),
        head: FAILED_PROGRAM.length - 1,
        label:
          "Game screen after a failed run: the automaton tried to move into a wall, the wall is striped yellow and the failing step is marked with a cross.",
      };
    case "solved":
      return {
        board: SOLVED_BOARD,
        tiles: tapeFromProgram(SOLUTION, { current: SOLUTION.length - 1, emptySlot: "plain" }),
        head: SOLUTION.length - 1,
        label: `Game screen after solving the level: ${SOLVED_STATS.used} of ${COMMAND_BUDGET} commands, ${SOLVED_STATS.steps} steps.`,
      };
  }
}

/** The numbers of the landing level that every drawn screen shows. */
export function screenData(): ScreenData {
  return {
    levelNumber: LEVEL_NUMBER,
    levelTitle: LEVEL_TITLE,
    budget: COMMAND_BUDGET,
    stats: SOLVED_STATS,
  };
}

/** The commands on the tape in a state, for the counter. */
export function tapeCount(state: GameScreenState): number {
  return state === "ready" ? READY_COUNT : SOLUTION.length;
}

/** One moment of the landing demo: a screen state, its frame and the counter. */
export type RunFrame = { state: GameScreenState; frame: Frame; count: number };

const DEMO_LABEL =
  "Game screen: instructions are added to the tape one by one, then the program runs and the automaton reaches the target.";

/**
 * The whole demo in order: the program built tile by tile, then run one step at a time to the
 * solved screen. Every frame comes from the landing level, so the numbers are the game's.
 */
export function runFrames(): RunFrame[] {
  const frames: RunFrame[] = [];
  for (let built = 1; built <= SOLUTION.length; built += 1) {
    frames.push({
      state: "ready",
      count: built,
      frame: {
        board: READY_BOARD,
        tiles: tapeFromProgram(SOLUTION.slice(0, built), {
          emptySlot: built < SOLUTION.length ? "plus" : undefined,
        }),
        label: DEMO_LABEL,
      },
    });
  }
  RUN_BOARDS.forEach((board, step) => {
    frames.push({
      state: "running",
      count: SOLUTION.length,
      frame: {
        board,
        tiles: tapeFromProgram(SOLUTION, { current: step }),
        head: step,
        label: DEMO_LABEL,
      },
    });
  });
  frames.push({
    state: "solved",
    count: SOLUTION.length,
    frame: { ...frameFor("solved"), label: DEMO_LABEL },
  });
  return frames;
}

/** Index in `runFrames()` of the frame the page shows before and without the demo. */
export function staticFrameIndex(): number {
  return SOLUTION.length + RUNNING_STEP;
}
