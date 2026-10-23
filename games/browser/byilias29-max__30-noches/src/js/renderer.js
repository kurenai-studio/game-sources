/* ==========================================================================
   30 NOCHES - renderer.js
   Dibujado procedural del mundo: terreno, decoracion, obstaculos, estructuras,
   entidades, efectos, clima e iluminacion.
   ========================================================================== */
window.TN = window.TN || {};

TN.Renderer = (function () {
  const U = TN.Utils;

  function draw(ctx, game) {
    const cam = game.camera;
    const vw = game.viewW, vh = game.viewH;

    ctx.save();
    ctx.setTransform(game.dpr, 0, 0, game.dpr, 0, 0);
    ctx.clearRect(0, 0, vw, vh);
    // Transformacion de camara: todo lo que sigue usa coordenadas de mundo.
    ctx.translate(
      -cam.x + vw / 2 + cam.shakeX,
      -cam.y + vh / 2 + cam.shakeY
    );

    drawGround(ctx, game);
    drawDecor(ctx, game);

    // Objetos ordenados por profundidad
    const items = [];
    const b = cam.bounds(120);

    for (const o of game.world.obstacles) {
      if (o.kind === 'tree' || o.kind === 'rock') {
        if (o.x < b.x0 || o.x > b.x1 || o.y < b.y0 || o.y > b.y1) continue;
        items.push({ y: o.y, draw: drawObstacle, ref: o });
      }
    }
    for (const p of game.world.pois) {
      if (p.x < b.x0 || p.x > b.x1 || p.y < b.y0 || p.y > b.y1) continue;
      items.push({ y: p.y, draw: drawPOI, ref: p });
    }
    for (const n of game.resources.nodes) {
      if (n.depleted) continue;
      if (n.x < b.x0 || n.x > b.x1 || n.y < b.y0 || n.y > b.y1) continue;
      if (n.kind === 'wood' || n.kind === 'stone') continue;   // ya son obstaculos
      items.push({ y: n.y, draw: drawResourceNode, ref: n });
    }
    for (const bl of game.buildings.list) {
      if (bl.x < b.x0 || bl.x > b.x1 || bl.y < b.y0 || bl.y > b.y1) continue;
      items.push({ y: bl.y, draw: drawBuildingProxy, ref: bl });
    }
    for (const e of game.enemies.list) {
      if (e.x < b.x0 || e.x > b.x1 || e.y < b.y0 || e.y > b.y1) continue;
      items.push({ y: e.y, draw: drawEnemyProxy, ref: e });
    }
    if (game.player) items.push({ y: game.player.y, draw: drawPlayerProxy, ref: game.player });

    // Base: generador y antena
    items.push({ y: game.generator.y, draw: drawGenerator, ref: game.generator });
    items.push({ y: game.quests.antenna.y, draw: drawAntenna, ref: game.quests.antenna });

    items.sort((p, q) => p.y - q.y);
    for (const it of items) it.draw(ctx, it.ref, game);

    game.projectiles.draw(ctx, cam);
    game.particles.draw(ctx, cam);
    drawEffects(ctx, game);
    drawFloaters(ctx, game);
    drawBuildGhost(ctx, game);

    ctx.restore();

    // Iluminacion (fuera de la transformacion dpr: usa pixeles logicos)
    ctx.save();
    ctx.setTransform(game.dpr, 0, 0, game.dpr, 0, 0);
    game.lighting.draw(ctx, game);
    drawWeather(ctx, game);
    drawVignette(ctx, game);
    ctx.restore();
  }

  /* --- Terreno ---------------------------------------------------------- */
  function drawGround(ctx, game) {
    const w = game.world;
    const cam = game.camera;
    const b = cam.bounds(64);
    const t = w.tile;
    const x0 = Math.max(0, Math.floor(b.x0 / t)), x1 = Math.min(w.cols - 1, Math.floor(b.x1 / t));
    const y0 = Math.max(0, Math.floor(b.y0 / t)), y1 = Math.min(w.rows - 1, Math.floor(b.y1 / t));
    ctx.fillStyle = '#16241a';
    ctx.fillRect(b.x0, b.y0, b.x1 - b.x0, b.y1 - b.y0);
    for (let ty = y0; ty <= y1; ty++) {
      for (let tx = x0; tx <= x1; tx++) {
        const wx = tx * t, wy = ty * t;
        ctx.fillStyle = w.tileColor(tx, ty);
        ctx.fillRect(wx, wy, t + 1, t + 1);
      }
    }
    // Senderos: detalle de tierra
    ctx.fillStyle = 'rgba(0,0,0,0.10)';
    for (let ty = y0; ty <= y1; ty++) {
      for (let tx = x0; tx <= x1; tx++) {
        if (w.tiles[ty * w.cols + tx] !== 3) continue;
        if (U.hash2(tx, ty, 3) > 0.55) ctx.fillRect(tx * t + 4, ty * t + 4, t - 8, t - 8);
      }
    }
  }

  function drawDecor(ctx, game) {
    const cam = game.camera;
    const b = cam.bounds(60);
    ctx.save();
    for (const d of game.world.decor) {
      if (d.x < b.x0 || d.x > b.x1 || d.y < b.y0 || d.y > b.y1) continue;
      if (d.kind === 'grass') {
        ctx.strokeStyle = 'rgba(90,130,70,0.55)';
        ctx.lineWidth = 1.4;
        ctx.beginPath();
        ctx.moveTo(d.x - 3, d.y); ctx.lineTo(d.x - 4, d.y - 6 * d.s);
        ctx.moveTo(d.x, d.y); ctx.lineTo(d.x + 1, d.y - 8 * d.s);
        ctx.moveTo(d.x + 3, d.y); ctx.lineTo(d.x + 4, d.y - 5 * d.s);
        ctx.stroke();
      } else if (d.kind === 'twig') {
        ctx.strokeStyle = 'rgba(90,70,45,0.6)';
        ctx.lineWidth = 1.6;
        ctx.beginPath();
        ctx.moveTo(d.x - 5 * d.s, d.y); ctx.lineTo(d.x + 5 * d.s, d.y - 2);
        ctx.stroke();
      } else if (d.kind === 'ruinSign') {
        ctx.fillStyle = 'rgba(190,180,150,0.75)';
        ctx.font = '10px "Trebuchet MS", sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(d.label, d.x, d.y);
      }
    }
    ctx.restore();
  }

  /* --- Obstaculos -------------------------------------------------------- */
  function drawObstacle(ctx, o, game) {
    if (o.kind === 'tree') drawTree(ctx, o);
    else if (o.kind === 'rock') drawRock(ctx, o);
  }

  function drawTree(ctx, o) {
    const r = o.r;
    const s = o.scale || 1;
    ctx.save();
    ctx.translate(o.x, o.y);
    // Sombra
    ctx.globalAlpha = 0.28;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(4, 4, r * 1.5 * s, r * 0.6 * s, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
    // Tronco
    ctx.fillStyle = '#3a2a1c';
    ctx.fillRect(-r * 0.28, -r * 0.4, r * 0.56, r * 1.5);
    // Copa
    const base = o.variant % 2 === 0 ? '#1d3320' : '#223a22';
    ctx.fillStyle = base;
    const cy = -r * (1.05 * s);
    ctx.beginPath();
    ctx.arc(0, cy, r * 1.35 * s, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(-r * 0.85 * s, cy + r * 0.5 * s, r * 0.95 * s, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(r * 0.9 * s, cy + r * 0.45 * s, r * 0.9 * s, 0, Math.PI * 2);
    ctx.fill();
    // Brillos
    ctx.fillStyle = 'rgba(120,160,90,0.22)';
    ctx.beginPath();
    ctx.arc(-r * 0.4 * s, cy - r * 0.5 * s, r * 0.55 * s, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  function drawRock(ctx, o) {
    const r = o.r;
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.globalAlpha = 0.3;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(2, 3, r * 1.1, r * 0.5, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
    const v = o.variant % 3;
    ctx.fillStyle = v === 0 ? '#54585c' : (v === 1 ? '#4b4f53' : '#5c6065');
    ctx.beginPath();
    const pts = 7;
    for (let i = 0; i < pts; i++) {
      const a = (i / pts) * Math.PI * 2;
      const rr = r * (0.85 + U.hash2(i, v, 11) * 0.35);
      const px = Math.cos(a) * rr, py = Math.sin(a) * rr * 0.82;
      if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
    }
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = 'rgba(255,255,255,0.08)';
    ctx.beginPath();
    ctx.ellipse(-r * 0.3, -r * 0.35, r * 0.45, r * 0.25, -0.4, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  /* --- Puntos de interes ------------------------------------------------ */
  function drawPOI(ctx, p, game) {
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rot || 0);
    ctx.globalAlpha = 0.3;
    ctx.fillStyle = '#000';
    ctx.fillRect(-p.hw + 5, -p.hh + 7, p.hw * 2, p.hh * 2);
    ctx.globalAlpha = 1;

    if (p.id === 'wreck') {
      // Furgoneta volcada
      ctx.fillStyle = '#6b4a3a';
      ctx.fillRect(-p.hw, -p.hh * 0.7, p.hw * 2, p.hh * 1.2);
      ctx.fillStyle = '#4d3428';
      ctx.fillRect(-p.hw + 8, -p.hh * 0.45, p.hw * 0.8, p.hh * 0.7);
      ctx.fillStyle = '#22303a';
      ctx.fillRect(-p.hw + 10, -p.hh * 0.38, p.hw * 0.7, p.hh * 0.5);
      ctx.fillStyle = '#22201c';
      ctx.beginPath(); ctx.arc(-p.hw + 12, p.hh * 0.6, 9, 0, 6.3); ctx.fill();
      ctx.beginPath(); ctx.arc(p.hw - 14, p.hh * 0.6, 9, 0, 6.3); ctx.fill();
    } else if (p.id === 'bunker') {
      ctx.fillStyle = '#4d5148';
      ctx.fillRect(-p.hw, -p.hh, p.hw * 2, p.hh * 2);
      ctx.fillStyle = '#3b3f38';
      ctx.fillRect(-p.hw + 8, -p.hh + 10, p.hw * 2 - 16, p.hh * 2 - 20);
      ctx.fillStyle = '#22251f';
      ctx.fillRect(-12, p.hh - 26, 24, 22);         // entrada
      ctx.fillStyle = '#6d7268';
      ctx.fillRect(-p.hw, -p.hh, p.hw * 2, 6);
    } else if (p.id === 'tower') {
      ctx.strokeStyle = '#5a4630';
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.moveTo(-p.hw * 0.6, p.hh); ctx.lineTo(0, -p.hh);
      ctx.moveTo(p.hw * 0.6, p.hh); ctx.lineTo(0, -p.hh);
      ctx.moveTo(-p.hw * 0.45, -p.hh * 0.2); ctx.lineTo(p.hw * 0.45, -p.hh * 0.2);
      ctx.moveTo(-p.hw * 0.25, -p.hh * 0.6); ctx.lineTo(p.hw * 0.25, -p.hh * 0.6);
      ctx.stroke();
      ctx.fillStyle = '#8a949c';
      ctx.fillRect(-8, -p.hh - 12, 16, 14);
      ctx.fillStyle = p.taken ? '#3a3a3a' : '#8be9ff';
      ctx.beginPath(); ctx.arc(0, -p.hh - 5, 4, 0, 6.3); ctx.fill();
    }
    ctx.restore();

    // Etiqueta
    if (game.camera.isVisible(p.x, p.y, 200)) {
      ctx.save();
      ctx.font = '11px "Trebuchet MS", sans-serif';
      ctx.textAlign = 'center';
      ctx.fillStyle = 'rgba(0,0,0,0.55)';
      const label = p.taken ? p.name + ' (vaciado)' : p.name;
      const wdt = ctx.measureText(label).width + 12;
      ctx.fillRect(p.x - wdt / 2, p.y - p.hh - 34, wdt, 16);
      ctx.fillStyle = p.discovered || p.taken ? '#d9c88a' : '#7d8a78';
      ctx.fillText(label, p.x, p.y - p.hh - 22);
      ctx.restore();
    }
  }

  /* --- Recursos ---------------------------------------------------------- */
  function drawResourceNode(ctx, n, game) {
    ctx.save();
    ctx.translate(n.x, n.y);
    ctx.globalAlpha = 0.28;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(2, 4, 11, 5, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;

    if (n.kind === 'herb') {
      ctx.fillStyle = '#2c4526';
      ctx.beginPath(); ctx.arc(0, 0, 10, 0, 6.3); ctx.fill();
      ctx.fillStyle = '#7fbf5a';
      for (let i = 0; i < 5; i++) {
        const a = (i / 5) * Math.PI * 2 + n.variant;
        ctx.beginPath();
        ctx.ellipse(Math.cos(a) * 4, Math.sin(a) * 3 - 2, 4, 2.4, a, 0, 6.3);
        ctx.fill();
      }
      if (n.variant > 0.5) {
        ctx.fillStyle = '#d8e87a';
        ctx.beginPath(); ctx.arc(1, -4, 2, 0, 6.3); ctx.fill();
      }
    } else if (n.kind === 'scrap') {
      ctx.fillStyle = '#7a5a33';
      ctx.fillRect(-9, -9, 18, 18);
      ctx.fillStyle = '#5d4426';
      ctx.fillRect(-9, -9, 18, 4);
      ctx.strokeStyle = '#3f2f1c';
      ctx.lineWidth = 2;
      ctx.strokeRect(-9, -9, 18, 18);
      ctx.fillStyle = '#9aa3ab';
      ctx.fillRect(-4, -3, 8, 4);
    }
    ctx.restore();
  }

  /* --- Base -------------------------------------------------------------- */
  function drawGenerator(ctx, gen, game) {
    const w = CFGGEN.w / 2, h = CFGGEN.h / 2;
    ctx.save();
    ctx.translate(gen.x, gen.y);
    ctx.globalAlpha = 0.32;
    ctx.fillStyle = '#000';
    ctx.fillRect(-w + 4, -h + 6, w * 2, h * 2);
    ctx.globalAlpha = 1;

    // Carcasa
    ctx.fillStyle = gen.hitFlash > 0 ? '#ffd9a0' : '#3f5a4a';
    ctx.fillRect(-w, -h, w * 2, h * 2);
    ctx.fillStyle = '#2c4034';
    ctx.fillRect(-w + 4, -h + 4, w * 2 - 8, h * 2 - 14);
    // Motor
    ctx.fillStyle = '#546b5c';
    ctx.fillRect(-w + 8, -h + 8, 16, h * 2 - 20);
    // Chimenea
    ctx.fillStyle = '#25332a';
    ctx.fillRect(w - 16, -h - 12, 8, 14);
    // Ventilador
    const spin = gen.dead ? 0 : performance.now() / 220;
    ctx.save();
    ctx.translate(-w + 16, 2);
    ctx.rotate(spin);
    ctx.strokeStyle = gen.dead ? '#3a3a3a' : '#9fd4b0';
    ctx.lineWidth = 2;
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * Math.PI * 2;
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(Math.cos(a) * 9, Math.sin(a) * 9);
      ctx.stroke();
    }
    ctx.restore();
    // Indicador
    const hpRatio = Math.max(0, gen.hp / CFGGEN.maxHp);
    ctx.fillStyle = hpRatio > 0.5 ? '#8fe36a' : (hpRatio > 0.25 ? '#e0c04a' : '#e05a4a');
    ctx.beginPath(); ctx.arc(w - 12, -h + 8, 3.4, 0, 6.3); ctx.fill();

    // Luz del generador
    if (!gen.dead) {
      const g = ctx.createRadialGradient(0, 0, 2, 0, 0, 40);
      g.addColorStop(0, 'rgba(255,190,120,0.28)');
      g.addColorStop(1, 'rgba(255,190,120,0)');
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(0, 0, 40, 0, 6.3); ctx.fill();
    }
    ctx.restore();

    // Barra de vida sobre el generador
    const bw = 56;
    ctx.fillStyle = 'rgba(0,0,0,0.65)';
    ctx.fillRect(gen.x - bw / 2, gen.y - h - 16, bw, 5);
    ctx.fillStyle = hpRatio > 0.5 ? '#6ad06a' : (hpRatio > 0.25 ? '#d0b04a' : '#d04a4a');
    ctx.fillRect(gen.x - bw / 2, gen.y - h - 16, bw * hpRatio, 5);
    ctx.font = '10px "Trebuchet MS", sans-serif';
    ctx.textAlign = 'center';
    ctx.fillStyle = '#e8dfc8';
    ctx.fillText('GENERADOR ' + Math.ceil(Math.max(0, gen.hp)) + '/' + CFGGEN.maxHp, gen.x, gen.y - h - 21);
  }

  function drawAntenna(ctx, ant, game) {
    ctx.save();
    ctx.translate(ant.x, ant.y);
    ctx.globalAlpha = 0.3;
    ctx.fillStyle = '#000';
    ctx.beginPath(); ctx.ellipse(3, 5, 18, 7, 0, 0, 6.3); ctx.fill();
    ctx.globalAlpha = 1;

    // Mástil
    ctx.strokeStyle = ant.repaired ? '#8be9ff' : '#6a6257';
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(-10, 12); ctx.lineTo(0, -26);
    ctx.moveTo(10, 12); ctx.lineTo(0, -26);
    ctx.moveTo(-6, -2); ctx.lineTo(6, -2);
    ctx.stroke();
    // Parabola
    ctx.fillStyle = ant.repaired ? '#bfe9ff' : '#55504a';
    ctx.beginPath();
    ctx.arc(0, -26, 9, Math.PI * 0.15, Math.PI * 0.85, true);
    ctx.fill();
    // Base
    ctx.fillStyle = '#3b3a35';
    ctx.fillRect(-12, 8, 24, 8);

    if (ant.repaired && !ant.activated) {
      const pulse = 0.5 + 0.5 * Math.sin(performance.now() / 260);
      const g = ctx.createRadialGradient(0, -26, 0, 0, -26, 34);
      g.addColorStop(0, 'rgba(139,233,255,' + (0.35 * pulse) + ')');
      g.addColorStop(1, 'rgba(139,233,255,0)');
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(0, -26, 34, 0, 6.3); ctx.fill();
    }
    if (ant.activated) {
      const pulse = 0.5 + 0.5 * Math.sin(performance.now() / 160);
      const g = ctx.createRadialGradient(0, -26, 0, 0, -26, 120);
      g.addColorStop(0, 'rgba(255,255,255,' + (0.8 * pulse) + ')');
      g.addColorStop(0.4, 'rgba(139,233,255,' + (0.4 * pulse) + ')');
      g.addColorStop(1, 'rgba(139,233,255,0)');
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(0, -26, 120, 0, 6.3); ctx.fill();
    }
    ctx.restore();

    ctx.font = '10px "Trebuchet MS", sans-serif';
    ctx.textAlign = 'center';
    ctx.fillStyle = ant.repaired ? '#8be9ff' : '#9a948a';
    ctx.fillText(ant.activated ? 'ANTENA ACTIVA' : (ant.repaired ? 'ANTENA LISTA' : 'ANTENA ROTA'), ant.x, ant.y + 26);
  }

  /* --- Proxies de dibujado (ordenados por Y) ----------------------------- */
  function drawBuildingProxy(ctx, b, game) {
    TN.Buildings.drawBuilding(ctx, b, game);
  }

  function drawEnemyProxy(ctx, e, game) {
    if (e.isBoss && e.boss) TN.Bosses.drawBoss(ctx, e);
    else TN.Enemies.drawEnemy(ctx, e);
  }

  function drawPlayerProxy(ctx, p, game) {
    p.draw(ctx, game);
  }

  /* --- Efectos ------------------------------------------------------------ */
  function drawEffects(ctx, game) {
    for (const fx of game.effects) {
      const t = Math.max(0, fx.life / fx.maxLife);
      ctx.save();
      if (fx.kind === 'slash') {
        ctx.globalAlpha = t * 0.7;
        ctx.strokeStyle = fx.color || '#fff';
        ctx.lineWidth = 4 * t + 1;
        ctx.beginPath();
        ctx.arc(fx.x, fx.y, fx.radius * 0.72, fx.angle - fx.arc / 2, fx.angle + fx.arc / 2);
        ctx.stroke();
      } else if (fx.kind === 'blast') {
        ctx.globalAlpha = t * 0.55;
        ctx.fillStyle = fx.color || '#ffb066';
        ctx.beginPath();
        ctx.arc(fx.x, fx.y, fx.radius * (1 - t * 0.55), 0, Math.PI * 2);
        ctx.fill();
      } else if (fx.kind === 'telegraphLine') {
        ctx.globalAlpha = 0.22 + (1 - fx.progress) * 0.2;
        ctx.fillStyle = fx.color || '#ff6b6b';
        ctx.translate(fx.x, fx.y);
        ctx.rotate(fx.angle);
        ctx.fillRect(0, -fx.width / 2, fx.length, fx.width);
      } else if (fx.kind === 'telegraphCircle') {
        ctx.globalAlpha = 0.18 + (1 - fx.progress) * 0.22;
        ctx.strokeStyle = fx.color || '#ffb066';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(fx.x, fx.y, fx.radius * (0.4 + fx.progress * 0.6), 0, Math.PI * 2);
        ctx.stroke();
      } else if (fx.kind === 'telegraphCone') {
        ctx.globalAlpha = 0.14;
        ctx.fillStyle = fx.color || '#c58bff';
        ctx.translate(fx.x, fx.y);
        ctx.rotate(fx.angle);
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.arc(0, 0, fx.radius, -0.5, 0.5);
        ctx.closePath();
        ctx.fill();
      }
      ctx.restore();
    }
  }

  function drawFloaters(ctx, game) {
    ctx.save();
    ctx.textAlign = 'center';
    for (const f of game.floaters) {
      const t = Math.max(0, f.life / f.maxLife);
      ctx.globalAlpha = t;
      ctx.font = 'bold ' + f.size + 'px "Trebuchet MS", sans-serif';
      ctx.fillStyle = 'rgba(0,0,0,0.75)';
      ctx.fillText(f.text, f.x + 1, f.y + 1);
      ctx.fillStyle = f.color;
      ctx.fillText(f.text, f.x, f.y);
    }
    ctx.restore();
  }

  /* --- Previsualizacion de construccion ---------------------------------- */
  function drawBuildGhost(ctx, game) {
    if (!game.buildMode || game.ui.current !== 'build') return;
    const def = TN.Buildings.DEFINITIONS[game.buildMode];
    if (!def) return;
    const g = game.buildGhost;
    const hw = def.w / 2, hh = def.h / 2;
    ctx.save();
    ctx.globalAlpha = 0.55;
    ctx.fillStyle = g.valid ? 'rgba(120,220,120,0.55)' : 'rgba(220,90,80,0.5)';
    ctx.fillRect(g.x - hw, g.y - hh, hw * 2, hh * 2);
    ctx.globalAlpha = 0.95;
    ctx.strokeStyle = g.valid ? '#8fe36a' : '#e05a4a';
    ctx.lineWidth = 2;
    ctx.strokeRect(g.x - hw, g.y - hh, hw * 2, hh * 2);
    // Cuadricula
    ctx.globalAlpha = 0.12;
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 1;
    ctx.strokeRect(g.x - hw - 6, g.y - hh - 6, hw * 2 + 12, hh * 2 + 12);
    ctx.globalAlpha = 1;
    ctx.font = '11px "Trebuchet MS", sans-serif';
    ctx.textAlign = 'center';
    ctx.fillStyle = g.valid ? '#8fe36a' : '#e05a4a';
    ctx.fillText(def.name + ' - ' + (g.valid ? 'clic para colocar' : (g.reason || 'no se puede aqui')), g.x, g.y - hh - 10);
    ctx.restore();
  }

  /* --- Clima y viñeta ---------------------------------------------------- */
  function drawWeather(ctx, game) {
    const vw = game.viewW, vh = game.viewH;
    if (game.weather.storm) {
      ctx.save();
      ctx.fillStyle = 'rgba(40,55,70,0.30)';
      ctx.fillRect(0, 0, vw, vh);
      // lluvia
      ctx.strokeStyle = 'rgba(180,200,220,0.35)';
      ctx.lineWidth = 1;
      const t = performance.now() / 9;
      for (let i = 0; i < 90; i++) {
        const x = (i * 137 + t) % (vw + 60) - 30;
        const y = (i * 71 + t * 2.2) % (vh + 60) - 30;
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.lineTo(x - 4, y + 12);
        ctx.stroke();
      }
      ctx.restore();
    }
    if (game.weather.fog) {
      ctx.save();
      ctx.fillStyle = 'rgba(180,190,200,0.16)';
      ctx.fillRect(0, 0, vw, vh);
      ctx.restore();
    }
    if (game.weather.blackout) {
      ctx.save();
      ctx.fillStyle = 'rgba(0,0,20,0.25)';
      ctx.fillRect(0, 0, vw, vh);
      ctx.restore();
    }
  }

  function drawVignette(ctx, game) {
    const vw = game.viewW, vh = game.viewH;
    const g = ctx.createRadialGradient(vw / 2, vh / 2, Math.min(vw, vh) * 0.35, vw / 2, vh / 2, Math.max(vw, vh) * 0.75);
    g.addColorStop(0, 'rgba(0,0,0,0)');
    g.addColorStop(1, 'rgba(0,0,0,0.55)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, vw, vh);
  }

  const CFGGEN = TN.Config.GENERATOR;

  return { draw: draw };
})();
