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

async function buildCompiledSource() {
  const files = await listSrcFiles();
  assert.ok(files.length > 0, "expected src/*.js files");

  const parts = [];
  for (const fileName of files) {
    const fullPath = path.join(SRC_DIR, fileName);
    const source = await fs.readFile(fullPath, "utf8");
    parts.push(`// ---- src/${fileName} ----\n`);
    parts.push(source.trimEnd() + "\n\n");
  }
  return parts.join("");
}

test("compiled-style bundle loads in one VM script", async () => {
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

  const compiled = await buildCompiledSource();
  new vm.Script(compiled, { filename: "compiled:src_bundle.js" }).runInContext(context);

  assert.equal(typeof context.MC, "object");
  assert.equal(typeof context.MC.mainTick, "function");
  assert.equal(typeof context.TIC, "function");
});

