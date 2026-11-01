import type { BodyNode, IfNode, Instruction, Primitive } from "./admin-api";
import { PROCEDURE_NAMES } from "@algomind/level-contract";
import { COMMANDS, commandOf, isIf, isLoop, isProc } from "./level-model";
import type { Command } from "@/lib/board";

export const SENSOR_LABELS: Record<string, string> = {
  CLEAR_AHEAD: "Clear ahead",
  CLEAR_LEFT: "Clear left",
  CLEAR_RIGHT: "Clear right",
  FRESH_AHEAD: "Fresh ahead",
  FRESH_LEFT: "Fresh left",
  FRESH_RIGHT: "Fresh right",
  BACK_AHEAD: "Back ahead",
  BACK_LEFT: "Back left",
  BACK_RIGHT: "Back right",
};

/** The sensors in groups; the fresh and back groups need MARK offered. */
export const SENSOR_GROUPS: { label: string; needsMark: boolean; sensors: string[] }[] = [
  { label: "Clear", needsMark: false, sensors: ["CLEAR_AHEAD", "CLEAR_LEFT", "CLEAR_RIGHT"] },
  {
    label: "Fresh (no breadcrumb)",
    needsMark: true,
    sensors: ["FRESH_AHEAD", "FRESH_LEFT", "FRESH_RIGHT"],
  },
  {
    label: "Back (the way back)",
    needsMark: true,
    sensors: ["BACK_AHEAD", "BACK_LEFT", "BACK_RIGHT"],
  },
];

/** The IF an else holds (an else-if), or null when the else holds actions or nothing. */
export function elseIf(node: { else?: { op: string }[] }): IfNode | null {
  const list = node.else ?? [];
  return list.length === 1 && list[0]!.op === "IF" ? asIf(list[0] as Instruction) : null;
}

export const UNTIL_LABELS: Record<string, string> = { BLOCKED: "Blocked", GOAL: "Goal" };

/** The branch limits of an IF (the contract's limits). */
export const IF_LIMITS = { then: { max: 4 }, else: { max: 4 } } as const;

/** The IF an else-if button adds: its own sensor, empty branches. */
export function newElseIf(first: string): IfNode {
  return { op: "IF", when: first, then: [], else: [] };
}

export function newIf(): IfNode {
  return { op: "IF", when: "CLEAR_AHEAD", then: [], else: [] };
}

/** The tape tiles of one node: its own tile, then the tiles of what it holds. One tile per slot. */
function nodeTiles(node: BodyNode | Instruction): Command[] {
  const own = commandOf(node.op);
  const n = node as Instruction;
  if (isIf(node))
    return [
      own,
      ...(n.then ?? []).map((p) => commandOf(p.op)),
      ...(n.else ?? []).flatMap((p) => nodeTiles(p as Instruction)),
    ];
  // A loop and a PROC both hold a body: the definition's tiles come from the PROC, a CALL is one tile.
  if (isLoop(node) || isProc(node)) return [own, ...(n.body ?? []).flatMap(nodeTiles)];
  return [own];
}

/** The tape tiles for a program. */
export function tileCommands(program: Instruction[]): Command[] {
  return program.flatMap(nodeTiles);
}

/** The names of the procedures the program defines, each once, in order of appearance. */
export function definedNames(program: Instruction[]): string[] {
  const names = program.filter(isProc).map((n) => n.name ?? "");
  return names.filter((name, i) => name !== "" && names.indexOf(name) === i);
}

/** The first of A, B, C that no PROC uses yet, or null when all three are defined. */
export function nextFreeName(program: Instruction[]): string | null {
  const used = definedNames(program);
  return PROCEDURE_NAMES.find((name) => !used.includes(name)) ?? null;
}

export function newProc(name: string): Instruction {
  return { op: "PROC", name, body: [] };
}

export function newCall(name: string): Instruction {
  return { op: "CALL", name };
}

/** What a program is made of, wherever it stands: nested loops, else-ifs and the counter and breadcrumb uses included. */
export function countKinds(program: Instruction[]) {
  const counts = {
    counted: 0,
    until: 0,
    ifs: 0,
    elseIfs: 0,
    procs: 0,
    calls: 0,
    nested: 0,
    incs: 0,
    marks: 0,
    byN: 0,
  };
  const walk = (items: readonly Instruction[] | undefined, inLoop: boolean, chained: boolean) => {
    for (const node of items ?? []) {
      if (node.op === "REPEAT" || node.op === "REPEAT_UNTIL") {
        if (node.op === "REPEAT") counts.counted += 1;
        else counts.until += 1;
        if (node.count === "N") counts.byN += 1;
        if (inLoop) counts.nested += 1;
        walk(node.body, true, false);
      } else if (node.op === "IF") {
        counts.ifs += 1;
        if (chained) counts.elseIfs += 1;
        const rest = node.else ?? [];
        if (rest.length === 1 && rest[0]!.op === "IF") walk(rest as Instruction[], inLoop, true);
      } else if (node.op === "PROC") {
        counts.procs += 1;
        walk(node.body, false, false);
      } else if (node.op === "CALL") counts.calls += 1;
      else if (node.op === "INC") counts.incs += 1;
      else if (node.op === "MARK") counts.marks += 1;
    }
  };
  walk(program, false, false);
  return counts;
}

export type { Primitive };

/** The row text of a node: its name, with the condition for an until-loop or an IF, or the name of a procedure. */
export function nodeLabel(node: {
  op: string;
  until?: string;
  when?: string;
  name?: string;
}): string {
  if (node.op === "PROC") return `Procedure ${node.name ?? ""}`.trim();
  if (node.op === "CALL") return `Call ${node.name ?? ""}`.trim();
  if (node.op === "REPEAT_UNTIL")
    return `Repeat until ${(UNTIL_LABELS[node.until ?? ""] ?? "").toLowerCase()}`.trim();
  if (node.op === "IF") return `If ${(SENSOR_LABELS[node.when ?? ""] ?? "").toLowerCase()}`.trim();
  return COMMANDS.find((c) => c.op === node.op)?.label ?? node.op;
}

/** The node as an IfNode, with empty branches for any field the saved data lacks. */
export function asIf(node: {
  op: string;
  when?: string;
  then?: Primitive[];
  else?: Primitive[];
}): IfNode {
  return {
    op: "IF",
    when: node.when ?? "CLEAR_AHEAD",
    then: node.then ?? [],
    else: node.else ?? [],
  };
}
