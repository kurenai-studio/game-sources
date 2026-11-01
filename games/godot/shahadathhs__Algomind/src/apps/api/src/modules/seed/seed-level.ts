import { randomUUID } from "node:crypto";
import {
  solve,
  type CommandName,
  type Direction,
  type Level,
  type Program,
} from "@algomind/level-contract";
import type { Prisma } from "../../generated/prisma/client.js";
import { analyzeLevel, contentHash } from "../levels/level-analysis.js";
import type { ValidationSummary } from "../levels/levels.schemas.js";

export const FACING: Record<string, Direction> = {
  "^": "north",
  ">": "east",
  v: "south",
  "<": "west",
};

/** A board from text rows: `.` floor, `#` wall, `G` target, `^ > v <` the automaton and its facing. */
export function readBoard(rows: readonly string[]) {
  const walls: [number, number][] = [];
  let goal: [number, number] | undefined;
  let start: { position: [number, number]; direction: Direction } | undefined;
  rows.forEach((row, y) => {
    Array.from(row).forEach((cell, x) => {
      if (cell === "#") walls.push([x, y]);
      else if (cell === "G") goal = [x, y];
      else if (cell in FACING) start = { position: [x, y], direction: FACING[cell]! };
    });
  });
  // A board without a target is a sweep: the goal is to visit every floor cell.
  if (!start) throw new Error("A starter board needs an automaton");
  return { width: rows[0]!.length, height: rows.length, walls, goal, start };
}

/** The goal of a board read from rows: the target cell, or the sweep when the board has none. */
function goalOf(position: [number, number] | undefined) {
  return position ? { type: "reach_tile" as const, position } : { type: "visit_all" as const };
}

export type LevelDef = {
  slug: string;
  title: string;
  difficulty: "easy" | "medium" | "hard";
  commands: readonly CommandName[];
  maxCommands: number;
  rows: readonly string[];
  hints?: readonly string[];
  /** The reference solution, for a level whose par the exact solver cannot search (IF). */
  solution?: readonly unknown[];
  /** Defaults to 100. */
  maxSteps?: number;
  /** Mechanics the level requires besides those of its commands (for example nested_loops). */
  requires?: readonly string[];
  /** More test boards as text rows (the same alphabet as `rows`): one program must solve them all. */
  extraBoards?: readonly (readonly string[])[];
  /** A debug level: the program the tape starts with. It must fail; `solution` is its fix. */
  startProgram?: readonly unknown[];
  /** Keys and the doors they open. */
  locks?: readonly { key: readonly [number, number]; door: readonly [number, number] }[];
  /** Items and the docks they belong on: the target counts once every item is delivered. */
  deliveries?: readonly { item: readonly [number, number]; dock: readonly [number, number] }[];
  /** Switches and the gates they toggle; `open` makes the gate start open. */
  switches?: readonly {
    switch: readonly [number, number];
    gate: readonly [number, number];
    open?: boolean;
  }[];
  /** Teleporter pairs: entering one end puts the automaton on the other. */
  teleports?: readonly { a: readonly [number, number]; b: readonly [number, number] }[];
  /** Ice cells: a move onto ice slides on while the way is free. */
  ice?: readonly (readonly [number, number])[];
  /** Belts: after an action that leaves the automaton on one, it is carried a cell. */
  belts?: readonly {
    cell: readonly [number, number];
    direction: "north" | "east" | "south" | "west";
  }[];
  /** Guards that walk a fixed route: their cell depends only on the step number. */
  patrols?: readonly {
    pattern: "back_and_forth" | "loop";
    cells: readonly (readonly [number, number])[];
  }[];
};

/** The seed content failed the validator or solver: a bug in the data, never a runtime problem. */
export class SeedContentError extends Error {}

export function buildLevel(def: LevelDef, id: string): Level {
  const board = readBoard(def.rows);
  return {
    schemaVersion: 1,
    levelId: id,
    levelVersion: 1,
    slug: def.slug,
    title: def.title,
    description: "",
    difficulty: def.difficulty,
    requires: { mechanics: [...(def.requires ?? [])] },
    board: { width: board.width, height: board.height, walls: board.walls },
    initialState: board.start,
    availableCommands: [...def.commands],
    constraints: { maxCommands: def.maxCommands, maxSteps: def.maxSteps ?? 100 },
    goal: goalOf(board.goal),
    ...(def.extraBoards
      ? {
          extraBoards: def.extraBoards.map((rows) => {
            const extra = readBoard(rows);
            return {
              board: { width: extra.width, height: extra.height, walls: extra.walls },
              initialState: extra.start,
              goal: goalOf(extra.goal),
            };
          }),
        }
      : {}),
    ...(def.startProgram ? { startProgram: structuredClone(def.startProgram) as Program } : {}),
    ...(def.locks
      ? {
          locks: def.locks.map((l) => ({ key: [...l.key], door: [...l.door] })) as Level["locks"],
        }
      : {}),
    ...(def.deliveries
      ? {
          deliveries: def.deliveries.map((d) => ({
            item: [...d.item],
            dock: [...d.dock],
          })) as Level["deliveries"],
        }
      : {}),
    ...(def.switches
      ? {
          switches: def.switches.map((s) => ({
            switch: [...s.switch],
            gate: [...s.gate],
            ...(s.open !== undefined ? { open: s.open } : {}),
          })) as Level["switches"],
        }
      : {}),
    ...(def.teleports
      ? {
          teleports: def.teleports.map((t) => ({ a: [...t.a], b: [...t.b] })) as Level["teleports"],
        }
      : {}),
    ...(def.ice ? { ice: def.ice.map((c) => [...c]) as Level["ice"] } : {}),
    ...(def.belts
      ? {
          belts: def.belts.map((b) => ({
            cell: [...b.cell],
            direction: b.direction,
          })) as Level["belts"],
        }
      : {}),
    ...(def.patrols
      ? {
          patrols: def.patrols.map((p) => ({
            pattern: p.pattern,
            cells: p.cells.map((c) => [...c]),
          })) as Level["patrols"],
        }
      : {}),
    hints: [...(def.hints ?? [])],
  };
}

export type PreparedLevel = ReturnType<typeof prepareLevel>;

/** Validates a level and solves it with the solver; throws SeedContentError if either fails. */
export function prepareLevel(def: LevelDef) {
  const id = randomUUID();
  const level = buildLevel(def, id);
  const program: readonly unknown[] | undefined = def.solution ?? solve(level)?.program;
  if (!program) throw new SeedContentError(`Seed level ${def.slug} has no solution`);
  const analysis = analyzeLevel(level, program);
  if (analysis.errors.length > 0 || !analysis.referenceSolved || !analysis.par) {
    throw new SeedContentError(
      `Seed level ${def.slug} is invalid: ${JSON.stringify(analysis.errors)}`,
    );
  }
  return { def, id, level, program, analysis, par: analysis.par };
}

/**
 * Creates one published level with its version and a recorded "seed" playtest. `chapterId` is null
 * for a daily-pool level, which is published but not in the campaign.
 */
export async function createPublishedLevel(
  tx: Prisma.TransactionClient,
  item: PreparedLevel,
  placement: { chapterId: string | null; orderInChapter: number; dailyPool: boolean },
  note: string,
): Promise<void> {
  const { def, id, level, program, analysis, par } = item;
  const hash = contentHash(level);
  const now = new Date();
  const summary: ValidationSummary = {
    ok: true,
    errors: [],
    warnings: analysis.warnings,
    par,
    referenceSolved: true,
    requiredMechanics: analysis.requiredMechanics,
    contentHash: hash,
    validatedAt: now.toISOString(),
  };
  await tx.level.create({
    data: {
      id,
      slug: def.slug,
      title: def.title,
      difficulty: def.difficulty,
      status: "PUBLISHED",
      chapterId: placement.chapterId,
      orderInChapter: placement.orderInChapter,
      dailyPool: placement.dailyPool,
    },
  });
  const version = await tx.levelVersion.create({
    data: {
      levelId: id,
      versionNumber: 1,
      schemaVersion: 1,
      state: "PUBLISHED",
      content: level as unknown as Prisma.InputJsonObject,
      referenceSolution: program as unknown as Prisma.InputJsonArray,
      par,
      contentHash: hash,
      validationSummary: summary as unknown as Prisma.InputJsonObject,
      publishedAt: now,
    },
  });
  await tx.playtestRecord.create({
    data: {
      levelVersionId: version.id,
      contentHash: hash,
      testerName: "seed",
      solved: true,
      commandsUsed: par.commands,
      notes: note,
    },
  });
  await tx.level.update({ where: { id }, data: { currentPublishedVersionId: version.id } });
}
