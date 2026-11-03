import * as THREE from 'three';
import { FS_VERT } from '../gfx/glsl.js';
import { WORLD } from '../core/Constants.js';

const COMP_FS = /* glsl */ `
varying vec2 vUv;
uniform sampler2D tScene;
uniform sampler2D tDepth;
uniform float uExposure;
uniform float uTime;
uniform float uVignette;
uniform vec3 uLift;
uniform vec3 uGain;
uniform vec2 uResolution;
uniform vec2 uNearFar;
uniform mat4 uInvProj;
uniform mat4 uInvView;
uniform vec3 uFogColor;

float sstep(float e0, float e1, float x){
  float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

vec3 aces(vec3 x){
  const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

float viewZ(float depth){
  return (uNearFar.x * uNearFar.y) / ((uNearFar.y - uNearFar.x) * depth - uNearFar.y);
}

vec3 viewPos(vec2 uv, float depth){
  vec4 p = uInvProj * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
  return p.xyz / p.w;
}

vec3 brightOf(vec3 hdr){
  float b = max(hdr.r, max(hdr.g, hdr.b));
  /* Red-dominant pixels (taillight lenses) bloom below the sun threshold
   * so a 4x emissive lens pops without dropping the global knee. */
  float redDom = sstep(0.10, 0.38, hdr.r - max(hdr.g, hdr.b));
  float thr = mix(0.85, 0.38, redDom);
  float knee = mix(0.55, 0.28, redDom);
  float soft = clamp(b - thr + knee, 0.0, 2.0 * knee);
  soft = soft * soft / (4.0 * knee + 1e-4);
  float w = max(soft, b - thr) / max(b, 1e-4);
  return hdr * clamp(w, 0.0, 1.0) * mix(1.0, 1.55, redDom);
}

float hash12(vec2 p){
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float gtao(vec2 uv, float depth, vec3 vp){
  vec3 n = normalize(cross(dFdx(vp), dFdy(vp)));
  if (dot(n, n) < 0.01) return 1.0;
  float acc = 0.0;
  float wsum = 0.0;
  float px = 1.0 / max(uResolution.x, 1.0);
  vec2 spiral[8];
  spiral[0] = vec2( 1.0,  0.2);
  spiral[1] = vec2(-0.7,  0.8);
  spiral[2] = vec2(-0.4, -1.0);
  spiral[3] = vec2( 0.9, -0.6);
  spiral[4] = vec2( 0.2,  1.1);
  spiral[5] = vec2(-1.1, -0.1);
  spiral[6] = vec2( 0.6, -1.0);
  spiral[7] = vec2(-0.3,  0.7);
  /* Tight kernel — 6–14 px was airbrushing every sun-shadow edge. */
  float rad = mix(2.2, 4.5, clamp(-vp.z / 28.0, 0.0, 1.0));
#ifdef COMP_FAST
  for (int i = 0; i < 4; i++){
#else
  for (int i = 0; i < 8; i++){
#endif
    vec2 suv = uv + spiral[i] * rad * px;
    float sd = texture2D(tDepth, suv).x;
    if (sd > 0.9994) continue;
    vec3 sp = viewPos(suv, sd);
    vec3 v = sp - vp;
    float dist = length(v);
    float occ = max(0.0, dot(n, v) / (dist + 0.012));
    float fall = 1.0 / (1.0 + dist * 0.42);
    acc += occ * fall;
    wsum += fall;
  }
  float raw = wsum > 0.0 ? acc / wsum : 0.0;
  return mix(1.0, 1.0 - clamp(raw * 1.85, 0.0, 0.62), 0.98);
}

void main(){
  vec3 scene = texture2D(tScene, vUv).rgb;
  float depth = texture2D(tDepth, vUv).x;
  float isSky = sstep(0.996, 0.9996, depth);
  vec3 vp = viewPos(vUv, depth);
  vec3 wp = (uInvView * vec4(vp, 1.0)).xyz;
  float z = max(0.0, -viewZ(depth));

  float occ = 1.0;
  if (isSky < 0.5 && z > 0.28) occ = gtao(vUv, depth, vp);
  float groundW = sstep(1.6, 0.12, wp.y) * (1.0 - isSky);
  occ = mix(occ, occ * occ, groundW * 0.18);
  scene *= mix(0.76, 1.0, occ);

  vec3 hdr = scene * uExposure;

  /* Milky warm distance haze: geometry past ~30m loses contrast so far
   * walls sit back like CS2 mid fog (fix 8). */
  float distFog = 1.0 - exp(-z * 0.0165);
  float hLow = exp(-max(wp.y - 0.04, 0.0) * 0.048);
  float fog = distFog * mix(0.36, 0.80, hLow);
  fog = min(fog, 0.66) * (1.0 - isSky) * smoothstep(10.0, 34.0, z);
  float farHaze = sstep(34.0, 80.0, z) * (1.0 - isSky);
  vec3 hazeCol = mix(uFogColor, vec3(0.93, 0.87, 0.74), 0.48);
  float sat = mix(1.0, 0.38, smoothstep(30.0, 70.0, z) * (1.0 - isSky));
  float lumaH = dot(hdr, vec3(0.2126, 0.7152, 0.0722));
  hdr = mix(vec3(lumaH), hdr, sat);
  hdr = mix(hdr, hazeCol, min(0.80, fog + farHaze * 0.38));

  vec2 px = 1.0 / max(uResolution, vec2(1.0));
  vec3 bloom = vec3(0.0);
  bloom += brightOf(texture2D(tScene, vUv + vec2( 2.0, 0.0) * px).rgb * uExposure);
  bloom += brightOf(texture2D(tScene, vUv + vec2(-2.0, 0.0) * px).rgb * uExposure);
  bloom += brightOf(texture2D(tScene, vUv + vec2( 0.0, 2.0) * px).rgb * uExposure);
  bloom += brightOf(texture2D(tScene, vUv + vec2( 0.0,-2.0) * px).rgb * uExposure);
  bloom += brightOf(texture2D(tScene, vUv + vec2( 4.0, 4.0) * px).rgb * uExposure) * 0.55;
  bloom += brightOf(texture2D(tScene, vUv + vec2(-4.0, 4.0) * px).rgb * uExposure) * 0.55;
  bloom += brightOf(texture2D(tScene, vUv + vec2( 4.0,-4.0) * px).rgb * uExposure) * 0.55;
  bloom += brightOf(texture2D(tScene, vUv + vec2(-4.0,-4.0) * px).rgb * uExposure) * 0.55;
#ifndef COMP_FAST
  bloom += brightOf(texture2D(tScene, vUv + vec2( 8.0, 0.0) * px).rgb * uExposure) * 0.32;
  bloom += brightOf(texture2D(tScene, vUv + vec2(-8.0, 0.0) * px).rgb * uExposure) * 0.32;
  bloom += brightOf(texture2D(tScene, vUv + vec2( 0.0, 8.0) * px).rgb * uExposure) * 0.32;
  bloom += brightOf(texture2D(tScene, vUv + vec2( 0.0,-8.0) * px).rgb * uExposure) * 0.32;
  bloom += brightOf(texture2D(tScene, vUv + vec2( 14.0, 0.0) * px).rgb * uExposure) * 0.16;
  bloom += brightOf(texture2D(tScene, vUv + vec2(-14.0, 0.0) * px).rgb * uExposure) * 0.16;
#endif
  hdr += bloom * 0.016;

  float pk = max(hdr.r, max(hdr.g, hdr.b));
  /* c25/c26: the old 1.05 knee pinned every lit plaster pixel under 220.
   * Start later and compress less so sunlit Italy plaster can reach 230. */
  float shoulder = mix(1.0, 1.22 / max(pk, 1.22), smoothstep(1.75, 3.20, pk) * 0.40);
  hdr *= mix(shoulder, 1.0, isSky * 0.28);

  vec3 col = aces(hdr);
  col = pow(max(col, 0.0), vec3(0.990, 1.000, 1.028));
  float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
  float shadowW = 1.0 - sstep(0.022, 0.26, luma);
  float midW = sstep(0.035, 0.18, luma) * (1.0 - sstep(0.38, 0.74, luma));
  col += uLift * shadowW;
  col *= mix(vec3(1.0), uGain, 0.22 + midW * 0.68);

  float r = length(vUv - 0.5);
  col *= 1.0 - uVignette * r * r;

  vec2 gp = vUv * uResolution + vec2(uTime * 37.0, uTime * 19.0);
  float grain = hash12(gp) + hash12(gp + 17.3) - 1.0;
  col += grain * 0.006 * (1.0 - smoothstep(0.62, 0.95, luma));

  float lumaR = dot(texture2D(tScene, vUv + vec2(px.x, 0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
  float lumaD = dot(texture2D(tScene, vUv + vec2(0.0, px.y)).rgb, vec3(0.2126, 0.7152, 0.0722));
  float edge = clamp(abs(luma - lumaR) + abs(luma - lumaD), 0.0, 1.0);
  vec3 nbor = (
    aces(texture2D(tScene, vUv + vec2( px.x, 0.0)).rgb * uExposure) +
    aces(texture2D(tScene, vUv + vec2(-px.x, 0.0)).rgb * uExposure) +
    aces(texture2D(tScene, vUv + vec2(0.0,  px.y)).rgb * uExposure) +
    aces(texture2D(tScene, vUv + vec2(0.0, -px.y)).rgb * uExposure)
  ) * 0.25;
  /* c24: 0.18 was airbrushing every sun-shadow edge. Keep a hair of AA. */
  col = mix(col, nbor, edge * 0.045);

  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
`;

export class Pipeline {
  constructor(renderer, quality = {}) {
    this.renderer = renderer;
    const samples = quality.msaa ?? 4;
    this._allocTarget(1, 1, samples);
    this.scene = new THREE.Scene();
    this.cam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    this.uniforms = {
      tScene: { value: this.target.texture },
      tDepth: { value: this.target.depthTexture },
      uExposure: { value: 2.26 },
      uTime: { value: 0 },
      uVignette: { value: 0.04 },
      /* Dusty luminous lift — c25 0.048 left shadowed plaster as a hole. */
      uLift: { value: new THREE.Vector3(0.092, 0.078, 0.056) },
      uGain: { value: new THREE.Vector3(1.055, 1.032, 0.995) },
      uResolution: { value: new THREE.Vector2(1, 1) },
      uNearFar: { value: new THREE.Vector2(0.04, 220) },
      uInvProj: { value: new THREE.Matrix4() },
      uInvView: { value: new THREE.Matrix4() },
      uFogColor: { value: new THREE.Color(WORLD.FOG_COLOR) },
    };
    this.compMat = new THREE.ShaderMaterial({
      vertexShader: FS_VERT,
      fragmentShader: COMP_FS,
      defines: quality.fast ? { COMP_FAST: '' } : {},
      uniforms: this.uniforms,
      depthTest: false,
      depthWrite: false,
      toneMapped: false,
      fog: false,
    });
    this.quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), this.compMat);
    this.quad.frustumCulled = false;
    this.scene.add(this.quad);
  }

  _allocTarget(w, h, samples) {
    if (this.target) {
      const oldDepth = this.target.depthTexture;
      this.target.dispose();
      oldDepth?.dispose();
    }
    const depth = new THREE.DepthTexture();
    depth.format = THREE.DepthFormat;
    depth.type = THREE.UnsignedIntType;
    depth.minFilter = THREE.NearestFilter;
    depth.magFilter = THREE.NearestFilter;
    this.target = new THREE.WebGLRenderTarget(w, h, {
      type: THREE.HalfFloatType,
      samples,
      depthBuffer: true,
      depthTexture: depth,
    });
    this.target.texture.minFilter = THREE.LinearFilter;
    this.target.texture.magFilter = THREE.LinearFilter;
    this._msaa = samples;
    if (this.uniforms) {
      this.uniforms.tScene.value = this.target.texture;
      this.uniforms.tDepth.value = depth;
    }
  }

  setQuality({ msaa, fast } = {}) {
    const wantFast = !!fast;
    const isFast = Object.prototype.hasOwnProperty.call(this.compMat.defines, 'COMP_FAST');
    if (wantFast !== isFast) {
      if (wantFast) this.compMat.defines.COMP_FAST = '';
      else delete this.compMat.defines.COMP_FAST;
      this.compMat.needsUpdate = true;
    }
    if (msaa != null && msaa !== this._msaa) {
      this._allocTarget(this.target.width, this.target.height, msaa);
    }
  }

  resize(w, h) {
    this.target.setSize(w, h);
    this.uniforms.uResolution.value.set(w, h);
  }

  render(world, camera, time) {
    const r = this.renderer;
    const prevTM = r.toneMapping;
    r.toneMapping = THREE.NoToneMapping;
    this.uniforms.uInvProj.value.copy(camera.projectionMatrixInverse);
    this.uniforms.uInvView.value.copy(camera.matrixWorld);
    this.uniforms.uNearFar.value.set(camera.near, camera.far);
    r.setRenderTarget(this.target);
    r.render(world, camera);
    this._calls = r.info.render.calls;
    this._tris = r.info.render.triangles;
    r.setRenderTarget(null);
    this.uniforms.uTime.value = time;
    r.autoClear = true;
    r.render(this.scene, this.cam);
    r.toneMapping = prevTM;
  }

  dispose() {
    this.target.depthTexture?.dispose();
    this.target.dispose();
    this.compMat.dispose();
    this.quad.geometry.dispose();
  }
}
