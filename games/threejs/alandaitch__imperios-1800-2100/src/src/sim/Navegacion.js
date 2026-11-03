/**
 * NAVEGACIÓN — rejilla, A*, suavizado y campos de flujo.
 *
 * Es el sistema que decide si el juego se siente como Age of Empires II o como
 * un rompecabezas de unidades trabadas. Reglas de la casa:
 *
 *  - Rejilla de 1 celda = 2 m, `tam/2` celdas por lado (mapa 512 m -> 256×256).
 *  - DOS capas de transitabilidad: terrestre y naval. Se elige por unidad.
 *  - Todo se guarda en arrays tipados. Cero objetos por celda, cero objetos por
 *    nodo de búsqueda, cero `sort()`. El montón binario vive en Int32/Float32.
 *  - `fijo()` nunca gasta más de PRESUPUESTO_MS. Los pedidos se encolan.
 *  - La holgura (distancia de Chebyshev a la celda bloqueada más cercana) hace
 *    de inflado de obstáculos: una unidad de radio r necesita holgura >= f(r),
 *    así nadie roza las esquinas de los edificios.
 *
 * Convención clave: `holgura[i] === 0` significa "celda intransitable" (fuera de
 * mapa, agua para terrestres, tierra para navales, pendiente brutal o bloqueada
 * por un edificio). Toda consulta de transitabilidad es un solo `>=`.
 */
import * as THREE from 'three';
import { ORDEN } from '../core/Ctx.js';
import { UNIDADES } from '../data/unidades.js';

/* ------------------------------- constantes ------------------------------- */
const TAM_CELDA = 2;            // metros por celda (contrato)
const COSTO_BASE = 8;           // costo de una celda llana; deja lugar a fracciones
const COSTO_MAX = 250;          // techo del Uint8
const MAX_HOLGURA = 6;          // 12 m: más que eso no le importa a nadie
const RAIZ2 = Math.SQRT2;
const PRESUPUESTO_MS = 3;       // techo duro de fijo()
const MAX_NODOS = 4000;         // expansión máxima de un A* corto
const TOPE_NODOS = 13000;       // techo absoluto para una marcha de punta a punta
const PESO_H = 1.12;            // A* levemente ponderado: 3-5× más rápido, camino casi óptimo
const LOTE_FLUJO = 1200;        // nodos de Dijkstra por lote de campo de flujo
const VIDA_CAMPO = 5;           // segundos de validez de un campo de flujo cacheado
const MAX_CAMPOS = 8;           // campos vivos en caché
const RESERVA_TICKS = 24;       // ~1.2 s: evita que dos desembarcos elijan la misma celda
const PENAL_MURO = COSTO_BASE * 3; // repulsión del gradiente cerca de obstáculos

/** Costo base por bioma (multiplicado por COSTO_BASE/8). */
const COSTO_BIOMA = {
  pradera: 8, playa: 9, desierto: 9, bosque: 11, montana: 18, agua: 8,
};

/* ============================== montón binario ============================== */
/**
 * Cola de prioridad mínima sobre arrays tipados. Inserción perezosa: un nodo
 * puede entrar varias veces y el duplicado se descarta al salir (ya cerrado).
 * Sale más barato que mantener un índice de posiciones para decrease-key.
 */
class MontonBinario {
  constructor(cap = 8192) {
    this.n = 0;
    this.nodos = new Int32Array(cap);
    this.claves = new Float32Array(cap);
    this.claveSacada = 0;
  }
  limpiar() { this.n = 0; }
  get vacio() { return this.n === 0; }

  _crecer() {
    const cap = this.nodos.length * 2;
    const nn = new Int32Array(cap); nn.set(this.nodos);
    const nc = new Float32Array(cap); nc.set(this.claves);
    this.nodos = nn; this.claves = nc;
  }

  meter(nodo, clave) {
    if (this.n === this.nodos.length) this._crecer();
    const nodos = this.nodos, claves = this.claves;
    let i = this.n++;
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (claves[p] <= clave) break;
      nodos[i] = nodos[p]; claves[i] = claves[p];
      i = p;
    }
    nodos[i] = nodo; claves[i] = clave;
  }

  sacar() {
    const nodos = this.nodos, claves = this.claves;
    const raiz = nodos[0];
    this.claveSacada = claves[0];
    const n = --this.n;
    if (n > 0) {
      const nodoU = nodos[n], claveU = claves[n];
      let i = 0;
      for (;;) {
        let h = i * 2 + 1;
        if (h >= n) break;
        if (h + 1 < n && claves[h + 1] < claves[h]) h++;
        if (claves[h] >= claveU) break;
        nodos[i] = nodos[h]; claves[i] = claves[h];
        i = h;
      }
      nodos[i] = nodoU; claves[i] = claveU;
    }
    return raiz;
  }
}

/* ================================ Navegación ================================ */
export class Navegacion {
  constructor(ctx) {
    this.ctx = ctx;
    this.nombre = 'navegacion';
    this.orden = ORDEN.NAV;

    const ter = ctx?.terreno;
    this.tam = ter?.tam ?? ctx?.mapa?.tam ?? 512;
    this.tamCelda = TAM_CELDA;
    this.mitad = this.tam / 2;
    this.ancho = Math.max(8, Math.round(this.tam / TAM_CELDA));
    this.alto = this.ancho;
    this.n = this.ancho * this.alto;

    const N = this.n;
    this.costo = new Uint8Array(N);        // costo de terreno (COSTO_BASE = llano)
    this.bloqueo = new Uint8Array(N);      // contador de bloqueadores estáticos
    this.pasaT = new Uint8Array(N);        // 1 = suelo pisable
    this.pasaN = new Uint8Array(N);        // 1 = agua navegable
    this.holguraT = new Uint8Array(N);     // 0 = intransitable · 1..MAX_HOLGURA
    this.holguraN = new Uint8Array(N);
    this.selloReserva = new Int32Array(N); // tick en que puntoLibreCerca entregó la celda

    // ---- estructuras de búsqueda (se reutilizan entre pedidos) ----
    this.gCosto = new Float32Array(N);
    this.padre = new Int32Array(N);
    this.sello = new Int32Array(N);        // id de búsqueda que tocó la celda
    this.cerrado = new Uint8Array(N);
    this.busqueda = 0;
    this.monton = new MontonBinario(1 << 13);
    this._rutaTmp = new Int32Array(4096);

    // ---- suciedad diferida ----
    // Dos listas de rectángulos: los de costo hay que re-muestrearlos contra el
    // terreno (caro), los de holgura sólo pasan el chamfer (barato). Se guardan
    // por separado y sin unir cosas lejanas: unir dos esquinas del mapa haría
    // que un árbol talado en cada punta cueste un remuestreo completo.
    this._rectsC = [];
    this._rectsH = [];
    this.version = 1;                              // sube en cada recálculo

    // ---- cola de pedidos asíncronos ----
    this._pendientes = new Map();  // id -> pedido (el último pedido de un id pisa al anterior)
    this._cola = [];
    this._colaIni = 0;
    this._op = { capa: undefined, naval: undefined, aereo: undefined, maxNodos: undefined, holgura: undefined };
    this._msPorPedido = 0.25;      // media móvil del costo de resolver un pedido

    // ---- campos de flujo ----
    this._campos = new Map();      // clave -> CampoFlujo
    this._camposPendientes = [];
    this._poolBuffers = [];

    this.stats = { pedidos: 0, resueltos: 0, fallidos: 0, nodos: 0, ms: 0, cola: 0, campos: 0 };
    this._debug = null;

    this._muestrearTerreno(0, 0, this.ancho - 1, this.alto - 1);
    this._recalcHolgura(0, 0, 0, this.ancho - 1, this.alto - 1);
    this._recalcHolgura(1, 0, 0, this.ancho - 1, this.alto - 1);
  }

  /* --------------------------- conversiones básicas -------------------------- */
  celdaX(x) { const c = ((x + this.mitad) / TAM_CELDA) | 0; return c < 0 ? 0 : c >= this.ancho ? this.ancho - 1 : c; }
  celdaZ(z) { const c = ((z + this.mitad) / TAM_CELDA) | 0; return c < 0 ? 0 : c >= this.alto ? this.alto - 1 : c; }
  mundoX(cx) { return (cx + 0.5) * TAM_CELDA - this.mitad; }
  mundoZ(cz) { return (cz + 0.5) * TAM_CELDA - this.mitad; }
  indice(cx, cz) { return cz * this.ancho + cx; }
  dentro(cx, cz) { return cx >= 0 && cz >= 0 && cx < this.ancho && cz < this.alto; }

  /**
   * Holgura mínima (en celdas) que necesita una unidad de radio `radio` metros.
   * Con margen de 0.5 m: la infantería (r≈0.4) pasa por huecos de 1 celda, los
   * tanques y las naves (r≈1.5-2) piden 2 celdas y no rozan las esquinas.
   */
  holguraNecesaria(radio = 0.5) {
    const h = Math.ceil((radio + 0.5) / TAM_CELDA);
    return h < 1 ? 1 : h > MAX_HOLGURA ? MAX_HOLGURA : h;
  }

  capaDe(id) {
    const m = this.ctx?.mundo;
    if (!m) return 0;
    const def = UNIDADES[m.defId[id]];
    return def?.naval ? 1 : 0;
  }

  /* ------------------------------ muestreo mapa ------------------------------ */
  /** Relee el terreno en un rectángulo de celdas y recalcula costo + pasabilidad. */
  _muestrearTerreno(x0, z0, x1, z1) {
    const ter = this.ctx?.terreno;
    const A = this.ancho;
    for (let cz = z0; cz <= z1; cz++) {
      const zw = this.mundoZ(cz);
      for (let cx = x0; cx <= x1; cx++) {
        const xw = this.mundoX(cx);
        const i = cz * A + cx;
        let bioma = 'pradera', pend = 0, trans = true;
        if (ter) {
          if (ter.bioma) bioma = ter.bioma(xw, zw) || 'pradera';
          if (ter.pendiente) pend = ter.pendiente(xw, zw) || 0;
          if (ter.transitable) trans = ter.transitable(xw, zw) !== false;
        }
        const agua = bioma === 'agua';
        let c = (COSTO_BIOMA[bioma] ?? COSTO_BASE) + pend * 34;
        if (c < COSTO_BASE) c = COSTO_BASE;
        if (c > COSTO_MAX) c = COSTO_MAX;
        this.costo[i] = c;
        // El borde del mapa queda muerto: nadie navega pegado al vacío.
        const borde = cx === 0 || cz === 0 || cx === A - 1 || cz === this.alto - 1;
        this.pasaT[i] = (!agua && trans && pend < 0.6 && !borde) ? 1 : 0;
        this.pasaN[i] = (agua && !borde) ? 1 : 0;
      }
    }
  }

  /**
   * Transformada de distancia de Chebyshev en dos pasadas (adelante/atrás).
   * Se recalcula sólo dentro del rectángulo, pero éste viene inflado por
   * MAX_HOLGURA: como el valor está topeado en MAX_HOLGURA, ninguna celda de
   * afuera pudo derivar su valor de una celda de adentro. Local y correcto.
   */
  _recalcHolgura(capa, x0, z0, x1, z1) {
    const A = this.ancho, B = this.alto;
    const pasa = capa === 1 ? this.pasaN : this.pasaT;
    const h = capa === 1 ? this.holguraN : this.holguraT;
    const blo = this.bloqueo;
    x0 = x0 < 0 ? 0 : x0; z0 = z0 < 0 ? 0 : z0;
    x1 = x1 >= A ? A - 1 : x1; z1 = z1 >= B ? B - 1 : z1;

    for (let cz = z0; cz <= z1; cz++) {
      const f = cz * A;
      for (let cx = x0; cx <= x1; cx++) {
        const i = f + cx;
        h[i] = (pasa[i] === 1 && blo[i] === 0) ? MAX_HOLGURA : 0;
      }
    }
    // pasada adelante: vecinos (-1,0) (-1,-1) (0,-1) (+1,-1)
    for (let cz = z0; cz <= z1; cz++) {
      const f = cz * A;
      for (let cx = x0; cx <= x1; cx++) {
        const i = f + cx;
        if (h[i] === 0) continue;
        let m = MAX_HOLGURA - 1;
        if (cx > 0 && h[i - 1] < m) m = h[i - 1];
        if (cz > 0) {
          if (h[i - A] < m) m = h[i - A];
          if (cx > 0 && h[i - A - 1] < m) m = h[i - A - 1];
          if (cx < A - 1 && h[i - A + 1] < m) m = h[i - A + 1];
        }
        const v = m + 1;
        if (v < h[i]) h[i] = v;
      }
    }
    // pasada atrás: vecinos (+1,0) (+1,+1) (0,+1) (-1,+1)
    for (let cz = z1; cz >= z0; cz--) {
      const f = cz * A;
      for (let cx = x1; cx >= x0; cx--) {
        const i = f + cx;
        if (h[i] === 0) continue;
        let m = h[i] - 1;
        if (cx < A - 1 && h[i + 1] < m) m = h[i + 1];
        if (cz < B - 1) {
          if (h[i + A] < m) m = h[i + A];
          if (cx < A - 1 && h[i + A + 1] < m) m = h[i + A + 1];
          if (cx > 0 && h[i + A - 1] < m) m = h[i + A - 1];
        }
        const v = m + 1;
        if (v < h[i]) h[i] = v;
      }
    }
  }

  /** Agrega un rectángulo sucio a `lista`, fusionándolo sólo si queda pegado. */
  _ensuciar(lista, x0, z0, x1, z1) {
    const areaN = (x1 - x0 + 1) * (z1 - z0 + 1);
    let mejor = -1, extraMin = Infinity, ux0 = 0, uz0 = 0, ux1 = 0, uz1 = 0;
    for (let i = 0; i < lista.length; i++) {
      const r = lista[i];
      const a = r[0] < x0 ? r[0] : x0, b = r[1] < z0 ? r[1] : z0;
      const cc = r[2] > x1 ? r[2] : x1, d = r[3] > z1 ? r[3] : z1;
      const extra = (cc - a + 1) * (d - b + 1) - (r[2] - r[0] + 1) * (r[3] - r[1] + 1) - areaN;
      if (extra < extraMin) { extraMin = extra; mejor = i; ux0 = a; uz0 = b; ux1 = cc; uz1 = d; }
    }
    if (mejor >= 0 && (extraMin <= 400 || lista.length >= 10)) {
      const r = lista[mejor]; r[0] = ux0; r[1] = uz0; r[2] = ux1; r[3] = uz1;
      return;
    }
    lista.push([x0, z0, x1, z1]);
  }

  /** Aplica los recálculos pendientes. Barato cuando no hay nada sucio. */
  _asegurarActualizado() {
    const lc = this._rectsC, lh = this._rectsH;
    if (!lc.length && !lh.length) return;
    const A = this.ancho, B = this.alto;
    for (let i = 0; i < lc.length; i++) {
      const r = lc[i];
      this._muestrearTerreno(
        Math.max(0, r[0]), Math.max(0, r[1]),
        Math.min(A - 1, r[2]), Math.min(B - 1, r[3]),
      );
      this._ensuciar(lh, r[0], r[1], r[2], r[3]);
    }
    lc.length = 0;
    const P = MAX_HOLGURA;
    for (let i = 0; i < lh.length; i++) {
      const r = lh[i];
      this._recalcHolgura(0, r[0] - P, r[1] - P, r[2] + P, r[3] + P);
      this._recalcHolgura(1, r[0] - P, r[1] - P, r[2] + P, r[3] + P);
    }
    lh.length = 0;
    this.version++;
  }

  /* ------------------------------- API pública ------------------------------- */

  /**
   * Marca/libera celdas ocupadas por un edificio.
   * (x,z) es el CENTRO en metros; ancho/alto van en CELDAS (tabla de edificios).
   * `valor` falsy libera, truthy bloquea. Se lleva un contador por celda para
   * que dos edificios superpuestos no se desbloqueen entre sí.
   */
  bloquear(x, z, ancho = 1, alto = 1, valor = 1) {
    const fx = (x + this.mitad) / TAM_CELDA, fz = (z + this.mitad) / TAM_CELDA;
    let cx0 = Math.round(fx - ancho / 2), cz0 = Math.round(fz - alto / 2);
    let cx1 = cx0 + Math.max(1, ancho | 0) - 1, cz1 = cz0 + Math.max(1, alto | 0) - 1;
    const A = this.ancho;
    const ex0 = Math.max(0, cx0), ez0 = Math.max(0, cz0);
    const ex1 = Math.min(this.ancho - 1, cx1), ez1 = Math.min(this.alto - 1, cz1);
    for (let cz = ez0; cz <= ez1; cz++) {
      for (let cx = ex0; cx <= ex1; cx++) {
        const i = cz * A + cx;
        if (valor) { if (this.bloqueo[i] < 255) this.bloqueo[i]++; }
        else if (this.bloqueo[i] > 0) this.bloqueo[i]--;
      }
    }
    if (ex1 >= ex0 && ez1 >= ez0) this._ensuciar(this._rectsH, ex0, ez0, ex1, ez1);
  }

  /** Recalcula terreno + holgura en un radio (metros). Talaste el bosque, cayó el muro. */
  refrescarZona(x, z, radio = 4) {
    const r = Math.ceil(radio / TAM_CELDA) + 1;
    const cx = this.celdaX(x), cz = this.celdaZ(z);
    const x0 = Math.max(0, cx - r), z0 = Math.max(0, cz - r);
    const x1 = Math.min(this.ancho - 1, cx + r), z1 = Math.min(this.alto - 1, cz + r);
    if (x1 >= x0 && z1 >= z0) this._ensuciar(this._rectsC, x0, z0, x1, z1);
  }

  celdaTransitable(cx, cz, capa = 0) {
    if (!this.dentro(cx, cz)) return false;
    const H = capa === 1 ? this.holguraN : this.holguraT;
    return H[cz * this.ancho + cx] > 0;
  }

  /** Costo relativo del terreno: 1.0 = llano. Sirve para modular la velocidad. */
  costoCelda(cx, cz) {
    if (!this.dentro(cx, cz)) return 999;
    return this.costo[cz * this.ancho + cx] / COSTO_BASE;
  }

  /** ¿Cabe algo de `radio` metros centrado en (x,z)? Usado para emplazar edificios. */
  esLibre(x, z, radio = 0.5, capa = 0) {
    this._asegurarActualizado();
    const H = capa === 1 ? this.holguraN : this.holguraT;
    const A = this.ancho;
    const r = Math.max(0, radio);
    const cx0 = this.celdaX(x - r), cx1 = this.celdaX(x + r);
    const cz0 = this.celdaZ(z - r), cz1 = this.celdaZ(z + r);
    if (x - r < -this.mitad || x + r > this.mitad || z - r < -this.mitad || z + r > this.mitad) return false;
    for (let cz = cz0; cz <= cz1; cz++) {
      for (let cx = cx0; cx <= cx1; cx++) if (H[cz * A + cx] === 0) return false;
    }
    return true;
  }

  /**
   * Celda libre más cercana a (x,z) en espiral, con reserva temporal para que
   * dos unidades que desembarcan el mismo tick no caigan en el mismo lugar.
   */
  puntoLibreCerca(x, z, radio = 0.5, opciones) {
    this._asegurarActualizado();
    const capa = opciones?.capa ?? (opciones?.naval ? 1 : 0);
    const hol = this.holguraNecesaria(radio);
    const i = this._celdaLibreCerca(this.celdaX(x), this.celdaZ(z), hol, capa, 24, true);
    if (i < 0) return { x, z };
    const A = this.ancho;
    return { x: this.mundoX(i % A), z: this.mundoZ((i / A) | 0) };
  }

  _celdaLibreCerca(cx, cz, hol, capa, maxAnillos = 20, reservar = false) {
    const H = capa === 1 ? this.holguraN : this.holguraT;
    const A = this.ancho, B = this.alto;
    const tick = this.ctx?.mundo?.tick ?? 0;
    const ok = (px, pz) => {
      if (px < 0 || pz < 0 || px >= A || pz >= B) return -1;
      const i = pz * A + px;
      if (H[i] < hol) return -1;
      if (reservar && tick - this.selloReserva[i] < RESERVA_TICKS && this.selloReserva[i] !== 0) return -1;
      if (reservar) this.selloReserva[i] = tick === 0 ? 1 : tick;
      return i;
    };
    let r0 = ok(cx, cz); if (r0 >= 0) return r0;
    for (let r = 1; r <= maxAnillos; r++) {
      for (let d = -r; d <= r; d++) {
        let i = ok(cx + d, cz - r); if (i >= 0) return i;
        i = ok(cx + d, cz + r); if (i >= 0) return i;
        i = ok(cx - r, cz + d); if (i >= 0) return i;
        i = ok(cx + r, cz + d); if (i >= 0) return i;
      }
    }
    return -1;
  }

  /**
   * A* sincrónico y acotado. Devuelve una lista corta de waypoints en metros
   * (ya suavizada) o null si no hay forma de llegar ni de acercarse.
   *
   * opciones: { capa, naval, aereo, maxNodos, holgura, destinoExacto }
   */
  camino(x0, z0, x1, z1, radio = 0.5, opciones) {
    this._asegurarActualizado();
    if (opciones?.aereo) return [{ x: x1, z: z1 }];   // los drones ignoran la malla

    const capa = opciones?.capa ?? (opciones?.naval ? 1 : 0);
    const hol = opciones?.holgura ?? this.holguraNecesaria(radio);
    const H = capa === 1 ? this.holguraN : this.holguraT;
    const A = this.ancho;

    // atajo: si hay línea limpia, no hace falta buscar nada
    if (this._lineaLibre(x0, z0, x1, z1, hol, capa)) return [{ x: x1, z: z1 }];

    let cx0 = this.celdaX(x0), cz0 = this.celdaZ(z0);
    let cx1 = this.celdaX(x1), cz1 = this.celdaZ(z1);
    let inicio = cz0 * A + cx0;
    if (H[inicio] < hol) {
      // la unidad quedó pisada por un edificio o encajonada: salimos a la celda válida más cercana
      const alt = this._celdaLibreCerca(cx0, cz0, hol, capa, 8, false);
      if (alt < 0) return null;
      inicio = alt;
    }
    let meta = cz1 * A + cx1;
    let metaExacta = true;
    if (H[meta] < hol) {
      const alt = this._celdaLibreCerca(cx1, cz1, hol, capa, 20, false);
      if (alt < 0) return null;
      meta = alt; metaExacta = false;
    }
    if (inicio === meta) {
      return metaExacta ? [{ x: x1, z: z1 }] : [{ x: this.mundoX(meta % A), z: this.mundoZ((meta / A) | 0) }];
    }

    // el presupuesto de nodos escala con la distancia: una orden corta cuesta
    // centavos y una marcha de punta a punta sigue llegando de una sola vez.
    const dCeldas = Math.abs((meta % A) - (inicio % A)) + Math.abs(((meta / A) | 0) - ((inicio / A) | 0));
    const tope = opciones?.maxNodos ?? Math.min(TOPE_NODOS, MAX_NODOS + dCeldas * 22);
    const nodoFinal = this._astar(inicio, meta, hol, capa, tope);
    if (nodoFinal < 0) return null;
    if (nodoFinal !== meta) metaExacta = false;

    const cant = this._reconstruir(inicio, nodoFinal);
    if (cant <= 0) return null;
    const destX = metaExacta ? x1 : this.mundoX(nodoFinal % A);
    const destZ = metaExacta ? z1 : this.mundoZ((nodoFinal / A) | 0);
    return this._suavizar(cant, x0, z0, destX, destZ, hol, capa);
  }

  /**
   * Pedido asíncrono: se resuelve en algún fijo() posterior, dentro del
   * presupuesto. Un pedido nuevo del mismo id pisa al anterior (la última orden
   * del jugador siempre gana).
   */
  pedirCamino(id, x1, z1, callback, opciones) {
    const p = this._pendientes.get(id);
    if (p) { p.x1 = x1; p.z1 = z1; p.cb = callback; p.op = opciones; return; }
    this._pendientes.set(id, { id, x1, z1, cb: callback, op: opciones });
    this._cola.push(id);
    this.stats.pedidos++;
  }

  cancelarCamino(id) { this._pendientes.delete(id); }

  /* --------------------------------- A* core -------------------------------- */
  _astar(inicio, meta, hol, capa, maxNodos) {
    const A = this.ancho, B = this.alto;
    const H = capa === 1 ? this.holguraN : this.holguraT;
    const costo = this.costo, g = this.gCosto, padre = this.padre;
    const sello = this.sello, cerrado = this.cerrado;
    const marca = ++this.busqueda;
    const monton = this.monton;
    monton.limpiar();

    const mx = meta % A, mz = (meta / A) | 0;
    const h = (i) => {
      const dx = Math.abs((i % A) - mx), dz = Math.abs(((i / A) | 0) - mz);
      const mn = dx < dz ? dx : dz;
      return COSTO_BASE * ((dx + dz) + (RAIZ2 - 2) * mn);
    };

    sello[inicio] = marca; g[inicio] = 0; padre[inicio] = -1; cerrado[inicio] = 0;
    monton.meter(inicio, h(inicio) * PESO_H);

    let mejor = inicio, mejorH = h(inicio);
    let expandidos = 0;

    while (!monton.vacio) {
      const act = monton.sacar();
      if (sello[act] !== marca || cerrado[act]) continue;
      cerrado[act] = 1;
      if (act === meta) { this.stats.nodos += expandidos; return meta; }
      if (++expandidos > maxNodos) break;

      const cx = act % A, cz = (act / A) | 0;
      const gAct = g[act];
      const izq = cx > 0, der = cx < A - 1, arr = cz > 0, aba = cz < B - 1;
      // rectos primero: mejor localidad de caché y menos zigzag
      for (let k = 0; k < 8; k++) {
        let nx, nz, diag;
        switch (k) {
          case 0: if (!der) continue; nx = cx + 1; nz = cz; diag = 0; break;
          case 1: if (!izq) continue; nx = cx - 1; nz = cz; diag = 0; break;
          case 2: if (!aba) continue; nx = cx; nz = cz + 1; diag = 0; break;
          case 3: if (!arr) continue; nx = cx; nz = cz - 1; diag = 0; break;
          case 4: if (!der || !aba) continue; nx = cx + 1; nz = cz + 1; diag = 1; break;
          case 5: if (!der || !arr) continue; nx = cx + 1; nz = cz - 1; diag = 1; break;
          case 6: if (!izq || !aba) continue; nx = cx - 1; nz = cz + 1; diag = 1; break;
          default: if (!izq || !arr) continue; nx = cx - 1; nz = cz - 1; diag = 1; break;
        }
        const vec = nz * A + nx;
        if (H[vec] < hol) continue;
        if (diag) {
          // nada de cortar esquinas: la diagonal exige los dos ortogonales libres
          if (H[cz * A + nx] < hol || H[nz * A + cx] < hol) continue;
        }
        const paso = (diag ? RAIZ2 : 1) * costo[vec];
        const ng = gAct + paso;
        if (sello[vec] === marca) {
          if (cerrado[vec] || ng >= g[vec]) continue;
        } else { sello[vec] = marca; cerrado[vec] = 0; }
        g[vec] = ng; padre[vec] = act;
        const hv = h(vec);
        if (hv < mejorH) { mejorH = hv; mejor = vec; }
        monton.meter(vec, ng + hv * PESO_H);
      }
    }
    this.stats.nodos += expandidos;
    // sin camino completo: devolvemos el nodo alcanzable más cercano al destino.
    // Es lo que hace AoE: la unidad camina lo que puede en vez de quedarse dura.
    return mejor === inicio ? -1 : mejor;
  }

  /** Rellena _rutaTmp con las celdas de inicio→final. Devuelve la cantidad. */
  _reconstruir(inicio, final) {
    const padre = this.padre;
    let cant = 0, i = final;
    const tmp = this._rutaTmp;
    while (i !== -1 && cant < tmp.length) { tmp[cant++] = i; if (i === inicio) break; i = padre[i]; }
    // invertir en sitio
    for (let a = 0, b = cant - 1; a < b; a++, b--) { const t = tmp[a]; tmp[a] = tmp[b]; tmp[b] = t; }
    return cant;
  }

  /**
   * String-pulling: avanzamos mientras haya visión directa y sólo guardamos el
   * punto donde se corta. Un camino de 40 celdas termina en 4 o 5 waypoints.
   */
  _suavizar(cant, x0, z0, destX, destZ, hol, capa) {
    const A = this.ancho, tmp = this._rutaTmp;
    const px = (k) => (k === cant - 1 ? destX : this.mundoX(tmp[k] % A));
    const pz = (k) => (k === cant - 1 ? destZ : this.mundoZ((tmp[k] / A) | 0));

    const salida = [];
    let ax = x0, az = z0, k = 0, guardia = 0;
    while (k < cant - 1 && guardia++ < 1024) {
      let mejor = k + 1;
      const tope = Math.min(cant, k + 96);
      for (let j = k + 2; j < tope; j++) {
        if (this._lineaLibre(ax, az, px(j), pz(j), hol, capa)) mejor = j; else break;
      }
      ax = px(mejor); az = pz(mejor);
      salida.push({ x: ax, z: az });
      k = mejor;
    }
    if (!salida.length) salida.push({ x: destX, z: destZ });
    return salida;
  }

  /**
   * Visión directa sobre la rejilla (DDA de Amanatides-Woo). Avanza de a un eje
   * por vez, así que atraviesa todas las celdas que toca el segmento: si dos
   * edificios se tocan en diagonal, la línea NO pasa. Justo lo que queremos.
   */
  _lineaLibre(ax, az, bx, bz, hol, capa) {
    const H = capa === 1 ? this.holguraN : this.holguraT;
    const A = this.ancho, B = this.alto, m = this.mitad, T = TAM_CELDA;
    const fx = (ax + m) / T, fz = (az + m) / T;
    const gx = (bx + m) / T, gz = (bz + m) / T;
    let cx = Math.floor(fx), cz = Math.floor(fz);
    const cxf = Math.floor(gx), czf = Math.floor(gz);
    if (cx < 0 || cz < 0 || cx >= A || cz >= B) return false;
    if (cxf < 0 || czf < 0 || cxf >= A || czf >= B) return false;
    if (H[cz * A + cx] < hol) return false;

    const dx = gx - fx, dz = gz - fz;
    const pasoX = dx > 0 ? 1 : dx < 0 ? -1 : 0;
    const pasoZ = dz > 0 ? 1 : dz < 0 ? -1 : 0;
    const invX = dx !== 0 ? Math.abs(1 / dx) : Infinity;
    const invZ = dz !== 0 ? Math.abs(1 / dz) : Infinity;
    let tX = pasoX > 0 ? (cx + 1 - fx) * invX : pasoX < 0 ? (fx - cx) * invX : Infinity;
    let tZ = pasoZ > 0 ? (cz + 1 - fz) * invZ : pasoZ < 0 ? (fz - cz) * invZ : Infinity;

    let guardia = 0;
    while ((cx !== cxf || cz !== czf) && guardia++ < 2048) {
      if (tX < tZ) { cx += pasoX; tX += invX; } else { cz += pasoZ; tZ += invZ; }
      if (cx < 0 || cz < 0 || cx >= A || cz >= B) return false;
      if (H[cz * A + cx] < hol) return false;
    }
    return true;
  }

  /* ----------------------------- campos de flujo ----------------------------- */
  /**
   * Campo de flujo compartido para grupos grandes (8+ unidades al mismo lugar):
   * un solo Dijkstra hacia atrás desde el destino en vez de N búsquedas A*.
   * Se cachea por celda de destino y caduca a los VIDA_CAMPO segundos o cuando
   * cambia la malla.
   */
  campoFlujo(destinoX, destinoZ, clave, opciones) {
    this._asegurarActualizado();
    const capa = opciones?.capa ?? (opciones?.naval ? 1 : 0);
    const hol = opciones?.holgura ?? this.holguraNecesaria(opciones?.radio ?? 0.5);
    const cx = this.celdaX(destinoX), cz = this.celdaZ(destinoZ);
    const k = clave != null ? `k${clave}` : `${cz * this.ancho + cx}:${capa}:${hol}`;

    const previo = this._campos.get(k);
    // con clave propia hay que verificar además que el destino sea el mismo
    const mismoDestino = previo && Math.abs(previo.cx - cx) <= 1 && Math.abs(previo.cz - cz) <= 1
      && previo.capa === capa && previo.holgura === hol;
    if (previo && mismoDestino && previo.vigente()) return previo;
    if (previo) this._soltarCampo(k, previo);

    const campo = new CampoFlujo(this, cx, cz, capa, hol, opciones?.alcance);
    this._campos.set(k, campo);
    campo.clave = k;
    campo.avanzar(LOTE_FLUJO * 2);                  // ráfaga inicial: los de cerca arrancan ya
    if (!campo.completo) this._camposPendientes.push(campo);
    if (this._campos.size > MAX_CAMPOS) {
      // desalojamos el más viejo
      let vk = null, vt = Infinity;
      for (const [kk, cc] of this._campos) if (cc.creado < vt && cc !== campo) { vt = cc.creado; vk = kk; }
      if (vk != null) this._soltarCampo(vk, this._campos.get(vk));
    }
    this.stats.campos = this._campos.size;
    return campo;
  }

  _soltarCampo(k, campo) {
    this._campos.delete(k);
    if (campo?.integrado && this._poolBuffers.length < MAX_CAMPOS) this._poolBuffers.push(campo.integrado);
    if (campo) campo.integrado = null;
  }

  _tomarBuffer() {
    const b = this._poolBuffers.pop();
    if (b) { b.fill(Infinity); return b; }
    const nb = new Float32Array(this.n);
    nb.fill(Infinity);
    return nb;
  }

  /* --------------------------------- sistema -------------------------------- */
  fijo(dt, ctx) {
    const t0 = performance.now();
    this._asegurarActualizado();

    // 1) campos de flujo: mueven grupos enteros, así que van primero
    this._integrarCampos(t0, PRESUPUESTO_MS * 0.55);

    // 2) pedidos de camino. Se corta ANTES de pasarse: se descuenta el costo
    //    medio de un pedido para no comerse el frame con el último de la tanda.
    const mundo = ctx.mundo;
    while (this._colaIni < this._cola.length
           && (performance.now() - t0) + this._msPorPedido < PRESUPUESTO_MS) {
      const tp = performance.now();
      const id = this._cola[this._colaIni++];
      const p = this._pendientes.get(id);
      if (!p) continue;
      this._pendientes.delete(id);
      if (mundo && !mundo.vivo[id]) continue;
      const radio = (mundo?.radio[id] || 0.5);
      // copia local: no ensuciamos el objeto de opciones del que pidió
      const op = this._op;
      op.capa = p.op?.capa; op.naval = p.op?.naval; op.aereo = p.op?.aereo;
      op.maxNodos = p.op?.maxNodos; op.holgura = p.op?.holgura;
      if (op.capa === undefined && op.naval === undefined && mundo) {
        const def = UNIDADES[mundo.defId[id]];
        if (def?.naval) op.naval = true;
        if (def?.vuela) op.aereo = true;
      }
      let ruta = null;
      try {
        ruta = this.camino(mundo.px[id], mundo.pz[id], p.x1, p.z1, radio, op);
      } catch (e) { ruta = null; console.error('[navegacion] camino', e); }
      if (ruta) this.stats.resueltos++; else this.stats.fallidos++;
      try { p.cb?.(ruta, id); } catch (e) { console.error('[navegacion] callback', e); }
      // media móvil del costo de un pedido (arranca optimista y se corrige sola)
      this._msPorPedido = this._msPorPedido * 0.75 + (performance.now() - tp) * 0.25;
    }
    if (this._colaIni >= this._cola.length) { this._cola.length = 0; this._colaIni = 0; }
    else if (this._colaIni > 256) { this._cola = this._cola.slice(this._colaIni); this._colaIni = 0; }

    // 3) si sobró tiempo, se lo comen los campos de flujo pendientes
    this._integrarCampos(t0, PRESUPUESTO_MS);

    // 4) higiene de caché (una vez por segundo)
    if ((ctx.mundo?.tick | 0) % 20 === 0) {
      for (const [k, c] of this._campos) if (!c.vigente()) this._soltarCampo(k, c);
      this.stats.campos = this._campos.size;
    }
    this.stats.cola = this._cola.length - this._colaIni;
    this.stats.ms = performance.now() - t0;
  }

  _integrarCampos(t0, techo) {
    while (this._camposPendientes.length && (performance.now() - t0) < techo) {
      const c = this._camposPendientes[0];
      if (!c.integrado || c.completo || !c.vigente()) { this._camposPendientes.shift(); continue; }
      c.avanzar(LOTE_FLUJO);
      if (c.completo) this._camposPendientes.shift();
    }
  }

  /* ------------------------------- depuración -------------------------------- */
  /**
   * Malla de depuración: rojo = bloqueado/intransitable, ámbar = celda pegada a
   * un obstáculo (holgura 1). Apagada por defecto: `ctx.nav.debugMalla().visible = true`.
   */
  debugMalla(capa = 0) {
    this._asegurarActualizado();
    if (this._debug) this._reconstruirDebug(this._debug, capa);
    else {
      const grupo = new THREE.Group();
      grupo.name = 'debug-navegacion';
      grupo.visible = false;
      grupo.frustumCulled = false;
      const mat = new THREE.MeshBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.42, depthWrite: false });
      const malla = new THREE.Mesh(new THREE.BufferGeometry(), mat);
      malla.frustumCulled = false;
      grupo.add(malla);
      this._debug = grupo;
      this._reconstruirDebug(grupo, capa);
    }
    return this._debug;
  }

  _reconstruirDebug(grupo, capa) {
    const H = capa === 1 ? this.holguraN : this.holguraT;
    const A = this.ancho, B = this.alto, ter = this.ctx?.terreno;
    const pos = [], col = [], idxs = [];
    const T = TAM_CELDA, MAXQ = 24000;
    let q = 0;
    for (let cz = 0; cz < B && q < MAXQ; cz++) {
      for (let cx = 0; cx < A && q < MAXQ; cx++) {
        const h = H[cz * A + cx];
        if (h > 1) continue;                       // sólo obstáculos y su borde
        const x = this.mundoX(cx), z = this.mundoZ(cz);
        const y = (ter?.altura ? ter.altura(x, z) : 0) + 0.18;
        const b = q * 4, s = T * 0.46;
        pos.push(x - s, y, z - s, x + s, y, z - s, x + s, y, z + s, x - s, y, z + s);
        const r = h === 0 ? 0.92 : 0.95, g = h === 0 ? 0.18 : 0.66, bl = h === 0 ? 0.16 : 0.14;
        for (let v = 0; v < 4; v++) col.push(r, g, bl);
        idxs.push(b, b + 1, b + 2, b, b + 2, b + 3);
        q++;
      }
    }
    const geo = grupo.children[0].geometry;
    geo.dispose();
    const nueva = new THREE.BufferGeometry();
    nueva.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    nueva.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
    nueva.setIndex(idxs);
    grupo.children[0].geometry = nueva;
  }
}

/* ================================ CampoFlujo ================================ */
/**
 * Integración de costos por Dijkstra hacia atrás desde el destino. Se calcula
 * por lotes (`avanzar`) para no comerse el frame: como la ola se expande desde
 * el destino, las unidades cercanas ya tienen dirección en el primer tick y las
 * lejanas la tienen uno o dos ticks después.
 *
 * `direccion()` devuelve SIEMPRE el mismo objeto: copiá dx/dz, no lo guardes.
 */
export class CampoFlujo {
  constructor(nav, dx, dz, capa = 0, holgura = 1, alcance) {
    this.nav = nav;
    this.cx = dx; this.cz = dz;
    this.capa = capa;
    this.holgura = holgura;
    // `alcance` en metros acota la ola: si el grupo está a 120 m no hace falta
    // integrar el mapa entero. Sin él se integra todo lo alcanzable.
    this.limite = alcance > 0 ? (alcance / TAM_CELDA) * COSTO_BASE * 1.7 : Infinity;
    this.destino = { x: nav.mundoX(dx), z: nav.mundoZ(dz) };
    this.version = nav.version;
    this.creado = nav.ctx?.mundo?.tiempo ?? 0;
    this.completo = false;
    this.integrado = nav._tomarBuffer();
    this.monton = new MontonBinario(1 << 12);
    this.expandidos = 0;
    this._dir = { dx: 0, dz: 0 };

    const A = nav.ancho;
    const H = capa === 1 ? nav.holguraN : nav.holguraT;
    let semilla = dz * A + dx;
    if (H[semilla] < holgura) {
      const alt = nav._celdaLibreCerca(dx, dz, holgura, capa, 16, false);
      if (alt < 0) { this.completo = true; return; }
      semilla = alt;
      this.cx = alt % A; this.cz = (alt / A) | 0;
      this.destino = { x: nav.mundoX(this.cx), z: nav.mundoZ(this.cz) };
    }
    this.integrado[semilla] = 0;
    this.monton.meter(semilla, 0);
  }

  vigente() {
    const nav = this.nav;
    if (!this.integrado) return false;
    if (this.version !== nav.version) return false;
    const t = nav.ctx?.mundo?.tiempo ?? 0;
    return (t - this.creado) < VIDA_CAMPO;
  }

  /** Expande hasta `nodos` celdas. Devuelve true si terminó. */
  avanzar(nodos = LOTE_FLUJO) {
    if (this.completo || !this.integrado) return true;
    const nav = this.nav, A = nav.ancho, B = nav.alto;
    const H = this.capa === 1 ? nav.holguraN : nav.holguraT;
    const costo = nav.costo, C = this.integrado, monton = this.monton;
    const hol = this.holgura;
    let n = 0;

    while (!monton.vacio && n < nodos) {
      const act = monton.sacar();
      const gAct = monton.claveSacada;
      if (gAct > C[act]) continue;                  // entrada vieja
      if (gAct > this.limite) { this.completo = true; break; }  // Dijkstra sale en orden: lo que viene está más lejos
      n++;
      const cx = act % A, cz = (act / A) | 0;
      const izq = cx > 0, der = cx < A - 1, arr = cz > 0, aba = cz < B - 1;
      for (let k = 0; k < 8; k++) {
        let nx, nz, diag;
        switch (k) {
          case 0: if (!der) continue; nx = cx + 1; nz = cz; diag = 0; break;
          case 1: if (!izq) continue; nx = cx - 1; nz = cz; diag = 0; break;
          case 2: if (!aba) continue; nx = cx; nz = cz + 1; diag = 0; break;
          case 3: if (!arr) continue; nx = cx; nz = cz - 1; diag = 0; break;
          case 4: if (!der || !aba) continue; nx = cx + 1; nz = cz + 1; diag = 1; break;
          case 5: if (!der || !arr) continue; nx = cx + 1; nz = cz - 1; diag = 1; break;
          case 6: if (!izq || !aba) continue; nx = cx - 1; nz = cz + 1; diag = 1; break;
          default: if (!izq || !arr) continue; nx = cx - 1; nz = cz - 1; diag = 1; break;
        }
        const vec = nz * A + nx;
        if (H[vec] < hol) continue;
        if (diag && (H[cz * A + nx] < hol || H[nz * A + cx] < hol)) continue;
        const ng = gAct + (diag ? RAIZ2 : 1) * costo[vec];
        if (ng < C[vec]) { C[vec] = ng; monton.meter(vec, ng); }
      }
    }
    this.expandidos += n;
    if (this.completo || monton.vacio || this.expandidos > nav.n) { this.completo = true; monton.limpiar(); }
    return this.completo;
  }

  /** Costo integrado hasta el destino (Infinity si todavía no llegó la ola). */
  costoEn(x, z) {
    if (!this.integrado) return Infinity;
    const nav = this.nav;
    return this.integrado[nav.celdaZ(z) * nav.ancho + nav.celdaX(x)];
  }

  listo(x, z) { return this.costoEn(x, z) < Infinity; }

  /**
   * Dirección normalizada hacia el destino. Mezcla el mejor vecino (robusto en
   * pasillos) con el gradiente por diferencias centrales (suave en campo
   * abierto, y repele de los muros porque las celdas bloqueadas cuentan como
   * caras). Si la ola todavía no llegó, devuelve (0,0) y el que llama decide.
   */
  direccion(x, z) {
    const d = this._dir; d.dx = 0; d.dz = 0;
    if (!this.integrado) return d;
    const nav = this.nav, A = nav.ancho, B = nav.alto;
    const C = this.integrado;
    const cx = nav.celdaX(x), cz = nav.celdaZ(z);
    const i = cz * A + cx;
    const c0 = C[i];
    if (!(c0 < Infinity)) return d;
    if (c0 === 0) return d;                          // ya estás en la celda destino

    const val = (px, pz) => {
      if (px < 0 || pz < 0 || px >= A || pz >= B) return c0 + PENAL_MURO;
      const v = C[pz * A + px];
      return v < Infinity ? v : c0 + PENAL_MURO;
    };

    // mejor vecino con regla de esquina
    const H = this.capa === 1 ? nav.holguraN : nav.holguraT;
    let mejorC = c0, mx = 0, mz = 0;
    for (let oz = -1; oz <= 1; oz++) {
      for (let ox = -1; ox <= 1; ox++) {
        if (!ox && !oz) continue;
        const px = cx + ox, pz = cz + oz;
        if (px < 0 || pz < 0 || px >= A || pz >= B) continue;
        if (H[pz * A + px] < this.holgura) continue;
        if (ox && oz && (H[cz * A + px] < this.holgura || H[pz * A + cx] < this.holgura)) continue;
        const v = C[pz * A + px];
        if (v < mejorC) { mejorC = v; mx = ox; mz = oz; }
      }
    }
    // gradiente continuo
    let gx = val(cx - 1, cz) - val(cx + 1, cz);
    let gz = val(cx, cz - 1) - val(cx, cz + 1);
    const lg = Math.hypot(gx, gz);
    if (lg > 1e-4) { gx /= lg; gz /= lg; } else { gx = 0; gz = 0; }
    const lm = Math.hypot(mx, mz);
    if (lm > 0) { mx /= lm; mz /= lm; }

    let rx = mx * 0.6 + gx * 0.4, rz = mz * 0.6 + gz * 0.4;
    const lr = Math.hypot(rx, rz);
    if (lr < 1e-4) { d.dx = mx; d.dz = mz; return d; }
    d.dx = rx / lr; d.dz = rz / lr;
    return d;
  }
}
