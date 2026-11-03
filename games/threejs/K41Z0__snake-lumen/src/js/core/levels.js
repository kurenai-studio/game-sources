window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var EMPTY = "....................";

  // A 20x20 map from the rows that are not empty. Keys are row numbers.
  function map(rows) {
    var out = [];
    for (var y = 0; y < 20; y++) out.push(rows[y] || EMPTY);
    return out;
  }

  function same(row, list) {
    var out = {};
    list.forEach(function (y) { out[y] = row; });
    return out;
  }

  function join() {
    var out = {};
    for (var i = 0; i < arguments.length; i++) {
      for (var k in arguments[i]) out[k] = arguments[i][k];
    }
    return out;
  }

  // goal: catch N stars | reach length N | survive N seconds | score N light.
  // par: seconds for three moons (survive: stars caught while surviving).
  var LEVELS = [
    // ---------- Whispering Garden: hedges only, a gentle ramp ----------
    { world: 0, name: "First Sprout", goal: { type: "eat", n: 8 }, par: 30, tick: 160, items: false,
      map: map({}) },
    { world: 0, name: "Hedge Squares", goal: { type: "eat", n: 12 }, par: 40, tick: 155,
      map: map(same("....##........##....", [4, 5, 14, 15])) },
    { world: 0, name: "Rose Rows", goal: { type: "length", n: 18 }, par: 55, tick: 150,
      map: map(join(same("..######....######..", [3, 16]), same("....############....", [7, 13]))) },
    { world: 0, name: "Lily Pond", goal: { type: "survive", n: 45 }, par: 16, tick: 150,
      map: map({ 4: ".......######.......", 5: "......########......", 6: "......########......",
        7: ".......######.......", 13: "...#..........#.....", 16: "........#..#........" }) },
    { world: 0, name: "Topiary", goal: { type: "score", n: 300 }, par: 50, tick: 145,
      map: map(join(same(".....#........#.....", [4, 6, 13, 15]), same("....###......###....", [5, 14]),
        same("###..............###", [0, 19]), same("#..................#", [1, 18]))) },

    // ---------- Sleeping City: gates and night trams ----------
    { world: 1, name: "Quiet Streets", goal: { type: "eat", n: 12 }, par: 40, tick: 145,
      map: map({ 2: "..A..............B..", 17: "..b..............a..", 5: ".....###....###.....",
        14: ".....###....###....." }) },
    { world: 1, name: "Night Trams", goal: { type: "eat", n: 14 }, par: 50, tick: 140,
      map: map({ 1: ".........A..........", 18: ".........a..........", 7: "######........######",
        13: "######........######" }),
      movers: [[0, 4, 19, 4, 2], [19, 15, 0, 15, 2]] },
    { world: 1, name: "Chimney Rows", goal: { type: "length", n: 22 }, par: 60, tick: 140,
      map: map(join(same("..###..###..###..###", [3, 4, 15, 16]),
        { 7: "A..................B", 12: "b..................a" })),
      movers: [[0, 1, 19, 1, 3]] },
    { world: 1, name: "Last Tram Home", goal: { type: "survive", n: 60 }, par: 22, tick: 140,
      map: map(same("###..............###", [8, 12])),
      movers: [[0, 3, 19, 3, 2], [19, 6, 0, 6, 3], [0, 14, 19, 14, 2], [19, 17, 0, 17, 3], [16, 0, 16, 19, 3]] },
    { world: 1, name: "Clocktower Square", goal: { type: "score", n: 450 }, par: 60, tick: 135,
      map: map(join(same("..##...##...##...##.", [2, 3, 6, 7, 13, 14, 17, 18]),
        { 0: "A..................B", 19: "b..................a" })),
      movers: [[0, 4, 19, 4, 2], [19, 15, 0, 15, 2], [10, 0, 10, 9, 3], [15, 11, 15, 19, 3]] },

    // ---------- Hollow Sky: the edges wrap, clouds drift ----------
    { world: 2, name: "Empty Heavens", goal: { type: "eat", n: 15 }, par: 45, tick: 135, wrap: true,
      map: map(same(".....#........#.....", [5, 14])) },
    { world: 2, name: "Drifting Clouds", goal: { type: "eat", n: 15 }, par: 50, tick: 130, wrap: true,
      map: map(same("........##..........", [2, 17])),
      movers: [[0, 0, 19, 19, 3], [19, 0, 0, 19, 3], [0, 15, 19, 15, 2], [3, 3, 3, 17, 4]] },
    { world: 2, name: "Old Observatory", goal: { type: "length", n: 26 }, par: 65, tick: 130, wrap: true,
      map: map(join(same("......###..###......", [6, 13]), same("......#......#......", [7, 8, 11, 12]))),
      movers: [[0, 3, 19, 3, 2], [19, 16, 0, 16, 2]] },
    { world: 2, name: "Starless Gates", goal: { type: "survive", n: 75 }, par: 30, tick: 130, wrap: true,
      map: map({ 3: "...A............B...", 16: "...b............a...", 5: ".........C..........",
        14: ".........c.........." }),
      movers: [[0, 7, 19, 7, 3], [19, 12, 0, 12, 3], [7, 0, 7, 19, 4]] },
    { world: 2, name: "Edge of Night", goal: { type: "score", n: 600 }, par: 65, tick: 125, wrap: true,
      map: map(join(same("..#....#....#....#..", [2, 17]), same("....#....#....#.....", [6, 14]))),
      movers: [[0, 4, 19, 4, 2], [19, 8, 0, 8, 3], [0, 12, 19, 12, 3], [19, 16, 0, 16, 2]] },

    // ---------- The Moon's Path: eclipse stones fade in and out ----------
    { world: 3, name: "Silver Steps", goal: { type: "eat", n: 15 }, par: 50, tick: 125,
      map: map(same(".....1........1.....", [2, 3, 4, 5, 6, 7, 12, 13, 14, 15, 16, 17])) },
    { world: 3, name: "Phases", goal: { type: "eat", n: 18 }, par: 60, tick: 120,
      map: map(join(same("..11111.....22222...", [3, 13]), same("...22222....11111...", [7, 16]))) },
    { world: 3, name: "Eclipse Gate", goal: { type: "length", n: 30 }, par: 80, tick: 125,
      map: map(join(same("......#......#......", [0, 1, 5, 6, 7, 8, 11, 12, 13, 14, 18, 19]),
        same("......1......1......", [3, 4]), same("......2......2......", [15, 16]),
        { 2: "..A...#......#...B..", 17: "..b...#......#...a.." })) },
    { world: 3, name: "Tide of Night", goal: { type: "survive", n: 90 }, par: 35, tick: 120, wrap: true,
      map: map({ 4: "...111......222.....", 15: ".....222......111...", 7: ".1..............2...",
        13: "...2..............1." }),
      movers: [[0, 2, 19, 2, 2], [19, 17, 0, 17, 2], [10, 0, 10, 19, 3]] },
    { world: 3, name: "Heart of the Moon", goal: { type: "score", n: 800 }, par: 75, tick: 115, wrap: true,
      map: map({ 1: ".A................B.", 18: ".b................a.", 4: "....####1111####....",
        15: "....####2222####....", 7: "..#..............#..", 12: "..#..............#.." }),
      movers: [[19, 6, 0, 6, 2], [0, 13, 19, 13, 2]] }
  ];

  var DARK = [4, 7, 12, 14, 17, 18];

  LEVELS.forEach(function (level, i) {
    level.id = i + 1;
    level.index = i;
    level.number = (level.world + 1) + "-" + ((i % 5) + 1);
    if (level.items === undefined) level.items = true;
    // dark levels: only the serpent's own light shows the board
    level.dark = DARK.indexOf(level.id) !== -1;
  });

  function goalText(goal) {
    if (!goal) return LM.t("goal.none");
    if (goal.type === "eat") return LM.t("goal.eat", { n: goal.n });
    if (goal.type === "length") return LM.t("goal.length", { n: goal.n });
    if (goal.type === "survive") return LM.t("goal.survive", { n: goal.n });
    return LM.t("goal.score", { n: goal.n });
  }

  // Moon thresholds in words, for the level card.
  function moonText(level) {
    if (level.goal.type === "survive") {
      return [LM.t("moon.survive"), LM.t("moon.catch", { n: Math.ceil(level.par * 0.6) }), LM.t("moon.catch", { n: level.par })];
    }
    return [LM.t("moon.clear"), LM.t("moon.under", { t: fmtTime(level.par * 1.5) }), LM.t("moon.under", { t: fmtTime(level.par) })];
  }

  function fmtTime(seconds) {
    seconds = Math.max(0, Math.floor(seconds));
    var m = Math.floor(seconds / 60);
    var s = seconds % 60;
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  // 1 to 3 moons for a cleared level.
  function rate(level, result) {
    if (!result.won) return 0;
    if (level.goal.type === "survive") {
      if (result.eaten >= level.par) return 3;
      if (result.eaten >= Math.ceil(level.par * 0.6)) return 2;
      return 1;
    }
    var t = result.elapsedMs / 1000;
    if (t <= level.par) return 3;
    if (t <= level.par * 1.5) return 2;
    return 1;
  }

  function progress(goal, game) {
    if (!goal) return 0;
    var cur = 0;
    if (goal.type === "eat") cur = game.eaten;
    else if (goal.type === "length") cur = game.snake.length();
    else if (goal.type === "survive") cur = game.elapsedMs / 1000;
    else cur = game.score;
    return Math.min(1, cur / goal.n);
  }

  function endlessLevel() {
    return { id: "endless", name: "Endless", world: 0, goal: null, tick: LM.config.endless.tickStart,
      items: true, map: map({}), mode: "endless" };
  }

  LM.levels = {
    list: LEVELS,
    byId: function (id) { return LEVELS[id - 1] || null; },
    ofWorld: function (w) { return LEVELS.filter(function (l) { return l.world === w; }); },
    darkList: function () { return LEVELS.filter(function (l) { return l.dark; }); },
    goalText: goalText,
    moonText: moonText,
    fmtTime: fmtTime,
    rate: rate,
    progress: progress,
    endless: endlessLevel,
    makeMap: map
  };
})(window.LUMEN);
