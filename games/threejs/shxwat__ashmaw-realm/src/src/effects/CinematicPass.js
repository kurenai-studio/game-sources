/**
 * The grade pass — one fragment shader carrying most of the "film" look, because
 * eight separate full-screen passes would cost eight full-screen reads.
 *
 * In order:
 *   god rays        radial occlusion-aware blur from the sun's screen position,
 *                   masked by luminance so only the bright sky streaks
 *   heat distortion two-octave noise refraction inside a world-projected radius
 *                   around the dragon's fire / the volcano vent
 *   motion blur     directional smear along the camera's screen-space velocity
 *   chromatic ab.   radial channel separation, zero at centre
 *   lens dirt       screen-space grime lit by the frame's own bloom energy
 *   grade           lift / gamma / gain, saturation, tone contrast
 *   vignette        natural + optional anamorphic squeeze
 *   grain           animated, luminance-weighted so shadows grain more
 */
import * as THREE from 'three';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';

export const CinematicShader = {
  name: 'CinematicShader',
  uniforms: {
    tDiffuse:      { value: null },
    tDirt:         { value: null },
    uTime:         { value: 0 },
    uResolution:   { value: new THREE.Vector2(1, 1) },

    uSunScreen:    { value: new THREE.Vector2(0.5, 0.9) },
    uSunVisible:   { value: 0 },
    uGodRays:      { value: 0.16 },
    uGodDecay:     { value: 0.96 },

    uHeatCenter:   { value: new THREE.Vector2(0.5, 0.5) },
    uHeatStrength: { value: 0.0 },
    uHeatRadius:   { value: 0.35 },
    uHeat2Center:  { value: new THREE.Vector2(0.5, 0.5) },
    uHeat2Strength:{ value: 0.0 },

    uMotion:       { value: new THREE.Vector2(0, 0) },
    uMotionAmount: { value: 0.5 },

    uChroma:       { value: 0.55 },
    uDirt:         { value: 0.075 },
    uVignette:     { value: 0.9 },
    uGrain:        { value: 0.55 },
    uExposure:     { value: 1.0 },
    uContrast:     { value: 1.06 },
    uSaturation:   { value: 1.08 },
    uLift:         { value: new THREE.Color(0.02, 0.012, 0.03) },
    uGain:         { value: new THREE.Color(1.04, 0.99, 0.94) },
    uShadowTint:   { value: new THREE.Color(0.18, 0.22, 0.42) },
    uHighlightTint:{ value: new THREE.Color(1.06, 0.96, 0.84) },
    uToneMapped:   { value: 0 },
    uHalation:     { value: 0.5 },

    // pressure-wave refraction: xy screen centre, z radius (uv-y units), w strength
    uRipple:       { value: new THREE.Vector4(0.5, 0.5, 0, 0) },
  },

  vertexShader: /* glsl */`
    varying vec2 vUv;
    void main(){
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }`,

  fragmentShader: /* glsl */`
    precision highp float;
    varying vec2 vUv;

    uniform sampler2D tDiffuse;
    uniform sampler2D tDirt;
    uniform float uTime;
    uniform vec2  uResolution;

    uniform vec2  uSunScreen;
    uniform float uSunVisible;
    uniform float uGodRays;
    uniform float uGodDecay;

    uniform vec2  uHeatCenter;
    uniform float uHeatStrength;
    uniform float uHeatRadius;
    uniform vec2  uHeat2Center;
    uniform float uHeat2Strength;

    uniform vec2  uMotion;
    uniform float uMotionAmount;

    uniform float uChroma;
    uniform float uDirt;
    uniform float uVignette;
    uniform float uGrain;
    uniform float uExposure;
    uniform float uContrast;
    uniform float uSaturation;
    uniform vec3  uLift;
    uniform vec3  uGain;
    uniform vec3  uShadowTint;
    uniform vec3  uHighlightTint;
    uniform float uHalation;
    uniform vec4  uRipple;

    ${NOISE_GLSL}

    float luma(vec3 c){ return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

    void main(){
      vec2 uv = vUv;
      float aspect = uResolution.x / max(uResolution.y, 1.0);

      // ── pressure wave ──────────────────────────────────────────────
      // A thin lens ring: the air just inside the front is compressed, so it
      // bends light outward; just behind it, rarefied, inward. That sign flip
      // across the band is what reads as a *wave* rather than a blur.
      if (uRipple.w > 0.001) {
        vec2 d = (uv - uRipple.xy) * vec2(aspect, 1.0);
        float r = length(d);
        float x = (r - uRipple.z) / max(uRipple.z * 0.16 + 0.015, 0.02);
        float lens = x * exp(-x * x * 1.4);
        uv -= (d / max(r, 1e-4)) / vec2(aspect, 1.0) * lens * uRipple.w * 0.03;
      }

      // ── heat distortion ────────────────────────────────────────────
      vec2 heatUv = uv;
      if (uHeatStrength > 0.001) {
        vec2 d = (uv - uHeatCenter) * vec2(aspect, 1.0);
        float m = 1.0 - smoothstep(0.0, uHeatRadius, length(d));
        if (m > 0.0) {
          float n1 = snoise(vec3(uv * 14.0, uTime * 2.4));
          float n2 = snoise(vec3(uv * 34.0 + 7.0, uTime * 4.1));
          vec2 off = vec2(n1, n2) * 0.010 * uHeatStrength * m * m;
          // Rising shimmer: bias upward, because hot air goes up.
          off.y += 0.004 * uHeatStrength * m * n1;
          heatUv += off;
        }
      }
      if (uHeat2Strength > 0.001) {
        vec2 d = (uv - uHeat2Center) * vec2(aspect, 1.0);
        float m = 1.0 - smoothstep(0.0, 0.5, length(d));
        if (m > 0.0) {
          float n1 = snoise(vec3(uv * 9.0, uTime * 1.1));
          float n2 = snoise(vec3(uv * 21.0 + 3.0, uTime * 1.9));
          heatUv += vec2(n1, n2 + 0.6) * 0.006 * uHeat2Strength * m * m;
        }
      }

      // ── chromatic aberration + motion blur, in one gather ──────────
      vec2 fromCenter = heatUv - 0.5;
      float rad = length(fromCenter);
      vec2 caOff = fromCenter * rad * 0.0055 * uChroma;

      vec2 mb = uMotion * uMotionAmount * 0.09;
      float mbLen = min(length(mb), 0.035);
      if (mbLen > 0.0) mb = normalize(mb) * mbLen;

      vec3 col;
      if (uMotionAmount < 0.001 && uChroma < 0.001) {
        col = texture2D(tDiffuse, heatUv).rgb;
      } else {
      col = vec3(0.0);
      const int TAPS = 5;
      float wsum = 0.0;
      for (int i = 0; i < TAPS; i++) {
        float f = (float(i) / float(TAPS - 1)) - 0.5;         // -0.5..0.5
        float w = 1.0 - abs(f) * 0.6;
        vec2 base = heatUv + mb * f;
        col.r += texture2D(tDiffuse, base + caOff).r * w;
        col.g += texture2D(tDiffuse, base).g * w;
        col.b += texture2D(tDiffuse, base - caOff).b * w;
        wsum += w;
      }
      col /= wsum;
      }

      // ── god rays ───────────────────────────────────────────────────
      if (uGodRays > 0.001 && uSunVisible > 0.001) {
        vec2 dir = (uSunScreen - uv);
        float dist = length(dir * vec2(aspect, 1.0));
        vec3 acc = vec3(0.0);
        float w = 1.0;
        float wTot = 0.0;
        vec2 step = dir / 22.0;
        vec2 p = uv;
        for (int i = 0; i < 22; i++) {
          p += step;
          vec3 s = texture2D(tDiffuse, clamp(p, 0.0, 1.0)).rgb;
          // Only bright stuff casts shafts; that's the occlusion test.
          float l = luma(s);
          float mask = smoothstep(1.15, 2.8, l);   // only genuinely blown pixels shaft
          acc += s * mask * w;
          wTot += w;
          w *= uGodDecay;
        }
        acc /= max(wTot, 1e-3);
        float falloff = exp(-dist * 1.6);
        col += acc * uGodRays * uSunVisible * falloff * 1.35;
      }

      // ── lens dirt, energised by the frame's brightness ─────────────
      if (uDirt > 0.001) {
        vec3 grime = texture2D(tDirt, uv * vec2(1.0, 1.0)).rgb;
        float bright = smoothstep(0.55, 1.9, luma(col));
        // Extra kick near the sun.
        float sunProx = 1.0 - smoothstep(0.0, 0.7, length((uv - uSunScreen) * vec2(aspect, 1.0)));
        col += grime * uDirt * (bright * 0.55 + sunProx * uSunVisible * 0.30);
      }

      // ── grade ──────────────────────────────────────────────────────
      //
      // Everything here runs on *linear HDR* — OutputPass does the ACES
      // tonemap + sRGB encode afterwards. That matters enormously for the
      // order of operations below, and getting it wrong is what used to make
      // the whole realm look like it was shot through milk:
      //
      //  · the old lift was "col += uLift * (1 - col) * 0.85" with uLift
      //    around 0.14 *linear*. A linear 0.119 floor on pure black survives
      //    ACES and comes out at roughly 38% grey in the final image, so the
      //    scene had no blacks anywhere — every shadow, every silhouette, the
      //    night sky, all sitting on a grey plateau.
      //  · the old contrast was "(col - 0.18) * c + 0.18", which on HDR values
      //    (a lava vein at 12.0) multiplies the *distance from grey*, blowing
      //    highlights further out while pushing darks negative.
      //
      // Both are now done the way a film pipeline does them: contrast as a
      // gain around middle grey in log2 space (exposure-invariant, never
      // clips, never goes negative), and the shadow floor as a *toe* that
      // only touches the bottom stop or so instead of the whole frame.
      col *= uExposure;
      col = max(col, 0.0);

      // Split tone: rich shadows, warm highlights.
      float l = luma(col);
      float shadowLuma = max(luma(uShadowTint), 0.05);
      vec3 normShadowTint = uShadowTint / shadowLuma;
      vec3 tint = mix(normShadowTint, uHighlightTint, smoothstep(0.0, 0.75, l));
      col *= mix(vec3(1.0), tint, 0.45);

      col *= uGain;

      // Contrast as a log-space gain about middle grey (0.18).
      vec3 logc = log2(max(col, 1e-5) / 0.18) * uContrast;
      col = exp2(logc) * 0.18;

      // Filmic toe: a *small* coloured floor under the darkest values only, so
      // shadows read as deep-but-not-dead rather than as flat grey. exp(-l*30)
      // is ~1 at black and already ~0.05 by the time luma reaches 0.1.
      col += uLift * 0.09 * exp(-luma(col) * 30.0);

      // Saturation.
      l = luma(col);
      col = mix(vec3(l), col, uSaturation);

      // ── vignette ───────────────────────────────────────────────────
      // Real glass falls off much harder than the old 0.28-scaled curve with
      // its 0.65 floor, which was doing almost nothing at the presets' typical
      // uVignette of ~0.2.
      vec2 vq = (uv - 0.5) * vec2(1.0, 1.0);
      float vig = 1.0 - uVignette * 0.85 * pow(length(vq) * 1.32, 2.4);
      col *= clamp(vig, 0.12, 1.0);

      // ── grain ──────────────────────────────────────────────────────
      if (uGrain > 0.001) {
        float g = hash12(uv * uResolution + fract(uTime) * 1000.0) - 0.5;
        float weight = mix(0.5, 0.2, smoothstep(0.0, 0.8, luma(col)));
        col += g * 0.035 * uGrain * weight;
      }

      gl_FragColor = vec4(max(col, 0.0), 1.0);
    }`,
};
