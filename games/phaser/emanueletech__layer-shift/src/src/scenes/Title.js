import Phaser from 'phaser';
import { W, H, CW, CH, C, txt, hex, FONT } from '../theme.js';
import { COLS, LEVELS } from '../levels.js';
import { buildPrinter, PX, rowY, colX } from '../printer.js';
import { resumeAudio, SFX, Music, SONGS, tone } from '../sfx.js';
import { dust, cameraLook, muteToggle } from '../fx.js';

// The logo is drawn once on a canvas, then sliced into horizontal "layers" that glitch sideways
// and snap back: a layer shift.
export function layerShiftLogo(scene, x, y, str, size) {
  const key = `logo-${str}-${size}`;
  if (!scene.textures.exists(key)) {
    const probe = document.createElement('canvas').getContext('2d');
    probe.font = `700 ${size}px ${FONT.display}`;
    const w = Math.ceil(probe.measureText(str).width + size * 0.3), h = Math.ceil(size * 1.15);
    const t = scene.textures.createCanvas(key, w, h);
    const ctx = t.getContext();
    ctx.font = `700 ${size}px ${FONT.display}`;
    ctx.textBaseline = 'alphabetic';
    const grad = ctx.createLinearGradient(0, h * 0.15, 0, h * 0.85);
    grad.addColorStop(0, '#ffffff');
    grad.addColorStop(0.55, '#d9ffe6');
    grad.addColorStop(1, '#2ee66b');
    ctx.fillStyle = grad;
    ctx.fillText(str, size * 0.15, h * 0.86);
    // printed-layer lines across the letters
    ctx.globalCompositeOperation = 'source-atop';
    ctx.fillStyle = 'rgba(0,0,0,0.16)';
    for (let yy = 0; yy < h; yy += 6) ctx.fillRect(0, yy, w, 1);
    t.refresh();
  }
  const tex = scene.textures.get(key).getSourceImage();
  const w = tex.width, h = tex.height, strips = 8, sh = Math.ceil(h / strips);
  const group = scene.add.container(x - w / 2, y - h / 2);
  const parts = [];
  for (let i = 0; i < strips; i++) {
    const shadow = scene.add.image(5, 5, key).setOrigin(0).setCrop(0, i * sh, w, sh).setTint(C.greenDark).setAlpha(0.85);
    const img = scene.add.image(0, 0, key).setOrigin(0).setCrop(0, i * sh, w, sh);
    group.add([shadow, img]);
    parts.push({ img, shadow });
  }
  const glitch = () => {
    parts.forEach((p, i) => {
      const dx = Math.random() < 0.5 ? Phaser.Math.Between(-18, 18) : 0;
      if (!dx) return;
      scene.tweens.add({ targets: p.img, x: dx, duration: 50, yoyo: true, hold: 140 + i * 18, ease: 'Quad.easeOut' });
      scene.tweens.add({ targets: p.shadow, x: 5 + dx * 1.4, duration: 50, yoyo: true, hold: 150 + i * 18, ease: 'Quad.easeOut' });
    });
    tone({ type: 'square', freq: 1800, freqEnd: 900, dur: 0.03, vol: 0.04 });
  };
  scene.time.addEvent({ delay: 2800, loop: true, callback: glitch });
  scene.time.delayedCall(600, glitch);
  return group;
}

export default class TitleScene extends Phaser.Scene {
  constructor() { super('title'); }

  create() {
    this.add.image(W / 2, H / 2, 'bg');
    const printer = buildPrinter(this);

    // demo: the printer keeps printing a little rocket in the background
    const demo = ['..#..##..#..', '..#.####.#..', '..########..', '....####....', '....####....', '....#..#....', '....####....', '....####....', '.....##.....'];
    const cells = this.add.container(0, 0);
    this.children.bringToTop(printer.gantry); this.children.bringToTop(printer.head);
    let r = 0;
    const printRow = () => {
      if (r >= demo.length) {
        this.tweens.add({ targets: cells, alpha: 0, duration: 500, onComplete: () => { cells.removeAll(true); cells.alpha = 1; r = 0; } });
        this.time.delayedCall(900, printRow);
        return;
      }
      const row = [...demo[r]], y = rowY(r);
      printer.placeHead(printer.head.x, y);
      row.forEach((ch, c) => {
        if (ch !== '#') return;
        this.time.delayedCall(c * 28, () => {
          printer.head.x = colX(c) + CW / 2;
          const img = this.add.image(colX(c), y, 'cell').setOrigin(0).setScale(0.2, 1);
          cells.add(img);
          this.tweens.add({ targets: img, scaleX: 1, duration: 90 });
        });
      });
      r++;
      this.time.delayedCall(520, printRow);
    };
    printRow();

    // right side: logo + pitch + start
    const cx = 750;
    layerShiftLogo(this, cx, 140, 'LAYER', 96);
    layerShiftLogo(this, cx, 232, 'SHIFT', 96);
    txt(this, cx, 304, 'Night shift at the print farm.', 16, C.muted, { ox: 0.5, weight: '500' });
    txt(this, cx, 326, 'Fix every layer before it hits the plate.', 16, C.muted, { ox: 0.5, weight: '500' });

    const keys = this.add.container(cx, 384);
    const cap = (x, label) => {
      const g = this.add.graphics();
      g.fillStyle(0x1b2332, 1).fillRoundedRect(x - 70, -20, 140, 40, 9);
      g.lineStyle(1.5, 0x3a475c, 1).strokeRoundedRect(x - 70, -20, 140, 40, 9);
      g.fillStyle(0x0d121b, 1).fillRoundedRect(x - 70, 14, 140, 6, { tl: 0, tr: 0, bl: 9, br: 9 });
      keys.add([g, txt(this, x, -2, label, 15, C.text, { ox: 0.5, oy: 0.5, spacing: 1 })]);
    };
    cap(-80, '⇧  SHIFT');
    cap(80, 'SHIFT  ⇧');
    const start = txt(this, cx, 438, 'PRESS BOTH SHIFT KEYS TO START', 13, C.greenGlow, { ox: 0.5, spacing: 2 });
    this.tweens.add({ targets: start, alpha: 0.35, duration: 700, yoyo: true, repeat: -1 });
    txt(this, cx, 462, 'or tap the screen', 11, C.muted, { ox: 0.5, weight: '500' });
    txt(this, W - 16, H - 14, 'GitHub Game Off 2026 · theme: SHIFT · by Emanuele Tech', 10, C.muted, { ox: 1, oy: 1, weight: '500' }).setAlpha(0.7);

    const music = new Music(SONGS.title);
    dust(this, 160, 80, 340, 360);
    cameraLook(this);
    muteToggle(this);
    this.events.once('shutdown', () => music.stop());

    const last = { l: -1e9, r: -1e9 };
    let started = false;
    const go = () => {
      if (started) return;
      started = true;
      resumeAudio(); SFX.click();
      tone({ type: 'square', freq: 440, freqEnd: 1320, dur: 0.25, vol: 0.15 });
      this.cameras.main.fadeOut(300, 6, 8, 13);
      this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start('game', { level: 0 }));
    };
    this.input.keyboard.on('keydown', (e) => {
      resumeAudio(); music.start();
      if (e.repeat) return;
      const now = performance.now();
      if (e.code === 'ShiftLeft') { if (now - last.r < 160) go(); last.l = now; }
      if (e.code === 'ShiftRight') { if (now - last.l < 160) go(); last.r = now; }
      if (e.code === 'Enter' || e.code === 'Space') go();
    });
    this.input.on('pointerdown', () => { resumeAudio(); music.start(); go(); });
    this.cameras.main.fadeIn(400, 6, 8, 13);
    window.__gameState = { scene: 'title' };
  }
}
