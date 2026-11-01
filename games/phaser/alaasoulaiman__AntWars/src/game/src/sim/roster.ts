// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The predators of CONCEPT_V2 section 5 as one typed table, with the numbers behind the slice 3 behaviours (the
// beetle's shell, the antlion's pit, the centipede's slow turn and long body). Speeds read the cap from curve.ts.
import { capPredatorSpeed, isBossRound, isBreatherRound, pickSpeedTier, tierSpeedShare, type BossKind } from './curve';

export type PredatorKind =
  | 'armyAnt'
  | 'wasp'
  | 'spider'
  | 'termite'
  | 'anteater'
  | 'beetle'
  | 'antlion'
  | 'centipede'
  | 'ember'
  | 'moth'
  | 'mantis'
  | 'hornet';
/** The one behaviour each predator has. */
export type Behaviour =
  | 'chase'
  | 'hoverSting'
  | 'webSpit'
  | 'rush'
  | 'nestRaid'
  | 'tank'
  | 'pitTrap'
  | 'snake'
  | 'burst'
  | 'flutter'
  | 'sweep'
  | 'brood';

export interface PredatorSpec {
  kind: PredatorKind;
  name: string;
  /** First round it can spawn. Termites only come on breather rounds. */
  fromRound: number;
  behaviour: Behaviour;
  /** Share of the round's base health (the army ant is 1). */
  hpShare: number;
  /** Fixed health that ignores the round (the termite's 1 HP). */
  fixedHp: number | null;
  /** Share of the ant's base speed, or 'tier' to roll the round's walk, jog, sprint mix. Capped at 0.94 either way. */
  speedShare: number | 'tier';
  /** Damage of one bite on contact. */
  biteDamage: number;
  /** Damage of one ranged shot, 0 when it has none. */
  shotDamage: number;
  /** Seconds between two shots. */
  shotEvery: number;
  /** Shots start inside this distance, in world units. */
  shotRange: number;
  /** Body radius in world units. */
  radius: number;
  /** Nectar the kill drops. */
  nectar: number;
}

/** A web hit slows the ant to this share of its speed for WEB_SECONDS (section 5: the anti training unit). */
export const WEB_SLOW = 0.55;
export const WEB_SECONDS = 2;

export const PREDATORS: Readonly<Record<PredatorKind, PredatorSpec>> = {
  armyAnt: {
    kind: 'armyAnt', name: 'Army ant', fromRound: 1, behaviour: 'chase', hpShare: 1, fixedHp: null,
    speedShare: 'tier', biteDamage: 60, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 15, nectar: 50,
  },
  wasp: {
    kind: 'wasp', name: 'Wasp', fromRound: 6, behaviour: 'hoverSting', hpShare: 0.6, fixedHp: null,
    speedShare: 0.8, biteDamage: 30, shotDamage: 45, shotEvery: 2.4, shotRange: 340, radius: 14, nectar: 70,
  },
  spider: {
    kind: 'spider', name: 'Spider', fromRound: 8, behaviour: 'webSpit', hpShare: 1.5, fixedHp: null,
    speedShare: 0.7, biteDamage: 70, shotDamage: 15, shotEvery: 3.4, shotRange: 330, radius: 17, nectar: 90,
  },
  // Termites are the breather: fast, weak, 1 HP. Their bite is a nuisance (at most about 12 damage a second through
  // the hit grace), so the rush plays as a mowing spree, not a wall. A bite of 25 killed the long run bot here.
  termite: {
    kind: 'termite', name: 'Termite', fromRound: 5, behaviour: 'rush', hpShare: 0, fixedHp: 1,
    speedShare: 0.88, biteDamage: 8, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 10, nectar: 20,
  },
  // The boss every 25th round (CONCEPT_V2 section 5): slow and heavy, it ignores the ant and walks for the nest; once
  // there it eats the colony's nectar until it falls. Twenty army ants of health; its kill drops a big bead and Royal Jelly.
  anteater: {
    kind: 'anteater', name: 'Anteater', fromRound: 25, behaviour: 'nestRaid', hpShare: 20, fixedHp: null,
    speedShare: 0.22, biteDamage: 150, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 46, nectar: 1000,
  },
  // Slice 3. Beetles from round 12: tanks with 5 times the health, slow, a shell that halves darts from the front.
  beetle: {
    kind: 'beetle', name: 'Beetle', fromRound: 12, behaviour: 'tank', hpShare: 5, fixedHp: null,
    speedShare: 0.4, biteDamage: 90, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 24, nectar: 120,
  },
  // Antlions from round 15: each sits in one of the two fixed pits and pulls the ant in when it comes close.
  antlion: {
    kind: 'antlion', name: 'Antlion', fromRound: 15, behaviour: 'pitTrap', hpShare: 3, fixedHp: null,
    speedShare: 0, biteDamage: 80, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 22, nectar: 110,
  },
  // Centipedes from round 20: a long body that bites along its length, fast in a straight line, slow to turn.
  centipede: {
    kind: 'centipede', name: 'Centipede', fromRound: 20, behaviour: 'snake', hpShare: 4, fixedHp: null,
    speedShare: 0.94, biteDamage: 55, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 16, nectar: 150,
  },
  // Slice 4 (more types of enemies; names, looks and numbers ours). Ember ants from round 7: they run at
  // the round's pace and burst when they reach the ant, so the swarm has to be met moving, or shot early.
  ember: {
    kind: 'ember', name: 'Ember ant', fromRound: 7, behaviour: 'burst', hpShare: 0.7, fixedHp: null,
    speedShare: 'tier', biteDamage: 0, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 14, nectar: 60,
  },
  // Dusk moths from round 9: they fly over rocks on a jinking path, so darts aimed where they are going miss.
  moth: {
    kind: 'moth', name: 'Dusk moth', fromRound: 9, behaviour: 'flutter', hpShare: 0.5, fixedHp: null,
    speedShare: 0.85, biteDamage: 35, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 15, nectar: 60,
  },
  // The bosses of the 10th rounds (rounds 10, 30, 70 and 20, 40, 60 by turns; curve.ts bossKind). The Scythe Mantis
  // walks at the ant, raises its blades (a red arc shows where they will fall) and sweeps; step out of the arc.
  mantis: {
    kind: 'mantis', name: 'Scythe Mantis', fromRound: 10, behaviour: 'sweep', hpShare: 14, fixedHp: null,
    speedShare: 0.45, biteDamage: 50, shotDamage: 0, shotEvery: 0, shotRange: 0, radius: 36, nectar: 800,
  },
  // The Brood Hornet hovers out of reach, fires a fan of three stings and keeps calling wasps until it falls.
  hornet: {
    kind: 'hornet', name: 'Brood Hornet', fromRound: 20, behaviour: 'brood', hpShare: 12, fixedHp: null,
    speedShare: 0.6, biteDamage: 60, shotDamage: 45, shotEvery: 2.6, shotRange: 420, radius: 32, nectar: 900,
  },
};

/** The kinds that are bosses: one hit kills, Lucky Sting and the crowd's push pass them by. */
export const BOSS_KINDS: ReadonlyArray<PredatorKind> = ['anteater', 'mantis', 'hornet'];
export function isBossKind(kind: PredatorKind): boolean {
  return BOSS_KINDS.includes(kind);
}
/** The predator that is the boss of a boss round (curve.ts BossKind names the same three). */
export function bossPredator(kind: BossKind): PredatorKind {
  return kind;
}

/** The ember ant lights its fuse this close to the ant, stops, and bursts this long after. */
export const EMBER_FUSE_RANGE = 46;
export const EMBER_FUSE_SECONDS = 0.55;
/** The burst: the ant inside this radius takes the burst (the hit cap still holds); predators inside it take a share of the round's health. */
export const EMBER_BURST_RADIUS = 90;
export const EMBER_BURST_DAMAGE = 110;
export const EMBER_BURST_PREDATOR_SHARE = 0.6;

/** Whether a point this far from a burst's middle is inside it. */
export function inBurst(dist: number): boolean {
  return dist <= EMBER_BURST_RADIUS;
}

/** What a burst does to the ant: a fuse that ran out hurts it; an ember killed by a dart pops on the predators only. */
export function emberBurstOnAnt(fuseRanOut: boolean, distToAnt: number): number {
  return fuseRanOut && inBurst(distToAnt) ? EMBER_BURST_DAMAGE : 0;
}

/** The moth turns to a new heading this often (seconds, a roll between the two), up to this many degrees off the ant. */
export const MOTH_JINK_MIN = 0.35;
export const MOTH_JINK_MAX = 0.7;
export const MOTH_JINK_DEG = 75;
/** Inside this distance the moth stops jinking and goes straight for the bite. */
export const MOTH_DIVE_RANGE = 60;

/** The moth's next heading: the way to the ant turned by up to 75 degrees either side, from a roll in [0, 1). */
export function mothHeading(toAnt: number, roll: number, dist: number): number {
  if (dist <= MOTH_DIVE_RANGE) return wrapAngle(toAnt);
  return wrapAngle(toAnt + (roll * 2 - 1) * ((MOTH_JINK_DEG * Math.PI) / 180));
}

/** The mantis sweep: its blades reach this far, in this half angle of its heading, after this wind up, then rest. */
export const MANTIS_REACH = 150;
export const MANTIS_ARC_DEG = 60;
export const MANTIS_WINDUP_SECONDS = 0.7;
export const MANTIS_REST_SECONDS = 1.6;
export const MANTIS_SWEEP_DAMAGE = 160;
export const MANTIS_TURN_DEG = 90;

/** Whether the ant at (dx, dy) from the mantis, which faces heading, is inside the sweep when the blades fall. */
export function inSweep(dx: number, dy: number, heading: number): boolean {
  const d = Math.hypot(dx, dy);
  if (d > MANTIS_REACH) return false;
  if (d === 0) return true;
  const off = Math.abs(wrapAngle(Math.atan2(dy, dx) - heading));
  return off <= (MANTIS_ARC_DEG * Math.PI) / 180 + 1e-9;
}

/** The Brood Hornet's fan: three stings this many degrees apart; and every this many seconds it calls this many wasps. */
export const HORNET_FAN_DEG = 15;
export const HORNET_FAN = 3;
export const HORNET_BROOD_SECONDS = 6;
export const HORNET_BROOD_COUNT = 2;
/** It calls at most this many times, so a player cannot farm its wasps for nectar by leaving it alive. */
export const HORNET_BROOD_MAX_CALLS = 8;

/** The angles of one fan of stings aimed at angle aim. */
export function hornetFan(aim: number): number[] {
  const out: number[] = [];
  for (let i = 0; i < HORNET_FAN; i++) out.push(aim + (i - (HORNET_FAN - 1) / 2) * ((HORNET_FAN_DEG * Math.PI) / 180));
  return out;
}

/** How many wasps one call adds: two, never past the round's alive cap, none once it has called eight times. */
export function broodCall(alive: number, aliveCap: number, callsSoFar = 0): number {
  if (callsSoFar >= HORNET_BROOD_MAX_CALLS) return 0;
  return Math.max(0, Math.min(HORNET_BROOD_COUNT, aliveCap - alive));
}

/** The first round a predator really shows: its fromRound, or the next horde round when that one is a breather or the boss. */
export function firstHordeRound(kind: PredatorKind): number {
  let r = PREDATORS[kind].fromRound;
  while (isBreatherRound(r) || isBossRound(r)) r += 1;
  return r;
}

/** The beetle's shell: a dart flying into its face, inside this half angle of its heading, does half damage. */
export const SHELL_ARC_DEG = 60;
export const SHELL_FACTOR = 0.5;
/** Degrees a second the beetle and the centipede can turn; the others turn at once. */
export const BEETLE_TURN_DEG = 90;
export const CENTIPEDE_TURN_DEG = 70;

/** An angle in (minus pi, pi]. */
export function wrapAngle(a: number): number {
  let x = a % (2 * Math.PI);
  if (x <= -Math.PI) x += 2 * Math.PI;
  if (x > Math.PI) x -= 2 * Math.PI;
  return x;
}

/** A heading turned toward a target angle by at most maxTurn radians, the short way round. */
export function turnToward(heading: number, target: number, maxTurn: number): number {
  const d = wrapAngle(target - heading);
  if (Math.abs(d) <= maxTurn) return wrapAngle(target);
  return wrapAngle(heading + Math.sign(d) * maxTurn);
}

/** The damage factor of one dart on a beetle facing heading: half when the dart flies into its face, full from the sides and the back. */
export function shellFactor(heading: number, dartVx: number, dartVy: number): number {
  const len = Math.hypot(dartVx, dartVy);
  if (len === 0) return 1;
  // Into its face: the dart flies against the heading, so the reversed dart direction lies inside the front arc.
  const cos = -(dartVx * Math.cos(heading) + dartVy * Math.sin(heading)) / len;
  return cos >= Math.cos((SHELL_ARC_DEG * Math.PI) / 180) - 1e-9 ? SHELL_FACTOR : 1;
}

/**
 * The two pits (CONCEPT_V2 section 5: a sand pit hazard that pulls, two fixed spots): at least 460 units from the nest,
 * so the shop is never inside a pull, and clear of the rocks and the holes.
 */
export const ANTLION_PITS: ReadonlyArray<{ x: number; y: number }> = [
  { x: 1080, y: 560 },
  { x: 360, y: 1460 },
];
/** A live antlion pulls the ant toward its pit inside this distance: 60 units a second at the edge, 160 near the jaws. */
export const PIT_PULL_RADIUS = 240;
export const PIT_PULL_EDGE = 60;
export const PIT_PULL_CORE = 160;
/** Inside this distance the ant is in the jaws: no more pull, so it does not shake on the spot. */
export const PIT_CORE_RADIUS = 12;

/** The pull toward a live antlion's pit, in world units a second, for an ant this far from the pit's middle. */
export function pitPull(dist: number): number {
  if (!(dist < PIT_PULL_RADIUS) || dist <= PIT_CORE_RADIUS) return 0;
  const t = 1 - dist / PIT_PULL_RADIUS;
  return PIT_PULL_EDGE + (PIT_PULL_CORE - PIT_PULL_EDGE) * t;
}

/** The centipede's body: this many segments trail the head, this far apart, each a disc that bites and can be hit. */
export const CENTIPEDE_SEGMENTS = 7;
export const CENTIPEDE_SPACING = 22;
export const CENTIPEDE_SEG_RADIUS = 13;
/** At most this many centipedes live at once; past it a spawn comes as an army ant. Antlions are held to one per pit. */
export const CENTIPEDE_MAX_ALIVE = 2;

/**
 * Where the segments sit: walks back along the head's trail (x, y pairs, newest first) and drops a point every spacing
 * units of path. A trail too short for every segment stacks the rest on its oldest point.
 */
export function placeSegments(trail: ReadonlyArray<number>, count: number, spacing: number): Array<{ x: number; y: number }> {
  const out: Array<{ x: number; y: number }> = [];
  if (trail.length < 2) return out;
  let want = spacing;
  let walked = 0;
  for (let i = 0; i + 3 < trail.length && out.length < count; i += 2) {
    const ax = trail[i];
    const ay = trail[i + 1];
    const bx = trail[i + 2];
    const by = trail[i + 3];
    const seg = Math.hypot(bx - ax, by - ay);
    while (seg > 0 && walked + seg >= want && out.length < count) {
      const t = (want - walked) / seg;
      out.push({ x: ax + (bx - ax) * t, y: ay + (by - ay) * t });
      want += spacing;
    }
    walked += seg;
  }
  const lx = trail[trail.length - 2];
  const ly = trail[trail.length - 1];
  while (out.length < count) out.push({ x: lx, y: ly });
  return out;
}

/** What a spawn really is: a kind held to its limit (a free pit for an antlion, two centipedes) comes as an army ant. */
export function spawnKind(kind: PredatorKind, aliveOfKind: number, freePits: number): PredatorKind {
  if (kind === 'antlion' && freePits <= 0) return 'armyAnt';
  if (kind === 'centipede' && aliveOfKind >= CENTIPEDE_MAX_ALIVE) return 'armyAnt';
  return kind;
}

/** The Anteater eats from the nest once its snout is this close to the nest's centre. */
export const ANTEATER_REACH = 120;
/** At the nest it gulps this much nectar every ANTEATER_GULP_SECONDS, never more than there is. */
export const ANTEATER_GULP = 250;
export const ANTEATER_GULP_SECONDS = 1;

/** Nectar one gulp takes from a stock of this much. */
export function anteaterGulp(nectar: number): number {
  return Math.max(0, Math.min(nectar, ANTEATER_GULP));
}

/** Queen's Blessing (section 5): from round 15 a kill can drop a crown worth 30 seconds of one hit kills or double nectar. */
export type BlessingKind = 'instakill' | 'double';
export const BLESSING_FROM_ROUND = 15;
export const BLESSING_SECONDS = 30;
/** Chance per kill, at most one crown on the field and none while a blessing runs. A first guess. */
export const BLESSING_DROP_CHANCE = 0.015;

export function blessingCanDrop(round: number): boolean {
  return round >= BLESSING_FROM_ROUND;
}

/**
 * Share of a horde round's spawns that are wasps (from round 6), spiders (8), beetles (12), antlions (15) and
 * centipedes (20). First guesses; the rest are army ants.
 */
export const WASP_SHARE = 0.18;
export const SPIDER_SHARE = 0.12;
export const BEETLE_SHARE = 0.1;
export const ANTLION_SHARE = 0.06;
export const CENTIPEDE_SHARE = 0.06;
/** Slice 4: ember ants (from round 7) and dusk moths (from round 9), first guesses. */
export const EMBER_SHARE = 0.07;
export const MOTH_SHARE = 0.07;

/** Which predator one spawn is, from a roll in [0, 1). */
export function pickPredator(round: number, roll: number): PredatorKind {
  if (isBreatherRound(round)) return 'termite';
  const shares: Array<[PredatorKind, number]> = [
    ['wasp', WASP_SHARE],
    ['spider', SPIDER_SHARE],
    ['beetle', BEETLE_SHARE],
    ['antlion', ANTLION_SHARE],
    ['centipede', CENTIPEDE_SHARE],
    ['ember', EMBER_SHARE],
    ['moth', MOTH_SHARE],
  ];
  let edge = 0;
  for (const [kind, share] of shares) {
    if (round < PREDATORS[kind].fromRound) continue;
    edge += share;
    if (roll < edge) return kind;
  }
  return 'armyAnt';
}


/** Speed of one spawn as a share of the ant's base speed, never above the cap. */
export function predatorSpeedShare(kind: PredatorKind, round: number, tierRoll: number): number {
  const spec = PREDATORS[kind];
  if (spec.speedShare === 'tier') return tierSpeedShare(pickSpeedTier(round, tierRoll));
  return capPredatorSpeed(spec.speedShare);
}

/** Health of one spawn given the round's base health from curve.ts. */
export function predatorHealth(kind: PredatorKind, roundHealth: number): number {
  const spec = PREDATORS[kind];
  if (spec.fixedHp !== null) return spec.fixedHp;
  return Math.max(1, Math.round(roundHealth * spec.hpShare));
}
