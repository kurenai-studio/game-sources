/* ==========================================================================
   30 NOCHES - events.js
   Eventos aleatorios con condiciones, duracion y limpieza de efectos.
   ========================================================================== */
window.TN = window.TN || {};

TN.Events = (function () {
  const U = TN.Utils;

  const EVENTS = {
    storm: {
      id: 'storm', name: 'Tormenta', group: 'weather', minDay: 6, weight: 3,
      desc: 'La lluvia tapa la visibilidad y el sonido.',
      duration: 26,
      apply: function (game) {
        game.weather.storm = 1;
        game.ui.toast('Tormenta: la visibilidad baja', 'warn');
      },
      end: function (game) { game.weather.storm = 0; }
    },
    blackout: {
      id: 'blackout', name: 'Apagon', group: 'tech', minDay: 4, weight: 3,
      desc: 'Las lamparas de la base se apagan un rato.',
      duration: 20,
      apply: function (game) {
        game.weather.blackout = 1;
        for (const b of game.buildings.list) if (b.type === 'lamp') b.disabled = true;
        game.ui.toast('Apagon: las lamparas se han apagado', 'warn');
      },
      end: function (game) {
        game.weather.blackout = 0;
        for (const b of game.buildings.list) if (b.type === 'lamp') b.disabled = false;
      }
    },
    fog: {
      id: 'fog', name: 'Niebla densa', group: 'weather', minDay: 3, weight: 3,
      desc: 'La niebla reduce lo que puedes ver.',
      duration: 22,
      apply: function (game) { game.weather.fog = 1; game.ui.toast('Niebla densa', 'warn'); },
      end: function (game) { game.weather.fog = 0; }
    },
    rareResources: {
      id: 'rareResources', name: 'Materiales raros', group: 'good', minDay: 2, weight: 3,
      desc: 'Has encontrado un alijo de materiales.',
      duration: 0,
      apply: function (game) {
        const inv = game.inventory;
        inv.addResource('scrap', 6);
        inv.addResource('stone', 4);
        inv.addResource('herbs', 2);
        game.ui.toast('Alijo encontrado: +6 chatarra, +4 piedra, +2 hierbas', 'good');
        game.audio.play('pickup');
      }
    },
    earlyElite: {
      id: 'earlyElite', name: 'Elite adelantada', group: 'bad', minDay: 19, weight: 2,
      desc: 'Una criatura de elite aparece antes de tiempo.',
      duration: 0,
      apply: function (game) {
        const diff = TN.Config.difficultyFor(game.dayNight.day);
        const type = diff.types[Math.floor(Math.random() * diff.types.length)];
        const pos = game.findSpawnPoint();
        const e = game.enemies.spawn(type, pos.x, pos.y, { diff: diff, elite: true });
        if (e) {
          game.ui.toast('Una criatura de elite ronda el bosque', 'warn');
          game.audio.play('bossWarn');
        }
      }
    },
    supplyCrate: {
      id: 'supplyCrate', name: 'Caja de suministros', group: 'good', minDay: 5, weight: 3,
      desc: 'Una caja aparece en una zona lejana.',
      duration: 0,
      apply: function (game) {
        const pos = game.findSpawnPoint();
        game.resources._mk('scrap', pos.x, pos.y, 12, 1, { scrap: 10 }, null);
        game.ui.toast('Una caja de suministros ha aparecido en el bosque', 'good');
      }
    },
    aggressiveNight: {
      id: 'aggressiveNight', name: 'Noche agresiva', group: 'bad', minDay: 8, weight: 2,
      desc: 'Mas criaturas de las habituales esta noche.',
      duration: 0,
      apply: function (game) {
        game.waveMultiplier = 1.6;
        game.ui.toast('Noche agresiva: se sienten mas criaturas de las habituales', 'warn');
      },
      // El multiplicador se restaura al acabar la noche (game.onNightEnd),
      // no al terminar el evento: es un evento instantaneo.
      end: function (game) { game.waveMultiplier = 1; }
    },
    radio: {
      id: 'radio', name: 'Interferencia de radio', group: 'good', minDay: 1, weight: 2,
      desc: 'Una interferencia revela la ubicacion de un punto de interes.',
      duration: 0,
      apply: function (game) {
        const hidden = game.world.pois.filter(p => !p.discovered);
        if (!hidden.length) {
          game.ui.toast('La radio solo emite estatico', 'info');
          return;
        }
        const p = hidden[Math.floor(Math.random() * hidden.length)];
        p.discovered = true;
        game.ui.toast('Radio: ' + p.name + ' esta en ' + Math.round(p.x) + ', ' + Math.round(p.y), 'good');
      }
    },
    ammoCache: {
      id: 'ammoCache', name: 'Municion abandonada', group: 'good', minDay: 4, weight: 3,
      desc: 'Has encontrado municion util.',
      duration: 0,
      apply: function (game) {
        game.inventory.addAmmo('arrow', 6);
        game.inventory.addAmmo('scrapAmmo', 8);
        game.ui.toast('Municion abandonada: +6 flechas, +8 balas', 'good');
      }
    }
  };

  class EventManager {
    constructor() {
      this.active = [];
      this.cooldown = 22;
      this.lastId = null;
      this.history = [];
    }

    clear() {
      for (const e of this.active) if (e.def.end && this.game) e.def.end(this.game);
      this.active.length = 0;
    }

    _available(game) {
      const out = [];
      const day = game.dayNight.day;
      const phase = game.dayNight.phase;
      for (const k in EVENTS) {
        const def = EVENTS[k];
        if (def.minDay && day < def.minDay) continue;
        if (def.group === 'weather' && phase !== 'night' && day < 10) continue;
        if (def.group === 'bad' && phase !== 'night') continue;
        if (this.active.some(a => a.def.group === def.group)) continue;
        if (this.history.indexOf(def.id) !== -1 && this.history.length > 3) continue;
        out.push(def);
      }
      return out;
    }

    update(dt, game) {
      this.game = game;
      // Actualizar eventos activos
      for (let i = this.active.length - 1; i >= 0; i--) {
        const a = this.active[i];
        if (a.def.update) a.def.update(dt, game, a);
        if (a.duration > 0) {
          a.timeLeft -= dt;
          if (a.timeLeft <= 0) {
            if (a.def.end) a.def.end(game);
            game.ui.toast('Fin de: ' + a.def.name, 'info');
            this.active.splice(i, 1);
          }
        } else {
          // Eventos instantaneos (duration 0): se retiran nada mas aplicarlos.
          // Si se quedaran en `active`, su grupo bloquearia el resto de
          // eventos del mismo grupo para siempre.
          this.active.splice(i, 1);
        }
      }
      // Lanzar nuevos eventos
      this.cooldown -= dt;
      if (this.cooldown <= 0) {
        this.cooldown = U.lerp(38, 16, U.clamp(game.dayNight.day / 30, 0, 1)) * (TN.Config.DEBUG.cycleScale < 1 ? 0.4 : 1);
        const pool = this._available(game);
        if (pool.length) {
          let total = 0;
          for (const p of pool) total += p.weight;
          let r = Math.random() * total;
          let chosen = pool[0];
          for (const p of pool) { r -= p.weight; if (r <= 0) { chosen = p; break; } }
          this.trigger(chosen, game);
        }
      }
    }

    trigger(def, game) {
      // Los eventos sin duracion son instantaneos: se aplican y se retiran.
      // Meterlos en `active` los dejaba bloqueados para siempre (su `end` no
      // se ejecutaba nunca y su grupo impedia que salieran mas eventos).
      if (def.duration > 0) {
        this.active.push({ def: def, timeLeft: def.duration, duration: def.duration });
      }
      this.history.push(def.id);
      if (this.history.length > 8) this.history.shift();
      if (def.apply) def.apply(game);
      if (def.duration > 0) {
        game.ui.toast('Evento: ' + def.name + ' - ' + def.desc, 'warn');
      }
      game.audio.play('ui');
    }

    hasActive(id) {
      return this.active.some(a => a.def.id === id);
    }

    serialize() {
      return this.active.map(a => ({ id: a.def.id, t: a.timeLeft }));
    }

    restore(data, game) {
      this.active.length = 0;
      if (!Array.isArray(data)) return;
      for (const rec of data) {
        const def = EVENTS[rec.id];
        if (!def) continue;
        // Los eventos instantaneos no se guardan (no tienen estado que
        // restaurar) y reaplicarlos daria material duplicado.
        if (!def.duration || def.duration <= 0) continue;
        this.active.push({ def: def, timeLeft: rec.t, duration: def.duration });
        if (def.apply) def.apply(game);
      }
    }
  }

  const Events = { Manager: EventManager, DEFINITIONS: EVENTS };
  Events.DEFINITIONS = EVENTS;
  return Events;
})();
