
// ================= 程序貼圖 =================
function canvasTex(w, h, draw, repeat) {
  const cv = document.createElement('canvas'); cv.width = w; cv.height = h;
  draw(cv.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(cv);
  t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 4;
  if (repeat) { t.wrapS = t.wrapT = THREE.RepeatWrapping; }
  return t;
}
const tint = (hex, amt) => '#' + new THREE.Color(hex).offsetHSL(0, 0, amt).getHexString();

const GROUND_TEX = {};
function buildGroundTextures() {
  GROUND_TEX.brick = canvasTex(256, 256, (g, w, h) => {
    g.fillStyle = '#e4d3c0'; g.fillRect(0, 0, w, h);
    for (let y = 0; y < h; y += 16) for (let x = -32; x < w; x += 32) {
      const ox = (y / 16) % 2 ? 16 : 0;
      g.fillStyle = tint('#efe2d1', rr(-.025, .02)); g.fillRect(x + ox + 1, y + 1, 30, 14);
    }
  }, true);
  GROUND_TEX.speckle = canvasTex(256, 256, (g, w, h) => {
    g.fillStyle = '#e8e2cc'; g.fillRect(0, 0, w, h);
    for (let i = 0; i < 900; i++) {
      g.fillStyle = pick(['#d9d0b6', '#cfd8b4', '#e0d2bd', '#c9d1ad', '#f3ecdc']);
      g.beginPath(); g.arc(rand() * w, rand() * h, rr(.8, 2.6), 0, 7); g.fill();
    }
  }, true);
  GROUND_TEX.stripe = canvasTex(256, 256, (g, w, h) => {
    g.fillStyle = '#f0e5d4'; g.fillRect(0, 0, w, h);
    g.strokeStyle = '#e6d6c1'; g.lineWidth = 9;
    for (let i = -h; i < w + h; i += 32) { g.beginPath(); g.moveTo(i, 0); g.lineTo(i + h, h); g.stroke(); }
  }, true);
}
function bandTex(color, k) {
  return canvasTex(256, 32, (g, w, h) => {
    g.fillStyle = color; g.fillRect(0, 0, w, h);
    g.fillStyle = PAL.cream;
    if (k % 3 === 0) for (let x = 0; x < w; x += 32) { g.beginPath(); g.moveTo(x, h); g.lineTo(x + 16, 6); g.lineTo(x + 32, h); g.fill(); }
    else if (k % 3 === 1) for (let x = 8; x < w; x += 21) { g.beginPath(); g.arc(x, h / 2, 5, 0, 7); g.fill(); }
    else { g.fillRect(0, 7, w, 4); g.fillRect(0, h - 11, w, 4); }
  }, true);
}

// 把幾何的 UV 改為世界座標 ÷2.2，讓花紋跨島連續
function worldUV(geo) {
  const p = geo.attributes.position, uv = geo.attributes.uv;
  for (let i = 0; i < p.count; i++) uv.setXY(i, p.getX(i) / 2.2, p.getZ(i) / 2.2);
  uv.needsUpdate = true; return geo;
}
const flatMat = (color, extra) => new THREE.MeshStandardMaterial(Object.assign({
  color, roughness: .92, metalness: 0, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: -1,
}, extra));

// ================= 路網 =================
const GRAPH = { nodes: [], adj: [] };
function addNode(x, y, z) { GRAPH.nodes.push(new THREE.Vector3(x, y, z)); GRAPH.adj.push([]); return GRAPH.nodes.length - 1; }
function linkNodes(a, b) {
  const d = GRAPH.nodes[a].distanceTo(GRAPH.nodes[b]);
  GRAPH.adj[a].push([b, d]); GRAPH.adj[b].push([a, d]);
}
function dijkstra(src, dst) {
  const n = GRAPH.nodes.length, dist = new Float64Array(n).fill(Infinity), prev = new Int32Array(n).fill(-1), done = new Uint8Array(n);
  dist[src] = 0;
  for (;;) {
    let u = -1, best = Infinity;
    for (let i = 0; i < n; i++) if (!done[i] && dist[i] < best) { best = dist[i]; u = i; }
    if (u < 0 || u === dst) break;
    done[u] = 1;
    for (const [v, w] of GRAPH.adj[u]) if (dist[u] + w < dist[v]) { dist[v] = dist[u] + w; prev[v] = u; }
  }
  const path = [];
  for (let u = dst; u >= 0; u = prev[u]) path.unshift(u);
  return path[0] === src ? path : [src];
}

// ================= 島 =================
const AX_DIRS = [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]];
const PATH_R = 1.8;

function buildIslands() {
  buildGroundTextures();
  const sideMat = ENV.waterMat;
  const pathMat = flatMat('#ead0b3');
  const curbMat = flatMat('#e4d6c3');
  const shallowMat = new THREE.MeshLambertMaterial({ color: '#d4efe9', transparent: true, opacity: .32, depthWrite: false, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: -2 });
  const foamMat = new THREE.MeshLambertMaterial({ color: '#ffffff', transparent: true, opacity: .55, depthWrite: false, polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -4 });
  const groundMats = {};

  DATA.islands.forEach((d, idx) => {
    const { x: cx, z: cz } = axialToWorld(d.q, d.r);
    const isl = { data: d, idx, cx, cz, nodes: [], items: [] };
    S.islands.push(isl); S.islandById[d.id] = isl;

    const gm = groundMats[d.ground] || (groundMats[d.ground] = new THREE.MeshStandardMaterial({ map: GROUND_TEX[d.ground], roughness: .92, metalness: 0 }));
    const top = new THREE.Mesh(worldUV(hexGeo(R - .05).translate(cx, TOP, cz)), gm);
    top.receiveShadow = true; top.userData.island = isl;
    isl.top = top;

    const curb = new THREE.Mesh(hexRingGeo(R - .2, R - .03).translate(cx, TOP + .006, cz), curbMat);
    const path = new THREE.Mesh(hexRingGeo(PATH_R - .14, PATH_R + .14).translate(cx, TOP + .008, cz), pathMat);
    curb.receiveShadow = path.receiveShadow = true;

    const bandH = .16, wallBot = WATER_Y - .05;
    const band = new THREE.Mesh(new THREE.CylinderGeometry(R - .02, R - .02, bandH, 6, 1, true).translate(cx, TOP - bandH / 2 + .003, cz),
      new THREE.MeshStandardMaterial({ map: bandTex(d.band, idx), roughness: .85 }));
    band.material.map.repeat.set(6, 1);
    const wallH = TOP - bandH - wallBot;
    const wall = new THREE.Mesh(new THREE.CylinderGeometry(R - .02, R + .03, wallH, 6, 1, true).translate(cx, wallBot + wallH / 2, cz), sideMat);
    band.castShadow = wall.castShadow = true;
    band.userData.island = wall.userData.island = curb.userData.island = path.userData.island = isl;

    const shallow = new THREE.Mesh(hexRingGeo(R, R + .7).translate(cx, WATER_Y + .004, cz), shallowMat);
    const foam = new THREE.Mesh(hexRingGeo(R, R + .16).translate(cx, WATER_Y + .008, cz), foamMat);
    shallow.renderOrder = 1; foam.renderOrder = 2;
    S.scene.add(top, curb, path, band, wall, shallow, foam);
    isl.pickables = [top, curb, path, band, wall];

    // 路網：12 節點，偶數 = 邊中點 k、奇數 = 頂點 k
    for (let k = 0; k < 6; k++) {
      const [mx, mz] = hexMid(k, PATH_R), [vx, vz] = hexVert(k, PATH_R);
      isl.nodes.push(addNode(cx + mx, TOP + .02, cz + mz), addNode(cx + vx, TOP + .02, cz + vz));
    }
    for (let i = 0; i < 12; i++) linkNodes(isl.nodes[i], isl.nodes[(i + 1) % 12]);
  });

  let sx = 0, sz = 0;
  S.islands.forEach((i) => { sx += i.cx; sz += i.cz; });
  S.center.set(sx / S.islands.length, TOP, sz / S.islands.length);
}

// 相鄰島之間的小拱橋：9 片甲板，連接兩島步道的邊中點
function buildBridges() {
  const key = (q, r) => q + ',' + r, byAx = {};
  S.islands.forEach((i) => { byAx[key(i.data.q, i.data.r)] = i; });
  S.bridges = [];
  S.islands.forEach((a) => {
    AX_DIRS.forEach(([dq, dr], k) => {
      const b = byAx[key(a.data.q + dq, a.data.r + dr)];
      if (!b || b.idx < a.idx) return;
      const na = a.nodes[2 * k], nb = b.nodes[2 * ((k + 3) % 6)];
      const A = GRAPH.nodes[na], B = GRAPH.nodes[nb];
      const h = rr(.04, .1), len = A.distanceTo(B);
      const dir = B.clone().sub(A).normalize(), yaw = Math.atan2(-dir.z, dir.x);
      const archY = (s) => TOP + .02 + Math.sin(Math.PI * s) * h;
      for (let i = 0; i < 9; i++) {
        const s0 = i / 9, s1 = (i + 1) / 9, sm = (s0 + s1) / 2;
        const p = A.clone().lerp(B, sm); p.y = archY(sm) - .01;
        const slope = Math.atan2(archY(s1) - archY(s0), len / 9);
        kit.add('rbox', { pos: p, rot: [0, yaw, slope], rotOrder: 'YXZ', scale: [len / 9 * .92, .045, .46] }, i % 2 ? PAL.wood : tint(PAL.wood, .04));
      }
      // 欄杆柱與扶手
      [-1, 1].forEach((side) => {
        const off = new THREE.Vector3(-dir.z, 0, dir.x).multiplyScalar(.22 * side);
        [0, .5, 1].forEach((s) => {
          const p = A.clone().lerp(B, s).add(off); p.y = archY(s) + .07;
          kit.add('cylinder', { pos: p, scale: [.035, .14, .035] }, PAL.cream);
        });
      });
      // 橋上節點（含拱高），讓小人跟著拱走
      let prev = na;
      for (const s of [.25, .5, .75]) {
        const p = A.clone().lerp(B, s); p.y = archY(s) + .01;
        const n = addNode(p.x, p.y, p.z); linkNodes(prev, n); prev = n;
      }
      linkNodes(prev, nb);
      S.bridges.push({ a, b });
    });
  });
}

// 島名 pill 標籤：掛在前側（+z）崖邊
function buildIslandLabels() {
  S.islands.forEach((isl) => {
    const el = document.createElement('div');
    el.className = 'isle-label';
    el.setAttribute('role', 'button'); el.tabIndex = -1;
    el.innerHTML = `<b>${isl.data.no}</b><span>${tr(isl.data.name, isl.data.en)}</span>`;
    el.addEventListener('click', (e) => { e.stopPropagation(); if (typeof selectIsland === 'function') selectIsland(isl); });
    const obj = new CSS2DObject(el);
    obj.position.set(isl.cx, TOP - .28, isl.cz + R * .87 + .1);
    S.scene.add(obj);
    isl.label = obj; isl.labelEl = el;
  });
}
