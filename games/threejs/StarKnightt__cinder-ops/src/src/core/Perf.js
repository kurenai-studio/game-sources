/* Cheap frame-time attribution. Off unless a harness calls begin().
 * Marks are performance.now() deltas — no DOM, no allocations in the
 * hot path when disabled (the `on` check is a single boolean). */

const EMPTY = Object.create(null);

export const perf = {
  on: false,
  acc: EMPTY,
  frames: null,
  _t: 0,
  _name: '',

  begin() {
    this.on = true;
    this.frames = [];
    this.acc = Object.create(null);
  },

  stop() {
    this.on = false;
    const out = this.frames || [];
    this.frames = null;
    this.acc = EMPTY;
    return out;
  },

  mark(name) {
    if (!this.on) return;
    this._name = name;
    this._t = performance.now();
  },

  done(name) {
    if (!this.on) return;
    const key = name || this._name;
    this.acc[key] = (this.acc[key] || 0) + (performance.now() - this._t);
  },

  commit(ft) {
    if (!this.on) return;
    this.acc.ft = ft;
    this.frames.push(this.acc);
    this.acc = Object.create(null);
  },
};
