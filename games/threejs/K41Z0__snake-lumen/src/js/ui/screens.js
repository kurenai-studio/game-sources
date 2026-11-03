window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var h = function () { return LM.dom.h.apply(null, arguments); };
  var C = LM.config;
  var P = LM.profile;
  var t = function (k, v) { return LM.t(k, v); };
  var L = LM.L;

  function backBtn(app, to) {
    return h("button.btn.back-btn", { "data-nav": "", onclick: function () { app.sfx("uiBack"); to(); } }, [t("back") + " ", h("span.k", "Esc")]);
  }

  function walletPill(app) {
    return h("span.pill", { title: t("wallet.title") }, [h("img", { src: LM.icons.star(44), alt: "" }), h("span.wallet", String(app.profile.wallet))]);
  }

  function head(app, title, sub, extra, back) {
    return h("div.screen-head", [backBtn(app, back), h("div", { style: { flex: "1" } }, [h("h2", title), sub ? h("div.sub", sub) : null]), extra]);
  }

  function mechanics(level) {
    var out = [];
    var b = new LM.Board(level);
    if (b.walls.some(function (v) { return v; })) out.push(t("mech.walls"));
    if (level.wrap) out.push(t("mech.wrap"));
    if (b.portalList.length) out.push(t("mech.gates"));
    if (b.movers.length) out.push(t(level.world === 2 ? "mech.rocks" : level.world === 3 ? "mech.shadows" : "mech.trams"));
    if (b.phase.length) out.push(t("mech.eclipse"));
    if (level.items) out.push(t("mech.powerups"));
    if (level.dark) out.unshift(t("mech.dark"));
    return out;
  }

  // "Press {enter} to ..." with the placeholders turned into key caps
  function kbdLine(text) {
    var keys = { enter: "Enter", esc: "Esc", m: "M" };
    return text.split(/(\{\w+\})/).map(function (part) {
      var m = /^\{(\w+)\}$/.exec(part);
      return m && keys[m[1]] ? h("kbd", keys[m[1]]) : part;
    });
  }

  // ---------------- title ----------------
  function title(app) {
    var p = app.profile;
    var total = LM.achievements.list.length;
    var today = LM.daily.dateKey();
    function item(label, ico, meta, fn, primary) {
      return h("button.btn" + (primary ? ".primary" : ""), { "data-nav": "", onclick: function () { app.sfx("uiSelect"); fn(); } },
        [h("span.ico", ico), h("span.lbl", label), h("span.meta", meta || "")]);
    }
    var cleared = LM.levels.list.filter(function (l) { return P.levelMoons(p, l.id) > 0; }).length;
    var el = h("div.clear", h("div.title-wrap", [
      h("div.logo", [
        h("img.logo-img", { src: LM.logo(320), alt: "" }),
        h("p.brand-pre", { "aria-hidden": "true" }, [h("i"), h("span", "SNAKE"), h("i")]),
        h("h1", { "aria-label": "Snake: Lumen" }, "LUMEN".split("").map(function (ch, i) { return h("span.ch", { style: { "animation-delay": (i * 0.12) + "s" } }, ch); })),
        h("p.tag", t("title.tag"))
      ]),
      h("div.menu", [
        item(t("menu.campaign"), "\u25B6", cleared + " / 20", function () { app.openCampaign(); }, true),
        item(t("menu.endless"), "\u221E", p.stats.bestEndless ? t("menu.best", { n: p.stats.bestEndless }) : "", function () { app.go("endless"); }),
        item(t("menu.daily"), "\u2726", p.daily[today] ? t("menu.today", { n: p.daily[today] }) : t("menu.new"), function () { app.go("daily"); }),
        item(t("menu.achievements"), "\u2605", LM.achievements.unlockedCount(p) + " / " + total, function () { app.go("trophies"); }),
        item(t("menu.shop"), "\u25C8", "", function () { app.go("shop"); }),
        item(t("menu.help"), "?", "", function () { app.go("help"); }),
        item(t("menu.settings"), "\u2699", "", function () { app.go("settings"); })
      ]),
      h("div.title-stats", [walletPill(app), h("span.pill.moon", String(P.totalMoons(p)) + " / 60")]),
      h("div.hint-line", kbdLine(t("title.hint")))
    ]));
    return { el: el };
  }

  // ---------------- world map ----------------
  // An old star chart: each world is a patch of sky, the levels are stars on
  // a path of light that runs toward the Moon (drawn by chart.js).
  var ZIG = [12, -12, 10, -10, 0];
  function nodePos(wi, j) {
    var k = wi * 5 + j;
    var lx = 10 + j * 20, ly = 76 - k * 2.9 + ZIG[j];
    var px = wi % 2 ? 88 - j * 19 : 12 + j * 19, py = j % 2 ? 68 : 32;
    return { "--lx": lx + "%", "--ly": ly.toFixed(1) + "%", "--px": px + "%", "--py": py + "%" };
  }

  function map(app, params) {
    var p = app.profile;
    var focus = null;
    var worlds = C.worlds.map(function (w, wi) {
      var open = P.worldUnlocked(p, wi);
      var nodes = LM.levels.ofWorld(wi).map(function (lv, j) {
        var st = P.levelMoons(p, lv.id);
        var unlocked = P.levelUnlocked(p, lv.id);
        var cls = (st > 0 ? ".cleared" : unlocked ? ".open" : "") + (lv.dark ? ".dark" : "");
        var node = h("button.node" + cls, { "data-nav": "", "data-world": String(wi), style: nodePos(wi, j), disabled: !unlocked,
          "aria-label": t("map.levelAria", { n: lv.number, name: L.level(lv) }) + (lv.dark ? ", " + t("map.darkAria") : ""),
          title: lv.number + " " + L.level(lv), onclick: function () { app.sfx("uiSelect"); app.go("level", { id: lv.id }); } },
          [h("span.dot", unlocked ? String((lv.index % 5) + 1) : "\uD83D\uDD12"), lv.dark ? h("img.dark-mark", { src: LM.icons.dark(40), alt: "" }) : null, LM.dom.moons(st)]);
        if ((params && params.focus === lv.id) || (!focus && unlocked && st === 0 && !(params && params.focus))) focus = node;
        return node;
      });
      return h("div.world.w" + wi + (open ? "" : ".locked"), [
        h("div.nodes", nodes),
        h("div.legend", [
          h("h3", [L.world(wi), h("span.ws", "\u263E " + P.worldMoons(p, wi) + " / 15")]),
          h("span.n", t("map.world", { n: wi + 1 })),
          h("p", L.blurb(wi)),
          open ? null : h("div.lockmsg", t("map.locked", { w: L.world(wi - 1) }))
        ])
      ]);
    });
    var canvas = h("canvas.chart-ink", { "aria-hidden": "true" });
    var chart = h("div.worlds.chart", [canvas].concat(worlds, [h("div.chart-moon")]));
    var all = LM.levels.list;
    LM.chart.attach(chart, canvas, function () {
      var cleared = all.map(function (lv) { return P.levelMoons(p, lv.id) > 0; });
      return {
        cleared: cleared,
        open: C.worlds.map(function (w, wi) { return P.worldUnlocked(p, wi); }),
        light: cleared.filter(Boolean).length / all.length
      };
    });
    var el = h("div", h("div.wrap", [
      head(app, t("menu.campaign"), t("map.sub"),
        h("div.title-stats", [walletPill(app), h("span.pill.moon", P.totalMoons(p) + " / 60")]), function () { app.go("title"); }),
      chart,
      h("div.btn-row", [h("button.btn.story-btn", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.playStory("intro", { then: "map" }); } }, t("map.replay"))])
    ]));
    return { el: el, back: function () { app.go("title"); }, focus: focus };
  }

  // ---------------- level card ----------------
  function level(app, params) {
    var p = app.profile;
    var lv = LM.levels.byId(params.id);
    var rec = p.levels[lv.id] || {};
    var st = rec.moons || 0;
    var crit = LM.levels.moonText(lv).map(function (t, i) {
      return h("div" + (st > i ? ".got" : ""), [h("span.s", "\u263E\u263E\u263E".slice(0, i + 1)), t]);
    });
    var play = h("button.btn.primary", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.startLevel(lv.id); } }, [t("level.play") + " ", h("span.k", "Enter")]);
    var el = h("div.overlay", h("div.card", [
      h("div.eyebrow", t("level.eyebrow", { w: L.world(lv.world), n: lv.number })),
      h("h2", L.level(lv)),
      lv.dark ? h("div.dark-tag", { title: t("level.darkText") }, [h("img", { src: LM.icons.dark(64), alt: "" }), h("div", [h("b", t("level.dark")), h("span", t("level.darkText"))])]) : null,
      h("div.goal", LM.levels.goalText(lv.goal)),
      h("div.mech", mechanics(lv).map(function (m) { return h("span", m); })),
      h("div.crit", crit),
      rec.bestMs ? h("div.facts", [
        h("div", [h("small", t("level.moons")), h("b", LM.dom.moons(st))]),
        h("div", [h("small", t("level.bestTime")), h("b", LM.levels.fmtTime(rec.bestMs / 1000))]),
        h("div", [h("small", t("level.mostLight")), h("b", String(rec.bestScore || 0))])
      ]) : null,
      h("div.btn-row", [backBtn(app, function () { app.go("map", { focus: lv.id }); }), play])
    ]));
    return { el: el, back: function () { app.go("map", { focus: lv.id }); }, focus: play };
  }

  // ---------------- endless ----------------
  function endless(app, params) {
    var p = app.profile;
    var rows = p.endless.map(function (e, i) {
      return h("tr" + (params && params.rank === i ? ".me" : ""), [h("td", "#" + (i + 1)), h("td.r", String(e.score)), h("td.r", String(e.length)),
        h("td.r", e.date || "")]);
    });
    var play = h("button.btn.primary", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.startEndless(); } }, [t("endless.play") + " ", h("span.k", "Enter")]);
    var el = h("div", h("div.wrap", { style: { "max-width": "620px" } }, [
      head(app, t("menu.endless"), t("endless.sub"), null, function () { app.go("title"); }),
      h("div.panel", rows.length ? h("table.table", [h("tr", [h("th", t("col.rank")), h("th.r", t("col.light")), h("th.r", t("col.length")), h("th.r", t("col.date"))]), rows])
        : h("div.empty", t("endless.empty"))),
      h("div.btn-row", [play])
    ]));
    return { el: el, back: function () { app.go("title"); }, focus: play };
  }

  // ---------------- daily ----------------
  function daily(app) {
    var p = app.profile;
    var key = LM.daily.dateKey();
    var lv = LM.daily.level(key);
    var best = p.daily[key] || 0;
    var hist = Object.keys(p.daily).sort().reverse().slice(0, 7).map(function (k) {
      return h("tr" + (k === key ? ".me" : ""), [h("td", k), h("td.r", String(p.daily[k]))]);
    });
    var play = h("button.btn.primary", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.startDaily(); } }, [t("daily.play") + " ", h("span.k", "Enter")]);
    var el = h("div", h("div.wrap", { style: { "max-width": "620px" } }, [
      head(app, t("menu.daily"), t("daily.sub"), null, function () { app.go("title"); }),
      h("div.panel", { style: { display: "flex", "flex-direction": "column", gap: "10px", "text-align": "center" } }, [
        h("div.eyebrow.muted", key + " \u00b7 " + L.world(lv.world)),
        h("h2", { style: { margin: "0" } }, L.level(lv)),
        h("div.mech", mechanics(lv).map(function (m) { return h("span", m); })),
        h("div", [t("daily.rules") + " ", h("span.gold", t("daily.goal"))]),
        h("div.big.gold", { style: { "font-size": "34px", "font-weight": "900" } }, best ? t("daily.best", { n: best }) : t("daily.notYet"))
      ]),
      hist.length ? h("div.panel", h("table.table", [h("tr", [h("th", t("col.day")), h("th.r", t("col.best"))]), hist])) : null,
      h("div.btn-row", [play])
    ]));
    return { el: el, back: function () { app.go("title"); }, focus: play };
  }

  // ---------------- trophies ----------------
  function trophies(app, params) {
    var p = app.profile;
    app.checkAchievements(null);
    var list = LM.achievements.list;
    var cat = (params && params.cat) || "all";
    var got = list.filter(function (a) { return p.unlocked[a.id]; });
    var pct = Math.round((got.length / list.length) * 100);
    var byR = { bronze: 0, silver: 0, gold: 0 };
    got.forEach(function (a) { byR[a.rarity]++; });
    var ctx = { p: p, run: null };
    var tabs = [{ id: "all" }].concat(LM.achievements.categories).map(function (c) {
      var n = c.id === "all" ? got.length : got.filter(function (a) { return a.cat === c.id; }).length;
      var tot = c.id === "all" ? list.length : list.filter(function (a) { return a.cat === c.id; }).length;
      return h("button.btn" + (c.id === cat ? ".sel" : ""), { "data-nav": "", "data-tab": c.id, onclick: function () {
        app.sfx("uiMove"); app.go("trophies", { cat: c.id, tab: true });
      } }, (c.id === "all" ? t("ach.all") : t("ach.cat." + c.id)) + " " + n + "/" + tot);
    });
    var cards = list.filter(function (a) { return cat === "all" || a.cat === cat; }).map(function (a) {
      var un = !!p.unlocked[a.id];
      var hidden = a.cat === "secret" && !un;
      var prog = !un ? LM.achievements.progress(a, ctx) : null;
      return h("div.ach" + (un ? ".unlocked" : ".locked"), { "data-nav": "", tabindex: "-1" }, [
        h("img", { src: LM.icons.achievement(a, 56, un ? "unlocked" : hidden ? "hidden" : "locked"), alt: "" }),
        h("div.tx", [
          h("div.nm", [hidden ? t("ach.secret") : L.achName(a)]),
          h("div.ds", hidden ? t("ach.secretDesc") : L.achDesc(a)),
          h("div.rt." + a.rarity, L.rarity(a.rarity) + (un ? " \u00b7 " + t("ach.unlockedOn", { d: new Date(p.unlocked[a.id]).toLocaleDateString(LM.i18n.lang === "ru" ? "ru-RU" : "en-US") }) : "")),
          prog ? h("div", [h("div.pbar", h("i", { style: { width: (prog[0] / prog[1] * 100) + "%" } })), h("div.pv", prog[0] + " / " + prog[1])]) : null
        ])
      ]);
    });
    var el = h("div", h("div.wrap", [
      head(app, t("ach.title"), null, null, function () { app.go("title"); }),
      h("div.panel.trophy-sum", [
        h("div.ring", { style: { "--p": String(pct) } }, h("span", pct + "%")),
        h("div", { style: { flex: "1" } }, [h("b", t("ach.count", { a: got.length, b: list.length })),
          h("div.muted", { style: { "font-size": "13px" } }, t("ach.blurb"))]),
        h("div.rar", [h("span.bronze", t("rarity.Bronze") + " " + byR.bronze), h("span.silver", t("rarity.Silver") + " " + byR.silver), h("span.gold", t("rarity.Gold") + " " + byR.gold)])
      ]),
      h("div.tabs", tabs),
      h("div.grid", cards)
    ]));
    var focus = params && params.tab ? tabs.filter(function (t) { return t.getAttribute("data-tab") === cat; })[0] : null;
    return { el: el, back: function () { app.go("title"); }, focus: focus };
  }

  // ---------------- shop ----------------
  function shop(app, params) {
    var p = app.profile;
    var focus = null;
    var cards = C.skins.map(function (s) {
      var owned = p.skins.owned.indexOf(s.id) !== -1;
      var eq = p.skins.selected === s.id;
      var afford = p.wallet >= s.price;
      var cv = h("canvas", { width: 360, height: 192 });
      var act = eq ? t("shop.equipped") : owned ? t("shop.equip") : [h("img", { src: LM.icons.star(36), alt: "" }), String(s.price)];
      var card = h("button.skin" + (eq ? ".equipped" : "") + (!owned && afford ? ".afford" : "") + (!owned && !afford ? ".poor" : ""),
        { "data-nav": "", "data-skin": s.id, onclick: function () {
          if (owned) { P.selectSkin(p, s.id); app.sfx("uiSelect"); app.save(); app.go("shop", { focus: s.id }); return; }
          if (P.buySkin(p, s.id)) {
            app.sfx("buy");
            app.save();
            app.checkAchievements(null);
            app.toast(t("shop.bought", { name: L.skin(s) }));
            app.go("shop", { focus: s.id });
          } else {
            app.sfx("error");
            app.toast(t("shop.need", { n: s.price - p.wallet }));
          }
        } }, [cv, h("div.nm", L.skin(s)), h("div.act", act)]);
      card._cv = cv;
      card._skin = s;
      if ((params && params.focus === s.id) || (!(params && params.focus) && eq)) focus = card;
      return card;
    });
    var el = h("div", h("div.wrap", [
      head(app, t("shop.title"), t("shop.sub"), walletPill(app), function () { app.go("title"); }),
      h("div.skins", cards)
    ]));
    // live previews: each card animates a little serpent in its skin
    var views = cards.map(function () { return new LM.SnakeView(); });
    var raf = 0, alive = true;
    function frame(ts) {
      if (!alive) return;
      var t = ts / 1000;
      cards.forEach(function (card, i) {
        var cv = card._cv, ctx = cv.getContext("2d");
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, cv.width, cv.height);
        var pts = [];
        for (var k = 0; k < 14; k++) {
          var x = 300 - k * 19;
          pts.push({ x: x, y: 96 + Math.sin(k * 0.55 - t * 3) * 26 });
        }
        views[i].draw(ctx, { pts: pts, cell: 30, skin: card._skin, t: t + i, dt: 0.016, dir: { x: 1, y: 0 }, look: { x: 360, y: 96 }, tickMs: 120 });
      });
      raf = requestAnimationFrame(frame);
    }
    raf = requestAnimationFrame(frame);
    return { el: el, back: function () { app.go("title"); }, focus: focus, onLeave: function () { alive = false; cancelAnimationFrame(raf); } };
  }

  // ---------------- settings ----------------
  function settings(app, params) {
    var p = app.profile, s = p.settings;
    var from = params && params.from;
    function back() { if (from === "pause") app.go("pause"); else app.go("title"); }
    function slider(label, key, sub) {
      var val = h("span.val", Math.round(s[key] * 100) + "");
      var input = h("input", { type: "range", min: "0", max: "100", step: "5", value: String(Math.round(s[key] * 100)), "data-nav": "", "aria-label": label,
        oninput: function () { s[key] = input.value / 100; val.textContent = input.value; app.applySettings(); },
        onchange: function () { app.save(); if (key === "sfx") app.sfx("eat"); } });
      return h("div.row", [h("label", [label, sub ? h("small", sub) : null]), input, val]);
    }
    function toggle(label, key, sub, invert) {
      var on = invert ? !s[key] : !!s[key];
      var btn = h("button.toggle" + (on ? ".on" : ""), { "data-nav": "", "aria-label": label, "aria-pressed": String(on), onclick: function () {
        s[key] = !s[key];
        var now = invert ? !s[key] : !!s[key];
        btn.classList.toggle("on", now);
        btn.setAttribute("aria-pressed", String(now));
        app.applySettings();
        app.save();
        app.sfx("uiSelect");
        if (key === "vibration" && s.vibration) app.vibrate(40);
      } });
      return h("div.row", [h("label", [label, sub ? h("small", sub) : null]), btn]);
    }
    var langFocus = null;
    var langRow = h("div.row.lang-row", [h("label", [t("set.language"), h("small", t("set.languageSub"))]),
      h("div.seg", LM.i18n.languages.map(function (lg) {
        var b = h("button.btn.seg-btn" + (s.lang === lg.id ? ".sel" : ""), { "data-nav": "", "data-lang": lg.id, lang: lg.id, "aria-pressed": String(s.lang === lg.id),
          onclick: function () { app.sfx("uiSelect"); app.setLanguage(lg.id); app.go("settings", { from: from, lang: true }); } }, lg.name);
        if (params && params.lang && s.lang === lg.id) langFocus = b;
        return b;
      }))]);
    var qFocus = null;
    var qRow = h("div.row.quality-row", [h("label", [t("set.quality"), h("small", app.webgl() ? t("set.qualitySub", { q: L.quality(app.scene3dLevel()) }) : t("set.quality2d"))]),
      h("div.seg", ["auto", "low", "medium", "high"].map(function (q) {
        var b = h("button.btn.seg-btn" + (s.quality === q ? ".sel" : ""), { "data-nav": "", "data-quality": q, "aria-pressed": String(s.quality === q),
          onclick: function () { app.sfx("uiSelect"); s.quality = q; app.applySettings(); app.save(); app.go("settings", { from: from, quality: true }); } }, L.quality(q));
        if (params && params.quality && s.quality === q) qFocus = b;
        return b;
      }))]);
    var armed = false;
    var reset = h("button.btn.danger", { "data-nav": "", onclick: function () {
      if (!armed) { armed = true; reset.textContent = t("set.resetConfirm"); app.sfx("error"); return; }
      app.resetProgress();
    } }, t("set.reset"));
    var el = h("div", h("div.wrap", { style: { "max-width": "620px" } }, [
      head(app, t("set.title"), null, null, back),
      h("div.settings", [
        langRow,
        qRow,
        slider(t("set.music"), "music"),
        slider(t("set.sfx"), "sfx"),
        toggle(t("set.sound"), "muted", t("set.soundSub"), true),
        toggle(t("set.vibration"), "vibration", t("set.vibrationSub")),
        toggle(t("set.reduced"), "reducedFlash", t("set.reducedSub")),
        toggle(t("set.shake"), "shake", t("set.shakeSub")),
        h("div.row", [h("label", [t("set.progress"), h("small", app.storage.ok ? t("set.saved") : t("set.blocked"))]), reset])
      ]),
      h("div.foot", t("set.foot", { v: C.version }))
    ]));
    return { el: el, back: back, focus: langFocus || qFocus };
  }

  // ---------------- help ----------------
  function help(app) {
    var pu = ["slow", "ghost", "magnet", "double"].map(function (k) {
      return h("div.panel", [h("img", { src: LM.icons.powerup(k, 80), alt: "" }), h("div", [h("b", L.power(k)), h("span", t("help." + k))])]);
    });
    var el = h("div", h("div.wrap", { style: { "max-width": "760px" } }, [
      head(app, t("help.title"), null, null, function () { app.go("title"); }),
      h("div.help-grid", [
        h("div.panel", [h("img", { src: LM.icons.star(80), alt: "" }), h("div", [h("b", t("help.star")), h("span", t("help.starText"))])]),
        h("div.panel", [h("img", { src: (function () { var c = document.createElement("canvas"); c.width = c.height = 80; LM.itemsView.star(c.getContext("2d"), 40, 38, 52, 1, { golden: true, noHalo: true }); return c.toDataURL(); })(), alt: "" }),
          h("div", [h("b", t("help.golden")), h("span", t("help.goldenText"))])]),
        pu
      ]),
      h("div.panel", h("div.keys", [
        h("span", [h("kbd", "\u2190\u2191\u2192\u2193"), " ", h("kbd", "WASD")]), h("span", t("help.move")),
        h("span", [h("kbd", "Space"), " ", h("kbd", "P")]), h("span", t("help.pause")),
        h("span", h("kbd", "Enter")), h("span", t("help.select")),
        h("span", h("kbd", "Esc")), h("span", t("help.back")),
        h("span", h("kbd", "M")), h("span", t("help.mute")),
        h("span", t("help.phone")), h("span", t("help.phoneText"))
      ])),
      h("div.panel", { style: { "font-size": "14px" } }, [
        h("b", t("help.worlds") + " "), t("help.worldsText")
      ]),
      h("div.panel.help-dark", { style: { "font-size": "14px" } }, [
        h("img", { src: LM.icons.dark(64), alt: "" }), h("div", [h("b", t("help.dark") + " "), t("help.darkText")])
      ])
    ]));
    return { el: el, back: function () { app.go("title"); } };
  }

  // ---------------- pause ----------------
  function pause(app) {
    var g = app.game;
    var resume = h("button.btn.primary", { "data-nav": "", onclick: function () { app.resume(); } }, [t("pause.resume") + " ", h("span.k", "Space")]);
    var el = h("div.overlay", h("div.card", [
      h("div.eyebrow", g.mode === "campaign" ? t("hud.level", { n: g.level.number }) + " \u00b7 " + L.level(g.level) : L.level(g.level)),
      h("h2", t("pause.title")),
      g.level.goal ? h("div.goal", LM.levels.goalText(g.level.goal)) : null,
      h("div.facts", [
        h("div", [h("small", t("res.light")), h("b", String(g.score))]),
        h("div", [h("small", t("res.length")), h("b", String(g.snake.length()))]),
        h("div", [h("small", t("res.time")), h("b", LM.levels.fmtTime(g.elapsedMs / 1000))])
      ]),
      h("div.menu", { style: { margin: "0 auto" } }, [
        resume,
        h("button.btn", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.restart(); } }, t("pause.restart")),
        h("button.btn", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.go("settings", { from: "pause" }); } }, t("pause.settings")),
        h("button.btn", { "data-nav": "", onclick: function () { app.sfx("uiBack"); app.quit(); } }, t("pause.quit"))
      ])
    ]));
    return { el: el, back: function () { app.resume(); }, focus: resume,
      onKey: function (action) { if (action === "pause") { app.resume(); return true; } return false; } };
  }

  // ---------------- results ----------------
  function results(app, params) {
    var g = app.game, r = g.result(), s = params.summary;
    var won = r.won;
    var kids = [];
    var primary;
    var lv = g.level;
    if (g.mode === "campaign") {
      var next = LM.levels.byId(lv.id + 1);
      kids.push(h("div.eyebrow", t("level.eyebrow", { w: L.world(lv.world), n: lv.number })));
      kids.push(h("h2." + (won ? "win" : "lose"), won ? t("res.won") : crashLine(r.stats.crash, g.board && g.level.world)));
      if (won) {
        var moonsEl = h("div.bigmoons", [h("span.st", "\u263E"), h("span.st", "\u263E"), h("span.st", "\u263E")]);
        kids.push(moonsEl);
        params.onMoons(moonsEl, s.moons);
        kids.push(h("div.crit", LM.levels.moonText(lv).map(function (t, i) {
          return h("div" + (s.moons > i ? ".got" : ""), [h("span.s", "\u263E\u263E\u263E".slice(0, i + 1)), t]);
        })));
      } else {
        kids.push(h("div.goal", t("res.there", { goal: LM.levels.goalText(lv.goal), p: Math.round(LM.levels.progress(lv.goal, g) * 100) })));
      }
      kids.push(h("div.facts", [
        h("div", [h("small", t("res.light")), h("b", String(r.score))]),
        h("div", [h("small", t("res.time")), h("b", LM.levels.fmtTime(r.elapsedMs / 1000))]),
        h("div", [h("small", t("res.stars")), h("b", String(r.eaten))])
      ]));
      if (s.bonus) kids.push(h("div.reward", [t("res.bonus", { n: s.bonus }), h("img", { src: LM.icons.star(40), alt: "" })]));
      var btns = [];
      if (params.finale) {
        primary = h("button.btn.primary", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.playStory("finale", { then: "title" }); } }, [t("res.continue") + " ", h("span.k", "Enter")]);
        btns.push(primary);
      } else if (won && next) {
        primary = h("button.btn.primary", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.startLevel(next.id); } }, [t("res.next") + " ", h("span.k", "Enter")]);
        btns.push(primary);
        btns.push(h("button.btn", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.startLevel(lv.id); } }, t("res.replay")));
      } else {
        primary = h("button.btn.primary", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); app.startLevel(lv.id); } }, [(won ? t("res.replay") : t("res.retry")) + " ", h("span.k", "Enter")]);
        btns.push(primary);
      }
      btns.push(h("button.btn", { "data-nav": "", onclick: function () { app.sfx("uiBack"); app.quit("map", { focus: won && next ? next.id : lv.id }); } }, t("res.map")));
      if (won && !next) kids.push(h("div.goal.gold", t("res.allDone")));
      kids.push(h("div.btn-row", btns));
    } else {
      var isDaily = g.mode === "daily";
      kids.push(h("div.eyebrow", isDaily ? t("res.dailyTitle", { d: lv.dateKey, name: L.level(lv) }) : t("mode.endless")));
      kids.push(h("h2.lose", crashLine(r.stats.crash, g.board && g.level.world)));
      kids.push(h("div.big", String(r.score)));
      if (s.newBest && r.score > 0) kids.push(h("div.newbest", isDaily ? t("res.newBestToday") : t("res.newRecord")));
      kids.push(h("div.facts", [
        h("div", [h("small", t("res.length")), h("b", String(r.length))]),
        h("div", [h("small", t("res.time")), h("b", LM.levels.fmtTime(r.elapsedMs / 1000))]),
        h("div", [h("small", isDaily ? t("res.todayBest") : t("res.best")), h("b", String(isDaily ? app.profile.daily[lv.dateKey] || 0 : app.profile.stats.bestEndless))])
      ]));
      if (!isDaily && app.profile.endless.length) {
        kids.push(h("table.table", app.profile.endless.slice(0, 5).map(function (e, i) {
          return h("tr" + (s.rank === i ? ".me" : ""), [h("td", "#" + (i + 1)), h("td.r", String(e.score)), h("td.r", t("res.len", { n: e.length }))]);
        })));
      }
      if (isDaily && r.score < 100) kids.push(h("div.reward", t("res.dailyNeed")));
      primary = h("button.btn.primary", { "data-nav": "", onclick: function () { app.sfx("uiSelect"); if (isDaily) app.startDaily(); else app.startEndless(); } }, [t("res.again") + " ", h("span.k", "Enter")]);
      kids.push(h("div.btn-row", [primary, h("button.btn", { "data-nav": "", onclick: function () { app.sfx("uiBack"); app.quit(isDaily ? "daily" : "endless"); } }, t("res.menu"))]));
    }
    var el = h("div.overlay", h("div.card", kids));
    return { el: el, focus: primary, back: function () { app.quit(g.mode === "campaign" ? "map" : g.mode === "daily" ? "daily" : "endless", { focus: lv.id }); } };
  }

  // ---------------- story ----------------
  function story(app, params) {
    var kind = params.kind || "intro";
    var def = LM.story.scenes[kind];
    var done = false;
    function finish() { if (done) return; done = true; app.sfx("uiSelect"); app.endStory(); }
    var lines = LM.story.lines(kind).map(function (l, i) {
      return h("p.line", { style: { "animation-delay": (LM.story.lineStart + i * LM.story.lineEvery) + "s" } }, l);
    });
    var skip = h("button.btn.story-skip", { "data-nav": "", onclick: function (e) { e.stopPropagation(); finish(); } }, [t("story.continue") + " ", h("span.k", "Enter")]);
    var el = h("div.story.story-" + kind, [h("div.lines", lines), h("div.story-foot", [skip])]);
    el.addEventListener("click", function () { finish(); });
    var timer = setTimeout(finish, LM.story.duration(kind) * 1000);
    return { el: el, focus: skip, back: finish,
      onKey: function (action) { if (action === "confirm" || action === "back" || action === "pause") finish(); return true; },
      onLeave: function () { clearTimeout(timer); } };
  }

  function crashLine(reason, world) {
    var w = world || 0;
    if (reason === "wall") return t("crash.wall." + w);
    if (reason === "mover") return t("crash.mover." + w);
    if (reason === "self" || reason === "glitch") return t("crash." + reason);
    return t("crash.other");
  }

  LM.screens = { title: title, map: map, level: level, endless: endless, daily: daily, trophies: trophies, shop: shop,
    settings: settings, help: help, pause: pause, results: results, story: story };
})(window.LUMEN);
