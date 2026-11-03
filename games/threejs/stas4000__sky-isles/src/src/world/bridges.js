// Rope bridges: sagging planks (walkable) + two tube ropes, gentle sway.
import * as THREE from 'three';
import { toonMaterial } from './toon.js';

const BRIDGE_LINKS = [
  ['home', 'meadow'],
  ['home', 'tree'],
  ['meadow', 'windmill'],
  ['temple', 'windmill'],
  ['stepping', 'lookout']
];

function buildBridge(a, b, rng) {
  const group = new THREE.Group();
  const dir = new THREE.Vector3().subVectors(b.pos, a.pos);
  const dist = dir.length();
  dir.normalize();
  const start = a.pos.clone().addScaledVector(dir, a.r - 0.4);
  const end = b.pos.clone().addScaledVector(dir, -(b.r - 0.4));
  const sag = Math.max(0.8, dist * 0.055);
  const mid = start.clone().lerp(end, 0.5);
  mid.y -= sag;
  const curve = new THREE.QuadraticBezierCurve3(start, mid, end);

  const span = start.distanceTo(end);
  const plankCount = Math.max(8, Math.round(span / 0.85));
  const plankGeo = new THREE.BoxGeometry(1.5, 0.09, 0.55);
  const plankMat = toonMaterial(0xd9b98f);
  const planks = [];
  const tmpT = new THREE.Vector3();
  for (let i = 0; i < plankCount; i++) {
    const t = (i + 0.5) / plankCount;
    const plank = new THREE.Mesh(plankGeo, plankMat);
    curve.getPoint(t, plank.position);
    curve.getTangent(t, tmpT);
    plank.lookAt(plank.position.clone().add(tmpT));
    plank.rotateZ(rng.float(-0.05, 0.05));
    plank.rotateY(rng.float(-0.06, 0.06));
    group.add(plank);
    planks.push(plank);
  }

  // two sagging rope rails offset to the sides, plus low guide ropes
  const perp = new THREE.Vector3(-dir.z, 0, dir.x).multiplyScalar(0.78);
  const ropeMat = toonMaterial(0x9a7bb8);
  for (const side of [-1, 1]) {
    const off = perp.clone().multiplyScalar(side);
    const s = start.clone().add(off);
    const e = end.clone().add(off);
    const m = mid.clone().add(off);
    // hand rail (raised) and deck rope (follows planks)
    const railCurve = new THREE.QuadraticBezierCurve3(
      s.clone().add(new THREE.Vector3(0, 1.05, 0)),
      m.clone().add(new THREE.Vector3(0, 0.55, 0)),
      e.clone().add(new THREE.Vector3(0, 1.05, 0))
    );
    group.add(new THREE.Mesh(new THREE.TubeGeometry(railCurve, 20, 0.045, 5), ropeMat));
    const deckCurve = new THREE.QuadraticBezierCurve3(s, m, e);
    group.add(new THREE.Mesh(new THREE.TubeGeometry(deckCurve, 20, 0.035, 5), ropeMat));
    // vertical ties every few planks
    for (let i = 1; i < plankCount; i += 3) {
      const t = i / plankCount;
      const top = railCurve.getPoint(t);
      const bottom = deckCurve.getPoint(t);
      const tieCurve = new THREE.LineCurve3(top, bottom);
      group.add(new THREE.Mesh(new THREE.TubeGeometry(tieCurve, 1, 0.02, 4), ropeMat));
    }
  }

  return { group, planks, phase: rng.float(0, Math.PI * 2) };
}

export function buildBridges(scene, islands, rng) {
  const byName = new Map(islands.map((i) => [i.name, i]));
  const bridges = [];
  const colliders = [];
  for (const [aName, bName] of BRIDGE_LINKS) {
    const bridge = buildBridge(byName.get(aName), byName.get(bName), rng);
    scene.add(bridge.group);
    bridges.push(bridge);
    colliders.push(...bridge.planks);
  }
  return {
    bridges,
    colliders,
    update(t) {
      for (const b of bridges) {
        b.group.rotation.z = Math.sin(t * 0.6 + b.phase) * 0.004;
        b.group.rotation.x = Math.cos(t * 0.45 + b.phase) * 0.003;
      }
    }
  };
}
