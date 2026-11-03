window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // h("div.card#id", { onclick: fn, "data-nav": "" }, [children or text])
  function h(sel, attrs, kids) {
    if (Array.isArray(attrs) || typeof attrs === "string" || attrs instanceof Node) { kids = attrs; attrs = null; }
    var m = sel.match(/^([a-z0-9]+)?((?:[.#][\w-]+)*)$/i);
    var el = document.createElement((m && m[1]) || "div");
    if (m && m[2]) {
      m[2].replace(/([.#])([\w-]+)/g, function (_, kind, name) {
        if (kind === ".") el.classList.add(name);
        else el.id = name;
      });
    }
    if (attrs) {
      for (var k in attrs) {
        var v = attrs[k];
        if (v === null || v === undefined || v === false) continue;
        if (k.indexOf("on") === 0 && typeof v === "function") el.addEventListener(k.slice(2), v);
        else if (k === "html") el.innerHTML = v;
        else if (k === "style" && typeof v === "object") { for (var s in v) el.style.setProperty(s, v[s]); }
        else el.setAttribute(k, v === true ? "" : v);
      }
    }
    append(el, kids);
    return el;
  }

  function append(el, kids) {
    if (kids === undefined || kids === null || kids === false) return;
    if (!Array.isArray(kids)) kids = [kids];
    for (var i = 0; i < kids.length; i++) {
      var c = kids[i];
      if (c === null || c === undefined || c === false) continue;
      if (Array.isArray(c)) append(el, c);
      else el.appendChild(c instanceof Node ? c : document.createTextNode(String(c)));
    }
  }

  function moons(n, total) {
    var out = h("span.moons");
    for (var i = 0; i < (total || 3); i++) out.appendChild(h("span" + (i < n ? ".on" : ""), "\u263E"));
    return out;
  }

  // Screen manager: one screen at a time, cross-faded, with a focused element.
  function Screens(root, sounds) {
    this.root = root;
    this.current = null;
    this.name = "";
    this.sounds = sounds;
    this.focusEl = null;
    var self = this;
    root.addEventListener("pointerover", function (e) {
      var t = e.target.closest && e.target.closest("[data-nav]");
      if (t && self.current && self.current.el.contains(t) && !t.disabled) self.focus(t, true);
    });
  }

  // def: { el, back: fn, onKey: fn(action) -> handled, focus: element }
  Screens.prototype.show = function (name, def) {
    var old = this.current;
    if (old) {
      old.el.classList.remove("active");
      old.el.classList.add("leave");
      if (old.onLeave) old.onLeave();
      setTimeout(function () { if (old.el.parentNode) old.el.parentNode.removeChild(old.el); }, 360);
    }
    this.current = def;
    this.name = name;
    def.el.classList.add("screen");
    def.el.setAttribute("data-screen", name);
    this.root.appendChild(def.el);
    void def.el.offsetWidth;
    def.el.classList.add("active");
    this.focusEl = null;
    var first = def.focus || LM.nav.items(def.el)[0];
    if (first) this.focus(first, true);
  };

  Screens.prototype.hide = function () {
    if (!this.current) return;
    var old = this.current;
    this.current = null;
    this.name = "";
    old.el.classList.remove("active");
    old.el.classList.add("leave");
    if (old.onLeave) old.onLeave();
    setTimeout(function () { if (old.el.parentNode) old.el.parentNode.removeChild(old.el); }, 360);
  };

  Screens.prototype.focus = function (el, quiet) {
    if (!el) return;
    if (this.focusEl === el) return;
    if (this.focusEl) this.focusEl.classList.remove("focus");
    this.focusEl = el;
    el.classList.add("focus");
    try { el.focus({ preventScroll: true }); } catch (e) { el.focus(); }
    if (el.scrollIntoView) {
      var r = el.getBoundingClientRect();
      if (r.top < 60 || r.bottom > window.innerHeight - 20) el.scrollIntoView({ block: "center", behavior: "smooth" });
    }
    if (!quiet && this.sounds) this.sounds.uiMove();
  };

  Screens.prototype.handle = function (action) {
    var cur = this.current;
    if (!cur) return false;
    if (cur.onKey && cur.onKey(action, this.focusEl)) return true;
    if (action === "up" || action === "down" || action === "left" || action === "right") {
      if (this.focusEl && this.focusEl.tagName === "INPUT" && this.focusEl.type === "range" && (action === "left" || action === "right")) return true;
      var next = LM.nav.move(cur.el, this.focusEl, action);
      if (next) this.focus(next);
      return true;
    }
    if (action === "confirm" || (action === "pause" && this.focusEl && this.focusEl.tagName !== "INPUT")) {
      if (this.focusEl && !this.focusEl.disabled) this.focusEl.click();
      return true;
    }
    if (action === "back" && cur.back) {
      if (this.sounds) this.sounds.uiBack();
      cur.back();
      return true;
    }
    return false;
  };

  LM.dom = { h: h, moons: moons, Screens: Screens };
})(window.LUMEN);
