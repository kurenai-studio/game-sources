/* ==========================================================================
   30 NOCHES - enemies.js
   Definicion de tipos de criatura, gestor de entidades y dibujado.
   La IA vive en enemyAI.js.
   ========================================================================== */
window.TN = window.TN || {};

TN.Enemies = (function () {
  const U = TN.Utils;

  const ENEMY_TYPES = {
    stalker: {
      key: 'stalker', name: 'Acechador', hp: 34, speed: 52, damage: 9,
      attackCd: 1.1, r: 11, detect: 340, color: '#54764c', accent: '#b6e07a',
      rewards: { scrap: 1, herbs: 1 }, xp: 2,
      desc: 'Acecha entre los arboles y golpea sin avisar.'
    },
    runner: {
      key: 'runner', name: 'Corredor', hp: 22, speed: 108, damage: 7,
      attackCd: 0.75, r: 9, detect: 430, color: '#7d5c3a', accent: '#ffd9a0',
      rewards: { scrap: 1 }, xp: 2,
      desc: 'Rapido y fragil. Atraviesa las defensas.'
    },
    brute: {
      key: 'brute', name: 'Tanque', hp: 135, speed: 34, damage: 22,
      attackCd: 1.5, r: 18, detect: 300, color: '#5c6154', accent: '#cfd3ae',
      structureDamage: 2.4, rewards: { scrap: 3, herbs: 2 }, xp: 5,
      desc: 'Lento y enorme. Abre brechas en los muros.'
    },
    spitter: {
      key: 'spitter', name: 'Lanzador', hp: 42, speed: 46, damage: 11,
      attackCd: 1.7, r: 12, detect: 560, color: '#6a5178', accent: '#e0b8ff',
      ranged: true, keepDist: 240, rewards: { scrap: 2 }, xp: 3,
      desc: 'Se mantiene lejos y escupe bilis acida.'
    },
    lightHunter: {
      key: 'lightHunter', name: 'Cazador de luz', hp: 52, speed: 82, damage: 13,
      attackCd: 1.1, r: 12, detect: 640, color: '#44515e', accent: '#ffe3a0',
      lightAffinity: true, rewards: { scrap: 2, herbs: 2 }, xp: 4,
      desc: 'Le atrae cualquier fuente de luz. Si la apagas, pierde el rastro.'
    }
  };

  /* Los tipos "elite" del plan de dificultad son variantes de los base. */
  const ELITE_ALIASES = {
    eliteStalker: 'stalker',
    eliteRunner: 'runner',
    eliteBrute: 'brute',
    eliteSpitter: 'spitter',
    eliteLightHunter: 'lightHunter'
  };

  class EnemyManager {
    constructor() {
      this.list = [];
      this.spawnTimer = 0;
      this.waveIndex = 0;
    }

    get aliveCount() {
      let n = 0;
      for (const e of this.list) if (!e.dead) n++;
      return n;
    }

    spawn(typeKey, x, y, opts) {
      opts = opts || {};
      let elite = !!opts.elite;
      let baseKey = typeKey;
      if (ELITE_ALIASES[typeKey]) { baseKey = ELITE_ALIASES[typeKey]; elite = true; }
      if (opts.eliteType) { baseKey = ELITE_ALIASES[opts.eliteType] || opts.eliteType; elite = true; }
      const def = ENEMY_TYPES[baseKey];
      if (!def) return null;

      const diff = opts.diff || TN.Config.difficultyFor(1);
      const hpMul = (diff.hpMul || 1) * (elite ? 2.2 : 1);
      const dmgMul = (diff.dmgMul || 1) * (elite ? 1.5 : 1);
      const scale = elite ? 1.3 : 1;

      const e = {
        id: U.uid('en'),
        type: baseKey,
        typeKey: typeKey,
        name: elite ? def.name + ' de élite' : def.name,
        x: x, y: y,
        r: def.r * scale,
        hp: Math.round(def.hp * hpMul),
        maxHp: Math.round(def.hp * hpMul),
        speed: def.speed * (elite ? 1.08 : 1) * (1 + (diff.day - 1) * 0.004),
        damage: def.damage * dmgMul,
        attackCd: def.attackCd,
        attackTimer: Math.random() * def.attackCd,
        detect: def.detect,
        color: def.color,
        accent: def.accent,
        rewards: def.rewards,
        ranged: !!def.ranged,
        keepDist: def.keepDist || 0,
        lightAffinity: !!def.lightAffinity,
        structureDamage: def.structureDamage || 1,
        isElite: elite,
        isBoss: false,
        dead: false,
        deathTimer: 0,
        hitFlash: 0,
        stun: 0,
        kx: 0, ky: 0,
        aggro: false,
        state: 'idle',
        stateTimer: 0,
        goalX: x, goalY: y,
        path: null, pathIndex: 0, pathTimer: Math.random() * 0.5,
        attackTarget: null,
        facing: Math.random() * Math.PI * 2,
        wanderAngle: Math.random() * Math.PI * 2,
        wanderTimer: 0,
        stuckTimer: 0, lastX: x, lastY: y,
        spawnAnim: 0.45,
        idleSound: 0,
        speedMul: 1,
        targetPlayer: null
      };
      this.list.push(e);
      return e;
    }

    removeDead(dt) {
      const step = dt === undefined ? 0.016 : dt;
      for (let i = this.list.length - 1; i >= 0; i--) {
        const e = this.list[i];
        if (e.dead) {
          e.deathTimer -= step;
          if (e.deathTimer <= 0) this.list.splice(i, 1);
        }
      }
    }

    clear() { this.list.length = 0; }

    nearestTo(x, y, maxDist) {
      let best = null, bd = maxDist === undefined ? Infinity : maxDist * maxDist;
      for (const e of this.list) {
        if (e.dead) continue;
        const d = U.dist2(x, y, e.x, e.y);
        if (d < bd) { bd = d; best = e; }
      }
      return best;
    }

    /* --- dibujado ------------------------------------------------------- */
    draw(ctx, cam) {
      const b = cam.bounds(80);
      for (const e of this.list) {
        if (e.x < b.x0 || e.x > b.x1 || e.y < b.y0 || e.y > b.y1) continue;
        drawEnemy(ctx, e);
      }
    }
  }

  /* Contorno oscuro: las criaturas se leen mejor sobre el bosque. */
  function outline(ctx) {
    ctx.strokeStyle = 'rgba(6,9,6,0.85)';
    ctx.lineWidth = 2;
    ctx.lineJoin = 'round';
    ctx.stroke();
  }

  /* Dibujo procedural: siluetas distinguibles por tipo. */
  function drawEnemy(ctx, e) {
    const s = e.r;
    ctx.save();
    ctx.translate(e.x, e.y);

    // Sombra
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(0, s * 0.65, s * 0.9, s * 0.38, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;

    if (e.dead) {
      // Cadaver desvanecido
      ctx.globalAlpha = Math.max(0, e.deathTimer / 0.6) * 0.7;
      ctx.rotate(1.2);
      ctx.fillStyle = '#3a1d1d';
      ctx.beginPath();
      ctx.ellipse(0, 0, s * 0.9, s * 0.55, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 1;
      ctx.restore();
      return;
    }

    const rot = e.facing;
    ctx.rotate(rot);

    const flash = e.hitFlash > 0;
    const body = flash ? '#ffd9d9' : e.color;
    const accent = flash ? '#ffffff' : e.accent;

    if (e.spawnAnim > 0) {
      // Aparicion: se materializa, pero nunca llega a ser invisible del todo
      ctx.globalAlpha = Math.max(0.35, 1 - e.spawnAnim / 0.45);
    }

    switch (e.type) {
      case 'stalker':
        ctx.fillStyle = body;
        ctx.beginPath();
        ctx.ellipse(0, 0, s * 0.95, s * 0.8, 0, 0, Math.PI * 2);
        ctx.fill();
        outline(ctx);
        // Brazos extendidos
        ctx.strokeStyle = body; ctx.lineWidth = s * 0.28; ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(s * 0.2, -s * 0.6); ctx.lineTo(s * 1.5, -s * 0.45);
        ctx.moveTo(s * 0.2, s * 0.6); ctx.lineTo(s * 1.5, s * 0.45);
        ctx.stroke();
        // Ojos
        ctx.fillStyle = accent;
        ctx.beginPath(); ctx.arc(s * 0.62, -s * 0.28, s * 0.16, 0, 6.3); ctx.fill();
        ctx.beginPath(); ctx.arc(s * 0.62, s * 0.28, s * 0.16, 0, 6.3); ctx.fill();
        break;
      case 'runner':
        ctx.fillStyle = body;
        ctx.beginPath();
        ctx.moveTo(s * 1.25, 0);
        ctx.lineTo(-s * 0.5, -s * 0.7);
        ctx.lineTo(-s * 0.9, 0);
        ctx.lineTo(-s * 0.5, s * 0.7);
        ctx.closePath(); ctx.fill();
        outline(ctx);
        ctx.strokeStyle = accent; ctx.lineWidth = s * 0.2; ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(-s * 0.3, -s * 0.5); ctx.lineTo(-s * 1.3, -s * 0.9);
        ctx.moveTo(-s * 0.3, s * 0.5); ctx.lineTo(-s * 1.3, s * 0.9);
        ctx.stroke();
        ctx.fillStyle = accent;
        ctx.beginPath(); ctx.arc(s * 0.5, 0, s * 0.2, 0, 6.3); ctx.fill();
        break;
      case 'brute':
        ctx.fillStyle = body;
        ctx.beginPath();
        ctx.moveTo(s * 1.1, 0);
        ctx.lineTo(s * 0.1, -s * 1.25);
        ctx.lineTo(-s * 1.0, -s * 0.9);
        ctx.lineTo(-s * 1.0, s * 0.9);
        ctx.lineTo(s * 0.1, s * 1.25);
        ctx.closePath(); ctx.fill();
        outline(ctx);
        ctx.fillStyle = accent;
        ctx.beginPath(); ctx.ellipse(0, 0, s * 0.55, s * 0.62, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#1a1a16';
        ctx.beginPath(); ctx.arc(s * 0.75, -s * 0.28, s * 0.14, 0, 6.3); ctx.fill();
        ctx.beginPath(); ctx.arc(s * 0.75, s * 0.28, s * 0.14, 0, 6.3); ctx.fill();
        break;
      case 'spitter':
        ctx.fillStyle = body;
        ctx.beginPath();
        ctx.ellipse(0, 0, s * 1.0, s * 0.95, 0, 0, Math.PI * 2);
        ctx.fill();
        outline(ctx);
        ctx.fillStyle = accent;
        ctx.beginPath(); ctx.ellipse(-s * 0.3, 0, s * 0.5, s * 0.5, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#d7f0ff';
        ctx.beginPath(); ctx.arc(s * 0.45, -s * 0.35, s * 0.18, 0, 6.3); ctx.fill();
        ctx.beginPath(); ctx.arc(s * 0.45, s * 0.35, s * 0.18, 0, 6.3); ctx.fill();
        break;
      case 'lightHunter':
        ctx.fillStyle = body;
        ctx.beginPath();
        ctx.moveTo(s * 0.9, 0);
        ctx.lineTo(-s * 0.2, -s * 0.6);
        ctx.lineTo(-s * 1.1, -s * 0.25);
        ctx.lineTo(-s * 1.1, s * 0.25);
        ctx.lineTo(-s * 0.2, s * 0.6);
        ctx.closePath(); ctx.fill();
        outline(ctx);
        // Cabeza-lampara brillante
        const glow = ctx.createRadialGradient(s * 0.9, 0, 0, s * 0.9, 0, s * 1.6);
        glow.addColorStop(0, accent);
        glow.addColorStop(1, 'rgba(255,217,138,0)');
        ctx.fillStyle = glow;
        ctx.beginPath(); ctx.arc(s * 0.9, 0, s * 1.6, 0, 6.3); ctx.fill();
        ctx.fillStyle = '#fff6d8';
        ctx.beginPath(); ctx.arc(s * 0.9, 0, s * 0.32, 0, 6.3); ctx.fill();
        break;
      default:
        ctx.fillStyle = body;
        ctx.beginPath(); ctx.arc(0, 0, s, 0, 6.3); ctx.fill();
        outline(ctx);
        break;
    }

    if (e.isElite) {
      ctx.globalAlpha = 0.55 + Math.sin(performance.now() / 180) * 0.15;
      ctx.strokeStyle = '#ffb347';
      ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(0, 0, s * 1.35, 0, 6.3); ctx.stroke();
      ctx.globalAlpha = 1;
    }

    ctx.restore();

    // Barra de vida de enemigos damaged (solo si es grande o herido)
    if (!e.dead && e.hp < e.maxHp && !e.boss) {
      const w = s * 2.2;
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(e.x - w / 2, e.y - s * 1.9, w, 3.5);
      ctx.fillStyle = '#d64646';
      ctx.fillRect(e.x - w / 2, e.y - s * 1.9, w * (e.hp / e.maxHp), 3.5);
    }
  }

  const Enemies = { Manager: EnemyManager, TYPES: ENEMY_TYPES, drawEnemy: drawEnemy };
  Enemies.ENEMY_TYPES = ENEMY_TYPES;
  Enemies.ELITE_ALIASES = ELITE_ALIASES;
  return Enemies;
})();
