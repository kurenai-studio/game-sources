window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;

  // A pooled particle system: sparks, soft blooms, falling star glints and floating text.
  function Particles() {
    this.list = [];
    this.max = 600;
  }

  Particles.prototype.add = function (p) {
    if (this.list.length >= this.max) this.list.shift();
    p.age = 0;
    this.list.push(p);
    return p;
  };

  Particles.prototype.burst = function (x, y, color, count, speed, opts) {
    opts = opts || {};
    for (var i = 0; i < count; i++) {
      var a = Math.random() * TAU, v = speed * (0.3 + Math.random() * 0.9);
      this.add({ kind: opts.kind || "spark", x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v,
        life: (opts.life || 0.6) * (0.6 + Math.random() * 0.6), size: (opts.size || 3) * (0.6 + Math.random() * 0.8),
        color: Array.isArray(color) ? color[i % color.length] : color, gravity: opts.gravity || 0,
        drag: opts.drag === undefined ? 2.5 : opts.drag, spin: (Math.random() - 0.5) * 12, rot: Math.random() * TAU });
    }
  };

  Particles.prototype.ring = function (x, y, color, radius, life) {
    this.add({ kind: "ring", x: x, y: y, vx: 0, vy: 0, life: life || 0.45, size: radius, color: color, drag: 0, gravity: 0 });
  };

  Particles.prototype.text = function (x, y, text, color, size) {
    this.add({ kind: "text", x: x, y: y, vx: 0, vy: -40, life: 0.9, size: size || 16, color: color, text: text,
      drag: 1.5, gravity: 0 });
  };

  Particles.prototype.update = function (dt) {
    var out = [];
    for (var i = 0; i < this.list.length; i++) {
      var p = this.list[i];
      p.age += dt;
      if (p.age >= p.life) continue;
      var k = Math.max(0, 1 - p.drag * dt);
      p.vx *= k;
      p.vy = p.vy * k + p.gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.rot !== undefined) p.rot += p.spin * dt;
      out.push(p);
    }
    this.list = out;
  };

  Particles.prototype.draw = function (ctx) {
    for (var i = 0; i < this.list.length; i++) {
      var p = this.list[i], k = p.age / p.life, a = 1 - k;
      ctx.globalAlpha = a;
      if (p.kind === "spark") {
        ctx.globalCompositeOperation = "lighter";
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size * (1 - k * 0.6), 0, TAU);
        ctx.fill();
        ctx.globalCompositeOperation = "source-over";
      } else if (p.kind === "confetti") {
        // little four-point stars that twinkle as they fall
        ctx.save();
        ctx.globalCompositeOperation = "lighter";
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rot * 0.2);
        var s = p.size * (0.7 + 0.3 * Math.sin(p.age * 14 + p.rot));
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.moveTo(0, -s * 1.6); ctx.lineTo(s * 0.35, 0); ctx.lineTo(0, s * 1.6); ctx.lineTo(-s * 0.35, 0); ctx.closePath();
        ctx.moveTo(-s * 1.6, 0); ctx.lineTo(0, s * 0.35); ctx.lineTo(s * 1.6, 0); ctx.lineTo(0, -s * 0.35); ctx.closePath();
        ctx.fill();
        ctx.restore();
      } else if (p.kind === "ring") {
        // a soft bloom of light that swells and fades (no outline)
        var rr = p.size * (0.4 + k * 0.9);
        var g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, rr);
        g.addColorStop(0, "rgba(255,255,255,0)");
        g.addColorStop(0.55, p.color);
        g.addColorStop(1, "rgba(255,255,255,0)");
        ctx.globalCompositeOperation = "lighter";
        ctx.globalAlpha = a * 0.35;
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(p.x, p.y, rr, 0, TAU);
        ctx.fill();
        ctx.globalCompositeOperation = "source-over";
      } else if (p.kind === "text") {
        ctx.font = LM.draw.font("800", p.size * (1 + (k < 0.15 ? (0.15 - k) * 3 : 0)));
        ctx.textAlign = "center";
        ctx.lineWidth = 3;
        ctx.strokeStyle = "rgba(0,0,0,.6)";
        ctx.strokeText(p.text, p.x, p.y);
        ctx.fillStyle = p.color;
        ctx.fillText(p.text, p.x, p.y);
        ctx.textAlign = "start";
      } else if (p.kind === "smoke") {
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size * (1 + k * 2), 0, TAU);
        ctx.fill();
      }
    }
    ctx.globalAlpha = 1;
  };

  Particles.prototype.clear = function () {
    this.list = [];
  };

  LM.Particles = Particles;
})(window.LUMEN);
