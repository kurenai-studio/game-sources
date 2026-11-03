// Level-up perks. Stat perks change `mods`; behaviours are read from `mods` flags at their call sites.
const stat = (fn) => (g) => fn(g.player.mods, g.player, g);

export const PERKS = [
  // Offence
  { id: 'deadeye', name: 'Dead Eye', tag: 'attack', desc: 'Spread halved, damage +10%.', apply: stat((m) => { m.spread *= 0.5; m.damage *= 1.1; }) },
  { id: 'trigger', name: 'Hair Trigger', tag: 'attack', desc: 'Fire rate +15%.', max: 3, apply: stat((m) => { m.fireRate *= 1.15; }) },
  { id: 'hollow', name: 'Hollow Points', tag: 'attack', desc: 'Damage +20%.', max: 3, apply: stat((m) => { m.damage *= 1.2; }) },
  { id: 'crit', name: 'Depleted Core', tag: 'attack', desc: '15% of hits deal triple damage.', apply: stat((m) => { m.crit = 0.15; }) },
  { id: 'venom', name: 'Venom Tips', tag: 'attack', desc: 'Shots poison whatever they touch.', apply: stat((m) => { m.poison = true; }) },
  { id: 'barrel', name: 'Long Barrel', tag: 'attack', desc: 'Bullet speed +30%, damage +8%.', apply: stat((m) => { m.bulletSpeed *= 1.3; m.damage *= 1.08; }) },
  { id: 'pyro', name: 'Pyromaniac', tag: 'attack', desc: 'Fire deals +75% damage and burns longer.', apply: stat((m) => { m.fire *= 1.75; }) },
  { id: 'arc', name: 'Arc Tuner', tag: 'attack', desc: 'Ion weapons jump 2 more targets, +25% damage.', apply: stat((m) => { m.chain += 2; m.ion *= 1.25; }) },
  { id: 'ricochet', name: 'Ricochet', tag: 'attack', desc: 'Bullets bounce to one more target.', apply: stat((m) => { m.bounce = 1; }) },
  { id: 'volatile', name: 'Volatile Flesh', tag: 'attack', desc: '15% of kills detonate the corpse.', apply: stat((m) => { m.volatile = 0.15; }) },
  { id: 'gorgon', name: 'Gorgon Stare', tag: 'attack', desc: 'Whatever is under your crosshair cannot move.', apply: stat((m) => { m.gorgon = true; }) },
  { id: 'pyrokin', name: 'Pyrokinetic', tag: 'attack', desc: 'Whatever is under your crosshair catches fire.', apply: stat((m) => { m.pyrokin = true; }) },
  { id: 'cough', name: 'Dragon Cough', tag: 'attack', desc: 'Every 3 seconds you spit a fireball at your aim.', apply: stat((m) => { m.cough = true; }) },
  { id: 'fuse', name: 'Short Fuse', tag: 'attack', desc: 'Every 8 seconds a ring of plasma bursts from you.', apply: stat((m) => { m.fuse = true; }) },
  // Reloading and handling
  { id: 'mags', name: 'Quick Mags', tag: 'handling', desc: 'Reload 35% faster.', max: 2, apply: stat((m) => { m.reload *= 0.65; }) },
  { id: 'drums', name: 'Drum Mags', tag: 'handling', desc: 'Clip size +50%.', max: 2, apply: stat((m, p) => { m.clip *= 1.5; p.refill(); }) },
  { id: 'holster', name: 'Second Holster', tag: 'handling', desc: 'Carry a second weapon. Swap with Q or right mouse.', apply: stat((m) => { m.holster = true; }) },
  { id: 'planted', name: 'Planted Feet', tag: 'handling', desc: 'Reload three times faster while standing still.', apply: stat((m) => { m.plantedReload = true; }) },
  { id: 'frantic', name: 'Frantic Hands', tag: 'handling', desc: 'Pulling the trigger speeds up a reload.', apply: stat((m) => { m.frantic = true; }) },
  { id: 'nova', name: 'Reload Nova', tag: 'handling', desc: 'Finishing a reload fires a ring of bullets.', apply: stat((m) => { m.nova = true; }) },
  { id: 'bottomless', name: 'Blood Rounds', tag: 'handling', desc: 'Keep firing during a reload. Each shot costs health.', apply: stat((m) => { m.bloodRounds = true; }) },
  { id: 'borrowed', name: 'Borrowed Rounds', tag: 'handling', desc: 'Keep firing during a reload. Each shot costs score.', apply: stat((m) => { m.xpRounds = true; }) },
  // Mobility and economy
  { id: 'boots', name: 'Light Boots', tag: 'utility', desc: 'Move 15% faster.', max: 2, apply: stat((m) => { m.speed *= 1.15; }) },
  { id: 'marathon', name: 'Marathon', tag: 'utility', desc: 'You pick up speed the longer you keep running.', apply: stat((m) => { m.marathon = true; }) },
  { id: 'notes', name: 'Field Notes', tag: 'utility', desc: 'Earn 25% more experience.', max: 2, apply: stat((m) => { m.xp *= 1.25; }) },
  { id: 'scav', name: 'Scavenger', tag: 'utility', desc: 'Drops are 60% more common and pull towards you.', apply: stat((m) => { m.drops *= 1.6; m.magnet = 6; }) },
  { id: 'longfuse', name: 'Long Fuse', tag: 'utility', desc: 'Timed bonuses last 60% longer.', apply: stat((m) => { m.bonusTime *= 1.6; }) },
  { id: 'reach', name: 'Long Reach', tag: 'utility', desc: 'Collect drops by pointing your crosshair at them.', apply: stat((m) => { m.reach = true; }) },
  { id: 'adrenal', name: 'Adrenal Gland', tag: 'utility', desc: 'The world moves 12% slower.', apply: stat((m) => { m.timeScale *= 0.88; }) },
  { id: 'forked', name: 'Forked Path', tag: 'utility', desc: 'See 5 perks at every level.', apply: stat((m) => { m.perkChoices = 5; }) },
  { id: 'many', name: 'Many Paths', tag: 'utility', desc: 'See 6 perks at every level.', req: 'forked', apply: stat((m) => { m.perkChoices = 6; }) },
  // Defence
  { id: 'thick', name: 'Thick Skin', tag: 'defence', desc: 'Take 30% less damage, but lose 15% max health.', apply: stat((m, p) => { m.armor *= 0.7; p.setMaxHp(p.maxHp * 0.85); }) },
  { id: 'sidestep', name: 'Sidestep', tag: 'defence', desc: '20% chance to dodge a hit.', apply: stat((m) => { m.dodge = Math.max(m.dodge, 0.2); }) },
  { id: 'ghost', name: 'Ghost Step', tag: 'defence', desc: '40% chance to dodge a hit.', req: 'sidestep', apply: stat((m) => { m.dodge = 0.4; }) },
  { id: 'iron', name: 'Iron Gut', tag: 'defence', desc: 'Hits no longer slow you down.', apply: stat((m) => { m.unstoppable = true; }) },
  { id: 'regen', name: 'Regrowth', tag: 'defence', desc: 'Recover 1.2 health per second.', apply: stat((m) => { m.regen += 1.2; }) },
  { id: 'hydra', name: 'Hydra Blood', tag: 'defence', desc: 'Recover 3 more health per second.', req: 'regen', apply: stat((m) => { m.regen += 3; }) },
  { id: 'dressing', name: 'Field Dressing', tag: 'defence', desc: 'Recover 50 health right now.', max: 9, apply: stat((m, p) => p.heal(50)) },
  { id: 'hard', name: 'Hard to Kill', tag: 'defence', desc: 'Max health +30.', max: 3, apply: stat((m, p) => { p.setMaxHp(p.maxHp + 30); p.heal(30); }) },
  { id: 'bayonet', name: 'Bayonet', tag: 'defence', desc: 'Anything touching you takes heavy damage.', apply: stat((m) => { m.melee = true; }) },
  { id: 'hotcore', name: 'Hot Core', tag: 'defence', desc: 'A radiation aura burns everything near you.', apply: stat((m) => { m.aura = 1; }) },
  { id: 'plague', name: 'Plague Carrier', tag: 'defence', desc: 'Enemies that touch you rot, and spread it.', apply: stat((m) => { m.plague = true; }) },
  { id: 'lastword', name: 'Last Word', tag: 'defence', desc: 'When you die, you take the whole screen with you.', apply: stat((m) => { m.lastWord = true; }) },
  { id: 'dug', name: 'Dug In', tag: 'defence', desc: 'Stand still for a second: damage +60%.', apply: stat((m) => { m.dugIn = true; }) },
  { id: 'static', name: 'Static Charge', tag: 'defence', desc: 'Stand still to charge a burst of ion bolts.', apply: stat((m) => { m.staticCharge = true; }) },
  // Gambles
  { id: 'contract', name: 'Devil\'s Contract', tag: 'gamble', desc: 'Gain 3 levels. Your health drops to 10.', apply: (g) => { g.player.hp = Math.min(g.player.hp, 10); g.addLevels(3); } },
  { id: 'bloodmoney', name: 'Blood Money', tag: 'gamble', desc: 'Gain 5000 score. Lose half your max health.', apply: (g) => { g.addScore(5000); g.player.setMaxHp(g.player.maxHp * 0.5); } },
  { id: 'fifty', name: 'Fifty-Fifty', tag: 'gamble', desc: 'Half of everything alive dies right now.', apply: (g) => g.fiftyFifty() },
  { id: 'roulette', name: 'Roulette', tag: 'gamble', desc: '5 in 6: gain 8000 score. 1 in 6: you die.', apply: (g) => { if (Math.random() < 1 / 6) g.player.kill(); else g.addScore(8000); } },
  { id: 'clock', name: 'Borrowed Time', tag: 'gamble', desc: 'Invulnerable for 30 seconds. Then you die.', apply: (g) => { g.timers.deathClock = 30; } },
  { id: 'onelife', name: 'One Life', tag: 'gamble', desc: 'Hits deal no damage. Each has a 10% chance to kill you.', apply: stat((m) => { m.oneLife = true; }) },
];

export function rollPerks(owned, count, allowed) {
  const pool = PERKS.filter((p) => {
    if (!allowed.has(p.id)) return false;
    const n = owned.get(p.id) ?? 0;
    if (n >= (p.max ?? 1)) return false;
    if (p.req && !owned.has(p.req)) return false;
    return true;
  });
  const out = [];
  while (out.length < count && pool.length) out.push(pool.splice(Math.floor(Math.random() * pool.length), 1)[0]);
  return out;
}
