/**
 * ECONOMÍA — el corazón del juego.
 *
 * Se ocupa de: recursos por jugador, modificadores (los mastica el árbol
 * tecnológico), población, el ciclo completo de recolección (ir → juntar →
 * depositar → volver), granjas, pesca, construcción con varios obreros,
 * reparación, caravanas de comercio y el mercado.
 *
 * Contrato público (lo dan por sentado los otros módulos):
 *   eco.recursos[jugador] -> { alimento, materiales, capital, energia }
 *   eco.mods[jugador]     -> objeto de modificadores (ver src/data/tecnologias.js)
 *   eco.pob[jugador]      -> { actual, tope }
 *   eco.puedePagar / pagar / reembolsar / sumar
 *   eco.ordenarRecolectar / ordenarConstruir / ordenarReparar / ordenarComerciar
 *   eco.depositoMasCercano / comerciar / estadisticas
 *
 * IMPORTANTE para quien escriba src/sim/Ordenes.js:
 *   antes de mandar a mover o atacar a una unidad, llamá a `eco.cancelar(ids)`
 *   (o emití 'orden:mover' / 'orden:atacar' / 'orden:detener' con {ids}) para que
 *   la economía suelte la tarea y no pelee por el destino de la unidad.
 */

import { CLAVES_RECURSO, IDX_RECURSO, NODOS } from '../data/recursos.js';
import { EDIFICIOS, EDIFICIO_POR_CLAVE } from '../data/edificios.js';
import { UNIDADES } from '../data/unidades.js';
import { TIPO, ESTADO } from '../core/World.js';
import { ORDEN } from '../core/Ctx.js';
import { bus as busGlobal } from '../core/EventBus.js';

/* ------------------------------------------------------------------ *
 * Constantes de balance. Una sola perilla por concepto, a propósito.
 * ------------------------------------------------------------------ */

/** Convierte el `tiempoPorUnidad` de la tabla de nodos en ritmo de juego.
 *  1 / tiempoPorUnidad * ESCALA = recursos por segundo de un colono base. */
const ESCALA_RECOLECCION = 0.35;
const TOPE_POBLACION = 200;
const CANT_GRANJA_BASE = 260;
const MARGEN_TRABAJO = 0.45;      // holgura para considerar "llegué"
const MARGEN_DEPOSITO = 1.0;
const CAPITAL_POR_METRO = 0.08;   // por tramo de ida (el viaje completo paga el doble)
const FRACCION_COSTE_REPARACION = 0.5;
const TICKS_CACHE_DEPOSITO = 100; // 5 s
const RADIO_BUSQUEDA_NODO = 40;
const MAX_JUGADORES = 8;

/** Estados internos de la tarea económica de una unidad. */
const T = {
  NADA: 0,
  IR_NODO: 1, RECOLECTAR: 2, IR_DEPOSITO: 3,
  IR_OBRA: 4, CONSTRUIR: 5,
  IR_REPARAR: 6, REPARAR: 7,
  COMERCIO_IDA: 8, COMERCIO_VUELTA: 9,
};

const ACOPIOS = new Set(['molino', 'aserradero', 'mina']);
const ANGULO_AUREO = 2.39996323;

const sujetar = (v, a, b) => (v < a ? a : v > b ? b : v);

/**
 * Crea el objeto de modificadores COMPLETO y neutro. Los efectos de
 * src/data/tecnologias.js multiplican y suman a ciegas sobre estas claves,
 * y algunos iteran con `for (const k in ...)`, así que ninguna puede faltar.
 */
export function crearModsNeutros() {
  const clases = ['infanteria', 'tirador', 'caballeria', 'asedio', 'apoyo', 'nave', 'aereo', 'aldeano'];
  const conValor = (v, extra) => {
    const o = {};
    for (const c of clases) o[c] = v;
    if (extra) for (const k in extra) o[k] = extra[k];
    return o;
  };
  return {
    velRecoleccion: { alimento: 1, materiales: 1, capital: 1, energia: 1 },
    ataque: conValor(0),
    armadura: conValor(0),
    armaduraPerf: conValor(0),
    vidaExtra: conValor(0),
    velocidad: conValor(1, { comercio: 1 }),
    alcance: conValor(0, { edificio: 0 }),
    vision: conValor(0, { edificio: 0 }),
    cadencia: conValor(1, { edificio: 1 }),

    capacidadCarga: 10,
    velConstruccion: 1,
    velEntrenamiento: 1,
    velEntrenamientoInf: 1,
    velInvestigacion: 1,
    duracionGranja: 1,
    granjaInfinita: false,
    tasaMercado: 0.3,
    bonoComercio: 1,
    velConversion: 1,
    resistenciaConversion: 0,
    multiplicadorCura: 1,
    autorreparacion: 0,
    dispersion: 1,
    autoFoco: false,
    ignoraPendiente: false,
    detectaAereo: false,
    vidaEdificioDefensa: 1,
    descuentoGranja: 1,
    descuentoAcopio: 1,
    descuentoFundicion: 1,
    descuentoAlimentoMilitar: 1,
    descuentoEdad: 1,
    velAstillero: 1,
    capitalPorColono: 0,

    /* extras propios, neutros: los usan los bonos de civilización */
    popExtraVivienda: 0,
    velReparacion: 1,
  };
}

export class Economia {
  constructor(ctx) {
    this.ctx = ctx;
    this.nombre = 'economia';
    this.orden = ORDEN.ECONOMIA;

    const bus = ctx.bus || busGlobal;
    this.bus = bus;

    const cap = ctx.mundo?.cap || 4096;
    this.cap = cap;

    /* ---------------- estado por jugador ---------------- */
    this.recursos = [];
    this.mods = [];
    this.pob = [];
    this.precios = [];          // índice de precio del mercado por recurso
    this.autoReplantar = [];
    this._stats = [];
    this._deudaRep = [];        // fracciones de coste de reparación acumuladas
    this._energiaPasiva = new Float32Array(MAX_JUGADORES);
    this._colonos = new Int32Array(MAX_JUGADORES);
    this._ociosos = new Int32Array(MAX_JUGADORES);
    this._avisoTope = new Float32Array(MAX_JUGADORES);
    this._avisoFalta = new Float32Array(MAX_JUGADORES);
    this._avisoDeposito = new Float32Array(MAX_JUGADORES);
    this.depositos = [];
    this.mercados = [];

    for (let j = 0; j < MAX_JUGADORES; j++) {
      this.recursos.push({ alimento: 350, materiales: 350, capital: 150, energia: 100 });
      this.mods.push(crearModsNeutros());
      this.pob.push({ actual: 0, tope: 0 });
      this.precios.push({ alimento: 1, materiales: 1, capital: 1, energia: 1 });
      this.autoReplantar.push(true);
      this._deudaRep.push(new Float32Array(4));
      this.depositos.push([]);
      this.mercados.push([]);
      this._stats.push({
        recolectado: { alimento: 0, materiales: 0, capital: 0, energia: 0 },
        gastado: { alimento: 0, materiales: 0, capital: 0, energia: 0 },
        tasaPorMinuto: { alimento: 0, materiales: 0, capital: 0, energia: 0 },
        _ventana: new Float32Array(12 * 4),
        _corte: new Float32Array(4),
        _slot: 0,
      });
    }

    /* ---------------- estado por entidad (SoA, cero basura) ---------------- */
    this.tarea = new Uint8Array(cap);
    this.objetivoTrabajo = new Int32Array(cap).fill(-1);
    this.depositoDest = new Int32Array(cap).fill(-1);
    this.recursoTrabajo = new Uint8Array(cap);
    this.memoriaNodo = new Int32Array(cap).fill(-1);
    this.memoriaRecurso = new Uint8Array(cap).fill(255);
    this.mercadoOrigen = new Int32Array(cap).fill(-1);
    this.mercadoDestino = new Int32Array(cap).fill(-1);
    this.distComercio = new Float32Array(cap);
    this._atasco = new Float32Array(cap);
    this._ultX = new Float32Array(cap);
    this._ultZ = new Float32Array(cap);

    /* nodos: cantidad restante con inicialización perezosa */
    this.restante = new Float32Array(cap);
    this._nodoListo = new Uint8Array(cap);

    /* caché depósito-por-nodo (evita pedir caminos al pathfinder cada vez) */
    this._depCache = new Int32Array(cap).fill(-1);
    this._depCacheTick = new Int32Array(cap).fill(-999999);
    this._depCacheJug = new Uint8Array(cap).fill(255);

    /* contadores por obra, reutilizados cada tick */
    this._obreros = new Float32Array(cap);
    this._reparadores = new Float32Array(cap);

    /* buffers reutilizables */
    this._activos = [];
    this._obras = [];
    this._buf = [];
    this._cands = [];
    this._pt = { x: 0, z: 0 };
    this._tick = 0;

    /* limpieza de ranuras recicladas */
    ctx.mundo?.alCrear?.add((id) => this._resetEntidad(id));
    ctx.mundo?.alDestruir?.add((id) => this._alMorir(id));

    /* si Órdenes avisa por el bus, soltamos la tarea sin pelear el destino */
    const soltar = (carga) => {
      const ids = carga?.ids || carga;
      if (ids && typeof ids[Symbol.iterator] === 'function') this.cancelar(ids);
    };
    bus.on('orden:mover', soltar);
    bus.on('orden:atacar', soltar);
    bus.on('orden:detener', soltar);
  }

  /* =================================================================== *
   * Recursos
   * =================================================================== */

  puedePagar(jugador, coste) {
    if (!coste) return true;
    const r = this.recursos[jugador];
    if (!r) return false;
    return (r.alimento >= (coste.alimento || 0) && r.materiales >= (coste.materiales || 0)
      && r.capital >= (coste.capital || 0) && r.energia >= (coste.energia || 0));
  }

  pagar(jugador, coste) {
    if (!coste) return true;
    if (!this.puedePagar(jugador, coste)) {
      this._avisarFalta(jugador, coste);
      return false;
    }
    const r = this.recursos[jugador], g = this._stats[jugador].gastado;
    for (let i = 0; i < 4; i++) {
      const k = CLAVES_RECURSO[i], c = coste[k] || 0;
      if (c) { r[k] -= c; g[k] += c; }
    }
    return true;
  }

  reembolsar(jugador, coste) {
    if (!coste) return;
    const r = this.recursos[jugador], g = this._stats[jugador].gastado;
    for (let i = 0; i < 4; i++) {
      const k = CLAVES_RECURSO[i], c = coste[k] || 0;
      if (c) { r[k] += c; g[k] = Math.max(0, g[k] - c); }
    }
  }

  sumar(jugador, recurso, cantidad) {
    const r = this.recursos[jugador];
    if (!r || !cantidad) return;
    const k = typeof recurso === 'number' ? CLAVES_RECURSO[recurso] : recurso;
    if (r[k] === undefined) return;
    r[k] += cantidad;
    if (cantidad > 0) this._stats[jugador].recolectado[k] += cantidad;
  }

  /** Coste de un edificio con los descuentos de civilización aplicados. */
  costeEdificio(jugador, clave) {
    const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];
    if (!def) return null;
    const m = this.mods[jugador];
    let f = 1;
    if (clave === 'granja') f = m.descuentoGranja;
    else if (ACOPIOS.has(clave)) f = m.descuentoAcopio;
    const c = def.coste;
    return {
      alimento: Math.round((c.alimento || 0) * f),
      materiales: Math.round((c.materiales || 0) * f),
      capital: Math.round((c.capital || 0) * f),
      energia: Math.round((c.energia || 0) * f),
    };
  }

  /** Coste de una unidad con el descuento militar de alimento (soviéticos). */
  costeUnidad(jugador, def) {
    if (typeof def === 'string') def = UNIDADES.find((u) => u.clave === def);
    if (!def) return null;
    const m = this.mods[jugador];
    const militar = def.clase !== 'aldeano';
    const c = def.coste;
    return {
      alimento: Math.round((c.alimento || 0) * (militar ? m.descuentoAlimentoMilitar : 1)),
      materiales: c.materiales || 0,
      capital: c.capital || 0,
      energia: c.energia || 0,
    };
  }

  estadisticas(jugador) { return this._stats[jugador]; }
  colonosOciosos(jugador) { return this._ociosos[jugador] | 0; }
  setAutoReplantar(jugador, v) { this.autoReplantar[jugador] = !!v; }

  /* =================================================================== *
   * Órdenes públicas
   * =================================================================== */

  /** Manda a recolectar. `nodoId` puede ser un nodo del mapa, una granja o un mercado. */
  ordenarRecolectar(ids, nodoId) {
    const m = this.ctx.mundo;
    if (!m || !m.vivo[nodoId]) return 0;
    let n = 0;
    for (const id of ids) {
      if (!m.vivo[id] || m.tipo[id] !== TIPO.UNIDAD) continue;
      const def = UNIDADES[m.defId[id]];
      if (!def) continue;
      if (def.linea === 'comercio') {
        if (this._asignarComercio(id, nodoId)) n++;
        continue;
      }
      if (def.clase !== 'aldeano' && def.clave !== 'pesquero') continue;
      if (!this._nodoCosechable(nodoId, m.jugador[id], def)) continue;
      this._iniciarRecoleccion(id, nodoId);
      n++;
    }
    if (n) {
      this.ctx.audio?.sfx?.('orden_trabajar', { x: m.px[nodoId], z: m.pz[nodoId] });
      this.bus.emit('economia:tarea', { tipo: 'recolectar', nodo: nodoId, cantidad: n });
    }
    return n;
  }

  /** Manda a construir/terminar una obra ya emplazada. */
  ordenarConstruir(ids, edificioId) {
    const m = this.ctx.mundo;
    if (!m || !m.vivo[edificioId] || m.tipo[edificioId] !== TIPO.EDIFICIO) return 0;
    let n = 0;
    for (const id of ids) {
      if (!m.vivo[id] || m.tipo[id] !== TIPO.UNIDAD) continue;
      const def = UNIDADES[m.defId[id]];
      if (!def || def.clase !== 'aldeano') continue;
      if (m.jugador[id] !== m.jugador[edificioId]) continue;
      if (m.estado[edificioId] !== ESTADO.CONSTRUYENDO && m.vida[edificioId] >= m.vidaMax[edificioId]) continue;
      this._limpiar(id);
      this.tarea[id] = m.estado[edificioId] === ESTADO.CONSTRUYENDO ? T.IR_OBRA : T.IR_REPARAR;
      this.objetivoTrabajo[id] = edificioId;
      n++;
    }
    if (n) this.ctx.audio?.sfx?.('orden_construir', { x: m.px[edificioId], z: m.pz[edificioId] });
    return n;
  }

  /** Manda a reparar un edificio (o nave) dañado. */
  ordenarReparar(ids, edificioId) {
    const m = this.ctx.mundo;
    if (!m || !m.vivo[edificioId]) return 0;
    let n = 0;
    for (const id of ids) {
      if (!m.vivo[id] || m.tipo[id] !== TIPO.UNIDAD) continue;
      const def = UNIDADES[m.defId[id]];
      if (!def || def.clase !== 'aldeano') continue;
      this._limpiar(id);
      this.tarea[id] = m.estado[edificioId] === ESTADO.CONSTRUYENDO ? T.IR_OBRA : T.IR_REPARAR;
      this.objetivoTrabajo[id] = edificioId;
      n++;
    }
    return n;
  }

  /** Manda caravanas a comerciar contra un mercado concreto (o el mejor disponible). */
  ordenarComerciar(ids, mercadoId = -1) {
    let n = 0;
    for (const id of ids) if (this._asignarComercio(id, mercadoId)) n++;
    return n;
  }

  /** Suelta la tarea económica: la llama Órdenes antes de mover/atacar. */
  cancelar(ids) {
    if (typeof ids === 'number') { this._limpiar(ids); return; }
    for (const id of ids) this._limpiar(id);
  }

  /** Emplaza una obra nueva y cobra el coste. Devuelve el id o -1. */
  crearObra(jugador, claveEdificio, x, z, rot = 0) {
    const m = this.ctx.mundo;
    const idx = EDIFICIO_POR_CLAVE.get(claveEdificio);
    if (idx === undefined || !m) return -1;
    const def = EDIFICIOS[idx];
    const coste = this.costeEdificio(jugador, claveEdificio);
    if (!this.pagar(jugador, coste)) return -1;
    const id = m.crear(TIPO.EDIFICIO, idx, x, z, jugador);
    m.py[id] = this.ctx.terreno?.altura?.(x, z) ?? 0;
    m.rot[id] = rot; m.rotObjetivo[id] = rot;
    m.vidaMax[id] = def.vida * ((def.muro || def.ataque) ? this.mods[jugador].vidaEdificioDefensa : 1);
    m.vida[id] = Math.max(1, m.vidaMax[id] * 0.05);
    m.radio[id] = Math.max(def.celdas[0], def.celdas[1]);
    m.estado[id] = ESTADO.CONSTRUYENDO;
    m.progreso[id] = 0;
    this.ctx.nav?.bloquear?.(x, z, def.celdas[0] * 2, def.celdas[1] * 2, 1);
    this.bus.emit('obra:iniciada', { id, jugador, clave: claveEdificio });
    return id;
  }

  /* =================================================================== *
   * Mercado
   * =================================================================== */

  /**
   * Mercado con tasa que se degrada al usarla: vender hunde el precio del
   * recurso, comprar lo empuja para arriba. `vende`/`compra` son claves.
   * Devuelve la cantidad efectivamente obtenida de `compra`.
   */
  comerciar(jugador, vende, compra, cantidad = 100) {
    if (vende === compra || !cantidad || cantidad <= 0) return 0;
    const r = this.recursos[jugador];
    const p = this.precios[jugador];
    if (!r || r[vende] === undefined || r[compra] === undefined) return 0;
    if (!this.mercados[jugador].length) {
      this._aviso(jugador, 'Necesitás un Mercado para comerciar.', 'alerta');
      return 0;
    }
    const comision = Math.max(0, this.mods[jugador].tasaMercado || 0);
    const mover = (k, dir) => { p[k] = sujetar(p[k] * (1 + dir * 0.03 * (cantidad / 100)), 0.25, 5); };

    let obtenido = 0;
    if (compra === 'capital') {
      if (r[vende] < cantidad) return 0;
      obtenido = cantidad * p[vende] * (1 - comision);
      r[vende] -= cantidad; r.capital += obtenido;
      mover(vende, -1);
    } else if (vende === 'capital') {
      const coste = cantidad * p[compra] * (1 + comision);
      if (r.capital < coste) return 0;
      r.capital -= coste; r[compra] += cantidad;
      obtenido = cantidad;
      mover(compra, +1);
    } else {
      if (r[vende] < cantidad) return 0;
      const bruto = cantidad * p[vende] * (1 - comision);
      obtenido = bruto / (p[compra] * (1 + comision));
      r[vende] -= cantidad; r[compra] += obtenido;
      mover(vende, -1); mover(compra, +1);
    }
    obtenido = Math.floor(obtenido * 10) / 10;
    this._stats[jugador].recolectado[compra] += obtenido;
    this.ctx.audio?.sfx?.('moneda');
    this.bus.emit('mercado:operacion', { jugador, vende, compra, cantidad, obtenido });
    return obtenido;
  }

  /** Precio actual (unidades de Capital por unidad de recurso). */
  precio(jugador, recurso, comprando = true) {
    const comision = Math.max(0, this.mods[jugador].tasaMercado || 0);
    return this.precios[jugador][recurso] * (comprando ? 1 + comision : 1 - comision);
  }

  /* =================================================================== *
   * Depósitos
   * =================================================================== */

  /**
   * Depósito más cercano que acepte `recurso`. Prefiltra por distancia al borde
   * y desempata con el largo REAL del camino (si hay navegación disponible).
   */
  depositoMasCercano(jugador, x, z, recurso) {
    const lista = this.depositos[jugador];
    if (!lista || !lista.length) return -1;
    const m = this.ctx.mundo;

    /* los tres mejores por distancia al borde (prefiltro barato) */
    let a1 = -1, a2 = -1, a3 = -1;
    let d1 = Infinity, d2 = Infinity, d3 = Infinity;
    for (let i = 0; i < lista.length; i++) {
      const e = lista[i];
      if (!m.vivo[e]) continue;
      const def = EDIFICIOS[m.defId[e]];
      if (!def.deposito || def.deposito.indexOf(recurso) < 0) continue;
      const d = this._distBorde(x, z, e);
      if (d < d1) { a3 = a2; d3 = d2; a2 = a1; d2 = d1; a1 = e; d1 = d; }
      else if (d < d2) { a3 = a2; d3 = d2; a2 = e; d2 = d; }
      else if (d < d3) { a3 = e; d3 = d; }
    }
    if (a1 < 0) return -1;
    if (a2 < 0 || typeof this.ctx.nav?.camino !== 'function') return a1;

    /* desempate con el largo REAL del camino: un aserradero detrás del cerro
       está "cerca" en línea recta y lejísimos en la práctica */
    const cands = this._cands; cands.length = 0;
    cands.push(a1, d1); if (a2 >= 0) cands.push(a2, d2); if (a3 >= 0) cands.push(a3, d3);
    let mejor = a1, mejorL = Infinity;
    for (let i = 0; i < cands.length; i += 2) {
      const e = cands[i];
      const p = this._puntoBorde(e, x, z, MARGEN_DEPOSITO, e);
      const L = this._largoCamino(x, z, p.x, p.z);
      const val = Number.isFinite(L) ? L : cands[i + 1] * 3;
      if (val < mejorL) { mejorL = val; mejor = e; }
    }
    return mejor;
  }

  /* =================================================================== *
   * Bucle de simulación (20 Hz)
   * =================================================================== */

  fijo(dt, ctx) {
    const m = ctx.mundo;
    if (!m) return;
    this._tick++;

    const activos = this._activos; activos.length = 0;
    const obras = this._obras; obras.length = 0;
    const pob = this.pob;

    for (let j = 0; j < MAX_JUGADORES; j++) {
      pob[j].actual = 0; pob[j].tope = 0;
      this.depositos[j].length = 0;
      this.mercados[j].length = 0;
      this._energiaPasiva[j] = 0;
      this._colonos[j] = 0;
      this._ociosos[j] = 0;
    }

    /* ---- una sola pasada por el mundo: población, depósitos, obras ---- */
    const n = m.maxUsado;
    for (let id = 0; id < n; id++) {
      if (!m.vivo[id]) continue;
      const j = m.jugador[id];
      if (j >= MAX_JUGADORES) continue;
      const t = m.tipo[id];

      if (t === TIPO.UNIDAD) {
        const def = UNIDADES[m.defId[id]];
        if (!def) continue;
        pob[j].actual += def.pop || 1;
        if (def.clase === 'aldeano') {
          this._colonos[j]++;
          if (!this.tarea[id] && !m.tieneDestino[id] && m.estado[id] !== ESTADO.ATACANDO) this._ociosos[j]++;
        }
        if (this.tarea[id]) activos.push(id);
      } else if (t === TIPO.EDIFICIO) {
        const def = EDIFICIOS[m.defId[id]];
        if (!def) continue;
        if (m.estado[id] === ESTADO.CONSTRUYENDO) { obras.push(id); continue; }
        if (def.pop) pob[j].tope += def.pop + (def.clave === 'vivienda' ? this.mods[j].popExtraVivienda : 0);
        if (def.deposito) this.depositos[j].push(id);
        if (def.comercio) this.mercados[j].push(id);
        if (def.generaEnergia) this._energiaPasiva[j] += def.generaEnergia;
        const auto = this.mods[j].autorreparacion;
        if (auto > 0 && m.vida[id] < m.vidaMax[id]) {
          m.vida[id] = Math.min(m.vidaMax[id], m.vida[id] + auto * dt);
        }
      }
    }

    for (let j = 0; j < MAX_JUGADORES; j++) {
      if (pob[j].tope > TOPE_POBLACION) pob[j].tope = TOPE_POBLACION;
      /* energía de las centrales y capital pasivo (bono indio) */
      if (this._energiaPasiva[j]) this.sumar(j, 'energia', this._energiaPasiva[j] * dt);
      const cpc = this.mods[j].capitalPorColono;
      if (cpc) this.sumar(j, 'capital', (cpc * this._colonos[j] / 60) * dt);
      /* aviso de tope de población */
      this._avisoTope[j] -= dt;
      if (pob[j].actual >= pob[j].tope && pob[j].tope > 0 && this._avisoTope[j] <= 0) {
        this._avisoTope[j] = 15;
        this.bus.emit('poblacion:tope', { jugador: j, tope: pob[j].tope });
        if (j === ctx.jugadorLocal) {
          this._aviso(j, 'Llegaste al tope de población: construí Viviendas.', 'alerta');
          ctx.audio?.sfx?.('tope_poblacion');
        }
      }
      this._avisoFalta[j] -= dt;
      this._avisoDeposito[j] -= dt;
    }

    /* ---- tareas de las unidades ---- */
    for (let i = 0; i < activos.length; i++) this._paso(activos[i], dt, ctx);

    /* ---- obras: rendimiento decreciente por raíz cuadrada ---- */
    for (let i = 0; i < obras.length; i++) this._pasoObra(obras[i], dt, ctx);

    /* ---- reparaciones acumuladas este tick ---- */
    if (this._hayReparaciones) this._aplicarReparaciones(dt);

    /* ---- estadísticas por minuto (ventana móvil de 60 s) ---- */
    if (this._tick % 100 === 0) this._muestrearStats();
  }

  /* =================================================================== *
   * Máquina de estados de la unidad
   * =================================================================== */

  _paso(id, dt, ctx) {
    const m = ctx.mundo;
    /* si Combate se apoderó de la unidad, la economía espera sin pelear */
    if (m.estado[id] === ESTADO.ATACANDO) return;

    switch (this.tarea[id]) {
      case T.IR_NODO: this._irNodo(id, dt, ctx); break;
      case T.RECOLECTAR: this._recolectar(id, dt, ctx); break;
      case T.IR_DEPOSITO: this._irDeposito(id, dt, ctx); break;
      case T.IR_OBRA: this._irObra(id, dt, ctx); break;
      case T.CONSTRUIR: this._construir(id, dt, ctx); break;
      case T.IR_REPARAR: this._irReparar(id, dt, ctx); break;
      case T.REPARAR: this._reparar(id, dt, ctx); break;
      case T.COMERCIO_IDA:
      case T.COMERCIO_VUELTA: this._comercio(id, dt, ctx); break;
      default: this.tarea[id] = T.NADA;
    }
  }

  /* -------- recolección -------- */

  _irNodo(id, dt, ctx) {
    const m = ctx.mundo;
    const nodo = this.objetivoTrabajo[id];
    if (!this._nodoVivo(nodo)) { this._buscarOtroNodo(id, ctx); return; }
    const rango = this._rangoNodo(id, nodo);
    if (this._distObjetivo(id, nodo) <= rango + MARGEN_TRABAJO) {
      this._detener(id);
      this.tarea[id] = T.RECOLECTAR;
      m.estado[id] = ESTADO.RECOLECTANDO;
      m.rotObjetivo[id] = Math.atan2(m.pz[nodo] - m.pz[id], m.px[nodo] - m.px[id]);
      return;
    }
    const p = this._puntoAcercamiento(id, nodo, rango);
    this._caminarHacia(id, p.x, p.z, dt);
  }

  _recolectar(id, dt, ctx) {
    const m = ctx.mundo;
    const nodo = this.objetivoTrabajo[id];
    if (!this._nodoVivo(nodo)) { this._buscarOtroNodo(id, ctx); return; }
    const rango = this._rangoNodo(id, nodo);
    if (this._distObjetivo(id, nodo) > rango + MARGEN_TRABAJO * 2.5) { this.tarea[id] = T.IR_NODO; return; }

    const j = m.jugador[id];
    const mods = this.mods[j];
    const clave = CLAVES_RECURSO[this.recursoTrabajo[id]];
    const tpu = this._tiempoPorUnidad(nodo);
    const cap = this._capacidad(id, mods);
    const tasa = (1 / tpu) * ESCALA_RECOLECCION * (mods.velRecoleccion[clave] || 1);

    let disponible = this._restanteDe(nodo, j);
    let cant = Math.min(tasa * dt, cap - m.cargaCant[id], disponible);
    if (cant > 0) {
      m.cargaTipo[id] = this.recursoTrabajo[id];
      m.cargaCant[id] += cant;
      this.restante[nodo] = disponible - cant;
      if (m.tipo[nodo] === TIPO.RECURSO) m.vida[nodo] = this.restante[nodo];
      m.estado[id] = ESTADO.RECOLECTANDO;
      m.animFase[id] += dt * 6;
    }

    if (this.restante[nodo] <= 0.001) { this._agotarNodo(nodo, ctx); }
    if (m.cargaCant[id] >= cap - 0.001) this._mandarADepositar(id, ctx);
  }

  _mandarADepositar(id, ctx) {
    const m = ctx.mundo;
    const j = m.jugador[id];
    const clave = CLAVES_RECURSO[m.cargaTipo[id]];
    const nodo = this.objetivoTrabajo[id];
    let dep = -1;

    /* caché por nodo: todos los que trabajan la misma veta comparten el mismo destino */
    if (this._nodoVivo(nodo) && this._depCacheJug[nodo] === j
      && this._tick - this._depCacheTick[nodo] < TICKS_CACHE_DEPOSITO
      && m.vivo[this._depCache[nodo]] && m.estado[this._depCache[nodo]] !== ESTADO.CONSTRUYENDO) {
      dep = this._depCache[nodo];
    } else {
      const ox = this._nodoVivo(nodo) ? m.px[nodo] : m.px[id];
      const oz = this._nodoVivo(nodo) ? m.pz[nodo] : m.pz[id];
      dep = this.depositoMasCercano(j, ox, oz, clave);
      if (this._nodoVivo(nodo) && dep >= 0) {
        this._depCache[nodo] = dep; this._depCacheTick[nodo] = this._tick; this._depCacheJug[nodo] = j;
      }
    }
    if (dep < 0) {
      /* sin depósito: sigue juntando pero avisa cada tanto, no cada tick */
      if (this._avisoDeposito[j] <= 0) {
        this._avisoDeposito[j] = 12;
        this._aviso(j, 'No hay dónde depositar: construí un punto de acopio.', 'alerta');
      }
      this.tarea[id] = T.RECOLECTAR;
      return;
    }
    this.depositoDest[id] = dep;
    this.tarea[id] = T.IR_DEPOSITO;
    this._atasco[id] = 0;
  }

  _irDeposito(id, dt, ctx) {
    const m = ctx.mundo;
    let dep = this.depositoDest[id];
    if (!m.vivo[dep] || m.tipo[dep] !== TIPO.EDIFICIO || m.estado[dep] === ESTADO.CONSTRUYENDO) {
      const clave = CLAVES_RECURSO[m.cargaTipo[id]];
      dep = this.depositoMasCercano(m.jugador[id], m.px[id], m.pz[id], clave);
      if (dep < 0) { this.tarea[id] = this._nodoVivo(this.objetivoTrabajo[id]) ? T.IR_NODO : T.NADA; return; }
      this.depositoDest[id] = dep;
    }
    const rango = (m.radio[id] || 0.45) + MARGEN_DEPOSITO;
    if (this._distBorde(m.px[id], m.pz[id], dep) <= rango) {
      this._depositar(id, ctx);
      return;
    }
    const p = this._puntoBorde(dep, m.px[id], m.pz[id], MARGEN_DEPOSITO * 0.8, id);
    this._caminarHacia(id, p.x, p.z, dt);
  }

  _depositar(id, ctx) {
    const m = ctx.mundo;
    const j = m.jugador[id];
    const cant = m.cargaCant[id];
    if (cant > 0) {
      const clave = CLAVES_RECURSO[m.cargaTipo[id]];
      this.sumar(j, clave, cant);
      this.bus.emit('recurso:depositado', { jugador: j, recurso: clave, cantidad: cant });
      ctx.audio?.sfx?.('deposito', { x: m.px[id], z: m.pz[id], volumen: 0.4 });
      m.cargaCant[id] = 0;
    }
    m.estado[id] = ESTADO.DEPOSITANDO;
    const nodo = this.objetivoTrabajo[id];
    if (this._nodoVivo(nodo)) { this.tarea[id] = T.IR_NODO; }
    else this._buscarOtroNodo(id, ctx);
    this._atasco[id] = 0;
  }

  /* -------- construcción -------- */

  _irObra(id, dt, ctx) {
    const m = ctx.mundo;
    const obra = this.objetivoTrabajo[id];
    if (!m.vivo[obra] || m.tipo[obra] !== TIPO.EDIFICIO) { this._terminarTarea(id, ctx); return; }
    if (m.estado[obra] !== ESTADO.CONSTRUYENDO) { this.tarea[id] = T.IR_REPARAR; return; }
    const rango = (m.radio[id] || 0.45) + MARGEN_DEPOSITO;
    if (this._distBorde(m.px[id], m.pz[id], obra) <= rango) {
      this._detener(id);
      this.tarea[id] = T.CONSTRUIR;
      m.estado[id] = ESTADO.CONSTRUYENDO;
      m.rotObjetivo[id] = Math.atan2(m.pz[obra] - m.pz[id], m.px[obra] - m.px[id]);
      return;
    }
    const p = this._puntoBorde(obra, m.px[id], m.pz[id], MARGEN_DEPOSITO * 0.7, id);
    this._caminarHacia(id, p.x, p.z, dt);
  }

  _construir(id, dt, ctx) {
    const m = ctx.mundo;
    const obra = this.objetivoTrabajo[id];
    if (!m.vivo[obra] || m.estado[obra] !== ESTADO.CONSTRUYENDO) { this._alTerminarObra(id, obra, ctx); return; }
    const rango = (m.radio[id] || 0.45) + MARGEN_DEPOSITO * 1.6;
    if (this._distBorde(m.px[id], m.pz[id], obra) > rango) { this.tarea[id] = T.IR_OBRA; return; }
    this._obreros[obra] += 1;
    m.estado[id] = ESTADO.CONSTRUYENDO;
    m.animFase[id] += dt * 7;
  }

  _pasoObra(obra, dt, ctx) {
    const m = ctx.mundo;
    const nObreros = this._obreros[obra];
    this._obreros[obra] = 0;
    if (nObreros <= 0) return;
    const def = EDIFICIOS[m.defId[obra]];
    const j = m.jugador[obra];
    const mods = this.mods[j];
    const vel = Math.sqrt(nObreros) * (mods.velConstruccion || 1);
    const antes = m.progreso[obra];
    let p = antes + (dt * vel) / Math.max(1, def.tiempo);
    if (p >= 1) {
      m.progreso[obra] = 1;
      m.vida[obra] = m.vidaMax[obra] || def.vida;
      m.estado[obra] = ESTADO.QUIETO;
      this.bus.emit('edificio:terminado', { id: obra, jugador: j, clave: def.clave });
      this.bus.emit('entidad:creada', obra);
      ctx.audio?.sfx?.('edificio_listo', { x: m.px[obra], z: m.pz[obra] });
      ctx.efectos?.polvo?.(m.px[obra], m.py[obra], m.pz[obra], 14);
      if (j === ctx.jugadorLocal) this._aviso(j, `${def.nombre} en pie.`, 'info');
      if (def.recursoInfinito) this._sembrarGranja(obra, j);
      this._depCacheTick.fill(-999999);
    } else {
      m.progreso[obra] = p;
      m.vida[obra] = Math.max(1, (m.vidaMax[obra] || def.vida) * (0.05 + 0.95 * p));
      if (this._tick % 6 === 0) ctx.efectos?.polvo?.(m.px[obra], m.py[obra], m.pz[obra], 2);
    }
  }

  /** El obrero que termina una obra sigue trabajando solo, como en AoE2. */
  _alTerminarObra(id, obra, ctx) {
    const m = ctx.mundo;
    if (m.vivo[obra]) {
      const def = EDIFICIOS[m.defId[obra]];
      if (def?.recursoInfinito) { this._iniciarRecoleccion(id, obra); return; }
    }
    this._terminarTarea(id, ctx);
  }

  /* -------- reparación -------- */

  _irReparar(id, dt, ctx) {
    const m = ctx.mundo;
    const obj = this.objetivoTrabajo[id];
    if (!m.vivo[obj] || m.vida[obj] >= m.vidaMax[obj]) { this._terminarTarea(id, ctx); return; }
    const rango = (m.radio[id] || 0.45) + MARGEN_DEPOSITO;
    if (this._distBorde(m.px[id], m.pz[id], obj) <= rango) {
      this._detener(id);
      this.tarea[id] = T.REPARAR;
      m.estado[id] = ESTADO.REPARANDO;
      return;
    }
    const p = this._puntoBorde(obj, m.px[id], m.pz[id], MARGEN_DEPOSITO * 0.7, id);
    this._caminarHacia(id, p.x, p.z, dt);
  }

  _reparar(id, dt, ctx) {
    const m = ctx.mundo;
    const obj = this.objetivoTrabajo[id];
    if (!m.vivo[obj] || m.vida[obj] >= m.vidaMax[obj]) { this._terminarTarea(id, ctx); return; }
    const rango = (m.radio[id] || 0.45) + MARGEN_DEPOSITO * 1.6;
    if (this._distBorde(m.px[id], m.pz[id], obj) > rango) { this.tarea[id] = T.IR_REPARAR; return; }
    this._reparadores[obj] += 1;
    this._hayReparaciones = true;
    m.estado[id] = ESTADO.REPARANDO;
    m.animFase[id] += dt * 7;
  }

  _aplicarReparaciones(dt) {
    const m = this.ctx.mundo;
    this._hayReparaciones = false;
    const n = m.maxUsado;
    for (let e = 0; e < n; e++) {
      const nRep = this._reparadores[e];
      if (nRep <= 0) continue;
      this._reparadores[e] = 0;
      if (!m.vivo[e]) continue;
      const j = m.jugador[e];
      const esEdificio = m.tipo[e] === TIPO.EDIFICIO;
      const def = esEdificio ? EDIFICIOS[m.defId[e]] : UNIDADES[m.defId[e]];
      if (!def) continue;
      const mods = this.mods[j];
      const base = (m.vidaMax[e] || def.vida) / Math.max(1, def.tiempo);
      const cura = base * Math.sqrt(nRep) * (mods.velConstruccion || 1) * (mods.velReparacion || 1) * dt;
      const real = Math.min(cura, m.vidaMax[e] - m.vida[e]);
      if (real <= 0) continue;
      if (!this._cobrarReparacion(j, def, real / Math.max(1, m.vidaMax[e]))) continue;
      m.vida[e] += real;
      if (m.vida[e] >= m.vidaMax[e]) {
        m.vida[e] = m.vidaMax[e];
        this.bus.emit('edificio:reparado', { id: e, jugador: j });
      }
    }
  }

  /** Cobra la fracción proporcional del coste del edificio (mitad de precio). */
  _cobrarReparacion(jugador, def, fraccion) {
    const deuda = this._deudaRep[jugador];
    const r = this.recursos[jugador];
    for (let i = 0; i < 4; i++) {
      const k = CLAVES_RECURSO[i];
      deuda[i] += (def.coste?.[k] || 0) * FRACCION_COSTE_REPARACION * fraccion;
      if (deuda[i] >= 1) {
        const paga = Math.floor(deuda[i]);
        if (r[k] < paga) { this._avisarFalta(jugador, null, k); return false; }
        r[k] -= paga; deuda[i] -= paga;
        this._stats[jugador].gastado[k] += paga;
      }
    }
    return true;
  }

  /* -------- comercio -------- */

  _asignarComercio(id, mercadoId) {
    const m = this.ctx.mundo;
    if (!m.vivo[id] || m.tipo[id] !== TIPO.UNIDAD) return false;
    const def = UNIDADES[m.defId[id]];
    if (!def || def.linea !== 'comercio') return false;
    const j = m.jugador[id];

    let destino = mercadoId;
    if (destino < 0 || !this._mercadoValido(destino, j, true)) destino = this._mercadoExtranjero(j, m.px[id], m.pz[id]);
    if (destino < 0) {
      this._aviso(j, 'No hay mercado ajeno con el cual comerciar.', 'alerta');
      return false;
    }
    const origen = this._mercadoPropio(j, m.px[destino], m.pz[destino]);
    if (origen < 0) { this._aviso(j, 'Necesitás tu propio Mercado.', 'alerta'); return false; }

    this._limpiar(id);
    this.mercadoOrigen[id] = origen;
    this.mercadoDestino[id] = destino;
    this.distComercio[id] = Math.hypot(m.px[destino] - m.px[origen], m.pz[destino] - m.pz[origen]);
    this.tarea[id] = T.COMERCIO_IDA;
    m.velocidad[id] = (def.velocidad || 4.6) * (this.mods[j].velocidad.comercio || 1);
    return true;
  }

  _comercio(id, dt, ctx) {
    const m = ctx.mundo;
    const j = m.jugador[id];
    const yendo = this.tarea[id] === T.COMERCIO_IDA;
    let meta = yendo ? this.mercadoDestino[id] : this.mercadoOrigen[id];

    if (!this._mercadoValido(meta, j, yendo)) {
      meta = yendo ? this._mercadoExtranjero(j, m.px[id], m.pz[id]) : this._mercadoPropio(j, m.px[id], m.pz[id]);
      if (meta < 0) { this.tarea[id] = T.NADA; return; }
      if (yendo) this.mercadoDestino[id] = meta; else this.mercadoOrigen[id] = meta;
      this.distComercio[id] = Math.hypot(m.px[this.mercadoDestino[id]] - m.px[this.mercadoOrigen[id]],
        m.pz[this.mercadoDestino[id]] - m.pz[this.mercadoOrigen[id]]);
    }

    const rango = (m.radio[id] || 0.45) + MARGEN_DEPOSITO;
    if (this._distBorde(m.px[id], m.pz[id], meta) <= rango) {
      if (yendo) {
        m.cargaTipo[id] = IDX_RECURSO.capital;
        m.cargaCant[id] = this.distComercio[id] * CAPITAL_POR_METRO * (this.mods[j].bonoComercio || 1);
        this.tarea[id] = T.COMERCIO_VUELTA;
      } else {
        const ganancia = m.cargaCant[id] + this.distComercio[id] * CAPITAL_POR_METRO * (this.mods[j].bonoComercio || 1);
        m.cargaCant[id] = 0;
        this.sumar(j, 'capital', ganancia);
        this.bus.emit('recurso:depositado', { jugador: j, recurso: 'capital', cantidad: ganancia });
        ctx.audio?.sfx?.('moneda', { x: m.px[id], z: m.pz[id], volumen: 0.35 });
        this.tarea[id] = T.COMERCIO_IDA;
      }
      this._detener(id);
      this._atasco[id] = 0;
      return;
    }
    const p = this._puntoBorde(meta, m.px[id], m.pz[id], MARGEN_DEPOSITO * 0.8, id);
    this._caminarHacia(id, p.x, p.z, dt);
  }

  _mercadoValido(e, jugador, ajeno) {
    const m = this.ctx.mundo;
    if (e < 0 || !m.vivo[e] || m.tipo[e] !== TIPO.EDIFICIO) return false;
    if (m.estado[e] === ESTADO.CONSTRUYENDO) return false;
    const def = EDIFICIOS[m.defId[e]];
    if (!def?.comercio) return false;
    return ajeno ? m.jugador[e] !== jugador : m.jugador[e] === jugador;
  }

  _mercadoExtranjero(jugador, x, z) {
    let mejor = -1, mejorD = Infinity;
    for (let j = 0; j < MAX_JUGADORES; j++) {
      if (j === jugador) continue;
      const lista = this.mercados[j];
      for (let i = 0; i < lista.length; i++) {
        const d = this._distBorde(x, z, lista[i]);
        if (d < mejorD) { mejorD = d; mejor = lista[i]; }
      }
    }
    return mejor;
  }

  _mercadoPropio(jugador, x, z) {
    const lista = this.mercados[jugador];
    let mejor = -1, mejorD = Infinity;
    for (let i = 0; i < lista.length; i++) {
      const d = this._distBorde(x, z, lista[i]);
      if (d < mejorD) { mejorD = d; mejor = lista[i]; }
    }
    return mejor;
  }

  /* =================================================================== *
   * Nodos: validez, agotamiento, granjas, búsqueda del más cercano
   * =================================================================== */

  _iniciarRecoleccion(id, nodo) {
    const m = this.ctx.mundo;
    const rec = this._recursoDeNodo(nodo);
    if (rec < 0) return;
    this._limpiar(id);
    if (m.cargaCant[id] > 0 && m.cargaTipo[id] !== rec) m.cargaCant[id] = 0;
    this.tarea[id] = m.cargaCant[id] >= this._capacidad(id, this.mods[m.jugador[id]]) ? T.IR_DEPOSITO : T.IR_NODO;
    this.objetivoTrabajo[id] = nodo;
    this.recursoTrabajo[id] = rec;
    this.memoriaNodo[id] = nodo;
    this.memoriaRecurso[id] = rec;
    this._restanteDe(nodo, m.jugador[id]);
  }

  _nodoVivo(nodo) {
    const m = this.ctx.mundo;
    if (nodo < 0 || !m.vivo[nodo]) return false;
    if (m.tipo[nodo] === TIPO.RECURSO) return this.restante[nodo] > 0.001 || !this._nodoListo[nodo];
    if (m.tipo[nodo] === TIPO.EDIFICIO) {
      const def = EDIFICIOS[m.defId[nodo]];
      return !!def?.recursoInfinito && m.estado[nodo] !== ESTADO.CONSTRUYENDO;
    }
    return false;
  }

  _nodoCosechable(nodo, jugador, defUnidad) {
    const m = this.ctx.mundo;
    if (m.tipo[nodo] === TIPO.RECURSO) {
      const def = NODOS[m.defId[nodo]];
      if (!def || def.reliquia) return false;
      const enAgua = !!def.agua;
      if (defUnidad.naval && !enAgua) return false;
      if (!defUnidad.naval && enAgua) return false;
      return true;
    }
    if (m.tipo[nodo] === TIPO.EDIFICIO) {
      const def = EDIFICIOS[m.defId[nodo]];
      return !!def?.recursoInfinito && m.jugador[nodo] === jugador && m.estado[nodo] !== ESTADO.CONSTRUYENDO;
    }
    return false;
  }

  _recursoDeNodo(nodo) {
    const m = this.ctx.mundo;
    if (m.tipo[nodo] === TIPO.RECURSO) {
      const def = NODOS[m.defId[nodo]];
      return def ? (IDX_RECURSO[def.recurso] ?? -1) : -1;
    }
    if (m.tipo[nodo] === TIPO.EDIFICIO) {
      const def = EDIFICIOS[m.defId[nodo]];
      return def?.recursoInfinito ? (IDX_RECURSO[def.recursoInfinito] ?? -1) : -1;
    }
    return -1;
  }

  _tiempoPorUnidad(nodo) {
    const m = this.ctx.mundo;
    if (m.tipo[nodo] === TIPO.RECURSO) return NODOS[m.defId[nodo]]?.tiempoPorUnidad || 0.5;
    return 0.5; // granja
  }

  /** Cantidad restante, con inicialización perezosa (soporta cualquier generador de mapa). */
  _restanteDe(nodo, jugador) {
    if (!this._nodoListo[nodo]) {
      const m = this.ctx.mundo;
      let base;
      if (m.tipo[nodo] === TIPO.RECURSO) {
        const def = NODOS[m.defId[nodo]];
        base = m.vida[nodo] > 0 ? m.vida[nodo] : (def?.cantidad || 100);
        m.vidaMax[nodo] = m.vidaMax[nodo] || base;
        m.vida[nodo] = base;
      } else {
        base = CANT_GRANJA_BASE * (this.mods[jugador]?.duracionGranja || 1);
      }
      this.restante[nodo] = base;
      this._nodoListo[nodo] = 1;
    }
    return this.restante[nodo];
  }

  _sembrarGranja(id, jugador) {
    this.restante[id] = CANT_GRANJA_BASE * (this.mods[jugador]?.duracionGranja || 1);
    this._nodoListo[id] = 1;
  }

  _agotarNodo(nodo, ctx) {
    const m = ctx.mundo;
    if (m.tipo[nodo] === TIPO.EDIFICIO) {
      /* granja: se replanta sola si el jugador quiere y le alcanza */
      const j = m.jugador[nodo];
      const mods = this.mods[j];
      if (mods.granjaInfinita) { this._sembrarGranja(nodo, j); return; }
      const coste = this.costeEdificio(j, 'granja');
      if (this.autoReplantar[j] && this.puedePagar(j, coste)) {
        this.pagar(j, coste);
        this._sembrarGranja(nodo, j);
        ctx.audio?.sfx?.('granja', { x: m.px[nodo], z: m.pz[nodo], volumen: 0.3 });
        this.bus.emit('granja:replantada', { id: nodo, jugador: j });
        return;
      }
      this.bus.emit('granja:agotada', { id: nodo, jugador: j });
      if (j === ctx.jugadorLocal) this._aviso(j, 'Se agotó una Granja.', 'info');
      this._quitarNodo(nodo, ctx);
      return;
    }
    this.bus.emit('nodo:agotado', { id: nodo });
    this._quitarNodo(nodo, ctx);
  }

  _quitarNodo(nodo, ctx) {
    const m = ctx.mundo;
    const def = m.tipo[nodo] === TIPO.RECURSO ? NODOS[m.defId[nodo]] : EDIFICIOS[m.defId[nodo]];
    const ancho = m.tipo[nodo] === TIPO.RECURSO ? (def?.radio || 1) * 2 : (def?.celdas?.[0] || 2) * 2;
    const alto = m.tipo[nodo] === TIPO.RECURSO ? (def?.radio || 1) * 2 : (def?.celdas?.[1] || 2) * 2;
    ctx.nav?.bloquear?.(m.px[nodo], m.pz[nodo], ancho, alto, 0);
    ctx.efectos?.polvo?.(m.px[nodo], m.py[nodo], m.pz[nodo], 6);
    m.destruir(nodo);
  }

  /** Al agotarse el nodo, el colono busca solo otro igual a menos de 40 m. */
  _buscarOtroNodo(id, ctx) {
    const m = ctx.mundo;
    const rec = this.memoriaRecurso[id] === 255 ? this.recursoTrabajo[id] : this.memoriaRecurso[id];
    if (m.cargaCant[id] > 0) { this._mandarADepositar(id, ctx); return; }

    const def = UNIDADES[m.defId[id]];
    const j = m.jugador[id];
    const buf = m.cerca(m.px[id], m.pz[id], RADIO_BUSQUEDA_NODO, this._buf);
    let mejor = -1, mejorD = Infinity;
    for (let i = 0; i < buf.length; i++) {
      const e = buf[i];
      if (e === this.objetivoTrabajo[id]) continue;
      if (!this._nodoCosechable(e, j, def)) continue;
      if (this._recursoDeNodo(e) !== rec) continue;
      if (this._restanteDe(e, j) <= 0.001) continue;
      const dx = m.px[e] - m.px[id], dz = m.pz[e] - m.pz[id];
      const d = dx * dx + dz * dz;
      if (d < mejorD) { mejorD = d; mejor = e; }
    }
    if (mejor >= 0) { this._iniciarRecoleccion(id, mejor); return; }
    this._terminarTarea(id, ctx);
  }

  _terminarTarea(id, ctx) {
    this._limpiar(id);
    const m = ctx.mundo;
    m.estado[id] = ESTADO.QUIETO;
    m.tieneDestino[id] = 0;
    this.bus.emit('colono:ocioso', { id, jugador: m.jugador[id] });
  }

  /* =================================================================== *
   * Geometría y movimiento (degrada con elegancia si no hay Navegación)
   * =================================================================== */

  /** Distancia de la unidad a la superficie del objetivo (nodo o edificio). */
  _distObjetivo(id, obj) {
    const m = this.ctx.mundo;
    if (m.tipo[obj] === TIPO.EDIFICIO) return this._distBorde(m.px[id], m.pz[id], obj);
    const dx = m.px[obj] - m.px[id], dz = m.pz[obj] - m.pz[id];
    return Math.sqrt(dx * dx + dz * dz);
  }

  _rangoNodo(id, nodo) {
    const m = this.ctx.mundo;
    const rUnidad = m.radio[id] || 0.45;
    if (m.tipo[nodo] === TIPO.EDIFICIO) return rUnidad + MARGEN_DEPOSITO;
    const def = NODOS[m.defId[nodo]];
    return rUnidad + (def?.radio || 0.9) + 0.35;
  }

  /** Anillo alrededor del nodo, del lado por el que viene la unidad: no se apilan. */
  _puntoAcercamiento(id, nodo, rango) {
    const m = this.ctx.mundo;
    if (m.tipo[nodo] === TIPO.EDIFICIO) return this._puntoBorde(nodo, m.px[id], m.pz[id], MARGEN_DEPOSITO * 0.7, id);
    const base = Math.atan2(m.pz[id] - m.pz[nodo], m.px[id] - m.px[nodo]);
    const disp = ((id * ANGULO_AUREO) % 1.9) - 0.95;
    const a = base + disp;
    const r = rango * 0.92;
    this._pt.x = m.px[nodo] + Math.cos(a) * r;
    this._pt.z = m.pz[nodo] + Math.sin(a) * r;
    return this._pt;
  }

  _medioEdificio(e) {
    const m = this.ctx.mundo;
    const def = EDIFICIOS[m.defId[e]];
    // 1 celda = 2 m ⇒ semiancho en metros = celdas
    return def?.celdas ? def.celdas : [2, 2];
  }

  _distBorde(x, z, e) {
    const m = this.ctx.mundo;
    if (m.tipo[e] !== TIPO.EDIFICIO) {
      const dx = m.px[e] - x, dz = m.pz[e] - z;
      return Math.sqrt(dx * dx + dz * dz);
    }
    const c = this._medioEdificio(e);
    const dx = Math.max(Math.abs(x - m.px[e]) - c[0], 0);
    const dz = Math.max(Math.abs(z - m.pz[e]) - c[1], 0);
    return Math.sqrt(dx * dx + dz * dz);
  }

  /** Punto de trabajo sobre el borde del edificio, con corrimiento lateral por unidad. */
  _puntoBorde(e, desdeX, desdeZ, margen, quien) {
    const m = this.ctx.mundo;
    if (m.tipo[e] !== TIPO.EDIFICIO) {
      const a = Math.atan2(desdeZ - m.pz[e], desdeX - m.px[e]);
      this._pt.x = m.px[e] + Math.cos(a) * margen;
      this._pt.z = m.pz[e] + Math.sin(a) * margen;
      return this._pt;
    }
    const c = this._medioEdificio(e);
    const cx = m.px[e], cz = m.pz[e];
    const dx = desdeX - cx, dz = desdeZ - cz;
    const lat = (((quien * 7) % 9) - 4) * 0.42;
    if (Math.abs(dx) / (c[0] + 0.001) > Math.abs(dz) / (c[1] + 0.001)) {
      this._pt.x = cx + (dx >= 0 ? 1 : -1) * (c[0] + margen);
      this._pt.z = sujetar(desdeZ + lat, cz - c[1] + 0.3, cz + c[1] - 0.3);
    } else {
      this._pt.z = cz + (dz >= 0 ? 1 : -1) * (c[1] + margen);
      this._pt.x = sujetar(desdeX + lat, cx - c[0] + 0.3, cx + c[0] - 0.3);
    }
    return this._pt;
  }

  _largoCamino(x0, z0, x1, z1) {
    const nav = this.ctx.nav;
    const recta = Math.hypot(x1 - x0, z1 - z0);
    if (!nav || typeof nav.camino !== 'function') return recta;
    let c = null;
    try { c = nav.camino(x0, z0, x1, z1, 0.5); } catch (e) { return recta; }
    if (!c || !c.length) return Infinity;
    let L = 0, px = x0, pz = z0;
    for (let i = 0; i < c.length; i++) {
      L += Math.hypot(c[i].x - px, c[i].z - pz);
      px = c[i].x; pz = c[i].z;
    }
    return L;
  }

  /**
   * Camina hacia un punto sin repetir la orden todos los ticks (eso mata al
   * pathfinder) y con detección de atasco: si no avanza, reintenta.
   */
  _caminarHacia(id, x, z, dt) {
    const m = this.ctx.mundo;
    const dx = m.destinoX[id] - x, dz = m.destinoZ[id] - z;
    let reemitir = !m.tieneDestino[id] || (dx * dx + dz * dz) > 2.25;

    const mx = m.px[id] - this._ultX[id], mz = m.pz[id] - this._ultZ[id];
    if (mx * mx + mz * mz < 0.0004) {
      this._atasco[id] += dt;
      if (this._atasco[id] > 1.2) { reemitir = true; this._atasco[id] = 0; }
    } else {
      this._atasco[id] = 0;
      this._ultX[id] = m.px[id]; this._ultZ[id] = m.pz[id];
    }
    if (reemitir) this._irA(id, x, z);
    if (m.estado[id] !== ESTADO.MOVIENDO) m.estado[id] = ESTADO.MOVIENDO;
  }

  _irA(id, x, z) {
    const m = this.ctx.mundo;
    m.destinoX[id] = x; m.destinoZ[id] = z; m.tieneDestino[id] = 1;
    const mov = this.ctx.movimiento;
    if (mov) {
      if (typeof mov.irA === 'function') mov.irA(id, x, z);
      else if (typeof mov.mover === 'function') mov.mover(id, x, z);
    }
  }

  _detener(id) {
    const m = this.ctx.mundo;
    m.tieneDestino[id] = 0;
    m.vx[id] = 0; m.vz[id] = 0;
    this.ctx.movimiento?.detener?.(id);
  }

  /* =================================================================== *
   * Utilidades internas
   * =================================================================== */

  _capacidad(id, mods) {
    const def = UNIDADES[this.ctx.mundo.defId[id]];
    const extra = def?.naval ? 5 : 0;   // el pesquero aguanta más antes de volver
    return (mods?.capacidadCarga || 10) + extra;
  }

  _limpiar(id) {
    this.tarea[id] = T.NADA;
    this.objetivoTrabajo[id] = -1;
    this.depositoDest[id] = -1;
    this._atasco[id] = 0;
  }

  _resetEntidad(id) {
    this.tarea[id] = T.NADA;
    this.objetivoTrabajo[id] = -1;
    this.depositoDest[id] = -1;
    this.memoriaNodo[id] = -1;
    this.memoriaRecurso[id] = 255;
    this.mercadoOrigen[id] = -1;
    this.mercadoDestino[id] = -1;
    this.restante[id] = 0;
    this._nodoListo[id] = 0;
    this._obreros[id] = 0;
    this._reparadores[id] = 0;
    this._atasco[id] = 0;
    this._depCache[id] = -1;
    this._depCacheJug[id] = 255;
    this._depCacheTick[id] = -999999;
  }

  _alMorir(id) {
    this._nodoListo[id] = 0;
    this.tarea[id] = T.NADA;
    // si murió un depósito, invalidamos las cachés que apuntaban a él
    const m = this.ctx.mundo;
    if (m.tipo[id] === TIPO.EDIFICIO) this._depCacheTick.fill(-999999);
  }

  _muestrearStats() {
    for (let j = 0; j < MAX_JUGADORES; j++) {
      const s = this._stats[j];
      const base = s._slot * 4;
      for (let i = 0; i < 4; i++) {
        const k = CLAVES_RECURSO[i];
        const total = s.recolectado[k];
        s._ventana[base + i] = total - s._corte[i];
        s._corte[i] = total;
      }
      s._slot = (s._slot + 1) % 12;
      for (let i = 0; i < 4; i++) {
        let suma = 0;
        for (let v = 0; v < 12; v++) suma += s._ventana[v * 4 + i];
        s.tasaPorMinuto[CLAVES_RECURSO[i]] = Math.round(suma);
      }
    }
  }

  _aviso(jugador, texto, tipo = 'info') {
    if (jugador !== this.ctx.jugadorLocal) return;
    this.bus.emit('aviso', { texto, tipo });
  }

  _avisarFalta(jugador, coste, clave) {
    if (this._avisoFalta[jugador] > 0) return;
    this._avisoFalta[jugador] = 4;
    let falta = clave || '';
    if (!falta && coste) {
      const r = this.recursos[jugador];
      for (let i = 0; i < 4; i++) {
        const k = CLAVES_RECURSO[i];
        if ((coste[k] || 0) > r[k]) { falta = k; break; }
      }
    }
    const nombres = { alimento: 'Alimento', materiales: 'Materiales', capital: 'Capital', energia: 'Energía' };
    this._aviso(jugador, `Faltan ${nombres[falta] || 'recursos'}.`, 'alerta');
    if (jugador === this.ctx.jugadorLocal) this.ctx.audio?.sfx?.('sin_recursos');
  }
}
