window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // localStorage when the browser allows it (some block it for file:// pages),
  // an in-memory stand-in when it does not. The game plays either way.
  function Storage(key) {
    this.key = key;
    this.ok = false;
    try {
      var probe = "__sy2_probe__";
      window.localStorage.setItem(probe, "1");
      window.localStorage.removeItem(probe);
      this.ok = true;
    } catch (e) {
      this.ok = false;
    }
    this.memory = null;
  }

  Storage.prototype.load = function () {
    var raw = null;
    if (this.ok) {
      try { raw = window.localStorage.getItem(this.key); } catch (e) { raw = null; }
    } else {
      raw = this.memory;
    }
    if (!raw) return LM.profile.create();
    try {
      return LM.profile.normalize(JSON.parse(raw));
    } catch (e) {
      return LM.profile.create();
    }
  };

  Storage.prototype.save = function (profile) {
    var raw = JSON.stringify(profile);
    if (!this.ok) { this.memory = raw; return false; }
    try {
      window.localStorage.setItem(this.key, raw);
      return true;
    } catch (e) {
      this.memory = raw;
      return false;
    }
  };

  Storage.prototype.clear = function () {
    this.memory = null;
    if (!this.ok) return;
    try { window.localStorage.removeItem(this.key); } catch (e) { /* ignore */ }
  };

  LM.Storage = Storage;
})(window.LUMEN);
