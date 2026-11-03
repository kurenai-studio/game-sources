/**
 * ASHMAW — entry point.
 *
 * Deliberately tiny: it owns the boot UI and nothing else. Heavy systems are
 * pulled in with dynamic import() so the browser can stream them in parallel
 * with the first paint (native code-splitting, no bundler required).
 */

const bootEl    = document.getElementById('boot');
const fillEl    = document.getElementById('bootFill');
const statusEl  = document.getElementById('bootStatus');
const enterEl   = document.getElementById('bootEnter');

const setProgress = (t, label) => {
  fillEl.style.width = `${Math.round(Math.min(1, t) * 100)}%`;
  if (label) statusEl.textContent = label;
};

async function boot() {
  setProgress(0.04, 'Summoning WebGL…');

  // ── capability gate ────────────────────────────────────────────────
  const probe = document.createElement('canvas');
  const gl = probe.getContext('webgl2') || probe.getContext('webgl');
  if (!gl) {
    statusEl.innerHTML = 'This realm needs WebGL.<br>Try a recent Chrome, Edge, Firefox or Safari.';
    return;
  }

  try {
    setProgress(0.1, 'Loading engine…');
    const { App } = await import('./core/App.js');

    const app = new App({
      canvas: document.getElementById('stage'),
      onProgress: setProgress,
    });

    await app.build();

    setProgress(1, 'The wyrm stirs');
    enterEl.hidden = false;
    window.ASHMAW = app; // handy console handle

    const enter = () => {
      enterEl.removeEventListener('click', enter);
      bootEl.classList.add('is-gone');
      document.getElementById('hud').hidden = false;
      app.start();
      app.sound?.start();      // audio may only start inside a user gesture
      setTimeout(() => bootEl.remove(), 1600);
    };
    enterEl.addEventListener('click', enter);
  } catch (err) {
    console.error(err);
    statusEl.innerHTML = `Failed to raise the realm.<br><span style="letter-spacing:0;text-transform:none">${err.message}</span>`;
  }
}

boot();
