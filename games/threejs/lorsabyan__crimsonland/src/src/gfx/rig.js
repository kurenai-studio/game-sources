// Tiny procedural modelling kit. A Rig collects ellipsoids and swept limbs into one indexed
// geometry, and every vertex carries a small skeleton description so the crowd shader can
// animate hundreds of instances without touching the CPU:
//   aPivot  xyz   upper joint (hip, shoulder, neck)
//   aLimb   x phase offset, y pitch amplitude, z sweep amplitude, w foot lift
//   aMat    x roughness (negative: part can be missing), y glow, z breathing, w cloth mask
//   aJoint  xyz   lower joint (knee, elbow)
//   aBend   x weight of the lower joint, y walking flex, z flex phase, w axis (0 pitch, 1 roll)
//   aPose   x pitch while attacking, y pitch when dead, z reach pose, w lower joint bend when dead
//   aFlop   sideways swing at the upper joint when dead, so limbs fall out from the body
// Part options: pivot, limb, joint, flex [amp, phase], flexAt (limb t where the joint sits) or
// flexW (constant weight), axis, pose, flop, rough, glow, breathe, cloth, missing, chain, mottle.
import * as THREE from 'three/webgpu';

const col = new THREE.Color();
const toRGB = (c) => { col.set(c); return [col.r, col.g, col.b]; };
const smooth = (a, b, x) => { const t = Math.min(1, Math.max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t); };

function mottle(x, y, z) {
  const s = Math.sin(x * 21.1 + y * 17.3 + z * 13.7) + Math.sin(x * 7.3 - y * 11.9 + z * 5.1) * 0.7;
  return s * 0.5 + 0.5;
}

const STRIDE = 23;

export class Rig {
  constructor() {
    this.pos = []; this.nor = []; this.rgb = []; this.rig = []; this.idx = [];
  }

  // w: lower-joint weight. amp: scales sweep along a chain. lag: phase delay along a chain.
  vertex(p, n, c, o, w = o.flexW ?? 0, amp = 1, lag = 0) {
    this.pos.push(p[0], p[1], p[2]);
    this.nor.push(n[0], n[1], n[2]);
    const m = 1 + (mottle(p[0], p[1], p[2]) - 0.5) * (o.mottle ?? 0.32);
    this.rgb.push(c[0] * m, c[1] * m, c[2] * m);
    const pv = o.pivot ?? [0, 0, 0], l = o.limb ?? [0, 0, 0, 0], j = o.joint ?? pv, f = o.flex ?? [0, 0], po = o.pose ?? [0, 0, 0, 0];
    const rough = (o.rough ?? 0.6) * (o.missing ? -1 : 1);
    this.rig.push(
      pv[0], pv[1], pv[2],
      l[0] - lag, l[1] * amp, l[2] * amp, l[3],
      rough, o.glow ?? 0, o.breathe ?? 0, o.cloth ?? 0,
      j[0], j[1], j[2],
      w, f[0], f[1], o.axis ?? 0,
      po[0], po[1], po[2], po[3],
      o.flop ?? 0,
    );
  }

  // Ellipsoid. opts: color, color2 (gradient along y), rot [x,y,z], plus shared part options.
  blob(center, radii, opts = {}) {
    const rings = opts.rings ?? 8, segs = opts.segs ?? 10;
    const start = this.pos.length / 3;
    const a = toRGB(opts.color ?? '#888888'), b = toRGB(opts.color2 ?? opts.color ?? '#888888');
    const r = Array.isArray(radii) ? radii : [radii, radii, radii];
    const euler = new THREE.Euler(...(opts.rot ?? [0, 0, 0]));
    const P = new THREE.Vector3(), N = new THREE.Vector3();
    for (let i = 0; i <= rings; i++) {
      const v = i / rings, th = v * Math.PI;
      for (let j = 0; j <= segs; j++) {
        const ph = (j / segs) * Math.PI * 2;
        const sx = Math.sin(th) * Math.cos(ph), sy = Math.cos(th), sz = Math.sin(th) * Math.sin(ph);
        P.set(sx * r[0], sy * r[1], sz * r[2]).applyEuler(euler);
        N.set(sx / r[0], sy / r[1], sz / r[2]).normalize().applyEuler(euler);
        const c = [a[0] + (b[0] - a[0]) * v, a[1] + (b[1] - a[1]) * v, a[2] + (b[2] - a[2]) * v];
        this.vertex([center[0] + P.x, center[1] + P.y, center[2] + P.z], [N.x, N.y, N.z], c, opts);
      }
    }
    for (let i = 0; i < rings; i++) {
      for (let j = 0; j < segs; j++) {
        const p0 = start + i * (segs + 1) + j, p1 = p0 + 1, p2 = p0 + segs + 1, p3 = p2 + 1;
        this.idx.push(p0, p1, p2, p1, p3, p2);
      }
    }
    return this;
  }

  // Swept tube through points, with a radius at each point. opts: color, color2 (along length),
  // sides, steps, flexAt, chain (phase delay along the tube; sweep grows from root to tip).
  limb(points, radii, opts = {}) {
    const sides = opts.sides ?? 6;
    const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(...p)), false, 'centripetal');
    const steps = opts.steps ?? Math.max(4, points.length * 3);
    const a = toRGB(opts.color ?? '#888888'), b = toRGB(opts.color2 ?? opts.color ?? '#888888');
    const start = this.pos.length / 3;
    const T = new THREE.Vector3(), prevT = new THREE.Vector3(), U = new THREE.Vector3(), V = new THREE.Vector3();
    const Q = new THREE.Quaternion();
    curve.getTangentAt(0, prevT);
    U.set(0, 1, 0);
    if (Math.abs(prevT.y) > 0.9) U.set(1, 0, 0);
    V.crossVectors(prevT, U).normalize();
    U.crossVectors(V, prevT).normalize();
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const c = curve.getPointAt(t);
      curve.getTangentAt(t, T);
      Q.setFromUnitVectors(prevT, T);
      U.applyQuaternion(Q); V.applyQuaternion(Q);
      prevT.copy(T);
      const f = t * (radii.length - 1), k = Math.min(Math.floor(f), radii.length - 2);
      const rad = radii[k] + (radii[k + 1] - radii[k]) * (f - k);
      const rgb = [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
      const w = opts.flexAt !== undefined ? smooth(opts.flexAt - 0.12, opts.flexAt + 0.12, t) : (opts.flexW ?? 0);
      const amp = opts.chain !== undefined ? t : 1, lag = opts.chain !== undefined ? t * opts.chain : 0;
      for (let j = 0; j <= sides; j++) {
        const ph = (j / sides) * Math.PI * 2, cs = Math.cos(ph), sn = Math.sin(ph);
        const n = [U.x * cs + V.x * sn, U.y * cs + V.y * sn, U.z * cs + V.z * sn];
        this.vertex([c.x + n[0] * rad, c.y + n[1] * rad, c.z + n[2] * rad], n, rgb, opts, w, amp, lag);
      }
    }
    for (let i = 0; i < steps; i++) {
      for (let j = 0; j < sides; j++) {
        const p0 = start + i * (sides + 1) + j, p1 = p0 + 1, p2 = p0 + sides + 1, p3 = p2 + 1;
        this.idx.push(p0, p2, p1, p1, p2, p3);
      }
    }
    return this;
  }

  // Mirror helper: builds a part on both sides of the X axis.
  both(fn) { fn(1); fn(-1); return this; }

  build() {
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(this.pos, 3));
    g.setAttribute('normal', new THREE.Float32BufferAttribute(this.nor, 3));
    g.setAttribute('color', new THREE.Float32BufferAttribute(this.rgb, 3));
    // WebGPU allows 8 vertex buffers per pipeline, so all rig data shares one.
    const ib = new THREE.InterleavedBuffer(new Float32Array(this.rig), STRIDE);
    g.setAttribute('aPivot', new THREE.InterleavedBufferAttribute(ib, 3, 0));
    g.setAttribute('aLimb', new THREE.InterleavedBufferAttribute(ib, 4, 3));
    g.setAttribute('aMat', new THREE.InterleavedBufferAttribute(ib, 4, 7));
    g.setAttribute('aJoint', new THREE.InterleavedBufferAttribute(ib, 3, 11));
    g.setAttribute('aBend', new THREE.InterleavedBufferAttribute(ib, 4, 14));
    g.setAttribute('aPose', new THREE.InterleavedBufferAttribute(ib, 4, 18));
    g.setAttribute('aFlop', new THREE.InterleavedBufferAttribute(ib, 1, 22));
    g.setIndex(this.idx);
    return g;
  }
}
