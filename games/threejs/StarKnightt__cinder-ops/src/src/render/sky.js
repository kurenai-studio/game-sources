import * as THREE from 'three';
import { COLORS } from '../core/Constants.js';

/* Sparse cirrus plate — a few horizontal wisps, wrap-safe in U.
 * Sampled once per sky pixel; no noise octaves in the fragment shader. */
function makeCirrusTex() {
  const w = 512, h = 128;
  const data = new Uint8Array(w * h * 4);
  /* v=0 zenith, v=0.5 horizon. Canyon stops look at v~0.20–0.38. */
  const strokes = [
    { u: 0.06, v: 0.24, len: 0.24, thick: 0.028, amp: 0.012, phase: 0.2, gain: 0.95 },
    { u: 0.22, v: 0.30, len: 0.20, thick: 0.022, amp: 0.010, phase: 1.6, gain: 0.80 },
    { u: 0.44, v: 0.22, len: 0.28, thick: 0.026, amp: 0.014, phase: 0.9, gain: 0.88 },
    { u: 0.68, v: 0.28, len: 0.18, thick: 0.020, amp: 0.009, phase: 2.5, gain: 0.70 },
    { u: 0.84, v: 0.34, len: 0.20, thick: 0.024, amp: 0.011, phase: 3.3, gain: 0.78 },
    { u: 0.14, v: 0.38, len: 0.16, thick: 0.018, amp: 0.008, phase: 4.1, gain: 0.60 },
    { u: 0.52, v: 0.36, len: 0.14, thick: 0.016, amp: 0.007, phase: 5.0, gain: 0.52 },
  ];
  for (const s of strokes) {
    const n = 72;
    for (let i = 0; i < n; i++) {
      const t = i / (n - 1);
      const fade = Math.sin(t * Math.PI);
      const uu = s.u + t * s.len;
      const vv = s.v
        + Math.sin(t * 6.3 + s.phase) * s.amp
        + Math.sin(t * 14.0 + s.phase * 0.5) * s.amp * 0.32;
      const x0 = Math.floor(((uu % 1) + 1) % 1 * w);
      const y0 = Math.floor(Math.max(0, Math.min(0.999, vv)) * h);
      const ru = Math.max(2, Math.ceil(s.len * 0.07 * w));
      const rv = Math.max(2, Math.ceil(s.thick * h));
      for (let dy = -rv; dy <= rv; dy++) {
        const y = y0 + dy;
        if (y < 0 || y >= h) continue;
        for (let dx = -ru; dx <= ru; dx++) {
          const x = (x0 + dx + w) % w;
          const du = dx / ru;
          const dv = dy / rv;
          const g = Math.exp(-0.5 * (du * du * 1.6 + dv * dv * 2.8));
          const add = s.gain * fade * g * 255;
          const idx = (y * w + x) * 4;
          data[idx] = Math.min(255, data[idx] + add);
        }
      }
    }
  }
  for (let i = 0; i < w * h; i++) {
    data[i * 4 + 1] = data[i * 4];
    data[i * 4 + 2] = data[i * 4];
    data[i * 4 + 3] = 255;
  }
  const tex = new THREE.DataTexture(data, w, h, THREE.RGBAFormat);
  tex.colorSpace = THREE.NoColorSpace;
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.ClampToEdgeWrapping;
  tex.minFilter = THREE.LinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.generateMipmaps = false;
  tex.needsUpdate = true;
  return tex;
}

const SKY_FS = /* glsl */ `
varying vec3 vDir;
uniform vec3 uZenith;
uniform vec3 uHorizon;
uniform vec3 uMid;
uniform vec3 uSunDir;
uniform vec3 uSunCol;
uniform sampler2D uCirrus;

float sstep(float e0, float e1, float x){
  float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

void main(){
  vec3 d = normalize(vDir);
  vec3 sd = normalize(uSunDir);
  float elev = d.y;

  /* Structured CS2 Italy/Dust gradient. Linear values sit under the
   * pipeline's 2.26 exposure + ACES so zenith stays blue (not paper) and
   * the horizon keeps a warm dust band at similar displayed luma. */
  float hz = sstep(-0.06, 0.10, elev);
  float midT = sstep(0.08, 0.48, elev);
  float zenT = sstep(0.36, 0.94, elev);
  vec3 col = mix(uHorizon * 0.84, uHorizon, hz);
  col = mix(col, uMid, midT);
  col = mix(col, uZenith, zenT);

  /* Tight warm dust sheet right on the roofline — the CS2 horizon haze. */
  float dust = exp(-max(elev, 0.0) * 5.2) * sstep(-0.04, 0.16, elev);
  col = mix(col, vec3(0.92, 0.74, 0.50), dust * 0.46);

  /* Sun-side warmth so the hemisphere isn't a flat wash. */
  vec3 flatD = normalize(vec3(d.x, 0.0, d.z));
  vec3 flatS = normalize(vec3(sd.x, 0.0, sd.z));
  float sunAz = max(0.0, dot(flatD, flatS));
  col *= mix(vec3(1.0), vec3(1.045, 1.016, 0.968), sunAz * 0.28 * sstep(-0.02, 0.28, elev));

  /* Direction-mapped cirrus. Texture only — shader bands read as a
   * flat rectangle across the balcony sun view. */
  float az = atan(d.z, d.x);
  float azU = az * 0.15915494 + 0.5;
  float elV = 0.5 - elev * 0.5;
  float cirrus = texture2D(uCirrus, vec2(azU, elV)).r;
  cirrus *= sstep(0.05, 0.14, elev) * sstep(0.72, 0.48, elev);
  float lit = max(0.0, dot(d, sd));
  vec3 cloudCol = mix(vec3(0.86, 0.88, 0.90), vec3(1.00, 0.93, 0.78), lit);
  col = mix(col, cloudCol, cirrus * 0.28);

  /* Soft atmospheric glare — wide Mie skirt + tighter core, no disk.
   * Kept modest so the balcony sun-view stays blue, not paper. */
  float mu = max(dot(d, sd), 0.0);
  float glare = pow(mu, 8.0) * 0.10 + pow(mu, 28.0) * 0.08 + pow(mu, 90.0) * 0.05;
  col += uSunCol * glare * (0.55 + 0.45 * sstep(-0.04, 0.22, elev));
  col += vec3(1.0, 0.88, 0.64) * sunAz * 0.020 * sstep(0.02, 0.30, elev);

  gl_FragColor = vec4(col, 1.0);
}
`;

const SKY_VS = /* glsl */ `
varying vec3 vDir;
void main(){
  vDir = (modelMatrix * vec4(position, 1.0)).xyz - cameraPosition;
  vec4 p = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  gl_Position = p.xyww;
}
`;

export class DaySky {
  constructor() {
    this.sunDir = new THREE.Vector3(0.84, 0.38, 0.36).normalize();
    this._cirrus = makeCirrusTex();
    const geo = new THREE.SphereGeometry(80, 64, 48);
    this.mat = new THREE.ShaderMaterial({
      vertexShader: SKY_VS,
      fragmentShader: SKY_FS,
      side: THREE.BackSide,
      depthWrite: false,
      depthTest: true,
      fog: false,
      toneMapped: false,
      uniforms: {
        /* Deeper sat blue / warm dust — luma chosen so ACES*2.26 stays
         * near the c32 sky median instead of washing to #c7d6dc. */
        uZenith: { value: new THREE.Color(0x4c70b2) },
        uHorizon: { value: new THREE.Color(0xd0a86a) },
        uMid: { value: new THREE.Color(0x6e9bb8) },
        uSunDir: { value: this.sunDir.clone() },
        uSunCol: { value: new THREE.Color(COLORS.SUN) },
        uCirrus: { value: this._cirrus },
      },
    });
    this.mesh = new THREE.Mesh(geo, this.mat);
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = -1;
    this.mesh.onBeforeRender = (_renderer, _s, camera) => {
      this.mesh.position.copy(camera.position);
      this.mesh.updateMatrixWorld(true);
    };
  }

  attach(scene) {
    scene.add(this.mesh);
  }
}

/** @deprecated keep name for any leftover imports */
export { DaySky as NightSky };
