/** Procedural effects plus a bundled female shoulder-tap voice. */
export class Sound {
  constructor() {
    this.context = null; this.muted = false; this.volume = .35; this.nextStep = 0;
    this.voice = null; this.voiceSource = null; this.voiceGain = null;
    this.voiceData = fetch(new URL('../assets/hey.wav', import.meta.url))
      .then(response => { if (!response.ok) throw new Error('Voice unavailable'); return response.arrayBuffer(); })
      .catch(() => null);
  }
  async unlock() {
    try {
      if (!this.context) this.context = new (window.AudioContext || window.webkitAudioContext)();
      if (this.context.state === 'suspended') await this.context.resume();
      if (!this.voiceReady) this.voiceReady = this.voiceData.then(data => data ? this.context.decodeAudioData(data) : null)
        .then(buffer => { this.voice = buffer; }).catch(() => {});
    } catch { this.muted = true; }
  }
  stopVoice() {
    if (this.voiceSource) { this.voiceSource.stop(); this.voiceSource = null; }
  }
  sayHey() {
    if (!this.voice || !this.context || this.muted || this.volume <= 0 || this.context.state !== 'running') return;
    this.stopVoice();
    const source = this.context.createBufferSource(), gain = this.context.createGain();
    source.buffer = this.voice; gain.gain.value = this.volume;
    source.connect(gain); gain.connect(this.context.destination);
    this.voiceSource = source; this.voiceGain = gain;
    source.onended = () => { source.disconnect(); gain.disconnect(); if (this.voiceSource === source) { this.voiceSource = null; this.voiceGain = null; } };
    source.start();
  }
  tone(frequency, duration, type='sine', gain=.15, endFrequency=frequency) {
    if (!this.context || this.muted || this.context.state !== 'running') return;
    const context = this.context, now = context.currentTime;
    const oscillator = context.createOscillator(), envelope = context.createGain();
    oscillator.type = type; oscillator.frequency.setValueAtTime(frequency, now);
    oscillator.frequency.exponentialRampToValueAtTime(Math.max(1,endFrequency), now+duration);
    envelope.gain.setValueAtTime(0,now); envelope.gain.linearRampToValueAtTime(gain*this.volume,now+.008);
    envelope.gain.exponentialRampToValueAtTime(.0001,now+duration);
    oscillator.connect(envelope); envelope.connect(context.destination);
    oscillator.start(); oscillator.stop(now+duration+.02);
    oscillator.onended = () => { oscillator.disconnect(); envelope.disconnect(); };
  }
  play(type) {
    if (type==='tap') { this.tone(160,.12,'triangle',.3,65); this.sayHey(); }
    if (type==='hit') { this.tone(80,.32,'sawtooth',.2,25); this.tone(700,.13,'triangle',.07,160); }
    if (type==='guard' || type==='block') this.tone(type==='block'?480:320,.16,'triangle',.14,120);
    if (type==='approach') this.tone(55,.7,'sine',.1,48);
    if (type==='warning') this.tone(190,.3,'sawtooth',.08,260);
    if (type==='forced') this.tone(160,.8,'sine',.13,30);
    if (type==='end') this.tone(110,.7,'triangle',.15,32);
  }
  update(model) {
    if (model.status !== 'playing' || this.muted) this.stopVoice();
    if (this.voiceGain) this.voiceGain.gain.value = this.muted ? 0 : this.volume;
    if (model.status === 'playing' && model.time >= this.nextStep) {
      this.tone(60,.07,'triangle',.11,35); this.nextStep = model.time + .48;
    }
    if (model.time === 0) this.nextStep = 0;
  }
}
