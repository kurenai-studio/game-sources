// Memory Manager - Optimized memory management and cleanup
export class MemoryManager {
  constructor() {
    this.cleanupQueue = [];
    this.cleanupInterval = 1000; // Cleanup every second
    this.lastCleanupTime = 0;
    this.maxQueueSize = 50;
  }

  /**
   * Schedule object for cleanup
   */
  scheduleCleanup(obj, cleanupFn) {
    if (this.cleanupQueue.length >= this.maxQueueSize) {
      // Process oldest item immediately
      const oldest = this.cleanupQueue.shift();
      if (oldest && oldest.cleanupFn) {
        oldest.cleanupFn(oldest.obj);
      }
    }
    
    this.cleanupQueue.push({ obj, cleanupFn, scheduledAt: Date.now() });
  }

  /**
   * Process cleanup queue
   */
  processCleanup(time) {
    if (time - this.lastCleanupTime < this.cleanupInterval) {
      return;
    }
    
    this.lastCleanupTime = time;
    
    // Process up to 10 items per cleanup cycle
    const maxProcess = 10;
    let processed = 0;
    
    while (this.cleanupQueue.length > 0 && processed < maxProcess) {
      const item = this.cleanupQueue.shift();
      if (item && item.cleanupFn && item.obj) {
        try {
          item.cleanupFn(item.obj);
        } catch (error) {
          console.warn('MemoryManager: Cleanup error', error);
        }
      }
      processed++;
    }
  }

  /**
   * Clear all scheduled cleanups
   */
  clear() {
    this.cleanupQueue = [];
    this.lastCleanupTime = 0;
  }

  /**
   * Force immediate cleanup of all items
   */
  forceCleanup() {
    while (this.cleanupQueue.length > 0) {
      const item = this.cleanupQueue.shift();
      if (item && item.cleanupFn && item.obj) {
        try {
          item.cleanupFn(item.obj);
        } catch (error) {
          console.warn('MemoryManager: Cleanup error', error);
        }
      }
    }
  }
}





