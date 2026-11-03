window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // Small shared helpers for the three.js renderer: canvas textures, the
  // star shape, colours, and the graphics quality presets.
  var THREE = window.THREE;
  var K = {};
  var TAU = Math.PI * 2;

  K.available = function () {
    if (!THREE) return false;
    try {
      var c = document.createElement("canvas");
      return !!(window.WebGLRenderingContext && (c.getContext("webgl2") || c.getContext("webgl")));
    } catch (e) { return false; }
  };

  // Low / Medium / High; "auto" picks one from the device.
  K.PRESETS = {
    low: { pixelRatio: 1, shadows: false, shadowSize: 512, headShadow: false, pool: 2, antialias: false, fireflies: 50, extras: 0.5 },
    medium: { pixelRatio: 1.5, shadows: true, shadowSize: 1024, headShadow: false, pool: 4, antialias: true, fireflies: 100, extras: 0.8 },
    high: { pixelRatio: 2, shadows: true, shadowSize: 2048, headShadow: true, pool: 6, antialias: true, fireflies: 160, extras: 1 }
  };

  K.autoQuality = function () {
    var touch = ("ontouchstart" in window && navigator.maxTouchPoints > 0) || (window.matchMedia && window.matchMedia("(pointer: coarse)").matches);
    var small = Math.min(window.screen ? screen.width : 1280, window.screen ? screen.height : 800) < 900;
    if (touch && small) return "low";
    if (touch) return "medium";
    return "medium";
  };

  K.resolve = function (setting) {
    return K.PRESETS[setting] ? setting : K.autoQuality();
  };

  K.color = function (c) { return new THREE.Color(c); };

  K.canvasTexture = function (w, h, paint, srgb) {
    var c = document.createElement("canvas");
    c.width = w; c.height = h;
    paint(c.getContext("2d"), w, h);
    var tex = new THREE.CanvasTexture(c);
    if (srgb !== false) tex.colorSpace = THREE.SRGBColorSpace;
    tex.anisotropy = 4;
    return tex;
  };

  // A soft round glow, white, for additive sprites.
  var glowCache = null;
  K.glowTexture = function () {
    if (glowCache) return glowCache;
    glowCache = K.canvasTexture(128, 128, function (x, w) {
      var g = x.createRadialGradient(w / 2, w / 2, 0, w / 2, w / 2, w / 2);
      g.addColorStop(0, "rgba(255,255,255,1)");
      g.addColorStop(0.18, "rgba(255,255,255,.55)");
      g.addColorStop(0.45, "rgba(255,255,255,.14)");
      g.addColorStop(1, "rgba(255,255,255,0)");
      x.fillStyle = g;
      x.fillRect(0, 0, w, w);
    });
    return glowCache;
  };

  K.glowSprite = function (color, size, opacity) {
    var m = new THREE.SpriteMaterial({ map: K.glowTexture(), color: new THREE.Color(color), transparent: true, opacity: opacity === undefined ? 1 : opacity,
      blending: THREE.AdditiveBlending, depthWrite: false, fog: false });
    var s = new THREE.Sprite(m);
    s.scale.set(size, size, 1);
    s.renderOrder = 5;
    return s;
  };

  // A soft smoke puff texture.
  var smokeCache = null;
  K.smokeTexture = function () {
    if (smokeCache) return smokeCache;
    smokeCache = K.canvasTexture(64, 64, function (x, w) {
      var g = x.createRadialGradient(w / 2, w / 2, 0, w / 2, w / 2, w / 2);
      g.addColorStop(0, "rgba(220,226,240,.5)");
      g.addColorStop(1, "rgba(220,226,240,0)");
      x.fillStyle = g;
      x.fillRect(0, 0, w, w);
    });
    return smokeCache;
  };

  // The night sky as a vertical gradient on a big inverted sphere.
  K.skyTexture = function (top, mid, bottom) {
    return K.canvasTexture(4, 256, function (x, w, h) {
      var g = x.createLinearGradient(0, 0, 0, h);
      g.addColorStop(0, top);
      g.addColorStop(0.5, mid);
      g.addColorStop(1, bottom);
      x.fillStyle = g;
      x.fillRect(0, 0, w, h);
    });
  };

  // The Moon, painted with the same art as the 2D game.
  K.moonTexture = function (fill) {
    return K.canvasTexture(512, 512, function (x) {
      if (LM.drawMoon) LM.drawMoon(x, 256, 256, 150, fill);
      // the 2D Moon carries a halo; fade it out before the square's edge
      x.globalCompositeOperation = "destination-in";
      var g = x.createRadialGradient(256, 256, 160, 256, 256, 255);
      g.addColorStop(0, "rgba(0,0,0,1)"); g.addColorStop(1, "rgba(0,0,0,0)");
      x.fillStyle = g;
      x.fillRect(0, 0, 512, 512);
      x.globalCompositeOperation = "source-over";
    });
  };

  // A five-pointed star, extruded and bevelled, lying in the XY plane.
  var starGeo = null;
  K.starGeometry = function () {
    if (starGeo) return starGeo;
    var s = new THREE.Shape();
    for (var i = 0; i < 10; i++) {
      var r = i % 2 ? 0.17 : 0.4, a = -Math.PI / 2 + i * Math.PI / 5;
      var px = Math.cos(a) * r, py = -Math.sin(a) * r;
      if (i === 0) s.moveTo(px, py); else s.lineTo(px, py);
    }
    s.closePath();
    starGeo = new THREE.ExtrudeGeometry(s, { depth: 0.08, bevelEnabled: true, bevelThickness: 0.05, bevelSize: 0.04, bevelSegments: 2 });
    starGeo.center();
    return starGeo;
  };

  // A sprite carrying a 2D drawing (power-up icons reuse the 2D art).
  K.drawnSprite = function (size, paint) {
    var tex = K.canvasTexture(128, 128, paint);
    var m = new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false, fog: false });
    var s = new THREE.Sprite(m);
    s.scale.set(size, size, 1);
    return s;
  };

  K.rng = function (seed) { return new LM.Rng(seed); };
  K.TAU = TAU;
  LM.K3 = K;
})(window.LUMEN);
