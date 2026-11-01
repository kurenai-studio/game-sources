// @ts-check
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";
import {
  contrast,
  depthOverrides,
  deriveDepth,
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
} from "../scripts/lib.mjs";

const tokens = loadTokens();
const byName = Object.fromEntries(tokens.map((t) => [t.name, t]));
const HEX = /^#[0-9A-F]{6}$/;

test("every token has a unique kebab-case name and valid colors in both themes", () => {
  const names = tokens.map((t) => t.name);
  assert.equal(new Set(names).size, names.length, "token names must be unique");
  for (const t of tokens) {
    assert.match(t.name, /^[a-z]+(-[a-z]+)*$/, `${t.name} must be kebab-case`);
    assert.match(t.light, HEX, `${t.name} light`);
    assert.match(t.dark, HEX, `${t.name} dark`);
    assert.ok(t.use.length > 0, `${t.name} needs a description`);
  }
});

// Contrast requirements from docs/README_VISUAL_DESIGN.md, section 2.
const pairs = [
  // [foreground, background, minimum ratio, themes checked]
  ["ink", "ground", 7, ["light", "dark"]],
  ["ink", "floor", 7, ["light", "dark"]],
  ["on-ink", "ink", 7, ["light", "dark"]],
  ["on-signal", "signal", 7, ["light", "dark"]],
  ["mute", "ground", 4.5, ["light", "dark"]],
  ["mute", "strip", 4.5, ["light", "dark"]],
  // Yellow is a fill with ink on top; as foreground on the ground it is dark-theme only.
  ["signal", "ground", 4.5, ["dark"]],
];
for (const [fg, bg, min, themes] of pairs) {
  for (const theme of /** @type {("light" | "dark")[]} */ (themes)) {
    test(`contrast ${fg} on ${bg} (${theme}) is at least ${min}`, () => {
      const ratio = contrast(byName[String(fg)][theme], byName[String(bg)][theme]);
      assert.ok(ratio >= Number(min), `${fg}/${bg} ${theme} is ${ratio.toFixed(2)}`);
    });
  }
}

test("signal on the light ground stays out of text use (documented as fill only)", () => {
  const ratio = contrast(byName.signal.light, byName.ground.light);
  assert.ok(ratio < 3, "if this ever passes, update the visual-design doc rule");
});

test("the token table in the visual-design doc matches tokens.json", () => {
  // Only section 2 is the shipped token table; section 14 lists proposed tokens that are not adopted.
  const whole = readFileSync(join(repoRoot, "docs/README_VISUAL_DESIGN.md"), "utf8");
  const start = whole.indexOf("\n## 2. Themes");
  const doc = whole.slice(start, whole.indexOf("\n## 3.", start));
  const rows = [
    ...doc.matchAll(/^\|\s*`([a-z-]+)`\s*\|\s*`(#[0-9A-F]{6})`\s*\|\s*`(#[0-9A-F]{6})`\s*\|/gim),
  ];
  assert.equal(rows.length, tokens.length, "doc table must list every token");
  for (const [, name, light, dark] of rows) {
    assert.ok(byName[name], `doc lists unknown token ${name}`);
    assert.equal(light.toUpperCase(), byName[name].light, `${name} light differs in the doc`);
    assert.equal(dark.toUpperCase(), byName[name].dark, `${name} dark differs in the doc`);
  }
});

test("generated GDScript defines every token and an apply function", () => {
  const gd = generateGdscript(tokens, depth);
  for (const t of tokens) {
    const upper = t.name.toUpperCase().replaceAll("-", "_");
    assert.ok(gd.includes(`static var ${upper}: Color`), `${upper} missing`);
    assert.ok(gd.includes(`"${t.name}": Color("${t.light}")`), `${t.name} light missing`);
    assert.ok(gd.includes(`"${t.name}": Color("${t.dark}")`), `${t.name} dark missing`);
  }
  assert.ok(gd.includes("static func apply(dark: bool, depth: bool = false) -> void:"));
});

test("generated CSS has light, system-dark, and forced-dark blocks", () => {
  const css = generateCss(tokens);
  assert.ok(css.includes(":root {"));
  assert.ok(css.includes("@media (prefers-color-scheme: dark)"));
  assert.ok(css.includes(':root:not([data-theme="light"])'));
  assert.ok(css.includes(':root[data-theme="dark"]'));
  for (const t of tokens) assert.ok(css.includes(`--${t.name}: ${t.light};`), `${t.name} missing`);
});

test("committed generated files are up to date", () => {
  const read = (/** @type {string} */ p) => readFileSync(join(repoRoot, p), "utf8");
  assert.equal(read(outputs.gd), generateGdscript(tokens, depth), "run `pnpm tokens`");
  assert.equal(read(outputs.css), generateCss(tokens), "run `pnpm tokens`");
  assert.equal(read(outputs.ts), generateTypescript(tokens), "run `pnpm tokens`");
});

// ---- the depth look (docs/README_VISUAL_DESIGN.md, section 14) ----
const depth = loadDepthTokens();
const depthAll = [...depth, ...deriveDepth(depth)];
const depthBy = Object.fromEntries(depthAll.map((t) => [t.name, t]));

test("depth tokens have unique names and valid colors, derived shades included", () => {
  const names = depthAll.map((t) => t.name);
  assert.equal(new Set(names).size, names.length, "depth token names must be unique");
  for (const t of depthAll) {
    assert.match(t.name, /^[a-z]+(-[a-z]+)*$/, `${t.name} must be kebab-case`);
    assert.match(t.light, HEX, `${t.name} light`);
    assert.match(t.dark, HEX, `${t.name} dark`);
  }
});

const depthPairs = [
  // [foreground, background, minimum ratio]
  ["ink", "tile", 7],
  ["ink", "ground-top", 7],
  ["ink", "ground-bottom", 7],
  ["ink", "strip", 7],
  ["on-ink", "ink", 7],
  ["on-signal", "signal", 7],
  ["mute", "ground-top", 4.5],
  ["mute", "ground-bottom", 4.5],
  ["mute", "strip", 4.5],
  ["mute", "tile", 4.5],
  ["ink", "floor", 4.5],
  ["wall", "floor", 3],
];
for (const [fg, bg, min] of depthPairs) {
  for (const theme of /** @type {("light" | "dark")[]} */ (["light", "dark"])) {
    test(`depth contrast ${fg} on ${bg} (${theme}) is at least ${min}`, () => {
      const ratio = contrast(depthBy[String(fg)][theme], depthBy[String(bg)][theme]);
      assert.ok(ratio >= Number(min), `${fg}/${bg} ${theme} is ${ratio.toFixed(2)}`);
    });
  }
}

test("the key lip is visibly darker than its face, in both themes", () => {
  for (const theme of /** @type {("light" | "dark")[]} */ (["light", "dark"])) {
    for (const [face, lip] of [
      ["tile", "tile-lip"],
      ["signal", "signal-lip"],
    ]) {
      const ratio = contrast(depthBy[String(face)][theme], depthBy[String(lip)][theme]);
      assert.ok(ratio >= 1.3, `${lip} ${theme} is only ${ratio.toFixed(2)} from ${face}`);
    }
  }
});

test("the depth table in the visual-design doc matches the depth tokens", () => {
  const whole = readFileSync(join(repoRoot, "docs/README_VISUAL_DESIGN.md"), "utf8");
  const doc = whole.slice(whole.indexOf("\n## 14."));
  const rows = [
    ...doc.matchAll(/^\|\s*`([a-z-]+)`\s*\|\s*`(#[0-9A-F]{6})`\s*\|\s*`(#[0-9A-F]{6})`\s*\|/gim),
  ];
  assert.equal(rows.length, depth.length, "section 14 must list every depth token");
  for (const [, name, light, dark] of rows) {
    const t = depth.find((d) => d.name === name);
    assert.ok(t, `doc lists unknown depth token ${name}`);
    assert.equal(light.toUpperCase(), t.light, `${name} light differs in the doc`);
    assert.equal(dark.toUpperCase(), t.dark, `${name} dark differs in the doc`);
  }
});

test("generated depth GDScript defines every depth token, derived ones included", () => {
  const gd = generateDepthGdscript(depth);
  for (const t of depthAll) {
    const upper = t.name.toUpperCase().replaceAll("-", "_");
    assert.ok(gd.includes(`static var ${upper}: Color`), `${upper} missing`);
  }
  assert.ok(gd.includes("static func apply(dark: bool) -> void:"));
});

test("the depth overrides only name tokens the flat palette has, and ground takes the top color", () => {
  const over = depthOverrides(tokens, depth);
  for (const o of over) assert.ok(byName[o.name], `${o.name} is not a flat token`);
  const ground = over.find((o) => o.name === "ground");
  assert.equal(ground?.light, depthBy["ground-top"].light);
  assert.equal(ground?.dark, depthBy["ground-top"].dark);
  assert.ok(
    !over.some((o) => o.name === "ground-top" || o.name === "tile"),
    "depth-only names stay out",
  );
});

test("the generated palette switches to the depth values with apply(dark, true)", () => {
  const gd = generateGdscript(tokens, depth);
  assert.ok(gd.includes("static func apply(dark: bool, depth: bool = false) -> void:"));
  assert.ok(gd.includes("const DEPTH_LIGHT := {"));
  assert.ok(gd.includes("DEPTH_LIGHT, true)"), "the override must replace existing keys");
  assert.ok(
    gd.includes(`"ink": Color("${depthBy.ink.dark}"),`),
    "the depth dark ink is in the file",
  );
});

test("the depth CSS is scoped to .look-depth, overrides shared names, and maps new color names", () => {
  const css = generateDepthCss(tokens, depth);
  assert.ok(css.includes(".look-depth {"), "light block");
  assert.ok(css.includes(':root[data-theme="dark"] .look-depth {'), "forced dark block");
  assert.ok(css.includes(`--ground: ${depthBy["ground-top"].light};`), "ground is the top color");
  assert.ok(css.includes("--tile-lip:"), "derived shades are included");
  assert.ok(css.includes("--color-tile: var(--tile);"), "a depth-only name gets a Tailwind color");
  assert.ok(!css.includes("--color-ink:"), "names the flat theme maps are not mapped twice");
  assert.ok(!css.includes(":root {"), "nothing is applied outside .look-depth");
});

test("committed generated depth CSS is up to date", () => {
  const committed = readFileSync(join(repoRoot, outputs.cssDepth), "utf8");
  assert.equal(committed, generateDepthCss(tokens, depth), "run `pnpm tokens`");
});

test("the depth TypeScript colors carry every depth token and derived shade, and are up to date", () => {
  const ts = generateDepthTypescript(depth);
  for (const t of depthAll) {
    const camel = t.name.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
    assert.ok(ts.includes(`${camel}: "${t.light}"`), `${camel} light missing`);
    assert.ok(ts.includes(`${camel}: "${t.dark}"`), `${camel} dark missing`);
  }
  const committed = readFileSync(join(repoRoot, outputs.tsDepth), "utf8");
  assert.equal(committed, ts, "run `pnpm tokens`");
});
