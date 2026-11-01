/**
 * Tiny Web Audio API sound synthesizer.
 *
 * Sounds are generated on the fly so no external assets are required.
 */

let audioContext: AudioContext | null = null;

/**
 * Multiplier applied to every sound's volume. Increase this to make all sounds louder.
 */
const MASTER_VOLUME = 5;

/**
 * Lazily creates and resumes the shared AudioContext.
 */
function getAudioContext(): AudioContext | null {
  audioContext ??= new AudioContext();
  if (audioContext.state === 'suspended') {
    audioContext.resume().catch(() => {
      // Ignore resume errors; audio will stay muted until user interaction.
    });
  }
  return audioContext;
}

/**
 * Plays a short tone with the given frequency envelope and duration.
 */
function playTone(
  startFrequency: number,
  endFrequency: number,
  duration: number,
  type: OscillatorType,
  volume = 0.1,
): void {
  const context = getAudioContext();
  if (!context) {
    return;
  }

  const oscillator = context.createOscillator();
  const gain = context.createGain();

  oscillator.type = type;
  oscillator.frequency.setValueAtTime(startFrequency, context.currentTime);
  oscillator.frequency.exponentialRampToValueAtTime(
    endFrequency,
    context.currentTime + duration,
  );

  gain.gain.setValueAtTime(volume * MASTER_VOLUME, context.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, context.currentTime + duration);

  oscillator.connect(gain);
  gain.connect(context.destination);

  oscillator.start(context.currentTime);
  oscillator.stop(context.currentTime + duration);
}

/**
 * Plays a pleasant rising chime for tile selection.
 */
export function playSelect(): void {
  playTone(880, 1100, 0.08, 'sine', 0.06);
}

/**
 * Plays a quick neutral pop when two tiles are swapped.
 */
export function playSwap(): void {
  playTone(600, 400, 0.1, 'triangle', 0.08);
}

/**
 * Plays a cheerful chord-like tone for matched tiles.
 */
export function playMatch(combo = 1): void {
  const base = 440 + Math.min(combo, 4) * 110;
  playTone(base, base * 1.5, 0.2, 'sine', 0.1);
}

/**
 * Plays a low buzz for an invalid swap.
 */
export function playInvalid(): void {
  playTone(200, 150, 0.15, 'sawtooth', 0.05);
}

/**
 * Plays a victory fanfare.
 */
export function playWin(): void {
  const context = getAudioContext();
  if (!context) {
    return;
  }
  for (let i = 0; i < 4; i += 1) {
    setTimeout(() => {
      playTone(
        440 * (1 + i * 0.25),
        440 * (1 + i * 0.25) * 1.2,
        0.15,
        'sine',
        0.08,
      );
    }, i * 80);
  }
}

/**
 * Plays a descending tone for game over.
 */
export function playLose(): void {
  playTone(300, 100, 0.4, 'sawtooth', 0.05);
}
