// The campaign is how you earn your arsenal: a new profile starts small, and each mission
// cleared for the first time adds to what can drop and be chosen in every mode.
import { WEAPON_LIST } from './weapons.js';
import { PERKS } from './perks.js';

const START_WEAPONS = ['pistol', 'rifle', 'smg', 'shotgun'];
const START_PERKS = ['deadeye', 'trigger', 'hollow', 'barrel', 'venom', 'mags', 'drums', 'planted', 'frantic', 'boots', 'marathon', 'notes', 'scav', 'longfuse', 'forked', 'thick', 'sidestep', 'iron', 'regen', 'dressing', 'hard', 'dug'];

export const REWARDS = {
  '1-1': { weapon: 'sawed', perks: ['crit'] },
  '1-2': { weapon: 'flamer', perks: ['pyro', 'ricochet'] },
  '1-3': { weapon: 'rocket', perks: ['holster'] },
  '1-4': { weapon: 'plasma', perks: ['nova', 'bayonet'] },
  '1-5': { weapon: 'saw', perks: ['volatile', 'hydra'] },
  '2-1': { weapon: 'mines', perks: ['reach'] },
  '2-2': { weapon: 'pulse', perks: ['plague', 'hotcore'] },
  '2-3': { weapon: 'shrinker', perks: ['adrenal'] },
  '2-4': { weapon: 'minigun', perks: ['ghost', 'cough'] },
  '2-5': { weapon: 'swarm', perks: ['fuse', 'lastword'] },
  '3-1': { weapon: 'ion', perks: ['arc'] },
  '3-2': { weapon: 'splitter', perks: ['gorgon', 'pyrokin'] },
  '3-3': { weapon: 'gauss', perks: ['static'] },
  '3-4': { weapon: 'triplasma', perks: ['bottomless', 'borrowed'] },
  '3-5': { weapon: 'ionmini', perks: ['many', 'contract'] },
  '4-1': { weapon: 'plasmacannon', perks: ['bloodmoney'] },
  '4-2': { perks: ['fifty'] },
  '4-3': { perks: ['roulette'] },
  '4-4': { perks: ['clock'] },
  '4-5': { perks: ['onelife'] },
};

// Which mission grants each item, for the Armory's "locked" notes.
export const SOURCE = {};
for (const [id, r] of Object.entries(REWARDS)) {
  if (r.weapon) SOURCE[r.weapon] = id;
  for (const p of r.perks) SOURCE[p] = id;
}

const ALL = { weapons: new Set(WEAPON_LIST.map((w) => w.id)), perks: new Set(PERKS.map((p) => p.id)) };

export function unlocked(profile) {
  if (!profile || profile.unlockAll) return ALL;
  const weapons = new Set(START_WEAPONS), perks = new Set(START_PERKS);
  for (const id of Object.keys(profile.missions ?? {})) {
    const r = REWARDS[id];
    if (!r) continue;
    if (r.weapon) weapons.add(r.weapon);
    for (const p of r.perks) perks.add(p);
  }
  return { weapons, perks };
}
