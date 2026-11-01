// @ts-check
// Fails if a color is defined by hand outside the design tokens.
// Rule (AGENTS.md, docs/README_VISUAL_DESIGN.md): colors come only from packages/design-tokens.
// Run: node scripts/check-colors.mjs
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

const SCAN_DIRS = ["apps", "packages"];
const EXTENSIONS = new Set([
  ".gd",
  ".tscn",
  ".tres",
  ".ts",
  ".tsx",
  ".js",
  ".mjs",
  ".css",
  ".html",
]);
const SKIP_DIRS = new Set([
  "node_modules",
  ".next",
  "dist",
  ".godot",
  "build",
  "addons",
  "coverage",
]);

// Files allowed to contain color literals, with the reason.
const ALLOWED = new Map([
  ["packages/design-tokens/tokens.json", "the token source"],
  [
    "packages/design-tokens/scripts/lib.mjs",
    "the generator; it writes Color(...) into the Godot palette",
  ],
  ["packages/design-tokens/test/tokens.test.mjs", "asserts the generator's Color(...) output"],
  ["apps/web/src/app/tokens.css", "generated from the tokens"],
  ["apps/web/src/app/depth-tokens.css", "generated from the depth tokens"],
  ["apps/web/src/lib/depth-colors.generated.ts", "generated from the depth tokens"],
  ["apps/web/src/lib/token-colors.generated.ts", "generated from the tokens"],
  ["apps/game/scripts/generated/palette.gd", "generated from the tokens"],
  ["apps/game/scripts/generated/depth_palette.gd", "generated from the depth tokens"],
  ["apps/game/tests/test_palette.gd", "asserts the generated palette's expected values"],
]);

const HEX = /#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b/;
const FUNCTIONS = /\b(?:Color|rgba?|hsla?|oklch|oklab)\s*\(/;

/** @param {string} dir @returns {string[]} */
function walk(dir) {
  const files = [];
  for (const name of readdirSync(dir)) {
    if (SKIP_DIRS.has(name)) continue;
    const full = join(dir, name);
    if (statSync(full).isDirectory()) files.push(...walk(full));
    else if (EXTENSIONS.has(name.slice(name.lastIndexOf(".")))) files.push(full);
  }
  return files;
}

const offenders = [];
for (const dir of SCAN_DIRS) {
  for (const file of walk(join(root, dir))) {
    const rel = relative(root, file).split(sep).join("/");
    if (ALLOWED.has(rel)) continue;
    readFileSync(file, "utf8")
      .split("\n")
      .forEach((line, i) => {
        if (HEX.test(line) || FUNCTIONS.test(line))
          offenders.push(`${rel}:${i + 1}: ${line.trim()}`);
      });
  }
}

if (offenders.length > 0) {
  console.error("Hand-written colors found. Use design tokens (packages/design-tokens) instead:\n");
  for (const o of offenders) console.error(`  ${o}`);
  process.exit(1);
}
console.log("No hand-written colors outside the design tokens.");
