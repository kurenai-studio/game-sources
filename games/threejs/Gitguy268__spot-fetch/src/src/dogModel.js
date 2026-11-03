// De hond zelf: vorm, vacht en animatie. In code opgebouwd uit buizen met een vacht van laagjes;
// de poten staan met IK op vaste voetpunten, zodat ze niet schuiven.
// Assen van de hond: +z is vooruit, +y omhoog, de oorsprong ligt op de grond onder het midden.
import * as THREE from 'three';
import { furMesh } from './fur.js';

const TAU = Math.PI * 2;
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const lerp = (a, b, t) => a + (b - a) * t;
const damp = (a, b, k, dt) => a + (b - a) * (1 - Math.exp(-k * dt));
const frac = (x) => x - Math.floor(x);
const ease = (t) => t * t * (3 - 2 * t);

// Buis langs +z met elliptische doorsnedes [z, rx, ry, cy], vloeiend (Catmull-Rom) tussen de sleutels.
function tube(keys, radial = 14, sub = 4) {
  const cr = (a, b, c, d, t) => 0.5 * (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (3 * b - a - 3 * c + d) * t * t * t);
  const key = (i) => keys[clamp(i, 0, keys.length - 1)];
  const rings = [];
  for (let i = 0; i < keys.length - 1; i++)
    for (let s = 0; s < sub; s++)
      rings.push([0, 1, 2, 3].map((c) => cr(key(i - 1)[c] || 0, key(i)[c] || 0, key(i + 1)[c] || 0, key(i + 2)[c] || 0, s / sub)));
  rings.push([0, 1, 2, 3].map((c) => keys.at(-1)[c] || 0));

  const pos = [], uv = [], idx = [], n = radial + 1;
  rings.forEach(([z, rx, ry, cy], i) => {
    for (let j = 0; j <= radial; j++) {
      const a = (j / radial) * TAU;
      pos.push(Math.max(rx, 1e-4) * Math.cos(a), cy + Math.max(ry, 1e-4) * Math.sin(a), z);
      uv.push(j / radial, i / (rings.length - 1));
    }
  });
  for (let i = 0; i < rings.length - 1; i++)
    for (let j = 0; j < radial; j++) {
      const a = i * n + j;
      idx.push(a, a + 1, a + n, a + 1, a + n + 1, a + n);
    }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  // De naad (eerste en laatste kolom vallen samen) krijgt één normaal.
  const nr = g.attributes.normal, va = new THREE.Vector3(), vb = new THREE.Vector3();
  for (let i = 0; i < rings.length; i++) {
    va.fromBufferAttribute(nr, i * n).add(vb.fromBufferAttribute(nr, i * n + radial)).normalize();
    nr.setXYZ(i * n, va.x, va.y, va.z);
    nr.setXYZ(i * n + radial, va.x, va.y, va.z);
  }
  const omtrek = (Math.PI * keys.reduce((s, k) => s + k[1] + k[2], 0)) / keys.length;
  g.userData.maat = [omtrek, keys.at(-1)[0] - keys[0][0]];
  return g;
}
const legTube = (keys) => tube(keys, 12, 3).rotateX(Math.PI / 2); // wijst omlaag; ry wordt voor-achter

const H = 0.455; // hoogte van het lichaamsmidden boven de grond
// Meters die een poot per standfase over de grond aflegt. Het pasritme volgt hieruit, zodat de
// stand altijd binnen het bereik van de poten blijft en ze niet gaan zweven of schuiven.
const PAS = 0.4;
const VOOR = {
  joint: [0.085, -0.07, 0.2], L: [0.18, 0.21, 0.075], home: [0.09, 0.21], lig: [0.1, 0.46], knik: -1, hoek: -0.2,
  boven: [[-0.04, 0.02, 0.03], [0, 0.036, 0.052], [0.09, 0.032, 0.042], [0.18, 0.027, 0.03], [0.2, 0.015, 0.018]],
  onder: [[-0.02, 0.018, 0.02], [0, 0.027, 0.03], [0.11, 0.022, 0.024], [0.21, 0.02, 0.021], [0.225, 0.012, 0.012]],
  voet: [[-0.015, 0.014, 0.014], [0, 0.02, 0.021], [0.05, 0.02, 0.021], [0.07, 0.016, 0.016]],
};
const ACHTER = {
  joint: [0.08, -0.03, -0.24], L: [0.2, 0.2, 0.13], home: [0.085, -0.3], lig: [0.17, -0.2], knik: 1, hoek: -0.25,
  boven: [[-0.05, 0.02, 0.04], [0, 0.045, 0.08, -0.005], [0.1, 0.04, 0.062], [0.2, 0.03, 0.036], [0.22, 0.015, 0.018]],
  onder: [[-0.02, 0.02, 0.022], [0, 0.03, 0.036], [0.1, 0.023, 0.027], [0.2, 0.018, 0.02], [0.215, 0.01, 0.01]],
  voet: [[-0.015, 0.012, 0.013], [0, 0.018, 0.02], [0.08, 0.016, 0.017], [0.115, 0.018, 0.018], [0.125, 0.012, 0.012]],
};
// Fase per poot [links voor, rechts voor, links achter, rechts achter] en het deel van de pas dat de poot staat.
const STAP = { off: [0.25, 0.75, 0, 0.5], duty: 0.6 };
const DRAF = { off: [0, 0.5, 0.5, 0], duty: 0.45 };
const GALOP = { off: [0.55, 0.45, 0, 0.1], duty: 0.24 };

export function createDog(cfg, lagen = 16) {
  if (cfg.modelUrl) return glbDog(cfg);
  const fur = (geo, k = 1) =>
    furMesh(geo, { kleur: cfg.vacht, glans: cfg.glans, lengte: cfg.haar * k, cel: 0.0028, lagen, maat: geo.userData.maat });

  const root = new THREE.Group();
  root.scale.setScalar(cfg.schaal);
  const body = new THREE.Group();
  root.add(body);

  const torso = fur(tube([
    [-0.34, 0.02, 0.02, 0.03], [-0.31, 0.085, 0.09, 0.02], [-0.22, 0.105, 0.115, 0], [-0.08, 0.1, 0.105, 0.01],
    [0.08, 0.115, 0.135, -0.015], [0.2, 0.115, 0.14, -0.02], [0.29, 0.09, 0.115, 0], [0.33, 0.02, 0.03, 0.02],
  ], 18));
  body.add(torso);

  // Nek en kop
  const neck = new THREE.Group();
  neck.position.set(0, 0.055, 0.25);
  neck.rotation.order = 'YXZ';
  body.add(neck);
  neck.add(fur(tube([[-0.05, 0.06, 0.07], [0, 0.074, 0.085], [0.08, 0.066, 0.074], [0.16, 0.056, 0.06], [0.2, 0.045, 0.048]])));
  const halsband = new THREE.Mesh(
    new THREE.TorusGeometry(0.077, 0.007, 10, 28),
    new THREE.MeshStandardMaterial({ color: cfg.halsband, roughness: 0.55 }),
  );
  halsband.position.z = 0.075;
  halsband.scale.set(1, 1.1, 2.2); // platgedrukt tot een band
  halsband.castShadow = true;
  const penning = new THREE.Mesh(
    new THREE.CylinderGeometry(0.014, 0.014, 0.003, 16).rotateX(Math.PI / 2),
    new THREE.MeshStandardMaterial({ color: 0xd9b24a, roughness: 0.25, metalness: 1 }),
  );
  penning.position.set(0, -0.1, 0.085);
  neck.add(halsband, penning);

  const head = new THREE.Group();
  head.position.z = 0.17;
  head.rotation.order = 'YXZ';
  neck.add(head);
  head.add(fur(tube([
    [-0.08, 0.01, 0.01, 0.015], [-0.065, 0.055, 0.058, 0.015], [0, 0.07, 0.072, 0.018], [0.05, 0.064, 0.062, 0.012],
    [0.085, 0.045, 0.047, -0.01], [0.135, 0.04, 0.04, -0.016], [0.178, 0.035, 0.035, -0.018], [0.195, 0.014, 0.014, -0.016],
  ], 16), 0.4));
  const neus = new THREE.Mesh(new THREE.SphereGeometry(0.017, 16, 12), new THREE.MeshStandardMaterial({ color: 0x050505, roughness: 0.25 }));
  neus.position.set(0, -0.006, 0.19);
  neus.scale.set(1.15, 0.9, 0.8);
  head.add(neus);
  const oogMat = new THREE.MeshPhysicalMaterial({ color: 0x1c0e06, roughness: 0.05, clearcoat: 1 });
  for (const side of [1, -1]) {
    const oog = new THREE.Mesh(new THREE.SphereGeometry(0.011, 14, 10), oogMat);
    oog.position.set(0.04 * side, 0.036, 0.072);
    head.add(oog);
  }
  const jaw = new THREE.Group();
  jaw.position.set(0, -0.052, 0.06);
  head.add(jaw);
  jaw.add(fur(tube([[-0.01, 0.02, 0.01], [0, 0.03, 0.014], [0.07, 0.027, 0.012], [0.12, 0.022, 0.01, 0.002], [0.132, 0.008, 0.005, 0.002]], 10, 3), 0.3));
  const tong = new THREE.Mesh(new THREE.SphereGeometry(1, 12, 8), new THREE.MeshStandardMaterial({ color: 0xd9667a, roughness: 0.45 }));
  tong.scale.set(0.017, 0.004, 0.05);
  jaw.add(tong);
  const mouth = new THREE.Object3D(); // hier zit de bal bij het dragen
  mouth.position.set(0, -0.055, 0.165);
  head.add(mouth);

  const earGeo = tube([[0, 0.022, 0.005], [0.03, 0.038, 0.007], [0.075, 0.034, 0.006], [0.115, 0.012, 0.004]], 10, 3)
    .rotateX(Math.PI / 2).rotateY(Math.PI / 2);
  const ears = [1, -1].map((side) => {
    const ear = new THREE.Group();
    ear.position.set(0.058 * side, 0.04, -0.01);
    ear.add(fur(earGeo, 0.5));
    ear.userData.side = side;
    head.add(ear);
    return ear;
  });

  // Staart: vier segmenten, naar achteren
  const tailRoot = new THREE.Group();
  tailRoot.position.set(0, 0.05, -0.31);
  tailRoot.rotation.y = Math.PI;
  body.add(tailRoot);
  const tail = [];
  [[0.032, 0.026], [0.026, 0.021], [0.021, 0.016], [0.016, 0.006]].reduce((parent, [r0, r1], i) => {
    const seg = new THREE.Group();
    seg.position.z = i ? 0.085 : 0;
    seg.add(fur(tube([[-0.015, r0 * 0.8, r0 * 0.8], [0, r0, r0], [0.085, r1, r1], [0.1, r1 * 0.5, r1 * 0.5]], 8, 2)));
    parent.add(seg);
    tail.push(seg);
    return seg;
  }, tailRoot);

  // Poten
  const pawGeo = tube([[-0.035, 0.008, 0.008], [-0.02, 0.026, 0.018], [0.01, 0.03, 0.02], [0.035, 0.022, 0.014, -0.004], [0.045, 0.006, 0.006, -0.006]], 10, 3);
  const legs = [[VOOR, 1], [VOOR, -1], [ACHTER, 1], [ACHTER, -1]].map(([spec, side]) => {
    const hip = new THREE.Group();
    hip.position.set(spec.joint[0] * side, spec.joint[1], spec.joint[2]);
    hip.rotation.order = 'ZXY';
    const knee = new THREE.Group();
    knee.position.y = -spec.L[0];
    const ankle = new THREE.Group();
    ankle.position.y = -spec.L[1];
    const paw = fur(pawGeo, 0.4);
    paw.position.set(0, -spec.L[2] + 0.02, 0.012);
    paw.rotation.x = -spec.hoek;
    hip.add(fur(legTube(spec.boven)), knee);
    knee.add(fur(legTube(spec.onder), 0.6), ankle);
    ankle.add(fur(legTube(spec.voet), 0.5), paw);
    body.add(hip);
    return { spec, side, hip, knee, ankle, pos: new THREE.Vector3(1e3, 0, 0), from: new THREE.Vector3(), swing: false, st: null, sw0: 0, lift: 0 };
  });

  const S = { t: 0, clock: 0, off: [...STAP.off], duty: STAP.duty, sit: 0, lie: 0, swim: 0, hd: 0, yaw: 0, up: 0, wag: 0, adem: 0, bark: 0 };
  const home = new THREE.Vector3(), doel = new THREE.Vector3(), loc = new THREE.Vector3();

  // Tweebots-IK in het vlak van de poot, plus zijwaarts kantelen vanuit de heup.
  function solve(leg, enkel, pawPitch, bodyPitch) {
    const [L1, L2] = leg.spec.L;
    const dx = enkel.x - leg.hip.position.x, dy = Math.min(enkel.y - leg.hip.position.y, -0.02), dz = enkel.z - leg.hip.position.z;
    const omlaag = Math.hypot(dx, dy);
    const d = clamp(Math.hypot(omlaag, dz), Math.abs(L1 - L2) + 0.02, L1 + L2 - 0.002);
    const A = Math.acos(clamp((L1 * L1 + d * d - L2 * L2) / (2 * L1 * d), -1, 1));
    const K = Math.acos(clamp((L1 * L1 + L2 * L2 - d * d) / (2 * L1 * L2), -1, 1));
    const t1 = Math.atan2(dz, omlaag) + leg.spec.knik * A;
    const t2 = -leg.spec.knik * (Math.PI - K);
    leg.hip.rotation.set(-t1, 0, Math.atan2(dx, -dy));
    leg.knee.rotation.x = -t2;
    leg.ankle.rotation.x = pawPitch + t1 + t2 - bodyPitch;
  }

  // d: de hond uit brain.js (pos, heading, speed, pose, swim, look, headDown, sniff, pant, wag, alert, hasBall)
  function update(dt, d) {
    S.t += dt;
    const v = d.speed;
    root.position.set(d.pos.x, 0, d.pos.z);
    root.rotation.y = d.heading;
    S.sit = damp(S.sit, d.pose === 'zit' ? 1 : 0, 7, dt);
    S.lie = damp(S.lie, d.pose === 'lig' ? 1 : 0, 5, dt);
    S.swim = damp(S.swim, d.swim ? 1 : 0, 4, dt);
    S.hd = damp(S.hd, d.headDown, 9, dt);

    // Gang: stap, draf of galop naar snelheid
    const gang = v < 1.5 ? STAP : v < 3 ? DRAF : GALOP;
    const f = d.swim ? 1.8 : Math.max(1.2, (v * S.duty) / PAS);
    const loopt = v > 0.15 || d.swim;
    if (loopt) S.clock += f * dt;
    const k = 1 - Math.exp(-8 * dt);
    S.duty += (gang.duty - S.duty) * k;
    for (let i = 0; i < 4; i++) S.off[i] += (frac(gang.off[i] - S.off[i] + 0.5) - 0.5) * k;
    const gal = clamp((v - 2.8) / 1, 0, 1) * (1 - S.swim);
    const c = S.clock * TAU;
    const dein = (1 - gal) * 0.012 * Math.min(v / 2, 1) * Math.sin(2 * c) + gal * 0.035 * Math.sin(c + 1);
    const staand = (1 - S.sit) * (1 - S.lie);
    body.position.set(0, H + dein - 0.2 * S.sit - 0.3 * S.lie - 0.52 * S.swim - 0.08 * S.hd * staand, -0.04 * S.sit);
    body.rotation.x = -0.6 * S.sit + gal * 0.1 * Math.sin(c - 0.6) + 0.35 * S.hd * staand - 0.12 * S.swim;
    body.rotation.z = (1 - gal) * 0.025 * Math.sin(c) * Math.min(v, 1);
    root.updateMatrixWorld(true);
    const bp = body.rotation.x;

    // Voeten: in de standfase vast op de grond, in de zwaaifase naar het volgende landingspunt
    const fx = Math.sin(d.heading), fz = Math.cos(d.heading);
    const standT = S.duty / f, zwaaiT = (1 - S.duty) / f;
    let stapt = legs.some((l) => l.swing);
    legs.forEach((leg, i) => {
      const sp = leg.spec;
      home.set(leg.side * lerp(sp.home[0], sp.lig[0], S.lie), 0, lerp(sp.home[1], sp.lig[1], S.lie));
      root.localToWorld(home);
      if (S.swim > 0.5) {
        const th = (S.clock + S.off[i]) * TAU; // peddelen
        leg.pos.set(leg.side * sp.home[0], -0.4 + 0.07 * Math.cos(th), sp.home[1] + 0.13 * Math.sin(th));
        root.localToWorld(leg.pos);
        leg.swing = false;
        leg.lift = 0.5;
      } else if (leg.pos.distanceToSquared(home) > 1.2) {
        leg.pos.copy(home); // eerste beeld of verplaatst
        leg.swing = false;
      } else if (loopt) {
        const ph = frac(S.clock + S.off[i]);
        if (ph >= S.duty) {
          const sw = (ph - S.duty) / (1 - S.duty);
          if (!leg.swing || leg.st !== null) {
            leg.swing = true;
            leg.st = null;
            leg.sw0 = Math.min(sw, 0.9);
            leg.from.copy(leg.pos).setY(0);
          }
          const s = clamp((sw - leg.sw0) / (1 - leg.sw0), 0, 1);
          const vooruit = (1 - sw) * zwaaiT + standT * 0.5; // zodat de voet halverwege de stand onder de heup staat
          doel.set(home.x + fx * v * vooruit, 0, home.z + fz * v * vooruit);
          leg.lift = Math.sin(Math.PI * s);
          leg.pos.lerpVectors(leg.from, doel, ease(s)).setY((0.035 + 0.012 * Math.min(v, 6) + 0.03 * gal) * leg.lift);
        } else if (leg.swing) {
          leg.swing = false;
          leg.pos.y = 0;
          leg.lift = 0;
        }
      } else {
        // Stilstaan: alleen bijstappen als een poot te ver van zijn plek staat, één tegelijk
        if (!leg.swing && !stapt && Math.hypot(leg.pos.x - home.x, leg.pos.z - home.z) > 0.07) leg.swing = stapt = true;
        if (leg.swing) {
          if (leg.st === null) {
            leg.st = 0;
            leg.from.copy(leg.pos).setY(0);
          }
          leg.st += dt / 0.2;
          const s = Math.min(leg.st, 1);
          leg.lift = Math.sin(Math.PI * s);
          leg.pos.lerpVectors(leg.from, home, ease(s)).setY(0.03 * leg.lift);
          if (s >= 1) {
            leg.swing = false;
            leg.st = null;
          }
        } else leg.lift = 0;
      }

      // De enkel ligt een voetlengte boven het voetpunt; reken om naar lichaamscoördinaten.
      const hoek = sp.hoek + (sp === VOOR ? 0.7 : 0.5) * leg.lift;
      const oy = sp.L[2] * Math.cos(hoek), oz = sp.L[2] * Math.sin(hoek);
      body.worldToLocal(loc.copy(leg.pos));
      loc.y += oy * Math.cos(bp) + oz * Math.sin(bp);
      loc.z += -oy * Math.sin(bp) + oz * Math.cos(bp);
      solve(leg, loc, hoek, bp);
    });

    // Kop volgt het kijkpunt; bij snuffelen en oppakken gaat de neus naar de grond
    let yaw = 0, up = 0;
    if (d.look) {
      body.worldToLocal(loc.set(d.look.x, d.look.y ?? 0.1, d.look.z)).sub(neck.position);
      yaw = clamp(Math.atan2(loc.x, loc.z), -1.4, 1.4);
      up = clamp(Math.atan2(loc.y - 0.12, Math.hypot(loc.x, loc.z)), -0.8, 0.9);
    }
    if (d.sniff) yaw += 0.25 * Math.sin(S.t * 7);
    S.yaw = damp(S.yaw, yaw * (1 - S.hd * 0.7), 8, dt);
    S.up = damp(S.up, up, 8, dt);
    const neckUp = lerp(0.75 + 0.3 * S.up - 0.3 * gal + 0.2 * S.swim, -0.9, S.hd);
    const headUp = lerp(S.up - 0.1, -1.15 + bp, S.hd); // ten opzichte van het lichaam
    neck.rotation.set(-neckUp, S.yaw * 0.5, 0);
    head.rotation.set(neckUp - headUp, S.yaw * 0.5, 0);

    // Bek: bal vasthouden, hijgen, blaffen
    S.bark = Math.max(0, S.bark - dt * 4);
    jaw.rotation.x = Math.max(d.hasBall ? 0.3 : 0, d.pant * (0.2 + 0.05 * Math.sin(S.t * 26)), S.bark * 0.5);
    tong.visible = d.pant > 0.3 && !d.hasBall;
    tong.position.set(0, 0.014, 0.07 + 0.03 * d.pant);

    // Ademhaling: sneller en dieper bij inspanning
    S.adem += dt * TAU * (0.35 + 2.4 * d.pant);
    const adem = Math.sin(S.adem) * (1 + d.pant);
    torso.scale.set(1 + 0.012 * adem, 1 + 0.008 * adem, 1);

    const flap = 0.14 * Math.min(v / 5, 1) * Math.max(0, Math.sin(2 * c + 0.5));
    for (const ear of ears) {
      ear.rotation.z = ear.userData.side * (0.22 + flap + 0.2 * d.alert);
      ear.rotation.x = -0.3 * d.alert;
    }

    // Staart: kwispelen naar stemming, gestrekt in galop, plat op de grond bij zitten
    S.wag += dt * (5 + 9 * d.wag);
    const amp = 0.55 * d.wag * (1 - 0.6 * gal);
    tail[0].rotation.x = -(lerp(0.1 + 0.45 * d.wag, 0.05, gal) * (1 - S.lie) + 0.6 * S.sit - 0.3 * S.swim);
    tail.forEach((seg, i) => {
      seg.rotation.y = amp * Math.sin(S.wag - i * 0.6) * (i ? 0.65 : 1);
      if (i) seg.rotation.x = -0.06;
    });
  }

  return { group: root, mouth, update, bark: () => (S.bark = 1) };
}

// shortcut: het GLB-slot is niet met een echt model geprobeerd; clips worden op naam gekoppeld
// (idle, walk, run, sit). Pas dit aan zodra er een model met andere clipnamen in komt.
function glbDog(cfg) {
  const root = new THREE.Group();
  root.scale.setScalar(cfg.schaal);
  const mouth = new THREE.Object3D();
  mouth.position.set(0, 0.45, 0.45);
  root.add(mouth);
  const clips = {};
  let mixer, nu;
  const mislukt = (err) => console.error(`Model ${cfg.modelUrl} laden mislukt`, err);
  // De lader komt pas binnen als er echt een GLB-model is; de honden uit code hoeven hem niet te downloaden.
  import('three/addons/loaders/GLTFLoader.js').then(({ GLTFLoader }) => new GLTFLoader().load(cfg.modelUrl, (gltf) => {
    gltf.scene.traverse((o) => { if (o.isMesh) o.castShadow = true; });
    root.add(gltf.scene);
    mixer = new THREE.AnimationMixer(gltf.scene);
    for (const clip of gltf.animations) clips[clip.name.toLowerCase()] = mixer.clipAction(clip);
  }, undefined, mislukt), mislukt);
  return {
    group: root, mouth, bark() {},
    update(dt, d) {
      root.position.set(d.pos.x, d.swim ? -0.4 : 0, d.pos.z);
      root.rotation.y = d.heading;
      if (!mixer) return;
      const naam = d.pose === 'zit' && clips.sit ? 'sit' : d.speed > 3.5 && clips.run ? 'run' : d.speed > 0.2 ? 'walk' : 'idle';
      const straks = clips[naam] || clips.idle;
      if (straks && straks !== nu) {
        straks.reset().fadeIn(0.2).play();
        nu?.fadeOut(0.2);
        nu = straks;
      }
      mixer.update(dt);
    },
  };
}
