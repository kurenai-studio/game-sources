import { grainDataURL } from '../world/Textures.js';

export class HUD {
  constructor() {
    this.el = {
      hud: document.getElementById('hud'),
      objective: document.getElementById('objective'),
      keys: document.getElementById('keys'),
      prompt: document.getElementById('prompt'),
      toast: document.getElementById('toast'),
      flash: document.getElementById('flash'),
      vignette: document.getElementById('vignette'),
      grain: document.getElementById('grain'),
      noteOverlay: document.getElementById('note-overlay'),
      noteText: document.getElementById('note-text'),
      scareFace: document.getElementById('scare-face'),
      batteryFill: document.getElementById('battery-fill'),
      battery: document.getElementById('battery'),
      burn: document.getElementById('burn'),
      burnFill: document.getElementById('burn-fill'),
    };
    this.el.grain.style.backgroundImage = `url(${grainDataURL()})`;
    this._grainPhase = 0;
    this._animateGrain();
    this.toastTimer = null;
  }

  _animateGrain() {
    // shuffle the noise tile every other frame — analog film feel
    setInterval(() => {
      this._grainPhase = (this._grainPhase + 1) % 4;
      const x = (this._grainPhase * 53) % 160;
      const y = (this._grainPhase * 97) % 160;
      this.el.grain.style.backgroundPosition = `${x}px ${y}px`;
    }, 90);
  }

  show() { this.el.hud.classList.remove('hidden'); }
  hide() { this.el.hud.classList.add('hidden'); }

  setObjective(text) { this.el.objective.textContent = text; }

  setKeys(count, total = 3) {
    this.el.keys.textContent = '⚿ '.repeat(count) + '· '.repeat(total - count);
  }

  setBattery(pct) {
    this.el.batteryFill.style.width = `${Math.max(0, pct)}%`;
    this.el.batteryFill.style.background = pct < 20 ? '#7e1212' : pct < 45 ? '#7a6a3f' : '#5d7a4f';
    this.el.battery.classList.toggle('dying', pct < 20);
  }

  setBurn(meter) {
    if (meter > 0.02) {
      this.el.burn.classList.remove('hidden');
      this.el.burnFill.style.width = `${Math.min(100, meter * 100)}%`;
    } else {
      this.el.burn.classList.add('hidden');
    }
  }

  setPrompt(text) {
    if (!text) { this.el.prompt.classList.add('hidden'); return; }
    this.el.prompt.classList.remove('hidden');
    this.el.prompt.innerHTML = `<kbd>E</kbd>${text}`;
  }

  toast(text, ms = 2600) {
    this.el.toast.textContent = text;
    this.el.toast.style.opacity = 1;
    clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => { this.el.toast.style.opacity = 0; }, ms);
  }

  flash(color = '#fff', peak = 0.55, ms = 130) {
    const f = this.el.flash;
    f.style.background = color;
    f.style.opacity = peak;
    setTimeout(() => { f.style.opacity = 0; }, ms);
  }

  shake() {
    document.body.classList.remove('shake');
    void document.body.offsetWidth; // restart the CSS animation
    document.body.classList.add('shake');
  }

  setDanger(on) { this.el.vignette.classList.toggle('danger', on); }

  showNote(text) {
    this.el.noteText.innerHTML = text.replace(/\n/g, '<br/>');
    this.el.noteOverlay.classList.remove('hidden');
  }

  hideNote() { this.el.noteOverlay.classList.add('hidden'); }
  get noteOpen() { return !this.el.noteOverlay.classList.contains('hidden'); }

  jumpscare(faceURL) {
    this.el.scareFace.querySelector('img').src = faceURL;
    this.el.scareFace.classList.remove('hidden');
  }

  hideJumpscare() { this.el.scareFace.classList.add('hidden'); }
}
