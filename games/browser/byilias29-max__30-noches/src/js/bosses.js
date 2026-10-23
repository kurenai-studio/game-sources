/* ==========================================================================
   30 NOCHES - bosses.js
   Arquitectura comun de jefes: configuracion, fases y patrones de ataque
   con telegrafia (aviso), ventana de recuperacion y oportunidad de
   contraataque.
   ========================================================================== */
window.TN = window.TN || {};

TN.Bosses = (function () {
  const U = TN.Utils;

  const PATTERNS = {
    charge: { windup: 0.95, active: 0.85, recover: 1.35, cd: 2.4, label: 'carga' },
    slam: { windup: 0.7, active: 0.2, recover: 1.0, cd: 2.8, label: 'onda sismica' },
    volley: { windup: 0.65, active: 0.75, recover: 1.05, cd: 2.6, label: 'lluvia' },
    leap: { windup: 0.75, active: 0.55, recover: 1.15, cd: 2.5, label: 'salto' },
    summon: { windup: 1.0, active: 0.35, recover: 1.25, cd: 5.0, label: 'invocacion' },
    sweep: { windup: 1.15, active: 1.35, recover: 1.1, cd: 4.0, label: 'barrido' },
    siege: { windup: 1.25, active: 1.7, recover: 1.5, cd: 4.5, label: 'asedio' }
  };

  const BOSSES = {
    day5: {
      id: 'day5', name: 'EL MAZACOTE', title: 'Lo que就没有 la noche',
      hp: 460, r: 30, speed: 46, damage: 26, color: '#4a3327', accent: '#e08a45',
      baseType: 'brute', structureDamage: 2.2,
      intro: 'Algo enorme se mueve entre los arboles.',
      phases: [
        { hpAbove: 1.0, patterns: ['charge'] },
        { hpAbove: 0.55, patterns: ['charge', 'slam'] },
        { hpAbove: 0.0, patterns: ['charge', 'slam'] }
      ],
      rewards: { scrap: 30, herbs: 12 }, rp: 18
    },
    day10: {
      id: 'day10', name: 'EL SALTADOR', title: 'Cazador de los tejados',
      hp: 620, r: 24, speed: 92, damage: 24, color: '#3a2f4a', accent: '#b98ce0',
      baseType: 'runner', structureDamage: 1.6,
      intro: 'Algo salta entre las copas. Cambia de objetivo.',
      phases: [
        { hpAbove: 1.0, patterns: ['leap'] },
        { hpAbove: 0.6, patterns: ['leap', 'leap', 'volley'] },
        { hpAbove: 0.0, patterns: ['leap', 'volley', 'charge'] }
      ],
      rewards: { scrap: 40, herbs: 15 }, rp: 24
    },
    day15: {
      id: 'day15', name: 'MADRE DE LA BABA', title: 'Escupe el bosque',
      hp: 880, r: 28, speed: 52, damage: 22, color: '#3c4a33', accent: '#9ede6a',
      baseType: 'spitter', structureDamage: 1.4,
      intro: 'El aire se vuelve acido.',
      phases: [
        { hpAbove: 1.0, patterns: ['volley'] },
        { hpAbove: 0.65, patterns: ['volley', 'slam'] },
        { hpAbove: 0.3, patterns: ['volley', 'slam', 'summon'] },
        { hpAbove: 0.0, patterns: ['volley', 'slam', 'summon', 'charge'] }
      ],
      rewards: { scrap: 55, herbs: 22 }, rp: 30
    },
    day20: {
      id: 'day20', name: 'ROMPEBASES', title: 'No necesita la puerta',
      hp: 1250, r: 34, speed: 40, damage: 30, color: '#3b3a34', accent: '#c9b458',
      baseType: 'brute', structureDamage: 4.5,
      intro: 'Viene directo a por tus defensas.',
      phases: [
        { hpAbove: 1.0, patterns: ['siege'] },
        { hpAbove: 0.6, patterns: ['siege', 'slam'] },
        { hpAbove: 0.25, patterns: ['siege', 'charge', 'summon'] },
        { hpAbove: 0.0, patterns: ['siege', 'charge', 'slam', 'summon'] }
      ],
      rewards: { scrap: 70, herbs: 26 }, rp: 38
    },
    day25: {
      id: 'day25', name: 'EL DEVORADOR', title: 'Multiples fases',
      hp: 1650, r: 30, speed: 66, damage: 28, color: '#41222c', accent: '#ff6f91',
      baseType: 'brute', structureDamage: 2.4,
      intro: 'Cambia de forma a mitad de combate.',
      phases: [
        { hpAbove: 1.0, patterns: ['charge', 'volley'] },
        { hpAbove: 0.75, patterns: ['charge', 'summon'] },
        { hpAbove: 0.45, patterns: ['volley', 'slam', 'summon'] },
        { hpAbove: 0.2, patterns: ['charge', 'volley', 'slam', 'summon'] },
        { hpAbove: 0.0, patterns: ['charge', 'volley', 'slam', 'summon', 'sweep'] }
      ],
      rewards: { scrap: 85, herbs: 30 }, rp: 48
    },
    day30: {
      id: 'day30', name: 'LA ENTIDAD', title: 'El origen de la Noche',
      hp: 2600, r: 36, speed: 62, damage: 34, color: '#1f2430', accent: '#8be9ff',
      baseType: 'brute', structureDamage: 3.0,
      intro: 'La antena no la encendio. La atrajo.',
      final: true,
      phases: [
        { hpAbove: 1.0, patterns: ['charge', 'volley'] },
        { hpAbove: 0.8, patterns: ['charge', 'summon'] },
        { hpAbove: 0.6, patterns: ['volley', 'slam', 'sweep'] },
        { hpAbove: 0.35, patterns: ['charge', 'volley', 'summon', 'sweep'] },
        { hpAbove: 0.15, patterns: ['charge', 'volley', 'slam', 'summon', 'sweep', 'siege'] },
        { hpAbove: 0.0, patterns: ['charge', 'volley', 'slam', 'summon', 'sweep', 'siege'] }
      ],
      rewards: { scrap: 150, herbs: 50 }, rp: 90
    }
  };

  /* --- Creacion ---------------------------------------------------------- */
  function spawnBoss(game, bossId, x, y) {
    const def = BOSSES[bossId];
    if (!def) return null;
    const diff = { hpMul: 1, dmgMul: 1, day: 30 };
    const e = game.enemies.spawn(def.baseType || 'stalker', x, y, { diff: diff });
    if (!e) return null;
    e.isBoss = true;
    e.bossId = bossId;
    e.name = def.name;
    e.hp = e.maxHp = def.hp;
    e.r = def.r;
    e.speed = def.speed;
    e.damage = def.damage;
    e.color = def.color;
    e.accent = def.accent;
    e.structureDamage = def.structureDamage || 1;
    e.rewards = def.rewards;
    e.isElite = false;
    e.spawnAnim = 1.4;
    e.boss = {
      def: def,
      phase: 0,
      state: 'roar',
      stateTimer: 2.0,
      pattern: null,
      patternIndex: 0,
      cd: 0,
      dir: 0,
      targetX: x, targetY: y,
      leapFromX: x, leapFromY: y,
      sweepAngle: 0,
      vulnerable: false
    };
    return e;
  }

  function currentPhase(e) {
    const ratio = e.hp / e.maxHp;
    const phases = e.boss.def.phases;
    let idx = 0;
    for (let i = 0; i < phases.length; i++) if (ratio <= phases[i].hpAbove) idx = i;
    return idx;
  }

  function pickTarget(game, e) {
    // Los jefes alternan entre jugador y generador; el final prioriza el generador.
    const pl = game.player;
    const gen = game.generator;
    const dP = U.dist(e.x, e.y, pl.x, pl.y);
    const dG = U.dist(e.x, e.y, gen.x, gen.y);
    if (e.boss.def.final) return dG < dP * 2.2 ? 'generator' : 'player';
    return (e.boss.patternIndex % 2 === 0) ? 'player' : 'generator';
  }

  function targetPoint(game, e, which) {
    const pl = game.player, gen = game.generator;
    if (which === 'generator') return { x: gen.x, y: gen.y, ref: gen };
    return { x: pl.x, y: pl.y, ref: pl };
  }

  /* --- Bucle principal del jefe ------------------------------------------ */
  function updateBoss(game, e, dt) {
    const b = e.boss;
    if (!b) return;
    const def = b.def;

    // Cambio de fase
    const phase = currentPhase(e);
    if (phase > b.phase) {
      b.phase = phase;
      b.state = 'roar';
      b.stateTimer = 1.6;
      b.vulnerable = false;
      game.audio.play('bossWarn');
      game.camera.addShake(8);
      game.ui.toast(def.name + ' entra en una nueva fase', 'warn');
      game.particles.burst(e.x, e.y, 40, { color: def.accent, speed: 260, life: 0.8, shape: 'circle' });
    }

    b.stateTimer -= dt;
    b.cd -= dt;

    const pl = game.player;
    const which = pickTarget(game, e);
    const tp = targetPoint(game, e, which);
    b.targetX = tp.x; b.targetY = tp.y;

    switch (b.state) {
      case 'roar':
        e.facing = U.angleTo(e.x, e.y, tp.x, tp.y);
        if (b.stateTimer <= 0) {
          b.state = 'move';
          b.stateTimer = 1.0;
        }
        break;

      case 'move': {
        // Acercarse al objetivo maintaining distancia de ataque
        const d = U.dist(e.x, e.y, tp.x, tp.y);
        e.facing = U.angleTo(e.x, e.y, tp.x, tp.y);
        if (d > e.r + 40) {
          const sp = e.speed * (def.final ? 1.05 : 1);
          const ang = U.angleTo(e.x, e.y, tp.x, tp.y);
          const res = game.world.resolve(e.x + Math.cos(ang) * sp * dt, e.y + Math.sin(ang) * sp * dt, e.r);
          e.x = res.x; e.y = res.y;
        }
        if (b.cd <= 0) {
          const phaseDef = def.phases[b.phase];
          const patName = phaseDef.patterns[b.patternIndex % phaseDef.patterns.length];
          b.patternIndex++;
          b.pattern = PATTERNS[patName] ? patName : 'charge';
          b.state = 'telegraph';
          b.stateTimer = PATTERNS[b.pattern].windup;
          b.dir = U.angleTo(e.x, e.y, tp.x, tp.y);
          b.vulnerable = false;
          game.audio.play('bossWarn');
        }
        break;
      }

      case 'telegraph': {
        e.facing = U.angleTo(e.x, e.y, tp.x, tp.y);
        b.dir = U.angleTo(e.x, e.y, tp.x, tp.y);
        drawTelegraph(game, e, b);
        if (b.stateTimer <= 0) {
          b.state = 'attack';
          b.stateTimer = PATTERNS[b.pattern].active;
          b.vulnerable = false;
          executePattern(game, e, b, tp, which);
        }
        break;
      }

      case 'attack': {
        updateAttack(game, e, b, tp, which, dt);
        if (b.stateTimer <= 0) {
          b.state = 'recover';
          b.stateTimer = PATTERNS[b.pattern].recover;
          b.vulnerable = true;      // ventana de contraataque
          b.cd = PATTERNS[b.pattern].cd;
        }
        break;
      }

      case 'recover': {
        e.facing = U.angleTo(e.x, e.y, tp.x, tp.y);
        if (b.stateTimer <= 0) {
          b.state = 'move';
          b.stateTimer = 0.4;
        }
        break;
      }
    }
  }

  function drawTelegraph(game, e, b) {
    const p = PATTERNS[b.pattern];
    const t = 1 - Math.max(0, b.stateTimer) / p.windup;
    if (b.pattern === 'charge' || b.pattern === 'leap') {
      game.effects.push({
        kind: 'telegraphLine', x: e.x, y: e.y, angle: b.dir,
        length: b.pattern === 'leap' ? 260 : 330, width: e.r * 1.6,
        life: 0.05, maxLife: 0.05, progress: t, color: '#ff6b6b'
      });
    } else if (b.pattern === 'slam' || b.pattern === 'siege') {
      game.effects.push({
        kind: 'telegraphCircle', x: e.x, y: e.y, radius: b.pattern === 'siege' ? 190 : 130,
        life: 0.05, maxLife: 0.05, progress: t, color: '#ffb066'
      });
    } else if (b.pattern === 'volley') {
      game.effects.push({
        kind: 'telegraphCone', x: e.x, y: e.y, angle: U.angleTo(e.x, e.y, tpSafe(game, e).x, tpSafe(game, e).y),
        radius: 300, life: 0.05, maxLife: 0.05, progress: t, color: '#c58bff'
      });
    }
  }

  function tpSafe(game, e) { return { x: e.boss.targetX, y: e.boss.targetY }; }

  function executePattern(game, e, b, tp, which) {
    const p = PATTERNS[b.pattern];
    switch (b.pattern) {
      case 'charge': {
        game.camera.addShake(7);
        game.particles.burst(e.x, e.y, 18, { color: e.accent, speed: 200, life: 0.5 });
        break;
      }
      case 'slam': {
        const r = 130;
        game.camera.addShake(10);
        game.effects.push({ kind: 'blast', x: e.x, y: e.y, radius: r, life: 0.45, maxLife: 0.45, color: '#ff9a5c' });
        game.particles.burst(e.x, e.y, 40, { color: '#c98a4a', speed: 280, life: 0.6, shape: 'circle' });
        game.audio.play('explode');
        if (U.dist(pl_x(game), pl_y(game), e.x, e.y) < r) {
          TN.Combat.damagePlayer(game, e.damage, e.name);
        }
        // Dano a estructuras cercanas
        for (const bl of game.buildings.list) {
          if (bl.dead) continue;
          if (U.dist(bl.x, bl.y, e.x, e.y) < r) {
            TN.Combat.damageBuilding(game, bl, e.damage * 1.2);
          }
        }
        break;
      }
      case 'volley': {
        const n = e.boss.def.final ? 9 : 6;
        const base = U.angleTo(e.x, e.y, tp.x, tp.y);
        for (let i = 0; i < n; i++) {
          const a = base + (i - (n - 1) / 2) * 0.22;
          game.projectiles.spawn({
            x: e.x + Math.cos(a) * (e.r + 6), y: e.y + Math.sin(a) * (e.r + 6),
            vx: Math.cos(a) * 300, vy: Math.sin(a) * 300, speed: 300,
            damage: e.damage * 0.7, color: e.accent, size: 6, kind: 'glob', friendly: false, life: 3.2
          });
        }
        game.audio.play('shoot');
        break;
      }
      case 'leap': {
        b.leapFromX = e.x; b.leapFromY = e.y;
        b.leapToX = tp.x; b.leapToY = tp.y;
        b.leapT = 0;
        game.camera.addShake(5);
        break;
      }
      case 'summon': {
        const n = e.boss.def.final ? 5 : 3;
        const diff = TN.Config.difficultyFor(game.dayNight.day);
        for (let i = 0; i < n; i++) {
          const ang = (i / n) * Math.PI * 2 + Math.random();
          const sx = e.x + Math.cos(ang) * 70, sy = e.y + Math.sin(ang) * 70;
          const type = diff.types[Math.floor(Math.random() * diff.types.length)];
          const spawn = game.enemies.spawn(type, sx, sy, { diff: diff });
          if (spawn) {
            spawn.spawnAnim = 0.6;
            game.particles.burst(sx, sy, 10, { color: e.accent, speed: 130, life: 0.4 });
          }
        }
        game.audio.play('bossWarn');
        game.ui.toast(e.name + ' invoca refuerzos', 'warn');
        break;
      }
      case 'sweep': {
        b.sweepAngle = U.angleTo(e.x, e.y, tp.x, tp.y) - 0.9;
        break;
      }
      case 'siege': {
        game.camera.addShake(8);
        // Dano a todas las estructuras cercanas y al generador
        for (const bl of game.buildings.list) {
          if (bl.dead) continue;
          if (U.dist(bl.x, bl.y, e.x, e.y) < 190) {
            TN.Combat.damageBuilding(game, bl, e.damage * 2.2);
          }
        }
        if (U.dist(game.generator.x, game.generator.y, e.x, e.y) < 190) {
          TN.Combat.damageGenerator(game, e.damage * 0.9);
        }
        game.effects.push({ kind: 'blast', x: e.x, y: e.y, radius: 190, life: 0.5, maxLife: 0.5, color: '#ffb066' });
        break;
      }
    }
  }

  function pl_x(game) { return game.player.x; }
  function pl_y(game) { return game.player.y; }

  function updateAttack(game, e, b, tp, which, dt) {
    const p = PATTERNS[b.pattern];
    switch (b.pattern) {
      case 'charge': {
        const sp = e.speed * 4.2;
        const nx = e.x + Math.cos(b.dir) * sp * dt;
        const ny = e.y + Math.sin(b.dir) * sp * dt;
        const res = game.world.resolve(nx, ny, e.r);
        const moved = U.dist(res.x, res.y, e.x, e.y);
        e.x = res.x; e.y = res.y;
        e.facing = b.dir;
        // Dano por contacto durante la carga
        const pl = game.player;
        if (U.dist(pl.x, pl.y, e.x, e.y) < e.r + pl.r + 6) {
          TN.Combat.damagePlayer(game, e.damage, e.name);
          b.state = 'recover';
          b.stateTimer = p.recover;
          b.vulnerable = true;
        }
        // Rompe estructuras
        for (const bl of game.buildings.list) {
          if (bl.dead) continue;
          if (U.dist(bl.x, bl.y, e.x, e.y) < e.r + 22) {
            TN.Combat.damageBuilding(game, bl, e.damage * e.structureDamage);
          }
        }
        if (moved < 1) {
          b.state = 'recover';
          b.stateTimer = p.recover;
          b.vulnerable = true;
          b.cd = p.cd;
          game.camera.addShake(9);
        }
        break;
      }
      case 'slam': {
        // Ya aplicado al ejecutar; aqui solo efecto
        if (Math.random() < dt * 12) {
          game.particles.burst(e.x + (Math.random() - 0.5) * 120, e.y + (Math.random() - 0.5) * 120, 2,
            { color: '#c98a4a', speed: 90, life: 0.4 });
        }
        break;
      }
      case 'leap': {
        b.leapT = Math.min(1, (b.leapT || 0) + dt / Math.max(0.2, p.active));
        const t = b.leapT;
        e.x = U.lerp(b.leapFromX, b.leapToX, t);
        e.y = U.lerp(b.leapFromY, b.leapToY, t);
        e.facing = U.angleTo(b.leapFromX, b.leapFromY, b.leapToX, b.leapToY);
        if (t >= 1) {
          game.camera.addShake(11);
          game.effects.push({ kind: 'blast', x: e.x, y: e.y, radius: 110, life: 0.4, maxLife: 0.4, color: '#ff9a5c' });
          const pl = game.player;
          if (U.dist(pl.x, pl.y, e.x, e.y) < 110) TN.Combat.damagePlayer(game, e.damage, e.name);
          if (U.dist(game.generator.x, game.generator.y, e.x, e.y) < 110) TN.Combat.damageGenerator(game, e.damage);
          for (const bl of game.buildings.list) {
            if (!bl.dead && U.dist(bl.x, bl.y, e.x, e.y) < 110) {
              TN.Combat.damageBuilding(game, bl, e.damage);
            }
          }
          game.audio.play('explode');
        }
        break;
      }
      case 'volley': {
        if (Math.random() < dt * 5) {
          const base = U.angleTo(e.x, e.y, tp.x, tp.y);
          const a = base + (Math.random() - 0.5) * 0.9;
          game.projectiles.spawn({
            x: e.x + Math.cos(a) * (e.r + 6), y: e.y + Math.sin(a) * (e.r + 6),
            vx: Math.cos(a) * 260, vy: Math.sin(a) * 260, speed: 260,
            damage: e.damage * 0.5, color: e.accent, size: 5, kind: 'glob', friendly: false, life: 3
          });
        }
        break;
      }
      case 'sweep': {
        b.sweepAngle += dt * 2.2;
        const n = 5;
        for (let i = 0; i < n; i++) {
          const a = b.sweepAngle + (i - (n - 1) / 2) * 0.16;
          game.projectiles.spawn({
            x: e.x + Math.cos(a) * (e.r + 8), y: e.y + Math.sin(a) * (e.r + 8),
            vx: Math.cos(a) * 340, vy: Math.sin(a) * 340, speed: 340,
            damage: e.damage * 0.45, color: e.accent, size: 4, kind: 'glob', friendly: false, life: 2.4
          });
        }
        break;
      }
      case 'siege': {
        if (Math.random() < dt * 10) {
          const a = Math.random() * Math.PI * 2;
          game.particles.burst(e.x + Math.cos(a) * 90, e.y + Math.sin(a) * 90, 2,
            { color: '#c98a4a', speed: 120, life: 0.4, gravity: 120 });
        }
        break;
      }
    }
  }

  /* --- Dibujo de jefe (sobrescribe el de enemigos normales) --------------- */
  function drawBoss(ctx, e) {
    const s = e.r;
    ctx.save();
    ctx.translate(e.x, e.y);
    ctx.globalAlpha = 0.4;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(0, s * 0.7, s * 1.0, s * 0.4, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;

    const pulse = 0.5 + 0.5 * Math.sin(performance.now() / 220);
    const flash = e.hitFlash > 0;
    const body = flash ? '#fff' : e.color;
    const accent = flash ? '#fff' : e.accent;

    ctx.rotate(e.facing);

    // Aura
    const aura = ctx.createRadialGradient(0, 0, s * 0.5, 0, 0, s * 1.9);
    aura.addColorStop(0, 'rgba(255,255,255,0)');
    aura.addColorStop(1, hexToRgba(accent, 0.18 + pulse * 0.12));
    ctx.fillStyle = aura;
    ctx.beginPath(); ctx.arc(0, 0, s * 1.9, 0, Math.PI * 2); ctx.fill();

    // Cuerpo
    ctx.fillStyle = body;
    ctx.beginPath();
    ctx.moveTo(s * 1.15, 0);
    ctx.lineTo(s * 0.15, -s * 1.15);
    ctx.lineTo(-s * 0.95, -s * 0.85);
    ctx.lineTo(-s * 1.05, 0);
    ctx.lineTo(-s * 0.95, s * 0.85);
    ctx.lineTo(s * 0.15, s * 1.15);
    ctx.closePath();
    ctx.fill();

    // Placas / espinas
    ctx.strokeStyle = accent;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(-s * 0.7, -s * 0.7); ctx.lineTo(s * 0.1, -s * 0.95);
    ctx.moveTo(-s * 0.7, s * 0.7); ctx.lineTo(s * 0.1, s * 0.95);
    ctx.stroke();

    // Nucleo brillante
    ctx.fillStyle = accent;
    ctx.beginPath(); ctx.arc(s * 0.15, 0, s * 0.3 * (0.8 + pulse * 0.35), 0, 6.3); ctx.fill();

    // Ojos
    ctx.fillStyle = '#15100e';
    ctx.beginPath(); ctx.arc(s * 0.78, -s * 0.3, s * 0.13, 0, 6.3); ctx.fill();
    ctx.beginPath(); ctx.arc(s * 0.78, s * 0.3, s * 0.13, 0, 6.3); ctx.fill();

    ctx.restore();

    // Indicador de vulnerabilidad
    if (e.boss && e.boss.vulnerable) {
      ctx.save();
      ctx.strokeStyle = 'rgba(255,230,150,0.9)';
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);
      ctx.beginPath(); ctx.arc(e.x, e.y, s * 1.5, 0, 6.3); ctx.stroke();
      ctx.restore();
    }
  }

  function hexToRgba(hex, a) {
    if (!hex || hex[0] !== '#') return 'rgba(255,255,255,' + a + ')';
    let h = hex.slice(1);
    if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
    const r = parseInt(h.slice(0, 2), 16), g = parseInt(h.slice(2, 4), 16), b = parseInt(h.slice(4, 6), 16);
    return 'rgba(' + r + ',' + g + ',' + b + ',' + a + ')';
  }

  return {
    BOSSES: BOSSES,
    PATTERNS: PATTERNS,
    spawnBoss: spawnBoss,
    updateBoss: updateBoss,
    drawBoss: drawBoss,
    hexToRgba: hexToRgba
  };
})();
