import { MECHANIC_PATTERN } from "@algomind/level-contract";
import { z } from "zod";

const mechanic = z
  .string()
  .min(1)
  .max(32)
  .regex(new RegExp(MECHANIC_PATTERN), "lowercase letters, digits, and underscores");
const mechanics = z
  .array(mechanic)
  .max(32)
  .refine((list) => new Set(list).size === list.length, "must not repeat a mechanic");

export const createClientVersionSchema = z.object({
  version: z
    .string()
    .regex(/^\d{1,4}\.\d{1,4}\.\d{1,4}(-[0-9A-Za-z.-]{1,32})?$/, "a version such as 0.1.0")
    .describe("The app version, for example 0.1.0."),
  supportedMechanics: mechanics.describe("Mechanic names this version can play, e.g. move, turn."),
  isMinimum: z
    .boolean()
    .default(false)
    .describe("Make this the minimum supported version (clears the flag elsewhere)."),
  releasedAt: z.iso.datetime().optional().describe("Defaults to now."),
});
export type CreateClientVersion = z.infer<typeof createClientVersionSchema>;

export const updateClientVersionSchema = z
  .object({
    supportedMechanics: mechanics.optional(),
    isMinimum: z
      .literal(true)
      .optional()
      .describe("Only true is accepted: mark another version as minimum to move the flag."),
    releasedAt: z.iso.datetime().optional(),
  })
  .refine((v) => Object.keys(v).length > 0, "send at least one field");
export type UpdateClientVersion = z.infer<typeof updateClientVersionSchema>;

export const clientVersionSchema = z.object({
  id: z.string(),
  version: z.string(),
  supportedMechanics: z.array(z.string()),
  isMinimum: z.boolean(),
  releasedAt: z.string().describe("ISO 8601"),
  createdAt: z.string(),
  updatedAt: z.string(),
});
export type ClientVersionView = z.infer<typeof clientVersionSchema>;

export const clientVersionListSchema = z.object({
  items: z.array(clientVersionSchema).describe("Newest release first."),
});
