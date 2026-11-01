import type { IfInstruction, Instruction, Program } from "./types.js";

/** The slots an IF uses: itself, its `then` actions, and its `else` (the actions, or the nested IF). */
function ifSlots(node: IfInstruction): number {
  const other = node.else as Instruction[];
  const elseSlots =
    other.length === 1 && other[0]!.op === "IF" ? nodeSlots(other[0]!) : other.length;
  return 1 + node.then.length + elseSlots;
}

function nodeSlots(node: Instruction): number {
  if (node.op === "IF") return ifSlots(node);
  if ("body" in node) return 1 + node.body.reduce((sum, item) => sum + nodeSlots(item), 0);
  return 1;
}

/**
 * The command budget a program uses: an action and a CALL are 1 slot; a loop, a PROC and an IF are 1
 * plus what they hold (the slots of the body items, the actions of the branches, or a nested IF in an
 * else). Compare it with `constraints.maxCommands` and with par.
 */
export function programSlots(program: Program): number {
  return program.reduce((sum, node) => sum + nodeSlots(node), 0);
}
