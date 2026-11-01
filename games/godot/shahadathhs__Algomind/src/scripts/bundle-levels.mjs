#!/usr/bin/env node
// Writes the game's bundled campaign from a running API's published campaign, so the levels
// the game ships with (its first launch without internet) are the same as the published ones.
//
//   node scripts/bundle-levels.mjs [api-base-url]     default: $API_BASE_URL or http://localhost:8000/v1
//
// It reads only the public routes (GET /campaign and GET /levels/:slug) and writes
// apps/game/data/campaign.json and apps/game/data/levels/<slug>.json. World and chapter ids are
// made from their titles, so running it again gives the same files.
import { mkdir, readdir, rm, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { solve } from "../packages/level-contract/dist/index.js";

const base = (process.argv[2] ?? process.env.API_BASE_URL ?? "http://localhost:8000/v1").replace(
  /\/$/,
  "",
);
const slug = (title) =>
  title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
const dataDir = fileURLToPath(new URL("../apps/game/data/", import.meta.url));

async function get(path) {
  const res = await fetch(`${base}${path}`, { headers: { Accept: "application/json" } });
  if (!res.ok) throw new Error(`${path} answered ${res.status}`);
  return res.json();
}

const catalog = await get("/campaign");
if (!Array.isArray(catalog.worlds) || catalog.worlds.length === 0) {
  throw new Error("The API has no published campaign; nothing to bundle.");
}

const worlds = [];
const levels = new Map();
const pars = {};
for (const world of catalog.worlds) {
  const chapters = [];
  for (const chapter of world.chapters) {
    const slugs = [];
    for (const summary of chapter.levels) {
      const detail = await get(`/levels/${encodeURIComponent(summary.slug)}`);
      levels.set(summary.slug, detail.content);
      if (detail.par)
        pars[summary.slug] = { commands: detail.par.commands, steps: detail.par.steps };
      slugs.push(summary.slug);
    }
    chapters.push({ id: slug(chapter.title), title: chapter.title, levels: slugs });
  }
  worlds.push({
    id: slug(world.title),
    title: world.title,
    summary: world.description ?? "",
    chapters,
  });
}

await mkdir(`${dataDir}levels`, { recursive: true });
for (const file of await readdir(`${dataDir}levels`)) {
  if (file.endsWith(".json")) await rm(`${dataDir}levels/${file}`);
}
// The server's par is the one to ship: for a level with test boards or IF and PROC it is the
// reference solution, which this script cannot see. The solver reads one board and searches neither
// IF nor PROC, so it is only a fallback for a level the server gave no par.
for (const [slug, content] of levels) {
  if (pars[slug]) continue;
  const best = solve(content);
  if (best) pars[slug] = { commands: best.commands, steps: best.steps };
}
for (const [slug, content] of levels) {
  await writeFile(`${dataDir}levels/${slug}.json`, `${JSON.stringify(content, null, 2)}\n`);
}
await writeFile(`${dataDir}campaign.json`, `${JSON.stringify({ worlds, par: pars }, null, 2)}\n`);
console.log(`Bundled ${levels.size} levels in ${worlds.length} worlds from ${base}`);
