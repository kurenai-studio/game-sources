import {
  ACTION_COMMANDS,
  CALL_OP,
  COUNTER_REF,
  IF_OP,
  LIMITS,
  PROCEDURE_NAMES,
  PROC_OP,
  REPEAT_OP,
  REPEAT_UNTIL_OP,
  SENSORS,
  UNTIL_CONDITIONS,
} from "./constants.js";
import type { PrimitiveInstruction } from "./types.js";

const ACTIONS = ACTION_COMMANDS as readonly string[];

export type Node = Record<string, unknown>;

export function isNode(node: unknown): node is Node {
  return typeof node === "object" && node !== null;
}

export function isActionNode(node: unknown): node is PrimitiveInstruction {
  return isNode(node) && typeof node["op"] === "string" && ACTIONS.includes(node["op"]);
}

function isActionList(list: unknown, min: number, max: number): boolean {
  return (
    Array.isArray(list) && list.length >= min && list.length <= max && list.every(isActionNode)
  );
}

/** Where a node stands, which decides what it may hold. */
export type Place = {
  /** Inside a procedure body (a CALL may not stand there). */
  inProc: boolean;
  /** How many loops enclose the node (a loop needs fewer than two). */
  loops: number;
  /** Inside an IF branch (only actions may stand there). */
  branch: boolean;
  top: boolean;
  /** The level lists the mechanic recursion: a CALL may stand in a procedure body. */
  recursion: boolean;
};

/** The place of a top-level node. */
export const topPlace = (recursion: boolean): Place => ({
  inProc: false,
  loops: 0,
  branch: false,
  top: true,
  recursion,
});

/** An IF whose branches can run: a known sensor, 1 to 4 actions to run, and 0 to 4 actions or one IF otherwise. */
function runnableIf(node: Node, chain: number): boolean {
  if (chain > LIMITS.ifChain) return false;
  if (typeof node["when"] !== "string" || !(SENSORS as readonly string[]).includes(node["when"])) {
    return false;
  }
  if (!isActionList(node["then"], LIMITS.ifThen.min, LIMITS.ifThen.max)) return false;
  const other = node["else"];
  if (Array.isArray(other) && other.length === 1 && isNode(other[0]) && other[0]["op"] === IF_OP) {
    return runnableIf(other[0], chain + 1);
  }
  return isActionList(other, LIMITS.ifElse.min, LIMITS.ifElse.max);
}

/**
 * True when the node and everything inside it can be run: known ops and conditions, bodies and branches
 * of the right size, and only what the place allows. `procs` are the procedures a CALL may name.
 */
export function runnable(node: unknown, place: Place, procs: ReadonlyMap<string, Node>): boolean {
  if (!isNode(node)) return false;
  const op = node["op"];
  if (isActionNode(node)) return true;
  if (op === IF_OP) return !place.branch && runnableIf(node, 1);
  if (op === CALL_OP) {
    // Inside a procedure a CALL stands directly in the body (the validator checks the mechanic).
    const stands = !place.branch && (!place.inProc || (place.recursion && place.loops === 0));
    const when = node["when"];
    const sensorOk =
      when === undefined ||
      (place.recursion &&
        typeof when === "string" &&
        (SENSORS as readonly string[]).includes(when));
    return stands && sensorOk && typeof node["name"] === "string" && procs.has(node["name"]);
  }
  const body = node["body"];
  const bodyOk = (min: number, max: number, inner: Place): boolean =>
    Array.isArray(body) &&
    body.length >= min &&
    body.length <= max &&
    body.every((item) => runnable(item, inner, procs));
  if (op === REPEAT_OP || op === REPEAT_UNTIL_OP) {
    if (place.branch || place.loops >= 2) return false;
    if (op === REPEAT_OP) {
      const count = node["count"];
      const fixed =
        typeof count === "number" &&
        Number.isInteger(count) &&
        count >= LIMITS.repeatCount.min &&
        count <= LIMITS.repeatCount.max;
      if (!fixed && count !== COUNTER_REF) return false;
    } else if (
      typeof node["until"] !== "string" ||
      !(UNTIL_CONDITIONS as readonly string[]).includes(node["until"])
    ) {
      return false;
    }
    return bodyOk(LIMITS.repeatBody.min, LIMITS.repeatBody.max, {
      ...place,
      top: false,
      loops: place.loops + 1,
    });
  }
  if (op === PROC_OP) {
    return (
      place.top &&
      typeof node["name"] === "string" &&
      (PROCEDURE_NAMES as readonly string[]).includes(node["name"]) &&
      bodyOk(LIMITS.procBody.min, LIMITS.procBody.max, {
        inProc: true,
        loops: 0,
        branch: false,
        top: false,
        recursion: place.recursion,
      })
    );
  }
  return false;
}
