/**
 * Generador de mapas de Imperios 1800–2100.
 *
 * El orden de las etapas importa tanto como las fórmulas: primero la roca
 * (fbm de continente + cordilleras ridged + escalones worley), después el agua
 * la esculpe (erosión hidráulica por transporte de sedimento) y recién ahí se
 * decide dónde vive cada cosa. Al revés salen mapas que parecen ruido pintado
 * de verde: sin valles en V, sin llanuras de sedimento, sin crestas afiladas.
 *
 * Todo sale de ctx.rng / ctx.ruido, así que la misma semilla da exactamente el
 * mismo mapa en cualquier máquina y una partida se puede compartir por número.
 */
import { RNG, Ruido, clamp, lerp, smoothstep } from '../core/RNG.js';
import { TIPO, ESTADO } from '../core/World.js';
import { NODOS, NODO_POR_CLAVE, IDX_RECURSO } from '../data/recursos.js';
import { EDIFICIOS, EDIFICIO_POR_CLAVE } from '../data/edificios.js';
import { UNIDADES, UNIDAD_POR_CLAVE } from '../data/unidades.js';
import { COLORES_JUGADOR } from '../data/civilizaciones.js';

export const TIPOS_BIOMA = ['pradera', 'bosque', 'montana', 'desierto', 'playa', 'agua'];

/** Índices de TIPOS_BIOMA, para no escribir strings en bucles de 260k celdas. */
export const B = { PRADERA: 0, BOSQUE: 1, MONTANA: 2, DESIERTO: 3, PLAYA: 4, AGUA: 5 };

/** Resolución fija del campo de alturas: 513 = 512 celdas + 1 vértice de cierre. */
const RES = 513;
const NIVEL_AGUA = 0;

export const TIPOS_MAPA = [
  { clave: 'arabia', nombre: 'Arabia',
    descripcion: 'Seco y abierto: poca madera, mucho oro y ninguna excusa. El clásico de torneo.' },
  { clave: 'tierras_negras', nombre: 'Tierras Negras',
    descripcion: 'Cada jugador en su lengua de tierra. Todo pasa por el único puente central.' },
  { clave: 'islas', nombre: 'Archipiélago',
    descripcion: 'Una isla por imperio. El que domina el agua dicta cuándo empieza la guerra.' },
  { clave: 'rio_grande', nombre: 'Río Grande',
    descripcion: 'Un río ancho parte el mapa en dos. Solo se cruza a pie por dos vados.' },
  { clave: 'fortaleza', nombre: 'Fortaleza',
    descripcion: 'Cada base nace rodeada de acantilados con una sola entrada. Se juega al asedio.' },
  { clave: 'valle_alpino', nombre: 'Valle Alpino',
    descripcion: 'Montañas nevadas, bosque denso y pasos estrechos donde diez hombres frenan a cien.' },
  { clave: 'mediterraneo', nombre: 'Mediterráneo',
    descripcion: 'Un mar interior con todos los imperios en su orilla. Comercio, pesca y desembarcos.' },
];

/**
 * Parámetros por tipo de mapa. Acá vive el balance: relieve, sequedad, cuánta
 * madera hay tirada y cuánto oro, que es lo que decide el ritmo de la partida.
 */
const PERFILES = {
  arabia: {
    relieve: 0.62, cordillera: 0.34, meseta: 1.0, humedad: -0.30, alturaMontana: 27,
    borde: 'continente', radioInicio: 0.315, rios: 2, nieve: false,
    densidadBosque: 0.38, densidadOro: 1.65, densidadCarbon: 1.2, densidadPez: 0.5,
    radioBusqueda: 55,
  },
  tierras_negras: {
    relieve: 0.70, cordillera: 0.20, meseta: 0.4, humedad: 0.18, alturaMontana: 30,
    borde: 'lenguas', radioInicio: 0.335, rios: 0, nieve: false,
    densidadBosque: 1.15, densidadOro: 0.9, densidadCarbon: 1.0, densidadPez: 1.6,
    radioBusqueda: 16,
  },
  islas: {
    relieve: 0.72, cordillera: 0.30, meseta: 0.5, humedad: 0.26, alturaMontana: 28,
    borde: 'islas', radioInicio: 0.315, rios: 0, nieve: false,
    densidadBosque: 0.95, densidadOro: 1.0, densidadCarbon: 0.9, densidadPez: 2.2,
    radioBusqueda: 15,
  },
  rio_grande: {
    relieve: 0.66, cordillera: 0.28, meseta: 0.7, humedad: 0.06, alturaMontana: 28,
    borde: 'continente', radioInicio: 0.30, rios: 1, nieve: false,
    densidadBosque: 0.75, densidadOro: 1.1, densidadCarbon: 1.0, densidadPez: 1.5,
    radioBusqueda: 34,
  },
  fortaleza: {
    relieve: 0.58, cordillera: 0.26, meseta: 0.8, humedad: -0.02, alturaMontana: 26,
    borde: 'continente', radioInicio: 0.325, rios: 2, nieve: false,
    densidadBosque: 0.80, densidadOro: 1.15, densidadCarbon: 1.05, densidadPez: 0.7,
    radioBusqueda: 12,
  },
  valle_alpino: {
    relieve: 1.35, cordillera: 1.15, meseta: 0.3, humedad: 0.24, alturaMontana: 30,
    borde: 'continente', radioInicio: 0.325, rios: 4, nieve: true,
    densidadBosque: 1.30, densidadOro: 0.95, densidadCarbon: 1.35, densidadPez: 0.8,
    radioBusqueda: 58,
  },
  mediterraneo: {
    relieve: 0.68, cordillera: 0.40, meseta: 0.8, humedad: 0.12, alturaMontana: 27,
    borde: 'mar_interior', radioInicio: 0.345, rios: 3, nieve: false,
    densidadBosque: 0.85, densidadOro: 1.15, densidadCarbon: 1.0, densidadPez: 2.0,
    radioBusqueda: 46,
  },
};

/* ═══════════════════════ utilidades de rejilla ═══════════════════════ */

function crearRejilla(tam) {
  const res = RES;
  return { res, tam, paso: tam / (res - 1), mitad: tam / 2 };
}

/** Muestreo bilineal de cualquier campo escalar del mapa. */
function muestrear(campo, rej, x, z) {
  const fx = clamp((x + rej.mitad) / rej.paso, 0, rej.res - 1.0001);
  const fz = clamp((z + rej.mitad) / rej.paso, 0, rej.res - 1.0001);
  const i = fx | 0, j = fz | 0;
  const tx = fx - i, tz = fz - j;
  const o = j * rej.res + i;
  const a = campo[o], b = campo[o + 1];
  const c = campo[o + rej.res], d = campo[o + rej.res + 1];
  return lerp(lerp(a, b, tx), lerp(c, d, tx), tz);
}

/** Muestreo por vecino más cercano: para campos discretos (bioma). */
function muestrearNN(campo, rej, x, z) {
  const i = clamp(Math.round((x + rej.mitad) / rej.paso), 0, rej.res - 1);
  const j = clamp(Math.round((z + rej.mitad) / rej.paso), 0, rej.res - 1);
  return campo[j * rej.res + i];
}

function mezclar(rng, arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(rng.float(0, i + 1)) % (i + 1);
    const t = arr[i]; arr[i] = arr[j]; arr[j] = t;
  }
  return arr;
}

/** Diferencia angular con signo en (-π, π]. */
function deltaAngulo(a, b) {
  let d = (a - b) % (Math.PI * 2);
  if (d > Math.PI) d -= Math.PI * 2;
  if (d < -Math.PI) d += Math.PI * 2;
  return d;
}

/** Distancia de un punto al segmento AB, más la proyección normalizada 0..1. */
function distSegmento(px, pz, ax, az, bx, bz) {
  const vx = bx - ax, vz = bz - az;
  const len2 = vx * vx + vz * vz || 1e-6;
  let t = ((px - ax) * vx + (pz - az) * vz) / len2;
  t = t < 0 ? 0 : t > 1 ? 1 : t;
  const dx = px - (ax + vx * t), dz = pz - (az + vz * t);
  return [Math.sqrt(dx * dx + dz * dz), t];
}

/**
 * Reserva de espacio compartida entre todas las pasadas de siembra. Sin esto,
 * un bosque y una veta de oro se pisan y quedan dos mallas encimadas.
 */
class Ocupacion {
  constructor(celda = 8) {
    this.celda = celda;
    this.mapa = new Map();
    this.rMax = 0;
  }
  _clave(i, j) { return ((i & 0xffff) << 16) | (j & 0xffff); }
  libre(x, z, r) {
    const c = this.celda;
    const alcance = Math.ceil((r + this.rMax) / c);
    const ci = Math.floor(x / c), cj = Math.floor(z / c);
    for (let oj = -alcance; oj <= alcance; oj++) {
      for (let oi = -alcance; oi <= alcance; oi++) {
        const lista = this.mapa.get(this._clave(ci + oi, cj + oj));
        if (!lista) continue;
        for (let n = 0; n < lista.length; n += 3) {
          const dx = lista[n] - x, dz = lista[n + 1] - z;
          const min = r + lista[n + 2];
          if (dx * dx + dz * dz < min * min) return false;
        }
      }
    }
    return true;
  }
  marcar(x, z, r) {
    const c = this.celda;
    const k = this._clave(Math.floor(x / c), Math.floor(z / c));
    let lista = this.mapa.get(k);
    if (!lista) { lista = []; this.mapa.set(k, lista); }
    lista.push(x, z, r);
    if (r > this.rMax) this.rMax = r;
  }
  fusionar(otra) {
    for (const lista of otra.mapa.values()) {
      for (let n = 0; n < lista.length; n += 3) this.marcar(lista[n], lista[n + 1], lista[n + 2]);
    }
  }
}

/** Montículo binario mínimo sobre arrays tipados: lo usa el relleno de cuencas. */
class MonticuloMin {
  constructor(cap) {
    this.claves = new Float32Array(cap);
    this.vals = new Int32Array(cap);
    this.n = 0;
    this.claveUlt = 0;
  }
  push(k, v) {
    let i = this.n++;
    const cl = this.claves, va = this.vals;
    cl[i] = k; va[i] = v;
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (cl[p] <= cl[i]) break;
      const tk = cl[p]; cl[p] = cl[i]; cl[i] = tk;
      const tv = va[p]; va[p] = va[i]; va[i] = tv;
      i = p;
    }
  }
  pop() {
    const cl = this.claves, va = this.vals;
    const salida = va[0];
    this.claveUlt = cl[0];
    const n = --this.n;
    cl[0] = cl[n]; va[0] = va[n];
    let i = 0;
    for (;;) {
      const a = i * 2 + 1, b = a + 1;
      let m = i;
      if (a < n && cl[a] < cl[m]) m = a;
      if (b < n && cl[b] < cl[m]) m = b;
      if (m === i) break;
      const tk = cl[m]; cl[m] = cl[i]; cl[i] = tk;
      const tv = va[m]; va[m] = va[i]; va[i] = tv;
      i = m;
    }
    return salida;
  }
}

/**
 * Muestreo de Poisson-disk (Bridson) con predicado de aceptación. Es lo que
 * evita que los recursos se lean como una grilla: hay separación mínima
 * garantizada pero la posición exacta nunca es previsible.
 *
 * Como el predicado puede partir el dominio en islas inconexas, se resiembra
 * el frente activo muchas veces en vez de crecer desde un único punto.
 */
function poissonDisk(rng, { x0, z0, ancho, alto, radio, aceptar, maxPuntos = 6000, k = 20, semillas = 900 }) {
  const celda = radio / Math.SQRT2;
  const cols = Math.max(1, Math.ceil(ancho / celda));
  const filas = Math.max(1, Math.ceil(alto / celda));
  const rejilla = new Int32Array(cols * filas).fill(-1);
  const px = [], pz = [], activos = [];
  const r2 = radio * radio;

  const libre = (x, z) => {
    const ci = Math.floor((x - x0) / celda), cj = Math.floor((z - z0) / celda);
    if (ci < 0 || cj < 0 || ci >= cols || cj >= filas) return false;
    for (let oj = -2; oj <= 2; oj++) {
      const jj = cj + oj;
      if (jj < 0 || jj >= filas) continue;
      for (let oi = -2; oi <= 2; oi++) {
        const ii = ci + oi;
        if (ii < 0 || ii >= cols) continue;
        const idx = rejilla[jj * cols + ii];
        if (idx < 0) continue;
        const dx = px[idx] - x, dz = pz[idx] - z;
        if (dx * dx + dz * dz < r2) return false;
      }
    }
    return true;
  };
  const empujar = (x, z) => {
    const idx = px.length;
    px.push(x); pz.push(z);
    const ci = Math.floor((x - x0) / celda), cj = Math.floor((z - z0) / celda);
    rejilla[cj * cols + ci] = idx;
    activos.push(idx);
  };

  for (let s = 0; s < semillas && px.length < maxPuntos; s++) {
    const sx = rng.float(x0, x0 + ancho), sz = rng.float(z0, z0 + alto);
    if (!libre(sx, sz) || !aceptar(sx, sz)) continue;
    empujar(sx, sz);
    while (activos.length && px.length < maxPuntos) {
      const ai = Math.floor(rng.float(0, activos.length)) % activos.length;
      const idx = activos[ai];
      let colocado = false;
      for (let t = 0; t < k; t++) {
        const ang = rng.float(0, Math.PI * 2);
        const rad = radio * (1 + rng.float(0, 1));
        const nx = px[idx] + Math.cos(ang) * rad;
        const nz = pz[idx] + Math.sin(ang) * rad;
        if (nx < x0 || nz < z0 || nx >= x0 + ancho || nz >= z0 + alto) continue;
        if (!libre(nx, nz) || !aceptar(nx, nz)) continue;
        empujar(nx, nz);
        colocado = true;
        break;
      }
      if (!colocado) { activos[ai] = activos[activos.length - 1]; activos.pop(); }
    }
  }

  const salida = new Array(px.length);
  for (let i = 0; i < px.length; i++) salida[i] = { x: px[i], z: pz[i] };
  return salida;
}

/**
 * Espiral de ángulo áureo para reacomodar un nodo que cayó en un lugar inválido.
 * Cubre el disco de forma pareja sin repetir direcciones, así el reacomodo es
 * mínimo y la simetría entre jugadores casi no se resiente.
 */
function acomodar(x, z, valido, rMax = 12, pasos = 48) {
  if (valido(x, z)) return { x, z };
  for (let s = 1; s <= pasos; s++) {
    const r = (s / pasos) * rMax;
    const a = s * 2.39996323;
    const nx = x + Math.cos(a) * r, nz = z + Math.sin(a) * r;
    if (valido(nx, nz)) return { x: nx, z: nz };
  }
  return null;
}

/* ═══════════════════════ 1. la roca ═══════════════════════ */

/**
 * Disposición ideal de las bases antes de conocer el terreno. Algunos tipos de
 * mapa esculpen la tierra alrededor de estos puntos, así que se calculan primero.
 */
function disposicionInicios(tipo, jugadores, tam, perfil, rng) {
  const radio = tam * perfil.radioInicio;
  const inicios = [];
  if (tipo === 'rio_grande') {
    // Dos columnas paralelas al cauce: nadie arranca con el río encima.
    const porLado = Math.ceil(jugadores / 2);
    for (let p = 0; p < jugadores; p++) {
      const lado = p % 2 === 0 ? 1 : -1;
      const fila = Math.floor(p / 2);
      const t = porLado === 1 ? 0.5 : fila / (porLado - 1);
      inicios.push({
        jugador: p, x: lado * radio, z: lerp(-tam * 0.26, tam * 0.26, t),
        ang: lado > 0 ? 0 : Math.PI, y: 0,
      });
    }
    return inicios;
  }
  const base = rng.float(0, Math.PI * 2);
  for (let p = 0; p < jugadores; p++) {
    const a = base + (p / jugadores) * Math.PI * 2;
    inicios.push({ jugador: p, x: Math.cos(a) * radio, z: Math.sin(a) * radio, ang: a, y: 0 });
  }
  return inicios;
}

/**
 * Campo de alturas base. Tres capas con roles distintos: fbm ancho da la forma
 * del continente, ridged da cordilleras con cresta afilada y worley mete
 * escalones de meseta que rompen la monotonía de las llanuras.
 */
function sintetizarAlturas(ruido, rej, perfil, rng) {
  const { res, paso, mitad } = rej;
  const alt = new Float32Array(res * res);
  const dx = rng.float(-2000, 2000), dz = rng.float(-2000, 2000);
  const usaMeseta = perfil.meseta > 0.05;

  for (let j = 0; j < res; j++) {
    const z = -mitad + j * paso, nz = z + dz;
    for (let i = 0; i < res; i++) {
      const x = -mitad + i * paso, nx = x + dx;

      const continente = ruido.fbm(nx * 0.0042, nz * 0.0042, 6);
      const detalle = ruido.fbm(nx * 0.0185, nz * 0.0185, 4);
      let h = continente * 15.5 + detalle * 2.3;

      // La máscara evita que el mapa entero sea cordillera: solo un tercio lo es.
      const mMont = smoothstep(0.02, 0.44, ruido.fbm(nx * 0.0031 + 91, nz * 0.0031 - 57, 3));
      const cresta = ruido.ridged(nx * 0.0074, nz * 0.0074, 5) * 0.5 + 0.5;
      h += mMont * Math.pow(cresta, 1.75) * 47 * perfil.cordillera;

      if (usaMeseta && h > 2.5) {
        const f = ruido.worley(nx, nz, 0.0125);
        h += smoothstep(0.055, 0.30, f[1] - f[0]) * 5.2 * perfil.meseta * smoothstep(2.5, 12, h);
      }

      alt[j * res + i] = h * perfil.relieve;
    }
  }
  return alt;
}

/**
 * Máscara de tierra según el tipo de mapa: devuelve `null` para los mapas que
 * son continente liso, o un Float32Array 0..1 de "cuánta tierra hay acá" que
 * después se reutiliza para que la erosión no rellene el mar.
 */
function construirMascaraTierra(rej, tipo, perfil, inicios, ruido, rng, tam) {
  const { res, paso, mitad } = rej;
  const campo = new Float32Array(res * res);
  const ox = rng.float(-500, 500), oz = rng.float(-500, 500);
  const radioIsla = Math.min(tam * 0.175, tam * perfil.radioInicio * 0.62);
  const largoBrazo = tam * perfil.radioInicio * 1.22;
  const radioCentro = tam * 0.066;

  for (let j = 0; j < res; j++) {
    const z = -mitad + j * paso;
    for (let i = 0; i < res; i++) {
      const x = -mitad + i * paso;
      const ondul = ruido.fbm((x + ox) * 0.0105, (z + oz) * 0.0105, 3);
      let tierra;

      if (perfil.borde === 'islas') {
        let mejor = -9;
        for (let s = 0; s < inicios.length; s++) {
          const ix = inicios[s].x, iz = inicios[s].z;
          const ddx = x - ix, ddz = z - iz;
          const d = Math.sqrt(ddx * ddx + ddz * ddz);
          const wob = ruido.fbm(ddx * 0.016 + s * 37, ddz * 0.016 - s * 19, 3) * 0.30;
          mejor = Math.max(mejor, 1 - d / (radioIsla * (1 + wob)));
        }
        // Islotes neutrales: dan pesca y una veta disputada en medio del agua.
        for (let s = 0; s < 4; s++) {
          const a = (s / 4) * Math.PI * 2 + 0.6;
          const rr = tam * 0.15;
          const ddx = x - Math.cos(a) * rr, ddz = z - Math.sin(a) * rr;
          const d = Math.sqrt(ddx * ddx + ddz * ddz);
          const wob = ruido.fbm(ddx * 0.03 + s * 61, ddz * 0.03, 2) * 0.34;
          mejor = Math.max(mejor, 1 - d / (tam * 0.045 * (1 + wob)));
        }
        tierra = smoothstep(-0.02, 0.24, mejor);
      } else if (perfil.borde === 'lenguas') {
        let mejor = 1 - Math.sqrt(x * x + z * z) / (radioCentro * (1 + ondul * 0.22));
        for (let s = 0; s < inicios.length; s++) {
          const bx = inicios[s].x / (tam * perfil.radioInicio) * largoBrazo;
          const bz = inicios[s].z / (tam * perfil.radioInicio) * largoBrazo;
          const [d, t] = distSegmento(x, z, 0, 0, bx, bz);
          // El cuello angosto cerca del centro es el único puente del mapa.
          const ancho = t < 0.30 ? 11 : lerp(11, 58, smoothstep(0.30, 0.74, t));
          mejor = Math.max(mejor, 1 - d / (ancho * (1 + ondul * 0.16)));
        }
        tierra = smoothstep(-0.03, 0.20, mejor);
      } else if (perfil.borde === 'mar_interior') {
        const dr = Math.sqrt(x * x + z * z) / mitad + ondul * 0.055;
        const dm = Math.max(Math.abs(x), Math.abs(z)) / mitad + ondul * 0.07;
        tierra = Math.min(smoothstep(0.20, 0.32, dr), smoothstep(1.02, 0.80, dm));
      } else {
        const dm = Math.max(Math.abs(x), Math.abs(z)) / mitad + ondul * 0.075;
        tierra = smoothstep(1.03, 0.80, dm);
      }
      campo[j * res + i] = clamp(tierra, 0, 1);
    }
  }
  return campo;
}

/** Hunde el mar donde la máscara dice que no hay tierra. */
function aplicarMascaraTierra(alt, tierra, profundidadMar = 13.5) {
  for (let i = 0; i < alt.length; i++) {
    const t = tierra[i];
    if (t >= 0.999) continue;
    const fondo = -profundidadMar - (1 - t) * 4;
    alt[i] = lerp(fondo, Math.max(alt[i], 0.6), t);
  }
}

/* ═══════════════════════ 2. el agua esculpe ═══════════════════════ */

const NB_CUBOS = 2048;

/**
 * Orden ascendente por altura con conteo por cubos: O(n). Ordenar con
 * comparador 26 veces sobre 263k celdas costaría más que la erosión entera.
 */
function ordenarPorAltura(alt, orden, cubos) {
  const n = alt.length;
  let mn = Infinity, mx = -Infinity;
  for (let i = 0; i < n; i++) { const v = alt[i]; if (v < mn) mn = v; if (v > mx) mx = v; }
  const esc = (NB_CUBOS - 1) / Math.max(1e-6, mx - mn);
  cubos.fill(0);
  for (let i = 0; i < n; i++) cubos[(((alt[i] - mn) * esc) | 0) + 1]++;
  for (let b = 1; b <= NB_CUBOS; b++) cubos[b] += cubos[b - 1];
  for (let i = 0; i < n; i++) orden[cubos[((alt[i] - mn) * esc) | 0]++] = i;
}

/**
 * Erosión hidráulica sobre la grilla (modelo de potencia de arroyo).
 *
 * Se recorren las celdas de mayor a menor altura acumulando área de drenaje;
 * cada celda erosiona hasta su capacidad de transporte (∝ √área · pendiente) y
 * deposita el excedente cuando la pendiente cae. Eso es lo que produce valles
 * en V arriba, abanicos de sedimento abajo y crestas afiladas en el medio: la
 * diferencia entre un mapa que parece terreno y uno que parece ruido.
 */
function erosionHidraulica(alt, res, paso, iteraciones) {
  const n = alt.length;
  const orden = new Int32Array(n);
  const cubos = new Int32Array(NB_CUBOS + 1);
  const area = new Float32Array(n);
  const sed = new Float32Array(n);

  const dv = new Int32Array([1, -1, res, -res, res + 1, res - 1, -res + 1, -res - 1]);
  const dl = new Float32Array([paso, paso, paso, paso, paso * 1.41421356, paso * 1.41421356, paso * 1.41421356, paso * 1.41421356]);
  const AREA_TOPE = 3600;   // sin tope el cauce principal se convierte en un cañón
  const KC = 0.055, KE = 0.32, KD = 0.34;

  for (let it = 0; it < iteraciones; it++) {
    ordenarPorAltura(alt, orden, cubos);
    area.fill(1);
    sed.fill(0);

    for (let k = n - 1; k >= 0; k--) {
      const c = orden[k];
      const i = c % res, j = (c / res) | 0;
      if (i === 0 || j === 0 || i === res - 1 || j === res - 1) continue;  // desagua fuera del mapa
      const hc = alt[c];
      if (hc < -0.4) { alt[c] += sed[c] * 0.25; continue; }                 // bajo el mar solo hay depósito

      let mejor = -1, mejorPend = 0, mejorLargo = paso;
      for (let d = 0; d < 8; d++) {
        const v = c + dv[d];
        const pend = (hc - alt[v]) / dl[d];
        if (pend > mejorPend) { mejorPend = pend; mejor = v; mejorLargo = dl[d]; }
      }
      if (mejor < 0) { alt[c] += sed[c] * 0.5; continue; }                  // pozo cerrado: rellena

      const a = area[c];
      const cap = KC * Math.sqrt(a < AREA_TOPE ? a : AREA_TOPE) * mejorPend;
      let s = sed[c];
      if (s > cap) {
        const dep = (s - cap) * KD;
        alt[c] += dep; s -= dep;
      } else {
        let e = (cap - s) * KE;
        const tope = mejorPend * mejorLargo * 0.45;
        if (e > tope) e = tope;
        alt[c] -= e; s += e;
      }
      area[mejor] += a;
      sed[mejor] += s;
    }
  }
}

/**
 * Erosión térmica: nada de roca aguanta más allá del ángulo de talud. Además de
 * ser físicamente honesto, garantiza que casi todo el mapa sea transitable.
 */
function erosionTermica(alt, res, paso, pasadas, talud = 0.72) {
  const delta = new Float32Array(alt.length);
  const dv = [1, -1, res, -res];
  for (let p = 0; p < pasadas; p++) {
    delta.fill(0);
    for (let j = 1; j < res - 1; j++) {
      for (let i = 1; i < res - 1; i++) {
        const c = j * res + i;
        const hc = alt[c];
        let mejor = -1, mejorCaida = 0;
        for (let d = 0; d < 4; d++) {
          const caida = hc - alt[c + dv[d]];
          if (caida > mejorCaida) { mejorCaida = caida; mejor = c + dv[d]; }
        }
        const exceso = mejorCaida - talud * paso;
        if (mejor < 0 || exceso <= 0) continue;
        const mov = exceso * 0.42;
        delta[c] -= mov; delta[mejor] += mov;
      }
    }
    for (let i = 0; i < alt.length; i++) alt[i] += delta[i];
  }
}

/** Suavizado gaussiano separable ligero: limpia el ruido de celda única. */
function suavizar(alt, res, peso = 0.55) {
  const tmp = new Float32Array(alt.length);
  for (let j = 0; j < res; j++) {
    for (let i = 0; i < res; i++) {
      const c = j * res + i;
      const a = alt[i > 0 ? c - 1 : c], b = alt[i < res - 1 ? c + 1 : c];
      tmp[c] = lerp(alt[c], a * 0.25 + alt[c] * 0.5 + b * 0.25, peso);
    }
  }
  for (let j = 0; j < res; j++) {
    for (let i = 0; i < res; i++) {
      const c = j * res + i;
      const a = tmp[j > 0 ? c - res : c], b = tmp[j < res - 1 ? c + res : c];
      alt[c] = lerp(tmp[c], a * 0.25 + tmp[c] * 0.5 + b * 0.25, peso);
    }
  }
}

/**
 * Relleno de depresiones (Priority-Flood). Devuelve la superficie "sin pozos":
 * sirve para dos cosas a la vez, detectar cuencas cerradas (lagos) y garantizar
 * que un río trazado por descenso siempre llegue al mar.
 */
function rellenarDepresiones(alt, res) {
  const n = alt.length;
  const lleno = new Float32Array(n);
  const visto = new Uint8Array(n);
  const cola = new MonticuloMin(n + 8);
  const dv = [1, -1, res, -res, res + 1, res - 1, -res + 1, -res - 1];

  for (let i = 0; i < res; i++) {
    const bordes = [i, (res - 1) * res + i, i * res, i * res + res - 1];
    for (const c of bordes) {
      if (visto[c]) continue;
      visto[c] = 1; lleno[c] = alt[c]; cola.push(alt[c], c);
    }
  }
  while (cola.n > 0) {
    const c = cola.pop();
    const hc = cola.claveUlt;
    const i = c % res, j = (c / res) | 0;
    for (let d = 0; d < 8; d++) {
      const v = c + dv[d];
      if (v < 0 || v >= n || visto[v]) continue;
      const vi = v % res, vj = (v / res) | 0;
      if (Math.abs(vi - i) > 1 || Math.abs(vj - j) > 1) continue;   // sin envolver el borde
      visto[v] = 1;
      lleno[v] = alt[v] > hc ? alt[v] : hc;
      cola.push(lleno[v], v);
    }
  }
  return lleno;
}

/**
 * Cuencas cerradas: las grandes se hunden bajo el nivel del mar y quedan como
 * lagos; las chicas se rellenan para no dejar hoyos donde se traba la navegación.
 */
function tallarLagos(alt, lleno, res, areaMinima = 260) {
  const n = alt.length;
  const marca = new Uint8Array(n);
  const pila = new Int32Array(n);
  const dv = [1, -1, res, -res];

  for (let s = 0; s < n; s++) {
    if (marca[s] || lleno[s] - alt[s] <= 0.30) continue;
    let tope = 0, cuenta = 0, nivel = lleno[s];
    pila[tope++] = s; marca[s] = 1;
    const celdas = [];
    while (tope > 0) {
      const c = pila[--tope];
      celdas.push(c);
      cuenta++;
      if (lleno[c] > nivel) nivel = lleno[c];
      const i = c % res, j = (c / res) | 0;
      if (i < 1 || j < 1 || i > res - 2 || j > res - 2) continue;
      for (let d = 0; d < 4; d++) {
        const v = c + dv[d];
        if (marca[v] || lleno[v] - alt[v] <= 0.30) continue;
        marca[v] = 1;
        pila[tope++] = v;
      }
    }
    if (cuenta < areaMinima || nivel < 0.4) {
      for (const c of celdas) alt[c] = lleno[c];      // hoyo chico: se tapa
      continue;
    }
    for (const c of celdas) {
      const prof = nivel - alt[c];
      const t = smoothstep(0.15, 1.7, prof);
      const objetivo = -0.35 - Math.min(prof, 5.5) * 0.55;
      const nuevo = lerp(alt[c], objetivo, t);
      if (nuevo < alt[c]) alt[c] = nuevo;
    }
  }
}

/**
 * Ríos: se largan desde los picos y bajan por gradiente sobre la superficie ya
 * rellenada, así nunca se quedan trabados. El cauce se hunde bajo el nivel del
 * mar recién en la llanura, que es donde el jugador lo ve como agua; arriba
 * queda como garganta seca, que es exactamente lo que hace un río de montaña.
 */
function trazarRios(alt, lleno, rej, cantidad, rng) {
  const { res, paso, mitad } = rej;
  const n = alt.length;
  if (cantidad <= 0) return [];
  const dv = [1, -1, res, -res, res + 1, res - 1, -res + 1, -res - 1];

  // Candidatos: celdas altas, bien repartidas, lejos del borde.
  const candidatos = [];
  for (let j = 24; j < res - 24; j += 7) {
    for (let i = 24; i < res - 24; i += 7) {
      const c = j * res + i;
      if (alt[c] > 9) candidatos.push(c);
    }
  }
  candidatos.sort((a, b) => alt[b] - alt[a]);
  const fuentes = [];
  for (const c of candidatos) {
    if (fuentes.length >= cantidad) break;
    const i = c % res, j = (c / res) | 0;
    let lejos = true;
    for (const f of fuentes) {
      const fi = f % res, fj = (f / res) | 0;
      if ((fi - i) * (fi - i) + (fj - j) * (fj - j) < 90 * 90) { lejos = false; break; }
    }
    if (lejos) fuentes.push(c);
  }

  const visitado = new Uint8Array(n);
  const rios = [];
  for (const fuente of fuentes) {
    const camino = [];
    let c = fuente;
    visitado.fill(0);
    for (let paso2 = 0; paso2 < 5000; paso2++) {
      camino.push(c);
      visitado[c] = 1;
      const i = c % res, j = (c / res) | 0;
      if (i < 3 || j < 3 || i > res - 4 || j > res - 4) break;
      if (alt[c] < -1.2) break;
      let mejor = -1, mejorH = Infinity;
      for (let d = 0; d < 8; d++) {
        const v = c + dv[d];
        if (visitado[v]) continue;
        if (lleno[v] < mejorH) { mejorH = lleno[v]; mejor = v; }
      }
      if (mejor < 0) break;
      c = mejor;
    }
    if (camino.length < 40) continue;

    let nivel = alt[camino[0]] - 1.0;
    for (let s = 0; s < camino.length; s++) {
      const cc = camino[s];
      const frac = s / (camino.length - 1);
      const ancho = lerp(2.0, 6.2, Math.sqrt(frac)) * (1 + rng.float(-0.12, 0.12));
      const prof = lerp(1.0, 3.4, frac);
      let objetivo = Math.min(nivel - 0.02, alt[cc] - prof);
      // En tierras bajas el cauce se hunde: ahí el río se vuelve agua navegable.
      if (alt[cc] < 9) objetivo = Math.min(objetivo, lerp(-2.2, 0.7, alt[cc] / 9));
      nivel = objetivo;

      const ci = cc % res, cj = (cc / res) | 0;
      const rc = Math.ceil((ancho + 2.4) / paso);
      for (let oj = -rc; oj <= rc; oj++) {
        const jj = cj + oj;
        if (jj < 0 || jj >= res) continue;
        for (let oi = -rc; oi <= rc; oi++) {
          const ii = ci + oi;
          if (ii < 0 || ii >= res) continue;
          const dd = Math.sqrt(oi * oi + oj * oj) * paso;
          const w = 1 - smoothstep(ancho * 0.5, ancho + 2.4, dd);
          if (w <= 0) continue;
          const k = jj * res + ii;
          const nuevo = lerp(alt[k], objetivo, w);
          if (nuevo < alt[k]) alt[k] = nuevo;
        }
      }
    }
    rios.push({
      x0: -mitad + (camino[0] % res) * paso, z0: -mitad + ((camino[0] / res) | 0) * paso,
      largo: camino.length,
    });
  }
  return rios;
}

/* ═══════════════════════ 3. rasgos que definen el tipo de mapa ═══════════════════════ */

/**
 * Los rasgos que hacen jugable a cada mapa van DESPUÉS de la erosión: si se
 * tallan antes, el sedimento rellena el río y redondea los acantilados hasta
 * dejarlos escalables. Acá se reafirman con borde duro.
 */
function tallarRasgosDuros(alt, rej, tipo, perfil, inicios, ruido, tam) {
  const { res, paso, mitad } = rej;

  if (tipo === 'rio_grande') {
    const vados = [-tam * 0.17, tam * 0.19];
    for (let j = 0; j < res; j++) {
      const z = -mitad + j * paso;
      const cauce = ruido.fbm(z * 0.0058, 77.3, 3) * 27;
      let vado = 0;
      for (const zv of vados) vado = Math.max(vado, 1 - smoothstep(0, 32, Math.abs(z - zv)));
      for (let i = 0; i < res; i++) {
        const x = -mitad + i * paso;
        const d = Math.abs(x - cauce);
        const orilla = 1 - smoothstep(30, 50, d);
        if (orilla <= 0) continue;
        const nucleo = 1 - smoothstep(0, 30, d);
        const fondo = lerp(-0.9, -4.8, nucleo);
        const meta = lerp(fondo, 1.15, smoothstep(0.12, 0.88, vado));
        const c = j * res + i;
        alt[c] = lerp(alt[c], meta, orilla);
      }
    }
  }

  if (tipo === 'fortaleza') {
    for (let j = 0; j < res; j++) {
      const z = -mitad + j * paso;
      for (let i = 0; i < res; i++) {
        const x = -mitad + i * paso;
        const c = j * res + i;
        for (let s = 0; s < inicios.length; s++) {
          const ix = inicios[s].x, iz = inicios[s].z;
          const dx = x - ix, dz = z - iz;
          const d = Math.sqrt(dx * dx + dz * dz);
          if (d > 66 || d < 30) continue;
          const rAnillo = 47 + ruido.fbm(x * 0.03 + s * 71, z * 0.03, 2) * 3.4;
          const banda = 1 - smoothstep(3.5, 10.5, Math.abs(d - rAnillo));
          if (banda <= 0) continue;
          // Una sola puerta, mirando al centro del mapa: por ahí se entra y se sale.
          const puerta = smoothstep(0.15, 0.33, Math.abs(deltaAngulo(Math.atan2(dz, dx), Math.atan2(-iz, -ix))));
          alt[c] += banda * puerta * 21;
        }
      }
    }
  }

  if (tipo === 'valle_alpino') {
    // Pasos: corredores angostos de base a base pasando por el centro del mapa.
    const segs = [];
    for (let s = 0; s < inicios.length; s++) {
      segs.push([inicios[s].x, inicios[s].z, 0, 0]);
      const t = inicios[(s + 1) % inicios.length];
      segs.push([inicios[s].x * 0.55, inicios[s].z * 0.55, t.x * 0.55, t.z * 0.55]);
    }
    for (let j = 0; j < res; j++) {
      const z = -mitad + j * paso;
      for (let i = 0; i < res; i++) {
        const x = -mitad + i * paso;
        let mejor = 0;
        for (const g of segs) {
          const [d] = distSegmento(x, z, g[0], g[1], g[2], g[3]);
          mejor = Math.max(mejor, 1 - d / 26);
        }
        if (mejor <= 0) continue;
        const c = j * res + i;
        const w = smoothstep(0.0, 0.55, mejor) * 0.85;
        const suelo = 5.5 + ruido.fbm(x * 0.02 + 400, z * 0.02, 3) * 2.4;
        if (alt[c] > suelo) alt[c] = lerp(alt[c], suelo, w);
      }
    }
  }
}

/* ═══════════════════════ 4. clima y biomas ═══════════════════════ */

function calcularPendientes(alt, rej) {
  const { res, paso } = rej;
  const pend = new Float32Array(alt.length);
  const inv = 1 / (2 * paso);
  for (let j = 0; j < res; j++) {
    for (let i = 0; i < res; i++) {
      const c = j * res + i;
      const dx = (alt[i < res - 1 ? c + 1 : c] - alt[i > 0 ? c - 1 : c]) * inv;
      const dz = (alt[j < res - 1 ? c + res : c] - alt[j > 0 ? c - res : c]) * inv;
      pend[c] = Math.sqrt(dx * dx + dz * dz);
    }
  }
  return pend;
}

/** Distancia al agua en metros (chamfer de dos pasadas: O(n), suficiente). */
function distanciaAlAgua(alt, rej) {
  const { res, paso } = rej;
  const n = alt.length;
  const d = new Float32Array(n);
  const GRANDE = 1e6;
  const dg = paso * 1.41421356;
  for (let i = 0; i < n; i++) d[i] = alt[i] < NIVEL_AGUA ? 0 : GRANDE;
  for (let j = 0; j < res; j++) {
    for (let i = 0; i < res; i++) {
      const c = j * res + i;
      let v = d[c];
      if (i > 0) v = Math.min(v, d[c - 1] + paso);
      if (j > 0) v = Math.min(v, d[c - res] + paso);
      if (i > 0 && j > 0) v = Math.min(v, d[c - res - 1] + dg);
      if (i < res - 1 && j > 0) v = Math.min(v, d[c - res + 1] + dg);
      d[c] = v;
    }
  }
  for (let j = res - 1; j >= 0; j--) {
    for (let i = res - 1; i >= 0; i--) {
      const c = j * res + i;
      let v = d[c];
      if (i < res - 1) v = Math.min(v, d[c + 1] + paso);
      if (j < res - 1) v = Math.min(v, d[c + res] + paso);
      if (i < res - 1 && j < res - 1) v = Math.min(v, d[c + res + 1] + dg);
      if (i > 0 && j < res - 1) v = Math.min(v, d[c + res - 1] + dg);
      d[c] = v;
    }
  }
  return d;
}

/**
 * Humedad = fbm de fondo + cercanía al agua + sombra orográfica.
 *
 * La sombra se calcula barriendo la grilla en el sentido del viento: la nube
 * pierde carga al trepar y la recupera despacio en la llanura. Por eso detrás
 * de una cordillera hay desierto y del lado de barlovento hay bosque cerrado,
 * que es justo lo que hace legible un mapa desde el minimapa.
 */
function calcularHumedad(alt, distAgua, rej, ruido, perfil, rng) {
  const { res, paso, mitad } = rej;
  const n = alt.length;
  const carga = new Float32Array(n);
  const dir = rng.int(0, 3);
  const K_SUBIDA = 0.13, RECUPERA = 0.0035 * paso;

  const barrer = (indice, largoFila, filas) => {
    for (let f = 0; f < filas; f++) {
      let c0 = 1;
      let prevAlt = 0;
      for (let s = 0; s < largoFila; s++) {
        const c = indice(f, s);
        if (alt[c] < NIVEL_AGUA) { c0 = 1; prevAlt = 0; }
        else {
          const subida = Math.max(0, alt[c] - prevAlt);
          c0 *= Math.exp(-subida * K_SUBIDA);
          c0 = Math.min(1, c0 + RECUPERA);
          prevAlt = alt[c];
        }
        carga[c] = c0;
      }
    }
  };
  if (dir === 0) barrer((f, s) => f * res + s, res, res);
  else if (dir === 1) barrer((f, s) => f * res + (res - 1 - s), res, res);
  else if (dir === 2) barrer((f, s) => s * res + f, res, res);
  else barrer((f, s) => (res - 1 - s) * res + f, res, res);

  const hum = new Float32Array(n);
  const ox = rng.float(-900, 900), oz = rng.float(-900, 900);
  for (let j = 0; j < res; j++) {
    const z = -mitad + j * paso + oz;
    for (let i = 0; i < res; i++) {
      const c = j * res + i;
      const x = -mitad + i * paso + ox;
      let h = 0.48
        + 0.30 * ruido.fbm(x * 0.0058, z * 0.0058, 4)
        + 0.28 * (1 - smoothstep(2, 95, distAgua[c]))
        + 0.30 * (carga[c] - 0.5)
        - 0.011 * Math.max(0, alt[c] - 13)
        + perfil.humedad;
      hum[c] = clamp(h, 0, 1);
    }
  }
  return hum;
}

function clasificarBiomas(alt, pend, hum, distAgua, perfil) {
  const n = alt.length;
  const bio = new Uint8Array(n);
  const hMont = perfil.alturaMontana;
  for (let c = 0; c < n; c++) {
    const h = alt[c];
    if (h < NIVEL_AGUA) { bio[c] = B.AGUA; continue; }
    if (h < 1.5 && distAgua[c] < 4.0) { bio[c] = B.PLAYA; continue; }
    if (pend[c] > 0.52 || h > hMont) { bio[c] = B.MONTANA; continue; }
    const m = hum[c];
    if (m < 0.325) { bio[c] = B.DESIERTO; continue; }
    if (m > 0.605) { bio[c] = B.BOSQUE; continue; }
    bio[c] = B.PRADERA;
  }
  return bio;
}

/**
 * Calibra el nivel del mar contra el continente.
 *
 * El fbm base está centrado en cero, así que tal cual sale, medio mapa nace bajo
 * el agua y Arabia termina siendo un archipiélago. Se busca el cuantil de altura
 * que deja la fracción de tierra pedida y se desplaza el campo entero: el
 * relieve no se toca, sólo se decide dónde está la costa.
 */
function nivelarContinente(alt, tierra, fraccion = 0.9) {
  const muestras = [];
  for (let i = 0; i < alt.length; i += 3) if (tierra[i] > 0.75) muestras.push(alt[i]);
  if (muestras.length < 64) return 0;
  muestras.sort((a, b) => a - b);
  const q = muestras[Math.floor(clamp(1 - fraccion, 0, 1) * (muestras.length - 1))];
  const desp = 0.8 - q;
  for (let i = 0; i < alt.length; i++) alt[i] += desp;
  return desp;
}

/* ═══════════════════════ 5. las bases ═══════════════════════ */

/**
 * Acomoda cada base al terreno real: después de la erosión, el punto ideal
 * puede haber quedado en una ladera o bajo el agua. Se busca el llano más
 * cercano comprobando el disco entero, no sólo el centro: una Sede son 10×10 m.
 */
function reubicarInicios(alt, pend, rej, inicios, tam) {
  const { res, paso, mitad } = rej;
  const margen = tam * 0.06;

  // Tres anillos hasta 42 m, que es donde vive la dotación inicial: un islote de
  // treinta metros pasa el examen del llano y deja al jugador sin una sola mina.
  const RADIOS_TIERRA = [18, 30, 42];
  const tierraAlrededor = (x, z) => {
    let seca = 0;
    for (let k = 0; k < 12; k++) {
      const a = ((k % 4) / 4) * Math.PI * 2 + (k < 4 ? 0 : k < 8 ? 0.4 : 0.8);
      const r = RADIOS_TIERRA[(k / 4) | 0];
      if (muestrear(alt, rej, x + Math.cos(a) * r, z + Math.sin(a) * r) > NIVEL_AGUA + 0.3) seca++;
    }
    return seca / 12;
  };
  /** Se comprueba el disco entero: una Sede son 10×10 m, no un punto. */
  const bueno = (x, z, hMin, pMax, tierraMin) => {
    if (Math.abs(x) > mitad - margen || Math.abs(z) > mitad - margen) return false;
    for (let k = 0; k < 9; k++) {
      const a = (k / 8) * Math.PI * 2;
      const r = k === 0 ? 0 : 9;
      const px = x + Math.cos(a) * r, pz = z + Math.sin(a) * r;
      if (muestrear(alt, rej, px, pz) < hMin) return false;
      if (muestrear(pend, rej, px, pz) > pMax) return false;
    }
    return tierraMin <= 0 || tierraAlrededor(x, z) >= tierraMin;
  };

  // Nadie puede terminar en la puerta del vecino. Se mide contra la posición
  // ACTUAL de todos los demás, incluidos los que todavía no se movieron: si no,
  // uno se muda al lugar del otro y quedan dos bases pegadas.
  let ideal = Infinity;
  for (let a = 0; a < inicios.length; a++) {
    for (let b = a + 1; b < inicios.length; b++) {
      const d = Math.hypot(inicios[a].x - inicios[b].x, inicios[a].z - inicios[b].z);
      if (d < ideal) ideal = d;
    }
  }
  if (!Number.isFinite(ideal)) ideal = 0;
  const sepAlta = ideal * 0.7;
  const sepMedia = Math.min(sepAlta, Math.max(84, ideal * 0.55));   // 84 m = dos discos de dotación
  const sepBaja = Math.min(sepMedia, Math.max(56, ideal * 0.3));

  const pos = inicios.map((i) => ({ x: i.x, z: i.z }));
  const lejosDe = (k, x, z, minimo) => {
    for (let i = 0; i < pos.length; i++) {
      if (i === k) continue;
      if (Math.hypot(x - pos[i].x, z - pos[i].z) < minimo) return false;
    }
    return true;
  };

  /** Barrido grueso de todo el mapa: el salvavidas cuando la base cayó al mar. */
  const bancos = new Map();
  const bancoDe = (hMin, pMax, tierraMin) => {
    const clave = `${hMin}|${pMax}|${tierraMin}`;
    let lista = bancos.get(clave);
    if (lista) return lista;
    lista = [];
    for (let j = 6; j < res - 6; j += 4) {
      const z = -mitad + j * paso;
      for (let i = 6; i < res - 6; i += 4) {
        const x = -mitad + i * paso;
        if (bueno(x, z, hMin, pMax, tierraMin)) lista.push(x, z);
      }
    }
    bancos.set(clave, lista);
    return lista;
  };

  for (let k = 0; k < inicios.length; k++) {
    const x0 = pos[k].x, z0 = pos[k].z;
    let p = null;
    const probar = (hMin, pMax, tierraMin, sepMin, radio, usarBanco) => {
      if (p) return;
      const ok = (x, z) => bueno(x, z, hMin, pMax, tierraMin) && lejosDe(k, x, z, sepMin);
      if (ok(x0, z0)) { p = { x: x0, z: z0 }; return; }
      p = acomodar(x0, z0, ok, radio, 220);
      if (p || !usarBanco) return;
      // No gana el más cercano al punto ideal sino el mejor sitio: a un jugador
      // le importa mucho más tener tierra alrededor que salir en el lugar exacto.
      const lista = bancoDe(hMin, pMax, tierraMin);
      let mejor = -1, mejorP = -Infinity;
      for (let q = 0; q < lista.length; q += 2) {
        if (!lejosDe(k, lista[q], lista[q + 1], sepMin)) continue;
        const dx = lista[q] - x0, dz = lista[q + 1] - z0;
        const puntaje = tierraAlrededor(lista[q], lista[q + 1]) * 120 - Math.sqrt(dx * dx + dz * dz) * 0.25;
        if (puntaje > mejorP) { mejorP = puntaje; mejor = q; }
      }
      if (mejor >= 0) p = { x: lista[mejor], z: lista[mejor + 1] };
    };
    // tierra firme y espacio alrededor primero; la separación cede después,
    // porque una base ahogada o en un islote ya no se arregla con nada
    probar(1.0, 0.17, 0.80, sepAlta, tam * 0.09, false);
    probar(0.6, 0.30, 0.70, sepAlta, tam * 0.17, true);
    probar(0.6, 0.32, 0.50, sepMedia, tam * 0.22, true);
    probar(0.5, 0.40, 0.30, sepBaja, tam * 0.30, true);
    probar(0.5, 0.45, 0, sepBaja * 0.6, tam * 0.35, true);
    if (p) { inicios[k].x = p.x; inicios[k].z = p.z; pos[k] = { x: p.x, z: p.z }; }
  }
}

/**
 * Aplana el terreno bajo una base. Sin esto la Sede queda medio enterrada de un
 * lado y flotando del otro, y los colonos salen a trepar una ladera.
 */
function aplanarInicio(alt, rej, x, z, radio = 10, borde = 8) {
  const { res, paso, mitad } = rej;
  const ci = Math.round((x + mitad) / paso), cj = Math.round((z + mitad) / paso);
  const rc = Math.ceil((radio + borde) / paso) + 1;

  let suma = 0, peso = 0;
  for (let oj = -rc; oj <= rc; oj++) {
    const jj = cj + oj;
    if (jj < 0 || jj >= res) continue;
    for (let oi = -rc; oi <= rc; oi++) {
      const ii = ci + oi;
      if (ii < 0 || ii >= res) continue;
      const d = Math.sqrt(oi * oi + oj * oj) * paso;
      if (d > radio) continue;
      const w = 1 - smoothstep(0, radio, d) * 0.6;
      suma += alt[jj * res + ii] * w;
      peso += w;
    }
  }
  if (peso <= 0) return NIVEL_AGUA + 1.1;
  const objetivo = Math.max(suma / peso, NIVEL_AGUA + 1.1);

  for (let oj = -rc; oj <= rc; oj++) {
    const jj = cj + oj;
    if (jj < 0 || jj >= res) continue;
    for (let oi = -rc; oi <= rc; oi++) {
      const ii = ci + oi;
      if (ii < 0 || ii >= res) continue;
      const d = Math.sqrt(oi * oi + oj * oj) * paso;
      const w = 1 - smoothstep(radio, radio + borde, d);
      if (w <= 0) continue;
      const c = jj * res + ii;
      alt[c] = lerp(alt[c], objetivo, w);
    }
  }
  return objetivo;
}

/* ═══════════════════════ 6. siembra de recursos ═══════════════════════ */

/** Máscara de bits de los biomas que admite cada nodo de `data/recursos.js`. */
const MASCARA_BIOMA = NODOS.map((n) => {
  const lista = Array.isArray(n.bioma) && n.bioma.length ? n.bioma : TIPOS_BIOMA;
  let m = 0;
  for (const b of lista) {
    const i = TIPOS_BIOMA.indexOf(b);
    if (i >= 0) m |= 1 << i;
  }
  return m || 0xff;
});

const iN = (clave) => NODO_POR_CLAVE.get(clave);
const ARBOLES = [iN('arbol_pino'), iN('arbol_roble'), iN('arbol_palmera')];
const PENDIENTE_MAX = 0.35;     // más que esto y el colono no puede trabajarlo
const PENDIENTE_LAXA = 0.50;    // sólo para dotación garantizada en mapas de montaña
const RADIO_DOTACION = 40;      // disco donde se mide el balance entre jugadores
const CV_MAXIMA = 0.08;         // varianza máxima tolerada de esa dotación
const TOPE_NODOS = 1500;        // techo de entidades de recurso (World cap = 6000)

/**
 * La dotación de arranque no se sortea por jugador: se sortea UNA vez y se rota
 * por el ángulo de cada base. Así el mapa es distinto en cada semilla pero
 * idéntico para todos los que lo juegan, que es lo que pide un mapa de torneo.
 */
function plantillaDotacion(rng) {
  const grupos = [];
  const base = rng.float(0, Math.PI * 2);
  const ranuras = mezclar(rng, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
  const paso = (Math.PI * 2) / 9;
  let k = 0;
  const ang = () => base + ranuras[k++] * paso + rng.float(-0.15, 0.15);

  // `rMin`/`rMax` son topes DUROS de distancia a la base, y están puestos para
  // que todo grupo caiga entero adentro o entero afuera del disco de 40 m donde
  // se mide el balance: si un yacimiento queda justo en el borde, 900 de energía
  // entran o salen según el jugador y la simetría se cae por un metro.
  const g = (claves, cant, r, disp, rMin, rMax, angulo) =>
    grupos.push({ claves, cant, a: angulo ?? ang(), r, disp, rMin, rMax });

  // comida y leña pegadas a la Sede: los primeros cinco minutos de la partida
  g([iN('baya')], 6, rng.float(13, 19), 2.7, 10, 24);
  g(ARBOLES, 8, rng.float(13, 19), 4.6, 10, 26);
  // dos jabalíes en direcciones distintas, como manda el manual
  g([iN('jabali')], 1, rng.float(16, 24), 1.4, 13, 27);
  g([iN('jabali')], 1, rng.float(16, 24), 1.4, 13, 27);
  g([iN('ciervo')], 4, rng.float(21, 33), 3.6, 18, 37);
  // oro y carbón lejos: hay que salir de casa y eso genera los primeros roces
  g([iN('veta_oro')], 1, rng.float(26, 36), 2.2, 23, 39);
  g([iN('veta_oro')], 1, rng.float(26, 36), 2.2, 23, 39);
  g([iN('carbon')], 1, rng.float(26, 36), 2.2, 23, 39);
  g([iN('carbon')], 1, rng.float(26, 36), 2.2, 23, 39);
  // los dos bosques de trabajo, enteros fuera del disco de medición
  for (let b = 0; b < 2; b++) {
    g(ARBOLES, rng.int(26, 52), rng.float(56, 70), 9, 43, 78, base + rng.float(0, Math.PI * 2));
  }
  return grupos;
}

/** Estado compartido por todas las pasadas de siembra de un mismo intento. */
function crearSembrador(campos, inicios, rng) {
  const { rej, alturas, pendientes, biomas } = campos;
  const mitad = rej.mitad;
  const BORDE = 8;
  const oc = new Ocupacion(8);
  const nodos = [];
  const buf = new Int32Array(8);

  const alturaEn = (x, z) => muestrear(alturas, rej, x, z);
  const pendEn = (x, z) => muestrear(pendientes, rej, x, z);
  const biomaEn = (x, z) => muestrearNN(biomas, rej, x, z);
  const dentro = (x, z) => x > -mitad + BORDE && x < mitad - BORDE && z > -mitad + BORDE && z < mitad - BORDE;

  function distBase(x, z) {
    let m = Infinity;
    for (let i = 0; i < inicios.length; i++) {
      const dx = x - inicios[i].x, dz = z - inicios[i].z;
      const d = dx * dx + dz * dz;
      if (d < m) m = d;
    }
    return Math.sqrt(m);
  }

  /** De una lista de nodos, el que le va al bioma de ese punto. */
  function elegirClave(lista, x, z, relajar = false) {
    const b = biomaEn(x, z);
    let n = 0;
    for (let i = 0; i < lista.length; i++) if (MASCARA_BIOMA[lista[i]] & (1 << b)) buf[n++] = lista[i];
    if (n === 0) return relajar ? lista[Math.floor(rng.float(0, lista.length)) % lista.length] : -1;
    return buf[Math.floor(rng.float(0, n)) % n];
  }

  /**
   * ¿Este punto le pertenece a la base `k`? Sin esta condición, el bosque de un
   * jugador puede caer en el patio del vecino cuando las bases quedan cerca, y
   * el reparto se desbalancea sin que falte ni sobre un solo nodo en el mapa.
   */
  function esDeSuZona(x, z, k) {
    const dx = x - inicios[k].x, dz = z - inicios[k].z;
    const propio = dx * dx + dz * dz;
    for (let i = 0; i < inicios.length; i++) {
      if (i === k) continue;
      const ex = x - inicios[i].x, ez = z - inicios[i].z;
      if (ex * ex + ez * ez < propio) return false;
    }
    return true;
  }

  /** `laxo` ignora el bioma y afloja la pendiente: es el modo "esto no puede faltar". */
  function apto(idx, x, z, dMinBase = 0, laxo = false, duenio = -1) {
    if (idx === undefined || idx < 0 || !dentro(x, z)) return false;
    if (duenio >= 0 && !esDeSuZona(x, z, duenio)) return false;
    const def = NODOS[idx];
    const h = alturaEn(x, z);
    if (def.agua) {
      if (h > NIVEL_AGUA - 0.8 || h < NIVEL_AGUA - 9) return false;   // sólo plataforma costera
    } else {
      if (h < NIVEL_AGUA + 0.45) return false;
      if (pendEn(x, z) > (laxo ? PENDIENTE_LAXA : PENDIENTE_MAX)) return false;
    }
    if (!laxo && !(MASCARA_BIOMA[idx] & (1 << biomaEn(x, z)))) return false;
    if (dMinBase > 0 && distBase(x, z) < dMinBase) return false;
    return oc.libre(x, z, (def.radio || 0.8) + 0.55);
  }

  function plantar(idx, x, z) {
    const def = NODOS[idx];
    oc.marcar(x, z, (def.radio || 0.8) + 0.55);
    nodos.push({ clave: def.clave, x, z, rot: rng.float(0, Math.PI * 2) });
  }

  /**
   * Un nodo del grupo alrededor de (cx,cz). El cúmulo puede engordar hasta un
   * 60% si está apretado, pero no más: si se desparrama, el arbusto de bayas
   * termina a treinta metros de la Sede y deja de ser dotación inicial.
   */
  function plantarCerca(lista, cx, cz, disp, dMinBase, duenio = -1, anillo = null) {
    const tope = disp * 0.6;
    for (let t = 0; t < 90; t++) {
      const relajar = t > 45;
      const rr = disp * Math.sqrt(rng.float(0, 1)) + Math.min(t * 0.08, tope);
      const aa = rng.float(0, Math.PI * 2);
      const x = cx + Math.cos(aa) * rr, z = cz + Math.sin(aa) * rr;
      if (anillo && !anillo(x, z)) continue;
      const idx = elegirClave(lista, x, z, relajar);
      const dm = relajar ? Math.min(dMinBase, 9.5) : dMinBase;
      if (apto(idx, x, z, dm, relajar, duenio)) { plantar(idx, x, z); return true; }
    }
    return false;
  }

  return { rej, oc, nodos, rng, dentro, distBase, alturaEn, pendEn, biomaEn, elegirClave, apto, plantar, plantarCerca };
}

/**
 * Centro de un grupo de la plantilla. Primero se barre el ÁNGULO manteniendo el
 * radio: mover un grupo de lado no cambia la dotación, alejarlo sí. El radio
 * recién cede cuando no hay ningún ángulo que sirva.
 */
function centroDeGrupo(s, ini, g, giro, duenio) {
  const rng = s.rng;
  const valido = (x, z, laxo) => s.apto(s.elegirClave(g.claves, x, z, laxo), x, z, 11, laxo, duenio);
  // el cúmulo se abre `disp` alrededor del centro, así que el centro respeta el
  // anillo duro con ese margen puesto de los dos lados
  const rBajo = Math.min(g.r, g.rMin + g.disp * 0.75);
  const rAlto = Math.max(g.r, g.rMax - g.disp * 0.75);
  const enRango = (r) => clamp(r, rBajo, rAlto);

  for (let p = 0; p < 74; p++) {
    const da = p === 0 ? 0 : (p % 2 ? 1 : -1) * Math.ceil(p / 2) * 0.085;
    const a = giro + g.a + da;
    const x = ini.x + Math.cos(a) * g.r, z = ini.z + Math.sin(a) * g.r;
    if (valido(x, z, false)) return { x, z };
  }
  for (let p = 0; p < 140; p++) {
    const a = giro + g.a + rng.float(-Math.PI, Math.PI);
    const r = enRango(g.r * (1 + rng.float(-0.15, 0.15)));
    const x = ini.x + Math.cos(a) * r, z = ini.z + Math.sin(a) * r;
    if (valido(x, z, false)) return { x, z };
  }
  for (let p = 0; p < 220; p++) {
    const a = giro + g.a + rng.float(-Math.PI, Math.PI);
    const r = enRango(g.r * (1 + rng.float(-0.25, 0.25)));
    const x = ini.x + Math.cos(a) * r, z = ini.z + Math.sin(a) * r;
    if (valido(x, z, true)) return { x, z };
  }
  return null;
}

/** Dotación garantizada de cada jugador: lo que define el balance de la partida. */
function sembrarDotacion(s, inicios) {
  const rng = s.rng;
  for (const ini of inicios) s.oc.marcar(ini.x, ini.z, 9.0);
  const plantilla = plantillaDotacion(rng);

  for (let p = 0; p < inicios.length; p++) {
    const ini = inicios[p];
    const giro = ini.ang || 0;
    for (const g of plantilla) {
      const anillo = (x, z) => {
        const dx = x - ini.x, dz = z - ini.z;
        const d2 = dx * dx + dz * dz;
        return d2 >= g.rMin * g.rMin && d2 <= g.rMax * g.rMax;
      };
      const centro = centroDeGrupo(s, ini, g, giro, p);
      if (!centro) continue;
      let puestos = 0;
      for (let k = 0; k < g.cant; k++) {
        if (s.plantarCerca(g.claves, centro.x, centro.z, g.disp, 11, p, anillo)) puestos++;
      }

      // Lo que no entró en el cúmulo se reparte por el anillo del grupo: la
      // cantidad se garantiza sin que el grupo se escape del lado del disco de
      // 40 m donde le toca estar.
      for (let t = 0; puestos < g.cant && t < 420; t++) {
        const laxo = t > 160;
        const a = giro + g.a + rng.float(-1, 1) * Math.min(Math.PI, 0.3 + t * 0.014);
        const r = clamp(g.r * (1 + rng.float(-0.14, 0.14)), g.rMin, g.rMax);
        const x = ini.x + Math.cos(a) * r, z = ini.z + Math.sin(a) * r;
        const idx = s.elegirClave(g.claves, x, z, laxo);
        if (s.apto(idx, x, z, laxo ? 9.5 : 11, laxo, p)) { s.plantar(idx, x, z); puestos++; }
      }
    }
  }
}

/**
 * Balance entre jugadores: coeficiente de variación del stock cosechable a menos
 * de `RADIO_DOTACION` metros de cada base. 0 = mapa perfectamente parejo.
 */
function varianzaDotacion(nodos, inicios, radio = RADIO_DOTACION) {
  if (inicios.length < 2) return 0;
  const suma = new Float64Array(inicios.length);
  const r2 = radio * radio;
  for (const n of nodos) {
    const def = NODOS[NODO_POR_CLAVE.get(n.clave)];
    const peso = def?.cantidad || 0;
    if (peso <= 0) continue;
    // se lo lleva la base más cercana: si dos discos se solapan, no se cuenta doble
    let duenio = -1, mejor = r2;
    for (let i = 0; i < inicios.length; i++) {
      const dx = n.x - inicios[i].x, dz = n.z - inicios[i].z;
      const d = dx * dx + dz * dz;
      if (d <= mejor) { mejor = d; duenio = i; }
    }
    if (duenio >= 0) suma[duenio] += peso;
  }
  let media = 0;
  for (let i = 0; i < suma.length; i++) media += suma[i];
  media /= suma.length;
  if (media <= 0) return 1;
  let v = 0;
  for (let i = 0; i < suma.length; i++) v += (suma[i] - media) * (suma[i] - media);
  return Math.sqrt(v / suma.length) / media;
}

/** Siembra dispersa por Poisson-disk sobre todo el mapa. */
function sembrarDisperso(s, lista, opciones) {
  const { radio, maxPuntos = 400, dMinBase = 44, prob = 1, soloBiomas = 0, semillas = 700 } = opciones;
  const rej = s.rej;
  const BORDE = 10;
  const filtro = (x, z) => (soloBiomas === 0 || (soloBiomas & (1 << s.biomaEn(x, z))) !== 0);
  const puntos = poissonDisk(s.rng, {
    x0: -rej.mitad + BORDE, z0: -rej.mitad + BORDE,
    ancho: rej.tam - BORDE * 2, alto: rej.tam - BORDE * 2,
    radio, maxPuntos, semillas,
    aceptar: (x, z) => filtro(x, z) && s.apto(s.elegirClave(lista, x, z), x, z, dMinBase),
  });
  let n = 0;
  for (const p of puntos) {
    if (s.nodos.length >= TOPE_NODOS) break;
    if (prob < 1 && !s.rng.bool(prob)) continue;
    const idx = s.elegirClave(lista, p.x, p.z);
    if (s.apto(idx, p.x, p.z, dMinBase)) { s.plantar(idx, p.x, p.z); n++; }
  }
  return n;
}

/**
 * Las cinco Patentes: sobre un anillo de ángulos iguales (equidistantes entre
 * sí) y con el desfase que las deja lo más lejos posible de todas las bases.
 */
function sembrarReliquias(s, inicios, tam, cantidad = 5) {
  const idx = iN('reliquia');
  const rng = s.rng;
  let mejor = null, mejorPuntaje = -Infinity;
  for (let intento = 0; intento < 48; intento++) {
    const off = rng.float(0, Math.PI * 2);
    const rad = tam * rng.float(0.10, 0.23);
    const puntos = [];
    let puntaje = Infinity;
    for (let k = 0; k < cantidad; k++) {
      const a = off + (k / cantidad) * Math.PI * 2;
      const p = { x: Math.cos(a) * rad, z: Math.sin(a) * rad };
      puntos.push(p);
      puntaje = Math.min(puntaje, s.distBase(p.x, p.z));
    }
    if (puntaje > mejorPuntaje) { mejorPuntaje = puntaje; mejor = puntos; }
  }

  const puestas = [];
  for (const p of mejor) {
    const v = acomodar(p.x, p.z, (x, z) => s.apto(idx, x, z, 52), 40, 130);
    if (v) { s.plantar(idx, v.x, v.z); puestas.push(v); }
  }
  if (puestas.length >= cantidad) return puestas.length;

  // En mapas de agua el anillo puede caer en el mar: se completa eligiendo, de
  // entre los candidatos válidos, el que quede más lejos de todo lo ya puesto.
  const BORDE = 12;
  for (const dMin of [48, 34, 22]) {
    if (puestas.length >= cantidad) break;
    const cands = poissonDisk(rng, {
      x0: -s.rej.mitad + BORDE, z0: -s.rej.mitad + BORDE,
      ancho: s.rej.tam - BORDE * 2, alto: s.rej.tam - BORDE * 2,
      radio: 22, maxPuntos: 420, semillas: 700,
      aceptar: (x, z) => s.apto(idx, x, z, dMin),
    });
    while (puestas.length < cantidad && cands.length) {
      let elegido = -1, mejorD = -1;
      for (let i = 0; i < cands.length; i++) {
        let d = s.distBase(cands[i].x, cands[i].z);
        for (const p of puestas) d = Math.min(d, Math.hypot(cands[i].x - p.x, cands[i].z - p.z));
        if (d > mejorD) { mejorD = d; elegido = i; }
      }
      if (elegido < 0) break;
      const c = cands.splice(elegido, 1)[0];
      if (s.apto(idx, c.x, c.z, dMin)) { s.plantar(idx, c.x, c.z); puestas.push(c); }
    }
  }
  return puestas.length;
}

/** Todo lo que no es dotación garantizada: bosques, minas, fauna y pesca. */
function sembrarAmbiente(s, inicios, perfil, tam) {
  const dens = (v) => Math.max(0.25, v || 1);
  sembrarReliquias(s, inicios, tam);

  // El bosque se come el presupuesto de entidades si lo dejás: primero se
  // reserva lo que necesitan minas, fauna y pesca, que son las que se juegan.
  const presupuesto = clamp(TOPE_NODOS - s.nodos.length - 360, 120, 900);
  sembrarDisperso(s, ARBOLES, {
    radio: clamp(3.0 / Math.sqrt(dens(perfil.densidadBosque)), 2.7, 6.5),
    maxPuntos: presupuesto, soloBiomas: 1 << B.BOSQUE, semillas: 900,
  });
  sembrarDisperso(s, [iN('veta_oro')], { radio: 58 / Math.sqrt(dens(perfil.densidadOro)), maxPuntos: 34 });
  sembrarDisperso(s, [iN('carbon')], { radio: 62 / Math.sqrt(dens(perfil.densidadCarbon)), maxPuntos: 30 });
  sembrarDisperso(s, [iN('pozo_petroleo')], { radio: 105, maxPuntos: 12 });
  sembrarDisperso(s, [iN('baya')], { radio: 76, maxPuntos: 16 });
  sembrarDisperso(s, [iN('ciervo')], { radio: 66, maxPuntos: 22 });
  sembrarDisperso(s, [iN('jabali')], { radio: 118, maxPuntos: 8 });
  // la pesca también se mantiene fuera del disco de balance: si no, un mapa de
  // islas queda desparejo por dónde le tocó la costa a cada uno
  sembrarDisperso(s, [iN('pez')], {
    radio: clamp(17 / Math.sqrt(dens(perfil.densidadPez)), 8, 30),
    maxPuntos: 240, dMinBase: 42, semillas: 900,
  });
  // árboles sueltos: rompen el vacío de la llanura sin taparle el paso a nadie
  sembrarDisperso(s, ARBOLES, {
    radio: clamp(14 / Math.sqrt(dens(perfil.densidadBosque)), 9, 30),
    maxPuntos: 300, prob: 0.65,
    soloBiomas: (1 << B.PRADERA) | (1 << B.PLAYA) | (1 << B.DESIERTO) | (1 << B.MONTANA),
  });
}

/* ═══════════════════════ 7. poblado inicial del mundo ═══════════════════════ */

/** La vista se engancha en `crear()`, cuando el radio todavía es 0: se corrige. */
function ajustarVista(ctx, id, radio) {
  const vista = ctx?.vista;
  if (!vista) return;
  try {
    const reg = vista.registros?.get?.(id);
    if (reg) { reg.radio = radio; reg.sucio = true; }
    else vista.registrar?.(id);
  } catch (e) { /* la vista puede no estar lista todavía: no es fatal */ }
}

function poblarMundo(ctx, mapa, rej) {
  const mundo = ctx?.mundo;
  if (!mundo) return;

  const idSede = EDIFICIO_POR_CLAVE.get('sede');
  const defSede = EDIFICIOS[idSede];
  const idColono = UNIDAD_POR_CLAVE.get('colono');
  const defColono = UNIDADES[idColono];
  const radioSede = Math.max(defSede.celdas[0], defSede.celdas[1]);
  const suelo = (x, z) => (ctx.terreno?.altura ? ctx.terreno.altura(x, z) : muestrear(mapa.alturas, rej, x, z));

  for (const ini of mapa.inicios) {
    const ang = Math.atan2(-ini.z, -ini.x);            // la fachada mira al centro
    const id = mundo.crear(TIPO.EDIFICIO, idSede, ini.x, ini.z, ini.jugador);
    mundo.py[id] = suelo(ini.x, ini.z);
    mundo.vidaMax[id] = defSede.vida;
    mundo.vida[id] = defSede.vida;
    mundo.radio[id] = radioSede;
    mundo.rot[id] = ang; mundo.rotObjetivo[id] = ang;
    mundo.estado[id] = ESTADO.QUIETO;
    mundo.progreso[id] = 1;                            // nace terminada, no en obra
    ctx.nav?.bloquear?.(ini.x, ini.z, defSede.celdas[0], defSede.celdas[1], 1);
    ajustarVista(ctx, id, radioSede);
    ctx.bus?.emit?.('entidad:creada', id);

    for (let k = 0; k < 3; k++) {
      const a = ang + (k - 1) * 0.55;
      const r = radioSede + 2.6;
      let cx = ini.x + Math.cos(a) * r, cz = ini.z + Math.sin(a) * r;
      const libre = ctx.nav?.puntoLibreCerca?.(cx, cz, 0.5);
      if (libre) { cx = libre.x; cz = libre.z; }
      const u = mundo.crear(TIPO.UNIDAD, idColono, cx, cz, ini.jugador);
      mundo.vidaMax[u] = defColono.vida;
      mundo.vida[u] = defColono.vida;
      mundo.velocidad[u] = defColono.velocidad;
      mundo.radio[u] = 0.45;
      mundo.py[u] = suelo(cx, cz);
      mundo.rot[u] = a; mundo.rotObjetivo[u] = a;
      mundo.estado[u] = ESTADO.QUIETO;
      ajustarVista(ctx, u, 0.45);
      ctx.bus?.emit?.('entidad:creada', u);
    }

    const bolsa = ctx.eco?.recursos?.[ini.jugador];
    if (bolsa) {
      bolsa.alimento = mapa.dotacionInicial.alimento;
      bolsa.materiales = mapa.dotacionInicial.materiales;
      bolsa.capital = mapa.dotacionInicial.capital;
      bolsa.energia = mapa.dotacionInicial.energia;
    }
  }

  for (const n of mapa.nodos) {
    if (mundo.maxUsado >= mundo.cap - 64) break;        // dejar aire para las unidades
    const defId = NODO_POR_CLAVE.get(n.clave);
    if (defId === undefined) continue;
    const def = NODOS[defId];
    const id = mundo.crear(TIPO.RECURSO, defId, n.x, n.z, 255);
    const stock = def.cantidad || 0;
    mundo.vidaMax[id] = stock;
    mundo.vida[id] = stock;                             // la vida ES el stock restante
    mundo.radio[id] = def.radio || 0.8;
    mundo.py[id] = suelo(n.x, n.z);
    mundo.rot[id] = n.rot; mundo.rotObjetivo[id] = n.rot;
    mundo.estado[id] = ESTADO.QUIETO;
    ajustarVista(ctx, id, def.radio || 0.8);
  }
}

/* ═══════════════════════ 8. API pública ═══════════════════════ */

/**
 * Genera un mapa completo y determinista.
 *
 * El orden no es negociable: roca → mar → erosión del agua → erosión térmica →
 * lagos y ríos → rasgos duros del tipo de mapa → clima → biomas → recursos.
 * Cambiarlo produce mapas que parecen ruido pintado de verde.
 */
export function generarMapa(ctx, opciones = {}) {
  const semilla = (((opciones.semilla ?? ctx?.semilla ?? 1337) >>> 0) || 1337) >>> 0;
  const tam = opciones.tam ?? 512;
  const jugadores = clamp(Math.round(opciones.jugadores ?? 2), 1, 8);
  const tipo = PERFILES[opciones.tipo] ? opciones.tipo : 'arabia';
  const perfil = PERFILES[tipo];

  const ruido = ctx?.ruido ?? new Ruido(semilla);
  const rng = new RNG((semilla ^ 0x9e3779b9) >>> 0);
  const rej = crearRejilla(tam);

  /* --- la roca --- */
  const inicios = disposicionInicios(tipo, jugadores, tam, perfil, rng);
  const alturas = sintetizarAlturas(ruido, rej, perfil, rng);
  const tierra = construirMascaraTierra(rej, tipo, perfil, inicios, ruido, rng, tam);
  // los mapas secos tienen más tierra firme y los húmedos más lagos: sale del
  // mismo número que después decide el bioma
  nivelarContinente(alturas, tierra, perfil.tierraFirme ?? clamp(0.92 - perfil.humedad * 0.10, 0.86, 0.96));
  aplicarMascaraTierra(alturas, tierra);

  /* --- el agua la esculpe --- */
  erosionHidraulica(alturas, rej.res, rej.paso, 22);
  erosionTermica(alturas, rej.res, rej.paso, 6);
  suavizar(alturas, rej.res, 0.5);

  let lleno = rellenarDepresiones(alturas, rej.res);
  tallarLagos(alturas, lleno, rej.res, 700);          // menos charcos, lagos de verdad
  if (perfil.rios > 0) {
    lleno = rellenarDepresiones(alturas, rej.res);    // los lagos cambiaron el drenaje
    trazarRios(alturas, lleno, rej, perfil.rios, rng);
  }

  /* --- lo que define el tipo de mapa --- */
  tallarRasgosDuros(alturas, rej, tipo, perfil, inicios, ruido, tam);

  /* --- las bases, sobre el terreno ya definitivo --- */
  let pendientes = calcularPendientes(alturas, rej);
  reubicarInicios(alturas, pendientes, rej, inicios, tam);
  for (const ini of inicios) aplanarInicio(alturas, rej, ini.x, ini.z, 10, 8);

  /* --- clima y biomas --- */
  pendientes = calcularPendientes(alturas, rej);
  const distAgua = distanciaAlAgua(alturas, rej);
  const humedad = calcularHumedad(alturas, distAgua, rej, ruido, perfil, rng);
  const biomas = clasificarBiomas(alturas, pendientes, humedad, distAgua, perfil);
  for (const ini of inicios) ini.y = muestrear(alturas, rej, ini.x, ini.z);

  /* --- recursos: se reintenta hasta que el mapa quede parejo --- */
  const campos = { rej, alturas, pendientes, biomas };
  let mejor = null, mejorCV = Infinity, intentos = 0;
  for (let t = 0; t < 20; t++) {
    intentos = t + 1;
    const s = crearSembrador(campos, inicios, new RNG((semilla ^ (0x51ed270b + t * 0x9e3779b9)) >>> 0));
    sembrarDotacion(s, inicios);
    const cv = varianzaDotacion(s.nodos, inicios);
    if (cv < mejorCV) { mejorCV = cv; mejor = s; }
    if (cv < CV_MAXIMA) break;
  }
  sembrarAmbiente(mejor, inicios, perfil, tam);
  const cvFinal = varianzaDotacion(mejor.nodos, inicios);

  const mapa = {
    semilla, tam, res: rej.res,
    alturas, biomas, humedad, pendientes,
    nivelAgua: NIVEL_AGUA,
    inicios: inicios.map((s) => ({ x: s.x, z: s.z, jugador: s.jugador, y: s.y, ang: s.ang })),
    nodos: mejor.nodos,
    tipo,
    nombresBioma: TIPOS_BIOMA,
    dotacionInicial: { alimento: 200, materiales: 200, capital: 100, energia: 100 },
    poblar(c) { poblarMundo(c || ctx, mapa, rej); },
  };

  console.info(
    `[mapa] ${TIPOS_MAPA.find((m) => m.clave === tipo)?.nombre ?? tipo} · semilla ${semilla} · ` +
    `${jugadores} jugadores · ${mapa.nodos.length} nodos · simetría ${(cvFinal * 100).toFixed(1)}% ` +
    `(${intentos} ${intentos === 1 ? 'intento' : 'intentos'})`,
  );
  return mapa;
}

/* ═══════════════════════ 9. previsualización 2D ═══════════════════════ */

const COLOR_BIOMA = [
  [104, 142, 62],    // pradera
  [58, 96, 46],      // bosque
  [132, 126, 118],   // montaña
  [206, 180, 116],   // desierto
  [150, 205, 214],   // playa (celeste de orilla)
  [40, 90, 150],     // agua (se recalcula por profundidad)
];
const COLOR_AGUA_HONDA = [16, 42, 84];
const COLOR_AGUA_BAJA = [64, 148, 186];
const LUZ = (() => {
  const v = [-0.52, 0.74, -0.43];
  const n = Math.hypot(v[0], v[1], v[2]);
  return [v[0] / n, v[1] / n, v[2] / n];
})();

/**
 * Minimapa del mapa generado: bioma + sombreado de relieve + bases.
 * Devuelve un `<canvas>` listo para meter en el DOM (o null fuera del navegador).
 */
export function previsualizarMapa(mapa, lado = 256) {
  if (typeof document === 'undefined' || !mapa?.alturas) return null;
  const L = Math.max(32, Math.round(lado));
  const lienzo = document.createElement('canvas');
  lienzo.width = L; lienzo.height = L;
  const g = lienzo.getContext('2d');
  if (!g) return lienzo;

  const res = mapa.res;
  const tam = mapa.tam;
  const paso = tam / (res - 1);
  const nivel = mapa.nivelAgua ?? 0;
  const alt = mapa.alturas, bio = mapa.biomas, pend = mapa.pendientes;
  const img = g.createImageData(L, L);
  const px = img.data;

  for (let j = 0; j < L; j++) {
    const cj = Math.min(res - 1, ((j * res / L) | 0));
    for (let i = 0; i < L; i++) {
      const ci = Math.min(res - 1, ((i * res / L) | 0));
      const c = cj * res + ci;
      const h = alt[c];
      const b = bio ? bio[c] : (h < nivel ? B.AGUA : B.PRADERA);
      let r, v, a;

      if (b === B.AGUA || h < nivel) {
        // el degradado de profundidad es lo que hace legible la costa de un vistazo
        const prof = clamp((nivel - h) / 11, 0, 1);
        const t = prof * prof * 0.85 + prof * 0.15;
        r = lerp(COLOR_AGUA_BAJA[0], COLOR_AGUA_HONDA[0], t);
        v = lerp(COLOR_AGUA_BAJA[1], COLOR_AGUA_HONDA[1], t);
        a = lerp(COLOR_AGUA_BAJA[2], COLOR_AGUA_HONDA[2], t);
      } else {
        const col = COLOR_BIOMA[b] || COLOR_BIOMA[0];
        r = col[0]; v = col[1]; a = col[2];
        // nieve en las cumbres: sólo un poco, para que la cordillera se lea
        const nieve = smoothstep(23, 34, h);
        if (nieve > 0) {
          r = lerp(r, 238, nieve); v = lerp(v, 242, nieve); a = lerp(a, 248, nieve);
        }
        // sombreado por relieve (sol del noroeste) sobre la rejilla fina
        const iz = ci > 0 ? c - 1 : c, de = ci < res - 1 ? c + 1 : c;
        const ar = cj > 0 ? c - res : c, ab = cj < res - 1 ? c + res : c;
        const hx = (alt[de] - alt[iz]) * 0.5, hz = (alt[ab] - alt[ar]) * 0.5;
        const nx = -hx, ny = paso, nz = -hz;
        const inv = 1 / Math.max(1e-5, Math.sqrt(nx * nx + ny * ny + nz * nz));
        const dif = (nx * LUZ[0] + ny * LUZ[1] + nz * LUZ[2]) * inv;
        let luz = clamp(0.52 + 0.72 * dif, 0.28, 1.3);
        if (pend) luz *= 1 - 0.16 * clamp(pend[c], 0, 1);
        r *= luz; v *= luz; a *= luz;
      }

      const o = (j * L + i) * 4;
      px[o] = clamp(r, 0, 255); px[o + 1] = clamp(v, 0, 255); px[o + 2] = clamp(a, 0, 255); px[o + 3] = 255;
    }
  }
  g.putImageData(img, 0, 0);

  // las bases, con el color de cada jugador
  const rPunto = Math.max(2.5, L / 52);
  for (const ini of mapa.inicios || []) {
    const x = ((ini.x + tam * 0.5) / tam) * L;
    const z = ((ini.z + tam * 0.5) / tam) * L;
    g.beginPath();
    g.arc(x, z, rPunto + 1.4, 0, Math.PI * 2);
    g.fillStyle = 'rgba(12,14,18,0.65)';
    g.fill();
    g.beginPath();
    g.arc(x, z, rPunto, 0, Math.PI * 2);
    g.fillStyle = COLORES_JUGADOR[(ini.jugador ?? 0) % COLORES_JUGADOR.length];
    g.fill();
    g.lineWidth = Math.max(1, L / 220);
    g.strokeStyle = 'rgba(255,255,255,0.9)';
    g.stroke();
  }
  return lienzo;
}
