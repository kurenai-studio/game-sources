/* ==========================================================================
   30 NOCHES - combat.js
   Dano, impactos, muerte y recompensas. La logica de vida vive aqui;
   los efectos visuales se delegan en particles/floating texts.
   ========================================================================== */
window.TN = window.TN || {};

TN.Combat = (function () {
  const U = TN.Utils;

  function floatText(game, x, y, text, color, size) {
    game.floaters.push({
      x: x, y: y, text: text, color: color || '#fff',
      life: 0.85, maxLife: 0.85, size: size || 12, vy: -34
    });
  }

  /* --- Ataque cuerpo a cuerpo ------------------------------------------- */
  function meleeAttack(game) {
    const pl = game.player;
    const w = TN.Weapons.stats(pl.inventory.equipped, game);
    let dir = pl.aimAngle;
    const halfArc = (w.arc || 1) / 2;
    const reach = w.range + pl.r;

    // Ayuda de punteria: si hay un enemigo claro dentro de un cono amplio,
    // el golpe se orienta hacia el. Evita fallar por un pixel de angulo.
    const enemies = game.enemies.list;
    let bestTarget = null, bestScore = Infinity;
    for (const en of enemies) {
      if (en.dead) continue;
      const dx = en.x - pl.x, dy = en.y - pl.y;
      const d = Math.hypot(dx, dy);
      if (d > reach + en.r) continue;
      const ang = Math.atan2(dy, dx);
      const diff = Math.abs(((ang - dir + Math.PI * 3) % (Math.PI * 2)) - Math.PI);
      if (diff > 1.3) continue;
      const score = diff * 60 + d;
      if (score < bestScore) { bestScore = score; bestTarget = en; }
    }
    if (bestTarget) dir = U.angleTo(pl.x, pl.y, bestTarget.x, bestTarget.y);

    game.audio.play('swing');
    pl.attackAnim = 0.22;
    pl.attackDir = dir;

    let hits = 0;
    for (const en of enemies) {
      if (en.dead) continue;
      const dx = en.x - pl.x, dy = en.y - pl.y;
      const d = Math.hypot(dx, dy);
      if (d > reach + en.r) continue;
      const ang = Math.atan2(dy, dx);
      const diff = Math.abs(((ang - dir + Math.PI * 3) % (Math.PI * 2)) - Math.PI);
      if (diff > halfArc) continue;
      if (hits >= (w.pierce || 1)) break;
      const isCrit = game.upgrades && game.upgrades.rollCrit();
      const dmg = Math.round(w.damage * (isCrit ? 2 : 1));
      damageEnemy(game, en, dmg, {
        knockback: w.knockback, dirX: dx, dirY: dy,
        effect: w.effect, source: 'melee', crit: isCrit
      });
      hits++;
    }
    // Golpea tambien estructuras (romper con golpes)
    const buildings = game.buildings.list;
    for (const b of buildings) {
      if (b.dead || b.hp <= 0) continue;
      const dx = b.x - pl.x, dy = b.y - pl.y;
      const d = Math.hypot(dx, dy);
      if (d > reach + 26) continue;
      const ang = Math.atan2(dy, dx);
      const diff = Math.abs(((ang - dir + Math.PI * 3) % (Math.PI * 2)) - Math.PI);
      if (diff > halfArc) continue;
      damageBuilding(game, b, w.damage * 0.8);
      break;
    }
    // Arco visual del golpe
    game.effects.push({ kind: 'slash', x: pl.x, y: pl.y, angle: dir, arc: w.arc || 1, radius: reach, life: 0.18, maxLife: 0.18, color: w.color });
    game.camera.addShake(1.6);
  }

  /* --- Dano a enemigos --------------------------------------------------- */
  function damageEnemy(game, en, amount, opts) {
    if (!en || en.dead) return 0;
    opts = opts || {};
    const final = Math.max(1, Math.round(amount));
    en.hp -= final;
    en.hitFlash = 0.14;
    en.aggro = true;
    en.lastHitBy = 'player';

    if (opts.knockback) {
      const dx = opts.dirX || 0, dy = opts.dirY || 0;
      const len = Math.hypot(dx, dy) || 1;
      const mass = en.boss ? 0.18 : (en.r / 12);
      en.kx += (dx / len) * opts.knockback * mass;
      en.ky += (dy / len) * opts.knockback * mass;
    }
    if (opts.effect === 'shock' && !en.boss) {
      en.stun = Math.max(en.stun || 0, 1.1);
    }

    game.particles.burst(en.x, en.y, opts.crit ? 14 : 8, {
      color: opts.crit ? '#ffd166' : '#c0453c',
      speed: opts.crit ? 190 : 130, life: 0.35, shape: 'circle'
    });
    floatText(game, en.x, en.y - en.r - 4, (opts.crit ? '!! ' : '') + final, opts.crit ? '#ffd166' : '#ffe9e4', opts.crit ? 16 : 12);
    if (opts.crit) game.audio.play('crit'); else game.audio.play('hit');
    game.camera.addShake(opts.crit ? 4 : 2);

    if (en.hp <= 0) killEnemy(game, en, opts);
    return final;
  }

  function killEnemy(game, en, opts) {
    if (en.dead) return;
    en.dead = true;
    en.deathTimer = 0.6;
    game.stats.kills++;
    game.audio.play('enemyDie');
    game.particles.burst(en.x, en.y, en.boss ? 60 : 16, {
      color: en.boss ? '#c58bff' : '#7e2f2a', speed: en.boss ? 280 : 160, life: 0.7, shape: 'circle'
    });
    // Recompensas
    const r = en.rewards || { scrap: 1, herbs: 0 };
    const mult = (en.boss ? 6 : (en.isElite ? 3 : 1)) * (1 + (game.progression.get('harvest') || 0) * 0.15);
    if (r.scrap) {
      const amt = Math.max(1, Math.round(r.scrap * mult));
      game.inventory.addResource('scrap', amt);
      floatText(game, en.x + 10, en.y, '+' + amt + ' chatarra', '#ffce6b', 11);
    }
    if (r.herbs) {
      const amt = Math.max(1, Math.round(r.herbs * mult));
      game.inventory.addResource('herbs', amt);
      floatText(game, en.x - 10, en.y, '+' + amt + ' hierbas', '#9ede6a', 11);
    }
    if (en.boss) {
      game.onBossDefeated(en);
    }
    game.ui.refreshInventory();
  }

  /* --- Dano al jugador --------------------------------------------------- */
  function damagePlayer(game, amount, source) {
    const pl = game.player;
    if (!pl || pl.dead) return;
    if (pl.invuln > 0) return;
    if (TN.Config.DEBUG.enabled && TN.Config.DEBUG.godMode) return;

    let dmg = amount * (game.upgrades ? game.upgrades.damageTakenMultiplier() : 1);
    dmg = Math.max(1, Math.round(dmg));
    pl.hp -= dmg;
    pl.invuln = TN.Config.PLAYER.invulnTime;
    pl.hurtFlash = 0.35;
    game.camera.addShake(7);
    game.audio.play('hurt');
    game.particles.burst(pl.x, pl.y, 12, { color: '#ff5c5c', speed: 150, life: 0.45 });
    floatText(game, pl.x, pl.y - 18, '-' + dmg, '#ff8080', 14);
    game.ui.flashDamage();
    if (pl.hp <= 0) {
      pl.hp = 0;
      game.onPlayerDeath(source);
    }
  }

  /* --- Estructuras ------------------------------------------------------- */
  function damageBuilding(game, b, amount) {
    if (!b || b.dead) return;
    b.hp -= amount;
    b.hitFlash = 0.15;
    game.particles.burst(b.x, b.y, 5, { color: '#b08a55', speed: 90, life: 0.3 });
    if (b.hp <= 0) {
      b.hp = 0;
      b.dead = true;
      game.buildings.remove(b);
      game.particles.burst(b.x, b.y, 18, { color: '#8a6a3c', speed: 170, life: 0.55 });
      game.audio.play('build');
      game.ui.toast(b.name + ' destruido', 'warn');
    }
  }

  function damageGenerator(game, amount) {
    const gen = game.generator;
    if (!gen || gen.dead) return;
    gen.hp -= amount;
    gen.hitFlash = 0.2;
    game.particles.burst(gen.x, gen.y, 6, { color: '#ffb46b', speed: 110, life: 0.35 });
    floatText(game, gen.x, gen.y - 26, '-' + Math.round(amount), '#ff9a5c', 12);
    if (gen.hp <= 0) {
      gen.hp = 0;
      game.onGeneratorDestroyed();
    }
  }

  /* --- Explosion --------------------------------------------------------- */
  function explode(game, x, y, radius, damage, color) {
    game.particles.burst(x, y, 34, { color: color || '#ff9a5c', speed: 300, life: 0.6, shape: 'circle', glow: true });
    game.effects.push({ kind: 'blast', x: x, y: y, radius: radius, life: 0.4, maxLife: 0.4, color: color || '#ffb066' });
    for (const en of game.enemies.list) {
      if (en.dead) continue;
      const d = Math.hypot(en.x - x, en.y - y);
      if (d <= radius + en.r) {
        const falloff = 1 - Math.min(1, d / (radius + en.r));
        damageEnemy(game, en, damage * (0.45 + 0.55 * falloff), {
          knockback: 260 * falloff, dirX: en.x - x, dirY: en.y - y, source: 'explosion'
        });
      }
    }
    const pl = game.player;
    if (!pl.dead) {
      const d = Math.hypot(pl.x - x, pl.y - y);
      if (d <= radius + pl.r) {
        damagePlayer(game, damage * 0.35 * (1 - d / (radius + pl.r)), 'explosion');
      }
    }
  }

  return {
    meleeAttack: meleeAttack,
    damageEnemy: damageEnemy,
    killEnemy: killEnemy,
    damagePlayer: damagePlayer,
    damageBuilding: damageBuilding,
    damageGenerator: damageGenerator,
    explode: explode,
    floatText: floatText
  };
})();
