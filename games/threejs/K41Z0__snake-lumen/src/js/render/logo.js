window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;
  var cache = {};

  // The Snake: Lumen mark: a soft crescent Moon, a glowing serpent curled along its
  // inner edge, and the star it carries home. Drawn once, cached as an image.
  function draw(ctx, S, t) {
    var cx = S * 0.5, cy = S * 0.5;
    // halo
    var hg = ctx.createRadialGradient(cx, cy, S * 0.05, cx, cy, S * 0.5);
    hg.addColorStop(0, "rgba(255,217,138,.22)");
    hg.addColorStop(0.6, "rgba(230,235,255,.06)");
    hg.addColorStop(1, "rgba(230,235,255,0)");
    ctx.fillStyle = hg;
    ctx.fillRect(0, 0, S, S);
    // crescent
    var R = S * 0.3;
    ctx.save();
    ctx.shadowColor = "rgba(230,235,255,.8)";
    ctx.shadowBlur = S * 0.06;
    var mg = ctx.createLinearGradient(cx - R, cy - R, cx + R, cy + R);
    mg.addColorStop(0, "#ffffff");
    mg.addColorStop(1, "#c9d1ee");
    ctx.fillStyle = mg;
    ctx.beginPath();
    ctx.arc(cx - S * 0.04, cy, R, 0, TAU);
    ctx.clip();
    ctx.beginPath();
    ctx.rect(0, 0, S, S);
    ctx.arc(cx + S * 0.08, cy - S * 0.06, R * 0.84, 0, TAU);
    ctx.fill("evenodd");
    ctx.restore();
    // serpent: a tapered ribbon of warm light along the inner curve
    var pts = [];
    for (var i = 0; i <= 40; i++) {
      var k = i / 40;
      var a = Math.PI * (0.62 + k * 0.95);
      var r = R * (0.62 - 0.05 * Math.sin(k * Math.PI * 3));
      pts.push({ x: cx + S * 0.07 + Math.cos(a) * r, y: cy - S * 0.03 + Math.sin(a) * r });
    }
    pts.reverse();
    ctx.save();
    ctx.lineCap = "round";
    ctx.shadowColor = "#ffc861";
    ctx.shadowBlur = S * 0.05;
    for (var j = 0; j < pts.length - 1; j++) {
      var f = j / (pts.length - 1);
      ctx.strokeStyle = LM.color.mix("#fff6d8", "#f2a93b", f);
      ctx.lineWidth = S * (0.055 - 0.035 * f);
      ctx.beginPath();
      ctx.moveTo(pts[j].x, pts[j].y);
      ctx.lineTo(pts[j + 1].x, pts[j + 1].y);
      ctx.stroke();
    }
    ctx.restore();
    // head and eye
    var hd = pts[0];
    ctx.fillStyle = "#fff6d8";
    ctx.save();
    ctx.shadowColor = "#ffd98a";
    ctx.shadowBlur = S * 0.05;
    ctx.beginPath();
    ctx.arc(hd.x, hd.y, S * 0.036, 0, TAU);
    ctx.fill();
    ctx.restore();
    ctx.fillStyle = "#2a1a08";
    ctx.beginPath();
    ctx.arc(hd.x + S * 0.012, hd.y - S * 0.008, S * 0.009, 0, TAU);
    ctx.fill();
    // the star it carries
    var sx = hd.x + S * 0.1, sy = hd.y - S * 0.09;
    LM.itemsView.star(ctx, sx, sy, S * 0.2, t || 0.4, { phase: 2 });
  }

  function logo(size) {
    if (cache[size]) return cache[size];
    var c = document.createElement("canvas");
    var dpr = Math.min(2, window.devicePixelRatio || 1);
    c.width = c.height = Math.round(size * dpr);
    var ctx = c.getContext("2d");
    ctx.scale(dpr, dpr);
    draw(ctx, size, 0.4);
    cache[size] = c.toDataURL("image/png");
    return cache[size];
  }

  LM.logo = logo;
  LM.drawLogo = draw;
})(window.LUMEN);
