import * as Config from '../config.js';

export default class Background {
  constructor(scene) {
    this.scene = scene;
    this.layers = [];
    this.createLayers();
  }

  createLayers() {
    // Layer 0: Sky gradient (drawn once, not scrollable)
    const skyGfx = this.scene.add.graphics();
    skyGfx.setDepth(-30);
    this.drawSkyGradient(skyGfx);
    this.layers.push(skyGfx);

    // Layer 1: Distant hills silhouette
    const hillsGfx = this.scene.add.graphics();
    hillsGfx.setDepth(-20);
    this.drawHills(hillsGfx);
    this.layers.push(hillsGfx);

    // Layer 2: Clouds
    this.clouds = [];
    for (let i = 0; i < 5; i++) {
      const cloud = this.createCloud(
        Math.random() * Config.GAME_WIDTH,
        40 + Math.random() * 80
      );
      cloud.setDepth(-10);
      this.clouds.push(cloud);
    }
  }

  drawSkyGradient(gfx) {
    const steps = 20;
    const stepH = Config.GAME_HEIGHT / steps;
    for (let i = 0; i < steps; i++) {
      const t = i / steps;
      // Sky blue to lighter blue
      const r = Math.floor(135 + t * 80);
      const g = Math.floor(206 + t * 30);
      const b = Math.floor(235 + t * 10);
      const color = (r << 16) | (g << 8) | b;
      gfx.fillStyle(color);
      gfx.fillRect(0, i * stepH, Config.GAME_WIDTH, stepH + 1);
    }
  }

  drawHills(gfx) {
    gfx.fillStyle(0x4a6741, 0.3);
    gfx.beginPath();
    gfx.moveTo(0, 350);
    for (let x = 0; x <= Config.GAME_WIDTH; x += 40) {
      const y = 280 + Math.sin(x * 0.01) * 40 + Math.sin(x * 0.025) * 20;
      gfx.lineTo(x, y);
    }
    gfx.lineTo(Config.GAME_WIDTH, Config.GAME_HEIGHT);
    gfx.lineTo(0, Config.GAME_HEIGHT);
    gfx.closePath();
    gfx.fillPath();
  }

  createCloud(x, y) {
    const gfx = this.scene.add.graphics();
    gfx.fillStyle(0xffffff, 0.5);
    const w = 40 + Math.random() * 60;
    gfx.fillEllipse(x, y, w, 20 + Math.random() * 10);
    gfx.fillEllipse(x + w * 0.3, y - 5, w * 0.6, 15);
    gfx.fillEllipse(x - w * 0.2, y + 3, w * 0.5, 12);
    return gfx;
  }

  update(delta) {
    // Drift clouds slowly
    for (const cloud of this.clouds) {
      cloud.x += 0.01 * delta;
      if (cloud.x > Config.GAME_WIDTH + 100) {
        cloud.x = -100;
      }
    }
  }

  applyTint(tint) {
    // Apply day/night tint by adjusting alpha overlay
    // Simple approach: tint the sky layer
    if (this.tintOverlay) {
      this.tintOverlay.destroy();
    }

    if (tint === 0xffffff) return; // No tint needed for day

    this.tintOverlay = this.scene.add.graphics();
    this.tintOverlay.setDepth(-5);

    // Extract RGB and apply as semi-transparent overlay
    const r = (tint >> 16) & 0xff;
    const g = (tint >> 8) & 0xff;
    const b = tint & 0xff;

    // If tint is darker than white, apply darkening overlay
    const avgBright = (r + g + b) / 3;
    if (avgBright < 255) {
      const alpha = 1 - (avgBright / 255);
      const tintColor = (r << 16) | (g << 8) | b;
      this.tintOverlay.fillStyle(tintColor, alpha * 0.3);
      this.tintOverlay.fillRect(0, 0, Config.GAME_WIDTH, Config.GAME_HEIGHT);
    }
  }

  destroy() {
    for (const layer of this.layers) {
      layer.destroy();
    }
    for (const cloud of this.clouds) {
      cloud.destroy();
    }
    if (this.tintOverlay) {
      this.tintOverlay.destroy();
    }
  }
}
