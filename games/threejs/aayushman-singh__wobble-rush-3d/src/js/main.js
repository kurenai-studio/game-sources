/* Boot: verify Three.js loaded and WebGL is available, then start.
   Any failure here shows a clear, visible error — no silent fallbacks. */
'use strict';

(function () {
  function fatal(msg) {
    const overlay = document.getElementById('error-overlay');
    const msgEl = document.getElementById('error-message');
    if (overlay && msgEl) {
      msgEl.textContent = msg;
      overlay.classList.remove('hidden');
    } else {
      alert(msg);
    }
  }

  if (typeof THREE === 'undefined') {
    fatal('Three.js could not be loaded: "vendor/three.min.js" is missing or was blocked. ' +
          'Keep the vendor folder next to index.html (or re-download three.js r128 into it) and reload the page.');
    return;
  }

  try {
    const game = new Game();
    window.WR = { game: game }; // handy handle for debugging
    game.boot();
  } catch (err) {
    console.error(err);
    fatal('Wobble Rush 3D failed to start: ' + (err && err.message ? err.message : err) +
          '. Your browser may not support WebGL — try a recent version of Chrome, Edge, Firefox or Safari.');
  }
})();
