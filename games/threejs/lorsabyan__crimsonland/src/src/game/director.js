// Decides what shows up, where and when. Survival escalates forever; Rush is pure kill-rate;
// Missions follow a script and end when the last wave is dead.
import { ARENA } from '../config.js';
import { rand, irand, pick, TAU, clamp, weighted, chance } from '../core/util.js';

const SURVIVAL = [
  { id: 'shambler', from: 0, w: 10 },
  { id: 'skitter', from: 12, w: 8 },
  { id: 'ripper', from: 60, w: 5 },
  { id: 'burster', from: 95, w: 3 },
  { id: 'spitter', from: 115, w: 2.2 },
  { id: 'brute', from: 140, w: 0.9 },
  { id: 'nest', from: 170, w: 0.09 },
  { id: 'brood', from: 210, w: 0.16 },
];
const SWARMS = ['ring', 'sides', 'corners', 'edge'];
const ELITE = { elite: true, hpMul: 3.5, size: 1.34, speedMul: 1.08 };

export class Director {
  constructor(game) { this.game = game; this.reset('survival'); }

  reset(mode, mission = null) {
    this.mode = mode; this.mission = mission;
    this.t = 0; this.acc = 0; this.nextSwarm = 20; this.nextBoss = 240; this.wave = 0; this.hpScale = 1; this.dmgScale = 1; this.complete = false;
  }

  update(dt) {
    this.t += dt;
    if (this.mode === 'survival') this.survival(dt);
    else if (this.mode === 'rush') this.rush(dt);
    else if (this.mode === 'typing') this.typing(dt);
    else this.scripted();
  }

  typing(dt) {
    const g = this.game, t = this.t;
    this.acc += Math.min(0.36 + t * 0.0032, 1.5) * dt;
    while (this.acc >= 1) {
      this.acc -= 1;
      if (g.typing.words.size >= 24) continue;
      const id = t > 70 && chance(0.25) ? 'ripper' : t > 30 && chance(0.35) ? 'skitter' : 'shambler';
      const p = this.edgePoint();
      const i = g.horde.spawn(id, p.x, p.z, { speedMul: id === 'shambler' ? 0.75 : 0.36 });
      if (i >= 0) g.typing.assign(i);
    }
  }

  survival(dt) {
    const g = this.game, t = this.t, h = g.horde;
    // Perks compound, so toughness has to curve upward to keep the late game dangerous.
    this.hpScale = 1 + t / 420 + (t / 420) ** 2;
    this.dmgScale = 1 + t / 600;
    const rate = Math.min(1 + t * 0.014 + g.level * 0.04, 16);
    const cap = Math.min(50 + t * 0.9, 520);
    this.acc += rate * dt;
    while (this.acc >= 1) {
      this.acc -= 1;
      if (h.alive >= cap) continue;
      const pool = SURVIVAL.filter((e) => e.from <= t);
      const e = weighted(pool, (c) => c.w);
      const p = this.edgePoint();
      const elite = e.w >= 0.5 && chance(clamp((t - 90) / 1500, 0, 0.14));
      h.spawn(e.id, p.x, p.z, elite ? ELITE : undefined);
    }
    if (t >= this.nextSwarm) {
      this.nextSwarm = t + rand(20, 28);
      const pool = SURVIVAL.filter((e) => e.w >= 2 && (e.from === 0 || e.from + 30 <= t));
      const e = pick(pool);
      this.pattern(e.id, Math.floor(clamp(6 + t * 0.1, 6, 60)), pick(SWARMS));
      g.ui.toast('Incoming');
    }
    if (t >= this.nextBoss) {
      this.nextBoss += 240;
      const p = this.edgePoint();
      h.spawn('tyrant', p.x, p.z, { hpScale: this.hpScale, size: 1 });
    }
  }

  rush(dt) {
    const g = this.game, t = this.t;
    const rate = Math.min(3.2 + t * 0.14, 24);
    this.acc += rate * dt;
    while (this.acc >= 1) {
      this.acc -= 1;
      if (g.horde.alive >= 420) continue;
      const id = t < 15 ? 'shambler' : weighted(['shambler', 'skitter', 'ripper', 'burster'].map((n, i) => ({ n, w: [7, 6, t > 40 ? 4 : 0, t > 70 ? 2 : 0][i] })), (c) => c.w).n;
      const p = this.edgePoint();
      g.horde.spawn(id, p.x, p.z);
    }
  }

  scripted() {
    const g = this.game, waves = this.mission.waves;
    this.hpScale = 1;
    while (this.wave < waves.length && this.t >= waves[this.wave][0]) {
      const [, id, n, pat] = waves[this.wave++];
      // Big waves swell in the later tiers; single heavies stay as scripted.
      const swell = n >= 5 ? [1, 1, 1, 1.3, 1.9][g.missionTier] : 1;
      this.pattern(id, Math.round(n * swell), pat);
    }
    if (this.wave >= waves.length && g.horde.alive === 0 && !this.complete && this.t > 1) {
      this.complete = true;
      g.victory();
    }
  }

  get progress() {
    if (this.mode !== 'mission') return 0;
    return this.wave / this.mission.waves.length;
  }

  // A point just outside the view, on a random or chosen side.
  edgePoint(side = irand(0, 3)) {
    const { stage } = this.game, f = stage.focus;
    const m = 3, w = stage.viewHalfW + m, hh = stage.viewHalfH + m;
    let x = f.x, z = f.z;
    if (side === 0) { x += rand(-w, w); z -= hh; } else if (side === 1) { x += rand(-w, w); z += hh; } else if (side === 2) { x -= w; z += rand(-hh, hh); } else { x += w; z += rand(-hh, hh); }
    const lim = ARENA + 10;
    return { x: clamp(x, -lim, lim), z: clamp(z, -lim, lim) };
  }

  pattern(id, n, pat) {
    const g = this.game, h = g.horde, p = g.player;
    const add = (x, z) => h.spawn(id, clamp(x, -ARENA - 10, ARENA + 10), clamp(z, -ARENA - 10, ARENA + 10));
    const R = Math.max(this.game.stage.viewHalfW, this.game.stage.viewHalfH) + 3;
    if (pat === 'ring') {
      const off = rand(TAU);
      for (let i = 0; i < n; i++) { const a = off + (i / n) * TAU; add(p.x + Math.cos(a) * R, p.z + Math.sin(a) * R); }
    } else if (pat === 'sides') {
      const s = irand(0, 1);
      for (let i = 0; i < n; i++) { const e = this.edgePoint(s * 2 + (i % 2)); add(e.x + rand(-1, 1), e.z + rand(-1, 1)); }
    } else if (pat === 'corners') {
      for (let i = 0; i < n; i++) {
        const sx = i & 1 ? 1 : -1, sz = i & 2 ? 1 : -1;
        add(p.x + sx * (R + rand(0, 3)), p.z + sz * (R * 0.7 + rand(0, 3)));
      }
    } else if (pat === 'nests') {
      for (let i = 0; i < n; i++) {
        const a = (i / n) * TAU + rand(0.3), d = rand(ARENA * 0.45, ARENA * 0.8);
        h.spawn(id, Math.cos(a) * d, Math.sin(a) * d, { emerge: true });
      }
    } else {
      const s = irand(0, 3), e = this.edgePoint(s);
      for (let i = 0; i < n; i++) add(e.x + rand(-5, 5), e.z + rand(-5, 5));
    }
  }

  // Highest weapon tier currently allowed to drop.
  maxWeaponTier() {
    const t = this.mode === 'mission' ? 60 + this.game.missionTier * 60 : this.t;
    return 1 + Math.floor(t / 55);
  }
}
