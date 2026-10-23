import * as Config from '../config.js';

export default class PredictionLine {
  constructor(scene) {
    this.scene = scene;
    this.graphics = scene.add.graphics();
    this.graphics.setDepth(10);
  }

  update(cannon, wind, weaponSpeedMult = 1) {
    this.graphics.clear();

    if (!cannon) return;

    const tip = cannon.getBarrelTip();
    const dir = cannon.isPlayer ? 1 : -1;

    let vx = cannon.power * Math.cos(cannon.angle) * dir * weaponSpeedMult;
    let vy = -cannon.power * Math.sin(cannon.angle) * weaponSpeedMult;

    let x = tip.x;
    let y = tip.y;

    this.graphics.fillStyle(0xffffff, 0.4);

    for (let i = 0; i < Config.PREDICTION_STEPS; i++) {
      vx += wind * Config.WIND_ACCEL;
      vy += Config.PREDICTION_GRAVITY;
      x += vx;
      y += vy;

      if (x < 0 || x > Config.GAME_WIDTH || y > Config.GAME_HEIGHT) break;

      if (i % Config.PREDICTION_DOT_SPACING === 0) {
        this.graphics.fillCircle(x, y, 2);
      }
    }
  }

  destroy() {
    this.graphics.destroy();
  }
}
