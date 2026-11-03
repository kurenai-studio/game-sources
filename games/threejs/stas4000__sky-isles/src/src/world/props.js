// Signature island features: ancient tree with falling glow-leaves, ruined
// marble temple with orbiting rune stones, koi pond with an impossible
// waterfall, windmill, crystal cluster, lookout gazebo.
import * as THREE from 'three';
import { toonMaterial, addOutline, puffTexture, canvasTexture } from './toon.js';
import { runeTexture, waterfallTexture } from './textures.js';
import { CHIMES } from '../sim/puzzle.js';

// ---------- ancient tree ----------
function buildTree(rng) {
  const group = new THREE.Group();
  const trunkMat = toonMaterial(0xb08a6a);
  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.55, 1.05, 5.2, 10), trunkMat);
  trunk.position.y = 2.6;
  addOutline(trunk, 0.03);
  group.add(trunk);
  // a few reaching branches
  for (let i = 0; i < 4; i++) {
    const a = rng.float(0, Math.PI * 2);
    const branch = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.24, 2.4, 6), trunkMat);
    branch.position.set(Math.cos(a) * 0.9, 4.4 + rng.float(0, 0.8), Math.sin(a) * 0.9);
    branch.rotation.z = Math.cos(a) * 0.8;
    branch.rotation.x = -Math.sin(a) * 0.8;
    group.add(branch);
  }
  // big layered canopy
  const canopyColors = [0xa8e6cf, 0xbef0d8, 0xcdf5e2, 0xb4ebce];
  for (let i = 0; i < 5; i++) {
    const blob = new THREE.Mesh(
      new THREE.SphereGeometry(rng.float(1.7, 2.6), 14, 10),
      toonMaterial(canopyColors[i % canopyColors.length])
    );
    const a = (i / 5) * Math.PI * 2;
    blob.position.set(Math.cos(a) * (i === 0 ? 0 : 1.5), 5.9 + (i % 2) * 0.9, Math.sin(a) * (i === 0 ? 0 : 1.5));
    addOutline(blob, 0.035);
    group.add(blob);
  }

  // continuously falling glowing leaves (instanced planes, additive)
  const LEAVES = 110;
  const leafTex = canvasTexture(64, (ctx, s) => {
    ctx.clearRect(0, 0, s, s);
    ctx.translate(s / 2, s / 2);
    ctx.fillStyle = 'rgba(216,255,233,0.95)';
    ctx.beginPath();
    ctx.moveTo(0, -s * 0.42);
    ctx.bezierCurveTo(s * 0.36, -s * 0.12, s * 0.24, s * 0.24, 0, s * 0.42);
    ctx.bezierCurveTo(-s * 0.24, s * 0.24, -s * 0.36, -s * 0.12, 0, -s * 0.42);
    ctx.fill();
  });
  const leafGeo = new THREE.PlaneGeometry(0.17, 0.17);
  const leafMat = new THREE.MeshBasicMaterial({
    map: leafTex,
    color: 0xcfffe6,
    transparent: true,
    opacity: 0.8,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    side: THREE.DoubleSide
  });
  const leaves = new THREE.InstancedMesh(leafGeo, leafMat, LEAVES);
  leaves.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  leaves.frustumCulled = false;
  group.add(leaves);
  const state = [];
  for (let i = 0; i < LEAVES; i++) {
    state.push({
      angle: rng.float(0, Math.PI * 2),
      radius: rng.float(0.4, 2.6),
      y: rng.float(0.2, 6.2), // height above the island surface
      fall: rng.float(0.35, 0.8),
      spin: rng.float(0.6, 2.2),
      drift: rng.float(0.15, 0.5)
    });
  }
  return { group, leaves, leafState: state };
}

// ---------- ruined temple ----------
function buildTemple(rng) {
  const group = new THREE.Group();
  const marble = toonMaterial(0xfff3d6);
  // plinth
  const plinth = new THREE.Mesh(new THREE.CylinderGeometry(5.2, 5.6, 0.5, 20), toonMaterial(0xf3e4c4));
  plinth.position.y = 0.25;
  addOutline(plinth, 0.02);
  group.add(plinth);
  // broken columns in a ring
  for (let i = 0; i < 7; i++) {
    const a = (i / 7) * Math.PI * 2;
    const h = rng.pick([1.6, 2.4, 3.4, 4.2]);
    const col = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.4, h, 10), marble);
    col.position.set(Math.cos(a) * 4.1, 0.5 + h / 2, Math.sin(a) * 4.1);
    col.rotation.z = rng.float(-0.06, 0.06);
    addOutline(col, 0.03);
    group.add(col);
    if (rng.chance(0.5)) {
      const cap = new THREE.Mesh(new THREE.BoxGeometry(0.95, 0.22, 0.95), marble);
      cap.position.set(Math.cos(a) * 4.1, 0.5 + h + 0.11, Math.sin(a) * 4.1);
      cap.rotation.y = a;
      group.add(cap);
    }
  }
  // a fallen column
  const fallen = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.4, 3.2, 10), marble);
  fallen.rotation.set(Math.PI / 2, 0, 0.7);
  fallen.position.set(1.6, 0.85, 2.2);
  addOutline(fallen, 0.03);
  group.add(fallen);

  // 5 floating rune stones slowly orbiting the center
  const runes = new THREE.Group();
  const stones = [];
  for (let i = 0; i < 5; i++) {
    const chime = CHIMES[i];
    const stone = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.55, 0),
      new THREE.MeshToonMaterial({
        map: runeTexture(chime.symbol, chime.color),
        emissive: new THREE.Color(chime.color),
        emissiveMap: runeTexture(chime.symbol, chime.color),
        emissiveIntensity: 0.9
      })
    );
    stone.scale.y = 1.45;
    addOutline(stone, 0.04);
    const a = (i / 5) * Math.PI * 2;
    stone.position.set(Math.cos(a) * 2.2, 3.6 + (i % 2) * 0.35, Math.sin(a) * 2.2);
    runes.add(stone);
    stones.push({ mesh: stone, baseY: stone.position.y, phase: i * 1.3 });
  }
  group.add(runes);
  return { group, runes, stones };
}

// ---------- koi pond + impossible waterfall ----------
function buildPond(islandR) {
  const group = new THREE.Group();
  // pond basin: shallow disc sunk into the grass
  const pond = new THREE.Mesh(
    new THREE.CircleGeometry(2.6, 28),
    new THREE.MeshToonMaterial({ color: 0x8fd8f0, transparent: true, opacity: 0.85 })
  );
  pond.rotation.x = -Math.PI / 2;
  pond.position.set(-1.4, 0.06, 0.6);
  group.add(pond);
  // ripple rings
  const rings = [];
  for (let i = 0; i < 3; i++) {
    const ring = new THREE.Mesh(
      new THREE.RingGeometry(0.4, 0.5, 24),
      new THREE.MeshBasicMaterial({
        color: 0xffffff,
        transparent: true,
        opacity: 0.5,
        depthWrite: false,
        side: THREE.DoubleSide
      })
    );
    ring.rotation.x = -Math.PI / 2;
    ring.position.copy(pond.position);
    ring.position.y = 0.08;
    group.add(ring);
    rings.push(ring);
  }
  // rim stones
  for (let i = 0; i < 9; i++) {
    const a = (i / 9) * Math.PI * 2;
    const stone = new THREE.Mesh(
      new THREE.DodecahedronGeometry(0.22, 0),
      toonMaterial(0xcabfdd)
    );
    stone.position.set(pond.position.x + Math.cos(a) * 2.7, 0.12, pond.position.z + Math.sin(a) * 2.7);
    group.add(stone);
  }

  // koi fish swimming in circles
  const koi = [];
  const koiColors = [0xffb3c1, 0xfff3d6, 0xcdb4f0];
  for (let i = 0; i < 3; i++) {
    const fish = new THREE.Group();
    const body = new THREE.Mesh(
      new THREE.SphereGeometry(0.16, 10, 8),
      toonMaterial(koiColors[i])
    );
    body.scale.set(1.6, 0.7, 0.8);
    fish.add(body);
    const tail = new THREE.Mesh(
      new THREE.ConeGeometry(0.09, 0.22, 6),
      toonMaterial(koiColors[i])
    );
    tail.rotation.z = Math.PI / 2;
    tail.position.x = -0.3;
    fish.add(tail);
    group.add(fish);
    koi.push({ mesh: fish, angle: (i / 3) * Math.PI * 2, radius: 1.1 + i * 0.45, speed: 0.7 + i * 0.22, dir: i % 2 ? 1 : -1 });
  }

  // the pond impossibly spills over the island edge at one clear lip
  const lipAngle = Math.atan2(pond.position.z, pond.position.x);
  const lipDir = new THREE.Vector3(Math.cos(lipAngle), 0, Math.sin(lipAngle));
  const lip = pond.position.clone().addScaledVector(lipDir, islandR - 0.15);
  lip.y = 0.05;

  // short, clearly-contained stream channel from the pond edge to the lip
  const pondR = 2.6;
  const channelLen = islandR - 0.15 - pondR - 0.35;
  const chanGeo = new THREE.PlaneGeometry(1.05, channelLen);
  chanGeo.rotateX(-Math.PI / 2);
  const stream = new THREE.Mesh(
    chanGeo,
    new THREE.MeshBasicMaterial({
      color: 0x8fd8f0,
      transparent: true,
      opacity: 0.9,
      depthWrite: false
    })
  );
  const chanMid = pond.position.clone().addScaledVector(lipDir, pondR + 0.3 + channelLen / 2);
  stream.position.set(chanMid.x, 0.055, chanMid.z);
  stream.rotation.y = Math.atan2(lipDir.x, lipDir.z);
  group.add(stream);
  // little stone banks so the channel reads as carved into the grass
  const perp = new THREE.Vector3(-lipDir.z, 0, lipDir.x);
  for (let i = 0; i < 3; i++) {
    for (const side of [-1, 1]) {
      const bank = new THREE.Mesh(
        new THREE.DodecahedronGeometry(0.16, 0),
        toonMaterial(0xcabfdd)
      );
      const along = pondR + 0.55 + (i / 2) * (channelLen - 0.6);
      const p = pond.position.clone().addScaledVector(lipDir, along).addScaledVector(perp, side * 0.68);
      bank.position.set(p.x, 0.1, p.z);
      group.add(bank);
    }
  }

  // wide soft ribbon of falling water from the lip down into the clouds
  const fallTex = waterfallTexture();
  const fallHeight = 46;
  const fallMat = new THREE.MeshBasicMaterial({
    map: fallTex,
    color: 0xbfe4f5,
    transparent: true,
    opacity: 0.9,
    depthWrite: false,
    side: THREE.DoubleSide
  });
  const ribbonGeo = new THREE.PlaneGeometry(3.2, fallHeight, 1, 8);
  const fall = new THREE.Group();
  const ribbonA = new THREE.Mesh(ribbonGeo, fallMat);
  const ribbonB = new THREE.Mesh(ribbonGeo, fallMat);
  ribbonB.rotation.y = Math.PI / 2; // crossed planes read from every angle
  fall.add(ribbonA, ribbonB);
  fall.position.set(lip.x + lipDir.x * 0.45, -fallHeight / 2 + 0.05, lip.z + lipDir.z * 0.45);
  fall.rotation.y = Math.atan2(lipDir.x, lipDir.z);
  group.add(fall);

  // bright foam curling over the lip
  const lipFoam = new THREE.Mesh(
    new THREE.PlaneGeometry(2.9, 0.7),
    new THREE.MeshBasicMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.85,
      depthWrite: false,
      side: THREE.DoubleSide
    })
  );
  lipFoam.rotation.x = -Math.PI / 2;
  lipFoam.rotation.z = -Math.atan2(lipDir.x, lipDir.z);
  lipFoam.position.set(lip.x + lipDir.x * 0.15, 0.07, lip.z + lipDir.z * 0.15);
  group.add(lipFoam);
  const foam = new THREE.Sprite(new THREE.SpriteMaterial({
    map: puffTexture('rgba(255,255,255,0.95)'),
    transparent: true,
    opacity: 0.9,
    depthWrite: false
  }));
  foam.position.set(lip.x + lipDir.x * 0.3, 0.15, lip.z + lipDir.z * 0.3);
  foam.scale.set(3.8, 1.9, 1);
  group.add(foam);

  // mist cloud where the fall dissolves
  const mist = new THREE.Sprite(new THREE.SpriteMaterial({
    map: puffTexture('rgba(240,250,255,0.85)'),
    transparent: true,
    opacity: 0.55,
    depthWrite: false
  }));
  mist.position.set(lip.x + lipDir.x * 0.6, -fallHeight + 3, lip.z + lipDir.z * 0.6);
  mist.scale.set(11, 6.5, 1);
  group.add(mist);

  return { group, pond, rings, koi, fallTex, foam, mist, lipFoam, fall };
}

// ---------- windmill ----------
function buildWindmill() {
  const group = new THREE.Group();
  const tower = new THREE.Mesh(
    new THREE.CylinderGeometry(0.9, 1.3, 4.6, 10),
    toonMaterial(0xfff3d6)
  );
  tower.position.y = 2.3;
  addOutline(tower, 0.03);
  group.add(tower);
  const roof = new THREE.Mesh(new THREE.ConeGeometry(1.15, 1.3, 10), toonMaterial(0xf2b8c6));
  roof.position.y = 5.2;
  addOutline(roof, 0.04);
  group.add(roof);
  const hub = new THREE.Group();
  hub.position.set(0, 4.5, 1.15);
  const bladeMat = toonMaterial(0xcdb4f0);
  for (let i = 0; i < 4; i++) {
    const blade = new THREE.Mesh(new THREE.BoxGeometry(0.34, 2.6, 0.06), bladeMat);
    blade.position.y = 1.45;
    const arm = new THREE.Group();
    arm.add(blade);
    arm.rotation.z = (i / 4) * Math.PI * 2;
    hub.add(arm);
  }
  const nose = new THREE.Mesh(new THREE.SphereGeometry(0.22, 10, 8), toonMaterial(0x5a4a7a));
  hub.add(nose);
  group.add(hub);
  return { group, hub };
}

// ---------- crystal cluster ----------
function buildCrystals(rng) {
  const group = new THREE.Group();
  const crystals = [];
  const colors = [0xcdb4f0, 0xa8e6cf, 0xf2b8c6, 0x9fd8f0, 0xfff3d6];
  for (let i = 0; i < 8; i++) {
    const color = colors[i % colors.length];
    const h = rng.float(0.7, 2.1);
    const c = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.4, 0),
      new THREE.MeshToonMaterial({
        color,
        emissive: new THREE.Color(color),
        emissiveIntensity: 0.5,
        transparent: true,
        opacity: 0.94
      })
    );
    c.scale.set(0.7, h / 0.4, 0.7);
    const a = rng.float(0, Math.PI * 2);
    const d = rng.float(0.4, 3.4);
    c.position.set(Math.cos(a) * d, h * 0.42, Math.sin(a) * d);
    c.rotation.set(rng.float(-0.25, 0.25), rng.float(0, Math.PI), rng.float(-0.25, 0.25));
    addOutline(c, 0.035);
    group.add(c);
    crystals.push({ mesh: c, phase: rng.float(0, Math.PI * 2) });
  }
  const glow = new THREE.PointLight(0xd8c2f5, 12, 16, 1.8);
  glow.position.y = 2.2;
  group.add(glow);
  return { group, crystals, glow };
}

// ---------- lookout gazebo ----------
function buildGazebo() {
  const group = new THREE.Group();
  const floor = new THREE.Mesh(new THREE.CylinderGeometry(1.9, 2.1, 0.25, 8), toonMaterial(0xf3e4c4));
  floor.position.y = 0.13;
  addOutline(floor, 0.03);
  group.add(floor);
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2;
    const post = new THREE.Mesh(new THREE.CylinderGeometry(0.09, 0.11, 2.1, 6), toonMaterial(0xfff3d6));
    post.position.set(Math.cos(a) * 1.55, 1.3, Math.sin(a) * 1.55);
    group.add(post);
  }
  const roof = new THREE.Mesh(new THREE.ConeGeometry(2.3, 1.1, 8), toonMaterial(0xa8e6cf));
  roof.position.y = 2.95;
  addOutline(roof, 0.04);
  group.add(roof);
  const finial = new THREE.Mesh(new THREE.SphereGeometry(0.16, 8, 6), toonMaterial(0xf2b8c6));
  finial.position.y = 3.6;
  group.add(finial);
  return { group };
}

// ---------- assembly ----------
export function buildProps(islands, rng) {
  const byName = new Map(islands.map((i) => [i.name, i]));
  const add = (name, obj, x = 0, z = 0, rotY = 0) => {
    obj.group.position.set(x, 0, z);
    obj.group.rotation.y = rotY;
    byName.get(name).group.add(obj.group);
    return obj;
  };

  const tree = add('tree', buildTree(rng), 0.6, -0.6);
  const temple = add('temple', buildTemple(rng));
  const pond = add('koi', buildPond(byName.get('koi').r));
  const windmill = add('windmill', buildWindmill(), -1.2, -1.4, 0.6);
  const crystals = add('crystal', buildCrystals(rng));
  const gazebo = add('lookout', buildGazebo(), 0.8, -0.8);

  const leafM = new THREE.Matrix4();
  const leafP = new THREE.Vector3();
  const leafQ = new THREE.Quaternion();
  const leafS = new THREE.Vector3(1, 1, 1);
  const leafE = new THREE.Euler();

  return {
    tree,
    temple,
    pond,
    windmill,
    crystals,
    gazebo,
    update(t, dt) {
      // falling leaves: spiral down, respawn at the canopy
      for (let i = 0; i < tree.leafState.length; i++) {
        const L = tree.leafState[i];
        L.y -= L.fall * dt;
        L.angle += L.drift * dt * 2.2;
        if (L.y < 0.1) {
          L.y = 6.0 + rng.float(0, 0.6);
          L.radius = 0.4 + rng.float(0, 2.2);
        }
        leafP.set(Math.cos(L.angle) * L.radius, L.y + 0.3, Math.sin(L.angle) * L.radius);
        leafE.set(t * L.spin, L.angle, t * L.spin * 0.7);
        leafQ.setFromEuler(leafE);
        leafM.compose(leafP, leafQ, leafS);
        tree.leaves.setMatrixAt(i, leafM);
      }
      tree.leaves.instanceMatrix.needsUpdate = true;

      // rune stones orbit + bob
      temple.runes.rotation.y = t * 0.22;
      for (const s of temple.stones) {
        s.mesh.position.y = s.baseY + Math.sin(t * 0.8 + s.phase) * 0.22;
        s.mesh.rotation.y = t * 0.6 + s.phase;
      }

      // koi swim circles; ripple rings expand
      for (const k of pond.koi) {
        k.angle += k.speed * k.dir * dt;
        k.mesh.position.set(
          pond.pond.position.x + Math.cos(k.angle) * k.radius,
          0.02,
          pond.pond.position.z + Math.sin(k.angle) * k.radius
        );
        k.mesh.rotation.y = -k.angle + (k.dir > 0 ? 0 : Math.PI);
      }
      pond.rings.forEach((ring, i) => {
        const phase = (t * 0.35 + i / pond.rings.length) % 1;
        ring.scale.setScalar(0.6 + phase * 4.4);
        ring.material.opacity = 0.5 * (1 - phase);
      });
      pond.fallTex.offset.y = -t * 0.45;
      pond.foam.material.opacity = 0.7 + Math.sin(t * 3.2) * 0.2;
      pond.lipFoam.material.opacity = 0.65 + Math.sin(t * 5.1) * 0.2;
      pond.mist.material.opacity = 0.42 + Math.sin(t * 0.9) * 0.14;
      pond.mist.position.y = -43 + Math.sin(t * 0.5) * 1.2;

      windmill.hub.rotation.z = t * 0.5;

      for (const c of crystals.crystals) {
        c.mesh.material.emissiveIntensity = 0.4 + 0.22 * Math.sin(t * 1.6 + c.phase);
      }
      crystals.glow.intensity = 10 + Math.sin(t * 1.6) * 3;
    }
  };
}
