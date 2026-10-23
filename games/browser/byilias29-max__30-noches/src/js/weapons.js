/* ==========================================================================
   30 NOCHES - weapons.js
   Configuracion de armas: estadisticas, tipo de ataque y efectos.
   ========================================================================== */
window.TN = window.TN || {};

TN.Weapons = (function () {
  const WEAPONS = {
    pipe: {
      id: 'pipe', name: 'Palo oxidado', type: 'melee',
      damage: 16, range: 44, cooldown: 0.5, arc: 0.95,
      color: '#a2916f', knockback: 120,
      desc: 'Un palo con un clavo. No es mucho, pero es algo.'
    },
    axe: {
      id: 'axe', name: 'Hacha de piedra', type: 'melee',
      damage: 27, range: 50, cooldown: 0.68, arc: 1.0,
      color: '#c8bfae', knockback: 160,
      desc: 'Hoja de piedra atada con fibra. Corta madera y criaturas.'
    },
    spear: {
      id: 'spear', name: 'Lanza', type: 'melee',
      damage: 33, range: 72, cooldown: 0.82, arc: 0.45,
      color: '#b9a37c', knockback: 210, pierce: 2,
      desc: 'Alcanza largo y atraviesa a mas de un enemigo.'
    },
    baton: {
      id: 'baton', name: 'Baston electrico', type: 'melee',
      damage: 21, range: 48, cooldown: 0.5, arc: 1.35,
      color: '#6fd3ff', knockback: 90, effect: 'shock',
      desc: 'Chatarra y una bateria. Aturde a los enemigos pequenos.'
    },
    bow: {
      id: 'bow', name: 'Arco', type: 'ranged',
      damage: 25, range: 360, cooldown: 0.72, speed: 460,
      ammo: { id: 'arrow', name: 'Flechas', max: 40 },
      color: '#d7c07c', knockback: 60,
      desc: 'Silencioso y barato. Consume flechas.'
    },
    pistol: {
      id: 'pistol', name: 'Pistola improvisada', type: 'ranged',
      damage: 23, range: 340, cooldown: 0.42, speed: 560,
      ammo: { id: 'scrapAmmo', name: 'Municion de chatarra', max: 60 },
      color: '#93a7b4', knockback: 70,
      desc: 'Ruido, pero fiable. Consume municion de chatarra.'
    },
    rifle: {
      id: 'rifle', name: 'Rifle de pernos', type: 'ranged',
      damage: 44, range: 540, cooldown: 1.05, speed: 760,
      ammo: { id: 'rifleAmmo', name: 'Municion de perno', max: 30 },
      color: '#aab3bb', knockback: 150, pierce: 2,
      desc: 'Aguanta varias lineas. Consume municion de perno.'
    },
    grenade: {
      id: 'grenade', name: 'Bomba arrojadiza', type: 'thrown',
      damage: 78, range: 330, cooldown: 1.5, speed: 320,
      blastRadius: 74, color: '#ff8a5c',
      desc: 'Explota al impacto. DanoArea amplio, uso limitado.'
    }
  };

  const AMMO_NAMES = {
    arrow: 'Flechas',
    scrapAmmo: 'Municion de chatarra',
    rifleAmmo: 'Municion de perno'
  };

  function get(id) { return WEAPONS[id] || WEAPONS.pipe; }

  /* Estadisticas efectivas despues de aplicar mejoras temporales. */
  function stats(id, game) {
    const w = get(id);
    const s = {
      id: w.id, name: w.name, type: w.type,
      damage: w.damage, range: w.range, cooldown: w.cooldown,
      arc: w.arc, speed: w.speed, ammo: w.ammo, pierce: w.pierce || 1,
      knockback: w.knockback || 80, effect: w.effect,
      blastRadius: w.blastRadius, color: w.color, desc: w.desc
    };
    if (game && game.upgrades) {
      const m = game.upgrades.attackMultiplier(w.type);
      s.damage = Math.round(s.damage * m);
      if (w.type === 'melee' && game.upgrades.has('reach')) s.range += 8;
    }
    return s;
  }

  return { WEAPONS: WEAPONS, get: get, stats: stats, AMMO_NAMES: AMMO_NAMES };
})();
