/**
 * Producción: colas de entrenamiento, obras en construcción y puntos de reunión.
 *
 * Diseño: la cola vive en `mundo.meta.get(edificioId).cola`, un array de
 * `{ tipo:'unidad'|'tecno', clave, restante, total, defId }`. Solo la cabeza
 * consume tiempo. Cancelar devuelve el 100% de lo pagado, como en AoE2.
 */
import { TIPO, ESTADO } from '../core/World.js';
import { ORDEN } from '../core/Ctx.js';
import { UNIDADES, UNIDAD_POR_CLAVE } from '../data/unidades.js';
import { EDIFICIOS, EDIFICIO_POR_CLAVE } from '../data/edificios.js';
import { TECNOLOGIAS, TECNO_POR_CLAVE } from '../data/tecnologias.js';
import { bus } from '../core/EventBus.js';

const CELDA = 2; // metros por celda de rejilla

export class Produccion {
  constructor(ctx) {
    this.nombre = 'produccion';
    this.orden = ORDEN.ECONOMIA;
    this.ctx = ctx;
    /** Obras en curso: edificioId -> { colonos:Set, trabajoTotal, trabajoHecho } */
    this.obras = new Map();
    this.puntosReunion = new Map(); // edificioId -> {x,z,objetivo}
  }

  /* ------------------------------------------------------------------ */
  /* Emplazado                                                           */
  /* ------------------------------------------------------------------ */

  /** ¿Se puede poner este edificio acá? Devuelve {puede, motivo}. */
  puedeEmplazar(jugador, claveEdificio, x, z) {
    const { ctx } = this;
    const def = EDIFICIOS[EDIFICIO_POR_CLAVE.get(claveEdificio)];
    if (!def) return { puede: false, motivo: 'Edificio desconocido' };

    const edad = ctx.edades?.edad?.[jugador] ?? 0;
    if (def.edad > edad) return { puede: false, motivo: `Requiere la ${['Edad del Vapor', 'Edad Eléctrica', 'Edad Atómica', 'Edad de la Información', 'Edad Sintética'][def.edad]}` };
    if (!ctx.eco?.puedePagar(jugador, def.coste)) return { puede: false, motivo: 'No alcanzan los recursos' };

    const [cw, ch] = def.celdas;
    const mitadX = (cw * CELDA) / 2, mitadZ = (ch * CELDA) / 2;

    // pendiente y agua bajo toda la huella
    let pendMax = 0, hMin = Infinity, hMax = -Infinity;
    for (let i = 0; i <= cw; i++) {
      for (let j = 0; j <= ch; j++) {
        const px = x - mitadX + i * CELDA, pz = z - mitadZ + j * CELDA;
        const h = ctx.terreno?.altura(px, pz) ?? 0;
        hMin = Math.min(hMin, h); hMax = Math.max(hMax, h);
        pendMax = Math.max(pendMax, ctx.terreno?.pendiente(px, pz) ?? 0);
        if (!def.costero && h < (ctx.mapa?.nivelAgua ?? 0) + 0.15) {
          return { puede: false, motivo: 'No se puede construir sobre el agua' };
        }
      }
    }
    if (pendMax > 0.32 || hMax - hMin > 2.4) return { puede: false, motivo: 'El terreno es muy irregular' };

    if (def.costero) {
      // el astillero necesita agua a menos de 6 m de su borde
      let tocaAgua = false;
      for (let a = 0; a < 16 && !tocaAgua; a++) {
        const ang = (a / 16) * Math.PI * 2;
        const px = x + Math.cos(ang) * (mitadX + 5), pz = z + Math.sin(ang) * (mitadZ + 5);
        if ((ctx.terreno?.altura(px, pz) ?? 0) < (ctx.mapa?.nivelAgua ?? 0)) tocaAgua = true;
      }
      if (!tocaAgua) return { puede: false, motivo: 'Tiene que tocar el agua' };
    }

    // colisión con lo que ya hay
    const cerca = ctx.mundo.cerca(x, z, Math.max(mitadX, mitadZ) + 6);
    for (const otro of cerca) {
      if (ctx.mundo.tipo[otro] === TIPO.UNIDAD) continue;
      const r = ctx.mundo.radio[otro] || 1;
      const dx = Math.abs(ctx.mundo.px[otro] - x), dz = Math.abs(ctx.mundo.pz[otro] - z);
      if (dx < mitadX + r && dz < mitadZ + r) return { puede: false, motivo: 'Hay algo en el camino' };
    }
    return { puede: true, motivo: '' };
  }

  /** Coloca el cimiento. Los colonos lo terminan trabajando. */
  emplazar(jugador, claveEdificio, x, z, rot = 0) {
    const { ctx } = this;
    const chequeo = this.puedeEmplazar(jugador, claveEdificio, x, z);
    if (!chequeo.puede) { bus.emit('aviso', { texto: chequeo.motivo, tipo: 'error' }); return -1; }

    const defId = EDIFICIO_POR_CLAVE.get(claveEdificio);
    const def = EDIFICIOS[defId];
    if (!ctx.eco.pagar(jugador, def.coste)) return -1;

    const id = ctx.mundo.crear(TIPO.EDIFICIO, defId, x, z, jugador);
    const m = ctx.mundo;
    m.rot[id] = rot;
    m.vidaMax[id] = def.vida;
    m.vida[id] = Math.max(1, def.vida * 0.05);   // arranca casi en cero y sube con la obra
    m.radio[id] = Math.max(def.celdas[0], def.celdas[1]) * CELDA * 0.5;
    m.estado[id] = ESTADO.CONSTRUYENDO;
    m.progreso[id] = 0;
    m.py[id] = ctx.terreno?.altura(x, z) ?? 0;

    ctx.terreno?.aplanar?.(x, z, def.celdas[0] * CELDA, def.celdas[1] * CELDA);
    ctx.nav?.bloquear?.(x, z, def.celdas[0] * CELDA, def.celdas[1] * CELDA, 1);
    // sin esto los árboles siguen atravesando el techo del edificio nuevo
    ctx.foliaje?.despejar?.(x, z, def.celdas[0] * CELDA, def.celdas[1] * CELDA);

    const factorCiv = ctx.eco.mods[jugador]?.velConstruccion ?? 1;
    this.obras.set(id, { colonos: new Set(), trabajoTotal: def.tiempo / factorCiv, trabajoHecho: 0 });
    bus.emit('obra:iniciada', { id, jugador, clave: claveEdificio });
    return id;
  }

  /** Un colono se suma (o se va) de una obra. */
  asignarObrero(edificioId, colonoId, sumar = true) {
    const obra = this.obras.get(edificioId);
    if (!obra) return false;
    if (sumar) obra.colonos.add(colonoId); else obra.colonos.delete(colonoId);
    return true;
  }

  /* ------------------------------------------------------------------ */
  /* Colas de entrenamiento e investigación                              */
  /* ------------------------------------------------------------------ */

  _meta(id) {
    let m = this.ctx.mundo.meta.get(id);
    if (!m) { m = {}; this.ctx.mundo.meta.set(id, m); }
    if (!m.cola) m.cola = [];
    return m;
  }

  encolarUnidad(edificioId, claveUnidad, cantidad = 1) {
    const { ctx } = this;
    const m = ctx.mundo;
    if (!m.vivo[edificioId] || m.estado[edificioId] === ESTADO.CONSTRUYENDO) {
      bus.emit('aviso', { texto: 'El edificio todavía está en obra', tipo: 'error' });
      return false;
    }
    const jugador = m.jugador[edificioId];
    const defU = UNIDADES[UNIDAD_POR_CLAVE.get(claveUnidad)];
    const defE = EDIFICIOS[m.defId[edificioId]];
    if (!defU || !defE?.entrena?.includes(claveUnidad)) return false;

    const edad = ctx.edades?.edad?.[jugador] ?? 0;
    if (defU.edad > edad) { bus.emit('aviso', { texto: `${defU.nombre} necesita una edad más avanzada`, tipo: 'error' }); return false; }

    const meta = this._meta(edificioId);
    if (meta.cola.length + cantidad > 15) { bus.emit('aviso', { texto: 'La cola está llena', tipo: 'error' }); return false; }

    const mods = ctx.eco.mods[jugador];
    for (let i = 0; i < cantidad; i++) {
      const coste = this._costeUnidad(defU, mods);
      const pob = ctx.eco.pob[jugador];
      if (pob && pob.actual + defU.pop > pob.tope) {
        bus.emit('aviso', { texto: 'Falta población: construí una Vivienda', tipo: 'alerta' });
        return i > 0;
      }
      if (!ctx.eco.pagar(jugador, coste)) {
        bus.emit('aviso', { texto: `No alcanzan los recursos para ${defU.nombre}`, tipo: 'error' });
        return i > 0;
      }
      const velocidad = (mods?.velEntrenamiento ?? 1) *
        (defU.clase === 'infanteria' ? (mods?.velEntrenamientoInf ?? 1) : 1) *
        (defU.naval ? (mods?.velAstillero ?? 1) : 1);
      meta.cola.push({
        tipo: 'unidad', clave: claveUnidad, defId: UNIDAD_POR_CLAVE.get(claveUnidad),
        total: defU.tiempo / velocidad, restante: defU.tiempo / velocidad, coste,
      });
    }
    bus.emit('cola:cambio', { edificioId });
    return true;
  }

  _costeUnidad(defU, mods) {
    const c = { ...defU.coste };
    if (mods?.descuentoAlimentoMilitar && defU.clase !== 'aldeano') {
      c.alimento = Math.round(c.alimento * mods.descuentoAlimentoMilitar);
    }
    return c;
  }

  encolarTecnologia(edificioId, claveTecno) {
    const { ctx } = this;
    const m = ctx.mundo;
    const jugador = m.jugador[edificioId];
    const idx = TECNO_POR_CLAVE.get(claveTecno);
    const def = TECNOLOGIAS[idx];
    if (!def) return false;

    const chequeo = ctx.edades?.puedeInvestigar?.(jugador, claveTecno) ?? { puede: true, motivo: '' };
    if (!chequeo.puede) { bus.emit('aviso', { texto: chequeo.motivo, tipo: 'error' }); return false; }

    const defE = EDIFICIOS[m.defId[edificioId]];
    if (def.en !== defE.clave) return false;

    const mods = ctx.eco.mods[jugador];
    const coste = { ...def.coste };
    if (def.en === 'fundicion' && mods?.descuentoFundicion) {
      for (const k in coste) coste[k] = Math.round(coste[k] * mods.descuentoFundicion);
    }
    if (!ctx.eco.pagar(jugador, coste)) { bus.emit('aviso', { texto: 'No alcanzan los recursos', tipo: 'error' }); return false; }

    const meta = this._meta(edificioId);
    const t = def.tiempo / (mods?.velInvestigacion ?? 1);
    meta.cola.push({ tipo: 'tecno', clave: claveTecno, defId: idx, total: t, restante: t, coste });
    bus.emit('cola:cambio', { edificioId });
    return true;
  }

  cancelar(edificioId, indice = -1) {
    const meta = this.ctx.mundo.meta.get(edificioId);
    if (!meta?.cola?.length) return false;
    const i = indice < 0 ? meta.cola.length - 1 : indice;
    const item = meta.cola.splice(i, 1)[0];
    if (item) this.ctx.eco.reembolsar(this.ctx.mundo.jugador[edificioId], item.coste);
    bus.emit('cola:cambio', { edificioId });
    return true;
  }

  fijarPuntoReunion(edificioId, x, z, objetivo = -1) {
    this.puntosReunion.set(edificioId, { x, z, objetivo });
  }

  /* ------------------------------------------------------------------ */

  fijo(dt, ctx) {
    const m = ctx.mundo;

    // --- obras en construcción ---
    for (const [id, obra] of this.obras) {
      if (!m.vivo[id]) { this.obras.delete(id); continue; }
      const n = obra.colonos.size;
      if (n === 0) continue;
      // rendimiento decreciente: 4 colonos no van 4x más rápido
      const mods = ctx.eco.mods[m.jugador[id]];
      const ritmo = Math.sqrt(n) * (mods?.velConstruccion ?? 1);
      obra.trabajoHecho += dt * ritmo;
      const t = Math.min(1, obra.trabajoHecho / obra.trabajoTotal);
      m.progreso[id] = t;
      const def = EDIFICIOS[m.defId[id]];
      m.vida[id] = Math.max(m.vida[id], def.vida * (0.05 + 0.95 * t));
      if (t >= 1) {
        m.estado[id] = ESTADO.QUIETO;
        m.vida[id] = def.vida;
        this.obras.delete(id);
        for (const c of obra.colonos) if (m.vivo[c]) m.estado[c] = ESTADO.QUIETO;
        bus.emit('obra:terminada', { id, jugador: m.jugador[id], clave: def.clave });
        bus.emit('aviso', { texto: `${def.nombre} terminado`, tipo: 'info' });
        ctx.audio?.sfx?.('construccion_fin', { x: m.px[id], z: m.pz[id] });
      }
    }

    // --- colas de producción ---
    for (const id of m.deTipo(TIPO.EDIFICIO)) {
      if (m.estado[id] === ESTADO.CONSTRUYENDO) continue;
      const meta = m.meta.get(id);
      if (!meta?.cola?.length) continue;
      const item = meta.cola[0];
      item.restante -= dt;
      m.progreso[id] = 1 - item.restante / item.total;
      if (item.restante > 0) continue;

      meta.cola.shift();
      m.progreso[id] = 0;
      if (item.tipo === 'unidad') this._salirUnidad(id, item, ctx);
      else ctx.edades?.completarTecnologia?.(m.jugador[id], item.clave);
      bus.emit('cola:cambio', { edificioId: id });
    }

    // --- autorreparación de edificios (tecnología de la Edad Sintética) ---
    if (m.tick % 20 === 0) {
      for (const id of m.deTipo(TIPO.EDIFICIO)) {
        const mods = ctx.eco.mods[m.jugador[id]];
        if (!mods?.autorreparacion) continue;
        if (m.estado[id] === ESTADO.CONSTRUYENDO) continue;
        if (m.vida[id] < m.vidaMax[id]) m.vida[id] = Math.min(m.vidaMax[id], m.vida[id] + mods.autorreparacion);
      }
    }
  }

  _salirUnidad(edificioId, item, ctx) {
    const m = ctx.mundo;
    const jugador = m.jugador[edificioId];
    const def = EDIFICIOS[m.defId[edificioId]];
    const defU = UNIDADES[item.defId];

    // la unidad aparece en el borde del edificio, del lado del punto de reunión
    const reunion = this.puntosReunion.get(edificioId);
    const bx = m.px[edificioId], bz = m.pz[edificioId];
    let ang = ctx.rng.float(0, Math.PI * 2);
    if (reunion) ang = Math.atan2(reunion.z - bz, reunion.x - bx);
    const r = Math.max(def.celdas[0], def.celdas[1]) * CELDA * 0.5 + 1.6;
    let sx = bx + Math.cos(ang) * r, sz = bz + Math.sin(ang) * r;
    const libre = ctx.nav?.puntoLibreCerca?.(sx, sz, 4);
    if (libre) { sx = libre.x; sz = libre.z; }

    const id = m.crear(TIPO.UNIDAD, item.defId, sx, sz, jugador);
    const mods = ctx.eco.mods[jugador];
    const clase = defU.clase;
    m.vidaMax[id] = defU.vida + (mods?.vidaExtra?.[clase] ?? 0);
    m.vida[id] = m.vidaMax[id];
    m.radio[id] = defU.clase === 'asedio' || defU.clase === 'caballeria' ? 1.1 : 0.55;
    m.velocidad[id] = defU.velocidad * (mods?.velocidad?.[clase] ?? 1);
    m.rot[id] = ang;
    m.py[id] = ctx.terreno?.altura(sx, sz) ?? 0;
    m.estado[id] = ESTADO.QUIETO;

    bus.emit('unidad:entrenada', { id, jugador, clave: item.clave });
    ctx.audio?.sfx?.('unidad_lista', { x: sx, z: sz });

    if (reunion) {
      if (reunion.objetivo >= 0 && m.vivo[reunion.objetivo]) {
        const tipoObj = m.tipo[reunion.objetivo];
        if (tipoObj === TIPO.RECURSO) ctx.ordenes?.recolectar?.([id], reunion.objetivo);
        else ctx.ordenes?.atacar?.([id], reunion.objetivo);
      } else {
        ctx.ordenes?.mover?.([id], reunion.x, reunion.z);
      }
    }
  }
}
