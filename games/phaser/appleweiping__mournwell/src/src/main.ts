import Phaser from 'phaser';
import '@/styles.css';
import { GAME_HEIGHT, GAME_WIDTH } from '@/game/config';
import { BootScene } from '@/game/scenes/BootScene';
import { GameScene } from '@/game/scenes/GameScene';
import { MenuScene } from '@/game/scenes/MenuScene';
import { createDebugBridge } from '@/game/systems/debug';
import { installTouchControls } from '@/game/systems/touch';
import { UiController } from '@/game/systems/ui';

const launchQuery = new URLSearchParams(window.location.search);
const touchLayoutRequested =
  launchQuery.get('mobile') === '1' || window.matchMedia('(hover: none), (pointer: coarse)').matches;
const getViewport = (): { width: number; height: number } =>
  touchLayoutRequested && window.innerHeight > window.innerWidth
    ? { width: 540, height: 720 }
    : { width: GAME_WIDTH, height: GAME_HEIGHT };
let viewport = getViewport();
document.documentElement.classList.toggle('mobile-game-layout', viewport.height > viewport.width);

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game-container',
  width: viewport.width,
  height: viewport.height,
  backgroundColor: '#09080b',
  transparent: false,
  scene: [BootScene, MenuScene, GameScene],
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: false,
    },
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: viewport.width,
    height: viewport.height,
  },
  input: {
    activePointers: 3,
    smoothFactor: 0.2,
  },
  render: {
    antialias: true,
    roundPixels: false,
    powerPreference: 'high-performance',
  },
  fps: {
    target: 60,
    forceSetTimeOut: false,
  },
  banner: false,
});

const removeTouchControls = installTouchControls();
const ui = new UiController(game);
window.__game = createDebugBridge(game);

const syncViewport = (): void => {
  const next = getViewport();
  if (next.width === viewport.width && next.height === viewport.height) return;
  viewport = next;
  document.documentElement.classList.toggle('mobile-game-layout', viewport.height > viewport.width);
  game.scale.setGameSize(viewport.width, viewport.height);
  const gameScene = game.scene.getScene('GameScene') as GameScene;
  if (gameScene && (gameScene.scene.isActive() || gameScene.scene.isPaused())) gameScene.syncViewport();
  const menuScene = game.scene.getScene('MenuScene') as MenuScene;
  if (menuScene?.scene.isActive()) menuScene.syncViewport();
};
window.addEventListener('resize', syncViewport);

window.addEventListener(
  'beforeunload',
  () => {
    window.removeEventListener('resize', syncViewport);
    removeTouchControls();
    ui.destroy();
    game.destroy(true);
  },
  { once: true },
);
