import * as Config from '../config.js';

export default class PowerUp {
  constructor(scene, x, y, type) {
    this.scene = scene;
    this.x = x;
    this.y = y;
    this.type = type;
    this.alive = true;

    const config = Config.POWERUP_TYPES[type];
    this.color = config ? config.color : 0xffffff;
    this.label = config ? config.label : '?';

    this.graphics = scene.add.graphics();
    this.text = scene.add.text(x, y, this.label, {
      fontSize: '10px',
      fill: '#fff',
      fontFamily: 'monospace',
      fontStyle: 'bold',
    }).setOrigin(0.5);

    this.render();
  }

  update() {
    this.y += Config.POWERUP_FALL_SPEED;
    this.text.setPosition(this.x, this.y);
    this.render();
  }

  render() {
    this.graphics.clear();
    this.graphics.fillStyle(this.color, 0.8);
    this.graphics.fillCircle(this.x, this.y, 12);
    this.graphics.lineStyle(2, 0xffffff, 0.6);
    this.graphics.strokeCircle(this.x, this.y, 12);
  }

  destroy() {
    this.alive = false;
    this.graphics.destroy();
    this.text.destroy();
  }
}
