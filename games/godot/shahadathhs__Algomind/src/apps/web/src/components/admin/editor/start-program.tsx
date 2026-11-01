"use client";

import { Caption } from "@/components/ui/caption";
import type { LevelContent } from "@/lib/admin/admin-api";
import { offersNestedLoops, offersRecursion } from "@/lib/admin/level-model";
import { ProgramEditor } from "./program-editor";

/**
 * The program the tape starts with, for a level about fixing a program (a debug level). It is
 * checked like any program of the level, but it must not solve the level: the publish gate in the
 * API refuses a start program that already does.
 */
export function StartProgram({
  content,
  onContent,
}: {
  content: LevelContent;
  onContent: (next: LevelContent) => void;
}) {
  const on = content.startProgram !== undefined;
  const toggle = () => {
    const { startProgram: _drop, ...rest } = content;
    onContent(on ? rest : { ...rest, startProgram: [] });
  };
  return (
    <div className="mt-10 max-w-[560px]">
      <Caption className="mb-3">Start program</Caption>
      <label className="flex min-h-11 items-center gap-3 text-base font-semibold">
        <input
          type="checkbox"
          className="h-5 w-5 accent-[var(--ink)]"
          checked={on}
          onChange={toggle}
        />
        <span>
          The tape starts with a program (a debug level)
          <span className="block text-sm font-normal text-mute">
            Players fix it instead of building one. It must not solve the level; the reference
            solution above is the fix.
          </span>
        </span>
      </label>
      {on && (
        <div className="mt-4">
          <ProgramEditor
            program={content.startProgram ?? []}
            onChange={(next) => onContent({ ...content, startProgram: next })}
            available={content.availableCommands}
            nested={offersNestedLoops(content)}
            recursion={offersRecursion(content)}
            idPrefix="Start"
          />
        </div>
      )}
    </div>
  );
}
