/** Minimal pub/sub. Systems talk through this instead of reaching into each other. */
export class EventBus {
  constructor() { this.map = new Map(); }

  on(type, fn) {
    if (!this.map.has(type)) this.map.set(type, new Set());
    this.map.get(type).add(fn);
    return () => this.off(type, fn);
  }
  off(type, fn) { this.map.get(type)?.delete(fn); }

  emit(type, payload) {
    const set = this.map.get(type);
    if (!set) return;
    for (const fn of set) {
      try { fn(payload); }
      catch (e) { console.error(`[bus:${type}]`, e); }
    }
  }
}

export const bus = new EventBus();

export const EV = {
  QUALITY:      'quality',       // { tier, settings }
  WEATHER:      'weather',       // { key, preset }
  TIME_OF_DAY:  'tod',           // { t }  0..1
  CAMERA_MODE:  'cameraMode',    // { mode }
  DRAGON_STATE: 'dragonState',   // { state }
  DRAGON_FIRE:  'dragonFire',    // { origin, dir, duration }
  ERUPTION:     'eruption',      // { stage }
  SHAKE:        'shake',         // { amplitude, duration, frequency }
  FLASH:        'flash',         // { intensity, duration, color }
  LIGHTNING:    'lightning',     // {}
  PAUSE:        'pause',         // { paused }
  SHOT:         'shot',          // { name }
  FX:           'fx',            // { key, enabled }
  IGNITE:       'ignite',        // { pos, radius, strength } — set the ground alight
  ROAR:         'roar',          // { origin }
  STRIKE:       'strike',        // { from, to, volcanic } — a lightning bolt landed
  CATACLYSM:    'cataclysm',     // { stage }
};
