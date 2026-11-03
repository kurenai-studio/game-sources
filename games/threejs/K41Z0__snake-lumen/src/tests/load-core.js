// Loads the pure core into node the same way the page does: plain scripts
// sharing one global `window.LUMEN`. No DOM is provided, so any DOM use would throw.
var fs = require("fs");
var path = require("path");
var vm = require("vm");

var FILES = [
  "js/config.js", "js/i18n/i18n.js", "js/i18n/en.js", "js/i18n/ru.js", "js/core/rng.js", "js/core/board.js", "js/core/snake.js", "js/core/levels.js",
  "js/core/game.js", "js/core/daily.js", "js/core/autopilot.js", "js/core/profile.js",
  "js/core/achievements.js"
];

module.exports = function loadCore() {
  var sandbox = { console: console, Math: Math, Date: Date, Uint8Array: Uint8Array, JSON: JSON };
  sandbox.window = sandbox;
  vm.createContext(sandbox);
  FILES.forEach(function (f) {
    var file = path.join(__dirname, "..", f);
    vm.runInContext(fs.readFileSync(file, "utf8"), sandbox, { filename: file });
  });
  return sandbox.LUMEN;
};
module.exports.FILES = FILES;
