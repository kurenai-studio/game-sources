// Renderer, post chain, camera rig and light rig. Game code talks to this, never to three directly.
import * as THREE from 'three/webgpu';
import {
  pass, renderOutput, uniform, vec2, vec3, vec4, screenUV, mix, smoothstep, luminance, time, rand, abs, Fn,
  positionWorld, normalize, max, pow, dot,
} from 'three/tsl';
import { bloom } from 'three/addons/tsl/display/BloomNode.js';
import { CAM, ARENA, FLAGS, REDUCED_MOTION } from '../config.js';
import { clamp, damp, rand as jitter } from '../core/util.js';

const _v = new THREE.Vector3();
const _dir = new THREE.Vector3();

// A stalled GPU process can leave WebGPU's adapter or device request pending forever. Without a
// limit the game would sit on its loading screen; with one, the player gets WebGL2 after a wait.
const GPU_PATIENCE = 6000;
const inTime = (promise) => Promise.race([promise.then(() => true, () => false), new Promise((done) => { setTimeout(() => done(false), GPU_PATIENCE); })]);

export class Stage {
  constructor(container, tier) {
    this.container = container;
    this.tier = tier;
    this.trauma = 0;
    this.focus = new THREE.Vector3();
    this.pixelRatio = Math.min(devicePixelRatio, tier.dpr);
    this.viewHalfW = 18; this.viewHalfH = 12;
    this.shockT = 1;
    this.distance = CAM.dist;
    this.shakeScale = 1;
  }

  async init() {
    const { container, tier } = this;
    const create = (forceWebGL) => new THREE.WebGPURenderer({ antialias: tier.msaa, forceWebGL, powerPreference: 'high-performance' });
    let renderer = create(FLAGS.webgl);
    if (!(await inTime(renderer.init()))) {
      renderer = create(true);
      await renderer.init();
    }
    this.renderer = renderer;
    renderer.setPixelRatio(this.pixelRatio);
    renderer.setSize(Math.max(1, container.clientWidth), Math.max(1, container.clientHeight));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1;
    renderer.shadowMap.enabled = tier.shadow > 0;
    renderer.shadowMap.type = THREE.PCFShadowMap;
    renderer.onDeviceLost = (info) => {
      console.error('GPU device lost', info);
      this.onLost?.();
    };
    const canvas = renderer.domElement;
    canvas.setAttribute('role', 'img');
    canvas.setAttribute('aria-label', 'Top-down view of a soldier fighting a monster horde');
    container.appendChild(canvas);

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color('#050404');
    this.camera = new THREE.PerspectiveCamera(CAM.fov, 1.6, 2, 170);
    this.pmrem = new THREE.PMREMGenerator(renderer);
    this.setupLights();
    this.setupPost();
    this.resize();
    window.addEventListener('resize', () => this.resize());
    window.addEventListener('orientationchange', () => this.resize());
  }

  setupLights() {
    const { scene, tier } = this;
    const sun = this.sun = new THREE.DirectionalLight('#ffffff', 2);
    sun.castShadow = tier.shadow > 0;
    if (sun.castShadow) {
      sun.shadow.mapSize.setScalar(tier.shadow);
      const r = 30;
      Object.assign(sun.shadow.camera, { left: -r, right: r, top: r, bottom: -r, near: 5, far: 120 });
      sun.shadow.bias = -0.0005;
      sun.shadow.normalBias = 0.03;
      sun.shadow.radius = 2.5;
    }
    scene.add(sun, sun.target);
    this.sunDir = new THREE.Vector3(0.5, 0.7, 0.5);

    this.hemi = new THREE.HemisphereLight('#ffffff', '#222222', 1);
    scene.add(this.hemi);

    // Fixed light count: toggling lights would recompile every material mid-fight.
    this.lantern = new THREE.PointLight('#ffd9ae', 20, 22, 1.6);
    this.torch = new THREE.SpotLight('#fff3df', 0, 30, 0.42, 0.65, 1.3);
    scene.add(this.lantern, this.torch, this.torch.target);
    this.pool = [];
    for (let i = 0; i < tier.lights; i++) {
      const l = new THREE.PointLight('#ffffff', 0, 12, 1.8);
      scene.add(l);
      this.pool.push({ light: l, power: 0, decay: 1 });
    }
  }

  setupPost() {
    const { renderer, scene, camera } = this;
    const pipeline = this.pipeline = new THREE.RenderPipeline(renderer);
    const u = this.u = {
      hurt: uniform(0), desat: uniform(0), aberration: uniform(0.0006), flash: uniform(0),
      shock: uniform(new THREE.Vector4(0.5, 0.5, 0, 0)), aspect: uniform(1.6),
      tint: uniform(new THREE.Color(1, 1, 1)), vignette: uniform(0.62),
    };
    const scenePass = pass(scene, camera);
    const color = scenePass.getTextureNode('output');
    this.bloomPass = bloom(color, 0.62, 0.55, 0.92);

    const warped = Fn(() => {
      const d = screenUV.sub(u.shock.xy).mul(vec2(u.aspect, 1));
      const r = d.length();
      const ring = smoothstep(0.1, 0, abs(r.sub(u.shock.z))).mul(u.shock.w);
      return screenUV.sub(d.div(r.add(0.001)).mul(ring));
    })();
    const fringe = warped.sub(0.5).mul(u.aberration.mul(warped.sub(0.5).length().mul(2).add(0.35)));
    const hdr = vec3(
      color.sample(warped.add(fringe)).r,
      color.sample(warped).g,
      color.sample(warped.sub(fringe)).b,
    ).add(this.bloomPass.rgb);
    const graded = mix(hdr, vec3(luminance(hdr)), u.desat).mul(u.tint).add(vec3(u.flash));

    const toned = renderOutput(vec4(graded, 1));
    const edge = smoothstep(0.32, 0.86, screenUV.sub(0.5).mul(vec2(1.08, 1)).length().mul(1.25));
    const vig = mix(1, u.vignette.oneMinus(), edge);
    const hurtEdge = smoothstep(0.2, 0.75, screenUV.sub(0.5).length().mul(1.2)).mul(u.hurt);
    const grain = rand(screenUV.add(time.fract())).sub(0.5).mul(0.028);
    const out = mix(toned.rgb.mul(vig), vec3(0.34, 0.0, 0.015), hurtEdge.mul(0.82)).add(grain);
    pipeline.outputNode = vec4(out, 1);
    pipeline.outputColorTransform = false;
  }

  // Dim sky-box only used for reflections on wet blood and chitin.
  buildEnvironment(biome) {
    const envScene = new THREE.Scene();
    const skyMat = new THREE.MeshBasicNodeMaterial({ side: THREE.BackSide });
    const sky = uniform(new THREE.Color(biome.hemi.sky));
    const low = uniform(new THREE.Color(biome.hemi.ground));
    const sunCol = uniform(new THREE.Color(biome.sun.color));
    const sunDir = uniform(new THREE.Vector3(...biome.sun.dir).normalize());
    const d = normalize(positionWorld);
    skyMat.colorNode = mix(low, sky, smoothstep(-0.2, 0.6, d.y)).add(sunCol.mul(pow(max(dot(d, sunDir), 0), 18).mul(9)));
    envScene.add(new THREE.Mesh(new THREE.SphereGeometry(20, 24, 16), skyMat));
    const rt = this.pmrem.fromScene(envScene, 0.03);
    this.envRT?.dispose();
    this.envRT = rt;
    this.scene.environment = rt.texture;
    skyMat.dispose();
  }

  applyBiome(biome) {
    const { renderer, scene } = this;
    renderer.toneMappingExposure = biome.exposure;
    scene.background.set(biome.bg);
    scene.environmentIntensity = biome.env;
    this.sun.color.set(biome.sun.color);
    this.sun.intensity = biome.sun.intensity;
    this.sunDir.set(...biome.sun.dir).normalize();
    this.hemi.color.set(biome.hemi.sky);
    this.hemi.groundColor.set(biome.hemi.ground);
    this.hemi.intensity = biome.hemi.intensity;
    this.lantern.color.set(biome.lantern);
    this.lanternPower = biome.lanternI;
    this.buildEnvironment(biome);
  }

  resize() {
    const { container, renderer, camera } = this;
    const w = container.clientWidth, h = container.clientHeight;
    if (!w || !h) return;   // hidden or minimised: WebGPU cannot make a zero-sized swapchain
    const aspect = w / h;
    camera.aspect = aspect;
    this.distance = CAM.dist * clamp(1.42 / aspect, 1, 1.9);
    camera.updateProjectionMatrix();
    renderer.setSize(w, h);
    this.u.aspect.value = aspect;
    const halfH = Math.tan(THREE.MathUtils.degToRad(CAM.fov / 2)) * this.distance;
    this.viewHalfH = halfH / Math.sin(CAM.pitch);
    this.viewHalfW = halfH * aspect;
  }

  setPixelRatio(pr) {
    if (Math.abs(pr - this.pixelRatio) < 0.01) return;
    this.pixelRatio = pr;
    this.renderer.setPixelRatio(pr);
  }

  snapCamera(x, z) { this.focus.set(x, 0, z); this.placeCamera(0, 0); }

  updateCamera(dt, x, z, lookX, lookZ) {
    const f = this.focus;
    const lim = ARENA - 3;
    f.x = damp(f.x, clamp(x + lookX, -lim, lim), CAM.follow, dt);
    f.z = damp(f.z, clamp(z + lookZ, -lim, lim), CAM.follow, dt);
    this.trauma = Math.max(0, this.trauma - dt * 1.7);
    const s = REDUCED_MOTION ? 0 : this.trauma * this.trauma * 1.5;
    this.placeCamera(s * jitter(-1, 1), s * jitter(-1, 1));
    this.updateLights(dt);
  }

  placeCamera(ox, oz) {
    const { camera, focus, distance } = this;
    camera.position.set(
      focus.x + ox,
      Math.sin(CAM.pitch) * distance,
      focus.z + oz + Math.cos(CAM.pitch) * distance,
    );
    camera.lookAt(focus.x + ox * 0.6, 0, focus.z + oz * 0.6);
    camera.updateMatrixWorld();
  }

  shake(amount) { this.trauma = Math.min(1, this.trauma + amount * this.shakeScale); }

  shockwave(x, z, strength) {
    if (REDUCED_MOTION) return;
    const p = this.project(x, 0, z);
    this.u.shock.value.set(p.u, p.v, 0, strength);
    this.shockT = 0;
  }

  // Short-lived dynamic light, for muzzle flash and explosions.
  flash(x, y, z, hex, power, range = 12, decay = 12) {
    let best = this.pool[0];
    for (const p of this.pool) if (p.power < best.power) best = p;
    if (!best || best.power > power) return;
    best.light.position.set(x, y, z);
    best.light.color.set(hex);
    best.light.distance = range;
    best.power = power;
    best.decay = decay;
  }

  updateLights(dt) {
    for (const p of this.pool) {
      if (p.power < 0.05) { p.power = 0; p.light.intensity = 0; continue; }
      p.light.intensity = p.power;
      p.power *= Math.exp(-p.decay * dt);
    }
    const f = this.focus, sun = this.sun;
    // Snap the shadow centre to whole texels so shadows do not crawl as the camera moves.
    const texel = 60 / (this.tier.shadow || 1024);
    const sx = Math.round(f.x / texel) * texel, sz = Math.round(f.z / texel) * texel;
    sun.target.position.set(sx, 0, sz);
    sun.position.set(sx, 0, sz).addScaledVector(this.sunDir, 60);
    if (this.shockT < 1) {
      this.shockT = Math.min(1, this.shockT + dt * 1.7);
      const s = this.u.shock.value;
      s.z = this.shockT * 0.95;
      s.w *= Math.exp(-3.2 * dt);
      if (this.shockT >= 1) s.w = 0;
    }
  }

  // NDC -> point on the horizontal plane at height y. Writes into `out` ({x, z}).
  toGround(ndcX, ndcY, y, out) {
    const { camera } = this;
    _v.set(ndcX, ndcY, 0.5).unproject(camera);
    _dir.copy(_v).sub(camera.position).normalize();
    const t = (y - camera.position.y) / _dir.y;
    out.x = camera.position.x + _dir.x * t;
    out.z = camera.position.z + _dir.z * t;
    return out;
  }

  project(x, y, z) {
    _v.set(x, y, z).project(this.camera);
    return {
      u: _v.x * 0.5 + 0.5, v: _v.y * 0.5 + 0.5,
      x: (_v.x * 0.5 + 0.5) * this.container.clientWidth,
      y: (-_v.y * 0.5 + 0.5) * this.container.clientHeight,
    };
  }

  render() {
    if (this.container.clientWidth && this.container.clientHeight) this.pipeline.render();
  }
}
