// Five wind chimes hanging from small wooden frames across the isles.
// Proximity highlight, gentle sway, and a colored note per chime.
import * as THREE from 'three';
import { toonMaterial, addOutline } from './toon.js';
import { CHIMES } from '../sim/puzzle.js';

// which island each chime lives on + local placement
const CHIME_SPOTS = [
  { island: 'home', x: 4.6, z: 3.6 },
  { island: 'meadow', x: 1.8, z: -2.4 },
  { island: 'windmill', x: 2.6, z: 2.2 },
  { island: 'crystal', x: -2.2, z: 2.4 },
  { island: 'lookout', x: -1.6, z: 2.2 }
];

export const CHIME_RANGE = 3;

function buildChime(index) {
  const chime = CHIMES[index];
  const group = new THREE.Group();
  const wood = toonMaterial(0xb08a6a);

  // frame: two posts + crossbar
  for (const side of [-1, 1]) {
    const post = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.09, 2.3, 6), wood);
    post.position.set(side * 0.7, 1.15, 0);
    group.add(post);
  }
  const bar = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.06, 1.7, 6), wood);
  bar.rotation.z = Math.PI / 2;
  bar.position.y = 2.3;
  group.add(bar);

  // swinging assembly
  const swing = new THREE.Group();
  swing.position.y = 2.3;
  group.add(swing);

  const crown = new THREE.Mesh(
    new THREE.CylinderGeometry(0.3, 0.34, 0.12, 10),
    toonMaterial(new THREE.Color(chime.color).getHex())
  );
  crown.position.y = -0.35;
  addOutline(crown, 0.05);
  swing.add(crown);

  const tubeMat = new THREE.MeshToonMaterial({
    color: 0xfdf6ea,
    emissive: new THREE.Color(chime.color),
    emissiveIntensity: 0.15
  });
  const tubes = [];
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * Math.PI * 2;
    const len = 0.5 + (i % 2) * 0.16;
    const tube = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.045, len, 8), tubeMat);
    tube.position.set(Math.cos(a) * 0.18, -0.45 - len / 2, Math.sin(a) * 0.18);
    swing.add(tube);
    tubes.push(tube);
  }
  // hanging clapper + colored sail
  const sail = new THREE.Mesh(
    new THREE.CircleGeometry(0.14, 12),
    new THREE.MeshToonMaterial({
      color: new THREE.Color(chime.color).getHex(),
      emissive: new THREE.Color(chime.color),
      emissiveIntensity: 0.5,
      side: THREE.DoubleSide
    })
  );
  sail.position.y = -1.35;
  swing.add(sail);

  // soft glow halo shown when the player is near
  const halo = new THREE.Sprite(new THREE.SpriteMaterial({
    color: new THREE.Color(chime.color),
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  }));
  halo.scale.set(2.4, 2.4, 1);
  halo.position.y = 1.6;
  group.add(halo);

  return { group, swing, tubes, sail, halo, index, chime };
}

export function buildChimes(islands) {
  const byName = new Map(islands.map((i) => [i.name, i]));
  const chimes = [];
  const hitMeshes = [];
  for (let i = 0; i < CHIME_SPOTS.length; i++) {
    const spot = CHIME_SPOTS[i];
    const c = buildChime(i);
    c.group.position.set(spot.x, 0, spot.z);
    byName.get(spot.island).group.add(c.group);
    c.group.updateWorldMatrix(true, true);
    c.worldPos = new THREE.Vector3();
    c.group.getWorldPosition(c.worldPos);
    c.worldPos.y += 1.6;
    c.highlight = 0;
    c.playPulse = 0;
    // generous invisible hit target for taps
    const hit = new THREE.Mesh(
      new THREE.SphereGeometry(1.3, 8, 6),
      new THREE.MeshBasicMaterial({ visible: false })
    );
    hit.position.y = 1.6;
    hit.userData.chimeIndex = i;
    c.group.add(hit);
    hitMeshes.push(hit);
    chimes.push(c);
  }

  return {
    chimes,
    hitMeshes,
    // returns nearest chime within range, or null
    nearest(pos) {
      let best = null;
      let bestD = CHIME_RANGE;
      for (const c of chimes) {
        const d = c.worldPos.distanceTo(pos);
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      return best;
    },
    update(t, dt, playerPos) {
      for (const c of chimes) {
        const near = playerPos && c.worldPos.distanceTo(playerPos) < CHIME_RANGE;
        c.highlight += ((near ? 1 : 0) - c.highlight) * Math.min(1, dt * 6);
        c.playPulse = Math.max(0, c.playPulse - dt * 1.6);
        c.halo.material.opacity = c.highlight * 0.5 + c.playPulse * 0.45;
        const sway = Math.sin(t * 1.4 + c.index * 2.1) * 0.06;
        const ring = c.playPulse * Math.sin(t * 14) * 0.3;
        c.swing.rotation.z = sway + ring;
        c.swing.rotation.x = Math.cos(t * 1.1 + c.index) * 0.05 + ring * 0.6;
        const s = 1 + c.highlight * 0.12 + c.playPulse * 0.2;
        c.swing.scale.setScalar(s);
      }
    }
  };
}
