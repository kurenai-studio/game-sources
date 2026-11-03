// Graphics quality is independent of the art style: every look can run at every level.
// Measured cost order (Golden Hour): MSAA > resolution > bloom > shadows; ocean mesh size is negligible.
// 4x MSAA cost almost twice 2x for no visible gain at Retina density, so High stops at 2x.

export const QUALITY = {
  high: { label: 'High', maxPixelRatio: 1.75, samples: 2, shadowMap: 2048, bloom: true, fxaa: false, waterSegments: 300 },
  medium: { label: 'Medium', maxPixelRatio: 1.25, samples: 0, shadowMap: 1024, bloom: true, fxaa: true, waterSegments: 200 },
  low: { label: 'Low', maxPixelRatio: 1, samples: 0, shadowMap: 0, bloom: false, fxaa: true, waterSegments: 150 },
};

export const LEVELS = ['high', 'medium', 'low'];

export function initialLevel() {
  const weak = (navigator.hardwareConcurrency || 8) <= 4 || /Android|iPhone|iPad/i.test(navigator.userAgent);
  return weak ? 'medium' : 'high';
}

// Watches the frame rate and steps quality down when the machine can't keep up.
// It never steps back up, so it can't flip-flop between levels.
export class AutoQuality {
  constructor(onSlow) {
    this.onSlow = onSlow;
    this.settle(3);
  }

  // Ignore the next few seconds (scene rebuilds cause a hitch).
  settle(seconds) {
    this.wait = seconds;
    this.frames = 0;
    this.time = 0;
  }

  sample(dt) {
    if (dt > 0.25 || document.hidden) return; // tab switch or one-off stall
    if (this.wait > 0) { this.wait -= dt; return; }
    this.frames++;
    this.time += dt;
    if (this.time < 4) return;
    const fps = this.frames / this.time;
    this.settle(1.5);
    if (fps < 45) this.onSlow(fps);
  }
}
