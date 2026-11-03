import * as THREE from "three";
import type { Box, Vec2 } from "./logic";
import { spreadIndices } from "./touch";

// Original, fully procedural Malacca-1511 kampung: timber stilt houses with atap
// roofs, pasar stalls, a three-tier istana, a harbour with a jetty and prahu boats.

export interface HideSpot {
  x: number;
  z: number;
  r: number;
}
export interface GuardDef {
  waypoints: Vec2[];
  isTarget?: boolean;
}
export interface Level {
  root: THREE.Group;
  colliders: Box[]; // everything solid
  occluders: Box[]; // blocks line of sight (tall things only)
  hides: HideSpot[];
  guards: GuardDef[];
  start: Vec2;
  exit: Vec2;
  exitBeam: THREE.Mesh;
  bounds: { minX: number; maxX: number; minZ: number; maxZ: number; jettyZ: number; jettyHalf: number };
}

/** Height of the open space under a stilt house's floor. */
const STILT_H = 1.75;

const matCache = new Map<string, THREE.MeshStandardMaterial>();
function mat(color: number, opts: Partial<THREE.MeshStandardMaterialParameters> = {}) {
  const key = color + JSON.stringify(opts);
  let m = matCache.get(key);
  if (!m) {
    m = new THREE.MeshStandardMaterial({ color, roughness: 0.95, flatShading: true, ...opts });
    matCache.set(key, m);
  }
  return m;
}

function seeded(seed: number) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) % 4294967296;
    return s / 4294967296;
  };
}

const boxOf = (cx: number, cz: number, w: number, d: number, h: number, minY = 0): Box => ({
  minX: cx - w / 2,
  maxX: cx + w / 2,
  minY,
  maxY: h,
  minZ: cz - d / 2,
  maxZ: cz + d / 2,
});

function mesh(geo: THREE.BufferGeometry, m: THREE.Material, x: number, y: number, z: number, shadow = true) {
  const o = new THREE.Mesh(geo, m);
  o.position.set(x, y, z);
  o.castShadow = shadow;
  o.receiveShadow = true;
  return o;
}

/** Sloped atap roof: a square frustum scaled to (w, d), top face at y = topY. */
function atapRoof(w: number, d: number, topY: number, rise: number, color: number) {
  const geo = new THREE.CylinderGeometry(0.5657, 0.7071, rise, 4, 1);
  geo.rotateY(Math.PI / 4);
  const m = mesh(geo, mat(color), 0, topY - rise / 2, 0);
  m.scale.set(w, 1, d);
  return m;
}

export function buildLevel(opts: { lampLights?: number } = {}): Level {
  const root = new THREE.Group();
  const colliders: Box[] = [];
  const occluders: Box[] = [];
  const hides: HideSpot[] = [];
  const rnd = seeded(1511);
  const winLit: THREE.Matrix4[] = [];
  const winDark: THREE.Matrix4[] = [];
  const dummy = new THREE.Object3D();

  const addCollider = (b: Box) => {
    colliders.push(b);
    if (b.maxY >= 2) occluders.push(b);
  };

  const addWindow = (x: number, y: number, z: number, faceX: boolean) => {
    dummy.position.set(x, y, z);
    dummy.rotation.set(0, faceX ? Math.PI / 2 : 0, 0);
    dummy.updateMatrix();
    (rnd() < 0.45 ? winLit : winDark).push(dummy.matrix.clone());
  };

  /** A timber stilt house (or tier of the palace). */
  function house(cx: number, cz: number, w: number, d: number, h: number, wall: number, roof: number, opts: { windows?: boolean; stilts?: boolean } = {}) {
    const { windows = true, stilts = true } = opts;
    const roofH = 0.6;
    const baseH = stilts ? STILT_H : 0;
    if (stilts) {
      // raised floor + walls + roof are one solid block; the space under it is open ground
      addCollider(boxOf(cx, cz, w, d, h, baseH));
      // stilts are thin solid posts; everything between them can be walked through
      const nx = Math.max(2, Math.round(w / 4) + 1);
      const nz = Math.max(2, Math.round(d / 4) + 1);
      for (let i = 0; i < nx; i++)
        for (let j = 0; j < nz; j++) {
          if (i > 0 && i < nx - 1 && j > 0 && j < nz - 1) continue;
          const px = cx - w / 2 + 0.25 + (i / (nx - 1)) * (w - 0.5);
          const pz = cz - d / 2 + 0.25 + (j / (nz - 1)) * (d - 0.5);
          addCollider(boxOf(px, pz, 0.36, 0.36, baseH));
          root.add(mesh(new THREE.CylinderGeometry(0.16, 0.2, baseH + 0.1, 6), mat(0x4a3220), px, baseH / 2, pz));
        }
      root.add(mesh(new THREE.BoxGeometry(w, 0.12, d), mat(0x2a1a10), cx, baseH - 0.06, cz));
    } else {
      addCollider(boxOf(cx, cz, w, d, h));
    }
    const wallH = h - roofH - baseH;
    root.add(mesh(new THREE.BoxGeometry(w, wallH, d), mat(wall), cx, baseH + wallH / 2, cz));
    // horizontal plank bands
    for (let y = baseH + 0.7; y < h - roofH - 0.2; y += 0.9)
      root.add(mesh(new THREE.BoxGeometry(w + 0.06, 0.06, d + 0.06), mat(0x3d2a1a), cx, y, cz, false));
    const r = atapRoof(w + 1.0, d + 1.0, h, roofH, roof);
    r.position.x = cx;
    r.position.z = cz;
    root.add(r);
    if (windows) {
      const rows = h > 5 ? [baseH + 0.9, h - roofH - 1.1] : [baseH + 0.9];
      for (const y of rows) {
        for (let i = 0; i < Math.floor(w / 3.2); i++) {
          const x = cx - w / 2 + (i + 0.5) * (w / Math.floor(w / 3.2));
          addWindow(x, y, cz - d / 2 - 0.06, false);
          addWindow(x, y, cz + d / 2 + 0.06, false);
        }
        for (let i = 0; i < Math.floor(d / 3.2); i++) {
          const z = cz - d / 2 + (i + 0.5) * (d / Math.floor(d / 3.2));
          addWindow(cx - w / 2 - 0.06, y, z, true);
          addWindow(cx + w / 2 + 0.06, y, z, true);
        }
      }
    }
  }

  // ---------------------------------------------------------------- ground + sea
  const groundTex = (() => {
    const c = document.createElement("canvas");
    c.width = c.height = 256;
    const g = c.getContext("2d")!;
    g.fillStyle = "#8c6c48";
    g.fillRect(0, 0, 256, 256);
    for (let i = 0; i < 2600; i++) {
      const v = 90 + Math.floor(rnd() * 70);
      g.fillStyle = `rgba(${v + 40},${v + 12},${v - 20},0.35)`;
      g.fillRect(rnd() * 256, rnd() * 256, 2 + rnd() * 3, 2 + rnd() * 3);
    }
    const t = new THREE.CanvasTexture(c);
    t.wrapS = t.wrapT = THREE.RepeatWrapping;
    t.repeat.set(40, 40);
    t.colorSpace = THREE.SRGBColorSpace;
    return t;
  })();
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(260, 200), new THREE.MeshStandardMaterial({ map: groundTex, roughness: 1 }));
  ground.rotation.x = -Math.PI / 2;
  ground.position.set(0, 0, -31 + 100);
  ground.receiveShadow = true;
  root.add(ground);

  const water = new THREE.Mesh(
    new THREE.PlaneGeometry(500, 300),
    new THREE.MeshStandardMaterial({ color: 0x1c5560, roughness: 0.25, metalness: 0.35 }),
  );
  water.rotation.x = -Math.PI / 2;
  water.position.set(0, -0.3, -31 - 150 + 1);
  root.add(water);
  // wet shore line
  root.add(mesh(new THREE.BoxGeometry(70, 0.12, 1.2), mat(0x5b4a35), 0, 0.02, -31.2, false));

  // ---------------------------------------------------------------- blocks of houses (kampung lanes between)
  const wallCols = [0x7a5535, 0x6d4a30, 0x84613c, 0x5f4029];
  const roofCols = [0xb89a5a, 0xa98a4e, 0xc2a566];
  const pick = <T,>(a: T[]) => a[Math.floor(rnd() * a.length)];
  const hs = (cx: number, cz: number, w: number, d: number, h: number) =>
    house(cx, cz, w, d, h, pick(wallCols), pick(roofCols));

  // SW (start side)
  hs(-22, -22, 12, 5.6, 3.4);
  hs(-22, -17.6, 12, 5.6, 3.4);
  hs(-22, -26.2, 12, 3.2, 6.6);
  // S middle
  hs(0, -22, 12, 12, 3.4);
  // SE
  hs(22, -22, 12, 12, 3.4);
  // W middle: low + tall
  hs(-22, -3, 12, 6, 3.4);
  hs(-22, 3, 12, 6, 6.6);
  // E middle
  hs(22, -3, 12, 6, 3.4);
  hs(22, 3, 12, 6, 6.6);
  // NW
  hs(-22, 22, 12, 12, 3.4);
  // NE: house plus watch tower
  hs(22, 22, 12, 12, 3.4);

  // Istana (sultanate palace), three tiers, north middle
  house(0, 22, 13, 12, 3.4, 0x8a6a3a, 0x9a3b2a, { windows: true });
  house(0, 22, 9, 8, 6.6, 0x93703f, 0x9a3b2a, { windows: true, stilts: false });
  house(0, 22, 5, 4.4, 9.6, 0x9d7a45, 0x9a3b2a, { windows: false, stilts: false });
  root.add(mesh(new THREE.ConeGeometry(0.35, 1.6, 8), mat(0xd9a93a, { emissive: 0x4a3200 }), 0, 10.4, 22));
  // palace steps (low, climbable)
  addCollider(boxOf(0, 15.2, 5, 1.4, 0.9));
  root.add(mesh(new THREE.BoxGeometry(5, 0.9, 1.4), mat(0x6b5a48), 0, 0.45, 15.2));

  // Watch tower (kubu), NE corner of the block
  {
    const tx = 17.3,
      tz = 17.3;
    addCollider(boxOf(tx, tz, 3.6, 3.6, 15, 11.5));
    for (const sx of [-1, 1])
      for (const sz of [-1, 1]) addCollider(boxOf(tx + sx * 1, tz + sz * 1, 0.5, 0.5, 11.5));
    for (const sx of [-1, 1])
      for (const sz of [-1, 1])
        root.add(mesh(new THREE.CylinderGeometry(0.17, 0.22, 11.5, 6), mat(0x4a3220), tx + sx * 1, 5.75, tz + sz * 1));
    for (let y = 1.5; y < 11; y += 2.4)
      root.add(mesh(new THREE.BoxGeometry(2.5, 0.12, 2.5), mat(0x3d2a1a), tx, y, tz, false));
    root.add(mesh(new THREE.BoxGeometry(3.6, 0.3, 3.6), mat(0x5a3d26), tx, 11.7, tz));
    root.add(mesh(new THREE.BoxGeometry(3.0, 2.2, 3.0), mat(0x6d4a30), tx, 12.9, tz));
    const r = atapRoof(4.6, 4.6, 15, 1.2, 0xb89a5a);
    r.position.x = tx;
    r.position.z = tz;
    root.add(r);
  }

  // ---------------------------------------------------------------- palisade (N, E, W) + jetty bounds
  const posts: THREE.Matrix4[] = [];
  const postAt = (x: number, z: number, h: number) => {
    dummy.position.set(x, h / 2, z);
    dummy.rotation.set(0, 0, 0);
    dummy.scale.set(1, h, 1);
    dummy.updateMatrix();
    posts.push(dummy.matrix.clone());
    dummy.scale.set(1, 1, 1);
  };
  for (let x = -35; x <= 35; x += 0.55) postAt(x, 35, 4.2 + rnd() * 0.5);
  for (let z = -31; z <= 35; z += 0.55) {
    postAt(-35, z, 4.2 + rnd() * 0.5);
    postAt(35, z, 4.2 + rnd() * 0.5);
  }
  const postGeo = new THREE.CylinderGeometry(0.22, 0.26, 1, 6);
  const postMesh = new THREE.InstancedMesh(postGeo, mat(0x4e3622), posts.length);
  posts.forEach((m, i) => postMesh.setMatrixAt(i, m));
  postMesh.castShadow = true;
  postMesh.receiveShadow = true;
  root.add(postMesh);

  // ---------------------------------------------------------------- jetty
  addCollider(boxOf(0, -34, 3, 8, 0.4));
  root.add(mesh(new THREE.BoxGeometry(3, 0.22, 8), mat(0x6e5237), 0, 0.28, -34));
  for (let z = -37.5; z <= -30.5; z += 1.75)
    for (const sx of [-1, 1]) root.add(mesh(new THREE.CylinderGeometry(0.14, 0.14, 1.6, 6), mat(0x3d2a1a), sx * 1.5, -0.1, z));

  // ---------------------------------------------------------------- stalls (gerai)
  const stalls: [number, number, number, number][] = [
    [-11, -19, 2.6, 1.6],
    [11, -8, 1.6, 2.6],
    [-11, 10, 2.6, 1.6],
    [11, 18, 1.6, 2.6],
    [-3, -11, 2.6, 1.6],
    [4, 11, 2.6, 1.6],
    [-20, -11, 2.6, 1.6],
    [20, 11, 2.6, 1.6],
    [-20, 11, 2.6, 1.6],
    [11, -24, 1.6, 2.6],
  ];
  const goods = [0xd24a2b, 0xe0a82e, 0x4d9a3a, 0xf0e0b0];
  for (const [x, z, w, d] of stalls) {
    addCollider(boxOf(x, z, w, d, 1.3));
    root.add(mesh(new THREE.BoxGeometry(w, 1.3, d), mat(0x6a4a2c), x, 0.65, z));
    for (const sx of [-1, 1])
      for (const sz of [-1, 1])
        root.add(mesh(new THREE.CylinderGeometry(0.05, 0.05, 1.1, 5), mat(0x3d2a1a), x + sx * (w / 2 - 0.1), 1.85, z + sz * (d / 2 - 0.1)));
    const aw = atapRoof(w + 0.8, d + 0.8, 2.5, 0.35, pick(roofCols));
    aw.position.x = x;
    aw.position.z = z;
    root.add(aw);
    for (let i = 0; i < 5; i++)
      root.add(mesh(new THREE.SphereGeometry(0.17, 6, 5), mat(pick(goods)), x + (rnd() - 0.5) * (w - 0.5), 1.4, z + (rnd() - 0.5) * (d - 0.5), false));
  }

  // ---------------------------------------------------------------- plaza: well + cannon
  addCollider(boxOf(0, 0, 2.6, 2.6, 0.8));
  root.add(mesh(new THREE.CylinderGeometry(1.4, 1.5, 0.8, 10), mat(0x7d7466), 0, 0.4, 0));
  root.add(mesh(new THREE.CylinderGeometry(1.0, 1.0, 0.1, 10), mat(0x1f4a55, { roughness: 0.2 }), 0, 0.82, 0, false));
  addCollider(boxOf(-3.2, 2.6, 2.2, 0.9, 0.9));
  const cannon = mesh(new THREE.CylinderGeometry(0.3, 0.38, 2.2, 8), mat(0x2f3338, { metalness: 0.5, roughness: 0.5 }), -3.2, 0.95, 2.6);
  cannon.rotation.z = Math.PI / 2.1;
  root.add(cannon);
  root.add(mesh(new THREE.BoxGeometry(1.4, 0.45, 0.9), mat(0x4e3622), -3.2, 0.35, 2.6));

  // ---------------------------------------------------------------- hiding spots (jerami + semak)
  const hay: [number, number][] = [[-11, -3], [11, 5], [3, -13], [-14, 18], [13, -18], [-8, 12]];
  for (const [x, z] of hay) {
    hides.push({ x, z, r: 1.5 });
    root.add(mesh(new THREE.ConeGeometry(1.25, 1.9, 9), mat(0xc9a64a), x, 0.95, z));
    root.add(mesh(new THREE.CylinderGeometry(1.3, 1.3, 0.5, 9), mat(0xb8953e), x, 0.25, z));
  }
  const bush: [number, number][] = [[-31, -5], [31, 8], [0, -29.2], [-5, 31], [31, -14], [-31, 14]];
  for (const [x, z] of bush) {
    hides.push({ x, z, r: 1.6 });
    for (let i = 0; i < 4; i++)
      root.add(mesh(new THREE.IcosahedronGeometry(0.9 + rnd() * 0.3, 0), mat(0x3f6b34), x + (rnd() - 0.5) * 1.2, 0.7 + rnd() * 0.3, z + (rnd() - 0.5) * 1.2));
  }

  // ---------------------------------------------------------------- palms
  const leafGeo = new THREE.PlaneGeometry(0.7, 3.4, 1, 3);
  leafGeo.translate(0, 1.7, 0);
  const palmPos: [number, number][] = [[-31, -12], [-31, 6], [-31, 24], [31, -22], [31, 2], [31, 22], [-26, -29.5], [13, -29.5], [-13, -29.8], [28.5, -29.5], [-5, 31.5], [27, 31], [-27, 31]];
  for (const [x, z] of palmPos) {
    const g = new THREE.Group();
    const trunk = mesh(new THREE.CylinderGeometry(0.2, 0.32, 7.5, 7), mat(0x6e5538), 0, 3.75, 0);
    g.add(trunk);
    for (let i = 0; i < 8; i++) {
      const leaf = new THREE.Mesh(leafGeo, mat(0x3c7a38, { side: THREE.DoubleSide }));
      leaf.position.y = 7.4;
      leaf.rotation.order = "YXZ";
      leaf.rotation.y = (i / 8) * Math.PI * 2;
      leaf.rotation.x = 1.15;
      leaf.castShadow = true;
      g.add(leaf);
    }
    g.position.set(x, 0, z);
    g.rotation.z = (rnd() - 0.5) * 0.12;
    root.add(g);
  }

  // ---------------------------------------------------------------- harbour: prahu + a big foreign ship
  function prahu(x: number, z: number, rotY: number, scale = 1) {
    const g = new THREE.Group();
    const hull = mesh(new THREE.SphereGeometry(1, 10, 6, 0, Math.PI * 2, Math.PI / 2, Math.PI / 2), mat(0x5a3d26), 0, 0.35, 0);
    hull.scale.set(0.9, 0.7, 3.2);
    g.add(hull);
    g.add(mesh(new THREE.CylinderGeometry(0.05, 0.06, 4.2, 5), mat(0x3d2a1a), 0, 2.2, 0));
    const sail = new THREE.Shape();
    sail.moveTo(0, 0);
    sail.lineTo(2.4, 0);
    sail.lineTo(0, 3.4);
    const sm = mesh(new THREE.ShapeGeometry(sail), mat(0xd9c9a0, { side: THREE.DoubleSide }), 0, 1.0, 0);
    sm.rotation.y = Math.PI / 2;
    g.add(sm);
    g.position.set(x, -0.1, z);
    g.rotation.y = rotY;
    g.scale.setScalar(scale);
    root.add(g);
  }
  prahu(-11, -36, 0.3);
  prahu(10, -39, -0.2, 1.1);
  prahu(-22, -44, 1.2, 0.9);
  prahu(22, -34, 1.5);
  {
    // foreign carrack at anchor, hazy in the fog
    const g = new THREE.Group();
    g.add(mesh(new THREE.BoxGeometry(9, 5, 30), mat(0x2f2620), 0, 1.5, 0));
    g.add(mesh(new THREE.BoxGeometry(9.6, 2.4, 8), mat(0x3a2e24), 0, 5.2, -11));
    for (const z of [-8, 1, 9]) {
      g.add(mesh(new THREE.CylinderGeometry(0.2, 0.25, 22, 6), mat(0x3d2a1a), 0, 14, z));
      g.add(mesh(new THREE.BoxGeometry(11, 7, 0.15), mat(0xe8dcc0), 0, 14, z + 0.3));
    }
    g.position.set(-26, 0, -85);
    g.rotation.y = 0.5;
    root.add(g);
  }

  // ---------------------------------------------------------------- lanterns
  const lampPos: [number, number][] = [
    [-5, 5], [5, -5], [-11, -12], [11, 12], [0, -29],
    [-28, 28], [-8, 16], [8, 16], [-8, -15], [8, -15], [-15, -8.5], [15, 8.5], [-14, 0], [14, 0], [-10, 30], [10, 30], [4, -31],
  ];
  const litLamps = spreadIndices(lampPos.length, opts.lampLights ?? lampPos.length);
  for (const [i, [x, z]] of lampPos.entries()) {
    root.add(mesh(new THREE.CylinderGeometry(0.07, 0.09, 3, 5), mat(0x3d2a1a), x, 1.5, z));
    root.add(mesh(new THREE.SphereGeometry(0.28, 8, 6), new THREE.MeshBasicMaterial({ color: 0xffb14a }), x, 3.1, z, false));
    if (!litLamps.has(i)) continue;
    const l = new THREE.PointLight(0xffa04a, 11, 17, 1.5);
    l.position.set(x, 3.0, z);
    root.add(l);
  }

  // ---------------------------------------------------------------- instanced windows
  const addWindows = (list: THREE.Matrix4[], m: THREE.Material) => {
    const im = new THREE.InstancedMesh(new THREE.BoxGeometry(0.85, 1.0, 0.12), m, Math.max(list.length, 1));
    im.count = list.length;
    list.forEach((mx, i) => im.setMatrixAt(i, mx));
    root.add(im);
  };
  addWindows(winLit, new THREE.MeshBasicMaterial({ color: 0xffc069 }));
  addWindows(winDark, mat(0x1c120b));

  // ---------------------------------------------------------------- exit beam
  const exitBeam = new THREE.Mesh(
    new THREE.CylinderGeometry(0.9, 0.9, 30, 16, 1, true),
    new THREE.MeshBasicMaterial({ color: 0x5affc8, transparent: true, opacity: 0.0, depthWrite: false, side: THREE.DoubleSide }),
  );
  exitBeam.position.set(0, 15, -36);
  root.add(exitBeam);

  const guards: GuardDef[] = [
    { waypoints: [{ x: -7.8, z: -24 }, { x: -7.8, z: 24 }] },
    { waypoints: [{ x: 8, z: -24 }, { x: 8, z: 24 }] },
    { waypoints: [{ x: -24, z: -8.5 }, { x: 24, z: -8.5 }] },
    { waypoints: [{ x: 24, z: 8.5 }, { x: -24, z: 8.5 }] },
    { waypoints: [{ x: -4.5, z: -4.5 }, { x: 4.5, z: -4.5 }, { x: 4.5, z: 4.5 }, { x: -4.5, z: 4.5 }] },
    { waypoints: [{ x: -2.4, z: 5.8 }, { x: 2.4, z: 5.8 }], isTarget: true },
  ];

  return {
    root,
    colliders,
    occluders,
    hides,
    guards,
    start: { x: -31.5, z: 31.5 },
    exit: { x: 0, z: -36 },
    exitBeam,
    bounds: { minX: -33.6, maxX: 33.6, minZ: -37.4, maxZ: 33.6, jettyZ: -31, jettyHalf: 1.1 },
  };
}
