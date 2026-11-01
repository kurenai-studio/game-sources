import Phaser from "phaser";
import { BASE_HEIGHT, BASE_WIDTH } from "../../constants/dimensions";

/**
 * Scene plugin exposing how much the current canvas differs from the base
 * design resolution, so sprites, speeds and UI can scale consistently.
 */
export class ResponsiveDimensionsPlugin extends Phaser.Plugins.ScenePlugin {
  public scaleFactor = 1;
  public scaleX = 1;
  public scaleY = 1;

  constructor(
    scene: Phaser.Scene,
    pluginManager: Phaser.Plugins.PluginManager,
    pluginKey: string
  ) {
    super(scene, pluginManager, pluginKey);
  }

  boot(): void {
    const { width, height } = this.scene!.scale;
    this.scaleX = width / BASE_WIDTH;
    this.scaleY = height / BASE_HEIGHT;
    this.scaleFactor = Math.min(this.scaleX, this.scaleY);
  }

  /** True when the device reports touch input (shows on-screen controls). */
  get isTouch(): boolean {
    return this.scene!.sys.game.device.input.touch;
  }
}
