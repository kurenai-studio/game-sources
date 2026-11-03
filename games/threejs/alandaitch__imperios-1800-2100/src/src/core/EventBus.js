/**
 * Bus de eventos global del juego. Síncrono, sin asignaciones en el camino caliente.
 * Contrato: on(evento, fn) -> función de baja; emit(evento, carga).
 */
export class EventBus {
  constructor() {
    /** @type {Map<string, Set<Function>>} */
    this.canales = new Map();
  }

  on(evento, fn) {
    let s = this.canales.get(evento);
    if (!s) { s = new Set(); this.canales.set(evento, s); }
    s.add(fn);
    return () => s.delete(fn);
  }

  once(evento, fn) {
    const baja = this.on(evento, (c) => { baja(); fn(c); });
    return baja;
  }

  off(evento, fn) {
    const s = this.canales.get(evento);
    if (s) s.delete(fn);
  }

  emit(evento, carga) {
    const s = this.canales.get(evento);
    if (!s) return;
    for (const fn of s) {
      try { fn(carga); } catch (e) { console.error(`[bus:${evento}]`, e); }
    }
  }
}

export const bus = new EventBus();
