/* ==========================================================================
   30 NOCHES - main.js
   Punto de entrada: crea el juego, engancha el audio al primer gesto del
   usuario y arranca el bucle de requestAnimationFrame.
   ========================================================================== */
(function () {
  'use strict';

  function boot() {
    const canvas = document.getElementById('game');
    if (!canvas || !window.TN || !TN.Game) {
      console.error('[TN] No se pudo iniciar el juego: faltan elementos o modulos.');
      return;
    }

    let game;
    try {
      game = new TN.Game(canvas);
    } catch (err) {
      console.error('[TN] Error al crear la partida inicial', err);
      const msg = document.createElement('div');
      msg.style.cssText = 'position:fixed;inset:0;display:flex;align-items:center;justify-content:center;' +
        'color:#e05a4a;font:16px sans-serif;padding:24px;text-align:center;background:#0b120d';
      msg.textContent = 'Error al iniciar 30 NOCHES: ' + (err && err.message ? err.message : err);
      document.body.appendChild(msg);
      return;
    }

    // El audio solo puede iniciarse tras una interaccion del usuario.
    const unlock = function () {
      game.audio.init();
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };
    window.addEventListener('pointerdown', unlock);
    window.addEventListener('keydown', unlock);

    // La partida se guarda al cerrar o recargar la pagina.
    window.addEventListener('beforeunload', function () {
      if (game.state === 'playing' || game.state === 'paused') game.saveMgr.save();
    });

    window.addEventListener('blur', function () {
      if (game.state === 'playing' && !game.ui.current) {
        game.ui.open('pause');
        game.saveMgr.save();
      }
    });

    game.start();

    // Expuesto para depuracion manual desde la consola del navegador.
    window.TN_GAME = game;
    if (TN.Config.DEBUG.enabled) {
      console.log('[TN] 30 NOCHES listo. Usa TN_GAME para inspeccionar el estado.');
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
