/**
 * IA.js — El cerebro enemigo.
 *
 * Una máquina de estados por jugador controlado por la máquina, con presupuesto
 * de decisiones: NADA se decide por tick. Hay dos relojes propios:
 *   · estratégico (~1 Hz)  economía, edificios, edades, tecnologías, fases.
 *   · táctico     (~4 Hz)  micro de combate, raids, exploración, huida de colonos.
 *
 * Reglas que se respetan a rajatabla:
 *   · La IA solo sabe lo que VE. Mantiene su propia rejilla de visión sellada
 *     con el alcance real de sus unidades y edificios; nunca lee la niebla ajena
 *     ni la posición de lo que no observó. Lo que vio, lo recuerda y lo olvida
 *     de a poco (memoria con decaimiento).
 *   · Cero trampas de recursos. El único bono es el +15% de recolección de la
 *     dificultad Brutal, y se declara por el bus para que la UI lo muestre.
 *   · Toda acción sale por `ctx.ordenes.*` (la misma fachada que usa el humano).
 *     Si algo todavía no existe, se degrada sin romper el arranque.
 *   · Antes de pedir nada se valida (pagar, población, cola, emplazamiento) para
 *     no ensuciar la pantalla del jugador con avisos de error ajenos.
 */

import { ORDEN } from '../core/Ctx.js';
import { TIPO, ESTADO } from '../core/World.js';
import { bus } from '../core/EventBus.js';
import { UNIDADES } from '../data/unidades.js';
import { EDIFICIOS, EDIFICIO_POR_CLAVE } from '../data/edificios.js';
import { TECNOLOGIAS } from '../data/tecnologias.js';
import { EDADES } from '../data/edades.js';
import { NODOS } from '../data/recursos.js';

/* ------------------------------------------------------------------ */
/* Tablas precalculadas (una sola vez, al importar el módulo)          */
/* ------------------------------------------------------------------ */

const CLAVES_REC = ['alimento', 'materiales', 'capital', 'energia'];
const IDX_REC = { alimento: 0, materiales: 1, capital: 2, energia: 3 };

/** Clases de unidad que nos importan para el censo y las contras. */
const CLASES = ['infanteria', 'tirador', 'caballeria', 'asedio', 'aldeano', 'apoyo', 'nave', 'aereo'];
const IDX_CLASE = {};
for (let i = 0; i < CLASES.length; i++) IDX_CLASE[CLASES[i]] = i;

/** Líneas de unidad que la IA sabe producir, en orden de decisión. */
const LINEAS = ['infanteria', 'antiblindaje', 'tirador', 'escaramuza', 'blindado', 'artilleria', 'ariete', 'aereo'];
const IDX_LINEA = {};
for (let i = 0; i < LINEAS.length; i++) IDX_LINEA[LINEAS[i]] = i;

/** MEJOR[linea][edad] -> clave de la mejor unidad disponible de esa línea. */
const MEJOR = {};
for (const linea of LINEAS) {
  const porEdad = new Array(EDADES.length).fill(null);
  for (let e = 0; e < EDADES.length; e++) {
    let mejor = null, mejorEdad = -1;
    for (let i = 0; i < UNIDADES.length; i++) {
      const u = UNIDADES[i];
      if (u.linea !== linea || u.edad > e || u.naval || u.clase === 'aldeano') continue;
      if (u.edad > mejorEdad) { mejorEdad = u.edad; mejor = u.clave; }
    }
    porEdad[e] = mejor;
  }
  MEJOR[linea] = porEdad;
}

const DEF_UNIDAD = new Map();
for (let i = 0; i < UNIDADES.length; i++) DEF_UNIDAD.set(UNIDADES[i].clave, UNIDADES[i]);

/** Edificio de acopio por recurso. */
const ACOPIO = { alimento: 'molino', materiales: 'aserradero', capital: 'mina', energia: 'mina' };

/** Nodos que un colono terrestre puede trabajar. */
const NODO_TRABAJABLE = NODOS.map((n) => !!n.recurso && !n.agua && !n.reliquia && n.cantidad > 0);
const NODO_RECURSO = NODOS.map((n) => (n.recurso ? IDX_REC[n.recurso] : -1));

/** Plan de edificios: [clave, edadMin, cantidadObjetivo, faseMin]. */
const PLAN = [
  ['cuartel', 0, 1, 0],
  ['mercado', 1, 1, 1],
  ['fundicion', 1, 1, 1],
  ['poligono', 1, 1, 1],
  ['establo', 1, 1, 1],
  ['taller', 1, 1, 2],
  ['cuartel', 1, 2, 2],
  ['instituto', 2, 1, 1],
  ['ciudadela', 2, 1, 2],
  ['poligono', 2, 2, 3],
  ['establo', 2, 2, 3],
  ['ministerio', 2, 1, 3],
  ['central', 3, 1, 1],
  ['aerodromo', 3, 1, 2],
  ['taller', 3, 2, 3],
];

/** Tecnologías por prioridad. Las económicas primero, siempre. */
const TECNO_ECO = [
  'arado', 'sierra_circular', 'carretilla', 'dinamita', 'cosechadora',
  'banca', 'motosierra', 'perforadora', 'camioneta', 'agroquimica',
  'contenedor', 'talado_robotico', 'mineria_autonoma', 'exoesqueleto_civil',
];
const TECNO_MIL = [
  'polvora_mejorada', 'placa_hierro', 'herradura', 'municion_perforante',
  'blindaje_soldado', 'retroceso_hidraulico', 'telemetria', 'hormigon_armado',
  'logistica', 'municion_guiada', 'compuesto_ceramico', 'balistica_asistida',
  'radar', 'suspension', 'nanomunicion', 'blindaje_reactivo', 'ia_tactica',
  'autorreparacion', 'orugas_activas',
];
const DEF_TECNO = new Map();
for (let i = 0; i < TECNOLOGIAS.length; i++) DEF_TECNO.set(TECNOLOGIAS[i].clave, TECNOLOGIAS[i]);

/** Índice de fase para comparar contra el plan. */
const IDX_FASE = { arranque: 0, expansion: 1, presion: 2, ataque: 3, asedio: 4, defensa: 2 };

const NOMBRE_FASE = {
  arranque: 'Arranque', expansion: 'Expansión', presion: 'Presión',
  ataque: 'Ataque combinado', asedio: 'Asedio', defensa: 'Defensa',
};

/* ------------------------------------------------------------------ */
/* Dificultades                                                        */
/* ------------------------------------------------------------------ */

const DIFICULTADES = {
  facil: {
    nombre: 'Fácil', tEstrategico: 2.6, tTactico: 1.0, factorColonos: 0.55,
    raids: false, muros: true, torretas: 1, micro: false, reaccion: 9.0,
    umbralAtaque: 26, bonoRecoleccion: 1, maxObras: 1, colaMax: 2,
  },
  normal: {
    nombre: 'Normal', tEstrategico: 1.2, tTactico: 0.35, factorColonos: 0.85,
    raids: true, muros: false, torretas: 2, micro: true, reaccion: 4.5,
    umbralAtaque: 18, bonoRecoleccion: 1, maxObras: 2, colaMax: 3,
  },
  dificil: {
    nombre: 'Difícil', tEstrategico: 0.8, tTactico: 0.25, factorColonos: 1.0,
    raids: true, muros: true, torretas: 4, micro: true, reaccion: 2.2,
    umbralAtaque: 15, bonoRecoleccion: 1, maxObras: 3, colaMax: 4,
  },
  brutal: {
    nombre: 'Brutal', tEstrategico: 0.55, tTactico: 0.18, factorColonos: 1.0,
    raids: true, muros: true, torretas: 6, micro: true, reaccion: 1.2,
    umbralAtaque: 14, bonoRecoleccion: 1.15, maxObras: 4, colaMax: 5,
  },
};

/** Tope de colonos por edad (antes del factor de dificultad). */
const TOPE_COLONOS = [25, 45, 70, 90, 110];

/** Distribución objetivo de colonos por recurso, por fase y edad. */
function distribucionObjetivo(edad, fase, salida) {
  // arranque: comida y materiales; después se equilibra hacia capital y energía.
  if (edad <= 0) {
    salida[0] = 0.58; salida[1] = 0.30; salida[2] = 0.12; salida[3] = 0.00;
  } else if (edad === 1) {
    salida[0] = 0.42; salida[1] = 0.30; salida[2] = 0.20; salida[3] = 0.08;
  } else if (edad === 2) {
    salida[0] = 0.36; salida[1] = 0.28; salida[2] = 0.22; salida[3] = 0.14;
  } else {
    salida[0] = 0.32; salida[1] = 0.26; salida[2] = 0.22; salida[3] = 0.20;
  }
  // en guerra abierta hacen falta más materiales (asedio, muros, reposición).
  if (fase === 'ataque' || fase === 'asedio' || fase === 'defensa') {
    salida[0] -= 0.06; salida[1] += 0.06;
  }
  return salida;
}

const CELDA_VIS = 8; // metros por celda de la rejilla de conocimiento

/* ------------------------------------------------------------------ */
/* Estado por jugador                                                  */
/* ------------------------------------------------------------------ */

class CerebroIA {
  constructor(jugador, dificultad, civ, rng) {
    this.jugador = jugador;
    this.dificultad = dificultad;
    this.cfg = DIFICULTADES[dificultad] || DIFICULTADES.normal;
    this.civ = civ || null;
    this.rng = rng;

    this.fase = 'arranque';
    this.objetivo = 'Levantar la economía';
    this.faseAnterior = '';

    this.relojEstrategico = rng.float(0, 0.6);
    this.relojTactico = rng.float(0, 0.2);

    // base
    this.baseX = 0; this.baseZ = 0; this.baseLista = false;
    this.reunionX = 0; this.reunionZ = 0; this.reunionLista = false;

    // listas reconstruidas por el escaneo global
    this.propias = [];
    this.aldeanos = [];
    this.militares = [];
    this.edificios = [];
    this.sedes = [];
    this.granjas = [];
    this.porClave = new Map();      // clave de edificio -> [ids]
    this.porLinea = new Float32Array(LINEAS.length);
    this.enemigosVistos = [];
    this.amenazasBase = [];
    this.censoEnemigo = new Float32Array(CLASES.length);
    this.vistoEnemigo = new Float32Array(CLASES.length);
    this.edificiosEnemigosVistos = 0;

    // conocimiento del mapa
    this.nc = 1; this.medioMapa = 0;
    this.visto = null; this.explorado = null;
    this.basesEnemigas = [];        // {x,z,jugador,t}

    // obras y pedidos propios (para no duplicar)
    this.obras = [];                // {clave,x,z,hasta}
    this.tecnoPedidas = new Set();
    this.colaMuros = [];            // pares x,z aplanados
    this.murosPedidos = 0;
    this.nivelMuro = 0;             // 0 = ninguno, 1 = empalizada, 2 = hormigón

    // exploración
    this.explorador = -1;
    this.expPaso = 0;
    this.expFase = rng.float(0, Math.PI * 2);
    this.expX = 0; this.expZ = 0; this.expHasta = 0;

    // militar
    this.blancoFoco = -1;
    this.blancoHasta = 0;
    this.avanceX = 0; this.avanceZ = 0;
    this.raidHasta = 0;
    this.alarmaHasta = -1;          // momento en que reacciona ante una amenaza
    this.enPeligro = false;

    this.ultimaDecision = '';
    this.ahorrandoEdad = false;

    this._estado = { fase: '', objetivo: '', ejercito: 0, economia: 0 };
    this._dist = new Float32Array(4);
    this._real = new Float32Array(4);
    this._cuentaRec = new Float32Array(4);
    this._deficit = new Float32Array(LINEAS.length);
  }
}

/* ------------------------------------------------------------------ */
/* Sistema                                                             */
/* ------------------------------------------------------------------ */

export class IA {
  constructor(ctx) {
    this.nombre = 'ia';
    this.orden = ORDEN.IA;
    this.ctx = ctx;

    /** @type {Map<number, CerebroIA>} */
    this.cerebros = new Map();

    const cap = ctx?.mundo?.cap ?? 4096;
    this.asignacion = new Int8Array(cap).fill(-1);   // recurso asignado a cada colono
    this.rol = new Uint8Array(cap);                  // 0 libre · 1 raid · 2 defensa · 3 explorador · 4 obrero
    this.ultimaOrden = new Float32Array(cap).fill(-999);
    this.retirado = new Uint8Array(cap);
    this.ocioDesde = new Float32Array(cap).fill(-1);

    this.porJugador = [];
    for (let i = 0; i < 9; i++) this.porJugador.push([]);
    this.nodos = [[], [], [], []];
    this.relojEscaneo = 0;
    this.relojAuto = 0;

    // scratch reutilizado (nada de asignar por entidad por tick)
    this._cerca = [];
    this._trabajadores = new Map();
    this._sx = 0; this._sz = 0;
    this._fallos = new Set();
    this._sigConstruir = 0;

    // limpiar marcas cuando el mundo recicla una ranura
    if (ctx?.mundo?.alCrear) {
      ctx.mundo.alCrear.add((id) => {
        this.asignacion[id] = -1;
        this.rol[id] = 0;
        this.retirado[id] = 0;
        this.ocioDesde[id] = -1;
        this.ultimaOrden[id] = -999;
      });
    }
  }

  /* ---------------------------------------------------------------- */
  /* API pública                                                       */
  /* ---------------------------------------------------------------- */

  /** Suma un jugador manejado por la máquina. `dificultad` = facil|normal|dificil|brutal. */
  agregarJugador(jugador, dificultad = 'normal', civ = null) {
    if (jugador == null || jugador === this.ctx?.jugadorLocal) return null;
    if (this.cerebros.has(jugador)) return this.cerebros.get(jugador);
    const dif = DIFICULTADES[dificultad] ? dificultad : 'normal';
    const rng = this.ctx?.rng?.fork ? this.ctx.rng.fork(0x51a1 + jugador * 977) : { float: (a = 0, b = 1) => (a + b) * 0.5, int: (a) => a, bool: () => false };
    const c = new CerebroIA(jugador, dif, civ, rng);
    c.ctx = this.ctx;

    const tam = this.ctx?.terreno?.tam ?? this.ctx?.mapa?.tam ?? 512;
    c.medioMapa = tam * 0.5;
    c.nc = Math.max(4, Math.ceil(tam / CELDA_VIS) + 2);
    c.visto = new Uint8Array(c.nc * c.nc);
    c.explorado = new Uint8Array(c.nc * c.nc);

    const inicio = this.ctx?.mapa?.inicios?.[jugador];
    if (inicio) { c.baseX = inicio.x; c.baseZ = inicio.z; c.baseLista = true; }

    this.cerebros.set(jugador, c);

    // Único bono declarado: Brutal recolecta 15% más. Se avisa por la UI.
    if (c.cfg.bonoRecoleccion !== 1) {
      const mods = this.ctx?.eco?.mods?.[jugador];
      if (mods?.velRecoleccion) {
        for (const k of CLAVES_REC) {
          if (typeof mods.velRecoleccion[k] === 'number') mods.velRecoleccion[k] *= c.cfg.bonoRecoleccion;
        }
      }
      bus.emit('aviso', { texto: `Rival ${jugador} en Brutal: +15% de recolección declarado.`, tipo: 'alerta' });
    }
    this._decidir(c, `Entra en juego en dificultad ${c.cfg.nombre}`);
    return c;
  }

  quitarJugador(jugador) { this.cerebros.delete(jugador); }

  /** Radiografía para la UI o el depurador. */
  estado(jugador) {
    const c = this.cerebros.get(jugador);
    if (!c) return null;
    const e = c._estado;
    e.fase = NOMBRE_FASE[c.fase] || c.fase;
    e.objetivo = c.objetivo;
    e.ejercito = c.militares.length;
    e.economia = c.aldeanos.length;
    return e;
  }

  /* ---------------------------------------------------------------- */
  /* Bucle                                                             */
  /* ---------------------------------------------------------------- */

  fijo(dt, ctx) {
    const m = ctx?.mundo;
    if (!m) return;

    // Alta automática: si nadie registró rivales, los detecta del mundo.
    this.relojAuto -= dt;
    if (this.relojAuto <= 0) {
      this.relojAuto = 2;
      this._autoRegistrar(ctx);
    }
    if (this.cerebros.size === 0) return;

    // Escaneo compartido (2 Hz): una sola pasada del mundo para todos.
    this.relojEscaneo -= dt;
    if (this.relojEscaneo <= 0) {
      this.relojEscaneo = 0.5;
      this._escanear(ctx);
    }

    for (const c of this.cerebros.values()) {
      c.relojTactico -= dt;
      if (c.relojTactico <= 0) {
        c.relojTactico = c.cfg.tTactico;
        try { this._tactico(c, ctx); } catch (e) { this._error('tactico', e); }
      }
      c.relojEstrategico -= dt;
      if (c.relojEstrategico <= 0) {
        c.relojEstrategico = c.cfg.tEstrategico;
        try { this._estrategico(c, ctx); } catch (e) { this._error('estrategico', e); }
      }
    }
  }

  _autoRegistrar(ctx) {
    const m = ctx.mundo;
    const local = ctx.jugadorLocal ?? 0;
    const dif = ctx.opciones?.dificultadIA ?? ctx.dificultadIA ?? 'normal';
    for (let i = 0; i < m.maxUsado; i++) {
      if (!m.vivo[i]) continue;
      const j = m.jugador[i];
      if (j === local || j >= 8) continue;
      if (this.cerebros.has(j)) continue;
      if (m.tipo[i] !== TIPO.EDIFICIO && m.tipo[i] !== TIPO.UNIDAD) continue;
      const civ = ctx.mapa?.jugadores?.[j]?.civ ?? null;
      this.agregarJugador(j, dif, civ);
    }
  }

  /* ---------------------------------------------------------------- */
  /* Escaneo del mundo (una pasada para todos los cerebros)            */
  /* ---------------------------------------------------------------- */

  _escanear(ctx) {
    const m = ctx.mundo;
    for (let i = 0; i < this.porJugador.length; i++) this.porJugador[i].length = 0;
    for (let r = 0; r < 4; r++) this.nodos[r].length = 0;

    for (const c of this.cerebros.values()) {
      c.propias.length = 0; c.aldeanos.length = 0; c.militares.length = 0;
      c.edificios.length = 0; c.sedes.length = 0; c.granjas.length = 0;
      c.enemigosVistos.length = 0; c.amenazasBase.length = 0;
      c.porClave.clear();
      c.porLinea.fill(0);
      c.vistoEnemigo.fill(0);
      c.edificiosEnemigosVistos = 0;
    }

    // --- pasada 1: clasificar todo lo vivo ---
    for (let id = 0; id < m.maxUsado; id++) {
      if (!m.vivo[id]) continue;
      const tipo = m.tipo[id];
      if (tipo === TIPO.PROYECTIL || tipo === TIPO.DECORADO) continue;

      if (tipo === TIPO.RECURSO) {
        const nd = m.defId[id];
        if (NODO_TRABAJABLE[nd]) this.nodos[NODO_RECURSO[nd]].push(id);
        continue;
      }
      const j = m.jugador[id];
      if (j > 8) continue;
      this.porJugador[j].push(id);

      const c = this.cerebros.get(j);
      if (!c) continue;
      c.propias.push(id);

      if (tipo === TIPO.UNIDAD) {
        const def = UNIDADES[m.defId[id]];
        if (!def) continue;
        if (def.clase === 'aldeano') {
          c.aldeanos.push(id);
        } else {
          c.militares.push(id);
          const li = IDX_LINEA[def.linea];
          if (li !== undefined) c.porLinea[li]++;
        }
      } else if (tipo === TIPO.EDIFICIO) {
        const def = EDIFICIOS[m.defId[id]];
        if (!def) continue;
        c.edificios.push(id);
        let arr = c.porClave.get(def.clave);
        if (!arr) { arr = []; c.porClave.set(def.clave, arr); }
        arr.push(id);
        if (def.clave === 'sede') c.sedes.push(id);
        else if (def.clave === 'granja') c.granjas.push(id);
      }
    }

    // --- pasada 2: visión honesta y censo del enemigo ---
    for (const c of this.cerebros.values()) {
      // base = primera sede viva; si no hay, el promedio de lo propio
      if (c.sedes.length) {
        c.baseX = m.px[c.sedes[0]]; c.baseZ = m.pz[c.sedes[0]]; c.baseLista = true;
      } else if (!c.baseLista && c.propias.length) {
        let sx = 0, sz = 0;
        for (let i = 0; i < c.propias.length; i++) { sx += m.px[c.propias[i]]; sz += m.pz[c.propias[i]]; }
        c.baseX = sx / c.propias.length; c.baseZ = sz / c.propias.length; c.baseLista = true;
      }
      if (!c.reunionLista && c.baseLista) {
        c.reunionX = c.baseX; c.reunionZ = c.baseZ;
        c.avanceX = c.baseX; c.avanceZ = c.baseZ;
        c.reunionLista = true;
      }

      this._sellarVision(c, m);

      for (let p = 0; p < this.porJugador.length; p++) {
        if (p === c.jugador) continue;
        const lista = this.porJugador[p];
        for (let k = 0; k < lista.length; k++) {
          const id = lista[k];
          const idx = this._celdaVis(c, m.px[id], m.pz[id]);
          if (idx < 0 || !c.visto[idx]) continue;

          if (m.tipo[id] === TIPO.UNIDAD) {
            const def = UNIDADES[m.defId[id]];
            if (def) {
              const ci = IDX_CLASE[def.clase];
              if (ci !== undefined) c.vistoEnemigo[ci]++;
            }
            if (c.enemigosVistos.length < 256) c.enemigosVistos.push(id);
          } else {
            c.edificiosEnemigosVistos++;
            const def = EDIFICIOS[m.defId[id]];
            if (def && (def.clave === 'sede' || def.clave === 'ciudadela')) this._recordarBase(c, m.px[id], m.pz[id], p);
            if (c.enemigosVistos.length < 256) c.enemigosVistos.push(id);
          }
          // amenaza cerca de casa
          const dx = m.px[id] - c.baseX, dz = m.pz[id] - c.baseZ;
          if (dx * dx + dz * dz < 55 * 55 && m.tipo[id] === TIPO.UNIDAD) c.amenazasBase.push(id);
        }
      }

      // memoria con decaimiento: lo que vio pesa, lo que dejó de ver se olvida de a poco
      for (let i = 0; i < CLASES.length; i++) {
        const visto = c.vistoEnemigo[i];
        c.censoEnemigo[i] = visto > c.censoEnemigo[i] ? visto : c.censoEnemigo[i] * 0.96;
      }
    }
  }

  _sellarVision(c, m) {
    c.visto.fill(0);
    const nc = c.nc, medio = c.medioMapa;
    for (let k = 0; k < c.propias.length; k++) {
      const id = c.propias[k];
      const def = m.tipo[id] === TIPO.UNIDAD ? UNIDADES[m.defId[id]] : EDIFICIOS[m.defId[id]];
      const vision = def?.vision ?? 18;
      const r = Math.min(7, Math.ceil(vision / CELDA_VIS));
      const cx = Math.floor((m.px[id] + medio) / CELDA_VIS);
      const cz = Math.floor((m.pz[id] + medio) / CELDA_VIS);
      const r2 = (r + 0.2) * (r + 0.2);
      for (let oz = -r; oz <= r; oz++) {
        const z = cz + oz;
        if (z < 0 || z >= nc) continue;
        for (let ox = -r; ox <= r; ox++) {
          if (ox * ox + oz * oz > r2) continue;
          const x = cx + ox;
          if (x < 0 || x >= nc) continue;
          const i = z * nc + x;
          c.visto[i] = 1; c.explorado[i] = 1;
        }
      }
    }
  }

  _celdaVis(c, x, z) {
    const cx = Math.floor((x + c.medioMapa) / CELDA_VIS);
    const cz = Math.floor((z + c.medioMapa) / CELDA_VIS);
    if (cx < 0 || cz < 0 || cx >= c.nc || cz >= c.nc) return -1;
    return cz * c.nc + cx;
  }

  _explorado(c, x, z) {
    const i = this._celdaVis(c, x, z);
    return i < 0 ? true : c.explorado[i] === 1;
  }

  _recordarBase(c, x, z, jugador) {
    for (let i = 0; i < c.basesEnemigas.length; i++) {
      const b = c.basesEnemigas[i];
      const dx = b.x - x, dz = b.z - z;
      if (dx * dx + dz * dz < 40 * 40) { b.x = x; b.z = z; b.t = this.ctx.mundo.tiempo; return; }
    }
    if (c.basesEnemigas.length >= 12) return;
    c.basesEnemigas.push({ x, z, jugador, t: this.ctx.mundo.tiempo });
    this._decidir(c, `Encontró una base del jugador ${jugador}`);
  }

  /* ---------------------------------------------------------------- */
  /* Capa estratégica (~1 Hz)                                          */
  /* ---------------------------------------------------------------- */

  _estrategico(c, ctx) {
    if (!c.propias.length) return;
    this._actualizarFase(c, ctx);
    this._limpiarObras(c, ctx);

    this._gestionarPoblacion(c, ctx);
    this._gestionarColonos(c, ctx);
    this._gestionarAcopios(c, ctx);
    this._gestionarGranjas(c, ctx);
    this._avanzarEdad(c, ctx);
    this._investigar(c, ctx);
    this._edificiosMilitares(c, ctx);
    this._producirEjercito(c, ctx);
    this._defensasEstaticas(c, ctx);
    this._muros(c, ctx);
    this._planMilitar(c, ctx);
  }

  _edad(c) { return this.ctx.edades?.edad?.[c.jugador] ?? 0; }

  _actualizarFase(c, ctx) {
    const t = ctx.mundo.tiempo;
    const amenaza = c.amenazasBase.length;

    // La reacción defensiva tiene retardo según dificultad: la fácil se despierta tarde.
    if (amenaza >= 2) {
      if (c.alarmaHasta < 0) c.alarmaHasta = t + c.cfg.reaccion;
    } else if (amenaza === 0) {
      c.alarmaHasta = -1;
      c.enPeligro = false;
    }
    if (c.alarmaHasta >= 0 && t >= c.alarmaHasta) c.enPeligro = true;

    let fase;
    if (c.enPeligro) fase = 'defensa';
    else if (t < 130) fase = 'arranque';
    else if (c.militares.length >= c.cfg.umbralAtaque) {
      const b = this._baseEnemigaMasCerca(c);
      fase = (b && this._grupoCerca(c, b.x, b.z, 45)) ? 'asedio' : 'ataque';
    } else if (t >= 420 && c.cfg.raids) fase = 'presion';
    else fase = 'expansion';

    if (fase !== c.fase) {
      c.fase = fase;
      c.objetivo = {
        arranque: 'Levantar la economía',
        expansion: 'Expandirse y sumar edificios',
        presion: 'Hostigar recolectores enemigos',
        ataque: 'Formar el ejército y avanzar',
        asedio: 'Romper la base enemiga',
        defensa: 'Defender la base',
      }[fase];
      this._decidir(c, `Fase: ${NOMBRE_FASE[fase]}`);
    }
  }

  _limpiarObras(c, ctx) {
    const t = ctx.mundo.tiempo;
    for (let i = c.obras.length - 1; i >= 0; i--) {
      if (c.obras[i].hasta < t) c.obras.splice(i, 1);
    }
  }

  _cuenta(c, clave) {
    const a = c.porClave.get(clave);
    let n = a ? a.length : 0;
    for (let i = 0; i < c.obras.length; i++) if (c.obras[i].clave === clave) n++;
    return n;
  }

  _obrasEnCurso(c) { return c.obras.length; }

  /* ---------------- población ---------------- */

  _gestionarPoblacion(c, ctx) {
    const pob = this._pob(c);
    if (!pob) return;
    // El error que delata a una IA mala: topearse. Se construye con 3 de margen.
    const margen = pob.tope - pob.actual;
    const viviendasEnObra = this._cuenta(c, 'vivienda') - (c.porClave.get('vivienda')?.length ?? 0);
    if (pob.tope >= 200) return;
    if (margen - viviendasEnObra * 5 > 3) return;
    if (this._obrasEnCurso(c) >= c.cfg.maxObras + 1) return;
    if (!this._puedePagarClave(c, 'vivienda')) return;
    this._construir(c, 'vivienda', c.baseX, c.baseZ, 10, 26, 1);
  }

  _pob(c) {
    const p = this.ctx.eco?.pob?.[c.jugador];
    if (p) return p;
    // degradado: lo calcula solo
    const m = this.ctx.mundo;
    let actual = 0;
    for (let i = 0; i < c.aldeanos.length; i++) actual += 1;
    for (let i = 0; i < c.militares.length; i++) actual += UNIDADES[m.defId[c.militares[i]]]?.pop ?? 1;
    let tope = 0;
    for (let i = 0; i < c.edificios.length; i++) tope += EDIFICIOS[m.defId[c.edificios[i]]]?.pop ?? 0;
    return { actual, tope: Math.min(200, tope) };
  }

  /* ---------------- colonos ---------------- */

  _gestionarColonos(c, ctx) {
    const m = ctx.mundo;
    const edad = this._edad(c);
    const tope = Math.round(TOPE_COLONOS[Math.min(edad, 4)] * c.cfg.factorColonos);

    // 1) producir colonos sin parar hasta el tope
    if (c.aldeanos.length < tope) {
      const pob = this._pob(c);
      const def = DEF_UNIDAD.get('colono');
      if (pob && pob.actual + 1 <= pob.tope && this._puedePagar(c, def.coste)) {
        for (let i = 0; i < c.sedes.length; i++) {
          const sede = c.sedes[i];
          if (m.estado[sede] === ESTADO.CONSTRUYENDO) continue;
          if (this._largoCola(sede) >= (c.fase === 'arranque' ? 2 : c.cfg.colaMax)) continue;
          if (this._entrenar(c, sede, 'colono')) break;
        }
      }
    }

    // 2) contar cómo está repartida la mano de obra
    const real = c._real; real.fill(0);
    let total = 0;
    for (let i = 0; i < c.aldeanos.length; i++) {
      const id = c.aldeanos[i];
      const a = this.asignacion[id];
      if (a >= 0) { real[a]++; total++; }
    }
    const dist = distribucionObjetivo(edad, c.fase, c._dist);

    // 3) ociosos y nuevos: al recurso más flojo
    const t = ctx.mundo.tiempo;
    let reasignados = 0;
    const maxReasign = c.cfg.micro ? 4 : 2;
    for (let i = 0; i < c.aldeanos.length; i++) {
      const id = c.aldeanos[i];
      if (this.rol[id] === 3 || this.rol[id] === 4) continue;      // explorador u obrero
      const est = m.estado[id];
      const ocupado = est === ESTADO.RECOLECTANDO || est === ESTADO.DEPOSITANDO ||
        est === ESTADO.CONSTRUYENDO || est === ESTADO.REPARANDO ||
        (est === ESTADO.MOVIENDO && m.tieneDestino[id]);
      if (ocupado) { this.ocioDesde[id] = -1; continue; }
      if (this.ocioDesde[id] < 0) { this.ocioDesde[id] = t; continue; }
      if (t - this.ocioDesde[id] < 1.2) continue;
      if (reasignados >= maxReasign) break;
      const rec = this._recursoMasFlojo(real, dist, total);
      if (this._mandarARecolectar(c, id, rec)) { reasignados++; this.ocioDesde[id] = -1; real[rec]++; total++; }
    }

    // 4) rebalanceo suave: mover uno del recurso sobrante al faltante
    if (total > 6 && reasignados === 0) {
      let sobra = -1, falta = -1, dMax = 0, dMin = 0;
      for (let r = 0; r < 4; r++) {
        const d = real[r] / total - dist[r];
        if (d > dMax) { dMax = d; sobra = r; }
        if (d < dMin) { dMin = d; falta = r; }
      }
      if (sobra >= 0 && falta >= 0 && dMax > 0.10 && dMin < -0.08) {
        for (let i = 0; i < c.aldeanos.length; i++) {
          const id = c.aldeanos[i];
          if (this.asignacion[id] !== sobra || this.rol[id] > 0) continue;
          if (this._mandarARecolectar(c, id, falta)) break;
        }
      }
    }
  }

  _recursoMasFlojo(real, dist, total) {
    let mejor = 0, peor = Infinity;
    for (let r = 0; r < 4; r++) {
      if (dist[r] <= 0.001) continue;
      const rel = total > 0 ? real[r] / total : 0;
      const d = rel - dist[r];
      if (d < peor) { peor = d; mejor = r; }
    }
    return mejor;
  }

  /** Manda un colono al mejor nodo del recurso pedido (cerca, poco poblado y explorado). */
  _mandarARecolectar(c, id, recurso) {
    const m = this.ctx.mundo;
    if (!this._puedeOrdenar(id, 0.8)) return false;

    // contar trabajadores por nodo (scratch reutilizado)
    const uso = this._trabajadores;
    uso.clear();
    for (let i = 0; i < c.aldeanos.length; i++) {
      const o = m.objetivo[c.aldeanos[i]];
      if (o >= 0) uso.set(o, (uso.get(o) || 0) + 1);
    }

    const lista = recurso === 0 ? null : this.nodos[recurso];
    let mejor = -1, mejorPuntaje = Infinity;
    const px = m.px[id], pz = m.pz[id];

    const evaluar = (nid, capacidad) => {
      if (!m.vivo[nid]) return;
      const n = uso.get(nid) || 0;
      if (n >= capacidad) return;
      const x = m.px[nid], z = m.pz[nid];
      if (!this._explorado(c, x, z)) return;
      const dx = x - px, dz = z - pz;
      const dbx = x - c.baseX, dbz = z - c.baseZ;
      // cerca del colono, cerca de casa y sin amontonarse
      const p = Math.sqrt(dx * dx + dz * dz) + Math.sqrt(dbx * dbx + dbz * dbz) * 0.7 + n * 14;
      if (p < mejorPuntaje) { mejorPuntaje = p; mejor = nid; }
    };

    if (recurso === 0) {
      for (let i = 0; i < c.granjas.length; i++) evaluar(c.granjas[i], 4);
      const nf = this.nodos[0];
      for (let i = 0; i < nf.length; i++) evaluar(nf[i], 4);
    } else {
      for (let i = 0; i < lista.length; i++) evaluar(lista[i], recurso === 1 ? 3 : 5);
    }
    if (mejor < 0) return false;

    if (!this._recolectar(c, id, mejor)) return false;
    this.asignacion[id] = recurso;
    return true;
  }

  /* ---------------- acopios y granjas ---------------- */

  /** Construye molinos/aserraderos/minas PEGADOS al recurso, no en la base. */
  _gestionarAcopios(c, ctx) {
    if (this._obrasEnCurso(c) >= c.cfg.maxObras) return;
    const m = ctx.mundo;
    const edad = this._edad(c);

    for (let r = 1; r < 4; r++) {
      if (r === 3 && edad < 1) continue;
      const clave = ACOPIO[CLAVES_REC[r]];
      if (this._cuenta(c, clave) >= 1 + edad) continue;
      if (!this._puedePagarClave(c, clave)) continue;

      // buscar el racimo de recursos explorado más cercano sin depósito al lado
      const lista = this.nodos[r];
      let mejor = -1, mejorD = Infinity;
      for (let i = 0; i < lista.length; i++) {
        const nid = lista[i];
        const x = m.px[nid], z = m.pz[nid];
        if (!this._explorado(c, x, z)) continue;
        const dbx = x - c.baseX, dbz = z - c.baseZ;
        const d = dbx * dbx + dbz * dbz;
        if (d > 190 * 190) continue;
        if (this._hayDepositoCerca(c, x, z, 26)) continue;
        if (d < mejorD) { mejorD = d; mejor = nid; }
      }
      if (mejor < 0) continue;
      if (mejorD < 26 * 26) continue;   // ya lo cubre la sede
      if (this._construir(c, clave, m.px[mejor], m.pz[mejor], 4, 11, 1)) {
        this._decidir(c, `Acopio de ${CLAVES_REC[r]} junto al recurso`);
        return;
      }
    }
  }

  _hayDepositoCerca(c, x, z, radio) {
    const m = this.ctx.mundo;
    const r2 = radio * radio;
    for (let i = 0; i < c.edificios.length; i++) {
      const id = c.edificios[i];
      const def = EDIFICIOS[m.defId[id]];
      if (!def?.deposito) continue;
      const dx = m.px[id] - x, dz = m.pz[id] - z;
      if (dx * dx + dz * dz < r2) return true;
    }
    for (let i = 0; i < c.obras.length; i++) {
      const o = c.obras[i];
      const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(o.clave)];
      if (!def?.deposito) continue;
      const dx = o.x - x, dz = o.z - z;
      if (dx * dx + dz * dz < r2) return true;
    }
    return false;
  }

  /** Cuando la comida cercana escasea, planta granjas alrededor de la base. */
  _gestionarGranjas(c, ctx) {
    if (this._obrasEnCurso(c) >= c.cfg.maxObras) return;
    const m = ctx.mundo;
    let cercanos = 0;
    const nf = this.nodos[0];
    for (let i = 0; i < nf.length; i++) {
      const dx = m.px[nf[i]] - c.baseX, dz = m.pz[nf[i]] - c.baseZ;
      if (dx * dx + dz * dz < 70 * 70) cercanos++;
    }
    const objetivo = Math.min(14, Math.max(0, 8 - cercanos) + this._edad(c) * 2);
    if (this._cuenta(c, 'granja') >= objetivo) return;
    if (!this._puedePagarClave(c, 'granja')) return;
    this._construir(c, 'granja', c.baseX, c.baseZ, 8, 24, 1);
  }

  /* ---------------- edades y tecnologías ---------------- */

  _avanzarEdad(c, ctx) {
    const edad = this._edad(c);
    if (edad >= EDADES.length - 1) { c.ahorrandoEdad = false; return; }
    const sig = EDADES[edad + 1];
    if (!sig?.coste) return;

    // requisito estilo AoE: dos edificios que no sean casas ni muros
    let solidos = 0;
    for (const [clave, arr] of c.porClave) {
      if (clave === 'vivienda' || clave === 'empalizada' || clave === 'muro_hormigon' || clave === 'granja' || clave === 'sede') continue;
      solidos += arr.length;
    }
    if (solidos < 2) { c.ahorrandoEdad = false; return; }
    if (!c.sedes.length) return;

    const rec = this.ctx.eco?.recursos?.[c.jugador];
    if (rec) {
      let cerca = true;
      for (const k of CLAVES_REC) if ((rec[k] ?? 0) < (sig.coste[k] ?? 0) * 0.6) cerca = false;
      c.ahorrandoEdad = cerca;
    }
    if (!this._puedePagar(c, sig.coste)) return;

    const sede = c.sedes[0];
    if (this._largoCola(sede) > 0) return;
    if (this._pedirAvanceEdad(c, sede)) {
      c.ahorrandoEdad = false;
      this._decidir(c, `Avanza a la ${sig.nombre}`);
    }
  }

  _investigar(c, ctx) {
    if (c.ahorrandoEdad) return;
    const edad = this._edad(c);
    const lista = this._prefiereMilitar(c) ? TECNO_MIL : TECNO_ECO;
    const otra = lista === TECNO_ECO ? TECNO_MIL : TECNO_ECO;

    for (let paso = 0; paso < 2; paso++) {
      const l = paso === 0 ? lista : otra;
      for (let i = 0; i < l.length; i++) {
        const clave = l[i];
        if (c.tecnoPedidas.has(clave)) continue;
        const def = DEF_TECNO.get(clave);
        if (!def || def.edad > edad) continue;
        if (def.requiere && !c.tecnoPedidas.has(def.requiere)) continue;
        const edificios = c.porClave.get(def.en);
        if (!edificios || !edificios.length) continue;
        if (!this._puedePagar(c, def.coste)) continue;
        // si el sistema de edades la bloquea, se reintenta más adelante (no se marca)
        const chequeo = this.ctx.edades?.puedeInvestigar?.(c.jugador, clave);
        if (chequeo && chequeo.puede === false) continue;
        for (let k = 0; k < edificios.length; k++) {
          const eid = edificios[k];
          if (this.ctx.mundo.estado[eid] === ESTADO.CONSTRUYENDO) continue;
          if (this._largoCola(eid) > 0) continue;
          if (this._investigarEn(c, eid, clave)) {
            c.tecnoPedidas.add(clave);
            this._decidir(c, `Investiga ${def.nombre}`);
            return;
          }
        }
      }
    }
  }

  _prefiereMilitar(c) {
    if (c.fase === 'defensa' || c.fase === 'asedio' || c.fase === 'ataque') return true;
    let enemigos = 0;
    for (let i = 0; i < CLASES.length; i++) if (i !== IDX_CLASE.aldeano) enemigos += c.censoEnemigo[i];
    return enemigos > c.militares.length * 1.2 && enemigos > 6;
  }

  /* ---------------- edificios militares ---------------- */

  _edificiosMilitares(c, ctx) {
    if (this._obrasEnCurso(c) >= c.cfg.maxObras) return;
    if (c.ahorrandoEdad && c.fase !== 'defensa') return;
    const edad = this._edad(c);
    const fase = IDX_FASE[c.fase] ?? 1;
    const t = ctx.mundo.tiempo;

    for (let i = 0; i < PLAN.length; i++) {
      const [clave, edadMin, cantidad, faseMin] = PLAN[i];
      if (edad < edadMin) continue;
      if (fase < faseMin && !(clave === 'cuartel' && (c.enPeligro || t > 220))) continue;
      if (this._cuenta(c, clave) >= cantidad) continue;
      if (!this._puedePagarClave(c, clave)) continue;
      const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];
      const min = def && def.celdas[0] >= 5 ? 14 : 11;
      if (this._construir(c, clave, c.baseX, c.baseZ, min, 30, 2)) {
        this._decidir(c, `Levanta ${def?.nombre ?? clave}`);
        return;
      }
    }
  }

  /* ---------------- ejército ---------------- */

  /** Composición objetivo: por edad y, sobre todo, por lo que VIO del enemigo. */
  _composicion(c, salida) {
    const edad = this._edad(c);
    salida.fill(0);
    salida[IDX_LINEA.infanteria] = 0.40;
    salida[IDX_LINEA.antiblindaje] = 0.15;
    if (edad >= 1) {
      salida[IDX_LINEA.infanteria] = 0.32;
      salida[IDX_LINEA.tirador] = 0.22;
      salida[IDX_LINEA.blindado] = 0.16;
      salida[IDX_LINEA.escaramuza] = 0.06;
      salida[IDX_LINEA.artilleria] = 0.09;
    }
    if (edad >= 3) {
      salida[IDX_LINEA.aereo] = 0.08;
      salida[IDX_LINEA.infanteria] -= 0.05;
    }

    // contras según el censo enemigo recordado
    let total = 0;
    for (let i = 0; i < CLASES.length; i++) if (i !== IDX_CLASE.aldeano) total += c.censoEnemigo[i];
    if (total > 3) {
      const blindaje = (c.censoEnemigo[IDX_CLASE.caballeria] + c.censoEnemigo[IDX_CLASE.asedio] * 0.6) / total;
      const tiro = c.censoEnemigo[IDX_CLASE.tirador] / total;
      const aire = c.censoEnemigo[IDX_CLASE.aereo] / total;
      if (blindaje > 0.25) { salida[IDX_LINEA.antiblindaje] += 0.22 * blindaje * 2; salida[IDX_LINEA.tirador] *= 0.7; }
      if (tiro > 0.25) { salida[IDX_LINEA.escaramuza] += 0.20 * tiro * 2; salida[IDX_LINEA.blindado] += 0.12; }
      if (aire > 0.10) { salida[IDX_LINEA.escaramuza] += 0.12; salida[IDX_LINEA.antiblindaje] += 0.08; }
    }
    // muchos edificios enfrente = artillería
    if (c.edificiosEnemigosVistos > 6 && edad >= 1) {
      salida[IDX_LINEA.artilleria] += 0.10;
      if (c.fase === 'asedio') { salida[IDX_LINEA.artilleria] += 0.12; salida[IDX_LINEA.ariete] += 0.06; }
    }

    let suma = 0;
    for (let i = 0; i < salida.length; i++) suma += salida[i];
    if (suma > 0) for (let i = 0; i < salida.length; i++) salida[i] /= suma;
    return salida;
  }

  _producirEjercito(c, ctx) {
    const m = ctx.mundo;
    const edad = this._edad(c);
    if (c.ahorrandoEdad && !c.enPeligro && c.fase !== 'asedio') return;
    if (c.fase === 'arranque' && !c.enPeligro && c.militares.length >= 3) return;

    const pob = this._pob(c);
    if (pob && pob.tope - pob.actual < 2) return;

    const obj = this._composicion(c, c._deficit);
    const total = Math.max(1, c.militares.length);

    // déficit por línea
    let mejorLinea = -1, mejorD = -1;
    for (let i = 0; i < LINEAS.length; i++) {
      if (obj[i] <= 0.001) continue;
      const d = obj[i] - c.porLinea[i] / total;
      if (d > mejorD) { mejorD = d; mejorLinea = i; }
    }
    if (mejorLinea < 0) return;

    // se intenta la línea más floja; si no se puede, se prueban las demás
    for (let intento = 0; intento < LINEAS.length; intento++) {
      const li = (mejorLinea + intento) % LINEAS.length;
      if (obj[li] <= 0.001) continue;
      const clave = MEJOR[LINEAS[li]]?.[Math.min(edad, 4)];
      if (!clave) continue;
      const def = DEF_UNIDAD.get(clave);
      if (!def || def.edad > edad) continue;
      if (pob && pob.actual + def.pop > pob.tope) continue;
      if (!this._puedePagar(c, def.coste, c.ahorrandoEdad ? 0.5 : 0)) continue;
      const edificios = c.porClave.get(def.desde);
      if (!edificios) continue;
      for (let k = 0; k < edificios.length; k++) {
        const eid = edificios[k];
        if (m.estado[eid] === ESTADO.CONSTRUYENDO) continue;
        if (this._largoCola(eid) >= c.cfg.colaMax) continue;
        if (this._entrenar(c, eid, clave)) return;
      }
    }
  }

  /* ---------------- defensa estática y muros ---------------- */

  _defensasEstaticas(c, ctx) {
    if (this._edad(c) < 1) return;
    if (this._obrasEnCurso(c) >= c.cfg.maxObras) return;
    const objetivo = c.enPeligro ? c.cfg.torretas : Math.min(c.cfg.torretas, 1 + this._edad(c));
    if (this._cuenta(c, 'torreta') >= objetivo) return;
    if (!this._puedePagarClave(c, 'torreta')) return;

    // en el acceso: mirando al enemigo conocido (o al centro del mapa)
    const b = this._baseEnemigaMasCerca(c);
    const ax = b ? b.x : 0, az = b ? b.z : 0;
    let dx = ax - c.baseX, dz = az - c.baseZ;
    const d = Math.hypot(dx, dz) || 1;
    dx /= d; dz /= d;
    const gx = c.baseX + dx * 22, gz = c.baseZ + dz * 22;
    if (this._construir(c, 'torreta', gx, gz, 0, 10, 1)) {
      this._decidir(c, 'Torreta en el acceso');
    }
  }

  /** Difícil y brutal amurallan los accesos: empalizada primero, hormigón después. */
  _muros(c, ctx) {
    if (!c.cfg.muros) return;
    const edad = this._edad(c);
    const nivel = edad >= 2 ? 2 : 1;
    const clave = nivel === 2 ? 'muro_hormigon' : 'empalizada';
    if (nivel !== c.nivelMuro && c.colaMuros.length === 0) {
      // (re)planificar el arco cuando cambia el material
      if (nivel === 1 && ctx.mundo.tiempo < 240) return;
      this._planificarMuro(c, nivel);
    }
    if (!c.colaMuros.length) return;
    if (!this._puedePagarClave(c, clave)) return;

    // de a poco: 2 segmentos por decisión estratégica, para no trabar la economía
    let puestos = 0;
    while (c.colaMuros.length >= 2 && puestos < 2) {
      const z = c.colaMuros.pop();
      const x = c.colaMuros.pop();
      if (this._construir(c, clave, x, z, 0, 3, 1)) puestos++;
      if (!this._puedePagarClave(c, clave)) break;
    }
  }

  _planificarMuro(c, nivel) {
    c.nivelMuro = nivel;
    c.colaMuros.length = 0;
    const b = this._baseEnemigaMasCerca(c);
    const angCentro = b ? Math.atan2(b.z - c.baseZ, b.x - c.baseX)
      : Math.atan2(-c.baseZ, -c.baseX);
    const radio = 30;
    const abertura = 0.62;                 // ~35°
    const paso = 2 / radio;                // segmentos de 1 celda = 2 m
    const n = Math.floor((abertura * 2) / paso);
    for (let i = 0; i <= n; i++) {
      const k = i / n;
      // se deja un portón en el medio para que salga el ejército
      if (k > 0.44 && k < 0.56) continue;
      const a = angCentro - abertura + k * abertura * 2;
      c.colaMuros.push(c.baseX + Math.cos(a) * radio, c.baseZ + Math.sin(a) * radio);
    }
    this._decidir(c, nivel === 2 ? 'Refuerza el acceso con hormigón' : 'Amuralla el acceso');
  }

  /* ---------------- plan militar ---------------- */

  _planMilitar(c, ctx) {
    const m = ctx.mundo;
    const t = m.tiempo;

    // reparto de roles: defensa fija, raid y grueso del ejército
    const quiereRaid = c.cfg.raids && (c.fase === 'presion' || c.fase === 'expansion') && c.militares.length >= 6;
    const objetivoRaid = quiereRaid ? Math.min(8, Math.max(4, Math.floor(c.militares.length * 0.35))) : 0;
    const objetivoDef = c.enPeligro ? c.militares.length : Math.min(4, Math.floor(c.militares.length * 0.2));

    let enRaid = 0, enDef = 0;
    for (let i = 0; i < c.militares.length; i++) {
      const r = this.rol[c.militares[i]];
      if (r === 1) enRaid++; else if (r === 2) enDef++;
    }
    for (let i = 0; i < c.militares.length; i++) {
      const id = c.militares[i];
      const def = UNIDADES[m.defId[id]];
      if (this.rol[id] === 3) continue;
      if (c.enPeligro) { this.rol[id] = 2; continue; }
      if (this.rol[id] === 2 && enDef > objetivoDef) { this.rol[id] = 0; enDef--; continue; }
      if (this.rol[id] === 0 && enDef < objetivoDef) { this.rol[id] = 2; enDef++; continue; }
      // los lentos y caros nunca van de raid
      if (def?.clase === 'asedio') { if (this.rol[id] === 1) { this.rol[id] = 0; enRaid--; } continue; }
      if (this.rol[id] === 0 && enRaid < objetivoRaid) { this.rol[id] = 1; enRaid++; }
      else if (this.rol[id] === 1 && enRaid > objetivoRaid) { this.rol[id] = 0; enRaid--; }
    }

    // punto de reunión: entre la base y el enemigo
    const b = this._baseEnemigaMasCerca(c);
    const ax = b ? b.x : 0, az = b ? b.z : 0;
    let dx = ax - c.baseX, dz = az - c.baseZ;
    const d = Math.hypot(dx, dz) || 1;
    c.reunionX = c.baseX + (dx / d) * 20;
    c.reunionZ = c.baseZ + (dz / d) * 20;

    // destino de avance del grueso
    if (c.fase === 'ataque' || c.fase === 'asedio') {
      if (b) { c.avanceX = b.x; c.avanceZ = b.z; }
      else {
        // no vio ninguna base: avanza hacia lo desconocido
        this._siguienteExploracion(c);
        c.avanceX = this._sx; c.avanceZ = this._sz;
      }
      if (c.fase === 'ataque' && t > c.raidHasta) {
        c.raidHasta = t + 20;
        this._decidir(c, `Ataque combinado con ${c.militares.length} unidades`);
      }
    } else {
      c.avanceX = c.reunionX; c.avanceZ = c.reunionZ;
    }
  }

  _baseEnemigaMasCerca(c) {
    let mejor = null, mejorD = Infinity;
    for (let i = 0; i < c.basesEnemigas.length; i++) {
      const b = c.basesEnemigas[i];
      const dx = b.x - c.baseX, dz = b.z - c.baseZ;
      const d = dx * dx + dz * dz;
      if (d < mejorD) { mejorD = d; mejor = b; }
    }
    return mejor;
  }

  _grupoCerca(c, x, z, radio) {
    const m = this.ctx.mundo;
    const r2 = radio * radio;
    let n = 0;
    for (let i = 0; i < c.militares.length; i++) {
      const id = c.militares[i];
      if (this.rol[id] === 2) continue;
      const dx = m.px[id] - x, dz = m.pz[id] - z;
      if (dx * dx + dz * dz < r2) n++;
    }
    return n >= 4;
  }

  /* ---------------------------------------------------------------- */
  /* Capa táctica (~4 Hz)                                              */
  /* ---------------------------------------------------------------- */

  _tactico(c, ctx) {
    if (!c.propias.length) return;
    this._explorar(c, ctx);
    this._defenderBase(c, ctx);
    this._microEjercito(c, ctx);
    this._raid(c, ctx);
  }

  /* ---------------- exploración ---------------- */

  _explorar(c, ctx) {
    const m = ctx.mundo;
    const t = m.tiempo;

    // validar explorador
    if (c.explorador >= 0 && (!m.vivo[c.explorador] || m.jugador[c.explorador] !== c.jugador)) {
      c.explorador = -1;
    }
    // al principio explora un colono; en cuanto hay tropa, lo releva
    if (c.explorador >= 0 && this.rol[c.explorador] === 3) {
      const esAldeano = UNIDADES[m.defId[c.explorador]]?.clase === 'aldeano';
      if (esAldeano && c.militares.length > 0) {
        this.rol[c.explorador] = 0;
        this.asignacion[c.explorador] = -1;
        c.explorador = -1;
      }
    }
    if (c.explorador < 0) {
      let elegido = -1;
      for (let i = 0; i < c.militares.length; i++) {
        const id = c.militares[i];
        const def = UNIDADES[m.defId[id]];
        if (def?.clase === 'caballeria') { elegido = id; break; }
        if (elegido < 0 && def?.clase !== 'asedio') elegido = id;
      }
      if (elegido < 0 && t < 200 && c.aldeanos.length > 3) elegido = c.aldeanos[c.aldeanos.length - 1];
      if (elegido >= 0) { c.explorador = elegido; this.rol[elegido] = 3; c.expHasta = 0; }
    }
    if (c.explorador < 0) return;
    if (c.fase === 'defensa') { this.rol[c.explorador] = 0; c.explorador = -1; return; }

    const id = c.explorador;
    const dx = m.px[id] - c.expX, dz = m.pz[id] - c.expZ;
    const llego = dx * dx + dz * dz < 10 * 10;
    if (llego || t > c.expHasta) {
      this._siguienteExploracion(c);
      c.expX = this._sx; c.expZ = this._sz;
      c.expHasta = t + 14;
      this._mover(c, id, c.expX, c.expZ, 0.5);
    }
  }

  /** Espiral hacia afuera, saltando lo ya explorado. */
  _siguienteExploracion(c) {
    const tam = this.ctx.terreno?.tam ?? this.ctx.mapa?.tam ?? 512;
    const lim = tam * 0.47;
    for (let i = 0; i < 40; i++) {
      c.expPaso++;
      const a = c.expFase + c.expPaso * 0.95;
      const r = 45 + (c.expPaso % 26) * 11;
      let x = c.baseX + Math.cos(a) * r;
      let z = c.baseZ + Math.sin(a) * r;
      x = x < -lim ? -lim : x > lim ? lim : x;
      z = z < -lim ? -lim : z > lim ? lim : z;
      if (!this._explorado(c, x, z)) { this._sx = x; this._sz = z; return; }
    }
    this._sx = c.baseX + c.rng.float(-60, 60);
    this._sz = c.baseZ + c.rng.float(-60, 60);
  }

  /* ---------------- defensa de la base ---------------- */

  _defenderBase(c, ctx) {
    if (!c.enPeligro) return;
    const m = ctx.mundo;

    // 1) colonos amenazados al refugio (sede o torreta más cercana)
    for (let i = 0; i < c.amenazasBase.length && i < 24; i++) {
      const eid = c.amenazasBase[i];
      const ex = m.px[eid], ez = m.pz[eid];
      for (let k = 0; k < c.aldeanos.length; k++) {
        const id = c.aldeanos[k];
        if (this.rol[id] === 3) continue;
        const dx = m.px[id] - ex, dz = m.pz[id] - ez;
        if (dx * dx + dz * dz > 18 * 18) continue;
        const ref = this._refugio(c, m.px[id], m.pz[id]);
        if (ref < 0) continue;
        if (!this._puedeOrdenar(id, 2.0)) continue;
        this._guarnecerOMover(c, id, ref);
        this.asignacion[id] = -1;
        this.ocioDesde[id] = -1;
      }
    }

    // 2) el ejército se agrupa y contraataca sobre el intruso más cercano a la base
    let blanco = -1, mejorD = Infinity;
    for (let i = 0; i < c.amenazasBase.length; i++) {
      const eid = c.amenazasBase[i];
      const dx = m.px[eid] - c.baseX, dz = m.pz[eid] - c.baseZ;
      const d = dx * dx + dz * dz;
      if (d < mejorD) { mejorD = d; blanco = eid; }
    }
    if (blanco < 0) return;
    for (let i = 0; i < c.militares.length; i++) {
      const id = c.militares[i];
      if (this.rol[id] === 3) continue;
      if (this.retirado[id]) continue;
      const dx = m.px[id] - m.px[blanco], dz = m.pz[id] - m.pz[blanco];
      if (dx * dx + dz * dz > 90 * 90) { this._mover(c, id, c.baseX, c.baseZ, 2.5); continue; }
      this._atacar(c, id, blanco, 1.5);
    }
  }

  _refugio(c, x, z) {
    const m = this.ctx.mundo;
    let mejor = -1, mejorD = Infinity;
    for (let i = 0; i < c.edificios.length; i++) {
      const id = c.edificios[i];
      const def = EDIFICIOS[m.defId[id]];
      if (!def?.guarnicion && def?.clave !== 'sede') continue;
      if (m.estado[id] === ESTADO.CONSTRUYENDO) continue;
      const dx = m.px[id] - x, dz = m.pz[id] - z;
      const d = dx * dx + dz * dz;
      if (d < mejorD) { mejorD = d; mejor = id; }
    }
    return mejor;
  }

  /* ---------------- micro de combate ---------------- */

  _microEjercito(c, ctx) {
    const m = ctx.mundo;
    const t = m.tiempo;
    if (!c.militares.length) return;

    // centro de masa del grueso
    let cx = 0, cz = 0, n = 0;
    for (let i = 0; i < c.militares.length; i++) {
      const id = c.militares[i];
      if (this.rol[id] !== 0) continue;
      cx += m.px[id]; cz += m.pz[id]; n++;
    }
    if (n > 0) { cx /= n; cz /= n; } else { cx = c.reunionX; cz = c.reunionZ; }

    // dirección de avance
    let dax = c.avanceX - cx, daz = c.avanceZ - cz;
    const dl = Math.hypot(dax, daz) || 1;
    dax /= dl; daz /= dl;

    // blanco concentrado: se enfoca uno solo a la vez
    if (c.cfg.micro && (c.blancoFoco < 0 || !m.vivo[c.blancoFoco] || t > c.blancoHasta)) {
      c.blancoFoco = this._elegirFoco(c, cx, cz);
      c.blancoHasta = t + 2.5;
    }
    const foco = c.cfg.micro ? c.blancoFoco : -1;

    const atacando = c.fase === 'ataque' || c.fase === 'asedio';

    for (let i = 0; i < c.militares.length; i++) {
      const id = c.militares[i];
      const rol = this.rol[id];
      if (rol === 1 || rol === 2 || rol === 3) continue;
      const def = UNIDADES[m.defId[id]];
      if (!def) continue;

      // 1) retirar a los muy heridos (y devolverlos cuando se recuperan)
      if (c.cfg.micro) {
        const vida = m.vidaMax[id] > 0 ? m.vida[id] / m.vidaMax[id] : 1;
        if (!this.retirado[id] && vida < 0.28) {
          this.retirado[id] = 1;
          this._mover(c, id, c.baseX, c.baseZ, 1.0);
          continue;
        }
        if (this.retirado[id]) {
          if (vida > 0.75) this.retirado[id] = 0;
          else continue;
        }
      }

      // 2) la artillería se queda atrás del centro de masa
      if (def.clase === 'asedio') {
        if (atacando) {
          const objArt = this._edificioEnemigoCerca(c, cx, cz, def.alcance + 6);
          if (objArt >= 0) { this._atacar(c, id, objArt, 2.0); continue; }
          this._mover(c, id, cx - dax * 9, cz - daz * 9, 1.6);
        } else {
          this._mover(c, id, c.reunionX - dax * 8, c.reunionZ - daz * 8, 2.5);
        }
        continue;
      }

      // 3) el antiblindaje se pone delante contra tanques y blindados
      if (def.linea === 'antiblindaje' && c.cfg.micro) {
        const tanque = this._enemigoDeClaseCerca(c, m.px[id], m.pz[id], 26, 'caballeria');
        if (tanque >= 0) { this._atacar(c, id, tanque, 1.2); continue; }
      }

      // 4) fuego concentrado
      if (foco >= 0) {
        const dx = m.px[id] - m.px[foco], dz = m.pz[id] - m.pz[foco];
        if (dx * dx + dz * dz < 40 * 40) { this._atacar(c, id, foco, 1.6); continue; }
      }

      // 5) avanzar en línea (o esperar en el punto de reunión)
      if (atacando) {
        this._avanzar(c, id, c.avanceX, c.avanceZ, 2.2);
      } else if (m.estado[id] === ESTADO.QUIETO && !m.tieneDestino[id]) {
        const dx = m.px[id] - c.reunionX, dz = m.pz[id] - c.reunionZ;
        if (dx * dx + dz * dz > 16 * 16) this._mover(c, id, c.reunionX, c.reunionZ, 3.0);
      }
    }
  }

  /** Blanco preferido: primero lo que hace daño y está flojo de vida. */
  _elegirFoco(c, cx, cz) {
    const m = this.ctx.mundo;
    let mejor = -1, mejorP = -Infinity;
    for (let i = 0; i < c.enemigosVistos.length; i++) {
      const id = c.enemigosVistos[i];
      if (!m.vivo[id]) continue;
      const dx = m.px[id] - cx, dz = m.pz[id] - cz;
      const d2 = dx * dx + dz * dz;
      if (d2 > 34 * 34) continue;
      let p = 0;
      if (m.tipo[id] === TIPO.UNIDAD) {
        const def = UNIDADES[m.defId[id]];
        if (!def) continue;
        p = def.clase === 'asedio' ? 90 : def.clase === 'apoyo' ? 80
          : def.clase === 'tirador' ? 60 : def.clase === 'aldeano' ? 55 : 40;
        const vida = m.vidaMax[id] > 0 ? m.vida[id] / m.vidaMax[id] : 1;
        p += (1 - vida) * 50;                    // rematar al herido
      } else {
        const def = EDIFICIOS[m.defId[id]];
        if (!def) continue;
        if (c.fase !== 'asedio' && c.fase !== 'ataque') continue;
        p = def.ataque ? 70 : def.clave === 'sede' ? 45 : 25;
      }
      p -= Math.sqrt(d2) * 1.2;
      if (p > mejorP) { mejorP = p; mejor = id; }
    }
    return mejor;
  }

  _enemigoDeClaseCerca(c, x, z, radio, clase) {
    const m = this.ctx.mundo;
    const r2 = radio * radio;
    let mejor = -1, mejorD = Infinity;
    for (let i = 0; i < c.enemigosVistos.length; i++) {
      const id = c.enemigosVistos[i];
      if (!m.vivo[id] || m.tipo[id] !== TIPO.UNIDAD) continue;
      if (UNIDADES[m.defId[id]]?.clase !== clase) continue;
      const dx = m.px[id] - x, dz = m.pz[id] - z;
      const d = dx * dx + dz * dz;
      if (d < r2 && d < mejorD) { mejorD = d; mejor = id; }
    }
    return mejor;
  }

  _edificioEnemigoCerca(c, x, z, radio) {
    const m = this.ctx.mundo;
    const r2 = radio * radio;
    let mejor = -1, mejorP = -Infinity;
    for (let i = 0; i < c.enemigosVistos.length; i++) {
      const id = c.enemigosVistos[i];
      if (!m.vivo[id] || m.tipo[id] !== TIPO.EDIFICIO) continue;
      const def = EDIFICIOS[m.defId[id]];
      if (!def) continue;
      const dx = m.px[id] - x, dz = m.pz[id] - z;
      const d = dx * dx + dz * dz;
      if (d > r2) continue;
      // primero lo que dispara, después los muros que traban el avance, después el resto
      let p = def.ataque ? 100 : def.muro ? 70 : def.entrena ? 55 : 30;
      p -= Math.sqrt(d);
      if (p > mejorP) { mejorP = p; mejor = id; }
    }
    return mejor;
  }

  /* ---------------- hostigamiento ---------------- */

  _raid(c, ctx) {
    if (!c.cfg.raids) return;
    const m = ctx.mundo;
    const t = m.tiempo;

    let hayRaiders = false;
    for (let i = 0; i < c.militares.length; i++) if (this.rol[c.militares[i]] === 1) { hayRaiders = true; break; }
    if (!hayRaiders) return;

    // edificios enemigos vistos (scratch reutilizado) para medir aislamiento
    const edif = this._cerca;
    edif.length = 0;
    for (let i = 0; i < c.enemigosVistos.length; i++) {
      const id = c.enemigosVistos[i];
      if (m.vivo[id] && m.tipo[id] === TIPO.EDIFICIO) edif.push(id);
    }

    // blanco de raid: recolector enemigo aislado (lejos de sus edificios)
    let blanco = -1, mejorP = -Infinity;
    for (let i = 0; i < c.enemigosVistos.length; i++) {
      const id = c.enemigosVistos[i];
      if (!m.vivo[id] || m.tipo[id] !== TIPO.UNIDAD) continue;
      const def = UNIDADES[m.defId[id]];
      if (def?.clase !== 'aldeano') continue;
      let aislamiento = 200;
      for (let k = 0; k < edif.length; k++) {
        const o = edif[k];
        const dx = m.px[o] - m.px[id], dz = m.pz[o] - m.pz[id];
        const d = Math.sqrt(dx * dx + dz * dz);
        if (d < aislamiento) aislamiento = d;
      }
      const dbx = m.px[id] - c.baseX, dbz = m.pz[id] - c.baseZ;
      const p = aislamiento * 2 - Math.sqrt(dbx * dbx + dbz * dbz) * 0.5;
      if (p > mejorP) { mejorP = p; blanco = id; }
    }

    for (let i = 0; i < c.militares.length; i++) {
      const id = c.militares[i];
      if (this.rol[id] !== 1) continue;
      if (blanco >= 0) {
        this._atacar(c, id, blanco, 1.8);
        if (t > c.raidHasta) { c.raidHasta = t + 25; this._decidir(c, 'Raid sobre recolectores enemigos'); }
      } else {
        // sin blanco a la vista: patrullar hacia la base enemiga conocida
        const b = this._baseEnemigaMasCerca(c);
        if (b) this._avanzar(c, id, b.x, b.z, 4.0);
        else this._mover(c, id, c.reunionX, c.reunionZ, 4.0);
      }
    }
  }

  /* ---------------------------------------------------------------- */
  /* Fachada de órdenes (todo pasa por ctx.ordenes, con degradación)   */
  /* ---------------------------------------------------------------- */

  _puedeOrdenar(id, minimo) {
    const t = this.ctx.mundo.tiempo;
    if (t - this.ultimaOrden[id] < minimo) return false;
    this.ultimaOrden[id] = t;
    return true;
  }

  _mover(c, id, x, z, espera = 1.0) {
    if (!this._puedeOrdenar(id, espera)) return false;
    return this._invocar(['mover', 'moverA', 'irA'], [[id], x, z]);
  }

  _avanzar(c, id, x, z, espera = 1.0) {
    if (!this._puedeOrdenar(id, espera)) return false;
    if (this._invocar(['atacarMover', 'avanzar', 'moverAtacando'], [[id], x, z])) return true;
    return this._invocar(['mover', 'moverA', 'irA'], [[id], x, z]);
  }

  _atacar(c, id, objetivo, espera = 1.0) {
    if (objetivo < 0) return false;
    if (!this._puedeOrdenar(id, espera)) return false;
    return this._invocar(['atacar', 'atacarA'], [[id], objetivo]);
  }

  _recolectar(c, id, nodo) {
    return this._invocar(['recolectar', 'juntar', 'cosechar'], [[id], nodo]);
  }

  _guarnecerOMover(c, id, edificio) {
    const m = this.ctx.mundo;
    if (this._invocar(['guarnecer', 'refugiar', 'entrar'], [[id], edificio])) return true;
    return this._invocar(['mover', 'moverA', 'irA'], [[id], m.px[edificio], m.pz[edificio]]);
  }

  _entrenar(c, edificio, clave) {
    if (this._invocar(['entrenar', 'encolarUnidad', 'producir'], [edificio, clave, 1])) return true;
    try {
      return !!this.ctx.produccion?.encolarUnidad?.(edificio, clave, 1);
    } catch (e) { this._error('entrenar', e); return false; }
  }

  _investigarEn(c, edificio, clave) {
    if (this._invocar(['investigar', 'encolarTecnologia'], [edificio, clave])) return true;
    try {
      return !!this.ctx.produccion?.encolarTecnologia?.(edificio, clave);
    } catch (e) { this._error('investigar', e); return false; }
  }

  _pedirAvanceEdad(c, sede) {
    const o = this.ctx.ordenes, ed = this.ctx.edades;
    const intentos = [
      [o, 'avanzarEdad'], [o, 'subirEdad'], [ed, 'avanzar'], [ed, 'avanzarEdad'],
      [ed, 'iniciarAvance'], [ed, 'solicitarAvance'],
    ];
    for (let i = 0; i < intentos.length; i++) {
      const [obj, nombre] = intentos[i];
      const fn = obj?.[nombre];
      if (typeof fn !== 'function') continue;
      try {
        const r = fn.length >= 2 ? fn.call(obj, c.jugador, sede) : fn.call(obj, c.jugador);
        return r !== false;
      } catch (e) { this._error(nombre, e); return false; }
    }
    return false;
  }

  /**
   * Emplaza un edificio con colonos libres. Busca sitio válido con la misma
   * validación que usa el jugador humano, así nunca dispara avisos de error.
   */
  _construir(c, clave, cx, cz, radioMin, radioMax, obreros) {
    const ctx = this.ctx;
    const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];
    if (!def) return false;
    if (!this._buscarSitio(c, clave, cx, cz, radioMin, radioMax)) return false;
    const x = this._sx, z = this._sz;

    // colonos más cercanos que no estén construyendo
    const elegidos = [];
    const m = ctx.mundo;
    for (let paso = 0; paso < 2 && elegidos.length < obreros; paso++) {
      let mejor = -1, mejorD = Infinity;
      for (let i = 0; i < c.aldeanos.length; i++) {
        const id = c.aldeanos[i];
        if (this.rol[id] === 3 || this.rol[id] === 4) continue;
        if (elegidos.indexOf(id) >= 0) continue;
        if (paso === 0 && m.estado[id] === ESTADO.CONSTRUYENDO) continue;
        const dx = m.px[id] - x, dz = m.pz[id] - z;
        const d = dx * dx + dz * dz;
        if (d < mejorD) { mejorD = d; mejor = id; }
      }
      if (mejor >= 0) elegidos.push(mejor); else break;
    }
    if (!elegidos.length) return false;

    let ok = this._invocar(['construir', 'edificar', 'colocar'], [elegidos, clave, x, z]);
    if (!ok) {
      // degradado: emplazar por producción y mandar a los colonos a la obra
      try {
        const chequeo = ctx.produccion?.puedeEmplazar?.(c.jugador, clave, x, z);
        if (chequeo && !chequeo.puede) return false;
        const eid = ctx.produccion?.emplazar?.(c.jugador, clave, x, z, 0);
        if (eid == null || eid < 0) return false;
        for (let i = 0; i < elegidos.length; i++) {
          ctx.produccion?.asignarObrero?.(eid, elegidos[i], true);
          this._invocar(['construir', 'ayudarObra', 'reparar'], [[elegidos[i]], eid]) ||
            this._invocar(['mover', 'moverA'], [[elegidos[i]], x, z]);
        }
        ok = true;
      } catch (e) { this._error('construir', e); return false; }
    }
    if (!ok) return false;

    for (let i = 0; i < elegidos.length; i++) {
      this.asignacion[elegidos[i]] = -1;
      this.ocioDesde[elegidos[i]] = -1;
      this.ultimaOrden[elegidos[i]] = ctx.mundo.tiempo;
    }
    c.obras.push({ clave, x, z, hasta: ctx.mundo.tiempo + Math.max(20, (def.tiempo || 30) * 1.6) });
    return true;
  }

  /** Sitio libre alrededor de (cx,cz): valida con Produccion si está disponible. */
  _buscarSitio(c, clave, cx, cz, radioMin, radioMax) {
    const ctx = this.ctx;
    const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];
    const radio = Math.max(def.celdas[0], def.celdas[1]) + 1.0;
    const tam = ctx.terreno?.tam ?? ctx.mapa?.tam ?? 512;
    const lim = tam * 0.48;

    for (let intento = 0; intento < 26; intento++) {
      const a = c.rng.float(0, Math.PI * 2);
      const r = radioMin + (radioMax - radioMin) * Math.sqrt(c.rng.float());
      const x = cx + Math.cos(a) * r;
      const z = cz + Math.sin(a) * r;
      if (x < -lim || x > lim || z < -lim || z > lim) continue;

      const p = ctx.produccion?.puedeEmplazar;
      if (typeof p === 'function') {
        let r2;
        try { r2 = p.call(ctx.produccion, c.jugador, clave, x, z); } catch (e) { this._error('puedeEmplazar', e); return false; }
        if (!r2?.puede) continue;
      } else {
        if (ctx.terreno?.transitable && !ctx.terreno.transitable(x, z)) continue;
        if ((ctx.terreno?.pendiente?.(x, z) ?? 0) > 0.3) continue;
        if (ctx.nav?.esLibre && !ctx.nav.esLibre(x, z, radio)) continue;
        const cerca = ctx.mundo.cerca(x, z, radio + 2, this._cerca);
        let choca = false;
        for (let i = 0; i < cerca.length; i++) {
          if (ctx.mundo.tipo[cerca[i]] === TIPO.UNIDAD) continue;
          choca = true; break;
        }
        if (choca) continue;
      }
      this._sx = x; this._sz = z;
      return true;
    }
    return false;
  }

  /* ---------------------------------------------------------------- */
  /* Utilidades                                                        */
  /* ---------------------------------------------------------------- */

  _invocar(nombres, args) {
    const o = this.ctx.ordenes;
    if (!o) return false;
    for (let i = 0; i < nombres.length; i++) {
      const fn = o[nombres[i]];
      if (typeof fn !== 'function') continue;
      try {
        const r = fn.apply(o, args);
        return r !== false;
      } catch (e) { this._error(nombres[i], e); return false; }
    }
    return false;
  }

  _largoCola(edificio) {
    const meta = this.ctx.mundo.meta.get(edificio);
    const cola = meta?.cola;
    if (Array.isArray(cola)) return cola.length;
    if (typeof cola === 'number') return cola;
    return 0;
  }

  _puedePagar(c, coste, reservaEdad = 0) {
    if (!coste) return false;
    const eco = this.ctx.eco;
    const rec = eco?.recursos?.[c.jugador];
    if (!rec) return false;
    let reserva = null;
    if (reservaEdad > 0) {
      const sig = EDADES[Math.min(EDADES.length - 1, this._edad(c) + 1)];
      reserva = sig?.coste || null;
    }
    for (let i = 0; i < CLAVES_REC.length; i++) {
      const k = CLAVES_REC[i];
      const necesita = (coste[k] ?? 0) + (reserva ? (reserva[k] ?? 0) * reservaEdad : 0);
      if ((rec[k] ?? 0) < necesita) return false;
    }
    return true;
  }

  _puedePagarClave(c, clave) {
    const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];
    if (!def) return false;
    return this._puedePagar(c, def.coste, c.ahorrandoEdad && clave !== 'vivienda' ? 0.5 : 0);
  }

  _decidir(c, texto) {
    if (c.ultimaDecision === texto) return;
    c.ultimaDecision = texto;
    bus.emit('ia:decision', { jugador: c.jugador, texto });
  }

  _error(donde, e) {
    if (this._fallos.has(donde)) return;
    this._fallos.add(donde);
    console.warn(`[IA] falló "${donde}":`, e?.message ?? e);
  }
}
