"use client";

import {
  assignLevel,
  chapterChoices,
  moveChapter,
  moveLevel,
  moveWorld,
} from "@/lib/admin/campaign-tree";
import { Notice, OutlineAction, PrimaryAction } from "./ui";
import { NewTitleForm } from "./campaign/new-title-form";
import { UnassignedSection } from "./campaign/unassigned-section";
import { useCampaignTree } from "./campaign/use-campaign-tree";
import { WorldSection } from "./campaign/world-section";

/** Worlds, chapters, and the order of levels. Reordering is local until Save order. */
export function CampaignManager() {
  const { api, tree, error, notice, dirty, saving, load, run, edit, saveOrder } = useCampaignTree();

  if (error && !tree) {
    return (
      <div className="py-6">
        <Notice>{error}</Notice>
        <div className="mt-4">
          <OutlineAction type="button" onClick={() => void load()}>
            Try again
          </OutlineAction>
        </div>
      </div>
    );
  }
  if (!tree) {
    return (
      <p role="status" className="py-10 text-sm tracking-[2px] uppercase">
        Loading campaign
      </p>
    );
  }

  const choices = chapterChoices(tree);

  return (
    <div>
      <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mb-2 text-xs tracking-[2px] text-mute uppercase">Admin</p>
          <h1 className="text-[34px] leading-tight tracking-[1px] uppercase">Campaign</h1>
        </div>
        <div className="flex flex-wrap items-center gap-4">
          <p role="status" className="text-sm tracking-[2px] uppercase">
            {saving ? "Saving" : dirty ? "Order not saved" : "Saved"}
          </p>
          <PrimaryAction type="button" onClick={() => void saveOrder()} disabled={!dirty || saving}>
            Save order
          </PrimaryAction>
        </div>
      </div>

      {notice && (
        <div className="mb-4">
          <Notice kind="info">{notice}</Notice>
        </div>
      )}
      {error && (
        <div className="mb-4">
          <Notice>{error}</Notice>
        </div>
      )}

      <div className="mb-10">
        <NewTitleForm
          openLabel="Add world"
          fieldLabel="World title"
          fieldId="new-world"
          submitLabel="Add world"
          onCreate={(title) => run(() => api.createWorld({ title }), "World added.")}
        />
      </div>

      {tree.worlds.length === 0 && (
        <p className="py-6 text-base font-semibold text-mute">No worlds yet. Add the first one.</p>
      )}

      <div className="grid gap-12">
        {tree.worlds.map((world, wi) => (
          <WorldSection
            key={world.id}
            world={world}
            index={wi}
            count={tree.worlds.length}
            choices={choices}
            onMove={(to) => edit(moveWorld(tree, wi, to))}
            onMoveChapter={(from, to) => edit(moveChapter(tree, wi, from, to))}
            onMoveLevel={(ci, from, to) => edit(moveLevel(tree, wi, ci, from, to))}
            onAssign={(level, chapterId) => edit(assignLevel(tree, level, chapterId))}
            onRename={(title) => run(() => api.updateWorld(world.id, { title }))}
            onDelete={() => {
              if (window.confirm(`Delete world ${world.title}?`))
                void run(() => api.deleteWorld(world.id), "World deleted.");
            }}
            onRenameChapter={(id, title) => run(() => api.updateChapter(id, { title }))}
            onDeleteChapter={(id, title) => {
              if (window.confirm(`Delete chapter ${title}?`))
                void run(() => api.deleteChapter(id), "Chapter deleted.");
            }}
            onAddChapter={(title) =>
              run(() => api.createChapter({ worldId: world.id, title }), "Chapter added.")
            }
          />
        ))}
      </div>

      <UnassignedSection
        levels={tree.unassigned}
        choices={choices}
        onAssign={(level, chapterId) => edit(assignLevel(tree, level, chapterId))}
      />
    </div>
  );
}
