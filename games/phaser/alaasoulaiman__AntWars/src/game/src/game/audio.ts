// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Tiny WebAudio blips, no sound files. Silent until the browser has unlocked audio with a touch, and silent while muted.
// The mute switch is remembered on the phone (mute.ts).
import * as Phaser from 'phaser';
import { browserStore } from '../sim/best';
import { readMute, writeMute } from './mute';

type BlipKind = 'kill' | 'pickup' | 'hurt' | 'buy' | 'round' | 'denied' | 'level';

interface BlipSpec {
  type: OscillatorType;
  from: number;
  to: number;
  seconds: number;
  volume: number;
  /** A second note this long after the first (the round chime), or none. */
  echoAfter?: number;
  echoFrom?: number;
  echoTo?: number;
}

const BLIPS: Readonly<Record<BlipKind, BlipSpec>> = {
  kill: { type: 'square', from: 520, to: 260, seconds: 0.06, volume: 0.035 },
  pickup: { type: 'sine', from: 880, to: 1320, seconds: 0.06, volume: 0.05 },
  hurt: { type: 'sawtooth', from: 180, to: 90, seconds: 0.14, volume: 0.06 },
  buy: { type: 'triangle', from: 660, to: 1320, seconds: 0.18, volume: 0.07 },
  // The round banner's chime: two rising notes.
  round: { type: 'triangle', from: 440, to: 660, seconds: 0.16, volume: 0.07, echoAfter: 0.13, echoFrom: 660, echoTo: 990 },
  denied: { type: 'square', from: 140, to: 120, seconds: 0.09, volume: 0.04 },
  level: { type: 'triangle', from: 520, to: 1560, seconds: 0.3, volume: 0.07 },
};

let ctx: AudioContext | null = null;
let muted = readMute(browserStore());
let unlockInstalled = false;
const lastAt: Partial<Record<BlipKind, number>> = {};

/** Borrows Phaser's audio context (Phaser unlocks it on a touch too) and makes sure the first touch wakes it up. */
export function attachAudio(manager: Phaser.Sound.BaseSoundManager): void {
  ctx = manager instanceof Phaser.Sound.WebAudioSoundManager ? manager.context : null;
  installUnlock();
}

/**
 * iPhone Safari starts audio only inside a touch: the first touch, click or key resumes the context and plays one
 * silent sample, inside that very event. The listeners go once audio runs.
 */
function installUnlock(): void {
  if (unlockInstalled || typeof document === 'undefined') return;
  unlockInstalled = true;
  const events = ['touchend', 'pointerdown', 'mousedown', 'keydown'];
  const unlock = () => {
    try {
      if (!ctx) return;
      if (ctx.state !== 'running') void ctx.resume();
      const buffer = ctx.createBuffer(1, 1, 22050);
      const src = ctx.createBufferSource();
      src.buffer = buffer;
      src.connect(ctx.destination);
      src.start(0);
      if (ctx.state === 'running') for (const e of events) document.removeEventListener(e, unlock, true);
    } catch {
      // A refused unlock leaves the game silent, never stopped.
    }
  };
  for (const e of events) document.addEventListener(e, unlock, true);
}

export function isMuted(): boolean {
  return muted;
}

/** Flips the mute switch and remembers it; returns the new state. */
export function toggleMute(): boolean {
  muted = !muted;
  writeMute(browserStore(), muted);
  return muted;
}

function tone(c: AudioContext, type: OscillatorType, from: number, to: number, seconds: number, volume: number, at: number): void {
  const osc = c.createOscillator();
  const gain = c.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(from, at);
  osc.frequency.exponentialRampToValueAtTime(to, at + seconds);
  gain.gain.setValueAtTime(volume, at);
  gain.gain.exponentialRampToValueAtTime(0.0001, at + seconds);
  osc.connect(gain);
  gain.connect(c.destination);
  osc.start(at);
  osc.stop(at + seconds + 0.02);
}

export function blip(kind: BlipKind): void {
  try {
    if (muted || !ctx || ctx.state !== 'running') return;
    const now = ctx.currentTime;
    const last = lastAt[kind];
    if (last !== undefined && now - last < 0.035) return;
    lastAt[kind] = now;
    const spec = BLIPS[kind];
    tone(ctx, spec.type, spec.from, spec.to, spec.seconds, spec.volume, now);
    if (spec.echoAfter !== undefined && spec.echoFrom !== undefined && spec.echoTo !== undefined) {
      tone(ctx, spec.type, spec.echoFrom, spec.echoTo, spec.seconds, spec.volume, now + spec.echoAfter);
    }
  } catch {
    // Audio is a nicety; a refused node never stops the game.
  }
}
