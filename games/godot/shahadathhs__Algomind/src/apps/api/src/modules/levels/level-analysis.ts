import { createHash } from "node:crypto";
import {
  explainResult,
  programSlots,
  type AuthoringLevel,
  type CommandName,
  simulateAll,
  solve,
  validateAuthoringLevel,
} from "@algomind/level-contract";
import type { CheckIssue, Par } from "./levels.schemas.js";

/** The mechanic each command needs. A level always needs the mechanics of its available commands. */
export const COMMAND_MECHANICS: Record<CommandName, string> = {
  MOVE_FORWARD: "move",
  TURN_LEFT: "turn",
  TURN_RIGHT: "turn",
  REPEAT: "repeat",
  REPEAT_UNTIL: "repeat_until",
  IF: "if",
  PROC: "procedures",
  INC: "counter",
  MARK: "markers",
};

export type Analysis = {
  errors: CheckIssue[];
  warnings: CheckIssue[];
  par: Par | null;
  referenceSolved: boolean;
  /** Explicit requires.mechanics plus the mechanics implied by the available commands. */
  requiredMechanics: string[];
  /** Present only when the authoring level passed the validator. */
  level: AuthoringLevel | null;
};

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** JSON with object keys sorted at every depth, so equal content always serializes identically. */
function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (isObject(value)) {
    return `{${Object.keys(value)
      .sort()
      .map((k) => `${JSON.stringify(k)}:${canonicalJson(value[k])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value) ?? "null";
}

/**
 * Hash of the level content that ties playtests to exact content. `levelVersion` is left out, so
 * restoring or re-drafting identical content keeps its playtests; the reference solution is not
 * part of what a tester plays.
 */
export function contentHash(content: unknown): string {
  const subject = isObject(content) ? { ...content, levelVersion: undefined } : content;
  return createHash("sha256").update(canonicalJson(subject)).digest("hex");
}

/** True when the level uses something the exact par search does not cover (the par is then the reference). */
/** True when the level has any of the extras the exact search moves through (not loops). */
function offersTiles(level: Record<string, unknown>): boolean {
  return ["patrols", "locks", "deliveries", "switches", "teleports", "ice", "belts"].some(
    (field) => level[field] !== undefined,
  );
}

function offersUnsearched(level: {
  availableCommands: readonly string[];
  extraBoards?: unknown;
  patrols?: unknown;
  locks?: unknown;
  deliveries?: unknown;
  switches?: unknown;
  teleports?: unknown;
  ice?: unknown;
  belts?: unknown;
  goal: { type: string };
  requires: { mechanics: readonly string[] };
}): boolean {
  const c = level.availableCommands;
  return (
    c.includes("IF") ||
    c.includes("PROC") ||
    c.includes("INC") ||
    c.includes("MARK") ||
    level.requires.mechanics.includes("nested_loops") ||
    level.goal.type !== "reach_tile" ||
    level.extraBoards !== undefined ||
    // The exact search over patrols, keys, deliveries, switches and floor tiles covers flat programs
    // only, so with loops on offer the reference counts.
    (offersTiles(level) && (c.includes("REPEAT") || c.includes("REPEAT_UNTIL")))
  );
}

/**
 * Runs every content check: the contract validator, the reference solution through the reference
 * simulator, and the solver (par, budget versus par). Pure; never throws.
 */
export function analyzeLevel(content: unknown, referenceSolution: unknown): Analysis {
  const errors: CheckIssue[] = [];
  const warnings: CheckIssue[] = [];
  const candidate = isObject(content) ? { ...content, referenceSolution } : content;
  const validation = validateAuthoringLevel(candidate);
  if (!validation.ok) {
    for (const issue of validation.issues) errors.push({ gate: "validation", ...issue });
    return {
      errors,
      warnings,
      par: null,
      referenceSolved: false,
      requiredMechanics: [],
      level: null,
    };
  }

  const level = candidate as AuthoringLevel;
  const { referenceSolution: program, ...publicLevel } = level;

  // A debug level starts the player with a program to fix, so that program must not already work.
  if (publicLevel.startProgram !== undefined) {
    const start = simulateAll(publicLevel, publicLevel.startProgram);
    if (start.status === "SUCCEEDED") {
      errors.push({
        gate: "start_program",
        path: "startProgram",
        code: "START_PROGRAM_SOLVES",
        message:
          "The start program already solves the level, so there is nothing to fix. Change it so that it fails.",
      });
    }
  }

  // Every board of the level: the reference solution must solve all of them.
  const run = simulateAll(publicLevel, program);
  const referenceSolved = run.status === "SUCCEEDED";
  if (!referenceSolved) {
    const failed = run.results[run.firstFailure ?? 0]!;
    const board = run.results.length > 1 ? `Board ${(run.firstFailure ?? 0) + 1}: ` : "";
    errors.push({
      gate: "reference_solution",
      path: "referenceSolution",
      code: "REFERENCE_SOLUTION_FAILS",
      message: `The reference solution does not solve the level: ${board}${explainResult(failed)}`,
    });
  }

  let par: Par | null = null;
  // The exact search does not cover IF or PROC, and reads one board only. For a level that offers IF or
  // PROC, par is the better of the best program without them and the reference solution (which the
  // simulator has just checked). For a level with test boards par is always the reference solution: the
  // best program for the level's own board may fail on the others, so it is not a par anyone can reach.
  let best = solve(publicLevel);
  if (offersUnsearched(publicLevel) && referenceSolved) {
    const slots = programSlots(program);
    const reference = { commands: slots, steps: run.steps, program, fitsConstraints: true };
    const better =
      !best || slots < best.commands || (slots === best.commands && run.steps < best.steps);
    if (publicLevel.extraBoards !== undefined || better) best = reference;
  }
  if (!best) {
    errors.push({
      gate: "par",
      path: "goal.position",
      code: "GOAL_UNREACHABLE",
      message: "The goal cannot be reached with the available commands.",
    });
  } else {
    par = { commands: best.commands, steps: best.steps };
    if (best.commands > level.constraints.maxCommands) {
      errors.push({
        gate: "par",
        path: "constraints.maxCommands",
        code: "BUDGET_BELOW_PAR",
        message: `The command limit is ${level.constraints.maxCommands}, but the shortest solution needs ${best.commands}.`,
      });
    }
    // maxSteps limits each run; with test boards it is compared with the longest single run.
    const longestRun = Math.max(...run.results.map((r) => r.steps));
    const stepsToCompare =
      publicLevel.extraBoards !== undefined && referenceSolved ? longestRun : best.steps;
    if (stepsToCompare > level.constraints.maxSteps) {
      errors.push({
        gate: "par",
        path: "constraints.maxSteps",
        code: "STEPS_BELOW_PAR",
        message: `The step limit is ${level.constraints.maxSteps}, but the shortest solution needs ${stepsToCompare}.`,
      });
    }
    if (level.constraints.maxCommands > best.commands + Math.max(4, best.commands)) {
      warnings.push({
        gate: "par",
        path: "constraints.maxCommands",
        code: "BUDGET_FAR_ABOVE_PAR",
        message: `The command limit is ${level.constraints.maxCommands}; the shortest solution needs only ${best.commands}.`,
      });
    }
    if (referenceSolved && programSlots(program) > best.commands) {
      warnings.push({
        gate: "par",
        path: "referenceSolution",
        code: "REFERENCE_LONGER_THAN_PAR",
        message: `The reference solution uses ${programSlots(program)} commands; the shortest uses ${best.commands}.`,
      });
    }
  }

  // A level that offers REPEAT should need it: if the shortest program without loops already fits
  // the limit, a loop is optional and the level does not teach loops. A warning, not an error:
  // an introductory level may allow either.
  const offersLoop =
    level.availableCommands.includes("REPEAT") || level.availableCommands.includes("REPEAT_UNTIL");
  if (offersLoop && best) {
    const flat = solve({
      ...level,
      availableCommands: level.availableCommands.filter(
        (c) => c !== "REPEAT" && c !== "REPEAT_UNTIL",
      ),
    });
    if (flat && flat.commands <= level.constraints.maxCommands) {
      warnings.push({
        gate: "par",
        path: "constraints.maxCommands",
        code: "LOOP_NOT_REQUIRED",
        message: `The shortest program without loops needs ${flat.commands} commands and the limit is ${level.constraints.maxCommands}, so a loop is optional here.`,
      });
    }
  }

  // A level that offers IF should need it: if the best program without IF already fits the limit, the
  // decision is optional and the level does not teach decisions.
  if (level.availableCommands.includes("IF") && best) {
    const withoutIf = solve({
      ...level,
      availableCommands: level.availableCommands.filter((c) => c !== "IF"),
    });
    if (withoutIf && withoutIf.commands <= level.constraints.maxCommands) {
      warnings.push({
        gate: "par",
        path: "constraints.maxCommands",
        code: "IF_NOT_REQUIRED",
        message: `A program without IF needs ${withoutIf.commands} commands and the limit is ${level.constraints.maxCommands}, so a decision is optional here.`,
      });
    }
  }

  // The same for procedures: if the best program without PROC already fits the limit, naming a part
  // is optional and the level does not teach procedures.
  if (level.availableCommands.includes("PROC") && best) {
    const withoutProc = solve({
      ...level,
      availableCommands: level.availableCommands.filter((c) => c !== "PROC"),
    });
    if (withoutProc && withoutProc.commands <= level.constraints.maxCommands) {
      warnings.push({
        gate: "par",
        path: "constraints.maxCommands",
        code: "PROC_NOT_REQUIRED",
        message: `A program without PROC needs ${withoutProc.commands} commands and the limit is ${level.constraints.maxCommands}, so a procedure is optional here.`,
      });
    }
  }

  // A level with test boards should need generality: if the best program for the level's own board
  // already solves every other board within the limit, the extra boards teach nothing.
  if (level.extraBoards !== undefined) {
    const own = solve({ ...level, extraBoards: undefined });
    if (own && own.commands <= level.constraints.maxCommands) {
      const everywhere = simulateAll(level, own.program);
      if (everywhere.status === "SUCCEEDED") {
        warnings.push({
          gate: "par",
          path: "extraBoards",
          code: "BOARDS_NOT_REQUIRED",
          message:
            "The shortest program for the first board already solves every board within the limit, so the extra boards add nothing.",
        });
      }
    }
  }

  const required = new Set<string>(level.requires.mechanics);
  if (level.extraBoards !== undefined) required.add("multi_board");
  if (level.startProgram !== undefined) required.add("start_program");
  if (level.patrols !== undefined) required.add("patrol");
  if (level.locks !== undefined) required.add("keys");
  if (level.deliveries !== undefined) required.add("delivery");
  if (level.switches !== undefined) required.add("switch");
  if (level.teleports !== undefined) required.add("teleport");
  if (level.ice !== undefined) required.add("ice");
  if (level.belts !== undefined) required.add("belts");
  // A sweep goal on any board needs the client to draw and count it.
  const goals = [level.goal, ...(level.extraBoards ?? []).map((b) => b.goal)];
  if (goals.some((g) => g.type === "visit_all")) required.add("visit_all");
  for (const command of level.availableCommands) required.add(COMMAND_MECHANICS[command]);

  return { errors, warnings, par, referenceSolved, requiredMechanics: [...required].sort(), level };
}

export type MinimumClient = { version: string; supportedMechanics: string[] } | null;
export type RegistryVersion = { version: string; supportedMechanics: string[] };

/**
 * Every publish gate that currently fails, each with a code and the field it concerns. An empty
 * list means the level may be published.
 */
export function failedGates(input: {
  analysis: Analysis;
  hasSolvedPlaytest: boolean;
  chapterId: string | null;
  minimum: MinimumClient;
  registry: RegistryVersion[];
}): CheckIssue[] {
  const { analysis, hasSolvedPlaytest, chapterId, minimum, registry } = input;
  const failed: CheckIssue[] = [...analysis.errors];

  if (!hasSolvedPlaytest) {
    failed.push({
      gate: "playtest",
      path: "playtests",
      code: "PLAYTEST_REQUIRED",
      message: "Record a solved playtest for the current content before publishing.",
    });
  }

  if (!minimum) {
    failed.push({
      gate: "compatibility",
      path: "requires.mechanics",
      code: "NO_MINIMUM_CLIENT_VERSION",
      message: "No minimum supported app version is set in the client registry.",
    });
  } else {
    for (const mechanic of analysis.requiredMechanics) {
      if (minimum.supportedMechanics.includes(mechanic)) continue;
      const supporting = registry
        .filter((v) => v.supportedMechanics.includes(mechanic))
        .map((v) => v.version);
      failed.push({
        gate: "compatibility",
        path: "requires.mechanics",
        code: "UNSUPPORTED_MECHANIC",
        message:
          `The level needs the mechanic "${mechanic}", which the minimum supported app version ` +
          `${minimum.version} does not support.` +
          (supporting.length
            ? ` Supported from: ${supporting.join(", ")}; raise the minimum version to publish.`
            : " No registered app version supports it."),
      });
    }
  }

  if (!chapterId) {
    failed.push({
      gate: "placement",
      path: "chapterId",
      code: "PLACEMENT_REQUIRED",
      message: "Assign the level to a chapter before publishing.",
    });
  }
  return failed;
}
