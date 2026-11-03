import Phaser from 'phaser';
import { COLORS } from '../config';
import { sfx } from '../game/audio';
import { endedCareer, loadCareer, switchCareer, type CareerMode, type Progress } from '../game/progress';
import { settings } from '../game/settings';
import { levelById } from '../levels';
import { CAMPAIGNS, RANKS } from '../levels/campaigns';
import { attractBackdrop } from './backdrop';
import {
  ACCENT, Button, DIM, display, FAINT, fadeIn, goTo, KeyNav, openSettings, panel, RED, setupScreenCamera, stagger, style, TEXT, UI,
  type Focusable,
} from './ui';

const CARD = { w: 380, h: 196, gap: 36, y: 318 };
const TOTAL_CASES = CAMPAIGNS.reduce((n, c) => n + c.levels.length, 0);

/** The start menu: pick a career, normal or realism, then on to its campaigns. */
export class TitleScene extends Phaser.Scene {
  private nav!: KeyNav;

  constructor() {
    super('title');
  }

  create(): void {
    setupScreenCamera(this);
    this.cameras.main.setBackgroundColor(COLORS.void);
    sfx.setVolume(settings.volume);
    attractBackdrop(this);
    fadeIn(this, 600);

    // Browsers only allow audio after a user gesture; the first click or key unlocks it.
    const wake = () => {
      sfx.unlock();
      sfx.menuAmbience(true);
    };
    this.input.once('pointerdown', wake);
    this.input.keyboard?.once('keydown', wake);
    sfx.menuAmbience(true);

    const cx = 640;
    const kicker = this.add.text(cx, 118, 'PORT ARDLEY POLICE DEPARTMENT', display(15, ACCENT)).setOrigin(0.5);
    const logo = this.add.text(cx, 186, 'BREACH', display(128, '#f8fafc', { letterSpacing: 30 })).setOrigin(0.5);
    const rule = this.add.rectangle(cx, 250, 240, 2, UI.accent, 0.8);
    const tagline = this.add.text(cx, 272, 'You only know what you see. Slow is smooth.', style(13, DIM)).setOrigin(0.5);

    const normal = this.card('normal', cx - CARD.w - CARD.gap / 2, 'NORMAL CAREER', 'Retry missions as often as you like.', ACCENT, UI.accent);
    const realism = this.card('realism', cx + CARD.gap / 2, 'REALISM CAREER', 'One life. Going down ends the career.', RED, UI.red);

    const settingsBtn = new Button(this, cx - 110, 590, 190, 40, 'SETTINGS', () => this.settings(), { size: 14 });
    const credits = new Button(this, cx + 110, 590, 190, 40, 'CREDITS', () => this.credits(), { size: 14 });
    const items: Focusable[] = [normal, realism, settingsBtn, credits];
    normal.adjust = (d) => this.nav.focus(d > 0 ? 1 : 0);
    realism.adjust = (d) => this.nav.focus(d > 0 ? 1 : 0);
    settingsBtn.adjust = (d) => this.nav.focus(d > 0 ? 3 : 2);
    credits.adjust = (d) => this.nav.focus(d > 0 ? 3 : 2);
    this.nav = new KeyNav(this, items);
    for (const b of [settingsBtn, credits]) b.nav = this.nav;

    const notes: Phaser.GameObjects.GameObject[] = [];
    const ended = endedCareer.record;
    if (ended && endedCareer.reason === 'left') {
      notes.push(this.add.text(cx, CARD.y + CARD.h + 18, [
        `Realism career ended: you left a mission unfinished at ${levelById(ended.levelId).name}.`,
        `Rank reached: ${RANKS[ended.rank]}, ${ended.stars} ★.`,
      ].join('\n'), style(12, RED, { align: 'center', lineSpacing: 4 })).setOrigin(0.5, 0));
      endedCareer.record = null;
    }

    const hint = this.add.text(cx, 650, 'ARROWS TO MOVE   ·   ENTER TO SELECT   ·   ESC IN GAME TO PAUSE', display(11, FAINT)).setOrigin(0.5);
    const version = this.add.text(1252, 700, `v${__APP_VERSION__}`, style(11, FAINT)).setOrigin(1, 1);

    stagger(this, [kicker, logo, rule, tagline], 150, 90, 10);
    stagger(this, [normal.container, realism.container, ...notes, settingsBtn.container, credits.container, hint, version], 500, 70, 16);
  }

  /** A career card: rank and insignia, stars, how far through the campaigns, and a call to action. */
  private card(mode: CareerMode, x: number, title: string, blurb: string, color: string, colorHex: number): Focusable & { container: Phaser.GameObjects.Container; adjust?: (d: -1 | 1) => void } {
    const p: Progress = loadCareer(mode);
    const stars = Object.values(p.stars).reduce((a, b) => a + b, 0);
    const fresh = p.rank === 0 && p.completed.length === 0;
    const c = this.add.container(x, CARD.y);
    const bg = this.add.graphics();
    const draw = (on: boolean) => {
      bg.clear();
      bg.fillStyle(on ? UI.panelHi : UI.panel, on ? 0.97 : 0.88);
      bg.fillRoundedRect(0, 0, CARD.w, CARD.h, 10);
      bg.lineStyle(on ? 2 : 1, on ? colorHex : UI.line, 1);
      bg.strokeRoundedRect(0, 0, CARD.w, CARD.h, 10);
      bg.fillStyle(colorHex, 1);
      bg.fillRect(0, 12, 3, CARD.h - 24);
    };
    draw(false);
    c.add(bg);
    c.add(this.add.text(26, 22, title, display(14, color)));
    c.add(this.add.text(26, 46, fresh ? 'NEW CAREER' : RANKS[p.rank].toUpperCase(), display(34, TEXT)));
    c.add(insignia(this, CARD.w - 34, 66, fresh ? 0 : p.rank, colorHex));
    const done = p.completed.length;
    c.add(this.add.text(26, 98, fresh ? 'Starts at the academy' : `${stars} ★   ·   ${done} of ${TOTAL_CASES} cases closed`, style(12, DIM)));
    // Progress through every case in the game.
    const bar = this.add.graphics();
    bar.fillStyle(0x1f2937, 1);
    bar.fillRoundedRect(26, 124, CARD.w - 52, 4, 2);
    bar.fillStyle(colorHex, 0.9);
    if (done) bar.fillRoundedRect(26, 124, (CARD.w - 52) * Math.min(1, done / TOTAL_CASES), 4, 2);
    c.add(bar);
    c.add(this.add.text(26, 142, blurb, style(11, FAINT)));
    const cta = this.add.text(CARD.w - 26, CARD.h - 22, fresh ? 'BEGIN  ›' : 'CONTINUE  ›', display(14, color)).setOrigin(1, 0.5);
    c.add(cta);

    const go = () => {
      sfx.unlock();
      sfx.confirm();
      switchCareer(mode);
      goTo(this, 'menu');
    };
    const zone = this.add.zone(CARD.w / 2, CARD.h / 2, CARD.w, CARD.h).setInteractive({ useHandCursor: true });
    c.add(zone);
    const item = {
      container: c,
      setFocused: (on: boolean) => {
        draw(on);
        this.tweens.add({ targets: c, y: CARD.y - (on ? 6 : 0), duration: 160, ease: 'Quad.Out' });
        this.tweens.add({ targets: cta, x: CARD.w - 26 + (on ? 6 : 0), duration: 160, ease: 'Quad.Out' });
      },
      activate: go,
      adjust: undefined as ((d: -1 | 1) => void) | undefined,
    };
    zone.on('pointerover', () => this.nav.focus(this.nav.items.indexOf(item)));
    zone.on('pointerup', go);
    return item;
  }

  private settings(): void {
    this.nav.enabled = false;
    openSettings(this, () => { this.nav.enabled = true; });
  }

  private credits(): void {
    this.nav.enabled = false;
    const layer = this.add.container(0, 0).setDepth(100).setAlpha(0);
    layer.add(this.add.rectangle(640, 360, 1280, 720, 0x000000, 0.6).setInteractive());
    layer.add(panel(this, 340, 150, 600, 420));
    layer.add(this.add.text(640, 190, 'CREDITS', display(22, TEXT)).setOrigin(0.5));
    layer.add(this.add.text(640, 236, [
      'BREACH',
      'A top-down tactical game set in Port Ardley.',
      '',
      'Built with Phaser 3, TypeScript and Vite.',
      'Every sound is synthesised in the browser.',
      '',
      'Fonts: Barlow Condensed and JetBrains Mono,',
      'both under the SIL Open Font License.',
      '',
      'Port Ardley, its people and its cases are fictional.',
    ].join('\n'), style(13, DIM, { align: 'center', lineSpacing: 6 })).setOrigin(0.5, 0));
    let nav: KeyNav;
    const close = () => {
      sfx.back();
      nav.destroy();
      this.tweens.add({ targets: layer, alpha: 0, duration: 140, onComplete: () => { layer.destroy(); this.nav.enabled = true; } });
    };
    const back = new Button(this, 640, 530, 200, 40, 'BACK', close, { size: 15 });
    layer.add(back.container);
    nav = new KeyNav(this, [back], close);
    back.nav = nav;
    this.tweens.add({ targets: layer, alpha: 1, duration: 160 });
  }
}

/** Rank insignia: one chevron per rank above Recruit, stacked. */
export function insignia(scene: Phaser.Scene, x: number, y: number, rank: number, color: number): Phaser.GameObjects.Graphics {
  const g = scene.add.graphics({ x, y });
  for (let i = 0; i < Math.max(rank, 0); i++) {
    const cy = -i * 9 + (rank - 1) * 4.5;
    g.lineStyle(3, color, 0.95);
    g.beginPath();
    g.moveTo(-12, cy + 5);
    g.lineTo(0, cy - 3);
    g.lineTo(12, cy + 5);
    g.strokePath();
  }
  if (rank === 0) {
    g.lineStyle(2, color, 0.5);
    g.strokeCircle(0, 0, 9);
  }
  return g;
}
