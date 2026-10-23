import { readFile } from "node:fs/promises";
import {
  FIELD_HEIGHT,
  FIELD_WIDTH,
  HAZARD_COUNT,
  SHOT_LIMIT,
  STAR_COUNT,
  applySling,
  createDailyField,
  formatShareResult,
  gradeFor,
  initialRunState,
  plannedTargets,
  simulatePlan,
  startRun
} from "../src/core.js";

const requiredFiles = [
  "index.html",
  "src/styles.css",
  "src/app.js",
  "src/core.js",
  "README.md",
  "LICENSE",
  "docs/preview.svg"
];

for (const file of requiredFiles) {
  const text = await readFile(new URL(`../${file}`, import.meta.url), "utf8");
  if (!text.trim()) throw new Error(`${file} is empty`);
}

const html = await readFile(new URL("../index.html", import.meta.url), "utf8");
const app = await readFile(new URL("../src/app.js", import.meta.url), "utf8");
const css = await readFile(new URL("../src/styles.css", import.meta.url), "utf8");
const readme = await readFile(new URL("../README.md", import.meta.url), "utf8");

if (!html.includes("Star Sling")) throw new Error("index.html must name the game");
if (!html.includes('id="field"')) throw new Error("index.html must expose the canvas");
if (!html.includes('id="challenge-date"')) throw new Error("index.html must expose a date picker");
if (!app.includes("window.StarSling")) throw new Error("app.js must expose a browser smoke hook");
if (!app.includes("solveToday")) throw new Error("app.js must expose deterministic solve hook");
if (!app.includes("getChallengeLink")) throw new Error("app.js must expose challenge links");
if (!css.includes("@media (max-width: 430px)")) throw new Error("styles.css must include narrow mobile layout");
if (css.includes("font-size: clamp")) throw new Error("styles.css must not scale type with viewport width");
if (!readme.includes("Why it may be worth starring")) throw new Error("README must include star-oriented positioning");
if (!readme.includes("Inspiration sources")) throw new Error("README must cite public inspiration sources");
if (!readme.includes("How to run")) throw new Error("README must explain local running");

for (const dateKey of ["2026-06-04", "2026-06-05", "2026-12-31"]) {
  const field = createDailyField(dateKey);
  assertField(dateKey, field);

  const again = createDailyField(dateKey);
  if (JSON.stringify(field.stars) !== JSON.stringify(again.stars)) {
    throw new Error(`${dateKey} stars are not deterministic`);
  }

  const solved = simulatePlan(field, plannedTargets(field));
  if (!solved.docked) throw new Error(`${dateKey} planned run did not dock`);
  if (solved.collected.size !== STAR_COUNT) throw new Error(`${dateKey} planned run missed stars`);
  if (solved.heat !== 0) throw new Error(`${dateKey} planned run hit a hazard`);
  if (solved.shots.length > SHOT_LIMIT) throw new Error(`${dateKey} planned run used too many shots`);
  if (gradeFor(solved.score, field.possibleScore) !== "S") {
    throw new Error(`${dateKey} planned run should grade S`);
  }

  let failed = startRun(field);
  failed = applySling(field, failed, { x: -500, y: -500 });
  if (failed.docked) throw new Error(`${dateKey} bad sling should not dock`);
  if (failed.score >= solved.score) throw new Error(`${dateKey} bad sling scored too high`);

  const idle = initialRunState(field);
  const unchanged = applySling(field, idle, { x: 200, y: 0 });
  if (unchanged.shots.length !== 0) throw new Error(`${dateKey} idle run accepted a shot`);
}

const field = createDailyField("2026-06-04");
const solved = simulatePlan(field, plannedTargets(field));
const share = formatShareResult({
  dateKey: field.dateKey,
  score: solved.score,
  possibleScore: field.possibleScore,
  grade: gradeFor(solved.score, field.possibleScore),
  docked: solved.docked,
  collectedCount: solved.collected.size,
  totalStars: field.stars.length,
  shotsUsed: solved.shots.length
});

for (const phrase of ["Star Sling 2026-06-04", "S grade", "docked", "stars", "shots"]) {
  if (!share.includes(phrase)) throw new Error(`share text missing ${phrase}: ${share}`);
}

console.log(
  `check passed: ${FIELD_WIDTH}x${FIELD_HEIGHT}, ${STAR_COUNT} stars, ` +
    `${HAZARD_COUNT} hazards, par ${field.par}, ${field.possibleScore} possible`
);

function assertField(dateKey, field) {
  if (field.dateKey !== dateKey) throw new Error(`date mismatch: ${field.dateKey}`);
  if (field.width !== FIELD_WIDTH || field.height !== FIELD_HEIGHT) throw new Error("unexpected field size");
  if (field.stars.length !== STAR_COUNT) throw new Error("unexpected star count");
  if (field.hazards.length !== HAZARD_COUNT) throw new Error("unexpected hazard count");
  if (field.shotLimit !== SHOT_LIMIT) throw new Error("unexpected shot limit");
  if (field.par < 5 || field.par > SHOT_LIMIT) throw new Error(`unexpected par: ${field.par}`);

  for (const point of [field.launcher, field.dock, ...field.stars, ...field.hazards]) {
    if (point.x < 0 || point.y < 0 || point.x > FIELD_WIDTH || point.y > FIELD_HEIGHT) {
      throw new Error(`point outside field: ${JSON.stringify(point)}`);
    }
  }
}
