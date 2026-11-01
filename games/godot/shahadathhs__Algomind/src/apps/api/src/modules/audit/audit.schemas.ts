import { z } from "zod";

export const auditListQuerySchema = z.object({
  action: z
    .enum([
      "LEVEL_PUBLISHED",
      "LEVEL_UNPUBLISHED",
      "LEVEL_ARCHIVED",
      "LEVEL_IMPORTED",
      "LEVEL_RESTORED",
      "CAMPAIGN_REORDERED",
    ])
    .optional()
    .describe("Only events with this action."),
  entityType: z.string().max(40).optional().describe("Only events about this entity type."),
  entityId: z.string().max(64).optional().describe("Only events about this entity."),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(25),
});
export type AuditListQuery = z.infer<typeof auditListQuerySchema>;

export const auditEventSchema = z.object({
  id: z.string(),
  action: z.string(),
  entityType: z.string().describe("level, campaign, ..."),
  entityId: z.string(),
  detail: z.record(z.string(), z.unknown()).nullable(),
  userId: z.string().nullable(),
  userEmail: z.string().nullable(),
  createdAt: z.string().describe("ISO 8601"),
});
export type AuditEventView = z.infer<typeof auditEventSchema>;

export const auditPageSchema = z.object({
  items: z.array(auditEventSchema).describe("Newest first."),
  total: z.number().int(),
  page: z.number().int(),
  pageSize: z.number().int(),
});
export type AuditPage = z.infer<typeof auditPageSchema>;
