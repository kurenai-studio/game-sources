"use client";

import { useMemo, useState } from "react";
import { BoardView } from "@/components/ui/board-view";
import { Caption } from "@/components/ui/caption";
import type { Instruction, LevelContent } from "@/lib/admin/admin-api";
import { boardCaseOf, boardCount, onBoard } from "@/lib/admin/board-model";
import { floorCells, isSweep } from "@/lib/admin/goal-model";
import {
  boardData,
  explainResult,
  offersCounter,
  offersNestedLoops,
  offersMarks,
  simulateAll,
} from "@/lib/admin/level-model";
import { crumbsOf, visitedOf } from "@/lib/admin/run-view";
import type { Level, Program } from "@algomind/level-contract";
import { OutlineAction } from "../ui";
import { BoardResults, ResultMark } from "./board-results";
import { BoardTabs } from "./board-tabs";
import { ProgramEditor } from "./program-editor";

export function PreviewPanel({
  content,
  solution,
}: {
  content: LevelContent;
  solution: Instruction[];
}) {
  const [program, setProgram] = useState<Instruction[]>(solution);
  const [step, setStep] = useState(0);
  const [picked, setPicked] = useState(0);
  const count = boardCount(content);
  const index = Math.min(picked, count - 1);
  const run = useMemo(() => {
    try {
      return simulateAll(content as unknown as Level, program as unknown as Program);
    } catch {
      return null;
    }
  }, [content, program]);
  const result = run?.results[index] ?? null;
  const view = onBoard(content, index);

  const total = result?.trace.length ?? 0;
  const shown = Math.min(step, total);
  const entry = shown > 0 ? result?.trace[shown - 1] : undefined;
  const trace = result?.trace.slice(0, shown) ?? [];
  const [sx, sy] = boardCaseOf(content, index).initialState.position;
  const position = entry ? entry.position : ([sx, sy] as [number, number]);
  const direction = entry ? entry.direction : view.initialState.direction;
  const finished = result !== null && shown >= total;
  const blocked = finished && result?.blockedCell ? result.blockedCell : undefined;

  const sweep = isSweep(view.goal);
  const visited = visitedOf([sx, sy], trace);
  const board = boardData(view, {
    automaton: { x: position[0], y: position[1], dir: direction },
    trail: sweep ? visited : trace.map((t) => t.position),
    crumbs: offersMarks(content) ? crumbsOf(trace) : undefined,
    hit: blocked && blocked[0] >= 0 && blocked[1] >= 0 ? blocked : undefined,
  });

  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
      <div>
        <Caption className="mb-3">Program to try</Caption>
        <ProgramEditor
          program={program}
          onChange={(next) => {
            setProgram(next);
            setStep(0);
          }}
          available={content.availableCommands}
          nested={offersNestedLoops(content)}
          idPrefix="Preview"
        />
        <div className="mt-4 flex flex-wrap gap-3">
          <OutlineAction
            type="button"
            onClick={() => setStep((s) => Math.min(total, s + 1))}
            disabled={!result || shown >= total}
          >
            Step
          </OutlineAction>
          <OutlineAction
            type="button"
            onClick={() => setStep(total)}
            disabled={!result || shown >= total}
          >
            Run
          </OutlineAction>
          <OutlineAction type="button" onClick={() => setStep(0)} disabled={shown === 0}>
            Reset
          </OutlineAction>
          <OutlineAction
            type="button"
            onClick={() => {
              setProgram(solution);
              setStep(0);
            }}
          >
            Use reference solution
          </OutlineAction>
        </div>
      </div>
      <div>
        <BoardTabs
          count={count}
          selected={index}
          onSelect={(i) => {
            setPicked(i);
            setStep(0);
          }}
          mark={(i) =>
            run && count > 1 ? (
              <span className="inline-flex items-center gap-1">
                <ResultMark ok={run.results[i]?.status === "SUCCEEDED"} />
                <span className="sr-only">
                  {run.results[i]?.status === "SUCCEEDED" ? "solved" : "failed"}
                </span>
              </span>
            ) : null
          }
        />
        <BoardView board={board} label={`Board ${index + 1} after ${shown} of ${total} steps.`} />
        <p role="status" className="mt-3 text-base font-semibold">
          {result === null
            ? "This level cannot be simulated yet. Check the Checks tab."
            : finished
              ? `${count > 1 ? `Board ${index + 1}: ` : ""}${explainResult(result)} ${total} ${total === 1 ? "step" : "steps"}.`
              : `Step ${shown} of ${total}.`}
        </p>
        {(offersCounter(content) || sweep) && result !== null && (
          <p className="mt-2 flex flex-wrap gap-x-6 text-sm font-semibold tracking-[1px] tabular-nums uppercase">
            {offersCounter(content) && <span>N {entry?.counter ?? 1}</span>}
            {sweep && (
              <span>
                {visited.length} / {floorCells(view.board)} CELLS
              </span>
            )}
          </p>
        )}
        {run && count > 1 && (
          <div className="mt-4 grid gap-2">
            <BoardResults run={run} />
            <p className="text-base font-semibold">
              {run.status === "SUCCEEDED"
                ? `Solved on every board, ${run.steps} steps in total.`
                : `Not solved: board ${(run.firstFailure ?? 0) + 1} failed.`}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
