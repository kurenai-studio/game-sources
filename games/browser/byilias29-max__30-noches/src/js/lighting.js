/* ==========================================================================
   30 NOCHES - lighting.js
   Sistema de luz: mascara de oscuridad + halogenos cálidos.
   La luz tiene consequences mecanicas (los cazadores de luz la detectan).
   ========================================================================== */
window.TN = window.TN || {};

TN.Lighting = (function () {
  const U = TN.Utils;

  class LightingSystem {
    constructor() {
      this.lights = [];
      this.canvas = document.createElement('canvas');
      this.ctx = this.canvas.getContext('2d');
      this.scale = 0.5;
      this.enabled = true;
    }

    /* Recolecta las fuentes de luz activas del mundo. */
    collect(game) {
      this.lights.length = 0;
      const pl = game.player;
      if (pl && pl.flashlightOn && pl.flashlightBattery > 0 && !pl.dead) {
        const radius = TN.Config.FLASHLIGHT.radius *
          (game.upgrades ? game.upgrades.flashlightRadiusMultiplier() : 1);
        this.lights.push({
          x: pl.x, y: pl.y, radius: radius,
          color: '#ffd9a0', intensity: 1, kind: 'player',
          angle: pl.aimAngle, cone: true
        });
      }
      const buildings = (game.buildings && game.buildings.list) ? game.buildings.list : [];
      for (const b of buildings) {
        if (b.dead) continue;
        if (b.type === 'lamp' && !b.disabled) {
          this.lights.push({ x: b.x, y: b.y - 12, radius: 190, color: '#ffd98a', intensity: 0.9, kind: 'lamp', building: b });
        } else if (b.type === 'forge') {
          this.lights.push({ x: b.x, y: b.y, radius: 120, color: '#ff9a4a', intensity: 0.8, kind: 'forge', building: b });
        }
      }
      const gen = game.generator;
      if (gen && !gen.dead) {
        this.lights.push({ x: gen.x, y: gen.y, radius: 150, color: '#ffb066', intensity: 0.7, kind: 'generator' });
      }
      if (game.quests && game.quests.antenna.repaired && !game.quests.antenna.activated) {
        this.lights.push({ x: game.quests.antenna.x, y: game.quests.antenna.y, radius: 110, color: '#8be9ff', intensity: 0.6, kind: 'antenna' });
      }
      return this.lights;
    }

    /* Iluminacion ambiental considerando clima y eventos. */
    ambient(game) {
      // Sin ciclo dia/noche todavia (menu) se asume luz de dia.
      let a = (game.dayNight && typeof game.dayNight.lightLevel === 'number') ? game.dayNight.lightLevel : 1;
      // El clima puede no existir todavia (menu, carga, refactor).
      const weather = game.weather || {};
      if (weather.storm) a *= 0.55;
      if (weather.fog) a *= 0.75;
      if (weather.blackout) a *= 0.8;
      return U.clamp(a, 0.05, 1);
    }

    draw(ctx, game) {
      const ambient = this.ambient(game);
      const darkness = U.clamp((1 - ambient) * 0.94, 0, 0.94);
      const vw = game.viewW, vh = game.viewH;

      if (darkness > 0.02) {
        const s = this.scale;
        const lw = Math.max(1, Math.ceil(vw * s)), lh = Math.max(1, Math.ceil(vh * s));
        if (this.canvas.width !== lw || this.canvas.height !== lh) {
          this.canvas.width = lw; this.canvas.height = lh;
        }
        const lc = this.ctx;
        lc.clearRect(0, 0, lw, lh);
        lc.globalCompositeOperation = 'source-over';
        lc.fillStyle = 'rgba(2,4,8,' + darkness + ')';
        lc.fillRect(0, 0, lw, lh);

        lc.globalCompositeOperation = 'destination-out';
        for (const light of this.lights) {
          const p = game.camera.worldToScreen(light.x, light.y);
          const r = Math.max(2, light.radius * s);
          if (p.x + r < 0 || p.x - r > lw || p.y + r < 0 || p.y - r > lh) continue;
          const g = lc.createRadialGradient(p.x, p.y, 0, p.x, p.y, r);
          g.addColorStop(0, 'rgba(0,0,0,1)');
          g.addColorStop(0.35, 'rgba(0,0,0,' + (0.92 * light.intensity) + ')');
          g.addColorStop(1, 'rgba(0,0,0,0)');
          lc.fillStyle = g;
          lc.beginPath();
          lc.arc(p.x, p.y, r, 0, Math.PI * 2);
          lc.fill();
          // cono de la linterna
          if (light.cone) {
            lc.save();
            const cg = lc.createRadialGradient(p.x, p.y, r * 0.15, p.x, p.y, r * 1.55);
            cg.addColorStop(0, 'rgba(0,0,0,0.95)');
            cg.addColorStop(1, 'rgba(0,0,0,0)');
            lc.fillStyle = cg;
            lc.beginPath();
            lc.moveTo(p.x, p.y);
            lc.arc(p.x, p.y, r * 1.55, light.angle - 0.55, light.angle + 0.55);
            lc.closePath();
            lc.fill();
            lc.restore();
          }
        }
        lc.globalCompositeOperation = 'source-over';
        ctx.drawImage(this.canvas, 0, 0, lw, lh, 0, 0, vw, vh);
      }

      // Resplandor calido
      ctx.save();
      ctx.globalCompositeOperation = 'lighter';
      for (const light of this.lights) {
        const p = game.camera.worldToScreen(light.x, light.y);
        const r = light.radius * 0.45;
        if (p.x + r < 0 || p.x - r > vw || p.y + r < 0 || p.y - r > vh) continue;
        const g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, r);
        g.addColorStop(0, hexAlpha(light.color, 0.16 * light.intensity));
        g.addColorStop(1, hexAlpha(light.color, 0));
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.arc(p.x, p.y, r, 0, Math.PI * 2); ctx.fill();
      }
      ctx.restore();
    }
  }

  function hexAlpha(hex, a) {
    if (!hex || hex[0] !== '#') return 'rgba(255,255,255,' + a + ')';
    let h = hex.slice(1);
    if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
    const r = parseInt(h.slice(0, 2), 16), g = parseInt(h.slice(2, 4), 16), b = parseInt(h.slice(4, 6), 16);
    return 'rgba(' + r + ',' + g + ',' + b + ',' + a + ')';
  }

  return { System: LightingSystem, hexAlpha: hexAlpha };
})();
