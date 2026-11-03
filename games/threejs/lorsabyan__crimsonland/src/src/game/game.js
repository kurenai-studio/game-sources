// A single run: owns the simulation objects and the order they update in.
import { Horde } from './horde.js';
import { Shots } from './shots.js';
import { Player } from './player.js';
import { Drops } from './drops.js';
import { Director } from './director.js';
import { Bot } from './bot.js';
import { Typing } from './typing.js';
import { CAM } from '../config.js';
import { WEAPONS } from '../data/weapons.js';
import { BIOMES, BIOME_LIST } from '../data/biomes.js';
import { rollPerks } from '../data/perks.js';
import { unlocked } from '../data/unlocks.js';
import { damp, clamp, pick } from '../core/util.js';

const levelCost = (level) => Math.round(90 + 55 * Math.pow(level, 1.55));

export class Game {
  constructor(deps) {
    Object.assign(this, deps);   // stage, decals, world, fx, hero, layers, audio, input, ui, profile
    this.player = new Player(this);
    this.shots = new Shots(this);
    this.director = new Director(this);
    this.horde = new Horde(this);
    this.drops = new Drops(this);
    this.bot = new Bot(this);
    this.typing = new Typing(this);
    this.timers = {};
    this.timerMax = {};
    this.phase = 'idle';      // idle | play | perk | paused | over
    this.timeScale = 1;
    this.attract = true;
    this.time = 0;
    this.fx.onClink = () => { if (Math.random() < 0.3) this.audio.play('casing', { vol: 0.14, rate: 0.9 + Math.random() * 0.4 }); };
  }

  start({ mode, mission = null, biome = null, attract = false }) {
    this.mode = mode;
    this.mission = mission;
    this.hasPerks = mode === 'survival' || mode === 'mission';
    this.arsenal = unlocked(attract ? null : this.profile);   // the menu's bot shows off everything
    this.typing.reset();
    this.input.onType = mode === 'typing' && !attract ? (k) => { if (this.phase === 'play') this.typing.key(k); } : null;
    this.attract = attract;
    this.audio.silent = attract;   // the menu's bot plays without sound effects
    this.missionTier = mission ? Number(mission.id[0]) : 0;
    const b = BIOMES[mission?.biome ?? biome] ?? pick(BIOME_LIST);
    if (this.biome !== b) { this.biome = b; this.world.setBiome(b); }
    this.decals.clear();
    this.fx.clear();
    this.horde.reset();
    this.shots.reset();
    this.drops.reset();
    this.director.reset(mode, mission);
    const startWeapon = mode === 'rush' || mode === 'typing' ? WEAPONS.rifle : WEAPONS[mission?.weapon ?? 'pistol'];
    this.player.reset(startWeapon);
    this.stage.snapCamera(0, 0);
    Object.assign(this, { score: 0, level: 1, levelFrom: 0, levelTo: levelCost(1), pendingPerks: 0, time: 0, hitStop: 0, slow: 1 });
    this.stats = { kills: 0, fired: 0, hit: 0, burned: 0 };
    this.timers = { shield: 0, speed: 0, fire: 0, xp2: 0, reflex: 0, overdrive: 0, deathClock: 0 };
    this.timerMax = { ...this.timers };
    this.owned = new Map();
    this.phase = 'play';
    this.overT = 0;
    // Later campaign tiers assume a veteran: start them with perks in hand.
    const veteran = Math.max(0, this.missionTier - 1);
    if (this.autoplay) for (let i = 0; i < veteran; i++) this.autoPerk();
    else this.pendingPerks = veteran;
  }

  // Scoring ------------------------------------------------------------------------------------
  addScore(v) {
    this.score += v;
    if (!this.hasPerks) return;
    while (this.score >= this.levelTo) this.levelUp();
  }

  levelUp() {
    this.level++;
    this.levelFrom = this.levelTo;
    this.levelTo += levelCost(this.level);
    this.pendingPerks++;
    this.fx.ring(this.player.x, this.player.z, 5, 3, 2.2, 0.9, 0.7);
    this.audio.play('levelup');
    if (this.attract || this.autoplay) this.autoPerk();
    else this.ui.toast(`Level ${this.level}`, '#ffd76a');
  }

  addLevels(n) {
    for (let i = 0; i < n; i++) { this.score = this.levelTo; this.levelUp(); }
  }

  onKill(def, x, z, burned, xpMul, elite) {
    const mult = (this.timers.xp2 > 0 ? 2 : 1) * this.player.mods.xp * xpMul;
    this.stats.kills++;
    if (burned) this.stats.burned++;
    this.addScore(Math.round(def.xp * mult));
    if (elite) this.drops.spawn(this.drops.pickBonus(), x, z);
    else this.drops.maybeDrop(x, z, def.xp);
    if (def.boss) this.addScore(1500);
  }

  // Perks --------------------------------------------------------------------------------------
  autoPerk() {
    const list = rollPerks(this.owned, 4, this.arsenal.perks).filter((p) => p.tag !== 'gamble');
    if (list.length) this.takePerk(list[0]);
    this.pendingPerks = 0;
  }

  openPerks() {
    if (this.phase !== 'play' || this.pendingPerks <= 0) return;
    const list = rollPerks(this.owned, this.player.mods.perkChoices, this.arsenal.perks);
    if (!list.length) { this.pendingPerks = 0; return; }
    this.phase = 'perk';
    this.ui.showPerks(list, this.level);
  }

  takePerk(perk) {
    this.owned.set(perk.id, (this.owned.get(perk.id) ?? 0) + 1);
    perk.apply(this);
  }

  choosePerk(perk) {
    this.takePerk(perk);
    this.pendingPerks--;
    this.audio.play('perk');
    this.phase = 'play';
    this.ui.hidePerks();
    if (this.pendingPerks > 0) this.openPerks();
  }

  // Screen-wide bonuses ------------------------------------------------------------------------
  nuke(x, z) {
    const h = this.horde;
    this.shots.explode(x, z, 9, 900, { kind: 'fire', knock: 26 });
    for (let k = 0; k < h.count; k++) {
      const i = h.list[k];
      if (h.dead[i] > 0) continue;
      if (Math.abs(h.x[i] - x) < this.stage.viewHalfW + 3 && Math.abs(h.z[i] - z) < this.stage.viewHalfH + 3) {
        h.damage(i, 500, 0, 0, 0, { explosive: true, quiet: true });
      }
    }
    this.nukeFlash();
    this.stage.shockwave(x, z, 0.055);
    this.audio.play('nuke');
  }

  nukeFlash() { this.stage.u.flash.value = 1.1; this.stage.shake(0.8); }

  freezeAll(sec) {
    this.horde.freezeAll(sec);
    this.fx.ring(this.player.x, this.player.z, 22, 1.2, 2.6, 4.5, 0.7);
    this.audio.play('freeze');
  }

  fiftyFifty() {
    const h = this.horde;
    for (let k = 0; k < h.count; k++) {
      const i = h.list[k];
      if (h.dead[i] === 0 && !h.defs[h.type[i]].boss && Math.random() < 0.5) h.damage(i, 1e6, 0, 0, 0, { quiet: true });
    }
    this.stage.u.flash.value = 0.5;
    this.audio.play('nuke', { vol: 0.5 });
  }

  // Frame --------------------------------------------------------------------------------------
  update(realDt) {
    const running = this.phase === 'play' || this.phase === 'over';
    const t = this.timers, p = this.player, input = this.input;
    if (this.mode === 'typing' && !this.attract) this.typing.drive(input);
    else if (this.attract || this.autoplay) this.bot.drive(input, realDt);
    else input.poll(this);
    if (running) {
      let scale = p.mods.timeScale;
      if (t.reflex > 0) scale *= 0.42;
      if (p.dead) scale *= 0.45;
      this.slow = damp(this.slow, scale, 9, realDt);
      const dt = realDt * this.slow;
      this.time += dt;
      for (const k in t) {
        if (t[k] <= 0) continue;
        t[k] -= realDt;
        if (t[k] <= 0) { t[k] = 0; if (k === 'deathClock') p.kill(); }
      }
      p.update(dt, input);
      this.horde.update(dt);
      this.shots.update(dt);
      this.drops.update(dt, input);
      if (!p.dead) this.director.update(dt);
      this.fx.update(dt);
      if (p.dead && this.phase === 'play') {
        this.phase = 'over';
        this.overT = 0;
      }
      if (this.phase === 'over') {
        this.overT += realDt;
        if (this.overT > 2.1) this.finish();
      }
      if (this.attract && this.time > 200) this.start({ mode: 'survival', attract: true });
    } else {
      this.fx.update(0);
    }
    if (input.perkKey) this.openPerks();
    if (input.pauseKey && !this.attract) this.togglePause();
    input.endFrame();
    this.syncView(realDt);
    this.ui.update(this);
  }

  syncView(realDt) {
    const p = this.player, s = this.stage, u = s.u;
    this.horde.render();
    this.hero.update(p);
    this.shots.draw();
    this.drops.draw();
    if (this.timers.shield > 0) {
      this.fx.glow.draw(p.x, 1, p.z, 3.1, 0, 0, 0, 0.5, 1.1, 2, 0.7, 11);
    }
    this.fx.commit();
    // Words must hold still to be read, so Type to Kill turns off aim look-ahead.
    const look = this.mode === 'typing' ? 0 : CAM.look;
    const lookX = clamp((this.input.aimX - p.x) * look, -CAM.lookMax, CAM.lookMax);
    const lookZ = clamp((this.input.aimZ - p.z) * look, -CAM.lookMax, CAM.lookMax);
    s.updateCamera(realDt, p.x, p.z, lookX, lookZ);
    p.syncLights();

    const low = clamp(1 - p.hp / (p.maxHp * 0.35), 0, 1);
    const beat = 0.65 + Math.sin(performance.now() * 0.006) * 0.35;
    u.hurt.value = this.attract ? 0 : Math.max(p.hurtPulse * 0.8, low * beat * 0.5, p.dead ? 0.7 : 0);
    u.desat.value = damp(u.desat.value, p.dead ? 0.7 : this.timers.reflex > 0 ? 0.35 : 0, 6, realDt);
    u.aberration.value = 0.0007 + p.hurtPulse * 0.01;
    u.flash.value = damp(u.flash.value, 0, 5, realDt);
    this.audio.setIntensity(clamp(this.horde.alive / 110, 0, 1));
    this.decals.flush();
  }

  togglePause() {
    if (this.phase === 'play') { this.phase = 'paused'; this.ui.showPause(true); this.audio.duck(true); } else if (this.phase === 'paused') { this.phase = 'play'; this.ui.showPause(false); this.audio.duck(false); }
  }

  finish() {
    if (this.attract) { this.start({ mode: 'survival', attract: true }); return; }
    this.overT = -1e9;
    this.ui.gameOver(this, false);
  }

  victory() {
    this.phase = 'over';
    this.overT = -1e9;
    this.audio.play('levelup', { rate: 0.75 });
    this.ui.gameOver(this, true);
  }
}
