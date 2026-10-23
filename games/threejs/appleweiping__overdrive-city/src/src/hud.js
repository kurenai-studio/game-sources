// DOM-based HUD. The browser's compositor renders text/blur/rounded corners
// for free, off the WebGL budget.
export class HUD {
  constructor() {
    this.el = {
      hud: document.getElementById('hud'),
      stars: document.getElementById('stars'),
      cash: document.getElementById('cash'),
      pending: document.getElementById('pending'),
      objective: document.getElementById('objective'),
      objTitle: document.querySelector('#objective .title'),
      objText: document.querySelector('#objective .text'),
      objBar: document.querySelector('#objective .bar>div'),
      hp: document.querySelector('#hpbar>div'),
      ap: document.querySelector('#apbar>div'),
      weapon: document.getElementById('weapon'),
      speed: document.getElementById('speed'),
      clock: document.getElementById('clock'),
      banner: document.getElementById('banner'),
      toasts: document.getElementById('toasts'),
      hint: document.getElementById('hint'),
    };
    // aim dot
    this.cross = document.createElement('div');
    this.cross.style.cssText = 'position:fixed;left:50%;top:50%;width:6px;height:6px;' +
      'margin:-3px 0 0 -3px;border-radius:50%;background:rgba(255,255,255,.85);' +
      'box-shadow:0 0 4px #000;display:none';
    this.el.hud.appendChild(this.cross);
    this._stars = -1;
    this._flash = false;
  }

  show() { this.el.hud.style.display = 'block'; }
  hide() { this.el.hud.style.display = 'none'; }

  setStars(n, flashing) {
    if (n === this._stars && flashing === this._flash) return;
    this._stars = n; this._flash = flashing;
    let html = '';
    for (let i = 0; i < 5; i++) html += `<span class="${i < n ? 'on' : 'off'}">★</span>`;
    this.el.stars.innerHTML = html;
    this.el.stars.classList.toggle('flash', !!flashing);
  }

  setCash(cash, pending) {
    this.el.cash.textContent = Math.floor(cash).toLocaleString('en-US');
    this.el.pending.textContent = pending > 0
      ? `+$${Math.floor(pending).toLocaleString('en-US')} when you lose the heat` : '';
  }

  setVitals(hp, maxHp, armor) {
    this.el.hp.style.width = Math.max(0, hp / maxHp * 100) + '%';
    this.el.ap.style.width = Math.max(0, armor) + '%';
  }

  setWeapon(name) {
    this.el.weapon.innerHTML = name ? `<b>${name}</b> &nbsp;·&nbsp; 1/2/3 or Q`
      : '<b>Driving</b> &nbsp;·&nbsp; Space drift · F exit';
    this.cross.style.display = name && name !== 'Fists' ? 'block' : 'none';
  }

  setSpeed(kmh) { this.el.speed.innerHTML = `<b>${Math.round(Math.abs(kmh))}</b> km/h`; }
  setClock(text) { this.el.clock.textContent = text; }

  objective(title, text, frac = null) {
    if (!title) { this.el.objective.style.display = 'none'; return; }
    this.el.objective.style.display = 'block';
    this.el.objTitle.textContent = title;
    this.el.objText.textContent = text;
    this.el.objBar.parentElement.style.display = frac === null ? 'none' : 'block';
    if (frac !== null) {
      this.el.objBar.style.width = Math.max(0, Math.min(1, frac)) * 100 + '%';
      this.el.objBar.style.background = frac < 0.25 ? 'var(--danger)' : 'var(--accent)';
    }
  }

  banner(kind, text, sub = '') {
    const b = this.el.banner;
    b.className = kind;
    b.innerHTML = text + (sub ? `<small>${sub}</small>` : '');
    b.style.display = 'block';
    clearTimeout(this._bannerT);
    this._bannerT = setTimeout(() => { b.style.display = 'none'; }, 3200);
  }

  toast(msg) {
    const t = document.createElement('div');
    t.className = 'toast';
    t.textContent = msg;
    this.el.toasts.appendChild(t);
    setTimeout(() => t.remove(), 4200);
    while (this.el.toasts.children.length > 4) this.el.toasts.firstChild.remove();
  }

  hint(msg) {
    this.el.hint.style.display = msg ? 'block' : 'none';
    if (msg) this.el.hint.textContent = msg;
  }

  hurtFlash() {
    document.body.style.boxShadow = 'inset 0 0 120px rgba(255,40,40,.5)';
    clearTimeout(this._hurtT);
    this._hurtT = setTimeout(() => { document.body.style.boxShadow = 'none'; }, 140);
  }
}
