window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var P = function () { return LM.profile; };

  // ctx = { p: profile, run: live game or null, over: bool, won: bool, hour: 0-23 }
  function runStat(ctx, key) { return ctx.run ? ctx.run.stats[key] || 0 : 0; }
  function inMode(ctx, mode) { return ctx.run && ctx.run.mode === mode; }
  function count(obj) { var n = 0; for (var k in obj) if (obj[k]) n++; return n; }
  function powerKinds(p) { var n = 0; for (var k in p.stats.powerups) if (p.stats.powerups[k] > 0) n++; return n; }

  // icon: [shape glyph] drawn by render/icons.js
  var LIST = [
    // ----- progress -----
    { id: "first_light", cat: "progress", rarity: "bronze", name: "First Light", desc: "Catch your first fallen star.",
      icon: "star", check: function (c) { return c.p.stats.stars >= 1; } },
    { id: "handful", cat: "progress", rarity: "bronze", name: "Handful of Stars", desc: "Catch 100 stars in total.",
      icon: "handful", goal: 100, value: function (c) { return c.p.stats.stars; } },
    { id: "constellation", cat: "progress", rarity: "silver", name: "Constellation", desc: "Catch 1,000 stars in total.",
      icon: "constellation", goal: 1000, value: function (c) { return c.p.stats.stars; } },
    { id: "garden_blooms", cat: "progress", rarity: "bronze", name: "The Garden Blooms", desc: "Bring light back to every level of the Whispering Garden.",
      icon: "flower", goal: 5, value: function (c) { return worldCount(c.p, 0); } },
    { id: "city_wakes", cat: "progress", rarity: "silver", name: "The City Wakes", desc: "Bring light back to every level of the Sleeping City.",
      icon: "city", goal: 5, value: function (c) { return worldCount(c.p, 1); } },
    { id: "sky_rekindled", cat: "progress", rarity: "silver", name: "Sky Rekindled", desc: "Bring light back to every level of the Hollow Sky.",
      icon: "planet", goal: 5, value: function (c) { return worldCount(c.p, 2); } },
    { id: "moonrise", cat: "progress", rarity: "gold", name: "Moonrise", desc: "Walk the Moon's Path to the end and wake the Moon.",
      icon: "moon", goal: 5, value: function (c) { return worldCount(c.p, 3); } },
    { id: "moon_gazer", cat: "progress", rarity: "silver", name: "Moon Gazer", desc: "Earn 30 moons in the campaign.",
      icon: "crescent", goal: 30, value: function (c) { return P().totalMoons(c.p); } },
    { id: "full_moon", cat: "progress", rarity: "gold", name: "Full Moon", desc: "Earn all 60 moons.",
      icon: "fullmoon", goal: 60, value: function (c) { return P().totalMoons(c.p); } },
    { id: "nightly_vigil", cat: "progress", rarity: "bronze", name: "Nightly Vigil", desc: "Gather 100 or more light in a Daily Challenge.",
      icon: "calendar", check: function (c) { return c.p.stats.dailyGood > 0; } },
    { id: "lantern_bearer", cat: "progress", rarity: "bronze", name: "Lantern Bearer", desc: "Clear a dark level by your own light.",
      icon: "lanternlit", check: function (c) { return LM.levels.darkList().some(function (l) { return P().levelMoons(c.p, l.id) > 0; }); } },
    { id: "new_glow", cat: "progress", rarity: "bronze", name: "New Glow", desc: "Buy a skin in the shop.",
      icon: "brush", check: function (c) { return c.p.stats.skinsBought > 0; } },
    { id: "every_hue", cat: "progress", rarity: "gold", name: "Every Hue", desc: "Own every skin.",
      icon: "prism", goal: LM.config.skins.length, value: function (c) { return c.p.skins.owned.length; } },
    { id: "long_night", cat: "progress", rarity: "silver", name: "Long Night", desc: "Play for 30 minutes in total.",
      icon: "clock", goal: 30, value: function (c) {
        return Math.floor((c.p.stats.playMs + (c.run ? c.run.elapsedMs : 0)) / 60000);
      } },

    // ----- mastery -----
    { id: "spark_chain", cat: "mastery", rarity: "bronze", name: "Spark Chain", desc: "Reach a x5 combo.",
      icon: "flame", check: function (c) { return runStat(c, "maxCombo") >= 5; } },
    { id: "supernova", cat: "mastery", rarity: "gold", name: "Supernova", desc: "Reach a x10 combo.",
      icon: "burst", check: function (c) { return runStat(c, "maxCombo") >= 10; } },
    { id: "ribbon_of_light", cat: "mastery", rarity: "bronze", name: "Ribbon of Light", desc: "Grow to length 30 in one run.",
      icon: "ribbon", check: function (c) { return runStat(c, "maxLength") >= 30; } },
    { id: "pure_light", cat: "mastery", rarity: "gold", name: "Pure Light", desc: "Grow to length 50 without taking a power-up.",
      icon: "snake", check: function (c) { return runStat(c, "maxLength") >= 50 && runStat(c, "powerups") === 0; } },
    { id: "shooting_star", cat: "mastery", rarity: "silver", name: "Shooting Star", desc: "Clear a campaign level in under 25 seconds.",
      icon: "comet", check: function (c) { return c.won && inMode(c, "campaign") && c.run.elapsedMs < 25000; } },
    { id: "radiant_world", cat: "mastery", rarity: "silver", name: "Radiant World", desc: "Earn 3 moons on every level of one world.",
      icon: "gem", check: function (c) { return [0, 1, 2, 3].some(function (w) { return P().worldPerfect(c.p, w); }); } },
    { id: "night_vision", cat: "mastery", rarity: "gold", name: "Night Vision", desc: "Earn 3 moons on every dark level.",
      icon: "eye", goal: LM.levels.darkList().length, value: function (c) {
        return LM.levels.darkList().filter(function (l) { return P().levelMoons(c.p, l.id) === 3; }).length;
      } },
    { id: "wishmaker", cat: "mastery", rarity: "silver", name: "Wishmaker", desc: "Catch 3 golden stars in one run.",
      icon: "wish", check: function (c) { return runStat(c, "golden") >= 3; } },
    { id: "night_watch", cat: "mastery", rarity: "silver", name: "Night Watch", desc: "Stay alight for 3 minutes in Endless.",
      icon: "lantern", check: function (c) { return inMode(c, "endless") && c.run.elapsedMs >= 180000; } },
    { id: "thousand_lights", cat: "mastery", rarity: "silver", name: "Thousand Lights", desc: "Gather 1,000 light in one Endless run.",
      icon: "trophy", check: function (c) { return inMode(c, "endless") && c.run.score >= 1000; } },
    { id: "gifts_of_night", cat: "mastery", rarity: "bronze", name: "Gifts of the Night", desc: "Use every kind of power-up.",
      icon: "orbs", goal: 4, value: function (c) { return powerKinds(c.p); } },

    // ----- secret -----
    { id: "ouroboros", cat: "secret", rarity: "bronze", name: "Ouroboros", desc: "Bite your own tail.",
      icon: "ring", check: function (c) { return c.over && runStat(c, "crash") === "self"; } },
    { id: "lights_out", cat: "secret", rarity: "bronze", name: "Lights Out", desc: "Go dark within 3 seconds of the start.",
      icon: "candle", check: function (c) { return c.over && !c.won && !!c.run && !!c.run.stats.crash && c.run.elapsedMs < 3000; } },
    { id: "night_owl", cat: "secret", rarity: "silver", name: "Night Owl", desc: "Play a run between midnight and 5 AM.",
      icon: "owl", check: function (c) { return !!c.run && c.hour >= 0 && c.hour < 5; } },
    { id: "old_school", cat: "secret", rarity: "gold", name: "Old School", desc: "Enter the Konami code on the title screen.",
      icon: "gamepad", check: function (c) { return !!c.p.flags.konami; } },
    { id: "wisp_walker", cat: "secret", rarity: "silver", name: "Wisp Walker", desc: "Drift through yourself 10 times in one run.",
      icon: "ghost", check: function (c) { return runStat(c, "ghostPasses") >= 10; } },
    { id: "guiding_star", cat: "secret", rarity: "silver", name: "Guiding Star", desc: "Catch 4 stars during a single Lodestar.",
      icon: "magnet", check: function (c) { return runStat(c, "magnetBest") >= 4 || runStat(c, "magnetEats") >= 4; } },
    { id: "daydreamer", cat: "secret", rarity: "bronze", name: "Daydreamer", desc: "Pause 10 times in one run.",
      icon: "pause", check: function (c) { return runStat(c, "pauses") >= 10; } }
  ];

  function worldCount(p, w) {
    return LM.levels.ofWorld(w).filter(function (l) { return P().levelMoons(p, l.id) > 0; }).length;
  }

  function met(a, ctx) {
    if (a.check) return !!a.check(ctx);
    return a.value(ctx) >= a.goal;
  }

  // [current, goal] for achievements that count toward something.
  function progress(a, ctx) {
    if (!a.goal) return null;
    return [Math.min(a.goal, a.value(ctx)), a.goal];
  }

  // Unlock everything newly met. Returns the new ones, in list order.
  function evaluate(p, ctx) {
    ctx.p = p;
    if (ctx.hour === undefined) ctx.hour = new Date().getHours();
    var fresh = [];
    for (var i = 0; i < LIST.length; i++) {
      var a = LIST[i];
      if (p.unlocked[a.id]) continue;
      var ok = false;
      try { ok = met(a, ctx); } catch (e) { ok = false; }
      if (ok) {
        p.unlocked[a.id] = Date.now();
        fresh.push(a);
      }
    }
    return fresh;
  }

  function byId(id) {
    return LIST.filter(function (a) { return a.id === id; })[0] || null;
  }

  LM.achievements = {
    list: LIST, evaluate: evaluate, progress: progress, byId: byId,
    unlockedCount: function (p) { return count(p.unlocked); },
    categories: [
      { id: "progress", name: "Progress" }, { id: "mastery", name: "Mastery" }, { id: "secret", name: "Secret" }
    ]
  };
})(window.LUMEN);
