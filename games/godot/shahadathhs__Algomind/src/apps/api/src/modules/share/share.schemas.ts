import { z } from "zod";
import { DATE_PATTERN } from "../daily/dates.js";

export const shareBodySchema = z
  .object({
    kind: z.enum(["level", "daily"]),
    levelSlug: z
      .string()
      .min(1)
      .max(64)
      .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/),
    /** The UTC date, for a daily result. */
    date: z.string().regex(DATE_PATTERN).optional(),
  })
  .strict()
  .refine((v) => (v.kind === "daily") === (v.date !== undefined), {
    message: "A daily share needs a date; a level share must not have one",
  });
export type ShareBody = z.infer<typeof shareBodySchema>;

export const codeParamSchema = z.string().regex(/^[a-z0-9]{8}$/);

/**
 * What a share page shows: the level and the result, spoiler-free. No program, no player name, no
 * account id.
 */
export type ShareView = {
  kind: "level" | "daily";
  levelSlug: string;
  title: string;
  difficulty: string;
  date: string | null;
  slots: number;
  steps: number;
  par: number;
};
