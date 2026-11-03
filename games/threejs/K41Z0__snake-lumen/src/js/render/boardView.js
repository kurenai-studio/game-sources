window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;
  var RR = function () { return LM.draw.roundRect.apply(null, arguments); };
  function clamp01(v) { return v < 0 ? 0 : v > 1 ? 1 : v; }

  // Board art per world, painted twice: asleep (cool, faded) and awake
  // (full colour). The two are blended by the world's light; the lighting
  // pass then adds moonlight, warm light and shadows on top.
  //   Garden: a moonlit lawn with hedges.
  //   City:   a cobbled old-town square; walls are tiled rooftops with
  //           chimneys, dormer windows and lanterns; lantern trams.
  //   Sky:    a sea of cloud tops; walls are thick cloud banks; small
  //           clouds drift.
  //   Moon:   a path of silver flagstones; moonstone pillars and eclipse
  //           stones; shadows drift.
  var ART = [
    { awake: { floor: "#40704a", floor2: "#4a7c52", spot: "#2f5838", hi: "#6a9a64",
        wall: "#2c6136", wallTop: "#4f9a58", wallHi: "#86c477", wallLo: "#173a20" },
      asleep: { floor: "#3d555c", floor2: "#445e64", spot: "#30464d", hi: "#5d767a",
        wall: "#304a50", wallTop: "#46646a", wallHi: "#62807f", wallLo: "#1f3136" } },
    { awake: { floor: "#5a5560", floor2: "#635d68", spot: "#3c3742", hi: "#7d7480",
        wall: "#8a4a3c", wallTop: "#a65d49", wallHi: "#c87a5e", wallLo: "#53291f", chimney: "#6b3a31" },
      asleep: { floor: "#4b5165", floor2: "#535a6f", spot: "#353a4b", hi: "#677089",
        wall: "#6c4c55", wallTop: "#875f66", wallHi: "#a97d80", wallLo: "#30232c", chimney: "#4a3640" } },
    { awake: { floor: "#33467c", floor2: "#3b5089", spot: "#2a3a6a", hi: "#5d70a8",
        wall: "#8e9ccc", wallTop: "#c9d1f2", wallHi: "#eef1ff", wallLo: "#5c689a" },
      asleep: { floor: "#383f5a", floor2: "#3f4762", spot: "#2e344c", hi: "#555d79",
        wall: "#68708a", wallTop: "#8a91a8", wallHi: "#a8aec0", wallLo: "#464c63" } },
    { awake: { floor: "#636a8e", floor2: "#6d7499", spot: "#454b6a", hi: "#8a91b6",
        wall: "#c1c8e4", wallTop: "#e3e8fb", wallHi: "#ffffff", wallLo: "#868eb2" },
      asleep: { floor: "#50566c", floor2: "#585e75", spot: "#3b4053", hi: "#6c7288",
        wall: "#848a9f", wallTop: "#9da3b6", wallHi: "#b8bdcc", wallLo: "#5c6175" } }
  ];

  function BoardView() {
    this.asleep = null;
    this.awake = null;
    this.decor = [];
    this.lamps = [];
    this.chimneys = [];
    this.key = "";
  }

  function wallAt(board, x, y) { return board.inBounds(x, y) && board.isWall(x, y); }

  BoardView.prototype.prepare = function (board, world, cell, dpr) {
    var key = [board.cols, board.rows, world, cell, dpr, board.walls.join(""), board.wrap].join("|");
    if (key === this.key) return;
    this.key = key;
    var W = board.cols * cell, H = board.rows * cell, pad = Math.ceil(cell * 0.7);
    this.pad = pad;
    var self = this;
    function paint(alive) {
      var pal = alive ? ART[world].awake : ART[world].asleep;
      return LM.makeLayer(W + pad * 2, H + pad * 2, Math.min(dpr, 2), function (x) {
        x.translate(pad, pad);
        var bx = -cell * 0.3, by = -cell * 0.3, bw = W + cell * 0.6, bh = H + cell * 0.6, br = cell * 0.55;
        x.save();
        x.shadowColor = "rgba(2,4,14,.55)";
        x.shadowBlur = cell * 0.9;
        x.shadowOffsetY = cell * 0.2;
        x.fillStyle = pal.floor;
        RR(x, bx, by, bw, bh, br);
        x.fill();
        x.restore();
        x.save();
        RR(x, bx, by, bw, bh, br);
        x.clip();
        floor(x, board, world, cell, W, H, pal, new LM.Rng(40 + world));
        x.restore();
        // a soft edge; dashed where the edges wrap around
        x.save();
        x.strokeStyle = "rgba(230,235,255," + (alive ? 0.32 : 0.2) + ")";
        x.lineWidth = Math.max(1, cell * 0.06);
        if (board.wrap) x.setLineDash([cell * 0.3, cell * 0.3]);
        RR(x, bx + 1, by + 1, bw - 2, bh - 2, br);
        x.stroke();
        x.restore();
        var rng = new LM.Rng(99 + world);
        for (var y = 0; y < board.rows; y++) {
          for (var cx = 0; cx < board.cols; cx++) {
            if (board.isWall(cx, y)) wall(x, board, cx, y, cell, world, pal, rng);
          }
        }
      });
    }
    this.asleep = paint(false);
    this.awake = paint(true);

    // living details, each with the light level at which it wakes
    var rng = new LM.Rng(300 + world);
    this.decor = [];
    this.lamps = [];
    this.chimneys = [];
    for (var y = 0; y < board.rows; y++) {
      for (var cx = 0; cx < board.cols; cx++) {
        if (!board.isWall(cx, y)) continue;
        if (world === 1) {
          // dormer windows on the roof edges that face the street
          var open = [[0, -1], [0, 1], [-1, 0], [1, 0]].filter(function (d) { return !wallAt(board, cx + d[0], y + d[1]); });
          if (open.length && rng.next() < 0.7) {
            var d = open[rng.int(open.length)];
            self.decor.push({ x: cx + 0.5 + d[0] * 0.3, y: y + 0.5 + d[1] * 0.3, th: 0.15 + rng.next() * 0.8, ph: rng.next() * TAU,
              vert: d[0] !== 0 });
          }
          if (rng.next() < 0.16) self.chimneys.push({ x: cx + 0.3 + rng.next() * 0.4, y: y + 0.3 + rng.next() * 0.3, ph: rng.next() * 10 });
          if (open.length >= 2 && rng.next() < 0.28) {
            var d2 = open[rng.int(open.length)];
            self.lamps.push({ x: cx + 0.5 + d2[0] * 0.62, y: y + 0.5 + d2[1] * 0.62, th: 0.12 + rng.next() * 0.7, ph: rng.next() * TAU });
          }
        } else if (rng.next() < (world === 0 ? 0.55 : world === 2 ? 0.3 : 0.4)) {
          var colors = world === 0 ? ["#ff9cc8", "#ffd166", "#fff1f7", "#c7a6ff", "#ff9f7a"] : world === 2 ? ["#eef1ff", "#ffe8a3"] : ["#eef1ff", "#ffe8a3"];
          self.decor.push({ x: cx + 0.25 + rng.next() * 0.5, y: y + 0.2 + rng.next() * 0.5, th: 0.15 + rng.next() * 0.8,
            color: colors[rng.int(colors.length)], s: 0.75 + rng.next() * 0.5, ph: rng.next() * TAU });
        }
      }
    }
    this.decor.sort(function (a, b) { return a.th - b.th; });
  };

  // ---------- floors ----------
  function floor(x, board, world, cell, W, H, pal, rng) {
    var cols = board.cols, rows = board.rows, i, cx, cy;
    if (world === 0) {
      // mown lawn: soft stripes, tufts and the odd clover
      for (cy = -1; cy <= rows; cy++) {
        x.fillStyle = cy % 2 ? pal.floor : pal.floor2;
        x.fillRect(-cell, cy * cell, W + cell * 2, cell);
      }
      x.lineWidth = Math.max(1, cell * 0.045);
      x.lineCap = "round";
      for (i = 0; i < cols * rows * 1.6; i++) {
        var gx = rng.next() * W, gy = rng.next() * H;
        x.strokeStyle = rng.next() < 0.5 ? pal.spot : pal.hi;
        x.globalAlpha = 0.35 + rng.next() * 0.35;
        x.beginPath();
        x.moveTo(gx, gy);
        x.lineTo(gx + (rng.next() - 0.5) * cell * 0.12, gy - cell * (0.1 + rng.next() * 0.12));
        x.stroke();
      }
      for (i = 0; i < cols * rows * 0.05; i++) {
        x.fillStyle = pal.hi;
        x.globalAlpha = 0.4;
        var cx2 = rng.next() * W, cy2 = rng.next() * H;
        for (var l = 0; l < 3; l++) { x.beginPath(); x.arc(cx2 + Math.cos(l * 2.1) * cell * 0.06, cy2 + Math.sin(l * 2.1) * cell * 0.06, cell * 0.06, 0, TAU); x.fill(); }
      }
      x.globalAlpha = 1;
    } else if (world === 1) {
      // cobbles in offset rows
      x.fillStyle = pal.spot;
      x.fillRect(-cell, -cell, W + cell * 2, H + cell * 2);
      var cw = cell / 2, chh = cell / 2.4;
      for (cy = -1; cy * chh < H + cell; cy++) {
        var off = (cy % 2) * cw * 0.5;
        for (var px = -cw + off; px < W + cw; px += cw) {
          x.fillStyle = rng.next() < 0.5 ? pal.floor : pal.floor2;
          RR(x, px + cw * 0.06, cy * chh + chh * 0.08, cw * 0.88, chh * 0.84, cw * 0.28);
          x.fill();
          x.fillStyle = pal.hi;
          x.globalAlpha = 0.35;
          RR(x, px + cw * 0.16, cy * chh + chh * 0.14, cw * 0.5, chh * 0.24, chh * 0.12);
          x.fill();
          x.globalAlpha = 1;
        }
      }
    } else if (world === 2) {
      // tops of the clouds, soft and rolling
      x.fillStyle = pal.floor;
      x.fillRect(-cell, -cell, W + cell * 2, H + cell * 2);
      for (i = 0; i < cols * rows * 0.35; i++) {
        var ccx = rng.next() * W, ccy = rng.next() * H, r = cell * (0.5 + rng.next() * 1.1);
        var g = x.createRadialGradient(ccx, ccy - r * 0.3, 0, ccx, ccy, r);
        g.addColorStop(0, LM.color.alpha(pal.hi, 0.35));
        g.addColorStop(0.6, LM.color.alpha(pal.floor2, 0.25));
        g.addColorStop(1, LM.color.alpha(pal.floor2, 0));
        x.fillStyle = g;
        x.fillRect(ccx - r, ccy - r, r * 2, r * 2);
      }
      for (i = 0; i < cols * rows * 0.12; i++) {
        var sx = rng.next() * W, sy = rng.next() * H, sr = cell * (0.3 + rng.next() * 0.6);
        var g2 = x.createRadialGradient(sx, sy, 0, sx, sy, sr);
        g2.addColorStop(0, LM.color.alpha(pal.spot, 0.35));
        g2.addColorStop(1, LM.color.alpha(pal.spot, 0));
        x.fillStyle = g2;
        x.fillRect(sx - sr, sy - sr, sr * 2, sr * 2);
      }
    } else {
      // silver flagstones
      x.fillStyle = pal.spot;
      x.fillRect(-cell, -cell, W + cell * 2, H + cell * 2);
      for (cy = -1; cy <= rows; cy++) {
        var shift = (cy % 2) * 0.5;
        for (cx = -1; cx <= cols; cx++) {
          var fx = (cx + shift) * cell, fy = cy * cell;
          var j = cell * 0.05;
          x.fillStyle = rng.next() < 0.5 ? pal.floor : pal.floor2;
          RR(x, fx + j + rng.next() * j, fy + j + rng.next() * j, cell - j * 3, cell - j * 3, cell * 0.12);
          x.fill();
          var hg = x.createLinearGradient(fx, fy, fx + cell, fy + cell);
          hg.addColorStop(0, LM.color.alpha(pal.hi, 0.35));
          hg.addColorStop(0.5, LM.color.alpha(pal.hi, 0));
          x.fillStyle = hg;
          RR(x, fx + j * 1.5, fy + j * 1.5, cell - j * 4, cell - j * 4, cell * 0.12);
          x.fill();
        }
      }
    }
  }

  // ---------- walls ----------
  function wall(x, board, cx, cy, cell, world, pal, rng) {
    var px = cx * cell, py = cy * cell;
    var L = wallAt(board, cx - 1, cy), R = wallAt(board, cx + 1, cy), T = wallAt(board, cx, cy - 1), B = wallAt(board, cx, cy + 1);
    var inset = cell * 0.06;
    var rx = px + (L ? 0 : inset), ry = py + (T ? 0 : inset), rw = cell - (L ? 0 : inset) - (R ? 0 : inset), rh = cell - (T ? 0 : inset) - (B ? 0 : inset);
    // contact shadow on the ground below
    x.fillStyle = "rgba(6,8,20,.35)";
    RR(x, rx + cell * 0.04, ry + cell * 0.12, rw, rh, cell * 0.2);
    x.fill();
    if (world === 0) {
      // a hedge: a mass of leaves, lit from the moon above
      x.fillStyle = pal.wallLo;
      RR(x, rx, ry + cell * 0.05, rw, rh, cell * 0.24);
      x.fill();
      x.fillStyle = pal.wall;
      RR(x, rx, ry, rw, rh - cell * 0.05, cell * 0.24);
      x.fill();
      for (var k = 0; k < 9; k++) {
        var lx = rx + rng.next() * rw, ly = ry + rng.next() * rh * 0.85, lr = cell * (0.08 + rng.next() * 0.1);
        x.fillStyle = k < 3 ? pal.wallLo : k < 7 ? pal.wallTop : pal.wallHi;
        x.globalAlpha = k < 3 ? 0.6 : 0.85;
        x.beginPath();
        x.arc(lx, ly, lr, 0, TAU);
        x.fill();
      }
      x.globalAlpha = 1;
    } else if (world === 1) {
      // a tiled rooftop; ridge along the long side of the block
      var horiz = (L || R) || !(T || B);
      x.fillStyle = pal.wallLo;
      x.fillRect(rx, ry, rw, rh);
      x.fillStyle = pal.wall;
      x.fillRect(rx, ry, rw, rh - cell * 0.06);
      // tile courses
      x.strokeStyle = LM.color.alpha(pal.wallLo, 0.75);
      x.lineWidth = Math.max(1, cell * 0.04);
      var n = 4;
      x.beginPath();
      for (var c = 1; c < n; c++) {
        if (horiz) { x.moveTo(rx, ry + rh * c / n); x.lineTo(rx + rw, ry + rh * c / n); }
        else { x.moveTo(rx + rw * c / n, ry); x.lineTo(rx + rw * c / n, ry + rh); }
      }
      x.stroke();
      // scalloped tile ends
      x.fillStyle = LM.color.alpha(pal.wallTop, 0.55);
      for (var row = 0; row < n; row++) {
        for (var col = 0; col < 4; col++) {
          var tx = horiz ? rx + (col + 0.5 + (row % 2) * 0.5) * rw / 4 : rx + (row + 0.5) * rw / n;
          var ty = horiz ? ry + (row + 0.55) * rh / n : ry + (col + 0.5 + (row % 2) * 0.5) * rh / 4;
          if (tx > rx + rw || ty > ry + rh) continue;
          x.beginPath();
          x.arc(tx, ty, cell * 0.06, 0, TAU);
          x.fill();
        }
      }
      // ridge highlight
      x.strokeStyle = LM.color.alpha(pal.wallHi, 0.7);
      x.lineWidth = Math.max(1, cell * 0.07);
      x.beginPath();
      if (horiz) { x.moveTo(rx, ry + rh * 0.5); x.lineTo(rx + rw, ry + rh * 0.5); }
      else { x.moveTo(rx + rw * 0.5, ry); x.lineTo(rx + rw * 0.5, ry + rh); }
      x.stroke();
      // eaves: a darker lip on the open sides
      x.fillStyle = "rgba(20,14,20,.35)";
      if (!B) x.fillRect(rx, ry + rh - cell * 0.1, rw, cell * 0.1);
      if (!R) x.fillRect(rx + rw - cell * 0.06, ry, cell * 0.06, rh);
    } else if (world === 2) {
      // a cloud bank: puffs with silver tops and a shaded underside
      var ccx = px + cell / 2, ccy = py + cell / 2;
      var puffs = [[0, 0.06, 0.42], [-0.25, -0.1, 0.3], [0.22, -0.12, 0.32], [0.02, -0.22, 0.28]];
      if (L) puffs.push([-0.48, 0.02, 0.32]);
      if (R) puffs.push([0.48, 0.02, 0.32]);
      if (T) puffs.push([0, -0.46, 0.34]);
      if (B) puffs.push([0, 0.44, 0.34]);
      x.fillStyle = pal.wallLo;
      puffs.forEach(function (p) { x.beginPath(); x.arc(ccx + p[0] * cell, ccy + p[1] * cell + cell * 0.06, p[2] * cell, 0, TAU); x.fill(); });
      puffs.forEach(function (p) {
        var g = x.createRadialGradient(ccx + p[0] * cell, ccy + (p[1] - p[2] * 0.5) * cell, 0, ccx + p[0] * cell, ccy + p[1] * cell, p[2] * cell);
        g.addColorStop(0, pal.wallHi);
        g.addColorStop(0.45, pal.wallTop);
        g.addColorStop(1, pal.wall);
        x.fillStyle = g;
        x.beginPath(); x.arc(ccx + p[0] * cell, ccy + p[1] * cell, p[2] * cell * 0.94, 0, TAU); x.fill();
      });
    } else {
      // a moonstone pillar: pale, faceted, with a bright upper edge
      var gm = x.createLinearGradient(rx, ry, rx + rw * 0.6, ry + rh);
      gm.addColorStop(0, pal.wallHi);
      gm.addColorStop(0.3, pal.wallTop);
      gm.addColorStop(1, pal.wall);
      x.fillStyle = pal.wallLo;
      RR(x, rx, ry + cell * 0.06, rw, rh, cell * 0.14);
      x.fill();
      x.fillStyle = gm;
      RR(x, rx, ry, rw, rh - cell * 0.06, cell * 0.14);
      x.fill();
      x.strokeStyle = "rgba(255,255,255,.35)";
      x.lineWidth = Math.max(1, cell * 0.035);
      x.beginPath();
      x.moveTo(px + cell * (0.25 + rng.next() * 0.2), py + cell * 0.2);
      x.lineTo(px + cell * (0.55 + rng.next() * 0.2), py + cell * 0.7);
      x.stroke();
    }
  }

  // ---------- details that wake with the light ----------
  BoardView.prototype.drawDecor = function (ctx, ox, oy, cell, world, light, t) {
    for (var i = 0; i < this.decor.length; i++) {
      var d = this.decor[i];
      var k = clamp01((light - d.th) / 0.12);
      var x = ox + d.x * cell, y = oy + d.y * cell;
      if (world === 0) {
        if (k <= 0) {
          ctx.fillStyle = "rgba(170,190,180,.45)";
          ctx.beginPath(); ctx.arc(x, y, cell * 0.05, 0, TAU); ctx.fill();
          continue;
        }
        var pr = cell * 0.13 * d.s * (0.3 + 0.7 * k);
        ctx.fillStyle = d.color;
        for (var p = 0; p < 5; p++) {
          var a = p * TAU / 5 + d.ph + Math.sin(t * 0.8 + d.ph) * 0.15;
          ctx.beginPath();
          ctx.arc(x + Math.cos(a) * pr * 0.75 * k, y + Math.sin(a) * pr * 0.75 * k, pr * 0.55, 0, TAU);
          ctx.fill();
        }
        ctx.fillStyle = "#fff3bf";
        ctx.beginPath(); ctx.arc(x, y, pr * 0.38, 0, TAU); ctx.fill();
      } else if (world === 1) {
        // a dormer window: dark until its light comes on
        var ww = cell * (d.vert ? 0.14 : 0.22), wh = cell * (d.vert ? 0.22 : 0.14);
        ctx.fillStyle = "#2a2430";
        ctx.fillRect(x - ww / 2 - 1, y - wh / 2 - 1, ww + 2, wh + 2);
        if (k > 0) {
          var flick = d.th > light - 0.05 ? 0.8 + 0.2 * Math.sin(t * 9 + d.ph) : 1;
          ctx.fillStyle = "rgba(255,206,130," + (0.95 * k * flick).toFixed(3) + ")";
          ctx.fillRect(x - ww / 2, y - wh / 2, ww, wh);
          ctx.fillStyle = "rgba(90,50,30,.6)";
          if (d.vert) ctx.fillRect(x - ww / 2, y - 0.5, ww, 1); else ctx.fillRect(x - 0.5, y - wh / 2, 1, wh);
        }
      } else {
        if (k <= 0) continue;
        var tw = 0.6 + 0.4 * Math.sin(t * 2.2 + d.ph);
        var sl = cell * 0.15 * d.s * k * tw;
        ctx.fillStyle = LM.color.alpha(d.color, 0.25 * k);
        ctx.beginPath(); ctx.arc(x, y, sl * 1.4, 0, TAU); ctx.fill();
        ctx.fillStyle = LM.color.alpha(d.color, 0.95 * k);
        ctx.beginPath();
        ctx.moveTo(x, y - sl); ctx.lineTo(x + sl * 0.22, y); ctx.lineTo(x, y + sl); ctx.lineTo(x - sl * 0.22, y); ctx.closePath();
        ctx.moveTo(x - sl, y); ctx.lineTo(x, y + sl * 0.22); ctx.lineTo(x + sl, y); ctx.lineTo(x, y - sl * 0.22); ctx.closePath();
        ctx.fill();
      }
    }
    // chimneys, and lanterns on their brackets
    for (var c = 0; c < this.chimneys.length; c++) {
      var ch = this.chimneys[c], chx = ox + ch.x * cell, chy = oy + ch.y * cell, s = cell * 0.22;
      ctx.fillStyle = "rgba(10,8,14,.35)";
      ctx.fillRect(chx - s / 2 + cell * 0.05, chy - s / 2 + cell * 0.07, s, s);
      ctx.fillStyle = ART[1][light > 0.5 ? "awake" : "asleep"].chimney;
      ctx.fillRect(chx - s / 2, chy - s / 2, s, s);
      ctx.fillStyle = "#2a2430";
      ctx.fillRect(chx - s * 0.32, chy - s * 0.32, s * 0.64, s * 0.64);
    }
    for (var l = 0; l < this.lamps.length; l++) {
      var lp = this.lamps[l], lx = ox + lp.x * cell, ly = oy + lp.y * cell;
      var lk = clamp01((light - lp.th) / 0.1);
      ctx.fillStyle = "#23202a";
      ctx.beginPath(); ctx.arc(lx, ly, cell * 0.12, 0, TAU); ctx.fill();
      ctx.fillStyle = lk > 0 ? "rgba(255,226,160," + (0.35 + 0.65 * lk).toFixed(3) + ")" : "#4a4652";
      ctx.beginPath(); ctx.arc(lx, ly, cell * 0.07, 0, TAU); ctx.fill();
    }
  };

  // smoke from the chimneys once the town is waking
  BoardView.prototype.drawSmoke = function (ctx, ox, oy, cell, light, t) {
    var k = clamp01((light - 0.3) / 0.3);
    if (k <= 0) return;
    for (var c = 0; c < this.chimneys.length; c++) {
      var ch = this.chimneys[c];
      for (var p = 0; p < 4; p++) {
        var age = ((t * 0.35 + ch.ph + p * 0.25) % 1);
        var sx = ox + ch.x * cell + Math.sin(age * 5 + ch.ph) * cell * 0.15 + age * cell * 0.4;
        var sy = oy + ch.y * cell - age * cell * 0.9;
        ctx.fillStyle = "rgba(210,214,230," + (0.18 * k * (1 - age)).toFixed(3) + ")";
        ctx.beginPath(); ctx.arc(sx, sy, cell * (0.08 + age * 0.18), 0, TAU); ctx.fill();
      }
    }
  };

  // gates between places: silver, gold and rose
  var GATE = { A: ["#cfdcff", [200, 216, 255]], B: ["#ffd98a", [255, 214, 140]], C: ["#ffc4b0", [255, 196, 176]] };

  BoardView.prototype.draw = function (ctx, game, ox, oy, cell, t, opts) {
    var board = game.board;
    var light = opts.light === undefined ? 1 : opts.light;
    var k = clamp01(light);
    ctx.drawImage(this.asleep, ox - this.pad, oy - this.pad, this.asleep.cssW, this.asleep.cssH);
    if (k > 0.01) {
      ctx.globalAlpha = k;
      ctx.drawImage(this.awake, ox - this.pad, oy - this.pad, this.awake.cssW, this.awake.cssH);
      ctx.globalAlpha = 1;
    }
    this.drawDecor(ctx, ox, oy, cell, opts.world, light, t);
    if (opts.world === 1 && !opts.reduced) this.drawSmoke(ctx, ox, oy, cell, light, t);

    // gates: a ring of old stones holding a soft light
    for (var p = 0; p < board.portalList.length; p++) {
      var pr = board.portalList[p];
      var col = (GATE[pr.id] || GATE.A)[0];
      [pr.a, pr.b].forEach(function (end, e) {
        var cx = ox + (end.x + 0.5) * cell, cy = oy + (end.y + 0.5) * cell;
        var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, cell * 0.42);
        g.addColorStop(0, LM.color.alpha(col, 0.95));
        g.addColorStop(0.6, LM.color.alpha(col, 0.45));
        g.addColorStop(1, LM.color.alpha(col, 0.1));
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.arc(cx, cy, cell * 0.42, 0, TAU); ctx.fill();
        for (var s = 0; s < 8; s++) {
          var a = s / 8 * TAU + 0.2;
          ctx.fillStyle = s % 2 ? "#6f7388" : "#8c90a6";
          ctx.beginPath();
          ctx.ellipse(cx + Math.cos(a) * cell * 0.42, cy + Math.sin(a) * cell * 0.42, cell * 0.11, cell * 0.08, a + Math.PI / 2, 0, TAU);
          ctx.fill();
        }
        for (var m = 0; m < 3; m++) {
          var ma = t * (e ? -0.8 : 0.8) + m * TAU / 3;
          ctx.fillStyle = "rgba(255,255,255,.75)";
          ctx.beginPath(); ctx.arc(cx + Math.cos(ma) * cell * 0.2, cy + Math.sin(ma) * cell * 0.2, cell * 0.035, 0, TAU); ctx.fill();
        }
      });
    }

    // eclipse stones: a dark moon with a silver rim when solid, a pale
    // ghost when open, and a rim that brightens before they close
    for (var i = 0; i < board.phase.length; i++) {
      var ph = board.phase[i];
      var x = ox + (ph.x + 0.5) * cell, y = oy + (ph.y + 0.5) * cell;
      if (ph.solid) {
        ctx.fillStyle = "rgba(6,8,20,.35)";
        ctx.beginPath(); ctx.arc(x + cell * 0.04, y + cell * 0.08, cell * 0.44, 0, TAU); ctx.fill();
        var sg = ctx.createRadialGradient(x - cell * 0.12, y - cell * 0.14, cell * 0.05, x, y, cell * 0.45);
        sg.addColorStop(0, ph.group === 1 ? "#4a4f6e" : "#54496a");
        sg.addColorStop(1, "#1c1f33");
        ctx.fillStyle = sg;
        ctx.beginPath(); ctx.arc(x, y, cell * 0.44, 0, TAU); ctx.fill();
        ctx.strokeStyle = ph.group === 1 ? "rgba(230,235,255,.8)" : "rgba(255,217,138,.8)";
        ctx.lineWidth = Math.max(1, cell * 0.06);
        ctx.beginPath(); ctx.arc(x, y, cell * 0.41, -2.6, -0.6); ctx.stroke();
      } else {
        var warn = LM.Board.prototype.ticksToSolid.call(board, ph.group, game.tick) <= LM.config.phaseWarnTicks && !ph.held;
        var a2 = 0.12;
        if (warn) a2 = opts.reduced ? 0.35 : 0.2 + 0.25 * (Math.sin(t * 14) * 0.5 + 0.5);
        ctx.fillStyle = "rgba(220,226,255," + a2.toFixed(3) + ")";
        ctx.beginPath(); ctx.arc(x, y, cell * 0.4, 0, TAU); ctx.fill();
        ctx.strokeStyle = (ph.group === 1 ? "rgba(230,235,255," : "rgba(255,217,138,") + (a2 * 2).toFixed(3) + ")";
        ctx.lineWidth = Math.max(1, cell * 0.04);
        ctx.beginPath(); ctx.arc(x, y, cell * 0.4, 0, TAU); ctx.stroke();
      }
    }

    // movers glide between cells
    var alpha = opts.alpha;
    for (var m2 = 0; m2 < board.movers.length; m2++) {
      var mv = board.movers[m2];
      var mx = ox + (mv.px + (mv.x - mv.px) * alpha + 0.5) * cell;
      var my = oy + (mv.py + (mv.y - mv.py) * alpha + 0.5) * cell;
      drawMover(ctx, mx, my, cell, opts.world, t, mv, m2);
    }
  };

  function heading(mv) {
    var tgt = mv.forward ? mv.to : mv.from;
    var hx = Math.sign(tgt.x - mv.x), hy = Math.sign(tgt.y - mv.y);
    if (!hx && !hy) { hx = Math.sign(mv.from.x - mv.to.x); hy = Math.sign(mv.from.y - mv.to.y); }
    return [hx, hy];
  }

  function drawMover(ctx, x, y, cell, world, t, mv, idx) {
    ctx.save();
    ctx.translate(x, y);
    if (world === 1 || world === 0) {
      // a little lantern tram, seen from above: red body, cream roof,
      // warm windows down both sides and a lamp in front
      var hd = heading(mv);
      ctx.rotate(Math.atan2(hd[1], hd[0]));
      var lg = ctx.createRadialGradient(cell * 0.62, 0, 0, cell * 0.62, 0, cell * 0.7);
      lg.addColorStop(0, "rgba(255,226,160,.55)");
      lg.addColorStop(1, "rgba(255,226,160,0)");
      ctx.fillStyle = lg;
      ctx.beginPath(); ctx.moveTo(cell * 0.5, 0); ctx.arc(cell * 0.5, 0, cell * 0.75, -0.6, 0.6); ctx.closePath(); ctx.fill();
      ctx.fillStyle = "rgba(6,8,20,.45)";
      RR(ctx, -cell * 0.48, -cell * 0.3, cell * 0.98, cell * 0.72, cell * 0.2);
      ctx.fill();
      ctx.fillStyle = world === 0 ? "#7c5a3a" : "#a2402f";
      ctx.strokeStyle = "#2a1410";
      ctx.lineWidth = Math.max(1, cell * 0.05);
      RR(ctx, -cell * 0.5, -cell * 0.36, cell * 1.0, cell * 0.72, cell * 0.2);
      ctx.fill(); ctx.stroke();
      ctx.fillStyle = "#ffd98a";
      for (var w = 0; w < 4; w++) {
        ctx.fillRect(-cell * 0.38 + w * cell * 0.19, -cell * 0.33, cell * 0.12, cell * 0.08);
        ctx.fillRect(-cell * 0.38 + w * cell * 0.19, cell * 0.25, cell * 0.12, cell * 0.08);
      }
      ctx.fillStyle = "#eadbb8";
      RR(ctx, -cell * 0.42, -cell * 0.22, cell * 0.84, cell * 0.44, cell * 0.14);
      ctx.fill();
      ctx.fillStyle = "#c7b28a";
      ctx.fillRect(-cell * 0.36, -cell * 0.05, cell * 0.72, cell * 0.1);
      ctx.strokeStyle = "#3a2a20";
      ctx.lineWidth = Math.max(1, cell * 0.035);
      ctx.beginPath(); ctx.moveTo(-cell * 0.12, 0); ctx.lineTo(cell * 0.06, -cell * 0.16); ctx.lineTo(cell * 0.2, 0); ctx.stroke();
      ctx.fillStyle = "#fff6d8";
      ctx.beginPath(); ctx.arc(cell * 0.47, 0, cell * 0.09, 0, TAU); ctx.fill();
    } else if (world === 2) {
      // a small dark cloud drifting through
      var wob = Math.sin(t * 1.5 + idx) * cell * 0.03;
      var puffs = [[-0.22, 0.05, 0.26], [0.18, 0.06, 0.28], [0, -0.12, 0.3], [-0.02, 0.14, 0.24]];
      ctx.fillStyle = "rgba(6,8,20,.35)";
      puffs.forEach(function (p) { ctx.beginPath(); ctx.arc(p[0] * cell + cell * 0.05, p[1] * cell + cell * 0.1, p[2] * cell, 0, TAU); ctx.fill(); });
      puffs.forEach(function (p) {
        var g = ctx.createRadialGradient(p[0] * cell, (p[1] - 0.15) * cell + wob, 0, p[0] * cell, p[1] * cell + wob, p[2] * cell);
        g.addColorStop(0, "#9aa4c8");
        g.addColorStop(0.5, "#5d6890");
        g.addColorStop(1, "#3d4668");
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.arc(p[0] * cell, p[1] * cell + wob, p[2] * cell, 0, TAU); ctx.fill();
      });
    } else {
      // a shadow: a soft smudge of night with two pale eyes
      var wb = Math.sin(t * 3 + idx);
      var sg = ctx.createRadialGradient(0, 0, cell * 0.1, 0, 0, cell * 0.58);
      sg.addColorStop(0, "rgba(14,12,30,.95)");
      sg.addColorStop(0.7, "rgba(28,24,56,.8)");
      sg.addColorStop(1, "rgba(40,36,80,0)");
      ctx.fillStyle = sg;
      ctx.beginPath();
      for (var s = 0; s <= 12; s++) {
        var a2 = s / 12 * TAU, rr = cell * (0.46 + 0.06 * Math.sin(s * 3 + t * 4 + idx));
        if (s === 0) ctx.moveTo(Math.cos(a2) * rr, Math.sin(a2) * rr);
        else ctx.lineTo(Math.cos(a2) * rr, Math.sin(a2) * rr);
      }
      ctx.fill();
      ctx.fillStyle = "#f3e6c0";
      ctx.beginPath();
      ctx.ellipse(-cell * 0.13, -cell * 0.05 + wb, cell * 0.055, cell * 0.075, 0, 0, TAU);
      ctx.ellipse(cell * 0.13, -cell * 0.05 + wb, cell * 0.055, cell * 0.075, 0, 0, TAU);
      ctx.fill();
    }
    ctx.restore();
  }

  // Lights the board itself gives off: lanterns, tram lamps, gates.
  BoardView.prototype.lights = function (game, ox, oy, cell, t, light, dark, alpha, world) {
    var out = [], board = game.board;
    var amp = dark ? 1 : 0.55;
    for (var l = 0; l < this.lamps.length; l++) {
      var lp = this.lamps[l], k = clamp01((light - lp.th) / 0.1);
      if (k > 0) out.push({ x: ox + lp.x * cell, y: oy + lp.y * cell, r: cell * 2.2, c: [255, 200, 130], i: 0.6 * k * amp });
    }
    for (var m = 0; m < board.movers.length && world <= 1; m++) {
      var mv = board.movers[m];
      var mx = ox + (mv.px + (mv.x - mv.px) * alpha + 0.5) * cell, my = oy + (mv.py + (mv.y - mv.py) * alpha + 0.5) * cell;
      var hd = heading(mv);
      out.push({ x: mx, y: my, r: cell * 2.1, c: [255, 210, 140], i: 0.55 * amp });
      out.push({ x: mx + hd[0] * cell * 0.9, y: my + hd[1] * cell * 0.9, r: cell * 1.6, c: [255, 230, 180], i: 0.5 * amp });
    }
    for (var p = 0; p < board.portalList.length; p++) {
      var pr = board.portalList[p], c = (GATE[pr.id] || GATE.A)[1];
      [pr.a, pr.b].forEach(function (e) { out.push({ x: ox + (e.x + 0.5) * cell, y: oy + (e.y + 0.5) * cell, r: cell * 1.8, c: c, i: 0.45 * amp }); });
    }
    void t;
    return out;
  };

  BoardView.ART = ART;
  BoardView.paintFloor = floor;
  LM.BoardView = BoardView;
})(window.LUMEN);
