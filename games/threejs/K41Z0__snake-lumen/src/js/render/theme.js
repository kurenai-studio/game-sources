window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // One accent per world, all drawn from the same night palette: deep night
  // blue, warm star gold and soft moonlight silver. The boards and backdrops
  // keep their own detailed palettes (boardView.js, backgrounds.js).
  LM.themes = [
    { id: "garden", accent: "#cfe6a8", glow: "#ffd98a" },
    { id: "city", accent: "#ffcf8a", glow: "#ffc878" },
    { id: "sky", accent: "#cdd8ff", glow: "#e4ebff" },
    { id: "moon", accent: "#eef1ff", glow: "#ffe6a8" }
  ];

  LM.colors = {
    bg: "#070912", text: "#eef0fa", muted: "#9aa0b8", gold: "#f2b84a", goldLight: "#ffd98a", moon: "#e6ebff",
    bronze: ["#e8a87c", "#b5651d", "#7a3e0e"], silver: ["#f1f3f5", "#adb5bd", "#5c636a"],
    gold3: ["#fff3bf", "#f2c65a", "#a8740f"]
  };

  // Small colour helpers shared by the views.
  LM.color = {
    hex: function (h) {
      h = h.replace("#", "");
      if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
      var n = parseInt(h, 16);
      return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
    },
    mix: function (a, b, t) {
      var x = LM.color.hex(a), y = LM.color.hex(b);
      return "rgb(" + Math.round(x[0] + (y[0] - x[0]) * t) + "," + Math.round(x[1] + (y[1] - x[1]) * t) + "," +
        Math.round(x[2] + (y[2] - x[2]) * t) + ")";
    },
    alpha: function (h, a) {
      var c = LM.color.hex(h);
      return "rgba(" + c[0] + "," + c[1] + "," + c[2] + "," + a + ")";
    },
    shade: function (h, amt) {
      return amt >= 0 ? LM.color.mix(h, "#ffffff", amt) : LM.color.mix(h, "#000000", -amt);
    }
  };

  LM.draw = {
    roundRect: function (ctx, x, y, w, h, r) {
      r = Math.min(r, w / 2, h / 2);
      ctx.beginPath();
      ctx.moveTo(x + r, y);
      ctx.arcTo(x + w, y, x + w, y + h, r);
      ctx.arcTo(x + w, y + h, x, y + h, r);
      ctx.arcTo(x, y + h, x, y, r);
      ctx.arcTo(x, y, x + w, y, r);
      ctx.closePath();
    },
    // Regular polygon / star path centred on (x, y).
    poly: function (ctx, x, y, r, n, rot, inner) {
      ctx.beginPath();
      var steps = inner ? n * 2 : n;
      for (var i = 0; i < steps; i++) {
        var rr = inner && i % 2 ? r * inner : r;
        var a = rot + (i / steps) * Math.PI * 2;
        if (i === 0) ctx.moveTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
        else ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
      }
      ctx.closePath();
    },
    font: function (weight, size) {
      return weight + " " + size + "px -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";
    }
  };
})(window.LUMEN);
