/**
 * The balloon model (public/models/balloon.glb, scripted in Blender by tools/balloon.py) dressed in
 * the toon uber material, plus the burner flame. Each glTF part maps to its own surface and outline
 * group; the envelope's vertex colours are recoloured per palette for the other balloons.
 *
 * Model space (after the glTF Y-up conversion): origin = centre of the basket floor, y up, metres.
 * Basket top 1.12 m, burner frame 2.55 m, burner nozzles ~2.94 m, envelope mouth 5 m, crown 20.5 m.
 */
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { COMMON, G, specializeUber, uber } from "../render/materials";
import { ID, M, prep } from "../world/geo";
import { LAYER_REFLECT, LAYER_SHADOW, onLayers } from "../render/lightpasses";

export const BALLOON = {
  basketTop: 1.12,
  frameY: 2.55,
  nozzleY: 2.94,
  nozzleX: 0.19,
  mouthY: 5.0,
  crownY: 20.48,
  /** Envelope centre (orbit target, sway pivot). */
  centreY: 13.5,
  radius: 7.6,
} as const;

/** Part name → surface (uber branch), outline group, ink mask, double-sided. */
const PARTS: Record<string, { mat: number; id: number; mask: number; double: boolean }> = {
  envelope: { mat: M.cloth, id: ID.boat, mask: 1, double: true },
  skirt: { mat: M.cloth, id: ID.motor, mask: 0.8, double: true },
  basket: { mat: M.wicker, id: ID.house, mask: 0.8, double: false },
  leather: { mat: M.plain, id: ID.pole, mask: 0.8, double: false },
  frame: { mat: M.metal, id: ID.pole, mask: 0.6, double: false },
  burner: { mat: M.metal, id: ID.motor, mask: 0.6, double: false },
  // Thin wires draw no ink (a line round a 4 cm wire would be thicker than the wire).
  wires: { mat: M.plain, id: ID.wire, mask: -1, double: false },
};

/** The envelope's authored colours (sRGB hex, tools/balloon.py) in slot order. */
const SLOTS = ["#c8322b", "#f3e6c8", "#1f8a86", "#e9a92a", "#8e2420"];
/** The player's palette (stripe A, stripe B between, stripe C, band, mouth/trim): the authored one with a truer teal. */
export const PLAYER_PALETTE = ["#c8322b", "#f3e6c8", "#0d8fa0", "#e9a92a", "#8e2420"];

/**
 * The other balloons' patterns, painted per triangle from the envelope's own coordinates: u = 0 at
 * the mouth .. 1 at the crown, g = gore index (0..19), ga = 0..1 across the gore. Each one is a bold,
 * saturated design that still reads as a speck at 1-2 km (a festival, not five copies).
 */
type Pattern = { trim: string; at: (u: number, g: number, ga: number) => string };
export const PATTERNS: Pattern[] = [
  // Blue and yellow chevrons.
  { trim: "#1b2f66", at: (u, _g, ga) => (u > 0.9 ? "#2152b4" : Math.floor(u * 8 + Math.abs(ga - 0.5) * 1.4) % 2 ? "#f4c531" : "#2152b4") },
  // Rainbow gores.
  { trim: "#3a2350", at: (_u, g) => ["#d8312c", "#ee7a22", "#f4c22e", "#86b83a", "#2e9a52", "#1c95a8", "#2a64b8", "#5a46a8", "#8e3c9e", "#d23a78"][g % 10] },
  // Red and white gores under a red crown.
  { trim: "#7e1714", at: (u, g) => (u > 0.86 || g % 2 ? "#cf2a25" : "#f7f1e6") },
  // Green with a ring of gold diamonds and a gold crown.
  { trim: "#1d4a2a", at: (u, _g, ga) => (u > 0.9 ? "#e9b52c" : Math.abs(ga - 0.5) * 2 + Math.abs((u - 0.55) / 0.12) < 1 || Math.abs(u - 0.36) < 0.025 || Math.abs(u - 0.74) < 0.025 ? "#ecb92e" : "#2f8a45") },
  // Purple and orange spiral.
  { trim: "#3b1d52", at: (u, g, ga) => (Math.floor(g + ga + u * 6) % 2 ? "#ef7d22" : "#6a3a9e") },
];

const toLin = (hex: string, k = 1) => {
  const c = new THREE.Color(hex);
  // Blender darkened the load tapes in sRGB before linearising.
  c.convertLinearToSRGB();
  c.setRGB(c.r * k, c.g * k, c.b * k);
  return c.convertSRGBToLinear();
};

let template: THREE.Group | null = null;

/** Load the glTF once; resolves to the shared template (do not add it to the scene). */
export async function loadBalloon(url = `${import.meta.env.BASE_URL}models/balloon.glb`): Promise<THREE.Group> {
  if (template) return template;
  const gltf = await new GLTFLoader().loadAsync(url);
  const root = new THREE.Group();
  root.name = "balloon template";
  gltf.scene.updateMatrixWorld(true);
  gltf.scene.traverse((o) => {
    const mesh = o as THREE.Mesh;
    if (!mesh.isMesh) return;
    const name = (mesh.name || (mesh.material as THREE.Material).name || "").replace(/\.\d+$/, "");
    const part = PARTS[name] ?? PARTS[(mesh.material as THREE.Material).name] ?? PARTS.basket;
    const g = mesh.geometry.clone();
    g.applyMatrix4(mesh.matrixWorld);
    // COLOR_0 may arrive as normalised shorts or with alpha: the uber wants float rgb.
    const src = g.getAttribute("color") as THREE.BufferAttribute | undefined;
    const n = g.getAttribute("position").count;
    const col = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) {
      col[i * 3] = src ? src.getX(i) : 1;
      col[i * 3 + 1] = src ? src.getY(i) : 1;
      col[i * 3 + 2] = src ? src.getZ(i) : 1;
    }
    g.deleteAttribute("color");
    g.setAttribute("color", new THREE.BufferAttribute(col, 3));
    // The wicker reads honey-brown and the weave darker than the authored tan (a roof-tile orange
    // under the low sun otherwise).
    if (name === "basket") for (let i = 0; i < n; i++) { col[i * 3] *= 0.9; col[i * 3 + 1] *= 0.8; col[i * 3 + 2] *= 0.58; }
    prep(g, null, part.mat);
    const m = new THREE.Mesh(g, uber(part.id, part.mask, part.double ? THREE.DoubleSide : THREE.FrontSide));
    m.name = name;
    m.frustumCulled = true;
    root.add(m);
  });
  specializeUber(root);
  template = root;
  return root;
}

/**
 * In-game rigging on the player's basket (the basket view's frame): a fat padded suede roll round
 * the rim, quilted in pillows, and a coiled handling rope hung inside each side by a corner.
 */
function rigging(_tpl: THREE.Group): THREE.Group {
  const grp = new THREE.Group();
  grp.name = "rigging";
  const BH = BALLOON.basketTop, H = 0.6, CR = 0.14;
  // Rounded-square path round the rim (outer top edge), sampled evenly.
  const path: THREE.Vector3[] = [], out: THREE.Vector3[] = [];
  const side = 2 * (H - CR), per = 4 * side + Math.PI * 2 * CR;
  const N = 240;
  for (let i = 0; i < N; i++) {
    let s = (i / N) * per;
    let k = 0;
    while (s > side + (Math.PI / 2) * CR) { s -= side + (Math.PI / 2) * CR; k++; }
    const ang = (k * Math.PI) / 2;
    const ca = Math.cos(ang), sa = Math.sin(ang);
    let lx: number, lz: number, nx: number, nz: number;
    if (s < side) { lx = H; lz = -side / 2 + s; nx = 1; nz = 0; }
    else {
      const a = (s - side) / CR;
      lx = H - CR + Math.cos(a) * CR; lz = side / 2 + Math.sin(a) * CR; nx = Math.cos(a); nz = Math.sin(a);
    }
    path.push(new THREE.Vector3(lx * ca - lz * sa, BH + 0.025, lx * sa + lz * ca));
    out.push(new THREE.Vector3(nx * ca - nz * sa, 0, nx * sa + nz * ca));
  }
  const RS = 12;
  const pos: number[] = [], idx: number[] = [];
  for (let i = 0; i < N; i++) {
    const s = (i / N) * per;
    const pillow = Math.sin(Math.PI * ((s / 0.17) % 1));
    const r = 0.06 * (0.86 + 0.16 * pillow);
    for (let j = 0; j < RS; j++) {
      const a = (j / RS) * Math.PI * 2;
      const o = out[i];
      const pnt = path[i].clone().addScaledVector(o, Math.cos(a) * r - 0.015).add(new THREE.Vector3(0, Math.sin(a) * r * 1.05, 0));
      pos.push(pnt.x, pnt.y, pnt.z);
    }
  }
  for (let i = 0; i < N; i++)
    for (let j = 0; j < RS; j++) {
      const a = i * RS + j, b = ((i + 1) % N) * RS + j, c = ((i + 1) % N) * RS + ((j + 1) % RS), d = i * RS + ((j + 1) % RS);
      idx.push(a, b, c, a, c, d);
    }
  const rg = new THREE.BufferGeometry();
  rg.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  rg.setIndex(idx);
  rg.computeVertexNormals();
  const roll = new THREE.Mesh(prep(rg.toNonIndexed(), "#6b3c20", M.cloth), uber(ID.pole, 0.8));
  roll.geometry.computeVertexNormals();
  roll.name = "rim pad";
  grp.add(roll);
  // Coiled handling ropes, one inside each side near its left-hand corner.
  const coil = new THREE.TorusGeometry(0.1, 0.012, 6, 22);
  for (let k = 0; k < 4; k++) {
    const ang = (k * Math.PI) / 2;
    for (let l = 0; l < 3; l++) {
      const g = prep(coil.clone(), l === 1 ? "#b8955f" : "#c9a873", M.plain);
      const m = new THREE.Mesh(g, uber(ID.pole, 0.6));
      const lx = H - 0.1 - l * 0.008, lz = -H + 0.3 + l * 0.02;
      m.position.set(lx * Math.cos(ang) - lz * Math.sin(ang), BH - 0.14 - l * 0.012, lx * Math.sin(ang) + lz * Math.cos(ang));
      m.rotation.set(0, -ang + Math.PI / 2, 0.15 * (l - 1));
      grp.add(m);
    }
  }
  specializeUber(grp);
  return grp;
}

/** Nearest authored slot (index, tape darkening k) of a linear vertex colour. */
function authored(r: number, g: number, b: number): [number, number] {
  let best = 0, bk = 1, bd = Infinity;
  SLOTS.forEach((hex, i) => {
    for (const k of [1, 0.8]) {
      const c = toLin(hex, k);
      const d = (r - c.r) ** 2 + (g - c.g) ** 2 + (b - c.b) ** 2;
      if (d < bd) (bd = d), (best = i), (bk = k);
    }
  });
  return [best, bk];
}

/** Recolour an envelope geometry's vertex colours from the authored palette to `pal` (in place). */
function recolour(g: THREE.BufferGeometry, pal: string[]): void {
  const a = g.getAttribute("color") as THREE.BufferAttribute;
  for (let i = 0; i < a.count; i++) {
    const [slot, k] = authored(a.getX(i), a.getY(i), a.getZ(i));
    const c = toLin(pal[slot], k);
    a.setXYZ(i, c.r, c.g, c.b);
  }
  a.needsUpdate = true;
}

/** Paint pattern `p` on an envelope geometry, one colour per triangle; returns the new (non-indexed) geometry. */
function paintPattern(src: THREE.BufferGeometry, p: Pattern): THREE.BufferGeometry {
  const g = src.index ? src.toNonIndexed() : src.clone();
  const pos = g.getAttribute("position") as THREE.BufferAttribute;
  const col = g.getAttribute("color") as THREE.BufferAttribute;
  const n = pos.count / 3;
  const STEP = (Math.PI * 2) / 20;
  const tri: { a: number; u: number; k: number }[] = [];
  // The load tapes (darkened in the authored colours) mark the gore seams: find their angle offset.
  let sx = 0, sy = 0;
  for (let t = 0; t < n; t++) {
    let x = 0, y = 0, z = 0, r = 0, gg = 0, b = 0;
    for (let v = t * 3; v < t * 3 + 3; v++) {
      x += pos.getX(v); y += pos.getY(v); z += pos.getZ(v);
      r += col.getX(v); gg += col.getY(v); b += col.getZ(v);
    }
    const [, k] = authored(r / 3, gg / 3, b / 3);
    const a = Math.atan2(x, z);
    tri.push({ a, u: (y / 3 - BALLOON.mouthY) / (BALLOON.crownY - BALLOON.mouthY), k });
    if (k < 1) {
      const ph = (a / STEP) * Math.PI * 2;
      sx += Math.cos(ph);
      sy += Math.sin(ph);
    }
  }
  const off = (Math.atan2(sy, sx) / (Math.PI * 2)) * STEP;
  const cache = new Map<string, THREE.Color>();
  const lin = (hex: string, k: number) => {
    const key = hex + k;
    let c = cache.get(key);
    if (!c) cache.set(key, (c = toLin(hex, k)));
    return c;
  };
  tri.forEach((t, i) => {
    const gf = (t.a - off) / STEP;
    const gi = ((Math.floor(gf) % 20) + 20) % 20;
    const hex = t.u < 0.045 ? p.trim : p.at(Math.min(1, Math.max(0, t.u)), gi, gf - Math.floor(gf));
    const c = lin(hex, t.k);
    for (let v = i * 3; v < i * 3 + 3; v++) col.setXYZ(v, c.r, c.g, c.b);
  });
  col.needsUpdate = true;
  return g;
}

// ------------------------------------------------------------------ flame

const FLAME_VS = /* glsl */ `
${COMMON}
uniform float uFlame;   // 0 = pilot light only .. 1 = full burn
uniform float uSeed;
out vec3 vWPos;
out vec3 vN;
out float vH;
void main(){
  float h = position.y;            // 0 at the nozzle .. 1 at the tip
  float t = uTime * 9.0 + uSeed * 10.0;
  float len = mix(0.16, 2.3 + 0.35 * sin(t * 1.3) + 0.2 * sin(t * 3.1), uFlame);
  vec3 p = position;
  // Tongue: narrow at the nozzle, swelling, then licking to a point; it wavers at the tip.
  float w = mix(0.7, 0.85, uFlame) * (0.3 + 0.75 * sin(3.14159 * pow(h, 0.6)) * (1.0 - 0.45 * h));
  p.xz *= w;
  p.x += sin(t * 1.7 + h * 4.0) * 0.06 * h * h * uFlame;
  p.z += cos(t * 1.3 + h * 5.0) * 0.06 * h * h * uFlame;
  p.y = h * len;
  vec4 wp = modelMatrix * vec4(p, 1.0);
  vWPos = wp.xyz;
  vN = normalize(mat3(modelMatrix) * vec3(normal.x, 0.0, normal.z));
  vH = h;
  gl_Position = projectionMatrix * viewMatrix * wp;
}`;

const FLAME_FS = /* glsl */ `
${COMMON}
layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
uniform float uFlame;
uniform float uSeed;
in vec3 vWPos;
in vec3 vN;
in float vH;
void main(){
  vec3 V = normalize(cameraPosition - vWPos);
  float edge = abs(dot(normalize(vN), V));
  float n = vnoise(vec2(vH * 6.0 - uTime * 7.0, atan(vN.z, vN.x) * 2.0 + uSeed * 9.0));
  // Blue at the root, a white-gold core, orange licking out to the tip.
  vec3 blue = vec3(0.2, 0.42, 1.5);
  vec3 core = vec3(1.35, 0.95, 0.38);
  vec3 orange = vec3(1.3, 0.42, 0.08);
  float hb = mix(0.65, 0.2, uFlame);
  vec3 c = mix(blue, core, smoothstep(0.05, hb, vH));
  c = mix(c, orange, smoothstep(0.3, 0.8, vH + (n - 0.5) * 0.3));
  float a = smoothstep(0.0, 0.55, edge) * (1.0 - smoothstep(0.7, 1.0, vH + (n - 0.5) * 0.35)) * smoothstep(0.0, 0.04, vH);
  a *= mix(0.9, 1.0, n);
  gColor = vec4(c * a * mix(0.8, 0.7, uFlame), 1.0);
  gNormal = vec4(0.0);
}`;

function flameGeometry(): THREE.BufferGeometry {
  // A unit lathe (radius 0.17 at its widest after the vertex shader's swell, y = 0..1).
  const pts: THREE.Vector2[] = [];
  for (let i = 0; i <= 14; i++) pts.push(new THREE.Vector2(0.17, i / 14));
  return new THREE.LatheGeometry(pts, 14);
}

export class Flame {
  readonly group = new THREE.Group();
  readonly uniforms = { ...G, uFlame: { value: 0 }, uSeed: { value: Math.random() } };
  /** Smoothed flame size 0..1. */
  level = 0;

  constructor(seed = 0) {
    this.uniforms.uSeed.value = seed;
    const mat = new THREE.ShaderMaterial({
      glslVersion: THREE.GLSL3,
      uniforms: this.uniforms,
      vertexShader: FLAME_VS,
      fragmentShader: FLAME_FS,
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      side: THREE.FrontSide,
    });
    const g = flameGeometry();
    for (const x of [-BALLOON.nozzleX, BALLOON.nozzleX]) {
      const m = new THREE.Mesh(g, mat);
      m.position.set(x, BALLOON.nozzleY, 0);
      m.frustumCulled = false;
      m.renderOrder = 8;
      this.group.add(m);
    }
  }

  /** Set the flame size directly (the cinematic's deterministic schedule). */
  setLevel(l: number): void {
    this.level = l;
    this.uniforms.uFlame.value = l;
  }

  /** Ease toward on/off: the flame lights fast and dies a little slower. */
  update(on: boolean, dt: number, instant = false): void {
    const goal = on ? 1 : 0;
    const k = instant ? 1 : 1 - Math.exp(-dt / (on ? 0.08 : 0.18));
    this.level += (goal - this.level) * k;
    this.uniforms.uFlame.value = this.level;
  }
}

/** One balloon in the world: model (recoloured), flame, sway pivot. */
export class BalloonActor {
  /** Placed at the basket floor centre (world). */
  readonly root = new THREE.Group();
  /** Rotates about the envelope centre for the basket sway. */
  private readonly pivot = new THREE.Group();
  readonly flame: Flame;
  readonly model: THREE.Group;

  constructor(tpl: THREE.Group, palette = 0, seed = 0) {
    this.model = new THREE.Group();
    for (const c of tpl.children) {
      const m = (c as THREE.Mesh).clone();
      if (m.name === "envelope") {
        if (palette > 0) m.geometry = paintPattern(m.geometry, PATTERNS[(palette - 1) % PATTERNS.length]);
        else {
          m.geometry = m.geometry.clone();
          recolour(m.geometry, PLAYER_PALETTE);
        }
      }
      this.model.add(m);
    }
    if (palette === 0) this.model.add(rigging(tpl));
    this.flame = new Flame(seed);
    this.model.add(this.flame.group);
    // The pivot sits at the envelope centre; the model hangs below it.
    this.pivot.position.y = BALLOON.centreY;
    this.model.position.y = -BALLOON.centreY;
    this.pivot.add(this.model);
    this.root.add(this.pivot);
    onLayers(this.model, LAYER_SHADOW, LAYER_REFLECT);
    // The flame casts no shadow and has no reflection.
    this.flame.group.traverse((o) => o.layers.set(0));
  }

  /** Sway angles (rad) about world x and z. */
  setSway(ax: number, az: number, yaw = 0): void {
    this.pivot.rotation.set(ax, yaw, az, "YXZ");
  }

  /** World position of the burner nozzles' midpoint. */
  burnerWorld(out: THREE.Vector3): THREE.Vector3 {
    return out.set(0, BALLOON.nozzleY + 0.4, 0).applyMatrix4(this.model.matrixWorld);
  }
}
