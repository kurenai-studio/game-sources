window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;

  // The world map is an old star chart: a hand-inked night sky with a path of
  // light that links every level and runs toward the Moon. The DOM places the
  // level buttons (so CSS decides landscape or portrait); this canvas reads
  // where they ended up and inks the chart around them.
  var TINT = ["158,196,140", "255,200,120", "160,180,255", "225,230,255"];

  function offsetIn(el, root) {
    var x = 0, y = 0, e = el;
    while (e && e !== root) { x += e.offsetLeft; y += e.offsetTop; e = e.offsetParent; }
    return { x: x + el.offsetWidth / 2, y: y + el.offsetHeight / 2 };
  }

  function jitter(rng, a) { return (rng.next() - 0.5) * 2 * a; }

  // a line that wobbles a little, like ink on paper
  function inkLine(ctx, a, b, rng, bend) {
    var mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
    var dx = b.x - a.x, dy = b.y - a.y, d = Math.sqrt(dx * dx + dy * dy) || 1;
    var off = bend * d;
    ctx.moveTo(a.x, a.y);
    ctx.quadraticCurveTo(mx - dy / d * off + jitter(rng, 2), my + dx / d * off + jitter(rng, 2), b.x, b.y);
  }

  function star4(ctx, x, y, r) {
    ctx.beginPath();
    ctx.moveTo(x, y - r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.quadraticCurveTo(x, y, x, y + r);
    ctx.quadraticCurveTo(x, y, x - r, y);
    ctx.quadraticCurveTo(x, y, x, y - r);
    ctx.fill();
  }

  function compass(ctx, x, y, r) {
    ctx.save();
    ctx.translate(x, y);
    ctx.strokeStyle = "rgba(230,235,255,.22)";
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(0, 0, r, 0, TAU); ctx.stroke();
    ctx.beginPath(); ctx.arc(0, 0, r * 0.78, 0, TAU); ctx.stroke();
    for (var i = 0; i < 32; i++) {
      var a = i / 32 * TAU, l = i % 4 ? 0.9 : 0.82;
      ctx.beginPath(); ctx.moveTo(Math.cos(a) * r * l, Math.sin(a) * r * l); ctx.lineTo(Math.cos(a) * r, Math.sin(a) * r); ctx.stroke();
    }
    for (var k = 0; k < 8; k++) {
      var ang = k / 8 * TAU - Math.PI / 2, len = k % 2 ? r * 0.45 : r * 0.92, w = r * 0.12;
      ctx.save();
      ctx.rotate(ang);
      ctx.fillStyle = k === 0 ? "rgba(255,217,138,.55)" : "rgba(230,235,255," + (k % 2 ? 0.14 : 0.24) + ")";
      ctx.beginPath(); ctx.moveTo(len, 0); ctx.lineTo(0, w); ctx.lineTo(-w * 0.2, 0); ctx.lineTo(0, -w); ctx.closePath(); ctx.fill();
      ctx.restore();
    }
    ctx.restore();
  }

  // tiny ink drawings, one per world
  function doodle(ctx, wi, x, y, s) {
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(s, s);
    ctx.lineWidth = 1.2 / s;
    ctx.lineJoin = ctx.lineCap = "round";
    ctx.strokeStyle = "rgba(" + TINT[wi] + ",.38)";
    ctx.fillStyle = "rgba(" + TINT[wi] + ",.12)";
    ctx.beginPath();
    if (wi === 0) {
      // a round tree, a cypress and two flowers
      ctx.arc(-10, -8, 9, 0, TAU); ctx.moveTo(-10, 1); ctx.lineTo(-10, 12);
      ctx.moveTo(8, 12); ctx.quadraticCurveTo(4, -2, 8, -16); ctx.quadraticCurveTo(12, -2, 8, 12);
      ctx.moveTo(20, 12); ctx.lineTo(20, 4); ctx.moveTo(23, 4); ctx.arc(20, 4, 3, 0, TAU);
      ctx.moveTo(-22, 12); ctx.lineTo(-22, 6); ctx.moveTo(-19.5, 6); ctx.arc(-22, 6, 2.5, 0, TAU);
      ctx.moveTo(-30, 12); ctx.lineTo(30, 12);
    } else if (wi === 1) {
      // rooftops with a chimney and a lit window
      ctx.moveTo(-30, 12); ctx.lineTo(-30, -2); ctx.lineTo(-20, -12); ctx.lineTo(-10, -2); ctx.lineTo(-10, 12);
      ctx.moveTo(-10, 0); ctx.lineTo(4, -16); ctx.lineTo(18, 0); ctx.lineTo(18, 12);
      ctx.moveTo(18, 4); ctx.lineTo(24, -4); ctx.lineTo(30, 4); ctx.lineTo(30, 12);
      ctx.moveTo(10, -9); ctx.lineTo(10, -16); ctx.lineTo(13, -16); ctx.lineTo(13, -6);
      ctx.moveTo(-32, 12); ctx.lineTo(32, 12);
      ctx.stroke();
      ctx.fillStyle = "rgba(255,210,130,.5)";
      ctx.fillRect(1, -1, 5, 5); ctx.fillRect(-23, 2, 4, 4);
      ctx.restore();
      return;
    } else if (wi === 2) {
      // a cloud with a small constellation above it
      ctx.moveTo(-26, 10);
      ctx.arc(-16, 4, 8, Math.PI * 0.9, Math.PI * 1.75);
      ctx.arc(-2, -2, 11, Math.PI * 1.15, Math.PI * 1.95);
      ctx.arc(15, 4, 9, Math.PI * 1.3, Math.PI * 0.1);
      ctx.lineTo(-26, 10);
      ctx.moveTo(-20, -18); ctx.lineTo(-6, -22); ctx.lineTo(6, -16); ctx.lineTo(20, -24);
    } else {
      // stepping stones toward a crescent
      ctx.ellipse(-24, 12, 6, 2.2, 0, 0, TAU);
      ctx.moveTo(-6, 6); ctx.ellipse(-10, 6, 5, 2, 0, 0, TAU);
      ctx.moveTo(6, 1); ctx.ellipse(2, 1, 4, 1.6, 0, 0, TAU);
      ctx.moveTo(24, -14); ctx.arc(18, -14, 8, -1.1, 1.1, true);
      ctx.quadraticCurveTo(14, -14, 21.4, -7.3);
    }
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }

  function draw(root, canvas, info) {
    if (!root.isConnected) return false;
    var w = root.clientWidth, hgt = root.clientHeight;
    if (!w || !hgt) return true;
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(hgt * dpr);
    canvas.style.width = w + "px";
    canvas.style.height = hgt + "px";
    var ctx = canvas.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    var rng = new LM.Rng(2026);
    var portrait = w < 640;

    // the paper: deep night blue, a little lighter in the middle
    var bg = ctx.createRadialGradient(w * 0.55, hgt * 0.45, 0, w * 0.55, hgt * 0.45, Math.max(w, hgt) * 0.75);
    bg.addColorStop(0, "#18203d");
    bg.addColorStop(1, "#0b1024");
    ctx.fillStyle = bg;
    LM.draw.roundRect(ctx, 0, 0, w, hgt, 20);
    ctx.fill();
    ctx.save();
    LM.draw.roundRect(ctx, 0, 0, w, hgt, 20);
    ctx.clip();

    // chart lines: arcs of declination around a far pole and a few meridians
    var pole = portrait ? { x: w * 1.3, y: -hgt * 0.15 } : { x: w * 1.05, y: -hgt * 0.6 };
    ctx.strokeStyle = "rgba(200,212,255,.06)";
    ctx.lineWidth = 1;
    for (var ri = 1; ri < 14; ri++) {
      ctx.beginPath();
      ctx.arc(pole.x, pole.y, ri * Math.max(w, hgt) * 0.13, 0, TAU);
      ctx.stroke();
    }
    for (var mi = 0; mi < 12; mi++) {
      var ma = Math.PI * 0.5 + mi * 0.11;
      ctx.beginPath();
      ctx.moveTo(pole.x, pole.y);
      ctx.lineTo(pole.x + Math.cos(ma) * 4000, pole.y + Math.sin(ma) * 4000);
      ctx.stroke();
    }

    // background stars
    for (var s = 0; s < Math.round(w * hgt / 2600); s++) {
      var sx = rng.next() * w, sy = rng.next() * hgt, big = rng.next();
      ctx.fillStyle = "rgba(230,235,255," + (0.15 + rng.next() * 0.45).toFixed(2) + ")";
      if (big > 0.97) star4(ctx, sx, sy, 3.5);
      else { ctx.beginPath(); ctx.arc(sx, sy, big > 0.85 ? 1.2 : 0.7, 0, TAU); ctx.fill(); }
    }

    // a soft wash of colour behind each world
    info.groups.forEach(function (g, wi) {
      if (!g.length) return;
      var cx = 0, cy = 0;
      g.forEach(function (p) { cx += p.x; cy += p.y; });
      cx /= g.length; cy /= g.length;
      var rr = portrait ? w * 0.6 : w * 0.17;
      var wash = ctx.createRadialGradient(cx, cy, 0, cx, cy, rr);
      var a = info.open[wi] ? 0.12 : 0.05;
      wash.addColorStop(0, "rgba(" + TINT[wi] + "," + a + ")");
      wash.addColorStop(1, "rgba(" + TINT[wi] + ",0)");
      ctx.fillStyle = wash;
      ctx.fillRect(cx - rr, cy - rr, rr * 2, rr * 2);
      // a doodle in the emptiest spot next to the group
      var minY = Math.min.apply(null, g.map(function (p) { return p.y; }));
      var maxY = Math.max.apply(null, g.map(function (p) { return p.y; }));
      var dy = portrait ? (minY + maxY) / 2 : (minY > 90 ? minY - 56 : maxY + 50);
      var dx = portrait ? (wi % 2 ? w - 34 : 34) : cx;
      if (!portrait || w > 300) doodle(ctx, wi, dx, dy, portrait ? 0.7 : 1);
    });

    // the compass rose sits in an empty corner
    if (portrait) compass(ctx, w - 34, 34, 22);
    else compass(ctx, 62, 62, 40);

    // the path of light, node to node and on to the Moon
    var pts = info.points.concat([info.moon]);
    ctx.lineCap = "round";
    for (var i = 0; i < pts.length - 1; i++) {
      var a0 = pts[i], b0 = pts[i + 1];
      var lit = info.cleared[i];
      var bend = (i % 2 ? 0.12 : -0.12);
      ctx.beginPath();
      inkLine(ctx, a0, b0, rng, bend);
      if (lit) {
        ctx.setLineDash([]);
        ctx.strokeStyle = "rgba(255,200,110,.22)";
        ctx.lineWidth = 7;
        ctx.stroke();
        ctx.strokeStyle = "rgba(255,222,150,.85)";
        ctx.lineWidth = 2;
        ctx.stroke();
      } else {
        ctx.setLineDash([2, 7]);
        ctx.strokeStyle = "rgba(220,228,255,.4)";
        ctx.lineWidth = 2;
        ctx.stroke();
      }
    }
    ctx.setLineDash([]);

    // a few constellations, inked in silver, that relight as the worlds wake
    var lightK = info.light;
    var cons = portrait ? [[0.12, 0.05], [0.3, 0.09], [0.42, 0.04], [0.58, 0.08]] : [[0.3, 0.07], [0.37, 0.15], [0.47, 0.1], [0.55, 0.17], [0.6, 0.08]];
    ctx.strokeStyle = "rgba(220,228,255," + (0.12 + lightK * 0.3).toFixed(2) + ")";
    ctx.lineWidth = 1;
    ctx.beginPath();
    cons.forEach(function (c, k) {
      var x = c[0] * w, y = c[1] * hgt;
      if (k) ctx.lineTo(x, y); else ctx.moveTo(x, y);
    });
    ctx.stroke();
    cons.forEach(function (c) {
      ctx.fillStyle = "rgba(240,244,255," + (0.35 + lightK * 0.5).toFixed(2) + ")";
      star4(ctx, c[0] * w, c[1] * hgt, 4);
    });

    // the Moon at the end of the road
    var mr = info.moon.r;
    LM.drawMoon(ctx, info.moon.x, info.moon.y, mr, 0.25 + 0.75 * lightK);
    ctx.restore();

    // an inked frame with corner ticks
    ctx.strokeStyle = "rgba(230,235,255,.22)";
    ctx.lineWidth = 1;
    LM.draw.roundRect(ctx, 6.5, 6.5, w - 13, hgt - 13, 15);
    ctx.stroke();
    ctx.strokeStyle = "rgba(255,217,138,.25)";
    LM.draw.roundRect(ctx, 10.5, 10.5, w - 21, hgt - 21, 12);
    ctx.stroke();
    return true;
  }

  // Wire a chart to its container: draw once laid out, then on resize.
  function attach(root, canvas, collect) {
    function redraw() {
      if (!root.isConnected) { window.removeEventListener("resize", redraw); return; }
      var nodes = Array.prototype.slice.call(root.querySelectorAll(".node"));
      var data = collect();
      var groups = [[], [], [], []];
      data.points = nodes.map(function (n) {
        var p = offsetIn(n.querySelector(".dot") || n, root);
        groups[+n.getAttribute("data-world")].push(p);
        return p;
      });
      data.groups = groups;
      var mEl = root.querySelector(".chart-moon");
      var mp = offsetIn(mEl, root);
      data.moon = { x: mp.x, y: mp.y, r: Math.max(26, Math.min(mEl.offsetWidth, mEl.offsetHeight) * 0.42) };
      draw(root, canvas, data);
    }
    window.addEventListener("resize", redraw);
    var tries = 0;
    (function first() {
      if (root.isConnected && root.clientWidth) { redraw(); setTimeout(redraw, 420); }
      else if (tries++ < 60) requestAnimationFrame(first);
    })();
  }

  LM.chart = { attach: attach, draw: draw };
})(window.LUMEN);
