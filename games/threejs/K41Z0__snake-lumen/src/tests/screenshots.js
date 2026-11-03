// Regenerates the README screenshots in screenshots/.
// Needs Playwright (see tests/e2e.js). Run: node tests/screenshots.js
// Gameplay shots are real runs steered by the built-in bot. WebGL runs on
// SwiftShader here, so frames are slow; the bot steers inside each game tick
// so a slow frame cannot make it miss a turn.
var path = require("path");
var chromium = require("playwright").chromium;
var URL = "file://" + path.resolve(__dirname, "..", "index.html");
var OUT = path.resolve(__dirname, "..", "screenshots");
function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

// A profile partway through the campaign, so the menus have something to show.
function seed(cleared) {
  var p = LUMEN.app.profile;
  p.wallet = 345;
  p.settings.quality = "high";
  LUMEN.app.applySettings();
  // SwiftShader is slow; keep full resolution for still shots
  if (LUMEN.app.scene.three) { LUMEN.app.scene.three.adaptive = false; LUMEN.app.scene.three.dynScale = 1; LUMEN.app.scene.three.resize(); }
  p.levels = {};
  var moons = [3, 3, 2, 3, 2, 3, 1, 2, 3, 2, 3, 2, 1, 2, 3, 2, 2, 3, 1, 2];
  for (var i = 1; i <= cleared; i++) p.levels[i] = { moons: moons[i - 1], bestMs: 31000 + i * 2000, bestScore: 180 + i * 20 };
  p.stats.stars = 612; p.stats.golden = 9; p.stats.bestEndless = 1240; p.stats.playMs = 1000 * 60 * 21;
  p.stats.powerups = { slow: 3, ghost: 2, magnet: 4, double: 0 };
  p.story = { intro: 1, w1: 1, w2: 1, w3: 1, finale: 0 };
  ["first_light", "handful", "garden_blooms", "city_wakes", "spark_chain", "ribbon_of_light", "shooting_star", "wishmaker", "ouroboros",
    "night_owl", "new_glow", "radiant_world", "thousand_lights"].forEach(function (id, k) { p.unlocked[id] = p.unlocked[id] || Date.now() - k * 86400000; });
  p.skins.owned = ["lumen", "firefly", "tide", "aurora"];
  LUMEN.achievements.evaluate(p, { run: null });
  p.endless = [{ score: 1240, length: 41, date: "2026-10-12" }, { score: 865, length: 33, date: "2026-10-14" }, { score: 610, length: 28, date: "2026-10-11" }];
  LUMEN.app.save();
}

function startBot() {
  window.__bot = setInterval(function () {
    var g = LUMEN.app.game;
    if (!g || g.__bot) return;
    g.__bot = true;
    var step = g.step;
    g.step = function () {
      if (window.__bot && !g.snake.queue.length) { var d = LUMEN.autopilot.choose(g); g.turn(d.x, d.y); }
      return step.call(g);
    };
  }, 10);
}
function stopBot() { clearInterval(window.__bot); window.__bot = 0; }

(async function () {
  var browser = await chromium.launch({ args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });
  var ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, locale: "en-US" });
  var page = await ctx.newPage();
  page.on("pageerror", function (e) { console.log("pageerror", e.message); });
  page.on("console", function (m) { if (m.type() === "error") console.log("console", m.text()); });
  await page.goto(URL);
  var shot = async function (name, ms) { await wait(ms || 900); await page.screenshot({ path: path.join(OUT, name + ".png"), timeout: 120000 }); console.log("  " + name + ".png"); };

  // a fresh save: the title, then the story intro
  // PART=2 resumes at the finale (the full run takes a while on SwiftShader)
  // SHOTS=title,worlds,garden,city,sky,moon,dark,menus,finale,ru,phone picks
  // batches (all by default), so a slow SwiftShader run can be split up
  var only = (process.env.SHOTS || "").split(",").filter(Boolean);
  var want = function (k) { return !only.length || only.indexOf(k) >= 0; };
  if (want("title")) {
  await shot("title", 6000);
  await page.evaluate(function () { LUMEN.app.openCampaign(); });
  await shot("story-intro", 10800);
  }

  // one run of a level, steered by the bot until `until(game)` holds
  async function play(level, skin, cleared, until, name, maxMs, extra) {
    await page.evaluate(function (a) {
      var p = LUMEN.app.profile;
      p.levels = {};
      for (var i = 1; i <= a[2]; i++) p.levels[i] = { moons: 2, bestMs: 50000, bestScore: 200 };
      p.skins.selected = a[1];
      LUMEN.app.startLevel(a[0]);
    }, [level, skin, cleared]);
    await wait(2700);
    await page.evaluate(startBot);
    var t0 = Date.now();
    for (;;) {
      // a crash before the moment we want: same level, try again
      if (await page.evaluate(function () { var g = LUMEN.app.game; return !!g && g.status === "over"; })) {
        await page.evaluate(function (id) { LUMEN.app.startLevel(id); }, level);
        await wait(3600);
        continue;
      }
      if (Date.now() - t0 > maxMs) break;
      var done = await page.evaluate(function (src) { var g = LUMEN.app.game; return !g || g.status === "won" || (g.status === "running" && (0, eval)("(" + src + ")")()); }, until.toString());
      if (done) break;
      await wait(100);
    }
    if (extra) { await page.evaluate(extra); await wait(350); }
    await shot(name, 60);
    await page.evaluate(stopBot);
    await page.evaluate(function () { LUMEN.app.quit("title"); });
    await wait(1000);
  }
  var powerup = function () {
    var g = LUMEN.app.game;
    if (!g.item) { var c = g.spawnCell(false); if (c) g.item = { x: c.x, y: c.y, type: "magnet", ttl: 8000, max: 9000 }; }
    if (!g.golden) { var c2 = g.spawnCell(false); if (c2) g.golden = { x: c2.x, y: c2.y, ttl: 5000, max: 6500 }; }
  };
  await page.evaluate(seed, 0);
  // each world from low down, during the camera glide at the start of a run
  async function glide(level, name) {
    await page.evaluate(function (id) {
      var p = LUMEN.app.profile;
      for (var i = 1; i < id; i++) p.levels[i] = p.levels[i] || { moons: 2, bestMs: 50000, bestScore: 200 };
      LUMEN.app.startLevel(id);
    }, level);
    var t0 = Date.now();
    while (Date.now() - t0 < 8000 && !(await page.evaluate(function () { var t = LUMEN.app.scene.three; return LUMEN.app.phase === "countdown" && t && t.introAt >= 0 && LUMEN.app.t - t.introAt > 0.35; }))) await wait(30);
    await shot(name, 10);
    await page.evaluate(function () { LUMEN.app.quit("title"); });
    await wait(900);
  }
  if (want("worlds")) {
  await glide(3, "world-garden");
  await glide(8, "world-city");
  await glide(13, "world-sky");
  await glide(16, "world-moon");
  }
  await page.evaluate(seed, 0);
  // the garden asleep (first moments of a new world) and awake (last level, nearly done)
  if (want("garden")) {
  await play(3, "lumen", 2, function () { return LUMEN.app.game.elapsedMs > 1500; }, "garden-before", 4000);
  await play(3, "lumen", 5, function () { return LUMEN.app.game.snake.length() >= 16; }, "garden-after", 90000, powerup);
  }
  if (want("city")) {
  await play(8, "firefly", 7, function () { return LUMEN.app.game.elapsedMs > 1500; }, "city-before", 4000);
  await play(8, "firefly", 10, function () { return LUMEN.app.game.snake.length() >= 20; }, "city-after", 90000, powerup);
  }
  if (want("sky")) await play(13, "aurora", 12, function () { return LUMEN.app.game.snake.length() >= 20; }, "play-sky", 90000, powerup);
  if (want("moon")) await play(16, "tide", 15, function () { return LUMEN.app.game.snake.length() >= 18; }, "play-moon", 90000, powerup);
  // dark levels: only the serpent's own light shows the board
  if (want("dark")) {
  await play(12, "lumen", 11, function () { return LUMEN.app.game.snake.length() >= 12; }, "dark-sky", 90000);
  await play(17, "ember", 16, function () { return LUMEN.app.game.snake.length() >= 17 && LUMEN.app.scene.flashAmt < 0.02 && !LUMEN.app.scene.banner; }, "dark-moon", 120000);
  }

  if (want("menus")) {
  await page.evaluate(seed, 13);
  await page.evaluate(function () { LUMEN.app.go("map", { focus: 14 }); }); await shot("world-map", 1500);
  await page.evaluate(function () { LUMEN.app.go("trophies"); }); await shot("achievements");
  await page.evaluate(function () { LUMEN.app.go("shop", { focus: "aurora" }); }); await shot("shop", 1200);

  // a results card, from a real win of level 1
  await page.evaluate(function () { LUMEN.app.startLevel(1); });
  await wait(2700);
  await page.evaluate(startBot);
  var t1 = Date.now();
  while (Date.now() - t1 < 90000 && !(await page.evaluate(function () { return LUMEN.app.phase === "results"; }))) await wait(200);
  await page.evaluate(stopBot);
  await shot("level-complete", 2600);
  }

  // the finale
  if (want("finale")) {
  await page.evaluate(function () { LUMEN.app.profile.skins.selected = "lumen"; LUMEN.app.playStory("finale", { then: "title" }); });
  await shot("finale", 11500);

  await page.evaluate(seed, 13);
  await page.evaluate(function () { LUMEN.app.go("level", { id: 14 }); }); await shot("dark-level-card", 1000);
  }

  await ctx.close();

  if (want("ru")) {
  // Russian: a browser set to Russian starts in Russian
  ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, locale: "ru-RU" });
  page = await ctx.newPage();
  page.on("pageerror", function (e) { console.log("pageerror", e.message); });
  page.on("console", function (m) { if (m.type() === "error") console.log("console", m.text()); });
  await page.goto(URL);
  await shot("title-ru", 6000);
  await page.evaluate(seed, 0);
  await play(8, "firefly", 9, function () { return LUMEN.app.game.snake.length() >= 14; }, "play-ru", 90000, powerup);
  await ctx.close();
  }

  if (want("phone")) {
  var phone = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: "en-US" });
  var mp = await phone.newPage();
  await mp.goto(URL);
  await wait(700);
  await mp.evaluate(seed, 7);
  // a phone shows what a phone gets: Auto, which picks Low
  await mp.evaluate(function () { LUMEN.app.profile.settings.quality = "auto"; LUMEN.app.applySettings(); });
  await mp.evaluate(function () { LUMEN.app.profile.skins.selected = "tide"; LUMEN.app.startLevel(8); });
  await wait(2700);
  await mp.evaluate(startBot);
  await wait(14000);
  await mp.screenshot({ path: path.join(OUT, "mobile.png"), timeout: 120000 });
  console.log("  mobile.png");
  await mp.evaluate(function () { LUMEN.app.quit("title"); });
  await wait(900);
  await mp.evaluate(function () { LUMEN.app.startLevel(7); });
  await wait(16000);
  await mp.screenshot({ path: path.join(OUT, "mobile-dark.png"), timeout: 120000 });
  console.log("  mobile-dark.png");
  await mp.evaluate(stopBot);
  await mp.evaluate(function () { LUMEN.app.quit("map", { focus: 7 }); });
  await wait(1600);
  await mp.screenshot({ path: path.join(OUT, "world-map-phone.png"), timeout: 120000 });
  console.log("  world-map-phone.png");
  }
  await browser.close();
})();
