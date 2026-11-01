#!/usr/bin/env node
// Level lab: find, measure, and look at candidate levels. Everything is deterministic for a seed.
//
//   node scripts/level-lab/cli.mjs families
//   node scripts/level-lab/cli.mjs search <family|world:N|all> [--count 6] [--seed 1] [--tries 8000]
//   node scripts/level-lab/cli.mjs check <levels.json>
//
// Outputs go to scripts/level-lab/out/ (git-ignored): <name>.json and <name>-light.svg / -dark.svg.
// Build the contract first: pnpm --filter @algomind/level-contract build
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  programSlots,
  simulate,
  solve,
  validateLevel,
} from "../../packages/level-contract/dist/index.js";
import { levelFromRows } from "./board.mjs";
import { FAMILIES } from "./families.mjs";
import { measure } from "./metrics.mjs";
import { sheetSvg } from "./render.mjs";
import { search } from "./search.mjs";

const out = fileURLToPath(new URL("./out/", import.meta.url));
const args = process.argv.slice(2);
const command = args[0];
const flag = (name, fallback) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? Number(args[i + 1]) : fallback;
};

function describe(m) {
  return [
    m.loops
      ? `par ${m.par} slots, ${m.flatPar} without loops`
      : `par ${m.par} (${m.moves} moves, ${m.turns} turns)`,
    `walls cost ${m.excess}, decoy ${m.decoy}, dead ends ${m.deadEnds}`,
    `${m.optimalPrograms} shortest program${m.optimalPrograms === 1 ? "" : "s"}, ${m.size}`,
  ];
}

function write(name, entries, title) {
  mkdirSync(out, { recursive: true });
  writeFileSync(`${out}${name}.json`, `${JSON.stringify(entries, null, 2)}\n`);
  const sheet = entries.map((e, i) => ({
    label: `${e.family ?? e.slug ?? ""} #${i + 1}`.toUpperCase(),
    title: e.title ?? `Candidate ${i + 1}`,
    rows: e.rows,
    caption: [
      ...describe(e.metrics),
      e.commands.map((c) => c.split("_")[0].toLowerCase()).join(" "),
    ],
  }));
  for (const theme of ["light", "dark"]) {
    writeFileSync(`${out}${name}-${theme}.svg`, sheetSvg(sheet, { title, theme }));
  }
  console.log(`Wrote ${out}${name}.json and ${name}-light.svg, ${name}-dark.svg`);
}

if (command === "families") {
  for (const [name, f] of Object.entries(FAMILIES)) {
    console.log(`${name.padEnd(16)} world ${f.world}  ${f.chapter.padEnd(8)} ${f.idea}`);
  }
} else if (command === "search") {
  const target = args[1];
  const names =
    target === "all"
      ? Object.keys(FAMILIES)
      : target?.startsWith("world:")
        ? Object.keys(FAMILIES).filter((n) => FAMILIES[n].world === Number(target.slice(6)))
        : [target];
  const entries = [];
  for (const name of names) {
    const { found, candidates } = search(name, {
      count: flag("count", 6),
      seed: flag("seed", 1),
      tries: flag("tries", undefined),
    });
    console.log(`${name}: ${found} distinct candidates, showing ${candidates.length}`);
    entries.push(...candidates);
  }
  write(target.replace(":", "-"), entries, `Level lab: ${target}`);
} else if (command === "check") {
  const defs = JSON.parse(readFileSync(args[1], "utf8"));
  let problems = 0;
  const parsByChapter = new Map();
  for (const def of defs) {
    const level = levelFromRows(def.rows, def);
    const valid = validateLevel(level);
    if (def.solution) {
      // A level with an IF has no exact par: the reference solution is par, and the best program
      // without IF must not fit the limit.
      const issues = [];
      if (!valid.ok)
        issues.push(`invalid: ${valid.issues.map((i) => `${i.path} ${i.code}`).join(", ")}`);
      else {
        const run = simulate(level, def.solution);
        const slots = programSlots(def.solution);
        const plain = solve({
          ...level,
          availableCommands: level.availableCommands.filter((c) => c !== "IF" && c !== "PROC"),
        });
        if (run.status !== "SUCCEEDED") issues.push(`the solution fails: ${run.reason}`);
        if (slots !== def.maxCommands)
          issues.push(`limit ${def.maxCommands} is not the solution's ${slots} slots`);
        if (
          plain &&
          plain.commands < (level.availableCommands.includes("PROC") ? 1.3 : 1.5) * def.maxCommands
        )
          issues.push(
            `a program without IF or PROC of ${plain.commands} slots is too close to the limit ${def.maxCommands}`,
          );
        if (run.steps * 2 > level.constraints.maxSteps)
          issues.push(
            `maxSteps ${level.constraints.maxSteps} is under twice the ${run.steps} steps of the solution`,
          );
        console.log(
          `${def.slug.padEnd(22)} solution ${slots} slots, ${run.steps} steps; without IF ${plain ? plain.commands : "none"}${issues.length ? `\n   PROBLEM: ${issues.join("; ")}` : ""}`,
        );
      }
      problems += issues.length;
      continue;
    }
    const m = valid.ok ? measure(level) : null;
    const issues = [];
    if (!valid.ok)
      issues.push(`invalid: ${valid.issues.map((i) => `${i.path} ${i.code}`).join(", ")}`);
    else if (!m) issues.push("the goal cannot be reached");
    else {
      if (def.maxCommands < m.par) issues.push(`limit ${def.maxCommands} is below par ${m.par}`);
      if (def.maxCommands > m.par + 4)
        issues.push(`limit ${def.maxCommands} is far above par ${m.par}`);
      // Set rules: what makes this level different from the others, and a limit that matters.
      const group = def.chapter ?? "";
      const earlier = parsByChapter.get(group) ?? new Map();
      if (earlier.has(m.par))
        issues.push(`par ${m.par} equals the par of ${earlier.get(m.par)} in the same chapter`);
      earlier.set(m.par, def.slug);
      parsByChapter.set(group, earlier);
      if (m.loops && m.flatPar !== null && m.flatPar <= def.maxCommands)
        issues.push(
          `a plain program of ${m.flatPar} fits the limit ${def.maxCommands}: no loop needed`,
        );
      if (def.budget && def.maxCommands > m.par)
        issues.push(
          `budget level with limit ${def.maxCommands} above par ${m.par}: slack lets a worse program pass`,
        );
    }
    problems += issues.length;
    console.log(
      `${def.slug.padEnd(22)} ${m ? describe(m).join("; ") : ""} ${issues.length ? `\n   PROBLEM: ${issues.join("; ")}` : ""}`,
    );
  }
  process.exitCode = problems ? 1 : 0;
} else {
  console.log(
    "Usage: cli.mjs families | search <family|world:N|all> [--count N --seed N --tries N] | check <file>",
  );
}
