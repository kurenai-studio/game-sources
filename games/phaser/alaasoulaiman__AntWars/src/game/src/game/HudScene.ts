// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The HUD over the Yard: the thumb stick (anywhere on the screen), the round and health readouts, banners, the nest shop and the death screen.
// It has its own camera, so the Yard's screen shake never shakes the numbers.
import * as Phaser from 'phaser';
import { BASE_ANT, LINES, PERKS, canBuy, canBuyLine, lineCard, lineOpen, linePrice, lineStep, perkCount, perkSpec, type LineId, type PerkId } from '../sim/economy';
import { PICK_READ_MS, powerLine, powerSpec, type PowerId } from '../sim/growth';
import { sheetOpen } from '../sim/pause';
import { LADDER_NAME, UPGRADES, canBuyUpgrade, nextCost, upgradeLine, upgradeSpec, type Ladder, type UpgradeId } from '../sim/colony';
import { applyUpdate, buildStamp, updateReady } from '../pwa/pwa';
import { browserStore } from '../sim/best';
import { dayLabel } from '../sim/daily';
import { attachAudio, isMuted, toggleMute } from './audio';
import { HOWTO_ITEMS, readHowToSeen, writeHowToSeen } from './howto';
import { PRESS_SLOP_PX, STICK_RADIUS, TapTracker, ThumbStick, type StickReading } from './joystick';
import { NEST_BACK_H, NEST_PLAY_H, PICK_CARD_H, PICK_GAP, SHOP_CARD_H, SHOP_CARD_W, ladderLine, lowHealth, nestLayout, pickLayout, pickPlace, shopCell, shopLayout, titleLayout, type SheetPlace, type TitleRow } from './layout';
import {
  HP_BAR,
  STATS_HEAD_H,
  STATS_PANEL_FILL,
  TOP_STRIP_H,
  bossBar,
  levelBar,
  muteButton,
  statsHit,
  statsLayout,
  statsPanelPlan,
  statsShown,
  type StatsFitLevel,
  type StatsLineKind,
  type StatsPlace,
} from './layout';
import { statsSheet, type StatRow, type StatsSheet } from '../sim/stats';
import type { Banner, GameScene, Snapshot } from './GameScene';

const FONT = '"Arial Rounded MT Bold", "Arial Black", "Helvetica Neue", Arial, sans-serif';
/** The death screen holds this long before a tap restarts, so a thumb still on the glass cannot skip the result. */
const DEATH_TAP_GUARD_MS = 1200;

function style(
  size: number,
  color: string,
  extra: Phaser.Types.GameObjects.Text.TextStyle = {},
): Phaser.Types.GameObjects.Text.TextStyle {
  return {
    fontFamily: FONT,
    fontSize: `${size}px`,
    fontStyle: 'bold',
    color,
    stroke: '#1a1207',
    strokeThickness: Math.max(4, Math.round(size / 6)),
    resolution: 2,
    ...extra,
  };
}

function fmt(n: number): string {
  return Math.floor(n)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/** One card of the nest shop in the break: a one time perk, or (slice 4) a repeatable line with its step and price. */
interface Card {
  perk: PerkId | null;
  line: LineId | null;
  price: number;
  bg: Phaser.GameObjects.Rectangle;
  /** The name, the plain line (a perk's blurb, a line's step now and next) and the price. */
  texts: Phaser.GameObjects.Text[];
  flashUntil: number;
  flashOk: boolean;
}

/** One card of the level up sheet: a power's icon, name, one line effect and how many the run already has. */
interface PickCard {
  bg: Phaser.GameObjects.Rectangle;
  icon: Phaser.GameObjects.Image;
  name: Phaser.GameObjects.Text;
  line: Phaser.GameObjects.Text;
  count: Phaser.GameObjects.Text;
  id: PowerId | null;
}

/** One card of the nest screen between runs: an upgrade's name, its next step, its count and the one price. */
interface NestCard {
  id: UpgradeId;
  bg: Phaser.GameObjects.Rectangle;
  stripe: Phaser.GameObjects.Rectangle;
  name: Phaser.GameObjects.Text;
  line: Phaser.GameObjects.Text;
  count: Phaser.GameObjects.Text;
  price: Phaser.GameObjects.Text;
  flashUntil: number;
  flashOk: boolean;
}

/** What a press on a button is for. Every one acts only on a tap (TapTracker). */
type Press =
  | { kind: 'shop'; card: Card }
  | { kind: 'pick'; card: PickCard }
  | { kind: 'title'; action: 'continue' | 'play' | 'daily' | 'ladder' | 'nest' }
  | { kind: 'nest'; card: NestCard }
  | { kind: 'nestBtn'; action: 'play' | 'back' }
  | { kind: 'death'; action: 'again' | 'nest' }
  | { kind: 'mute' }
  | { kind: 'update' }
  | { kind: 'howto'; action: 'open' | 'close' }
  | { kind: 'stats'; action: 'toggle' | 'close' };

/** Lane N1: the colour of each kind of line on the stats panel (layout.ts statsPanelPlan places them). */
const STATS_COLOR: Readonly<Record<StatsLineKind, string>> = {
  label: '#ffd34d',
  value: '#ffffff',
  note: '#cfe8c4',
  head: '#ffd34d',
  item: '#ffffff',
  more: '#cfe8c4',
  empty: '#cfe8c4',
};
/** Lane N1: the most lines the panel draws (a long run's full list fits in it before the plan folds the list). */
const STATS_LINE_POOL = 64;


function showFps(): boolean {
  try {
    return new URLSearchParams(window.location.search).has('fps');
  } catch {
    return false;
  }
}

export class HudScene extends Phaser.Scene {
  /** Read by the Yard every frame: a unit direction while the thumb is out of the dead zone. */
  readonly stick = { active: false, x: 0, y: 0 };

  private world!: GameScene;
  private readonly thumb = new ThumbStick();
  /** Lane N1, M3: where the stick's knob was last drawn (on the ring toward a thumb past it), for the smoke's read. */
  private readonly stickKnob = { x: 0, y: 0 };
  /** Presses on the shop and pick cards: only a tap buys or picks (joystick.ts TapTracker). */
  private readonly taps = new TapTracker<Press>();
  private titleParts: Phaser.GameObjects.GameObject[] = [];
  private titleLine!: Phaser.GameObjects.Text;
  private titleSub!: Phaser.GameObjects.Text;
  private contBtn!: Phaser.GameObjects.Rectangle;
  private contText!: Phaser.GameObjects.Text;
  private playBtn!: Phaser.GameObjects.Rectangle;
  private playText!: Phaser.GameObjects.Text;
  private playSub!: Phaser.GameObjects.Text;
  private ladderBtn!: Phaser.GameObjects.Rectangle;
  private ladderText!: Phaser.GameObjects.Text;
  private ladderSub!: Phaser.GameObjects.Text;
  /** Lane G7, M3: the Daily challenge button, its date and its best round of the day. */
  private dailyBtn!: Phaser.GameObjects.Rectangle;
  private dailyText!: Phaser.GameObjects.Text;
  private dailySub!: Phaser.GameObjects.Text;
  private nestBtn!: Phaser.GameObjects.Rectangle;
  private nestBtnText!: Phaser.GameObjects.Text;
  private nestBtnSub!: Phaser.GameObjects.Text;
  /** Lane G7, M2: the ant under the name, the How to play button and its card (shown by itself once, on a phone's first title). */
  private titleAnt!: Phaser.GameObjects.Image;
  /** The running build's stamp, small in the top strip of the title (a phone can tell which build it runs). */
  private buildText!: Phaser.GameObjects.Text;
  private howtoBtn!: Phaser.GameObjects.Rectangle;
  private howtoParts: Phaser.GameObjects.GameObject[] = [];
  private howtoLines: string[] = [];
  private howtoClose!: Phaser.GameObjects.Rectangle;
  private howtoOpen = false;
  private howtoShownAt = -1;
  private howtoChecked = false;
  private titleKey = '';
  private titleShown = false;
  private titleShownAt = -1;
  /** The nest screen between runs, opened from the title or the death screen. */
  private nestParts: Phaser.GameObjects.GameObject[] = [];
  private nestCards: NestCard[] = [];
  private nestBank!: Phaser.GameObjects.Text;
  private nestPrice!: Phaser.GameObjects.Text;
  private nestNote!: Phaser.GameObjects.Text;
  private nestPlay!: Phaser.GameObjects.Rectangle;
  private nestBack!: Phaser.GameObjects.Rectangle;
  /** The sound switch, on every screen, and the low health vignette under the HUD. */
  private muteBtn!: Phaser.GameObjects.Image;
  /** Lane G7: the small "New version" line on the title and the death screen; a tap reloads into the new build. */
  private updateBg!: Phaser.GameObjects.Rectangle;
  private updateText!: Phaser.GameObjects.Text;
  private updateShown = false;
  private vignette!: Phaser.GameObjects.Image;
  private nestOpen = false;
  private nestFrom: 'title' | 'dead' = 'title';
  private nestShownAt = -1;
  private nestKey = '';
  private bossBar!: Phaser.GameObjects.Graphics;
  private bossText!: Phaser.GameObjects.Text;
  private lastBossKey = '';
  private levelBar!: Phaser.GameObjects.Graphics;
  private levelText!: Phaser.GameObjects.Text;
  private lastLevelKey = '';
  private pickTitle!: Phaser.GameObjects.Text;
  private pickCards: PickCard[] = [];
  private pickKey = '';
  private pickShownAt = -1;
  private pickShown = false;
  /** Where the sheet sits now: low under the thumb in a round, high in the break so the shop shows below it. */
  private pickPlaceNow: SheetPlace = 'low';
  private stickGfx!: Phaser.GameObjects.Graphics;
  private roundText!: Phaser.GameObjects.Text;
  private aliveText!: Phaser.GameObjects.Text;
  private nectarText!: Phaser.GameObjects.Text;
  private nectarIcon!: Phaser.GameObjects.Image;
  private hpBar!: Phaser.GameObjects.Graphics;
  private hpText!: Phaser.GameObjects.Text;
  private blessText!: Phaser.GameObjects.Text;
  private breakText!: Phaser.GameObjects.Text;
  private nestHint!: Phaser.GameObjects.Text;
  private arrow!: Phaser.GameObjects.Image;
  private bannerTitle!: Phaser.GameObjects.Text;
  private bannerSub!: Phaser.GameObjects.Text;
  private hint!: Phaser.GameObjects.Text;
  private shopTitle!: Phaser.GameObjects.Text;
  private shopLocked!: Phaser.GameObjects.Text;
  private cards: Card[] = [];
  private deathBg!: Phaser.GameObjects.Rectangle;
  private deathTexts: Array<Phaser.GameObjects.Text | Phaser.GameObjects.Rectangle> = [];
  /** The death screen's two buttons (Play again, the nest) and their texts: they show once a tap can act. */
  private deathAgain!: Phaser.GameObjects.Rectangle;
  private deathNest!: Phaser.GameObjects.Rectangle;
  private deathNestSub!: Phaser.GameObjects.Text;
  private deathButtons: Array<Phaser.GameObjects.Text | Phaser.GameObjects.Rectangle> = [];
  /** Back from the nest: the death screen returns without its guard (the thumb has long left the glass). */
  private deathReturn = false;
  private deathRound!: Phaser.GameObjects.Text;
  private deathBest!: Phaser.GameObjects.Text;
  private deathShownAt = -1;
  private fpsText: Phaser.GameObjects.Text | null = null;
  private fpsAt = 0;
  private lastHp = -1;
  private lastMax = -1;
  private bannerQueue: Banner[] = [];
  private bannerBusyUntil = 0;
  private hintGone = false;
  private shopShown = false;
  /** Lane N1, M2: the stats tab (sim/stats.ts): open or not (never saved), where it sits, what shows, and its parts. */
  private statsOpen = false;
  private statsPlace!: StatsPlace;
  private statsVis = { button: false, panel: false };
  private statsKey = '';
  private statsPanelH = 0;
  private statsSheetNow: StatsSheet | null = null;
  private statsBtnGfx!: Phaser.GameObjects.Graphics;
  private statsBtnText!: Phaser.GameObjects.Text;
  private statsGfx!: Phaser.GameObjects.Graphics;
  private statsTitle!: Phaser.GameObjects.Text;
  private statsBody!: Phaser.GameObjects.Container;
  /** The panel's lines (a pool, placed by layout.ts statsPanelPlan) and one hidden text the plan measures with. */
  private statsLines: Phaser.GameObjects.Text[] = [];
  private statsMeasure!: Phaser.GameObjects.Text;
  private statsLevel: StatsFitLevel = 'full';
  private statsHidden = 0;
  private statsPlanLines: Array<{ kind: StatsLineKind; text: string }> = [];

  constructor() {
    super('hud');
  }

  create(): void {
    this.world = this.scene.get('game') as GameScene;
    attachAudio(this.sound);
    this.stick.active = false;
    this.stick.x = 0;
    this.stick.y = 0;
    this.thumb.release();
    this.taps.clear();
    this.cards = [];
    this.deathTexts = [];
    this.deathButtons = [];
    this.deathReturn = false;
    this.deathShownAt = -1;
    this.fpsText = null;
    this.fpsAt = 0;
    this.lastHp = -1;
    this.lastMax = -1;
    this.bannerQueue = [];
    this.bannerBusyUntil = 0;
    this.hintGone = false;
    this.shopShown = false;
    this.lastLevelKey = '';
    this.lastBossKey = '';
    this.titleParts = [];
    this.titleKey = '';
    this.titleShown = false;
    this.titleShownAt = -1;
    this.howtoParts = [];
    this.howtoLines = [];
    this.howtoOpen = false;
    this.howtoShownAt = -1;
    this.howtoChecked = false;
    this.nestParts = [];
    this.nestCards = [];
    this.nestOpen = false;
    this.nestFrom = 'title';
    this.nestShownAt = -1;
    this.nestKey = '';
    this.pickCards = [];
    this.pickKey = '';
    this.pickShownAt = -1;
    this.pickShown = false;
    this.pickPlaceNow = 'low';

    const W = this.scale.width;
    const H = this.scale.height;

    // The low health vignette: one full screen picture drawn once (a red edge that fades in toward the middle), pulsing
    // under the HUD when health is low. One quad a frame, nothing allocated.
    const vKey = `vignette_${W}x${H}`;
    if (!this.textures.exists(vKey)) {
      const tex = this.textures.createCanvas(vKey, W, H);
      if (tex) {
        const c = tex.getContext();
        const gr = c.createRadialGradient(W / 2, H / 2, Math.min(W, H) * 0.3, W / 2, H / 2, Math.hypot(W, H) / 2);
        gr.addColorStop(0, 'rgba(210, 20, 20, 0)');
        gr.addColorStop(0.55, 'rgba(210, 20, 20, 0.22)');
        gr.addColorStop(1, 'rgba(150, 0, 0, 0.85)');
        c.fillStyle = gr;
        c.fillRect(0, 0, W, H);
        tex.refresh();
      }
    }
    this.vignette = this.add.image(0, 0, vKey).setOrigin(0).setDepth(-1).setAlpha(0).setVisible(false);
    this.add.rectangle(0, 0, W, TOP_STRIP_H, 0x000000, 0.3).setOrigin(0);
    // The sound switch sits in the top strip and above every screen (the title, the nest, the death screen too).
    const MB = muteButton(W);
    this.muteBtn = this.add.image(MB.x + MB.w / 2, MB.y + MB.h / 2, isMuted() ? 'sound_off' : 'sound_on').setDepth(95).setInteractive({ useHandCursor: true });
    this.roundText = this.add.text(24, 14, 'GET READY', style(46, '#ffffff'));
    this.aliveText = this.add.text(26, 72, '', style(26, '#e9f5e1'));
    this.nectarIcon = this.add.image(W - 32, 44, 'bead').setScale(1.8);
    this.nectarText = this.add.text(W - 58, 44, '0', style(44, '#ffd34d')).setOrigin(1, 0.5);
    this.hpBar = this.add.graphics();
    this.hpText = this.add.text(24 + 160, 125, '', style(20, '#ffffff')).setOrigin(0.5);
    // The level bar mirrors the health bar on the right: the level and the experience toward the next one.
    this.levelBar = this.add.graphics();
    this.levelText = this.add.text(W - 184, 125, '', style(20, '#ffffff')).setOrigin(0.5);
    this.blessText = this.add.text(W / 2, 180, '', style(28, '#ffe14d')).setOrigin(0.5);
    // The Anteater's big health bar, under the top strip while it lives.
    this.bossBar = this.add.graphics();
    this.bossText = this.add.text(W / 2, 217, '', style(22, '#ffffff')).setOrigin(0.5);
    this.breakText = this.add.text(W / 2, H * 0.2, '', style(42, '#ffffff')).setOrigin(0.5);
    this.nestHint = this.add.text(W / 2, H * 0.2 + 50, '', style(28, '#ffe07a')).setOrigin(0.5);
    this.arrow = this.add.image(0, 0, 'arrow').setVisible(false).setScale(1.3);
    this.bannerTitle = this.add.text(W / 2, H * 0.33, '', style(80, '#ffffff')).setOrigin(0.5).setAlpha(0);
    this.bannerSub = this.add.text(W / 2, H * 0.33 + 72, '', style(32, '#ffffff')).setOrigin(0.5).setAlpha(0);
    this.hint = this.add
      .text(W / 2, H - 60, 'Drag anywhere to move.\nStand still to shoot at full speed.', style(28, '#ffffff', { align: 'center' }))
      .setOrigin(0.5, 1);

    // Slice 4: the shop is a grid of two columns (layout.ts shopCell). The repeatable lines sit on the left, the extra
    // dart over the three perks on the right, the perks in the cells slices 1 to 3 gave them. A tap on a card buys it;
    // a drag that starts on a card is the stick, as anywhere else.
    const cw = SHOP_CARD_W;
    const ch = SHOP_CARD_H;
    const SL = shopLayout(H);
    this.shopTitle = this.add.text(W / 2, SL.titleY, 'NEST SHOP', style(30, '#ffe07a')).setOrigin(0.5).setVisible(false);
    // During a round the shop never opens: an ant that has left the nest this round and walks back in sees this plain
    // line where the shop sits, and no cards (sim/economy.ts shopState; not the ant still standing where the round found it).
    this.shopLocked = this.add
      .text(W - 12, SL.titleY, 'Shop opens between rounds', style(30, '#ffe07a'))
      .setOrigin(1, 0.5)
      .setVisible(false);
    const addCard = (col: number, row: number, perk: PerkId | null, line: LineId | null, name: string, blurb: string, price: number) => {
      const { x, y } = shopCell(col, row, W, H);
      const bg = this.add.rectangle(x, y, cw, ch, 0x2b1d0e, 0.94).setOrigin(0).setStrokeStyle(4, 0xffd34d);
      bg.setInteractive({ useHandCursor: true });
      const tName = this.add.text(x + 16, y + 10, name, style(28, '#ffffff'));
      const tBlurb = this.add.text(x + 16, y + 54, blurb, style(20, '#e9f5e1', { strokeThickness: 3 }));
      // A line card's step runs the full width, so its price sits on the name row; a perk keeps its price low right.
      const tPrice = line
        ? this.add.text(x + cw - 14, y + 13, '', style(24, '#ffd34d')).setOrigin(1, 0)
        : this.add.text(x + cw - 14, y + ch - 8, fmt(price), style(24, '#ffd34d')).setOrigin(1, 1);
      this.cards.push({ perk, line, price, bg, texts: [tName, tBlurb, tPrice], flashUntil: 0, flashOk: false });
    };
    LINES.forEach((l, i) => {
      if (l.id === 'darts') addCard(1, 0, null, l.id, l.name, '', 0);
      else addCard(0, i, null, l.id, l.name, '', 0);
    });
    PERKS.forEach((perk, i) => addCard(1, i + 1, perk.id, null, perk.name, perk.blurb, perk.price));
    this.setShopVisible(false);

    // The level up sheet: three full width cards low on the screen. A tap on a card takes that power; a drag that
    // starts on a card is the stick, as anywhere else. It takes the shop's place while a pick waits.
    const pickTop = pickLayout('low', H).cardsTop;
    this.pickTitle = this.add.text(W / 2, pickTop - 32, '', style(34, '#c9b6ff')).setOrigin(0.5).setDepth(60);
    for (let i = 0; i < 3; i++) {
      const y = pickTop + i * (PICK_CARD_H + PICK_GAP);
      const bg = this.add.rectangle(12, y, W - 24, PICK_CARD_H, 0x221a3d, 0.95).setOrigin(0).setStrokeStyle(4, 0xb39dff).setDepth(60);
      const icon = this.add.image(12 + 54, y + PICK_CARD_H / 2, 'pow_jaw').setScale(1.25).setDepth(61);
      const name = this.add.text(118, y + 12, '', style(30, '#ffffff')).setDepth(61);
      const line = this.add.text(118, y + 60, '', style(22, '#e7e0ff', { strokeThickness: 3 })).setDepth(61);
      const count = this.add.text(W - 28, y + 14, '', style(22, '#c9b6ff')).setOrigin(1, 0).setDepth(61);
      this.pickCards.push({ bg, icon, name, line, count, id: null });
    }
    this.setPickVisible(false);

    // The death screen: the round reached, the ladder, the nectar banked (Colony) or the best round (Pure), and two
    // buttons, Play again and the nest. Both act on a tap, once the screen has been up DEATH_TAP_GUARD_MS.
    this.deathBg = this.add.rectangle(0, 0, W, H, 0x0b0b0b, 0.8).setOrigin(0).setDepth(80);
    const title = this.add.text(W / 2, H * 0.19, 'THE ANT FELL', style(72, '#ff6b5e')).setOrigin(0.5);
    this.deathRound = this.add.text(W / 2, H * 0.19 + 92, '', style(44, '#ffffff')).setOrigin(0.5);
    this.deathBest = this.add.text(W / 2, H * 0.19 + 146, '', style(30, '#ffe07a', { align: 'center' })).setOrigin(0.5, 0);
    this.deathAgain = this.add.rectangle(W / 2, H * 0.64, 470, 120, 0x2f7d32, 1).setStrokeStyle(6, 0x9effa1);
    const tAgain = this.add.text(W / 2, H * 0.64, 'PLAY AGAIN', style(54, '#ffffff')).setOrigin(0.5);
    this.deathNest = this.add.rectangle(W / 2, H * 0.79, 350, 96, 0x3a2a14, 1).setStrokeStyle(4, 0xffd34d);
    const tDeathNest = this.add.text(W / 2, H * 0.79, 'THE NEST', style(40, '#ffe07a')).setOrigin(0.5);
    this.deathNestSub = this.add.text(W / 2, H * 0.79 + 72, '', style(22, '#e8d9a8')).setOrigin(0.5);
    this.deathButtons = [this.deathAgain, tAgain, this.deathNest, tDeathNest, this.deathNestSub];
    this.deathTexts = [title, this.deathRound, this.deathBest, ...this.deathButtons];
    for (const t of this.deathTexts) t.setDepth(81);
    for (const t of [tAgain, tDeathNest]) t.setDepth(82);
    this.setDeathVisible(false);

    // The title before every run: Continue (only when a saved run waits), Play, the ladder switch and the nest. Every
    // button acts on a tap. Play with a saved run waiting starts a new run and ends the saved one. Lane G7, M2: the
    // Yard's own look (its grass along the edges, the ant between two predators under the name), a short line, the How
    // to play button in the top strip; the places come from layout.ts titleLayout.
    const TL = titleLayout(H, false);
    const rowH = (row: TitleRow) => Math.min(...[false, true].map((sv) => titleLayout(H, sv).rows.find((r) => r.row === row)?.h ?? 999));
    const tBg = this.add.rectangle(0, 0, W, H, 0x0b1a0d, 0.9).setOrigin(0).setDepth(85).setInteractive();
    const deco: Phaser.GameObjects.GameObject[] = [];
    const drng = new Phaser.Math.RandomDataGenerator(['title-v1']);
    for (let i = 0; i < 18; i++) {
      const x = 16 + (i * (W - 32)) / 17 + drng.between(-12, 12);
      const key = drng.pick(['tuft', 'tuft', 'clover', 'flower', 'tuft']);
      deco.push(this.add.image(x, H - drng.between(10, 34), key).setScale(drng.realInRange(1.2, 1.8)).setAlpha(0.9).setDepth(85.5));
    }
    const tName = this.add.text(W / 2, TL.nameY, 'ANT WARS', style(104, '#ffd34d')).setOrigin(0.5).setDepth(86);
    const tTag = this.add.text(W / 2, TL.tagY, 'One ant. Every predator in the Yard.', style(26, '#d8f5d0')).setOrigin(0.5).setDepth(86);
    this.titleAnt = this.add.image(W / 2, TL.artY, 'ant0').setScale(2).setRotation(-Math.PI / 2).setDepth(86);
    const foeL = this.add.image(W / 2 - 200, TL.artY + 14, 'armyAnt0').setScale(1.6).setRotation(-0.25).setDepth(86);
    const foeR = this.add.image(W / 2 + 200, TL.artY - 8, 'wasp0').setScale(1.5).setRotation(Math.PI + 0.2).setDepth(86);
    this.tweens.add({ targets: this.titleAnt, y: TL.artY - 10, yoyo: true, repeat: -1, duration: 650, ease: 'Sine.easeInOut' });
    this.tweens.add({ targets: [foeL, foeR], scale: '+=0.08', yoyo: true, repeat: -1, duration: 900, ease: 'Sine.easeInOut' });
    this.titleLine = this.add.text(W / 2, TL.bestY, '', style(28, '#ffffff', { align: 'center' })).setOrigin(0.5).setDepth(86);
    this.contBtn = this.add.rectangle(W / 2, 0, 470, rowH('cont'), 0x2f7d32, 1).setStrokeStyle(6, 0x9effa1).setDepth(86);
    this.contText = this.add.text(W / 2, 0, 'CONTINUE', style(56, '#ffffff')).setOrigin(0.5).setDepth(87);
    this.titleSub = this.add.text(W / 2, 0, '', style(22, '#d8f5d0')).setOrigin(0.5).setDepth(86);
    this.playBtn = this.add.rectangle(W / 2, 0, 470, rowH('play'), 0x2f7d32, 1).setStrokeStyle(6, 0x9effa1).setDepth(86);
    this.playText = this.add.text(W / 2, 0, 'PLAY', style(60, '#ffffff')).setOrigin(0.5).setDepth(87);
    this.playSub = this.add.text(W / 2, 0, '', style(22, '#d8f5d0')).setOrigin(0.5).setDepth(86);
    this.dailyBtn = this.add.rectangle(W / 2, 0, 470, rowH('daily'), 0x4a3008, 1).setStrokeStyle(5, 0xffd34d).setDepth(86);
    this.dailyText = this.add.text(W / 2, 0, 'DAILY CHALLENGE', style(44, '#ffe07a')).setOrigin(0.5).setDepth(87);
    this.dailyText.setScale(Math.min(1, 440 / Math.max(1, this.dailyText.width)));
    this.dailySub = this.add.text(W / 2, 0, '', style(22, '#ffe9a8')).setOrigin(0.5).setDepth(86);
    this.ladderBtn = this.add.rectangle(W / 2, 0, 470, rowH('ladder'), 0x1d2a44, 1).setStrokeStyle(5, 0x8fb8ff).setDepth(86);
    this.ladderText = this.add.text(W / 2, 0, '', style(40, '#ffffff')).setOrigin(0.5).setDepth(87);
    this.ladderSub = this.add.text(W / 2, 0, '', style(22, '#cfe0ff')).setOrigin(0.5).setDepth(86);
    this.nestBtn = this.add.rectangle(W / 2, 0, 350, rowH('nest'), 0x3a2a14, 1).setStrokeStyle(4, 0xffd34d).setDepth(86);
    this.nestBtnText = this.add.text(W / 2, 0, 'THE NEST', style(40, '#ffe07a')).setOrigin(0.5).setDepth(87);
    this.nestBtnSub = this.add.text(W / 2, 0, '', style(22, '#e8d9a8')).setOrigin(0.5).setDepth(86);
    // How to play, in the top strip on the left (the sound switch sits in its middle, the nectar on the right).
    this.howtoBtn = this.add.rectangle(128, 44, 224, 66, 0x1d2a44, 1).setStrokeStyle(4, 0x8fb8ff).setDepth(86);
    const tHow = this.add.text(128, 44, 'HOW TO PLAY', style(26, '#ffffff')).setOrigin(0.5).setDepth(87);
    tHow.setScale(Math.min(1, 204 / Math.max(1, tHow.width)));
    this.buildText = this.add.text(W - 22, 44, '', style(20, '#9fbf96', { strokeThickness: 3 })).setOrigin(1, 0.5).setDepth(87);
    this.titleParts = [
      tBg, ...deco, tName, tTag, this.titleAnt, foeL, foeR, this.titleLine, this.contBtn, this.contText, this.titleSub,
      this.playBtn, this.playText, this.playSub, this.dailyBtn, this.dailyText, this.dailySub, this.ladderBtn,
      this.ladderText, this.ladderSub, this.nestBtn, this.nestBtnText, this.nestBtnSub, this.howtoBtn, tHow, this.buildText,
    ];
    this.placeTitle(false);
    this.setTitleVisible(false);

    // Lane G7, M2: the How to play card over the title: the stick, the shop between rounds, the picks and the nest. It
    // opens by itself once, on the first title a phone sees (howto.ts), then from its button; GOT IT closes it.
    const cardTop = Math.round(H * 0.13);
    const cardBottom = Math.round(H * 0.89);
    const shade = this.add.rectangle(0, 0, W, H, 0x000000, 0.6).setOrigin(0).setDepth(98).setInteractive();
    const panel = this.add
      .rectangle(W / 2, (cardTop + cardBottom) / 2, W - 40, cardBottom - cardTop, 0x17301a, 0.98)
      .setStrokeStyle(6, 0x9effa1)
      .setDepth(98.5);
    const hTitle = this.add.text(W / 2, cardTop + 64, 'HOW TO PLAY', style(56, '#ffd34d')).setOrigin(0.5).setDepth(99);
    const closeY = cardBottom - 88;
    const rowsTop = cardTop + 132;
    const itemH = (closeY - 70 - rowsTop) / HOWTO_ITEMS.length;
    this.howtoParts = [shade, panel, hTitle];
    this.howtoLines = [];
    const ICON: Record<string, { key: string; scale: number; rot: number }> = {
      stick: { key: 'ant0', scale: 1.3, rot: -Math.PI / 2 },
      shop: { key: 'bead', scale: 2.6, rot: 0 },
      picks: { key: 'pow_jaw', scale: 1.25, rot: 0 },
      nest: { key: 'nest', scale: 0.38, rot: 0 },
    };
    HOWTO_ITEMS.forEach((item, i) => {
      const y = rowsTop + i * itemH;
      const ic = ICON[item.id];
      const icon = this.add.image(86, y + 46, ic.key).setScale(ic.scale).setRotation(ic.rot).setDepth(99);
      const name = this.add.text(150, y + 8, item.title, style(30, '#ffffff')).setDepth(99);
      const line = this.add
        .text(150, y + 50, item.line, style(23, '#e9f5e1', { strokeThickness: 3, wordWrap: { width: W - 150 - 48, useAdvancedWrap: true } }))
        .setDepth(99);
      this.howtoParts.push(icon, name, line);
      this.howtoLines.push(`${item.title}: ${item.line}`);
    });
    this.howtoClose = this.add.rectangle(W / 2, closeY, 360, 104, 0x2f7d32, 1).setStrokeStyle(6, 0x9effa1).setDepth(99);
    const tGot = this.add.text(W / 2, closeY, 'GOT IT', style(52, '#ffffff')).setOrigin(0.5).setDepth(100);
    this.howtoParts.push(this.howtoClose, tGot);
    this.setHowToVisible(false);

    // The nest screen between runs: the banked nectar and six permanent upgrades at one climbing price (sim/colony.ts).
    const NL = nestLayout(H);
    const nBg = this.add.rectangle(0, 0, W, H, 0x1a1006, 0.97).setOrigin(0).setDepth(88).setInteractive();
    const nTitle = this.add.text(W / 2, 140, 'THE NEST', style(76, '#ffd34d')).setOrigin(0.5).setDepth(89);
    this.nestBank = this.add.text(W / 2, 214, '', style(34, '#ffe9a8')).setOrigin(0.5).setDepth(89);
    this.nestPrice = this.add.text(W / 2, 262, '', style(24, '#e8d9a8')).setOrigin(0.5).setDepth(89);
    this.nestParts = [nBg, nTitle, this.nestBank, this.nestPrice];
    UPGRADES.forEach((u, i) => {
      const y = NL.cardsTop + i * (NL.cardH + NL.gap);
      const bg = this.add.rectangle(12, y, W - 24, NL.cardH, 0x2b1d0e, 0.96).setOrigin(0).setStrokeStyle(4, 0xffd34d).setDepth(89);
      const stripe = this.add.rectangle(14, y + 2, 16, NL.cardH - 4, u.color, 1).setOrigin(0).setDepth(90);
      const name = this.add.text(44, y + 10, u.name, style(30, '#ffffff')).setDepth(90);
      const line = this.add.text(44, y + NL.cardH - 44, '', style(22, '#e9f5e1', { strokeThickness: 3 })).setDepth(90);
      const count = this.add.text(W - 28, y + 12, '', style(22, '#ffe07a')).setOrigin(1, 0).setDepth(90);
      const price = this.add.text(W - 28, y + NL.cardH - 12, '', style(26, '#ffd34d')).setOrigin(1, 1).setDepth(90);
      this.nestCards.push({ id: u.id, bg, stripe, name, line, count, price, flashUntil: 0, flashOk: false });
      this.nestParts.push(bg, stripe, name, line, count, price);
    });
    this.nestNote = this.add.text(W / 2, NL.playY - NEST_PLAY_H / 2 - 30, '', style(22, '#cfe0ff')).setOrigin(0.5).setDepth(89);
    this.nestPlay = this.add.rectangle(W / 2, NL.playY, 470, NEST_PLAY_H, 0x2f7d32, 1).setStrokeStyle(6, 0x9effa1).setDepth(89);
    const nPlay = this.add.text(W / 2, NL.playY, 'PLAY', style(56, '#ffffff')).setOrigin(0.5).setDepth(90);
    this.nestBack = this.add.rectangle(W / 2, NL.backY, 300, NEST_BACK_H, 0x3a2a14, 1).setStrokeStyle(4, 0xffd34d).setDepth(89);
    const nBack = this.add.text(W / 2, NL.backY, 'Back', style(36, '#ffe07a')).setOrigin(0.5).setDepth(90);
    this.nestParts.push(this.nestNote, this.nestPlay, nPlay, this.nestBack, nBack);
    this.setNestVisible(false);

    // A new build waits behind the one running (src/pwa/pwa.ts): one small line low on the title and the death screen,
    // where a reload loses nothing; never in a round, so a thumb on the stick cannot reload by mistake.
    this.updateShown = false;
    this.updateBg = this.add.rectangle(W / 2, H - 52, W - 120, 64, 0x10240f, 0.96).setStrokeStyle(3, 0x9effa1).setDepth(96);
    this.updateText = this.add.text(W / 2, H - 52, 'New version ready: tap to reload', style(26, '#d8f5d0')).setOrigin(0.5).setDepth(97);
    this.updateText.setScale(Math.min(1, (W - 150) / Math.max(1, this.updateText.width)));
    this.updateBg.setVisible(false);
    this.updateText.setVisible(false);

    // Lane N1, M2: the stats tab. A small button at the top left in a run; a tap opens a see through
    // panel with the ant's numbers and every upgrade it owns (sim/stats.ts statsSheet), kept up to date; a second tap or
    // its x closes it, and so does Tab on a desk. The Yard runs on under it (it is no pick sheet), and nothing is saved.
    this.statsOpen = false;
    this.statsKey = '';
    this.statsVis = { button: false, panel: false };
    this.statsPanelH = 0;
    this.statsSheetNow = null;
    this.statsPlace = statsLayout(H);
    const SB = this.statsPlace.button;
    const SP = this.statsPlace.panel;
    this.statsBtnGfx = this.add.graphics().setDepth(1);
    this.statsBtnText = this.add.text(SB.x + SB.w / 2, SB.y + SB.h / 2, 'STATS', style(22, '#ffffff', { strokeThickness: 4 })).setOrigin(0.5).setDepth(1.1);
    this.statsBtnText.setScale(Math.min(1, (SB.w - 12) / Math.max(1, this.statsBtnText.width)));
    // The panel lies under the HUD's own words (a banner or the nest arrow shows over it). Its lines come placed and
    // wrapped from layout.ts statsPanelPlan, which measures them with the hidden text below in the same face.
    this.statsGfx = this.add.graphics().setDepth(-0.5);
    this.statsTitle = this.add.text(SP.x + 16, SP.y + 16, 'YOUR ANT', style(26, '#ffd34d')).setDepth(-0.4);
    this.statsBody = this.add.container(SP.x, SP.y + STATS_HEAD_H).setDepth(-0.4);
    this.statsLines = [];
    for (let i = 0; i < STATS_LINE_POOL; i++) {
      const t = this.add.text(0, 0, '', style(18, '#ffffff', { strokeThickness: 3 })).setVisible(false);
      this.statsLines.push(t);
      this.statsBody.add(t);
    }
    this.statsMeasure = this.add.text(0, 0, '', style(18, '#ffffff', { strokeThickness: 3 })).setVisible(false);
    this.statsLevel = 'full';
    this.statsHidden = 0;
    this.statsPlanLines = [];
    this.applyStatsVisible();
    const tabKey = this.input.keyboard ? this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.TAB) : null;
    if (tabKey) tabKey.on('down', () => {
      if (this.statsVis.button) this.setStatsOpen(!this.statsOpen);
    });

    if (showFps()) this.fpsText = this.add.text(W / 2, 20, '', style(22, '#9effa1')).setOrigin(0.5, 0).setDepth(90);

    this.stickGfx = this.add.graphics().setDepth(70);
    this.input.on('pointerdown', (p: Phaser.Input.Pointer, over: Phaser.GameObjects.GameObject[]) => this.onDown(p, over));
    this.input.on('pointermove', (p: Phaser.Input.Pointer) => {
      this.taps.move(p.id, p.x, p.y);
      const r = this.thumb.move(p.id, p.x, p.y);
      if (r) this.applyStick(r);
    });
    this.input.on('pointerup', (p: Phaser.Input.Pointer) => this.onUp(p));
    this.input.on('pointerupoutside', (p: Phaser.Input.Pointer) => this.onUp(p));
    const release = () => {
      this.releaseStick();
      this.taps.clear();
    };
    this.game.events.on(Phaser.Core.Events.HIDDEN, release);
    this.game.events.on(Phaser.Core.Events.BLUR, release);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.game.events.off(Phaser.Core.Events.HIDDEN, release);
      this.game.events.off(Phaser.Core.Events.BLUR, release);
    });
  }

  private onDown(p: Phaser.Input.Pointer, over: Phaser.GameObjects.GameObject[]): void {
    // The sound switch answers on a tap on any screen; in a run the finger still takes the stick, as on a card.
    if (over.includes(this.muteBtn)) {
      this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'mute' });
      if (this.nestOpen || this.world.phase === 'title' || this.world.phase === 'dead') return;
    }
    if (this.howtoOpen) {
      // The How to play card: only GOT IT answers, once the card has been up a moment.
      if (this.time.now - this.howtoShownAt >= PICK_READ_MS && over.includes(this.howtoClose)) {
        this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'howto', action: 'close' });
      }
      return;
    }
    if (this.updateShown && over.includes(this.updateBg)) {
      this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'update' });
      return;
    }
    if (this.nestOpen) {
      // The nest screen: its cards and its two buttons answer on a tap once it has been up a moment; no stick here.
      if (this.time.now - this.nestShownAt >= PICK_READ_MS) {
        const card = this.nestCards.find((c) => over.includes(c.bg));
        if (card) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'nest', card });
        else if (over.includes(this.nestPlay)) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'nestBtn', action: 'play' });
        else if (over.includes(this.nestBack)) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'nestBtn', action: 'back' });
      }
      return;
    }
    if (this.world.phase === 'title') {
      // Only the title's buttons answer on the title, and only once it has been up a moment; no stick here.
      const now = this.time.now;
      if (this.titleShown && now - this.titleShownAt >= PICK_READ_MS) {
        const action =
          this.contBtn.visible && over.includes(this.contBtn)
            ? 'continue'
            : over.includes(this.playBtn)
              ? 'play'
              : over.includes(this.dailyBtn)
                ? 'daily'
                : over.includes(this.ladderBtn)
                  ? 'ladder'
                  : over.includes(this.nestBtn)
                    ? 'nest'
                    : null;
        if (action) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'title', action });
        else if (over.includes(this.howtoBtn)) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'howto', action: 'open' });
      }
      return;
    }
    if (this.world.phase === 'dead') {
      // Only the two buttons answer, once the guard is over, so a thumb still on the glass cannot skip the result.
      if (this.deathShownAt >= 0 && this.time.now - this.deathShownAt > DEATH_TAP_GUARD_MS) {
        const action = over.includes(this.deathAgain) ? 'again' : over.includes(this.deathNest) ? 'nest' : null;
        if (action) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'death', action });
      }
      return;
    }
    // Lane N1, M2: a press that starts on the stats button or on the open panel is the tab's alone: a tap on the button
    // opens or closes it, a tap on the x closes it, and the stick never takes such a press, a drag either.
    const statsAt = statsHit(p.x, p.y, this.statsPlace, this.statsPanelH, this.statsVis);
    if (statsAt) {
      if (statsAt !== 'panel') this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'stats', action: statsAt === 'button' ? 'toggle' : 'close' });
      return;
    }
    // A press on a card may turn out a tap (it buys or picks on the lift); either way the first free finger takes the
    // stick, anywhere on the screen, so a drag from a card moves the ant and never buys or picks.
    const now = this.time.now;
    const card = this.shopShown ? this.cards.find((c) => over.includes(c.bg)) : undefined;
    // A press is timed by the touch events' own clock (p.downTime, p.upTime), not the frame clock, so a frame that
    // stalls between the finger landing and lifting cannot turn a quick tap into a slow press.
    if (card) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'shop', card });
    // A pick card counts only once the sheet has been up PICK_READ_MS, so a thumb landing as it appears picks nothing.
    const pick = this.pickShown && now - this.pickShownAt >= PICK_READ_MS ? this.pickCards.find((c) => c.id && over.includes(c.bg)) : undefined;
    if (pick) this.taps.down(p.id, p.x, p.y, p.downTime, { kind: 'pick', card: pick });
    if (!this.thumb.down(p.id, p.x, p.y, this.slopUnits())) return;
    const r = this.thumb.move(p.id, p.x, p.y);
    if (r) this.applyStick(r);
  }

  private onUp(p: Phaser.Input.Pointer): void {
    const press = this.taps.up(p.id, p.x, p.y, p.upTime, this.slopUnits());
    if (press && press.kind === 'mute') {
      this.muteBtn.setTexture(toggleMute() ? 'sound_off' : 'sound_on');
    } else if (press && press.kind === 'update' && this.updateShown) {
      if (applyUpdate()) this.updateText.setText('Loading the new version');
    } else if (press && press.kind === 'howto') {
      if (press.action === 'open' && this.titleShown && !this.howtoOpen) this.openHowTo();
      else if (press.action === 'close' && this.howtoOpen) this.closeHowTo(true);
    } else if (press && press.kind === 'shop') {
      const c = press.card;
      c.flashOk = c.perk ? this.world.tryBuy(c.perk) : c.line ? this.world.tryBuyLine(c.line) : false;
      c.flashUntil = this.time.now + 180;
    } else if (press && press.kind === 'pick' && press.card.id && this.pickShown) {
      this.world.pickPower(press.card.id);
    } else if (press && press.kind === 'title' && this.titleShown) {
      if (press.action === 'continue') this.world.continueRun();
      else if (press.action === 'play') this.world.startOver();
      else if (press.action === 'daily') this.world.startDaily();
      else if (press.action === 'ladder') this.world.setLadder(this.world.snap.ladder === 'colony' ? 'pure' : 'colony');
      else this.openNest('title');
    } else if (press && press.kind === 'nest' && this.nestOpen) {
      press.card.flashOk = this.world.buyColony(press.card.id);
      press.card.flashUntil = this.time.now + 180;
      this.nestKey = '';
    } else if (press && press.kind === 'death' && this.world.phase === 'dead' && !this.nestOpen) {
      if (press.action === 'again') this.world.playAgain();
      else this.openNest('dead');
    } else if (press && press.kind === 'nestBtn' && this.nestOpen) {
      if (press.action === 'back') this.closeNest();
      else if (this.nestFrom === 'title') {
        this.closeNest();
        this.world.startOver();
        // Lane G7, M3: the nest's PLAY starts a run on the ladder, where its upgrades count (not a Daily run again).
      } else this.world.playAgain(false);
    } else if (press && press.kind === 'stats' && this.statsVis.button) {
      this.setStatsOpen(press.action === 'toggle' ? !this.statsOpen : false);
    }
    if (this.thumb.up(p.id)) this.releaseStick();
  }

  /** Lane N1, M2: opens or closes the stats panel; it shows from the next frame (update reads statsShown). */
  private setStatsOpen(open: boolean): void {
    if (open === this.statsOpen) return;
    this.statsOpen = open;
    this.statsKey = '';
    this.drawStats();
  }

  /** Lane N1, M2: shows or hides the tab's parts as statsVis says; a panel that shows is filled again. */
  private applyStatsVisible(): void {
    this.statsBtnText.setVisible(this.statsVis.button);
    this.statsTitle.setVisible(this.statsVis.panel);
    this.statsBody.setVisible(this.statsVis.panel);
    if (this.statsVis.panel) this.statsKey = '';
    this.drawStats();
  }

  /**
   * Lane N1, M2: fills the panel from the run as it stands (sim/stats.ts), whenever anything it shows has changed. The
   * lines, their places and the body's scale come from layout.ts statsPanelPlan, measured in the panel's own face.
   */
  private refreshStats(s: Snapshot): void {
    const key = [s.ladder, Object.values(s.colonyLevels).join(','), s.owned.join(','), Object.values(s.lines).join(','), Object.values(s.stacks).join(','), Math.ceil(s.hp), s.maxHp].join('|');
    if (key === this.statsKey) return;
    this.statsKey = key;
    const sheet = statsSheet({ ladder: s.ladder, colony: s.colonyLevels, owned: s.owned, lines: s.lines, stacks: s.stacks, hp: s.hp });
    this.statsSheetNow = sheet;
    const m = this.statsMeasure;
    const plan = statsPanelPlan(sheet.rows, this.statsPlace.panel, (text, size) => m.setFontSize(size).setText(text).width);
    this.statsLines.forEach((t, i) => {
      const line = plan.lines[i];
      if (!line) {
        t.setVisible(false);
        return;
      }
      t.setFontSize(line.size).setColor(STATS_COLOR[line.kind]).setText(line.text).setPosition(line.x, line.y).setVisible(true);
    });
    this.statsLevel = plan.level;
    this.statsHidden = plan.hidden;
    this.statsPlanLines = plan.lines.slice(0, STATS_LINE_POOL).map((l) => ({ kind: l.kind, text: l.text }));
    this.statsBody.setScale(plan.scale);
    this.statsPanelH = plan.drawnH;
    this.drawStats();
  }

  /** Lane N1, M2: the button (brighter while the panel is open) and the panel, as tall as its rows, with its close x. */
  private drawStats(): void {
    const b = this.statsBtnGfx;
    b.clear();
    if (this.statsVis.button) {
      const SB = this.statsPlace.button;
      b.fillStyle(this.statsOpen ? 0x2f7d32 : 0x10240f, this.statsOpen ? 0.9 : 0.72);
      b.fillRoundedRect(SB.x, SB.y, SB.w, SB.h, 16);
      b.lineStyle(3, 0x9effa1, 0.85);
      b.strokeRoundedRect(SB.x, SB.y, SB.w, SB.h, 16);
    }
    const g = this.statsGfx;
    g.clear();
    if (!this.statsVis.panel) return;
    const P = this.statsPlace.panel;
    g.fillStyle(0x0b140a, STATS_PANEL_FILL);
    g.fillRoundedRect(P.x, P.y, P.w, this.statsPanelH, 18);
    g.lineStyle(3, 0x9effa1, 0.5);
    g.strokeRoundedRect(P.x, P.y, P.w, this.statsPanelH, 18);
    // The close x on the title's row; the whole corner square around it is its tap target (layout.ts statsLayout).
    const C = this.statsPlace.close;
    const cx = C.x + C.w / 2;
    const cy = C.y + 32;
    g.lineStyle(3, 0xffffff, 0.35);
    g.strokeCircle(cx, cy, 22);
    g.lineStyle(5, 0xffffff, 0.9);
    g.lineBetween(cx - 10, cy - 10, cx + 10, cy + 10);
    g.lineBetween(cx - 10, cy + 10, cx + 10, cy - 10);
  }

  /** The one press slop (PRESS_SLOP_PX screen points) in HUD units; displayScale is HUD units per CSS pixel. */
  private slopUnits(): number {
    return PRESS_SLOP_PX * this.scale.displayScale.x;
  }

  private applyStick(r: StickReading): void {
    this.stick.active = r.moving;
    this.stick.x = r.x;
    this.stick.y = r.y;
    this.stickKnob.x = r.knobX;
    this.stickKnob.y = r.knobY;
    const g = this.stickGfx;
    g.clear();
    g.fillStyle(0xffffff, 0.12);
    g.fillCircle(r.baseX, r.baseY, STICK_RADIUS);
    g.lineStyle(4, 0xffffff, 0.35);
    g.strokeCircle(r.baseX, r.baseY, STICK_RADIUS);
    g.fillStyle(0xffffff, 0.55);
    g.fillCircle(r.knobX, r.knobY, 40);
    g.lineStyle(4, 0x1a1207, 0.5);
    g.strokeCircle(r.knobX, r.knobY, 40);
  }

  private releaseStick(): void {
    this.thumb.release();
    this.stick.active = false;
    this.stick.x = 0;
    this.stick.y = 0;
    if (this.stickGfx) this.stickGfx.clear();
  }

  private setShopVisible(v: boolean): void {
    this.shopShown = v;
    this.shopTitle.setVisible(v);
    for (const c of this.cards) {
      c.bg.setVisible(v);
      if (v) c.bg.setInteractive({ useHandCursor: true });
      else c.bg.disableInteractive();
      for (const t of c.texts) t.setVisible(v);
    }
  }

  /** Moves the sheet's title and cards to the place for this phase (layout.ts pickLayout). */
  private placePick(place: SheetPlace): void {
    this.pickPlaceNow = place;
    const L = pickLayout(place, this.scale.height);
    this.pickTitle.setY(L.titleY);
    this.pickCards.forEach((c, i) => {
      const y = L.cardsTop + i * (PICK_CARD_H + PICK_GAP);
      c.bg.setY(y);
      c.icon.setY(y + PICK_CARD_H / 2);
      c.name.setY(y + 12);
      c.line.setY(y + 60);
      c.count.setY(y + 14);
    });
  }

  private setTitleVisible(v: boolean): void {
    this.titleShown = v;
    this.titleKey = '';
    for (const o of this.titleParts) (o as unknown as Phaser.GameObjects.Components.Visible).setVisible(v);
    for (const b of [this.contBtn, this.playBtn, this.dailyBtn, this.ladderBtn, this.nestBtn, this.howtoBtn]) {
      if (v) b.setInteractive({ useHandCursor: true });
      else b.disableInteractive();
    }
    // The card belongs to the title: it goes when the title goes (closed this way it still counts as not seen).
    if (!v && this.howtoOpen) this.closeHowTo(false);
  }

  /** Puts the title's buttons and their small lines where layout.ts titleLayout says, with or without Continue. */
  private placeTitle(saved: boolean): void {
    const L = titleLayout(this.scale.height, saved);
    const place: Record<TitleRow, Array<Phaser.GameObjects.Components.Transform>> = {
      cont: [this.contBtn, this.contText],
      play: [this.playBtn, this.playText],
      daily: [this.dailyBtn, this.dailyText],
      ladder: [this.ladderBtn, this.ladderText],
      nest: [this.nestBtn, this.nestBtnText],
    };
    const subs: Record<TitleRow, Phaser.GameObjects.Text> = {
      cont: this.titleSub,
      play: this.playSub,
      daily: this.dailySub,
      ladder: this.ladderSub,
      nest: this.nestBtnSub,
    };
    for (const r of L.rows) {
      for (const o of place[r.row]) o.setY(r.y);
      subs[r.row].setY(r.subY);
    }
  }

  private setHowToVisible(v: boolean): void {
    for (const o of this.howtoParts) (o as unknown as Phaser.GameObjects.Components.Visible).setVisible(v);
    if (v) this.howtoClose.setInteractive({ useHandCursor: true });
    else this.howtoClose.disableInteractive();
  }

  /** Opens the How to play card over the title (by itself on a phone's first title, or from its button). */
  private openHowTo(): void {
    this.howtoOpen = true;
    this.howtoShownAt = this.time.now;
    this.taps.clear();
    this.setHowToVisible(true);
  }

  /** GOT IT closes the card and the phone remembers it was seen; closed with the title (seen false) it may show again. */
  private closeHowTo(seen: boolean): void {
    this.howtoOpen = false;
    this.taps.clear();
    this.setHowToVisible(false);
    if (seen) writeHowToSeen(browserStore());
    // The title's buttons under the card wait out their read guard again, so the closing finger presses nothing.
    this.titleShownAt = this.time.now;
  }

  /** Lays the title out for this frame: Continue only with a saved run, Play under it (or in its place without one). */
  private refreshTitle(saved: { round: number; level: number; ladder: Ladder; daily: string | null } | null, ladder: Ladder): void {
    const view = this.world.colonyView();
    const best = this.world.bestRounds();
    const dv = this.world.dailyView();
    const key = `${saved ? `${saved.round}|${saved.level}|${saved.ladder}|${saved.daily}` : ''}|${ladder}|${view.bank}|${best.colony}|${best.pure}|${dv.day}|${dv.best}`;
    if (key === this.titleKey) return;
    this.titleKey = key;
    const has = saved !== null;
    for (const o of [this.contBtn, this.contText, this.titleSub]) o.setVisible(has);
    if (has) this.contBtn.setInteractive({ useHandCursor: true });
    else this.contBtn.disableInteractive();
    this.placeTitle(has);
    this.playSub.setText(has ? 'A new run ends the saved one' : '');
    const bestLine = (l: Ladder) => (best[l] === null ? 'none yet' : `round ${best[l]}`);
    this.titleLine.setText(`Best ${LADDER_NAME.colony}: ${bestLine('colony')}\nBest ${LADDER_NAME.pure}: ${bestLine('pure')}`);
    if (saved) {
      const what = saved.daily ? `DAILY run (${dayLabel(saved.daily)})` : `${LADDER_NAME[saved.ladder]} run`;
      this.titleSub.setScale(1).setText(`Saved ${what}: round ${saved.round} cleared, level ${saved.level}`);
      this.titleSub.setScale(Math.min(1, (this.scale.width - 40) / Math.max(1, this.titleSub.width)));
    }
    // Lane G7, M3: the Daily challenge shows its date and the day's best round (the same run for everyone that day).
    const dailyLine = `${dv.label}: ${dv.best === null ? 'the same run for everyone today' : `best round ${dv.best} today`}`;
    this.dailySub.setScale(1).setText(has ? `${dailyLine}. Ends the saved run` : dailyLine);
    this.dailySub.setScale(Math.min(1, (this.scale.width - 40) / Math.max(1, this.dailySub.width)));
    this.ladderText.setText(`LADDER: ${LADDER_NAME[ladder]}`);
    this.ladderSub.setText(ladder === 'colony' ? 'Your colony upgrades are on. Tap to switch' : 'Everyone starts weak, no upgrades. Tap to switch');
    this.ladderSub.setScale(Math.min(1, (this.scale.width - 40) / Math.max(1, this.ladderSub.width)));
    this.nestBtnSub.setText(`Banked nectar: ${fmt(view.bank)}`);
  }

  private setNestVisible(v: boolean): void {
    for (const o of this.nestParts) (o as unknown as Phaser.GameObjects.Components.Visible).setVisible(v);
    for (const b of [...this.nestCards.map((c) => c.bg), this.nestPlay, this.nestBack]) {
      if (v) b.setInteractive({ useHandCursor: true });
      else b.disableInteractive();
    }
  }

  private openNest(from: 'title' | 'dead'): void {
    this.nestOpen = true;
    this.nestFrom = from;
    this.nestShownAt = this.time.now;
    this.nestKey = '';
    this.taps.clear();
    this.setNestVisible(true);
    if (from === 'title') this.setTitleVisible(false);
    else this.setDeathVisible(false);
  }

  private closeNest(): void {
    this.nestOpen = false;
    this.taps.clear();
    this.setNestVisible(false);
    // The screen under it comes back on the next frame (update shows the title or the death screen again).
    this.titleShown = false;
    if (this.nestFrom === 'dead') {
      this.deathShownAt = -1;
      this.deathReturn = true;
    }
  }

  /** Fills the nest's cards: the bank, the one price, each line's next step and count. */
  private refreshNest(now: number): void {
    const view = this.world.colonyView();
    const cost = nextCost(view.levels);
    const flashing = this.nestCards.some((c) => now < c.flashUntil);
    // Opened from the title with a run saved, the nest's PLAY starts a new run as the title's PLAY does: it says so.
    const savedWaiting = this.nestFrom === 'title' && this.world.snap.saved !== null;
    const key = `${view.bank}|${UPGRADES.map((u) => view.levels[u.id]).join(',')}|${view.ladder}|${flashing}|${savedWaiting}`;
    if (key === this.nestKey) return;
    this.nestKey = key;
    this.nestBank.setText(`Banked nectar: ${fmt(view.bank)}`);
    this.nestPrice.setText(cost === null ? 'Every upgrade is at its max' : `Next upgrade: ${fmt(cost)} nectar (the price climbs each buy)`);
    this.nestPrice.setScale(Math.min(1, (this.scale.width - 40) / Math.max(1, this.nestPrice.width)));
    this.nestNote.setText(
      savedWaiting
        ? 'PLAY starts a new run and ends the saved one'
        : view.ladder === 'pure'
          ? 'Upgrades count on Colony runs; Pure starts weak'
          : 'Colony runs start with these upgrades',
    );
    const room = this.scale.width - 24 - 44 - 16;
    for (const c of this.nestCards) {
      const lvl = view.levels[c.id];
      const max = upgradeSpec(c.id).max;
      const full = lvl >= max;
      const afford = canBuyUpgrade({ bank: view.bank, levels: { ...view.levels } }, c.id);
      let fill = full ? 0x1f4d1c : afford ? 0x3a2810 : 0x241a10;
      if (now < c.flashUntil) fill = c.flashOk ? 0x3f9a37 : 0x8a2420;
      c.bg.setFillStyle(fill, 0.96);
      c.bg.setStrokeStyle(4, full ? 0x9effa1 : afford ? 0xffd34d : 0x6b5a3a);
      c.line.setScale(1).setText(upgradeLine(c.id, BASE_ANT, view.levels));
      c.line.setScale(Math.min(1, room / Math.max(1, c.line.width)));
      c.count.setText(`${lvl} OF ${max}`);
      c.price.setText(full ? 'MAX' : cost === null ? '' : fmt(cost));
      c.price.setColor(full ? '#9effa1' : afford ? '#ffd34d' : '#a08a66');
      c.name.setAlpha(afford || full ? 1 : 0.7);
    }
  }

  private setPickVisible(v: boolean): void {
    this.pickShown = v;
    this.pickTitle.setVisible(v);
    for (const c of this.pickCards) {
      c.bg.setVisible(v);
      if (v) c.bg.setInteractive({ useHandCursor: true });
      else c.bg.disableInteractive();
      for (const o of [c.icon, c.name, c.line, c.count]) o.setVisible(v);
    }
  }

  /** Fills the sheet with the offer: one card per power, the rest hidden (Honeydew alone when everything else is full). */
  private fillPick(offer: readonly PowerId[], stacks: Readonly<Record<PowerId, number>>): void {
    const room = this.scale.width - 24 - 118 - 16;
    this.pickCards.forEach((c, i) => {
      const id = offer[i] ?? null;
      c.id = id;
      const show = this.pickShown && id !== null;
      c.bg.setVisible(show);
      if (show) c.bg.setInteractive({ useHandCursor: true });
      else c.bg.disableInteractive();
      for (const o of [c.icon, c.name, c.line, c.count]) o.setVisible(show);
      if (!id) return;
      const spec = powerSpec(id);
      const have = stacks[id];
      c.icon.setTexture(`pow_${id}`);
      c.name.setText(spec.name);
      c.line.setScale(1).setText(powerLine(id, stacks));
      c.line.setScale(Math.min(1, room / Math.max(1, c.line.width)));
      c.count.setText(have === 0 ? 'NEW' : spec.max === null ? 'AGAIN' : `${have + 1} OF ${spec.max}`);
    });
  }

  private setDeathVisible(v: boolean): void {
    this.deathBg.setVisible(v);
    for (const t of this.deathTexts) t.setVisible(v);
    for (const b of [this.deathAgain, this.deathNest]) {
      if (v) b.setInteractive({ useHandCursor: true });
      else b.disableInteractive();
    }
  }

  private showBanner(b: Banner, now: number): void {
    this.tweens.killTweensOf([this.bannerTitle, this.bannerSub]);
    // Long titles (ROUND 12 CLEARED, QUEEN'S BLESSING) shrink to fit the screen instead of running off it.
    const room = this.scale.width - 40;
    this.bannerTitle.setScale(1).setText(b.title).setColor(b.color).setAlpha(1);
    const fit = Math.min(1, room / Math.max(1, this.bannerTitle.width));
    this.bannerTitle.setScale(0.6 * fit);
    this.bannerSub.setScale(1).setText(b.sub).setAlpha(b.sub ? 1 : 0);
    this.bannerSub.setScale(Math.min(1, room / Math.max(1, this.bannerSub.width)));
    this.tweens.add({ targets: this.bannerTitle, scale: fit, duration: 260, ease: 'Back.easeOut' });
    this.tweens.add({ targets: [this.bannerTitle, this.bannerSub], alpha: 0, delay: 1250, duration: 320 });
    this.bannerBusyUntil = now + 1500;
  }

  update(): void {
    const s = this.world.snap;
    if (!s) return;
    const now = this.time.now;
    const W = this.scale.width;
    const H = this.scale.height;

    while (this.world.banners.length > 0) this.bannerQueue.push(this.world.banners.shift() as Banner);
    if (this.bannerQueue.length > 0 && now >= this.bannerBusyUntil) this.showBanner(this.bannerQueue.shift() as Banner, now);

    const onTitle = s.phase === 'title' && !this.nestOpen;
    if (onTitle !== this.titleShown) {
      this.setTitleVisible(onTitle);
      this.titleShownAt = now;
    }
    if (onTitle) this.refreshTitle(s.saved, s.ladder);
    if (onTitle) {
      const stamp = buildStamp();
      if (this.buildText.text !== stamp) this.buildText.setText(stamp);
    }
    // Lane G7, M2: the first title a phone sees opens the How to play card by itself, once (howto.ts).
    if (onTitle && !this.howtoChecked) {
      this.howtoChecked = true;
      if (!readHowToSeen(browserStore())) this.openHowTo();
    }
    // The first round's drag hint and the run's readouts wait for the run; they never show through the title.
    for (const o of [this.hint, this.hpBar, this.hpText, this.levelBar, this.levelText, this.nectarText, this.nectarIcon]) o.setVisible(!onTitle);
    if (this.nestOpen) {
      // A nest opened from the title closes if the run started meanwhile (it cannot, but never leave it stuck).
      if (this.nestFrom === 'title' && s.phase !== 'title') this.closeNest();
      else this.refreshNest(now);
    }
    // Lane G7, M3: a Daily run says so on the HUD, where the ladder's name sits on any other run.
    const tag = s.daily ? 'DAILY' : LADDER_NAME[s.ladder];
    this.roundText.setText(s.phase === 'title' ? '' : s.phase === 'intro' ? 'GET READY' : `ROUND ${s.round}`);
    this.aliveText.setText(ladderLine(s, tag));
    this.nectarText.setText(fmt(s.nectar));
    if (s.hp !== this.lastHp || s.maxHp !== this.lastMax) {
      this.lastHp = s.hp;
      this.lastMax = s.maxHp;
      const f = Phaser.Math.Clamp(s.hp / s.maxHp, 0, 1);
      const g = this.hpBar;
      g.clear();
      g.fillStyle(0x000000, 0.6);
      g.fillRoundedRect(HP_BAR.x, HP_BAR.y, HP_BAR.w, HP_BAR.h, 8);
      g.fillStyle(f > 0.5 ? 0x6fe36b : f > 0.25 ? 0xffc23d : 0xff4d4d, 1);
      g.fillRoundedRect(HP_BAR.x + 3, HP_BAR.y + 3, Math.max(4, (HP_BAR.w - 6) * f), HP_BAR.h - 6, 6);
      this.hpText.setText(`${Math.ceil(s.hp)} / ${s.maxHp}`);
    }
    const levelKey = `${s.level}|${s.xp}|${s.xpNeed}`;
    if (levelKey !== this.lastLevelKey) {
      this.lastLevelKey = levelKey;
      const f = s.xpNeed === null ? 1 : Phaser.Math.Clamp(s.xp / s.xpNeed, 0, 1);
      const g = this.levelBar;
      const LB = levelBar(W);
      g.clear();
      g.fillStyle(0x000000, 0.6);
      g.fillRoundedRect(LB.x, LB.y, LB.w, LB.h, 8);
      g.fillStyle(0x9d7bff, 1);
      if (f > 0) g.fillRoundedRect(LB.x + 3, LB.y + 3, Math.max(4, (LB.w - 6) * f), LB.h - 6, 6);
      this.levelText.setText(s.xpNeed === null ? `LV ${s.level}  MAX` : `LV ${s.level}  ${s.xp} / ${s.xpNeed}`);
    }
    const bossKey = s.boss ? `${Math.ceil(s.boss.hp)}|${s.boss.maxHp}|${s.boss.eating}` : '';
    if (bossKey !== this.lastBossKey) {
      this.lastBossKey = bossKey;
      const g = this.bossBar;
      g.clear();
      if (s.boss) {
        const f = Phaser.Math.Clamp(s.boss.hp / s.boss.maxHp, 0, 1);
        const BB = bossBar(W);
        g.fillStyle(0x000000, 0.65);
        g.fillRoundedRect(BB.x, BB.y, BB.w, BB.h, 8);
        g.fillStyle(s.boss.eating ? 0xffb000 : 0xff7a45, 1);
        if (f > 0) g.fillRoundedRect(BB.x + 3, BB.y + 3, Math.max(4, (BB.w - 6) * f), BB.h - 6, 6);
        this.bossText.setText(`THE ${s.boss.name.toUpperCase()}  ${fmt(Math.ceil(s.boss.hp))} / ${fmt(s.boss.maxHp)}${s.boss.eating ? '  EATING YOUR NECTAR' : ''}`);
        this.bossText.setScale(Math.min(1, (W - 64) / Math.max(1, this.bossText.width)));
      } else this.bossText.setText('');
    }
    // Health at 30 percent or less in a run: the red edge pulses (layout.ts lowHealth).
    if (lowHealth(s.phase, s.hp, s.maxHp)) this.vignette.setVisible(true).setAlpha(0.6 + 0.3 * Math.sin(now / 150));
    else if (this.vignette.visible) this.vignette.setVisible(false);
    this.blessText.setText(
      s.blessing ? `QUEEN'S BLESSING: ${s.blessing === 'instakill' ? 'ONE HIT KILLS' : 'DOUBLE NECTAR'} ${Math.ceil(s.blessingLeft)}` : '',
    );

    if (!this.hintGone && (s.moving || s.round >= 2)) {
      this.hintGone = true;
      this.tweens.add({ targets: this.hint, alpha: 0, duration: 400 });
    }

    const inBreak = s.phase === 'break';
    this.breakText.setText(inBreak ? `NEXT ROUND IN ${Math.ceil(s.breakLeft)}` : '');
    // A waiting pick takes the lower screen first; the shop comes back once it is taken.
    // The same decision the Yard holds on (sim/pause.ts): the cards are up exactly while the Yard stands still.
    const picking = sheetOpen(s.pending, s.offer.length, s.phase);
    if (picking !== this.pickShown) {
      this.setPickVisible(picking);
      this.pickKey = '';
    }
    if (picking) {
      // In the break the sheet moves up under the countdown and the shop stays in reach below it (VG3 note 6); a moved
      // sheet re-arms the read guard, so a finger already down where a card lands picks nothing.
      const place = pickPlace(s.phase);
      if (place !== this.pickPlaceNow) {
        this.placePick(place);
        this.pickShownAt = now;
      }
      const key = `${s.offer.join(',')}|${s.pending}|${s.pickTitle}`;
      if (key !== this.pickKey) {
        this.pickKey = key;
        this.pickShownAt = now;
        this.pickTitle.setText(s.pending > 1 ? `${s.pickTitle} (${s.pending} TO PICK)` : s.pickTitle);
        this.pickTitle.setScale(Math.min(1, (W - 40) / Math.max(1, this.pickTitle.width)));
        this.fillPick(s.offer, s.stacks);
      }
    }
    // A waiting pick never hides the shop: the shop is open only in the break, where the sheet sits high.
    const shop = s.shop === 'open';
    if (shop !== this.shopShown) this.setShopVisible(shop);
    this.shopLocked.setVisible(s.shop === 'locked' && !picking);
    this.nestHint.setText(inBreak && !s.inNest ? 'Walk to the nest to shop' : '');
    this.updateArrow(inBreak && !s.inNest, now, W, H);

    // Lane N1, M2: the stats tab shows in a run; the panel steps aside while a pick's cards sit high in the break.
    const statsVis = statsShown(this.statsOpen, s.phase, picking);
    if (statsVis.button !== this.statsVis.button || statsVis.panel !== this.statsVis.panel) {
      this.statsVis = statsVis;
      this.applyStatsVisible();
    }
    if (statsVis.panel) this.refreshStats(s);

    if (shop) {
      for (const c of this.cards) {
        let owned: boolean;
        let afford: boolean;
        if (c.perk) {
          // Lane G8: a perk is done at its max; Thick Chitin sells three times, then reads MAX as a line does.
          const spec = perkSpec(c.perk);
          const count = perkCount(s.owned, c.perk);
          owned = count >= spec.max;
          afford = canBuy(s.nectar, s.owned, c.perk);
          c.texts[2].setText(owned ? (spec.max > 1 ? 'MAX' : 'OWNED') : fmt(c.price));
          // Once bought, a perk that sells more than once names its count: "Thick Chitin 1/3".
          const label = spec.max > 1 && count > 0 ? `${spec.name} ${count}/${spec.max}` : spec.name;
          if (c.texts[0].text !== label) c.texts[0].setText(label);
        } else {
          // A repeatable line: the step now and the next one, its price on the shared ladder (sim/economy.ts).
          const id = c.line as LineId;
          const maxed = lineStep(id, s.lines[id] + 1) === null;
          owned = maxed;
          afford = canBuyLine(s.nectar, s.lines, id, s.round);
          c.price = linePrice(id, s.lines);
          const text = lineCard(id, s.lines, s.round);
          if (c.texts[1].text !== text) {
            c.texts[1].setScale(1).setText(text);
            c.texts[1].setScale(Math.min(1, (SHOP_CARD_W - 32) / Math.max(1, c.texts[1].width)));
          }
          // A line not open yet shows no price; one at its maximum reads MAX and sells nothing (design note, 2026-10-24).
          c.texts[2].setText(maxed ? 'MAX' : lineOpen(id, s.round) ? fmt(c.price) : '');
        }
        let fill = owned ? 0x1f4d1c : afford ? 0x3a2810 : 0x241a10;
        if (now < c.flashUntil) fill = c.flashOk ? 0x3f9a37 : 0x8a2420;
        c.bg.setFillStyle(fill, 0.94);
        c.bg.setStrokeStyle(4, owned ? 0x9effa1 : afford ? 0xffd34d : 0x6b5a3a);
        c.texts[2].setColor(owned ? '#9effa1' : afford ? '#ffd34d' : '#a08a66');
        c.texts[0].setAlpha(afford || owned ? 1 : 0.6);
      }
    }

    if (s.phase === 'dead' && this.deathShownAt < 0 && !this.nestOpen) {
      this.deathShownAt = this.deathReturn ? now - DEATH_TAP_GUARD_MS - 1 : now;
      this.deathReturn = false;
      this.releaseStick();
      this.taps.clear();
      this.deathRound.setText(`Round reached: ${s.round}`);
      const rec = s.record;
      let best = 'Practice run: best round not saved';
      if (rec) {
        // Lane G7, M3: a Daily run's best is the day's (its own record), with the date.
        if (s.daily) best = rec.isNew ? `NEW DAILY BEST: ROUND ${rec.best}` : `Daily best ${dayLabel(s.daily)}: round ${rec.best}`;
        else best = rec.isNew ? `NEW BEST ${tag} ROUND: ${rec.best}` : `Best ${tag} round: ${rec.best}`;
        if (!rec.saved) best += '\n(this browser would not save it)';
      }
      // Colony: what this death banked first; Pure: the best round is the headline (no meta, nothing banked); a Daily
      // run names its day first.
      const head = s.daily ? `DAILY CHALLENGE, ${dayLabel(s.daily)}` : `${tag} ladder`;
      const lines = s.banked !== null ? [head, `Nectar banked: +${fmt(s.banked)}`, best] : [head, best];
      lines.push(`${s.kills} ${s.kills === 1 ? 'predator' : 'predators'} down`);
      // Slice 4: the run's economy, so the spending shows (sim/economy.ts, the ledger counts every drop earned and spent).
      const share = s.earned > 0 ? Math.round((s.spent / s.earned) * 100) : 0;
      lines.push(`Nectar spent: ${fmt(s.spent)} of ${fmt(s.earned)} earned (${share}%)`);
      this.deathBest.setText(lines.join('\n'));
      this.deathNestSub.setText(`Banked nectar: ${fmt(s.bank)}`);
      this.setDeathVisible(true);
      this.setShopVisible(false);
      this.setPickVisible(false);
    }
    // The two buttons show only once a tap can act.
    if (this.deathShownAt >= 0 && !this.nestOpen) {
      const ready = now - this.deathShownAt > DEATH_TAP_GUARD_MS;
      for (const b of this.deathButtons) b.setVisible(ready);
    }

    // Lane G7: a new version waiting shows its line on the title and on the death screen once a tap can act there.
    const quiet =
      (s.phase === 'title' && this.titleShown && now - this.titleShownAt >= PICK_READ_MS) ||
      (s.phase === 'dead' && this.deathShownAt >= 0 && now - this.deathShownAt > DEATH_TAP_GUARD_MS);
    const showUpdate = updateReady() && !this.nestOpen && quiet;
    if (showUpdate !== this.updateShown) {
      this.updateShown = showUpdate;
      this.updateBg.setVisible(showUpdate);
      this.updateText.setVisible(showUpdate);
      if (showUpdate) this.updateBg.setInteractive({ useHandCursor: true });
      else this.updateBg.disableInteractive();
    }

    if (this.fpsText && now >= this.fpsAt) {
      this.fpsAt = now + 500;
      this.fpsText.setText(`${this.game.loop.actualFps.toFixed(0)} fps`);
    }
  }

  /** What the HUD shows right now, for the smoke test: the countdown line and which face of the shop is up. */
  readout(): {
    countdown: string;
    cards: boolean;
    locked: boolean;
    level: string;
    title: {
      shown: boolean;
      line: string;
      cont: { x: number; y: number };
      contShown: boolean;
      play: { x: number; y: number };
      ladder: { x: number; y: number; text: string };
      nest: { x: number; y: number };
      /** Lane G7, M2: the How to play button in the top strip. */
      howto: { x: number; y: number };
      /** Lane G7, M3: the Daily challenge button and its line (the date and the day's best). */
      daily: { x: number; y: number; sub: string };
      /** Lane G7, M1: the build stamp shown in the top strip ("build" and the first 7 hex digits of the version). */
      build: string;
    };
    /** Lane G7, M2: the How to play card: up or not, how long before GOT IT answers, GOT IT's middle, the four lines. */
    howto: { shown: boolean; readyIn: number; close: { x: number; y: number }; lines: string[] };
    ladderLine: string;
    mute: { x: number; y: number; muted: boolean; icon: string };
    vignette: boolean;

    death: { shown: boolean; text: string; ready: boolean; nest: { x: number; y: number }; again: { x: number; y: number } };

    nest: {
      shown: boolean;
      readyIn: number;

      bank: string;
      cards: Array<{ id: UpgradeId; x: number; y: number; line: string; count: string; price: string }>;
      play: { x: number; y: number };
      back: { x: number; y: number };
    };
    pick: { shown: boolean; title: string; readyIn: number; cards: Array<{ id: PowerId; x: number; y: number }> };
    /** Slice 4: every shop card's middle, its plain line and its price as shown. */
    shop: Array<{ id: string; x: number; y: number; line: string; price: string }>;
    /** Lane G7: the "New version" line, its middle and its text. */
    update: { shown: boolean; x: number; y: number; text: string };
    /** Lane N1, M2: the stats tab: open or not, its button, the panel as drawn, the close x's middle, the rows it shows. */
    stats: {
      open: boolean;
      button: { x: number; y: number; w: number; h: number; shown: boolean };
      panel: { x: number; y: number; w: number; h: number; shown: boolean; scale: number };
      close: { x: number; y: number };
      rows: StatRow[];
      dart: number | null;
      /** Lane N1: how much the panel shows (layout.ts statsPanelPlan), the upgrades behind "+N more", the lines drawn. */
      level: StatsFitLevel;
      hidden: number;
      lines: Array<{ kind: string; text: string }>;
    };
    /** Lane N1, M3: the thumb stick: the finger that holds it (-1 for none), its base, its knob and the way the ant runs. */
    stick: { pointerId: number; baseX: number; baseY: number; knobX: number; knobY: number; active: boolean; x: number; y: number };
  } {
    const cards: Array<{ id: PowerId; x: number; y: number }> = [];
    for (const c of this.pickCards) {
      if (this.pickShown && c.id && c.bg.visible) cards.push({ id: c.id, x: c.bg.x + c.bg.width / 2, y: c.bg.y + c.bg.height / 2 });
    }
    return {
      countdown: this.breakText ? this.breakText.text : '',
      cards: this.shopShown,
      locked: this.shopLocked ? this.shopLocked.visible : false,
      level: this.levelText ? this.levelText.text : '',
      title: {
        shown: this.titleShown,
        line: this.titleLine ? this.titleLine.text : '',
        cont: { x: this.contBtn ? this.contBtn.x : 0, y: this.contBtn ? this.contBtn.y : 0 },
        contShown: this.contBtn ? this.contBtn.visible : false,
        play: { x: this.playBtn ? this.playBtn.x : 0, y: this.playBtn ? this.playBtn.y : 0 },
        ladder: { x: this.ladderBtn ? this.ladderBtn.x : 0, y: this.ladderBtn ? this.ladderBtn.y : 0, text: this.ladderText ? this.ladderText.text : '' },
        nest: { x: this.nestBtn ? this.nestBtn.x : 0, y: this.nestBtn ? this.nestBtn.y : 0 },
        howto: { x: this.howtoBtn ? this.howtoBtn.x : 0, y: this.howtoBtn ? this.howtoBtn.y : 0 },
        daily: { x: this.dailyBtn ? this.dailyBtn.x : 0, y: this.dailyBtn ? this.dailyBtn.y : 0, sub: this.dailySub ? this.dailySub.text : '' },
        build: this.buildText ? this.buildText.text : '',
      },
      howto: {
        shown: this.howtoOpen,
        readyIn: this.howtoOpen ? Math.max(0, PICK_READ_MS - (this.time.now - this.howtoShownAt)) : 0,
        close: { x: this.howtoClose ? this.howtoClose.x : 0, y: this.howtoClose ? this.howtoClose.y : 0 },
        lines: [...this.howtoLines],
      },
      ladderLine: this.aliveText ? this.aliveText.text : '',
      mute: { x: this.muteBtn ? this.muteBtn.x : 0, y: this.muteBtn ? this.muteBtn.y : 0, muted: isMuted(), icon: this.muteBtn ? this.muteBtn.texture.key : '' },
      vignette: this.vignette ? this.vignette.visible : false,
      death: {
        shown: this.deathBg ? this.deathBg.visible : false,
        text: this.deathRound ? `${this.deathRound.text}\n${this.deathBest.text}` : '',
        ready: this.deathAgain ? this.deathAgain.visible : false,
        again: { x: this.deathAgain ? this.deathAgain.x : 0, y: this.deathAgain ? this.deathAgain.y : 0 },
        nest: { x: this.deathNest ? this.deathNest.x : 0, y: this.deathNest ? this.deathNest.y : 0 },
      },
      nest: {
        shown: this.nestOpen,
        readyIn: this.nestOpen ? Math.max(0, PICK_READ_MS - (this.time.now - this.nestShownAt)) : 0,
        bank: this.nestBank ? this.nestBank.text : '',
        cards: this.nestCards.map((c) => ({ id: c.id, x: c.bg.x + c.bg.width / 2, y: c.bg.y + c.bg.height / 2, line: c.line.text, count: c.count.text, price: c.price.text })),
        play: { x: this.nestPlay ? this.nestPlay.x : 0, y: this.nestPlay ? this.nestPlay.y : 0 },
        back: { x: this.nestBack ? this.nestBack.x : 0, y: this.nestBack ? this.nestBack.y : 0 },
      },
      pick: {
        shown: this.pickShown,
        title: this.pickTitle ? this.pickTitle.text : '',
        readyIn: this.pickShown ? Math.max(0, PICK_READ_MS - (this.time.now - this.pickShownAt)) : 0,
        cards,
      },
      shop: this.cards.map((c) => ({
        id: (c.perk ?? c.line) as string,
        x: c.bg.x + c.bg.width / 2,
        y: c.bg.y + c.bg.height / 2,
        line: c.texts[1].text,
        price: c.texts[2].text,
      })),
      update: {
        shown: this.updateShown,
        x: this.updateBg ? this.updateBg.x : 0,
        y: this.updateBg ? this.updateBg.y : 0,
        text: this.updateText ? this.updateText.text : '',
      },
      stats: this.statsPlace
        ? {
            open: this.statsOpen,
            button: { ...this.statsPlace.button, shown: this.statsVis.button },
            panel: { ...this.statsPlace.panel, h: this.statsPanelH, shown: this.statsVis.panel, scale: this.statsBody ? this.statsBody.scaleX : 1 },
            close: { x: this.statsPlace.close.x + this.statsPlace.close.w / 2, y: this.statsPlace.close.y + 32 },
            rows: this.statsSheetNow ? this.statsSheetNow.rows.map((r) => ({ ...r })) : [],
            dart: this.statsSheetNow ? this.statsSheetNow.numbers.dart : null,
            level: this.statsLevel,
            hidden: this.statsHidden,
            lines: this.statsPlanLines.map((l) => ({ ...l })),
          }
        : {
            open: false,
            button: { x: 0, y: 0, w: 0, h: 0, shown: false },
            panel: { x: 0, y: 0, w: 0, h: 0, shown: false, scale: 1 },
            close: { x: 0, y: 0 },
            rows: [],
            dart: null,
            level: 'full',
            hidden: 0,
            lines: [],
          },
      stick: {
        pointerId: this.thumb.pointerId,
        baseX: this.thumb.baseX,
        baseY: this.thumb.baseY,
        knobX: this.stickKnob.x,
        knobY: this.stickKnob.y,
        active: this.stick.active,
        x: this.stick.x,
        y: this.stick.y,
      },
    };
  }

  private updateArrow(show: boolean, now: number, W: number, H: number): void {
    if (!show) {
      this.arrow.setVisible(false);
      return;
    }
    const view = this.world.cameras.main.worldView;
    const sx = this.world.nest.x - view.x;
    const sy = this.world.nest.y - view.y;
    const bob = Math.sin(now / 160) * 10;
    // The nest shows on screen (even in part): hover above it and point at its middle.
    if (sx > -80 && sx < W + 80 && sy > 150 && sy < H + 80) {
      const ax = Phaser.Math.Clamp(sx, 50, W - 50);
      const ay = Phaser.Math.Clamp(sy - 140 + bob, 220, H - 50);
      this.arrow.setPosition(ax, ay).setRotation(Math.atan2(sy - ay, sx - ax)).setVisible(true);
      return;
    }
    // Off screen: sit at the nearest screen edge, pointing toward the nest.
    const cx = W / 2;
    const cy = H / 2;
    const ang = Math.atan2(sy - cy, sx - cx);
    const ex = Phaser.Math.Clamp(sx, 50, W - 50);
    const ey = Phaser.Math.Clamp(sy, 220, H - 50);
    this.arrow.setPosition(ex, ey).setRotation(ang).setVisible(true);
  }
}
