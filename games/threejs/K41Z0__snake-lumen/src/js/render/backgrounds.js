window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;
  function clamp01(v) { return v < 0 ? 0 : v > 1 ? 1 : v; }
  function ramp(light, from, span) { return clamp01((light - from) / (span || 0.2)); }
  function mix(a, b, k) { return LM.color.mix(a, b, clamp01(k)); }

  function layer(w, h, dpr, fn) {
    var c = document.createElement("canvas");
    c.width = Math.max(1, Math.ceil(w * dpr));
    c.height = Math.max(1, Math.ceil(h * dpr));
    var x = c.getContext("2d");
    x.scale(dpr, dpr);
    fn(x, w, h);
    c.cssW = w;
    c.cssH = h;
    return c;
  }

  function glowSprite(color, size) {
    return layer(size, size, 1, function (x) {
      var g = x.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
      g.addColorStop(0, color);
      g.addColorStop(0.25, LM.color.alpha(color, 0.5));
      g.addColorStop(1, LM.color.alpha(color, 0));
      x.fillStyle = g;
      x.fillRect(0, 0, size, size);
    });
  }

  // The Moon's face, painted once per size: soft maria, a few craters, a
  // darker limb.
  var moonCache = {};
  function moonFace(r) {
    r = Math.max(6, Math.round(r));
    if (moonCache[r]) return moonCache[r];
    var rng = new LM.Rng(7);
    var c = layer(r * 2, r * 2, 2, function (x) {
      x.save();
      x.beginPath(); x.arc(r, r, r, 0, TAU); x.clip();
      var g = x.createRadialGradient(r * 0.8, r * 0.75, r * 0.1, r, r, r);
      g.addColorStop(0, "#fbfcff");
      g.addColorStop(0.7, "#e2e6f6");
      g.addColorStop(1, "#b9c0db");
      x.fillStyle = g;
      x.fillRect(0, 0, r * 2, r * 2);
      [[0.62, 0.62, 0.3], [0.95, 0.5, 0.22], [0.78, 0.95, 0.24], [1.25, 0.85, 0.18], [1.1, 1.3, 0.2], [0.55, 1.2, 0.14]].forEach(function (m) {
        var mg = x.createRadialGradient(m[0] * r, m[1] * r, 0, m[0] * r, m[1] * r, m[2] * r);
        mg.addColorStop(0, "rgba(140,148,182,.42)");
        mg.addColorStop(0.7, "rgba(150,158,190,.25)");
        mg.addColorStop(1, "rgba(150,158,190,0)");
        x.fillStyle = mg;
        x.fillRect(0, 0, r * 2, r * 2);
      });
      for (var i = 0; i < 14; i++) {
        var cx = r * (0.35 + rng.next() * 1.3), cy = r * (0.35 + rng.next() * 1.3), cr = r * (0.025 + rng.next() * 0.06);
        x.fillStyle = "rgba(120,128,165,.35)";
        x.beginPath(); x.arc(cx, cy, cr, 0, TAU); x.fill();
        x.fillStyle = "rgba(255,255,255,.4)";
        x.beginPath(); x.arc(cx + cr * 0.25, cy + cr * 0.25, cr * 0.75, 0, TAU); x.fill();
        x.fillStyle = "rgba(150,156,190,.35)";
        x.beginPath(); x.arc(cx - cr * 0.1, cy - cr * 0.1, cr * 0.7, 0, TAU); x.fill();
      }
      var limb = x.createRadialGradient(r, r, r * 0.7, r, r, r);
      limb.addColorStop(0, "rgba(60,70,110,0)");
      limb.addColorStop(1, "rgba(60,70,110,.35)");
      x.fillStyle = limb;
      x.fillRect(0, 0, r * 2, r * 2);
      x.restore();
    });
    moonCache[r] = c;
    return c;
  }

  // Draws the Moon. `fill` 0..1: a faint sleeping Moon with a thin lit
  // edge grows into a full, glowing disc.
  function drawMoon(ctx, x, y, r, fill) {
    fill = clamp01(fill);
    var halo = ctx.createRadialGradient(x, y, r * 0.9, x, y, r * (2 + fill * 1.6));
    halo.addColorStop(0, "rgba(220,228,255," + (0.08 + fill * 0.32).toFixed(3) + ")");
    halo.addColorStop(1, "rgba(220,228,255,0)");
    ctx.fillStyle = halo;
    ctx.fillRect(x - r * 3.8, y - r * 3.8, r * 7.6, r * 7.6);
    ctx.drawImage(moonFace(r), x - r, y - r, r * 2, r * 2);
    // the unlit part: a soft shadow that slides off as the light returns
    var sh = 0.12 + fill * 2.1;
    if (sh < 2.15) {
      ctx.save();
      ctx.beginPath(); ctx.arc(x, y, r + 0.5, 0, TAU); ctx.clip();
      ctx.fillStyle = "rgba(24,30,58,.62)";
      ctx.shadowColor = "rgba(24,30,58,.62)";
      ctx.shadowBlur = r * 0.3;
      ctx.beginPath(); ctx.arc(x - r * sh, y - r * sh * 0.1, r * 1.04, 0, TAU); ctx.fill();
      ctx.restore();
    }
  }

  // Backdrops, one per world: a quiet night that wakes as the light (0..1)
  // returns. Static parts are painted into offscreen layers on resize.
  function Backdrop() {
    this.w = 0;
    this.h = 0;
    this.layers = null;
    this.sprites = {
      firefly: glowSprite("#eaffa0", 32),
      star: glowSprite("#e4ebff", 16),
      warm: glowSprite("#ffd98a", 64),
      moon: glowSprite("#e6ebff", 128)
    };
  }

  Backdrop.prototype.resize = function (w, h, dpr) {
    if (w === this.w && h === this.h) return;
    this.w = w;
    this.h = h;
    dpr = Math.min(dpr || 1, 1.5);
    var rng = new LM.Rng(77);
    var L = {};
    var self = this;

    // ---- garden: rolling hills with round trees and cypresses ----
    function ridgeY(px, i) {
      var base = h * (0.56 + i * 0.12);
      return base - Math.sin(px * 0.004 + i * 2) * h * 0.06 - Math.sin(px * 0.011 + i) * h * 0.025;
    }
    function hills(alive) {
      var r = new LM.Rng(91);
      return [0, 1, 2].map(function (i) {
        var lw = w * 1.3;
        return layer(lw, h, dpr, function (x) {
          var cols = alive ? ["#244a3e", "#1c3d31", "#143026"] : ["#26324a", "#1e293e", "#172034"];
          var rim = alive ? "rgba(190,220,200,.22)" : "rgba(190,200,230,.16)";
          x.fillStyle = cols[i];
          x.beginPath();
          x.moveTo(0, h);
          for (var px = 0; px <= lw; px += 8) x.lineTo(px, ridgeY(px, i));
          x.lineTo(lw, h);
          x.fill();
          x.strokeStyle = rim;
          x.lineWidth = 1.5;
          x.beginPath();
          for (px = 0; px <= lw; px += 8) { if (px === 0) x.moveTo(px, ridgeY(px, i)); else x.lineTo(px, ridgeY(px, i)); }
          x.stroke();
          if (i > 0) {
            for (var t = 0; t < 14; t++) {
              var tx = r.next() * lw, ty = ridgeY(tx, i) + 2;
              var s = (9 + r.next() * 12) * (i === 2 ? 1.5 : 1);
              x.fillStyle = cols[i];
              if (r.next() < 0.6) {
                x.fillRect(tx - s * 0.08, ty - s * 1.2, s * 0.16, s * 1.2);
                [[0, -1.6, 0.8], [-0.5, -1.25, 0.6], [0.5, -1.2, 0.62], [0, -2.1, 0.55]].forEach(function (b) {
                  x.beginPath(); x.arc(tx + b[0] * s, ty + b[1] * s, b[2] * s, 0, TAU); x.fill();
                });
                x.fillStyle = rim;
                x.beginPath(); x.arc(tx + 0.15 * s, ty - 2.2 * s, 0.35 * s, Math.PI * 1.1, Math.PI * 1.9); x.lineWidth = 1.5; x.strokeStyle = rim; x.stroke();
              } else {
                x.beginPath();
                x.moveTo(tx, ty - s * 2.6);
                x.quadraticCurveTo(tx + s * 0.5, ty - s * 1.2, tx + s * 0.3, ty);
                x.lineTo(tx - s * 0.3, ty);
                x.quadraticCurveTo(tx - s * 0.5, ty - s * 1.2, tx, ty - s * 2.6);
                x.fill();
              }
            }
          }
        });
      });
    }
    L.hillsDark = hills(false);
    L.hillsLit = hills(true);
    this.flowers = [];
    var fcols = ["#ff9cc8", "#ffd166", "#fff1f7", "#c7a6ff", "#ff9f7a", "#a8e6a0"];
    for (var f = 0; f < 80; f++) {
      var ri = 1 + (f % 2);
      var fx = rng.next() * w * 1.3;
      this.flowers.push({ x: fx, y: ridgeY(fx, ri) + 6 + rng.next() * h * 0.12 * ri, r: ri, th: 0.1 + rng.next() * 0.85,
        c: fcols[rng.int(fcols.length)], s: (2.4 + rng.next() * 2.5) * (ri === 2 ? 1.4 : 1), p: rng.next() * TAU });
    }

    // ---- city: an old town of gabled houses, a clock tower and a church ----
    L.town = [];
    L.windows = [];
    this.chimneys = [];
    var townFloor = [h * 0.66, h * 0.76, h * 0.88];
    for (var i = 0; i < 3; i++) {
      var lw = w * (1.2 + i * 0.1);
      var houses = [];
      var px = -20, floorY = townFloor[i];
      var scale = [0.7, 0.9, 1.15][i];
      while (px < lw + 20) {
        var bw = (38 + rng.next() * 40) * scale;
        var bh = (36 + rng.next() * 60) * scale;
        var kind = rng.next();
        houses.push({ x: px, w: bw, h: bh, floor: floorY, roof: (16 + rng.next() * 18) * scale, kind: kind,
          chimney: rng.next() < 0.55, cx: 0.2 + rng.next() * 0.55, tower: i === 0 && rng.next() < 0.08 });
        px += bw - 2;
      }
      (function (houses, i, lw) {
        var col = ["#222b48", "#1a2139", "#13192b"][i];
        var rim = "rgba(200,212,245," + [0.16, 0.2, 0.24][i] + ")";
        L.town.push(layer(lw, h, dpr, function (x) {
          houses.forEach(function (hs) {
            var top = hs.floor - hs.h;
            x.fillStyle = col;
            x.fillRect(hs.x, top, hs.w, h - top);
            // roof: gable, steep gable or a little dome
            x.beginPath();
            if (hs.tower) {
              x.fillRect(hs.x + hs.w * 0.3, top - hs.h * 0.9, hs.w * 0.4, hs.h * 0.9);
              x.moveTo(hs.x + hs.w * 0.25, top - hs.h * 0.9);
              x.lineTo(hs.x + hs.w * 0.5, top - hs.h * 1.5);
              x.lineTo(hs.x + hs.w * 0.75, top - hs.h * 0.9);
            } else if (hs.kind < 0.65) {
              x.moveTo(hs.x - 2, top);
              x.lineTo(hs.x + hs.w / 2, top - hs.roof);
              x.lineTo(hs.x + hs.w + 2, top);
            } else {
              x.moveTo(hs.x, top);
              x.lineTo(hs.x + hs.w * 0.15, top - hs.roof * 0.6);
              x.lineTo(hs.x + hs.w * 0.85, top - hs.roof * 0.6);
              x.lineTo(hs.x + hs.w, top);
            }
            x.closePath();
            x.fill();
            x.strokeStyle = rim;
            x.lineWidth = 1.2;
            x.stroke();
            if (hs.chimney && !hs.tower) {
              var chx = hs.x + hs.w * hs.cx, chy = top - hs.roof * (hs.kind < 0.65 ? 1 - Math.abs(hs.cx - 0.5) * 2 : 0.6) - 4;
              x.fillStyle = col;
              x.fillRect(chx, chy - 10 * scale, 7 * scale, 14 * scale);
              x.fillRect(chx - 1.5, chy - 11 * scale, 10 * scale, 3);
              if (i > 0) self.chimneys.push({ layer: i, x: chx + 3.5 * scale, y: chy - 11 * scale, s: scale });
            }
          });
          if (i === 0) {
            // a clock tower and a church spire on the skyline
            [[0.3, 1.0], [0.72, 0.8]].forEach(function (tw, k) {
              var tx = lw * tw[0], ty = townFloor[0] - h * 0.2 * tw[1];
              x.fillStyle = col;
              x.fillRect(tx - 14, ty, 28, h);
              x.beginPath();
              if (k === 0) { x.moveTo(tx - 18, ty); x.lineTo(tx, ty - 46); x.lineTo(tx + 18, ty); }
              else { x.moveTo(tx - 16, ty); x.lineTo(tx, ty - 70); x.lineTo(tx + 16, ty); }
              x.fill();
              x.strokeStyle = rim;
              x.stroke();
              if (k === 0) {
                x.fillStyle = "#3a4466";
                x.beginPath(); x.arc(tx, ty + 18, 9, 0, TAU); x.fill();
              }
            });
          }
        }));
        var buckets = [];
        for (var b = 0; b < 5; b++) {
          (function (b) {
            var wr = new LM.Rng(500 + i * 10 + b);
            buckets.push(layer(lw, h, dpr, function (x) {
              houses.forEach(function (hs) {
                var top = hs.floor - hs.h;
                var floors = Math.max(1, Math.floor(hs.h / (22 * scale)));
                var per = Math.max(1, Math.floor(hs.w / (18 * scale)));
                for (var fl = 0; fl < floors; fl++) {
                  for (var c = 0; c < per; c++) {
                    if (wr.next() > 0.2) continue;
                    var ww = 6 * scale, wh = 8 * scale;
                    var wx = hs.x + (c + 0.5) * hs.w / per - ww / 2, wy = top + 8 * scale + fl * 22 * scale;
                    if (wy + wh > hs.floor - 4) continue;
                    x.fillStyle = "rgba(255,204,128,.18)";
                    x.fillRect(wx - 3, wy - 3, ww + 6, wh + 6);
                    x.fillStyle = "rgba(255,206,130,.95)";
                    x.fillRect(wx, wy, ww, wh);
                    x.fillStyle = "rgba(80,48,30,.7)";
                    x.fillRect(wx + ww / 2 - 0.5, wy, 1, wh);
                    x.fillRect(wx, wy + wh / 2 - 0.5, ww, 1);
                  }
                }
              });
            }));
          })(b);
        }
        L.windows.push(buckets);
      })(houses, i, lw);
    }
    this.lamps = [];
    for (var lp = 0; lp < 9; lp++) this.lamps.push({ x: (lp + 0.5) / 9, th: 0.12 + rng.next() * 0.7 });

    // ---- the night sky: star fields, a milky band ----
    L.stars = [0, 1, 2].map(function (i) {
      return layer(w, h, dpr, function (x) {
        var n = Math.round((w * h) / (2400 + i * 2200));
        for (var s = 0; s < n; s++) {
          var r = (0.4 + rng.next() * 0.8) * (1 + i * 0.45);
          x.globalAlpha = 0.35 + rng.next() * 0.6;
          x.fillStyle = rng.next() < 0.15 ? "#ffe6b8" : rng.next() < 0.3 ? "#c8dcff" : "#ffffff";
          x.beginPath();
          x.arc(rng.next() * w, rng.next() * h * 0.8, r, 0, TAU);
          x.fill();
        }
      });
    });
    L.band = layer(w, h, Math.min(dpr, 0.75), function (x) {
      x.save();
      x.translate(w * 0.5, h * 0.35);
      x.rotate(-0.42);
      var g = x.createLinearGradient(0, -h * 0.16, 0, h * 0.16);
      g.addColorStop(0, "rgba(200,212,255,0)");
      g.addColorStop(0.5, "rgba(200,212,255,.14)");
      g.addColorStop(1, "rgba(200,212,255,0)");
      x.fillStyle = g;
      x.fillRect(-w, -h * 0.16, w * 2, h * 0.32);
      for (var s = 0; s < 500; s++) {
        x.globalAlpha = 0.2 + rng.next() * 0.5;
        x.fillStyle = "#ffffff";
        var yy = (rng.next() + rng.next() + rng.next() - 1.5) * h * 0.1;
        x.fillRect((rng.next() - 0.5) * w * 2, yy, 1, 1);
      }
      x.restore();
    });
    this.constellations = [];
    for (var c = 0; c < 5; c++) {
      var ccx = (0.1 + c * 0.2) * w, ccy = (0.12 + rng.next() * 0.25) * h, pts = [];
      for (var k = 0; k < 5; k++) pts.push({ x: ccx + (rng.next() - 0.5) * w * 0.14, y: ccy + (rng.next() - 0.5) * h * 0.14 });
      this.constellations.push({ pts: pts, th: 0.25 + c * 0.15 });
    }

    // ---- the sea of clouds below the Hollow Sky ----
    L.clouds = [0, 1, 2].map(function (i) {
      var lw = w * 1.4;
      var r = new LM.Rng(600 + i);
      return [false, true].map(function (alive) {
        return layer(lw, h, Math.min(dpr, 1), function (x) {
          var base = h * (0.66 + i * 0.1);
          var top = alive ? ["#9aa6d2", "#aab5de", "#c3cbee"][i] : ["#5d6684", "#6b7491", "#7b839d"][i];
          var body = alive ? ["#465486", "#3c4878", "#323d68"][i] : ["#363d55", "#30364c", "#292f43"][i];
          var rr = new LM.Rng(600 + i);
          void r;
          for (var p = 0; p < lw / 22; p++) {
            var cx = rr.next() * lw, cr = (28 + rr.next() * 46) * (1 + i * 0.35), cy = base + rr.next() * 18;
            var g = x.createRadialGradient(cx - cr * 0.2, cy - cr * 0.55, cr * 0.1, cx, cy, cr);
            g.addColorStop(0, top);
            g.addColorStop(0.55, body);
            g.addColorStop(1, body);
            x.fillStyle = g;
            x.beginPath(); x.arc(cx, cy, cr, 0, TAU); x.fill();
          }
          x.fillStyle = body;
          x.fillRect(0, base + 14, lw, h);
        });
      });
    });

    // ---- the Moon's Path: a path of light on still water ----
    this.stones = [];
    for (var s2 = 0; s2 < 16; s2++) {
      var k2 = s2 / 15;
      this.stones.push({ k: k2, wob: Math.sin(s2 * 1.7) * 0.5, th: k2 * 0.85 + 0.05 });
    }

    this.layers = L;
    this.flies = [];
    for (var fl = 0; fl < 40; fl++) this.flies.push({ x: rng.next(), y: 0.4 + rng.next() * 0.55, p: rng.next() * TAU, s: 0.5 + rng.next(), th: rng.next() });
    this.petals = [];
    for (var pe = 0; pe < 14; pe++) this.petals.push({ x: rng.next(), y: rng.next(), s: 0.6 + rng.next() * 0.8, p: rng.next() * TAU });
    this.motes = [];
    for (var m = 0; m < 40; m++) this.motes.push({ x: rng.next(), y: rng.next(), s: 0.4 + rng.next(), p: rng.next() * TAU });
  };

  // opts: { light: 0..1, reduced, moon: extra Moon brightness for the finale, story }
  Backdrop.prototype.draw = function (ctx, world, t, px, py, opts) {
    if (!this.layers) return;
    opts = opts || {};
    var light = opts.light === undefined ? 1 : clamp01(opts.light);
    var fn = [this.garden, this.city, this.skyWorld, this.moonPath][world] || this.garden;
    fn.call(this, ctx, this.w, this.h, t, px || 0, py || 0, light, opts);
  };

  Backdrop.prototype.sky = function (ctx, w, h, a, b) {
    var g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, a);
    g.addColorStop(1, b);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);
  };

  Backdrop.prototype.theMoon = function (ctx, x, y, r, fill) { drawMoon(ctx, x, y, r, fill); };

  Backdrop.prototype.drawStars = function (ctx, w, h, t, px, py, light, base) {
    var stars = this.layers.stars;
    for (var i = 0; i < 3; i++) {
      var a = clamp01(base + ramp(light, i * 0.25, 0.35) * (1 - base));
      if (a <= 0.01) continue;
      ctx.globalAlpha = a * (i === 0 ? 0.8 + 0.2 * Math.sin(t * 1.3) : 1);
      ctx.drawImage(stars[i], -px * (i + 1) * 6, -py * (i + 1) * 4, w, h);
    }
    ctx.globalAlpha = 1;
  };

  Backdrop.prototype.garden = function (ctx, w, h, t, px, py, light) {
    this.sky(ctx, w, h, mix("#121d3a", "#15284e", light), mix("#22304e", "#2a4a5e", light));
    this.drawStars(ctx, w, h, t, px * 0.3, py * 0.3, light * 0.7, 0.25);
    drawMoon(ctx, w * 0.82 - px * 6, h * 0.17 - py * 4, Math.min(w, h) * 0.05, 0.25 + light * 0.45);
    var hd = this.layers.hillsDark, hl = this.layers.hillsLit;
    var self = this;
    for (var i = 0; i < 3; i++) {
      var depth = (i + 1) * 10;
      var hx = -w * 0.15 - px * depth, hy = -py * depth * 0.5;
      ctx.drawImage(hd[i], hx, hy, hd[i].cssW, hd[i].cssH);
      if (light > 0.01) {
        ctx.globalAlpha = light;
        ctx.drawImage(hl[i], hx, hy, hl[i].cssW, hl[i].cssH);
        ctx.globalAlpha = 1;
      }
      if (i > 0) {
        self.flowers.forEach(function (fl) {
          if (fl.r !== i) return;
          var k = ramp(light, fl.th, 0.12);
          var x = fl.x + hx, y = fl.y + hy;
          if (x < -10 || x > w + 10) return;
          ctx.fillStyle = "rgba(80,130,100,.7)";
          ctx.fillRect(x - 0.6, y - fl.s * 0.4, 1.2, fl.s * 1.4);
          if (k <= 0) {
            ctx.fillStyle = "rgba(150,170,180,.55)";
            ctx.beginPath(); ctx.arc(x, y - fl.s * 0.5, fl.s * 0.25, 0, TAU); ctx.fill();
            return;
          }
          var r = fl.s * (0.35 + 0.65 * k);
          ctx.fillStyle = fl.c;
          for (var p = 0; p < 5; p++) {
            var a = p * TAU / 5 + fl.p + Math.sin(t + fl.p) * 0.2;
            ctx.beginPath();
            ctx.arc(x + Math.cos(a) * r * 0.7 * k, y - fl.s * 0.5 + Math.sin(a) * r * 0.7 * k, r * 0.5, 0, TAU);
            ctx.fill();
          }
          ctx.fillStyle = "#fff3bf";
          ctx.beginPath();
          ctx.arc(x, y - fl.s * 0.5, r * 0.35, 0, TAU);
          ctx.fill();
        });
      }
    }
    ctx.globalCompositeOperation = "lighter";
    for (var f = 0; f < this.flies.length; f++) {
      var fl = this.flies[f];
      if (fl.th > 0.15 + light) continue;
      var fx = ((fl.x * w + Math.sin(t * 0.3 * fl.s + fl.p) * 40 - px * 20) % w + w) % w;
      var fy = fl.y * h + Math.cos(t * 0.4 * fl.s + fl.p) * 24 - py * 14;
      ctx.globalAlpha = 0.35 + 0.65 * Math.max(0, Math.sin(t * 1.6 * fl.s + fl.p));
      ctx.drawImage(this.sprites.firefly, fx - 10, fy - 10, 20, 20);
    }
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = "source-over";
    var pa = ramp(light, 0.5, 0.3);
    if (pa > 0) {
      for (var p2 = 0; p2 < this.petals.length; p2++) {
        var pe = this.petals[p2];
        var yy = ((pe.y * h + t * 18 * pe.s) % (h + 40)) - 20;
        var xx = (pe.x * w + Math.sin(t * 0.7 + pe.p) * 30 + t * 8 * pe.s) % w;
        ctx.save();
        ctx.translate(xx, yy);
        ctx.rotate(t * pe.s + pe.p);
        ctx.globalAlpha = pa;
        ctx.fillStyle = p2 % 3 ? "rgba(255,190,210,.55)" : "rgba(255,236,170,.5)";
        ctx.beginPath();
        ctx.ellipse(0, 0, 5 * pe.s + 2, 2.4 * pe.s + 1, 0, 0, TAU);
        ctx.fill();
        ctx.restore();
      }
      ctx.globalAlpha = 1;
    }
  };

  Backdrop.prototype.city = function (ctx, w, h, t, px, py, light, opts) {
    this.sky(ctx, w, h, mix("#121c3a", "#172a52", light), mix("#2a2f4c", "#4a3f58", light));
    this.drawStars(ctx, w, h, t, px * 0.3, py * 0.3, light * 0.5, 0.25);
    drawMoon(ctx, w * 0.2 - px * 6, h * 0.16 - py * 4, Math.min(w, h) * 0.045, 0.25 + light * 0.45);
    var hz = ctx.createLinearGradient(0, h * 0.45, 0, h);
    hz.addColorStop(0, "rgba(255,190,120,0)");
    hz.addColorStop(1, "rgba(255,190,120," + (0.05 + 0.14 * light).toFixed(3) + ")");
    ctx.fillStyle = hz;
    ctx.fillRect(0, h * 0.45, w, h * 0.55);
    var town = this.layers.town, win = this.layers.windows;
    for (var i = 0; i < 3; i++) {
      var ox = -w * 0.08 - px * (i + 1) * 12, oy = -py * (i + 1) * 5;
      ctx.drawImage(town[i], ox, oy, town[i].cssW, town[i].cssH);
      for (var b = 0; b < 5; b++) {
        var a = ramp(light, 0.06 + b * 0.18, 0.12);
        if (a <= 0) break;
        ctx.globalAlpha = a;
        ctx.drawImage(win[i][b], ox, oy, town[i].cssW, town[i].cssH);
      }
      ctx.globalAlpha = 1;
      // chimney smoke drifts up once the town is waking
      var sk = ramp(light, 0.35, 0.3);
      if (sk > 0 && !opts.reduced) {
        for (var c = 0; c < this.chimneys.length; c++) {
          var ch = this.chimneys[c];
          if (ch.layer !== i) continue;
          for (var p = 0; p < 3; p++) {
            var age = (t * 0.12 + c * 0.37 + p / 3) % 1;
            ctx.fillStyle = "rgba(200,206,226," + (0.1 * sk * (1 - age)).toFixed(3) + ")";
            ctx.beginPath();
            ctx.arc(ch.x + ox + age * 18 * ch.s + Math.sin(age * 6 + c) * 3, ch.y + oy - age * 40 * ch.s, (3 + age * 9) * ch.s, 0, TAU);
            ctx.fill();
          }
        }
      }
    }
    // the cobbled street and its lanterns
    var hy = h * 0.9 - py * 6;
    ctx.fillStyle = "#151a2a";
    ctx.fillRect(0, hy, w, h - hy);
    ctx.fillStyle = "rgba(200,210,240,.06)";
    for (var cx = 0; cx < w; cx += 14) ctx.fillRect(cx + ((cx / 14) % 2) * 7, hy + 6, 10, 3);
    for (var l = 0; l < this.lamps.length; l++) {
      var lamp = this.lamps[l];
      var lx = ((lamp.x * w - px * 30) % w + w) % w;
      ctx.fillStyle = "#0d101c";
      ctx.fillRect(lx - 1.5, hy - 42, 3, 42);
      ctx.fillRect(lx - 1.5, hy - 42, 9, 2);
      ctx.fillRect(lx + 4, hy - 48, 8, 10);
      var k = ramp(light, lamp.th, 0.08);
      if (k > 0) {
        ctx.globalAlpha = k;
        ctx.drawImage(this.sprites.warm, lx + 8 - 30, hy - 43 - 30, 60, 60);
        ctx.fillStyle = "#ffe9b8";
        ctx.fillRect(lx + 5.5, hy - 46.5, 5, 7);
        var pool = ctx.createRadialGradient(lx + 8, hy + 6, 0, lx + 8, hy + 6, 46);
        pool.addColorStop(0, "rgba(255,210,140,.3)");
        pool.addColorStop(1, "rgba(255,210,140,0)");
        ctx.fillStyle = pool;
        ctx.fillRect(lx - 40, hy - 6, 96, 40);
        ctx.globalAlpha = 1;
      }
    }
  };

  Backdrop.prototype.drawConstellations = function (ctx, px, py, light) {
    for (var c = 0; c < this.constellations.length; c++) {
      var con = this.constellations[c], k = ramp(light, con.th, 0.18);
      if (k <= 0) continue;
      ctx.strokeStyle = "rgba(210,222,255," + (0.3 * k).toFixed(3) + ")";
      ctx.lineWidth = 1;
      ctx.beginPath();
      var seg = k * (con.pts.length - 1);
      for (var j = 0; j < con.pts.length; j++) {
        var q = con.pts[j], x = q.x - px * 10, y = q.y - py * 10;
        if (j === 0) ctx.moveTo(x, y);
        else if (j <= seg) ctx.lineTo(x, y);
        else { var pr = con.pts[j - 1], f = seg - (j - 1); if (f > 0) ctx.lineTo(pr.x - px * 10 + (q.x - pr.x) * f, pr.y - py * 10 + (q.y - pr.y) * f); break; }
      }
      ctx.stroke();
      ctx.globalCompositeOperation = "lighter";
      for (j = 0; j < con.pts.length; j++) {
        ctx.globalAlpha = k;
        ctx.drawImage(this.sprites.star, con.pts[j].x - px * 10 - 8, con.pts[j].y - py * 10 - 8, 16, 16);
      }
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = "source-over";
    }
  };

  Backdrop.prototype.skyWorld = function (ctx, w, h, t, px, py, light) {
    this.sky(ctx, w, h, mix("#0f1734", "#122152", light), mix("#262f52", "#34467a", light));
    var ba = ramp(light, 0.3, 0.5);
    if (ba > 0) {
      ctx.globalAlpha = ba;
      ctx.drawImage(this.layers.band, -px * 6, -py * 6, this.w, this.h);
      ctx.globalAlpha = 1;
    }
    this.drawStars(ctx, w, h, t, px, py, light, 0.3);
    this.drawConstellations(ctx, px, py, light);
    drawMoon(ctx, w * 0.16 - px * 8, h * 0.2 - py * 6, Math.min(w, h) * 0.055, 0.3 + light * 0.45);
    // shooting stars come back last
    if (light > 0.4) {
      var cyc = t % 6;
      if (cyc < 0.9) {
        var kk = cyc / 0.9, seed = Math.floor(t / 6);
        var x0 = ((seed * 377) % 100) / 100 * w, y0 = ((seed * 211) % 40) / 100 * h;
        var x1 = x0 + kk * w * 0.35, y1 = y0 + kk * h * 0.2;
        var lg = ctx.createLinearGradient(x1 - 80, y1 - 45, x1, y1);
        lg.addColorStop(0, "rgba(255,240,200,0)");
        lg.addColorStop(1, "rgba(255,240,200," + (1 - kk) + ")");
        ctx.strokeStyle = lg;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(x1 - 80, y1 - 45);
        ctx.lineTo(x1, y1);
        ctx.stroke();
      }
    }
    // the sea of clouds, drifting slowly
    var cl = this.layers.clouds;
    for (var i = 0; i < 3; i++) {
      var lw = cl[i][0].cssW;
      var ox = -((t * (2 + i * 3) + px * (i + 1) * 14) % (lw - w)) - 1;
      var oy = -py * (i + 1) * 6;
      ctx.drawImage(cl[i][0], ox, oy, lw, cl[i][0].cssH);
      if (light > 0.01) {
        ctx.globalAlpha = light;
        ctx.drawImage(cl[i][1], ox, oy, lw, cl[i][1].cssH);
        ctx.globalAlpha = 1;
      }
    }
  };

  Backdrop.prototype.moonPath = function (ctx, w, h, t, px, py, light, opts) {
    var full = clamp01(light + (opts.moon || 0));
    this.sky(ctx, w, h, mix("#0d1430", "#15214a", full), mix("#222a4c", "#3a4676", full));
    this.drawStars(ctx, w, h, t, px * 0.5, py * 0.5, full * 0.8, 0.3);
    var story = !!opts.story;
    var mr = Math.min(w, h) * (story ? 0.2 : 0.3);
    var mx = (story ? w * 0.5 : w * 0.84) - px * 6, my = (story ? h * 0.38 : h * 0.3) - py * 4;
    drawMoon(ctx, mx, my, mr, 0.15 + full * 0.85);
    // still water, and the Moon's light laid across it as a path
    var horizon = h * (story ? 0.66 : 0.7) - py * 5;
    var wg = ctx.createLinearGradient(0, horizon, 0, h);
    wg.addColorStop(0, mix("#1a2140", "#283662", full));
    wg.addColorStop(1, mix("#0c1024", "#121a38", full));
    ctx.fillStyle = wg;
    ctx.fillRect(0, horizon, w, h - horizon);
    ctx.fillStyle = "rgba(220,228,255," + (0.15 + 0.25 * full).toFixed(3) + ")";
    ctx.fillRect(0, horizon - 0.5, w, 1);
    var pathA = 0.2 + 0.6 * full;
    // where the path reaches the viewer: straight below the Moon while playing,
    // so it shows beside the board; toward the middle in the story scenes
    var endX = story ? w * 0.5 : Math.min(w * 0.93, mx + w * 0.04);
    for (var r = 0; r < 34; r++) {
      var k = r / 33, y = horizon + 3 + k * k * (h - horizon);
      var half = (mr * 0.35 + k * w * 0.08) * (0.55 + 0.45 * Math.sin(t * 1.5 + r * 1.3));
      var cx = mx + (endX - mx) * k + Math.sin(t * 0.8 + r) * 3;
      ctx.fillStyle = "rgba(230,236,255," + (pathA * (0.5 + 0.5 * (1 - k))).toFixed(3) + ")";
      ctx.fillRect(cx - half, y, half * 2, 1 + k * 2.5);
    }
    // stepping stones along the path, lighting one after another
    for (var s = 0; s < this.stones.length; s++) {
      var st = this.stones[s], kk = 1 - st.k;
      var sy = horizon + 6 + kk * kk * (h - horizon - 10);
      var sx = mx + (endX - mx) * kk + st.wob * 30 * kk;
      var rw = 4 + kk * w * 0.014, rh = rw * 0.26;
      var lit = ramp(full, st.th, 0.08);
      ctx.fillStyle = mix("#2c3456", "#c9d2f4", lit * 0.7);
      ctx.beginPath(); ctx.ellipse(sx, sy, rw, rh, 0, 0, TAU); ctx.fill();
      if (lit > 0) {
        ctx.globalAlpha = lit * (0.3 + 0.15 * Math.sin(t * 2 + s));
        ctx.drawImage(this.sprites.moon, sx - rw * 1.6, sy - rw * 1.6, rw * 3.2, rw * 3.2);
        ctx.globalAlpha = 1;
      }
    }
    ctx.globalCompositeOperation = "lighter";
    for (var m = 0; m < this.motes.length; m++) {
      var mo = this.motes[m];
      if (mo.p / TAU > full + 0.15) continue;
      var my2 = h - ((mo.y * h + t * 14 * mo.s) % h);
      var mx2 = mo.x * w + Math.sin(t * 0.5 + mo.p) * 20 - px * 10;
      ctx.globalAlpha = 0.45 * (0.5 + 0.5 * Math.sin(t * 2 + mo.p));
      ctx.drawImage(this.sprites.star, mx2 - 5, my2 - 5, 10, 10);
    }
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = "source-over";
  };

  LM.Backdrop = Backdrop;
  LM.makeLayer = layer;
  LM.glowSprite = glowSprite;
  LM.drawMoon = drawMoon;
})(window.LUMEN);
