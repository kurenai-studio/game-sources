window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var TAU = Math.PI * 2;

  // Achievement glyphs in unit space (about -1..1). Each is drawn twice by
  // the medal, light then dark, so it reads as engraved metal.
  function circle(c, x, y, r) { c.beginPath(); c.arc(x, y, r, 0, TAU); }
  function line(c, pts) { c.beginPath(); c.moveTo(pts[0], pts[1]); for (var i = 2; i < pts.length; i += 2) c.lineTo(pts[i], pts[i + 1]); }

  function star5(c, x, y, r) { LM.draw.poly(c, x, y, r, 5, -Math.PI / 2, 0.45); c.fill(); }

  var G = {
    star: function (c) { star5(c, 0, 0.05, 0.9); },
    handful: function (c) { c.beginPath(); c.moveTo(-0.85, 0.15); c.quadraticCurveTo(-0.8, 0.85, 0, 0.85); c.quadraticCurveTo(0.8, 0.85, 0.85, 0.15); c.closePath(); c.fill(); star5(c, -0.38, -0.15, 0.32); star5(c, 0.3, -0.35, 0.36); star5(c, 0.02, -0.72, 0.24); },
    constellation: function (c) { c.lineWidth = 0.08; line(c, [-0.75, 0.55, -0.3, -0.05, 0.25, 0.25, 0.7, -0.55]); c.stroke(); line(c, [-0.3, -0.05, -0.15, -0.7]); c.stroke(); star5(c, -0.75, 0.55, 0.22); star5(c, -0.3, -0.05, 0.26); star5(c, 0.25, 0.25, 0.22); star5(c, 0.7, -0.55, 0.3); star5(c, -0.15, -0.7, 0.18); },
    flower: function (c) { for (var i = 0; i < 6; i++) { var a = i * TAU / 6; c.beginPath(); c.ellipse(Math.cos(a) * 0.45, Math.sin(a) * 0.45 - 0.05, 0.32, 0.22, a, 0, TAU); c.fill(); } },
    city: function (c) { line(c, [-0.9, 0.8, -0.9, 0.0, -0.55, -0.4, -0.2, 0.0, -0.2, 0.8]); c.closePath(); c.fill(); line(c, [-0.25, 0.8, -0.25, -0.3, 0.2, -0.85, 0.65, -0.3, 0.65, 0.8]); c.closePath(); c.fill(); c.fillRect(0.3, -0.85, 0.16, 0.4); line(c, [0.6, 0.8, 0.6, 0.1, 0.78, -0.12, 0.95, 0.1, 0.95, 0.8]); c.closePath(); c.fill(); },
    planet: function (c) { c.beginPath(); c.arc(-0.45, 0.35, 0.35, Math.PI * 0.5, Math.PI * 1.5); c.arc(0, 0.05, 0.45, Math.PI * 1.1, Math.PI * 1.95); c.arc(0.5, 0.35, 0.35, Math.PI * 1.5, Math.PI * 0.5); c.closePath(); c.fill(); star5(c, -0.45, -0.6, 0.2); star5(c, 0.15, -0.75, 0.15); star5(c, 0.65, -0.45, 0.22); },
    moon: function (c) { c.save(); circle(c, 0, 0, 0.8); c.clip(); c.beginPath(); c.rect(-1, -1, 2, 2); c.arc(0.42, -0.3, 0.66, 0, TAU); c.fill("evenodd"); c.restore(); star5(c, 0.55, 0.55, 0.22); },
    crescent: function (c) { c.save(); circle(c, 0, 0, 0.82); c.clip(); c.beginPath(); c.rect(-1, -1, 2, 2); c.arc(0.38, -0.12, 0.7, 0, TAU); c.fill("evenodd"); c.restore(); },
    fullmoon: function (c) { circle(c, 0, 0, 0.82); c.fill(); },
    calendar: function (c) { LM.draw.roundRect(c, -0.75, -0.6, 1.5, 1.4, 0.15); c.fill(); c.fillRect(-0.5, -0.85, 0.16, 0.4); c.fillRect(0.34, -0.85, 0.16, 0.4); },
    brush: function (c) { c.save(); c.rotate(-0.7); c.fillRect(-0.12, -0.9, 0.24, 1.0); c.beginPath(); c.ellipse(0, 0.4, 0.3, 0.5, 0, 0, TAU); c.fill(); c.restore(); },
    prism: function (c) { line(c, [0, -0.85, 0.85, 0.7, -0.85, 0.7]); c.closePath(); c.fill(); },
    clock: function (c) { c.lineWidth = 0.18; circle(c, 0, 0, 0.75); c.stroke(); line(c, [0, -0.45, 0, 0, 0.35, 0.2]); c.stroke(); },
    flame: function (c) { c.beginPath(); c.moveTo(0, -0.95); c.bezierCurveTo(0.9, -0.1, 0.7, 0.85, 0, 0.85); c.bezierCurveTo(-0.7, 0.85, -0.8, 0, -0.25, -0.35); c.bezierCurveTo(-0.2, 0, 0.1, 0, 0, -0.95); c.fill(); },
    burst: function (c) { LM.draw.poly(c, 0, 0, 0.95, 12, -Math.PI / 2, 0.45); c.fill(); },
    ribbon: function (c) { c.lineWidth = 0.3; c.lineCap = "round"; c.beginPath(); c.moveTo(-0.85, 0.3); c.bezierCurveTo(-0.5, -0.6, -0.1, 0.8, 0.25, -0.1); c.bezierCurveTo(0.45, -0.6, 0.7, -0.5, 0.85, -0.4); c.stroke(); },
    snake: function (c) { c.lineWidth = 0.28; c.lineCap = "round"; c.beginPath(); c.moveTo(-0.8, 0.6); c.bezierCurveTo(-0.2, 0.9, -0.6, -0.1, 0, -0.1); c.bezierCurveTo(0.5, -0.1, 0.2, -0.7, 0.7, -0.6); c.stroke(); circle(c, 0.72, -0.62, 0.22); c.fill(); },
    comet: function (c) { star5(c, 0.45, -0.45, 0.42); c.lineWidth = 0.16; c.lineCap = "round"; line(c, [0.1, -0.1, -0.85, 0.85]); c.stroke(); line(c, [0.2, -0.45, -0.55, 0.3]); c.stroke(); line(c, [0.45, -0.1, -0.3, 0.65]); c.stroke(); },
    gem: function (c) { line(c, [-0.8, -0.25, -0.45, -0.7, 0.45, -0.7, 0.8, -0.25, 0, 0.85]); c.closePath(); c.fill(); },
    wish: function (c) { star5(c, 0, -0.1, 0.62); star5(c, -0.62, 0.62, 0.2); star5(c, 0.62, 0.62, 0.2); star5(c, 0, 0.82, 0.15); },
    lantern: function (c) { c.fillRect(-0.25, -0.95, 0.5, 0.15); LM.draw.roundRect(c, -0.5, -0.75, 1, 1.35, 0.25); c.fill(); c.fillRect(-0.35, 0.6, 0.7, 0.22); },
    trophy: function (c) { c.beginPath(); c.moveTo(-0.55, -0.75); c.lineTo(0.55, -0.75); c.quadraticCurveTo(0.55, 0.2, 0, 0.25); c.quadraticCurveTo(-0.55, 0.2, -0.55, -0.75); c.fill(); c.fillRect(-0.1, 0.2, 0.2, 0.4); c.fillRect(-0.4, 0.55, 0.8, 0.22); c.lineWidth = 0.13; c.beginPath(); c.arc(-0.55, -0.4, 0.25, Math.PI * 0.5, Math.PI * 1.5); c.arc(0.55, -0.4, 0.25, -Math.PI * 0.5, Math.PI * 0.5); c.stroke(); },
    orbs: function (c) { circle(c, -0.42, -0.42, 0.32); c.fill(); circle(c, 0.42, -0.42, 0.32); c.fill(); circle(c, -0.42, 0.42, 0.32); c.fill(); circle(c, 0.42, 0.42, 0.32); c.fill(); },
    ring: function (c) { c.lineWidth = 0.26; circle(c, 0, 0, 0.62); c.stroke(); circle(c, 0.62, 0, 0.2); c.fill(); },
    candle: function (c) { c.fillRect(-0.28, -0.2, 0.56, 1.05); c.lineWidth = 0.08; line(c, [0, -0.2, 0, -0.45]); c.stroke(); c.lineWidth = 0.06; c.beginPath(); c.moveTo(-0.25, -0.75); c.quadraticCurveTo(0, -0.95, 0.1, -0.6); c.quadraticCurveTo(0.3, -0.8, 0.45, -0.65); c.stroke(); },
    owl: function (c) { c.beginPath(); c.moveTo(-0.6, -0.85); c.lineTo(-0.35, -0.55); c.lineTo(0.35, -0.55); c.lineTo(0.6, -0.85); c.lineTo(0.7, 0.3); c.quadraticCurveTo(0.6, 0.9, 0, 0.9); c.quadraticCurveTo(-0.6, 0.9, -0.7, 0.3); c.closePath(); c.fill(); },
    gamepad: function (c) { LM.draw.roundRect(c, -0.95, -0.45, 1.9, 0.95, 0.4); c.fill(); },
    ghost: function (c) { c.beginPath(); c.arc(0, -0.15, 0.65, Math.PI, 0); c.lineTo(0.65, 0.8); c.lineTo(0.33, 0.55); c.lineTo(0, 0.8); c.lineTo(-0.33, 0.55); c.lineTo(-0.65, 0.8); c.closePath(); c.fill(); },
    magnet: function (c) { star5(c, 0, -0.35, 0.5); c.lineWidth = 0.1; for (var i = 0; i < 3; i++) { c.beginPath(); c.arc(0, -0.35, 0.65 + i * 0.22, Math.PI * 0.25, Math.PI * 0.75); c.stroke(); } },
    pause: function (c) { LM.draw.roundRect(c, -0.6, -0.75, 0.42, 1.5, 0.1); c.fill(); LM.draw.roundRect(c, 0.18, -0.75, 0.42, 1.5, 0.1); c.fill(); },
    lock: function (c) { c.lineWidth = 0.2; c.beginPath(); c.arc(0, -0.25, 0.42, Math.PI, 0); c.stroke(); LM.draw.roundRect(c, -0.65, -0.25, 1.3, 1.05, 0.15); c.fill(); },
    lanternlit: function (c) { c.lineWidth = 0.09; c.beginPath(); c.arc(0, -0.72, 0.18, Math.PI, 0); c.stroke(); LM.draw.roundRect(c, -0.42, -0.6, 0.84, 1.1, 0.22); c.fill(); c.fillRect(-0.3, 0.5, 0.6, 0.18);
      for (var i = 0; i < 8; i++) { var a = i * TAU / 8; line(c, [Math.cos(a) * 0.62, Math.sin(a) * 0.62 - 0.05, Math.cos(a) * 0.9, Math.sin(a) * 0.9 - 0.05]); c.stroke(); } },
    eye: function (c) { c.beginPath(); c.moveTo(-0.95, 0); c.quadraticCurveTo(0, -0.85, 0.95, 0); c.quadraticCurveTo(0, 0.85, -0.95, 0); c.closePath(); c.fill(); },
    question: function (c) { c.font = LM.draw.font("900", 1.7); c.textAlign = "center"; c.textBaseline = "middle"; c.fillText("?", 0, 0.08); }
  };

  // Engraved details cut back out of some glyphs (eyes, holes, windows).
  var CUT = {
    ghost: function (c) { circle(c, -0.22, -0.2, 0.12); c.fill(); circle(c, 0.22, -0.2, 0.12); c.fill(); },
    owl: function (c) { circle(c, -0.27, -0.15, 0.2); c.fill(); circle(c, 0.27, -0.15, 0.2); c.fill(); },
    flower: function (c) { circle(c, 0, -0.05, 0.22); c.fill(); },
    gamepad: function (c) { c.fillRect(-0.65, -0.07, 0.4, 0.14); c.fillRect(-0.52, -0.2, 0.14, 0.4); circle(c, 0.42, -0.1, 0.1); c.fill(); circle(c, 0.62, 0.1, 0.1); c.fill(); },
    calendar: function (c) { for (var i = 0; i < 6; i++) c.fillRect(-0.5 + (i % 3) * 0.38, -0.15 + Math.floor(i / 3) * 0.4, 0.22, 0.22); },
    city: function (c) { c.fillRect(0.14, -0.2, 0.18, 0.2); c.fillRect(-0.65, 0.15, 0.16, 0.18); c.fillRect(0.14, 0.3, 0.18, 0.5); },
    lantern: function (c) { circle(c, 0, -0.05, 0.22); c.fill(); },
    fullmoon: function (c) { circle(c, -0.3, -0.2, 0.16); c.fill(); circle(c, 0.25, 0.3, 0.12); c.fill(); circle(c, 0.3, -0.35, 0.08); c.fill(); },
    prism: function (c) { c.lineWidth = 0.08; line(c, [0, -0.85, 0, 0.7]); c.stroke(); },
    gem: function (c) { c.lineWidth = 0.08; line(c, [-0.8, -0.25, 0.8, -0.25]); c.stroke(); line(c, [-0.2, -0.7, -0.3, -0.25, 0, 0.85, 0.3, -0.25, 0.2, -0.7]); c.stroke(); },
    lock: function (c) { circle(c, 0, 0.2, 0.14); c.fill(); },
    lanternlit: function (c) { c.beginPath(); c.moveTo(0, -0.4); c.quadraticCurveTo(0.22, -0.05, 0, 0.25); c.quadraticCurveTo(-0.22, -0.05, 0, -0.4); c.fill(); },
    eye: function (c) { c.lineWidth = 0.13; circle(c, 0, 0, 0.36); c.stroke(); }
  };

  // Medals are little star charms: a night-blue enamel face inside a metal
  // rim. Amber, moon silver and star gold by rarity; the rim shape tells the
  // category (a round coin, a coin with rays, a diamond for secrets).
  var RARITY = {
    bronze: ["#ffd9a8", "#d68f4e", "#7c4519"],
    silver: ["#ffffff", "#c9d1ea", "#636c90"],
    gold: ["#fff6cc", "#f2c65a", "#a8740f"]
  };
  var PEWTER = ["#7d86a3", "#4a5272", "#262b42"];

  var cache = {};

  function medal(ctx, a, size, state) {
    var cx = size / 2, cy = size / 2, R = size * 0.44;
    var on = state === "unlocked";
    var metal = on ? RARITY[a.rarity] : PEWTER;
    ctx.save();
    ctx.clearRect(0, 0, size, size);
    function shape(r) {
      if (a.cat === "secret") LM.draw.poly(ctx, cx, cy, r * 1.08, 4, -Math.PI / 2);
      else circle(ctx, cx, cy, r);
    }
    function metalFill(x0, y0, x1, y1) {
      var g = ctx.createLinearGradient(x0, y0, x1, y1);
      g.addColorStop(0, metal[0]); g.addColorStop(0.45, metal[1]); g.addColorStop(1, metal[2]);
      return g;
    }
    // soft glow of the charm
    if (on) {
      var halo = ctx.createRadialGradient(cx, cy, R * 0.6, cx, cy, size * 0.5);
      halo.addColorStop(0, LM.color.alpha(metal[1], 0.45));
      halo.addColorStop(1, LM.color.alpha(metal[1], 0));
      ctx.fillStyle = halo;
      ctx.fillRect(0, 0, size, size);
    }
    // rays behind the coin for mastery
    if (a.cat === "mastery") {
      ctx.fillStyle = metalFill(0, 0, size, size);
      LM.draw.poly(ctx, cx, cy, R * 1.12, 8, -Math.PI / 2, 0.72);
      ctx.fill();
    }
    // rim
    ctx.fillStyle = metalFill(0, 0, size, size);
    shape(a.cat === "mastery" ? R * 0.9 : R);
    ctx.fill();
    // night enamel
    var inner = a.cat === "mastery" ? R * 0.74 : R * 0.82;
    var en = ctx.createRadialGradient(cx - inner * 0.3, cy - inner * 0.35, 0, cx, cy, inner);
    en.addColorStop(0, on ? "#2c3866" : "#20253b");
    en.addColorStop(1, on ? "#0d1230" : "#0c0f1d");
    ctx.fillStyle = en;
    shape(inner);
    ctx.fill();
    // a few enamel stars
    ctx.fillStyle = on ? "rgba(230,235,255,.55)" : "rgba(160,170,200,.2)";
    [[-0.55, -0.35, 0.035], [0.5, -0.5, 0.03], [0.58, 0.42, 0.025], [-0.42, 0.55, 0.03]].forEach(function (st) {
      circle(ctx, cx + st[0] * inner, cy + st[1] * inner, Math.max(0.6, st[2] * size * 0.5)); ctx.fill();
    });
    // a thin bright edge on the rim
    ctx.strokeStyle = on ? "rgba(255,255,255,.45)" : "rgba(200,210,240,.12)";
    ctx.lineWidth = Math.max(0.6, size * 0.012);
    shape(inner);
    ctx.stroke();
    // glyph, inlaid in the metal of the rim
    var glyph = state === "hidden" ? "question" : a.icon;
    ctx.translate(cx, cy);
    var gs = inner * 0.6;
    ctx.scale(gs, gs);
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    if (on) { ctx.shadowColor = LM.color.alpha(metal[1], 0.9); ctx.shadowBlur = size * 0.08; }
    var gg = ctx.createLinearGradient(-1, -1, 1, 1);
    gg.addColorStop(0, on ? metal[0] : "#8a92b0");
    gg.addColorStop(1, on ? metal[1] : "#555d7c");
    ctx.fillStyle = gg;
    ctx.strokeStyle = gg;
    (G[glyph] || G.star)(ctx);
    ctx.shadowBlur = 0;
    if (CUT[glyph]) {
      ctx.fillStyle = on ? "#141a3a" : "#151a2c";
      ctx.strokeStyle = ctx.fillStyle;
      CUT[glyph](ctx);
    }
    ctx.restore();
    if (state === "locked") {
      ctx.save();
      ctx.translate(size * 0.8, size * 0.8);
      ctx.scale(size * 0.1, size * 0.1);
      ctx.fillStyle = "#9aa3c2";
      ctx.strokeStyle = "#9aa3c2";
      G.lock(ctx);
      ctx.fillStyle = "#151a2c";
      CUT.lock(ctx);
      ctx.restore();
    }
  }

  function achievementIcon(a, size, state) {
    var key = a.id + "|" + size + "|" + state;
    if (cache[key]) return cache[key];
    var c = document.createElement("canvas");
    var dpr = Math.min(2, window.devicePixelRatio || 1);
    c.width = c.height = Math.round(size * dpr);
    var ctx = c.getContext("2d");
    ctx.scale(dpr, dpr);
    medal(ctx, a, size, state);
    cache[key] = c.toDataURL("image/png");
    return cache[key];
  }

  function powerupIcon(type, size) {
    var key = "pu|" + type + "|" + size;
    if (cache[key]) return cache[key];
    var c = document.createElement("canvas");
    var dpr = Math.min(2, window.devicePixelRatio || 1);
    c.width = c.height = Math.round(size * dpr);
    var ctx = c.getContext("2d");
    ctx.scale(dpr, dpr);
    LM.itemsView.powerup(ctx, type, size / 2, size / 2, size * 0.95, 0);
    cache[key] = c.toDataURL("image/png");
    return cache[key];
  }

  function starIcon(size) {
    var key = "star|" + size;
    if (cache[key]) return cache[key];
    var c = document.createElement("canvas");
    var dpr = Math.min(2, window.devicePixelRatio || 1);
    c.width = c.height = Math.round(size * dpr);
    var ctx = c.getContext("2d");
    ctx.scale(dpr, dpr);
    LM.itemsView.star(ctx, size / 2, size / 2 - size * 0.1, size * 0.92, 0.4, { noHalo: true });
    cache[key] = c.toDataURL("image/png");
    return cache[key];
  }

  // The dark-level mark: a moonlit crescent in a night disc, with a warm spark.
  function darkIcon(size) {
    var key = "dark:" + size;
    if (cache[key]) return cache[key];
    var c = document.createElement("canvas");
    c.width = c.height = size;
    var x = c.getContext("2d"), r = size / 2;
    var bg = x.createRadialGradient(r * 0.8, r * 0.8, 0, r, r, r);
    bg.addColorStop(0, "#1a1f3d"); bg.addColorStop(1, "#05060f");
    x.fillStyle = bg; x.beginPath(); x.arc(r, r, r * 0.96, 0, TAU); x.fill();
    x.strokeStyle = "rgba(230,235,255,.35)"; x.lineWidth = size * 0.04; x.stroke();
    x.save(); x.translate(r, r); x.scale(r * 0.62, r * 0.62);
    x.shadowColor = "rgba(230,235,255,.8)"; x.shadowBlur = size * 0.12;
    x.fillStyle = "#e6ebff"; G.crescent(x);
    x.restore();
    var sp = x.createRadialGradient(r * 1.42, r * 1.38, 0, r * 1.42, r * 1.38, r * 0.4);
    sp.addColorStop(0, "rgba(255,217,138,1)"); sp.addColorStop(0.25, "rgba(255,190,100,.6)"); sp.addColorStop(1, "rgba(255,190,100,0)");
    x.fillStyle = sp; x.beginPath(); x.arc(r * 1.42, r * 1.38, r * 0.4, 0, TAU); x.fill();
    return (cache[key] = c.toDataURL());
  }

  LM.icons = { achievement: achievementIcon, powerup: powerupIcon, star: starIcon, dark: darkIcon, medal: medal, glyphs: G };
})(window.LUMEN);
