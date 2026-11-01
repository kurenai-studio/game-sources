import { Injectable, Logger } from "@nestjs/common";
import { notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { asPar } from "../levels/level-views.js";
import type { Par } from "../levels/levels.schemas.js";
import type {
  Campaign,
  CampaignBoards,
  CatalogLevel,
  LevelList,
  PublicLevel,
} from "./catalog.schemas.js";

/** Only levels with a live version AND a chapter reach players. */
const PLAYABLE = {
  status: "PUBLISHED",
  currentPublishedVersionId: { not: null },
  chapterId: { not: null },
} as const;

@Injectable()
export class CatalogService {
  private readonly logger = new Logger(CatalogService.name);

  constructor(private readonly prisma: PrismaService) {}

  private async playable() {
    const rows = await this.prisma.level.findMany({
      where: PLAYABLE,
      include: { chapter: { include: { world: true } }, currentPublishedVersion: true },
    });
    rows.sort(
      (a, b) =>
        a.chapter!.world.order - b.chapter!.world.order ||
        a.chapter!.order - b.chapter!.order ||
        a.orderInChapter - b.orderInChapter ||
        a.slug.localeCompare(b.slug),
    );
    // One row without a usable par (published before the column existed, or edited by hand) must
    // not turn the two endpoints every client depends on into a 500: leave it out and say so.
    const usable = rows.filter((row) => {
      const ok = row.currentPublishedVersion && asPar(row.currentPublishedVersion.par);
      if (!ok) this.logger.error(`Level ${row.slug} is published without a par and was left out.`);
      return Boolean(ok);
    });
    return usable.flatMap((row, index): { row: typeof row; item: CatalogLevel }[] => {
      const version = row.currentPublishedVersion;
      const chapter = row.chapter;
      if (!version || !chapter) return [];
      const content = version.content as Record<string, unknown>;
      const constraints = content.constraints as { maxCommands: number };
      const summary = version.validationSummary as { requiredMechanics?: string[] } | null;
      return [
        {
          row,
          item: {
            id: row.id,
            slug: row.slug,
            title: String(content.title),
            difficulty: content.difficulty as CatalogLevel["difficulty"],
            number: index + 1,
            worldId: chapter.worldId,
            chapterId: chapter.id,
            levelVersion: version.versionNumber,
            schemaVersion: version.schemaVersion,
            par: asPar(version.par) as Par,
            maxCommands: constraints.maxCommands,
            requiredMechanics: summary?.requiredMechanics ?? [],
          },
        },
      ];
    });
  }

  async campaign(): Promise<Campaign> {
    const levels = await this.playable();
    const worlds: Campaign["worlds"] = [];
    for (const { row, item } of levels) {
      const chapter = row.chapter!;
      const world = chapter.world;
      let w = worlds.find((x) => x.id === world.id);
      if (!w) {
        w = {
          id: world.id,
          title: world.title,
          description: world.description,
          order: world.order,
          chapters: [],
        };
        worlds.push(w);
      }
      let c = w.chapters.find((x) => x.id === chapter.id);
      if (!c) {
        c = { id: chapter.id, title: chapter.title, order: chapter.order, levels: [] };
        w.chapters.push(c);
      }
      c.levels.push(item);
    }
    return { worlds };
  }

  /**
   * The boards of every campaign level in one answer, so a page that draws them all (the public levels
   * page) does not need a request for each level. Only the fields that draw a board are sent.
   */
  async boards(): Promise<CampaignBoards> {
    const drawn = [
      "board",
      "initialState",
      "goal",
      "patrols",
      "locks",
      "deliveries",
      "switches",
      "teleports",
      "ice",
      "belts",
    ];
    const items = (await this.playable()).map(({ row }) => {
      const full = row.currentPublishedVersion!.content as Record<string, unknown>;
      const content = Object.fromEntries(drawn.filter((k) => k in full).map((k) => [k, full[k]]));
      const extra = full.extraBoards;
      return { slug: row.slug, boardCount: 1 + (Array.isArray(extra) ? extra.length : 0), content };
    });
    return { items };
  }

  async levels(): Promise<LevelList> {
    return { items: (await this.playable()).map((p) => p.item) };
  }

  async level(slug: string): Promise<{ body: PublicLevel; versionId: string }> {
    // A daily-pool level has no chapter but may be fetched by slug: the game gets its slug from the
    // daily endpoint. The campaign and the level list never include it.
    const row = await this.prisma.level.findFirst({
      where: {
        slug,
        status: "PUBLISHED",
        currentPublishedVersionId: { not: null },
        OR: [{ chapterId: { not: null } }, { dailyPool: true }],
      },
      include: { currentPublishedVersion: true },
    });
    const version = row?.currentPublishedVersion;
    if (!row || !version) throw notFound("The level");
    const par = asPar(version.par);
    if (!par) {
      this.logger.error(`Level ${row.slug} is published without a par; answering 404.`);
      throw notFound("The level");
    }
    const summary = version.validationSummary as { requiredMechanics?: string[] } | null;
    return {
      versionId: version.id,
      body: {
        id: row.id,
        slug: row.slug,
        schemaVersion: version.schemaVersion,
        levelVersion: version.versionNumber,
        par,
        requiredMechanics: summary?.requiredMechanics ?? [],
        publishedAt: version.publishedAt!.toISOString(),
        content: version.content as Record<string, unknown>,
      },
    };
  }
}
