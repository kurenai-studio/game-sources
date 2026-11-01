// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
import { describe, expect, it } from 'vitest';
import { NO_POINTER, PRESS_SLOP_PX, STICK_RADIUS, TAP_MAX_MS, TapTracker, ThumbStick, readStick } from './joystick';

describe('thumb stick', () => {
  it('a finger on the base or inside the dead zone means standing still', () => {
    expect(readStick(100, 100, 100, 100).moving).toBe(false);
    expect(readStick(100, 100, 109, 100).moving).toBe(false);
  });

  it('the dead zone is a distance: under it the ant stands, at it the ant runs', () => {
    expect(readStick(0, 0, 9.99, 0, STICK_RADIUS, 10).moving).toBe(false);
    expect(readStick(0, 0, 10, 0, STICK_RADIUS, 10)).toMatchObject({ moving: true, x: 1, y: 0 });
    expect(readStick(0, 0, 0, 18, STICK_RADIUS, 18.5).moving).toBe(false);
    expect(readStick(0, 0, 0, 18.5, STICK_RADIUS, 18.5).moving).toBe(true);
  });

  it('past the dead zone it gives a unit direction', () => {
    const r = readStick(100, 100, 150, 100);
    expect(r).toMatchObject({ moving: true, x: 1, y: 0 });
    const diag = readStick(0, 0, 40, 40);
    expect(Math.hypot(diag.x, diag.y)).toBeCloseTo(1, 9);
  });

  // Lane N1, design note of 2026-10-29: the base trailed a finger past the radius here (to 208); it stays put now.
  it('the base stays where the touch landed when the finger runs past the radius, the knob on the ring', () => {
    const r = readStick(100, 100, 100 + STICK_RADIUS + 108, 100);
    expect(r.baseX).toBe(100);
    expect(r.baseY).toBe(100);
    expect(r.knobX).toBeCloseTo(100 + STICK_RADIUS, 9);
    expect(r.knobY).toBe(100);
    expect(r).toMatchObject({ moving: true, x: 1, y: 0 });
  });
});

// Design note, 2026-10-29 (lane N1): the stick stays firm where the first touch landed. A touch in the bottom third
// of a 1558 unit tall screen (the 390 by 844 phone), then the thumb 2 and 5 ring radii away.
const BASE = { x: 360, y: 1200 };
const ANGLES = [0, 45, 90, 135, 180, 225, 270, 315];
const AWAY = ANGLES.flatMap((deg) => [2, 5].map((radii) => [deg, radii] as const));

describe('the base stays where the first touch landed (lane N1)', () => {
  it.each(AWAY)('the thumb %i degrees round and %i ring radii away: the base unmoved, the ant runs toward the thumb, the knob on the ring', (deg, radii) => {
    const a = (deg * Math.PI) / 180;
    const s = new ThumbStick();
    expect(s.down(1, BASE.x, BASE.y)).toBe(true);
    const r = s.move(1, BASE.x + Math.cos(a) * radii * STICK_RADIUS, BASE.y + Math.sin(a) * radii * STICK_RADIUS);
    expect(r).not.toBeNull();
    const reading = r as NonNullable<typeof r>;
    expect([reading.baseX, reading.baseY]).toEqual([BASE.x, BASE.y]);
    expect([s.baseX, s.baseY]).toEqual([BASE.x, BASE.y]);
    expect(reading.moving).toBe(true);
    expect(reading.x).toBeCloseTo(Math.cos(a), 9);
    expect(reading.y).toBeCloseTo(Math.sin(a), 9);
    expect(Math.hypot(reading.knobX - BASE.x, reading.knobY - BASE.y)).toBeCloseTo(STICK_RADIUS, 9);
  });

  it('a thumb that runs far right and comes back, still right of the first touch, keeps the ant running right', () => {
    const s = new ThumbStick();
    s.down(1, BASE.x, BASE.y);
    s.move(1, BASE.x + 5 * STICK_RADIUS, BASE.y);
    const back = s.move(1, BASE.x + 3 * STICK_RADIUS, BASE.y);
    expect(back).toMatchObject({ moving: true, x: 1, y: 0, baseX: BASE.x, baseY: BASE.y });
  });

  it('a thumb that runs far away and comes home to the first touch stands the ant still', () => {
    const s = new ThumbStick();
    s.down(1, BASE.x, BASE.y);
    s.move(1, BASE.x - 4 * STICK_RADIUS, BASE.y - 4 * STICK_RADIUS);
    expect(s.move(1, BASE.x + 3, BASE.y - 2)?.moving).toBe(false);
  });

  it('a long winding drag never moves the base; the way the ant runs is always the thumb from the first touch', () => {
    const s = new ThumbStick();
    s.down(1, BASE.x, BASE.y);
    const path = [
      [600, 300],
      [40, 200],
      [700, 1500],
      [100, 1400],
      [361, 1000],
    ];
    for (const [x, y] of path) {
      const r = s.move(1, x, y) as NonNullable<ReturnType<ThumbStick['move']>>;
      const d = Math.hypot(x - BASE.x, y - BASE.y);
      expect([r.baseX, r.baseY]).toEqual([BASE.x, BASE.y]);
      expect(r.x).toBeCloseTo((x - BASE.x) / d, 9);
      expect(r.y).toBeCloseTo((y - BASE.y) / d, 9);
    }
  });

  it('lifting ends the stick; the next touch starts a new base where it lands, however far the last thumb went', () => {
    const s = new ThumbStick();
    s.down(1, 100, 1300);
    s.move(1, 650, 350);
    expect(s.up(1)).toBe(true);
    expect(s.down(2, 500, 900)).toBe(true);
    expect([s.baseX, s.baseY]).toEqual([500, 900]);
    expect(s.move(2, 500, 800)).toMatchObject({ moving: true, x: 0, y: -1, baseX: 500, baseY: 900 });
  });

  it('full speed at the ring and past it: the way to run is a whole step whatever the distance past the dead zone', () => {
    for (const k of [0.2, 1, 2, 5]) {
      const r = readStick(0, 0, 0, -k * STICK_RADIUS);
      expect(r).toMatchObject({ moving: true, x: 0, y: -1 });
    }
  });
});

// The HUD is 720 units wide: x 600 sits on the right half, where slice 1 ignored the thumb.
describe('the stick anywhere on the screen (feel round 1)', () => {
  it('a first touch on the right half takes the stick with its origin under the thumb', () => {
    const s = new ThumbStick();
    expect(s.down(1, 600, 1200)).toBe(true);
    expect(s).toMatchObject({ pointerId: 1, baseX: 600, baseY: 1200 });
    expect(s.move(1, 600, 1150)).toMatchObject({ moving: true, x: 0, y: -1, baseX: 600, baseY: 1200 });
  });

  it('a touch on the left half works the same way', () => {
    const s = new ThumbStick();
    expect(s.down(1, 120, 1300)).toBe(true);
    expect(s.move(1, 170, 1300)).toMatchObject({ moving: true, x: 1, y: 0, baseX: 120, baseY: 1300 });
  });

  it('a second finger can neither take the stick nor break it', () => {
    const s = new ThumbStick();
    s.down(1, 600, 1200);
    expect(s.down(2, 100, 300)).toBe(false);
    expect(s).toMatchObject({ pointerId: 1, baseX: 600, baseY: 1200 });
    expect(s.move(2, 0, 0)).toBeNull();
    expect(s.up(2)).toBe(false);
    expect(s.move(1, 650, 1200)).toMatchObject({ moving: true, x: 1, y: 0 });
  });

  it('lifting the stick finger stops it; the next touch starts a new stick where it lands', () => {
    const s = new ThumbStick();
    s.down(1, 600, 1200);
    expect(s.up(1)).toBe(true);
    expect(s.pointerId).toBe(NO_POINTER);
    expect(s.move(1, 650, 1200)).toBeNull();
    expect(s.down(2, 640, 300)).toBe(true);
    expect(s).toMatchObject({ pointerId: 2, baseX: 640, baseY: 300 });
  });

  it('a touch that lands on a shop card takes the stick too, so a drag from a card moves the ant', () => {
    const s = new ThumbStick();
    expect(s.down(1, 540, 1230)).toBe(true);
    expect(s.move(1, 540, 1150)).toMatchObject({ moving: true, x: 0, y: -1 });
  });

  it('the mouse (pointer 0) drives it the same way on a desk', () => {
    const s = new ThumbStick();
    expect(s.down(0, 500, 500)).toBe(true);
    expect(s.move(0, 500, 560)).toMatchObject({ moving: true, x: 0, y: 1 });
    expect(s.up(0)).toBe(true);
    expect(s.pointerId).toBe(NO_POINTER);
  });
});

// A 390 point wide phone shows 720 HUD units, so 10 screen points are 10 x 720 / 390 = 18.46 units.
const K = 720 / 390;
const SLOP = PRESS_SLOP_PX * K;

describe('a shop card buys only on a tap (polish round)', () => {
  it('the rule is a lift within 300 ms that strayed under 10 points', () => {
    expect(TAP_MAX_MS).toBe(300);
    expect(PRESS_SLOP_PX).toBe(10);
  });

  it('a quick still press is a tap and names its card, up to 300 ms exactly', () => {
    const t = new TapTracker<string>();
    t.down(1, 538, 1234, 1000, 'twin');
    t.move(1, 541, 1236);
    expect(t.up(1, 541, 1236, 1250, SLOP)).toBe('twin');
    t.down(1, 538, 1234, 2000, 'twin');
    expect(t.up(1, 538, 1234, 2300, SLOP)).toBe('twin');
  });

  it('a thumb resting on a card past 300 ms never buys', () => {
    const t = new TapTracker<string>();
    t.down(1, 538, 1234, 1000, 'chitin');
    expect(t.up(1, 538, 1234, 1301, SLOP)).toBeNull();
  });

  it('a drag that starts on a card never buys, even when it comes back to where it landed', () => {
    const t = new TapTracker<string>();
    t.down(1, 538, 1234, 1000, 'quick');
    t.move(1, 538, 1204); // 30 units, past the slop
    t.move(1, 538, 1234);
    expect(t.up(1, 538, 1234, 1100, SLOP)).toBeNull();
  });

  it('the lift point counts even with no move event before it', () => {
    const t = new TapTracker<string>();
    t.down(1, 538, 1234, 1000, 'twin');
    expect(t.up(1, 600, 1234, 1100, SLOP)).toBeNull();
  });

  it('each finger has its own press: a second finger can tap a card while the first drags', () => {
    const t = new TapTracker<string>();
    t.down(1, 538, 1234, 1000, 'chitin');
    t.down(2, 538, 1350, 1050, 'twin');
    t.move(1, 400, 1234);
    expect(t.up(2, 539, 1351, 1200, SLOP)).toBe('twin');
    expect(t.up(1, 400, 1234, 1250, SLOP)).toBeNull();
  });

  it('a lift with no press, or after the presses were cleared, does nothing', () => {
    const t = new TapTracker<string>();
    expect(t.up(3, 0, 0, 0, SLOP)).toBeNull();
    t.down(1, 538, 1234, 1000, 'twin');
    t.clear();
    expect(t.up(1, 538, 1234, 1100, SLOP)).toBeNull();
  });
});

describe('one press slop for the stick and the tap (VG2 note 2)', () => {
  // A quick press (lifted after 100 ms) that moves d screen points: exactly one of the two may happen, never both.
  it.each([0, 4, 8, 9, 9.5, 9.99, 10, 10.01, 11, 12, 15, 30])('a quick press that moves %s points either nudges the ant or taps, not both', (d) => {
    const stick = new ThumbStick();
    const taps = new TapTracker<string>();
    expect(stick.down(1, 0, 900, SLOP)).toBe(true);
    taps.down(1, 0, 900, 1000, 'card');
    const reading = stick.move(1, d * K, 900);
    taps.move(1, d * K, 900);
    const nudged = reading !== null && reading.moving;
    const tapped = taps.up(1, d * K, 900, 1100, SLOP) !== null;
    expect(nudged !== tapped).toBe(true);
    expect(tapped).toBe(d < PRESS_SLOP_PX);
  });

  it('the stick keeps the slop it was given for the whole press', () => {
    const stick = new ThumbStick();
    stick.down(1, 0, 0, 20);
    expect(stick.deadzone).toBe(20);
    expect(stick.move(1, 19, 0)?.moving).toBe(false);
    expect(stick.move(1, 21, 0)?.moving).toBe(true);
  });
});
