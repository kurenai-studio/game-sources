import type { Inventory, ItemDefinition, PlayerStats } from '@/game/types';

export const BASE_STATS: PlayerStats = {
  maxHp: 100,
  damage: 18,
  fireInterval: 260,
  shotSpeed: 500,
  moveSpeed: 205,
  range: 410,
  luck: 0,
  projectiles: 1,
  spread: 0,
  pierce: 0,
  homing: 0,
  projectileScale: 1,
};

export const ITEM_DEFINITIONS: readonly ItemDefinition[] = [
  {
    id: 'iron-lament',
    name: 'Iron Lament',
    epithet: 'The wound answers back',
    description: '+5 attack per stack. Your cast grows heavier and larger.',
    color: 0xb4544e,
    glyph: 'I',
    effectSummary: { damage: 5 },
  },
  {
    id: 'quickwick',
    name: 'Quickwick',
    epithet: 'Burn before the dark can blink',
    description: 'Casting interval is 12% shorter per stack.',
    color: 0xe4a766,
    glyph: 'Q',
    effectSummary: { fireRate: 0.12 },
  },
  {
    id: 'longglass',
    name: 'Longglass',
    epithet: 'See the end from here',
    description: '+55 range and +35 projectile speed per stack.',
    color: 0x86b5b7,
    glyph: 'L',
    effectSummary: { range: 55 },
  },
  {
    id: 'mudrunner-soles',
    name: 'Mudrunner Soles',
    epithet: 'The mire cannot keep you',
    description: '+20 movement speed per stack, up to 340.',
    color: 0x89966b,
    glyph: 'M',
    effectSummary: { moveSpeed: 20 },
  },
  {
    id: 'blackwax-knot',
    name: 'Blackwax Knot',
    epithet: 'Resolve takes another shape',
    description: '+20 maximum resolve and heal 20 on pickup.',
    color: 0x7d688d,
    glyph: 'K',
    effectSummary: { maxHp: 20 },
  },
  {
    id: 'twin-rune',
    name: 'Twin Rune',
    epithet: 'One grief becomes three',
    description: 'Cast three, then five, projectiles in a controlled fan.',
    color: 0xd0c28f,
    glyph: 'T',
    effectSummary: { projectiles: 2 },
  },
  {
    id: 'briar-eye',
    name: 'Briar Eye',
    epithet: 'Nothing hides behind another',
    description: '+1 enemy pierced per stack, up to three.',
    color: 0xac6c75,
    glyph: 'B',
    effectSummary: { pierce: 1 },
  },
  {
    id: 'compass-moth',
    name: 'Compass Moth',
    epithet: 'Every flame knows its hunger',
    description: 'Projectiles bend toward nearby enemies.',
    color: 0xa6b98e,
    glyph: 'C',
    effectSummary: { homing: 0.12 },
  },
] as const;

export const ITEM_BY_ID = new Map(ITEM_DEFINITIONS.map((item) => [item.id, item]));

export function deriveStats(inventory: Readonly<Inventory>): PlayerStats {
  const iron = Math.min(inventory['iron-lament'] ?? 0, 8);
  const wick = inventory['quickwick'] ?? 0;
  const glass = inventory['longglass'] ?? 0;
  const soles = inventory['mudrunner-soles'] ?? 0;
  const wax = inventory['blackwax-knot'] ?? 0;
  const rune = inventory['twin-rune'] ?? 0;
  const briar = inventory['briar-eye'] ?? 0;
  const moth = inventory['compass-moth'] ?? 0;

  const projectiles = rune === 0 ? 1 : rune === 1 ? 3 : 5;
  const multiShotMultiplier = rune === 0 ? 1 : rune === 1 ? 0.62 : 0.42 * 1.08 ** Math.max(0, rune - 2);
  return {
    maxHp: BASE_STATS.maxHp + wax * 20,
    damage: Number(((BASE_STATS.damage + iron * 5) * multiShotMultiplier).toFixed(3)),
    fireInterval: Math.max(100, Math.round(BASE_STATS.fireInterval * 0.88 ** wick)),
    shotSpeed: BASE_STATS.shotSpeed + glass * 35,
    moveSpeed: Math.min(340, BASE_STATS.moveSpeed + soles * 20),
    range: BASE_STATS.range + glass * 55,
    luck: Math.min(0.35, (inventory['grave-salt'] ?? 0) * 0.07),
    projectiles,
    spread: projectiles === 1 ? 0 : projectiles === 3 ? 0.2 : 0.31,
    pierce: Math.min(3, briar),
    homing: Math.min(0.36, moth * 0.12),
    projectileScale: 1 + iron * 0.055,
  };
}

export function addItem(inventory: Readonly<Inventory>, itemId: string): Inventory {
  if (!ITEM_BY_ID.has(itemId)) throw new Error(`Unknown item: ${itemId}`);
  return { ...inventory, [itemId]: (inventory[itemId] ?? 0) + 1 };
}
