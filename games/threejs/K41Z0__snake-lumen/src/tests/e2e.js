// End-to-end test: loads index.html from file:// in headless Chromium and
// plays it with real key presses and taps.
// Needs Playwright:  npm i playwright && npx playwright install chromium
// Run:               node tests/e2e.js
var path = require("path");
var chromium = require("playwright").chromium;

var URL = "file://" + path.resolve(__dirname, "..", "index.html");
var passed = 0, failed = 0;
var LUMEN_DARK = [4, 7, 12, 14, 17, 18];
function ok(cond, name, extra) {
  if (cond) { passed++; console.log("  ok   " + name); }
  else { failed++; console.log("  FAIL " + name + (extra !== undefined ? "  -> " + JSON.stringify(extra) : "")); }
}
function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

function watch(page, bag) {
  page.on("console", function (m) { if (m.type() === "error" || m.type() === "warning") bag.push(m.type() + ": " + m.text()); });
  page.on("pageerror", function (e) { bag.push("pageerror: " + e.message); });
}

var KEY = { "1,0": "ArrowRight", "-1,0": "ArrowLeft", "0,1": "ArrowDown", "0,-1": "ArrowUp" };

// Let the built-in bot decide, but steer with real key presses. Frames on
// SwiftShader are slow and uneven, so when the bot turns it restarts the
// current tick's clock to give the key press time to arrive (game rules and
// the input path stay untouched).
async function botPlay(page, maxMs) {
  var t0 = Date.now();
  while (Date.now() - t0 < maxMs) {
    var s = await page.evaluate(function () {
      var app = LUMEN.app, g = app.game;
      if (!g || app.phase !== "play" || g.status !== "running") return { phase: app.phase, status: g && g.status };
      if (g.snake.queue.length) return { phase: app.phase, wait: true };
      var d = LUMEN.autopilot.choose(g);
      var cur = g.snake.dir;
      if (!(d.x === cur.x && d.y === cur.y)) g.acc = 0;
      return { phase: app.phase, key: (d.x === cur.x && d.y === cur.y) ? null : d.x + "," + d.y };
    });
    if (s.phase === "ending" || s.phase === "results") return s.phase;
    if (s.key) await page.keyboard.press(KEY[s.key]);
    await wait(15);
  }
  return "timeout";
}

// WebGL on SwiftShader builds a level more slowly than a real GPU, so wait
// for states instead of fixed times where a run starts.
async function waitFor(page, fn, ms, arg) {
  var t0 = Date.now();
  while (Date.now() - t0 < (ms || 15000)) {
    if (await page.evaluate(fn, arg)) return true;
    await wait(50);
  }
  return false;
}
function playing() { return LUMEN.app.phase === "play" && LUMEN.app.game && LUMEN.app.game.status === "running"; }

async function screen(page) {
  return page.evaluate(function () { var el = document.querySelector(".screen.active"); return el ? el.getAttribute("data-screen") : null; });
}

(async function () {
  // WebGL in headless Chromium runs on SwiftShader (software). It is slow,
  // so most of the run uses the Low preset; one check renders on High.
  var browser = await chromium.launch({ args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });
  async function lowQuality(p) { await p.evaluate(function () { LUMEN.app.profile.settings.quality = "low"; LUMEN.app.applySettings(); LUMEN.app.save(); }); }

  // ---------------- desktop ----------------
  console.log("desktop");
  var ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, locale: "en-US" });
  var page = await ctx.newPage();
  var errors = [];
  watch(page, errors);
  await page.goto(URL);
  await wait(900);
  ok(await page.evaluate(function () { return !!(window.LUMEN && LUMEN.app); }), "game boots from file:// with no server");
  ok(await screen(page) === "title", "title screen is shown");
  ok(await page.evaluate(function () { return !document.getElementById("fallback"); }), "load-failure fallback removed");
  ok(await page.evaluate(function () { return LUMEN.app.storage.ok; }), "localStorage available");
  ok(await page.evaluate(function () { return typeof THREE === "object" && THREE.REVISION === "160" && LUMEN.app.webgl(); }), "three.js r160 loaded from vendor/ and WebGL is on");
  await lowQuality(page);

  ok(await page.evaluate(function () { return document.title === "Snake: Lumen" && document.querySelector(".logo h1").getAttribute("aria-label") === "Snake: Lumen" && /SNAKE/.test(document.querySelector(".logo .brand-pre").textContent); }), "title and logo say Snake: Lumen");
  ok(await page.evaluate(function () { return /fallen stars/i.test(document.body.innerText) && /light/i.test(document.body.innerText); }), "the title screen tells the Snake: Lumen story");

  // menus by keyboard: Campaign -> story intro -> map -> level 1-1 card -> play
  await page.keyboard.press("Enter"); await wait(900);
  var intro = await page.evaluate(function () {
    return { screen: document.querySelector(".screen.active").getAttribute("data-screen"), phase: LUMEN.app.phase,
      lines: document.querySelectorAll(".story .line").length, first: document.querySelector(".story .line").textContent };
  });
  ok(intro.screen === "story" && intro.phase === "story" && intro.lines === 4 && /darkness/.test(intro.first), "first Campaign plays the story intro", intro);
  await wait(1500);
  await page.keyboard.press("Enter"); await wait(1000);
  ok(await screen(page) === "map" && await page.evaluate(function () { return LUMEN.app.profile.story.intro === 1 && LUMEN.app.phase === "menu"; }),
    "Enter skips the story to the world map");
  await page.keyboard.press("Escape"); await wait(500);
  await page.keyboard.press("Enter"); await wait(600);
  ok(await screen(page) === "map", "the intro plays only once");
  await page.keyboard.press("Enter"); await wait(500);
  ok(await screen(page) === "level", "Enter on the first node opens the level card");
  await page.keyboard.press("Escape"); await wait(500);
  ok(await screen(page) === "map", "Esc goes back to the map");
  await page.keyboard.press("Enter"); await wait(450);
  await page.keyboard.press("Enter"); await wait(600);
  ok(await page.evaluate(function () { return LUMEN.app.phase === "countdown" && LUMEN.app.game.level.id === 1; }), "Play starts level 1-1 with a countdown");
  ok(await waitFor(page, playing), "countdown hands over to play");
  var v3 = await page.evaluate(function () {
    var c = document.getElementById("view3d"), t = LUMEN.app.scene.three;
    return { shown: !!c && getComputedStyle(c).display !== "none", w: c && c.width, q: t.qName, calls: t.renderer.info.render.calls, tris: t.renderer.info.render.triangles,
      lights: t.pool.length + 2, m: t.measure() };
  });
  ok(v3.shown && v3.w > 0 && v3.calls > 10 && v3.tris > 1000, "the run is drawn by three.js on its own canvas", v3);
  ok(v3.q === "low" && v3.m && v3.m.mean > 30, "Low preset renders a visible board", v3);

  // pause and resume
  await page.keyboard.press("Space"); await wait(400);
  ok(await screen(page) === "pause" && await page.evaluate(function () { return LUMEN.app.game.status === "paused"; }), "Space pauses");
  await page.keyboard.press("Escape");
  ok(await waitFor(page, playing, 6000), "Esc resumes after a short countdown");

  // mute toggle
  await page.keyboard.press("m"); await wait(100);
  ok(await page.evaluate(function () { return LUMEN.app.profile.settings.muted === true; }), "M mutes");
  await page.keyboard.press("m");

  // play the level to the end with key presses
  var end = await botPlay(page, 90000);
  ok(end === "ending" || end === "results", "level 1-1 played to the end", end);
  await wait(2800);
  var r = await page.evaluate(function () {
    var g = LUMEN.app.game;
    return { won: g.status === "won", moons: (LUMEN.app.profile.levels[1] || {}).moons, screen: document.querySelector(".screen.active").getAttribute("data-screen"),
      title: document.querySelector(".screen.active h2").textContent, first: !!LUMEN.app.profile.unlocked.first_light,
      moonsOn: document.querySelectorAll(".bigmoons .st.on").length, toasts: document.querySelectorAll(".toast").length,
      wallet: LUMEN.app.profile.wallet };
  });
  ok(r.won && r.moons >= 1, "level won and moons recorded", r);
  ok(r.screen === "results" && /light restored/i.test(r.title), "light-restored screen shown", r.title);
  ok(r.moonsOn === r.moons, "moons animate in on the results card", r);
  ok(r.first, "achievement First Light unlocked");
  ok(r.wallet > 0, "stardust added to the wallet", r.wallet);
  var lit = await page.evaluate(function () { return { light: LUMEN.app.light, target: LUMEN.app.targetLight(LUMEN.app.game) }; });
  ok(lit.light > 0.6 && lit.target > 0.7, "catching the stars brought light back to the garden", lit);
  var stored = await page.evaluate(function () { return JSON.parse(localStorage.getItem("lumen.profile")); });
  ok(stored && stored.levels["1"] && stored.unlocked.first_light, "progress written to localStorage");

  // Enter -> next level is offered
  await page.keyboard.press("Enter");
  ok(await waitFor(page, function () { return LUMEN.app.game && LUMEN.app.game.level.id === 2 && LUMEN.app.phase === "play"; }), "Next level starts 1-2");

  // crash on purpose: Lights Out (secret) and the game-over card
  await page.keyboard.press("ArrowUp");
  var t0 = Date.now();
  while (Date.now() - t0 < 8000 && await page.evaluate(function () { return LUMEN.app.phase === "play" || LUMEN.app.phase === "countdown"; })) await wait(50);
  await wait(1500);
  var over = await page.evaluate(function () {
    var a = LUMEN.app;
    return { screen: document.querySelector(".screen.active").getAttribute("data-screen"), crash: a.game.stats.crash,
      title: document.querySelector(".screen.active h2").textContent, hugger: !!a.profile.unlocked.lights_out };
  });
  ok(over.screen === "results" && over.crash === "wall" && /hedge/i.test(over.title), "crashing shows the game-over card", over);
  ok(over.hugger, "secret achievement Lights Out unlocked by an early crash");

  // reload: everything persists
  await page.reload(); await wait(900);
  var persisted = await page.evaluate(function () {
    var p = LUMEN.app.profile;
    return { l1: p.levels[1] && p.levels[1].moons, a: Object.keys(p.unlocked).length, hug: !!p.unlocked.lights_out, wallet: p.wallet };
  });
  ok(persisted.l1 >= 1 && persisted.hug && persisted.a >= 2, "moons, achievements and wallet survive a reload", persisted);

  // Konami code on the title screen
  for (var k of ["ArrowUp", "ArrowUp", "ArrowDown", "ArrowDown", "ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowRight", "b", "a"]) {
    await page.keyboard.press(k); await wait(30);
  }
  await wait(300);
  ok(await page.evaluate(function () { var p = LUMEN.app.profile; return !!p.unlocked.old_school && p.skins.owned.indexOf("prism") !== -1; }),
    "Konami code unlocks Old School and the Prism skin");

  // shop: buy Firefly with the keyboard
  await page.evaluate(function () { LUMEN.app.profile.wallet = 100; LUMEN.app.go("shop"); }); await wait(500);
  await page.keyboard.press("ArrowRight"); await wait(100);
  var focused = await page.evaluate(function () { return document.querySelector(".skin.focus").getAttribute("data-skin"); });
  await page.keyboard.press("Enter"); await wait(400);
  var shop = await page.evaluate(function () { var p = LUMEN.app.profile; return { owned: p.skins.owned, sel: p.skins.selected, wallet: p.wallet, glow: !!p.unlocked.new_glow }; });
  ok(focused === "firefly" && shop.owned.indexOf("firefly") !== -1 && shop.sel === "firefly" && shop.wallet === 60, "arrow + Enter buys and equips Firefly", shop);
  ok(shop.glow, "New Glow unlocked by the purchase");
  await page.keyboard.press("ArrowRight"); await page.keyboard.press("ArrowRight"); await page.keyboard.press("ArrowRight");
  var poor = await page.evaluate(function () { return document.querySelector(".skin.focus").getAttribute("data-skin"); });
  await page.keyboard.press("Enter"); await wait(300);
  ok(await page.evaluate(function (id) { var p = LUMEN.app.profile; return p.wallet === 60 && p.skins.owned.length === 3 && p.skins.owned.indexOf(id) === -1; }, poor),
    "cannot buy what you cannot afford", poor);

  // trophies
  await page.keyboard.press("Escape"); await wait(500);
  await page.evaluate(function () { LUMEN.app.go("trophies"); }); await wait(500);
  var tro = await page.evaluate(function () {
    return { n: document.querySelectorAll(".ach").length, hidden: Array.prototype.filter.call(document.querySelectorAll(".ach .nm"), function (e) { return e.textContent === "Secret achievement"; }).length,
      unlocked: document.querySelectorAll(".ach.unlocked").length, imgs: Array.prototype.every.call(document.querySelectorAll(".ach img"), function (i) { return i.naturalWidth > 0; }) };
  });
  ok(tro.n === 32, "achievements screen lists 32 achievements", tro);
  ok(tro.hidden === 7 - 2, "locked secrets stay hidden (2 of 7 found)", tro);
  ok(tro.imgs, "every achievement has a drawn icon");

  // daily challenge
  await page.evaluate(function () { LUMEN.app.go("daily"); }); await wait(500);
  await page.keyboard.press("Enter"); await wait(3000);
  var daily = await page.evaluate(function () {
    var g = LUMEN.app.game; return { mode: g.mode, seed: g.seed, want: LUMEN.daily.seedFor(LUMEN.daily.dateKey()), name: g.level.name };
  });
  ok(daily.mode === "daily" && daily.seed === daily.want, "daily run uses the seed of today's date", daily);

  // endless from the menu, play a bit
  await page.evaluate(function () { LUMEN.app.quit("title"); }); await wait(1000);
  await page.keyboard.press("ArrowDown"); await page.keyboard.press("Enter"); await wait(500);
  ok(await screen(page) === "endless", "Endless screen reached with arrows");
  await page.keyboard.press("Enter");
  await waitFor(page, playing);
  await botPlay(page, 6000);
  ok(await page.evaluate(function () { return LUMEN.app.game.mode === "endless" && LUMEN.app.game.eaten > 0; }), "endless run eats stars");

  // settings: reduced flashing toggles a class and persists
  await page.evaluate(function () { LUMEN.app.quit("settings"); }); await wait(1000);
  await page.evaluate(function () { document.querySelectorAll(".toggle")[2].click(); });
  ok(await page.evaluate(function () { return LUMEN.app.profile.settings.reducedFlash && document.body.classList.contains("reduced"); }), "reduced-flashing setting applies");

  // a new world opens with a short story beat, once
  await page.evaluate(function () {
    var p = LUMEN.app.profile;
    for (var i = 1; i <= 5; i++) p.levels[i] = { moons: 1, bestMs: 60000, bestScore: 100 };
    LUMEN.app.quit("map");
  });
  await wait(1000);
  await page.evaluate(function () { LUMEN.app.startLevel(6); }); await wait(900);
  var inter = await page.evaluate(function () {
    return { screen: document.querySelector(".screen.active").getAttribute("data-screen"), kind: LUMEN.app.story && LUMEN.app.story.kind,
      text: document.querySelector(".story .lines").textContent };
  });
  ok(inter.screen === "story" && inter.kind === "w1" && /city/.test(inter.text), "the Sleeping City opens with an interlude", inter);
  await wait(800);
  await page.keyboard.press("Escape"); await wait(1200);
  ok(await page.evaluate(function () { return LUMEN.app.game && LUMEN.app.game.level.id === 6 && LUMEN.app.phase !== "story"; }), "Esc skips it and level 2-1 starts");
  await wait(2200);
  var cityLight = await page.evaluate(function () { return LUMEN.app.light; });
  ok(cityLight > 0.05 && cityLight < 0.3, "a new world starts dark", cityLight);

  // the finale: win the last level, Continue plays the Moon scene
  await page.evaluate(function () {
    var p = LUMEN.app.profile;
    for (var i = 1; i <= 19; i++) p.levels[i] = { moons: 2, bestMs: 60000, bestScore: 100 };
    LUMEN.app.quit("map");
  });
  await wait(1000);
  await page.evaluate(function () { LUMEN.app.startLevel(20); }); await wait(900);
  if (await page.evaluate(function () { return LUMEN.app.phase === "story"; })) { await page.keyboard.press("Enter"); await wait(1200); }
  await waitFor(page, playing);
  await page.evaluate(function () { var g = LUMEN.app.game; g.score = g.level.goal.n; g.checkGoal(); });
  await waitFor(page, function () { var el = document.querySelector(".screen.active"); return el && el.getAttribute("data-screen") === "results"; }, 12000);
  await wait(600);
  ok(await screen(page) === "results" && await page.evaluate(function () { return /continue/i.test(document.querySelector(".card .btn.primary").textContent); }),
    "beating the last level offers Continue");
  await page.keyboard.press("Enter"); await wait(1000);
  var fin = await page.evaluate(function () {
    return { kind: LUMEN.app.story && LUMEN.app.story.kind, text: document.querySelector(".story .lines").textContent,
      moonrise: !!LUMEN.app.profile.unlocked.moonrise, flag: LUMEN.app.profile.story.finale };
  });
  ok(fin.kind === "finale" && /Moon opens its eyes/.test(fin.text) && fin.flag === 1, "the finale scene plays", fin);
  ok(fin.moonrise, "Moonrise unlocked for clearing the Moon's Path");
  await wait(800);
  await page.mouse.click(640, 400); await wait(1200);
  ok(await screen(page) === "title", "a tap ends the finale on the title screen");

  // dark levels: marked on the map and the card, lit only by the serpent
  await page.evaluate(function () { LUMEN.app.go("map"); }); await wait(700);
  var marks = await page.evaluate(function () {
    var nodes = Array.prototype.slice.call(document.querySelectorAll(".node"));
    return nodes.map(function (n, i) { return n.querySelector(".dark-mark") ? i + 1 : 0; }).filter(Boolean);
  });
  ok(JSON.stringify(marks) === JSON.stringify(LUMEN_DARK), "the map marks exactly the dark levels with a moon", marks);
  await page.evaluate(function () { LUMEN.app.go("level", { id: 7 }); }); await wait(600);
  ok(await page.evaluate(function () { var d = document.querySelector(".card .dark-tag"); return !!d && /dark level/i.test(d.textContent) && !!d.querySelector("img"); }),
    "a dark level card shows the darkness mark and a note");
  async function boardDarkness(id) {
    await page.evaluate(function (id) { LUMEN.app.startLevel(id); }, id); await wait(900);
    if (await page.evaluate(function () { return LUMEN.app.phase === "story"; })) { await page.keyboard.press("Enter"); await wait(1200); }
    await waitFor(page, playing);
    await wait(300);
    return page.evaluate(function () {
      var t = LUMEN.app.scene.three, m = t.measure();
      return { black: m.black, mean: m.mean, night: t.game === LUMEN.app.game && t.dark, head: t.headLight.intensity, moon: t.moon.intensity };
    });
  }
  var lit6 = await boardDarkness(6);
  var dark7 = await boardDarkness(7);
  ok(dark7.night && !lit6.night, "dark levels use the night lighting, others do not", [lit6, dark7]);
  ok(lit6.mean > 55 && lit6.black < 0.02, "a normal board is clearly lit", lit6);
  ok(dark7.mean < lit6.mean * 0.55, "a dark board is much darker than a normal one", [lit6.mean, dark7.mean]);
  ok(dark7.black < 0.5, "a dark board keeps faint moonlit silhouettes instead of pure black", dark7);
  ok(dark7.head > lit6.head && dark7.moon < lit6.moon * 0.5, "in the dark the serpent's light is stronger and the moonlight low", [lit6, dark7]);
  var darkEnd = await botPlay(page, 120000);
  await wait(3600);
  var darkRes = await page.evaluate(function () { var p = LUMEN.app.profile; return { won: !!(p.levels[7] && p.levels[7].moons), lantern: !!p.unlocked.lantern_bearer }; });
  ok(darkEnd !== "timeout" && darkRes.won, "the dark level 2-2 can be played to a win", [darkEnd, darkRes]);
  ok(darkRes.lantern, "Lantern Bearer unlocked");
  await page.evaluate(function () { LUMEN.app.quit("title"); }); await wait(800);
  ok(await page.evaluate(function () { var c = document.getElementById("view3d"); return getComputedStyle(c).display === "none"; }), "the 3D canvas hides on the menus");

  // graphics quality: a setting with four choices, applied live and saved
  await page.evaluate(function () { LUMEN.app.go("settings"); }); await wait(500);
  var qs = await page.evaluate(function () {
    return { n: document.querySelectorAll(".quality-row [data-quality]").length, label: document.querySelector(".quality-row label").textContent,
      names: Array.prototype.map.call(document.querySelectorAll(".quality-row [data-quality]"), function (b) { return b.textContent; }).join(",") };
  });
  ok(qs.n === 4 && /Graphics/.test(qs.label) && qs.names === "Auto,Low,Medium,High", "Settings has Graphics: Auto / Low / Medium / High", qs);
  await page.click(".quality-row [data-quality=high]"); await wait(500);
  var qh = await page.evaluate(function () {
    var t = LUMEN.app.scene.three;
    return { set: LUMEN.app.profile.settings.quality, q: t.qName, shadows: t.renderer.shadowMap.enabled, pool: t.pool.length, sel: document.querySelector(".quality-row .sel").getAttribute("data-quality"),
      stored: JSON.parse(localStorage.getItem("lumen.profile")).settings.quality };
  });
  ok(qh.set === "high" && qh.q === "high" && qh.shadows && qh.pool === 6 && qh.sel === "high" && qh.stored === "high", "choosing High rebuilds the renderer with shadows and saves it", qh);
  await page.evaluate(function () { LUMEN.app.startLevel(16); }); await wait(900);
  if (await page.evaluate(function () { return LUMEN.app.phase === "story"; })) { await page.keyboard.press("Enter"); await wait(1200); }
  await waitFor(page, playing);
  var hi = await page.evaluate(function () { var t = LUMEN.app.scene.three; return { m: t.measure(), shadow: t.moon.castShadow, head: t.headLight.castShadow }; });
  ok(hi.m.mean > 40 && hi.shadow && hi.head, "High renders the Moon's Path with moon and serpent shadows", hi);
  await page.evaluate(function () { LUMEN.app.quit("title"); }); await wait(800);
  await lowQuality(page);

  ok(errors.length === 0, "no console errors or warnings on desktop", errors);
  await ctx.close();

  // ---------------- phone ----------------
  console.log("phone");
  var phone = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true, locale: "en-US" });
  var mp = await phone.newPage();
  var perr = [];
  watch(mp, perr);
  await mp.goto(URL);
  await wait(900);
  ok(await mp.evaluate(function () { return LUMEN.app.touch; }), "touch device detected");
  ok(await mp.evaluate(function () { return document.documentElement.scrollWidth <= window.innerWidth; }), "no horizontal overflow on the title");
  await mp.tap(".menu .btn.primary"); await wait(900);
  ok(await screen(mp) === "story", "tap on Campaign plays the story intro");
  await wait(600);
  await mp.tap(".story .lines"); await wait(1000);
  ok(await screen(mp) === "map", "a tap skips the story to the map");
  await mp.tap(".node.open"); await wait(500);
  await mp.tap(".card .btn.primary"); await waitFor(mp, playing);
  var mob = await mp.evaluate(function () {
    var pad = document.getElementById("pad"), L = LUMEN.app.scene.layoutBox, pr = pad.getBoundingClientRect();
    return { pad: !pad.hidden, padTop: pr.top, boardBottom: L.oy + L.h, boardW: L.w, vw: innerWidth, hudB: document.getElementById("hud").getBoundingClientRect().bottom, boardTop: L.oy };
  });
  ok(mob.pad, "on-screen arrows shown while playing");
  ok(mob.boardBottom <= mob.padTop && mob.boardTop >= mob.hudB - 1, "board fits between the HUD and the pad", mob);
  var mq = await mp.evaluate(function () { var t = LUMEN.app.scene.three; return { set: LUMEN.app.profile.settings.quality, q: t.qName, pr: t.renderer.getPixelRatio(), pool: t.pool.length }; });
  ok(mq.set === "auto" && mq.q === "low" && mq.pr <= 1 && mq.pool === 2, "Auto picks Low on a phone (pixel ratio capped, fewer lights)", mq);
  await mp.tap("#pad .up"); await wait(400);
  ok(await mp.evaluate(function () { return LUMEN.app.game.snake.dir.y === -1; }), "pad Up turns the serpent");
  // swipe left->down on the board
  var box = await mp.evaluate(function () { var L = LUMEN.app.scene.layoutBox; return { x: L.ox + L.w / 2, y: L.oy + L.h / 2 }; });
  var cdp = await phone.newCDPSession(mp);
  await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [{ x: box.x, y: box.y }] });
  for (var i = 1; i <= 5; i++) await cdp.send("Input.dispatchTouchEvent", { type: "touchMove", touchPoints: [{ x: box.x - i * 12, y: box.y }] });
  await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
  await wait(400);
  ok(await mp.evaluate(function () { var g = LUMEN.app.game; return g.snake.dir.x === -1 || g.status !== "running"; }), "swipe left turns the serpent");
  ok(perr.length === 0, "no console errors on the phone", perr);
  await phone.close();

  // ---------------- language ----------------
  console.log("language");
  var ru = await browser.newContext({ viewport: { width: 1280, height: 800 }, locale: "ru-RU" });
  var rp = await ru.newPage();
  var rerr = [];
  watch(rp, rerr);
  await rp.goto(URL);
  await wait(900);
  var r0 = await rp.evaluate(function () {
    var stored = JSON.parse(localStorage.getItem("lumen.profile") || "{}");
    return { lang: document.documentElement.lang, set: LUMEN.app.profile.settings.lang, stored: stored.settings && stored.settings.lang,
      menu: document.querySelector(".menu").textContent, tag: document.querySelector(".logo .tag").textContent };
  });
  ok(r0.lang === "ru" && r0.set === "ru" && r0.stored === "ru", "a Russian browser starts in Russian and saves it", r0);
  ok(/Кампания/.test(r0.menu) && /Настройки/.test(r0.menu) && !/Campaign|Settings/.test(r0.menu) && /тьму/.test(r0.tag), "title menu is in Russian", r0.menu);
  // Settings -> English with the keyboard
  await rp.evaluate(function () { LUMEN.app.go("settings"); }); await wait(500);
  ok(await rp.evaluate(function () { return document.querySelector(".screen-head h2").textContent === "Настройки" && document.querySelectorAll(".lang-row [data-lang]").length === 2; }),
    "Settings has a language switch (English / Русский)");
  await rp.click(".lang-row [data-lang=en]"); await wait(500);
  var r1 = await rp.evaluate(function () {
    return { h: document.querySelector(".screen-head h2").textContent, lang: document.documentElement.lang, set: LUMEN.app.profile.settings.lang,
      sel: document.querySelector(".lang-row .sel").getAttribute("data-lang") };
  });
  ok(r1.h === "Settings" && r1.lang === "en" && r1.set === "en" && r1.sel === "en", "switching to English re-renders Settings in English", r1);
  await rp.reload(); await wait(900);
  ok(await rp.evaluate(function () { return LUMEN.i18n.lang === "en" && /Campaign/.test(document.querySelector(".menu").textContent); }),
    "the choice persists over a Russian browser after a reload");
  await rp.evaluate(function () { LUMEN.app.go("settings"); }); await wait(500);
  await rp.click(".lang-row [data-lang=ru]"); await wait(500);
  await rp.keyboard.press("Escape"); await wait(500);
  await rp.keyboard.press("Enter"); await wait(900);
  var rs = await rp.evaluate(function () { return { screen: document.querySelector(".screen.active").getAttribute("data-screen"), text: document.querySelector(".story .lines").textContent,
    btn: document.querySelector(".story-skip").textContent }; });
  ok(rs.screen === "story" && /Мир погрузился во тьму/.test(rs.text) && /Продолжить/.test(rs.btn), "the story intro is told in Russian", rs);
  await wait(800); await rp.keyboard.press("Enter"); await wait(900);
  ok(await rp.evaluate(function () { return /Шепчущий сад/.test(document.querySelector(".worlds").textContent); }), "world names on the map are in Russian");
  await rp.keyboard.press("Enter"); await wait(500);
  ok(await rp.evaluate(function () { return /Поймай 8 звёзд/.test(document.querySelector(".card .goal").textContent) && /Первый росток/.test(document.querySelector(".card h2").textContent); }),
    "the level card goal and name are in Russian");
  await rp.keyboard.press("Enter"); await waitFor(rp, playing);
  var rh = await rp.evaluate(function () { return { tag: document.getElementById("hud-tag").textContent, goal: document.getElementById("hud-goal-text").textContent,
    label: document.getElementById("hud-score-label").textContent, time: document.getElementById("hud-time-label").textContent }; });
  ok(rh.tag === "Уровень 1-1" && /^Звёзды 0 \/ 8$/.test(rh.goal) && rh.label === "Свет" && rh.time === "Время", "the HUD is in Russian", rh);
  await rp.keyboard.press("Space"); await wait(500);
  ok(await rp.evaluate(function () { return document.querySelector(".card h2").textContent === "Пауза"; }), "the pause card is in Russian");
  await rp.evaluate(function () { LUMEN.app.quit("title"); }); await wait(1200);
  await rp.evaluate(function () { LUMEN.app.go("trophies"); }); await wait(700);
  var rt = await rp.evaluate(function () { var el = document.querySelector(".screen.active"); return { screen: el.getAttribute("data-screen"), text: el.textContent.slice(0, 600) }; });
  ok(rt.screen === "trophies" && /Первый свет/.test(rt.text) && /Поймай свою первую упавшую звезду/.test(rt.text) && !/First Light/.test(rt.text),
    "achievement names and descriptions are in Russian", rt);
  await rp.evaluate(function () { LUMEN.app.go("settings"); }); await wait(500);
  var rq = await rp.evaluate(function () { return { label: document.querySelector(".quality-row label").textContent,
    names: Array.prototype.map.call(document.querySelectorAll(".quality-row [data-quality]"), function (b) { return b.textContent; }).join(",") }; });
  ok(/Графика/.test(rq.label) && rq.names === "Авто,Низкая,Средняя,Высокая", "the Graphics setting is in Russian", rq);
  ok(rerr.length === 0, "no console errors while switching languages", rerr);
  await ru.close();

  // Russian on a phone: nothing spills out of its box
  var rph = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: "ru" });
  var rmp = await rph.newPage();
  var rmerr = [];
  watch(rmp, rmerr);
  await rmp.goto(URL); await wait(900);
  await rmp.evaluate(function () { var p = LUMEN.app.profile; p.story.intro = 1; for (var i = 1; i <= 12; i++) p.levels[i] = { moons: 2, bestMs: 50000, bestScore: 200 }; });
  var spills = [];
  var views = [["title"], ["map"], ["level", { id: 12 }], ["endless"], ["daily"], ["trophies"], ["shop"], ["settings"], ["help"]];
  for (var v = 0; v < views.length; v++) {
    await rmp.evaluate(function (a) { LUMEN.app.go(a[0], a[1]); }, views[v]); await wait(450);
    var sp = await rmp.evaluate(function () {
      var bad = [];
      if (document.documentElement.scrollWidth > innerWidth) bad.push("page " + document.documentElement.scrollWidth);
      document.querySelectorAll(".screen.active .btn, .screen.active h2, .screen.active .row label, .screen.active .card, .screen.active .tab").forEach(function (e) {
        if (e.scrollWidth > e.clientWidth + 1) bad.push(e.className + ": " + e.textContent.slice(0, 24));
        var r = e.getBoundingClientRect(); if (r.right > innerWidth + 1 || r.left < -1) bad.push("out " + e.className + ": " + e.textContent.slice(0, 24));
      });
      return bad;
    });
    if (sp.length) spills.push(views[v][0] + " " + sp.join(" | "));
  }
  ok(spills.length === 0, "Russian text fits every menu screen on a phone", spills);
  await rmp.evaluate(function () { LUMEN.app.startLevel(12); }); await waitFor(rmp, playing);
  var rhud = await rmp.evaluate(function () {
    var rs = Array.prototype.slice.call(document.querySelectorAll("#hud .chip, #hud-pause")).map(function (e) { return e.getBoundingClientRect(); })
      .filter(function (r) { return r.width > 0 && r.top < 80; }).sort(function (x, y) { return x.left - y.left; });
    var overlap = false;
    for (var i = 1; i < rs.length; i++) if (rs[i - 1].right > rs[i].left + 1) overlap = true;
    return { overlap: overlap, n: rs.length, right: Math.max.apply(null, rs.map(function (r) { return r.right; })), vw: innerWidth };
  });
  ok(!rhud.overlap && rhud.right <= rhud.vw, "Russian HUD chips fit side by side on a phone", rhud);
  ok(rmerr.length === 0, "no console errors on the Russian phone", rmerr);
  await rph.close();

  // ---------------- storage blocked ----------------
  console.log("storage blocked");
  var blocked = await browser.newContext({ viewport: { width: 1000, height: 700 }, locale: "en-US" });
  await blocked.addInitScript(function () {
    Object.defineProperty(window, "localStorage", { get: function () { throw new Error("SecurityError: blocked"); } });
  });
  var bp = await blocked.newPage();
  var berr = [];
  watch(bp, berr);
  await bp.goto(URL);
  await wait(900);
  ok(await bp.evaluate(function () { return !!LUMEN.app && LUMEN.app.storage.ok === false; }), "game still boots when localStorage throws");
  await bp.keyboard.press("Enter"); await wait(900); await bp.keyboard.press("Enter"); await wait(1000);
  await bp.keyboard.press("Enter"); await wait(500); await bp.keyboard.press("Enter");
  ok(await waitFor(bp, playing), "and is playable");
  ok(berr.length === 0, "with no console errors", berr);
  await blocked.close();

  // ---------------- no WebGL ----------------
  console.log("no WebGL");
  for (var lang of ["en-US", "ru-RU"]) {
    var nogl = await browser.newContext({ viewport: { width: 1000, height: 700 }, locale: lang });
    await nogl.addInitScript(function () {
      var orig = HTMLCanvasElement.prototype.getContext;
      HTMLCanvasElement.prototype.getContext = function (type) { if (/webgl/.test(type)) return null; return orig.apply(this, arguments); };
    });
    var np = await nogl.newPage();
    var nerr = [];
    watch(np, nerr);
    await np.goto(URL); await wait(1800);
    var ng = await np.evaluate(function () { var n = document.getElementById("no3d"), t = n ? n.textContent : ""; return { gl: LUMEN.app.webgl(), text: t, c3: !!document.getElementById("view3d") }; });
    var want = lang === "en-US" ? /WebGL is not available.*Snake: Lumen.*2D/ : /WebGL здесь недоступен.*Snake: Lumen.*2D/;
    ok(!ng.gl && !ng.c3 && want.test(ng.text), "without WebGL a " + lang + " notice points to the 2D version", ng);
    await np.evaluate(function () { var p = LUMEN.app.profile; p.story.intro = 1; LUMEN.app.startLevel(1); }); await waitFor(np, playing);
    ok(await np.evaluate(function () { return LUMEN.app.phase === "play" && LUMEN.app.scene.layoutBox.w > 100; }), "and the game still plays in 2D (" + lang + ")");
    ok(nerr.length === 0, "with no console errors (" + lang + ")", nerr);
    await nogl.close();
  }

  await browser.close();
  console.log("\n" + passed + " passed, " + failed + " failed");
  process.exit(failed ? 1 : 0);
})().catch(function (e) { console.error(e); process.exit(1); });
