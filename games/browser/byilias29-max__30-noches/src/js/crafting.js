/* ==========================================================================
   30 NOCHES - crafting.js
   Recetas data-driven y logica de fabricacion.
   ========================================================================== */
window.TN = window.TN || {};

TN.Crafting = (function () {
  const U = TN.Utils;

  /* Requisitos: bench = banco de trabajo construido, forge = horno construido. */
  const RECIPES = [
    {
      id: 'axe', name: 'Hacha de piedra', cost: { wood: 5, stone: 2 }, type: 'weapon',
      result: { weapon: 'axe' }, tier: 0,
      desc: 'Mejora el cuerpo a cuerpo: mas daño y mas alcance.'
    },
    {
      id: 'spear', name: 'Lanza', cost: { wood: 4, stone: 2 }, type: 'weapon',
      result: { weapon: 'spear' }, tier: 0,
      desc: 'Alcance largo y atraviesa a dos enemigos.'
    },
    {
      id: 'medkit', name: 'Medicina', cost: { herbs: 2 }, type: 'consumable',
      result: { item: 'medkit' }, tier: 0, stack: 5,
      desc: 'Restaura 45 puntos de vida.'
    },
    {
      id: 'repairkit', name: 'Kit de reparacion', cost: { scrap: 3, wood: 2 }, type: 'consumable',
      result: { item: 'repairkit' }, tier: 0, stack: 5,
      desc: 'Repara el generador o una estructura en 120 puntos.'
    },
    {
      id: 'flashlight', name: 'Linterna', cost: { scrap: 4, wood: 2 }, type: 'gear',
      result: { item: 'flashlight' }, tier: 0, stack: 1,
      desc: 'Ilumina el entorno. Las criaturas con sensibilidad a la luz la detectan.'
    },
    {
      id: 'lamp', name: 'Lampara', cost: { wood: 6, scrap: 3 }, type: 'building',
      result: { building: 'lamp' }, tier: 0,
      desc: 'Ilumina la base. Atrae a los cazadores de luz.'
    },
    {
      id: 'bow', name: 'Arco', cost: { wood: 4, scrap: 3 }, type: 'weapon',
      result: { weapon: 'bow' }, tier: 1, req: { bench: true }, unlock: 'unlock_bow',
      desc: 'Ataque a distancia silencioso. Necesitas flechas.'
    },
    {
      id: 'arrows', name: 'Flechas', cost: { wood: 2, stone: 1 }, type: 'ammo',
      result: { ammo: 'arrow', amount: 6 }, tier: 1, req: { bench: true }, unlock: 'unlock_bow',
      desc: 'Municion para el arco.'
    },
    {
      id: 'pistol', name: 'Pistola improvisada', cost: { scrap: 8, stone: 3 }, type: 'weapon',
      result: { weapon: 'pistol' }, tier: 1, req: { bench: true }, unlock: 'unlock_pistol',
      desc: 'Disparo rapido. Consume municion de chatarra.'
    },
    {
      id: 'scrapAmmo', name: 'Municion de chatarra', cost: { scrap: 2 }, type: 'ammo',
      result: { ammo: 'scrapAmmo', amount: 12 }, tier: 1, req: { bench: true }, unlock: 'unlock_pistol',
      desc: 'Municion para la pistola.'
    },
    {
      id: 'bench', name: 'Banco de trabajo', cost: { wood: 8, scrap: 4 }, type: 'building',
      result: { building: 'bench' }, tier: 1,
      desc: 'Desbloquea recetas avanzadas y permite recargar torretas.'
    },
    {
      id: 'door', name: 'Puerta', cost: { wood: 8 }, type: 'building',
      result: { building: 'door' }, tier: 1,
      desc: 'Controla un paso. Tu puedes abrirla con E; las criaturas tienen que romperla.'
    },
    {
      id: 'turret', name: 'Torreta', cost: { wood: 10, scrap: 8 }, type: 'building',
      result: { building: 'turret' }, tier: 1,
      desc: 'Dispara automaticamente a los enemigos. Recarga en el banco de trabajo.'
    },
    {
      id: 'forge', name: 'Horno', cost: { wood: 15, stone: 10, scrap: 8 }, type: 'building',
      result: { building: 'forge' }, tier: 2, req: { bench: true },
      desc: 'Desbloquea recetas de alto nivel.'
    },
    {
      id: 'baton', name: 'Baston electrico', cost: { scrap: 10, wood: 3 }, type: 'weapon',
      result: { weapon: 'baton' }, tier: 2, req: { forge: true }, unlock: 'unlock_baton',
      desc: 'Golpe en area que aturde a las criaturas pequenas.'
    },
    {
      id: 'rifle', name: 'Rifle de pernos', cost: { scrap: 18, stone: 6 }, type: 'weapon',
      result: { weapon: 'rifle' }, tier: 2, req: { forge: true }, unlock: 'unlock_baton',
      desc: 'Atraviesa varias lineas de criaturas.'
    },
    {
      id: 'rifleAmmo', name: 'Municion de perno', cost: { scrap: 4, stone: 1 }, type: 'ammo',
      result: { ammo: 'rifleAmmo', amount: 10 }, tier: 2, req: { forge: true }, unlock: 'unlock_baton',
      desc: 'Municion para el rifle.'
    },
    {
      id: 'grenade', name: 'Bomba', cost: { scrap: 5, wood: 1 }, type: 'consumable',
      result: { item: 'grenade' }, tier: 2, req: { forge: true }, stack: 6,
      desc: 'Se usa con el acceso rapido: explosion de area.'
    }
  ];

  const BY_ID = {};
  RECIPES.forEach(r => { BY_ID[r.id] = r; });

  function get(id) { return BY_ID[id] || null; }

  function all() { return RECIPES; }

  /* Requisitos de instalacion cumplidos?
     bench/forge exigen la estructura CONSTRUIDA en la base (no solo haber
     fabricado la receta): hasStructure() mira this.list, has() solo mira
     el desbloqueo de la receta. */
  function checkRequirements(recipe, game) {
    if (recipe.req) {
      if (recipe.req.bench && !game.buildings.hasStructure('bench')) {
        return { ok: false, reason: 'Necesitas un banco de trabajo en la base' };
      }
      if (recipe.req.forge && !game.buildings.hasStructure('forge')) {
        return { ok: false, reason: 'Necesitas un horno en la base' };
      }
    }
    if (recipe.unlock && !game.progression.isUnlocked(recipe.unlock)) {
      const r = TN.Progression.RESEARCH[recipe.unlock];
      return { ok: false, reason: 'Requiere la investigacion "' + (r ? r.name : recipe.unlock) + '"' };
    }
    return { ok: true };
  }

  /* Coste efectivo con descuentos (mejora temporal + investigacion). */
  function effectiveCost(recipe, game) {
    const cost = {};
    const disc = game.getCostMultiplier();
    for (const k in recipe.cost) {
      const v = recipe.cost[k] * disc;
      cost[k] = Math.max(1, Math.round(v));
    }
    return cost;
  }

  function canCraft(recipe, game) {
    if (!recipe) return { ok: false, reason: 'Receta desconocida' };
    const req = checkRequirements(recipe, game);
    if (!req.ok) return req;
    const cost = effectiveCost(recipe, game);
    if (!game.inventory.canAfford(cost)) {
      const miss = game.inventory.missingFor(cost);
      let txt = 'Faltan materiales:';
      for (const k in miss) txt += ' ' + (TN.Inventory.RES_NAMES[k] || k) + ' x' + miss[k] + '.';
      return { ok: false, reason: txt, cost: cost };
    }
    return { ok: true, cost: cost };
  }

  /* Fabrica un objeto. Nunca cobra si la operacion no es valida. */
  function craft(recipeId, game) {
    const recipe = get(recipeId);
    const check = canCraft(recipe, game);
    if (!check.ok) {
      game.ui.toast(check.reason, 'error');
      game.audio.play('error');
      return false;
    }
    const cost = check.cost;
    if (!game.inventory.spend(cost)) {
      game.ui.toast('No se pudieron descontar los materiales.', 'error');
      return false;
    }
    const r = recipe.result || {};
    if (r.weapon) {
      game.inventory.addWeapon(r.weapon);
      game.inventory.equip(r.weapon);
      game.ui.toast('Fabricado: ' + TN.Weapons.get(r.weapon).name, 'good');
    }
    if (r.item) {
      game.inventory.addItem(r.item, 1);
      game.ui.toast('Fabricado: ' + r.item, 'good');
    }
    if (r.ammo) {
      const amount = Math.round((r.amount || 1) * game.getAmmoMultiplier());
      game.inventory.addAmmo(r.ammo, amount);
      game.ui.toast('+' + amount + ' ' + (TN.Weapons.AMMO_NAMES[r.ammo] || r.ammo), 'good');
    }
    if (r.building) {
      game.buildings.unlockBuildable(r.building);
      game.ui.toast('Ahora puedes construir: ' + r.building, 'good');
    }
    game.audio.play('craft');
    game.particles.burst(game.player.x, game.player.y, 12, { color: '#ffd27a', speed: 90, life: 0.5 });
    game.ui.refreshInventory();
    game.save.markDirty();
    return true;
  }

  return {
    RECIPES: RECIPES,
    get: get,
    all: all,
    canCraft: canCraft,
    effectiveCost: effectiveCost,
    checkRequirements: checkRequirements,
    craft: craft
  };
})();
