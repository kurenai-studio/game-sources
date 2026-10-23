/* ==========================================================================
   30 NOCHES - inventory.js
   Recursos, objetos, municion, armas y barra de acceso rapido.
   ========================================================================== */
window.TN = window.TN || {};

TN.Inventory = (function () {
  const RES_KEYS = ['wood', 'stone', 'scrap', 'herbs'];

  const RES_NAMES = { wood: 'Madera', stone: 'Piedra', scrap: 'Chatarra', herbs: 'Hierbas' };
  const RES_ICONS = { wood: '🪵', stone: '🪨', scrap: '⚙️', herbs: '🌿' };

  class Inventory {
    constructor() {
      this.resources = { wood: 0, stone: 0, scrap: 0, herbs: 0 };
      this.items = {};                 // consumibles y equipables por id
      this.ammo = { arrow: 0, scrapAmmo: 0, rifleAmmo: 0 };
      this.weapons = [TN.Config.PLAYER.startWeapon];
      this.equipped = TN.Config.PLAYER.startWeapon;
      this.hotbar = ['medkit', 'repairkit', 'grenade', 'flashlight'];
      this.collected = { wood: 0, stone: 0, scrap: 0, herbs: 0 };
    }

    /* --- recursos ------------------------------------------------------- */
    addResource(kind, amount) {
      if (!(amount > 0)) return 0;
      this.resources[kind] = (this.resources[kind] || 0) + amount;
      this.collected[kind] = (this.collected[kind] || 0) + amount;
      return amount;
    }

    canAfford(cost) {
      if (!cost) return true;
      for (const k in cost) {
        if ((this.resources[k] || 0) < cost[k]) return false;
      }
      return true;
    }

    missingFor(cost) {
      const miss = {};
      if (!cost) return miss;
      for (const k in cost) {
        const need = cost[k], have = this.resources[k] || 0;
        if (have < need) miss[k] = need - have;
      }
      return miss;
    }

    spend(cost) {
      if (!this.canAfford(cost)) return false;
      for (const k in cost) this.resources[k] -= cost[k];
      return true;
    }

    /* --- objetos -------------------------------------------------------- */
    addItem(id, n) {
      n = n || 1;
      this.items[id] = (this.items[id] || 0) + n;
      return this.items[id];
    }

    removeItem(id, n) {
      n = n || 1;
      if ((this.items[id] || 0) < n) return false;
      this.items[id] -= n;
      if (this.items[id] <= 0) delete this.items[id];
      return true;
    }

    hasItem(id, n) { return (this.items[id] || 0) >= (n || 1); }
    countItem(id) { return this.items[id] || 0; }

    /* --- municion ------------------------------------------------------- */
    addAmmo(id, n) {
      this.ammo[id] = (this.ammo[id] || 0) + n;
      return this.ammo[id];
    }
    ammoCount(id) { return this.ammo[id] || 0; }
    consumeAmmo(id, n) {
      if ((this.ammo[id] || 0) < n) return false;
      this.ammo[id] -= n;
      return true;
    }

    /* --- armas ---------------------------------------------------------- */
    addWeapon(id) {
      if (this.weapons.indexOf(id) === -1) this.weapons.push(id);
    }
    hasWeapon(id) { return this.weapons.indexOf(id) !== -1; }
    equip(id) {
      if (!this.hasWeapon(id)) return false;
      this.equipped = id;
      return true;
    }
    equipBest() {
      const order = ['pipe', 'axe', 'spear', 'bow', 'pistol', 'baton', 'rifle', 'grenade'];
      let best = 'pipe';
      for (const w of order) if (this.hasWeapon(w)) best = w;
      this.equipped = best;
    }

    /* --- serializacion -------------------------------------------------- */
    serialize() {
      return {
        resources: Object.assign({}, this.resources),
        items: Object.assign({}, this.items),
        ammo: Object.assign({}, this.ammo),
        weapons: this.weapons.slice(),
        equipped: this.equipped,
        hotbar: this.hotbar.slice(),
        collected: Object.assign({}, this.collected)
      };
    }

    restore(data) {
      if (!data) return;
      this.resources = Object.assign({ wood: 0, stone: 0, scrap: 0, herbs: 0 }, data.resources || {});
      this.items = Object.assign({}, data.items || {});
      this.ammo = Object.assign({ arrow: 0, scrapAmmo: 0, rifleAmmo: 0 }, data.ammo || {});
      this.weapons = Array.isArray(data.weapons) && data.weapons.length ? data.weapons.slice() : ['pipe'];
      this.equipped = data.equipped || 'pipe';
      this.hotbar = Array.isArray(data.hotbar) ? data.hotbar.slice() : ['medkit', 'repairkit', 'grenade', 'flashlight'];
      this.collected = Object.assign({ wood: 0, stone: 0, scrap: 0, herbs: 0 }, data.collected || {});
      if (!this.hasWeapon(this.equipped)) this.equipped = this.weapons[0];
    }
  }

  Inventory.RES_NAMES = RES_NAMES;
  Inventory.RES_ICONS = RES_ICONS;
  Inventory.RES_KEYS = RES_KEYS;
  return Inventory;
})();
