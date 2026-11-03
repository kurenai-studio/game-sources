// Original creature designs, built from primitives. Forward is +Z, feet on y = 0.
// Conventions for the rig: limb phase 0 means a part is fully back at wave = PI/2 and passes
// forward at wave = PI. Negative pitch swings a hanging limb forwards. See rig.js for the fields.
import { Rig } from './rig.js';

const PI = Math.PI;

function spiderLegs(r, pairs, z0, z1, y, reach, thick, o) {
  r.both((s) => {
    for (let i = 0; i < pairs; i++) {
      const t = pairs > 1 ? i / (pairs - 1) : 0.5;
      const z = z0 + (z1 - z0) * t, splay = (t - 0.5) * reach * 1.25;
      const root = [s * thick * 1.2, y, z], knee = [s * reach * 0.55, y + reach * 0.42, z + splay * 0.55];
      const part = {
        pivot: root, joint: knee, axis: 1,
        limb: [(i % 2 ? PI : 0) + (s > 0 ? 0 : PI), 0, s * (o.sweep ?? 0.36), 0],
        flex: [s * (o.flex ?? 0.5), 0],
        pose: [o.strike && i === 0 ? s * 0.5 : 0, s * (o.deadHip ?? -0.5), 0, s * (o.deadCurl ?? -1.5)],
        color: o.color, color2: o.color2, rough: o.rough ?? 0.4,
      };
      r.limb([root, knee, [s * reach * 0.86, y * 0.4 + 0.08, z + splay * 0.85], [s * reach, 0.03, z + splay]], [thick, thick * 0.72, thick * 0.42, thick * 0.12], { ...part, sides: 5, steps: 8, flexAt: 0.42 });
    }
  });
}

function shambler() {
  const r = new Rig();
  const skin = '#b3a996', skin2 = '#8c8675', shirt = '#857d6e', shirt2 = '#5f594e', pants = '#3d3a36', hipY = 0.94, shY = 1.42, neck = [0, 1.5, 0.05];
  r.both((s) => {
    const left = s < 0, hip = [s * 0.14, hipY, 0], knee = [s * 0.17, 0.52, 0.05], ankle = [s * 0.16, 0.1, -0.02];
    // The left leg drags: shorter stride and less knee, which gives the walk its limp.
    const leg = { pivot: hip, joint: knee, limb: [left ? PI : 0, left ? 0.34 : 0.56, 0, 0], flex: [left ? 0.55 : 1.15, 0.25], pose: [0, left ? -0.32 : 0.12, 0, left ? 0.75 : 0.3], flop: s * 0.16 };
    r.limb([hip, knee, ankle], [0.14, 0.105, 0.075], { ...leg, color: pants, color2: '#282623', cloth: 1, flexAt: 0.5, rough: 0.9, sides: 7, steps: 8 });
    r.limb([[s * 0.16, 0.12, -0.08], [s * 0.16, 0.08, 0.08], [s * 0.16, 0.05, 0.22]], [0.085, 0.085, 0.055], { ...leg, flexW: 1, color: '#17140f', rough: 0.55, sides: 6, steps: 4 });

    const sh = [s * 0.33, shY, 0.03], elbow = [s * 0.4, 1.12, 0.06], wrist = [s * 0.38, 0.84, 0.12];
    // Hangs at the side. `reach` (per instance) lifts it into the classic zombie grab.
    const arm = { pivot: sh, joint: elbow, limb: [left ? 0.3 : PI + 0.3, 0.22, 0.05, 0], flex: [-0.3, 0.7], pose: [-0.9, 0, -1.42, -0.35], flop: s * (left ? 1.15 : 0.5), flexAt: 0.5 };
    r.limb([sh, elbow, wrist], [0.115, 0.09, 0.07], { ...arm, color: shirt2, color2: skin, cloth: 0, sides: 7, steps: 8, missing: left ? 0 : 1 });
    r.blob([s * 0.38, 0.78, 0.14], [0.08, 0.095, 0.09], { ...arm, flexW: 1, flexAt: undefined, color: skin2, rings: 5, segs: 6, missing: left ? 0 : 1 });
    for (let f = 0; f < 3; f++) r.limb([[s * (0.33 + f * 0.05), 0.74, 0.19], [s * (0.33 + f * 0.05), 0.66, 0.27]], [0.024, 0.012], { ...arm, flexW: 1, flexAt: undefined, color: '#4e3a30', sides: 4, steps: 2, missing: left ? 0 : 1 });
  });
  r.blob([0, hipY, 0], [0.25, 0.17, 0.18], { color: pants, cloth: 1, rough: 0.9, segs: 8, rings: 5 });
  r.limb([[0, hipY - 0.03, 0], [0, 1.2, 0.03], [0, shY, 0.04]], [0.21, 0.255, 0.24], { color: shirt, color2: shirt2, cloth: 1, rough: 0.85, sides: 9, steps: 7, mottle: 0.5 });
  // One wide yoke across the shoulders, so the arms grow out of the torso instead of off a ball.
  r.blob([0, shY + 0.02, 0.03], [0.42, 0.13, 0.2], { color: shirt, color2: shirt2, cloth: 1, rough: 0.85, rings: 6, segs: 10 });
  // Torn shirt tails that swing with the body.
  for (let i = 0; i < 5; i++) {
    const a = PI * 0.15 + i * PI * 0.3, x = Math.cos(a) * 0.23, z = -Math.sin(a) * 0.18, w = [x, hipY + 0.06, z];
    r.limb([w, [x * 1.15, hipY - 0.1, z * 1.15], [x * 1.2, hipY - 0.24 - (i % 2) * 0.1, z * 1.2]], [0.07, 0.055, 0.015], { pivot: w, limb: [i * 1.3, 0.3, 0.1, 0], color: shirt2, cloth: 1, rough: 0.9, sides: 4, steps: 4 });
  }
  // An old wound: ribs showing through the shirt, which is what you see when one lies on its back.
  r.blob([0.08, 1.22, 0.24], [0.13, 0.15, 0.05], { color: '#3c0d0a', rough: 0.3, rings: 4, segs: 7 });
  for (let i = 0; i < 3; i++) r.limb([[-0.03, 1.31 - i * 0.08, 0.26], [0.07, 1.31 - i * 0.08, 0.29], [0.17, 1.29 - i * 0.08, 0.24]], [0.014, 0.018, 0.012], { color: '#cfc5ad', sides: 4, steps: 4, rough: 0.5 });
  const head = { pivot: neck, limb: [0.8, 0.09, 0.12, 0], pose: [0.35, -0.3, 0.42, 0] };
  r.limb([[0, 1.44, 0.04], neck, [0, 1.6, 0.09]], [0.1, 0.095, 0.09], { ...head, color: skin2, sides: 6, steps: 3 });
  r.blob([0, 1.69, 0.1], [0.17, 0.19, 0.18], { ...head, color: skin, color2: skin2 });
  r.blob([-0.03, 1.79, 0.03], [0.14, 0.08, 0.14], { ...head, color: '#26211d', rough: 0.9, rings: 5, segs: 8 });
  r.blob([0.1, 1.8, 0.11], [0.05, 0.03, 0.06], { ...head, color: '#431411', rough: 0.35, rings: 3, segs: 5 });
  const jaw = { ...head, pose: [0.75, 0.2, 0.42, 0] };
  r.blob([0, 1.54, 0.2], [0.1, 0.05, 0.09], { ...jaw, color: '#4a2a22', rings: 4, segs: 6 });
  r.both((s) => r.blob([s * 0.075, 1.7, 0.27], 0.022, { ...head, color: '#ff5a26', glow: 0.7, rings: 3, segs: 4 }));
  return r.build();
}

function skitter() {
  const r = new Rig();
  r.blob([0, 0.42, -0.42], [0.42, 0.34, 0.54], { color: '#4a3726', color2: '#140e0a', rough: 0.25, segs: 12, breathe: 0.012 });
  for (let i = 0; i < 4; i++) r.limb([[-0.33 + i * 0.01, 0.56, -0.74 + i * 0.22], [0, 0.76, -0.74 + i * 0.22], [0.33, 0.56, -0.74 + i * 0.22]], [0.025, 0.04, 0.025], { color: '#6e5234', sides: 4, steps: 6, rough: 0.3 });
  r.both((s) => { for (let i = 0; i < 3; i++) r.blob([s * 0.17, 0.72 - i * 0.03, -0.6 + i * 0.26], 0.045, { color: '#ffb12e', glow: 1, rings: 3, segs: 5 }); });
  r.blob([0, 0.36, 0.18], [0.27, 0.22, 0.3], { color: '#5a4630', rough: 0.3 });
  r.both((s) => {
    const fang = { pivot: [s * 0.1, 0.32, 0.42], limb: [s > 0 ? 0 : PI, 0.2, 0, 0], pose: [-0.7, 0.4, 0, 0] };
    r.limb([[s * 0.1, 0.32, 0.42], [s * 0.14, 0.2, 0.6], [s * 0.07, 0.1, 0.72]], [0.055, 0.04, 0.01], { ...fang, color: '#1a1412', sides: 4, rough: 0.2 });
    r.blob([s * 0.09, 0.44, 0.44], 0.04, { color: '#ff3a1e', glow: 1, rings: 3, segs: 4 });
  });
  spiderLegs(r, 4, 0.34, -0.1, 0.36, 1.05, 0.055, { color: '#3a2c1e', color2: '#0f0c0a', flex: 0.55 });
  return r.build();
}

function ripper() {
  const r = new Rig();
  const hide = '#22343f', belly = '#4a7a80', bone = '#cfc6ae';
  r.limb([[0, 0.92, -0.32], [0, 1.0, 0.1], [0, 1.15, 0.52]], [0.24, 0.31, 0.19], { color: hide, color2: '#2e4650', rough: 0.22, sides: 9, steps: 8 });
  r.limb([[0, 0.8, -0.15], [0, 0.82, 0.14], [0, 0.98, 0.5]], [0.14, 0.2, 0.12], { color: belly, rough: 0.35, sides: 7, steps: 6 });
  for (let i = 0; i < 6; i++) {
    const z = -0.4 + i * 0.17;
    r.limb([[0, 1.18 + i * 0.03, z], [0, 1.42 + i * 0.02, z - 0.14]], [0.05, 0.005], { color: '#6fe6d8', glow: 0.9, sides: 4, steps: 2 });
  }
  // The tail whips: a travelling wave that grows towards the tip.
  r.limb([[0, 0.94, -0.3], [0, 0.86, -0.9], [0, 0.72, -1.45], [0, 0.6, -2.0]], [0.17, 0.11, 0.06, 0.012], { color: hide, color2: '#101a20', pivot: [0, 0.9, -0.3], limb: [0.4, 0, 0.5, 0], chain: 2.2, rough: 0.28, sides: 6, steps: 14 });
  const head = { pivot: [0, 1.14, 0.5], limb: [1.2, 0.08, 0.1, 0], pose: [0.45, 0.5, 0, 0] };
  r.limb([[0, 1.14, 0.5], [0, 1.2, 0.86], [0, 1.1, 1.22]], [0.14, 0.15, 0.04], { ...head, color: hide, color2: bone, rough: 0.2, sides: 7, steps: 7 });
  const jaw = { ...head, pivot: [0, 1.04, 0.62], pose: [1.0, 0.9, 0, 0] };
  r.limb([[0, 1.02, 0.6], [0, 0.97, 0.9], [0, 0.93, 1.14]], [0.09, 0.075, 0.02], { ...jaw, color: '#7a2030', sides: 5, steps: 4 });
  r.both((s) => {
    r.blob([s * 0.1, 1.24, 0.92], 0.03, { ...head, color: '#7dfff0', glow: 1, rings: 3, segs: 4 });
    const left = s < 0, hip = [s * 0.2, 0.86, -0.1], knee = [s * 0.3, 0.58, 0.2];
    const leg = { pivot: hip, joint: knee, limb: [left ? PI : 0, 0.66, 0, 0.06], flex: [1, -0.3], pose: [0, left ? -0.7 : 0.4, 0, 0.8] };
    r.limb([hip, knee, [s * 0.24, 0.3, -0.2], [s * 0.22, 0.06, 0.08], [s * 0.22, 0.03, 0.3]], [0.15, 0.1, 0.06, 0.05, 0.03], { ...leg, color: hide, color2: '#0d1418', rough: 0.25, flexAt: 0.28, sides: 6, steps: 14 });
    const sh = [s * 0.26, 1.08, 0.38], el = [s * 0.44, 0.92, 0.62];
    const arm = { pivot: sh, joint: el, limb: [left ? 0 : PI, 0.3, 0.1, 0], flex: [-0.3, 0.4], pose: [-1.1, 0.6, 0, -0.6] };
    r.limb([sh, el, [s * 0.3, 0.62, 0.94], [s * 0.16, 0.56, 1.26]], [0.07, 0.05, 0.04, 0.006], { ...arm, color: hide, color2: bone, rough: 0.2, flexAt: 0.32, sides: 5, steps: 10 });
  });
  return r.build();
}

function brute() {
  const r = new Rig();
  const hide = '#94614c', hide2 = '#54332a', plate = '#a59b85';
  // Built like the shambler: a torso that widens into one yoke, so the arms grow out of the mass.
  r.limb([[0, 0.72, -0.04], [0, 1.2, 0], [0, 1.72, 0.04]], [0.46, 0.64, 0.72], { color: hide2, color2: hide, rough: 0.55, sides: 12, steps: 8, breathe: 0.012, mottle: 0.5 });
  r.blob([0, 1.76, 0.04], [1.02, 0.34, 0.54], { color: hide, color2: hide2, rough: 0.5, rings: 7, segs: 12 });
  r.blob([0, 1.32, 0.56], [0.44, 0.44, 0.16], { color: '#a56a52', rough: 0.45, rings: 6, segs: 9 });
  for (let i = 0; i < 3; i++) r.limb([[-0.3, 1.54 - i * 0.2, 0.68], [0.3, 1.48 - i * 0.2, 0.68]], [0.03, 0.03], { color: '#451512', sides: 4, steps: 3, rough: 0.3 });
  const head = { pivot: [0, 1.82, 0.42], limb: [1, 0.06, 0.1, 0], pose: [0.4, -0.3, 0, 0] };
  r.blob([0, 1.94, 0.56], [0.27, 0.23, 0.28], { ...head, color: hide, color2: hide2, rings: 7, segs: 9 });
  r.blob([0, 1.8, 0.74], [0.17, 0.09, 0.12], { ...head, color: '#3f1a14', pose: [0.8, 0, 0, 0], rings: 4, segs: 6 });
  for (let i = 0; i < 6; i++) {
    const z = -0.56 + i * 0.2, y = 2.12 - Math.abs(i - 2.5) * 0.08;
    r.limb([[0, y, z], [0, y + 0.3 - Math.abs(i - 2.5) * 0.05, z - 0.18]], [0.11, 0.01], { color: plate, sides: 5, steps: 2, rough: 0.45 });
  }
  r.both((s) => {
    const left = s < 0, hip = [s * 0.32, 0.8, 0], knee = [s * 0.4, 0.44, 0.08];
    const leg = { pivot: hip, joint: knee, limb: [left ? PI : 0, 0.42, 0, 0], flex: [0.75, 0.2], pose: [0, left ? -0.3 : 0.15, 0, 0.4], flop: s * 0.2 };
    r.limb([hip, knee, [s * 0.38, 0.05, 0.04]], [0.28, 0.23, 0.18], { ...leg, color: hide2, rough: 0.7, sides: 8, steps: 6, flexAt: 0.5 });
    r.blob([s * 0.38, 0.09, 0.14], [0.2, 0.1, 0.28], { ...leg, flexW: 1, color: '#2a1612', rings: 4, segs: 7 });
    r.limb([[s * 0.72, 2.04, -0.12], [s * 0.86, 2.2, -0.18], [s * 1.02, 2.22, -0.26]], [0.1, 0.06, 0.008], { color: plate, sides: 5, steps: 4, rough: 0.45 });
    const sh = [s * 0.92, 1.72, 0.05], el = [s * 1.14, 1.14, 0.2];
    const arm = { pivot: sh, joint: el, limb: [left ? 0 : PI, 0.34, 0.12, 0], flex: [-0.4, 0.4], pose: [-2.3, 0, 0, -0.5], flop: s * (left ? 1 : 0.45), rough: 0.55 };
    r.limb([sh, el, [s * 1.02, 0.56, 0.5]], [0.33, 0.27, 0.27], { ...arm, color: hide, color2: hide2, sides: 9, steps: 8, flexAt: 0.5 });
    r.blob([s * 1.02, 0.46, 0.56], [0.33, 0.28, 0.34], { ...arm, flexW: 1, color: '#33201a', rough: 0.5 });
    for (let k = 0; k < 3; k++) r.limb([[s * (0.84 + k * 0.17), 0.34, 0.76], [s * (0.84 + k * 0.17), 0.22, 0.98]], [0.06, 0.01], { ...arm, flexW: 1, color: plate, sides: 4, steps: 2 });
    r.blob([s * 0.1, 2, 0.8], 0.03, { ...head, color: '#ffd23a', glow: 1, rings: 3, segs: 4 });
  });
  return r.build();
}

function spitter() {
  const r = new Rig();
  r.blob([0, 0.78, -0.3], [0.62, 0.58, 0.72], { color: '#54762a', color2: '#b6d24a', rough: 0.2, glow: 0.3, breathe: 0.03, segs: 14, rings: 10 });
  r.both((s) => { for (let i = 0; i < 3; i++) r.blob([s * (0.34 + i * 0.05), 1.14 - i * 0.2, -0.56 + i * 0.3], [0.13, 0.12, 0.13], { color: '#e5ff5a', glow: 1, breathe: 0.02, rings: 5, segs: 7, rough: 0.15 }); });
  r.blob([0, 0.6, 0.42], [0.3, 0.28, 0.32], { color: '#3a4a22', rough: 0.4 });
  // The neck rears back to spit.
  const neck = { pivot: [0, 0.66, 0.54], limb: [0.5, 0.1, 0.14, 0], pose: [-0.95, 0.6, 0, 0] };
  r.limb([[0, 0.66, 0.54], [0, 0.78, 0.88], [0, 0.76, 1.1]], [0.17, 0.12, 0.2], { ...neck, color: '#3a4a22', color2: '#99b83e', rough: 0.25, sides: 8, steps: 7 });
  r.blob([0, 0.76, 1.14], [0.1, 0.1, 0.05], { ...neck, color: '#e5ff5a', glow: 1, rings: 4, segs: 6 });
  spiderLegs(r, 3, 0.4, -0.5, 0.4, 0.95, 0.075, { color: '#2c3618', color2: '#11150a', sweep: 0.24, flex: 0.4 });
  return r.build();
}

function burster() {
  const r = new Rig();
  r.blob([0, 0.55, 0], [0.52, 0.46, 0.6], { color: '#3a1a14', color2: '#160908', rough: 0.2, segs: 14, rings: 10, breathe: 0.035 });
  for (let i = 0; i < 4; i++) {
    const a = -0.6 + i * 0.4;
    r.limb([[-0.48, 0.74, a * 0.7], [0, 1.0, a], [0.48, 0.74, a * 0.7]], [0.03, 0.05, 0.03], { color: '#ff5a1e', glow: 1, sides: 5, steps: 10, breathe: 0.03 });
  }
  r.blob([0, 0.9, 0], [0.25, 0.14, 0.34], { color: '#ffb02e', glow: 1, breathe: 0.04, rings: 6, segs: 8 });
  r.blob([0, 0.42, 0.56], [0.2, 0.16, 0.16], { color: '#1a0c0a', rough: 0.3 });
  r.both((s) => r.blob([s * 0.09, 0.47, 0.68], 0.035, { color: '#ffdf5a', glow: 1, rings: 3, segs: 4 }));
  spiderLegs(r, 3, 0.34, -0.34, 0.32, 0.72, 0.05, { color: '#20100c', color2: '#0a0504', sweep: 0.44, flex: 0.5 });
  return r.build();
}

function brood() {
  const r = new Rig();
  r.blob([0, 1.16, -0.92], [1.1, 0.92, 1.24], { color: '#6b5a4a', color2: '#2a1e18', rough: 0.3, segs: 16, rings: 12, breathe: 0.03 });
  for (let i = 0; i < 16; i++) {
    const a = i * 2.4, h = -0.7 + (i / 16) * 1.5;
    const y = 1.16 + h * 0.62, rad = Math.sqrt(Math.max(0.04, 1 - h * h * 0.8));
    r.blob([Math.cos(a) * rad * 0.98, y, -0.92 + Math.sin(a) * rad * 1.08], [0.15, 0.13, 0.15], { color: '#d9f07a', glow: 0.85, breathe: 0.03, rings: 4, segs: 6, rough: 0.2 });
  }
  r.blob([0, 0.82, 0.56], [0.66, 0.5, 0.7], { color: '#3f3226', rough: 0.3, segs: 12 });
  r.both((s) => {
    const fang = { pivot: [s * 0.2, 0.7, 1.1], limb: [s > 0 ? 0 : PI, 0.2, 0, 0], pose: [-0.8, 0.5, 0, 0] };
    r.limb([[s * 0.2, 0.7, 1.1], [s * 0.3, 0.42, 1.42], [s * 0.13, 0.16, 1.62]], [0.12, 0.09, 0.012], { ...fang, color: '#1a1412', sides: 5, rough: 0.2 });
    r.blob([s * 0.2, 1.02, 1.1], 0.09, { color: '#ff3a1e', glow: 1, rings: 4, segs: 6 });
    r.blob([s * 0.42, 0.98, 1.0], 0.06, { color: '#ff3a1e', glow: 1, rings: 3, segs: 5 });
  });
  spiderLegs(r, 4, 1.0, 0.0, 0.8, 2.5, 0.14, { color: '#2a2018', color2: '#0f0c0a', sweep: 0.28, flex: 0.6, deadHip: -0.3, deadCurl: -1.1 });
  return r.build();
}

function nest() {
  const r = new Rig();
  const flesh = '#6a2a30', dark = '#2a1216';
  for (let i = 0; i < 9; i++) {
    const a = i * 2.4, d = i ? 0.75 + (i % 3) * 0.32 : 0;
    r.blob([Math.cos(a) * d, 0.55 - d * 0.13, Math.sin(a) * d], [0.82 - d * 0.14, 0.72 - d * 0.16, 0.82 - d * 0.14], { color: flesh, color2: dark, rough: 0.28, breathe: 0.04, segs: 12 });
  }
  for (let i = 0; i < 9; i++) {
    const a = i * 1.9 + 0.3, d = 0.34 + (i % 4) * 0.24;
    r.blob([Math.cos(a) * d, 1.18 - d * 0.42, Math.sin(a) * d], [0.13, 0.08, 0.13], { color: '#ffd86a', glow: 1, breathe: 0.03, rings: 4, segs: 7 });
  }
  // Tentacles feel about: a slow wave running from root to tip.
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * PI * 2, x = Math.cos(a), z = Math.sin(a), root = [x * 1.25, 0.2, z * 1.25];
    r.limb([root, [x * 1.7, 0.72, z * 1.7], [x * 2.1, 0.9, z * 2.1], [x * 2.4, 0.42, z * 2.4]], [0.13, 0.09, 0.06, 0.01], { color: flesh, color2: dark, pivot: root, limb: [i * 1.1, 0, 0.7, 0], chain: 2.4, sides: 6, steps: 12 });
  }
  return r.build();
}

// Boss: an armoured scorpion-like tyrant, tail held over its back.
function tyrant() {
  const r = new Rig();
  const shell = '#2e2736', shell2 = '#64283c', vent = '#ff4a2e';
  for (let i = 0; i < 4; i++) {
    const z = 0.9 - i * 0.92, w = 1.34 - i * 0.14;
    r.blob([0, 1.14 - i * 0.06, z], [w, 0.62, 0.68], { color: shell2, color2: shell, rough: 0.2, segs: 16, rings: 10 });
    r.limb([[-w * 0.72, 1.56 - i * 0.06, z - 0.2], [0, 1.8 - i * 0.06, z - 0.24], [w * 0.72, 1.56 - i * 0.06, z - 0.2]], [0.03, 0.07, 0.03], { color: vent, glow: 1, sides: 5, steps: 10 });
  }
  const tailRoot = [0, 1.3, -2.4], tail = { pivot: tailRoot, limb: [0.3, 0.08, 0.2, 0], pose: [0.55, 0.9, 0, 0] };
  r.limb([tailRoot, [0, 1.9, -3.1], [0, 3.0, -3.1], [0, 3.8, -2.2], [0, 3.8, -1.2], [0, 3.1, -0.7]], [0.5, 0.42, 0.34, 0.27, 0.2, 0.1], { ...tail, color: shell2, color2: shell, chain: 1.2, rough: 0.22, sides: 8, steps: 20 });
  r.blob([0, 3.0, -0.62], [0.32, 0.36, 0.42], { ...tail, color: '#ff5a2e', glow: 1, breathe: 0.03, rough: 0.2 });
  r.limb([[0, 2.8, -0.44], [0, 2.3, -0.2]], [0.13, 0.008], { ...tail, color: '#e8dcc4', sides: 5 });
  r.blob([0, 0.96, 1.72], [0.92, 0.5, 0.66], { color: shell, rough: 0.2, segs: 14 });
  r.both((s) => {
    const left = s < 0, sh = [s * 1.08, 0.94, 1.5];
    const claw = { pivot: sh, joint: [s * 1.95, 0.9, 3.05], limb: [left ? PI : 0, 0, s * 0.2, 0], pose: [-0.5, 0.3, 0, 0], rough: 0.25 };
    r.limb([sh, [s * 2.1, 0.92, 2.1], [s * 1.95, 0.9, 3.05]], [0.3, 0.26, 0.24], { ...claw, color: shell2, color2: shell, sides: 8 });
    r.blob([s * 1.9, 0.88, 3.45], [0.54, 0.34, 0.68], { ...claw, color: shell2, rough: 0.2 });
    r.limb([[s * 2.2, 0.88, 3.8], [s * 1.98, 0.86, 4.5], [s * 1.6, 0.84, 4.86]], [0.2, 0.13, 0.01], { ...claw, color: '#e8dcc4', sides: 6 });
    r.limb([[s * 1.5, 0.88, 3.8], [s * 1.5, 0.86, 4.32], [s * 1.62, 0.84, 4.68]], [0.16, 0.1, 0.01], { ...claw, color: '#e8dcc4', sides: 6 });
    r.blob([s * 0.34, 1.22, 2.3], 0.11, { color: '#ffe05a', glow: 1, rings: 4, segs: 6 });
    r.blob([s * 0.6, 1.16, 2.16], 0.07, { color: '#ffe05a', glow: 1, rings: 3, segs: 5 });
  });
  spiderLegs(r, 4, 0.9, -1.8, 0.9, 3.5, 0.2, { color: shell, color2: '#0d0a10', sweep: 0.2, flex: 0.6, rough: 0.25, deadHip: -0.3, deadCurl: -1 });
  return r.build();
}

// Body rig per creature. hip: where the upper body bends. fallX: tips backwards onto the back.
// fallZ: rolls over sideways (PI flips a bug onto its back). rest: lifts the body so it lies on
// the ground instead of through it. fallRate: 1/seconds to hit the ground.
export const CREATURES = {
  shambler: { build: shambler, cap: 280, hip: 0.95, lean: 0.14, lunge: 0.42, flinch: 0.55, bob: 0.05, sway: 0.09, fallX: 1.5, bodyLen: 0.8, rest: 0.27, squash: 0.92, height: 0.7, fallRate: 2, rim: '#d0c8b4', glow: '#ff4a22' },
  skitter: { build: skitter, cap: 260, hip: 0.3, lean: 0.03, lunge: 0.3, flinch: 0.4, bob: 0.02, sway: 0.02, fallZ: Math.PI, hop: 0.9, rest: 0.72, squash: 1, height: 1, fallRate: 2.6, rim: '#a89878', glow: '#ff8a1e' },
  ripper: { build: ripper, cap: 160, hip: 0.85, lean: 0.08, lunge: 0.35, flinch: 0.5, bob: 0.08, sway: 0.05, fallZ: Math.PI / 2, hop: 0.25, rest: 0.34, squash: 1, height: 0.9, fallRate: 2.6, rim: '#7fe8e0', glow: '#55ffe6' },
  brute: { build: brute, cap: 50, grain: 3.4, hip: 0.9, lean: 0.1, lunge: 0.32, flinch: 0.16, bob: 0.08, sway: 0.1, fallX: 1.5, bodyLen: 1, rest: 0.68, squash: 0.9, height: 1.3, fallRate: 1.5, heavy: true, rim: '#ffb890', glow: '#ffc42e' },
  spitter: { build: spitter, cap: 60, hip: 0.4, lean: 0, lunge: -0.1, flinch: 0.25, bob: 0.03, sway: 0.03, squash: 0.55, height: 1.1, fallRate: 2.2, rim: '#9ca878', glow: '#c4f03a', glowPower: 2.4 },
  burster: { build: burster, cap: 90, hip: 0.3, lunge: 0, flinch: 0.3, bob: 0.05, sway: 0.03, squash: 0.7, height: 1, noCorpse: true, rim: '#ffa070', glow: '#ff6a1e', glowPower: 5 },
  brood: { build: brood, cap: 14, grain: 2.6, hip: 0.8, flinch: 0.08, bob: 0.03, sway: 0.02, squash: 0.45, height: 1.4, fallRate: 1.3, heavy: true, rim: '#8c8674', glow: '#c8ec5a', glowPower: 2.2 },
  nest: { build: nest, cap: 14, grain: 2.8, hip: 2, flinch: 0.04, bob: 0, sway: 0, squash: 0.4, height: 1.2, fallRate: 1.1, heavy: true, rim: '#ffb0a0', glow: '#ffb83a', glowPower: 3 },
  tyrant: { build: tyrant, cap: 3, grain: 2.2, hip: 1.2, lunge: 0.06, flinch: 0.03, bob: 0.04, sway: 0.02, fallZ: 0.32, rest: 0.1, squash: 0.5, height: 2.4, fallRate: 0.8, heavy: true, rim: '#ff9a80', glow: '#ff4a22', glowPower: 5 },
};
