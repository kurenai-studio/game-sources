import test from 'node:test';
import assert from 'node:assert/strict';
import { R, G, WATER_Y, newBall, step, submerged, predictLanding } from './physics.js';

const DT = 1 / 240;
const on = (surf, extra = {}) => ({ surfaceAt: () => surf, ...extra });

// Gooi vanaf de grond en geef de toestand bij de eerste stuit terug.
function fly(v, w, env) {
  const b = newBall({ x: 0, y: R + 1e-6, z: 0 }, v, w);
  for (let i = 0; i < 240 * 20 && !b.events.length; i++) step(b, DT, env);
  return b;
}
const launch = (speed, deg) => ({ x: speed * Math.cos((deg * Math.PI) / 180), y: speed * Math.sin((deg * Math.PI) / 180), z: 0 });

// Laat vallen en meet de top van de eerste terugstuit.
function rebound(surf, nat = 0, h = 2.54) {
  const b = newBall({ x: 0, y: h + R, z: 0 });
  let top = 0, bounced = false;
  for (let i = 0; i < 240 * 5; i++) {
    step(b, DT, on(surf, { nat }));
    if (b.events.length) bounced = true;
    if (bounced) top = Math.max(top, b.p.y - R);
    if (bounced && b.v.y < 0) break;
  }
  return top;
}

test('zonder lucht klopt de dracht met v²·sin2θ/g', () => {
  const b = fly(launch(20, 45), undefined, on('gras', { geenLucht: true }));
  assert.ok(Math.abs(b.p.x - (20 * 20) / G) < 0.3, `dracht ${b.p.x}`);
});

test('luchtweerstand verkort de worp', () => {
  const vac = fly(launch(20, 45), undefined, on('gras', { geenLucht: true })).p.x;
  const air = fly(launch(20, 45), undefined, on('gras')).p.x;
  assert.ok(air < 0.85 * vac && air > 0.5 * vac, `lucht ${air} vacuüm ${vac}`);
});

test('Magnus: backspin draagt verder dan topspin, zijspin buigt de baan', () => {
  // De bal vliegt in +x; topspin is dan een negatieve z-rotatie.
  const top = fly(launch(20, 30), { x: 0, y: 0, z: -150 }, on('gras')).p.x;
  const back = fly(launch(20, 30), { x: 0, y: 0, z: 150 }, on('gras')).p.x;
  assert.ok(back > top + 2, `backspin ${back} topspin ${top}`);
  const side = fly(launch(20, 30), { x: 0, y: 150, z: 0 }, on('gras'));
  const other = fly(launch(20, 30), { x: 0, y: -150, z: 0 }, on('gras'));
  assert.ok(side.p.z < -1 && other.p.z > 1, `zijwaarts ${side.p.z} ${other.p.z}`);
});

test('valproef op beton voldoet aan de tennisbalnorm (135–147 cm vanaf 254 cm)', () => {
  const h = rebound('beton');
  assert.ok(h > 1.35 && h < 1.47, `terugstuit ${h}`);
});

test('stuithoogte: beton > gras > zand, en nat gras lager dan droog', () => {
  const [beton, gras, zand, nat] = [rebound('beton'), rebound('gras'), rebound('zand'), rebound('gras', 1)];
  assert.ok(beton > gras && gras > zand && nat < gras, `${beton} ${gras} ${zand} ${nat}`);
});

test('topspin schiet door na de stuit, backspin remt', () => {
  const env = on('beton');
  const top = fly(launch(15, 30), { x: 0, y: 0, z: -200 }, env).v.x;
  const none = fly(launch(15, 30), undefined, env).v.x;
  const back = fly(launch(15, 30), { x: 0, y: 0, z: 200 }, env).v.x;
  assert.ok(top > none && none > back, `${top} ${none} ${back}`);
});

test('een gladde natte bal neemt bij de stuit minder spin op', () => {
  const dry = fly(launch(15, 20), undefined, on('beton'));
  const wet = fly(launch(15, 20), undefined, on('beton', { nat: 1 }));
  assert.ok(Math.abs(wet.w.z) < Math.abs(dry.w.z), `${wet.w.z} ${dry.w.z}`);
});

test('de bal rolt uit, en eerder in zand dan op beton', () => {
  const roll = (surf) => {
    const b = newBall({ x: 0, y: R, z: 0 }, { x: 4, y: 0, z: 0 }, { x: 0, y: 0, z: -4 / R });
    for (let i = 0; i < 240 * 120 && !b.rust; i++) step(b, DT, on(surf));
    assert.ok(b.rust, `${surf} komt niet tot rust`);
    return b.p.x;
  };
  assert.ok(roll('zand') < roll('gras') && roll('gras') < roll('beton'));
});

test('de bal drijft: komt tot rust met ruim een derde onder water', () => {
  const b = newBall({ x: 0, y: 2, z: 0 }, { x: 3, y: 0, z: 0 });
  for (let i = 0; i < 240 * 20 && !b.rust; i++) step(b, DT, on('water'));
  assert.ok(b.rust, 'dobbert niet uit');
  assert.equal(b.events[0].type, 'plons');
  const f = submerged(b, 'water');
  assert.ok(f > 0.3 && f < 0.45, `ondergedompeld ${f}`);
  assert.ok(b.p.y > WATER_Y - R && b.p.y < WATER_Y + R);
});

test('de voorspelde landing komt overeen met de echte', () => {
  const env = on('gras');
  const b = newBall({ x: 0, y: 1.5, z: 0 }, { x: 3, y: 8, z: -14 }, { x: 30, y: 40, z: 0 });
  const guess = predictLanding(b, env);
  while (!b.events.length) step(b, DT, env);
  assert.ok(Math.hypot(b.p.x - guess.x, b.p.z - guess.z) < 0.3);
});

test('de bal kaatst terug van een boomstam en vliegt eroverheen als hij hoog genoeg is', () => {
  const env = on('gras', { obstakels: [{ x: 5, z: 0, r: 0.3, h: 3 }] });
  const laag = newBall({ x: 0, y: 1, z: 0.1 }, { x: 15, y: 2, z: 0 });
  for (let i = 0; i < 240 && !laag.events.length; i++) step(laag, DT, env);
  assert.equal(laag.events[0].surf, 'hout');
  assert.ok(laag.v.x < 0 && laag.v.x > -15, `terug met verlies: ${laag.v.x}`);
  assert.ok(laag.v.z > 0, 'schampt naar de kant waar hij de stam raakte');
  assert.ok(Math.hypot(laag.p.x - 5, laag.p.z) >= 0.3 + R - 1e-9, 'blijft buiten de stam');
  const hoog = newBall({ x: 0, y: 4, z: 0 }, { x: 15, y: 3, z: 0 });
  for (let i = 0; i < 120; i++) step(hoog, DT, env);
  assert.ok(hoog.p.x > 6 && !hoog.events.length);
});
