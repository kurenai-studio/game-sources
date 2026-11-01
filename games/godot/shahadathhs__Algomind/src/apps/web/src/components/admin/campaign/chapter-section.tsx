"use client";

import { useState } from "react";
import { Caption } from "@/components/ui/caption";
import type { AdminCampaign, LevelSummary } from "@/lib/admin/admin-api";
import { TextAction } from "../text-action";
import { LevelRow } from "./level-row";
import { RenameForm } from "./rename-form";

type Chapter = AdminCampaign["worlds"][number]["chapters"][number];

export function ChapterSection({
  chapter,
  index,
  count,
  choices,
  onMove,
  onMoveLevel,
  onAssign,
  onRename,
  onDelete,
}: {
  chapter: Chapter;
  index: number;
  count: number;
  choices: { id: string; label: string }[];
  onMove: (to: number) => void;
  onMoveLevel: (from: number, to: number) => void;
  onAssign: (level: LevelSummary, chapterId: string) => void;
  onRename: (title: string) => Promise<boolean>;
  onDelete: () => void;
}) {
  const [renaming, setRenaming] = useState(false);
  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <Caption>Chapter {index + 1}</Caption>
          {renaming ? (
            <RenameForm
              kind="chapter"
              id={chapter.id}
              initial={chapter.title}
              onRename={onRename}
              onCancel={() => setRenaming(false)}
            />
          ) : (
            <h3 className="text-xl tracking-[1px] uppercase">{chapter.title}</h3>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-x-4">
          <TextAction
            disabled={index === 0}
            onClick={() => onMove(index - 1)}
            aria-label={`Move chapter ${chapter.title} up`}
          >
            Up
          </TextAction>
          <TextAction
            disabled={index === count - 1}
            onClick={() => onMove(index + 1)}
            aria-label={`Move chapter ${chapter.title} down`}
          >
            Down
          </TextAction>
          <TextAction onClick={() => setRenaming(true)}>Rename</TextAction>
          <TextAction onClick={onDelete} aria-label={`Delete chapter ${chapter.title}`}>
            Delete
          </TextAction>
        </div>
      </div>
      {chapter.levels.length === 0 ? (
        <p className="py-3 text-base font-semibold text-mute">No levels in this chapter.</p>
      ) : (
        <ol className="mt-2 grid">
          {chapter.levels.map((level, li) => (
            <LevelRow
              key={level.id}
              level={level}
              index={li}
              last={li === chapter.levels.length - 1}
              chapterId={chapter.id}
              choices={choices}
              onMove={(to) => onMoveLevel(li, to)}
              onAssign={(id) => onAssign(level, id)}
            />
          ))}
        </ol>
      )}
    </div>
  );
}
