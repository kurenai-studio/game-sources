import { Bar } from "./bar";
import { Physics, Scene } from "phaser";
import Player from "./player";
import ChasedObject from "./chased-object";
import DataHandler from "./data-handler/data-handler";
import Bed from "./bed";

const sceneConfig: Phaser.Types.Scenes.SettingsConfig = {
  active: false,
  visible: false,
  key: "Game",
};

export class GameScene extends Phaser.Scene {
  player: Player;
  heart: ChasedObject;
  bed: Bed;
  velocity = 500;
  dataHandler: DataHandler;
  ws: WebSocket;

  destinationToMouse = { x: 0, y: 0 };
  destinationToHeart = { x: 0, y: 0 };

  constructor() {
    super(sceneConfig);
  }

  public preload() {
    this.load.image("heart", "assets/heart/heart_full.png");
    this.load.atlas(
      "player",
      "assets/player/player.png",
      "assets/player/player.json"
    );
    this.load.image("bed", "assets/carpet.png");
  }

  public create(ws: WebSocket) {
    this.player = new Player(this, 400, 400, "player");
    this.heart = new ChasedObject(this, this.player, "heart");
    this.bed = new Bed(this, "bed");

    this.ws = ws;

    const dataHandler = new DataHandler(this.player);

    this.ws.onmessage = (event) => {
      dataHandler.getMessage(event.data);
    };

    this.dataHandler = new DataHandler(this.player);

    function onClick(pointer: Phaser.Input.Pointer, scene: GameScene) {
      scene.destinationToMouse.x = pointer.x;
      scene.destinationToMouse.y = pointer.y;

      if (scene.destinationToMouse.x - scene.player.sprite.body.x < 0) {
        scene.player.sprite.play("move").setFlipX(false);
      } else {
        scene.player.sprite.play("move").setFlipX(true);
      }
      scene.physics.moveTo(
        scene.player.sprite,
        pointer.x,
        pointer.y,
        scene.velocity
      );
      // console.log("initial: ", scene.destination);
    }

    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) =>
      onClick(pointer, this)
    );

    this.player.createAnimations();

    this.physics.add.overlap(
      this.player.sprite,
      this.heart.sprite,
      () => this.heart.move(),
      null,
      this
    );

    this.physics.add.overlap(
      this.player.sprite,
      this.bed.sprite,
      () => this.bed.sleep(),
      null,
      this
    );
  }

  changeMoveAnimation(player: Phaser.Scene, destinationX: number) {
    if (destinationX - this.player.sprite.body.x < 0) {
      this.player.sprite.play("move").setFlipX(false);
    } else {
      this.player.sprite.play("move").setFlipX(true);
    }
  }

  makeAnim(key: string, frameName: string, numberOfFrames: number) {
    let myArray = [];
    for (let i = 1; i <= numberOfFrames; i++) {
      let fn = frameName + i + ".png";
      myArray.push({
        key: key,
        frame: fn,
      });
    }
    return myArray;
  }

  public update() {
    const distMouse = Phaser.Math.Distance.Between(
      this.player.sprite.x,
      this.player.sprite.y,
      this.destinationToMouse.x,
      this.destinationToMouse.y
    );

    if (distMouse <= 10) {
      this.player.sprite.body.velocity.setTo(0, 0);
      this.player.sprite.play("idle");
      this.destinationToMouse.x = 0;
      this.destinationToMouse.y = 0;
    }

    // const distBed = Phaser.Math.Distance.Between(
    //   this.player.sprite.x,
    //   this.player.sprite.y,
    //   this.bed.sprite.x,
    //   this.bed.sprite.y
    // );
    // if (distBed <= this.bed.sprite.height) {
    //   this.player.sprite.body.velocity.setTo(0, 0);
    //   this.player.sprite.play("idle");
    //   this.bed.used = true;
    // }
    // this.bed.used = false;
  }
}
