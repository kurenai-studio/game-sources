window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;
  function clamp01(v) { return v < 0 ? 0 : v > 1 ? 1 : v; }
  function ease(v) { v = clamp01(v); return v * v * (3 - 2 * v); }

  // The story beats: a few short lines over a small animated scene.
  var SCENES = {
    intro: { world: 0, music: "title", lines: [
      "The world has fallen into darkness.",
      "The stars fell, one by one, and the Moon went quiet.",
      "But one small light remains.",
      "Gather the fallen stars. Bring the light back."
    ] },
    w1: { world: 1, music: "city", lines: [
      "The garden breathes again.",
      "Beyond the hedges, a city sleeps with its windows dark.",
      "Wake it gently."
    ] },
    w2: { world: 2, music: "sky", lines: [
      "Behind you, the city glows.",
      "Above, the sky is hollow. Its stars lie scattered and still.",
      "Climb, and kindle them."
    ] },
    w3: { world: 3, music: "moon", lines: [
      "The sky remembers its stars.",
      "Only one light is missing now.",
      "Follow the silver path to the Moon."
    ] },
    finale: { world: 3, music: "moon", lines: [
      "The last star finds its place.",
      "The Moon opens its eyes, and remembers how to shine.",
      "Light returns to every world.",
      "Thank you for playing Snake: Lumen."
    ] }
  };
  var LINE_START = 0.6, LINE_EVERY = 2.4, TAIL = 3;
  function lines(kind) {
    var l = LM.t ? LM.t("story." + kind, null, SCENES[kind].lines) : SCENES[kind].lines;
    return Array.isArray(l) ? l : SCENES[kind].lines;
  }
  function duration(kind) { return LINE_START + lines(kind).length * LINE_EVERY + TAIL; }

  // Draws one frame of a story scene behind the story text.
  function StoryView() {
    this.snake = new LM.SnakeView();
    this.rng = new LM.Rng(4242);
    this.fallers = [];
    for (var i = 0; i < 16; i++) {
      this.fallers.push({ at: 0.2 + i * 0.32 + this.rng.next() * 0.2, x0: 0.1 + this.rng.next() * 0.9, x1: 0.08 + this.rng.next() * 0.84,
        y1: 0.74 + this.rng.next() * 0.2, s: 0.6 + this.rng.next() * 0.6, ph: this.rng.next() * TAU });
    }
  }

  function serpentPts(cx, cy, cell, n, t, amp, heading) {
    var pts = [];
    var dx = Math.cos(heading), dy = Math.sin(heading);
    for (var k = 0; k < n; k++) {
      var along = -k * cell * 0.62;
      var side = Math.sin(k * 0.6 - t * 3) * amp * cell * Math.min(1, k / 3);
      pts.push({ x: cx + dx * along - dy * side, y: cy + dy * along + dx * side });
    }
    return pts;
  }

  StoryView.prototype.draw = function (ctx, scene, kind, el, t, skin) {
    var w = scene.w, h = scene.h;
    var def = SCENES[kind] || SCENES.intro;
    var cell = Math.max(16, Math.min(w, h) * 0.045);
    var light = 0, moon = 0;
    if (kind === "intro") light = 0.12 * ease((el - 9) / 4);
    else if (kind === "finale") { light = 0.55 + 0.45 * ease((el - 1) / 6); moon = 0.6 * ease((el - 2) / 6); }
    else light = 0.08 + 0.42 * ease((el - 1) / 7);
    scene.backdrop.draw(ctx, def.world, t, 0, 0, { light: light, moon: moon, story: true });

    // a veil of night that lifts a little as the scene goes on
    ctx.fillStyle = "rgba(2,3,10," + (kind === "finale" ? 0.25 * (1 - ease(el / 4)) : 0.35).toFixed(3) + ")";
    ctx.fillRect(0, 0, w, h);

    var sx = w * 0.5, sy = h * 0.74, n = 9, heading = -Math.PI / 2 + 0.2 * Math.sin(t * 0.7), alpha = 1;
    if (kind === "intro") {
      // the stars fall and land as small glints on the ground
      for (var i = 0; i < this.fallers.length; i++) {
        var f = this.fallers[i], k = (el - f.at) / 1.1;
        if (k < 0) continue;
        var x1 = f.x1 * w, y1 = f.y1 * h;
        if (k < 1) {
          var e = k * k;
          var x = f.x0 * w + (x1 - f.x0 * w) * e, y = -20 + (y1 + 20) * e;
          var tx = x - (x1 - f.x0 * w) * 0.12, ty = y - (y1 + 20) * 0.12;
          var lg = ctx.createLinearGradient(tx, ty, x, y);
          lg.addColorStop(0, "rgba(255,230,170,0)");
          lg.addColorStop(1, "rgba(255,230,170,.8)");
          ctx.strokeStyle = lg;
          ctx.lineWidth = 2;
          ctx.beginPath(); ctx.moveTo(tx, ty); ctx.lineTo(x, y); ctx.stroke();
          LM.itemsView.star(ctx, x, y, cell * 0.8 * f.s, t, { phase: f.ph, noHalo: true });
        } else {
          // dimming as the world goes dark, until the serpent wakes
          var dim = 0.35 + 0.65 * Math.max(1 - ease((el - f.at - 1.1) / 2), ease((el - 9) / 3));
          ctx.globalAlpha = dim;
          LM.itemsView.star(ctx, x1, y1, cell * 0.65 * f.s, t, { phase: f.ph });
          ctx.globalAlpha = 1;
        }
      }
      alpha = ease((el - 6.2) / 1.5);
      n = 6;
      sx = w * 0.5 + Math.sin(t * 0.5) * cell;
      heading = -Math.PI / 2 + 0.5 * Math.sin(t * 0.8);
    } else if (kind === "finale") {
      // rays from the waking Moon
      var mx = w * 0.5, my = h * 0.38, rk = ease((el - 3) / 4);
      if (rk > 0) {
        ctx.save();
        ctx.globalCompositeOperation = "lighter";
        ctx.translate(mx, my);
        ctx.rotate(t * 0.05);
        for (var r = 0; r < 18; r++) {
          ctx.rotate(TAU / 18);
          var len = Math.max(w, h) * (0.6 + 0.2 * Math.sin(t + r));
          var rg = ctx.createLinearGradient(0, 0, 0, -len);
          rg.addColorStop(0, "rgba(230,235,255," + (0.07 * rk).toFixed(3) + ")");
          rg.addColorStop(1, "rgba(230,235,255,0)");
          ctx.fillStyle = rg;
          ctx.beginPath(); ctx.moveTo(-6, 0); ctx.lineTo(0, -len); ctx.lineTo(6, 0); ctx.fill();
        }
        ctx.restore();
      }
      // the serpent curls over the top of the Moon, carrying the last light
      var mr = Math.min(w, h) * 0.2 * 1.32, arc = [];
      var spin = (1 - ease(el / 5)) * 1.1;
      for (var q = 0; q < 24; q++) {
        var ang = -Math.PI * 0.5 - 1.27 - spin + q * 0.11;
        arc.push({ x: mx + Math.cos(ang) * mr + Math.sin(q * 0.9 - t * 3) * cell * 0.12, y: my + Math.sin(ang) * mr });
      }
      arc.reverse();
      var fa = ease(el / 1.5);
      ctx.globalAlpha = fa;
      ctx.globalCompositeOperation = "lighter";
      ctx.drawImage(scene.backdrop.sprites.warm, arc[0].x - cell * 4, arc[0].y - cell * 4, cell * 8, cell * 8);
      // the whole body glows warm against the bright Moon
      for (var gq = 0; gq < arc.length; gq += 2) {
        ctx.globalAlpha = fa * 0.4 * (1 - gq / arc.length * 0.5);
        ctx.drawImage(scene.backdrop.sprites.warm, arc[gq].x - cell * 1.6, arc[gq].y - cell * 1.6, cell * 3.2, cell * 3.2);
      }
      ctx.globalAlpha = fa;
      ctx.globalCompositeOperation = "source-over";
      var hd = arc[0], nk = arc[1];
      this.snake.draw(ctx, { pts: arc, cell: cell, skin: skin, t: t, dt: 0.016, dir: { x: hd.x - nk.x, y: hd.y - nk.y }, look: { x: mx, y: my }, tickMs: 120 });
      ctx.globalAlpha = 1;
      alpha = 0;
    } else {
      // the serpent arrives from the left
      var arrive = ease(el / 4);
      sx = w * (0.12 + 0.38 * arrive);
      heading = -0.25 * Math.sin(t * 0.8);
      n = 10 + Number(kind.charAt(1)) * 4;
    }
    if (alpha > 0.01) {
      var pts = serpentPts(sx, sy, cell, n, t, 0.6, heading);
      var warm = scene.backdrop.sprites.warm;
      ctx.globalCompositeOperation = "lighter";
      ctx.globalAlpha = alpha * 0.8;
      var gs = cell * (4 + n * 0.12);
      ctx.drawImage(warm, sx - gs, sy - gs, gs * 2, gs * 2);
      ctx.globalCompositeOperation = "source-over";
      ctx.globalAlpha = alpha;
      this.snake.draw(ctx, { pts: pts, cell: cell, skin: skin, t: t, dt: 0.016, dir: { x: Math.cos(heading), y: Math.sin(heading) },
        look: null, tickMs: 120 });
      ctx.globalAlpha = 1;
    }
  };

  LM.story = { scenes: SCENES, lines: lines, duration: duration, lineStart: LINE_START, lineEvery: LINE_EVERY, StoryView: StoryView };
})(window.LUMEN);
