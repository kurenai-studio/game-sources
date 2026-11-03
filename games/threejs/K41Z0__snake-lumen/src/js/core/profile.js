window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var C = LM.config;

  // The saved player: progress, wallet, skins, settings and lifetime stats.
  // Plain data plus pure functions over it. Storage is someone else's job.
  function create() {
    return {
      v: 1,
      wallet: 0,
      levels: {},
      unlocked: {},
      seen: {},
      skins: { owned: ["lumen"], selected: "lumen" },
      settings: { music: 0.55, sfx: 0.8, muted: false, vibration: true, reducedFlash: false, shake: true, lang: "", quality: "auto" },
      stats: { stars: 0, golden: 0, playMs: 0, runs: 0, deaths: 0, dailyGood: 0, bestEndless: 0, skinsBought: 0,
        powerups: { slow: 0, ghost: 0, magnet: 0, double: 0 } },
      endless: [],
      daily: {},
      flags: {},
      story: { intro: 0, w1: 0, w2: 0, w3: 0, finale: 0 }
    };
  }

  function merge(base, extra) {
    if (!extra || typeof extra !== "object") return base;
    for (var k in base) {
      if (!Object.prototype.hasOwnProperty.call(extra, k)) continue;
      var a = base[k], b = extra[k];
      if (a && typeof a === "object" && !Array.isArray(a) && b && typeof b === "object" && !Array.isArray(b)) {
        if (Object.keys(a).length === 0) base[k] = b;
        else merge(a, b);
      } else if (Array.isArray(a) === Array.isArray(b) && typeof a === typeof b) {
        base[k] = b;
      }
    }
    return base;
  }

  // Accept whatever was stored, keep what still makes sense, fill the rest.
  function normalize(raw) {
    var p = merge(create(), raw);
    if (p.skins.owned.indexOf("lumen") === -1) p.skins.owned.unshift("lumen");
    if (p.skins.owned.indexOf(p.skins.selected) === -1) p.skins.selected = "lumen";
    if (p.settings.lang !== "en" && p.settings.lang !== "ru") p.settings.lang = "";
    if (["auto", "low", "medium", "high"].indexOf(p.settings.quality) === -1) p.settings.quality = "auto";
    return p;
  }

  function levelMoons(p, id) {
    return (p.levels[id] && p.levels[id].moons) || 0;
  }

  function totalMoons(p) {
    var n = 0;
    for (var k in p.levels) n += p.levels[k].moons || 0;
    return n;
  }

  function worldCleared(p, w) {
    return LM.levels.ofWorld(w).every(function (l) { return levelMoons(p, l.id) > 0; });
  }

  function worldPerfect(p, w) {
    return LM.levels.ofWorld(w).every(function (l) { return levelMoons(p, l.id) === 3; });
  }

  function worldMoons(p, w) {
    return LM.levels.ofWorld(w).reduce(function (n, l) { return n + levelMoons(p, l.id); }, 0);
  }

  function levelUnlocked(p, id) {
    return id === 1 || levelMoons(p, id - 1) > 0;
  }

  function worldUnlocked(p, w) {
    return levelUnlocked(p, w * 5 + 1);
  }

  // Lifetime counters move during play, so a crash never loses eaten stars.
  function onEvent(p, ev) {
    if (ev.type === "eat") {
      p.stats.stars += 1;
      if (ev.golden) p.stats.golden += 1;
      p.wallet += ev.wallet || 1;
    } else if (ev.type === "powerup") {
      p.stats.powerups[ev.effect] = (p.stats.powerups[ev.effect] || 0) + 1;
    }
  }

  // Book a finished run. Returns what the results screen needs to say.
  function finishRun(p, game, extra) {
    extra = extra || {};
    var r = game.result();
    var out = { moons: 0, prevMoons: 0, newBest: false, rank: -1, bonus: 0, firstClear: false };
    p.stats.runs += 1;
    p.stats.playMs += r.elapsedMs;
    if (!r.won) p.stats.deaths += 1;

    if (r.mode === "campaign") {
      var lv = game.level;
      var rec = p.levels[lv.id] || { moons: 0, bestMs: 0, bestScore: 0 };
      out.prevMoons = rec.moons;
      if (r.won) {
        out.moons = LM.levels.rate(lv, r);
        out.firstClear = rec.moons === 0;
        if (out.moons > rec.moons) {
          out.bonus = (out.moons - rec.moons) * C.moonBonusWallet;
          p.wallet += out.bonus;
          rec.moons = out.moons;
        }
        if (!rec.bestMs || r.elapsedMs < rec.bestMs) rec.bestMs = Math.round(r.elapsedMs);
        if (r.score > rec.bestScore) { rec.bestScore = r.score; out.newBest = true; }
        p.levels[lv.id] = rec;
      }
    } else if (r.mode === "endless") {
      out.newBest = r.score > p.stats.bestEndless;
      p.stats.bestEndless = Math.max(p.stats.bestEndless, r.score);
      var entry = { score: r.score, length: r.length, eaten: r.eaten, date: extra.dateKey || "" };
      if (r.score > 0) {
        p.endless.push(entry);
        p.endless.sort(function (a, b) { return b.score - a.score; });
        p.endless = p.endless.slice(0, C.endless.tableSize);
        out.rank = p.endless.indexOf(entry);
      }
    } else if (r.mode === "daily") {
      var key = game.level.dateKey;
      var prev = p.daily[key] || 0;
      out.prevBest = prev;
      out.newBest = r.score > prev;
      if (out.newBest) p.daily[key] = r.score;
      if (r.score >= 100) p.stats.dailyGood += 1;
      var keys = Object.keys(p.daily).sort();
      while (keys.length > 30) delete p.daily[keys.shift()];
    }
    return out;
  }

  function buySkin(p, id) {
    var skin = C.skins.filter(function (s) { return s.id === id; })[0];
    if (!skin || p.skins.owned.indexOf(id) !== -1) return false;
    if (p.wallet < skin.price) return false;
    p.wallet -= skin.price;
    p.skins.owned.push(id);
    p.skins.selected = id;
    p.stats.skinsBought += 1;
    return true;
  }

  function grantSkin(p, id) {
    if (p.skins.owned.indexOf(id) === -1) p.skins.owned.push(id);
  }

  function selectSkin(p, id) {
    if (p.skins.owned.indexOf(id) === -1) return false;
    p.skins.selected = id;
    return true;
  }

  LM.profile = {
    create: create, normalize: normalize, levelMoons: levelMoons, totalMoons: totalMoons,
    worldCleared: worldCleared, worldPerfect: worldPerfect, worldMoons: worldMoons,
    levelUnlocked: levelUnlocked, worldUnlocked: worldUnlocked, onEvent: onEvent,
    finishRun: finishRun, buySkin: buySkin, grantSkin: grantSkin, selectSkin: selectSkin
  };
})(window.LUMEN);
