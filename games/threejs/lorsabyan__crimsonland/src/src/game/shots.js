// Projectiles, both sides. One pool, behaviour by kind.
import { ARENA } from '../config.js';
import { SPRITE } from '../gfx/textures.js';
import { rand, TAU, len, wrapAngle } from '../core/util.js';

const N = 1400;
const F = ['x', 'z', 'vx', 'vz', 'life', 'dmg', 'rad', 'pierce', 'knock', 'splash', 'gen', 't', 'y', 'tx', 'tz', 'r', 'g', 'b'];
const KINDS = ['bullet', 'plasma', 'rocket', 'seeker', 'flame', 'ion', 'blade', 'split', 'shrink', 'pulse', 'mine', 'acid', 'fireball'];
const K = Object.fromEntries(KINDS.map((k, i) => [k, i]));
const LIFE = { bullet: 0.8, plasma: 1.4, rocket: 1.8, seeker: 2.8, ion: 0.55, split: 0.9, shrink: 0.9, fireball: 2 };
const RAD = { bullet: 0.12, plasma: 0.3, rocket: 0.3, seeker: 0.26, flame: 0.75, ion: 0.16, blade: 0.5, split: 0.14, shrink: 0.18, pulse: 0.9, fireball: 0.5 };

export class Shots {
  constructor(game) {
    this.game = game;
    for (const f of F) this[f] = new Float32Array(N);
    this.kind = new Uint8Array(N);
    this.owner = new Uint8Array(N);
    this.big = new Uint8Array(N);
    this.ignite = new Uint8Array(N);
    this.last = new Int32Array(N);
    this.aimed = new Uint8Array(N);   // fired by the trigger, counts towards accuracy
    this.count = 0;
    this.visited = new Int32Array(64);
  }

  reset() { this.count = 0; }

  spawn(kindName, x, z, vx, vz, dmg, o = {}) {
    if (this.count >= N) return -1;
    const i = this.count++, kind = K[kindName];
    this.kind[i] = kind;
    this.owner[i] = o.enemy ? 1 : 0;
    this.x[i] = x; this.z[i] = z; this.vx[i] = vx; this.vz[i] = vz;
    this.dmg[i] = dmg;
    this.life[i] = o.life ?? LIFE[kindName] ?? 1;
    this.rad[i] = o.rad ?? RAD[kindName] ?? 0.15;
    this.pierce[i] = o.pierce ?? 0;
    this.knock[i] = o.knock ?? 2;
    this.splash[i] = o.splash ?? 0;
    this.gen[i] = o.gen ?? 0;
    this.big[i] = o.big ? 1 : 0;
    this.ignite[i] = o.ignite ? 1 : 0;
    this.aimed[i] = o.aimed ? 1 : 0;
    this.last[i] = -1;
    this.t[i] = 0; this.y[i] = 1.1; this.tx[i] = o.tx ?? 0; this.tz[i] = o.tz ?? 0;
    const c = o.col ?? [1, 0.8, 0.4];
    this.r[i] = c[0]; this.g[i] = c[1]; this.b[i] = c[2];
    return i;
  }

  fire(w, x, z, dx, dz, dmg) {
    const g = this.game, m = g.player.mods;
    const speed = (w.speed ?? 0) * m.bulletSpeed * rand(0.97, 1.03);
    const fire = g.timers.fire > 0;
    if (fire) dmg *= 2.2;
    const col = fire ? [1, 0.42, 0.12] : w.col;
    if (w.kind === 'rail') { this.rail(x, z, dx, dz, dmg, w.pierce, col, w.knock); return; }
    if (w.kind === 'mine') { this.spawn('mine', g.player.x, g.player.z, 0, 0, dmg, { life: 22, rad: 0, splash: w.splash, knock: w.knock, col }); return; }
    this.spawn(w.kind, x, z, dx * speed, dz * speed, dmg, {
      life: w.life, pierce: w.pierce, knock: w.knock, splash: w.splash, gen: w.gen ?? w.chain, big: w.big, col, ignite: fire || w.fire, aimed: true,
    });
  }

  // Instant line: every creature along it takes the hit.
  rail(x, z, dx, dz, dmg, pierce, col, knock) {
    const g = this.game, h = g.horde, range = 48;
    let hits = 0;
    const seen = this.tmpSeen ?? (this.tmpSeen = new Set());
    seen.clear();
    for (let s = 1; s < range && hits < pierce; s += 2.5) {
      const cx = x + dx * s, cz = z + dz * s;
      const n = h.nearby(cx, cz, 1.3);
      for (let k = 0; k < n; k++) {
        const i = h.tmp[k];
        if (seen.has(i)) continue;
        const ox = h.x[i] - x, oz = h.z[i] - z, along = ox * dx + oz * dz, side = Math.abs(ox * dz - oz * dx);
        if (along < 0 || side > h.rad[i] + 0.25) continue;
        seen.add(i);
        hits++;
        h.damage(i, dmg, dx, dz, knock, { direct: true });
        if (hits >= pierce) break;
      }
    }
    if (hits) g.stats.hit++;
    const [r, gg, b] = col;
    g.fx.beam(x, z, x + dx * range, z + dz * range, 1.12, 0.42, r * 9, gg * 9, b * 9, 0.14);
    g.fx.beam(x, z, x + dx * range, z + dz * range, 1.12, 0.14, 7, 7, 8, 0.08);
  }

  ring(x, z, n, kind, dmg) {
    const col = kind === 'plasma' ? [1, 0.5, 0.2] : kind === 'ion' ? [0.6, 0.76, 1] : [1, 0.8, 0.4];
    const speed = kind === 'plasma' ? 30 : kind === 'ion' ? 60 : 56;
    const off = rand(TAU);
    for (let i = 0; i < n; i++) {
      const a = off + (i / n) * TAU, c = Math.cos(a), s = Math.sin(a);
      this.spawn(kind, x + c * 0.6, z + s * 0.6, c * speed, s * speed, dmg, { col, splash: kind === 'plasma' ? 1.5 : 0 });
    }
    this.game.fx.ring(x, z, 4, col[0] * 3, col[1] * 3, col[2] * 3);
  }

  lob(x, z, tx, tz, dmg) {
    const d = len(tx - x, tz - z), t = Math.max(0.5, d / 14);
    const i = this.spawn('acid', x, z, (tx - x) / t, (tz - z) / t, dmg, { enemy: true, life: t, rad: 1.6, col: [0.7, 1.3, 0.15] });
    if (i >= 0) { this.tx[i] = t; }
    this.game.audio.play('spit', { vol: 0.42 });
  }

  explode(x, z, r, dmg, o = {}) {
    const g = this.game, h = g.horde;
    const n = h.nearby(x, z, r);
    const ids = this.blast ?? (this.blast = new Int32Array(900));
    for (let k = 0; k < n; k++) ids[k] = h.tmp[k];
    for (let k = 0; k < n; k++) {
      const i = ids[k], dx = h.x[i] - x, dz = h.z[i] - z, d = Math.sqrt(dx * dx + dz * dz) || 0.01;
      const f = 1 - Math.min(1, d / (r + h.rad[i])) * 0.6;
      h.damage(i, dmg * f, dx / d, dz / d, (o.knock ?? 9) * f, { explosive: true, noBurst: false, quiet: n > 12 });
    }
    if (o.hurtsPlayer) {
      const p = g.player, d = len(p.x - x, p.z - z);
      if (d < r) p.hurt(o.hurtsPlayer * (1 - (d / r) * 0.5), x, z);
    }
    g.fx.explosion(x, z, r * 0.62, o.kind ?? 'fire');
    if (!o.quiet) g.audio.play('explosion', { vol: Math.min(1, 0.45 + r * 0.09), rate: rand(0.9, 1.1) });
  }

  shockChain(x, z, jumps, dmg) {
    const h = this.game.horde;
    let cx = x, cz = z;
    const v = this.visited;
    let vn = 0;
    for (let j = 0; j < jumps && vn < v.length; j++) {
      const best = this.nearest(cx, cz, 16, vn);
      if (best < 0) break;
      v[vn++] = best;
      const bx = h.x[best], bz = h.z[best];
      this.game.fx.arc(cx, cz, bx, bz, 3, 3.6, 8);
      h.damage(best, dmg, 0, 0, 0, { quiet: true });
      cx = bx; cz = bz;
    }
    this.game.audio.play('ion', { rate: 0.75 });
  }

  nearest(x, z, r, visitedCount) {
    const h = this.game.horde, n = h.nearby(x, z, r);
    let best = -1, bd = 1e9;
    for (let k = 0; k < n; k++) {
      const i = h.tmp[k];
      let seen = false;
      for (let q = 0; q < visitedCount; q++) if (this.visited[q] === i) { seen = true; break; }
      if (seen) continue;
      const d = (h.x[i] - x) ** 2 + (h.z[i] - z) ** 2;
      if (d < bd) { bd = d; best = i; }
    }
    return best;
  }

  remove(i) {
    const last = --this.count;
    if (i === last) return;
    for (const f of F) this[f][i] = this[f][last];
    this.kind[i] = this.kind[last]; this.owner[i] = this.owner[last]; this.big[i] = this.big[last];
    this.ignite[i] = this.ignite[last]; this.last[i] = this.last[last]; this.aimed[i] = this.aimed[last];
  }

  update(dt) {
    const g = this.game, h = g.horde, p = g.player;
    let i = 0;
    while (i < this.count) {
      const kind = this.kind[i];
      this.t[i] += dt;
      if ((this.life[i] -= dt) <= 0) {
        if (this.expire(i, kind)) { this.remove(i); continue; }
      }
      if (kind === K.seeker) this.steer(i, dt);
      if (kind === K.rocket || kind === K.seeker) {
        g.fx.soft.spawn(this.x[i], 1, this.z[i], rand(-0.4, 0.4), 0.5, rand(-0.4, 0.4), 0.7, 0.22, 0.9, 0.42, 0.4, 0.38, 0.28, SPRITE.smoke, { rot: rand(TAU) });
      }
      if (kind === K.mine) { if (this.mine(i)) { this.remove(i); continue; } i++; continue; }
      const px = this.x[i], pz = this.z[i];
      const nx = (this.x[i] = px + this.vx[i] * dt), nz = (this.z[i] = pz + this.vz[i] * dt);
      if (kind === K.blade) this.bounce(i);
      else if (Math.abs(nx) > ARENA + 11 || Math.abs(nz) > ARENA + 11) { this.remove(i); continue; }
      if (kind === K.flame) { this.rad[i] += dt * 2.1; this.vx[i] *= Math.exp(-2.2 * dt); this.vz[i] *= Math.exp(-2.2 * dt); }

      if (this.owner[i] === 1) {
        if (kind === K.fireball && !p.dead && len(nx - p.x, nz - p.z) < this.rad[i] + 0.45) {
          p.hurt(this.dmg[i], px, pz);
          this.remove(i);
          continue;
        }
        i++;
        continue;
      }
      const hit = this.sweep(px, pz, nx, nz, this.rad[i], this.last[i]);
      if (hit >= 0 && this.impact(i, kind, hit)) { this.remove(i); continue; }
      i++;
    }
  }

  // Closest enemy along the segment, or -1.
  sweep(ax, az, bx, bz, rad, skip) {
    const h = this.game.horde, grid = h.grid;
    const dx = bx - ax, dz = bz - az, l2 = dx * dx + dz * dz;
    const n = grid.query((ax + bx) * 0.5, (az + bz) * 0.5, Math.sqrt(l2) * 0.5 + rad + 3.2);
    let best = -1, bt = 1e9;
    for (let k = 0; k < n; k++) {
      const i = grid.out[k];
      if (i === skip || h.dead[i] > 0 || h.rise[i] < 0.4) continue;
      const ox = h.x[i] - ax, oz = h.z[i] - az;
      const t = l2 > 0 ? Math.min(1, Math.max(0, (ox * dx + oz * dz) / l2)) : 0;
      const qx = ox - dx * t, qz = oz - dz * t, rr = rad + h.rad[i];
      if (qx * qx + qz * qz < rr * rr && t < bt) { bt = t; best = i; }
    }
    return best;
  }

  impact(i, kind, e) {
    const g = this.game, h = g.horde, m = g.player.mods;
    const speed = len(this.vx[i], this.vz[i]) || 1, ux = this.vx[i] / speed, uz = this.vz[i] / speed;
    const dmg = this.dmg[i], knock = this.knock[i];
    if (this.aimed[i]) { g.stats.hit++; this.aimed[i] = 0; }
    this.last[i] = e;
    if (m.poison) h.poison[e] = Math.max(h.poison[e], 3);
    if (this.ignite[i]) h.burn[e] = Math.max(h.burn[e], m.fire > 1 ? 4 : 2.5);

    switch (kind) {
      case K.rocket: case K.seeker: case K.fireball:
        this.explode(this.x[i], this.z[i], this.splash[i] || 2.5, dmg, { kind: 'fire', knock });
        return true;
      case K.plasma:
        if (this.splash[i] > 2) {
          this.explode(this.x[i], this.z[i], this.splash[i], dmg * 0.5, { kind: 'plasma', knock });
          h.damage(e, dmg * 0.5, ux, uz, knock, { direct: true });
          return --this.pierce[i] < 0;
        }
        h.damage(e, dmg, ux, uz, knock, { direct: true });
        { const c = this.nearbyDamage(this.x[i], this.z[i], this.splash[i], dmg * 0.35); g.fx.sparks(this.x[i], this.z[i], 6 + c, this.r[i] * 3, this.g[i] * 3, this.b[i] * 3, 8); }
        return true;
      case K.ion: {
        const chain = (this.gen[i] || 2) + m.chain;
        h.damage(e, dmg, ux, uz, knock, { direct: true, quiet: true });
        this.visited[0] = e;
        let vn = 1, cx = this.x[i], cz = this.z[i];
        for (let j = 0; j < chain; j++) {
          const n = this.nearest(cx, cz, 7, vn);
          if (n < 0) break;
          this.visited[vn++] = n;
          g.fx.arc(cx, cz, h.x[n], h.z[n], 2.2, 3, 7);
          cx = h.x[n]; cz = h.z[n];
          h.damage(n, dmg * 0.7, 0, 0, 0.5, { quiet: true });
        }
        g.fx.sparks(this.x[i], this.z[i], 5, 2.5, 3, 7, 8);
        return true;
      }
      case K.split: {
        h.damage(e, dmg, ux, uz, knock, { direct: true });
        if (this.gen[i] > 0) {
          const a = Math.atan2(uz, ux), x = this.x[i], z = this.z[i], gen = this.gen[i] - 1, col = [this.r[i], this.g[i], this.b[i]];
          for (const s of [-0.5, 0.5]) {
            const id = this.spawn('split', x, z, Math.cos(a + s) * speed, Math.sin(a + s) * speed, dmg * 0.7, { gen, knock, col });
            if (id >= 0) this.last[id] = e;
          }
        }
        return true;
      }
      case K.shrink:
        h.damage(e, dmg, ux, uz, knock, { direct: true, quiet: true });
        if (h.dead[e] === 0) {
          h.shrink[e] *= 0.84;
          h.hp[e] *= 0.84;
          h.rad[e] *= 0.84;
          g.fx.sparks(h.x[e], h.z[e], 4, 3, 0.8, 2.6, 5);
          if (h.shrink[e] < 0.34) { h.hp[e] = 0; h.kill(e, ux, uz); }
        }
        return true;
      case K.blade:
        h.damage(e, dmg, ux, uz, knock, { direct: true });
        g.fx.sparks(this.x[i], this.z[i], 3, 3, 3, 3.4, 9);
        return --this.pierce[i] < 0;
      case K.flame:
        h.damage(e, dmg, ux, uz, knock, { quiet: true });
        h.burn[e] = Math.max(h.burn[e], m.fire > 1 ? 4 : 2.5);
        return --this.pierce[i] < 0;
      case K.pulse:
        h.damage(e, dmg, ux, uz, knock, { direct: true, quiet: true });
        g.fx.sparks(this.x[i], this.z[i], 2, 1, 3, 2.6, 6);
        return --this.pierce[i] < 0;
      default: {
        h.damage(e, dmg, ux, uz, knock, { direct: true });
        if (m.bounce && this.gen[i] === 0) {
          const n = this.nearestFrom(e, 10);
          if (n >= 0) {
            const dx = h.x[n] - this.x[i], dz = h.z[n] - this.z[i], d = len(dx, dz) || 1;
            this.vx[i] = (dx / d) * speed; this.vz[i] = (dz / d) * speed;
            this.gen[i] = 1;
            return false;
          }
        }
        return --this.pierce[i] < 0;
      }
    }
  }

  nearestFrom(e, r) {
    this.visited[0] = e;
    const h = this.game.horde;
    return this.nearest(h.x[e], h.z[e], r, 1);
  }

  nearbyDamage(x, z, r, dmg) {
    if (!r) return 0;
    const h = this.game.horde, n = h.nearby(x, z, r);
    const ids = this.blast ?? (this.blast = new Int32Array(900));
    for (let k = 0; k < n; k++) ids[k] = h.tmp[k];
    for (let k = 0; k < n; k++) h.damage(ids[k], dmg, 0, 0, 0, { quiet: true });
    return n;
  }

  expire(i, kind) {
    const g = this.game, x = this.x[i], z = this.z[i];
    if (kind === K.flame) g.fx.flameOut(x, z);
    if (kind === K.rocket || kind === K.seeker) this.explode(x, z, this.splash[i] || 2.5, this.dmg[i], { kind: 'fire', knock: this.knock[i] });
    else if (kind === K.plasma && this.splash[i] > 2) this.explode(x, z, this.splash[i], this.dmg[i] * 0.5, { kind: 'plasma', knock: this.knock[i] });
    else if (kind === K.acid) {
      g.fx.explosion(x, z, 0.9, 'acid');
      for (let k = 0; k < 8; k++) g.fx.acidDrop(x, z);
      const p = g.player;
      if (len(p.x - x, p.z - z) < this.rad[i]) p.hurt(this.dmg[i], x, z);
      g.audio.play('splat', { vol: 0.5, rate: 1.4 });
    }
    return true;
  }

  steer(i, dt) {
    const h = this.game.horde;
    const n = this.nearest(this.x[i], this.z[i], 18, 0);
    if (n < 0) return;
    const want = Math.atan2(h.z[n] - this.z[i], h.x[n] - this.x[i]);
    const cur = Math.atan2(this.vz[i], this.vx[i]);
    const a = cur + Math.max(-1, Math.min(1, wrapAngle(want - cur) * 6)) * 5.5 * dt;
    const s = len(this.vx[i], this.vz[i]);
    this.vx[i] = Math.cos(a) * s; this.vz[i] = Math.sin(a) * s;
  }

  bounce(i) {
    const lim = ARENA + 1;
    if (Math.abs(this.x[i]) > lim) { this.vx[i] *= -1; this.x[i] = Math.sign(this.x[i]) * lim; this.last[i] = -1; }
    if (Math.abs(this.z[i]) > lim) { this.vz[i] *= -1; this.z[i] = Math.sign(this.z[i]) * lim; this.last[i] = -1; }
  }

  mine(i) {
    const h = this.game.horde;
    if (this.t[i] < 0.5) return false;
    if (h.nearby(this.x[i], this.z[i], 1.8) > 0) {
      this.explode(this.x[i], this.z[i], this.splash[i], this.dmg[i], { kind: 'fire', knock: this.knock[i] });
      return true;
    }
    return false;
  }

  draw() {
    const { glow, soft } = this.game.fx;
    for (let i = 0; i < this.count; i++) {
      const kind = this.kind[i], x = this.x[i], z = this.z[i], r = this.r[i], g = this.g[i], b = this.b[i];
      const vx = this.vx[i], vz = this.vz[i];
      switch (kind) {
        case K.bullet: case K.split:
          glow.draw(x, 1.1, z, 0.07, vx * 0.018, 0, vz * 0.018, r * 6, g * 5, b * 4, 1, SPRITE.dot);
          glow.draw(x, 1.1, z, 0.2, vx * 0.009, 0, vz * 0.009, r * 0.9, g * 0.65, b * 0.4, 0.7, SPRITE.dot);
          break;
        case K.plasma: {
          const s = this.big[i] ? 3 : 1;
          glow.draw(x, 1.1, z, s, 0, 0, 0, r * 1.3, g * 1.3, b * 1.3, 0.9, SPRITE.plasma);
          glow.draw(x, 1.1, z, s * 0.34, 0, 0, 0, r * 2 + 0.5, g * 2 + 0.5, b * 2 + 0.5, 1, SPRITE.dot);
          break;
        }
        case K.rocket: case K.seeker:
          glow.draw(x, 1.05, z, 0.26, vx * -0.012, 0, vz * -0.012, 3.2, 1.3, 0.3, 1, SPRITE.dot);
          soft.draw(x, 1.05, z, 0.2, vx * 0.018, 0, vz * 0.018, 0.14, 0.14, 0.15, 1, SPRITE.drop);
          break;
        case K.flame: {
          // Burns down from yellow-white through orange to a dull red as it ages.
          const u = Math.min(1, this.t[i] / 0.48), s = this.rad[i] * 2;
          const fr = u < 0.4 ? 2.1 : 2.1 - (u - 0.4) * 2.6, fg = u < 0.4 ? 1.25 - u * 1.5 : 0.65 - (u - 0.4) * 0.95, fb = u < 0.25 ? 0.5 - u * 1.6 : 0.1 * (1 - u);
          glow.draw(x, 0.95, z, s, 0, 0, 0, fr, fg, fb, 0.34 * (1 - u * 0.75), SPRITE.flame, this.t[i] * 4 + i);
          break;
        }
        case K.ion:
          glow.draw(x, 1.1, z, 0.1, vx * 0.014, 0, vz * 0.014, r * 3, g * 3.2, b * 5, 1, SPRITE.dot);
          glow.draw(x, 1.1, z, 0.34, vx * 0.008, 0, vz * 0.008, r * 0.7, g * 0.7, b * 1.3, 0.8, SPRITE.dot);
          break;
        case K.shrink:
          glow.draw(x, 1.1, z, 0.42, 0, 0, 0, 4, 1, 3.3, 1, SPRITE.ring);
          break;
        case K.pulse: {
          const s = 1.7 + this.t[i] * 3;
          glow.draw(x, 1, z, s, 0, 0, 0, r * 0.75, g * 0.75, b * 0.75, 0.8 * Math.min(1, this.life[i] * 5), SPRITE.ring, 0, 1);
          break;
        }
        case K.blade:
          soft.draw(x, 0.85, z, 1.1, 0, 0, 0, 0.86, 0.88, 0.94, 1, SPRITE.blade, this.t[i] * 24, 1);
          glow.draw(x, 0.85, z, 1.2, 0, 0, 0, 0.4, 0.4, 0.5, 0.6, SPRITE.halo);
          break;
        case K.mine: {
          const on = this.t[i] * 3 % 1 < 0.5 ? 6 : 1.4;
          soft.draw(x, 0.12, z, 0.56, 0, 0, 0, 0.1, 0.1, 0.11, 1, SPRITE.drop, 0, 1);
          glow.draw(x, 0.2, z, 0.3, 0, 0, 0, on, on * 0.2, on * 0.1, 1, SPRITE.dot);
          break;
        }
        case K.acid: {
          const u = 1 - this.life[i] / Math.max(0.01, this.tx[i]);
          const y = 0.9 + Math.sin(u * Math.PI) * 4.6;
          glow.draw(x, y, z, 0.7, 0, 0, 0, 1.6, 2.8, 0.3, 1, SPRITE.plasma);
          soft.draw(x, 0.08, z, 0.9 + u * 0.6, 0, 0, 0, 0, 0, 0, 0.42, SPRITE.dot, 0, 1);
          break;
        }
        case K.fireball:
          glow.draw(x, 1, z, 1.3, 0, 0, 0, 2.2, 0.75, 0.14, 0.9, SPRITE.plasma);
          glow.draw(x, 1, z, 0.42, 0, 0, 0, 3, 2.1, 0.8, 1, SPRITE.dot);
          break;
      }
    }
  }
}
