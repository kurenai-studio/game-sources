// Bot sweep: the built-in autopilot plays every campaign level with twelve
// seeds. A level passes when the bot clears it at least NEED times, which
// shows it is winnable with these rules and seeds. The autopilot is a simple
// greedy path finder that never plans for its own tail, so long survive
// levels are hard for it; win rates are printed for every level.
// Dark levels (marked "dark") use the same rules as the rest: darkness only
// changes what is drawn, so the bot plays them exactly like the others.
// Run: node tests/bot-sweep.js
var LUMEN = require("./load-core.js")();
var SEEDS = 12, NEED = 3;
var total = 0, darkWins = 0, darkGames = 0;
var bad = 0;
LUMEN.levels.list.forEach(function (lv) {
  var wins = 0, reasons = {}, times = [];
  for (var s = 1; s <= SEEDS; s++) {
    var g = new LUMEN.Game({ level: lv, mode: "campaign", seed: s * 977 });
    g.start();
    for (var i = 0; i < 20000 && g.status === "running"; i++) {
      if (!g.snake.queue.length) { var d = LUMEN.autopilot.choose(g); g.turn(d.x, d.y); }
      g.update(g.tickMs());
    }
    if (g.status === "won") { wins++; times.push(Math.round(g.elapsedMs / 1000)); }
    else reasons[g.stats.crash || "stalled"] = (reasons[g.stats.crash || "stalled"] || 0) + 1;
  }
  total += wins;
  if (lv.dark) { darkWins += wins; darkGames += SEEDS; }
  var okLevel = wins >= NEED;
  if (!okLevel) bad++;
  console.log((okLevel ? "  ok   " : "  FAIL ") + lv.number + " " + lv.name.padEnd(18) + (lv.dark ? " dark" : "     ") + " wins " + wins + "/" + SEEDS + "  par " + lv.par +
    "  times " + times.join(",") + (Object.keys(reasons).length ? "  " + JSON.stringify(reasons) : ""));
});
console.log("\nbot wins " + total + "/" + LUMEN.levels.list.length * SEEDS + " overall, " + darkWins + "/" + darkGames + " on dark levels");
console.log((LUMEN.levels.list.length - bad) + " passed, " + bad + " failed");
process.exit(bad ? 1 : 0);
