// maze-core — nucleo determinista del laberinto infinito de "The Bathrooms".
// ESM puro, cero dependencias, sin DOM, sin Math.random ni Date.now.
// Contrato: knowledge/contracts/maze-core.md

const DEFAULT_SIZE = 18; // multiplo del periodo de bloque (6)
const PERIOD = 6;        // toda celda con wx%6===0 o wz%6===0 es corredor
const SKIN = 1e-3;       // holgura de colision para que el disco no toque la pared

// --- utilidades puras -------------------------------------------------------

function mod(n, m) { return ((n % m) + m) % m; }

// hash entero determinista de (seed, a, b) -> uint32
function hash3(seed, a, b) {
  let h = (seed | 0) ^ 0x9e3779b9;
  h = Math.imul(h ^ (a | 0), 0x85ebca6b);
  h ^= h >>> 13;
  h = Math.imul(h ^ (b | 0), 0xc2b2ae35);
  h ^= h >>> 16;
  h = Math.imul(h ^ 0x27d4eb2d, 0x165667b1);
  h ^= h >>> 15;
  return h >>> 0;
}

// clasifica el bloque 5x5 (bx,bz) de forma determinista.
// kind -> layout de celdas (ver cellTypeAt):
//   solid=macizo/pared, open=pasillo, cubicle=cubiculos, sinkroom=lavabos,
//   flooded=inundado, shower=sala de duchas (tipo 5), locker=cuarto limpieza/vestuario (tipo 6).
function classifyBlock(seed, bx, bz) {
  const h = hash3(seed, bx, bz);
  const sel = h % 24;
  let kind;
  if (sel <= 7) kind = 'solid';          // 33% macizo (paredes con props)
  else if (sel <= 10) kind = 'cubicle';  // sala de cubiculos (tipo 2)
  else if (sel <= 13) kind = 'sinkroom'; // sala de lavabos (tipo 3)
  else if (sel <= 15) kind = 'flooded';  // inundada (tipo 4)
  else if (sel <= 17) kind = 'open';     // pasillo abierto (tipo 1)
  else if (sel <= 20) kind = 'shower';   // sala de duchas (tipo 5)
  else kind = 'locker';                  // cuarto limpieza/vestuario (tipo 6)
  const style = ((h / 24) | 0) % 4;
  return { h, kind, style };
}

// tipo de la celda interior (ox,oz en 1..5, = mod(w,PERIOD)) segun el kind del bloque.
// Las salas de duchas dejan el muro -z (oz===1) macizo para colgar las duchas.
function cellTypeAt(kind, ox, oz) {
  switch (kind) {
    case 'solid': return 0;
    case 'cubicle': return 2;
    case 'sinkroom': return 3;
    case 'flooded': return 4;
    case 'shower': return oz === 1 ? 0 : 5;
    case 'locker': return 6;
    default: return 1; // open
  }
}

// tipo de celda mundial (entero). Fuente de verdad de caminabilidad.
function worldCell(seed, wx, wz) {
  if (mod(wx, PERIOD) === 0 || mod(wz, PERIOD) === 0) return 1; // reticula de corredores
  const bx = Math.floor(wx / PERIOD);
  const bz = Math.floor(wz / PERIOD);
  return cellTypeAt(classifyBlock(seed, bx, bz).kind, mod(wx, PERIOD), mod(wz, PERIOD));
}

// --- API --------------------------------------------------------------------

export function isWalkable(seed, wx, wz) {
  return worldCell(seed | 0, Math.floor(wx), Math.floor(wz)) !== 0;
}

export function generateChunk(seed, cx, cz, opts) {
  seed = seed | 0; cx = cx | 0; cz = cz | 0;
  const size = (opts && opts.chunkSize) || DEFAULT_SIZE;

  const cells = new Array(size * size);
  for (let dz = 0; dz < size; dz++) {
    for (let dx = 0; dx < size; dx++) {
      cells[dz * size + dx] = worldCell(seed, cx * size + dx, cz * size + dz);
    }
  }

  const props = [];
  const lights = [{ x: 0, z: 0 }];              // luz garantizada sobre corredor (0,0)
  const puddles = [{ x: PERIOD, z: 0, r: 0.35 }]; // charco garantizado sobre corredor

  const nb = Math.floor(size / PERIOD); // bloques por eje dentro del chunk
  for (let jz = 0; jz < nb; jz++) {
    for (let jx = 0; jx < nb; jx++) {
      const bx = cx * nb + jx;
      const bz = cz * nb + jz;
      fillBlock(seed, bx, bz, jx * PERIOD, jz * PERIOD, props, lights, puddles);
    }
  }

  return { cx, cz, size, cells, props, lights, puddles };
}

// genera props/luces/charcos de un bloque; baseX/baseZ = origen local del bloque.
function fillBlock(seed, bx, bz, baseX, baseZ, props, lights, puddles) {
  const info = classifyBlock(seed, bx, bz);
  const cx = baseX + 3, cz = baseZ + 3; // centro local del bloque
  if (info.kind === 'solid') {
    // fila contigua de props de pared a lo largo del muro -z (celdas NO caminables,
    // frente hacia el corredor en -z => rot 2). Estilo variable por bloque.
    for (let lx = 1; lx <= 5; lx++) {
      const type = wallPropType(info.style, lx);
      props.push({ x: baseX + lx, z: baseZ + 1, type, rot: 2 });
    }
    return;
  }
  if (info.kind === 'shower') {
    // duchas en fila sobre el muro -z (oz===1, NO caminable), frente +z (rot 0)
    // hacia la sala tipo 5 caminable. Un banco de vestuario suelto en la sala.
    for (let lx = 1; lx <= 5; lx++) {
      props.push({ x: baseX + lx, z: baseZ + 1, type: 'shower', rot: 0 });
    }
    lights.push({ x: cx, z: cz });
    props.push({ x: baseX + 2, z: baseZ + 3, type: 'bench', rot: 0 });
    return;
  }
  // salas caminables: luz al centro, y props sueltos sobre celdas caminables.
  lights.push({ x: cx, z: cz });
  if (info.kind === 'flooded') {
    const r = 0.2 + (info.h % 40) / 100; // (0.15, 0.6]
    puddles.push({ x: cx, z: cz, r });
    puddles.push({ x: baseX + 2, z: baseZ + 2, r: 0.25 });
    return;
  }
  if (info.kind === 'locker') {
    // cuarto de limpieza/vestuario: cubo de fregona y banco (sueltos, sobre tipo 6).
    props.push({ x: baseX + 2, z: baseZ + 2, type: 'mop_bucket', rot: 0 });
    props.push({ x: cx, z: cz, type: 'bench', rot: 0 });
    return;
  }
  props.push({ x: cx, z: cz, type: 'bin', rot: 0 });
  if (info.kind === 'open') props.push({ x: baseX + 2, z: baseZ + 2, type: 'pipes', rot: 0 });
}

function wallPropType(style, lx) {
  if (style === 0) return 'stall';
  // muro de lavabos: espejos y lavabos apareados, con un secador mural (dryer) al centro.
  if (style === 1) return lx === 3 ? 'dryer' : (lx % 2 === 0 ? 'sink' : 'mirror');
  if (style === 2) return 'urinal';
  return 'dispenser';
}

export function chunksInRadius(px, pz, r, opts) {
  const size = (opts && opts.chunkSize) || DEFAULT_SIZE;
  const centerCx = Math.floor(px / size);
  const centerCz = Math.floor(pz / size);
  const R = Math.max(0, Math.ceil(r));
  const out = [];
  for (let dz = -R; dz <= R; dz++) {
    for (let dx = -R; dx <= R; dx++) {
      out.push({ cx: centerCx + dx, cz: centerCz + dz });
    }
  }
  return out;
}

// --- colision ---------------------------------------------------------------

// ¿el disco (centro x,z, radio R) invade alguna celda no caminable?
function diskHitsWall(seed, x, z, R) {
  const minX = Math.floor(x - R), maxX = Math.floor(x + R);
  const minZ = Math.floor(z - R), maxZ = Math.floor(z + R);
  for (let cz = minZ; cz <= maxZ; cz++) {
    for (let cx = minX; cx <= maxX; cx++) {
      if (worldCell(seed, cx, cz) !== 0) continue; // caminable
      const nx = Math.max(cx, Math.min(x, cx + 1));
      const nz = Math.max(cz, Math.min(z, cz + 1));
      const ddx = x - nx, ddz = z - nz;
      if (ddx * ddx + ddz * ddz < R * R) return true;
    }
  }
  return false;
}

// desliza sobre un solo eje por sub-pasos (evita tunel) dejando holgura SKIN.
function slideAxis(seed, x, z, d, R, isX) {
  let cur = isX ? x : z;
  if (d === 0) return cur;
  const other = isX ? z : x;
  const guard = R + SKIN;
  const stepLen = Math.max(1e-3, R * 0.5);
  const steps = Math.max(1, Math.ceil(Math.abs(d) / stepLen));
  const inc = d / steps;
  for (let i = 0; i < steps; i++) {
    const next = cur + inc;
    const nx = isX ? next : other;
    const nz = isX ? other : next;
    if (diskHitsWall(seed, nx, nz, guard)) break;
    cur = next;
  }
  return cur;
}

export function resolveMovement(seed, pos, delta, radius, opts) {
  seed = seed | 0;
  const R = radius;
  let x = pos.x, z = pos.z;
  x = slideAxis(seed, x, z, delta.x, R, true);  // primero X
  z = slideAxis(seed, x, z, delta.z, R, false); // luego Z (deslizamiento)
  return { x, z };
}
