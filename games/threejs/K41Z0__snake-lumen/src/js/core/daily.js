window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  function pad(n) { return (n < 10 ? "0" : "") + n; }

  // The local calendar date. Everyone on the same date gets the same board.
  function dateKey(date) {
    date = date || new Date();
    return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
  }

  function seedFor(key) {
    return LM.hash("lumen:daily:" + key);
  }

  function blank() {
    var g = [];
    for (var y = 0; y < 20; y++) g.push("....................".split(""));
    return g;
  }

  // Keep the starting lane (rows 9 to 11, from the left edge to the middle) clear.
  function reserved(x, y) {
    return y >= 8 && y <= 12 && x <= 14;
  }

  function put(g, x, y, ch) {
    var pts = [[x, y], [19 - x, y], [x, 19 - y], [19 - x, 19 - y]];
    for (var i = 0; i < pts.length; i++) {
      if (reserved(pts[i][0], pts[i][1])) return false;
    }
    for (i = 0; i < pts.length; i++) g[pts[i][1]][pts[i][0]] = ch;
    return true;
  }

  function connected(g) {
    var seen = {}, total = 0, start = null;
    for (var y = 0; y < 20; y++) {
      for (var x = 0; x < 20; x++) {
        if (g[y][x] !== "#") { total++; if (!start) start = [x, y]; }
      }
    }
    var stack = [start], count = 0;
    seen[start[1] * 20 + start[0]] = true;
    while (stack.length) {
      var c = stack.pop();
      count++;
      var n = [[1, 0], [-1, 0], [0, 1], [0, -1]];
      for (var i = 0; i < 4; i++) {
        var nx = c[0] + n[i][0], ny = c[1] + n[i][1];
        if (nx < 0 || ny < 0 || nx > 19 || ny > 19) continue;
        var k = ny * 20 + nx;
        if (seen[k] || g[ny][nx] === "#") continue;
        seen[k] = true;
        stack.push([nx, ny]);
      }
    }
    return count === total;
  }

  var NAMES = [
    ["Morning Dew", "Hedge Hollow", "Quiet Meadow"],
    ["Midnight Run", "Lamplight Lane", "Sleeping Square"],
    ["Cloud Drift", "Comet Tail", "Starless Reach"],
    ["Silver Tide", "Pale Crossing", "Moonward"]
  ];

  // A level built from the date: theme, layout, mechanics and the seed for
  // every star that will ever fall in it.
  function level(key) {
    key = key || dateKey();
    var seed = seedFor(key);
    var rng = new LM.Rng(seed);
    var world = rng.int(4);
    var g, tries = 0;
    do {
      g = blank();
      var blocks = 3 + rng.int(4);
      for (var b = 0; b < blocks; b++) {
        var w = 1 + rng.int(3), h = 1 + rng.int(2);
        if (rng.chance(0.5)) { var t = w; w = h; h = t; }
        var bx = 1 + rng.int(8), by = 1 + rng.int(8);
        var ch = world === 3 && rng.chance(0.6) ? (rng.chance(0.5) ? "1" : "2") : "#";
        for (var yy = 0; yy < h; yy++) {
          for (var xx = 0; xx < w; xx++) put(g, bx + xx, by + yy, ch);
        }
      }
      tries++;
    } while (!connected(g) && tries < 50);

    var movers = [];
    if (world === 1) {
      var px = 1 + rng.int(6), py = 1 + rng.int(5);
      if (g[py][px] === ".") { g[py][px] = "A"; g[19 - py][19 - px] = "a"; }
    }
    if (world === 1 || world === 2) {
      var lanes = [];
      for (var y = 0; y < 20; y++) {
        if (y >= 8 && y <= 12) continue;
        if (g[y].join("") === "....................") lanes.push(y);
      }
      var count = world === 2 ? 3 : 2;
      for (var m = 0; m < count && lanes.length; m++) {
        var lane = lanes.splice(rng.int(lanes.length), 1)[0];
        movers.push(m % 2 ? [19, lane, 0, lane, 2 + rng.int(2)] : [0, lane, 19, lane, 2 + rng.int(2)]);
      }
    }

    var ni = rng.int(NAMES[world].length);
    return {
      id: "daily", mode: "daily", dateKey: key, seed: seed, world: world,
      name: "Daily " + NAMES[world][ni], daily: [world, ni], dailyName: NAMES[world][ni],
      goal: null, tick: LM.config.daily.tickStart, items: true, wrap: world === 2 || world === 3,
      map: g.map(function (row) { return row.join(""); }), movers: movers
    };
  }

  LM.daily = { dateKey: dateKey, seedFor: seedFor, level: level, connected: connected };
})(window.LUMEN);
