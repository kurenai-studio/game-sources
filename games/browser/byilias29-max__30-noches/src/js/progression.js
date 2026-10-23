/* ==========================================================================
   30 NOCHES - progression.js
   Progresion permanente: puntos de investigacion, desbloqueos, records
   y opciones. Se guarda en localStorage, separada de la partida.
   ========================================================================== */
window.TN = window.TN || {};

TN.Progression = (function () {
  const U = TN.Utils;

  const RESEARCH = {
    harvest: {
      id: 'harvest', name: 'Recoleccion eficiente', max: 3, costs: [20, 35, 60],
      desc: '+15% de recursos obtenidos por nivel (tambien en la partida actual).'
    },
    craft: {
      id: 'craft', name: 'Ahorro de materiales', max: 3, costs: [25, 45, 80],
      desc: '-10% de coste de fabricacion y construccion por nivel.'
    },
    vigor: {
      id: 'vigor', name: 'Vigor', max: 3, costs: [20, 40, 70],
      desc: '+15 de vida maxima por nivel.'
    },
    stock: {
      id: 'stock', name: 'Almacen de campana', max: 2, costs: [15, 35],
      desc: 'Empiezas cada expedicion con materiales extra.'
    },
    scout: {
      id: 'scout', name: 'Rastreador', max: 1, costs: [25],
      desc: 'Los puntos de interes aparecen marcados en el minimapa desde el inicio.'
    },
    unlock_bow: {
      id: 'unlock_bow', name: 'Arco de monte', max: 1, costs: [30],
      desc: 'Desbloquea la receta del Arco y las flechas.'
    },
    unlock_pistol: {
      id: 'unlock_pistol', name: 'Armeria basica', max: 1, costs: [45],
      desc: 'Desbloquea la receta de la pistola improvisada y su municion.'
    },
    unlock_baton: {
      id: 'unlock_baton', name: 'Electroquimica', max: 1, costs: [70],
      desc: 'Desbloquea elaston electrico y el rifle de pernos.'
    }
  };

  const DEFAULTS = {
    rp: 0,
    research: {},
    unlocked: {},
    records: { bestDay: 0, bestTime: 0, nights: 0, kills: 0, bosses: 0, expeditions: 0, victories: 0 },
    options: {
      volume: 0.6,
      muted: false,
      cycleScale: 1,
      screenEffects: true,
      showCoords: false
    }
  };

  class Progression {
    constructor() {
      this.rp = 0;
      this.research = {};
      this.unlocked = {};
      this.records = Object.assign({}, DEFAULTS.records);
      this.options = Object.assign({}, DEFAULTS.options);
      this.load();
    }

    /* --- Puntos ---------------------------------------------------------- */
    addRp(n) {
      if (!(n > 0)) return;
      this.rp += Math.round(n);
      this.save();
    }

    canBuy(id) {
      const r = RESEARCH[id];
      if (!r) return false;
      const lvl = this.research[id] || 0;
      if (lvl >= r.max) return false;
      return this.rp >= r.costs[lvl];
    }

    buy(id) {
      const r = RESEARCH[id];
      if (!r || !this.canBuy(id)) return false;
      const lvl = this.research[id] || 0;
      this.rp -= r.costs[lvl];
      this.research[id] = lvl + 1;
      if (id.indexOf('unlock_') === 0) this.unlocked[id] = true;
      this.save();
      return true;
    }

    get(id) { return this.research[id] || 0; }
    isUnlocked(id) { return !!this.unlocked[id]; }

    /* Multiplicadores permanentes aplicados a la partida */
    harvestBonus() { return 1 + this.get('harvest') * 0.15; }
    craftBonus() { return 1 - this.get('craft') * 0.1; }
    maxHpBonus() { return this.get('vigor') * 15; }

    /* --- Records --------------------------------------------------------- */
    recordRun(stats) {
      this.records.expeditions++;
      this.records.nights += stats.nights || 0;
      this.records.kills += stats.kills || 0;
      this.records.bosses += stats.bosses || 0;
      if ((stats.day || 0) > this.records.bestDay) this.records.bestDay = stats.day || 0;
      if ((stats.time || 0) > this.records.bestTime) this.records.bestTime = stats.time || 0;
      if (stats.victory) this.records.victories++;
      this.save();
    }

    /* --- Persistencia ---------------------------------------------------- */
    load() {
      let raw = null;
      try { raw = localStorage.getItem(TN.Config.STORAGE_KEYS.meta); } catch (e) { raw = null; }
      if (!raw) return;
      try {
        const d = JSON.parse(raw);
        if (!d || typeof d !== 'object') return;
        this.rp = typeof d.rp === 'number' ? d.rp : 0;
        this.research = d.research || {};
        this.unlocked = d.unlocked || {};
        this.records = Object.assign({}, DEFAULTS.records, d.records || {});
        this.options = Object.assign({}, DEFAULTS.options, d.options || {});
      } catch (e) {
        console.warn('[TN] no se pudo leer la progresion permanente', e);
      }
    }

    save() {
      try {
        localStorage.setItem(TN.Config.STORAGE_KEYS.meta, JSON.stringify({
          v: TN.Config.SCHEMA_VERSION,
          rp: this.rp,
          research: this.research,
          unlocked: this.unlocked,
          records: this.records,
          options: this.options
        }));
      } catch (e) {
        console.warn('[TN] no se pudo guardar la progresion permanente', e);
      }
    }

    reset() {
      this.rp = 0;
      this.research = {};
      this.unlocked = {};
      this.records = Object.assign({}, DEFAULTS.records);
      this.save();
    }
  }

  Progression.RESEARCH = RESEARCH;
  Progression.DEFAULTS = DEFAULTS;
  return Progression;
})();
