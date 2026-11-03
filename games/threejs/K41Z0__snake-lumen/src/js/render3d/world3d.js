window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // The three.js renderer for a run: a tilted camera over the board diorama,
  // cool moonlight with soft shadows, a hemisphere sky light, and the serpent
  // as a glowing body with a real warm light at its head. Stars, power-ups,
  // gates, trams and lanterns share a small pool of point lights; everything
  // else glows with additive sprites. The 2D canvas above draws particles,
  // banners and the countdown, using project() to find the cells on screen.
  var THREE = window.THREE;
  var K = LM.K3;
  var TAU = Math.PI * 2;
  var WARM = new THREE.Color("#ffbe76");
  var MAXSEG = 960;

  function World3D(host) {
    this.host = host;            // the 2D Scene (owns reserve, particles, overlays)
    this.ok = false;
    this.visible = false;
    this.setting = "auto";
    this.qName = null;
    this.fps = 60;
    this.dynScale = 1;
    this.key = "";
    this.camState = null;
    this.tmpV = new THREE.Vector3();
  }

  World3D.prototype.init = function (setting) {
    this.setting = setting || "auto";
    return this.rebuild();
  };

  World3D.prototype.rebuild = function () {
    var qName = K.resolve(this.setting);
    if (this.setting === "auto" && this.autoCap && ["low", "medium", "high"].indexOf(qName) > ["low", "medium", "high"].indexOf(this.autoCap)) qName = this.autoCap;
    var q = K.PRESETS[qName];
    if (this.renderer) {
      this.disposeLevel();
      this.renderer.dispose();
      if (this.canvas && this.canvas.parentNode) this.canvas.parentNode.removeChild(this.canvas);
    }
    var canvas = document.createElement("canvas");
    canvas.id = "view3d";
    canvas.setAttribute("aria-hidden", "true");
    var anchor = document.getElementById("view");
    anchor.parentNode.insertBefore(canvas, anchor);
    try {
      this.renderer = new THREE.WebGLRenderer({ canvas: canvas, antialias: q.antialias, powerPreference: "high-performance", alpha: false, stencil: false });
    } catch (e) {
      canvas.parentNode.removeChild(canvas);
      this.ok = false;
      return false;
    }
    this.canvas = canvas;
    this.qName = qName;
    this.q = q;
    var r = this.renderer;
    r.outputColorSpace = THREE.SRGBColorSpace;
    r.toneMapping = THREE.ACESFilmicToneMapping;
    r.toneMappingExposure = 1.05;
    r.shadowMap.enabled = q.shadows;
    r.shadowMap.type = THREE.PCFSoftShadowMap;
    canvas.style.display = this.visible ? "block" : "none";

    var scene = this.scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2("#141e3a", 0.012);
    this.camera = new THREE.PerspectiveCamera(36, 1, 1, 700); // a near plane of 1 keeps depth precise on phones

    // moonlight and sky
    this.hemi = new THREE.HemisphereLight("#9fb4ff", "#1a1e30", 0.6);
    scene.add(this.hemi);
    var moon = this.moon = new THREE.DirectionalLight("#c6d4ff", 1.2);
    moon.position.set(-8, 16, 7);
    moon.target.position.set(0, 0, 0);
    moon.castShadow = q.shadows;
    moon.shadow.mapSize.set(q.shadowSize, q.shadowSize);
    var sc = moon.shadow.camera;
    sc.left = -15; sc.right = 15; sc.top = 15; sc.bottom = -15; sc.near = 1; sc.far = 60;
    moon.shadow.bias = -0.0006;
    moon.shadow.normalBias = 0.03;
    moon.shadow.radius = 4;
    scene.add(moon, moon.target);

    // the serpent's light
    var head = this.headLight = new THREE.PointLight(WARM, 6, 9, 2);
    head.castShadow = q.headShadow;
    head.shadow.mapSize.set(512, 512);
    head.shadow.bias = -0.004;
    head.shadow.radius = 3;
    // the head itself sits closer than the near plane, so it never shades its
    // own light; the body, walls and items further away still cast shadows
    head.shadow.camera.near = 1.0;
    scene.add(head);

    // the light pool
    this.pool = [];
    for (var i = 0; i < q.pool; i++) {
      var pl = new THREE.PointLight("#ffd28c", 0, 3, 2);
      scene.add(pl);
      this.pool.push(pl);
    }

    this.buildSerpent();
    this.buildItems();
    this.ok = true;
    this.resize();
    this.key = "";
    return true;
  };

  World3D.prototype.setQuality = function (setting) {
    if (setting === this.setting && this.ok) return;
    this.setting = setting || "auto";
    this.autoCap = null;
    if (this.ok) this.rebuild();
  };

  World3D.prototype.setVisible = function (v) {
    if (v === this.visible) return;
    this.visible = v;
    if (this.canvas) this.canvas.style.display = v ? "block" : "none";
  };

  World3D.prototype.resize = function () {
    if (!this.renderer) return;
    var w = window.innerWidth, h = window.innerHeight;
    var pr = Math.min(window.devicePixelRatio || 1, this.q.pixelRatio) * this.dynScale;
    this.renderer.setPixelRatio(Math.max(0.5, pr));
    this.renderer.setSize(w, h, false);
    this.canvas.style.width = w + "px";
    this.canvas.style.height = h + "px";
    this.w = w; this.h = h;
    this.fitKey = "";
  };

  // ---------- the serpent ----------
  World3D.prototype.buildSerpent = function () {
    var geo = new THREE.SphereGeometry(1, 16, 10);
    this.bodyMat = new THREE.MeshStandardMaterial({ color: "#ffffff", roughness: 0.38, metalness: 0.02, emissive: "#ffd98a", emissiveIntensity: 0.32, transparent: true, opacity: 1 });
    var body = this.body = new THREE.InstancedMesh(geo, this.bodyMat, MAXSEG);
    body.count = 0;
    body.castShadow = true;
    body.receiveShadow = false;
    body.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    body.setColorAt(0, new THREE.Color("#ffffff"));
    body.frustumCulled = false;
    this.scene.add(body);
    // the head with eyes
    this.headGroup = new THREE.Group();
    this.headMat = new THREE.MeshStandardMaterial({ color: "#ffffff", roughness: 0.35, emissive: "#ffd98a", emissiveIntensity: 0.4, transparent: true });
    this.headMesh = new THREE.Mesh(geo, this.headMat);
    this.headMesh.castShadow = true;
    this.headMesh.scale.set(0.46, 0.42, 0.46);
    var white = new THREE.MeshStandardMaterial({ color: "#ffffff", roughness: 0.3, emissive: "#ffffff", emissiveIntensity: 0.2 });
    var dark = new THREE.MeshBasicMaterial({ color: "#1a1424" });
    this.eyes = [];
    for (var s = -1; s <= 1; s += 2) {
      var eye = new THREE.Mesh(geo, white);
      eye.scale.setScalar(0.11);
      eye.position.set(0.22, 0.2, s * 0.15);
      var pupil = new THREE.Mesh(geo, dark);
      pupil.scale.setScalar(0.06);
      pupil.position.set(0.3, 0.22, s * 0.15);
      this.headGroup.add(eye, pupil);
      this.eyes.push({ eye: eye, pupil: pupil, s: s });
    }
    this.headGroup.add(this.headMesh);
    this.scene.add(this.headGroup);
    // glow sprites along the body
    this.glows = [];
    for (var g = 0; g < 24; g++) {
      var sp = K.glowSprite("#ffd98a", 1.4, 0);
      this.scene.add(sp);
      this.glows.push(sp);
    }
    this.headGlow = K.glowSprite("#ffd98a", 3.2, 0.7);
    this.scene.add(this.headGlow);
  };

  // ---------- stars and power-ups ----------
  World3D.prototype.buildItems = function () {
    var scene = this.scene;
    function star(color, emissive, scale) {
      var m = new THREE.Mesh(K.starGeometry(), new THREE.MeshStandardMaterial({ color: color, emissive: emissive, emissiveIntensity: 1.6, roughness: 0.3, metalness: 0.3 }));
      m.scale.setScalar(scale);
      m.castShadow = true;
      return m;
    }
    this.star = star("#ffd98a", "#ffb547", 1.2);
    this.starGlow = K.glowSprite("#ffd38a", 2.4, 0.85);
    this.golden = star("#fff3bf", "#ffe08a", 1.3);
    this.goldenGlow = K.glowSprite("#fff0b0", 3.6, 1);
    this.goldenRing = new THREE.Mesh(new THREE.RingGeometry(0.62, 0.7, 48, 1, 0, TAU), new THREE.MeshBasicMaterial({ color: "#ffec99", transparent: true, opacity: 0.6, side: THREE.DoubleSide, depthWrite: false }));
    this.goldenRing.rotation.x = -Math.PI / 2;
    this.orb = new THREE.Mesh(new THREE.SphereGeometry(0.3, 24, 16), new THREE.MeshStandardMaterial({ color: "#ffffff", emissive: "#ffffff", emissiveIntensity: 1, roughness: 0.2, transparent: true, opacity: 0.9 }));
    this.orb.castShadow = true;
    this.orbGlow = K.glowSprite("#ffffff", 2.2, 0.8);
    this.orbIcons = {};
    this.magnet = K.glowSprite("#ffaa8c", 2.8, 0);
    [this.star, this.starGlow, this.golden, this.goldenGlow, this.goldenRing, this.orb, this.orbGlow, this.magnet].forEach(function (o) { o.visible = false; scene.add(o); });
  };

  World3D.prototype.orbIcon = function (type) {
    if (this.orbIcons[type]) return this.orbIcons[type];
    var sp = K.drawnSprite(0.85, function (x, w) {
      if (LM.itemsView && LM.itemsView.powerup) LM.itemsView.powerup(x, type, w / 2, w / 2, w * 0.7, 0, 1);
    });
    sp.visible = false;
    sp.renderOrder = 6;
    this.scene.add(sp);
    this.orbIcons[type] = sp;
    return sp;
  };

  // ---------- level ----------
  World3D.prototype.disposeLevel = function () {
    if (this.board3) { this.scene.remove(this.board3.group); this.board3.dispose(); this.board3 = null; }
    if (this.dio) { this.scene.remove(this.dio.group); this.dio.dispose(); this.dio = null; }
    this.key = "";
  };

  World3D.prototype.prepare = function (g, world) {
    var b = g.board;
    var key = [world, b.cols, b.rows, b.walls.join(""), g.level && g.level.id, this.qName, g.mode].join("|");
    if (key === this.key && this.game === g) return;
    if (key !== this.key) {
      this.disposeLevel();
      this.board3 = new LM.Board3D(g, world, this.q);
      this.dio = new LM.Diorama(world, this.q, b, this.renderer);
      this.scene.add(this.dio.group, this.board3.group);
      this.key = key;
      this.fitKey = "";
      this.warmUp();
    }
    this.game = g;
    this.introAt = -1;
    this.nightFade = 0;
    this.world = world;
  };

  // Compile every shader the level can need now, so the first star, orb or
  // golden star does not stall a frame mid-run.
  World3D.prototype.warmUp = function () {
    var self = this, items = [this.star, this.starGlow, this.golden, this.goldenGlow, this.goldenRing, this.orb, this.orbGlow, this.magnet];
    ["slow", "ghost", "magnet", "double"].forEach(function (k) { items.push(self.orbIcon(k)); });
    var was = items.map(function (o) { return o.visible; });
    items.forEach(function (o) { o.visible = true; });
    try { this.renderer.compile(this.scene, this.camera); } catch (e) { /* compile is only a hint */ }
    items.forEach(function (o, i) { o.visible = was[i]; });
  };

  // ---------- camera ----------
  // A gentle tilt over the board, fitted into the space the HUD leaves free.
  World3D.prototype.fit = function (b) {
    var r = this.host.reserve, w = this.w, h = this.h;
    var fk = [w, h, r.top, r.bottom, r.left, r.right, b.cols, b.rows].join("|");
    if (fk === this.fitKey) return;
    this.fitKey = fk;
    var aw = Math.max(80, w - r.left - r.right), ah = Math.max(80, h - r.top - r.bottom);
    var portrait = aw < ah * 0.9;
    this.tilt = portrait ? 1.16 : 0.96;   // radians from horizontal
    var cam = this.camera;
    cam.aspect = w / h;
    cam.clearViewOffset();
    cam.updateProjectionMatrix();
    var W = b.cols, H = b.rows, self = this;
    var corners = [[-W / 2, 0, -H / 2], [W / 2, 0, -H / 2], [-W / 2, 0, H / 2], [W / 2, 0, H / 2], [-W / 2, 0.9, -H / 2], [W / 2, 0.9, -H / 2]];
    var dist = Math.max(W, H) * 1.6;
    var box;
    for (var it = 0; it < 6; it++) {
      this.placeCamera(dist, 0, 0, 0);
      box = this.bbox(corners);
      var k = Math.max((box.x1 - box.x0) / (aw * 0.96), (box.y1 - box.y0) / (ah * 0.96));
      dist *= 0.35 + 0.65 * k;
    }
    this.placeCamera(dist, 0, 0, 0);
    box = this.bbox(corners);
    // shift the view so the board sits in the middle of the free space
    var cx = (box.x0 + box.x1) / 2, cy = (box.y0 + box.y1) / 2;
    var tx = r.left + aw / 2, ty = r.top + ah / 2;
    this.viewOffset = { x: cx - tx, y: cy - ty };
    cam.setViewOffset(w, h, this.viewOffset.x, this.viewOffset.y, w, h);
    cam.updateProjectionMatrix();
    this.dist = dist;
    this.camState = { x: 0, z: 0, yaw: 0 };
    void self;
  };

  World3D.prototype.placeCamera = function (dist, fx, fz, yaw) {
    var cam = this.camera, t = this.tilt;
    var tgt = new THREE.Vector3(fx, 0, fz + 0.4);
    cam.position.set(tgt.x + Math.sin(yaw) * Math.cos(t) * dist, tgt.y + Math.sin(t) * dist, tgt.z + Math.cos(yaw) * Math.cos(t) * dist);
    cam.lookAt(tgt);
    cam.updateMatrixWorld();
  };

  World3D.prototype.bbox = function (pts) {
    var b = { x0: 1e9, y0: 1e9, x1: -1e9, y1: -1e9 }, v = this.tmpV, w = this.w, h = this.h;
    for (var i = 0; i < pts.length; i++) {
      v.set(pts[i][0], pts[i][1], pts[i][2]).project(this.camera);
      var x = (v.x + 1) / 2 * w, y = (1 - v.y) / 2 * h;
      b.x0 = Math.min(b.x0, x); b.x1 = Math.max(b.x1, x); b.y0 = Math.min(b.y0, y); b.y1 = Math.max(b.y1, y);
    }
    return b;
  };

  // board cell -> screen point (CSS px), for the 2D overlay
  World3D.prototype.project = function (c, y) {
    if (!this.game) return { x: 0, y: 0 };
    var b = this.game.board, v = this.tmpV;
    v.set(c.x - b.cols / 2 + 0.5, y === undefined ? 0.45 : y, c.y - b.rows / 2 + 0.5).project(this.camera);
    return { x: (v.x + 1) / 2 * this.w, y: (1 - v.y) / 2 * this.h };
  };

  World3D.prototype.updateLayout = function (b) {
    var W = b.cols, H = b.rows;
    var box = this.bbox([[-W / 2, 0, -H / 2], [W / 2, 0, -H / 2], [-W / 2, 0, H / 2], [W / 2, 0, H / 2]]);
    var a = this.project({ x: Math.floor(W / 2) - 1, y: Math.floor(H / 2) }, 0), c = this.project({ x: Math.floor(W / 2), y: Math.floor(H / 2) }, 0);
    var cell = Math.max(6, Math.abs(c.x - a.x));
    this.host.layoutBox = { cell: cell, ox: box.x0, oy: box.y0, w: box.x1 - box.x0, h: box.y1 - box.y0 };
  };

  // ---------- frame ----------
  World3D.prototype.render = function (f) {
    var g = f.game, b = g.board, t = f.t;
    var world = f.boardWorld === undefined ? f.world : f.boardWorld;
    var reduced = !!(f.settings && f.settings.reducedFlash);
    this.prepare(g, world);
    this.fit(b);
    var alpha = g.status === "running" ? g.alpha : (g.status === "ready" ? 0 : 1);
    var light = Math.max(0, Math.min(1, f.light === undefined ? 1 : f.light));
    var dark = !!(g.level && g.level.dark);
    this.dark = dark;
    var want = !dark ? 1 : g.status === "won" ? 1 : g.status === "over" ? 0.4 : 0;
    this.nightFade += (want - this.nightFade) * Math.min(1, (f.dt || 0.016) * (want > this.nightFade ? 1.2 : 6));
    if (!dark) this.nightFade = 1;
    var day = this.nightFade;

    // points of the serpent, in board units
    var pts = LM.SnakeView.points(g.snake.cells, g.prevCells, alpha, -b.cols / 2, -b.rows / 2, 1);
    var head = pts[0];

    // camera: a slight follow toward the head, a touch of parallax, shake
    var cs = this.camState;
    var k = Math.min(1, (f.dt || 0.016) * 1.5);
    cs.x += (head.x * 0.06 - cs.x) * k;
    cs.z += (head.y * 0.05 - cs.z) * k;
    cs.yaw += (head.x / b.cols * 0.05 - cs.yaw) * k;
    // a short glide from a low view of the world down to the board
    if (this.introAt < 0) this.introAt = t;
    var ik = reduced || g.status === "running" && t - this.introAt > 2.2 ? 1 : Math.min(1, (t - this.introAt) / 2.2);
    var ie = 1 - Math.pow(1 - ik, 3), baseTilt = this.tilt;
    this.tilt = baseTilt - (1 - ie) * 0.62;
    this.placeCamera(this.dist * (1 + 0.3 * (1 - ie)), cs.x, cs.z, cs.yaw + (1 - ie) * 0.12);
    this.tilt = baseTilt;
    var sh = this.host.shakeAmt || 0;
    if (sh > 0.1 && !(f.settings && f.settings.shake === false)) {
      var amt = sh / Math.max(8, this.host.layoutBox.cell || 20) * 0.12 * (reduced ? 0.4 : 1);
      this.camera.position.x += (Math.random() - 0.5) * amt;
      this.camera.position.y += (Math.random() - 0.5) * amt;
    }
    this.camera.updateMatrixWorld();
    this.updateLayout(b);

    // world light: moonlight, sky, fog
    var fog = this.dio.fogColor(light);
    var nightK = dark ? 0.15 + 0.85 * day : 1;
    this.scene.fog.color.copy(fog).multiplyScalar(dark ? 0.45 + 0.55 * day : 1);
    // fog is measured from the board, not the lens: a phone camera stands much
    // further back to fit the board in a narrow screen
    this.scene.fog.density = (dark ? 0.02 - 0.008 * day : 0.012) * Math.min(1, 34 / (this.dist || 34));
    this.renderer.setClearColor(this.scene.fog.color);
    this.hemi.intensity = (0.75 + 0.55 * light) * nightK;
    this.hemi.color.set(light > 0.5 ? "#b8c6ff" : "#9fb4ff");
    this.hemi.groundColor.set(["#24331f", "#2a2630", "#2a3058", "#1c2140"][world]);
    this.moon.intensity = (1.25 + 0.8 * light) * (dark ? 0.12 + 0.88 * day : 1);
    this.moon.color.set(light > 0.6 ? "#d6deff" : "#c0ceff");
    this.renderer.toneMappingExposure = 1.05;

    this.board3.update(g, t, light, alpha, dark, reduced);
    this.dio.update(t, light, dark, reduced);

    // the serpent
    this.drawSerpent(f, g, pts, alpha, t, dark, reduced);

    // items
    var cand = [];
    this.drawItems(f, g, alpha, t, dark, reduced, cand, head);
    this.board3.lightCandidates(cand, light, dark);
    this.dio.lightCandidates(cand);
    this.assignPool(cand, head, dark);

    this.renderer.render(this.scene, this.camera);
    this.trackFps(f.dt);
  };

  World3D.prototype.drawSerpent = function (f, g, pts, alpha, t, dark, reduced) {
    var n = pts.length, skin = f.skin || LM.SnakeView.skinById("lumen");
    var dead = f.dead || g.status === "over";
    var body = this.body, m = new THREE.Matrix4(), q = new THREE.Quaternion(), s = new THREE.Vector3(), p = new THREE.Vector3(), col = new THREE.Color();
    var gk = Math.max(0, Math.min(1, (n - 4) / 36));
    var idx = 0;
    function radius(i) { return Math.max(0.2, 0.37 - 0.15 * Math.pow(i / Math.max(1, n - 1), 1.4)); }
    var samples = [];
    for (var i = 1; i < n; i++) {
      var a = pts[i - 1], bb = pts[i];
      var jump = Math.abs(a.x - bb.x) + Math.abs(a.y - bb.y) > 1.6;
      var sub = jump ? 1 : (n > 200 ? 2 : n > 80 ? 3 : 4);
      for (var j = jump ? 1 : 0; j < sub; j++) {
        var u = j / sub;
        samples.push({ x: a.x + (bb.x - a.x) * u, y: a.y + (bb.y - a.y) * u, i: i - 1 + u });
      }
    }
    samples.push({ x: pts[n - 1].x, y: pts[n - 1].y, i: n - 1 });
    for (var si = 1; si < samples.length && idx < MAXSEG; si++) {
      var sp = samples[si], r = radius(sp.i);
      p.set(sp.x, r * 0.92, sp.y);
      s.set(r, r * 0.9, r);
      m.compose(p, q, s);
      body.setMatrixAt(idx, m);
      var c = dead ? "#5c6070" : LM.SnakeView.segColor(skin, Math.round(sp.i), n, t);
      body.setColorAt(idx, col.set(c));
      idx++;
    }
    body.count = idx;
    body.instanceMatrix.needsUpdate = true;
    if (body.instanceColor) body.instanceColor.needsUpdate = true;
    var ghost = g.effects.ghost > 0;
    var op = ghost ? (g.effects.ghost < 1500 && Math.sin(t * 18) > 0 ? 0.85 : 0.5) : 1;
    var glowCol = g.effects.double > 0 ? "#ffd166" : (skin.glow || skin.colors[0]);
    this.bodyMat.opacity = this.headMat.opacity = op;
    this.bodyMat.emissive.set(dead ? "#000000" : glowCol);
    this.headMat.emissive.set(dead ? "#000000" : glowCol);
    this.bodyMat.emissiveIntensity = (dark ? 0.42 : 0.3) + 0.12 * gk;
    this.headMat.emissiveIntensity = (dark ? 0.5 : 0.36) + 0.1 * gk;
    this.headMat.color.set(dead ? "#6e7280" : LM.SnakeView.segColor(skin, 0, n, t));

    // head: position, facing, eyes looking toward the star
    var hd = pts[0], nk = pts[1] || { x: hd.x - g.snake.dir.x, y: hd.y - g.snake.dir.y };
    var dx = hd.x - nk.x, dy = hd.y - nk.y;
    if (Math.abs(dx) + Math.abs(dy) > 1.6 || (!dx && !dy)) { dx = g.snake.dir.x; dy = g.snake.dir.y; }
    this.headGroup.position.set(hd.x, 0.42, hd.y);
    this.headGroup.rotation.y = -Math.atan2(dy, dx);
    var bob = reduced ? 0 : Math.sin(t * 6) * 0.015;
    this.headGroup.position.y += bob;
    var blink = !dead && (t % 3.7) < 0.12;
    this.eyes.forEach(function (e) { e.eye.scale.y = blink ? 0.02 : 0.11; e.pupil.visible = !blink && !dead; });

    // the warm light: brighter and wider the longer the serpent grows
    var flick = reduced ? 1 : 1 + 0.03 * Math.sin(t * 6.1) + 0.02 * Math.sin(t * 11.7 + 1.3);
    var boost = g.effects.double > 0 ? 1.2 : 1;
    var L = this.headLight;
    L.position.set(hd.x + dx * 0.15, dark ? 1.4 : 1.25, hd.y + dy * 0.15);
    L.distance = (dark ? 6.5 + 6 * gk : 6 + 4 * gk) * boost;
    L.intensity = dead ? 0.6 : (dark ? 13 + 9 * gk : 5 + 4 * gk) * flick * boost;
    L.color.copy(WARM);
    // glow sprites
    this.headGlow.position.set(hd.x, 0.5, hd.y);
    this.headGlow.material.opacity = dead ? 0.1 : (dark ? 0.55 : 0.4) * op;
    this.headGlow.material.color.set(glowCol);
    this.headGlow.scale.setScalar(2.4 + 1.6 * gk);
    var step = Math.max(1, Math.ceil(n / this.glows.length));
    for (var gi = 0; gi < this.glows.length; gi++) {
      var pi = 1 + gi * step, sg = this.glows[gi];
      if (pi >= n || dead) { sg.material.opacity = 0; continue; }
      sg.position.set(pts[pi].x, 0.35, pts[pi].y);
      sg.material.color.set(glowCol);
      sg.material.opacity = (0.12 + 0.1 * gk) * (1 - pi / n * 0.6) * op * (dark ? 1.3 : 1);
      sg.scale.setScalar(1.3 + 0.5 * gk);
    }
  };

  World3D.prototype.drawItems = function (f, g, alpha, t, dark, reduced, cand, head) {
    var b = g.board, self = this;
    function X(x) { return x - b.cols / 2 + 0.5; }
    function Z(y) { return y - b.rows / 2 + 0.5; }
    var spin = reduced ? 0.4 : 1;
    // fallen star
    var st = g.star;
    this.star.visible = this.starGlow.visible = !!st;
    this.magnet.visible = !!st && g.effects.magnet > 0;
    if (st) {
      var bp = g.starPrev || st;
      var jump = Math.abs(bp.x - st.x) + Math.abs(bp.y - st.y) > 1;
      var sx = jump ? st.x : bp.x + (st.x - bp.x) * alpha, sy = jump ? st.y : bp.y + (st.y - bp.y) * alpha;
      var y = 0.55 + (reduced ? 0 : Math.sin(t * 2.4) * 0.08);
      this.star.position.set(X(sx), y, Z(sy));
      this.star.rotation.set(-0.85, Math.sin(t * 1.3) * 0.55 * spin, Math.sin(t * 0.7) * 0.12 * spin);
      this.starGlow.position.set(X(sx), y, Z(sy));
      var tw = reduced ? 1 : 0.85 + 0.15 * Math.sin(t * 5);
      this.starGlow.material.opacity = (dark ? 1 : 0.8) * tw;
      this.magnet.position.copy(this.starGlow.position);
      this.magnet.material.opacity = 0.35 + 0.15 * Math.sin(t * 8);
      cand.push({ x: X(sx), y: 0.8, z: Z(sy), color: "#ffcf80", i: dark ? 3.2 : 2.2, d: dark ? 4.2 : 3.2, pri: 3, bx: sx, by: sy });
    }
    // golden star
    var gd = g.golden;
    this.golden.visible = this.goldenGlow.visible = this.goldenRing.visible = !!gd;
    if (gd) {
      var gy = 0.65 + (reduced ? 0 : Math.sin(t * 3) * 0.1);
      this.golden.position.set(X(gd.x), gy, Z(gd.y));
      this.golden.rotation.set(-0.85, Math.sin(t * 1.8) * 0.6 * spin, 0);
      this.goldenGlow.position.set(X(gd.x), gy, Z(gd.y));
      this.goldenGlow.material.opacity = 0.9;
      var left = gd.ttl / gd.max;
      this.goldenRing.position.set(X(gd.x), 0.04, Z(gd.y));
      var arc = Math.max(1, Math.round(left * 64));
      if (arc !== this.ringArc) {
        this.ringArc = arc;
        this.goldenRing.geometry.dispose();
        this.goldenRing.geometry = new THREE.RingGeometry(0.62, 0.7, 48, 1, Math.PI / 2, TAU * arc / 64);
      }
      cand.push({ x: X(gd.x), y: 0.9, z: Z(gd.y), color: "#fff0b0", i: dark ? 4 : 3, d: dark ? 5 : 3.8, pri: 4, bx: gd.x, by: gd.y });
    }
    // power-up orb, with its 2D icon floating inside
    var it = g.item;
    Object.keys(this.orbIcons).forEach(function (k) { self.orbIcons[k].visible = false; });
    this.orb.visible = this.orbGlow.visible = !!it;
    if (it) {
      var pc = LM.config.powerups[it.type].color;
      var oy = 0.5 + (reduced ? 0 : Math.sin(t * 2) * 0.06);
      var blinkOut = it.ttl < 2000 && Math.sin(t * 16) > 0 && !reduced;
      this.orb.position.set(X(it.x), oy, Z(it.y));
      this.orb.material.color.set(pc);
      this.orb.material.emissive.set(pc);
      this.orb.material.emissiveIntensity = blinkOut ? 0.3 : 0.9;
      this.orb.material.opacity = 0.55;
      this.orbGlow.position.copy(this.orb.position);
      this.orbGlow.material.color.set(pc);
      this.orbGlow.material.opacity = blinkOut ? 0.3 : 0.75;
      var icon = this.orbIcon(it.type);
      icon.visible = true;
      icon.position.set(X(it.x), oy + 0.02, Z(it.y));
      cand.push({ x: X(it.x), y: 0.8, z: Z(it.y), color: pc, i: dark ? 2.4 : 1.6, d: dark ? 3.4 : 2.6, pri: 3, bx: it.x, by: it.y });
    }
    void head;
  };

  // the few dynamic lights go to the emitters that matter most right now
  World3D.prototype.assignPool = function (cand, head, dark) {
    cand.forEach(function (c) {
      var hx = c.bx === undefined ? 99 : c.bx - head.x - 0 + 0, hy = c.by === undefined ? 99 : c.by - head.y;
      var d = c.bx === undefined ? 30 : Math.sqrt(hx * hx + hy * hy);
      c.score = c.pri * 10 - d * (dark ? 1.2 : 0.4);
    });
    cand.sort(function (a, b) { return b.score - a.score; });
    for (var i = 0; i < this.pool.length; i++) {
      var L = this.pool[i], c = cand[i];
      if (!c) { L.intensity = 0; continue; }
      L.position.set(c.x, c.y, c.z);
      L.color.set(c.color);
      L.intensity = c.i;
      L.distance = c.d;
    }
  };

  // adaptive resolution: if frames are slow, render fewer pixels
  // Adaptive resolution from the real frame rate (wall clock, since the game
  // clamps dt). On "auto" a machine that stays slow at the lowest scale
  // also drops one quality preset.
  World3D.prototype.trackFps = function () {
    var now = performance.now();
    var last = this.fpsLast; this.fpsLast = now;
    if (!last) return;
    var dt = (now - last) / 1000;
    if (dt > 0.5 || this.adaptive === false) return; // adaptive is switched off only for still screenshots // tab was hidden or the run was paused
    this.fps += (1 / Math.max(0.001, dt) - this.fps) * 0.08;
    this.fpsT = (this.fpsT || 0) + dt;
    if (this.fpsT < 2.5) return;
    this.fpsT = 0;
    var before = this.dynScale;
    if (this.fps < 40 && this.dynScale > 0.55) this.dynScale = Math.max(0.55, this.dynScale - 0.15);
    else if (this.fps > 58 && this.dynScale < 1 && !this.dynCapped) this.dynScale = Math.min(1, this.dynScale + 0.05);
    // a machine that had to step down twice does not climb back up mid-run
    if (this.dynScale < before) this.dynDrops = (this.dynDrops || 0) + 1;
    if (this.dynDrops >= 2) this.dynCapped = true;
    if (before !== this.dynScale) this.resize();
    if (this.setting === "auto" && this.fps < 28 && this.dynScale <= 0.55) {
      this.slowCount = (this.slowCount || 0) + 1;
      var order = ["low", "medium", "high"], i = order.indexOf(this.qName);
      if (this.slowCount >= 2 && i > 0) {
        this.slowCount = 0;
        this.autoCap = order[i - 1];
        this.dynScale = 1;
        this.rebuild();
      }
    } else this.slowCount = 0;
  };

  // average brightness of the board on screen (used by the tests)
  World3D.prototype.measure = function () {
    if (!this.ok || !this.game) return null;
    this.renderer.render(this.scene, this.camera);
    var gl = this.renderer.getContext();
    var L = this.host.layoutBox, pr = this.renderer.getPixelRatio();
    var x0 = Math.round(L.ox * pr), y0 = Math.round((this.h - L.oy - L.h) * pr), w = Math.round(L.w * pr), h = Math.round(L.h * pr);
    var px = new Uint8Array(w * h * 4);
    gl.readPixels(x0, y0, w, h, gl.RGBA, gl.UNSIGNED_BYTE, px);
    var sum = 0, black = 0, n = 0;
    for (var i = 0; i < px.length; i += 16) {
      var y = px[i] * 0.3 + px[i + 1] * 0.59 + px[i + 2] * 0.11;
      sum += y; n++; if (y < 4) black++;
    }
    return { mean: +(sum / n).toFixed(1), black: +(black / n).toFixed(3) };
  };

  LM.World3D = World3D;
})(window.LUMEN);
