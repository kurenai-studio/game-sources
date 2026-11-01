import { readFileSync } from "node:fs";
import { Injectable, Logger, type OnApplicationBootstrap } from "@nestjs/common";
import { AppConfig } from "../../core/config/app-config.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import type { Prisma } from "../../generated/prisma/client.js";
import { DEFAULT_ACHIEVEMENTS } from "../achievements/default-achievements.js";
import { DAILY_POOL } from "./daily-pool.data.js";
import {
  SeedContentError,
  createPublishedLevel,
  prepareLevel,
  type LevelDef,
} from "./seed-level.js";
import { CAMPAIGN } from "./starter-campaign.data.js";

export { buildLevel, readBoard, type LevelDef } from "./seed-level.js";

/** The app version the registry row describes: this package's version, which `make version` keeps current. */
const APP_VERSION: string = (
  JSON.parse(readFileSync(new URL("../../../package.json", import.meta.url), "utf8")) as {
    version: string;
  }
).version;

/** Every level with its place in the campaign, in play order. */
export const LEVELS = CAMPAIGN.worlds.flatMap((world) =>
  world.chapters.flatMap((chapter) =>
    (chapter.levels as readonly LevelDef[]).map((def, orderInChapter) => ({
      def,
      world: { title: world.title, description: world.description },
      chapterTitle: chapter.title,
      orderInChapter,
    })),
  ),
);

/** The levels of the daily challenge pool: published, but not in the campaign. */
export const POOL_LEVELS = DAILY_POOL as readonly LevelDef[];

/**
 * Creates the starter worlds, chapters, and published levels (starter-campaign.data.ts), the daily
 * pool (daily-pool.data.ts), and the default badges, so a fresh install is a complete game.
 * Idempotent: anything that already exists (by slug, title) is left alone. Controlled by
 * SEED_STARTER_CAMPAIGN (default on outside production, off in production).
 */
/**
 * Checks a level (validator, reference solution, solver) and gives the event loop a turn first, so a
 * small instance that spends minutes on the whole campaign still answers its health check.
 */
async function prepareChecked(def: LevelDef): Promise<ReturnType<typeof prepareLevel>> {
  await new Promise<void>((resolve) => setImmediate(resolve));
  return prepareLevel(def);
}

/**
 * Takes the seed lock for the rest of the transaction and says whether the level is already there.
 * A deploy can start a new instance while the old one is still seeding (or restart a crashed one), and
 * two seeds that write the same level at once would collide on its slug or, worse, create a world
 * twice. The lock makes them take turns; the second finds the level and moves on.
 */
async function alreadySeeded(tx: Prisma.TransactionClient, slug: string): Promise<boolean> {
  await tx.$executeRaw`SELECT pg_advisory_xact_lock(${SEED_LOCK})`;
  return (await tx.level.findUnique({ where: { slug }, select: { id: true } })) !== null;
}

const SEED_LOCK = 4_260_117;

/** A level takes a handful of queries; allow a slow, far-away database plenty of time for them. */
const SEED_TRANSACTION = { maxWait: 15_000, timeout: 60_000 } as const;

@Injectable()
export class StarterCampaignSeed implements OnApplicationBootstrap {
  private readonly logger = new Logger(StarterCampaignSeed.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: AppConfig,
  ) {}

  /**
   * In production the seed runs in the background, after the API has started listening: checking a
   * hundred levels takes minutes on a small instance, and a host that sees no open port for that long
   * fails the deploy. Elsewhere the start waits for the seed, so a local database is ready when the
   * API is.
   */
  async onApplicationBootstrap(): Promise<void> {
    if (this.config.seedStarterCampaign === "never") return;
    if (this.config.nodeEnv === "production") {
      void this.run();
      return;
    }
    await this.run();
  }

  private async run(): Promise<void> {
    const mode = this.config.seedStarterCampaign;
    try {
      if (mode === "when-empty" && (await this.prisma.level.count()) > 0) return;
      await this.seed();
    } catch (error) {
      // A seed that cannot finish is reported loudly; the levels it did add stay, and the next start
      // carries on from the missing ones.
      const message = error instanceof Error ? error.message : "failed";
      if (this.config.nodeEnv === "production" || error instanceof SeedContentError) {
        this.logger.error(`Starter campaign seed stopped: ${message}`, (error as Error)?.stack);
        if (this.config.nodeEnv !== "production") throw error;
        return;
      }
      this.logger.warn(`Starter campaign seed skipped: ${message}`);
    }
  }

  private async seed(): Promise<void> {
    await this.seedClientVersion();
    await this.seedAchievements();
    await this.seedCampaign();
    await this.seedPool();
  }

  private async missing<T extends { slug: string }>(wanted: readonly T[]): Promise<T[]> {
    const existing = new Set(
      (
        await this.prisma.level.findMany({
          where: { slug: { in: wanted.map((w) => w.slug) } },
          select: { slug: true },
        })
      ).map((l) => l.slug),
    );
    return wanted.filter((w) => !existing.has(w.slug));
  }

  private async seedCampaign(): Promise<void> {
    const missingSlugs = new Set((await this.missing(LEVELS.map((l) => l.def))).map((d) => d.slug));
    const missing = LEVELS.filter((l) => missingSlugs.has(l.def.slug));
    if (missing.length === 0) return;

    // One transaction per level, not one for the whole campaign: against a database in another region
    // every query costs a round trip, and a single transaction of 100 levels outlives Prisma's
    // 5 second limit. A level and its place go in together or not at all, and a seed that stops
    // half way carries on from the missing levels at the next start.
    const worlds = new Map<string, string>();
    const chapters = new Map<string, string>();
    for (const entry of missing) {
      const item = await prepareChecked(entry.def);
      await this.prisma.$transaction(async (tx) => {
        if (await alreadySeeded(tx, entry.def.slug)) return;
        const worldId = async (title: string, description: string): Promise<string> => {
          const known = worlds.get(title);
          if (known) return known;
          const world =
            (await tx.world.findFirst({ where: { title }, orderBy: { order: "asc" } })) ??
            (await tx.world.create({
              data: {
                title,
                description,
                order: ((await tx.world.aggregate({ _max: { order: true } }))._max.order ?? -1) + 1,
              },
            }));
          worlds.set(title, world.id);
          return world.id;
        };
        const chapterId = async (wid: string, title: string): Promise<string> => {
          const key = `${wid}/${title}`;
          const known = chapters.get(key);
          if (known) return known;
          const chapter =
            (await tx.chapter.findFirst({ where: { worldId: wid, title } })) ??
            (await tx.chapter.create({
              data: {
                title,
                worldId: wid,
                order:
                  ((await tx.chapter.aggregate({ where: { worldId: wid }, _max: { order: true } }))
                    ._max.order ?? -1) + 1,
              },
            }));
          chapters.set(key, chapter.id);
          return chapter.id;
        };
        const wid = await worldId(entry.world.title, entry.world.description);
        const cid = await chapterId(wid, entry.chapterTitle);
        await createPublishedLevel(
          tx,
          item,
          { chapterId: cid, orderInChapter: entry.orderInChapter, dailyPool: false },
          "Recorded by the starter campaign seed.",
        );
      }, SEED_TRANSACTION);
    }
    this.logger.log(
      `Created ${missing.length} starter level(s): ${missing.map((l) => l.def.slug).join(", ")}`,
    );
  }

  /** The daily pool: published levels with no chapter, so players meet them only on their day. */
  private async seedPool(): Promise<void> {
    const missing = await this.missing(POOL_LEVELS);
    if (missing.length === 0) return;
    for (const def of missing) {
      const item = await prepareChecked(def);
      await this.prisma.$transaction(async (tx) => {
        if (await alreadySeeded(tx, def.slug)) return;
        await createPublishedLevel(
          tx,
          item,
          { chapterId: null, orderInChapter: 0, dailyPool: true },
          "Recorded by the daily pool seed.",
        );
      }, SEED_TRANSACTION);
    }
    this.logger.log(`Created ${missing.length} daily pool level(s).`);
  }

  /** The default badges, only on a database that has none: later edits in the dashboard stay. */
  private async seedAchievements(): Promise<void> {
    if ((await this.prisma.achievement.count()) > 0) return;
    await this.prisma.achievement.createMany({
      data: DEFAULT_ACHIEVEMENTS.map((badge, position) => ({
        slug: badge.slug,
        title: badge.title,
        description: badge.description,
        rule: badge.rule as unknown as object,
        position,
      })),
      // Another instance may be seeding at the same moment.
      skipDuplicates: true,
    });
    this.logger.log(`Created ${DEFAULT_ACHIEVEMENTS.length} default badges.`);
  }

  /** The registry row for this app version, supporting the three initial commands. */
  private async seedClientVersion(): Promise<void> {
    if (await this.prisma.clientVersion.findUnique({ where: { version: APP_VERSION } })) return;
    const hasMinimum = await this.prisma.clientVersion.findFirst({ where: { isMinimum: true } });
    try {
      await this.prisma.clientVersion.create({
        data: {
          version: APP_VERSION,
          supportedMechanics: [
            "move",
            "turn",
            "repeat",
            "repeat_until",
            "if",
            "procedures",
            "counter",
            "markers",
            "nested_loops",
            "visit_all",
            "multi_board",
            "start_program",
            "patrol",
            "keys",
            "delivery",
            "switch",
            "teleport",
            "recursion",
            "ice",
            "belts",
          ],
          isMinimum: !hasMinimum,
        },
      });
    } catch (error) {
      // Another instance registered it first.
      if ((error as { code?: string }).code !== "P2002") throw error;
      return;
    }
    this.logger.log(`Registered app version ${APP_VERSION} in the client registry.`);
  }
}
