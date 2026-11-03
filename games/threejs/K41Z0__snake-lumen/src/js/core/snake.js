window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // The snake is a list of cells, head first, plus a short queue of turns so
  // quick double taps (up, then left) are not lost between ticks.
  function Snake(start, length) {
    this.cells = [];
    for (var i = 0; i < length; i++) {
      this.cells.push({ x: start.x - start.dx * i, y: start.y - start.dy * i });
    }
    this.dir = { x: start.dx, y: start.dy };
    this.queue = [];
  }

  Snake.prototype.head = function () {
    return this.cells[0];
  };

  Snake.prototype.length = function () {
    return this.cells.length;
  };

  Snake.prototype.turn = function (x, y, limit) {
    var last = this.queue.length ? this.queue[this.queue.length - 1] : this.dir;
    if (x === last.x && y === last.y) return false;
    if (x === -last.x && y === -last.y) return false;
    if (this.queue.length >= (limit || 2)) return false;
    this.queue.push({ x: x, y: y });
    return true;
  };

  Snake.prototype.applyTurn = function () {
    if (this.queue.length) this.dir = this.queue.shift();
    return this.dir;
  };

  // Index of the body cell at (x, y), or -1. `skipTail` ignores the last cell,
  // which moves out of the way on a tick where the snake does not grow.
  Snake.prototype.indexAt = function (x, y, skipTail) {
    var end = skipTail ? this.cells.length - 1 : this.cells.length;
    for (var i = 0; i < end; i++) {
      if (this.cells[i].x === x && this.cells[i].y === y) return i;
    }
    return -1;
  };

  Snake.prototype.moveTo = function (cell, grow) {
    this.cells.unshift({ x: cell.x, y: cell.y });
    if (!grow) this.cells.pop();
  };

  Snake.prototype.copyCells = function () {
    return this.cells.map(function (c) { return { x: c.x, y: c.y }; });
  };

  LM.Snake = Snake;
})(window.LUMEN);
