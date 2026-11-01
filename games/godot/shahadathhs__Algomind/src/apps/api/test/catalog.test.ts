import { describe, expect, it } from "vitest";
import { CatalogService } from "../src/modules/catalog/catalog.service.js";
import { level } from "./support/level.js";

/** A published level row as the catalog reads it; `par` null models a row with no par. */
function row(slug: string, par: unknown) {
  return {
    id: `id-${slug}`,
    slug,
    orderInChapter: 0,
    chapter: {
      id: "c1",
      title: "Chapter",
      order: 0,
      worldId: "w1",
      world: { id: "w1", title: "World", description: "", order: 0 },
    },
    currentPublishedVersion: {
      id: `v-${slug}`,
      versionNumber: 1,
      schemaVersion: 1,
      par,
      content: { ...level({ slug }), title: slug },
      validationSummary: { requiredMechanics: ["move"] },
      publishedAt: new Date("2026-01-01T00:00:00Z"),
    },
  };
}

function service(rows: unknown[]) {
  const prisma = {
    level: { findMany: async () => rows, findFirst: async () => rows[0] ?? null },
  };
  return new CatalogService(prisma as never);
}

describe("public catalog", () => {
  it("lists levels in order with their par", async () => {
    const { items } = await service([
      row("a", { commands: 3, steps: 3 }),
      row("b", { commands: 4, steps: 4 }),
    ]).levels();
    expect(items.map((i) => [i.slug, i.number, i.par.commands])).toEqual([
      ["a", 1, 3],
      ["b", 2, 4],
    ]);
  });

  it("leaves out a level published without a par instead of failing the whole catalog", async () => {
    const catalog = service([row("a", { commands: 3, steps: 3 }), row("broken", null)]);
    const { items } = await catalog.levels();
    expect(items.map((i) => i.slug)).toEqual(["a"]);
    const tree = await catalog.campaign();
    expect(tree.worlds[0]?.chapters[0]?.levels).toHaveLength(1);
  });

  it("gives the boards of every level in one answer, only what draws them", async () => {
    const withExtra = row("b", { commands: 4, steps: 4 });
    (withExtra.currentPublishedVersion.content as Record<string, unknown>).extraBoards = [
      { board: {}, initialState: {}, goal: {} },
    ];
    const { items } = await service([row("a", { commands: 3, steps: 3 }), withExtra]).boards();
    expect(items.map((i) => [i.slug, i.boardCount])).toEqual([
      ["a", 1],
      ["b", 2],
    ]);
    const keys = Object.keys(items[0]!.content);
    expect(keys).toEqual(expect.arrayContaining(["board", "initialState", "goal"]));
    expect(keys).not.toContain("hints");
    expect(keys).not.toContain("availableCommands");
  });

  it("numbers the remaining levels without gaps", async () => {
    const { items } = await service([
      row("broken", null),
      row("b", { commands: 4, steps: 4 }),
    ]).levels();
    expect(items.map((i) => i.number)).toEqual([1]);
  });

  it("answers 404 for a single level that has no par", async () => {
    await expect(service([row("broken", null)]).level("broken")).rejects.toMatchObject({
      status: 404,
    });
  });
});
