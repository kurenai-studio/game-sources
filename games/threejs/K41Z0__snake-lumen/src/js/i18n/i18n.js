window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // A tiny string table. Each language adds a flat map of keys to strings,
  // string arrays (story lines) or functions of the variables (for plurals).
  // Missing keys fall back to English, then to the given default.
  var tables = {};
  var I = {
    lang: "en",
    languages: [{ id: "en", name: "English" }, { id: "ru", name: "\u0420\u0443\u0441\u0441\u043a\u0438\u0439" }],
    add: function (lang, table) {
      tables[lang] = tables[lang] || {};
      for (var k in table) tables[lang][k] = table[k];
    },
    has: function (lang) { return !!tables[lang]; },
    set: function (lang) { I.lang = tables[lang] ? lang : "en"; return I.lang; },
    // "ru-RU" -> "ru"; anything we do not have -> "en"
    detect: function (navLang) { return /^ru\b/i.test(String(navLang || "")) ? "ru" : "en"; },
    // Russian-style plural: forms = [one, few, many] (1 star, 2 stars, 5 stars)
    plural: function (n, forms) {
      n = Math.abs(Math.floor(n));
      var d = n % 10, dd = n % 100;
      if (forms.length < 3) return n === 1 ? forms[0] : forms[1];
      if (d === 1 && dd !== 11) return forms[0];
      if (d >= 2 && d <= 4 && (dd < 12 || dd > 14)) return forms[1];
      return forms[2];
    }
  };

  function t(key, vars, fallback) {
    var v = tables[I.lang] && tables[I.lang][key];
    if (v === undefined && tables.en) v = tables.en[key];
    if (v === undefined) v = fallback !== undefined ? fallback : key;
    if (typeof v === "function") return v(vars || {});
    if (typeof v === "string" && vars) {
      v = v.replace(/\{(\w+)\}/g, function (m, k) { return vars[k] !== undefined ? vars[k] : m; });
    }
    return v;
  }

  // Names of game data. English lives with the data; other languages
  // translate by id.
  var L = {
    world: function (i) { return t("world." + i + ".name", null, LM.config.worlds[i].name); },
    blurb: function (i) { return t("world." + i + ".blurb", null, LM.config.worlds[i].blurb); },
    level: function (lv) {
      if (lv.daily) return t("daily.name", { name: t("daily." + lv.daily[0] + "." + lv.daily[1], null, lv.dailyName) });
      if (lv.id === "endless") return t("mode.endless");
      return t("level." + lv.id, null, lv.name);
    },
    power: function (k) { return t("pu." + k + ".name", null, LM.config.powerups[k].name); },
    skin: function (s) { return t("skin." + s.id, null, s.name); },
    achName: function (a) { return t("ach." + a.id + ".name", null, a.name); },
    achDesc: function (a) { return t("ach." + a.id + ".desc", null, a.desc); },
    rarity: function (r) { return t("rarity." + r, null, r); },
    quality: function (q) { return t("quality." + q, null, q); }
  };

  LM.i18n = I;
  LM.t = t;
  LM.L = L;
})(window.LUMEN);
