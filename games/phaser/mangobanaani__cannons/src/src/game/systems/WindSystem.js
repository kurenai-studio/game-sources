import * as Config from '../config.js';

export default class WindSystem {
  constructor() {
    this.current = 0;
    this.target = 0;
    this.timer = 0;
    this.newTarget();
  }

  newTarget() {
    this.target = (Math.random() - 0.5) * 2 * Config.WIND_MAX;
  }

  update(delta) {
    this.timer += delta;

    if (this.timer >= Config.WIND_CHANGE_INTERVAL) {
      this.timer = 0;
      this.newTarget();
    }

    // Smooth lerp toward target
    this.current += (this.target - this.current) * Config.WIND_LERP_SPEED;
  }

  getWind() {
    return this.current;
  }

  reset() {
    this.current = 0;
    this.target = 0;
    this.timer = 0;
    this.newTarget();
  }
}
