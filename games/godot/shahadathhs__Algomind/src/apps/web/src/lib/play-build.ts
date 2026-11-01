import { existsSync, statSync } from "node:fs";
import { join } from "node:path";

/** Where the game's browser export is served from (apps/web/public/play-build, git-ignored). */
export const PLAY_BUILD_PATH = "/play-build";
const BASE_NAME = "algomind";
const FILES = ["js", "wasm", "pck"] as const;

export type PlayBuild =
  { available: true; executable: string; sizes: Record<string, number> } | { available: false };

/**
 * Whether a browser export of the game was fetched or exported into public/play-build. Read at
 * build time: a site built without the export shows the page's "not available" state and never
 * loads anything.
 */
export function readPlayBuild(directory = join(process.cwd(), "public", "play-build")): PlayBuild {
  const sizes: Record<string, number> = {};
  for (const extension of FILES) {
    const path = join(directory, `${BASE_NAME}.${extension}`);
    if (!existsSync(path)) return { available: false };
    sizes[`${BASE_NAME}.${extension}`] = statSync(path).size;
  }
  return { available: true, executable: `${PLAY_BUILD_PATH}/${BASE_NAME}`, sizes };
}
