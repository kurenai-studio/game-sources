/* ==========================================================================
   30 NOCHES - projectiles.js
   Proyectiles (balas, flechas, bombas) con colisiones y vida finita.
   ========================================================================== */
window.TN = window.TN || {};

TN.Projectiles = (function () {
  const U = TN.Utils;

  class ProjectileManager {
    constructor() {
      this.list = [];
    }

    spawn(opts) {
      const p = {
        id: U.uid('pr'),
        x: opts.x, y: opts.y,
        vx: opts.vx, vy: opts.vy,
        speed: opts.speed || 400,
        damage: opts.damage || 10,
        life: opts.life || 2.2,
        color: opts.color || '#e8e2c8',
        size: opts.size || 3,
        pierce: opts.pierce || 1,
        knockback: opts.knockback || 60,
        effect: opts.effect || null,
        crit: !!opts.crit,
        blastRadius: opts.blastRadius || 0,
        kind: opts.kind || 'bullet',
        hit: {},
        friendly: opts.friendly !== false,
        owner: opts.owner || null,
        spin: 0,
        // El proyectil no choca con el mundo en su primer tramo: si no,
        // naciendo pegado a una pared o a una torreta se destruiria al instante.
        spawnX: opts.x, spawnY: opts.y,
        grace: 0.05
      };
      this.list.push(p);
      return p;
    }

    update(dt, game) {
      for (let i = this.list.length - 1; i >= 0; i--) {
        const p = this.list[i];
        p.life -= dt;

        if (p.kind === 'grenade') {
          // Bomba: rebota lightly y explota al terminar o al chocar
          const nx = p.x + p.vx * dt, ny = p.y + p.vy * dt;
          p.spin += dt * 9;
          if (game.world.nearby(nx, ny, 8).length > 0 && game.world.navBlockedAt(nx, ny)) {
            p.vx *= -0.35; p.vy *= -0.35;
          } else { p.x = nx; p.y = ny; }
          p.vx *= Math.pow(0.55, dt); p.vy *= Math.pow(0.55, dt);
          if (p.life <= 0) { this._explode(p, game); this.list.splice(i, 1); continue; }
          continue;
        }

        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.spin += dt * 12;
        if (p.grace > 0) p.grace -= dt;

        if (p.life <= 0 || p.x < 0 || p.y < 0 || p.x > game.world.width || p.y > game.world.height) {
          this.list.splice(i, 1);
          continue;
        }
        // Impacto con obstaculos solidos (se ignora el primer tramo)
        if (p.grace <= 0 && game.world.navBlockedAt(p.x, p.y)) {
          game.particles.burst(p.x, p.y, 5, { color: '#b9b2a0', speed: 80, life: 0.25 });
          this.list.splice(i, 1);
          continue;
        }
        // Impacto con enemigos
        if (p.friendly) {
          const enemies = game.enemies.list;
          let consumed = false;
          for (let e = 0; e < enemies.length; e++) {
            const en = enemies[e];
            if (en.dead) continue;
            if (p.hit[en.id]) continue;
            if (U.dist2(p.x, p.y, en.x, en.y) <= (en.r + p.size) * (en.r + p.size)) {
              p.hit[en.id] = 1;
              TN.Combat.damageEnemy(game, en, p.damage, {
                knockback: p.knockback, dirX: p.vx, dirY: p.vy, effect: p.effect,
                crit: p.crit, source: 'projectile'
              });
              game.particles.burst(p.x, p.y, 7, { color: p.color, speed: 110, life: 0.28, shape: 'spark' });
              if (p.pierce-- <= 0) { consumed = true; break; }
            }
          }
          if (consumed) { this.list.splice(i, 1); continue; }
        } else {
          // Proyectil enemigo contra jugador y generador
          const pl = game.player;
          if (!pl.dead && U.dist2(p.x, p.y, pl.x, pl.y) <= (pl.r + p.size) * (pl.r + p.size)) {
            TN.Combat.damagePlayer(game, p.damage, 'enemy');
            game.particles.burst(p.x, p.y, 7, { color: '#ff6b6b', speed: 110, life: 0.28 });
            this.list.splice(i, 1);
            continue;
          }
          const gen = game.generator;
          if (gen && U.dist2(p.x, p.y, gen.x, gen.y) <= (40 + p.size) * (40 + p.size)) {
            TN.Combat.damageGenerator(game, p.damage);
            game.particles.burst(p.x, p.y, 7, { color: '#ffb46b', speed: 110, life: 0.28 });
            this.list.splice(i, 1);
            continue;
          }
        }
      }
    }

    _explode(p, game) {
      TN.Combat.explode(game, p.x, p.y, p.blastRadius, p.damage, p.color);
      game.audio.play('explode');
      game.camera.addShake(9);
    }

    draw(ctx, cam) {
      const b = cam.bounds(30);
      ctx.save();
      for (const p of this.list) {
        if (p.x < b.x0 || p.x > b.x1 || p.y < b.y0 || p.y > b.y1) continue;
        if (p.kind === 'grenade') {
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.spin);
          ctx.fillStyle = '#4a4438';
          ctx.fillRect(-4, -5, 8, 10);
          ctx.fillStyle = '#ff8a5c';
          ctx.fillRect(-2, -7, 4, 3);
          ctx.restore();
          continue;
        }
        const ang = Math.atan2(p.vy, p.vx);
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(ang);
        ctx.fillStyle = p.color;
        if (p.kind === 'arrow') {
          ctx.fillRect(-9, -1, 14, 2);
          ctx.fillStyle = '#cbbfa0';
          ctx.fillRect(4, -1.5, 4, 3);
        } else {
          ctx.fillRect(-6, -1.2, 12, 2.4);
        }
        ctx.restore();
        ctx.globalAlpha = 0.35;
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size * 1.6, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;
      }
      ctx.restore();
    }

    clear() { this.list.length = 0; }

    serialize() {
      return this.list.filter(p => p.kind !== 'grenade').map(p => ({
        x: p.x, y: p.y, vx: p.vx, vy: p.vy, d: p.damage,
        c: p.color, k: p.kind, l: p.life
      }));
    }
  }

  const Projectiles = { Manager: ProjectileManager };
  Projectiles.Manager = ProjectileManager;
  return Projectiles;
})();
