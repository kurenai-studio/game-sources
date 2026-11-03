/**
 * Cloud layer + ground fog banks.
 *
 * Two complementary tricks, because neither alone is convincing:
 *
 *  · Clouds — large camera-facing billboards on two decks, each shaded by a
 *    procedural fbm "puff" with a directional light term, so they have a lit
 *    top and a shadowed base and read as volume when you fly through them.
 *  · Fog banks — huge horizontal quads at low altitude with soft edges and a
 *    scrolling noise mask, giving the valleys that layered inversion look
 *    without paying for real volumetrics.
 *
 * The fragment shader softens the depth intersection (the classic "soft
 * particles" trick using the depth buffer would be better, but this keeps us off
 * an extra depth pass; instead we fade by view-space distance to camera).
 */
import * as THREE from 'three';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';
import { cloudNoise } from '../materials/CloudNoise.js';
import { G } from '../materials/GlobalUniforms.js';
import { WORLD } from '../world/Heightfield.js';
import { TAU } from '../utils/MathX.js';

const cloudVert = /* glsl */`
attribute vec3  aCenter;
attribute vec2  aSize;
attribute float aSeed;
attribute float aDeck;

varying vec2  vUvC;
varying float vSeed;
varying float vDeck;
varying vec3  vWPos;
varying float vDist;

uniform float uTime;
uniform vec2  uWindDir;
uniform float uWindStrength;
uniform vec3  uCameraPos;
uniform vec3  uCamRight;    // camera's horizontal right axis — see below
uniform float uSpan;

void main(){
  vUvC = uv;
  vSeed = aSeed;
  vDeck = aDeck;

  // Drift and wrap in a big cell around the camera (clouds are everywhere).
  vec3 c = aCenter;
  c.xz += uWindDir * uTime * (2.2 + aDeck * 3.5) * (0.3 + uWindStrength);
  vec2 rel = c.xz - uCameraPos.xz;
  rel = mod(rel + uSpan, uSpan * 2.0) - uSpan;
  c.xz = uCameraPos.xz + rel;

  // Y-locked billboard, oriented from the CAMERA's own horizontal facing —
  // not from each instance's direction to the camera. That per-instance
  // version normalize()s (cloudCenter - cameraPos) flattened to XZ, which goes
  // to zero-length (and the billboard axis to noise) for any cloud sitting
  // near-directly overhead — exactly what standing still and looking up does.
  // One shared right-axis for the whole draw call sidesteps the singularity
  // entirely: it only degenerates if the camera itself looks exactly along
  // world-up, at which point every billboard is broken identically anyway,
  // rather than one at a time turning into a knife-edge streak.
  vec3 right = uCamRight;
  vec3 up = vec3(0.0, 1.0, 0.0);

  vec3 world = c + right * position.x * aSize.x + up * position.y * aSize.y;
  vWPos = world;
  vec4 mv = viewMatrix * vec4(world, 1.0);
  vDist = -mv.z;
  gl_Position = projectionMatrix * mv;
}`;

const cloudFrag = /* glsl */`
precision highp float;
varying vec2  vUvC;
varying float vSeed;
varying float vDeck;
varying vec3  vWPos;
varying float vDist;

uniform float uTime;
uniform vec3  uSunDir;
uniform vec3  uSunColor;
uniform vec3  uShadowColor;
uniform vec3  uEmberColor;
uniform float uEmberGlow;
uniform float uOpacity;
uniform float uSoft;
uniform sampler2D uCloudNoise;

${NOISE_GLSL}

void main(){
  vec2 uv = vUvC * 2.0 - 1.0;

  // Puff density: a soft ellipse eroded by fbm that evolves slowly.
  float base = 1.0 - length(vec2(uv.x * 0.74, uv.y * 1.45));
  float n = texture2D(uCloudNoise, vUvC * 1.15 + vSeed * 3.7 + vec2(uTime * 0.002, 0.0)).r * 2.0 - 1.0;
  float detail = texture2D(uCloudNoise, vUvC * 2.62 + vSeed * 2.3 - vec2(0.0, uTime * 0.003)).r * 2.0 - 1.0;
  float d = base + n * 0.48 + detail * 0.18 - 0.18;
  float density = smoothstep(0.14, 0.68, d);
  if (density < 0.01) discard;

  // Lighting: the sun comes through the thin edges, the core is in shadow.
  float thick = smoothstep(0.0, 0.9, d);
  float sunUp = clamp(uSunDir.y * 1.6 + 0.25, 0.0, 1.0);
  // Vertical gradient — lit crown, dark belly.
  float vgrad = smoothstep(-0.9, 0.8, uv.y);
  vec3 lit = mix(uShadowColor, uSunColor, vgrad * (0.35 + sunUp * 0.75));
  // Rim scatter where the cloud is thin.
  lit += uSunColor * (1.0 - thick) * 0.85 * (0.25 + sunUp);
  // Ember uplight from the caldera.
  lit += uEmberColor * uEmberGlow * (1.0 - vgrad) * 0.75;

  float feather = 1.0 - smoothstep(0.62, 1.12, length(vec2(uv.x * 0.9, uv.y * 1.1)));
  float a = pow(density, 1.35) * feather * uOpacity * 0.72 * (0.55 + 0.45 * (1.0 - vDeck));
  // Fade near the camera so you can fly through without a hard pop.
  a *= smoothstep(0.0, uSoft, vDist);

  gl_FragColor = vec4(lit, a);
}`;

function buildBillboards(count, { yRange, sizeRange, span, deck }) {
  const quad = new THREE.PlaneGeometry(1, 1);
  const geo = new THREE.InstancedBufferGeometry();
  geo.index = quad.index;
  geo.attributes.position = quad.attributes.position;
  geo.attributes.uv = quad.attributes.uv;
  geo.attributes.normal = quad.attributes.normal;

  const center = new Float32Array(count * 3);
  const size = new Float32Array(count * 2);
  const seed = new Float32Array(count);
  const deckA = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    center[i * 3] = (Math.random() * 2 - 1) * span;
    center[i * 3 + 1] = yRange[0] + Math.random() * (yRange[1] - yRange[0]);
    center[i * 3 + 2] = (Math.random() * 2 - 1) * span;
    const w = sizeRange[0] + Math.random() * (sizeRange[1] - sizeRange[0]);
    size[i * 2] = w;
    size[i * 2 + 1] = w * (0.34 + Math.random() * 0.30);
    seed[i] = Math.random();
    deckA[i] = deck;
  }
  geo.setAttribute('aCenter', new THREE.InstancedBufferAttribute(center, 3));
  geo.setAttribute('aSize', new THREE.InstancedBufferAttribute(size, 2));
  geo.setAttribute('aSeed', new THREE.InstancedBufferAttribute(seed, 1));
  geo.setAttribute('aDeck', new THREE.InstancedBufferAttribute(deckA, 1));
  geo.instanceCount = count;
  quad.dispose();
  return geo;
}

export class Clouds {
  constructor(settings) {
    this.group = new THREE.Group();
    this.group.name = 'Clouds';
    this.layers = [];

    const decks = [
      { count: Math.round(settings.cloudCount * 0.55), yRange: [420, 620], sizeRange: [420, 900], span: 2200, deck: 0, soft: 140 },
      { count: Math.round(settings.cloudCount * 0.45), yRange: [760, 1150], sizeRange: [700, 1500], span: 3000, deck: 1, soft: 260 },
    ];

    for (const d of decks) {
      const geo = buildBillboards(d.count, d);
      const mat = new THREE.ShaderMaterial({
        vertexShader: cloudVert, fragmentShader: cloudFrag,
        uniforms: {
          uTime: G.uTime,
        uCloudNoise: { value: cloudNoise() },
          uWindDir: G.uWindDir,
          uWindStrength: G.uWindStrength,
          uSunDir: G.uSunDir,
          uSunColor: { value: new THREE.Color(0xffd0a0) },
          uShadowColor: { value: new THREE.Color(0x3b3546) },
          uEmberColor: { value: new THREE.Color(0xff5a18) },
          uEmberGlow: { value: 0.35 },
          uCameraPos: { value: new THREE.Vector3() },
          uCamRight: { value: new THREE.Vector3(1, 0, 0) },
          uSpan: { value: d.span },
          uOpacity: { value: 0.62 },
          uSoft: { value: d.soft },
        },
        transparent: true, depthWrite: false, side: THREE.DoubleSide,
      });
      const mesh = new THREE.Mesh(geo, mat);
      mesh.frustumCulled = false;
      mesh.renderOrder = 5;
      this.group.add(mesh);
      this.layers.push(mesh);
    }

    // ── ground fog banks ────────────────────────────────────────────
    this.fog = this._buildFogBanks(settings);
    this.group.add(this.fog);
  }

  /**
   * Ground fog.
   *
   * These used to be large horizontal planes. Don't do that: a plane at the
   * camera's own altitude slices through the frustum and reads as a hard grey
   * rectangle across the frame — which is exactly what it looked like. Ground
   * fog has to be camera-facing billboards with a long near-fade, same as the
   * decks above, just low, wide and squashed flat.
   */
  _buildFogBanks(settings) {
    const g = new THREE.Group();
    g.name = 'FogBanks';

    const count = Math.max(10, Math.round(settings.cloudCount * 0.5));
    const geo = buildBillboards(count, {
      yRange: [14, 96], sizeRange: [520, 1250], span: 1500, deck: 0,
    });
    // Squash: ground fog is a sheet, not a puff.
    const sz = geo.attributes.aSize;
    for (let i = 0; i < sz.count; i++) sz.setY(i, sz.getX(i) * 0.085);
    sz.needsUpdate = true;

    const mat = new THREE.ShaderMaterial({
      vertexShader: cloudVert, fragmentShader: cloudFrag,
      uniforms: {
        uTime: G.uTime,
        uCloudNoise: { value: cloudNoise() },
        uWindDir: G.uWindDir,
        uWindStrength: G.uWindStrength,
        uSunDir: G.uSunDir,
        uSunColor: { value: new THREE.Color(0xb4bcc8) },
        uShadowColor: { value: new THREE.Color(0x6a7080) },
        uEmberColor: { value: new THREE.Color(0xff6a22) },
        uEmberGlow: { value: 0.18 },
        uCameraPos: { value: new THREE.Vector3() },
        uCamRight: { value: new THREE.Vector3(1, 0, 0) },
        uSpan: { value: 1500 },
        uOpacity: { value: 0.16 },
        uSoft: { value: 230 },
      },
      transparent: true, depthWrite: false, side: THREE.DoubleSide,
    });
    this.fogMaterial = mat;

    const mesh = new THREE.Mesh(geo, mat);
    mesh.frustumCulled = false;
    mesh.renderOrder = 4;
    g.add(mesh);
    this.fogMesh = mesh;
    return g;
  }

  setMood({ cloudOpacity, sunColor, shadowColor, emberGlow, fogOpacity, fogColor }) {
    for (const l of this.layers) {
      const u = l.material.uniforms;
      if (cloudOpacity != null) u.uOpacity.value = cloudOpacity;
      if (sunColor) u.uSunColor.value.set(sunColor);
      if (shadowColor) u.uShadowColor.value.set(shadowColor);
      if (emberGlow != null) u.uEmberGlow.value = emberGlow;
    }
    const f = this.fogMaterial.uniforms;
    if (fogOpacity != null) f.uOpacity.value = fogOpacity;
    if (fogColor) {
      f.uSunColor.value.set(fogColor);
      f.uShadowColor.value.set(fogColor).multiplyScalar(0.62);
    }
    if (emberGlow != null) f.uEmberGlow.value = emberGlow * 0.35;
  }

  update(dt, camera) {
    // One right-axis, derived from the camera's actual horizontal facing,
    // shared by every billboard this frame — see the vertex shader comment.
    camera.getWorldDirection(this._camFwd ?? (this._camFwd = new THREE.Vector3()));
    const fwd = this._camFwd;
    const right = (this._camRight ?? (this._camRight = new THREE.Vector3()));
    right.crossVectors(fwd, new THREE.Vector3(0, 1, 0));
    // Camera pointed (near-)exactly straight up/down: fall back to a fixed
    // axis rather than propagating a zero-length cross product.
    right.set(right.x, 0, right.z);
    if (right.lengthSq() < 1e-8) right.set(1, 0, 0);
    else right.normalize();

    for (const l of this.layers) {
      l.material.uniforms.uCameraPos.value.copy(camera.position);
      l.material.uniforms.uCamRight.value.copy(right);
    }
    this.fogMaterial.uniforms.uCameraPos.value.copy(camera.position);
    this.fogMaterial.uniforms.uCamRight.value.copy(right);
  }

  dispose() {
    for (const l of this.layers) { l.geometry.dispose(); l.material.dispose(); }
  }
}
