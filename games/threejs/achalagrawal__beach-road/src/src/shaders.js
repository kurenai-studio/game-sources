// Custom shaders: sky dome, ocean, neon terrain grid, and post-processing passes.
import * as THREE from 'three';
import { ROAD_GLSL } from './road.js';

const NOISE_GLSL = /* glsl */ `
float hash12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float vnoise(vec2 p) {
  vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}
`;

// Matches the sky's sun glow so fogged water blends into the horizon.
const GLOW_GLSL = /* glsl */ `
vec3 sunGlow(vec3 d, vec3 L, vec3 sunColor, float glow) {
  float sd = max(dot(d, L), 0.0);
  return sunColor * glow * (0.25 * pow(sd, 4.0) + 0.6 * pow(sd, 48.0));
}
`;

const c = (hex) => new THREE.Color(hex);
const setColor = (target, v) => (v.isColor ? target.copy(v) : target.set(v));

// ---------------------------------------------------------------- sky

const SKY_FRAG = /* glsl */ `
uniform vec3 topColor; uniform vec3 horizonColor; uniform vec3 bottomColor;
uniform vec3 sunColor; uniform vec3 sunDir;
uniform float sunSize; uniform float glow; uniform float mode; uniform float time;
uniform float stars; uniform float disc;
varying vec3 vDir;
${GLOW_GLSL}
float hash13(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }
void main() {
  vec3 d = normalize(vDir);
  vec3 L = normalize(sunDir);
  float y = d.y;
  vec3 col = mix(horizonColor, topColor, pow(smoothstep(-0.02, 0.55, y), 0.7));
  col = mix(col, bottomColor, smoothstep(0.0, 0.25, -y));
  col += sunGlow(d, L, sunColor, glow);
  float sd = dot(d, L);
  if (mode < 0.5) {
    float edge = smoothstep(cos(sunSize), cos(sunSize * 0.85), sd);
    col = mix(col, sunColor * 2.0, edge * disc);
    if (stars > 0.0) {
      vec3 q = floor(d * 420.0);
      float st = step(0.9978, hash13(q)) * smoothstep(0.02, 0.3, y) * (1.0 - edge);
      col += vec3(st) * stars * (0.55 + 0.45 * sin(time * 1.7 + hash13(q + 1.0) * 20.0));
    }
  } else {
    // Retro striped sun.
    vec3 right = normalize(cross(L, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(right, L));
    vec2 p = vec2(dot(d, right), dot(d, up)) / sin(sunSize);
    float r = length(p);
    if (sd > 0.0) {
      float disc = 1.0 - smoothstep(0.98, 1.0, r);
      float v = clamp(p.y * 0.5 + 0.5, 0.0, 1.0);
      vec3 sc = mix(vec3(1.0, 0.12, 0.55), vec3(1.0, 0.86, 0.25), v) * 1.15;
      float gap = mix(0.12, 0.6, clamp((0.45 - p.y) / 0.9, 0.0, 1.0));
      float stripe = p.y < 0.45 ? step(gap, fract(p.y * 6.0)) : 1.0;
      col = mix(col, sc, disc * stripe);
    }
    vec3 q = floor(d * 380.0);
    float st = step(0.9975, hash13(q)) * smoothstep(0.05, 0.4, y);
    col += vec3(st) * (0.6 + 0.4 * sin(time * 2.0 + hash13(q + 1.0) * 20.0));
  }
  gl_FragColor = vec4(col, 1.0);
}
`;

export function createSky() {
  const material = new THREE.ShaderMaterial({
    uniforms: {
      topColor: { value: c('#ffffff') }, horizonColor: { value: c('#ffffff') }, bottomColor: { value: c('#ffffff') },
      sunColor: { value: c('#ffffff') }, sunDir: { value: new THREE.Vector3(0, 1, 0) },
      sunSize: { value: 0.05 }, glow: { value: 0.5 }, mode: { value: 0 }, time: { value: 0 },
      stars: { value: 0 }, disc: { value: 1 },
    },
    vertexShader: /* glsl */ `
      varying vec3 vDir;
      void main() {
        vec4 wp = modelMatrix * vec4(position, 1.0);
        vDir = wp.xyz - cameraPosition;
        gl_Position = projectionMatrix * viewMatrix * wp;
      }`,
    fragmentShader: SKY_FRAG,
    side: THREE.BackSide,
    depthWrite: false,
  });
  const mesh = new THREE.Mesh(new THREE.SphereGeometry(1500, 48, 24), material);
  mesh.renderOrder = -1;
  mesh.frustumCulled = false;
  return {
    mesh, material,
    // Accepts hex strings or THREE.Color values, so the time-of-day system can feed it every frame.
    set(s) {
      const u = material.uniforms;
      setColor(u.topColor.value, s.top);
      setColor(u.horizonColor.value, s.horizon);
      setColor(u.bottomColor.value, s.bottom);
      setColor(u.sunColor.value, s.sunColor);
      if (Array.isArray(s.sunDir)) u.sunDir.value.set(...s.sunDir).normalize();
      else u.sunDir.value.copy(s.sunDir);
      u.sunSize.value = s.sunSize;
      u.glow.value = s.glow;
      u.mode.value = s.mode;
      u.stars.value = s.stars ?? 0;
      u.disc.value = s.disc ?? 1;
    },
    environment(pmrem) {
      const sc = new THREE.Scene();
      sc.add(new THREE.Mesh(mesh.geometry, material));
      return pmrem.fromScene(sc, 0, 0.1, 3000);
    },
  };
}

// ---------------------------------------------------------------- ocean

const WATER_VERT = /* glsl */ `
uniform float time; uniform float waveAmp;
varying vec3 vWorld; varying vec3 vNormalW;
${ROAD_GLSL}
void wave(vec2 p, vec2 dir, float len, float a, float spd, inout float h, inout vec2 g) {
  dir = normalize(dir);
  float k = 6.2831853 / len;
  float ph = dot(dir, p) * k - time * spd;
  h += a * sin(ph);
  g += a * k * cos(ph) * dir;
}
void main() {
  vec4 wp = modelMatrix * vec4(position, 1.0);
  float dist = (wp.x - roadX(wp.z)) - shoreInfo(wp.z).r;
  float amp = waveAmp * (0.12 + 0.88 * smoothstep(0.0, 35.0, dist));
  float h = 0.0; vec2 g = vec2(0.0);
  wave(wp.xz, vec2(-1.0, 0.35), 70.0, 0.55, 0.9, h, g);
  wave(wp.xz, vec2(-0.8, -0.6), 38.0, 0.30, 1.2, h, g);
  wave(wp.xz, vec2(-0.3, 1.0), 26.0, 0.18, 1.5, h, g);
  wave(wp.xz, vec2(-1.0, -0.1), 20.0, 0.12, 1.9, h, g);
  wp.y += h * amp;
  g *= amp;
  vNormalW = normalize(vec3(-g.x, 1.0, -g.y));
  vWorld = wp.xyz;
  gl_Position = projectionMatrix * viewMatrix * wp;
}
`;

const WATER_FRAG = /* glsl */ `
uniform float time;
uniform vec3 sunDir; uniform vec3 sunColor;
uniform vec3 deepColor; uniform vec3 shallowColor; uniform vec3 foamColor;
uniform vec3 skyColor; uniform vec3 skyTop; uniform vec3 fogColor; uniform vec3 gridColor;
uniform float fogDensity; uniform float mode; uniform float specStrength; uniform float shininess;
uniform float reflectAmt; uniform float glow;
varying vec3 vWorld; varying vec3 vNormalW;
${ROAD_GLSL}
${NOISE_GLSL}
${GLOW_GLSL}
void main() {
  vec2 si = shoreInfo(vWorld.z);
  float dist = (vWorld.x - roadX(vWorld.z)) - si.r;
  float rocky = si.g;
  vec3 n;
  if (mode < 0.5) {
    n = normalize(cross(dFdx(vWorld), dFdy(vWorld)));
    if (n.y < 0.0) n = -n;
  } else {
    float a = dot(vWorld.xz, vec2(0.9, 0.4)) * 1.7 + time * 2.1;
    float b = dot(vWorld.xz, vec2(-0.3, 1.0)) * 2.3 - time * 1.7;
    float e = dot(vWorld.xz, vec2(0.6, -0.8)) * 3.1 + time * 2.6;
    vec2 rip = vec2(0.9, 0.4) * cos(a) + vec2(-0.3, 1.0) * cos(b) * 0.8 + vec2(0.6, -0.8) * cos(e) * 0.6;
    n = normalize(vNormalW + vec3(rip.x, 0.0, rip.y) * 0.05);
  }
  vec3 V = normalize(cameraPosition - vWorld);
  vec3 L = normalize(sunDir);
  vec3 R = reflect(-V, n);
  float shallowT = smoothstep(0.0, 40.0, dist);
  vec3 base = mix(shallowColor, deepColor, shallowT);
  float ndl = max(dot(n, L), 0.0);
  float fres = 0.02 + 0.98 * pow(1.0 - max(dot(n, V), 0.0), 5.0);
  float spec = pow(max(dot(R, L), 0.0), shininess) * specStrength;
  vec3 refl = mix(skyColor, skyTop, smoothstep(0.0, 0.5, R.y));

  // Shore foam: a swash line plus bands of surf rolling in.
  float swash = 2.5 + 1.8 * sin(time * 0.7 + vWorld.z * 0.04);
  float shore = 1.0 - smoothstep(swash * 0.6, swash, dist);
  float bands = sin(dist * 0.5 + time * 1.2 + vnoise(vWorld.xz * 0.05) * 4.0);
  float bandMask = smoothstep(0.82, 0.98, bands) * exp(-max(dist, 0.0) * 0.09);
  float breakup = vnoise(vWorld.xz * 0.35 + vec2(time * 0.3, 0.0));
  // Rocky coasts churn more white water around the rocks.
  float churn = rocky * smoothstep(0.55, 0.85, vnoise(vWorld.xz * 0.22 + vec2(time * 0.25, -time * 0.1))) * exp(-max(dist, 0.0) * 0.12);
  float foam = clamp(shore + bandMask * (1.0 + rocky) + churn, 0.0, 1.0) * smoothstep(0.15, 0.55, breakup + shore * 0.3);

  vec3 col;
  if (mode < 0.5) {          // low-poly facets
    col = base * (0.6 + 0.5 * ndl);
    col = mix(col, refl, fres * reflectAmt);
    col += sunColor * spec;
    foam = step(0.45, foam);
  } else if (mode < 1.5) {   // toon
    col = base * (ndl > 0.55 ? 1.0 : 0.82);
    col = mix(col, refl, step(0.35, fres) * reflectAmt);
    col += sunColor * step(0.5, spec) * 0.8;
    float lines = smoothstep(0.92, 0.97, sin(vWorld.x * 0.35 + sin(vWorld.z * 0.2 + time) * 1.5 + time * 0.8))
                * smoothstep(0.4, 0.7, vnoise(vWorld.xz * 0.08 + time * 0.05));
    col = mix(col, foamColor, lines * 0.5);
    foam = step(0.5, foam);
  } else if (mode < 2.5) {   // neon grid
    col = base;
    vec2 gp = vWorld.xz / 8.0;
    vec2 gg = abs(fract(gp - 0.5) - 0.5) / fwidth(gp);
    float line = 1.0 - min(min(gg.x, gg.y), 1.0);
    col += gridColor * line * 0.9;
    col += sunColor * spec;
    col = mix(col, refl, fres * reflectAmt);
    foam *= 0.6;
  } else if (mode < 3.5) {   // soft watercolour
    col = base * (0.8 + 0.25 * ndl);
    col = mix(col, refl, fres * reflectAmt);
    col += sunColor * spec * 0.5;
  } else {                   // golden-hour realism
    col = base * (0.35 + 0.65 * ndl);
    col += shallowColor * 0.15 * pow(max(dot(V, -L), 0.0), 4.0);
    col = mix(col, refl, fres * reflectAmt);
    col += sunColor * spec;
  }
  col = mix(col, foamColor, foam);

  float fd = length(vWorld - cameraPosition);
  float ff = 1.0 - exp(-fogDensity * fogDensity * fd * fd);
  col = mix(col, fogColor + sunGlow(-V, L, sunColor, glow), ff);
  gl_FragColor = vec4(col, 1.0);
}
`;

const WATER_SIZE = 2400;
const SHORE_TEXELS = 1024;
const SHORE_SPAN = 2800;
const RAIN_BOX = [70, 40, 70];

function waterGeometry(segments) {
  const g = new THREE.PlaneGeometry(WATER_SIZE, WATER_SIZE, segments, segments);
  g.rotateX(-Math.PI / 2);
  return g;
}

export function createWater(segments) {
  const u = {
    time: { value: 0 }, waveAmp: { value: 1 },
    sunDir: { value: new THREE.Vector3(0, 1, 0) }, sunColor: { value: c('#ffffff') },
    deepColor: { value: c('#000000') }, shallowColor: { value: c('#000000') }, foamColor: { value: c('#ffffff') },
    skyColor: { value: c('#ffffff') }, skyTop: { value: c('#ffffff') }, fogColor: { value: c('#ffffff') },
    gridColor: { value: c('#000000') },
    fogDensity: { value: 0.003 }, mode: { value: 0 }, specStrength: { value: 1 }, shininess: { value: 60 },
    reflectAmt: { value: 0.5 }, glow: { value: 0.5 },
    shoreTex: { value: null }, shoreZ0: { value: 0 }, shoreSpan: { value: SHORE_SPAN },
  };
  // Shoreline distance (r) and rockiness (g) sampled along z around the camera.
  const shoreData = new Uint16Array(SHORE_TEXELS * 2);
  const shoreTex = new THREE.DataTexture(shoreData, SHORE_TEXELS, 1, THREE.RGFormat, THREE.HalfFloatType);
  shoreTex.minFilter = shoreTex.magFilter = THREE.LinearFilter;
  u.shoreTex.value = shoreTex;
  let shoreCenter = Infinity;

  const material = new THREE.ShaderMaterial({ uniforms: u, vertexShader: WATER_VERT, fragmentShader: WATER_FRAG });
  const mesh = new THREE.Mesh(waterGeometry(segments), material);
  mesh.frustumCulled = false;
  return {
    mesh, material,
    setSegments(n) {
      if (n === segments) return;
      segments = n;
      mesh.geometry.dispose();
      mesh.geometry = waterGeometry(n);
    },
    // w = water preset, sky = sky colours, sunDir = Vector3, fog = { color, density }.
    set(w, sky, sunDir, fog) {
      setColor(u.deepColor.value, w.deep);
      setColor(u.shallowColor.value, w.shallow);
      setColor(u.foamColor.value, w.foam);
      setColor(u.gridColor.value, w.grid);
      u.mode.value = w.mode;
      u.specStrength.value = w.spec;
      u.shininess.value = w.shininess;
      u.reflectAmt.value = w.reflect;
      u.waveAmp.value = w.amp;
      setColor(u.skyColor.value, sky.horizon);
      setColor(u.skyTop.value, sky.top);
      setColor(u.sunColor.value, sky.sunColor);
      u.glow.value = sky.glow;
      u.sunDir.value.copy(sunDir);
      setColor(u.fogColor.value, fog.color);
      u.fogDensity.value = fog.density;
    },
    // shoreAt(z) -> [distance from road centre to waterline, rockiness 0..1]
    update(time, cam, shoreAt, force = false) {
      u.time.value = time;
      // Snap to whole grid cells so the waves don't swim as the plane follows the camera.
      const cell = WATER_SIZE / segments;
      mesh.position.set(Math.round(cam.x / cell) * cell, 0, Math.round(cam.z / cell) * cell);
      if (force || Math.abs(cam.z - shoreCenter) > 300) {
        shoreCenter = cam.z;
        const z0 = cam.z - SHORE_SPAN / 2;
        for (let i = 0; i < SHORE_TEXELS; i++) {
          const [d, rock] = shoreAt(z0 + ((i + 0.5) / SHORE_TEXELS) * SHORE_SPAN);
          shoreData[i * 2] = THREE.DataUtils.toHalfFloat(d);
          shoreData[i * 2 + 1] = THREE.DataUtils.toHalfFloat(rock);
        }
        u.shoreZ0.value = z0;
        shoreTex.needsUpdate = true;
      }
    },
  };
}

// ---------------------------------------------------------------- rain

// Streaks that wrap around the camera, animated entirely on the GPU.
export function createRain(count = 3000) {
  const pos = new Float32Array(count * 6), end = new Float32Array(count * 2);
  for (let i = 0; i < count; i++) {
    const x = Math.random() * RAIN_BOX[0], y = Math.random() * RAIN_BOX[1], z = Math.random() * RAIN_BOX[2];
    pos.set([x, y, z, x, y, z], i * 6);
    end[i * 2 + 1] = 1;
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  g.setAttribute('aEnd', new THREE.BufferAttribute(end, 1));
  const material = new THREE.ShaderMaterial({
    uniforms: {
      time: { value: 0 }, camPos: { value: new THREE.Vector3() }, opacity: { value: 0 },
      color: { value: c('#cfd8e6') }, wind: { value: new THREE.Vector2(2, 1) },
    },
    vertexShader: /* glsl */ `
      uniform float time; uniform vec3 camPos; uniform vec2 wind;
      attribute float aEnd;
      varying float vA;
      void main() {
        vec3 box = vec3(${RAIN_BOX.map((v) => v.toFixed(1)).join(', ')});
        vec3 vel = vec3(wind.x, -22.0, wind.y);
        vec3 p = position + vel * time;
        p = mod(p - camPos, box) + camPos - box * 0.5;
        p += normalize(vel) * 0.9 * aEnd;
        vA = 1.0 - aEnd * 0.8;
        gl_Position = projectionMatrix * viewMatrix * vec4(p, 1.0);
      }`,
    fragmentShader: /* glsl */ `
      uniform vec3 color; uniform float opacity;
      varying float vA;
      void main() { gl_FragColor = vec4(color, opacity * vA * 0.55); }`,
    transparent: true,
    depthWrite: false,
  });
  const mesh = new THREE.LineSegments(g, material);
  mesh.frustumCulled = false;
  mesh.renderOrder = 2;
  return {
    mesh, material,
    update(time, cam, amount, colorHex) {
      const u = material.uniforms;
      u.time.value = time;
      u.camPos.value.copy(cam);
      u.opacity.value = amount;
      if (colorHex) setColor(u.color.value, colorHex);
      mesh.visible = amount > 0.01;
    },
  };
}

// ---------------------------------------------------------------- neon terrain

export function neonTerrainMaterial(style) {
  return new THREE.ShaderMaterial({
    uniforms: {
      baseColor: { value: c(style.terrain.base) },
      lineA: { value: c(style.terrain.lineA) },
      lineB: { value: c(style.terrain.lineB) },
      fogColor: { value: c(style.fog.color) },
      fogDensity: { value: style.fog.density },
    },
    vertexShader: /* glsl */ `
      varying vec3 vWorld;
      void main() {
        vec4 wp = modelMatrix * vec4(position, 1.0);
        vWorld = wp.xyz;
        gl_Position = projectionMatrix * viewMatrix * wp;
      }`,
    fragmentShader: /* glsl */ `
      uniform vec3 baseColor; uniform vec3 lineA; uniform vec3 lineB; uniform vec3 fogColor; uniform float fogDensity;
      varying vec3 vWorld;
      void main() {
        vec2 gp = vWorld.xz / 6.0;
        vec2 gg = abs(fract(gp - 0.5) - 0.5) / fwidth(gp);
        float line = 1.0 - min(min(gg.x, gg.y), 1.0);
        vec3 lc = mix(lineB, lineA, smoothstep(2.0, 30.0, vWorld.y));
        vec3 col = baseColor + lc * line * 1.4;
        float fd = length(vWorld - cameraPosition);
        col = mix(col, fogColor, 1.0 - exp(-fogDensity * fogDensity * fd * fd));
        gl_FragColor = vec4(col, 1.0);
      }`,
  });
}

// ---------------------------------------------------------------- post

const FULLSCREEN_VERT = /* glsl */ `
varying vec2 vUv;
void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }
`;

// Kuwahara filter + pigment edges + paper grain = watercolour look.
export const PainterlyShader = {
  uniforms: { tDiffuse: { value: null }, resolution: { value: new THREE.Vector2(1, 1) } },
  vertexShader: FULLSCREEN_VERT,
  fragmentShader: /* glsl */ `
    uniform sampler2D tDiffuse; uniform vec2 resolution;
    varying vec2 vUv;
    ${NOISE_GLSL}
    vec3 tex(vec2 uv) { return texture2D(tDiffuse, uv).rgb; }
    void main() {
      vec2 px = 1.0 / resolution;
      vec2 warp = vec2(vnoise(vUv * resolution / 36.0), vnoise(vUv * resolution / 36.0 + 17.0)) - 0.5;
      vec2 uv = vUv + warp * px * 4.0;
      vec3 m0 = vec3(0.0), m1 = vec3(0.0), m2 = vec3(0.0), m3 = vec3(0.0);
      vec3 s0 = vec3(0.0), s1 = vec3(0.0), s2 = vec3(0.0), s3 = vec3(0.0);
      for (int j = 0; j <= 3; j++) {
        for (int i = 0; i <= 3; i++) {
          vec2 o = vec2(float(i), float(j)) * px * 2.2;
          vec3 cc;
          cc = tex(uv + vec2(-o.x, -o.y)); m0 += cc; s0 += cc * cc;
          cc = tex(uv + vec2( o.x, -o.y)); m1 += cc; s1 += cc * cc;
          cc = tex(uv + vec2(-o.x,  o.y)); m2 += cc; s2 += cc * cc;
          cc = tex(uv + vec2( o.x,  o.y)); m3 += cc; s3 += cc * cc;
        }
      }
      m0 /= 16.0; m1 /= 16.0; m2 /= 16.0; m3 /= 16.0;
      vec3 v0 = abs(s0 / 16.0 - m0 * m0), v1 = abs(s1 / 16.0 - m1 * m1);
      vec3 v2 = abs(s2 / 16.0 - m2 * m2), v3 = abs(s3 / 16.0 - m3 * m3);
      float q0 = v0.r + v0.g + v0.b, q1 = v1.r + v1.g + v1.b, q2 = v2.r + v2.g + v2.b, q3 = v3.r + v3.g + v3.b;
      vec3 col = m0; float best = q0;
      if (q1 < best) { best = q1; col = m1; }
      if (q2 < best) { best = q2; col = m2; }
      if (q3 < best) { best = q3; col = m3; }
      vec3 ex = tex(uv + vec2(px.x * 2.0, 0.0)) - tex(uv - vec2(px.x * 2.0, 0.0));
      vec3 ey = tex(uv + vec2(0.0, px.y * 2.0)) - tex(uv - vec2(0.0, px.y * 2.0));
      col *= 1.0 - smoothstep(0.03, 0.3, length(ex) + length(ey)) * 0.42;
      float paper = vnoise(vUv * resolution / 2.0) * 0.5 + vnoise(vUv * resolution / 7.0) * 0.35 + vnoise(vUv * resolution / 23.0) * 0.15;
      float blot = vnoise(vUv * resolution / 90.0 + 3.0);
      float lum = dot(col, vec3(0.299, 0.587, 0.114));
      col *= 0.82 + 0.2 * paper;
      col *= 0.92 + 0.14 * blot; // uneven pigment wash
      col = mix(vec3(lum), col, 0.88);
      float v = length((vUv - 0.5) * vec2(resolution.x / resolution.y, 1.0));
      col = mix(col, vec3(0.93, 0.9, 0.84), smoothstep(0.55, 1.05, v) * 0.7);
      gl_FragColor = vec4(col, 1.0);
    }`,
};

export const FinishShader = {
  uniforms: {
    tDiffuse: { value: null }, resolution: { value: new THREE.Vector2(1, 1) },
    time: { value: 0 }, vignette: { value: 0 }, grain: { value: 0 }, scan: { value: 0 }, chroma: { value: 0 },
  },
  vertexShader: FULLSCREEN_VERT,
  fragmentShader: /* glsl */ `
    uniform sampler2D tDiffuse; uniform vec2 resolution;
    uniform float time; uniform float vignette; uniform float grain; uniform float scan; uniform float chroma;
    varying vec2 vUv;
    float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
    void main() {
      vec2 uv = vUv;
      vec3 col;
      if (chroma > 0.0) {
        vec2 off = (uv - 0.5) * chroma;
        col = vec3(texture2D(tDiffuse, uv + off).r, texture2D(tDiffuse, uv).g, texture2D(tDiffuse, uv - off).b);
      } else {
        col = texture2D(tDiffuse, uv).rgb;
      }
      if (scan > 0.0) col *= 1.0 - scan * (0.5 + 0.5 * sin(uv.y * resolution.y * 1.5));
      float v = 1.0 - smoothstep(0.35, 0.95, length((uv - 0.5) * vec2(1.15, 1.0)) * 1.25);
      col *= mix(1.0, v, vignette);
      col += (hash(uv * resolution + fract(time) * 100.0) - 0.5) * grain;
      gl_FragColor = vec4(col, 1.0);
    }`,
};
