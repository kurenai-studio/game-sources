import * as THREE from 'three';
import { toon, canvasTex, dotTex, OUTLINE } from './common.js';
import { cowX } from '../game.js';
import { toX } from './common.js';

// Three procedural 3D stages. Everything is built from primitives and canvas-drawn textures (no downloaded assets).
const B = (x, y, z) => new THREE.BoxGeometry(x, y, z);
function mesh(g, m, x = 0, y = 0, z = 0, parent) { const o = new THREE.Mesh(g, m); o.position.set(x, y, z); if (parent) parent.add(o); return o; }
const rnd = (() => { let s = 7; return () => { s = (s * 16807) % 2147483647; return s / 2147483647; }; })();

function skyDome(top, mid, bottom, stars = false) {
  const tex = canvasTex(16, 512, (c, w, h) => {
    const g = c.createLinearGradient(0, 0, 0, h); g.addColorStop(0, top); g.addColorStop(0.55, mid); g.addColorStop(1, bottom);
    c.fillStyle = g; c.fillRect(0, 0, w, h);
  });
  const m = new THREE.Mesh(new THREE.SphereGeometry(60, 24, 12), new THREE.MeshBasicMaterial({ map: tex, side: THREE.BackSide, fog: false, depthWrite: false }));
  m.renderOrder = -10;
  const g = new THREE.Group(); g.add(m);
  if (stars) {
    const pos = []; for (let i = 0; i < 260; i++) { const a = rnd() * Math.PI - Math.PI / 2 - Math.PI / 2, e = 0.15 + rnd() * 1.2; pos.push(Math.cos(a) * 55 * Math.cos(e), 55 * Math.sin(e), Math.sin(a) * 55 * Math.cos(e)); }
    const geo = new THREE.BufferGeometry(); geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    g.add(new THREE.Points(geo, new THREE.PointsMaterial({ color: 0xffffff, size: 0.25, fog: false, map: dotTex(), transparent: true, depthWrite: false })));
  }
  return g;
}

function windowsTex(lit = 0.45, base = '#1a1a2a', warm = ['#ffcf6b', '#ffe9a8', '#8fd8ff']) {
  return canvasTex(128, 256, (c, w, h) => {
    c.fillStyle = base; c.fillRect(0, 0, w, h);
    for (let y = 12; y < h - 10; y += 26) for (let x = 10; x < w - 10; x += 22) {
      c.fillStyle = rnd() < lit ? warm[Math.floor(rnd() * warm.length)] : '#0c0c14'; c.fillRect(x, y, 12, 15);
    }
  });
}

function sign(text, bg, fg, w = 512, h = 128, font = 72) {
  return canvasTex(w, h, (c) => {
    c.fillStyle = bg; c.fillRect(0, 0, w, h); c.strokeStyle = fg; c.lineWidth = 8; c.strokeRect(8, 8, w - 16, h - 16);
    c.fillStyle = fg; c.font = `900 ${font}px Anton, Impact, "Arial Black", sans-serif`; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillText(text, w / 2, h / 2 + 4);
  });
}

function groundTex(kind) {
  return canvasTex(256, 256, (c, w, h) => {
    if (kind === 'road') {
      c.fillStyle = '#2b2b31'; c.fillRect(0, 0, w, h);
      for (let i = 0; i < 2200; i++) { const v = 30 + rnd() * 40; c.fillStyle = `rgb(${v},${v},${v + 4})`; c.fillRect(rnd() * w, rnd() * h, 2, 2); }
    } else if (kind === 'tiles') {
      c.fillStyle = '#b9a58c'; c.fillRect(0, 0, w, h);
      for (let y = 0; y < h; y += 64) for (let x = 0; x < w; x += 64) { const v = 160 + rnd() * 40; c.fillStyle = `rgb(${v},${v - 18},${v - 40})`; c.fillRect(x + 2, y + 2, 60, 60); }
      for (let i = 0; i < 900; i++) { c.fillStyle = 'rgba(60,40,20,0.12)'; c.fillRect(rnd() * w, rnd() * h, 3, 3); }
    } else {
      c.fillStyle = '#8a8580'; c.fillRect(0, 0, w, h);
      for (let i = 0; i < 1800; i++) { const v = 110 + rnd() * 50; c.fillStyle = `rgb(${v},${v},${v - 6})`; c.fillRect(rnd() * w, rnd() * h, 2, 2); }
      for (let x = 0; x < w; x += 64) { c.fillStyle = 'rgba(0,0,0,0.18)'; c.fillRect(x, 0, 2, h); }
    }
  }, { repeat: [10, 3] });
}

// cow (chaos event), auto-drawn low poly
function makeCow() {
  const g = new THREE.Group(), w = toon('#f2efe6'), blk = toon('#2a2622'), pink = toon('#e8a0a0');
  mesh(B(1.3, 0.62, 0.62), w, 0, 0.95, 0, g);
  mesh(B(0.4, 0.3, 0.64), blk, 0.2, 1.1, 0, g);
  const head = mesh(B(0.42, 0.38, 0.38), w, 0.82, 1.15, 0, g);
  mesh(B(0.2, 0.16, 0.3), pink, 0.16, -0.12, 0, head);
  for (const s of [-1, 1]) { mesh(new THREE.ConeGeometry(0.05, 0.22, 5), toon('#d8c9a0'), 0, 0.27, s * 0.15, head).rotation.x = s * 0.5; }
  g.legs = [];
  for (const [x, z] of [[-0.5, -0.22], [-0.5, 0.22], [0.5, -0.22], [0.5, 0.22]]) { const l = new THREE.Group(); l.position.set(x, 0.7, z); g.add(l); mesh(B(0.14, 0.7, 0.14), w, 0, -0.35, 0, l); g.legs.push(l); }
  const ms = []; g.traverse((o) => { if (o.isMesh) ms.push(o); });
  for (const o of ms) { o.castShadow = true; const ol = new THREE.Mesh(o.geometry, OUTLINE); ol.scale.setScalar(1.06); o.add(ol); }
  return g;
}

function makeKite(color) {
  const s = new THREE.Shape(); s.moveTo(0, 0.5); s.lineTo(0.38, 0); s.lineTo(0, -0.55); s.lineTo(-0.38, 0); s.closePath();
  const k = new THREE.Mesh(new THREE.ShapeGeometry(s), new THREE.MeshBasicMaterial({ color, side: THREE.DoubleSide }));
  const tail = mesh(B(0.04, 0.5, 0.01), new THREE.MeshBasicMaterial({ color: 0xffffff }), 0, -0.75, 0, k);
  tail.rotation.z = 0.2;
  return k;
}

function makeTrain() {
  const g = new THREE.Group();
  const body = toon('#2457a6'), stripe = toon('#e7c13a'), win = new THREE.MeshBasicMaterial({ map: windowsTex(0.9, '#173a70', ['#fff3c4']) });
  for (let i = 0; i < 6; i++) {
    const car = new THREE.Group(); car.position.x = i * 5.2; g.add(car);
    mesh(B(5, 1.9, 1.8), body, 0, 1.45, 0, car);
    mesh(B(5.02, 0.18, 1.82), stripe, 0, 0.75, 0, car);
    const w = mesh(B(4.6, 0.6, 1.84), win, 0, 1.75, 0, car); w.material = win;
    mesh(B(5, 0.25, 1.6), toon('#222'), 0, 0.42, 0, car);
  }
  const nose = mesh(B(1, 1.9, 1.8), toon('#c43a2a'), -3, 1.45, 0, g);
  mesh(new THREE.SphereGeometry(0.16, 8, 6), new THREE.MeshBasicMaterial({ color: 0xfff6c0 }), -3.52, 1.9, 0, g);
  return g;
}

export function buildStage(id, q) {
  const root = new THREE.Group();
  const S = { root, id, update: () => {}, lights: [], ambient: null, baseFog: null };
  const add = (o) => (root.add(o), o);
  const floorSize = [40, 18];

  // shared lights
  const hemi = add(new THREE.HemisphereLight(0xffffff, 0x404050, 1.0));
  const key = add(new THREE.DirectionalLight(0xffffff, 1.6)); key.position.set(-4, 8, 6); key.target.position.set(0, 0.8, 0); add(key.target);
  const rim = add(new THREE.DirectionalLight(0x88aaff, 1.1)); rim.position.set(3, 4, -6);
  if (q.shadows) {
    key.castShadow = true; key.shadow.mapSize.set(1024, 1024); key.shadow.bias = -0.0015;
    Object.assign(key.shadow.camera, { left: -7, right: 7, top: 5, bottom: -1, near: 1, far: 25 });
  }
  S.hemi = hemi; S.key = key; S.rim = rim;

  let floorMat;
  if (id === 'tapri') {
    add(skyDome('#05050f', '#141433', '#3a2340', true));
    const moon = add(new THREE.Mesh(new THREE.CircleGeometry(2.2, 32), new THREE.MeshBasicMaterial({ color: 0xfff1c9, fog: false })));
    moon.position.set(14, 16, -40);
    hemi.color.set(0x8c8cff); hemi.groundColor.set(0x2a1a20); hemi.intensity = 0.55;
    key.color.set(0xffc58a); key.intensity = 1.5; rim.color.set(0x7a5cff); rim.intensity = 1.4;
    floorMat = toon('#ffffff', { map: groundTex('road') });
    // buildings
    for (let i = -6; i <= 6; i++) {
      const h = 5 + rnd() * 7, w = 3 + rnd() * 1.6;
      const b = mesh(B(w, h, 3), new THREE.MeshLambertMaterial({ map: windowsTex(0.4), emissive: 0xffffff, emissiveMap: windowsTex(0.35, '#000000'), emissiveIntensity: 0.9 }), i * 3.6, h / 2, -10 - rnd() * 4, root);
      b.material.map.repeat.set(1, h / 8);
    }
    // tapri stall (left back)
    const stall = new THREE.Group(); stall.position.set(-3.6, 0, -2.6); add(stall);
    mesh(B(2.6, 1.05, 1.1), toon('#7a3b1e'), 0, 0.52, 0, stall);
    mesh(B(2.7, 0.08, 1.2), toon('#cfa36a'), 0, 1.08, 0, stall);
    const awn = mesh(B(3.0, 0.08, 1.6), new THREE.MeshLambertMaterial({ map: canvasTex(128, 32, (c, w, h) => { for (let x = 0; x < w; x += 16) { c.fillStyle = (x / 16) % 2 ? '#e3b65a' : '#c0392b'; c.fillRect(x, 0, 16, h); } }) }), 0, 2.4, 0.2, stall);
    awn.rotation.x = 0.25;
    for (const x of [-1.4, 1.4]) mesh(B(0.08, 2.4, 0.08), toon('#3a2a1a'), x, 1.2, 0.5, stall);
    const kettle = mesh(new THREE.CylinderGeometry(0.16, 0.2, 0.3, 10), toon('#c0c4c8'), -0.6, 1.27, 0, stall);
    mesh(new THREE.SphereGeometry(0.1, 8, 6), toon('#c0c4c8'), 0, 0.2, 0, kettle);
    for (let i = 0; i < 5; i++) mesh(new THREE.CylinderGeometry(0.05, 0.04, 0.12, 8), new THREE.MeshLambertMaterial({ color: 0xfff1d6, transparent: true, opacity: 0.8 }), 0.1 + i * 0.16, 1.18, 0.2, stall);
    const board = mesh(B(2.2, 0.5, 0.05), new THREE.MeshBasicMaterial({ map: sign('CHAI ₹10', '#c0392b', '#ffe9a8', 512, 128, 76) }), 0, 2.95, 0.4, stall);
    // steam
    const steamGeo = new THREE.BufferGeometry(); const sp = new Float32Array(24 * 3); steamGeo.setAttribute('position', new THREE.BufferAttribute(sp, 3));
    const steam = new THREE.Points(steamGeo, new THREE.PointsMaterial({ map: dotTex(), size: 0.35, transparent: true, opacity: 0.35, depthWrite: false, color: 0xffffff }));
    steam.position.set(-4.2, 1.5, -2.6); add(steam);
    // string lights
    const bulbs = [];
    const bulbMat = [0xffd36b, 0xff6b9b, 0x6bd3ff, 0x9bff6b].map((c) => new THREE.MeshBasicMaterial({ color: c }));
    for (let i = 0; i < 34; i++) { const x = -8 + i * 0.5, y = 3.6 - Math.sin((i / 33) * Math.PI) * 0.6; bulbs.push(mesh(new THREE.SphereGeometry(0.06, 6, 4), bulbMat[i % 4], x, y, -3.4, root)); }
    // street lamp
    const lamp = new THREE.Group(); lamp.position.set(4.2, 0, -2.2); add(lamp);
    mesh(new THREE.CylinderGeometry(0.06, 0.09, 4, 6), toon('#30343c'), 0, 2, 0, lamp);
    mesh(B(0.9, 0.08, 0.08), toon('#30343c'), -0.4, 3.95, 0, lamp);
    const lampBulb = mesh(new THREE.SphereGeometry(0.14, 8, 6), new THREE.MeshBasicMaterial({ color: 0xffe0a0 }), -0.8, 3.85, 0, lamp);
    const pl = new THREE.PointLight(0xffb060, q.level === 'low' ? 0 : 6, 9, 1.6); pl.position.set(3.4, 3.6, -1.6); add(pl); S.lights.push(pl);
    const glow = new THREE.Sprite(new THREE.SpriteMaterial({ map: dotTex(), color: 0xffb060, blending: THREE.AdditiveBlending, transparent: true, depthWrite: false, opacity: 0.6 })); glow.scale.set(2.2, 2.2, 1); glow.position.set(3.4, 3.85, -2.2); add(glow);
    // parked scooter-ish props: crates, gas cylinder
    mesh(B(0.6, 0.5, 0.6), toon('#8a5a2b'), 2.4, 0.25, -2.4, root); mesh(B(0.5, 0.4, 0.5), toon('#9c6a36'), 2.5, 0.7, -2.3, root);
    mesh(new THREE.CylinderGeometry(0.22, 0.22, 0.75, 10), toon('#c0392b'), -2.0, 0.38, -2.2, root);
    S.fog = new THREE.Fog(0x141433, 14, 48);
    S.update = (t, game) => {
      for (let i = 0; i < bulbs.length; i++) bulbs[i].visible = Math.sin(t * 3 + i * 1.7) > -0.85;
      for (let i = 0; i < 24; i++) { const k = ((t * 0.4 + i / 24) % 1); sp[i * 3] = Math.sin(i * 12.3 + t) * 0.15 * k; sp[i * 3 + 1] = k * 1.6; sp[i * 3 + 2] = Math.cos(i * 7.1) * 0.1; }
      steamGeo.attributes.position.needsUpdate = true;
      glow.material.opacity = 0.5 + Math.sin(t * 20) * 0.03;
    };
  } else if (id === 'terrace') {
    add(skyDome('#3d8fe0', '#8cc8f5', '#ffd9a0'));
    const sun = add(new THREE.Sprite(new THREE.SpriteMaterial({ map: dotTex(), color: 0xfff2b0, fog: false, blending: THREE.AdditiveBlending, transparent: true }))); sun.scale.set(14, 14, 1); sun.position.set(-18, 14, -40);
    hemi.color.set(0xbfe0ff); hemi.groundColor.set(0x8a6a4a); hemi.intensity = 1.0; key.color.set(0xfff0d0); key.intensity = 1.9; rim.color.set(0xffd080); rim.intensity = 1.0;
    floorMat = toon('#ffffff', { map: groundTex('tiles') });
    // parapet wall behind
    const wallMat = toon('#e8d9c0');
    mesh(B(26, 0.9, 0.3), wallMat, 0, 0.45, -3.2, root);
    mesh(B(26, 0.1, 0.45), toon('#cbb89a'), 0, 0.92, -3.2, root);
    // water tank
    const tank = mesh(new THREE.CylinderGeometry(0.9, 0.9, 1.6, 14), toon('#26262b'), 4.4, 1.9, -4.2, root);
    mesh(B(1.8, 1.1, 1.8), toon('#a89a88'), 4.4, 0.55, -4.2, root);
    mesh(new THREE.CylinderGeometry(0.25, 0.25, 0.12, 10), toon('#26262b'), 0, 0.85, 0, tank);
    // stair room
    mesh(B(2.6, 2.6, 2.4), toon('#f0e2c8'), -5.4, 1.3, -4.6, root);
    mesh(B(0.9, 1.9, 0.05), toon('#2f6f8f'), -5.0, 0.95, -3.38, root);
    // clothesline with clothes
    const line = mesh(B(6, 0.02, 0.02), toon('#444'), -0.4, 2.6, -2.6, root);
    for (const x of [-3.4, 2.6]) mesh(new THREE.CylinderGeometry(0.04, 0.04, 2.6, 5), toon('#666'), x, 1.3, -2.6, root);
    const clothes = []; const ccol = ['#e74c3c', '#f1c40f', '#3498db', '#ecf0f1', '#9b59b6', '#2ecc71'];
    for (let i = 0; i < 6; i++) { const c = mesh(B(0.5, 0.65, 0.02), toon(ccol[i], { side: THREE.DoubleSide }), -3 + i * 0.95, 2.28, -2.6, root); clothes.push(c); }
    // distant rooftops
    const pastel = ['#f4c7a1', '#c7e3f4', '#f4e1a1', '#d7c7f4', '#f4a1b5', '#c7f4cf', '#ffffff'];
    for (let i = -9; i <= 9; i++) { const h = 1 + rnd() * 6, w = 2.4 + rnd() * 2; mesh(B(w, h, 3), new THREE.MeshLambertMaterial({ color: pastel[Math.floor(rnd() * pastel.length)] }), i * 3.2, h / 2 - 2.5, -12 - rnd() * 8, root); }
    // kites
    const kites = []; const kcol = [0xff3b6b, 0xffd23f, 0x29d3ff, 0x7bd23c, 0xff8a1f, 0xb06bff];
    for (let i = 0; i < 6; i++) { const k = makeKite(kcol[i]); k.position.set(-9 + i * 3.5, 6 + rnd() * 4, -10 - rnd() * 6); k.userData.ph = rnd() * 6; add(k); kites.push(k); }
    S.fog = new THREE.Fog(0xbfe0ff, 18, 60);
    S.kites = kites;
    S.update = (t) => {
      for (const k of kites) { k.position.y += Math.sin(t * 1.3 + k.userData.ph) * 0.004; k.rotation.z = Math.sin(t * 1.7 + k.userData.ph) * 0.35; }
      clothes.forEach((c, i) => (c.rotation.x = Math.sin(t * 2.2 + i) * 0.25));
    };
  } else { // platform / railway junction
    add(skyDome('#2a1f4a', '#c4563a', '#ffb35c'));
    const sun = add(new THREE.Sprite(new THREE.SpriteMaterial({ map: dotTex(), color: 0xff9a4a, fog: false, blending: THREE.AdditiveBlending, transparent: true }))); sun.scale.set(16, 16, 1); sun.position.set(10, 5, -45);
    hemi.color.set(0xffc0a0); hemi.groundColor.set(0x3a2a40); hemi.intensity = 0.8; key.color.set(0xffb070); key.intensity = 1.7; rim.color.set(0x6a7aff); rim.intensity = 1.2;
    floorMat = toon('#ffffff', { map: groundTex('platform') });
    // platform edge + tracks behind
    mesh(B(40, 0.06, 0.35), toon('#f2d43c'), 0, 0.01, -2.0, root);
    mesh(B(40, 0.9, 0.2), toon('#6f6a66'), 0, -0.45, -2.2, root);
    const trackY = -0.9;
    mesh(B(40, 0.1, 3.4), toon('#4a3f38'), 0, trackY, -4.0, root);
    for (const z of [-3.4, -4.6]) mesh(B(40, 0.08, 0.08), toon('#9aa0a8'), 0, trackY + 0.12, z, root);
    for (let x = -20; x < 20; x += 0.7) mesh(B(0.2, 0.06, 1.8), toon('#5a4636'), x, trackY + 0.06, -4.0, root);
    // pillars + canopy
    for (const x of [-6, -2, 2, 6]) mesh(new THREE.CylinderGeometry(0.12, 0.12, 4.2, 8), toon('#3a5a7a'), x, 2.1, -1.6, root);
    const canopy = mesh(B(18, 0.12, 2.6), toon('#8a2a2a'), 0, 4.25, -1.2, root); canopy.rotation.x = -0.08;
    // station board
    const board = mesh(B(3.2, 0.8, 0.08), new THREE.MeshBasicMaterial({ map: sign('NUKKAD JN.', '#f2d43c', '#111111', 512, 128, 70) }), 0, 3.4, -1.55, root);
    for (const x of [-1.4, 1.4]) mesh(B(0.05, 0.6, 0.05), toon('#222'), x, 3.95, -1.55, root);
    // benches + far buildings
    for (const x of [-4.2, 4.2]) { mesh(B(1.6, 0.08, 0.45), toon('#2f6f8f'), x, 0.45, -1.2, root); for (const dx of [-0.6, 0.6]) mesh(B(0.08, 0.45, 0.4), toon('#333'), x + dx, 0.22, -1.2, root); }
    for (let i = -8; i <= 8; i++) { const h = 2 + rnd() * 5; mesh(B(2.8, h, 3), new THREE.MeshLambertMaterial({ map: windowsTex(0.25, '#3a2a3a') }), i * 3.3, h / 2 - 0.9, -11 - rnd() * 5, root); }
    // lamps
    const lampMat = new THREE.MeshBasicMaterial({ color: 0xfff1c4 });
    for (const x of [-6, -2, 2, 6]) mesh(B(0.7, 0.06, 0.14), lampMat, x, 4.15, -0.6, root);
    const train = makeTrain(); train.position.set(40, trackY, -4.0); add(train); train.visible = false;
    S.fog = new THREE.Fog(0xc4563a, 16, 55);
    S.update = (t, game) => {
      if (game && game.trainT > 0) { train.visible = true; train.position.x = 22 - game.trainT * 0.32; }
      else train.visible = false;
    };
  }
  // floor
  const floor = mesh(new THREE.PlaneGeometry(floorSize[0], floorSize[1]), floorMat, 0, 0, 2, root);
  floor.rotation.x = -Math.PI / 2; floor.receiveShadow = true;
  floor.position.z = id === 'platform' ? 4 + 2 - 9 + 7 : 2;
  if (id === 'platform') { floor.scale.y = 0.45; floor.position.z = 2.0; }
  S.floor = floor;

  // chaos props
  const cow = makeCow(); cow.visible = false; root.add(cow); S.cow = cow;
  const eventKite = makeKite(0xff3b6b); eventKite.scale.setScalar(2.2); eventKite.visible = false; root.add(eventKite);
  // rain
  const rainN = q.level === 'low' ? 250 : 600;
  const rp = new Float32Array(rainN * 6);
  for (let i = 0; i < rainN; i++) { const x = (rnd() - 0.5) * 22, y = rnd() * 9, z = -3 + rnd() * 8; rp.set([x, y, z, x - 0.05, y - 0.35, z], i * 6); }
  const rainGeo = new THREE.BufferGeometry(); rainGeo.setAttribute('position', new THREE.BufferAttribute(rp, 3));
  const rain = new THREE.LineSegments(rainGeo, new THREE.LineBasicMaterial({ color: 0xaad4ff, transparent: true, opacity: 0.55 })); rain.visible = false; root.add(rain);

  const base = { hemi: hemi.intensity, key: key.intensity, rim: rim.intensity, pl: S.lights.map((l) => l.intensity) };
  const inner = S.update;
  S.update = (t, game, dt = 1 / 60) => {
    inner(t, game);
    const e = game && game.event;
    // power cut: lights drop, a flicker
    let power = 1;
    if (e && e.type === 'powercut') power = e.t < 20 ? (Math.sin(e.t * 2) > 0 ? 1 : 0.15) : e.t > e.len - 20 ? (Math.sin(e.t * 2) > 0 ? 0.15 : 1) : 0.12;
    if (e && e.type === 'rain') power = Math.min(power, 0.7);
    hemi.intensity = base.hemi * power; key.intensity = base.key * Math.max(power, 0.25); rim.intensity = base.rim * (power < 0.5 ? 1.3 : 1);
    S.lights.forEach((l, i) => (l.intensity = base.pl[i] * power));
    // rain
    rain.visible = !!(e && e.type === 'rain');
    if (rain.visible) { rain.position.y = -((t * 14) % 9); }
    // cow
    if (e && e.type === 'cow') {
      cow.visible = true; cow.position.x = toX(cowX(e)); cow.rotation.y = e.dir === 1 ? 0 : Math.PI; cow.position.z = 0.6;
      cow.legs.forEach((l, i) => (l.rotation.z = Math.sin(t * 9 + i * Math.PI) * 0.4));
    } else cow.visible = false;
    // kite event: a huge kite swoops across
    if (e && e.type === 'kite') {
      eventKite.visible = true; const k = e.t / e.len;
      eventKite.position.set(-9 + k * 18, 3.2 + Math.sin(e.t * 0.08) * 0.8, -0.5); eventKite.rotation.z = Math.sin(e.t * 0.1) * 0.5;
    } else eventKite.visible = false;
  };
  return S;
}
