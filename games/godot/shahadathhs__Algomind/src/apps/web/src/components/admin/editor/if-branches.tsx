"use client";

import type { IfNode, Primitive } from "@/lib/admin/admin-api";
import { IF_CHAIN_MAX, offersMarks, primitivesOf } from "@/lib/admin/level-model";
import {
  IF_LIMITS,
  SENSOR_GROUPS,
  SENSOR_LABELS,
  elseIf,
  newElseIf,
} from "@/lib/admin/program-model";
import { OutlineAction, SelectField } from "../ui";
import { TextAction } from "../text-action";
import { BranchList } from "./branch-list";

/**
 * The sensor and the two branches of one IF, shown indented under its row. An else that is empty can
 * grow an else-if: one nested IF with its own sensor, then and else, up to a chain of six.
 */
export function IfBranches({
  node,
  where,
  idPrefix,
  available,
  position = 1,
  onChange,
}: {
  node: IfNode;
  where: string;
  idPrefix: string;
  available: string[];
  /** Where this IF stands in its else-if chain: 1 for the first. */
  position?: number;
  onChange: (next: IfNode) => void;
}) {
  const marks = offersMarks({ availableCommands: available });
  const next = elseIf(node);
  const id = `${idPrefix}-sensor`;
  return (
    <div className="mt-2 mb-2 ml-8 grid gap-3 border-l-2 border-ink pl-4">
      <SelectField
        label={position > 1 ? "Else if sensor" : "Sensor"}
        id={id}
        value={node.when}
        onChange={(e) => onChange({ ...node, when: e.target.value })}
      >
        {SENSOR_GROUPS.filter((g) => !g.needsMark || marks || g.sensors.includes(node.when)).map(
          (g) => (
            <optgroup key={g.label} label={g.label}>
              {g.sensors.map((value) => (
                <option key={value} value={value}>
                  {SENSOR_LABELS[value] ?? value}
                </option>
              ))}
            </optgroup>
          ),
        )}
      </SelectField>
      {node.then.length === 0 && (
        <p className="text-sm font-semibold text-mute">
          The then branch is empty. Add a command to it; an if with an empty then is not a valid
          program.
        </p>
      )}
      <BranchList
        title="Then"
        items={node.then}
        max={IF_LIMITS.then.max}
        primitives={primitivesOf(available)}
        where={where}
        onChange={(then: Primitive[]) => onChange({ ...node, then })}
      />
      {next ? (
        <div className="grid gap-1">
          <div className="flex flex-wrap items-center gap-x-4">
            <p className="grow text-xs tracking-[2px] text-mute uppercase">
              Else if {position + 1} of {IF_CHAIN_MAX} at most
            </p>
            <TextAction
              onClick={() => onChange({ ...node, else: [] })}
              aria-label={`Remove the else if of ${where}`}
            >
              Remove else if
            </TextAction>
          </div>
          <IfBranches
            node={next}
            where={`else if ${position + 1} of ${where}`}
            idPrefix={`${idPrefix}-else`}
            available={available}
            position={position + 1}
            onChange={(inner) => onChange({ ...node, else: [inner] })}
          />
        </div>
      ) : (
        <>
          <BranchList
            title="Else"
            items={node.else as Primitive[]}
            max={IF_LIMITS.else.max}
            primitives={primitivesOf(available)}
            where={where}
            onChange={(items: Primitive[]) => onChange({ ...node, else: items })}
          />
          <div>
            <OutlineAction
              type="button"
              disabled={node.else.length > 0 || position >= IF_CHAIN_MAX}
              onClick={() => onChange({ ...node, else: [newElseIf(node.when)] })}
              aria-label={`Add an else if to ${where}`}
            >
              Else if
            </OutlineAction>
            {node.else.length > 0 && (
              <p className="mt-2 text-sm font-semibold text-mute">
                An else holds commands or one else if, not both. Remove the else commands first.
              </p>
            )}
            {position >= IF_CHAIN_MAX && (
              <p className="mt-2 text-sm font-semibold text-mute">
                A chain holds at most {IF_CHAIN_MAX} ifs.
              </p>
            )}
          </div>
        </>
      )}
    </div>
  );
}
