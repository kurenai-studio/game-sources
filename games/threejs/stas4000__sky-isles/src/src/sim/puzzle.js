// Chime sequence puzzle — pure logic, no three imports.
// Five wind chimes, each with a distinct color, symbol and pentatonic note.
// The murals on the home isle show the correct order; playing the full
// sequence opens the portal. A wrong note resets progress with a low tone.

export const CHIMES = [
  { id: 'moon', symbol: 'moon', color: '#a8e6cf', note: 523.25 }, // C5
  { id: 'star', symbol: 'star', color: '#cdb4f0', note: 587.33 }, // D5
  { id: 'sun', symbol: 'sun', color: '#fff3d6', note: 659.25 }, // E5
  { id: 'wave', symbol: 'wave', color: '#9fd8f0', note: 783.99 }, // G5
  { id: 'leaf', symbol: 'leaf', color: '#f2b8c6', note: 880.0 } // A5
];

// The mural order (indices into CHIMES): sun, leaf, moon, wave, star.
export const MURAL_ORDER = [2, 4, 0, 3, 1];

export class ChimePuzzle {
  constructor(order = MURAL_ORDER) {
    if (!Array.isArray(order) || order.length === 0) {
      throw new Error('ChimePuzzle needs a non-empty order array');
    }
    this.order = [...order];
    this.progress = 0;
    this.portalOpen = false;
    this.lastResult = null;
  }

  // Number of chimes correctly played in the current run == unlocked layers.
  get unlocked() {
    return this.progress;
  }

  // Play chime `index`. Returns a result object:
  //   { type: 'correct', index, progress, complete }
  //   { type: 'wrong',   index, progress: 0, complete: false }
  //   { type: 'replay',  index, progress, complete: true } (portal already open)
  play(index) {
    if (this.portalOpen) {
      this.lastResult = { type: 'replay', index, progress: this.progress, complete: true };
      return this.lastResult;
    }
    if (index === this.order[this.progress]) {
      this.progress += 1;
      const complete = this.progress >= this.order.length;
      if (complete) this.portalOpen = true;
      this.lastResult = { type: 'correct', index, progress: this.progress, complete };
    } else {
      this.progress = 0;
      this.lastResult = { type: 'wrong', index, progress: 0, complete: false };
    }
    return this.lastResult;
  }

  reset() {
    this.progress = 0;
    this.portalOpen = false;
    this.lastResult = null;
  }
}
