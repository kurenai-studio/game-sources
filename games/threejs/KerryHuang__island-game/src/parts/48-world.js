
// ================= 遠景：盆地地形、背景樹、遠山、雲、海上點綴 =================
const ticks = [];
let noise, terrainH;

function setupTerrainFn() {
  noise = new SimplexNoise({ random: rand });
  const C = S.center;
  const fbm = (x, z) => { let a = 0, f = .035, amp = 1; for (let i = 0; i < 4; i++) { a += noise.noise(x * f, z * f) * amp; f *= 2; amp *= .5; } return a; };
  terrainH = (x, z) => {
    const dx = x - C.x, dz = z - C.z, d = Math.hypot(dx, dz) || 1;
    const front = (dx * .27 + dz * .96) / d; // 鏡頭那一側壓低
    let hill = smooth(28, 54, d) * (4.6 + fbm(x, z) * 2.6) * (1 - .75 * smooth(.05, .85, front));
    hill += smooth(32, 62, d) * fbm(x + 50, z - 30) * .8;
    let h = -1.6 + Math.max(hill, 0);
    if (h > 0) h = Math.floor(h / .55) * .55 + (h % .55) * .25; // 梯田量化
    return h;
  };
}

function buildTerrain() {
  const geo = new THREE.PlaneGeometry(170, 170, 160, 160).rotateX(-Math.PI / 2);
  const p = geo.attributes.position, cols = new Float32Array(p.count * 3);
  const stops = [[-.3, '#8fb3ad'], [.3, '#d9c9a3'], [1.6, '#aec493'], [3.5, '#a3b986'], [6, '#6f8a62'], [99, '#b2a38d']].map(([h, c]) => [h, new THREE.Color(c)]);
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i) + S.center.x, z = p.getZ(i) + S.center.z, h = terrainH(x, z);
    p.setY(i, h);
    const c = stops.find((s) => h < s[0])[1];
    cols[i * 3] = c.r; cols[i * 3 + 1] = c.g; cols[i * 3 + 2] = c.b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(cols, 3));
  geo.computeVertexNormals();
  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ vertexColors: true, flatShading: true, roughness: .95 }));
  mesh.position.set(S.center.x, 0, S.center.z);
  S.scene.add(mesh);
}

function buildBackgroundTrees() {
  const merge = (list) => BufferGeometryUtils.mergeGeometries(list.map((g) => g.index ? g.toNonIndexed() : g));
  const conifer = merge([
    new THREE.CylinderGeometry(.08, .1, .5, 5).translate(0, .25, 0),
    new THREE.ConeGeometry(.55, .8, 6).translate(0, .75, 0),
    new THREE.ConeGeometry(.42, .7, 6).translate(0, 1.1, 0),
    new THREE.ConeGeometry(.28, .55, 6).translate(0, 1.42, 0),
  ]);
  const r2 = mulberry32(77);
  const broad = merge([
    new THREE.CylinderGeometry(.08, .1, .5, 5).translate(0, .25, 0),
    ...[[0, .8, 0, .5], [.25, .7, .1, .36], [-.2, .72, -.12, .38], [.02, 1.08, .04, .32]].map(([x, y, z, s]) => {
      const g = new THREE.IcosahedronGeometry(s, 0); const a = g.attributes.position;
      for (let i = 0; i < a.count; i++) a.setXYZ(i, a.getX(i) * (1 + (r2() - .5) * .25), a.getY(i) * (1 + (r2() - .5) * .25), a.getZ(i) * (1 + (r2() - .5) * .25));
      return g.translate(x, y, z);
    }),
  ]);
  const mat = new THREE.MeshStandardMaterial({ flatShading: true, roughness: .9 });
  const N = IS_MOBILE ? 500 : 1600, picks = { c: [], b: [] };
  let guard = 0;
  while (picks.c.length + picks.b.length < N && guard++ < N * 6) {
    const a = rand() * Math.PI * 2, d = rr(16, 52), x = S.center.x + Math.cos(a) * d, z = S.center.z + Math.sin(a) * d, h = terrainH(x, z);
    if (h < .4 || (d < 34 && rand() < .6)) continue; // 近處稀疏，讓城市是主角
    (h > 2.4 || rand() < .3 ? picks.c : picks.b).push([x, h, z]);
  }
  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), col = new THREE.Color();
  // 顏色偏灰、偏淺，退到背景
  [[conifer, picks.c, ['#7d917a', '#869a80', '#748a72']], [broad, picks.b, ['#a3b98e', '#adc197', '#98ad86', '#b5c39c']]].forEach(([g, list, cs]) => {
    const mesh = new THREE.InstancedMesh(g, mat, list.length);
    list.forEach(([x, y, z], i) => {
      const s = rr(.6, 1.15);
      q.setFromAxisAngle(Y_AXIS, rand() * 6.28);
      m.compose(new THREE.Vector3(x, y - .05, z), q, new THREE.Vector3(s, s * rr(.85, 1.2), s));
      mesh.setMatrixAt(i, m); mesh.setColorAt(i, col.set(pick(cs)));
    });
    S.scene.add(mesh);
  });
}

function buildMountains() {
  [[95, '#9fb39a', .3, 10], [115, '#a9b7b4', .5, 14], [135, '#b9c3c8', .7, 19]].forEach(([rad, base, mix, hMax], band) => {
    const N = 200, pos = [], idx = [];
    for (let i = 0; i <= N; i++) {
      const a = i / N * Math.PI * 2, x = S.center.x + Math.cos(a) * rad, z = S.center.z + Math.sin(a) * rad;
      const h = hMax * (.45 + .55 * (noise.noise(Math.cos(a) * 2.2 + band * 7, Math.sin(a) * 2.2) * .5 + .5)) + noise.noise(a * 9, band) * 1.4;
      pos.push(x, -2, z, x, h, z);
      if (i < N) { const j = i * 2; idx.push(j, j + 2, j + 1, j + 1, j + 2, j + 3); }
    }
    const geo = new THREE.BufferGeometry(); geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); geo.setIndex(idx);
    const mat = new THREE.MeshBasicMaterial({ color: base, fog: false, side: THREE.DoubleSide });
    const baseC = new THREE.Color(base);
    timeListeners.push((hor) => mat.color.copy(baseC).lerp(hor, mix));
    S.scene.add(new THREE.Mesh(geo, mat));
  });
}

function buildClouds() {
  const mat = new THREE.MeshLambertMaterial({ color: '#ffffff', emissive: '#ffffff', emissiveIntensity: .25 });
  const geo = new THREE.IcosahedronGeometry(1, 2);
  const clouds = [];
  for (let i = 0; i < 12; i++) {
    const g = new THREE.Group(), n = 4 + Math.floor(rand() * 4);
    for (let k = 0; k < n; k++) {
      const m = new THREE.Mesh(geo, mat), s = rr(1.4, 2.6);
      m.scale.set(s, s * .7, s); m.position.set(k * 1.6 - n * .8 + rr(-.4, .4), rr(-.3, .5), rr(-.8, .8));
      g.add(m);
    }
    g.position.set(S.center.x + rr(-80, 80), rr(16, 27), S.center.z + rr(-70, 30));
    g.userData.v = rr(.25, .55);
    S.scene.add(g); clouds.push(g);
  }
  ticks.push((dt) => clouds.forEach((g) => {
    g.position.x += g.userData.v * dt;
    if (g.position.x - S.center.x > 85) g.position.x = S.center.x - 85;
  }));
}

function buildSeaProps() {
  const C = S.center;
  [[-2.4, 16], [-1.9, 19], [-.5, 17.5], [-1.2, 21]].forEach(([a, d], i) => {
    const x = C.x + Math.cos(a) * d, z = C.z + Math.sin(a) * d;
    kit.add('ico', { pos: new THREE.Vector3(x, WATER_Y, z), scale: [2.2, .5, 1.8] }, '#d9c9a3');
    kit.add('ico', { pos: new THREE.Vector3(x, WATER_Y + .15, z), scale: [1.5, .5, 1.2] }, PAL.plants[i % 3]);
    if (i === 1) {
      for (let k = 0; k < 4; k++) kit.add('cylinder', { pos: new THREE.Vector3(x, WATER_Y + .55 + k * .32, z), scale: [.36 - k * .03, .32, .36 - k * .03] }, k % 2 ? PAL.coral : PAL.cream);
      kit.add('glowsphere', { pos: new THREE.Vector3(x, WATER_Y + 1.95, z), scale: .26 }, PAL.yellow);
      kit.add('cone', { pos: new THREE.Vector3(x, WATER_Y + 2.25, z), scale: [.4, .3, .4] }, PAL.ink);
    } else addTree(pick(['cone', 'palm', 'round']), x + .3, z, 1.1);
  });
  // 帆船：沿圓周慢慢繞
  const boats = [];
  const hullM = new THREE.MeshStandardMaterial({ color: PAL.wood, roughness: .8 }), sailM = new THREE.MeshStandardMaterial({ color: PAL.cream, roughness: .8, side: THREE.DoubleSide });
  for (let i = 0; i < 3; i++) {
    const g = new THREE.Group();
    g.add(new THREE.Mesh(new RoundedBoxGeometry(.9, .2, .34, 2, .08), hullM));
    const mast = new THREE.Mesh(new THREE.CylinderGeometry(.02, .02, .9), hullM); mast.position.y = .5; g.add(mast);
    const sg = new THREE.BufferGeometry(); sg.setAttribute('position', new THREE.Float32BufferAttribute([0, .15, 0, 0, .95, 0, .4, .2, 0], 3)); sg.computeVertexNormals();
    const sail = new THREE.Mesh(sg, i === 1 ? new THREE.MeshStandardMaterial({ color: PAL.coral, side: THREE.DoubleSide }) : sailM); g.add(sail);
    g.userData = { a: i * 2.1 + .6, r: 16 + i * 2.5, v: .02 + i * .006 };
    S.scene.add(g); boats.push(g);
  }
  const place = () => boats.forEach((b) => {
    const { a, r } = b.userData;
    b.position.set(C.x + Math.cos(a) * r, WATER_Y + .06, C.z + Math.sin(a) * r * .8 - 3);
    b.rotation.y = -a;
  });
  place();
  ticks.push((dt) => { boats.forEach((b) => { b.userData.a += b.userData.v * dt; }); place(); });
}

function buildWorld() {
  setupTerrainFn();
  S.islands.forEach((isl) => { layoutIsland(isl); buildFurniture(isl); });
  buildPools();
  buildTerrain();
  buildBackgroundTrees();
  buildMountains();
  buildClouds();
  buildSeaProps();
}
