/**
 * Procedural sky dome.
 *
 * A single inward-facing sphere carrying an analytic atmosphere: Rayleigh-ish
 * zenith→horizon gradient, a sun disc with forward-scatter halo, two drifting
 * fbm cloud decks with cheap silver-lining, stars that fade in as the sun sets,
 * and — the signature of this realm — an ember glow that bleeds up out of the
 * caldera and stains the underside of the clouds.
 *
 * The same dome is re-rendered into a PMREM cubemap for image-based lighting,
 * so ambient light always agrees with what you can see.
 */
import * as THREE from 'three';
import { cloudNoise } from '../materials/CloudNoise.js';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';

const vert = /* glsl */`
varying vec3 vDir;
void main(){
  vDir = normalize(position);
  vec4 mv = modelViewMatrix * vec4(position, 1.0);
  gl_Position = projectionMatrix * mv;
}`;

const frag = /* glsl */`
precision highp float;
varying vec3 vDir;

uniform float uTime;
uniform vec3  uSunDir;
uniform vec3  uSunColor;
uniform float uSunIntensity;
uniform vec3  uZenith;
uniform vec3  uHorizon;
uniform vec3  uGround;
uniform float uCloudCover;    // 0..1
uniform float uCloudSharp;
uniform vec3  uCloudColor;
uniform vec3  uCloudShadow;
uniform float uStars;
uniform vec3  uEmberDir;      // direction of the caldera from origin
uniform float uEmberGlow;
uniform vec3  uEmberColor;
uniform float uHaze;
uniform vec2  uWindDir;
uniform float uMoon;
uniform sampler2D uCloudNoise;

${NOISE_GLSL}

float cloudDeck(vec3 d, float h, float scale, float speed, float oct){
  // Project the ray onto a flat deck at height h — proper perspective on clouds.
  float t = h / max(d.y, 0.045);
  vec3 p = d * t;
  vec2 uv = p.xz * scale + uWindDir * uTime * speed;
  float n = texture2D(uCloudNoise, uv * 0.25 + vec2(uTime * 0.0006, 0.0)).r;
  n += 0.22 * texture2D(uCloudNoise, uv * 0.925 - vec2(0.0, uTime * 0.001)).r;
  return n;
}

void main(){
  vec3 d = normalize(vDir);
  float up = clamp(d.y, -1.0, 1.0);

  // ── base atmosphere ────────────────────────────────────────────────
  float g = pow(clamp(1.0 - abs(up), 0.0, 1.0), 3.2);
  vec3 sky = mix(uZenith, uHorizon, g);
  sky = mix(sky, uGround, smoothstep(0.0, -0.16, up));

  // ── sun ────────────────────────────────────────────────────────────
  float sd = max(dot(d, uSunDir), 0.0);
  float disc = smoothstep(0.9986, 0.99955, sd);
  float halo = pow(sd, 900.0) * 0.6 + pow(sd, 64.0) * 0.30 + pow(sd, 8.0) * 0.11;
  float sunLow = smoothstep(0.30, -0.06, uSunDir.y);           // horizon golden warming
  vec3 sunTint = mix(uSunColor, uSunColor * vec3(1.08, 0.85, 0.62), sunLow);
  sky += sunTint * halo * uSunIntensity;
  sky += sunTint * disc * uSunIntensity * 22.0;

  // Mie-ish forward scatter smeared along the horizon.
  sky += sunTint * pow(sd, 3.5) * g * 0.22 * uSunIntensity;

  // ── moon (night only) ──────────────────────────────────────────────
  if (uMoon > 0.001) {
    vec3 md = normalize(-uSunDir + vec3(0.12, 0.28, 0.05));
    float mdd = max(dot(d, md), 0.0);
    float mdisc = smoothstep(0.99938, 0.99972, mdd);
    // crescent bite
    float bite = smoothstep(0.99930, 0.99985, max(dot(d, normalize(md + vec3(0.010, 0.006, 0.0))), 0.0));
    sky += vec3(0.72, 0.78, 0.95) * uMoon * (mdisc * 6.0 - bite * 2.4);
    sky += vec3(0.30, 0.40, 0.62) * uMoon * (pow(mdd, 240.0) * 0.5 + pow(mdd, 18.0) * 0.09);
  }

  // ── stars ──────────────────────────────────────────────────────────
  if (uStars > 0.002 && up > -0.02) {
    vec2 sc = d.xz / max(abs(d.y) + 0.22, 0.05);
    float cell = hash12(floor(sc * 220.0));
    float star = step(0.9975, cell) * (0.4 + 0.6 * hash12(floor(sc * 220.0) + 7.3));
    float twinkle = 0.55 + 0.45 * sin(uTime * (2.0 + cell * 9.0) + cell * 64.0);
    // Milky band
    float band = exp(-pow((d.y - 0.25 + 0.4 * d.x) * 3.4, 2.0)) * 0.055;
    sky += (vec3(0.85, 0.9, 1.0) * star * twinkle * 2.2 + vec3(0.5, 0.55, 0.8) * band)
         * uStars * smoothstep(-0.02, 0.12, up);
  }

  // ── cloud decks ────────────────────────────────────────────────────
  if (d.y > 0.005) {
    float lowN  = cloudDeck(d, 0.55, 0.85, 0.010, 5.0);
    float highN = cloudDeck(d, 1.60, 0.32, 0.004, 4.0);

    float lowT  = smoothstep(1.0 - uCloudCover, 1.0 - uCloudCover + uCloudSharp, lowN);
    float highT = smoothstep(1.02 - uCloudCover * 0.75, 1.30 - uCloudCover * 0.5, highN);

    float fadeH = smoothstep(0.02, 0.20, d.y);
    lowT  *= fadeH;
    highT *= smoothstep(0.05, 0.28, d.y);

    // Lighting: sun behind the cloud → silver rim; sun above → lit top.
    float back = pow(max(dot(d, uSunDir), 0.0), 5.0);
    vec3 lit   = mix(uCloudShadow, uCloudColor, clamp(lowN * 1.3, 0.0, 1.0));
    lit += sunTint * back * 1.5;
    // Ember uplight on the belly of the clouds.
    float emberFacing = pow(max(dot(normalize(d + vec3(0.0, -0.35, 0.0)), uEmberDir), 0.0), 2.0);
    lit += uEmberColor * uEmberGlow * (0.35 + emberFacing * 0.9) * (1.0 - back * 0.4);

    vec3 hi = mix(uCloudShadow * 1.25, uCloudColor * 1.08, clamp(highN * 1.4, 0.0, 1.0))
            + sunTint * back * 0.7;

    sky = mix(sky, hi,  highT * 0.55);
    sky = mix(sky, lit, lowT  * 0.95);
  }

  // ── volcanic glow rising off the caldera ───────────────────────────
  float e = pow(max(dot(d, uEmberDir), 0.0), 8.0);   // tight, or it stains the whole dome
  float lowBias = smoothstep(0.55, -0.02, d.y);
  float churn = fbm(vec3(d.xz * 3.2, uTime * 0.06), 3) * 0.5 + 0.5;
  sky += uEmberColor * uEmberGlow * e * lowBias * (0.55 + churn * 0.85) * 0.95;

  // ── horizon haze ───────────────────────────────────────────────────
  sky = mix(sky, uHorizon * 1.06, uHaze * pow(clamp(1.0 - abs(up) * 1.7, 0.0, 1.0), 2.0));

  gl_FragColor = vec4(max(sky, 0.0), 1.0);
}`;

export class Sky {
  constructor(renderer, { radius = 9000, envResolution = 256 } = {}) {
    this.renderer = renderer;

    this.uniforms = {
      uTime:         { value: 0 },
      uSunDir:       { value: new THREE.Vector3(0.4, 0.3, -0.86).normalize() },
      uSunColor:     { value: new THREE.Color(0xffb066) },
      uSunIntensity: { value: 1.0 },
      uZenith:       { value: new THREE.Color(0x1d2b52) },
      uHorizon:      { value: new THREE.Color(0xd8763a) },
      uGround:       { value: new THREE.Color(0x180f10) },
      uCloudCover:   { value: 0.5 },
      uCloudSharp:   { value: 0.26 },
      uCloudColor:   { value: new THREE.Color(0xffd0a0) },
      uCloudShadow:  { value: new THREE.Color(0x2b2333) },
      uStars:        { value: 0.0 },
      uEmberDir:     { value: new THREE.Vector3(-0.5, 0.22, -0.84).normalize() },
      uEmberGlow:    { value: 0.55 },
      uEmberColor:   { value: new THREE.Color(0xff5a18) },
      uHaze:         { value: 0.35 },
      uWindDir:      { value: new THREE.Vector2(0.8, 0.6) },
      uMoon:         { value: 0.0 },
      uCloudNoise:   { value: cloudNoise() },
    };

    this.material = new THREE.ShaderMaterial({
      vertexShader: vert,
      fragmentShader: frag,
      uniforms: this.uniforms,
      side: THREE.BackSide,
      depthWrite: false,
      depthTest: false,
      fog: false,
      toneMapped: true,
    });

    this.mesh = new THREE.Mesh(new THREE.SphereGeometry(radius, 64, 40), this.material);
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = -1000;
    this.mesh.name = 'SkyDome';

    // ── IBL ──────────────────────────────────────────────────────────
    this.pmrem = new THREE.PMREMGenerator(renderer);
    this.pmrem.compileEquirectangularShader();
    this._envScene = new THREE.Scene();
    this._envDome = new THREE.Mesh(new THREE.SphereGeometry(100, 32, 20), this.material);
    this._envDome.frustumCulled = false;
    this._envScene.add(this._envDome);
    this._envRT = null;
    this._envDirty = true;
    this._envCooldown = 0;
    this.envResolution = envResolution;
  }

  get envMap() { return this._envRT?.texture ?? null; }

  markEnvDirty() { this._envDirty = true; }

  /** Rebuild the PMREM from the live sky. ~4ms at 256 — we throttle it hard. */
  updateEnvironment(force = false) {
    if (!force && (!this._envDirty || this._envCooldown > 0)) return this.envMap;
    this._envDirty = false;
    this._envCooldown = 0.45;

    const prev = this._envRT;
    this._envRT = this.pmrem.fromScene(this._envScene, 0.02, 1, 400);
    prev?.dispose();
    return this.envMap;
  }

  update(dt, elapsed) {
    this.uniforms.uTime.value = elapsed;
    this._envCooldown = Math.max(0, this._envCooldown - dt);
  }

  dispose() {
    this.mesh.geometry.dispose();
    this._envDome.geometry.dispose();
    this.material.dispose();
    this._envRT?.dispose();
    this.pmrem.dispose();
  }
}
