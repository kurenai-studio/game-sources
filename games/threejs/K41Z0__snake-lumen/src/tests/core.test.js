// Unit tests for the pure core. Run: node tests/core.test.js
var loadCore = require("./load-core");
var LUMEN = loadCore();

var passed = 0, failed = 0;
function test(name, fn) {
  try { fn(); passed++; console.log("  ok   " + name); }
  catch (e) { failed++; console.log("  FAIL " + name + "\n       " + (e && e.stack || e)); }
}
function eq(a, b, msg) { if (a !== b) throw new Error((msg || "") + " expected " + JSON.stringify(b) + ", got " + JSON.stringify(a)); }
function ok(v, msg) { if (!v) throw new Error(msg || "expected truthy"); }

function play(game, maxTicks, bot) {
  game.start();
  for (var i = 0; i < maxTicks && game.status === "running"; i++) {
    if (bot) { var d = LUMEN.autopilot.choose(game); game.turn(d.x, d.y); }
    game.update(game.tickMs());
  }
  return game;
}

console.log("rng and daily");
test("rng is deterministic per seed", function () {
  var a = new LUMEN.Rng(42), b = new LUMEN.Rng(42), c = new LUMEN.Rng(43);
  for (var i = 0; i < 50; i++) eq(a.next(), b.next());
  ok(new LUMEN.Rng(42).next() !== c.next(), "different seeds differ");
});
test("daily board is the same for the same date and differs across dates", function () {
  var a = LUMEN.daily.level("2026-10-15"), b = LUMEN.daily.level("2026-10-15"), c = LUMEN.daily.level("2026-10-16");
  eq(JSON.stringify(a), JSON.stringify(b));
  ok(JSON.stringify(a.map) !== JSON.stringify(c.map) || a.world !== c.world, "next day differs");
});
test("daily boards are connected and keep the start lane clear for a year", function () {
  var d = new Date(2026, 0, 1);
  for (var i = 0; i < 365; i++) {
    var lv = LUMEN.daily.level(LUMEN.daily.dateKey(d));
    ok(LUMEN.daily.connected(lv.map.map(function (r) { return r.split(""); })), "connected " + lv.dateKey);
    for (var x = 1; x <= 12; x++) eq(lv.map[10].charAt(x), ".", lv.dateKey + " lane x=" + x);
    d.setDate(d.getDate() + 1);
  }
});
test("same daily seed and same inputs give the same star sequence", function () {
  var lv = LUMEN.daily.level("2026-10-15");
  function run() {
    var g = new LUMEN.Game({ level: lv, mode: "daily", seed: lv.seed });
    play(g, 400, true);
    return g.score + ":" + g.eaten + ":" + g.tick;
  }
  eq(run(), run());
});

console.log("levels");
test("there are 20 levels, 5 per world", function () {
  eq(LUMEN.levels.list.length, 20);
  for (var w = 0; w < 4; w++) eq(LUMEN.levels.ofWorld(w).length, 5);
});
LUMEN.levels.list.forEach(function (lv) {
  test("level " + lv.number + " " + lv.name + " is well formed", function () {
    eq(lv.map.length, 20);
    lv.map.forEach(function (r, y) { eq(r.length, 20, "row " + y); });
    var b = new LUMEN.Board(lv);
    eq(Object.keys(b.portals).length, b.portalList.length * 2, "portals paired");
    for (var x = 2; x <= 12; x++) ok(b.isStaticFree(x, 10), "start lane free at x=" + x);
    ok(LUMEN.daily.connected(lv.map.map(function (r) { return r.replace(/[^#]/g, ".").split(""); })), "connected");
    b.movers.forEach(function (m) {
      var x = m.from.x, y = m.from.y;
      while (true) {
        ok(!b.isWall(x, y) && !b.portalAt(x, y), "mover path clear at " + x + "," + y);
        if (x === m.to.x && y === m.to.y) break;
        x += Math.sign(m.to.x - x); y += Math.sign(m.to.y - y);
      }
    });
  });
});
test("the bot clears the first level of every world", function () {
  [1, 6, 11, 16].forEach(function (id) {
    var g = new LUMEN.Game({ level: LUMEN.levels.byId(id), mode: "campaign", seed: 7 });
    play(g, 4000, true);
    eq(g.status, "won", "level " + id);
  });
});
test("star rating follows par time", function () {
  var lv = LUMEN.levels.byId(1);
  eq(LUMEN.levels.rate(lv, { won: true, elapsedMs: 20000 }), 3);
  eq(LUMEN.levels.rate(lv, { won: true, elapsedMs: 40000 }), 2);
  eq(LUMEN.levels.rate(lv, { won: true, elapsedMs: 90000 }), 1);
  eq(LUMEN.levels.rate(lv, { won: false, elapsedMs: 1 }), 0);
  var sv = LUMEN.levels.byId(4);
  eq(LUMEN.levels.rate(sv, { won: true, eaten: 16 }), 3);
  eq(LUMEN.levels.rate(sv, { won: true, eaten: 10 }), 2);
  eq(LUMEN.levels.rate(sv, { won: true, eaten: 3 }), 1);
});

console.log("rules");
test("snake moves one cell per tick and the opening star is straight ahead", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  eq(g.star.x, 11); eq(g.star.y, 10);
  g.start(); g.update(g.tickMs());
  eq(g.snake.head().x, 6); eq(g.tick, 1);
});
test("eating grows the snake, scores and spawns a new star", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  g.start();
  for (var i = 0; i < 6; i++) g.update(g.tickMs());
  eq(g.eaten, 1); eq(g.snake.length(), 5); eq(g.score, 10);
  ok(g.star && !(g.star.x === 11 && g.star.y === 10));
  ok(g.takeEvents().some(function (e) { return e.type === "eat"; }));
});
test("reversing is ignored and turns queue up to two", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  g.start();
  eq(g.turn(-1, 0), false);
  eq(g.turn(0, -1), true);
  eq(g.turn(-1, 0), true);
  eq(g.turn(0, 1), false);
  g.update(g.tickMs()); eq(g.snake.dir.y, -1);
  g.update(g.tickMs()); eq(g.snake.dir.x, -1);
});
test("hitting the wall ends the run", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  g.turn(0, -1);
  play(g, 50, false);
  eq(g.status, "over"); eq(g.stats.crash, "wall");
});
test("wrap levels let the snake leave one edge and enter the other", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(11), seed: 3 });
  g.star = { x: 0, y: 0 };
  g.start(); g.update(g.tickMs());
  g.turn(0, -1);
  for (var i = 0; i < 12; i++) g.update(g.tickMs());
  eq(g.status, "running"); eq(g.snake.head().x, 6); eq(g.snake.head().y, 18);
});
test("biting your own tail ends the run unless ghosted", function () {
  function loop(ghost) {
    var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
    g.snake.cells = [{ x: 8, y: 10 }, { x: 7, y: 10 }, { x: 6, y: 10 }, { x: 5, y: 10 }, { x: 4, y: 10 }, { x: 3, y: 10 }];
    g.star = { x: 0, y: 0 };
    if (ghost) g.effects.ghost = 99999;
    g.start();
    g.turn(0, 1); g.update(g.tickMs());
    g.turn(-1, 0); g.update(g.tickMs());
    g.turn(0, -1); g.update(g.tickMs());
    return g;
  }
  var a = loop(false); eq(a.status, "over"); eq(a.stats.crash, "self");
  var b = loop(true); eq(b.status, "running"); eq(b.stats.ghostPasses, 1);
});
test("portals carry the head to their partner", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(6), seed: 2 });
  g.snake.cells = [{ x: 2, y: 4 }, { x: 2, y: 5 }, { x: 2, y: 6 }, { x: 2, y: 7 }];
  g.snake.dir = { x: 0, y: -1 };
  g.star = { x: 10, y: 10 };
  g.start(); g.update(g.tickMs()); g.update(g.tickMs());
  eq(g.snake.head().x, 17); eq(g.snake.head().y, 16);
});
test("phase blocks switch on and kill, but wait while occupied", function () {
  var lv = LUMEN.levels.byId(16);
  var b = new LUMEN.Board(lv);
  b.updatePhase(0, null); eq(b.isPhaseSolid(5, 2), false);
  b.updatePhase(14, function (x, y) { return x === 5 && y === 2; });
  eq(b.isPhaseSolid(5, 2), false, "held under snake"); eq(b.isPhaseSolid(5, 3), true);
  b.updatePhase(28, null); eq(b.isPhaseSolid(5, 3), false);
});
test("stars and power-ups never spawn on a mover lane", function () {
  [7, 9, 10, 12, 19].forEach(function (id) {
    var g = new LUMEN.Game({ level: LUMEN.levels.byId(id), seed: id });
    for (var i = 0; i < 300; i++) { var c = g.spawnCell(false); ok(!g.board.isLane(c.x, c.y), "level " + id + " lane " + c.x + "," + c.y); }
  });
});
test("movers walk their lane and never step onto the snake", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(7), seed: 4 });
  var m = g.board.movers[0];
  g.start();
  for (var i = 0; i < 10; i++) g.update(g.tickMs());
  ok(m.x > 0 && m.y === 4, "moved along row 4");
  g.board.stepMovers(2, function () { return true; });
  eq(m.x, m.px, "waits when blocked");
});
test("power-ups apply their effect and the combo multiplies points", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  g.item = { x: 6, y: 10, type: "double", ttl: 5000, max: 5000 };
  g.start(); g.update(g.tickMs());
  ok(g.effects.double > 0, "double active");
  for (var i = 0; i < 5; i++) g.update(g.tickMs());
  eq(g.score, 20, "first star doubled");
  g.star = { x: g.snake.head().x + 1, y: 10 };
  g.update(g.tickMs());
  eq(g.combo, 2); eq(g.score, 20 + 30, "combo x2 doubled");
});
test("slow-mo stretches the tick", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  var t = g.tickMs(); g.effects.slow = 1000;
  ok(Math.abs(g.tickMs() - t * LUMEN.config.slowFactor) < 1e-9);
});
test("magnet drags the star toward the head", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  g.star = { x: 9, y: 13 }; g.effects.magnet = 5000;
  g.start(); g.update(g.tickMs());
  ok(Math.abs(g.star.x - 6) + Math.abs(g.star.y - 10) < 6, "closer");
});
test("survive goals are won by the clock", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(4), seed: 1 });
  g.start(); g.elapsedMs = 44990; g.update(20);
  eq(g.status, "won");
});
test("endless shifts worlds every few stars", function () {
  var g = new LUMEN.Game({ level: LUMEN.levels.endless(), mode: "endless", seed: 9 });
  play(g, 3000, true);
  ok(g.eaten >= 12, "bot ate " + g.eaten);
  ok(g.worldIndex === Math.floor(g.eaten / 12) % 4);
});

console.log("profile and achievements");
test("profile survives junk and keeps sane defaults", function () {
  var p = LUMEN.profile.normalize({ wallet: "lots", skins: { owned: ["gold"], selected: "nope" }, settings: { music: 0.1 } });
  eq(p.wallet, 0); eq(p.skins.selected, "lumen"); ok(p.skins.owned.indexOf("lumen") !== -1);
  eq(p.settings.music, 0.1); eq(p.settings.sfx, 0.8);
  eq(LUMEN.profile.normalize(null).wallet, 0);
});
test("the graphics quality setting defaults to auto and rejects junk", function () {
  eq(LUMEN.profile.create().settings.quality, "auto");
  eq(LUMEN.profile.normalize({ settings: { quality: "ultra" } }).settings.quality, "auto");
  ["auto", "low", "medium", "high"].forEach(function (q) { eq(LUMEN.profile.normalize({ settings: { quality: q } }).settings.quality, q); });
});
test("finishing a level books moons, unlocks the next and pays a bonus", function () {
  var p = LUMEN.profile.create();
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 7 });
  play(g, 4000, true);
  g.takeEvents().forEach(function (e) { LUMEN.profile.onEvent(p, e); });
  var out = LUMEN.profile.finishRun(p, g, {});
  ok(out.moons >= 1); eq(LUMEN.profile.levelMoons(p, 1), out.moons);
  ok(LUMEN.profile.levelUnlocked(p, 2)); ok(!LUMEN.profile.levelUnlocked(p, 3));
  eq(p.wallet, g.eaten + out.moons * LUMEN.config.moonBonusWallet);
});
test("endless table keeps the top scores in order", function () {
  var p = LUMEN.profile.create();
  [50, 300, 120].forEach(function (s) {
    var g = new LUMEN.Game({ level: LUMEN.levels.endless(), mode: "endless", seed: 1 });
    g.score = s; g.status = "over";
    LUMEN.profile.finishRun(p, g, { dateKey: "2026-10-15" });
  });
  eq(p.endless.map(function (e) { return e.score; }).join(","), "300,120,50"); eq(p.stats.bestEndless, 300);
});
test("shop spends the wallet once", function () {
  var p = LUMEN.profile.create(); p.wallet = 45;
  eq(LUMEN.profile.buySkin(p, "firefly"), true); eq(p.wallet, 5);
  eq(LUMEN.profile.buySkin(p, "firefly"), false); eq(LUMEN.profile.buySkin(p, "sunlit"), false);
  eq(p.skins.selected, "firefly"); eq(p.stats.skinsBought, 1);
});
test("the game is Snake: Lumen: four worlds, story flags, starting skin", function () {
  eq(LUMEN.config.name, "Snake: Lumen");
  eq(LUMEN.config.storageKey, "lumen.profile");
  eq(LUMEN.config.worlds.map(function (w) { return w.name; }).join("|"), "Whispering Garden|Sleeping City|Hollow Sky|The Moon's Path");
  var p = LUMEN.profile.create();
  eq(p.skins.selected, "lumen"); eq(p.story.intro, 0); eq(p.story.finale, 0);
  var q = LUMEN.profile.normalize({ story: { intro: 1 }, skins: { owned: ["prism"], selected: "prism" } });
  eq(q.story.intro, 1); eq(q.story.w1, 0); ok(q.skins.owned.indexOf("lumen") !== -1); eq(q.skins.selected, "prism");
  eq(LUMEN.levels.goalText({ type: "eat", n: 8 }), "Catch 8 stars");
  eq(LUMEN.levels.byId(20).name, "Heart of the Moon");
});
test("every achievement, world and level has a name and a description", function () {
  LUMEN.achievements.list.forEach(function (a) { ok(a.name && a.desc && a.icon, a.id); });
  LUMEN.config.worlds.forEach(function (w) { ok(w.name && w.blurb, w.id); });
  LUMEN.levels.list.forEach(function (l) { ok(l.name, "level " + l.id); });
});
test("there are 32 achievements in three categories with unique ids", function () {
  eq(LUMEN.achievements.list.length, 32);
  var ids = {};
  LUMEN.achievements.list.forEach(function (a) { ok(!ids[a.id], "dup " + a.id); ids[a.id] = 1; ok(/bronze|silver|gold/.test(a.rarity)); });
  ["progress", "mastery", "secret"].forEach(function (c) {
    ok(LUMEN.achievements.list.some(function (a) { return a.cat === c; }), c);
  });
});
test("achievements unlock once from live run state", function () {
  var p = LUMEN.profile.create();
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  g.stats.maxCombo = 10; p.stats.stars = 1;
  var got = LUMEN.achievements.evaluate(p, { run: g, hour: 12 }).map(function (a) { return a.id; });
  ok(got.indexOf("first_light") !== -1 && got.indexOf("spark_chain") !== -1 && got.indexOf("supernova") !== -1, got.join());
  eq(LUMEN.achievements.evaluate(p, { run: g, hour: 12 }).length, 0, "no repeats");
});
test("secret achievements: tail bite, early crash, night owl, konami", function () {
  var p = LUMEN.profile.create();
  var g = new LUMEN.Game({ level: LUMEN.levels.byId(1), seed: 1 });
  g.stats.crash = "self"; g.elapsedMs = 1000; g.status = "over"; p.flags.konami = true;
  var got = LUMEN.achievements.evaluate(p, { run: g, over: true, won: false, hour: 2 }).map(function (a) { return a.id; });
  ["ouroboros", "lights_out", "night_owl", "old_school"].forEach(function (id) { ok(got.indexOf(id) !== -1, id + " in " + got); });
});
test("progress values are reported for counting achievements", function () {
  var p = LUMEN.profile.create(); p.stats.stars = 42;
  var a = LUMEN.achievements.byId("handful");
  eq(LUMEN.achievements.progress(a, { p: p }).join("/"), "42/100");
});

test("dark levels: one or two per world, later worlds have more", function () {
  var dark = LUMEN.levels.darkList();
  ok(dark.length === 6, "six dark levels");
  [0, 1, 2, 3].forEach(function (w) {
    var n = dark.filter(function (l) { return l.world === w; }).length;
    ok(n >= 1 && n <= 2, "world " + w + " has " + n);
  });
  ok(dark.filter(function (l) { return l.world >= 2; }).length === 4, "later worlds have two each");
  ok(!LUMEN.levels.byId(1).dark, "the first level is lit");
});
test("dark level achievements: Lantern Bearer and Night Vision", function () {
  var p = LUMEN.profile.create();
  var ids = function () { return LUMEN.achievements.evaluate(p, { run: null }).map(function (a) { return a.id; }); };
  ok(ids().indexOf("lantern_bearer") === -1, "nothing yet");
  p.levels[4] = { moons: 1 };
  ok(ids().indexOf("lantern_bearer") !== -1, "lantern bearer after one dark clear");
  var nv = LUMEN.achievements.byId("night_vision");
  eq(LUMEN.achievements.progress(nv, { p: p }).join("/"), "0/6");
  LUMEN.levels.darkList().forEach(function (l) { p.levels[l.id] = { moons: 3 }; });
  ok(ids().indexOf("night_vision") !== -1, "night vision with 3 moons on all");
});
test("i18n: detection, fallback, plurals, full Russian table", function () {
  var I = LUMEN.i18n;
  eq(I.detect("ru-RU"), "ru"); eq(I.detect("ru"), "ru"); eq(I.detect("en-GB"), "en"); eq(I.detect("de"), "en"); eq(I.detect(""), "en");
  eq(I.plural(1, ["a", "b", "c"]), "a"); eq(I.plural(3, ["a", "b", "c"]), "b"); eq(I.plural(11, ["a", "b", "c"]), "c"); eq(I.plural(22, ["a", "b", "c"]), "b");
  I.set("ru");
  eq(LUMEN.levels.goalText({ type: "eat", n: 5 }), "\u041f\u043e\u0439\u043c\u0430\u0439 5 \u0437\u0432\u0451\u0437\u0434");
  ok(LUMEN.t("no.such.key", null, "x") === "x", "default for unknown keys");
  LUMEN.achievements.list.forEach(function (a) {
    ok(LUMEN.L.achName(a) !== a.name && LUMEN.L.achDesc(a) !== a.desc, "ru for " + a.id);
  });
  LUMEN.levels.list.forEach(function (l) { ok(LUMEN.L.level(l) !== l.name, "ru level " + l.id); });
  LUMEN.config.skins.forEach(function (s) { ok(LUMEN.L.skin(s) !== s.name || s.id === "prism", "ru skin " + s.id); });
  ["intro", "w1", "w2", "w3", "finale"].forEach(function (k) {
    ok(Array.isArray(LUMEN.t("story." + k)) && LUMEN.t("story." + k).length >= 3, "story " + k);
  });
  I.set("en");
  eq(LUMEN.levels.goalText({ type: "eat", n: 1 }), "Catch 1 star");
});

console.log("\n" + passed + " passed, " + failed + " failed");
process.exit(failed ? 1 : 0);
