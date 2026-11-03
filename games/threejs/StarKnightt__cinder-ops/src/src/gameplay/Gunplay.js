import { PLAYER_CONFIG } from '../core/Constants.js';

/* Shared gunplay math — no allocations, no Three.js.
 * Camera recoil pattern, spread envelope, and the 5-DOF viewmodel spring
 * are all dt-correct (exp-decay / semi-implicit Euler) so 30 fps and 144 fps
 * settle the same. */

export const RECOIL_VEL_BLEED = 16;
export const RECOIL_RECOVER = 6.5;
/* Yaw auto-return at the pitch rate slid the crosshair sideways after a
 * burst (CS2 never yaw-recovers). 2.0 is slow enough to be invisible under
 * normal aiming but still drains the render-only offset to zero. */
export const RECOIL_RECOVER_YAW = 2.0;
export const RECOIL_IMPULSE = 38;
export const BURST_IDLE = 0.32;
export const VM_SPRING_K = 210;
/* 19 was zeta 0.66 — the gun wobbled ~2 cycles (~0.4 s) after the last
 * shot. 29 = 2*sqrt(210) is critical damping: sharp punch, no oscillation. */
export const VM_SPRING_D = 29;
export const FOV_KICK_BLEED = 13;
export const FOV_KICK_CAP = 3.2;
export const CROSSHAIR_PX_PER_RAD = 240;
export const CROSSHAIR_RETURN = 20;

/** Learnable spray: hard first kick, settled climb, then a two-sine plateau.
 * n is 1-indexed burst count (Weapon._burst). No yaw noise — CS2 sprays
 * are deterministic. */
export function recoilPattern(n) {
  const i = n | 0;
  const vert = i <= 1 ? 1.55 : (i < 5 ? 1.12 : 0.82 + Math.sin(i * 0.9) * 0.10);
  const drift = Math.sin(i * 0.62) * 0.85 + Math.sin(i * 0.23 + 1.1) * 0.45;
  return { vert, drift };
}

/** Camera recoil velocity impulse for shot n of the current burst. */
export function recoilImpulse(cfg, n) {
  const { vert, drift } = recoilPattern(n);
  const y = cfg?.recoil?.y || 0;
  const x = cfg?.recoil?.x || 0;
  return { vy: y * RECOIL_IMPULSE * vert, vx: drift * x * RECOIL_IMPULSE };
}

/** Integrate camera recoil. Velocity always bleeds; pitch/yaw only
 * auto-recover once the kick has died off so a mag dump can climb
 * (tap-fire still self-centers within ~0.5 s). */
export function stepRecoil(s, dt) {
  if (dt <= 0) return s;
  const vb = Math.exp(-RECOIL_VEL_BLEED * dt);
  s.recoilVelP *= vb;
  s.recoilVelY *= vb;
  s.recoilPitch += s.recoilVelP * dt;
  s.recoilYaw += s.recoilVelY * dt;
  const idle = Math.abs(s.recoilVelP) < 0.18 && Math.abs(s.recoilVelY) < 0.18;
  if (idle) {
    s.recoilPitch *= Math.exp(-RECOIL_RECOVER * dt);
    s.recoilYaw *= Math.exp(-RECOIL_RECOVER_YAW * dt);
  }
  return s;
}

/** Hip/ADS base + accumulated bloom + move/air, then crouch / ADS extras. */
export function currentSpread(cfg, bloom, st) {
  const sp = cfg?.spread || {};
  const ads = !!(st && (st.ads || st.scoped));
  let s = ads ? (sp.ads ?? 0) : (sp.hip ?? 0);
  const speed = st?.speed || 0;
  const extra = (bloom || 0)
    + (speed / PLAYER_CONFIG.SPRINT) * (sp.move || 0)
    + (st && st.grounded === false ? (sp.air || 0) : 0);
  const adsK = st?.adsEase ?? (ads ? 1 : 0);
  const adsMul = sp.adsMult ?? 1;
  s += extra * (1 + (adsMul - 1) * adsK);
  if (st?.crouching && speed < 0.6) s *= (sp.crouchMult ?? 1);
  return s;
}

/** Semi-implicit Euler + exp damping on one spring axis. Mutates `s`. */
export function stepSpringAxis(s, pKey, vKey, dt, K = VM_SPRING_K, D = VM_SPRING_D) {
  if (dt <= 0) return;
  s[vKey] = (s[vKey] + (-s[pKey] * K) * dt) * Math.exp(-D * dt);
  s[pKey] += s[vKey] * dt;
}

export function stepViewmodel(s, dt) {
  stepSpringAxis(s, 'pz', 'vz', dt);
  stepSpringAxis(s, 'py', 'vy', dt);
  stepSpringAxis(s, 'rx', 'vrx', dt);
  stepSpringAxis(s, 'ry', 'vry', dt);
  stepSpringAxis(s, 'rz', 'vrz', dt);
  return s;
}

export function impulseViewmodel(s, vmKick, vmRot) {
  s.vz += vmKick * 46;
  s.vy += vmKick * 13;
  s.vrx -= vmRot * 46;
  s.vry += (Math.random() - 0.5) * vmRot * 24;
  s.vrz += (Math.random() - 0.5) * vmRot * 30;
  return s;
}

export function makeViewmodel() {
  return { pz: 0, py: 0, rx: 0, ry: 0, rz: 0, vz: 0, vy: 0, vrx: 0, vry: 0, vrz: 0 };
}
