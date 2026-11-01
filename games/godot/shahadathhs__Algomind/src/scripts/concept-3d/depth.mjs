#!/usr/bin/env node
// Renders the depth concept (new theme, UI, and 2.5D board) into docs/design/depth/.
//
//   node scripts/concept-3d/depth.mjs
//
// A concept, not the game: the screens are HTML drawn with the proposed tokens in
// the depth tokens in packages/design-tokens/tokens.json. Needs Google Chrome (playwright-core drives it).
import { mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";
import { cameraFor, darken, depthBoard, lighten, mix, tokens } from "./depth-board.mjs";
import { readFileSync } from "node:fs";

const root = join(dirname(fileURLToPath(import.meta.url)), "../..");
const outDir = join(root, "docs/design/depth");
const scratch = process.env.CONCEPT_SCRATCH ?? join(tmpdir(), "algomind-concept-depth");
const font = join(root, "apps/game/assets/fonts/BarlowCondensed-Bold.ttf");

// ---- icons ----
const icon = {
  move: `<svg viewBox="0 0 24 24" width="26" height="26"><polygon points="12,3 20,12 14.5,12 14.5,21 9.5,21 9.5,12 4,12" fill="currentColor"/></svg>`,
  left: `<svg viewBox="0 0 24 24" width="26" height="26"><path d="M17 21V12H9" fill="none" stroke="currentColor" stroke-width="3.4"/><polygon points="3,12 11,5 11,19" fill="currentColor"/></svg>`,
  right: `<svg viewBox="0 0 24 24" width="26" height="26"><path d="M7 21V12H15" fill="none" stroke="currentColor" stroke-width="3.4"/><polygon points="21,12 13,5 13,19" fill="currentColor"/></svg>`,
  step: `<svg viewBox="0 0 24 24" width="22" height="22"><polygon points="4,4 15,12 4,20" fill="currentColor"/><rect x="17" y="4" width="3.5" height="16" fill="currentColor"/></svg>`,
  run: `<svg viewBox="0 0 24 24" width="22" height="22"><polygon points="5,3 21,12 5,21" fill="currentColor"/></svg>`,
  reset: `<svg viewBox="0 0 24 24" width="22" height="22"><path d="M12 5a7 7 0 1 1-6.6 4.7" fill="none" stroke="currentColor" stroke-width="3"/><polygon points="2,3 11,3 6.5,11" fill="currentColor"/></svg>`,
  back: `<svg viewBox="0 0 24 24" width="22" height="22"><polyline points="15,4 7,12 15,20" fill="none" stroke="currentColor" stroke-width="3.4"/></svg>`,
  menu: `<svg viewBox="0 0 24 24" width="22" height="22"><rect x="3" y="5" width="18" height="3" fill="currentColor"/><rect x="3" y="10.5" width="18" height="3" fill="currentColor"/><rect x="3" y="16" width="18" height="3" fill="currentColor"/></svg>`,
  check: `<svg viewBox="0 0 24 24" width="22" height="22"><polyline points="4,13 10,19 20,6" fill="none" stroke="currentColor" stroke-width="3.6"/></svg>`,
  cross: `<svg viewBox="0 0 24 24" width="22" height="22"><path d="M5 5L19 19M19 5L5 19" stroke="currentColor" stroke-width="3.6"/></svg>`,
  lock: `<svg viewBox="0 0 24 24" width="20" height="20"><rect x="5" y="11" width="14" height="10" fill="currentColor"/><path d="M8 11V8a4 4 0 0 1 8 0v3" fill="none" stroke="currentColor" stroke-width="2.6"/></svg>`,
};

// ---- boards ----
const BASE = {
  cols: 6,
  rows: 5,
  goal: [5, 0],
  walls: [
    [2, 0],
    [4, 3],
    [1, 3],
  ],
};
const PATH = [
  [1, 2],
  [2, 2],
  [3, 2],
  [4, 2],
];
const STATES = {
  ready: { board: BASE, auto: [0, 4, "north"], guard: { at: [1, 2], path: PATH } },
  running: {
    board: BASE,
    auto: [0, 1, "east"],
    trail: [
      [0, 4],
      [0, 3],
      [0, 2],
    ],
    guard: { at: [4, 2], path: PATH },
  },
  failed: {
    board: BASE,
    auto: [2, 2, "east"],
    hit: [3, 2],
    trail: [
      [0, 4],
      [0, 3],
      [0, 2],
      [1, 2],
    ],
    guard: { at: [3, 2], path: PATH },
  },
  solved: {
    board: BASE,
    auto: [5, 0, "north"],
    trail: [
      [0, 4],
      [0, 3],
      [0, 2],
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
    ],
    guard: { at: [2, 2], path: PATH },
  },
};

// ---- page pieces ----
const css = (theme) => {
  const t = (n) => tokens[n][theme];
  const lip = (c) => darken(c, 0.3);
  return `
  @font-face{font-family:Bar;src:url('file://${font}')}
  :root{--ink:${t("ink")};--on-ink:${t("on-ink")};--mute:${t("mute")};--tile:${t("tile")};--tile-lip:${lip(t("tile"))};
    --signal:${t("signal")};--signal-lip:${darken(t("signal"), 0.26)};--on-signal:${t("on-signal")};--strip:${t("strip")};
    --shadow:${mix(t("shadow"), t("ground-bottom"), 0.0)};--ink-lip:${theme === "light" ? lighten(t("ink"), 0.28) : darken(t("ink"), 0.35)}}
  *{box-sizing:border-box}
  html,body{margin:0;background:${mix(t("ground-bottom"), t("ink"), 0.4)}}
  .screen{position:relative;width:390px;height:844px;overflow:hidden;font-family:Bar;color:var(--ink);text-transform:uppercase;
    background:linear-gradient(${t("ground-top")},${t("ground-bottom")})}
  .abs{position:absolute}
  .cap{font-size:13px;letter-spacing:2.4px;color:var(--mute)}
  .title{font-size:24px;letter-spacing:.5px;line-height:1}
  .key{position:absolute;filter:drop-shadow(0 4px 0 var(--tile-lip)) drop-shadow(0 8px 7px color-mix(in srgb,var(--shadow) 30%,transparent))}
  .key.sig{filter:drop-shadow(0 4px 0 var(--signal-lip)) drop-shadow(0 8px 7px color-mix(in srgb,var(--shadow) 30%,transparent))}
  .key.ink{filter:drop-shadow(0 4px 0 var(--ink-lip)) drop-shadow(0 8px 7px color-mix(in srgb,var(--shadow) 30%,transparent))}
  .key>.f{clip-path:polygon(0 0,calc(100% - 11px) 0,100% 11px,100% 100%,0 100%);background:var(--tile);height:100%;width:100%;
    display:flex;align-items:center;justify-content:center;gap:8px;font-size:19px;letter-spacing:2px;color:var(--ink)}
  .key.sig>.f{background:var(--signal);color:var(--on-signal)}
  .key.ink>.f{background:var(--ink);color:var(--on-ink)}
  .trough{background:var(--strip);box-shadow:inset 0 4px 8px color-mix(in srgb,var(--shadow) 35%,transparent),inset 0 -1px 0 color-mix(in srgb,var(--on-ink) 14%,transparent)}
  .num{font-size:13px;letter-spacing:1px;color:var(--mute);text-align:center;width:58px}
  .num.on{color:var(--ink)}
  .head{position:absolute;width:0;height:0;border-left:8px solid transparent;border-right:8px solid transparent;border-top:12px solid var(--signal)}
  `;
};

const key = (label, left, top, w, h, kind = "", ic = "") =>
  `<div class="key ${kind} abs" style="left:${left}px;top:${top}px;width:${w}px;height:${h}px"><div class="f">${ic}${label}</div></div>`;

function topbar(level, title) {
  return `${key("", 20, 28, 46, 46, "", icon.back)}
  <div class="abs" style="left:78px;top:26px;width:234px;text-align:center"><div class="cap" style="font-size:12px">${level}</div><div class="title" style="margin-top:4px">${title}</div></div>
  ${key("", 322, 28, 48, 46, "", icon.menu)}`;
}

function tape(items) {
  const x0 = 20;
  let out = `<div class="abs cap" style="left:22px;top:524px">Program</div>
  <div class="abs trough" style="left:20px;top:546px;width:350px;height:112px"></div>`;
  items.forEach((it, i) => {
    const left = x0 + 12 + i * 66;
    const cls = it.state === "now" ? "sig" : it.state === "done" ? "ink" : "";
    if (it.state === "empty") {
      out += `<div class="abs" style="left:${left}px;top:566px;width:58px;height:58px;border:2px dashed var(--mute);opacity:.7"></div>`;
    } else {
      out += key("", left, 566, 58, 58, cls, icon[it.icon]);
    }
    out += `<div class="abs num ${it.state === "now" ? "on" : ""}" style="left:${left}px;top:634px">${it.n ?? ""}</div>`;
    if (it.state === "now") out += `<div class="head" style="left:${left + 21}px;top:548px"></div>`;
  });
  return out;
}

const palette = (top = 690) =>
  `<div class="abs cap" style="left:22px;top:${top - 22}px">Commands</div>` +
  key("Move", 20, top, 110, 54, "", icon.move) +
  key("Left", 140, top, 110, 54, "", icon.left) +
  key("Right", 260, top, 110, 54, "", icon.right);

// The guard's stop at each step: it walks stops 1 to 4 and back.
const STOPS = [1, 2, 3, 4, 3, 2, 1, 2];
function patrol(now, failAt = -1) {
  let out = `<div class="abs cap" style="left:22px;top:450px">Guard, stop by step</div>`;
  STOPS.forEach((stop, i) => {
    const kind = i === failAt ? "sig" : i === now ? "ink" : "";
    out += `<div class="key ${kind} abs" style="left:${20 + i * 44}px;top:472px;width:38px;height:34px"><div class="f" style="font-size:18px;letter-spacing:0">${i === failAt ? icon.cross.replace(/width="22" height="22"/, 'width="16" height="16"') : stop}</div></div>`;
  });
  return out;
}

function board(state, top = 134, h = 372) {
  return `<div class="abs" style="left:20px;top:${top}px;width:350px;height:${h}px">${depthBoard(state, THEME, cameraFor(state.board.cols, state.board.rows), { w: 350, h })}</div>`;
}

let THEME = "light";

const SCREENS = {
  menu: () => `
    <div class="abs" style="left:0;top:92px;width:390px;display:flex;justify-content:center;gap:5px">
      ${"ALGOMIND"
        .split("")
        .map(
          (c, i) =>
            `<div class="key ${i === 0 ? "sig" : "ink"}" style="position:relative;width:38px;height:46px"><div class="f" style="font-size:28px;letter-spacing:0">${c}</div></div>`,
        )
        .join("")}
    </div>
    <div class="abs" style="left:20px;top:176px;width:350px;height:380px">${depthBoard(
      {
        board: {
          cols: 5,
          rows: 5,
          goal: [3, 1],
          walls: [
            [1, 1],
            [2, 3],
            [4, 2],
          ],
        },
        auto: [1, 3, "east"],
        trail: [[0, 3]],
      },
      THEME,
      { pitch: 56, persp: 0.07 },
      { w: 350, h: 380 },
    )}</div>
    ${key("Play", 20, 640, 350, 66, "sig")}
    <div class="abs" style="left:20px;top:752px;width:350px;display:flex;justify-content:space-between;font-size:16px;letter-spacing:2.4px">
      <span>Levels</span><span>Settings</span><span>Account</span></div>`,

  worlds: () => {
    const world = (n, name, sub, st, mini) => ({ n, name, sub, st, mini });
    const rows = [
      world("01", "Basics", "08 of 08 solved", "done", {
        cols: 4,
        rows: 3,
        goal: [3, 1],
        walls: [],
        auto: [0, 1, "east"],
        trail: [[1, 1]],
      }),
      world("02", "Routes", "05 of 10 solved", "now", {
        cols: 4,
        rows: 3,
        goal: [3, 1],
        walls: [
          [2, 1],
          [2, 2],
        ],
        auto: [0, 1, "east"],
        trail: [
          [1, 1],
          [1, 0],
          [2, 0],
        ],
      }),
      world("03", "Loops", "Locked", "lock", {
        cols: 4,
        rows: 3,
        goal: [3, 0],
        walls: [],
        auto: [0, 2, "east"],
        trail: [
          [1, 2],
          [1, 1],
          [2, 1],
          [2, 0],
        ],
      }),
      world("04", "Until", "Locked", "lock", {
        cols: 5,
        rows: 2,
        goal: [3, 0],
        walls: [
          [4, 0],
          [4, 1],
        ],
        auto: [0, 0, "east"],
        trail: [
          [1, 0],
          [2, 0],
        ],
      }),
      world("05", "Decisions", "Locked", "lock", {
        cols: 4,
        rows: 3,
        goal: [3, 2],
        walls: [
          [1, 0],
          [1, 1],
          [2, 1],
        ],
        auto: [0, 2, "east"],
        trail: [
          [1, 2],
          [2, 2],
        ],
      }),
    ];
    const list = rows
      .map(({ n, name, sub, st, mini }, i) => {
        const top = 128 + i * 120;
        const dim = st === "lock" ? "opacity:.55" : "";
        const kind = st === "now" ? "sig" : "";
        return `<div class="key ${kind} abs" style="left:20px;top:${top}px;width:350px;height:100px;${dim}"><div class="f" style="justify-content:flex-start;padding:0 16px;gap:14px">
            <div style="font-size:34px;width:40px">${n}</div>
            <div style="flex:1"><div style="font-size:26px;display:flex;align-items:center;gap:8px">${name}${st === "lock" ? icon.lock : ""}</div><div class="cap" style="color:${st === "now" ? "var(--on-signal)" : "var(--mute)"};margin-top:6px;letter-spacing:1.6px">${sub}</div></div>
            <div style="width:112px;height:84px">${depthBoard({ board: { cols: mini.cols, rows: mini.rows, goal: mini.goal, walls: mini.walls }, auto: mini.auto, trail: mini.trail }, THEME, { pitch: 56, persp: 0.04 }, { w: 112, h: 84 })}</div>
          </div></div>`;
      })
      .join("");
    return `<div class="abs" style="left:22px;top:44px"><div class="cap">Campaign</div><div class="title" style="font-size:38px;margin-top:6px">Worlds</div></div>
      <div class="abs cap" style="left:250px;top:62px;width:120px;text-align:right">Of 20 worlds</div>
      ${list}
      ${key("Continue level 14", 20, 746, 350, 62, "sig")}`;
  },

  ready: () => `${topbar("Level 12 · Patrol", "Past the guard")}
    <div class="abs cap" style="left:22px;top:96px;color:var(--ink);font-size:17px;letter-spacing:1.4px">Reach the target</div>
    <div class="abs cap" style="left:208px;top:98px;width:162px;text-align:right">0 / 9 commands</div>
    <div class="abs" style="left:22px;top:118px;font-size:13px;letter-spacing:1.8px;color:var(--mute)">Guard walks 1 to 4, then back</div>
    ${board(STATES.ready, 142, 300)}${patrol(0)}
    ${tape(
      [
        { n: "01", state: "empty" },
        { n: "02", state: "empty" },
        { n: "03", state: "empty" },
        { n: "04", state: "empty" },
        { n: "05", state: "empty" },
      ].map((x) => x),
    )}
    ${palette()}
    ${key("Step", 20, 764, 110, 56, "", icon.step)}${key("Run", 140, 764, 120, 56, "sig", icon.run)}${key("Reset", 270, 764, 100, 56, "", icon.reset)}`,

  running: () => `${topbar("Level 12 · Patrol", "Past the guard")}
    <div class="abs cap" style="left:22px;top:96px;color:var(--ink);font-size:17px;letter-spacing:1.4px">Step 3 of 9</div>
    <div class="abs cap" style="left:208px;top:98px;width:162px;text-align:right">7 / 9 commands</div>
    <div class="abs" style="left:22px;top:118px;font-size:13px;letter-spacing:1.8px;color:var(--mute)">Guard is on 4, going back</div>
    ${board(STATES.running, 142, 300)}${patrol(3)}
    ${tape([
      { icon: "move", n: "02", state: "done" },
      { icon: "move", n: "03", state: "done" },
      { icon: "right", n: "04", state: "now" },
      { icon: "move", n: "05", state: "todo" },
      { icon: "move", n: "06", state: "todo" },
    ])}
    ${palette()}
    ${key("Step", 20, 764, 110, 56, "", icon.step)}${key("Continue", 140, 764, 120, 56, "sig", icon.run)}${key("Reset", 270, 764, 100, 56, "", icon.reset)}`,

  failed: () => `${topbar("Level 12 · Patrol", "Past the guard")}
    <div class="abs" style="left:20px;top:92px">${key("", 0, 0, 44, 44, "sig", icon.cross).replace("abs", "")}</div>
    <div class="abs" style="left:76px;top:92px;width:290px;font-size:19px;letter-spacing:1px;line-height:1.1">The guard crossed the automaton on step 5</div>
    ${board(STATES.failed, 142, 300)}${patrol(4, 5)}
    ${tape([
      { icon: "move", n: "03", state: "done" },
      { icon: "right", n: "04", state: "done" },
      { icon: "move", n: "05", state: "now" },
      { icon: "move", n: "06", state: "todo" },
      { icon: "move", n: "07", state: "todo" },
    ])}
    ${palette()}
    ${key("Reset", 20, 764, 120, 56, "", icon.reset)}${key("Edit program", 150, 764, 220, 56, "sig")}`,

  solved: () => `${topbar("Level 12 · Patrol", "Past the guard")}
    <div class="abs" style="left:20px;top:92px">${key("", 0, 0, 44, 44, "sig", icon.check).replace("abs", "")}</div>
    <div class="abs" style="left:76px;top:100px;font-size:22px;letter-spacing:1.4px">Level solved</div>
    ${board(STATES.solved, 142, 300)}${patrol(-1)}
    ${tape([
      { icon: "right", n: "07", state: "done" },
      { icon: "move", n: "08", state: "done" },
      { icon: "move", n: "09", state: "now" },
      { n: "10", state: "empty" },
    ])}
    ${["9 / 9|Commands", "11|Steps", "9|Best"]
      .map((s, i) => {
        const [a, b] = s.split("|");
        return `<div class="key abs" style="left:${20 + i * 120}px;top:684px;width:110px;height:72px"><div class="f" style="flex-direction:column;gap:4px;font-size:30px;letter-spacing:0">${a}<span class="cap" style="font-size:12px">${b}</span></div></div>`;
      })
      .join("")}
    ${key("Levels", 20, 774, 100, 54, "")}${key("Replay", 130, 774, 110, 54, "", icon.reset)}${key("Next", 250, 774, 120, 54, "sig")}`,
};

const NAMES = ["menu", "worlds", "ready", "running", "failed", "solved"];
const page = (theme, body, width) =>
  `<!doctype html><html><head><meta charset="utf-8"><style>${css(theme)}
  .row{display:flex;gap:20px;padding:20px;width:${width}px;background:${mix(tokens["ground-bottom"][theme], tokens.ink[theme], 0.4)}}</style></head><body>${body}</body></html>`;

mkdirSync(scratch, { recursive: true });
const browser = await chromium.launch({ channel: "chrome", headless: true });
async function shoot(html, path, size, scale) {
  const file = join(scratch, "page.html");
  writeFileSync(file, html);
  const ctx = await browser.newContext({ viewport: size, deviceScaleFactor: scale });
  const pg = await ctx.newPage();
  await pg.goto(`file://${file}`);
  await pg.evaluate(() => document.fonts.ready);
  await pg.screenshot({ path, clip: { x: 0, y: 0, ...size } });
  await ctx.close();
}

for (const theme of ["light", "dark"]) {
  THEME = theme;
  mkdirSync(join(outDir, theme), { recursive: true });
  const screens = NAMES.map((name) => `<div class="screen">${SCREENS[name]()}</div>`);
  for (const [i, name] of NAMES.entries())
    await shoot(
      page(theme, screens[i], 390),
      join(outDir, theme, `${String(i + 1).padStart(2, "0")}-${name}.png`),
      { width: 390, height: 844 },
      2,
    );
  await shoot(
    page(theme, `<div class="row">${screens.join("")}</div>`, 2500),
    join(outDir, `overview-${theme}.png`),
    { width: 2500, height: 884 },
    1,
  );
}

// Big boards in the depth theme: the adaptive camera against a fixed one.
const level = (name) =>
  JSON.parse(readFileSync(join(root, "apps/game/data/levels", `${name}.json`), "utf8"));
const asState = (l) => ({
  board: { cols: l.board.width, rows: l.board.height, walls: l.board.walls, goal: l.goal.position },
  auto: [...l.initialState.position, l.initialState.direction],
});
for (const theme of ["light", "dark"]) {
  THEME = theme;
  const [mid, big] = [asState(level("square-maze")), asState(level("big-spiral"))];
  const panel = (label, state, view) =>
    `<div class="panel"><div class="cap" style="padding:12px 20px 8px;font-size:15px">${label}</div><div style="margin:0 20px 16px;width:350px;height:340px">${depthBoard(state, theme, view, { w: 350, h: 340 })}</div></div>`;
  const body = `<div class="row">${[
    panel("9 by 9, adaptive camera", mid, cameraFor(9, 9)),
    panel("12 by 10, adaptive camera", big, cameraFor(12, 10)),
    panel("12 by 10, fixed 62 degrees", big, { pitch: 62, persp: 0.06 }),
  ].join("")}</div>`;
  const html = page(theme, body, 1240).replace(
    "</style>",
    ".panel{background:linear-gradient(" +
      tokens["ground-top"][theme] +
      "," +
      tokens["ground-bottom"][theme] +
      ");width:390px;color:" +
      tokens.ink[theme] +
      ";font-family:Bar;text-transform:uppercase;letter-spacing:2px}</style>",
  );
  await shoot(
    html,
    join(outDir, `compare-large-board-${theme}.png`),
    { width: 1240, height: 460 },
    2,
  );
}
await browser.close();
console.log(`Wrote ${outDir}`);
