window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var C = LM.config;
  var DIRS = [{ x: 1, y: 0 }, { x: -1, y: 0 }, { x: 0, y: 1 }, { x: 0, y: -1 }];

  // One run of the game: a level, a snake, stars, power-ups, a score and an
  // event queue. Pure rules: no DOM, no canvas, no clock of its own. The caller
  // feeds it elapsed milliseconds with update(), so it runs the same in node.
  function Game(opts) {
    opts = opts || {};
    this.level = opts.level || LM.levels.byId(1);
    this.mode = opts.mode || "campaign";
    this.seed = opts.seed === undefined ? LM.randomSeed() : opts.seed;
    this.rng = new LM.Rng(this.seed);
    this.board = new LM.Board(this.level);
    var start = this.level.start || C.start;
    this.snake = new LM.Snake(start, C.startLength);
    this.prevCells = this.snake.copyCells();
    this.status = "ready";
    this.events = [];

    this.score = 0;
    this.eaten = 0;
    this.combo = 0;
    this.comboLeftMs = 0;
    this.tick = 0;
    this.elapsedMs = 0;
    this.acc = 0;
    this.alpha = 0;
    this.effects = { slow: 0, ghost: 0, magnet: 0, double: 0 };
    this.golden = null;
    this.item = null;
    this.lastHit = null;
    this.worldIndex = this.level.world || 0;

    this.stats = {
      eaten: 0, golden: 0, maxCombo: 0, maxLength: this.snake.length(), powerups: 0,
      powerupTypes: {}, ghostPasses: 0, pauses: 0, magnetEats: 0, magnetBest: 0, crash: null, portals: 0
    };

    this.star = this.spawnCell(true);
    this.starPrev = { x: this.star.x, y: this.star.y };
  }

  Game.prototype.push = function (event) {
    this.events.push(event);
  };

  Game.prototype.takeEvents = function () {
    var list = this.events;
    this.events = [];
    return list;
  };

  Game.prototype.start = function () {
    if (this.status !== "ready") return;
    this.status = "running";
    this.push({ type: "start" });
  };

  Game.prototype.pause = function () {
    if (this.status !== "running") return false;
    this.status = "paused";
    this.stats.pauses += 1;
    this.push({ type: "pause" });
    return true;
  };

  Game.prototype.resume = function () {
    if (this.status !== "paused") return false;
    this.status = "running";
    this.push({ type: "resume" });
    return true;
  };

  Game.prototype.turn = function (x, y) {
    if (this.status !== "running" && this.status !== "ready") return false;
    var ok = this.snake.turn(x, y, C.turnQueue);
    if (ok) this.push({ type: "turn" });
    return ok;
  };

  Game.prototype.baseTickMs = function () {
    var start = this.level.tick || 150;
    return Math.max(C.minTickMs, start - this.eaten * C.accelPerStar);
  };

  Game.prototype.tickMs = function () {
    return this.baseTickMs() * (this.effects.slow > 0 ? C.slowFactor : 1);
  };

  Game.prototype.multiplier = function () {
    var m = 1 + Math.max(0, this.combo - 1) * C.comboStep;
    return this.effects.double > 0 ? m * 2 : m;
  };

  // ---------- occupancy ----------

  Game.prototype.snakeAt = function (x, y) {
    return this.snake.indexAt(x, y, false) !== -1;
  };

  Game.prototype.itemAt = function (x, y) {
    if (this.star && this.star.x === x && this.star.y === y) return true;
    if (this.golden && this.golden.x === x && this.golden.y === y) return true;
    if (this.item && this.item.x === x && this.item.y === y) return true;
    return false;
  };

  Game.prototype.isFreeCell = function (x, y) {
    var b = this.board;
    if (!b.inBounds(x, y) || !b.isStaticFree(x, y) || b.isLane(x, y)) return false;
    if (b.moverAt(x, y) || this.snakeAt(x, y) || this.itemAt(x, y)) return false;
    return true;
  };

  // Pick a free cell. The very first star sits a few cells ahead of the snake
  // when that is possible, so the opening bite needs no chase.
  Game.prototype.spawnCell = function (first) {
    var b = this.board;
    if (first) {
      var h = this.snake.head();
      var d = this.snake.dir;
      var fx = h.x + d.x * 6, fy = h.y + d.y * 6;
      if (b.inBounds(fx, fy) && this.isFreeCell(fx, fy)) {
        var clear = true;
        for (var s = 1; s < 6; s++) {
          if (!this.isFreeCell(h.x + d.x * s, h.y + d.y * s)) clear = false;
        }
        if (clear) return { x: fx, y: fy };
      }
    }
    var free = [];
    var head = this.snake.head();
    for (var y = 0; y < b.rows; y++) {
      for (var x = 0; x < b.cols; x++) {
        if (!this.isFreeCell(x, y)) continue;
        if (Math.abs(x - head.x) + Math.abs(y - head.y) < 2) continue;
        free.push({ x: x, y: y });
      }
    }
    if (!free.length) return null;
    return free[this.rng.int(free.length)];
  };

  // ---------- the clock ----------

  Game.prototype.update = function (dtMs) {
    if (this.status !== "running") return;
    dtMs = Math.min(dtMs, 250);
    this.elapsedMs += dtMs;

    for (var k in this.effects) {
      if (this.effects[k] > 0) {
        this.effects[k] -= dtMs;
        if (this.effects[k] <= 0) {
          this.effects[k] = 0;
          if (k === "magnet") this.stats.magnetBest = Math.max(this.stats.magnetBest, this.stats.magnetEats);
          this.push({ type: "effectEnd", effect: k });
        }
      }
    }
    if (this.comboLeftMs > 0) {
      this.comboLeftMs -= dtMs;
      if (this.comboLeftMs <= 0 && this.combo > 1) this.push({ type: "comboEnd", combo: this.combo });
      if (this.comboLeftMs <= 0) this.combo = 0;
    }
    if (this.golden) {
      this.golden.ttl -= dtMs;
      if (this.golden.ttl <= 0) {
        this.push({ type: "expire", what: "golden", cell: { x: this.golden.x, y: this.golden.y } });
        this.golden = null;
      }
    }
    if (this.item) {
      this.item.ttl -= dtMs;
      if (this.item.ttl <= 0) {
        this.push({ type: "expire", what: "item", cell: { x: this.item.x, y: this.item.y } });
        this.item = null;
      }
    }

    this.acc += dtMs;
    var guard = 0;
    while (this.status === "running" && this.acc >= this.tickMs() && guard < 8) {
      this.acc -= this.tickMs();
      this.step();
      guard += 1;
    }
    if (guard >= 8) this.acc = 0;
    this.checkGoal();
    this.alpha = this.status === "running" ? Math.min(1, this.acc / this.tickMs()) : 1;
  };

  // ---------- one tick ----------

  Game.prototype.step = function () {
    var b = this.board;
    var snake = this.snake;
    this.prevCells = snake.copyCells();
    this.starPrev = this.star ? { x: this.star.x, y: this.star.y } : null;
    this.tick += 1;

    var dir = snake.applyTurn();
    var head = snake.head();
    var next = b.normalize(head.x + dir.x, head.y + dir.y);
    if (!next) return this.crash("wall", { x: head.x + dir.x, y: head.y + dir.y });

    var portal = b.portalAt(next.x, next.y);
    if (portal) {
      var out = b.normalize(portal.x + dir.x, portal.y + dir.y);
      this.push({ type: "portal", from: next, to: { x: portal.x, y: portal.y } });
      this.stats.portals += 1;
      if (!out) return this.crash("wall", next);
      next = out;
    }

    if (b.isWall(next.x, next.y)) return this.crash("wall", next);
    if (b.isPhaseSolid(next.x, next.y)) return this.crash("glitch", next);
    if (b.moverAt(next.x, next.y)) return this.crash("mover", next);

    var eatsStar = this.star && this.star.x === next.x && this.star.y === next.y;
    var eatsGolden = this.golden && this.golden.x === next.x && this.golden.y === next.y;
    var grow = eatsStar || eatsGolden;
    var hit = snake.indexAt(next.x, next.y, !grow);
    if (hit !== -1) {
      if (this.effects.ghost > 0) {
        this.stats.ghostPasses += 1;
        this.push({ type: "ghostPass", cell: next });
      } else {
        return this.crash("self", next);
      }
    }

    snake.moveTo(next, grow);
    this.stats.maxLength = Math.max(this.stats.maxLength, snake.length());
    this.push({ type: "move" });

    if (eatsStar) this.eat(next, false);
    if (eatsGolden) this.eat(next, true);

    if (this.item && this.item.x === next.x && this.item.y === next.y) {
      var type = this.item.type;
      this.item = null;
      this.effects[type] = C.effectMs[type];
      if (type === "magnet") this.stats.magnetEats = 0;
      this.stats.powerups += 1;
      this.stats.powerupTypes[type] = true;
      this.push({ type: "powerup", effect: type, cell: next });
    }

    var self = this;
    b.stepMovers(this.tick, function (x, y) {
      return self.snakeAt(x, y) || self.itemAt(x, y) || !b.inBounds(x, y) || b.isWall(x, y);
    });
    b.updatePhase(this.tick, function (x, y) {
      return self.snakeAt(x, y) || self.itemAt(x, y);
    });

    if (this.effects.magnet > 0) this.pullStar();
  };

  Game.prototype.eat = function (cell, golden) {
    this.combo = this.comboLeftMs > 0 ? this.combo + 1 : 1;
    this.comboLeftMs = C.comboWindowMs;
    this.stats.maxCombo = Math.max(this.stats.maxCombo, this.combo);
    var points = Math.round((golden ? C.pointsGolden : C.pointsPerStar) * this.multiplier());
    this.score += points;
    this.eaten += 1;
    this.stats.eaten += 1;
    if (this.effects.magnet > 0) {
      this.stats.magnetEats += 1;
      this.stats.magnetBest = Math.max(this.stats.magnetBest, this.stats.magnetEats);
    }
    if (golden) {
      this.stats.golden += 1;
      this.golden = null;
    } else {
      this.star = this.spawnCell(false);
      this.starPrev = this.star ? { x: this.star.x, y: this.star.y } : null;
    }
    this.push({ type: "eat", cell: cell, golden: golden, points: points, combo: this.combo,
      wallet: golden ? C.goldenWallet : 1 });

    if (this.mode === "endless") {
      var w = Math.floor(this.eaten / C.endless.worldEvery) % 4;
      if (w !== this.worldIndex) {
        this.worldIndex = w;
        this.push({ type: "worldShift", world: w });
      }
    }
    if (!golden) this.maybeSpawnExtras();
  };

  Game.prototype.maybeSpawnExtras = function () {
    if (!this.golden && this.eaten >= 4 && this.rng.chance(C.goldenChance)) {
      var g = this.spawnCell(false);
      if (g) {
        this.golden = { x: g.x, y: g.y, ttl: C.goldenTtlMs, max: C.goldenTtlMs };
        this.push({ type: "spawn", what: "golden", cell: g });
      }
    }
    if (this.level.items && !this.item && this.eaten >= C.itemFirstAfter && this.rng.chance(C.itemChance)) {
      var c = this.spawnCell(false);
      if (c) {
        var type = this.rng.pick(["slow", "ghost", "magnet", "double"]);
        this.item = { x: c.x, y: c.y, type: type, ttl: C.itemTtlMs, max: C.itemTtlMs };
        this.push({ type: "spawn", what: "item", effect: type, cell: c });
      }
    }
  };

  // The magnet drags the star one cell per tick toward the head.
  Game.prototype.pullStar = function () {
    if (!this.star) return;
    var h = this.snake.head();
    var dx = h.x - this.star.x, dy = h.y - this.star.y;
    var dist = Math.abs(dx) + Math.abs(dy);
    if (dist <= 1 || dist > C.magnetRange) return;
    var options = [];
    if (dx) options.push({ x: this.star.x + Math.sign(dx), y: this.star.y });
    if (dy) options.push({ x: this.star.x, y: this.star.y + Math.sign(dy) });
    if (Math.abs(dy) > Math.abs(dx)) options.reverse();
    var saved = this.star;
    this.star = null;
    for (var i = 0; i < options.length; i++) {
      if (this.isFreeCell(options[i].x, options[i].y)) {
        this.star = options[i];
        this.push({ type: "magnetPull" });
        return;
      }
    }
    this.star = saved;
  };

  Game.prototype.crash = function (reason, cell) {
    this.status = "over";
    this.stats.crash = reason;
    this.lastHit = cell;
    this.stats.magnetBest = Math.max(this.stats.magnetBest, this.stats.magnetEats);
    this.push({ type: "crash", reason: reason, cell: cell });
    this.push({ type: "over", won: false });
  };

  Game.prototype.goalMet = function () {
    var g = this.level.goal;
    if (!g) return false;
    if (g.type === "eat") return this.eaten >= g.n;
    if (g.type === "length") return this.snake.length() >= g.n;
    if (g.type === "survive") return this.elapsedMs >= g.n * 1000;
    return this.score >= g.n;
  };

  Game.prototype.checkGoal = function () {
    if (this.status !== "running" || !this.goalMet()) return;
    this.status = "won";
    this.push({ type: "over", won: true });
  };

  Game.prototype.result = function () {
    return {
      mode: this.mode, levelId: this.level.id, won: this.status === "won", score: this.score,
      eaten: this.eaten, length: this.snake.length(), elapsedMs: this.elapsedMs, stats: this.stats,
      seed: this.seed
    };
  };

  Game.DIRS = DIRS;
  LM.Game = Game;
})(window.LUMEN);
