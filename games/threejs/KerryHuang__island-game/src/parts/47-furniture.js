
// ================= 街道家具與島上大樹 =================
const POOLS = []; // 加法混合光池：{x, z, r}

function addTree(kind, x, z, s) {
  const y = TOP, P = PAL.plants;
  const T = (k, dy, sc, c, rot) => kit.add(k, { pos: new THREE.Vector3(x, y + dy * s, z), rot, scale: sc.map ? sc.map((v) => v * s) : sc * s }, c);
  if (kind === 'cone') {
    T('cylinder', .12, [.08, .24, .08], PAL.wood);
    T('cone', .42, [.5, .5, .5], P[2]); T('cone', .66, [.4, .42, .4], P[1]); T('cone', .86, [.28, .34, .28], P[0]);
  } else if (kind === 'cherry') {
    T('cylinder', .22, [.07, .44, .07], '#8a5a44');
    T('ico', .6, .5, '#f2b5c6'); T('ico', .7, .34, '#f7cbd7');
    kit.add('ico', { pos: new THREE.Vector3(x + .16 * s, y + .52 * s, z + .05 * s), scale: .3 * s }, '#eea4b8');
  } else if (kind === 'fruit') {
    T('cylinder', .2, [.08, .4, .08], PAL.wood);
    T('sphere', .58, .56, P[1]);
    [[.2, .62, .14], [-.16, .5, .2], [.05, .78, .18], [-.2, .7, -.1]].forEach(([dx, dy, dz]) =>
      kit.add('sphere', { pos: new THREE.Vector3(x + dx * s, y + dy * s, z + dz * s), scale: .08 * s }, '#f29a4a'));
  } else if (kind === 'palm') {
    for (let i = 0; i < 4; i++) kit.add('cylinder', { pos: new THREE.Vector3(x + i * .03 * s, y + (.12 + i * .2) * s, z), scale: [.08 * s, .2 * s, .08 * s] }, i % 2 ? '#c39a6c' : PAL.wood);
    for (let i = 0; i < 6; i++) {
      const a = i * Math.PI / 3;
      kit.add('box', { pos: new THREE.Vector3(x + .12 * s + Math.cos(a) * .2 * s, y + .82 * s, z + Math.sin(a) * .2 * s), rot: [0, -a, -.35], rotOrder: 'YXZ', scale: [.42 * s, .03 * s, .12 * s] }, P[i % 2]);
    }
  } else if (kind === 'willow') {
    T('cylinder', .22, [.08, .44, .08], '#8a6a4c');
    T('dome', .44, [.7, .6, .7], P[0]);
    for (let i = 0; i < 6; i++) {
      const a = i * Math.PI / 3;
      kit.add('cylinder', { pos: new THREE.Vector3(x + Math.cos(a) * .3 * s, y + .36 * s, z + Math.sin(a) * .3 * s), scale: [.07 * s, .3 * s, .07 * s] }, P[1]);
    }
  } else {
    T('cylinder', .2, [.08, .4, .08], PAL.wood);
    T('ico', .58, .6, P[0]); T('ico', .72, .36, P[1]);
  }
}

function buildFurniture(isl) {
  const { cx, cz } = isl;
  // 路燈：六角形頂點
  for (let k = 0; k < 6; k++) {
    const [x, z] = hexVert(k, R - .15);
    kit.add('cylinder', { pos: new THREE.Vector3(cx + x, TOP + .22, cz + z), scale: [.03, .44, .03] }, PAL.ink);
    kit.add('cylinder', { pos: new THREE.Vector3(cx + x, TOP + .02, cz + z), scale: [.08, .04, .08] }, PAL.ink);
    kit.add('glowsphere', { pos: new THREE.Vector3(cx + x, TOP + .47, cz + z), scale: .1 }, PAL.cream);
    POOLS.push({ x: cx + x, z: cz + z, r: .55 });
  }
  // 邊上：盆栽、灌木、花，以及島緣串燈（小物件，LOD）
  kit.lod = true;
  for (let k = 0; k < 6; k++) {
    const a = hexVert(k, R - .12), b = hexVert((k + 1) % 6, R - .12);
    for (let i = 1; i < 6; i++) {
      const t = i / 6, x = cx + a[0] + (b[0] - a[0]) * t, z = cz + a[1] + (b[1] - a[1]) * t;
      if (i === 3) continue; // 邊中點留給橋
      const r = rand();
      if (r < .3) { kit.add('cylinder', { pos: new THREE.Vector3(x, TOP + .05, z), scale: [.1, .1, .1] }, PAL.coral); kit.add('ico', { pos: new THREE.Vector3(x, TOP + .14, z), scale: .12 }, pick(PAL.plants)); }
      else if (r < .65) kit.add('ico', { pos: new THREE.Vector3(x, TOP + .07, z), scale: [.17, .13, .17] }, pick(PAL.plants));
      else { kit.add('sphere', { pos: new THREE.Vector3(x, TOP + .06, z), scale: .07 }, pick([PAL.yellow, ...PAL.pastel, '#fff8f4'])); kit.add('ico', { pos: new THREE.Vector3(x, TOP + .03, z), scale: [.14, .05, .14] }, PAL.plants[2]); }
    }
    for (let i = 0; i <= 8; i++) {
      const t = i / 8, x = cx + (a[0] + (b[0] - a[0]) * t) * 1.06, z = cz + (a[1] + (b[1] - a[1]) * t) * 1.06;
      kit.add('glowsphere', { pos: new THREE.Vector3(x, TOP + .01, z), scale: .035 }, '#fff3d6');
    }
  }
  // 長椅：步道內側
  [1, 3, 5].forEach((k) => {
    const [x, z] = hexMid(k, PATH_R - .32), yaw = Math.atan2(x, z);
    const p = new THREE.Vector3(cx + x, TOP + .07, cz + z);
    kit.add('box', { pos: p, rot: [0, yaw + Math.PI / 2, 0], scale: [.26, .03, .09] }, PAL.wood);
    kit.add('box', { pos: p.clone().add(new THREE.Vector3(x, 0, z).normalize().multiplyScalar(.04)).setY(TOP + .12), rot: [0, yaw + Math.PI / 2, 0], scale: [.26, .08, .02] }, PAL.wood);
  });
  kit.lod = false;
  // 外圈大樹：4–6 棵，各島樹種不同；避開正前方，不擋建物
  const ks = [0, 1, 2, 3, 5].slice(0, 4 + (isl.idx % 2));
  ks.forEach((k) => { const [x, z] = hexVert(k, 1.6); addTree(isl.data.tree, cx + x, cz + z, rr(.72, .9)); });
}

// 光池：路燈下與窗前，強度乘上 night
function buildPools() {
  S.islands.forEach((isl) => isl.items.forEach((it) => {
    const f = it.frame;
    const p = new THREE.Vector3(0, 0, .55).multiplyScalar(f.size).applyAxisAngle(Y_AXIS, f.yaw).add(f.origin);
    POOLS.push({ x: p.x, z: p.z, r: .32 * f.size + .12 });
  }));
  const tex = canvasTex(64, 64, (g) => {
    const gr = g.createRadialGradient(32, 32, 0, 32, 32, 32);
    gr.addColorStop(0, 'rgba(255,199,119,1)'); gr.addColorStop(1, 'rgba(255,199,119,0)');
    g.fillStyle = gr; g.fillRect(0, 0, 64, 64);
  });
  const mat = new THREE.MeshBasicMaterial({ map: tex, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, opacity: 0, fog: false });
  const mesh = new THREE.InstancedMesh(new THREE.PlaneGeometry(2, 2).rotateX(-Math.PI / 2), mat, POOLS.length);
  const m = new THREE.Matrix4();
  POOLS.forEach((p, i) => { m.makeScale(p.r, 1, p.r).setPosition(p.x, TOP + .015, p.z); mesh.setMatrixAt(i, m); });
  mesh.renderOrder = 3; mesh.visible = false;
  S.scene.add(mesh);
  nightListeners.push((n) => { mat.opacity = n * .55; mesh.visible = n > .01; });
}
