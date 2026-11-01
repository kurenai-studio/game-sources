import type { Engine } from '@babylonjs/core/Engines/engine';
import type { Scene } from '@babylonjs/core/scene';

/**
 * Manages the render loop and delta time
 */
export class RenderSystem {
  private engine: Engine;
  private scene: Scene;
  private lastTime = 0;
  private deltaTime = 0;

  constructor(engine: Engine, scene: Scene) {
    this.engine = engine;
    this.scene = scene;
  }

  /**
   * Get the time elapsed since the last frame (in seconds)
   */
  getDeltaTime(): number {
    return this.deltaTime;
  }

  /**
   * Start the render loop
   */
  startRenderLoop(onFrame: (deltaTime: number) => void) {
    this.lastTime = performance.now();

    this.engine.runRenderLoop(() => {
      const currentTime = performance.now();
      this.deltaTime = (currentTime - this.lastTime) / 1000;
      this.lastTime = currentTime;

      onFrame(this.deltaTime);
      this.scene.render();
    });
  }

  /**
   * Stop the render loop
   */
  stopRenderLoop() {
    this.engine.stopRenderLoop();
  }
}
