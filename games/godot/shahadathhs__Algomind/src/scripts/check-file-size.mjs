// @ts-check
// Fails if a hand-written source file is over the hard ceiling; lists files over the soft limit.
// Rule (AGENTS.md, docs/README_CODE_STANDARDS.md): 300 lines soft, 450 lines hard.
// Run: node scripts/check-file-size.mjs
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

const SOFT = 300;
const HARD = 450;
const SCAN_DIRS = ["apps/web/src", "apps/api/src", "apps/game/scripts", "packages"];
const EXTENSIONS = new Set([".ts", ".tsx", ".gd"]);
const SKIP_DIRS = new Set([
  "node_modules",
  ".next",
  "dist",
  ".godot",
  "build",
  "addons",
  "generated",
  "test",
  "tests",
]);

// Files allowed over the ceiling, with the reason (docs/README_CODE_STANDARDS.md, section 8).
const EXEMPT = new Map([
  ["apps/api/src/modules/seed/starter-campaign.data.ts", "pure data, one entry per level"],
  ["apps/api/src/modules/seed/daily-pool.data.ts", "pure data, one entry per level"],
  ["apps/game/scripts/contract/level_validator.gd", "contract mirror of validate.ts"],
  ["packages/level-contract/src/validate.ts", "contract mirror of level_validator.gd"],
]);

/** @param {string} dir @returns {string[]} */
function walk(dir) {
  const files = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) files.push(...walk(join(dir, entry.name)));
    } else if (EXTENSIONS.has(entry.name.slice(entry.name.lastIndexOf(".")))) {
      files.push(join(dir, entry.name));
    }
  }
  return files;
}

const failures = [];
const soft = [];
for (const dir of SCAN_DIRS) {
  for (const file of walk(join(root, dir))) {
    const path = relative(root, file).split(sep).join("/");
    if (path.endsWith(".d.ts") || EXEMPT.has(path)) continue;
    const lines = readFileSync(file, "utf8").split("\n").length - 1;
    if (lines > HARD) failures.push(`${path}: ${lines} lines (limit ${HARD})`);
    else if (lines > SOFT) soft.push(`${path}: ${lines}`);
  }
}

if (soft.length > 0) {
  console.log(`Over the soft limit of ${SOFT} lines (split the part you touch):`);
  for (const line of soft) console.log(`  ${line}`);
}
if (failures.length > 0) {
  console.error(`Files over the hard ceiling:\n  ${failures.join("\n  ")}`);
  process.exit(1);
}
console.log(`File sizes ok (ceiling ${HARD}).`);
