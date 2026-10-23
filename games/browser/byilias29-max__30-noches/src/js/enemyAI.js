/* ==========================================================================
   30 NOCHES - enemyAI.js
   Percepcion, decision de objetivo y navegacion (A* sobre la cuadricula).
   ========================================================================== */
window.TN = window.TN || {};

TN.EnemyAI = (function () {
  const U = TN.Utils;

  /* ---------------------------------------------------------------------
     Navigator: A* 8-direcciones sobre la cuadricula del mundo.
     Las busquedas se cachean por enemigo y se reparten entre fotogramas.
     --------------------------------------------------------------------- */
  class Navigator {
    constructor(world) {
      this.world = world;
      const n = world.cols * world.rows;
      this.g = new Float32Array(n);
      this.f = new Float32Array(n);
      this.came = new Int32Array(n);
      this.stamp = new Int32Array(n);
      this.closed = new Uint8Array(n);
      this.epoch = 0;
      this.heap = new Int32Array(2048);
      this.heapSize = 0;
    }

    _push(idx) {
      if (this.heapSize >= this.heap.length) return;
      let i = this.heapSize++;
      this.heap[i] = idx;
      while (i > 0) {
        const p = (i - 1) >> 1;
        if (this.f[this.heap[p]] <= this.f[this.heap[i]]) break;
        const t = this.heap[p]; this.heap[p] = this.heap[i]; this.heap[i] = t;
        i = p;
      }
    }

    _pop() {
      const top = this.heap[0];
      this.heapSize--;
      if (this.heapSize > 0) {
        this.heap[0] = this.heap[this.heapSize];
        let i = 0;
        for (;;) {
          const l = i * 2 + 1, r = l + 1;
          let m = i;
          if (l < this.heapSize && this.f[this.heap[l]] < this.f[this.heap[m]]) m = l;
          if (r < this.heapSize && this.f[this.heap[r]] < this.f[this.heap[m]]) m = r;
          if (m === i) break;
          const t = this.heap[m]; this.heap[m] = this.heap[i]; this.heap[i] = t;
          i = m;
        }
      }
      return top;
    }

    toTile(x, y) {
      const tx = Math.floor(x / this.world.tile), ty = Math.floor(y / this.world.tile);
      if (tx < 0 || ty < 0 || tx >= this.world.cols || ty >= this.world.rows) return -1;
      return ty * this.world.cols + tx;
    }

    nearestFree(idx) {
      const w = this.world;
      const tx = idx % w.cols, ty = (idx / w.cols) | 0;
      for (let r = 1; r <= 6; r++) {
        for (let oy = -r; oy <= r; oy++) {
          for (let ox = -r; ox <= r; ox++) {
            if (Math.max(Math.abs(ox), Math.abs(oy)) !== r) continue;
            const nx = tx + ox, ny = ty + oy;
            if (nx < 0 || ny < 0 || nx >= w.cols || ny >= w.rows) continue;
            const i = ny * w.cols + nx;
            if (!w.navBlocked[i]) return i;
          }
        }
      }
      return -1;
    }

    /* Devuelve una lista de puntos {x,y} o null. */
    findPath(sx, sy, tx, ty) {
      const w = this.world;
      const start = this.toTile(sx, sy);
      let goal = this.toTile(tx, ty);
      if (start < 0 || goal < 0) return null;
      if (w.navBlocked[goal]) {
        goal = this.nearestFree(goal);
        if (goal < 0) return null;
      }
      if (start === goal) return [{ x: tx, y: ty }];

      this.epoch++;
      const ep = this.epoch;
      this.heapSize = 0;
      const gx = goal % w.cols, gy = (goal / w.cols) | 0;

      this.g[start] = 0;
      this.f[start] = 0;
      this.came[start] = -1;
      this.stamp[start] = ep;
      this.closed[start] = 0;
      this._push(start);

      let iterations = 0;
      const maxIter = 2600;
      let found = false;

      while (this.heapSize > 0 && iterations++ < maxIter) {
        const cur = this._pop();
        if (this.closed[cur] === 1 && this.stamp[cur] === ep) continue;
        this.closed[cur] = 1;
        if (cur === goal) { found = true; break; }
        const cx = cur % w.cols, cy = (cur / w.cols) | 0;
        const cg = this.g[cur];
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            if (dx === 0 && dy === 0) continue;
            const nx = cx + dx, ny = cy + dy;
            if (nx < 0 || ny < 0 || nx >= w.cols || ny >= w.rows) continue;
            const ni = ny * w.cols + nx;
            if (w.navBlocked[ni]) continue;
            if (dx !== 0 && dy !== 0) {
              // No cortar esquinas
              if (w.navBlocked[cy * w.cols + nx] || w.navBlocked[ny * w.cols + cx]) continue;
            }
            const step = (dx !== 0 && dy !== 0) ? 1.4142 : 1;
            const extra = w.navCost[ni] || 0;
            const ng = cg + step + extra;
            if (this.stamp[ni] !== ep) {
              this.stamp[ni] = ep;
              this.g[ni] = Infinity;
              this.closed[ni] = 0;
              this.came[ni] = -1;
            }
            if (ng < this.g[ni]) {
              this.g[ni] = ng;
              this.came[ni] = cur;
              const h = Math.hypot(nx - gx, ny - gy);
              this.f[ni] = ng + h * 1.05;
              this._push(ni);
            }
          }
        }
      }

      if (!found) {
        // Sin ruta completa: devuelve el mejor nodo expandido alcanzable
        let best = -1, bestH = Infinity;
        for (let i = 0; i < this.stamp.length; i++) {
          if (this.stamp[i] !== ep) continue;
          const ix = i % w.cols, iy = (i / w.cols) | 0;
          const h = Math.hypot(ix - gx, iy - gy);
          if (h < bestH) { bestH = h; best = i; }
        }
        if (best < 0 || bestH > 14) return null;
        goal = best;
      }

      // Reconstruir
      const rev = [];
      let cur = goal;
      let guard = 0;
      while (cur !== -1 && guard++ < 4000) {
        const ix = cur % w.cols, iy = (cur / w.cols) | 0;
        rev.push({ x: ix * w.tile + w.tile / 2, y: iy * w.tile + w.tile / 2 });
        cur = this.came[cur];
        if (this.stamp[cur] !== ep) break;
      }
      rev.reverse();
      if (rev.length) rev[rev.length - 1] = { x: tx, y: ty };
      // Descarta el primer punto (ya estamos ahi)
      while (rev.length > 1 && U.dist(rev[0].x, rev[0].y, sx, sy) < 12) rev.shift();
      return rev;
    }
  }

  /* ---------------------------------------------------------------------
     Comportamiento por enemigo
     --------------------------------------------------------------------- */
  function applyKnockback(game, e, dt) {
    if (Math.abs(e.kx) > 0.01 || Math.abs(e.ky) > 0.01) {
      e.x += e.kx * dt;
      e.y += e.ky * dt;
      const d = Math.pow(0.0015, dt);
      e.kx *= d; e.ky *= d;
      if (Math.abs(e.kx) < 1) e.kx = 0;
      if (Math.abs(e.ky) < 1) e.ky = 0;
    }
  }

  function moveToward(game, e, tx, ty, dt) {
    const w = game.world;
    const dist = U.dist(e.x, e.y, tx, ty);
    let gx = tx, gy = ty;
    const direct = dist < 240 && w.losClear(e.x, e.y, tx, ty);

    if (!direct) {
      e.pathTimer -= dt;
      if (!e.path || e.pathTimer <= 0 || e.pathIndex >= e.path.length) {
        e.path = game.navigator.findPath(e.x, e.y, tx, ty);
        e.pathIndex = 0;
        e.pathTimer = 0.55 + Math.random() * 0.5;
      }
      if (e.path && e.path.length) {
        let guard = 0;
        while (e.pathIndex < e.path.length && guard++ < 40 &&
          U.dist(e.x, e.y, e.path[e.pathIndex].x, e.path[e.pathIndex].y) < 18) {
          e.pathIndex++;
        }
        if (e.pathIndex < e.path.length) {
          gx = e.path[e.pathIndex].x; gy = e.path[e.pathIndex].y;
        }
      }
    } else {
      e.path = null;
    }

    const dx = gx - e.x, dy = gy - e.y;
    const len = Math.hypot(dx, dy);
    if (len > 0.5) {
      let sp = e.speed * e.speedMul;
      if (w.isSwamp(e.x, e.y)) sp *= 0.7;
      if (e.aggro) sp *= 1.1;
      const nx = e.x + (dx / len) * sp * dt;
      const ny = e.y + (dy / len) * sp * dt;
      const res = w.resolve(nx, ny, e.r);
      e.x = res.x; e.y = res.y;
      e.facing = Math.atan2(dy, dx);
    }

    // Anti-atasco: si no avanza, prueba a desviarse
    const moved = U.dist(e.x, e.y, e.lastX, e.lastY);
    if (moved < 3) {
      e.stuckTimer += dt;
      if (e.stuckTimer > 0.5) {
        e.stuckTimer = 0;
        e.path = null;
        e.pathTimer = 0;
        const side = e.facing + (Math.random() < 0.5 ? 1.3 : -1.3);
        const res = w.resolve(e.x + Math.cos(side) * e.r * 2, e.y + Math.sin(side) * e.r * 2, e.r);
        e.x = res.x; e.y = res.y;
      }
    } else {
      e.stuckTimer = 0;
      e.lastX = e.x; e.lastY = e.y;
    }
  }

  function shootAtPlayer(game, e, speed, damage, color) {
    const pl = game.player;
    const lead = 0.18;
    const tx = pl.x + pl.vx * lead, ty = pl.y + pl.vy * lead;
    const ang = U.angleTo(e.x, e.y, tx, ty);
    game.projectiles.spawn({
      x: e.x + Math.cos(ang) * (e.r + 4),
      y: e.y + Math.sin(ang) * (e.r + 4),
      vx: Math.cos(ang) * speed,
      vy: Math.sin(ang) * speed,
      speed: speed,
      damage: damage,
      color: color || '#b98ce0',
      size: 5,
      kind: 'glob',
      friendly: false,
      life: 3
    });
    game.audio.play('shoot');
  }

  function updateEnemy(game, e, dt) {
    if (e.dead) return;
    if (e.hitFlash > 0) e.hitFlash -= dt;
    if (e.spawnAnim > 0) e.spawnAnim -= dt;

    if (e.stun > 0) {
      e.stun -= dt;
      applyKnockback(game, e, dt);
      return;
    }
    applyKnockback(game, e, dt);
    e.attackTimer -= dt;

    const pl = game.player;
    const dPlayer = U.dist(e.x, e.y, pl.x, pl.y);
    const gen = game.generator;

    /* ---------- Eleccion de objetivo ----------
       Prioridad: el generador (objetivo de la horda). El jugador solo es
       objetivo personal si esta muy cerca o si ha causado dano al enemigo. */
    let targetType = 'generator';
    let targetRef = null;

    if (e.lightAffinity) {
      const light = game.findLightTarget(e.x, e.y, e.detect);
      if (light) { targetType = 'light'; targetRef = light; }
      else if (dPlayer < e.detect) { targetType = 'player'; }
    } else if (e.aggro) {
      // Enemigo implicado en un combate: persigue al jugador si lo tiene cerca
      if (dPlayer < e.detect * 1.6) targetType = 'player';
      else e.aggro = false;
    } else if (dPlayer < e.detect * 0.45) {
      targetType = 'player';
    } else if (gen && !gen.dead) {
      targetType = 'generator';
    }

    if (targetType === 'player' || (targetType === 'light' && targetRef && targetRef.kind === 'player')) {
      e.aggro = true;
    }

    /* ---------- Comportamiento por tipo ---------- */
    if (e.ranged) {
      // Lanzador: mantiene la distancia y dispara
      const desired = e.keepDist;
      if (targetType === 'player' && dPlayer < desired * 0.75) {
        // Huye
        const ang = U.angleTo(pl.x, pl.y, e.x, e.y);
        const res = game.world.resolve(e.x + Math.cos(ang) * 30, e.y + Math.sin(ang) * 30, e.r);
        e.x = res.x; e.y = res.y;
        e.facing = ang + Math.PI;
      } else if (targetType === 'player') {
        const ang = U.angleTo(e.x, e.y, pl.x, pl.y);
        e.facing = ang;
        if (e.attackTimer <= 0 && dPlayer < e.detect && game.world.losClear(e.x, e.y, pl.x, pl.y)) {
          shootAtPlayer(game, e, 250, e.damage, '#b98ce0');
          e.attackTimer = e.attackCd;
        }
        if (dPlayer > desired) moveToward(game, e, pl.x, pl.y, dt);
      } else {
        moveToward(game, e, gen.x, gen.y, dt);
      }
      return;
    }

    /* ---------- Melee: acercarse y golpear ---------- */
    let goalX, goalY;
    if (targetType === 'player') {
      goalX = pl.x; goalY = pl.y;
    } else if (targetType === 'light') {
      goalX = targetRef.x; goalY = targetRef.y;
    } else {
      goalX = gen.x; goalY = gen.y;
    }

    // ¿Una estructura bloquea el camino? -> atacarla
    const blocking = game.buildings.blockingFor(e, goalX, goalY);
    if (blocking && targetType !== 'player') {
      goalX = blocking.x; goalY = blocking.y;
    }

    const distGoal = U.dist(e.x, e.y, goalX, goalY);
    const atkRange = e.r + 14;

    if (targetType === 'player') {
      if (distGoal <= atkRange + pl.r && e.attackTimer <= 0) {
        TN.Combat.damagePlayer(game, e.damage, e.name);
        e.attackTimer = e.attackCd;
        e.facing = U.angleTo(e.x, e.y, pl.x, pl.y);
      }
    } else if (targetType === 'light' && targetRef) {
      const light = targetRef;
      if (distGoal <= atkRange + 12 && e.attackTimer <= 0) {
        if (light.kind === 'player') {
          TN.Combat.damagePlayer(game, e.damage, e.name);
        } else if (light.building) {
          TN.Combat.damageBuilding(game, light.building, e.damage * e.structureDamage);
        }
        e.attackTimer = e.attackCd;
      }
    } else if (targetType === 'generator') {
      if (distGoal <= atkRange + 30 && e.attackTimer <= 0) {
        TN.Combat.damageGenerator(game, e.damage * e.structureDamage);
        e.attackTimer = e.attackCd;
        e.facing = U.angleTo(e.x, e.y, gen.x, gen.y);
        game.particles.burst(e.x + (gen.x - e.x) * 0.5, e.y + (gen.y - e.y) * 0.5, 4,
          { color: '#ffb46b', speed: 80, life: 0.25 });
      }
    }

    if (blocking && distGoal <= atkRange + 26 && e.attackTimer <= 0) {
      TN.Combat.damageBuilding(game, blocking, e.damage * e.structureDamage);
      e.attackTimer = e.attackCd;
    }

    // Solo se mueve si no esta pegado al objetivo
    const stopDist = targetType === 'player' ? (e.r + pl.r + 4) : (targetType === 'generator' ? e.r + 34 : atkRange + 8);
    if (distGoal > stopDist) {
      moveToward(game, e, goalX, goalY, dt);
    } else if (targetType === 'player') {
      e.facing = U.angleTo(e.x, e.y, pl.x, pl.y);
    }
  }

  return { Navigator: Navigator, updateEnemy: updateEnemy };
})();
