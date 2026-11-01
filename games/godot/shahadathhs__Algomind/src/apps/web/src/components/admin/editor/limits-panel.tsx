"use client";

import {
  COMMANDS,
  MAX_COMMANDS,
  MAX_STEPS,
  NESTED_LOOPS,
  offersNestedLoops,
  offersRecursion,
  RECURSION,
} from "@/lib/admin/level-model";
import { Field } from "../ui";
import type { ContentProps } from "./content-props";

/** The mechanics that follow the commands (the API adds counter and markers itself), plus nested_loops when kept. */
function mechanicsFor(commands: string[], nested: boolean, recursion = false): string[] {
  const out: string[] = [];
  if (commands.includes("MOVE_FORWARD")) out.push("move");
  if (commands.includes("TURN_LEFT") || commands.includes("TURN_RIGHT")) out.push("turn");
  if (commands.includes("REPEAT")) out.push("repeat");
  if (commands.includes("REPEAT_UNTIL")) out.push("repeat_until");
  if (commands.includes("IF")) out.push("if");
  if (commands.includes("PROC")) out.push("procedures");
  if (nested && (commands.includes("REPEAT") || commands.includes("REPEAT_UNTIL")))
    out.push(NESTED_LOOPS);
  if (recursion && commands.includes("PROC")) out.push(RECURSION);
  return out;
}

export function LimitsPanel({ content, onChange }: ContentProps) {
  const toggle = (op: string) => {
    const has = content.availableCommands.includes(op);
    const next = COMMANDS.map((c) => c.op as string).filter((o) =>
      o === op ? !has : content.availableCommands.includes(o),
    );
    onChange({
      ...content,
      availableCommands: next,
      requires: {
        mechanics: mechanicsFor(next, offersNestedLoops(content), offersRecursion(content)),
      },
    });
  };
  const hasLoop =
    content.availableCommands.includes("REPEAT") ||
    content.availableCommands.includes("REPEAT_UNTIL");
  const toggleNested = () =>
    onChange({
      ...content,
      requires: {
        mechanics: mechanicsFor(
          content.availableCommands,
          !offersNestedLoops(content),
          offersRecursion(content),
        ),
      },
    });
  const toggleRecursion = () =>
    onChange({
      ...content,
      requires: {
        mechanics: mechanicsFor(
          content.availableCommands,
          offersNestedLoops(content),
          !offersRecursion(content),
        ),
      },
    });
  return (
    <div className="grid max-w-[560px] gap-6">
      <fieldset>
        <legend className="mb-3 text-xs tracking-[2px] text-mute uppercase">
          Allowed commands
        </legend>
        <div className="grid gap-2">
          {COMMANDS.map((c) => (
            <label key={c.op} className="flex min-h-11 items-center gap-3 text-base font-semibold">
              <input
                type="checkbox"
                className="h-5 w-5 accent-[var(--ink)]"
                checked={content.availableCommands.includes(c.op)}
                onChange={() => toggle(c.op)}
              />
              <span>
                {c.label}
                {c.note && <span className="block text-sm font-normal text-mute">{c.note}</span>}
              </span>
            </label>
          ))}
          <label className="flex min-h-11 items-center gap-3 text-base font-semibold">
            <input
              type="checkbox"
              className="h-5 w-5 accent-[var(--ink)]"
              checked={offersNestedLoops(content)}
              disabled={!hasLoop}
              onChange={toggleNested}
            />
            <span>
              Nested loops
              <span className="block text-sm font-normal text-mute">
                A loop body may hold one more loop (two levels). Needs Repeat or Repeat until.
              </span>
            </span>
          </label>
          <label className="flex min-h-11 items-center gap-3 text-base font-semibold">
            <input
              type="checkbox"
              className="h-5 w-5 accent-[var(--ink)]"
              checked={offersRecursion(content)}
              disabled={!content.availableCommands.includes("PROC")}
              onChange={toggleRecursion}
            />
            <span>
              Recursion
              <span className="block text-sm font-normal text-mute">
                A procedure may call procedures, itself included, and a call may carry a sensor (the
                base case). Needs Procedures.
              </span>
            </span>
          </label>
        </div>
        <p className="mt-2 text-sm font-semibold text-mute">
          Required mechanics follow the commands: {content.requires.mechanics.join(", ") || "none"}.
        </p>
      </fieldset>
      <Field
        label={`Max commands (${MAX_COMMANDS.min} to ${MAX_COMMANDS.max})`}
        id="ed-max-commands"
        type="number"
        min={MAX_COMMANDS.min}
        max={MAX_COMMANDS.max}
        value={content.constraints.maxCommands}
        onChange={(e) =>
          onChange({
            ...content,
            constraints: { ...content.constraints, maxCommands: Number(e.target.value) || 1 },
          })
        }
        hint="How many instructions a player may place."
      />
      <Field
        label={`Max steps (${MAX_STEPS.min} to ${MAX_STEPS.max})`}
        id="ed-max-steps"
        type="number"
        min={MAX_STEPS.min}
        max={MAX_STEPS.max}
        value={content.constraints.maxSteps}
        onChange={(e) =>
          onChange({
            ...content,
            constraints: { ...content.constraints, maxSteps: Number(e.target.value) || 1 },
          })
        }
        hint="A run is stopped after this many steps."
      />
    </div>
  );
}
