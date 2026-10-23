import * as Config from '../config.js';

export default class Water {
  constructor(scene) {
    this.scene = scene;
    this.graphics = scene.add.graphics();
    this.time = 0;
    this.render();
  }

  update(delta) {
    this.time += delta;
    this.render();
  }

  render() {
    this.graphics.clear();
    this.graphics.setDepth(5);

    // Water body
    this.graphics.fillStyle(Config.WATER_COLOR, 0.6);
    this.graphics.fillRect(0, Config.WATER_LEVEL, Config.GAME_WIDTH, Config.GAME_HEIGHT - Config.WATER_LEVEL);

    // Animated wave surface
    this.graphics.lineStyle(3, 0x4488cc, 0.8);
    this.graphics.beginPath();
    this.graphics.moveTo(0, Config.WATER_LEVEL);
    for (let x = 0; x <= Config.GAME_WIDTH; x += 4) {
      const wave = Math.sin(x * 0.03 + this.time * 0.002) * 3 +
                   Math.sin(x * 0.05 + this.time * 0.003) * 2;
      this.graphics.lineTo(x, Config.WATER_LEVEL + wave);
    }
    this.graphics.strokePath();

    // Surface shimmer
    this.graphics.lineStyle(1, 0x88bbee, 0.3);
    this.graphics.beginPath();
    this.graphics.moveTo(0, Config.WATER_LEVEL + 5);
    for (let x = 0; x <= Config.GAME_WIDTH; x += 4) {
      const wave = Math.sin(x * 0.04 + this.time * 0.001 + 1) * 2;
      this.graphics.lineTo(x, Config.WATER_LEVEL + 5 + wave);
    }
    this.graphics.strokePath();
  }

  destroy() {
    this.graphics.destroy();
  }
}
