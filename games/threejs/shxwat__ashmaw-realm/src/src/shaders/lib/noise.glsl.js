/**
 * GLSL noise library, shared by every custom shader in the project.
 * Simplex 3D is Ashima Arts / Stefan Gustavson (MIT). Everything below it is
 * ours: fbm variants, curl, ridged, voronoi and a couple of colour ramps used
 * by lava/fire so the palettes stay consistent across systems.
 */
/**
 * Shared global uniforms.
 *
 * Several injections land in the same shader (terrain + ambient, water +
 * ambient), so every block below is preprocessor-guarded — that's the only way
 * to compose independent onBeforeCompile patches without redefinition errors.
 */
export const AX_GLOBALS = /* glsl */`
#ifndef AX_GLOBALS_INCLUDED
#define AX_GLOBALS_INCLUDED
uniform float uTime;
uniform float uEmberMood;
uniform float uAshLoad;
uniform float uWetness;
uniform vec3  uFirePos;
uniform vec3  uFireColor;
uniform float uFireIntensity;
uniform vec3  uSunDir;
uniform vec3  uSkyColor;
uniform vec3  uFogColor;
uniform float uFogDensity;
uniform vec2  uWindDir;
uniform float uWindStrength;
uniform float uGustPhase;
uniform vec4  uShockwave;
uniform vec4  uRoarWave;
#endif
`;

export const NOISE_GLSL = /* glsl */`
#ifndef AX_NOISE_INCLUDED
#define AX_NOISE_INCLUDED
vec3 ax_mod289(vec3 x){ return x - floor(x * (1.0/289.0)) * 289.0; }
vec4 ax_mod289(vec4 x){ return x - floor(x * (1.0/289.0)) * 289.0; }
vec4 ax_permute289(vec4 x){ return ax_mod289(((x*34.0)+1.0)*x); }
vec4 ax_taylorInvSqrt(vec4 r){ return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v){
  const vec2 C = vec2(1.0/6.0, 1.0/3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
  vec3 i  = floor(v + dot(v, C.yyy));
  vec3 x0 = v - i + dot(i, C.xxx);
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;
  i = ax_mod289(i);
  vec4 p = ax_permute289(ax_permute289(ax_permute289(
             i.z + vec4(0.0, i1.z, i2.z, 1.0))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0));
  float n_ = 0.142857142857;
  vec3 ns = n_ * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);
  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);
  vec4 norm = ax_taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
  p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

float fbm(vec3 p, int oct){
  float a = 0.5, s = 0.0, n = 0.0;
  for(int i = 0; i < 8; i++){
    if(i >= oct) break;
    s += a * snoise(p);
    n += a;
    a *= 0.5;
    p *= 2.03;
  }
  return s / max(n, 1e-4);
}

float fbm4(vec3 p){ return fbm(p, 4); }
float fbm6(vec3 p){ return fbm(p, 6); }

float ridged(vec3 p, int oct){
  float a = 0.5, s = 0.0, n = 0.0;
  for(int i = 0; i < 8; i++){
    if(i >= oct) break;
    float v = 1.0 - abs(snoise(p));
    s += a * v * v;
    n += a;
    a *= 0.5;
    p *= 2.07;
  }
  return s / max(n, 1e-4);
}

/** Finite-difference curl of a 3D potential — swirly advection for smoke/fire. */
vec3 curlNoise(vec3 p){
  const float e = 0.12;
  float x1 = snoise(p + vec3(0.0, e, 0.0)) - snoise(p - vec3(0.0, e, 0.0));
  float x2 = snoise(p + vec3(0.0, 0.0, e)) - snoise(p - vec3(0.0, 0.0, e));
  float y1 = snoise(p + vec3(0.0, 0.0, e)) - snoise(p - vec3(0.0, 0.0, e));
  float y2 = snoise(p + vec3(e, 0.0, 0.0)) - snoise(p - vec3(e, 0.0, 0.0));
  float z1 = snoise(p + vec3(e, 0.0, 0.0)) - snoise(p - vec3(e, 0.0, 0.0));
  float z2 = snoise(p + vec3(0.0, e, 0.0)) - snoise(p - vec3(0.0, e, 0.0));
  return normalize(vec3(x1 - x2, y1 - y2, z1 - z2) / (2.0 * e) + 1e-5);
}

float hash12(vec2 p){
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p){
  vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xx + p3.yz) * p3.zy);
}

/** Voronoi returning (F1, F2) — cell distance and second-nearest, for crust/scales. */
vec2 voronoi(vec2 p){
  vec2 n = floor(p), f = fract(p);
  float f1 = 8.0, f2 = 8.0;
  for(int j = -1; j <= 1; j++){
    for(int i = -1; i <= 1; i++){
      vec2 g = vec2(float(i), float(j));
      vec2 o = hash22(n + g);
      float d = length(g + o - f);
      if(d < f1){ f2 = f1; f1 = d; }
      else if(d < f2){ f2 = d; }
    }
  }
  return vec2(f1, f2);
}

/** Blackbody-ish fire ramp: t=0 smoke → t=1 white core. Tuned by eye, not physics. */
vec3 fireRamp(float t){
  t = clamp(t, 0.0, 1.0);
  vec3 smoke = vec3(0.055, 0.045, 0.048);
  vec3 deep  = vec3(0.42, 0.055, 0.012);
  vec3 mid   = vec3(1.00, 0.28, 0.045);
  vec3 hot   = vec3(1.00, 0.72, 0.22);
  vec3 core  = vec3(1.00, 0.97, 0.86);
  vec3 c = mix(smoke, deep, smoothstep(0.00, 0.22, t));
  c = mix(c, mid,  smoothstep(0.18, 0.50, t));
  c = mix(c, hot,  smoothstep(0.48, 0.78, t));
  c = mix(c, core, smoothstep(0.78, 1.00, t));
  return c;
}

/** Molten rock ramp: t=0 cooled crust → t=1 fresh magma. */
vec3 lavaRamp(float t){
  t = clamp(t, 0.0, 1.0);
  vec3 crust = vec3(0.035, 0.028, 0.030);
  vec3 warm  = vec3(0.22, 0.055, 0.020);
  vec3 glow  = vec3(0.95, 0.24, 0.035);
  vec3 hot   = vec3(1.00, 0.62, 0.12);
  vec3 white = vec3(1.00, 0.93, 0.70);
  vec3 c = mix(crust, warm, smoothstep(0.05, 0.35, t));
  c = mix(c, glow,  smoothstep(0.34, 0.62, t));
  c = mix(c, hot,   smoothstep(0.60, 0.85, t));
  c = mix(c, white, smoothstep(0.88, 1.00, t));
  return c;
}
#endif
`;
