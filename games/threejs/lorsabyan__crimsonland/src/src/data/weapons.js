// rate: shots/s. spread: base half-angle, gain: added per shot (recovers over time).
export const WEAPONS = {
  pistol: { name: 'Pistol', tier: 0, cls: 'pistol', rate: 4.6, clip: 12, reload: 1, dmg: 28, spread: 0.02, gain: 0.05, speed: 62, kind: 'bullet', knock: 3, shake: 0.06, snd: 'pistol', col: [1, 0.8, 0.45] },
  rifle: { name: 'Assault Rifle', tier: 1, cls: 'rifle', rate: 9.5, clip: 30, reload: 1.5, dmg: 22, spread: 0.03, gain: 0.02, speed: 70, kind: 'bullet', knock: 2.4, shake: 0.05, snd: 'rifle', col: [1, 0.75, 0.38] },
  smg: { name: 'Submachine Gun', tier: 1, cls: 'pistol', rate: 15, clip: 42, reload: 1.3, dmg: 13, spread: 0.06, gain: 0.018, speed: 62, kind: 'bullet', knock: 1.6, shake: 0.035, snd: 'smg', col: [1, 0.82, 0.5] },
  shotgun: { name: 'Shotgun', tier: 1, cls: 'shotgun', rate: 1.45, clip: 8, reload: 1.9, dmg: 17, pellets: 9, spread: 0.13, gain: 0.04, speed: 56, kind: 'bullet', knock: 3.5, shake: 0.24, snd: 'shotgun', col: [1, 0.68, 0.32], power: 1.5 },
  sawed: { name: 'Sawed-Off', tier: 2, cls: 'shotgun', rate: 2.1, clip: 4, reload: 1.7, dmg: 19, pellets: 14, spread: 0.26, gain: 0.03, speed: 50, kind: 'bullet', knock: 4, shake: 0.32, snd: 'sawed', col: [1, 0.6, 0.28], power: 1.7 },
  minigun: { name: 'Minigun', tier: 3, cls: 'heavy', rate: 26, clip: 150, reload: 3.2, dmg: 14, spread: 0.07, gain: 0.006, speed: 72, kind: 'bullet', knock: 1.8, shake: 0.05, snd: 'minigun', col: [1, 0.72, 0.34], slow: 0.8 },
  gauss: { name: 'Gauss Rifle', tier: 3, cls: 'energy', rate: 1.5, clip: 6, reload: 1.8, dmg: 150, spread: 0.004, gain: 0.03, kind: 'rail', pierce: 40, knock: 5, shake: 0.22, snd: 'gauss', col: [0.45, 0.8, 1], power: 1.4 },
  flamer: { name: 'Flamethrower', tier: 2, cls: 'heavy', rate: 32, clip: 200, reload: 2.5, dmg: 5.5, spread: 0.16, gain: 0, speed: 21, kind: 'flame', life: 0.48, pierce: 5, knock: 0.2, shake: 0.018, snd: 'flame', col: [1, 0.55, 0.2], noShell: true, fire: true },
  plasma: { name: 'Plasma Rifle', tier: 2, cls: 'energy', rate: 6.5, clip: 32, reload: 1.7, dmg: 36, spread: 0.02, gain: 0.015, speed: 42, kind: 'plasma', splash: 1.5, knock: 2.5, shake: 0.08, snd: 'plasma', col: [0.35, 0.72, 1], noShell: true },
  triplasma: { name: 'Tri-Plasma', tier: 3, cls: 'energy', rate: 4.6, clip: 24, reload: 1.8, dmg: 34, pellets: 3, fan: 0.17, spread: 0.01, gain: 0.01, speed: 40, kind: 'plasma', splash: 1.4, knock: 2.5, shake: 0.13, snd: 'plasma', col: [0.45, 0.6, 1], noShell: true },
  plasmacannon: { name: 'Plasma Cannon', tier: 4, cls: 'launcher', rate: 0.9, clip: 4, reload: 2.4, dmg: 240, spread: 0.008, gain: 0.03, speed: 26, kind: 'plasma', big: true, pierce: 24, splash: 4.6, knock: 8, shake: 0.42, snd: 'cannon', col: [0.3, 0.95, 0.7], noShell: true, power: 2 },
  rocket: { name: 'Rocket Launcher', tier: 2, cls: 'launcher', rate: 1.25, clip: 5, reload: 2.1, dmg: 160, spread: 0.012, gain: 0.02, speed: 34, kind: 'rocket', splash: 4.8, knock: 7, shake: 0.2, snd: 'rocket', col: [1, 0.55, 0.22], noShell: true, power: 1.5 },
  swarm: { name: 'Swarm Launcher', tier: 3, cls: 'launcher', rate: 2.2, clip: 12, reload: 2.5, dmg: 70, pellets: 3, fan: 0.42, spread: 0.08, gain: 0.02, speed: 23, kind: 'seeker', splash: 2.5, knock: 3, shake: 0.13, snd: 'rocket', col: [1, 0.6, 0.3], noShell: true },
  ion: { name: 'Ion Rifle', tier: 3, cls: 'energy', rate: 5, clip: 24, reload: 1.8, dmg: 34, spread: 0.012, gain: 0.015, speed: 92, kind: 'ion', chain: 3, knock: 1, shake: 0.08, snd: 'ion', col: [0.68, 0.74, 1], noShell: true },
  ionmini: { name: 'Ion Minigun', tier: 4, cls: 'heavy', rate: 14, clip: 90, reload: 2.8, dmg: 21, spread: 0.05, gain: 0.006, speed: 92, kind: 'ion', chain: 2, knock: 0.8, shake: 0.05, snd: 'ion', col: [0.6, 0.76, 1], noShell: true, slow: 0.85 },
  saw: { name: 'Sawblade Launcher', tier: 2, cls: 'launcher', rate: 2.6, clip: 8, reload: 1.9, dmg: 54, spread: 0.018, gain: 0.02, speed: 30, kind: 'blade', pierce: 11, life: 3.4, knock: 1.5, shake: 0.1, snd: 'blade', col: [0.92, 0.92, 1], noShell: true },
  splitter: { name: 'Splitter Gun', tier: 3, cls: 'rifle', rate: 3.5, clip: 16, reload: 1.6, dmg: 42, spread: 0.016, gain: 0.02, speed: 56, kind: 'split', gen: 3, knock: 2, shake: 0.08, snd: 'rifle', col: [0.75, 1, 0.5] },
  shrinker: { name: 'Shrink Ray', tier: 2, cls: 'energy', rate: 5.5, clip: 28, reload: 1.5, dmg: 13, spread: 0.022, gain: 0.015, speed: 58, kind: 'shrink', knock: 0.6, shake: 0.04, snd: 'shrink', col: [1, 0.4, 0.95], noShell: true },
  pulse: { name: 'Pulse Gun', tier: 2, cls: 'energy', rate: 7.5, clip: 44, reload: 1.5, dmg: 16, spread: 0.1, gain: 0.004, speed: 32, kind: 'pulse', pierce: 4, life: 0.5, knock: 11, shake: 0.06, snd: 'pulse', col: [0.4, 1, 0.88], noShell: true },
  mines: { name: 'Mine Layer', tier: 2, cls: 'launcher', rate: 2.4, clip: 8, reload: 2, dmg: 210, spread: 0, gain: 0, speed: 0, kind: 'mine', splash: 5.2, knock: 8, shake: 0.03, snd: 'click', col: [1, 0.3, 0.2], noShell: true },
};

for (const [id, w] of Object.entries(WEAPONS)) w.id = id;
export const WEAPON_LIST = Object.values(WEAPONS);
