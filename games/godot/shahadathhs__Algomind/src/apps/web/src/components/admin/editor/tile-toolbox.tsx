"use client";

import { Caption } from "@/components/ui/caption";
import type { LevelContent } from "@/lib/admin/admin-api";
import {
  addGuard,
  type Cell,
  NO_TILE_STATE,
  setGateOpen,
  setGuardPattern,
  tileEntries,
  TILE_TOOLS,
  type TileState,
  type TileTool,
} from "@/lib/admin/tile-tools";
import { OutlineAction, SelectField } from "../ui";

/**
 * The tools for the tiles of the later worlds, the unfinished pair or route, and the list of what
 * the board holds. Tiles live on the level's own board, so a level with test boards has none.
 */
export function TileToolbox({
  content,
  tool,
  onTool,
  state,
  onState,
  onChange,
  disabled,
}: {
  content: LevelContent;
  /** The selected tool when it is a tile tool, else null. */
  tool: TileTool | null;
  onTool: (tool: TileTool) => void;
  state: TileState;
  onState: (next: TileState) => void;
  onChange: (next: LevelContent) => void;
  /** The level has test boards. */
  disabled: boolean;
}) {
  const entries = tileEntries(content);
  const hint = TILE_TOOLS.find((t) => t.id === tool)?.hint;
  const finishRoute = (pattern: "back_and_forth" | "loop") => {
    onChange(addGuard(content, state.route as Cell[], pattern));
    onState(NO_TILE_STATE);
  };
  return (
    <div className="mt-8">
      <Caption className="mb-3">Tiles</Caption>
      {disabled ? (
        <p className="text-sm font-semibold text-mute">
          Tiles live on the level's own board. A level with test boards has none: remove the extra
          boards to place them.
        </p>
      ) : (
        <>
          <div role="radiogroup" aria-label="Tile tool" className="flex flex-wrap gap-3">
            {TILE_TOOLS.map((t) => (
              <button
                key={t.id}
                type="button"
                role="radio"
                aria-checked={tool === t.id}
                onClick={() => {
                  onTool(t.id);
                  onState(NO_TILE_STATE);
                }}
                className={`tile inline-flex h-11 items-center px-5 text-[13px] tracking-[2px] uppercase ${
                  tool === t.id ? "bg-ink text-on-ink" : "bg-strip text-ink"
                }`}
                style={{ ["--chamfer" as string]: "10px" }}
              >
                {t.label}
              </button>
            ))}
          </div>
          {hint && <p className="mt-3 text-sm font-semibold text-mute">{hint}</p>}
          {state.pending && (
            <p className="mt-2 text-sm font-semibold">
              First cell placed at ({state.pending[0] + 1}, {state.pending[1] + 1}). Select the
              second.
            </p>
          )}
          {tool === "guard" && state.route.length > 0 && (
            <div className="mt-3 flex flex-wrap items-center gap-3">
              <span className="text-sm font-semibold">
                {state.route.length} cells in the route.
              </span>
              <OutlineAction
                type="button"
                disabled={state.route.length < 2}
                onClick={() => finishRoute("back_and_forth")}
              >
                Finish: back and forth
              </OutlineAction>
              <OutlineAction
                type="button"
                disabled={state.route.length < 4}
                onClick={() => finishRoute("loop")}
              >
                Finish: ring
              </OutlineAction>
              <OutlineAction type="button" onClick={() => onState(NO_TILE_STATE)}>
                Cancel route
              </OutlineAction>
            </div>
          )}
        </>
      )}
      {entries.length > 0 && (
        <ul className="mt-5 grid max-w-[560px] gap-2" aria-label="Tiles on this board">
          {entries.map((entry) => {
            const switchIndex = entry.key.startsWith("switches") ? Number(entry.key.slice(8)) : -1;
            const guardIndex = entry.key.startsWith("guard") ? Number(entry.key.slice(5)) : -1;
            return (
              <li
                key={entry.key}
                className="flex flex-wrap items-center gap-3 border-t-2 border-ink py-2 text-sm font-semibold"
              >
                <span className="flex-1">{entry.label}</span>
                {switchIndex >= 0 && (
                  <label className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      className="h-5 w-5 accent-[var(--ink)]"
                      checked={content.switches?.[switchIndex]?.open === true}
                      onChange={(e) =>
                        onChange(setGateOpen(content, switchIndex, e.target.checked))
                      }
                    />
                    Gate starts open
                  </label>
                )}
                {guardIndex >= 0 && (
                  <SelectField
                    label="Route"
                    id={`ed-guard-${guardIndex}`}
                    value={content.patrols?.[guardIndex]?.pattern ?? "back_and_forth"}
                    onChange={(e) =>
                      onChange(
                        setGuardPattern(
                          content,
                          guardIndex,
                          e.target.value as "back_and_forth" | "loop",
                        ),
                      )
                    }
                  >
                    <option value="back_and_forth">Back and forth</option>
                    <option value="loop">Ring</option>
                  </SelectField>
                )}
                <OutlineAction type="button" onClick={() => onChange(entry.remove)}>
                  Remove
                  <span className="sr-only">{` ${entry.label}`}</span>
                </OutlineAction>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
