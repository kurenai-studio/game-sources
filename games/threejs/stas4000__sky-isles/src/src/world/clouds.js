// Endless cloud sea far below + drifting billboard cloud puffs (instanced).
import * as THREE from 'three';
import { puffTexture, noiseTexture } from './toon.js';

export function buildClouds(scene, rng) {
  // --- cloud sea ---
  const noise = noiseTexture(rng);
  noise.wrapS = THREE.RepeatWrapping;
  noise.wrapT = THREE.RepeatWrapping;
  noise.repeat.set(6, 6);
  const sea = new THREE.Mesh(
    new THREE.CircleGeometry(340, 48),
    new THREE.MeshBasicMaterial({
      map: noise,
      transparent: true,
      opacity: 1,
      color: 0xffffff,
      depthWrite: false
    })
  );
  sea.rotation.x = -Math.PI / 2;
  sea.position.y = -55;
  scene.add(sea);

  // second slower layer for parallax depth
  const sea2 = new THREE.Mesh(
    new THREE.CircleGeometry(380, 32),
    new THREE.MeshBasicMaterial({
      color: 0xeadcf6,
      transparent: true,
      opacity: 0.35,
      depthWrite: false
    })
  );
  sea2.rotation.x = -Math.PI / 2;
  sea2.position.y = -62;
  scene.add(sea2);

  // --- instanced billboard puffs ---
  const COUNT = 84;
  const geo = new THREE.PlaneGeometry(1, 1);
  const mat = new THREE.MeshBasicMaterial({
    map: puffTexture('rgba(255,251,244,0.92)'),
    transparent: true,
    opacity: 0.85,
    depthWrite: false,
    fog: true
  });
  const mesh = new THREE.InstancedMesh(geo, mat, COUNT);
  mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  mesh.frustumCulled = false;
  scene.add(mesh);

  const puffs = [];
  for (let i = 0; i < COUNT; i++) {
    const low = i < 40; // most puffs hug the cloud sea so it reads as an ocean
    puffs.push({
      x: rng.float(-170, 170),
      y: low ? rng.float(-50, -26) : rng.pick([rng.float(-24, 4), rng.float(6, 36)]),
      z: rng.float(-170, 170),
      w: low ? rng.float(16, 34) : rng.float(9, 24),
      drift: rng.float(0.35, 1.1),
      bob: rng.float(0, Math.PI * 2)
    });
  }

  const m = new THREE.Matrix4();
  const q = new THREE.Quaternion();
  const s = new THREE.Vector3();
  const p = new THREE.Vector3();

  return {
    sea,
    mesh,
    update(t, dt, camera) {
      noise.offset.x = t * 0.004;
      noise.offset.y = t * 0.0025;
      q.copy(camera.quaternion);
      for (let i = 0; i < COUNT; i++) {
        const c = puffs[i];
        c.x += c.drift * dt;
        if (c.x > 180) c.x = -180;
        p.set(c.x, c.y + Math.sin(t * 0.2 + c.bob) * 1.2, c.z);
        s.set(c.w, c.w * 0.55, 1);
        m.compose(p, q, s);
        mesh.setMatrixAt(i, m);
      }
      mesh.instanceMatrix.needsUpdate = true;
    }
  };
}
