/* Cinder Ops shell: loader, start/pause menu, settings, KIA/extract. */

const STAT_ROWS = [
  { key: 'kills', label: 'Kills' },
  { key: 'headshots', label: 'Headshots' },
  { key: 'accuracy', label: 'Accuracy' },
  { key: 'damageTaken', label: 'Damage taken' },
  { key: 'raidTime', label: 'Raid time' },
];

function fmtTime(ms) {
  const s = Math.max(0, Math.round(ms / 1000));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

function prefersReduce() {
  try { return matchMedia('(prefers-reduced-motion: reduce)').matches; }
  catch { return false; }
}

export class Shell {
  constructor(root = document.getElementById('shell')) {
    this.root = root;
    this.loader = root?.querySelector('#loader');
    this.menu = root?.querySelector('#menu');
    this.over = root?.querySelector('#over');
    this.flash = root?.querySelector('#over-flash');
    this.bar = root?.querySelector('#load-bar');
    this.stage = root?.querySelector('#load-stage');
    this.playBtn = root?.querySelector('#menu-play');
    this.panel = null;
    this.resume = false;
    this._fpsTimer = 0;
    this._countGen = 0;
    this._handlers = { play: null, resume: null, restart: null };
    this._settings = null;
    if (!root) return;
    this._bind();
  }

  _bind() {
    this.root.querySelector('#menu-play')?.addEventListener('click', () => {
      this.resume ? this._handlers.resume?.() : this._handlers.play?.();
    });
    this.root.querySelector('#menu-controls')?.addEventListener('click', () => this._open('controls'));
    this.root.querySelector('#menu-settings')?.addEventListener('click', () => this._open('settings'));
    this.root.querySelectorAll('[data-back]').forEach((b) => {
      b.addEventListener('click', () => this._open(null));
    });
    this.over?.querySelector('button')?.addEventListener('click', () => this._handlers.restart?.());

    const sens = this.root.querySelector('#set-sens');
    const vol = this.root.querySelector('#set-vol');
    sens?.addEventListener('input', () => {
      const v = +sens.value;
      this._settings?.setSens(v);
      this._paintSettings();
    });
    vol?.addEventListener('input', () => {
      const v = +vol.value;
      this._settings?.setVol(v);
      this._paintSettings();
    });
    this.root.querySelectorAll('[data-fps]').forEach((b) => {
      b.addEventListener('click', () => {
        this._settings?.setFpsCap(+b.dataset.fps);
        this._paintSettings();
      });
    });
    this.root.querySelectorAll('[data-quality]').forEach((b) => {
      b.addEventListener('click', () => {
        this._settings?.setQuality(b.dataset.quality);
        this._paintSettings();
      });
    });
  }

  on(name, fn) { this._handlers[name] = fn; }

  bindSettings(api) {
    this._settings = api;
    this._paintSettings();
  }

  setProgress(pct, label) {
    const p = Math.max(0, Math.min(1, pct));
    if (this.bar) this.bar.style.transform = `scaleX(${p})`;
    if (this.stage) this.stage.textContent = label || '';
    this.root?.setAttribute('aria-busy', p < 1 ? 'true' : 'false');
  }

  showMenu({ resume = false } = {}) {
    this.resume = !!resume;
    if (this.playBtn) this.playBtn.textContent = resume ? 'Resume' : 'Play';
    this._open(null);
    this._mode('menu');
    if (this.loader) this.loader.hidden = true;
    if (this.menu) this.menu.hidden = false;
    this._resetOver();
    this.playBtn?.focus({ preventScroll: true });
  }

  showOver(title, body, kind = 'kia', stats = null) {
    this._stopFps();
    if (this.over) {
      this.over.hidden = false;
      this.over.dataset.kind = kind;
      const k = this.over.querySelector('.shell-kicker');
      const h = this.over.querySelector('h2');
      const p = this.over.querySelector('.over-lede');
      const btn = this.over.querySelector('button');
      if (k) k.textContent = kind === 'extract' ? 'Block secure' : 'Raid over';
      if (h) h.textContent = title;
      if (p) p.textContent = body;
      if (btn) btn.textContent = kind === 'extract' ? 'Play again' : 'Restart';
      this._paintRaidStats(stats || {});
      this._playOverSeq(kind);
    }
    if (this.menu) this.menu.hidden = true;
    if (this.loader) this.loader.hidden = true;
    this._mode('over');
  }

  hide() {
    this._stopFps();
    this._mode('play');
    if (this.menu) this.menu.hidden = true;
    if (this.loader) this.loader.hidden = true;
    this._resetOver();
  }

  _resetOver() {
    this._countGen++;
    if (this.over) {
      this.over.hidden = true;
      this.over.classList.remove('is-seq');
    }
    if (this.flash) {
      this.flash.hidden = true;
      this.flash.classList.remove('is-run');
    }
  }

  _playOverSeq(kind) {
    const reduce = prefersReduce();
    if (this.flash) {
      this.flash.classList.remove('is-run');
      if (kind === 'extract' && !reduce) {
        this.flash.hidden = false;
        void this.flash.offsetWidth;
        this.flash.classList.add('is-run');
        this.flash.addEventListener('animationend', () => {
          this.flash.classList.remove('is-run');
          this.flash.hidden = true;
        }, { once: true });
      } else {
        this.flash.hidden = true;
      }
    }
    if (!this.over) return;
    this.over.classList.remove('is-seq');
    if (reduce) return;
    void this.over.offsetWidth;
    this.over.classList.add('is-seq');
  }

  _paintRaidStats(stats) {
    const box = this.over?.querySelector('.over-stats');
    if (!box) return;
    const kills = stats.kills | 0;
    const heads = stats.headshots | 0;
    const hit = stats.shotsHit | 0;
    const fired = stats.shotsFired | 0;
    const acc = fired > 0 ? stats.accuracy ?? (hit / fired) : 0;
    const dmg = stats.damageTaken | 0;
    const ms = stats.raidMs | 0;
    const values = {
      kills,
      headshots: heads,
      accuracy: Math.round(acc * 100),
      damageTaken: dmg,
      raidTime: ms,
    };
    const fmt = {
      kills: (v) => String(Math.round(v)),
      headshots: (v) => String(Math.round(v)),
      accuracy: (v) => `${Math.round(v)}%`,
      damageTaken: (v) => String(Math.round(v)),
      raidTime: (v) => fmtTime(v),
    };
    const sub = box.querySelector('[data-acc-sub]');
    if (sub) sub.textContent = `${hit} / ${fired}`;
    const reduce = prefersReduce();
    const gen = ++this._countGen;
    STAT_ROWS.forEach((row, i) => {
      const el = box.querySelector(`[data-count="${row.key}"]`);
      if (!el) return;
      const to = values[row.key];
      if (reduce) {
        el.textContent = fmt[row.key](to);
        return;
      }
      el.textContent = fmt[row.key](0);
      const delay = 420 + i * 80;
      setTimeout(() => {
        if (this._countGen !== gen) return;
        this._countUp(el, to, 600, fmt[row.key], gen);
      }, delay);
    });
  }

  _countUp(el, to, dur, format, gen) {
    const t0 = performance.now();
    const step = (now) => {
      if (this._countGen !== gen) return;
      const t = Math.min(1, (now - t0) / dur);
      const e = 1 - (1 - t) ** 3;
      el.textContent = format(to * e);
      if (t < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }

  dismiss() { this.hide(); }

  handleEscape() {
    if (!this.root || this.root.classList.contains('is-play')) return false;
    if (this.over && !this.over.hidden) return true;
    if (this.panel) {
      this._open(null);
      return true;
    }
    if (this.resume) {
      this._handlers.resume?.();
      return true;
    }
    return false;
  }

  _mode(name) {
    if (!this.root) return;
    this.root.classList.remove('is-loading', 'is-menu', 'is-play', 'is-over');
    this.root.classList.add(`is-${name}`);
    this.root.hidden = name === 'play';
  }

  _open(name) {
    this.panel = name;
    this.root?.querySelectorAll('[data-panel]').forEach((el) => {
      el.hidden = el.dataset.panel !== (name || 'nav');
    });
    if (name === 'settings') {
      this._paintSettings();
      this._startFps();
    } else {
      this._stopFps();
    }
  }

  _paintSettings() {
    if (!this._settings || !this.root) return;
    const sens = this._settings.getSens();
    const vol = this._settings.getVol();
    const cap = this._settings.getFpsCap();
    const sensEl = this.root.querySelector('#set-sens');
    const volEl = this.root.querySelector('#set-vol');
    const sensVal = this.root.querySelector('#set-sens-val');
    const volVal = this.root.querySelector('#set-vol-val');
    if (sensEl) sensEl.value = String(sens);
    if (volEl) volEl.value = String(vol);
    if (sensVal) sensVal.textContent = `${Number(sens).toFixed(2)}×`;
    if (volVal) volVal.textContent = `${Math.round(Number(vol) * 100)}%`;
    this.root.querySelectorAll('[data-fps]').forEach((b) => {
      const on = +b.dataset.fps === cap;
      b.classList.toggle('on', on);
      b.setAttribute('aria-checked', on ? 'true' : 'false');
    });
    const quality = this._settings.getQuality?.() ?? 'cinematic';
    this.root.querySelectorAll('[data-quality]').forEach((b) => {
      const on = b.dataset.quality === quality;
      b.classList.toggle('on', on);
      b.setAttribute('aria-checked', on ? 'true' : 'false');
    });
    this._paintFps();
  }

  _paintFps() {
    const el = this.root?.querySelector('#set-fps-live');
    if (!el || !this._settings) return;
    const n = this._settings.getFps();
    el.textContent = n > 1 ? `${n.toFixed(0)} fps` : '— fps';
  }

  _startFps() {
    this._stopFps();
    const tick = () => {
      this._paintFps();
      this._fpsTimer = requestAnimationFrame(tick);
    };
    this._fpsTimer = requestAnimationFrame(tick);
  }

  _stopFps() {
    if (this._fpsTimer) cancelAnimationFrame(this._fpsTimer);
    this._fpsTimer = 0;
  }
}
