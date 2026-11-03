window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // The board as a little 3D diorama: a slab with the painted floor, and the
  // walls, gates, eclipse stones and movers of the level as real objects
  // that catch light and cast shadows.
  var THREE = window.THREE;
  var K = LM.K3;
  var TAU = Math.PI * 2;
  var GATE = { A: "#cfdcff", B: "#ffd98a", C: "#ffc4b0" };
  var FLOWERS = ["#ffb3d1", "#ffffff", "#c9a8ff", "#ffe08a", "#ffc9a8"];
  var dummy = new THREE.Object3D();

  function std(o) { return new THREE.MeshStandardMaterial(o); }

  function Board3D(game, world, quality) {
    var board = game.board;
    this.board = board;
    this.world = world;
    this.q = quality;
    this.group = new THREE.Group();
    this.cols = board.cols;
    this.rows = board.rows;
    this.rng = K.rng(17 + world * 31 + board.cols);
    this.lamps = [];
    this.chimneys = [];
    this.windows = null;
    this.flowers = null;
    this.smoke = [];
    this.movers = [];
    this.stones = [];
    this.gates = [];
    this.lastLight = -1;
    this.build(game);
  }

  Board3D.prototype.X = function (x) { return x - this.cols / 2 + 0.5; };
  Board3D.prototype.Z = function (y) { return y - this.rows / 2 + 0.5; };

  Board3D.prototype.build = function () {
    var b = this.board, W = this.cols, H = this.rows, world = this.world, g = this.group, self = this;
    var art = LM.BoardView.ART[world].awake;

    // the slab
    var slabCol = ["#2b3a2a", "#3a3438", "#5d6894", "#4a5070"][world];
    var slab = new THREE.Mesh(new THREE.BoxGeometry(W + 0.9, 0.9, H + 0.9), std({ color: slabCol, roughness: world === 2 ? 1 : 0.85 }));
    slab.position.y = -0.475; // top just below the floor, so the two never z-fight
    slab.receiveShadow = true;
    slab.castShadow = false;
    g.add(slab);

    // the painted floor
    var cell = this.q.pixelRatio > 1 ? 48 : 32;
    var tex = K.canvasTexture(W * cell, H * cell, function (x) {
      LM.BoardView.paintFloor(x, b, world, cell, W * cell, H * cell, art, new LM.Rng(40 + world));
      liftAlbedo(x, W * cell, H * cell, world);
    });
    this.floorMat = std({ map: tex, roughness: world === 3 ? 0.55 : 0.92, metalness: world === 3 ? 0.08 : 0 });
    var floor = new THREE.Mesh(new THREE.PlaneGeometry(W, H), this.floorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.receiveShadow = true;
    g.add(floor);

    // the edge: a low curb, or a glowing dashed line where the edges wrap
    if (b.wrap) {
      var pts = [new THREE.Vector3(-W / 2, 0.03, -H / 2), new THREE.Vector3(W / 2, 0.03, -H / 2), new THREE.Vector3(W / 2, 0.03, H / 2),
        new THREE.Vector3(-W / 2, 0.03, H / 2), new THREE.Vector3(-W / 2, 0.03, -H / 2)];
      var line = new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts),
        new THREE.LineDashedMaterial({ color: "#cfdcff", dashSize: 0.35, gapSize: 0.3, transparent: true, opacity: 0.55 }));
      line.computeLineDistances();
      g.add(line);
    } else {
      var curbMat = std({ color: ["#3c4a38", "#4d4650", "#8e9ccc", "#7c84a8"][world], roughness: 0.8 });
      [[0, -H / 2 - 0.12, W + 0.48, 0.24], [0, H / 2 + 0.12, W + 0.48, 0.24]].forEach(function (c) {
        var m = new THREE.Mesh(new THREE.BoxGeometry(c[2], 0.16, c[3]), curbMat); m.position.set(c[0], 0.08, c[1]); m.castShadow = m.receiveShadow = true; g.add(m);
      });
      [[-W / 2 - 0.12, 0, 0.24, H], [W / 2 + 0.12, 0, 0.24, H]].forEach(function (c) {
        var m = new THREE.Mesh(new THREE.BoxGeometry(c[2], 0.16, c[3]), curbMat); m.position.set(c[0], 0.08, c[1]); m.castShadow = m.receiveShadow = true; g.add(m);
      });
    }

    // walls
    var walls = [];
    for (var y = 0; y < H; y++) for (var x = 0; x < W; x++) if (b.isWall(x, y)) walls.push({ x: x, y: y });
    this.walls = walls;
    if (walls.length) this["walls" + world](walls);

    // gates
    b.portalList.forEach(function (p) {
      [p.a, p.b].forEach(function (e) {
        var col = GATE[p.id] || GATE.A;
        var gate = new THREE.Group();
        var ring = new THREE.Mesh(new THREE.TorusGeometry(0.36, 0.075, 10, 32), std({ color: "#b8bccb", roughness: 0.45, metalness: 0.3, emissive: col, emissiveIntensity: 0.6 }));
        ring.rotation.x = -Math.PI / 2;
        ring.position.y = 0.08;
        ring.castShadow = true;
        var disc = new THREE.Mesh(new THREE.CircleGeometry(0.3, 32), new THREE.MeshBasicMaterial({ color: col, transparent: true, opacity: 0.4, blending: THREE.AdditiveBlending, depthWrite: false }));
        disc.rotation.x = -Math.PI / 2;
        disc.position.y = 0.06;
        var glow = K.glowSprite(col, 1.6, 0.5);
        glow.position.y = 0.3;
        gate.add(ring, disc, glow);
        gate.position.set(self.X(e.x), 0, self.Z(e.y));
        g.add(gate);
        self.gates.push({ obj: gate, disc: disc, glow: glow, color: col, x: e.x, y: e.y, ph: self.rng.next() * TAU });
      });
    });

    // eclipse stones
    b.phase.forEach(function (ph) {
      var grp = new THREE.Group();
      var mat = std({ color: "#2b3150", roughness: 0.45, metalness: 0.15, transparent: true, opacity: 1 });
      var body = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.44, 0.72, 28), mat);
      body.position.y = 0.36;
      body.castShadow = body.receiveShadow = true;
      var rimCol = ph.group === 1 ? "#e6ebff" : "#ffd98a";
      var rimMat = std({ color: rimCol, emissive: rimCol, emissiveIntensity: 0.5, roughness: 0.3 });
      var rim = new THREE.Mesh(new THREE.TorusGeometry(0.38, 0.035, 8, 32), rimMat);
      rim.rotation.x = -Math.PI / 2;
      rim.position.y = 0.72;
      grp.add(body, rim);
      grp.position.set(self.X(ph.x), 0, self.Z(ph.y));
      g.add(grp);
      self.stones.push({ ph: ph, grp: grp, body: body, rim: rim, mat: mat, rimMat: rimMat, k: ph.solid ? 1 : 0 });
    });

    // movers
    b.movers.forEach(function (mv, i) {
      var o = self.makeMover(i);
      g.add(o.obj);
      self.movers.push(o);
    });
  };

  function instanced(geo, mat, n, shadows) {
    var m = new THREE.InstancedMesh(geo, mat, Math.max(1, n));
    m.count = n;
    m.castShadow = shadows !== false;
    m.receiveShadow = true;
    return m;
  }

  // The 2D floor art is painted dark (it carries its own night). Under real
  // lights it needs a brighter, less saturated albedo, so the lights decide
  // how dark the night is.
  function liftAlbedo(x, w, h, world) {
    var img = x.getImageData(0, 0, w, h), d = img.data;
    var sat = [0.62, 0.55, 0.5, 0.38][world], gain = [1.15, 1.5, 1.35, 1.3][world], lift = [6, 12, 14, 14][world];
    for (var i = 0; i < d.length; i += 4) {
      var l = d[i] * 0.3 + d[i + 1] * 0.59 + d[i + 2] * 0.11;
      for (var c = 0; c < 3; c++) d[i + c] = Math.min(255, (l + (d[i + c] - l) * sat) * gain + lift);
    }
    x.putImageData(img, 0, 0);
  }

  // the floor wakes from a cool night tint; the garden lawn stays a night lawn
  function world3Tint(world, light) { return world === 0 ? 0.6 + 0.28 * light : 0.62 + 0.38 * light; }

  function wallAt(b, x, y) { return b.inBounds(x, y) && b.isWall(x, y); }

  // exposed faces of a wall cell: the sides that look onto open ground
  Board3D.prototype.faces = function (w) {
    var b = this.board, out = [];
    [[0, -1], [0, 1], [-1, 0], [1, 0]].forEach(function (d) {
      if (!wallAt(b, w.x + d[0], w.y + d[1])) out.push(d);
    });
    return out;
  };

  // Whispering Garden: clipped hedges of leafy clumps, flowers that open
  Board3D.prototype.walls0 = function (walls) {
    var rng = this.rng, self = this;
    var body = instanced(new THREE.BoxGeometry(0.94, 0.62, 0.94), std({ color: "#2f6a3a", roughness: 1 }), walls.length);
    var leafGeo = new THREE.IcosahedronGeometry(0.2, 1);
    var leaves = instanced(leafGeo, std({ color: "#ffffff", roughness: 0.95 }), walls.length * 6);
    var flowers = instanced(new THREE.SphereGeometry(0.075, 10, 8), std({ color: "#ffffff", roughness: 0.6, emissive: "#ffffff", emissiveIntensity: 0.12 }), walls.length * 2, false);
    var greens = ["#3f8a4a", "#4b9a55", "#357a42", "#5aa862"];
    var li = 0, fi = 0, col = new THREE.Color();
    this.flowerData = [];
    walls.forEach(function (w, i) {
      dummy.position.set(self.X(w.x), 0.31, self.Z(w.y));
      dummy.rotation.set(0, 0, 0); dummy.scale.set(1, 1, 1); dummy.updateMatrix();
      body.setMatrixAt(i, dummy.matrix);
      for (var k = 0; k < 6; k++) {
        dummy.position.set(self.X(w.x) + (rng.next() - 0.5) * 0.7, 0.55 + rng.next() * 0.16, self.Z(w.y) + (rng.next() - 0.5) * 0.7);
        var s = 0.9 + rng.next() * 0.6;
        dummy.scale.set(s, s * 0.8, s); dummy.rotation.set(rng.next() * 3, rng.next() * 3, 0); dummy.updateMatrix();
        leaves.setMatrixAt(li, dummy.matrix);
        leaves.setColorAt(li, col.set(greens[Math.floor(rng.next() * greens.length)]));
        li++;
      }
      for (var f = 0; f < 2; f++) {
        var fd = { x: self.X(w.x) + (rng.next() - 0.5) * 0.6, y: 0.78 + rng.next() * 0.06, z: self.Z(w.y) + (rng.next() - 0.5) * 0.6, th: rng.next() * 0.9 };
        self.flowerData.push(fd);
        flowers.setColorAt(fi, col.set(FLOWERS[Math.floor(rng.next() * FLOWERS.length)]));
        fi++;
      }
    });
    leaves.instanceColor.needsUpdate = true;
    this.flowers = flowers;
    this.group.add(body, leaves, flowers);
  };

  // Sleeping City: little houses with tiled roofs, chimneys, windows, lanterns
  Board3D.prototype.walls1 = function (walls) {
    var rng = this.rng, self = this, b = this.board;
    var plaster = ["#c9b79a", "#b7a58e", "#a9b0bf", "#c4a98e", "#9fa8b8"];
    var body = instanced(new THREE.BoxGeometry(0.96, 0.55, 0.96), std({ color: "#ffffff", roughness: 0.9 }), walls.length);
    var shape = new THREE.Shape();
    shape.moveTo(-0.58, -0.02); shape.lineTo(0.58, -0.02); shape.lineTo(0, 0.5); shape.closePath();
    var roofGeo = new THREE.ExtrudeGeometry(shape, { depth: 1.0, bevelEnabled: false });
    roofGeo.translate(0, 0, -0.5);
    var roofs = instanced(roofGeo, std({ color: "#ffffff", roughness: 0.75 }), walls.length);
    var chimneyN = 0, winN = 0, col = new THREE.Color();
    var terracotta = ["#a4503c", "#94473a", "#b45f45", "#8a4a3c"];
    var chims = [], wins = [];
    walls.forEach(function (w, i) {
      var X = self.X(w.x), Z = self.Z(w.y);
      dummy.position.set(X, 0.275, Z); dummy.rotation.set(0, 0, 0); dummy.scale.set(1, 1, 1); dummy.updateMatrix();
      body.setMatrixAt(i, dummy.matrix);
      body.setColorAt(i, col.set(plaster[Math.floor(rng.next() * plaster.length)]));
      var alongX = wallAt(b, w.x - 1, w.y) || wallAt(b, w.x + 1, w.y);
      dummy.position.set(X, 0.55, Z); dummy.rotation.set(0, alongX ? Math.PI / 2 : 0, 0); dummy.updateMatrix();
      roofs.setMatrixAt(i, dummy.matrix);
      roofs.setColorAt(i, col.set(terracotta[Math.floor(rng.next() * terracotta.length)]));
      if (rng.next() < 0.35) chims.push({ x: X + (alongX ? (rng.next() - 0.5) * 0.5 : 0.22), z: Z + (alongX ? 0.2 : (rng.next() - 0.5) * 0.5) });
      self.faces(w).forEach(function (d) {
        wins.push({ x: X + d[0] * 0.485, z: Z + d[1] * 0.485, ry: d[0] ? (d[0] > 0 ? Math.PI / 2 : -Math.PI / 2) : (d[1] > 0 ? 0 : Math.PI), th: rng.next() * 0.95, d: d });
      });
    });
    body.instanceColor.needsUpdate = true;
    roofs.instanceColor.needsUpdate = true;
    this.group.add(body, roofs);
    if (chims.length) {
      var cm = instanced(new THREE.BoxGeometry(0.14, 0.34, 0.14), std({ color: "#6b3a31", roughness: 0.9 }), chims.length);
      chims.forEach(function (c, i) { dummy.position.set(c.x, 0.82, c.z); dummy.rotation.set(0, 0, 0); dummy.updateMatrix(); cm.setMatrixAt(i, dummy.matrix); });
      this.group.add(cm);
      this.chimneys = chims;
      var smokeN = Math.min(chims.length, Math.round(8 * this.q.extras));
      for (var s = 0; s < smokeN; s++) {
        for (var p = 0; p < 3; p++) {
          var sm = new THREE.Sprite(new THREE.SpriteMaterial({ map: K.smokeTexture(), transparent: true, opacity: 0, depthWrite: false }));
          sm.scale.set(0.4, 0.4, 1);
          this.group.add(sm);
          this.smoke.push({ s: sm, c: chims[s], ph: p / 3 + rng.next() * 0.1 });
        }
      }
    }
    if (wins.length) {
      var wm = new THREE.InstancedMesh(new THREE.PlaneGeometry(0.2, 0.22), new THREE.MeshBasicMaterial({ color: "#ffffff" }), wins.length);
      wins.forEach(function (wd, i) {
        dummy.position.set(wd.x, 0.3, wd.z); dummy.rotation.set(0, wd.ry, 0); dummy.updateMatrix();
        wm.setMatrixAt(i, dummy.matrix);
        wm.setColorAt(i, col.set("#2a3048"));
      });
      this.windows = { mesh: wm, data: wins };
      this.group.add(wm);
      // wall lanterns on a few faces
      var picks = wins.filter(function (w2, i) { return i % 5 === 2; }).slice(0, 10);
      picks.forEach(function (wd, i) {
        var lampMat = new THREE.MeshBasicMaterial({ color: "#ffd38a" });
        var lamp = new THREE.Mesh(new THREE.SphereGeometry(0.07, 10, 8), lampMat);
        var ox = wd.d[0] * 0.1, oz = wd.d[1] * 0.1;
        lamp.position.set(wd.x + ox + (wd.d[1] ? 0.25 : 0), 0.62, wd.z + oz + (wd.d[0] ? 0.25 : 0));
        var gl = K.glowSprite("#ffc878", 0.9, 0);
        gl.position.copy(lamp.position);
        self.group.add(lamp, gl);
        self.lamps.push({ lamp: lamp, mat: lampMat, glow: gl, th: 0.1 + i * 0.08, x: lamp.position.x, y: lamp.position.y, z: lamp.position.z, on: 0 });
      });
    }
  };

  // Hollow Sky: banks of cloud
  Board3D.prototype.walls2 = function (walls) {
    var rng = this.rng, self = this;
    var puffs = instanced(new THREE.IcosahedronGeometry(0.4, 2), std({ color: "#ffffff", roughness: 1, emissive: "#28325a", emissiveIntensity: 0.6 }), walls.length * 3);
    var col = new THREE.Color(), k = 0;
    walls.forEach(function (w) {
      for (var p = 0; p < 3; p++) {
        var s = 0.85 + rng.next() * 0.35;
        dummy.position.set(self.X(w.x) + (rng.next() - 0.5) * 0.4, 0.32 + rng.next() * 0.12, self.Z(w.y) + (rng.next() - 0.5) * 0.4);
        dummy.scale.set(s, s * 0.82, s); dummy.rotation.set(0, rng.next() * 3, 0); dummy.updateMatrix();
        puffs.setMatrixAt(k, dummy.matrix);
        puffs.setColorAt(k, col.set(["#dfe6ff", "#cfd8f6", "#e9ecff"][p]));
        k++;
      }
    });
    puffs.instanceColor.needsUpdate = true;
    this.group.add(puffs);
  };

  // The Moon's Path: pillars of moonstone
  Board3D.prototype.walls3 = function (walls) {
    var self = this;
    var pillars = instanced(new THREE.CylinderGeometry(0.4, 0.45, 0.78, 24), std({ color: "#b9c1e0", roughness: 0.35, metalness: 0.15 }), walls.length);
    var caps = instanced(new THREE.CylinderGeometry(0.3, 0.38, 0.08, 24), std({ color: "#e8ecff", roughness: 0.25, emissive: "#9aa6d8", emissiveIntensity: 0.25 }), walls.length);
    walls.forEach(function (w, i) {
      dummy.position.set(self.X(w.x), 0.39, self.Z(w.y)); dummy.rotation.set(0, 0, 0); dummy.scale.set(1, 1, 1); dummy.updateMatrix();
      pillars.setMatrixAt(i, dummy.matrix);
      dummy.position.y = 0.82; dummy.updateMatrix();
      caps.setMatrixAt(i, dummy.matrix);
    });
    this.group.add(pillars, caps);
  };

  Board3D.prototype.makeMover = function (i) {
    var world = this.world, o = new THREE.Group(), out = { obj: o, i: i };
    if (world <= 1) {
      // a little red tram (a lantern cart in the garden) with a headlamp
      var bodyCol = world === 0 ? "#7c5a3a" : "#a8402f";
      var body = new THREE.Mesh(new THREE.BoxGeometry(0.92, 0.42, 0.6), std({ color: bodyCol, roughness: 0.6 }));
      body.position.y = 0.3;
      var roof = new THREE.Mesh(new THREE.BoxGeometry(0.84, 0.08, 0.52), std({ color: "#eadbb8", roughness: 0.7 }));
      roof.position.y = 0.55;
      var winMat = new THREE.MeshBasicMaterial({ color: "#ffd98a" });
      var w1 = new THREE.Mesh(new THREE.BoxGeometry(0.66, 0.13, 0.62), winMat);
      w1.position.y = 0.36;
      var lamp = new THREE.Mesh(new THREE.SphereGeometry(0.07, 10, 8), new THREE.MeshBasicMaterial({ color: "#fff6d8" }));
      lamp.position.set(0.48, 0.26, 0);
      var pole = new THREE.Mesh(new THREE.BoxGeometry(0.03, 0.22, 0.03), std({ color: "#3a2a20" }));
      pole.position.set(-0.1, 0.68, 0); pole.rotation.z = 0.5;
      var gl = K.glowSprite("#ffe2a0", 1.4, 0.75);
      gl.position.set(0.62, 0.28, 0);
      [body, roof].forEach(function (m) { m.castShadow = true; m.receiveShadow = true; });
      o.add(body, roof, w1, lamp, pole, gl);
      out.lamp = lamp;
    } else if (world === 2) {
      var mat = std({ color: "#6a7398", roughness: 1, emissive: "#20264a", emissiveIntensity: 0.5 });
      [[-0.18, 0.3, 0.05, 0.27], [0.17, 0.32, -0.04, 0.29], [0, 0.42, 0, 0.3]].forEach(function (p) {
        var m = new THREE.Mesh(new THREE.IcosahedronGeometry(p[3], 2), mat);
        m.position.set(p[0], p[1], p[2]); m.castShadow = true;
        o.add(m);
      });
    } else {
      var sh = new THREE.Mesh(new THREE.SphereGeometry(0.38, 20, 16), std({ color: "#1a1630", roughness: 0.8, emissive: "#140f2a", emissiveIntensity: 0.6 }));
      sh.scale.set(1, 0.9, 1);
      sh.position.y = 0.4;
      sh.castShadow = true;
      var eyeMat = new THREE.MeshBasicMaterial({ color: "#f3e6c0" });
      var e1 = new THREE.Mesh(new THREE.SphereGeometry(0.06, 8, 6), eyeMat), e2 = e1.clone();
      e1.position.set(0.3, 0.48, 0.12); e2.position.set(0.3, 0.48, -0.12);
      o.add(sh, e1, e2);
      out.wisp = sh;
    }
    return out;
  };

  function heading(mv) {
    var tgt = mv.forward ? mv.to : mv.from;
    var hx = Math.sign(tgt.x - mv.x), hy = Math.sign(tgt.y - mv.y);
    if (!hx && !hy) { hx = Math.sign(mv.from.x - mv.to.x); hy = Math.sign(mv.from.y - mv.to.y); }
    return [hx, hy];
  }

  // per frame: restoration, animation, movers
  Board3D.prototype.update = function (game, t, light, alpha, dark, reduced) {
    var self = this, b = this.board, col = new THREE.Color();
    // the floor wakes from a cool night tint
    var tint = world3Tint(this.world, light);
    this.floorMat.color.setRGB(tint, tint, tint);
    var lightStep = Math.round(light * 40) / 40;
    if (lightStep !== this.lastLight) {
      this.lastLight = lightStep;
      if (this.flowers) {
        this.flowerData.forEach(function (fd, i) {
          var open = Math.max(0, Math.min(1, (light - fd.th * 0.8) / 0.15));
          var s = 0.25 + 0.75 * open;
          dummy.position.set(fd.x, fd.y, fd.z); dummy.rotation.set(0, 0, 0); dummy.scale.set(s, s * (0.6 + 0.4 * open), s); dummy.updateMatrix();
          self.flowers.setMatrixAt(i, dummy.matrix);
        });
        this.flowers.instanceMatrix.needsUpdate = true;
        if (this.flowers.instanceColor) this.flowers.instanceColor.needsUpdate = true;
      }
      if (this.windows) {
        var wm = this.windows.mesh;
        this.windows.data.forEach(function (wd, i) {
          var on = light > wd.th;
          wm.setColorAt(i, col.set(on ? "#ffcf7a" : "#283048"));
          if (on) wm.instanceColor.setXYZ(i, 1.6, 1.15, 0.55);
        });
        wm.instanceColor.needsUpdate = true;
      }
    }
    this.lamps.forEach(function (l) {
      var on = Math.max(0, Math.min(1, (light - l.th) / 0.1));
      l.on = on;
      l.mat.color.setRGB(0.25 + 0.75 * on * 1.4, 0.22 + 0.6 * on * 1.2, 0.2 + 0.25 * on);
      l.glow.material.opacity = on * 0.8;
    });
    this.smoke.forEach(function (s) {
      if (light < 0.35 || reduced) { s.s.material.opacity = 0; return; }
      var k = (t * 0.25 + s.ph) % 1;
      s.s.position.set(s.c.x + Math.sin(t + s.ph * 6) * 0.08 + k * 0.2, 1.0 + k * 1.1, s.c.z);
      var sc = 0.25 + k * 0.6;
      s.s.scale.set(sc, sc, 1);
      s.s.material.opacity = 0.35 * Math.sin(k * Math.PI) * Math.min(1, (light - 0.35) / 0.2);
    });
    this.gates.forEach(function (gt) {
      var p = reduced ? 0.8 : 0.7 + 0.3 * Math.sin(t * 2.4 + gt.ph);
      gt.disc.material.opacity = 0.28 + 0.2 * p;
      gt.glow.material.opacity = 0.35 + 0.25 * p;
      gt.disc.rotation.z = t * 0.6;
    });
    this.stones.forEach(function (st) {
      var ph = st.ph, target = ph.solid ? 1 : 0;
      st.k += (target - st.k) * 0.18;
      var sy = 0.06 + 0.94 * st.k;
      st.body.scale.y = sy;
      st.body.position.y = 0.36 * sy;
      st.rim.position.y = 0.72 * sy + 0.01;
      st.mat.opacity = 0.3 + 0.7 * st.k;
      st.body.castShadow = st.k > 0.5;
      var warn = !ph.solid && LM.Board.prototype.ticksToSolid.call(b, ph.group, game.tick) <= LM.config.phaseWarnTicks && !ph.held;
      st.rimMat.emissiveIntensity = warn ? (reduced ? 1.2 : 0.8 + 0.9 * (0.5 + 0.5 * Math.sin(t * 14))) : (ph.solid ? 0.55 : 0.25);
    });
    this.movers.forEach(function (m) {
      var mv = b.movers[m.i];
      var x = mv.px + (mv.x - mv.px) * alpha, y = mv.py + (mv.y - mv.py) * alpha;
      m.obj.position.set(self.X(x), 0, self.Z(y));
      var hd = heading(mv);
      m.obj.rotation.y = -Math.atan2(hd[1], hd[0]);
      if (m.wisp) m.obj.position.y = 0.05 * Math.sin(t * 3 + m.i);
      m.hx = hd[0]; m.hy = hd[1]; m.x = x; m.y = y;
    });
  };

  // lights the board offers to the light pool
  Board3D.prototype.lightCandidates = function (out, light, dark) {
    var self = this;
    this.gates.forEach(function (gt) {
      out.push({ x: self.X(gt.x), y: 0.6, z: self.Z(gt.y), color: gt.color, i: dark ? 1.6 : 1.0, d: dark ? 3.5 : 2.6, pri: 2, bx: gt.x, by: gt.y });
    });
    this.movers.forEach(function (m) {
      if (self.world > 1 || m.x === undefined) return;
      out.push({ x: self.X(m.x + m.hx * 0.7), y: 0.45, z: self.Z(m.y + m.hy * 0.7), color: "#ffd9a0", i: dark ? 2.2 : 1.4, d: dark ? 4 : 3, pri: 2.2, bx: m.x, by: m.y });
    });
    this.lamps.forEach(function (l) {
      if (l.on <= 0.05) return;
      out.push({ x: l.x, y: l.y + 0.1, z: l.z, color: "#ffc878", i: 1.1 * l.on, d: 2.6, pri: 1, bx: l.x + self.cols / 2 - 0.5, by: l.z + self.rows / 2 - 0.5 });
    });
  };

  Board3D.prototype.dispose = function () {
    this.group.traverse(function (o) {
      if (o.geometry && o.geometry !== K.starGeometry()) o.geometry.dispose();
      if (o.material) {
        (Array.isArray(o.material) ? o.material : [o.material]).forEach(function (m) {
          if (m.map && m.map !== K.glowTexture() && m.map !== K.smokeTexture()) m.map.dispose();
          m.dispose();
        });
      }
    });
  };

  LM.Board3D = Board3D;
})(window.LUMEN);
