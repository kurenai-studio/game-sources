/**
 * Seleccion — el mouse y el teclado del jugador. Es la capa que traduce clicks
 * en órdenes, con el tacto de Age of Empires II:
 *
 *   · Izquierdo: elige. Doble click: todas las del mismo tipo en pantalla.
 *     Arrastre: rectángulo (un div del HUD, no geometría 3D) que prioriza
 *     militares sobre colonos. Shift suma a lo ya elegido.
 *   · Derecho: orden contextual (mover / atacar / recolectar / reparar /
 *     refugiarse / embarcar / punto de reunión). Shift encola.
 *   · Ctrl+1..9 guarda grupos, 1..9 los recupera, doble tecla centra la cámara.
 *   · «.» y «,» saltan entre colonos ociosos, «H» va a la Sede, «Supr» elimina.
 *   · Modo construcción: fantasma encajado a la grilla de 2 m, verde/rojo según
 *     se pueda emplazar, R o rueda para rotar, Shift para encolar varios,
 *     Escape para salir. Los muros se emplazan arrastrando una línea.
 *
 * Este módulo NO dibuja anillos de selección: sólo mantiene el Set `ids` y
 * emite 'seleccion:cambio'. De los anillos se ocupa VistaEntidades.
 */

import * as THREE from 'three';
import { ORDEN } from '../core/Ctx.js';
import { TIPO, ESTADO } from '../core/World.js';
import { bus } from '../core/EventBus.js';
import { UNIDADES } from '../data/unidades.js';
import { EDIFICIOS, EDIFICIO_POR_CLAVE } from '../data/edificios.js';

const TOPE = 60;                 // tope de unidades seleccionadas
const UMBRAL_ARRASTRE = 6;       // px para que un click pase a ser rectángulo
const MS_DOBLE = 320;
const CELDA = 2;                 // metros por celda de la grilla de emplazado
const MAX_MURO = 32;             // segmentos máximos por arrastre de muralla

const _v = new THREE.Vector3();
const _pt = { x: 0, y: 0 };

export class Seleccion {
  constructor(ctx) {
    this.nombre = 'seleccion';
    this.orden = ORDEN.ENTRADA;
    this.ctx = ctx;

    /** @type {Set<number>} */
    this.ids = new Set();
    /** orden estable de la selección (para el HUD y para que no baile entre frames) */
    this.lista = [];
    this.principal = -1;

    this.grupos = new Array(10).fill(null).map(() => []);
    this.construccion = null;     // { clave, def, rot, muro, valido, x, z, inicio }

    this.lienzo = ctx.renderer?.domElement || document.getElementById('lienzo') || document.body;
    this._w = window.innerWidth; this._h = window.innerHeight;

    this._abajo = false;
    this._arrastre = false;
    this._x0 = 0; this._y0 = 0; this._x1 = 0; this._y1 = 0;
    this._ultClickT = 0; this._ultClickX = 0; this._ultClickY = 0; this._ultClickId = -1;
    this._ultGrupo = -1; this._ultGrupoT = 0;
    this._idxOcioso = -1;
    this._cand = [];
    this._acumHover = 0;
    this._hover = -1;
    this._cursor = '';

    this._crearRect();
    this._crearFantasmas();
    this._instalar();
  }

  /* ================================================================
   *  API pública
   * ================================================================ */

  seleccionar(ids, aditivo = false) {
    if (!aditivo) { this.ids.clear(); this.lista.length = 0; }
    const w = this.ctx.mundo;
    const entrada = ids && ids.forEach ? ids : Array.from(ids || []);
    entrada.forEach((id) => {
      if (!(id >= 0) || !w.vivo[id] || this.ids.has(id)) return;
      if (this.lista.length >= TOPE) return;
      this.ids.add(id);
      this.lista.push(id);
    });
    this.lista.sort((a, b) => a - b);          // orden estable entre frames
    this.principal = this.lista.length ? this.lista[0] : -1;
    this._emitir();
    return this.ids;
  }

  limpiar() {
    if (!this.ids.size) return;
    this.ids.clear(); this.lista.length = 0; this.principal = -1;
    this._emitir();
  }

  quitar(id) {
    if (!this.ids.delete(id)) return;
    const i = this.lista.indexOf(id);
    if (i >= 0) this.lista.splice(i, 1);
    this.principal = this.lista.length ? this.lista[0] : -1;
    this._emitir();
  }

  /** Entidad bajo el cursor, o -1. Barata: sólo mira lo que hay cerca del rayo. */
  entidadBajoCursor() {
    const cam = this.ctx.camCtrl;
    const p = cam?.puntoSueloCursor?.();
    if (!p) return -1;
    const w = this.ctx.mundo;
    w.cerca(p.x, p.z, 14, this._cand);
    const mx = cam.raton.x, my = cam.raton.y;
    const ppm = this._pixelesPorMetro();
    let mejor = -1, mejorP = Infinity;
    for (let i = 0; i < this._cand.length; i++) {
      const id = this._cand[i];
      if (!w.vivo[id] || w.visible[id] === 0) continue;
      const t = w.tipo[id];
      if (t === TIPO.PROYECTIL || t === TIPO.DECORADO) continue;
      const alto = t === TIPO.EDIFICIO ? Math.max(2, w.radio[id] || 2) : 1.0;
      if (!this._proyectar(w.px[id], w.py[id] + alto * 0.55, w.pz[id], _pt)) continue;
      const dx = _pt.x - mx, dy = _pt.y - my;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const radioPx = Math.max(10, (w.radio[id] || 0.6) * ppm * (t === TIPO.EDIFICIO ? 1.1 : 1.7));
      if (dist > radioPx + 6) continue;
      // prioridad: unidades propias > otras unidades > recursos > edificios
      let p2 = dist;
      if (t === TIPO.UNIDAD) p2 -= w.jugador[id] === this.ctx.jugadorLocal ? 26 : 14;
      else if (t === TIPO.RECURSO) p2 -= 6;
      if (p2 < mejorP) { mejorP = p2; mejor = id; }
    }
    return mejor;
  }

  /** Ctrl+N guarda; N recupera. Doble N centra la cámara. */
  grupoControl(n, guardar) {
    if (n < 0 || n > 9) return;
    const w = this.ctx.mundo;
    if (guardar) {
      const g = this.grupos[n];
      g.length = 0;
      for (let i = 0; i < this.lista.length; i++) {
        const id = this.lista[i];
        if (w.vivo[id]) { g.push(id); w.grupo[id] = n; }
      }
      bus.emit('aviso', { texto: `Grupo ${n} guardado (${g.length})`, tipo: 'info' });
      bus.emit('grupo:cambio', { n, cantidad: g.length });
      return;
    }
    const g = this.grupos[n].filter((id) => w.vivo[id]);
    this.grupos[n] = g;
    if (!g.length) return;
    this.seleccionar(g, false);
    const ahora = performance.now();
    if (this._ultGrupo === n && ahora - this._ultGrupoT < 400) this.centrarEnSeleccion();
    this._ultGrupo = n; this._ultGrupoT = ahora;
  }

  centrarEnSeleccion() {
    const w = this.ctx.mundo;
    let x = 0, z = 0, n = 0;
    for (let i = 0; i < this.lista.length; i++) {
      const id = this.lista[i];
      if (!w.vivo[id]) continue;
      x += w.px[id]; z += w.pz[id]; n++;
    }
    if (n) this.ctx.camCtrl?.enfocar?.(x / n, z / n);
  }

  /** Entra (o sale, con null) en el modo de emplazado de edificios. */
  modoConstruccion(claveEdificio) {
    if (!claveEdificio) { this._salirConstruccion(); return false; }
    const idx = EDIFICIO_POR_CLAVE.get(claveEdificio);
    if (idx === undefined) return false;
    const def = EDIFICIOS[idx];
    const j = this.ctx.jugadorLocal;
    const edad = this.ctx.edades?.edad?.[j];
    if (edad !== undefined && edad !== null && edad < def.edad) {
      bus.emit('aviso', { texto: `Todavía no: eso es de otra edad`, tipo: 'error' });
      return false;
    }
    if (!this._colonosSeleccionados().length) {
      bus.emit('aviso', { texto: 'Seleccioná un Colono para construir', tipo: 'error' });
      return false;
    }
    this._salirConstruccion();
    this.construccion = {
      clave: claveEdificio, def, defIdx: idx, rot: 0, muro: !!def.muro,
      valido: false, x: 0, z: 0, inicio: null, celdas: [],
    };
    this._montarFantasma(claveEdificio);
    this.lienzo.style.cursor = 'crosshair';
    return true;
  }

  /* ================================================================
   *  Bucle por frame
   * ================================================================ */

  cada(dtReal) {
    this._w = window.innerWidth; this._h = window.innerHeight;
    this._depurarSeleccion();
    if (this.construccion) this._actualizarFantasma();
    else {
      this._acumHover += dtReal;
      if (this._acumHover > 0.06) { this._acumHover = 0; this._actualizarCursor(); }
    }
  }

  /* ================================================================
   *  Entrada
   * ================================================================ */

  _instalar() {
    const c = this.lienzo;
    this._onDown = this._onDown.bind(this);
    this._onMove = this._onMove.bind(this);
    this._onUp = this._onUp.bind(this);
    this._onKey = this._onKey.bind(this);
    this._onWheel = this._onWheel.bind(this);

    c.addEventListener('pointerdown', this._onDown);
    window.addEventListener('pointermove', this._onMove);
    window.addEventListener('pointerup', this._onUp);
    window.addEventListener('keydown', this._onKey);
    // captura en window: llega antes que el zoom de la cámara, así la rueda
    // puede rotar el fantasma sin mover el zoom.
    window.addEventListener('wheel', this._onWheel, { capture: true, passive: false });
    window.addEventListener('blur', () => { this._abajo = false; this._arrastre = false; this._rect.style.display = 'none'; });
  }

  _onDown(e) {
    if (e.button === 2 && e.shiftKey) {
      // La cámara usa Shift+derecho para rotar; acá Shift+derecho tiene que
      // encolar órdenes, así que le devolvemos el control al juego.
      const cam = this.ctx.camCtrl;
      if (cam) { cam.arrastreRotar = false; document.exitPointerLock?.(); }
    }
    if (e.button === 1) return;              // rueda: paneo/rotación de la cámara

    if (this.construccion) {
      if (e.button === 2) { this._salirConstruccion(); e.preventDefault(); return; }
      if (e.button === 0) {
        const p = this._puntoCursor();
        if (p) this.construccion.inicio = { x: p.x, z: p.z };
        this._abajo = true;
      }
      return;
    }

    if (e.button === 0) {
      this._abajo = true; this._arrastre = false;
      this._x0 = e.clientX; this._y0 = e.clientY;
      this._x1 = e.clientX; this._y1 = e.clientY;
    }
  }

  _onMove(e) {
    if (!this._abajo) return;
    this._x1 = e.clientX; this._y1 = e.clientY;
    if (this.construccion) return;
    if (!this._arrastre) {
      if (Math.abs(this._x1 - this._x0) + Math.abs(this._y1 - this._y0) < UMBRAL_ARRASTRE) return;
      this._arrastre = true;
      this._rect.style.display = 'block';
    }
    this._pintarRect();
  }

  _onUp(e) {
    if (e.button === 2) {
      if (this.construccion) return;
      if (this.ctx.camCtrl?.arrastreRotar) return;
      this._ordenContextual(e.shiftKey);
      return;
    }
    if (e.button !== 0 || !this._abajo) return;
    this._abajo = false;

    if (this.construccion) { this._emplazar(e.shiftKey); return; }

    if (this._arrastre) {
      this._arrastre = false;
      this._rect.style.display = 'none';
      this._seleccionarCaja(
        Math.min(this._x0, this._x1), Math.min(this._y0, this._y1),
        Math.max(this._x0, this._x1), Math.max(this._y0, this._y1),
        e.shiftKey, false,
      );
      return;
    }

    const id = this.entidadBajoCursor();
    const ahora = performance.now();
    const doble = id >= 0 && id === this._ultClickId && ahora - this._ultClickT < MS_DOBLE;
    this._ultClickT = ahora; this._ultClickId = id;

    if (id < 0) { if (!e.shiftKey) this.limpiar(); return; }
    if (doble) { this._seleccionarMismoTipo(id, e.shiftKey); return; }
    if (e.shiftKey && this.ids.has(id)) { this.quitar(id); return; }
    this.seleccionar([id], e.shiftKey);
    this._sonidoSeleccion(id);
  }

  _onWheel(e) {
    if (!this.construccion) return;
    e.preventDefault();
    e.stopPropagation();
    this.construccion.rot = (this.construccion.rot + (e.deltaY > 0 ? 1 : 3)) % 4;
  }

  _onKey(e) {
    const t = e.target;
    if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return;
    const code = e.code;

    if (code === 'Escape') {
      if (this.construccion) this._salirConstruccion();
      else this.limpiar();
      return;
    }
    if (code === 'KeyR' && this.construccion) {
      this.construccion.rot = (this.construccion.rot + 1) % 4;
      e.preventDefault();
      return;
    }
    if (code.startsWith('Digit')) {
      const n = Number(code.slice(5));
      if (Number.isNaN(n)) return;
      if (e.ctrlKey || e.metaKey) this.grupoControl(n, true);
      else if (e.shiftKey) {
        const g = this.grupos[n].filter((id) => this.ctx.mundo.vivo[id]);
        if (g.length) this.seleccionar(g, true);
      } else this.grupoControl(n, false);
      e.preventDefault();
      return;
    }
    if (code === 'Period') { this._saltarOcioso(1); e.preventDefault(); return; }
    if (code === 'Comma') { this._saltarOcioso(-1); e.preventDefault(); return; }
    if (code === 'KeyH' && !e.ctrlKey && !e.metaKey) { this._irASede(); return; }
    if (code === 'Delete') { this._eliminarSeleccion(); return; }
    if (code === 'KeyF' && (e.ctrlKey || e.metaKey)) { this.centrarEnSeleccion(); e.preventDefault(); }
  }

  /* ================================================================
   *  Selección
   * ================================================================ */

  _seleccionarCaja(x0, y0, x1, y1, aditivo, incluirEdificios) {
    const w = this.ctx.mundo;
    const j = this.ctx.jugadorLocal;
    const militares = [];
    const civiles = [];
    for (let id = 0; id < w.maxUsado; id++) {
      if (!w.vivo[id] || w.tipo[id] !== TIPO.UNIDAD) continue;
      if (w.jugador[id] !== j || w.visible[id] === 0) continue;
      if (!this._proyectar(w.px[id], w.py[id] + 0.7, w.pz[id], _pt)) continue;
      if (_pt.x < x0 || _pt.x > x1 || _pt.y < y0 || _pt.y > y1) continue;
      const def = UNIDADES[w.defId[id]];
      if (def && (def.clase === 'aldeano' || def.clase === 'apoyo')) civiles.push(id);
      else militares.push(id);
    }
    let elegidos = militares.length ? militares : civiles;
    if (!elegidos.length && incluirEdificios !== false) {
      for (let id = 0; id < w.maxUsado; id++) {
        if (!w.vivo[id] || w.tipo[id] !== TIPO.EDIFICIO || w.jugador[id] !== j) continue;
        if (!this._proyectar(w.px[id], w.py[id] + 2, w.pz[id], _pt)) continue;
        if (_pt.x < x0 || _pt.x > x1 || _pt.y < y0 || _pt.y > y1) continue;
        elegidos.push(id);
        break;   // con un edificio alcanza: no se manejan pilas de edificios
      }
    }
    if (!elegidos.length) { if (!aditivo) this.limpiar(); return; }
    elegidos.sort((a, b) => a - b);
    if (elegidos.length > TOPE) elegidos.length = TOPE;
    this.seleccionar(elegidos, aditivo);
    this._sonidoSeleccion(elegidos[0]);
  }

  _seleccionarMismoTipo(id, aditivo) {
    const w = this.ctx.mundo;
    if (w.tipo[id] !== TIPO.UNIDAD) { this.seleccionar([id], aditivo); return; }
    const def = w.defId[id], j = w.jugador[id];
    if (j !== this.ctx.jugadorLocal) { this.seleccionar([id], aditivo); return; }
    const out = [];
    for (let i = 0; i < w.maxUsado; i++) {
      if (!w.vivo[i] || w.tipo[i] !== TIPO.UNIDAD || w.defId[i] !== def || w.jugador[i] !== j) continue;
      if (w.visible[i] === 0) continue;
      if (!this._proyectar(w.px[i], w.py[i] + 0.7, w.pz[i], _pt)) continue;
      if (_pt.x < 0 || _pt.x > this._w || _pt.y < 0 || _pt.y > this._h) continue;
      out.push(i);
      if (out.length >= TOPE) break;
    }
    this.seleccionar(out.length ? out : [id], aditivo);
    this._sonidoSeleccion(id);
  }

  _depurarSeleccion() {
    const w = this.ctx.mundo;
    let cambio = false;
    for (let i = this.lista.length - 1; i >= 0; i--) {
      const id = this.lista[i];
      if (w.vivo[id]) continue;
      this.lista.splice(i, 1); this.ids.delete(id); cambio = true;
    }
    if (cambio) {
      this.principal = this.lista.length ? this.lista[0] : -1;
      this._emitir();
    }
  }

  _emitir() { bus.emit('seleccion:cambio', this.ids); }

  _sonidoSeleccion(id) {
    const w = this.ctx.mundo;
    if (!(id >= 0) || !w.vivo[id] || w.jugador[id] !== this.ctx.jugadorLocal) return;
    this.ctx.audio?.sfx?.(w.tipo[id] === TIPO.EDIFICIO ? 'sel_edificio' : 'sel_unidad');
  }

  /* ================================================================
   *  Órdenes contextuales (click derecho)
   * ================================================================ */

  _ordenContextual(encolar) {
    const ord = this.ctx.ordenes;
    if (!ord || !this.lista.length) return;
    const w = this.ctx.mundo, j = this.ctx.jugadorLocal;

    const propias = this.lista.filter((id) => w.vivo[id] && w.jugador[id] === j);
    if (!propias.length) return;
    const unidades = propias.filter((id) => w.tipo[id] === TIPO.UNIDAD);
    const edificios = propias.filter((id) => w.tipo[id] === TIPO.EDIFICIO);
    const blanco = this.entidadBajoCursor();
    const p = this._puntoCursor();

    // sólo edificios seleccionados: el derecho fija el punto de reunión
    if (!unidades.length && edificios.length) {
      const dx = blanco >= 0 && w.jugador[blanco] === j ? w.px[blanco] : p?.x;
      const dz = blanco >= 0 && w.jugador[blanco] === j ? w.pz[blanco] : p?.z;
      if (dx === undefined) return;
      for (let i = 0; i < edificios.length; i++) ord.puntoReunion(edificios[i], dx, dz);
      bus.emit('aviso', { texto: 'Punto de reunión fijado', tipo: 'info' });
      return;
    }
    if (!unidades.length) return;

    if (blanco >= 0 && blanco !== undefined) {
      const tb = w.tipo[blanco], jb = w.jugador[blanco];
      if (tb === TIPO.RECURSO) { ord.recolectar(unidades, blanco, encolar); return; }
      if (jb !== j && jb !== 255) { ord.atacar(unidades, blanco, encolar); return; }
      if (jb === j) {
        const defE = tb === TIPO.EDIFICIO ? EDIFICIOS[w.defId[blanco]] : null;
        if (defE?.recursoInfinito) { ord.recolectar(unidades, blanco, encolar); return; }
        if (tb === TIPO.EDIFICIO && (w.vida[blanco] < w.vidaMax[blanco] || w.progreso[blanco] < 1)) {
          if (unidades.some((id) => UNIDADES[w.defId[id]]?.clase === 'aldeano')) {
            ord.reparar(unidades, blanco, encolar); return;
          }
        }
        if (defE?.guarnicion) { ord.refugiar(unidades, blanco, encolar); return; }
        const defU = tb === TIPO.UNIDAD ? UNIDADES[w.defId[blanco]] : null;
        if (defU?.capacidad) { ord.refugiar(unidades, blanco, encolar); return; }
        if (tb === TIPO.UNIDAD) { ord.seguir(unidades, blanco, encolar); return; }
      }
      if (jb === 255 && tb === TIPO.UNIDAD) { ord.atacar(unidades, blanco, encolar); return; }
    }
    if (p) ord.mover(unidades, p.x, p.z, encolar);
  }

  _eliminarSeleccion() {
    const w = this.ctx.mundo, j = this.ctx.jugadorLocal;
    const copia = this.lista.slice();
    let n = 0;
    for (let i = 0; i < copia.length; i++) {
      const id = copia[i];
      if (!w.vivo[id] || w.jugador[id] !== j) continue;
      this.ctx.ordenes?.cancelar?.([id]);
      bus.emit('entidad:muerta', { id, porJugador: j });
      this.ctx.vista?.quitar?.(id);
      w.destruir(id);
      n++;
    }
    if (n) { this.limpiar(); bus.emit('aviso', { texto: `${n} unidad(es) eliminada(s)`, tipo: 'alerta' }); }
  }

  _saltarOcioso(dir) {
    const w = this.ctx.mundo, j = this.ctx.jugadorLocal, ord = this.ctx.ordenes;
    const ociosos = [];
    for (let id = 0; id < w.maxUsado; id++) {
      if (!w.vivo[id] || w.tipo[id] !== TIPO.UNIDAD || w.jugador[id] !== j) continue;
      const def = UNIDADES[w.defId[id]];
      if (!def || def.clase !== 'aldeano') continue;
      if (w.estado[id] !== ESTADO.QUIETO) continue;
      if (ord && ord.cola(id).length) continue;
      ociosos.push(id);
    }
    if (!ociosos.length) { bus.emit('aviso', { texto: 'No hay colonos ociosos', tipo: 'info' }); return; }
    this._idxOcioso = (this._idxOcioso + dir + ociosos.length * 2) % ociosos.length;
    const id = ociosos[this._idxOcioso];
    this.seleccionar([id], false);
    this.ctx.camCtrl?.enfocar?.(w.px[id], w.pz[id]);
  }

  _irASede() {
    const w = this.ctx.mundo, j = this.ctx.jugadorLocal;
    const sede = EDIFICIO_POR_CLAVE.get('sede');
    for (let id = 0; id < w.maxUsado; id++) {
      if (!w.vivo[id] || w.tipo[id] !== TIPO.EDIFICIO) continue;
      if (w.jugador[id] !== j || w.defId[id] !== sede) continue;
      this.ctx.camCtrl?.enfocar?.(w.px[id], w.pz[id]);
      return;
    }
  }

  /* ================================================================
   *  Modo construcción
   * ================================================================ */

  _emplazar(encolar) {
    const c = this.construccion;
    if (!c) return;
    const colonos = this._colonosSeleccionados();
    if (!colonos.length) { this._salirConstruccion(); return; }
    const ord = this.ctx.ordenes;
    let puestos = 0;
    if (c.muro && c.celdas.length > 1) {
      for (let i = 0; i < c.celdas.length; i++) {
        const cel = c.celdas[i];
        if (!cel.ok) continue;
        if (ord?.construir(colonos, c.clave, cel.x, cel.z, 0, encolar || puestos > 0)) puestos++;
      }
    } else if (c.valido) {
      if (ord?.construir(colonos, c.clave, c.x, c.z, c.rot * Math.PI * 0.5, encolar)) puestos++;
    } else {
      bus.emit('aviso', { texto: 'No se puede construir ahí', tipo: 'error' });
    }
    c.inicio = null;
    c.celdas.length = 0;
    if (!encolar && puestos) this._salirConstruccion();
  }

  _salirConstruccion() {
    if (!this.construccion) return;
    this.construccion = null;
    if (this._fantasma.parent) this.ctx.escena?.remove?.(this._fantasma);
    this._muroInst.count = 0;
    this._muroMal.count = 0;
    this.lienzo.style.cursor = '';
    bus.emit('construccion:salida');
  }

  _colonosSeleccionados() {
    const w = this.ctx.mundo, j = this.ctx.jugadorLocal;
    const out = [];
    for (let i = 0; i < this.lista.length; i++) {
      const id = this.lista[i];
      if (!w.vivo[id] || w.jugador[id] !== j || w.tipo[id] !== TIPO.UNIDAD) continue;
      if (UNIDADES[w.defId[id]]?.clase !== 'aldeano') continue;
      out.push(id);
    }
    return out;
  }

  _actualizarFantasma() {
    const c = this.construccion;
    const p = this._puntoCursor();
    if (!p) return;
    const w = this.ctx.mundo;
    const swap = c.rot % 2 === 1;
    const cw = swap ? c.def.celdas[1] : c.def.celdas[0];
    const ch = swap ? c.def.celdas[0] : c.def.celdas[1];
    const x = this._encajar(p.x, cw);
    const z = this._encajar(p.z, ch);

    if (c.muro && this._abajo && c.inicio) {
      this._lineaMuro(c, c.inicio.x, c.inicio.z, x, z);
      if (this._fantasma.parent) this.ctx.escena?.remove?.(this._fantasma);
      return;
    }
    this._muroInst.count = 0; this._muroMal.count = 0;

    c.x = x; c.z = z;
    c.valido = this._sePuede(x, z, cw, ch, c.def);
    const y = this.ctx.terreno?.altura?.(x, z) ?? 0;
    this._fantasma.position.set(x, y, z);
    this._fantasma.rotation.y = c.rot * Math.PI * 0.5;
    this._tinte(c.valido);
    if (!this._fantasma.parent) this.ctx.escena?.add?.(this._fantasma);
  }

  /** Línea de segmentos de muralla entre dos celdas. */
  _lineaMuro(c, x0, z0, x1, z1) {
    const ax = this._encajar(x0, 1), az = this._encajar(z0, 1);
    const bx = this._encajar(x1, 1), bz = this._encajar(z1, 1);
    const dx = bx - ax, dz = bz - az;
    const pasos = Math.min(MAX_MURO, Math.max(Math.abs(dx), Math.abs(dz)) / CELDA);
    const n = Math.floor(pasos) + 1;
    c.celdas.length = 0;
    const eco = this.ctx.eco?.recursos?.[this.ctx.jugadorLocal];
    const costeUnit = c.def.coste.materiales || 0;
    let presupuesto = eco ? Math.floor((eco.materiales || 0) / Math.max(1, costeUnit)) : n;
    let ok = 0, mal = 0;
    for (let i = 0; i < n; i++) {
      const t = n === 1 ? 0 : i / (n - 1);
      const x = this._encajar(ax + dx * t, 1);
      const z = this._encajar(az + dz * t, 1);
      if (c.celdas.some((q) => q.x === x && q.z === z)) continue;
      const puede = this._sePuede(x, z, 1, 1, c.def) && presupuesto > 0;
      if (puede) presupuesto--;
      c.celdas.push({ x, z, ok: puede });
      const y = this.ctx.terreno?.altura?.(x, z) ?? 0;
      this._mat4.makeTranslation(x, y + 1.4, z);
      if (puede) this._muroInst.setMatrixAt(ok++, this._mat4);
      else this._muroMal.setMatrixAt(mal++, this._mat4);
    }
    this._muroInst.count = ok; this._muroMal.count = mal;
    this._muroInst.instanceMatrix.needsUpdate = true;
    this._muroMal.instanceMatrix.needsUpdate = true;
  }

  /** Encaja a la grilla de 2 m: par → borde de celda, impar → centro de celda. */
  _encajar(v, celdas) {
    const m = celdas % 2 === 0 ? 0 : 1;
    return Math.round((v - m) / CELDA) * CELDA + m;
  }

  _sePuede(x, z, cw, ch, def) {
    const ctx = this.ctx;
    const lim = (ctx.terreno?.tam ?? 512) * 0.5 - 4;
    if (Math.abs(x) > lim || Math.abs(z) > lim) return false;
    const ox = (cw - 1) * CELDA * 0.5, oz = (ch - 1) * CELDA * 0.5;
    let aguaCerca = false;
    for (let i = 0; i < cw; i++) {
      for (let k = 0; k < ch; k++) {
        const cx = x - ox + i * CELDA, cz = z - oz + k * CELDA;
        if (ctx.terreno?.transitable && !ctx.terreno.transitable(cx, cz)) return false;
        if (ctx.terreno?.pendiente && ctx.terreno.pendiente(cx, cz) > 0.34) return false;
        if (ctx.nav?.esLibre && !ctx.nav.esLibre(cx, cz, 0.85)) return false;
      }
    }
    if (def.costero) {
      for (let a = 0; a < 12 && !aguaCerca; a++) {
        const ang = (a / 12) * Math.PI * 2;
        const r = Math.max(cw, ch) * CELDA * 0.5 + 4;
        if (ctx.terreno?.bioma?.(x + Math.cos(ang) * r, z + Math.sin(ang) * r) === 'agua') aguaCerca = true;
      }
      if (!aguaCerca) return false;
    }
    return true;
  }

  /* ================================================================
   *  Presentación (rectángulo y fantasmas)
   * ================================================================ */

  _crearRect() {
    const d = document.createElement('div');
    d.id = 'rect-seleccion';
    const s = d.style;
    s.position = 'fixed'; s.left = '0'; s.top = '0'; s.width = '0'; s.height = '0';
    s.border = '1px solid rgba(150,255,180,0.95)';
    s.background = 'rgba(120,255,170,0.10)';
    s.boxShadow = '0 0 0 1px rgba(0,0,0,0.35) inset';
    s.pointerEvents = 'none';
    s.zIndex = '45';
    s.display = 'none';
    (document.getElementById('app') || document.body).appendChild(d);
    this._rect = d;
  }

  _pintarRect() {
    const x = Math.min(this._x0, this._x1), y = Math.min(this._y0, this._y1);
    const w = Math.abs(this._x1 - this._x0), h = Math.abs(this._y1 - this._y0);
    const s = this._rect.style;
    s.transform = `translate(${x}px, ${y}px)`;
    s.width = `${w}px`; s.height = `${h}px`;
  }

  _crearFantasmas() {
    this._mat4 = new THREE.Matrix4();
    this._cacheFantasma = new Map();
    this._fantasma = new THREE.Group();
    this._fantasma.renderOrder = 900;
    this._matsFantasma = [];

    const geo = new THREE.BoxGeometry(CELDA, 3, CELDA);
    const matOk = new THREE.MeshBasicMaterial({ color: 0x5ee08a, transparent: true, opacity: 0.42, depthWrite: false });
    const matMal = new THREE.MeshBasicMaterial({ color: 0xe0503c, transparent: true, opacity: 0.42, depthWrite: false });
    this._muroInst = new THREE.InstancedMesh(geo, matOk, MAX_MURO);
    this._muroMal = new THREE.InstancedMesh(geo, matMal, MAX_MURO);
    this._muroInst.count = 0; this._muroMal.count = 0;
    this._muroInst.frustumCulled = false; this._muroMal.frustumCulled = false;
    this._muroInst.renderOrder = 900; this._muroMal.renderOrder = 900;
    this.ctx.escena?.add?.(this._muroInst);
    this.ctx.escena?.add?.(this._muroMal);
  }

  _montarFantasma(clave) {
    this._fantasma.clear();
    this._matsFantasma.length = 0;
    let piezas = this._cacheFantasma.get(clave);
    if (!piezas) {
      const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];
      const w = def.celdas[0] * CELDA, d = def.celdas[1] * CELDA;
      const h = Math.max(2.6, Math.min(w, d) * 0.85);
      const matCaja = new THREE.MeshBasicMaterial({ color: 0x5ee08a, transparent: true, opacity: 0.30, depthWrite: false });
      const matBase = new THREE.MeshBasicMaterial({ color: 0x5ee08a, transparent: true, opacity: 0.22, depthWrite: false, side: THREE.DoubleSide });
      const matLinea = new THREE.LineBasicMaterial({ color: 0xbdffd6, transparent: true, opacity: 0.95, depthTest: false });
      const gCaja = new THREE.BoxGeometry(w, h, d);
      const caja = new THREE.Mesh(gCaja, matCaja); caja.position.y = h * 0.5;
      const bordes = new THREE.LineSegments(new THREE.EdgesGeometry(gCaja), matLinea); bordes.position.y = h * 0.5;
      const base = new THREE.Mesh(new THREE.PlaneGeometry(w, d), matBase);
      base.rotation.x = -Math.PI * 0.5; base.position.y = 0.08;
      piezas = { objetos: [base, caja, bordes], mats: [matCaja, matBase, matLinea] };
      this._cacheFantasma.set(clave, piezas);
    }
    for (const o of piezas.objetos) { o.frustumCulled = false; this._fantasma.add(o); }
    for (const m of piezas.mats) this._matsFantasma.push(m);
  }

  _tinte(valido) {
    const col = valido ? 0x5ee08a : 0xe0503c;
    for (let i = 0; i < this._matsFantasma.length; i++) this._matsFantasma[i].color.setHex(col);
  }

  _actualizarCursor() {
    if (!this.lista.length) { this._ponerCursor(''); return; }
    const id = this.entidadBajoCursor();
    if (id === this._hover) return;
    this._hover = id;
    if (id < 0) { this._ponerCursor(''); return; }
    const w = this.ctx.mundo, j = this.ctx.jugadorLocal;
    const jb = w.jugador[id];
    if (jb !== j && jb !== 255) this._ponerCursor('crosshair');
    else if (w.tipo[id] === TIPO.RECURSO) this._ponerCursor('grab');
    else this._ponerCursor('pointer');
  }

  _ponerCursor(c) {
    if (this._cursor === c) return;
    this._cursor = c;
    this.lienzo.style.cursor = c;
  }

  /* ================================================================
   *  Geometría de pantalla
   * ================================================================ */

  _puntoCursor() { return this.ctx.camCtrl?.puntoSueloCursor?.() || null; }

  _proyectar(x, y, z, salida) {
    _v.set(x, y, z).project(this.ctx.camara);
    if (_v.z > 1) return false;                     // detrás de la cámara
    salida.x = (_v.x * 0.5 + 0.5) * this._w;
    salida.y = (-_v.y * 0.5 + 0.5) * this._h;
    return true;
  }

  _pixelesPorMetro() {
    const cam = this.ctx.camara;
    const dist = this.ctx.camCtrl?.distancia || 78;
    const fov = (cam.fov || 55) * Math.PI / 180;
    return (this._h * 0.5) / (Math.tan(fov * 0.5) * Math.max(1, dist));
  }
}
