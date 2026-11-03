import { ARENA } from '../config.js';
import { WEAPONS } from '../data/weapons.js';
import { GUN_MUZZLE, GUN_X } from '../gfx/hero.js';
import { STAMP } from '../gfx/textures.js';
import { clamp, damp, rand, wrapAngle, chance } from '../core/util.js';

const baseMods = () => ({
  damage: 1, fireRate: 1, reload: 1, clip: 1, spread: 1, speed: 1, xp: 1, armor: 1, dodge: 0, bulletSpeed: 1, bonusTime: 1,
  drops: 1, regen: 0, fire: 1, ion: 1, chain: 0, timeScale: 1, perkChoices: 4, magnet: 0, bounce: 0, crit: 0, volatile: 0,
  poison: false, gorgon: false, pyrokin: false, cough: false, fuse: false, holster: false, plantedReload: false, frantic: false,
  nova: false, bloodRounds: false, xpRounds: false, marathon: false, reach: false, unstoppable: false, melee: false, aura: 0,
  plague: false, lastWord: false, dugIn: false, staticCharge: false, oneLife: false,
});

export class Player {
  constructor(game) { this.game = game; this.reset(WEAPONS.pistol); }

  reset(weapon) {
    Object.assign(this, {
      x: 0, z: 0, vx: 0, vz: 0, aimX: 0, aimZ: 1, aimYaw: 0, legYaw: 0, hp: 100, maxHp: 100, moveAmt: 0, phase: 0,
      ammo: 0, reloadT: 0, reloadLen: 1, cooldown: 0, spread: 0, kick: 0, flash: 0, deadT: 0, alt: null, stillT: 0, runT: 0,
      slowT: 0, stepT: 0, wetFeet: 0, footSide: 0, hurtCool: 0, cookT: 0, chargeT: 0, fuseT: 8, coughT: 3, hurtPulse: 0,
    });
    this.mods = baseMods();
    this.weapon = weapon;
    this.refill();
  }

  get dead() { return this.deadT > 0; }
  get clip() { return Math.ceil(this.weapon.clip * this.mods.clip); }
  get reloading() { return this.reloadT > 0; }

  refill() { this.ammo = this.clip; this.reloadT = 0; }

  giveWeapon(id) {
    const w = WEAPONS[id];
    if (this.mods.holster && !this.alt && w !== this.weapon) this.alt = { weapon: this.weapon, ammo: this.ammo };
    this.weapon = w;
    this.refill();
    this.game.ui.toast(w.name);
  }

  swap() {
    if (!this.alt) return;
    const a = this.alt;
    this.alt = { weapon: this.weapon, ammo: this.ammo };
    this.weapon = a.weapon; this.ammo = a.ammo; this.reloadT = 0;
    this.game.audio.play('reload', { vol: 0.5 });
  }

  startReload() {
    if (this.reloadT > 0 || this.ammo >= this.clip) return;
    this.reloadLen = this.weapon.reload * this.mods.reload;
    this.reloadT = this.reloadLen;
    this.game.audio.play('reload', { vol: 0.4 });
  }

  setMaxHp(v) { this.maxHp = Math.max(10, Math.round(v)); this.hp = Math.min(this.hp, this.maxHp); }
  heal(v) { this.hp = Math.min(this.maxHp, this.hp + v); this.game.ui.floatText(this.x, this.z, `+${Math.round(v)}`, '#ff8d8d'); }

  hurt(dmg, fromX, fromZ) {
    const g = this.game;
    if (this.dead || g.timers.shield > 0 || g.timers.deathClock > 0 || g.attract) return;
    // Mercy frames: a swarm arriving together must not land every first hit in one instant.
    if (this.hurtCool > 0) return;
    const m = this.mods;
    if (chance(m.dodge)) { g.ui.floatText(this.x, this.z, 'dodge', '#cfe9ff'); return; }
    if (m.oneLife) { if (chance(0.1)) this.kill(); return; }
    this.hp -= dmg * m.armor;
    this.flash = 1;
    this.hurtPulse = 1;
    this.hurtCool = 0.28;
    if (!m.unstoppable) this.slowT = 0.18;
    const dx = this.x - fromX, dz = this.z - fromZ, l = Math.sqrt(dx * dx + dz * dz) || 1;
    if (!m.unstoppable) { this.vx += (dx / l) * 8; this.vz += (dz / l) * 8; }
    g.fx.hit(this.x, this.z, dx / l, dz / l, g.fx.bloodRed, 0.7);
    g.stage.shake(0.26);
    g.audio.play('hurt', { rate: rand(0.9, 1.1) });
    if (this.hp <= 0) this.kill();
  }

  kill() {
    if (this.dead) return;
    const g = this.game;
    this.hp = 0;
    this.deadT = 0.0001;
    g.fx.death(this.x, this.z, 0, 1, g.fx.bloodRed, 1.3, 6);
    g.stage.shake(0.6);
    g.audio.play('death');
    if (this.mods.lastWord) g.nuke(this.x, this.z);
  }

  update(dt, input) {
    const g = this.game, m = this.mods;
    this.flash = Math.max(0, this.flash - dt * 7);
    this.hurtPulse = Math.max(0, this.hurtPulse - dt * 1.7);
    this.kick = damp(this.kick, 0, 20, dt);
    if (this.dead) { this.deadT += dt; this.moveAmt = 0; return; }
    this.hurtCool -= dt;
    this.slowT -= dt;

    // Movement: a little inertia, so strafing around a crowd feels physical.
    let mx = input.moveX, mz = input.moveZ;
    const ml = Math.sqrt(mx * mx + mz * mz);
    if (ml > 1) { mx /= ml; mz /= ml; }
    const moving = ml > 0.1;
    this.runT = moving ? this.runT + dt : Math.max(0, this.runT - dt * 3);
    this.stillT = moving ? 0 : this.stillT + dt;
    let speed = 7.6 * m.speed * (this.weapon.slow ?? 1);
    if (g.timers.speed > 0) speed *= 1.75;
    if (m.marathon) speed *= 1 + clamp(this.runT / 5, 0, 1) * 0.6;
    if (this.slowT > 0) speed *= 0.72;
    const accel = 15;
    this.vx = damp(this.vx, mx * speed, accel, dt);
    this.vz = damp(this.vz, mz * speed, accel, dt);
    this.x = clamp(this.x + this.vx * dt, -ARENA, ARENA);
    this.z = clamp(this.z + this.vz * dt, -ARENA, ARENA);
    const vel = Math.sqrt(this.vx * this.vx + this.vz * this.vz);
    this.moveAmt = damp(this.moveAmt, clamp(vel / 6, 0, 1), 14, dt);
    // Moving against the aim: keep the feet under the gun and run the cycle backwards.
    const heading = Math.atan2(this.vx, this.vz), back = vel > 0.5 && Math.abs(wrapAngle(heading - this.aimYaw)) > 1.85;
    this.phase += vel * 1.05 * dt * (back ? -1 : 1);
    if (vel > 0.5) {
      const want = back ? heading + Math.PI : heading;
      this.legYaw += wrapAngle(want - this.legYaw) * Math.min(1, dt * 14);
      this.steps(dt, vel);
    }

    // Aim
    const ax = input.aimX - this.x, az = input.aimZ - this.z, al = Math.sqrt(ax * ax + az * az);
    if (al > 0.2) { this.aimX = ax / al; this.aimZ = az / al; }
    this.aimYaw = Math.atan2(this.aimX, this.aimZ);
    if (!moving) this.legYaw += wrapAngle(this.aimYaw - this.legYaw) * Math.min(1, dt * 7);

    // Weapon
    const w = this.weapon;
    this.cooldown -= dt;
    this.spread = Math.max(0, this.spread - dt * (0.28 + this.spread * 1.4));
    if (input.reload) this.startReload();
    if (input.swap) this.swap();
    if (this.reloadT > 0) {
      let rate = 1;
      if (m.plantedReload && this.stillT > 0.15) rate = 3;
      if (m.frantic && input.firePressed) this.reloadT -= this.reloadLen * 0.12;
      if (g.timers.overdrive > 0) rate *= 3;
      this.reloadT -= dt * rate;
      if (this.reloadT <= 0) {
        this.refill();
        g.audio.play('click', { vol: 0.5, rate: 1.4 });
        if (m.nova) g.shots.ring(this.x, this.z, 16, 'bullet', 30);
      }
    }
    const canFire = this.reloadT <= 0 || m.bloodRounds || m.xpRounds;
    if (input.fire && this.cooldown <= 0 && canFire) {
      if (this.ammo > 0 || this.reloadT > 0) this.fire(w);
      else this.startReload();
    }
    if (!input.fire && this.ammo <= 0) this.startReload();

    if (m.regen > 0) this.hp = Math.min(this.maxHp, this.hp + m.regen * dt);
    this.perkTick(dt, input);
  }

  steps(dt, vel) {
    const g = this.game;
    this.stepT -= vel * dt;
    if (this.stepT > 0) return;
    this.stepT = 1.15;
    this.footSide ^= 1;
    if (g.decals.bloodAt(this.x, this.z) > 0.35) this.wetFeet = 12;
    if (this.wetFeet > 0) {
      const s = this.footSide ? 0.17 : -0.17;
      const c = Math.cos(this.legYaw), n = Math.sin(this.legYaw);
      g.decals.stamp(this.footSide ? STAMP.footR : STAMP.footL, this.x + c * s, this.z - n * s, 0.52, 0.52, -this.legYaw, 0.1, 0.003, 0.006, Math.min(0.9, this.wetFeet / 9));
      this.wetFeet--;
    }
  }

  fire(w) {
    const g = this.game, m = this.mods;
    const drive = g.timers.overdrive > 0 ? 1.6 : 1;
    this.cooldown = 1 / (w.rate * m.fireRate * drive);
    const usesReserve = this.reloadT > 0;
    if (usesReserve) {
      if (m.bloodRounds) { this.hp -= 0.8; if (this.hp <= 0) { this.kill(); return; } } else if (g.score > 1) g.score = Math.max(0, g.score - 6);
    } else {
      this.ammo--;
    }
    const pellets = w.pellets ?? 1;
    const spread = (w.spread + this.spread) * m.spread;
    const muzzle = GUN_MUZZLE[w.cls] + 0.05;
    const fx0 = this.x + this.aimX * muzzle + this.aimZ * GUN_X, fz0 = this.z + this.aimZ * muzzle - this.aimX * GUN_X;
    let dmg = w.dmg * m.damage;
    if (m.dugIn && this.stillT > 1) dmg *= 1.6;
    if (w.fire) dmg *= m.fire;
    if (w.kind === 'ion') dmg *= m.ion;
    const aim = Math.atan2(this.aimZ, this.aimX);
    for (let i = 0; i < pellets; i++) {
      const fan = w.fan ? (i - (pellets - 1) / 2) * w.fan : 0;
      const a = aim + fan + rand(-spread, spread);
      g.shots.fire(w, fx0, fz0, Math.cos(a), Math.sin(a), dmg);
    }
    g.stats.fired += pellets;
    this.spread = Math.min(0.32, this.spread + w.gain);
    this.kick = Math.min(0.32, this.kick + 0.05 + (w.shake ?? 0) * 0.65);
    if (w.kind !== 'flame' && w.kind !== 'mine') g.fx.muzzle(fx0, 1.12, fz0, this.aimX, this.aimZ, w.col, w.power ?? 1, w.rate);
    if (!w.noShell) g.fx.shell(this.x + this.aimX * 0.4, 1.15, this.z + this.aimZ * 0.4, this.aimX, this.aimZ);
    g.stage.shake(w.shake);
    g.audio.play(w.snd, { rate: rand(0.95, 1.05), x: 0 });
    if (this.ammo <= 0 && !usesReserve) this.startReload();
  }

  perkTick(dt, input) {
    const g = this.game, m = this.mods;
    if (m.cough) {
      this.coughT -= dt;
      if (this.coughT <= 0) {
        this.coughT = 3;
        g.shots.spawn('fireball', this.x, this.z, this.aimX * 20, this.aimZ * 20, 60 * m.fire, { rad: 0.7, life: 1.4, splash: 3 });
        g.audio.play('flame', { vol: 0.7 });
      }
    }
    if (m.fuse) {
      this.fuseT -= dt;
      if (this.fuseT <= 0) { this.fuseT = 8; g.shots.ring(this.x, this.z, 22, 'plasma', 34); g.audio.play('plasma', { rate: 0.7 }); }
    }
    if (m.staticCharge && this.stillT > 0.25) {
      this.chargeT += dt;
      if (this.chargeT >= 3) { this.chargeT = 0; g.shots.ring(this.x, this.z, 14, 'ion', 60); g.audio.play('ion', { rate: 0.7 }); }
    } else this.chargeT = Math.max(0, this.chargeT - dt);
    if (m.aura) {
      this.cookT -= dt;
      if (this.cookT <= 0) { this.cookT = 0.25; g.horde.aura(this.x, this.z, 6, 14 * m.aura * 0.25); g.fx.ring(this.x, this.z, 3, 0.04, 0.16, 0.05, 0.5); }
    }
    if (m.gorgon || m.pyrokin) g.horde.underCursor(input.aimX, input.aimZ, m.gorgon, m.pyrokin, dt);
  }

  // Lights follow the player; called once per rendered frame.
  syncLights() {
    const { stage } = this.game;
    stage.lantern.position.set(this.x, 6, this.z);
    stage.lantern.intensity = this.dead ? 0 : stage.lanternPower * 2.4;
    stage.torch.position.set(this.x + this.aimX * 0.6, 2.4, this.z + this.aimZ * 0.6);
    stage.torch.target.position.set(this.x + this.aimX * 10, 0, this.z + this.aimZ * 10);
    stage.torch.intensity = this.dead ? 0 : stage.lanternPower * 4;
  }
}

