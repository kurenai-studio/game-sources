// Update Manager - Optimized update scheduling with frame skipping
export class UpdateManager {
  constructor() {
    this.updateIntervals = {
      particles: 1,      // Every frame
      bullets: 1,        // Every frame
      obstacles: 1,      // Every frame
      energies: 1,       // Every frame
      powerups: 1,       // Every frame
      boss: 1,           // Every frame
      stars: 2,          // Every 2 frames
      floatingTexts: 1,  // Every frame
      ui: 2,             // Every 2 frames
      autoAim: 2,        // Every 2 frames
      magnet: 2          // Every 2 frames
    };
    
    this.lastUpdateTimes = {};
    this.frameCount = 0;
  }

  shouldUpdate(systemName, frameCount) {
    const interval = this.updateIntervals[systemName] || 1;
    return frameCount % interval === 0;
  }

  setUpdateInterval(systemName, interval) {
    this.updateIntervals[systemName] = interval;
  }

  reset() {
    this.lastUpdateTimes = {};
    this.frameCount = 0;
  }

  incrementFrame() {
    this.frameCount++;
  }
}





