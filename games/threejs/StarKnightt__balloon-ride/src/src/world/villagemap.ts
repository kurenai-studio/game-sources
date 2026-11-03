/**
 * The village detail map: a fine (~0.23 m/texel) painted ground texture over the village only,
 * on top of the 2 m field map. It carries what the field map is too coarse for: rough meadow
 * mottling under everything, garden plots (lawn stripes, veg rows, paths, patios, flower borders),
 * orchards, paddocks, allotments, farm yards, the paved market square, the green with its footpath,
 * the churchyard and its paths, and crisp lanes with verges and a worn centre.
 *
 * Two textures: colour (sRGB, opaque) and a coverage mask (where the detail replaces the field map).
 */
import * as THREE from "three";
import { mulberry32, pick, range } from "../core/rng";
import { ROAD_PATHS, VILLAGE } from "./layout";
import type { PaintOp, Rect, VillagePlan } from "./villageplan";

/** World square the detail map covers (centre and half size, m). */
export const VMAP = { x: 0, z: 0, half: 400 } as const;

type Ctx = CanvasRenderingContext2D;

function canvas(n: number): [HTMLCanvasElement, Ctx] {
  const cv = document.createElement("canvas");
  cv.width = cv.height = n;
  const ctx = cv.getContext("2d")!;
  return [cv, ctx];
}

/** World → canvas transform for this map. */
function world(ctx: Ctx, n: number): void {
  const s = n / (VMAP.half * 2);
  ctx.setTransform(s, 0, 0, s, (VMAP.half - VMAP.x) * s, (VMAP.half - VMAP.z) * s);
}

/** Enter a rect's local frame (local x, z drawn as canvas x, y). */
function local(ctx: Ctx, n: number, R: Rect): void {
  world(ctx, n);
  ctx.translate(R.cx, R.cz);
  ctx.rotate(-R.yaw);
}

const LAWN = ["#86b852", "#80b44e", "#8cbc56", "#7aae4a", "#90be5a"];
const SOIL = ["#8a6a44", "#7e5f3e", "#957250", "#86683f"];
const CROPROW = ["#5d8f3a", "#4f8434", "#6f9a7a", "#7aa246", "#a8a24a", "#5a8a5a"];
const FLOWERS = ["#e8a0b8", "#f0d060", "#f4f0e8", "#c86a8a", "#9a7ad0", "#f0a050"];

function rows(ctx: Ctx, x0: number, x1: number, z0: number, z1: number, gap: number, w: number, color: string, alongX: boolean): void {
  ctx.strokeStyle = color;
  ctx.lineWidth = w;
  ctx.beginPath();
  if (alongX) for (let z = z0 + gap / 2; z < z1; z += gap) { ctx.moveTo(x0 + 0.3, z); ctx.lineTo(x1 - 0.3, z); }
  else for (let x = x0 + gap / 2; x < x1; x += gap) { ctx.moveTo(x, z0 + 0.3); ctx.lineTo(x, z1 - 0.3); }
  ctx.stroke();
}

function dots(ctx: Ctx, r: () => number, x0: number, x1: number, z0: number, z1: number, n: number, rad: [number, number], colors: string[], alpha = 1): void {
  ctx.globalAlpha = alpha;
  for (let i = 0; i < n; i++) {
    ctx.fillStyle = pick(r, colors);
    ctx.beginPath();
    ctx.arc(range(r, x0, x1), range(r, z0, z1), range(r, rad[0], rad[1]), 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.globalAlpha = 1;
}

function paintOp(ctx: Ctx, n: number, op: PaintOp): void {
  const r = mulberry32(op.seed);
  const R = op.R;
  local(ctx, n, R);
  const { x0, x1, z0, z1 } = R;
  const w = x1 - x0, d = z1 - z0;
  const fill = (c: string, a = x0, b = z0, ww = w, dd = d) => {
    ctx.fillStyle = c;
    ctx.fillRect(a, b, ww, dd);
  };
  switch (op.kind) {
    case "garden": {
      // z1 is the house end, z0 the far end.
      fill(pick(r, LAWN));
      // Mown stripes across the lawn.
      ctx.globalAlpha = 0.16;
      for (let z = z0; z < z1; z += 2.4) fill("#d8f0a0", x0, z, w, 1.2);
      ctx.globalAlpha = 1;
      // Patio by the house.
      fill(pick(r, ["#cdbd9a", "#c4b08c", "#d6c8a8"]), x0, z1 - 2.6, w, 2.6);
      // Flower borders down both sides.
      dots(ctx, r, x0 + 0.2, x0 + 1.1, z0 + 1, z1 - 3, Math.ceil(d * 1.2), [0.18, 0.4], [...FLOWERS, "#4f8434", "#4f8434"], 0.95);
      dots(ctx, r, x1 - 1.1, x1 - 0.2, z0 + 1, z1 - 3, Math.ceil(d * 1.2), [0.18, 0.4], [...FLOWERS, "#4f8434", "#4f8434"], 0.95);
      if (op.veg) {
        const vz1 = z0 + d * op.veg;
        fill(pick(r, SOIL), x0 + 0.8, z0 + 0.8, w - 1.6, vz1 - z0 - 0.8);
        // Rows of crops across the plot, in two or three crops.
        const parts = 2 + Math.floor(r() * 2);
        for (let k = 0; k < parts; k++) {
          const za = z0 + 0.8 + ((vz1 - z0 - 0.8) * k) / parts, zb = z0 + 0.8 + ((vz1 - z0 - 0.8) * (k + 1)) / parts;
          if (r() < 0.15) continue; // a bare dug bed
          rows(ctx, x0 + 1.0, x1 - 1.0, za, zb, range(r, 0.7, 1.0), range(r, 0.3, 0.45), pick(r, CROPROW), true);
        }
      }
      if (op.path !== undefined && !Number.isNaN(op.path)) fill(pick(r, ["#d8c8a4", "#cfbf98"]), op.path - 0.45, z0 + 0.5, 0.9, d - 0.5);
      break;
    }
    case "front": {
      fill(pick(r, LAWN));
      dots(ctx, r, x0 + 0.2, x1 - 0.2, z0 + 0.2, z0 + 1.0, Math.ceil(w * 1.4), [0.2, 0.4], FLOWERS, 1);
      dots(ctx, r, x0 + 0.2, x1 - 0.2, z1 - 1.0, z1 - 0.2, Math.ceil(w * 1.2), [0.2, 0.45], [...FLOWERS, "#4f8434"], 1);
      fill("#d6c6a0", -0.6, z0, 1.2, d);
      break;
    }
    case "orchard": {
      fill(pick(r, ["#90bc5a", "#8ab656", "#96c060"]));
      // Long grass between mown alleys under the rows.
      ctx.globalAlpha = 0.25;
      for (let z = z0 + 3.5; z < z1 - 2; z += 6) fill("#6a9a40", x0 + 1, z - 1.4, w - 2, 2.8);
      ctx.globalAlpha = 1;
      dots(ctx, r, x0, x1, z0, z1, Math.ceil(w * d * 0.05), [0.12, 0.25], ["#f4f0e0", "#f0d860"], 0.8);
      break;
    }
    case "paddock": {
      fill(pick(r, ["#78a646", "#80aa4a", "#729e44"]));
      // Tussocks and darker rushy patches.
      dots(ctx, r, x0, x1, z0, z1, Math.ceil(w * d * 0.12), [0.3, 0.7], ["#5e8a38", "#6a9640", "#8ab452"], 0.7);
      // A worn track from the gate and a poached patch by it.
      ctx.fillStyle = "#a08a62";
      ctx.globalAlpha = 0.8;
      ctx.beginPath();
      ctx.ellipse((x0 + x1) / 2, z0 + 2.5, 3.5, 2.2, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 0.45;
      fill("#a89470", (x0 + x1) / 2 - 0.8, z0, 1.6, d * 0.6);
      ctx.globalAlpha = 1;
      break;
    }
    case "allot": {
      fill("#b6a47c");
      // Plots 5 m wide along x, grass paths between.
      for (let x = x0 + 0.8; x < x1 - 1; x += 5) {
        const pw = Math.min(4.2, x1 - 0.8 - x);
        const kind = r();
        if (kind < 0.2) fill(pick(r, LAWN), x, z0 + 0.8, pw, d - 5);
        else {
          fill(pick(r, SOIL), x, z0 + 0.8, pw, d - 5);
          if (kind > 0.3) {
            const split = z0 + 0.8 + (d - 5) * range(r, 0.3, 0.7);
            rows(ctx, x + 0.3, x + pw - 0.3, z0 + 0.8, split, range(r, 0.6, 0.9), 0.32, pick(r, CROPROW), false);
            if (r() < 0.8) rows(ctx, x + 0.3, x + pw - 0.3, split + 0.4, z1 - 4.2, range(r, 0.6, 0.9), 0.38, pick(r, CROPROW), false);
          }
        }
      }
      fill("#86b250", x0, z1 - 4, w, 4);
      break;
    }
    case "yard": {
      fill(pick(r, ["#b9a27a", "#b09a74", "#c0aa82"]));
      dots(ctx, r, x0, x1, z0, z1, Math.ceil(w * d * 0.04), [0.4, 1.4], ["#a08a64", "#c8b48c", "#9a8660"], 0.5);
      // Straw spread by the barn door.
      ctx.globalAlpha = 0.6;
      fill("#d8c070", x0 + w * 0.3, z0 + 10, w * 0.4, 3);
      ctx.globalAlpha = 1;
      break;
    }
    case "copse": {
      fill(pick(r, ["#5f8a3e", "#5a843a", "#668e42"]));
      dots(ctx, r, x0, x1, z0, z1, Math.ceil(w * d * 0.08), [0.4, 1.0], ["#4c7432", "#6e9446", "#7a7040"], 0.6);
      break;
    }
    case "meadow": {
      fill(pick(r, ["#92bc58", "#8cb654"]));
      dots(ctx, r, x0, x1, z0, z1, Math.ceil(w * d * 0.15), [0.12, 0.3], ["#f4f0e0", "#f0d860", "#e8a0b8", "#7aa646"], 0.8);
      break;
    }
    case "square": {
      // Warm flagstones with darker joints, a cobbled border and a central ring round the cross.
      fill("#e0cca4");
      ctx.strokeStyle = "rgba(120,96,64,0.5)";
      ctx.lineWidth = 0.08;
      ctx.beginPath();
      for (let x = x0; x <= x1; x += 1.4) { ctx.moveTo(x, z0); ctx.lineTo(x, z1); }
      for (let z = z0; z <= z1; z += 1.0) { ctx.moveTo(x0, z); ctx.lineTo(x1, z); }
      ctx.stroke();
      dots(ctx, r, x0, x1, z0, z1, Math.ceil(w * d * 0.3), [0.25, 0.6], ["#d0bc94", "#e6d4ae", "#d6c29a", "#c8b48e"], 0.6);
      ctx.strokeStyle = "#a8906a";
      ctx.lineWidth = 1.6;
      ctx.strokeRect(x0 + 0.7, z0 + 0.7, w - 1.4, d - 1.4);
      break;
    }
    case "green": {
      // The ellipse inside the rect: stripes, a footpath ring and two crossing paths.
      const rx = (w - 6) / 2, rz = (d - 6) / 2;
      ctx.save();
      ctx.beginPath();
      ctx.ellipse(0, 0, rx, rz, 0, 0, Math.PI * 2);
      ctx.clip();
      fill("#98c85c");
      ctx.globalAlpha = 0.18;
      for (let x = x0; x < x1; x += 3) fill("#e4f8b0", x, z0, 1.5, d);
      ctx.globalAlpha = 1;
      ctx.strokeStyle = "#d8c8a0";
      ctx.lineWidth = 1.3;
      ctx.beginPath();
      ctx.moveTo(-rx, -rz * 0.3); ctx.lineTo(rx, rz * 0.4);
      ctx.moveTo(-rx * 0.2, -rz); ctx.lineTo(rx * 0.1, rz);
      ctx.stroke();
      ctx.restore();
      ctx.strokeStyle = "#d6c49c";
      ctx.lineWidth = 2.0;
      ctx.beginPath();
      ctx.ellipse(0, 0, rx + 1.5, rz + 1.5, 0, 0, Math.PI * 2);
      ctx.stroke();
      break;
    }
    case "churchyard": {
      fill("#7cae50");
      ctx.globalAlpha = 0.14;
      for (let z = z0; z < z1; z += 2) fill("#d8f0a0", x0, z, w, 1);
      ctx.globalAlpha = 1;
      // Gravel path from the lychgate to the porch and round the church.
      fill("#d4c8aa", -1.2, 7, 2.4, z1 - 7);
      ctx.strokeStyle = "#d4c8aa";
      ctx.lineWidth = 1.6;
      ctx.strokeRect(-21, -8.5, 41, 17);
      break;
    }
    case "path": {
      fill("#d6c8a6");
      ctx.fillStyle = "#6c9444";
      ctx.fillRect(x0 - 0.4, z0, 0.4, d);
      ctx.fillRect(x1, z0, 0.4, d);
      break;
    }
  }
}

export interface VillageMap {
  color: THREE.Texture;
  mask: THREE.Texture;
}

export function paintVillageMap(plan: VillagePlan, res = 3072): VillageMap {
  const [cv, C] = canvas(res);
  const mres = 1024;
  const [mv, Mk] = canvas(mres);
  const r = mulberry32(911);

  // Rough village meadow under everything, mottled at several sizes.
  world(C, res);
  C.fillStyle = "#82ae4c";
  C.fillRect(VMAP.x - VMAP.half, VMAP.z - VMAP.half, VMAP.half * 2, VMAP.half * 2);
  const H = VMAP.half;
  dots(C, r, -H, H, -H, H, 2600, [4, 10], ["#78a446", "#8cb654", "#7ea84a", "#86ae4e"], 0.5);
  dots(C, r, -H, H, -H, H, 16000, [0.8, 2.2], ["#6e9a40", "#94bc58", "#7aa446", "#a2c060"], 0.45);

  // Coverage: the village disc (soft edge), then every op wherever it lies.
  world(Mk, mres);
  Mk.fillStyle = "#000";
  Mk.fillRect(-H, -H, H * 2, H * 2);
  const grad = Mk.createRadialGradient(VILLAGE.x, VILLAGE.z, VILLAGE.r * 0.9, VILLAGE.x, VILLAGE.z, VILLAGE.r * 1.02);
  grad.addColorStop(0, "#fff");
  grad.addColorStop(1, "#000");
  Mk.fillStyle = grad;
  Mk.beginPath();
  Mk.arc(VILLAGE.x, VILLAGE.z, VILLAGE.r * 1.02, 0, Math.PI * 2);
  Mk.fill();

  for (const op of plan.paint) {
    paintOp(C, res, op);
    local(Mk, mres, op.R);
    Mk.fillStyle = "#fff";
    Mk.fillRect(op.R.x0 - 0.6, op.R.z0 - 0.6, op.R.x1 - op.R.x0 + 1.2, op.R.z1 - op.R.z0 + 1.2);
  }

  // Hedge and wall footprints: a dark green or stone line under the meshes (and their far LOD).
  world(C, res);
  C.lineCap = "round";
  for (const b of plan.bounds) {
    C.strokeStyle = b.kind === "hedge" ? "#3e6a34" : "#b8a684";
    C.lineWidth = b.kind === "hedge" ? 1.3 : 0.7;
    C.beginPath();
    C.moveTo(b.a[0], b.a[1]);
    C.lineTo(b.b[0], b.b[1]);
    C.stroke();
  }

  // Crisp lanes: grassy verge, warm surface, worn wheel tracks (a grass crown on the narrow lanes).
  world(Mk, mres);
  for (const rd of ROAD_PATHS) {
    const p = rd.path;
    const trace = (ctx: Ctx) => {
      ctx.beginPath();
      ctx.moveTo(p[0][0], p[0][1]);
      for (let i = 1; i < p.length; i++) ctx.lineTo(p[i][0], p[i][1]);
    };
    C.lineJoin = "round";
    trace(C);
    C.strokeStyle = "#6a9242";
    C.lineWidth = rd.w + 1.8;
    C.stroke();
    C.strokeStyle = "#d2bc94";
    C.lineWidth = rd.w;
    C.stroke();
    if (rd.w <= 4.5) {
      C.strokeStyle = "#a4ae70";
      C.lineWidth = 0.55;
      C.stroke();
    } else {
      C.strokeStyle = "rgba(150,124,88,0.55)";
      C.lineWidth = rd.w * 0.5 + 0.8;
      C.stroke();
      C.strokeStyle = "#d2bc94";
      C.lineWidth = rd.w * 0.5 - 0.8;
      C.stroke();
    }
    // Inside the coverage the detail map draws the road; outside it the field map does.
  }
  // The green's footpath ring and the square on top of the roads.
  for (const op of plan.paint) if (op.kind === "square") paintOp(C, res, op);

  const tex = (c: HTMLCanvasElement, srgb: boolean) => {
    const t = new THREE.CanvasTexture(c);
    t.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
    t.wrapS = t.wrapT = THREE.ClampToEdgeWrapping;
    t.minFilter = THREE.LinearMipmapLinearFilter;
    t.magFilter = THREE.LinearFilter;
    t.anisotropy = 8;
    t.flipY = false;
    return t;
  };
  return { color: tex(cv, true), mask: tex(mv, false) };
}
