// Set dressing: a perimeter fence, dead trees outside it, and low scenery inside. Nothing here
// collides, and everything inside the fence stays under knee height so it never hides a creature.
import * as THREE from 'three/webgpu';
import { attribute, uniform, mix, smoothstep, normalWorld, positionGeometry, vec3, float } from 'three/tsl';
import { ARENA, OUTER } from '../config.js';
import { Rig } from './rig.js';
import { mulberry32, TAU } from '../core/util.js';

const FENCE = ARENA + 0.8;
const WHITE = '#ffffff';

function treeGeometry(seed) {
  const rng = mulberry32(seed), r = new Rig();
  const branch = (p, d, len, rad, depth) => {
    const q = [p[0] + d[0] * len, p[1] + d[1] * len, p[2] + d[2] * len];
    const m = [(p[0] + q[0]) / 2 + (rng() - 0.5) * len * 0.3, (p[1] + q[1]) / 2, (p[2] + q[2]) / 2 + (rng() - 0.5) * len * 0.3];
    r.limb([p, m, q], [rad, rad * 0.8, rad * 0.55], { color: WHITE, sides: depth > 1 ? 5 : 4, steps: 4, rough: 0.85, mottle: 0.5 });
    if (depth <= 0) return;
    const kids = 2 + (rng() < 0.4 ? 1 : 0);
    for (let k = 0; k < kids; k++) {
      const a = rng() * TAU, spread = 0.5 + rng() * 0.5;
      const nd = [d[0] + Math.cos(a) * spread, d[1] * (0.6 + rng() * 0.4), d[2] + Math.sin(a) * spread];
      const l = Math.hypot(...nd);
      branch(q, nd.map((v) => v / l), len * (0.62 + rng() * 0.16), rad * 0.62, depth - 1);
    }
  };
  branch([0, -0.2, 0], [0, 1, 0], 3.2, 0.42, 3);
  return r.build();
}

function ribsGeometry() {
  const r = new Rig();
  const spine = [[0, 0.1, -3.2], [0.1, 0.36, -1.6], [-0.05, 0.42, 0], [0.08, 0.34, 1.6], [0, 0.14, 3]];
  r.limb(spine, [0.08, 0.15, 0.17, 0.15, 0.1], { color: WHITE, sides: 6, steps: 18, rough: 0.7, mottle: 0.45 });
  for (let i = 0; i < 8; i++) {
    const z = -2.3 + i * 0.68, w = 1.1 - Math.abs(i - 3.5) * 0.11;
    r.both((s) => r.limb([[0, 0.38, z], [s * w * 0.8, 0.72, z + 0.1], [s * w * 1.25, 0.4, z + 0.2], [s * w * 1.3, 0, z + 0.25]], [0.07, 0.06, 0.05, 0.02], { color: WHITE, sides: 5, steps: 10, rough: 0.7, mottle: 0.45 }));
  }
  r.blob([0, 0.3, 3.5], [0.55, 0.42, 0.75], { color: WHITE, rough: 0.6, mottle: 0.5 });
  r.both((s) => r.limb([[s * 0.34, 0.5, 3.2], [s * 0.9, 0.75, 3.1], [s * 1.25, 0.7, 3.6]], [0.1, 0.07, 0.01], { color: WHITE, sides: 5, rough: 0.6 }));
  return r.build();
}

function stumpGeometry() {
  const r = new Rig();
  r.limb([[0, -0.1, 0], [0.03, 0.34, 0.02], [0, 0.58, 0]], [0.46, 0.33, 0.27], { color: WHITE, sides: 7, steps: 6, rough: 0.85, mottle: 0.6 });
  for (let i = 0; i < 5; i++) {
    const a = i * 1.26 + 0.2, x = Math.cos(a), z = Math.sin(a);
    r.limb([[x * 0.22, 0.26, z * 0.22], [x * 0.62, 0.06, z * 0.62], [x * 0.98, -0.05, z * 0.98]], [0.14, 0.09, 0.02], { color: WHITE, sides: 5, steps: 5, rough: 0.85, mottle: 0.6 });
  }
  return r.build();
}

function shardGeometry() {
  const r = new Rig();
  const spike = (x, z, h, w, lean) => r.limb([[x, -0.05, z], [x + lean, h * 0.55, z + lean * 0.4], [x + lean * 1.4, h, z + lean * 0.6]], [w, w * 0.62, 0.008], { color: WHITE, sides: 4, steps: 3, rough: 0.28, mottle: 0.2 });
  spike(0, 0, 0.95, 0.24, 0.1); spike(0.3, 0.14, 0.62, 0.17, 0.2); spike(-0.26, 0.2, 0.5, 0.15, -0.16); spike(0.05, -0.32, 0.72, 0.16, -0.08); spike(-0.2, -0.18, 0.38, 0.12, -0.12);
  return r.build();
}

function postGeometry() {
  const r = new Rig();
  r.limb([[0, -0.1, 0], [0.02, 0.8, 0], [0, 1.55, 0.02]], [0.09, 0.075, 0.06], { color: WHITE, sides: 5, steps: 4, rough: 0.85, mottle: 0.6 });
  return r.build();
}

// A unit length of wire along +X, sagging in the middle.
function wireGeometry() {
  const r = new Rig();
  r.limb([[0, 0, 0], [0.5, -0.09, 0], [1, 0, 0]], [0.03, 0.03, 0.03], { color: WHITE, sides: 3, steps: 6, rough: 0.5, mottle: 0.3 });
  return r.build();
}

export class Props {
  constructor(stage) {
    this.stage = stage;
    this.u = {
      woodA: uniform(new THREE.Color()), woodB: uniform(new THREE.Color()),
      boneA: uniform(new THREE.Color()), boneB: uniform(new THREE.Color()),
      lowA: uniform(new THREE.Color()), lowB: uniform(new THREE.Color()),
      metal: uniform(new THREE.Color()), ember: uniform(0),
    };
    const rng = this.rng = mulberry32(2718);
    const { u } = this;
    this.trees = [treeGeometry(11), treeGeometry(23)].map((g, i) => this.scatter(g, this.material(u.woodA, u.woodB), 17, (M) => this.outside(M, 0.7 + rng() * 0.75, i), true));
    this.ribs = this.scatter(ribsGeometry(), this.material(u.boneA, u.boneB), 7, (M) => this.inside(M, 0.75 + rng() * 0.5, 0.05), true);
    this.stumps = this.scatter(stumpGeometry(), this.material(u.woodA, u.woodB), 26, (M) => this.inside(M, 0.7 + rng() * 0.7, 0), true);
    this.shards = this.scatter(shardGeometry(), this.material(u.lowA, u.lowB, true), 34, (M) => this.inside(M, 0.7 + rng() * 1, 0), true);
    this.buildFence();
  }

  // Top faces pick up the second colour, which reads as snow, ash or moss on the upper surfaces.
  material(a, b, ember = false) {
    const m = new THREE.MeshStandardNodeMaterial();
    m.colorNode = mix(a, b, smoothstep(0.1, 0.8, normalWorld.y)).mul(attribute('color', 'vec3'));
    m.roughnessNode = attribute('aMat', 'vec4').x;
    m.metalnessNode = float(0);
    if (ember) m.emissiveNode = vec3(2.2, 0.5, 0.08).mul(smoothstep(0.1, 0.8, positionGeometry.y)).mul(this.u.ember);
    return m;
  }

  scatter(geometry, material, count, place, shadow) {
    const mesh = new THREE.InstancedMesh(geometry, material, count);
    const M = new THREE.Matrix4();
    for (let i = 0; i < count; i++) { place(M); mesh.setMatrixAt(i, M); }
    mesh.castShadow = shadow && this.stage.tier.shadow > 0;
    mesh.frustumCulled = false;
    this.stage.scene.add(mesh);
    return mesh;
  }

  compose(M, x, y, z, yaw, s, sy = s) {
    return M.compose(new THREE.Vector3(x, y, z), new THREE.Quaternion().setFromEuler(new THREE.Euler(0, yaw, 0)), new THREE.Vector3(s, sy, s));
  }

  // Beyond the fence, in the dark band.
  outside(M, s) {
    const { rng } = this, side = Math.floor(rng() * 4), t = (rng() * 2 - 1) * (OUTER - 3), d = FENCE + 2 + rng() * 11;
    const x = side < 2 ? (side ? d : -d) : t, z = side < 2 ? t : (side === 2 ? d : -d);
    return this.compose(M, x, 0, z, rng() * TAU, s);
  }

  // Inside the arena, clear of the middle where a run begins.
  inside(M, s, y) {
    const { rng } = this;
    let x, z;
    do { x = (rng() * 2 - 1) * (ARENA - 3); z = (rng() * 2 - 1) * (ARENA - 3); } while (Math.hypot(x, z) < 9);
    return this.compose(M, x, y, z, rng() * TAU, s);
  }

  buildFence() {
    const { rng, u } = this, posts = [], wires = [];
    const step = 3.6, n = Math.floor((FENCE * 2) / step);
    for (let side = 0; side < 4; side++) {
      for (let i = 0; i <= n; i++) {
        if (rng() < 0.12) continue;     // gaps where the horde broke through
        const t = -FENCE + i * step + (rng() - 0.5) * 0.5;
        const x = side === 0 ? t : side === 1 ? t : side === 2 ? -FENCE : FENCE;
        const z = side === 0 ? -FENCE : side === 1 ? FENCE : t;
        posts.push({ x: x + (rng() - 0.5) * 0.2, z: z + (rng() - 0.5) * 0.2, side, lean: (rng() - 0.5) * 0.2 });
      }
    }
    const postMesh = this.scatter(postGeometry(), this.material(u.woodA, u.woodB), posts.length, (() => {
      let i = 0;
      return (M) => {
        const p = posts[i++];
        M.compose(new THREE.Vector3(p.x, 0, p.z), new THREE.Quaternion().setFromEuler(new THREE.Euler(p.lean, rng() * TAU, p.lean * 0.7)), new THREE.Vector3(1, 0.85 + rng() * 0.3, 1));
      };
    })(), true);
    this.posts = postMesh;
    for (let i = 0; i + 1 < posts.length; i++) {
      const a = posts[i], b = posts[i + 1];
      if (a.side !== b.side) continue;
      const dx = b.x - a.x, dz = b.z - a.z, l = Math.hypot(dx, dz);
      if (l > step * 1.6) continue;     // the wire is down across a gap
      for (const y of [0.72, 1.18]) if (rng() > 0.1) wires.push({ x: a.x, y: y + (rng() - 0.5) * 0.06, z: a.z, yaw: -Math.atan2(dz, dx), l });
    }
    const wireMat = new THREE.MeshStandardNodeMaterial();
    wireMat.colorNode = u.metal;
    wireMat.roughness = 0.55;
    this.wires = this.scatter(wireGeometry(), wireMat, wires.length, (() => {
      let i = 0;
      return (M) => {
        const w = wires[i++];
        M.compose(new THREE.Vector3(w.x, w.y, w.z), new THREE.Quaternion().setFromEuler(new THREE.Euler(0, w.yaw, 0)), new THREE.Vector3(w.l, 1, 1));
      };
    })(), false);
  }

  setBiome(b) {
    const p = b.props, { u } = this;
    u.woodA.value.set(p.wood[0]); u.woodB.value.set(p.wood[1]);
    u.boneA.value.set(p.bone[0]); u.boneB.value.set(p.bone[1]);
    u.lowA.value.set(p.low[0]); u.lowB.value.set(p.low[1]);
    u.metal.value.set(p.metal);
    u.ember.value = p.ember ?? 0;
    this.stumps.visible = !!p.stumps;
    this.shards.visible = !!p.shards;
  }
}
