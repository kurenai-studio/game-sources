window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // A small, honest bot: time-aware breadth-first search toward the star,
  // where a body cell counts as free once the tail will have left it. Used by
  // the title screen demo and by the tests to play real levels.
  function neighbors(game, cell) {
    var b = game.board, out = [];
    var dirs = LM.Game.DIRS;
    for (var i = 0; i < 4; i++) {
      var d = dirs[i];
      var n = b.normalize(cell.x + d.x, cell.y + d.y);
      if (!n) continue;
      var p = b.portalAt(n.x, n.y);
      if (p) {
        n = b.normalize(p.x + d.x, p.y + d.y);
        if (!n) continue;
      }
      out.push({ x: n.x, y: n.y, d: d });
    }
    return out;
  }

  function blockedAt(game, x, y, step) {
    var b = game.board;
    if (b.isWall(x, y)) return true;
    var ph = b.phaseCell(x, y);
    if (ph && (ph.solid || b.ticksToSolid(ph.group, game.tick + step) <= 1)) return true;
    for (var i = 0; i < b.movers.length; i++) {
      var m = b.movers[i];
      if (Math.abs(m.x - x) + Math.abs(m.y - y) <= (step < 3 ? 1 : 0)) return true;
    }
    var cells = game.snake.cells, len = cells.length;
    for (var j = 0; j < len; j++) {
      if (cells[j].x === x && cells[j].y === y && step < len - j) return true;
    }
    return false;
  }

  function floodSize(game, from, limit) {
    var seen = {}, stack = [from], count = 0;
    seen[from.y * 100 + from.x] = true;
    while (stack.length && count < limit) {
      var c = stack.pop();
      count++;
      var ns = neighbors(game, c);
      for (var i = 0; i < ns.length; i++) {
        var k = ns[i].y * 100 + ns[i].x;
        if (seen[k] || blockedAt(game, ns[i].x, ns[i].y, 1)) continue;
        seen[k] = true;
        stack.push(ns[i]);
      }
    }
    return count;
  }

  function choose(game) {
    var head = game.snake.head();
    var dir = game.snake.dir;
    var target = game.golden || (game.item && game.mode === "demo" ? game.item : null) || game.star;
    var len = game.snake.length();

    var first = neighbors(game, head).filter(function (n) {
      return !(n.d.x === -dir.x && n.d.y === -dir.y) && !blockedAt(game, n.x, n.y, 1);
    });
    if (!first.length) return dir;

    if (target) {
      var seen = {}, queue = [];
      first.forEach(function (n) {
        seen[n.y * 100 + n.x] = true;
        queue.push({ x: n.x, y: n.y, step: 1, first: n.d });
      });
      while (queue.length) {
        var c = queue.shift();
        if (c.x === target.x && c.y === target.y) {
          var after = floodSize(game, c, len + 4);
          if (after >= Math.min(len + 4, 12)) return c.first;
          break;
        }
        if (c.step > 60) continue;
        var ns = neighbors(game, c);
        for (var i = 0; i < ns.length; i++) {
          var k = ns[i].y * 100 + ns[i].x;
          if (seen[k] || blockedAt(game, ns[i].x, ns[i].y, c.step + 1)) continue;
          seen[k] = true;
          queue.push({ x: ns[i].x, y: ns[i].y, step: c.step + 1, first: c.first });
        }
      }
    }

    var best = first[0], bestSize = -1;
    for (var f = 0; f < first.length; f++) {
      var size = floodSize(game, first[f], 400);
      if (size > bestSize) { bestSize = size; best = first[f]; }
    }
    return best.d;
  }

  LM.autopilot = { choose: choose };
})(window.LUMEN);
