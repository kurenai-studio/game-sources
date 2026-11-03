// DOM interface: title/pause menu with tabs, garage, HUD, toasts and region titles.
// The game passes `model()` (everything the menu shows) and `onSet(key, value)` / `onAction(name)`.

const TABS = [
  { id: 'drive', name: 'Drive' },
  { id: 'garage', name: 'Garage' },
  { id: 'world', name: 'World' },
  { id: 'radio', name: 'Radio' },
  { id: 'settings', name: 'Settings' },
  { id: 'controls', name: 'Controls' },
];

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const chip = (key, value, label, on, extra = '') => `<button class="chip${on ? ' on' : ''}" data-set="${key}" data-value="${esc(value)}" ${extra}>${label}</button>`;
const bar = (label, v) => `<div class="stat"><span>${label}</span><i><b style="width:${Math.round(Math.min(1, Math.max(0.05, v)) * 100)}%"></b></i></div>`;

export class UI {
  constructor({ model, onSet, onAction }) {
    this.model = model;
    this.onSet = onSet;
    this.onAction = onAction;
    this.tab = 'drive';
    this.open = true;
    this.started = false;
    this.$ = (id) => document.getElementById(id);
    this.menu = this.$('menu');
    this.toastTimer = 0;
    this.regionTimer = 0;

    this.menu.addEventListener('click', (e) => {
      const t = e.target.closest('[data-set],[data-act],[data-tab]');
      if (!t) return;
      if (t.dataset.tab) { this.tab = t.dataset.tab; this.render(); this.onAction('tab', this.tab); return; }
      if (t.dataset.act) { this.onAction(t.dataset.act); return; }
      this.onSet(t.dataset.set, t.dataset.value);
      this.render();
    });
    this.menu.addEventListener('input', (e) => {
      if (e.target.dataset.vol) this.onSet(`volume.${e.target.dataset.vol}`, Number(e.target.value) / 100);
    });
    document.querySelectorAll('#quick [data-act], #radio [data-act]').forEach((b) => {
      b.addEventListener('click', () => this.onAction(b.dataset.act));
    });
  }

  show(tab) {
    if (tab) this.tab = tab;
    this.open = true;
    this.menu.classList.remove('hidden');
    this.render();
  }

  hide() {
    this.open = false;
    this.menu.classList.add('hidden');
  }

  render() {
    if (!this.open) return;
    const m = this.model();
    const nav = TABS.map((t) => `<button class="${t.id === this.tab ? 'on' : ''}" data-tab="${t.id}">${t.name}</button>`).join('');
    this.menu.classList.toggle('garage', this.tab === 'garage'); // dock left so the car stays in view
    const prev = this.menu.querySelector('.menu-body');
    const scroll = prev && prev.dataset.tab === this.tab ? prev.scrollTop : 0;
    this.menu.innerHTML = `
      <div class="menu-card">
        <aside class="menu-nav">
          <div class="logo">Beach Road<small>an endless coastal drive</small></div>
          ${nav}
          <button class="primary" data-act="resume">${this.started ? 'Resume' : 'Start driving'}</button>
        </aside>
        <section class="menu-body" data-tab="${this.tab}">${this[`tab_${this.tab}`](m)}</section>
      </div>`;
    this.menu.querySelector('.menu-body').scrollTop = scroll;
  }

  tab_drive(m) {
    const intro = this.started ? '' : `
      <p class="lead">A slow drive along an endless coast. Turn on autodrive, pick a station, and let the road unwind:
      palm beaches, clifftops, pine forests, harbour villages, dunes and windy meadows.</p>`;
    return `
      <h2>${this.started ? 'Paused' : 'Welcome'}</h2>${intro}
      <h3>Driving</h3>
      <div class="chips">${m.modes.map((d) => chip('mode', d.id, d.name, d.id === m.mode)).join('')}</div>
      <p class="note">Autodrive keeps its lane, follows and overtakes traffic. Cruise holds your speed while you steer.
      Set speed: <b>${m.setSpeed}</b> (use <kbd>+</kbd> <kbd>−</kbd>).</p>
      <h3>Camera</h3>
      <div class="chips">${m.cameras.map((c) => chip('camera', c.id, c.name, c.id === m.camera)).join('')}</div>
      <p class="note">Drag with the mouse to look around, scroll to zoom. Cinematic cuts between shots on its own.</p>
      <h3>Trip</h3>
      <div class="facts">
        <div><b>${m.stats.distance}</b><span>driven in total</span></div>
        <div><b>${m.stats.time}</b><span>time on the road</span></div>
        <div><b>${esc(m.region)}</b><span>current region</span></div>
      </div>
      <div class="chips"><button class="chip" data-act="turnAround">Turn around</button><button class="chip" data-act="screenshot">Save screenshot</button></div>`;
  }

  tab_garage(m) {
    const cards = m.cars.map((c) => `
      <button class="car${c.id === m.car ? ' on' : ''}" data-set="car" data-value="${c.id}">
        <div class="car-name">${esc(c.name)}</div>
        <div class="car-blurb">${esc(c.blurb)}</div>
        ${bar('Top speed', c.topSpeed / 250)}${bar('Acceleration', c.accel / 5.5)}${bar('Handling', c.handling)}
        <div class="car-meta">${Math.round(c.topSpeed)} km/h · ${esc(c.engine)}</div>
      </button>`).join('');
    const current = m.cars.find((c) => c.id === m.car);
    const paints = (current?.paints ?? []).map((p) => `<button class="swatch${p === m.paint ? ' on' : ''}" style="background:${p}" data-set="paint" data-value="${p}" title="${p}"></button>`).join('');
    return `
      <h2>Garage</h2>
      <p class="note">Pick a car and a colour. It swaps in right away; the camera circles it while this tab is open.</p>
      <div class="paints"><span>Paint</span>${paints}</div>
      <div class="cars">${cards}</div>`;
  }

  tab_world(m) {
    const looks = m.looks.map((l) => `
      <button class="look${l.id === m.look ? ' on' : ''}" data-set="look" data-value="${l.id}">
        <span class="sw" style="background:${l.swatch}"></span><b>${esc(l.name)}</b><small>${esc(l.tagline)}</small>
      </button>`).join('');
    const times = m.timeEnabled
      ? `<div class="chips">${chip('time', 'default', 'Look default', m.time === 'default')}${m.times.map((t) => chip('time', t.id, t.name, t.id === m.time)).join('')}${chip('time', 'cycle', 'Day cycle (30 min)', m.time === 'cycle')}</div>`
      : '<p class="note">This look is always night.</p>';
    return `
      <h2>World</h2>
      <h3>Look</h3><div class="looks">${looks}</div>
      <h3>Time of day <small>${esc(m.clock)}</small></h3>${times}
      <h3>Weather</h3>
      <div class="chips">${m.weathers.map((w) => chip('weather', w.id, w.name, w.id === m.weather)).join('')}${chip('weather', 'auto', 'Changing', m.weather === 'auto')}</div>
      <h3>Traffic</h3>
      <div class="chips">${m.densities.map((d) => chip('traffic', d, d[0].toUpperCase() + d.slice(1), d === m.traffic)).join('')}</div>
      <h3>Travel to a region</h3>
      <p class="note">Regions change every few kilometres on their own. Jump ahead to the next stretch of any of them:</p>
      <div class="chips">${m.regions.map((r) => `<button class="chip${r.id === m.regionId ? ' on' : ''}" data-act="travel:${r.id}">${esc(r.name)}</button>`).join('')}</div>`;
  }

  tab_radio(m) {
    const list = m.stations.map((s) => `
      <button class="station${s.id === m.station ? ' on' : ''}" data-set="station" data-value="${s.id}">
        <b>${esc(s.name)}</b><small>${esc(s.description ?? '')}</small>
      </button>`).join('');
    const vol = (k, label) => `<label class="slider"><span>${label}</span><input type="range" min="0" max="100" value="${Math.round(m.volume[k] * 100)}" data-vol="${k}"></label>`;
    return `
      <h2>Radio</h2>
      <p class="note">Every station is composed live and keeps changing key, tempo and arrangement, so it doesn't loop.
      Now playing: <b>${esc(m.nowPlaying)}</b></p>
      <div class="stations">${list}</div>
      <h3>Volume</h3>
      ${vol('master', 'Master')}${vol('music', 'Music')}${vol('sfx', 'Engine & ambience')}
      <div class="chips">${chip('muted', m.muted ? 'false' : 'true', m.muted ? 'Unmute' : 'Mute all', false)}</div>`;
  }

  tab_settings(m) {
    return `
      <h2>Settings</h2>
      <h3>Graphics quality <small>now: ${esc(m.qualityLevel)}</small></h3>
      <div class="chips">${['auto', 'high', 'medium', 'low'].map((q) => chip('quality', q, q[0].toUpperCase() + q.slice(1), q === m.quality)).join('')}</div>
      <p class="note">Auto starts high and steps down if the frame rate drops. Low turns off real shadows and glow for older machines.</p>
      <h3>Speed units</h3>
      <div class="chips">${chip('units', 'kmh', 'km/h', m.units === 'kmh')}${chip('units', 'mph', 'mph', m.units === 'mph')}</div>
      <h3>Display</h3>
      <div class="chips">${chip('hud', m.hud ? 'false' : 'true', m.hud ? 'Hide HUD' : 'Show HUD', false)}</div>
      <h3>Reset</h3>
      <div class="chips"><button class="chip" data-act="reset">Reset all settings</button></div>`;
  }

  tab_controls() {
    const row = (a, b) => `<tr><td>${a}</td><td>${b}</td></tr>`;
    return `
      <h2>Controls</h2>
      <div class="controls">
        <table><tr><th colspan="2">Keyboard &amp; mouse</th></tr>
          ${row('<kbd>W</kbd> <kbd>↑</kbd>', 'Accelerate')}${row('<kbd>S</kbd> <kbd>↓</kbd> <kbd>Space</kbd>', 'Brake / reverse')}
          ${row('<kbd>A</kbd> <kbd>D</kbd> <kbd>←</kbd> <kbd>→</kbd>', 'Steer')}${row('<kbd>E</kbd>', 'Autodrive on/off')}
          ${row('<kbd>C</kbd>', 'Cruise control on/off')}${row('<kbd>+</kbd> <kbd>−</kbd>', 'Set speed')}
          ${row('<kbd>V</kbd>', 'Change camera')}${row('Mouse drag / wheel', 'Look around / zoom')}
          ${row('<kbd>,</kbd> <kbd>.</kbd>', 'Previous / next station')}${row('<kbd>1</kbd> <kbd>2</kbd> <kbd>3</kbd>', 'Switch look')}
          ${row('<kbd>T</kbd> / <kbd>Y</kbd>', 'Next time of day / weather')}${row('<kbd>R</kbd>', 'Turn around')}
          ${row('<kbd>L</kbd>', 'Headlights')}${row('<kbd>G</kbd>', 'Horn')}
          ${row('<kbd>H</kbd>', 'Hide HUD')}${row('<kbd>M</kbd>', 'Mute')}
          ${row('<kbd>K</kbd>', 'Save screenshot')}${row('<kbd>Esc</kbd> <kbd>P</kbd>', 'Menu')}
        </table>
        <table><tr><th colspan="2">Gamepad</th></tr>
          ${row('Left stick', 'Steer')}${row('RT / LT', 'Accelerate / brake')}
          ${row('A', 'Autodrive')}${row('X', 'Cruise control')}${row('Y', 'Camera')}${row('B', 'Horn')}
          ${row('LB / RB', 'Station')}${row('D-pad ↑ ↓', 'Set speed')}${row('D-pad ← →', 'Time / weather')}
          ${row('Right stick', 'Look around')}${row('Start', 'Menu')}${row('Back', 'Hide HUD')}
        </table>
      </div>`;
  }

  // ------------------------------------------------------------ HUD

  hud(h) {
    const $ = this.$;
    $('speed').textContent = h.speed;
    $('unit').textContent = h.unit;
    $('gear').textContent = h.gear;
    const mode = $('mode');
    mode.textContent = h.modeText;
    mode.className = `badge ${h.mode}`;
    $('lightsIcon').classList.toggle('dim', !h.lights);
    $('clock').textContent = h.clock;
    $('weatherName').textContent = h.weather;
    $('odo').textContent = h.odo;
    $('stName').textContent = h.station;
    $('stMeta').textContent = h.meta;
    $('camName').textContent = h.camera;
    document.querySelector('#quick [data-act="autodrive"]').classList.toggle('on', h.mode === 'auto');
    document.querySelector('#quick [data-act="cruise"]').classList.toggle('on', h.mode === 'cruise');
  }

  setHudVisible(v) {
    this.$('hud').classList.toggle('hidden', !v);
  }

  toast(text) {
    const t = this.$('toast');
    t.textContent = text;
    t.classList.add('show');
    clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => t.classList.remove('show'), 2200);
  }

  region(name, sub) {
    const r = this.$('region');
    r.innerHTML = `<b>${esc(name)}</b><small>${esc(sub)}</small>`;
    r.classList.add('show');
    clearTimeout(this.regionTimer);
    this.regionTimer = setTimeout(() => r.classList.remove('show'), 5000);
  }

  hint(show) {
    this.$('hint').classList.toggle('show', show);
  }
}
