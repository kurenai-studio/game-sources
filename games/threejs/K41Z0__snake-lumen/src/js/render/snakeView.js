window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;
  var mix = function (a, b, t) { return LM.color.mix(a, b, t); };

  function skinById(id) {
    var list = LM.config.skins;
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return list[0];
  }

  // Colour of body segment i (0 = head) out of n, at time t.
  function segColor(skin, i, n, t) {
    var c = skin.colors, k = n > 1 ? i / (n - 1) : 0;
    switch (skin.pattern) {
      case "stripes": return (i % 4 < 2) ? c[0] : c[1];
      case "gradient": return mix(c[0], c[1], k);
      case "shimmer": return mix(c[0], c[1], 0.5 + 0.5 * Math.sin(i * 0.45 - t * 4));
      case "glitch": return ((i * 7 + Math.floor(t * 8)) % 11 === 0) ? c[1] : c[0];
      case "galaxy": return mix(c[0], c[1], 0.3 + 0.35 * Math.sin(i * 0.3 + t));
      case "metal": return mix(c[0], c[1], 0.5 + 0.5 * Math.sin(i * 0.55 - t * 3));
      case "rainbow": return "hsl(" + Math.round((i * 22 - t * 120) % 360 + 360) % 360 + ",85%,62%)";
      default: return mix(c[0], c[1], k * 0.7);
    }
  }

  // Width of segment i: full at the neck, tapering to a point-ish tail.
  function segWidth(cell, i, n) {
    var k = n > 1 ? i / (n - 1) : 0;
    return cell * (0.82 - 0.4 * Math.pow(k, 1.3));
  }

  var sprites = {};
  function sprite(color) {
    if (!sprites[color]) sprites[color] = LM.glowSprite(color, 64);
    return sprites[color];
  }

  function SnakeView() {
    this.blinkAt = 2;
    this.blinkUntil = 0;
    this.tongueAt = 3;
    this.pops = [];
  }

  SnakeView.prototype.pop = function (t) {
    this.pops.push(t);
    if (this.pops.length > 6) this.pops.shift();
  };

  // Interpolated centre points in pixels. A segment that jumped (portal or
  // wrap) snaps, and the path breaks there so no line crosses the board.
  SnakeView.points = function (cells, prev, alpha, ox, oy, cell) {
    var pts = [];
    for (var i = 0; i < cells.length; i++) {
      var c = cells[i];
      var p = prev && prev.length ? prev[Math.min(i, prev.length - 1)] : c;
      var dx = c.x - p.x, dy = c.y - p.y;
      var jump = Math.abs(dx) + Math.abs(dy) > 1;
      var x = jump ? c.x : p.x + dx * alpha, y = jump ? c.y : p.y + dy * alpha;
      pts.push({ x: ox + (x + 0.5) * cell, y: oy + (y + 0.5) * cell });
    }
    return pts;
  };

  // opts: pts, cell, skin, t, dir, look {x,y}|null, ghost, dead, mouth, glow, eyesClosed
  SnakeView.prototype.draw = function (ctx, opts) {
    var pts = opts.pts, n = pts.length, cell = opts.cell, skin = opts.skin || skinById("lumen"), t = opts.t;
    if (!n) return;
    var self = this;
    var widths = [];
    for (var i = 0; i < n; i++) {
      var w = segWidth(cell, i, n);
      for (var p = 0; p < this.pops.length; p++) {
        var at = (t - this.pops[p]) * (1000 / (opts.tickMs || 120));
        var d = i - at;
        if (at >= 0 && at < n + 3) w *= 1 + 0.32 * Math.exp(-d * d * 0.6);
      }
      widths.push(w);
    }
    function joined(a, b) {
      return Math.abs(pts[a].x - pts[b].x) + Math.abs(pts[a].y - pts[b].y) < cell * 1.6;
    }
    function strokeSegs(widthFn, colorFn, dx, dy) {
      for (var j = n - 1; j >= 1; j--) {
        if (!joined(j, j - 1)) continue;
        ctx.strokeStyle = colorFn(j);
        ctx.lineWidth = widthFn(j);
        ctx.beginPath();
        ctx.moveTo(pts[j].x + dx, pts[j].y + dy);
        ctx.lineTo(pts[j - 1].x + dx, pts[j - 1].y + dy);
        ctx.stroke();
      }
      // lone points (after a jump) still need a blob
      for (j = 1; j < n; j++) {
        if (joined(j, j - 1) || (j + 1 < n && joined(j, j + 1))) continue;
        ctx.fillStyle = colorFn(j);
        ctx.beginPath();
        ctx.arc(pts[j].x + dx, pts[j].y + dy, widthFn(j) / 2, 0, TAU);
        ctx.fill();
      }
    }

    ctx.save();
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    var wobble = 1;
    ctx.globalAlpha = 1;

    // the serpent's own light: brighter and wider the longer it grows
    if (!opts.dead) {
      var gk = Math.max(0, Math.min(1, (n - 4) / 36));
      var spr = sprite(skin.glow || skin.colors[0]);
      ctx.globalCompositeOperation = "lighter";
      var pulse = 0.9 + 0.1 * Math.sin(t * 2.4);
      for (var gi = n - 1; gi >= 0; gi--) {
        var fall = 1 - (gi / Math.max(1, n)) * 0.55;
        var gs = cell * (1.3 + 1.6 * gk) * fall * (gi === 0 ? 1.5 : 1);
        ctx.globalAlpha = (0.07 + 0.13 * gk) * fall * pulse * (gi === 0 ? 1.8 : 1);
        ctx.drawImage(spr, pts[gi].x - gs, pts[gi].y - gs, gs * 2, gs * 2);
      }
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = "source-over";
    }
    // drop shadow
    strokeSegs(function (j) { return widths[j]; }, function () { return "rgba(0,0,0,.28)"; }, 0, cell * 0.14);
    // glow for shimmering skins or the double-points aura
    if (skin.pattern === "shimmer" || skin.pattern === "glitch" || opts.glow) {
      var gc = opts.glow || skin.colors[0];
      strokeSegs(function (j) { return widths[j] * 1.7; }, function () { return LM.color.alpha(gc.charAt(0) === "#" ? gc : "#ffd98a", 0.16); }, 0, 0);
    }
    // outline, body, belly highlight
    strokeSegs(function (j) { return widths[j] + Math.max(2, cell * 0.1); },
      function (j) { return opts.dead ? "#1a1a1a" : LM.color.alpha("#000000", 0.45); }, 0, 0);
    strokeSegs(function (j) { return widths[j]; },
      function (j) { return opts.dead ? mix("#6e7681", "#30363d", j / n) : segColor(skin, j, n, t); }, 0, 0);
    if (!opts.dead) {
      ctx.globalAlpha *= 0.4;
      strokeSegs(function (j) { return widths[j] * 0.32; }, function () { return skin.belly; }, -cell * 0.08, -cell * 0.1);
      ctx.globalAlpha = 1;
    }
    // patterns layered on top
    if (!opts.dead && skin.pattern === "galaxy") {
      for (var s = 2; s < n; s++) {
        var tw = 0.5 + 0.5 * Math.sin(t * 3 + s * 1.7);
        ctx.fillStyle = "rgba(255,255,255," + (0.35 + tw * 0.6) + ")";
        ctx.beginPath();
        ctx.arc(pts[s].x + Math.sin(s * 2.1) * widths[s] * 0.25, pts[s].y + Math.cos(s * 1.3) * widths[s] * 0.25,
          Math.max(0.8, cell * 0.05 * tw), 0, TAU);
        ctx.fill();
      }
    }
    if (!opts.dead && skin.pattern === "glitch" && Math.sin(t * 13) > 0.85 && !opts.reduced) {
      ctx.globalAlpha = 0.35;
      strokeSegs(function (j) { return widths[j] * 0.8; }, function () { return skin.colors[1]; }, cell * 0.12, 0);
      ctx.globalAlpha = 1;
    }

    // ---------- head ----------
    var h = pts[0];
    var dir = opts.dir || { x: 1, y: 0 };
    var ang = Math.atan2(dir.y, dir.x);
    if (n > 1 && joined(0, 1)) {
      var vx = pts[0].x - pts[1].x, vy = pts[0].y - pts[1].y;
      if (Math.abs(vx) + Math.abs(vy) > cell * 0.2) ang = Math.atan2(vy, vx);
    }
    if (self.lastAng === undefined) self.lastAng = ang;
    var diff = Math.atan2(Math.sin(ang - self.lastAng), Math.cos(ang - self.lastAng));
    self.lastAng += diff * Math.min(1, 0.35 + (opts.dt || 0.016) * 12);
    ang = self.lastAng;
    var r = Math.max(widths[0], cell * 0.8) * 0.56;
    ctx.save();
    ctx.translate(h.x, h.y);
    ctx.rotate(ang);
    ctx.fillStyle = "rgba(0,0,0,.28)";
    ctx.beginPath();
    ctx.ellipse(0, cell * 0.14, r * 1.12, r, 0, 0, TAU);
    ctx.fill();
    ctx.fillStyle = LM.color.alpha("#000000", 0.45);
    ctx.beginPath();
    ctx.ellipse(0, 0, r * 1.12 + cell * 0.05, r + cell * 0.05, 0, 0, TAU);
    ctx.fill();
    var hc = opts.dead ? "#6e7681" : segColor(skin, 0, n, t);
    var hg = ctx.createRadialGradient(-r * 0.3, -r * 0.4, r * 0.1, 0, 0, r * 1.2);
    hg.addColorStop(0, opts.dead ? "#8b949e" : mix(hc.charAt(0) === "#" ? hc : skin.colors[0], "#ffffff", 0.25));
    hg.addColorStop(1, hc);
    ctx.fillStyle = hg;
    ctx.beginPath();
    ctx.ellipse(0, 0, r * 1.12, r, 0, 0, TAU);
    ctx.fill();

    // mouth opens as a star gets close; otherwise the tongue flicks now and then
    if (opts.mouth > 0 && !opts.dead) {
      ctx.fillStyle = "#3b0d16";
      ctx.beginPath();
      ctx.ellipse(r * 0.72, 0, r * 0.32 * opts.mouth, r * 0.5 * opts.mouth, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#ff6b81";
      ctx.beginPath();
      ctx.ellipse(r * 0.72, r * 0.15 * opts.mouth, r * 0.16 * opts.mouth, r * 0.2 * opts.mouth, 0, 0, TAU);
      ctx.fill();
    } else if (!opts.dead && t > this.tongueAt && t < this.tongueAt + 0.28) {
      var k = Math.sin(((t - this.tongueAt) / 0.28) * Math.PI);
      ctx.strokeStyle = "#ff4d6d";
      ctx.lineWidth = Math.max(1.2, cell * 0.06);
      ctx.beginPath();
      ctx.moveTo(r * 0.9, 0);
      ctx.lineTo(r * (0.9 + 0.7 * k), 0);
      ctx.lineTo(r * (1.1 + 0.8 * k), -r * 0.18 * k);
      ctx.moveTo(r * (0.9 + 0.7 * k), 0);
      ctx.lineTo(r * (1.1 + 0.8 * k), r * 0.18 * k);
      ctx.stroke();
    } else if (t > this.tongueAt + 0.28) {
      this.tongueAt = t + 2.5 + Math.random() * 4;
    }

    // cheeks
    if (!opts.dead) {
      ctx.fillStyle = "rgba(255,120,150,.28)";
      ctx.beginPath();
      ctx.arc(r * 0.35, -r * 0.72, r * 0.16, 0, TAU);
      ctx.arc(r * 0.35, r * 0.72, r * 0.16, 0, TAU);
      ctx.fill();
    }

    // eyes: look toward the target, blink every few seconds
    if (t > this.blinkAt) {
      this.blinkUntil = t + 0.13;
      this.blinkAt = t + 2 + Math.random() * 3.5;
      if (Math.random() < 0.2) this.blinkAt = t + 0.25;
    }
    var closed = opts.eyesClosed || t < this.blinkUntil;
    var lookX = 0, lookY = 0;
    if (opts.look) {
      var lx = opts.look.x - h.x, ly = opts.look.y - h.y;
      var ll = Math.sqrt(lx * lx + ly * ly) || 1;
      var ca = Math.cos(-ang), sa = Math.sin(-ang);
      lookX = (lx * ca - ly * sa) / ll;
      lookY = (lx * sa + ly * ca) / ll;
    }
    for (var e = -1; e <= 1; e += 2) {
      var ex = r * 0.28, ey = e * r * 0.46, er = r * 0.36;
      if (opts.dead) {
        ctx.strokeStyle = "#0d1117";
        ctx.lineWidth = Math.max(1.5, cell * 0.08);
        ctx.beginPath();
        ctx.moveTo(ex - er * 0.6, ey - er * 0.6); ctx.lineTo(ex + er * 0.6, ey + er * 0.6);
        ctx.moveTo(ex + er * 0.6, ey - er * 0.6); ctx.lineTo(ex - er * 0.6, ey + er * 0.6);
        ctx.stroke();
        continue;
      }
      if (closed) {
        ctx.strokeStyle = "#0d1117";
        ctx.lineWidth = Math.max(1.5, cell * 0.07);
        ctx.beginPath();
        ctx.arc(ex, ey, er * 0.7, 0.2 * Math.PI + (e < 0 ? 0 : 0), 0.8 * Math.PI);
        ctx.stroke();
        continue;
      }
      ctx.fillStyle = "#ffffff";
      ctx.beginPath();
      ctx.ellipse(ex, ey, er, er * 1.05, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#0d1117";
      ctx.beginPath();
      ctx.arc(ex + lookX * er * 0.42, ey + lookY * er * 0.42, er * 0.55, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#ffffff";
      ctx.beginPath();
      ctx.arc(ex + lookX * er * 0.42 - er * 0.2, ey + lookY * er * 0.42 - er * 0.22, er * 0.18, 0, TAU);
      ctx.fill();
    }
    ctx.restore();
    ctx.restore();
  };

  SnakeView.skinById = skinById;
  SnakeView.segColor = segColor;
  LM.SnakeView = SnakeView;
})(window.LUMEN);
