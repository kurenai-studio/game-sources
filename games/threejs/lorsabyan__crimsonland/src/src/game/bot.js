// Plays the game behind the title screen and drives ?autoplay runs.
// Two skill levels: the attract bot sees everything and aims perfectly; the human model decides
// a few times a second, sees only what is on screen, and aims with lag and error. Balance
// numbers come from the human model, because the perfect bot makes everything look easy.
import { ARENA } from '../config.js';
import { len, clamp, rand, damp } from '../core/util.js';

export class Bot {
  constructor(game) {
    this.game = game;
    this.human = false;
    this.wander = 0;
    this.think = 0; this.target = -1;
    this.mx = 0; this.mz = 0;
    this.seenX = 0; this.seenZ = 0;
    this.aimX = 0; this.aimZ = 5;
  }

  drive(input, dt) {
    if (this.human) this.play(input, dt); else this.perfect(input);
    input.reload = false; input.swap = false; input.firePressed = false;
  }

  perfect(input) {
    const g = this.game, p = g.player, h = g.horde;
    let fx = -p.x * 0.012, fz = -p.z * 0.012, best = -1, bd = 1e9;
    for (let k = 0; k < h.count; k++) {
      const i = h.list[k];
      if (h.dead[i] > 0) continue;
      const dx = h.x[i] - p.x, dz = h.z[i] - p.z, d = len(dx, dz) || 0.01;
      if (d < bd && d < 26) { bd = d; best = i; }
      if (d < 12) {
        const w = (1 + h.rad[i]) / (d * d);
        fx -= (dx / d) * w; fz -= (dz / d) * w;
      }
    }
    for (const c of g.drops.items) {
      if (!c.on) continue;
      const dx = c.x - p.x, dz = c.z - p.z, d = len(dx, dz) || 0.01;
      fx += (dx / d) * 0.09; fz += (dz / d) * 0.09;
    }
    const lim = ARENA - 6;
    if (Math.abs(p.x) > lim) fx -= Math.sign(p.x) * 0.5;
    if (Math.abs(p.z) > lim) fz -= Math.sign(p.z) * 0.5;
    const fl = len(fx, fz) || 1;
    input.moveX = clamp((fx / fl) * Math.min(1, fl * 6), -1, 1);
    input.moveZ = clamp((fz / fl) * Math.min(1, fl * 6), -1, 1);
    if (best >= 0) {
      input.aimX = h.x[best] + h.vx[best] * 0.2;
      input.aimZ = h.z[best] + h.vz[best] * 0.2;
      input.fire = bd < 24;
    } else {
      this.wander += 0.01;
      input.aimX = p.x + Math.cos(this.wander) * 8;
      input.aimZ = p.z + Math.sin(this.wander) * 8;
      input.fire = false;
    }
  }

  // Decide on a reaction tick, then execute that stale decision until the next one.
  play(input, dt) {
    const g = this.game, p = g.player, h = g.horde, s = g.stage;
    this.think -= dt;
    if (this.think <= 0) {
      this.think = rand(0.16, 0.28);
      let fx = -p.x * 0.01, fz = -p.z * 0.01, threat = 0, best = -1, bd = 1e9;
      for (let k = 0; k < h.count; k++) {
        const i = h.list[k];
        if (h.dead[i] > 0) continue;
        const dx = h.x[i] - p.x, dz = h.z[i] - p.z;
        if (Math.abs(dx) > s.viewHalfW || Math.abs(dz) > s.viewHalfH) continue;   // off screen is unknown
        const d = len(dx, dz) || 0.01;
        if (d < bd) { bd = d; best = i; }
        if (d < 7.5) {
          const w = (1 + h.rad[i]) / (d * d);
          threat += w;
          fx -= (dx / d) * w; fz -= (dz / d) * w;
        }
      }
      // Nothing in view but the fight is not over: go looking, as a player would.
      if (best < 0 && h.alive > 0) {
        for (let k = 0; k < h.count; k++) {
          const i = h.list[k];
          if (h.dead[i] > 0) continue;
          const dx = h.x[i] - p.x, dz = h.z[i] - p.z, d = len(dx, dz) || 0.01;
          fx += (dx / d) * 0.3; fz += (dz / d) * 0.3;
          break;
        }
      }
      if (threat < 0.25) {
        for (const c of g.drops.items) {
          if (!c.on) continue;
          const dx = c.x - p.x, dz = c.z - p.z, d = len(dx, dz) || 0.01;
          if (d < 10) { fx += (dx / d) * 0.14; fz += (dz / d) * 0.14; }
        }
      }
      const lim = ARENA - 5;
      if (Math.abs(p.x) > lim) fx -= Math.sign(p.x) * 0.3;
      if (Math.abs(p.z) > lim) fz -= Math.sign(p.z) * 0.3;
      const fl = len(fx, fz) || 1, a = Math.atan2(fz, fx) + rand(-0.5, 0.5), m = Math.min(1, fl * 5);
      this.mx = Math.cos(a) * m; this.mz = Math.sin(a) * m;
      if (this.target >= 0 && (h.dead[this.target] > 0 || !h.hp[this.target])) this.target = -1;
      if (this.target < 0 || Math.random() < 0.3) this.target = best;
      if (this.target >= 0) {
        this.seenX = h.x[this.target] + rand(-0.7, 0.7);
        this.seenZ = h.z[this.target] + rand(-0.7, 0.7);
      }
    }
    this.aimX = damp(this.aimX, this.seenX, 9, dt);
    this.aimZ = damp(this.aimZ, this.seenZ, 9, dt);
    input.moveX = this.mx; input.moveZ = this.mz;
    input.aimX = this.aimX; input.aimZ = this.aimZ;
    input.fire = this.target >= 0;
  }
}
