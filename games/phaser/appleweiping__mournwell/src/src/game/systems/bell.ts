// The toll bell: pay resolve (health) to ring it, and every enemy in the
// chamber takes a heavy hit, flinches, and loses its shots in flight.
// Pure rules so they can be unit-tested without Phaser.

export const BELL = {
  cost: 15,
  damage: 45,
  cooldownMs: 8_000,
  staggerMs: 700,
} as const;

export type BellBlock = 'cooldown' | 'resolve';

export interface BellStatus {
  ready: boolean;
  readyInMs: number;
  blockedBy: BellBlock | null;
}

/** Whether the bell can be rung right now, and if not, why. */
export function bellStatus(hp: number, now: number, readyAt: number): BellStatus {
  const readyInMs = Math.max(0, Math.ceil(readyAt - now));
  // Ringing must never kill you: you need strictly more resolve than it costs.
  const blockedBy: BellBlock | null = readyInMs > 0 ? 'cooldown' : hp <= BELL.cost ? 'resolve' : null;
  return { ready: blockedBy === null, readyInMs, blockedBy };
}

export type TollResult =
  | { rung: false; blockedBy: BellBlock }
  | { rung: true; hp: number; readyAt: number; damage: number; staggerUntil: number };

/** Ring the bell: returns the new resolve and cooldown, or why it stayed silent. */
export function tollBell(hp: number, now: number, readyAt: number): TollResult {
  const status = bellStatus(hp, now, readyAt);
  if (status.blockedBy) return { rung: false, blockedBy: status.blockedBy };
  return {
    rung: true,
    hp: hp - BELL.cost,
    readyAt: now + BELL.cooldownMs,
    damage: BELL.damage,
    staggerUntil: now + BELL.staggerMs,
  };
}
