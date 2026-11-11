import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const REPO_ROOT = path.resolve(__dirname, "..");
const SRC_DIR = path.join(REPO_ROOT, "src");

async function listSrcFiles() {
  const entries = await fs.readdir(SRC_DIR, { withFileTypes: true });
  return entries
    .filter((e) => e.isFile() && e.name.endsWith(".js"))
    .map((e) => e.name)
    .sort((a, b) => a.localeCompare(b));
}

test("src bundle does not leak unexpected globals", async () => {
  const context = vm.createContext({
    cls: () => {},
    print: () => {},
    rect: () => {},
    rectb: () => {},
    line: () => {},
    spr: () => {},
    btn: () => 0,
    btnp: () => 0,
    console
  });

  const before = new Set(Object.keys(context));

  const files = await listSrcFiles();
  assert.ok(files.length > 0, "expected src/*.js files");

  for (const fileName of files) {
    const source = await fs.readFile(path.join(SRC_DIR, fileName), "utf8");
    new vm.Script(source, { filename: `src/${fileName}` }).runInContext(context);
  }

  const after = new Set(Object.keys(context));
  const added = [];
  for (const k of after) {
    if (!before.has(k)) added.push(k);
  }
  added.sort((a, b) => a.localeCompare(b));

  assert.deepEqual(
    added,
    ["MC", "TIC"],
    `unexpected global(s) leaked: ${added.join(", ")}`
  );
});

