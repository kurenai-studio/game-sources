/**
 * EDADES Y TECNOLOGÍAS — el eje temporal de 1800 a 2100.
 *
 * Se ocupa de: avanzar de edad (coste, temporizador, bonos, remodelado visual),
 * investigar tecnologías en un edificio concreto y aplicar el mod de la
 * civilización de cada jugador al arrancar la partida.
 *
 * Contrato público:
 *   edades.edad[jugador]            -> 0..4
 *   edades.progresoAvance[jugador]  -> 0..1
 *   edades.avanzar(jugador)         -> boolean
 *   edades.investigar(jugador, claveTecno, edificioId) -> boolean
 *   edades.investigadas[jugador]    -> Set<string>
 *   edades.puedeInvestigar(jugador, claveTecno) -> { puede, motivo }
 *   edades.aplicarCiv(jugador, claveCiv)
 *
 * Eventos que emite:
 *   'edad:avanzada'   { jugador, edad }
 *   'edad:remodelar'  { jugador, edad }     ← VistaEntidades reconstruye las mallas
 *   'tecno:completada'{ jugador, clave }
 *   'tecno:iniciada'  { jugador, clave, edificio }
 */

import { EDADES } from '../data/edades.js';
import { TECNOLOGIAS, TECNO_POR_CLAVE } from '../data/tecnologias.js';
import { CIVILIZACIONES, CIV_POR_CLAVE } from '../data/civilizaciones.js';
import { EDIFICIOS } from '../data/edificios.js';
import { TIPO, ESTADO } from '../core/World.js';
import { ORDEN } from '../core/Ctx.js';
import { bus as busGlobal } from '../core/EventBus.js';

const MAX_JUGADORES = 8;

/**
 * Bonos mecánicos de cada edad. Traducen a números lo que EDADES[n].bonos
 * promete en texto. Se aplican una sola vez, al completarse el avance.
 */
const BONOS_EDAD = [
  null,
  /* Eléctrica: '+15% velocidad de recolección' */
  (m) => { for (const k in m.velRecoleccion) m.velRecoleccion[k] *= 1.15; },
  /* Atómica: los muros pasan a hormigón */
  (m) => { m.vidaEdificioDefensa *= 1.10; },
  /* Información: '+2 de visión a todas las unidades' */
  (m) => { for (const k in m.vision) m.vision[k] += 2; },
  /* Sintética: 'los edificios se autorreparan' */
  (m) => { m.autorreparacion = Math.max(m.autorreparacion, 1.5); },
];

/**
 * Extras de civilización que el texto promete y `mod()` no puede expresar
 * porque dependen de la edad o de la población.
 */
const EXTRAS_CIV = {
  sovietica: { alIniciar: (m) => { m.popExtraVivienda += 1; } },
  estadounidense: { alLlegarEdad: { 2: (m) => { m.popExtraVivienda += 5; } } },
  britanica: { porEdadDesde: 1, porEdad: (m) => { m.alcance.tirador += 1; } },
  sintetica: { alLlegarEdad: { 2: (m) => { m.autorreparacion = Math.max(m.autorreparacion, 1.0); } } },
};

export class SistemaEdades {
  constructor(ctx) {
    this.ctx = ctx;
    this.nombre = 'edades';
    this.orden = ORDEN.ECONOMIA;
    this.bus = ctx.bus || busGlobal;

    this.edad = new Array(MAX_JUGADORES).fill(0);
    this.progresoAvance = new Array(MAX_JUGADORES).fill(0);
    this.investigadas = [];
    this.civ = new Array(MAX_JUGADORES).fill(null);
    this.edificioAvance = new Array(MAX_JUGADORES).fill(-1);

    this._restanteEdad = new Float32Array(MAX_JUGADORES);
    this._totalEdad = new Float32Array(MAX_JUGADORES);
    for (let j = 0; j < MAX_JUGADORES; j++) this.investigadas.push(new Set());

    /** Investigaciones en curso: se crean sólo al iniciar, nunca por tick. */
    this.investigaciones = [];

    /* civilizaciones: las toma de donde el generador/lobby las haya dejado */
    this._civInicial();
    this.bus.once('juego:listo', () => this._civInicial());
  }

  /* =================================================================== *
   * Civilizaciones
   * =================================================================== */

  _civInicial() {
    const ctx = this.ctx;
    const fuente = ctx.civilizaciones || ctx.mapa?.civilizaciones || ctx.mapa?.civs || null;
    const cantidad = ctx.mapa?.inicios?.length || 2;
    for (let j = 0; j < MAX_JUGADORES; j++) {
      if (this.civ[j]) continue;
      if (j >= cantidad && !fuente?.[j]) continue;
      const clave = fuente?.[j] || CIVILIZACIONES[j % CIVILIZACIONES.length].clave;
      this.aplicarCiv(j, clave);
    }
  }

  /** Aplica (una sola vez) el mod de la civilización al objeto de modificadores. */
  aplicarCiv(jugador, claveCiv) {
    if (this.civ[jugador] === claveCiv) return false;
    const idx = CIV_POR_CLAVE.get(claveCiv);
    if (idx === undefined) return false;
    const def = CIVILIZACIONES[idx];
    const m = this._mods(jugador);
    if (!m) return false;
    if (this.civ[jugador]) {
      console.warn('[edades] la civilización ya estaba fijada; los mods no se revierten');
      return false;
    }
    this.civ[jugador] = claveCiv;
    try { def.mod?.(m, jugador); } catch (e) { console.error('[edades] mod de civilización', e); }
    EXTRAS_CIV[claveCiv]?.alIniciar?.(m);
    this.bus.emit('civ:asignada', { jugador, clave: claveCiv, nombre: def.nombre, color: def.color });
    return true;
  }

  civDe(jugador) { return this.civ[jugador]; }
  defCiv(jugador) {
    const i = CIV_POR_CLAVE.get(this.civ[jugador]);
    return i === undefined ? null : CIVILIZACIONES[i];
  }

  /* =================================================================== *
   * Avance de edad
   * =================================================================== */

  /** Coste del próximo avance con el descuento de civilización aplicado. */
  costeAvance(jugador) {
    const prox = this.edad[jugador] + 1;
    if (prox >= EDADES.length) return null;
    const base = EDADES[prox].coste;
    if (!base) return null;
    const f = this._mods(jugador)?.descuentoEdad ?? 1;
    return {
      alimento: Math.round((base.alimento || 0) * f),
      materiales: Math.round((base.materiales || 0) * f),
      capital: Math.round((base.capital || 0) * f),
      energia: Math.round((base.energia || 0) * f),
    };
  }

  puedeAvanzar(jugador) {
    if (this.edad[jugador] >= EDADES.length - 1) return { puede: false, motivo: 'Ya estás en la última edad.' };
    if (this._restanteEdad[jugador] > 0) return { puede: false, motivo: 'Ya estás avanzando de edad.' };
    if (this._sedeDe(jugador) < 0) return { puede: false, motivo: 'Necesitás una Sede Municipal en pie.' };
    if (!this.ctx.eco?.puedePagar(jugador, this.costeAvance(jugador))) {
      return { puede: false, motivo: 'No te alcanzan los recursos.' };
    }
    return { puede: true, motivo: '' };
  }

  /** Cobra el coste y arranca el temporizador del avance. */
  avanzar(jugador) {
    const v = this.puedeAvanzar(jugador);
    if (!v.puede) {
      if (jugador === this.ctx.jugadorLocal) this.bus.emit('aviso', { texto: v.motivo, tipo: 'alerta' });
      return false;
    }
    const coste = this.costeAvance(jugador);
    if (!this.ctx.eco.pagar(jugador, coste)) return false;

    const prox = this.edad[jugador] + 1;
    const vel = this._mods(jugador)?.velInvestigacion || 1;
    this._totalEdad[jugador] = Math.max(1, EDADES[prox].tiempo / vel);
    this._restanteEdad[jugador] = this._totalEdad[jugador];
    this.progresoAvance[jugador] = 0;
    this.edificioAvance[jugador] = this._sedeDe(jugador);

    this.bus.emit('edad:iniciada', { jugador, edad: prox, tiempo: this._totalEdad[jugador] });
    if (jugador === this.ctx.jugadorLocal) {
      this.bus.emit('aviso', { texto: `Avanzando a la ${EDADES[prox].nombre}…`, tipo: 'info' });
      this.ctx.audio?.sfx?.('edad_inicia');
    }
    return true;
  }

  _completarEdad(jugador) {
    const ctx = this.ctx;
    const n = Math.min(EDADES.length - 1, this.edad[jugador] + 1);
    this.edad[jugador] = n;
    this._restanteEdad[jugador] = 0;
    this.progresoAvance[jugador] = 1;
    this.edificioAvance[jugador] = -1;

    const m = this._mods(jugador);
    if (m) {
      try { BONOS_EDAD[n]?.(m, jugador); } catch (e) { console.error('[edades] bono de edad', e); }
      const extra = EXTRAS_CIV[this.civ[jugador]];
      if (extra) {
        extra.alLlegarEdad?.[n]?.(m);
        if (extra.porEdad && n >= (extra.porEdadDesde ?? 0)) extra.porEdad(m);
      }
    }

    this.bus.emit('edad:avanzada', { jugador, edad: n });
    this.bus.emit('edad:remodelar', { jugador, edad: n });

    if (jugador === ctx.jugadorLocal) {
      ctx.cielo?.setEdad?.(n);
      ctx.agua?.setEdad?.(n);
      ctx.audio?.musicaEdad?.(n);
      ctx.audio?.sfx?.('edad_lista');
      this.bus.emit('aviso', { texto: `${EDADES[n].nombre} — ${EDADES[n].lema}`, tipo: 'info' });
    }
  }

  /* =================================================================== *
   * Tecnologías
   * =================================================================== */

  /** Coste de una tecnología con los descuentos de civilización. */
  costeTecno(jugador, clave) {
    const def = this._defTecno(clave);
    if (!def) return null;
    const m = this._mods(jugador);
    const f = (def.en === 'fundicion' ? (m?.descuentoFundicion ?? 1) : 1);
    const c = def.coste;
    return {
      alimento: Math.round((c.alimento || 0) * f),
      materiales: Math.round((c.materiales || 0) * f),
      capital: Math.round((c.capital || 0) * f),
      energia: Math.round((c.energia || 0) * f),
    };
  }

  puedeInvestigar(jugador, claveTecno) {
    const def = this._defTecno(claveTecno);
    if (!def) return { puede: false, motivo: 'Tecnología desconocida.' };
    if (this.investigadas[jugador].has(claveTecno)) return { puede: false, motivo: 'Ya la investigaste.' };
    if (this._enCurso(jugador, claveTecno)) return { puede: false, motivo: 'Ya se está investigando.' };
    if (this.edad[jugador] < def.edad) {
      return { puede: false, motivo: `Requiere la ${EDADES[def.edad].nombre}.` };
    }
    if (def.requiere && !this.investigadas[jugador].has(def.requiere)) {
      const prev = this._defTecno(def.requiere);
      return { puede: false, motivo: `Requiere ${prev ? prev.nombre : def.requiere}.` };
    }
    if (this._edificioLibre(jugador, def.en) < 0) {
      const ed = EDIFICIOS.find((e) => e.clave === def.en);
      return { puede: false, motivo: `Necesitás ${ed ? ed.nombre : def.en} disponible.` };
    }
    if (!this.ctx.eco?.puedePagar(jugador, this.costeTecno(jugador, claveTecno))) {
      return { puede: false, motivo: 'No te alcanzan los recursos.' };
    }
    return { puede: true, motivo: '' };
  }

  /** Arranca una investigación en un edificio concreto (o en el primero libre). */
  investigar(jugador, claveTecno, edificioId = -1) {
    const v = this.puedeInvestigar(jugador, claveTecno);
    if (!v.puede) {
      if (jugador === this.ctx.jugadorLocal) this.bus.emit('aviso', { texto: v.motivo, tipo: 'alerta' });
      return false;
    }
    const def = this._defTecno(claveTecno);
    let ed = edificioId;
    if (ed < 0 || !this._edificioSirve(ed, jugador, def.en)) ed = this._edificioLibre(jugador, def.en);
    if (ed < 0) return false;

    if (!this.ctx.eco.pagar(jugador, this.costeTecno(jugador, claveTecno))) return false;

    const vel = this._mods(jugador)?.velInvestigacion || 1;
    const total = Math.max(0.5, def.tiempo / vel);
    this.investigaciones.push({ jugador, clave: claveTecno, edificio: ed, restante: total, total });

    this.bus.emit('tecno:iniciada', { jugador, clave: claveTecno, edificio: ed, tiempo: total });
    if (jugador === this.ctx.jugadorLocal) {
      this.bus.emit('aviso', { texto: `Investigando ${def.nombre}…`, tipo: 'info' });
      this.ctx.audio?.sfx?.('tecno_inicia');
    }
    return true;
  }

  /** Investigación en curso en un edificio (para el HUD). */
  enProgreso(edificioId) {
    for (let i = 0; i < this.investigaciones.length; i++) {
      const t = this.investigaciones[i];
      if (t.edificio === edificioId) {
        return { clave: t.clave, progreso: 1 - t.restante / t.total, restante: t.restante };
      }
    }
    return null;
  }

  /** Tecnologías que el jugador puede ver en la ficha de ese edificio. */
  tecnosDe(jugador, claveEdificio) {
    const salida = [];
    for (let i = 0; i < TECNOLOGIAS.length; i++) {
      const def = TECNOLOGIAS[i];
      if (def.en !== claveEdificio) continue;
      if (this.investigadas[jugador].has(def.clave)) continue;
      if (def.requiere && !this.investigadas[jugador].has(def.requiere)) continue;
      salida.push(def);
    }
    return salida;
  }

  _completarTecno(t) {
    const def = this._defTecno(t.clave);
    const m = this._mods(t.jugador);
    this.investigadas[t.jugador].add(t.clave);
    if (m && def) {
      try { def.efecto?.(m, t.jugador); } catch (e) { console.error('[edades] efecto de tecnología', t.clave, e); }
    }
    this.bus.emit('tecno:completada', { jugador: t.jugador, clave: t.clave });
    if (t.jugador === this.ctx.jugadorLocal) {
      this.bus.emit('aviso', { texto: `${def ? def.nombre : t.clave}: listo.`, tipo: 'info' });
      this.ctx.audio?.sfx?.('tecno_lista');
    }
  }

  /* =================================================================== *
   * Bucle de simulación (20 Hz)
   * =================================================================== */

  fijo(dt, ctx) {
    /* avance de edad */
    for (let j = 0; j < MAX_JUGADORES; j++) {
      if (this._restanteEdad[j] <= 0) continue;
      const sede = this.edificioAvance[j];
      if (sede >= 0 && !ctx.mundo.vivo[sede]) {
        /* le voltearon la Sede en medio del avance: se busca otra o se cancela */
        const otra = this._sedeDe(j);
        if (otra < 0) {
          this._restanteEdad[j] = 0;
          this.progresoAvance[j] = 0;
          this.ctx.eco?.reembolsar(j, this.costeAvance(j));
          if (j === ctx.jugadorLocal) this.bus.emit('aviso', { texto: 'Se interrumpió el avance de edad.', tipo: 'error' });
          continue;
        }
        this.edificioAvance[j] = otra;
      }
      this._restanteEdad[j] -= dt;
      this.progresoAvance[j] = 1 - Math.max(0, this._restanteEdad[j]) / this._totalEdad[j];
      if (this._restanteEdad[j] <= 0) this._completarEdad(j);
    }

    /* investigaciones */
    for (let i = this.investigaciones.length - 1; i >= 0; i--) {
      const t = this.investigaciones[i];
      if (!ctx.mundo.vivo[t.edificio] || ctx.mundo.estado[t.edificio] === ESTADO.CONSTRUYENDO) {
        this.ctx.eco?.reembolsar(t.jugador, this.costeTecno(t.jugador, t.clave));
        this.bus.emit('tecno:cancelada', { jugador: t.jugador, clave: t.clave });
        this.investigaciones.splice(i, 1);
        continue;
      }
      t.restante -= dt;
      if (t.restante <= 0) {
        this._completarTecno(t);
        this.investigaciones.splice(i, 1);
      }
    }
  }

  /* =================================================================== *
   * Utilidades
   * =================================================================== */

  _mods(jugador) { return this.ctx.eco?.mods?.[jugador] || null; }

  _defTecno(clave) {
    const i = TECNO_POR_CLAVE.get(clave);
    return i === undefined ? null : TECNOLOGIAS[i];
  }

  _enCurso(jugador, clave) {
    for (let i = 0; i < this.investigaciones.length; i++) {
      const t = this.investigaciones[i];
      if (t.jugador === jugador && t.clave === clave) return true;
    }
    return false;
  }

  _ocupado(edificioId) {
    for (let i = 0; i < this.investigaciones.length; i++) {
      if (this.investigaciones[i].edificio === edificioId) return true;
    }
    return false;
  }

  _edificioSirve(id, jugador, clave) {
    const m = this.ctx.mundo;
    if (id < 0 || !m.vivo[id] || m.tipo[id] !== TIPO.EDIFICIO) return false;
    if (m.jugador[id] !== jugador) return false;
    if (m.estado[id] === ESTADO.CONSTRUYENDO) return false;
    if (EDIFICIOS[m.defId[id]]?.clave !== clave) return false;
    return !this._ocupado(id);
  }

  /** Primer edificio de esa clave, terminado y sin investigación en curso. */
  _edificioLibre(jugador, clave) {
    const m = this.ctx.mundo;
    if (!m) return -1;
    for (let id = 0; id < m.maxUsado; id++) {
      if (this._edificioSirve(id, jugador, clave)) return id;
    }
    return -1;
  }

  _sedeDe(jugador) {
    const m = this.ctx.mundo;
    if (!m) return -1;
    for (let id = 0; id < m.maxUsado; id++) {
      if (!m.vivo[id] || m.tipo[id] !== TIPO.EDIFICIO || m.jugador[id] !== jugador) continue;
      if (m.estado[id] === ESTADO.CONSTRUYENDO) continue;
      if (EDIFICIOS[m.defId[id]]?.clave === 'sede') return id;
    }
    return -1;
  }
}
