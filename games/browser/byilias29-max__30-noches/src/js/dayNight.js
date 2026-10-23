/* ==========================================================================
   30 NOCHES - dayNight.js
   Temporizador de dia/noche basado en segundos reales, independiente de los
   fotogramas, con transiciones controladas.
   ========================================================================== */
window.TN = window.TN || {};

TN.DayNight = (function () {
  const U = TN.Utils;
  const CFG = TN.Config;

  class DayNightCycle {
    constructor() {
      this.day = 1;
      this.phase = 'day';        // 'day' | 'night' | 'final'
      this.timeLeft = CFG.TIME.day;
      this.phaseDuration = CFG.TIME.day;
      this.lightLevel = 1;
      this.totalElapsed = 0;
      this.nightsSurvived = 0;
      this.transitionGuard = false;
    }

    _scale() {
      const s = CFG.DEBUG.cycleScale || 1;
      return s;
    }

    startPhase(phase, game) {
      const scale = this._scale();
      if (phase === 'day') {
        this.phaseDuration = Math.max(1, CFG.TIME.day * scale);
      } else if (phase === 'night') {
        this.phaseDuration = Math.max(1, CFG.TIME.night * scale);
      } else {
        this.phaseDuration = Infinity;
      }
      this.timeLeft = this.phaseDuration;
      this.phase = phase;
      if (game) game.onPhaseChange(phase);
    }

    update(dt, game) {
      this.totalElapsed += dt;
      if (this.phase === 'final') {
        this.lightLevel = 0.3;
        return;
      }
      this.timeLeft -= dt;
      if (this.timeLeft <= 0) {
        this.timeLeft = 0;
        this._transition(game);
      }
      this._updateLight();
    }

    _transition(game) {
      if (this.transitionGuard) return;
      this.transitionGuard = true;
      if (this.phase === 'day') {
        this.startPhase('night', game);
      } else if (this.phase === 'night') {
        if (this.day >= CFG.CAMPAIGN_DAYS) {
          // Noche final: la partida continua hasta activar la antena
          this.phase = 'final';
          this.phaseDuration = Infinity;
          this.timeLeft = Infinity;
          this.lightLevel = 0.3;
          if (game) game.onPhaseChange('final');
        } else {
          this.lastNight = this.day;     // noche que se acaba de sobrevivir
          this.day++;
          this.nightsSurvived++;
          this.startPhase('day', game);
        }
      }
      this.transitionGuard = false;
    }

    _updateLight() {
      const dusk = CFG.TIME.dusk * this._scale();
      const dawn = CFG.TIME.dawn * this._scale();
      if (this.phase === 'day') {
        const t = this.timeLeft;
        if (t < dusk) this.lightLevel = U.lerp(0.14, 1, U.clamp(t / dusk, 0, 1));
        else if (this.phaseDuration - t < dawn) this.lightLevel = U.lerp(0.14, 1, U.clamp((this.phaseDuration - t) / dawn, 0, 1));
        else this.lightLevel = 1;
      } else if (this.phase === 'night') {
        const t = this.timeLeft;
        const total = this.phaseDuration;
        if (t > total - dusk) this.lightLevel = U.lerp(0.14, 1, U.clamp((total - t) / dusk, 0, 1));
        else if (t < dawn) this.lightLevel = U.lerp(0.14, 1, U.clamp(t / dawn, 0, 1));
        else this.lightLevel = 0.13;
      } else {
        this.lightLevel = 0.3;
      }
    }

    /* Saltar a la siguiente fase (modo desarrollo / pruebas). */
    skipPhase(game) {
      this.timeLeft = 0;
      this._transition(game);
    }

    phaseName() {
      if (this.phase === 'day') return 'DIA';
      if (this.phase === 'night') return 'NOCHE';
      return 'RESOLUCION';
    }

    threatText(game) {
      if (this.phase === 'day') {
        if (game.dayNight.day >= CFG.CAMPAIGN_DAYS) return 'Ultima preparacion';
        return 'Calma relativa';
      }
      const alive = game.enemies.aliveCount;
      if (game.getActiveBoss && game.getActiveBoss()) return 'JEFE EN COMBATE';
      if (alive > 18) return 'Asedio';
      if (alive > 8) return 'Ataque activo';
      if (alive > 0) return 'Presencia detectada';
      return 'Silencio';
    }

    serialize() {
      return {
        day: this.day, phase: this.phase,
        timeLeft: this.timeLeft === Infinity ? -1 : this.timeLeft,
        phaseDuration: this.phaseDuration === Infinity ? -1 : this.phaseDuration,
        totalElapsed: this.totalElapsed,
        nightsSurvived: this.nightsSurvived,
        lastNight: this.lastNight || 0
      };
    }

    restore(data) {
      if (!data) return;
      this.day = data.day || 1;
      this.phase = data.phase || 'day';
      this.timeLeft = data.timeLeft === -1 ? Infinity : (data.timeLeft || CFG.TIME.day);
      this.phaseDuration = data.phaseDuration === -1 ? Infinity : (data.phaseDuration || CFG.TIME.day);
      this.totalElapsed = data.totalElapsed || 0;
      this.nightsSurvived = data.nightsSurvived || 0;
      this.lastNight = data.lastNight || 0;
      this._updateLight();
    }
  }

  return DayNightCycle;
})();
