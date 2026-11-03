import * as THREE from 'three';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/examples/jsm/postprocessing/OutputPass.js';
import { FighterModel } from './fighterModel.js';
import { buildStage } from './stages.js';
import { Fx3D } from './fx3d.js';
import { toX, toY, lerp, clamp, dotTex } from './common.js';

export const QUALITY = {
  low: { level: 'low', dpr: 0.75, shadows: false, outline: false, bloom: false, particles: 0.5 },
  med: { level: 'med', dpr: 1.25, shadows: false, outline: true, bloom: false, particles: 1 },
  high: { level: 'high', dpr: 2, shadows: true, outline: true, bloom: true, particles: 1 },
};

export class World {
  constructor(canvas, quality = 'med') {
    this.canvas = canvas;
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: quality !== 'low', powerPreference: 'high-performance', preserveDrawingBuffer: false, alpha: false });
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping; this.renderer.toneMappingExposure = 1.05;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(32, 16 / 9, 0.1, 200);
    this.camera.position.set(0, 1.6, 9);
    this.camPos = new THREE.Vector3(0, 1.6, 9); this.camLook = new THREE.Vector3(0, 1, 0);
    this.time = 0; this.stageId = null; this.models = [null, null]; this.chars = [null, null];
    this.shadowBlobs = [];
    this.mode = 'menu';
    this.setQuality(quality, true);
  }

  setQuality(name, initial = false) {
    this.qName = name; this.q = QUALITY[name] || QUALITY.med;
    this.renderer.shadowMap.enabled = this.q.shadows;
    this.resize();
    this.composer = null;
    if (this.q.bloom) {
      const size = this.renderer.getSize(new THREE.Vector2());
      this.composer = new EffectComposer(this.renderer);
      this.composer.addPass(new RenderPass(this.scene, this.camera));
      this.bloom = new UnrealBloomPass(new THREE.Vector2(size.x / 2, size.y / 2), 0.55, 0.5, 0.82);
      this.composer.addPass(this.bloom); this.composer.addPass(new OutputPass());
      this.composer.setPixelRatio(this.renderer.getPixelRatio()); this.composer.setSize(size.x, size.y);
    }
    if (!initial && this.stageId) { const s = this.stageId; this.stageId = null; this.setStage(s); const c = this.chars; this.chars = [null, null]; this.setFighters(c[0], c[1]); }
  }

  resize() {
    const w = this.canvas.clientWidth || innerWidth, h = this.canvas.clientHeight || innerHeight;
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, this.q.dpr));
    this.renderer.setSize(w, h, false);
    if (this.composer) { this.composer.setPixelRatio(this.renderer.getPixelRatio()); this.composer.setSize(w, h); }
    this.camera.aspect = w / h; this.camera.updateProjectionMatrix();
  }

  setStage(id) {
    if (this.stageId === id) return;
    if (this.stage) { this.scene.remove(this.stage.root); this.stage.root.traverse((o) => { if (o.geometry) o.geometry.dispose(); if (o.material) { for (const m of [].concat(o.material)) { if (m.map) m.map.dispose(); if (m.emissiveMap) m.emissiveMap.dispose(); m.dispose(); } } }); }
    this.stage = buildStage(id, this.q); this.stageId = id;
    this.scene.add(this.stage.root);
    this.scene.fog = this.stage.fog || null;
    if (!this.fx) this.fx = new Fx3D(this.scene, this.q);
    else if (this.fx.q !== this.q) { this.fx.clear(); for (const p of [this.fx.glow, this.fx.solid]) this.scene.remove(p.mesh); this.fx = new Fx3D(this.scene, this.q); if (this.models[0]) this.fx.setTrails(this.models); }
  }

  setFighters(c1, c2) {
    const cs = [c1, c2];
    for (let i = 0; i < 2; i++) {
      if (this.chars[i] === cs[i] && this.models[i]) continue;
      if (this.models[i]) { this.scene.remove(this.models[i].root); this.models[i].dispose(); }
      if (this.shadowBlobs[i]) this.scene.remove(this.shadowBlobs[i]);
      if (!cs[i]) { this.models[i] = null; continue; }
      const m = new FighterModel(cs[i], { outline: this.q.outline });
      this.models[i] = m; this.chars[i] = cs[i];
      this.scene.add(m.root);
      const blob = new THREE.Mesh(new THREE.CircleGeometry(0.45, 20), new THREE.MeshBasicMaterial({ map: dotTex(), color: 0x000000, transparent: true, opacity: 0.55, depthWrite: false }));
      blob.rotation.x = -Math.PI / 2; blob.position.y = 0.012; blob.visible = !this.q.shadows; this.scene.add(blob); this.shadowBlobs[i] = blob;
    }
    if (this.fx) this.fx.setTrails(this.models.filter(Boolean));
  }

  // camera director: frames both fighters, punches in on supers and KOs, shakes on hits
  directCamera(game, dt, extra = {}) {
    const k = 1 - Math.exp(-dt * (extra.fast ? 9 : 4.5));
    const aspect = this.camera.aspect;
    let pos, look;
    if (this.mode === 'menu' || !game) {
      const t = this.time * 0.18;
      pos = new THREE.Vector3(Math.sin(t) * 6.5, 1.9 + Math.sin(t * 0.7) * 0.4, 7.5 + Math.cos(t) * 1.5);
      look = new THREE.Vector3(0, 1.0, 0);
    } else if (this.mode === 'select') {
      pos = new THREE.Vector3(0, 1.2, 7.2); look = new THREE.Vector3(0, 0.95, 0);
    } else {
      const [a, b] = game.f;
      const ax = toX(a.x), bx = toX(b.x), mid = (ax + bx) / 2, sep = Math.abs(ax - bx);
      const fovH = 2 * Math.atan(Math.tan((this.camera.fov * Math.PI) / 360) * aspect);
      const want = Math.max(4.6, sep + 2.8);
      const dist = clamp(want / 2 / Math.tan(fovH / 2), 5.2, 13);
      const hy = Math.max(toY(a.y), toY(b.y));
      pos = new THREE.Vector3(clamp(mid, -2.6, 2.6), 1.45 + hy * 0.35 + dist * 0.035, dist);
      look = new THREE.Vector3(clamp(mid, -2.6, 2.6), 1.0 + hy * 0.4, 0);
      if (game.phase === 'intro' && game.phaseT < 62) {      // round intro sweep
        const t = 1 - game.phaseT / 62;
        pos.add(new THREE.Vector3(Math.sin(t * 1.4) * 4.5, t * 1.2, -t * 2));
      }
      if (game.freeze > 0 && game.freezeBy) {                // super cinematic: punch in on the user
        const f = game.freezeBy, fx = toX(f.x), side = f.facing;
        const t = 1 - game.freeze / 32;
        pos = new THREE.Vector3(fx + side * (1.6 - t * 0.3), 1.25 + t * 0.15, 2.6 - t * 0.5);
        look = new THREE.Vector3(fx, 1.15 * f.char.scale, 0);
        extra.fast = true;
      }
      if (game.phase === 'roundEnd' && game.roundResult?.kind === 'ko' && game.phaseT < 110 && game.roundResult.winner !== null) {
        const loser = game.f[1 - game.roundResult.winner], lx = toX(loser.x);
        const t = game.phaseT / 110;
        pos = new THREE.Vector3(lx + Math.sin(t * 1.5 - 0.6) * 2.4, 0.9 + t * 0.6, 3.2 + t * 0.6);
        look = new THREE.Vector3(lx, 0.5 + toY(loser.y), 0);
      }
      if (game.phase === 'over' || (game.phase === 'roundEnd' && game.phaseT >= 110)) {
        const w = game.winner ?? game.roundResult?.winner;
        if (w !== null && w !== undefined) { const f = game.f[w], fx = toX(f.x); pos = new THREE.Vector3(fx + f.facing * 1.4, 1.35, 3.6); look = new THREE.Vector3(fx, 1.15, 0); }
      }
    }
    this.camPos.lerp(pos, extra.fast ? Math.min(1, k * 2) : k); this.camLook.lerp(look, extra.fast ? Math.min(1, k * 2) : k);
    this.camera.position.copy(this.camPos);
    const sh = game ? (game.shakeAmt || 0) : 0;
    if (sh > 0 && extra.shake !== false) this.camera.position.add(new THREE.Vector3((Math.random() - 0.5) * sh * 0.02, (Math.random() - 0.5) * sh * 0.02, 0));
    this.camera.lookAt(this.camLook);
    // zoom pulse on supers
    const targetFov = game && game.freeze > 0 ? 27 : 32;
    this.camera.fov += (targetFov - this.camera.fov) * k; this.camera.updateProjectionMatrix();
  }

  sync(game, dt) {
    for (let i = 0; i < 2; i++) {
      const m = this.models[i], f = game.f[i]; if (!m) continue;
      m.root.position.set(toX(f.x), toY(f.y), 0);
      m.update(f, game, dt, this.time);
      const blob = this.shadowBlobs[i];
      if (blob) { blob.position.x = toX(f.x); const h = Math.max(0, toY(f.y)); blob.scale.setScalar(Math.max(0.4, 1 - h * 0.35) * f.char.scale); blob.material.opacity = 0.5 - Math.min(0.35, h * 0.2); }
      if ((f.state === 'super' || f.state === 'badla' || f.meter >= 100) && this.fx && this.q.level !== 'low') this.fx.embers(toX(f.x), 0.6, new THREE.Color(f.char.superColor).getHex());
    }
  }

  // super / KO dimming of the scene during the cinematic
  dim(game) {
    const want = game && game.freeze > 0 ? 0.35 : 1;
    this.scene.userData.dim = lerp(this.scene.userData.dim ?? 1, want, 0.2);
    const d = this.scene.userData.dim;
    if (this.stage) { this.stage.hemi.intensity *= d; this.stage.key.intensity *= Math.max(0.6, d); }
  }

  render(game, dt, opts = {}) {
    this.time += dt;
    if (this.stage) this.stage.update(this.time, game, dt);
    if (game && this.models[0]) this.sync(game, dt);
    else if (opts.showroom) this.showroom(dt);
    this.dim(game);
    this.directCamera(game, dt, opts);
    if (this.fx) this.fx.update(game, this.camera, dt, game ? this.models : null);
    if (this.composer) this.composer.render(); else this.renderer.render(this.scene, this.camera);
  }

  showX() { const d = this.camera.position.z - 0.4, half = Math.tan((this.camera.fov * Math.PI) / 360) * d * this.camera.aspect; return Math.min(3.6, half * 0.74); }
  // select screen: both fighters idle-posing on the stage, facing camera-ish
  showroom(dt) {
    const fake = (side, m) => ({ side, state: m.char.id === 'anish' ? 'idle' : 'idle', t: 0, facing: side === 0 ? 1 : -1, walkCycle: 0, holdingBack: false, flash: 0, meter: 0, hp: 100, char: m.char, attack: null, x: 0, y: 0, vx: 0, vy: 0, airborne: false, attackPhase: null });
    this.models.forEach((m, i) => {
      if (!m) return;
      const f = fake(i, m);
      m.root.position.set((i === 0 ? -1 : 1) * this.showX(), 0, 0.4);
      m.update(f, null, dt, this.time);
      m.root.rotation.y = (i === 0 ? 0.55 : -0.55) + Math.sin(this.time * 0.6 + i) * 0.25;
      const blob = this.shadowBlobs[i]; if (blob) { blob.position.set(m.root.position.x, 0.012, 0.4); blob.scale.setScalar(1); }
    });
  }

  // render a single fighter portrait into a 2D canvas (select tiles)
  portrait(char, target, size = 160) {
    const r = this.renderer;
    if (!this._pScene) {
      this._pScene = new THREE.Scene();
      this._pScene.add(new THREE.HemisphereLight(0xffffff, 0x303040, 1.4));
      const d = new THREE.DirectionalLight(0xffffff, 1.8); d.position.set(-2, 3, 4); this._pScene.add(d);
      const rim = new THREE.DirectionalLight(0xe3b65a, 2.0); rim.position.set(2, 2, -3); this._pScene.add(rim);
      this._pCam = new THREE.PerspectiveCamera(26, 0.8, 0.1, 20);
    }
    const m = new FighterModel(char, { outline: true });
    m.update({ side: 0, state: 'idle', t: 0, facing: 1, walkCycle: 0, flash: 0, meter: 0, hp: 100, char, attack: null, holdingBack: false }, null, 1, 0.5);
    m.root.rotation.y = 0.5; m.aura.visible = false;
    this._pScene.add(m.root);
    const h = 1.62 * char.scale;
    this._pCam.position.set(0, h * 0.78, 2.4); this._pCam.lookAt(0, h * 0.72, 0);
    const old = r.getSize(new THREE.Vector2()), oldPR = r.getPixelRatio();
    const W = target.width, H = target.height;
    r.setPixelRatio(1); r.setSize(W, H, false);
    r.setClearColor(0x000000, 0); r.setClearAlpha(0);
    this._pCam.aspect = W / H; this._pCam.updateProjectionMatrix();
    const fogBak = this.scene.fog;
    r.render(this._pScene, this._pCam);
    const ctx = target.getContext('2d'); ctx.clearRect(0, 0, W, H); ctx.drawImage(r.domElement, 0, 0, W, H);
    this._pScene.remove(m.root); m.dispose();
    r.setPixelRatio(oldPR); r.setSize(old.x, old.y, false); r.setClearColor(0x000000, 1);
    this.scene.fog = fogBak;
  }
}
