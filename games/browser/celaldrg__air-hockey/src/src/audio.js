// Small synthesised sound effects with Web Audio. The audio context is only
// created from a user gesture (unlock), so browsers never block or warn.

const SOUNDS = {
  hit: { type: 'triangle', from: 520, to: 260, length: 0.08, volume: 0.35 },
  wall: { type: 'sine', from: 180, to: 120, length: 0.07, volume: 0.25 },
  post: { type: 'square', from: 900, to: 700, length: 0.09, volume: 0.12 },
};
const GOAL_NOTES = [523.25, 659.25, 783.99, 1046.5];
const MIN_GAP = 0.04;

/**
 * Creates the sound player.
 * @param {boolean} muted Initial mute state.
 */
export function createAudio(muted) {
  let ctx = null;
  let isMuted = muted;
  const lastPlayed = {};

  /** Plays one short tone with a pitch sweep and a fast decay. */
  function tone(spec, start, gain) {
    const osc = ctx.createOscillator();
    const amp = ctx.createGain();
    osc.type = spec.type;
    osc.frequency.setValueAtTime(spec.from, start);
    osc.frequency.exponentialRampToValueAtTime(spec.to, start + spec.length);
    amp.gain.setValueAtTime(spec.volume * gain, start);
    amp.gain.exponentialRampToValueAtTime(0.0001, start + spec.length);
    osc.connect(amp).connect(ctx.destination);
    osc.start(start);
    osc.stop(start + spec.length + 0.02);
  }

  return {
    /** Creates or resumes the audio context; call from a user gesture. */
    unlock() {
      const Ctx = globalThis.AudioContext || globalThis.webkitAudioContext;
      if (!ctx && Ctx) ctx = new Ctx();
      if (ctx && ctx.state === 'suspended') ctx.resume().catch(() => {});
    },
    /** @param {boolean} value */
    setMuted(value) {
      isMuted = value;
    },
    /** @returns {boolean} */
    get muted() {
      return isMuted;
    },
    /**
     * Plays a named effect: hit, wall, post or goal.
     * @param {string} name
     * @param {number} [strength] 0..1, louder for faster impacts.
     */
    play(name, strength = 1) {
      if (isMuted || !ctx || ctx.state !== 'running') return;
      const now = ctx.currentTime;
      if (now - (lastPlayed[name] ?? -1) < MIN_GAP) return;
      lastPlayed[name] = now;
      if (name === 'goal') {
        GOAL_NOTES.forEach((f, i) => tone({ type: 'triangle', from: f, to: f * 1.01, length: 0.18, volume: 0.25 }, now + i * 0.09, 1));
        return;
      }
      const spec = SOUNDS[name];
      if (spec) tone(spec, now, 0.3 + 0.7 * Math.min(1, Math.max(0, strength)));
    },
  };
}
