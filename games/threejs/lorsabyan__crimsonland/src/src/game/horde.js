// Enemy simulation. Struct-of-arrays and a dense live list: no objects per enemy, no per-frame garbage.
import { ARENA } from '../config.js';
import { ENEMIES, ENEMY_IDS } from '../data/enemies.js';
import { BLOOD } from '../gfx/fx.js';
import { SPRITE, STAMP } from '../gfx/textures.js';
import { Grid } from '../core/spatial.js';
import { rand, irand, pick, TAU, wrapAngle, chance, clamp, damp } from '../core/util.js';

const N = 900;
const FLOATS = ['x', 'z', 'vx', 'vz', 'kx', 'kz', 'yaw', 'hp', 'maxHp', 'rad', 'spd', 'phase', 'cool', 'atk', 'tA', 'flash', 'frozen', 'burn', 'poison', 'plague', 'stagger', 'shrink', 'rise', 'dead', 'seed', 'tr', 'tg', 'tb', 'lockX', 'lockZ', 'scale', 'xpMul', 'stab', 'hurtA', 'swing', 'dyaw', 'shape'];
const BOUND = ARENA + 12;

export class Horde {
  constructor(game) {
    this.game = game;
    for (const f of FLOATS) this[f] = new Float32Array(N);
    this.type = new Uint8Array(N);
    this.elite = new Uint8Array(N);
    this.state = new Uint8Array(N);
    this.list = new Int32Array(N);
    this.count = 0;
    this.free = new Int32Array(N);
    this.freeCount = 0;
    this.grid = new Grid(BOUND + 2, 2.5, N);
    this.tmp = new Int32Array(N);
    this.defs = ENEMY_IDS.map((id) => ENEMIES[id]);
    this.reset();
  }

  reset() {
    this.count = 0;
    this.freeCount = N;
    for (let i = 0; i < N; i++) this.free[i] = N - 1 - i;
    this.alive = 0;
    this.bossId = -1;
    this.grid.clear();
  }

  spawn(id, x, z, o = {}) {
    if (!this.freeCount) return -1;
    const d = ENEMIES[id], i = this.free[--this.freeCount];
    this.list[this.count++] = i;
    const hpScale = o.hpScale ?? this.game.director.hpScale;
    const t = pick(d.tints);
    const size = o.size ?? rand(0.92, 1.1);
    this.type[i] = ENEMY_IDS.indexOf(id);
    this.state[i] = 0;
    this.x[i] = x; this.z[i] = z;
    this.vx[i] = this.vz[i] = this.kx[i] = this.kz[i] = 0;
    this.yaw[i] = Math.atan2(-x, -z);
    this.hp[i] = this.maxHp[i] = d.hp * hpScale * (o.hpMul ?? 1);
    this.rad[i] = d.radius * size;
    this.scale[i] = d.scale * size;
    this.spd[i] = d.speed * rand(0.9, 1.12) * (o.speedMul ?? 1);
    this.phase[i] = rand(TAU);
    this.cool[i] = rand(1, 3);
    this.atk[i] = 0;
    this.tA[i] = 0;
    this.flash[i] = this.frozen[i] = this.burn[i] = this.poison[i] = this.plague[i] = this.stagger[i] = 0;
    this.shrink[i] = 1;
    this.rise[i] = o.emerge ? 0 : 1;
    this.dead[i] = 0;
    this.seed[i] = rand(1000);
    this.tr[i] = t[0]; this.tg[i] = t[1]; this.tb[i] = t[2];
    this.elite[i] = o.elite ? 1 : 0;
    this.stab[i] = 0;
    this.hurtA[i] = this.swing[i] = 0;
    this.dyaw[i] = 0;
    this.shape[i] = Math.random();     // per-instance look: clothes, reach pose, missing arm
    this.xpMul[i] = o.elite ? 4 : 1;
    if (o.elite) { this.tr[i] = 1.5; this.tg[i] = 0.6; this.tb[i] = 0.5; }
    this.alive++;
    if (d.boss) { this.bossId = i; this.game.ui.boss(d.name); this.game.audio.play('roar'); }
    return i;
  }

  aura(x, z, r, dmg) {
    const n = this.nearby(x, z, r);
    for (let k = 0; k < n; k++) this.damage(this.tmp[k], dmg, 0, 0, 0, { quiet: true });
  }

  // Copies grid hits inside radius into this.tmp so callers can damage while iterating.
  nearby(x, z, r) {
    const g = this.grid, n = g.query(x, z, r + 3);
    let c = 0;
    for (let k = 0; k < n; k++) {
      const i = g.out[k];
      if (this.dead[i] > 0) continue;
      const dx = this.x[i] - x, dz = this.z[i] - z, rr = r + this.rad[i];
      if (dx * dx + dz * dz <= rr * rr) this.tmp[c++] = i;
    }
    return c;
  }

  underCursor(x, z, freeze, ignite, dt) {
    const n = this.nearby(x, z, 0.8);
    for (let k = 0; k < n; k++) {
      const i = this.tmp[k];
      if (freeze) this.frozen[i] = Math.max(this.frozen[i], 0.25);
      if (ignite) this.burn[i] = Math.max(this.burn[i], 1.2 + dt);
    }
  }

  damage(i, dmg, dx, dz, knock, o = {}) {
    if (this.dead[i] > 0) return false;
    const g = this.game, d = this.defs[this.type[i]];
    const mods = g.player.mods;
    if (o.direct && mods.crit && chance(mods.crit)) dmg *= 3;
    this.hp[i] -= dmg;
    this.flash[i] = o.quiet ? Math.max(this.flash[i], 0.3) : 1;
    if (!o.quiet) this.hurtA[i] = Math.min(1, Math.max(this.hurtA[i], 0.45 + (dmg / this.maxHp[i]) * 2.5));
    const k = knock / d.mass;
    this.kx[i] += dx * k; this.kz[i] += dz * k;
    if (d.mass < 5) this.stagger[i] = Math.max(this.stagger[i], 0.14);
    if (!o.quiet) {
      const blood = BLOOD[d.blood];
      if (this.frozen[i] > 0) g.fx.sparks(this.x[i], this.z[i], 4, 1, 1.6, 2.4, 6);
      else g.fx.hit(this.x[i], this.z[i], dx, dz, blood, clamp(dmg / 40, 0.2, 1.4));
      g.audio.play('hit', { vol: 0.32, rate: rand(0.85, 1.25) });
    }
    if (this.hp[i] <= 0) { this.kill(i, dx, dz, o); return true; }
    return false;
  }

  kill(i, dx, dz, o = {}) {
    if (this.dead[i] > 0) return;
    const g = this.game, d = this.defs[this.type[i]], x = this.x[i], z = this.z[i];
    this.dead[i] = 0.001;
    this.alive--;
    // Turn to face the shot and take the fall backwards, away from whatever did it.
    this.dyaw[i] = dx || dz ? Math.atan2(-dx, -dz) : this.yaw[i];
    this.kx[i] += dx * 3.5; this.kz[i] += dz * 3.5;
    if (i === this.bossId) { this.bossId = -1; g.ui.boss(null); g.nukeFlash(); }
    const blood = BLOOD[d.blood], sc = this.scale[i] * (this.rad[i] / d.radius);
    const shattered = this.frozen[i] > 0;
    if (shattered) {
      g.fx.sparks(x, z, 16, 1, 1.7, 2.6, 9);
      for (let k = 0; k < 8; k++) g.fx.shardBurst(x, z);
      g.audio.play('shatter', { vol: 0.7, rate: rand(0.9, 1.2) });
      this.dead[i] = 2;
    } else {
      g.fx.death(x, z, dx, dz, blood, Math.max(0.8, this.rad[i] * 1.3), o.explosive ? d.gib * 2 : d.gib);
      if (g.layers[this.type[i]].noCorpse) this.dead[i] = 2;
      g.audio.play('splat', { vol: 0.5, rate: rand(0.8, 1.2) });
    }
    if (d.ai === 'burst' && !o.noBurst) g.shots.explode(x, z, 3.2, 70, { kind: 'fire', hurtsPlayer: 16 });
    if (d.ai === 'brood') for (let k = 0; k < 8; k++) this.spawn('skitter', x + rand(-2, 2), z + rand(-2, 2), { emerge: true });
    if (g.player.mods.volatile && chance(g.player.mods.volatile)) g.shots.explode(x, z, 3.2, 60, { kind: 'fire', quiet: true });
    g.onKill(d, x, z, this.burn[i] > 0, this.xpMul[i], this.elite[i] === 1);
  }

  freezeAll(sec) {
    for (let k = 0; k < this.count; k++) {
      const i = this.list[k];
      if (this.dead[i] === 0) this.frozen[i] = Math.max(this.frozen[i], sec);
    }
  }

  update(dt) {
    const g = this.game, p = g.player, grid = this.grid;
    grid.clear();
    const { x, z, list } = this;
    for (let k = 0; k < this.count; k++) { const i = list[k]; if (this.dead[i] === 0) grid.insert(i, x[i], z[i]); }
    const px = p.x, pz = p.z, targetable = !p.dead;
    let k = 0;
    while (k < this.count) {
      const i = list[k];
      if (this.dead[i] > 0) {
        if (this.dead[i] >= 2 || this.corpse(i, dt)) { list[k] = list[--this.count]; this.free[this.freeCount++] = i; continue; }
        k++;
        continue;
      }
      k++;
      const d = this.defs[this.type[i]];
      this.flash[i] = Math.max(0, this.flash[i] - dt * 9);
      this.hurtA[i] = Math.max(0, this.hurtA[i] - dt * 5.5);
      this.swing[i] = Math.max(0, this.swing[i] - dt * 3);
      this.atk[i] -= dt;
      this.cool[i] -= dt;
      this.stagger[i] -= dt;
      if (this.rise[i] < 1) { this.rise[i] = Math.min(1, this.rise[i] + dt * 1.6); continue; }

      this.statusEffects(i, d, dt);
      if (this.dead[i] > 0) continue;

      // Knockback always applies, even to frozen targets.
      const kd = Math.exp(-7 * dt);
      x[i] += this.kx[i] * dt; z[i] += this.kz[i] * dt;
      this.kx[i] *= kd; this.kz[i] *= kd;
      if (this.frozen[i] > 0) { this.frozen[i] -= dt; this.vx[i] = this.vz[i] = 0; continue; }

      const dx = px - x[i], dz = pz - z[i], dist = Math.sqrt(dx * dx + dz * dz) || 0.001;
      let hx = dx / dist, hz = dz / dist, speed = this.spd[i];
      if (!targetable) { const a = this.seed[i] + g.time * 0.3; hx = Math.cos(a); hz = Math.sin(a); speed *= 0.4; }
      else {
        switch (d.ai) {
          case 'weave': {
            const w = Math.sin(g.time * 6 + this.seed[i]) * clamp(dist / 5, 0.1, 1.1), c = Math.cos(w), s = Math.sin(w);
            const nx = hx * c - hz * s; hz = hx * s + hz * c; hx = nx;
            break;
          }
          case 'chase': {
            const w = Math.sin(g.time * 1.4 + this.seed[i]) * 0.3 * clamp(dist / 8, 0, 1), c = Math.cos(w), s = Math.sin(w);
            const nx = hx * c - hz * s; hz = hx * s + hz * c; hx = nx;
            break;
          }
          case 'charge': speed = this.brain_charge(i, hx, hz, dist, speed, dt); if (this.state[i] === 2) { hx = this.lockX[i]; hz = this.lockZ[i]; } break;
          case 'ranged': {
            // Only ever attack from on screen: a player cannot answer what they cannot see.
            const f = g.stage.focus, seen = Math.abs(x[i] - f.x) < g.stage.viewHalfW - 1 && Math.abs(z[i] - f.z) < g.stage.viewHalfH - 1;
            const st = Math.sin(g.time * 0.7 + this.seed[i]) > 0 ? 1 : -1;
            const w = !seen ? 1 : dist < 7 ? -1 : 0;
            const strafe = seen ? 0.8 : 0;
            const nx = hx * w - hz * st * strafe; hz = hz * w + hx * st * strafe; hx = nx;
            if (this.cool[i] <= 0 && seen) { this.cool[i] = rand(2.2, 3.4); this.swing[i] = 1; g.shots.lob(x[i], z[i], px, pz, d.dmg); }
            break;
          }
          case 'burst':
            if (dist < this.rad[i] + 1.1) { this.hp[i] = 0; this.kill(i, hx, hz); continue; }
            break;
          case 'brood':
            if (this.cool[i] <= 0) {
              this.cool[i] = 4;
              for (let s = 0; s < 3; s++) this.spawn('skitter', x[i] + rand(-2.2, 2.2), z[i] + rand(-2.2, 2.2), { emerge: true });
            }
            break;
          case 'nest':
            speed = 0;
            if (this.cool[i] <= 0) {
              this.cool[i] = rand(3, 5);
              const a = rand(TAU), kid = chance(0.7) ? 'skitter' : 'shambler';
              this.spawn(kid, x[i] + Math.cos(a) * 2.6, z[i] + Math.sin(a) * 2.6, { emerge: true });
            }
            break;
          case 'boss': speed = this.brain_boss(i, hx, hz, dist, speed, dt); if (this.state[i] === 2) { hx = this.lockX[i]; hz = this.lockZ[i]; } break;
        }
      }
      if (this.stagger[i] > 0) speed *= 0.45;

      // Soft separation: a crowd should press, not stack.
      let sx = 0, sz = 0;
      if (d.mass < 50) {
        const n = grid.query(x[i], z[i], 1.8);
        for (let q = 0; q < n; q++) {
          const o = grid.out[q];
          if (o === i) continue;
          const ox = x[i] - x[o], oz = z[i] - z[o], rr = this.rad[i] + this.rad[o], l2 = ox * ox + oz * oz;
          // Plague reaches further than the separation push, or bodies would part before it could jump.
          if (this.plague[i] > 0 && this.plague[o] <= 0 && l2 < (rr + 0.9) ** 2 && chance(dt * 2.5)) this.plague[o] = 6;
          if (l2 < rr * rr && l2 > 0.0001) {
            const l = Math.sqrt(l2), f = (rr - l) / rr;
            sx += (ox / l) * f; sz += (oz / l) * f;
          }
        }
      }
      const wantX = hx * speed + sx * 7, wantZ = hz * speed + sz * 7;
      const ac = 8;
      this.vx[i] = damp(this.vx[i], wantX, ac, dt);
      this.vz[i] = damp(this.vz[i], wantZ, ac, dt);
      x[i] = clamp(x[i] + this.vx[i] * dt, -BOUND, BOUND);
      z[i] = clamp(z[i] + this.vz[i] * dt, -BOUND, BOUND);
      const vel = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
      if (vel > 0.15) this.yaw[i] += wrapAngle(Math.atan2(this.vx[i], this.vz[i]) - this.yaw[i]) * Math.min(1, dt * 9);
      this.phase[i] += (vel * d.anim + (d.ai === 'nest' ? 1.4 : 0)) * dt * 1.9;

      // Contact
      if (targetable && d.dmg > 0) {
        const hit = this.rad[i] + 0.42;
        if (dist < hit) {
          if (p.mods.plague) this.plague[i] = Math.max(this.plague[i], 6);
          if (p.mods.melee && (this.stab[i] -= dt) <= 0) { this.stab[i] = 0.5; this.damage(i, 55, hx, hz, 8, { direct: true }); }
          if (this.dead[i] > 0) continue;
          if (this.atk[i] <= 0) {
            this.atk[i] = 0.85;
            this.swing[i] = 1;
            p.hurt(d.dmg * g.director.dmgScale, x[i], z[i]);
            this.kx[i] -= hx * 3; this.kz[i] -= hz * 3;
          }
          if (d.mass >= 5) { p.vx += hx * 40 * dt; p.vz += hz * 40 * dt; }
        }
      }
    }
  }

  // A dying body: it slides with the hit, hits the ground, gets printed into the stain, and sinks.
  corpse(i, dt) {
    const g = this.game, t = this.dead[i], l = g.layers[this.type[i]], d = this.defs[this.type[i]];
    this.flash[i] = Math.max(0, this.flash[i] - dt * 9);
    this.hurtA[i] = Math.max(0, this.hurtA[i] - dt * 5.5);
    if (t >= 1) {
      const n = t + dt * 0.4;
      if (t < 1.4 && n >= 1.4) this.pool(i, d, 1.5);
      this.dead[i] = n;
      return n >= 2;
    }
    const fr = Math.exp(-6 * dt), v = Math.sqrt(this.kx[i] * this.kx[i] + this.kz[i] * this.kz[i]);
    this.x[i] = clamp(this.x[i] + this.kx[i] * dt, -BOUND, BOUND);
    this.z[i] = clamp(this.z[i] + this.kz[i] * dt, -BOUND, BOUND);
    this.kx[i] *= fr; this.kz[i] *= fr;
    this.yaw[i] += wrapAngle(this.dyaw[i] - this.yaw[i]) * Math.min(1, dt * 14);
    if (v > 1.5 && chance(dt * 16)) g.decals.stamp(STAMP.drops, this.x[i], this.z[i], 1.1, 1.1, rand(TAU), BLOOD[d.blood].r, BLOOD[d.blood].g, BLOOD[d.blood].b, 0.7);
    const n = t + dt * l.fallRate;
    this.dead[i] = Math.min(1, n);
    if (n >= 1) {
      this.pool(i, d, 1);
      l.baker?.add(this.x[i], this.z[i], this.yaw[i], this.scale[i] * this.shrink[i], this.tr[i], this.tg[i], this.tb[i], this.shape[i]);
      if (l.heavy) {
        g.stage.shake(0.14);
        g.fx.ring(this.x[i], this.z[i], this.rad[i] * 2, 0.3, 0.26, 0.2, 0.4);
        g.fx.burst(this.x[i], this.z[i], BLOOD[d.blood], 10, 0.8);
      }
    }
    return false;
  }

  // Blood keeps spreading from under a body for a while after it lands.
  pool(i, d, grow) {
    // A body on its back lies behind its feet, and the feet are where its position is.
    const b = BLOOD[d.blood], s = (2.4 + this.rad[i] * 1.8) * grow, back = this.game.layers[this.type[i]].bodyLen * this.scale[i];
    const x = this.x[i] - Math.sin(this.yaw[i]) * back, z = this.z[i] - Math.cos(this.yaw[i]) * back;
    this.game.decals.stamp(irand(STAMP.splat0, STAMP.splat3), x, z, s, s, rand(TAU), b.r * 0.6, b.g * 0.6, b.b * 0.6, 0.72, 0.3);
  }

  statusEffects(i, d, dt) {
    const g = this.game, fxMod = g.player.mods.fire;
    if (this.burn[i] > 0) {
      this.burn[i] -= dt;
      this.hp[i] -= 16 * fxMod * dt;
      if (Math.random() < dt * 22) g.fx.flames(this.x[i], this.z[i], 1, this.rad[i] * 0.7);
      if (this.hp[i] <= 0) { this.kill(i, 0, 0, { quiet: true }); return; }
    }
    if (this.poison[i] > 0) {
      this.poison[i] -= dt;
      this.hp[i] -= 11 * dt;
      if (this.hp[i] <= 0) { this.kill(i, 0, 0, { quiet: true }); return; }
    }
    if (this.plague[i] > 0) {
      this.plague[i] -= dt;
      this.hp[i] -= 9 * dt;
      if (this.hp[i] <= 0) { this.kill(i, 0, 0, { quiet: true }); }
    }
  }

  brain_charge(i, hx, hz, dist, speed, dt) {
    const s = this.state[i], g = this.game;
    if (s === 0) {
      if (dist < 15 && this.cool[i] <= 0) { this.state[i] = 1; this.tA[i] = 0.75; g.audio.play('roar', { vol: 0.32, rate: 1.5 }); }
      return speed;
    }
    this.tA[i] -= dt;
    if (s === 1) {
      this.flash[i] = 0.35 + Math.sin(g.time * 40) * 0.25;
      if (this.tA[i] <= 0) { this.state[i] = 2; this.tA[i] = 1.05; this.lockX[i] = hx; this.lockZ[i] = hz; }
      return 0;
    }
    if (this.tA[i] <= 0) { this.state[i] = 0; this.cool[i] = rand(3, 5.5); }
    return 15;
  }

  brain_boss(i, hx, hz, dist, speed, dt) {
    const s = this.state[i], g = this.game, x = this.x[i], z = this.z[i];
    this.tA[i] -= dt;
    if (s === 0 && this.cool[i] <= 0) {
      const next = pick([1, 1, 3, 4]);
      this.state[i] = next;
      this.tA[i] = next === 1 ? 0.9 : next === 3 ? 2.2 : 0.8;
      this.atk[i] = 0;
      if (next === 1) g.audio.play('roar', { vol: 0.5, rate: 0.8 });
    }
    if (s === 1) {            // wind up, then charge
      this.flash[i] = 0.35 + Math.sin(g.time * 36) * 0.25;
      if (this.tA[i] <= 0) { this.state[i] = 2; this.tA[i] = 1.25; this.lockX[i] = hx; this.lockZ[i] = hz; }
      return 0;
    }
    if (s === 2) {            // charge
      if (this.tA[i] <= 0) { this.state[i] = 0; this.cool[i] = rand(2.5, 4); }
      if (Math.random() < dt * 30) g.stage.shake(0.05);
      return 17;
    }
    if (s === 3) {            // radial volleys
      this.lockX[i] -= dt;
      if (this.lockX[i] <= 0) {
        this.lockX[i] = 0.42;
        const off = rand(TAU);
        for (let k = 0; k < 18; k++) {
          const a = off + (k / 18) * TAU;
          g.shots.spawn('fireball', x + Math.cos(a) * 3, z + Math.sin(a) * 3, Math.cos(a) * 11, Math.sin(a) * 11, 14, { enemy: true, rad: 0.5, life: 4 });
        }
        g.audio.play('plasma', { rate: 0.6, vol: 0.6 });
      }
      if (this.tA[i] <= 0) { this.state[i] = 0; this.cool[i] = rand(3, 5); }
      return 0.6;
    }
    if (s === 4) {            // summon
      if (this.tA[i] <= 0) {
        for (let k = 0; k < 10; k++) { const a = rand(TAU); this.spawn(chance(0.4) ? 'burster' : 'ripper', x + Math.cos(a) * 5, z + Math.sin(a) * 5, { emerge: true }); }
        this.state[i] = 0; this.cool[i] = rand(3, 5);
      }
      return 0;
    }
    return speed;
  }

  render() {
    const layers = this.game.layers, list = this.list;
    for (const l of layers) l.begin();
    for (let k = 0; k < this.count; k++) {
      const i = list[k];
      const l = layers[this.type[i]];
      const dead = this.dead[i];
      if (dead >= 2) continue;
      const moving = dead > 0 ? 0 : this.frozen[i] > 0 ? 0 : 1;
      const v = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
      if (this.elite[i] && dead === 0) this.game.fx.glow.draw(this.x[i], 0.12, this.z[i], this.rad[i] * 3.6, 0, 0, 0, 1.3, 0.12, 0.08, 0.6, SPRITE.ring, 0, 1);
      const s = this.swing[i], lunge = Math.sin(Math.PI * Math.min(1, s * 1.1));
      const windup = this.state[i] === 1 ? 1 : this.state[i] === 2 ? 0.55 : lunge;
      l.push(this.x[i], 0, this.z[i], this.yaw[i], this.phase[i], this.scale[i] * this.shrink[i], moving * clamp(v / 1.4, 0.15, 1.1), dead,
        this.tr[i], this.tg[i], this.tb[i], this.flash[i],
        clamp(this.frozen[i] * 5, 0, 1), this.burn[i] > 0 ? 1 : 0, clamp(this.poison[i] + this.plague[i], 0, 1), this.rise[i],
        windup, this.hurtA[i], clamp(1 - this.hp[i] / this.maxHp[i], 0, 0.42), this.shape[i]);
    }
    for (const l of layers) l.end();
  }
}
