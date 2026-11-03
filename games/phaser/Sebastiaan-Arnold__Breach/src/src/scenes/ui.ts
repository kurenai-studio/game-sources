import Phaser from 'phaser';
import { DISPLAY_FONT, FONT, RENDER_SCALE } from '../config';
import { sfx } from '../game/audio';
import { saveSettings, settings } from '../game/settings';

export const TEXT = '#e5e7eb';
export const DIM = '#9ca3af';
export const FAINT = '#64748b';
export const ACCENT = '#60a5fa';
export const GOLD = '#facc15';
export const RED = '#ef4444';

/** Panel and line colours shared by every screen. */
export const UI = {
  void: 0x07090c,
  panel: 0x0b1220,
  panelHi: 0x111c30,
  line: 0x1e3a5f,
  accent: 0x60a5fa,
  primary: 0x1d4ed8,
  primaryHi: 0x2563eb,
  red: 0xef4444,
  gold: 0xfacc15,
} as const;

type Style = Phaser.Types.GameObjects.Text.TextStyle;

/** Screen text style: crisp at any render scale, with a soft shadow so it reads over the game. */
export function style(size: number, color = TEXT, extra: Style = {}): Style {
  return {
    fontFamily: FONT, fontSize: `${size}px`, color, resolution: 2,
    shadow: { offsetX: 0, offsetY: 1, color: '#000000', blur: 4, fill: true },
    ...extra,
  };
}

/** Headings and labels: the condensed display face, tracked out. Pass upper-case text. */
export function display(size: number, color = TEXT, extra: Style = {}): Style {
  return style(size, color, { fontFamily: DISPLAY_FONT, fontStyle: 'bold', letterSpacing: Math.round(size * 0.12), ...extra });
}

/** Screens are laid out in logical 1280x720 coordinates whatever the render scale. */
export function setupScreenCamera(scene: Phaser.Scene): void {
  scene.cameras.main.setOrigin(0, 0).setZoom(RENDER_SCALE);
}

/** Every screen fades in from black. */
export function fadeIn(scene: Phaser.Scene, ms = 280): void {
  scene.cameras.main.fadeIn(ms, 7, 9, 12);
}

/** Fades the current screen out, then starts `key`. Repeated calls while fading are ignored. */
export function goTo(scene: Phaser.Scene, key: string, data?: object, ms = 220): void {
  if (scene.data.get('leaving')) return;
  scene.data.set('leaving', true);
  scene.cameras.main.fadeOut(ms, 7, 9, 12);
  scene.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => {
    scene.data.set('leaving', false);
    scene.scene.start(key, data);
  });
}

/** Anything a keyboard can move between and activate. */
export interface Focusable {
  setFocused(on: boolean): void;
  activate(): void;
  /** Left and right on a setting. */
  adjust?(dir: -1 | 1): void;
}

/**
 * Keyboard (and mouse) navigation over a list of items: up and down (or W and S) move, Enter or
 * Space activates, left and right adjust, Escape backs out. Hovering with the mouse moves the
 * focus too, so both ways of using a menu agree on what's selected.
 */
export class KeyNav {
  index = 0;
  enabled = true;

  private onKey = (e: KeyboardEvent) => this.key(e);

  constructor(private scene: Phaser.Scene, public items: Focusable[], private onBack?: () => void, start = 0) {
    this.index = Math.max(0, Math.min(start, items.length - 1));
    scene.input.keyboard?.on('keydown', this.onKey);
    scene.events.once('shutdown', () => this.destroy());
    this.refresh();
  }

  destroy(): void {
    this.enabled = false;
    this.scene.input.keyboard?.off('keydown', this.onKey);
  }

  focus(i: number, quiet = false): void {
    if (i === this.index || i < 0 || i >= this.items.length) return;
    this.index = i;
    if (!quiet) sfx.hover();
    this.refresh();
  }

  refresh(): void {
    this.items.forEach((it, i) => it.setFocused(i === this.index));
  }

  private key(e: KeyboardEvent): void {
    if (!this.enabled || this.scene.data.get('leaving')) return;
    const n = this.items.length;
    switch (e.code) {
      case 'ArrowUp': case 'KeyW':
        this.focus((this.index - 1 + n) % n);
        break;
      case 'ArrowDown': case 'KeyS':
        this.focus((this.index + 1) % n);
        break;
      case 'ArrowLeft': case 'KeyA':
        this.items[this.index]?.adjust?.(-1);
        break;
      case 'ArrowRight': case 'KeyD':
        this.items[this.index]?.adjust?.(1);
        break;
      case 'Enter': case 'Space':
        this.items[this.index]?.activate();
        break;
      case 'Escape':
        this.onBack?.();
        break;
    }
  }
}

export interface ButtonOptions {
  /** Filled in the accent colour: the main action on a screen. */
  primary?: boolean;
  size?: number;
  /** Text alignment inside the button. */
  align?: 'left' | 'center';
  nav?: KeyNav;
}

/**
 * A framed button. Hover or keyboard focus brightens it, slides the label a touch and lights a
 * bar on its left edge; clicking plays a confirm.
 */
export class Button implements Focusable {
  readonly container: Phaser.GameObjects.Container;
  readonly label: Phaser.GameObjects.Text;
  private bg: Phaser.GameObjects.Graphics;
  private focused = false;
  private disabled = false;
  nav?: KeyNav;
  /** Left and right, when the button sits in a row with others. */
  adjust?: (dir: -1 | 1) => void;

  constructor(
    private scene: Phaser.Scene,
    x: number,
    y: number,
    private w: number,
    private h: number,
    text: string,
    private onClick: () => void,
    private opts: ButtonOptions = {},
  ) {
    this.bg = scene.add.graphics();
    const size = opts.size ?? 15;
    const left = opts.align === 'left';
    this.label = scene.add.text(left ? -w / 2 + 18 : 0, 0, text, display(size, TEXT)).setOrigin(left ? 0 : 0.5, 0.5);
    this.container = scene.add.container(x, y, [this.bg, this.label]);
    const zone = scene.add.zone(0, 0, w, h).setInteractive({ useHandCursor: true });
    this.container.add(zone);
    zone.on('pointerover', () => {
      if (this.nav) this.nav.focus(this.nav.items.indexOf(this));
      else {
        sfx.hover();
        this.setFocused(true);
      }
    });
    zone.on('pointerout', () => {
      if (!this.nav) this.setFocused(false);
    });
    zone.on('pointerup', () => this.activate());
    this.nav = opts.nav;
    this.draw();
  }

  setText(text: string): this {
    this.label.setText(text);
    return this;
  }

  setDisabled(d: boolean): this {
    this.disabled = d;
    this.draw();
    return this;
  }

  setFocused(on: boolean): void {
    if (on === this.focused) return;
    this.focused = on;
    this.draw();
    const left = this.opts.align === 'left';
    this.scene.tweens.add({ targets: this.label, x: (left ? -this.w / 2 + 18 : 0) + (on ? 5 : 0), duration: 120, ease: 'Quad.Out' });
  }

  activate(): void {
    if (this.disabled || this.scene.data.get('leaving')) return;
    sfx.unlock();
    sfx.confirm();
    this.scene.tweens.add({ targets: this.container, scaleX: 0.97, scaleY: 0.97, duration: 60, yoyo: true });
    this.onClick();
  }

  private draw(): void {
    const g = this.bg, w = this.w, h = this.h, on = this.focused && !this.disabled;
    g.clear();
    if (this.opts.primary) {
      g.fillStyle(on ? UI.primaryHi : UI.primary, this.disabled ? 0.4 : 1);
      g.fillRoundedRect(-w / 2, -h / 2, w, h, 6);
      if (on) {
        g.lineStyle(2, 0x93c5fd, 0.9);
        g.strokeRoundedRect(-w / 2, -h / 2, w, h, 6);
      }
    } else {
      g.fillStyle(on ? UI.panelHi : UI.panel, on ? 0.95 : 0.75);
      g.fillRoundedRect(-w / 2, -h / 2, w, h, 6);
      g.lineStyle(1, on ? UI.accent : UI.line, on ? 0.9 : 0.8);
      g.strokeRoundedRect(-w / 2, -h / 2, w, h, 6);
      if (on) {
        g.fillStyle(UI.accent, 1);
        g.fillRect(-w / 2, -h / 2 + 6, 3, h - 12);
      }
    }
    this.label.setColor(this.disabled ? FAINT : on && !this.opts.primary ? '#ffffff' : TEXT);
  }
}

/** A panel: dark fill, a thin border and an optional accent strip down the left. */
export function panel(scene: Phaser.Scene, x: number, y: number, w: number, h: number, strip?: number): Phaser.GameObjects.Graphics {
  const g = scene.add.graphics();
  g.fillStyle(UI.panel, 0.92);
  g.fillRoundedRect(x, y, w, h, 10);
  g.lineStyle(1, UI.line, 1);
  g.strokeRoundedRect(x, y, w, h, 10);
  if (strip !== undefined) {
    g.fillStyle(strip, 1);
    g.fillRect(x, y + 10, 3, h - 20);
  }
  return g;
}

/** Fades and slides objects in one after another, for a screen's entrance. */
export function stagger(scene: Phaser.Scene, targets: Phaser.GameObjects.GameObject[], delay = 0, step = 60, dy = 12): void {
  targets.forEach((t, i) => {
    const o = t as unknown as Phaser.GameObjects.Components.Alpha & { y: number };
    const y = o.y;
    o.setAlpha(0);
    o.y = y + dy;
    scene.tweens.add({ targets: t, alpha: 1, y, delay: delay + i * step, duration: 360, ease: 'Cubic.Out' });
  });
}

/**
 * The settings, as a modal panel over the current screen: volume, blood, screen shake and
 * fullscreen. Used from the title screen and the pause menu alike.
 */
export function openSettings(scene: Phaser.Scene, onClose: () => void, depth = 100): void {
  const cx = 640, cy = 360, w = 520, h = 352;
  const layer = scene.add.container(0, 0).setDepth(depth);
  const shade = scene.add.rectangle(cx, cy, 1280, 720, 0x000000, 0.6).setInteractive();
  layer.add([shade, panel(scene, cx - w / 2, cy - h / 2, w, h)]);
  layer.add(scene.add.text(cx, cy - h / 2 + 34, 'SETTINGS', display(22, TEXT)).setOrigin(0.5));

  const pct = (v: number) => `${Math.round(v * 100)}%`;
  // `wrap`: a plain click on the row goes round from the top back to the bottom.
  const rows: { label: string; value: () => string; change: (dir: -1 | 1, wrap?: boolean) => void }[] = [
    {
      label: 'VOLUME', value: () => pct(settings.volume), change: (d, wrap) => {
        const v = wrap && settings.volume >= 1 ? 0 : settings.volume + d * 0.1;
        settings.volume = Math.round(Math.max(0, Math.min(1, v)) * 10) / 10;
        sfx.setVolume(settings.volume);
      },
    },
    { label: 'BLOOD', value: () => (settings.blood ? 'On' : 'Off'), change: () => { settings.blood = !settings.blood; } },
    { label: 'SCREEN SHAKE', value: () => (settings.shake ? 'On' : 'Off'), change: () => { settings.shake = !settings.shake; } },
    { label: 'FULLSCREEN', value: () => (scene.scale.isFullscreen ? 'On' : 'Off'), change: () => scene.scale.toggleFullscreen() },
  ];

  let nav: KeyNav;
  const refreshers: (() => void)[] = [];
  const refreshAll = () => refreshers.forEach((f) => f());
  const close = () => {
    saveSettings();
    sfx.back();
    nav.destroy();
    scene.scale.off('enterfullscreen', refreshAll);
    scene.scale.off('leavefullscreen', refreshAll);
    // Hand the keyboard back once the panel has gone, so this key press isn't seen twice.
    scene.tweens.add({ targets: layer, alpha: 0, duration: 140, onComplete: () => { layer.destroy(); onClose(); } });
  };
  const items: Focusable[] = rows.map((r, i) => {
    const y = cy - h / 2 + 96 + i * 50;
    // A click on ‹ steps down, on › steps up; anywhere else on the row steps round.
    const click = () => {
      const p = scene.input.activePointer;
      const px = scene.cameras.main.getWorldPoint(p.x, p.y).x;
      const right = cx + w / 2 - 50, left = right - value.width;
      if (px > left - 8 && px < left + value.width / 2) r.change(-1);
      else if (px >= left + value.width / 2 && px < right + 8) r.change(1);
      else r.change(1, true);
      refresh();
    };
    const btn = new Button(scene, cx, y, w - 64, 40, r.label, click, { align: 'left', size: 14 });
    const value = scene.add.text(w / 2 - 50, 0, '', style(14, ACCENT)).setOrigin(1, 0.5);
    btn.container.add(value);
    layer.add(btn.container);
    const refresh = () => value.setText(`‹  ${r.value()}  ›`);
    refresh();
    refreshers.push(refresh);
    return Object.assign(btn, {
      adjust: (dir: -1 | 1) => {
        r.change(dir);
        sfx.select();
        refresh();
      },
    });
  });
  const back = new Button(scene, cx, cy + h / 2 - 40, 200, 40, 'BACK', close, { size: 15 });
  layer.add(back.container);
  items.push(back);
  nav = new KeyNav(scene, items, close);
  for (const it of items) (it as Button).nav = nav;
  // Fullscreen changes a moment after it's asked for (or from the browser): keep the row honest.
  scene.scale.on('enterfullscreen', refreshAll);
  scene.scale.on('leavefullscreen', refreshAll);
  layer.setAlpha(0);
  scene.tweens.add({ targets: layer, alpha: 1, duration: 160 });
}
