// Pastel gradient sky dome, soft lighting, gentle fog, and fake god rays.
import * as THREE from 'three';
import { canvasTexture, puffTexture } from './toon.js';

export const SUN_DIR = new THREE.Vector3(-0.45, 0.62, -0.55).normalize();

export function buildSky(scene) {
  // --- gradient dome: pale peach -> lavender -> mint ---
  const skyTex = canvasTexture(512, (ctx, s) => {
    const g = ctx.createLinearGradient(0, 0, 0, s);
    g.addColorStop(0.0, '#7f66d4'); // deep lavender zenith
    g.addColorStop(0.28, '#b495e6'); // lavender
    g.addColorStop(0.5, '#f2bdd6'); // rosy peach
    g.addColorStop(0.68, '#ffcead'); // pale peach at horizon
    g.addColorStop(0.85, '#c8f0dc'); // mint haze
    g.addColorStop(1.0, '#a8e6cf'); // mint
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
  });
  const skyGeo = new THREE.SphereGeometry(420, 32, 24);
  const skyMat = new THREE.MeshBasicMaterial({
    map: skyTex,
    side: THREE.BackSide,
    fog: false,
    depthWrite: false
  });
  const dome = new THREE.Mesh(skyGeo, skyMat);
  dome.renderOrder = -10;
  scene.add(dome);

  scene.fog = new THREE.Fog(0xe9d2f2, 130, 430);

  // --- lighting ---
  const hemi = new THREE.HemisphereLight(0xffe8d6, 0x9fe0c4, 0.95);
  scene.add(hemi);
  const sun = new THREE.DirectionalLight(0xfff0da, 1.7);
  sun.position.copy(SUN_DIR).multiplyScalar(120);
  scene.add(sun);

  // --- fake god rays: additive translucent shafts from the sun direction ---
  const rayGroup = new THREE.Group();
  // soft shaft texture: bright spine fading to nothing at the edges
  const shaftTex = canvasTexture(128, (ctx, s) => {
    const g = ctx.createLinearGradient(0, 0, s, 0);
    g.addColorStop(0, 'rgba(255,243,214,0)');
    g.addColorStop(0.5, 'rgba(255,243,214,0.85)');
    g.addColorStop(1, 'rgba(255,243,214,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
    // fade top and bottom too
    const v = ctx.createLinearGradient(0, 0, 0, s);
    v.addColorStop(0, 'rgba(0,0,0,0.25)');
    v.addColorStop(0.35, 'rgba(0,0,0,1)');
    v.addColorStop(0.8, 'rgba(0,0,0,1)');
    v.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.globalCompositeOperation = 'destination-in';
    ctx.fillStyle = v;
    ctx.fillRect(0, 0, s, s);
  });
  const rayGeo = new THREE.PlaneGeometry(14, 150);
  const rays = [];
  for (let i = 0; i < 6; i++) {
    const mat = new THREE.MeshBasicMaterial({
      map: shaftTex,
      transparent: true,
      opacity: 0.2 + (i % 3) * 0.06,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      side: THREE.DoubleSide,
      fog: false
    });
    const ray = new THREE.Mesh(rayGeo, mat);
    const angle = (i / 6) * Math.PI * 2;
    ray.position.set(Math.cos(angle) * 46, 44 + (i % 3) * 14, Math.sin(angle) * 46);
    ray.rotation.z = 0.38 + (i % 2) * 0.14;
    ray.rotation.y = angle + Math.PI / 2;
    ray.renderOrder = 5;
    rayGroup.add(ray);
    rays.push({ mesh: ray, base: mat.opacity, phase: i * 1.1 });
  }
  scene.add(rayGroup);

  // --- drifting cloud wisps near the light ---
  const wispTex = puffTexture('rgba(255,246,232,0.9)');
  const wisps = [];
  const wispMat = new THREE.SpriteMaterial({
    map: wispTex,
    transparent: true,
    opacity: 0.5,
    depthWrite: false,
    fog: false
  });
  for (let i = 0; i < 10; i++) {
    const wisp = new THREE.Sprite(wispMat.clone());
    const a = (i / 10) * Math.PI * 2;
    wisp.position.set(Math.cos(a) * (30 + i * 6), 30 + (i % 4) * 14, Math.sin(a) * (30 + i * 6));
    const s = 18 + (i % 3) * 10;
    wisp.scale.set(s * 1.8, s, 1);
    scene.add(wisp);
    wisps.push({ sprite: wisp, angle: a, radius: 30 + i * 6, speed: 0.008 + i * 0.0015, y: wisp.position.y });
  }

  return {
    dome,
    update(t, dt) {
      rayGroup.rotation.y = t * 0.02;
      for (const r of rays) {
        r.mesh.material.opacity = r.base * (0.75 + 0.35 * Math.sin(t * 0.5 + r.phase));
      }
      for (const w of wisps) {
        w.angle += w.speed * dt;
        w.sprite.position.x = Math.cos(w.angle) * w.radius;
        w.sprite.position.z = Math.sin(w.angle) * w.radius;
        w.sprite.position.y = w.y + Math.sin(t * 0.25 + w.angle * 3) * 1.5;
      }
    }
  };
}
