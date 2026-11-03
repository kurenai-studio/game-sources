window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var h = function () { return LM.dom.h.apply(null, arguments); };

  // Achievement unlock toasts: queued, one slides in at a time.
  function Toasts(root, onShow) {
    this.root = root;
    this.queue = [];
    this.busy = false;
    this.onShow = onShow;
  }

  Toasts.prototype.achievement = function (a) {
    this.queue.push({ kind: "ach", a: a });
    this.pump();
  };

  Toasts.prototype.info = function (text) {
    this.queue.push({ kind: "info", text: text });
    this.pump();
  };

  Toasts.prototype.pump = function () {
    if (this.busy || !this.queue.length) return;
    this.busy = true;
    var item = this.queue.shift();
    var el;
    if (item.kind === "ach") {
      var a = item.a;
      el = h("div.toast." + a.rarity, [
        h("img", { src: LM.icons.achievement(a, 52, "unlocked"), alt: "" }),
        h("div", [
          h("small", LM.t(a.cat === "secret" ? "ach.secret" : "ach.toast") + " \u00b7 " + LM.L.rarity(a.rarity)),
          h("b", LM.L.achName(a)),
          h("span", LM.L.achDesc(a))
        ])
      ]);
    } else {
      el = h("div.toast.info", h("b", item.text));
    }
    this.root.appendChild(el);
    void el.offsetWidth;
    el.classList.add("show");
    if (this.onShow) this.onShow(item);
    var self = this;
    var stay = item.kind === "ach" ? 3000 : 1500;
    setTimeout(function () {
      el.classList.add("hide");
      setTimeout(function () {
        if (el.parentNode) el.parentNode.removeChild(el);
        self.busy = false;
        self.pump();
      }, 320);
    }, stay);
  };

  LM.Toasts = Toasts;
})(window.LUMEN);
