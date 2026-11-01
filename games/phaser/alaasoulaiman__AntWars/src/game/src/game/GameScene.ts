// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The Yard: the ant, the predators, the darts, the nectar and the round director.
// Every round number comes from sim/curve.ts; predators from sim/roster.ts; the ant and the shop from sim/economy.ts.
import * as Phaser from 'phaser';
import { BREAK_SECONDS, breakStep, capPredatorSpeed, roundPlan, type RoundPlan } from '../sim/curve';
import { browserRunStore, clearRun, encodeRun, loadRun, saveRun, type RunSave } from '../sim/save';
import {
  ANTEATER_GULP_SECONDS,
  ANTEATER_REACH,
  ANTLION_PITS,
  BEETLE_TURN_DEG,
  BLESSING_DROP_CHANCE,
  BLESSING_SECONDS,
  CENTIPEDE_SEGMENTS,
  CENTIPEDE_SEG_RADIUS,
  CENTIPEDE_SPACING,
  CENTIPEDE_TURN_DEG,
  EMBER_BURST_PREDATOR_SHARE,
  EMBER_BURST_RADIUS,
  EMBER_FUSE_RANGE,
  EMBER_FUSE_SECONDS,
  HORNET_BROOD_SECONDS,
  MANTIS_ARC_DEG,
  MANTIS_REACH,
  MANTIS_REST_SECONDS,
  MANTIS_SWEEP_DAMAGE,
  MANTIS_TURN_DEG,
  MANTIS_WINDUP_SECONDS,
  MOTH_DIVE_RANGE,
  MOTH_JINK_MAX,
  MOTH_JINK_MIN,
  PREDATORS,
  broodCall,
  emberBurstOnAnt,
  hornetFan,
  inBurst,
  inSweep,
  isBossKind,
  mothHeading,
  WEB_SECONDS,
  WEB_SLOW,
  anteaterGulp,
  blessingCanDrop,
  firstHordeRound,
  pickPredator,
  pitPull,
  placeSegments,
  predatorHealth,
  predatorSpeedShare,
  shellFactor,
  spawnKind,
  turnToward,
  type BlessingKind,
  type PredatorKind,
} from '../sim/roster';
import {
  BASE_ANT,
  CRIT_MULTIPLIER,
  NECTAR_PER_HIT,
  buyLine,
  buyPerk,
  canBuy,
  canBuyLine,
  capHit,
  emptyLedger,
  emptyLines,
  fireIntervalSeconds,
  killNectar,
  lineSpec,
  nectarGain,
  perkSpec,
  picksOpen,
  runStats,
  shopState,
  stepText,
  trackLeftNest,
  lineStep,
  type AntStats,
  type Ledger,
  type LineId,
  type PerkId,
  type ShopState,
} from '../sim/economy';
import {
  BLIND_DRIFT,
  BLIND_SECONDS,
  BURST_RADIUS,
  BURST_SHARE,
  ECHO_DELAY_SECONDS,
  FIRE_BURN_SECONDS,
  FIRE_TICK_SECONDS,
  FORK_ANGLE_DEG,
  FROST_SECONDS,
  FROST_SLOW,
  PUDDLE_RADIUS,
  PUDDLE_SECONDS,
  PUDDLE_TICK_SECONDS,
  PUDDLE_TICK_SHARE,
  SPARK_RANGE,
  SPARK_SHARE,
  STEAM_RADIUS,
  STEAM_SECONDS,
  antLook,
  burnPerTick,
  combosOf,
  elementProc,
  type AntLook,
  type ComboId,
  HOP_KEEP,
  HOP_RANGE,
  NEEDLE_KEEP,
  addXp,
  canTake,
  damageTaken,
  deriveBuild,
  drawOffer,
  emptyStacks,
  furyFactor,
  healthAfterPick,
  luckyHit,
  powerSpec,
  takePower,
  xpForKill,
  xpToNext,
  type Build,
  type PowerId,
  type PowerStacks,
} from '../sim/growth';
import { browserStore, readBest, recordRun, type RunRecord } from '../sim/best';
import { newYardClock, sheetOpen, shopSells, yardTick, yardTime, type YardClock } from '../sim/pause';

import {
  BEST_KEYS,
  applyColony,
  armorCut,
  armoredDamage,
  bankAfterRun,
  buyUpgrade,
  canBuyUpgrade,
  levelsFor,
  loadColony,
  loadLadder,
  nectarBonus,
  saveColony,
  saveLadder,
  type ColonyState,
  type Ladder,
  type UpgradeId,
} from '../sim/colony';
import { ROCKS, rockContact, rockTouching, sidestepHeading, spawnHoles, stallStep, steerAround } from '../sim/yard';
import { dartOrigin, firstTouched, groupHit, inView, type Disc, type HitGroup } from '../sim/hit';
import { makeRng } from '../sim/rng';
import { againDay, dailySeed, dayKey, dayLabel, isDayKey, readDailyBest, recordDaily, spawnRolls, streamSeed, type SpawnRolls } from '../sim/daily';
import { blip } from './audio';
import * as T from './tuning';
import type { HudScene } from './HudScene';

/** title: every run opens on it (Play, the ladder switch, Continue when a run is saved); then the four phases of a run. */
export type Phase = 'title' | 'intro' | 'active' | 'break' | 'dead';

export interface Snapshot {
  phase: Phase;
  round: number;
  alive: number;
  left: number;
  hp: number;
  maxHp: number;
  nectar: number;
  kills: number;
  breakLeft: number;
  inNest: boolean;
  /** The nest shop this frame: open only in the break; locked line only once the ant came back during a round (sim/economy.ts shopState). */
  shop: ShopState;
  /** Nest perks bought this run, a perk once per buy. */
  owned: ReadonlyArray<PerkId>;
  blessing: BlessingKind | null;
  blessingLeft: number;
  record: RunRecord | null;
  practice: boolean;
  moving: boolean;
  antX: number;
  antY: number;
  /** Growth inside the run (sim/growth.ts): the level, the experience inside it and what the next level needs (null at the cap). */
  level: number;
  xp: number;
  xpNeed: number | null;
  /** Picks waiting to be taken, the three powers on offer for the first of them, and why they came. */
  pending: number;
  offer: readonly PowerId[];
  pickTitle: string;
  stacks: PowerStacks;
  /** Lane G9: true while a pick sheet holds the whole Yard still (sim/pause.ts); the sheet waits for the tap. */
  frozen: boolean;
  /** Lane G9: the Yard's clock in ms, which stands still while a pick sheet is open. */
  yardMs: number;
  /** The boss while it lives (its health for the HUD's big bar, and whether the Anteater is eating at the nest). */
  boss: { kind: PredatorKind; name: string; hp: number; maxHp: number; x: number; y: number; eating: boolean } | null;
  /** Slice 4: the last hits the ant took, raw and after the cap of a fifth of its max health, and what it lost. */
  hurts: ReadonlyArray<{ raw: number; capped: number; taken: number; maxHp: number }>;
  /** Slice 4: the elements carried, the combos they unlock, what is on the field now and what the combos did. */
  elements: {
    fire: boolean;
    frost: boolean;
    spark: boolean;
    combos: Readonly<Record<ComboId, boolean>>;
    puddles: Array<{ x: number; y: number; left: number }>;
    steams: number;
    burning: number;
    blind: number;
    sparks: number;
    comboHits: Readonly<Record<ComboId, number>>;
    /** Design note, 2026-10-24: the rolls behind each effect, for the smoke (dart hits and kills rolled, and what fired). */
    procs: Readonly<{ hits: number; slow: number; burn: number; spark: number; kills: number; puddle: number; steam: number; burst: number }>;
  };
  /** The ant's look: armour plates, the element aura and the level rim (sim/growth.ts antLook). */
  look: AntLook;
  /** The ant is touching a rock this frame. */
  rockContact: boolean;
  /** The saved run the title offers to continue, null when there is none (lane G7: with its day when it is a Daily run). */
  saved: { round: number; level: number; ladder: Ladder; daily: string | null } | null;
  /** Lane G7, M3: the day of this Daily run (null on any other run), the phone's day now and that day's best round. */
  daily: string | null;
  today: string;
  dailyBest: number | null;
  /** Lane G7, M3: the spawns of the run in order (round, kind, hole) and every pick offer drawn, for the smoke test. */
  spawns: ReadonlyArray<{ round: number; kind: PredatorKind; hole: number }>;
  offers: ReadonlyArray<{ round: number; offer: readonly PowerId[] }>;
  /** The Colony (sim/colony.ts): the run's ladder, the colony's store and steps, and what this death banked. */
  ladder: Ladder;
  bank: number;
  colonyLevels: Readonly<Record<UpgradeId, number>>;
  banked: number | null;
  /** Slice 3: the beetles, antlions and centipedes alive (heading in radians, the antlion's pit), and the last dart hits. */
  hunters: Array<{ kind: PredatorKind; x: number; y: number; heading: number; hp: number; maxHp: number; pit: number }>;
  lastHits: ReadonlyArray<{ kind: PredatorKind; raw: number; dealt: number; factor: number; body: boolean }>;
  /** Slice 4: the nest shop's repeatable lines bought this run, and the run's nectar earned and spent. */
  lines: Readonly<Record<LineId, number>>;
  earned: number;
  spent: number;
  /** The ant's numbers this frame, so a test can measure a stronger start. */
  damage: number;
  /** Slice 4: the dart and the max health before the powers multiply (the meta ant, the shop lines and the perks). */
  baseDamage: number;
  baseMaxHp: number;
  speed: number;
  fireInterval: number;
  armor: number;
}

export interface Banner {
  title: string;
  sub: string;
  color: string;
}

type PickupKind = 'bead' | 'jelly' | 'crown';
interface Pickup {
  img: Phaser.GameObjects.Image;
  kind: PickupKind;
  value: number;
}

const KINDS: PredatorKind[] = ['armyAnt', 'wasp', 'spider', 'termite', 'anteater', 'beetle', 'antlion', 'centipede', 'ember', 'moth', 'mantis', 'hornet'];
const PUFF_TINT: Readonly<Record<PredatorKind, number>> = {
  armyAnt: 0xd2493a,
  wasp: 0xffd23f,
  spider: 0x9a6bd1,
  termite: 0xf1dcb0,
  anteater: 0x9c7a5b,
  beetle: 0x4f8f6a,
  antlion: 0xd8b678,
  centipede: 0xd0602f,
  ember: 0xff7a1a,
  moth: 0xa18ad6,
  mantis: 0x6cc24a,
  hornet: 0xffa31a,
};
/** Degrees a second, as radians: how fast a beetle, a centipede and the mantis can turn (sim/roster.ts). */
const TURN_RATE: Partial<Record<PredatorKind, number>> = {
  beetle: (BEETLE_TURN_DEG * Math.PI) / 180,
  centipede: (CENTIPEDE_TURN_DEG * Math.PI) / 180,
  mantis: (MANTIS_TURN_DEG * Math.PI) / 180,
};
/** The fastest any predator may move, in world units a second (94 percent of the ant's base speed). */
const MAX_PREDATOR_SPEED = capPredatorSpeed(1) * BASE_ANT.speed;

class Predator extends Phaser.Physics.Arcade.Sprite {
  kind: PredatorKind = 'armyAnt';
  hp = 1;
  maxHp = 1;
  speed = 100;
  biteReadyAt = 0;
  shotReadyAt = 0;
  windupAt = 0;
  flashUntil = 0;
  strafe = 1;
  spawnUntil = 0;
  stepAt = 0;
  step = false;
  flying = false;
  /** Frost Sap: slowed until this time. */
  slowUntil = 0;
  /** A dart has hit it since it climbed out (Lucky Sting rolls only on the first hit). */
  struck = false;
  /** The Anteater's next gulp, and whether its snout is at the nest. */
  gulpAt = 0;
  eating = false;
  /** The stall watch against rocks (sim/yard.ts stallStep) and where it stood last frame. */
  stalledFor = 0;
  sidestepLeft = 0;
  lastX = 0;
  lastY = 0;
  /** Slice 3: the heading a beetle or a centipede turns slowly; the antlion's pit; the centipede's trail and body. */
  heading = 0;
  pit = -1;
  trail: number[] = [];
  segs: Phaser.GameObjects.Image[] = [];
  segPos: Array<{ x: number; y: number }> = [];
  /** Slice 4: the ember ant's burst time once its fuse is lit, the moth's next jink, the hornet's next call for wasps. */
  fuseAt = 0;
  jinkAt = 0;
  broodAt = 0;
  /** Slice 4: a burn (until, the next tick, a tick's damage) and the blindness steam brings, with the way it drifts. */
  burnUntil = 0;
  burnNext = 0;
  burnTick = 0;
  blindUntil = 0;
  wander = 0;
  /** How many times the Brood Hornet has called wasps. */
  broodCalls = 0;
  /** Design note, 2026-10-24: the hits of the last half second on it, and the one number that shows their total. */
  hitGroup: HitGroup | null = null;
  hitText: Phaser.GameObjects.Text | null = null;
}

class Dart extends Phaser.Physics.Arcade.Image {
  damage = 0;
  crit = false;
  dieAt = 0;
  pierce = false;
  hopsLeft = 0;
  /** Predators this dart already hit: a piercing or hopping dart hits each one once. */
  readonly hits: Predator[] = [];
}

class Shot extends Phaser.Physics.Arcade.Image {
  damage = 0;
  web = false;
  dieAt = 0;
}

/** ?debug&assist (test runs only): the ant takes no damage and its darts hit 4 times as hard, for the long bot. */
export const ASSIST_DAMAGE = 4;
function readAssist(): boolean {
  try {
    const q = new URLSearchParams(window.location.search);
    return q.has('debug') && q.has('assist');
  } catch {
    return false;
  }
}

/** The phone's calendar day; ?debug&day=YYYY-MM-DD sets another one (the smoke test plays a fixed day). */
function readToday(): string {
  try {
    const q = new URLSearchParams(window.location.search);
    const day = q.get('day');
    if (q.has('debug') && isDayKey(day)) return day;
  } catch {
    // The real day below.
  }
  return dayKey(new Date());
}

/** ?round=N starts a practice run at round N (it never touches the saved best). */
function readStartRound(): number {
  try {
    const raw = new URLSearchParams(window.location.search).get('round');
    if (raw === null) return 1;
    const n = Number(raw);
    return Number.isInteger(n) && n >= 1 && n <= 200 ? n : 1;
  } catch {
    return 1;
  }
}

function body(obj: Phaser.GameObjects.GameObject): Phaser.Physics.Arcade.Body {
  return obj.body as Phaser.Physics.Arcade.Body;
}

export class GameScene extends Phaser.Scene {
  ant!: Phaser.Physics.Arcade.Sprite;
  readonly nest = new Phaser.Math.Vector2(T.WORLD_W / 2, T.WORLD_H / 2);
  readonly banners: Banner[] = [];
  phase: Phase = 'intro';
  snap!: Snapshot;

  private predators!: Phaser.Physics.Arcade.Group;
  private darts!: Phaser.Physics.Arcade.Group;
  private shots!: Phaser.Physics.Arcade.Group;
  private antBar!: Phaser.GameObjects.Graphics;
  private nestRing!: Phaser.GameObjects.Graphics;
  private cursors: Phaser.Types.Input.Keyboard.CursorKeys | null = null;
  private wasd: Record<'W' | 'A' | 'S' | 'D', Phaser.Input.Keyboard.Key> | null = null;
  private pickups: Pickup[] = [];
  private floats: Phaser.GameObjects.Text[] = [];
  private floatNext = 0;
  /** Juice (slice 3): a pool of rings for the kill pop, and the next time a big hit may shake the screen again. */
  private rings: Phaser.GameObjects.Image[] = [];
  private ringNext = 0;
  private nextHitShakeAt = 0;
  private puffs = new Map<PredatorKind, Phaser.GameObjects.Particles.ParticleEmitter>();
  private holes: Phaser.Math.Vector2[] = [];
  private rocks!: Phaser.Physics.Arcade.StaticGroup;
  /** A boss round spawns the Anteater before its escort. */
  private bossPending = false;
  private bossWarned = false;
  private live: Predator[] = [];
  private sepX: number[] = [];
  private sepY: number[] = [];

  /** The ant after the nest perks; the build adds the powers on top (sim/growth.ts deriveBuild). */
  private perkStats: AntStats = { ...BASE_ANT };
  private stacks: PowerStacks = emptyStacks();
  private build: Build = deriveBuild(BASE_ANT, emptyStacks());
  private level = 1;
  private xp = 0;
  private pending = 0;
  private offer: PowerId[] = [];
  private pickTitle = '';
  /** Lane G9: the Yard's clock (sim/pause.ts) and whether a pick sheet holds the Yard now. */
  private yard: YardClock = newYardClock();
  private held = false;
  /** Times (ms) of the Echo Sting volleys still to fire. */
  private echoes: number[] = [];
  private hp = BASE_ANT.maxHp;
  private nectar = 0;
  private owned: PerkId[] = [];
  /** Slice 4: the repeatable lines bought this run, and the ledger of nectar earned and spent in it. */
  private lines: Record<LineId, number> = emptyLines();
  private ledger: Ledger = emptyLedger();
  private kills = 0;
  private round = 0;
  private startRound = 1;
  private practice = false;
  private plan: RoundPlan | null = null;
  private queued = 0;
  private spawnTimer = 0;
  private introLeft = 0;
  private breakLeft = 0;
  private fireCooldown = 0;
  private moving = false;
  private graceUntil = 0;
  private webUntil = 0;
  private antStepAt = 0;
  private antStep = false;
  private blessing: BlessingKind | null = null;
  private blessingUntil = 0;
  private vacuum = false;
  private record: RunRecord | null = null;
  /** The ant has been out of the nest during this round (the shop's locked line waits for that). */
  private leftNestThisRound = false;
  /** The run save (sim/save.ts): the record the title offers, the last text written, the next check in a break. */
  private savedRun: RunSave | null = null;
  private lastSaveJson = '';
  private nextSaveAt = 0;
  private assist = false;
  /** The ladder of this run and the colony between runs: Colony applies the upgrades, Pure starts everyone weak. */
  private ladder: Ladder = 'colony';
  private colony: ColonyState = loadColony(null);
  private armor = 0;
  private nectarGain = 1;
  private banked: number | null = null;
  private bests: Record<Ladder, number | null> = { colony: null, pure: null };
  /** Slice 4: the hits the ant took (for the smoke test), the mantis sweep's red arc, and what bursts and sweeps did. */
  private hurtLog: Array<{ raw: number; capped: number; taken: number; maxHp: number }> = [];
  /** Design note, 2026-10-24: the ant's hits of the last half second and the one number that shows them. */
  private antHitGroup: HitGroup | null = null;
  private antHitText: Phaser.GameObjects.Text | null = null;
  private sweepGfx!: Phaser.GameObjects.Graphics;
  private burstLog: Array<{ fuse: boolean; antTook: number; predatorsHit: number }> = [];
  private sweepLog: Array<{ hit: boolean }> = [];
  /** Slice 4: the combo fields on the ground (pools, nothing made in a fight), the spark arcs, and the ant's look. */
  private puddles: Array<{ img: Phaser.GameObjects.Image; x: number; y: number; until: number; next: number }> = [];
  private steams: Array<{ img: Phaser.GameObjects.Image; x: number; y: number; until: number; next: number }> = [];
  private sparkSegs: Array<{ x1: number; y1: number; x2: number; y2: number; until: number }> = [];
  private sparkCount = 0;
  private comboHits: Record<ComboId, number> = { puddle: 0, steam: 0, burst: 0 };
  private sparkGfx!: Phaser.GameObjects.Graphics;
  /** The one seeded random behind every element chance (sim/rng.ts); seeded at each run's start. */
  private chance: () => number = makeRng(1);
  /**
   * Lane G7, M3: the daily challenge. The run's day (null on any other run) and its seed; the round's spawn stream (each
   * spawn takes six rolls from it, sim/daily.ts spawnRolls), the offers drawn so far (each offer its own stream), the
   * phone's day and its best Daily round, and the logs the smoke test compares between two players.
   */
  private daily: string | null = null;
  private dailySeedNow = 0;
  private spawnNext: () => number = Math.random;
  private heldRoll: SpawnRolls | null = null;
  private offersDrawn = 0;
  private today = '';
  private dailyBest: number | null = null;
  private spawnLog: Array<{ round: number; kind: PredatorKind; hole: number }> = [];
  private offerLog: Array<{ round: number; offer: PowerId[] }> = [];
  private procs = { hits: 0, slow: 0, burn: 0, spark: 0, kills: 0, puddle: 0, steam: 0, burst: 0 };
  private lookGfx!: Phaser.GameObjects.Graphics;
  private platesImg!: Phaser.GameObjects.Image;
  /** The last dart hits (kind, dart damage, damage dealt, the shell's factor), for the smoke test. */
  private hitLog: Array<{ kind: PredatorKind; raw: number; dealt: number; factor: number; body: boolean }> = [];

  constructor() {
    super('game');
  }

  create(): void {
    this.resetRun();
    this.physics.world.setBounds(0, 0, T.WORLD_W, T.WORLD_H);
    this.physics.resume();
    this.buildYard();

    this.ant = this.physics.add.sprite(this.nest.x, this.nest.y + 6, 'ant0').setDepth(5);
    body(this.ant).setCircle(T.ANT_RADIUS, this.ant.width / 2 - T.ANT_RADIUS, this.ant.height / 2 - T.ANT_RADIUS);
    this.ant.setCollideWorldBounds(true);
    this.ant.setRotation(-Math.PI / 2);
    this.antBar = this.add.graphics().setDepth(9);
    this.sweepGfx = this.add.graphics().setDepth(3.95);
    this.sparkGfx = this.add.graphics().setDepth(7.5);
    this.lookGfx = this.add.graphics().setDepth(4.9);
    this.platesImg = this.add.image(this.ant.x, this.ant.y, 'plates1').setDepth(5.05).setVisible(false);
    for (let i = 0; i < 8; i++) {
      this.puddles.push({ img: this.add.image(0, 0, 'puddle').setDepth(2.9).setVisible(false), x: 0, y: 0, until: 0, next: 0 });
    }
    for (let i = 0; i < 6; i++) {
      this.steams.push({ img: this.add.image(0, 0, 'steam').setDepth(6.5).setVisible(false), x: 0, y: 0, until: 0, next: 0 });
    }

    this.predators = this.physics.add.group({ classType: Predator, maxSize: 32 });
    // Room for a full build: four darts and two fork pairs a volley, three echoes, a few shots in flight.
    this.darts = this.physics.add.group({ classType: Dart, maxSize: 120 });
    this.shots = this.physics.add.group({ classType: Shot, maxSize: 32 });
    this.physics.add.overlap(this.darts, this.predators, (d, p) =>
      this.onDartHit(d as unknown as Dart, p as unknown as Predator),
    );
    this.physics.add.overlap(this.ant, this.predators, (_a, p) => this.onBite(p as unknown as Predator));
    this.physics.add.overlap(this.ant, this.shots, (_a, s) => this.onShotHit(s as unknown as Shot));
    // Rocks block the ant and every walker; wasps fly over them (CONCEPT_V2 section 5). Darts and stings fly over too.
    this.physics.add.collider(this.ant, this.rocks);
    this.physics.add.collider(this.predators, this.rocks, undefined, (p) => !(p as unknown as Predator).flying);

    for (const kind of KINDS) {
      const emitter = this.add.particles(0, 0, 'puff', {
        speed: { min: 60, max: 240 },
        lifespan: 420,
        scale: { start: 1.2, end: 0 },
        alpha: { start: 0.95, end: 0 },
        tint: PUFF_TINT[kind],
        emitting: false,
      });
      emitter.setDepth(8);
      this.puffs.set(kind, emitter);
    }
    for (let i = 0; i < 28; i++) {
      const t = this.add
        .text(0, 0, '', {
          fontFamily: '"Arial Rounded MT Bold", "Arial Black", Arial, sans-serif',
          fontSize: '24px',
          fontStyle: 'bold',
          color: '#ffffff',
          stroke: '#1a1207',
          strokeThickness: 5,
          resolution: 2,
        })
        .setOrigin(0.5)
        .setDepth(20)
        .setVisible(false);
      this.floats.push(t);
    }

    // The kill pop: a ring that bursts out from the kill and fades, from a fixed pool (no new objects in a fight).
    for (let i = 0; i < 14; i++) this.rings.push(this.add.image(0, 0, 'ring').setDepth(8).setVisible(false));

    const cam = this.cameras.main;
    cam.setBounds(0, 0, T.WORLD_W, T.WORLD_H);
    cam.startFollow(this.ant, true, 0.14, 0.14);
    cam.setFollowOffset(0, this.scale.height * T.CAMERA_LEAD_Y);
    cam.centerOn(this.ant.x, this.ant.y - this.scale.height * T.CAMERA_LEAD_Y);

    const kb = this.input.keyboard;
    if (kb) {
      this.cursors = kb.createCursorKeys();
      this.wasd = kb.addKeys('W,A,S,D') as Record<'W' | 'A' | 'S' | 'D', Phaser.Input.Keyboard.Key>;
    }

    if (this.scene.isActive('hud') || this.scene.isPaused('hud')) this.scene.get('hud').scene.restart();
    else this.scene.launch('hud');

    if (this.phase === 'intro') {
      this.pushBanner(this.practice ? `PRACTICE: ROUND ${this.startRound}` : 'GET READY', 'The predators are coming', '#ffffff');
    }
    // Leaving the page in a break writes the save at once (the half second check might not come again).
    const flush = () => {
      if (this.phase === 'break') this.writeSave(true);
    };
    this.game.events.on(Phaser.Core.Events.HIDDEN, flush);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.game.events.off(Phaser.Core.Events.HIDDEN, flush));
    this.refreshSnap();
  }

  private resetRun(): void {
    this.colony = loadColony(browserStore());
    this.ladder = loadLadder(browserStore());
    this.bests = { colony: readBest(browserStore(), BEST_KEYS.colony), pure: readBest(browserStore(), BEST_KEYS.pure) };
    // Lane G7, M3: the phone's day and its best Daily round; Play again after a Daily run plays the same day again (the
    // registry carries the day across the restart).
    this.today = readToday();
    this.dailyBest = readDailyBest(browserStore(), this.today);
    const againDaily: unknown = this.registry.get('autostartDaily');
    this.registry.set('autostartDaily', null);
    this.daily = null;
    this.dailySeedNow = 0;
    this.offersDrawn = 0;
    this.spawnNext = Math.random;
    this.heldRoll = null;
    this.spawnLog = [];
    this.offerLog = [];
    this.stacks = emptyStacks();
    this.applyMeta();
    this.level = 1;
    this.xp = 0;
    this.pending = 0;
    this.offer = [];
    this.pickTitle = '';
    // A run starts with the Yard running; a held span still open is dropped, so the Yard's clock never runs backward.
    if (this.held) this.holdYard(false);
    this.yard = yardTick(this.yard, this.time.now, false).clock;
    this.echoes = [];
    this.hp = this.build.maxHp;
    this.nectar = 0;
    this.owned = [];
    this.lines = emptyLines();
    this.ledger = emptyLedger();
    this.kills = 0;
    this.startRound = readStartRound();
    this.assist = readAssist();
    this.practice = this.startRound > 1;
    this.round = this.startRound - 1;
    // A saved run (never in a practice run) waits on the title for Continue; Play starts a new one and ends it.
    this.savedRun = this.practice ? null : loadRun(browserRunStore());
    this.lastSaveJson = '';
    this.nextSaveAt = 0;
    // Every run opens on the title (Play, the ladder switch, Continue when a save waits), except a practice run and the
    // run that Play again or the nest's Play asked for.
    const auto = this.registry.get('autostart') === true;
    this.registry.set('autostart', false);
    this.phase = this.practice || auto ? 'intro' : 'title';
    this.banked = null;
    this.plan = null;
    this.queued = 0;
    this.spawnTimer = 0;
    this.introLeft = T.INTRO_SECONDS;
    this.breakLeft = 0;
    this.fireCooldown = 0;
    this.moving = false;
    this.graceUntil = 0;
    this.webUntil = 0;
    this.antStepAt = 0;
    this.antStep = false;
    this.blessing = null;
    this.blessingUntil = 0;
    this.vacuum = false;
    this.record = null;
    this.leftNestThisRound = false;
    this.pickups = [];
    this.floats = [];
    this.floatNext = 0;
    this.rings = [];
    this.ringNext = 0;
    this.nextHitShakeAt = 0;
    this.banners.length = 0;
    this.puffs = new Map();
    this.holes = [];
    this.bossPending = false;
    this.bossWarned = false;
    this.live = [];
    this.hitLog = [];
    this.hurtLog = [];
    this.antHitGroup = null;
    this.antHitText = null;
    this.burstLog = [];
    this.sweepLog = [];
    this.puddles = [];
    this.steams = [];
    this.sparkSegs = [];
    this.sparkCount = 0;
    this.comboHits = { puddle: 0, steam: 0, burst: 0 };
    this.chance = makeRng(Date.now() >>> 0);
    this.procs = { hits: 0, slow: 0, burn: 0, spark: 0, kills: 0, puddle: 0, steam: 0, burst: 0 };
    // A Daily run asked for by Play again starts at once (never in a practice run): on its own day when that is still
    // today, else on today's challenge (VG7: after midnight it started a fresh run of yesterday's); sim/daily.ts againDay.
    const again = auto && !this.practice ? againDay(againDaily, this.today) : null;
    if (again) this.beginDaily(again);
  }

  /**
   * Lane G7, M3: puts this run on a day's challenge. A Daily run is a Pure run (the bare ant whatever the colony holds,
   * nothing banked, its own best per day); its spawns and offers come from the day's seed, and so do its element rolls.
   */
  private beginDaily(day: string): void {
    this.daily = day;
    this.dailySeedNow = dailySeed(day);
    this.ladder = 'pure';
    this.offersDrawn = 0;
    this.chance = makeRng(streamSeed(this.dailySeedNow, 'chance', 0));
    this.applyMeta();
  }

  /** The next pick offer: on a Daily run each offer has its own stream (sim/daily.ts), so the same picks bring the same offers. */
  private nextOffer(): PowerId[] {
    const n = this.offersDrawn;
    this.offersDrawn += 1;
    const offer = drawOffer(this.stacks, this.daily ? makeRng(streamSeed(this.dailySeedNow, 'offer', n)) : Math.random);
    if (this.offerLog.length < 80) this.offerLog.push({ round: this.round, offer: [...offer] });
    return offer;
  }

  /** The ant a run starts with: the base ant plus the colony's upgrades on a Colony run, the bare ant on Pure. */
  private metaBase(ladder: Ladder): AntStats {
    return applyColony(BASE_ANT, levelsFor(ladder, this.colony.levels));
  }

  /** Puts the ladder's meta on a fresh ant (the title, a new run): stats, armor, nectar bonus, full health. */
  private applyMeta(): void {
    const levels = levelsFor(this.ladder, this.colony.levels);
    this.perkStats = this.metaBase(this.ladder);
    this.armor = armorCut(levels);
    this.nectarGain = nectarBonus(levels);
    this.build = deriveBuild(this.perkStats, this.stacks);
    this.hp = this.build.maxHp;
  }

  private buildYard(): void {
    const W = T.WORLD_W;
    const H = T.WORLD_H;
    this.add.tileSprite(0, 0, W, H, 'grass').setOrigin(0).setDepth(0);
    const rng = new Phaser.Math.RandomDataGenerator(['yard-v1']);
    for (let i = 0; i < 95; i++) {
      const x = rng.between(60, W - 60);
      const y = rng.between(60, H - 60);
      if (Phaser.Math.Distance.Between(x, y, this.nest.x, this.nest.y) < 170) continue;
      this.add
        .image(x, y, rng.pick(['clover', 'pebble', 'flower', 'tuft', 'tuft', 'clover']))
        .setRotation(rng.realInRange(0, Math.PI * 2))
        .setScale(rng.realInRange(0.75, 1.35))
        .setDepth(1);
    }
    const band = this.add.graphics().setDepth(2);
    for (let i = 0; i < 10; i++) {
      const t = T.SOFT_EDGE * (1 - i / 10);
      band.fillStyle(0x0d2209, 0.075);
      band.fillRect(0, 0, W, t);
      band.fillRect(0, H - t, W, t);
      band.fillRect(0, T.SOFT_EDGE, t, H - 2 * T.SOFT_EDGE);
      band.fillRect(W - t, T.SOFT_EDGE, t, H - 2 * T.SOFT_EDGE);
    }
    for (let i = 0; i < 150; i++) {
      const side = rng.between(0, 3);
      const along = rng.realInRange(0, 1);
      const depth = rng.realInRange(4, T.SOFT_EDGE - 10);
      const x = side === 0 ? along * W : side === 1 ? along * W : side === 2 ? depth : W - depth;
      const y = side === 0 ? depth : side === 1 ? H - depth : along * H;
      this.add.image(x, y, 'tuft').setScale(rng.realInRange(1.1, 1.8)).setTint(0x8fbf7a).setDepth(2);
    }
    for (const h of spawnHoles()) this.holes.push(new Phaser.Math.Vector2(h.x, h.y));
    for (const h of this.holes) this.add.image(h.x, h.y, 'hole').setDepth(2.5);
    // The three rocks (sim/yard.ts): a static circle each, the art scaled to the circle.
    this.rocks = this.physics.add.staticGroup();
    for (const r of ROCKS) {
      const img = this.rocks.create(r.x, r.y, 'rock') as Phaser.Physics.Arcade.Image;
      img.setScale((r.r * 2 + 8) / img.width).setDepth(3.5);
      img.refreshBody();
      const sb = img.body as Phaser.Physics.Arcade.StaticBody;
      sb.setCircle(r.r, img.displayWidth / 2 - r.r, img.displayHeight / 2 - r.r);
      sb.reset();
    }
    // The two antlion pits (sim/roster.ts): sand that does nothing until an antlion digs in from round 15.
    for (const p of ANTLION_PITS) this.add.image(p.x, p.y, 'pit').setDepth(2.55);
    this.add.image(this.nest.x, this.nest.y, 'nest').setDepth(2.6);
    this.nestRing = this.add.graphics().setDepth(2.7);
  }

  update(_time: number, delta: number): void {
    const dt = Math.min(delta, 50) / 1000;
    // Lane G9 (design note, 2026-10-25): while a pick sheet (the three cards) is open the whole Yard holds still,
    // the round's countdown with it, and waits for the tap; then it runs on from where it stopped (sim/pause.ts). Lane
    // G9c: the break's countdown holds too, so a round never begins under the cards.
    const open = sheetOpen(this.pending, this.offer.length, this.phase);
    const tick = yardTick(this.yard, this.time.now, open);
    this.yard = tick.clock;
    const now = tick.now;
    if (open !== this.held) this.holdYard(open);
    if (tick.run && this.phase !== 'dead') {
      this.moveAnt(now);
      this.updateFire(now, dt);
      this.updatePredators(now, dt);
      this.updateCentipedes(now);
      this.updateFields(now);
      this.expire(this.darts, now);
      this.expire(this.shots, now);
      this.updatePickups(dt);
      this.updateDirector(now, dt);
      this.leftNestThisRound = trackLeftNest(this.leftNestThisRound, this.phase, this.inNest());
    }
    // In a break the save follows every change (beads landing, a pick, a buy) within half a second, a held Yard too (the
    // waiting pick, for Continue); it runs on the scene clock, which a pick sheet never stops. No buy goes through under
    // the cards (lane G9c, tryBuy and tryBuyLine).
    if (this.phase === 'break' && this.time.now >= this.nextSaveAt) {
      this.nextSaveAt = this.time.now + 500;
      this.writeSave(false);
    }
    this.drawAnt(now);
    this.drawNestRing(now);
    this.refreshSnap();
  }

  /** The Yard's time (ms): the scene clock less every span a pick sheet held the Yard (sim/pause.ts). */
  private get yardNow(): number {
    return yardTime(this.yard, this.time.now);
  }

  /** Lane G9: holds the Yard's physics and tweens while a pick sheet is open, and lets them go on the tap. */
  private holdYard(hold: boolean): void {
    this.held = hold;
    if (hold) {
      if (!this.physics.world.isPaused) this.physics.pause();
      this.tweens.pauseAll();
    } else {
      if (this.phase !== 'dead') this.physics.resume();
      this.tweens.resumeAll();
    }
  }

  /** For the smoke (lane G9): every live predator, dart and enemy shot, read on demand to show the Yard holds still. */
  yardSpots(): { foes: Array<{ kind: PredatorKind; x: number; y: number; hp: number }>; darts: Array<{ x: number; y: number }>; shots: Array<{ x: number; y: number }> } {
    const at = (g: Phaser.Physics.Arcade.Group | undefined) =>
      g ? (g.getChildren() as Phaser.Physics.Arcade.Image[]).filter((o) => o.active).map((o) => ({ x: +o.x.toFixed(2), y: +o.y.toFixed(2) })) : [];
    const foes = this.predators
      ? (this.predators.getChildren() as Predator[]).filter((p) => p.active).map((p) => ({ kind: p.kind, x: +p.x.toFixed(2), y: +p.y.toFixed(2), hp: p.hp }))
      : [];
    return { foes, darts: at(this.darts), shots: at(this.shots) };
  }

  private hud(): HudScene | null {
    const hud = this.scene.get('hud') as HudScene | null;
    return hud && hud.sys.isActive() ? hud : null;
  }

  private moveAnt(now: number): void {
    let dx = 0;
    let dy = 0;
    const hud = this.hud();
    if (hud && hud.stick.active) {
      dx = hud.stick.x;
      dy = hud.stick.y;
    } else if (this.cursors && this.wasd) {
      const c = this.cursors;
      const k = this.wasd;
      dx = (c.right.isDown || k.D.isDown ? 1 : 0) - (c.left.isDown || k.A.isDown ? 1 : 0);
      dy = (c.down.isDown || k.S.isDown ? 1 : 0) - (c.up.isDown || k.W.isDown ? 1 : 0);
    }
    const len = Math.hypot(dx, dy);
    this.moving = len > 0.01;
    const b = body(this.ant);
    // A live antlion pulls the ant toward its pit (standing still too); the stick adds on top, so running climbs out.
    const pull = this.pitPullOn(now);
    if (!this.moving) {
      b.setVelocity(pull.x, pull.y);
      return;
    }
    const slow = now < this.webUntil ? WEB_SLOW : 1;
    let vx = (dx / len) * this.build.speed * slow;
    let vy = (dy / len) * this.build.speed * slow;
    // The soft boundary: the outward part of the speed fades to zero across the edge band.
    const r = T.ANT_RADIUS;
    const e = T.SOFT_EDGE;
    const fade = (dist: number) => Phaser.Math.Clamp((dist - r) / (e - r), 0, 1);
    const { x, y } = this.ant;
    if (vx < 0 && x < e) vx *= fade(x);
    if (vx > 0 && x > T.WORLD_W - e) vx *= fade(T.WORLD_W - x);
    if (vy < 0 && y < e) vy *= fade(y);
    if (vy > 0 && y > T.WORLD_H - e) vy *= fade(T.WORLD_H - y);
    b.setVelocity(vx + pull.x, vy + pull.y);
    this.ant.setRotation(Math.atan2(dy, dx));
    if (now >= this.antStepAt) {
      this.antStep = !this.antStep;
      this.ant.setTexture(this.antStep ? 'ant1' : 'ant0');
      this.antStepAt = now + 110;
    }
  }

  /** The pull of every live antlion's pit on the ant this frame, in world units a second (sim/roster.ts pitPull). */
  private pitPullOn(now: number): { x: number; y: number } {
    let px = 0;
    let py = 0;
    for (const p of this.live) {
      if (!p.active || p.kind !== 'antlion' || p.pit < 0 || now < p.spawnUntil) continue;
      const pit = ANTLION_PITS[p.pit];
      const dx = pit.x - this.ant.x;
      const dy = pit.y - this.ant.y;
      const d = Math.hypot(dx, dy);
      const s = pitPull(d);
      if (s <= 0) continue;
      px += (dx / d) * s;
      py += (dy / d) * s;
    }
    return { x: px, y: py };
  }

  /** On screen: any part of the predator inside the camera's view (sim/hit.ts inView; design note, 2026-10-24). */
  private onScreen(x: number, y: number, kind: PredatorKind): boolean {
    return inView(x, y, PREDATORS[kind].radius, this.cameras.main.worldView);
  }

  private nearestPredator(range: number, now: number): Predator | null {
    let best: Predator | null = null;
    let bestD = range * range;
    for (const p of this.predators.getChildren() as Predator[]) {
      if (!p.active || now < p.spawnUntil || !this.onScreen(p.x, p.y, p.kind)) continue;
      const dx = p.x - this.ant.x;
      const dy = p.y - this.ant.y;
      const d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  private updateFire(now: number, dt: number): void {
    // Echo Sting: the queued repeats of the last shot, each at whoever is nearest when it fires.
    if (this.echoes.length > 0 && now >= this.echoes[0]) {
      this.echoes.shift();
      const echoTarget = this.nearestPredator(T.TARGET_RANGE, now);
      if (echoTarget) this.fireVolley(echoTarget, now);
    }
    this.fireCooldown -= dt;
    if (this.fireCooldown > 0) return;
    const target = this.nearestPredator(T.TARGET_RANGE, now);
    if (!target) return;
    this.fireVolley(target, now);
    for (let v = 1; v < this.build.volleys; v++) this.echoes.push(now + v * ECHO_DELAY_SECONDS * 1000);
    this.fireCooldown = fireIntervalSeconds(this.build, this.moving);
  }

  /** One volley at the target: the side by side darts (Twin Stinger, Front Fang) and the angled pairs (Fork Darts). */
  private fireVolley(target: Predator, now: number): void {
    const d = Phaser.Math.Distance.Between(this.ant.x, this.ant.y, target.x, target.y);
    const lead = d / T.DART_SPEED;
    const tv = body(target).velocity;
    const ang = Math.atan2(target.y + tv.y * lead - this.ant.y, target.x + tv.x * lead - this.ant.x);
    if (!this.moving) this.ant.setRotation(ang);
    const crit = !this.moving && Math.random() < this.build.critChance;
    const fury = this.build.fury ? furyFactor(this.hp, this.build.maxHp) : 1;
    const damage = this.build.damage * fury * (crit ? CRIT_MULTIPLIER : 1) * (this.assist ? ASSIST_DAMAGE : 1);
    const n = this.build.darts;
    // Every dart leaves from the ant's centre (sim/hit.ts dartOrigin); launchDart hits whatever sits at point blank.
    for (let i = 0; i < n; i++) {
      const o = dartOrigin(this.ant.x, this.ant.y, ang, n === 1 ? 0 : (i - (n - 1) / 2) * 14);
      if (!this.launchDart(o.x, o.y, ang, damage, crit, now)) return;
    }
    for (let k = 1; k <= this.build.forkPairs; k++) {
      for (const side of [-1, 1]) {
        const a = ang + (side * k * FORK_ANGLE_DEG * Math.PI) / 180;
        if (!this.launchDart(this.ant.x, this.ant.y, a, damage, crit, now)) return;
      }
    }
  }

  private launchDart(sx: number, sy: number, ang: number, damage: number, crit: boolean, now: number): boolean {
    const dart = this.darts.get(sx, sy, 'dart') as Dart | null;
    if (!dart) return false;
    dart.enableBody(true, sx, sy, true, true);
    dart.setTexture('dart').setRotation(ang).setDepth(7);
    body(dart).setCircle(5, dart.width / 2 - 5, dart.height / 2 - 5);
    dart.setVelocity(Math.cos(ang) * T.DART_SPEED, Math.sin(ang) * T.DART_SPEED);
    dart.damage = damage;
    dart.crit = crit;
    dart.dieAt = now + (T.DART_RANGE / T.DART_SPEED) * 1000;
    dart.pierce = this.build.pierce;
    dart.hopsLeft = this.build.hops;
    dart.hits.length = 0;
    this.pointBlank(dart, ang, now);
    return true;
  }

  /**
   * Point blank (VG3): a predator the dart touches before its first overlap test, one 60 Hz physics step out, is hit
   * at launch, so a termite sitting on a still ant dies like any other. A piercing dart goes on to the next one.
   */
  private pointBlank(dart: Dart, ang: number, now: number): void {
    const reach = T.DART_SPEED / 60 + 2;
    const ux = Math.cos(ang);
    const uy = Math.sin(ang);
    for (let k = 0; k < 4 && dart.active; k++) {
      const cand: Predator[] = [];
      const discs: Disc[] = [];
      for (const q of this.predators.getChildren() as Predator[]) {
        if (!q.active || now < q.spawnUntil || dart.hits.includes(q)) continue;
        cand.push(q);
        discs.push({ x: q.x, y: q.y, r: PREDATORS[q.kind].radius });
      }
      const i = firstTouched(dart.x, dart.y, ux, uy, reach, 5, discs);
      if (i < 0) return;
      const hopsBefore = dart.hopsLeft;
      this.onDartHit(dart, cand[i]);
      if (dart.hopsLeft !== hopsBefore) return;
    }
  }

  /** A dart hits a predator; (hx, hy) is where, for a hit on a centipede's body (the head otherwise). */
  private onDartHit(dart: Dart, p: Predator, hx = p.x, hy = p.y): void {
    if (!dart.active || !p.active || this.phase === 'dead') return;
    if (dart.hits.includes(p)) return;
    // A dart passes over what the player cannot see (design note, 2026-10-24): it hits only on screen.
    if (!this.onScreen(hx, hy, p.kind)) return;
    const now = this.yardNow;
    if (now < p.spawnUntil) {
      dart.disableBody(true, true);
      return;
    }
    const boss = isBossKind(p.kind);
    const lucky = luckyHit(this.build, !p.struck, boss, Math.random());
    p.struck = true;
    // The beetle's shell halves a dart that flies into its face (sim/roster.ts shellFactor); its back and sides take it all.
    const v = body(dart).velocity;
    const factor = p.kind === 'beetle' ? shellFactor(p.heading, v.x, v.y) : 1;
    const damage = (this.blessing === 'instakill' && !boss) || lucky ? p.hp : dart.damage * factor;
    p.hp -= damage;
    this.hitLog.push({ kind: p.kind, raw: dart.damage, dealt: damage, factor, body: hx !== p.x || hy !== p.y });
    if (this.hitLog.length > 12) this.hitLog.shift();
    p.flashUntil = now + 60;
    // Design note, 2026-10-24: each element fires on one hit in five, each on its own roll (sim/growth.ts elementProc).
    if (this.build.frost || this.build.fire || this.build.spark) this.procs.hits += 1;
    if (this.build.frost && elementProc(this.chance())) {
      p.slowUntil = now + FROST_SECONDS * 1000;
      this.procs.slow += 1;
    }
    // Slice 4: fire sets the foe burning, spark arcs to the one nearest other foe (sim/growth.ts).
    if (this.build.fire && p.hp > 0 && elementProc(this.chance())) {
      this.ignite(p, dart.damage, now);
      this.procs.burn += 1;
    }
    if (this.build.spark && elementProc(this.chance())) {
      this.procs.spark += 1;
      this.sparkFrom(p, dart.damage, now);
    }
    this.earn(nectarGain(NECTAR_PER_HIT, this.nectarMultiplier()));
    const big = dart.crit || lucky;
    const shelled = factor < 1 && !lucky;
    // Design note, 2026-10-24: hits on one predator within half a second show one number, their total (sim/hit.ts groupHit);
    // a lucky kill keeps its own word. A new group pops up a little to one side, so separate bursts fan out.
    const color = lucky ? '#7dffc4' : shelled ? '#b9c7d6' : dart.crit ? '#ffe14d' : '#ffffff';
    if (lucky) this.floatText(hx, hy - 20, 'LUCKY', color, 34, true);
    else {
      const g = groupHit(p.hitGroup, damage, now);
      p.hitGroup = g.group;
      const label = String(Math.round(g.group.total));
      if (g.joined && p.hitText && p.hitText.visible && p.hitText.getData('owner') === p) this.refloat(p.hitText, hx, hy - 20, label, color, big);
      else {
        const jx = (Math.random() - 0.5) * 26;
        p.hitText = this.floatText(hx + jx, hy - 20, label, color, big ? 34 : 24, big);
        p.hitText.setData('owner', p);
      }
    }
    // A big hit (a crit or a lucky kill) gives a short shake, at most one every 140 ms so a crit storm stays readable.
    if (big && now >= this.nextHitShakeAt) {
      this.nextHitShakeAt = now + 140;
      this.cameras.main.shake(70, 0.0032);
    }
    if (p.hp <= 0) this.killPredator(p);
    // What the dart does next: Bounce Venom hops while it has hops, then Needle Point carries it on, else it is spent.
    dart.hits.push(p);
    if (dart.hopsLeft > 0) {
      const next = this.nearestUnhit(dart, now);
      if (next) {
        dart.hopsLeft -= 1;
        dart.damage *= HOP_KEEP;
        const a = Math.atan2(next.y - dart.y, next.x - dart.x);
        dart.setVelocity(Math.cos(a) * T.DART_SPEED, Math.sin(a) * T.DART_SPEED).setRotation(a);
        dart.dieAt = now + (T.DART_RANGE / T.DART_SPEED) * 1000;
        return;
      }
    }
    if (dart.pierce) {
      dart.damage *= NEEDLE_KEEP;
      return;
    }
    dart.disableBody(true, true);
  }

  /** The nearest live predator this dart has not hit yet, inside the hop range. */
  private nearestUnhit(dart: Dart, now: number): Predator | null {
    let best: Predator | null = null;
    let bestD = HOP_RANGE * HOP_RANGE;
    for (const q of this.predators.getChildren() as Predator[]) {
      if (!q.active || now < q.spawnUntil || dart.hits.includes(q) || !this.onScreen(q.x, q.y, q.kind)) continue;
      const dx = q.x - dart.x;
      const dy = q.y - dart.y;
      const d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = q;
      }
    }
    return best;
  }

  /** Nectar comes in (a hit, a bead): the run holds it and the ledger counts it as earned. */
  private earn(n: number): void {
    this.nectar += n;
    this.ledger.earned += n;
  }

  /** Double nectar from the Queen's Blessing, times Sweet Tooth on a Colony run. */
  private nectarMultiplier(): number {
    return (this.blessing === 'double' ? 2 : 1) * this.nectarGain;
  }

  private killPredator(p: Predator): void {
    // VG5 F1: a kill inside a kill (a spark kills a neighbour whose Flame Burst kills this dart's target first) must not
    // kill the target a second time and pay its bead, experience and combos again: a predator already down is left alone.
    if (!p.active) return;
    const spec = PREDATORS[p.kind];
    const x = p.x;
    const y = p.y;
    const dist = Phaser.Math.Distance.Between(this.ant.x, this.ant.y, x, y);
    this.puffs.get(p.kind)?.explode(14, x, y);
    this.popRing(x, y, PUFF_TINT[p.kind], PREDATORS[p.kind].radius);
    // A centipede bursts along its whole body.
    for (const sp of p.segPos) this.puffs.get(p.kind)?.explode(5, sp.x, sp.y);
    this.dropBody(p);
    p.disableBody(true, true);
    this.kills++;
    this.gainXp(xpForKill(p.kind));
    this.spawnPickup('bead', x, y, nectarGain(killNectar(spec.nectar, dist), this.nectarMultiplier()));
    // An ember ant shot down pops where it fell: the burst hurts the predators round it, never the ant.
    if (p.kind === 'ember') this.emberBurst(p, false);
    // Slice 4: the combos a second element unlocks all fire on a kill.
    this.comboOnKill(p, x, y);
    const last = this.queued === 0 && this.predators.countActive(true) === 0;
    if (isBossKind(p.kind)) {
      // A boss's reward: its big bead (above), Royal Jelly (full health, and a free pick below the cap) and a banner.
      this.spawnPickup('jelly', x + 30, y, 0);
      this.pushBanner(`${spec.name.toUpperCase()} DOWN`, picksOpen(this.level) ? 'Royal Jelly: full health and a free pick' : 'Royal Jelly: full health', '#ffb38a');
      this.cameras.main.shake(260, 0.012);
    } else if (this.plan && this.plan.kind === 'breather' && last) {
      this.spawnPickup('jelly', x, y, 0);
    } else if (
      blessingCanDrop(this.round) &&
      this.blessing === null &&
      !this.pickups.some((k) => k.kind === 'crown') &&
      Math.random() < BLESSING_DROP_CHANCE
    ) {
      this.spawnPickup('crown', x, y, 0);
    }
    this.cameras.main.shake(60, 0.0018);
    blip('kill');
  }

  /** Experience from a kill; each level gained queues a pick (sim/growth.ts addXp, capped at level 12). */
  private gainXp(gain: number): void {
    const r = addXp({ level: this.level, xp: this.xp }, gain);
    this.level = r.level;
    this.xp = r.xp;
    if (r.ups > 0) {
      this.floatText(this.ant.x, this.ant.y - 64, `LEVEL ${this.level}`, '#c9b6ff', 34);
      this.queuePicks(r.ups, 'LEVEL UP: PICK ONE');
    }
  }

  /** Queues picks (a level up, or a bonus pick): the sheet shows the first offer and the Yard holds still until the tap. */
  private queuePicks(n: number, title: string): void {
    this.pending += n;
    this.pickTitle = title;
    if (this.offer.length === 0) this.offer = this.nextOffer();
    blip('level');
  }

  /** Called by the HUD's pick cards: takes one of the offered powers. With the last pick taken the Yard runs on next frame. */
  pickPower(id: PowerId): boolean {
    if (this.phase === 'dead' || this.pending <= 0 || !this.offer.includes(id) || !canTake(this.stacks, id)) {
      blip('denied');
      return false;
    }
    const oldMax = this.build.maxHp;
    this.stacks = takePower(this.stacks, id);
    this.build = deriveBuild(this.perkStats, this.stacks);
    this.hp = healthAfterPick(id, this.hp, oldMax, this.build.maxHp);
    this.pending -= 1;
    this.offer = this.pending > 0 ? this.nextOffer() : [];
    this.floatText(this.ant.x, this.ant.y - 50, powerSpec(id).name.toUpperCase(), '#c9b6ff', 28);
    blip('buy');
    return true;
  }

  private onBite(p: Predator): void {
    if (!p.active || this.phase === 'dead') return;
    const now = this.yardNow;
    if (now < p.spawnUntil || now < p.biteReadyAt || now < this.graceUntil || now < p.blindUntil) return;
    // A predator with no bite (the ember ant, which bursts instead) touches without hurting and grants no grace.
    // Lane G9, M4: a later termite rush bites harder (curve.ts breatherByAppearance, at most double).
    const plan = this.plan;
    const base = PREDATORS[p.kind].biteDamage;
    const bite = p.kind === 'termite' && plan && plan.kind === 'breather' ? Math.round(base * plan.termiteBite) : base;
    if (bite <= 0) return;
    p.biteReadyAt = now + T.BITE_COOLDOWN_MS;
    this.hurt(bite, now);
  }

  private onShotHit(s: Shot): void {
    if (!s.active || this.phase === 'dead') return;
    s.disableBody(true, true);
    const now = this.yardNow;
    if (now < this.graceUntil) return;
    if (s.web) {
      this.webUntil = now + WEB_SECONDS * 1000;
      this.floatText(this.ant.x, this.ant.y - 52, 'WEBBED', '#dfe9ff', 26);
    }
    this.hurt(s.damage, now);
  }

  private hurt(raw: number, now: number): void {
    // Nothing to take: no grace, no number, no shake (slice 4: a zero bite once ate the ember's own burst).
    if (this.assist || raw <= 0) return;
    // Slice 4: no single hit takes more than a fifth of the max health (sim/economy.ts capHit); then Stone Stance
    // (standing still) and Plated Back from the colony cut what is left.
    const capped = capHit(raw, this.build.maxHp);
    const damage = armoredDamage(damageTaken(capped, this.build, this.moving), this.armor);
    this.hurtLog.push({ raw, capped, taken: damage, maxHp: this.build.maxHp });
    if (this.hurtLog.length > 12) this.hurtLog.shift();
    this.hp = Math.max(0, this.hp - damage);
    this.graceUntil = now + T.GRACE_MS;
    // A hit worth a tenth of the ant's health or more shakes harder and longer.
    const heavy = damage >= this.build.maxHp * 0.1;
    // Design note, 2026-10-24: hits on the ant within half a second show one number, their total.
    const g = groupHit(this.antHitGroup, damage, now);
    this.antHitGroup = g.group;
    const label = `-${Math.max(1, Math.round(g.group.total))}`;
    const own = this.antHitText;
    if (g.joined && own && own.visible && own.getData('owner') === 'ant') this.refloat(own, this.ant.x, this.ant.y - 34, label, '#ff5a4f', heavy);
    else {
      this.antHitText = this.floatText(this.ant.x, this.ant.y - 34, label, '#ff5a4f', heavy ? 36 : 30, heavy);
      this.antHitText.setData('owner', 'ant');
    }
    this.cameras.main.shake(heavy ? 160 : 110, heavy ? 0.009 : 0.006);
    blip('hurt');
    if (this.hp <= 0) this.die();
  }

  private die(): void {
    this.phase = 'dead';
    // A run ends its save on death.
    if (!this.practice) clearRun(browserRunStore());
    this.lastSaveJson = '';
    body(this.ant).setVelocity(0, 0);
    this.ant.setAlpha(1).setTint(0x5c5c5c);
    this.physics.pause();
    // A Colony run banks the nectar it still holds; Pure has no meta, so nothing is banked there.
    if (!this.practice && this.ladder === 'colony') {
      this.banked = Math.max(0, Math.floor(this.nectar));
      this.colony = { ...this.colony, bank: bankAfterRun(this.colony.bank, this.nectar) };
      saveColony(browserStore(), this.colony);
    }
    // Lane G7, M3: a Daily run keeps its own best for its day, never the Pure best.
    this.record = this.practice
      ? null
      : this.daily
        ? recordDaily(browserStore(), this.daily, this.round)
        : recordRun(browserStore(), this.round, BEST_KEYS[this.ladder]);
    if (this.daily && this.daily === this.today) this.dailyBest = readDailyBest(browserStore(), this.today);
  }

  private updatePredators(now: number, dt: number): void {
    const live = this.live;
    live.length = 0;
    for (const p of this.predators.getChildren() as Predator[]) if (p.active) live.push(p);
    const n = live.length;
    const sx = this.sepX;
    const sy = this.sepY;
    for (let i = 0; i < n; i++) {
      sx[i] = 0;
      sy[i] = 0;
    }
    for (let i = 0; i < n; i++) {
      const a = live[i];
      for (let j = i + 1; j < n; j++) {
        const b = live[j];
        if (a.flying !== b.flying) continue;
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const min = PREDATORS[a.kind].radius + PREDATORS[b.kind].radius;
        const d2 = dx * dx + dy * dy;
        if (d2 >= min * min || d2 === 0) continue;
        const d = Math.sqrt(d2);
        const push = (min - d) / min;
        const ux = dx / d;
        const uy = dy / d;
        sx[i] -= ux * push;
        sy[i] -= uy * push;
        sx[j] += ux * push;
        sy[j] += uy * push;
      }
    }
    for (let i = 0; i < n; i++) {
      const p = live[i];
      // A burst earlier in this loop can have killed it (slice 4).
      if (!p.active) continue;
      // Fire Venom's burn ticks every half second until it runs out (sim/growth.ts burnPerTick).
      if (p.burnUntil > 0 && now >= p.burnNext) {
        if (p.burnNext > p.burnUntil) p.burnUntil = 0;
        else {
          p.burnNext += FIRE_TICK_SECONDS * 1000;
          p.hp -= p.burnTick;
          p.flashUntil = now + 40;
          if (p.hp <= 0) {
            this.killPredator(p);
            continue;
          }
        }
      }
      const spec = PREDATORS[p.kind];
      const b = body(p);
      if (now < p.spawnUntil) {
        b.setVelocity(0, 0);
        continue;
      }
      // Every predator hunts the ant except the Anteater, which walks for the nest.
      const raid = spec.behaviour === 'nestRaid';
      const turner = spec.behaviour === 'tank' || spec.behaviour === 'snake' || spec.behaviour === 'sweep';
      const pitted = spec.behaviour === 'pitTrap';
      const tx = raid ? this.nest.x : this.ant.x;
      const ty = raid ? this.nest.y : this.ant.y;
      const dx = tx - p.x;
      const dy = ty - p.y;
      const d = Math.hypot(dx, dy) || 1;
      // Walkers steer round the rocks (sim/yard.ts steerAround); wasps fly straight over them.
      const way = p.flying ? { x: dx / d, y: dy / d } : steerAround(p.x, p.y, tx, ty, spec.radius);
      const ux = way.x;
      const uy = way.y;
      let vx = ux * p.speed;
      let vy = uy * p.speed;
      if (turner) {
        // Beetles, centipedes and the mantis turn slowly toward their way (sim/roster.ts turnToward): circle one to beat it.
        // A mantis with its blades up holds its heading, so the arc it shows is the arc that falls.
        const holding = spec.behaviour === 'sweep' && p.windupAt > 0;
        if (!holding && Math.hypot(ux, uy) > 0) p.heading = turnToward(p.heading, Math.atan2(uy, ux), (TURN_RATE[p.kind] ?? Math.PI) * dt);
        vx = Math.cos(p.heading) * p.speed;
        vy = Math.sin(p.heading) * p.speed;
        if (spec.behaviour === 'sweep') {
          if (p.windupAt > 0) {
            vx = 0;
            vy = 0;
            if (now >= p.windupAt) this.mantisSweep(p, now);
          } else if (now >= p.shotReadyAt && d <= MANTIS_REACH && now >= p.blindUntil) p.windupAt = now + MANTIS_WINDUP_SECONDS * 1000;
        }
      } else if (spec.behaviour === 'burst') {
        // The ember ant runs in at the round's pace; close to the ant it lights its fuse, stops and bursts.
        if (p.fuseAt === 0 && d <= EMBER_FUSE_RANGE && now >= p.blindUntil) p.fuseAt = now + EMBER_FUSE_SECONDS * 1000;
        if (p.fuseAt > 0) {
          vx = 0;
          vy = 0;
          if (now >= p.fuseAt) {
            this.emberBurst(p, true);
            continue;
          }
        }
      } else if (spec.behaviour === 'flutter') {
        // The moth jinks: a new heading every 0.35 to 0.7 s, up to 75 degrees off the ant, straight in when close.
        if (now >= p.jinkAt || d <= MOTH_DIVE_RANGE) {
          p.heading = mothHeading(Math.atan2(dy, dx), Math.random(), d);
          if (now >= p.jinkAt) p.jinkAt = now + (MOTH_JINK_MIN + Math.random() * (MOTH_JINK_MAX - MOTH_JINK_MIN)) * 1000;
        }
        vx = Math.cos(p.heading) * p.speed;
        vy = Math.sin(p.heading) * p.speed;
      } else if (pitted) {
        vx = 0;
        vy = 0;
      } else if (raid) {
        p.eating = d <= ANTEATER_REACH;
        if (p.eating) {
          vx = 0;
          vy = 0;
          this.gulp(p, now);
        }
      } else if (spec.behaviour === 'hoverSting' || spec.behaviour === 'webSpit' || spec.behaviour === 'brood') {
        const near = spec.behaviour === 'hoverSting' ? 180 : spec.behaviour === 'brood' ? 220 : 200;
        const far = spec.behaviour === 'hoverSting' ? 270 : spec.behaviour === 'brood' ? 300 : 250;
        // The Brood Hornet keeps calling wasps out of itself while it lives.
        if (spec.behaviour === 'brood' && now >= p.broodAt) {
          p.broodAt = now + HORNET_BROOD_SECONDS * 1000;
          this.callBrood(p);
        }
        if (d < near) {
          vx = -ux * p.speed * 0.8;
          vy = -uy * p.speed * 0.8;
        } else if (d < far) {
          const s = p.strafe * p.speed * (spec.behaviour === 'hoverSting' ? 0.6 : 0.4);
          vx = -uy * s;
          vy = ux * s;
        }
        if (p.windupAt > 0 && now >= p.windupAt) {
          this.fireShot(p, now);
          p.windupAt = 0;
          p.shotReadyAt = now + spec.shotEvery * 1000;
        } else if (p.windupAt === 0 && now >= p.shotReadyAt && d < spec.shotRange && now >= p.blindUntil) {
          p.windupAt = now + T.SHOT_WINDUP_MS;
        }
        if (p.windupAt > 0) {
          vx *= 0.25;
          vy *= 0.25;
        }
      }
      // The bosses, the beetle, the antlion and the centipede are too heavy for the crowd to push; the crowd makes way.
      if (!raid && !turner && !pitted && !isBossKind(p.kind)) {
        vx += sx[i] * T.SEPARATION;
        vy += sy[i] * T.SEPARATION;
      }
      // A walker pressed on a rock that barely moves for 2 s steps along the rock's edge for 1 s, then strafes the
      // other way round (VG3: spiders parked in their web band behind a rock).
      if (!p.flying && dt > 0) {
        const rock = rockTouching(p.x, p.y, spec.radius);
        const moved = Math.hypot(p.x - p.lastX, p.y - p.lastY) / dt;
        const st = stallStep({ stalledFor: p.stalledFor, sidestepLeft: p.sidestepLeft }, rock !== null, moved, dt);
        p.stalledFor = st.stalledFor;
        p.sidestepLeft = st.sidestepLeft;
        if (st.started) p.strafe = -p.strafe;
        if (st.sidestep && rock && !pitted) {
          const h = sidestepHeading(p.x, p.y, rock, p.strafe);
          vx = h.x * p.speed;
          vy = h.y * p.speed;
          if (turner) p.heading = Math.atan2(h.y, h.x);
        }
      }
      p.lastX = p.x;
      p.lastY = p.y;
      // Blinded in the steam (fire plus frost): the foe has lost the ant and drifts.
      if (now < p.blindUntil) {
        vx = Math.cos(p.wander) * p.speed * BLIND_DRIFT;
        vy = Math.sin(p.wander) * p.speed * BLIND_DRIFT;
      }
      if (now < p.slowUntil) {
        vx *= FROST_SLOW;
        vy *= FROST_SLOW;
      }
      const v = Math.hypot(vx, vy);
      if (v > MAX_PREDATOR_SPEED) {
        vx *= MAX_PREDATOR_SPEED / v;
        vy *= MAX_PREDATOR_SPEED / v;
      }
      b.setVelocity(vx, vy);
      const chaser = spec.behaviour === 'chase' || spec.behaviour === 'rush' || spec.behaviour === 'burst' || spec.behaviour === 'flutter' || raid;
      p.setRotation(turner ? p.heading : chaser && v > 1 ? Math.atan2(vy, vx) : Math.atan2(dy, dx));
      if (p.kind === 'centipede') this.followBody(p);
      if (now >= p.stepAt) {
        p.step = !p.step;
        p.setTexture(p.step ? `${p.kind}1` : `${p.kind}0`);
        p.stepAt = now + (p.kind === 'wasp' ? 45 : Math.max(70, 16000 / Math.max(60, p.speed)));
      }
      if (now < p.flashUntil) p.setTintFill(0xffffff);
      else if (p.fuseAt > 0) p.setTintFill(Math.floor(now / 70) % 2 === 0 ? 0xffffff : 0xff3b00);
      else if (p.windupAt > 0) p.setTint(0xff9a3d);
      else p.clearTint();
    }
    this.drawSweeps(now);
  }

  /** The mantis's red arc while its blades are up: where the sweep will fall, brighter as it nears. */
  private drawSweeps(now: number): void {
    const g = this.sweepGfx;
    g.clear();
    const arc = (MANTIS_ARC_DEG * Math.PI) / 180;
    for (const p of this.live) {
      if (!p.active || p.kind !== 'mantis' || p.windupAt <= 0) continue;
      const left = Math.max(0, (p.windupAt - now) / (MANTIS_WINDUP_SECONDS * 1000));
      g.fillStyle(0xff2a1a, 0.18 + 0.32 * (1 - left));
      g.slice(p.x, p.y, MANTIS_REACH, p.heading - arc, p.heading + arc, false);
      g.fillPath();
      g.lineStyle(4, 0xff5a3d, 0.85);
      g.strokePath();
    }
  }

  /**
   * An ember ant bursts. Its fuse ran out: the ant inside the burst takes it (the hit cap holds) and the ember is gone,
   * no bead. Shot down (killPredator): it pops on the predators only. Either way the predators inside lose a share of
   * the round's health, so shooting one in a crowd clears the crowd.
   */
  private emberBurst(p: Predator, fuseRanOut: boolean): void {
    const now = this.yardNow;
    const x = p.x;
    const y = p.y;
    const toAnt = emberBurstOnAnt(fuseRanOut, Math.hypot(this.ant.x - x, this.ant.y - y));
    let antTook = 0;
    if (toAnt > 0 && now >= this.graceUntil && this.phase !== 'dead') {
      const before = this.hp;
      this.hurt(toAnt, now);
      antTook = before - this.hp;
    }
    if (fuseRanOut) {
      this.dropBody(p);
      p.disableBody(true, true);
    }
    const share = this.plan ? Math.round(this.plan.health * EMBER_BURST_PREDATOR_SHARE) : 0;
    let hit = 0;
    for (const q of this.predators.getChildren() as Predator[]) {
      if (q === p || !q.active || now < q.spawnUntil) continue;
      if (!inBurst(Math.hypot(q.x - x, q.y - y))) continue;
      hit += 1;
      q.hp -= share;
      q.flashUntil = now + 60;
      if (q.hp <= 0) this.killPredator(q);
    }
    this.burstLog.push({ fuse: fuseRanOut, antTook, predatorsHit: hit });
    if (this.burstLog.length > 12) this.burstLog.shift();
    this.puffs.get('ember')?.explode(26, x, y);
    this.popRing(x, y, 0xff7a1a, EMBER_BURST_RADIUS / 1.6);
    this.cameras.main.shake(90, 0.004);
  }

  /** The mantis's blades fall: inside the arc (sim/roster.ts inSweep) the ant takes the sweep; then it rests. */
  private mantisSweep(p: Predator, now: number): void {
    p.windupAt = 0;
    p.shotReadyAt = now + MANTIS_REST_SECONDS * 1000;
    const hit = inSweep(this.ant.x - p.x, this.ant.y - p.y, p.heading);
    this.sweepLog.push({ hit });
    if (this.sweepLog.length > 12) this.sweepLog.shift();
    if (hit && now >= this.graceUntil && this.phase !== 'dead') this.hurt(MANTIS_SWEEP_DAMAGE, now);
    this.popRing(p.x + Math.cos(p.heading) * 70, p.y + Math.sin(p.heading) * 70, 0xff5a3d, 40);
  }

  /** The Brood Hornet calls two wasps out of itself, never past the round's alive cap; they are extra, the round waits for them too. */
  private callBrood(p: Predator): void {
    const plan = this.plan;
    if (!plan) return;
    const n = broodCall(this.predators.countActive(true), plan.aliveCap, p.broodCalls);
    p.broodCalls += 1;
    for (let i = 0; i < n; i++) this.spawnPredator(plan, 'wasp', { x: p.x + (i === 0 ? -30 : 30), y: p.y });
  }

  /** Fire Venom: the foe burns for 30 percent more of the hit over 2 s; a new hit starts the burn again, never weaker. */
  private ignite(p: Predator, hit: number, now: number): void {
    const burning = p.burnUntil > now;
    p.burnTick = Math.max(burning ? p.burnTick : 0, burnPerTick(hit));
    if (!burning) p.burnNext = now + FIRE_TICK_SECONDS * 1000;
    p.burnUntil = now + FIRE_BURN_SECONDS * 1000;
  }

  /** Spark Venom: a hit arcs to the nearest other foe within 220 units for 40 percent of the hit. */
  private sparkFrom(p: Predator, hit: number, now: number): void {
    let best: Predator | null = null;
    let bestD = SPARK_RANGE * SPARK_RANGE;
    for (const q of this.predators.getChildren() as Predator[]) {
      if (q === p || !q.active || now < q.spawnUntil || !this.onScreen(q.x, q.y, q.kind)) continue;
      const dx = q.x - p.x;
      const dy = q.y - p.y;
      const d2 = dx * dx + dy * dy;
      if (d2 < bestD) {
        bestD = d2;
        best = q;
      }
    }
    if (!best) return;
    this.sparkCount += 1;
    this.sparkSegs.push({ x1: p.x, y1: p.y, x2: best.x, y2: best.y, until: now + 110 });
    if (this.sparkSegs.length > 24) this.sparkSegs.shift();
    best.hp -= hit * SPARK_SHARE;
    best.flashUntil = now + 60;
    if (best.hp <= 0) this.killPredator(best);
  }

  /** The combos on a kill (sim/growth.ts combosOf): a shock puddle, blinding steam, a flame burst. */
  private comboOnKill(p: Predator, x: number, y: number): void {
    const c = combosOf(this.stacks);
    const now = this.yardNow;
    // Design note, 2026-10-24: each combo fires on one kill in five, each on its own roll.
    if (c.puddle || c.steam || c.burst) this.procs.kills += 1;
    const puddle = c.puddle && elementProc(this.chance());
    const steam = c.steam && elementProc(this.chance());
    const burst = c.burst && elementProc(this.chance());
    if (puddle) {
      this.procs.puddle += 1;
      this.layField(this.puddles, x, y, now + PUDDLE_SECONDS * 1000);
    }
    if (steam) {
      this.procs.steam += 1;
      this.layField(this.steams, x, y, now + STEAM_SECONDS * 1000);
    }
    if (burst) {
      this.procs.burst += 1;
      const dmg = this.build.damage * BURST_SHARE;
      this.popRing(x, y, 0xff8a2a, BURST_RADIUS / 1.6);
      for (const q of this.predators.getChildren() as Predator[]) {
        if (q === p || !q.active || now < q.spawnUntil) continue;
        if (Math.hypot(q.x - x, q.y - y) > BURST_RADIUS) continue;
        this.comboHits.burst += 1;
        q.hp -= dmg;
        q.flashUntil = now + 60;
        if (q.hp <= 0) this.killPredator(q);
      }
    }
  }

  /** Lays a puddle or a steam cloud from its pool (the oldest is reused when all are out). */
  private layField(pool: Array<{ img: Phaser.GameObjects.Image; x: number; y: number; until: number; next: number }>, x: number, y: number, until: number): void {
    if (pool.length === 0) return;
    let f = pool.find((k) => k.until <= this.yardNow) ?? null;
    if (!f) f = pool.reduce((a, b) => (a.until <= b.until ? a : b));
    f.x = x;
    f.y = y;
    f.until = until;
    f.next = this.yardNow;
    this.tweens.killTweensOf(f.img);
    f.img.setPosition(x, y).setVisible(true).setAlpha(0.9).setScale(0.5);
    this.tweens.add({ targets: f.img, scale: 1, duration: 180, ease: 'Back.easeOut' });
  }

  /** The puddles hurt and slow, the steam blinds, every quarter second; the spark arcs fade; both fields run out on time. */
  private updateFields(now: number): void {
    const tick = PUDDLE_TICK_SECONDS * 1000;
    for (const f of this.puddles) {
      if (!f.img.visible) continue;
      if (now >= f.until) {
        f.img.setVisible(false);
        continue;
      }
      f.img.setAlpha(0.55 + 0.35 * Math.abs(Math.sin(now / 90)));
      if (now < f.next) continue;
      f.next = now + tick;
      const dmg = this.build.damage * PUDDLE_TICK_SHARE;
      for (const q of this.predators.getChildren() as Predator[]) {
        if (!q.active || now < q.spawnUntil || q.flying) continue;
        if (Math.hypot(q.x - f.x, q.y - f.y) > PUDDLE_RADIUS) continue;
        this.comboHits.puddle += 1;
        q.hp -= dmg;
        q.slowUntil = Math.max(q.slowUntil, now + tick + 50);
        q.flashUntil = now + 40;
        if (q.hp <= 0) this.killPredator(q);
      }
    }
    for (const f of this.steams) {
      if (!f.img.visible) continue;
      if (now >= f.until) {
        f.img.setVisible(false);
        continue;
      }
      f.img.setAlpha(0.35 + 0.45 * Math.max(0, (f.until - now) / (STEAM_SECONDS * 1000)));
      if (now < f.next) continue;
      f.next = now + tick;
      for (const q of this.predators.getChildren() as Predator[]) {
        if (!q.active || now < q.spawnUntil) continue;
        if (Math.hypot(q.x - f.x, q.y - f.y) > STEAM_RADIUS) continue;
        if (q.blindUntil <= now) q.wander = Math.random() * Math.PI * 2;
        q.blindUntil = now + BLIND_SECONDS * 1000;
        q.windupAt = q.kind === 'mantis' ? 0 : q.windupAt;
        this.comboHits.steam += 1;
      }
    }
    const g = this.sparkGfx;
    g.clear();
    for (const sg of this.sparkSegs) {
      if (sg.until <= now) continue;
      const mx = (sg.x1 + sg.x2) / 2 + (Math.random() - 0.5) * 24;
      const my = (sg.y1 + sg.y2) / 2 + (Math.random() - 0.5) * 24;
      g.lineStyle(5, 0x1f1206, 0.7);
      g.beginPath();
      g.moveTo(sg.x1, sg.y1);
      g.lineTo(mx, my);
      g.lineTo(sg.x2, sg.y2);
      g.strokePath();
      g.lineStyle(3, 0xfff59d, 1);
      g.beginPath();
      g.moveTo(sg.x1, sg.y1);
      g.lineTo(mx, my);
      g.lineTo(sg.x2, sg.y2);
      g.strokePath();
    }
  }

  /** The ant's look: the element aura, the level rim and the armour plates (sim/growth.ts antLook). */
  private drawLook(now: number): void {
    const look = antLook(this.level, this.build.maxHp, this.stacks);
    const g = this.lookGfx;
    g.clear();
    const show = this.phase !== 'dead' && this.phase !== 'title';
    if (show && look.aura.length > 0) {
      const color = look.aura[Math.floor(now / 260) % look.aura.length];
      g.fillStyle(color, 0.2 + 0.1 * Math.sin(now / 140));
      g.fillCircle(this.ant.x, this.ant.y, 34);
      g.lineStyle(3, color, 0.75);
      g.strokeCircle(this.ant.x, this.ant.y, 31);
    }
    if (show && look.rim !== null) {
      g.lineStyle(3, look.rim, 0.9);
      g.strokeCircle(this.ant.x, this.ant.y, 26);
    }
    if (show && look.plates > 0) {
      this.platesImg.setTexture(`plates${look.plates}`).setPosition(this.ant.x, this.ant.y).setRotation(this.ant.rotation).setAlpha(this.ant.alpha).setVisible(true);
    } else this.platesImg.setVisible(false);
  }

  /** The centipede's body follows the path its head took (sim/roster.ts placeSegments), each segment facing the one ahead. */
  private followBody(p: Predator): void {
    const t = p.trail;
    if (t.length < 2 || Math.hypot(p.x - t[0], p.y - t[1]) > 0.5) t.unshift(p.x, p.y);
    const keep = 2 * (Math.ceil((CENTIPEDE_SEGMENTS * CENTIPEDE_SPACING) / 2) + 4);
    if (t.length > keep) t.length = keep;
    p.segPos = placeSegments(t, CENTIPEDE_SEGMENTS, CENTIPEDE_SPACING);
    let ax = p.x;
    let ay = p.y;
    p.segPos.forEach((sp, i) => {
      const img = p.segs[i];
      if (!img) return;
      img.setPosition(sp.x, sp.y).setRotation(Math.atan2(ay - sp.y, ax - sp.x)).setAlpha(p.alpha);
      if (p.flashUntil > this.yardNow) img.setTintFill(0xffffff);
      else img.clearTint();
      ax = sp.x;
      ay = sp.y;
    });
  }

  /** A centipede's body bites and takes darts along its whole length, not only at the head. */
  private updateCentipedes(now: number): void {
    const reach = T.ANT_RADIUS + CENTIPEDE_SEG_RADIUS;
    for (const p of this.live) {
      if (!p.active || p.kind !== 'centipede' || now < p.spawnUntil) continue;
      for (const sp of p.segPos) {
        if (Math.hypot(sp.x - this.ant.x, sp.y - this.ant.y) < reach) {
          this.onBite(p);
          break;
        }
      }
      for (const d of this.darts.getChildren() as Dart[]) {
        if (!d.active || d.hits.includes(p)) continue;
        for (const sp of p.segPos) {
          if (Math.hypot(sp.x - d.x, sp.y - d.y) < CENTIPEDE_SEG_RADIUS + 5) {
            this.onDartHit(d, p, sp.x, sp.y);
            break;
          }
        }
        if (!p.active) break;
      }
    }
  }

  /** Lets go of a predator's body parts and its pit. */
  private dropBody(p: Predator): void {
    for (const img of p.segs) img.destroy();
    p.segs = [];
    p.segPos = [];
    p.trail = [];
    p.pit = -1;
  }

  /** The Anteater at the nest: a gulp of nectar every second until it falls (sim/roster.ts anteaterGulp). */
  private gulp(p: Predator, now: number): void {
    if (!this.bossWarned) {
      this.bossWarned = true;
      this.pushBanner('THE ANTEATER IS EATING', 'Kill it before your nectar is gone', '#ffb38a');
    }
    if (now < p.gulpAt) return;
    p.gulpAt = now + ANTEATER_GULP_SECONDS * 1000;
    const eaten = anteaterGulp(this.nectar);
    if (eaten <= 0) return;
    this.nectar -= eaten;
    this.floatText(this.nest.x, this.nest.y - 40, `-${eaten}`, '#ffb000', 32);
    blip('denied');
  }

  private fireShot(p: Predator, now: number): void {
    const spec = PREDATORS[p.kind];
    const web = spec.behaviour === 'webSpit';
    const s = this.shots.get(p.x, p.y, web ? 'web' : 'sting') as Shot | null;
    if (!s) return;
    s.enableBody(true, p.x, p.y, true, true);
    s.setTexture(web ? 'web' : 'sting').setDepth(6);
    const r = web ? 8 : 4;
    body(s).setCircle(r, s.width / 2 - r, s.height / 2 - r);
    const aim = Phaser.Math.Angle.Between(p.x, p.y, this.ant.x, this.ant.y);
    // The Brood Hornet fires a fan of three stings (sim/roster.ts hornetFan); the rest one shot at the ant.
    const angles = p.kind === 'hornet' ? hornetFan(aim) : [aim];
    const speed = web ? T.WEB_SPEED : T.STING_SPEED;
    let shot: Shot | null = s;
    for (let i = 0; i < angles.length; i++) {
      if (i > 0) {
        shot = this.shots.get(p.x, p.y, 'sting') as Shot | null;
        if (!shot) return;
        shot.enableBody(true, p.x, p.y, true, true);
        shot.setTexture('sting').setDepth(6);
        body(shot).setCircle(r, shot.width / 2 - r, shot.height / 2 - r);
      }
      if (!shot) return;
      const ang = angles[i];
      shot.setVelocity(Math.cos(ang) * speed, Math.sin(ang) * speed);
      shot.setRotation(ang);
      shot.damage = spec.shotDamage;
      shot.web = web;
      shot.dieAt = now + T.SHOT_LIFE_MS;
    }
  }

  private expire(group: Phaser.Physics.Arcade.Group, now: number): void {
    for (const o of group.getChildren() as Array<Dart | Shot>) {
      if (o.active && now >= o.dieAt) o.disableBody(true, true);
    }
  }

  private spawnPredator(plan: RoundPlan, forced?: PredatorKind, at?: { x: number; y: number }): boolean {
    // Lane G7, M3: every queued spawn takes the same six rolls in one order (sim/daily.ts spawnRolls) from the round's
    // stream, so on a Daily run everyone meets the same predators in the same order. A wasp a hornet calls (at) is not
    // in the queue and rolls apart, so it never shifts the queue's rolls.
    const roll = at ? spawnRolls(Math.random) : (this.heldRoll ?? spawnRolls(this.spawnNext));
    if (!at) this.heldRoll = null;
    let kind = forced ?? pickPredator(plan.round, roll.kind);
    // An antlion needs a free pit and the centipedes are held to two; past that a spawn comes as an army ant.
    const taken = new Set<number>();
    let ofKind = 0;
    for (const q of this.predators.getChildren() as Predator[]) {
      if (!q.active) continue;
      if (q.kind === 'antlion' && q.pit >= 0) taken.add(q.pit);
      if (q.kind === kind) ofKind += 1;
    }
    const freePits = ANTLION_PITS.map((_, i) => i).filter((i) => !taken.has(i));
    kind = spawnKind(kind, ofKind, freePits.length);
    // The Anteater climbs out of the hole farthest from the ant, so its long walk to the nest can be seen and stopped.
    // An antlion digs in at a free pit.
    const pitIndex = kind === 'antlion' ? freePits[Math.floor(roll.pit * freePits.length)] : -1;
    const hole = at
      ? new Phaser.Math.Vector2(at.x, at.y)
      : kind === 'anteater'
        ? this.farthestHole()
        : pitIndex >= 0
          ? new Phaser.Math.Vector2(ANTLION_PITS[pitIndex].x, ANTLION_PITS[pitIndex].y)
          : this.pickHole(roll.hole);
    const p = this.predators.get(hole.x, hole.y, `${kind}0`) as Predator | null;
    if (!p) {
      // No free body in the pool this frame: the same rolls wait for the next try, so the queue's order never shifts.
      if (!at) this.heldRoll = roll;
      return false;
    }
    if (!at && this.spawnLog.length < 400) {
      const hi = this.holes.findIndex((h) => h.x === hole.x && h.y === hole.y);
      this.spawnLog.push({ round: plan.round, kind, hole: pitIndex >= 0 ? -1 - pitIndex : hi });
    }
    const now = this.yardNow;
    const spec = PREDATORS[kind];
    p.enableBody(true, hole.x, hole.y, true, true);
    p.setTexture(`${kind}0`);
    body(p).setCircle(spec.radius, p.width / 2 - spec.radius, p.height / 2 - spec.radius);
    p.setCollideWorldBounds(true);
    p.kind = kind;
    p.maxHp = predatorHealth(kind, plan.health);
    // Lane G9, M4: a later termite rush takes more of the ant's shots to clear (curve.ts breatherByAppearance, at most 3).
    if (kind === 'termite' && plan.kind === 'breather' && plan.termiteHits > 1) p.maxHp = 1 + (plan.termiteHits - 1) * this.build.damage;
    p.hp = p.maxHp;
    p.speed = predatorSpeedShare(kind, plan.round, roll.speed) * BASE_ANT.speed;
    p.spawnUntil = now + T.SPAWN_FADE_MS;
    p.biteReadyAt = p.spawnUntil;
    p.shotReadyAt = now + 1200 + roll.shot * 1200;
    p.windupAt = 0;
    p.flashUntil = 0;
    p.slowUntil = 0;
    p.struck = false;
    p.gulpAt = 0;
    p.eating = false;
    p.stalledFor = 0;
    p.sidestepLeft = 0;
    p.lastX = hole.x;
    p.lastY = hole.y;
    p.strafe = roll.strafe < 0.5 ? -1 : 1;
    p.flying = kind === 'wasp' || kind === 'moth' || kind === 'hornet';
    p.fuseAt = 0;
    p.jinkAt = 0;
    p.broodAt = now + 3000;
    p.burnUntil = 0;
    p.burnNext = 0;
    p.burnTick = 0;
    p.blindUntil = 0;
    p.broodCalls = 0;
    p.hitGroup = null;
    p.hitText = null;
    p.stepAt = 0;
    p.setDepth(p.flying ? 6 : kind === 'antlion' ? 3.8 : 4);
    p.heading = Phaser.Math.Angle.Between(hole.x, hole.y, this.ant.x, this.ant.y);
    p.setRotation(p.heading);
    this.dropBody(p);
    p.pit = pitIndex;
    if (kind === 'centipede') {
      p.trail = [hole.x, hole.y];
      for (let i = 0; i < CENTIPEDE_SEGMENTS; i++) p.segs.push(this.add.image(hole.x, hole.y, 'centSeg0').setDepth(3.9).setAlpha(0));
      p.segPos = p.segs.map(() => ({ x: hole.x, y: hole.y }));
    }
    p.clearTint();
    p.setAlpha(0);
    this.tweens.add({ targets: p, alpha: 1, duration: T.SPAWN_FADE_MS });
    return true;
  }

  private farthestHole(): Phaser.Math.Vector2 {
    let best = this.holes[0];
    let bestD = -1;
    for (const h of this.holes) {
      const d = Phaser.Math.Distance.Between(h.x, h.y, this.ant.x, this.ant.y);
      if (d > bestD) {
        bestD = d;
        best = h;
      }
    }
    return best;
  }

  /**
   * A hole neither on top of the ant nor across the Yard: predators climb out where the player can see them come. The
   * spawn's hole roll picks among them (on a Daily run the same roll for everyone; the holes in reach follow the ant).
   */
  private pickHole(roll: number): Phaser.Math.Vector2 {
    const ring = this.holes.filter((h) => {
      const d = Phaser.Math.Distance.Between(h.x, h.y, this.ant.x, this.ant.y);
      return d > T.SPAWN_MIN_DIST && d < T.SPAWN_MAX_DIST;
    });
    if (ring.length > 0) return ring[Math.min(ring.length - 1, Math.floor(roll * ring.length))];
    const byDistance = [...this.holes].sort(
      (a, b) =>
        Phaser.Math.Distance.Between(b.x, b.y, this.ant.x, this.ant.y) -
        Phaser.Math.Distance.Between(a.x, a.y, this.ant.x, this.ant.y),
    );
    const n = Math.min(3, byDistance.length);
    return byDistance[Math.min(n - 1, Math.floor(roll * n))];
  }

  private spawnPickup(kind: PickupKind, x: number, y: number, value: number): void {
    const img = this.add.image(x, y, kind).setDepth(3).setScale(0.2);
    this.tweens.add({ targets: img, scale: kind === 'bead' ? 1 : 1.3, duration: 220, ease: 'Back.easeOut' });
    this.pickups.push({ img, kind, value });
    if (this.pickups.length > 140) {
      const oldest = this.pickups.findIndex((k) => k.kind === 'bead');
      if (oldest >= 0) {
        const [k] = this.pickups.splice(oldest, 1);
        this.collect(k);
        k.img.destroy();
      }
    }
  }

  private updatePickups(dt: number): void {
    for (let i = this.pickups.length - 1; i >= 0; i--) {
      const k = this.pickups[i];
      const dx = this.ant.x - k.img.x;
      const dy = this.ant.y - k.img.y;
      const d = Math.hypot(dx, dy);
      if (d < T.PICKUP_RADIUS) {
        this.pickups.splice(i, 1);
        this.collect(k);
        k.img.destroy();
        continue;
      }
      if (this.vacuum || d < T.MAGNET_RADIUS) {
        const step = Math.min(d, T.BEAD_SPEED * (this.vacuum ? 1.7 : 1) * dt);
        k.img.x += (dx / d) * step;
        k.img.y += (dy / d) * step;
      }
    }
  }

  private collect(k: Pickup): void {
    if (k.kind === 'bead') {
      this.earn(k.value);
      this.floatText(this.ant.x + 26, this.ant.y - 44, `+${Math.floor(k.value)}`, '#ffd34d', 24);
      blip('pickup');
    } else if (k.kind === 'jelly') {
      // The breather's reward (CONCEPT_V2 section 5): full health and a free pick. Slice 4: past the pick cap (level 12)
      // no pick comes at all, the nest shop is the only growth, so the jelly heals only.
      this.hp = this.build.maxHp;
      if (picksOpen(this.level)) {
        this.pushBanner('ROYAL JELLY', 'Full health and a free pick', '#ffc6e6');
        this.queuePicks(1, 'ROYAL JELLY: A FREE PICK');
      } else this.pushBanner('ROYAL JELLY', 'Full health. Grow in the nest shop now', '#ffc6e6');
    } else {
      const kind: BlessingKind = Math.random() < 0.5 ? 'instakill' : 'double';
      this.blessing = kind;
      this.blessingUntil = this.yardNow + BLESSING_SECONDS * 1000;
      this.pushBanner("QUEEN'S BLESSING", kind === 'instakill' ? 'One hit kills for 30 s' : 'Double nectar for 30 s', '#ffe14d');
      blip('buy');
    }
  }

  private updateDirector(now: number, dt: number): void {
    if (this.blessing !== null && now >= this.blessingUntil) this.blessing = null;
    switch (this.phase) {
      case 'intro':
        this.introLeft -= dt;
        if (this.introLeft <= 0) this.beginRound(this.round + 1);
        break;
      case 'active': {
        const plan = this.plan;
        if (!plan) break;
        this.spawnTimer -= dt;
        if (this.queued > 0 && this.spawnTimer <= 0 && this.predators.countActive(true) < plan.aliveCap) {
          const forced: PredatorKind | undefined = this.bossPending && plan.boss ? plan.boss : undefined;
          if (this.spawnPredator(plan, forced)) {
            if (forced) this.bossPending = false;
            this.queued--;
            this.spawnTimer = plan.spawnGap;
          }
        }
        if (this.queued === 0 && this.predators.countActive(true) === 0) this.endRound();
        break;
      }
      case 'break': {
        // The countdown runs the full break whatever the ant does (the shop does not pause it; an open pick sheet holds
        // the whole Yard, this with it); at zero the round starts.
        const step = breakStep(this.breakLeft, dt);
        this.breakLeft = step.left;
        if (step.start) this.beginRound(this.round + 1);
        break;
      }
      case 'dead':
        break;
    }
  }

  private beginRound(r: number): void {
    this.round = r;
    this.plan = roundPlan(r);
    // Lane G7, M3: a Daily run's round has its own spawn stream from the day's seed (any other run rolls Math.random).
    this.spawnNext = this.daily ? makeRng(streamSeed(this.dailySeedNow, 'spawn', r)) : Math.random;
    this.heldRoll = null;
    this.queued = this.plan.total;
    this.spawnTimer = 0.8;
    this.phase = 'active';
    this.vacuum = false;
    this.leftNestThisRound = false;
    let sub = '';
    this.bossPending = this.plan.kind === 'boss';
    this.bossWarned = false;
    if (this.plan.boss === 'anteater') sub = 'The Anteater is after your nectar';
    else if (this.plan.boss === 'mantis') sub = 'The Scythe Mantis: step out of the red arc';
    else if (this.plan.boss === 'hornet') sub = 'The Brood Hornet: it keeps calling wasps';
    else if (this.plan.kind === 'breather') sub = `Termite rush: ${this.plan.total} of them`;
    else if (r === PREDATORS.wasp.fromRound) sub = 'Wasps join the hunt';
    else if (r === firstHordeRound('ember')) sub = 'Ember ants burst up close: shoot them early';
    else if (r === firstHordeRound('moth')) sub = 'Dusk moths jink: they are hard to hit';
    else if (r === PREDATORS.spider.fromRound) sub = 'Spiders: their webs slow you';
    else if (r === firstHordeRound('beetle')) sub = 'Beetles: the shell takes half, hit them from behind';
    else if (r === firstHordeRound('antlion')) sub = 'Antlions dig in: keep out of the pits';
    else if (r === firstHordeRound('centipede')) sub = 'Centipedes: fast and long, slow to turn';
    else if (r === 1) sub = 'Stand still to shoot faster';
    this.pushBanner(`ROUND ${r}`, sub, this.plan.kind === 'boss' ? '#ffb38a' : this.plan.kind === 'breather' ? '#ffe7a8' : '#ffffff');
    blip('round');
  }

  private endRound(): void {
    this.phase = 'break';
    this.breakLeft = this.plan ? this.plan.breakSeconds : BREAK_SECONDS;
    this.vacuum = true;
    for (const s of this.shots.getChildren() as Shot[]) if (s.active) s.disableBody(true, true);
    this.pushBanner(`ROUND ${this.round} CLEARED`, 'Walk to the nest to shop', '#b8ff9e');
    this.writeSave(true);
  }

  /** The run as the save keeps it: the round just cleared, the growth, the perks, nectar and health. */
  private runRecord(): RunSave {
    return {
      v: 1,
      round: this.round,
      level: this.level,
      xp: this.xp,
      stacks: { ...this.stacks },
      owned: [...this.owned],
      nectar: this.nectar,
      hp: this.hp,
      kills: this.kills,
      pending: this.pending,
      offer: [...this.offer],
      pickTitle: this.pickTitle,
      ladder: this.ladder,
      lines: { ...this.lines },
      ledger: { ...this.ledger },
      daily: this.daily,
      offers: this.offersDrawn,
    };
  }

  /** Writes the save in a break (never in a practice run); unchanged text is not written again unless forced. */
  private writeSave(force: boolean): void {
    if (this.practice || this.phase !== 'break' || this.hp <= 0) return;
    const record = this.runRecord();
    const json = encodeRun(record);
    if (!force && json === this.lastSaveJson) return;
    if (saveRun(browserRunStore(), record)) this.lastSaveJson = json;
  }

  /** The title's Continue: the saved run comes back in the break after its round, with the full countdown. */
  continueRun(): boolean {
    const saved = this.savedRun;
    if (this.phase !== 'title' || !saved) return false;
    this.savedRun = null;
    this.round = saved.round;
    this.level = saved.level;
    this.xp = saved.xp;
    this.stacks = { ...saved.stacks };
    this.owned = [...saved.owned];
    this.lines = { ...saved.lines };
    // A save from before slice 4 never counted the ledger: it starts counting at Continue.
    this.ledger = saved.ledger ? { ...saved.ledger } : emptyLedger();
    // The saved run keeps its own ladder; a Colony run comes back with the colony's upgrades as they are now.
    this.ladder = saved.ladder;
    // Lane G7, M3: a saved Daily run comes back on its own day's seed, its offers counted on from where they stopped.
    if (saved.daily) this.beginDaily(saved.daily);
    this.offersDrawn = saved.offers;
    this.applyMeta();
    this.perkStats = runStats(this.metaBase(saved.ladder), this.owned, this.lines);
    this.build = deriveBuild(this.perkStats, this.stacks);
    this.hp = Math.min(saved.hp, this.build.maxHp);
    this.nectar = saved.nectar;
    this.kills = saved.kills;
    this.pending = saved.pending;
    this.offer = [...saved.offer];
    this.pickTitle = saved.pickTitle;
    this.plan = roundPlan(saved.round);
    this.phase = 'break';
    this.breakLeft = BREAK_SECONDS;
    this.vacuum = true;
    this.leftNestThisRound = false;
    this.lastSaveJson = '';
    this.pushBanner(`ROUND ${saved.round} CLEARED`, 'Welcome back: walk to the nest to shop', '#b8ff9e');
    blip('round');
    return true;
  }

  /** The title's Play: a fresh run on the chosen ladder begins, and a saved run (if any) is ended. */
  startOver(): boolean {
    if (this.phase !== 'title') return false;
    clearRun(browserRunStore());
    this.savedRun = null;
    this.applyMeta();
    this.phase = 'intro';
    this.introLeft = T.INTRO_SECONDS;
    this.pushBanner('GET READY', `${this.ladder === 'colony' ? 'Colony' : 'Pure'} ladder: the predators are coming`, '#ffffff');
    return true;
  }

  /**
   * Lane G7, M3: the title's Daily challenge: a fresh Pure run on today's seed (the same spawns and offers for everyone
   * today), with its own best round for the day; a saved run (if any) is ended, as Play ends it.
   */
  startDaily(): boolean {
    if (this.phase !== 'title') return false;
    this.refreshToday();
    clearRun(browserRunStore());
    this.savedRun = null;
    this.stacks = emptyStacks();
    this.beginDaily(this.today);
    this.phase = 'intro';
    this.introLeft = T.INTRO_SECONDS;
    this.pushBanner('DAILY CHALLENGE', `${dayLabel(this.today)}: the same run for everyone today`, '#ffe07a');
    return true;
  }

  /** The title's Daily button: today's day, as shown, and its best round (null before the first Daily run today). */
  dailyView(): { day: string; label: string; best: number | null } {
    this.refreshToday();
    return { day: this.today, label: dayLabel(this.today), best: this.dailyBest };
  }

  /**
   * The phone's day as of now. An installed app comes back from the background without a page load, so a title left
   * open overnight must meet the new day: its date, its best round, and the new day's run on the DAILY tap.
   */
  private refreshToday(): void {
    const day = readToday();
    if (day === this.today) return;
    this.today = day;
    this.dailyBest = readDailyBest(browserStore(), day);
  }

  /** The title's ladder switch: Colony (the upgrades on) or Pure (everyone weak, its own best round). */
  setLadder(ladder: Ladder): boolean {
    if (this.phase !== 'title') return false;
    this.ladder = ladder;
    saveLadder(browserStore(), ladder);
    this.applyMeta();
    return true;
  }

  /** The best round of each ladder, read when the run was set up (the title shows both). */
  bestRounds(): Readonly<Record<Ladder, number | null>> {
    return this.bests;
  }

  /** The colony as the nest screen shows it. */
  colonyView(): { bank: number; levels: Readonly<Record<UpgradeId, number>>; ladder: Ladder } {
    return { bank: this.colony.bank, levels: this.colony.levels, ladder: this.ladder };
  }

  /** The nest screen's cards: one step of an upgrade, only between runs (the title or the death screen). */
  buyColony(id: UpgradeId): boolean {
    if ((this.phase !== 'title' && this.phase !== 'dead') || !canBuyUpgrade(this.colony, id)) {
      blip('denied');
      return false;
    }
    this.colony = buyUpgrade(this.colony, id);
    saveColony(browserStore(), this.colony);
    if (this.phase === 'title') this.applyMeta();
    blip('buy');
    return true;
  }

  /**
   * Play again (the death screen or the nest after it): both scenes restart and the run starts at once. Lane G7, M3:
   * the death screen's Play again after a Daily run plays that day again (sameRun); the nest's PLAY starts a run on
   * the ladder, where the nest's upgrades count.
   */
  playAgain(sameRun = true): boolean {
    if (this.phase !== 'dead') return false;
    this.registry.set('autostart', true);
    this.registry.set('autostartDaily', sameRun && this.daily ? this.daily : null);
    this.scene.restart();
    return true;
  }

  /** Live predators by kind, for the smoke test and the console. */
  kindCounts(): Record<PredatorKind, number> {
    const counts = {} as Record<PredatorKind, number>;
    for (const k of KINDS) counts[k] = 0;
    if (!this.predators) return counts;
    for (const p of this.predators.getChildren() as Predator[]) if (p.active) counts[p.kind] += 1;
    return counts;
  }

  inNest(): boolean {
    return Phaser.Math.Distance.Between(this.ant.x, this.ant.y, this.nest.x, this.nest.y) < T.NEST_SHOP_RADIUS;
  }

  /**
   * Called by the HUD's shop cards. Buys only in the break between rounds, standing in the nest; locked while a round is
   * on. Lane G9c: refused while a pick sheet is up (sim/pause.ts shopSells), so a held break buys no shop time.
   */
  tryBuy(id: PerkId): boolean {
    if (!this.shopSellsNow() || !canBuy(this.nectar, this.owned, id)) {
      blip('denied');
      return false;
    }
    const bought = buyPerk(this.nectar, this.owned, id);
    const oldMax = this.build.maxHp;
    this.ledger.spent += this.nectar - bought.nectar;
    this.nectar = bought.nectar;
    this.owned = bought.owned;
    this.perkStats = runStats(this.metaBase(this.ladder), this.owned, this.lines);
    this.build = deriveBuild(this.perkStats, this.stacks);
    if (this.build.maxHp !== oldMax) this.hp = Math.round((this.hp * this.build.maxHp) / oldMax);
    this.floatText(this.ant.x, this.ant.y - 50, perkSpec(id).name.toUpperCase(), '#9effa1', 28);
    blip('buy');
    return true;
  }

  /**
   * Slice 4: the HUD's line cards. One more step of a repeatable line, in the break and in the nest like the perks; its
   * price is the next step of the shared ladder (sim/economy.ts). Added health comes with the health to fill it.
   */
  tryBuyLine(id: LineId): boolean {
    if (!this.shopSellsNow() || !canBuyLine(this.nectar, this.lines, id, this.round)) {
      blip('denied');
      return false;
    }
    const step = lineStep(id, this.lines[id] + 1) as number;
    const bought = buyLine(this.nectar, this.lines, id, this.round);
    const oldMax = this.build.maxHp;
    this.ledger.spent += bought.price;
    this.nectar = bought.nectar;
    this.lines = bought.levels;
    this.perkStats = runStats(this.metaBase(this.ladder), this.owned, this.lines);
    this.build = deriveBuild(this.perkStats, this.stacks);
    if (this.build.maxHp > oldMax) this.hp = Math.min(this.build.maxHp, this.hp + (this.build.maxHp - oldMax));
    this.floatText(this.ant.x, this.ant.y - 50, `${lineSpec(id).name.toUpperCase()} ${stepText(id, step).toUpperCase()}`, '#9effa1', 26);
    blip('buy');
    return true;
  }

  /** Lane G9c: the one gate both buy paths share: the shop open (economy.ts shopState) and no pick sheet up. */
  private shopSellsNow(): boolean {
    const shop = shopState(this.phase, this.inNest(), this.leftNestThisRound);
    return shopSells(shop, sheetOpen(this.pending, this.offer.length, this.phase));
  }

  private pushBanner(title: string, sub: string, color: string): void {
    this.banners.push({ title, sub, color });
  }

  /** A number that floats up and fades; a big one pops in at 1.4 times its size and settles. */
  private floatText(x: number, y: number, text: string, color: string, size: number, pop = false): Phaser.GameObjects.Text {
    const t = this.floats[this.floatNext];
    this.floatNext = (this.floatNext + 1) % this.floats.length;
    this.tweens.killTweensOf(t);
    // A pooled number taken for a new one belongs to nobody until its caller says so.
    t.setData('owner', null);
    t.setText(text).setColor(color).setFontSize(size).setPosition(x, y).setAlpha(1).setScale(pop ? 1.4 : 1).setVisible(true);
    this.tweens.add({
      targets: t,
      y: y - 46,
      alpha: 0,
      duration: 650,
      ease: 'Cubic.easeOut',
      onComplete: () => t.setVisible(false),
    });
    if (pop) this.tweens.add({ targets: t, scale: 1, duration: 160, ease: 'Back.easeOut' });
    return t;
  }

  /** A grouped number takes the new total: it goes back over its target, fully shown, and starts its rise and fade again. */
  private refloat(t: Phaser.GameObjects.Text, x: number, y: number, text: string, color: string, pop: boolean): void {
    this.tweens.killTweensOf(t);
    t.setText(text).setColor(color).setPosition(x, y).setAlpha(1).setScale(pop ? 1.25 : 1).setVisible(true);
    this.tweens.add({ targets: t, y: y - 46, alpha: 0, duration: 650, ease: 'Cubic.easeOut', onComplete: () => t.setVisible(false) });
    if (pop) this.tweens.add({ targets: t, scale: 1, duration: 160, ease: 'Back.easeOut' });
  }

  /** The kill pop: a ring the predator's colour bursts out from the kill and fades in under a quarter second. */
  private popRing(x: number, y: number, tint: number, radius: number): void {
    const ring = this.rings[this.ringNext];
    if (!ring) return;
    this.ringNext = (this.ringNext + 1) % this.rings.length;
    this.tweens.killTweensOf(ring);
    const s = Math.max(0.5, radius / 20);
    ring.setPosition(x, y).setTint(tint).setScale(0.35 * s).setAlpha(0.95).setVisible(true);
    this.tweens.add({ targets: ring, scale: 1.5 * s, alpha: 0, duration: 230, ease: 'Cubic.easeOut', onComplete: () => ring.setVisible(false) });
  }


  private drawAnt(now: number): void {
    const g = this.antBar;
    g.clear();
    if (this.phase === 'dead') {
      this.drawLook(now);
      return;
    }
    const w = 48;
    const h = 7;
    const x = this.ant.x - w / 2;
    const y = this.ant.y - 40;
    const f = Phaser.Math.Clamp(this.hp / this.build.maxHp, 0, 1);
    g.fillStyle(0x000000, 0.55);
    g.fillRoundedRect(x - 2, y - 2, w + 4, h + 4, 4);
    g.fillStyle(f > 0.5 ? 0x6fe36b : f > 0.25 ? 0xffc23d : 0xff4d4d, 1);
    g.fillRoundedRect(x, y, Math.max(2, w * f), h, 3);
    this.ant.setAlpha(now < this.graceUntil ? (Math.floor(now / 70) % 2 === 0 ? 0.35 : 1) : 1);
    if (now < this.webUntil) this.ant.setTint(0xb9cfff);
    else this.ant.clearTint();
    this.drawLook(now);
  }

  private drawNestRing(time: number): void {
    const g = this.nestRing;
    g.clear();
    if (this.phase !== 'break') return;
    const pulse = 0.5 + 0.5 * Math.sin(time / 220);
    g.lineStyle(6, this.inNest() ? 0x9effa1 : 0xffe07a, 0.45 + 0.4 * pulse);
    g.strokeCircle(this.nest.x, this.nest.y, T.NEST_SHOP_RADIUS);
  }

  private refreshSnap(): void {
    const alive = this.predators ? this.predators.countActive(true) : 0;
    let boss: Snapshot['boss'] = null;
    const hunters: Snapshot['hunters'] = [];
    if (this.predators) {
      for (const p of this.predators.getChildren() as Predator[]) {
        if (p.active && isBossKind(p.kind)) {
          boss = { kind: p.kind, name: PREDATORS[p.kind].name, hp: Math.max(0, p.hp), maxHp: p.maxHp, x: Math.round(p.x), y: Math.round(p.y), eating: p.eating };
        }
        if (p.active && (p.kind === 'beetle' || p.kind === 'antlion' || p.kind === 'centipede' || p.kind === 'ember' || p.kind === 'moth' || p.kind === 'mantis' || p.kind === 'hornet')) {
          hunters.push({ kind: p.kind, x: Math.round(p.x), y: Math.round(p.y), heading: p.heading, hp: p.hp, maxHp: p.maxHp, pit: p.pit });
        }
      }
    }
    const inNest = this.ant ? this.inNest() : false;
    this.snap = {
      phase: this.phase,
      round: this.round,
      alive,
      left: this.phase === 'active' ? this.queued + alive : 0,
      hp: this.hp,
      maxHp: this.build.maxHp,
      nectar: this.nectar,
      kills: this.kills,
      breakLeft: Math.max(0, this.breakLeft),
      inNest,
      shop: shopState(this.phase, inNest, this.leftNestThisRound),
      owned: this.owned,
      blessing: this.blessing,
      blessingLeft: this.blessing ? Math.max(0, (this.blessingUntil - this.yardNow) / 1000) : 0,
      record: this.record,
      practice: this.practice,
      moving: this.moving,
      antX: this.ant ? Math.round(this.ant.x) : 0,
      antY: this.ant ? Math.round(this.ant.y) : 0,
      level: this.level,
      xp: this.xp,
      xpNeed: xpToNext(this.level),
      pending: this.pending,
      offer: this.offer,
      pickTitle: this.pickTitle,
      stacks: this.stacks,
      frozen: this.held,
      yardMs: Math.round(this.yardNow),
      boss,
      hurts: this.hurtLog,
      elements: {
        fire: this.build.fire,
        frost: this.build.frost,
        spark: this.build.spark,
        combos: combosOf(this.stacks),
        puddles: this.puddles.filter((f) => f.img.visible).map((f) => ({ x: Math.round(f.x), y: Math.round(f.y), left: Math.max(0, (f.until - this.yardNow) / 1000) })),
        steams: this.steams.filter((f) => f.img.visible).length,
        burning: this.live.filter((q) => q.active && q.burnUntil > this.yardNow).length,
        blind: this.live.filter((q) => q.active && q.blindUntil > this.yardNow).length,
        sparks: this.sparkCount,
        comboHits: this.comboHits,
        procs: this.procs,
      },
      look: antLook(this.level, this.build.maxHp, this.stacks),
      rockContact: this.ant ? rockContact(this.ant.x, this.ant.y, T.ANT_RADIUS) : false,
      saved: this.savedRun
        ? { round: this.savedRun.round, level: this.savedRun.level, ladder: this.savedRun.ladder, daily: this.savedRun.daily }
        : null,
      daily: this.daily,
      today: this.today,
      dailyBest: this.dailyBest,
      spawns: this.spawnLog,
      offers: this.offerLog,
      ladder: this.ladder,
      bank: this.colony.bank,
      colonyLevels: this.colony.levels,
      banked: this.banked,
      hunters,
      lastHits: this.hitLog,

      lines: this.lines,
      earned: this.ledger.earned,
      spent: this.ledger.spent,
      damage: this.build.damage,
      baseDamage: this.perkStats.damage,
      baseMaxHp: this.perkStats.maxHp,
      speed: this.build.speed,
      fireInterval: this.build.fireInterval,
      armor: this.armor,
    };

  }
}
