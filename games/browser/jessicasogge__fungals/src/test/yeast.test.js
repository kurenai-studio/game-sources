// @vitest-environment jsdom
// yeast.js draws cells into the page, so these tests run in jsdom, a
// simulated browser page.
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { R, ROD_STEP, SPACING } from '../public/game/attach.js';
import { yeastGroup } from '../public/game/yeast.js';
import { GAME, SPECIES } from '../public/game/config.js';

// jsdom doesn't lay anything out, so every width reads as 0. Give the dish a
// fixed size and work out each mover's width from its percent width, the way
// the browser would.
const DISH_WIDTH = 400;
const DISH_RADIUS = DISH_WIDTH / 2;
const CELL_PX = 0.05 * DISH_WIDTH; // CELL_SIZE is 5% of the dish
const UNIT = CELL_PX / (2 * R); // pixels per SVG unit

let saved;
beforeEach(() => {
  document.body.innerHTML = '<div class="agar"></div>';
  saved = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'offsetWidth');
  Object.defineProperty(HTMLElement.prototype, 'offsetWidth', {
    configurable: true,
    get() {
      return ((parseFloat(this.style.width) || 0) / 100) * DISH_WIDTH;
    },
  });
});
afterEach(() => {
  if (saved) Object.defineProperty(HTMLElement.prototype, 'offsetWidth', saved);
  else delete HTMLElement.prototype.offsetWidth;
});

// A group in the dish at (x, y) px from the center, like the game makes.
function makeGroup(name, { isPlayer = false, x = 0, y = 0 } = {}) {
  const mover = document.createElement('div');
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  mover.appendChild(svg);
  document.querySelector('.agar').appendChild(mover);
  const group = yeastGroup({ mover, svg, species: SPECIES[name], isPlayer });
  group.x = x;
  group.y = y;
  return group;
}

// Grow an offspring group to `size` cells by budding from a player next to it.
function grow(group, size) {
  const player = makeGroup('sasha', { isPlayer: true, x: group.x, y: group.y });
  while (group.cellCount() < size) {
    player.divide([group], DISH_RADIUS);
    group.update(1); // finish sliding the new cell into place
  }
}

const cellCenters = (group) => group.body().map(([x, y]) => [x, y]);
const distance = ([ax, ay], [bx, by]) => Math.hypot(ax - bx, ay - by);

describe('a new yeast cell', () => {
  it('starts as a single cell', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    expect(player.cellCount()).toBe(1);
  });

  it('only the player has a face', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    const offspring = makeGroup('sasha');
    expect(player.svg.querySelectorAll('ellipse:not(.cell-body)')).toHaveLength(2); // cheeks
    expect(offspring.svg.querySelectorAll('ellipse:not(.cell-body)')).toHaveLength(0);
  });

  it('draws in its species colors', () => {
    const candi = makeGroup('candi');
    expect(candi.svg.querySelector('.cell-body').getAttribute('fill'))
      .toBe(SPECIES.candi.colors.fill);
  });

  it('has a body of one circle, one cell wide plus its outline, where the group is', () => {
    const group = makeGroup('sasha', { x: 30, y: -40 });
    const [[x, y, r]] = group.body();
    expect(x).toBeCloseTo(30);
    expect(y).toBeCloseTo(-40);
    const OUTLINE = 1.7;
    expect(r).toBeCloseTo((R + OUTLINE / 2) * UNIT);
  });
});

describe('budding with no group nearby', () => {
  it('starts a new offspring group where the player is', () => {
    const player = makeGroup('sasha', { isPlayer: true, x: 20, y: 10 });
    const child = player.divide([], DISH_RADIUS);
    expect(child).not.toBeNull();
    expect(child.isPlayer).toBe(false);
    expect(child.cellCount()).toBe(1);
    expect([child.x, child.y]).toEqual([20, 10]);
  });

  it('sends the new group off with a push', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    const child = player.divide([], DISH_RADIUS);
    expect(Math.hypot(child.vx, child.vy)).toBeCloseTo(GAME.BURST_SPEED * DISH_RADIUS * 0.5);
  });

  it('adds the new group to the dish as a faceless, hidden-from-screen-readers copy', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    const child = player.divide([], DISH_RADIUS);
    expect(child.mover.parentElement).toBe(document.querySelector('.agar'));
    expect(child.mover.classList.contains('offspring')).toBe(true);
    expect(child.svg.getAttribute('aria-hidden')).toBe('true');
    expect(child.svg.querySelectorAll('ellipse:not(.cell-body)')).toHaveLength(0);
  });

  it('leaves the player a single cell', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    player.divide([], DISH_RADIUS);
    expect(player.cellCount()).toBe(1);
  });
});

describe('budding next to a group', () => {
  it('adds the daughter to the group instead of starting a new one', () => {
    const group = makeGroup('sasha', { x: 30 });
    const player = makeGroup('sasha', { isPlayer: true, x: 50 });
    expect(player.divide([group], DISH_RADIUS)).toBeNull();
    expect(group.cellCount()).toBe(2);
  });

  it('slides the new cell from the player into place, touching its neighbor', () => {
    const group = makeGroup('sasha', { x: 0 });
    const player = makeGroup('sasha', { isPlayer: true, x: 50 });
    player.divide([group], DISH_RADIUS);

    // It starts where the player is...
    group.update(0);
    expect(cellCenters(group)[1][0]).toBeCloseTo(50);

    // ...and ends up touching the first cell, on the player's side.
    group.update(GAME.DIVIDE_MS / 1000);
    const [first, second] = cellCenters(group);
    expect(distance(first, second)).toBeCloseTo(SPACING * 0.95 * UNIT); // snug in a cluster
    expect(second[0]).toBeGreaterThan(first[0]);
  });

  it('starts a new group if the nearest one is out of reach', () => {
    const group = makeGroup('sasha', { x: 0 });
    const player = makeGroup('sasha', { isPlayer: true, x: GAME.SNAP_REACH * DISH_RADIUS + 40 });
    expect(player.divide([group], DISH_RADIUS)).not.toBeNull();
    expect(group.cellCount()).toBe(1);
  });

  it('joins whichever group is nearest', () => {
    const near = makeGroup('sasha', { x: 20 });
    const far = makeGroup('sasha', { x: -45 });
    const player = makeGroup('sasha', { isPlayer: true, x: 0 });
    player.divide([far, near], DISH_RADIUS);
    expect(near.cellCount()).toBe(2);
    expect(far.cellCount()).toBe(1);
  });

  it(`stops growing a group at ${GAME.GROUP_CAP} cells`, () => {
    const group = makeGroup('sasha');
    grow(group, GAME.GROUP_CAP);
    const player = makeGroup('sasha', { isPlayer: true, x: 5 });
    expect(group.attachSpot(5, 0, [], DISH_RADIUS)).toBeNull();
    expect(player.divide([group], DISH_RADIUS)).not.toBeNull();
    expect(group.cellCount()).toBe(GAME.GROUP_CAP);
  });

  it('never lets two cells in a grown cluster sit on top of each other', () => {
    const group = makeGroup('sasha');
    grow(group, GAME.GROUP_CAP);
    const centers = cellCenters(group);
    for (let i = 0; i < centers.length; i++) {
      for (let j = i + 1; j < centers.length; j++) {
        expect(distance(centers[i], centers[j])).toBeGreaterThan(R * UNIT);
      }
    }
  });

  it('works out the right spot when the group is flipped to face left', () => {
    const group = makeGroup('sasha', { x: 0 });
    group.facing = -1;
    const spot = group.attachSpot(50, 0, [], DISH_RADIUS);
    expect(spot.world[0]).toBeGreaterThan(0); // still on the player's side
    expect(distance(spot.world, [0, 0])).toBeCloseTo(SPACING * 0.95 * UNIT);
  });
});

describe('sliding a new cell into place', () => {
  // A group that has just had a cell join it from the player 50px away.
  function joining() {
    const group = makeGroup('sasha');
    const player = makeGroup('sasha', { isPlayer: true, x: 50 });
    player.divide([group], DISH_RADIUS);
    const cell = group.cells.find((c) => c.fromX !== c.toX || c.fromY !== c.toY);
    return { group, cell };
  }

  it('glides partway there midway through, fast at first and slowing as it arrives', () => {
    const { group, cell } = joining();
    const half = GAME.DIVIDE_MS / 2000; // half the slide, in seconds
    group.update(half);
    // Halfway through the time it's already 7/8 of the way (an ease-out).
    expect(cell.x).toBeCloseTo(cell.fromX + (cell.toX - cell.fromX) * 0.875);
    expect(cell.y).toBeCloseTo(cell.fromY + (cell.toY - cell.fromY) * 0.875);
    expect(group.moveFor).not.toBeNull(); // still sliding
  });

  it('adds up the time across frames, landing exactly in place and stopping', () => {
    const { group, cell } = joining();
    const frame = GAME.DIVIDE_MS / 1000 / 10;
    for (let i = 0; i < 9; i++) group.update(frame);
    expect(group.moveFor).not.toBeNull();
    group.update(frame * 2); // a slow last frame overshoots the time, not the spot
    expect([cell.x, cell.y]).toEqual([cell.toX, cell.toY]);
    expect(group.moveFor).toBeNull();
  });

  it("stops redrawing once everything is still, since that's slow with many cells", () => {
    const { group } = joining();
    group.update(5); // finish the slide, and the daughter growing
    group.svg.innerHTML = '<g class="marker" />'; // anything a redraw would replace
    group.update(1);
    expect(group.svg.querySelector('.marker')).not.toBeNull();
  });
});

describe('size and position', () => {
  it('reaches one cell\'s radius from its middle when it is a single cell', () => {
    expect(makeGroup('sasha').reach()).toBeCloseTo(R * UNIT);
  });

  it('reaches to the edge of its farthest cell as it grows', () => {
    const group = makeGroup('sasha', { x: 40, y: -10 });
    grow(group, 5);
    const farthest = Math.max(...cellCenters(group).map((c) => distance(c, [40, -10])));
    expect(group.reach()).toBeCloseTo(farthest + R * UNIT);
    expect(group.reach()).toBeGreaterThan(R * UNIT);
  });

  it('is drawn where it is in the dish, flipped to face the way it is going', () => {
    const group = makeGroup('sasha', { x: -25, y: 60 });
    group.facing = -1;
    group.place();
    expect(group.mover.style.transform).toBe('translate(-25px, 60px) scaleX(-1)');
  });
});

describe('an offspring cell budding', () => {
  it('adds the daughter to its own group, next to the cell that divided', () => {
    const group = makeGroup('sasha');
    grow(group, 3);
    const before = cellCenters(group);
    const [cx, cy] = before[2];
    expect(group.divide([group], DISH_RADIUS, [], [cx, cy])).toBeNull();
    expect(group.cellCount()).toBe(4);
    group.update(1);
    const newest = cellCenters(group).find((c) => before.every((b) => distance(b, c) > 0.01));
    expect(distance(newest, [cx, cy])).toBeLessThan(2 * SPACING * UNIT);
  });

  it('starts the daughter sliding in from the cell that divided', () => {
    const group = makeGroup('sasha');
    grow(group, 2);
    const [ex, ey] = group.body()[1];
    group.divide([group], DISH_RADIUS, [], [ex, ey]);
    group.update(0);
    const centers = cellCenters(group);
    // The new cell starts on top of the cell that divided...
    expect(centers.some(([x, y]) => distance([x, y], [ex, ey]) < 0.01 &&
      centers.filter((c) => distance(c, [ex, ey]) < 0.01).length === 2)).toBe(true);
    // ...and ends up next to it.
    group.update(1);
    const newest = cellCenters(group)[2];
    expect(distance(newest, [ex, ey])).toBeLessThan(2 * SPACING * UNIT);
  });

  it('starts a new group at the cell that divided when its own group is full', () => {
    const group = makeGroup('sasha');
    grow(group, GAME.GROUP_CAP);
    const [cx, cy] = group.body()[0];
    const child = group.divide([group], DISH_RADIUS, [], [cx, cy]);
    expect(child).not.toBeNull();
    expect([child.x, child.y]).toEqual([cx, cy]);
    expect(child.isPlayer).toBe(false);
    expect(group.cellCount()).toBe(GAME.GROUP_CAP);
  });
});

describe('antifungal disks', () => {
  // A disk to the right of a cell at the center, as the game stores it
  // (fractions of the dish radius), with a zone of inhibition around it. The
  // usual spot for a new cell on that side is just clear of the disk itself
  // but inside its zone, so the zone is the only thing keeping a cell out.
  const ZONE = 0.045;
  const clearOfDisk = SPACING * UNIT + (GAME.DISK_RADIUS + ZONE / 2) * DISH_RADIUS + CELL_PX / 2;
  const diskRight = { fx: clearOfDisk / DISH_RADIUS, fy: 0, r: GAME.DISK_RADIUS, zone: ZONE };

  it('keeps every cell it does attach clear of the disk and its zone', () => {
    const reach = (diskRight.r + ZONE) * DISH_RADIUS + CELL_PX / 2;
    const diskCenter = [diskRight.fx * DISH_RADIUS, 0];
    for (let angle = 0; angle < 6.28; angle += 0.4) {
      const group = makeGroup('sasha');
      grow(group, 3);
      const spot = group.attachSpot(Math.cos(angle) * 50, Math.sin(angle) * 50, [diskRight], DISH_RADIUS);
      if (spot) expect(distance(spot.world, diskCenter)).toBeGreaterThanOrEqual(reach);
    }
  });

  it('starts a new group instead when the only spots are on a disk', () => {
    const group = makeGroup('sasha');
    const player = makeGroup('sasha', { isPlayer: true, x: 20 });
    const covering = { fx: 0, fy: 0, r: 0.5 };
    expect(group.attachSpot(20, 0, [covering], DISH_RADIUS)).toBeNull();
    expect(player.divide([group], DISH_RADIUS, [covering])).not.toBeNull();
    expect(group.cellCount()).toBe(1);
  });
});

describe('a daughter cell', () => {
  // The size of each cell's oval, as a fraction of a full-grown cell.
  const sizes = (group) => [...group.svg.querySelectorAll('.cell-body')]
    .map((oval) => Number(oval.getAttribute('rx')) / R);
  const smallest = (group) => Math.min(...sizes(group));

  it('starts at a quarter of full size and grows slowly, after she has slid into place', () => {
    const group = makeGroup('sasha');
    const player = makeGroup('sasha', { isPlayer: true, x: 30 });
    player.divide([group], DISH_RADIUS);
    group.update(0);
    expect(smallest(group)).toBeCloseTo(0.25);
    group.update(GAME.DIVIDE_MS / 1000); // the slide is done...
    expect(group.moveFor).toBeNull();
    expect(smallest(group)).toBeLessThan(0.75); // ...but she's still small
    group.update(1.5);
    expect(smallest(group)).toBeCloseTo(1);
  });

  it('starts small even when she starts a new group of her own', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    const child = player.divide([], DISH_RADIUS);
    child.update(0); // the game sizes a new group before it's first drawn
    expect(sizes(child)).toEqual([0.25]);
    child.update(0.75);
    expect(sizes(child)[0]).toBeCloseTo(0.625);
    child.update(5);
    expect(sizes(child)).toEqual([1]);
  });

  it("leaves the cells that are already grown at full size", () => {
    const group = makeGroup('sasha');
    grow(group, 3);
    group.update(5); // let them all grow up
    const player = makeGroup('sasha', { isPlayer: true, x: 30 });
    player.divide([group], DISH_RADIUS);
    group.update(0);
    expect(sizes(group).filter((size) => size === 1)).toHaveLength(3);
  });

  it('is a little oval, a bit wider than it is tall', () => {
    const oval = makeGroup('sasha').svg.querySelector('.cell-body');
    expect(Number(oval.getAttribute('ry'))).toBeLessThan(Number(oval.getAttribute('rx')));
  });
});

describe('a gal who buds from one end (Olive)', () => {
  it('always grows her bud from the top', () => {
    for (let i = 0; i < 5; i++) {
      const player = makeGroup('olive', { isPlayer: true });
      player.startBud();
      expect(player.budding.angle).toBeCloseTo(-Math.PI / 2);
    }
  });

  it('leaves the others budding any which way', () => {
    const angles = new Set();
    for (let i = 0; i < 5; i++) {
      const player = makeGroup('sasha', { isPlayer: true });
      player.startBud();
      angles.add(player.budding.angle);
    }
    expect(angles.size).toBeGreaterThan(1);
  });
});

describe('a yeast who grows in chains (Yara)', () => {
  // Grow an offspring chain by budding from a Yara player beside it.
  function growChain(group, size) {
    const player = makeGroup('yara', { isPlayer: true, x: group.x, y: group.y });
    for (let tries = 0; group.cellCount() < size && tries < 50; tries++) {
      // Swim to the end of the chain, the way a player would, then bud.
      const spot = group.attachSpot(player.x, player.y, [], DISH_RADIUS);
      [player.x, player.y] = spot.world;
      player.divide([group], DISH_RADIUS);
      group.update(2); // finish sliding into place and growing
    }
  }

  it('draws plump, egg-shaped cells, longer than wide, with droplets of fat inside', () => {
    const player = makeGroup('yara', { isPlayer: true });
    const body = player.svg.querySelector('.cell-body');
    expect(body.tagName).toBe('path');
    // Two curved halves and nothing straight: a longer one, then a shorter one.
    const arcs = [...body.getAttribute('d').matchAll(/A (\S+) (\S+) /g)].map(([, rx, ry]) => [Number(rx), Number(ry)]);
    expect(body.getAttribute('d')).not.toMatch(/[LHV]/);
    expect(arcs).toHaveLength(2);
    expect(arcs[0][0]).toBeGreaterThan(arcs[1][0]);
    expect(arcs[0][0] + arcs[1][0]).toBeGreaterThan(arcs[0][1] * 2 * 1.4);
    const oil = [...player.svg.querySelectorAll('circle')].filter((c) => c.getAttribute('fill') === SPECIES.yara.colors.oil);
    expect(oil).toHaveLength(2);
  });

  it('stays level as she swims; only her daughters point every which way', () => {
    const player = makeGroup('yara', { isPlayer: true });
    expect(player.svg.querySelector('.cell-body').getAttribute('transform')).toContain('rotate(0)');
    player.vx = 50;
    player.vy = -80;
    player.place();
    expect(player.svg.querySelector('.cell-body').getAttribute('transform')).toContain('rotate(0)');
  });

  it('buds from one end or the other', () => {
    const angles = new Set();
    for (let i = 0; i < 20; i++) {
      const player = makeGroup('yara', { isPlayer: true });
      player.startBud();
      angles.add(Math.round(Math.cos(player.budding.angle)));
      expect(Math.abs(Math.sin(player.budding.angle))).toBeLessThan(1e-9);
    }
    expect([...angles].sort()).toEqual([-1, 1]);
  });

  it("grows her bud out past her end, as a smaller egg", () => {
    const player = makeGroup('yara', { isPlayer: true });
    player.startBud();
    player.budding.angle = 0;
    player.update(1);
    const bud = player.svg.querySelector('.bud');
    expect(bud.tagName).toBe('path');
    const [, x] = bud.getAttribute('transform').match(/translate\((\S+) /).map(Number);
    expect(x).toBeGreaterThan(R);
    const [bx, by] = player.budSpot();
    expect(by).toBeCloseTo(player.y);
    expect(bx).toBeGreaterThan(player.x);
  });

  it('lines her daughters up end to end in a chain, up to the cap', () => {
    const chain = makeGroup('yara', { x: 30, y: 0 });
    growChain(chain, GAME.CHAIN_CAP);
    expect(GAME.CHAIN_CAP).toBe(4);
    expect(chain.cellCount()).toBe(GAME.CHAIN_CAP);
    const centers = cellCenters(chain);
    const step = ROD_STEP * UNIT;
    for (let i = 1; i < centers.length; i++) expect(distance(centers[i], centers[i - 1])).toBeCloseTo(step, 0);
    // It runs out long, instead of bunching like Sasha's clusters.
    expect(distance(centers[0], centers.at(-1))).toBeGreaterThan(step * 2.5);
    // Full: no room at either end, so the next daughter starts a chain of her own.
    const [end] = centers.slice(-1);
    expect(chain.attachSpot(end[0], end[1], [], DISH_RADIUS)).toBeNull();
    const player = makeGroup('yara', { isPlayer: true, x: end[0], y: end[1] });
    expect(player.divide([chain], DISH_RADIUS)).not.toBeNull();
  });

  it('reaches to the far end of her longest cell', () => {
    const player = makeGroup('yara', { isPlayer: true });
    expect(player.reach()).toBeGreaterThan(R * UNIT * 1.1);
  });
});

describe("the player's bud", () => {
  const bud = (player) => player.svg.querySelector('.bud');
  const budSize = (player) => Number(bud(player).getAttribute('rx')) / R;
  const budCenter = (player) => {
    const [, x, y] = bud(player).getAttribute('transform').match(/translate\((\S+) (\S+)\)/).map(Number);
    return [x, y];
  };

  it("isn't there until she starts one", () => {
    const player = makeGroup('sasha', { isPlayer: true });
    expect(bud(player)).toBeNull();
    expect(player.budReady()).toBe(false);
  });

  it('swells on her side, joined to her at a neck, until it is ready to pinch off', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    player.startBud();
    player.update(0);
    expect(budSize(player)).toBeCloseTo(0.25);
    // Drawn behind her, and overlapping her outline a little.
    expect(player.svg.firstElementChild.classList.contains('bud')).toBe(true);
    const gap = Math.hypot(...budCenter(player));
    expect(gap).toBeGreaterThan(R * 0.8);
    expect(gap).toBeLessThan(R + R * budSize(player));
    expect(player.budReady()).toBe(false);

    player.update(0.35);
    expect(budSize(player)).toBeCloseTo(0.4);
    player.update(0.35);
    expect(budSize(player)).toBeCloseTo(0.55);
    expect(player.budReady()).toBe(true);
    player.update(1);
    expect(budSize(player)).toBeCloseTo(0.55); // it doesn't keep growing on her
  });

  it("keeps the same bud if she's asked to start one again", () => {
    const player = makeGroup('sasha', { isPlayer: true });
    player.startBud();
    const first = player.budding;
    player.update(0.2);
    player.startBud();
    expect(player.budding).toBe(first);
  });

  it("makes room in her drawing for the bud, and doesn't count it as part of her body", () => {
    const player = makeGroup('sasha', { isPlayer: true });
    const width = player.mover.style.width;
    const body = player.body();
    player.startBud();
    player.budding.angle = 0; // pointing right, so she gets wider
    player.update(1);
    expect(parseFloat(player.mover.style.width)).toBeGreaterThan(parseFloat(width));
    expect(player.body()).toHaveLength(1);
    expect(player.body()[0][2]).toBeCloseTo(body[0][2]);
  });

  it('pinches off into a daughter where the bud was, as big as the bud, and leaves her round again', () => {
    const player = makeGroup('sasha', { isPlayer: true, x: 20, y: -10 });
    player.startBud();
    player.update(1);
    const spot = player.budSpot();
    const child = player.divide([], DISH_RADIUS);
    child.update(0);
    expect(bud(player)).toBeNull();
    expect(player.budding).toBeNull();
    expect([child.x, child.y]).toEqual(spot);
    expect(Number(child.svg.querySelector('.cell-body').getAttribute('rx')) / R).toBeCloseTo(0.55);
  });

  it('works out where the bud is when she faces left', () => {
    const player = makeGroup('sasha', { isPlayer: true });
    player.startBud();
    player.budding.angle = 0; // pointing right in her own drawing
    player.update(1);
    expect(player.budSpot()[0]).toBeGreaterThan(0);
    player.facing = -1;
    expect(player.budSpot()[0]).toBeLessThan(0);
  });

  it('sends a daughter that joins a cluster in from the bud, at the bud\'s size', () => {
    const group = makeGroup('sasha', { x: 30 });
    const player = makeGroup('sasha', { isPlayer: true });
    player.startBud();
    player.update(1);
    player.divide([group], DISH_RADIUS);
    group.update(0);
    const sizes = [...group.svg.querySelectorAll('.cell-body')].map((oval) => Number(oval.getAttribute('rx')) / R);
    expect(Math.min(...sizes)).toBeCloseTo(0.55);
  });
});

describe('a yeast with peroxisomes (Peachy)', () => {
  // The sizes of the last cell's peroxisomes: the player's own, drawn after
  // any bud swelling on her side.
  const sizes = (group) => [...[...group.svg.querySelectorAll('.peroxisomes')].at(-1).querySelectorAll('circle')]
    .map((c) => Number(c.getAttribute('r')));

  it('draws pink peroxisomes inside her cells', () => {
    const player = makeGroup('peachy', { isPlayer: true });
    const circles = player.svg.querySelectorAll('.peroxisomes circle');
    expect(circles.length).toBe(2);
    for (const c of circles) expect(c.getAttribute('fill')).toBe(SPECIES.peachy.colors.perox);
  });

  it('keeps them one size as she buds', () => {
    const player = makeGroup('peachy', { isPlayer: true });
    const start = sizes(player);
    for (let i = 0; i < 12; i++) {
      player.budding = null;
      player.startBud();
    }
    player.update(1);
    expect(sizes(player)).toEqual(start);
  });

  it('gives a daughter her own scattered peroxisomes', () => {
    const daughter = makeGroup('peachy');
    expect(sizes(daughter)).toHaveLength(3);
  });

  it("leaves other yeasts' cells without them", () => {
    expect(makeGroup('sasha', { isPlayer: true }).svg.querySelector('.peroxisomes')).toBeNull();
  });
});

describe('a yeast with cigar-shaped cells (Maizey)', () => {
  it('draws long, cigar-shaped cells with rounded tips', () => {
    const player = makeGroup('maizey', { isPlayer: true });
    const body = player.svg.querySelector('.cell-body');
    expect(body.tagName).toBe('path');
    // Curves all the way round, no straight edges.
    expect(body.getAttribute('d')).not.toMatch(/[LHV]/);
    expect(body.getAttribute('d').match(/C/g)).toHaveLength(4);
  });

  it('stays level as she swims', () => {
    const player = makeGroup('maizey', { isPlayer: true });
    player.vx = 60;
    player.vy = 90;
    player.place();
    expect(player.svg.querySelector('.cell-body').getAttribute('transform')).toContain('rotate(0)');
  });

  it('buds from one tip or the other', () => {
    const angles = new Set();
    for (let i = 0; i < 20; i++) {
      const player = makeGroup('maizey', { isPlayer: true });
      player.startBud();
      angles.add(Math.round(Math.cos(player.budding.angle)));
      expect(Math.abs(Math.sin(player.budding.angle))).toBeLessThan(1e-9);
    }
    expect([...angles].sort()).toEqual([-1, 1]);
  });

  it('grows her bud out past her tip, farther than an oval would', () => {
    const maizey = makeGroup('maizey', { isPlayer: true });
    const sasha = makeGroup('sasha', { isPlayer: true });
    for (const player of [maizey, sasha]) {
      player.startBud();
      player.budding.angle = 0;
      player.update(1);
    }
    expect(maizey.budSpot()[0] - maizey.x).toBeGreaterThan(sasha.budSpot()[0] - sasha.x);
  });

  it('clusters her daughters a little farther apart than Sasha\'s', () => {
    const spread = (name) => {
      const group = makeGroup(name, { x: 30, y: 0 });
      const spot = group.attachSpot(130, 0, [], DISH_RADIUS);
      return Math.hypot(spot.x, spot.y);
    };
    expect(spread('maizey')).toBeGreaterThan(spread('sasha') * 1.2);
  });
});

describe('a yeast in a capsule (Neve)', () => {
  it('wraps her round cell in a glossy capsule, drawn behind it', () => {
    const player = makeGroup('neve', { isPlayer: true });
    const capsule = player.svg.querySelector('.capsule');
    const body = player.svg.querySelector('.cell-body');
    expect(capsule).not.toBeNull();
    expect(Number(capsule.getAttribute('r'))).toBeGreaterThan(R * 1.4);
    expect(capsule.getAttribute('stroke')).toBe(SPECIES.neve.colors.capsule);
    // Behind her: it comes first in the drawing.
    expect(capsule.compareDocumentPosition(body) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    // Round, not oval.
    expect(body.getAttribute('rx')).toBe(body.getAttribute('ry'));
  });

  it('gives her swelling bud a capsule too', () => {
    const player = makeGroup('neve', { isPlayer: true });
    player.startBud();
    player.update(1);
    expect(player.svg.querySelectorAll('.capsule')).toHaveLength(2);
  });

  it('clusters her daughters far enough apart for their capsules', () => {
    const spread = (name) => {
      const group = makeGroup(name, { x: 30, y: 0 });
      const spot = group.attachSpot(130, 0, [], DISH_RADIUS);
      return Math.hypot(spot.x, spot.y);
    };
    expect(spread('neve')).toBeGreaterThan(spread('sasha') * 1.3);
  });

  it("leaves other yeasts' cells without one", () => {
    expect(makeGroup('sasha', { isPlayer: true }).svg.querySelector('.capsule')).toBeNull();
  });
});
