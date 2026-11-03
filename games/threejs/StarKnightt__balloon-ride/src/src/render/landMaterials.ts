/**
 * Terrain and water materials, built from the uber factory's shared GLSL (COMMON: toon lighting,
 * shadows, brush strokes, haze; OUT: the two-target output) and its G / time-of-day uniforms, so
 * the land lights, hazes and inks exactly like every other surface.
 *
 * Terrain: shared flat grid patches displaced in the vertex shader from the heightfield texture
 * (one geometry per LOD, chunks as instances). The patchwork comes from the painted field map
 * (groundmap.ts): colour, road mask, stripe amounts and row direction, every periodic pattern
 * band-limited by its pixel footprint so nothing shimmers from altitude. Beyond the map a
 * procedural patchwork carries the fields on into the haze.
 *
 * Water: one flat surface at the water level wherever the ground dips under it (river and lake),
 * with gentle travelling ripples, a fresnel mix of the planar mirror (or the sky) over a body
 * colour that deepens with the real depth, a pale painted shoreline and sun glitter.
 */
import * as THREE from "three";
import { COMMON, G, OUT, REFL } from "./materials";
import { ID } from "../world/geo";

export const LAND = {
  uHeight: { value: null as THREE.Texture | null },
  uGridStep: { value: 6.25 },
  uGridHalf: { value: 4000 },
  uGridN: { value: 1281 },
  uMapA: { value: null as THREE.Texture | null },
  uMapB: { value: null as THREE.Texture | null },
  uMapC: { value: null as THREE.Texture | null },
  uMapHalf: { value: 4000 },
  /** Village detail map (villagemap.ts): colour, coverage mask, and its square (centre xz, half). */
  uMapV: { value: null as THREE.Texture | null },
  uMapVM: { value: null as THREE.Texture | null },
  uMapVRect: { value: new THREE.Vector3(0, 0, 400) },
  /** Balloon Ride: soft cloud shadows on the land (cloudlayers.ts): ground centre xz, radius across
   * and along the sun's azimuth; the sun's horizontal direction; strength. */
  uCloudSh: { value: Array.from({ length: 24 }, () => new THREE.Vector4(0, 0, 0, 0)) },
  uCloudShDir: { value: new THREE.Vector2(1, 0) },
  uCloudShK: { value: 0 },
};

const LAND_GLSL = /* glsl */ `
uniform highp sampler2D uHeight;
uniform float uGridStep;
uniform float uGridHalf;
uniform int uGridN;
uniform sampler2D uMapA;
uniform sampler2D uMapB;
uniform sampler2D uMapC;
uniform float uMapHalf;
uniform sampler2D uMapV;
uniform sampler2D uMapVM;
uniform vec3 uMapVRect;
uniform vec4 uCloudSh[24];
uniform vec2 uCloudShDir;
uniform float uCloudShK;
float cloudShadow(vec2 p){
  if (uCloudShK <= 0.0) return 0.0;
  float s = 0.0;
  vec2 a = uCloudShDir, b = vec2(-a.y, a.x);
  float n = (vnoise(p * 0.012) - 0.5) * 0.35 + (vnoise(p * 0.05) - 0.5) * 0.1;
  for (int i = 0; i < 24; i++) {
    vec4 c = uCloudSh[i];
    if (c.z <= 0.0) continue;
    vec2 d = p - c.xy;
    float e = length(vec2(dot(d, b) / c.z, dot(d, a) / c.w));
    // A painted edge a few tens of metres soft whatever the cloud's size (a relative falloff
    // smeared a big cloud's shadow over hundreds of metres: no edge to read anywhere).
    float m = (e - 0.8 + n) * c.z;
    s = max(s, 1.0 - smoothstep(-16.0, 16.0, m));
  }
  return s * uCloudShK;
}
float hFetch(ivec2 c){ c = clamp(c, ivec2(0), ivec2(uGridN - 1)); return texelFetch(uHeight, c, 0).r; }
/** Bilinear height at world xz (inside the grid). */
float hAt(vec2 xz){
  vec2 f = (xz + uGridHalf) / uGridStep;
  ivec2 i = ivec2(floor(f)); vec2 u = fract(f);
  return mix(mix(hFetch(i), hFetch(i + ivec2(1, 0)), u.x), mix(hFetch(i + ivec2(0, 1)), hFetch(i + ivec2(1, 1)), u.x), u.y);
}
`;

const TERRAIN_VS = /* glsl */ `
${COMMON}
${LAND_GLSL}
out vec3 vWPos;
out vec3 vN;
void main(){
#ifdef FAR
  vec3 wp = (modelMatrix * vec4(position, 1.0)).xyz;
  vN = normal;
#else
  // Instance: translation xz = chunk origin (grid cells), x scale = this LOD's step (cells).
  vec2 cell0 = instanceMatrix[3].xz;
  float s = instanceMatrix[0].x;
  ivec2 c = ivec2(floor(cell0 + position.xz + 0.5));
  float h = hFetch(c);
  // Skirt vertices (position.y = 1) hang below the patch edge and hide cracks between LODs.
  h -= position.y * (3.0 + 2.5 * s);
  vec3 wp = vec3(float(c.x) * uGridStep - uGridHalf, h, float(c.y) * uGridStep - uGridHalf);
  float hx = hFetch(c + ivec2(2, 0)) - hFetch(c - ivec2(2, 0));
  float hz = hFetch(c + ivec2(0, 2)) - hFetch(c - ivec2(0, 2));
  vN = normalize(vec3(-hx, 4.0 * uGridStep, -hz));
#endif
  vWPos = wp;
  gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
}
`;

const TERRAIN_FS = /* glsl */ `
${COMMON}
${OUT}
${LAND_GLSL}
in vec3 vWPos;
in vec3 vN;

// Anti-aliased line on every integer of x (half-width hw); fades to its mean once it would alias.
float aaLine(float x, float hw){
  float w = fwidth(x);
  float d = abs(fract(x + 0.5) - 0.5);
  float l = 1.0 - smoothstep(hw - w, hw + w, d);
  return mix(l, 2.0 * hw, smoothstep(0.2, 0.5, w));
}
// Anti-aliased square wave (0/1 halves); fades to 0.5 once a period is under ~3 px.
float aaSquare(float x){
  float w = fwidth(x) + 1e-5;
  float d = abs(fract(x) - 0.5) - 0.25;
  float sq = clamp(d / w + 0.5, 0.0, 1.0);
  return mix(sq, 0.5, smoothstep(0.15, 0.4, w));
}
vec2 cellular(vec2 p){
  vec2 i = floor(p), f = fract(p); float d = 8.0; vec2 best = vec2(0.0);
  for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
    vec2 g = vec2(float(x), float(y));
    vec2 o = vec2(hash12(i + g), hash12(i + g + 17.3));
    vec2 r = g + o - f; float dd = dot(r, r);
    if (dd < d) { d = dd; best = g; }
  }
  return vec2(sqrt(d), hash12(i + best + 41.7));
}
vec3 srgb(vec3 c){ return pow(c, vec3(2.2)); }

// Far patchwork beyond the painted map: same palette, procedural parcels.
void farField(vec2 xz, out vec3 base, out float mown, out float furrow, out float ang){
  vec2 c = cellular(xz / 190.0 + vec2(vnoise(xz * 0.004), vnoise(xz * 0.004 + 9.0)) * 0.6);
  float h = c.y;
  ang = hash12(vec2(h * 91.0, 3.0)) * 3.14159;
  mown = 0.0; furrow = 0.0;
  if (h < 0.42) base = srgb(mix(vec3(0.33, 0.58, 0.24), vec3(0.47, 0.66, 0.3), hash12(vec2(h, 1.0))));
  else if (h < 0.56) { base = srgb(vec3(0.84, 0.7, 0.36)); furrow = 0.3; }
  else if (h < 0.64) { base = srgb(vec3(0.62, 0.73, 0.36)); mown = 1.0; }
  else if (h < 0.72) { base = srgb(vec3(0.53, 0.38, 0.25)); furrow = 1.0; }
  else if (h < 0.76) base = srgb(vec3(0.9, 0.8, 0.2));
  else if (h < 0.88) base = srgb(vec3(0.19, 0.36, 0.18));
  else base = srgb(vec3(0.8, 0.7, 0.47));
}

void main(){
  gFoot = max(length(dFdx(vWPos)), length(dFdy(vWPos)));
  vec3 N = normalize(vN);
  vec2 xz = vWPos.xz;
  vec2 uv = (xz + uMapHalf) / (2.0 * uMapHalf);
  vec4 A = texture(uMapA, uv);
  vec4 B = texture(uMapB, uv);
  vec4 C = texture(uMapC, uv);
  vec3 base = A.rgb;
  float road = B.r, mown = B.g, furrow = B.b;
  float ang = C.r * 3.14159;
  float tram = C.g;
  // Out past the painted map: the procedural patchwork, blended in over the last 300 m.
  vec2 edge = abs(xz) - (uMapHalf - 300.0);
  float far = smoothstep(0.0, 300.0, max(edge.x, edge.y));
  if (far > 0.0) {
    vec3 fb; float fm, ff, fa;
    farField(xz, fb, fm, ff, fa);
    base = mix(base, fb, far); mown = mix(mown, fm, far); furrow = mix(furrow, ff, far);
    road *= 1.0 - far; tram *= 1.0 - far;
    if (far > 0.5) ang = fa;
  }
  // The village's fine painted ground (gardens, yards, square, lanes) over the field map.
  vec2 vuv = (xz - uMapVRect.xy) / (2.0 * uMapVRect.z) + 0.5;
  // (Sampled outside any branch: mip selection needs the derivatives.)
  float vm = texture(uMapVM, vuv).r * step(max(abs(vuv.x - 0.5), abs(vuv.y - 0.5)), 0.499);
  vec3 vcol = texture(uMapV, vuv).rgb;
  base = mix(base, vcol, vm);
  mown *= 1.0 - vm; furrow *= 1.0 - vm; tram *= 1.0 - vm; road *= 1.0 - vm;
  vec2 dir = vec2(cos(ang), sin(ang));
  float across = dot(xz, vec2(-dir.y, dir.x));
  // Broad soil / sward variation (moisture, wear) so no parcel is a flat swatch.
  float lo = fbm2(xz * 0.0045);
  float mid = vnoise(xz * 0.035);
  base *= 0.86 + 0.26 * lo + 0.1 * (mid - 0.5) * footKeep(0.035);
  // Low-frequency colour patches inside a field (damp hollows bluer, dry knolls warmer)...
  float patchK = fbm2(xz * 0.011 + 3.1);
  base *= mix(vec3(0.9, 0.99, 1.05), vec3(1.1, 1.04, 0.86), smoothstep(0.3, 0.7, patchK));
  // ...and painted grass strokes up close (band-limited inside brush()).
  base *= 0.8 + 0.4 * brush(vWPos, N);
  // Tussocks and darker clumps close up, and broad yellow-green / blue-green drifts across a field.
  float tus = vnoise(xz * 1.3 + 7.0);
  base *= 1.0 - 0.16 * smoothstep(0.55, 0.85, tus) * footKeep(1.3) * (1.0 - furrow);
  float drift = vnoise(mat2(0.8, 0.6, -0.6, 0.8) * xz * 0.05 + 2.0);
  base *= mix(vec3(0.9, 0.99, 1.05), vec3(1.09, 1.04, 0.88), drift);
  // Mown hay: alternating light/dark bands 9 m wide along the rows.
  float band = aaSquare(across / 18.0);
  base *= 1.0 + mown * 0.16 * (band - 0.5) * 2.0;
  // Plough furrows / crop rows (2.4 m), band-limited: they fade to their mean before they alias.
  float row = 0.5 + 0.5 * sin(across * 2.618);
  float rk = footKeep(0.42);
  base *= 1.0 - furrow * 0.28 * mix(0.5, row, rk);
  // Tractor tramlines through the crops every 24 m.
  base *= 1.0 - tram * 0.22 * aaLine(across / 24.0 + 0.5, 0.05);
  // Pasture flecks (clover, buttercups) close up.
  float fl = hash12(floor(xz * 1.7));
  base = mix(base, base * vec3(1.25, 1.2, 0.75), step(0.94, fl) * 0.45 * footKeep(1.7) * (1.0 - furrow));
  // Steep banks show a little earth.
  float slope = 1.0 - N.y;
  base = mix(base, base * vec3(0.92, 0.82, 0.7), smoothstep(0.08, 0.25, slope) * 0.5);
  // River and lake margins: muddy sand, then reeds.
  float y = vWPos.y;
  float bank = 1.0 - smoothstep(0.7, 2.3, y);
  base = mix(base, srgb(vec3(0.52, 0.47, 0.35)) * (0.9 + 0.2 * mid), bank * (1.0 - smoothstep(-0.3, 0.6, -y)) * 0.8);
  base = mix(base, srgb(vec3(0.36, 0.48, 0.24)), smoothstep(1.5, 2.2, y) * (1.0 - smoothstep(2.2, 3.0, y)) * 0.45);
  // Dusty pale roads with a darker grassy verge; crisp edges from the blurred mask.
  float rk2 = smoothstep(0.5 - fwidth(road) * 0.8 - 0.02, 0.5 + fwidth(road) * 0.8 + 0.02, road);
  vec3 roadCol = srgb(vec3(0.84, 0.76, 0.6)) * (0.9 + 0.16 * vnoise(xz * 0.6) * footKeep(0.6) + 0.08 * lo);
  base *= 1.0 - 0.14 * smoothstep(0.12, 0.45, road) * (1.0 - rk2);
  base = mix(base, roadCol, rk2);
  // A little vibrance: the warm low key light would otherwise turn every green to olive.
  float lum = dot(base, vec3(0.2126, 0.7152, 0.0722));
  base = max(mix(vec3(lum), base, 1.16), 0.0);
  float paint = 1.0;
  // Painted hill shading: the cel ramp alone keeps every gentle slope fully lit under a low sun, so
  // the land also takes a soft gradient by its turn to the light (the downs read as forms).
  float ndl = dot(N, uSunDir);
  float sunUp = max(uSunDir.y, 0.05);
  float turn = (ndl - sunUp) / max(1.0 - sunUp, 0.2);
  base *= clamp(1.0 + turn * 2.2, 0.62, 1.25) * mix(1.0, 0.92, smoothstep(0.0, 0.3, -turn));
  vec3 col = toon(base, N, vWPos, 0.0, paint, 0.0, 0.04);
  // Cloud shadows drifting over the fields: a soft cool shade, not black.
  col = mix(col, col * vec3(0.4, 0.44, 0.62), cloudShadow(vWPos.xz) * 0.85);
  col = applyFog(col, vWPos);
  writeOut(col, N, uMask);
}
`;

export function terrainMaterial(far = false): THREE.ShaderMaterial {
  const m = new THREE.ShaderMaterial({
    glslVersion: THREE.GLSL3,
    uniforms: { ...G, ...LAND, uId: { value: ID.ground }, uMask: { value: 0.35 } },
    vertexShader: TERRAIN_VS,
    fragmentShader: TERRAIN_FS,
    defines: far ? { FAR: 1 } : {},
  });
  m.name = far ? "terrain-far" : "terrain";
  return m;
}

const WATER_VS = /* glsl */ `
${COMMON}
out vec3 vWPos;
void main(){
  vec4 wp = modelMatrix * vec4(position, 1.0);
  vWPos = wp.xyz;
  gl_Position = projectionMatrix * viewMatrix * wp;
}
`;

const WATER_FS = /* glsl */ `
${COMMON}
${OUT}
${LAND_GLSL}
uniform sampler2D uRefl;
uniform mat4 uReflMat;
uniform float uReflOn;
in vec3 vWPos;

// Ripple slope (d/dx, d/dz) from drifting noise layers, faded by pixel footprint. Each layer is
// turned and domain-warped so the value-noise lattice never lines up into a visible tile.
float rn(vec2 q){ return vnoise(q + vec2(vnoise(q * 0.37 + 5.1), vnoise(q * 0.37 + 9.7)) * 1.6); }
vec2 ripple(vec2 p, float keep1, float keep2){
  vec2 w = uWindDir;
  vec2 q1 = mat2(0.94, 0.34, -0.34, 0.94) * p * 0.09 + w * uTime * 0.05;
  vec2 q2 = mat2(0.8, -0.6, 0.6, 0.8) * p * 0.29 - w * uTime * 0.11;
  float e = 0.15;
  float a0 = rn(q1), ax = rn(q1 + vec2(e, 0.0)), az = rn(q1 + vec2(0.0, e));
  float b0 = rn(q2), bx = rn(q2 + vec2(e, 0.0)), bz = rn(q2 + vec2(0.0, e));
  return (vec2(ax - a0, az - a0) * 0.09 * keep1 + vec2(bx - b0, bz - b0) * 0.29 * 0.4 * keep2) / e;
}

void main(){
  gFoot = max(length(dFdx(vWPos)), length(dFdy(vWPos)));
  vec3 V = normalize(cameraPosition - vWPos);
  float dist = length(cameraPosition - vWPos);
  vec2 sl = ripple(vWPos.xz, footKeep(0.09), footKeep(0.29)) * 0.2;
  vec3 N = normalize(vec3(-sl.x, 1.0, -sl.y));
  float depth = max(0.0, -hAt(vWPos.xz));
  float ndv = max(dot(N, V), 0.0);
  float fres = 0.12 + 0.88 * pow(1.0 - ndv, 4.0);
  vec3 R = reflect(-V, N);
  // Painted water reads as water from any height: the mirror (trees, houses, clouds) over a sky taken
  // higher up than the true reflection (a grazing view would only mirror the gold horizon and turn
  // the river to sand), cooled a little, over a deep teal body.
  // Mostly the pale warm low sky (the lake as a mirror of the evening), a little of the blue above.
  // Balloon Ride: seen from above the true reflection is the blue zenith and the lake went grey-blue
  // under a peach sky; it mirrors the warm low sky round the sun instead, a little blue on top.
  vec3 Rw = normalize(vec3(mix(R.xz, normalize(uGlintDir.xz + 1e-4) * 0.6 + R.xz * 0.4, 0.5), 0.0).xzy);
  vec3 skyHi = mix(skyColor(normalize(vec3(Rw.x, max(R.y, 0.0) * 0.1 + 0.15, Rw.z))), skyColor(normalize(vec3(R.x, max(R.y, 0.0) * 0.5 + 0.45, R.z))), 0.12);
  // Seen steeply from above (the basket's look-down) the river must still read as water: a cool
  // blue of the high sky over a darker teal body, not the warm low sky (that read as a dusty road).
  float steep = smoothstep(0.55, 0.92, V.y);
  vec3 zen = skyColor(normalize(vec3(R.x * 0.35, 1.0, R.z * 0.35)));
  float zl = dot(zen, vec3(0.2126, 0.7152, 0.0722));
  zen = max(mix(vec3(zl), zen, 1.25), 0.0) * vec3(0.92, 1.0, 1.08);
  skyHi = mix(skyHi, zen, steep * 0.75);
  vec3 refl = skyHi;
  if (uReflOn > 0.5) {
    vec4 rp = uReflMat * vec4(vWPos.x, 0.0, vWPos.z, 1.0);
    vec2 ruv = rp.xy / rp.w + sl * 0.015;
    vec4 rc = texture(uRefl, clamp(ruv, vec2(0.001), vec2(0.999)));
    // Keep the mirror only where it holds something darker than the sky (trees, houses, banks):
    // mixing the true golden sky with the painted one would only grey the water.
    vec3 skyTrue = skyColor(normalize(vec3(R.x, max(R.y, 0.02), R.z)));
    float lumW = dot(skyTrue - rc.rgb, vec3(0.2126, 0.7152, 0.0722));
    float obj = smoothstep(0.02, 0.12, lumW / max(dot(skyTrue, vec3(0.2126, 0.7152, 0.0722)), 0.05)) * rc.a;
    refl = mix(skyHi, rc.rgb * vec3(0.9, 0.95, 1.0), obj * 0.85);
  }
  // A richer, slightly darker mirror than the land's brightest fields, so the water reads as
  // water from above (warm and saturated), not as a pale road.
  float rl = dot(refl, vec3(0.2126, 0.7152, 0.0722));
  refl = max(mix(vec3(rl), refl, 1.15), 0.0) * 0.86;
  refl *= uWaterRefl * vec3(1.02, 0.98, 0.95);
  vec3 body = mix(uWaterShallow * 0.6, mix(vec3(0.03, 0.14, 0.17), uWaterDeep, 0.5), smoothstep(0.1, 1.6, depth));
  body *= uWorldTint;
  vec3 col = mix(body, refl, clamp(0.62 + fres * 0.3 - steep * 0.12, 0.0, 0.9));
  // Ripple glints: the crests that face the sky catch it a little brighter.
  col *= 1.0 + 0.05 * clamp(dot(sl, normalize(uGlintDir.xz + 1e-4)), -1.0, 1.0);
  // A darker band under the banks (their reflection and shade), the open water paler.
  col *= mix(0.62, 1.0, smoothstep(0.15, 1.4, depth));
  // Sun glitter.
  float g = pow(max(dot(R, uGlintDir), 0.0), 380.0) * 10.0 + pow(max(dot(R, uGlintDir), 0.0), 40.0) * 0.25;
  col += uGlintCol * g * uGlint * mix(1.0, 0.4, smoothstep(0.2, 1.0, gFoot));
  col = applyFog(col, vWPos);
  writeOut(col, vec3(0.0, 1.0, 0.0), uMask);
}
`;

export function waterMaterial(): THREE.ShaderMaterial {
  const m = new THREE.ShaderMaterial({
    glslVersion: THREE.GLSL3,
    uniforms: { ...G, ...LAND, ...REFL, uId: { value: ID.water }, uMask: { value: 0.0 } },
    vertexShader: WATER_VS,
    fragmentShader: WATER_FS,
  });
  m.name = "water";
  return m;
}
