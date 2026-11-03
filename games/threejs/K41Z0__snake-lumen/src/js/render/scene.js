window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // Composes a frame: backdrop, board, items, snake, particles and the
  // full-screen effects (shake, flash, countdown). Owns the canvas and DPR.
  function Scene(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.backdrop = new LM.Backdrop();
    this.boardView = new LM.BoardView();
    this.snakeView = new LM.SnakeView();
    this.particles = new LM.Particles();
    this.w = 0;
    this.h = 0;
    this.dpr = 1;
    this.shakeAmt = 0;
    this.flashAmt = 0;
    this.flashColor = "#ffffff";
    this.cam = { x: 0, y: 0 };
    this.layoutBox = { cell: 20, ox: 0, oy: 0 };
    this.reserve = { top: 70, bottom: 16, left: 16, right: 16 };
    this.banner = null;
  }

  Scene.prototype.resize = function () {
    var w = window.innerWidth, h = window.innerHeight;
    var dpr = Math.min(window.devicePixelRatio || 1, 2.5);
    this.w = w;
    this.h = h;
    this.dpr = dpr;
    this.canvas.width = Math.round(w * dpr);
    this.canvas.height = Math.round(h * dpr);
    this.canvas.style.width = w + "px";
    this.canvas.style.height = h + "px";
    this.backdrop.resize(w, h, dpr);
    if (this.three && this.three.ok) this.three.resize();
  };

  // Offscreen layers the size of the screen, for drawing things translucently.
  Scene.prototype.layer = function (name) {
    this.layers = this.layers || {};
    var c = this.layers[name];
    if (!c) c = this.layers[name] = document.createElement("canvas");
    if (c.width !== this.canvas.width || c.height !== this.canvas.height) {
      c.width = this.canvas.width;
      c.height = this.canvas.height;
    }
    return c;
  };

  Scene.prototype.composite = function (ctx, name, alpha, dx, dy) {
    ctx.save();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.globalAlpha = alpha;
    ctx.drawImage(this.layers[name], dx * this.dpr, dy * this.dpr);
    ctx.restore();
  };

  Scene.prototype.setReserve = function (r) {
    this.reserve = r;
  };

  Scene.prototype.layout = function (board) {
    var r = this.reserve;
    var aw = this.w - r.left - r.right, ah = this.h - r.top - r.bottom;
    var cell = Math.max(8, Math.floor(Math.min(aw / board.cols, ah / board.rows)));
    var bw = cell * board.cols, bh = cell * board.rows;
    this.layoutBox = {
      cell: cell,
      ox: Math.round(r.left + (aw - bw) / 2),
      oy: Math.round(r.top + (ah - bh) / 2),
      w: bw,
      h: bh
    };
    return this.layoutBox;
  };

  Scene.prototype.cellCenter = function (c) {
    if (this.three && this.three.ok && this.three.visible && this.three.game) return this.three.project(c);
    var L = this.layoutBox;
    return { x: L.ox + (c.x + 0.5) * L.cell, y: L.oy + (c.y + 0.5) * L.cell };
  };

  Scene.prototype.shake = function (amount) {
    this.shakeAmt = Math.max(this.shakeAmt, amount);
  };

  Scene.prototype.flash = function (color, amount) {
    this.flashColor = color;
    this.flashAmt = Math.max(this.flashAmt, amount);
  };

  // f: { game, world, worldFrom, worldMix, light, t, dt, skin, settings, boardAlpha, dead, countdown }
  Scene.prototype.render = function (f) {
    var ctx = this.ctx, w = this.w, h = this.h, t = f.t;
    var reduced = !!(f.settings && f.settings.reducedFlash);
    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);

    // smooth camera parallax toward the snake head
    var tx = 0, ty = 0;
    if (f.game) {
      var hd = f.game.snake.head();
      tx = (hd.x / f.game.board.cols - 0.5) * 2;
      ty = (hd.y / f.game.board.rows - 0.5) * 2;
    }
    var k = Math.min(1, f.dt * 2);
    this.cam.x += (tx - this.cam.x) * k;
    this.cam.y += (ty - this.cam.y) * k;

    var light = f.light === undefined ? 1 : f.light;
    var bopts = { reduced: reduced, light: light, moon: f.moon || 0 };
    // in a run, three.js draws the world and the board; this canvas only
    // carries particles, banners, the flash and the countdown on top
    var three = this.three && this.three.ok ? this.three : null;
    if (three) three.setVisible(!!f.game);
    if (three && f.game) {
      ctx.clearRect(0, 0, w, h);
      three.render(f);
      this.shakeAmt *= Math.pow(0.0015, f.dt);
      this.particles.update(f.dt);
      this.particles.draw(ctx);
      this.overlays(ctx, f, reduced, t);
      return;
    }
    if (f.worldMix !== undefined && f.worldMix < 1 && f.worldFrom !== undefined && f.worldFrom !== f.world) {
      this.backdrop.draw(ctx, f.worldFrom, t, this.cam.x, this.cam.y, bopts);
      ctx.globalAlpha = f.worldMix;
      this.backdrop.draw(ctx, f.world, t, this.cam.x, this.cam.y, bopts);
      ctx.globalAlpha = 1;
    } else {
      this.backdrop.draw(ctx, f.world, t, this.cam.x, this.cam.y, bopts);
    }

    this.particles.update(f.dt);

    if (f.game) {
      var shakeScale = f.settings && f.settings.shake === false ? 0 : reduced ? 0.4 : 1;
      var sx = 0, sy = 0;
      if (this.shakeAmt > 0.1 && shakeScale > 0) {
        sx = (Math.random() - 0.5) * this.shakeAmt * shakeScale;
        sy = (Math.random() - 0.5) * this.shakeAmt * shakeScale;
      }
      this.shakeAmt *= Math.pow(0.0015, f.dt);
      var ba = f.boardAlpha === undefined ? 1 : f.boardAlpha;
      if (ba < 1) {
        // draw on a layer first so overlapping strokes do not double up
        var lc = this.layer("board").getContext("2d");
        lc.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
        lc.clearRect(0, 0, w, h);
        this.drawGame(lc, f, reduced);
        this.composite(ctx, "board", ba, 0, 0);
      } else {
        ctx.save();
        ctx.translate(sx, sy);
        this.drawGame(ctx, f, reduced);
        ctx.restore();
      }
    }
    this.particles.draw(ctx);
    this.overlays(ctx, f, reduced, t);
  };

  Scene.prototype.overlays = function (ctx, f, reduced, t) {
    var w = this.w, h = this.h;
    if (this.flashAmt > 0.01) {
      ctx.globalAlpha = Math.min(1, this.flashAmt) * (reduced ? 0.25 : 1);
      ctx.fillStyle = this.flashColor;
      ctx.fillRect(0, 0, w, h);
      ctx.globalAlpha = 1;
      this.flashAmt *= Math.pow(0.004, f.dt);
    }

    if (f.countdown) this.drawCountdown(ctx, f.countdown);
    if (this.banner) this.drawBanner(ctx, t);
  };

  // Ambient moonlight per world: asleep (cool, a little dim) and awake.
  var AMBIENT = [
    { sleep: [150, 164, 204], awake: [236, 238, 240] },
    { sleep: [146, 156, 200], awake: [238, 234, 232] },
    { sleep: [150, 160, 210], awake: [232, 236, 248] },
    { sleep: [156, 164, 206], awake: [240, 242, 252] }
  ];
  // Moonlight in dark levels, per world, so each board ends up about as dim:
  // the pale moon flagstones need less of it than the dark cloud tops.
  var NIGHT = [[64, 74, 116], [62, 72, 114], [72, 82, 126], [44, 51, 84]];
  var WARM = [255, 190, 118], STAR = [255, 212, 140], GOLD = [255, 232, 170];
  function mix3(a, b, k) { return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k]; }
  function hexRgb(h) { return LM.color.hex(h); }

  Scene.prototype.drawGame = function (ctx, f, reduced) {
    var g = f.game, t = f.t;
    var L = this.layout(g.board);
    var cell = L.cell, ox = L.ox, oy = L.oy;
    var world = f.boardWorld === undefined ? f.world : f.boardWorld;
    this.boardView.prepare(g.board, world, cell, this.dpr);
    var alpha = g.status === "running" ? g.alpha : (g.status === "ready" ? 0 : 1);
    var light = f.light === undefined ? 1 : f.light;
    var dark = !!(g.level && g.level.dark);
    this.boardView.draw(ctx, g, ox, oy, cell, t, { world: world, alpha: alpha, reduced: reduced, light: light, dark: dark });
    if (g.item) {
      var ip = this.cellCenter(g.item);
      LM.itemsView.powerup(ctx, g.item.type, ip.x, ip.y, cell, t, g.item.ttl / g.item.max);
    }

    var pts = LM.SnakeView.points(g.snake.cells, g.prevCells, alpha, ox, oy, cell);
    var head = pts[0];
    this.drawLight(ctx, f, g, pts, L, world, light, dark, reduced);

    // stars carry their own light, so they sit above the lighting
    var look = null;
    var self = this;
    function starAlpha(px, py) {
      if (!dark || self.nightFade > 0.9) return 1;
      var d = Math.sqrt((px - head.x) * (px - head.x) + (py - head.y) * (py - head.y)) / cell;
      var tw = reduced ? 0.7 : 0.6 + 0.4 * Math.sin(t * 2.3 + px * 0.05);
      return Math.max(0.55 * tw, Math.min(1, 1.6 - d / 6));
    }
    if (g.star) {
      var bp = g.starPrev || g.star;
      var jump = Math.abs(bp.x - g.star.x) + Math.abs(bp.y - g.star.y) > 1;
      var bx = jump ? g.star.x : bp.x + (g.star.x - bp.x) * alpha;
      var by = jump ? g.star.y : bp.y + (g.star.y - bp.y) * alpha;
      var px = ox + (bx + 0.5) * cell, py = oy + (by + 0.5) * cell;
      if (g.effects.magnet > 0) {
        var mg = ctx.createRadialGradient(px, py, 0, px, py, cell * 1.2);
        mg.addColorStop(0, "rgba(255,170,140,0)");
        mg.addColorStop(0.7, "rgba(255,170,140," + (0.12 + 0.06 * Math.sin(t * 8)).toFixed(3) + ")");
        mg.addColorStop(1, "rgba(255,170,140,0)");
        ctx.fillStyle = mg;
        ctx.fillRect(px - cell * 1.2, py - cell * 1.2, cell * 2.4, cell * 2.4);
      }
      ctx.globalAlpha = starAlpha(px, py);
      LM.itemsView.star(ctx, px, py, cell, t, {});
      ctx.globalAlpha = 1;
      look = { x: px, y: py };
    }
    if (g.golden) {
      var gp = this.cellCenter(g.golden);
      ctx.globalAlpha = starAlpha(gp.x, gp.y);
      LM.itemsView.star(ctx, gp.x, gp.y, cell * 1.15, t, { golden: true, phase: 1 });
      LM.itemsView.timerRing(ctx, gp.x, gp.y, cell * 1.15, g.golden.ttl / g.golden.max, "rgba(255,236,153,.55)");
      ctx.globalAlpha = 1;
      look = gp;
    }

    // the serpent
    var mouth = 0;
    [g.star, g.golden].forEach(function (it) {
      if (!it) return;
      var c = { x: ox + (it.x + 0.5) * cell, y: oy + (it.y + 0.5) * cell };
      var d = Math.sqrt((c.x - head.x) * (c.x - head.x) + (c.y - head.y) * (c.y - head.y)) / cell;
      mouth = Math.max(mouth, Math.max(0, Math.min(1, (2.2 - d) / 1.2)));
    });
    var glow = g.effects.double > 0 ? "#ffd166" : null;
    if (g.effects.slow > 0) {
      ctx.strokeStyle = "rgba(143,184,255,.22)";
      ctx.lineWidth = cell * 0.9;
      ctx.lineCap = "round";
      ctx.beginPath();
      for (var i = 0; i < pts.length; i++) {
        var far = i > 0 && Math.abs(pts[i].x - pts[i - 1].x) + Math.abs(pts[i].y - pts[i - 1].y) > cell * 1.6;
        if (i === 0 || far) ctx.moveTo(pts[i].x, pts[i].y + cell * 0.05);
        else ctx.lineTo(pts[i].x, pts[i].y + cell * 0.05);
      }
      ctx.stroke();
    }
    var ghost = g.effects.ghost > 0;
    var target = ctx;
    if (ghost) {
      target = this.layer("snake").getContext("2d");
      target.setTransform(ctx.getTransform());
      target.clearRect(-this.w, -this.h, this.w * 3, this.h * 3);
    }
    this.snakeView.draw(target, {
      pts: pts, cell: cell, skin: f.skin, t: t, dt: f.dt, dir: g.snake.dir, look: look,
      ghost: ghost, dead: f.dead || g.status === "over", mouth: g.status === "over" ? 0 : mouth,
      glow: glow, tickMs: g.tickMs(), reduced: reduced
    });
    if (ghost) {
      var left = g.effects.ghost;
      var a = 0.45 + 0.12 * Math.sin(t * 10);
      if (left < 1500 && Math.sin(t * 18) > 0) a = 0.85;
      ctx.save();
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.globalAlpha = a;
      ctx.drawImage(this.layers.snake, 0, 0);
      ctx.restore();
    }
  };

  // Natural light over the board: moonlight ambient (dim in dark levels),
  // warm light from the serpent with soft shadows, little pools around the
  // stars, lanterns, trams and gates.
  Scene.prototype.drawLight = function (ctx, f, g, pts, L, world, light, dark, reduced) {
    if (!this.lighting) this.lighting = new LM.Lighting();
    var cell = L.cell, t = f.t;
    if (this.lightGame !== g) { this.lightGame = g; this.nightFade = 0; }
    this.lightDark = dark;
    var want = !dark ? 1 : g.status === "won" ? 1 : g.status === "over" ? 0.4 : 0;
    this.nightFade += (want - this.nightFade) * Math.min(1, (f.dt || 0.016) * (want > this.nightFade ? 1.2 : 6));
    if (!dark) this.nightFade = 1;
    var amb = AMBIENT[world] || AMBIENT[0];
    var day = mix3(amb.sleep, amb.awake, Math.max(0, Math.min(1, light)));
    var ambient = dark ? mix3(NIGHT[world] || NIGHT[0], day, this.nightFade) : day;
    var gk = Math.max(0, Math.min(1, (pts.length - 4) / 36));
    var flick = reduced ? 1 : 1 + 0.025 * Math.sin(t * 6.1) + 0.016 * Math.sin(t * 11.7 + 1.3) + 0.01 * Math.sin(t * 17.3 + 0.4);
    var boost = g.effects.double > 0 ? 1.18 : 1;
    var head = pts[0];
    var lights = [];
    var alive = g.status !== "over" || !f.dead;
    var hr = cell * (dark ? 5.6 + 4.6 * gk : 3.6 + 3.6 * gk) * flick * boost;
    if (alive) {
      lights.push({ x: head.x, y: head.y, r: hr, c: WARM, i: dark ? 1 : 0.6, shadow: dark ? 0.8 : 0.5, spill: dark ? 0.42 : 0.22 });
      for (var i = 2; i < pts.length; i += 2) {
        lights.push({ x: pts[i].x, y: pts[i].y, r: cell * (dark ? 1.9 + 0.8 * gk : 1.5), c: WARM, i: (dark ? 0.32 : 0.16) * (1 - 0.5 * i / pts.length) });
      }
    }
    var ox = L.ox, oy = L.oy;
    if (g.star) lights.push({ x: ox + (g.star.x + 0.5) * cell, y: oy + (g.star.y + 0.5) * cell, r: cell * (dark ? 2.8 : 2.2), c: STAR, i: dark ? 0.75 : 0.32, spill: dark ? 0.12 : 0.06 });
    if (g.golden) lights.push({ x: ox + (g.golden.x + 0.5) * cell, y: oy + (g.golden.y + 0.5) * cell, r: cell * (dark ? 3.4 : 2.6), c: GOLD, i: dark ? 0.9 : 0.4, spill: 0.1 });
    if (g.item) {
      var pc = hexRgb(LM.config.powerups[g.item.type].color);
      lights.push({ x: ox + (g.item.x + 0.5) * cell, y: oy + (g.item.y + 0.5) * cell, r: cell * (dark ? 2.2 : 1.7), c: pc, i: dark ? 0.6 : 0.3 });
    }
    this.boardView.lights(g, ox, oy, cell, t, light, dark, g.status === "running" ? g.alpha : (g.status === "ready" ? 0 : 1), world).forEach(function (l) { lights.push(l); });
    this.lighting.apply(ctx, {
      ox: ox, oy: oy, w: L.w, h: L.h, pad: cell * 0.7, cell: cell, dpr: this.dpr,
      ambient: ambient, lights: lights, board: g.board,
      rim: alive ? { x: head.x, y: head.y, r: hr * 1.1, c: [255, 214, 150], i: dark ? 0.85 : 0.55 } : null
    });
  };

  Scene.prototype.drawCountdown = function (ctx, cd) {
    var L = this.layoutBox;
    var cx = L.ox + L.w / 2, cy = L.oy + L.h / 2;
    var k = cd.k;
    var scale = 1 + (1 - k) * 0.6;
    ctx.save();
    ctx.globalAlpha = Math.min(1, k * 2.5) * (k < 0.15 ? k / 0.15 : 1);
    ctx.translate(cx, cy);
    ctx.scale(scale, scale);
    var fs = Math.max(40, L.cell * 3.4);
    ctx.font = LM.draw.font("900", fs);
    var tw = ctx.measureText(cd.text).width;
    if (tw > L.w * 0.85) ctx.font = LM.draw.font("900", fs * L.w * 0.85 / tw);
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.lineWidth = 8;
    ctx.strokeStyle = "rgba(0,0,0,.6)";
    ctx.strokeText(cd.text, 0, 0);
    var g = ctx.createLinearGradient(0, -L.cell * 1.5, 0, L.cell * 1.5);
    g.addColorStop(0, "#fff3bf");
    g.addColorStop(1, /\d/.test(cd.text) ? "#f2b84a" : "#ffffff");
    ctx.fillStyle = g;
    ctx.fillText(cd.text, 0, 0);
    ctx.restore();
  };

  // A big centred line of text that slides in (world shifts, combo milestones).
  Scene.prototype.showBanner = function (text, color, t) {
    this.banner = { text: text, color: color || "#ffd98a", at: t };
  };

  Scene.prototype.drawBanner = function (ctx, t) {
    var b = this.banner, age = t - b.at;
    if (age > 1.8) { this.banner = null; return; }
    var L = this.layoutBox;
    var a = age < 0.25 ? age / 0.25 : age > 1.4 ? (1.8 - age) / 0.4 : 1;
    var slide = age < 0.25 ? (1 - age / 0.25) * 40 : 0;
    ctx.save();
    ctx.globalAlpha = a;
    var fs = Math.max(18, L.cell * 1.3);
    ctx.font = LM.draw.font("900", fs);
    var bw = ctx.measureText(b.text).width;
    if (bw > L.w * 0.94) ctx.font = LM.draw.font("900", Math.max(11, fs * L.w * 0.94 / bw));
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    var y = L.oy + L.h * 0.3;
    ctx.lineWidth = 6;
    ctx.strokeStyle = "rgba(0,0,0,.65)";
    ctx.strokeText(b.text, L.ox + L.w / 2 + slide, y);
    ctx.fillStyle = b.color;
    ctx.fillText(b.text, L.ox + L.w / 2 + slide, y);
    ctx.restore();
  };

  LM.Scene = Scene;
})(window.LUMEN);
