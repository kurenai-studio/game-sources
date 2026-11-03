// Tests CONGELADOS (oraculo del PM) para src/game/maze-core.mjs — contrato maze-core.
// NO EDITAR: sellado por tests_sha256 en knowledge/contracts/maze-core.md
import test from 'node:test';
import assert from 'node:assert/strict';

const mod = await import(new URL('../../src/game/maze-core.mjs', import.meta.url));
const { generateChunk, isWalkable, chunksInRadius, resolveMovement } = mod;

const SEED = 20260711;
const CS = 18; // chunkSize fijado por contrato (multiplo del periodo de bloque 6)
const PROP_TYPES = new Set(['stall', 'sink', 'mirror', 'urinal', 'dispenser', 'bin', 'pipes',
  'shower', 'dryer', 'mop_bucket', 'bench']);
const WALL_PROPS = new Set(['stall', 'sink', 'mirror', 'urinal', 'dispenser', 'shower', 'dryer']);

test('exports esperados', () => {
  for (const fn of [generateChunk, isWalkable, chunksInRadius, resolveMovement])
    assert.equal(typeof fn, 'function');
});

test('determinismo: mismo (seed,cx,cz) => resultado identico; distinto seed => distinto', () => {
  const a = generateChunk(SEED, 3, -2);
  const b = generateChunk(SEED, 3, -2);
  assert.deepStrictEqual(a, b);
  let differs = false;
  for (const [cx, cz] of [[0, 0], [1, 0], [0, 1], [-1, -1]]) {
    const p = generateChunk(SEED, cx, cz);
    const q = generateChunk(SEED + 1, cx, cz);
    if (JSON.stringify(p.cells) !== JSON.stringify(q.cells)) differs = true;
  }
  assert.ok(differs, 'seeds distintos deben producir algun chunk distinto');
});

test('forma del chunk: size, cells, tipos de celda validos', () => {
  const c = generateChunk(SEED, 0, 0);
  assert.equal(c.size, CS);
  assert.equal(c.cells.length, CS * CS);
  for (const v of c.cells) {
    assert.ok(Number.isInteger(v) && v >= 0 && v <= 6, 'tipo de celda 0..6, vino: ' + v);
  }
});

test('reticula de corredores: toda celda mundial con wx%6===0 o wz%6===0 es caminable', () => {
  for (const [cx, cz] of [[0, 0], [2, -1], [-3, 4]]) {
    for (let dz = 0; dz < CS; dz++) for (let dx = 0; dx < CS; dx++) {
      const wx = cx * CS + dx, wz = cz * CS + dz;
      if (((wx % 6) + 6) % 6 === 0 || ((wz % 6) + 6) % 6 === 0) {
        assert.ok(isWalkable(SEED, wx, wz), `corredor bloqueado en mundo (${wx},${wz})`);
      }
    }
  }
});

test('coherencia isWalkable <-> generateChunk (walkable = tipo != 0)', () => {
  const c = generateChunk(SEED, 1, 1);
  for (let dz = 0; dz < CS; dz++) for (let dx = 0; dx < CS; dx++) {
    const t = c.cells[dz * CS + dx];
    const w = isWalkable(SEED, 1 * CS + dx, 1 * CS + dz);
    assert.equal(w, t !== 0, `desacuerdo en celda local (${dx},${dz}) tipo=${t}`);
  }
});

test('conectividad: toda celda caminable del chunk alcanzable por BFS mundial desde la reticula', () => {
  for (const [cx, cz] of [[0, 0], [-2, 3]]) {
    const x0 = cx * CS, z0 = cz * CS;
    // ventana mundial: el chunk + 1 celda de margen (los bloques estan alineados a la reticula 6)
    const min = -1, max = CS; // offsets locales
    const key = (x, z) => x + ',' + z;
    const seen = new Set();
    const start = [x0, z0]; // (x0,z0): x0%6===0 => corredor garantizado
    assert.ok(isWalkable(SEED, start[0], start[1]));
    const q = [start]; seen.add(key(start[0], start[1]));
    while (q.length) {
      const [x, z] = q.pop();
      for (const [nx, nz] of [[x + 1, z], [x - 1, z], [x, z + 1], [x, z - 1]]) {
        if (nx - x0 < min || nx - x0 > max || nz - z0 < min || nz - z0 > max) continue;
        if (seen.has(key(nx, nz)) || !isWalkable(SEED, nx, nz)) continue;
        seen.add(key(nx, nz)); q.push([nx, nz]);
      }
    }
    const c = generateChunk(SEED, cx, cz);
    for (let dz = 0; dz < CS; dz++) for (let dx = 0; dx < CS; dx++) {
      if (c.cells[dz * CS + dx] !== 0) {
        assert.ok(seen.has(key(x0 + dx, z0 + dz)),
          `celda caminable aislada en local (${dx},${dz}) del chunk (${cx},${cz})`);
      }
    }
  }
});

test('props: tipos validos, coordenadas locales en rango, orientacion 0..3', () => {
  const c = generateChunk(SEED, 0, 0);
  assert.ok(Array.isArray(c.props));
  for (const p of c.props) {
    assert.ok(PROP_TYPES.has(p.type), 'tipo de prop desconocido: ' + p.type);
    assert.ok(Number.isInteger(p.x) && p.x >= 0 && p.x < CS);
    assert.ok(Number.isInteger(p.z) && p.z >= 0 && p.z < CS);
    assert.ok(Number.isInteger(p.rot) && p.rot >= 0 && p.rot <= 3);
  }
});

test('props de pared ocupan celda NO caminable y tienen vecino caminable; bins en celda caminable', () => {
  let wallProps = 0;
  for (const [cx, cz] of [[0, 0], [1, 0], [0, 1], [1, 1], [-1, 0], [0, -1], [-1, -1], [2, 2], [3, -3]]) {
    const c = generateChunk(SEED, cx, cz);
    for (const p of c.props) {
      const wx = cx * CS + p.x, wz = cz * CS + p.z;
      if (WALL_PROPS.has(p.type)) {
        wallProps++;
        assert.ok(!isWalkable(SEED, wx, wz), `prop de pared ${p.type} en celda caminable (${wx},${wz})`);
        const open = [[wx + 1, wz], [wx - 1, wz], [wx, wz + 1], [wx, wz - 1]]
          .some(([ax, az]) => isWalkable(SEED, ax, az));
        assert.ok(open, `prop de pared ${p.type} sin vecino caminable en (${wx},${wz})`);
      } else {
        assert.ok(isWalkable(SEED, wx, wz), `prop suelto ${p.type} en celda no caminable (${wx},${wz})`);
      }
    }
  }
  assert.ok(wallProps >= 20, 'muy pocos props de pared en 9 chunks: ' + wallProps);
});

test('densidad: fraccion caminable razonable y hay stalls, sinks y celdas inundadas en la muestra', () => {
  let walk = 0, total = 0;
  const types = new Set();
  const propTypes = new Set();
  for (let cx = -2; cx <= 2; cx++) for (let cz = -2; cz <= 2; cz++) {
    const c = generateChunk(SEED, cx, cz);
    for (const v of c.cells) { total++; if (v !== 0) { walk++; types.add(v); } }
    for (const p of c.props) propTypes.add(p.type);
  }
  const frac = walk / total;
  assert.ok(frac > 0.25 && frac < 0.85, 'fraccion caminable fuera de rango: ' + frac);
  assert.ok(types.has(4), 'sin celdas inundadas (tipo 4) en 25 chunks');
  assert.ok(types.has(5), 'sin salas de duchas (tipo 5) en 25 chunks');
  assert.ok(types.has(6), 'sin cuartos de limpieza/vestuario (tipo 6) en 25 chunks');
  for (const t of ['stall', 'sink', 'bin', 'shower', 'dryer', 'mop_bucket', 'bench'])
    assert.ok(propTypes.has(t), 'falta prop: ' + t);
});

test('lights y puddles: en celdas caminables, al menos 1 luz por chunk, radio de charco en rango', () => {
  for (const [cx, cz] of [[0, 0], [2, -1]]) {
    const c = generateChunk(SEED, cx, cz);
    assert.ok(c.lights.length >= 1, 'chunk sin luces');
    for (const l of c.lights) {
      assert.ok(isWalkable(SEED, cx * CS + l.x, cz * CS + l.z), 'luz sobre celda no caminable');
    }
    assert.ok(c.puddles.length >= 1, 'chunk sin charcos');
    for (const p of c.puddles) {
      assert.ok(isWalkable(SEED, cx * CS + p.x, cz * CS + p.z), 'charco sobre celda no caminable');
      assert.ok(p.r > 0.15 && p.r <= 0.6, 'radio de charco fuera de rango: ' + p.r);
    }
  }
});

test('chunksInRadius: incluye chunk central, cubre el radio, ordenado y determinista', () => {
  const r1 = chunksInRadius(9.5, 9.5, 1);
  const r2 = chunksInRadius(9.5, 9.5, 1);
  assert.deepStrictEqual(r1, r2);
  const has = (cx, cz) => r1.some(c => c.cx === cx && c.cz === cz);
  assert.ok(has(0, 0), 'falta el chunk central');
  for (const [cx, cz] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) assert.ok(has(cx, cz), `falta vecino (${cx},${cz})`);
  for (const c of r1) assert.ok(Math.abs(c.cx) <= 2 && Math.abs(c.cz) <= 2, 'chunk fuera de radio+1');
});

// helper: el disco de radio r alrededor de pos esta contenido en celdas caminables
function posClear(seed, pos, radius) {
  for (const [ox, oz] of [[radius, 0], [-radius, 0], [0, radius], [0, -radius],
    [radius * 0.71, radius * 0.71], [-radius * 0.71, radius * 0.71],
    [radius * 0.71, -radius * 0.71], [-radius * 0.71, -radius * 0.71]]) {
    if (!isWalkable(seed, Math.floor(pos.x + ox), Math.floor(pos.z + oz))) return false;
  }
  return true;
}

test('resolveMovement: nunca termina dentro de pared, sin tunel, y desliza por el eje libre', () => {
  const R = 0.3;
  // punto de partida garantizado: centro de una celda de corredor de la reticula
  const start = { x: 0.5, z: 0.5 }; // celda mundial (0,0): 0%6===0 => caminable
  assert.ok(isWalkable(SEED, 0, 0));

  // delta cero => misma posicion
  const still = resolveMovement(SEED, start, { x: 0, z: 0 }, R);
  assert.ok(Math.abs(still.x - start.x) < 1e-9 && Math.abs(still.z - start.z) < 1e-9);

  // busca una pared adyacente a un corredor para probar colision
  let wall = null, from = null;
  outer: for (let wz = -12; wz <= 12; wz++) for (let wx = -12; wx <= 12; wx++) {
    if (!isWalkable(SEED, wx, wz) && isWalkable(SEED, wx - 1, wz)) { wall = [wx, wz]; from = [wx - 1, wz]; break outer; }
  }
  assert.ok(wall, 'no se encontro pareja pared/corredor en la ventana (¿todo caminable?)');

  const p0 = { x: from[0] + 0.5, z: from[1] + 0.5 };
  // empuje directo contra la pared con delta grande (3 celdas): no atraviesa
  const p1 = resolveMovement(SEED, p0, { x: 3, z: 0 }, R);
  assert.ok(posClear(SEED, p1, R), 'termino con el radio invadiendo pared');
  assert.ok(p1.x < wall[0] + 0.01, 'atraveso la pared (tunel)');

  // movimiento diagonal contra la pared: debe avanzar por el eje libre si esta despejado
  if (isWalkable(SEED, from[0], from[1] + 1)) {
    const p2 = resolveMovement(SEED, p0, { x: 1.5, z: 0.6 }, R);
    assert.ok(posClear(SEED, p2, R));
    assert.ok(p2.z > p0.z + 0.1, 'no deslizo por el eje libre');
  }
});
