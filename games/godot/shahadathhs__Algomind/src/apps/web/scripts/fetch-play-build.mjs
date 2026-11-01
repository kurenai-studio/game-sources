// Downloads the game's browser export (algomind-web-*.tar.gz, attached to a GitHub release by
// CI) into public/play-build before `next build`. Optional by design: with no export the /play
// page says the browser version is unavailable. An export already in place (make game-web) is
// kept unless PLAY_BUILD_FORCE is set.
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const target = join(here, "..", "public", "play-build");
const repository = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(process.env.GITHUB_REPOSITORY ?? "")
  ? process.env.GITHUB_REPOSITORY
  : "shahadathhs/Algomind";
const tag = process.env.PLAY_BUILD_TAG || "latest";
const api = (process.env.GITHUB_API_URL || "https://api.github.com").replace(/\/$/, "");

function note(message) {
  console.log(`[play-build] ${message}`);
}

async function main() {
  if (existsSync(join(target, "algomind.wasm")) && !process.env.PLAY_BUILD_FORCE) {
    note("an export is already in public/play-build; keeping it.");
    return;
  }
  const headers = { Accept: "application/vnd.github+json" };
  if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;

  const response = await fetch(`${api}/repos/${repository}/releases/tags/${tag}`, {
    headers,
    signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) throw new Error(`release "${tag}" not readable (HTTP ${response.status})`);
  const release = await response.json();
  const asset = (release.assets ?? []).find((item) =>
    /^algomind-web-.+\.tar\.gz$/.test(item.name ?? ""),
  );
  if (!asset?.browser_download_url) throw new Error(`release "${tag}" has no algomind-web asset`);
  const url = new URL(asset.browser_download_url);
  if (url.protocol !== "https:") throw new Error("the asset URL is not https");

  note(`downloading ${asset.name} (${Math.round(asset.size / 1e6)} MB)`);
  const download = await fetch(url, { signal: AbortSignal.timeout(120000) });
  if (!download.ok) throw new Error(`download failed (HTTP ${download.status})`);
  const work = mkdtempSync(join(tmpdir(), "algomind-play-"));
  try {
    const archive = join(work, "play.tar.gz");
    writeFileSync(archive, Buffer.from(await download.arrayBuffer()));
    rmSync(target, { recursive: true, force: true });
    mkdirSync(target, { recursive: true });
    execFileSync("tar", ["-xzf", archive, "-C", target]);
  } finally {
    rmSync(work, { recursive: true, force: true });
  }
  note("ready in public/play-build.");
}

main().catch((error) => {
  // Never fail the site build over an optional extra.
  note(`skipped: ${error.message}. /play will say the browser version is unavailable.`);
});
