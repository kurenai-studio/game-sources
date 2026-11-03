import Phaser from 'phaser';
import { COLORS } from '../config';
import { sfx } from '../game/audio';
import { campaignStars, endedCareer, isUnlocked, newProgress, progress, saveProgress } from '../game/progress';
import { levelById } from '../levels';
import { CAMPAIGNS, RANKS, type CampaignDef } from '../levels/campaigns';
import { attractBackdrop } from './backdrop';
import { insignia } from './TitleScene';
import {
  ACCENT, Button, DIM, display, FAINT, fadeIn, GOLD, goTo, KeyNav, panel, RED, setupScreenCamera, stagger, style, TEXT, UI,
  type Focusable,
} from './ui';

const LEFT = { x: 56, w: 360, top: 132, h: 70 };
const RIGHT = { x: 448, w: 776, top: 132 };
const ROW = 54;

/**
 * The campaign screen: campaigns down the left (one per rank), the chosen campaign's story,
 * promotion progress and cases on the right. Up and down pick a case, left and right a campaign.
 * Opens on the current campaign.
 */
export class MenuScene extends Phaser.Scene {
  private selected = 0;
  private cards: { draw: (selected: boolean, hover: boolean) => void }[] = [];
  private caseLayer!: Phaser.GameObjects.Container;
  private nav?: KeyNav;
  private footer: Button[] = [];

  constructor() {
    super('menu');
  }

  create(): void {
    setupScreenCamera(this);
    this.cameras.main.setBackgroundColor(COLORS.void);
    attractBackdrop(this, 0.8);
    fadeIn(this);
    sfx.menuAmbience(true);
    this.cards = [];
    this.footer = [];

    // Header: the career and where it stands.
    const stars = Object.values(progress.stars).reduce((a, b) => a + b, 0);
    const career = progress.realism ? 'REALISM CAREER' : 'NORMAL CAREER';
    const careerColor = progress.realism ? RED : ACCENT;
    const head: Phaser.GameObjects.GameObject[] = [
      this.add.text(LEFT.x, 52, 'BREACH', display(26, '#f8fafc', { letterSpacing: 8 })),
      this.add.text(LEFT.x + 136, 60, career, display(13, careerColor)),
      this.add.text(1224, 52, RANKS[progress.rank].toUpperCase(), display(26, TEXT)).setOrigin(1, 0),
      this.add.text(1224, 86, `${stars} ★   ·   ${progress.completed.length} cases closed`, style(12, DIM)).setOrigin(1, 0),
    ];
    // The insignia sits clear of both lines; at the top ranks the chevrons are as tall as the pair.
    const lines = Math.max((head[2] as Phaser.GameObjects.Text).width, (head[3] as Phaser.GameObjects.Text).width);
    head.push(insignia(this, 1224 - lines - 32, 76, progress.rank, progress.realism ? UI.red : UI.accent));
    head.push(this.add.rectangle(640, 116, 1168, 1, UI.line, 1));

    // Campaign cards.
    const cardObjs = CAMPAIGNS.map((c, i) => this.campaignCard(c, i));
    this.caseLayer = this.add.container(0, 0);

    const current = CAMPAIGNS.map((c, i) => ({ c, i })).filter(({ c }) => progress.rank >= c.rank).at(-1);
    this.select(current?.i ?? 0, true);

    // Footer: back, and the career's own options.
    const back = new Button(this, LEFT.x + 90, 664, 180, 40, '‹  BACK', () => this.back(), { size: 14 });
    let armed = false;
    const reset = new Button(this, 1224 - 120, 664, 240, 40, 'RESET THIS CAREER', () => {
      if (!armed) {
        armed = true;
        reset.setText('CLICK AGAIN TO RESET');
        return;
      }
      Object.assign(progress, newProgress(progress.realism));
      saveProgress(progress);
      this.scene.restart();
    }, { size: 13 });
    this.footer.push(back, reset);
    // A fresh realism career can skip the academy and start as an Officer.
    if (progress.realism && progress.rank === 0 && progress.completed.length === 0) {
      const skip = new Button(this, 640, 664, 300, 40, 'SKIP THE ACADEMY: START AS OFFICER', () => {
        progress.rank = 1;
        saveProgress(progress);
        this.scene.restart();
      }, { size: 13 });
      this.footer.push(skip);
    }

    // A realism career that just ended gets one notice.
    const notices: Phaser.GameObjects.GameObject[] = [];
    const ended = endedCareer.record;
    if (ended) {
      const why = { down: 'went down at', quit: 'quit a mission at', left: 'left a mission unfinished at' }[endedCareer.reason];
      notices.push(this.add.text(640, 622, [
        `Realism career over: you ${why} ${levelById(ended.levelId).name}.`,
        `Rank reached: ${RANKS[ended.rank]}, ${ended.stars} ★. A new career starts as Recruit.`,
      ].join('\n'), style(12, RED, { align: 'center', lineSpacing: 4 })).setOrigin(0.5, 1));
      endedCareer.record = null;
    }

    this.input.keyboard?.on('keydown-ESC', () => this.back());
    stagger(this, head, 0, 40, 8);
    stagger(this, cardObjs, 120, 60, 10);
    stagger(this, [...notices, ...this.footer.map((b) => b.container)], 400, 60, 8);
  }

  private back(): void {
    sfx.back();
    goTo(this, 'title');
  }

  /** A campaign on the left: title, rank, and stars earned against what's on offer. */
  private campaignCard(c: CampaignDef, i: number): Phaser.GameObjects.Container {
    const open = progress.rank >= c.rank;
    const y = LEFT.top + i * (LEFT.h + 8);
    const box = this.add.container(LEFT.x, y);
    const bg = this.add.graphics();
    const stars = campaignStars(progress, c), max = c.levels.length * 3;
    const draw = (selected: boolean, hover: boolean) => {
      bg.clear();
      bg.fillStyle(selected ? UI.panelHi : UI.panel, selected ? 0.97 : hover ? 0.92 : 0.8);
      bg.fillRoundedRect(0, 0, LEFT.w, LEFT.h, 8);
      bg.lineStyle(1, selected ? UI.accent : UI.line, selected ? 1 : 0.9);
      bg.strokeRoundedRect(0, 0, LEFT.w, LEFT.h, 8);
      if (selected) {
        bg.fillStyle(UI.accent, 1);
        bg.fillRect(0, 10, 3, LEFT.h - 20);
      }
      // Stars earned out of the campaign's total.
      bg.fillStyle(0x1f2937, 1);
      bg.fillRoundedRect(20, LEFT.h - 16, LEFT.w - 40, 3, 1.5);
      if (stars) {
        bg.fillStyle(UI.gold, open ? 0.85 : 0.3);
        bg.fillRoundedRect(20, LEFT.h - 16, (LEFT.w - 40) * (stars / max), 3, 1.5);
      }
    };
    box.add(bg);
    box.add(this.add.text(20, 14, c.title.toUpperCase(), display(20, open ? TEXT : FAINT)));
    box.add(this.add.text(20, 40, open ? RANKS[c.rank] : `Requires ${RANKS[c.rank]}`, style(11, open ? DIM : FAINT)));
    box.add(this.add.text(LEFT.w - 20, 18, open ? `${stars} / ${max} ★` : 'LOCKED', open ? style(12, stars ? GOLD : FAINT) : display(12, FAINT)).setOrigin(1, 0));
    const card = { draw };
    this.cards.push(card);
    draw(false, false);
    if (open) {
      const zone = this.add.zone(LEFT.w / 2, LEFT.h / 2, LEFT.w, LEFT.h).setInteractive({ useHandCursor: true });
      box.add(zone);
      zone.on('pointerover', () => i !== this.selected && draw(false, true));
      zone.on('pointerout', () => draw(i === this.selected, false));
      zone.on('pointerup', () => this.select(i));
    }
    return box;
  }

  private select(i: number, quiet = false): void {
    if (!quiet && i !== this.selected) sfx.select();
    this.selected = i;
    this.cards.forEach((c, k) => c.draw(k === i, false));
    this.caseLayer.removeAll(true);
    this.nav?.destroy();

    const c = CAMPAIGNS[i];
    const L = this.caseLayer;
    const promoted = progress.rank > c.rank;
    const stars = campaignStars(progress, c), max = c.levels.length * 3;
    const h = 120 + c.levels.length * ROW + 24;
    L.add(panel(this, RIGHT.x, RIGHT.top, RIGHT.w, h));
    L.add(this.add.text(RIGHT.x + 28, RIGHT.top + 22, c.title.toUpperCase(), display(30, TEXT)));
    L.add(this.add.text(RIGHT.x + RIGHT.w - 28, RIGHT.top + 30, RANKS[c.rank].toUpperCase(), display(13, ACCENT)).setOrigin(1, 0));
    L.add(this.add.text(RIGHT.x + 28, RIGHT.top + 62, c.blurb, style(12, DIM)));
    // Promotion: what it takes, and how close.
    const need = promoted ? 'PROMOTED' : `PROMOTION: EVERY CASE AND ${c.promotion.minStars} ★`;
    L.add(this.add.text(RIGHT.x + 28, RIGHT.top + 88, need, display(11, promoted ? GOLD : FAINT)));
    const bar = this.add.graphics();
    const bx = RIGHT.x + 300, bw = RIGHT.w - 300 - 28;
    bar.fillStyle(0x1f2937, 1);
    bar.fillRoundedRect(bx, RIGHT.top + 94, bw, 4, 2);
    bar.fillStyle(UI.gold, 0.85);
    if (stars) bar.fillRoundedRect(bx, RIGHT.top + 94, bw * (stars / max), 4, 2);
    // The promotion threshold, marked on the bar.
    bar.fillStyle(0xffffff, 0.6);
    bar.fillRect(bx + bw * (c.promotion.minStars / max) - 1, RIGHT.top + 90, 2, 12);
    L.add(bar);

    const rows = c.levels.map((id, k) => this.caseRow(id, k, RIGHT.top + 120 + k * ROW));
    L.add(rows.flatMap((r) => r.objects));
    const open = rows.filter((r) => r.focusable).map((r) => r.focusable!);
    // Up and down move through the cases; left and right change campaign.
    const step = (d: -1 | 1) => {
      let n = this.selected + d;
      while (n >= 0 && n < CAMPAIGNS.length && progress.rank < CAMPAIGNS[n].rank) n += d;
      if (n >= 0 && n < CAMPAIGNS.length) this.select(n);
    };
    for (const f of open) f.adjust = step;
    // Start on the first case not yet completed.
    const firstNew = Math.max(0, open.findIndex((f) => !progress.completed.includes(f.id)));
    this.nav = new KeyNav(this, open, undefined, firstNew);
    for (const f of open) f.nav = this.nav;
    if (!quiet) stagger(this, rows.flatMap((r) => r.objects), 0, 18, 6);
  }

  /** One case: its number, name, where and when, and the best stars earned. */
  private caseRow(id: string, k: number, y: number): { objects: Phaser.GameObjects.GameObject[]; focusable?: Focusable & { id: string; nav?: KeyNav; adjust?: (d: -1 | 1) => void } } {
    const level = levelById(id);
    const unlocked = isUnlocked(progress, id);
    const stars = progress.stars[id] ?? 0;
    const x = RIGHT.x + 16, w = RIGHT.w - 32;
    const bg = this.add.graphics();
    const draw = (on: boolean) => {
      bg.clear();
      if (!on) return;
      bg.fillStyle(UI.panelHi, 1);
      bg.fillRoundedRect(x, y, w, ROW - 6, 6);
      bg.fillStyle(UI.accent, 1);
      bg.fillRect(x, y + 8, 3, ROW - 22);
    };
    const m = level.mission;
    const num = this.add.text(x + 22, y + (ROW - 6) / 2, String(k + 1).padStart(2, '0'), display(18, unlocked ? FAINT : '#334155')).setOrigin(0, 0.5);
    const name = this.add.text(x + 66, y + 8, level.name.toUpperCase(), display(19, unlocked ? TEXT : '#475569'));
    const where = this.add.text(x + 66, y + 32, m ? `${m.location}  ·  ${m.time}` : 'Training  ·  Port Ardley Police Academy', style(11, unlocked ? DIM : '#475569'));
    const right = unlocked
      ? this.add.text(x + w - 20, y + (ROW - 6) / 2, '★'.repeat(stars) + '☆'.repeat(3 - stars), style(17, stars ? GOLD : '#334155')).setOrigin(1, 0.5)
      : this.add.text(x + w - 20, y + (ROW - 6) / 2, 'LOCKED', display(12, '#475569')).setOrigin(1, 0.5);
    const objects: Phaser.GameObjects.GameObject[] = [bg, num, name, where, right];
    if (!unlocked) return { objects };

    const play = () => {
      sfx.unlock();
      sfx.confirm();
      if (level.mission) goTo(this, 'briefing', { levelId: id });
      else {
        sfx.menuAmbience(false);
        goTo(this, 'game', { levelId: id });
      }
    };
    const focusable = {
      id,
      nav: undefined as KeyNav | undefined,
      adjust: undefined as ((d: -1 | 1) => void) | undefined,
      setFocused: (on: boolean) => {
        draw(on);
        this.tweens.add({ targets: name, x: x + 66 + (on ? 6 : 0), duration: 120, ease: 'Quad.Out' });
      },
      activate: play,
    };
    const zone = this.add.zone(x + w / 2, y + (ROW - 6) / 2, w, ROW - 6).setInteractive({ useHandCursor: true });
    zone.on('pointerover', () => focusable.nav?.focus(focusable.nav.items.indexOf(focusable)));
    zone.on('pointerup', play);
    objects.push(zone);
    return { objects, focusable };
  }
}
