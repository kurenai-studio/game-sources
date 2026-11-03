window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;

  // Light on the board. A small light map is filled with the ambient
  // moonlight of the world, warm lights are added on top (the serpent, the
  // stars, lanterns, gates), walls cut soft shadows out of the serpent's
  // light, and the map is multiplied over the board. Then a little warm
  // spill and rim light is added on the faces that look toward the serpent.

  // Smooth inverse-square falloff, windowed so it reaches zero at the edge.
  function falloff(d) {
    var k = 2.1;
    var f = 1 / (1 + (d * k) * (d * k));
    var end = 1 / (1 + k * k);
    f = (f - end) / (1 - end);
    var win = 1 - d * d;
    return Math.max(0, f * win);
  }

  function makeSprite(rgb, size) {
    var c = document.createElement("canvas");
    c.width = c.height = size;
    var x = c.getContext("2d"), r = size / 2;
    var g = x.createRadialGradient(r, r, 0, r, r, r);
    for (var i = 0; i <= 24; i++) {
      var d = i / 24;
      g.addColorStop(d, "rgba(" + rgb[0] + "," + rgb[1] + "," + rgb[2] + "," + falloff(d).toFixed(4) + ")");
    }
    x.fillStyle = g;
    x.fillRect(0, 0, size, size);
    return c;
  }

  function hull(pts) {
    pts.sort(function (a, b) { return a[0] - b[0] || a[1] - b[1]; });
    function cross(o, a, b) { return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]); }
    var lo = [], up = [], i;
    for (i = 0; i < pts.length; i++) {
      while (lo.length >= 2 && cross(lo[lo.length - 2], lo[lo.length - 1], pts[i]) <= 0) lo.pop();
      lo.push(pts[i]);
    }
    for (i = pts.length - 1; i >= 0; i--) {
      while (up.length >= 2 && cross(up[up.length - 2], up[up.length - 1], pts[i]) <= 0) up.pop();
      up.push(pts[i]);
    }
    up.pop(); lo.pop();
    return lo.concat(up);
  }

  function Lighting() {
    this.map = document.createElement("canvas");
    this.tmp = document.createElement("canvas");
    this.sprites = {};
    this.canBlur = typeof this.map.getContext("2d").filter === "string";
  }

  Lighting.falloff = falloff;

  Lighting.prototype.sprite = function (rgb) {
    var key = rgb.join(",");
    return this.sprites[key] || (this.sprites[key] = makeSprite(rgb, 256));
  };

  // o: { ox, oy, w, h, pad, cell, dpr, ambient: [r,g,b], lights: [{ x, y, r, c: [r,g,b], i, shadow }],
  //      board, spill, rim, rimColor }
  Lighting.prototype.apply = function (ctx, o) {
    var sc = Math.max(0.35, Math.min(1, o.dpr * 0.5));
    var bx = o.ox - o.pad, by = o.oy - o.pad, bw = o.w + o.pad * 2, bh = o.h + o.pad * 2;
    var mw = Math.ceil(bw * sc), mh = Math.ceil(bh * sc);
    var m = this.map, tp = this.tmp;
    if (m.width !== mw || m.height !== mh) { m.width = tp.width = mw; m.height = tp.height = mh; }
    var mc = m.getContext("2d"), tc = tp.getContext("2d");
    mc.setTransform(1, 0, 0, 1, 0, 0);
    mc.globalCompositeOperation = "source-over";
    mc.globalAlpha = 1;
    mc.fillStyle = "rgb(" + o.ambient.map(Math.round).join(",") + ")";
    mc.fillRect(0, 0, mw, mh);
    mc.setTransform(sc, 0, 0, sc, -bx * sc, -by * sc);
    mc.globalCompositeOperation = "lighter";
    var board = o.board, cell = o.cell, self = this;

    for (var i = 0; i < o.lights.length; i++) {
      var L = o.lights[i];
      if (L.i <= 0.005 || L.r <= 1) continue;
      var spr = this.sprite(L.c);
      if (!L.shadow || !board) {
        mc.globalAlpha = Math.min(1, L.i);
        mc.drawImage(spr, L.x - L.r, L.y - L.r, L.r * 2, L.r * 2);
        continue;
      }
      // a light that casts shadows is drawn on its own first
      tc.setTransform(1, 0, 0, 1, 0, 0);
      tc.globalCompositeOperation = "source-over";
      tc.globalAlpha = 1;
      tc.filter = "none";
      tc.clearRect(0, 0, mw, mh);
      tc.setTransform(sc, 0, 0, sc, -bx * sc, -by * sc);
      tc.globalAlpha = Math.min(1, L.i);
      tc.drawImage(spr, L.x - L.r, L.y - L.r, L.r * 2, L.r * 2);
      var walls = [];
      var c0 = Math.max(0, Math.floor((L.x - o.ox - L.r) / cell)), c1 = Math.min(board.cols - 1, Math.floor((L.x - o.ox + L.r) / cell));
      var r0 = Math.max(0, Math.floor((L.y - o.oy - L.r) / cell)), r1 = Math.min(board.rows - 1, Math.floor((L.y - o.oy + L.r) / cell));
      for (var cy = r0; cy <= r1; cy++) {
        for (var cx = c0; cx <= c1; cx++) if (board.isWall(cx, cy)) walls.push([cx, cy]);
      }
      if (walls.length) {
        tc.globalCompositeOperation = "destination-out";
        tc.globalAlpha = L.shadow;
        if (self.canBlur) tc.filter = "blur(" + Math.max(1, cell * 0.35 * sc).toFixed(1) + "px)";
        tc.fillStyle = "#000";
        tc.beginPath();
        walls.forEach(function (wc) {
          var x0 = o.ox + wc[0] * cell, y0 = o.oy + wc[1] * cell;
          if (L.x >= x0 && L.x <= x0 + cell && L.y >= y0 && L.y <= y0 + cell) return;
          var pts = [], corners = [[x0, y0], [x0 + cell, y0], [x0, y0 + cell], [x0 + cell, y0 + cell]];
          corners.forEach(function (p) {
            var dx = p[0] - L.x, dy = p[1] - L.y, d = Math.sqrt(dx * dx + dy * dy) || 1;
            var far = (L.r * 1.2) / d;
            pts.push(p, [p[0] + dx * far, p[1] + dy * far]);
          });
          var hp = hull(pts);
          tc.moveTo(hp[0][0], hp[0][1]);
          for (var k = 1; k < hp.length; k++) tc.lineTo(hp[k][0], hp[k][1]);
          tc.closePath();
        });
        tc.fill();
        tc.filter = "none";
        // the tops of the walls themselves still catch the light
        tc.globalCompositeOperation = "source-over";
        tc.globalAlpha = Math.min(1, L.i) * 0.85;
        tc.save();
        tc.beginPath();
        walls.forEach(function (wc) { tc.rect(o.ox + wc[0] * cell, o.oy + wc[1] * cell, cell, cell); });
        tc.clip();
        tc.drawImage(spr, L.x - L.r, L.y - L.r, L.r * 2, L.r * 2);
        tc.restore();
      }
      mc.setTransform(1, 0, 0, 1, 0, 0);
      mc.globalAlpha = 1;
      mc.drawImage(tp, 0, 0);
      mc.setTransform(sc, 0, 0, sc, -bx * sc, -by * sc);
    }
    mc.globalAlpha = 1;
    mc.globalCompositeOperation = "source-over";

    // multiply the light over the board
    ctx.save();
    LM.draw.roundRect(ctx, bx, by, bw, bh, o.cell * 0.7);
    ctx.clip();
    ctx.globalCompositeOperation = "multiply";
    ctx.drawImage(m, bx, by, bw, bh);
    // warm spill: light that lands on the surfaces near the serpent
    ctx.globalCompositeOperation = "screen";
    for (i = 0; i < o.lights.length; i++) {
      var S = o.lights[i];
      if (!S.spill) continue;
      ctx.globalAlpha = Math.min(1, S.spill);
      var sr = S.r * 0.85;
      ctx.drawImage(this.sprite(S.c), S.x - sr, S.y - sr, sr * 2, sr * 2);
    }
    ctx.globalAlpha = 1;
    // rim light on the wall edges that face the serpent
    var R = o.rim;
    if (R && board) {
      ctx.lineWidth = Math.max(1, cell * 0.08);
      ctx.lineCap = "round";
      var rc = R.c;
      var x0 = Math.max(0, Math.floor((R.x - o.ox - R.r) / cell)), x1 = Math.min(board.cols - 1, Math.floor((R.x - o.ox + R.r) / cell));
      var y0 = Math.max(0, Math.floor((R.y - o.oy - R.r) / cell)), y1 = Math.min(board.rows - 1, Math.floor((R.y - o.oy + R.r) / cell));
      for (var yy = y0; yy <= y1; yy++) {
        for (var xx = x0; xx <= x1; xx++) {
          if (!board.isWall(xx, yy)) continue;
          var px = o.ox + xx * cell, py = o.oy + yy * cell;
          var edges = [[0, -1, px, py, px + cell, py], [0, 1, px, py + cell, px + cell, py + cell],
            [-1, 0, px, py, px, py + cell], [1, 0, px + cell, py, px + cell, py + cell]];
          for (var e = 0; e < 4; e++) {
            var E = edges[e];
            var nx = xx + E[0], ny = yy + E[1];
            if (board.inBounds(nx, ny) && board.isWall(nx, ny)) continue;
            var mx = (E[2] + E[4]) / 2, my = (E[3] + E[5]) / 2;
            var dx = R.x - mx, dy = R.y - my, d = Math.sqrt(dx * dx + dy * dy);
            var facing = (dx * E[0] + dy * E[1]) / (d || 1);
            if (facing <= 0.05 || d > R.r) continue;
            var a = R.i * facing * falloff(d / R.r);
            if (a < 0.02) continue;
            ctx.strokeStyle = "rgba(" + rc[0] + "," + rc[1] + "," + rc[2] + "," + a.toFixed(3) + ")";
            ctx.beginPath();
            var ix = E[0] ? 0 : cell * 0.08, iy = E[1] ? 0 : cell * 0.08;
            ctx.moveTo(E[2] + ix - E[0] * cell * 0.04, E[3] + iy - E[1] * cell * 0.04);
            ctx.lineTo(E[4] - ix - E[0] * cell * 0.04, E[5] - iy - E[1] * cell * 0.04);
            ctx.stroke();
          }
        }
      }
    }
    ctx.restore();
  };

  LM.Lighting = Lighting;
  void TAU;
})(window.LUMEN);
