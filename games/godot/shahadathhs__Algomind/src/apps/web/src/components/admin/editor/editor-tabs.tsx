"use client";

import { useRef } from "react";

export const TABS = [
  { id: "details", label: "Details" },
  { id: "board", label: "Board" },
  { id: "limits", label: "Commands and limits" },
  { id: "solution", label: "Solution" },
  { id: "preview", label: "Preview" },
  { id: "playtest", label: "Playtest" },
  { id: "checks", label: "Checks" },
] as const;
export type TabId = (typeof TABS)[number]["id"];

/** The tab strip, with arrow, Home and End keys moving between tabs. */
export function EditorTabs({ tab, onSelect }: { tab: TabId; onSelect: (id: TabId) => void }) {
  const refs = useRef<Record<string, HTMLButtonElement | null>>({});

  function onKey(e: React.KeyboardEvent, index: number) {
    let next = index;
    if (e.key === "ArrowRight") next = (index + 1) % TABS.length;
    else if (e.key === "ArrowLeft") next = (index - 1 + TABS.length) % TABS.length;
    else if (e.key === "Home") next = 0;
    else if (e.key === "End") next = TABS.length - 1;
    else return;
    e.preventDefault();
    const target = TABS[next]!;
    onSelect(target.id);
    refs.current[target.id]?.focus();
  }

  return (
    <div role="tablist" aria-label="Level sections" className="mb-8 flex flex-wrap gap-2">
      {TABS.map((t, i) => (
        <button
          key={t.id}
          ref={(el) => {
            refs.current[t.id] = el;
          }}
          type="button"
          role="tab"
          id={`tab-${t.id}`}
          aria-selected={tab === t.id}
          aria-controls={`panel-${t.id}`}
          tabIndex={tab === t.id ? 0 : -1}
          onClick={() => onSelect(t.id)}
          onKeyDown={(e) => onKey(e, i)}
          className={`tile inline-flex h-11 items-center px-5 text-[13px] tracking-[2px] uppercase ${
            tab === t.id ? "bg-ink text-on-ink" : "bg-strip text-ink"
          }`}
          style={{ ["--chamfer" as string]: "10px" }}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}
