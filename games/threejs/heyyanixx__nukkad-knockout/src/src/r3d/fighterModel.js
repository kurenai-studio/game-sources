import * as THREE from 'three';
import { toon, OUTLINE, lerp, clamp, ease, dotTex } from './common.js';
import { SUPER } from '../moves.js';

// Procedural low-poly toon fighter. Model faces +Z; all geometry is built here (no downloaded models).
const H = 0.84;                // hip height (local units, before char.scale)
const L1 = 0.40, L2 = 0.38;     // thigh / shin
const A1 = 0.27, A2 = 0.27;     // upper arm / forearm+fist
const JOINTS = ['lean', 'twist', 'side', 'pitch', 'spin', 'headX', 'headZ', 'nSx', 'nSz', 'nEx', 'fSx', 'fSz', 'fEx', 'nHx', 'nHz', 'nKx', 'fHx', 'fHz', 'fKx', 'lift', 'mouth'];
const zeroPose = () => Object.fromEntries(JOINTS.map((j) => [j, 0]));

const GEO = {};
function geo(key, make) { return GEO[key] || (GEO[key] = make()); }

export class FighterModel {
  constructor(char, opts = {}) {
    this.char = char; this.L = char.look; this.outline = opts.outline !== false;
    this.mats = [];
    this.root = new THREE.Group(); this.root.name = char.id;
    this.pose = zeroPose(); this.target = zeroPose();
    this.build();
    this.root.scale.setScalar(char.scale);
  }

  mat(color, extra) { const m = toon(color, extra); this.mats.push(m); return m; }

  part(parent, geometry, material, x = 0, y = 0, z = 0, opts = {}) {
    const m = new THREE.Mesh(geometry, material);
    m.position.set(x, y, z);
    if (opts.scale) m.scale.set(...opts.scale);
    if (opts.rot) m.rotation.set(...opts.rot);
    m.castShadow = true;
    if (this.outline && opts.outline !== false) {
      const o = new THREE.Mesh(geometry, OUTLINE); o.scale.setScalar(opts.ol || 1.09); o.castShadow = false; m.add(o);
    }
    parent.add(m);
    return m;
  }

  build() {
    const L = this.L, c = this.char;
    const skin = this.mat(L.skin), shirt = this.mat(L.shirt), pants = this.mat(L.pants), shoes = this.mat(L.shoes), hair = this.mat(L.hair);
    const acc = this.mat(L.acc || c.color);
    this.skinMat = skin; this.accMat = acc;
    const wide = L.wide || 1;
    const cap = (r, l) => geo('cap' + r + l, () => new THREE.CapsuleGeometry(r, l, 3, 8));
    const sph = (r, a = 10, b = 8) => geo('s' + r + a + b, () => new THREE.SphereGeometry(r, a, b));
    const box = (x, y, z) => geo('b' + x + y + z, () => new THREE.BoxGeometry(x, y, z));

    // pitch pivot at hip height (falls, knockdowns), body inside
    this.pitch = new THREE.Group(); this.pitch.position.y = H; this.root.add(this.pitch);
    this.body = new THREE.Group(); this.pitch.add(this.body);
    // pelvis
    this.part(this.body, box(0.3 * wide, 0.16, 0.19), pants, 0, 0.02, 0);
    // legs
    const leg = (side) => {
      const hip = new THREE.Group(); hip.position.set(side * 0.1 * wide, -0.02, 0); this.body.add(hip);
      this.part(hip, cap(0.08, L1 - 0.12), pants, 0, -L1 / 2, 0);
      const knee = new THREE.Group(); knee.position.y = -L1; hip.add(knee);
      this.part(knee, cap(0.068, L2 - 0.1), L.saree ? skin : pants, 0, -L2 / 2, 0);
      const foot = this.part(knee, box(0.12, 0.08, 0.24), shoes, 0, -L2 - 0.02, 0.05);
      return { hip, knee, foot };
    };
    this.legR = leg(-1); this.legL = leg(1);
    if (L.saree) { // saree skirt
      this.part(this.body, geo('saree', () => new THREE.CylinderGeometry(0.17, 0.3, 0.62, 10, 1, true)), this.mat(L.pants, { side: THREE.DoubleSide }), 0, -0.3, 0, { outline: false });
    }
    // spine / torso
    this.spine = new THREE.Group(); this.spine.position.y = 0.06; this.body.add(this.spine);
    const torso = this.part(this.spine, geo('torso', () => new THREE.CylinderGeometry(0.19, 0.15, 0.44, 8)), shirt, 0, 0.22, 0, { scale: [wide, 1, 0.68] });
    this.torso = torso;
    // chest emblem stripe / extras on torso
    if (L.extra === 'anish' || L.extra === 'mintu') this.part(this.spine, box(0.05, 0.36, 0.02), acc, 0.04, 0.22, 0.125, { outline: false });
    if (L.extra === 'hood') {
      const ring = new THREE.Mesh(geo('emb', () => new THREE.TorusGeometry(0.05, 0.012, 6, 16)), acc); ring.position.set(0, 0.27, 0.13); this.spine.add(ring);
    }
    if (L.extra === 'anish') { // gold chain
      const ch = new THREE.Mesh(geo('chain', () => new THREE.TorusGeometry(0.13, 0.014, 6, 20, Math.PI)), this.mat('#ffd36b', { emissive: new THREE.Color('#6b4a00') }));
      ch.rotation.set(Math.PI * 0.62, 0, Math.PI); ch.position.set(0, 0.42, 0.04); this.spine.add(ch);
    }
    if (L.extra === 'towel') this.part(this.spine, box(0.1, 0.42, 0.04), acc, -0.11 * wide, 0.27, 0.1, { rot: [0.15, 0, 0.35] });
    if (L.extra === 'pan') { // frying pan on the back
      const pan = new THREE.Group(); pan.position.set(0, 0.25, -0.15); pan.rotation.set(0.1, 0, 0.5); this.spine.add(pan);
      this.part(pan, geo('pan', () => new THREE.CylinderGeometry(0.2, 0.17, 0.04, 14)), this.mat('#3a3a3a'), 0, 0, 0, { rot: [Math.PI / 2, 0, 0] });
      this.part(pan, box(0.05, 0.28, 0.04), this.mat('#6b4a2b'), 0, -0.3, 0);
    }
    // shoulders / arms
    const arm = (side) => {
      const sh = new THREE.Group(); sh.position.set(side * 0.235 * wide, 0.4, 0); this.spine.add(sh);
      const sleeve = (L.extra === 'hood' || L.extra === 'anish' || L.extra === 'mintu' || L.extra === 'helmet' || L.extra === 'headset') ? shirt : skin;
      this.part(sh, cap(0.062, A1 - 0.1), sleeve, 0, -A1 / 2, 0);
      if (sleeve === skin) this.part(sh, sph(0.075, 8, 6), shirt, 0, -0.02, 0, { outline: false });
      const el = new THREE.Group(); el.position.y = -A1; sh.add(el);
      this.part(el, cap(0.055, A2 - 0.14), skin, 0, -A2 / 2 + 0.03, 0);
      const hand = this.part(el, sph(0.07, 8, 6), skin, 0, -A2 + 0.01, 0.01);
      return { sh, el, hand };
    };
    this.armR = arm(-1); this.armL = arm(1);
    if (L.extra === 'selfie') { // selfie stick in the left hand
      const st = new THREE.Group(); st.position.y = -0.05; this.armL.hand.add(st); st.rotation.x = 0.6;
      this.part(st, geo('stick', () => new THREE.CylinderGeometry(0.012, 0.012, 0.6, 5)), this.mat('#cfcfcf'), 0, 0.3, 0.05, { outline: false });
      this.part(st, box(0.1, 0.17, 0.02), this.mat('#111111'), 0, 0.62, 0.05);
    }
    if (c.id === 'mintu') { // roast mic in the right hand
      const mic = new THREE.Group(); this.armR.hand.add(mic); mic.position.set(0, 0, 0.06);
      this.part(mic, geo('mic', () => new THREE.CylinderGeometry(0.02, 0.015, 0.16, 6)), this.mat('#222222'), 0, 0.03, 0, { outline: false, rot: [0.4, 0, 0] });
      this.part(mic, sph(0.04, 8, 6), this.mat('#999999'), 0, 0.11, 0.04, { outline: false });
    }
    // neck + head
    this.neck = new THREE.Group(); this.neck.position.y = 0.45; this.spine.add(this.neck);
    this.part(this.neck, cap(0.05, 0.04), skin, 0, 0.03, 0, { outline: false });
    this.head = new THREE.Group(); this.head.position.y = 0.08; this.neck.add(this.head);
    const R = L.extra === 'anish' ? 0.175 : 0.17;
    this.part(this.head, sph(R, 14, 10), skin, 0, R, 0, { scale: [0.95, 1.02, 1] });
    if (L.bigEars) for (const s of [-1, 1]) this.part(this.head, geo('ear', () => new THREE.ConeGeometry(0.05, 0.16, 5)), skin, s * 0.17, R + 0.04, -0.02, { rot: [0, 0, -s * 1.1] });
    else for (const s of [-1, 1]) this.part(this.head, sph(0.035, 6, 5), skin, s * 0.165, R, 0, { outline: false });
    // face
    const fy = R + 0.02, fz = R * 0.88;
    const white = this.mat('#ffffff'), black = new THREE.MeshBasicMaterial({ color: 0x111111 });
    this.eyes = [];
    for (const s of [-1, 1]) {
      const e = new THREE.Group(); e.position.set(s * 0.06, fy, fz); this.head.add(e);
      const w = new THREE.Mesh(sph(0.036, 8, 6), white); w.scale.set(1, 1.15, 0.5); e.add(w);
      const pupil = new THREE.Mesh(sph(0.019, 6, 5), L.redEyes ? new THREE.MeshBasicMaterial({ color: 0xff2030 }) : black); pupil.position.set(0, 0, 0.018); e.add(pupil);
      const brow = new THREE.Mesh(box(0.07, 0.016, 0.02), new THREE.MeshBasicMaterial({ color: new THREE.Color(L.hair).multiplyScalar(0.7) }));
      brow.position.set(0, 0.055, 0.01); brow.rotation.z = -s * 0.25; e.add(brow);
      // KO eyes (x x)
      const x1 = new THREE.Mesh(box(0.06, 0.012, 0.01), black); x1.rotation.z = 0.785; x1.position.z = 0.02; x1.visible = false; e.add(x1);
      const x2 = x1.clone(); x2.rotation.z = -0.785; e.add(x2);
      this.eyes.push({ e, w, pupil, brow, x: [x1, x2] });
    }
    this.mouth = new THREE.Mesh(box(0.075, 0.018, 0.02), new THREE.MeshBasicMaterial({ color: 0x5a1a14 })); this.mouth.position.set(0, R - 0.085, fz - 0.005); this.head.add(this.mouth);
    this.part(this.head, sph(0.026, 6, 5), skin, 0, R - 0.02, R * 0.98, { outline: false });
    if (L.redEyes) {
      const glow = new THREE.Sprite(new THREE.SpriteMaterial({ map: dotTex(), color: 0xff2030, blending: THREE.AdditiveBlending, depthWrite: false, transparent: true, opacity: 0.8 }));
      glow.scale.set(0.3, 0.12, 1); glow.position.set(0, fy, fz + 0.03); this.head.add(glow); this.eyeGlow = glow;
    }
    // hair / headwear
    const top = (r, mat, sx = 1.06, phi = 0.62) => this.part(this.head, geo('hair' + r + phi, () => new THREE.SphereGeometry(r, 14, 8, 0, Math.PI * 2, 0, Math.PI * phi)), mat, 0, R, -0.01, { scale: [sx, 1.04, sx], ol: 1.05 });
    switch (L.extra) {
      case 'bun': top(R, hair, 1.07, 0.45); this.part(this.head, sph(0.09, 8, 6), hair, 0, R + 0.1, -0.15); break;
      case 'hood': this.part(this.head, geo('hood', () => new THREE.SphereGeometry(R * 1.25, 12, 9, Math.PI * 0.5 + 1.0, Math.PI * 2 - 2.0, 0, Math.PI * 0.72)), this.mat(L.shirt, { side: THREE.DoubleSide }), 0, R - 0.01, -0.03, { rot: [-0.25, 0, 0], outline: false }); top(R, hair, 1.04, 0.35); break;
      case 'helmet': this.part(this.head, geo('helm', () => new THREE.SphereGeometry(R * 1.18, 12, 8, 0, Math.PI * 2, 0, Math.PI * 0.55)), acc, 0, R, 0, { rot: [-0.15, 0, 0] });
        this.part(this.head, box(0.3, 0.07, 0.04), this.mat('#123040', { emissive: new THREE.Color('#0a6a8a') }), 0, R + 0.08, R * 0.95, { outline: false }); break;
      case 'headset': top(R, hair, 1.06, 0.5);
        this.part(this.head, geo('band', () => new THREE.TorusGeometry(R * 1.12, 0.02, 6, 16, Math.PI)), acc, 0, R, 0, { outline: false });
        for (const s of [-1, 1]) this.part(this.head, geo('cup', () => new THREE.CylinderGeometry(0.065, 0.065, 0.05, 10)), this.mat('#1d1d28'), s * 0.18, R, 0, { rot: [0, 0, Math.PI / 2] });
        break;
      case 'anish': { // spiky silver hair
        top(R, hair, 1.06, 0.5);
        const spike = geo('spike', () => new THREE.ConeGeometry(0.06, 0.22, 5));
        const spots = [[0, 0.17, 0.05, -0.2, 0], [0.09, 0.15, 0.02, -0.3, -0.5], [-0.09, 0.15, 0.02, -0.3, 0.5], [0.05, 0.12, -0.1, 0.5, -0.3], [-0.05, 0.12, -0.1, 0.5, 0.3], [0, 0.1, 0.14, -0.9, 0]];
        for (const [x, y, z, rx, rz] of spots) this.part(this.head, spike, hair, x, R + y, z, { rot: [rx, 0, rz], ol: 1.06 });
        break;
      }
      case 'selfie': top(R, hair, 1.06, 0.5); break;
      default: top(R, hair, 1.06, 0.5);
    }
    if (L.extra === 'mustache') this.part(this.head, box(0.13, 0.03, 0.03), this.mat(L.hair), 0, R - 0.055, R * 0.92, { outline: false });
    if (L.beard) this.part(this.head, geo('beard', () => new THREE.SphereGeometry(R * 0.98, 12, 6, 0, Math.PI * 2, Math.PI * 0.55, Math.PI * 0.35)), this.mat(L.hair), 0, R + 0.005, 0.01, { outline: false });
    if (L.glasses || L.shades) {
      const gm = L.shades ? this.mat('#0d0d0d') : this.mat('#c9a24a');
      for (const s of [-1, 1]) {
        const lens = new THREE.Mesh(L.shades ? box(0.08, 0.045, 0.01) : geo('lens', () => new THREE.TorusGeometry(0.035, 0.008, 5, 12)), gm);
        lens.position.set(s * 0.06, fy, fz + 0.03); this.head.add(lens);
      }
    }
    // dizzy stars
    this.stars = new THREE.Group(); this.stars.position.y = R * 2 + 0.06; this.head.add(this.stars); this.stars.visible = false;
    const starMat = new THREE.MeshBasicMaterial({ color: 0xffe066 });
    for (let i = 0; i < 3; i++) { const s = new THREE.Mesh(geo('dstar', () => new THREE.OctahedronGeometry(0.045, 0)), starMat); s.position.set(Math.cos(i * 2.1) * 0.2, 0, Math.sin(i * 2.1) * 0.2); this.stars.add(s); }
    // aura (supers, boss)
    this.aura = new THREE.Sprite(new THREE.SpriteMaterial({ map: dotTex(), color: new THREE.Color(c.superColor || c.color), blending: THREE.AdditiveBlending, depthWrite: false, transparent: true, opacity: 0 }));
    this.aura.scale.set(2.2, 2.6, 1); this.aura.position.y = 0.95; this.root.add(this.aura);
    if (L.rgb) this.rgbMats = [acc, shoes];
    // hand / foot world-position helpers for trails
    this.tipHandN = new THREE.Object3D(); this.tipHandF = new THREE.Object3D(); this.tipFootN = new THREE.Object3D(); this.tipFootF = new THREE.Object3D();
  }

  limbs(facing) {
    // the limb nearer the camera is the "near" one; model's right side faces camera when facing +X
    return facing === 1 ? { nA: this.armR, fA: this.armL, nL: this.legR, fL: this.legL } : { nA: this.armL, fA: this.armR, nL: this.legL, fL: this.legR };
  }

  // Decide the target pose from the simulation state.
  computeTarget(f, game, time) {
    const T = this.target; for (const j of JOINTS) T[j] = 0;
    const a = f.attack, m = a && a.move;
    const bob = Math.sin(time * 4.2 + f.side) * 0.04;
    const guard = () => { T.nSx = -0.95; T.nEx = -2.0; T.nSz = 0.25; T.fSx = -0.75; T.fEx = -2.2; T.fSz = 0.15; T.nHx = -0.42; T.nKx = 0.45; T.fHx = 0.32; T.fKx = 0.42; T.lean = 0.12 + bob * 0.5; T.headX = -0.05; T.twist = 0.25; T.spin = 0; };
    const crouch = () => { T.nHx = -1.25; T.nKx = 2.0; T.fHx = -0.55; T.fKx = 1.9; T.lean = 0.45; T.headX = -0.35; };
    const block = () => { T.nSx = -1.45; T.nEx = -2.3; T.nSz = -0.25; T.fSx = -1.3; T.fEx = -2.4; T.fSz = -0.15; T.lean = -0.05; T.headX = 0.25; T.twist = 0.1; };
    const ph = (lo, hi, fr) => clamp((fr - lo) / Math.max(1, hi - lo), 0, 1);
    switch (f.state) {
      case 'idle': case 'intro': guard(); if (f.holdingBack && f.state === 'idle') block(); T.lift = bob * 0.4; break;
      case 'walk': {
        guard(); const w = f.walkCycle * 1.6;
        T.nHx = -0.2 + Math.sin(w) * 0.55; T.nKx = 0.35 + Math.max(0, -Math.cos(w)) * 0.8;
        T.fHx = -0.2 - Math.sin(w) * 0.55; T.fKx = 0.35 + Math.max(0, Math.cos(w)) * 0.8; T.lift = Math.abs(Math.sin(w)) * 0.03;
        if (f.holdingBack) block();
        break;
      }
      case 'crouch': guard(); crouch(); if (f.holdingBack) { block(); T.lean = 0.35; } break;
      case 'blockstun': guard(); if (f.crouching) crouch(); block(); T.lean -= 0.1; break;
      case 'jump': {
        guard(); const up = f.vy < 0;
        T.nHx = -1.2; T.nKx = 1.9; T.fHx = -0.4; T.fKx = 1.6; T.nSx = -2.2; T.nEx = -0.6; T.fSx = -0.9; T.fEx = -1.4; T.lean = up ? 0.1 : 0.3;
        if (Math.abs(f.vx) > 1) T.pitch = Math.sign(f.vx * f.facing) * clamp(f.t / 30, 0, 1) * Math.PI * 2 * (f.t < 30 ? 1 : 0);
        break;
      }
      case 'hitstun': guard(); T.lean = -0.45; T.headX = 0.5; T.nSz = 0.9; T.fSz = 0.7; T.nEx = -0.6; T.fEx = -0.5; T.nSx = 0.3; T.fSx = 0.2; T.mouth = 1; if (f.crouching) crouch(); break;
      case 'dizzy': guard(); T.lean = -0.1 + Math.sin(time * 5) * 0.15; T.side = Math.sin(time * 3.3) * 0.2; T.headZ = Math.sin(time * 6) * 0.3; T.nSx = 0; T.fSx = 0; T.nSz = 0.5; T.fSz = 0.5; T.nEx = -0.3; T.fEx = -0.3; T.mouth = 0.6; break;
      case 'launched': T.pitch = -0.9 - clamp(f.t / 40, 0, 1) * 0.6; T.nSx = -2.6; T.fSx = -2.2; T.nSz = 0.8; T.fSz = 0.8; T.nHx = -0.8; T.fHx = -0.3; T.nKx = 0.6; T.fKx = 0.9; T.headX = 0.6; T.mouth = 1; break;
      case 'knockdown': case 'ko': T.pitch = -1.5; T.nSx = -2.8; T.fSx = -2.5; T.nSz = 0.9; T.fSz = 1.1; T.nHx = -0.2; T.fHx = 0.1; T.nKx = 0.5; T.fKx = 0.2; T.headX = 0.2; T.mouth = 1; break;
      case 'getup': { const k = 1 - clamp(f.t / 16, 0, 1); T.pitch = -1.5 * k; guard(); T.nHx = lerp(T.nHx, -1.3, k); T.nKx = lerp(T.nKx, 2.0, k); T.lean = lerp(T.lean, 0.6, k); break; }
      case 'grabbed': T.lift = 0; T.lean = -0.4; T.nSx = -2.5; T.fSx = -2.3; T.nSz = 0.9; T.fSz = 0.9; T.nHx = -0.6; T.nKx = 1.2; T.fHx = 0.3; T.fKx = 1.0; T.headX = 0.4; T.mouth = 1; T.side = Math.sin(time * 18) * 0.15; break;
      case 'throw': {
        const k = clamp(f.throwT / 30, 0, 1);
        T.nSx = lerp(-1.4, -3.0, k); T.fSx = lerp(-1.3, -2.9, k); T.nEx = -0.3; T.fEx = -0.3; T.lean = lerp(0.1, -0.5, k); T.nHx = -0.5; T.nKx = 0.5; T.fHx = 0.4; T.fKx = 0.3; T.twist = lerp(0, -0.8, k); T.mouth = 0.5;
        break;
      }
      case 'taunt': {
        guard(); const k = Math.sin(time * 12);
        T.nSx = -1.6; T.nEx = -0.2 + k * 0.4; T.nSz = 0.2; T.fSx = 0.2; T.fEx = -1.6; T.fSz = 0.5; T.lean = -0.2 + k * 0.05; T.headX = -0.2 + k * 0.1; T.mouth = 0.8 + k * 0.2;
        break;
      }
      case 'victory': {
        const k = Math.sin(time * 6);
        T.nSx = -3.0 + k * 0.15; T.nEx = -0.3; T.nSz = 0.2; T.fSx = -0.4; T.fEx = -1.9; T.fSz = 0.6; T.lift = Math.max(0, k) * 0.12; T.headX = -0.3; T.mouth = 1; T.twist = 0.6; T.nHx = -0.1; T.fHx = 0.15;
        break;
      }
      case 'super': {
        const k = clamp(f.superT / SUPER.freeze, 0, 1);
        if (f.superT < SUPER.freeze) { T.nSx = 0.6; T.fSx = 0.5; T.nSz = 1.1 * k; T.fSz = 1.0 * k; T.nEx = -0.5; T.fEx = -0.5; T.headX = -0.4 * k; T.lean = -0.25 * k; T.nHx = -0.5; T.nKx = 0.6; T.fHx = 0.5; T.fKx = 0.5; T.mouth = k; T.lift = 0.05 * k; }
        else { T.nSx = -1.6; T.fSx = -1.5; T.nEx = 0; T.fEx = -0.1; T.nSz = -0.1; T.lean = 0.3; T.nHx = -0.6; T.nKx = 0.5; T.fHx = 0.6; T.fKx = 0.2; T.mouth = 1; T.twist = 0.4; }
        break;
      }
      case 'badla': {
        const rapid = f.badlaHits ? (Math.floor(f.superT / 3) % 2) : -1;
        T.lean = 0.55; T.fHx = 0.8; T.nHx = -0.9; T.nKx = 0.8; T.fKx = 0.6; T.mouth = 1;
        if (rapid < 0) { T.nSx = 1.2; T.fSx = 1.1; T.nEx = -0.2; T.fEx = -0.2; }
        else { T.nSx = rapid ? -1.6 : -0.8; T.nEx = rapid ? 0 : -2; T.fSx = rapid ? -0.8 : -1.6; T.fEx = rapid ? -2 : 0; T.twist = rapid ? 0.4 : -0.4; }
        break;
      }
      case 'attack': case 'airattack': {
        if (!m) { guard(); break; }
        guard();
        const fr = a.frame, s = m.s, act = m.s + m.a, end = s + m.a + m.r;
        const wind = ph(0, s, fr), strike = fr < s ? 0 : fr < act ? 1 : 1 - ph(act, end, fr);
        const P = (base, target) => lerp(base, target, ease(strike));
        switch (m.id) {
          case 'jab': case 'rush': T.nSx = P(-0.9 - wind * 0.3, -1.6); T.nEx = P(-2.0, -0.05); T.nSz = P(0.25, -0.15); T.twist = P(0.25, -0.35); T.lean = P(0.12, m.id === 'rush' ? 0.5 : 0.25); if (m.id === 'rush') { T.fHx = 0.6; T.nHx = -0.7; } break;
          case 'jab2': T.fSx = P(-0.75, -1.62); T.fEx = P(-2.2, -0.05); T.fSz = P(0.15, -0.35); T.twist = P(0.25, 0.65); T.lean = P(0.12, 0.3); break;
          case 'upper': T.nSx = P(-0.2, -2.9); T.nEx = P(-1.9, -0.7); T.lean = P(0.4, -0.25); T.lift = P(-0.05, 0.1); T.nHx = P(-0.9, -0.2); T.nKx = P(1.1, 0.2); T.twist = P(0.4, -0.2); break;
          case 'spin': T.spin = fr < s ? -0.5 * wind : fr < act ? Math.PI * 2 * ph(s, act, fr) : 0; T.fSx = -1.5; T.fEx = -0.1; T.fSz = 0.9 * strike; T.lean = 0.15; break;
          case 'kick': T.nHx = P(-1.0 - wind * 0.4, -1.55); T.nKx = P(1.7, 0.05); T.lean = P(0.1, -0.3); T.fKx = 0.15; T.fHx = 0.1; break;
          case 'round': T.fHx = P(0.2, -1.45); T.fHz = P(0, 0.9 * (f.facing === 1 ? 1 : -1)); T.fKx = P(1.4, 0.1); T.twist = P(0.3, -1.1); T.lean = P(0.1, -0.45); T.nHx = 0; T.nKx = 0.1; break;
          case 'lowp': crouch(); T.nSx = P(-1.0, -1.25); T.nEx = P(-2.0, 0); T.twist = P(0.2, -0.3); break;
          case 'sweep': crouch(); T.lean = 0.55; T.nHx = P(-1.25, -1.4); T.nKx = P(2.0, 0.05); T.nHz = P(0, 0.4); T.fHx = -0.9; T.fKx = 2.4; T.spin = strike * 0.7; T.nSx = 0.4; T.fSx = -0.6; T.fEx = -1; break;
          case 'fly': T.lift = P(0, 0.42); T.nHx = P(-1.0, -1.5); T.nKx = P(1.6, 0); T.fHx = P(0.2, 0.5); T.fKx = P(0.5, 1.9); T.lean = P(0.1, -0.45); T.nSx = -0.4; T.fSx = 0.6; break;
          case 'beep': T.nSx = P(-0.6, -1.5); T.fSx = P(-0.5, -1.5); T.nEx = P(-1.8, -0.1); T.fEx = P(-1.8, -0.1); T.lean = P(0, 0.3); T.mouth = 1; break;
          case 'emote': case 'roast': T.nSx = P(-0.5, -2.6); T.nEx = -0.6; T.fSx = P(-0.5, -0.8); T.fEx = -1.8; T.lean = -0.2; T.mouth = 1; T.headX = -0.25; break;
          case 'grab': T.nSx = P(-1.0, -1.45); T.fSx = P(-0.9, -1.4); T.nEx = P(-1.8, -0.35); T.fEx = P(-1.8, -0.35); T.nSz = P(0.3, -0.3); T.fSz = P(0.2, -0.3); T.lean = P(0.1, 0.3); break;
          case 'airp': T.nHx = -1.0; T.nKx = 1.7; T.fHx = -0.2; T.fKx = 1.4; T.nSx = P(-1.0, -1.1); T.nEx = P(-2, 0); T.lean = 0.45; break;
          case 'airk': T.nHx = P(-1.0, -1.2); T.nKx = P(1.8, 0); T.fHx = 0.2; T.fKx = 1.8; T.lean = -0.1; T.nSx = -0.4; T.fSx = 0.4; break;
          default: break;
        }
        if (m.special) T.mouth = Math.max(T.mouth, 0.7);
        break;
      }
      default: guard();
    }
    return T;
  }

  // Apply sim state to the 3D model. dt in seconds of real time.
  update(f, game, dt, time) {
    const T = this.computeTarget(f, game, time);
    const snap = (f.state === 'attack' || f.state === 'airattack') && f.attackPhase === 'active';
    const k = snap ? 1 : 1 - Math.exp(-dt * (f.state === 'attack' || f.state === 'airattack' || f.state === 'badla' ? 30 : 14));
    const p = this.pose;
    for (const j of JOINTS) p[j] = j === 'spin' && Math.abs(T.spin - p.spin) > 3 ? T.spin : p[j] + (T[j] - p[j]) * k;
    const { nA, fA, nL, fL } = this.limbs(f.facing);
    const sgnN = nA === this.armL ? 1 : -1;     // shoulder z sign so + is "outward" for both
    nA.sh.rotation.set(p.nSx, 0, p.nSz * sgnN); nA.el.rotation.set(p.nEx, 0, 0);
    fA.sh.rotation.set(p.fSx, 0, -p.fSz * sgnN); fA.el.rotation.set(p.fEx, 0, 0);
    nL.hip.rotation.set(p.nHx, 0, p.nHz * sgnN * 0.6); nL.knee.rotation.set(p.nKx, 0, 0);
    fL.hip.rotation.set(p.fHx, 0, -p.fHz * sgnN * 0.6); fL.knee.rotation.set(p.fKx, 0, 0);
    this.spine.rotation.set(p.lean, p.twist * f.facing * -0.6, p.side);
    this.head.rotation.set(p.headX, 0, p.headZ);
    this.mouth.scale.set(1, 1 + p.mouth * 3.5, 1);
    // planting: lowest foot on the floor when grounded
    const lying = f.state === 'knockdown' || f.state === 'ko' || f.state === 'launched';
    const drop = (hx, kx) => L1 * Math.cos(hx) + L2 * Math.cos(hx + kx) + 0.06;
    const legDrop = Math.max(drop(p.nHx, p.nKx), drop(p.fHx, p.fKx));
    const ground = H - legDrop;
    let y = -ground + p.lift;
    if (lying || f.state === 'getup') y = lerp(y, -H + 0.16, clamp(-p.pitch / 1.5, 0, 1));
    this.pitch.position.y = H + y;
    this.pitch.rotation.x = p.pitch;
    this.body.rotation.y = p.spin;
    // facing: profile, turned a little toward the camera
    const yaw = f.facing === 1 ? Math.PI / 2 - 0.45 : -Math.PI / 2 + 0.45;
    this.root.rotation.y += (yaw - this.root.rotation.y) * (1 - Math.exp(-dt * 18));
    // eyes / expression
    const ko = f.state === 'ko' || (f.state === 'knockdown' && f.hp <= 0);
    for (const e of this.eyes) { e.w.visible = !ko; e.pupil.visible = !ko; e.x[0].visible = e.x[1].visible = ko; e.w.scale.y = f.state === 'hitstun' ? 0.4 : 1.15; }
    this.stars.visible = f.state === 'dizzy'; if (this.stars.visible) this.stars.rotation.y = time * 6;
    // hit flash + aura
    const flash = f.flash > 0 ? f.flash / 6 : 0;
    for (const mm of this.mats) mm.emissive.setRGB(flash, flash, flash);
    if (this.rgbMats) { const c = new THREE.Color().setHSL((time * 0.3) % 1, 1, 0.5); for (const mm of this.rgbMats) mm.emissive.copy(c).multiplyScalar(0.6 + flash); }
    const auraOn = f.state === 'super' || f.state === 'badla' ? 0.85 : f.meter >= 100 ? 0.35 + Math.sin(time * 8) * 0.15 : this.char.id === 'anish' ? 0.18 : 0;
    this.aura.material.opacity += (auraOn - this.aura.material.opacity) * Math.min(1, dt * 10);
    this.aura.visible = this.aura.material.opacity > 0.01;
    this.aura.scale.set(2.2 + Math.sin(time * 9) * 0.1, 2.6 + Math.sin(time * 7) * 0.1, 1);
  }

  // world positions of the striking points (for trails)
  tips(f) {
    const { nA, fA, nL, fL } = this.limbs(f.facing);
    const v = (o, y) => o.localToWorld(new THREE.Vector3(0, y, 0));
    return { hn: v(nA.el, -A2), hf: v(fA.el, -A2), fn: v(nL.knee, -L2 - 0.04), ff: v(fL.knee, -L2 - 0.04) };
  }

  dispose() { this.root.traverse((o) => { if (o.material && o.material !== OUTLINE && o.material.dispose) o.material.dispose(); }); }
}
