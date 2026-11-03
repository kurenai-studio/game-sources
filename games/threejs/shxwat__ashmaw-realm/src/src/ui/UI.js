/**
 * HUD wiring.
 *
 * Pure DOM ↔ bus translation: no system reaches into the interface and the
 * interface never reaches into a system's internals — it calls commands on the
 * app and listens for events. Keyboard and pointer share the same command set.
 */
import { bus, EV } from '../core/EventBus.js';
import { WEATHER_KEYS } from '../weather/WeatherSystem.js';

export class UI {
  constructor(app) {
    this.app = app;
    this.hud = document.getElementById('hud');
    this.flash = document.getElementById('flash');
    this.dragonStateEl = document.getElementById('dragonState');
    this.regionEl = document.getElementById('regionName');
    this.todEl = document.getElementById('tod');
    this.todReadout = document.getElementById('todReadout');

    this._wireChips();
    this._wireKeys();
    this._wireBus();
  }

  /* ── chips ────────────────────────────────────────────────────────── */

  _group(selector, attr, fn) {
    const root = document.querySelector(selector);
    if (!root) return;
    root.addEventListener('click', (e) => {
      const btn = e.target.closest(`[data-${attr}]`);
      if (!btn) return;
      for (const b of root.querySelectorAll(`[data-${attr}]`)) b.classList.remove('is-on');
      btn.classList.add('is-on');
      fn(btn.dataset[attr], btn);
    });
  }

  _wireChips() {
    const app = this.app;

    this._group('#camChips', 'cam', (mode) => app.setCameraMode(mode));
    this._group('#wxChips', 'wx', (key) => app.setWeather(key));

    // Actions (not a radio group).
    document.querySelectorAll('[data-act]').forEach((btn) => {
      btn.addEventListener('click', () => app.action(btn.dataset.act));
    });

    // The render-FX and quality-tier chips were removed from the HUD (see the
    // note in index.html). App.setFx / App.setQuality still exist and still
    // work from the console; there is simply no UI bound to them, so there is
    // nothing to wire here.

    // Time of day.
    // The raw 0..1 cycle puts midnight at *both* ends of the track, so the
    // slider's extremes were unusable. Map the travel onto dawn → dusk → deep
    // evening instead; night is still reachable via the Moonlight preset.
    this.todEl?.addEventListener('input', () => {
      const t = UI.sliderToTod(parseFloat(this.todEl.value));
      app.setTimeOfDay(t);
      this._writeClock(t);
    });

    document.getElementById('pauseBtn')?.addEventListener('click', () => app.togglePause());
  }

  /** slider 0..1 → time of day 0.22 (05:17) … 0.86 (20:40) */
  static sliderToTod(v) { return 0.22 + Math.min(1, Math.max(0, v)) * 0.64; }
  static todToSlider(t) { return Math.min(1, Math.max(0, (t - 0.22) / 0.64)); }

  _writeClock(t) {
    const mins = Math.round(t * 24 * 60);
    const h = String(Math.floor(mins / 60) % 24).padStart(2, '0');
    const m = String(mins % 60).padStart(2, '0');
    if (this.todReadout) this.todReadout.textContent = `${h}:${m}`;
  }

  /* ── keyboard ─────────────────────────────────────────────────────── */

  _wireKeys() {
    const app = this.app;
    const modes = ['cinematic', 'orbit', 'follow', 'free', 'walk'];

    window.addEventListener('keydown', (e) => {
      // Don't steal keys while the walk controller has the pointer.
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      // The HUD is built during boot, before "Enter the Realm" — without this,
      // a key pressed on the title screen ran its command against a world whose
      // frame loop hadn't started (Q played the whole Cataclysm unseen).
      if (!app.started) return;
      switch (e.code) {
        case 'Digit1': case 'Digit2': case 'Digit3': case 'Digit4': case 'Digit5': {
          const i = Number(e.code.slice(-1)) - 1;
          app.setCameraMode(modes[i]);
          this._syncChip('#camChips', 'cam', modes[i]);
          break;
        }
        case 'KeyC': app.setCameraMode('cinematic'); this._syncChip('#camChips', 'cam', 'cinematic'); break;
        case 'KeyF': app.action('fire'); break;
        case 'KeyL': app.action('land'); break;
        case 'KeyT': app.action('takeoff'); break;
        case 'KeyR': app.action('roar'); break;
        case 'KeyE': app.action('erupt'); break;
        case 'KeyQ': app.action('cataclysm'); break;
        case 'KeyB': app.action('lightning'); break;
        case 'KeyM': app.action('mute'); break;
        case 'KeyX': {
          const i = (WEATHER_KEYS.indexOf(app.weather.key) + 1) % WEATHER_KEYS.length;
          app.setWeather(WEATHER_KEYS[i]);
          this._syncChip('#wxChips', 'wx', WEATHER_KEYS[i]);
          break;
        }
        case 'KeyN': app.setWeather('night'); this._syncChip('#wxChips', 'wx', 'night'); break;
        case 'KeyH': this.hud.classList.toggle('is-hidden'); break;
        case 'KeyV': app.director.next(); break;
        case 'BracketLeft': app.nudgeTime(-0.02); break;
        case 'BracketRight': app.nudgeTime(0.02); break;
        case 'Space':
          if (app.rig.mode !== 'walk') { e.preventDefault(); app.togglePause(); }
          break;
      }
    });
  }

  _syncChip(root, attr, value) {
    const el = document.querySelector(root);
    if (!el) return;
    for (const b of el.querySelectorAll(`[data-${attr}]`)) {
      b.classList.toggle('is-on', b.dataset[attr] === value);
    }
  }

  /* ── bus ──────────────────────────────────────────────────────────── */

  _wireBus() {
    bus.on(EV.DRAGON_STATE, ({ state }) => {
      if (this.dragonStateEl) this.dragonStateEl.textContent = `State — ${state}`;
    });

    bus.on(EV.SHOT, ({ name }) => {
      if (this.regionEl) this.regionEl.textContent = name;
    });

    // EV.QUALITY no longer has anything to update — the tier readout and the
    // FX chips it used to sync are gone. PerfMonitor still emits it and still
    // scales the renderer; it just has no HUD to reflect into.

    bus.on(EV.TIME_OF_DAY, ({ t }) => {
      if (this.todEl && document.activeElement !== this.todEl) this.todEl.value = String(UI.todToSlider(t));
      this._writeClock(t);
    });

    bus.on(EV.PAUSE, ({ paused }) => {
      const b = document.getElementById('pauseBtn');
      if (b) b.textContent = paused ? '▶ Resume' : '⏸ Pause';
    });

    // Screen flash (eruption, lightning, fire ignition).
    bus.on(EV.FLASH, ({ intensity = 0.4, duration = 0.4, color = '#fff' }) => {
      if (!this.flash) return;
      this.flash.style.background = color;
      this.flash.style.transition = 'none';
      this.flash.style.opacity = String(intensity);
      requestAnimationFrame(() => {
        this.flash.style.transition = `opacity ${duration}s cubic-bezier(.2,0,.4,1)`;
        this.flash.style.opacity = '0';
      });
    });
  }
}
