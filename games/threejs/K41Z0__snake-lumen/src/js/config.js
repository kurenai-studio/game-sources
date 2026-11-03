window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  // Every number worth tuning lives here. Rules read it, nothing writes it.
  LM.config = {
    version: "1.0.0",
    name: "Snake: Lumen",
    cols: 20,
    rows: 20,
    startLength: 4,
    start: { x: 5, y: 10, dx: 1, dy: 0 },

    minTickMs: 72,
    accelPerStar: 2.5,
    slowFactor: 1.75,
    turnQueue: 2,

    pointsPerStar: 10,
    pointsGolden: 50,
    comboWindowMs: 4000,
    comboStep: 0.5,

    goldenChance: 0.07,
    goldenTtlMs: 6500,
    goldenWallet: 5,
    itemChance: 0.2,
    itemTtlMs: 9000,
    itemFirstAfter: 3,
    effectMs: { slow: 8000, ghost: 7000, magnet: 9000, double: 10000 },
    magnetRange: 7,

    phasePeriod: 28,
    phaseWarnTicks: 7,

    endless: { tickStart: 140, worldEvery: 12, tableSize: 10 },
    daily: { tickStart: 130 },
    moonBonusWallet: 5,

    storageKey: "lumen.profile",

    powerups: {
      slow: { name: "Hush", color: "#8fb8ff", hint: "The night holds its breath" },
      ghost: { name: "Wisp", color: "#c9a8ff", hint: "Drift through your own tail" },
      magnet: { name: "Lodestar", color: "#ff9f8a", hint: "Stars drift toward you" },
      double: { name: "Radiance", color: "#ffd166", hint: "Every light counts twice" }
    },

    worlds: [
      { id: "garden", name: "Whispering Garden", blurb: "A garden asleep under a starless sky. Hedges and quiet paths." },
      { id: "city", name: "Sleeping City", blurb: "An old town asleep: dark windows, gates between streets, lantern trams that never stop." },
      { id: "sky", name: "Hollow Sky", blurb: "A hollow heaven above the clouds. The edges wrap around and small clouds drift by." },
      { id: "moon", name: "The Moon's Path", blurb: "Eclipse stones fade in and out on the road to the silent Moon." }
    ],

    skins: [
      { id: "lumen", name: "Lumen", price: 0, colors: ["#fff1b8", "#f2b84a"], belly: "#fffbe6", glow: "#ffd98a", pattern: "plain" },
      { id: "firefly", name: "Firefly", price: 40, colors: ["#d8f59a", "#62b346"], belly: "#f4ffd6", glow: "#c6f68d", pattern: "stripes" },
      { id: "ember", name: "Ember", price: 80, colors: ["#ffb170", "#e8590c"], belly: "#ffe0c2", glow: "#ff9a5a", pattern: "stripes" },
      { id: "tide", name: "Tide", price: 120, colors: ["#8be9fd", "#1c7ed6"], belly: "#d0f4ff", glow: "#74c0fc", pattern: "gradient" },
      { id: "blossom", name: "Blossom", price: 200, colors: ["#ffb3d9", "#fff0f6"], belly: "#ffe3f1", glow: "#ffa8d2", pattern: "stripes" },
      { id: "aurora", name: "Aurora", price: 300, colors: ["#7dffcf", "#b388ff"], belly: "#e6fff6", glow: "#96f2d7", pattern: "shimmer" },
      { id: "comet", name: "Comet", price: 400, colors: ["#e7f5ff", "#4dabf7"], belly: "#ffffff", glow: "#a5d8ff", pattern: "glitch" },
      { id: "nebula", name: "Nebula", price: 500, colors: ["#9775fa", "#2b1a5c"], belly: "#d0bfff", glow: "#b197fc", pattern: "galaxy" },
      { id: "sunlit", name: "Sunlit", price: 700, colors: ["#ffe066", "#c77d14"], belly: "#fff9db", glow: "#ffd43b", pattern: "metal" },
      { id: "prism", name: "Prism", price: 900, colors: ["#ff6b6b", "#4dabf7"], belly: "#ffffff", glow: "#ffffff", pattern: "rainbow" }
    ]
  };
})(window.LUMEN);
