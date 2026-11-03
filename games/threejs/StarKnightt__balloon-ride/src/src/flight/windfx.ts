/**
 * The wind made visible round the camera: dandelion fluff (soft pale tufts that turn slowly) and
 * tiny motes that catch the low sun. Each drifts with the wind of its own altitude plus a little
 * swirl, so a climb or a sink streams them past, and the veer between layers shears them. They live
 * in a box that wraps round the camera, so there are always some in view and never too many.
 */
import * as THREE from "three";
import { COMMON, G } from "../render/materials";
import { mulberry32, range } from "../core/rng";
import { windAt } from "./wind";

const N = 260;
const BOX = 36; // half size (m) of the wrap box round the camera

const VS = /* glsl */ `
${COMMON}
in vec4 aP;    // world xyz, kind (0 = fluff, 1 = mote)
in float aSize;
out vec2 vQ;
out float vKind;
out vec3 vWPos;
out float vFade;
out float vSeed;
void main(){
  vec3 right = vec3(viewMatrix[0][0], viewMatrix[1][0], viewMatrix[2][0]);
  vec3 up = vec3(viewMatrix[0][1], viewMatrix[1][1], viewMatrix[2][1]);
  float spin = uTime * (0.4 + fract(aSize * 37.0)) + aSize * 50.0;
  vec2 q = mat2(cos(spin), -sin(spin), sin(spin), cos(spin)) * position.xy;
  float d = length(aP.xyz - cameraPosition);
  // Never close to the lens: a tuft a metre or two away fills the frame as a bright starburst
  // (it read as a glowing object on the ground from altitude). Gone at the box edge too.
  vFade = smoothstep(5.0, 11.0, d) * (1.0 - smoothstep(${(BOX * 0.7).toFixed(1)}, ${BOX.toFixed(1)}, d));
  // A mote stays at least ~1.5 px wide so it twinkles instead of vanishing.
  float px = d * 0.0016;
  float s = max(aSize, aP.w > 0.5 ? px * 1.5 : 0.0);
  vec3 wp = aP.xyz + (right * q.x + up * q.y) * s;
  vQ = position.xy;
  vKind = aP.w;
  vSeed = aSize * 91.0;
  vWPos = wp;
  gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
}`;

const FS = /* glsl */ `
${COMMON}
layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
in vec2 vQ;
in float vKind;
in vec3 vWPos;
in float vFade;
in float vSeed;
void main(){
  float r = length(vQ) * 2.0;
  vec3 V = normalize(vWPos - cameraPosition);
  // Toward the sun the fluff and motes light up (forward scatter).
  float back = pow(max(dot(V, uSunDir), 0.0), 3.0);
  float a;
  vec3 col;
  if (vKind < 0.5) {
    // A dandelion pappus: fine radial filaments round a tiny seed.
    float th = atan(vQ.y, vQ.x);
    float fil = pow(abs(cos(th * 7.0 + vSeed)), 18.0);
    a = (fil * (1.0 - smoothstep(0.55, 1.0, r)) * smoothstep(0.05, 0.25, r) * 0.8 + (1.0 - smoothstep(0.0, 0.18, r)));
    a *= 0.75;
    col = mix(vec3(0.95, 0.93, 0.86), uSunColor * 1.6, back) * mix(0.75, 1.0, uSunDir.y + 0.6);
  } else {
    a = 1.0 - smoothstep(0.0, 1.0, r);
    a *= a;
    col = uSunColor * (0.8 + 2.6 * back) * vec3(1.0, 0.92, 0.75);
  }
  // Lit by the day: at dusk and night the fluff and motes all but vanish (no self-lit specks).
  a *= vFade * (1.0 - uNight * 0.9);
  col *= mix(1.0, 0.55, uNight);
  if (a < 0.01) discard;
  gColor = vec4(safe3(col * a), 1.0);
  gNormal = vec4(0.0);
}`;

export class WindFx {
  readonly mesh: THREE.Mesh;
  private readonly p: Float32Array;
  private readonly attr: THREE.InstancedBufferAttribute;
  private readonly w = new THREE.Vector2();
  private readonly phase: Float32Array;

  constructor(seed = 5) {
    const r = mulberry32(seed);
    this.p = new Float32Array(N * 4);
    const size = new Float32Array(N);
    this.phase = new Float32Array(N);
    for (let i = 0; i < N; i++) {
      const mote = r() < 0.55;
      this.p.set([range(r, -BOX, BOX), range(r, -BOX, BOX), range(r, -BOX, BOX), mote ? 1 : 0], i * 4);
      size[i] = mote ? range(r, 0.025, 0.05) : range(r, 0.09, 0.16);
      this.phase[i] = r() * 100;
    }
    const quad = new THREE.PlaneGeometry(1, 1);
    const g = new THREE.InstancedBufferGeometry();
    g.index = quad.index;
    g.setAttribute("position", quad.getAttribute("position"));
    this.attr = new THREE.InstancedBufferAttribute(this.p, 4);
    this.attr.setUsage(THREE.DynamicDrawUsage);
    g.setAttribute("aP", this.attr);
    g.setAttribute("aSize", new THREE.InstancedBufferAttribute(size, 1));
    g.instanceCount = N;
    const mat = new THREE.ShaderMaterial({
      glslVersion: THREE.GLSL3,
      uniforms: { ...G },
      vertexShader: VS,
      fragmentShader: FS,
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });
    this.mesh = new THREE.Mesh(g, mat);
    this.mesh.name = "wind fluff";
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = 9;
    this.started = false;
  }

  private started: boolean;

  /** Move with the wind of each particle's altitude (game dt) and wrap round the camera. */
  update(cam: THREE.Vector3, t: number, dt: number): void {
    const p = this.p;
    if (!this.started) {
      for (let i = 0; i < N; i++) {
        p[i * 4] += cam.x;
        p[i * 4 + 1] += cam.y;
        p[i * 4 + 2] += cam.z;
      }
      this.started = true;
    }
    for (let i = 0; i < N; i++) {
      const o = i * 4;
      const ph = this.phase[i];
      windAt(p[o], p[o + 1], p[o + 2], t, this.w);
      // Swirl: slow eddies on top of the layer wind, fluff bobbing up and down.
      const sx = Math.sin(t * 0.31 + ph) * 0.5, sz = Math.cos(t * 0.27 + ph * 1.3) * 0.5;
      const sy = Math.sin(t * 0.43 + ph * 0.7) * (p[o + 3] > 0.5 ? 0.12 : 0.3);
      p[o] += (this.w.x + sx) * dt;
      p[o + 1] += sy * dt;
      p[o + 2] += (this.w.y + sz) * dt;
      for (let k = 0; k < 3; k++) {
        const c = k === 0 ? cam.x : k === 1 ? cam.y : cam.z;
        const d = p[o + k] - c;
        if (d > BOX) p[o + k] -= 2 * BOX;
        else if (d < -BOX) p[o + k] += 2 * BOX;
      }
    }
    this.attr.needsUpdate = true;
  }
}
