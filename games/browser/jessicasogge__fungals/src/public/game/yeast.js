import { touchesDisk } from './antifungal.js';
import {
  CAPSULE, CAPSULE_SPACING, chainSpot, CIGAR_LENGTH, CIGAR_SPACING, CIGAR_WIDTH, clusterSpot, R, ROD_LENGTH,
  ROD_WIDTH,
} from './attach.js';
import { GAME } from './config.js';
import { idlePose, newMover } from './mover.js';
import { coaster } from './physics.js';

// Budding yeast (Sasha, Candi, Olive, Yara, Peachy, Maizey, Neve): the
// player stays one cell.
// Eating grows a bud that pinches off; daughters form clusters up to GROUP_CAP,
// growing toward where the player budded.
//
// `chains` (Yara): egg-shaped cells with fat droplets bud end-to-end into
// chains up to CHAIN_CAP. The player stays level; daughters tilt freely.
//
// `peroxisomes` (Peachy): pink peroxisomes inside her cells.
//
// `cigars` (Maizey): long cigar-shaped cells that bud from their tips and
// cluster like the ovals, a little farther apart. The player stays level.
//
// `capsule` (Neve): round cells, each in a thick, glossy, see-through
// capsule, drawn under all the cells; her clusters are spaced to fit them.
export function yeastGroup({ mover, svg, species, isPlayer }) {
  const CELL_SIZE = 5; // one cell's width, as a percent of the dish
  const OUTLINE = 1.7; // each cell's outline width, in SVG units
  const { colors } = species;
  const rods = Boolean(species.chains);
  const cigars = Boolean(species.cigars);
  const capsule = Boolean(species.capsule);
  const perox = Boolean(species.peroxisomes);
  // A long cell (a rod or a cigar) buds from her ends; her length tip to tip.
  const LONG = rods ? ROD_LENGTH : cigars ? CIGAR_LENGTH : 0;
  // How far a cell reaches from its middle, at most: half a long cell's
  // length, or an oval's radius.
  const CELL_REACH = LONG ? LONG / 2 : capsule ? R * CAPSULE : R;

  const group = {
    mover,
    svg,
    isPlayer,
    x: 0,
    y: 0,
    vx: 0,
    vy: 0,
    facing: 1,
    // Cells in SVG units around the group's origin.
    cells: [{ x: 0, y: 0, fromX: 0, fromY: 0, toX: 0, toY: 0, face: isPlayer }],
    moveFor: null, // ms into sliding a new cell into place, or null
    // The player's bud, while it swells on her side before pinching off:
    // { ms, angle }, how long it's been growing and which way it points.
    budding: null,
    twist: Math.random() * Math.PI * 2, // each cluster packs at its own angle
    cellCount: () => group.cells.length,
  };

  // Yeast cells are a little oval, each tipped its own way.
  const OVAL = capsule ? 1 : 0.86; // height over width (Neve is round)
  // A daughter starts as a bud BUD_START of full size. On the player it
  // swells on her side for BUD_SWELL_MS, to BUD_PINCH of full size, then
  // pinches off. Every daughter then grows to full size at a steady pace,
  // taking GROW_MS from BUD_START to full, so you can watch her grow.
  const BUD_START = 0.25;
  const BUD_PINCH = 0.55;
  const BUD_SWELL_MS = 700;
  const GROW_MS = 1500;

  // How big the player's bud is right now, as a fraction of a full cell.
  function budSize() {
    const t = Math.min(1, group.budding.ms / BUD_SWELL_MS);
    return BUD_START + (BUD_PINCH - BUD_START) * t;
  }

  // Where the player's bud is, in SVG units: just outside her outline in the
  // bud's direction, overlapping it a little so the two look joined at a neck.
  function budCenter() {
    const { angle } = group.budding;
    const r = R * budSize();
    const sin = Math.sin(angle);
    if (LONG) {
      // Out past her end, joined to her where the two rounded tips meet.
      const half = (LONG / 2) * budSize();
      const d = LONG / 2 + half * 0.75;
      return [Math.cos(angle) * d, sin * d, half];
    }
    const edge = R * (1 - (1 - OVAL) * sin * sin); // roughly her oval's edge
    const d = edge + r * 0.55;
    return [Math.cos(angle) * d, sin * d, r];
  }

  // Half the drawing's width and height in SVG units, centered on (0, 0).
  function extent() {
    let mx = 0;
    let my = 0;
    for (const c of group.cells) {
      mx = Math.max(mx, Math.abs(c.x) + CELL_REACH);
      my = Math.max(my, Math.abs(c.y) + CELL_REACH);
    }
    if (group.budding) {
      const [bx, by, br] = budCenter();
      const reach = capsule ? br * CAPSULE : br;
      mx = Math.max(mx, Math.abs(bx) + reach);
      my = Math.max(my, Math.abs(by) + reach);
    }
    return [mx + 2, my + 2];
  }

  const pxPerUnit = () => mover.offsetWidth / (2 * extent()[0]);

  // Convert between dish pixels (from the dish center) and this group's units.
  function toLocal(wx, wy) {
    const unit = pxPerUnit();
    return [((wx - group.x) / unit) * group.facing, (wy - group.y) / unit];
  }
  function toWorld(lx, ly) {
    const unit = pxPerUnit();
    return [group.x + lx * unit * group.facing, group.y + ly * unit];
  }

  // A plump egg `l` long and `w` wide, centered on (0, 0) and lying along x:
  // two half-ovals joined at her widest point, the right one a little longer,
  // so her sides curve all the way round with no straight edges.
  function eggPath(l, w) {
    const [right, left, h] = [l * 0.54, l * 0.46, w / 2];
    const x = (left - right) / 2;
    return `M ${x} ${-h} A ${right} ${h} 0 0 1 ${x} ${h} A ${left} ${h} 0 0 1 ${x} ${-h} Z`;
  }

  // A cigar `l` long and `w` wide, centered on (0, 0) and lying along x,
  // with rounded tips.
  function cigarPath(l, w) {
    const [h, k] = [l / 2, w / 2];
    return `M ${-h} 0 C ${-h} ${-k * 0.58} ${-h * 0.57} ${-k} 0 ${-k} C ${h * 0.57} ${-k} ${h} ${-k * 0.58} ${h} 0 ` +
      `C ${h} ${k * 0.58} ${h * 0.57} ${k} 0 ${k} C ${-h * 0.57} ${k} ${-h} ${k * 0.58} ${-h} 0 Z`;
  }

  function cellBody(c) {
    const paint = `fill="${colors.fill}" stroke="${colors.stroke}" stroke-width="${OUTLINE}"`;
    const size = c.grow ?? 1;
    if (LONG) {
      const d = rods
        ? eggPath(ROD_LENGTH * size, ROD_WIDTH * size)
        : cigarPath(CIGAR_LENGTH * size, CIGAR_WIDTH * size);
      return `<path class="${c.bud ? 'bud' : 'cell-body'}" d="${d}" ` +
        `transform="translate(${c.x} ${c.y}) rotate(${c.tilt ?? 0})" ${paint} />`;
    }
    return `<ellipse class="${c.bud ? 'bud' : 'cell-body'}" cx="0" cy="0" rx="${R * size}" ry="${R * OVAL * size}" ` +
      `transform="translate(${c.x} ${c.y}) rotate(${c.tilt ?? 0})" ${paint} />`;
  }

  // A rod's droplets of fat, inside it and turned with it.
  function droplets(c) {
    const [l, w] = [ROD_LENGTH * (c.grow ?? 1), ROD_WIDTH * (c.grow ?? 1)];
    const paint = `fill="${colors.oil}" stroke="${colors.stroke}" stroke-opacity="0.45" stroke-width="0.6"`;
    return `<g transform="translate(${c.x} ${c.y}) rotate(${c.tilt ?? 0})">` +
      `<circle cx="${-l * 0.24}" cy="${w * 0.12}" r="${w * 0.17}" ${paint} />` +
      `<circle cx="${l * 0.27}" cy="${-w * 0.1}" r="${w * 0.13}" ${paint} /></g>`;
  }

  // Peachy's peroxisomes, turned with her cell. The player's sit low, under
  // her face; a daughter's are scattered.
  function peroxisomes(c) {
    const size = c.grow ?? 1;
    const spots = c.face
      ? [[-4.2, 6, 1.3], [4.2, 6, 1.3]]
      : [[-4.5, 2.8, 1.7], [3.8, 4.2, 1.4], [4.6, -2.2, 1.2]];
    const paint = `fill="${colors.perox}" stroke="${colors.stroke}" stroke-opacity="0.5" stroke-width="0.5"`;
    return `<g class="peroxisomes" transform="translate(${c.x} ${c.y}) rotate(${c.tilt ?? 0})">` +
      spots.map(([x, y, r]) => `<circle cx="${x * size}" cy="${y * size}" r="${r * size}" ${paint} />`).join('') +
      '</g>';
  }

  // The glint on a cell. A cigar's is a long streak out toward her tip,
  // turned with her, so it stays clear of her face.
  function shine(c) {
    const size = c.grow ?? 1;
    if (cigars) {
      return `<ellipse cx="${-CIGAR_LENGTH * 0.27 * size}" cy="${-CIGAR_WIDTH * 0.24 * size}" ` +
        `rx="${2.6 * size}" ry="${1 * size}" fill="${colors.highlight}" ` +
        `transform="translate(${c.x} ${c.y}) rotate(${c.tilt ?? 0})" />`;
    }
    return `<circle cx="${c.x - 2.7}" cy="${c.y - 3.2}" r="${1.5 * size}" fill="${colors.highlight}" />`;
  }

  function cellMarkup(c) {
    let out = cellBody(c) + (rods ? droplets(c) : shine(c));
    if (perox) out += peroxisomes(c);
    if (c.face) {
      out +=
        // A cigar is slimmer than an oval, so her face is a little smaller
        // and sits a touch higher, to keep her cheeks inside her outline.
        `<g transform="translate(${c.x} ${c.y})${cigars ? ' translate(0 -0.6) scale(0.82)' : ''}">` +
        `<circle cx="-3.6" cy="0" r="2" fill="${colors.dark}" />` +
        `<circle cx="3.6" cy="0" r="2" fill="${colors.dark}" />` +
        '<circle cx="-3" cy="-0.6" r="0.75" fill="white" />' +
        '<circle cx="4.2" cy="-0.6" r="0.75" fill="white" />' +
        '<ellipse cx="-6.3" cy="3.8" rx="1.8" ry="1.2" fill="#f9a8d4" opacity="0.9" />' +
        '<ellipse cx="6.3" cy="3.8" rx="1.8" ry="1.2" fill="#f9a8d4" opacity="0.9" />' +
        `<path d="M-2 3.8 Q0 6 2 3.8" stroke="${colors.dark}" stroke-width="1.2" fill="none" stroke-linecap="round" />` +
        '</g>';
    }
    return out;
  }

  // The player's swelling bud, drawn behind her so her outline crosses it,
  // like the gals' pictures.
  function budMarkup() {
    if (!group.budding) return '';
    const [bx, by] = budCenter();
    return cellMarkup({ x: bx, y: by, grow: budSize(), tilt: 0, bud: true });
  }

  // Neve's capsule around a cell: see-through, faintly tinted, with a soft
  // rim and a curved white shine, like Pearl's in PetriPals.
  function capsuleMarkup(c) {
    const r = R * CAPSULE * (c.grow ?? 1);
    const [a1, a2] = [Math.PI * 1.08, Math.PI * 1.42];
    const [sx, sy, ex, ey] = [Math.cos(a1), Math.sin(a1), Math.cos(a2), Math.sin(a2)]
      .map((v) => v * r * 0.8);
    return `<circle class="capsule" cx="${c.x}" cy="${c.y}" r="${r}" fill="${colors.capsuleFill}" fill-opacity="0.7" ` +
      `stroke="${colors.capsule}" stroke-width="1.5" />` +
      `<path d="M ${c.x + sx} ${c.y + sy} A ${r * 0.8} ${r * 0.8} 0 0 1 ${c.x + ex} ${c.y + ey}" ` +
      'stroke="#ffffff" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.95" />';
  }

  function draw() {
    const [mx, my] = extent();
    svg.setAttribute('viewBox', `${-mx} ${-my} ${2 * mx} ${2 * my}`);
    mover.style.width = `${(mx / R) * CELL_SIZE}%`;
    // Cells higher up sit behind lower ones.
    const order = [...group.cells].sort((a, b) => a.y - b.y);
    let capsules = '';
    if (capsule) {
      // Under everything, so every cell sits inside its own glossy coat.
      const bud = group.budding ? budCenter() : null;
      capsules = (bud ? capsuleMarkup({ x: bud[0], y: bud[1], grow: budSize() }) : '') +
        order.map(capsuleMarkup).join('');
    }
    svg.innerHTML = capsules + budMarkup() + order.map(cellMarkup).join('');
  }

  Object.assign(group, {
    reach() {
      let farthest = 0;
      for (const c of group.cells) farthest = Math.max(farthest, Math.hypot(c.x, c.y) + CELL_REACH);
      return farthest * pxPerUnit();
    },
    // Redraw only while something is changing (a new cell sliding into
    // place, a daughter growing, the player's bud swelling); a still group
    // looks the same every frame, and with hundreds of cells redrawing them
    // all slows the game down.
    update(seconds) {
      const ms = seconds * 1000;
      let changed = false;
      if (group.moveFor !== null) {
        group.moveFor += ms;
        const t = Math.min(1, group.moveFor / GAME.DIVIDE_MS);
        const ease = 1 - (1 - t) ** 3;
        for (const c of group.cells) {
          // At the end, land exactly on the spot (the sum can be a hair off).
          c.x = t >= 1 ? c.toX : c.fromX + (c.toX - c.fromX) * ease;
          c.y = t >= 1 ? c.toY : c.fromY + (c.toY - c.fromY) * ease;
        }
        if (t >= 1) group.moveFor = null;
        changed = true;
      }
      for (const c of group.cells) {
        if (c.grow === undefined || c.grow >= 1) continue;
        c.grow = Math.min(1, c.grow + (ms / GROW_MS) * (1 - BUD_START));
        changed = true;
      }
      if (group.budding) {
        group.budding.ms += ms;
        changed = true;
      }
      if (changed) draw();
    },
    // Start a bud swelling on the player's side (if one isn't already
    // growing): from the top for a gal who always buds from the same end
    // (Olive), from one end or the other for a long cell (Yara, Maizey), or
    // else pointing a random way.
    startBud() {
      let angle = Math.random() * Math.PI * 2;
      if (species.budsFromOneEnd) angle = -Math.PI / 2;
      else if (LONG) angle = Math.random() < 0.5 ? 0 : Math.PI;
      group.budding ??= { ms: 0, angle };
    },
    // Whether her bud has swelled enough to pinch off.
    budReady() {
      return group.budding !== null && group.budding.ms >= BUD_SWELL_MS;
    },
    // Where her bud is in the dish, for the daughter to start from.
    budSpot() {
      const [bx, by] = budCenter();
      return toWorld(bx, by);
    },
    // Remove the cells at these places in the list (the same order as body()),
    // when they pop. The others stay exactly where they are.
    removeCells(indexes) {
      const gone = new Set(indexes);
      group.cells = group.cells.filter((_, i) => !gone.has(i));
      draw();
    },
    place() {
      mover.style.transform = `translate(${group.x}px, ${group.y}px) scaleX(${group.facing})`;
    },
    // Every cell's circle, used to tell whether the group touches a nutrient
    // or an antifungal disk.
    // Each circle includes the cell's outline. The player's follows its idle
    // animation, so touches match the screen.
    body() {
      const unit = pxPerUnit();
      const pose = isPlayer ? idlePose(svg) : (x, y, r) => [x, y, r];
      return group.cells.map((c) => {
        const [x, y, r] = pose(c.x * unit, c.y * unit, (R + OUTLINE / 2) * unit);
        return [group.x + x * group.facing, group.y + y, r];
      });
    },
    // Where a new cell would join this group if it came from (wx, wy) in the
    // dish, or null if the group is full or every open spot is on a disk.
    attachSpot(wx, wy, disks = [], dishRadius = 0) {
      if (group.cells.length >= (rods ? GAME.CHAIN_CAP : GAME.GROUP_CAP)) return null;
      const [px, py] = toLocal(wx, wy);
      // Spots on or right next to an antifungal disk are off-limits. Measure
      // each cell the same way body() does (with its outline), or a new cell
      // can land a hair inside the clear space and get shoved right away.
      const cellRadius = (R + OUTLINE / 2) * pxPerUnit();
      const allowed = (x, y) => {
        const [sx, sy] = toWorld(x, y);
        return !disks.some((disk) =>
          touchesDisk(disk, [[sx, sy, cellRadius]], dishRadius));
      };
      // Maizey's cigars and Neve's capsules need a little more room.
      const spacing = cigars ? CIGAR_SPACING : capsule ? CAPSULE_SPACING : 1;
      const spot = rods
        ? chainSpot(group.cells, px, py, allowed)
        : clusterSpot(group.cells, group.twist, px, py, allowed, spacing);
      if (!spot) return null;
      spot.world = toWorld(spot.x, spot.y);
      return spot;
    },
    // Slide a new cell from (wx, wy) in the dish into `spot`, starting at
    // `grow` of full size.
    addCell(spot, wx, wy, grow = BUD_START) {
      const [fx, fy] = toLocal(wx, wy);
      for (const c of group.cells) {
        c.fromX = c.toX = c.x;
        c.fromY = c.toY = c.y;
      }
      const cell = {
        x: fx, y: fy, fromX: fx, fromY: fy, toX: spot.x, toY: spot.y, face: false,
        grow, tilt: spot.tilt ?? Math.round(Math.random() * 180),
      };
      if (spot.atStart) group.cells.unshift(cell);
      else group.cells.push(cell);
      group.moveFor = 0;
    },
    // A cell buds: the daughter joins the nearest cluster that
    // has room and is close enough (and not onto an antifungal disk), or else
    // starts a new one. `from` is where she starts in the dish: the player's
    // bud, if one has swelled on her side, or else the cell in an offspring
    // group that ate a nutrient. She starts as small as the bud was.
    // Returns the new group, or null if the daughter joined one.
    divide(others, dishRadius, disks = [], from = group.budding ? group.budSpot() : [group.x, group.y]) {
      const [fx, fy] = from;
      const grow = group.budding ? budSize() : BUD_START;
      if (group.budding) {
        // Pinched off: the bud is the daughter now.
        group.budding = null;
        draw();
      }
      let best = null;
      for (const other of others) {
        const spot = other.attachSpot?.(fx, fy, disks, dishRadius);
        if (!spot) continue;
        const distance = Math.hypot(spot.world[0] - fx, spot.world[1] - fy);
        if (distance > GAME.SNAP_REACH * dishRadius) continue;
        if (!best || distance < best.distance) best = { other, spot, distance };
      }
      if (best) {
        best.other.addCell(best.spot, fx, fy, grow);
        return null;
      }
      const copy = svg.cloneNode(false);
      const child = yeastGroup({ mover: newMover(copy), svg: copy, species, isPlayer: false });
      child.x = fx;
      child.y = fy;
      // She starts small and grows, like a daughter joining a cluster.
      Object.assign(child.cells[0], { grow, tilt: Math.round(Math.random() * 180) });
      const angle = Math.random() * Math.PI * 2;
      const burst = GAME.BURST_SPEED * dishRadius * 0.5;
      child.vx = Math.cos(angle) * burst;
      child.vy = Math.sin(angle) * burst;
      return child;
    },
  });

  group.coast = coaster(group);
  draw();
  return group;
}
