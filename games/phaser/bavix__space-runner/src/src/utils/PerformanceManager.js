// Performance Manager - Monitors and optimizes game performance
export class PerformanceManager {
  constructor() {
    this.frameTimes = [];
    this.maxFrameTimeHistory = 60; // Keep last 60 frames
    this.fps = 60;
    this.avgFrameTime = 16.67; // 60fps = 16.67ms per frame
    this.lastFrameTime = 0;
    this.performanceMode = 'normal'; // 'normal', 'high', 'low'
    this.adaptiveOptimizations = true;
  }

  /**
   * Record frame time
   */
  recordFrame(time) {
    if (this.lastFrameTime > 0) {
      const frameTime = time - this.lastFrameTime;
      this.frameTimes.push(frameTime);
      
      if (this.frameTimes.length > this.maxFrameTimeHistory) {
        this.frameTimes.shift();
      }
      
      // Calculate average
      let sum = 0;
      for (let i = 0; i < this.frameTimes.length; i++) {
        sum += this.frameTimes[i];
      }
      this.avgFrameTime = sum / this.frameTimes.length;
      this.fps = 1000 / this.avgFrameTime;
      
      // Adaptive performance mode
      if (this.adaptiveOptimizations) {
        this.updatePerformanceMode();
      }
    }
    
    this.lastFrameTime = time;
  }

  /**
   * Update performance mode based on FPS
   */
  updatePerformanceMode() {
    if (this.fps < 45) {
      this.performanceMode = 'low';
    } else if (this.fps < 55) {
      this.performanceMode = 'normal';
    } else {
      this.performanceMode = 'high';
    }
  }

  /**
   * Get recommended update interval for system
   */
  getRecommendedInterval(systemName) {
    if (this.performanceMode === 'low') {
      const lowModeIntervals = {
        stars: 3,
        ui: 3,
        autoAim: 3,
        magnet: 3,
        particles: 2
      };
      return lowModeIntervals[systemName] || 2;
    } else if (this.performanceMode === 'high') {
      return 1; // Update every frame
    } else {
      // Normal mode - default intervals
      const normalModeIntervals = {
        stars: 2,
        ui: 2,
        autoAim: 2,
        magnet: 2,
        particles: 1
      };
      return normalModeIntervals[systemName] || 1;
    }
  }

  /**
   * Check if should skip update for performance
   */
  shouldSkipUpdate(systemName, frameCount) {
    if (this.performanceMode === 'low') {
      const interval = this.getRecommendedInterval(systemName);
      return frameCount % interval !== 0;
    }
    return false;
  }

  /**
   * Get current FPS
   */
  getFPS() {
    return Math.round(this.fps);
  }

  /**
   * Get average frame time
   */
  getAvgFrameTime() {
    return this.avgFrameTime;
  }

  /**
   * Get performance mode
   */
  getPerformanceMode() {
    return this.performanceMode;
  }

  /**
   * Reset performance tracking
   */
  reset() {
    this.frameTimes = [];
    this.fps = 60;
    this.avgFrameTime = 16.67;
    this.lastFrameTime = 0;
    this.performanceMode = 'normal';
  }
}





