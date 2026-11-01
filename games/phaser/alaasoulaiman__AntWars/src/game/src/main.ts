// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Ant Wars slice 1: boots Phaser in portrait at a fixed world width, touch first, mouse and keys for desk tests.
import * as Phaser from 'phaser';
import { BootScene } from './game/BootScene';
import { GameScene } from './game/GameScene';
import { HudScene } from './game/HudScene';
import { VIEW_W } from './game/tuning';
import { pwaState, registerServiceWorker, type PwaState } from './pwa/pwa';
import { ANTLION_PITS } from './sim/roster';
import { ROCKS } from './sim/yard';

declare global {
  interface Window {
    /** Read only state for the smoke test and a curious playtester's console; it exists only with ?debug in the address. */
    __antwars?: {
      game: Phaser.Game;
      snapshot: () => Record<string, unknown> | null;
      kinds: () => Record<string, number> | null;
      hud: () => ReturnType<HudScene['readout']> | null;
      rocks: () => Array<{ x: number; y: number; r: number }>;
      pits: () => Array<{ x: number; y: number }>;
      /** Lane G9: every live predator, dart and enemy shot, to show the Yard holds still under a pick sheet. */
      yard: () => ReturnType<GameScene['yardSpots']> | null;
      /** Lane G7: the service worker as the page sees it (registered, in control, a new version waiting). */
      pwa: () => PwaState;
    };
  }
}

// The installable app: a built game registers its service worker (offline after the first visit); the dev server never does.
registerServiceWorker(import.meta.env.PROD);

/** The world width is fixed; the height follows the game box (the safe area), held to a portrait shape on a desktop. */
function viewHeight(): number {
  const box = document.getElementById('game');
  const w = Math.max(1, box && box.clientWidth > 0 ? box.clientWidth : window.innerWidth);
  const h = Math.max(1, box && box.clientHeight > 0 ? box.clientHeight : window.innerHeight);
  const aspect = Math.min(Math.max(w / h, 0.4), 0.5625);
  return Math.round(VIEW_W / aspect);
}

// iPhone Safari: keep pinch zoom, double tap zoom and rubber band scrolling away from the game.
const stop = (e: Event) => e.preventDefault();
for (const type of ['gesturestart', 'gesturechange', 'gestureend', 'dblclick']) {
  document.addEventListener(type, stop, { passive: false });
}
document.addEventListener('touchmove', stop, { passive: false });

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#16301a',
  banner: false,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: VIEW_W,
    height: viewHeight(),
  },
  input: { activePointers: 3 },
  physics: { default: 'arcade', arcade: { debug: false } },
  render: { antialias: true, powerPreference: 'high-performance' },
  fps: { target: 60 },
  scene: [BootScene, GameScene, HudScene],
});

/** ?debug in the address turns on the console hook below (VG2 note 6: no ladder build should expose the live game). */
function debugMode(): boolean {
  try {
    return new URLSearchParams(window.location.search).has('debug');
  } catch {
    return false;
  }
}

if (debugMode()) window.__antwars = {
  game,
  snapshot: () => {
    const scene = game.scene.getScene('game') as GameScene | null;
    if (!scene || !scene.snap) return null;
    return { ...scene.snap, owned: [...scene.snap.owned] };
  },
  kinds: () => {
    const scene = game.scene.getScene('game') as GameScene | null;
    return scene && scene.snap ? scene.kindCounts() : null;
  },
  hud: () => {
    const hud = game.scene.getScene('hud') as HudScene | null;
    return hud && hud.sys.isActive() ? hud.readout() : null;
  },
  rocks: () => ROCKS.map((r) => ({ x: r.x, y: r.y, r: r.r })),
  pits: () => ANTLION_PITS.map((p) => ({ x: p.x, y: p.y })),
  yard: () => {
    const scene = game.scene.getScene('game') as GameScene | null;
    return scene && scene.snap ? scene.yardSpots() : null;
  },
  pwa: () => pwaState(),
};
