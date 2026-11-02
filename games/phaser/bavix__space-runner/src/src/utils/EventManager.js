// Event Manager - Centralized event system for game events
export class EventManager {
  constructor() {
    this.listeners = new Map();
    this.onceListeners = new Map();
    this.eventQueue = [];
    this.processingQueue = false;
  }

  /**
   * Subscribe to an event
   */
  on(eventType, callback) {
    if (!this.listeners.has(eventType)) {
      this.listeners.set(eventType, []);
    }
    this.listeners.get(eventType).push(callback);
  }

  /**
   * Subscribe to an event once
   */
  once(eventType, callback) {
    if (!this.onceListeners.has(eventType)) {
      this.onceListeners.set(eventType, []);
    }
    this.onceListeners.get(eventType).push(callback);
  }

  /**
   * Unsubscribe from an event
   */
  off(eventType, callback) {
    if (this.listeners.has(eventType)) {
      const callbacks = this.listeners.get(eventType);
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
    
    if (this.onceListeners.has(eventType)) {
      const callbacks = this.onceListeners.get(eventType);
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }

  /**
   * Emit an event (synchronous)
   */
  emit(eventType, data = {}) {
    // Process regular listeners
    if (this.listeners.has(eventType)) {
      const callbacks = this.listeners.get(eventType);
      for (let i = 0; i < callbacks.length; i++) {
        try {
          callbacks[i](data);
        } catch (error) {
          console.warn(`EventManager: Error in listener for ${eventType}`, error);
        }
      }
    }

    // Process once listeners and remove them
    if (this.onceListeners.has(eventType)) {
      const callbacks = this.onceListeners.get(eventType);
      for (let i = 0; i < callbacks.length; i++) {
        try {
          callbacks[i](data);
        } catch (error) {
          console.warn(`EventManager: Error in once listener for ${eventType}`, error);
        }
      }
      this.onceListeners.delete(eventType);
    }
  }

  /**
   * Queue an event for later processing
   */
  queue(eventType, data = {}) {
    this.eventQueue.push({ eventType, data });
  }

  /**
   * Process queued events
   */
  processQueue() {
    if (this.processingQueue || this.eventQueue.length === 0) {
      return;
    }

    this.processingQueue = true;
    
    // Process up to 10 events per frame to avoid blocking
    const maxProcess = 10;
    let processed = 0;
    
    while (this.eventQueue.length > 0 && processed < maxProcess) {
      const event = this.eventQueue.shift();
      this.emit(event.eventType, event.data);
      processed++;
    }
    
    this.processingQueue = false;
  }

  /**
   * Clear all listeners
   */
  clear() {
    this.listeners.clear();
    this.onceListeners.clear();
    this.eventQueue = [];
  }

  /**
   * Remove all listeners for a specific event
   */
  removeAllListeners(eventType) {
    this.listeners.delete(eventType);
    this.onceListeners.delete(eventType);
  }
}

// Event types constants
export const GAME_EVENTS = {
  // Game state
  GAME_START: 'game:start',
  GAME_OVER: 'game:over',
  GAME_PAUSE: 'game:pause',
  GAME_RESUME: 'game:resume',
  GAME_RESET: 'game:reset',
  
  // Player
  PLAYER_MOVE: 'player:move',
  PLAYER_SHOOT: 'player:shoot',
  PLAYER_DAMAGE: 'player:damage',
  PLAYER_DEATH: 'player:death',
  
  // Obstacles
  OBSTACLE_SPAWN: 'obstacle:spawn',
  OBSTACLE_DESTROY: 'obstacle:destroy',
  
  // Boss
  BOSS_SPAWN: 'boss:spawn',
  BOSS_HIT: 'boss:hit',
  BOSS_DEFEAT: 'boss:defeat',
  
  // Powerups
  POWERUP_PICKUP: 'powerup:pickup',
  POWERUP_ACTIVATE: 'powerup:activate',
  POWERUP_DEACTIVATE: 'powerup:deactivate',
  
  // Energy
  ENERGY_PICKUP: 'energy:pickup',
  
  // Score
  SCORE_UPDATE: 'score:update',
  COMBO_UPDATE: 'combo:update',
  LEVEL_UP: 'level:up',
  
  // Multi-kill
  MULTI_KILL: 'multi:kill',
  
  // Particles
  PARTICLE_CREATE: 'particle:create',
  
  // Floating text
  FLOATING_TEXT_CREATE: 'floating:text:create'
};





