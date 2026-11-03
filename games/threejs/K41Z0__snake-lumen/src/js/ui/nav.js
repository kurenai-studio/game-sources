window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // Spatial focus for menus: arrows move to the nearest focusable element in
  // that direction, so every screen works with a keyboard or a gamepad-like pad.
  function items(root) {
    return Array.prototype.filter.call(root.querySelectorAll("[data-nav]"), function (el) {
      if (el.disabled && !el.hasAttribute("data-nav-disabled-ok")) return false;
      var r = el.getBoundingClientRect();
      return r.width > 0 && r.height > 0;
    });
  }

  function center(el) {
    var r = el.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2, r: r };
  }

  function move(root, current, dir) {
    var list = items(root);
    if (!list.length) return null;
    if (!current || list.indexOf(current) === -1) return list[0];
    var c = center(current);
    var best = null, bestScore = Infinity;
    for (var i = 0; i < list.length; i++) {
      var el = list[i];
      if (el === current) continue;
      var p = center(el);
      var dx = p.x - c.x, dy = p.y - c.y;
      var main, cross;
      if (dir === "left") { main = -dx; cross = Math.abs(dy); }
      else if (dir === "right") { main = dx; cross = Math.abs(dy); }
      else if (dir === "up") { main = -dy; cross = Math.abs(dx); }
      else { main = dy; cross = Math.abs(dx); }
      if (main <= 4) continue;
      var score = main + cross * 2.2;
      if (score < bestScore) { bestScore = score; best = el; }
    }
    if (!best && (dir === "down" || dir === "up")) {
      // wrap vertically through a simple list
      var idx = list.indexOf(current);
      var vertical = list.every(function (el) { return Math.abs(center(el).x - c.x) < 40; });
      if (vertical) best = list[(idx + (dir === "down" ? 1 : -1) + list.length) % list.length];
    }
    return best;
  }

  LM.nav = { items: items, move: move };
})(window.LUMEN);
