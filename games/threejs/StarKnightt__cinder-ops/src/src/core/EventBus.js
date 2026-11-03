class EventBus {
  constructor() {
    this.listeners = new Map();
  }

  on(event, callback) {
    if (!this.listeners.has(event)) this.listeners.set(event, new Set());
    this.listeners.get(event).add(callback);
    return () => this.off(event, callback);
  }

  once(event, callback) {
    const wrapper = (...args) => {
      this.off(event, wrapper);
      callback(...args);
    };
    this.on(event, wrapper);
  }

  off(event, callback) {
    const cbs = this.listeners.get(event);
    if (cbs) {
      cbs.delete(callback);
      if (cbs.size === 0) this.listeners.delete(event);
    }
  }

  emit(event, data) {
    const cbs = this.listeners.get(event);
    if (cbs) cbs.forEach((cb) => {
      try { cb(data); } catch (e) { console.error(`EventBus error [${event}]:`, e); }
    });
  }

  clear(event) {
    event ? this.listeners.delete(event) : this.listeners.clear();
  }
}

export const eventBus = new EventBus();

export const Events = {
  GAME_START: 'game:start',
  GAME_OVER: 'game:over',
  GAME_WIN: 'game:win',
  GAME_RESTART: 'game:restart',
  PLAYER_HIT: 'player:hit',
  PLAYER_DIE: 'player:die',
  WEAPON_FIRE: 'weapon:fire',
  WEAPON_RELOAD: 'weapon:reload',
  WEAPON_EMPTY: 'weapon:empty',
  WEAPON_SWITCH: 'weapon:switch',
  PICKUP: 'pickup:taken',
  ENEMY_HIT: 'enemy:hit',
  ENEMY_DIE: 'enemy:die',
  EXTRACT_READY: 'extract:ready',
  AUDIO_PLAY: 'audio:play',
};
