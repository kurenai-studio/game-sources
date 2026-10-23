/* ==========================================================================
   30 NOCHES - upgrades.js
   Mejoras temporales de la expedicion (se pierden al terminar la partida).
   ========================================================================== */
window.TN = window.TN || {};

TN.Upgrades = (function () {
  const U = TN.Utils;

  const UPGRADES = {
    dmg_melee: {
      id: 'dmg_melee', name: 'Filo afilado', desc: '+25% de dano cuerpo a cuerpo',
      icon: '🗡'
    },
    dmg_all: {
      id: 'dmg_all', name: 'Municion mejor', desc: '+15% de dano con todas las armas',
      icon: '💥'
    },
    speed: {
      id: 'speed', name: 'Paso ligero', desc: '+12% de velocidad de movimiento',
      icon: '👟'
    },
    harvest: {
      id: 'harvest', name: 'Manos habiles', desc: '+40% de recursos recolectados',
      icon: '🌿'
    },
    maxhp: {
      id: 'maxhp', name: 'Corazon de piedra', desc: '+25 de vida maxima (y la recupera)',
      icon: '❤️'
    },
    armor: {
      id: 'armor', name: 'Piel endurecida', desc: '-20% de dano recibido',
      icon: '🛡'
    },
    structures: {
      id: 'structures', name: 'Buena madera', desc: '+30% de vida en tus estructuras',
      icon: '🪵'
    },
    turret: {
      id: 'turret', name: 'Mantenimiento', desc: '+40% de dano de las torretas',
      icon: '🔫'
    },
    turretRange: {
      id: 'turretRange', name: 'Ojo de tirador', desc: '+25% de alcance de las torretas',
      icon: '🎯'
    },
    trap: {
      id: 'trap', name: 'Puntas afiladas', desc: '+50% de dano de las trampas',
      icon: '🪤'
    },
    heal: {
      id: 'heal', name: 'Primeros auxilios avanzados', desc: 'La medicina cura un 60% mas',
      icon: '💊'
    },
    economy: {
      id: 'economy', name: 'Materiales baratos', desc: '-25% de coste al fabricar y construir',
      icon: '🪙'
    },
    ammo: {
      id: 'ammo', name: 'Cargador extra', desc: '+50% de municion al fabricar',
      icon: '🔩'
    },
    reach: {
      id: 'reach', name: 'Alcance extendido', desc: '+8 de alcance cuerpo a cuerpo',
      icon: '📏'
    },
    light: {
      id: 'light', name: 'Foco potente', desc: 'La linterna dura mas y alumbra mas',
      icon: '🔦'
    },
    crit: {
      id: 'crit', name: 'Instinto letal', desc: '+15% de probabilidad de critico (x2 dano)',
      icon: '⚡'
    }
  };

  const UPGRADE_IDS = Object.keys(UPGRADES);

  class UpgradeManager {
    constructor() {
      this.owned = [];
      this.pending = null;   // ids ofrecidos, esperando eleccion
      this.offerCount = 0;
    }

    has(id) { return this.owned.indexOf(id) !== -1; }

    /* Ofrece tres mejoras aleatorias sin repetir. */
    offer() {
      const pool = UPGRADE_IDS.filter(id => !this.has(id));
      if (!pool.length) { this.pending = null; return null; }
      const shuffled = U.makeRng(Date.now() & 0xffffffff).shuffle(pool);
      this.pending = shuffled.slice(0, Math.min(3, shuffled.length));
      this.offerCount++;
      return this.pending;
    }

    choose(id) {
      if (!this.pending || this.pending.indexOf(id) === -1) return false;
      this.owned.push(id);
      this.pending = null;
      return true;
    }

    clear() { this.owned = []; this.pending = null; }

    /* --- Multiplicadores ------------------------------------------------- */
    attackMultiplier(type) {
      let m = 1;
      if (this.has('dmg_melee') && type === 'melee') m *= 1.25;
      if (this.has('dmg_all')) m *= 1.15;
      return m;
    }
    damageTakenMultiplier() { return this.has('armor') ? 0.8 : 1; }
    harvestMultiplier() { return this.has('harvest') ? 1.4 : 1; }
    structureHpMultiplier() { return this.has('structures') ? 1.3 : 1; }
    turretMultiplier() { return this.has('turret') ? 1.4 : 1; }
    turretRangeMultiplier() { return this.has('turretRange') ? 1.25 : 1; }
    trapMultiplier() { return this.has('trap') ? 1.5 : 1; }
    healMultiplier() { return this.has('heal') ? 1.6 : 1; }
    costMultiplier() { return this.has('economy') ? 0.75 : 1; }
    ammoMultiplier() { return this.has('ammo') ? 1.5 : 1; }
    movementMultiplier() { return this.has('speed') ? 1.12 : 1; }
    flashlightRadiusMultiplier() { return this.has('light') ? 1.35 : 1; }
    flashlightDrainMultiplier() { return this.has('light') ? 0.6 : 1; }
    critChance() { return this.has('crit') ? 0.15 : 0; }
    rollCrit() { return Math.random() < this.critChance(); }

    serialize() { return { owned: this.owned.slice(), pending: this.pending ? this.pending.slice() : null }; }
    restore(data) {
      if (!data) return;
      this.owned = Array.isArray(data.owned) ? data.owned.slice() : [];
      this.pending = Array.isArray(data.pending) ? data.pending.slice() : null;
    }
  }

  const Upgrades = { Manager: UpgradeManager, LIST: UPGRADES, IDS: UPGRADE_IDS };
  Upgrades.LIST = UPGRADES;
  return Upgrades;
})();
