'use client';

/**
 * GOAL RUSH — cabinet shell around the Phaser canvas.
 *
 * The frame is styled as a slice of the physical machine: a neon marquee
 * (title + controls) above the glass, matching the in-canvas table below.
 * Loads the game bundle dynamically (client-only; Phaser touches window at
 * import time) and destroys it cleanly on unmount. The canvas itself is
 * fully responsive via Phaser's FIT scale mode.
 */

import { useEffect, useRef, useState } from 'react';
import type Phaser from 'phaser';
import { audio } from '@/game/audio/AudioKit';

export default function GameCanvas() {
  const hostRef = useRef<HTMLDivElement>(null);
  const frameRef = useRef<HTMLDivElement>(null);
  const [muted, setMuted] = useState(false);

  useEffect(() => {
    let game: Phaser.Game | null = null;
    let cancelled = false;

    void import('@/game').then(({ createGame }) => {
      if (!cancelled && hostRef.current) {
        game = createGame(hostRef.current);
      }
    });

    return () => {
      cancelled = true;
      game?.destroy(true);
      game = null;
    };
  }, []);

  const toggleFullscreen = (): void => {
    const el = frameRef.current;
    if (!el) return;
    if (document.fullscreenElement) {
      void document.exitFullscreen();
    } else {
      void el.requestFullscreen();
    }
  };

  return (
    <div
      ref={frameRef}
      className="relative mx-auto flex aspect-[9/16] w-[min(100%,calc(84svh*0.5625))] flex-col overflow-hidden rounded-2xl border border-emerald-400/25 bg-[#070b14] shadow-[0_0_70px_rgba(53,240,139,0.14)]"
    >
      {/* Marquee — the machine's header board. */}
      <div className="relative z-10 flex h-11 shrink-0 items-center gap-3 border-b border-emerald-400/20 bg-gradient-to-r from-[#0a1322] via-[#10203a] to-[#0a1322] px-3">
        <span
          aria-hidden
          className="h-2 w-2 shrink-0 animate-pulse rounded-full bg-emerald-400 shadow-[0_0_8px_rgba(53,240,139,0.9)]"
        />
        <p className="min-w-0 truncate text-sm font-black leading-none tracking-tight">
          <span className="text-emerald-400">GOAL</span>{' '}
          <span className="text-amber-300">RUSH</span>
          <span className="ml-2 hidden text-[10px] font-semibold uppercase tracking-[0.22em] text-slate-400 sm:inline">
            Stadium Slots
          </span>
        </p>
        <div className="ml-auto flex shrink-0 gap-1.5">
          <button
            type="button"
            onClick={() => setMuted(audio.toggleMute())}
            className="rounded-md border border-white/15 bg-black/40 px-2 py-1 text-xs text-white/70 backdrop-blur transition hover:border-emerald-400/40 hover:text-emerald-300"
            aria-label={muted ? 'Unmute sound' : 'Mute sound'}
          >
            {muted ? '🔇' : '🔊'}
          </button>
          <button
            type="button"
            onClick={toggleFullscreen}
            className="rounded-md border border-white/15 bg-black/40 px-2 py-1 text-xs text-white/70 backdrop-blur transition hover:border-emerald-400/40 hover:text-emerald-300"
            aria-label="Toggle fullscreen"
          >
            ⛶
          </button>
        </div>
      </div>

      {/* Playfield glass. */}
      <div className="relative min-h-0 flex-1">
        <div
          ref={hostRef}
          className="absolute inset-0"
          role="img"
          aria-label="GOAL RUSH pinball and slots game canvas"
        />
        <div className="pointer-events-none absolute inset-0 ring-1 ring-inset ring-white/5" />
      </div>
    </div>
  );
}
