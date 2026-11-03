// Tests CONGELADOS (oraculo del PM) para el motor — contrato engine-bathrooms.
// NO EDITAR: sellado por tests_sha256 en knowledge/contracts/engine-bathrooms.md
// Chequeos estructurales deterministas (los aspectos visuales/sonoros se verifican
// end-to-end en navegador por el PM; esto congela el cableado que los hace posibles).
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const p = (rel) => root + rel;
const read = (rel) => readFileSync(p(rel), 'utf8');

const FILES = ['src/game/index.html', 'src/game/main.mjs', 'src/game/engine.mjs',
  'src/game/vhs.mjs', 'src/game/audio.mjs'];

test('archivos del motor presentes', () => {
  for (const f of FILES) assert.ok(existsSync(p(f)), 'falta ' + f);
});

test('offline total: ninguna URL http(s) en el codigo del juego', () => {
  for (const f of FILES) {
    const src = read(f);
    assert.ok(!/https?:\/\//.test(src), f + ' contiene una URL externa (el juego debe ser 100% offline)');
  }
});

test('index.html: importmap a three vendoreado, artefacto de datos y main.mjs', () => {
  const html = read('src/game/index.html');
  assert.ok(/"three"\s*:\s*"..\/..\/vendor\/three\/three.module.js"/.test(html),
    'importmap debe mapear "three" a ../../vendor/three/three.module.js');
  assert.ok(/<script[^>]*src="game-data.generated.js"/.test(html),
    'index.html debe cargar game-data.generated.js (artefacto del protocolo, window.GAME)');
  assert.ok(/<script[^>]*type="module"[^>]*src="main.mjs"/.test(html),
    'index.html debe cargar main.mjs como modulo');
});

test('engine.mjs: consume maze-core, fx-logic, three y window.GAME; pointer lock; sin dead-reckoning de reloj', () => {
  const src = read('src/game/engine.mjs');
  assert.ok(/from\s+'\.\/maze-core\.mjs'/.test(src), 'engine debe importar ./maze-core.mjs');
  assert.ok(/from\s+'\.\/fx-logic\.mjs'/.test(src), 'engine debe importar ./fx-logic.mjs');
  assert.ok(/from\s+'three'/.test(src), 'engine debe importar three (via importmap)');
  assert.ok(/requestPointerLock/.test(src), 'engine debe usar pointer lock para mirar');
  assert.ok(/export\s+function\s+startGame/.test(src), 'engine debe exportar startGame');
});

test('vhs.mjs: el tratamiento VHS declara sus efectos (scanlines, grano, tracking, timestamp, REC)', () => {
  const src = read('src/game/vhs.mjs');
  for (const token of ['scanline', 'grain', 'tracking', 'vignette']) {
    assert.ok(src.includes(token), 'vhs.mjs no menciona el efecto: ' + token);
  }
  assert.ok(/vhsTimestamp/.test(src + read('src/game/engine.mjs')),
    'el timestamp del overlay debe venir de fx-logic.vhsTimestamp');
});

test('audio.mjs: sintesis WebAudio procedural, sin assets', () => {
  const src = read('src/game/audio.mjs');
  assert.ok(/AudioContext/.test(src), 'audio.mjs debe usar Web Audio API');
  assert.ok(!/\.(mp3|ogg|wav|m4a)/i.test(src), 'audio.mjs no debe referenciar archivos de audio');
  for (const ev of ['flush', 'dryer', 'stall_noise', 'pipe_knock',
    'shower_hiss', 'door_slam', 'drain_gurgle', 'faucet_squeal']) {
    assert.ok(src.includes(ev), 'audio.mjs no maneja el evento: ' + ev);
  }
  for (const amb of ['drip', 'hum']) {
    assert.ok(src.toLowerCase().includes(amb), 'audio.mjs no implementa capa ambiental: ' + amb);
  }
});

test('engine.mjs: instancia las estructuras nuevas de variedad de salas', () => {
  const src = read('src/game/engine.mjs');
  for (const st of ['shower_unit', 'dryer_unit', 'mop_bucket', 'bench_unit']) {
    assert.ok(src.includes(st), 'engine.mjs no instancia la estructura: ' + st);
  }
});

test('determinismo de mundo: el motor no usa Math.random para el laberinto (solo seed)', () => {
  const src = read('src/game/engine.mjs');
  assert.ok(!/Math\.random\(\)/.test(src.split('\n').filter(l => /maze|chunk|generate/i.test(l)).join('\n')),
    'la generacion de mundo debe ser 100% por seed (Math.random prohibido en ese camino)');
});

test('modulos del juego previos siguen intactos y cargables', async () => {
  const maze = await import(new URL('../../src/game/maze-core.mjs', import.meta.url));
  const fx = await import(new URL('../../src/game/fx-logic.mjs', import.meta.url));
  assert.equal(typeof maze.generateChunk, 'function');
  assert.equal(typeof fx.vhsTimestamp, 'function');
});
