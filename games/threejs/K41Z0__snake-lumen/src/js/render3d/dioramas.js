window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // The world around the board, one diorama per world: the moonlit garden,
  // the old town, the sky above the clouds, the silver path to the Moon.
  // Everything here is decoration; it wakes up with the light (0..1).
  var THREE = window.THREE;
  var K = LM.K3;
  var TAU = Math.PI * 2;
  var dummy = new THREE.Object3D();

  function std(o) { return new THREE.MeshStandardMaterial(o); }

  var SKY = [
    { top: ["#060a1c", "#0e1a3c"], mid: ["#101a3a", "#1d3058"], low: ["#1a2848", "#2c4468"], fog: ["#141e3a", "#24365a"] },
    { top: ["#070a1c", "#0f1838"], mid: ["#121a38", "#22284c"], low: ["#1f2440", "#3a3450"], fog: ["#171c34", "#2a2c48"] },
    { top: ["#050818", "#0c1436"], mid: ["#0e1636", "#1a2a5c"], low: ["#1e2a52", "#34467c"], fog: ["#1a2448", "#2c3c6c"] },
    { top: ["#060818", "#0e1534"], mid: ["#0f1530", "#1c2650"], low: ["#1a2240", "#2e3a66"], fog: ["#121a34", "#222e56"] }
  ];

  function lerpHex(a, b, k) { return new THREE.Color(a).lerp(new THREE.Color(b), k); }

  function Diorama(world, quality, board, renderer) {
    this.world = world;
    this.q = quality;
    this.renderer = renderer;
    this.group = new THREE.Group();
    this.rng = K.rng(900 + world);
    this.anim = [];
    this.W = board.cols;
    this.H = board.rows;
    this.lastLight = -1;
    this.buildSky();
    this["world" + world]();
  }

  Diorama.prototype.fogColor = function (light) {
    var s = SKY[this.world];
    return lerpHex(s.fog[0], s.fog[1], light);
  };

  Diorama.prototype.buildSky = function () {
    var s = SKY[this.world];
    this.skyMat = new THREE.MeshBasicMaterial({ map: K.skyTexture(s.top[0], s.mid[0], s.low[0]), side: THREE.BackSide, fog: false, depthWrite: false });
    this.skyMat2 = new THREE.MeshBasicMaterial({ map: K.skyTexture(s.top[1], s.mid[1], s.low[1]), side: THREE.BackSide, fog: false, depthWrite: false, transparent: true, opacity: 0 });
    var geo = new THREE.SphereGeometry(300, 32, 16, 0, TAU, 0, Math.PI * 0.62);
    var a = new THREE.Mesh(geo, this.skyMat), b = new THREE.Mesh(geo, this.skyMat2);
    a.renderOrder = -10; b.renderOrder = -9;
    this.group.add(a, b);
    // stars
    var n = this.world === 2 ? 1400 : 900, pos = new Float32Array(n * 3), rng = this.rng;
    for (var i = 0; i < n; i++) {
      var th = rng.next() * TAU, ph = Math.acos(1 - rng.next() * 0.9), r = 280;
      pos[i * 3] = Math.sin(ph) * Math.cos(th) * r;
      pos[i * 3 + 1] = Math.cos(ph) * r * 0.9 + 10;
      pos[i * 3 + 2] = Math.sin(ph) * Math.sin(th) * r;
    }
    var sg = new THREE.BufferGeometry();
    sg.setAttribute("position", new THREE.BufferAttribute(pos, 3));
    this.starMat = new THREE.PointsMaterial({ color: "#e4ebff", size: 1.6, sizeAttenuation: false, transparent: true, opacity: 0.7, fog: false, depthWrite: false });
    var pts = new THREE.Points(sg, this.starMat);
    pts.renderOrder = -8;
    this.group.add(pts);
    // the Moon: small in most worlds, huge on the Moon's Path
    var huge = this.world === 3;
    this.moonTex = K.moonTexture(huge ? 0.35 : 0.55);
    this.moonFill = huge ? 0.35 : 0.55;
    this.moon = new THREE.Sprite(new THREE.SpriteMaterial({ map: this.moonTex, fog: false, depthWrite: false, transparent: true }));
    if (huge) { this.moon.position.set(0, 2, -170); this.moon.scale.set(110, 110, 1); }
    else { this.moon.position.set(-60, 70, -170); this.moon.scale.set(48, 48, 1); }
    this.moon.renderOrder = -7;
    this.group.add(this.moon);
  };

  // A tiny environment map (sky gradient and a bright Moon) so the water
  // and polished stone have something real to reflect.
  Diorama.prototype.nightEnv = function () {
    if (!this.renderer) return null;
    var s = SKY[this.world], es = new THREE.Scene();
    es.add(new THREE.Mesh(new THREE.SphereGeometry(50, 24, 12), new THREE.MeshBasicMaterial({ map: K.skyTexture(s.top[1], s.mid[1], s.low[0]), side: THREE.BackSide })));
    var disc = new THREE.Mesh(new THREE.CircleGeometry(9, 32), new THREE.MeshBasicMaterial({ color: "#f4f6ff" }));
    disc.position.set(0, 36, -30); disc.lookAt(0, 0, 0);
    es.add(disc);
    var pm = new THREE.PMREMGenerator(this.renderer);
    var rt = pm.fromScene(es, 0.02);
    pm.dispose();
    this.envRT = rt;
    return rt.texture;
  };

  // a big ground plane around the board
  Diorama.prototype.ground = function (color, rough, y) {
    var g = new THREE.Mesh(new THREE.CircleGeometry(180, 48), std({ color: color, roughness: rough === undefined ? 1 : rough }));
    g.rotation.x = -Math.PI / 2;
    g.position.y = y === undefined ? -0.9 : y;
    g.receiveShadow = true;
    this.group.add(g);
    return g;
  };

  // spots around the board (not on it), mostly on the far side
  Diorama.prototype.around = function (n, rMin, rMax, farBias) {
    var out = [], rng = this.rng, W = this.W, H = this.H, guard = 0;
    while (out.length < n && guard++ < n * 20) {
      var a = rng.next() * TAU;
      if (farBias && Math.sin(a) > 0.2 && rng.next() < farBias) continue; // fewer on the near side
      var r = rMin + rng.next() * (rMax - rMin);
      var x = Math.cos(a) * r, z = Math.sin(a) * r * 0.9 - 4;
      if (Math.abs(x) < W / 2 + 2.5 && Math.abs(z) < H / 2 + 2.5) continue;
      out.push({ x: x, z: z });
    }
    return out;
  };

  // ---------- the Whispering Garden ----------
  Diorama.prototype.world0 = function () {
    var rng = this.rng, self = this;
    this.groundMat = this.ground("#1d3a28").material;
    // gentle hills on the far side
    var hillMat = std({ color: "#25472f", roughness: 1 });
    for (var i = 0; i < 7; i++) {
      var hill = new THREE.Mesh(new THREE.SphereGeometry(1, 24, 12), hillMat);
      var r = 30 + rng.next() * 30;
      hill.scale.set(r, 4 + rng.next() * 6, r * 0.6);
      hill.position.set(-90 + i * 30 + rng.next() * 10, -2, -60 - rng.next() * 40);
      this.group.add(hill);
    }
    this.hillMat = hillMat;
    // trees: round ones and cypresses
    var spots = this.around(Math.round(46 * this.q.extras + 10), 15, 42, 0.75);
    var trunks = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.12, 0.18, 1.4, 6), std({ color: "#3a2c22", roughness: 1 }), spots.length);
    var crowns = new THREE.InstancedMesh(new THREE.IcosahedronGeometry(1, 1), std({ color: "#ffffff", roughness: 1 }), spots.length);
    trunks.castShadow = crowns.castShadow = true;
    var col = new THREE.Color();
    spots.forEach(function (s, i) {
      var cyp = s.z < self.H / 2 - 2 && rng.next() < 0.35, h = 0.8 + rng.next() * 0.7; // no tall cypresses right in front of the camera
      dummy.position.set(s.x, -0.9 + 0.7 * h, s.z); dummy.scale.set(h, h, h); dummy.rotation.set(0, 0, 0); dummy.updateMatrix();
      trunks.setMatrixAt(i, dummy.matrix);
      if (cyp) { dummy.position.set(s.x, -0.9 + 2.4 * h, s.z); dummy.scale.set(0.6 * h, 2.2 * h, 0.6 * h); }
      else { dummy.position.set(s.x, -0.9 + 1.9 * h, s.z); dummy.scale.set(1.2 * h, 1.0 * h, 1.2 * h); }
      dummy.updateMatrix();
      crowns.setMatrixAt(i, dummy.matrix);
      crowns.setColorAt(i, col.set(cyp ? "#1f4a32" : ["#2e6a3c", "#357a45", "#2a5e38"][i % 3]));
    });
    crowns.instanceColor.needsUpdate = true;
    this.group.add(trunks, crowns);
    // flower beds around the board, opening with the light
    var beds = this.around(Math.round(12 * this.q.extras + 4), 12.5, 22, 0.3), fl = [];
    var mound = new THREE.InstancedMesh(new THREE.SphereGeometry(1, 14, 8), std({ color: "#24502e", roughness: 1 }), beds.length);
    beds.forEach(function (bd, i) {
      dummy.position.set(bd.x, -0.9, bd.z); dummy.rotation.set(0, rng.next() * 3, 0); dummy.scale.set(1.5, 0.45, 1.0); dummy.updateMatrix();
      mound.setMatrixAt(i, dummy.matrix);
      for (var k = 0; k < 11; k++) {
        var a = rng.next() * TAU, r = Math.sqrt(rng.next());
        fl.push({ x: bd.x + Math.cos(a) * r * 1.3, z: bd.z + Math.sin(a) * r * 0.85, y: -0.9 + 0.42 * Math.sqrt(1 - r * r) });
      }
    });
    mound.receiveShadow = true;
    this.group.add(mound);
    this.bed = new THREE.InstancedMesh(new THREE.SphereGeometry(0.12, 8, 6), std({ color: "#ffffff", roughness: 0.6, emissive: "#ffffff", emissiveIntensity: 0.15 }), fl.length);
    fl.forEach(function (s, i) { self.bed.setColorAt(i, col.set(["#ffb3d1", "#ffffff", "#c9a8ff", "#ffe08a"][i % 4])); s.th = rng.next(); });
    this.bedSpots = fl;
    this.group.add(this.bed);
    this.fireflies();
  };

  Diorama.prototype.fireflies = function () {
    var n = this.q.fireflies, pos = new Float32Array(n * 3), rng = this.rng;
    this.ff = [];
    for (var i = 0; i < n; i++) {
      var s = { x: (rng.next() - 0.5) * 56, y: 0.2 + rng.next() * 2.4, z: (rng.next() - 0.5) * 44 - 4, p: rng.next() * TAU, th: rng.next() };
      if (Math.abs(s.x) < this.W / 2 + 2 && Math.abs(s.z) < this.H / 2 + 2) { i--; continue; } // keep the board clear
      this.ff.push(s);
    }
    var geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.BufferAttribute(pos, 3));
    this.ffMat = new THREE.PointsMaterial({ color: "#c8f060", size: 0.26, map: K.glowTexture(), transparent: true, opacity: 0.9, blending: THREE.AdditiveBlending, depthWrite: false });
    this.ffPoints = new THREE.Points(geo, this.ffMat);
    this.group.add(this.ffPoints);
  };

  // ---------- the Sleeping City ----------
  Diorama.prototype.world1 = function () {
    var rng = this.rng, self = this;
    this.groundMat = this.ground("#2a2a34", 0.9).material;
    var spots = this.around(Math.round(70 * this.q.extras + 14), 14, 46, 0.8);
    var bodies = new THREE.InstancedMesh(new THREE.BoxGeometry(1, 1, 1), std({ color: "#ffffff", roughness: 0.9 }), spots.length);
    var shape = new THREE.Shape();
    shape.moveTo(-0.6, 0); shape.lineTo(0.6, 0); shape.lineTo(0, 0.55); shape.closePath();
    var roofGeo = new THREE.ExtrudeGeometry(shape, { depth: 1, bevelEnabled: false });
    roofGeo.translate(0, 0, -0.5);
    var roofs = new THREE.InstancedMesh(roofGeo, std({ color: "#ffffff", roughness: 0.8 }), spots.length);
    bodies.castShadow = roofs.castShadow = true;
    bodies.receiveShadow = true;
    var col = new THREE.Color(), wins = [], chims = [];
    spots.forEach(function (s, i) {
      var near = s.z > self.H / 2 - 1;
      var w = 2 + rng.next() * 2, d = 2 + rng.next() * 1.5, h = near ? 1.4 + rng.next() * 1.2 : 2 + rng.next() * 3.5;
      // streets run on a grid: each house turns its face to the board side
      var face = Math.abs(s.x) - self.W / 2 > Math.abs(s.z + 4) - self.H / 2 ? (s.x > 0 ? -Math.PI / 2 : Math.PI / 2) : (s.z + 4 > 0 ? Math.PI : 0);
      dummy.position.set(s.x, -0.9 + h / 2, s.z); dummy.rotation.set(0, face, 0); dummy.scale.set(w, h, d); dummy.updateMatrix();
      bodies.setMatrixAt(i, dummy.matrix);
      bodies.setColorAt(i, col.set(["#b9ab94", "#a99a86", "#9ea4b2", "#c2ae92", "#a4a8b4"][i % 5]));
      dummy.position.set(s.x, -0.9 + h, s.z); dummy.scale.set(w * 0.95, h * 0.25 + 0.6, d); dummy.updateMatrix();
      roofs.setMatrixAt(i, dummy.matrix);
      roofs.setColorAt(i, col.set(["#8e4535", "#7a3d32", "#9a5440", "#5a5260"][i % 4]));
      // windows on the face toward the board
      var rows = Math.floor(h / 1.1), cols2 = Math.floor(w / 0.8);
      for (var r = 0; r < rows; r++) for (var c = 0; c < cols2; c++) {
        if (rng.next() < 0.25) continue;
        var lx = (c + 0.5) / cols2 - 0.5, ly = 0.7 + r * 1.05;
        var fx = Math.sin(face), fz = Math.cos(face);
        wins.push({ x: s.x + Math.cos(face) * lx * w + fx * (d / 2 + 0.02), y: -0.9 + ly, z: s.z - Math.sin(face) * lx * w + fz * (d / 2 + 0.02), ry: face, th: rng.next() });
      }
      if (rng.next() < 0.5) chims.push({ x: s.x + (rng.next() - 0.5) * w * 0.5, y: -0.9 + h + 0.5, z: s.z });
    });
    bodies.instanceColor.needsUpdate = true;
    roofs.instanceColor.needsUpdate = true;
    this.group.add(bodies, roofs);
    this.winMesh = new THREE.InstancedMesh(new THREE.PlaneGeometry(0.34, 0.46), new THREE.MeshBasicMaterial({ color: "#ffffff" }), Math.max(1, wins.length));
    wins.forEach(function (wd, i) {
      dummy.position.set(wd.x, wd.y, wd.z); dummy.rotation.set(0, wd.ry, 0); dummy.scale.set(1, 1, 1); dummy.updateMatrix();
      self.winMesh.setMatrixAt(i, dummy.matrix);
      self.winMesh.setColorAt(i, col.set("#1c2238"));
    });
    this.wins = wins;
    this.group.add(this.winMesh);
    // chimney smoke
    this.smoke = [];
    chims.slice(0, Math.round(14 * this.q.extras)).forEach(function (c, i) {
      for (var p = 0; p < 3; p++) {
        var sm = new THREE.Sprite(new THREE.SpriteMaterial({ map: K.smokeTexture(), transparent: true, opacity: 0, depthWrite: false }));
        self.group.add(sm);
        self.smoke.push({ s: sm, c: c, ph: p / 3 + i * 0.13 });
      }
    });
    // a church spire and a clock tower far behind
    var stone = std({ color: "#5c5f72", roughness: 0.9 });
    var tower = new THREE.Mesh(new THREE.BoxGeometry(3, 16, 3), stone); tower.position.set(-14, 7, -42);
    var spire = new THREE.Mesh(new THREE.ConeGeometry(2.4, 8, 4), std({ color: "#4a4e64", roughness: 0.8 })); spire.position.set(-14, 19, -42); spire.rotation.y = Math.PI / 4;
    var clock = new THREE.Mesh(new THREE.BoxGeometry(3.4, 12, 3.4), stone); clock.position.set(16, 5, -48);
    this.clockFace = new THREE.Mesh(new THREE.CircleGeometry(1.1, 24), new THREE.MeshBasicMaterial({ color: "#3a3424" }));
    this.clockFace.position.set(16, 8.5, -46.25);
    [tower, spire, clock].forEach(function (m) { m.castShadow = true; });
    this.group.add(tower, spire, clock, this.clockFace);
    // street lanterns along the edges of the board
    this.lanterns = [];
    var W = this.W, H = this.H;
    [[-W / 2 - 1.4, -H / 2 + 2], [-W / 2 - 1.4, H / 2 - 3], [W / 2 + 1.4, -H / 2 + 2], [W / 2 + 1.4, H / 2 - 3], [-4, -H / 2 - 1.6], [5, -H / 2 - 1.6]].forEach(function (p, i) {
      var post = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.08, 2.2, 6), std({ color: "#1e2028", roughness: 0.6, metalness: 0.5 }));
      post.position.set(p[0], 0.2, p[1]);
      post.castShadow = true;
      var lampMat = new THREE.MeshBasicMaterial({ color: "#ffd38a" });
      var lamp = new THREE.Mesh(new THREE.BoxGeometry(0.26, 0.32, 0.26), lampMat);
      lamp.position.set(p[0], 1.4, p[1]);
      var gl = K.glowSprite("#ffc878", 2.6, 0);
      gl.position.copy(lamp.position);
      self.group.add(post, lamp, gl);
      self.lanterns.push({ mat: lampMat, glow: gl, th: 0.05 + i * 0.12, x: p[0], y: 1.4, z: p[1], on: 0 });
    });
  };

  // ---------- the Hollow Sky ----------
  Diorama.prototype.world2 = function () {
    var rng = this.rng, self = this;
    // a sea of clouds below the board
    var n = Math.round(150 * this.q.extras + 30);
    this.clouds = new THREE.InstancedMesh(new THREE.IcosahedronGeometry(1, 2), std({ color: "#ffffff", roughness: 1, emissive: "#1a2246", emissiveIntensity: 0.7 }), n);
    var col = new THREE.Color();
    this.cloudData = [];
    for (var i = 0; i < n; i++) {
      var a = rng.next() * TAU, r = 6 + Math.pow(rng.next(), 0.7) * 90;
      var c = { x: Math.cos(a) * r, z: Math.sin(a) * r * 0.8 - 10, y: -4 - rng.next() * 3, s: 3 + rng.next() * 5, v: 0.2 + rng.next() * 0.4 };
      this.cloudData.push(c);
      this.clouds.setColorAt(i, col.set(["#aab6e0", "#c3cdf0", "#9aa6d4"][i % 3]));
    }
    this.clouds.instanceColor.needsUpdate = true;
    this.group.add(this.clouds);
    // constellations, high in the sky, that reappear with the light
    var lines = [], R = 200;
    var figs = [[[-0.5, 0.42], [-0.4, 0.5], [-0.28, 0.46], [-0.18, 0.55], [-0.08, 0.5]], [[0.12, 0.6], [0.2, 0.52], [0.3, 0.58], [0.26, 0.68], [0.12, 0.6]],
      [[0.4, 0.4], [0.5, 0.48], [0.58, 0.42], [0.66, 0.5]], [[-0.7, 0.3], [-0.62, 0.38], [-0.66, 0.46], [-0.56, 0.5]]];
    var starPos = [];
    figs.forEach(function (f) {
      var pts = f.map(function (p) {
        var th = -Math.PI / 2 + p[0] * 1.6, el = p[1];
        return new THREE.Vector3(Math.cos(th) * Math.cos(el) * R, Math.sin(el) * R, Math.sin(th) * Math.cos(el) * R);
      });
      for (var k = 0; k < pts.length - 1; k++) lines.push(pts[k], pts[k + 1]);
      pts.forEach(function (p) { starPos.push(p.x, p.y, p.z); });
    });
    this.consMat = new THREE.LineBasicMaterial({ color: "#cfdcff", transparent: true, opacity: 0, fog: false, depthWrite: false });
    this.group.add(new THREE.LineSegments(new THREE.BufferGeometry().setFromPoints(lines), this.consMat));
    var sg = new THREE.BufferGeometry();
    sg.setAttribute("position", new THREE.BufferAttribute(new Float32Array(starPos), 3));
    this.consStars = new THREE.PointsMaterial({ color: "#ffffff", size: 7, sizeAttenuation: false, map: K.glowTexture(), transparent: true, opacity: 0.4, fog: false, depthWrite: false, blending: THREE.AdditiveBlending });
    this.group.add(new THREE.Points(sg, this.consStars));
    // a few shooting stars
    this.shoot = [];
    for (var s = 0; s < 2; s++) {
      var sp = K.glowSprite("#ffffff", 3, 0);
      this.group.add(sp);
      this.shoot.push({ s: sp, at: s * 4.3 });
    }
  };

  // ---------- the Moon's Path ----------
  Diorama.prototype.world3 = function () {
    var rng = this.rng, self = this;
    // still dark water that mirrors the moonlight
    this.water = new THREE.Mesh(new THREE.PlaneGeometry(400, 400), std({ color: "#34416a", roughness: 0.24, metalness: 0.85, envMap: this.nightEnv(), envMapIntensity: 1.5 }));
    this.water.rotation.x = -Math.PI / 2;
    this.water.position.y = -0.7;
    this.water.receiveShadow = true;
    this.group.add(this.water);
    // the Moon's light laid on the water toward the viewer
    var glade = K.canvasTexture(64, 256, function (x, w, h) {
      // soft ripples of moonlight, narrow far away and wider close by
      var r = K.rng(77);
      for (var i = 0; i < 140; i++) {
        var y = r.next() * h, k = y / h, half = (0.1 + 0.45 * k) * w * (0.3 + r.next() * 0.7);
        var cx = w / 2 + (r.next() - 0.5) * w * 0.25 * k;
        var gr = x.createLinearGradient(cx - half / 2, 0, cx + half / 2, 0);
        var a = (0.06 + 0.22 * r.next()) * (0.4 + 0.6 * k);
        gr.addColorStop(0, "rgba(220,228,255,0)"); gr.addColorStop(0.5, "rgba(220,228,255," + a.toFixed(3) + ")"); gr.addColorStop(1, "rgba(220,228,255,0)");
        x.fillStyle = gr;
        x.fillRect(cx - half / 2, y, half, 0.6 + k * 1.2);
      }
    });
    this.gladeMat = new THREE.MeshBasicMaterial({ map: glade, transparent: true, opacity: 0.4, blending: THREE.AdditiveBlending, depthWrite: false, fog: false });
    var gl = new THREE.Mesh(new THREE.PlaneGeometry(26, 150), this.gladeMat);
    gl.rotation.x = -Math.PI / 2;
    gl.position.set(0, -0.68, -80);
    this.group.add(gl);
    // stepping stones from the board toward the Moon
    this.stones = [];
    var stoneGeo = new THREE.CylinderGeometry(0.7, 0.8, 0.4, 16);
    for (var i = 0; i < 14; i++) {
      var mat = std({ color: "#5a6288", roughness: 0.5, emissive: "#c9d2f4", emissiveIntensity: 0 });
      var st = new THREE.Mesh(stoneGeo, mat);
      var z = -this.H / 2 - 2.5 - i * 3.2;
      st.position.set(Math.sin(i * 0.9) * 1.6, -0.62, z);
      st.scale.setScalar(1 - i * 0.03);
      st.receiveShadow = true;
      this.group.add(st);
      this.stones.push({ m: st, mat: mat, th: i / 14 });
    }
    // a few rocks rising from the water at the sides
    var rocks = new THREE.InstancedMesh(new THREE.DodecahedronGeometry(1, 0), std({ color: "#3a4060", roughness: 0.8 }), 18);
    var spots = this.around(18, 14, 40, 0.6);
    spots.forEach(function (s, i) {
      var sc = 0.6 + rng.next() * 1.6;
      dummy.position.set(s.x, -0.7, s.z); dummy.scale.set(sc, sc * 0.6, sc); dummy.rotation.set(rng.next(), rng.next() * 3, 0); dummy.updateMatrix();
      rocks.setMatrixAt(i, dummy.matrix);
    });
    rocks.castShadow = true;
    this.group.add(rocks);
    // motes of light drifting up
    this.fireflies();
    this.ffMat.color.set("#e4ebff");
  };

  Diorama.prototype.update = function (t, light, dark, reduced) {
    var self = this, col = new THREE.Color(), world = this.world;
    var vis = dark ? 0.35 : 1;
    this.skyMat2.opacity = light * vis;
    this.starMat.opacity = (world === 2 ? 0.5 + 0.5 * light : 0.55 + 0.25 * light) * (dark ? 0.8 : 1);
    var step = Math.round(light * 30) / 30;
    if (step !== this.lastLight) {
      this.lastLight = step;
      var fill = world === 3 ? 0.25 + 0.75 * light : 0.5 + 0.4 * light;
      if (Math.abs(fill - this.moonFill) > 0.04) {
        this.moonFill = fill;
        var old = this.moonTex;
        this.moonTex = K.moonTexture(fill);
        this.moon.material.map = this.moonTex;
        this.moon.material.needsUpdate = true;
        old.dispose();
      }
      if (this.bed) {
        this.bedSpots.forEach(function (s, i) {
          var open = Math.max(0, Math.min(1, (light - s.th * 0.8) / 0.15));
          dummy.position.set(s.x, s.y + 0.04, s.z); dummy.rotation.set(0, 0, 0); dummy.scale.setScalar(0.35 + 0.85 * open); dummy.updateMatrix();
          self.bed.setMatrixAt(i, dummy.matrix);
        });
        this.bed.instanceMatrix.needsUpdate = true;
        this.bed.instanceColor.needsUpdate = true;
        this.hillMat.color.copy(lerpHex("#1e3a4a", "#2c5a36", light));
        this.groundMat.color.copy(lerpHex("#1a3036", "#22472c", light));
      }
      if (this.winMesh) {
        this.wins.forEach(function (w, i) {
          if (light > w.th) self.winMesh.instanceColor.setXYZ(i, 1.5, 1.05, 0.5);
          else self.winMesh.setColorAt(i, col.set("#1c2238"));
        });
        this.winMesh.instanceColor.needsUpdate = true;
        this.clockFace.material.color.copy(lerpHex("#3a3424", "#ffe8b0", light));
      }
      if (this.stones) {
        this.stones.forEach(function (s) { s.mat.emissiveIntensity = Math.max(0, Math.min(1, (light - s.th) / 0.08)) * 0.55; });
        this.gladeMat.opacity = 0.18 + 0.5 * light;
      }
      if (this.consMat) {
        this.consMat.opacity = 0.05 + 0.55 * light;
        this.consStars.opacity = 0.3 + 0.7 * light;
      }
    }
    if (this.ffPoints) {
      var arr = this.ffPoints.geometry.attributes.position.array;
      var on = world === 0 ? 0.2 + 0.8 * light : light;
      for (var i = 0; i < this.ff.length; i++) {
        var f = this.ff[i], show = f.th < on;
        arr[i * 3] = f.x + Math.sin(t * 0.4 + f.p) * 1.2;
        arr[i * 3 + 1] = show ? (world === 3 ? -0.5 + ((f.y + t * 0.3 * (0.5 + f.th)) % 6) : f.y + Math.sin(t * 0.9 + f.p * 2) * 0.4) : -50;
        arr[i * 3 + 2] = f.z + Math.cos(t * 0.3 + f.p) * 1.2;
      }
      this.ffPoints.geometry.attributes.position.needsUpdate = true;
      this.ffMat.opacity = reduced ? 0.75 : 0.65 + 0.25 * Math.sin(t * 2.3);
    }
    if (this.smoke) {
      this.smoke.forEach(function (s) {
        if (light < 0.35 || reduced) { s.s.material.opacity = 0; return; }
        var k = (t * 0.12 + s.ph) % 1;
        s.s.position.set(s.c.x + k * 1.6, s.c.y + k * 3, s.c.z);
        var sc = 0.8 + k * 2.2;
        s.s.scale.set(sc, sc, 1);
        s.s.material.opacity = 0.3 * Math.sin(k * Math.PI);
      });
    }
    if (this.lanterns) {
      this.lanterns.forEach(function (l) {
        var o = Math.max(0, Math.min(1, (light - l.th) / 0.1));
        l.on = o;
        l.mat.color.setRGB(0.2 + 1.2 * o, 0.18 + 0.9 * o, 0.15 + 0.35 * o);
        l.glow.material.opacity = 0.85 * o;
      });
    }
    if (this.clouds) {
      for (var c = 0; c < this.cloudData.length; c++) {
        var cd = this.cloudData[c];
        var x = ((cd.x + t * cd.v + 100) % 200) - 100;
        dummy.position.set(x, cd.y, cd.z); dummy.rotation.set(0, 0, 0); dummy.scale.set(cd.s * 1.4, cd.s * 0.55, cd.s); dummy.updateMatrix();
        this.clouds.setMatrixAt(c, dummy.matrix);
      }
      this.clouds.instanceMatrix.needsUpdate = true;
      this.clouds.material.emissiveIntensity = 0.5 + 0.4 * light;
      this.shoot.forEach(function (s) {
        var k = ((t + s.at) % 9) / 1.2;
        if (k > 1 || light < 0.2 || reduced) { s.s.material.opacity = 0; return; }
        s.s.position.set(-60 + k * 90, 70 - k * 25, -150);
        s.s.material.opacity = Math.sin(k * Math.PI) * light;
      });
    }
  };

  Diorama.prototype.lightCandidates = function (out) {
    (this.lanterns || []).forEach(function (l) {
      if (l.on > 0.05) out.push({ x: l.x, y: l.y, z: l.z, color: "#ffc878", i: 3 * l.on, d: 6, pri: 0.8 });
    });
  };

  Diorama.prototype.dispose = function () {
    if (this.envRT) { this.envRT.dispose(); this.envRT = null; }
    this.group.traverse(function (o) {
      if (o.geometry) o.geometry.dispose();
      if (o.material) {
        if (o.material.map && o.material.map !== K.glowTexture() && o.material.map !== K.smokeTexture()) o.material.map.dispose();
        o.material.dispose();
      }
    });
  };

  LM.Diorama = Diorama;
})(window.LUMEN);
