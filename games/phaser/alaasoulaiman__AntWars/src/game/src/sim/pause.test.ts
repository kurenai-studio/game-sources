// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for lane G9 (design note, 2026-10-25): while a pick sheet is open the Yard holds still, and on the
// tap it runs on from where it stopped. A model Yard runs the scene's frame gate (sheetOpen, yardTick, as GameScene.update
// runs them) over the real round pieces: the round plan and the break countdown (curve.ts) and the Daily spawn stream
// (daily.ts). Frames are 16 ms so every clock value is a whole number and two runs can be compared exactly.
// Lane G9c (design note, 2026-10-25): the cards hold the break countdown too, so a round never begins under a sheet, and
// no nest buy goes through while a sheet is up (shopSells, through the real shop and its prices in economy.ts); on the
// tap the countdown runs on from the same number and the shop sells again.
import { describe, expect, it } from 'vitest';
import { breakStep, roundPlan } from './curve';
import { dailySeed, dailySpawnKinds, spawnRolls, streamSeed } from './daily';
import { buyLine, buyPerk, canBuy, canBuyLine, emptyLines, linePrice, perkSpec, shopState, type LineId, type PerkId } from './economy';
import { makeRng } from './rng';
import { pickPredator, type PredatorKind } from './roster';
import { newYardClock, sheetOpen, shopSells, yardTick, yardTime, type YardClock } from './pause';

const FRAME_MS = 16;
const DAY = '2026-10-25';

interface Foe {
  kind: PredatorKind;
  x: number;
  y: number;
  hp: number;
}
interface Yard {
  clock: YardClock;
  real: number;
  phase: 'active' | 'break';
  round: number;
  queued: number;
  spawnTimer: number;
  breakLeft: number;
  next: () => number;
  ant: { x: number; y: number };
  foes: Foe[];
  hp: number;
  nectar: number;
  biteReadyAt: number;
  fireReadyAt: number;
  /** Each spawn: its round, kind, Yard time and the frame of its round it came on (`f`, the round's running frames). */
  spawns: Array<{ round: number; kind: PredatorKind; at: number; f: number }>;
  pending: number;
  offer: number;
  /** Frames the Yard ran (a held frame does not count). */
  frames: number;
  /** Frames this round ran (a held frame does not count). */
  roundFrames: number;
  /** The nest shop's side of the run (GameScene inNest, owned, lines). */
  inNest: boolean;
  owned: PerkId[];
  lines: Record<LineId, number>;
}

function begin(y: Yard, r: number): void {
  y.round = r;
  y.phase = 'active';
  y.queued = roundPlan(r).total;
  y.spawnTimer = 0.8;
  y.next = makeRng(streamSeed(dailySeed(DAY), 'spawn', r));
  y.roundFrames = 0;
}

function newYard(): Yard {
  const y: Yard = {
    clock: newYardClock(), real: 10_000, phase: 'active', round: 0, queued: 0, spawnTimer: 0, breakLeft: 0, next: Math.random,
    ant: { x: 540, y: 960 }, foes: [], hp: 600, nectar: 0, biteReadyAt: 0, fireReadyAt: 0, spawns: [], pending: 0, offer: 0, frames: 0,
    roundFrames: 0, inNest: false, owned: [], lines: emptyLines(),
  };
  begin(y, 1);
  return y;
}

/** The break countdown, one frame (GameScene.updateDirector's break case): at zero the next round begins. */
function stepBreak(y: Yard, dt: number): void {
  const step = breakStep(y.breakLeft, dt);
  y.breakLeft = step.left;
  if (step.start) begin(y, y.round + 1);
}

/**
 * One frame as GameScene.update runs it: the gate first, then, only when the Yard runs, every system on the Yard clock.
 * A held frame runs nothing, the break countdown included (lane G9c), as update does.
 */
function frame(y: Yard, ms = FRAME_MS): void {
  y.real += ms;
  const dt = Math.min(ms, 50) / 1000;
  const tick = yardTick(y.clock, y.real, sheetOpen(y.pending, y.offer, y.phase));
  y.clock = tick.clock;
  if (!tick.run) return;
  const now = tick.now;
  y.frames += 1;
  y.ant.x += 90 * dt * Math.sin(now / 900);
  y.ant.y += 90 * dt * Math.cos(now / 700);
  for (const f of y.foes) {
    const dx = y.ant.x - f.x;
    const dy = y.ant.y - f.y;
    const d = Math.hypot(dx, dy) || 1;
    f.x += (dx / d) * 70 * dt;
    f.y += (dy / d) * 70 * dt;
    if (d < 40 && now >= y.biteReadyAt) {
      y.hp -= 4;
      y.biteReadyAt = now + 610;
    }
  }
  if (y.foes.length > 0 && now >= y.fireReadyAt) {
    y.fireReadyAt = now + 345;
    const f = y.foes[0];
    f.hp -= 20;
    if (f.hp <= 0) {
      y.foes.shift();
      y.nectar += 10;
    }
  }
  if (y.phase === 'active') {
    y.roundFrames += 1;
    y.spawnTimer -= dt;
    if (y.queued > 0 && y.spawnTimer <= 0) {
      const roll = spawnRolls(y.next);
      const kind = pickPredator(y.round, roll.kind);
      y.foes.push({ kind, x: 100 + roll.hole * 880, y: 100 + roll.pit * 300, hp: 120 });
      y.spawns.push({ round: y.round, kind, at: now, f: y.roundFrames });
      y.queued -= 1;
      y.spawnTimer = roundPlan(y.round).spawnGap;
    }
    if (y.queued === 0 && y.foes.length === 0) {
      y.phase = 'break';
      y.breakLeft = roundPlan(y.round).breakSeconds;
    }
  } else stepBreak(y, dt);
}

const run = (y: Yard, frames: number, ms = FRAME_MS): void => {
  for (let i = 0; i < frames; i++) frame(y, ms);
};
/** Everything the Yard shows and counts (the clock's own bookkeeping left out), as plain data. */
const view = (y: Yard) =>
  JSON.parse(
    JSON.stringify({
      phase: y.phase, round: y.round, queued: y.queued, spawnTimer: y.spawnTimer, breakLeft: y.breakLeft, ant: y.ant, foes: y.foes,
      hp: y.hp, nectar: y.nectar, spawns: y.spawns, at: yardTime(y.clock, y.real), frames: y.frames, biteReadyAt: y.biteReadyAt,
      fireReadyAt: y.fireReadyAt, inNest: y.inNest, owned: y.owned, lines: y.lines,
    }),
  );
/** A nest buy as GameScene takes it: the one gate both buy paths share (shopSellsNow), then the real economy. */
const sells = (y: Yard): boolean => shopSells(shopState(y.phase, y.inNest, false), sheetOpen(y.pending, y.offer, y.phase));
const buyPerkNow = (y: Yard, id: PerkId): boolean => {
  if (!sells(y) || !canBuy(y.nectar, y.owned, id)) return false;
  const bought = buyPerk(y.nectar, y.owned, id);
  y.nectar = bought.nectar;
  y.owned = bought.owned;
  return true;
};
const buyLineNow = (y: Yard, id: LineId): boolean => {
  if (!sells(y) || !canBuyLine(y.nectar, y.lines, id, y.round)) return false;
  const bought = buyLine(y.nectar, y.lines, id, y.round);
  y.nectar = bought.nectar;
  y.lines = bought.levels;
  return true;
};
const open = (y: Yard, picks: number): void => {
  y.pending += picks;
  y.offer = 3;
};
const tap = (y: Yard): void => {
  y.pending -= 1;
  if (y.pending === 0) y.offer = 0;
};

describe('a pick sheet holds the Yard (lane G9)', () => {
  it.each([
    [1, 3, 'active', true],
    [1, 3, 'break', true],
    [1, 3, 'intro', true],
    [2, 3, 'active', true],
    [1, 1, 'break', true],
    [0, 0, 'active', false],
    [0, 0, 'break', false],
    [1, 3, 'dead', false],
    [1, 0, 'active', false],
  ] as const)('pending %s with %s cards in the %s phase: the sheet is open = %s (the nest platform is no input)', (pending, cards, phase, openNow) => {
    expect(sheetOpen(pending, cards, phase)).toBe(openNow);
  });

  it.each([
    ['open', false, true],
    ['open', true, false],
    ['locked', false, false],
    ['locked', true, false],
    ['closed', false, false],
    ['closed', true, false],
  ] as const)('the shop %s with a sheet up %s: a nest buy goes through = %s (lane G9c)', (shop, up, goes) => {
    expect(shopSells(shop, up)).toBe(goes);
  });

  it('the Yard clock frame by frame: it stands while the sheet is open and runs on from there, the held span dropped', () => {
    // [scene clock ms, sheet open, the Yard runs, Yard time ms], in order on one clock.
    const rows: Array<[number, boolean, boolean, number]> = [
      [1000, false, true, 1000],
      [1016, true, false, 1016],
      [5000, true, false, 1016],
      [65_000, true, false, 1016],
      [65_016, false, true, 1016],
      [65_032, false, true, 1032],
      [70_000, true, false, 6000],
      [90_000, false, true, 6000],
      [90_016, false, true, 6016],
    ];
    let c = newYardClock();
    for (const [now, openNow, runs, at] of rows) {
      const t = yardTick(c, now, openNow);
      c = t.clock;
      expect([now, t.run, t.now]).toEqual([now, runs, at]);
    }
  });

  it('time with a sheet open changes nothing (positions, health, countdown, spawns, nectar); the tap resumes the same Yard', () => {
    const a = newYard();
    const b = newYard();
    run(a, 400);
    run(b, 400);
    expect(a.spawns.length).toBeGreaterThan(0);
    expect(a.foes.length).toBeGreaterThan(0);
    expect(view(a)).toEqual(view(b));
    open(a, 1);
    run(a, 1);
    let heldFrames = 1;
    const held = view(a);
    for (const seconds of [1, 5, 30]) {
      const n = Math.round((seconds * 1000) / FRAME_MS);
      run(a, n);
      heldFrames += n;
      expect(view(a)).toEqual(held);
    }
    tap(a);
    run(a, 1);
    // The first frame after the tap runs at the Yard time it stopped at: no catch up of the 36 s held.
    expect(yardTime(a.clock, a.real)).toBe(held.at);
    expect(a.frames).toBe(held.frames + 1);
    run(b, 1);
    run(a, 900);
    run(b, 900);
    // The held Yard is the Yard that never paused, frame for frame: a long think costs nothing and gains nothing.
    expect(view(a)).toEqual(view(b));
    expect(a.real - b.real).toBe(FRAME_MS * heldFrames);
  });

  it('two picks chain: the second sheet opens on the first tap and the Yard stays held until the last one', () => {
    const y = newYard();
    run(y, 300);
    open(y, 2);
    run(y, 1);
    const held = view(y);
    run(y, 200);
    expect(view(y)).toEqual(held);
    tap(y);
    expect(sheetOpen(y.pending, y.offer, y.phase)).toBe(true);
    run(y, 200);
    expect(view(y)).toEqual(held);
    tap(y);
    expect(sheetOpen(y.pending, y.offer, y.phase)).toBe(false);
    run(y, 1);
    expect(y.frames).toBe(held.frames + 1);
    expect(yardTime(y.clock, y.real)).toBe(held.at);
  });

  it('a sheet in a break holds the countdown and the Yard: 3 s under the cards change nothing, the tap runs on from the same number (lane G9c)', () => {
    const y = newYard();
    for (let guard = 0; y.phase !== 'break' && guard < 60_000; guard++) frame(y);
    expect(y.phase).toBe('break');
    const full = roundPlan(1).breakSeconds;
    run(y, 100, 20);
    expect(y.breakLeft).toBeCloseTo(full - 2, 9);
    open(y, 1);
    run(y, 1, 20);
    const before = view(y);
    run(y, 150, 20);
    const after = view(y);
    // The countdown (the HUD reads NEXT ROUND IN its ceiling) stands at the same value, and nothing in the Yard moved.
    expect(before.breakLeft).toBeCloseTo(full - 2, 9);
    expect(after.breakLeft).toBe(before.breakLeft);
    expect(Math.ceil(after.breakLeft)).toBe(Math.ceil(before.breakLeft));
    expect(after).toEqual(before);
    tap(y);
    run(y, 50, 20);
    // 1 s after the tap: the countdown 1 s below the value it stood at, the Yard 50 frames on from the time it stopped.
    expect(y.breakLeft).toBeCloseTo(before.breakLeft - 1, 9);
    expect(y.frames).toBe(before.frames + 50);
    expect(yardTime(y.clock, y.real)).toBe(before.at + 49 * 20);
  });

  it('a round never begins under a sheet: the break countdown stands for 5 s and for 65 s of cards, then runs on (lane G9c)', () => {
    const y = newYard();
    for (let guard = 0; y.phase !== 'break' && guard < 60_000; guard++) frame(y);
    expect(y.phase).toBe('break');
    const full = roundPlan(1).breakSeconds;
    run(y, 125);
    const rows: Array<[string, number, number]> = [];
    rows.push(['2 s into the break', y.breakLeft, Math.ceil(y.breakLeft)]);
    open(y, 1);
    run(y, 1);
    run(y, 312);
    rows.push(['the cards up 5 s', y.breakLeft, Math.ceil(y.breakLeft)]);
    run(y, 3750);
    rows.push(['the cards up 65 s', y.breakLeft, Math.ceil(y.breakLeft)]);
    // 65 s is far past the whole break: the next round still waits, nothing queued, nothing spawned.
    expect([y.phase, y.round, y.queued, y.spawns.filter((s) => s.round === 2).length]).toEqual(['break', 1, 0, 0]);
    tap(y);
    run(y, 62);
    rows.push(['1 s after the tap', y.breakLeft, Math.ceil(y.breakLeft)]);
    const want: Array<[string, number, number]> = [
      ['2 s into the break', full - 2, Math.ceil(full - 2)],
      ['the cards up 5 s', full - 2, Math.ceil(full - 2)],
      ['the cards up 65 s', full - 2, Math.ceil(full - 2)],
      ['1 s after the tap', full - 2 - 0.992, Math.ceil(full - 2 - 0.992)],
    ];
    rows.forEach(([label, left, shown], i) => {
      expect(label).toBe(want[i][0]);
      expect(left).toBeCloseTo(want[i][1], 6);
      expect(shown).toBe(want[i][2]);
    });
    expect(y.phase).toBe('break');
  });

  it('no nest buy goes through under the cards: refused, nothing changes; after the tap the countdown runs on and the buy goes through (lane G9c)', () => {
    const y = newYard();
    for (let guard = 0; y.phase !== 'break' && guard < 60_000; guard++) frame(y);
    expect(y.phase).toBe('break');
    y.inNest = true;
    y.nectar = 5000;
    run(y, 60, 20);
    expect(sells(y)).toBe(true);
    open(y, 1);
    run(y, 1, 20);
    const before = view(y);
    const sheet = [y.pending, y.offer];
    const price = linePrice('damage', y.lines);
    expect(before.nectar).toBeGreaterThanOrEqual(price + perkSpec('chitin').price);
    // Taps on the shop under the cards: the perk and the line are both refused, and nothing moves (the nectar, the perks
    // owned, the line's level and its price, the waiting pick, the countdown), 3 s later too.
    expect(sells(y)).toBe(false);
    expect(buyPerkNow(y, 'chitin')).toBe(false);
    expect(buyLineNow(y, 'damage')).toBe(false);
    run(y, 150, 20);
    expect(buyLineNow(y, 'damage')).toBe(false);
    expect(view(y)).toEqual(before);
    expect([y.pending, y.offer]).toEqual(sheet);
    expect(linePrice('damage', y.lines)).toBe(price);
    tap(y);
    run(y, 1, 20);
    // The tap: the countdown runs on from the value it stood at (the same number on the HUD), and the same buys go through.
    expect(y.breakLeft).toBeCloseTo(before.breakLeft - 0.02, 9);
    expect(Math.ceil(y.breakLeft)).toBe(Math.ceil(before.breakLeft));
    expect(buyLineNow(y, 'damage')).toBe(true);
    expect(buyPerkNow(y, 'chitin')).toBe(true);
    expect(y.lines.damage).toBe(before.lines.damage + 1);
    expect(y.owned).toEqual([...before.owned, 'chitin']);
    expect(y.nectar).toBe(before.nectar - price - perkSpec('chitin').price);
  });

  it('the Daily spawns come in the same order at the same Yard times with and without pauses', () => {
    const plain = newYard();
    const paused = newYard();
    const total = 2600;
    while (plain.frames < total) frame(plain);
    const phases: string[] = [];
    let nextAt = 90;
    let chain = false;
    while (paused.frames < total) {
      if (paused.frames === nextAt && paused.pending === 0) {
        phases.push(paused.phase);
        const picks = chain ? 2 : 1;
        chain = !chain;
        open(paused, picks);
        for (let k = 0; k < picks; k++) {
          run(paused, 47 + 31 * k);
          tap(paused);
        }
        nextAt += 173;
      }
      frame(paused);
    }
    expect(phases).toContain('active');
    expect(phases).toContain('break');
    expect(plain.round).toBeGreaterThanOrEqual(2);
    expect(paused.spawns.length).toBeGreaterThan(5);
    // Every clock holds under the cards, the break countdown too (lane G9c): the paused run is the plain one exactly,
    // the same spawns at the same Yard times on the same frames of their rounds, and the same Yard at the end.
    expect(plain.spawns.some((s) => s.round >= 2)).toBe(true);
    expect(paused.spawns).toEqual(plain.spawns);
    expect(view(paused)).toEqual(view(plain));
    for (const r of [1, 2]) {
      const kinds = plain.spawns.filter((s) => s.round === r).map((s) => s.kind);
      expect(kinds).toEqual(dailySpawnKinds(DAY, r, kinds.length));
    }
  });
});
