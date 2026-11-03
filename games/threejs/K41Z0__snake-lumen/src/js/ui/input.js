window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var KEYS = {
    ArrowUp: "up", ArrowDown: "down", ArrowLeft: "left", ArrowRight: "right",
    w: "up", s: "down", a: "left", d: "right",
    " ": "pause", p: "pause", Enter: "confirm", Escape: "back", Backspace: "back", m: "mute"
  };
  var KONAMI = ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"];

  // Turns keys, swipes and on-screen buttons into a handful of actions and
  // hands them to whoever is in charge (`handler(action, source)`).
  function Input(handler) {
    this.handler = handler;
    this.konami = [];
    this.onKonami = null;
    var self = this;

    document.addEventListener("keydown", function (e) {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      var key = e.key && e.key.length === 1 ? e.key.toLowerCase() : e.key;
      self.trackKonami(key);
      var action = KEYS[key];
      if (!action) return;
      var target = e.target;
      // let range sliders keep left/right, and never hijack typing
      if (target && target.tagName === "INPUT" && target.type === "range" && (action === "left" || action === "right")) return;
      if (target && target.tagName === "INPUT" && target.type === "text") return;
      e.preventDefault();
      if (e.repeat && (action === "confirm" || action === "back" || action === "pause" || action === "mute")) return;
      self.handler(action, "key", e);
    });

    // swipes on the canvas
    var view = document.getElementById("view");
    var start = null;
    view.addEventListener("pointerdown", function (e) {
      start = { x: e.clientX, y: e.clientY, used: false };
      self.handler("tap", "pointer", e);
    });
    view.addEventListener("pointermove", function (e) {
      if (!start || start.used) return;
      var dx = e.clientX - start.x, dy = e.clientY - start.y;
      if (Math.abs(dx) < 22 && Math.abs(dy) < 22) return;
      start.used = true;
      if (Math.abs(dx) > Math.abs(dy)) self.handler(dx > 0 ? "right" : "left", "swipe", e);
      else self.handler(dy > 0 ? "down" : "up", "swipe", e);
    });
    var end = function () { start = null; };
    view.addEventListener("pointerup", end);
    view.addEventListener("pointercancel", end);

    Array.prototype.forEach.call(document.querySelectorAll("#pad [data-dir]"), function (btn) {
      btn.addEventListener("pointerdown", function (e) {
        e.preventDefault();
        btn.classList.add("pressed");
        self.handler(btn.getAttribute("data-dir"), "pad", e);
      });
      var up = function () { btn.classList.remove("pressed"); };
      btn.addEventListener("pointerup", up);
      btn.addEventListener("pointerleave", up);
    });
  }

  Input.prototype.trackKonami = function (key) {
    var k = KEYS[key] && KEYS[key].length > 1 && /^(up|down|left|right)$/.test(KEYS[key]) && key.length > 1 ? KEYS[key] : key;
    this.konami.push(k);
    if (this.konami.length > KONAMI.length) this.konami.shift();
    if (this.konami.join(",") === KONAMI.join(",") && this.onKonami) {
      this.konami = [];
      this.onKonami();
    }
  };

  LM.Input = Input;
})(window.LUMEN);
