/**
 * BIBLIOTECA DE TEXTURAS PROCEDURALES — la base visual del juego.
 *
 * Todo sale de aritmética + ruido determinista (src/core/RNG.js). Cero assets.
 *
 * Cómo está armado, de abajo hacia arriba:
 *   1. `RuidoTeja`: ruido de gradiente y celular PERIÓDICO. La periodicidad es
 *      exacta porque el hash trabaja sobre la celda envuelta con módulo, así que
 *      no hay costura ni fantasmas de mezcla (el truco de mezclar 4 copias
 *      espejadas lava el contraste; esto no).
 *   2. `Campo`: seis búferes float por textura (albedo, altura, rugosidad,
 *      metálico, AO, alfa). El generador de cada clave sólo escribe números.
 *   3. `finalizar()`: deriva la normal por Sobel sobre la MISMA altura, hornea
 *      AO de cavidad con un desenfoque de caja, y empaqueta ORM en una sola
 *      textura (R=AO, G=rugosidad, B=metálico) como hace glTF: tres mapas por
 *      el precio de uno en VRAM y en samplers.
 *
 * Las capas macro se calculan a resolución reducida y se amplían bilinealmente:
 * una mancha de 3 ciclos por textura no necesita 512 muestras por eje, y eso
 * baja el costo de carga de decenas de segundos a menos de dos.
 */
import * as THREE from 'three';
import { RNG, Ruido, clamp, lerp, smoothstep } from '../core/RNG.js';
import { EDADES } from '../data/edades.js';

/* ══════════════════════════════════════════════════════════════════════════
   Color
   ══════════════════════════════════════════════════════════════════════════ */

/** '#rrggbb' -> [r,g,b] en 0..1 (espacio sRGB, que es lo que se escribe al byte). */
function C(hex) {
  const s = hex.charCodeAt(0) === 35 ? hex.slice(1) : hex;
  const v = parseInt(s, 16);
  return [((v >> 16) & 255) / 255, ((v >> 8) & 255) / 255, (v & 255) / 255];
}
const pon = (A, i, c) => { A[i] = c[0]; A[i + 1] = c[1]; A[i + 2] = c[2]; };
const mez = (A, i, c, t) => {
  A[i] += (c[0] - A[i]) * t; A[i + 1] += (c[1] - A[i + 1]) * t; A[i + 2] += (c[2] - A[i + 2]) * t;
};
const esc = (A, i, k) => { A[i] *= k; A[i + 1] *= k; A[i + 2] *= k; };
const sat = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);

/* ══════════════════════════════════════════════════════════════════════════
   Ruido periódico (tileable de verdad)
   ══════════════════════════════════════════════════════════════════════════ */

// 8 direcciones: alcanza para gradiente 2D y evita una multiplicación por eje.
const GRAD = new Float32Array([
  1, 0, -1, 0, 0, 1, 0, -1,
  0.70710678, 0.70710678, -0.70710678, 0.70710678,
  0.70710678, -0.70710678, -0.70710678, -0.70710678,
]);

class RuidoTeja {
  /** Reusa la tabla de permutación del Ruido del ctx: misma semilla, mismo mundo. */
  constructor(ruido) { this.p = ruido.perm; }

  hash(x, y, s) {
    const p = this.p;
    return p[(x + p[(y + p[s & 255]) & 255]) & 255];
  }

  /**
   * Gradiente tipo Perlin con período entero (px,py) en celdas. Devuelve ~[-1,1].
   * `x` viene en unidades de celda, no en píxeles.
   */
  perlin(x, y, px, py, s) {
    const x0 = Math.floor(x), y0 = Math.floor(y);
    const fx = x - x0, fy = y - y0;
    const u = fx * fx * fx * (fx * (fx * 6 - 15) + 10);
    const v = fy * fy * fy * (fy * (fy * 6 - 15) + 10);
    const xa = ((x0 % px) + px) % px, xb = ((x0 + 1) % px + px) % px;
    const ya = ((y0 % py) + py) % py, yb = ((y0 + 1) % py + py) % py;
    const g00 = (this.hash(xa, ya, s) & 7) << 1;
    const g10 = (this.hash(xb, ya, s) & 7) << 1;
    const g01 = (this.hash(xa, yb, s) & 7) << 1;
    const g11 = (this.hash(xb, yb, s) & 7) << 1;
    const n00 = GRAD[g00] * fx + GRAD[g00 + 1] * fy;
    const n10 = GRAD[g10] * (fx - 1) + GRAD[g10 + 1] * fy;
    const n01 = GRAD[g01] * fx + GRAD[g01 + 1] * (fy - 1);
    const n11 = GRAD[g11] * (fx - 1) + GRAD[g11 + 1] * (fy - 1);
    const a = n00 + (n10 - n00) * u;
    const b = n01 + (n11 - n01) * u;
    return (a + (b - a) * v) * 1.4;
  }
}

const pot2 = (v) => 1 << Math.ceil(Math.log2(Math.max(2, v)));

/** Ampliación bilineal con envoltura: mantiene la teja al subir de resolución. */
function ampliar(src, m, n) {
  if (m === n) return src;
  const dst = new Float32Array(n * n);
  const k = m / n;
  for (let y = 0; y < n; y++) {
    const sy = (y + 0.5) * k - 0.5;
    const y0 = Math.floor(sy), ty = sy - y0;
    const ya = ((y0 % m) + m) % m, yb = ((y0 + 1) % m + m) % m;
    for (let x = 0; x < n; x++) {
      const sx = (x + 0.5) * k - 0.5;
      const x0 = Math.floor(sx), tx = sx - x0;
      const xa = ((x0 % m) + m) % m, xb = ((x0 + 1) % m + m) % m;
      const a = src[ya * m + xa] + (src[ya * m + xb] - src[ya * m + xa]) * tx;
      const b = src[yb * m + xa] + (src[yb * m + xb] - src[yb * m + xa]) * tx;
      dst[y * n + x] = a + (b - a) * ty;
    }
  }
  return dst;
}

/** Idem pero al vecino más cercano: los identificadores de celda no se interpolan. */
function ampliarNN(src, m, n) {
  if (m === n) return src;
  const dst = new Uint8Array(n * n);
  const k = m / n;
  for (let y = 0; y < n; y++) {
    const sy = Math.min(m - 1, Math.floor(y * k));
    for (let x = 0; x < n; x++) dst[y * n + x] = src[sy * m + Math.min(m - 1, Math.floor(x * k))];
  }
  return dst;
}

/**
 * Capa escalar fractal. `fx`/`fy` son ciclos por textura (enteros: de ahí sale
 * la teja). `tipo`: 'fbm' -> [-1,1] · 'ridged' -> [0,1] · 'turb' -> [0,1].
 * `warp` deforma el dominio con ruido periódico, así que sigue tejando.
 */
function capaRuido(rt, n, cfg) {
  const fx = Math.max(1, Math.round(cfg.fx || 4));
  const fy = Math.max(1, Math.round(cfg.fy || cfg.fx || 4));
  const oct = cfg.oct || 4, gan = cfg.gan == null ? 0.5 : cfg.gan;
  const sal = cfg.sal | 0, tipo = cfg.tipo || 'fbm';
  const warp = cfg.warp || 0;
  const fw = Math.max(1, Math.round(cfg.warpFrec || 2));
  // 3 muestras por período de la octava más fina: por debajo de eso se nota el escalón.
  const fMax = Math.max(fx, fy) * (1 << (oct - 1)) + (warp ? fw * 2 : 0);
  const m = Math.min(n, pot2(Math.ceil(fMax * 3)));
  const out = new Float32Array(m * m);
  for (let y = 0; y < m; y++) {
    const v = (y + 0.5) / m;
    for (let x = 0; x < m; x++) {
      const u = (x + 0.5) / m;
      let cx = u * fx, cy = v * fy;
      if (warp) {
        const wx = rt.perlin(u * fw, v * fw, fw, fw, sal + 211);
        const wy = rt.perlin(u * fw, v * fw, fw, fw, sal + 307);
        cx += wx * warp; cy += wy * warp;
      }
      let amp = 1, f = 1, suma = 0, norm = 0;
      for (let o = 0; o < oct; o++) {
        const p = rt.perlin(cx * f, cy * f, fx * f, fy * f, sal + o * 37);
        if (tipo === 'ridged') { const t = 1 - Math.abs(p); suma += amp * t * t; }
        else if (tipo === 'turb') suma += amp * Math.abs(p);
        else suma += amp * p;
        norm += amp; amp *= gan; f *= 2;
      }
      out[y * m + x] = suma / norm;
    }
  }
  return ampliar(out, m, n);
}

/**
 * Worley periódico. `cx`/`cy` = celdas por textura. Devuelve F1, F2 y un id de
 * celda (para variar tono por piedra / por ladrillo / por teja).
 */
function capaWorley(rt, n, cfg) {
  const cx = Math.max(1, Math.round(cfg.cx || 8));
  const cy = Math.max(1, Math.round(cfg.cy || cfg.cx || 8));
  const sal = cfg.sal | 0;
  const m = Math.min(n, pot2(Math.max(cx, cy) * (cfg.muestras || 8)));
  const f1 = new Float32Array(m * m), f2 = new Float32Array(m * m), id = new Uint8Array(m * m);
  for (let y = 0; y < m; y++) {
    const py = ((y + 0.5) / m) * cy;
    const iy = Math.floor(py);
    for (let x = 0; x < m; x++) {
      const px = ((x + 0.5) / m) * cx;
      const ix = Math.floor(px);
      let d1 = 9, d2 = 9, mejor = 0;
      for (let oy = -1; oy <= 1; oy++) {
        const gy = iy + oy, wy = ((gy % cy) + cy) % cy;
        for (let ox = -1; ox <= 1; ox++) {
          const gx = ix + ox, wx = ((gx % cx) + cx) % cx;
          const ha = rt.hash(wx, wy, sal), hb = rt.hash(wx, wy, sal + 53);
          const jx = gx + 0.12 + (ha / 255) * 0.76;
          const jy = gy + 0.12 + (hb / 255) * 0.76;
          const dx = jx - px, dy = jy - py;
          const d = Math.sqrt(dx * dx + dy * dy);
          if (d < d1) { d2 = d1; d1 = d; mejor = rt.hash(wx, wy, sal + 97); }
          else if (d < d2) d2 = d;
        }
      }
      const i = y * m + x;
      f1[i] = d1; f2[i] = d2; id[i] = mejor;
    }
  }
  return { f1: ampliar(f1, m, n), f2: ampliar(f2, m, n), id: ampliarNN(id, m, n) };
}

/** Desenfoque de caja separable con envoltura. Base del AO de cavidad. */
function suavizarCaja(src, n, r) {
  if (r < 1) return src;
  const inv = 1 / (2 * r + 1);
  const tmp = new Float32Array(n * n), out = new Float32Array(n * n);
  for (let y = 0; y < n; y++) {
    const f = y * n; let suma = 0;
    for (let k = -r; k <= r; k++) suma += src[f + (((k % n) + n) % n)];
    for (let x = 0; x < n; x++) {
      tmp[f + x] = suma * inv;
      suma -= src[f + (((x - r) % n + n) % n)];
      suma += src[f + (((x + r + 1) % n + n) % n)];
    }
  }
  for (let x = 0; x < n; x++) {
    let suma = 0;
    for (let k = -r; k <= r; k++) suma += tmp[(((k % n) + n) % n) * n + x];
    for (let y = 0; y < n; y++) {
      out[y * n + x] = suma * inv;
      suma -= tmp[(((y - r) % n + n) % n) * n + x];
      suma += tmp[(((y + r + 1) % n + n) % n) * n + x];
    }
  }
  return out;
}

/**
 * Escurrido vertical: propaga el máximo hacia abajo con decaimiento. Es lo que
 * convierte una mancha de óxido en un chorreado y una junta en una veta de agua.
 * (La fila crece hacia abajo en la imagen, así que el goteo va con el índice.)
 */
function escurrir(src, n, decaimiento) {
  const out = new Float32Array(src);
  for (let x = 0; x < n; x++) {
    let acc = 0;
    // dos vueltas: la primera carga el acumulador con la envoltura de la teja
    for (let paso = 0; paso < 2; paso++) {
      for (let y = 0; y < n; y++) {
        const i = y * n + x;
        acc *= decaimiento;
        if (src[i] > acc) acc = src[i];
        if (paso === 1 && acc > out[i]) out[i] = acc;
      }
    }
  }
  return out;
}

/* ══════════════════════════════════════════════════════════════════════════
   Normal por diferencias finitas (Sobel) sobre el campo de altura
   ══════════════════════════════════════════════════════════════════════════ */

/**
 * @param {Float32Array|Uint8ClampedArray|number[]} datosAltura  altura 0..1 (o gris 0..255)
 * @returns {ImageData} normal tangente, convención OpenGL (+Y hacia arriba en UV)
 */
export function generarMapaNormalDesdeAltura(datosAltura, ancho, alto, fuerza = 1) {
  const px = ancho * alto;
  let H = datosAltura;
  if (!(H instanceof Float32Array)) {
    const tmp = new Float32Array(px);
    const paso = datosAltura.length >= px * 4 ? 4 : 1;
    const div = paso === 4 || datosAltura instanceof Uint8ClampedArray ? 255 : 1;
    for (let i = 0; i < px; i++) tmp[i] = datosAltura[i * paso] / div;
    H = tmp;
  }
  const out = new Uint8ClampedArray(px * 4);
  const k = fuerza * ancho * 0.012; // escala en píxeles: la pendiente no depende del tamaño
  for (let y = 0; y < alto; y++) {
    const ya = ((y - 1) + alto) % alto, yb = (y + 1) % alto;
    for (let x = 0; x < ancho; x++) {
      const xa = ((x - 1) + ancho) % ancho, xb = (x + 1) % ancho;
      // Sobel 3x3: menos ruidoso que la diferencia central pelada.
      const h00 = H[ya * ancho + xa], h10 = H[ya * ancho + x], h20 = H[ya * ancho + xb];
      const h01 = H[y * ancho + xa], h21 = H[y * ancho + xb];
      const h02 = H[yb * ancho + xa], h12 = H[yb * ancho + x], h22 = H[yb * ancho + xb];
      const gx = (h20 + 2 * h21 + h22) - (h00 + 2 * h01 + h02);
      // el eje V apunta hacia arriba en pantalla, y la fila crece hacia abajo
      const gv = (h00 + 2 * h10 + h20) - (h02 + 2 * h12 + h22);
      let nx = -gx * k, ny = -gv * k, nz = 1;
      const inv = 1 / Math.sqrt(nx * nx + ny * ny + 1);
      nx *= inv; ny *= inv; nz *= inv;
      const i = (y * ancho + x) * 4;
      out[i] = (nx * 0.5 + 0.5) * 255;
      out[i + 1] = (ny * 0.5 + 0.5) * 255;
      out[i + 2] = (nz * 0.5 + 0.5) * 255;
      out[i + 3] = 255;
    }
  }
  return typeof ImageData !== 'undefined'
    ? new ImageData(out, ancho, alto)
    : { data: out, width: ancho, height: alto };
}

/* ══════════════════════════════════════════════════════════════════════════
   Lienzos y texturas
   ══════════════════════════════════════════════════════════════════════════ */

function crearLienzo(n) {
  if (typeof OffscreenCanvas !== 'undefined') return new OffscreenCanvas(n, n);
  const c = document.createElement('canvas');
  c.width = n; c.height = n;
  return c;
}

function lienzoDesde(imgData, n) {
  const lienzo = crearLienzo(n);
  const g = lienzo.getContext('2d', { willReadFrequently: false });
  g.putImageData(imgData, 0, 0);
  return lienzo;
}

/**
 * Helper público: textura de ruido tejable lista para usar (agua, disolvencias,
 * scroll de humo en shaders). `fuente` puede ser el ctx o un `Ruido`.
 */
export function texturaRuido(fuente, opciones = {}) {
  const ruido = fuente && fuente.ruido ? fuente.ruido : (fuente instanceof Ruido ? fuente : new Ruido(1337));
  const n = opciones.n || 256;
  const rt = new RuidoTeja(ruido);
  const canales = opciones.canales || 1;
  const capas = [];
  for (let c = 0; c < canales; c++) {
    capas.push(capaRuido(rt, n, {
      tipo: opciones.tipo || 'fbm', fx: opciones.fx || 8, fy: opciones.fy || opciones.fx || 8,
      oct: opciones.oct || 4, gan: opciones.gan, warp: opciones.warp || 0,
      sal: (opciones.sal | 0) + c * 601,
    }));
  }
  const datos = new Uint8ClampedArray(n * n * 4);
  const rango = (opciones.tipo || 'fbm') === 'fbm';
  for (let i = 0; i < n * n; i++) {
    const j = i * 4;
    for (let c = 0; c < 3; c++) {
      const v = capas[Math.min(c, canales - 1)][i];
      datos[j + c] = (rango ? v * 0.5 + 0.5 : v) * 255;
    }
    datos[j + 3] = 255;
  }
  const img = typeof ImageData !== 'undefined' ? new ImageData(datos, n, n) : { data: datos, width: n, height: n };
  const tex = new THREE.CanvasTexture(lienzoDesde(img, n));
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.colorSpace = opciones.colorSpace || THREE.NoColorSpace;
  tex.generateMipmaps = true;
  tex.minFilter = THREE.LinearMipmapLinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.needsUpdate = true;
  return tex;
}

/** Tintes de cada edad, leídos de src/data/edades.js. */
export function paletaEdad(edad) {
  const e = EDADES[clamp(edad | 0, 0, EDADES.length - 1)];
  const p = e.paleta;
  return {
    clave: e.clave,
    nombre: e.nombre,
    primario: new THREE.Color(p.primario),
    secundario: new THREE.Color(p.secundario),
    acento: new THREE.Color(p.acento),
    humo: new THREE.Color(p.humo),
    hex: { ...p },
    // multiplicador neutro-cálido que se aplica al albedo de los edificios de la edad
    tinte: new THREE.Color(p.primario).lerp(new THREE.Color('#ffffff'), 0.55),
  };
}

/* ══════════════════════════════════════════════════════════════════════════
   Campo: los búferes que llena cada generador
   ══════════════════════════════════════════════════════════════════════════ */

class Campo {
  constructor(n, conAlfa, conEmision) {
    const p = n * n;
    this.n = n;
    this.alb = new Float32Array(p * 3);
    this.alt = new Float32Array(p);
    this.rug = new Float32Array(p);
    this.met = new Float32Array(p);
    this.ao = new Float32Array(p).fill(1);
    this.alfa = conAlfa ? new Float32Array(p).fill(1) : null;
    this.emis = conEmision ? new Float32Array(p * 3) : null;
  }
}

/* ══════════════════════════════════════════════════════════════════════════
   Configuración por clave
   ══════════════════════════════════════════════════════════════════════════ */

const CFG = {
  pasto:           { normal: 1.5, cavidad: 0.9, radio: 6 },
  pasto_seco:      { normal: 1.4, cavidad: 0.9, radio: 6 },
  tierra:          { normal: 1.7, cavidad: 1.0, radio: 7 },
  arena:           { normal: 1.1, cavidad: 0.5, radio: 5 },
  roca:            { normal: 2.1, cavidad: 1.1, radio: 8 },
  grava:           { normal: 2.0, cavidad: 1.2, radio: 5 },
  nieve:           { normal: 1.0, cavidad: 0.6, radio: 8 },
  asfalto:         { normal: 1.0, cavidad: 0.7, radio: 4 },
  hormigon:        { normal: 0.9, cavidad: 0.7, radio: 5 },
  ladrillo:        { normal: 1.9, cavidad: 1.2, radio: 4 },
  madera_tabla:    { normal: 1.3, cavidad: 0.9, radio: 4 },
  madera_vieja:    { normal: 1.7, cavidad: 1.1, radio: 4 },
  metal_pintado:   { normal: 0.8, cavidad: 0.6, radio: 4 },
  metal_oxidado:   { normal: 1.4, cavidad: 0.8, radio: 5 },
  chapa_ondulada:  { normal: 2.2, cavidad: 0.8, radio: 6 },
  teja:            { normal: 2.0, cavidad: 1.3, radio: 6 },
  vidrio:          { normal: 0.35, cavidad: 0.2, radio: 6, alfa: true },
  panel_compuesto: { normal: 1.0, cavidad: 0.8, radio: 4 },
  panel_led:       { normal: 1.0, cavidad: 0.9, radio: 3, emision: true },
  marmol:          { normal: 0.5, cavidad: 0.35, radio: 6 },
  lona:            { normal: 1.2, cavidad: 0.9, radio: 3 },
  tela_uniforme:   { normal: 0.9, cavidad: 0.8, radio: 3 },
  cuero:           { normal: 1.3, cavidad: 1.0, radio: 4 },
  agua_espuma:     { normal: 1.1, cavidad: 0.6, radio: 4, alfa: true },
  humo:            { normal: 0.7, cavidad: 0.3, radio: 6, alfa: true },
  chispa:          { normal: 0.2, cavidad: 0.0, radio: 0, alfa: true, emision: true },
  destello:        { normal: 0.2, cavidad: 0.0, radio: 0, alfa: true, emision: true },
  particula_humo:  { n: 128, normal: 0.6, cavidad: 0.2, radio: 3, alfa: true },
  particula_fuego: { n: 128, normal: 0.4, cavidad: 0.0, radio: 0, alfa: true, emision: true },
  particula_polvo: { n: 128, normal: 0.5, cavidad: 0.2, radio: 3, alfa: true },
  anillo_choque:   { n: 128, normal: 0.3, cavidad: 0.0, radio: 0, alfa: true, emision: true },
  decal_crater:    { n: 128, normal: 1.8, cavidad: 1.0, radio: 4, alfa: true },
  decal_quemadura: { n: 128, normal: 0.6, cavidad: 0.4, radio: 3, alfa: true },
};

/** Orden de precarga: primero lo que se ve apenas arranca la partida. */
/**
 * Resolución relativa por clave. El coste de generar es CUADRÁTICO en el lado y
 * la precarga entera se hace pixel por pixel en el hilo principal: a 512 uniforme
 * el juego tardaba un minuto en arrancar, que es inaceptable.
 *
 * El reparto no es arbitrario. El terreno se ve estirado sobre cientos de metros
 * cuadrados y con la cámara casi encima en el zoom cercano: ahí cada téxel cuenta
 * y va a full. Un ladrillo o una chapa se ven sobre una pared de 4 m con la
 * repetición alta, así que a 0.5 nadie nota la diferencia y cuesta la cuarta
 * parte. Las telas y los efectos se ven chicos, borrosos o en movimiento.
 */
const FACTOR_RES = {
  pasto: 1, tierra: 1, roca: 1, pasto_seco: 1, arena: 1, grava: 1, nieve: 1,
  asfalto: 0.75, hormigon: 0.75,
  ladrillo: 0.5, madera_tabla: 0.5, madera_vieja: 0.5, teja: 0.5,
  metal_pintado: 0.5, metal_oxidado: 0.5, chapa_ondulada: 0.5,
  panel_compuesto: 0.5, panel_led: 0.5, marmol: 0.5, vidrio: 0.375,
  lona: 0.375, tela_uniforme: 0.375, cuero: 0.375, agua_espuma: 0.5,
  _resto: 0.5,
};

const ORDEN_PRECARGA = [
  'pasto', 'tierra', 'roca', 'pasto_seco', 'arena', 'grava', 'nieve', 'asfalto', 'hormigon',
  'ladrillo', 'madera_tabla', 'madera_vieja', 'teja', 'metal_pintado', 'metal_oxidado',
  'chapa_ondulada', 'vidrio', 'panel_compuesto', 'panel_led', 'marmol',
  'lona', 'tela_uniforme', 'cuero', 'agua_espuma', 'humo', 'chispa', 'destello',
  'particula_humo', 'particula_fuego', 'particula_polvo', 'anillo_choque',
  'decal_crater', 'decal_quemadura',
];

/* ══════════════════════════════════════════════════════════════════════════
   GENERADORES — uno por clave
   ══════════════════════════════════════════════════════════════════════════ */

const GEN = {};

/* ---------------------------------------------------------------- TERRENO */

/** Pasto y pasto seco comparten estructura: cambia la paleta y cuánta tierra asoma. */
function generarPasto(rt, c, rng, seco) {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const macro = capaRuido(rt, n, { fx: 3, oct: 3, sal: 11 });
  const medio = capaRuido(rt, n, { fx: 11, oct: 3, sal: 23, warp: 0.15, warpFrec: 3 });
  // briznas: ruido muy anisótropo en dos direcciones, mezcladas por una máscara
  // suave. El warp periódico curva los mechones sin romper la teja.
  const briA = capaRuido(rt, n, { fx: 9, fy: 72, oct: 2, sal: 41, warp: 0.35, warpFrec: 4 });
  const briB = capaRuido(rt, n, { fx: 64, fy: 12, oct: 2, sal: 59, warp: 0.35, warpFrec: 5 });
  const dir = capaRuido(rt, n, { fx: 2, oct: 2, sal: 71 });
  const matas = capaWorley(rt, n, { cx: 17, sal: 83, muestras: 12 });
  const secas = capaWorley(rt, n, { cx: 4, sal: 97, muestras: 24 });
  const grano = capaRuido(rt, n, { fx: 128, oct: 2, sal: 103 });

  const vOsc = C(seco ? '#5e5a2c' : '#33501e');
  const vMed = C(seco ? '#8f8341' : '#5f8a2e');
  const vCla = C(seco ? '#b7a659' : '#8cb045');
  const paja = C(seco ? '#c9b06a' : '#a89a4e');
  const suelo = C(seco ? '#7a5f3c' : '#5d452c');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const m = dir[i] * 0.5 + 0.5;
    const br = briA[i] * (1 - m) + briB[i] * m;      // -1..1
    const mata = smoothstep(0.55, 0.05, matas.f1[i]); // 0..1, centro de mechón
    const g = grano[i];

    // altura: mechones + brizna + grano fino
    let h = 0.34 + mata * 0.30 + br * 0.22 + medio[i] * 0.10 + g * 0.05;
    // parches secos y calvas de tierra
    const seq = sat(smoothstep(0.62, 0.95, secas.f1[i] * 0.75 + macro[i] * 0.35 + 0.4));
    const calva = sat(smoothstep(0.35, 0.02, mata * 0.7 + medio[i] * 0.5 + 0.5) * (seco ? 1.15 : 0.75));

    pon(A, i3, vOsc);
    mez(A, i3, vMed, sat(smoothstep(-0.45, 0.35, br) * 0.85 + macro[i] * 0.2 + 0.15));
    mez(A, i3, vCla, sat(smoothstep(0.25, 0.85, br * 0.6 + mata * 0.7)) * 0.75);
    mez(A, i3, paja, seq * (seco ? 0.8 : 0.55));
    mez(A, i3, suelo, calva * 0.85);
    // variación macro de tono: rompe la repetición a distancia de cámara
    esc(A, i3, 0.88 + macro[i] * 0.16 + g * 0.06);

    h = lerp(h, 0.16 + g * 0.05, calva * 0.8);
    H[i] = sat(h);
    R[i] = sat(0.86 + g * 0.08 + seq * 0.06 - mata * 0.05);
    O[i] = sat(0.52 + 0.48 * smoothstep(0.05, 0.75, h) + mata * 0.12);
  }
}
GEN.pasto = (rt, c, rng) => generarPasto(rt, c, rng, false);
GEN.pasto_seco = (rt, c, rng) => generarPasto(rt, c, rng, true);

GEN.tierra = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const macro = capaRuido(rt, n, { fx: 3, oct: 3, sal: 131 });
  const terrones = capaWorley(rt, n, { cx: 13, sal: 137, muestras: 14 });
  const grietas = capaWorley(rt, n, { cx: 6, sal: 149, muestras: 20 });
  const piedras = capaWorley(rt, n, { cx: 38, sal: 151, muestras: 8 });
  const grano = capaRuido(rt, n, { fx: 128, oct: 2, sal: 157 });
  const fino = capaRuido(rt, n, { fx: 24, oct: 3, sal: 163, warp: 0.2, warpFrec: 3 });

  const claro = C('#7d603c'), medio = C('#5c452b'), oscuro = C('#3a2a1a');
  const humedo = C('#2e2114'), piedra = C('#8d8578');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const terron = smoothstep(0.62, 0.10, terrones.f1[i]);
    const grieta = smoothstep(0.16, 0.0, grietas.f2[i] - grietas.f1[i]);
    const esPiedra = piedras.id[i] > 200 ? smoothstep(0.28, 0.10, piedras.f1[i]) : 0;
    const g = grano[i];

    let h = 0.40 + terron * 0.26 + fino[i] * 0.12 + g * 0.06;
    h -= grieta * 0.34;
    h += esPiedra * 0.22;

    pon(A, i3, medio);
    mez(A, i3, claro, sat(terron * 0.7 + fino[i] * 0.4 + 0.15));
    mez(A, i3, oscuro, sat(0.45 - fino[i] * 0.6) * 0.7);
    mez(A, i3, humedo, grieta * 0.75);
    mez(A, i3, humedo, sat(smoothstep(0.35, -0.2, macro[i])) * 0.35);
    mez(A, i3, piedra, esPiedra * 0.85);
    esc(A, i3, 0.9 + g * 0.14 + macro[i] * 0.08);

    H[i] = sat(h);
    R[i] = sat(0.93 + g * 0.06 - esPiedra * 0.2 - smoothstep(0.3, -0.3, macro[i]) * 0.12);
    O[i] = sat(0.5 + 0.5 * smoothstep(0.0, 0.7, h));
  }
};

GEN.arena = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const dunas = capaRuido(rt, n, { fx: 3, oct: 3, sal: 181 });
  const ondaWarp = capaRuido(rt, n, { fx: 4, oct: 2, sal: 191 });
  const grano = capaRuido(rt, n, { fx: 170, oct: 2, sal: 197 });
  const conchas = capaWorley(rt, n, { cx: 42, sal: 199, muestras: 8 });
  const claro = C('#e0c99a'), medio = C('#c9ad78'), oscuro = C('#a98d5c');

  for (let i = 0; i < n * n; i++) {
    const x = i % n, y = (i / n) | 0;
    const v = (y + 0.5) / n;
    // rizos: seno de período entero + deformación periódica => teja perfecta
    const fase = v * 9 + ondaWarp[i] * 0.9 + dunas[i] * 0.4;
    const rizo = Math.sin(fase * Math.PI * 2) * 0.5 + 0.5;
    const g = grano[i];
    const concha = conchas.id[i] > 236 ? smoothstep(0.22, 0.06, conchas.f1[i]) : 0;

    let h = 0.42 + rizo * 0.16 + dunas[i] * 0.20 + g * 0.07 + concha * 0.1;
    H[i] = sat(h);

    pon(A, i3d(i), medio);
    mez(A, i * 3, claro, sat(rizo * 0.7 + dunas[i] * 0.3 + 0.1));
    mez(A, i * 3, oscuro, sat(0.55 - rizo * 0.8) * 0.6);
    mez(A, i * 3, C('#f2e6cd'), concha * 0.9);
    esc(A, i * 3, 0.93 + g * 0.12);

    // mica: puntos aislados de rugosidad baja que centellean con el sol
    const brillo = g > 0.42 ? 1 : 0;
    R[i] = brillo ? 0.16 : sat(0.9 + g * 0.08);
    O[i] = sat(0.66 + 0.34 * smoothstep(0.15, 0.7, h));
    void x;
  }
};
const i3d = (i) => i * 3;

GEN.roca = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  // estratos: ridged estirado en un eje = capas sedimentarias
  const estratos = capaRuido(rt, n, { tipo: 'ridged', fx: 2, fy: 9, oct: 5, sal: 211, warp: 0.35, warpFrec: 3 });
  const macro = capaRuido(rt, n, { fx: 3, oct: 3, sal: 223 });
  const fract1 = capaWorley(rt, n, { cx: 5, sal: 227, muestras: 26 });
  const fract2 = capaWorley(rt, n, { cx: 12, sal: 229, muestras: 14 });
  const aspero = capaRuido(rt, n, { fx: 40, oct: 3, sal: 233 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 239 });
  const liquenN = capaRuido(rt, n, { fx: 6, oct: 3, sal: 241 });

  const gris = C('#6f6b62'), grisCl = C('#928d83'), grisOs = C('#4a463f');
  const ocre = C('#7c6a4e'), liquen = C('#7d8a4e'), liquen2 = C('#a8ad74');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const est = estratos[i];
    const cr1 = smoothstep(0.13, 0.0, fract1.f2[i] - fract1.f1[i]);
    const cr2 = smoothstep(0.10, 0.0, fract2.f2[i] - fract2.f1[i]) * 0.7;
    const cr = sat(cr1 + cr2);
    const g = grano[i], asp = aspero[i];

    let h = 0.36 + est * 0.34 + asp * 0.14 + g * 0.06 + macro[i] * 0.12;
    h -= cr * 0.42;
    H[i] = sat(h);

    pon(A, i3, gris);
    mez(A, i3, grisCl, sat(est * 0.9 + asp * 0.3));
    mez(A, i3, grisOs, sat(0.55 - est * 1.1) * 0.85);
    mez(A, i3, ocre, sat(macro[i] * 0.8 + 0.15) * 0.45);
    mez(A, i3, grisOs, cr * 0.8);
    // líquenes: sólo donde hay grieta o repisa y el ruido lo permite
    const liq = sat((cr * 0.8 + smoothstep(0.55, 0.85, est)) * smoothstep(0.1, 0.6, liquenN[i]));
    mez(A, i3, liquen, liq * 0.6);
    mez(A, i3, liquen2, liq * liq * 0.35);
    esc(A, i3, 0.9 + g * 0.14);

    R[i] = sat(0.74 + asp * 0.14 + cr * 0.14 + liq * 0.12 + g * 0.05);
    O[i] = sat(0.42 + 0.58 * smoothstep(-0.05, 0.7, h) - cr * 0.2);
  }
};

GEN.grava = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const p1 = capaWorley(rt, n, { cx: 20, sal: 251, muestras: 16 });
  const p2 = capaWorley(rt, n, { cx: 44, sal: 257, muestras: 10 });
  const grano = capaRuido(rt, n, { fx: 160, oct: 2, sal: 263 });
  const macro = capaRuido(rt, n, { fx: 4, oct: 3, sal: 269 });
  const tonos = [C('#8d8880'), C('#6f6a62'), C('#a09585'), C('#57534c'), C('#7d6f5c'), C('#b0a99c')];
  const arena = C('#5a5248');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const canto = smoothstep(0.50, 0.06, p1.f1[i]);
    const chico = smoothstep(0.34, 0.05, p2.f1[i]) * 0.7;
    const cubierto = Math.max(canto, chico);
    const t = tonos[(canto >= chico ? p1.id[i] : p2.id[i]) % tonos.length];
    const g = grano[i];

    // domo redondeado por piedra (raíz => hombros suaves, cima chata)
    const domo = Math.sqrt(cubierto);
    let h = 0.16 + domo * 0.62 + g * 0.05 + macro[i] * 0.06;
    H[i] = sat(h);

    pon(A, i3, arena);
    mez(A, i3, t, sat(cubierto * 1.25));
    esc(A, i3, 0.82 + domo * 0.24 + g * 0.13 + macro[i] * 0.06);

    R[i] = sat(0.95 - domo * 0.2 + g * 0.06);
    O[i] = sat(0.3 + 0.7 * smoothstep(0.0, 0.55, h));
  }
};

GEN.nieve = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const dunas = capaRuido(rt, n, { fx: 4, oct: 4, sal: 271 });
  const sastrugi = capaRuido(rt, n, { fx: 3, fy: 26, oct: 3, sal: 277, warp: 0.3, warpFrec: 3 });
  const grano = capaRuido(rt, n, { fx: 140, oct: 2, sal: 281 });
  const costra = capaWorley(rt, n, { cx: 30, sal: 283, muestras: 8 });
  const blanco = C('#f4f7fc'), sombra = C('#bcccE2'.toLowerCase()), azul = C('#93a9c8');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const g = grano[i];
    const h = sat(0.5 + dunas[i] * 0.24 + sastrugi[i] * 0.16 + g * 0.05);
    H[i] = h;
    pon(A, i3, blanco);
    mez(A, i3, sombra, sat(smoothstep(0.62, 0.2, h)) * 0.7);
    mez(A, i3, azul, sat(smoothstep(0.4, 0.05, h)) * 0.5);
    // cristales: chispazos especulares muy puntuales
    const cristal = g > 0.46 && costra.f1[i] < 0.5 ? 1 : 0;
    if (cristal) mez(A, i3, C('#ffffff'), 0.6);
    R[i] = cristal ? 0.07 : sat(0.44 + dunas[i] * 0.14 + g * 0.1);
    O[i] = sat(0.72 + 0.28 * smoothstep(0.1, 0.8, h));
  }
};

GEN.asfalto = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const arido = capaWorley(rt, n, { cx: 46, sal: 293, muestras: 8 });
  const parches = capaWorley(rt, n, { cx: 3, sal: 307, muestras: 30 });
  const fisuras = capaRuido(rt, n, { tipo: 'ridged', fx: 3, oct: 5, sal: 311, warp: 0.4, warpFrec: 3 });
  const manchas = capaRuido(rt, n, { fx: 2, oct: 3, sal: 313 });
  const grano = capaRuido(rt, n, { fx: 160, oct: 2, sal: 317 });

  const ligante = C('#2a2a2e'), aridoCl = C('#6e6e74'), aridoOs = C('#45454b'), gastado = C('#57575e');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const piedrita = arido.id[i] > 120 ? smoothstep(0.34, 0.10, arido.f1[i]) : 0;
    const fis = smoothstep(0.80, 0.97, fisuras[i]);
    const g = grano[i];
    const parche = (parches.id[i] / 255 - 0.5) * 0.12;

    let h = 0.55 + piedrita * 0.16 + g * 0.07 - fis * 0.45;
    H[i] = sat(h);

    pon(A, i3, ligante);
    mez(A, i3, aridoOs, piedrita * 0.85);
    mez(A, i3, aridoCl, piedrita * piedrita * 0.7);
    mez(A, i3, gastado, sat(manchas[i] * 0.6 + 0.2) * 0.35);
    mez(A, i3, C('#141416'), fis * 0.9);
    esc(A, i3, 1 + parche + g * 0.1);

    // mancha de aceite: más oscura y más pulida
    const aceite = sat(smoothstep(0.45, 0.8, manchas[i]));
    mez(A, i3, C('#1a1a20'), aceite * 0.5);
    R[i] = sat(0.82 + g * 0.08 - piedrita * 0.1 - aceite * 0.42);
    O[i] = sat(0.55 + 0.45 * smoothstep(0.1, 0.7, h) - fis * 0.25);
  }
};

GEN.hormigon = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const mancha = capaRuido(rt, n, { fx: 3, oct: 4, sal: 331 });
  const fino = capaRuido(rt, n, { fx: 26, oct: 3, sal: 337, warp: 0.2, warpFrec: 3 });
  const burbujas = capaWorley(rt, n, { cx: 54, sal: 347, muestras: 8 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 349 });
  const desconche = capaWorley(rt, n, { cx: 7, sal: 353, muestras: 18 });

  // chorreado desde las juntas de encofrado
  const juntasMask = new Float32Array(n * n);
  for (let y = 0; y < n; y++) {
    const v = (y + 0.5) / n;
    const fv = v * 4, tv = fv - Math.floor(fv);
    const d = Math.min(tv, 1 - tv) * (n / 4);
    const junta = smoothstep(2.2, 0.2, d);
    for (let x = 0; x < n; x++) juntasMask[y * n + x] = junta;
  }
  const chorreo = escurrir(juntasMask, n, 60, 0.965);

  const base = C('#a9a69d'), claro = C('#c2beb4'), oscuro = C('#7e7b73'), sucio = C('#6a675f');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;
    const g = grano[i];
    const junta = juntasMask[i];
    const burbuja = burbujas.id[i] > 205 ? smoothstep(0.24, 0.05, burbujas.f1[i]) : 0;
    const roto = smoothstep(0.30, 0.06, desconche.f1[i]) * (desconche.id[i] > 214 ? 1 : 0);

    // agujeros de los separadores del encofrado, en la intersección de la grilla
    const fu = u * 4, tu = fu - Math.floor(fu);
    const du = Math.min(tu, 1 - tu) * (n / 4), dv = Math.min(v * 4 - Math.floor(v * 4), 1 - (v * 4 - Math.floor(v * 4))) * (n / 4);
    const separador = smoothstep(4.5, 2.0, Math.sqrt(du * du + dv * dv));

    let h = 0.62 + fino[i] * 0.10 + g * 0.05 - junta * 0.22 - separador * 0.4 - burbuja * 0.35 - roto * 0.3;
    H[i] = sat(h);

    pon(A, i3, base);
    mez(A, i3, claro, sat(fino[i] * 0.6 + mancha[i] * 0.4 + 0.2) * 0.7);
    mez(A, i3, oscuro, sat(-fino[i] * 0.7 + 0.25) * 0.6);
    mez(A, i3, sucio, sat(chorreo[i] * 0.8 - 0.1) * 0.45);
    mez(A, i3, oscuro, (junta * 0.5 + burbuja * 0.8 + separador * 0.7));
    mez(A, i3, C('#8a7f6e'), roto * 0.6);
    esc(A, i3, 0.92 + g * 0.12 + mancha[i] * 0.08);

    R[i] = sat(0.84 + g * 0.08 - chorreo[i] * 0.18 + roto * 0.08);
    O[i] = sat(0.55 + 0.45 * smoothstep(0.15, 0.75, h));
  }
};

/* ----------------------------------------------------------- CONSTRUCCIÓN */

GEN.ladrillo = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const COLS = 8, FILAS = 16;                 // filas par => el desfase medio ladrillo teja
  const anchoPx = n / COLS, altoPx = n / FILAS;
  const irregular = capaRuido(rt, n, { fx: 64, oct: 3, sal: 401 });
  const poro = capaRuido(rt, n, { fx: 150, oct: 2, sal: 409 });
  const manchaN = capaRuido(rt, n, { fx: 3, oct: 4, sal: 419 });
  const eflorescencia = capaRuido(rt, n, { fx: 5, oct: 3, sal: 421, warp: 0.3, warpFrec: 3 });
  const mordida = capaWorley(rt, n, { cx: 26, sal: 431, muestras: 10 });

  // humedad: nace de manchas macro y escurre hacia abajo
  const humedadSemilla = new Float32Array(n * n);
  for (let i = 0; i < n * n; i++) humedadSemilla[i] = sat(smoothstep(0.42, 0.78, manchaN[i]));
  const humedad = escurrir(humedadSemilla, n, 90, 0.975);

  const rojos = [C('#8e3a29'), C('#a04a33'), C('#7a3325'), C('#96543c'), C('#5f2d22'), C('#b0563a'), C('#6d3a2c')];
  const mortero = C('#b3ab9c'), morteroOs = C('#8f887a');
  const desgaste = C('#c2a08a'), hollin = C('#3b2a22');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;

    const fv = v * FILAS, fila = Math.floor(fv), ty = fv - fila;
    const desp = (fila & 1) * 0.5;
    const fu = u * COLS + desp, col = Math.floor(fu), tx = fu - col;

    // distancia al borde del ladrillo, en píxeles, con el borde comido por ruido
    const dx = Math.min(tx, 1 - tx) * anchoPx;
    const dy = Math.min(ty, 1 - ty) * altoPx;
    const erosion = irregular[i] * 1.6 + 1.2;
    const d = Math.min(dx, dy) - erosion;

    const hb = rt.hash(col % COLS, fila % FILAS, 7) / 255;
    const hb2 = rt.hash(col % COLS, fila % FILAS, 71) / 255;
    const esLadrillo = smoothstep(0.0, 3.2, d);

    // esquinas mordidas en algunos ladrillos: rompe la grilla perfecta
    const golpe = hb2 > 0.72 ? smoothstep(0.42, 0.12, mordida.f1[i]) * smoothstep(6.0, 1.0, d) : 0;
    const cara = sat(esLadrillo - golpe);

    const p = poro[i];
    let h = lerp(0.24 + p * 0.06, 0.80 + p * 0.07 + (hb - 0.5) * 0.05, cara);
    // bisel: el borde del ladrillo cae antes que la cara
    h -= smoothstep(4.5, 0.5, d) * 0.10 * cara;
    H[i] = sat(h);

    // color del ladrillo: tono por pieza + degradado interno + poros
    const tono = rojos[(rt.hash(col % COLS, fila % FILAS, 13) % rojos.length)];
    pon(A, i3, mortero);
    mez(A, i3, morteroOs, sat(1 - esLadrillo) * (0.35 + p * 0.3));
    mez(A, i3, tono, cara);
    if (cara > 0.02) {
      // degradado suave dentro de la pieza (cocción despareja) + poros
      const grad = (ty - 0.5) * 0.10 + (tx - 0.5) * 0.05 + (hb - 0.5) * 0.14;
      esc(A, i3, 1 + grad * cara + p * 0.12 * cara);
      // arista gastada, más pálida
      mez(A, i3, desgaste, smoothstep(5.0, 1.2, d) * cara * 0.35 * (0.4 + hb2 * 0.6));
    }
    mez(A, i3, hollin, humedad[i] * 0.42);
    mez(A, i3, C('#d9d3c4'), sat(eflorescencia[i] * 0.9 - 0.35) * (1 - cara * 0.5) * 0.5);
    esc(A, i3, 0.94 + manchaN[i] * 0.1);

    R[i] = sat(lerp(0.96, 0.84 + p * 0.08, cara) - humedad[i] * 0.3);
    O[i] = sat(0.36 + 0.64 * smoothstep(0.15, 0.8, h));
  }
};

/** Tablas y tablas viejas: misma carpintería, distinto grado de intemperie. */
function generarMadera(rt, c, rng, viejo) {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const TABLAS = 5, ANILLOS = 7;
  const veta = capaRuido(rt, n, { fx: 3, fy: 30, oct: 4, sal: 449, warp: 0.25, warpFrec: 3 });
  const fibra = capaRuido(rt, n, { fx: 6, fy: 140, oct: 2, sal: 457 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 461 });
  const intemperie = capaRuido(rt, n, { fx: 4, oct: 4, sal: 463 });
  const musgoN = capaRuido(rt, n, { fx: 9, oct: 3, sal: 467 });

  // nudos: posición determinista por tabla, distancia toroidal para que tejen
  const nudos = [];
  for (let t = 0; t < TABLAS; t++) {
    const cuantos = rng.int(1, 2);
    for (let k = 0; k < cuantos; k++) {
      nudos.push({ tabla: t, u: rng.float(0.05, 0.95), tv: rng.float(0.25, 0.75), r: rng.float(0.018, 0.042) });
    }
  }

  const claro = C(viejo ? '#a89c86' : '#c39a62');
  const medio = C(viejo ? '#8a7f6c' : '#9d7040');
  const oscuro = C(viejo ? '#5d5548' : '#6b4526');
  const gris = C('#9a9083'), musgo = C('#5d6b3c');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;
    const fv = v * TABLAS, tabla = Math.floor(fv), tv = fv - tabla;

    const ht = rt.hash(tabla, 3, 17) / 255;
    const ht2 = rt.hash(tabla, 5, 19) / 255;

    // junta entre tablas
    const dTabla = Math.min(tv, 1 - tv) * (n / TABLAS);
    const junta = smoothstep(3.0, 0.4, dTabla);

    // anillos: fase periódica en v + veta deformada + nudos
    let fase = fv * ANILLOS + veta[i] * 2.2 + ht * 3.0;
    let nudoMask = 0, nudoCore = 0;
    for (let k = 0; k < nudos.length; k++) {
      const nd = nudos[k];
      if (nd.tabla !== tabla) continue;
      let du = u - nd.u; du -= Math.round(du);           // envoltura toroidal
      const dv = (tv - nd.tv) / TABLAS;
      const dist = Math.sqrt(du * du + dv * dv * 2.2);
      if (dist < 0.22) {
        fase += 0.75 / (dist + 0.035);
        nudoMask = Math.max(nudoMask, smoothstep(0.14, nd.r, dist));
        nudoCore = Math.max(nudoCore, smoothstep(nd.r * 1.5, nd.r * 0.45, dist));
      }
    }
    const anillo = Math.sin(fase * Math.PI * 2) * 0.5 + 0.5;
    const anilloDuro = Math.pow(anillo, 1.6);
    const g = grano[i], fib = fibra[i];

    // desgaste: la madera vieja pierde la fibra blanda y queda acanalada
    const relieve = viejo ? 0.16 : 0.06;
    let h = 0.72 - anilloDuro * relieve + fib * 0.05 + g * 0.03;
    h -= junta * 0.45;
    h -= nudoCore * 0.10;
    h += nudoMask * 0.03;

    pon(A, i3, medio);
    mez(A, i3, oscuro, anilloDuro * (viejo ? 0.75 : 0.62));
    mez(A, i3, claro, sat((1 - anillo) * 0.7 + fib * 0.35 - 0.15) * 0.55);
    esc(A, i3, 0.88 + ht * 0.2 + ht2 * 0.06 + g * 0.08);
    mez(A, i3, oscuro, nudoMask * 0.55);
    mez(A, i3, C('#2f2116'), nudoCore * 0.75);
    mez(A, i3, C('#231a12'), junta * 0.85);

    if (viejo) {
      // grisado por sol y lluvia, rajaduras siguiendo la fibra, musgo en la junta
      const grisado = sat(intemperie[i] * 0.8 + 0.35);
      mez(A, i3, gris, grisado * 0.55);
      const raja = smoothstep(0.92, 0.99, anillo) * sat(intemperie[i] + 0.4);
      h -= raja * 0.3;
      mez(A, i3, C('#3a3229'), raja * 0.8);
      const mus = sat(smoothstep(0.45, 0.85, musgoN[i]) * (junta * 0.9 + 0.15));
      mez(A, i3, musgo, mus * 0.6);
      R[i] = sat(0.90 + g * 0.06 - anilloDuro * 0.04);
    } else {
      // clavos: dos columnas por tabla, con cabeza abollada
      const cu = ((u - (0.12 + ht * 0.05)) % 0.5 + 0.5) % 0.5;
      const du2 = Math.min(cu, 0.5 - cu) * n;
      const dv2 = Math.abs(tv - 0.5) * (n / TABLAS);
      const dClavo = Math.sqrt(du2 * du2 + dv2 * dv2);
      const clavo = smoothstep(3.4, 1.6, dClavo);
      if (clavo > 0.01) {
        mez(A, i3, C('#4a4844'), clavo * 0.85);
        h -= clavo * 0.06;
        R[i] = 0.42;
        c.met[i] = clavo * 0.9;
      } else {
        R[i] = sat(0.72 + anilloDuro * 0.12 + g * 0.06);
      }
    }
    H[i] = sat(h);
    O[i] = sat(0.5 + 0.5 * smoothstep(0.2, 0.85, h) - nudoCore * 0.15);
  }
}
GEN.madera_tabla = (rt, c, rng) => generarMadera(rt, c, rng, false);
GEN.madera_vieja = (rt, c, rng) => generarMadera(rt, c, rng, true);

GEN.metal_pintado = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, M = c.met, O = c.ao;
  const piel = capaRuido(rt, n, { fx: 90, oct: 2, sal: 487 });          // piel de naranja
  const macro = capaRuido(rt, n, { fx: 3, oct: 3, sal: 491 });
  const rayas = capaRuido(rt, n, { tipo: 'ridged', fx: 180, fy: 5, oct: 2, sal: 499 });
  const saltados = capaWorley(rt, n, { cx: 26, sal: 503, muestras: 10 });
  const suciedadN = capaRuido(rt, n, { fx: 6, oct: 3, sal: 509 });

  const pintura = C('#c8ccd0'), pinturaOs = C('#a3a8ad');
  const imprimacion = C('#8a5c3c'), metal = C('#6e7276');

  // juntas de panel 2x2 + remaches sobre la junta
  const juntaMask = new Float32Array(n * n);
  for (let y = 0; y < n; y++) {
    const v = (y + 0.5) / n, fv = v * 2, tv = fv - Math.floor(fv);
    const dv = Math.min(tv, 1 - tv) * (n / 2);
    for (let x = 0; x < n; x++) {
      const u = (x + 0.5) / n, fu = u * 2, tu = fu - Math.floor(fu);
      const du = Math.min(tu, 1 - tu) * (n / 2);
      juntaMask[y * n + x] = smoothstep(2.6, 0.4, Math.min(du, dv));
    }
  }
  const chorreo = escurrir(juntaMask, n, 40, 0.955);

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;
    const junta = juntaMask[i];

    // remaches cada 1/16 a lo largo de las juntas
    const su = (u * 16) % 1, sv = (v * 16) % 1;
    const dRem = Math.min(
      Math.hypot((su - 0.5) * (n / 16), Math.min(Math.abs(v * 2 - Math.round(v * 2))) * (n / 2)),
      Math.hypot((sv - 0.5) * (n / 16), Math.abs(u * 2 - Math.round(u * 2)) * (n / 2))
    );
    const remache = smoothstep(3.6, 1.6, dRem);

    const salto = saltados.id[i] > 218 ? smoothstep(0.30, 0.08, saltados.f1[i]) : 0;
    const raya = smoothstep(0.90, 0.99, rayas[i]);
    const p = piel[i];

    let h = 0.66 + p * 0.05 - junta * 0.30 + remache * 0.22 - salto * 0.06;
    H[i] = sat(h);

    pon(A, i3, pintura);
    mez(A, i3, pinturaOs, sat(0.4 - macro[i] * 0.6) * 0.4);
    esc(A, i3, 0.96 + p * 0.07 + macro[i] * 0.05);
    mez(A, i3, C('#4c5054'), junta * 0.6);
    mez(A, i3, C('#909498'), remache * 0.7);
    mez(A, i3, imprimacion, salto * 0.7);
    mez(A, i3, metal, salto * salto * 0.6);
    mez(A, i3, C('#b9bec2'), raya * 0.5);
    mez(A, i3, C('#59544c'), sat(chorreo[i] * 0.9 - 0.15) * 0.3 * sat(suciedadN[i] + 0.5));

    R[i] = sat(0.44 + p * 0.10 - raya * 0.26 + salto * 0.28 + junta * 0.2);
    M[i] = sat(salto * salto * 0.85 + remache * 0.6 + raya * 0.35);
    O[i] = sat(0.62 + 0.38 * smoothstep(0.25, 0.8, h));
  }
};

GEN.metal_oxidado = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, M = c.met, O = c.ao;
  const celdas = capaWorley(rt, n, { cx: 5, sal: 521, muestras: 24 });
  const parche = capaRuido(rt, n, { fx: 7, oct: 5, sal: 523, warp: 0.5, warpFrec: 3 });
  const costra = capaRuido(rt, n, { fx: 40, oct: 3, sal: 541 });
  const pulido = capaRuido(rt, n, { fx: 4, fy: 120, oct: 2, sal: 547 });
  const grano = capaRuido(rt, n, { fx: 160, oct: 2, sal: 557 });
  const picado = capaWorley(rt, n, { cx: 60, sal: 563, muestras: 8 });

  // máscara de óxido con borde comido y chorreado hacia abajo
  const semilla = new Float32Array(n * n);
  for (let i = 0; i < n * n; i++) {
    const base = smoothstep(0.55, 0.18, celdas.f1[i]) * 0.7 + parche[i] * 0.55 + 0.18;
    semilla[i] = sat(smoothstep(0.42, 0.62, base + costra[i] * 0.22));
  }
  const chorreo = escurrir(semilla, n, 120, 0.982);

  const acero = C('#71767b'), aceroOs = C('#4a4e53');
  const ox1 = C('#b4703a'), ox2 = C('#8e4a20'), ox3 = C('#5d2f16'), ox0 = C('#d19556');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const g = grano[i];
    const oxido = sat(Math.max(semilla[i], chorreo[i] * 0.62));
    const nucleo = semilla[i];
    const pit = oxido > 0.6 && picado.id[i] > 200 ? smoothstep(0.26, 0.06, picado.f1[i]) : 0;

    let h = 0.6 + pulido[i] * 0.03 + g * 0.02;
    h += oxido * (0.10 + costra[i] * 0.12);   // el óxido levanta costra
    h -= pit * 0.5;
    H[i] = sat(h);

    pon(A, i3, acero);
    mez(A, i3, aceroOs, sat(0.5 - pulido[i] * 0.9) * 0.5);
    esc(A, i3, 0.95 + pulido[i] * 0.1 + g * 0.05);
    mez(A, i3, ox1, oxido * 0.9);
    mez(A, i3, ox2, nucleo * 0.8);
    mez(A, i3, ox3, sat(nucleo * 1.3 - 0.45) * 0.85);
    mez(A, i3, ox0, sat(oxido - nucleo) * 0.5);       // el chorreado es más claro
    mez(A, i3, C('#241209'), pit * 0.85);
    esc(A, i3, 0.94 + costra[i] * 0.12 * oxido);

    R[i] = sat(lerp(0.30 + pulido[i] * 0.1 + g * 0.04, 0.93 + g * 0.06, oxido));
    M[i] = sat((1 - oxido * 1.15) * (1 - pit));
    O[i] = sat(0.55 + 0.45 * smoothstep(0.3, 0.85, h) - pit * 0.3);
  }
};

GEN.chapa_ondulada = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, M = c.met, O = c.ao;
  const ONDAS = 8, FILAS_TORNILLO = 3;
  const cristal = capaWorley(rt, n, { cx: 22, sal: 571, muestras: 10 });   // flor del galvanizado
  const oxN = capaRuido(rt, n, { fx: 6, oct: 4, sal: 577, warp: 0.4, warpFrec: 3 });
  const mugre = capaRuido(rt, n, { fx: 3, fy: 20, oct: 3, sal: 587 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 593 });

  const zinc = C('#b6bbc0'), zincOs = C('#878d93'), ox = C('#8a4a24'), oxCl = C('#b06f3a');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;
    const onda = Math.sin(u * ONDAS * Math.PI * 2);
    const valle = sat(-onda * 0.5 + 0.5);
    const g = grano[i];

    // tornillos en la cresta, en filas horizontales
    const fv = v * FILAS_TORNILLO, tv = fv - Math.floor(fv);
    const fu = u * ONDAS, tu = fu - Math.floor(fu);
    const dTor = Math.hypot((tu - 0.25) * (n / ONDAS), (tv - 0.5) * (n / FILAS_TORNILLO));
    const tornillo = smoothstep(4.6, 2.4, dTor);

    // el óxido se acumula en el valle, donde queda el agua
    const oxido = sat(smoothstep(0.35, 0.72, oxN[i] * 0.6 + valle * 0.55 + mugre[i] * 0.2 + 0.1));

    let h = 0.5 + onda * 0.42 + g * 0.02 + tornillo * 0.16 + oxido * 0.04;
    H[i] = sat(h);

    const flor = (cristal.id[i] / 255 - 0.5) * 0.14 + smoothstep(0.5, 0.1, cristal.f1[i]) * 0.06;
    pon(A, i3, zinc);
    mez(A, i3, zincOs, sat(valle * 0.7 + 0.1) * 0.55);
    esc(A, i3, 0.95 + flor + g * 0.05);
    mez(A, i3, oxCl, oxido * 0.75);
    mez(A, i3, ox, oxido * oxido * 0.8);
    mez(A, i3, C('#5a5f63'), tornillo * 0.5);
    mez(A, i3, C('#3f4145'), sat(mugre[i] * 0.8 - 0.2) * valle * 0.35);

    R[i] = sat(lerp(0.34 + flor * 0.6 + g * 0.05, 0.92, oxido) - tornillo * 0.05);
    M[i] = sat((1 - oxido * 1.1) * 0.92 + tornillo * 0.2);
    O[i] = sat(0.5 + 0.5 * smoothstep(0.05, 0.85, h));
  }
};

GEN.teja = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const COLS = 7, FILAS = 5;
  const poro = capaRuido(rt, n, { fx: 120, oct: 2, sal: 601 });
  const macro = capaRuido(rt, n, { fx: 4, oct: 3, sal: 607 });
  const musgoN = capaRuido(rt, n, { fx: 8, oct: 4, sal: 613, warp: 0.3, warpFrec: 3 });
  const desgasteN = capaRuido(rt, n, { fx: 26, oct: 3, sal: 617 });

  const tonos = [C('#a8502e'), C('#8d4526'), C('#b9623a'), C('#7a3d24'), C('#9c5733'), C('#6d3a26')];
  const musgo = C('#4f6033'), cal = C('#b9a894');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;

    const fv = v * FILAS, fila = Math.floor(fv), tv = fv - fila;
    const desp = (fila & 1) * 0.5;
    const fu = u * COLS + desp, colu = Math.floor(fu), tu = fu - colu;

    const h1 = rt.hash(colu % COLS, fila % FILAS, 23) / 255;
    const h2 = rt.hash(colu % COLS, fila % FILAS, 29) / 255;

    // perfil de teja árabe: medio cilindro, con canal entre piezas
    const s = tu * 2 - 1;
    const cilindro = Math.sqrt(Math.max(0, 1 - s * s));
    const canal = smoothstep(0.16, 0.02, Math.min(tu, 1 - tu));
    // solape: la hilada de arriba tapa el arranque de ésta
    const labio = smoothstep(0.16, 0.02, tv);
    const sombraSolape = smoothstep(0.24, 0.03, tv);

    let h = 0.20 + Math.pow(cilindro, 0.75) * 0.62 * (0.9 + h1 * 0.2);
    h -= canal * 0.34;
    h += labio * 0.16;                       // la teja de arriba monta sobre ésta
    h += (h2 - 0.5) * 0.05 + poro[i] * 0.03;
    H[i] = sat(h);

    const tono = tonos[rt.hash(colu % COLS, fila % FILAS, 31) % tonos.length];
    pon(A, i3, tono);
    esc(A, i3, 0.82 + cilindro * 0.3 + h1 * 0.12 + poro[i] * 0.08);
    // desgaste calcáreo en la cima, musgo en el canal y bajo el solape
    mez(A, i3, cal, sat(smoothstep(0.55, 1.0, cilindro) * desgasteN[i] + 0.05) * 0.35);
    const mus = sat(smoothstep(0.35, 0.8, musgoN[i]) * (canal * 0.8 + sombraSolape * 0.6 + 0.1));
    mez(A, i3, musgo, mus * 0.7);
    esc(A, i3, 1 - sombraSolape * 0.45);
    esc(A, i3, 0.92 + macro[i] * 0.14);

    R[i] = sat(0.82 + poro[i] * 0.08 + mus * 0.1 - smoothstep(0.6, 1.0, cilindro) * 0.06);
    O[i] = sat((0.42 + 0.58 * smoothstep(0.1, 0.8, h)) * (1 - sombraSolape * 0.55) * (1 - canal * 0.3));
  }
};

GEN.vidrio = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa;
  const onda = capaRuido(rt, n, { fx: 3, oct: 3, sal: 631 });
  const polvoN = capaRuido(rt, n, { fx: 5, oct: 4, sal: 641 });
  const gotas = capaWorley(rt, n, { cx: 14, sal: 643, muestras: 12 });
  const vidrioCol = C('#0e1b26'), sucio = C('#4c5257'), reflejo = C('#28414f');

  const semilla = new Float32Array(n * n);
  for (let i = 0; i < n * n; i++) semilla[i] = sat(smoothstep(0.5, 0.85, polvoN[i]));
  const chorreo = escurrir(semilla, n, 80, 0.972);

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const y = (i / n) | 0;
    const v = (y + 0.5) / n;
    const suciedad = sat(chorreo[i] * 0.7 + smoothstep(0.55, 0.9, polvoN[i]) * 0.5 + (1 - v) * 0.12);
    const gota = gotas.id[i] > 226 ? smoothstep(0.3, 0.1, gotas.f1[i]) : 0;

    H[i] = sat(0.5 + onda[i] * 0.06 + gota * 0.12);
    pon(A, i3, vidrioCol);
    mez(A, i3, reflejo, sat(onda[i] * 0.5 + 0.35) * 0.4);
    mez(A, i3, sucio, suciedad * 0.55 + gota * 0.2);
    R[i] = sat(0.06 + suciedad * 0.5 + gota * 0.25);
    O[i] = 1;
    AL[i] = sat(0.42 + suciedad * 0.45 + gota * 0.2);
  }
};

GEN.panel_compuesto = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, M = c.met, O = c.ao;
  const COLS = 2, FILAS = 3;
  const cepillado = capaRuido(rt, n, { fx: 200, fy: 6, oct: 2, sal: 653 });
  const macro = capaRuido(rt, n, { fx: 4, oct: 3, sal: 659 });
  const polvo = capaRuido(rt, n, { fx: 9, oct: 3, sal: 661 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 673 });
  const base = C('#b9bec3'), baseOs = C('#8f959a'), junta = C('#2b2f33');

  const juntaMask = new Float32Array(n * n);
  for (let y = 0; y < n; y++) {
    const v = (y + 0.5) / n, fv = v * FILAS, tv = fv - Math.floor(fv);
    const dv = Math.min(tv, 1 - tv) * (n / FILAS);
    for (let x = 0; x < n; x++) {
      const u = (x + 0.5) / n, fu = u * COLS, tu = fu - Math.floor(fu);
      const du = Math.min(tu, 1 - tu) * (n / COLS);
      juntaMask[y * n + x] = smoothstep(3.4, 1.0, Math.min(du, dv));
    }
  }
  const sombraJunta = escurrir(juntaMask, n, 20, 0.90);

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const j = juntaMask[i];
    const g = grano[i];
    let h = 0.72 + cepillado[i] * 0.02 + g * 0.015 - j * 0.55;
    H[i] = sat(h);

    pon(A, i3, base);
    mez(A, i3, baseOs, sat(0.45 - macro[i] * 0.7) * 0.35);
    esc(A, i3, 0.97 + cepillado[i] * 0.05 + g * 0.03);
    mez(A, i3, junta, j * 0.92);
    mez(A, i3, C('#6f7378'), sat(sombraJunta[i] - j) * 0.35 * sat(polvo[i] + 0.4));

    R[i] = sat(0.38 + cepillado[i] * 0.06 + j * 0.4 + polvo[i] * 0.05);
    M[i] = sat(0.28 * (1 - j));
    O[i] = sat(0.6 + 0.4 * smoothstep(0.25, 0.8, h));
  }
};

GEN.panel_led = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, M = c.met, O = c.ao, E = c.emis;
  const CELDAS = 12;
  const trazas = capaRuido(rt, n, { fx: 30, fy: 30, oct: 2, sal: 677 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 683 });
  const cuerpo = C('#0b0f15'), bisel = C('#1b222b'), pista = C('#1d3540');
  const luzA = C('#5fe0f0'), luzB = C('#3aa8ff'), luzC = C('#b48bff');

  // halo: se calcula sobre la máscara de LED encendido y se desenfoca
  const ledMask = new Float32Array(n * n);
  const ledTono = new Float32Array(n * n);
  for (let y = 0; y < n; y++) {
    const v = (y + 0.5) / n, fv = v * CELDAS, cy = Math.floor(fv), tv = fv - cy;
    for (let x = 0; x < n; x++) {
      const u = (x + 0.5) / n, fu = u * CELDAS, cx = Math.floor(fu), tu = fu - cx;
      const h = rt.hash(cx, cy, 43) / 255;
      const encendido = h > 0.22 ? 1 : 0;
      // barra luminosa horizontal dentro de la celda
      const dx = Math.abs(tu - 0.5), dy = Math.abs(tv - 0.5);
      const barra = smoothstep(0.34, 0.24, dx) * smoothstep(0.16, 0.09, dy);
      ledMask[y * n + x] = barra * encendido * (0.55 + h * 0.45);
      ledTono[y * n + x] = h;
    }
  }
  const halo = suavizarCaja(ledMask, n, Math.max(2, (n / 96) | 0));

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3, g = grano[i];
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;
    const fu = u * CELDAS, fv = v * CELDAS;
    const tu = fu - Math.floor(fu), tv = fv - Math.floor(fv);
    const marco = smoothstep(0.06, 0.015, Math.min(Math.min(tu, 1 - tu), Math.min(tv, 1 - tv)));
    const led = ledMask[i], hal = halo[i];
    const tono = ledTono[i];
    const traza = smoothstep(0.72, 0.86, Math.abs(trazas[i])) * (1 - marco);

    let h = 0.62 - marco * 0.35 + led * 0.10 + traza * 0.04 + g * 0.015;
    H[i] = sat(h);

    pon(A, i3, cuerpo);
    mez(A, i3, bisel, marco * 0.8);
    mez(A, i3, pista, traza * 0.75);
    const col = tono > 0.72 ? luzC : (tono > 0.45 ? luzA : luzB);
    mez(A, i3, col, sat(led * 0.9 + hal * 0.25));
    esc(A, i3, 0.95 + g * 0.06);

    const inten = sat(led * 1.15 + hal * 0.55 + traza * 0.12);
    E[i3] = col[0] * inten; E[i3 + 1] = col[1] * inten; E[i3 + 2] = col[2] * inten;

    R[i] = sat(0.22 + marco * 0.3 + g * 0.04 - led * 0.1);
    M[i] = sat(0.15 + marco * 0.25);
    O[i] = sat(0.55 + 0.45 * smoothstep(0.2, 0.75, h));
  }
};

GEN.marmol = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const turb = capaRuido(rt, n, { tipo: 'turb', fx: 3, oct: 6, sal: 691 });
  const turb2 = capaRuido(rt, n, { tipo: 'turb', fx: 5, oct: 5, sal: 701 });
  const fino = capaRuido(rt, n, { fx: 40, oct: 3, sal: 709 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 719 });
  const base = C('#eeebe3'), veta = C('#8f8a80'), vetaOs = C('#5f5b53'), oro = C('#c0a468');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const u = (x + 0.5) / n, v = (y + 0.5) / n;
    // vetas: seno de fase periódica (3u+2v) deformada por turbulencia
    const f1 = Math.sin((u * 3 + v * 2 + turb[i] * 2.6) * Math.PI * 2);
    const f2 = Math.sin((u * -2 + v * 5 + turb2[i] * 3.2) * Math.PI * 2);
    const v1 = Math.pow(1 - Math.abs(f1), 9);
    const v2 = Math.pow(1 - Math.abs(f2), 16);
    const capilar = Math.pow(1 - Math.abs(Math.sin((u * 11 + v * 7 + turb2[i] * 4.5) * Math.PI * 2)), 26);
    const g = grano[i];

    pon(A, i3, base);
    esc(A, i3, 0.97 + fino[i] * 0.05 + g * 0.02);
    mez(A, i3, veta, sat(v1 * 0.9 + capilar * 0.4));
    mez(A, i3, vetaOs, sat(v1 * v1 * 1.2) * 0.8);
    mez(A, i3, oro, sat(v2 * 0.85) * 0.55);
    H[i] = sat(0.62 + v1 * 0.06 + v2 * 0.04 - capilar * 0.05 + fino[i] * 0.03);
    R[i] = sat(0.14 + v1 * 0.12 + v2 * 0.10 + fino[i] * 0.05);
    O[i] = sat(0.86 + 0.14 * smoothstep(0.4, 0.8, H[i]));
  }
};

/* --------------------------------------------------------- TELA / DETALLE */

/** Tejido: `twill` da sarga diagonal (uniformes); si no, tafetán (lona). */
function generarTejido(rt, c, cfg) {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const HILOS = cfg.hilos;
  const pelusa = capaRuido(rt, n, { fx: 120, oct: 2, sal: cfg.sal });
  const arrugas = capaRuido(rt, n, { fx: 3, oct: 3, sal: cfg.sal + 7, warp: 0.3, warpFrec: 3 });
  const pliegues = capaRuido(rt, n, { tipo: 'ridged', fx: 4, fy: 6, oct: 3, sal: cfg.sal + 13 });
  const manchaN = capaRuido(rt, n, { fx: 5, oct: 3, sal: cfg.sal + 19 });

  const claro = cfg.claro, medio = cfg.medio, oscuro = cfg.oscuro, mugre = cfg.mugre;

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const x = i % n, y = (i / n) | 0;
    const tu = ((x + 0.5) / n) * HILOS, tv = ((y + 0.5) / n) * HILOS;
    const cu = Math.floor(tu), cv = Math.floor(tv);
    const fu = tu - cu, fv = tv - cv;
    const perU = Math.sin(fu * Math.PI);      // perfil redondo del hilo vertical
    const perV = Math.sin(fv * Math.PI);
    // sarga 2/2 vs tafetán
    const arriba = cfg.twill ? (((cu - cv) % 4) + 4) % 4 < 2 : ((cu + cv) & 1) === 0;

    const hh = rt.hash(cu, cv, 61) / 255;
    const p = pelusa[i];
    const alto = arriba ? 0.62 + perU * 0.30 : 0.40 + perV * 0.26;
    let h = alto + p * 0.05 + arrugas[i] * 0.10 - pliegues[i] * 0.08;
    H[i] = sat(h);

    pon(A, i3, medio);
    mez(A, i3, claro, sat((arriba ? perU : perV * 0.7) * 0.9 - 0.1) * 0.7);
    mez(A, i3, oscuro, sat(1 - (arriba ? perU : perV)) * (arriba ? 0.35 : 0.6));
    esc(A, i3, 0.93 + hh * 0.12 + p * 0.06 + arrugas[i] * 0.08);
    mez(A, i3, mugre, sat(manchaN[i] * 0.8 - 0.25) * cfg.mugreFuerza);

    R[i] = sat(cfg.rugosidad + p * 0.06 - (arriba ? perU : perV) * 0.04);
    O[i] = sat(0.45 + 0.55 * smoothstep(0.15, 0.9, h));
  }
}

GEN.lona = (rt, c) => {
  generarTejido(rt, c, {
    hilos: 44, twill: false, sal: 727, rugosidad: 0.90, mugreFuerza: 0.5,
    claro: C('#d8c49a'), medio: C('#bda577'), oscuro: C('#8d7748'), mugre: C('#6b5c42'),
  });
  // refuerzo: ojales en las esquinas del paño y costura perimetral
  const n = c.n, A = c.alb, H = c.alt, R = c.rug;
  for (let y = 0; y < n; y++) {
    const v = (y + 0.5) / n;
    for (let x = 0; x < n; x++) {
      const u = (x + 0.5) / n, i = y * n + x, i3 = i * 3;
      const du = Math.min(u, 1 - u), dv = Math.min(v, 1 - v);
      const d = Math.min(du, dv) * n;
      const costura = smoothstep(9.0, 6.0, d) * smoothstep(3.0, 5.0, d);
      if (costura > 0.01) {
        mez(A, i3, C('#7a6540'), costura * 0.6);
        H[i] = sat(H[i] + costura * 0.12);
        R[i] = sat(R[i] - costura * 0.08);
      }
    }
  }
};

GEN.tela_uniforme = (rt, c) => {
  generarTejido(rt, c, {
    hilos: 96, twill: true, sal: 733, rugosidad: 0.84, mugreFuerza: 0.28,
    claro: C('#e2ded4'), medio: C('#c9c4b8'), oscuro: C('#a29d92'), mugre: C('#7d7566'),
  });
};

GEN.cuero = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao;
  const poroA = capaWorley(rt, n, { cx: 70, sal: 739, muestras: 7 });
  const poroB = capaWorley(rt, n, { cx: 26, sal: 743, muestras: 12 });
  const pliegue = capaRuido(rt, n, { tipo: 'ridged', fx: 4, oct: 4, sal: 751, warp: 0.4, warpFrec: 3 });
  const macro = capaRuido(rt, n, { fx: 3, oct: 3, sal: 757 });
  const grano = capaRuido(rt, n, { fx: 150, oct: 2, sal: 761 });

  const base = C('#5a3a23'), claro = C('#7d5433'), oscuro = C('#33200f'), rozado = C('#95apply'.length ? '#956b45' : '#956b45');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const celA = smoothstep(0.55, 0.12, poroA.f1[i]);
    const celB = smoothstep(0.48, 0.14, poroB.f1[i]) * 0.5;
    const arruga = smoothstep(0.62, 0.95, pliegue[i]);
    const g = grano[i];

    let h = 0.55 + celA * 0.16 + celB * 0.14 + g * 0.04 - arruga * 0.34;
    H[i] = sat(h);

    pon(A, i3, base);
    mez(A, i3, claro, sat(celA * 0.8 + celB * 0.5 - 0.1) * 0.5);
    mez(A, i3, oscuro, arruga * 0.75);
    mez(A, i3, oscuro, sat(0.4 - macro[i] * 0.8) * 0.35);
    // rozaduras: la cresta del grano se pule con el uso
    const rozadura = sat(smoothstep(0.62, 0.95, h) * (macro[i] * 0.6 + 0.5));
    mez(A, i3, rozado, rozadura * 0.45);
    esc(A, i3, 0.92 + g * 0.1 + macro[i] * 0.08);

    R[i] = sat(0.62 + g * 0.06 + arruga * 0.14 - rozadura * 0.22);
    O[i] = sat(0.44 + 0.56 * smoothstep(0.1, 0.8, h));
  }
};

GEN.agua_espuma = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa;
  const burbA = capaWorley(rt, n, { cx: 11, sal: 769, muestras: 14 });
  const burbB = capaWorley(rt, n, { cx: 27, sal: 773, muestras: 10 });
  const turbul = capaRuido(rt, n, { tipo: 'turb', fx: 5, oct: 5, sal: 787, warp: 0.5, warpFrec: 3 });
  const hilos = capaRuido(rt, n, { fx: 9, fy: 40, oct: 3, sal: 797 });
  const blanco = C('#f6fafb'), gris = C('#cddde2'), agua = C('#5f97a8');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const b1 = smoothstep(0.52, 0.10, burbA.f1[i]);
    const b2 = smoothstep(0.44, 0.10, burbB.f1[i]);
    const espuma = sat(b1 * 0.75 + b2 * 0.55 + turbul[i] * 0.5 + hilos[i] * 0.25 - 0.18);

    H[i] = sat(0.45 + b1 * 0.3 + b2 * 0.22 + turbul[i] * 0.12);
    pon(A, i3, agua);
    mez(A, i3, gris, sat(espuma * 1.3));
    mez(A, i3, blanco, sat(espuma * 1.6 - 0.35));
    R[i] = sat(0.22 + espuma * 0.5);
    O[i] = sat(0.7 + 0.3 * smoothstep(0.2, 0.8, H[i]));
    AL[i] = sat(espuma * 1.35 - 0.08);
  }
};

GEN.humo = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa;
  const dens = capaRuido(rt, n, { tipo: 'turb', fx: 4, oct: 6, sal: 809, warp: 0.6, warpFrec: 3 });
  const detalle = capaRuido(rt, n, { tipo: 'turb', fx: 14, oct: 3, sal: 811 });
  const claro = C('#d4d2ce'), oscuro = C('#57544f');

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const d = sat(dens[i] * 1.15 + detalle[i] * 0.3 - 0.18);
    H[i] = sat(0.5 + d * 0.4);
    pon(A, i3, oscuro);
    mez(A, i3, claro, sat(d * 1.4));
    R[i] = 1;
    O[i] = sat(0.55 + 0.45 * d);
    AL[i] = sat(d * 1.25);
  }
};

GEN.chispa = (rt, c, rng) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa, E = c.emis;
  const nucleo = C('#fff6d8'), medio = C('#ffb648'), cola = C('#e8531a');
  const inten = new Float32Array(n * n);

  const cuantas = 34;
  for (let s = 0; s < cuantas; s++) {
    const x0 = rng.float(0, n), y0 = rng.float(0, n);
    const ang = rng.float(0, Math.PI * 2);
    const largo = rng.float(n * 0.04, n * 0.17);
    const radio = rng.float(0.7, 2.0);
    const brillo = rng.float(0.45, 1);
    const dx = Math.cos(ang), dy = Math.sin(ang);
    const r = Math.ceil(radio * 3.2);
    const minX = Math.floor(Math.min(x0, x0 + dx * largo) - r);
    const maxX = Math.ceil(Math.max(x0, x0 + dx * largo) + r);
    const minY = Math.floor(Math.min(y0, y0 + dy * largo) - r);
    const maxY = Math.ceil(Math.max(y0, y0 + dy * largo) + r);
    for (let y = minY; y <= maxY; y++) {
      const yy = ((y % n) + n) % n;
      for (let x = minX; x <= maxX; x++) {
        const xx = ((x % n) + n) % n;
        // proyección sobre el segmento
        const px = x - x0, py = y - y0;
        const t = clamp(px * dx + py * dy, 0, largo);
        const qx = px - dx * t, qy = py - dy * t;
        const d = Math.sqrt(qx * qx + qy * qy);
        const cae = 1 - t / largo;                       // la chispa se apaga hacia la punta
        const v = Math.exp(-(d * d) / (radio * radio)) * cae * brillo;
        const i = yy * n + xx;
        if (v > inten[i]) inten[i] = v;
      }
    }
  }

  for (let i = 0; i < n * n; i++) {
    const i3 = i * 3;
    const v = sat(inten[i]);
    pon(A, i3, cola);
    mez(A, i3, medio, sat(v * 1.6));
    mez(A, i3, nucleo, sat(v * 2.4 - 0.9));
    E[i3] = A[i3] * v * 1.6; E[i3 + 1] = A[i3 + 1] * v * 1.6; E[i3 + 2] = A[i3 + 2] * v * 1.6;
    H[i] = 0.5; R[i] = 1; O[i] = 1;
    AL[i] = sat(v * 1.4);
  }
};

GEN.destello = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa, E = c.emis;
  const ruidoAng = capaRuido(rt, n, { fx: 6, oct: 3, sal: 821 });
  const calido = C('#fff3cf'), medio = C('#ffd27a'), frio = C('#8fd4ff');

  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const i = y * n + x, i3 = i * 3;
      const dx = (x + 0.5) / n - 0.5, dy = (y + 0.5) / n - 0.5;
      const r = Math.sqrt(dx * dx + dy * dy) * 2;         // 0 centro, 1 borde
      const ang = Math.atan2(dy, dx);
      const nucleo = Math.pow(sat(1 - r * 1.05), 3.2);
      const halo = Math.pow(sat(1 - r), 1.5) * 0.35;
      // seis puntas, moduladas por ruido para que no parezca un asterisco
      const puntas = Math.pow(sat(Math.cos(ang * 3) * 0.5 + 0.5), 22) * Math.pow(sat(1 - r * 1.1), 1.6);
      const anillo = Math.exp(-Math.pow((r - 0.62) * 9, 2)) * 0.22 * (0.7 + ruidoAng[i] * 0.6);
      const v = sat(nucleo + halo + puntas * 0.8 + anillo);

      pon(A, i3, frio);
      mez(A, i3, medio, sat(v * 1.4));
      mez(A, i3, calido, sat(v * 2.2 - 0.8));
      E[i3] = A[i3] * v * 2; E[i3 + 1] = A[i3 + 1] * v * 2; E[i3 + 2] = A[i3 + 2] * v * 2;
      H[i] = 0.5; R[i] = 1; O[i] = 1;
      AL[i] = v;
    }
  }
};

/* ------------------------------------------------------- EFECTOS (128 px) */

GEN.particula_humo = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa;
  const dens = capaRuido(rt, n, { tipo: 'turb', fx: 3, oct: 5, sal: 823, warp: 0.55, warpFrec: 2 });
  const claro = C('#cfcdc8'), oscuro = C('#4e4b47');
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const i = y * n + x, i3 = i * 3;
      const dx = (x + 0.5) / n - 0.5, dy = (y + 0.5) / n - 0.5;
      const r = Math.sqrt(dx * dx + dy * dy) * 2;
      const bola = smoothstep(1.0, 0.15, r);
      const d = sat(bola * (0.55 + dens[i] * 0.9));
      // gradiente de luz falso: el borde superior izquierdo del bollo se ve más claro
      const luz = sat(0.5 - dy * 1.2 - dx * 0.5);
      pon(A, i3, oscuro);
      mez(A, i3, claro, sat(luz * 0.85 + dens[i] * 0.3));
      H[i] = sat(0.4 + d * 0.5);
      R[i] = 1; O[i] = sat(0.6 + 0.4 * d);
      AL[i] = sat(d * 1.25 - 0.06);
    }
  }
};

GEN.particula_fuego = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa, E = c.emis;
  const turbul = capaRuido(rt, n, { tipo: 'turb', fx: 4, oct: 5, sal: 827, warp: 0.6, warpFrec: 2 });
  const blanco = C('#fff8e0'), amarillo = C('#ffc martial'.length ? '#ffc046' : '#ffc046');
  const naranja = C('#ff6a1c'), rojo = C('#8e1f06');
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const i = y * n + x, i3 = i * 3;
      const dx = (x + 0.5) / n - 0.5, dy = (y + 0.5) / n - 0.5;
      // llama estirada hacia arriba (dy negativo = arriba en el sprite)
      const r = Math.sqrt(dx * dx * 1.9 + (dy + 0.08) * (dy + 0.08) * 0.95) * 2;
      const cuerpo = sat(smoothstep(1.05, 0.1, r) * (0.6 + turbul[i] * 0.85));
      const calor = sat(cuerpo * 1.25 - Math.max(0, dy) * 0.5);
      pon(A, i3, rojo);
      mez(A, i3, naranja, sat(calor * 1.5));
      mez(A, i3, amarillo, sat(calor * 2.0 - 0.6));
      mez(A, i3, blanco, sat(calor * 2.6 - 1.5));
      E[i3] = A[i3] * calor * 2.2; E[i3 + 1] = A[i3 + 1] * calor * 2.2; E[i3 + 2] = A[i3 + 2] * calor * 2.2;
      H[i] = 0.5; R[i] = 1; O[i] = 1;
      AL[i] = sat(cuerpo * 1.3 - 0.08);
    }
  }
};

GEN.particula_polvo = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa;
  const dens = capaRuido(rt, n, { tipo: 'turb', fx: 5, oct: 4, sal: 829, warp: 0.45, warpFrec: 3 });
  const motas = capaWorley(rt, n, { cx: 16, sal: 839, muestras: 8 });
  const claro = C('#d8c49c'), oscuro = C('#8a7351');
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const i = y * n + x, i3 = i * 3;
      const dx = (x + 0.5) / n - 0.5, dy = (y + 0.5) / n - 0.5;
      const r = Math.sqrt(dx * dx + dy * dy) * 2;
      const bola = smoothstep(1.0, 0.2, r);
      const mota = smoothstep(0.42, 0.16, motas.f1[i]) * 0.35;
      const d = sat(bola * (0.5 + dens[i] * 0.9 + mota));
      pon(A, i3, oscuro);
      mez(A, i3, claro, sat(0.45 - dy * 1.1 + dens[i] * 0.4));
      H[i] = sat(0.45 + d * 0.35);
      R[i] = 1; O[i] = sat(0.7 + 0.3 * d);
      AL[i] = sat(d * 0.95 - 0.05);
    }
  }
};

GEN.anillo_choque = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa, E = c.emis;
  const modula = capaRuido(rt, n, { fx: 7, oct: 3, sal: 853 });
  const frio = C('#dff0ff'), calido = C('#ffe9c0');
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const i = y * n + x, i3 = i * 3;
      const dx = (x + 0.5) / n - 0.5, dy = (y + 0.5) / n - 0.5;
      const r = Math.sqrt(dx * dx + dy * dy) * 2;
      const radio = 0.70 + modula[i] * 0.05;
      const grosor = 0.10 + modula[i] * 0.03;
      const anillo = Math.exp(-Math.pow((r - radio) / grosor, 2));
      const interior = smoothstep(radio, 0.1, r) * 0.16;
      const v = sat(anillo + interior) * smoothstep(1.02, 0.9, r);
      pon(A, i3, frio);
      mez(A, i3, calido, sat(v * 0.6));
      E[i3] = A[i3] * v * 1.8; E[i3 + 1] = A[i3 + 1] * v * 1.8; E[i3 + 2] = A[i3 + 2] * v * 1.8;
      H[i] = 0.5; R[i] = 1; O[i] = 1;
      AL[i] = v;
    }
  }
};

GEN.decal_crater = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa;
  const borde = capaRuido(rt, n, { fx: 5, oct: 4, sal: 857 });
  const escombro = capaWorley(rt, n, { cx: 20, sal: 859, muestras: 8 });
  const grano = capaRuido(rt, n, { fx: 60, oct: 2, sal: 863 });
  const hondo = C('#241a12'), tierra = C('#4e3a26'), labio = C('#7a6244'), quemado = C('#15100c');

  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const i = y * n + x, i3 = i * 3;
      const dx = (x + 0.5) / n - 0.5, dy = (y + 0.5) / n - 0.5;
      const ang = Math.atan2(dy, dx);
      const r = Math.sqrt(dx * dx + dy * dy) * 2 * (1 + Math.sin(ang * 3 + borde[i] * 5) * 0.06);
      const cuenco = smoothstep(0.62, 0.0, r);
      const labioM = Math.exp(-Math.pow((r - 0.58) / 0.14, 2));
      const rayo = Math.pow(sat(Math.cos(ang * 7 + borde[i] * 6) * 0.5 + 0.5), 6) * smoothstep(0.95, 0.5, r);
      const esc2 = smoothstep(0.30, 0.08, escombro.f1[i]) * smoothstep(0.95, 0.4, r);
      const g = grano[i];

      const h = sat(0.5 - cuenco * 0.45 + labioM * 0.30 + esc2 * 0.12 + g * 0.04);
      H[i] = h;
      pon(A, i3, tierra);
      mez(A, i3, hondo, cuenco * 0.85);
      mez(A, i3, quemado, sat(cuenco * 1.4 - 0.5) * 0.8);
      mez(A, i3, labio, sat(labioM * 0.9 + esc2 * 0.6));
      esc(A, i3, 0.9 + g * 0.14);
      R[i] = sat(0.9 + g * 0.06 - cuenco * 0.1);
      O[i] = sat(0.35 + 0.65 * smoothstep(0.05, 0.7, h));
      AL[i] = sat(smoothstep(0.98, 0.72, r) + rayo * 0.35 + esc2 * 0.4);
    }
  }
};

GEN.decal_quemadura = (rt, c) => {
  const n = c.n, A = c.alb, H = c.alt, R = c.rug, O = c.ao, AL = c.alfa;
  const forma = capaRuido(rt, n, { tipo: 'turb', fx: 4, oct: 5, sal: 877, warp: 0.5, warpFrec: 2 });
  const grietas = capaRuido(rt, n, { tipo: 'ridged', fx: 7, oct: 4, sal: 881 });
  const negro = C('#12100d'), carbon = C('#2e2620'), ceniza = C('#6b6257'), borde = C('#4a3524');

  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const i = y * n + x, i3 = i * 3;
      const dx = (x + 0.5) / n - 0.5, dy = (y + 0.5) / n - 0.5;
      const r = Math.sqrt(dx * dx + dy * dy) * 2;
      const mancha = sat(smoothstep(1.0, 0.25, r) * (0.6 + forma[i] * 0.9));
      const grieta = smoothstep(0.86, 0.98, grietas[i]) * mancha;

      pon(A, i3, borde);
      mez(A, i3, carbon, sat(mancha * 1.5));
      mez(A, i3, negro, sat(mancha * 2.0 - 0.7));
      mez(A, i3, ceniza, grieta * 0.55);
      H[i] = sat(0.5 - mancha * 0.12 + grieta * 0.06);
      R[i] = sat(0.94 - grieta * 0.1);
      O[i] = sat(0.7 + 0.3 * (1 - mancha));
      AL[i] = sat(mancha * 1.2 - 0.06);
    }
  }
};

/* ══════════════════════════════════════════════════════════════════════════
   Biblioteca
   ══════════════════════════════════════════════════════════════════════════ */

function hashCadena(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return h >>> 0;
}

export class BibliotecaTexturas {
  constructor(ctx) {
    this.ctx = ctx;
    this.rt = new RuidoTeja(ctx && ctx.ruido ? ctx.ruido : new Ruido(1337));
    this.semilla = (ctx && ctx.semilla) || 1337;
    // en calidad baja bajamos el lado: mismo diseño, un cuarto de la memoria
    this.lado = (ctx && ctx.calidad === 'baja') ? 256 : 512;
    this.anisotropia = 4;
    try {
      const r = ctx && ctx.renderer;
      if (r && r.capabilities) this.anisotropia = Math.min(8, r.capabilities.getMaxAnisotropy());
    } catch (e) { /* sin renderer todavía: se queda en 4 */ }

    this.base = new Map();        // clave -> juego de texturas repetición 1x1
    this.variantes = new Map();   // clave@UxV -> clones
    this.materiales = new Map();
    this.listo = false;
  }

  /* ---------------- generación ---------------- */

  _generar(clave) {
    const cfg = CFG[clave];
    const gen = GEN[clave];
    if (!cfg || !gen) {
      console.warn(`[Texturas] clave desconocida: ${clave}`);
      return this._base('hormigon');
    }
    const n = cfg.n || Math.round(this.lado * (FACTOR_RES[clave] ?? FACTOR_RES._resto));
    const c = new Campo(n, !!cfg.alfa, !!cfg.emision);
    const rng = new RNG((this.semilla ^ hashCadena(clave)) >>> 0);
    gen(this.rt, c, rng);
    return this._finalizar(clave, c, cfg);
  }

  _finalizar(clave, c, cfg) {
    const n = c.n, px = n * n;
    const { alb: A, alt: H, rug: R, met: M, ao: O, alfa: AL, emis: E } = c;

    // AO de cavidad: cuánto se hunde el píxel respecto de su vecindario.
    if (cfg.cavidad > 0 && cfg.radio > 0) {
      const radio = Math.max(1, Math.round(cfg.radio * (n / 512)) || 1);
      const suave = suavizarCaja(H, n, radio);
      for (let i = 0; i < px; i++) {
        const d = H[i] - suave[i];
        const oc = 0.32 + 0.68 * smoothstep(-0.22, 0.05, d);
        O[i] *= lerp(1, oc, cfg.cavidad);
      }
    }
    // Un poco de esa oclusión va al albedo: el aoMap sólo toca la luz indirecta
    // y sin esto las juntas se pierden a 80 m de cámara.
    for (let i = 0; i < px; i++) esc(A, i * 3, lerp(1, sat(O[i]), 0.28));

    const datosAlb = new Uint8ClampedArray(px * 4);
    const datosOrm = new Uint8ClampedArray(px * 4);
    for (let i = 0; i < px; i++) {
      const i3 = i * 3, i4 = i * 4;
      datosAlb[i4] = sat(A[i3]) * 255;
      datosAlb[i4 + 1] = sat(A[i3 + 1]) * 255;
      datosAlb[i4 + 2] = sat(A[i3 + 2]) * 255;
      datosAlb[i4 + 3] = AL ? sat(AL[i]) * 255 : 255;
      datosOrm[i4] = sat(O[i]) * 255;        // R = oclusión
      datosOrm[i4 + 1] = sat(R[i]) * 255;    // G = rugosidad
      datosOrm[i4 + 2] = sat(M[i]) * 255;    // B = metálico
      datosOrm[i4 + 3] = 255;
    }

    const mkImg = (d) => (typeof ImageData !== 'undefined' ? new ImageData(d, n, n) : { data: d, width: n, height: n });
    const map = this._tex(mkImg(datosAlb), n, THREE.SRGBColorSpace);
    const orm = this._tex(mkImg(datosOrm), n, THREE.NoColorSpace);
    const normalMap = this._tex(generarMapaNormalDesdeAltura(H, n, n, cfg.normal), n, THREE.NoColorSpace);

    const juego = { map, normalMap, roughnessMap: orm, aoMap: orm, metalnessMap: orm };

    if (E) {
      const datosEmis = new Uint8ClampedArray(px * 4);
      for (let i = 0; i < px; i++) {
        const i3 = i * 3, i4 = i * 4;
        datosEmis[i4] = sat(E[i3]) * 255;
        datosEmis[i4 + 1] = sat(E[i3 + 1]) * 255;
        datosEmis[i4 + 2] = sat(E[i3 + 2]) * 255;
        datosEmis[i4 + 3] = 255;
      }
      juego.emissiveMap = this._tex(mkImg(datosEmis), n, THREE.SRGBColorSpace);
    }
    juego.tieneAlfa = !!AL;
    return juego;
  }

  _tex(imgData, n, colorSpace) {
    const t = new THREE.CanvasTexture(lienzoDesde(imgData, n));
    t.wrapS = t.wrapT = THREE.RepeatWrapping;
    t.colorSpace = colorSpace;
    t.generateMipmaps = true;
    t.minFilter = THREE.LinearMipmapLinearFilter;
    t.magFilter = THREE.LinearFilter;
    t.anisotropy = this.anisotropia;
    t.needsUpdate = true;
    return t;
  }

  _base(clave) {
    let j = this.base.get(clave);
    if (!j) { j = this._generar(clave); this.base.set(clave, j); }
    return j;
  }

  /* ---------------- API pública ---------------- */

  /** Genera el set base cediendo el hilo cada 3 texturas para que la barra avance. */
  async precargar() {
    const total = ORDEN_PRECARGA.length;
    for (let i = 0; i < total; i++) {
      const clave = ORDEN_PRECARGA[i];
      if (!this.base.has(clave)) this.base.set(clave, this._generar(clave));
      if (i % 3 === 2 || i === total - 1) {
        this.ctx?.bus?.emit?.('carga:textura', { clave, hechas: i + 1, total });
        await new Promise((r) => setTimeout(r, 0));
      }
    }
    this.listo = true;
    return this;
  }

  /**
   * @param {string} clave
   * @param {{repeticion?:[number,number]}} [opciones]
   * @returns {{map:THREE.Texture, normalMap:THREE.Texture, roughnessMap:THREE.Texture, aoMap:THREE.Texture}}
   */
  obtener(clave, opciones = {}) {
    const base = this._base(clave);
    const rep = opciones.repeticion;
    if (!rep || (rep[0] === 1 && rep[1] === 1)) return base;
    const k = `${clave}@${rep[0]}x${rep[1]}`;
    let v = this.variantes.get(k);
    if (v) return v;
    // los clones comparten `source`: una sola subida a GPU, distinto repeat
    v = {};
    for (const nombre of ['map', 'normalMap', 'emissiveMap']) {
      if (base[nombre]) { const t = base[nombre].clone(); t.repeat.set(rep[0], rep[1]); t.needsUpdate = true; v[nombre] = t; }
    }
    const orm = base.roughnessMap.clone();
    orm.repeat.set(rep[0], rep[1]);
    orm.needsUpdate = true;
    v.roughnessMap = orm; v.aoMap = orm; v.metalnessMap = orm;
    v.tieneAlfa = base.tieneAlfa;
    this.variantes.set(k, v);
    return v;
  }

  /**
   * Material cacheado. opciones:
   *  { repeticion:[u,v], color, rugosidad, metalico, emisivo, transparente, ladoDoble, tinte }
   */
  material(clave, opciones = {}) {
    const o = opciones;
    const emisivoK = o.emisivo && typeof o.emisivo === 'object'
      ? `${o.emisivo.color || ''}:${o.emisivo.intensidad || 1}` : (o.emisivo || '');
    const k = [
      clave,
      o.repeticion ? `${o.repeticion[0]}x${o.repeticion[1]}` : '1x1',
      o.color || '', o.tinte || '', o.rugosidad ?? '', o.metalico ?? '',
      emisivoK, o.transparente ? 't' : '', o.ladoDoble ? 'd' : '',
    ].join('|');
    let m = this.materiales.get(k);
    if (m) return m;

    const t = this.obtener(clave, o);
    const color = new THREE.Color(o.color != null ? o.color : 0xffffff);
    if (o.tinte != null) color.multiply(new THREE.Color(o.tinte));

    m = new THREE.MeshStandardMaterial({
      map: t.map,
      normalMap: t.normalMap,
      roughnessMap: t.roughnessMap,
      metalnessMap: t.metalnessMap,
      aoMap: t.aoMap,
      color,
      // los mapas ORM multiplican, así que el escalar por defecto es 1
      roughness: o.rugosidad != null ? o.rugosidad : 1,
      metalness: o.metalico != null ? o.metalico : 1,
      side: o.ladoDoble ? THREE.DoubleSide : THREE.FrontSide,
    });
    m.name = `mat_${clave}`;
    m.normalScale.set(1, 1);
    m.aoMapIntensity = 1;

    if (t.emissiveMap) {
      m.emissiveMap = t.emissiveMap;
      const e = o.emisivo && typeof o.emisivo === 'object' ? o.emisivo : { color: o.emisivo };
      m.emissive = new THREE.Color(e.color != null ? e.color : 0xffffff);
      m.emissiveIntensity = e.intensidad != null ? e.intensidad : 1.4;
    } else if (o.emisivo) {
      const e = typeof o.emisivo === 'object' ? o.emisivo : { color: o.emisivo };
      m.emissive = new THREE.Color(e.color != null ? e.color : 0xffffff);
      m.emissiveIntensity = e.intensidad != null ? e.intensidad : 1;
    }

    if (o.transparente || t.tieneAlfa) {
      m.transparent = true;
      // las partículas y los decals no deben escribir profundidad entre sí
      const esEfecto = clave.startsWith('particula_') || clave.startsWith('decal_')
        || clave === 'chispa' || clave === 'destello' || clave === 'anillo_choque' || clave === 'humo';
      m.depthWrite = o.escribirProfundidad != null ? o.escribirProfundidad : !esEfecto;
      if (clave.startsWith('decal_')) { m.polygonOffset = true; m.polygonOffsetFactor = -2; m.polygonOffsetUnits = -2; }
    }
    this.materiales.set(k, m);
    return m;
  }

  /** Tintes de la edad (atajo para las fábricas de mallas). */
  paletaEdad(edad) { return paletaEdad(edad); }

  dispose() {
    for (const j of this.base.values()) {
      for (const nombre of ['map', 'normalMap', 'roughnessMap', 'emissiveMap']) j[nombre]?.dispose?.();
    }
    for (const j of this.variantes.values()) {
      for (const nombre of ['map', 'normalMap', 'roughnessMap', 'emissiveMap']) j[nombre]?.dispose?.();
    }
    for (const m of this.materiales.values()) m.dispose();
    this.base.clear(); this.variantes.clear(); this.materiales.clear();
    this.listo = false;
  }
}

export default BibliotecaTexturas;
