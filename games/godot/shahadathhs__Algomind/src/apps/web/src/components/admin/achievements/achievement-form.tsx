"use client";

import { useState, type FormEvent } from "react";
import {
  draftFromRule,
  RULE_TYPES,
  ruleFromDraft,
  type RuleDraft,
} from "@/lib/admin/achievement-rule";
import type { AchievementInput, AdminAchievement } from "@/lib/admin/social-api";
import { Field, Notice, OutlineAction, PrimaryAction, SelectField } from "../ui";

/** Create a badge, or edit one (the slug is fixed once created). */
export function AchievementForm({
  badge,
  busy,
  onSubmit,
  onCancel,
}: {
  badge: AdminAchievement | null;
  busy: boolean;
  onSubmit: (input: AchievementInput) => Promise<boolean>;
  onCancel: () => void;
}) {
  const [slug, setSlug] = useState(badge?.slug ?? "");
  const [title, setTitle] = useState(badge?.title ?? "");
  const [description, setDescription] = useState(badge?.description ?? "");
  const [position, setPosition] = useState(String(badge?.position ?? 0));
  const [active, setActive] = useState(badge?.active ?? true);
  const [rule, setRule] = useState<RuleDraft>(
    badge ? draftFromRule(badge.rule) : { type: "levels_solved", value: "5", slug: "" },
  );
  const [problem, setProblem] = useState<string | null>(null);
  const unit = RULE_TYPES.find((r) => r.type === rule.type)?.unit ?? "";
  const idp = badge ? `badge-${badge.id}` : "badge-new";

  async function submit(e: FormEvent) {
    e.preventDefault();
    const parsed = ruleFromDraft(rule);
    if (typeof parsed === "string") return setProblem(parsed);
    const pos = Number(position);
    if (!Number.isInteger(pos) || pos < 0)
      return setProblem("Position is a whole number, 0 or more.");
    setProblem(null);
    await onSubmit({
      slug: slug.trim(),
      title: title.trim(),
      description: description.trim(),
      rule: parsed,
      active,
      position: pos,
    });
  }

  return (
    <form
      onSubmit={(e) => void submit(e)}
      aria-label={badge ? `Edit ${badge.title}` : "New badge"}
      className="grid max-w-[560px] gap-4"
    >
      {!badge && (
        <Field
          label="Slug"
          id={`${idp}-slug`}
          value={slug}
          onChange={(e) => setSlug(e.target.value)}
          hint="Lowercase words joined by hyphens. It cannot change later."
          required
          maxLength={48}
        />
      )}
      <Field
        label="Title"
        id={`${idp}-title`}
        value={title}
        maxLength={40}
        required
        onChange={(e) => setTitle(e.target.value)}
      />
      <Field
        label="Description"
        id={`${idp}-description`}
        value={description}
        maxLength={140}
        required
        onChange={(e) => setDescription(e.target.value)}
      />
      <SelectField
        label="Rule"
        id={`${idp}-rule`}
        value={rule.type}
        onChange={(e) => setRule({ ...rule, type: e.target.value as RuleDraft["type"] })}
      >
        {RULE_TYPES.map((r) => (
          <option key={r.type} value={r.type}>
            {r.label}
          </option>
        ))}
      </SelectField>
      {rule.type === "level_solved" ? (
        <Field
          label="Level slug"
          id={`${idp}-level`}
          value={rule.slug}
          onChange={(e) => setRule({ ...rule, slug: e.target.value })}
          hint="Earned the first time a player solves this level."
        />
      ) : (
        <Field
          label={`How many ${unit}`}
          id={`${idp}-value`}
          type="number"
          min={1}
          value={rule.value}
          onChange={(e) => setRule({ ...rule, value: e.target.value })}
        />
      )}
      <Field
        label="Position"
        id={`${idp}-position`}
        type="number"
        min={0}
        value={position}
        onChange={(e) => setPosition(e.target.value)}
        hint="Badges are listed from the lowest position."
      />
      <label className="flex min-h-11 items-center gap-3 text-base font-semibold">
        <input
          type="checkbox"
          className="h-5 w-5 accent-[var(--ink)]"
          checked={active}
          onChange={(e) => setActive(e.target.checked)}
        />
        Active (players can earn it)
      </label>
      {problem && <Notice>{problem}</Notice>}
      <div className="flex flex-wrap gap-3">
        {badge ? (
          <OutlineAction type="submit" disabled={busy}>
            Save badge
          </OutlineAction>
        ) : (
          <PrimaryAction type="submit" disabled={busy}>
            Create badge
          </PrimaryAction>
        )}
        {badge && (
          <OutlineAction type="button" onClick={onCancel}>
            Cancel
          </OutlineAction>
        )}
      </div>
    </form>
  );
}
