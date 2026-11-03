import test from 'node:test';
import assert from 'node:assert/strict';
import { newDog, update, command, reward, pet, tickStats, applyAway, obeyChance, distractChance } from './brain.js';

// Een kleine wereld zonder three: bal ligt stil op het gras, speler staat op z = 12.
function world(rand = () => 0) {
  const log = [];
  return {
    log,
    ball: { mode: 'vrij', p: { x: 0, y: 0.03, z: -8 }, rust: true },
    land: null, worp: 1, nat: 0,
    player: { x: 0, z: 12 }, hand: { x: 0, y: 1.2, z: 11.5 },
    bowls: { voer: { x: -2, z: 10, vol: 0 }, water: { x: -3, z: 10, vol: 0 } },
    vijverRand: { x: 5, z: -5 },
    surfaceAt: () => 'gras',
    events: [], rand, say: (m) => log.push(m),
  };
}

// Speel de spellus na: verwerk wat Spot met de bal doet.
function run(d, ctx, seconds, until = () => false) {
  for (let t = 0; t < seconds; t += 1 / 60) {
    update(d, 1 / 60, ctx);
    for (const e of d.events.splice(0)) {
      if (e.type === 'pak') ctx.ball.mode = 'bek';
      if (e.type === 'val') ctx.ball.mode = 'vrij';
      if (e.type === 'los') { ctx.ball.mode = e.bijSpeler ? 'hand' : 'vrij'; ctx.los = e; }
    }
    ctx.events.length = 0;
    if (until()) return true;
  }
  return false;
}

test('stats blijven binnen 0–100 en rennen kost energie, rusten herstelt', () => {
  const d = newDog();
  const e0 = d.stats.energie;
  tickStats(d, 5, 'ren');
  assert.ok(d.stats.energie < e0);
  const e1 = d.stats.energie;
  tickStats(d, 5, 'lig');
  assert.ok(d.stats.energie > e1);
  tickStats(d, 1e6, 'ren');
  tickStats(d, 1e6, 'lig');
  for (const v of Object.values(d.stats)) assert.ok(v >= 0 && v <= 100, `${v}`);
});

test('verwaarlozing (honger, dorst, lang wegblijven) verlaagt vertrouwen', () => {
  const d = newDog();
  d.stats.honger = 95;
  const v0 = d.stats.vertrouwen;
  tickStats(d, 60, 'sta');
  assert.ok(d.stats.vertrouwen < v0);
  const e = newDog();
  applyAway(e, 6 * 3600);
  assert.ok(e.stats.honger > 70 && e.stats.dorst > 80 && e.stats.vertrouwen < 40);
  applyAway(e, 1e12); // begrensd
  assert.ok(e.stats.vertrouwen >= 0);
});

test('belonen na een goed commando verhoogt beheersing en gehoorzaamheid', () => {
  const d = newDog(), ctx = world();
  ctx.ball.mode = 'hand';
  const p0 = obeyChance(d, 'zit');
  assert.ok(command(d, 'zit', ctx));
  assert.equal(d.state, 'zit');
  assert.equal(reward(d), 'zit');
  assert.ok(obeyChance(d, 'zit') > p0);
  assert.equal(reward(d), null, 'een tweede koekje leert niets');
});

test('een onbetrouwbare worp van de dobbelsteen: Spot negeert het commando', () => {
  const d = newDog(), ctx = world(() => 0.999);
  ctx.ball.mode = 'hand';
  assert.equal(command(d, 'zit', ctx), false);
  assert.equal(d.state, 'wacht');
});

test('vertrouwen, moeheid en afleiding bepalen de gehoorzaamheid', () => {
  const d = newDog();
  const base = obeyChance(d, 'bring');
  assert.ok(obeyChance(d, 'bring', 1) < base);
  d.stats.vertrouwen = 100;
  assert.ok(obeyChance(d, 'bring') > base);
  d.stats.energie = 5;
  assert.ok(obeyChance(d, 'bring') < base);
  const a0 = distractChance(d, 0.8);
  d.mastery.blijf = d.mastery.bring = 1;
  assert.ok(distractChance(d, 0.8) < a0);
  assert.ok(pet(d) && !pet(d), 'aaien heeft een pauze');
});

test('volledige apporteerlus: achtervolgen, pakken, brengen, aus', () => {
  const d = newDog(), ctx = world();
  assert.ok(run(d, ctx, 30, () => d.state === 'houvast'), `blijft hangen in ${d.state}`);
  assert.equal(ctx.ball.mode, 'bek');
  assert.ok(Math.hypot(d.pos.x - ctx.player.x, d.pos.z - ctx.player.z) < 2.5);
  assert.equal(d.done, 'bring');
  assert.ok(command(d, 'aus', ctx));
  assert.ok(run(d, ctx, 2, () => ctx.los));
  assert.ok(ctx.los.netjes && ctx.los.bijSpeler);
  assert.equal(ctx.ball.mode, 'hand');
});

test('zonder gehoorzaamheid speelt Spot eerst, maar de bal komt altijd terug', () => {
  const d = newDog(), ctx = world(() => 0.999);
  assert.ok(run(d, ctx, 20, () => d.state === 'speel'));
  assert.ok(run(d, ctx, 90, () => ctx.ball.mode === 'hand'), `blijft hangen in ${d.state}`);
  assert.equal(ctx.los.netjes, false);
});

test('blijf: Spot wacht tijdens de worp en gaat pas op "bring"', () => {
  const d = newDog(), ctx = world();
  ctx.ball.mode = 'hand';
  assert.ok(command(d, 'blijf', ctx));
  ctx.ball.mode = 'vrij'; ctx.worp = 2;
  run(d, ctx, 2);
  assert.equal(d.state, 'blijf');
  assert.equal(d.done, 'blijf');
  assert.ok(command(d, 'bring', ctx));
  assert.equal(d.state, 'achtervolg');
});

test('in zand zoekt Spot eerst, en een eekhoorn leidt hem af', () => {
  const d = newDog(), ctx = world();
  ctx.surfaceAt = () => 'zand';
  assert.ok(run(d, ctx, 20, () => d.state === 'zoek'));
  assert.ok(run(d, ctx, 20, () => d.hasBall));
  const e = newDog(), c2 = world();
  c2.ball.mode = 'hand';
  c2.events.push({ type: 'eekhoorn', pos: { x: 10, z: 0 }, sterkte: 0.8 });
  update(e, 1 / 60, c2);
  assert.equal(e.state, 'afgeleid');
  c2.events.length = 0;
  assert.ok(run(e, c2, 15, () => e.state === 'wacht'));
});

test('moe, hongerig en dorstig: Spot rust, eet en drinkt', () => {
  const d = newDog(), ctx = world();
  ctx.ball.mode = 'hand';
  d.stats.energie = 5;
  run(d, ctx, 1);
  assert.equal(d.state, 'rust');
  assert.ok(run(d, ctx, 60, () => d.state === 'wacht'));
  d.stats.honger = 60; d.stats.dorst = 60;
  ctx.bowls.voer.vol = 1; ctx.bowls.water.vol = 1;
  assert.ok(run(d, ctx, 60, () => d.stats.honger < 10 && d.stats.dorst < 10), JSON.stringify(d.stats));
});

test('Spot loopt om een boomstam heen in plaats van erdoor', () => {
  const d = newDog(), ctx = world();
  const stam = { x: 0.45, z: 0, r: 0.3, h: 3 }; // midden op de rechte lijn naar de bal
  ctx.obstakels = [stam];
  let dichtst = Infinity;
  assert.ok(run(d, ctx, 30, () => {
    dichtst = Math.min(dichtst, Math.hypot(d.pos.x - stam.x, d.pos.z - stam.z));
    return d.hasBall;
  }), 'komt niet bij de bal');
  assert.ok(dichtst >= stam.r + 0.4 - 1e-6, `door de stam: ${dichtst}`);
});
