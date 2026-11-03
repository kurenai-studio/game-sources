import Phaser from 'phaser';
import { VIEW_H, VIEW_W } from '../config';
import { sfx } from '../game/audio';
import type { GameScene, HudState, Outcome } from './GameScene';
import { ACCENT, Button, DIM, display, FAINT, GOLD, KeyNav, openSettings, panel, RED, setupScreenCamera, stagger, style, TEXT, UI } from './ui';

/** How long a station's tutorial text stays up after entering it, then how long it fades. */
const TUTORIAL_HOLD = 9;
const TUTORIAL_FADE = 1.2;
const TOAST_LIFE = 3;
const BAR_HEIGHT = 74;

const CONTROLS: [string, string][] = [
  ['Move', 'WASD'],
  ['Sprint (loud)', 'Shift'],
  ['Aim / fire', 'Mouse / left click'],
  ['Open or close a door', 'E or right click'],
  ['Secure a civilian', 'Hold E next to them'],
  ['Reload', 'R'],
  ['Primary / pistol', '1 / 2'],
  ['Scope (sniper rifle)', 'Hold Space'],
  ['Breach charge (Captain)', 'G, facing a wall'],
  ['Skip intro', 'Space'],
  ['Frame rate', 'F3'],
];

interface Toast {
  text: Phaser.GameObjects.Text;
  age: number;
}

/**
 * Screen-space UI on top of the game. Deliberately minimal: ammo and armour in a corner, short
 * messages and, only in the tutorial, a station card that fades once read. Settings and
 * controls live in the Esc menu.
 */
export class HudScene extends Phaser.Scene {
  private tutorial!: Phaser.GameObjects.Container;
  private tutorialTitle!: Phaser.GameObjects.Text;
  private tutorialBody!: Phaser.GameObjects.Text;
  private tutorialAge = 0;
  private lastStation: string | undefined;

  private weaponName!: Phaser.GameObjects.Text;
  private chargeKey!: Phaser.GameObjects.Text;
  private reserve!: Phaser.GameObjects.Text;
  private gfx!: Phaser.GameObjects.Graphics;
  private overlay!: Phaser.GameObjects.Graphics;
  private subtitle!: Phaser.GameObjects.Text;
  private skipHint!: Phaser.GameObjects.Text;
  private securing!: Phaser.GameObjects.Text;
  private clock!: Phaser.GameObjects.Text;

  private menu!: Phaser.GameObjects.Container;
  private menuNav!: KeyNav;
  private settingsOpen = false;
  private debrief!: Phaser.GameObjects.Container;
  private debriefNav?: KeyNav;
  private shownOutcome: Outcome | null = null;
  private toasts: Toast[] = [];
  private fps!: Phaser.GameObjects.Text;
  private cardShown = false;
  /** The title card while it's up; it goes as soon as the intro ends. */
  private card: Phaser.GameObjects.GameObject[] = [];

  constructor() {
    super('hud');
  }

  private get game_(): GameScene {
    return this.scene.get('game') as GameScene;
  }

  create(): void {
    setupScreenCamera(this);
    this.tutorialAge = 0;
    this.lastStation = undefined;
    this.shownOutcome = null;
    this.settingsOpen = false;
    this.cardShown = false;
    this.card = [];
    this.toasts = [];

    this.overlay = this.add.graphics();
    this.tutorialTitle = this.add.text(0, 0, '', style(13, ACCENT, { fontStyle: 'bold' }));
    this.tutorialBody = this.add.text(0, 22, '', style(13, TEXT, { lineSpacing: 5, wordWrap: { width: 460 } }));
    this.tutorial = this.add.container(28, 24, [this.tutorialTitle, this.tutorialBody]).setAlpha(0);

    this.gfx = this.add.graphics();
    this.weaponName = this.add.text(VIEW_W - 28, VIEW_H - 63, '', display(12, DIM)).setOrigin(1, 0);
    this.reserve = this.add.text(VIEW_W - 28, VIEW_H - 44, '', style(15, TEXT, { fontStyle: 'bold' })).setOrigin(1, 0);
    this.chargeKey = this.add.text(VIEW_W - 28 - 66 - 34, VIEW_H - 81, 'G', display(11, DIM)).setOrigin(1, 0.5);
    this.subtitle = this.add.text(VIEW_W / 2, VIEW_H - BAR_HEIGHT - 34, '', style(16, TEXT)).setOrigin(0.5, 0);
    this.skipHint = this.add.text(VIEW_W - 28, VIEW_H - 44, 'SPACE TO SKIP', display(11, DIM)).setOrigin(1, 0);
    this.securing = this.add.text(VIEW_W / 2, VIEW_H * 0.62, 'Securing', style(12, TEXT)).setOrigin(0.5, 0);
    this.clock = this.add.text(VIEW_W / 2, 24, '', style(18, TEXT, { fontStyle: 'bold' })).setOrigin(0.5, 0);

    // F3 toggles a frame-rate readout, handy for checking performance on different machines.
    this.fps = this.add.text(VIEW_W - 16, 12, '', style(11, DIM)).setOrigin(1, 0).setVisible(false);
    this.input.keyboard?.addCapture('F3');
    this.input.keyboard?.on('keydown-F3', () => this.fps.setVisible(!this.fps.visible));
    this.input.keyboard?.on('keydown-ESC', () => this.toggleMenu());

    this.menu = this.buildMenu();
    this.debrief = this.buildDebrief();

    const onToast = (text: string) => this.showToast(text);
    this.game.events.on('toast', onToast);
    // Tabbing away mid-mission pauses it.
    const onBlur = () => {
      if (!this.menu.visible && !this.debrief.visible) this.toggleMenu();
    };
    this.game.events.on(Phaser.Core.Events.BLUR, onBlur);
    this.events.once('shutdown', () => {
      this.game.events.off('toast', onToast);
      this.game.events.off(Phaser.Core.Events.BLUR, onBlur);
      this.input.setDefaultCursor('default');
    });
  }

  update(_time: number, deltaMs: number): void {
    const dt = deltaMs / 1000;
    const s = this.game_.hud;
    if (!s) return;

    this.updateTutorial(s, dt);
    if (this.fps.visible) this.fps.setText(`${Math.round(this.game.loop.actualFps)} fps  ·  ${this.scale.width}x${this.scale.height}`);

    const cut = s.cutscene;
    if (cut && !this.cardShown) this.showCard(s.card);
    if (!cut && this.card.length) this.hideCard();
    this.gfx.clear();
    this.overlay.clear();
    if (!cut) this.drawStatus(s);
    this.drawReticle(s);
    for (const t of [this.weaponName, this.reserve]) t.setVisible(!cut);
    this.chargeKey.setVisible(!cut && !!s.charge?.ready);
    this.drawOverlay(s);
    this.subtitle.setText(cut?.subtitle ?? '');
    this.skipHint.setVisible(!!cut);
    this.securing.setVisible(s.securing !== null);
    // A countdown (the hostage clock, or a guard at an alarm panel) sits alone at the top.
    this.clock.setVisible(s.clock !== null && !cut);
    if (s.clock !== null) {
      const t = Math.ceil(s.clock.seconds);
      this.clock.setText(`${s.clock.label}  ${Math.floor(t / 60)}:${String(t % 60).padStart(2, '0')}`).setColor(t <= 10 ? RED : TEXT);
    }

    this.toasts = this.toasts.filter((t) => {
      t.age += dt;
      t.text.setAlpha(Math.min(1, t.age / 0.15, (TOAST_LIFE - t.age) / 0.6));
      if (t.age >= TOAST_LIFE) t.text.destroy();
      return t.age < TOAST_LIFE;
    });
    this.toasts.forEach((t, i) => t.text.setY(VIEW_H * 0.72 + i * 22));

    if (s.outcome && s.outcome !== this.shownOutcome) this.showDebrief(s.outcome);
  }

  // ---------------------------------------------------------------- in-game readouts

  private updateTutorial(s: HudState, dt: number): void {
    // Tutorial card: appears on entering a station, fades once it has had time to be read.
    const station = s.tutorial ? s.station : undefined;
    if (station?.id !== this.lastStation) {
      this.lastStation = station?.id;
      this.tutorialAge = 0;
      if (station) {
        this.tutorialTitle.setText(station.name.toUpperCase());
        this.tutorialBody.setText(station.brief.join('\n'));
      }
    }
    if (!this.menu.visible) this.tutorialAge += dt;
    const fade = 1 - Phaser.Math.Clamp((this.tutorialAge - TUTORIAL_HOLD) / TUTORIAL_FADE, 0, 1);
    this.tutorial.setAlpha(station ? fade : 0);
  }

  /**
   * The title card over the intro: the case name typed out in the top-left corner, then where
   * and when, held for a few seconds and faded.
   */
  private showCard(card: HudState['card']): void {
    this.cardShown = true;
    const x = 56, y = 110;
    const rule = this.add.rectangle(x, y + 50, 0, 2, UI.accent, 0.9).setOrigin(0, 0.5);
    const title = this.add.text(x, y, '', display(34, '#f8fafc'));
    const sub = this.add.text(x, y + 62, card.sub, display(14, ACCENT)).setAlpha(0);
    const all = [rule, title, sub];
    this.card = all;
    const text = card.title.toUpperCase();
    let shown = 0;
    this.time.addEvent({
      delay: 38, repeat: text.length - 1, startAt: 0,
      callback: () => {
        if (!title.active) return;
        shown++;
        title.setText(text.slice(0, shown));
        if (shown % 2) sfx.hover();
      },
    });
    this.tweens.add({ targets: rule, width: 260, duration: 500, ease: 'Cubic.Out', delay: 200 });
    this.tweens.add({ targets: sub, alpha: 1, duration: 400, delay: 200 + text.length * 38 });
    this.tweens.add({ targets: all, alpha: 0, duration: 700, delay: 4200, onComplete: () => this.hideCard() });
  }

  /** The intro is over (or skipped): the title card makes way for the game and its tutorial. */
  private hideCard(): void {
    const all = this.card;
    this.card = [];
    this.tweens.killTweensOf(all);
    this.tweens.add({ targets: all, alpha: 0, duration: 250, onComplete: () => all.forEach((o) => o.destroy()) });
  }

  /**
   * The crosshair, in place of the system cursor while the operator is in control: four ticks
   * that open up as the aim wanders, dimmed during a reload.
   */
  private drawReticle(s: HudState): void {
    const show = !!s.aim && !this.menu.visible && !this.debrief.visible;
    this.input.setDefaultCursor(show ? 'none' : 'default');
    if (!show || !s.aim) return;
    const p = this.input.activePointer;
    const cam = this.cameras.main;
    const x = p.x / cam.zoom, y = p.y / cam.zoom;
    const gap = 5 + s.aim.spread * 2.2, len = 6;
    const g = this.gfx;
    const a = s.aim.reloading ? 0.35 : 0.9;
    for (const [w, c, al] of [[3, 0x000000, 0.45 * a], [1.5, 0xffffff, a]] as const) {
      g.lineStyle(w, c, al);
      g.lineBetween(x - gap - len, y, x - gap, y);
      g.lineBetween(x + gap, y, x + gap + len, y);
      g.lineBetween(x, y - gap - len, x, y - gap);
      g.lineBetween(x, y + gap, x, y + gap + len);
    }
    g.fillStyle(0xffffff, a);
    g.fillCircle(x, y, 1.2);
  }

  /** Ammo as a row of rounds with spare rounds beside it; armour and health above. */
  private drawStatus(s: HudState): void {
    const g = this.gfx;
    const w = s.weapon;
    const round = w.magSize > 15 ? 3 : 4;
    const gap = 2;
    const right = VIEW_W - 28 - this.reserve.width - 12;
    const y = VIEW_H - 41;
    const shown = w.reload !== null ? Math.round(w.magSize * w.reload) : w.mag;
    for (let i = 0; i < w.magSize; i++) {
      const x = right - (w.magSize - i) * (round + gap);
      const color = w.reload !== null ? 0x60a5fa : w.mag === 0 ? 0xef4444 : 0xe5e7eb;
      g.fillStyle(0x000000, 0.45);
      g.fillRect(x + 1, y + 1, round, 14);
      g.fillStyle(color, i < shown ? 0.95 : 0.15);
      g.fillRect(x, y, round, 14);
    }
    this.weaponName.setText(w.name.toUpperCase());
    this.reserve.setText(`${w.reserve}`);

    // Armour (blue) then health (white), right-aligned above the weapon name.
    const pips = [{ on: s.armor > 0, color: 0x60a5fa }, { on: s.health > 1, color: 0xe5e7eb }, { on: s.health > 0, color: 0xe5e7eb }];
    pips.forEach((p, i) => {
      const x = VIEW_W - 28 - (pips.length - i) * 22 + 4;
      g.fillStyle(0x000000, 0.45);
      g.fillRect(x + 1, VIEW_H - 83, 18, 6);
      g.fillStyle(p.on ? p.color : 0xef4444, p.on ? 0.95 : 0.35);
      g.fillRect(x, VIEW_H - 84, 18, 6);
    });

    // The breach charge, left of the pips: amber while in hand, flashing red on the fuse.
    if (s.charge) {
      const x = VIEW_W - 28 - 66 - 28, y = VIEW_H - 86;
      const color = s.charge.fuse !== null ? (Math.sin(s.charge.fuse * 30) > 0 ? 0xef4444 : 0x7f1d1d) : s.charge.ready ? 0xf59e0b : 0x3f3f46;
      g.fillStyle(0x000000, 0.45);
      g.fillRect(x + 1, y + 1, 16, 10);
      g.fillStyle(color, s.charge.ready || s.charge.fuse !== null ? 0.95 : 0.5);
      g.fillRect(x, y, 16, 10);
      g.fillStyle(0x000000, 0.35);
      g.fillRect(x + 3, y + 3, 10, 2);
    }

    if (s.securing !== null) {
      g.fillStyle(0x000000, 0.5);
      g.fillRect(VIEW_W / 2 - 60, VIEW_H * 0.62 + 20, 120, 4);
      g.fillStyle(0xfacc15, 1);
      g.fillRect(VIEW_W / 2 - 60, VIEW_H * 0.62 + 20, 120 * s.securing, 4);
    }
  }

  private drawOverlay(s: HudState): void {
    const g = this.overlay;
    // A red flash at the edges of the screen when hit.
    if (s.hurt > 0) {
      for (let i = 0; i < 6; i++) {
        const inset = i * 14;
        g.lineStyle(14, 0xb91c1c, s.hurt * (0.4 - i * 0.06));
        g.strokeRect(inset + 7, inset + 7, VIEW_W - inset * 2 - 14, VIEW_H - inset * 2 - 14);
      }
    }
    // Letterbox bars for the intro.
    const bars = s.cutscene?.bars ?? 0;
    if (bars > 0) {
      g.fillStyle(0x000000, 1);
      g.fillRect(0, 0, VIEW_W, BAR_HEIGHT * bars);
      g.fillRect(0, VIEW_H - BAR_HEIGHT * bars, VIEW_W, BAR_HEIGHT * bars);
    }
  }

  private showToast(text: string): void {
    const t = this.add.text(VIEW_W / 2, VIEW_H * 0.72, text, style(14, TEXT)).setOrigin(0.5, 0).setAlpha(0);
    this.toasts.push({ text: t, age: 0 });
    if (this.toasts.length > 3) this.toasts.shift()!.text.destroy();
  }

  // ---------------------------------------------------------------- menu and debrief

  private toggleMenu(): void {
    if (this.debrief.visible || this.settingsOpen) return;
    const open = !this.menu.visible;
    this.menu.setVisible(open);
    this.menuNav.enabled = open;
    if (open) {
      this.scene.pause('game');
      sfx.select();
      this.menu.setAlpha(0);
      this.tweens.add({ targets: this.menu, alpha: 1, duration: 140 });
    } else {
      this.scene.resume('game');
    }
  }

  private buildMenu(): Phaser.GameObjects.Container {
    const cx = VIEW_W / 2;
    const menu = this.add.container(0, 0).setDepth(80).setVisible(false);
    menu.add(this.add.rectangle(cx, VIEW_H / 2, VIEW_W, VIEW_H, 0x05070a, 0.82).setInteractive());
    menu.add(this.add.text(cx, 112, 'PAUSED', display(46, TEXT)).setOrigin(0.5));
    menu.add(this.add.text(cx, 152, this.game_.levelName.toUpperCase(), display(13, ACCENT)).setOrigin(0.5));

    // In a realism career there's no restarting a mission, and quitting one ends the career.
    const realism = this.game_.realism;
    let quitArmed = false;
    const entries: [string, () => void][] = [
      ['RESUME', () => this.toggleMenu()],
      ['SETTINGS', () => {
        this.settingsOpen = true;
        this.menuNav.enabled = false;
        openSettings(this, () => {
          this.settingsOpen = false;
          this.menuNav.enabled = true;
        }, 120);
      }],
      ...(realism ? [] : [['RESTART', () => { this.scene.resume('game'); this.game_.retry(); }] as [string, () => void]]),
    ];
    const buttons = entries.map(([label, action], i) => new Button(this, cx, 206 + i * 52, 300, 42, label, action, { size: 15, primary: i === 0 }));
    const quit = new Button(this, cx, 206 + entries.length * 52, 300, 42, realism ? 'QUIT (ENDS YOUR CAREER)' : 'QUIT TO MENU', () => {
      if (realism && !quitArmed) {
        quitArmed = true;
        quit.setText('CLICK AGAIN TO END YOUR CAREER');
        return;
      }
      this.scene.resume('game');
      if (realism) this.game_.abandon();
      else this.game_.toMenu();
    }, { size: 15 });
    buttons.push(quit);
    for (const b of buttons) menu.add(b.container);
    this.menuNav = new KeyNav(this, buttons);
    this.menuNav.enabled = false;
    for (const b of buttons) b.nav = this.menuNav;

    // The controls, in two columns.
    const top = 206 + buttons.length * 52 + 20;
    menu.add(this.add.text(cx, top, 'CONTROLS', display(12, FAINT)).setOrigin(0.5));
    const half = Math.ceil(CONTROLS.length / 2);
    CONTROLS.forEach(([what, key], i) => {
      const col = i < half ? -1 : 1, row = i % half;
      const x = cx + col * 170, y = top + 26 + row * 21;
      menu.add(this.add.text(x - 8, y, what, style(12, DIM)).setOrigin(1, 0));
      menu.add(this.add.text(x + 8, y, key, style(12, TEXT)));
    });
    return menu;
  }

  private buildDebrief(): Phaser.GameObjects.Container {
    return this.add.container(0, 0).setDepth(90).setVisible(false);
  }

  /**
   * The debrief: the result, then the stars stamped on one by one, the numbers, the case note
   * and the way on. Laid out to its content and centred.
   */
  private showDebrief(o: Outcome): void {
    this.shownOutcome = o;
    this.menu.setVisible(false);
    this.menuNav.enabled = false;
    const d = this.debrief;
    d.removeAll(true);
    d.setVisible(true).setAlpha(0);
    const cx = VIEW_W / 2, W = 600, pad = 30;

    // Measure first, then place: everything is stacked from the top of the panel.
    const parts: { obj: Phaser.GameObjects.GameObject & { y: number }; at: number }[] = [];
    let h = 0;
    const put = (obj: Phaser.GameObjects.GameObject & { y: number }, height: number) => {
      parts.push({ obj, at: h });
      h += height;
    };
    put(this.add.text(cx, 0, `DEBRIEF  ·  ${this.game_.levelName.toUpperCase()}`, display(13, ACCENT)).setOrigin(0.5, 0), 26);
    const title = this.add.text(cx, 0, o.title.toUpperCase(), display(40, o.success ? TEXT : RED)).setOrigin(0.5, 0);
    // A long result ("Range qualification complete") steps down until it fits the panel.
    for (let size = 40; title.width > W - pad * 2 && size > 20; size -= 2) title.setFontSize(size).setLetterSpacing(Math.round(size * 0.12));
    put(title, 62);
    const stars: Phaser.GameObjects.Text[] = [];
    if (o.stars) {
      const row = this.add.container(cx, 0);
      o.stars.forEach((earned, i) => {
        const t = this.add.text((i - 1) * 64, 26, '★', style(46, earned ? GOLD : '#283548')).setOrigin(0.5).setScale(0);
        stars.push(t);
        row.add(t);
      });
      put(row, 64);
    }
    const lines: Phaser.GameObjects.Text[] = [];
    for (const line of o.lines) {
      if (!line) {
        h += 8;
        continue;
      }
      const t = this.add.text(cx - 210, 0, line, style(14, TEXT));
      lines.push(t);
      put(t, 22);
    }
    if (o.note) {
      h += 12;
      const label = this.add.text(cx - 210, 0, 'CASE NOTE', display(11, FAINT));
      put(label, 20);
      const note = this.add.text(cx - 210, 0, o.note, style(13, DIM, { fontStyle: 'italic', wordWrap: { width: 420 }, lineSpacing: 3 }));
      put(note, note.height);
      lines.push(label, note);
    }
    h += 26;
    const buttonsAt = h;
    h += 44;

    const top = (VIEW_H - h) / 2;
    d.add(this.add.rectangle(cx, VIEW_H / 2, VIEW_W, VIEW_H, 0x05070a, 0.78).setInteractive());
    d.add(panel(this, cx - W / 2, top - pad, W, h + pad * 2, o.success ? UI.accent : UI.red));
    for (const p of parts) {
      p.obj.y = top + p.at;
      d.add(p.obj);
    }

    const go = (label: string, action: () => void, primary: boolean, x: number) =>
      new Button(this, x, top + buttonsAt + 22, 210, 44, label, action, { size: 15, primary });
    const buttons = o.careerOver
      ? [go('BACK TO THE ACADEMY', () => this.game_.toMenu(), true, cx)]
      : o.success
        ? [go('CONTINUE', () => this.game_.toMenu(), true, cx - 115), go('PLAY AGAIN', () => this.game_.retry(), false, cx + 115)]
        : [go('RETRY', () => this.game_.retry(), true, cx - 115), go('MENU', () => this.game_.toMenu(), false, cx + 115)];
    for (const b of buttons) d.add(b.container);
    this.debriefNav = new KeyNav(this, buttons);
    buttons.forEach((b, i) => {
      b.nav = this.debriefNav;
      b.adjust = (dir) => this.debriefNav!.focus(Math.max(0, Math.min(buttons.length - 1, i + dir)));
    });

    // The entrance: panel in, title settles, stars stamp, then the numbers.
    this.tweens.add({ targets: d, alpha: 1, duration: 220 });
    title.setScale(1.15);
    this.tweens.add({ targets: title, scale: 1, duration: 420, ease: 'Cubic.Out' });
    stars.forEach((t, i) => {
      const earned = o.stars![i];
      this.tweens.add({
        targets: t, scale: 1, delay: 380 + i * 240, duration: 320, ease: 'Back.Out',
        onStart: () => (earned ? sfx.star(i) : sfx.select()),
      });
    });
    stagger(this, lines, 380 + stars.length * 240 + 120, 45, 6);
    stagger(this, buttons.map((b) => b.container), 380 + stars.length * 240 + 220 + lines.length * 45, 80, 8);
  }
}
