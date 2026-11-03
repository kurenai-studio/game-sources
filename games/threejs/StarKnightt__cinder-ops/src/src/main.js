import * as THREE from 'three';
import { Game } from './core/Game.js';
import { Shell } from './ui/Menu.js';

function wantsAutostart() {
  try {
    const q = new URLSearchParams(location.search);
    if (q.has('autostart') && q.get('autostart') !== '0') return true;
  } catch { /* ignore */ }
  return /(^|[#&])manual(&|$)/.test(location.hash);
}

async function boot() {
  const shell = new Shell();
  const game = new Game(document.getElementById('view'));
  game.manual = /(^|[#&])manual(&|$)/.test(location.hash);
  const autostart = wantsAutostart();

  await game.init({
    onProgress: (p) => shell.setProgress(p.pct, p.label),
    uncapped: autostart,
  });

  window.__game = game;
  window.THREE = THREE;
  game.attachShell(shell);

  if (autostart) game.skipMenu();
  else {
    game.begin();
    shell.showMenu({ resume: false });
  }
  return game;
}

boot();
