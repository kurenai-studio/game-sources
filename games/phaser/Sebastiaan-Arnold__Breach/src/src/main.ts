import '@fontsource/barlow-condensed/latin-600.css';
import '@fontsource/barlow-condensed/latin-700.css';
import '@fontsource/jetbrains-mono/latin-400.css';
import '@fontsource/jetbrains-mono/latin-700.css';
import Phaser from 'phaser';
import { COLORS, RENDER_SCALE, VIEW_H, VIEW_W } from './config';
import { BriefingScene } from './scenes/BriefingScene';
import { GameScene } from './scenes/GameScene';
import { HudScene } from './scenes/HudScene';
import { MenuScene } from './scenes/MenuScene';
import { PromotionScene } from './scenes/PromotionScene';
import { TitleScene } from './scenes/TitleScene';

/** Text is drawn to canvas, so the fonts have to be ready before the first screen is built. */
async function loadFonts(): Promise<void> {
  try {
    await Promise.all(['600 20px "Barlow Condensed"', '700 20px "Barlow Condensed"', '400 14px "JetBrains Mono"', '700 14px "JetBrains Mono"']
      .map((f) => document.fonts.load(f)));
  } catch {
    // The fallback fonts in config.ts take over.
  }
}

await loadFonts();
document.getElementById('loader')?.remove();

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  width: VIEW_W * RENDER_SCALE,
  height: VIEW_H * RENDER_SCALE,
  backgroundColor: COLORS.void,
  // 16:9, scaled to fit: the same layout has to work on a phone later.
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  render: { antialias: true },
  input: { activePointers: 2 },
  scene: [TitleScene, MenuScene, BriefingScene, GameScene, HudScene, PromotionScene],
});

if (import.meta.env.DEV) (window as unknown as { game: Phaser.Game }).game = game;
