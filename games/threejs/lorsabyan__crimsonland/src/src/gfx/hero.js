// The player is three animated layers: legs face the move direction, the torso faces the aim,
// and each weapon class has its own arms-and-gun layer so the hands actually hold the grip.
import { Rig } from './rig.js';
import { CrowdLayer } from './crowd.js';

const PI = Math.PI;
const SKIN = '#c49a7c', CLOTH = '#4d5340', CLOTH2 = '#383c2d', VEST = '#6c6850', VEST2 = '#4a4838', STRAP = '#2c2a22', METAL = '#2a2d30';

function legs() {
  const r = new Rig();
  r.both((s) => {
    const left = s < 0, hip = [s * 0.14, 0.86, 0], knee = [s * 0.17, 0.48, 0.05];
    const leg = { pivot: hip, joint: knee, limb: [left ? PI : 0, 0.82, 0, 0.02], flex: [1.5, 0.15], pose: [0, left ? -0.5 : 0.1, 0, left ? 1 : 0.3], flop: s * 0.16 };
    r.limb([hip, knee, [s * 0.16, 0.13, -0.03]], [0.125, 0.095, 0.07], { ...leg, color: CLOTH, color2: CLOTH2, rough: 0.85, flexAt: 0.5, sides: 7, steps: 8 });
    r.blob([s * 0.17, 0.5, 0.1], [0.085, 0.075, 0.05], { ...leg, flexW: 0.5, color: '#2a2a24', rough: 0.5, rings: 4, segs: 6 });
    r.blob([s * 0.19, 0.72, 0.03], [0.05, 0.09, 0.08], { ...leg, color: STRAP, rough: 0.7, rings: 4, segs: 5 });
    r.limb([[s * 0.16, 0.14, -0.09], [s * 0.16, 0.09, 0.08], [s * 0.16, 0.06, 0.22]], [0.085, 0.085, 0.055], { ...leg, flexW: 1, color: '#17140f', rough: 0.5, sides: 6, steps: 4 });
  });
  r.blob([0, 0.9, 0], [0.23, 0.14, 0.17], { color: CLOTH2, rough: 0.8 });
  r.limb([[-0.22, 0.98, 0.02], [0, 1, 0.17], [0.22, 0.98, 0.02]], [0.03, 0.035, 0.03], { color: STRAP, sides: 4, steps: 6 });
  return r.build();
}

function torso() {
  const r = new Rig();
  r.limb([[0, 0.9, -0.01], [0, 1.14, 0.01], [0, 1.42, 0.03]], [0.2, 0.27, 0.25], { color: VEST2, color2: VEST, rough: 0.7, sides: 9, steps: 7 });
  for (let i = 0; i < 3; i++) r.blob([-0.14 + i * 0.14, 1.04, 0.22], [0.06, 0.08, 0.04], { color: '#3c3a2c', rough: 0.8, rings: 4, segs: 6 });
  r.blob([0, 1.28, 0.21], [0.17, 0.1, 0.05], { color: '#3f3d2e', rough: 0.75, rings: 4, segs: 7 });
  r.blob([0, 1.2, -0.3], [0.21, 0.27, 0.14], { color: '#3a392c', color2: '#2a2a20', rough: 0.8, segs: 9 });
  r.limb([[-0.17, 1.44, -0.26], [0, 1.47, -0.3], [0.17, 1.44, -0.26]], [0.075, 0.08, 0.075], { color: '#50503c', rough: 0.8, sides: 6, steps: 6 });
  r.blob([0, 1.3, -0.44], [0.05, 0.05, 0.03], { color: '#ffc46a', glow: 1, rings: 3, segs: 5 });
  r.limb([[0.14, 1.42, -0.38], [0.17, 1.92, -0.46]], [0.012, 0.006], { color: METAL, sides: 3, steps: 2 });
  r.both((s) => r.limb([[s * 0.16, 1.5, 0.1], [s * 0.1, 1.2, 0.26], [s * 0.05, 1.0, 0.22]], [0.02, 0.02, 0.02], { color: STRAP, sides: 4, steps: 6 }));
  r.limb([[0, 1.46, 0.02], [0, 1.56, 0.04]], [0.085, 0.08], { color: SKIN, sides: 6, steps: 2 });
  const head = { pivot: [0, 1.52, 0.03], limb: [0, 0.03, 0, 0], pose: [0.1, -0.35, 0, 0] };
  r.blob([0, 1.62, 0.04], [0.13, 0.135, 0.145], { ...head, color: SKIN, rings: 6, segs: 8 });
  r.blob([0, 1.69, 0.01], [0.175, 0.125, 0.195], { ...head, color: '#465040', color2: '#262c22', rough: 0.45 });
  r.limb([[-0.17, 1.66, 0.14], [0, 1.65, 0.22], [0.17, 1.66, 0.14]], [0.02, 0.03, 0.02], { ...head, color: '#262c22', sides: 4, steps: 6 });
  r.blob([0, 1.62, 0.17], [0.115, 0.035, 0.03], { ...head, color: '#66e0ff', glow: 1, rings: 3, segs: 6 });
  return r.build();
}

// Where each weapon class keeps its hands. The gun sits on the right shoulder line (GUN_X), the
// way a rifle is carried, so from above the arms and gun make a tight triangle, not a ring.
export const GUN_X = 0.15;
const GRIP = {
  pistol: { y: 1.24, right: [GUN_X, 1.2, 0.56], left: [GUN_X - 0.06, 1.17, 0.52], rEl: [0.34, 1.14, 0.28], lEl: [-0.16, 1.12, 0.32] },
  rifle: { y: 1.24, right: [GUN_X, 1.2, 0.3], left: [GUN_X - 0.02, 1.17, 0.66], rEl: [0.42, 1.1, 0.1], lEl: [-0.12, 1.1, 0.38] },
  shotgun: { y: 1.24, right: [GUN_X, 1.2, 0.3], left: [GUN_X - 0.02, 1.16, 0.74], rEl: [0.42, 1.1, 0.1], lEl: [-0.1, 1.1, 0.42] },
  heavy: { y: 1.08, right: [GUN_X, 1.02, 0.3], left: [GUN_X - 0.12, 1.04, 0.62], rEl: [0.44, 1.04, 0.08], lEl: [-0.14, 1.02, 0.36] },
  energy: { y: 1.24, right: [GUN_X, 1.2, 0.3], left: [GUN_X - 0.02, 1.17, 0.62], rEl: [0.42, 1.1, 0.1], lEl: [-0.12, 1.1, 0.36] },
  launcher: { y: 1.56, right: [GUN_X + 0.08, 1.34, 0.36], left: [GUN_X - 0.14, 1.38, 0.66], rEl: [0.5, 1.2, 0.14], lEl: [-0.16, 1.2, 0.38] },
};

export const GUN_MUZZLE = { pistol: 0.92, rifle: 1.22, shotgun: 1.16, heavy: 1.3, energy: 1.12, launcher: 1.2 };
const CLASSES = Object.keys(GRIP);

function gunBits(r, y, parts, part) {
  for (const [z0, z1, w, col, opts] of parts) {
    r.limb([[GUN_X, y, z0], [GUN_X, y, z1]], [w, w], { ...part, color: col, sides: 6, steps: 2, rough: 0.34, mottle: 0.12, ...opts });
  }
}

function armsAndGun(cls) {
  const r = new Rig(), g = GRIP[cls], k = '#16171a', m = '#3a3d42', w = '#5c3d24';
  const rShoulder = [0.3, 1.4, 0.04], lShoulder = [-0.3, 1.4, 0.04];
  // Reload: the gun tips up on the right shoulder while the left hand drops to the belt.
  const hold = { pivot: rShoulder, pose: [-0.5, 1.2, 0, 0], flop: 0.9 };
  const arm = (sh, elbow, hand, pose, flop) => {
    const part = { pivot: sh, joint: elbow, pose, flop, flexAt: 0.5 };
    r.limb([sh, elbow, hand], [0.1, 0.082, 0.06], { ...part, color: '#5a5844', color2: '#4a4838', rough: 0.75, sides: 6, steps: 8 });
    r.blob(hand, [0.068, 0.068, 0.08], { ...part, flexW: 1, flexAt: undefined, color: '#2c2a22', rough: 0.7, rings: 4, segs: 6 });
  };
  r.both((s) => r.blob([s * 0.3, 1.44, 0.03], [0.14, 0.09, 0.15], { color: '#7c7662', color2: '#57533f', rough: 0.55, rings: 5, segs: 7 }));
  arm(rShoulder, g.rEl, g.right, [-0.5, 1.2, 0, 0], 0.9);
  arm(lShoulder, g.lEl, g.left, [0.95, 1.2, 0, -0.5], -1.1);
  const y = g.y;
  if (cls === 'pistol') gunBits(r, y, [[0.48, 0.86, 0.044, k]], hold);
  if (cls === 'rifle') gunBits(r, y, [[0.02, 0.36, 0.055, w], [0.36, 0.8, 0.06, k], [0.8, 1.18, 0.024, m], [0.5, 0.58, 0.1, m]], hold);
  if (cls === 'shotgun') gunBits(r, y, [[0.04, 0.36, 0.06, w], [0.36, 0.7, 0.058, k], [0.7, 1.12, 0.036, m], [0.7, 0.9, 0.05, w]], hold);
  if (cls === 'heavy') {
    gunBits(r, y, [[0.16, 0.74, 0.1, k], [0.24, 0.44, 0.14, m], [0.74, 1.26, 0.075, m], [0.7, 0.82, 0.095, k]], hold);
    r.blob([GUN_X + 0.16, 0.94, 0.42], [0.09, 0.13, 0.17], { ...hold, color: '#4a4f3a', rough: 0.5 });
  }
  if (cls === 'energy') {
    gunBits(r, y, [[0.04, 0.44, 0.06, k], [0.44, 0.92, 0.075, m], [0.92, 1.08, 0.055, '#66e0ff', { glow: 1 }]], hold);
    r.blob([GUN_X, y + 0.07, 0.6], [0.05, 0.05, 0.16], { ...hold, color: '#66e0ff', glow: 1, rings: 4, segs: 6 });
  }
  if (cls === 'launcher') {
    gunBits(r, y, [[-0.2, 1.1, 0.14, '#3f4a38'], [1.1, 1.18, 0.17, k], [-0.3, -0.2, 0.17, k]], hold);
    gunBits(r, 1.32, [[0.26, 0.46, 0.05, k]], hold);
  }
  return r.build();
}

export class HeroView {
  constructor(stage) {
    const base = { hip: 0.9, fallX: 1.5, rest: 0.26, squash: 0.92, height: 0, rim: '#ffe7c8' };
    this.legs = new CrowdLayer(stage, null, legs(), 1, { ...base, bob: 0.05, glow: '#ffc46a', glowPower: 2.5 });
    const upper = { ...base, lean: 0.2, flinch: 0.4, bob: 0.05 };
    this.torso = new CrowdLayer(stage, null, torso(), 1, { ...upper, glow: '#7fe0ff', glowPower: 4 });
    this.guns = {};
    for (const c of CLASSES) this.guns[c] = new CrowdLayer(stage, null, armsAndGun(c), 1, { ...upper, glow: '#66e0ff', glowPower: 5 });
  }

  update(p) {
    const dead = p.deadT > 0 ? Math.min(1, p.deadT * 2) : 0, fl = p.flash;
    const wounds = 1 - p.hp / p.maxHp, flinch = p.kick * 1.4 + p.hurtPulse * 0.6;
    const reload = p.reloading ? Math.sin(Math.PI * (1 - p.reloadT / p.reloadLen)) : 0;
    const y = -0.02;
    const yawL = dead ? p.aimYaw : p.legYaw;
    this.legs.begin();
    this.legs.push(p.x, y, p.z, yawL, p.phase, 1, p.moveAmt, dead, 1, 1, 1, fl, 0, 0, 0, 1, 0, 0, wounds);
    this.legs.end();
    this.torso.begin();
    this.torso.push(p.x, y, p.z, p.aimYaw, p.phase, 1, p.moveAmt, dead, 1, 1, 1, fl, 0, 0, 0, 1, 0, flinch, wounds);
    this.torso.end();
    for (const c of CLASSES) {
      const L = this.guns[c];
      L.begin();
      if (c === p.weapon.cls) {
        L.push(p.x - p.aimX * p.kick, y, p.z - p.aimZ * p.kick, p.aimYaw, p.phase, 1, p.moveAmt, dead, 1, 1, 1, 0, 0, 0, 0, 1, reload, flinch, wounds);
      }
      L.end();
    }
  }
}
