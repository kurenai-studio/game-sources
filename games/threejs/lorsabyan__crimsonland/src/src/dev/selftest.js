// Behaviour tests for game content, run in the real game with ?selftest (dev server only).
// Each test builds a tiny scripted scene and asserts the effect a perk, drop or weapon promises.
// Results land in window.__selftest and the console.
import { PERKS } from '../data/perks.js';
import { BONUSES } from '../data/bonuses.js';
import { WEAPONS, WEAPON_LIST } from '../data/weapons.js';
import { MISSIONS } from '../data/missions.js';
import { len } from '../core/util.js';

export async function run(g) {
  const h = g.horde, S = g.shots, I = g.input, D = g.director, R = [];
  const p = () => g.player;
  const near = (a, b, tol = 0.02) => Math.abs(a - b) <= Math.abs(b) * tol + 1e-6;

  const reset = () => {
    g.autoplay = false;
    g.start({ mode: 'survival', biome: 'dust' });
    g.phase = 'play';
    D.update = () => {};
    I.poll = () => {};
    Object.assign(I, { moveX: 0, moveZ: 0, aimX: 0, aimZ: 10, fire: false, firePressed: false, reload: false, swap: false });
    p().aimX = 0; p().aimZ = 1;
  };
  const tick = (n = 1) => { for (let i = 0; i < n; i++) g.update(1 / 60); };
  const secs = (s) => tick(Math.round(s * 60));
  const perk = (id) => g.takePerk(PERKS.find((x) => x.id === id));
  const dummy = (id, x, z, o = {}) => {
    const i = h.spawn(id, x, z, { hpScale: 1, size: 1, ...o });
    h.spd[i] = 0;
    return i;
  };
  const tank = (id, x, z) => { const i = dummy(id, x, z); h.hp[i] = h.maxHp[i] = 1e6; return i; };
  const lost = (i) => h.maxHp[i] - h.hp[i];
  const shoot = (w = null) => { if (w) p().giveWeapon(w); p().cooldown = 0; I.fire = true; tick(1); I.fire = false; };
  const test = (name, fn) => {
    reset();
    let ok = false, detail = '';
    try {
      const r = fn();
      ok = Array.isArray(r) ? r[0] : r;
      detail = Array.isArray(r) ? String(r[1]) : '';
    } catch (e) { detail = `threw: ${e.message}`; }
    R.push({ name, ok: !!ok, detail });
  };

  // Offence --------------------------------------------------------------------------------------
  test('deadeye: spread x0.5, damage +10%', () => { perk('deadeye'); shoot(); return [near(S.dmg[0], WEAPONS.pistol.dmg * 1.1) && p().mods.spread === 0.5, S.dmg[0]]; });
  test('trigger: fire rate +15%', () => { perk('trigger'); shoot(); return [near(p().cooldown, 1 / (WEAPONS.pistol.rate * 1.15)), p().cooldown]; });
  test('hollow: damage +20%', () => { perk('hollow'); shoot(); return near(S.dmg[0], WEAPONS.pistol.dmg * 1.2); });
  test('crit: triples a hit', () => { p().mods.crit = 1; const e = tank('shambler', 0, 6); p().spread = 0; shoot(); secs(0.4); return [near(lost(e), WEAPONS.pistol.dmg * 3, 0.05), lost(e)]; });
  test('venom: poisons on hit', () => { perk('venom'); const e = tank('shambler', 0, 6); shoot(); secs(0.4); return [h.poison[e] > 0 && lost(e) > WEAPONS.pistol.dmg, h.poison[e]]; });
  test('barrel: bullet speed +30%', () => { perk('barrel'); shoot(); return near(len(S.vx[0], S.vz[0]), 62 * 1.3, 0.05); });
  test('pyro: flamer damage +75%', () => { perk('pyro'); shoot('flamer'); return [near(S.dmg[0], WEAPONS.flamer.dmg * 1.75), S.dmg[0]]; });
  test('arc: ion chain reaches 2 further targets', () => {
    const run = (extra) => {
      reset(); if (extra) perk('arc');
      const es = [0, 1, 2, 3, 4, 5, 6, 7].map((k) => tank('shambler', 0, 5 + k * 3));
      shoot('ion'); secs(0.5);
      return es.filter((e) => lost(e) > 0).length;
    };
    const a = run(false), b = run(true);
    return [b === a + 2 && a === 1 + WEAPONS.ion.chain, `${a} -> ${b}, weapon chain ${WEAPONS.ion.chain}`];
  });
  test('ricochet: bullet bounces to a second target', () => { perk('ricochet'); const a = tank('shambler', 0, 6), b = tank('shambler', 4, 8); shoot(); secs(0.6); return [lost(a) > 0 && lost(b) > 0, `${lost(a)} ${lost(b)}`]; });
  test('volatile: kills can detonate', () => { p().mods.volatile = 1; const a = dummy('skitter', 0, 6), b = tank('shambler', 1.5, 6); h.hp[a] = 1; shoot(); secs(0.4); return [lost(b) > 0, lost(b)]; });
  test('gorgon: crosshair freezes', () => { perk('gorgon'); const e = tank('shambler', 0, 6); I.aimX = 0; I.aimZ = 6; tick(3); return h.frozen[e] > 0; });
  test('pyrokinetic: crosshair ignites', () => { perk('pyrokin'); const e = tank('shambler', 0, 6); I.aimX = 0; I.aimZ = 6; tick(3); return h.burn[e] > 0; });
  test('cough: spits a fireball every 3s', () => { perk('cough'); let seen = 0; for (let i = 0; i < 210; i++) { tick(); if (S.count) seen++; } return [seen > 0, seen]; });
  test('fuse: ring every 8s', () => { perk('fuse'); secs(7.5); const a = S.count; secs(0.6); return [a === 0 && S.count >= 20, `${a} -> ${S.count}`]; });
  // Handling ------------------------------------------------------------------------------------
  test('mags: reload 35% faster', () => { perk('mags'); p().ammo = 1; p().startReload(); return near(p().reloadLen, WEAPONS.pistol.reload * 0.65); });
  test('drums: clip +50%', () => { perk('drums'); return [p().ammo === 18 && p().clip === 18, p().ammo]; });
  test('holster: keeps old weapon, swap restores it', () => { perk('holster'); p().giveWeapon('rifle'); const held = p().alt?.weapon.id; I.swap = true; tick(); return [held === 'pistol' && p().weapon.id === 'pistol' && p().alt.weapon.id === 'rifle', held]; });
  test('planted: reload x3 standing still', () => { perk('planted'); p().ammo = 1; secs(0.3); p().startReload(); const len0 = p().reloadLen; secs(len0 / 3 + 0.1); return [!p().reloading, p().reloadT]; });
  test('frantic: trigger speeds reload', () => { perk('frantic'); p().ammo = 1; p().startReload(); const t0 = p().reloadT; I.firePressed = true; tick(); return [t0 - p().reloadT > 0.1, t0 - p().reloadT]; });
  test('nova: ring when reload finishes', () => { perk('nova'); p().ammo = 1; p().startReload(); secs(p().reloadLen + 0.05); return [S.count >= 12, S.count]; });
  test('blood rounds: fires during reload for health', () => { perk('bottomless'); p().ammo = 1; p().startReload(); const hp = p().hp, s0 = g.stats.fired; I.fire = true; secs(0.5); I.fire = false; return [g.stats.fired > s0 && p().hp < hp, `${g.stats.fired - s0} shots, hp ${p().hp}`]; });
  test('borrowed rounds: fires during reload for score', () => { perk('borrowed'); g.score = 80; p().ammo = 1; p().startReload(); I.fire = true; secs(0.5); I.fire = false; return [g.score < 80, g.score]; });
  // Mobility and economy --------------------------------------------------------------------------
  test('boots: speed +15%', () => { perk('boots'); I.moveX = 1; secs(1); return [near(p().vx, 7.6 * 1.15, 0.03), p().vx]; });
  test('marathon: speeds up over time', () => { perk('marathon'); I.moveX = 1; secs(1); const a = p().vx; p().x = -30; secs(4.5); return [p().vx > a * 1.3, `${a} -> ${p().vx}`]; });
  test('notes: xp +25%', () => { perk('notes'); const s = g.score; h.kill(dummy('shambler', 3, 3), 0, 0); return [g.score - s === 15, g.score - s]; });
  test('scavenger: drops pull towards you', () => { perk('scav'); g.drops.spawn(BONUSES.points, 4, 0); const d = g.drops.items.find((x) => x.on); tick(30); return [d.x < 4, d.x]; });
  test('long fuse: timers +60%', () => { perk('longfuse'); g.drops.spawn(BONUSES.shield, 0, 0); tick(2); return [near(g.timers.shield, 12.8, 0.02), g.timers.shield]; });
  test('reach: crosshair collects drops', () => { perk('reach'); g.drops.spawn(BONUSES.points, 20, 20); I.aimX = 20; I.aimZ = 20; tick(2); return [g.score >= 500, g.score]; });
  test('adrenal: world 12% slower', () => { perk('adrenal'); secs(2); return [near(g.slow, 0.88, 0.02), g.slow]; });
  test('forked: 5 choices', () => { perk('forked'); g.pendingPerks = 1; g.openPerks(); const n = g.ui.cards.length; g.ui.hidePerks(); g.phase = 'play'; return [n === 5, n]; });
  test('many paths: 6 choices', () => { perk('forked'); perk('many'); g.pendingPerks = 1; g.openPerks(); const n = g.ui.cards.length; g.ui.hidePerks(); g.phase = 'play'; return [n === 6, n]; });
  // Defence -------------------------------------------------------------------------------------
  test('mercy frames: second instant hit ignored', () => { p().hurt(10, 3, 0); const a = p().hp; p().hurt(10, 3, 0); return [p().hp === a && a === 90, p().hp]; });
  test('thick skin: -30% damage, -15% max hp', () => { perk('thick'); p().hurt(10, 3, 0); return [near(p().hp, 78, 0.01) && p().maxHp === 85, p().hp]; });
  test('sidestep: dodges about 20%', () => { perk('sidestep'); let d = 0; for (let i = 0; i < 400; i++) { p().hp = 100; p().hurtCool = 0; p().hurt(1, 3, 0); if (p().hp === 100) d++; } return [d > 50 && d < 115, d]; });
  test('ghost step: dodges about 40%', () => { perk('sidestep'); perk('ghost'); let d = 0; for (let i = 0; i < 400; i++) { p().hp = 100; p().hurtCool = 0; p().hurt(1, 3, 0); if (p().hp === 100) d++; } return [d > 120 && d < 200, d]; });
  test('iron gut: no slow, no shove', () => { perk('iron'); p().hurt(5, 3, 0); return [p().slowT <= 0 && p().vx === 0, p().vx]; });
  test('regrowth: heals 1.2/s', () => { perk('regen'); p().hp = 50; secs(1); return [near(p().hp, 51.2, 0.01), p().hp]; });
  test('hydra blood: heals 4.2/s total', () => { perk('regen'); perk('hydra'); p().hp = 50; secs(1); return [near(p().hp, 54.2, 0.01), p().hp]; });
  test('dressing: heals 50', () => { p().hp = 20; perk('dressing'); return p().hp === 70; });
  test('hard to kill: max hp +30 and heals it', () => { perk('hard'); return p().maxHp === 130 && p().hp === 130; });
  test('bayonet: hurts what touches you', () => { perk('bayonet'); const e = tank('shambler', 0.5, 0); secs(1.2); return [lost(e) > 0, lost(e)]; });
  test('bayonet: touching enemies still hit you', () => { perk('bayonet'); tank('shambler', 0.5, 0); secs(1.5); return [p().hp < 100, p().hp]; });
  test('hot core: aura burns nearby only', () => { perk('hotcore'); const a = tank('shambler', 4, 0), b = tank('shambler', 15, 0); secs(1); return [lost(a) > 5 && lost(b) === 0, `${lost(a)} ${lost(b)}`]; });
  test('plague: infects on touch and damages', () => { perk('plague'); const e = tank('shambler', 0.5, 0); secs(1); return [h.plague[e] > 0 && lost(e) > 0, h.plague[e]]; });
  test('plague: spreads between enemies', () => { const a = tank('shambler', 10, 0), b = tank('shambler', 10.5, 0); h.plague[a] = 6; secs(3); return [h.plague[b] > 0, h.plague[b]]; });
  test('last word: death clears nearby', () => { perk('lastword'); const e = dummy('shambler', 6, 0); p().hp = 1; p().hurt(5, 3, 0); tick(2); return [h.dead[e] > 0, h.dead[e]]; });
  test('dug in: +60% damage when still', () => { perk('dug'); secs(1.1); shoot(); return [near(S.dmg[0], WEAPONS.pistol.dmg * 1.6), S.dmg[0]]; });
  test('static charge: bolts after standing', () => { perk('static'); secs(2.8); const a = S.count; secs(0.6); return [a === 0 && S.count >= 10, `${a} -> ${S.count}`]; });
  // Gambles -------------------------------------------------------------------------------------
  test('contract: +3 levels, hp 10', () => { perk('contract'); return [g.level === 4 && p().hp === 10 && g.pendingPerks === 3, g.level]; });
  test('blood money: +5000, half max hp', () => { perk('bloodmoney'); return [g.score >= 5000 && p().maxHp === 50, p().maxHp]; });
  test('fifty-fifty: roughly half die', () => { const es = []; for (let i = 0; i < 40; i++) es.push(dummy('shambler', 3 + (i % 8), (i >> 3) * 2 + 4)); perk('fifty'); const dead = es.filter((e) => h.dead[e] > 0).length; return [dead > 10 && dead < 30, dead]; });
  test('borrowed time: immune, then dies', () => { perk('clock'); p().hurt(500, 3, 0); const safe = p().hp === 100; g.timers.deathClock = 0.1; secs(0.3); return [safe && p().dead, p().hp]; });
  test('one life: hits do nothing or kill', () => { perk('onelife'); let n = 0; for (let i = 0; i < 300 && !p().dead; i++) { p().hurtCool = 0; p().hurt(50, 3, 0); n++; } return [p().dead && n > 1, `died on hit ${n}`]; });
  // Drops ---------------------------------------------------------------------------------------
  const collect = (id) => { g.drops.spawn(BONUSES[id], 0, 0); tick(2); };
  test('points: +500', () => { collect('points'); return g.score === 500; });
  test('medkit: +30', () => { p().hp = 50; collect('medkit'); return near(p().hp, 80, 0.01); });
  test('weapon crate: swaps gun', () => { collect('weapon'); return [p().weapon.id !== 'pistol', p().weapon.id]; });
  test('nuke: clears the screen', () => { const a = dummy('brute', 7, 3), b = dummy('shambler', -7, 3); collect('nuke'); return [h.dead[a] > 0 && h.dead[b] > 0, `${h.hp[a]} ${h.hp[b]}`]; });
  test('freeze: stops everything', () => { const e = tank('shambler', 6, 0); h.spd[e] = 3; collect('freeze'); const x = h.x[e]; secs(0.5); return [h.frozen[e] > 0 && Math.abs(h.x[e] - x) < 0.3, h.frozen[e]]; });
  test('freeze: frozen kills shatter', () => { const e = dummy('shambler', 6, 0); collect('freeze'); h.damage(e, 1e6, 0, 0, 0); return h.dead[e] >= 2; });
  test('fire ring: burst of plasma', () => { collect('firering'); return [S.count >= 20, S.count]; });
  test('shock chain: arcs through a group', () => { const es = [1, 2, 3, 4, 5].map((k) => tank('shambler', k * 3, 2)); collect('shock'); return [es.every((e) => lost(e) > 0), es.map(lost).join(',')]; });
  test('reflex: slows the world', () => { collect('reflex'); secs(1); return [g.slow < 0.5, g.slow]; });
  test('shield: blocks damage', () => { collect('shield'); p().hurt(50, 3, 0); return p().hp === 100; });
  test('speed: nearly doubles speed', () => { collect('speed'); I.moveX = 1; secs(1); return [p().vx > 12, p().vx]; });
  test('fire rounds: +120% damage and ignite', () => { const e = tank('shambler', 0, 6); collect('fireammo'); shoot(); const d = S.dmg[0]; secs(0.4); return [near(d, WEAPONS.pistol.dmg * 2.2) && h.burn[e] > 0, d]; });
  test('double xp: doubles kills', () => { collect('xp2'); const s = g.score; h.kill(dummy('shambler', 3, 3), 0, 0); return [g.score - s === 24, g.score - s]; });
  test('overdrive: faster fire, quick reload', () => { collect('overdrive'); shoot(); return [near(p().cooldown, 1 / (WEAPONS.pistol.rate * 1.6)), p().cooldown]; });
  // Weapons -------------------------------------------------------------------------------------
  for (const w of WEAPON_LIST) {
    test(`${w.id}: damages a target it is aimed at`, () => {
      const e = tank('brute', 0, 7);
      if (w.kind === 'mine') { p().z = 5.5; p().x = 1.5; }
      p().giveWeapon(w.id);
      I.aimX = h.x[e]; I.aimZ = h.z[e]; I.fire = true;
      secs(w.kind === 'mine' ? 3 : 2); I.fire = false; secs(0.6);
      return [lost(e) > 0, lost(e)];
    });
  }
  test('rail: pierces a whole line', () => { const es = [4, 6, 8, 10].map((z) => tank('shambler', 0, z)); tick(); shoot('gauss'); return [es.every((e) => lost(e) > 0), es.map(lost).join(',')]; });
  test('rocket: splash hits a neighbour', () => { tank('shambler', 0, 8); const b = tank('shambler', 2.5, 8); shoot('rocket'); secs(0.6); return [lost(b) > 0, lost(b)]; });
  test('seeker: homes on an off-axis target', () => { const e = tank('shambler', 9, 6); p().giveWeapon('swarm'); shoot(); secs(1.5); return [lost(e) > 0, lost(e)]; });
  test('blade: bounces off the arena wall', () => { p().z = 30; I.aimZ = 40; shoot('saw'); secs(0.5); return [S.count > 0 && S.vz[0] < 0, S.vz[0]]; });
  test('blade: passes through several', () => { const es = [4, 7, 10].map((z) => tank('shambler', 0, z)); shoot('saw'); secs(0.7); return [es.every((e) => lost(e) > 0), es.map(lost).join(',')]; });
  test('splitter: splits on hit', () => { tank('shambler', 0, 5); shoot('splitter'); secs(0.2); return [S.count >= 2, S.count]; });
  test('shrinker: shrinks and eventually kills', () => { const e = dummy('brute', 0, 6); h.hp[e] = 1e6; p().giveWeapon('shrinker'); I.aimZ = 6; I.fire = true; secs(4); I.fire = false; return [h.shrink[e] < 0.5 || h.dead[e] > 0, h.shrink[e]]; });
  test('pulse: knocks targets back', () => { const e = tank('shambler', 0, 4); const z = h.z[e]; shoot('pulse'); secs(0.5); return [h.z[e] > z + 0.2, h.z[e] - z]; });
  test('flamer: ignites', () => { const e = tank('shambler', 0, 4); p().giveWeapon('flamer'); I.aimZ = 4; I.fire = true; secs(0.6); I.fire = false; return h.burn[e] > 0; });
  test('mine: waits, then detonates on approach', () => { shoot('mines'); const n = S.count; const e = tank('shambler', 5, 5); secs(1); const quiet = lost(e) === 0; h.x[e] = p().x + 0.5; h.z[e] = p().z; p().x = 12; secs(0.2); return [n === 1 && quiet && lost(e) > 0, lost(e)]; });
  // Creatures -----------------------------------------------------------------------------------
  test('brute: winds up then charges', () => { const e = dummy('brute', 8, 0); h.spd[e] = 2.5; h.cool[e] = 0; secs(0.3); const wind = h.state[e] === 1; secs(0.7); return [wind && h.state[e] === 2, h.state[e]]; });
  test('spitter: lobs acid that hurts on landing', () => { const e = dummy('spitter', 7, 0); h.cool[e] = 0; secs(4); return [p().hp < 100, p().hp]; });
  test('spitter: holds fire while off screen', () => { const e = dummy('spitter', 0, 16); h.cool[e] = 0; h.spd[e] = 0; secs(1); return [S.count === 0, S.count]; });
  test('burster: detonates next to you', () => { const e = dummy('burster', 1, 0); h.spd[e] = 5; secs(1); return [h.dead[e] > 0 && p().hp < 100, p().hp]; });
  test('brood: births skitters', () => { dummy('brood', 10, 0); const a = h.alive; h.cool[h.list[0]] = 0; secs(0.2); return [h.alive > a, h.alive]; });
  test('hive: spawns creatures and never moves', () => { const e = dummy('nest', 10, 0); const a = h.alive; h.cool[e] = 0; const x = h.x[e]; secs(0.5); return [h.alive > a && h.x[e] === x, h.alive]; });
  test('tyrant: runs all its attack phases', () => {
    const e = h.spawn('tyrant', 12, 0, { hpScale: 1, size: 1 }), seen = new Set();
    const hp = p().hp;
    for (let i = 0; i < 60 * 120; i++) { p().hp = hp; p().hurtCool = 1; tick(); seen.add(h.state[e]); if (seen.size === 5) break; }
    return [[0, 1, 2, 3, 4].every((s) => seen.has(s)), [...seen].join(',')];
  });
  // Progression ---------------------------------------------------------------------------------
  const P = g.profile, saved = { m: P.missions, a: P.unlockAll };
  const restrict = (missions) => { P.missions = missions; P.unlockAll = false; reset(); };
  test('new profile: only starter guns drop', () => { restrict({}); const seen = new Set(); for (let i = 0; i < 300; i++) { D.t = 900; seen.add(g.drops.pickWeapon()); } return [[...seen].every((w) => ['rifle', 'smg', 'shotgun'].includes(w)), [...seen].join()]; });
  test('clearing 1-1 adds its weapon to drops', () => { restrict({ '1-1': 30 }); const seen = new Set(); for (let i = 0; i < 300; i++) { D.t = 900; seen.add(g.drops.pickWeapon()); } return [seen.has('sawed'), [...seen].join()]; });
  test('locked perks are never offered', () => { restrict({}); g.pendingPerks = 1; for (let i = 0; i < 30; i++) { g.phase = 'play'; g.openPerks(); if (g.ui.cards.some((c) => /Depleted Core|Bayonet|Hot Core/.test(c.textContent))) return false; g.ui.hidePerks(); } g.phase = 'play'; return true; });
  test('unlock everything opens the whole arsenal', () => { P.missions = {}; P.unlockAll = true; reset(); return [g.arsenal.weapons.size === 20 && g.arsenal.perks.size === PERKS.length, g.arsenal.perks.size]; });
  test('every mission grants something, every item is reachable', () => { P.missions = Object.fromEntries(MISSIONS.map((m) => [m.id, 1])); P.unlockAll = false; reset(); return [g.arsenal.weapons.size === 20 && g.arsenal.perks.size === PERKS.length, `${g.arsenal.weapons.size} ${g.arsenal.perks.size}`]; });
  P.missions = saved.m; P.unlockAll = saved.a;

  // Death ---------------------------------------------------------------------------------------
  test('zombie turns to the shot and lands on its back', () => {
    const e = dummy('shambler', 6, 0); h.hp[e] = 1;
    h.yaw[e] = 2.5;                                   // facing away when the shot lands
    tick(); I.aimX = 6; I.aimZ = 0; p().aimX = 1; p().aimZ = 0; shoot(); secs(1.2);
    const faces = Math.atan2(h.x[e] - 0, h.z[e] - 0);  // bearing from shooter to body
    const toShooter = Math.abs(Math.atan2(Math.sin(h.yaw[e] - faces - Math.PI), Math.cos(h.yaw[e] - faces - Math.PI)));
    return [h.dead[e] >= 1 && toShooter < 0.2, `yaw off by ${toShooter.toFixed(2)}`];
  });
  test('body slides away from the shooter', () => { const e = dummy('shambler', 6, 0); h.hp[e] = 1; tick(); p().aimX = 1; p().aimZ = 0; I.aimX = 6; I.aimZ = 0; shoot(); secs(1); return [h.x[e] > 6.2, h.x[e]]; });
  test('corpse joins the ground only once it has landed', () => {
    const e = dummy('shambler', 3, 3), l = g.layers[0], spy = l.baker.add; let n = 0;
    l.baker.add = function (...a) { n++; return spy.apply(this, a); };
    h.kill(e, 1, 0); const before = n; secs(1); l.baker.add = spy;
    return [before === 0 && n === 1, `${before} -> ${n}`];
  });
  test('burn kills fall without a shot direction', () => { const e = dummy('shambler', 4, 4); h.yaw[e] = 1; h.kill(e, 0, 0); secs(0.8); return [h.yaw[e] === 1 && h.dead[e] >= 1, h.yaw[e]]; });
  test('attack swing fires on contact', () => { const e = tank('shambler', 0.5, 0); h.spd[e] = 0; let peak = 0; for (let i = 0; i < 90; i++) { tick(); peak = Math.max(peak, h.swing[e]); } return [peak > 0.5, peak]; });
  test('hits make a target flinch', () => { const e = tank('shambler', 3, 3); h.damage(e, 30, 1, 0, 0, {}); return [h.hurtA[e] > 0.3, h.hurtA[e]]; });
  test('backpedalling runs the legs in reverse', () => { I.aimX = 0; I.aimZ = 12; tick(5); const a = p().phase; I.moveZ = -1; secs(0.5); return [p().phase < a, `${a} -> ${p().phase}`]; });

  test('elite: tougher, worth more, always drops', () => { const e = dummy('shambler', 4, 4, { elite: true, hpMul: 3.5 }); const hp = h.hp[e]; h.kill(e, 0, 0); return [near(hp, 147, 0.02) && g.score === 48 && g.drops.items.some((d) => d.on), g.score]; });

  delete D.update; delete I.poll;
  g.autoplay = false;
  g.start({ mode: 'survival', attract: true });
  const failed = R.filter((r) => !r.ok);
  const out = { total: R.length, passed: R.length - failed.length, failed };
  window.__selftest = out;
  console.info(`selftest: ${out.passed}/${out.total} passed`, failed);
  return out;
}
