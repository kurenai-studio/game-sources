import { createHash } from "node:crypto";
import {
  programSlots,
  simulateAll,
  validateLevel,
  validateProgram,
  type Level,
  type Program,
} from "@algomind/level-contract";

export type Verified =
  | { ok: true; slots: number; steps: number }
  | {
      ok: false;
      code: "PROGRAM_INVALID";
      issues: { path: string; code: string; message: string }[];
    }
  | { ok: false; code: "LEVEL_INVALID" | "PROGRAM_DID_NOT_SOLVE"; issues: [] };

/**
 * Validates a submitted program for a stored level and runs it with the reference simulator. Only
 * a program that is valid for the level and reaches the goal is a submission. Pure: no database.
 */
export function verifySubmission(content: unknown, program: unknown): Verified {
  const checked = validateLevel(content);
  if (!checked.ok) return { ok: false, code: "LEVEL_INVALID", issues: [] };
  const level = content as Level;
  const checkedProgram = validateProgram(level, program);
  if (!checkedProgram.ok)
    return { ok: false, code: "PROGRAM_INVALID", issues: checkedProgram.issues };
  const result = simulateAll(level, program as Program);
  if (result.status !== "SUCCEEDED")
    return { ok: false, code: "PROGRAM_DID_NOT_SOLVE", issues: [] };
  return { ok: true, slots: programSlots(program as Program), steps: result.steps };
}

/** The same program always has the same hash: nodes are rebuilt in a fixed key order. */
type HashNode = {
  op: string;
  count?: number;
  until?: string;
  when?: string;
  name?: string;
  body?: HashNode[];
  then?: HashNode[];
  else?: HashNode[];
};

export function programHash(program: HashNode[]) {
  const ops = (list: HashNode[] | undefined) => (list ?? []).map((b) => ({ op: b.op }));
  const canonicalNode = (n: HashNode): unknown =>
    n.op === "REPEAT"
      ? { op: n.op, count: n.count, body: (n.body ?? []).map(canonicalNode) }
      : n.op === "REPEAT_UNTIL"
        ? { op: n.op, until: n.until, body: (n.body ?? []).map(canonicalNode) }
        : n.op === "IF"
          ? {
              op: n.op,
              when: n.when,
              then: ops(n.then),
              // An else-if chain: the else holds one more IF, which has to be hashed in full.
              else:
                n.else?.length === 1 && n.else[0]!.op === "IF"
                  ? [canonicalNode(n.else[0]!)]
                  : ops(n.else),
            }
          : n.op === "PROC"
            ? { op: n.op, name: n.name, body: (n.body ?? []).map(canonicalNode) }
            : n.op === "CALL"
              ? { op: n.op, name: n.name }
              : { op: n.op };
  const canonical = program.map(canonicalNode);
  return createHash("sha256").update(JSON.stringify(canonical)).digest("hex");
}
