"use client";

import { useCallback, useState } from "react";
import { Caption } from "@/components/ui/caption";
import type { AchievementInput } from "@/lib/admin/social-api";
import { LabelTile, OutlineAction, PageHeading } from "../ui";
import { ResourceMessages } from "../resource-messages";
import { TextAction } from "../text-action";
import { useAdminResource } from "../use-admin-resource";
import { useSocialApi } from "../use-social-api";
import { AchievementForm } from "./achievement-form";

/** Badges: every rule in words, who has earned it, and forms to create or change one. */
export function AchievementsAdmin() {
  const api = useSocialApi();
  const load = useCallback(async () => (await api.listAchievements()).items, [api]);
  const { data, error, notice, busy, run, reload } = useAdminResource(load);
  const [editing, setEditing] = useState<string | null>(null);

  async function create(input: AchievementInput) {
    return run(() => api.createAchievement(input), `Badge ${input.title} created.`);
  }

  return (
    <div>
      <PageHeading caption="Admin" title="Badges" />
      <p className="mb-8 max-w-[640px] text-base font-semibold text-mute">
        A badge is earned when a player&apos;s verified results meet its rule, checked after each
        result they submit. A badge already earned stays earned: changing a rule never takes it
        away. A badge that is off is hidden from players and not awarded until it is switched on.
      </p>
      <ResourceMessages notice={notice} error={error} loading={!data} what="badges" />
      {!data && error && (
        <OutlineAction type="button" onClick={() => void reload()}>
          Try again
        </OutlineAction>
      )}
      {data && (
        <>
          <ul className="mb-12 grid gap-0" aria-label="Badges">
            {data.map((b) => (
              <li key={b.id} className="border-t-2 border-ink py-4">
                <div className="grid gap-x-6 gap-y-2 sm:grid-cols-[1fr_auto]">
                  <div>
                    <p className="flex flex-wrap items-center gap-3 text-lg tracking-[1px] uppercase">
                      {b.title}
                      <LabelTile solid={b.active}>{b.active ? "Active" : "Off"}</LabelTile>
                    </p>
                    <p className="mt-1 text-[15px] font-semibold">{b.description}</p>
                    <p className="mt-1 text-sm font-semibold text-mute">
                      Rule: {b.ruleText}. Earned by {b.earnedBy}{" "}
                      {b.earnedBy === 1 ? "player" : "players"}. Slug {b.slug}, position{" "}
                      {b.position}.
                    </p>
                  </div>
                  <div className="flex flex-wrap items-start gap-x-5">
                    <TextAction
                      disabled={busy}
                      onClick={() =>
                        void run(
                          () => api.updateAchievement(b.id, { active: !b.active }),
                          `${b.title} is ${b.active ? "off" : "on"}.`,
                        )
                      }
                    >
                      {b.active ? "Switch off" : "Switch on"}
                    </TextAction>
                    <TextAction
                      disabled={busy}
                      onClick={() => setEditing(editing === b.id ? null : b.id)}
                    >
                      {editing === b.id ? "Close" : "Edit"}
                    </TextAction>
                  </div>
                </div>
                {editing === b.id && (
                  <div className="mt-4">
                    <AchievementForm
                      badge={b}
                      busy={busy}
                      onCancel={() => setEditing(null)}
                      onSubmit={async (input) => {
                        const { slug: _slug, ...patch } = input;
                        const ok = await run(
                          () => api.updateAchievement(b.id, patch),
                          `${input.title} saved.`,
                        );
                        if (ok) setEditing(null);
                        return ok;
                      }}
                    />
                  </div>
                )}
              </li>
            ))}
          </ul>
          <Caption as="h2" className="mb-4">
            New badge
          </Caption>
          <AchievementForm badge={null} busy={busy} onCancel={() => undefined} onSubmit={create} />
        </>
      )}
    </div>
  );
}
