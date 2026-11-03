// CPU-simulated billboards, drawn with one instanced quad per layer.
import * as THREE from 'three/webgpu';
import {
  attribute, positionGeometry, vec2, vec3, cos, sin, length, normalize, cross, uniform, select, Fn, texture, uv, mod, floor, varying, float,
} from 'three/tsl';
import { SPRITE_CELLS } from './textures.js';

export const LAND_BLOOD = 1, LAND_CASING = 2, LAND_ACID = 3;

const camRight = uniform(new THREE.Vector3(1, 0, 0));
const camUp = uniform(new THREE.Vector3(0, 1, 0));
const camFwd = uniform(new THREE.Vector3(0, 0, -1));

export function syncBillboards(camera) {
  const m = camera.matrixWorld.elements;
  camRight.value.set(m[0], m[1], m[2]);
  camUp.value.set(m[4], m[5], m[6]);
  camFwd.value.set(-m[8], -m[9], -m[10]);
}

const FIELDS = ['x', 'y', 'z', 'vx', 'vy', 'vz', 'life', 'max', 's0', 's1', 'r', 'g', 'b', 'a', 'shape', 'grav', 'drag', 'stretch', 'rot', 'spin', 'flat', 'land'];

export class ParticleLayer {
  constructor(stage, atlas, capacity, additive) {
    this.capacity = capacity;
    this.count = 0;
    this.drawn = 0;
    for (const f of FIELDS) this[f] = new Float32Array(capacity);
    this.iPos = new Float32Array(capacity * 4);
    this.iDir = new Float32Array(capacity * 4);
    this.iCol = new Float32Array(capacity * 4);
    this.iCel = new Float32Array(capacity * 2);

    const quad = new THREE.PlaneGeometry(1, 1);
    const g = this.geo = new THREE.InstancedBufferGeometry();
    g.index = quad.index;
    g.setAttribute('position', quad.getAttribute('position'));
    g.setAttribute('uv', quad.getAttribute('uv'));
    const dyn = (arr, n) => new THREE.InstancedBufferAttribute(arr, n).setUsage(THREE.DynamicDrawUsage);
    this.attrs = [dyn(this.iPos, 4), dyn(this.iDir, 4), dyn(this.iCol, 4), dyn(this.iCel, 2)];
    ['iPos', 'iDir', 'iCol', 'iCel'].forEach((k, i) => g.setAttribute(k, this.attrs[i]));
    g.instanceCount = 0;

    const iPos = attribute('iPos', 'vec4'), iDir = attribute('iDir', 'vec4'), iCol = attribute('iCol', 'vec4'), iCel = attribute('iCel', 'vec2');
    const m = new THREE.MeshBasicNodeMaterial({ transparent: true, depthWrite: false, side: THREE.DoubleSide });
    m.blending = additive ? THREE.AdditiveBlending : THREE.NormalBlending;
    m.positionNode = Fn(() => {
      const q = positionGeometry.xy;
      const c = cos(iDir.w), s = sin(iDir.w), size = iPos.w;
      const rq = vec2(q.x.mul(c).sub(q.y.mul(s)), q.x.mul(s).add(q.y.mul(c))).mul(size);
      const stretch = length(iDir.xyz);
      const axis = normalize(iDir.xyz.add(vec3(0.00001, 0, 0)));
      const side = normalize(cross(axis, camFwd));
      const streak = side.mul(q.x).mul(size).add(axis.mul(q.y).mul(size.add(stretch)));
      const bill = camRight.mul(rq.x).add(camUp.mul(rq.y));
      const flat = vec3(rq.x, 0, rq.y);
      const off = select(iCel.y.greaterThan(0.5), flat, select(stretch.greaterThan(0.0001), streak, bill));
      return iPos.xyz.add(off);
    })();
    const cell = varying(vec2(mod(iCel.x, SPRITE_CELLS), floor(iCel.x.div(SPRITE_CELLS))));
    const t = texture(atlas, vec2(uv().x, uv().y.oneMinus()).add(cell).div(SPRITE_CELLS));
    m.colorNode = additive ? iCol.rgb.mul(t.rgb).mul(t.a).mul(iCol.a) : iCol.rgb.mul(t.rgb);
    m.opacityNode = additive ? float(1) : t.a.mul(iCol.a);
    const mesh = this.mesh = new THREE.Mesh(g, m);
    mesh.frustumCulled = false;
    mesh.renderOrder = additive ? 20 : 10;
    stage.scene.add(mesh);
  }

  spawn(x, y, z, vx, vy, vz, life, s0, s1, r, g, b, a, shape, o = EMPTY) {
    let i = this.count;
    if (i >= this.capacity) i = Math.floor(Math.random() * this.capacity); // overwrite instead of dropping
    else this.count++;
    this.x[i] = x; this.y[i] = y; this.z[i] = z;
    this.vx[i] = vx; this.vy[i] = vy; this.vz[i] = vz;
    this.life[i] = life; this.max[i] = life;
    this.s0[i] = s0; this.s1[i] = s1;
    this.r[i] = r; this.g[i] = g; this.b[i] = b; this.a[i] = a;
    this.shape[i] = shape;
    this.grav[i] = o.grav ?? 0; this.drag[i] = o.drag ?? 0; this.stretch[i] = o.stretch ?? 0;
    this.rot[i] = o.rot ?? 0; this.spin[i] = o.spin ?? 0; this.flat[i] = o.flat ? 1 : 0;
    this.land[i] = o.land ?? 0;
  }

  // One-frame sprite, for bullets and pickups that are simulated elsewhere.
  draw(x, y, z, size, sx, sy, sz, r, g, b, a, shape, rot = 0, flat = 0) {
    const i = this.drawn;
    if (i >= this.capacity) return;
    this.drawn++;
    const p = i * 4, P = this.iPos, D = this.iDir, C = this.iCol;
    P[p] = x; P[p + 1] = y; P[p + 2] = z; P[p + 3] = size;
    D[p] = sx; D[p + 1] = sy; D[p + 2] = sz; D[p + 3] = rot;
    C[p] = r; C[p + 1] = g; C[p + 2] = b; C[p + 3] = a;
    this.iCel[i * 2] = shape; this.iCel[i * 2 + 1] = flat;
  }

  update(dt, onLand) {
    let i = 0;
    while (i < this.count) {
      const life = (this.life[i] -= dt);
      if (life <= 0) { this.remove(i); continue; }
      const drag = Math.exp(-this.drag[i] * dt);
      this.vx[i] *= drag; this.vz[i] *= drag; this.vy[i] = this.vy[i] * drag - this.grav[i] * dt;
      this.x[i] += this.vx[i] * dt; this.y[i] += this.vy[i] * dt; this.z[i] += this.vz[i] * dt;
      if (this.land[i] && this.y[i] <= 0.02) {
        onLand(this.land[i], this.x[i], this.z[i], this.s0[i], this.r[i], this.g[i], this.b[i]);
        this.remove(i);
        continue;
      }
      this.rot[i] += this.spin[i] * dt;
      const t = 1 - life / this.max[i];
      const size = this.s0[i] + (this.s1[i] - this.s0[i]) * t;
      const fade = Math.min(1, life / (this.max[i] * 0.35));
      const st = this.stretch[i];
      this.draw(this.x[i], this.y[i], this.z[i], size, this.vx[i] * st, this.vy[i] * st, this.vz[i] * st, this.r[i], this.g[i], this.b[i], this.a[i] * fade, this.shape[i], this.rot[i], this.flat[i]);
      i++;
    }
  }

  remove(i) {
    const last = --this.count;
    if (i === last) return;
    for (const f of FIELDS) this[f][i] = this[f][last];
  }

  commit() {
    this.geo.instanceCount = this.drawn;
    if (this.drawn) for (const a of this.attrs) a.needsUpdate = true;
    this.drawn = 0;
  }

  clear() { this.count = 0; this.drawn = 0; }
}

const EMPTY = {};
