import { Engine } from '@babylonjs/core/Engines/engine';

/**
 * Creates and configures the Babylon.js Engine
 */
export function createEngine(canvas: HTMLCanvasElement): Engine {
  const engine = new Engine(canvas, true, {
    preserveDrawingBuffer: false,
    stencil: true,
    audioEngine: true,
  });

  // Handle window resize
  window.addEventListener('resize', () => {
    engine.resize();
  });

  return engine;
}
