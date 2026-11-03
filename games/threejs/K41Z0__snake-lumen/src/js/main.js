window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var C = LM.config;
  var P = LM.profile;
  var $ = function (id) { return document.getElementById(id); };

  // ---------- the pieces ----------
  var storage = new LM.Storage(C.storageKey);
  var profile = storage.load();
  var synth = new LM.Synth();
  var music = new LM.Music(synth);
  var scene = new LM.Scene($("view"));
  // three.js draws the runs; without WebGL the 2D renderer carries on alone
  var webgl = !!(LM.K3 && LM.K3.available() && !/[?&]2d\b/.test(location.search));
  if (webgl) {
    var w3 = new LM.World3D(scene);
    try { if (w3.init(profile.settings.quality)) scene.three = w3; } catch (e) { scene.three = null; }
  }
  var hud = new LM.Hud();
  var screens = new LM.dom.Screens($("screens"), { uiMove: function () { sfx("uiMove"); }, uiBack: function () { sfx("uiBack"); } });
  var toasts = new LM.Toasts($("toasts"), function (item) {
    if (item.kind !== "ach") return;
    synth.achievement(item.a.rarity);
    var colors = item.a.rarity === "gold" ? ["#ffd98a", "#fff3bf", "#ffd43b"] : item.a.rarity === "silver" ? ["#e9ecef", "#adb5bd", "#ffffff"] : ["#e8a87c", "#d08a52", "#fff3bf"];
    scene.particles.burst(scene.w - Math.min(180, scene.w / 2), 50, colors, 26, 260, { kind: "confetti", gravity: 70, drag: 1.6, life: 1.4, size: 3 });
  });

  var app = {
    profile: profile,
    storage: storage,
    synth: synth,
    music: music,
    scene: scene,
    game: null,
    demo: null,
    phase: "menu",
    world: 0,
    worldFrom: 0,
    worldMix: 1,
    boardWorld: 0,
    countdown: null,
    endAt: 0,
    t: 0,
    touch: false,
    lastCheck: 0,
    light: 0.3,
    story: null
  };

  function sfx(name, arg) {
    if (synth[name]) synth[name](arg);
  }
  app.sfx = sfx;

  app.vibrate = function (pattern) {
    if (!profile.settings.vibration || !navigator.vibrate) return;
    try { navigator.vibrate(pattern); } catch (e) { /* not allowed */ }
  };

  app.save = function () {
    storage.save(profile);
  };

  app.toast = function (text) {
    var note = $("note");
    note.textContent = text;
    note.classList.add("show");
    clearTimeout(app._noteTimer);
    app._noteTimer = setTimeout(function () { note.classList.remove("show"); }, 1600);
  };

  // language: saved choice, else the browser's, else English
  function staticText() {
    document.documentElement.lang = LM.i18n.lang;
    var map = { "hud-score-label": "hud.lightLabel" };
    for (var id in map) if ($(id)) $(id).textContent = LM.t(map[id]);
    if ($("hud-pause")) $("hud-pause").setAttribute("aria-label", LM.t("hud.pause"));
    if ($("view")) $("view").setAttribute("aria-label", LM.t("aria.board"));
    var dirs = document.querySelectorAll("[data-dir]");
    for (var i = 0; i < dirs.length; i++) dirs[i].setAttribute("aria-label", LM.t("aria." + dirs[i].getAttribute("data-dir")));
  }
  app.setLanguage = function (lang) {
    profile.settings.lang = LM.i18n.set(lang);
    app.save();
    staticText();
    if (app.game) hud.show(app.game);
  };
  if (!profile.settings.lang) {
    var nav = (navigator.languages && navigator.languages[0]) || navigator.language || "";
    profile.settings.lang = LM.i18n.detect(nav);
    storage.save(profile);
  }
  LM.i18n.set(profile.settings.lang);
  staticText();

  app.applySettings = function () {
    var s = profile.settings;
    synth.setVolumes(s.music, s.sfx, s.muted);
    document.body.classList.toggle("reduced", !!s.reducedFlash);
    if (scene.three) scene.three.setQuality(s.quality);
  };
  app.webgl = function () { return !!(scene.three && scene.three.ok); };
  app.scene3dLevel = function () { return scene.three && scene.three.qName ? scene.three.qName : "low"; };

  app.checkAchievements = function (extra) {
    var ctx = extra || {};
    if (ctx.run === undefined) ctx.run = null;
    var fresh = LM.achievements.evaluate(profile, ctx);
    fresh.forEach(function (a) { toasts.achievement(a); });
    if (fresh.length) app.save();
    return fresh;
  };

  // ---------- worlds and backdrop ----------
  function setWorld(w, instant) {
    if (w === app.world) return;
    app.worldFrom = app.world;
    app.world = w;
    app.worldMix = instant ? 1 : 0;
  }

  // ---------- light ----------
  // How much light the current world has back, 0..1: part from the levels of
  // this world already restored, most from the stars caught in this run.
  function targetLight(g) {
    if (!g) return 0.3;
    var n = g.snake.length();
    if (g.mode === "demo") return 0.2 + 0.8 * Math.min(1, (n - 4) / 26);
    if (g.mode === "campaign") {
      var lv = LM.levels.ofWorld(g.level.world);
      var done = lv.filter(function (l) { return P.levelMoons(profile, l.id) > 0; }).length;
      var run = g.status === "won" ? 1 : LM.levels.progress(g.level.goal, g);
      return Math.min(1, 0.1 + 0.35 * (done / lv.length) + 0.55 * run);
    }
    // endless: each new world starts dark and lights up over its twelve stars
    if (g.mode === "endless") return 0.12 + 0.8 * ((g.eaten % C.endless.worldEvery) / C.endless.worldEvery);
    return Math.min(1, 0.12 + 0.88 * g.eaten / 20);
  }
  app.targetLight = targetLight;

  // ---------- story ----------
  app.openCampaign = function () {
    if (!profile.story.intro) app.playStory("intro", { then: "map" });
    else app.go("map");
  };

  app.playStory = function (kind, opts) {
    opts = opts || {};
    profile.story[kind] = 1;
    app.save();
    app.wipe(function () {
      app.go("story", { kind: kind });
      app.phase = "story";
      app.story = { kind: kind, at: app.t, then: opts.then || "title", view: new LM.story.StoryView() };
      var def = LM.story.scenes[kind];
      if (synth.ctx) { music.play(def.music); music.duck(false); }
    });
  };

  app.endStory = function () {
    var s = app.story;
    if (!s) return;
    app.story = null;
    var then = s.then;
    if (typeof then === "function") {
      app.phase = "menu";
      then();
      return;
    }
    app.wipe(function () {
      app.phase = "menu";
      app.go(then);
    });
  };

  // ---------- screens ----------
  var OVERLAYS = { pause: 1, results: 1 };

  app.go = function (name, params) {
    if (!OVERLAYS[name] && !(name === "settings" && params && params.from === "pause")) {
      if (app.game) leaveGame();
    }
    // the level card shows the world it belongs to; other menus follow the demo
    if (name === "level" && params && LM.levels.byId(params.id)) {
      app.heldWorld = true;
      if (app.phase !== "playing") setWorld(LM.levels.byId(params.id).world, false);
    } else if (!OVERLAYS[name] && app.heldWorld) {
      app.heldWorld = false;
      if (app.demo && app.phase === "menu") setWorld(app.demo.level.world, false);
    }
    var def = LM.screens[name](app, params || {});
    screens.show(name, def);
    if (name === "title" && synth.ctx) music.play("title");
    if (name !== "story" && app.phase === "story") { app.phase = "menu"; app.story = null; }
  };

  function leaveGame() {
    app.game = null;
    app.phase = "menu";
    app.countdown = null;
    hud.hide();
    $("pad").hidden = true;
    scene.particles.clear();
    layoutReserve();
    if (!app.demo) newDemo();
    setWorld(app.demo.level.world, false);
    if (synth.ctx) { music.play("title"); music.duck(false); }
  }

  app.wipe = function (fn) {
    var wipe = $("wipe");
    wipe.classList.add("cover");
    setTimeout(function () {
      fn();
      setTimeout(function () { wipe.classList.remove("cover"); }, 60);
    }, 400);
  };

  // ---------- starting runs ----------
  function begin(game) {
    app.wipe(function () {
      screens.hide();
      app.game = game;
      app.phase = "countdown";
      app.countdown = { at: app.t, fast: false };
      app.boardWorld = game.level.world;
      setWorld(game.level.world, true);
      app.light = targetLight(game);
      scene.particles.clear();
      scene.snakeView = new LM.SnakeView();
      hud.show(game);
      hud.update(game);
      $("pad").hidden = !app.touch;
      layoutReserve();
      music.playWorld(game.level.world);
      music.duck(false);
      game.takeEvents();
      app.runHour = new Date().getHours();
    });
  }

  app.startLevel = function (id) {
    var lv = LM.levels.byId(id);
    if (!lv || !P.levelUnlocked(profile, id)) return;
    var key = "w" + lv.world;
    if (lv.world > 0 && lv.index % 5 === 0 && !profile.story[key]) {
      app.playStory(key, { then: function () { app.startLevel(id); } });
      return;
    }
    app.lastStart = { kind: "level", id: id };
    begin(new LM.Game({ level: lv, mode: "campaign" }));
  };

  app.startEndless = function () {
    app.lastStart = { kind: "endless" };
    begin(new LM.Game({ level: LM.levels.endless(), mode: "endless" }));
  };

  app.startDaily = function () {
    var lv = LM.daily.level(LM.daily.dateKey());
    app.lastStart = { kind: "daily" };
    begin(new LM.Game({ level: lv, mode: "daily", seed: lv.seed }));
  };

  app.restart = function () {
    var s = app.lastStart || { kind: "endless" };
    if (app.game) bookRun(true);
    if (s.kind === "level") app.startLevel(s.id);
    else if (s.kind === "daily") app.startDaily();
    else app.startEndless();
  };

  app.pause = function () {
    if (app.phase !== "play" || !app.game || !app.game.pause()) return;
    app.phase = "paused";
    music.duck(true);
    sfx("uiSelect");
    app.go("pause");
    app.checkAchievements({ run: app.game, hour: app.runHour });
  };

  app.resume = function () {
    if (app.phase !== "paused") return;
    screens.hide();
    music.duck(false);
    app.phase = "countdown";
    app.countdown = { at: app.t, fast: true, resume: true };
  };

  app.quit = function (to, params) {
    if (app.game && app.phase !== "results") bookRun(true);
    app.wipe(function () { app.go(to || "title", params); });
  };

  // Abandoned runs still count their play time and stars, not a result.
  function bookRun(abandoned) {
    var g = app.game;
    if (!g || g.booked) return;
    g.booked = true;
    if (abandoned) {
      profile.stats.playMs += g.elapsedMs;
      app.save();
    }
  }

  app.resetProgress = function () {
    storage.clear();
    var fresh = P.create();
    fresh.settings = profile.settings;
    for (var k in profile) delete profile[k];
    for (k in fresh) profile[k] = fresh[k];
    app.save();
    app.toast(LM.t("note.reset"));
    app.go("title");
  };

  // ---------- game events -> effects ----------
  function handleEvents(g) {
    var events = g.takeEvents();
    if (!events.length) return;
    var L = scene.layoutBox;
    var check = false;
    for (var i = 0; i < events.length; i++) {
      var e = events[i];
      var pt = e.cell ? scene.cellCenter(e.cell) : null;
      switch (e.type) {
        case "eat":
          P.onEvent(profile, e);
          check = true;
          scene.snakeView.pop(app.t);
          if (e.golden) {
            scene.particles.burst(pt.x, pt.y, ["#fff3bf", "#ffd43b", "#ffffff", "#ffd98a"], 46, L.cell * 9, { size: L.cell * 0.14, life: 0.9 });
            scene.particles.ring(pt.x, pt.y, "#fff3bf", L.cell * 2.4, 0.6);
            scene.flash("#ffe8a3", 0.25);
            sfx("golden");
            app.vibrate(25);
          } else {
            scene.particles.burst(pt.x, pt.y, ["#ffd98a", "#fff3bf", "#ffffff"], 18, L.cell * 6, { size: L.cell * 0.1 });
            scene.particles.ring(pt.x, pt.y, "rgba(255,217,138,.9)", L.cell * 1.3, 0.35);
            sfx("eat", e.combo);
          }
          scene.particles.text(pt.x, pt.y - L.cell * 0.6, "+" + e.points, e.golden ? "#fff3bf" : "#ffd98a", Math.max(13, L.cell * 0.7));
          if (e.combo === 5 || e.combo === 10 || e.combo === 15) {
            scene.showBanner(LM.t(e.combo >= 10 ? "banner.nova" : "banner.spark", { n: e.combo }), e.combo >= 10 ? "#fff3bf" : "#ffd98a", app.t);
            sfx("combo", e.combo);
          }
          break;
        case "powerup":
          P.onEvent(profile, e);
          check = true;
          var col = C.powerups[e.effect].color;
          scene.particles.burst(pt.x, pt.y, [col, "#ffffff"], 30, L.cell * 8, { size: L.cell * 0.12 });
          scene.particles.ring(pt.x, pt.y, col, L.cell * 3, 0.6);
          scene.showBanner(LM.t("banner.power", { name: LM.L.power(e.effect) }), col, app.t);
          sfx("powerup", e.effect);
          app.vibrate(20);
          break;
        case "effectEnd":
          sfx("powerEnd");
          check = true;
          break;
        case "portal":
          var a = scene.cellCenter(e.from), b = scene.cellCenter(e.to);
          scene.particles.ring(a.x, a.y, "#dbe8ff", L.cell * 1.6, 0.4);
          scene.particles.ring(b.x, b.y, "#dbe8ff", L.cell * 1.6, 0.5);
          scene.particles.burst(b.x, b.y, "#8fb8ff", 10, L.cell * 4, { size: L.cell * 0.08 });
          sfx("portal");
          break;
        case "ghostPass":
          scene.particles.burst(pt.x, pt.y, "#c9a8ff", 6, L.cell * 3, { size: L.cell * 0.08 });
          sfx("ghostPass");
          check = true;
          break;
        case "turn":
          sfx("turn");
          break;
        case "spawn":
          scene.particles.ring(pt.x, pt.y, e.what === "golden" ? "#fff3bf" : C.powerups[e.effect].color, L.cell * 1.5, 0.5);
          if (e.what === "golden") sfx("combo", 8);
          break;
        case "expire":
          scene.particles.burst(pt.x, pt.y, "rgba(200,200,220,.5)", 8, L.cell * 2, { kind: "smoke", size: L.cell * 0.15, life: 0.5 });
          sfx("expire");
          break;
        case "worldShift":
          setWorld(e.world, false);
          app.boardWorld = e.world;
          music.playWorld(e.world);
          scene.showBanner(LM.t("banner.onward", { w: LM.L.world(e.world) }), LM.themes[e.world].accent, app.t);
          break;
        case "crash":
          var hp = scene.cellCenter(g.snake.head());
          var skin = LM.SnakeView.skinById(profile.skins.selected);
          scene.particles.burst(hp.x, hp.y, [skin.colors[0], skin.colors[1], "#ffffff"], 40, L.cell * 10, { size: L.cell * 0.13, life: 0.8 });
          scene.particles.burst(hp.x, hp.y, "rgba(120,120,140,.45)", 12, L.cell * 3, { kind: "smoke", size: L.cell * 0.25, life: 0.8 });
          scene.shake(L.cell * 0.9);
          scene.flash("#1a1430", 0.45);
          sfx("crash");
          app.vibrate([60, 40, 120]);
          break;
        case "over":
          endRun(g, e.won);
          break;
      }
    }
    if (check) app.checkAchievements({ run: g, hour: app.runHour });
  }

  function endRun(g, won) {
    app.phase = "ending";
    app.endAt = app.t + (won ? 0.7 : 1.1);
    var extra = { dateKey: LM.daily.dateKey() };
    g.booked = true;
    app.summary = P.finishRun(profile, g, extra);
    app.save();
    if (won) {
      sfx("win");
      var L = scene.layoutBox;
      for (var i = 0; i < 3; i++) {
        scene.particles.burst(L.ox + L.w * (0.2 + i * 0.3), L.oy + L.h * 0.3, ["#ffd98a", "#fff3bf", "#e6ebff", "#cfdcff", "#ffffff"], 30,
          L.cell * 12, { kind: "confetti", gravity: L.cell * 4, drag: 1.6, life: 1.8, size: L.cell * 0.12 });
      }
    } else {
      sfx("lose");
    }
    music.duck(true);
    app.checkAchievements({ run: g, over: true, won: won, hour: app.runHour });
  }

  function showResults() {
    app.phase = "results";
    var g = app.game;
    app.go("results", {
      summary: app.summary,
      finale: g.mode === "campaign" && g.status === "won" && g.level.id === LM.levels.list.length && !profile.story.finale,
      onMoons: function (el, n) {
        for (var i = 0; i < n; i++) {
          (function (k) {
            setTimeout(function () {
              var st = el.children[k];
              if (!st) return;
              st.classList.add("on");
              sfx("moonChime", k);
              var r = st.getBoundingClientRect();
              scene.particles.burst(r.left + r.width / 2, r.top + r.height / 2, ["#e6ebff", "#fff3bf"], 22, 260, { size: 3.5 });
            }, 420 + k * 380);
          })(i);
        }
      }
    });
    void g;
  }

  // ---------- input ----------
  var DIRS = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };

  var input = new LM.Input(function (action, source) {
    synth.ensure();
    if (!music.name && app.phase === "menu") music.play("title");
    if (action === "mute") {
      profile.settings.muted = !profile.settings.muted;
      app.applySettings();
      app.save();
      app.toast(LM.t(profile.settings.muted ? "note.soundOff" : "note.soundOn"));
      return;
    }
    var playing = app.phase === "play" || app.phase === "countdown";
    if (playing && app.game) {
      if (DIRS[action]) {
        app.game.turn(DIRS[action][0], DIRS[action][1]);
        return;
      }
      if (action === "pause" || action === "back") {
        if (app.phase === "play") app.pause();
        return;
      }
      return;
    }
    if (app.phase === "ending") {
      if (action === "confirm" || action === "pause") app.endAt = Math.min(app.endAt, app.t + 0.15);
      return;
    }
    if (action === "tap") return;
    if (source === "swipe") return;
    screens.handle(action);
  });

  input.onKonami = function () {
    if (screens.name !== "title" || profile.flags.konami) return;
    profile.flags.konami = true;
    P.grantSkin(profile, "prism");
    app.save();
    sfx("buy");
    app.toast(LM.t("note.konami"));
    app.checkAchievements(null);
  };

  hud.onPause = function () { app.pause(); };

  // ---------- layout ----------
  function layoutReserve() {
    var portrait = window.innerHeight >= window.innerWidth;
    var pad = $("pad");
    pad.classList.toggle("side", app.touch && !portrait);
    if (app.game) {
      var hudBottom = 70;
      var hudEl = $("hud");
      if (!hudEl.hidden) hudBottom = hudEl.getBoundingClientRect().bottom + 8;
      var r = { top: hudBottom, bottom: 14, left: 12, right: 12 };
      if (app.touch && portrait) r.bottom = 152;
      if (app.touch && !portrait) { r.right = 220; r.left = 12; }
      if (!portrait && window.innerHeight <= 520) {
        // short landscape: the HUD is a column on the left
        r.top = 10;
        r.left = hudEl.hidden ? 12 : hudEl.getBoundingClientRect().right + 10;
      }
      scene.setReserve(r);
    } else {
      scene.setReserve({ top: 24, bottom: 24, left: 24, right: 24 });
    }
  }

  function resize() {
    scene.resize();
    layoutReserve();
  }

  // ---------- attract-mode demo behind the menus ----------
  var DEMO_LEVELS = [2, 6, 12, 16];
  function newDemo() {
    var w = app.demo ? (app.demo.level.world + 1) % 4 : 0;
    var base = LM.levels.byId(DEMO_LEVELS[w]);
    var lv = {};
    for (var k in base) lv[k] = base[k];
    lv.tick = 110;
    lv.goal = null;
    app.demo = new LM.Game({ level: lv, mode: "demo" });
    app.demo.start();
    app.demoAge = 0;
    if (app.phase === "menu" && !app.heldWorld) setWorld(w, false);
  }

  function stepDemo(dtMs) {
    var d = app.demo;
    if (!d) return;
    if (d.status === "running") {
      if (!d.snake.queue.length) {
        var dir = LM.autopilot.choose(d);
        d.turn(dir.x, dir.y);
      }
      d.update(dtMs);
      d.takeEvents();
    }
    app.demoAge += dtMs;
    if (d.status !== "running" && app.demoAge > 0) {
      if (!d.deadAt) d.deadAt = app.t;
      if (app.t - d.deadAt > 1.2) newDemo();
    } else if (d.snake.length() > 34 || app.demoAge > 26000) {
      newDemo();
    }
  }

  // ---------- the frame loop ----------
  var last = 0;
  function frame(ts) {
    requestAnimationFrame(frame);
    if (!last) last = ts;
    var rawMs = Math.min(250, ts - last);
    last = ts;
    var dt = Math.min(0.05, rawMs / 1000);
    app.t += dt;
    if (app.worldMix < 1) app.worldMix = Math.min(1, app.worldMix + dt / 1.2);

    var g = app.game;
    if (app.phase === "story" && app.story) {
      var st = app.story;
      if (scene.three) scene.three.setVisible(false);
      scene.ctx.setTransform(scene.dpr, 0, 0, scene.dpr, 0, 0);
      st.view.draw(scene.ctx, scene, st.kind, app.t - st.at, app.t, LM.SnakeView.skinById(profile.skins.selected));
      scene.particles.update(dt);
      scene.particles.draw(scene.ctx);
      return;
    }
    if (g) {
      app.light += (targetLight(g) - app.light) * Math.min(1, dt * 1.5);
      if (app.phase === "countdown" && app.countdown) {
        var step = app.countdown.fast ? 0.35 : 0.55;
        var el = app.t - app.countdown.at;
        var idx = Math.floor(el / step);
        if (idx !== app.countdown.idx) {
          app.countdown.idx = idx;
          if (idx < 3) sfx("count", false);
          else if (idx === 3) {
            sfx("count", true);
            if (app.countdown.resume) g.resume(); else g.start();
            app.phase = "play";
          }
        }
        app.countdown.text = idx < 3 ? String(3 - idx) : LM.t("go");
        app.countdown.k = 1 - (el - idx * step) / step;
      } else if (app.phase === "play" && app.countdown) {
        var el2 = app.t - app.countdown.at, st2 = app.countdown.fast ? 0.35 : 0.55;
        app.countdown.k = 1 - (el2 - 3 * st2) / st2;
        if (app.countdown.k <= 0) app.countdown = null;
      }
      if (app.phase === "play") {
        g.update(rawMs);
        hud.update(g);
        if (app.t - app.lastCheck > 1) {
          app.lastCheck = app.t;
          app.checkAchievements({ run: g, hour: app.runHour });
        }
      }
      handleEvents(g);
      if (app.phase === "ending" && app.t >= app.endAt) showResults();
      scene.render({
        game: g, world: app.world, worldFrom: app.worldFrom, worldMix: app.worldMix, boardWorld: app.boardWorld,
        light: app.light, t: app.t, dt: dt, skin: LM.SnakeView.skinById(profile.skins.selected), settings: profile.settings,
        countdown: app.countdown && app.countdown.k > 0 ? app.countdown : null
      });
    } else {
      stepDemo(rawMs);
      app.light += (targetLight(app.demo) - app.light) * Math.min(1, dt * 1.2);
      scene.render({
        light: app.light,
        // menus show the world alone; the unseen demo run slowly wakes it
        game: null, world: app.world, worldFrom: app.worldFrom, worldMix: app.worldMix,
        boardWorld: app.demo ? app.demo.level.world : app.world, t: app.t, dt: dt,
        skin: LM.SnakeView.skinById(profile.skins.selected), settings: profile.settings
      });
    }
  }

  // ---------- boot ----------
  app.touch = !!(window.matchMedia && window.matchMedia("(pointer: coarse)").matches) || ("ontouchstart" in window && navigator.maxTouchPoints > 0);
  app.applySettings();
  resize();
  window.addEventListener("resize", resize);
  window.addEventListener("orientationchange", resize);
  document.addEventListener("visibilitychange", function () {
    if (document.hidden) { if (app.phase === "play") app.pause(); app.save(); }
  });
  window.addEventListener("blur", function () { if (app.phase === "play") app.pause(); });
  window.addEventListener("pagehide", function () { app.save(); });
  // the first gesture unlocks audio
  ["pointerdown", "keydown", "touchstart"].forEach(function (ev) {
    window.addEventListener(ev, function once() {
      synth.ensure();
      app.applySettings();
      if (!music.name && !app.game) music.play("title");
      window.removeEventListener(ev, once);
    }, { passive: true });
  });

  newDemo();
  setWorld(0, true);
  app.go("title");
  // catch anything an older save already qualifies for
  setTimeout(function () { app.checkAchievements(null); }, 1200);
  if (!storage.ok) setTimeout(function () { app.toast(LM.t("note.storage")); }, 900);
  // no WebGL: say so (in the player's language) and keep playing in 2D
  if (!scene.three) {
    var no3d = document.createElement("div");
    no3d.id = "no3d";
    no3d.className = "no3d";
    no3d.setAttribute("role", "status");
    no3d.textContent = LM.t("note.no3d");
    no3d.addEventListener("click", function () { no3d.classList.add("gone"); });
    document.body.appendChild(no3d);
    setTimeout(function () { no3d.classList.add("gone"); }, 12000);
  }
  requestAnimationFrame(frame);

  LM.app = app;
})(window.LUMEN);
