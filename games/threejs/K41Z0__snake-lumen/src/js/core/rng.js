window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // Small seeded generator (mulberry32). Same seed, same sequence, on every machine.
  function Rng(seed) {
    this.state = (seed >>> 0) || 0x9e3779b9;
  }

  Rng.prototype.next = function () {
    var t = (this.state = (this.state + 0x6d2b79f5) >>> 0);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };

  Rng.prototype.int = function (n) {
    return Math.floor(this.next() * n);
  };

  Rng.prototype.pick = function (list) {
    return list[this.int(list.length)];
  };

  Rng.prototype.chance = function (p) {
    return this.next() < p;
  };

  // FNV-1a over a string: turns "2026-10-15" into a stable 32-bit seed.
  function hash(text) {
    var h = 0x811c9dc5;
    for (var i = 0; i < text.length; i++) {
      h ^= text.charCodeAt(i);
      h = Math.imul(h, 0x01000193);
    }
    return h >>> 0;
  }

  function randomSeed() {
    return (Math.floor(Math.random() * 4294967296) ^ Date.now()) >>> 0;
  }

  LM.Rng = Rng;
  LM.hash = hash;
  LM.randomSeed = randomSeed;
})(window.LUMEN);
