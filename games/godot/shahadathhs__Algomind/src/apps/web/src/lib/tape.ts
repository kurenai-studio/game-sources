import type { Command } from "@/lib/board";

/** executed = solid, current = yellow, failed = yellow with a cross, upcoming = outlined. */
export type TapeState = "executed" | "current" | "failed" | "upcoming" | "empty";

export type TapeTile = {
  state: TapeState;
  command?: Command;
  /** One-based step number shown under the tile. */
  step?: number;
  /** Draw a plus in an empty slot (the editing state). */
  plus?: boolean;
};

type Options = {
  /** Zero-based index of the current instruction. Omit while editing (nothing has run). */
  current?: number;
  /** The current instruction is the one that failed. */
  failed?: boolean;
  /** Append an empty slot after the last instruction. */
  emptySlot?: "plus" | "plain";
};

/** Builds the tile states of a tape from a program and the position of the read-head. */
export function tapeFromProgram(program: readonly Command[], options: Options = {}): TapeTile[] {
  const { current, failed = false, emptySlot } = options;
  const tiles: TapeTile[] = program.map((command, index) => {
    let state: TapeState = "upcoming";
    if (current !== undefined) {
      if (index < current) state = "executed";
      else if (index === current) state = failed ? "failed" : "current";
    }
    return { state, command, step: index + 1 };
  });
  if (emptySlot) tiles.push({ state: "empty", plus: emptySlot === "plus" });
  return tiles;
}

/** Two-digit step label: 5 becomes "05". */
export function stepLabel(step: number): string {
  return String(step).padStart(2, "0");
}
