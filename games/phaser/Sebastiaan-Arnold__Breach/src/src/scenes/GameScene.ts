import Phaser from 'phaser';
import { COLORS, MOVE, NOISE, REACH, RENDER_SCALE, TILE, VISION } from '../config';
import { moveCircle } from '../core/collision';
import { circleIntersectsRect, DEG, pointInPolygon, rayCircle } from '../core/geometry';
import { blocksSight, isOutdoor, parseLevel, type FloorMaterial, type ParsedLevel } from '../core/grid';
import { visibilityPolygon, type RayHit } from '../core/visibility';
import { levelById } from '../levels';
import { KILLHOUSE_ROLL, stationAt, type StationDef } from '../levels/academy/range';
import { campaignOf, DIFFICULTY, RANKS } from '../levels/campaigns';
import { isTall, propTiles } from '../levels/props';
import type { EntryDef, LevelDef } from '../levels/types';
import { sfx } from '../game/audio';
import type { Surface } from '../game/Sfx';
import { Civilian, SECURE_TIME } from '../game/Civilian';
import type { Door } from '../game/Door';
import { Effects } from '../game/Effects';
import { Enemy, type EnemyContext } from '../game/Enemy';
import { Fog } from '../game/Fog';
import { Glass } from '../game/Glass';
import { Intro, INTRO_PACE } from '../game/Intro';
import { drawLevelArt } from '../game/LevelArt';
import { NoiseSystem, type NoiseEvent } from '../game/Noise';
import { Player } from '../game/Player';
import { RangeStations } from '../game/RangeStations';
import { endCareer, endedCareer, hasBreachCharge, progress, recordSuccess, saveProgress, unlockedWeapons } from '../game/progress';
import { settings } from '../game/settings';
import { rollSituation, type Situation } from '../game/situation';
import { Target, type TargetKind } from '../game/Target';
import type { WeaponId } from '../game/weapons';
import { World } from '../game/World';

const DEPTH = { world: 0, decals: 1, doors: 4, targets: 5, people: 5, player: 6, glow: 7, fog: 10, light: 12, ripples: 20, laser: 21 };
const RAIL_NOISE = 250;
const CAMERA_LOOKAHEAD = 70;
/**
 * Looking down a scope (hold Space): the operator stops, a narrow strip of vision reaches far
 * down the aim, and the camera pulls back and pushes out along it.
 */
const SCOPE = { halfFov: 4 * DEG, range: 1800, sweepStep: 0.25 * DEG, lookahead: 640, zoomOut: 0.4 };
/**
 * Overwatch: the camera pulls right out and the operator sees across the whole map. Suspects
 * making for the getaway are carrying bags, so they move at a jog.
 */
const OVERWATCH = { zoom: 0.55, range: 1700, getawaySpeed: 68, lookahead: 520 };
/** When the bolt is worked after a shot, in ms. */
const BOLT_SOUND_DELAY = 450;
/** Seconds a guard needs at a panel to set the alarm off. */
const ALARM_ARM_TIME = 3;
/** A guard running for a panel goes at a brisk walk, not a sprint: there's time to catch him. */
const ALARM_RUN_SPEED = 80;
/** Breaking glass is loud: suppressed or not, a shattered window carries through the house. */
const GLASS_NOISE = 700;
/** Enemies' handguns are unsuppressed too: the whole house hears them. */
const ENEMY_SHOT_NOISE = 1000;
/**
 * The breach charge: a short fuse, the loudest thing in the game, a stun for anyone with a line
 * to the blast, and a hit for anyone right next to it, the operator included.
 */
const CHARGE = { fuse: 2.5, noise: 1800, stunRadius: 5 * TILE, stun: 3.5, hurtRadius: 1.6 * TILE };
/** The floor a breached wall becomes, matched to the room beside it. */
const FLOOR_COLOR: Record<FloorMaterial, number> = {
  wood: COLORS.floor, deck: COLORS.deck, tile: COLORS.tile, screed: COLORS.screed, concrete: COLORS.concrete, grass: COLORS.grass, water: COLORS.water,
};
/** Pellet spread either side of a hider's aim, in degrees. */
const ENEMY_SHOTGUN_SPREAD = 7;
/**
 * Ways a mission is lost with the operator still standing. Even a realism career goes on after
 * one of these: only going down ends it.
 */
const MISSION_FAILURES = {
  time: { title: 'Out of time', lines: ['Hostage not reached in time.', 'On redeploy, go for the hostage room first.'] },
  escaped: { title: 'Suspect escaped', lines: ['A suspect reached the car.', 'On redeploy, take the ones nearest the car first.'] },
  alarm: { title: 'Alarm raised', lines: ['A guard reached an alarm panel.', 'On redeploy, stop whoever runs for a panel.'] },
} as const;
type MissionFailure = keyof typeof MISSION_FAILURES;

/** Pause between the last hostile going down (or the operator) and the debrief. */
const OUTCOME_DELAY = 1.6;

export interface GameData {
  levelId: string;
  entryId?: string;
  /** Rolled on the briefing screen; rolled here when a level has no briefing. */
  situation?: Situation;
  /** The primary gun chosen on the briefing; the pistol is always carried as a sidearm. */
  primary?: WeaponId;
  /** Suppressors fitted (once issued, chosen on the briefing). */
  suppressed?: boolean;
}

export interface Outcome {
  success: boolean;
  title: string;
  /** Completed, no civilian hit, no damage taken. Null when the operator went down. */
  stars: [boolean, boolean, boolean] | null;
  lines: string[];
  note?: string;
  /** A realism career just ended: the only way on is a new career. */
  careerOver?: boolean;
}

export interface HudState {
  /** True on the Range, where each station shows its tutorial text. */
  tutorial: boolean;
  station: StationDef | undefined;
  weapon: { name: string; mag: number; magSize: number; reserve: number; reload: number | null };
  dark: boolean;
  armor: number;
  health: number;
  /** 1 right after taking a hit, fading to 0. */
  hurt: number;
  cutscene: { bars: number; subtitle: string | null } | null;
  /** The title card over the intro: where this is, and when. */
  card: { title: string; sub: string };
  /** 0..1 while holding E on a civilian. */
  securing: number | null;
  /** A countdown at the top of the screen: the hostage clock, or a guard setting off an alarm. */
  clock: { label: string; seconds: number } | null;
  /** The breach charge, once issued: whether it's still in hand, or the fuse if it's set. */
  charge: { ready: boolean; fuse: number | null } | null;
  /** The crosshair while the operator is in control: how far the aim is wandering, in degrees. */
  aim: { spread: number; reloading: boolean } | null;
  outcome: Outcome | null;
}

/** Anything a bullet can hit besides walls. */
type Hittable = Target | Enemy | Civilian;

interface Tracer { x0: number; y0: number; x1: number; y1: number; age: number; color: number }
type Keys = Record<'W' | 'A' | 'S' | 'D' | 'UP' | 'DOWN' | 'LEFT' | 'RIGHT' | 'SHIFT' | 'E' | 'SPACE', Phaser.Input.Keyboard.Key>;
/** A breach charge on a wall: where, which wall tiles it takes out, and the floor beyond. */
interface Charge { x: number; y: number; tiles: { tx: number; ty: number }[]; material: FloorMaterial; dark: boolean; wall: number; fuse: number; beep: number; gfx: Phaser.GameObjects.Graphics }

/**
 * Plays one level: the Range (stations and cardboard targets) or a mission (enemies and
 * civilians). Starts with the intro walk and ends with a debrief or "operator down".
 */
export class GameScene extends Phaser.Scene {
  hud!: HudState;
  private params!: GameData;

  private def!: LevelDef;
  private world!: World;
  private glass!: Glass;
  private targets: Target[] = [];
  private enemies: Enemy[] = [];
  private civilians: Civilian[] = [];
  private player!: Player;
  private fog!: Fog;
  private noise!: NoiseSystem;
  private stations: RangeStations | null = null;
  private intro!: Intro;
  private laserGfx!: Phaser.GameObjects.Graphics;
  private effects!: Effects;
  private keys!: Keys;

  private visionPolys: number[][] = [];
  private tracers: Tracer[] = [];
  /** Hit markers: an X where a shot landed on someone, red when it put them down. */
  private markers: { x: number; y: number; age: number; down: boolean }[] = [];
  private muzzleFlash = 0;
  private triggerPressed = false;
  private lookX = 0;
  /** Looking down the scope right now, and how far the view has eased into it (0..1). */
  private scoped = false;
  private scopeView = 0;
  private lookY = 0;
  private lastStation: StationDef | undefined;
  private stats = { shots: 0, hits: 0 };
  private damaged = false;
  private hurt = 0;
  private securing: Civilian | null = null;
  private outcomeTimer = -1;
  private outcome: Outcome | null = null;
  private remindedCivilians = false;
  /** Raised the first time a suspect sees the operator, or on any shot or shout. */
  private alarm = false;
  private hostage: Civilian | null = null;
  private clock: number | null = null;
  /** Set when the mission is lost without the operator going down. */
  private failure: MissionFailure | null = null;
  /** The suspect sent to destroy the evidence, and how long they've been at it. */
  private destroyer: Enemy | null = null;
  private destroying = 0;
  private evidenceLost = false;
  /** The guard running for an alarm panel, and how long he's been at it. */
  private alarmRunner: Enemy | null = null;
  private arming = 0;
  /** Guns on the number keys: primary then pistol in a mission, everything unlocked on the Range. */
  private guns: WeaponId[] = ['pistol'];
  /** Breach charges in hand (one, once issued), and the one set on a wall. */
  private charges = 0;
  private charge: Charge | null = null;
  /** Set when this run earned a promotion; shown on the way back to the menu. */
  private promotion: string | null = null;
  private leaving = false;

  constructor() {
    super('game');
  }

  init(data: GameData): void {
    this.params = data;
    this.targets = [];
    this.enemies = [];
    this.civilians = [];
    this.tracers = [];
    this.markers = [];
    this.muzzleFlash = 0;
    this.triggerPressed = false;
    this.lookX = this.lookY = 0;
    this.scoped = false;
    this.scopeView = 0;
    this.lastStation = undefined;
    this.stats = { shots: 0, hits: 0 };
    this.damaged = false;
    this.hurt = 0;
    this.securing = null;
    this.outcomeTimer = -1;
    this.outcome = null;
    this.remindedCivilians = false;
    this.alarm = false;
    this.hostage = null;
    this.clock = null;
    this.failure = null;
    this.destroyer = null;
    this.destroying = 0;
    this.evidenceLost = false;
    this.alarmRunner = null;
    this.arming = 0;
    this.promotion = null;
    this.leaving = false;
    this.charges = 0;
    this.charge = null;
  }

  create(): void {
    this.def = levelById(this.params.levelId);
    const entry: EntryDef = this.def.entries.find((e) => e.id === this.params.entryId) ?? this.def.entries[0];
    const level = parseLevel(this.def.map);
    this.cameras.main.setBackgroundColor(COLORS.void);

    const rails = level.markers.filter((m) => m.kind === 'mover')
      .map((m) => ({ x0: (m.tx + 0.3) * TILE, x1: (m.tx + 7.7) * TILE, y: (m.ty + 0.5) * TILE }));
    drawLevelArt(this, level, this.def.labels, rails, this.def.props ?? [], DEPTH.world, RENDER_SCALE);
    const props = this.def.props ?? [];
    this.world = new World(this, level, DEPTH.doors, props.flatMap(propTiles), props.filter(isTall).flatMap(propTiles));
    this.glass = new Glass(this, level, DEPTH.doors);

    if (this.def.stations) this.spawnTargets(level.markers);
    const situation = this.params.situation ?? (this.def.mission ? rollSituation(this.def.mission) : null);
    if (situation) {
      const difficulty = DIFFICULTY[campaignOf(this.def.id)?.rank ?? 1];
      this.enemies = situation.hostiles.map((s) => new Enemy(this, s.type, s, DEPTH.people, difficulty));
      this.civilians = situation.civilians.map((s) => new Civilian(this, s, DEPTH.people));
      const held = this.def.mission?.hostage;
      if (held) {
        this.hostage = new Civilian(this, held, DEPTH.people, true);
        this.civilians.push(this.hostage);
      }
    }

    this.intro = new Intro(entry.approach, this.def.intro.map((l) => l.replace('{entry}', entry.name)));
    this.player = new Player(this, this.intro.start.x, this.intro.start.y, DEPTH.player);
    this.player.facing = this.intro.finalFacing;
    this.issueGuns();
    this.fog = new Fog(this, level.width * TILE, level.height * TILE, DEPTH.glow, DEPTH.fog, exteriorTiles(level));
    this.noise = new NoiseSystem(this, DEPTH.ripples);
    this.noise.onNoise((e) => this.onNoise(e));
    this.laserGfx = this.add.graphics().setDepth(DEPTH.laser);
    this.effects = new Effects(this, level.width * TILE, level.height * TILE, RENDER_SCALE, DEPTH.decals, DEPTH.light);
    this.stations = this.def.stations ? new RangeStations(this.targets) : null;

    // Unbounded on purpose: the operator stays centred even at the map edge (beyond it is just dark).
    this.cameras.main.setZoom(RENDER_SCALE * this.intro.zoom).startFollow(this.player.displayObject, false, 0.1, 0.1);
    this.cameras.main.fadeIn(500, 7, 9, 12);
    // Wind outdoors, room tone indoors, mixed by how much of the level is open to the sky.
    const open = level.tiles.filter((k, i) => k === 'floor' && isOutdoor(level.material[i])).length;
    const floor = level.tiles.filter((k) => k === 'floor').length;
    sfx.levelAmbience(floor ? open / floor : 0);
    this.events.once('shutdown', () => sfx.stopLevelAmbience());

    // A realism career is on the line from the moment it deploys.
    if (this.realism) {
      progress.deployed = this.def.id;
      saveProgress(progress);
    }

    this.setupInput();
    if (!this.scene.isActive('hud')) this.scene.launch('hud');
    this.scene.bringToTop('hud');
    this.updateHud();
  }

  update(_time: number, deltaMs: number): void {
    const dt = Math.min(deltaMs, 50) / 1000;
    const p = this.player;
    const k = this.keys;
    const inIntro = this.intro.active;
    const active = !inIntro && !this.outcome && p.alive;

    // Movement and aim: scripted during the intro, from the player afterwards.
    let mx = 0, my = 0, aimAt = p.facing;
    if (inIntro) {
      const steer = this.intro.update(dt, p.x, p.y);
      mx = steer.moveX;
      my = steer.moveY;
      aimAt = mx || my ? Math.atan2(my, mx) : this.intro.finalFacing;
    } else if (active) {
      if (k.A.isDown || k.LEFT.isDown) mx -= 1;
      if (k.D.isDown || k.RIGHT.isDown) mx += 1;
      if (k.W.isDown || k.UP.isDown) my -= 1;
      if (k.S.isDown || k.DOWN.isDown) my += 1;
      const wp = this.input.activePointer.positionToCamera(this.cameras.main) as Phaser.Math.Vector2;
      aimAt = Math.atan2(wp.y - p.y, wp.x - p.x);
    }
    this.scoped = active && !!p.weapon.def.scope && k.SPACE.isDown && !p.weapon.reloading;
    this.scopeView += ((this.scoped ? 1 : 0) - this.scopeView) * Math.min(1, dt * 6);
    // Bracing for a scoped shot: the operator stands still.
    if (this.scoped) mx = my = 0;
    const step = p.update(dt, { moveX: mx, moveY: my, sprint: active && k.SHIFT.isDown, aimAt, pace: inIntro ? INTRO_PACE : 1 }, this.world.solid);
    this.separateBodies();
    const ptx = Math.floor(p.x / TILE), pty = Math.floor(p.y / TILE);
    if (step) {
      sfx.footstep(step.loud, {}, this.surfaceAt(ptx, pty));
      this.noise.emit({ x: p.x, y: p.y, radius: step.loud ? NOISE.sprintStep : NOISE.walkStep, source: 'player', kind: 'step' }, p.x, p.y);
    }
    if (p.sprinting) this.stations?.onSprint(dt, ptx, pty);

    this.world.update(dt);
    this.updateVision(ptx, pty);

    for (const t of this.targets) {
      if (t.update(dt, this.canSee(t.x, t.y), p.x, p.y)) this.worldNoise(t.x, t.y, RAIL_NOISE);
    }
    const ctx = this.enemyContext(ptx, pty);
    for (const e of this.enemies) e.update(dt, ctx, this.canSee(e.x, e.y));
    if (this.enemies.some((e) => e.alive && e.state === 'combat')) this.raiseAlarm();
    for (const c of this.civilians) c.update(dt, this.world, this.canSee(c.x, c.y), p.x, p.y);
    this.updateSecuring(dt);

    // Shooting: semi-auto fires per click, automatics while held.
    if (active && (this.triggerPressed || (this.input.activePointer.leftButtonDown() && p.weapon.def.auto))) this.tryFire(this.triggerPressed);
    this.triggerPressed = false;

    this.updateCharge(dt);
    this.effects.update(dt, this.world.solid);
    this.drawLaserAndFx(dt, active);
    this.noise.update(dt);
    this.hurt = Math.max(0, this.hurt - dt * 1.5);

    // Camera: pulled back during the intro, then a little ahead of where the operator aims.
    const overwatch = this.def.mission?.overwatch ? OVERWATCH.zoom : 1;
    this.cameras.main.setZoom(RENDER_SCALE * this.intro.zoom * overwatch * (1 - SCOPE.zoomOut * this.scopeView));
    const ahead = this.def.mission?.overwatch ? OVERWATCH.lookahead : CAMERA_LOOKAHEAD;
    const look = inIntro ? 0 : ahead + SCOPE.lookahead * this.scopeView;
    this.lookX += (Math.cos(p.facing) * look - this.lookX) * Math.min(1, dt * 4);
    this.lookY += (Math.sin(p.facing) * look - this.lookY) * Math.min(1, dt * 4);
    this.cameras.main.setFollowOffset(-this.lookX, -this.lookY);

    if (!inIntro) this.updateProgress(dt, ptx, pty);
    this.updateHud();
  }

  /** What the floor at a tile sounds like underfoot. */
  private surfaceAt(tx: number, ty: number): Surface {
    const m = this.world.level.material[ty * this.world.width + tx];
    return m === 'wood' || m === 'deck' || m === 'tile' || m === 'grass' ? m : 'concrete';
  }

  /** People don't walk through each other: push the operator out of anyone standing. */
  private separateBodies(): void {
    const p = this.player;
    const minDist = MOVE.radius * 2 + 2;
    for (const o of [...this.enemies, ...this.civilians]) {
      if (!o.alive) continue;
      const dx = p.x - o.x, dy = p.y - o.y, d = Math.hypot(dx, dy);
      if (d >= minDist || d < 0.01) continue;
      const push = moveCircle(p.x, p.y, (dx / d) * (minDist - d), (dy / d) * (minDist - d), MOVE.radius, TILE, this.world.solid);
      p.x = push.x;
      p.y = push.y;
    }
  }

  // ---------------------------------------------------------------- level contents

  private spawnTargets(markers: ReturnType<typeof parseLevel>['markers']): void {
    const slots: { x: number; y: number }[] = [];
    for (const m of markers) {
      const x = (m.tx + 0.5) * TILE;
      const y = (m.ty + 0.5) * TILE;
      const station = stationAt(m.tx, m.ty)?.id ?? 'killhouse';
      if (m.kind === 'suspect' || m.kind === 'civilian') {
        const lane = station === 'targets';
        this.addTarget(m.kind, x, y, station, !lane, lane ? 1.6 : 0);
      } else if (m.kind === 'random') {
        slots.push({ x, y });
      } else if (m.kind === 'mover') {
        this.targets.push(new Target(this, {
          kind: 'suspect', x, y, station, popup: false, respawn: 0,
          rail: { x0: x, x1: x + 7 * TILE, speed: 36 },
        }, DEPTH.targets));
      }
    }

    // The kill house layout is fixed; who is in it is rolled on every run.
    Phaser.Utils.Array.Shuffle(slots);
    const r = KILLHOUSE_ROLL;
    const nS = Phaser.Math.Between(r.minSuspects, r.maxSuspects);
    const nC = Phaser.Math.Between(r.minCivilians, r.maxCivilians);
    slots.forEach((s, i) => {
      if (i < nS) this.addTarget('suspect', s.x, s.y, 'killhouse', true, 0);
      else if (i < nS + nC) this.addTarget('civilian', s.x, s.y, 'killhouse', true, 0);
    });
  }

  private addTarget(kind: TargetKind, x: number, y: number, station: StationDef['id'], popup: boolean, respawn: number): void {
    this.targets.push(new Target(this, { kind, x, y, station, popup, respawn }, DEPTH.targets));
  }

  private enemyContext(ptx: number, pty: number): EnemyContext {
    const p = this.player;
    return {
      world: this.world,
      // The intro is a cutscene: nobody can spot (or shoot) the operator until it's over.
      player: { x: p.x, y: p.y, alive: p.alive && !this.intro.active, inDark: this.world.isDark(ptx, pty) },
      shoot: (e, angle, pellets) => this.enemyShoot(e, angle, pellets),
      noise: (e, radius, kind) => {
        this.worldNoise(e.x, e.y, radius, kind);
        if (kind === 'shout') sfx.shout(this.soundAt(e.x, e.y, radius));
        if (kind === 'door') sfx.creak(this.soundAt(e.x, e.y, radius));
      },
    };
  }

  private onNoise(e: NoiseEvent): void {
    // Shots and shouts raise the alarm only if a suspect is in earshot: a suppressed shot in an
    // empty wing goes unheard.
    if ((e.kind === 'shot' || e.kind === 'shout' || e.kind === 'glass') && this.enemies.some((en) => en.alive && Math.hypot(en.x - e.x, en.y - e.y) <= e.radius)) {
      this.raiseAlarm();
    }
    for (const en of this.enemies) en.hear(e);
    for (const c of this.civilians) c.hear(e, this.world);
  }

  // ---------------------------------------------------------------- vision

  private updateVision(ptx: number, pty: number): void {
    const p = this.player;
    const segs = this.world.segments();
    const dark = this.world.isDark(ptx, pty);
    const range = this.def.mission?.overwatch ? OVERWATCH.range : dark ? VISION.rangeDark : VISION.rangeLit;
    const cone = visibilityPolygon(p.x, p.y, p.facing, VISION.halfFov, range, segs, VISION.sweepStep);
    const peri = visibilityPolygon(p.x, p.y, 0, Math.PI, VISION.peripheral, segs, 8 * DEG);
    this.visionPolys = [cone.polygon, peri.polygon];
    const scope = this.scoped ? visibilityPolygon(p.x, p.y, p.facing, SCOPE.halfFov, SCOPE.range, segs, SCOPE.sweepStep) : null;
    if (scope) this.visionPolys.push(scope.polygon);

    // Walls the rays struck get remembered too, otherwise rooms would have no outline.
    const seen = new Set<number>();
    const wallTiles: { tx: number; ty: number }[] = [];
    const markTile = (tx: number, ty: number) => {
      const key = ty * this.world.width + tx;
      if (seen.has(key) || !this.world.blocksSightAt(tx, ty)) return;
      seen.add(key);
      wallTiles.push({ tx, ty });
    };
    const mark = (hits: RayHit[]) => {
      for (let i = 0; i < hits.length; i++) {
        const a = hits[i];
        if (!a.blocked) continue;
        markTile(Math.floor((a.x + a.dx * 2) / TILE), Math.floor((a.y + a.dy * 2) / TILE));
        // At grazing angles neighbouring rays land far apart on the same wall face; the face
        // between them is visible too, so fill it in.
        const b = hits[i + 1];
        if (!b?.blocked) continue;
        if (Math.abs(a.y - b.y) < 0.01 && Math.abs(a.y / TILE - Math.round(a.y / TILE)) < 0.001) {
          const ty = Math.round(a.y / TILE) - (a.dy < 0 ? 1 : 0);
          for (let tx = Math.floor(Math.min(a.x, b.x) / TILE); tx <= Math.floor(Math.max(a.x, b.x) / TILE); tx++) markTile(tx, ty);
        } else if (Math.abs(a.x - b.x) < 0.01 && Math.abs(a.x / TILE - Math.round(a.x / TILE)) < 0.001) {
          const tx = Math.round(a.x / TILE) - (a.dx < 0 ? 1 : 0);
          for (let ty = Math.floor(Math.min(a.y, b.y) / TILE); ty <= Math.floor(Math.max(a.y, b.y) / TILE); ty++) markTile(tx, ty);
        }
      }
    };
    mark(cone.hits);
    mark(peri.hits);
    if (scope) mark(scope.hits);

    this.fog.update(this.visionPolys, wallTiles, {
      x: p.x,
      y: p.y,
      range: scope ? SCOPE.range : range,
      falloff: dark ? VISION.falloffDark : VISION.falloffLit,
      warmth: dark ? 0.08 : 0.035,
    });
  }

  /** True if the operator can currently see any part of something at (x, y). */
  private canSee(x: number, y: number): boolean {
    const r = 7;
    const pts = [[x, y], [x + r, y], [x - r, y], [x, y + r], [x, y - r]];
    return this.visionPolys.some((poly) => pts.some(([px, py]) => pointInPolygon(px, py, poly)));
  }

  // ---------------------------------------------------------------- combat

  private hittables(): Hittable[] {
    return [...this.targets, ...this.enemies, ...this.civilians];
  }

  private traceShot(angle: number, range: number): { x: number; y: number; dist: number; target?: Hittable } {
    const p = this.player;
    const dx = Math.cos(angle), dy = Math.sin(angle);
    let dist = this.world.castRay(p.x, p.y, dx, dy, range);
    let target: Hittable | undefined;
    for (const t of this.hittables()) {
      const d = t.hitTest(p.x, p.y, dx, dy);
      if (d < dist) {
        dist = d;
        target = t;
      }
    }
    return { x: p.x + dx * dist, y: p.y + dy * dist, dist, target };
  }

  private tryFire(pressed: boolean): void {
    const p = this.player;
    const w = p.weapon;
    if (w.reloading) return;
    if (w.mag <= 0) {
      if (!pressed) return;
      sfx.dryFire();
      if (!this.reload()) this.toast('Out of ammo');
      return;
    }
    if (!w.canFire()) return;

    w.fire();
    this.stats.shots++;
    const base = p.aimAngle;
    const muzzle = p.muzzle;
    let landed = false;
    for (let i = 0; i < w.def.pellets; i++) {
      const a = base + (w.def.pellets > 1 ? Phaser.Math.FloatBetween(-1, 1) * w.def.spread * DEG : 0);
      const dx = Math.cos(a), dy = Math.sin(a);
      const shot = this.traceShot(a, w.def.range);
      this.shatterAlong(p.x, p.y, dx, dy, shot.dist);
      if (shot.target) {
        const alive = shot.target.alive;
        const downed = this.onHit(shot.target, w.def.damage);
        if (alive) this.markers.push({ x: shot.x, y: shot.y, age: 0, down: downed });
        this.hitEffect(shot.target, shot.x, shot.y, dx, dy, alive && downed);
        landed = true;
      } else if (shot.dist < w.def.range) {
        this.effects.bulletHole(shot.x, shot.y, dx, dy);
      }
      this.tracers.push({ x0: muzzle.x, y0: muzzle.y, x1: shot.x, y1: shot.y, age: 0, color: 0xfff1b8 });
    }
    if (landed) this.stats.hits++;
    p.kick(w.def.recoil);
    // A small camera kick with every shot, bigger for heavier guns.
    if (settings.shake) this.cameras.main.shake(70, 0.0008 + w.def.recoil * 0.0022);
    this.muzzleFlash = 0.05;
    this.effects.muzzle(muzzle.x, muzzle.y, w.def.id !== 'pistol');
    this.effects.casing(p.x, p.y, p.facing, w.def.id === 'shotgun');
    sfx.shot(w.def.id !== 'pistol', {}, w.suppressed);
    if (w.def.bolt) this.time.delayedCall(BOLT_SOUND_DELAY, () => sfx.bolt());
    this.noise.emit({ x: p.x, y: p.y, radius: w.noise, source: 'player', kind: 'shot' }, p.x, p.y);
  }

  /** Spatter where the shot landed; a pool too if it just took them down. */
  /** Every pane a shot passes through shatters, loudly. */
  private shatterAlong(x: number, y: number, dx: number, dy: number, dist: number): void {
    for (let d = 0; d < dist; d += 6) {
      const tx = Math.floor((x + dx * d) / TILE), ty = Math.floor((y + dy * d) / TILE);
      if (!this.glass.shatter(tx, ty)) continue;
      const cx = (tx + 0.5) * TILE, cy = (ty + 0.5) * TILE;
      this.effects.glassBreak(cx, cy, dx, dy);
      sfx.glass(this.soundAt(cx, cy, GLASS_NOISE));
      this.worldNoise(cx, cy, GLASS_NOISE, 'glass');
    }
  }

  private hitEffect(t: Hittable, x: number, y: number, dx: number, dy: number, downed: boolean): void {
    if (t.prop) {
      this.effects.cardboardHit(x, y, dx, dy);
      return;
    }
    if (!settings.blood) return;
    this.effects.bloodHit(x, y, dx, dy);
    if (downed) this.effects.bloodPool(t.x, t.y);
  }

  /** Applies a hit of `damage`. Returns true if it took the target down. */
  private onHit(t: Hittable, damage: number): boolean {
    if (!t.alive) return false;
    const p = this.player;
    const downed = t instanceof Enemy ? t.hit(damage, p.x, p.y) : t.hit();
    if (t instanceof Target) this.stations?.onTargetHit(t);
    if (t.kind === 'civilian') {
      sfx.penalty();
      this.toast('Civilian hit. Star lost.');
    } else {
      sfx.hit();
    }
    return downed;
  }

  private enemyShoot(e: Enemy, angle: number, pellets = 1): void {
    const p = this.player;
    const seen = this.canSee(e.x, e.y);
    const mx = e.x + Math.cos(angle) * 16, my = e.y + Math.sin(angle) * 16;
    let hitPlayer = false;
    for (let i = 0; i < pellets; i++) {
      const a = angle + (pellets > 1 ? Phaser.Math.FloatBetween(-1, 1) * ENEMY_SHOTGUN_SPREAD * DEG : 0);
      const dx = Math.cos(a), dy = Math.sin(a);
      const wall = this.world.castRay(mx, my, dx, dy, 900);
      const toPlayer = p.alive ? rayCircle(mx, my, dx, dy, p.x, p.y, MOVE.radius) : Infinity;
      const dist = Math.min(wall, toPlayer);
      const hx = mx + dx * dist, hy = my + dy * dist;
      this.shatterAlong(mx, my, dx, dy, dist);
      if (toPlayer < wall) {
        if (!hitPlayer && settings.blood) this.effects.bloodHit(p.x, p.y, dx, dy);
        hitPlayer = true;
      } else {
        this.effects.bulletHole(hx, hy, dx, dy);
      }
      if (seen) this.tracers.push({ x0: mx, y0: my, x1: hx, y1: hy, age: 0, color: 0xffb4a8 });
    }
    // However many pellets land, it counts as one hit.
    if (hitPlayer) {
      this.damaged = true;
      this.hurt = 1;
      if (p.damage()) this.toast('Operator down');
      sfx.hurt();
      if (settings.shake) this.cameras.main.shake(140, 0.006);
    }
    if (seen) this.effects.muzzle(mx, my, pellets > 1);
    sfx.shot(pellets > 1, this.soundAt(e.x, e.y, 1200));
    this.worldNoise(e.x, e.y, ENEMY_SHOT_NOISE, 'shot');
  }

  private reload(): boolean {
    const w = this.player.weapon;
    if (w.reserve <= 0 && w.mag < w.def.magSize && !w.reloading) {
      this.toast('No spare magazines');
      return false;
    }
    if (!w.startReload()) return false;
    sfx.reload();
    this.noise.emit({ x: this.player.x, y: this.player.y, radius: NOISE.reload, source: 'player', kind: 'reload' }, this.player.x, this.player.y);
    return true;
  }

  private drawLaserAndFx(dt: number, showLaser: boolean): void {
    const p = this.player;
    const g = this.laserGfx;
    g.clear();

    if (showLaser) {
      const aim = this.traceShot(p.aimAngle, p.weapon.def.range);
      const muzzleLen = Math.hypot(p.muzzle.x - p.x, p.muzzle.y - p.y);
      if (aim.dist > muzzleLen) {
        const dx = Math.cos(p.aimAngle), dy = Math.sin(p.aimAngle);
        const sx = p.x + dx * muzzleLen, sy = p.y + dy * muzzleLen;
        const alpha = p.weapon.reloading ? 0.3 : 1;
        g.lineStyle(4, COLORS.laser, 0.07 * alpha);
        g.lineBetween(sx, sy, aim.x, aim.y);
        g.lineStyle(1.1, COLORS.laser, 0.8 * alpha);
        g.lineBetween(sx, sy, aim.x, aim.y);
        g.fillStyle(COLORS.laser, 0.25 * alpha);
        g.fillCircle(aim.x, aim.y, 4.5);
        g.fillStyle(0xffd0d0, alpha);
        g.fillCircle(aim.x, aim.y, 1.6);
      }
    }

    if (this.muzzleFlash > 0) {
      this.muzzleFlash -= dt;
      const m = p.muzzle;
      const fx = Math.cos(p.facing), fy = Math.sin(p.facing);
      g.fillStyle(0xffe6a8, 0.95);
      g.fillTriangle(m.x - fy * 3, m.y + fx * 3, m.x + fy * 3, m.y - fx * 3, m.x + fx * 14, m.y + fy * 14);
      g.fillStyle(0xffffff, 0.9);
      g.fillCircle(m.x + fx * 2, m.y + fy * 2, 2.5);
    }
    this.tracers = this.tracers.filter((t) => (t.age += dt) < 0.06);
    for (const t of this.tracers) {
      g.lineStyle(1.2, t.color, 0.6 * (1 - t.age / 0.06));
      g.lineBetween(t.x0, t.y0, t.x1, t.y1);
    }
    this.markers = this.markers.filter((m) => (m.age += dt) < 0.3);
    for (const m of this.markers) {
      const a = 1 - m.age / 0.3, r = (m.down ? 7 : 5) + m.age * 10, gap = 2.5;
      g.lineStyle(m.down ? 2 : 1.5, m.down ? 0xff4d4d : 0xffffff, a);
      for (const [sx, sy] of [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
        g.lineBetween(m.x + sx * gap, m.y + sy * gap, m.x + sx * r, m.y + sy * r);
      }
    }
  }

  // ---------------------------------------------------------------- doors and civilians

  private doorUnder(wx: number, wy: number): Door | undefined {
    return this.world.doorAtTile(Math.floor(wx / TILE), Math.floor(wy / TILE));
  }

  private nearestDoor(): Door | undefined {
    const p = this.player;
    let best: Door | undefined;
    let bestD = REACH;
    for (const d of this.world.doors) {
      const dist = Phaser.Math.Distance.Between(p.x, p.y, d.cx, d.cy);
      if (dist <= bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best;
  }

  private inReach(d: Door): boolean {
    return Phaser.Math.Distance.Between(this.player.x, this.player.y, d.cx, d.cy) <= REACH;
  }

  private toggleDoor(door: Door): void {
    const p = this.player;
    if (door.state === 'open' && circleIntersectsRect(p.x, p.y, MOVE.radius + 1, { x: door.tx * TILE, y: door.ty * TILE, w: TILE, h: TILE })) {
      this.toast('Step out of the doorway first');
      return;
    }
    const radius = door.toggle(p.x, p.y);
    this.noise.emit({ x: door.cx, y: door.cy, radius, source: 'player', kind: 'door' }, p.x, p.y);
    sfx.creak();
  }

  private nearestSecurable(): Civilian | undefined {
    const p = this.player;
    return this.civilians.find((c) => c.canBeSecured && Math.hypot(c.x - p.x, c.y - p.y) < 44);
  }

  /** Holding E next to a civilian gets them on the ground and out of the line of fire. */
  private updateSecuring(dt: number): void {
    const c = this.securing;
    if (!c) return;
    const p = this.player;
    if (!this.keys.E.isDown || !c.canBeSecured || Math.hypot(c.x - p.x, c.y - p.y) > 50) {
      c.secureProgress = 0;
      this.securing = null;
      return;
    }
    c.secureProgress += dt / SECURE_TIME;
    if (c.secureProgress >= 1) {
      c.secure();
      this.securing = null;
      sfx.ok();
      this.toast(c.hostage ? 'Hostage secured' : 'Civilian secured');
    }
  }

  // ---------------------------------------------------------------- input

  private setupInput(): void {
    const kb = this.input.keyboard!;
    this.keys = kb.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT,SHIFT,E,SPACE') as Keys;
    this.input.mouse?.disableContextMenu();

    this.input.on('pointerdown', (pointer: Phaser.Input.Pointer) => {
      if (this.intro.active) {
        this.skipIntro();
        return;
      }
      if (this.outcome || !this.player.alive) return;
      if (pointer.rightButtonDown()) {
        const wp = pointer.positionToCamera(this.cameras.main) as Phaser.Math.Vector2;
        const under = this.doorUnder(wp.x, wp.y);
        const door = under && this.inReach(under) ? under : this.nearestDoor();
        if (door) this.toggleDoor(door);
        else if (under) this.toast('Get closer to the door');
        return;
      }
      this.triggerPressed = true;
    });

    kb.on('keydown', (e: KeyboardEvent) => {
      if (this.intro.active) {
        if (e.code === 'Space' || e.code === 'Enter') this.skipIntro();
        return;
      }
      if (this.outcome || !this.player.alive) return;
      const digit = /^Digit([1-4])$/.exec(e.code);
      const gun = digit ? this.guns[Number(digit[1]) - 1] : undefined;
      if (gun) {
        this.switchWeapon(gun);
        return;
      }
      switch (e.code) {
        case 'KeyE': {
          const civilian = this.nearestSecurable();
          if (civilian) {
            this.securing = civilian;
            break;
          }
          const d = this.nearestDoor();
          if (d) this.toggleDoor(d);
          break;
        }
        case 'KeyR':
          this.reload();
          break;
        case 'KeyG':
          this.plantCharge();
          break;
      }
    });
  }

  // ---------------------------------------------------------------- breach charge

  /** Sets the charge on the wall the operator faces, if there's one in hand and the wall will do. */
  private plantCharge(): void {
    if (this.charge || this.charges <= 0) return;
    const spot = this.breachSpot();
    if (!spot) {
      this.toast('Face a wall with a room behind it');
      return;
    }
    this.charges--;
    const g = this.add.graphics().setDepth(DEPTH.targets);
    this.charge = { ...spot, fuse: CHARGE.fuse, beep: 0, gfx: g };
    sfx.reload();
    this.toast('Charge set. Stand back');
  }

  /**
   * The wall in front of the operator, within reach, if a charge can go on it: any wall with open
   * floor on the far side, inside or the outside of a building (a way in of your own), but not
   * the edge of the level, a door or glass. The hole
   * is two tiles wide where the wall runs on, otherwise one.
   */
  private breachSpot(): Omit<Charge, 'fuse' | 'beep' | 'gfx'> | null {
    const p = this.player, lvl = this.world.level;
    const along = Math.abs(Math.cos(p.facing)) >= Math.abs(Math.sin(p.facing));
    const dx = along ? Math.sign(Math.cos(p.facing)) : 0, dy = along ? 0 : Math.sign(Math.sin(p.facing));
    const ptx = Math.floor(p.x / TILE), pty = Math.floor(p.y / TILE);
    const tx = ptx + dx, ty = pty + dy;
    const face = along ? (dx > 0 ? tx * TILE : (tx + 1) * TILE) : (dy > 0 ? ty * TILE : (ty + 1) * TILE);
    if (Math.abs(face - (along ? p.x : p.y)) > TILE * 0.9) return null;
    const inner = (x: number, y: number) => x > 0 && y > 0 && x < lvl.width - 1 && y < lvl.height - 1;
    const wallAt = (x: number, y: number) => inner(x, y) && blocksSight(this.world.tileAt(x, y)) && !this.world.doorAtTile(x, y);
    const open = (x: number, y: number) => this.world.tileAt(x, y) === 'floor' && !this.world.doorAtTile(x, y);
    if (!wallAt(tx, ty) || !open(tx + dx, ty + dy)) return null;
    // Widen towards whichever side of the tile the operator stands nearer.
    const sx = along ? 0 : 1, sy = along ? 1 : 0;
    const off = along ? p.y / TILE - pty : p.x / TILE - ptx;
    const order = off >= 0.5 ? [1, -1] : [-1, 1];
    const tiles = [{ tx, ty }];
    for (const k of order) {
      const nx = tx + sx * k, ny = ty + sy * k;
      if (wallAt(nx, ny) && open(nx + dx, ny + dy) && open(nx - dx, ny - dy)) {
        tiles.push({ tx: nx, ty: ny });
        break;
      }
    }
    const cx = tiles.reduce((a, t) => a + t.tx + 0.5, 0) / tiles.length * TILE;
    const cy = tiles.reduce((a, t) => a + t.ty + 0.5, 0) / tiles.length * TILE;
    const behind = (ty + dy) * lvl.width + (tx + dx);
    const kind = this.world.tileAt(tx, ty);
    return {
      x: along ? face - dx * 3 : cx, y: along ? cy : face - dy * 3, tiles,
      material: lvl.material[behind], dark: lvl.dark[behind],
      wall: kind === 'plywood' ? COLORS.plywood : kind === 'interior' ? COLORS.interior : COLORS.wall,
    };
  }

  /** The fuse: a blinking light and a beep that quickens, then the blast. */
  private updateCharge(dt: number): void {
    const c = this.charge;
    if (!c) return;
    c.fuse -= dt;
    c.beep -= dt;
    if (c.beep <= 0) {
      c.beep = Math.max(0.12, c.fuse * 0.22);
      sfx.chargeBeep(this.soundAt(c.x, c.y, 500));
    }
    // The light flashes with each beep.
    const on = c.beep > Math.max(0.12, c.fuse * 0.22) - 0.08;
    c.gfx.clear();
    c.gfx.fillStyle(0x000000, 0.4).fillRect(c.x - 6, c.y - 5, 13, 11);
    c.gfx.fillStyle(0x3f3f46, 1).fillRect(c.x - 7, c.y - 6, 13, 11);
    c.gfx.fillStyle(0xd6d3d1, 0.9).fillRect(c.x - 5, c.y - 4, 9, 2);
    c.gfx.fillStyle(on ? 0xef4444 : 0x7f1d1d, 1).fillCircle(c.x + 2, c.y + 2, 1.8);
    if (c.fuse <= 0) this.detonate(c);
  }

  private detonate(c: Charge): void {
    this.charge = null;
    c.gfx.destroy();
    this.world.breach(c.tiles, c.material, c.dark);
    const floor = FLOOR_COLOR[c.material];
    this.effects.breach(c.x, c.y, c.tiles, c.dark ? COLORS.floorDark : floor, c.wall);
    sfx.blast(this.soundAt(c.x, c.y, 2000));
    if (settings.shake) this.cameras.main.shake(520, 0.012);
    this.worldNoise(c.x, c.y, CHARGE.noise, 'shot');
    for (const e of this.enemies) {
      const d = Math.hypot(e.x - c.x, e.y - c.y);
      if (!e.alive || d > CHARGE.stunRadius || !this.world.lineOfSight(c.x, c.y, e.x, e.y)) continue;
      if (d < CHARGE.hurtRadius) e.hit(1, c.x, c.y);
      e.stun(CHARGE.stun * (1 - d / CHARGE.stunRadius * 0.4));
    }
    const p = this.player;
    if (p.alive && Math.hypot(p.x - c.x, p.y - c.y) < CHARGE.hurtRadius) {
      this.damaged = true;
      this.hurt = 1;
      if (p.damage()) this.toast('Operator down');
      sfx.hurt();
    }
  }

  private skipIntro(): void {
    const end = this.intro.skip();
    this.player.x = end.x;
    this.player.y = end.y;
    this.player.facing = this.intro.finalFacing;
    this.issueGuns();
  }

  /** Hands out the guns for this run: every gun issued on the Range, else the primary and pistol. */
  private issueGuns(): void {
    this.guns = this.def.stations ? unlockedWeapons(progress) : [...new Set<WeaponId>([this.params.primary ?? 'pistol', 'pistol'])];
    this.player.suppressors = !this.def.stations && !!this.params.suppressed;
    this.player.equip(this.guns[0]);
    // Not from a rooftop: overwatch never goes in.
    this.charges = hasBreachCharge(progress) && !this.def.mission?.overwatch ? 1 : 0;
  }

  private switchWeapon(id: WeaponId): void {
    if (this.player.weapon.def.id === id) return;
    const w = this.player.equip(id);
    sfx.reload();
    this.toast(w.def.name);
  }

  // ---------------------------------------------------------------- flow

  private worldNoise(x: number, y: number, radius: number, kind: NoiseEvent['kind'] = 'other'): void {
    const p = this.player;
    this.noise.emit({ x, y, radius, source: 'world', kind }, p.x, p.y);
    if (kind === 'other' || kind === 'step') {
      const d = Phaser.Math.Distance.Between(x, y, p.x, p.y);
      if (d < radius) sfx.railTick({ pan: (x - p.x) / 400, vol: 1 - d / radius });
    }
  }

  /** Stereo pan and distance falloff for a sound at (x, y). */
  private soundAt(x: number, y: number, radius: number): { pan: number; vol: number } {
    const p = this.player;
    const d = Math.hypot(x - p.x, y - p.y);
    return { pan: (x - p.x) / 500, vol: Phaser.Math.Clamp(1 - d / radius, 0.15, 1) };
  }

  private updateProgress(dt: number, ptx: number, pty: number): void {
    const p = this.player;
    if (this.stations) {
      const station = stationAt(ptx, pty);
      if (station && station !== this.lastStation) {
        if (this.lastStation && p.weapon.reserve < p.weapon.def.magSize * p.weapon.def.spareMags) {
          p.weapon.refill();
          this.toast('Ammo restocked');
        }
        this.lastStation = station;
      }
      if (!this.outcome) {
        for (const s of this.stations.update(ptx, pty)) {
          sfx.ok();
          this.toast(`${s.name} complete`);
        }
      }
    }

    if (this.outcome) return;
    this.updateHostage(dt);
    this.updateEvidence(dt);
    this.updateGetaway();
    this.updateAlarmPanels(dt);
    // The area is secure once every suspect is down and every civilian is secured (or hit).
    const suspectsDown = this.enemies.length > 0 && this.enemies.every((e) => !e.alive);
    // On overwatch, ground units see to the civilians.
    const civiliansSafe = !!this.def.mission?.overwatch || this.civilians.every((c) => c.state === 'secured' || c.state === 'down');
    if (suspectsDown && !civiliansSafe && !this.remindedCivilians) {
      this.remindedCivilians = true;
      this.toast('Suspects down. Secure the civilians.');
    }
    const done = this.stations ? this.stations.allDone : suspectsDown && civiliansSafe;
    if ((done || !p.alive || this.failure) && this.outcomeTimer < 0) {
      this.outcomeTimer = 0;
      if (done && !this.stations && !this.failure) {
        sfx.secured();
        this.toast('Area secure');
      }
    }
    if (this.outcomeTimer >= 0) {
      this.outcomeTimer += dt;
      if (this.outcomeTimer >= OUTCOME_DELAY) {
        // A mission already lost stays lost, even if the operator is hit in the moments after.
        this.outcome = this.failure ? this.lostOutcome(this.failure) : !p.alive ? this.failedOutcome() : this.successOutcome();
      }
    }
  }

  /**
   * The first time a suspect sees the operator, or anyone fires or shouts: the hostage clock
   * starts and someone goes for the evidence.
   */
  private raiseAlarm(): void {
    if (this.alarm || this.intro.active || !this.def.mission) return;
    this.alarm = true;
    const m = this.def.mission;
    if (m.hostage && this.hostage?.canBeSecured) {
      this.clock = m.hostage.seconds;
      this.toast(`Compromised. ${m.hostage.seconds} s to reach the hostage.`);
    }
    if (m.overwatch) {
      const x = m.overwatch.getaway.tx * TILE, y = m.overwatch.getaway.ty * TILE;
      for (const e of this.enemies) if (e.alive) e.sendTo(x, y, OVERWATCH.getawaySpeed);
      this.toast("Compromised. They're making for the car.");
    }
    if (m.evidence) {
      const x = m.evidence.tx * TILE, y = m.evidence.ty * TILE;
      const nearest = this.enemies
        .filter((e) => e.alive && e.type !== 'hider')
        .sort((a, b) => Math.hypot(a.x - x, a.y - y) - Math.hypot(b.x - x, b.y - y))[0];
      if (nearest) {
        nearest.sendTo(x, y);
        this.destroyer = nearest;
        this.toast('Compromised. Suspect moving on the evidence.');
      }
    }
  }

  /** The clock runs until the hostage is secured (or hit); at zero the mission is lost. */
  private updateHostage(dt: number): void {
    if (this.clock === null || !this.hostage) return;
    if (!this.hostage.canBeSecured) {
      this.clock = null;
      return;
    }
    this.clock = Math.max(0, this.clock - dt);
    if (this.clock === 0) {
      this.failure = 'time';
      this.clock = null;
      this.toast('Out of time');
    }
  }

  /**
   * Alarm panels: the alerted guard nearest a panel runs for it, one at a time. Reaching it and
   * staying long enough sets it off.
   */
  private updateAlarmPanels(dt: number): void {
    const panels = this.def.mission?.alarmPanels;
    if (!panels?.length || this.failure) return;
    if (this.alarmRunner && !this.alarmRunner.alive) {
      this.alarmRunner = null;
      this.toast('Alarm runner down');
    }
    if (!this.alarmRunner) {
      let best: { e: Enemy; x: number; y: number; d: number } | null = null;
      for (const e of this.enemies) {
        // Footsteps and doors only make a guard curious; a fight sends him to the alarm.
        if (!e.alive || e.errand || !e.alarmed) continue;
        for (const p of panels) {
          const x = p.tx * TILE, y = p.ty * TILE, d = Math.hypot(x - e.x, y - e.y);
          if (!best || d < best.d) best = { e, x, y, d };
        }
      }
      if (!best) return;
      best.e.sendTo(best.x, best.y, ALARM_RUN_SPEED);
      this.alarmRunner = best.e;
      this.arming = 0;
      this.toast('A guard is running for the alarm');
    }
    if (!this.alarmRunner.atErrand) return;
    this.arming += dt;
    if (this.arming >= ALARM_ARM_TIME) {
      this.failure = 'alarm';
      sfx.penalty();
      this.toast('Alarm raised');
    }
  }

  /** Overwatch: anyone reaching the getaway is gone, and so is the mission. */
  private updateGetaway(): void {
    if (!this.def.mission?.overwatch || this.failure) return;
    if (this.enemies.some((e) => e.alive && e.atErrand)) {
      this.failure = 'escaped';
      this.toast('Suspect at the car');
    }
  }

  /** Whoever was sent for the evidence destroys it unless stopped first. */
  private updateEvidence(dt: number): void {
    const e = this.destroyer;
    const m = this.def.mission;
    if (!e || !m?.evidence) return;
    if (!e.alive) {
      this.destroyer = null;
      this.toast('Evidence secured');
      return;
    }
    if (!e.atErrand) return;
    this.destroying += dt;
    if (this.destroying >= m.evidence.seconds) {
      this.evidenceLost = true;
      this.destroyer = null;
      e.release();
      sfx.penalty();
      this.toast('Evidence destroyed. Star lost.');
    }
  }

  private successOutcome(): Outcome {
    const civiliansHit = [...this.targets, ...this.civilians].filter((t) => t.kind === 'civilian' && t.wasHit).length;
    const accuracy = this.stats.shots ? Math.round((this.stats.hits / this.stats.shots) * 100) : 0;
    const lines: string[] = [];
    if (this.def.mission) {
      const secured = this.civilians.filter((c) => c.state === 'secured').length;
      lines.push(`Suspects down       ${this.enemies.filter((e) => !e.alive).length} of ${this.enemies.length}`);
      if (this.civilians.length && !this.def.mission.overwatch) lines.push(`Civilians secured   ${secured} of ${this.civilians.length}`);
    }
    lines.push(`Shots fired         ${this.stats.shots}`, `Accuracy            ${accuracy}%`);
    if (this.stations) sfx.secured();
    const stars: [boolean, boolean, boolean] = [!this.evidenceLost, civiliansHit === 0, !this.damaged];
    const earned = recordSuccess(progress, this.def.id, stars.filter(Boolean).length);
    saveProgress(progress);
    if (earned) this.promotion = earned.id;
    return {
      success: true,
      title: this.def.mission ? 'Area secure' : 'Range qualification complete',
      stars,
      lines: [
        ...(this.def.mission?.evidence ? [this.evidenceLost ? 'Evidence destroyed' : 'Evidence seized'] : []),
        civiliansHit ? `Civilians hit: ${civiliansHit}` : 'No civilians hit',
        this.damaged ? 'Took damage' : 'No damage taken',
        '',
        ...lines,
      ],
      note: this.def.mission?.debriefNote,
    };
  }

  /** True on a mission in a realism career, where going down (or quitting) ends the career. */
  /** The level's name, for the pause menu and the debrief. */
  get levelName(): string {
    return this.def.name;
  }

  get realism(): boolean {
    return progress.realism && !!this.def.mission;
  }

  private failedOutcome(): Outcome {
    if (this.realism) {
      const record = endCareer(progress, this.def.id);
      saveProgress(progress);
      return {
        success: false,
        title: 'Career over',
        stars: null,
        careerOver: true,
        lines: [
          `You went down at ${this.def.name}.`,
          'In realism mode that ends the career.',
          '',
          `Rank reached     ${RANKS[record.rank]}`,
          `Stars earned     ${record.stars}`,
        ],
      };
    }
    return {
      success: false,
      title: 'Operator down',
      stars: null,
      lines: this.def.mission
        ? ['Intel unchanged.', 'Suspect positions will differ on redeploy.']
        : ['Back to the start of the Range.'],
    };
  }

  /** Lost with the operator still standing: the mission is over, but even a realism career goes on. */
  private lostOutcome(failure: MissionFailure): Outcome {
    progress.deployed = null;
    saveProgress(progress);
    const f = MISSION_FAILURES[failure];
    return { success: false, title: f.title, stars: null, lines: [...f.lines] };
  }

  /** Quitting a realism mission ends the career, the same as going down. */
  abandon(): void {
    const record = endCareer(progress, this.def.id);
    saveProgress(progress);
    endedCareer.record = record;
    endedCareer.reason = 'quit';
    this.leave('menu', {});
  }

  /** Retry: missions go back to the briefing (and a fresh roll), the Range restarts. */
  retry(): void {
    if (this.outcome?.careerOver) this.toMenu();
    else if (this.def.mission) this.leave('briefing', { levelId: this.def.id });
    else this.scene.restart({ levelId: this.def.id });
  }

  /** Back to the menu, by way of the promotion screen if this run earned one. */
  toMenu(): void {
    if (this.promotion) this.leave('promotion', { campaignId: this.promotion });
    else this.leave('menu', {});
  }

  /** Fades the game and its HUD out together, then moves on. */
  private leave(key: string, data: object): void {
    if (this.leaving) return;
    this.leaving = true;
    this.scene.get('hud').cameras.main.fadeOut(260, 7, 9, 12);
    this.cameras.main.fadeOut(260, 7, 9, 12);
    this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => {
      this.scene.stop('hud');
      this.scene.start(key, data);
    });
  }

  private toast(text: string): void {
    this.game.events.emit('toast', text);
  }

  private updateHud(): void {
    const p = this.player;
    const w = p.weapon;
    const ptx = Math.floor(p.x / TILE), pty = Math.floor(p.y / TILE);
    this.hud = {
      tutorial: !!this.stations && !this.intro.active,
      station: this.stations ? stationAt(ptx, pty) : undefined,
      weapon: {
        name: w.suppressed ? `${w.def.name} · suppressed` : w.def.name,
        mag: w.mag,
        magSize: w.def.magSize,
        reserve: w.reserve,
        reload: w.reloading ? 1 - w.reloadLeft / w.def.reloadTime : null,
      },
      dark: this.world.isDark(ptx, pty),
      armor: p.armor,
      health: p.health,
      hurt: this.hurt,
      cutscene: this.intro.active ? { bars: this.intro.bars, subtitle: this.intro.subtitle } : null,
      card: this.def.mission
        ? { title: this.def.mission.title, sub: `${this.def.mission.location}  ·  ${this.def.mission.time}` }
        : { title: this.def.name, sub: 'Port Ardley Police Academy' },
      securing: this.securing ? this.securing.secureProgress : null,
      aim: !this.intro.active && !this.outcome && this.player.alive
        ? { spread: this.player.instability * this.player.weapon.def.wobble, reloading: this.player.weapon.reloading }
        : null,
      charge: hasBreachCharge(progress) && !this.def.mission?.overwatch ? { ready: this.charges > 0, fuse: this.charge?.fuse ?? null } : null,
      clock: this.clock !== null ? { label: 'HOSTAGE', seconds: this.clock }
        : this.alarmRunner?.atErrand ? { label: 'ALARM', seconds: Math.max(0, ALARM_ARM_TIME - this.arming) } : null,
      outcome: this.outcome,
    };
  }
}

/**
 * Tiles that are always lit: everything outdoors (ground, and the props and furniture standing
 * on it) plus the outside face of buildings, i.e. any wall touching the outdoors.
 */
function exteriorTiles(level: ParsedLevel): { tx: number; ty: number }[] {
  const { width, height, tiles, material } = level;
  const outside = (x: number, y: number) =>
    x >= 0 && y >= 0 && x < width && y < height && !blocksSight(tiles[y * width + x]) && isOutdoor(material[y * width + x]);
  const lit: { tx: number; ty: number }[] = [];
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (outside(x, y)) {
        lit.push({ tx: x, ty: y });
        continue;
      }
      if (!blocksSight(tiles[y * width + x])) continue;
      let touches = false;
      for (let dy = -1; dy <= 1 && !touches; dy++) for (let dx = -1; dx <= 1; dx++) if (outside(x + dx, y + dy)) touches = true;
      if (touches) lit.push({ tx: x, ty: y });
    }
  }
  return lit;
}
