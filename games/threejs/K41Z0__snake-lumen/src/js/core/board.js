window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // The static and moving furniture of one level: walls, portals, glitch (phase)
  // blocks and movers. Built from an ASCII map:
  //   .  floor     #  wall
  //   A/a B/b C/c  portal pairs
  //   1  phase block, off first     2  phase block, on first
  function Board(level) {
    var map = level.map;
    this.rows = map.length;
    this.cols = map[0].length;
    this.wrap = !!level.wrap;
    this.walls = new Uint8Array(this.cols * this.rows);
    this.portals = {};
    this.portalList = [];
    this.phase = [];
    this.phaseAt = {};
    this.phasePeriod = level.phasePeriod || LM.config.phasePeriod;

    var pending = {};
    for (var y = 0; y < this.rows; y++) {
      for (var x = 0; x < this.cols; x++) {
        var ch = map[y].charAt(x);
        if (ch === "#") this.walls[this.key(x, y)] = 1;
        else if (ch === "1" || ch === "2") {
          var cell = { x: x, y: y, group: ch === "1" ? 1 : 2, solid: false, held: false };
          this.phase.push(cell);
          this.phaseAt[this.key(x, y)] = cell;
        } else if (/[A-Za-z]/.test(ch)) {
          var id = ch.toUpperCase();
          var end = { x: x, y: y, id: id };
          if (pending[id]) {
            var a = pending[id];
            this.portals[this.key(a.x, a.y)] = { x: x, y: y, id: id };
            this.portals[this.key(x, y)] = { x: a.x, y: a.y, id: id };
            this.portalList.push({ id: id, a: a, b: end });
            delete pending[id];
          } else {
            pending[id] = end;
          }
        }
      }
    }

    this.movers = (level.movers || []).map(function (m) {
      return { x: m[0], y: m[1], px: m[0], py: m[1], from: { x: m[0], y: m[1] }, to: { x: m[2], y: m[3] },
        every: m[4] || 2, wait: 0, forward: true };
    });
    // every cell a mover can visit: stars and power-ups never land there
    this.lanes = new Uint8Array(this.cols * this.rows);
    for (var i = 0; i < this.movers.length; i++) {
      var mv = this.movers[i], lx = mv.from.x, ly = mv.from.y;
      for (var guard = 0; guard < 64; guard++) {
        if (this.inBounds(lx, ly)) this.lanes[this.key(lx, ly)] = 1;
        if (lx === mv.to.x && ly === mv.to.y) break;
        lx += Math.sign(mv.to.x - lx);
        ly += Math.sign(mv.to.y - ly);
      }
    }
    this.updatePhase(0, null);
  }

  Board.prototype.isLane = function (x, y) {
    return this.lanes[this.key(x, y)] === 1;
  };

  Board.prototype.key = function (x, y) {
    return y * this.cols + x;
  };

  Board.prototype.inBounds = function (x, y) {
    return x >= 0 && y >= 0 && x < this.cols && y < this.rows;
  };

  Board.prototype.isWall = function (x, y) {
    return this.walls[this.key(x, y)] === 1;
  };

  Board.prototype.portalAt = function (x, y) {
    return this.portals[this.key(x, y)] || null;
  };

  Board.prototype.phaseCell = function (x, y) {
    return this.phaseAt[this.key(x, y)] || null;
  };

  Board.prototype.moverAt = function (x, y) {
    for (var i = 0; i < this.movers.length; i++) {
      if (this.movers[i].x === x && this.movers[i].y === y) return this.movers[i];
    }
    return null;
  };

  // Step off the board: wrap around if the level allows it, otherwise null.
  Board.prototype.normalize = function (x, y) {
    if (this.inBounds(x, y)) return { x: x, y: y };
    if (!this.wrap) return null;
    return { x: (x + this.cols) % this.cols, y: (y + this.rows) % this.rows };
  };

  Board.prototype.groupSolidAt = function (group, tick) {
    var half = this.phasePeriod / 2;
    var on = (tick % this.phasePeriod) >= half;
    return group === 1 ? on : !on;
  };

  // Ticks until a phase group next switches on (0 if it is on now).
  Board.prototype.ticksToSolid = function (group, tick) {
    for (var i = 0; i <= this.phasePeriod; i++) {
      if (this.groupSolidAt(group, tick + i)) return i;
    }
    return this.phasePeriod;
  };

  // A block that would switch on under the snake waits for the next cycle: no unfair deaths.
  Board.prototype.updatePhase = function (tick, occupied) {
    for (var i = 0; i < this.phase.length; i++) {
      var cell = this.phase[i];
      var want = this.groupSolidAt(cell.group, tick);
      if (!want) {
        cell.solid = false;
        cell.held = false;
      } else if (!cell.solid && !cell.held) {
        if (occupied && occupied(cell.x, cell.y)) cell.held = true;
        else cell.solid = true;
      }
    }
  };

  Board.prototype.isPhaseSolid = function (x, y) {
    var cell = this.phaseCell(x, y);
    return !!(cell && cell.solid);
  };

  // Movers are polite: they wait rather than push into the snake or an item.
  Board.prototype.stepMovers = function (tick, occupied) {
    for (var i = 0; i < this.movers.length; i++) {
      var m = this.movers[i];
      m.px = m.x;
      m.py = m.y;
      if (tick % m.every !== 0) continue;
      var target = m.forward ? m.to : m.from;
      if (m.x === target.x && m.y === target.y) {
        m.forward = !m.forward;
        target = m.forward ? m.to : m.from;
      }
      var nx = m.x + Math.sign(target.x - m.x);
      var ny = m.y + Math.sign(target.y - m.y);
      if (occupied(nx, ny) || this.moverAt(nx, ny)) continue;
      m.x = nx;
      m.y = ny;
    }
  };

  Board.prototype.isStaticFree = function (x, y) {
    return !this.isWall(x, y) && !this.portalAt(x, y) && !this.phaseCell(x, y);
  };

  LM.Board = Board;
})(window.LUMEN);
