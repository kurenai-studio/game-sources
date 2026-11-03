/**
 * Frame-time watchdog + HUD readout.
 *
 * Also does adaptive resolution: if we spend ~1.5s below the floor we shave
 * the render scale rather than let the whole thing chug. It creeps back up
 * when there's headroom, so a heavy moment (eruption) doesn't permanently
 * degrade the image.
 */
export class PerfMonitor {
  constructor(renderer, { floor = 42, ceiling = 58 } = {}) {
    this.renderer = renderer;
    this.floor = floor;
    this.ceiling = ceiling;

    this.fps = 60;
    this.scale = 1;
    this._acc = 0;
    this._frames = 0;
    this._badTime = 0;
    this._goodTime = 0;
    this.adaptive = true;
    this.onScale = null;

    this.dom = {
      fps: document.getElementById('fps'),
      calls: document.getElementById('drawcalls'),
      tris: document.getElementById('tris'),
    };
  }

  update(dt) {
    this._acc += dt;
    this._frames++;

    if (this._acc >= 0.5) {
      this.fps = this._frames / this._acc;
      this._acc = 0;
      this._frames = 0;

      const info = this.renderer.info.render;
      if (this.dom.fps)   this.dom.fps.textContent = Math.round(this.fps);
      if (this.dom.calls) this.dom.calls.textContent = info.calls;
      if (this.dom.tris)  this.dom.tris.textContent = formatCount(info.triangles);
    }

    if (!this.adaptive) return;

    if (this.fps < this.floor) { this._badTime += dt; this._goodTime = 0; }
    else if (this.fps > this.ceiling) { this._goodTime += dt; this._badTime = 0; }
    else { this._badTime = this._goodTime = 0; }

    if (this._badTime > 1.5 && this.scale > 0.62) {
      this._badTime = 0;
      this._setScale(this.scale - 0.1);
    } else if (this._goodTime > 4 && this.scale < 1) {
      this._goodTime = 0;
      this._setScale(Math.min(1, this.scale + 0.05));
    }
  }

  _setScale(s) {
    this.scale = s;
    this.onScale?.(s);
  }
}

const formatCount = (n) =>
  n >= 1e6 ? `${(n / 1e6).toFixed(1)}M` : n >= 1e3 ? `${(n / 1e3).toFixed(0)}k` : `${n}`;
