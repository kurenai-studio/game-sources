window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var $ = function (id) { return document.getElementById(id); };

  // The in-game heads-up display. Cheap to call every frame: it only touches
  // the DOM when a value changes.
  function Hud() {
    this.el = $("hud");
    this.last = {};
    this.effects = {};
    var self = this;
    $("hud-pause").addEventListener("click", function () { if (self.onPause) self.onPause(); });
  }

  Hud.prototype.set = function (key, value, fn) {
    if (this.last[key] === value) return false;
    this.last[key] = value;
    fn(value);
    return true;
  };

  Hud.prototype.show = function (game) {
    this.el.hidden = false;
    this.last = {};
    this.effects = {};
    $("hud-effects").innerHTML = "";
    var lv = game.level;
    $("hud-tag").textContent = game.mode === "campaign" ? LM.t("hud.level", { n: lv.number }) : game.mode === "daily" ? LM.t("hud.daily", { d: lv.dateKey }) : LM.t("mode.endless");
    $("hud-name").textContent = game.mode === "endless" ? LM.L.world(game.worldIndex) : LM.L.level(lv);
    $("hud-goal").hidden = !lv.goal;
    $("hud-goal-text").textContent = LM.levels.goalText(lv.goal);
    $("hud-time-label").textContent = lv.goal && lv.goal.type === "survive" ? LM.t("hud.left") : LM.t("hud.time");
  };

  Hud.prototype.hide = function () {
    this.el.hidden = true;
  };

  Hud.prototype.update = function (game) {
    var lv = game.level;
    this.set("score", game.score, function (v) {
      var el = $("hud-score");
      el.textContent = v;
      el.classList.remove("bump");
      void el.offsetWidth;
      el.classList.add("bump");
    });
    var secs = lv.goal && lv.goal.type === "survive" ? Math.max(0, lv.goal.n - game.elapsedMs / 1000) : game.elapsedMs / 1000;
    this.set("time", Math.ceil(secs - 0.001), function () { $("hud-time").textContent = LM.levels.fmtTime(Math.ceil(secs - 0.001)); });
    if (lv.goal) {
      var p = LM.levels.progress(lv.goal, game);
      this.set("goal", Math.round(p * 200), function () { $("hud-goal-bar").style.width = (p * 100) + "%"; });
      var g = lv.goal, txt;
      if (g.type === "eat") txt = LM.t("hud.stars", { a: game.eaten, b: g.n });
      else if (g.type === "length") txt = LM.t("hud.length", { a: game.snake.length(), b: g.n });
      else if (g.type === "survive") txt = LM.t("hud.survive", { n: g.n });
      else txt = LM.t("hud.light", { a: game.score, b: g.n });
      this.set("goaltxt", txt, function (v) { $("hud-goal-text").textContent = v; });
    }
    if (game.mode === "endless") {
      this.set("wname", game.worldIndex, function (w) { $("hud-name").textContent = LM.L.world(w); });
    }
    var combo = game.combo;
    this.set("combo", combo, function (c) {
      var el = $("hud-combo");
      el.textContent = LM.t("hud.spark", { n: c });
      el.classList.toggle("show", c > 1);
      el.classList.toggle("hot", c >= 5);
    });

    // active power-ups with a draining bar
    var box = $("hud-effects");
    for (var k in game.effects) {
      var left = game.effects[k];
      var chip = this.effects[k];
      if (left > 0 && !chip) {
        chip = LM.dom.h("div.fx", [LM.dom.h("img", { src: LM.icons.powerup(k, 44), alt: "" }), LM.L.power(k),
          LM.dom.h("div.t", LM.dom.h("i", { style: { background: LM.config.powerups[k].color } }))]);
        box.appendChild(chip);
        this.effects[k] = chip;
      } else if (left <= 0 && chip) {
        if (chip.parentNode) chip.parentNode.removeChild(chip);
        delete this.effects[k];
      }
      if (left > 0 && chip) chip.querySelector(".t i").style.width = Math.max(0, left / LM.config.effectMs[k] * 100) + "%";
    }
  };

  LM.Hud = Hud;
})(window.LUMEN);
