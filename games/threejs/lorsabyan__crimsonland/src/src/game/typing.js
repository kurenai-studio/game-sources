// Type to Kill: the soldier stands still and every creature carries a word. Finish the word,
// the creature dies. The player's keyboard is the only weapon.
import { byLength } from '../data/words.js';
import { pick, len } from '../core/util.js';

export class Typing {
  constructor(game) {
    this.game = game;
    this.words = new Map();     // enemy id -> word
    this.reset();
  }

  reset() {
    this.words.clear();
    this.buffer = '';
    this.chars = 0;
    this.errors = 0;
    this.misfire = 0;
    this.aimX = 0; this.aimZ = 6;
  }

  get wpm() {
    const min = this.game.time / 60;
    return min > 0.1 ? Math.round(this.chars / 5 / min) : 0;
  }

  // Prefer a word whose first letter is free, so the next keystroke is unambiguous.
  assign(i) {
    const t = this.game.time;
    const pool = byLength(Math.min(3 + Math.floor(t / 70), 6), Math.min(5 + Math.floor(t / 40), 12));
    const used = new Set();
    for (const w of this.words.values()) used.add(w[0]);
    let word = pick(pool);
    for (let k = 0; k < 14 && used.has(word[0]); k++) word = pick(pool);
    this.words.set(i, word);
  }

  key(k) {
    if (k === 'Backspace') { this.buffer = this.buffer.slice(0, -1); return; }
    if (k.length !== 1 || !/[a-zA-Z]/.test(k)) return;
    const next = this.buffer + k.toLowerCase();
    let match = -1, prefix = false;
    for (const [i, w] of this.words) {
      if (!w.startsWith(next)) continue;
      prefix = true;
      if (w === next) match = i;
    }
    if (!prefix) {
      this.errors++;
      this.misfire = 1;
      this.game.audio.play('click', { vol: 0.6, rate: 0.7 });
      return;
    }
    this.buffer = next;
    this.chars++;
    this.game.audio.play('click', { vol: 0.25, rate: 1.5 });
    if (match >= 0) this.fire(match);
  }

  fire(i) {
    const g = this.game, h = g.horde, p = g.player;
    const word = this.words.get(i);
    const dx = h.x[i] - p.x, dz = h.z[i] - p.z, d = len(dx, dz) || 1, ux = dx / d, uz = dz / d;
    p.aimX = ux; p.aimZ = uz;
    p.kick = 0.2;
    this.aimX = h.x[i]; this.aimZ = h.z[i];
    const mx = p.x + ux * 1.25, mz = p.z + uz * 1.25;
    g.fx.muzzle(mx, 1.12, mz, ux, uz, p.weapon.col, 1);
    g.fx.shell(p.x + ux * 0.4, 1.15, p.z + uz * 0.4, ux, uz);
    g.fx.beam(mx, mz, h.x[i], h.z[i], 1.12, 0.2, 6, 4, 2, 0.1);
    g.audio.play('rifle', { rate: 1 });
    g.stage.shake(0.09);
    h.damage(i, 1e6, ux, uz, 7, { direct: true });
    g.addScore(word.length * 8);
    this.words.delete(i);
    this.buffer = '';
  }

  drive(input) {
    const h = this.game.horde;
    for (const i of this.words.keys()) if (h.dead[i] > 0) this.words.delete(i);
    if (this.buffer && ![...this.words.values()].some((w) => w.startsWith(this.buffer))) this.buffer = '';
    this.misfire = Math.max(0, this.misfire - 0.1);
    input.moveX = 0; input.moveZ = 0; input.fire = false;
    input.aimX = this.aimX; input.aimZ = this.aimZ;
  }
}
