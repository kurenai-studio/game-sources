/**
 * Minimapa — el mapa del imperio en una esquina, con la misma lectura que el de
 * Age of Empires II: relieve sombreado, niebla en dos tonos (negro = sin
 * explorar, velo = explorado pero sin visión), puntos por color de jugador y el
 * trapecio del frustum de la cámara.
 *
 * Cómo está armado, en capas:
 *   1. TERRENO   se pinta UNA sola vez a un canvas fuera de pantalla, con
 *                sombreado de relieve derivado del campo de alturas.
 *   2. NIEBLA    se rearma a 10 Hz desde `ctx.niebla.pintura` (RG: R explorado,
 *                G visible). La grilla de niebla es de 256, igual que el lienzo,
 *                así que el volcado es 1:1 y sin remuestreo.
 *   3. PUNTOS    entidades: propias siempre, ajenas sólo si las ves ahora, más
 *                los fantasmas de edificios recordados (ctx.niebla.recuerdos).
 *   4. FRUSTUM   el cuadrilátero que ve la cámara, redibujado por frame sobre el
 *                compuesto cacheado (un blit de 256×256, baratísimo).
 *
 * El trabajo caro (recorrer el mundo, releer la niebla) va a 10 Hz. Lo único que
 * corre por frame es un `drawImage` y cuatro líneas.
 *
 * Interacción: izquierdo mueve la cámara, derecho da la orden contextual en ese
 * punto del mundo. Los ataques dejan un destello rojo que late unos segundos.
 */

import { TIPO } from '../core/World.js';
import { COLORES_JUGADOR } from '../data/civilizaciones.js';
import { NODOS, RECURSOS, IDX_RECURSO } from '../data/recursos.js';
import * as MapaGen from '../world/MapaGenerador.js';

const LADO = 256;                 // resolución interna del lienzo (= grilla de niebla)
const PERIODO = 0.1;              // 10 Hz para las capas caras
const VIDA_ALERTA = 4.0;          // segundos que late un destello de ataque

/* Paleta de biomas: cálida y saturada, para que el minimapa se lea de un vistazo. */
const COLOR_BIOMA = [
  [126, 152, 62],   // 0 pradera
  [58, 96, 44],     // 1 bosque
  [130, 120, 106],  // 2 montaña
  [196, 168, 100],  // 3 desierto
  [222, 202, 142],  // 4 playa
  [38, 86, 122],    // 5 agua
];
const NOMBRE_BIOMA = ['pradera', 'bosque', 'montana', 'desierto', 'playa', 'agua'];

/** Nodos que sí merecen un punto propio (los árboles ya los pinta el bioma). */
const NODOS_PUNTUALES = new Set(['baya', 'ciervo', 'jabali', 'pez', 'veta_oro', 'carbon', 'pozo_petroleo', 'reliquia']);

export class Minimapa {
  constructor(ctx, contenedor) {
    this.ctx = ctx;
    this.contenedor = contenedor || document.body;

    this.tam = ctx?.mapa?.tam ?? ctx?.terreno?.tam ?? 512;
    this.medio = this.tam * 0.5;

    this.lienzo = document.createElement('canvas');
    this.lienzo.width = LADO;
    this.lienzo.height = LADO;
    this.lienzo.className = 'minimapa-lienzo';
    this.g = this.lienzo.getContext('2d', { alpha: false });
    this.g.imageSmoothingEnabled = false;
    this.contenedor.appendChild(this.lienzo);

    this.terreno = this._lienzoAuxiliar();      // relieve, se pinta una vez
    this.velo = this._lienzoAuxiliar(true);     // niebla, 10 Hz
    this.compuesto = this._lienzoAuxiliar();    // terreno + niebla + puntos

    this._imgNiebla = this.velo.g.createImageData(LADO, LADO);
    this._acum = PERIODO;
    this._tiempo = 0;
    this._dt = 0.016;
    this._terrenoListo = false;
    this._alertas = [];
    this._colores = COLORES_JUGADOR.map((h) => h);
    this._buf = [];

    this._pintarTerreno();
    this._instalarEntrada();
  }

  /* ================================================================== *
   *  API pública
   * ================================================================== */

  /** Llamalo por frame: se encarga solo de repartir el trabajo en el tiempo. */
  actualizar(dt) {
    const paso = dt > 0.25 ? 0.25 : (dt > 0 ? dt : 0.016);
    this._dt = paso;
    this._tiempo += paso;
    this._acum += paso;
    if (!this._terrenoListo) this._pintarTerreno();

    if (this._acum >= PERIODO) {
      this._acum = 0;
      this._refrescarNiebla();
      this._componer();
    }
    this._pintarPantalla();
  }

  /** Click sobre el minimapa, en píxeles CSS relativos al contenedor. */
  click(x, y, boton = 0, encolar = false) {
    const p = this.aMundo(x, y);
    if (!p) return null;
    const ctx = this.ctx;
    if (boton === 2) {
      const ids = ctx.seleccion?.ids;
      if (ids && ids.size) {
        ctx.ordenes?.mover?.(ids, p.x, p.z, encolar);
        this.marcarOrden(p.x, p.z);
      }
    } else {
      ctx.camCtrl?.enfocar?.(p.x, p.z);
    }
    return p;
  }

  /** Coordenadas de mundo a partir de píxeles del contenedor. */
  aMundo(x, y) {
    const r = this.lienzo.getBoundingClientRect();
    if (!r.width || !r.height) return null;
    const u = Math.min(1, Math.max(0, x / r.width));
    const v = Math.min(1, Math.max(0, y / r.height));
    return { x: u * this.tam - this.medio, z: v * this.tam - this.medio };
  }

  /** Destello rojo: algo tuyo está siendo atacado ahí. */
  alerta(x, z, color = '#ff4a3a') {
    if (this._alertas.length > 12) this._alertas.shift();
    this._alertas.push({ x, z, t: VIDA_ALERTA, color });
  }

  /** Destello suave de confirmación de orden. */
  marcarOrden(x, z) {
    this.alerta(x, z, '#9de8a8');
    this._alertas[this._alertas.length - 1].t = 1.1;
  }

  /** Si el mundo se regenera, obligamos a repintar el relieve. */
  invalidarTerreno() { this._terrenoListo = false; }

  liberar() {
    this.lienzo.remove();
    this._alertas.length = 0;
  }

  /* ================================================================== *
   *  Capa 1 — relieve
   * ================================================================== */

  _lienzoAuxiliar(conAlfa = false) {
    const c = document.createElement('canvas');
    c.width = LADO; c.height = LADO;
    const g = c.getContext('2d', { alpha: conAlfa });
    g.imageSmoothingEnabled = false;
    return { c, g };
  }

  _pintarTerreno() {
    const campos = this._camposDelMapa();
    if (!campos) return;                     // todavía no hay mundo: se reintenta

    const { alturas, biomas, res, muestrear } = campos;
    const g = this.terreno.g;
    const img = g.createImageData(LADO, LADO);
    const d = img.data;
    const nivelAgua = this.ctx?.agua?.nivel ?? this.ctx?.mapa?.nivelAgua ?? 0;

    const altura = (i, j) => {
      if (alturas) {
        const ii = Math.min(res - 1, Math.max(0, i));
        const jj = Math.min(res - 1, Math.max(0, j));
        return alturas[jj * res + ii];
      }
      return muestrear.altura(i, j);
    };

    let p = 0;
    for (let j = 0; j < LADO; j++) {
      const fj = (j / (LADO - 1)) * (res - 1);
      const rj = Math.round(fj);
      for (let i = 0; i < LADO; i++, p += 4) {
        const fi = (i / (LADO - 1)) * (res - 1);
        const ri = Math.round(fi);

        let b = 0;
        if (biomas) b = biomas[rj * res + ri] | 0;
        else b = muestrear.bioma(ri, rj);
        if (b < 0 || b > 5) b = 0;

        const h = altura(ri, rj);
        const base = COLOR_BIOMA[b];
        let r = base[0], v = base[1], a = base[2];

        if (b === 5) {
          // Agua: cuanto más honda, más oscura y más azul.
          const hondo = Math.min(1, Math.max(0, (nivelAgua - h) / 14));
          r = 30 + (1 - hondo) * 44;
          v = 74 + (1 - hondo) * 52;
          a = 112 + (1 - hondo) * 40;
        } else {
          // Relieve: derivada del campo de alturas con el sol al noroeste.
          const dx = altura(ri + 1, rj) - altura(ri - 1, rj);
          const dz = altura(ri, rj + 1) - altura(ri, rj - 1);
          let luz = 1 + (-dx * 0.058 - dz * 0.042);
          if (luz < 0.55) luz = 0.55; else if (luz > 1.42) luz = 1.42;
          // un pelín de variación de tinte para que no quede plano
          const tinte = 1 + ((ri * 7 + rj * 13) % 5 - 2) * 0.012;
          r = Math.min(255, r * luz * tinte);
          v = Math.min(255, v * luz * tinte);
          a = Math.min(255, a * luz);
        }
        d[p] = r; d[p + 1] = v; d[p + 2] = a; d[p + 3] = 255;
      }
    }
    g.putImageData(img, 0, 0);

    // Marco interior sutil: le da profundidad al disco del mapa.
    g.save();
    const vig = g.createRadialGradient(LADO / 2, LADO / 2, LADO * 0.32, LADO / 2, LADO / 2, LADO * 0.78);
    vig.addColorStop(0, 'rgba(0,0,0,0)');
    vig.addColorStop(1, 'rgba(0,0,0,0.34)');
    g.fillStyle = vig;
    g.fillRect(0, 0, LADO, LADO);
    g.restore();

    this._terrenoListo = true;
  }

  /**
   * Consigue el campo de alturas y biomas de donde se pueda: primero la
   * previsualización del generador (si la expone), después los arrays crudos del
   * mapa y, en última instancia, muestreando el terreno a mano.
   */
  _camposDelMapa() {
    const m = this.ctx?.mapa;

    // 1) el generador puede regalarnos un ImageData/canvas ya pintado
    const prev = MapaGen?.previsualizarMapa;
    if (typeof prev === 'function') {
      try {
        const r = prev(m || this.ctx, LADO);
        if (r) {
          const g = this.terreno.g;
          if (typeof ImageData !== 'undefined' && r instanceof ImageData) { g.putImageData(r, 0, 0); this._terrenoListo = true; return null; }
          if (r.width && (r.getContext || r.tagName === 'CANVAS')) { g.drawImage(r, 0, 0, LADO, LADO); this._terrenoListo = true; return null; }
        }
      } catch (e) { /* el generador todavía no está listo: seguimos por abajo */ }
    }

    const esArray = (v) => v && ArrayBuffer.isView(v) && v.length > 16;
    const alturas = esArray(m?.alturas) ? m.alturas : (esArray(m?.alt) ? m.alt : (esArray(m?.campoAlturas) ? m.campoAlturas : null));
    const biomas = esArray(m?.biomas) ? m.biomas : (esArray(m?.bio) ? m.bio : null);

    if (alturas || biomas) {
      const largo = (alturas || biomas).length;
      const res = m?.res || Math.round(Math.sqrt(largo));
      if (res * res <= largo) {
        return { alturas, biomas: biomas && biomas.length >= res * res ? biomas : null, res, muestrear: this._muestreador(res) };
      }
    }

    // 3) sin arrays: muestreamos el terreno UNA vez a una grilla propia y de ahí
    //    en más trabajamos como en el caso anterior (nada de 300k raycasts).
    const t = this.ctx?.terreno;
    if (t?.altura && t?.bioma) {
      const res = 192;
      const m = this._muestreador(res);
      const alt = new Float32Array(res * res);
      const bio = new Uint8Array(res * res);
      for (let j = 0; j < res; j++) {
        for (let i = 0; i < res; i++) {
          alt[j * res + i] = m.altura(i, j);
          bio[j * res + i] = m.bioma(i, j);
        }
      }
      return { alturas: alt, biomas: bio, res, muestrear: m };
    }
    return null;
  }

  _muestreador(res) {
    const t = this.ctx?.terreno;
    const paso = this.tam / (res - 1);
    const medio = this.medio;
    return {
      altura: (i, j) => {
        if (!t?.altura) return 0;
        const x = -medio + Math.min(res - 1, Math.max(0, i)) * paso;
        const z = -medio + Math.min(res - 1, Math.max(0, j)) * paso;
        const h = t.altura(x, z);
        return Number.isFinite(h) ? h : 0;
      },
      bioma: (i, j) => {
        if (!t?.bioma) return 0;
        const x = -medio + i * paso;
        const z = -medio + j * paso;
        const n = NOMBRE_BIOMA.indexOf(t.bioma(x, z));
        return n < 0 ? 0 : n;
      },
    };
  }

  /* ================================================================== *
   *  Capa 2 — niebla
   * ================================================================== */

  _refrescarNiebla() {
    const n = this.ctx?.niebla;
    const g = this.velo.g;
    const img = this._imgNiebla;
    const d = img.data;

    const pintura = n?.pintura;
    const lado = n?.N || LADO;

    if (!pintura || n?.activa === false) {
      // Sin niebla (o modo espía): la capa queda transparente.
      g.clearRect(0, 0, LADO, LADO);
      return;
    }

    const escala = lado / LADO;
    let p = 0;
    for (let j = 0; j < LADO; j++) {
      const sj = escala === 1 ? j : Math.min(lado - 1, (j * escala) | 0);
      const fila = sj * lado;
      for (let i = 0; i < LADO; i++, p += 4) {
        const si = escala === 1 ? i : Math.min(lado - 1, (i * escala) | 0);
        const k = (fila + si) * 2;
        const explorado = pintura[k];
        const visible = pintura[k + 1];
        let alfa;
        if (explorado < 60) alfa = 255;                       // jamás pisado: negro
        else if (visible > 150) alfa = 0;                     // a la vista
        else alfa = 96 + (1 - visible / 255) * 42;            // recordado: velo
        d[p] = 4; d[p + 1] = 7; d[p + 2] = 11; d[p + 3] = alfa;
      }
    }
    g.putImageData(img, 0, 0);
  }

  /* ================================================================== *
   *  Capa 3 — puntos
   * ================================================================== */

  _componer() {
    const g = this.compuesto.g;
    g.clearRect(0, 0, LADO, LADO);
    g.drawImage(this.terreno.c, 0, 0);

    this._puntosRecursos(g);
    this._puntosEntidades(g);

    g.drawImage(this.velo.c, 0, 0);

    this._fantasmas(g);
  }

  _aLienzoX(x) { return ((x + this.medio) / this.tam) * LADO; }
  _aLienzoZ(z) { return ((z + this.medio) / this.tam) * LADO; }

  _puntosRecursos(g) {
    const w = this.ctx?.mundo;
    const n = this.ctx?.niebla;
    if (!w) return;
    const jl = this.ctx.jugadorLocal | 0;
    for (let id = 0; id < w.maxUsado; id++) {
      if (!w.vivo[id] || w.tipo[id] !== TIPO.RECURSO) continue;
      const def = NODOS[w.defId[id]];
      if (!def || !NODOS_PUNTUALES.has(def.clave)) continue;
      const x = w.px[id], z = w.pz[id];
      if (n?.explorado && !n.explorado(jl, x, z)) continue;
      const rec = RECURSOS[IDX_RECURSO[def.recurso] ?? 0];
      g.fillStyle = def.reliquia ? '#f0e0a0' : (rec?.color || '#ddd');
      g.fillRect(this._aLienzoX(x) - 0.5 | 0, this._aLienzoZ(z) - 0.5 | 0, 2, 2);
    }
  }

  _puntosEntidades(g) {
    const w = this.ctx?.mundo;
    if (!w) return;
    const jl = this.ctx.jugadorLocal | 0;

    // Dos pasadas: primero unidades, después edificios, para que los edificios
    // (que son el ancla visual del mapa) queden siempre arriba.
    for (let pasada = 0; pasada < 2; pasada++) {
      const buscado = pasada === 0 ? TIPO.UNIDAD : TIPO.EDIFICIO;
      for (let id = 0; id < w.maxUsado; id++) {
        if (!w.vivo[id] || w.tipo[id] !== buscado) continue;
        const j = w.jugador[id];
        const propio = j === jl;
        if (!propio && w.visible[id] === 0) continue;
        const cx = this._aLienzoX(w.px[id]);
        const cz = this._aLienzoZ(w.pz[id]);
        const color = j === 255 ? '#cfc6b0' : this._colores[j % this._colores.length];
        if (buscado === TIPO.EDIFICIO) {
          g.fillStyle = 'rgba(0,0,0,0.55)';
          g.fillRect((cx | 0) - 2, (cz | 0) - 2, 5, 5);
          g.fillStyle = color;
          g.fillRect((cx | 0) - 1, (cz | 0) - 1, 3, 3);
        } else {
          g.fillStyle = color;
          g.fillRect((cx | 0) - 1, (cz | 0) - 1, propio ? 3 : 2, propio ? 3 : 2);
        }
      }
    }
  }

  /** Edificios enemigos que ya viste y seguís recordando bajo la niebla. */
  _fantasmas(g) {
    const n = this.ctx?.niebla;
    if (!n?.recuerdos) return;
    let lista;
    try { lista = n.recuerdos(this.ctx.jugadorLocal | 0); } catch (e) { return; }
    if (!lista || !lista.length) return;
    g.save();
    g.globalAlpha = 0.62;
    for (let i = 0; i < lista.length; i++) {
      const r = lista[i];
      if (!r || r.x === undefined) continue;
      const cx = this._aLienzoX(r.x) | 0;
      const cz = this._aLienzoZ(r.z) | 0;
      g.fillStyle = 'rgba(0,0,0,0.6)';
      g.fillRect(cx - 2, cz - 2, 5, 5);
      g.fillStyle = this._colores[(r.jugador | 0) % this._colores.length];
      g.fillRect(cx - 1, cz - 1, 3, 3);
    }
    g.restore();
  }

  /* ================================================================== *
   *  Capa 4 — frustum, alertas y volcado a pantalla
   * ================================================================== */

  _pintarPantalla() {
    const g = this.g;
    g.drawImage(this.compuesto.c, 0, 0);
    this._dibujarAlertas(g);
    this._dibujarFrustum(g);
  }

  _dibujarFrustum(g) {
    const cam = this.ctx?.camCtrl;
    if (!cam?.puntoSuelo) return;
    const esquinas = [[-1, 1], [1, 1], [1, -1], [-1, -1]];
    let ok = true;
    const pts = this._buf;
    pts.length = 0;
    for (let i = 0; i < 4; i++) {
      const p = cam.puntoSuelo(esquinas[i][0] * 0.985, esquinas[i][1] * 0.985);
      if (!p) { ok = false; break; }
      // el horizonte puede escaparse muy lejos: lo recortamos al borde del mapa
      const lim = this.medio * 1.6;
      pts.push(Math.max(-lim, Math.min(lim, p.x)), Math.max(-lim, Math.min(lim, p.z)));
    }
    if (!ok || pts.length < 8) return;

    g.save();
    g.beginPath();
    g.moveTo(this._aLienzoX(pts[0]), this._aLienzoZ(pts[1]));
    for (let i = 1; i < 4; i++) g.lineTo(this._aLienzoX(pts[i * 2]), this._aLienzoZ(pts[i * 2 + 1]));
    g.closePath();
    g.lineWidth = 3;
    g.strokeStyle = 'rgba(0,0,0,0.55)';
    g.stroke();
    g.lineWidth = 1.25;
    g.strokeStyle = 'rgba(255,255,255,0.92)';
    g.stroke();
    g.restore();
  }

  _dibujarAlertas(g) {
    const A = this._alertas;
    if (!A.length) return;
    const dt = this._dt || 0.016;
    for (let i = A.length - 1; i >= 0; i--) {
      const a = A[i];
      a.t -= dt;
      if (a.t <= 0) { A.splice(i, 1); continue; }
      const fase = (Math.sin(this._tiempo * 11) * 0.5 + 0.5);
      const r = 3 + fase * 6 + (VIDA_ALERTA - a.t) * 0.6;
      g.save();
      g.globalAlpha = Math.min(1, a.t / 1.2) * (0.45 + fase * 0.55);
      g.strokeStyle = a.color;
      g.lineWidth = 1.6;
      g.beginPath();
      g.arc(this._aLienzoX(a.x), this._aLienzoZ(a.z), r, 0, Math.PI * 2);
      g.stroke();
      g.restore();
    }
  }

  /* ================================================================== *
   *  Entrada
   * ================================================================== */

  _instalarEntrada() {
    const el = this.contenedor;
    let arrastrando = false;

    const local = (e) => {
      const r = this.lienzo.getBoundingClientRect();
      return { x: e.clientX - r.left, y: e.clientY - r.top };
    };

    el.addEventListener('pointerdown', (e) => {
      const p = local(e);
      if (e.button === 0) {
        arrastrando = true;
        el.setPointerCapture?.(e.pointerId);
        this.click(p.x, p.y, 0, e.shiftKey);
      } else if (e.button === 2) {
        this.click(p.x, p.y, 2, e.shiftKey);
      }
      e.preventDefault();
      e.stopPropagation();
    });

    el.addEventListener('pointermove', (e) => {
      if (!arrastrando) return;
      const p = local(e);
      this.click(p.x, p.y, 0, false);
      e.stopPropagation();
    });

    const soltar = (e) => {
      if (arrastrando) { arrastrando = false; el.releasePointerCapture?.(e.pointerId); }
      e.stopPropagation();
    };
    el.addEventListener('pointerup', soltar);
    el.addEventListener('pointercancel', soltar);
    el.addEventListener('contextmenu', (e) => { e.preventDefault(); e.stopPropagation(); });
    el.addEventListener('wheel', (e) => { e.stopPropagation(); }, { passive: true });
  }
}
