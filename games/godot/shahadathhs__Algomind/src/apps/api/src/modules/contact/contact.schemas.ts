import { z } from "zod";

/** A web address that must be https, or empty (the field is then not shown). */
const link = z
  .string()
  .trim()
  .max(200)
  .refine((value) => value === "" || /^https:\/\/[^\s/]+\.[^\s/]+(\/\S*)?$/.test(value), {
    message: "must be an https address",
  });

const email = z
  .string()
  .trim()
  .max(120)
  .refine((value) => value === "" || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value), {
    message: "must be an email address",
  });

export const contactInputSchema = z
  .object({
    displayName: z.string().trim().min(1).max(80),
    email,
    github: link,
    website: link,
    issues: link,
    note: z.string().trim().max(280),
  })
  .strict();
export type ContactInput = z.infer<typeof contactInputSchema>;

/** What the public contact page reads. */
export type ContactView = ContactInput;

/** What the dashboard reads: the same, with when and by whom it last changed. */
export type AdminContactView = ContactView & { updatedAt: string; updatedByEmail: string | null };
