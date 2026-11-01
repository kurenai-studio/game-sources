#!/usr/bin/env node
// Renders the 2.5D board concept screens into docs/design/3d/ (PNG, light and dark).
//
//   node scripts/concept-3d/render.mjs
//
// The screens are the existing concept renders (docs/design/screens) with the board replaced by a
// flat-shaded, extruded board drawn from the design tokens. Face shades are computed from the
// tokens, so no color is written by hand. Needs Google Chrome (playwright-core drives it).
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const root = join(dirname(fileURLToPath(import.meta.url)), "../..");
const outDir = join(root, "docs/design/3d");
const scratch = process.env.CONCEPT_SCRATCH ?? join(tmpdir(), "algomind-concept-3d");
const fontFile = join(root, "apps/game/assets/fonts/BarlowCondensed-Bold.ttf");

const tokens = Object.fromEntries(
  JSON.parse(readFileSync(join(root, "packages/design-tokens/tokens.json"), "utf8")).tokens.map(
    (t) => [t.name, { light: t.light, dark: t.dark }],
  ),
);

// ---- color helpers (shades are computed from tokens) ----
const rgb = (hex) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const hex = (c) => `#${c.map((v) => Math.round(v).toString(16).padStart(2, "0")).join("")}`;
const mix = (a, b, t) => {
  const [x, y] = [rgb(a), rgb(b)];
  return hex(x.map((v, i) => v + (y[i] - v) * t));
};
const darker = (c, t) => mix(c, tokens.ink.light, t);
const lighter = (c, t) => mix(c, tokens["on-ink"].light, t);

// Per theme and role: [direction, front/left amount, right amount].
const FACE = {
  light: {
    base: ["dk", 0.1, 0.2],
    floor: ["dk", 0.12, 0.2],
    wall: ["lt", 0.22, 0.1],
    auto: ["lt", 0.28, 0.14],
    goal: ["dk", 0.2, 0.3],
    trail: ["dk", 0.1, 0.18],
  },
  dark: {
    base: ["lt", 0.05, 0.02],
    floor: ["lt", 0.07, 0.04],
    wall: ["dk", 0.3, 0.45],
    auto: ["dk", 0.22, 0.34],
    goal: ["dk", 0.2, 0.3],
    trail: ["dk", 0.2, 0.3],
  },
};

const Z = { base: -0.32, floor: 0.14, wall: 0.6, goal: 0.26, auto: 0.5 };
const GAP = 0.04;

let clipCounter = 0;

function makeView(cols, rows, yawDeg, pitchDeg, persp, box) {
  const yaw = (yawDeg * Math.PI) / 180;
  const pitch = (pitchDeg * Math.PI) / 180;
  const [cy, sy, sp, cp] = [Math.cos(yaw), Math.sin(yaw), Math.sin(pitch), Math.cos(pitch)];
  const rot = (x, y) => [x * cy - y * sy, x * sy + y * cy];
  // The camera in plan, in rotated board coordinates: in front of the board's centre line.
  const cam = [0, rows * 0.5 + 1.4];
  const raw = (x, y, z) => {
    const [rx, ry] = rot(x - cols / 2, y - rows / 2);
    const f = 1 / (1 - persp * (ry * sp + z * cp));
    return [rx * f, (ry * sp - z * cp) * f];
  };
  const pts = [];
  for (const [x, y] of [
    [0, 0],
    [cols, 0],
    [0, rows],
    [cols, rows],
  ])
    for (const z of [Z.base, Z.wall]) pts.push(raw(x, y, z));
  const xs = pts.map((p) => p[0]);
  const ys = pts.map((p) => p[1]);
  const [minX, maxX, minY, maxY] = [
    Math.min(...xs),
    Math.max(...xs),
    Math.min(...ys),
    Math.max(...ys),
  ];
  const margin = 6;
  const scale = Math.min(
    (box.w - 2 * margin) / (maxX - minX),
    (box.h - 2 * margin) / (maxY - minY),
  );
  const [mx, my] = [(minX + maxX) / 2, (minY + maxY) / 2];
  return {
    scale,
    proj: (x, y, z) => {
      const [a, b] = raw(x, y, z);
      return [box.w / 2 + (a - mx) * scale, box.h / 2 + (b - my) * scale];
    },
    // Smaller is farther from the camera, so an ascending sort paints far to near.
    depth: (x, y) => {
      const [rx, ry] = rot(x - cols / 2, y - rows / 2);
      return -Math.hypot(rx - cam[0], ry - cam[1]);
    },
    // Is a vertical face with outward normal (nx, ny) through (px, py) seen by the camera?
    sees: (px, py, nx, ny) => {
      const [rx, ry] = rot(px - cols / 2, py - rows / 2);
      const [rnx, rny] = rot(nx, ny);
      return [rnx * (cam[0] - rx) + rny * (cam[1] - ry) > 0.001, rnx];
    },
  };
}

const pointsAttr = (pts) => pts.map((p) => `${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");

function prism(v, footprint, z0, z1, role, topColor, theme, extra = "") {
  let area = 0;
  footprint.forEach((p, i) => {
    const q = footprint[(i + 1) % footprint.length];
    area += p[0] * q[1] - q[0] * p[1];
  });
  const fp = area < 0 ? [...footprint].reverse() : footprint;
  const [dir, amtA, amtB] = FACE[theme][role];
  const shade = (c, t) => (dir === "dk" ? darker(c, t) : lighter(c, t));
  let out = "";
  fp.forEach((p, i) => {
    const q = fp[(i + 1) % fp.length];
    const [dx, dy] = [q[0] - p[0], q[1] - p[1]];
    const len = Math.hypot(dx, dy);
    const [seen, rx] = v.sees((p[0] + q[0]) / 2, (p[1] + q[1]) / 2, dy / len, -dx / len);
    if (!seen) return;
    const fill = shade(topColor, rx > 0.3 ? amtB : amtA);
    const quad = [p, q]
      .map((c) => v.proj(c[0], c[1], z1))
      .concat([q, p].map((c) => v.proj(c[0], c[1], z0)));
    out += `<polygon points="${pointsAttr(quad)}" fill="${fill}" stroke="${fill}" stroke-width="0.6"/>`;
  });
  const top = fp.map((p) => v.proj(p[0], p[1], z1));
  out += `<polygon points="${pointsAttr(top)}" fill="${topColor}" stroke="${topColor}" stroke-width="0.6" ${extra}/>`;
  return { svg: out, top };
}

const square = (x, y, inset = GAP) => [
  [x + inset, y + inset],
  [x + 1 - inset, y + inset],
  [x + 1 - inset, y + 1 - inset],
  [x + inset, y + 1 - inset],
];

const DIRS = { north: [0, -1], south: [0, 1], east: [1, 0], west: [-1, 0] };

function boardSvg(spec, theme, opts) {
  const { cols, rows } = spec.board;
  const box = opts.box;
  const v = makeView(cols, rows, opts.yaw, opts.pitch, opts.persp, box);
  const t = (name) => tokens[name][theme];
  const walls = new Set(spec.board.walls.map((w) => w.join()));
  const trail = new Set((spec.trail ?? []).map((w) => w.join()));
  const goalKey = spec.board.goal.join();
  const hitKey = spec.hit ? spec.hit.join() : "";
  const items = [
    {
      depth: -1e9,
      layer: 0,
      svg: prism(
        v,
        [
          [0, 0],
          [cols, 0],
          [cols, rows],
          [0, rows],
        ],
        Z.base,
        0,
        "base",
        t("strip"),
        theme,
      ).svg,
    },
  ];
  let defs = "";

  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < cols; x++) {
      const key = `${x},${y}`;
      const depth = v.depth(x + 0.5, y + 0.5);
      if (walls.has(key)) {
        const hit = key === hitKey;
        const { svg, top } = prism(v, square(x, y), 0, Z.wall, "wall", t("wall"), theme);
        const id = `c${clipCounter++}`;
        defs += `<clipPath id="${id}"><polygon points="${pointsAttr(top)}"/></clipPath>`;
        let hatch = "";
        const [line, width] = hit
          ? [t("signal"), 0.17 * v.scale]
          : [t("wall-hatch"), 0.12 * v.scale];
        for (let c = 0.1; c < 1.95; c += hit ? 0.34 : 0.28) {
          const [a, b] = [v.proj(x + c, y, Z.wall), v.proj(x, y + c, Z.wall)];
          hatch += `<line x1="${a[0].toFixed(1)}" y1="${a[1].toFixed(1)}" x2="${b[0].toFixed(1)}" y2="${b[1].toFixed(1)}" stroke="${line}" stroke-width="${width.toFixed(1)}"/>`;
        }
        items.push({ depth, layer: 1, svg: `${svg}<g clip-path="url(#${id})">${hatch}</g>` });
        continue;
      }
      const isGoal = key === goalKey;
      const isTrail = trail.has(key);
      const role = isGoal ? "goal" : isTrail ? "trail" : "floor";
      const topColor = isGoal ? t("signal") : isTrail ? t("trail") : t("floor");
      const height = isGoal ? Z.goal : Z.floor;
      let { svg } = prism(v, square(x, y), 0, height, role, topColor, theme);
      if (isGoal) {
        const ring = [];
        const dot = [];
        for (let i = 0; i < 40; i++) {
          const a = (i / 40) * Math.PI * 2;
          ring.push(
            v.proj(x + 0.5 + Math.cos(a) * 0.27, y + 0.5 + Math.sin(a) * 0.27, height + 0.002),
          );
          dot.push(
            v.proj(x + 0.5 + Math.cos(a) * 0.1, y + 0.5 + Math.sin(a) * 0.1, height + 0.002),
          );
        }
        svg += `<polygon points="${pointsAttr(ring)}" fill="none" stroke="${t("on-signal")}" stroke-width="${(0.07 * v.scale).toFixed(1)}"/>`;
        svg += `<polygon points="${pointsAttr(dot)}" fill="${t("on-signal")}"/>`;
      } else if (isTrail) {
        const [m, mx, my] = [0.1, x + 0.5, y + 0.5];
        const pts = [
          [mx - m, my - m],
          [mx + m, my - m],
          [mx + m, my + m],
          [mx - m, my + m],
        ].map((p) => v.proj(p[0], p[1], height + 0.002));
        svg += `<polygon points="${pointsAttr(pts)}" fill="${t("signal")}" stroke="${t("ink")}" stroke-width="1.4"/>`;
      }
      items.push({ depth, layer: 0, svg });
    }
  }

  const [ax, ay, facing] = spec.auto;
  const base = `${ax},${ay}` === goalKey ? Z.goal : Z.floor;
  const [i0, i1, ch] = [0.17, 0.83, 0.13];
  const body = [
    [ax + i0, ay + i0],
    [ax + i1 - ch, ay + i0],
    [ax + i1, ay + i0 + ch],
    [ax + i1, ay + i1],
    [ax + i0, ay + i1],
  ];
  const hit = Boolean(spec.hit);
  const { svg: autoSvg, top } = prism(v, body, base, base + Z.auto, "auto", t("ink"), theme);
  const [dx, dy] = DIRS[facing];
  const [cx, cy] = [ax + 0.5, ay + 0.5];
  const [px, py] = [-dy, dx];
  const wedge = [
    [cx + dx * 0.26, cy + dy * 0.26],
    [cx - dx * 0.1 + px * 0.2, cy - dy * 0.1 + py * 0.2],
    [cx - dx * 0.1 - px * 0.2, cy - dy * 0.1 - py * 0.2],
  ].map((p) => v.proj(p[0], p[1], base + Z.auto + 0.003));
  const outline = hit
    ? `<polygon points="${pointsAttr(top)}" fill="none" stroke="${t("signal")}" stroke-width="3"/>`
    : "";
  items.push({
    depth: v.depth(ax + 0.5, ay + 0.5),
    layer: 2,
    svg: `${autoSvg}${outline}<polygon points="${pointsAttr(wedge)}" fill="${t("signal")}"/>`,
  });

  items.sort((a, b) => a.depth - b.depth || a.layer - b.layer);
  return `<svg width="${box.w}" height="${box.h}" viewBox="0 0 ${box.w} ${box.h}" xmlns="http://www.w3.org/2000/svg"><defs>${defs}</defs>${items.map((i) => i.svg).join("")}</svg>`;
}

// ---- screens ----
const BOARD = {
  cols: 5,
  rows: 5,
  walls: [
    [1, 2],
    [4, 2],
    [2, 3],
    [1, 4],
  ],
  goal: [3, 2],
};
const SCREENS = [
  {
    file: "01-game-ready",
    bg: "05-game-ready",
    top: 140,
    state: { board: BOARD, auto: [0, 4, "north"] },
  },
  {
    file: "02-game-running",
    bg: "06-game-running",
    top: 140,
    state: {
      board: BOARD,
      auto: [1, 1, "east"],
      trail: [
        [0, 1],
        [0, 2],
        [0, 3],
        [0, 4],
      ],
    },
  },
  {
    file: "03-game-failed",
    bg: "07-game-failed",
    top: 146,
    state: {
      board: BOARD,
      auto: [0, 2, "east"],
      hit: [1, 2],
      trail: [
        [0, 3],
        [0, 4],
      ],
    },
  },
  {
    file: "04-game-solved",
    bg: "08-game-solved",
    top: 140,
    state: {
      board: BOARD,
      auto: [3, 2, "south"],
      trail: [
        [0, 1],
        [1, 1],
        [2, 1],
        [3, 1],
        [0, 2],
        [0, 3],
        [0, 4],
      ],
    },
  },
];
const MAIN_VIEW = process.env.CONCEPT_VIEW ?? "persp";
const AREA = { left: 20, w: 350, h: 366 };
const VIEWS = {
  flat: { yaw: 0, pitch: 58, persp: 0 },
  persp: { yaw: 0, pitch: 64, persp: 0.06 },
  angled: { yaw: 16, pitch: 54, persp: 0.06 },
  iso: { yaw: 45, pitch: 35, persp: 0 },
  top: { yaw: 0, pitch: 90, persp: 0 },
  large: { yaw: 0, pitch: 78, persp: 0.02 },
};

function screenHtml(screen, theme, viewName) {
  const bg = join(root, "docs/design/screens", theme, `${screen.bg}.png`);
  const board = boardSvg(screen.state, theme, {
    ...VIEWS[viewName],
    box: { w: AREA.w, h: AREA.h },
  });
  return `<div class="screen" style="background:url('file://${bg}') 0 0/390px 844px">
    <div style="position:absolute;left:${AREA.left}px;top:${screen.top}px;width:${AREA.w}px;height:${AREA.h}px;background:${tokens.ground[theme]}">${board}</div>
  </div>`;
}

const page = (theme, body, width) => `<!doctype html><html><head><meta charset="utf-8"><style>
  @font-face{font-family:Bar;src:url('file://${fontFile}')}
  html,body{margin:0;padding:0;background:${mix(tokens.ground[theme], tokens.ink[theme], 0.45)}}
  .screen{position:relative;width:390px;height:844px;overflow:hidden}
  .row{display:flex;gap:20px;padding:20px;width:${width}px;box-sizing:border-box;background:${mix(tokens.ground[theme], tokens.ink[theme], 0.45)}}
  .cap{font:700 20px Bar;letter-spacing:2px;color:${tokens.ink[theme]};padding:10px 0 0}
  .panel{background:${tokens.ground[theme]};width:390px;padding:0 0 16px}
  </style></head><body>${body}</body></html>`;

async function shoot(browser, html, path, size, scale) {
  const file = `${scratch}/page.html`;
  writeFileSync(file, html);
  const ctx = await browser.newContext({ viewport: size, deviceScaleFactor: scale });
  const pg = await ctx.newPage();
  await pg.goto(`file://${file}`);
  await pg.evaluate(() => document.fonts.ready);
  await pg.screenshot({ path, clip: { x: 0, y: 0, ...size } });
  await ctx.close();
}

mkdirSync(scratch, { recursive: true });
const browser = await chromium.launch({ channel: "chrome", headless: true });
for (const theme of ["light", "dark"]) {
  mkdirSync(join(outDir, theme), { recursive: true });
  for (const screen of SCREENS) {
    const html = page(theme, screenHtml(screen, theme, MAIN_VIEW), 390);
    await shoot(
      browser,
      html,
      join(outDir, theme, `${screen.file}.png`),
      { width: 390, height: 844 },
      2,
    );
  }
  const row = SCREENS.map((s) => screenHtml(s, theme, MAIN_VIEW)).join("");
  const sheet = page(theme, `<div class="row">${row}</div>`, 1660);
  await shoot(
    browser,
    sheet,
    join(outDir, `overview-${theme}.png`),
    { width: 1660, height: 884 },
    1,
  );

  // Camera options side by side on the same board.
  const options = [
    ["flat", "FLAT TILT"],
    ["persp", "TILT, PERSPECTIVE"],
    ["angled", "ANGLED, PERSPECTIVE"],
    ["iso", "ISOMETRIC"],
  ];
  const panels = options
    .map(
      ([name, label]) =>
        `<div class="panel"><div class="cap" style="padding-left:20px">${label}</div>${boardPanel(theme, name)}</div>`,
    )
    .join("");
  const cmp = page(theme, `<div class="row">${panels}</div>`, 1660);
  await shoot(
    browser,
    cmp,
    join(outDir, `compare-camera-${theme}.png`),
    { width: 1660, height: 520 },
    1,
  );

  // The largest board in the campaign (world 8, 12 by 10), today's top-down view against the tilt.
  const big = JSON.parse(readFileSync(join(root, "apps/game/data/levels/big-spiral.json"), "utf8"));
  const bigState = {
    board: {
      cols: big.board.width,
      rows: big.board.height,
      walls: big.board.walls,
      goal: big.goal.position,
    },
    auto: [...big.initialState.position, big.initialState.direction],
  };
  const bigPanel = (name, label) =>
    `<div class="panel"><div class="cap" style="padding-left:20px">${label}</div><div style="margin:10px 20px 0;width:${AREA.w}px;height:${AREA.h}px">${boardSvg(bigState, theme, { ...VIEWS[name], box: { w: AREA.w, h: AREA.h } })}</div></div>`;
  const bigPage = page(
    theme,
    `<div class="row">${bigPanel("top", "TOP-DOWN, 12 BY 10")}${bigPanel("persp", "TILT, PERSPECTIVE")}${bigPanel("large", "TILT, LARGE BOARD")}</div>`,
    1280,
  );
  await shoot(
    browser,
    bigPage,
    join(outDir, `compare-large-board-${theme}.png`),
    { width: 1280, height: 520 },
    2,
  );
}
await browser.close();

function boardPanel(theme, viewName) {
  const state = SCREENS[1].state;
  return `<div style="margin:10px 20px 0;width:${AREA.w}px;height:${AREA.h}px;background:${tokens.ground[theme]}">${boardSvg(state, theme, { ...VIEWS[viewName], box: { w: AREA.w, h: AREA.h } })}</div>`;
}
console.log(`Wrote ${outDir}`);
