/**
 * MOVIMIENTO Y FORMACIONES — el tacto del juego.
 *
 * Acá vive lo que hace que un RTS se sienta bien: respuesta inmediata a la orden,
 * aceleración y frenado con peso, unidades que se esquivan sin trabarse y que al
 * llegar se acomodan sin vibrar.
 *
 * API pública (contrato):
 *   new Movimiento(ctx)
 *   .nombre = 'movimiento' ; .orden = 40
 *   .fijo(dt, ctx)                          — 20 Hz, toda la lógica pesada
 *   .cada(dtReal, alfa, ctx)                — por frame: giro suave y altura suave
 *   .ordenarMover(ids, x, z, opciones)      — formación + pedido de caminos
 *   .detener(ids)
 *   .formacion(ids, x, z, tipo) -> [{id,x,z}]
 *   .empujar(id, dx, dz, fuerza)            — retrocesos y explosiones
 *
 * Eventos que emite:
 *   'unidad:llego'  (carga: id numérico) — la unidad terminó su ruta (llegó o se rindió).
 *
 * Convenciones que respeta:
 *   - `rot` es yaw en radianes con 0 = mirando a +X. En Three.js una rotación en Y
 *     lleva +X a (cos, 0, -sin), por eso el yaw de marcha es atan2(-dz, dx).
 *   - La ruta de cada unidad vive en `ctx.mundo.meta.get(id).ruta` (array de {x,z})
 *     y el índice de avance en este sistema (`rutaIdx`), para no ensuciar el meta.
 *   - No mueve unidades en estado RECOLECTANDO / CONSTRUYENDO / ATACANDO /
 *     DEPOSITANDO / REPARANDO / MURIENDO / PRODUCIENDO (sí les aplica retrocesos).
 *   - Cero asignaciones por entidad por tick: todo el estado por unidad son arrays
 *     tipados del tamaño de World, reseteados cuando se recicla un id.
 */

import { TIPO, ESTADO } from '../core/World.js';
import { bus } from '../core/EventBus.js';
import { ORDEN } from '../core/Ctx.js';
import { UNIDADES } from '../data/unidades.js';
import { EDIFICIOS } from '../data/edificios.js';

export const FORMACIONES = ['linea', 'caja', 'flanco', 'dispersa'];

const DOS_PI = Math.PI * 2;
const ANGULO_ORO = 2.399963229728653;
const MAX_CAMINOS_TICK = 8;      // pedidos de camino resueltos por tick (evita picos)
const MAX_DECALS_TICK = 6;       // huellas pintadas por tick
const HORIZONTE = 0.55;          // segundos de anticipación para la evasión predictiva
const METROS_POR_HUELLA = 7.5;

/**
 * Perfil de manejo por clase. `acel`/`freno` en m/s², `giro` en rad/s.
 * Un tanque gira despacio y tarda en arrancar; un colono es un resorte.
 */
const PERFIL_CLASE = {
  aldeano:    { acel: 26, freno: 30, giro: 9.5, radio: 0.42, sep: 1.00 },
  infanteria: { acel: 24, freno: 28, giro: 8.5, radio: 0.45, sep: 1.00 },
  tirador:    { acel: 24, freno: 28, giro: 9.0, radio: 0.44, sep: 1.05 },
  apoyo:      { acel: 22, freno: 26, giro: 8.0, radio: 0.45, sep: 1.00 },
  caballeria: { acel: 14, freno: 16, giro: 4.2, radio: 0.68, sep: 1.10 },
  asedio:     { acel: 6.5, freno: 9,  giro: 1.5, radio: 0.95, sep: 1.25 },
  nave:       { acel: 3.5, freno: 2.6, giro: 0.85, radio: 1.70, sep: 1.35 },
  aereo:      { acel: 13, freno: 11, giro: 2.6, radio: 0.90, sep: 1.15 },
};

const OCUPADA = new Uint8Array(16);
OCUPADA[ESTADO.RECOLECTANDO] = 1;
OCUPADA[ESTADO.CONSTRUYENDO] = 1;
OCUPADA[ESTADO.ATACANDO] = 1;
OCUPADA[ESTADO.DEPOSITANDO] = 1;
OCUPADA[ESTADO.REPARANDO] = 1;
OCUPADA[ESTADO.MURIENDO] = 1;
OCUPADA[ESTADO.PRODUCIENDO] = 1;

/** Radio de choque de referencia para edificios, derivado de la tabla (celda = 2 m). */
const RADIO_EDIFICIO = EDIFICIOS.map((e) => {
  const cw = (e.celdas && e.celdas[0]) || 2;
  const ch = (e.celdas && e.celdas[1]) || 2;
  return Math.max(cw, ch); // círculo inscripto en la caja: deja pegarse a las esquinas
});

export class Movimiento {
  constructor(ctx) {
    this.nombre = 'movimiento';
    this.orden = ORDEN.MOVIMIENTO; // 40

    this.ctx = ctx;
    this.mundo = ctx.mundo;
    const cap = this.mundo.cap;

    /* ---- estado por unidad (arrays tipados, sin basura por tick) ---- */
    this.rutaIdx = new Int32Array(cap);      // waypoint actual dentro de meta.ruta
    this.grupoDe = new Uint16Array(cap);     // grupo de movimiento (0 = ninguno)
    this.velRitmo = new Float32Array(cap);   // tope de velocidad impuesto por el grupo
    this.asentado = new Uint8Array(cap);     // ya se acomodó: no vibra más
    this.bloqueo = new Float32Array(cap);    // segundos sin poder avanzar
    this.intentos = new Uint8Array(cap);     // recálculos de camino consumidos
    this.empX = new Float32Array(cap);       // canal de empuje externo (retrocesos)
    this.empZ = new Float32Array(cap);
    this.acumDecal = new Float32Array(cap);  // metros caminados desde la última huella
    this.factorPend = new Float32Array(cap); // penalización de pendiente cacheada
    this.altDest = new Float32Array(cap);    // altura objetivo del suelo/agua/vuelo
    this.pyInit = new Uint8Array(cap);       // ya se ancló la altura al menos una vez
    this.enCola = new Uint8Array(cap);
    this.factorPend.fill(1);

    /* ---- perfiles por defId (una sola vez) ---- */
    this.perfilBase = { ...PERFIL_CLASE.infanteria, vel: 4.5, vuela: false, naval: false, alturaVuelo: 0, pesado: false, modClave: 'infanteria' };
    this.perfilDef = UNIDADES.map((u) => {
      const b = PERFIL_CLASE[u.clase] || PERFIL_CLASE.infanteria;
      const pesado = u.clase === 'asedio' || (u.clase === 'caballeria' && (u.pop || 1) >= 2);
      const p = {
        acel: b.acel, freno: b.freno, giro: b.giro, radio: b.radio, sep: b.sep,
        vel: u.velocidad || 4.5,
        vuela: !!u.vuela, naval: !!u.naval,
        alturaVuelo: u.clase === 'aereo' ? 8 + (u.pop || 1) * 0.8 : 0,
        pesado,
        modClave: u.linea === 'comercio' ? 'comercio' : u.clase,
      };
      if (pesado) { // blindados y artillería: masa, inercia y giro de camión
        p.giro = Math.min(p.giro, 2.0);
        p.acel = Math.min(p.acel, 9);
        p.freno = Math.min(p.freno, 12);
        p.radio = Math.max(p.radio, 0.85);
      }
      return p;
    });

    /* ---- multiplicadores de velocidad por (jugador, defId), refrescados 1 vez/s ---- */
    this.nDef = UNIDADES.length;
    this.multVel = new Float32Array(8 * this.nDef);
    this.multVel.fill(1);
    this.ignoraPend = new Uint8Array(8);

    /* ---- cola de caminos diferidos ---- */
    this.cola = [];
    this.colaIni = 0;

    /* ---- scratch reutilizable ---- */
    this._vec = [];
    this._lista = [];
    this._ordU = [];
    this._ordP = [];
    this._decals = 0;
    this._lim = 0;
    this.contGrupo = 0;
    this.tVis = 0;

    // los ids se reciclan: al crear una entidad hay que limpiar su estado viejo
    this._alCrear = (id) => this.reiniciar(id);
    this.mundo.alCrear.add(this._alCrear);
  }

  /* ==================================================================== */
  /*  API pública                                                          */
  /* ==================================================================== */

  /**
   * Ordena mover un conjunto de unidades a (x,z).
   * opciones: {
   *   formacion: 'linea'|'caja'|'flanco'|'dispersa'|null,
   *   ritmo: bool     — el grupo marcha al paso del más lento
   *   encolar: bool   — reservado para Ordenes (no borra el objetivo actual)
   * }
   * Devuelve la cantidad de unidades que aceptaron la orden.
   */
  ordenarMover(ids, x, z, opciones) {
    const M = this.mundo;
    const op = opciones || {};
    const lista = this._filtrar(ids).slice();
    const n = lista.length;
    if (!n) return 0;

    let tipo = op.formacion;
    if (tipo === undefined || tipo === null) tipo = n > 1 ? this._formacionSugerida(lista) : null;

    // destinos finales: puesto de formación o el punto crudo si es una sola unidad
    const puestos = (n > 1 && tipo) ? this.formacion(lista, x, z, tipo) : null;
    const total = puestos ? puestos.length : n;

    const gid = this._nuevoGrupo();
    let velLenta = Infinity;
    if (op.ritmo) for (let i = 0; i < n; i++) velLenta = Math.min(velLenta, this._velMaxDe(lista[i]));

    // Respuesta inmediata: los primeros salen con camino real, el resto arranca
    // derecho al puesto y recibe su camino en los ticks siguientes. Nadie espera.
    let inmediatos = 16;

    for (let i = 0; i < total; i++) {
      const id = puestos ? puestos[i].id : lista[i];
      const px = puestos ? puestos[i].x : x;
      const pz = puestos ? puestos[i].z : z;
      if (!M.vivo[id]) continue;

      this.grupoDe[id] = gid;
      this.velRitmo[id] = op.ritmo && velLenta < Infinity ? velLenta : 0;
      this.asentado[id] = 0;
      this.bloqueo[id] = 0;
      this.intentos[id] = 0;
      M.destinoX[id] = px; M.destinoZ[id] = pz;
      M.tieneDestino[id] = 1;
      // una orden de mover manda sobre recolectar, construir o atacar
      if (M.estado[id] !== ESTADO.MURIENDO) M.estado[id] = ESTADO.MOVIENDO;

      if (inmediatos > 0) { inmediatos--; this._pedirCamino(id, px, pz); }
      else { this._rutaDirecta(id, px, pz); this._encolar(id); }
    }
    return total;
  }

  /** Corta la ruta: la unidad frena con su curva de frenado, no de golpe. */
  detener(ids) {
    const M = this.mundo;
    const lista = this._filtrar(ids);
    for (let i = 0; i < lista.length; i++) {
      const id = lista[i];
      const meta = M.meta.get(id);
      if (meta) meta.ruta = null;
      this.rutaIdx[id] = 0;
      this.velRitmo[id] = 0;
      this.bloqueo[id] = 0;
      this.intentos[id] = 0;
      this.asentado[id] = 0;
      M.tieneDestino[id] = 0;
      if (M.estado[id] === ESTADO.MOVIENDO) M.estado[id] = ESTADO.QUIETO;
    }
    return lista.length;
  }

  /**
   * Puestos de formación alrededor de (x,z) mirando desde el centroide del grupo.
   * Devuelve [{id,x,z}] en el MISMO orden que `ids`.
   * La asignación ordena unidades y puestos por su proyección lateral (la de la
   * izquierda queda a la izquierda) y después pule los cruces con barridos 2-opt.
   */
  formacion(ids, x, z, tipo) {
    const M = this.mundo;
    const lista = Array.isArray(ids) ? ids.filter((id) => M.vivo[id]) : this._filtrar(ids).slice();
    const n = lista.length;
    if (!n) return [];
    if (n === 1) return [{ id: lista[0], x, z }];

    // centroide y separación media
    let cx = 0, cz = 0, sep = 0;
    for (let i = 0; i < n; i++) {
      const id = lista[i];
      cx += M.px[id]; cz += M.pz[id];
      sep += this._radioDe(id);
    }
    cx /= n; cz /= n;
    sep = Math.max(1.7, (sep / n) * 2 + 0.9);

    // frente: del grupo hacia el destino
    let fx = x - cx, fz = z - cz;
    const fd = Math.sqrt(fx * fx + fz * fz);
    if (fd > 0.5) { fx /= fd; fz /= fd; } else { fx = 1; fz = 0; }
    const lx = -fz, lz = fx; // vector lateral (a 90°)

    // ---- puestos en coordenadas locales (ade = a lo largo del frente, lat = a lo ancho)
    const puestos = new Array(n);
    const t = FORMACIONES.indexOf(tipo) >= 0 ? tipo : (tipo === 'rigida' ? 'rigida' : 'caja');

    if (t === 'rigida') {
      // conserva la silueta actual del grupo: sólo lo traslada
      for (let i = 0; i < n; i++) {
        const id = lista[i];
        const dx = M.px[id] - cx, dz = M.pz[id] - cz;
        puestos[i] = { lat: dx * lx + dz * lz, ade: dx * fx + dz * fz, x: 0, z: 0 };
      }
    } else if (t === 'linea') {
      const filas = Math.max(1, Math.min(4, Math.round(Math.sqrt(n) / 2.2)));
      const cols = Math.ceil(n / filas);
      for (let i = 0; i < n; i++) {
        const r = Math.floor(i / cols);
        const enFila = Math.min(cols, n - r * cols);
        const c = i - r * cols;
        puestos[i] = { lat: (c - (enFila - 1) / 2) * sep, ade: -r * sep * 0.9, x: 0, z: 0 };
      }
    } else if (t === 'flanco') {
      // cuña: la punta adelante, las alas abiertas para envolver
      let i = 0, r = 0;
      while (i < n) {
        const enFila = r + 1;
        for (let k = 0; k < enFila && i < n; k++, i++) {
          puestos[i] = { lat: (k - r / 2) * sep * 1.05, ade: -r * sep * 0.8, x: 0, z: 0 };
        }
        r++;
      }
    } else if (t === 'dispersa') {
      // espiral de filotaxis: reparto parejo y determinista, sin apelotonar
      const paso = sep * 1.25;
      for (let i = 0; i < n; i++) {
        const ang = i * ANGULO_ORO;
        const rad = paso * Math.sqrt(i + 0.6);
        puestos[i] = { lat: Math.cos(ang) * rad, ade: Math.sin(ang) * rad, x: 0, z: 0 };
      }
    } else { // 'caja'
      const cols = Math.max(1, Math.ceil(Math.sqrt(n)));
      for (let i = 0; i < n; i++) {
        const r = Math.floor(i / cols);
        const enFila = Math.min(cols, n - r * cols);
        const c = i - r * cols;
        puestos[i] = { lat: (c - (enFila - 1) / 2) * sep, ade: (Math.ceil(n / cols) - 1) * sep * 0.45 - r * sep * 0.9, x: 0, z: 0 };
      }
    }

    // ---- a coordenadas de mundo, recortado al mapa
    const lim = this._limite();
    for (let i = 0; i < n; i++) {
      const p = puestos[i];
      let wx = x + fx * p.ade + lx * p.lat;
      let wz = z + fz * p.ade + lz * p.lat;
      if (wx < -lim) wx = -lim; else if (wx > lim) wx = lim;
      if (wz < -lim) wz = -lim; else if (wz > lim) wz = lim;
      p.x = wx; p.z = wz;
    }

    // ---- asignación (izquierda con izquierda) + pulido de cruces
    const asignado = this._asignar(lista, puestos, fx, fz, lx, lz, cx, cz);

    // ---- validación final: cada puesto tiene que ser pisable por SU unidad
    const salida = new Array(n);
    for (let i = 0; i < n; i++) {
      const id = lista[i];
      const p = puestos[asignado[i]];
      const radio = this._radioDe(id);
      const perfil = this._perfil(id);
      let px = p.x, pz = p.z;
      if (!this._puedePisar(px, pz, radio, perfil)) {
        let ok = false;
        for (let k = 1; k <= 6 && !ok; k++) {
          const f = k / 7;
          const tx = px + (x - px) * f, tz = pz + (z - pz) * f;
          if (this._puedePisar(tx, tz, radio, perfil)) { px = tx; pz = tz; ok = true; }
        }
      }
      salida[i] = { id, x: px, z: pz };
    }
    return salida;
  }

  /** Impulso externo en m/s (retrocesos, ondas de choque). No lo limita velMax. */
  empujar(id, dx, dz, fuerza) {
    const M = this.mundo;
    if (!M.vivo[id]) return;
    const d = Math.sqrt(dx * dx + dz * dz);
    if (d < 1e-5) return;
    const f = fuerza === undefined ? 4 : fuerza;
    let ex = this.empX[id] + (dx / d) * f;
    let ez = this.empZ[id] + (dz / d) * f;
    const m = Math.sqrt(ex * ex + ez * ez);
    if (m > 22) { ex = ex / m * 22; ez = ez / m * 22; }
    this.empX[id] = ex; this.empZ[id] = ez;
    this.asentado[id] = 0;
  }

  /** Limpia todo el estado de movimiento de un id (lo llama World al reciclar). */
  reiniciar(id) {
    this.rutaIdx[id] = 0;
    this.grupoDe[id] = 0;
    this.velRitmo[id] = 0;
    this.asentado[id] = 0;
    this.bloqueo[id] = 0;
    this.intentos[id] = 0;
    this.empX[id] = 0; this.empZ[id] = 0;
    this.acumDecal[id] = 0;
    this.factorPend[id] = 1;
    this.altDest[id] = 0;
    this.pyInit[id] = 0;
    this.enCola[id] = 0;
  }

  /* ==================================================================== */
  /*  Paso fijo (20 Hz)                                                    */
  /* ==================================================================== */

  fijo(dt, ctx) {
    const M = this.mundo;
    if ((M.tick % 20) === 0) this._refrescarMods();
    this._decals = 0;
    this._procesarCola();

    const n = M.maxUsado;
    for (let id = 0; id < n; id++) {
      if (!M.vivo[id] || M.tipo[id] !== TIPO.UNIDAD) continue;
      const p = this.perfilDef[M.defId[id]] || this.perfilBase;

      if (OCUPADA[M.estado[id]]) {
        // trabajando o peleando: no la movemos, pero el retroceso siempre vale
        M.vx[id] = 0; M.vz[id] = 0;
        if (this.empX[id] || this.empZ[id]) this._soloEmpuje(id, p, dt);
        this._altura(id, p);
        continue;
      }
      this._mover(id, p, dt);
    }
  }

  /* ==================================================================== */
  /*  Por frame: giro y altura suaves (visual, no afecta la simulación)     */
  /* ==================================================================== */

  cada(dtReal, alfa, ctx) {
    const M = this.mundo;
    this.tVis += dtReal;
    const agua = ctx.agua;
    const conOla = agua && typeof agua.alturaOla === 'function';
    const kAlt = 1 - Math.exp(-14 * dtReal);
    const n = M.maxUsado;

    for (let id = 0; id < n; id++) {
      if (!M.vivo[id] || M.tipo[id] !== TIPO.UNIDAD) continue;
      const p = this.perfilDef[M.defId[id]] || this.perfilBase;

      // giro hacia la dirección de marcha, limitado por clase
      let d = M.rotObjetivo[id] - M.rot[id];
      if (d > Math.PI) d -= DOS_PI; else if (d < -Math.PI) d += DOS_PI;
      if (d !== 0) {
        const maxG = p.giro * dtReal;
        if (d > maxG) d = maxG; else if (d < -maxG) d = -maxG;
        let r = M.rot[id] + d;
        if (r > Math.PI) r -= DOS_PI; else if (r < -Math.PI) r += DOS_PI;
        M.rot[id] = r;
      }

      // altura: se pega al suelo con suavizado; las naves cabecean con la ola
      if (!this.pyInit[id]) this._altura(id, p);
      let objetivo = this.altDest[id];
      if (p.naval && conOla) {
        const o = agua.alturaOla(M.px[id], M.pz[id], this.tVis);
        if (typeof o === 'number' && isFinite(o)) objetivo = o;
      }
      if (!this.pyInit[id]) { M.py[id] = objetivo; this.pyInit[id] = 1; }
      else M.py[id] += (objetivo - M.py[id]) * kAlt;
    }
  }

  /* ==================================================================== */
  /*  Núcleo del movimiento                                                */
  /* ==================================================================== */

  _mover(id, p, dt) {
    const M = this.mundo;
    const px = M.px[id], pz = M.pz[id];
    let vx = M.vx[id], vz = M.vz[id];
    const radio = this._radioDe(id);
    const jug = M.jugador[id];
    const grupo = this.grupoDe[id];

    let velMax = (M.velocidad[id] > 0.05 ? M.velocidad[id] : p.vel) * this.multVel[jug * this.nDef + M.defId[id]];
    const ritmo = this.velRitmo[id];
    if (ritmo > 0.05 && ritmo < velMax) velMax = ritmo; // el grupo marcha al paso del más lento

    /* ---------- 1. ruta ---------- */
    let meta = M.meta.get(id);
    let ruta = meta ? meta.ruta : null;
    if ((!ruta || !ruta.length) && M.tieneDestino[id] && M.estado[id] === ESTADO.MOVIENDO) {
      // otro sistema fijó destino sin pasar por ordenarMover: lo adoptamos
      this._rutaDirecta(id, M.destinoX[id], M.destinoZ[id]);
      this._encolar(id);
      meta = M.meta.get(id);
      ruta = meta.ruta;
    }

    let dirX = 0, dirZ = 0, velDeseada = 0, enMarcha = false;

    if (ruta && ruta.length) {
      let i = this.rutaIdx[id];
      if (i >= ruta.length) { this._llegar(id); ruta = null; }
      else {
        // atajo: si el waypoint siguiente se ve en línea recta, salteamos el actual
        if (i + 1 < ruta.length && ((M.tick + id) % 6) === 0) {
          const s = ruta[i + 1];
          if (this._lineaLibre(px, pz, s.x, s.z, radio, p)) { i++; this.rutaIdx[id] = i; }
        }
        let wp = ruta[i];
        let dx = wp.x - px, dz = wp.z - pz;
        let d = Math.sqrt(dx * dx + dz * dz);
        let ultimo = (i === ruta.length - 1);
        const umbral = ultimo ? Math.max(0.34, radio * 0.75) : (radio + 1.15);
        if (d <= umbral) {
          i++; this.rutaIdx[id] = i;
          if (i >= ruta.length) { this._llegar(id); ruta = null; }
          else {
            wp = ruta[i]; dx = wp.x - px; dz = wp.z - pz;
            d = Math.sqrt(dx * dx + dz * dz);
            ultimo = (i === ruta.length - 1);
          }
        }
        if (ruta && d > 1e-4) {
          dirX = dx / d; dirZ = dz / d;
          // arrive: frena con antelación suficiente para no pasarse de largo
          const rFreno = (velMax * velMax) / (2 * p.freno) + 0.5;
          const restante = ultimo ? d : 1e9;
          velDeseada = restante >= rFreno ? velMax : velMax * (restante / rFreno);
          if (velDeseada < 0.3 && ultimo && d < 0.6) velDeseada = 0;
          velDeseada *= this._pendiente(id, p, dirX, dirZ);
          enMarcha = velDeseada > 0.05;
        }
      }
    }

    if (enMarcha) this.asentado[id] = 0;

    /* ---------- 2. separación / evasión ---------- */
    let sepX = 0, sepZ = 0, corrX = 0, corrZ = 0;
    const asentada = this.asentado[id] === 1;
    const vecinos = M.cerca(px, pz, radio + 3.0, this._vec);
    const velAct = Math.sqrt(vx * vx + vz * vz);

    for (let k = 0; k < vecinos.length; k++) {
      const o = vecinos[k];
      if (o === id || !M.vivo[o]) continue;
      const tipoO = M.tipo[o];
      if (tipoO === TIPO.PROYECTIL || tipoO === TIPO.DECORADO) continue;

      const esUnidad = tipoO === TIPO.UNIDAD;
      const perfilO = esUnidad ? (this.perfilDef[M.defId[o]] || this.perfilBase) : null;
      if (p.vuela) { if (!perfilO || !perfilO.vuela) continue; }      // el aire ignora el suelo
      else if (perfilO && perfilO.vuela) continue;                     // y el suelo ignora al aire

      const dx = px - M.px[o], dz = pz - M.pz[o];
      const d2 = dx * dx + dz * dz;
      const ro = this._radioObj(o, tipoO, perfilO);
      const min = radio + ro;
      const alcance = min + 1.7;
      if (d2 >= alcance * alcance) continue;
      const d = Math.sqrt(d2) || 1e-4;

      if (!esUnidad) {
        // edificios y nodos de recurso: no se atraviesan nunca. Steering fuerte
        // + corrección de posición; el filtro de nav es la garantía final.
        const solapa = min + 0.15 - d;
        if (solapa > 0) {
          const f = 2.4 * (solapa / min);
          sepX += (dx / d) * f; sepZ += (dz / d) * f;
          if (solapa > 0.05) { corrX += (dx / d) * solapa * 0.55; corrZ += (dz / d) * solapa * 0.55; }
        }
        continue;
      }

      const mismoGrupo = grupo !== 0 && this.grupoDe[o] === grupo;
      const enemiga = M.jugador[o] !== jug;
      const solapa = min + 0.22 - d;

      if (solapa > 0) {
        let peso;
        const vo2 = M.vx[o] * M.vx[o] + M.vz[o] * M.vz[o];
        if (vo2 < 0.36) {
          peso = 1.85;                       // parada: hay que rodearla, no empujarla
        } else if (velAct > 0.3) {
          const alineado = (vx * M.vx[o] + vz * M.vz[o]) / (velAct * Math.sqrt(vo2));
          peso = 1.15 - 0.8 * alineado;      // misma dirección => casi no se estorban
          if (peso < 0.22) peso = 0.22; else if (peso > 2) peso = 2;
        } else peso = 1.1;
        if (mismoGrupo) peso *= 0.55;
        if (enemiga) peso *= 1.35;

        const f = peso * (solapa / min);
        sepX += (dx / d) * f; sepZ += (dz / d) * f;

        // desapilado duro: sólo si están MUY encimadas (evita el temblor)
        if (solapa > min * 0.45 + 0.05) {
          const g = (solapa - min * 0.45) * (mismoGrupo ? 0.4 : 0.5);
          corrX += (dx / d) * g; corrZ += (dz / d) * g;
        }
      } else if (enMarcha && vo2Movil(M, o)) {
        // evasión predictiva: miramos HORIZONTE segundos adelante
        const rvx = vx - M.vx[o], rvz = vz - M.vz[o];
        const rv2 = rvx * rvx + rvz * rvz;
        if (rv2 > 0.05) {
          const rpx = -dx, rpz = -dz;                 // de mí hacia el vecino
          const acerc = rvx * rpx + rvz * rpz;
          if (acerc > 0) {
            const tcpa = acerc / rv2;
            if (tcpa < HORIZONTE) {
              const cxp = rpx - rvx * tcpa, czp = rpz - rvz * tcpa;
              const cd = Math.sqrt(cxp * cxp + czp * czp);
              if (cd < min + 0.4) {
                const urg = (1 - tcpa / HORIZONTE) * (mismoGrupo ? 0.55 : 1);
                let ax, az;
                if (cd > 0.08) { ax = -cxp / cd; az = -czp / cd; }
                else { // frontal exacto: lado determinista y opuesto para cada uno
                  const s = ((id ^ o) & 1) ? 1 : -1;
                  ax = -rpz / d * s; az = rpx / d * s;
                }
                sepX += ax * urg * 1.15; sepZ += az * urg * 1.15;
              }
            }
          }
        }
      }
    }

    /* ---------- 3. velocidad deseada ---------- */
    let desX, desZ;
    if (asentada && !enMarcha) { desX = 0; desZ = 0; }
    else {
      desX = dirX * velDeseada + sepX * velMax * 0.9;
      desZ = dirZ * velDeseada + sepZ * velMax * 0.9;
      const tope = enMarcha ? velMax : velMax * 0.5;
      const dm = Math.sqrt(desX * desX + desZ * desZ);
      if (dm > tope && dm > 1e-6) { const kk = tope / dm; desX *= kk; desZ *= kk; }
    }
    const dm = Math.sqrt(desX * desX + desZ * desZ);

    /* ---------- 4. integración con aceleración/frenado ---------- */
    let sx = desX - vx, sz = desZ - vz;
    const sm = Math.sqrt(sx * sx + sz * sz);
    if (sm > 1e-6) {
      const aMax = (dm < velAct ? p.freno : p.acel) * dt;
      if (sm > aMax) { const kk = aMax / sm; sx *= kk; sz *= kk; }
      vx += sx; vz += sz;
    }

    // los pesados frenan para girar: giro y velocidad no son gratis a la vez
    if (p.giro < 5 && dm > 0.1) {
      const vm = Math.sqrt(vx * vx + vz * vz);
      if (vm > 0.5) {
        const cosA = (vx * desX + vz * desZ) / (vm * dm);
        if (cosA < 0.75) {
          const f = 0.55 + 0.45 * Math.max(0, cosA) / 0.75;
          vx *= f; vz *= f;
        }
      }
    }

    // tope de velocidad
    const v2 = vx * vx + vz * vz;
    const vmx = velMax * 1.02;
    if (v2 > vmx * vmx) { const kk = vmx / Math.sqrt(v2); vx *= kk; vz *= kk; }

    // sin objetivo: amortigua hasta parar del todo (nada de deslizarse eterno)
    if (!enMarcha) {
      vx *= 0.86; vz *= 0.86;
      if (vx * vx + vz * vz < 0.0225) {
        vx = 0; vz = 0;
        if (!ruta) {
          this.asentado[id] = 1;
          if (M.estado[id] === ESTADO.MOVIENDO && !M.tieneDestino[id]) M.estado[id] = ESTADO.QUIETO;
        }
      }
    }

    /* ---------- 5. desplazamiento con filtros de terreno ---------- */
    const ex = this.empX[id], ez = this.empZ[id];
    let nx = px + (vx + ex) * dt;
    let nz = pz + (vz + ez) * dt;
    if (ex !== 0 || ez !== 0) {
      const dec = Math.exp(-4.5 * dt);
      this.empX[id] = Math.abs(ex) < 0.02 ? 0 : ex * dec;
      this.empZ[id] = Math.abs(ez) < 0.02 ? 0 : ez * dec;
    }

    // corrección de desapilado (limitada: 0.1 m por tick, imperceptible pero constante)
    const cm = Math.sqrt(corrX * corrX + corrZ * corrZ);
    if (cm > 0.015) {
      const limC = Math.min(cm, 2.0 * dt);
      nx += corrX / cm * limC; nz += corrZ / cm * limC;
    }

    if (!p.vuela) {
      const yaAtrapada = !this._puedePisar(px, pz, radio, p);
      if (!yaAtrapada && !this._puedePisar(nx, nz, radio, p)) {
        // deslizar por el muro en vez de clavarse contra él
        if (this._puedePisar(nx, pz, radio, p)) { nz = pz; vz *= 0.35; }
        else if (this._puedePisar(px, nz, radio, p)) { nx = px; vx *= 0.35; }
        else { nx = px; nz = pz; vx *= 0.2; vz *= 0.2; this.bloqueo[id] += dt; }
      }
    }

    const lim = this._limite();
    if (nx < -lim) { nx = -lim; vx = 0; } else if (nx > lim) { nx = lim; vx = 0; }
    if (nz < -lim) { nz = -lim; vz = 0; } else if (nz > lim) { nz = lim; vz = 0; }

    M.px[id] = nx; M.pz[id] = nz;
    M.vx[id] = vx; M.vz[id] = vz;

    /* ---------- 6. orientación, huellas, altura, atascos ---------- */
    const vfin = Math.sqrt(vx * vx + vz * vz);
    if (vfin > 0.25) M.rotObjetivo[id] = Math.atan2(-vz, vx);

    if (vfin > 0.4 && !p.naval && !p.vuela) {
      this.acumDecal[id] += vfin * dt;
      if (this.acumDecal[id] >= METROS_POR_HUELLA) {
        this.acumDecal[id] = 0;
        if (this._decals < MAX_DECALS_TICK) {
          const T = this.ctx.terreno;
          if (T && typeof T.pintarDecal === 'function') {
            T.pintarDecal(nx, nz, radio * 1.15, 'camino');
            this._decals++;
          }
        }
      }
    }

    if (ruta && velDeseada > 0.6) {
      if (vfin < velDeseada * 0.28) this.bloqueo[id] += dt;
      else if (this.bloqueo[id] > 0) this.bloqueo[id] = Math.max(0, this.bloqueo[id] - dt * 0.6);
      if (this.bloqueo[id] > 1.1) {
        this.bloqueo[id] = 0;
        if (this.intentos[id] < 3) { this.intentos[id]++; this._encolar(id); }
        else this._llegar(id);   // se rinde: mejor quieta que temblando contra una pared
      }
    }

    this._altura(id, p);
  }

  /** Sólo aplica el retroceso a una unidad ocupada (trabajando o peleando). */
  _soloEmpuje(id, p, dt) {
    const M = this.mundo;
    const ex = this.empX[id], ez = this.empZ[id];
    const radio = this._radioDe(id);
    let nx = M.px[id] + ex * dt, nz = M.pz[id] + ez * dt;
    if (!p.vuela && !this._puedePisar(nx, nz, radio, p)) { nx = M.px[id]; nz = M.pz[id]; }
    const lim = this._limite();
    if (nx < -lim) nx = -lim; else if (nx > lim) nx = lim;
    if (nz < -lim) nz = -lim; else if (nz > lim) nz = lim;
    M.px[id] = nx; M.pz[id] = nz;
    const dec = Math.exp(-4.5 * dt);
    this.empX[id] = Math.abs(ex) < 0.02 ? 0 : ex * dec;
    this.empZ[id] = Math.abs(ez) < 0.02 ? 0 : ez * dec;
  }

  /* ==================================================================== */
  /*  Altura, pendiente y terreno                                          */
  /* ==================================================================== */

  _altura(id, p) {
    const M = this.mundo, ctx = this.ctx;
    const x = M.px[id], z = M.pz[id];
    let h = 0;
    const T = ctx.terreno;
    if (p.naval) {
      const A = ctx.agua;
      h = (A && typeof A.nivel === 'number') ? A.nivel : (T && T.altura ? T.altura(x, z) : 0);
    } else if (T && typeof T.altura === 'function') {
      h = T.altura(x, z);
    }
    if (p.vuela) {
      const A = ctx.agua;
      const suelo = T && typeof T.altura === 'function' ? T.altura(x, z) : 0;
      const nivel = (A && typeof A.nivel === 'number') ? A.nivel : 0;
      h = Math.max(suelo, nivel) + p.alturaVuelo;
    }
    this.altDest[id] = h;
  }

  /** Cuesta arriba se pierde hasta 40% de velocidad; cuesta abajo se gana un poco. */
  _pendiente(id, p, dirX, dirZ) {
    if (p.vuela || p.naval) return 1;
    const M = this.mundo;
    if (this.ignoraPend[M.jugador[id]]) return 1;
    const T = this.ctx.terreno;
    if (!T || typeof T.altura !== 'function') return 1;
    if (((M.tick + id) & 3) === 0) {
      const x = M.px[id], z = M.pz[id];
      const h0 = T.altura(x, z);
      const h1 = T.altura(x + dirX * 2.2, z + dirZ * 2.2);
      const g = (h1 - h0) / 2.2;
      let f;
      if (g > 0) { f = 1 - g * 1.0; if (f < 0.6) f = 0.6; }
      else { f = 1 - g * 0.3; if (f > 1.12) f = 1.12; }
      this.factorPend[id] = f;
    }
    const c = this.factorPend[id];
    return c > 0 ? c : 1;
  }

  _puedePisar(x, z, radio, p) {
    const lim = this._limite();
    if (x < -lim || x > lim || z < -lim || z > lim) return false;
    const ctx = this.ctx;
    const T = ctx.terreno;
    if (p && p.naval) {
      if (T && typeof T.bioma === 'function') return T.bioma(x, z) === 'agua';
      return true;
    }
    if (T && typeof T.transitable === 'function' && !T.transitable(x, z)) return false;
    const N = ctx.nav;
    if (N && typeof N.esLibre === 'function' && !N.esLibre(x, z, radio)) return false;
    return true;
  }

  _lineaLibre(x0, z0, x1, z1, radio, p) {
    if (p && p.vuela) return true;
    const dx = x1 - x0, dz = z1 - z0;
    const d = Math.sqrt(dx * dx + dz * dz);
    if (d < 0.01) return true;
    const pasos = Math.min(6, Math.max(2, Math.ceil(d / 2)));
    for (let i = 1; i <= pasos; i++) {
      const t = i / pasos;
      if (!this._puedePisar(x0 + dx * t, z0 + dz * t, radio, p)) return false;
    }
    return true;
  }

  /* ==================================================================== */
  /*  Caminos                                                              */
  /* ==================================================================== */

  _meta(id) {
    let m = this.mundo.meta.get(id);
    if (!m) { m = {}; this.mundo.meta.set(id, m); }
    return m;
  }

  _rutaDirecta(id, tx, tz) {
    const m = this._meta(id);
    m.ruta = [{ x: tx, z: tz }];
    this.rutaIdx[id] = 0;
  }

  _pedirCamino(id, tx, tz) {
    const M = this.mundo;
    if (!M.vivo[id]) return;
    const p = this._perfil(id);
    const radio = this._radioDe(id);
    let ruta = null;

    if (!p.vuela) {
      const N = this.ctx.nav;
      if (N && typeof N.camino === 'function') {
        try { ruta = N.camino(M.px[id], M.pz[id], tx, tz, radio); }
        catch (e) { ruta = null; }
      }
    }

    if (!ruta || !ruta.length) {
      this._rutaDirecta(id, tx, tz);
      return;
    }
    // el último punto de la rejilla puede quedar hasta 1 m corto: rematamos exacto
    const u = ruta[ruta.length - 1];
    const dx = tx - u.x, dz = tz - u.z;
    if (dx * dx + dz * dz > 0.09 && dx * dx + dz * dz < 9 && this._puedePisar(tx, tz, radio, p)) {
      ruta.push({ x: tx, z: tz });
    }
    // si el primer waypoint ya lo tenemos encima, arrancamos por el siguiente
    let ini = 0;
    if (ruta.length > 1) {
      const a = ruta[0];
      const ax = a.x - M.px[id], az = a.z - M.pz[id];
      if (ax * ax + az * az < (radio + 0.6) * (radio + 0.6)) ini = 1;
    }
    const m = this._meta(id);
    m.ruta = ruta;
    this.rutaIdx[id] = ini;
  }

  _encolar(id) {
    if (this.enCola[id]) return;
    this.enCola[id] = 1;
    this.cola.push(id);
  }

  _procesarCola() {
    const M = this.mundo;
    let hechos = 0;
    while (this.colaIni < this.cola.length && hechos < MAX_CAMINOS_TICK) {
      const id = this.cola[this.colaIni++];
      this.enCola[id] = 0;
      hechos++;
      if (!M.vivo[id] || M.tipo[id] !== TIPO.UNIDAD) continue;
      if (!M.tieneDestino[id]) continue;
      if (OCUPADA[M.estado[id]]) continue;
      this._pedirCamino(id, M.destinoX[id], M.destinoZ[id]);
    }
    if (this.colaIni >= this.cola.length) { this.cola.length = 0; this.colaIni = 0; }
    else if (this.colaIni > 512) { this.cola = this.cola.slice(this.colaIni); this.colaIni = 0; }
  }

  _llegar(id) {
    const M = this.mundo;
    const meta = M.meta.get(id);
    if (meta) meta.ruta = null;
    this.rutaIdx[id] = 0;
    this.velRitmo[id] = 0;
    this.bloqueo[id] = 0;
    this.intentos[id] = 0;
    M.tieneDestino[id] = 0;
    if (M.estado[id] === ESTADO.MOVIENDO) M.estado[id] = ESTADO.QUIETO;
    bus.emit('unidad:llego', id);
  }

  /* ==================================================================== */
  /*  Asignación de puestos                                                */
  /* ==================================================================== */

  /**
   * Devuelve, por índice de unidad, el índice de puesto asignado.
   * Primero ordena a ambos por (lateral, adelante) — así la de la izquierda queda
   * a la izquierda — y después pule los cruces con barridos de intercambio.
   */
  _asignar(lista, puestos, fx, fz, lx, lz, cx, cz) {
    const M = this.mundo;
    const n = lista.length;
    const ordU = this._ordU; ordU.length = 0;
    const ordP = this._ordP; ordP.length = 0;
    const claveU = new Float64Array(n);
    const claveP = new Float64Array(n);

    for (let i = 0; i < n; i++) {
      const id = lista[i];
      const dx = M.px[id] - cx, dz = M.pz[id] - cz;
      claveU[i] = (dx * lx + dz * lz) * 4096 + (dx * fx + dz * fz);
      claveP[i] = puestos[i].lat * 4096 + puestos[i].ade;
      ordU.push(i); ordP.push(i);
    }
    ordU.sort((a, b) => claveU[a] - claveU[b]);
    ordP.sort((a, b) => claveP[a] - claveP[b]);

    const asignado = new Int32Array(n);
    for (let k = 0; k < n; k++) asignado[ordU[k]] = ordP[k];

    // pulido: si dos vecinos en el orden ganan cruzándose, se cruzan
    for (let s = 0; s < 4; s++) {
      let mejoro = false;
      for (let k = 0; k + 1 < n; k++) {
        const ua = ordU[k], ub = ordU[k + 1];
        const pa = asignado[ua], pb = asignado[ub];
        const c0 = this._d2(lista[ua], puestos[pa]) + this._d2(lista[ub], puestos[pb]);
        const c1 = this._d2(lista[ua], puestos[pb]) + this._d2(lista[ub], puestos[pa]);
        if (c1 < c0 * 0.98) { asignado[ua] = pb; asignado[ub] = pa; mejoro = true; }
      }
      if (!mejoro) break;
    }
    return asignado;
  }

  _d2(id, puesto) {
    const M = this.mundo;
    const dx = M.px[id] - puesto.x, dz = M.pz[id] - puesto.z;
    return dx * dx + dz * dz;
  }

  /** Grupo compacto y chico: conserva su silueta. Si no, caja. */
  _formacionSugerida(lista) {
    const M = this.mundo;
    const n = lista.length;
    if (n > 16) return 'caja';
    let cx = 0, cz = 0;
    for (let i = 0; i < n; i++) { cx += M.px[lista[i]]; cz += M.pz[lista[i]]; }
    cx /= n; cz /= n;
    let max2 = 0;
    for (let i = 0; i < n; i++) {
      const dx = M.px[lista[i]] - cx, dz = M.pz[lista[i]] - cz;
      const d2 = dx * dx + dz * dz;
      if (d2 > max2) max2 = d2;
    }
    return max2 < 100 ? 'rigida' : 'caja';
  }

  /* ==================================================================== */
  /*  Utilidades                                                           */
  /* ==================================================================== */

  _filtrar(ids) {
    const M = this.mundo;
    const out = this._lista; out.length = 0;
    if (!ids) return out;
    if (typeof ids === 'number') { if (M.vivo[ids] && M.tipo[ids] === TIPO.UNIDAD) out.push(ids); return out; }
    for (const id of ids) {
      if (id === undefined || id === null) continue;
      if (M.vivo[id] && M.tipo[id] === TIPO.UNIDAD && M.estado[id] !== ESTADO.MURIENDO) out.push(id);
    }
    return out;
  }

  _perfil(id) { return this.perfilDef[this.mundo.defId[id]] || this.perfilBase; }

  _radioDe(id) {
    const r = this.mundo.radio[id];
    return r > 0.05 ? r : this._perfil(id).radio;
  }

  _radioObj(o, tipoO, perfilO) {
    const r = this.mundo.radio[o];
    if (r > 0.05) return r;
    if (tipoO === TIPO.EDIFICIO) return RADIO_EDIFICIO[this.mundo.defId[o]] || 2;
    if (perfilO) return perfilO.radio;
    return 1.0;
  }

  _velMaxDe(id) {
    const M = this.mundo;
    const p = this._perfil(id);
    const base = M.velocidad[id] > 0.05 ? M.velocidad[id] : p.vel;
    return base * this.multVel[M.jugador[id] * this.nDef + M.defId[id]];
  }

  _limite() {
    if (this._lim > 0) return this._lim;
    const t = (this.ctx.terreno && this.ctx.terreno.tam) || (this.ctx.mapa && this.ctx.mapa.tam) || 512;
    this._lim = t / 2 - 2;
    return this._lim;
  }

  _nuevoGrupo() {
    this.contGrupo = (this.contGrupo % 65000) + 1;
    return this.contGrupo;
  }

  /** Multiplicadores de velocidad y de pendiente por tecnologías, 1 vez por segundo. */
  _refrescarMods() {
    const eco = this.ctx.eco;
    const nd = this.nDef;
    for (let j = 0; j < 8; j++) {
      const m = eco && eco.mods ? eco.mods[j] : null;
      this.ignoraPend[j] = m && m.ignoraPendiente ? 1 : 0;
      const global = m && typeof m.velocidadGlobal === 'number' ? m.velocidadGlobal : 1;
      const tabla = m && m.velocidad ? m.velocidad : null;
      for (let d = 0; d < nd; d++) {
        let f = global;
        if (tabla) {
          const v = tabla[this.perfilDef[d].modClave];
          if (typeof v === 'number' && v > 0) f *= v;
        }
        this.multVel[j * nd + d] = f;
      }
    }
  }
}

/** ¿El vecino se está moviendo? (helper suelto para no inflar el bucle caliente) */
function vo2Movil(M, o) {
  return (M.vx[o] * M.vx[o] + M.vz[o] * M.vz[o]) > 0.09;
}
