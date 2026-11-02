import Phaser from 'phaser';
import { W, H, C, txt, hex } from '../theme.js';
import { COLS, LEVELS } from '../levels.js';
import { tone, SFX } from '../sfx.js';
import { cameraLook, confetti, muteToggle } from '../fx.js';
import { burst } from '../juice.js';
import { layerShiftLogo } from './Title.js';

const starsFor = (acc) => (acc >= 0.95 ? 3 : acc >= 0.8 ? 2 : acc >= 0.6 ? 1 : 0);

export default class ResultsScene extends Phaser.Scene {
  constructor() { super('results'); }

  launch(print, x, baseY) {
    const flame = this.add.container(x, baseY);
    const outer = this.add.image(0, 10, 'glow').setTint(C.hot).setScale(0.8, 1.6).setBlendMode('ADD');
    const inner = this.add.image(0, 4, 'glow').setTint(0xfff3b0).setScale(0.4, 0.9).setBlendMode('ADD');
    flame.add([outer, inner]);
    this.tweens.add({ targets: [outer, inner], scaleY: '*=1.25', duration: 70, yoyo: true, repeat: -1 });
    const smoke = this.add.particles(x, baseY + 6, 'glow', {
      speedX: { min: -140, max: 140 }, speedY: { min: -30, max: 10 }, scale: { start: 0.5, end: 1.4 },
      alpha: { start: 0.35, end: 0 }, lifespan: 1100, tint: 0x9aa6ba, frequency: 25,
    });
    SFX.rumble(2.2);
    this.cameras.main.shake(1400, 0.004);
    const lift = { y: 0 };
    this.tweens.add({
      targets: lift, y: -620, delay: 500, duration: 1900, ease: 'Cubic.easeIn',
      onUpdate: () => { print.y = lift.y; flame.y = baseY + lift.y; },
      onComplete: () => { smoke.stop(); flame.destroy(); },
    });
    const t = txt(this, x, 200, 'LIFT-OFF!', 34, C.amber, { ox: 0.5, oy: 0.5 }).setAlpha(0);
    this.tweens.add({ targets: t, alpha: 1, scale: { from: 0.6, to: 1 }, delay: 900, duration: 300, ease: 'Back.easeOut' });
  }

  create(data) {
    this.add.image(W / 2, H / 2, 'bg');
    const level = LEVELS[data.level], last = data.level >= LEVELS.length - 1;
    const stars = starsFor(data.accuracy);
    const best = this.registry.get('best') || {};
    best[level.id] = Math.max(best[level.id] || 0, stars);
    this.registry.set('best', best);

    // the finished print, on a display plinth
    const cw = 26, ch = 15, rows = data.snapshot.length;
    const px = 280, baseY = 420, x0 = px - (COLS * cw) / 2;
    const g = this.add.graphics();
    g.fillStyle(0x0f1724, 1).fillRoundedRect(px - 190, baseY + 2, 380, 16, 6);
    this.add.image(px, baseY + 4, 'glow').setScale(8, 1.2).setTint(C.greenGlow).setAlpha(0.18).setBlendMode('ADD');
    const print = this.add.container(0, 0);
    data.snapshot.forEach((row, r) => row.forEach((v, c) => {
      if (!v) return;
      const img = this.add.image(x0 + c * cw, baseY - (r + 1) * ch, v === 1 ? 'cell' : 'cellBad').setOrigin(0).setDisplaySize(cw, ch).setAlpha(0);
      print.add(img);
      this.tweens.add({ targets: img, alpha: 1, delay: r * 45 + c * 6, duration: 160 });
    }));
    // A clean rocket earns a launch.
    if (level.id === 'rocket' && stars >= 2) this.time.delayedCall(2200, () => this.launch(print, px, baseY));
    txt(this, px, baseY + 34, level.name.toUpperCase(), 14, C.muted, { ox: 0.5, spacing: 3 });

    // right: verdict
    const cx = 690;
    txt(this, cx, 70, `JOB ${data.level + 1} COMPLETE · ${data.clock}`, 12, C.muted, { ox: 0.5, spacing: 3 });
    const verdict = ['FAILED PRINT', 'PRINTABLE', 'CLEAN PRINT', 'FLAWLESS'][stars];
    txt(this, cx, 96, verdict, 40, stars ? C.white : C.red, { ox: 0.5 });

    for (let i = 0; i < 3; i++) {
      const on = i < stars;
      const s = txt(this, cx - 70 + i * 70, 178, '★', 56, on ? C.amber : 0x2a3446, { ox: 0.5, oy: 0.5 }).setScale(0);
      this.tweens.add({
        targets: s, scale: 1, delay: 400 + i * 260, duration: 260, ease: 'Back.easeOut',
        onStart: () => { if (on) { SFX.star(i); burst(this, s.x, s.y, C.amber, 14, 200); } },
      });
    }

    const st = data.stats;
    const lines = [
      ['Accuracy', `${Math.round(data.accuracy * 100)}%`],
      ['Perfect layers', `${st.perfect} / ${rows}`],
      ['Best combo', `×${st.bestCombo}`],
      ['Spaghetti', `${st.droop}`],
      ['Bits lost off the edge', `${st.lost}`],
    ];
    lines.forEach(([k, v], i) => {
      const y = 236 + i * 30;
      txt(this, cx - 150, y, k, 15, C.muted, { weight: '500' });
      txt(this, cx + 150, y, v, 15, C.white, { ox: 1, mono: true });
      this.add.rectangle(cx, y + 24, 300, 1, 0x223047);
    });

    const next = last ? 'SHIFT COMPLETE — SEE YOU TOMORROW NIGHT' : 'BOTH SHIFTS: NEXT JOB   ·   ONE SHIFT: RETRY';
    const t = txt(this, cx, 420, next, 12, C.greenGlow, { ox: 0.5, spacing: 2 });
    this.tweens.add({ targets: t, alpha: 0.4, duration: 700, yoyo: true, repeat: -1 });
    if (last) txt(this, cx, 444, 'Press any Shift to play again', 11, C.muted, { ox: 0.5, weight: '500' });

    // Both Shifts within a moment = next job; a single Shift = retry (timing-based, see Game.press).
    const downAt = { l: -1e9, r: -1e9 }, bornAt = performance.now();
    let leaving = false;
    const leave = (scene, payload) => {
      if (leaving) return;
      leaving = true;
      SFX.click();
      this.cameras.main.fadeOut(250, 6, 8, 13);
      this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start(scene, payload));
    };
    let retryTimer = null;
    const goNext = () => { clearTimeout(retryTimer); leave(last ? 'title' : 'game', last ? undefined : { level: data.level + 1 }); };
    this.input.keyboard.on('keydown', (e) => {
      if (e.repeat || performance.now() - bornAt < 500) return;          // ignore keys still flying from the last layer
      if (e.code === 'Enter' || e.code === 'Space') return goNext();
      if (e.code !== 'ShiftLeft' && e.code !== 'ShiftRight') return;
      if (last) return goNext();
      const now = performance.now(), side = e.code === 'ShiftLeft' ? 'l' : 'r', other = side === 'l' ? 'r' : 'l';
      downAt[side] = now;
      if (now - downAt[other] < 160) return goNext();
      clearTimeout(retryTimer);
      retryTimer = setTimeout(() => leave('game', { level: data.level }), 220);
    });
    this.input.on('pointerdown', () => goNext());
    this.events.once('shutdown', () => clearTimeout(retryTimer));

    this.cameras.main.fadeIn(300, 6, 8, 13);
    if (stars) this.time.delayedCall(300, () => SFX.win());
    if (stars === 3) this.time.delayedCall(1250, () => { confetti(this, cx - 160, 200); confetti(this, cx + 160, 200); });
    cameraLook(this);
    muteToggle(this);
    window.__gameState = { scene: 'results', stars, accuracy: data.accuracy };
  }
}
