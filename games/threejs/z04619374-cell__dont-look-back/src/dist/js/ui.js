const $ = id => document.getElementById(id);
const REASONS = {
  forgotten: ['B is gone.','Contact lost.',''],
  turned: ['You looked back.','You faced B.',''],
  held: ['You looked back.','You held A too long.',''],
  hurt: ['The road ends.','No health remaining.',''],
  exit: ['Daybreak.','You made it together.','']
};

export class UI {
  constructor(model) {
    this.model = model; this.lastStatus = ''; this.damage = 0; this.noticeUntil = 0;
    this.notice = ''; this.settingsOpen = false; this.pointerError = false;
    this.reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
    $('reduced-motion').checked = this.reducedMotion;
    const needsDesktop = matchMedia('(pointer: coarse)').matches || innerWidth < 540;
    $('unsupported').hidden = !needsDesktop;
    this.compatibility = () => { $('unsupported').hidden = !(matchMedia('(pointer: coarse)').matches || innerWidth < 540); };
    window.addEventListener('resize', this.compatibility);
  }
  event(event) {
    if (event.type === 'hit') { this.damage = 1; this.notice = '−3'; }
    if (event.type === 'block') this.notice = 'Blocked';
    if (event.type === 'tap') this.notice = '';
    if (event.type === 'warning') this.notice = '';
    if (event.type === 'forced') this.notice = '';
    if (['hit','block','tap','warning','forced'].includes(event.type)) this.noticeUntil = this.model.time + 1.1;
  }
  showPointerError() {
    this.pointerError = true; this.lastStatus = '';
    this.update(0);
  }
  showSettings(open) {
    this.settingsOpen = open; $('settings-panel').hidden = !open;
    if (open) $('close-settings').focus();
    else $('settings').focus();
  }
  update(dt) {
    const model = this.model;
    this.damage = Math.max(0, this.damage - dt * 2.1);
    $('damage').style.opacity = (this.damage * (this.reducedMotion ? .4 : .65)).toFixed(3);
    $('health-fill').style.width = `${model.health}%`; $('health-value').textContent = model.health;
    $('contact-fill').style.width = `${model.contact*100}%`;
    $('contact-fill').style.background = model.contact < .35 ? 'var(--accent)' : '#a1aaa7';
    $('contact-value').textContent = `${Math.ceil(model.contact*100)}%`;
    const seconds = Math.floor(model.time);
    $('time-value').textContent = `${String(Math.floor(seconds/60)).padStart(2,'0')}:${String(seconds%60).padStart(2,'0')}`;
    $('hold-warning').hidden = !(model.holdPressure > .15 || model.forced);
    $('pressure-fill').style.width = `${model.forced ? 100 : model.holdPressure*100}%`;
    $('cue').textContent = model.forced ? '' : model.time < this.noticeUntil ? this.notice : model.guarding ? 'Guard' : '';
    $('b-cue').textContent = model.contact < .65 ? '' : '';
    $('b-cue').hidden = model.contact < .28;
    $('reticle').hidden = model.status !== 'playing';
    $('pause').disabled = model.status !== 'playing';
    if (this.lastStatus === model.status) return;
    this.lastStatus = model.status;
    $('overlay').hidden = model.status === 'playing';
    if (model.status === 'playing') return;
    const title = $('dialog-title'), copy = $('dialog-copy'), detail = $('dialog-detail'), button = $('start');
    $('result-label').hidden = !(model.status === 'lost' || model.status === 'won');
    $('dialog-note').textContent = this.pointerError ? 'Drag to look · Click to tap' : '';
    if (model.status === 'ready') {
      title.innerHTML = 'Don’t look back.'; copy.textContent = '';
      detail.innerHTML = '';
      button.innerHTML = 'Start <span aria-hidden="true">→</span>';
    } else if (model.status === 'paused') {
      title.textContent = 'Paused.'; copy.textContent = '';
      detail.textContent = this.pointerError ? 'Drag to look.' : '';
      button.innerHTML = 'Resume <span aria-hidden="true">→</span>';
    } else {
      const result = REASONS[model.reason];
      title.textContent = result[0]; copy.textContent = result[1]; detail.textContent = result[2];
      $('result-label').textContent = model.status === 'won' ? 'SURVIVED' : 'GAME OVER';
      $('dialog-note').textContent = `${model.time.toFixed(1)}s`;
      button.innerHTML = 'Retry <span aria-hidden="true">↗</span>';
    }
    button.focus({ preventScroll: true });
  }
  resetFeedback() { this.damage = 0; this.noticeUntil = 0; this.notice = ''; }
}
