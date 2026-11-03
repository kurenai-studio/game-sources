/**
 * The painted field map: three canvases over the whole heightfield (+-GRID_HALF), drawn in world
 * metres with Canvas 2D, uploaded as textures for the terrain shader.
 *   A (sRGB colour): parcel colours, headlands, woods floor, village lawns and gardens, farm
 *     yards, hedge lines (the far LOD of the hedgerow meshes).
 *   B (data): r = road mask (blurred so the shader can rebuild a crisp edge at any zoom),
 *     g = mown-stripe amount, b = furrow / row amount.
 *   C (data, low res): r = row direction (0..PI), g = tramlines.
 */
import * as THREE from "three";
import { GRID_HALF, RIVER_PATH, ROAD_PATHS, lakeShore, riverHalfWidth } from "./layout";
import type { Edge, Parcel } from "./parcels";

export interface PaintShape {
  poly: [number, number][];
  color: string;
  mown?: number;
  furrow?: number;
  angle?: number;
  /** Outline (fences, walls) drawn over it, sRGB. */
  stroke?: string;
  strokeW?: number;
}

export interface GroundMap {
  a: THREE.Texture;
  b: THREE.Texture;
  c: THREE.Texture;
}

function canvas(n: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const cv = document.createElement("canvas");
  cv.width = cv.height = n;
  const ctx = cv.getContext("2d", { willReadFrequently: false })!;
  const s = n / (GRID_HALF * 2);
  ctx.setTransform(s, 0, 0, s, GRID_HALF * s, GRID_HALF * s);
  ctx.lineJoin = "round";
  ctx.lineCap = "round";
  return [cv, ctx];
}

function path(ctx: CanvasRenderingContext2D, poly: readonly (readonly [number, number])[], close = true): void {
  ctx.beginPath();
  ctx.moveTo(poly[0][0], poly[0][1]);
  for (let i = 1; i < poly.length; i++) ctx.lineTo(poly[i][0], poly[i][1]);
  if (close) ctx.closePath();
}

const v8 = (x: number) => Math.round(Math.max(0, Math.min(1, x)) * 255);
const HEADLAND: Record<string, string> = {
  wheat: "#a7b45e", barley: "#a9b766", rape: "#8fae4e", lavender: "#7ea452", plough: "#8a9a52", stubble: "#a8b062",
  young: "#8cae52", mown: "#8fb052", orchard: "#86ae50",
};

export function paintGroundMap(res: number, parcels: Parcel[], edges: Edge[], shapes: PaintShape[], hedgeLines: [number, number][][], noRoad: [number, number][][] = []): GroundMap {
  const [ca, A] = canvas(res);
  const [cb, B] = canvas(res);
  const lowRes = Math.max(512, res / 4);
  const [cc, C] = canvas(lowRes);
  const m = 1 / (res / (GRID_HALF * 2)); // metres per texel

  A.fillStyle = "#5e963e";
  A.fillRect(-GRID_HALF, -GRID_HALF, GRID_HALF * 2, GRID_HALF * 2);
  B.fillStyle = "#000000";
  B.fillRect(-GRID_HALF, -GRID_HALF, GRID_HALF * 2, GRID_HALF * 2);
  C.fillStyle = "#000000";
  C.fillRect(-GRID_HALF, -GRID_HALF, GRID_HALF * 2, GRID_HALF * 2);

  for (const p of parcels) {
    path(A, p.poly);
    A.fillStyle = p.color;
    A.fill();
    // Seal hairline gaps between neighbours.
    A.strokeStyle = p.color;
    A.lineWidth = m * 1.2;
    A.stroke();
    path(B, p.poly);
    B.fillStyle = `rgb(0,${v8(p.mown)},${v8(p.furrow)})`;
    B.fill();
    B.strokeStyle = B.fillStyle;
    B.lineWidth = m * 1.2;
    B.stroke();
    path(C, p.poly);
    const tram = p.crop === "wheat" || p.crop === "barley" || p.crop === "rape" || p.crop === "young" ? 1 : 0;
    C.fillStyle = `rgb(${v8(p.angle / Math.PI)},${v8(tram)},0)`;
    C.fill();
    C.strokeStyle = C.fillStyle;
    C.lineWidth = (GRID_HALF * 2) / lowRes * 1.5;
    C.stroke();
    // Headland: a ring of grass round the crop, with no rows in it.
    const hl = HEADLAND[p.crop];
    if (hl || p.crop === "pasture") {
      A.save();
      path(A, p.poly);
      A.clip();
      A.strokeStyle = hl ?? "#6aa446";
      A.globalAlpha = hl ? 1 : 0.35;
      A.lineWidth = hl ? 11 : 7;
      A.stroke();
      A.restore();
      B.save();
      path(B, p.poly);
      B.clip();
      B.strokeStyle = "#000000";
      B.lineWidth = 12;
      B.stroke();
      B.restore();
    }
  }

  // Village lawns, gardens, yards, churchyard.
  for (const s of shapes) {
    path(A, s.poly);
    A.fillStyle = s.color;
    A.fill();
    path(B, s.poly);
    B.fillStyle = `rgb(0,${v8(s.mown ?? 0)},${v8(s.furrow ?? 0)})`;
    B.fill();
    if (s.angle !== undefined) {
      path(C, s.poly);
      C.fillStyle = `rgb(${v8((((s.angle % Math.PI) + Math.PI) % Math.PI) / Math.PI)},0,0)`;
      C.fill();
    }
    if (s.stroke) {
      path(A, s.poly);
      A.strokeStyle = s.stroke;
      A.lineWidth = s.strokeW ?? 0.8;
      A.stroke();
    }
  }

  // Lake margin: a muddy strand, then reed beds in broken stretches of varying depth (the half
  // over the water is hidden under it).
  {
    const sh = lakeShore(360);
    A.strokeStyle = "#9a8a64";
    A.lineWidth = 6;
    path(A, sh);
    A.stroke();
    for (let i = 0; i < sh.length; i++) {
      const k = Math.sin(i * 0.11) * 0.5 + Math.sin(i * 0.37 + 1.7) * 0.35 + Math.sin(i * 0.05 + 4) * 0.4;
      if (k < -0.15) continue;
      const a = sh[i], b = sh[(i + 1) % sh.length];
      A.strokeStyle = k > 0.45 ? "#8a9a4a" : "#6a8a3c";
      A.lineWidth = 7 + 12 * Math.max(0, k);
      A.beginPath();
      A.moveTo(a[0], a[1]);
      A.lineTo(b[0], b[1]);
      A.stroke();
    }
  }
  // Gravel and mud bars on the inside of the river's bends.
  {
    const P = RIVER_PATH, n = P.length, K = 6;
    for (let i = K; i < n - K; i++) {
      const [ax, az] = P[i - K], [bx, bz] = P[i], [cx, cz] = P[i + K];
      const t1x = bx - ax, t1z = bz - az, t2x = cx - bx, t2z = cz - bz;
      const turn = Math.atan2(t1x * t2z - t1z * t2x, t1x * t2x + t1z * t2z);
      // Local maxima of the bend only.
      const turnAt = (j: number) => {
        const [px, pz] = P[j - K], [qx, qz] = P[j], [rx, rz] = P[j + K];
        const u1x = qx - px, u1z = qz - pz, u2x = rx - qx, u2z = rz - qz;
        return Math.abs(Math.atan2(u1x * u2z - u1z * u2x, u1x * u2x + u1z * u2z));
      };
      if (Math.abs(turn) < 0.22 || i < K + 1 || i > n - K - 2 || turnAt(i - 1) > Math.abs(turn) || turnAt(i + 1) > Math.abs(turn)) continue;
      const tl = Math.hypot(cx - ax, cz - az) || 1;
      const tx = (cx - ax) / tl, tz = (cz - az) / tl;
      // Inside of the bend: the side the path turns toward.
      const side = turn > 0 ? 1 : -1;
      const nx = -tz * side, nz = tx * side;
      const hw = riverHalfWidth(i, n - 1);
      A.save();
      A.translate(bx + nx * (hw + 1.5), bz + nz * (hw + 1.5));
      A.rotate(Math.atan2(tz, tx));
      A.fillStyle = "#cdbb94";
      A.beginPath();
      A.ellipse(0, 0, 26 + 30 * Math.min(1, Math.abs(turn)), 5.5, 0, 0, Math.PI * 2);
      A.fill();
      A.fillStyle = "#b8a47c";
      A.beginPath();
      A.ellipse(0, side * 1.5, 18, 2.5, 0, 0, Math.PI * 2);
      A.fill();
      A.restore();
    }
  }

  // Hedge lines (the hedgerow meshes' far LOD and the dark ground under them).
  A.strokeStyle = "#35602e";
  A.lineWidth = 2.8;
  for (const l of hedgeLines) {
    path(A, l, false);
    A.stroke();
  }
  // Unhedged boundaries still read as a slightly darker grassy margin.
  A.strokeStyle = "rgba(40,70,30,0.25)";
  A.lineWidth = 2.5;
  for (const e of edges) {
    if (e.hedge) continue;
    if (parcels[e.p].crop === "village" || (e.q >= 0 && parcels[e.q].crop === "village")) continue;
    A.beginPath();
    A.moveTo(e.a[0], e.a[1]);
    A.lineTo(e.b[0], e.b[1]);
    A.stroke();
  }

  // Roads: soft-edged mask (thresholded at 0.5 in the shader = the true edge), added on top.
  B.globalCompositeOperation = "lighter";
  B.strokeStyle = "#ff0000";
  B.filter = `blur(${Math.max(1, 1.6 * (res / 4096))}px)`;
  for (const r of ROAD_PATHS) {
    path(B, r.path, false);
    B.lineWidth = r.w;
    B.stroke();
  }
  B.filter = "none";
  B.globalCompositeOperation = "source-over";
  // Paved over (the market square): no road there.
  for (const p of noRoad) {
    path(B, p);
    B.fillStyle = "#000000";
    B.fill();
  }

  const tex = (cv: HTMLCanvasElement, srgb: boolean) => {
    const t = new THREE.CanvasTexture(cv);
    t.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
    t.wrapS = t.wrapT = THREE.ClampToEdgeWrapping;
    t.magFilter = THREE.LinearFilter;
    t.minFilter = THREE.LinearMipmapLinearFilter;
    t.anisotropy = 8;
    t.generateMipmaps = true;
    t.flipY = false;
    return t;
  };
  return { a: tex(ca, true), b: tex(cb, false), c: tex(cc, false) };
}
