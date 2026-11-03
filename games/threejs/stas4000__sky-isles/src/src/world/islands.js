// The nine floating isles: layered rock bases, mint grass tops, scattered
// props, murals on the home isle, and glowing jump pads.
import * as THREE from 'three';
import { toonMaterial, addOutline } from './toon.js';
import { CHIMES, MURAL_ORDER } from '../sim/puzzle.js';
import { muralTexture } from './textures.js';

export const ISLANDS = [
  { name: 'home', x: 0, y: 0, z: 0, r: 9 },
  { name: 'tree', x: 26, y: 5, z: -14, r: 7 },
  { name: 'temple', x: -24, y: 10, z: -20, r: 8 },
  { name: 'koi', x: 18, y: 8, z: 22, r: 7 },
  { name: 'meadow', x: -14, y: 3, z: 18, r: 6 },
  { name: 'windmill', x: -30, y: 8, z: 4, r: 6 },
  { name: 'crystal', x: 34, y: 13, z: 4, r: 5 },
  { name: 'lookout', x: 2, y: 14, z: -30, r: 5 },
  { name: 'stepping', x: 14, y: 11, z: -26, r: 3.5 }
];

const GRASS = 0x8fdcb4;
const GRASS_DARK = 0x6fc79c;
const ROCK_A = 0xbfaede;
const ROCK_B = 0xa491c8;
const ROCK_C = 0x8a76b4;

function buildRockBase(r, depth) {
  const group = new THREE.Group();
  const upper = new THREE.Mesh(
    new THREE.CylinderGeometry(r * 0.92, r * 0.58, depth * 0.42, 12),
    toonMaterial(ROCK_A)
  );
  upper.position.y = -depth * 0.21;
  addOutline(upper, 0.02);
  group.add(upper);

  const mid = new THREE.Mesh(
    new THREE.CylinderGeometry(r * 0.6, r * 0.34, depth * 0.3, 10),
    toonMaterial(ROCK_B)
  );
  mid.position.y = -depth * 0.42 - depth * 0.13;
  group.add(mid);

  const tip = new THREE.Mesh(
    new THREE.CylinderGeometry(r * 0.34, 0.12, depth * 0.42, 8),
    toonMaterial(ROCK_C)
  );
  tip.position.y = -depth * 0.57 - depth * 0.19;
  group.add(tip);

  // embedded pebble rings for a layered strata feel
  for (let i = 0; i < 5; i++) {
    const a = (i / 5) * Math.PI * 2 + r;
    const pebble = new THREE.Mesh(
      new THREE.DodecahedronGeometry(r * 0.09, 0),
      toonMaterial(ROCK_B)
    );
    pebble.position.set(Math.cos(a) * r * 0.72, -depth * (0.2 + (i % 3) * 0.18), Math.sin(a) * r * 0.72);
    group.add(pebble);
  }
  return group;
}

function buildFlower(rng) {
  const g = new THREE.Group();
  const stem = new THREE.Mesh(
    new THREE.CylinderGeometry(0.02, 0.03, 0.32, 5),
    toonMaterial(0x6fbf92)
  );
  stem.position.y = 0.16;
  g.add(stem);
  const head = new THREE.Mesh(
    new THREE.SphereGeometry(0.1, 8, 6),
    toonMaterial(rng.pick([0xf2b8c6, 0xcdb4f0, 0xfff3d6, 0xffffff]))
  );
  head.position.y = 0.36;
  g.add(head);
  return g;
}

function scatterProps(islandGroup, r, rng, density = 1) {
  const count = Math.round((6 + r) * density);
  for (let i = 0; i < count; i++) {
    const a = rng.float(0, Math.PI * 2);
    const d = rng.float(r * 0.25, r * 0.82);
    const kind = rng.float();
    let prop;
    if (kind < 0.45) {
      prop = buildFlower(rng);
    } else if (kind < 0.75) {
      prop = new THREE.Mesh(
        new THREE.DodecahedronGeometry(rng.float(0.14, 0.34), 0),
        toonMaterial(0xcabfdd)
      );
      prop.rotation.set(rng.float(0, 3), rng.float(0, 3), rng.float(0, 3));
      prop.position.y = 0.1;
    } else {
      prop = new THREE.Mesh(
        new THREE.SphereGeometry(rng.float(0.3, 0.55), 10, 8),
        toonMaterial(GRASS_DARK)
      );
      addOutline(prop, 0.05);
      prop.scale.y = 0.75;
      prop.position.y = 0.2;
    }
    prop.position.x = Math.cos(a) * d;
    prop.position.z = Math.sin(a) * d;
    islandGroup.add(prop);
  }
}

// Glowing mushroom jump pad. userData.jumpPad marks it for the player sim.
function buildJumpPad(color = 0xf2b8c6) {
  const g = new THREE.Group();
  const stem = new THREE.Mesh(
    new THREE.CylinderGeometry(0.22, 0.34, 0.5, 10),
    toonMaterial(0xfff3d6)
  );
  stem.position.y = 0.25;
  g.add(stem);
  const cap = new THREE.Mesh(
    new THREE.SphereGeometry(0.62, 16, 10, 0, Math.PI * 2, 0, Math.PI * 0.5),
    new THREE.MeshToonMaterial({ color, emissive: color, emissiveIntensity: 0.55 })
  );
  cap.position.y = 0.48;
  cap.scale.y = 0.72;
  addOutline(cap, 0.05);
  g.add(cap);
  const halo = new THREE.Mesh(
    new THREE.TorusGeometry(0.72, 0.045, 8, 32),
    new THREE.MeshBasicMaterial({
      color,
      transparent: true,
      opacity: 0.65,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    })
  );
  halo.rotation.x = Math.PI / 2;
  halo.position.y = 0.56;
  g.add(halo);
  cap.userData.jumpPad = { strength: 15.5, group: g, cap, halo, pulse: 0 };
  return { group: g, pad: cap.userData.jumpPad };
}

// Mural wall on the home isle: 5 panels painted with the chime sequence.
function buildMurals() {
  const group = new THREE.Group();
  const panels = [];
  MURAL_ORDER.forEach((chimeIdx, i) => {
    const chime = CHIMES[chimeIdx];
    const panel = new THREE.Mesh(
      new THREE.BoxGeometry(1.25, 1.5, 0.14),
      new THREE.MeshBasicMaterial({ map: muralTexture(chime.symbol, chime.color) })
    );
    addOutline(panel, 0.03);
    const a = -0.55 + i * 0.275; // gentle arc
    panel.position.set(Math.sin(a) * 6.4, 1.05, -Math.cos(a) * 6.4);
    panel.lookAt(0, 1.05, 0);
    group.add(panel);
    // small stone plinth under each panel
    const plinth = new THREE.Mesh(
      new THREE.CylinderGeometry(0.42, 0.52, 0.34, 8),
      toonMaterial(ROCK_A)
    );
    plinth.position.copy(panel.position);
    plinth.position.y = 0.17;
    group.add(plinth);
    panels.push(panel);
  });
  return { group, panels };
}

export function buildIslands(scene, rng) {
  const group = new THREE.Group();
  const colliders = [];
  const islands = [];
  const jumpPads = [];

  for (const def of ISLANDS) {
    const isle = new THREE.Group();
    isle.position.set(def.x, def.y, def.z);

    const grass = new THREE.Mesh(
      new THREE.CylinderGeometry(def.r, def.r * 0.9, 1.1, 28),
      toonMaterial(GRASS)
    );
    grass.position.y = -0.55;
    addOutline(grass, 0.018);
    grass.userData.island = def.name;
    isle.add(grass);
    colliders.push(grass);

    const depth = 3.2 + def.r * 0.55;
    const rock = buildRockBase(def.r, depth);
    rock.position.y = -1.05;
    isle.add(rock);

    if (def.name !== 'stepping') {
      scatterProps(isle, def.r, rng, def.name === 'home' ? 0.6 : 1);
    }

    group.add(isle);
    islands.push({
      name: def.name,
      r: def.r,
      pos: new THREE.Vector3(def.x, def.y, def.z),
      group: isle,
      grass
    });
  }

  // murals on the home isle
  const home = islands[0];
  const murals = buildMurals();
  home.group.add(murals.group);

  // jump pads: home (toward koi), tree (toward stepping), koi (toward crystal)
  const padDefs = [
    { island: 'home', angle: Math.atan2(22, 18), dist: 6.2, strength: 16.5 },
    { island: 'tree', angle: Math.atan2(-12, -12), dist: 4.6, strength: 15 },
    { island: 'koi', angle: Math.atan2(-18, 16), dist: 4.6, strength: 15 }
  ];
  for (const pd of padDefs) {
    const isle = islands.find((i) => i.name === pd.island);
    const { group: padGroup, pad } = buildJumpPad();
    pad.strength = pd.strength;
    padGroup.position.set(Math.cos(pd.angle) * pd.dist, 0, Math.sin(pd.angle) * pd.dist);
    isle.group.add(padGroup);
    colliders.push(pad.cap);
    jumpPads.push(pad);
  }

  scene.add(group);
  return { group, colliders, islands, jumpPads, murals: murals.panels };
}

export function updateJumpPads(jumpPads, t, dt) {
  for (const pad of jumpPads) {
    pad.pulse = Math.max(0, pad.pulse - dt * 2.2);
    const s = 1 + pad.pulse * 0.45 + Math.sin(t * 2.4) * 0.04;
    pad.cap.scale.set(s, 0.72 * (1 + pad.pulse * 0.3), s);
    pad.halo.scale.setScalar(1 + pad.pulse * 0.8);
    pad.halo.material.opacity = 0.4 + 0.3 * Math.sin(t * 2.4) + pad.pulse * 0.3;
  }
}
