"use client";

import type { Difficulty } from "@/lib/admin/admin-api";
import { Field, OutlineAction, SelectField } from "../ui";
import { TextAction } from "../text-action";
import type { ContentProps } from "./content-props";

export function DetailsPanel({ content, onChange, slug }: ContentProps & { slug: string }) {
  const hints = content.hints;
  return (
    <div className="grid max-w-[640px] gap-6">
      <Field
        label="Title"
        id="ed-title"
        value={content.title}
        maxLength={60}
        onChange={(e) => onChange({ ...content, title: e.target.value })}
      />
      <Field
        label="Slug"
        id="ed-slug"
        value={slug}
        readOnly
        hint="Fixed once the level is published."
      />
      <div>
        <label
          htmlFor="ed-description"
          className="mb-2 block text-xs tracking-[2px] text-mute uppercase"
        >
          Description
        </label>
        <span className="tile block bg-ink p-[2px]" style={{ ["--chamfer" as string]: "12px" }}>
          <textarea
            id="ed-description"
            rows={3}
            maxLength={280}
            value={content.description}
            onChange={(e) => onChange({ ...content, description: e.target.value })}
            className="block w-full bg-floor px-4 py-3 text-base text-ink focus-visible:outline-offset-[-7px]"
          />
        </span>
      </div>
      <SelectField
        label="Difficulty"
        id="ed-difficulty"
        value={content.difficulty}
        onChange={(e) => onChange({ ...content, difficulty: e.target.value as Difficulty })}
      >
        <option value="easy">Easy</option>
        <option value="medium">Medium</option>
        <option value="hard">Hard</option>
      </SelectField>
      <fieldset>
        <legend className="mb-2 text-xs tracking-[2px] text-mute uppercase">
          Hints ({hints.length} of 5)
        </legend>
        <ul className="grid gap-3">
          {hints.map((hint, i) => (
            <li key={i} className="flex items-end gap-3">
              <div className="grow">
                <Field
                  label={`Hint ${i + 1}`}
                  id={`ed-hint-${i}`}
                  value={hint}
                  maxLength={140}
                  onChange={(e) =>
                    onChange({
                      ...content,
                      hints: hints.map((h, j) => (j === i ? e.target.value : h)),
                    })
                  }
                />
              </div>
              <TextAction
                onClick={() => onChange({ ...content, hints: hints.filter((_, j) => j !== i) })}
              >
                Remove
              </TextAction>
            </li>
          ))}
        </ul>
        {hints.length < 5 && (
          <div className="mt-3">
            <OutlineAction
              type="button"
              onClick={() => onChange({ ...content, hints: [...hints, ""] })}
            >
              Add hint
            </OutlineAction>
          </div>
        )}
      </fieldset>
    </div>
  );
}
