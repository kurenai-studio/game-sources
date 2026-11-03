// Tests CONGELADOS (oraculo del PM) para src/game/fx-logic.mjs — contrato fx-logic.
// NO EDITAR: sellado por tests_sha256 en knowledge/contracts/fx-logic.md
import test from 'node:test';
import assert from 'node:assert/strict';

const mod = await import(new URL('../../src/game/fx-logic.mjs', import.meta.url));
const { vhsTimestamp, lightState, attenuation, scheduleAmbientEvents } = mod;

const SEED = 20260711;
const EVENT_TYPES = new Set(['flush', 'dryer', 'stall_noise', 'pipe_knock',
  'shower_hiss', 'door_slam', 'drain_gurgle', 'faucet_squeal']);

test('exports esperados', () => {
  for (const fn of [vhsTimestamp, lightState, attenuation, scheduleAmbientEvents])
    assert.equal(typeof fn, 'function');
});

test('vhsTimestamp: formato camcorder exacto, UTC, determinista', () => {
  assert.deepStrictEqual(vhsTimestamp(0), { date: 'JAN.1 1970', time: '00:00:00' });
  assert.deepStrictEqual(
    vhsTimestamp(Date.UTC(2026, 6, 11, 20, 56, 3)),
    { date: 'JUL.11 2026', time: '20:56:03' });
  assert.deepStrictEqual(
    vhsTimestamp(Date.UTC(1997, 11, 31, 4, 5, 9)),
    { date: 'DEC.31 1997', time: '04:05:09' });
  // milisegundos truncan, no redondean
  assert.equal(vhsTimestamp(Date.UTC(2026, 0, 2, 0, 0, 1) + 999).time, '00:00:01');
});

test('lightState: modo estable por (seed,id), intensidad en [0,1], dead siempre 0', () => {
  for (let id = 0; id < 50; id++) {
    const m0 = lightState(SEED, id, 0).mode;
    for (const t of [0, 137, 5000, 60000, 3600000]) {
      const s = lightState(SEED, id, t);
      assert.ok(['steady', 'flicker', 'dead'].includes(s.mode), 'modo invalido: ' + s.mode);
      assert.equal(s.mode, m0, 'el modo de una luz no puede cambiar con el tiempo');
      assert.ok(s.intensity >= 0 && s.intensity <= 1, 'intensidad fuera de [0,1]: ' + s.intensity);
      if (s.mode === 'dead') assert.equal(s.intensity, 0, 'luz muerta con intensidad > 0');
      if (s.mode === 'steady') assert.ok(s.intensity >= 0.6, 'steady demasiado tenue: ' + s.intensity);
    }
  }
});

test('lightState: distribucion de modos sobre 200 luces (hay muertas, parpadeantes y estables)', () => {
  const count = { steady: 0, flicker: 0, dead: 0 };
  for (let id = 0; id < 200; id++) count[lightState(SEED, id, 0).mode]++;
  assert.ok(count.dead >= 10 && count.dead <= 70, 'muertas fuera de [10,70]: ' + count.dead);
  assert.ok(count.flicker >= 20 && count.flicker <= 100, 'flicker fuera de [20,100]: ' + count.flicker);
  assert.ok(count.steady >= 60, 'muy pocas estables: ' + count.steady);
});

test('lightState: una luz flicker varia en el tiempo y toca valores bajos y altos', () => {
  let flickerId = -1;
  for (let id = 0; id < 200; id++) if (lightState(SEED, id, 0).mode === 'flicker') { flickerId = id; break; }
  assert.ok(flickerId >= 0, 'no se encontro ninguna luz flicker');
  let lo = Infinity, hi = -Infinity;
  for (let t = 0; t < 20000; t += 40) {
    const v = lightState(SEED, flickerId, t).intensity;
    lo = Math.min(lo, v); hi = Math.max(hi, v);
  }
  assert.ok(lo < 0.3, 'flicker nunca baja de 0.3 (min=' + lo + ')');
  assert.ok(hi > 0.6, 'flicker nunca sube de 0.6 (max=' + hi + ')');
});

test('lightState: determinista (mismos argumentos, mismo resultado)', () => {
  for (const [id, t] of [[3, 777], [42, 123456]]) {
    assert.deepStrictEqual(lightState(SEED, id, t), lightState(SEED, id, t));
  }
});

test('attenuation: 1 en refDist, 0 en maxDist, monotona no creciente, rango [0,1]', () => {
  const REF = 2, MAX = 30;
  assert.equal(attenuation(0, REF, MAX), 1);
  assert.equal(attenuation(REF, REF, MAX), 1);
  assert.equal(attenuation(MAX, REF, MAX), 0);
  assert.equal(attenuation(MAX + 50, REF, MAX), 0);
  let prev = 1;
  for (let d = REF; d <= MAX; d += 0.25) {
    const g = attenuation(d, REF, MAX);
    assert.ok(g >= 0 && g <= 1, 'ganancia fuera de [0,1]: ' + g);
    assert.ok(g <= prev + 1e-9, 'atenuacion no monotona en d=' + d);
    prev = g;
  }
  const mid = attenuation((REF + MAX) / 2, REF, MAX);
  assert.ok(mid > 0 && mid < 1, 'punto medio debe estar estrictamente entre 0 y 1');
});

test('scheduleAmbientEvents: deterministico, ordenado, tipos validos, en ventana, offsets en rango', () => {
  const t0 = 0, t1 = 600000; // 10 minutos
  const a = scheduleAmbientEvents(SEED, t0, t1);
  const b = scheduleAmbientEvents(SEED, t0, t1);
  assert.deepStrictEqual(a, b);
  assert.ok(Array.isArray(a));
  let prev = -Infinity;
  for (const e of a) {
    assert.ok(e.t >= t0 && e.t < t1, 'evento fuera de ventana: ' + e.t);
    assert.ok(e.t >= prev, 'eventos no ordenados por t');
    prev = e.t;
    assert.ok(EVENT_TYPES.has(e.type), 'tipo de evento invalido: ' + e.type);
    assert.ok(typeof e.dx === 'number' && Math.abs(e.dx) <= 20, 'dx fuera de rango');
    assert.ok(typeof e.dz === 'number' && Math.abs(e.dz) <= 20, 'dz fuera de rango');
  }
  assert.ok(a.length >= 6 && a.length <= 180, 'cantidad de eventos en 10min fuera de [6,180]: ' + a.length);
});

test('scheduleAmbientEvents: ventanas componen (sin estado entre llamadas)', () => {
  const whole = scheduleAmbientEvents(SEED, 0, 120000);
  const first = scheduleAmbientEvents(SEED, 0, 60000);
  const second = scheduleAmbientEvents(SEED, 60000, 120000);
  assert.deepStrictEqual(whole, [...first, ...second],
    'events(0,120s) debe ser identico a events(0,60s) ++ events(60s,120s)');
});

test('scheduleAmbientEvents: hay variedad de tipos en una ventana larga', () => {
  const evs = scheduleAmbientEvents(SEED, 0, 1800000); // 30 min
  const types = new Set(evs.map(e => e.type));
  assert.ok(types.size >= 6, 'menos de 6 tipos de evento distintos en 30min: ' + [...types].join(','));
});
