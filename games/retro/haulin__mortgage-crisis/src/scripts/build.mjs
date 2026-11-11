import fs from "node:fs/promises";
import path from "node:path";

const REPO_ROOT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const SRC_DIR = path.join(REPO_ROOT, "src");
const OUT_FILE = path.join(REPO_ROOT, "game.js");

const HEADER_LINES = [
  "// title: Mortgage Crisis",
  "// author: haulin",
  "// desc: A card game inspired by Monopoly Deal",
  "// script: js",
  "// saveid: MortgageCrisis",
  "",
  "// generated: do not edit by hand (edit src/* instead)",
  ""
];

// Some TIC-80 upload pipelines appear to scrape the *last* `// title:` / `// desc:` they see
// in the code body (instead of relying on the proper metadata header).
// Keep a small footer so those scrapers pick the intended cart title/desc, not unrelated `title:`/`desc:` fields.
const FOOTER_LINES = [
  "",
  "// tic80.com metadata fallback (do not remove)",
  "// title: Mortgage Crisis",
  "// author: haulin",
  "// desc: A card game inspired by Monopoly Deal",
  ""
];

function fail(message) {
  // eslint-disable-next-line no-console
  console.error(`build failed: ${message}`);
  process.exit(1);
}

function hasForbiddenModuleSyntax(source) {
  // Keep this strict: even commented-out imports are suspicious in this workflow.
  // We only allow plain scripts that can be concatenated.
  return /^\s*(import|export)\b/m.test(source);
}

function hasForbiddenTicHeaders(source) {
  return /^\s*\/\/\s*(script|title|author|desc|input|saveid)\s*:/im.test(source);
}

function countTicDefinitions(source) {
  // Standardize on `function TIC()` to keep this robust.
  const matches = source.match(/\bfunction\s+TIC\s*\(/g);
  return matches ? matches.length : 0;
}

async function listSrcFiles() {
  let entries;
  try {
    entries = await fs.readdir(SRC_DIR, { withFileTypes: true });
  } catch (err) {
    fail(`missing src directory at ${SRC_DIR}`);
  }

  const files = entries
    .filter((e) => e.isFile() && e.name.endsWith(".js"))
    .map((e) => e.name)
    .sort((a, b) => a.localeCompare(b));

  if (files.length === 0) fail("no src/*.js files found");
  return files;
}

async function main() {
  const files = await listSrcFiles();

  const parts = [];
  parts.push(HEADER_LINES.join("\n"));

  let ticCount = 0;

  for (const fileName of files) {
    const fullPath = path.join(SRC_DIR, fileName);
    const relPath = `src/${fileName}`;
    const source = await fs.readFile(fullPath, "utf8");

    if (hasForbiddenModuleSyntax(source)) {
      fail(`${relPath} contains 'import'/'export' (src must be plain TIC-80 scripts)`);
    }

    if (hasForbiddenTicHeaders(source)) {
      fail(`${relPath} contains TIC-80 headers (put headers only in generated game.js)`);
    }

    ticCount += countTicDefinitions(source);

    parts.push(`// ---- ${relPath} ----\n`);
    parts.push(source.trimEnd() + "\n\n");
  }

  if (ticCount !== 1) {
    fail(`expected exactly 1 'function TIC(', found ${ticCount}`);
  }

  parts.push(FOOTER_LINES.join("\n"));

  const out = parts.join("");
  await fs.writeFile(OUT_FILE, out, "utf8");

  const stat = await fs.stat(OUT_FILE);
  // eslint-disable-next-line no-console
  console.log(`built ${files.length} files -> ${path.relative(REPO_ROOT, OUT_FILE)} (${stat.size} bytes)`);
}

await main();

