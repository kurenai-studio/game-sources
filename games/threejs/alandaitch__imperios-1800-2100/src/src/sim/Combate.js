/**
 * COMBATE — daño, cadencia, adquisición de blanco, proyectiles con física real,
 * conversión, curación, veteranía y muerte.
 *
 * Filosofía (vara: Age of Empires II DE):
 *  - La orden del jugador manda SIEMPRE por encima de la postura.
 *  - El golpe se resuelve a mitad de la animación de ataque, no al apretar el botón:
 *    así la mano y el impacto se ven juntos.
 *  - Los proyectiles vuelan de verdad. Un obús describe una parábola resuelta,
 *    un misil gira con radio limitado, un riel llega instantáneo y atraviesa.
 *  - Nada de asignaciones por entidad por tick: todo vive en arrays tipados.
 *
 * Contrato de sistema: { nombre:'combate', orden:50, fijo(dt,ctx), cada(dtReal,alfa,ctx) }
 */
import * as THREE from 'three';
import { ORDEN } from '../core/Ctx.js';
import { TIPO, ESTADO } from '../core/World.js';
import { RNG, clamp } from '../core/RNG.js';
import { bus } from '../core/EventBus.js';
import { UNIDADES } from '../data/unidades.js';
import { EDIFICIOS } from '../data/edificios.js';

/* ------------------------------------------------------------------ */
/* Tablas propias del módulo                                          */
/* ------------------------------------------------------------------ */

export const POSTURA = { AGRESIVA: 0, DEFENSIVA: 1, QUIETA: 2, NO_ATACAR: 3 };
const POSTURA_POR_NOMBRE = {
  agresiva: 0, defensiva: 1, quieta: 2, no_atacar: 3, noatacar: 3, pasiva: 3,
};
export const NOMBRE_POSTURA = ['agresiva', 'defensiva', 'quieta', 'no_atacar'];

/**
 * Tipos de proyectil. El índice ES el defId de la entidad TIPO.PROYECTIL,
 * así cualquiera puede preguntar `ctx.combate.datosProyectil(id)` para pintarlo.
 *  vel      m/s inicial (0 = lo resuelve la balística)
 *  grav     m/s² de caída
 *  guia     rad/s de giro máximo (0 = sin guiado)
 *  acel     m/s² de empuje del motor
 *  ttl      segundos de vuelo antes de autodestruirse
 */
export const PROYECTILES = [
  { clave: 'bala', vel: 115, grav: 2.6, guia: 0, acel: 0, ttl: 2.2,
    radio: 0.13, largo: 3.2, color: 0xffe9b0, estelaTtl: 0.10, humo: 0, sonido: 'disparo_bala' },
  { clave: 'obus', vel: 0, grav: 26, guia: 0, acel: 0, ttl: 7.0,
    radio: 0.26, largo: 1.6, color: 0xffc070, estelaTtl: 0.55, humo: 0.5, sonido: 'disparo_canon' },
  { clave: 'misil', vel: 22, grav: 0, guia: 3.0, acel: 40, ttl: 7.0,
    radio: 0.24, largo: 2.4, color: 0xffb050, estelaTtl: 1.10, humo: 1, sonido: 'disparo_misil' },
  { clave: 'cohete', vel: 26, grav: 1.4, guia: 1.1, acel: 30, ttl: 4.5,
    radio: 0.20, largo: 2.0, color: 0xffa040, estelaTtl: 0.75, humo: 1, sonido: 'disparo_cohete' },
  { clave: 'enjambre', vel: 18, grav: 0, guia: 2.6, acel: 26, ttl: 6.0,
    radio: 0.14, largo: 1.4, color: 0xc79dff, estelaTtl: 0.60, humo: 0.4, serpentea: 1, sonido: 'disparo_enjambre' },
  { clave: 'riel', vel: 0, grav: 0, guia: 0, acel: 0, ttl: 0,
    radio: 0.10, largo: 6.0, color: 0x9fe8ff, estelaTtl: 0.30, humo: 0, hitscan: 1, sonido: 'disparo_riel' },
];
const PROY_POR_CLAVE = new Map(PROYECTILES.map((p, i) => [p.clave, i]));

/** Cuántos submuniciones larga un 'enjambre'. */
const SUBMUNICIONES = 5;
/** Gravedad de juego para la balística (más alta que la real: arcos legibles). */
const G_OBUS = 26;

const MODS_VACIOS = Object.freeze({
  ataque: {}, armadura: {}, armaduraPerf: {}, alcance: {}, cadencia: {},
  vision: {}, velocidad: {}, vidaExtra: {},
});

const _v3a = new THREE.Vector3();
const _v3b = new THREE.Vector3();
const _color = new THREE.Color();
const _dummy = new THREE.Object3D();

/* ------------------------------------------------------------------ */
/* Capa visual propia: trazas, estelas y cuerpos de proyectil          */
/* ------------------------------------------------------------------ */

/**
 * Segmentos aditivos con desvanecido. Sirve para trazadoras, estelas de humo,
 * el rayo de riel y el haz de conversión. Un solo draw call.
 */
class CapaTrazas {
  constructor(ctx, max = 900) {
    this.max = max;
    this.n = 0;
    this.a = new Float32Array(max * 6);      // extremos
    this.rgb = new Float32Array(max * 3);
    this.ttl = new Float32Array(max);
    this.ttlMax = new Float32Array(max);

    const geo = new THREE.BufferGeometry();
    this.pos = new Float32Array(max * 6);
    this.col = new Float32Array(max * 6);
    geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3));
    geo.setAttribute('color', new THREE.BufferAttribute(this.col, 3));
    geo.setDrawRange(0, 0);
    const mat = new THREE.LineBasicMaterial({
      vertexColors: true, transparent: true, opacity: 0.95,
      blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false,
    });
    this.malla = new THREE.LineSegments(geo, mat);
    this.malla.frustumCulled = false;
    this.malla.renderOrder = 6;
    this.geo = geo;
    ctx.escena?.add(this.malla);
  }

  agregar(x1, y1, z1, x2, y2, z2, color, ttl) {
    let i = this.n;
    if (i >= this.max) {
      // buffer lleno: pisamos en round-robin (nada de escanear la lista entera)
      i = this.cursor;
      this.cursor = (this.cursor + 1) % this.max;
    } else this.n++;
    const o = i * 6;
    this.a[o] = x1; this.a[o + 1] = y1; this.a[o + 2] = z1;
    this.a[o + 3] = x2; this.a[o + 4] = y2; this.a[o + 5] = z2;
    _color.setHex(color);
    const c = i * 3;
    this.rgb[c] = _color.r; this.rgb[c + 1] = _color.g; this.rgb[c + 2] = _color.b;
    this.ttl[i] = ttl; this.ttlMax[i] = ttl;
  }

  actualizar(dt) {
    let w = 0;
    for (let i = 0; i < this.n; i++) {
      this.ttl[i] -= dt;
      if (this.ttl[i] <= 0) continue;
      if (w !== i) {
        const s = i * 6, d = w * 6, sc = i * 3, dc = w * 3;
        for (let k = 0; k < 6; k++) this.a[d + k] = this.a[s + k];
        for (let k = 0; k < 3; k++) this.rgb[dc + k] = this.rgb[sc + k];
        this.ttl[w] = this.ttl[i]; this.ttlMax[w] = this.ttlMax[i];
      }
      w++;
    }
    this.n = w;
    for (let i = 0; i < w; i++) {
      const o = i * 6, c = i * 3;
      for (let k = 0; k < 6; k++) this.pos[o + k] = this.a[o + k];
      const f = this.ttlMax[i] > 0 ? this.ttl[i] / this.ttlMax[i] : 0;
      const r = this.rgb[c] * f, g = this.rgb[c + 1] * f, b = this.rgb[c + 2] * f;
      this.col[o] = r; this.col[o + 1] = g; this.col[o + 2] = b;
      this.col[o + 3] = r * 0.25; this.col[o + 4] = g * 0.25; this.col[o + 5] = b * 0.25;
    }
    this.geo.setDrawRange(0, w * 2);
    this.geo.attributes.position.needsUpdate = true;
    this.geo.attributes.color.needsUpdate = true;
    this.malla.visible = w > 0;
  }
}

/** Cuerpos brillantes de los proyectiles (solo si la vista no los dibuja ella). */
class CapaCuerpos {
  constructor(ctx, max = 512) {
    this.max = max;
    const geo = new THREE.SphereGeometry(1, 6, 4);
    const mat = new THREE.MeshBasicMaterial({
      color: 0xffffff, blending: THREE.AdditiveBlending,
      depthWrite: false, transparent: true, toneMapped: false,
    });
    this.malla = new THREE.InstancedMesh(geo, mat, max);
    this.malla.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    this.malla.frustumCulled = false;
    this.malla.renderOrder = 5;
    this.malla.count = 0;
    ctx.escena?.add(this.malla);
    this.n = 0;
  }
  reiniciar() { this.n = 0; }
  poner(x, y, z, dx, dy, dz, radio, largo, color) {
    if (this.n >= this.max) return;
    const i = this.n++;
    _dummy.position.set(x, y, z);
    const l = Math.hypot(dx, dy, dz);
    if (l > 1e-4) {
      _v3a.set(dx / l, dy / l, dz / l);
      _dummy.quaternion.setFromUnitVectors(_v3b.set(0, 1, 0), _v3a);
    } else _dummy.quaternion.identity();
    _dummy.scale.set(radio, radio * largo, radio);
    _dummy.updateMatrix();
    this.malla.setMatrixAt(i, _dummy.matrix);
    _color.setHex(color);
    this.malla.setColorAt(i, _color);
  }
  aplicar() {
    this.malla.count = this.n;
    this.malla.instanceMatrix.needsUpdate = true;
    if (this.malla.instanceColor) this.malla.instanceColor.needsUpdate = true;
  }
}

/* ------------------------------------------------------------------ */
/* Sistema                                                             */
/* ------------------------------------------------------------------ */

export class Combate {
  constructor(ctx) {
    this.nombre = 'combate';
    this.orden = ORDEN.COMBATE;
    this.ctx = ctx;

    this.rng = ctx.rng?.fork ? ctx.rng.fork(0x636f6d62) : new RNG(0x636f6d62);

    const cap = ctx.mundo?.cap ?? 4096;
    this.cap = cap;

    /* ---- estado de combate por entidad ---- */
    this.postura_ = new Uint8Array(cap);        // POSTURA.*
    this.ordenExplicita = new Uint8Array(cap);  // 1 = el jugador eligió el blanco
    this.puestoX = new Float32Array(cap);       // ancla de la postura defensiva
    this.puestoZ = new Float32Array(cap);
    this.agresor = new Int32Array(cap).fill(-1);
    this.tAgresion = new Float32Array(cap);     // segundos que recuerda a su agresor
    this.golpeT = new Float32Array(cap);        // cuenta atrás hasta el frame de impacto
    this.golpeBlanco = new Int32Array(cap).fill(-1);
    this.tBusqueda = new Float32Array(cap);     // reescaneo escalonado
    this.muertesPropias = new Uint8Array(cap);
    this.persigueX = new Float32Array(cap);
    this.persigueZ = new Float32Array(cap);
    this.tRepath = new Float32Array(cap);
    this.muerteT = new Float32Array(cap);       // animación de muerte
    this.matador = new Int32Array(cap).fill(-1);

    /* ataque a posición / ataque en movimiento */
    this.lugarActivo = new Uint8Array(cap);
    this.lugarX = new Float32Array(cap);
    this.lugarZ = new Float32Array(cap);

    /* conversión / curación */
    this.convBlanco = new Int32Array(cap).fill(-1);
    this.convT = new Float32Array(cap);
    this.curaT = new Float32Array(cap);

    /* ---- proyectiles (paralelo a los arrays de World) ---- */
    this.prTipo = new Uint8Array(cap);
    this.prFuente = new Int32Array(cap).fill(-1);
    this.prBlanco = new Int32Array(cap).fill(-1);
    this.prDanio = new Float32Array(cap);
    this.prVy = new Float32Array(cap);
    this.prTtl = new Float32Array(cap);
    this.prSalp = new Float32Array(cap);
    this.prAmigo = new Uint8Array(cap);         // 1 = hace fuego amigo (asedio)
    this.prDestX = new Float32Array(cap);
    this.prDestZ = new Float32Array(cap);
    this.prDestY = new Float32Array(cap);
    this.prFase = new Float32Array(cap);        // serpenteo
    this.prPrevX = new Float32Array(cap);
    this.prPrevY = new Float32Array(cap);
    this.prPrevZ = new Float32Array(cap);
    this.prVisualPropia = new Uint8Array(cap);  // 0 no sabemos, 1 propia, 2 la pinta la vista

    /* buffers reusables para consultas espaciales */
    this._buf0 = []; this._buf1 = []; this._buf2 = [];
    this._proyectiles = [];   // ids activos, se reconstruye por tick

    this._tAviso = 0;
    this._acumVisual = 0;

    this.trazas = new CapaTrazas(ctx);
    this.cuerpos = new CapaCuerpos(ctx);

    /* alta/baja de entidades: inicializamos su estado de combate */
    this._alCrear = (id) => this._inicializar(id);
    this._alDestruir = (id) => this._limpiar(id);
    ctx.mundo?.alCrear?.add(this._alCrear);
    ctx.mundo?.alDestruir?.add(this._alDestruir);
    // entidades que ya existían antes de que naciera este sistema
    if (ctx.mundo) for (let i = 0; i < ctx.mundo.maxUsado; i++) if (ctx.mundo.vivo[i]) this._inicializar(i);
  }

  /* ================================================================ */
  /* Ciclo de vida                                                     */
  /* ================================================================ */

  _inicializar(id) {
    const M = this.ctx.mundo;
    this.golpeT[id] = 0; this.golpeBlanco[id] = -1;
    this.agresor[id] = -1; this.tAgresion[id] = 0;
    this.ordenExplicita[id] = 0;
    this.muerteT[id] = 0; this.matador[id] = -1;
    this.lugarActivo[id] = 0;
    this.convBlanco[id] = -1; this.convT[id] = 0; this.curaT[id] = 0;
    this.muertesPropias[id] = 0;
    this.puestoX[id] = M.px[id]; this.puestoZ[id] = M.pz[id];
    this.tBusqueda[id] = (id % 5) * 0.05;
    this.tRepath[id] = 0;
    if (M.tipo[id] === TIPO.PROYECTIL) { this.prVisualPropia[id] = 0; return; }
    this.postura_[id] = this._posturaPorDefecto(id);
  }

  _limpiar(id) {
    if (this.ctx.mundo.tipo[id] === TIPO.PROYECTIL) {
      this.prFuente[id] = -1; this.prBlanco[id] = -1; this.prTtl[id] = 0;
      this.prVisualPropia[id] = 0;
    }
    this.golpeBlanco[id] = -1;
    this.convBlanco[id] = -1;
  }

  _posturaPorDefecto(id) {
    const def = this._def(id);
    if (!def) return POSTURA.NO_ATACAR;
    if (this.ctx.mundo.tipo[id] === TIPO.EDIFICIO) return POSTURA.DEFENSIVA;
    if (def.clase === 'aldeano' || def.clase === 'apoyo') return POSTURA.NO_ATACAR;
    if (!def.ataque || !def.cadencia) return POSTURA.NO_ATACAR;
    return POSTURA.AGRESIVA;
  }

  /* ================================================================ */
  /* Consultas de datos (con degradación elegante)                     */
  /* ================================================================ */

  _def(id) {
    const M = this.ctx.mundo;
    const t = M.tipo[id];
    if (t === TIPO.UNIDAD) return UNIDADES[M.defId[id]] || null;
    if (t === TIPO.EDIFICIO) return EDIFICIOS[M.defId[id]] || null;
    return null;
  }

  _claseDe(id) {
    const M = this.ctx.mundo;
    if (M.tipo[id] === TIPO.EDIFICIO) return 'edificio';
    const d = UNIDADES[M.defId[id]];
    return d ? d.clase : 'infanteria';
  }

  _mods(jugador) { return this.ctx.eco?.mods?.[jugador] || MODS_VACIOS; }

  /** Radio de colisión utilizable aunque nadie lo haya seteado todavía. */
  _radioDe(id) {
    const M = this.ctx.mundo;
    const r = M.radio[id];
    if (r > 0.05) return r;
    const def = this._def(id);
    if (M.tipo[id] === TIPO.EDIFICIO && def?.celdas) {
      return (def.celdas[0] + def.celdas[1]) * 0.5 * 0.9; // celdas → metros (1 celda = 2 m)
    }
    return 0.45;
  }

  /** Altura a la que hay que apuntarle a una entidad. */
  _alturaBlanco(id) {
    const M = this.ctx.mundo;
    const base = M.py[id];
    if (M.tipo[id] === TIPO.EDIFICIO) {
      const d = this._def(id);
      const alto = d?.celdas ? clamp(d.celdas[0] * 0.9, 2.2, 8) : 3;
      return base + alto * 0.5;
    }
    const d = UNIDADES[M.defId[id]];
    if (d?.vuela) return base + 0.4;
    return base + 0.95;
  }

  /** Boca de fuego: de dónde sale el proyectil. */
  _alturaBoca(id) {
    const M = this.ctx.mundo;
    if (M.tipo[id] === TIPO.EDIFICIO) {
      const d = this._def(id);
      const alto = d?.celdas ? clamp(d.celdas[0] * 0.9, 2.2, 8) : 3;
      return M.py[id] + alto * 0.85;
    }
    const d = UNIDADES[M.defId[id]];
    if (d?.vuela) return M.py[id];
    if (d?.clase === 'asedio' || d?.clase === 'caballeria') return M.py[id] + 1.5;
    return M.py[id] + 1.15;
  }

  _ataqueDe(id) {
    const M = this.ctx.mundo;
    const def = this._def(id);
    if (!def) return 0;
    const clase = this._claseDe(id);
    const m = this._mods(M.jugador[id]);
    let a = (def.ataque || 0) + (m.ataque?.[clase] || 0);
    a *= 1 + 0.10 * M.veterania[id];
    return a;
  }

  _armaduraDe(id, perforante) {
    const def = this._def(id);
    if (!def) return 0;
    const clase = this._claseDe(id);
    const m = this._mods(this.ctx.mundo.jugador[id]);
    const base = perforante ? (def.armaduraPerf || 0) : (def.armadura || 0);
    const extra = perforante ? (m.armaduraPerf?.[clase] || 0) : (m.armadura?.[clase] || 0);
    return base + extra;
  }

  _alcanceDe(id) {
    const def = this._def(id);
    if (!def) return 0;
    const clase = this._claseDe(id);
    const m = this._mods(this.ctx.mundo.jugador[id]);
    return (def.alcance || 0) + (m.alcance?.[clase] || 0);
  }

  _cadenciaDe(id) {
    const def = this._def(id);
    if (!def || !def.cadencia) return 0;
    const clase = this._claseDe(id);
    const m = this._mods(this.ctx.mundo.jugador[id]);
    return Math.max(0.25, def.cadencia * (m.cadencia?.[clase] ?? 1));
  }

  _visionDe(id) {
    const def = this._def(id);
    if (!def) return 12;
    const clase = this._claseDe(id);
    const m = this._mods(this.ctx.mundo.jugador[id]);
    return (def.vision || 16) + (m.vision?.[clase] || 0);
  }

  /** Distancia a la que se considera "en alcance" contra un blanco concreto. */
  _rangoContra(id, blanco) {
    return this._alcanceDe(id) + this._radioDe(id) * 0.6 + this._radioDe(blanco);
  }

  _enConstruccion(id) {
    const M = this.ctx.mundo;
    if (M.tipo[id] !== TIPO.EDIFICIO) return false;
    if (M.estado[id] === ESTADO.CONSTRUYENDO) return true;
    const p = M.progreso[id];
    return p > 0.001 && p < 0.999;
  }

  _puedeAtacarAereo(id) {
    const def = this._def(id);
    if (!def) return false;
    if (def.vuela) return true;
    if (def.bonos?.aereo) return true;
    return !!def.proyectil && (def.alcance || 0) >= 2;
  }

  /* ================================================================ */
  /* API pública                                                       */
  /* ================================================================ */

  /** Recorre ids venga como venga (array, Set, número suelto). */
  _cada(ids, fn) {
    if (ids == null) return;
    if (typeof ids === 'number') { fn(ids); return; }
    for (const id of ids) fn(id);
  }

  /** Orden explícita de atacar a una entidad. Pisa cualquier postura. */
  ordenarAtacar(ids, objetivoId) {
    const M = this.ctx.mundo;
    if (objetivoId == null || objetivoId < 0 || !M.vivo[objetivoId]) return;
    let alguna = false;
    this._cada(ids, (id) => {
      if (!M.vivo[id] || M.estado[id] === ESTADO.MURIENDO) return;
      if (M.tipo[id] !== TIPO.UNIDAD && M.tipo[id] !== TIPO.EDIFICIO) return;
      if (id === objetivoId) return;
      const def = this._def(id);
      const puedeConvertir = !!def?.convierte;
      if (!def || (!def.ataque && !puedeConvertir)) return;
      if (M.jugador[objetivoId] === M.jugador[id] && !puedeConvertir) return;
      M.objetivo[id] = objetivoId;
      this.ordenExplicita[id] = 1;
      this.lugarActivo[id] = 0;
      this.convBlanco[id] = -1; this.convT[id] = 0;
      this.golpeBlanco[id] = -1; this.golpeT[id] = 0;
      this.puestoX[id] = M.px[id]; this.puestoZ[id] = M.pz[id];
      this.tRepath[id] = 0;
      alguna = true;
    });
    if (alguna) {
      this.ctx.audio?.sfx?.('orden_atacar', { x: M.px[objetivoId], z: M.pz[objetivoId] });
      bus.emit('combate:orden', { objetivo: objetivoId });
    }
  }

  /**
   * Ataque a una posición. Para artillería es fuego indirecto sobre el suelo;
   * para el resto es "ataque en movimiento": avanza y engancha lo que aparezca.
   */
  atacarLugar(ids, x, z) {
    const M = this.ctx.mundo;
    this._cada(ids, (id) => {
      if (!M.vivo[id] || M.tipo[id] !== TIPO.UNIDAD) return;
      const def = this._def(id);
      if (!def) return;
      this.lugarActivo[id] = 1;
      this.lugarX[id] = x; this.lugarZ[id] = z;
      this.ordenExplicita[id] = 0;
      M.objetivo[id] = -1;
      this.golpeBlanco[id] = -1; this.golpeT[id] = 0;
      if (this.postura_[id] === POSTURA.NO_ATACAR && def.ataque) this.postura_[id] = POSTURA.AGRESIVA;
      // la artillería se planta y tira; el resto camina hasta el punto
      const indirecto = def.clase === 'asedio' && !!def.proyectil;
      if (!indirecto) this._irHacia(id, x, z, true);
      this.puestoX[id] = x; this.puestoZ[id] = z;
    });
  }

  /** Cambia la postura. `modo` en texto ('agresiva'…) o número (POSTURA.*). */
  postura(ids, modo) {
    const M = this.ctx.mundo;
    const p = typeof modo === 'number' ? clamp(modo | 0, 0, 3) : (POSTURA_POR_NOMBRE[String(modo).toLowerCase()] ?? POSTURA.AGRESIVA);
    this._cada(ids, (id) => {
      if (!M.vivo[id]) return;
      this.postura_[id] = p;
      this.puestoX[id] = M.px[id]; this.puestoZ[id] = M.pz[id];
      if (p === POSTURA.NO_ATACAR) {
        M.objetivo[id] = -1; this.ordenExplicita[id] = 0;
        this.golpeBlanco[id] = -1; this.golpeT[id] = 0;
        this.convBlanco[id] = -1;
      }
    });
    bus.emit('combate:postura', { modo: NOMBRE_POSTURA[p] });
  }

  posturaDe(id) { return NOMBRE_POSTURA[this.postura_[id]] || 'agresiva'; }

  /**
   * Fórmula de daño estilo AoE2:
   *   daño = max(1, (ataque + bonos_contra_clase) - armadura_correspondiente)
   * `tipo`: 'cuerpo' usa armadura; cualquier otro ('perforante','distancia','area')
   * usa armaduraPerf. Devuelve el daño efectivo aplicado.
   */
  danio(atacanteId, objetivoId, cantidad, tipo = 'cuerpo') {
    const M = this.ctx.mundo;
    if (objetivoId == null || objetivoId < 0 || !M.vivo[objetivoId]) return 0;
    if (M.estado[objetivoId] === ESTADO.MURIENDO) return 0;
    if (M.tipo[objetivoId] !== TIPO.UNIDAD && M.tipo[objetivoId] !== TIPO.EDIFICIO) return 0;

    const perforante = tipo !== 'cuerpo' && tipo !== 'melee';
    const claseObj = this._claseDe(objetivoId);

    let bono = 0;
    if (atacanteId >= 0 && M.vivo[atacanteId]) {
      const defA = this._def(atacanteId);
      if (defA?.bonos) bono = defA.bonos[claseObj] || 0;
    }

    const armadura = this._armaduraDe(objetivoId, perforante);
    let d = Math.max(1, (cantidad + bono) - armadura);
    if (this._enConstruccion(objetivoId)) d *= 2;   // andamios: se caen a nada

    M.vida[objetivoId] -= d;

    // memoria de agresor: alimenta la preferencia de blanco y la respuesta defensiva
    if (atacanteId >= 0 && M.vivo[atacanteId] && M.jugador[atacanteId] !== M.jugador[objetivoId]) {
      this.agresor[objetivoId] = atacanteId;
      this.tAgresion[objetivoId] = 7;
      if (M.jugador[objetivoId] === this.ctx.jugadorLocal) this._avisarAtaque(objetivoId);
    }

    if (M.vida[objetivoId] <= 0) this._matar(objetivoId, atacanteId);
    return d;
  }

  /**
   * Elige el mejor blanco para `id` dentro de `radio`.
   * Preferencia: el que me está pegando → el más débil en alcance → el más cercano.
   * Con mods.autoFoco pesa fuerte el bono de daño contra la clase del blanco.
   */
  buscarObjetivo(id, radio) {
    const M = this.ctx.mundo;
    if (!M.vivo[id]) return -1;
    const def = this._def(id);
    if (!def) return -1;
    const mio = M.jugador[id];
    const x = M.px[id], z = M.pz[id];
    const r = radio && radio > 0 ? radio : this._radioBusqueda(id);
    const alcance = this._alcanceDe(id);
    const autoFoco = !!this._mods(mio).autoFoco;
    const agresor = this.tAgresion[id] > 0 ? this.agresor[id] : -1;
    const antiAereo = this._puedeAtacarAereo(id);
    const yoRadio = this._radioDe(id) * 0.6;

    const lista = M.cerca(x, z, r, this._buf0);
    let mejor = -1, mejorP = -Infinity;
    for (let k = 0; k < lista.length; k++) {
      const o = lista[k];
      if (o === id || !M.vivo[o]) continue;
      const t = M.tipo[o];
      if (t !== TIPO.UNIDAD && t !== TIPO.EDIFICIO) continue;
      if (M.estado[o] === ESTADO.MURIENDO) continue;
      const jo = M.jugador[o];
      if (jo === mio || jo === 255) continue;
      const defO = this._def(o);
      if (!defO) continue;
      if (t === TIPO.EDIFICIO && defO.muro) continue;     // los muros se pican a mano
      if (defO.vuela && !antiAereo) continue;

      const dx = M.px[o] - x, dz = M.pz[o] - z;
      const d = Math.sqrt(dx * dx + dz * dz);
      const rango = alcance + yoRadio + this._radioDe(o);

      let p = 0;
      if (o === agresor) p += 900;
      if (d <= rango) p += 420;
      const vm = M.vidaMax[o] > 0 ? M.vidaMax[o] : 1;
      p += (1 - clamp(M.vida[o] / vm, 0, 1)) * 150;
      p -= d * 6;
      if (t === TIPO.EDIFICIO) p -= 460;                  // primero la carne, después el ladrillo
      if (defO.clase === 'aldeano') p += 70;              // el recolector es el blanco jugoso
      if (def.bonos) {
        const b = def.bonos[this._claseDe(o)] || 0;
        p += autoFoco ? b * 9 : b * 1.4;
      }
      if (p > mejorP) { mejorP = p; mejor = o; }
    }
    return mejor;
  }

  _radioBusqueda(id) {
    const alc = this._alcanceDe(id);
    const vis = this._visionDe(id);
    return Math.min(Math.max(alc + 4, 15), Math.max(vis, alc + 4), 26);
  }

  /* ================================================================ */
  /* Bucle de simulación (20 Hz)                                       */
  /* ================================================================ */

  fijo(dt, ctx) {
    const M = ctx.mundo;
    this._tAviso -= dt;

    this._proyectiles.length = 0;

    for (let id = 0; id < M.maxUsado; id++) {
      if (!M.vivo[id]) continue;
      const t = M.tipo[id];
      if (t === TIPO.PROYECTIL) { this._proyectiles.push(id); continue; }
      if (t !== TIPO.UNIDAD && t !== TIPO.EDIFICIO) continue;

      if (M.estado[id] === ESTADO.MURIENDO) { this._pasoMuerte(id, dt); continue; }
      if (this.tAgresion[id] > 0) this.tAgresion[id] -= dt;

      if (t === TIPO.EDIFICIO) this._pasoEdificio(id, dt);
      else this._pasoUnidad(id, dt);
    }

    this._pasoProyectiles(dt);
  }

  /* ---------------- muerte ---------------- */

  _pasoMuerte(id, dt) {
    const M = this.ctx.mundo;
    M.vx[id] = 0; M.vz[id] = 0; M.tieneDestino[id] = 0;
    this.muerteT[id] -= dt;
    if (this.muerteT[id] > 0) return;
    this._enterrar(id);
  }

  _matar(id, atacanteId) {
    const M = this.ctx.mundo;
    if (M.estado[id] === ESTADO.MURIENDO) return;
    const def = this._def(id);
    const esEdificio = M.tipo[id] === TIPO.EDIFICIO;

    M.vida[id] = 0;
    M.estado[id] = ESTADO.MURIENDO;
    M.objetivo[id] = -1;
    M.tieneDestino[id] = 0;
    M.vx[id] = 0; M.vz[id] = 0;
    this.golpeT[id] = 0; this.golpeBlanco[id] = -1;
    this.convBlanco[id] = -1;
    this.lugarActivo[id] = 0;
    this.muerteT[id] = esEdificio ? 1.15 : 0.8;
    this.matador[id] = atacanteId ?? -1;

    const porJugador = (atacanteId >= 0 && M.vivo[atacanteId]) ? M.jugador[atacanteId] : 255;
    const x = M.px[id], y = M.py[id], z = M.pz[id];

    // veteranía del que remató
    if (atacanteId >= 0 && M.vivo[atacanteId] && M.tipo[atacanteId] === TIPO.UNIDAD) {
      this._sumarMuerte(atacanteId);
    }

    if (esEdificio) {
      this.ctx.efectos?.explosion?.(x, y + 1.5, z, Math.max(2.5, this._radioDe(id)));
      this.ctx.efectos?.polvo?.(x, y, z, 40);
      this._sacudir(x, z, 1.1);
      // una central energética se lleva puesto lo que tenga alrededor
      if (def?.generaEnergia) {
        this._danioArea(-1, x, z, 9, 90, 'perforante', -1, true, M.jugador[id]);
        this.ctx.efectos?.explosion?.(x, y + 3, z, 9);
        this._sacudir(x, z, 2.4);
      }
    } else {
      this.ctx.efectos?.impacto?.(x, y + 0.8, z, 'muerte', 1);
    }

    this.ctx.audio?.sfx?.(esEdificio ? 'derrumbe' : 'muerte_unidad', { x, z });
    bus.emit('combate:muerte', {
      id, porJugador, jugador: M.jugador[id], x, z,
      clase: this._claseDe(id), edificio: esEdificio,
    });
    bus.emit('entidad:muerta', { id, porJugador });

    if (M.jugador[id] === this.ctx.jugadorLocal) this._avisarPerdida(id, esEdificio);
  }

  _enterrar(id) {
    const M = this.ctx.mundo;
    const x = M.px[id], z = M.pz[id];
    const esEdificio = M.tipo[id] === TIPO.EDIFICIO;
    const def = this._def(id);
    const clave = esEdificio ? 'escombros' : (def?.clase === 'caballeria' || def?.clase === 'asedio' ? 'chatarra' : 'cadaver');
    const radio = esEdificio ? Math.max(3, this._radioDe(id)) : 1.1;
    this.ctx.terreno?.pintarDecal?.(x, z, clave, radio, M.rot[id]);
    M.destruir(id);
  }

  _sumarMuerte(id) {
    const M = this.ctx.mundo;
    this.muertesPropias[id]++;
    if (this.muertesPropias[id] % 3 !== 0) return;
    if (M.veterania[id] >= 3) return;
    M.veterania[id]++;
    const extra = M.vidaMax[id] * 0.05;
    M.vidaMax[id] += extra;
    M.vida[id] = Math.min(M.vidaMax[id], M.vida[id] + extra);
    this.ctx.efectos?.impacto?.(M.px[id], M.py[id] + 1.6, M.pz[id], 'ascenso', 0.6);
    bus.emit('combate:veterania', { id, nivel: M.veterania[id], jugador: M.jugador[id] });
  }

  _avisarAtaque(id) {
    if (this._tAviso > 0) return;
    this._tAviso = 9;
    const M = this.ctx.mundo;
    const esEd = M.tipo[id] === TIPO.EDIFICIO;
    bus.emit('aviso', {
      texto: esEd ? '¡Están atacando tus edificios!' : '¡Están atacando a tus unidades!',
      tipo: 'alerta', x: M.px[id], z: M.pz[id], id,
    });
  }

  _avisarPerdida(id, esEdificio) {
    if (!esEdificio) return;
    bus.emit('aviso', { texto: 'Perdiste un edificio.', tipo: 'error', x: this.ctx.mundo.px[id], z: this.ctx.mundo.pz[id] });
  }

  /* ---------------- unidades ---------------- */

  _pasoUnidad(id, dt) {
    const M = this.ctx.mundo;
    const def = this._def(id);
    if (!def) return;

    // apoyo: convierte y cura (no dispara)
    if (def.convierte || def.cura) {
      this._pasoApoyo(id, dt, def);
      if (!def.ataque) return;
    }
    if (!def.ataque || !def.cadencia) return;

    const post = this.postura_[id];
    if (M.temporizador[id] > 0) M.temporizador[id] -= dt;

    // golpe en curso: se resuelve a mitad de la animación
    if (this.golpeT[id] > 0) {
      this.golpeT[id] -= dt;
      if (this.golpeT[id] <= 0) this._resolverGolpe(id);
      return;
    }

    if (post === POSTURA.NO_ATACAR) {
      if (M.objetivo[id] >= 0 && !this.ordenExplicita[id]) M.objetivo[id] = -1;
      if (!this.ordenExplicita[id]) return;
    }

    let obj = M.objetivo[id];
    if (obj >= 0 && (!M.vivo[obj] || M.estado[obj] === ESTADO.MURIENDO)) {
      obj = -1; M.objetivo[id] = -1; this.ordenExplicita[id] = 0;
    }

    // fuego indirecto sobre el suelo (artillería con ataque a posición)
    if (obj < 0 && this.lugarActivo[id] && def.clase === 'asedio' && def.proyectil) {
      this._pasoAtaqueLugar(id, def, dt);
      return;
    }

    // adquisición automática escalonada
    this.tBusqueda[id] -= dt;
    if (obj < 0 && this.tBusqueda[id] <= 0) {
      this.tBusqueda[id] = 0.2 + (id % 4) * 0.05;
      if (post !== POSTURA.NO_ATACAR) {
        const cand = this.buscarObjetivo(id, 0);
        if (cand >= 0 && this._admitidoPorPostura(id, cand, post)) {
          obj = cand; M.objetivo[id] = cand;
        }
      }
    }

    if (obj < 0) {
      // ataque en movimiento: si no hay nadie, seguimos hacia el punto
      if (this.lugarActivo[id]) {
        const dx = this.lugarX[id] - M.px[id], dz = this.lugarZ[id] - M.pz[id];
        if (dx * dx + dz * dz < 4) this.lugarActivo[id] = 0;
        else this._irHacia(id, this.lugarX[id], this.lugarZ[id], false);
      }
      if (M.estado[id] === ESTADO.ATACANDO) M.estado[id] = ESTADO.QUIETO;
      return;
    }

    // ¿lo tengo a tiro?
    const dx = M.px[obj] - M.px[id], dz = M.pz[obj] - M.pz[id];
    const d2 = dx * dx + dz * dz;
    const rango = this._rangoContra(id, obj);

    if (d2 <= rango * rango) {
      M.rotObjetivo[id] = Math.atan2(dz, dx);
      this._detener(id);
      if (M.temporizador[id] <= 0) this._iniciarGolpe(id, obj);
      else if (M.estado[id] !== ESTADO.ATACANDO) M.estado[id] = ESTADO.ATACANDO;
      return;
    }

    // fuera de alcance: perseguir según postura
    if (post === POSTURA.QUIETA && !this.ordenExplicita[id]) { M.objetivo[id] = -1; return; }
    if (post === POSTURA.DEFENSIVA && !this.ordenExplicita[id]) {
      const px = M.px[obj] - this.puestoX[id], pz = M.pz[obj] - this.puestoZ[id];
      if (px * px + pz * pz > 36 + rango * rango) {   // más de 6 m del puesto: lo dejo ir
        M.objetivo[id] = -1;
        this._irHacia(id, this.puestoX[id], this.puestoZ[id], false);
        return;
      }
    }
    if (post === POSTURA.AGRESIVA && !this.ordenExplicita[id] && !this.lugarActivo[id]) {
      const px = M.px[obj] - this.puestoX[id], pz = M.pz[obj] - this.puestoZ[id];
      if (px * px + pz * pz > 900) { M.objetivo[id] = -1; return; }  // 30 m de correa
    }
    this._perseguir(id, obj, rango, dt);
  }

  _admitidoPorPostura(id, cand, post) {
    if (post === POSTURA.NO_ATACAR) return false;
    const M = this.ctx.mundo;
    if (post === POSTURA.QUIETA) {
      const rango = this._rangoContra(id, cand);
      return M.dist2(id, cand) <= rango * rango;
    }
    if (post === POSTURA.DEFENSIVA) {
      const dx = M.px[cand] - this.puestoX[id], dz = M.pz[cand] - this.puestoZ[id];
      const rango = this._rangoContra(id, cand) + 6;
      return dx * dx + dz * dz <= rango * rango;
    }
    return true;
  }

  _pasoAtaqueLugar(id, def, dt) {
    const M = this.ctx.mundo;
    const x = this.lugarX[id], z = this.lugarZ[id];
    const dx = x - M.px[id], dz = z - M.pz[id];
    const d2 = dx * dx + dz * dz;
    const alc = this._alcanceDe(id);
    if (d2 > alc * alc) { this._irHacia(id, x, z, false); return; }
    this._detener(id);
    M.rotObjetivo[id] = Math.atan2(dz, dx);
    if (M.temporizador[id] > 0) return;
    const cad = this._cadenciaDe(id);
    M.temporizador[id] = cad;
    this.golpeT[id] = Math.min(cad * 0.45, 0.45);
    this.golpeBlanco[id] = -1;   // -1 + lugarActivo = tiro al suelo
    M.estado[id] = ESTADO.ATACANDO;
    M.animFase[id] = 0;
  }

  _iniciarGolpe(id, obj) {
    const M = this.ctx.mundo;
    const cad = this._cadenciaDe(id);
    M.temporizador[id] = cad;
    this.golpeT[id] = Math.min(cad * 0.45, 0.45);
    this.golpeBlanco[id] = obj;
    M.estado[id] = ESTADO.ATACANDO;
    M.animFase[id] = 0;   // la animación arranca justo ahora: mano e impacto van juntos
  }

  _resolverGolpe(id) {
    const M = this.ctx.mundo;
    this.golpeT[id] = 0;
    if (!M.vivo[id] || M.estado[id] === ESTADO.MURIENDO) return;
    const def = this._def(id);
    if (!def) return;
    const obj = this.golpeBlanco[id];
    const ataque = this._ataqueDe(id);

    // tiro al suelo
    if (obj < 0) {
      if (!this.lugarActivo[id]) return;
      this.lanzarProyectil(id, -1, def.proyectil || 'obus', ataque, this.lugarX[id], this.lugarZ[id]);
      return;
    }
    if (!M.vivo[obj] || M.estado[obj] === ESTADO.MURIENDO) { M.objetivo[id] = -1; return; }

    const rango = this._rangoContra(id, obj) * 1.35;
    if (M.dist2(id, obj) > rango * rango) return;   // se le escapó: el golpe se pierde

    if (def.proyectil) {
      this.lanzarProyectil(id, obj, def.proyectil, ataque);
    } else {
      const d = this.danio(id, obj, ataque, 'cuerpo');
      const x = M.px[obj], y = this._alturaBlanco(obj), z = M.pz[obj];
      this.ctx.efectos?.impacto?.(x, y, z, 'cuerpo', clamp(d / 30, 0.25, 1.4));
      this.ctx.audio?.sfx?.('golpe_cuerpo', { x, z });
      bus.emit('combate:impacto', { fuente: id, objetivo: obj, x, y, z, danio: d, tipo: 'cuerpo' });
      if (def.salpicadura) {
        this._danioArea(id, x, z, def.salpicadura, ataque * 0.6, 'cuerpo', obj, false, M.jugador[id]);
      }
    }
  }

  /* ---------------- edificios defensivos ---------------- */

  _pasoEdificio(id, dt) {
    const M = this.ctx.mundo;
    const def = this._def(id);
    if (!def || !def.ataque || !def.cadencia) return;
    if (M.estado[id] === ESTADO.CONSTRUYENDO) return;
    if (this._enConstruccion(id)) return;

    if (M.temporizador[id] > 0) M.temporizador[id] -= dt;
    if (this.golpeT[id] > 0) {
      this.golpeT[id] -= dt;
      if (this.golpeT[id] <= 0) this._resolverGolpeEdificio(id, def);
      return;
    }

    let obj = M.objetivo[id];
    if (obj >= 0 && (!M.vivo[obj] || M.estado[obj] === ESTADO.MURIENDO)) { obj = -1; M.objetivo[id] = -1; }
    if (obj < 0) {
      this.tBusqueda[id] -= dt;
      if (this.tBusqueda[id] > 0) return;
      this.tBusqueda[id] = 0.25;
      obj = this.buscarObjetivo(id, this._alcanceDe(id) + this._radioDe(id) + 1);
      if (obj < 0) return;
      M.objetivo[id] = obj;
    }
    const rango = this._rangoContra(id, obj);
    if (M.dist2(id, obj) > rango * rango) { M.objetivo[id] = -1; return; }
    if (M.temporizador[id] > 0) return;

    const cad = this._cadenciaDe(id);
    M.temporizador[id] = cad;
    this.golpeT[id] = Math.min(cad * 0.35, 0.3);
    this.golpeBlanco[id] = obj;
    M.rotObjetivo[id] = Math.atan2(M.pz[obj] - M.pz[id], M.px[obj] - M.px[id]);
  }

  _resolverGolpeEdificio(id, def) {
    const M = this.ctx.mundo;
    const obj = this.golpeBlanco[id];
    this.golpeT[id] = 0;
    if (obj < 0 || !M.vivo[obj] || M.estado[obj] === ESTADO.MURIENDO) return;
    this.lanzarProyectil(id, obj, def.proyectil || 'bala', this._ataqueDe(id));
  }

  /* ---------------- apoyo: conversión y curación ---------------- */

  _pasoApoyo(id, dt, def) {
    const M = this.ctx.mundo;
    const mods = this._mods(M.jugador[id]);
    const alcance = (def.alcance || 8) + (mods.alcance?.apoyo || 0);

    /* --- conversión --- */
    if (def.convierte && this.postura_[id] !== POSTURA.NO_ATACAR) {
      let b = this.convBlanco[id];
      if (b >= 0 && (!M.vivo[b] || M.estado[b] === ESTADO.MURIENDO || M.jugador[b] === M.jugador[id])) b = -1;
      if (b >= 0) {
        const dx = M.px[b] - M.px[id], dz = M.pz[b] - M.pz[id];
        if (dx * dx + dz * dz > (alcance + 1.5) * (alcance + 1.5)) b = -1;
      }
      if (b < 0) {
        // blanco explícito primero, si no busca uno
        const ord = this.ordenExplicita[id] ? M.objetivo[id] : -1;
        if (ord >= 0 && M.vivo[ord] && M.jugador[ord] !== M.jugador[id]) b = ord;
        else {
          this.tBusqueda[id] -= dt;
          if (this.tBusqueda[id] <= 0) {
            this.tBusqueda[id] = 0.4;
            b = this._buscarConvertible(id, alcance);
          }
        }
        if (b >= 0) { this.convBlanco[id] = b; this.convT[id] = 0; }
      }
      if (b >= 0) {
        this.convBlanco[id] = b;
        M.rotObjetivo[id] = Math.atan2(M.pz[b] - M.pz[id], M.px[b] - M.px[id]);
        this._detener(id);
        M.estado[id] = ESTADO.ATACANDO;
        this._avanzarConversion(id, b, dt, mods);
      } else if (this.convBlanco[id] >= 0) {
        this.convBlanco[id] = -1; this.convT[id] = 0;
      }
    }

    /* --- curación --- */
    if (def.cura && this.convBlanco[id] < 0) {
      this.curaT[id] -= dt;
      if (this.curaT[id] <= 0) {
        const cad = def.cadencia || 5;
        this.curaT[id] = cad;
        const herido = this._buscarHerido(id, alcance);
        if (herido >= 0) {
          const mult = mods.multiplicadorCura ?? 1;
          const cura = (def.cura || 10) * mult;
          M.vida[herido] = Math.min(M.vidaMax[herido], M.vida[herido] + cura);
          M.rotObjetivo[id] = Math.atan2(M.pz[herido] - M.pz[id], M.px[herido] - M.px[id]);
          this.trazas.agregar(
            M.px[id], this._alturaBoca(id), M.pz[id],
            M.px[herido], this._alturaBlanco(herido), M.pz[herido],
            0x9fffc0, 0.5
          );
          this.ctx.efectos?.impacto?.(M.px[herido], this._alturaBlanco(herido), M.pz[herido], 'cura', 0.4);
          this.ctx.audio?.sfx?.('cura', { x: M.px[herido], z: M.pz[herido] });
          bus.emit('combate:cura', { fuente: id, objetivo: herido, cantidad: cura });
        }
      }
    }
  }

  _buscarConvertible(id, alcance) {
    const M = this.ctx.mundo;
    const mio = M.jugador[id];
    const lista = M.cerca(M.px[id], M.pz[id], alcance, this._buf2);
    let mejor = -1, mejorD = Infinity;
    for (let k = 0; k < lista.length; k++) {
      const o = lista[k];
      if (!M.vivo[o] || M.tipo[o] !== TIPO.UNIDAD) continue;
      if (M.jugador[o] === mio || M.jugador[o] === 255) continue;
      if (M.estado[o] === ESTADO.MURIENDO) continue;
      const d = this._def(o);
      if (!d || d.inmuneConversion) continue;
      const dd = M.dist2(id, o);
      if (dd < mejorD) { mejorD = dd; mejor = o; }
    }
    return mejor;
  }

  _buscarHerido(id, alcance) {
    const M = this.ctx.mundo;
    const mio = M.jugador[id];
    const lista = M.cerca(M.px[id], M.pz[id], alcance, this._buf2);
    let mejor = -1, peorFrac = 1;
    for (let k = 0; k < lista.length; k++) {
      const o = lista[k];
      if (o === id || !M.vivo[o] || M.tipo[o] !== TIPO.UNIDAD) continue;
      if (M.jugador[o] !== mio) continue;
      if (M.estado[o] === ESTADO.MURIENDO) continue;
      if (M.vidaMax[o] <= 0) continue;
      const f = M.vida[o] / M.vidaMax[o];
      if (f >= 0.995) continue;
      if (f < peorFrac) { peorFrac = f; mejor = o; }
    }
    return mejor;
  }

  _avanzarConversion(id, b, dt, mods) {
    const M = this.ctx.mundo;
    const vel = mods.velConversion ?? 1;
    const resist = this._mods(M.jugador[b]).resistenciaConversion ?? 0;
    this.convT[id] += dt * vel * (1 - clamp(resist, 0, 0.9));

    // haz visual pulsante
    const y0 = this._alturaBoca(id), y1 = this._alturaBlanco(b);
    this.trazas.agregar(M.px[id], y0, M.pz[id], M.px[b], y1, M.pz[b], 0xc98bff, 0.12);

    const minimo = 2.5;
    if (this.convT[id] < minimo) return;
    // probabilidad creciente: cuanto más tiempo aguanta el haz, más chances por tick
    const p = clamp(0.035 + (this.convT[id] - minimo) * 0.05, 0, 0.55) * (dt / 0.05);
    if (this.rng.r() >= p) return;
    this._convertir(b, M.jugador[id], id);
    this.convBlanco[id] = -1; this.convT[id] = 0;
    M.objetivo[id] = -1; this.ordenExplicita[id] = 0;
  }

  _convertir(id, nuevoJugador, fuenteId) {
    const M = this.ctx.mundo;
    const anterior = M.jugador[id];
    M.jugador[id] = nuevoJugador;
    M.objetivo[id] = -1;
    M.tieneDestino[id] = 0;
    M.vx[id] = 0; M.vz[id] = 0;
    M.estado[id] = ESTADO.QUIETO;
    M.vida[id] = M.vidaMax[id];
    this.agresor[id] = -1; this.tAgresion[id] = 0;
    this.ordenExplicita[id] = 0;
    this.golpeT[id] = 0; this.golpeBlanco[id] = -1;
    this.lugarActivo[id] = 0;
    this.postura_[id] = this._posturaPorDefecto(id);
    this.puestoX[id] = M.px[id]; this.puestoZ[id] = M.pz[id];

    const x = M.px[id], y = this._alturaBlanco(id), z = M.pz[id];
    this.ctx.efectos?.explosion?.(x, y, z, 1.4);
    this.ctx.efectos?.impacto?.(x, y, z, 'conversion', 1);
    this.ctx.audio?.sfx?.('conversion', { x, z });

    // que la vista lo repinte con el color nuevo
    if (this.ctx.vista?.actualizarJugador) this.ctx.vista.actualizarJugador(id);
    else if (this.ctx.vista?.quitar && this.ctx.vista?.registrar) {
      this.ctx.vista.quitar(id); this.ctx.vista.registrar(id);
    }
    bus.emit('entidad:convertida', { id, de: anterior, a: nuevoJugador, por: fuenteId });
    if (nuevoJugador === this.ctx.jugadorLocal || anterior === this.ctx.jugadorLocal) {
      bus.emit('aviso', {
        texto: nuevoJugador === this.ctx.jugadorLocal ? 'Convertiste una unidad enemiga.' : '¡Te convirtieron una unidad!',
        tipo: nuevoJugador === this.ctx.jugadorLocal ? 'info' : 'alerta', x, z,
      });
    }
  }

  /* ================================================================ */
  /* Movimiento auxiliar (nunca importamos Movimiento: usamos el SoA)  */
  /* ================================================================ */

  _irHacia(id, x, z, forzar) {
    const M = this.ctx.mundo;
    if (!forzar) {
      const dx = M.destinoX[id] - x, dz = M.destinoZ[id] - z;
      if (M.tieneDestino[id] && dx * dx + dz * dz < 4) return;
    }
    if (this.ctx.movimiento?.irA) { this.ctx.movimiento.irA(id, x, z); }
    M.destinoX[id] = x; M.destinoZ[id] = z; M.tieneDestino[id] = 1;
    if (M.estado[id] !== ESTADO.MOVIENDO) M.estado[id] = ESTADO.MOVIENDO;
  }

  _detener(id) {
    const M = this.ctx.mundo;
    if (!M.tieneDestino[id]) return;
    M.tieneDestino[id] = 0;
    M.vx[id] = 0; M.vz[id] = 0;
    this.ctx.movimiento?.detener?.(id);
  }

  /** Persigue sin repathear cada tick: solo si el blanco se corrió de verdad. */
  _perseguir(id, obj, rango, dt) {
    const M = this.ctx.mundo;
    this.tRepath[id] -= dt;
    const bx = M.px[obj], bz = M.pz[obj];
    const dx = bx - this.persigueX[id], dz = bz - this.persigueZ[id];
    if (this.tRepath[id] > 0 && M.tieneDestino[id] && dx * dx + dz * dz < 4) return;
    this.tRepath[id] = 0.25;
    this.persigueX[id] = bx; this.persigueZ[id] = bz;
    // apuntamos a un punto justo dentro del alcance, no al centro del blanco
    const ex = M.px[id] - bx, ez = M.pz[id] - bz;
    const l = Math.hypot(ex, ez) || 1;
    const acercar = Math.max(0.6, rango * 0.8);
    this._irHacia(id, bx + (ex / l) * acercar, bz + (ez / l) * acercar, true);
  }

  /* ================================================================ */
  /* Proyectiles                                                       */
  /* ================================================================ */

  datosProyectil(id) {
    const M = this.ctx.mundo;
    if (M.tipo[id] !== TIPO.PROYECTIL) return null;
    return PROYECTILES[this.prTipo[id]] || null;
  }

  /**
   * Larga un proyectil. `haciaId` = -1 y (destX,destZ) definidos → tiro al suelo.
   * El daño ya viene con el ataque del tirador (los bonos y la armadura se
   * aplican en el impacto, dentro de danio()).
   */
  lanzarProyectil(desdeId, haciaId, tipo, danio, destX, destZ) {
    const M = this.ctx.mundo;
    const idx = PROY_POR_CLAVE.get(tipo) ?? 0;
    const P = PROYECTILES[idx];
    const def = this._def(desdeId);
    const jugador = M.jugador[desdeId];
    const mods = this._mods(jugador);

    const x0 = M.px[desdeId], z0 = M.pz[desdeId];
    const y0 = this._alturaBoca(desdeId);

    // punto de impacto: con predicción de movimiento de primer orden
    let bx, by, bz;
    if (haciaId >= 0 && M.vivo[haciaId]) {
      bx = M.px[haciaId]; by = this._alturaBlanco(haciaId); bz = M.pz[haciaId];
    } else {
      bx = destX ?? x0; bz = destZ ?? z0;
      by = (this.ctx.terreno?.altura?.(bx, bz) ?? 0) + 0.2;
    }

    const dirX = bx - x0, dirZ = bz - z0;
    const distPlano = Math.hypot(dirX, dirZ) || 0.001;

    this.ctx.efectos?.disparo?.(x0, y0, z0, dirX / distPlano, dirZ / distPlano, P.clave);
    this.ctx.audio?.sfx?.(P.sonido, { x: x0, z: z0 });
    bus.emit('combate:disparo', {
      id: desdeId, jugador, tipo: P.clave, objetivo: haciaId,
      x: x0, y: y0, z: z0, danio,
    });

    const salpicadura = def?.salpicadura || 0;
    const fuegoAmigo = def?.clase === 'asedio';

    /* ---- riel: hitscan, atraviesa hasta 2 blancos ---- */
    if (P.hitscan) {
      this._hitscanRiel(desdeId, haciaId, x0, y0, z0, bx, by, bz, danio, salpicadura);
      return -1;
    }

    /* ---- enjambre: varias submuniciones con dispersión ---- */
    if (P.serpentea) {
      const n = SUBMUNICIONES;
      const dCada = danio / n;
      for (let i = 0; i < n; i++) {
        this._crearProyectil(idx, desdeId, haciaId, dCada, x0, y0, z0, bx, by, bz,
          salpicadura * 0.6, fuegoAmigo, mods, 0.55, i / n * Math.PI * 2);
      }
      return -1;
    }

    return this._crearProyectil(idx, desdeId, haciaId, danio, x0, y0, z0, bx, by, bz,
      salpicadura, fuegoAmigo, mods, tipo === 'cohete' ? 0.25 : 0, 0);
  }

  _crearProyectil(idx, desdeId, haciaId, danio, x0, y0, z0, bx, by, bz, salpicadura, fuegoAmigo, mods, dispExtra, fase) {
    const M = this.ctx.mundo;
    const P = PROYECTILES[idx];
    const jugador = M.jugador[desdeId];

    // predicción de interceptación de primer orden
    let px = bx, pz = bz, py = by;
    const velEstim = P.vel > 0 ? P.vel : 30;
    if (haciaId >= 0 && M.vivo[haciaId]) {
      const t = Math.hypot(bx - x0, bz - z0) / velEstim;
      px = bx + M.vx[haciaId] * t;
      pz = bz + M.vz[haciaId] * t;
    }

    // dispersión (los mods de balística la achican)
    const disp = ((mods.dispersion ?? 1) * (dispExtra || 0.12)) * (P.clave === 'obus' ? 1.6 : 1);
    if (disp > 0) {
      px += this.rng.gauss(0, disp);
      pz += this.rng.gauss(0, disp);
    }

    const id = M.crear(TIPO.PROYECTIL, idx, x0, z0, jugador);
    M.py[id] = y0;
    M.radio[id] = P.radio;
    M.vida[id] = 1; M.vidaMax[id] = 1;
    M.escala[id] = 1;
    M.estado[id] = ESTADO.MOVIENDO;
    M.objetivo[id] = haciaId;

    this.prTipo[id] = idx;
    this.prFuente[id] = desdeId;
    this.prBlanco[id] = haciaId;
    this.prDanio[id] = danio;
    this.prSalp[id] = salpicadura;
    this.prAmigo[id] = fuegoAmigo ? 1 : 0;
    this.prDestX[id] = px; this.prDestZ[id] = pz; this.prDestY[id] = py;
    this.prTtl[id] = P.ttl;
    this.prFase[id] = fase;
    this.prPrevX[id] = x0; this.prPrevY[id] = y0; this.prPrevZ[id] = z0;
    this.prVisualPropia[id] = 0;

    const dx = px - x0, dz = pz - z0;
    const dPlano = Math.hypot(dx, dz) || 0.001;

    if (P.clave === 'obus') {
      // balística resuelta: elegimos tiempo de vuelo y sacamos la vertical
      const t = clamp(dPlano / 30, 0.5, 2.4);
      M.vx[id] = dx / t;
      M.vz[id] = dz / t;
      this.prVy[id] = ((py - y0) + 0.5 * G_OBUS * t * t) / t;
      this.prTtl[id] = t + 1.2;
    } else {
      const dy = py - y0;
      const d3 = Math.hypot(dx, dy, dz) || 0.001;
      const v = P.vel;
      M.vx[id] = (dx / d3) * v;
      M.vz[id] = (dz / d3) * v;
      this.prVy[id] = (dy / d3) * v;
      if (P.clave === 'bala') {
        // compensación de caída: apunta un pelín arriba
        const t = d3 / v;
        this.prVy[id] += 0.5 * P.grav * t;
      }
    }
    M.rot[id] = Math.atan2(M.vz[id], M.vx[id]);
    return id;
  }

  _hitscanRiel(desdeId, haciaId, x0, y0, z0, bx, by, bz, danio, salpicadura) {
    const M = this.ctx.mundo;
    const P = PROYECTILES[5];
    let dx = bx - x0, dy = by - y0, dz = bz - z0;
    const largo = Math.hypot(dx, dy, dz) || 0.001;
    dx /= largo; dy /= largo; dz /= largo;
    const alcanceTotal = largo + 6;

    const mio = M.jugador[desdeId];
    const lista = M.cerca(x0 + dx * alcanceTotal * 0.5, z0 + dz * alcanceTotal * 0.5, alcanceTotal * 0.5 + 3, this._buf1);
    // ordenamos por distancia sobre el rayo y perforamos hasta 2
    const golpes = [];
    for (let k = 0; k < lista.length; k++) {
      const o = lista[k];
      if (o === desdeId || !M.vivo[o]) continue;
      if (M.tipo[o] !== TIPO.UNIDAD && M.tipo[o] !== TIPO.EDIFICIO) continue;
      if (M.jugador[o] === mio || M.jugador[o] === 255) continue;
      if (M.estado[o] === ESTADO.MURIENDO) continue;
      const ox = M.px[o] - x0, oy = this._alturaBlanco(o) - y0, oz = M.pz[o] - z0;
      const t = ox * dx + oy * dy + oz * dz;
      if (t < 0 || t > alcanceTotal) continue;
      const cx = ox - dx * t, cy = oy - dy * t, cz = oz - dz * t;
      const r = this._radioDe(o) + 0.5;
      if (cx * cx + cy * cy + cz * cz > r * r) continue;
      golpes.push(t, o);
    }
    // burbuja corta sobre pares (t, id): son pocos
    for (let i = 0; i < golpes.length; i += 2) {
      for (let j = i + 2; j < golpes.length; j += 2) {
        if (golpes[j] < golpes[i]) {
          const t = golpes[i], o = golpes[i + 1];
          golpes[i] = golpes[j]; golpes[i + 1] = golpes[j + 1];
          golpes[j] = t; golpes[j + 1] = o;
        }
      }
    }
    let fin = alcanceTotal, tocados = 0;
    for (let i = 0; i < golpes.length && tocados < 2; i += 2) {
      const o = golpes[i + 1];
      const escala = tocados === 0 ? 1 : 0.6;
      const d = this.danio(desdeId, o, danio * escala, 'perforante');
      const ix = M.px[o], iy = this._alturaBlanco(o), iz = M.pz[o];
      this.ctx.efectos?.impacto?.(ix, iy, iz, 'riel', 1.2);
      bus.emit('combate:impacto', { fuente: desdeId, objetivo: o, x: ix, y: iy, z: iz, danio: d, tipo: 'riel' });
      if (salpicadura > 0) this._danioArea(desdeId, ix, iz, salpicadura, danio * 0.5, 'perforante', o, false, mio);
      fin = golpes[i] + 2;
      tocados++;
    }
    if (tocados === 0) fin = largo;
    // traza: dos líneas superpuestas para que se lea el fogonazo
    this.trazas.agregar(x0, y0, z0, x0 + dx * fin, y0 + dy * fin, z0 + dz * fin, P.color, P.estelaTtl);
    this.trazas.agregar(x0, y0 + 0.05, z0, x0 + dx * fin, y0 + dy * fin + 0.05, z0 + dz * fin, 0xffffff, P.estelaTtl * 0.5);
    this._sacudir(x0, z0, 0.35);
    if (tocados > 0) this._sacudir(bx, bz, 0.5);
  }

  _pasoProyectiles(dt) {
    const M = this.ctx.mundo;
    const lista = this._proyectiles;
    for (let k = 0; k < lista.length; k++) {
      const id = lista[k];
      if (!M.vivo[id]) continue;
      const P = PROYECTILES[this.prTipo[id]];
      if (!P) { M.destruir(id); continue; }

      const x = M.px[id], y = M.py[id], z = M.pz[id];
      this.prPrevX[id] = x; this.prPrevY[id] = y; this.prPrevZ[id] = z;

      let vx = M.vx[id], vy = this.prVy[id], vz = M.vz[id];
      const blanco = this.prBlanco[id];
      const vivoBlanco = blanco >= 0 && M.vivo[blanco] && M.estado[blanco] !== ESTADO.MURIENDO;

      // punto al que va: el blanco si sigue vivo, si no, el último destino conocido
      let tx = this.prDestX[id], ty = this.prDestY[id], tz = this.prDestZ[id];
      if (vivoBlanco) {
        tx = M.px[blanco]; ty = this._alturaBlanco(blanco); tz = M.pz[blanco];
        this.prDestX[id] = tx; this.prDestY[id] = ty; this.prDestZ[id] = tz;
      }

      /* --- guiado --- */
      if (P.guia > 0 && vivoBlanco) {
        let dx = tx - x, dy = ty - y, dz = tz - z;
        // interceptación de primer orden
        const vel = Math.hypot(vx, vy, vz) || 1;
        const tAnticipo = Math.hypot(dx, dy, dz) / vel;
        dx += M.vx[blanco] * tAnticipo; dz += M.vz[blanco] * tAnticipo;
        if (P.serpentea) {
          // serpenteo: desplazamiento lateral senoidal alrededor de la línea de tiro
          this.prFase[id] += dt * 7;
          const lx = -dz, lz = dx;
          const ll = Math.hypot(lx, lz) || 1;
          const amp = Math.sin(this.prFase[id]) * 0.55;
          dx += (lx / ll) * amp * 6;
          dz += (lz / ll) * amp * 6;
          dy += Math.cos(this.prFase[id] * 0.7) * 1.2;
        }
        const dl = Math.hypot(dx, dy, dz) || 1;
        dx /= dl; dy /= dl; dz /= dl;
        const vl = Math.hypot(vx, vy, vz) || 1;
        let ux = vx / vl, uy = vy / vl, uz = vz / vl;
        const cos = clamp(ux * dx + uy * dy + uz * dz, -1, 1);
        const ang = Math.acos(cos);
        const maxA = P.guia * dt;
        const t = ang > 1e-4 ? Math.min(1, maxA / ang) : 1;
        ux += (dx - ux) * t; uy += (dy - uy) * t; uz += (dz - uz) * t;
        const ul = Math.hypot(ux, uy, uz) || 1;
        ux /= ul; uy /= ul; uz /= ul;
        const nuevaVel = Math.min(vl + (P.acel || 0) * dt, 95);
        vx = ux * nuevaVel; vy = uy * nuevaVel; vz = uz * nuevaVel;
      } else if (P.acel > 0) {
        const vl = Math.hypot(vx, vy, vz) || 1;
        const nv = Math.min(vl + P.acel * dt, 95);
        vx = (vx / vl) * nv; vy = (vy / vl) * nv; vz = (vz / vl) * nv;
      }

      if (P.grav) vy -= P.grav * dt;

      const nx = x + vx * dt, ny = y + vy * dt, nz = z + vz * dt;
      M.vx[id] = vx; M.vz[id] = vz; this.prVy[id] = vy;
      M.rot[id] = Math.atan2(vz, vx);

      /* --- estela --- */
      if (P.estelaTtl > 0) {
        const col = P.humo > 0.6 ? 0x6a6a72 : P.color;
        this.trazas.agregar(x, y, z, nx, ny, nz, col, P.estelaTtl);
      }

      /* --- colisión con el blanco (segmento contra esfera) --- */
      let impactado = -1;
      if (vivoBlanco) {
        const r = this._radioDe(blanco) + P.radio + 0.35;
        const cx = M.px[blanco], cy = this._alturaBlanco(blanco), cz = M.pz[blanco];
        if (this._segmentoEsfera(x, y, z, nx, ny, nz, cx, cy, cz, r)) impactado = blanco;
      }

      M.px[id] = nx; M.py[id] = ny; M.pz[id] = nz;

      if (impactado >= 0) { this._impactar(id, impactado, nx, ny, nz); continue; }

      /* --- suelo --- */
      const hSuelo = this.ctx.terreno?.altura?.(nx, nz) ?? 0;
      if (ny <= hSuelo + 0.05) {
        const explota = P.grav > 0 || this.prSalp[id] > 0;
        if (explota) this._impactar(id, -1, nx, hSuelo + 0.1, nz);
        else { this._chispa(nx, hSuelo + 0.1, nz, P); M.destruir(id); }
        continue;
      }

      /* --- llegó al punto de destino sin blanco vivo (tiro al suelo) --- */
      if (!vivoBlanco) {
        const ddx = nx - this.prDestX[id], ddz = nz - this.prDestZ[id];
        if (ddx * ddx + ddz * ddz < 0.8 && Math.abs(ny - this.prDestY[id]) < 1.5) {
          this._impactar(id, -1, nx, ny, nz);
          continue;
        }
      }

      this.prTtl[id] -= dt;
      if (this.prTtl[id] <= 0) {
        if (this.prSalp[id] > 0) this._impactar(id, -1, nx, ny, nz);
        else M.destruir(id);
      }
    }
  }

  _segmentoEsfera(ax, ay, az, bx, by, bz, cx, cy, cz, r) {
    const dx = bx - ax, dy = by - ay, dz = bz - az;
    const fx = ax - cx, fy = ay - cy, fz = az - cz;
    const len2 = dx * dx + dy * dy + dz * dz;
    let t = len2 > 1e-9 ? -(fx * dx + fy * dy + fz * dz) / len2 : 0;
    t = clamp(t, 0, 1);
    const px = fx + dx * t, py = fy + dy * t, pz = fz + dz * t;
    return px * px + py * py + pz * pz <= r * r;
  }

  _chispa(x, y, z, P) {
    this.ctx.efectos?.impacto?.(x, y, z, P.clave, 0.4);
  }

  _impactar(id, blancoId, x, y, z) {
    const M = this.ctx.mundo;
    const P = PROYECTILES[this.prTipo[id]];
    const fuente = this.prFuente[id];
    const salp = this.prSalp[id];
    const danioBase = this.prDanio[id];
    const jugador = M.jugador[id];

    let d = 0;
    if (blancoId >= 0) d = this.danio(fuente, blancoId, danioBase, 'perforante');

    const fuerza = clamp(danioBase / 40 + salp * 0.5, 0.3, 2.5);
    this.ctx.efectos?.impacto?.(x, y, z, P.clave, fuerza);

    if (salp > 0) {
      this.ctx.efectos?.explosion?.(x, y, z, salp * 1.6);
      this.ctx.terreno?.pintarDecal?.(x, z, 'crater', salp * 1.2, 0);
      this._danioArea(fuente, x, z, salp, danioBase, 'perforante', blancoId, this.prAmigo[id] === 1, jugador);
      this.ctx.audio?.sfx?.('explosion', { x, z });
      this._sacudir(x, z, clamp(salp * 0.6, 0.3, 2));
    } else {
      this.ctx.audio?.sfx?.('impacto_' + P.clave, { x, z });
      if (danioBase >= 40) this._sacudir(x, z, 0.3);
    }

    bus.emit('combate:impacto', {
      fuente, objetivo: blancoId, x, y, z, danio: d || danioBase, tipo: P.clave, salpicadura: salp,
    });
    M.destruir(id);
  }

  /**
   * Daño en área con caída lineal. `excluir` es el blanco directo (ya golpeado).
   * `fuegoAmigo` incluye a las unidades propias (artillería, como corresponde).
   */
  _danioArea(fuenteId, x, z, radio, cantidad, tipo, excluir, fuegoAmigo, jugadorFuente) {
    const M = this.ctx.mundo;
    const lista = M.cerca(x, z, radio + 2, this._buf1);
    for (let k = 0; k < lista.length; k++) {
      const o = lista[k];
      if (o === excluir || !M.vivo[o]) continue;
      if (M.tipo[o] !== TIPO.UNIDAD && M.tipo[o] !== TIPO.EDIFICIO) continue;
      if (M.estado[o] === ESTADO.MURIENDO) continue;
      const propio = M.jugador[o] === jugadorFuente;
      if (propio && !fuegoAmigo) continue;
      if (M.jugador[o] === 255) continue;
      const dx = M.px[o] - x, dz = M.pz[o] - z;
      const d = Math.sqrt(dx * dx + dz * dz) - this._radioDe(o);
      if (d > radio) continue;
      const caida = clamp(1 - Math.max(0, d) / radio, 0.15, 1);   // caída lineal
      this.danio(fuenteId, o, cantidad * caida, tipo);
    }
  }

  _sacudir(x, z, fuerza) {
    const c = this.ctx.camCtrl;
    if (!c || !c.sacudir || !c.foco) return;
    const dx = x - c.foco.x, dz = z - c.foco.z;
    const d = Math.hypot(dx, dz);
    const r = (c.distancia || 80) * 1.15;
    if (d > r) return;                        // fuera de pantalla: no molestamos
    c.sacudir(fuerza * (1 - d / r));
  }

  /* ================================================================ */
  /* Visual por frame                                                  */
  /* ================================================================ */

  cada(dtReal, alfa, ctx) {
    this.trazas.actualizar(dtReal);

    const M = ctx.mundo;
    this.cuerpos.reiniciar();
    const lista = this._proyectiles;
    for (let k = 0; k < lista.length; k++) {
      const id = lista[k];
      if (!M.vivo[id] || M.tipo[id] !== TIPO.PROYECTIL) continue;
      // si la vista ya le puso una malla, no lo dibujamos nosotros
      if (this.prVisualPropia[id] === 0) {
        this.prVisualPropia[id] = ctx.vista?.mallaDe?.(id) ? 2 : 1;
      }
      if (this.prVisualPropia[id] !== 1) continue;
      const P = PROYECTILES[this.prTipo[id]];
      if (!P) continue;
      const px = this.prPrevX[id] + (M.px[id] - this.prPrevX[id]) * alfa;
      const py = this.prPrevY[id] + (M.py[id] - this.prPrevY[id]) * alfa;
      const pz = this.prPrevZ[id] + (M.pz[id] - this.prPrevZ[id]) * alfa;
      this.cuerpos.poner(px, py, pz, M.vx[id], this.prVy[id], M.vz[id], P.radio, P.largo, P.color);
    }
    this.cuerpos.aplicar();
  }
}
