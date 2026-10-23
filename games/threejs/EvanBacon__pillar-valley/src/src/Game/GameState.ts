import type { Renderer } from "three/webgpu";

import { RendererEvent, ResizeEvent } from "../components/GraphicsView";
import Game from "./Game";

export default class GameState {
  game: Game | null = null;
  renderer: Renderer | null = null;

  onContextCreateAsync = async ({
    renderer,
    width,
    height,
  }: RendererEvent) => {
    this.renderer = renderer;
    this.game = new Game(width, height, renderer);
    await this.game.loadAsync();
  };

  onTouchesBegan = () => {
    if (this.game) {
      this.game.onTouchesBegan();
    }
  };

  onResize = (layout: ResizeEvent) => {
    const width = layout.width;
    const height = layout.height;

    if (this.renderer) {
      this.renderer.setSize(width, height);
    }
    if (this.game?.camera) {
      this.game.camera.aspect = width / height;
      this.game.camera.updateProjectionMatrix();
    }
  };

  onRender = (delta: number, time: number) => {
    if (this.game) {
      this.game.update(delta, time);
      if (this.renderer) {
        this.renderer.render(this.game.scene!, this.game.camera!);
      }
    }
  };
}
