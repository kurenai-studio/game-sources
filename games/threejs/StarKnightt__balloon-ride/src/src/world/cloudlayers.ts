/**
 * Cloud layers you fly among: low scattered puffs (base 250-330 m) that you can rise through, mid
 * cumulus (base ~600 m), and high cirrus streaks (~1700 m).
 *
 * The puffs and cumulus are real 3D heaps, so they hold up from below, beside and above: each is
 * a cluster of noise-bumped lumps (one instanced mesh per layer, one draw call), pressed flat at the
 * base, shaded in the painted cloud palette of cloudPaint.ts (sunlit cream tops, lilac-grey shade and
 * creases, warm undersides at a low sun, a rim on the lit edge). Each lump's normal is blended with
 * the whole cloud's envelope, so light falls on a few big planes like a painted cloud rather than
 * on a pile of balls, and lump silhouettes fade over a few pixels (alpha to coverage), so the
 * outline reads soft and brushed.
 *
 * Every layer drifts with its own wind (wind.ts) and wraps round the camera on a square period, so
 * the sky never empties wherever the balloon goes. The camera inside a cloud gets a soft whiteout.
 */
import * as THREE from "three";
import { COMMON, G } from "../render/materials";
import { CLOUD_NORMAL_BLEND } from "../render/cloudPaint";
import { LAYER_REFLECT, onLayers } from "../render/lightpasses";
import { mulberry32, range } from "../core/rng";
import { layerDrift } from "../flight/wind";

/** One cloud: base centre (x, z at drift 0), base height, half sizes, its lumps (offset xyz, radius). */
export interface Cloud {
  x: number;
  z: number;
  base: number;
  w: number;
  h: number;
  d: number;
  seed: number;
  lumps: [number, number, number, number][];
}

export interface LayerSpec {
  name: string;
  count: number;
  base: [number, number];
  halfWidth: [number, number];
  /** Height as a share of the half width. */
  tall: [number, number];
  lumps: [number, number];
  /** Wrap period (m) and fade-out distance (m). */
  period: number;
  far: number;
  /** Scud: each cloud may bring one or two smaller companions drifting nearby (groups, not dots). */
  cluster?: boolean;
}

export const CLOUD_LAYERS: LayerSpec[] = [
  { name: "low puffs", count: 70, base: [250, 330], halfWidth: [45, 125], tall: [0.45, 0.8], lumps: [34, 46], period: 8000, far: 3900 },
  { name: "mid cumulus", count: 34, base: [585, 625], halfWidth: [150, 300], tall: [0.75, 1.25], lumps: [52, 68], period: 9000, far: 4400 },
  // Scattered scud well under the puffs: small, low fair-weather wisps you float over from ~300 m,
  // with their shadows on the fields.
  { name: "low wisps", count: 90, base: [140, 185], halfWidth: [20, 64], tall: [0.55, 0.85], lumps: [28, 36], period: 5000, far: 2800, cluster: true },
];
export const CIRRUS_Y = 1700;

const smooth = (a: number, b: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};

function makeCloud(r: () => number, spec: LayerSpec, x: number, z: number): Cloud {
  const w = range(r, spec.halfWidth[0], spec.halfWidth[1]);
  const h = Math.min(w * range(r, spec.tall[0], spec.tall[1]), spec.name.startsWith("mid") ? 340 : 110);
  const d = w * range(r, 0.6, 0.9);
  const base = range(r, spec.base[0], spec.base[1]);
  const lumps: Cloud["lumps"] = [];
  const n = Math.floor(range(r, spec.lumps[0], spec.lumps[1] + 1));
  // A broad base row first (wide, low lumps that make the flat bottom), then a heaped body that
  // narrows upward and leans a little, then cauliflower bumps on the upper surface.
  const lean = range(r, -0.2, 0.2);
  const nb = Math.max(4, Math.floor(n * 0.22));
  for (let i = 0; i < nb; i++) {
    const a = (i / nb) * Math.PI * 2 + range(r, -0.3, 0.3);
    const rr = Math.min(w, h * 1.1) * range(r, 0.32, 0.46);
    lumps.push([Math.cos(a) * (w - rr) * range(r, 0.55, 0.95), rr * range(r, 0.35, 0.6), Math.sin(a) * (d - rr * 0.8) * range(r, 0.4, 0.9), rr]);
  }
  const core = Math.min(w, h) * 0.55;
  lumps.push([lean * w * 0.3, h * 0.38, 0, core]);
  const nBody = Math.floor((n - nb - 1) * 0.4);
  for (let i = 0; i < nBody; i++) {
    const t = range(r, 0.3, 0.85);
    const a = r() * Math.PI * 2;
    const spread = (1 - t) * 0.75 + 0.1;
    const rr = Math.min(w, h) * range(r, 0.26, 0.4) * (1.1 - 0.4 * t);
    lumps.push([Math.cos(a) * w * spread * range(r, 0.3, 0.9) + lean * w * t, h * t - rr * 0.35, Math.sin(a) * d * spread * range(r, 0.3, 0.8), rr]);
  }
  const body = lumps.slice(nb);
  for (let i = lumps.length; i < n; i++) {
    const b = body[Math.floor(r() * body.length)];
    const a = r() * Math.PI * 2;
    const up = range(r, 0.2, 0.95);
    const rr = b[3] * range(r, 0.28, 0.5);
    const dd = b[3] * range(r, 0.75, 0.95);
    const hz = Math.sqrt(1 - up * up);
    lumps.push([b[0] + Math.cos(a) * hz * dd, b[1] + up * dd, b[2] + Math.sin(a) * hz * dd, rr]);
  }
  const top = Math.max(...lumps.map((l) => l[1] + l[3]));
  return { x, z, base, w, h: top, d, seed: r(), lumps };
}

// Each lobe is a ray-traced sphere impostor on a camera-facing quad: a perfectly smooth round
// billow at any distance (no facets), cut by the cloud's flat base plane, with a soft dissolving
// rim. Lobes are blended back to front (sorted on the CPU each frame), so overlapping billows melt
// into one another instead of meeting along hard sphere-sphere creases.
const CLOUD_VS = /* glsl */ `
${COMMON}
in vec4 aLump;   // lobe centre, world (xyz), radius
in vec4 aCloud;  // cloud base centre x, base height, z, fade 0..1
in vec4 aEnv;    // half width, height, half depth, seed
out vec3 vWPos;
flat out vec4 vLobe;
flat out vec4 vCloud;
flat out vec4 vEnv;
flat out vec2 vProj;
void main(){
  vProj = vec2(projectionMatrix[2][2], projectionMatrix[3][2]);
  vec3 C = aLump.xyz;
  float R = aLump.w;
  vec3 toCam = cameraPosition - C;
  float d = length(toCam);
  vLobe = aLump; vCloud = aCloud; vEnv = aEnv;
  // Inside (or touching) the sphere there is no front surface to draw: the whiteout covers it.
  if (d < R * 1.01 || R < 0.01) { gl_Position = vec4(2.0, 2.0, 2.0, 1.0); vWPos = C; return; }
  vec3 f = toCam / d;
  vec3 right = abs(f.y) > 0.98 ? vec3(1.0, 0.0, 0.0) : normalize(cross(vec3(0.0, 1.0, 0.0), f));
  vec3 up = cross(f, right);
  // The sphere's silhouette circle (tangent cone), with a margin for the soft rim.
  float dq = d - R * R / d;
  float rq = R * sqrt(d * d - R * R) / d * 1.12;
  // Keep the quad off the near plane, at the same angular size, capped below 90 degrees.
  float dn = max(dq, 1.5);
  float rr = min(rq / dq, 5.0) * dn;
  vec3 c = cameraPosition - f * dn;
  vec3 wp = c + right * position.x * rr + up * position.y * rr;
  vWPos = wp;
  gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
}`;

const CLOUD_FS = /* glsl */ `
${COMMON}
layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
in vec3 vWPos;
flat in vec4 vLobe;
flat in vec4 vCloud;
flat in vec4 vEnv;
flat in vec2 vProj;
void main(){
  vec3 ro = cameraPosition;
  vec3 rd = normalize(vWPos - ro);
  vec3 C = vLobe.xyz;
  float R = vLobe.w;
  float seed = vEnv.w;
  // Each lobe is a sphere above its centre and a squashed half-ellipsoid below it (vertical
  // semi-axis K * R): rounded, slightly flattened billow bottoms, never a cut plane.
  const float K = 0.6;
  vec3 oc = ro - C;
  float b = dot(oc, rd);
  float q2 = max(dot(oc, oc) - b * b, 0.0);
  float rrS = sqrt(q2) / R;                  // 0 at the sphere's centre .. 1 on its silhouette
  vec3 sc = vec3(1.0, 1.0 / K, 1.0);
  vec3 oe = oc * sc;
  vec3 de = rd * sc;
  float Ld = length(de);
  de /= Ld;
  float be = dot(oe, de);
  float q2e = max(dot(oe, oe) - be * be, 0.0);
  float rrE = sqrt(q2e) / R;                 // the same for the squashed lower half
  // Which half's outline this pixel sits on: where the view ray passes closest to the centre.
  bool upper = oc.y - b * rd.y >= 0.0;
  float rr = upper ? rrS : rrE;
  // A ragged, dissolving rim: the edge wanders with a little noise round the outline.
  vec3 ce = normalize(cross(rd, oc) + 1e-5);
  float edgeN = vnoise(vec2(atan(dot(ce, vec3(0.0, 1.0, 0.0)), dot(ce, normalize(vec3(1.0, 0.0, 0.3)))) * 5.0, seed * 17.0 + R * 0.1)) - 0.5;
  float er = rr + edgeN * 0.05;
  if (er > 1.04) discard;
  vec3 p;
  vec3 Nl;
  float tS = -b - sqrt(max(R * R - q2, 0.0));
  vec3 pS = ro + rd * tS;
  if (rrS <= 1.0 && pS.y >= C.y) {
    p = pS;
    Nl = (pS - C) / R;
  } else if (rrE <= 1.0) {
    p = ro + rd * ((-be - sqrt(max(R * R - q2e, 0.0))) / Ld);
    vec3 d = p - C;
    Nl = normalize(vec3(d.x, d.y / (K * K), d.z));
  } else {
    // The soft rim just outside the outline: the closest point of the ray stands in.
    p = upper ? ro + rd * -b : ro + rd * (-be / Ld);
    vec3 d = p - C;
    Nl = normalize(vec3(d.x, d.y / (upper ? 1.0 : K * K), d.z));
  }
  // Painted edge: a crisp, soft rim one or two pixels wide at any distance (never a blur).
  float aw = clamp(fwidth(rr) * 2.0, 0.004, 0.25);
  float alpha = 1.0 - smoothstep(1.0 - aw, 1.0, er);
  // The cloud's underside: billow bottoms near the base, turned down (cool lilac shade).
  float vH0 = clamp((p.y - vCloud.y) / max(vEnv.y, 1.0), 0.0, 1.0);
  float flatK = smoothstep(-0.25, -0.85, Nl.y) * (1.0 - smoothstep(0.05, 0.35, vH0));
  alpha *= vCloud.w;
  if (alpha < 0.01) discard;

  // Shading: the lobe's own sphere normal, blended with the whole cloud's envelope so light falls
  // on a few big planes, like a painted cumulus.
  vec3 cc = vCloud.xyz;
  vec3 e = (p - (cc + vec3(0.0, vEnv.y * 0.42, 0.0))) / vec3(vEnv.x, vEnv.y * 0.7, vEnv.z);
  vec3 Ne = normalize(e + vec3(0.0, 1e-3, 0.0));
  vec3 V = -rd;
  // Close to the lens a cloud fills the frame, and the envelope's few big planes read as one
  // smooth pillow: there the lobes take over the shading, so every billow keeps its own form.
  float near = 1.0 - smoothstep(250.0, 1400.0, length(p - ro));
  vec3 N = normalize(mix(Ne, Nl, mix(0.55, 0.8, near)));
  N = normalize(mix(N, vec3(0.0, -1.0, 0.0), flatK * 0.85));
  // Painter's key: never straight from behind the viewer. A front-lit cloud has its terminator on
  // the outline and reads as a flat cut-out (sunrise, sun at your back), so the key swings aside
  // and a little up, and a shade side and base cross the cloud again.
  vec3 L = uCloudLight;
  float fr = smoothstep(0.1, 0.9, dot(L, V));
  vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), V) + vec3(1e-4, 0.0, 0.0));
  side *= dot(side, L) >= 0.0 ? 1.0 : -1.0;
  L = normalize(L - V * fr * 1.0 + side * fr * 1.1 + vec3(0.0, fr * 0.2, 0.0));
  float vH = clamp((p.y - cc.y) / max(vEnv.y, 1.0), 0.0, 1.0);
  float br = vnoise(p.xz * 0.035 + p.y * 0.05 + seed * 13.0) * 0.6 + vnoise(p.xy * 0.11 + seed * 7.0) * 0.4;
  float selfSh = 1.0 - smoothstep(0.08, 0.7, vH + (br - 0.5) * 0.15);
  float sky = smoothstep(0.1, 0.8, N.y);
  // Front-lit, the lit band also narrows (and the sky term eases), so each billow keeps a shade side.
  N = normalize(mix(N, Nl, 0.25 * fr));
  float t = dot(N, L) * 0.42 + 0.5 - fr * 0.13 + (br - 0.5) * 0.14 + sky * (0.14 - 0.06 * fr) - selfSh * 0.34 - flatK * 0.3;
  // Each billow's underside turns into shade, and a soft shaded rim separates it from the billow
  // behind it (cauliflower), but only inside the cloud's outline.
  float lumpUnder = smoothstep(0.2, -0.7, Nl.y) * (1.0 - flatK);
  float inner = smoothstep(0.1, 0.45, dot(Ne, V));
  float seam = smoothstep(mix(0.55, 0.42, near), 0.95, rr) * inner * (1.0 - flatK * (1.0 - near));
  t -= lumpUnder * (0.24 + 0.14 * near) + seam * (0.2 + 0.16 * near);
  // Painted breakup of the lower body and the underside: each lobe a slightly different tone (so
  // billows overlap as separate shapes), plus broad brushed patches of shade, strongest low down.
  float lobeTone = hash13(floor(C * 0.5) + seed * 31.0) - 0.5;
  float patchN = vnoise(p.xz * 0.045 + p.y * 0.07 + seed * 3.0) * 0.65 + vnoise(p.xz * 0.13 - p.y * 0.1 + seed * 9.0) * 0.35;
  float low = 1.0 - smoothstep(0.15, 0.7, vH);
  t += lobeTone * (0.08 + 0.1 * near) * (0.5 + 0.5 * low) + (patchN - 0.5) * (0.12 + 0.22 * near) * low;
  float lit = smoothstep(0.5, 0.62, t);
  float mid = smoothstep(0.25, 0.4, t);
  // Lavender shade a step below the palette's low tone; the lit tops a touch warmer than white.
  vec3 shade = uCloudLow * vec3(0.8, 0.78, 0.94);
  vec3 col = mix(shade, uCloudMid, mid);
  col = mix(col, uCloudTop * 0.97, lit);
  // The flat base: a cool lilac-grey, mottled a little, lighter toward its sunlit edge.
  float bm = vnoise(p.xz * 0.04 + seed * 5.0);
  col = mix(col, shade * vec3(0.9, 0.9, 0.98) * (0.86 + (0.2 + 0.2 * near) * bm + lobeTone * 0.14 * near), flatK * 0.85);
  // In the shade the bands above clamp the breakup away, so it is also painted into the tone there:
  // darker and lighter washes of lilac, lobe by lobe, so a near shade mass is never one flat fill.
  float wash = ((patchN - 0.5) * 0.22 + lobeTone * 0.12) * (0.35 + 0.65 * near) * (1.0 - lit);
  col *= 1.0 + wash;
  col = mix(col, col * vec3(1.04, 0.98, 0.94), clamp((patchN - 0.5) * 1.5, 0.0, 1.0) * near * (1.0 - lit) * 0.5);
  // Low sun: shaded flanks and the base take a warm bounce (rose-peach over the lilac).
  float lowSun = 1.0 - smoothstep(0.08, 0.5, L.y);
  float sunSide = smoothstep(-0.3, 0.7, dot(normalize(N.xz + 1e-5), normalize(L.xz + 1e-5)));
  float warm = uCloudK.z * (1.0 - lit) * (0.35 + 0.4 * sunSide) * (1.0 - 0.6 * flatK) * mix(0.4, 1.0, lowSun);
  col = mix(col, col * uCloudUnder * 1.25, clamp(warm, 0.0, 0.4));
  // Rim light where the outer silhouette faces the light.
  float edge = smoothstep(0.7, 1.0, rr) * (1.0 - inner);
  float facing = smoothstep(-0.1, 0.6, dot(Nl, L));
  col = mix(col, uCloudRim, clamp(edge * facing * (uCloudK.x * 0.8 + 0.2), 0.0, 1.0));
  // Aerial perspective toward the sky behind.
  vec3 dv = p - cameraPosition;
  float dist = length(dv);
  col = col * uWorldTint;
  col = mix(col, skyColor(dv / max(dist, 1.0)), (1.0 - exp(-max(dist - 900.0, 0.0) / 6000.0)) * 0.6);
  float vz = (viewMatrix * vec4(p, 1.0)).z;
  gl_FragDepth = clamp((vProj.x * vz + vProj.y) / -vz * 0.5 + 0.5, 0.0, 1.0);
  gColor = vec4(safe3(col), safe1(alpha));
  // The mask leaves the ink behind a cloud as soon as it starts to cover it (see CLOUD_NORMAL_BLEND),
  // not in proportion to its alpha: no field or hedge lines through a soft rim.
  gNormal = vec4(0.5, 0.5, 0.0, safe1(min(alpha * 3.0, 1.0)));
}`;

export class CloudLayer {
  readonly mesh: THREE.Mesh;
  readonly clouds: Cloud[];
  readonly drift = new THREE.Vector2();
  private readonly wind: THREE.Vector2;
  private readonly aLump: THREE.InstancedBufferAttribute;
  private readonly aCloud: THREE.InstancedBufferAttribute;
  private readonly aEnv: THREE.InstancedBufferAttribute;
  private readonly geo: THREE.InstancedBufferGeometry;
  private keys: Float32Array;
  private order: Uint32Array;
  /** Per lobe: cloud index, lobe index. */
  private readonly ref: Uint32Array;
  /** Clouds kept out of view (the cinematic's camera path), by index. */
  culled = new Set<number>();

  constructor(readonly spec: LayerSpec, seed: number) {
    const r = mulberry32(seed);
    const P = spec.period;
    this.clouds = [];
    // Jittered grid over one period, with a little clumping (some cells empty, some doubled).
    const cells = Math.ceil(Math.sqrt(spec.count));
    let primaries = 0;
    const cs = P / cells;
    for (let i = 0; i < cells; i++)
      for (let j = 0; j < cells; j++) {
        if (primaries >= spec.count) break;
        primaries++;
        const x = -P / 2 + (i + range(r, 0.15, 0.85)) * cs;
        const z = -P / 2 + (j + range(r, 0.15, 0.85)) * cs;
        this.clouds.push(makeCloud(r, spec, x, z));
        if (spec.cluster) {
          const k = r() < 0.35 ? 0 : r() < 0.6 ? 1 : 2;
          for (let m = 0; m < k; m++) {
            const a = r() * Math.PI * 2, d = range(r, 140, 260);
            const small = { ...spec, halfWidth: [spec.halfWidth[0] * 0.6, spec.halfWidth[1] * 0.7] as [number, number], lumps: [spec.lumps[0] - 6, spec.lumps[1] - 6] as [number, number] };
            this.clouds.push(makeCloud(r, small, x + Math.cos(a) * d, z + Math.sin(a) * d));
          }
        }
      }
    const lumps = this.clouds.reduce((s, c) => s + c.lumps.length, 0);
    this.ref = new Uint32Array(lumps * 2);
    let k = 0;
    this.clouds.forEach((c, ci) => c.lumps.forEach((_, li) => ((this.ref[k * 2] = ci), (this.ref[k * 2 + 1] = li), k++)));
    this.keys = new Float32Array(lumps);
    this.order = new Uint32Array(lumps);
    const quad = new THREE.PlaneGeometry(2, 2);
    const g = new THREE.InstancedBufferGeometry();
    g.index = quad.index;
    g.setAttribute("position", quad.getAttribute("position"));
    this.aLump = new THREE.InstancedBufferAttribute(new Float32Array(lumps * 4), 4).setUsage(THREE.DynamicDrawUsage);
    this.aCloud = new THREE.InstancedBufferAttribute(new Float32Array(lumps * 4), 4).setUsage(THREE.DynamicDrawUsage);
    this.aEnv = new THREE.InstancedBufferAttribute(new Float32Array(lumps * 4), 4).setUsage(THREE.DynamicDrawUsage);
    g.setAttribute("aLump", this.aLump);
    g.setAttribute("aCloud", this.aCloud);
    g.setAttribute("aEnv", this.aEnv);
    g.instanceCount = 0;
    g.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e6);
    this.geo = g;
    const mat = new THREE.ShaderMaterial({
      glslVersion: THREE.GLSL3,
      uniforms: { ...G },
      vertexShader: CLOUD_VS,
      fragmentShader: CLOUD_FS,
      transparent: true,
      depthWrite: false,
    });
    mat.userData.normalBlend = CLOUD_NORMAL_BLEND;
    this.mesh = new THREE.Mesh(g, mat);
    this.mesh.name = spec.name;
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = -3;
    this.wind = layerDrift((spec.base[0] + spec.base[1]) / 2 + 40);
  }

  /** Cloud drift for clock t (deterministic: the same t always puts the clouds in the same place). */
  update(t: number): void {
    this.drift.copy(this.wind).multiplyScalar(t);
  }

  /**
   * Fill the instance buffers for a camera at `cam`: the clouds in reach, every lobe at its world
   * position, sorted far to near (they blend over each other).
   */
  sort(cam: THREE.Vector3, fwd: THREE.Vector3): void {
    const far = this.spec.far;
    const cc = new THREE.Vector3();
    const fade = new Float32Array(this.clouds.length);
    const cx = new Float32Array(this.clouds.length), cz = new Float32Array(this.clouds.length);
    this.clouds.forEach((c, i) => {
      this.centre(c, cam, cc);
      cx[i] = cc.x;
      cz[i] = cc.z;
      const d = Math.hypot(cc.x - cam.x, cc.z - cam.z);
      const f = 1 - smooth(far * 0.82, far, d);
      // Behind the camera and well clear of it: skip.
      const dx = cc.x - cam.x, dy = c.base + c.h * 0.5 - cam.y, dz = cc.z - cam.z;
      const ahead = dx * fwd.x + dy * fwd.y + dz * fwd.z;
      fade[i] = ahead < -(c.w + c.h) * 1.3 || this.culled.has(i) ? 0 : f;
    });
    let n = 0;
    const L = this.ref.length / 2;
    for (let k = 0; k < L; k++) {
      const ci = this.ref[k * 2];
      if (fade[ci] <= 0.001) continue;
      const c = this.clouds[ci], l = c.lumps[this.ref[k * 2 + 1]];
      const s = 0.6 + 0.4 * fade[ci];
      const x = cx[ci] + l[0] * s - cam.x, y = c.base + l[1] * s - cam.y, z = cz[ci] + l[2] * s - cam.z;
      this.keys[k] = -(x * x + y * y + z * z);
      this.order[n++] = k;
    }
    const keys = this.keys;
    const ord = this.order.subarray(0, n);
    ord.sort((a, b) => keys[a] - keys[b]);
    const A = this.aLump.array as Float32Array, B = this.aCloud.array as Float32Array, E = this.aEnv.array as Float32Array;
    for (let i = 0; i < n; i++) {
      const k = ord[i];
      const ci = this.ref[k * 2], c = this.clouds[ci], l = c.lumps[this.ref[k * 2 + 1]];
      const f = fade[ci], s = 0.6 + 0.4 * f;
      A[i * 4] = cx[ci] + l[0] * s;
      A[i * 4 + 1] = c.base + l[1] * s;
      A[i * 4 + 2] = cz[ci] + l[2] * s;
      A[i * 4 + 3] = l[3] * f;
      B[i * 4] = cx[ci];
      B[i * 4 + 1] = c.base;
      B[i * 4 + 2] = cz[ci];
      // Fading clouds shrink (the lobe radius above), never go see-through: a translucent cloud
      // shows the fields' ink lines straight through its body.
      B[i * 4 + 3] = Math.min(1, f * 12);
      E[i * 4] = c.w;
      E[i * 4 + 1] = c.h;
      E[i * 4 + 2] = c.d;
      E[i * 4 + 3] = c.seed;
    }
    this.geo.instanceCount = n;
    for (const a of [this.aLump, this.aCloud, this.aEnv]) {
      a.clearUpdateRanges();
      a.addUpdateRange(0, n * 4);
      a.needsUpdate = true;
    }
  }

  /** World base centre of cloud `c` as drawn now (or at clock `t`), wrapped round `cam`. */
  centre(c: Cloud, cam: THREE.Vector3, out = new THREE.Vector3(), t?: number): THREE.Vector3 {
    const P = this.spec.period;
    const wrap = (v: number, o: number) => o + (((v - o + P / 2) % P) + P) % P - P / 2;
    const dx = t === undefined ? this.drift.x : this.wind.x * t, dz = t === undefined ? this.drift.y : this.wind.y * t;
    return out.set(wrap(c.x + dx, cam.x), c.base, wrap(c.z + dz, cam.z));
  }

  /**
   * Keep out of view every cloud that would pass closer than `radius` to the camera while in its
   * frustum at any of the given views (clock time, camera): for a scripted path. Empty clears it.
   */
  keepOut(views: { t: number; cam: THREE.PerspectiveCamera }[], radius: number): number {
    this.culled.clear();
    const fr = new THREE.Frustum(), m = new THREE.Matrix4(), cc = new THREE.Vector3(), sph = new THREE.Sphere();
    for (const v of views) {
      m.multiplyMatrices(v.cam.projectionMatrix, v.cam.matrixWorldInverse);
      fr.setFromProjectionMatrix(m);
      const cam = v.cam.position;
      this.clouds.forEach((c, i) => {
        if (this.culled.has(i)) return;
        this.centre(c, cam, cc, v.t);
        for (const l of c.lumps) {
          sph.center.set(cc.x + l[0], c.base + l[1], cc.z + l[2]);
          sph.radius = l[3];
          if (sph.center.distanceTo(cam) - l[3] < radius && fr.intersectsSphere(sph)) {
            this.culled.add(i);
            break;
          }
        }
      });
    }
    return this.culled.size;
  }

  /** 0..1: how deep inside a cloud the point is (1 = well inside a lobe). */
  inside(p: THREE.Vector3, cam: THREE.Vector3): number {
    let best = 0;
    const cc = new THREE.Vector3();
    for (let ci = 0; ci < this.clouds.length; ci++) {
      if (this.culled.has(ci)) continue;
      const c = this.clouds[ci];
      this.centre(c, cam, cc);
      if (p.y < c.base - 12 || p.y > c.base + c.h + 12) continue;
      if (Math.abs(p.x - cc.x) > c.w + 40 || Math.abs(p.z - cc.z) > c.w + 40) continue;
      const below = smooth(c.base - 6, c.base + 3, p.y);
      for (const l of c.lumps) {
        const dx = p.x - (cc.x + l[0]), dy = p.y - (cc.y + l[1]), dz = p.z - (cc.z + l[2]);
        const d = Math.sqrt(dx * dx + dy * dy + dz * dz) / l[3];
        best = Math.max(best, (1 - smooth(0.8, 1.08, d)) * below);
      }
    }
    return best;
  }

  /** The cloud nearest to (x, z) as drawn now (for capture spots). */
  nearest(x: number, z: number, cam: THREE.Vector3): { x: number; z: number; base: number; top: number; w: number } {
    let best: Cloud = this.clouds[0], bd = Infinity;
    const cc = new THREE.Vector3();
    for (const c of this.clouds) {
      this.centre(c, cam, cc);
      const d = Math.hypot(cc.x - x, cc.z - z);
      if (d < bd) (bd = d), (best = c);
    }
    this.centre(best, cam, cc);
    return { x: cc.x, z: cc.z, base: best.base, top: best.base + best.h, w: best.w };
  }
}

// ------------------------------------------------------------------ cirrus

const CIRRUS_VS = /* glsl */ `
${COMMON}
in vec4 aStreak;  // x, z, half length, half width
in float aAng;
uniform vec2 uDrift;
uniform float uPeriod;
out vec2 vQ;
out vec3 vWPos;
out float vSeed;
void main(){
  vec2 c = aStreak.xy + uDrift;
  c = cameraPosition.xz + mod(c - cameraPosition.xz + 0.5 * uPeriod, uPeriod) - 0.5 * uPeriod;
  float cs = cos(aAng), sn = sin(aAng);
  vec2 o = mat2(cs, -sn, sn, cs) * (position.xy * aStreak.zw);
  vec3 wp = vec3(c.x + o.x, ${CIRRUS_Y.toFixed(1)}, c.y + o.y);
  vQ = position.xy;
  vSeed = aAng;
  vWPos = wp;
  gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
}`;

const CIRRUS_FS = /* glsl */ `
${COMMON}
layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
in vec2 vQ;
in vec3 vWPos;
in float vSeed;
void main(){
  // Mares' tails: fine combed strands along the streak, thinning to wisps at the ends.
  float along = vQ.x, across = vQ.y;
  float env = (1.0 - smoothstep(0.4, 1.0, abs(along))) * (1.0 - smoothstep(0.15, 1.0, abs(across + 0.25 * sin(along * 2.5 + vSeed))));
  float strands = vnoise(vec2(along * 3.0 + vSeed * 5.0, across * 26.0)) * 0.65 + vnoise(vec2(along * 9.0, across * 60.0 + vSeed)) * 0.35;
  float a = env * smoothstep(0.35, 0.8, strands) * 0.55;
  if (a < 0.01) discard;
  vec3 dir = normalize(vWPos - cameraPosition);
  vec3 col = mix(uCloudTop, uCloudUnder, 0.35 * uCloudK.z);
  col = mix(col, skyColor(dir), 0.35);
  gColor = vec4(safe3(col), safe1(a));
  gNormal = vec4(0.5, 0.5, 0.0, safe1(a * 0.5));
}`;

function cirrusMesh(seed: number): { mesh: THREE.Mesh; drift: THREE.Vector2 } {
  const r = mulberry32(seed);
  const n = 26;
  const quad = new THREE.PlaneGeometry(2, 2, 1, 1);
  const g = new THREE.InstancedBufferGeometry();
  g.index = quad.index;
  g.setAttribute("position", quad.getAttribute("position"));
  const st = new Float32Array(n * 4), ang = new Float32Array(n);
  const base = range(r, -1.2, -0.8);
  for (let i = 0; i < n; i++) {
    st.set([range(r, -7000, 7000), range(r, -7000, 7000), range(r, 500, 1400), range(r, 90, 220)], i * 4);
    ang[i] = base + range(r, -0.25, 0.25);
  }
  g.setAttribute("aStreak", new THREE.InstancedBufferAttribute(st, 4));
  g.setAttribute("aAng", new THREE.InstancedBufferAttribute(ang, 1));
  g.instanceCount = n;
  const drift = new THREE.Vector2();
  const mat = new THREE.ShaderMaterial({
    glslVersion: THREE.GLSL3,
    uniforms: { ...G, uDrift: { value: drift }, uPeriod: { value: 14000 } },
    vertexShader: CIRRUS_VS,
    fragmentShader: CIRRUS_FS,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
  });
  mat.userData.normalBlend = CLOUD_NORMAL_BLEND;
  const mesh = new THREE.Mesh(g, mat);
  mesh.name = "cirrus";
  mesh.frustumCulled = false;
  mesh.renderOrder = -4;
  return { mesh, drift };
}

// ------------------------------------------------------------------ whiteout

const WHITE_FS = /* glsl */ `
${COMMON}
layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
uniform float uWhite;
uniform mat4 uInvVP;
in vec2 vNdc;
void main(){
  // Inside a sunlit cloud: luminous soft white all round, warmer toward the sun, brighter overhead,
  // with slow, gentle drifts of denser and thinner vapour streaming past.
  vec4 w = uInvVP * vec4(vNdc, 1.0, 1.0);
  vec3 dir = normalize(w.xyz / w.w - cameraPosition);
  vec3 L = uCloudLight;
  float sunK = pow(max(dot(dir, L), 0.0), 3.0);
  vec3 q = dir * 3.0 + vec3(uTime * 0.04, uTime * 0.07, -uTime * 0.03);
  float n = vnoise3(q) * 0.6 + vnoise3(q * 2.3 + 4.0) * 0.4;
  float n2 = vnoise3(q * 0.45 - 2.0);
  vec3 top = mix(uCloudTop, vec3(1.0), 0.45);
  vec3 lav = mix(uCloudLow * vec3(0.84, 0.84, 1.0), vec3(0.9, 0.9, 0.97), 0.25);
  vec3 col = mix(lav, top, clamp(0.45 + 0.3 * dir.y + (n - 0.5) * 1.1 + (n2 - 0.5) * 0.8, 0.0, 1.0));
  col = mix(col, mix(top, uCloudRim, 0.35) * 1.08, sunK * 0.7);
  col = mix(col, col * uCloudUnder * 1.2, 0.12 * uCloudK.z);
  float a = smoothstep(0.0, 0.55, uWhite) * (0.9 + 0.1 * n);
  a = mix(a, 1.0, smoothstep(0.6, 0.85, uWhite));
  gColor = vec4(safe3(col * uWorldTint), safe1(a));
  gNormal = vec4(0.5, 0.5, 0.0, safe1(a));
}`;

function whiteoutMesh(): { mesh: THREE.Mesh; u: { value: number }; vp: { value: THREE.Matrix4 } } {
  const u = { value: 0 };
  const vp = { value: new THREE.Matrix4() };
  const mat = new THREE.ShaderMaterial({
    glslVersion: THREE.GLSL3,
    uniforms: { ...G, uWhite: u, uInvVP: vp },
    vertexShader: /* glsl */ `out vec2 vNdc; void main(){ vNdc = position.xy; gl_Position = vec4(position.xy, 0.0, 1.0); }`,
    fragmentShader: WHITE_FS,
    transparent: true,
    depthTest: false,
    depthWrite: false,
  });
  mat.userData.normalBlend = CLOUD_NORMAL_BLEND;
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), mat);
  mesh.name = "cloud whiteout";
  mesh.frustumCulled = false;
  mesh.renderOrder = 1000;
  return { mesh, u, vp };
}

// ------------------------------------------------------------------ all layers

export class Clouds {
  readonly group = new THREE.Group();
  readonly layers: CloudLayer[];
  private readonly cirrus = cirrusMesh(911);
  private readonly white = whiteoutMesh();
  private readonly highWind = layerDrift(CIRRUS_Y);
  private readonly fwd = new THREE.Vector3();
  /** Smoothed whiteout amount 0..1. */
  whiteout = 0;

  constructor(seed: number) {
    this.layers = CLOUD_LAYERS.map((s, i) => new CloudLayer(s, seed * 131 + 17 + i * 7));
    for (const l of this.layers) this.group.add(l.mesh);
    this.group.add(this.cirrus.mesh);
    onLayers(this.group, LAYER_REFLECT);
    this.group.add(this.white.mesh);
  }

  /**
   * Fill LAND.uCloudSh with the shadows of the clouds nearest to `focus` (ground xz), cast along the
   * light `L` (toward the sun). A low sun stretches them long across the fields.
   */
  shadows(focus: THREE.Vector3, cam: THREE.Vector3, L: THREE.Vector3, out: THREE.Vector4[], dir: THREE.Vector2): number {
    const cand: [number, number, number, number, number][] = [];
    const ly = Math.max(L.y, 0.12);
    const lh = Math.hypot(L.x, L.z) || 1;
    dir.set(L.x / lh, L.z / lh);
    const stretch = Math.min(3.5, 1 / Math.max(ly, 0.2));
    const cc = new THREE.Vector3();
    for (const l of this.layers)
      for (let ci = 0; ci < l.clouds.length; ci++) {
        if (l.culled.has(ci)) continue;
        const c = l.clouds[ci];
        l.centre(c, cam, cc);
        const yc = c.base + c.h * 0.4 - 15;
        const gx = cc.x - (L.x / ly) * yc, gz = cc.z - (L.z / ly) * yc;
        const d = Math.hypot(gx - focus.x, gz - focus.z);
        if (d < 3500) cand.push([d, gx, gz, c.w * 0.8, c.w * 0.8 * stretch]);
      }
    cand.sort((a, b) => a[0] - b[0]);
    for (let i = 0; i < out.length; i++) {
      const c = cand[i];
      if (c) out[i].set(c[1], c[2], c[3], c[4]);
      else out[i].set(0, 0, 0, 0);
    }
    return Math.min(cand.length, out.length);
  }

  /**
   * Keep big near clouds off a scripted camera path: `pose(s, camera)` places the camera at path
   * time s, which plays at clock t0 + s; clouds within `radius` of the lens in [s0, s1] stay out of
   * view for the whole path (chosen once, so nothing pops mid-shot). Call with no pose to clear.
   */
  keepOffPath(pose?: (s: number, cam: THREE.PerspectiveCamera) => void, t0 = 0, s0 = 0, s1 = 0, radius = 450): void {
    if (!pose) {
      for (const l of this.layers) l.culled.clear();
      return;
    }
    const views: { t: number; cam: THREE.PerspectiveCamera }[] = [];
    for (let s = s0; s <= s1 + 1e-6; s += 0.5) {
      const cam = new THREE.PerspectiveCamera(50, 2, 0.3, 20000);
      pose(s, cam);
      cam.updateMatrixWorld();
      cam.matrixWorldInverse.copy(cam.matrixWorld).invert();
      views.push({ t: t0 + s, cam });
    }
    for (const l of this.layers) l.keepOut(views, radius);
  }

  /** Drift (clock t) and the whiteout for a camera at `cam` (`dt` real seconds; snap jumps there). */
  update(t: number, camera: THREE.Camera, dt: number, snap = false): void {
    const cam = camera.position;
    camera.getWorldDirection(this.fwd);
    for (const l of this.layers) {
      l.update(t);
      l.sort(cam, this.fwd);
    }
    this.white.vp.value.multiplyMatrices(camera.matrixWorld, (camera as THREE.PerspectiveCamera).projectionMatrixInverse);
    this.cirrus.drift.copy(this.highWind).multiplyScalar(t);
    let k = 0;
    for (const l of this.layers) k = Math.max(k, l.inside(cam, cam));
    this.whiteout += (k - this.whiteout) * (snap ? 1 : 1 - Math.exp(-dt / 0.35));
    this.white.u.value = this.whiteout;
    this.white.mesh.visible = this.whiteout > 0.003;
  }
}
