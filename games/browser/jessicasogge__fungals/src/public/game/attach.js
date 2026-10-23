// Where a new bud attaches to a cluster of yeast cells. Plain math on cell
// positions (in SVG units, relative to the group's origin), with no page
// access, so it can be tested on its own.

export const R = 10; // cell radius in SVG units
export const SPACING = R * 1.75; // center to center, for cells that touch

// A fixed pseudo-random value from -1 to 1, so shapes vary without jitter.
export const wobble = (k, salt) => Math.sin(k * 12.9898 + salt * 78.233);

// Where a new cell would attach to a cluster: an open spot touching the
// cluster, on the side facing (px, py), preferring nooks that touch several
// cells so the cluster fills out into a bunch instead of a line. `twist` is
// the cluster's own packing angle. `allowed(x, y)` can rule spots out (for
// example, spots on an antifungal disk). `scale` spaces the cells farther
// apart, for cells bigger than a plain oval (Maizey's cigars).
export function clusterSpot(cells, twist, px, py, allowed = () => true, scale = 1) {
  const reach = SPACING * 0.95 * scale; // how far a new cell sits from one it touches
  let best = null;

  function consider(x, y) {
    if (!allowed(x, y)) return;
    if (cells.some((o) => Math.hypot(o.x - x, o.y - y) < R * 1.5 * scale)) return;
    const touching = cells.filter((o) => Math.hypot(o.x - x, o.y - y) < SPACING * 1.15 * scale).length;
    const distance = Math.hypot(x - px, y - py);
    const score = distance - touching * SPACING * 1.5 * scale;
    if (!best || score < best.score) best = { x, y, atStart: false, distance, score };
  }

  // Six spots around each cell, each turned a little so clusters look organic.
  cells.forEach((c, i) => {
    for (let k = 0; k < 6; k++) {
      const angle = twist + (k * Math.PI) / 3 + wobble(k, i) * 0.3;
      consider(c.x + Math.cos(angle) * reach, c.y + Math.sin(angle) * reach);
    }
  });

  // The nooks between each pair of neighboring cells: the two spots that
  // touch both. The turned spots above can miss these, and they're what lets
  // a cluster fill in instead of growing arms.
  for (let i = 0; i < cells.length; i++) {
    for (let j = i + 1; j < cells.length; j++) {
      const a = cells[i];
      const b = cells[j];
      const gap = Math.hypot(b.x - a.x, b.y - a.y);
      if (gap === 0 || gap >= 2 * reach) continue;
      const midX = (a.x + b.x) / 2;
      const midY = (a.y + b.y) / 2;
      const rise = Math.sqrt(reach * reach - (gap / 2) ** 2);
      const nx = -(b.y - a.y) / gap;
      const ny = (b.x - a.x) / gap;
      consider(midX + nx * rise, midY + ny * rise);
      consider(midX - nx * rise, midY - ny * rise);
    }
  }

  return best;
}

// Rod-shaped cells (Yara) grow in end-to-end chains.
// ROD_LENGTH/ROD_WIDTH are in SVG units; ROD_STEP spaces chain cells.
export const ROD_LENGTH = R * 2.35;
export const ROD_WIDTH = R * 1.5;
export const ROD_STEP = ROD_LENGTH * 0.92;

// Find a chain-continuation spot past the nearer end of (px, py), with a slight kink.
// Returns { x, y, tilt, atStart }, or null if both ends are blocked or taken.
export function chainSpot(cells, px, py, allowed = () => true) {
  if (cells.length === 0) return null;
  const first = cells[0];
  const last = cells.at(-1);
  const way = (a, b) => Math.atan2(b.y - a.y, b.x - a.x);
  const pointing = ((first.tilt ?? 0) * Math.PI) / 180;
  const ends = cells.length === 1
    ? [[last, pointing, false], [first, pointing + Math.PI, true]]
    : [[last, way(cells.at(-2), last), false], [first, way(cells[1], first), true]];
  let best = null;
  for (const [cell, angle, atStart] of ends) {
    const bent = angle + wobble(cells.length, atStart ? 2 : 1) * 0.3;
    const x = cell.x + Math.cos(bent) * ROD_STEP;
    const y = cell.y + Math.sin(bent) * ROD_STEP;
    if (!allowed(x, y)) continue;
    if (cells.some((o) => Math.hypot(o.x - x, o.y - y) < ROD_STEP * 0.8)) continue;
    const distance = Math.hypot(x - px, y - py);
    if (!best || distance < best.distance) {
      best = { x, y, tilt: Math.round((bent * 180) / Math.PI), atStart, distance };
    }
  }
  return best;
}

// Maizey's cigar-shaped cells: CIGAR_LENGTH tip to tip and CIGAR_WIDTH
// across, in SVG units. They cluster like ovals, spaced CIGAR_SPACING times
// as far apart so they don't pile on top of each other.
export const CIGAR_LENGTH = R * 2.4;
export const CIGAR_WIDTH = R * 1.25;
export const CIGAR_SPACING = 1.35;

// Neve's capsule
export const CAPSULE = 1.5;
export const CAPSULE_SPACING = 1.4;
