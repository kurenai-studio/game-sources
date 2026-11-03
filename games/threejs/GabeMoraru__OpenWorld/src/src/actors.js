import * as THREE from 'three';

const lam = (color) => new THREE.MeshLambertMaterial({ color, flatShading: true });
const glow = (r, g, b) => new THREE.MeshBasicMaterial({ color: new THREE.Color(r, g, b) });
const box = (w, h, d, mat, x = 0, y = 0, z = 0) => {
  const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
  m.position.set(x, y, z);
  return m;
};

export function buildCar() {
  const root = new THREE.Group();
  const body = new THREE.Group();
  root.add(body);
  const shell = lam('#e9d8b4'), dark = lam('#1c1e2b'), stripe = lam('#2f7f86'), glass = lam('#273449');
  body.add(
    box(2.3, 0.75, 4.8, shell, 0, 0.95, 0),
    box(2.32, 0.18, 4.82, stripe, 0, 1.12, 0),
    box(2.1, 1.05, 1.9, shell, 0, 1.85, 0.45),
    box(1.95, 0.7, 0.08, glass, 0, 1.98, 1.42),
    box(2.12, 0.6, 1.4, glass, 0, 1.98, 0.45),
    box(2.25, 0.25, 1.2, shell, 0, 1.4, 1.85),
    box(2.3, 0.5, 0.14, dark, 0, 1.45, -1.05),
    box(0.14, 0.5, 2.1, dark, 1.08, 1.45, -1.55),
    box(0.14, 0.5, 2.1, dark, -1.08, 1.45, -1.55),
    box(2.3, 0.5, 0.14, dark, 0, 1.45, -2.35),
    box(2.4, 0.3, 0.3, dark, 0, 0.75, 2.45),
    box(2.4, 0.3, 0.3, dark, 0, 0.75, -2.45),
    box(1.9, 0.1, 0.9, dark, 0, 2.42, 0.4)
  );
  const tankMat = glow(0.2, 0.1, 0.05);
  const tank = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.62, 1.9, 12).rotateX(Math.PI / 2), tankMat);
  tank.position.set(0, 1.75, -1.6);
  const tankCage = new THREE.Mesh(new THREE.TorusGeometry(0.68, 0.06, 4, 12), dark);
  tankCage.position.set(0, 1.75, -1.6);
  body.add(tank, tankCage, tankCage.clone().translateZ(0.7), tankCage.clone().translateZ(-0.7));
  const head = glow(4, 3.4, 2.4), tail = glow(4, 0.25, 0.3);
  for (const s of [-1, 1]) {
    body.add(box(0.5, 0.26, 0.08, head, s * 0.75, 1.05, 2.42), box(0.4, 0.22, 0.08, tail, s * 0.8, 1.05, -2.42));
    body.add(box(0.2, 0.12, 0.2, glow(1.6, 0.9, 0.25), s * 0.85, 2.52, 0.9));
  }
  const wheels = [];
  const tire = lam('#141420'), hub = lam('#8d8aa3');
  for (const [x, z] of [[1.12, 1.55], [-1.12, 1.55], [1.12, -1.55], [-1.12, -1.55]]) {
    const pivot = new THREE.Group();
    pivot.position.set(x, 0.52, z);
    const wheel = new THREE.Group();
    wheel.add(new THREE.Mesh(new THREE.CylinderGeometry(0.52, 0.52, 0.42, 12).rotateZ(Math.PI / 2), tire));
    wheel.add(new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.26, 0.44, 6).rotateZ(Math.PI / 2), hub));
    pivot.add(wheel);
    root.add(pivot);
    wheels.push({ pivot, wheel, front: z > 0 });
  }
  const under = new THREE.Mesh(
    new THREE.PlaneGeometry(4, 7).rotateX(-Math.PI / 2),
    new THREE.MeshBasicMaterial({ color: new THREE.Color(0.3, 0.15, 0.05), transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, map: softTexture() })
  );
  under.position.y = 0.12;
  root.add(under);
  const spot = new THREE.SpotLight('#ffe0b0', 900, 90, 0.55, 0.6, 1.6);
  spot.position.set(0, 1.3, 2.4);
  spot.target.position.set(0, -2, 22);
  root.add(spot, spot.target);
  return { root, body, wheels, tankMat, tank };
}

export function buildWalker() {
  const root = new THREE.Group();
  const coat = lam('#2b5d63'), pants = lam('#262838'), skin = lam('#e3b896'), scarf = lam('#e0664f'), hat = lam('#3a2f3f');
  const limb = (w, h, d, mat, x, y) => {
    const pivot = new THREE.Group();
    pivot.position.set(x, y, 0);
    pivot.add(box(w, h, d, mat, 0, -h / 2, 0));
    root.add(pivot);
    return pivot;
  };
  const legs = [limb(0.26, 0.92, 0.3, pants, 0.16, 0.95), limb(0.26, 0.92, 0.3, pants, -0.16, 0.95)];
  const arms = [limb(0.2, 0.78, 0.22, coat, 0.45, 1.75), limb(0.2, 0.78, 0.22, coat, -0.45, 1.75)];
  root.add(
    box(0.72, 0.9, 0.44, coat, 0, 1.4, 0),
    box(0.76, 0.18, 0.5, scarf, 0, 1.84, 0),
    box(0.16, 0.5, 0.08, scarf, 0.18, 1.6, -0.28),
    new THREE.Mesh(new THREE.SphereGeometry(0.27, 10, 8).translate(0, 2.12, 0), skin),
    box(0.58, 0.14, 0.58, hat, 0, 2.36, 0),
    box(0.38, 0.22, 0.38, hat, 0, 2.5, 0)
  );
  const lanternMat = glow(3, 1.6, 0.5);
  const lantern = box(0.2, 0.28, 0.2, lanternMat, 0, -0.85, 0.1);
  arms[0].add(lantern);
  return { root, legs, arms, lanternMat, phase: 0 };
}

export function buildHollowMeshes(scene, max) {
  const profile = [[0, 0], [0.45, 0.25], [0.8, 0.9], [0.75, 1.6], [0.45, 2.15], [0, 2.4]].map(([r, y]) => new THREE.Vector2(r, y));
  const bodies = new THREE.InstancedMesh(new THREE.LatheGeometry(profile, 9), new THREE.MeshBasicMaterial({ color: '#06040c' }), max);
  const eyeGeo = new THREE.SphereGeometry(0.11, 6, 4);
  const eyes = new THREE.InstancedMesh(
    mergeTwo(eyeGeo.clone().translate(0.24, 1.85, 0.62), eyeGeo.clone().translate(-0.24, 1.85, 0.62)),
    new THREE.MeshBasicMaterial({ color: new THREE.Color(5, 0.5, 2.6) }), max
  );
  const aura = new THREE.InstancedMesh(
    new THREE.PlaneGeometry(7, 7).rotateX(-Math.PI / 2),
    new THREE.MeshBasicMaterial({ color: new THREE.Color(0.3, 0.05, 0.38), transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, map: softTexture() }), max
  );
  for (const m of [bodies, eyes, aura]) {
    m.frustumCulled = false;
    m.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    scene.add(m);
  }
  return { bodies, eyes, aura };
}

function mergeTwo(a, b) {
  const g = new THREE.BufferGeometry();
  const pa = a.toNonIndexed().attributes.position.array, pb = b.toNonIndexed().attributes.position.array;
  const p = new Float32Array(pa.length + pb.length);
  p.set(pa);
  p.set(pb, pa.length);
  g.setAttribute('position', new THREE.BufferAttribute(p, 3));
  return g;
}

let soft;
export function softTexture() {
  if (soft) return soft;
  const c = document.createElement('canvas');
  c.width = c.height = 64;
  const ctx = c.getContext('2d'), g = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
  g.addColorStop(0, 'rgba(255,255,255,1)');
  g.addColorStop(0.35, 'rgba(255,255,255,0.45)');
  g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 64, 64);
  soft = new THREE.CanvasTexture(c);
  return soft;
}

export function buildTrafficMeshes(scene, max) {
  const body = new THREE.InstancedMesh(new THREE.BoxGeometry(2, 1.3, 4.2).translate(0, 1.0, 0), lam('#ffffff'), max);
  const g = new THREE.BufferGeometry();
  const quads = [[0.65, 2.12, 1], [-0.65, 2.12, 1], [0.65, -2.12, 0], [-0.65, -2.12, 0]];
  const pos = [], col = [];
  for (const [x, z, front] of quads) {
    const b = new THREE.BoxGeometry(0.45, 0.25, 0.06).translate(x, 1.0, z).toNonIndexed();
    pos.push(...b.attributes.position.array);
    for (let k = 0; k < b.attributes.position.count; k++) col.push(...(front ? [4, 3.4, 2.4] : [4, 0.2, 0.25]));
  }
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  const lamps = new THREE.InstancedMesh(g, new THREE.MeshBasicMaterial({ vertexColors: true }), max);
  for (const m of [body, lamps]) {
    m.frustumCulled = false;
    m.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    scene.add(m);
  }
  return { body, lamps };
}
