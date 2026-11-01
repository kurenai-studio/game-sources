import { Injectable, Logger, type OnModuleInit } from "@nestjs/common";
import { DEFAULT_POINTS_RULES, type PointsRules } from "@algomind/level-contract";
import type { Prisma } from "../../generated/prisma/client.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { pointsRulesSchema, type PointsRulesInput, type RuleSetView } from "./points.schemas.js";

type Row = { version: number; rules: unknown; active: boolean; createdAt: Date };

function toView(row: Row): RuleSetView {
  return {
    version: row.version,
    rules: pointsRulesSchema.parse(row.rules),
    active: row.active,
    createdAt: row.createdAt.toISOString(),
  };
}

/** The versioned scoring rules. One version is active; a change creates the next version. */
@Injectable()
export class PointsRulesService implements OnModuleInit {
  private readonly logger = new Logger(PointsRulesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  /** A fresh database gets rule set 1, the contract's defaults. */
  async onModuleInit(): Promise<void> {
    if ((await this.prisma.pointsRuleSet.count()) > 0) return;
    await this.prisma.pointsRuleSet.create({
      data: {
        version: DEFAULT_POINTS_RULES.version,
        rules: DEFAULT_POINTS_RULES as unknown as Prisma.InputJsonObject,
        active: true,
      },
    });
    this.logger.log("Created points rule set 1 from the defaults.");
  }

  /** The rules scoring uses now. Falls back to the defaults if no row exists. */
  async active(db: Prisma.TransactionClient | PrismaService = this.prisma): Promise<PointsRules> {
    const row = await db.pointsRuleSet.findFirst({
      where: { active: true },
      orderBy: { version: "desc" },
    });
    return row ? pointsRulesSchema.parse(row.rules) : DEFAULT_POINTS_RULES;
  }

  async list(): Promise<{ items: RuleSetView[] }> {
    const rows = await this.prisma.pointsRuleSet.findMany({ orderBy: { version: "desc" } });
    return { items: rows.map(toView) };
  }

  /** Creates the next version and makes it the active one. History is never rewritten. */
  async create(input: PointsRulesInput, userId: string): Promise<RuleSetView> {
    return this.prisma.$transaction(async (tx) => {
      const latest = await tx.pointsRuleSet.aggregate({ _max: { version: true } });
      const version = (latest._max.version ?? 0) + 1;
      await tx.pointsRuleSet.updateMany({ where: { active: true }, data: { active: false } });
      const row = await tx.pointsRuleSet.create({
        data: {
          version,
          rules: { ...input, version } as Prisma.InputJsonObject,
          active: true,
          createdBy: userId,
        },
      });
      await this.audit.record(tx, {
        userId,
        action: "POINTS_RULES_CHANGED",
        entityType: "points-rules",
        entityId: row.id,
        detail: { version },
      });
      return toView(row);
    });
  }
}
