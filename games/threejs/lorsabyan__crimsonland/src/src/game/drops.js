import { ARENA } from '../config.js';
import { BONUSES, BONUS_LIST } from '../data/bonuses.js';
import { WEAPON_LIST } from '../data/weapons.js';
import { SPRITE } from '../gfx/textures.js';
import { clamp, chance, pick, weighted, len, rand, TAU } from '../core/util.js';

const MAX = 28, LIFE = 11;

export class Drops {
  constructor(game) {
    this.game = game;
    this.items = [];
    for (let i = 0; i < MAX; i++) this.items.push({ on: false, x: 0, z: 0, b: null, weapon: null, life: 0, t: 0 });
    this.sinceLast = 0;
    this.sinceWeapon = 0;
  }

  reset() { for (const d of this.items) d.on = false; this.sinceLast = 0; this.sinceWeapon = 0; }

  maybeDrop(x, z, xpValue) {
    const g = this.game;
    if (!g.hasPerks) return;
    if (this.sinceWeapon > 20) { this.spawn(BONUSES.weapon, x, z); return; }  // a new gun early is what makes the first minute fun
    const pity = clamp(this.sinceLast / 12, 0, 1) * 0.3;
    const base = 0.05 + Math.min(0.12, xpValue / 900) + pity;
    if (!chance(base * g.player.mods.drops)) return;
    this.spawn(this.pickBonus(), x, z);
  }

  pickBonus() {
    const p = this.game.player;
    const hurt = 1 - p.hp / p.maxHp;
    return weighted(BONUS_LIST, (b) => (b.id === 'medkit' ? b.weight * (0.4 + hurt * 3.4) : b.weight));
  }

  pickWeapon() {
    const g = this.game, max = g.director.maxWeaponTier(), cur = g.player.weapon;
    const owned = WEAPON_LIST.filter((w) => g.arsenal.weapons.has(w.id) && w.tier >= 1 && w !== cur);
    const pool = owned.filter((w) => w.tier <= max);
    return pick(pool.length ? pool : owned).id;
  }

  spawn(b, x, z) {
    const d = this.items.find((i) => !i.on);
    if (!d) return;
    d.on = true;
    d.b = b;
    d.x = clamp(x, -ARENA, ARENA); d.z = clamp(z, -ARENA, ARENA);
    d.life = LIFE; d.t = rand(TAU);
    d.weapon = b.id === 'weapon' ? this.pickWeapon() : null;
    this.sinceLast = 0;
    if (b.id === 'weapon') this.sinceWeapon = 0;
  }

  update(dt, input) {
    const g = this.game, p = g.player, m = p.mods;
    this.sinceLast += dt;
    this.sinceWeapon += dt;
    if (p.dead) return;
    for (const d of this.items) {
      if (!d.on) continue;
      d.life -= dt; d.t += dt;
      if (d.life <= 0) { d.on = false; continue; }
      const dist = len(d.x - p.x, d.z - p.z);
      if (m.magnet && dist < m.magnet && dist > 0.01) {
        const s = (1 - dist / m.magnet) * 18 * dt;
        d.x += ((p.x - d.x) / dist) * s; d.z += ((p.z - d.z) / dist) * s;
      }
      const reached = m.reach && len(d.x - input.aimX, d.z - input.aimZ) < 1.2;
      if (dist < 1.25 || reached) { d.on = false; this.collect(d); }
    }
  }

  collect(d) {
    const g = this.game, b = d.b, [r, gg, bl] = b.col;
    if (b.timer) {
      const cur = g.timers[b.timer];
      g.timers[b.timer] = Math.max(cur, 0) + b.time * g.player.mods.bonusTime;
      g.timerMax[b.timer] = g.timers[b.timer];
    }
    b.apply?.(g, d);
    if (b.id !== 'weapon') g.ui.toast(b.name, `rgb(${r * 255 | 0},${gg * 255 | 0},${bl * 255 | 0})`);
    g.fx.ring(d.x, d.z, 2.4, r * 3, gg * 3, bl * 3, 0.4);
    g.audio.play('pickup', { rate: rand(0.96, 1.08) });
  }

  draw() {
    const { glow, soft } = this.game.fx;
    for (const d of this.items) {
      if (!d.on) continue;
      if (d.life < 3 && (d.life * 6) % 1 < 0.35) continue; // blink out
      const [r, g, b] = d.b.col, y = 1.25 + Math.sin(d.t * 2.6) * 0.14, pulse = 1 + Math.sin(d.t * 5) * 0.12;
      glow.draw(d.x, 0.1, d.z, 2.3 * pulse, 0, 0, 0, r * 0.7, g * 0.7, b * 0.7, 0.8, SPRITE.ring, d.t, 1);
      soft.draw(d.x, y, d.z, 1.75, 0, 0, 0, 0.02, 0.02, 0.02, 0.62, SPRITE.dot);
      soft.draw(d.x, y, d.z, 1.15, 0, 0, 0, r, g, b, 1, SPRITE.iconStart + d.b.index);
    }
  }
}

