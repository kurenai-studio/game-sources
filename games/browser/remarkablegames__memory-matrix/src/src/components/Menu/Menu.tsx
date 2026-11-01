import { useState } from 'react';
import type { Mode } from 'src/types/game';
import { loadSettings } from 'src/utils/storage';

import { Button } from '../Button';

export interface MenuProps {
  onStart: (mode: Mode) => void;
}

const STEPS = [
  'Watch the tiles light up.',
  'Recreate the pattern from memory.',
  'Clear each round to climb higher.',
];

const MODES: { mode: Mode; title: string; blurb: string }[] = [
  { mode: 'classic', title: 'Classic', blurb: 'One mistake ends the run.' },
  { mode: 'timed', title: 'Timed', blurb: 'Beat the clock.' },
];

/**
 * Title screen: how to play, mode select, and per-mode best scores. Sound
 * lives in the app-level corner toggle.
 *
 * @param props - `onStart` receives the chosen mode.
 * @returns The rendered menu.
 */
export function Menu({ onStart }: MenuProps) {
  const [settings] = useState(loadSettings);

  return (
    <section className="flex w-full max-w-xl flex-col gap-8 px-6 text-center">
      <div>
        <h1 className="text-4xl font-bold text-slate-900 sm:text-5xl dark:text-slate-100">
          Memory Matrix
        </h1>
        <p className="mt-3 text-slate-600 dark:text-slate-400">
          Study the pattern. Then recreate it.
        </p>
      </div>

      <div className="rounded-xl bg-slate-100 p-4 text-left dark:bg-slate-800/60">
        <h2 className="text-sm font-semibold tracking-wider text-slate-500 uppercase dark:text-slate-400">
          How to play
        </h2>
        <ol className="mt-2 list-decimal space-y-1 pl-5 text-sm text-slate-700 dark:text-slate-300">
          {STEPS.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        {MODES.map(({ mode, title, blurb }) => (
          <Button
            key={mode}
            variant="mode"
            onClick={() => {
              onStart(mode);
            }}
          >
            <span className="block text-lg font-semibold text-slate-900 dark:text-slate-100">
              {title}
            </span>
            <span className="mt-1 block text-xs text-slate-500 dark:text-slate-400">
              {blurb}
            </span>
            <span className="mt-2 block text-sm font-medium text-sky-600 dark:text-sky-400">
              Best: {settings.best[mode]}
            </span>
          </Button>
        ))}
      </div>
    </section>
  );
}
