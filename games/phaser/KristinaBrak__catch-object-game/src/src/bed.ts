import { Physics } from "phaser";

export default class Bed {
  sprite: Physics.Arcade.Sprite;
  scene: Phaser.Scene;
  shade: Phaser.GameObjects.Graphics;
  used: boolean;

  constructor(scene: Phaser.Scene, name: string) {
    this.scene = scene;
    this.sprite = this.scene.physics.add.sprite(
      this.scene.scale.width,
      this.scene.scale.height,
      name
    );
    this.sprite.setScale(2, 2);
    this.sprite.setOrigin(1, 1); //rightbottom corner
    this.sprite.setDepth(0);
    this.used = false;
    this.createShade();
  }

  public sleep() {
    console.log("sleepu sleepu");
    // this.scene.cameras.main.backgroundColor = Phaser.Display.Color.HexStringToColor("#3498db");

    this.shade.setAlpha(0.98);
  }
  private createShade() {
    console.log("create shade");

    this.shade = new Phaser.GameObjects.Graphics(this.scene);
    this.shade.fillStyle(0x000000);
    this.shade.fillRect(0, 0, this.scene.scale.width, this.scene.scale.height);
    this.shade.setDepth(0.98);
    this.shade.setAlpha(0);
  }
}
