"use client";

import { TapeView } from "@/components/ui/tape-view";
import { tapeFromProgram } from "@/lib/tape";
import type { Instruction } from "@/lib/admin/admin-api";
import { isCall, isIf, isLoop, isProc, slotsOf } from "@/lib/admin/level-model";
import {
  asIf,
  definedNames,
  nextFreeName,
  nodeLabel,
  tileCommands,
} from "@/lib/admin/program-model";
import { moveItem } from "@/lib/admin/list-ops";
import { AddCommands } from "./add-commands";
import { CallName } from "./call-name";
import { CallWhen } from "./call-when";
import { IfBranches } from "./if-branches";
import { ItemRow } from "./item-row";
import { LoopBody } from "./loop-body";
import { ProcBody } from "./proc-body";

export function ProgramEditor({
  program,
  onChange,
  available,
  nested = false,
  recursion = false,
  idPrefix,
}: {
  program: Instruction[];
  onChange: (next: Instruction[]) => void;
  available: string[];
  /** The level lists nested_loops: a loop body may hold one loop. */
  nested?: boolean;
  /** The level lists the mechanic recursion: calls may stand in procedures and carry a sensor. */
  recursion?: boolean;
  idPrefix: string;
}) {
  const slots = slotsOf(program);
  const tiles = tapeFromProgram(tileCommands(program), { emptySlot: "plus" });
  const canProc = available.includes("PROC");
  const names = definedNames(program);

  const setNode = (i: number, change: Partial<Instruction>) =>
    onChange(program.map((node, j) => (j === i ? { ...node, ...change } : node)));

  return (
    <div>
      <div className="mb-4 max-w-[560px]">
        <TapeView
          tiles={tiles}
          label={
            program.length ? `Program of ${slots} commands.` : "An empty program. Add a command."
          }
        />
      </div>
      <div className="mb-4">
        <AddCommands
          available={available}
          label="Add a command"
          loops
          callNames={canProc ? names : undefined}
          freeName={canProc ? nextFreeName(program) : undefined}
          onAdd={(node) => onChange([...program, node])}
        />
      </div>
      {program.length > 0 && (
        <ol className="grid max-w-[560px] gap-1" aria-label={`${idPrefix} program`}>
          {program.map((p, i) => (
            <li key={i} className="border-t-2 border-ink py-1">
              <ItemRow
                index={i}
                count={program.length}
                text={nodeLabel(p)}
                name={`step ${i + 1}`}
                onMove={(to) => onChange(moveItem(program, i, to))}
                onRemove={() => onChange(program.filter((_, j) => j !== i))}
              />
              {isLoop(p) && (
                <LoopBody
                  node={p}
                  name={`loop ${i + 1}`}
                  idPrefix={`loop-${i}`}
                  available={available}
                  callNames={canProc ? names : undefined}
                  nested={nested}
                  onCount={(count) => setNode(i, { count })}
                  onUntil={(until) => setNode(i, { until })}
                  onBody={(body) => setNode(i, { body })}
                />
              )}
              {isProc(p) && (
                <ProcBody
                  node={p}
                  available={available}
                  nested={nested}
                  names={names}
                  recursion={recursion}
                  idPrefix={`${idPrefix}-proc-${i}`}
                  onBody={(body) => setNode(i, { body })}
                />
              )}
              {isCall(p) && (
                <CallName
                  value={p.name ?? ""}
                  names={names}
                  id={`${idPrefix}-call-${i}`}
                  where={`step ${i + 1}`}
                  onChange={(name) => setNode(i, { name })}
                />
              )}
              {isCall(p) && recursion && (
                <CallWhen
                  value={p.when}
                  id={`${idPrefix}-when-${i}`}
                  where={`step ${i + 1}`}
                  marks={available.includes("MARK")}
                  onChange={(when) =>
                    onChange(
                      program.map((node, j) => {
                        if (j !== i) return node;
                        const { when: _drop, ...rest } = node;
                        return when === undefined ? rest : { ...rest, when };
                      }),
                    )
                  }
                />
              )}
              {isIf(p) && (
                <IfBranches
                  node={asIf(p)}
                  where={`step ${i + 1}`}
                  idPrefix={`${idPrefix}-if-${i}`}
                  available={available}
                  onChange={(next) => onChange(program.map((node, j) => (j === i ? next : node)))}
                />
              )}
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
