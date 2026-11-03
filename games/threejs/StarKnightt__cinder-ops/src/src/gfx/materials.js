import * as THREE from 'three';
import { bakeSurface, bakeImage, SURF_GUNMETAL, SURF_BAKELITE } from './bake.js';
import { PLASTER_MICRO, PLASTER_MASK, PLASTER_MACRO, STAIN_A, STAIN_B, STAIN_C, STAIN_D } from '../world/stoneTex.js';

/* CS2 warm-dust PBR. Shaders author in 0–1 tile space; meshes carry metre UVs. */

const SURF_ASPHALT = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float macro = pfbm(uv * 1.6 + 1.7, vec2(1.6), 5);
  float n = pfbm(uv * 7.0, vec2(7.0), 5);
  float grit = pfbm(uv * 32.0 + 4.0, vec2(32.0), 3);
  vec2 w = pworley(uv * 4.2 + macro * 0.4, vec2(4.2));
  float crack = sstep(0.07, 0.016, w.y - w.x) * sstep(0.08, 0.55, n + macro);
  float dust = sstep(0.08, 0.72, pfbm(uv * 1.1 + 8.2, vec2(1.1), 4));
  float drift = sstep(0.48, 0.82, pfbm(uv * 0.7 + 14.0, vec2(0.7), 4));
  float stain = sstep(0.52, 0.80, pfbm(uv * 2.2 + 21.0, vec2(2.2), 3));
  float lane = abs(uv.x - 0.5);
  float tire = sstep(0.24, 0.05, abs(lane - 0.07)) * sstep(0.12, 0.78, pfbm(vec2(uv.x * 4.0, uv.y * 16.0), vec2(4.0, 16.0), 3));
  float tire2 = sstep(0.20, 0.04, abs(lane - 0.15)) * sstep(0.16, 0.82, pfbm(vec2(uv.x * 3.0 + 2.0, uv.y * 12.0), vec2(3.0, 12.0), 2));
  float tire3 = sstep(0.16, 0.03, abs(lane - 0.22)) * sstep(0.22, 0.80, pfbm(vec2(uv.x * 2.4 + 5.0, uv.y * 9.0), vec2(2.4, 9.0), 2));
  tire = max(tire, max(tire2 * 0.82, tire3 * 0.55));
  vec2 peb = pworley(uv * 22.0 + 3.0, vec2(22.0));
  float pebble = sstep(0.16, 0.05, peb.x) * sstep(0.2, 0.6, n);
  height = n * 0.22 + grit * 0.10 - crack * 0.42 - stain * 0.08 + pebble * 0.18 - tire * 0.06;
  vec3 tar = vec3(0.52, 0.42, 0.32);
  vec3 gritC = vec3(0.62, 0.52, 0.40);
  vec3 sand = vec3(0.72, 0.60, 0.46);
  vec3 pale = vec3(0.78, 0.66, 0.50);
  albedo = mix(tar, gritC, sstep(-0.15, 0.4, macro) * 0.7 + grit * 0.35);
  albedo = mix(albedo, sand, dust * 0.78);
  albedo = mix(albedo, pale, drift * 0.58);
  albedo = mix(albedo, vec3(0.14, 0.11, 0.08), crack);
  albedo = mix(albedo, vec3(0.16, 0.12, 0.08), stain * 0.50);
  albedo = mix(albedo, vec3(0.12, 0.10, 0.07), tire * 0.72);
  albedo = mix(albedo, vec3(0.38, 0.30, 0.20), pebble);
  rough = 0.90 + grit * 0.06 + crack * 0.08 - dust * 0.04 + pebble * 0.04;
  ao = 0.88 - crack * 0.50 - stain * 0.12 - pebble * 0.08;
}
`;

const SURF_CONCRETE = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 6.0, vec2(6.0), 5);
  float pit = pworley(uv * 20.0, vec2(20.0)).x;
  float stain = pfbm(uv * 2.2 + 8.0, vec2(2.2), 4);
  float grit = pfbm(uv * 18.0, vec2(18.0), 3);
  float dirt = sstep(0.05, 0.70, pfbm(uv * 0.9 + 19.0, vec2(0.9), 4));
  float edge = sstep(0.02, 0.16, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
  /* Cluster the air-pocket pits into sparse patches instead of an even
   * dot-speckle over the whole face. */
  float pitMask = sstep(0.08, 0.30, pfbm(uv * 1.4 + 3.0, vec2(1.4), 3));
  float pits = sstep(0.24, 0.08, pit) * pitMask;
  height = n * 0.28 - pits * 0.20 - dirt * 0.06;
  albedo = vec3(0.48, 0.44, 0.38) + n * 0.07 + grit * 0.03;
  albedo *= mix(0.62, 1.0, sstep(-0.25, 0.42, stain));
  albedo = mix(albedo, vec3(0.28, 0.22, 0.15), dirt * 0.55);
  albedo -= sstep(0.20, 0.05, pit) * pitMask * 0.08;
  albedo *= 0.78 + edge * 0.22;
  rough = 0.88 - n * 0.06 + pit * 0.06 + dirt * 0.06;
  ao = 0.78 + n * 0.10 - pits * 0.10 - (1.0 - edge) * 0.16;
}
`;

/* Big open ground slabs (plaza / yard / forecourt). Same bones as concrete
 * but with macro dust patches, diagonal twin tire tracks and sparse debris
 * so the lower third of every frame stops reading as one khaki plane. */
const SURF_SLAB = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 6.0, vec2(6.0), 5);
  float grit = pfbm(uv * 18.0, vec2(18.0), 3);
  float macro = pfbm(uv * 0.55 + 3.3, vec2(0.55), 4);
  float dust = sstep(0.10, 0.74, pfbm(uv * 1.05 + 8.2, vec2(1.05), 4));
  float drift = sstep(0.50, 0.84, pfbm(uv * 0.72 + 14.0, vec2(0.72), 4));
  float stain = sstep(0.55, 0.85, pfbm(uv * 1.8 + 21.0, vec2(1.8), 3));
  vec2 w = pworley(uv * 3.2 + macro, vec2(3.2));
  float crack = sstep(0.05, 0.012, w.y - w.x) * sstep(0.10, 0.60, n + macro);
  float lane = uv.x * 0.34 + uv.y;
  float tire = max(
    sstep(0.075, 0.018, abs(fract(lane * 0.5) - 0.30) - 0.025),
    sstep(0.075, 0.018, abs(fract(lane * 0.5) - 0.42) - 0.025));
  tire *= sstep(0.14, 0.66, pfbm(vec2(uv.x * 3.0, uv.y * 11.0), vec2(3.0, 11.0), 3));
  vec2 peb = pworley(uv * 16.0 + 5.0, vec2(16.0));
  float debris = sstep(0.14, 0.045, peb.x) * sstep(0.30, 0.68, pfbm(uv * 1.3 + 31.0, vec2(1.3), 3));
  vec2 pit = pworley(uv * 14.0 + 2.0, vec2(14.0));
  float pits = sstep(0.20, 0.07, pit.x) * sstep(0.25, 0.60, pfbm(uv * 1.2 + 41.0, vec2(1.2), 3));
  height = n * 0.20 + grit * 0.06 - crack * 0.34 + debris * 0.16 - tire * 0.05 - pits * 0.10;
  vec3 base = vec3(0.42, 0.375, 0.30);
  vec3 sandy = vec3(0.56, 0.47, 0.35);
  vec3 pale = vec3(0.64, 0.545, 0.41);
  albedo = base + n * 0.06 + grit * 0.03;
  albedo *= mix(0.66, 1.0, sstep(-0.2, 0.45, macro));
  albedo = mix(albedo, sandy, dust * 0.60);
  albedo = mix(albedo, pale, drift * 0.42);
  albedo = mix(albedo, vec3(0.16, 0.12, 0.08), crack);
  albedo = mix(albedo, vec3(0.18, 0.14, 0.10), stain * 0.50);
  albedo = mix(albedo, albedo * 0.55, tire * 0.85);
  albedo = mix(albedo, vec3(0.35, 0.28, 0.20), debris);
  albedo -= pits * 0.10;
  rough = 0.90 + grit * 0.05 - dust * 0.05 + crack * 0.06;
  ao = 0.86 - crack * 0.42 - stain * 0.12 - tire * 0.06 - debris * 0.06 - pits * 0.10;
}
`;

const SURF_BRICK = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  vec2 grid = uv * vec2(6.0, 13.0);
  float row = floor(grid.y);
  grid.x += mod(row, 2.0) * 0.5;
  vec2 f = fract(grid);
  float mx = sstep(0.07, 0.025, min(f.x, 1.0 - f.x));
  float my = sstep(0.11, 0.035, min(f.y, 1.0 - f.y));
  float mortar = max(mx, my);
  float n = pfbm(uv * 16.0, vec2(16.0), 4);
  float chip = pworley(uv * 18.0, vec2(18.0)).x;
  float soot = sstep(0.05, 0.55, pfbm(uv * 1.8 + 3.4, vec2(1.8), 4));
  float brickN = pfbm(floor(grid) + 5.0, vec2(16.0), 3);
  height = (1.0 - mortar) * (0.58 + n * 0.18) - sstep(0.18, 0.05, chip) * 0.16;
  vec3 brick = vec3(0.62, 0.42, 0.30) + n * 0.05;
  brick += vec3(0.06, -0.01, -0.02) * brickN;
  brick *= mix(1.0, 0.78, soot * 0.55);
  albedo = mix(brick, vec3(0.52, 0.46, 0.38), mortar);
  rough = mix(0.86, 0.94, mortar);
  ao = mix(1.0, 0.72, mortar) - soot * 0.06;
}
`;

const SURF_METAL = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 10.0, vec2(10.0), 4);
  float scratch = abs(pfbm(vec2(uv.x * 52.0, uv.y * 2.4), vec2(52.0, 2.4), 3));
  float scratch2 = abs(pfbm(vec2(uv.x * 16.0 + 4.0, uv.y * 10.0), vec2(16.0, 10.0), 2));
  float rust = sstep(0.22, 0.58, pfbm(uv * 4.2 + 2.0, vec2(4.2), 4));
  float wear = sstep(0.28, 0.78, pfbm(uv * 2.6 + 9.0, vec2(2.6), 3));
  float edge = sstep(0.04, 0.18, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
  height = n * 0.12 - scratch * 0.10 - scratch2 * 0.04 - rust * 0.06;
  vec3 bare = vec3(0.14, 0.138, 0.128);
  vec3 worn = vec3(0.42, 0.38, 0.30);
  albedo = mix(bare, worn, wear * 0.62);
  albedo = mix(albedo, vec3(0.40, 0.16, 0.05), rust * 0.70);
  albedo += scratch * 0.14;
  albedo = mix(albedo, vec3(0.50, 0.48, 0.42), (1.0 - edge) * 0.35);
  rough = mix(0.18, 0.68, rust) - scratch * 0.22 + wear * 0.12 - (1.0 - edge) * 0.16;
  ao = 0.92 - rust * 0.08;
}
`;

const SURF_POLYMER = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 16.0, vec2(16.0), 3);
  float weave = sin(uv.x * 210.0) * sin(uv.y * 210.0);
  float dust = sstep(0.25, 0.65, pfbm(uv * 3.4 + 6.0, vec2(3.4), 3));
  float scuff = abs(pfbm(vec2(uv.x * 36.0, uv.y * 4.0), vec2(36.0, 4.0), 2));
  height = n * 0.07 + weave * 0.012 - scuff * 0.02;
  vec3 fde = vec3(0.30, 0.248, 0.185);
  albedo = fde * (0.88 + n * 0.10);
  albedo = mix(albedo, vec3(0.30, 0.26, 0.20), dust * 0.35);
  albedo += scuff * 0.03;
  rough = 0.52 + n * 0.10 + dust * 0.08;
  ao = 0.95;
}
`;

const SURF_PLASTER = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 8.0, vec2(8.0), 4);
  float grit = pfbm(uv * 22.0, vec2(22.0), 3);
  float grime = sstep(0.08, 0.72, pfbm(uv * 1.15 + 11.0, vec2(1.15), 4));
  float leak = sstep(0.52, 0.90, pfbm(vec2(uv.x * 3.4, uv.y * 1.05) + 4.0, vec2(3.4, 1.05), 4));
  float drip = sstep(0.64, 0.94, pfbm(vec2(uv.x * 9.0 + 7.0, uv.y * 0.50), vec2(9.0, 0.50), 3));
  float soot = sstep(0.12, 0.74, pfbm(uv * 0.7 + 21.0, vec2(0.7), 4));
  float hair = sstep(0.045, 0.008, pworley(uv * 7.0, vec2(7.0)).y - pworley(uv * 7.0, vec2(7.0)).x);
  float base = sstep(0.88, 0.06, uv.y);
  height = 0.50 + n * 0.05 + grit * 0.02 - leak * 0.04 - hair * 0.06 - base * 0.03;
  vec3 clean = vec3(0.60, 0.54, 0.44);
  vec3 dirty = vec3(0.38, 0.33, 0.26);
  vec3 leakC = vec3(0.22, 0.17, 0.12);
  albedo = mix(clean, dirty, grime * 0.70);
  albedo = mix(albedo, leakC, max(leak, drip) * 0.50);
  albedo = mix(albedo, vec3(0.18, 0.14, 0.10), soot * 0.42);
  albedo = mix(albedo, vec3(0.24, 0.18, 0.12), base * 0.55);
  albedo *= 0.88 + n * 0.10 + grit * 0.04;
  rough = 0.88 + grime * 0.06 + leak * 0.04;
  ao = 0.86 - grime * 0.08 - leak * 0.10 - hair * 0.08 - base * 0.12;
}
`;

const SURF_GLOVE = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 9.0, vec2(9.0), 3);
  float crease = abs(pfbm(vec2(uv.x * 5.5, uv.y * 13.0), vec2(5.5, 13.0), 3));
  /* c28: ONE uniform tan/olive. Form is AO in the creases only — the old
   * dark/mid mix + stitch albedo swaps read as striped taffy / chocolate
   * segments under the vm key. */
  albedo = vec3(0.138, 0.124, 0.082);
  height = crease * 0.035 + n * 0.015;
  rough = 0.93 + n * 0.03;
  ao = 0.93 - crease * 0.16;
}
`;

const SURF_AWNING = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 10.0, vec2(10.0), 3);
  float stripe = sstep(0.40, 0.60, fract(uv.y * 7.5 + n * 0.03));
  /* Stitched seams every couple of stripe widths + a coarse canvas weave. */
  float sy = fract(uv.y * 3.75 + n * 0.015);
  float seam = sstep(0.045, 0.012, min(sy, 1.0 - sy));
  float weave = abs(sin(uv.x * 140.0)) * abs(sin(uv.y * 140.0));
  float fade = sstep(0.25, 0.80, pfbm(uv * 2.2 + 7.0, vec2(2.2), 3));
  vec3 terra = vec3(0.36, 0.20, 0.14);
  vec3 cream = vec3(0.56, 0.48, 0.36);
  albedo = mix(terra, cream, stripe);
  albedo = mix(albedo, albedo * 1.18, fade * 0.5);
  albedo *= 0.86 + n * 0.10 + weave * 0.05;
  albedo *= 1.0 - seam * 0.30;
  height = n * 0.08 + stripe * 0.02 - seam * 0.05 + weave * 0.015;
  rough = 0.90 + n * 0.04 + seam * 0.04;
  ao = 0.90 - seam * 0.06;
}
`;

const SURF_FABRIC = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 14.0, vec2(14.0), 4);
  float twill = abs(sin((uv.x + uv.y) * 88.0)) * abs(sin((uv.x - uv.y) * 88.0));
  float fade = sstep(0.15, 0.75, pfbm(uv * 2.0 + 5.0, vec2(2.0), 4));
  float dirt = sstep(0.35, 0.78, pfbm(uv * 3.2 + 9.0, vec2(3.2), 3));
  height = n * 0.14 + twill * 0.07;
  vec3 base = vec3(0.28, 0.24, 0.16);
  albedo = mix(base, vec3(0.40, 0.32, 0.20), fade * 0.55);
  albedo = mix(albedo, vec3(0.16, 0.14, 0.10), dirt * 0.40);
  albedo *= 0.78 + n * 0.22 + twill * 0.10;
  rough = 0.88 + twill * 0.08 + dirt * 0.04;
  ao = 0.86 - twill * 0.08 - dirt * 0.06;
}
`;

const SURF_RUST = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 6.0, vec2(6.0), 5);
  float flake = pworley(uv * 14.0, vec2(14.0)).x;
  float stain = pfbm(uv * 2.4 + 4.0, vec2(2.4), 4);
  float pit = sstep(0.22, 0.06, flake);
  height = n * 0.24 - pit * 0.2 - stain * 0.06;
  vec3 deep = vec3(0.10, 0.045, 0.028);
  vec3 mid = vec3(0.22, 0.10, 0.045);
  vec3 bright = vec3(0.30, 0.14, 0.055);
  albedo = mix(deep, mid, sstep(-0.2, 0.35, n));
  albedo = mix(albedo, bright, sstep(0.25, 0.55, n) * (1.0 - stain) * 0.45);
  albedo = mix(albedo, vec3(0.08, 0.055, 0.040), sstep(0.2, 0.55, stain));
  rough = 0.84 + n * 0.10 + pit * 0.06;
  ao = 0.86 - pit * 0.22;
}
`;

const SURF_WOOD = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  /* Plank-and-batten crate wood (fix 6). The old sin band across uv.y
   * crossed the plank gaps into a checkerboard that read as a UV test
   * pattern. Grain now runs ALONG the planks, with two batten strips and
   * nail dots. */
  float plank = uv.x * 5.0;
  float id = floor(plank);
  float f = fract(plank);
  float gap = max(sstep(0.045, 0.010, f), sstep(0.045, 0.010, 1.0 - f));
  float pvar = fract(sin(id * 12.9898) * 43758.5453);
  float grain = pfbm(vec2(uv.x * 46.0, uv.y * 3.0) + id * 7.0, vec2(46.0, 3.0), 4);
  float knot = sstep(0.09, 0.02, pworley(uv * 4.0 + id, vec2(4.0)).x)
             * sstep(0.55, 0.85, pvar);
  float n = pfbm(uv * 9.0, vec2(9.0), 3);
  float b0 = sstep(0.060, 0.042, abs(uv.y - 0.16));
  float b1 = sstep(0.060, 0.042, abs(uv.y - 0.84));
  float batten = max(b0, b1);
  float bgrain = pfbm(vec2(uv.x * 2.8, uv.y * 44.0), vec2(2.8, 44.0), 3);
  float nail = max(
    sstep(0.016, 0.007, length(vec2((f - 0.5) * 0.2, uv.y - 0.16))),
    sstep(0.016, 0.007, length(vec2((f - 0.5) * 0.2, uv.y - 0.84))));
  vec3 light = vec3(0.285, 0.170, 0.080);
  vec3 dark = vec3(0.150, 0.085, 0.040);
  albedo = mix(dark, light, 0.28 + pvar * 0.26 + grain * 0.30);
  albedo *= 0.86 + n * 0.12;
  albedo = mix(albedo, albedo * 0.68, knot);
  albedo = mix(albedo, vec3(0.08, 0.05, 0.02), gap * (1.0 - batten));
  vec3 battenC = mix(vec3(0.125, 0.070, 0.034), vec3(0.230, 0.135, 0.062), 0.35 + bgrain * 0.45);
  albedo = mix(albedo, battenC, batten);
  albedo = mix(albedo, vec3(0.10, 0.095, 0.085), nail * 0.9);
  height = 0.20 + grain * 0.10 - gap * 0.38 * (1.0 - batten) + batten * 0.26 + nail * 0.05 - knot * 0.06;
  rough = mix(0.66, 0.94, gap) + (1.0 - grain) * 0.08 + batten * 0.04 - nail * 0.25;
  ao = 0.92 - gap * 0.34 * (1.0 - batten) - knot * 0.10
     - max(sstep(0.075, 0.058, abs(uv.y - 0.16)), sstep(0.075, 0.058, abs(uv.y - 0.84))) * (1.0 - batten) * 0.30;
}
`;

const SURF_TRASH = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float wrinkle = pfbm(uv * 10.0, vec2(10.0), 5);
  float cell = pworley(uv * 7.0, vec2(7.0)).x;
  float gloss = sstep(0.15, 0.55, pfbm(uv * 3.0 + 6.0, vec2(3.0), 3));
  height = wrinkle * 0.5 - cell * 0.18;
  vec3 bag = vec3(0.07, 0.068, 0.055);
  vec3 hi = vec3(0.14, 0.13, 0.10);
  albedo = mix(bag, hi, wrinkle * 0.55 + gloss * 0.15);
  rough = mix(0.70, 0.32, gloss) + wrinkle * 0.12;
  ao = 0.86 - cell * 0.12;
}
`;

const SURF_PAINT = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 8.0, vec2(8.0), 4);
  float scratch = abs(pfbm(vec2(uv.x * 38.0, uv.y * 3.2), vec2(38.0, 3.2), 3));
  float chip = sstep(0.38, 0.78, pfbm(uv * 2.8 + 5.0, vec2(2.8), 4));
  float rust = sstep(0.48, 0.82, pfbm(uv * 3.8 + 9.0, vec2(3.8), 3)) * chip;
  float dust = sstep(0.22, 0.70, pfbm(uv * 1.6 + 12.0, vec2(1.6), 3));
  height = n * 0.14 - chip * 0.22 - scratch * 0.07;
  vec3 coat = vec3(0.42, 0.22, 0.14);
  vec3 primer = vec3(0.18, 0.14, 0.10);
  vec3 rustC = vec3(0.32, 0.12, 0.04);
  albedo = mix(coat, primer, chip);
  albedo = mix(albedo, rustC, rust);
  albedo = mix(albedo, vec3(0.40, 0.32, 0.22), dust * 0.40);
  albedo *= 0.80 + n * 0.16;
  albedo += scratch * 0.08;
  rough = mix(0.28, 0.88, chip) + scratch * 0.16 + dust * 0.10;
  ao = 0.88 - chip * 0.18;
}
`;

const SURF_AKWOOD = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  /* Real wood grain: fine streaks elongated ALONG uv.x (every AK wood part
   * maps uv.x to its long axis), LOW value contrast with a soft cathedral
   * wobble. The old dense sine rings read as laminate flooring stripes in
   * the 4x crop (fix 2). */
  /* Muted grain (fix 9): the c16 band term drew ruler-straight varnish
   * streaks down the stock. Lower band frequency + amplitude, more noise
   * wobble so no line runs straight, and a matter finish. */
  /* Pore/band frequency lowered (fix 3, c18): the 140-cycle pore rows
   * squeezed by tight cross-UVs became bright rib stripes on the stock. */
  float streak = pfbm(vec2(uv.x * 2.2, uv.y * 78.0), vec2(2.2, 78.0), 5);
  float streak2 = pfbm(vec2(uv.x * 1.0, uv.y * 32.0) + 3.2, vec2(1.0, 32.0), 4);
  /* No sine-around-Y bands — those wrapped spindles into tiger-stripe coils. */
  float cathedral = pfbm(vec2(uv.x * 1.4, uv.y * 5.5) + 2.0, vec2(1.4, 5.5), 3);
  float pore = pfbm(vec2(uv.x * 16.0, uv.y * 88.0), vec2(16.0, 88.0), 3);
  float stain = sstep(0.25, 0.75, pfbm(uv * 2.4 + 6.0, vec2(2.4), 3));
  height = streak * 0.18 + streak2 * 0.08 - pore * 0.04 + cathedral * 0.04;
  /* Warm brown, not orange: ~20% less sat, slightly darker than c24. */
  vec3 light = vec3(0.150, 0.118, 0.082);
  vec3 dark = vec3(0.088, 0.068, 0.048);
  albedo = mix(dark, light, 0.34 + streak * 0.38 + streak2 * 0.16 + cathedral * 0.10);
  albedo = mix(albedo, vec3(0.078, 0.056, 0.034), stain * 0.22);
  albedo *= 0.94 + pore * 0.05;
  rough = 0.64 + (1.0 - streak) * 0.16 + stain * 0.08 + pore * 0.04;
  ao = 0.93 - stain * 0.06 - (1.0 - streak) * 0.03;
}
`;

const SURF_DIRT = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 5.0, vec2(5.0), 5);
  float peb = pworley(uv * 14.0, vec2(14.0)).x;
  float drift = sstep(0.15, 0.75, pfbm(uv * 1.2 + 4.0, vec2(1.2), 4));
  height = n * 0.28 - sstep(0.2, 0.06, peb) * 0.12;
  vec3 dust = vec3(0.42, 0.34, 0.22);
  vec3 sand = vec3(0.58, 0.48, 0.32);
  albedo = mix(dust, sand, drift * 0.65 + n * 0.2);
  albedo = mix(albedo, vec3(0.30, 0.24, 0.16), sstep(0.18, 0.05, peb) * 0.4);
  rough = 0.92 + n * 0.04;
  ao = 0.88 - sstep(0.18, 0.05, peb) * 0.1;
}
`;

const SURF_GRANITE = /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  float n = pfbm(uv * 8.0, vec2(8.0), 4);
  float speckle = pworley(uv * 36.0, vec2(36.0)).x;
  float vein = abs(pfbm(vec2(uv.x * 3.0, uv.y * 14.0), vec2(3.0, 14.0), 3));
  height = n * 0.16 - sstep(0.2, 0.05, speckle) * 0.08;
  albedo = vec3(0.26, 0.25, 0.235) + n * 0.03;
  albedo = mix(albedo, vec3(0.42, 0.41, 0.39), sstep(0.32, 0.12, speckle) * 0.4);
  albedo = mix(albedo, vec3(0.10, 0.095, 0.09), sstep(0.5, 0.72, speckle) * 0.45);
  albedo = mix(albedo, vec3(0.18, 0.175, 0.165), sstep(0.35, 0.15, vein) * 0.25);
  rough = 0.42 - n * 0.08 + speckle * 0.12;
  ao = 0.9 + n * 0.06;
}
`;

/* World-space micro + mask + macro. Breaks the 1–2 m UV tile on long facades. */
export function dressFacade(mat, maps, tag = 'plaster') {
  const U = {
    tMaskF: { value: maps.mask },
    tMacroF: { value: maps.macro },
  };
  const prev = mat.onBeforeCompile;
  mat.onBeforeCompile = (shader) => {
    if (prev) prev(shader);
    Object.assign(shader.uniforms, U);
    shader.vertexShader = 'varying vec3 vWPosF; varying vec3 vWNrmF;\n' + shader.vertexShader.replace(
      '#include <begin_vertex>',
      `#include <begin_vertex>
       vWPosF = (modelMatrix * vec4(position, 1.0)).xyz;
       vWNrmF = normalize(mat3(modelMatrix) * normal);`,
    );
    shader.fragmentShader = `
      uniform sampler2D tMaskF, tMacroF;
      varying vec3 vWPosF;
      varying vec3 vWNrmF;
      float sstepF(float e0, float e1, float x){
        float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
        return t * t * (3.0 - 2.0 * t);
      }
    ` + shader.fragmentShader.replace(
      '#include <color_fragment>',
      `#include <color_fragment>
       vec3 nF = normalize(vWNrmF);
       float ax = abs(nF.x), ay = abs(nF.y), az = abs(nF.z);
       vec2 wallUVF = (ay > ax && ay > az) ? vWPosF.xz
                     : (ax > az ? vec2(vWPosF.z, vWPosF.y) : vec2(vWPosF.x, vWPosF.y));
       vec4 mac = texture2D(tMacroF, wallUVF * 0.018);
       vec3 msk = texture2D(tMaskF, wallUVF * 0.62).rgb;
       float streak = msk.r;
       float dust = msk.g * sstepF(0.18, 0.82, mac.r);
       float baseG = sstepF(1.55, 0.18, vWPosF.y);
       /* Hard-ish wainscot band: a distinctly darker skirt below ~1.2 m plus
        * the soft grime gradient above it. */
       float wain = sstepF(1.28, 1.02, vWPosF.y);
       float flake = msk.b;
       float chipW = sstepF(0.42, 0.86, mac.g) * sstepF(0.22, 0.78, msk.b);
       /* c23: re-plaster patches are rotated ellipses on a domain-warped
        * lattice — the c21 axis-aligned 3.3×2.4 rectangle grid read as a
        * stamp sheet on the yard south wall. */
       vec2 warpF = vec2(
         sin(wallUVF.y * 0.37 + 1.7) * 0.95 + sin(wallUVF.x * 0.19 + 4.2) * 0.40,
         cos(wallUVF.x * 0.33 + 2.4) * 0.80 + cos(wallUVF.y * 0.21 + 0.8) * 0.35
       );
       vec2 cellSzF = vec2(5.1, 4.2);
       vec2 warpedF = wallUVF + warpF;
       vec2 cellIdF = floor(warpedF / cellSzF);
       vec2 cellFF = fract(warpedF / cellSzF);
       float phF = fract(sin(dot(cellIdF, vec2(127.1, 311.7))) * 43758.5453);
       float ph2F = fract(phF * 91.17 + 0.37);
       float angF = phF * 6.2831853;
       vec2 ctrF = cellFF - 0.5;
       vec2 rotF = vec2(ctrF.x * cos(angF) - ctrF.y * sin(angF), ctrF.x * sin(angF) + ctrF.y * cos(angF));
       vec2 radF = vec2(0.16 + ph2F * 0.20, 0.12 + fract(phF * 5.1) * 0.18);
       float dEllF = length(rotF / max(radF, vec2(0.04))) + (msk.g - 0.5) * 0.15;
       float isPatchF = step(phF, 0.26);
       float inPatch = sstepF(1.05, 0.70, dEllF) * isPatchF;
       float patchRim = sstepF(0.22, 0.04, abs(dEllF - 0.88)) * isPatchF;
       /* Fresh render covers old grime and bridges old cracks. */
       streak *= 1.0 - inPatch * 0.72;
       flake *= 1.0 - inPatch * 0.60;
       float macCrack = mac.a * (1.0 - inPatch * 0.85);
       /* Macro tone patches: 0.60-1.08 multiplier range so the 2-3 tone
        * meters-scale patches are plainly visible at 1x (fix 4). */
       diffuseColor.rgb *= 0.50 + 0.62 * mac.r;
       diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb * vec3(1.07, 1.00, 0.91), sstepF(0.55, 0.90, mac.g) * 0.8);
       /* Prior macro lesson (fix 4): ±10% washes vanish under warm sun at
        * 1x — patch tones need to land at ±20% with a hue shift to read. */
       vec3 patchTintF = ph2F > 0.5 ? vec3(1.21, 1.13, 1.01) : vec3(0.77, 0.73, 0.67);
       diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb * patchTintF, inPatch * 0.92);
       diffuseColor.rgb *= 1.0 - patchRim * 0.30;
       diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.17, 0.125, 0.085), macCrack * 0.85);
       diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.16, 0.11, 0.07), streak * 0.78);
       diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.28, 0.20, 0.12), chipW * 0.88);
       diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.46, 0.38, 0.26), dust * 0.22);
       diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.14, 0.10, 0.07), flake * 0.50);
       /* Base-course dirt varies with the dust field instead of one flat
        * multiplier, plus a tight contact-AO band where the wall meets the
        * ground (c21 fix 1/5). */
       diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.18, 0.13, 0.08), baseG * (0.44 + msk.g * 0.30));
       diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb * vec3(0.60, 0.52, 0.42), wain * (0.55 + 0.25 * mac.r));
       diffuseColor.rgb *= 1.0 - sstepF(0.60, 0.03, vWPosF.y) * 0.26;
       diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb * vec3(0.52, 0.44, 0.32), mac.b * 0.38);
       /* Occasional exposed-brick patch where render coat fell off: strongest
        * soot spots become brick courses with mortar lines (fix 4). */
       float brickPatch = sstepF(0.86, 0.97, mac.b) * (1.0 - sstepF(2.6, 3.4, vWPosF.y)) * (1.0 - inPatch);
       float course = fract(vWPosF.y * 3.4);
       float mortarH = sstepF(0.14, 0.02, min(course, 1.0 - course));
       vec3 brickC = mix(vec3(0.40, 0.225, 0.14), vec3(0.60, 0.53, 0.44), mortarH);
       diffuseColor.rgb = mix(diffuseColor.rgb, brickC, brickPatch * 0.85);
      `,
    ).replace(
      '#include <roughnessmap_fragment>',
      /* Roughness variation (c21 fix 1): macro tone zones, smoother fresh
       * repair patches and rougher crack/streak grime so the sun actually
       * responds across a facade instead of one uniform lobe. Runs after
       * color_fragment, so mac/inPatch/macCrack/streak are in scope. */
      `#include <roughnessmap_fragment>
       roughnessFactor = clamp(roughnessFactor + (mac.r - 0.5) * 0.22 - inPatch * 0.18 + macCrack * 0.10 + streak * 0.06, 0.30, 1.0);
      `,
    );
  };
  mat.customProgramCacheKey = () => `facade-8s-${tag}`;
  return mat;
}

function applyMaps(mat, maps, { metal = 0, aniso = 8, repeat = 1, nrm = 0.85 } = {}) {
  mat.map = maps.map;
  if (maps.normalMap) {
    mat.normalMap = maps.normalMap;
    mat.normalScale = new THREE.Vector2(nrm, nrm);
  }
  if (maps.ormMap) {
    mat.aoMap = maps.ormMap;
    mat.roughnessMap = maps.ormMap;
    mat.aoMapIntensity = 1;
  }
  mat.metalness = metal;
  mat.roughness = 1;
  [mat.map, mat.normalMap, mat.roughnessMap, mat.aoMap].forEach((t) => {
    if (!t) return;
    t.wrapS = t.wrapT = THREE.RepeatWrapping;
    t.anisotropy = aniso;
    t.repeat.set(repeat, repeat);
  });
  mat.needsUpdate = true;
  return mat;
}

function std(opts) {
  return new THREE.MeshStandardMaterial({
    roughness: 0.7,
    metalness: 0,
    envMapIntensity: 0.35,
    ...opts,
  });
}

function phys(opts) {
  return new THREE.MeshPhysicalMaterial({
    roughness: 0.35,
    metalness: 0.05,
    envMapIntensity: 0.85,
    ...opts,
  });
}

export function bakeWorldMaterials(renderer, aniso = 8) {
  const asphalt = bakeSurface(renderer, SURF_ASPHALT, { size: 1024, repeat: 1, normalStrength: 4.4 });
  const concrete = bakeSurface(renderer, SURF_CONCRETE, { size: 1024, repeat: 1, normalStrength: 2.4 });
  const slab = bakeSurface(renderer, SURF_SLAB, { size: 1024, repeat: 1, normalStrength: 2.6 });
  const brick = bakeSurface(renderer, SURF_BRICK, { size: 1024, repeat: 1, normalStrength: 3.1 });
  const metal = bakeSurface(renderer, SURF_METAL, { size: 512, repeat: 1, normalStrength: 1.8 });
  const polymer = bakeSurface(renderer, SURF_POLYMER, { size: 512, repeat: 1, normalStrength: 1.3 });
  const plaster = bakeSurface(renderer, PLASTER_MICRO, { size: 1024, repeat: 1, normalStrength: 7.2 });
  const plasterMask = bakeImage(renderer, PLASTER_MASK, {
    size: 512, colorSpace: THREE.NoColorSpace, wrap: THREE.RepeatWrapping, transparent: false,
  });
  const plasterMacro = bakeImage(renderer, PLASTER_MACRO, {
    size: 256, colorSpace: THREE.NoColorSpace, wrap: THREE.RepeatWrapping, transparent: false,
  });
  const stainA = bakeImage(renderer, STAIN_A, { size: 512, transparent: true });
  const stainB = bakeImage(renderer, STAIN_B, { size: 512, transparent: true });
  const stainC = bakeImage(renderer, STAIN_C, { size: 512, transparent: true });
  const stainD = bakeImage(renderer, STAIN_D, { size: 512, transparent: true });
  stainA.wrapS = stainA.wrapT = THREE.ClampToEdgeWrapping;
  stainB.wrapS = stainB.wrapT = THREE.ClampToEdgeWrapping;
  stainC.wrapS = stainC.wrapT = THREE.ClampToEdgeWrapping;
  stainD.wrapS = stainD.wrapT = THREE.ClampToEdgeWrapping;
  const glove = bakeSurface(renderer, SURF_GLOVE, { size: 512, repeat: 1, normalStrength: 0.45 });
  const fabric = bakeSurface(renderer, SURF_FABRIC, { size: 512, repeat: 1, normalStrength: 1.6 });
  const rust = bakeSurface(renderer, SURF_RUST, { size: 512, repeat: 1, normalStrength: 2.5 });
  const wood = bakeSurface(renderer, SURF_WOOD, { size: 512, repeat: 1, normalStrength: 2.1 });
  const trash = bakeSurface(renderer, SURF_TRASH, { size: 512, repeat: 1, normalStrength: 2.6 });
  const paint = bakeSurface(renderer, SURF_PAINT, { size: 512, repeat: 1, normalStrength: 1.8 });
  const granite = bakeSurface(renderer, SURF_GRANITE, { size: 512, repeat: 1, normalStrength: 1.6 });
  const akwood = bakeSurface(renderer, SURF_AKWOOD, { size: 512, repeat: 1, normalStrength: 4.4 });
  const gunmetal = bakeSurface(renderer, SURF_GUNMETAL, { size: 512, repeat: 1, normalStrength: 1.85 });
  const bakelite = bakeSurface(renderer, SURF_BAKELITE, { size: 1024, repeat: 1, normalStrength: 1.35 });
  /* Mag is seen at a hard grazing angle in ADS — max aniso kills the
   * mip/gradient smear at the bakelite toe. */
  {
    const maxA = renderer.capabilities.getMaxAnisotropy();
    [bakelite.map, bakelite.normalMap, bakelite.ormMap].forEach((t) => {
      if (!t) return;
      t.anisotropy = maxA;
      t.minFilter = THREE.LinearMipmapLinearFilter;
      t.needsUpdate = true;
    });
  }
  const dirt = bakeSurface(renderer, SURF_DIRT, { size: 512, repeat: 1, normalStrength: 2.2 });
  const awning = bakeSurface(renderer, SURF_AWNING, { size: 512, repeat: 1, normalStrength: 1.2 });

  const contactTex = bakeImage(renderer, /* glsl */ `
void main(){
  float r = length(vUv - 0.5) * 2.05;
  float core = sstep(0.48, 0.0, r);
  float halo = sstep(1.0, 0.22, r);
  float a = core * 0.99 + halo * 0.55;
  gl_FragColor = vec4(0.008, 0.005, 0.003, a);
}
`, { size: 256, transparent: true });

  const sandBlob = bakeImage(renderer, /* glsl */ `
void main(){
  float r = length(vUv - 0.5) * 2.0;
  float n = pfbm(vUv * 5.5 + 2.4, vec2(5.5), 4);
  float a = sstep(1.0, 0.08, r) * (0.42 + n * 0.22);
  vec3 c = mix(vec3(0.34, 0.27, 0.17), vec3(0.54, 0.44, 0.28), n * 0.6);
  gl_FragColor = vec4(c, a);
}
`, { size: 512, transparent: true });
  contactTex.wrapS = contactTex.wrapT = THREE.ClampToEdgeWrapping;
  sandBlob.wrapS = sandBlob.wrapT = THREE.ClampToEdgeWrapping;

  /* Windshield map: darker sun band up top, vertical gradient, and a bright
   * diagonal sky-reflection streak. Box faces carry 0-1 UVs so this lands on
   * every pane orientation. */
  const windGrad = bakeImage(renderer, /* glsl */ `
void main(){
  float g = mix(0.28, 1.0, sstep(0.0, 0.82, vUv.y));
  vec3 c = mix(vec3(0.07, 0.08, 0.10), vec3(0.22, 0.28, 0.36), g);
  c *= 1.0 - sstep(0.82, 0.98, vUv.y) * 0.35;
  float streak = sstep(0.14, 0.0, abs(vUv.y - (0.54 + (vUv.x - 0.5) * 0.28)));
  c += vec3(0.72, 0.80, 0.92) * streak * 1.15;
  float glint = sstep(0.04, 0.0, abs(vUv.y - 0.78 - (vUv.x - 0.5) * 0.12));
  c += vec3(0.55, 0.60, 0.68) * glint * 0.55;
  gl_FragColor = vec4(c, 1.0);
}
`, { size: 256, transparent: false });
  windGrad.wrapS = windGrad.wrapT = THREE.ClampToEdgeWrapping;

  /* Baked pane: dark-warm room at the bottom, sky band up top, and a
   * hard diagonal reflection so glass reads even when envMap is weak
   * (yard/extract look almost head-on at the south wall). */
  const paneSpec = bakeImage(renderer, /* glsl */ `
void main(){
  float g = mix(0.18, 1.0, sstep(0.0, 0.86, vUv.y));
  vec3 c = mix(vec3(0.10, 0.07, 0.05), vec3(0.38, 0.44, 0.54), g);
  float streak = sstep(0.16, 0.0, abs(vUv.y - (0.56 + (vUv.x - 0.5) * 0.42)));
  c += vec3(0.85, 0.90, 1.00) * streak * 1.25;
  float rim = sstep(0.10, 0.0, min(min(vUv.x, 1.0 - vUv.x), min(vUv.y, 1.0 - vUv.y)));
  c = mix(c, vec3(0.05, 0.04, 0.03), rim * 0.55);
  gl_FragColor = vec4(c, 1.0);
}
`, { size: 256, transparent: false });
  paneSpec.wrapS = paneSpec.wrapT = THREE.ClampToEdgeWrapping;

  /* Taillight lens (c21 fix 4): the c20 lens rendered as one flat 83/20/14
   * quad. This map carries a vertical hot-to-deep red gradient, faint
   * vertical lens ribs, a dark moulded rim and a bright top glint, and it is
   * used as BOTH map and emissiveMap so the gradient survives in shade. */
  const tailLens = bakeImage(renderer, /* glsl */ `
void main(){
  vec2 p = vUv;
  float rib = 0.86 + 0.14 * abs(sin(p.x * 44.0));
  float grad = sstep(0.05, 0.95, p.y);
  vec3 deep = vec3(0.30, 0.030, 0.020);
  vec3 hot = vec3(0.92, 0.155, 0.075);
  vec3 c = mix(deep, hot, grad * 0.72 + 0.14) * rib;
  float rim = sstep(0.14, 0.03, min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y)));
  c = mix(c, vec3(0.11, 0.018, 0.012), rim * 0.85);
  c += vec3(0.90, 0.50, 0.32) * sstep(0.88, 0.985, p.y) * (1.0 - rim) * 0.45;
  gl_FragColor = vec4(c, 1.0);
}
`, { size: 128, transparent: false });
  tailLens.wrapS = tailLens.wrapT = THREE.ClampToEdgeWrapping;

  const mats = {
    asphalt: applyMaps(std({ color: 0xc8bcaa, envMapIntensity: 0.18 }), asphalt, { metal: 0.02, aniso, nrm: 1.35 }),
    concrete: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.18 }), concrete, { aniso, nrm: 0.95 }),
    brick: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.16 }), brick, { aniso, nrm: 1.0 }),
    metal: applyMaps(std({ color: 0xffffff, envMapIntensity: 1.05 }), metal, { metal: 0.82, aniso, nrm: 0.7 }),
    darkMetal: applyMaps(std({ color: 0xb0b0b4, envMapIntensity: 0.95 }), metal, { metal: 0.86, aniso, nrm: 0.65 }),
    polymer: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.32 }), polymer, { aniso, nrm: 0.7 }),
    /* Wall tints desaturated ~10% toward luma (fix 10: c16 ochre ran hot
     * vs dust-agents) and normal response raised so the new stipple relief
     * shows at grazing sun (fix 7). */
    /* nrm raised ~30% (fix 6, c19): the stipple relief was washing out at
     * the grazing angles the yard/extract stops see the long walls from. */
    plaster: applyMaps(std({ color: 0xdfd2b7, envMapIntensity: 0.16 }), plaster, { aniso, nrm: 2.6 }),
    plasterSand: applyMaps(std({ color: 0xdac4a4, envMapIntensity: 0.15 }), plaster, { aniso, nrm: 2.55 }),
    plasterRose: applyMaps(std({ color: 0xd5b5a3, envMapIntensity: 0.15 }), plaster, { aniso, nrm: 2.5 }),
    plasterLime: applyMaps(std({ color: 0xd2c4a7, envMapIntensity: 0.14 }), plaster, { aniso, nrm: 2.5 }),
    plasterOchre: applyMaps(std({ color: 0xd1b085, envMapIntensity: 0.15 }), plaster, { aniso, nrm: 1.95 }),
    dirt: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.16 }), dirt, { aniso, nrm: 1.1 }),
    akWood: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.38 }), akwood, { aniso, nrm: 1.2 }),
    gunMetal: applyMaps(std({ color: 0xc8cac6, envMapIntensity: 1.35 }), gunmetal, { metal: 0.86, aniso, nrm: 0.75 }),
    burlap: applyMaps(std({ color: 0x8a7048, envMapIntensity: 0.10 }), fabric, { aniso, nrm: 0.7 }),
    glove: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.12 }), glove, { aniso, nrm: 0.9 }),
    fabric: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.08 }), fabric, { aniso, nrm: 0.8 }),
    rust: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.35 }), rust, { metal: 0.22, aniso }),
    wood: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.22 }), wood, { aniso, nrm: 1.05 }),
    trashBag: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.4 }), trash, { metal: 0.08, aniso }),
    paint: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.55 }), paint, { metal: 0.18, aniso }),
    granite: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.45 }), granite, { metal: 0.06, aniso }),
    wetCurb: applyMaps(std({ color: 0xc8c4bc, envMapIntensity: 0.55 }), granite, { metal: 0.08, aniso, nrm: 0.7 }),

    glass: std({
      color: 0xffffff, map: paneSpec, roughness: 0.08, metalness: 0.22,
      transparent: true, opacity: 0.82, envMapIntensity: 1.85,
      emissive: 0xffffff, emissiveMap: paneSpec, emissiveIntensity: 0.28,
      depthWrite: true, side: THREE.DoubleSide,
    }),
    windowDark: std({
      color: 0xffffff, map: paneSpec, roughness: 0.07, metalness: 0.24,
      transparent: true, opacity: 0.84, envMapIntensity: 1.95,
      emissive: 0xffffff, emissiveMap: paneSpec, emissiveIntensity: 0.32,
      depthWrite: true, side: THREE.DoubleSide,
    }),
    litGlass: std({
      color: 0xffffff, map: paneSpec, roughness: 0.08, metalness: 0.16,
      transparent: true, opacity: 0.80, envMapIntensity: 1.65,
      emissive: 0xffffff, emissiveMap: paneSpec, emissiveIntensity: 0.26,
      depthWrite: true, side: THREE.DoubleSide,
    }),
    windshield: std({
      color: 0xffffff, map: windGrad, roughness: 0.06, metalness: 0.20,
      transparent: true, opacity: 0.86, envMapIntensity: 2.05,
      emissive: 0xffffff, emissiveMap: windGrad, emissiveIntensity: 0.34,
      depthWrite: true, side: THREE.FrontSide,
    }),
    paneGlass: std({
      color: 0xffffff, map: paneSpec, roughness: 0.08, metalness: 0.20,
      transparent: true, opacity: 0.80, envMapIntensity: 1.70,
      emissive: 0xffffff, emissiveMap: paneSpec, emissiveIntensity: 0.24,
      depthWrite: true, side: THREE.DoubleSide,
    }),
    rayGlass: phys({
      color: 0x1a2018, roughness: 0.08, metalness: 0.06, transparent: true,
      opacity: 0.50, emissive: 0x6a4820, emissiveIntensity: 0.05,
      envMapIntensity: 1.35, depthWrite: true, side: THREE.DoubleSide,
    }),
    chrome: std({
      color: 0xd4dce4, roughness: 0.12, metalness: 0.94, envMapIntensity: 1.65,
    }),

    cabSolid: applyMaps(std({ color: 0x5e5244, envMapIntensity: 0.55 }), paint, { metal: 0.14, aniso }),
    maroonSolid: applyMaps(std({ color: 0x4a2824, envMapIntensity: 0.45 }), paint, { metal: 0.14, aniso }),
    cabGlass: std({
      color: 0xffffff, map: windGrad, roughness: 0.07, metalness: 0.18,
      transparent: true, opacity: 0.84, envMapIntensity: 1.95,
      emissive: 0xffffff, emissiveMap: windGrad, emissiveIntensity: 0.30,
    }),
    wreckCab: applyMaps(std({ color: 0x6a5a4c, envMapIntensity: 0.55 }), rust, { metal: 0.28, aniso }),
    wreckFill: applyMaps(std({ color: 0x2e2620, envMapIntensity: 0.3 }), rust, { metal: 0.16, aniso }),
    wreckGlass: std({
      color: 0xffffff, map: windGrad, roughness: 0.12, metalness: 0.14,
      transparent: true, opacity: 0.80, envMapIntensity: 1.55,
      emissive: 0xffffff, emissiveMap: windGrad, emissiveIntensity: 0.22,
    }),
    tanMull: applyMaps(std({ color: 0x6a6256, envMapIntensity: 0.2 }), plaster, { aniso }),
    vanPlate: applyMaps(std({ color: 0x3a2822, envMapIntensity: 0.4 }), paint, { metal: 0.16, aniso }),
    rayRoom: std({
      color: 0x16120e, roughness: 0.88, metalness: 0,
      emissive: 0x8a5a28, emissiveIntensity: 0.05, envMapIntensity: 0.08,
    }),
    rayTan: applyMaps(std({ color: 0x6a6256, envMapIntensity: 0.18 }), plaster, { aniso }),
    rayMull: applyMaps(std({ color: 0x8a8074, envMapIntensity: 0.25 }), metal, { metal: 0.18, aniso }),
    rayPlate: applyMaps(std({ color: 0x4a3028, envMapIntensity: 0.35 }), paint, { metal: 0.14, aniso }),
    wreckRubber: std({ color: 0x2a2622, roughness: 0.92, metalness: 0.04, envMapIntensity: 0.16 }),
    wreckHub: applyMaps(std({ color: 0xc8b090, envMapIntensity: 0.7 }), metal, { metal: 0.55, aniso }),
    alleyHub: applyMaps(std({ color: 0xc4a860, envMapIntensity: 0.65 }), metal, { metal: 0.5, aniso }),
    warmRoom: std({
      color: 0x16120c, roughness: 0.9, metalness: 0,
      emissive: 0x8a5a28, emissiveIntensity: 0.055, envMapIntensity: 0.06,
    }),
    mullion: applyMaps(std({ color: 0x5a544c, envMapIntensity: 0.20 }), plaster, { metal: 0.06, aniso }),
    sill: applyMaps(std({ color: 0x9a8a72, envMapIntensity: 0.2 }), concrete, { aniso }),
    acShell: applyMaps(std({ color: 0x8e887a, envMapIntensity: 0.34 }), paint, { metal: 0.14, aniso }),
    interior: std({
      color: 0x2a2016, roughness: 0.92, metalness: 0,
      emissive: 0x4a3018, emissiveIntensity: 0.038, envMapIntensity: 0.08,
    }),
    darkRoom: std({
      color: 0x1a1410, roughness: 0.94, metalness: 0,
      emissive: 0x2e2014, emissiveIntensity: 0.028, envMapIntensity: 0.06,
    }),
    recess: applyMaps(std({ color: 0x5a544c, envMapIntensity: 0.1 }), plaster, { aniso }),
    warmWall: applyMaps(std({ color: 0x6a6458, envMapIntensity: 0.1 }), plaster, { aniso }),
    soak: phys({
      color: 0x3a3224, roughness: 0.42, metalness: 0.04,
      transparent: true, opacity: 0.26, envMapIntensity: 0.45,
    }),
    curtain: applyMaps(std({ color: 0x6a5848, envMapIntensity: 0.08 }), fabric, { aniso }),
    neon: std({
      color: 0x1a2218, emissive: 0x2a8a80, emissiveIntensity: 0.85,
      roughness: 0.45, envMapIntensity: 0.2,
    }),
    neonAmber: std({
      color: 0x8a5a28, emissive: 0xc47830, emissiveIntensity: 0.22,
      roughness: 0.55, envMapIntensity: 0.18,
    }),
    fire: std({
      color: 0xff6a28, emissive: 0xff4a10, emissiveIntensity: 3.4, roughness: 1,
    }),
    lamp: std({
      color: 0xe8c890, emissive: 0xe0a858, emissiveIntensity: 0.35, roughness: 0.42,
    }),
    headlight: std({
      color: 0xfff0d0, emissive: 0xffe0a8, emissiveIntensity: 2.2, roughness: 0.22,
    }),
    /* Passive lens with a moulded gradient (c21 fix 4): the flat-color lens
     * measured one uniform 83/20/14 patch. The baked map + emissiveMap give
     * it a hot upper glow, deep red base and rib texture. */
    taillight: std({
      color: 0xffffff, map: tailLens, emissive: 0xffffff, emissiveMap: tailLens,
      emissiveIntensity: 4.2, roughness: 0.10, metalness: 0.08,
      envMapIntensity: 1.15,
    }),
    /* Second rear lens element: pale reverse-light plastic (c21 fix 4). */
    reverseLens: std({
      color: 0xcfc8b8, emissive: 0x585048, emissiveIntensity: 0.20,
      roughness: 0.14, metalness: 0.05, envMapIntensity: 1.15,
    }),
    lane: std({ color: 0xa09058, roughness: 0.52, metalness: 0.04, envMapIntensity: 0.2 }),
    wet: phys({
      color: 0x3a3224, roughness: 0.40, metalness: 0.04,
      transparent: true, opacity: 0.26, envMapIntensity: 0.50,
    }),
    sheen: phys({
      color: 0x2a2418, roughness: 0.18, metalness: 0.08,
      transparent: true, opacity: 0.22, depthWrite: false, envMapIntensity: 0.85,
    }),
    oil: phys({
      color: 0x181410, roughness: 0.14, metalness: 0.22,
      transparent: true, opacity: 0.62, envMapIntensity: 1.6,
    }),
    gutter: applyMaps(std({ color: 0x6a6458, envMapIntensity: 0.2 }), asphalt, { aniso }),
    rubber: std({ color: 0x2c2824, roughness: 0.90, metalness: 0.05, envMapIntensity: 0.20 }),
    sidewall: std({ color: 0x625c52, roughness: 0.86, metalness: 0.04, envMapIntensity: 0.20 }),
    /* Lifted from 0x12100e/env 0.04 (fix 8, c20): pure-black char turned the
     * whole burnt van into a paper silhouette; charcoal with a little sky
     * response keeps panel edges readable. */
    scorch: std({ color: 0x241f1a, roughness: 0.94, metalness: 0, envMapIntensity: 0.14 }),
    cardboard: applyMaps(std({ color: 0x8a6a40, envMapIntensity: 0.08 }), wood, { aniso }),
    blind: applyMaps(std({ color: 0x8a7a62, envMapIntensity: 0.1 }), fabric, { aniso }),
    skin: std({ color: 0x6b4a36, roughness: 0.68, metalness: 0.02, envMapIntensity: 0.15 }),
    cloth: applyMaps(std({ color: 0x3a3e34, envMapIntensity: 0.06 }), fabric, { aniso }),
    vest: applyMaps(std({ color: 0x6a7064, envMapIntensity: 0.22 }), polymer, { metal: 0.1, aniso }),
    contact: new THREE.MeshBasicMaterial({
      map: contactTex, color: 0xffffff, transparent: true, opacity: 1,
      depthWrite: false, fog: true,
    }),
    sandDrift: new THREE.MeshBasicMaterial({
      map: sandBlob, color: 0xffffff, transparent: true, opacity: 1,
      depthWrite: false, fog: true,
    }),
    crateMetal: applyMaps(std({ color: 0x8a7a58, envMapIntensity: 0.55 }), metal, { metal: 0.42, aniso, nrm: 0.7 }),
    dumpPaint: applyMaps(std({ color: 0x5a5840, envMapIntensity: 0.22 }), paint, { metal: 0.06, aniso }),
    dumpRust: applyMaps(std({ color: 0x8a6a48, envMapIntensity: 0.12 }), rust, { metal: 0.06, aniso, nrm: 0.7 }),
    vanRed: applyMaps(std({ color: 0x9a4632, envMapIntensity: 0.52 }), paint, { metal: 0.12, aniso, nrm: 1.35 }),
    vanBlack: applyMaps(std({ color: 0x807462, envMapIntensity: 0.48 }), paint, { metal: 0.12, aniso, nrm: 1.15 }),
    balconySlab: applyMaps(std({ color: 0x6a7382, envMapIntensity: 0.16 }), concrete, { aniso, nrm: 1.05 }),
    awningBounce: std({
      color: 0x8a6a48, roughness: 0.82, metalness: 0,
      emissive: 0x6a4828, emissiveIntensity: 0.08, envMapIntensity: 0.16,
    }),
    /* Shadowed roof underside: warm brown that still reads as a surface —
     * the darkRoom soffit under the extract header rendered as featureless
     * void-black (fix 8). */
    soffit: std({
      color: 0x4a3a2c, roughness: 0.92, metalness: 0,
      emissive: 0x201810, emissiveIntensity: 0.05, envMapIntensity: 0.10,
    }),
    awningStripe: applyMaps(std({ color: 0xffffff, envMapIntensity: 0.10 }), awning, { aniso, nrm: 0.55 }),
    awningUnder: applyMaps(std({ color: 0x86705a, envMapIntensity: 0.05 }), awning, { aniso, nrm: 0.40 }),
    tarp: applyMaps(std({ color: 0x5a4a32, envMapIntensity: 0.08 }), fabric, { aniso, nrm: 0.95 }),
    burlap: applyMaps(std({ color: 0x967c50, envMapIntensity: 0.05 }), fabric, { aniso, nrm: 1.25 }),
    cratePaint: applyMaps(std({ color: 0x4a4638, envMapIntensity: 0.16 }), paint, { metal: 0.04, aniso, nrm: 0.8 }),
    sedanMaroon: applyMaps(std({ color: 0x8a3a30, envMapIntensity: 0.42 }), paint, { metal: 0.16, aniso }),
    sedanSilver: applyMaps(std({ color: 0xb4aea2, envMapIntensity: 0.48 }), paint, { metal: 0.24, aniso }),
    sedanTaxi: applyMaps(std({ color: 0xc8a838, envMapIntensity: 0.40 }), paint, { metal: 0.12, aniso }),
    awningCloth: applyMaps(std({ color: 0x7a4030, envMapIntensity: 0.14 }), fabric, { aniso, nrm: 0.85 }),
    awningAlt: applyMaps(std({ color: 0x5a4a28, envMapIntensity: 0.14 }), fabric, { aniso, nrm: 0.85 }),
    lightGlass: phys({
      color: 0xf0e8d0, roughness: 0.12, metalness: 0.04, transparent: true,
      opacity: 0.55, emissive: 0xffe8b0, emissiveIntensity: 0.35,
      envMapIntensity: 1.1, depthWrite: false,
    }),
  };

  mats.asphalt.roughness = 0.94;
  mats.asphalt.metalness = 0.0;
  mats.asphalt.envMapIntensity = 0.10;
  mats.asphalt.color.setHex(0xe2c8a4);
  mats.concrete.roughness = 0.90;
  mats.plaster.roughness = 0.90;
  mats.plasterSand.roughness = 0.90;
  mats.plasterRose.roughness = 0.90;
  mats.plasterLime.roughness = 0.91;
  mats.plasterOchre.roughness = 0.89;
  if (mats.burlap) mats.burlap.roughness = 0.86;
  mats.wood.roughness = 0.62;
  mats.akWood.roughness = 0.38;
  mats.metal.roughness = 0.36;
  mats.darkMetal.roughness = 0.40;
  mats.gunMetal.roughness = 1.0;
  mats.rust.roughness = 0.86;
  mats.rust.metalness = 0.08;
  mats.rust.envMapIntensity = 0.14;
  mats.dumpRust.roughness = 0.82;
  mats.dumpRust.metalness = 0.06;
  mats.dumpRust.envMapIntensity = 0.10;
  mats.dumpPaint.roughness = 0.72;
  mats.wetCurb.roughness = 0.74;
  const facadeMaps = { mask: plasterMask, macro: plasterMacro };
  dressFacade(mats.plaster, facadeMaps, 'p');
  dressFacade(mats.plasterSand, facadeMaps, 's');
  dressFacade(mats.plasterRose, facadeMaps, 'r');
  dressFacade(mats.plasterLime, facadeMaps, 'l');
  dressFacade(mats.plasterOchre, facadeMaps, 'o');
  dressFacade(mats.brick, facadeMaps, 'b');

  mats.stainA = new THREE.MeshBasicMaterial({
    map: stainA, color: 0xffffff, transparent: true, opacity: 1,
    depthWrite: false, fog: true, side: THREE.DoubleSide,
    polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2,
  });
  mats.stainB = new THREE.MeshBasicMaterial({
    map: stainB, color: 0xffffff, transparent: true, opacity: 1,
    depthWrite: false, fog: true, side: THREE.DoubleSide,
    polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2,
  });
  mats.stainC = new THREE.MeshBasicMaterial({
    map: stainC, color: 0xffffff, transparent: true, opacity: 1,
    depthWrite: false, fog: true, side: THREE.DoubleSide,
    polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2,
  });
  mats.stainD = new THREE.MeshBasicMaterial({
    map: stainD, color: 0xffffff, transparent: true, opacity: 1,
    depthWrite: false, fog: true, side: THREE.DoubleSide,
    polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2,
  });
  mats.woodEnd = applyMaps(std({ color: 0x4a3018, envMapIntensity: 0.12 }), wood, { aniso, nrm: 0.7 });
  mats.woodEnd.roughness = 0.88;
  mats.balconySlab.roughness = 0.88;
  mats.balconySlab.color.setHex(0x6a6458);
  if (mats.tarp) mats.tarp.roughness = 0.92;
  if (mats.burlap) mats.burlap.roughness = 0.96;
  if (mats.awningStripe) mats.awningStripe.roughness = 0.88;
  if (mats.awningUnder) mats.awningUnder.roughness = 0.92;
  if (mats.cratePaint) mats.cratePaint.roughness = 0.78;
  mats.sedanMaroon.roughness = 0.34;
  mats.sedanSilver.roughness = 0.30;
  mats.sedanTaxi.roughness = 0.36;
  mats.sedanMaroon.metalness = 0.28;
  mats.sedanSilver.metalness = 0.36;
  mats.sedanTaxi.metalness = 0.22;
  mats.sedanMaroon.envMapIntensity = 0.92;
  mats.sedanSilver.envMapIntensity = 1.05;
  mats.sedanTaxi.envMapIntensity = 0.85;
  mats.vanRed.roughness = 0.36;
  mats.vanBlack.roughness = 0.38;
  mats.vanRed.metalness = 0.22;
  mats.vanBlack.metalness = 0.20;
  mats.vanRed.envMapIntensity = 0.88;
  mats.vanBlack.envMapIntensity = 0.80;
  mats.asphaltDim = mats.asphalt.clone();
  mats.asphaltDim.color.setHex(0xa89880);
  mats.asphaltDim.envMapIntensity = 0.12;

  /* Big plaza/yard/forecourt ground. LevelBuilder only clones concrete as a
   * fallback when this is missing, so defining it here gives the open slabs
   * the tracked/dusty bake instead of a flat warm tint. */
  mats.slabWarm = applyMaps(std({ color: 0xdcc4a0, envMapIntensity: 0.08 }), slab, { aniso, nrm: 1.25 });
  mats.slabWarm.roughness = 0.92;

  mats._maps = {
    asphalt, concrete, brick, metal, polymer, plaster, glove, fabric, rust, wood, trash, paint, granite,
    akwood, gunmetal, bakelite, dirt, awning,
  };

  /* Neutral-grey studio environment for the VIEWMODEL metals (c20, fix 1/2).
   * The c19 black-cube envMap left gunmetal with nothing to reflect, so the
   * receiver was carried entirely by the warm vm lights: high metalness went
   * BLACK, low metalness went KHAKI (warm light x grey albedo). A dim
   * grey-gradient PMREM gives metals a genuinely neutral reflection term —
   * dark floor, mid horizon, soft bright top — so gunmetal reads as gunmetal
   * at metalness 0.7-0.85 without ever picking up the warm sky. */
  {
    const pmrem = new THREE.PMREMGenerator(renderer);
    const es = new THREE.Scene();
    const grad = new THREE.Mesh(
      new THREE.SphereGeometry(6, 24, 16),
      new THREE.ShaderMaterial({
        side: THREE.BackSide,
        depthWrite: false,
        vertexShader: 'varying vec3 vDir; void main(){ vDir = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }',
        fragmentShader: [
          'varying vec3 vDir;',
          'void main(){',
          '  vec3 d = normalize(vDir);',
          '  float h = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);',
          '  float t = smoothstep(0.12, 0.88, h);',
          '  vec3 col = mix(vec3(0.060), vec3(0.46), t);',
          '  col += vec3(0.14) * smoothstep(0.72, 1.0, h);',
          '  gl_FragColor = vec4(col, 1.0);',
          '}',
        ].join('\n'),
      }),
    );
    es.add(grad);
    mats._vmEnv = pmrem.fromScene(es, 0.05).texture;
    pmrem.dispose();
    grad.geometry.dispose();
    grad.material.dispose();
  }
  return mats;
}
