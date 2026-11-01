// @ts-check
// Generates the Godot palette and the web CSS from tokens.json.
//   node scripts/build.mjs           write the generated files
//   node scripts/build.mjs --check   fail if they differ from what is committed
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import {
  generateCss,
  generateDepthCss,
  generateDepthGdscript,
  generateDepthTypescript,
  generateGdscript,
  generateTypescript,
  loadDepthTokens,
  loadTokens,
  outputs,
  repoRoot,
} from "./lib.mjs";

const tokens = loadTokens();
const files = [
  { path: outputs.gd, content: generateGdscript(tokens, loadDepthTokens()) },
  { path: outputs.css, content: generateCss(tokens) },
  { path: outputs.ts, content: generateTypescript(tokens) },
  { path: outputs.gdDepth, content: generateDepthGdscript(loadDepthTokens()) },
  { path: outputs.cssDepth, content: generateDepthCss(tokens, loadDepthTokens()) },
  { path: outputs.tsDepth, content: generateDepthTypescript(loadDepthTokens()) },
];

const checkOnly = process.argv.includes("--check");
const stale = [];

for (const { path, content } of files) {
  const abs = join(repoRoot, path);
  if (checkOnly) {
    const current = existsSync(abs) ? readFileSync(abs, "utf8") : null;
    if (current !== content) stale.push(path);
    continue;
  }
  mkdirSync(dirname(abs), { recursive: true });
  writeFileSync(abs, content);
  console.log(`wrote ${path}`);
}

if (checkOnly) {
  if (stale.length > 0) {
    console.error(
      "Generated token files are out of date. Run `pnpm tokens` and commit the result:",
    );
    for (const path of stale) console.error(`  ${path}`);
    process.exit(1);
  }
  console.log("Generated token files are up to date.");
}
