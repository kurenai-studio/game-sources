import { Fighter, GROUND, HALF_W, emptyInput, WORLD, GRAVITY } from './fighter.js';
import { MOVES, comboScale, SUPER } from './moves.js';

export const W = 960, H = 540, FLOOR_Y = 470;   // logical screen size, floor line on screen
export const LEFT = 40, RIGHT = 920;            // arena walls
export const ROUND_SECONDS = 60, WINS_NEEDED = 2, FPS = 60;

const COMBO_WORDS = ['', '', 'DHISHUM!', 'BHAUKAAL!', 'JHAKAAS!', 'OP BOLTE!', 'KHATAM!', 'GAME OVER BETA!'];
const MEME_WORDS = ['BONK!', 'OOF!', 'EMOTIONAL DAMAGE!', 'MAA KASAM!', 'AYYO!', 'NOOB!', 'SED LYF', 'KYA SCENE HAI!', 'BRUH', 'OHHH NOOO'];

export const cowX = (e) => (e.dir === 1 ? -160 + e.t * 3 : W + 160 - e.t * 3);

// tiny seeded RNG so tests and CPU matches can be repeated exactly
export function rng(seed = 1) {
  let s = seed >>> 0 || 1;
  return () => { s ^= s << 13; s >>>= 0; s ^= s >> 17; s ^= s << 5; s >>>= 0; return (s >>> 0) / 4294967296; };
}

// Effects are plain data; the renderer draws them, tests can ignore them.
class Fx {
  constructor(game) { this.g = game; this.parts = []; this.texts = []; this.rings = []; }
  spark(x, y, blocked = false, big = false) {
    const n = blocked ? 8 : big ? 26 : 14, r = this.g.rand;
    for (let i = 0; i < n; i++) {
      const a = r() * Math.PI * 2, sp = (blocked ? 3 : 5) + r() * (big ? 9 : 6);
      this.parts.push({ x, y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - 1, life: 18 + r() * 12, max: 30, color: blocked ? '#9fd8ff' : (r() < 0.5 ? '#ffe28a' : '#ff8a3c'), size: 3 + r() * 4, g: 0.25 });
    }
    this.rings.push({ x, y, r: 6, max: big ? 70 : 40, life: 14, color: blocked ? '#9fd8ff' : '#fff2c0' });
  }
  dust(x, s = 1) {
    const r = this.g.rand;
    for (let i = 0; i < 10 * s; i++) this.parts.push({ x: x + (r() - 0.5) * 40, y: -4, vx: (r() - 0.5) * 4, vy: -r() * 2.5, life: 24 + r() * 16, max: 40, color: '#b7a58a', size: 6 + r() * 8, g: -0.02, soft: true });
  }
  confetti() {
    const r = this.g.rand, cols = ['#e3b65a', '#ff3b6b', '#29d3ff', '#7bd23c', '#ffffff', '#ff8a1f'];
    for (let i = 0; i < 160; i++) this.parts.push({ x: r() * W - 0, y: -520 - r() * 200, vx: (r() - 0.5) * 3, vy: 1 + r() * 3, life: 160 + r() * 80, max: 240, color: cols[i % cols.length], size: 5 + r() * 5, g: 0.04, confetti: true, rot: r() * 6 });
  }
  beep(x, y) {
    this.texts.push({ x, y, text: '*#@!$%', color: '#ff3b3b', life: 40, max: 40, size: 34, vy: -1.2, box: '#111' });
    this.rings.push({ x, y, r: 10, max: 120, life: 18, color: '#ff3b3b' });
  }
  popup(x, y, text, color = '#fff', size = 30) { this.texts.push({ x, y, text, color, life: 50, max: 50, size, vy: -1.4 }); }
  update() {
    for (const p of this.parts) { p.x += p.vx; p.y += p.vy; p.vy += p.g; p.life--; if (p.confetti) { p.vx *= 0.99; p.rot += 0.2; } }
    this.parts = this.parts.filter((p) => p.life > 0);
    for (const t of this.texts) { t.y += t.vy; t.life--; }
    this.texts = this.texts.filter((t) => t.life > 0);
    for (const r of this.rings) { r.r += (r.max - r.r) * 0.3; r.life--; }
    this.rings = this.rings.filter((r) => r.life > 0);
  }
}

export class Game {
  constructor({ p1, p2, stage = 'tapri', seed = Date.now() & 0xffff, events = true, meme = false } = {}) {
    this.meme = meme;
    this.rand = rng(seed);
    this.stage = stage;
    this.f = [new Fighter(0, p1), new Fighter(1, p2)];
    this.fx = new Fx(this);
    this.wins = [0, 0]; this.round = 1; this.history = [];
    this.events = events;
    this.sounds = [];        // queued sound names, drained by the audio layer
    this.callouts = [];      // big centre/side texts
    this.onSound = null;
    this.frame = 0;
    this.startRound();
  }

  audio(name) { this.sounds.push(name); if (this.onSound) this.onSound(name); }
  shake(n) { this.shakeAmt = Math.max(this.shakeAmt || 0, n); }
  callout(side, text, color = '#e3b65a', big = false) {
    this.callouts.push({ side, text, color, big, life: big ? 90 : 55, max: big ? 90 : 55 });
  }
  banner(text, sub = '', life = 70, color = '#e3b65a') { this.bannerData = { text, sub, life, max: life, color }; }

  startRound() {
    const [a, b] = this.f;
    a.reset(330); b.reset(630);
    a.force('intro'); b.force('intro');
    this.timer = ROUND_SECONDS * FPS;
    this.phase = 'intro'; this.phaseT = 0;
    this.projectiles = []; this.pending = [];
    this.freeze = 0; this.freezeBy = null; this.slowmo = 0; this.bruhT = 0;
    this.shakeAmt = 0; this.flashT = 0; this.flashColor = '#fff';
    WORLD.gravity = GRAVITY; this.trainT = 0; this.nextTrain = 60 * 9;
    this.event = null; this.nextEvent = 60 * (8 + Math.floor(this.rand() * 8));
    this.roundResult = null;
    this.banner(this.isFinalRound ? 'FINAL ROUND' : 'ROUND ' + this.round, '', 60);
    this.audio('round');
  }
  get isFinalRound() { return this.wins[0] === WINS_NEEDED - 1 && this.wins[1] === WINS_NEEDED - 1; }
  get winner() {
    if (this.wins[0] >= WINS_NEEDED && this.wins[0] > this.wins[1]) return 0;
    if (this.wins[1] >= WINS_NEEDED && this.wins[1] > this.wins[0]) return 1;
    return null;
  }

  superFreeze(f) {
    this.freeze = SUPER.freeze; this.freezeBy = f;
    this.callout(f.side, 'JUGAAD!', f.char.superColor);
    this.audio('super'); this.shake(3);
  }
  bruh() { this.bruhT = 50; this.audio('bruh'); }

  // ---------- one fixed 1/60 s step ----------
  step(inputs = [emptyInput(), emptyInput()]) {
    this.frame++;
    this.fx.update();
    for (const c of this.callouts) c.life--; this.callouts = this.callouts.filter((c) => c.life > 0);
    if (this.bannerData && --this.bannerData.life <= 0) this.bannerData = null;
    if (this.shakeAmt > 0) this.shakeAmt = Math.max(0, this.shakeAmt - 0.5);
    if (this.flashT > 0) this.flashT--;
    if (this.bruhT > 0) { this.bruhT--; return; }               // freeze-frame "bruh" moment
    if (this.slowmo > 0) { this.slowmo--; if (this.slowmo % 3 !== 0) return; }  // KO slow motion
    if (this.event && this.event.type === 'lag' && this.phase === 'fight') { this.event.t++; if (this.event.t >= this.event.len) this.event = null; else if (this.rand() < 0.45) return; }

    const [a, b] = this.f;
    this.phaseT++;
    if (this.phase === 'intro') {
      if (this.phaseT === 62) { this.banner('LADO!', '', 40, '#ffffff'); this.audio('fight'); }
      if (this.phaseT >= 80) { this.phase = 'fight'; a.force('idle'); b.force('idle'); }
    }
    const live = this.phase === 'fight';
    const inA = live ? inputs[0] : emptyInput(), inB = live ? inputs[1] : emptyInput();

    if (this.freeze > 0) {               // super flash: only the super user moves
      this.freeze--;
      this.freezeBy.update(this.freezeBy === a ? inA : inB, this.freezeBy === a ? b : a, this);
      return;
    }

    a.update(inA, b, this); b.update(inB, a, this);
    this.updateFacing(a, b); this.updateFacing(b, a);

    // melee hits (both can trade)
    const hA = this.checkHit(a, b), hB = this.checkHit(b, a);
    if (hA && hB && hA.grab !== hB.grab) { if (hA.grab) this.resolveHit(b, a, hB.move); else this.resolveHit(a, b, hA.move); }
    else if (hA && hB && hA.grab) { this.resolveHit(a, b, hA.move); }       // both grab: left player wins the scramble
    else { if (hA) this.resolveHit(a, b, hA.move); if (hB) this.resolveHit(b, a, hB.move); }

    this.updateProjectiles();
    this.separate(a, b);
    this.updateEvents();

    if (this.phase === 'fight') {
      this.timer--;
      if (a.hp <= 0 || b.hp <= 0) this.endRound('ko');
      else if (this.timer <= 0) this.endRound('time');
    } else if (this.phase === 'roundEnd') {
      if (this.phaseT === 70 && this.roundResult.winner !== null) this.f[this.roundResult.winner].force('victory');
      if (this.phaseT >= 170) {
        if (this.winner !== null || this.round >= 6) { this.phase = 'over'; this.audio(this.winner === null ? 'ko' : 'win'); }
        else { this.round++; this.startRound(); }
      }
    }
  }

  updateFacing(me, opp) {
    if ((me.actionable || me.state === 'blockstun' || me.state === 'intro') && !me.airborne) {
      const d = opp.x - me.x; if (Math.abs(d) > 4) me.facing = Math.sign(d);
    }
  }

  separate(a, b) {
    for (const f of this.f) f.x = Math.max(LEFT + HALF_W, Math.min(RIGHT - HALF_W, f.x));
    if (a.state === 'grabbed' || b.state === 'grabbed') return;
    if (a.y < -70 || b.y < -70) return;
    const d = b.x - a.x, min = HALF_W * 2;
    if (Math.abs(d) < min) {
      const dir = d === 0 ? a.facing : Math.sign(d), push = (min - Math.abs(d)) / 2;
      a.x -= dir * push; b.x += dir * push;
      // keep both inside walls: if one is pinned, push the other
      for (const [f, o] of [[a, b], [b, a]]) {
        if (f.x < LEFT + HALF_W) { o.x += LEFT + HALF_W - f.x; f.x = LEFT + HALF_W; }
        if (f.x > RIGHT - HALF_W) { o.x -= f.x - (RIGHT - HALF_W); f.x = RIGHT - HALF_W; }
      }
    }
  }

  // Does fighter `att`'s active attack touch `def` this frame?
  checkHit(att, def) {
    if (!att.attackActive || def.invulnerable || def.state === 'grabbed') return null;
    const m = att.attack.move;
    if (!m.reach && !m.grab) return null;
    const dx = (def.x - att.x) * att.facing;
    const reach = m.reach * att.char.reachMul + HALF_W;
    if (dx < -10 || dx > reach) return null;
    if (m.grab) {
      if (def.airborne || def.state === 'hitstun' || def.state === 'launched' || def.state === 'throw') return null;
      return { grab: true, move: m };
    }
    const defUp = -def.y;
    if (m.air) { if (Math.abs(att.y - def.y) > 120) return null; }
    else {
      if (m.h === 'low' && defUp > 20) return null;                  // jump over lows
      if (m.h === 'high' && def.isLow) return null;                   // duck under highs
      if (defUp > (m.antiAir ? 170 : 90)) return null;               // too high in the air
    }
    return { grab: false, move: m };
  }

  resolveHit(att, def, m) {
    if (att.attack) att.attack.contact = true;
    if (m.grab) {
      // grab vs grab startup = tech; otherwise throw starts
      att.beginThrow(def); this.audio('grab');
      return;
    }
    const blocks = def.canBlock && def.holdingBack && (
      m.h === 'low' ? def.isLow : m.h === 'air' ? !def.isLow : true);
    if (blocks) { this.applyBlock(att, def, m, 0); return; }
    if (att.attack) att.attack.hit = true;
    let dmg = Math.round(m.dmg * att.char.dmgMul);
    this.applyDamage(att, def, dmg, { kd: m.kd, launch: m.launch, hs: m.hs, push: m.push, moveId: m.id });
    if (m.special || m.kd) this.callout(att.side, (att.char.moves[m.id] || '') ? att.char.moves[m.id] + '!' : '', att.char.color);
  }

  applyBlock(att, def, m, chip = 0) {
    def.force('blockstun'); def.stun = m.bs || 12; def.attack = null;
    def.pushVx = (m.push || 6) * 0.9 * att.facing;
    if (chip) def.hp = Math.max(1, def.hp - chip);
    att.addMeter(2 * att.char.meterMul); def.addMeter(3 * def.char.meterMul);
    att.hitstop = def.hitstop = 3;
    def.stats.blocks++;
    this.fx.spark(def.x - att.facing * 18, def.y - def.height * 0.6, true);
    this.audio('block');
    // pinned at a wall: attacker gets pushed back instead
    if (def.x <= LEFT + HALF_W + 2 || def.x >= RIGHT - HALF_W - 2) att.pushVx = -(m.push || 6) * 0.6 * att.facing;
  }

  applyDamage(att, def, rawDmg, opts = {}) {
    if (def.hp <= 0) return;
    const scaled = opts.superHit || opts.throwHit ? rawDmg : Math.max(1, Math.round(rawDmg * comboScale(def.comboHits)));
    def.hp = Math.max(0, def.hp - scaled);
    def.comboHits++;
    att.stats.dmgDealt += scaled; att.stats.hits++;
    att.stats.maxCombo = Math.max(att.stats.maxCombo, def.comboHits);
    att.addMeter((scaled * 0.9 + 2) * att.char.meterMul); def.addMeter(scaled * 0.6 * def.char.meterMul);
    def.attack = null; def.crouching = false; def.grabTarget = null;
    const big = opts.kd || scaled >= 12;
    if (def.hp <= 0) {
      def.force('ko'); def.vy = -11; def.vx = att.facing * 6; def.y = Math.min(def.y, -1);
    } else if (opts.kd) {
      def.force('launched'); def.vx = att.facing * (opts.launch?.vx ?? 5); def.vy = opts.launch?.vy ?? -8; def.y = Math.min(def.y, -1);
    } else if (opts.dizzy) {
      def.force('dizzy'); def.stun = opts.dizzy;
    } else if (def.airborne) {
      def.force('launched'); def.vx = att.facing * 3; def.vy = -6;
    } else {
      def.force('hitstun'); def.stun = opts.hs || 18; def.pushVx = (opts.push || 5) * att.facing;
    }
    att.hitstop = def.hitstop = big ? 8 : 5;
    def.flash = 6;
    const hx = def.x - att.facing * 16, hy = def.y - def.height * (opts.low ? 0.25 : 0.62);
    this.fx.spark(hx, hy, false, big);
    this.shake(big ? 7 : 3);
    this.audio(big ? 'heavy' : 'hit');
    if (def.comboHits >= 2) {
      const word = COMBO_WORDS[Math.min(def.comboHits, COMBO_WORDS.length - 1)];
      this.callout(att.side, def.comboHits + ' HITS ' + word, '#e3b65a');
      if (def.comboHits === 3 || def.comboHits === 5) this.audio('crowd');
    } else if (this.rand() < (this.meme ? 0.45 : 0.12)) {
      this.fx.popup(hx, hy - 40, MEME_WORDS[Math.floor(this.rand() * MEME_WORDS.length)], '#ffffff', 26);
    }
  }

  // ---------- specials & supers ----------
  spawnSpecial(f, kind) {
    const dir = f.facing;
    if (kind === 'lol') this.projectiles.push({ type: 'lol', owner: f, x: f.x + dir * 50, y: f.y - 120, vx: 7 * dir, vy: 0, w: 70, h: 44, life: 48, dizzy: 50, dmg: 3, hits: new Set(), small: true });
    if (kind === 'roastwave') this.projectiles.push({ type: 'roastwave', owner: f, x: f.x + dir * 50, y: f.y - 100, vx: 8 * dir, vy: 0, w: 60, h: 90, life: 42, dizzy: 24, dmg: 4, hits: new Set(), small: true });
    this.audio(kind === 'lol' ? 'lol' : 'roast');
  }

  spawnSuper(f) {
    const dir = f.facing, opp = this.f[1 - f.side], P = this.projectiles;
    const base = { owner: f, hits: new Set(), dmg: Math.round(SUPER.dmg * f.char.dmgMul), chip: SUPER.chip, superHit: true, kd: true, life: 200, isSuper: true };
    switch (f.char.superType) {
      case 'chai': P.push({ ...base, type: 'chai', x: f.x + dir * 60, y: -45, vx: 9 * dir, vy: 0, w: 100, h: 90 }); this.audio('splash'); break;
      case 'auto': P.push({ ...base, type: 'auto', x: f.x - dir * 140, y: -60, vx: 13 * dir, vy: 0, w: 150, h: 110, dmg: base.dmg + 2, chip: 8 }); this.audio('horn'); break;
      case 'chappal': P.push({ ...base, type: 'chappal', x: f.x + dir * 50, y: f.y - 110, vx: 13 * dir, vy: 0, w: 46, h: 30, dmg: 13, kd: false, hs: 34, boomerang: true, dir }); this.audio('whoosh'); break;
      case 'headshot': P.push({ ...base, type: 'reticle', x: opp.x, y: -opp.height * 0.88, vx: 0, vy: 0, w: 70, h: 70, life: 60, dmg: 28, chip: 8, target: opp, noTouch: true }); this.audio('lock'); break;
      case 'jelly': P.push({ ...base, type: 'jelly', x: f.x + dir * 70, y: -85, vx: 5 * dir, vy: 0, w: 44, h: 170, life: 100, dmg: 17, wall: true }); this.audio('jelly'); break;
      case 'pans': for (let i = 0; i < 3; i++) this.pending.push({ at: i * 8, p: { ...base, type: 'pan', x: 0, y: -105, vx: 12 * dir, vy: 0, w: 42, h: 42, dmg: 10, kd: i === 2, hs: 26, followOwner: true } }); this.audio('whoosh'); break;
      case 'likes': for (let i = 0; i < 7; i++) this.pending.push({ at: i * 5, p: { ...base, type: 'like', x: 0, offset: (i - 3) * 30, y: -560, vx: 0, vy: 16, w: 44, h: 44, dmg: 5, chip: 1, kd: i === 6, hs: 22, fall: true } }); this.audio('likes'); break;
      case 'flash': {
        this.flashT = 30; this.flashColor = '#ffffff'; this.audio('flash');
        P.push({ ...base, type: 'ringlight', x: f.x + dir * 40, y: -150, vx: 0, vy: 0, w: 0, h: 0, life: 40, noTouch: true });
        const dx = (opp.x - f.x) * dir;
        if (dx > 0 && dx < 340 && !opp.invulnerable && opp.state !== 'grabbed' && -opp.y < 120) {
          this.applyDamage(f, opp, 6, { dizzy: 80, superHit: true });
          this.callout(opp.side, 'ANKHEIN CHAUNDHIYA GAYI!', '#ffffff');
        } else this.bruh();
        break;
      }
      case 'scream':
        P.push({ ...base, type: 'scream', x: f.x + dir * 60, y: -90, vx: 11 * dir, vy: 0, w: 60, h: 170, dmg: 21, chip: 7 });
        this.shake(16); this.audio('scream'); this.fx.popup(f.x, -200, 'YALGAARRR!!', '#ff5a1f', 40); break;
    }
  }

  updateProjectiles() {
    for (const q of this.pending) q.at--;
    for (const q of this.pending.filter((q) => q.at <= 0)) {
      const p = q.p; if (p.fall) p.x = this.f[1 - p.owner.side].x + p.offset;
      if (p.followOwner) { p.x = p.owner.x + p.owner.facing * 50; p.vx = Math.abs(p.vx) * p.owner.facing; }
      this.projectiles.push(p);
    }
    this.pending = this.pending.filter((q) => q.at > 0);

    for (const p of this.projectiles) {
      p.life--; p.age = (p.age || 0) + 1;
      const opp = this.f[1 - p.owner.side];
      if (p.type === 'reticle') {
        if (p.age < 38) { p.x += (opp.x - p.x) * 0.35; p.y = -opp.height * 0.88 + opp.y; }
        if (p.age === 56) {
          const onHead = Math.abs(opp.x - p.x) < 55 && !opp.invulnerable && !opp.isLow && opp.state !== 'grabbed';
          if (onHead) {
            if (opp.canBlock && opp.holdingBack) this.applyBlock(p.owner, opp, { bs: 20, push: 4 }, p.chip);
            else { this.applyDamage(p.owner, opp, p.dmg, { kd: true, launch: { vx: 4, vy: -10 }, superHit: true }); this.callout(p.owner.side, 'HEADSHOT!!', '#e3b65a', true); }
            p.hitAny = true;
          }
          this.audio('shot'); this.flashT = 6; this.flashColor = '#e3b65a'; p.life = 0;
        }
        continue;
      }
      if (p.boomerang) {
        p.vx -= p.dir * 0.42;
        if (!p.back && Math.sign(p.vx) !== p.dir) { p.back = true; p.hits.clear(); p.kd = true; }
        if (p.back && Math.abs(p.x - p.owner.x) < 40) p.life = 0;
        p.spin = (p.spin || 0) + 0.5;
      }
      if (p.type === 'jelly') { if (p.age > 45) p.vx *= 0.85; p.h = Math.min(170, 40 + p.age * 8); }
      if (p.type === 'scream') p.h = Math.min(260, p.h + 3);
      p.x += p.vx; p.y += p.vy;
      if (p.fall && p.y > -20) p.life = 0;
      if (p.x < -200 || p.x > W + 200) p.life = 0;
      if (p.noTouch) continue;
      // hit the opponent?
      if (!p.hits.has(opp.side) && !opp.invulnerable && opp.state !== 'grabbed') {
        const top = opp.y - opp.height, bottom = opp.y;
        if (Math.abs(opp.x - p.x) < p.w / 2 + HALF_W && p.y + p.h / 2 > top && p.y - p.h / 2 < bottom) {
          p.hits.add(opp.side); p.hitAny = true;
          if (opp.canBlock && opp.holdingBack) this.applyBlock(p.owner, opp, { bs: p.small ? 12 : 18, push: 6 }, p.chip || 0);
          else this.applyDamage(p.owner, opp, p.dmg, { kd: p.kd, dizzy: p.dizzy, hs: p.hs, launch: { vx: p.type === 'auto' ? 11 : 7, vy: p.type === 'auto' ? -13 : -9 }, superHit: p.superHit });
          if (p.type === 'lol') { p.life = 0; this.callout(p.owner.side, 'LOL! STUNNED', '#e3b65a'); }
          if (p.type === 'roastwave') { p.life = 0; this.callout(p.owner.side, 'ROASTED!', '#ff5a1f'); }
          if (p.type === 'pan' || p.type === 'like') p.life = 0;
        }
      }
      if (p.wall) {   // jelly wall keeps the opponent from walking through it
        const dx = opp.x - p.x;
        if (Math.abs(dx) < p.w / 2 + HALF_W && -opp.y < p.h) opp.x = p.x + Math.sign(dx || p.vx) * (p.w / 2 + HALF_W);
      }
    }
    // projectile clashes: small ones cancel, the jelly wall eats enemy projectiles
    const ps = this.projectiles;
    for (let i = 0; i < ps.length; i++) for (let j = i + 1; j < ps.length; j++) {
      const a = ps[i], b = ps[j];
      if (a.owner === b.owner || a.life <= 0 || b.life <= 0 || a.noTouch || b.noTouch) continue;
      if (Math.abs(a.x - b.x) < (a.w + b.w) / 2 && Math.abs(a.y - b.y) < (a.h + b.h) / 2) {
        if (a.wall && !b.wall) { b.life = 0; this.fx.spark(b.x, b.y, true); }
        else if (b.wall && !a.wall) { a.life = 0; this.fx.spark(a.x, a.y, true); }
        else if (a.small || b.small || (!a.isSuper && !b.isSuper)) { if (a.small) a.life = 0; if (b.small) b.life = 0; this.fx.spark((a.x + b.x) / 2, a.y, true); this.audio('block'); }
      }
    }
    for (const p of ps) if (p.life <= 0 && p.isSuper && !p.hitAny && !p.bruhDone && p.type !== 'ringlight' && p.type !== 'pan' && p.type !== 'like') { p.bruhDone = true; if (this.phase === 'fight') this.bruh(); }
    this.projectiles = ps.filter((p) => p.life > 0);
  }

  // ---------- random stage chaos ----------
  updateEvents() {
    // railway platform: a train thunders past every ~15 s (screen shake + horn)
    if (this.stage === 'platform') {
      if (this.trainT > 0) { this.trainT++; if (this.trainT < 150) this.shake(3); if (this.trainT > 190) this.trainT = 0; }
      else if (--this.nextTrain <= 0) { this.trainT = 1; this.nextTrain = 60 * (13 + Math.floor(this.rand() * 6)); this.audio('train'); this.banner('TRAIN AAYI!', '', 50, '#ffffff'); }
    }
    if (!this.events || this.phase !== 'fight') { if (this.event) this.event.t++; if (this.phase !== 'fight') WORLD.gravity = GRAVITY; return; }
    if (this.event) {
      const e = this.event; e.t++;
      if (e.type === 'cow') {   // the cow walks through the fight and bumps whoever is in the way
        e.x = cowX(e);
        for (const f of this.f) {
          if (!e.bumped?.[f.side] && Math.abs(f.x - e.x) < 70 && !f.airborne && !f.invulnerable && f.state !== 'grabbed' && f.state !== 'throw' && f.state !== 'super' && f.state !== 'badla') {
            e.bumped = { ...(e.bumped || {}), [f.side]: true };
            f.attack = null; f.force('launched'); f.vx = e.dir * 6; f.vy = -9; f.y = -1;
            this.callout(f.side, 'GAI NE UDA DIYA!', '#ffffff'); this.audio('moo'); this.shake(5);
          }
        }
      }
      if (e.type === 'moon') WORLD.gravity = GRAVITY * 0.45;
      if (e.t >= e.len) { this.event = null; WORLD.gravity = GRAVITY; }
      return;
    }
    if (--this.nextEvent > 0) return;
    const pool = { tapri: ['cow', 'powercut', 'rain', 'lag', 'moon'], terrace: ['cow', 'rain', 'kite', 'moon', 'lag'], platform: ['cow', 'rain', 'lag', 'moon', 'powercut'] }[this.stage] || ['cow'];
    const type = pool[Math.floor(this.rand() * pool.length)];
    const len = { cow: 420, powercut: 240, rain: 600, kite: 300, lag: 180, moon: 300 }[type];
    this.event = { type, t: 0, len, dir: this.rand() < 0.5 ? 1 : -1 };
    this.nextEvent = 60 * (14 + Math.floor(this.rand() * 10));
    const words = { cow: 'GAI AAYI! SAB RUK JAO!', powercut: 'LIGHT GAYI!', rain: 'BAARISH!', kite: 'BO KATAAA!', lag: 'BHAI NE BOLA: LAG HAI!', moon: 'BHAI NE BOLA: CHAND PE DANGAL!' };
    this.banner(words[type], '', 70, '#ffffff');
    this.audio({ cow: 'moo', powercut: 'powercut', rain: 'thunder', lag: 'bruh', moon: 'jelly' }[type] || 'whoosh');
  }

  endRound(kind) {
    const [a, b] = this.f;
    let winner = null;
    if (kind === 'ko') winner = a.hp <= 0 && b.hp <= 0 ? null : a.hp <= 0 ? 1 : 0;
    else winner = a.hp === b.hp ? null : a.hp > b.hp ? 0 : 1;
    if (winner !== null) this.wins[winner]++;
    const perfect = winner !== null && this.f[winner].hp === this.f[winner].maxHp;
    this.roundResult = { kind, winner, perfect };
    this.history.push(this.roundResult);
    this.phase = 'roundEnd'; this.phaseT = 0; this.projectiles = []; this.pending = [];
    if (kind === 'ko') {
      this.slowmo = 75; this.shake(12); this.fx.confetti(); this.audio('ko');
      this.banner('K.O.!', perfect ? 'EK DUM PERFECT!' : 'KHATAM, TATA, BYE BYE!', 160, '#e3b65a');
    } else {
      this.audio('timeup');
      this.banner('TIME KHATAM!', winner === null ? 'BARABAR! DRAW' : '', 160, '#ffffff');
    }
    for (const f of this.f) if (f.hp > 0 && (f.state === 'attack' || f.state === 'airattack')) { f.attack = null; f.force(f.airborne ? 'jump' : 'idle'); }
  }
}
