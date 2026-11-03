
// ================= 零件庫：全部靜態物件走 InstancedMesh =================
const kit = {
  parts: [], owner: null, lod: false, groups: {}, meshes: [], ownerParts: new Map(),
  add(kind, t, color, opts) {
    const s = t.scale === undefined ? [1, 1, 1] : (typeof t.scale === 'number' ? [t.scale, t.scale, t.scale] : t.scale);
    const j = 1 + (rand() * 2 - 1) * .0072; // 防 z-fighting 的微抖動
    this.parts.push({
      kind, pos: t.pos, rot: t.rot || [0, 0, 0], rotOrder: t.rotOrder || 'XYZ', scale: [s[0] * j, s[1] * j, s[2] * j],
      color: new THREE.Color(color), owner: this.owner, lod: (opts && opts.lod) ?? this.lod,
    });
  },
  // 在區域座標系 (origin, yaw, size) 裡加零件：模型在單位空間設計，再縮放放到格子上
  local(frame, kind, p, s, color, rot) {
    const v = new THREE.Vector3(p[0], p[1], p[2]).multiplyScalar(frame.size).applyAxisAngle(Y_AXIS, frame.yaw).add(frame.origin);
    const sc = (typeof s === 'number' ? [s, s, s] : s).map((x) => x * frame.size);
    const r = rot || [0, 0, 0];
    this.add(kind, { pos: v, rot: [r[0], r[1] + frame.yaw, r[2]], rotOrder: 'YXZ', scale: sc }, color);
  },
};
let Y_AXIS;

function kitGeometries() {
  const g = {
    box: new THREE.BoxGeometry(1, 1, 1),
    rbox: new RoundedBoxGeometry(1, 1, 1, 2, .12),
    cylinder: new THREE.CylinderGeometry(.5, .5, 1, 14),
    cone: new THREE.ConeGeometry(.5, 1, 14),
    sphere: new THREE.SphereGeometry(.5, 16, 12),
    ico: new THREE.IcosahedronGeometry(.5, 1),
    dome: new THREE.SphereGeometry(.5, 16, 8, 0, Math.PI * 2, 0, Math.PI / 2),
    torus: new THREE.TorusGeometry(.35, .12, 8, 20),
    prism: new THREE.CylinderGeometry(.5, .5, 1, 3).rotateZ(Math.PI / 2),
    hip: new THREE.ConeGeometry(Math.SQRT1_2, 1, 4).rotateY(Math.PI / 4),
  };
  g.glowbox = g.box; g.glowsphere = g.sphere;
  return g;
}

function buildKit() {
  const geos = kitGeometries();
  const solid = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: .78, metalness: 0 });
  const glow = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: .6, metalness: 0, emissive: new THREE.Color(PAL.glow), emissiveIntensity: 0 });
  nightListeners.push((n) => { glow.emissiveIntensity = n * 3.2; });
  kit.glowMat = glow;

  const groups = {};
  kit.parts.forEach((p) => { const k = p.kind + (p.lod ? '|lod' : ''); (groups[k] = groups[k] || []).push(p); });
  const dummy = new THREE.Object3D();
  Object.entries(groups).forEach(([k, list]) => {
    const kind = k.split('|')[0], isGlow = kind.startsWith('glow');
    const mesh = new THREE.InstancedMesh(geos[kind], isGlow ? glow : solid, list.length);
    mesh.castShadow = !isGlow; mesh.receiveShadow = true;
    mesh.userData.parts = list; mesh.userData.lod = k.endsWith('|lod');
    list.forEach((p, i) => {
      dummy.position.copy(p.pos); dummy.rotation.set(p.rot[0], p.rot[1], p.rot[2], p.rotOrder); dummy.scale.set(...p.scale);
      dummy.updateMatrix(); mesh.setMatrixAt(i, dummy.matrix); mesh.setColorAt(i, p.color);
      if (p.owner) {
        if (!kit.ownerParts.has(p.owner)) kit.ownerParts.set(p.owner, []);
        kit.ownerParts.get(p.owner).push({ mesh, i, base: p.color.clone() });
      }
    });
    mesh.computeBoundingSphere();
    S.scene.add(mesh); kit.meshes.push(mesh);
  });
  kit.parts = [];
}

// 依鏡頭距離切換小物件 LOD
let lodHidden = null;
function updateLOD() {
  const hide = S.camera.position.distanceTo(S.controls.target) >= 26;
  if (hide === lodHidden) return;
  lodHidden = hide;
  kit.meshes.forEach((m) => { if (m.userData.lod) m.visible = !hide; });
}
