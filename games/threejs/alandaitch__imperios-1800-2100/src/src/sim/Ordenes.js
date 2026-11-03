/**
 * Ordenes — la fachada por la que TODO el juego (UI e IA) le pide cosas a las
 * unidades y a los edificios. Nadie escribe órdenes a mano en el World: se pasa
 * por acá, porque acá se validan costes, población, edad y requisitos, y acá
 * vive la cola de órdenes (Shift encola, tal cual AoE2).
 *
 * Cómo se reparte el trabajo con los demás sistemas:
 *   · Ordenes escribe la INTENCIÓN en el World (destinoX/Z, tieneDestino,
 *     objetivo, estado) y vigila cuándo la orden se dio por cumplida.
 *   · Movimiento mueve, Combate golpea, Economia recolecta y deposita,
 *     Produccion entrena e investiga. Ordenes no les pisa el trabajo: en cuanto
 *     el otro sistema toma el mando (por ejemplo estado = DEPOSITANDO) se corre
 *     al costado y sólo vuelve a intervenir cuando la unidad queda libre.
 *   · Si un sistema todavía no existe, Ordenes degrada con una implementación
 *     mínima propia (obras, reparación, entrenamiento) para que el juego se
 *     pueda jugar igual. Nunca tira una excepción hacia el arranque.
 *
 * Convención de metadatos compartidos: `mundo.meta.get(id)` es un objeto suelto;
 * acá se usan `postura` ('libre'|'mantener'|'patrulla'|'ataque') y `obra`.
 */

import { ORDEN } from '../core/Ctx.js';
import { TIPO, ESTADO } from '../core/World.js';
import { bus } from '../core/EventBus.js';
import { UNIDADES, UNIDAD_POR_CLAVE } from '../data/unidades.js';
import { EDIFICIOS, EDIFICIO_POR_CLAVE } from '../data/edificios.js';
import { TECNOLOGIAS, TECNO_POR_CLAVE } from '../data/tecnologias.js';
import { NODOS, CLAVES_RECURSO } from '../data/recursos.js';
import { EDADES } from '../data/edades.js';

const VACIO = Object.freeze([]);
const FALTA = [
  'No alcanza el Alimento',
  'No alcanzan los Materiales',
  'No alcanza el Capital',
  'No alcanza la Energía',
];
const CLASES_RECOLECTORAS = new Set(['aldeano']);
/** cada cuánto se recalcula una persecución (segundos de simulación) */
const REPATH = 0.45;

export class Ordenes {
  constructor(ctx) {
    this.nombre = 'ordenes';
    this.orden = ORDEN.ENTRADA;
    this.ctx = ctx;

    /** @type {Map<number, Array<Object>>} cola de órdenes por entidad */
    this.colas = new Map();
    /** obras que administra este módulo (sólo si Produccion no las tomó) */
    this.obras = new Map();          // idObra -> { def, tiempo, jugador }
    /** reparaciones en curso: idEdificio -> Set<idColono> */
    this.reparaciones = new Map();
    /** punto de reunión por edificio */
    this.reuniones = new Map();      // idEdificio -> {x, z}
    /** guarniciones administradas acá (fallback) */
    this.guarniciones = new Map();   // idEdificio -> Array<snapshot>
    /** colas de producción internas (fallback) */
    this.produccionPropia = new Map(); // idEdificio -> Array<{clave, tipo, restante, total}>
    /** tecnologías completadas por jugador (fallback / consulta) */
    this.tecnos = [];

    this._cerca = [];
    this._tmp = [];
    this._slots = [];
    this._orden = [];
    this._dt = 0;
    this._hooks = null;

    this._pasoCola = this._pasoCola.bind(this);
    this._pasoObra = this._pasoObra.bind(this);
    this._pasoReparacion = this._pasoReparacion.bind(this);
    this._pasoProduccion = this._pasoProduccion.bind(this);

    // punto de reunión: si Produccion no lo aplica, lo aplicamos nosotros.
    bus.on('entidad:creada', (id) => this._quizasReunion(id));
  }

  /* ================================================================
   *  API pública
   * ================================================================ */

  /** Mueve el grupo a (x,z) repartiendo posiciones para que no se apilen. */
  mover(ids, x, z, encolar = false) {
    const lista = this._propias(ids, true);
    if (!lista.length) return false;
    this._repartir(lista, x, z);
    for (let i = 0; i < lista.length; i++) {
      const id = lista[i];
      const o = this._nueva('mover');
      o.x = this._slots[i * 2]; o.z = this._slots[i * 2 + 1];
      this._empujar(id, o, encolar);
    }
    this._marca(x, z, 'mover');
    this.ctx.audio?.sfx?.('orden', { x, z });
    return true;
  }

  /** Ataca a una entidad concreta. */
  atacar(ids, objetivoId, encolar = false) {
    const w = this.ctx.mundo;
    if (!(objetivoId >= 0) || !w.vivo[objetivoId]) return false;
    const lista = this._propias(ids, true);
    if (!lista.length) return false;
    let alguna = false;
    for (let i = 0; i < lista.length; i++) {
      const id = lista[i];
      if (this._ataque(id) <= 0 && !this._esConstructor(id)) {
        // apoyo/comercio: no pelean, van hasta ahí y listo
        const o = this._nueva('mover'); o.x = w.px[objetivoId]; o.z = w.pz[objetivoId];
        this._empujar(id, o, encolar);
        continue;
      }
      const o = this._nueva('atacar');
      o.obj = objetivoId;
      this._empujar(id, o, encolar);
      alguna = true;
    }
    if (alguna) {
      this._marca(w.px[objetivoId], w.pz[objetivoId], 'atacar');
      this.ctx.audio?.sfx?.('orden_ataque', { x: w.px[objetivoId], z: w.pz[objetivoId] });
    }
    return alguna;
  }

  /** Ataque en área: avanza hasta (x,z) enganchando todo lo hostil del camino. */
  atacarLugar(ids, x, z, encolar = false) {
    const lista = this._propias(ids, true);
    if (!lista.length) return false;
    this._repartir(lista, x, z);
    for (let i = 0; i < lista.length; i++) {
      const o = this._nueva('ataqueLugar');
      o.x = this._slots[i * 2]; o.z = this._slots[i * 2 + 1];
      o.obj = -1;
      this._empujar(lista[i], o, encolar);
      this._metaDe(lista[i]).postura = 'ataque';
    }
    this._marca(x, z, 'atacar');
    return true;
  }

  /** Manda a recolectar un nodo (árbol, baya, veta, granja…). */
  recolectar(ids, nodoId, encolar = false) {
    const w = this.ctx.mundo;
    if (!(nodoId >= 0) || !w.vivo[nodoId]) return false;
    const lista = this._propias(ids, true);
    if (!lista.length) return false;
    let alguna = false;
    for (let i = 0; i < lista.length; i++) {
      const id = lista[i];
      if (!this._puedeRecolectar(id, nodoId)) {
        const o = this._nueva('mover'); o.x = w.px[nodoId]; o.z = w.pz[nodoId];
        this._empujar(id, o, encolar);
        continue;
      }
      const o = this._nueva('recolectar');
      o.obj = nodoId;
      o.def = w.defId[nodoId];
      this._empujar(id, o, encolar);
      alguna = true;
    }
    if (alguna) this._marca(w.px[nodoId], w.pz[nodoId], 'recolectar');
    return alguna;
  }

  /**
   * Emplaza una obra y manda a construirla. Cobra el coste completo al
   * apoyarse los cimientos, como en AoE2.
   */
  construir(ids, claveEdificio, x, z, rot = 0, encolar = false) {
    const ctx = this.ctx, w = ctx.mundo;
    const defId = EDIFICIO_POR_CLAVE.get(claveEdificio);
    if (defId === undefined) return false;
    const def = EDIFICIOS[defId];
    const lista = this._propias(ids, true).filter((id) => this._esConstructor(id));
    if (!lista.length) { this._error('Seleccioná un Colono para construir'); return false; }
    const j = w.jugador[lista[0]];

    if (this._edad(j) < def.edad) { this._error(`Necesitás la ${EDADES[def.edad].nombre}`); return false; }
    const coste = this._costeEdificio(j, def);
    if (!this._puedePagar(j, coste)) { this._error(this._falta(j, coste)); return false; }

    // el emplazado ya lo validó la UI; revalidamos barato por si el terreno cambió
    if (ctx.nav?.esLibre && !ctx.nav.esLibre(x, z, 0.8)) {
      this._error('No se puede construir acá'); return false;
    }

    let obra = -1;
    const hook = this._hook('produccion', ['colocarObra', 'iniciarObra', 'crearObra', 'emplazar', 'fundar']);
    this._conCobro(j, coste, () => {
      if (hook) obra = hook(claveEdificio, x, z, rot, j) ?? -1;
      if (!(obra >= 0)) obra = this._fundarObra(def, defId, x, z, rot, j);
    });
    if (!(obra >= 0)) return false;

    for (let i = 0; i < lista.length; i++) {
      const o = this._nueva('construir');
      o.obj = obra;
      this._empujar(lista[i], o, encolar);
    }
    this._marca(x, z, 'construir');
    this.ctx.audio?.sfx?.('obra', { x, z });
    bus.emit('obra:emplazada', { id: obra, clave: claveEdificio, jugador: j });
    return true;
  }

  /** Manda a reparar un edificio propio dañado (o a terminar una obra). */
  reparar(ids, edificioId, encolar = false) {
    const w = this.ctx.mundo;
    if (!(edificioId >= 0) || !w.vivo[edificioId]) return false;
    const lista = this._propias(ids, true).filter((id) => this._esConstructor(id));
    if (!lista.length) { this._error('Sólo los Colonos reparan'); return false; }
    const enObra = w.progreso[edificioId] > 0 && w.progreso[edificioId] < 1;
    for (let i = 0; i < lista.length; i++) {
      const o = this._nueva(enObra ? 'construir' : 'reparar');
      o.obj = edificioId;
      this._empujar(lista[i], o, encolar);
    }
    this._marca(w.px[edificioId], w.pz[edificioId], 'reparar');
    return true;
  }

  /** Mete unidades adentro de un edificio con guarnición (o de un transporte). */
  refugiar(ids, edificioId, encolar = false) {
    const w = this.ctx.mundo;
    if (!(edificioId >= 0) || !w.vivo[edificioId]) return false;
    const lista = this._propias(ids, true);
    if (!lista.length) return false;
    const cap = this._capacidad(edificioId);
    if (cap <= 0) { this._error('Ahí no se puede refugiar a nadie'); return false; }
    for (let i = 0; i < lista.length; i++) {
      if (lista[i] === edificioId) continue;
      const o = this._nueva('refugiar');
      o.obj = edificioId;
      this._empujar(lista[i], o, encolar);
    }
    return true;
  }

  /** Saca a todos los que estén adentro. */
  desalojar(edificioId) {
    const hook = this._hook('produccion', ['desalojar', 'expulsar']);
    if (hook) { hook(edificioId); return true; }
    const w = this.ctx.mundo;
    const dentro = this.guarniciones.get(edificioId);
    if (!dentro || !dentro.length) return false;
    const r = (w.radio[edificioId] || 3) + 1.4;
    for (let i = 0; i < dentro.length; i++) {
      const s = dentro[i];
      const a = (i / dentro.length) * Math.PI * 2;
      const x = w.px[edificioId] + Math.cos(a) * r;
      const z = w.pz[edificioId] + Math.sin(a) * r;
      const nuevo = w.crear(TIPO.UNIDAD, s.defId, x, z, s.jugador);
      w.vida[nuevo] = s.vida; w.vidaMax[nuevo] = s.vidaMax;
      w.radio[nuevo] = s.radio; w.velocidad[nuevo] = s.velocidad;
      w.veterania[nuevo] = s.veterania;
      w.rot[nuevo] = a; w.rotObjetivo[nuevo] = a;
      w.py[nuevo] = this.ctx.terreno?.altura?.(x, z) ?? 0;
      this._asegurarVista(nuevo);
      const o = this._nueva('mover'); o.x = x + Math.cos(a) * 2.2; o.z = z + Math.sin(a) * 2.2;
      this._empujar(nuevo, o, false);
    }
    dentro.length = 0;
    this.guarniciones.delete(edificioId);
    bus.emit('guarnicion:cambio', { id: edificioId, cantidad: 0 });
    return true;
  }

  /** Cuántas unidades hay adentro de un edificio (para el HUD). */
  guarnicionDe(edificioId) {
    const hook = this._hook('produccion', ['guarnicionDe']);
    if (hook) return hook(edificioId) ?? 0;
    return this.guarniciones.get(edificioId)?.length ?? 0;
  }

  /** Encola unidades en un edificio de producción. */
  entrenar(edificioId, claveUnidad, cantidad = 1) {
    const ctx = this.ctx, w = ctx.mundo;
    if (!(edificioId >= 0) || !w.vivo[edificioId] || w.tipo[edificioId] !== TIPO.EDIFICIO) return false;
    if (w.progreso[edificioId] < 1 && this.obras.has(edificioId)) { this._error('El edificio todavía está en obra'); return false; }
    const defEd = EDIFICIOS[w.defId[edificioId]];
    const idx = UNIDAD_POR_CLAVE.get(claveUnidad);
    if (idx === undefined) return false;
    const def = UNIDADES[idx];
    const j = w.jugador[edificioId];
    if (defEd?.entrena && defEd.entrena.length && !defEd.entrena.includes(claveUnidad)) {
      this._error(`${defEd.nombre} no entrena ${def.nombre}`); return false;
    }
    if (this._edad(j) < def.edad) { this._error(`Necesitás la ${EDADES[def.edad].nombre}`); return false; }

    let hechas = 0;
    for (let n = 0; n < cantidad; n++) {
      const coste = this._costeUnidad(j, def);
      if (!this._puedePagar(j, coste)) { if (!hechas) this._error(this._falta(j, coste)); break; }
      if (!this._hayPoblacion(j, def.pop || 1)) {
        if (!hechas) this._error('Falta población: construí una Vivienda');
        break;
      }
      const hook = this._hook('produccion', ['entrenar', 'encolarUnidad', 'encolar', 'agregarCola']);
      this._conCobro(j, coste, () => {
        if (hook) hook(edificioId, claveUnidad, 1);
        else this._encolarPropia(edificioId, claveUnidad, 'unidad', this._tiempoUnidad(j, def));
      });
      hechas++;
    }
    if (hechas) bus.emit('produccion:cambio', { id: edificioId });
    return hechas > 0;
  }

  /** Encola una tecnología en un edificio. */
  investigar(edificioId, claveTecno) {
    const ctx = this.ctx, w = ctx.mundo;
    if (!(edificioId >= 0) || !w.vivo[edificioId]) return false;
    const idx = TECNO_POR_CLAVE.get(claveTecno);
    if (idx === undefined) return false;
    const tec = TECNOLOGIAS[idx];
    const j = w.jugador[edificioId];
    const defEd = EDIFICIOS[w.defId[edificioId]];
    if (tec.en && defEd && tec.en !== defEd.clave) { this._error(`Eso se investiga en el ${tec.en}`); return false; }
    if (this._edad(j) < tec.edad) { this._error(`Necesitás la ${EDADES[tec.edad].nombre}`); return false; }
    if (this.investigada(j, claveTecno)) { this._error('Ya la tenés investigada'); return false; }
    if (tec.requiere && !this.investigada(j, tec.requiere)) {
      const prev = TECNOLOGIAS[TECNO_POR_CLAVE.get(tec.requiere)];
      this._error(`Primero investigá ${prev ? prev.nombre : tec.requiere}`); return false;
    }
    const coste = this._costeTecno(j, tec);
    if (!this._puedePagar(j, coste)) { this._error(this._falta(j, coste)); return false; }

    const hook = this._hook('produccion', ['investigar', 'encolarTecno']);
    this._conCobro(j, coste, () => {
      if (hook) hook(edificioId, claveTecno);
      else this._encolarPropia(edificioId, claveTecno, 'tecno', tec.tiempo);
    });
    bus.emit('produccion:cambio', { id: edificioId });
    return true;
  }

  /** ¿El jugador ya tiene esa tecnología? Consulta a Produccion si existe. */
  investigada(jugador, clave) {
    const ext = this.ctx.produccion?.investigadas?.[jugador] ?? this.ctx.eco?.tecnos?.[jugador];
    if (ext) return typeof ext.has === 'function' ? ext.has(clave) : !!ext[clave];
    return !!this.tecnos[jugador]?.has(clave);
  }

  /** Punto de reunión de un edificio. */
  puntoReunion(edificioId, x, z) {
    const w = this.ctx.mundo;
    if (!(edificioId >= 0) || !w.vivo[edificioId]) return false;
    this.reuniones.set(edificioId, { x, z });
    this._hook('produccion', ['puntoReunion', 'setReunion'])?.(edificioId, x, z);
    this._marca(x, z, 'reunion');
    bus.emit('reunion:cambio', { id: edificioId, x, z });
    return true;
  }

  reunionDe(edificioId) { return this.reuniones.get(edificioId) || null; }

  /** Patrulla de ida y vuelta entre la posición actual y (x,z). */
  patrullar(ids, x, z, encolar = false) {
    const w = this.ctx.mundo;
    const lista = this._propias(ids, true);
    if (!lista.length) return false;
    for (let i = 0; i < lista.length; i++) {
      const id = lista[i];
      const o = this._nueva('patrullar');
      o.x = x; o.z = z;
      o.x2 = w.px[id]; o.z2 = w.pz[id];
      o.obj = -1; o.fase = 0;
      this._empujar(id, o, encolar);
      this._metaDe(id).postura = 'patrulla';
    }
    this._marca(x, z, 'patrullar');
    return true;
  }

  /** Se queda clavada donde está: no persigue. */
  mantenerPosicion(ids) {
    const lista = this._propias(ids, true);
    for (let i = 0; i < lista.length; i++) {
      const id = lista[i];
      this.colas.delete(id);
      this._detener(id);
      this._metaDe(id).postura = 'mantener';
    }
    if (lista.length) bus.emit('aviso', { texto: 'Mantener la posición', tipo: 'info' });
    return lista.length > 0;
  }

  /** Sigue a otra entidad manteniendo distancia corta. */
  seguir(ids, objetivoId, encolar = false) {
    const w = this.ctx.mundo;
    if (!(objetivoId >= 0) || !w.vivo[objetivoId]) return false;
    const lista = this._propias(ids, true);
    for (let i = 0; i < lista.length; i++) {
      if (lista[i] === objetivoId) continue;
      const o = this._nueva('seguir');
      o.obj = objetivoId;
      this._empujar(lista[i], o, encolar);
    }
    return lista.length > 0;
  }

  /** Corta todo lo que estén haciendo. */
  cancelar(ids) {
    const lista = this._propias(ids, false);
    for (let i = 0; i < lista.length; i++) {
      const id = lista[i];
      this.colas.delete(id);
      this._detener(id);
      const m = this.ctx.mundo.meta.get(id);
      if (m) m.postura = 'libre';
    }
    return lista.length > 0;
  }

  /** Cola de órdenes pendientes de una entidad (la lee el HUD para dibujarla). */
  cola(id) { return this.colas.get(id) || VACIO; }

  /** Cancela un ítem de la cola de producción propia (fallback). */
  cancelarProduccion(edificioId, indice = -1) {
    const hook = this._hook('produccion', ['cancelar', 'cancelarCola']);
    if (hook) { hook(edificioId, indice); return true; }
    const cola = this.produccionPropia.get(edificioId);
    if (!cola || !cola.length) return false;
    const i = indice < 0 ? cola.length - 1 : indice;
    const it = cola[i];
    if (!it) return false;
    cola.splice(i, 1);
    const j = this.ctx.mundo.jugador[edificioId];
    if (it.tipo === 'unidad') {
      const def = UNIDADES[UNIDAD_POR_CLAVE.get(it.clave)];
      if (def) this._devolver(j, this._costeUnidad(j, def));
    } else {
      const tec = TECNOLOGIAS[TECNO_POR_CLAVE.get(it.clave)];
      if (tec) this._devolver(j, this._costeTecno(j, tec));
    }
    bus.emit('produccion:cambio', { id: edificioId });
    return true;
  }

  /* ================================================================
   *  Bucle fijo (20 Hz)
   * ================================================================ */

  fijo(dt, ctx) {
    this._dt = dt;
    this.colas.forEach(this._pasoCola);
    this.obras.forEach(this._pasoObra);
    this.reparaciones.forEach(this._pasoReparacion);
    this.produccionPropia.forEach(this._pasoProduccion);
  }

  _pasoCola(cola, id) {
    const w = this.ctx.mundo;
    if (!w.vivo[id] || cola.length === 0) { this.colas.delete(id); return; }
    const o = cola[0];
    if (!o.iniciada) { o.iniciada = true; this._iniciar(id, o); }
    o.t += this._dt;
    let fin = false;
    try { fin = this._avanzar(id, o, this._dt); }
    catch (e) { console.error('[ordenes]', e); fin = true; }
    if (!fin) return;
    cola.shift();
    if (cola.length === 0) {
      this.colas.delete(id);
      this._detener(id);
      bus.emit('unidad:ociosa', id);
    }
  }

  /* ---------------- máquina de estados por tipo de orden ---------------- */

  _iniciar(id, o) {
    const w = this.ctx.mundo;
    o.ux = w.px[id]; o.uz = w.pz[id]; o.sinAvance = 0; o.ult = -9;
    switch (o.tipo) {
      case 'mover':
      case 'ataqueLugar':
        this._irA(id, o.x, o.z, 0);
        break;
      case 'patrullar':
        this._irA(id, o.x, o.z, 0);
        break;
      default: break;
    }
  }

  _avanzar(id, o, dt) {
    switch (o.tipo) {
      case 'mover': return this._orMover(id, o, dt);
      case 'atacar': return this._orAtacar(id, o, dt);
      case 'ataqueLugar': return this._orAtaqueLugar(id, o, dt);
      case 'recolectar': return this._orRecolectar(id, o, dt);
      case 'construir': return this._orConstruir(id, o, dt);
      case 'reparar': return this._orReparar(id, o, dt);
      case 'refugiar': return this._orRefugiar(id, o, dt);
      case 'patrullar': return this._orPatrullar(id, o, dt);
      case 'seguir': return this._orSeguir(id, o, dt);
      default: return true;
    }
  }

  _orMover(id, o, dt) {
    const w = this.ctx.mundo;
    const dx = w.px[id] - o.x, dz = w.pz[id] - o.z;
    const tol = (w.radio[id] || 0.5) + 1.0;
    if (dx * dx + dz * dz <= tol * tol) return true;
    if (o.t > 0.5 && w.tieneDestino[id] === 0) return true;   // el movimiento la dio por llegada
    return this._atascado(id, o, dt);
  }

  _orAtacar(id, o, dt) {
    const w = this.ctx.mundo;
    const t = o.obj;
    if (!(t >= 0) || !w.vivo[t]) {
      // buscar otro blanco cercano: el grupo no se queda parado tras matar a uno
      const otro = this._enemigoCerca(id, this._vision(id) * 0.8);
      if (otro >= 0) { o.obj = otro; o.ult = -9; return false; }
      return true;
    }
    w.objetivo[id] = t;
    const r = this._alcance(id) + (w.radio[id] || 0.5) + (w.radio[t] || 0.5);
    const d2 = w.dist2(id, t);
    if (d2 > r * r) {
      if (o.t - o.ult > REPATH) {
        o.ult = o.t;
        const d = Math.max(0.001, Math.sqrt(d2));
        const k = Math.max(0, (d - r * 0.75)) / d;
        this._irA(id, w.px[id] + (w.px[t] - w.px[id]) * k, w.pz[id] + (w.pz[t] - w.pz[id]) * k, 0);
      }
      if (w.estado[id] !== ESTADO.ATACANDO) w.estado[id] = ESTADO.MOVIENDO;
      return this._atascado(id, o, dt);
    }
    w.tieneDestino[id] = 0;
    w.estado[id] = ESTADO.ATACANDO;
    w.rotObjetivo[id] = Math.atan2(-(w.pz[t] - w.pz[id]), w.px[t] - w.px[id]);
    o.sinAvance = 0;
    return false;
  }

  _orAtaqueLugar(id, o, dt) {
    const w = this.ctx.mundo;
    if (o.obj >= 0 && w.vivo[o.obj]) {
      const r = this._alcance(id) + (w.radio[id] || 0.5) + (w.radio[o.obj] || 0.5);
      const d2 = w.dist2(id, o.obj);
      if (d2 <= r * r) {
        w.objetivo[id] = o.obj; w.tieneDestino[id] = 0; w.estado[id] = ESTADO.ATACANDO;
        w.rotObjetivo[id] = Math.atan2(-(w.pz[o.obj] - w.pz[id]), w.px[o.obj] - w.px[id]);
        return false;
      }
      if (d2 > (this._vision(id) * 1.4) ** 2) { o.obj = -1; }   // se escapó: seguir avanzando
      else {
        if (o.t - o.ult > REPATH) { o.ult = o.t; this._irA(id, w.px[o.obj], w.pz[o.obj], 0); }
        return false;
      }
    } else if (o.obj >= 0) {
      o.obj = -1; o.ult = -9;
    }
    // sin blanco: escanear cada ~0.4 s escalonado por id
    if ((this.ctx.mundo.tick + id) % 8 === 0) {
      const e = this._enemigoCerca(id, this._vision(id) * 0.85);
      if (e >= 0) { o.obj = e; o.ult = -9; return false; }
    }
    if (w.tieneDestino[id] === 0 && o.t > 0.5) this._irA(id, o.x, o.z, 0);
    return this._orMover(id, o, dt);
  }

  _orRecolectar(id, o, dt) {
    const w = this.ctx.mundo;
    let n = o.obj;
    if (!(n >= 0) || !w.vivo[n]) {
      const otro = this._nodoCercano(id, o.def, 18);
      if (otro < 0) return true;
      n = o.obj = otro; o.ult = -9;
    }
    // Si Economia ya tomó el mando (recolectando o volviendo a depositar), no molestar.
    const est = w.estado[id];
    if (est === ESTADO.DEPOSITANDO) { o.sinAvance = 0; return false; }
    if (est === ESTADO.RECOLECTANDO && w.objetivo[id] === n) { o.sinAvance = 0; return false; }

    w.objetivo[id] = n;
    const r = (w.radio[id] || 0.5) + (w.radio[n] || 0.6) + 0.5;
    const d2 = w.dist2(id, n);
    if (d2 > r * r) {
      if (o.t - o.ult > REPATH * 1.5) {
        o.ult = o.t;
        const d = Math.max(0.001, Math.sqrt(d2));
        const k = Math.max(0, d - r * 0.85) / d;
        this._irA(id, w.px[id] + (w.px[n] - w.px[id]) * k, w.pz[id] + (w.pz[n] - w.pz[id]) * k, 0);
      }
      if (est !== ESTADO.RECOLECTANDO) w.estado[id] = ESTADO.MOVIENDO;
      return this._atascado(id, o, dt);
    }
    w.tieneDestino[id] = 0;
    w.estado[id] = ESTADO.RECOLECTANDO;
    w.rotObjetivo[id] = Math.atan2(-(w.pz[n] - w.pz[id]), w.px[n] - w.px[id]);
    o.sinAvance = 0;
    return false;
  }

  _orConstruir(id, o, dt) {
    const w = this.ctx.mundo;
    const b = o.obj;
    if (!(b >= 0) || !w.vivo[b]) return true;
    if (w.progreso[b] >= 1) return true;
    const r = (w.radio[id] || 0.5) + (w.radio[b] || 2) + 0.8;
    const d2 = w.dist2(id, b);
    if (d2 > r * r) {
      if (o.t - o.ult > REPATH * 1.5) {
        o.ult = o.t;
        const d = Math.max(0.001, Math.sqrt(d2));
        const k = Math.max(0, d - r * 0.8) / d;
        this._irA(id, w.px[id] + (w.px[b] - w.px[id]) * k, w.pz[id] + (w.pz[b] - w.pz[id]) * k, 0);
      }
      w.estado[id] = ESTADO.MOVIENDO;
      w.objetivo[id] = b;
      return this._atascado(id, o, dt);
    }
    w.tieneDestino[id] = 0;
    w.objetivo[id] = b;
    w.estado[id] = ESTADO.CONSTRUYENDO;
    w.rotObjetivo[id] = Math.atan2(-(w.pz[b] - w.pz[id]), w.px[b] - w.px[id]);
    o.sinAvance = 0;
    return false;
  }

  _orReparar(id, o, dt) {
    const w = this.ctx.mundo;
    const b = o.obj;
    if (!(b >= 0) || !w.vivo[b]) return true;
    if (w.vida[b] >= w.vidaMax[b]) { this._quitarReparador(b, id); return true; }
    const r = (w.radio[id] || 0.5) + (w.radio[b] || 2) + 0.8;
    const d2 = w.dist2(id, b);
    if (d2 > r * r) {
      if (o.t - o.ult > REPATH * 1.5) {
        o.ult = o.t;
        const d = Math.max(0.001, Math.sqrt(d2));
        const k = Math.max(0, d - r * 0.8) / d;
        this._irA(id, w.px[id] + (w.px[b] - w.px[id]) * k, w.pz[id] + (w.pz[b] - w.pz[id]) * k, 0);
      }
      w.estado[id] = ESTADO.MOVIENDO;
      return this._atascado(id, o, dt);
    }
    w.tieneDestino[id] = 0;
    w.objetivo[id] = b;
    w.estado[id] = ESTADO.REPARANDO;
    let set = this.reparaciones.get(b);
    if (!set) { set = new Set(); this.reparaciones.set(b, set); }
    set.add(id);
    o.sinAvance = 0;
    return false;
  }

  _orRefugiar(id, o, dt) {
    const w = this.ctx.mundo;
    const b = o.obj;
    if (!(b >= 0) || !w.vivo[b]) return true;
    const r = (w.radio[id] || 0.5) + (w.radio[b] || 2) + 0.9;
    if (w.dist2(id, b) > r * r) {
      if (o.t - o.ult > REPATH * 1.5) { o.ult = o.t; this._irA(id, w.px[b], w.pz[b], 0); }
      w.estado[id] = ESTADO.MOVIENDO;
      return this._atascado(id, o, dt);
    }
    this._guarnecer(id, b);
    return true;
  }

  _orPatrullar(id, o, dt) {
    const w = this.ctx.mundo;
    // enganchar enemigos como en ataque en área, pero volviendo a la ruta
    if (o.obj >= 0 && w.vivo[o.obj]) {
      const r = this._alcance(id) + (w.radio[id] || 0.5) + (w.radio[o.obj] || 0.5);
      const d2 = w.dist2(id, o.obj);
      if (d2 <= r * r) {
        w.objetivo[id] = o.obj; w.tieneDestino[id] = 0; w.estado[id] = ESTADO.ATACANDO;
        return false;
      }
      if (d2 < (this._vision(id) * 1.3) ** 2) {
        if (o.t - o.ult > REPATH) { o.ult = o.t; this._irA(id, w.px[o.obj], w.pz[o.obj], 0); }
        return false;
      }
      o.obj = -1; o.ult = -9;
    }
    if ((w.tick + id) % 8 === 0) {
      const e = this._enemigoCerca(id, this._vision(id) * 0.8);
      if (e >= 0) { o.obj = e; o.ult = -9; return false; }
    }
    const dx = w.px[id] - o.x, dz = w.pz[id] - o.z;
    const tol = (w.radio[id] || 0.5) + 1.4;
    if (dx * dx + dz * dz <= tol * tol || (o.t > 1 && w.tieneDestino[id] === 0)) {
      const tx = o.x, tz = o.z;
      o.x = o.x2; o.z = o.z2; o.x2 = tx; o.z2 = tz;
      o.t = 0; o.sinAvance = 0;
      this._irA(id, o.x, o.z, 0);
    }
    this._atascado(id, o, dt);
    return false;  // la patrulla no termina sola
  }

  _orSeguir(id, o, dt) {
    const w = this.ctx.mundo;
    const t = o.obj;
    if (!(t >= 0) || !w.vivo[t]) return true;
    const d2 = w.dist2(id, t);
    const cerca = ((w.radio[id] || 0.5) + (w.radio[t] || 0.5) + 2.2);
    if (d2 > cerca * cerca) {
      if (o.t - o.ult > REPATH) {
        o.ult = o.t;
        const d = Math.max(0.001, Math.sqrt(d2));
        const k = Math.max(0, d - cerca * 0.8) / d;
        this._irA(id, w.px[id] + (w.px[t] - w.px[id]) * k, w.pz[id] + (w.pz[t] - w.pz[id]) * k, 0);
      }
    } else if (w.tieneDestino[id]) {
      w.tieneDestino[id] = 0; w.estado[id] = ESTADO.QUIETO;
    }
    return false;
  }

  /* ---------------- obras, reparación y producción de respaldo ---------------- */

  _pasoObra(datos, idObra) {
    const w = this.ctx.mundo, dt = this._dt;
    if (!w.vivo[idObra]) { this.obras.delete(idObra); return; }
    if (w.progreso[idObra] >= 1) { this.obras.delete(idObra); return; }
    // contar constructores efectivamente pegados a la obra
    let n = 0;
    const cola = this.colas;
    w.cerca(w.px[idObra], w.pz[idObra], (w.radio[idObra] || 2) + 3.2, this._cerca);
    for (let i = 0; i < this._cerca.length; i++) {
      const c = this._cerca[i];
      if (w.tipo[c] !== TIPO.UNIDAD || w.objetivo[c] !== idObra) continue;
      if (w.estado[c] !== ESTADO.CONSTRUYENDO) continue;
      if (!cola.has(c)) continue;
      n++;
    }
    if (n === 0) return;
    const mod = this.ctx.eco?.mods?.[datos.jugador];
    const vel = (mod?.velConstruccion ?? 1);
    // rendimientos decrecientes, como en AoE2: el segundo constructor no duplica
    const efectivo = 1 + (n - 1) * 0.6;
    w.progreso[idObra] = Math.min(1, w.progreso[idObra] + (dt * efectivo * vel) / Math.max(1, datos.tiempo));
    w.vida[idObra] = Math.max(1, w.vidaMax[idObra] * (0.1 + 0.9 * w.progreso[idObra]));
    if (w.progreso[idObra] >= 1) {
      w.estado[idObra] = ESTADO.QUIETO;
      w.vida[idObra] = w.vidaMax[idObra];
      const def = datos.def;
      this.ctx.nav?.bloquear?.(w.px[idObra], w.pz[idObra], def.celdas[0] * 2, def.celdas[1] * 2, 1);
      this.obras.delete(idObra);
      this.ctx.audio?.sfx?.('obra_lista', { x: w.px[idObra], z: w.pz[idObra] });
      bus.emit('edificio:terminado', { id: idObra, clave: def.clave, jugador: datos.jugador });
      if (datos.jugador === this.ctx.jugadorLocal) {
        bus.emit('aviso', { texto: `${def.nombre} en pie`, tipo: 'info' });
      }
    }
  }

  _pasoReparacion(set, idEd) {
    const w = this.ctx.mundo, dt = this._dt;
    if (!w.vivo[idEd] || w.vida[idEd] >= w.vidaMax[idEd]) { this.reparaciones.delete(idEd); return; }
    let n = 0;
    for (const c of set) {
      if (!w.vivo[c] || w.estado[c] !== ESTADO.REPARANDO || w.objetivo[c] !== idEd) { set.delete(c); continue; }
      n++;
    }
    if (!n) { this.reparaciones.delete(idEd); return; }
    const def = EDIFICIOS[w.defId[idEd]];
    const tiempo = def ? def.tiempo : 40;
    const efectivo = 1 + (n - 1) * 0.6;
    w.vida[idEd] = Math.min(w.vidaMax[idEd], w.vida[idEd] + (w.vidaMax[idEd] / (tiempo * 1.6)) * efectivo * dt);
  }

  _pasoProduccion(cola, idEd) {
    const w = this.ctx.mundo, dt = this._dt;
    if (!w.vivo[idEd] || !cola.length) { if (!w.vivo[idEd]) this.produccionPropia.delete(idEd); return; }
    if (w.progreso[idEd] < 1 && this.obras.has(idEd)) return;
    const it = cola[0];
    it.restante -= dt;
    w.estado[idEd] = ESTADO.PRODUCIENDO;
    w.progreso[idEd] = it.total > 0 ? 1 - Math.max(0, it.restante) / it.total : 1;
    if (it.restante > 0) return;
    cola.shift();
    if (!cola.length) { this.produccionPropia.delete(idEd); w.estado[idEd] = ESTADO.QUIETO; }
    if (it.tipo === 'unidad') this._sacarUnidad(idEd, it.clave);
    else this._aplicarTecno(w.jugador[idEd], it.clave);
    bus.emit('produccion:cambio', { id: idEd });
  }

  _encolarPropia(idEd, clave, tipo, tiempo) {
    let cola = this.produccionPropia.get(idEd);
    if (!cola) { cola = []; this.produccionPropia.set(idEd, cola); }
    cola.push({ clave, tipo, restante: Math.max(0.5, tiempo), total: Math.max(0.5, tiempo) });
  }

  _sacarUnidad(idEd, clave) {
    const w = this.ctx.mundo;
    const idx = UNIDAD_POR_CLAVE.get(clave);
    if (idx === undefined) return -1;
    const def = UNIDADES[idx];
    const j = w.jugador[idEd];
    const rp = this.reuniones.get(idEd);
    const r = (w.radio[idEd] || 3) + 1.6;
    let ax = 1, az = 0;
    if (rp) {
      const dx = rp.x - w.px[idEd], dz = rp.z - w.pz[idEd];
      const d = Math.hypot(dx, dz) || 1;
      ax = dx / d; az = dz / d;
    }
    const x = w.px[idEd] + ax * r, z = w.pz[idEd] + az * r;
    const id = w.crear(TIPO.UNIDAD, idx, x, z, j);
    this._prepararUnidad(id, def, j);
    this._asegurarVista(id);
    bus.emit('entidad:creada', id);
    if (rp) { const o = this._nueva('mover'); o.x = rp.x; o.z = rp.z; this._empujar(id, o, false); }
    return id;
  }

  _prepararUnidad(id, def, j) {
    const w = this.ctx.mundo;
    const mod = this.ctx.eco?.mods?.[j];
    const extra = mod?.vidaExtra?.[def.clase] || 0;
    w.vida[id] = w.vidaMax[id] = def.vida + extra;
    w.velocidad[id] = def.velocidad * (mod?.velocidad?.[def.clase] ?? 1);
    w.radio[id] = def.clase === 'asedio' || def.clase === 'caballeria' || def.clase === 'nave' ? 0.75 : 0.45;
    w.py[id] = this.ctx.terreno?.altura?.(w.px[id], w.pz[id]) ?? 0;
    w.estado[id] = ESTADO.QUIETO;
  }

  _aplicarTecno(j, clave) {
    const idx = TECNO_POR_CLAVE.get(clave);
    if (idx === undefined) return;
    const tec = TECNOLOGIAS[idx];
    if (!this.tecnos[j]) this.tecnos[j] = new Set();
    this.tecnos[j].add(clave);
    const mods = this.ctx.eco?.mods?.[j];
    if (mods) { try { tec.efecto?.(mods, j); } catch (e) { console.error('[tecno]', e); } }
    bus.emit('tecno:completada', { jugador: j, clave });
    if (j === this.ctx.jugadorLocal) bus.emit('aviso', { texto: `${tec.nombre} listo`, tipo: 'info' });
  }

  _fundarObra(def, defId, x, z, rot, j) {
    const w = this.ctx.mundo;
    const id = w.crear(TIPO.EDIFICIO, defId, x, z, j);
    w.py[id] = this.ctx.terreno?.altura?.(x, z) ?? 0;
    w.vidaMax[id] = def.vida;
    w.vida[id] = Math.max(1, def.vida * 0.1);
    w.radio[id] = Math.max(def.celdas[0], def.celdas[1]);
    w.rot[id] = rot; w.rotObjetivo[id] = rot;
    w.estado[id] = ESTADO.CONSTRUYENDO;
    w.progreso[id] = 0;
    this._metaDe(id).obra = true;
    const mod = this.ctx.eco?.mods?.[j];
    const tiempo = def.tiempo / (mod?.velConstruccion ?? 1);
    this.obras.set(id, { def, tiempo, jugador: j });
    this._asegurarVista(id);
    bus.emit('entidad:creada', id);
    return id;
  }

  _guarnecer(id, b) {
    const w = this.ctx.mundo;
    const hook = this._hook('produccion', ['guarnecer', 'refugiar']);
    if (hook) { hook(id, b); return; }
    let dentro = this.guarniciones.get(b);
    if (!dentro) { dentro = []; this.guarniciones.set(b, dentro); }
    if (dentro.length >= this._capacidad(b)) { this._error('No entra nadie más'); return; }
    dentro.push({
      defId: w.defId[id], jugador: w.jugador[id], vida: w.vida[id], vidaMax: w.vidaMax[id],
      radio: w.radio[id], velocidad: w.velocidad[id], veterania: w.veterania[id],
    });
    this.colas.delete(id);
    this.ctx.seleccion?.ids?.delete?.(id);
    this.ctx.vista?.quitar?.(id);
    w.destruir(id);
    bus.emit('guarnicion:cambio', { id: b, cantidad: dentro.length });
    this.ctx.audio?.sfx?.('guarnicion', { x: w.px[b], z: w.pz[b] });
  }

  _quitarReparador(b, id) {
    const set = this.reparaciones.get(b);
    if (set) { set.delete(id); if (!set.size) this.reparaciones.delete(b); }
  }

  /* ================================================================
   *  Utilidades
   * ================================================================ */

  _nueva(tipo) {
    return {
      tipo, x: 0, z: 0, x2: 0, z2: 0, obj: -1, def: 0, rot: 0,
      t: 0, ult: -9, iniciada: false, fase: 0, ux: 0, uz: 0, sinAvance: 0,
    };
  }

  _empujar(id, o, encolar) {
    let cola = this.colas.get(id);
    if (!cola) { cola = []; this.colas.set(id, cola); }
    if (!encolar) {
      cola.length = 0;
      const m = this.ctx.mundo.meta.get(id);
      if (m && m.postura && m.postura !== 'libre') m.postura = 'libre';
      this.ctx.mundo.objetivo[id] = -1;
    }
    if (cola.length >= 24) return;   // tope sano de cola
    cola.push(o);
  }

  _detener(id) {
    const w = this.ctx.mundo;
    if (!w.vivo[id]) return;
    w.tieneDestino[id] = 0;
    w.vx[id] = 0; w.vz[id] = 0;
    w.objetivo[id] = -1;
    if (w.estado[id] !== ESTADO.MURIENDO) w.estado[id] = ESTADO.QUIETO;
    this.ctx.movimiento?.detener?.(id);
  }

  _irA(id, x, z, _tol) {
    const w = this.ctx.mundo;
    const lim = (this.ctx.terreno?.tam ?? 512) * 0.5 - 2;
    const dx = Math.min(lim, Math.max(-lim, x));
    const dz = Math.min(lim, Math.max(-lim, z));
    w.destinoX[id] = dx; w.destinoZ[id] = dz;
    w.tieneDestino[id] = 1;
    if (w.estado[id] !== ESTADO.ATACANDO) w.estado[id] = ESTADO.MOVIENDO;
    this.ctx.movimiento?.irA?.(id, dx, dz);
  }

  /** Detecta unidades que no llegan nunca (encajonadas) y libera la orden. */
  _atascado(id, o, dt) {
    const w = this.ctx.mundo;
    o.sinAvance += dt;
    if (o.sinAvance < 1) return false;
    const dx = w.px[id] - o.ux, dz = w.pz[id] - o.uz;
    o.ux = w.px[id]; o.uz = w.pz[id];
    const avance = dx * dx + dz * dz;
    if (avance > 0.09) { o.sinAvance = 0; o.trabas = 0; return false; }
    o.sinAvance = 0;
    o.trabas = (o.trabas || 0) + 1;
    return o.trabas >= 4;
  }

  /** Reparte n destinos alrededor de (x,z) en anillos y los asigna por cercanía. */
  _repartir(lista, x, z) {
    const n = lista.length;
    const s = this._slots;
    s.length = n * 2;
    if (n === 1) { s[0] = x; s[1] = z; return; }
    const w = this.ctx.mundo;
    let paso = 0;
    for (let i = 0; i < n; i++) paso = Math.max(paso, w.radio[lista[i]] || 0.5);
    paso = Math.max(1.6, paso * 2.2);
    // puntos candidatos: centro + anillos hexagonales
    const px = this._tmp; px.length = 0;
    px.push(x, z);
    for (let anillo = 1; px.length < n * 2; anillo++) {
      const cant = anillo * 6;
      const r = anillo * paso;
      for (let i = 0; i < cant && px.length < n * 2; i++) {
        const a = (i / cant) * Math.PI * 2 + anillo * 0.37;
        px.push(x + Math.cos(a) * r, z + Math.sin(a) * r);
      }
    }
    // asignación glotona: la unidad más cercana al centro se queda con el centro
    const orden = this._orden; orden.length = n;
    for (let i = 0; i < n; i++) orden[i] = i;
    orden.sort((a, b) => {
      const da = (w.px[lista[a]] - x) ** 2 + (w.pz[lista[a]] - z) ** 2;
      const db = (w.px[lista[b]] - x) ** 2 + (w.pz[lista[b]] - z) ** 2;
      return da - db;
    });
    const usado = new Uint8Array(n);
    for (let k = 0; k < n; k++) {
      const i = orden[k];
      const ux = w.px[lista[i]], uz = w.pz[lista[i]];
      let mejor = -1, mejorD = Infinity;
      for (let c = 0; c < n; c++) {
        if (usado[c]) continue;
        const d = (px[c * 2] - ux) ** 2 + (px[c * 2 + 1] - uz) ** 2;
        if (d < mejorD) { mejorD = d; mejor = c; }
      }
      if (mejor < 0) mejor = 0;
      usado[mejor] = 1;
      s[i * 2] = px[mejor * 2]; s[i * 2 + 1] = px[mejor * 2 + 1];
    }
  }

  /** Normaliza ids (Set|Array) y filtra por vivas / controlables. */
  _propias(ids, soloUnidades) {
    const w = this.ctx.mundo;
    const out = [];
    if (!ids) return out;
    const iter = ids.forEach ? ids : Array.from(ids);
    iter.forEach((id) => {
      if (!(id >= 0) || !w.vivo[id]) return;
      if (soloUnidades && w.tipo[id] !== TIPO.UNIDAD) return;
      out.push(id);
    });
    return out;
  }

  _metaDe(id) {
    const m = this.ctx.mundo.meta;
    let o = m.get(id);
    if (!o) { o = {}; m.set(id, o); }
    return o;
  }

  _hook(modulo, nombres) {
    const obj = this.ctx[modulo];
    if (!obj) return null;
    for (let i = 0; i < nombres.length; i++) {
      const f = obj[nombres[i]];
      if (typeof f === 'function') return f.bind(obj);
    }
    return null;
  }

  _asegurarVista(id) {
    const v = this.ctx.vista;
    if (!v) return;
    if (typeof v.mallaDe === 'function' && v.mallaDe(id)) return;  // ya se registró sola
    v.registrar?.(id);
  }

  _esConstructor(id) {
    const w = this.ctx.mundo;
    if (w.tipo[id] !== TIPO.UNIDAD) return false;
    const def = UNIDADES[w.defId[id]];
    return !!def && CLASES_RECOLECTORAS.has(def.clase);
  }

  _puedeRecolectar(id, nodoId) {
    const w = this.ctx.mundo;
    const def = UNIDADES[w.defId[id]];
    if (!def) return false;
    const nodo = w.tipo[nodoId] === TIPO.RECURSO ? NODOS[w.defId[nodoId]] : null;
    const edif = w.tipo[nodoId] === TIPO.EDIFICIO ? EDIFICIOS[w.defId[nodoId]] : null;
    if (edif && !edif.recursoInfinito) return false;
    if (nodo?.agua) return def.naval === true;
    if (def.clase === 'aldeano') return true;
    return false;
  }

  _capacidad(id) {
    const w = this.ctx.mundo;
    if (w.tipo[id] === TIPO.EDIFICIO) return EDIFICIOS[w.defId[id]]?.guarnicion || 0;
    const u = UNIDADES[w.defId[id]];
    return u?.capacidad || 0;
  }

  _ataque(id) {
    const w = this.ctx.mundo;
    if (w.tipo[id] === TIPO.EDIFICIO) return EDIFICIOS[w.defId[id]]?.ataque || 0;
    return UNIDADES[w.defId[id]]?.ataque || 0;
  }

  _alcance(id) {
    const w = this.ctx.mundo;
    const j = w.jugador[id];
    if (w.tipo[id] === TIPO.EDIFICIO) {
      const d = EDIFICIOS[w.defId[id]];
      return (d?.alcance || 0) + (this.ctx.eco?.mods?.[j]?.alcance?.edificio || 0);
    }
    const d = UNIDADES[w.defId[id]];
    if (!d) return 1;
    return d.alcance + (this.ctx.eco?.mods?.[j]?.alcance?.[d.clase] || 0);
  }

  _vision(id) {
    const w = this.ctx.mundo;
    const d = w.tipo[id] === TIPO.EDIFICIO ? EDIFICIOS[w.defId[id]] : UNIDADES[w.defId[id]];
    return (d?.vision || 20);
  }

  _enemigoCerca(id, radio) {
    const w = this.ctx.mundo;
    const j = w.jugador[id];
    w.cerca(w.px[id], w.pz[id], radio, this._cerca);
    let mejor = -1, mejorP = Infinity;
    for (let i = 0; i < this._cerca.length; i++) {
      const e = this._cerca[i];
      if (e === id || !w.vivo[e]) continue;
      const je = w.jugador[e];
      if (je === j || je === 255) continue;
      const t = w.tipo[e];
      if (t !== TIPO.UNIDAD && t !== TIPO.EDIFICIO) continue;
      if (w.estado[e] === ESTADO.MURIENDO) continue;
      let p = w.dist2(id, e);
      if (t === TIPO.EDIFICIO) p += 900;      // preferimos gente antes que ladrillos
      if (p < mejorP) { mejorP = p; mejor = e; }
    }
    return mejor;
  }

  _nodoCercano(id, defNodo, radio) {
    const w = this.ctx.mundo;
    w.cerca(w.px[id], w.pz[id], radio, this._cerca);
    let mejor = -1, mejorD = Infinity;
    for (let i = 0; i < this._cerca.length; i++) {
      const n = this._cerca[i];
      if (!w.vivo[n] || w.tipo[n] !== TIPO.RECURSO || w.defId[n] !== defNodo) continue;
      const d = w.dist2(id, n);
      if (d < mejorD) { mejorD = d; mejor = n; }
    }
    return mejor;
  }

  _quizasReunion(id) {
    const w = this.ctx.mundo;
    if (!w.vivo[id] || w.tipo[id] !== TIPO.UNIDAD) return;
    if (this.colas.has(id) || w.tieneDestino[id]) return;
    if (!this.reuniones.size) return;
    w.cerca(w.px[id], w.pz[id], 9, this._cerca);
    for (let i = 0; i < this._cerca.length; i++) {
      const b = this._cerca[i];
      if (w.tipo[b] !== TIPO.EDIFICIO || w.jugador[b] !== w.jugador[id]) continue;
      const rp = this.reuniones.get(b);
      if (!rp) continue;
      const o = this._nueva('mover'); o.x = rp.x; o.z = rp.z;
      this._empujar(id, o, false);
      return;
    }
  }

  /* ---------------- costes ---------------- */

  _edad(j) {
    const e = this.ctx.edades?.edad?.[j];
    return e === undefined || e === null ? 4 : e;   // sin sistema de edades, no bloqueamos
  }

  _mods(j) { return this.ctx.eco?.mods?.[j] || null; }

  _costeUnidad(j, def) {
    const m = this._mods(j);
    const c = { ...def.coste };
    if (m?.descuentoAlimentoMilitar && def.clase !== 'aldeano') c.alimento = Math.round(c.alimento * m.descuentoAlimentoMilitar);
    return c;
  }

  _costeEdificio(j, def) {
    const m = this._mods(j);
    const c = { ...def.coste };
    if (m?.descuentoGranja && def.clave === 'granja') c.materiales = Math.round(c.materiales * m.descuentoGranja);
    if (m?.descuentoAcopio && def.deposito) c.materiales = Math.round(c.materiales * m.descuentoAcopio);
    return c;
  }

  _costeTecno(j, tec) {
    const m = this._mods(j);
    const c = { ...tec.coste };
    if (m?.descuentoFundicion && tec.en === 'fundicion') {
      for (const k of CLAVES_RECURSO) c[k] = Math.round((c[k] || 0) * m.descuentoFundicion);
    }
    return c;
  }

  _tiempoUnidad(j, def) {
    const m = this._mods(j);
    let t = def.tiempo;
    if (m?.velEntrenamiento) t /= m.velEntrenamiento;
    if (m?.velEntrenamientoInf && def.clase === 'infanteria') t /= m.velEntrenamientoInf;
    return t;
  }

  _puedePagar(j, coste) {
    const eco = this.ctx.eco;
    if (!eco?.recursos?.[j]) return true;
    if (typeof eco.puedePagar === 'function') return eco.puedePagar(j, coste);
    const r = eco.recursos[j];
    for (let i = 0; i < CLAVES_RECURSO.length; i++) {
      const k = CLAVES_RECURSO[i];
      if ((coste[k] || 0) > (r[k] || 0)) return false;
    }
    return true;
  }

  _falta(j, coste) {
    const r = this.ctx.eco?.recursos?.[j];
    if (!r) return 'No alcanzan los recursos';
    for (let i = 0; i < CLAVES_RECURSO.length; i++) {
      const k = CLAVES_RECURSO[i];
      if ((coste[k] || 0) > (r[k] || 0)) return FALTA[i];
    }
    return 'No alcanzan los recursos';
  }

  _hayPoblacion(j, pop) {
    const p = this.ctx.eco?.pob?.[j];
    if (!p) return true;
    return (p.actual || 0) + pop <= (p.tope || 0);
  }

  /**
   * Ejecuta `fn` y, si nadie tocó los recursos del jugador, cobra el coste acá.
   * Así no importa si Produccion cobra o no: nunca se cobra dos veces.
   */
  _conCobro(j, coste, fn) {
    const eco = this.ctx.eco;
    const r = eco?.recursos?.[j];
    let a = 0, b = 0, c = 0, d = 0;
    if (r) { a = r.alimento || 0; b = r.materiales || 0; c = r.capital || 0; d = r.energia || 0; }
    const res = fn();
    if (!r) return res;
    const cambio = Math.abs((r.alimento || 0) - a) + Math.abs((r.materiales || 0) - b)
      + Math.abs((r.capital || 0) - c) + Math.abs((r.energia || 0) - d);
    if (cambio < 1e-6) {
      if (typeof eco.pagar === 'function') eco.pagar(j, coste);
      else {
        r.alimento -= coste.alimento || 0; r.materiales -= coste.materiales || 0;
        r.capital -= coste.capital || 0; r.energia -= coste.energia || 0;
      }
    }
    return res;
  }

  _devolver(j, coste) {
    const r = this.ctx.eco?.recursos?.[j];
    if (!r) return;
    r.alimento += coste.alimento || 0; r.materiales += coste.materiales || 0;
    r.capital += coste.capital || 0; r.energia += coste.energia || 0;
  }

  _error(texto) {
    bus.emit('aviso', { texto, tipo: 'error' });
    this.ctx.audio?.sfx?.('error');
  }

  _marca(x, z, tipo) {
    bus.emit('orden:marca', { x, z, tipo });
    const y = this.ctx.terreno?.altura?.(x, z) ?? 0;
    if (tipo === 'mover' || tipo === 'atacar') this.ctx.efectos?.polvo?.(x, y + 0.1, z, 6);
  }
}
