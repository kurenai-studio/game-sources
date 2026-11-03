/**
 * Bucle principal: simulación a paso fijo (20 Hz) + render a la tasa del monitor
 * con interpolación. Esto es lo que permite que el juego se sienta suave sin que
 * la física/IA dependan del framerate.
 */
import { bus } from './EventBus.js';

export const HZ_SIM = 20;
export const DT_SIM = 1 / HZ_SIM;
const MAX_ACUM = 0.25;

export class Engine {
  constructor() {
    this.sistemas = [];      // { nombre, orden, fijo(dt, ctx), cada(dtReal, alfa, ctx) }
    this.ctx = null;
    this.corriendo = false;
    this.acum = 0;
    this.ultimo = 0;
    this.velocidad = 1;      // multiplicador de velocidad de juego
    this.pausado = false;
    this.stats = { fps: 0, ms: 0, simMs: 0, renderMs: 0, dibujos: 0, triangulos: 0 };
    this._fpsAcum = 0; this._fpsCuenta = 0; this._fpsT = 0;
  }

  registrar(sistema) {
    this.sistemas.push(sistema);
    this.sistemas.sort((a, b) => (a.orden ?? 100) - (b.orden ?? 100));
    return sistema;
  }

  iniciar(ctx) {
    this.ctx = ctx;
    this.corriendo = true;
    this.ultimo = performance.now();
    const bucle = (t) => {
      if (!this.corriendo) return;
      requestAnimationFrame(bucle);
      const ahora = t;
      let dtReal = (ahora - this.ultimo) / 1000;
      this.ultimo = ahora;
      if (dtReal > MAX_ACUM) dtReal = MAX_ACUM;

      const t0 = performance.now();
      if (!this.pausado) {
        this.acum += dtReal * this.velocidad;
        let pasos = 0;
        while (this.acum >= DT_SIM && pasos < 5) {
          this.acum -= DT_SIM;
          pasos++;
          this.ctx.mundo.tick++;
          this.ctx.mundo.tiempo += DT_SIM;
          this.ctx.mundo.reconstruirRejilla();
          for (const s of this.sistemas) if (s.fijo) s.fijo(DT_SIM, this.ctx);
        }
      }
      const t1 = performance.now();
      const alfa = this.acum / DT_SIM;
      for (const s of this.sistemas) if (s.cada) s.cada(dtReal, alfa, this.ctx);
      const t2 = performance.now();

      this.stats.simMs = t1 - t0;
      this.stats.renderMs = t2 - t1;
      this.stats.ms = t2 - t0;
      this._fpsAcum += dtReal; this._fpsCuenta++;
      if (this._fpsAcum >= 0.5) {
        this.stats.fps = Math.round(this._fpsCuenta / this._fpsAcum);
        this._fpsAcum = 0; this._fpsCuenta = 0;
        bus.emit('stats', this.stats);
      }
    };
    requestAnimationFrame(bucle);
  }

  detener() { this.corriendo = false; }
}
