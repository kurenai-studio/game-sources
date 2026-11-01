import { useEffect, useState } from 'react';
import type { Mode } from 'src/types/game';
import { loadSettings, saveBest } from 'src/utils/storage';

/**
 * Tracks the persisted best score for one mode and reports whether the
 * current score set a new record. Records are persisted once per mount.
 *
 * @param mode - Game mode the score belongs to.
 * @param score - Rounds cleared in the finished run.
 * @returns The best score for the mode and whether `score` beat it.
 */
export function useBestScore(mode: Mode, score: number) {
  const [initialBest] = useState(() => loadSettings().best[mode]);
  const record = score > initialBest;

  useEffect(() => {
    if (record) {
      saveBest(mode, score);
    }
  }, [mode, record, score]);

  return { best: Math.max(initialBest, score), record };
}
