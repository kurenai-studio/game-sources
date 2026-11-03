/* Three-scale plaster / masonry — ported from jungle-trail/src/world/stoneTex.js.
 *
 *   MICRO   dressed plaster face, ~1.5 m tile (grain, pits, hairline cracks)
 *   MASK    orientation tenants: dirt streaks, ledge dust, window-sill grime
 *   MACRO   one field over tens of metres so a wall is not forty copies
 *
 * Periods stay integral (p = uv * 8, period == scale) so pnoise wraps clean.
 * Never name a GLSL ident `patch` — ANGLE reserves it.
 */

const HELP = /* glsl */ `
float unit(float x){ return x * 0.5 + 0.5; }
float contrast(float x, float k){
  x = clamp(x, 0.0, 1.0);
  return x <= 0.5 ? 0.5 * pow(2.0 * x, k) : 1.0 - 0.5 * pow(2.0 * (1.0 - x), k);
}
`;

const FIELDS = /* glsl */ `
void plasterFields(vec2 p, out float bed, out float grain, out float pit, out float crack){
  /* c27: isotropic low-freq blotches — the old p.x*0.85 / p.y*1.6 bed
   * plus vertical drips read as plywood sheeting, not Italy plaster. */
  float warp = pfbm(p * 0.55, 4.4, 3) * 0.42;
  bed = pfbm(p * 0.48 + vec2(warp, -warp * 0.7), 3.84, 4);
  vec2 ag = pworley(p * 6.4, 51.2);
  grain = sstep(0.18, 0.0, ag.y - ag.x) * 0.35;
  float sizeVar = unit(pfbm(p * 2.5, 20.0, 3));
  vec2 pw = pworley(p * 5.0, 40.0);
  pit = sstep(0.04 + 0.18 * sizeVar * sizeVar, 0.004, pw.x)
      * sstep(0.42, 0.70, unit(pfbm(p * 1.5, 12.0, 3)));
  vec2 cWarp = vec2(pfbm(p * 0.85 + 3.0, 6.8, 3), pfbm(p * 0.85 + 9.0, 6.8, 3)) * 1.85;
  vec2 cwl = pworley(p * 2.15 + cWarp, 17.2);
  float net = sstep(0.048, 0.002, cwl.y - cwl.x);
  float region = sstep(0.62, 0.88, unit(pfbm(p * 0.22 + 5.0, 1.76, 3)));
  float breaker = sstep(0.34, 0.70, unit(pfbm(p * 4.4 + 11.0, 35.2, 2)));
  float amp = 0.08 + 1.15 * pow(unit(pfbm(p * 0.38 + 19.0, 3.04, 3)), 1.65);
  crack = net * region * breaker * amp;
}
`;

/* Dressed plaster — chips/cracks anywhere on the face, not just tile rims. */
export const PLASTER_MICRO = HELP + FIELDS + /* glsl */ `
void surf(vec2 uv, out vec3 albedo, out float height, out float rough, out float ao){
  vec2 p = uv * 8.0;
  float bed, grain, pit, crack;
  plasterFields(p, bed, grain, pit, crack);
  float rind = contrast(unit(bed * 1.35), 1.35);
  vec2 cw = pworley(p * 2.4 + 6.0, 19.2);
  float chip = sstep(0.16, 0.045, cw.x) * sstep(0.28, 0.72, unit(pfbm(p * 1.6 + 9.0, 12.8, 3)));
  float chip2 = sstep(0.12, 0.03, pworley(p * 4.6 + 14.0, 36.8).x)
              * sstep(0.40, 0.78, unit(pfbm(p * 2.8 + 3.0, 22.4, 3)));
  float flake = sstep(0.62, 0.90, unit(pfbm(p * 3.4 + 11.0, 27.2, 3))) * (1.0 - pit);
  /* Irregular blotch chips + underlayer — not vertical drip columns. */
  float blot = contrast(unit(pfbm(p * 0.34 + 5.0, 2.72, 4)), 1.85);
  float blot2 = contrast(unit(pfbm(p * 0.78 + 19.0, 6.24, 3)), 2.15);
  /* Hard plaster-loss chips — step, not a soft amoeba mix. */
  float under = step(0.86, blot) * step(0.68, blot2);
  float cluster = sstep(0.56, 0.86, unit(pfbm(p * 0.30 + 21.0, 2.4, 3)));
  chip *= cluster;
  chip2 *= cluster;
  flake *= cluster;
  pit *= 0.35 + 0.65 * cluster;
  float mottle = unit(pfbm(p * 0.28 + 31.0, 2.24, 4));
  /* Plaster stipple, c18 fix 7: the c17 dot field was ONE worley frequency at
   * ONE amplitude across every face — styrofoam. Two scales of trowel dots
   * are blended by a metre-scale patch mask, and a second mask fades the
   * whole relief so some patches are near-smooth float finish. */
  float stipCoarse = sstep(0.28, 0.06, pworley(p * 2.6 + 17.0, 20.8).x);
  float stipFine = sstep(0.20, 0.04, pworley(p * 6.2 + 53.0, 49.6).x);
  float scaleMask = sstep(0.35, 0.65, unit(pfbm(p * 0.24 + 63.0, 1.92, 3)));
  /* c26: 4x crops read as bubble-wrap craters — keep stipple as sparse
   * weathered patches, not a uniform dimple field. */
  float ampMask = 0.02 + 0.34 * contrast(unit(pfbm(p * 0.18 + 77.0, 1.44, 3)), 2.4);
  float stip = mix(stipCoarse, stipFine, scaleMask) * ampMask;
  float undul = pfbm(p * 1.6 + 41.0, 12.8, 3);
  /* ~10% desaturated toward luma vs the c16 ochre (fix 10). */
  vec3 clean = vec3(0.546, 0.482, 0.385);
  vec3 dirty = vec3(0.366, 0.302, 0.221);
  vec3 stone = vec3(0.26, 0.20, 0.13);
  vec3 voidC = vec3(0.12, 0.09, 0.06);
  vec3 grimeC = vec3(0.16, 0.12, 0.08);
  albedo = mix(clean, dirty, rind * 0.22 + mottle * 0.08);
  albedo = mix(albedo, voidC, crack * 0.96 + pit * 0.03);
  albedo = mix(albedo, stone, (chip + chip2) * 1.0 + flake * 0.62 + under * 0.78);
  albedo = mix(albedo, grimeC, step(0.80, max(blot, blot2)) * 0.22);
  albedo *= 0.80 + 0.16 * unit(pfbm(p * 0.38, 3.04, 3));
  albedo *= 1.0 - grain * 0.04;
  height = 0.55 + bed * 0.28 + stip * 0.05 + undul * 0.10 - pit * 0.08 - crack * 0.58
         - chip * 0.62 - chip2 * 0.44 - flake * 0.20 - under * 0.18 - blot * 0.06;
  rough = mix(0.80, 0.96, rind) + (chip + chip2) * 0.10 + mottle * 0.04;
  ao = 1.0 - pit * 0.22 - crack * 0.36 - grain * 0.05 - chip * 0.30 - chip2 * 0.18;
}
`;

/* r dirt-streak / runoff, g ledge dust, b window-sill grime */
export const PLASTER_MASK = HELP + FIELDS + /* glsl */ `
void main(){
  vec2 p = vUv * 8.0;
  float bed, grain, pit, crack;
  plasterFields(p, bed, grain, pit, crack);
  /* c27: mask.r used to be vertical runoff columns (plywood). Now it is
   * the same low-freq blotch field the micro bake uses. */
  float blot = contrast(unit(pfbm(p * 0.36 + 3.0, 2.88, 4)), 2.05);
  float blot2 = contrast(unit(pfbm(p * 0.82 + 11.0, 6.56, 3)), 1.75);
  float dust = sstep(0.10, 0.68, unit(pfbm(p * 1.2 + 9.0, 9.6, 4)));
  float sill = sstep(0.28, 0.86, unit(pfbm(p * 1.15 + 7.0, 9.2, 3)));
  float dirt = clamp(blot * 0.62 + blot2 * 0.40 + crack * 0.30 + pit * 0.16 + sill * 0.12, 0.0, 1.0);
  gl_FragColor = vec4(dirt, dust, sill, 1.0);
}
`;

export const PLASTER_MACRO = HELP + /* glsl */ `
void main(){
  vec2 p = vUv * 8.0;
  /* fbm hugs 0.5 — without a hard contrast curve the meters-scale patches
   * collapse to a ±5% wash that vanishes under warm sun (fix 4). Quantize
   * softly toward 3 tones so distinct patch borders survive at 1x. */
  float t0 = contrast(unit(pfbm(p, 8.0, 4)), 3.4);
  float t1 = contrast(unit(pfbm(p * 0.45 + 7.0, 3.6, 3)), 3.0);
  float tone = clamp(t0 * 0.50 + t1 * 0.70, 0.0, 1.0);
  tone = mix(tone, floor(tone * 3.0 + 0.5) / 3.0, 0.78);
  float stain = contrast(unit(pfbm(p * 0.5, 4.0, 3) + pfbm(p * 2.0, 16.0, 2) * 0.30), 2.6);
  float soot  = contrast(unit(pfbm(p * 1.5, 12.0, 4)), 2.3);
  /* Macro crack network in alpha (c21 fix 1): metre-scale meandering
   * fissures broken into segments so no single line crosses a whole facade.
   * These read at 1x where the micro-bake hairlines vanish. */
  vec2 wM = vec2(pfbm(p * 0.55 + 4.0, 4.4, 3), pfbm(p * 0.55 + 11.0, 4.4, 3)) * 1.65;
  vec2 cwM = pworley(p * 0.62 + wM + 2.0, 5.0);
  float lineM = sstep(0.145, 0.012, cwM.y - cwM.x);
  float segM = sstep(0.32, 0.64, unit(pfbm(p * 1.35 + 13.0, 10.8, 3)));
  float taperM = 0.30 + 0.70 * unit(pfbm(p * 2.4 + 21.0, 19.2, 2));
  gl_FragColor = vec4(tone, stain, soot, lineM * segM * taperM);
}
`;

export const STAIN_A = HELP + /* glsl */ `
void main(){
  /* c29: rain streaks + open sill soak. Never a closed ring / crop circle. */
  float t = 1.0 - vUv.y;
  float n = unit(pfbm(vUv * 6.2 + 2.4, 6.2, 4));
  float n2 = unit(pfbm(vUv * 3.1 + 8.1, 3.1, 4));
  float a = 0.0;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float wob = unit(pfbm(vec2(fi * 3.1 + 1.7, vUv.y * 4.0), vec2(4.0), 3)) - 0.5;
    float cx = 0.20 + fi * 0.30 + wob * 0.12;
    float w = 0.016 + 0.028 * unit(pfbm(vec2(fi * 4.7, vUv.y * 5.2), vec2(5.2), 2));
    float len = 0.52 + 0.42 * fract(fi * 0.618 + 0.19);
    float col = sstep(w, w * 0.16, abs(vUv.x - cx));
    col *= sstep(len, len * 0.38, t) * sstep(0.0, 0.05, t);
    a = max(a, col * (0.38 + 0.48 * n));
  }
  float head = sstep(0.18, 0.0, t) * sstep(0.96, 0.28, abs(vUv.x - 0.5) * 2.0);
  float wash = sstep(0.42, 0.02, t) * sstep(0.94, 0.22, abs(vUv.x - 0.5 + (n2 - 0.5) * 0.18) * 2.0);
  a = clamp(max(a, max(head * (0.26 + n * 0.20), wash * (0.12 + n * 0.10))), 0.0, 0.48);
  vec3 c = mix(vec3(0.38, 0.30, 0.18), vec3(0.26, 0.19, 0.12), n);
  gl_FragColor = vec4(c, a);
}
`;

export const STAIN_B = HELP + /* glsl */ `
void main(){
  /* c29: open base-grime wash — torn sides, open top, no radial ring. */
  float n = unit(pfbm(vUv * 5.2 + 8.1, 5.2, 4));
  float n2 = unit(pfbm(vUv * 2.4 + 3.0, 2.4, 3));
  float fall = sstep(0.12, 0.94, vUv.y);
  float sides = sstep(0.02, 0.16, vUv.x) * sstep(0.02, 0.16, 1.0 - vUv.x);
  float torn = sstep(0.20, 0.76, n) * sstep(0.16, 0.68, n2);
  float a = clamp(fall * sides * torn * (0.16 + n * 0.22), 0.0, 0.36);
  vec3 c = mix(vec3(0.40, 0.32, 0.20), vec3(0.28, 0.21, 0.13), n);
  gl_FragColor = vec4(c, a);
}
`;

/* Streak-style leak (c21 fix 3): rivulets hanging from the decal's top edge,
 * each with its own wobble, width and length — the anti-stamp counterpart to
 * the round A/B soot blots that were repeating at identical scale. */
export const STAIN_D = HELP + /* glsl */ `
void main(){
  float t = 1.0 - vUv.y; /* 0 at the top edge, grows downward */
  float n = unit(pfbm(vUv * 6.0 + 4.2, 6.0, 4));
  float a = 0.0;
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    float wob = unit(pfbm(vec2(fi * 2.7 + 1.3, vUv.y * 3.0), vec2(3.0), 3)) - 0.5;
    float cx = 0.14 + fi * 0.24 + wob * 0.14;
    float w = 0.014 + 0.024 * unit(pfbm(vec2(fi * 5.1, vUv.y * 6.0), vec2(6.0), 2));
    float len = 0.45 + 0.5 * fract(fi * 0.618 + 0.27);
    float col = sstep(w, w * 0.2, abs(vUv.x - cx));
    col *= sstep(len, len * 0.45, t) * sstep(0.0, 0.05, t);
    a = max(a, col * (0.45 + 0.55 * n));
  }
  float head = sstep(0.15, 0.01, t) * sstep(0.95, 0.30, abs(vUv.x - 0.5) * 2.0);
  a = clamp(max(a, head * (0.22 + n * 0.28)), 0.0, 0.50);
  vec3 c = mix(vec3(0.40, 0.30, 0.20), vec3(0.28, 0.20, 0.13), n);
  gl_FragColor = vec4(c, a);
}
`;

export const STAIN_C = HELP + /* glsl */ `
void main(){
  vec2 p = (vUv - 0.5) * vec2(0.95, 2.1);
  float n = unit(pfbm(vec2(vUv.x * 8.0, vUv.y * 3.0) + 4.0, vec2(8.0, 3.0), 4));
  float column = sstep(0.28, 0.04, abs(p.x + (n - 0.5) * 0.18));
  float fall = sstep(-0.85, 0.75, p.y) * sstep(1.05, 0.15, p.y);
  float a = column * fall * (0.22 + n * 0.32);
  vec3 c = mix(vec3(0.40, 0.30, 0.20), vec3(0.28, 0.21, 0.13), n);
  gl_FragColor = vec4(c, a);
}
`;
