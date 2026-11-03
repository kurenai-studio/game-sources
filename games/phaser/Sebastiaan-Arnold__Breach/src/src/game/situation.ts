import type { CivilianSlot, HostileSlot, MissionDef } from '../levels/types';

/** What is actually inside, rolled from the intel each time the operator deploys. */
export interface Situation {
  hostiles: HostileSlot[];
  civilians: CivilianSlot[];
  /** "Last known position" marks for the briefing map. */
  suspectMarks: { tx: number; ty: number }[];
}

/**
 * The briefing is mostly right, never fully right. The real hostile count falls inside the
 * stated range; on unverified intel there's a chance of one more than stated. Marks on the map
 * point at real positions, except on unverified intel where one may point at an empty room.
 */
export function rollSituation(m: MissionDef, rng: () => number = Math.random): Situation {
  const between = (a: number, b: number) => a + Math.floor(rng() * (b - a + 1));
  let count = between(m.hostiles.min, m.hostiles.max);
  if (m.reliability === 'Unverified' && rng() < 0.35) count++;
  count = Math.min(count, m.hostileSlots.length);

  // Always include a patroller when the level has one: the moving threat you can hear.
  const pool = shuffle([...m.hostileSlots], rng);
  const patroller = pool.findIndex((s) => s.type === 'patroller');
  if (patroller > 0) pool.unshift(pool.splice(patroller, 1)[0]);
  pool.sort((a, b) => Number(!!b.always) - Number(!!a.always));
  const hostiles = pool.slice(0, count);

  const civilians = shuffle([...m.civilianSlots], rng).slice(0, Math.min(between(m.civilians.min, m.civilians.max), m.civilianSlots.length));

  const stationary = hostiles.filter((h) => h.type === 'lookout');
  const suspectMarks = stationary.slice(0, 2).map((h) => ({ tx: h.tx, ty: h.ty }));
  if (m.reliability === 'Unverified' && suspectMarks.length && rng() < 0.5) {
    const decoy = m.hostileSlots.find((s) => !hostiles.includes(s));
    if (decoy) suspectMarks[suspectMarks.length - 1] = { tx: decoy.tx, ty: decoy.ty };
  }
  return { hostiles, civilians, suspectMarks };
}

function shuffle<T>(a: T[], rng: () => number): T[] {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
