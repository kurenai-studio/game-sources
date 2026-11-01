"use client";

import { useMemo } from "react";
import { Caption } from "@/components/ui/caption";
import type { Instruction, LevelContent } from "@/lib/admin/admin-api";
import { boardCount } from "@/lib/admin/board-model";
import {
  localCheck,
  offersNestedLoops,
  offersRecursion,
  parIsReferenceFor,
  slotsOf,
} from "@/lib/admin/level-model";
import { Notice } from "../ui";
import { BoardResults } from "./board-results";
import { ProgramEditor } from "./program-editor";
import { StartProgram } from "./start-program";

export function SolutionPanel({
  content,
  solution,
  onSolution,
  onContent,
}: {
  content: LevelContent;
  solution: Instruction[];
  onSolution: (next: Instruction[]) => void;
  onContent: (next: LevelContent) => void;
}) {
  const check = useMemo(() => localCheck(content, solution), [content, solution]);
  const par = check.par;
  const boards = boardCount(content);
  return (
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_320px]">
      <div>
        <ProgramEditor
          program={solution}
          onChange={onSolution}
          available={content.availableCommands}
          nested={offersNestedLoops(content)}
          recursion={offersRecursion(content)}
          idPrefix="Reference"
        />
        <StartProgram content={content} onContent={onContent} />
      </div>
      <div className="grid content-start gap-4">
        <Caption>Reference solution</Caption>
        <p className="text-base font-semibold">
          {slotsOf(solution)} {slotsOf(solution) === 1 ? "command" : "commands"}
          {par && (check.parIsReference ? ", this is par" : `, par ${par.commands}`)}
        </p>
        {!check.validation.ok ? (
          <Notice kind="info">
            The level is not valid yet, so the solution cannot be run. See the Checks tab.
          </Notice>
        ) : check.solved ? (
          <Notice kind="info">
            {boards > 1
              ? "This solution reaches the goal on every board."
              : "This solution reaches the goal."}
          </Notice>
        ) : (
          <Notice>
            {boards > 1
              ? "This solution does not reach the goal on every board."
              : "This solution does not reach the goal."}
          </Notice>
        )}
        {check.run && boards > 1 && (
          <>
            <BoardResults run={check.run} />
            <p className="text-base font-semibold">
              Total steps: {check.run.steps} over {boards} boards
            </p>
          </>
        )}
        {par && !parIsReferenceFor(content) && slotsOf(solution) > par.commands && check.solved && (
          <Notice kind="info">A shorter solution exists: {par.commands} commands.</Notice>
        )}
      </div>
    </div>
  );
}
