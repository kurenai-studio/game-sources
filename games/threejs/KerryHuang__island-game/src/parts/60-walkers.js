
// ================= 小人、協作線、badge、城市日誌 =================
const WK = { list: [], meshes: {}, tubes: [], log: [], lastLog: 0 };
const SKIN = ['#f1cdb2', '#e0b08f', '#c98f6b'], HAIR = ['#3a2a24', '#5a3b2a', '#211d1d', '#7a4a32'];
const SHIRT = [PAL.coral, PAL.teal, PAL.pastel[2], PAL.green, '#e7b24a', PAL.pastel[0]];
const CARGO_COLOR = { book: PAL.coral, meal: '#e7b24a', sapling: PAL.plants[0], medkit: '#fbf7f1', laptop: '#6f7fb5', ticket: PAL.pastel[0], ball: '#e58a3c', letter: PAL.cream };

// 角色配件：[幾何, 位置, 縮放, 顏色]；單位是小人座標（腳底為原點，高約 0.35，面向 +z）
const ROLE_PARTS = {
  civil: [['box', [0, .185, 0], [.1, .08, .095], PAL.coral], ['box', [.022, .2, .05], [.022, .028, .006], '#ffffff']],
  researcher: [['cylinder', [0, .15, 0], [.11, .13, .1], '#fbfaf7']],
  elder: [['cylinder', [.075, .1, .05], [.012, .2, .012], PAL.wood]],
  student: [['dome', [0, .29, -.004], [.18, .17, .18], PAL.yellow, [-.25, 0, 0]]],
  parent: [['box', [0, .11, .17], [.1, .08, .12], PAL.pastel[0]], ['box', [0, .16, .1], [.08, .012, .012], PAL.ink],
    ['cylinder', [-.045, .03, .17], [.04, .012, .04], PAL.ink, [0, 0, Math.PI / 2]], ['cylinder', [.045, .03, .17], [.04, .012, .04], PAL.ink, [0, 0, Math.PI / 2]]],
  commuter: [['torus', [0, .06, .09], [.17, .17, .1], PAL.ink, [0, Math.PI / 2, 0]], ['torus', [0, .06, -.09], [.17, .17, .1], PAL.ink, [0, Math.PI / 2, 0]],
    ['box', [0, .09, 0], [.015, .015, .18], PAL.teal], ['box', [0, .13, .07], [.07, .01, .01], PAL.ink]],
  farmer: [['cone', [0, .37, 0], [.23, .05, .23], '#e9cf86']],
  worker: [['dome', [0, .292, -.004], [.176, .168, .176], '#f29a4a', [-.25, 0, 0]], ['box', [0, .18, 0], [.096, .03, .092], '#fcea8b']],
  tourist: [['rbox', [.085, .06, -.02], [.05, .08, .1], PAL.pastel[1]]],
};

function walkerGeos() {
  return {
    leg: new THREE.BoxGeometry(.034, .1, .04).translate(0, -.05, 0),
    arm: new THREE.BoxGeometry(.024, .08, .028).translate(0, -.04, 0),
    capsule: new THREE.CapsuleGeometry(.045, .05, 4, 10),
    sphere: new THREE.SphereGeometry(.5, 14, 10),
    dome: new THREE.SphereGeometry(.5, 14, 6, 0, Math.PI * 2, 0, Math.PI / 2),
    box: new THREE.BoxGeometry(1, 1, 1),
    rbox: new RoundedBoxGeometry(1, 1, 1, 2, .15),
    cylinder: new THREE.CylinderGeometry(.5, .5, 1, 10),
    cone: new THREE.ConeGeometry(.5, 1, 12),
    torus: new THREE.TorusGeometry(.35, .1, 6, 16),
    shadow: new THREE.CircleGeometry(.09, 16).rotateX(-Math.PI / 2),
  };
}

function badgeTexture(cargo) {
  return canvasTex(128, 128, (g) => {
    g.fillStyle = '#ffffff'; g.beginPath(); g.arc(64, 64, 56, 0, 7); g.fill();
    g.strokeStyle = PAL.coral; g.lineWidth = 9; g.stroke();
    g.strokeStyle = PAL.ink; g.lineWidth = 6; g.lineCap = g.lineJoin = 'round'; g.beginPath();
    const P = {
      book: () => { g.moveTo(64, 46); g.lineTo(64, 86); g.moveTo(64, 46); g.quadraticCurveTo(50, 38, 36, 44); g.lineTo(36, 84); g.quadraticCurveTo(50, 78, 64, 86); g.moveTo(64, 46); g.quadraticCurveTo(78, 38, 92, 44); g.lineTo(92, 84); g.quadraticCurveTo(78, 78, 64, 86); },
      meal: () => { g.rect(38, 54, 52, 30); g.moveTo(38, 66); g.lineTo(90, 66); g.moveTo(60, 54); g.lineTo(60, 66); },
      sapling: () => { g.moveTo(64, 88); g.lineTo(64, 58); g.moveTo(64, 66); g.quadraticCurveTo(44, 64, 42, 44); g.quadraticCurveTo(62, 46, 64, 66); g.moveTo(64, 58); g.quadraticCurveTo(80, 54, 86, 38); g.quadraticCurveTo(68, 38, 64, 58); },
      medkit: () => { g.rect(38, 48, 52, 38); g.moveTo(54, 48); g.lineTo(54, 40); g.lineTo(74, 40); g.lineTo(74, 48); g.moveTo(64, 58); g.lineTo(64, 76); g.moveTo(55, 67); g.lineTo(73, 67); },
      laptop: () => { g.rect(42, 44, 44, 30); g.moveTo(34, 84); g.lineTo(94, 84); },
      ticket: () => { g.rect(36, 50, 56, 30); g.moveTo(54, 50); g.lineTo(54, 80); },
      ball: () => { g.arc(64, 64, 22, 0, 7); g.moveTo(42, 64); g.lineTo(86, 64); g.moveTo(64, 42); g.quadraticCurveTo(50, 64, 64, 86); },
      letter: () => { g.rect(38, 48, 52, 34); g.moveTo(38, 48); g.lineTo(64, 68); g.lineTo(90, 48); },
    };
    (P[cargo] || P.book)(); g.stroke();
  });
}

// ---------- 協作線：沿路網的 TubeGeometry ----------
function flowRoute(f) {
  const a = S.islandById[f.from], b = S.islandById[f.to];
  // 兩端都從島前側（+z，面向鏡頭）的步道頂點出發，相鄰島的路線也夠長、看得見
  const path = dijkstra(a.nodes[9], b.nodes[9]);
  return path.map((n) => GRAPH.nodes[n].clone());
}
function buildFlows() {
  DATA.flows.forEach((f) => {
    const pts = flowRoute(f);
    const curve = new THREE.CurvePath();
    for (let i = 0; i < pts.length - 1; i++) curve.add(new THREE.LineCurve3(pts[i].clone().setY(pts[i].y + .06), pts[i + 1].clone().setY(pts[i + 1].y + .06)));
    const len = curve.getLength();
    const mat = new THREE.ShaderMaterial({
      transparent: true, depthWrite: false,
      uniforms: { uTime: S.uTime, uLen: { value: len }, uStyle: { value: { official: 0, thematic: 1, pending: 2 }[f.evidence] }, uColor: { value: new THREE.Color(PAL.coral) }, uOpacity: { value: .82 }, uReduced: { value: 0 } },
      vertexShader: 'varying vec2 vUv; void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }',
      fragmentShader: `uniform float uTime, uLen, uStyle, uOpacity, uReduced; uniform vec3 uColor; varying vec2 vUv;
        void main(){
          float t = uReduced > .5 ? 0.0 : uTime;
          float st = uReduced > .5 ? 1.0 : uStyle;
          float u = vUv.x * uLen * 5.0 - t * 1.4;
          if (st > .5 && st < 1.5 && fract(u) > .6) discard;
          if (st > 1.5 && fract(u) > .3) discard;
          gl_FragColor = vec4(uColor, uOpacity);
          #include <colorspace_fragment>
        }`,
    });
    const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, Math.max(24, pts.length * 10), .035, 6, false), mat);
    tube.visible = false; tube.renderOrder = 5; tube.userData.flow = f;
    S.scene.add(tube);
    WK.tubes.push(tube);
    f._pts = pts;
  });
}

function relatedFlows(sel) {
  if (!sel) return new Set();
  if (sel.flow) return new Set([sel.flow]);
  const isl = sel.island;
  return new Set(isl ? DATA.flows.filter((f) => f.from === isl.data.id || f.to === isl.data.id) : []);
}
function showFlowsFor(sel) {
  const rel = relatedFlows(sel);
  let any = false;
  WK.tubes.forEach((t) => { t.visible = S.show.flows || rel.has(t.userData.flow); any = any || t.visible; });
  $('legend').hidden = !any;
  markDirty();
}

// ---------- 小人 ----------
function buildWalkers() {
  const geos = walkerGeos(), plan = [];
  const mat = new THREE.MeshStandardMaterial({ roughness: .7, metalness: 0 });
  const shadowMat = new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: .22, depthWrite: false });
  const badgeTex = {};
  DATA.flows.forEach((f) => {
    const pts = f._pts, cum = [0];
    for (let i = 1; i < pts.length; i++) cum.push(cum[i - 1] + pts[i].distanceTo(pts[i - 1]));
    const L = cum[cum.length - 1], n = clamp(f.count, 4, 14);
    for (let k = 0; k < n; k++) {
      const bike = f.role === 'commuter';
      const w = {
        flow: f, pts, cum, L, s: rand() * L, dir: rand() < .5 ? 1 : -1, wait: 0,
        speed: bike ? rr(.62, .70) : rr(.32, .40), phase: rand(), side: rr(-.06, .06), bike,
        pos: new THREE.Vector3(), yaw: 0, carrying: true, idx: WK.list.length,
        skin: pick(SKIN), hair: f.role === 'elder' ? '#d9d4cf' : pick(HAIR), shirt: pick(SHIRT), legs: pick([PAL.ink, '#4a5568', PAL.wood]),
      };
      w.carrying = w.dir === 1;
      // 零件：[幾何, 位置, 縮放, 顏色, 旋轉, 動畫]
      const parts = [
        ['leg', [-.024, .1, 0], 1, w.legs, null, 'legL'], ['leg', [.024, .1, 0], 1, w.legs, null, 'legR'],
        ['capsule', [0, .168, 0], 1, w.shirt], ['arm', [-.062, .215, 0], 1, w.shirt, null, 'armL'], ['arm', [.062, .215, 0], 1, w.shirt, null, 'armR'],
        ['sphere', [0, .29, 0], .14, w.skin], ['dome', [0, .29, -.004], [.158, .156, .158], w.hair, [-.25, 0, 0]], // 髮殼要比頭（半徑 .07）大一圈，否則被頭蓋住變禿頭
        ['sphere', [-.024, .296, .064], .022, PAL.ink], ['sphere', [.024, .296, .064], .022, PAL.ink],
        ...(ROLE_PARTS[f.role] || []).map((p) => [...p]), // 每人一份，slot 才不會被同角色的人覆蓋
        ['box', [0, .2, .075], [.075, .06, .06], CARGO_COLOR[f.cargo], null, 'cargo'],
        ['shadow', [0, .004, 0], 1, '#000000'],
      ];
      w.parts = parts;
      plan.push(w); WK.list.push(w);
      const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: badgeTex[f.cargo] || (badgeTex[f.cargo] = badgeTexture(f.cargo)), depthWrite: false, transparent: true }));
      sp.scale.set(.15, .15, 1); sp.renderOrder = 8; sp.visible = false; S.scene.add(sp); w.badge = sp;
      const el = document.createElement('div'); el.className = 'bubble';
      const lbl = new CSS2DObject(el); lbl.visible = false; S.scene.add(lbl); w.label = lbl; w.labelEl = el;
    }
  });
  // 每種幾何一個 InstancedMesh（DynamicDrawUsage）
  const counts = {};
  plan.forEach((w) => w.parts.forEach((p) => { counts[p[0]] = (counts[p[0]] || 0) + 1; }));
  Object.entries(counts).forEach(([k, n]) => {
    const m = new THREE.InstancedMesh(geos[k], k === 'shadow' ? shadowMat : mat, n);
    m.instanceMatrix.setUsage(THREE.DynamicDrawUsage); m.userData.owners = []; m.userData.n = 0;
    m.frustumCulled = false; if (k === 'shadow') m.renderOrder = 4;
    S.scene.add(m); WK.meshes[k] = m;
  });
  const col = new THREE.Color();
  plan.forEach((w) => w.parts.forEach((p) => {
    const m = WK.meshes[p[0]], i = m.userData.n++;
    m.setColorAt(i, col.set(p[3])); m.userData.owners[i] = w; p.slot = i;
  }));
  Object.values(WK.meshes).forEach((m) => { if (m.instanceColor) m.instanceColor.needsUpdate = true; });

  S.pickers.push({ objects: () => [WK.meshes.capsule, WK.meshes.sphere], bias: .3, resolve: (h) => { const w = h.object.userData.owners[h.instanceId]; if (!w) return false; selectWalker(w); return true; } });
  S.pickers.push({ objects: () => WK.tubes, bias: .15, resolve: (h) => { selectFlow(h.object.userData.flow); return true; } });
}

function pointAt(w, s) {
  const { pts, cum } = w;
  let i = 1; while (i < cum.length - 1 && cum[i] < s) i++;
  const a = pts[i - 1], b = pts[i], t = (s - cum[i - 1]) / ((cum[i] - cum[i - 1]) || 1);
  const dx = b.x - a.x, dz = b.z - a.z, l = Math.hypot(dx, dz) || 1;
  return { x: a.x + dx * t - dz / l * w.side, y: a.y + (b.y - a.y) * t, z: a.z + dz * t + dx / l * w.side, dx: dx / l, dz: dz / l };
}

function stepWalker(w, dt) {
  if (w.wait > 0) {
    w.wait -= dt;
    if (w.wait <= 0) {
      const end = w.dir === 1 ? w.flow.to : w.flow.from;
      if (w.dir === 1) logEvent('handoff', w, end); else logEvent('depart', w, end);
      w.dir *= -1; w.carrying = w.dir === 1;
    }
    return;
  }
  w.s += w.dir * w.speed * dt;
  if (w.s >= w.L || w.s <= 0) {
    w.s = clamp(w.s, 0, w.L); w.wait = 1.4;
    logEvent('arrive', w, w.dir === 1 ? w.flow.to : w.flow.from);
  }
}

let _m, _base, _q, _e, _v, _sv;
function poseWalkers() {
  const camD = S.camera.position.distanceTo(S.controls.target), k = clamp(camD / 20, 1, 1.45);
  WK.list.forEach((w) => {
    const p = pointAt(w, w.s), moving = w.wait <= 0;
    const dirSign = w.dir;
    w.yaw = Math.atan2(p.dx * dirSign, p.dz * dirSign);
    const ph = S.time * 9 + w.phase * 20, sw = moving && !w.bike ? Math.sin(ph) : 0;
    const bob = moving ? Math.abs(Math.sin(ph)) * .012 : 0;
    w.pos.set(p.x, p.y + bob + (w.bike ? .04 : 0), p.z);
    _base.compose(w.pos, _q.setFromAxisAngle(Y_AXIS, w.yaw), _sv.set(k, k, k));
    w.parts.forEach((pt) => {
      const [g, pos, sc, , rot, anim] = pt;
      let rx = rot ? rot[0] : 0, ry = rot ? rot[1] : 0, rz = rot ? rot[2] : 0, s = sc;
      if (anim === 'legL') rx = w.bike ? -.9 : sw * .55;
      else if (anim === 'legR') rx = w.bike ? -.9 : -sw * .55;
      else if (anim === 'armL') rx = w.carrying && S.show.carry ? -1.2 : -sw * .45;
      else if (anim === 'armR') rx = w.carrying && S.show.carry ? -1.2 : sw * .45;
      else if (anim === 'cargo' && !(w.carrying && S.show.carry)) s = 0;
      const sx = typeof s === 'number' ? s : s[0], sy = typeof s === 'number' ? s : s[1], sz = typeof s === 'number' ? s : s[2];
      _m.compose(_v.set(pos[0], pos[1], pos[2]), _q.setFromEuler(_e.set(rx, ry, rz)), _sv.set(sx || 1e-5, sy || 1e-5, sz || 1e-5));
      if (g === 'shadow') { _m.compose(_v.set(pos[0], pos[1] - bob, pos[2]), _q.identity(), _sv.set(1, 1, 1)); }
      _m.premultiply(_base);
      WK.meshes[g].setMatrixAt(pt.slot, _m);
    });
    const d = S.camera.position.distanceTo(w.pos);
    w.badge.visible = S.show.carry && w.carrying && d < 16;
    if (w.badge.visible) w.badge.position.set(w.pos.x, w.pos.y + .48 * k, w.pos.z);
    w.label.visible = S.show.names && d < 14;
    if (w.label.visible) {
      w.label.position.set(w.pos.x, w.pos.y + .42 * k, w.pos.z);
      const txt = w.carrying ? tr('正在搬 ', 'Carrying ') + tr(CARGO[w.flow.cargo][0], CARGO[w.flow.cargo][1]) : tr('交接完成，回程中', 'Heading back');
      if (w.labelEl.textContent !== txt) w.labelEl.textContent = txt;
    }
  });
  Object.values(WK.meshes).forEach((m) => { m.instanceMatrix.needsUpdate = true; });
}

// ---------- 城市日誌 ----------
const LOG_TEXT = {
  depart: ['出發', 'DEPART', (w, i) => tr(`從${i.data.name}出發，帶著${CARGO[w.flow.cargo][0]}`, `left ${i.data.en} with ${CARGO[w.flow.cargo][1]}`)],
  arrive: ['到站', 'ARRIVE', (w, i) => tr(`抵達${i.data.name}`, `arrived at ${i.data.en}`)],
  handoff: ['交接', 'HANDOFF', (w, i) => tr(`在${i.data.name}交出${CARGO[w.flow.cargo][0]}`, `handed ${CARGO[w.flow.cargo][1]} over at ${i.data.en}`)],
};
const ROLE_NAME = { civil: ['公務員', 'Civil servant'], researcher: ['研究員', 'Researcher'], elder: ['長者', 'Elder'], student: ['學童', 'Student'], parent: ['家長', 'Parent'], commuter: ['通勤族', 'Commuter'], farmer: ['農夫', 'Farmer'], worker: ['工人', 'Worker'], tourist: ['旅客', 'Traveler'] };
function logEvent(kind, w, islandId) {
  const now = performance.now();
  if (now - WK.lastLog < 700) return; // 節流，避免洗版
  WK.lastLog = now;
  WK.log.unshift({ kind, w, isl: S.islandById[islandId], min: S.minute });
  if (WK.log.length > 60) WK.log.pop();
  if (!$('log').hidden) renderLog();
}
function renderLog() {
  const fid = $('logFilter').value;
  const rows = WK.log.filter((e) => !fid || e.w.flow.id === fid).slice(0, 30);
  $('logList').innerHTML = rows.map((e) => {
    const t = LOG_TEXT[e.kind];
    return `<li><time>${fmtTime(e.min)}</time><span><span class="k ${e.kind}">${tr(t[0], t[1])}</span>${tr(ROLE_NAME[e.w.flow.role][0], ROLE_NAME[e.w.flow.role][1])}${tr('', ' ')}${esc(t[2](e.w, e.isl))}</span></li>`;
  }).join('') || `<li><time></time><span>${tr('等待市民到站…', 'Waiting for arrivals…')}</span></li>`;
}
function setLogOpen(on) { $('log').hidden = !on; if (on) renderLog(); }
function onSideToggle(open) { $('log').classList.toggle('noside', !open); }

function buildWalkersAll() {
  _m = new THREE.Matrix4(); _base = new THREE.Matrix4(); _q = new THREE.Quaternion(); _e = new THREE.Euler(); _v = new THREE.Vector3(); _sv = new THREE.Vector3();
  buildFlows();
  buildWalkers();
  $('logFilter').innerHTML = `<option value="">${tr('全部牽連線', 'All links')}</option>` + DATA.flows.map((f) => `<option value="${f.id}">${esc(flowName(f))}</option>`).join('');
  $('logFilter').addEventListener('change', renderLog);
  poseWalkers();
}

function updateFrame(dt, animate) {
  if (animate) WK.list.forEach((w) => stepWalker(w, dt));
  WK.tubes.forEach((t) => { t.material.uniforms.uReduced.value = S.reduced ? 1 : 0; });
  if (animate || S.dirty) poseWalkers();
}
