import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
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

function stripLineComment(line) {
  const i = line.indexOf("//");
  return i >= 0 ? line.slice(0, i) : line;
}

function hasBitwiseOrZero(code) {
  for (let i = 0; i < code.length; i++) {
    if (code[i] !== "|") continue;
    // Skip logical OR.
    if (code[i + 1] === "|") {
      i += 1;
      continue;
    }
    let j = i + 1;
    while (j < code.length && /\s/.test(code[j])) j += 1;
    if (code[j] !== "0") continue;
    const next = code[j + 1] || "";
    if (/[0-9]/.test(next)) continue;
    return true;
  }
  return false;
}

test("lint: forbid defensive fallbacks in src/ (enforced via tests)", async () => {
  const files = await listSrcFiles();
  assert.ok(files.length > 0, "expected src/*.js files");

  const allowMarker = /lint-allow\(fallback\)/;

  // High-signal patterns we don't want in the cartridge.
  const forbidden = [
    // Shape fallbacks: `x = x || []`, `r.cmds = r.cmds || []`, etc.
    /\|\|\s*\[\s*\]/,
    /\|\|\s*\{/,
    // Shape init via if: `if (!x) x = []/{}`.
    /\bif\s*\(![^)]+\)\s*[^;{]*=\s*\[\s*\]/,
    /\bif\s*\(![^)]+\)\s*[^;{]*=\s*\{/,
  ];

  const violations = [];
  for (const fileName of files) {
    const fullPath = path.join(SRC_DIR, fileName);
    const source = await fs.readFile(fullPath, "utf8");
    const lines = source.split(/\r?\n/);

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (!line) continue;

      // Special-case: `var MC = MC || {};` is the one allowed fallback.
      if (fileName === "00_prelude.js" && /\bvar\s+MC\s*=\s*MC\s*\|\|\s*\{\s*\}\s*;?\s*$/.test(line.trim())) {
        continue;
      }

      if (allowMarker.test(line)) continue;

      const code = stripLineComment(line);
      for (const re of forbidden) {
        if (re.test(code)) {
          violations.push({ fileName, line: i + 1, text: line.trim() });
          break;
        }
      }
    }
  }

  assert.deepEqual(violations, [], `defensive fallbacks found:\n${violations.map((v) => `- ${v.fileName}:${v.line} ${v.text}`).join("\n")}`);
});

test("lint: numeric coercion is localized (|0 / >>>0)", async () => {
  const files = await listSrcFiles();
  assert.ok(files.length > 0, "expected src/*.js files");

  const allowFiles = new Set([
    "15_rng.js",
    "60_render.js",
  ]);

  const allowMarker = /lint-allow\(bitwise-coerce\)/;

  const reU32 = />>>\s*0\b/;
  const reU32Assign = />>>=\s*0\b/;

  const violations = [];
  for (const fileName of files) {
    if (allowFiles.has(fileName)) continue;
    const fullPath = path.join(SRC_DIR, fileName);
    const source = await fs.readFile(fullPath, "utf8");
    const lines = source.split(/\r?\n/);

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (!line) continue;
      if (allowMarker.test(line)) continue;

      const code = stripLineComment(line);
      if (hasBitwiseOrZero(code) || reU32.test(code) || reU32Assign.test(code)) {
        violations.push({ fileName, line: i + 1, text: line.trim() });
      }
    }
  }

  assert.deepEqual(violations, [], `bitwise coercion found outside allowlist:\n${violations.map((v) => `- ${v.fileName}:${v.line} ${v.text}`).join("\n")}`);
});

test("lint: cmd profiles avoid defensive ctx checks", async () => {
  const fileName = "54_cmd_profiles.js";
  const fullPath = path.join(SRC_DIR, fileName);
  const source = await fs.readFile(fullPath, "utf8");
  const lines = source.split(/\r?\n/);

  const allowMarker = /lint-allow\(defensive-ctx\)/;
  const violations = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    if (allowMarker.test(line)) continue;

    const code = stripLineComment(line);
    if (/\bctx\s*&&/.test(code) || /&&\s*ctx\b/.test(code)) {
      violations.push({ fileName, line: i + 1, text: line.trim() });
    }
  }

  assert.deepEqual(violations, [], `defensive ctx checks found:\n${violations.map((v) => `- ${v.fileName}:${v.line} ${v.text}`).join("\n")}`);
});

