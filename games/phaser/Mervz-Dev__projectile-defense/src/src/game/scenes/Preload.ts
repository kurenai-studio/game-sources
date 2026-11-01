import { Scene } from "phaser";

export class Preload extends Scene {
  constructor() {
    super("Preload");
  }

  preload() {
    const { width, height } = this.scale;
    const barWidth = Math.min(320, width * 0.6);
    const barHeight = 16;

    this.add
      .text(width / 2, height / 2 - 30, "Loading...", { fontSize: 24 })
      .setOrigin(0.5);

    const track = this.add
      .rectangle(width / 2, height / 2 + 10, barWidth, barHeight, 0xffffff, 0.2)
      .setOrigin(0.5);
    const fill = this.add
      .rectangle(
        track.x - barWidth / 2,
        track.y,
        0,
        barHeight,
        0x00ff88
      )
      .setOrigin(0, 0.5);

    this.load.on("progress", (value: number) => {
      fill.width = barWidth * value;
    });

    this.load.setPath("assets");

    this.load.image("bg", "bg.png");
    this.load.image("ship", "ships/ship_1.png");
    this.load.image("missile", "missiles/missile_1.png");

    this.load.image("pink_enemy", "enemies/pink_alien.png");
    this.load.image("green_enemy", "enemies/green_alien.png");
    this.load.image("blue_enemy", "enemies/blue_alien.png");

    this.load.image("logo", "logo.png");

    this.load.audio("gun", "audio/gun_1.wav");

    this.load.image("circle_button", "ui/controls/button_circle.png");
    this.load.image("crosshair", "ui/controls/icon_crosshair.png");
    this.load.image("down_button", "ui/controls/dpad_element_north.png");
    this.load.image("up_button", "ui/controls/dpad_element_south.png");
  }

  create() {
    this.scene.start("Game");
  }
}
