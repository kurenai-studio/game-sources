window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;

  // A fallen star: a soft halo, slow twinkle rays, a five-pointed body with a
  // warm core and a sparkle that winks now and then. Golden stars are larger,
  // whiter and spin a crown of rays. `size` is the cell size in pixels.
  function star(ctx, x, y, size, t, opts) {
    opts = opts || {};
    var phase = opts.phase || 0;
    var bob = Math.sin(t * 2.4 + phase) * size * 0.05;
    var golden = !!opts.golden;
    var s = size * (opts.scale || 1) * (1 + Math.sin(t * 4 + phase) * 0.04) * (golden ? 1.12 : 1);
    y += bob;
    if (!opts.noHalo) {
      var halo = ctx.createRadialGradient(x, y, 0, x, y, s * 1.35);
      halo.addColorStop(0, golden ? "rgba(255,246,214,.7)" : "rgba(255,214,128,.5)");
      halo.addColorStop(0.35, golden ? "rgba(255,214,102,.28)" : "rgba(255,190,90,.18)");
      halo.addColorStop(1, "rgba(255,190,90,0)");
      ctx.fillStyle = halo;
      ctx.fillRect(x - s * 1.4, y - s * 1.4, s * 2.8, s * 2.8);
    }
    ctx.save();
    ctx.translate(x, y);
    // twinkle rays: a long cross and a short diagonal cross
    var tw = 0.65 + 0.35 * Math.sin(t * 3.1 + phase * 2);
    ctx.globalCompositeOperation = "lighter";
    ctx.fillStyle = golden ? "rgba(255,248,220,.75)" : "rgba(255,232,170,.6)";
    for (var k = 0; k < 4; k++) {
      var len = (k % 2 ? 0.95 : 1.15) * s * tw * (golden ? 1.2 : 1);
      ctx.save();
      ctx.rotate(k * Math.PI / 2 + (golden ? t * 0.5 : 0));
      ctx.beginPath();
      ctx.moveTo(-s * 0.05, 0); ctx.lineTo(0, -len); ctx.lineTo(s * 0.05, 0);
      ctx.fill();
      ctx.restore();
    }
    if (golden) {
      ctx.fillStyle = "rgba(255,236,153,.22)";
      for (var j = 0; j < 8; j++) {
        ctx.save();
        ctx.rotate(t * 0.7 + j * TAU / 8 + TAU / 16);
        ctx.beginPath();
        ctx.moveTo(0, 0); ctx.lineTo(-s * 0.12, -s * 1.0); ctx.lineTo(s * 0.12, -s * 1.0);
        ctx.fill();
        ctx.restore();
      }
    }
    ctx.globalCompositeOperation = "source-over";
    // body
    var r = s * 0.42;
    ctx.rotate(Math.sin(t * 1.3 + phase) * 0.12);
    ctx.shadowColor = golden ? "#fff3bf" : "#ffc861";
    ctx.shadowBlur = s * 0.35;
    var g = ctx.createRadialGradient(0, -r * 0.1, 0, 0, 0, r * 1.05);
    g.addColorStop(0, "#fffef6");
    g.addColorStop(0.45, golden ? "#ffe9a3" : "#ffd98a");
    g.addColorStop(1, golden ? "#f5b700" : "#e8a33a");
    ctx.fillStyle = g;
    LM.draw.poly(ctx, 0, r * 0.06, r * 1.08, 5, -Math.PI / 2, 0.48);
    ctx.fill();
    ctx.shadowBlur = 0;
    // inner core
    ctx.fillStyle = "rgba(255,255,255,.85)";
    ctx.beginPath();
    ctx.arc(0, r * 0.06, r * 0.26, 0, TAU);
    ctx.fill();
    ctx.restore();
    // a sparkle that winks at the upper right
    var wink = Math.max(0, Math.sin(t * 1.7 + phase * 3) * 2 - 1.2);
    if (wink > 0) {
      var sx = x + s * 0.34, sy = y - s * 0.36, sl = s * 0.22 * wink;
      ctx.fillStyle = "rgba(255,255,255," + (0.9 * wink).toFixed(3) + ")";
      ctx.beginPath();
      ctx.moveTo(sx, sy - sl); ctx.lineTo(sx + sl * 0.2, sy); ctx.lineTo(sx, sy + sl); ctx.lineTo(sx - sl * 0.2, sy);
      ctx.closePath(); ctx.fill();
      ctx.beginPath();
      ctx.moveTo(sx - sl, sy); ctx.lineTo(sx, sy + sl * 0.2); ctx.lineTo(sx + sl, sy); ctx.lineTo(sx, sy - sl * 0.2);
      ctx.closePath(); ctx.fill();
    }
  }

  // Power-up glyphs, shared by the board, the HUD and the help screens.
  var glyphs = {
    // Hush: a sleeping crescent with two little z's of silence
    slow: function (ctx, s) {
      ctx.fillStyle = "#ffffff";
      ctx.save();
      ctx.beginPath();
      ctx.arc(-s * 0.04, s * 0.02, s * 0.26, 0, TAU);
      ctx.arc(s * 0.08, -s * 0.06, s * 0.22, 0, TAU, true);
      ctx.fill("evenodd");
      ctx.restore();
      ctx.strokeStyle = "#ffffff";
      ctx.lineWidth = s * 0.045;
      ctx.lineJoin = "round";
      [[0.16, -0.26, 0.1], [0.27, -0.1, 0.07]].forEach(function (z) {
        var zx = s * z[0], zy = s * z[1], zs = s * z[2];
        ctx.beginPath();
        ctx.moveTo(zx - zs, zy - zs); ctx.lineTo(zx + zs, zy - zs); ctx.lineTo(zx - zs, zy + zs); ctx.lineTo(zx + zs, zy + zs);
        ctx.stroke();
      });
    },
    // Wisp: a small flame of pale light with two eyes
    ghost: function (ctx, s) {
      ctx.fillStyle = "#ffffff";
      ctx.beginPath();
      ctx.moveTo(0, -s * 0.34);
      ctx.bezierCurveTo(s * 0.34, -s * 0.06, s * 0.3, s * 0.3, 0, s * 0.3);
      ctx.bezierCurveTo(-s * 0.3, s * 0.3, -s * 0.32, 0, -s * 0.1, -s * 0.12);
      ctx.bezierCurveTo(-s * 0.06, -s * 0.02, s * 0.04, -s * 0.12, 0, -s * 0.34);
      ctx.fill();
      ctx.fillStyle = "#3b2566";
      ctx.beginPath();
      ctx.arc(-s * 0.08, s * 0.08, s * 0.04, 0, TAU);
      ctx.arc(s * 0.08, s * 0.08, s * 0.04, 0, TAU);
      ctx.fill();
    },
    // Lodestar: a four-pointed guiding star with a ring
    magnet: function (ctx, s) {
      ctx.fillStyle = "#ffffff";
      LM.draw.poly(ctx, 0, 0, s * 0.34, 4, -Math.PI / 2, 0.32);
      ctx.fill();
      ctx.strokeStyle = "rgba(255,255,255,.8)";
      ctx.lineWidth = s * 0.04;
      ctx.beginPath();
      ctx.arc(0, 0, s * 0.2, 0, TAU);
      ctx.stroke();
    },
    // Radiance: a sun of eight rays
    double: function (ctx, s) {
      ctx.fillStyle = "#ffffff";
      ctx.beginPath();
      ctx.arc(0, 0, s * 0.14, 0, TAU);
      ctx.fill();
      ctx.strokeStyle = "#ffffff";
      ctx.lineWidth = s * 0.06;
      ctx.lineCap = "round";
      for (var i = 0; i < 8; i++) {
        var a = i * TAU / 8;
        ctx.beginPath();
        ctx.moveTo(Math.cos(a) * s * 0.22, Math.sin(a) * s * 0.22);
        ctx.lineTo(Math.cos(a) * s * (i % 2 ? 0.3 : 0.35), Math.sin(a) * s * (i % 2 ? 0.3 : 0.35));
        ctx.stroke();
      }
      ctx.lineCap = "butt";
    }
  };

  // A power-up is a glowing orb of colored light carrying its glyph.
  function powerup(ctx, type, x, y, size, t, life) {
    var col = LM.config.powerups[type].color;
    var bob = Math.sin(t * 4) * size * 0.05;
    var s = size * (1 + Math.sin(t * 6) * 0.04);
    ctx.save();
    ctx.translate(x, y + bob);
    var halo = ctx.createRadialGradient(0, 0, 0, 0, 0, s);
    halo.addColorStop(0, LM.color.alpha(col, 0.5));
    halo.addColorStop(1, LM.color.alpha(col, 0));
    ctx.fillStyle = halo;
    ctx.fillRect(-s, -s, s * 2, s * 2);
    // blink when about to expire
    if (life !== undefined && life < 0.25 && Math.sin(t * 20) < 0) ctx.globalAlpha = 0.45;
    var g = ctx.createRadialGradient(-s * 0.12, -s * 0.14, s * 0.04, 0, 0, s * 0.42);
    g.addColorStop(0, LM.color.shade(col, 0.55));
    g.addColorStop(0.6, col);
    g.addColorStop(1, LM.color.shade(col, -0.35));
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.arc(0, 0, s * 0.4, 0, TAU);
    ctx.fill();
    ctx.strokeStyle = "rgba(255,255,255,.55)";
    ctx.lineWidth = Math.max(1, s * 0.035);
    ctx.stroke();
    ctx.rotate(Math.sin(t * 2) * 0.1);
    glyphs[type](ctx, s, col);
    if (life !== undefined) {
      ctx.rotate(-Math.sin(t * 2) * 0.1);
      ctx.strokeStyle = "rgba(255,255,255,.85)";
      ctx.lineWidth = Math.max(1.5, s * 0.06);
      ctx.beginPath();
      ctx.arc(0, 0, s * 0.56, -Math.PI / 2, -Math.PI / 2 + TAU * life);
      ctx.stroke();
    }
    ctx.restore();
  }

  function timerRing(ctx, x, y, size, life, color) {
    ctx.strokeStyle = color;
    ctx.lineWidth = Math.max(1.5, size * 0.07);
    ctx.beginPath();
    ctx.arc(x, y, size * 0.62, -Math.PI / 2, -Math.PI / 2 + TAU * Math.max(0, life));
    ctx.stroke();
  }

  LM.itemsView = { star: star, powerup: powerup, glyphs: glyphs, timerRing: timerRing };
})(window.LUMEN);
