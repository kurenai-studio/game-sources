// The portal (glowing swirl ring) on the home isle, and the bonus
// star-field island high above in a night-sky sphere.
import * as THREE from 'three';
import { toonMaterial, addOutline, puffTexture } from './toon.js';

export const BONUS_POS = new THREE.Vector3(0, 90, 0);

function buildPortalRing(color = 0xcdb4f0) {
  const group = new THREE.Group();
  const ring = new THREE.Mesh(
    new THREE.TorusGeometry(1.5, 0.13, 12, 48),
    new THREE.MeshToonMaterial({
      color,
      emissive: new THREE.Color(color),
      emissiveIntensity: 0.9
    })
  );
  group.add(ring);
  // swirling disc inside
  const disc = new THREE.Mesh(
    new THREE.CircleGeometry(1.42, 40),
    new THREE.MeshBasicMaterial({
      color: 0xfff3d6,
      transparent: true,
      opacity: 0.5,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      side: THREE.DoubleSide
    })
  );
  group.add(disc);
  // orbiting swirl particles
  const COUNT = 90;
  const positions = new Float32Array(COUNT * 3);
  const seeds = [];
  for (let i = 0; i < COUNT; i++) {
    seeds.push({
      angle: (i / COUNT) * Math.PI * 2,
      radius: 1.0 + ((i * 37) % 100) / 100 * 0.9,
      speed: 0.8 + ((i * 53) % 100) / 100 * 1.4,
      wobble: (i * 29) % 100 / 100 * Math.PI * 2
    });
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  const points = new THREE.Points(geo, new THREE.PointsMaterial({
    color: 0xffffff,
    size: 0.14,
    map: puffTexture('rgba(255,255,255,0.95)'),
    transparent: true,
    opacity: 0.9,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    sizeAttenuation: true
  }));
  group.add(points);
  return { group, ring, disc, points, seeds, positions };
}

function buildStarField(rng) {
  const group = new THREE.Group();
  const layers = [];
  const tex = puffTexture('rgba(255,255,255,1)');
  for (let layer = 0; layer < 3; layer++) {
    const COUNT = 420;
    const positions = new Float32Array(COUNT * 3);
    for (let i = 0; i < COUNT; i++) {
      // points on a dome shell around the island
      const theta = rng.float(0, Math.PI * 2);
      const phi = rng.float(0.05, Math.PI * 0.95);
      const r = 46 + layer * 7 + rng.float(0, 3);
      positions[i * 3] = Math.cos(theta) * Math.sin(phi) * r;
      positions[i * 3 + 1] = Math.cos(phi) * r;
      positions[i * 3 + 2] = Math.sin(theta) * Math.sin(phi) * r;
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const mat = new THREE.PointsMaterial({
      color: [0xffffff, 0xcdb4f0, 0xa8e6cf][layer],
      size: 0.35 - layer * 0.07,
      map: tex,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      sizeAttenuation: true
    });
    const pts = new THREE.Points(geo, mat);
    group.add(pts);
    layers.push({ mat, phase: layer * 2.1, speed: 0.9 + layer * 0.5 });
  }
  return { group, layers };
}

export function buildPortal(scene, homeIsland, rng) {
  // --- portal on the home isle (starts closed) ---
  const portal = buildPortalRing();
  portal.group.position.set(-5.2, 2.1, 3.4);
  portal.group.rotation.y = 0.7;
  homeIsland.group.add(portal.group);
  portal.group.visible = false;
  portal.openAmount = 0;

  // --- bonus star island ---
  const bonus = new THREE.Group();
  bonus.position.copy(BONUS_POS);

  // night-sky sphere enclosing the island
  const night = new THREE.Mesh(
    new THREE.SphereGeometry(58, 24, 18),
    new THREE.MeshBasicMaterial({ color: 0x1a1440, side: THREE.BackSide, fog: false })
  );
  bonus.add(night);

  const stars = buildStarField(rng);
  bonus.add(stars.group);

  // tiny island
  const grass = new THREE.Mesh(
    new THREE.CylinderGeometry(4, 3.6, 1, 20),
    toonMaterial(0x7ecfae)
  );
  grass.position.y = -0.5;
  addOutline(grass, 0.02);
  bonus.add(grass);
  const rock = new THREE.Mesh(
    new THREE.CylinderGeometry(3.6, 0.15, 5.4, 10),
    toonMaterial(0x8a76b4)
  );
  rock.position.y = -3.6;
  addOutline(rock, 0.02);
  bonus.add(rock);

  // glowing reward: a floating heart-star crystal
  const reward = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.62, 0),
    new THREE.MeshToonMaterial({
      color: 0xf2b8c6,
      emissive: 0xf2b8c6,
      emissiveIntensity: 0.95
    })
  );
  reward.scale.set(1, 1.25, 0.7);
  reward.position.set(0, 2.1, 0);
  addOutline(reward, 0.05, 0x2a2050);
  bonus.add(reward);
  const rewardGlow = new THREE.PointLight(0xf2b8c6, 26, 22, 1.7);
  rewardGlow.position.set(0, 2.4, 0);
  bonus.add(rewardGlow);
  const rewardHalo = new THREE.Sprite(new THREE.SpriteMaterial({
    map: puffTexture('rgba(242,184,198,0.8)'),
    transparent: true,
    opacity: 0.7,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  }));
  rewardHalo.scale.set(4.5, 4.5, 1);
  rewardHalo.position.copy(reward.position);
  bonus.add(rewardHalo);

  // portal back home
  const back = buildPortalRing(0xa8e6cf);
  back.group.position.set(-2.4, 1.9, -1.6);
  back.group.rotation.y = 0.9;
  bonus.add(back.group);

  scene.add(bonus);

  // home-side light that turns on with the portal
  const portalGlow = new THREE.PointLight(0xcdb4f0, 0, 18, 1.8);
  portalGlow.position.copy(portal.group.position);
  homeIsland.group.add(portalGlow);

  const state = { open: false };

  function animateRing(p, t) {
    const pos = p.positions;
    for (let i = 0; i < p.seeds.length; i++) {
      const s = p.seeds[i];
      const a = s.angle + t * s.speed;
      const r = s.radius + Math.sin(t * 2 + s.wobble) * 0.12;
      pos[i * 3] = Math.cos(a) * r;
      pos[i * 3 + 1] = Math.sin(a) * r;
      pos[i * 3 + 2] = Math.sin(t * 3 + s.wobble) * 0.15;
    }
    p.points.geometry.attributes.position.needsUpdate = true;
    p.ring.rotation.z = t * 0.4;
  }

  // world-space center of the home portal
  const homePortalWorld = new THREE.Vector3();
  portal.group.getWorldPosition(homePortalWorld);
  const backPortalWorld = new THREE.Vector3();
  back.group.getWorldPosition(backPortalWorld);

  return {
    state,
    homePortalWorld,
    backPortalWorld,
    bonusPos: BONUS_POS.clone(),
    bonusColliders: [grass],
    open() {
      state.open = true;
      portal.group.visible = true;
    },
    update(t, dt) {
      if (state.open && portal.openAmount < 1) {
        portal.openAmount = Math.min(1, portal.openAmount + dt * 1.4);
        portal.group.scale.setScalar(0.2 + portal.openAmount * 0.8);
        portalGlow.intensity = portal.openAmount * 14;
      }
      if (portal.group.visible) {
        animateRing(portal, t);
        portal.disc.material.opacity = 0.35 + Math.sin(t * 2.2) * 0.15;
      }
      animateRing(back, t * 1.2);
      back.disc.material.opacity = 0.3 + Math.sin(t * 2 + 1) * 0.12;
      reward.rotation.y = t * 0.8;
      reward.position.y = 2.1 + Math.sin(t * 1.3) * 0.25;
      rewardHalo.position.y = reward.position.y;
      rewardHalo.material.opacity = 0.5 + Math.sin(t * 2.4) * 0.2;
      for (const l of stars.layers) {
        l.mat.opacity = 0.55 + 0.4 * Math.abs(Math.sin(t * l.speed + l.phase));
      }
      stars.group.rotation.y = t * 0.01;
    }
  };
}
