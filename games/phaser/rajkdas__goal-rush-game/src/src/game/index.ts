/**
 * GOAL RUSH — game entry point.
 *
 * Creates the Phaser.Game instance bound to a DOM parent. The game module is
 * framework-agnostic: it can be embedded in this Next.js app (GameCanvas)
 * or dropped into any Vite project unchanged.
 */

import * as Phaser from 'phaser';
import { PHYSICS, TABLE } from './config/game.config';
import { BootScene } from './scenes/BootScene';
import { PlayScene } from './scenes/PlayScene';

export function createGame(parent: HTMLElement): Phaser.Game {
  const params = new URLSearchParams(window.location.search);
  const debug = params.has('debug');
  // `?renderer=canvas` — software-rendering fallback for headless/CI runs.
  const forceCanvas = params.has('canvas');

  const game = new Phaser.Game({
    type: forceCanvas ? Phaser.CANVAS : Phaser.AUTO,
    parent,
    width: TABLE.width,
    height: TABLE.height,
    backgroundColor: '#070b14',
    scale: {
      mode: Phaser.Scale.FIT,
      autoCenter: Phaser.Scale.CENTER_BOTH,
    },
    render: {
      antialias: true,
      powerPreference: 'high-performance',
    },
    fps: { target: 60, min: 30 },
    physics: {
      default: 'matter',
      matter: {
        gravity: { x: 0, y: PHYSICS.gravityY },
        positionIterations: PHYSICS.positionIterations,
        velocityIterations: PHYSICS.velocityIterations,
        enableSleeping: false,
        debug: debug
          ? { showBody: true, showStaticBody: true, showSensors: true }
          : false,
      },
    },
    scene: [BootScene, PlayScene],
  });
  // QA hook (mirrors window.__goalrush): lets automation reach the scenes.
  (window as unknown as Record<string, unknown>).__goalrushGame = game;
  return game;
}
