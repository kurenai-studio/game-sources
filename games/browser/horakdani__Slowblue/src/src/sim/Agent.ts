export const MAIN_FACTION = 0;

/**
 * How many kinds of fish exist. 0 is the shoal you start the run with; the rest
 * belong to rescue pods.
 *
 * Slowblue: species is a *render* property that the simulation carries, and it exists
 * for one reason - a rescued pod keeps its own shape and tint after it merges. The
 * shoal you finish with should visibly be the one you assembled, not a hundred
 * copies of what you started with, and "that school of long thin ones came from the
 * ring I held at the second rock" is a memory the game gets for one integer.
 */
export const SPECIES_COUNT = 6;

/** Which kind of fish a given pod is made of. Deterministic, so replays match. */
export function podSpecies(podId: number): number {
  return 1 + ((podId - 1) % (SPECIES_COUNT - 1));
}

export interface Agent {
  x: number;
  y: number;
  vx: number;
  vy: number;
  /** Previous-step position, used only for render interpolation. */
  px: number;
  py: number;
  /** 0 = player's shoal. >0 = an un-rescued pod, keyed by pod id. */
  faction: number;
  alive: boolean;
  /** Per-individual multiplier (~0.9..1.1) so the shoal never looks cloned. */
  variation: number;
  /** Phase offset for the organic wander term, and for the tail beat. */
  phase: number;
  /** Which kind of fish this is. Survives a merge into the main shoal. */
  species: number;
  /** Station-keeping target for un-rescued pods. */
  anchorX: number;
  anchorY: number;
  /** Radius of the ring that contains this fish until it is rescued. */
  anchorRadius: number;
  anchored: boolean;
  /** Seconds since spawn - drives the fade-in of freshly joined agents. */
  age: number;
}

export function createAgent(): Agent {
  return {
    x: 0,
    y: 0,
    vx: 0,
    vy: 0,
    px: 0,
    py: 0,
    faction: MAIN_FACTION,
    alive: false,
    variation: 1,
    phase: 0,
    species: 0,
    anchorX: 0,
    anchorY: 0,
    anchorRadius: 0,
    anchored: false,
    age: 0,
  };
}
