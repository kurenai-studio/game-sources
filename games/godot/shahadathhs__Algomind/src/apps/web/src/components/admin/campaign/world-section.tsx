"use client";

import { useState } from "react";
import { Caption } from "@/components/ui/caption";
import type { AdminCampaign, LevelSummary } from "@/lib/admin/admin-api";
import { TextAction } from "../text-action";
import { ChapterSection } from "./chapter-section";
import { NewTitleForm } from "./new-title-form";
import { RenameForm } from "./rename-form";

type World = AdminCampaign["worlds"][number];

export function WorldSection({
  world,
  index,
  count,
  choices,
  onMove,
  onMoveChapter,
  onMoveLevel,
  onAssign,
  onRename,
  onDelete,
  onRenameChapter,
  onDeleteChapter,
  onAddChapter,
}: {
  world: World;
  index: number;
  count: number;
  choices: { id: string; label: string }[];
  onMove: (to: number) => void;
  onMoveChapter: (from: number, to: number) => void;
  onMoveLevel: (ci: number, from: number, to: number) => void;
  onAssign: (level: LevelSummary, chapterId: string) => void;
  onRename: (title: string) => Promise<boolean>;
  onDelete: () => void;
  onRenameChapter: (chapterId: string, title: string) => Promise<boolean>;
  onDeleteChapter: (chapterId: string, title: string) => void;
  onAddChapter: (title: string) => Promise<boolean>;
}) {
  const [renaming, setRenaming] = useState(false);
  return (
    <section aria-label={`World ${world.title}`}>
      <div className="flex flex-wrap items-center justify-between gap-3 border-b-2 border-ink pb-3">
        <div>
          <Caption>World {index + 1}</Caption>
          {renaming ? (
            <RenameForm
              kind="world"
              id={world.id}
              initial={world.title}
              onRename={onRename}
              onCancel={() => setRenaming(false)}
            />
          ) : (
            <h2 className="text-[26px] leading-tight tracking-[1px] uppercase">{world.title}</h2>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-x-4">
          <TextAction
            disabled={index === 0}
            onClick={() => onMove(index - 1)}
            aria-label={`Move ${world.title} up`}
          >
            Up
          </TextAction>
          <TextAction
            disabled={index === count - 1}
            onClick={() => onMove(index + 1)}
            aria-label={`Move ${world.title} down`}
          >
            Down
          </TextAction>
          <TextAction onClick={() => setRenaming(true)}>Rename</TextAction>
          <TextAction onClick={onDelete} aria-label={`Delete world ${world.title}`}>
            Delete
          </TextAction>
        </div>
      </div>

      <div className="mt-6 grid gap-8 pl-0 sm:pl-6">
        {world.chapters.map((chapter, ci) => (
          <ChapterSection
            key={chapter.id}
            chapter={chapter}
            index={ci}
            count={world.chapters.length}
            choices={choices}
            onMove={(to) => onMoveChapter(ci, to)}
            onMoveLevel={(from, to) => onMoveLevel(ci, from, to)}
            onAssign={onAssign}
            onRename={(title) => onRenameChapter(chapter.id, title)}
            onDelete={() => onDeleteChapter(chapter.id, chapter.title)}
          />
        ))}
        <div>
          <NewTitleForm
            openLabel={`Add chapter to ${world.title}`}
            fieldLabel={`Chapter title in ${world.title}`}
            fieldId={`new-chapter-${world.id}`}
            submitLabel="Add chapter"
            onCreate={onAddChapter}
          />
        </div>
      </div>
    </section>
  );
}
