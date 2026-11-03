// Tests CONGELADOS (oraculo del PM) para src/game/GAME.md — contrato game-md-bathrooms.
// NO EDITAR: sellado por tests_sha256 en knowledge/contracts/game-md-bathrooms.md
// Precondicion del test_command: game-lint en verde y game-export ya corrido sobre GAME.md.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const genPath = fileURLToPath(new URL('../../src/game/game-data.generated.js', import.meta.url));
const code = readFileSync(genPath, 'utf8');
const win = {};
new Function('window', code)(win);
const GAME = win.GAME;

const REQUIRED_MATERIALS = ['TILE_WALL', 'TILE_FLOOR', 'GROUT', 'STALL', 'PORCELAIN',
  'MIRROR', 'WATER', 'MOLD', 'GRIME', 'CEILING', 'LIGHT_ON', 'LIGHT_DEAD', 'PAPER'];
const REQUIRED_STRUCTURES = ['stall_unit', 'sink_unit', 'urinal_unit', 'toilet_unit',
  'bin_full', 'dispenser_empty', 'light_fixture',
  'shower_unit', 'dryer_unit', 'mop_bucket', 'bench_unit'];

test('artefacto generado: perfil voxel y titulo del juego', () => {
  assert.ok(GAME, 'window.GAME no definido por el artefacto');
  assert.equal(GAME.profile, 'voxel');
  assert.equal(GAME.name, 'The Bathrooms');
});

test('materiales: los requeridos existen y todo color es RGB valido', () => {
  const mats = GAME.MATERIALS || {};
  for (const m of REQUIRED_MATERIALS) assert.ok(mats[m], 'falta material: ' + m);
  const names = Object.keys(mats);
  assert.ok(names.length >= 13, 'paleta muy corta: ' + names.length);
  for (const [n, m] of Object.entries(mats)) {
    assert.ok(Array.isArray(m.color) && m.color.length === 3, 'color invalido en ' + n);
    for (const v of m.color) assert.ok(Number.isInteger(v) && v >= 0 && v <= 255, 'canal invalido en ' + n);
  }
});

test('estructuras voxel: las requeridas existen, no vacias y con bounds acotados', () => {
  const vox = GAME.VOXELS || {};
  for (const s of REQUIRED_STRUCTURES) {
    const st = vox[s];
    assert.ok(st, 'falta estructura voxel: ' + s);
    assert.ok(st.count > 0, 'estructura vacia: ' + s);
    assert.ok(st.bounds, 'sin bounds: ' + s);
    for (const axis of [0, 1, 2]) {
      assert.ok(st.bounds.max[axis] - st.bounds.min[axis] < 24,
        `estructura ${s} demasiado grande en eje ${axis} (voxel=0.25m, celda=8 voxeles)`);
    }
  }
});

test('estructuras voxel: todo material referenciado existe en MATERIALS', () => {
  const mats = GAME.MATERIALS || {};
  for (const [name, st] of Object.entries(GAME.VOXELS || {})) {
    for (const v of st.voxels) assert.ok(mats[v.m], `estructura ${name} usa material inexistente ${v.m}`);
  }
});

test('platform: knobs de mundo requeridos con valores sanos', () => {
  const p = GAME.platform || {};
  assert.equal(p.chunkSize, 18, 'chunkSize debe ser 18 (multiplo del periodo de bloque 6)');
  assert.equal(p.cellSize, 2, 'cellSize debe ser 2 (metros por celda)');
  assert.ok(p.wallHeight >= 2.5 && p.wallHeight <= 4, 'wallHeight fuera de [2.5,4]');
  assert.ok(p.playerSpeed > 0 && p.playerSpeed <= 8, 'playerSpeed fuera de (0,8]');
  assert.ok(p.playerRadius > 0.1 && p.playerRadius < 0.5, 'playerRadius fuera de (0.1,0.5)');
  assert.ok(Number.isInteger(p.viewChunks) && p.viewChunks >= 1 && p.viewChunks <= 3, 'viewChunks fuera de [1,3]');
  assert.ok(p.eyeHeight >= 1.4 && p.eyeHeight <= 1.8, 'eyeHeight fuera de [1.4,1.8]');
});

test('platform.audio: distancias de atenuacion coherentes', () => {
  const a = (GAME.platform || {}).audio || {};
  assert.ok(a.refDist > 0, 'audio.refDist debe ser > 0');
  assert.ok(a.maxDist > a.refDist, 'audio.maxDist debe ser > refDist');
  assert.ok(a.maxDist <= 60, 'audio.maxDist excesivo (> 60m)');
});

test('platform.texts: textos del juego presentes', () => {
  const t = (GAME.platform || {}).texts || {};
  assert.equal(t.title, 'The Bathrooms');
  assert.equal(t.rec, 'REC');
  assert.ok(typeof t.hint === 'string' && t.hint.length >= 10, 'hint ausente o muy corto');
});
