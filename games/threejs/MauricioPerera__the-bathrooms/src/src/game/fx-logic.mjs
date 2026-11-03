// src/game/fx-logic.mjs — contrato fx-logic.
// Logica pura y determinista: timestamp VHS, luces fluorescentes, atenuacion y
// scheduler componible de eventos ambientales. ESM puro, cero dependencias, sin
// Math.random / Date.now / DOM / estado mutable de modulo.

const MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
const TWO_PI = Math.PI * 2;

// --- helper de hash entero compartido (mezcla estilo FNV + finalizador) -----
function hashMix(...nums) {
  let h = 2166136261 >>> 0;
  for (const n of nums) {
    h ^= (n >>> 0);
    h = Math.imul(h, 16777619);
    h ^= h >>> 13;
  }
  h = Math.imul(h ^ (h >>> 15), 0x5bd1e995);
  return (h ^ (h >>> 15)) >>> 0;
}

// float determinista en [0,1) a partir de enteros
function hashFloat(...nums) {
  return hashMix(...nums) / 4294967296;
}

const pad2 = (n) => String(n).padStart(2, '0');

// --- vhsTimestamp -----------------------------------------------------------
export function vhsTimestamp(epochMs) {
  const d = new Date(epochMs); // los milisegundos truncan al leer solo H:M:S
  const date = MONTHS[d.getUTCMonth()] + '.' + d.getUTCDate() + ' ' + d.getUTCFullYear();
  const time = pad2(d.getUTCHours()) + ':' + pad2(d.getUTCMinutes()) + ':' + pad2(d.getUTCSeconds());
  return { date, time };
}

// --- lightState -------------------------------------------------------------
function lightMode(seed, id) {
  const r = hashFloat(seed, id, 1);
  if (r < 0.2) return 'dead';       // ~40 / 200  -> [10,70]
  if (r < 0.55) return 'flicker';   // ~70 / 200  -> [20,100]
  return 'steady';                  // ~90 / 200  -> >= 60
}

export function lightState(seed, id, timeMs) {
  const mode = lightMode(seed, id);
  if (mode === 'dead') return { mode, intensity: 0 };
  if (mode === 'steady') {
    const intensity = 0.8 + hashFloat(seed, id, 2) * 0.19; // [0.80, 0.99), constante
    return { mode, intensity };
  }
  // flicker: varia con timeMs, toca < 0.3 y > 0.6 en cualquier ventana de ~20s
  const phase = hashFloat(seed, id, 3) * TWO_PI;
  const w = 0.006 + hashFloat(seed, id, 4) * 0.02; // rad/ms -> periodo ~262..1047ms
  let v = 0.5 + 0.42 * Math.sin(timeMs * w + phase)
    + 0.12 * Math.sin(timeMs * w * 2.3 + phase * 1.7);
  if (v < 0) v = 0;
  else if (v > 1) v = 1;
  return { mode: 'flicker', intensity: v };
}

// --- attenuation ------------------------------------------------------------
export function attenuation(dist, refDist, maxDist) {
  if (dist <= refDist) return 1;
  if (dist >= maxDist) return 0;
  return (maxDist - dist) / (maxDist - refDist); // lineal, monotona no creciente
}

// --- scheduleAmbientEvents --------------------------------------------------
const EVENT_TYPES = ['flush', 'dryer', 'stall_noise', 'pipe_knock',
  'shower_hiss', 'door_slam', 'drain_gurgle', 'faucet_squeal'];
const SLOT_MS = 10000; // reticula fija de 10s -> 60 eventos/10min, 180/30min

export function scheduleAmbientEvents(seed, t0, t1) {
  const events = [];
  const firstSlot = Math.floor(t0 / SLOT_MS);
  const lastSlot = Math.ceil(t1 / SLOT_MS);
  for (let slot = firstSlot; slot <= lastSlot; slot++) {
    const base = slot * SLOT_MS;
    const t = base + Math.floor(hashFloat(seed, slot, 10) * SLOT_MS); // dentro del slot
    if (t < t0 || t >= t1) continue;
    events.push({
      t,
      type: EVENT_TYPES[hashMix(seed, slot, 11) % EVENT_TYPES.length],
      dx: (hashFloat(seed, slot, 12) * 2 - 1) * 20,
      dz: (hashFloat(seed, slot, 13) * 2 - 1) * 20,
    });
  }
  return events; // ya ordenados por t (offset < SLOT_MS, slots crecientes)
}
