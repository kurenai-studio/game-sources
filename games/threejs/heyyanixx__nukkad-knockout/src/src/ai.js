import { emptyInput } from './fighter.js';

// CPU difficulty profiles. react = frames between decisions (lower = faster brain).
export const PROFILES = {
  easy:   { react: 26, block: 0.2,  punish: 0.25, aggr: 0.45, superC: 0.3, brk: 0.1,  combo: 0.35, special: 0.15 },
  normal: { react: 16, block: 0.45, punish: 0.5,  aggr: 0.62, superC: 0.7, brk: 0.35, combo: 0.65, special: 0.3 },
  hard:   { react: 9,  block: 0.72, punish: 0.85, aggr: 0.78, superC: 1.0, brk: 0.65, combo: 0.92, special: 0.45 },
};

const COMBOS = {
  ppp: [{ at: 0, b: 'p' }, { at: 7, b: 'p' }, { at: 15, b: 'p' }],
  ppk: [{ at: 0, b: 'p' }, { at: 7, b: 'p' }, { at: 15, b: 'k' }],
  kk:  [{ at: 0, b: 'k' }, { at: 13, b: 'k' }],
  pk:  [{ at: 0, b: 'p' }, { at: 7, b: 'k' }, { at: 20, b: 'k' }],
  dk:  [{ at: 0, b: 'k', dir: 'down' }],
  dpk: [{ at: 0, b: 'p', dir: 'down' }, { at: 7, b: 'k', dir: 'down' }],
  fp:  [{ at: 0, b: 'p', dir: 'fwd' }],
  fk:  [{ at: 0, b: 'k', dir: 'fwd' }],
  p:   [{ at: 0, b: 'p' }],
  g:   [{ at: 0, b: 'g' }],
};

export class CPU {
  constructor(level = 'normal', rand = Math.random) {
    this.p = PROFILES[level] || PROFILES.normal;
    this.rand = rand;
    this.plan = { kind: 'wait', t: 0, len: 10, buttons: [] };
    this.since = 99;
    this.lastHeld = emptyInput();
    this.brokeThisThrow = false;
  }

  setPlan(kind, len, buttons = [], hold = null) { this.plan = { kind, t: 0, len, buttons, hold }; }

  decide(me, opp, game) {
    const r = this.rand, p = this.p;
    const dist = Math.abs(opp.x - me.x);
    this.since = 0;
    if (!me.actionable && me.state !== 'blockstun') return;
    if ((opp.state === 'knockdown' || opp.state === 'ko') && Math.abs(opp.x - me.x) > 120 && r() < 0.25) { this.setPlan('taunt', 46, [{ at: 0, b: 't' }]); return; }
    // incoming projectile?
    const proj = game.projectiles.find((q) => q.owner === opp && !q.noTouch && Math.abs(q.x - me.x) < 260 && Math.sign(q.vx || 1) === Math.sign(me.x - q.x));
    if (proj && r() < p.block + 0.1) { r() < 0.3 && !proj.fall && proj.type !== 'jelly' ? this.setPlan('jump', 30, [], 'upback') : this.setPlan('block', 24, [], proj.y > -40 ? 'downback' : 'back'); return; }
    if (game.projectiles.some((q) => q.type === 'reticle' && q.owner === opp) && r() < p.block) { this.setPlan('duck', 30, [], 'down'); return; }
    // super when full
    if (me.meter >= 100 && opp.state !== 'knockdown' && opp.state !== 'getup' && r() < p.superC * 0.5) {
      const t = me.char.superType;
      const ok = t === 'flash' ? dist < 300 : t === 'badla' ? dist < 260 : true;
      if (ok) { this.setPlan('super', 6, [{ at: 0, b: 's' }]); return; }
    }
    // opponent attacking -> block
    if ((opp.attackPhase === 'startup' || opp.attackPhase === 'active') && dist < 190 && r() < p.block) {
      if (opp.attack.move.grab) { if (r() < p.brk) this.setPlan('tech', 8, [{ at: 0, b: 'g' }]); return; }
      const low = opp.attack.move.h === 'low';
      this.setPlan('block', 22, [], low ? 'downback' : 'back');
      return;
    }
    // punish recovery / getup
    if (dist < 130 && (opp.attackPhase === 'recovery' || opp.state === 'getup' || opp.state === 'dizzy') && r() < p.punish) {
      this.setPlan('attack', 40, r() < p.combo ? COMBOS[['ppp', 'ppk', 'pk', 'kk'][Math.floor(r() * 4)]] : COMBOS.p);
      return;
    }
    // opponent blocking a lot -> throw
    if (dist < 75 && (opp.state === 'blockstun' || (opp.holdingBack && opp.actionable)) && r() < 0.35 * p.aggr) { this.setPlan('attack', 30, COMBOS.g); return; }
    if (dist > 170) {
      const sp = me.char.specials?.rush;
      if ((sp === 'emote' || sp === 'roast') && dist < 420 && r() < p.special) { this.setPlan('attack', 30, COMBOS.fp); return; }
      if (dist < 330 && r() < 0.14 * p.aggr) { this.setPlan('jumpin', 44, [{ at: 16, b: 'k' }], 'upfwd'); return; }
      if (dist < 260 && r() < p.special * 0.5) { this.setPlan('attack', 36, r() < 0.5 ? COMBOS.fp : COMBOS.fk); return; }
      this.setPlan('approach', 14 + Math.floor(r() * 18), [], 'fwd');
      return;
    }
    const o = r();
    if (o < p.aggr) {
      const pick = r() < p.combo ? ['ppp', 'ppk', 'pk', 'kk', 'dpk', 'dk', 'fp', 'fk'][Math.floor(r() * 8)] : ['p', 'dk', 'kk'][Math.floor(r() * 3)];
      if (dist > 120 && !['fp', 'fk', 'kk', 'dk'].includes(pick)) { this.setPlan('approach', 10, [], 'fwd'); return; }
      this.setPlan('attack', 40, COMBOS[pick]);
    } else if (o < p.aggr + 0.15) this.setPlan('retreat', 12 + Math.floor(r() * 14), [], 'back');
    else if (o < p.aggr + 0.27) this.setPlan('block', 18, [], r() < 0.5 ? 'back' : 'downback');
    else this.setPlan('wait', 10);
  }

  // Returns an input object, exactly like the keyboard would.
  think(me, opp, game) {
    this.since++;
    const plan = this.plan;
    plan.t++;
    // throw break reflex
    if (me.state === 'grabbed') {
      if (!this.brokeDecided) { this.brokeDecided = true; this.breakIt = this.rand() < this.p.brk; this.breakAt = 3 + Math.floor(this.rand() * 5); }
      const inp = emptyInput();
      if (this.breakIt && me.t >= 0 && this.breakFrame === undefined) this.breakFrame = 0;
      if (this.breakIt) { this.breakFrame++; if (this.breakFrame === this.breakAt) { inp.g = true; inp.pressed.g = true; } }
      return this.finish(inp);
    }
    this.brokeDecided = false; this.breakFrame = undefined;
    if (this.since >= this.p.react || plan.t > plan.len) this.decide(me, opp, game);
    const pl = this.plan;
    const inp = emptyInput();
    const fwdKey = me.facing === 1 ? 'right' : 'left', backKey = me.facing === 1 ? 'left' : 'right';
    const hold = pl.hold || '';
    if (hold.includes('fwd')) inp[fwdKey] = true;
    if (hold.includes('back')) inp[backKey] = true;
    if (hold.includes('down')) inp.down = true;
    if (hold.includes('up') && pl.t < 3) inp.up = true;
    for (const btn of pl.buttons) {
      if (btn.at === pl.t - 1) {
        inp[btn.b] = true; inp.pressed[btn.b] = true;
        if (btn.dir === 'down') inp.down = true;
        if (btn.dir === 'fwd') inp[fwdKey] = true;
      }
    }
    // keep direction held for the frame a directional move is pressed
    const next = pl.buttons.find((b) => b.at === pl.t - 1 && b.dir);
    if (next?.dir === 'down') inp.down = true;
    return this.finish(inp);
  }
  finish(inp) { inp.pressed.up = inp.up && !this.lastHeld.up; this.lastHeld = inp; return inp; }
}
