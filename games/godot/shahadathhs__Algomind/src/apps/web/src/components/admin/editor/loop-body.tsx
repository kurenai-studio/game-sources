"use client";

import { moveItem } from "@/lib/admin/list-ops";
import type { Instruction } from "@/lib/admin/admin-api";
import { REPEAT_LIMITS, isCall, isIf, isLoop, offersCounter } from "@/lib/admin/level-model";
import { UNTIL_LABELS, asIf, nodeLabel } from "@/lib/admin/program-model";
import { SelectField } from "../ui";
import { AddCommands } from "./add-commands";
import { CallName } from "./call-name";
import { IfBranches } from "./if-branches";
import { ItemRow } from "./item-row";
import { LoopCount } from "./loop-count";

/** The count and body of one loop, shown indented under its row. */
export function LoopBody({
  node,
  name,
  idPrefix,
  available,
  callNames,
  nested = false,
  onCount,
  onUntil,
  onBody,
}: {
  node: Instruction;
  /** E.g. "loop 1" or "command 2 of procedure A"; names the loop for assistive technology. */
  name: string;
  idPrefix: string;
  available: string[];
  /** The defined procedure names when a CALL may stand in this body (the main program); else omitted. */
  callNames?: readonly string[];
  /** The level allows nested loops and this loop is the outer one: its body may hold a loop. */
  nested?: boolean;
  onCount: (count: number | "N") => void;
  onUntil: (until: string) => void;
  onBody: (body: Instruction[]) => void;
}) {
  const body = node.body ?? [];
  const full = body.length >= REPEAT_LIMITS.body.max;
  const id = `${idPrefix}-count`;
  return (
    <div className="mt-2 mb-2 ml-8 grid gap-2 border-l-2 border-ink pl-4">
      {node.op === "REPEAT_UNTIL" ? (
        <>
          <SelectField
            label="Until"
            id={`${idPrefix}-until`}
            value={node.until ?? "BLOCKED"}
            onChange={(e) => onUntil(e.target.value)}
          >
            {Object.entries(UNTIL_LABELS).map(([value, text]) => (
              <option key={value} value={value}>
                {text}
              </option>
            ))}
          </SelectField>
          <p className="text-sm font-semibold text-mute">
            {node.until === "GOAL"
              ? "The body runs round after round until the goal is reached, a move fails or the step limit stops it."
              : "The body runs while the cell ahead is open. It can run zero times."}
          </p>
        </>
      ) : (
        <LoopCount
          id={id}
          value={node.count}
          counter={offersCounter({ availableCommands: available })}
          onChange={onCount}
        />
      )}
      {body.length === 0 && (
        <p className="text-sm font-semibold text-mute">
          This loop is empty. Add a command to it; an empty loop is not a valid program.
        </p>
      )}
      <ol className="grid gap-1" aria-label={`${name[0]!.toUpperCase()}${name.slice(1)} body`}>
        {body.map((b, j) => (
          <li key={j} className="py-1">
            <ItemRow
              index={j}
              count={body.length}
              text={nodeLabel(b)}
              name={`command ${j + 1} of ${name}`}
              onMove={(to) => onBody(moveItem(body, j, to))}
              onRemove={() => onBody(body.filter((_, k) => k !== j))}
            />
            {isIf(b) && (
              <IfBranches
                node={asIf(b)}
                where={`command ${j + 1} of ${name}`}
                idPrefix={`${idPrefix}-if-${j}`}
                available={available}
                onChange={(next) => onBody(body.map((x, k) => (k === j ? next : x)))}
              />
            )}
            {isLoop(b) && (
              <LoopBody
                node={b as Instruction}
                name={`inner loop ${j + 1} of ${name}`}
                idPrefix={`${idPrefix}-loop-${j}`}
                available={available}
                callNames={callNames}
                onCount={(count) => onBody(body.map((x, k) => (k === j ? { ...x, count } : x)))}
                onUntil={(until) => onBody(body.map((x, k) => (k === j ? { ...x, until } : x)))}
                onBody={(inner) =>
                  onBody(body.map((x, k) => (k === j ? { ...x, body: inner } : x)))
                }
              />
            )}
            {isCall(b) && callNames && (
              <CallName
                value={(b as Instruction).name ?? ""}
                names={callNames}
                id={`${idPrefix}-call-${j}`}
                where={`command ${j + 1} of ${name}`}
                onChange={(next) =>
                  onBody(body.map((x, k) => (k === j ? { ...x, name: next } : x)))
                }
              />
            )}
          </li>
        ))}
      </ol>
      <AddCommands
        available={available}
        label={`Add a command to ${name}`}
        disabled={full}
        loops={nested}
        callNames={callNames}
        onAdd={(node) => onBody([...body, node])}
      />
      {full && (
        <p className="text-sm font-semibold text-mute">
          A loop body holds at most {REPEAT_LIMITS.body.max} commands.
        </p>
      )}
    </div>
  );
}
