// @vitest-environment jsdom
// nutrients.js adds elements to the page, so these tests run in jsdom, a
// simulated browser page.
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { scatterNutrients } from '../public/game/nutrients.js';

const COUNT = 10; // flecks on the agar at a time
const RESPAWN_MS = 3000;

// Every fleck on the agar that hasn't been eaten, with its position as a
// fraction of the dish radius from the center (-1 to 1), read back from the
// left/top percentages it was placed at.
function liveFlecks() {
  return [...document.querySelectorAll('.agar .nutrient:not(.eaten)')].map((el) => ({
    el,
    fx: (parseFloat(el.style.left) - 50) / 50,
    fy: (parseFloat(el.style.top) - 50) / 50,
  }));
}

beforeEach(() => {
  document.body.innerHTML = '<div class="agar"></div>';
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

describe('scattering nutrients', () => {
  it(`starts with ${COUNT} flecks on the agar`, () => {
    scatterNutrients();
    expect(liveFlecks()).toHaveLength(COUNT);
  });

  // Placement is random, so check the rules hold across many fresh dishes.
  it('keeps every fleck away from the rim', () => {
    for (let dish = 0; dish < 30; dish++) {
      document.body.innerHTML = '<div class="agar"></div>';
      scatterNutrients();
      for (const f of liveFlecks()) expect(Math.hypot(f.fx, f.fy)).toBeLessThanOrEqual(0.82);
    }
  });

  it('keeps the middle clear so the gal does not start on top of food', () => {
    for (let dish = 0; dish < 30; dish++) {
      document.body.innerHTML = '<div class="agar"></div>';
      scatterNutrients();
      for (const f of liveFlecks()) expect(Math.hypot(f.fx, f.fy)).toBeGreaterThan(0.3);
    }
  });

  it('spaces flecks apart instead of clumping them', () => {
    for (let dish = 0; dish < 30; dish++) {
      document.body.innerHTML = '<div class="agar"></div>';
      scatterNutrients();
      const flecks = liveFlecks();
      for (let i = 0; i < flecks.length; i++) {
        for (let j = i + 1; j < flecks.length; j++) {
          const gap = Math.hypot(flecks[i].fx - flecks[j].fx, flecks[i].fy - flecks[j].fy);
          expect(gap).toBeGreaterThan(0.12);
        }
      }
    }
  });

  it('keeps flecks off areas to avoid, like the antifungal disk', () => {
    const disk = { fx: 0.5, fy: 0.2, r: 0.07 };
    for (let dish = 0; dish < 30; dish++) {
      document.body.innerHTML = '<div class="agar"></div>';
      const nutrients = scatterNutrients({ avoid: [disk] });
      // Also eat and respawn a few times, since replacements must avoid it too.
      for (let bite = 0; bite < 5; bite++) {
        const [target] = liveFlecks();
        nutrients.eatNear(target.fx, target.fy, 0.01);
        vi.advanceTimersByTime(RESPAWN_MS);
      }
      for (const f of liveFlecks()) {
        expect(Math.hypot(f.fx - disk.fx, f.fy - disk.fy)).toBeGreaterThan(disk.r + 0.12);
      }
    }
  });

  it('hides flecks from screen readers, since they are decoration', () => {
    scatterNutrients();
    for (const f of liveFlecks()) expect(f.el.getAttribute('aria-hidden')).toBe('true');
  });
});

describe('colors', () => {
  it('gives each fleck a rainbow color, not all the same one', () => {
    const hues = new Set();
    for (let dish = 0; dish < 5; dish++) {
      document.body.innerHTML = '<div class="agar"></div>';
      scatterNutrients();
      for (const f of liveFlecks()) {
        const hue = Number(f.el.style.getPropertyValue('--hue'));
        expect(hue).toBeGreaterThanOrEqual(0);
        expect(hue).toBeLessThan(360);
        hues.add(hue);
      }
    }
    expect(hues.size).toBeGreaterThan(10);
  });
});

describe('count and positions', () => {
  it('can put a different number of flecks on the agar', () => {
    scatterNutrients({ count: 14 });
    expect(liveFlecks()).toHaveLength(14);
  });

  it('reports where every fleck is', () => {
    const nutrients = scatterNutrients();
    const reported = nutrients.positions();
    expect(reported).toHaveLength(COUNT);
    for (const f of liveFlecks()) {
      expect(reported.some((p) => Math.abs(p.fx - f.fx) < 1e-6 && Math.abs(p.fy - f.fy) < 1e-6)).toBe(true);
    }
  });

  it('stops reporting a fleck once it is eaten', () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    nutrients.eatNear(target.fx, target.fy, 0.01);
    expect(nutrients.positions()).toHaveLength(COUNT - 1);
  });
});

describe('eating nutrients', () => {
  it('eats a fleck the gal is on and reports it', () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    const eaten = vi.fn();
    expect(nutrients.eatNear(target.fx + 0.005, target.fy, 0.01, eaten)).toBe(1);
    // Says exactly where the fleck was, not where the gal was.
    expect(eaten).toHaveBeenCalledTimes(1);
    const [fx, fy] = eaten.mock.calls[0];
    expect(fx).toBeCloseTo(target.fx);
    expect(fy).toBeCloseTo(target.fy);
    expect(target.el.classList.contains('eaten')).toBe(true);
    expect(liveFlecks()).toHaveLength(COUNT - 1);
  });

  // A fleck's radius as a fraction of the dish radius (see the CSS widths).
  const fleckRadius = (el) => (el.classList.contains('small') ? 0.015 : 0.022);

  it('eats a fleck as soon as its edge touches the gal', () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    const reach = 0.05;
    // The gal's circle is centered just far enough away for the edges to meet.
    const gap = reach + fleckRadius(target.el) - 0.001;
    // (Another random fleck can be in reach too, so check this one went.)
    expect(nutrients.eatNear(target.fx + gap, target.fy, reach)).toBeGreaterThanOrEqual(1);
    expect(target.el.classList.contains('eaten')).toBe(true);
  });

  it('does not eat a fleck whose edge is just short of the gal', () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    const reach = 0.05;
    const gap = reach + fleckRadius(target.el) + 0.002;
    // Make sure no other fleck happens to be at the test spot.
    const others = liveFlecks().filter((f) => f !== target);
    const spot = [target.fx + gap, target.fy];
    const nearOther = others.some((f) => Math.hypot(f.fx - spot[0], f.fy - spot[1]) < reach + 0.03);
    if (nearOther) return;
    expect(nutrients.eatNear(spot[0], spot[1], reach)).toBe(0);
  });

  it('does not eat flecks that are out of reach', () => {
    const nutrients = scatterNutrients();
    // The middle is kept clear, so nothing is within 0.2 of the center.
    expect(nutrients.eatNear(0, 0, 0.2)).toBe(0);
    expect(liveFlecks()).toHaveLength(COUNT);
  });

  it('can eat several flecks at once with a big enough reach', () => {
    const nutrients = scatterNutrients();
    expect(nutrients.eatNear(0, 0, 2)).toBe(COUNT);
    expect(liveFlecks()).toHaveLength(0);
  });

  it('cannot eat the same fleck twice', () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    nutrients.eatNear(target.fx, target.fy, 0.01);
    expect(nutrients.eatNear(target.fx, target.fy, 0.01)).toBe(0);
  });

  it('removes an eaten fleck from the page once its shrink animation ends', () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    nutrients.eatNear(target.fx, target.fy, 0.01);
    expect(target.el.isConnected).toBe(true); // still shrinking away
    target.el.dispatchEvent(new Event('transitionend'));
    expect(target.el.isConnected).toBe(false);
  });
});

describe('respawning nutrients', () => {
  it(`replaces an eaten fleck ${RESPAWN_MS / 1000} seconds later, not sooner`, () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    nutrients.eatNear(target.fx, target.fy, 0.01);

    vi.advanceTimersByTime(RESPAWN_MS - 1);
    expect(liveFlecks()).toHaveLength(COUNT - 1);

    vi.advanceTimersByTime(1);
    expect(liveFlecks()).toHaveLength(COUNT);
  });

  it('puts the replacement somewhere else, not right where the gal ate', () => {
    for (let round = 0; round < 20; round++) {
      document.body.innerHTML = '<div class="agar"></div>';
      const nutrients = scatterNutrients();
      const [target] = liveFlecks();
      nutrients.eatNear(target.fx, target.fy, 0.01);
      const before = new Set(liveFlecks().map((f) => f.el));
      vi.advanceTimersByTime(RESPAWN_MS);
      const replacement = liveFlecks().find((f) => !before.has(f.el));
      expect(Math.hypot(replacement.fx - target.fx, replacement.fy - target.fy)).toBeGreaterThan(0.3);
    }
  });

  it('keeps the count steady through lots of eating', () => {
    const nutrients = scatterNutrients();
    for (let bite = 0; bite < 25; bite++) {
      const [target] = liveFlecks();
      nutrients.eatNear(target.fx, target.fy, 0.01);
      vi.advanceTimersByTime(RESPAWN_MS);
    }
    expect(liveFlecks()).toHaveLength(COUNT);
  });

  it('keeps the count steady on a crowded dish, squeezing flecks into small gaps', () => {
    // A ring of big areas to avoid (like a mold's colonies) covering most of
    // the dish, leaving only narrow gaps between them.
    const avoid = [{ fx: 0, fy: 0, r: 0.3 }];
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * Math.PI * 2;
      avoid.push({ fx: Math.cos(a) * 0.62, fy: Math.sin(a) * 0.62, r: 0.16 });
    }
    const nutrients = scatterNutrients({ avoid, count: 5 });
    expect(liveFlecks()).toHaveLength(5);
    for (let bite = 0; bite < 25; bite++) {
      const [target] = liveFlecks();
      nutrients.eatNear(target.fx, target.fy, 0.01);
      vi.advanceTimersByTime(RESPAWN_MS);
    }
    expect(liveFlecks()).toHaveLength(5);
    // Still clear of everything to avoid.
    for (const f of liveFlecks()) {
      for (const a of avoid) expect(Math.hypot(f.fx - a.fx, f.fy - a.fy)).toBeGreaterThan(a.r);
    }
  });

  it("keeps a squeezed-in fleck out of a disk's zone, not just off the disk", () => {
    // Everything is covered but a thin ring around one disk, inside its zone.
    const disk = { fx: 0.5, fy: 0, r: 0.08, zone: 0.02, fullZone: 0.07 };
    const avoid = [disk, { fx: -0.3, fy: 0, r: 0.65 }, { fx: 0.5, fy: 0.5, r: 0.38 }, { fx: 0.5, fy: -0.5, r: 0.38 }];
    scatterNutrients({ avoid, count: 3 });
    for (const f of liveFlecks()) {
      expect(Math.hypot(f.fx - disk.fx, f.fy - disk.fy)).toBeGreaterThan(disk.r + disk.fullZone);
    }
  });

  it('tries again a moment later when the dish is full, instead of losing the fleck', () => {
    // Nowhere to go at first.
    const avoid = [{ fx: 0, fy: 0, r: 2 }];
    scatterNutrients({ avoid, count: 3 });
    expect(liveFlecks()).toHaveLength(0);
    // Room again (say, a colony popped): they all come back.
    avoid.length = 0;
    vi.advanceTimersByTime(500);
    expect(liveFlecks()).toHaveLength(3);
  });

  it('stops replacing flecks once the game is over', () => {
    const nutrients = scatterNutrients();
    const [target] = liveFlecks();
    nutrients.eatNear(target.fx, target.fy, 0.01);
    nutrients.stop();
    vi.advanceTimersByTime(RESPAWN_MS * 2);
    expect(liveFlecks()).toHaveLength(COUNT - 1);
  });
});
