/* ==========================================================================
   30 NOCHES - player.js
   Estado y comportamiento del protagonista.
   ========================================================================== */
window.TN = window.TN || {};

TN.Player = (function () {
  const U = TN.Utils;
  const CFG = TN.Config;

  class Player {
    constructor(game, x, y) {
      this.game = game;
      this.x = x; this.y = y;
      this.r = CFG.PLAYER.radius;
      this.maxHp = CFG.PLAYER.maxHp;
      this.hp = this.maxHp;
      this.vx = 0; this.vy = 0;
      this.speed = CFG.PLAYER.speed;
      this.aimAngle = -Math.PI / 2;
      this.facing = -Math.PI / 2;
      this.attackCd = 0;
      this.invuln = 0;
      this.hurtFlash = 0;
      this.attackAnim = 0;
      this.attackDir = 0;
      this.walkPhase = 0;
      this.moving = false;
      this.dead = false;
      this.deathTimer = 0;
      this.flashlightOn = false;
      this.flashlightBattery = CFG.FLASHLIGHT.batteryMax;
      this.harvestTimer = 0;
      this.interactTarget = null;
      this.useFlashlight = false;
    }

    reset(x, y) {
      this.x = x; this.y = y;
      this.hp = this.maxHp;
      this.vx = 0; this.vy = 0;
      this.dead = false;
      this.invuln = 0;
      this.hurtFlash = 0;
      this.flashlightOn = false;
      this.flashlightBattery = CFG.FLASHLIGHT.batteryMax;
    }

    update(dt, game) {
      if (this.dead) { this.deathTimer += dt; return; }

      if (this.attackCd > 0) this.attackCd -= dt;
      if (this.invuln > 0) this.invuln -= dt;
      if (this.hurtFlash > 0) this.hurtFlash -= dt;
      if (this.attackAnim > 0) this.attackAnim -= dt;

      const input = game.input;
      const mv = game.canControl() ? input.moveVector() : { x: 0, y: 0 };

      // Velocidad constante respecto al tiempo (nunca ligada a los fotogramas)
      const spd = this.speed * game.upgrades.movementMultiplier();
      const targetVx = mv.x * spd, targetVy = mv.y * spd;
      const accel = 14;
      this.vx += (targetVx - this.vx) * Math.min(1, accel * dt);
      this.vy += (targetVy - this.vy) * Math.min(1, accel * dt);
      if (Math.abs(this.vx) < 1) this.vx = 0;
      if (Math.abs(this.vy) < 1) this.vy = 0;

      this.moving = (mv.x !== 0 || mv.y !== 0);

      // Desplazamiento con subpasos para no atravesar obstaculos
      let nx = this.x + this.vx * dt;
      let ny = this.y + this.vy * dt;
      const stepLen = Math.hypot(this.vx, this.vy) * dt;
      if (stepLen > this.r * 0.6) {
        const steps = Math.ceil(stepLen / (this.r * 0.6));
        for (let i = 0; i < steps; i++) {
          const sx = this.x + this.vx * dt / steps;
          const sy = this.y + this.vy * dt / steps;
          const res = game.world.resolve(sx, sy, this.r, { ignorePassable: true });
          this.x = res.x; this.y = res.y;
        }
      } else {
        const res = game.world.resolve(nx, ny, this.r, { ignorePassable: true });
        this.x = res.x; this.y = res.y;
      }

      // El pantano ralentiza
      if (game.world.isSwamp(this.x, this.y)) {
        this.x -= this.vx * dt * 0.4;
        this.y -= this.vy * dt * 0.4;
      }

      if (this.moving) {
        this.walkPhase += dt * 9;
        this.facing = Math.atan2(this.vy, this.vx);
      }

      // Apuntado con el raton
      const m = game.camera.screenToWorld(input.mouse.x, input.mouse.y);
      this.aimAngle = U.angleTo(this.x, this.y, m.x, m.y);

      // Ataque
      if (game.canControl() && input.mouse.down && this.attackCd <= 0) {
        this.attack(game);
      }

      // Linterna
      if (this.flashlightOn) {
        const drain = CFG.FLASHLIGHT.drainPerSecond * game.upgrades.flashlightDrainMultiplier();
        this.flashlightBattery = Math.max(0, this.flashlightBattery - drain * dt);
        if (this.flashlightBattery <= 0) {
          this.flashlightOn = false;
          game.ui.toast('La linterna se ha quedado sin bateria', 'warn');
        }
      }
    }

    attack(game) {
      const w = TN.Weapons.stats(game.inventory.equipped, game);
      this.attackCd = w.cooldown;
      if (w.type === 'melee') {
        TN.Combat.meleeAttack(game);
        return;
      }
      // Proyectiles
      if (w.ammo) {
        if (!game.inventory.consumeAmmo(w.ammo.id, 1)) {
          game.ui.toast('Sin ' + w.ammo.name.toLowerCase() + ': fabrica mas', 'warn');
          game.audio.play('error');
          this.attackCd = 0.6;
          return;
        }
      }
      const spread = (Math.random() - 0.5) * 0.07;
      const ang = this.aimAngle + spread;
      const isThrown = w.type === 'thrown';
      // El critico tambien afecta a los proyectiles, no solo al cuerpo a cuerpo.
      const isCrit = !!(game.upgrades && game.upgrades.rollCrit());
      const dmg = isCrit ? Math.round(w.damage * 2) : w.damage;
      game.projectiles.spawn({
        x: this.x + Math.cos(this.aimAngle) * 14,
        y: this.y + Math.sin(this.aimAngle) * 14,
        vx: Math.cos(ang) * w.speed,
        vy: Math.sin(ang) * w.speed,
        speed: w.speed,
        damage: dmg,
        crit: isCrit,
        color: w.color,
        size: w.type === 'thrown' ? 5 : 3,
        kind: isThrown ? 'grenade' : (w.id === 'bow' ? 'arrow' : 'bullet'),
        friendly: true,
        life: isThrown ? 1.6 : 1.6,
        blastRadius: w.blastRadius || 0,
        pierce: w.pierce || 1,
        knockback: w.knockback || 60
      });
      this.attackAnim = 0.16;
      game.audio.play(isThrown ? 'swing' : (w.id === 'bow' ? 'arrow' : 'shoot'));
      game.camera.addShake(w.type === 'ranged' ? 1.5 : 0.5);
    }

    toggleFlashlight(game) {
      if (!game.inventory.hasItem('flashlight')) {
        game.ui.toast('No tienes linterna (fabricala con C)', 'warn');
        return;
      }
      if (!this.flashlightOn && this.flashlightBattery <= 0) {
        game.ui.toast('Bateria agotada: recarga en el banco de trabajo', 'warn');
        return;
      }
      this.flashlightOn = !this.flashlightOn;
      game.audio.play('ui');
      game.ui.toast(this.flashlightOn ? 'Linterna encendida (te podran ver)' : 'Linterna apagada', 'info');
    }

    /* --- Dibujado -------------------------------------------------------- */
    draw(ctx, game) {
      const r = this.r;
      ctx.save();
      ctx.translate(this.x, this.y);

      // Sombra
      ctx.globalAlpha = 0.35;
      ctx.fillStyle = '#000';
      ctx.beginPath();
      ctx.ellipse(0, r * 0.75, r * 0.95, r * 0.4, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 1;

      if (this.dead) {
        ctx.rotate(Math.PI * 0.4);
        ctx.fillStyle = '#5a3b3b';
        ctx.beginPath();
        ctx.ellipse(0, 0, r * 1.1, r * 0.6, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        return;
      }

      const bob = this.moving ? Math.sin(this.walkPhase) * 1.6 : Math.sin(performance.now() / 600) * 0.6;
      ctx.translate(0, bob);

      // Parpadeo de invulnerabilidad
      if (this.invuln > 0 && Math.floor(this.invuln * 20) % 2 === 0) {
        ctx.globalAlpha = 0.45;
      }

      const hurt = this.hurtFlash > 0;

      // Cuerpo (giro hacia el raton)
      ctx.save();
      ctx.rotate(this.aimAngle);
      // Piernas
      ctx.strokeStyle = '#2c2f38';
      ctx.lineWidth = 4;
      ctx.lineCap = 'round';
      const step = this.moving ? Math.sin(this.walkPhase) * 4 : 0;
      ctx.beginPath();
      ctx.moveTo(-2, -4); ctx.lineTo(-6 + step, -8);
      ctx.moveTo(-2, 4); ctx.lineTo(-6 - step, 8);
      ctx.stroke();
      // Torso
      ctx.fillStyle = hurt ? '#ff6b6b' : '#4a5568';
      ctx.beginPath();
      ctx.ellipse(0, 0, r * 0.85, r * 0.7, 0, 0, Math.PI * 2);
      ctx.fill();
      // Chaleco
      ctx.fillStyle = hurt ? '#ffaaaa' : '#6b5138';
      ctx.beginPath();
      ctx.ellipse(1, 0, r * 0.62, r * 0.52, 0, 0, Math.PI * 2);
      ctx.fill();
      // Brazo + arma
      const w = TN.Weapons.get(game.inventory.equipped);
      const swing = this.attackAnim > 0 ? (0.22 - this.attackAnim) / 0.22 : 0;
      const armAngle = -0.25 + swing * 1.1;
      ctx.save();
      ctx.rotate(armAngle);
      ctx.strokeStyle = hurt ? '#ff9a9a' : '#c2a07c';
      ctx.lineWidth = 3.4;
      ctx.beginPath();
      ctx.moveTo(2, -3); ctx.lineTo(r * 1.25, -3);
      ctx.stroke();
      // Arma
      ctx.fillStyle = w.color || '#aaa';
      if (w.type === 'melee') {
        ctx.fillRect(r * 1.1, -4, r * 1.5, 4);
      } else if (w.type === 'thrown') {
        ctx.beginPath(); ctx.arc(r * 1.4, -3, 4.5, 0, 6.3); ctx.fill();
      } else {
        ctx.fillRect(r * 1.0, -3.2, r * 1.7, 3.2);
      }
      ctx.restore();
      ctx.restore();

      // Cabeza
      ctx.fillStyle = hurt ? '#ffd0d0' : '#d8b48c';
      ctx.beginPath();
      ctx.arc(r * 0.55, 0, r * 0.5, 0, Math.PI * 2);
      ctx.fill();
      // Casco
      ctx.fillStyle = hurt ? '#ffe0e0' : '#3b4a5a';
      ctx.beginPath();
      ctx.arc(r * 0.55, 0, r * 0.52, Math.PI * 0.55, Math.PI * 1.45);
      ctx.fill();
      // Ojos
      ctx.fillStyle = '#20242c';
      ctx.beginPath(); ctx.arc(r * 0.82, -r * 0.18, 1.3, 0, 6.3); ctx.fill();
      ctx.beginPath(); ctx.arc(r * 0.82, r * 0.18, 1.3, 0, 6.3); ctx.fill();
      // Contorno claro para destacar sobre el bosque
      ctx.strokeStyle = 'rgba(220,235,210,0.35)';
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.arc(r * 0.55, 0, r * 0.52, 0, Math.PI * 2);
      ctx.stroke();

      ctx.globalAlpha = 1;

      // Indicador de linterna
      if (this.flashlightOn) {
        ctx.fillStyle = '#ffe6a8';
        ctx.beginPath(); ctx.arc(r * 0.9, r * 0.75, 2.2, 0, 6.3); ctx.fill();
      }

      ctx.restore();

      // Anillo de alcance del arma en modo construccion? no: anillo de luz tenue
      if (game.debugShowHitbox) {
        ctx.strokeStyle = 'rgba(255,80,80,0.5)';
        ctx.lineWidth = 1;
        ctx.beginPath(); ctx.arc(this.x, this.y, this.r, 0, 6.3); ctx.stroke();
      }
    }

    serialize() {
      return {
        x: this.x, y: this.y, hp: this.hp, maxHp: this.maxHp,
        flashlightOn: this.flashlightOn, flashlightBattery: this.flashlightBattery
      };
    }

    restore(data) {
      if (!data) return;
      this.x = data.x; this.y = data.y;
      this.maxHp = data.maxHp || this.maxHp;
      this.hp = Math.min(data.hp, this.maxHp);
      this.flashlightOn = !!data.flashlightOn;
      this.flashlightBattery = data.flashlightBattery === undefined ? CFG.FLASHLIGHT.batteryMax : data.flashlightBattery;
    }
  }

  return Player;
})();
