import * as THREE from 'three';
import { perf } from '../core/Perf.js';

const UP = new THREE.Vector3(0, 1, 0);
const _axisX = new THREE.Vector3(1, 0, 0);

/* Tracer presets (plan §5). 'none' and the pistol's every-2nd-shot gating
 * are handled in Combat before calling tracer(). */
const TRACERS = {
  warm: { r1: 0.008, r2: 0.003, op: 0.42, color: 0xffc878, maxLen: 22 },
  bright: { r1: 0.014, r2: 0.006, op: 0.70, color: 0xffe2a8, maxLen: 80 },
  faint2nd: { r1: 0.005, r2: 0.002, op: 0.20, color: 0xffc878, maxLen: 18 },
  enemy: { r1: 0.006, r2: 0.003, op: 0.50, color: 0xff9a5a, maxLen: 40 },
};

/* Hard caps: a mag dump at 200 Hz used to allocate a Mesh + cloned
 * material per puff and never dispose them. GPU/JS then climbed until
 * context loss. Pools pre-allocate; acquire never grows past CAP. */
const CAP = {
  impact: 48,
  blood: 32,
  spark: 96,
  dust: 64,
  tracer: 24,
  muzzle: 16,
};

const WARM = {
  impact: 16,
  blood: 8,
  spark: 32,
  dust: 24,
  tracer: 8,
  muzzle: 4,
};

export class VfxSystem {
  constructor(scene) {
    this.scene = scene;
    this.impacts = [];
    this.geo = new THREE.SphereGeometry(0.028, 8, 6);
    this.spark = new THREE.ConeGeometry(0.012, 0.055, 6);
    this.dustGeo = new THREE.PlaneGeometry(1, 1);
    this.mat = new THREE.MeshStandardMaterial({
      color: 0xf0d8a0, emissive: 0xffd090, emissiveIntensity: 1.15,
      roughness: 0.38, metalness: 0.22, transparent: true, opacity: 1,
    });
    this.blood = new THREE.MeshStandardMaterial({
      color: 0x5a1410, roughness: 0.7, metalness: 0.02, transparent: true, opacity: 1,
    });
    this.sparkMat = new THREE.MeshBasicMaterial({
      color: 0xffd090, transparent: true, opacity: 0.9,
      depthWrite: false, blending: THREE.AdditiveBlending,
    });
    this.dustMat = new THREE.MeshBasicMaterial({
      color: 0xd8c8a8, transparent: true, opacity: 0.8, depthWrite: false,
    });
    this.tracerMat = new THREE.MeshBasicMaterial({
      color: 0xffc878, transparent: true, opacity: 0.42,
      depthWrite: false, depthTest: false,
      blending: THREE.AdditiveBlending,
    });
    this._tracerGeo = {};
    for (const [k, p] of Object.entries(TRACERS)) {
      this._tracerGeo[k] = new THREE.CylinderGeometry(p.r1, p.r2, 1, 6);
    }
    this._pools = { impact: [], blood: [], spark: [], dust: [], tracer: [], muzzle: [] };
    this.created = { impact: 0, blood: 0, spark: 0, dust: 0, tracer: 0, muzzle: 0 };
    this.lastOrigin = new THREE.Vector3();
    this.lastDir = new THREE.Vector3();
    this.lastLen = 0;
    this._warm();
  }

  _protoMat(kind) {
    if (kind === 'blood') return this.blood;
    if (kind === 'dust') return this.dustMat;
    if (kind === 'tracer') return this.tracerMat;
    if (kind === 'spark' || kind === 'muzzle') return this.sparkMat;
    return this.mat;
  }

  _protoGeo(kind) {
    if (kind === 'dust') return this.dustGeo;
    if (kind === 'spark' || kind === 'muzzle') return this.spark;
    if (kind === 'tracer') return this._tracerGeo.warm;
    return this.geo;
  }

  _make(kind) {
    const mat = this._protoMat(kind).clone();
    const m = new THREE.Mesh(this._protoGeo(kind), mat);
    m.castShadow = false;
    m.receiveShadow = false;
    m.visible = false;
    m.frustumCulled = true;
    m.userData.kind = kind;
    m.userData.pooled = true;
    m.userData.life = 0;
    m.userData.grow = 0;
    m.userData.fade = 8;
    this.created[kind] += 1;
    this.scene.add(m);
    return m;
  }

  _warm() {
    for (const kind of Object.keys(this._pools)) {
      const n = WARM[kind] || 0;
      for (let i = 0; i < n; i++) this._pools[kind].push(this._make(kind));
    }
  }

  _acquire(kind) {
    const pool = this._pools[kind];
    let mesh = pool.pop();
    if (!mesh && this.created[kind] < CAP[kind]) mesh = this._make(kind);
    if (!mesh) {
      for (let i = 0; i < this.impacts.length; i++) {
        if (this.impacts[i].userData.kind === kind) {
          mesh = this.impacts[i];
          this.impacts.splice(i, 1);
          break;
        }
      }
    }
    if (!mesh) return null;
    mesh.visible = true;
    if (!mesh.parent) this.scene.add(mesh);
    this.impacts.push(mesh);
    return mesh;
  }

  _release(m) {
    m.visible = false;
    m.scale.set(1, 1, 1);
    m.userData.life = 0;
    m.userData.grow = 0;
    const kind = m.userData.kind;
    if (kind && this._pools[kind]) this._pools[kind].push(m);
  }

  impact(pos, flesh) {
    perf.mark('vfx');
    const m = this._acquire(flesh ? 'blood' : 'impact');
    if (!m) return;
    m.position.copy(pos);
    m.scale.setScalar(1);
    m.material.opacity = 1;
    m.userData.life = 0.14;
    m.userData.grow = 0;
    m.userData.fade = 8;
    if (!flesh) {
      for (let i = 0; i < 5; i++) this._sparkAt(pos, 0.07);
    }
    perf.done('vfx');
  }

  _sparkAt(pos, life) {
    const s = this._acquire('spark');
    if (!s) return;
    s.position.copy(pos);
    s.rotation.set(Math.random() * 6, Math.random() * 6, Math.random() * 6);
    s.scale.setScalar(1);
    s.material.opacity = 0.9;
    s.userData.life = life;
    s.userData.grow = 0;
    s.userData.fade = 8;
  }

  /* Wall-impact dust: 4 sand quads scaling 0.05 → 0.14 over 0.22 s, plus
   * 2 cone sparks when withSparks (Combat caps sparks at 4/trigger pull). */
  dust(pos, withSparks = true) {
    perf.mark('vfx');
    for (let i = 0; i < 4; i++) {
      const m = this._acquire('dust');
      if (!m) break;
      m.position.set(
        pos.x + (Math.random() - 0.5) * 0.09,
        pos.y + (Math.random() - 0.5) * 0.09,
        pos.z + (Math.random() - 0.5) * 0.09,
      );
      m.rotation.set(Math.random() * 6, Math.random() * 6, Math.random() * 6);
      m.scale.setScalar(0.05);
      m.material.opacity = 0.8;
      m.userData.life = 0.22;
      m.userData.grow = (0.14 - 0.05) / 0.22;
      m.userData.fade = 4.5;
    }
    if (withSparks) {
      for (let i = 0; i < 2; i++) this._sparkAt(pos, 0.07);
    }
    perf.done('vfx');
  }

  muzzleFlash(pos) {
    const s = this._acquire('muzzle');
    if (!s) return;
    s.position.copy(pos);
    s.rotation.set(0, 0, 0);
    s.scale.setScalar(1);
    s.material.opacity = 0.9;
    s.userData.life = 0.045;
    s.userData.grow = 0;
    s.userData.fade = 8;
  }

  /* Fired on EVERY shot now (pre-c21 they only drew on misses — a bug).
   * dist clamps the beam so it ends at the hit/wall instead of punching
   * through; 'bright' (sniper) always runs the full length.
   * origin is the muzzle WORLD position (Combat converts the camera-parented
   * viewmodel tip); the beam flies from there toward the impact. */
  tracer(origin, dir, style = 'warm', dist = 22) {
    perf.mark('vfx');
    const p = TRACERS[style] || TRACERS.warm;
    const key = TRACERS[style] ? style : 'warm';
    const len = Math.max(1.5, Math.min(dist, p.maxLen));
    const mesh = this._acquire('tracer');
    if (!mesh) return;
    mesh.geometry = this._tracerGeo[key] || this._tracerGeo.warm;
    mesh.material.color.setHex(p.color);
    mesh.material.opacity = p.op;
    mesh.scale.set(1, len, 1);
    mesh.position.copy(origin).addScaledVector(dir, len * 0.5);
    if (dir.y > 0.999) mesh.quaternion.identity();
    else if (dir.y < -0.999) mesh.quaternion.setFromAxisAngle(_axisX, Math.PI);
    else mesh.quaternion.setFromUnitVectors(UP, dir);
    mesh.userData.life = style === 'bright' ? 0.07 : 0.045;
    mesh.userData.fade = style === 'bright' ? 10 : 8;
    mesh.userData.grow = 0;
    this.lastOrigin.copy(origin);
    this.lastDir.copy(dir);
    this.lastLen = len;
    perf.done('vfx');
  }

  update(dt) {
    for (let i = this.impacts.length - 1; i >= 0; i--) {
      const m = this.impacts[i];
      m.userData.life -= dt;
      if (m.userData.grow) {
        const s = m.scale.x + m.userData.grow * dt;
        m.scale.setScalar(s);
      }
      if (m.material && m.material.opacity !== undefined) {
        m.material.opacity = Math.max(0, Math.min(1, m.userData.life * (m.userData.fade || 8)));
      }
      if (m.userData.life <= 0) {
        this.impacts.splice(i, 1);
        this._release(m);
      }
    }
  }
}
