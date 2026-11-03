// ai: chase | weave | charge | ranged | burst | brood | nest | boss
export const ENEMIES = {
  shambler: { name: 'Shambler', hp: 42, speed: 2.3, radius: 0.52, dmg: 9, xp: 12, ai: 'chase', scale: 1.32, anim: 1.5, blood: 'red', mass: 1, tints: [[1, 1, 1], [0.86, 1, 0.8], [1, 0.84, 0.74], [0.72, 0.76, 0.84]], gib: 3 },
  skitter: { name: 'Skitter', hp: 14, speed: 5.4, radius: 0.46, dmg: 5, xp: 6, ai: 'weave', scale: 0.95, anim: 3.1, blood: 'acid', mass: 0.5, tints: [[1, 1, 1], [1, 0.82, 0.62], [0.74, 0.9, 0.7]], gib: 1 },
  ripper: { name: 'Ripper', hp: 64, speed: 6.3, radius: 0.58, dmg: 13, xp: 24, ai: 'chase', scale: 1, anim: 1.5, blood: 'ichor', mass: 1.1, tints: [[1, 1, 1], [0.84, 1, 1], [1.2, 0.86, 0.9]], gib: 3 },
  brute: { name: 'Brute', hp: 420, speed: 2.5, radius: 1.05, dmg: 26, xp: 95, ai: 'charge', scale: 1.15, anim: 1.05, blood: 'red', mass: 7, tints: [[1, 1, 1], [0.8, 0.9, 1], [1.1, 0.9, 0.74]], gib: 8 },
  spitter: { name: 'Spitter', hp: 95, speed: 2.5, radius: 0.72, dmg: 12, xp: 38, ai: 'ranged', scale: 0.92, anim: 2.3, blood: 'acid', mass: 2, tints: [[1, 1, 1], [0.8, 1, 0.8]], gib: 4 },
  burster: { name: 'Burster', hp: 30, speed: 6.6, radius: 0.55, dmg: 22, xp: 18, ai: 'burst', scale: 0.9, anim: 2.8, blood: 'dark', mass: 0.8, tints: [[1, 1, 1], [1, 0.85, 0.7]], gib: 2 },
  brood: { name: 'Broodmother', hp: 900, speed: 1.75, radius: 1.6, dmg: 22, xp: 220, ai: 'brood', scale: 1, anim: 1.1, blood: 'acid', mass: 14, tints: [[1, 1, 1]], gib: 12 },
  nest: { name: 'Hive', hp: 800, speed: 0, radius: 1.8, dmg: 0, xp: 260, ai: 'nest', scale: 1.1, anim: 0.9, blood: 'dark', mass: 999, tints: [[1, 1, 1], [0.9, 1, 0.84]], gib: 14 },
  tyrant: { name: 'The Tyrant', hp: 8000, speed: 2.8, radius: 3.0, dmg: 22, xp: 1800, ai: 'boss', scale: 1, anim: 1, blood: 'red', mass: 60, tints: [[1, 1, 1]], gib: 30, boss: true },
};
for (const [id, e] of Object.entries(ENEMIES)) e.id = id;
export const ENEMY_IDS = Object.keys(ENEMIES);
