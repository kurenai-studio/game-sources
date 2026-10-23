/* ==========================================================================
   30 NOCHES - buildings.js
   Estructuras: colocacion, validacion, IA de torretas/trampas/lamparas,
   puertas y dano.
   ========================================================================== */
window.TN = window.TN || {};

TN.Buildings = (function () {
  const U = TN.Utils;

  const BUILDINGS = {
    wall: {
      id: 'wall', name: 'Muro de madera', cost: { wood: 5 }, hp: 130,
      w: 32, h: 32, solid: true, tier: 0, unlocked: true,
      desc: 'Bloquea a las criaturas. Se rompe si recibe demasiados golpes.'
    },
    trap: {
      id: 'trap', name: 'Trampa de pinchos', cost: { wood: 4, stone: 2 }, hp: 70,
      w: 32, h: 32, solid: false, tier: 0, unlocked: true,
      desc: 'Daña a las criaturas que la pisan. Cooldown por criatura.'
    },
    lamp: {
      id: 'lamp', name: 'Lampara', cost: { wood: 6, scrap: 3 }, hp: 90,
      w: 26, h: 26, solid: true, tier: 0, unlocked: false,
      desc: 'Ilumina el area. Atrae a los cazadores de luz.'
    },
    door: {
      id: 'door', name: 'Puerta', cost: { wood: 8 }, hp: 160,
      w: 32, h: 32, solid: true, tier: 1, unlocked: false,
      desc: 'Tus adversarios tienen que romperla. Tu la abres con E.'
    },
    bench: {
      id: 'bench', name: 'Banco de trabajo', cost: { wood: 8, scrap: 4 }, hp: 140,
      w: 48, h: 32, solid: true, tier: 1, unlocked: false,
      desc: 'Desbloquea recetas avanzadas, recarga torretas y recarga la linterna.'
    },
    turret: {
      id: 'turret', name: 'Torreta', cost: { wood: 10, scrap: 8 }, hp: 170,
      w: 32, h: 32, solid: true, tier: 1, unlocked: false,
      desc: 'Dispara sola a los enemigos. Recarga con chatarra en el banco.'
    },
    forge: {
      id: 'forge', name: 'Horno', cost: { wood: 15, stone: 10, scrap: 8 }, hp: 220,
      w: 48, h: 40, solid: true, tier: 2, unlocked: false,
      desc: 'Desbloquea recetas de alto nivel.'
    }
  };

  class BuildingManager {
    constructor(world) {
      this.world = world;
      this.list = [];
      this.unlocked = {};
      for (const k in BUILDINGS) if (BUILDINGS[k].unlocked) this.unlocked[k] = true;
      this.turretAmmo = 30;
      this.turretMaxAmmo = 30;
      this.turretRange = 240;
      this.turretDamage = 15;
      this.turretFireCd = 0.8;
      this.trapDamage = 24;
      this.trapCooldown = 1.2;
    }

    has(type) { return !!this.unlocked[type]; }
    unlockBuildable(type) {
      if (!BUILDINGS[type]) return;
      this.unlocked[type] = true;
    }
    countOf(type) {
      let n = 0;
      for (const b of this.list) if (b.type === type && !b.dead) n++;
      return n;
    }
    hasStructure(type) {
      for (const b of this.list) if (b.type === type && !b.dead) return true;
      return false;
    }

    /* --- Validacion de colocacion ---------------------------------------
       opts.fast = true omite la comprobacion cara de accesibilidad
       (se recalcula solo cuando cambia la casilla). */
    validate(game, type, x, y, opts) {
      const def = BUILDINGS[type];
      if (!def) return { ok: false, reason: 'Estructura desconocida' };
      if (!this.unlocked[type]) return { ok: false, reason: 'Construccion bloqueada: fabricala primero.' };

      const hw = def.w / 2, hh = def.h / 2;
      if (x - hw < 8 || y - hh < 8 || x + hw > this.world.width - 8 || y + hh > this.world.height - 8) {
        return { ok: false, reason: 'Fuera del mapa' };
      }
      // Sobre el jugador
      const pl = game.player;
      if (U.circleVsRect(pl.x, pl.y, pl.r + 6, x, y, hw, hh)) {
        return { ok: false, reason: 'No puedes construir sobre ti' };
      }
      // Sobre el generador o la antena
      const gen = game.generator;
      if (U.circleVsRect(gen.x, gen.y, 34, x, y, hw, hh)) {
        return { ok: false, reason: 'No puedes construir sobre el generador' };
      }
      if (U.circleVsRect(game.quests.antenna.x, game.quests.antenna.y, 22, x, y, hw, hh)) {
        return { ok: false, reason: 'No puedes construir sobre la antena' };
      }
      // Choca con obstaculos del mundo
      for (const o of this.world.nearby(x, y, Math.max(hw, hh) + 24)) {
        if (!o.solid) continue;
        if (o.shape === 'circle') {
          if (U.circleVsRect(o.x, o.y, o.r + 2, x, y, hw, hh)) {
            return { ok: false, reason: 'Hay un obstaculo ahi' };
          }
        } else {
          if (U.rectsOverlap({ x: x, y: y, hw: hw, hh: hh }, { x: o.x, y: o.y, hw: o.hw, hh: o.hh })) {
            return { ok: false, reason: 'Hay un obstaculo ahi' };
          }
        }
      }
      // Choca con otras estructuras
      for (const b of this.list) {
        if (b.dead) continue;
        if (U.rectsOverlap({ x: x, y: y, hw: hw, hh: hh }, { x: b.x, y: b.y, hw: b.hw, hh: b.hh })) {
          return { ok: false, reason: 'Ya hay algo construido ahi' };
        }
      }
      // Debe dejar accesible el generador y la antena
      if (!(opts && opts.fast) && !this._reachabilityOk(game, { x: x, y: y, hw: hw, hh: hh })) {
        return { ok: false, reason: 'Bloquearia el acceso a la base' };
      }
      // Materiales
      const cost = this.effectiveCost(type, game);
      if (!game.inventory.canAfford(cost)) {
        const miss = game.inventory.missingFor(cost);
        let txt = 'Faltan materiales:';
        for (const k in miss) txt += ' ' + (TN.Inventory.RES_NAMES[k] || k) + ' x' + miss[k] + '.';
        return { ok: false, reason: txt, cost: cost };
      }
      return { ok: true, cost: cost };
    }

    /* Comprueba (solo) que la colocacion no deja sin acceso a la base. */
    checkAccess(game, type, x, y) {
      const def = BUILDINGS[type];
      if (!def) return false;
      return this._reachabilityOk(game, { x: x, y: y, hw: def.w / 2, hh: def.h / 2 });
    }

    effectiveCost(type, game) {
      const def = BUILDINGS[type];
      const cost = {};
      const disc = game.getCostMultiplier();
      for (const k in def.cost) cost[k] = Math.max(1, Math.round(def.cost[k] * disc));
      return cost;
    }

    /* Flood fill para comprobar que no se bloquea el acceso. */
    _reachabilityOk(game, rect) {
      const w = this.world;
      const cols = w.cols, rows = w.rows;
      const startX = Math.floor(game.player.x / w.tile), startY = Math.floor(game.player.y / w.tile);
      const seen = new Uint8Array(cols * rows);
      const queue = [startY * cols + startX];
      seen[startY * cols + startX] = 1;
      let head = 0;
      let found = 0;
      const targets = [
        { x: game.generator.x, y: game.generator.y, tag: 1 },
        { x: game.quests.antenna.x, y: game.quests.antenna.y, tag: 2 }
      ];
      // El generador y la antena son solidos: basta con llegar a una casilla
      // contigua a ellos, de ahi el margen de 90px.
      const REACH = 90;
      while (head < queue.length && found !== 3) {
        const idx = queue[head++];
        const cx = idx % cols, cy = (idx / cols) | 0;
        for (let i = 0; i < targets.length; i++) {
          if (found & targets[i].tag) continue;
          const t = targets[i];
          if (Math.abs(cx * w.tile + w.tile / 2 - t.x) < REACH && Math.abs(cy * w.tile + w.tile / 2 - t.y) < REACH) {
            found |= t.tag;
          }
        }
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            if (dx === 0 && dy === 0) continue;
            const nx = cx + dx, ny = cy + dy;
            if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
            const ni = ny * cols + nx;
            if (seen[ni]) continue;
            if (w.navBlocked[ni]) continue;
            // No entrar en el rectangulo nuevo
            const wx = nx * w.tile + w.tile / 2, wy = ny * w.tile + w.tile / 2;
            if (Math.abs(wx - rect.x) <= rect.hw + w.tile * 0.5 && Math.abs(wy - rect.y) <= rect.hh + w.tile * 0.5) continue;
            seen[ni] = 1;
            queue.push(ni);
          }
        }
      }
      return found === 3;
    }

    /* --- Colocacion ------------------------------------------------------ */
    place(game, type, x, y) {
      const check = this.validate(game, type, x, y);
      if (!check.ok) {
        game.ui.toast(check.reason, 'error');
        game.audio.play('error');
        return null;
      }
      const def = BUILDINGS[type];
      if (!game.inventory.spend(check.cost)) return null;

      const hw = def.w / 2, hh = def.h / 2;
      const b = {
        id: U.uid('bl'),
        type: type,
        name: def.name,
        x: x, y: y, hw: hw, hh: hh,
        hp: def.hp * (game.upgrades ? game.upgrades.structureHpMultiplier() : 1),
        maxHp: def.hp * (game.upgrades ? game.upgrades.structureHpMultiplier() : 1),
        dead: false,
        hitFlash: 0,
        buildAnim: 0.35,
        open: false,
        ammo: type === 'turret' ? this.turretAmmo : 0,
        angle: 0,
        cooldown: 0,
        trapHits: {},
        sign: Math.random() < 0.5 ? 1 : -1
      };
      b.obstacle = this.world.addObstacle({
        kind: 'building_' + type, x: x, y: y, shape: 'rect', hw: hw, hh: hh,
        solid: !!def.solid, building: b, passableForPlayer: false
      });
      this.list.push(b);
      if (def.solid) this.world.blockers.push({ x: x, y: y, hw: hw, hh: hh, building: b });
      this.world.rebuildNav();
      game.audio.play('build');
      game.particles.burst(x, y, 14, { color: '#c9a06a', speed: 120, life: 0.45 });
      game.ui.toast('Construido: ' + def.name, 'good');
      game.save.markDirty();
      return b;
    }

    remove(b) {
      const i = this.list.indexOf(b);
      if (i !== -1) this.list.splice(i, 1);
      if (b.obstacle) this.world.removeObstacle(b.obstacle);
      for (let k = this.world.blockers.length - 1; k >= 0; k--) {
        if (this.world.blockers[k].building === b) this.world.blockers.splice(k, 1);
      }
      this.world.rebuildNav();
    }

    /* --- Actualizacion ---------------------------------------------------- */
    update(dt, game) {
      for (const b of this.list) {
        if (b.dead) continue;
        if (b.hitFlash > 0) b.hitFlash -= dt;
        if (b.buildAnim > 0) b.buildAnim -= dt;

        switch (b.type) {
          case 'trap': this._updateTrap(b, dt, game); break;
          case 'turret': this._updateTurret(b, dt, game); break;
          case 'door': this._updateDoor(b, dt, game); break;
          default: break;
        }
      }
    }

    _updateTrap(b, dt, game) {
      for (const e of game.enemies.list) {
        if (e.dead) continue;
        if (U.dist(e.x, e.y, b.x, b.y) > b.hw + e.r) continue;
        const last = b.trapHits[e.id] || -99;
        if (game.time - last < this.trapCooldown) continue;
        b.trapHits[e.id] = game.time;
        const dmg = this.trapDamage * (game.upgrades ? game.upgrades.trapMultiplier() : 1);
        TN.Combat.damageEnemy(game, e, dmg, {
          knockback: 180, dirX: e.x - b.x, dirY: e.y - b.y, source: 'trap'
        });
        game.audio.play('trap');
        game.particles.burst(b.x, b.y, 8, { color: '#d8d0b8', speed: 120, life: 0.3, shape: 'spark' });
      }
    }

    _updateTurret(b, dt, game) {
      if (b.ammo <= 0) return;
      b.cooldown -= dt;
      const range = this.turretRange * (game.upgrades ? game.upgrades.turretRangeMultiplier() : 1);
      const dmg = this.turretDamage * (game.upgrades ? game.upgrades.turretMultiplier() : 1);
      let target = null, bd = range * range;
      for (const e of game.enemies.list) {
        if (e.dead) continue;
        const d = U.dist2(b.x, b.y, e.x, e.y);
        if (d < bd && game.world.losClear(b.x, b.y, e.x, e.y)) { bd = d; target = e; }
      }
      if (!target) return;
      b.angle = U.angleTo(b.x, b.y, target.x, target.y);
      if (b.cooldown <= 0) {
        b.cooldown = this.turretFireCd;
        b.ammo--;
        const spread = (Math.random() - 0.5) * 0.08;
        const a = b.angle + spread;
        game.projectiles.spawn({
          x: b.x + Math.cos(a) * 14, y: b.y + Math.sin(a) * 14,
          vx: Math.cos(a) * 620, vy: Math.sin(a) * 620, speed: 620,
          damage: dmg, color: '#ffd27a', size: 3, kind: 'bullet', friendly: true, life: 1.2
        });
        game.audio.play('shoot');
      }
    }

    _updateDoor(b, dt, game) {
      // Las puertas abiertas se cierran solas si hay enemigos cerca
      if (b.open) {
        const near = game.enemies.nearestTo(b.x, b.y, 90);
        if (near) b.open = false;
      }
      if (b.obstacle) b.obstacle.passableForPlayer = b.open;
    }

    /* Edificio que bloquea el paso hacia un objetivo. */
    blockingFor(enemy, gx, gy) {
      let best = null, bestD = Infinity;
      const ang = U.angleTo(enemy.x, enemy.y, gx, gy);
      const dirX = Math.cos(ang), dirY = Math.sin(ang);
      for (const b of this.list) {
        if (b.dead) continue;
        const dx = b.x - enemy.x, dy = b.y - enemy.y;
        const d = Math.hypot(dx, dy);
        if (d > enemy.r + 34) continue;
        const dot = (dx * dirX + dy * dirY) / (d || 1);
        if (dot < 0.25) continue;
        if (d < bestD) { bestD = d; best = b; }
      }
      return best;
    }

    /* Recarga de torretas y linterna en el banco de trabajo. */
    serviceBench(game) {
      let did = false;
      for (const b of this.list) {
        if (b.dead || b.type !== 'turret') continue;
        if (b.ammo >= this.turretMaxAmmo) continue;
        if (!game.inventory.canAfford({ scrap: 3 })) {
          game.ui.toast('Necesitas 3 de chatarra para recargar torretas', 'error');
          return did;
        }
        game.inventory.spend({ scrap: 3 });
        b.ammo = this.turretMaxAmmo;
        game.ui.toast('Torreta recargada', 'good');
        did = true;
      }
      if (game.player.flashlightBattery < TN.Config.FLASHLIGHT.batteryMax) {
        if (game.inventory.canAfford(TN.Config.FLASHLIGHT.rechargeCost)) {
          game.inventory.spend(TN.Config.FLASHLIGHT.rechargeCost);
          game.player.flashlightBattery = Math.min(
            TN.Config.FLASHLIGHT.batteryMax,
            game.player.flashlightBattery + TN.Config.FLASHLIGHT.rechargeAmount
          );
          game.ui.toast('Linterna recargada', 'good');
          did = true;
        }
      }
      if (!did) game.ui.toast('No hay nada que reparar aqui', 'info');
      return did;
    }

    /* --- Dibujado --------------------------------------------------------- */
    draw(ctx, cam) {
      const b = cam.bounds(80);
      for (const bl of this.list) {
        if (bl.x < b.x0 || bl.x > b.x1 || bl.y < b.y0 || bl.y > b.y1) continue;
        drawBuilding(ctx, bl);
      }
    }

    /* --- Guardado --------------------------------------------------------- */
    serialize() {
      return {
        list: this.list.map(b => ({
          t: b.type, x: Math.round(b.x), y: Math.round(b.y),
          h: Math.round(b.hp), o: b.open ? 1 : 0, a: b.ammo,
          d: b.disabled ? 1 : 0
        })),
        // Sin guardar los desbloqueos, al continuar una partida las
        // estructuras ya construidas (lampara, banco, torreta, horno...)
        // habria que recraftearlas pagando materiales otra vez.
        unlocked: Object.assign({}, this.unlocked)
      };
    }

    restore(data, game) {
      // Limpia construccion previa para no duplicar
      for (let i = this.list.length - 1; i >= 0; i--) this.remove(this.list[i]);
      // Formato antiguo (solo la lista) o nuevo (lista + desbloqueos).
      const list = Array.isArray(data) ? data : (data && Array.isArray(data.list) ? data.list : null);
      if (!list) return;
      if (!Array.isArray(data) && data.unlocked && typeof data.unlocked === 'object') {
        for (const k in data.unlocked) if (data.unlocked[k]) this.unlocked[k] = true;
      }
      const mult = (game && game.upgrades) ? game.upgrades.structureHpMultiplier() : 1;
      for (const rec of list) {
        const def = BUILDINGS[rec.t];
        if (!def) continue;
        const hw = def.w / 2, hh = def.h / 2;
        const maxHp = def.hp * mult;
        const b = {
          id: U.uid('bl'),
          type: rec.t, name: def.name,
          x: rec.x, y: rec.y, hw: hw, hh: hh,
          hp: Math.min(rec.h, maxHp), maxHp: maxHp,
          dead: false, hitFlash: 0, buildAnim: 0,
          open: !!rec.o,
          ammo: rec.a || 0,
          disabled: !!rec.d,
          angle: 0, cooldown: 0, trapHits: {},
          sign: Math.random() < 0.5 ? 1 : -1
        };
        b.obstacle = this.world.addObstacle({
          kind: 'building_' + rec.t, x: b.x, y: b.y, shape: 'rect', hw: hw, hh: hh,
          solid: !!def.solid, building: b, passableForPlayer: b.open
        });
        this.list.push(b);
        if (def.solid) this.world.blockers.push({ x: b.x, y: b.y, hw: hw, hh: hh, building: b });
      }
      this.world.rebuildNav();
    }
  }

  /* --- Dibujo por tipo --------------------------------------------------- */
  function drawBuilding(ctx, b) {
    const w = b.hw, h = b.hh;
    ctx.save();
    ctx.translate(b.x, b.y);

    // Sombra
    ctx.globalAlpha = 0.3;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(0, h * 0.7, w * 1.05, h * 0.35, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;

    const flash = b.hitFlash > 0;
    const grow = b.buildAnim > 0 ? 1 - b.buildAnim / 0.35 : 1;

    switch (b.type) {
      case 'wall': {
        ctx.fillStyle = flash ? '#ffd9a0' : '#6b4f31';
        ctx.fillRect(-w, -h, w * 2, h * 2);
        ctx.strokeStyle = flash ? '#fff' : '#4a3620';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(-w, -h); ctx.lineTo(w, h);
        ctx.moveTo(w, -h); ctx.lineTo(-w, h);
        ctx.stroke();
        ctx.fillStyle = flash ? '#fff' : '#836440';
        ctx.fillRect(-w, -h, w * 2, 3);
        break;
      }
      case 'door': {
        ctx.fillStyle = flash ? '#ffd9a0' : '#5b4227';
        ctx.fillRect(-w, -h, w * 2, h * 2);
        if (b.open) {
          ctx.fillStyle = '#241a10';
          ctx.fillRect(-w + 4, -h + 4, w * 2 - 8, h * 2 - 8);
          ctx.strokeStyle = '#9a7546'; ctx.lineWidth = 3;
          ctx.beginPath();
          ctx.moveTo(-w, -h); ctx.lineTo(-w, h);
          ctx.moveTo(w, -h); ctx.lineTo(w, h);
          ctx.stroke();
        } else {
          ctx.fillStyle = '#7d5c33';
          ctx.fillRect(-w + 3, -h + 3, w * 2 - 6, h * 2 - 6);
          ctx.strokeStyle = '#3c2c19'; ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.moveTo(-w + 3, 0); ctx.lineTo(w - 3, 0);
          ctx.stroke();
          ctx.fillStyle = '#d8c07a';
          ctx.fillRect(w - 9, -3, 4, 6);
        }
        break;
      }
      case 'trap': {
        ctx.fillStyle = '#3a2c1f';
        ctx.fillRect(-w, -h, w * 2, h * 2);
        ctx.strokeStyle = flash ? '#fff' : '#cfd6dc';
        ctx.lineWidth = 2;
        for (let i = -1; i <= 1; i++) {
          for (let j = -1; j <= 1; j++) {
            const px = i * 10, py = j * 10;
            ctx.beginPath();
            ctx.moveTo(px - 3, py + 3); ctx.lineTo(px + 3, py - 3);
            ctx.stroke();
          }
        }
        break;
      }
      case 'turret': {
        ctx.fillStyle = flash ? '#ffd9a0' : '#4a4a45';
        ctx.fillRect(-w, -h, w * 2, h * 2);
        ctx.save();
        ctx.rotate(b.angle);
        ctx.fillStyle = b.ammo > 0 ? '#8d949b' : '#5a3a3a';
        ctx.fillRect(0, -3, 26, 6);
        ctx.fillStyle = '#33332f';
        ctx.fillRect(-8, -6, 12, 12);
        ctx.restore();
        ctx.fillStyle = b.ammo > 0 ? '#8fe36a' : '#c04a4a';
        ctx.beginPath(); ctx.arc(-w + 5, -h + 5, 3, 0, 6.3); ctx.fill();
        break;
      }
      case 'bench': {
        ctx.fillStyle = flash ? '#ffd9a0' : '#6f5233';
        ctx.fillRect(-w, -h + 6, w * 2, h * 2 - 12);
        ctx.fillStyle = '#8a6a42';
        ctx.fillRect(-w, -h, w * 2, 8);
        ctx.strokeStyle = '#4a3620'; ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(-w + 4, -h + 8); ctx.lineTo(w - 4, -h + 8);
        ctx.stroke();
        ctx.fillStyle = '#9fb4c0';
        ctx.fillRect(-8, -h + 2, 7, 4);
        ctx.fillStyle = '#c9a06a';
        ctx.fillRect(4, -h + 3, 9, 3);
        break;
      }
      case 'lamp': {
        ctx.fillStyle = flash ? '#fff' : '#3f3a33';
        ctx.fillRect(-4, -h, 8, h * 2);
        ctx.fillStyle = b.disabled ? '#4a4a4a' : '#ffd98a';
        ctx.beginPath(); ctx.arc(0, -h, 7, 0, 6.3); ctx.fill();
        if (!b.disabled) {
          const g = ctx.createRadialGradient(0, -h, 0, 0, -h, 46);
          g.addColorStop(0, 'rgba(255,217,138,0.5)');
          g.addColorStop(1, 'rgba(255,217,138,0)');
          ctx.fillStyle = g;
          ctx.beginPath(); ctx.arc(0, -h, 46, 0, 6.3); ctx.fill();
        }
        break;
      }
      case 'forge': {
        ctx.fillStyle = flash ? '#ffd9a0' : '#4a4239';
        ctx.fillRect(-w, -h, w * 2, h * 2);
        ctx.fillStyle = '#2a251f';
        ctx.fillRect(-w + 5, -h + 5, w * 2 - 10, h * 2 - 10);
        const g = ctx.createRadialGradient(0, 4, 1, 0, 4, 22);
        g.addColorStop(0, 'rgba(255,150,60,0.95)');
        g.addColorStop(1, 'rgba(255,80,20,0)');
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.arc(0, 4, 22, 0, 6.3); ctx.fill();
        break;
      }
      default: {
        ctx.fillStyle = '#666';
        ctx.fillRect(-w, -h, w * 2, h * 2);
        break;
      }
    }

    if (grow < 1) {
      ctx.globalAlpha = 0.6;
    }

    // Barra de vida si esta danada
    if (b.hp < b.maxHp) {
      const bw = w * 2;
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(-bw / 2, -h - 9, bw, 3);
      ctx.fillStyle = '#d69a4a';
      ctx.fillRect(-bw / 2, -h - 9, bw * (b.hp / b.maxHp), 3);
    }
    ctx.globalAlpha = 1;
    ctx.restore();
  }

  const Buildings = { Manager: BuildingManager, DEFINITIONS: BUILDINGS, drawBuilding: drawBuilding };
  Buildings.BUILDINGS = BUILDINGS;
  return Buildings;
})();
