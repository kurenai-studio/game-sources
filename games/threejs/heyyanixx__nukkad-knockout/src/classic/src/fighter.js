import { MOVES, totalFrames, pickMove, THROW, SUPER } from './moves.js';

export const GROUND = 0;          // y = 0 is the floor, negative y is up
export const GRAVITY = 0.9;
export const WORLD = { gravity: GRAVITY };   // events can change gravity (moon mode)
export const HALF_W = 26;         // half body width (px)
export const BUFFER_FRAMES = 8;   // how long a pressed button is remembered

export const TAUNTS = ['Bas itna hi?', 'Chal nikal!', 'Mummy ko bolu?', 'Aur bhai, kya haal?', 'Noob detected', 'Thoda practice kar le', 'Chai peeke aa'];
const ACTIONABLE = new Set(['idle', 'walk', 'crouch']);
const INVULN = new Set(['knockdown', 'getup', 'ko', 'victory', 'intro']);

export const emptyInput = () => ({
  left: false, right: false, up: false, down: false,
  p: false, k: false, g: false, s: false, t: false,
  pressed: { p: false, k: false, g: false, s: false, t: false, up: false },
});

export class Fighter {
  constructor(side, char) {
    this.side = side;     // 0 = left player, 1 = right player
    this.char = char;
    this.stats = { dmgDealt: 0, maxCombo: 0, hits: 0, blocks: 0 };   // whole match
    this.reset(side === 0 ? 300 : 660);
  }

  reset(x) {
    this.x = x; this.y = GROUND; this.vx = 0; this.vy = 0; this.pushVx = 0;
    this.facing = this.side === 0 ? 1 : -1;
    this.hp = 100; this.maxHp = 100; this.trailHp = 100;
    this.meter = 0;
    this.state = 'idle'; this.t = 0;
    this.attack = null;        // { move, frame, contact, hit }
    this.stun = 0; this.hitstop = 0;
    this.buffer = null; this.superBuf = 0;
    this.airUsed = false; this.crouching = false; this.holdingBack = false;
    this.comboHits = 0; this.lastHitFrame = 0;
    this.grabTarget = null; this.throwT = 0;
    this.superT = 0; this.flash = 0;
    this.input = emptyInput();
    this.walkCycle = 0;
  }

  get airborne() { return this.y < GROUND - 0.5 || this.vy < 0; }
  get actionable() { return ACTIONABLE.has(this.state); }
  get invulnerable() { return INVULN.has(this.state); }
  get canBlock() { return (this.actionable || this.state === 'blockstun') && !this.airborne; }
  get height() {
    const h = 150 * this.char.scale;
    if (this.state === 'knockdown' || this.state === 'ko') return 34;
    if (this.crouching || this.state === 'crouch' || (this.attack && this.attack.move.crouch)) return h * 0.64;
    return h;
  }
  get isLow() { return this.crouching || this.state === 'crouch' || !!(this.attack && this.attack.move.crouch); }

  enter(state) { if (this.state !== state) { this.state = state; this.t = 0; } }
  force(state) { this.state = state; this.t = 0; }
  addMeter(v) { this.meter = Math.max(0, Math.min(100, this.meter + v)); }

  moveFor(button, dirs) {
    let id = pickMove(button, dirs);
    const sp = this.char.specials || {};
    if (id === 'rush' && sp.rush) id = sp.rush;
    if (id === 'fly' && sp.fly) id = sp.fly;
    return MOVES[id];
  }

  startAttack(move) {
    this.attack = { move, frame: 0, contact: false, hit: false, spawned: false };
    this.force(move.air ? 'airattack' : 'attack');
    if (!move.air) this.vx = 0;
  }

  // One simulation frame. `game` gives access to the opponent and effects.
  update(input, opp, game) {
    this.input = input;
    // remember presses even during hitstop so inputs feel responsive
    for (const b of ['p', 'k', 'g']) if (input.pressed[b]) this.buffer = { b, t: BUFFER_FRAMES, both: input.pressed.p && input.pressed.k };
    if (input.pressed.s) this.superBuf = BUFFER_FRAMES;
    if (this.flash > 0) this.flash--;
    if (this.hitstop > 0) { this.hitstop--; return; }
    if (this.buffer && --this.buffer.t <= 0) this.buffer = null;
    if (this.superBuf > 0) this.superBuf--;
    if (this.trailHp > this.hp) this.trailHp = Math.max(this.hp, this.trailHp - 0.6);

    this.t++;
    const fwd = this.facing === 1 ? input.right : input.left;
    const back = this.facing === 1 ? input.left : input.right;
    this.holdingBack = back && !fwd;

    switch (this.state) {
      case 'intro': case 'victory': break;
      case 'idle': case 'walk': case 'crouch': this.updateActionable(input, fwd, back, opp, game); break;
      case 'jump': case 'airattack': this.updateAir(input, fwd, game); break;
      case 'attack': this.updateAttack(input, fwd, game); break;
      case 'hitstun': case 'blockstun': case 'dizzy':
        if (--this.stun <= 0) { this.enter('idle'); this.comboHits = 0; }
        break;
      case 'launched':
        if (!this.airborne && this.t > 2) { this.force('knockdown'); this.stun = 38; game.fx.dust(this.x, 1.2); game.shake(4); game.audio('thud'); }
        break;
      case 'knockdown':
        if (--this.stun <= 0) { this.force('getup'); this.stun = 16; }
        break;
      case 'getup':
        if (--this.stun <= 0) { this.enter('idle'); this.comboHits = 0; }
        break;
      case 'throw': this.updateThrow(opp, game); break;
      case 'grabbed': break; // controlled by the thrower
      case 'super': this.updateSuper(opp, game); break;
      case 'badla': this.updateBadla(opp, game); break;
      case 'taunt':
        if (this.t === 12) { this.addMeter(12 * this.char.meterMul); game.fx.popup(this.x, this.y - 190 * this.char.scale, TAUNTS[Math.floor(game.rand() * TAUNTS.length)], '#ffffff', 22); game.audio('lol'); }
        if (this.t >= 44) this.enter('idle');
        break;
      case 'ko': break;
    }
    this.physics();
  }

  updateActionable(input, fwd, back, opp, game) {
    if (this.superBuf && this.meter >= 100) { this.startSuper(game); return; }
    if (input.pressed.t) { this.vx = 0; this.crouching = false; this.force('taunt'); return; }
    const buf = this.buffer;
    if (buf && (buf.b === 'g' || buf.both)) { this.buffer = null; this.startAttack(MOVES.grab); return; }
    if (input.up && !input.down) { this.startJump(fwd ? 1 : back ? -1 : 0, game); return; }
    if (buf) {
      this.buffer = null;
      this.startAttack(this.moveFor(buf.b, { down: input.down, forward: fwd && !input.down }));
      return;
    }
    if (input.down) { this.crouching = true; this.enter('crouch'); this.vx = 0; return; }
    this.crouching = false;
    if (fwd) { this.vx = this.char.speed * this.facing; this.enter('walk'); this.walkCycle += 0.18; }
    else if (back) { this.vx = -this.char.back * this.facing; this.enter('walk'); this.walkCycle -= 0.14; }
    else { this.vx = 0; this.enter('idle'); }
  }

  startJump(dir, game) {
    this.crouching = false;
    this.vy = this.char.jump;
    this.vx = dir * 4.2 * this.facing;
    this.airUsed = false;
    this.force('jump');
    game.audio('jump');
  }

  updateAir(input, fwd, game) {
    if (this.state === 'jump' && this.buffer && !this.airUsed && (this.buffer.b === 'p' || this.buffer.b === 'k')) {
      const b = this.buffer.b; this.buffer = null; this.airUsed = true;
      this.startAttack(MOVES[b === 'p' ? 'airp' : 'airk']);
      this.state = 'airattack';
    }
    if (this.attack) this.attack.frame++;
    else if (this.state === 'airattack') this.state = 'jump';
    if (!this.airborne && this.t > 1) {
      this.attack = null; this.force('idle'); this.vx = 0; game.fx.dust(this.x, 0.5);
    }
  }

  updateAttack(input, fwd, game) {
    const a = this.attack;
    if (!a) { this.force('idle'); return; }
    const m = a.move;
    a.frame++;
    if (m.lunge && a.frame <= m.s + 2) this.vx = m.lunge * this.facing * (1 - a.frame / (m.s + 6));
    else if (!m.air) this.vx *= 0.7;
    if (m.spawn && !a.spawned && a.frame >= m.s) { a.spawned = true; game.spawnSpecial(this, m.spawn); }
    if (m.fx === 'beep' && a.frame === m.s) game.fx.beep(this.x + this.facing * 70, this.y - 90);
    // combo chains: a buffered button cancels into the next move once this one connected
    if (a.contact && m.chains && this.buffer && a.frame >= m.s + m.a - 1) {
      const next = m.chains[this.buffer.b];
      if (next) { this.buffer = null; this.startAttack(MOVES[next]); return; }
    }
    if (a.frame >= totalFrames(m)) {
      this.attack = null;
      if (m.crouch && input.down) { this.crouching = true; this.force('crouch'); }
      else { this.crouching = false; this.force('idle'); }
    }
  }

  get attackPhase() {
    if (!this.attack) return null;
    const { frame } = this.attack, m = this.attack.move;
    if (frame < m.s) return 'startup';
    if (frame < m.s + m.a) return 'active';
    return 'recovery';
  }
  get attackActive() { return this.attackPhase === 'active' && !this.attack.contact; }

  // --- throws ---
  beginThrow(target) {
    this.force('throw'); this.throwT = 0; this.grabTarget = target; this.attack = null; this.vx = 0;
    target.force('grabbed'); target.attack = null; target.vx = 0; target.crouching = false;
  }
  updateThrow(opp, game) {
    this.throwT++;
    const tg = this.grabTarget;
    if (!tg) { this.force('idle'); return; }
    tg.x = this.x + this.facing * 48; tg.y = Math.min(0, -Math.sin(Math.min(1, this.throwT / THROW.length) * Math.PI) * 60);
    if (this.throwT <= THROW.breakWindow && (tg.input.pressed.g || (tg.input.pressed.p && tg.input.pressed.k))) {
      // throw break!
      for (const [f, dir] of [[this, -1], [tg, 1]]) { f.force('blockstun'); f.stun = 14; f.pushVx = dir * this.facing * 6; }
      tg.y = 0; this.grabTarget = null;
      game.callout(tg.side, 'CHHOD!', '#ffffff'); game.audio('block'); game.fx.spark((this.x + tg.x) / 2, -100, true);
      return;
    }
    if (this.throwT === THROW.length) {
      const dmg = Math.round(THROW.dmg * this.char.dmgMul);
      game.applyDamage(this, tg, dmg, { kd: true, launch: { vx: 7, vy: -10 }, throwHit: true });
      tg.facing = -this.facing;
      game.callout(this.side, this.char.moves.grab + '!', this.char.color);
      this.grabTarget = null;
    }
    if (this.throwT >= THROW.length + 14) this.force('idle');
  }

  // --- super ---
  startSuper(game) {
    this.superBuf = 0; this.meter = 0; this.buffer = null; this.attack = null; this.vx = 0; this.crouching = false;
    this.force('super'); this.superT = 0;
    game.superFreeze(this);
  }
  updateSuper(opp, game) {
    this.superT++;
    if (this.superT === SUPER.freeze) {
      if (this.char.superType === 'badla') { this.force('badla'); this.superT = 0; this.vx = 15 * this.facing; return; }
      game.spawnSuper(this);
    }
    if (this.superT >= SUPER.freeze + SUPER.recover) this.force('idle');
  }
  // HEYY ANISH's 8-3 BADLA: a dash; on contact, 8 rapid hits.
  updateBadla(opp, game) {
    this.superT++;
    if (!this.badlaHits) {
      this.vx = 15 * this.facing;
      const dx = (opp.x - this.x) * this.facing;
      if (dx > 0 && dx < 80 && !opp.invulnerable && !opp.airborne) {
        if (opp.canBlock && opp.holdingBack) {
          game.applyBlock(this, opp, { bs: 22, push: 10 }, 6); this.vx = 0; this.force('idle'); return;
        }
        this.badlaHits = 1; this.vx = 0; this.superT = 0;
      } else if (this.superT > 30) { this.vx = 0; this.force('idle'); return; }
    } else {
      opp.x = this.x + this.facing * 60;
      if (this.superT % 6 === 0) {
        const last = this.badlaHits >= 8;
        game.applyDamage(this, opp, last ? 6 : 3, last ? { kd: true, launch: { vx: 9, vy: -12 }, superHit: true } : { hs: 30, superHit: true });
        if (last) { game.callout(this.side, '8-3 BADLA!!', '#e3b65a', true); this.badlaHits = 0; this.force('idle'); return; }
        this.badlaHits++;
      }
    }
  }

  physics() {
    this.x += this.vx + this.pushVx;
    this.pushVx *= 0.82; if (Math.abs(this.pushVx) < 0.05) this.pushVx = 0;
    if (this.state !== 'grabbed') {
      if (this.y < GROUND || this.vy < 0) {
        this.vy += WORLD.gravity; this.y += this.vy;
        if (this.y >= GROUND) { this.y = GROUND; this.vy = 0; if (this.state === 'launched' || this.state === 'ko') this.vx *= 0.3; }
      }
    }
    if (!this.airborne && (this.state === 'hitstun' || this.state === 'blockstun' || this.state === 'knockdown' || this.state === 'ko' || this.state === 'dizzy')) this.vx *= 0.8;
  }
}
