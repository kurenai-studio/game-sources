class Emitter {
    constructor() { this._ev = {}; }
    on(e, fn)  { (this._ev[e] = this._ev[e] || []).push(fn); return this; }
    off(e, fn) { if (this._ev[e]) this._ev[e] = this._ev[e].filter(f => f !== fn); }
    emit(e, ...a) { (this._ev[e] || []).slice().forEach(fn => fn(...a)); }
    once(e, fn) { const w = (...a) => { fn(...a); this.off(e, w); }; this.on(e, w); }
}

export default new Emitter();
