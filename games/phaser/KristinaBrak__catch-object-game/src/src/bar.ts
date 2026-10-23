import Status from "./status";

interface BarInterface {
  scene: Phaser.Scene;
  x: number;
  y: number;
  status: Status;
}

export class Bar {
  scene: Phaser.Scene;
  bar_display: Phaser.GameObjects.Graphics;
  private _status: Status;
  bar_size = {
    width: 200,
    height: 25,
  };
  bar_frame_size = this.bar_size.width * 0.02;

  constructor({ scene, x, y, status }: BarInterface) {
    this.scene = scene;
    this.bar_display = new Phaser.GameObjects.Graphics(scene);
    this.bar_display.setX(x);
    this.bar_display.setY(y);
    this.bar_display.setDepth(0.99);
    this._status = status;
    this.draw();

    scene.add.existing(this.bar_display);
  }

  public draw() {
    this.bar_display.clear();
    this.createEmptyStatusBar();
    this.displayStatusChange();
    this.displayName();
  }
  private displayName() {
    const name: string = this._status.name;

    text: Phaser.GameObjects.Text;
    const { x, y } = this.calculateTextPosition();
    const text = this.scene.add.text(x, y, name, { color: "000" });
    text.depth = 1;
  }
  private calculateTextPosition() {
    return {
      x: this.bar_display.x * 2 + this.bar_frame_size + 5,
      y: this.bar_display.y * 2 + this.bar_frame_size,
    };
  }

  private createEmptyStatusBar() {
    //  Creating black fream and white background
    this.bar_display.fillStyle(0x000000);
    this.bar_display.fillRect(
      this.bar_display.x,
      this.bar_display.y,
      this.bar_size.width,
      this.bar_size.height
    );

    this.bar_display.fillStyle(0xffffff);
    this.bar_display.fillRect(
      this.bar_display.x + this.bar_frame_size,
      this.bar_display.y + this.bar_frame_size,
      this.bar_size.width - this.bar_frame_size * 2,
      this.bar_size.height - this.bar_frame_size * 2
    );
  }

  private displayStatusChange() {
    if (this._status.current_value !== 0) {
      this.changeStatusColor();
      let distance = Math.floor(
        (this._status.current_value / this._status.max_value) *
          this.bar_size.width -
          this.bar_frame_size * 2
      );
      this.bar_display.fillRect(
        this.bar_display.x + this.bar_frame_size,
        this.bar_display.y + this.bar_frame_size,
        distance,
        this.bar_size.height - this.bar_frame_size * 2
      );
    }
  }

  private changeStatusColor() {
    if (this._status.current_value <= 30) {
      this.bar_display.fillStyle(0xff0000);
    } else if (this._status.current_value <= 60) {
      this.bar_display.fillStyle(0xff9933);
    } else if (this._status.current_value <= 90) {
      this.bar_display.fillStyle(0xfff000);
    } else {
      this.bar_display.fillStyle(0x00ff00);
    }
  }

  public set status(status: Status) {
    this._status = status;
    this.draw();
  }
}
