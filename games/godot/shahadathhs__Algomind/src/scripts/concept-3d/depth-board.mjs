// The depth concept's board: an extruded, softly lit board drawn from the proposed tokens.
// Concept only. The game would draw the same polygons in BoardView with _draw().
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const raw = JSON.parse(readFileSync(join(here, "../../packages/design-tokens/tokens.json"), "utf8"))
  .depth.tokens;
export const tokens = Object.fromEntries(
  raw.map((t) => [t.name, { light: t.light, dark: t.dark }]),
);

const rgb = (hex) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const toHex = (c) => `#${c.map((v) => Math.round(v).toString(16).padStart(2, "0")).join("")}`;
export const mix = (a, b, t) => {
  const [x, y] = [rgb(a), rgb(b)];
  return toHex(x.map((v, i) => v + (y[i] - v) * t));
};
export const darken = (c, t) => mix(c, toHex([0, 0, 0]), t);
export const lighten = (c, t) => mix(c, toHex([255, 255, 255]), t);

export const Z = { plate: -0.4, floor: 0.12, wall: 0.62, goal: 0.24, auto: 0.5, guard: 0.72 };
const GAP = 0.035;
const DIRS = { north: [0, -1], south: [0, 1], east: [1, 0], west: [-1, 0] };
let counter = 0;

function makeView(cols, rows, { pitch, persp }, box) {
  const [sp, cp] = [Math.sin((pitch * Math.PI) / 180), Math.cos((pitch * Math.PI) / 180)];
  const cam = [0, rows * 0.5 + 1.4];
  const rawProject = (x, y, z) => {
    const [rx, ry] = [x - cols / 2, y - rows / 2];
    const f = 1 / (1 - persp * (ry * sp + z * cp));
    return [rx * f, (ry * sp - z * cp) * f];
  };
  const pts = [];
  for (const [x, y] of [
    [-0.3, -0.3],
    [cols + 0.3, -0.3],
    [-0.3, rows + 0.3],
    [cols + 0.3, rows + 0.3],
  ])
    for (const z of [Z.plate - 0.25, Z.guard]) pts.push(rawProject(x, y, z));
  const [xs, ys] = [pts.map((p) => p[0]), pts.map((p) => p[1])];
  const [minX, maxX, minY, maxY] = [
    Math.min(...xs),
    Math.max(...xs),
    Math.min(...ys),
    Math.max(...ys),
  ];
  const m = 4;
  const scale = Math.min((box.w - 2 * m) / (maxX - minX), (box.h - 2 * m) / (maxY - minY));
  const [mx, my] = [(minX + maxX) / 2, (minY + maxY) / 2];
  return {
    scale,
    proj: (x, y, z) => {
      const [a, b] = rawProject(x, y, z);
      return [box.w / 2 + (a - mx) * scale, box.h / 2 + (b - my) * scale];
    },
    depth: (x, y) => -Math.hypot(x - cols / 2 - cam[0], y - rows / 2 - cam[1]),
    sees: (px, py, nx, ny) => {
      const [rx, ry] = [px - cols / 2, py - rows / 2];
      return [nx * (cam[0] - rx) + ny * (cam[1] - ry) > 0.001, nx];
    },
  };
}

const pts = (list) => list.map((p) => `${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");

function prism(v, footprint, z0, z1, top, sideA, sideB, edge) {
  let area = 0;
  footprint.forEach((p, i) => {
    const q = footprint[(i + 1) % footprint.length];
    area += p[0] * q[1] - q[0] * p[1];
  });
  const fp = area < 0 ? [...footprint].reverse() : footprint;
  let out = "";
  fp.forEach((p, i) => {
    const q = fp[(i + 1) % fp.length];
    const [dx, dy] = [q[0] - p[0], q[1] - p[1]];
    const len = Math.hypot(dx, dy);
    const [seen, nx] = v.sees((p[0] + q[0]) / 2, (p[1] + q[1]) / 2, dy / len, -dx / len);
    if (!seen) return;
    const fill = nx > 0.3 ? sideB : sideA;
    const quad = [p, q]
      .map((c) => v.proj(c[0], c[1], z1))
      .concat([q, p].map((c) => v.proj(c[0], c[1], z0)));
    out += `<polygon points="${pts(quad)}" fill="${fill}" stroke="${fill}" stroke-width="0.6"/>`;
  });
  const topPts = fp.map((p) => v.proj(p[0], p[1], z1));
  out += `<polygon points="${pts(topPts)}" fill="${top}" stroke="${edge ?? top}" stroke-width="${edge ? 1 : 0.6}"/>`;
  return { svg: out, top: topPts };
}

const square = (x, y, inset = GAP, size = 1) => [
  [x + inset, y + inset],
  [x + size - inset, y + inset],
  [x + size - inset, y + size - inset],
  [x + inset, y + size - inset],
];

/** state: { board: {cols, rows, walls, goal}, auto: [x, y, facing], trail, hit, guard: {at, path} } */
/** The camera for a board: steeper and flatter as the board grows, so big boards stay readable. */
export function cameraFor(cols, rows) {
  const t = Math.min(1, Math.max(0, (Math.max(cols, rows) - 6) / 6));
  return { pitch: 62 + 18 * t, persp: 0.06 - 0.04 * t };
}

export function depthBoard(state, theme, view, box, shades = {}) {
  const t = (name) => tokens[name][theme];
  const { cols, rows } = state.board;
  const v = makeView(cols, rows, view, box);
  const id = counter++;
  const walls = new Set(state.board.walls.map((w) => w.join()));
  const trail = new Set((state.trail ?? []).map((w) => w.join()));
  const goalKey = state.board.goal.join();
  const hitKey = state.hit ? state.hit.join() : "";
  const [front, side] = [shades.front ?? 0.22, shades.side ?? 0.36];
  const sides = (c) => [darken(c, front), darken(c, side)];
  const blur = `<filter id="b${id}" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="${(v.scale * 0.07).toFixed(1)}"/></filter>`;
  const bigBlur = `<filter id="g${id}" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="${(v.scale * 0.22).toFixed(1)}"/></filter>`;
  let defs = blur + bigBlur;
  let under = "";
  let shadows = "";
  const items = [];
  const plateFp = [
    [-0.3, -0.3],
    [cols + 0.3, -0.3],
    [cols + 0.3, rows + 0.3],
    [-0.3, rows + 0.3],
  ];

  // The soft shadow the plate casts on the ground.
  const cast = plateFp.map((p) => v.proj(p[0] + 0.1, p[1] + 0.35, Z.plate));
  under += `<polygon points="${pts(cast)}" fill="${t("shadow")}" opacity="0.4" filter="url(#g${id})"/>`;
  const [pa, pb] = sides(t("plate"));
  under += prism(v, plateFp, Z.plate, 0, t("plate"), pa, pb, lighten(t("plate"), 0.12)).svg;

  const cellItems = [];
  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < cols; x++) {
      const key = `${x},${y}`;
      if (walls.has(key)) continue;
      const isGoal = key === goalKey;
      const topColor = isGoal ? t("signal") : trail.has(key) ? t("trail") : t("floor");
      const h = isGoal ? Z.goal : Z.floor;
      const [sa, sb] = sides(topColor);
      const cell = prism(v, square(x, y), 0, h, topColor, sa, sb, lighten(topColor, 0.18));
      let svg = cell.svg;
      if (key === hitKey) {
        // The cell where the run failed: a hazard-striped floor, like a wall that was hit.
        const clip = `k${id}_h`;
        defs += `<clipPath id="${clip}"><polygon points="${pts(cell.top)}"/></clipPath>`;
        let stripes = `<polygon points="${pts(cell.top)}" fill="${t("signal")}"/>`;
        for (let c = 0.1; c < 1.95; c += 0.34) {
          const [a, b] = [v.proj(x + c, y, h), v.proj(x, y + c, h)];
          stripes += `<line x1="${a[0].toFixed(1)}" y1="${a[1].toFixed(1)}" x2="${b[0].toFixed(1)}" y2="${b[1].toFixed(1)}" stroke="${t("ink")}" stroke-width="${(0.15 * v.scale).toFixed(1)}"/>`;
        }
        svg += `<g clip-path="url(#${clip})">${stripes}</g>`;
      }
      if (isGoal) {
        const [ring, dot] = [[], []];
        for (let i = 0; i < 40; i++) {
          const a = (i / 40) * Math.PI * 2;
          ring.push(v.proj(x + 0.5 + Math.cos(a) * 0.27, y + 0.5 + Math.sin(a) * 0.27, h + 0.002));
          dot.push(v.proj(x + 0.5 + Math.cos(a) * 0.1, y + 0.5 + Math.sin(a) * 0.1, h + 0.002));
        }
        svg += `<polygon points="${pts(ring)}" fill="none" stroke="${t("on-signal")}" stroke-width="${(0.07 * v.scale).toFixed(1)}"/><polygon points="${pts(dot)}" fill="${t("on-signal")}"/>`;
      } else if (trail.has(key)) {
        const m = square(x + 0.5 - 0.1, y + 0.5 - 0.1, 0, 0.2).map((p) =>
          v.proj(p[0], p[1], h + 0.002),
        );
        svg += `<polygon points="${pts(m)}" fill="${t("signal")}" stroke="${t("ink")}" stroke-width="1.2"/>`;
      }
      cellItems.push(svg);
    }
  }

  // Soft contact shadows of everything that stands on the floor.
  const casters = [];
  for (const w of state.board.walls) casters.push(square(w[0], w[1]));
  casters.push(square(state.auto[0] + 0.17, state.auto[1] + 0.17, 0, 0.66));
  if (state.guard) casters.push(square(state.guard.at[0] + 0.2, state.guard.at[1] + 0.2, 0, 0.6));
  for (const fp of casters) {
    const s = fp.map((p) => v.proj(p[0] + 0.2, p[1] + 0.14, Z.floor));
    shadows += `<polygon points="${pts(s)}" fill="${t("shadow")}" opacity="0.42" filter="url(#b${id})"/>`;
  }

  // The route the guard walks, drawn on the floor, with the step it stands there.
  let route = "";
  if (state.guard?.path) {
    const line = state.guard.path.map((p) => v.proj(p[0] + 0.5, p[1] + 0.5, Z.floor + 0.004));
    route += `<polyline points="${pts(line)}" fill="none" stroke="${t("ink")}" stroke-width="${(0.05 * v.scale).toFixed(1)}" stroke-dasharray="${(0.12 * v.scale).toFixed(1)} ${(0.1 * v.scale).toFixed(1)}" opacity="0.75"/>`;
    state.guard.path.forEach((p, i) => {
      const [cx, cy] = v.proj(p[0] + 0.5, p[1] + 0.5, Z.floor + 0.004);
      const r = 0.15 * v.scale;
      route += `<circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="${r.toFixed(1)}" fill="${t("ink")}"/><text x="${cx.toFixed(1)}" y="${(cy + r * 0.38).toFixed(1)}" text-anchor="middle" font-family="Bar" font-size="${(r * 1.25).toFixed(1)}" fill="${t("on-ink")}">${i + 1}</text>`;
    });
  }

  // Walls.
  const [wa, wb] = sides(t("wall"));
  for (const [x, y] of state.board.walls) {
    const hit = `${x},${y}` === hitKey;
    const { svg, top } = prism(
      v,
      square(x, y),
      0,
      Z.wall,
      t("wall"),
      wa,
      wb,
      lighten(t("wall"), 0.16),
    );
    const clip = `k${id}_${x}_${y}`;
    defs += `<clipPath id="${clip}"><polygon points="${pts(top)}"/></clipPath>`;
    let hatch = "";
    for (let c = 0.1; c < 1.95; c += hit ? 0.34 : 0.28) {
      const [a, b] = [v.proj(x + c, y, Z.wall), v.proj(x, y + c, Z.wall)];
      hatch += `<line x1="${a[0].toFixed(1)}" y1="${a[1].toFixed(1)}" x2="${b[0].toFixed(1)}" y2="${b[1].toFixed(1)}" stroke="${hit ? t("signal") : t("wall-hatch")}" stroke-width="${((hit ? 0.17 : 0.1) * v.scale).toFixed(1)}"/>`;
    }
    items.push({
      depth: v.depth(x + 0.5, y + 0.5),
      svg: `${svg}<g clip-path="url(#${clip})">${hatch}</g>`,
    });
  }

  // The guard: a tall diamond with a hazard top, so it is a different shape from every wall.
  if (state.guard) {
    const [gx, gy] = [state.guard.at[0] + 0.5, state.guard.at[1] + 0.5];
    const r = 0.31;
    const diamond = [
      [gx, gy - r],
      [gx + r, gy],
      [gx, gy + r],
      [gx - r, gy],
    ];
    const [ga, gb] = sides(t("ink"));
    const { svg, top } = prism(v, diamond, Z.floor, Z.guard, t("signal"), ga, gb, t("ink"));
    const clip = `k${id}_g`;
    defs += `<clipPath id="${clip}"><polygon points="${pts(top)}"/></clipPath>`;
    let stripes = "";
    for (let c = -0.5; c < 0.5; c += 0.22) {
      const [a, b] = [
        v.proj(gx + c - 0.4, gy - 0.4, Z.guard),
        v.proj(gx + c + 0.4, gy + 0.4, Z.guard),
      ];
      stripes += `<line x1="${a[0].toFixed(1)}" y1="${a[1].toFixed(1)}" x2="${b[0].toFixed(1)}" y2="${b[1].toFixed(1)}" stroke="${t("ink")}" stroke-width="${(0.08 * v.scale).toFixed(1)}"/>`;
    }
    const guardRing =
      hitKey === state.guard.at.join()
        ? `<polygon points="${pts(top)}" fill="none" stroke="${t("signal")}" stroke-width="3"/>`
        : "";
    items.push({
      depth: v.depth(gx, gy),
      svg: `${svg}<g clip-path="url(#${clip})">${stripes}</g>${guardRing}`,
    });
  }

  // The automaton: a chamfered block with the wedge on its top face.
  const [ax, ay, facing] = state.auto;
  const base = `${ax},${ay}` === goalKey ? Z.goal : Z.floor;
  const [i0, i1, ch] = [0.17, 0.83, 0.14];
  const body = [
    [ax + i0, ay + i0],
    [ax + i1 - ch, ay + i0],
    [ax + i1, ay + i0 + ch],
    [ax + i1, ay + i1],
    [ax + i0, ay + i1],
  ];
  const [aa, ab] = sides(t("ink"));
  const auto = prism(v, body, base, base + Z.auto, t("ink"), aa, ab, lighten(t("ink"), 0.1));
  const [dx, dy] = DIRS[facing];
  const [cx, cy] = [ax + 0.5, ay + 0.5];
  const [px, py] = [-dy, dx];
  const wedge = [
    [cx + dx * 0.27, cy + dy * 0.27],
    [cx - dx * 0.1 + px * 0.2, cy - dy * 0.1 + py * 0.2],
    [cx - dx * 0.1 - px * 0.2, cy - dy * 0.1 - py * 0.2],
  ].map((p) => v.proj(p[0], p[1], base + Z.auto + 0.003));
  const ring = state.hit
    ? `<polygon points="${pts(auto.top)}" fill="none" stroke="${t("signal")}" stroke-width="3"/>`
    : "";
  items.push({
    depth: v.depth(cx, cy),
    svg: `${auto.svg}${ring}<polygon points="${pts(wedge)}" fill="${t("signal")}"/>`,
  });

  items.sort((a, b) => a.depth - b.depth);
  return `<svg width="${box.w}" height="${box.h}" viewBox="0 0 ${box.w} ${box.h}" xmlns="http://www.w3.org/2000/svg"><defs>${defs}</defs>${under}${cellItems.join("")}${shadows}${route}${items.map((i) => i.svg).join("")}</svg>`;
}
