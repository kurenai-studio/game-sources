import { Bar } from "./bar";
import { Physics } from "phaser";
import Status from "./status";

export default class Player {
  private _statuses: Bar[];
  sprite: Physics.Arcade.Sprite;
  scene: Phaser.Scene;

  constructor(scene: Phaser.Scene, x: number, y: number, key: string) {
    this.scene = scene;
    this.sprite = scene.physics.add.sprite(x, y, "player");
    this.sprite.setScale(4, 4);
    this.sprite.setDepth(0.5);
  }

  createAnimations() {
    this.scene.anims.create({
      key: "idle",
      frames: this.makeAnimation("player", "player_idle_00", 4),
      frameRate: 8,
      repeat: -1,
    });
    this.scene.anims.create({
      key: "move",
      frames: this.makeAnimation("player", "player_walk_left_00", 6),
      frameRate: 8,
      repeat: -1,
    });
  }

  makeAnimation(key: string, frameName: string, numberOfFrames: number) {
    const myArray = [];
    for (let i = 1; i <= numberOfFrames; i++) {
      const fn = frameName + i + ".png";
      myArray.push({
        key: key,
        frame: fn,
      });
    }
    return myArray;
  }

  public set statuses(statuses: Status[]) {
    if (!this._statuses) {
      let y = 10;
      this._statuses = statuses.map((status) => {
        const bar = new Bar({ scene: this.scene, x: 10, y, status });
        y += 20;
        return bar;
      });
    } else {
      statuses.forEach((status, index) => {
        this._statuses[index].status = status;
      });
    }
  }
}
