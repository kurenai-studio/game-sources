import { START_TIME_MS, WARNING_MS } from 'src/utils/difficulty';

export interface HudProps {
  round: number;
  count: number | null;
  timeLeft: number | null;
}

const MAX_SECONDS = START_TIME_MS / 1_000;

/**
 * Round, target count, and (in Timed mode) the countdown clock.
 *
 * @param props - Current HUD values.
 * @returns The rendered heads-up display.
 */
export function Hud({ round, count, timeLeft }: HudProps) {
  const seconds = timeLeft === null ? null : Math.ceil(timeLeft / 1_000);
  const progressValue = seconds === null ? 0 : Math.min(MAX_SECONDS, seconds);
  const low = timeLeft !== null && timeLeft <= WARNING_MS;
  const barWidth =
    timeLeft === null ? 0 : Math.min(100, (timeLeft / START_TIME_MS) * 100);

  return (
    <header className="w-full max-w-xl px-4">
      <div className="grid grid-cols-3 items-center">
        <div className="justify-self-start text-center">
          <span className="block text-xs font-medium tracking-widest text-slate-500 uppercase dark:text-slate-400">
            Round
          </span>
          <span className="block text-2xl font-bold text-slate-900 dark:text-slate-100">
            {round}
          </span>
        </div>

        {/* Always occupy the middle column so the timer never shifts. */}
        <div role="status" className="justify-self-center text-center">
          {count !== null && (
            <>
              <span
                aria-hidden="true"
                className="block text-3xl font-bold text-sky-600 dark:text-sky-400"
              >
                {count}
              </span>
              <span className="sr-only">Recall {count} tiles</span>
            </>
          )}
        </div>

        {seconds !== null && (
          <div
            role="timer"
            className={`justify-self-end text-2xl font-bold tabular-nums ${low ? 'text-red-500' : 'text-slate-900 dark:text-slate-100'}`}
          >
            {seconds}s
          </div>
        )}
      </div>

      {timeLeft !== null && (
        <div
          role="progressbar"
          aria-label="Time left"
          aria-valuemin={0}
          aria-valuemax={MAX_SECONDS}
          aria-valuenow={progressValue}
          className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700"
        >
          <div
            className={`h-full rounded-full transition-[width] duration-100 ease-linear ${low ? 'bg-red-500' : 'bg-sky-500'}`}
            style={{ width: `${String(barWidth)}%` }}
          />
        </div>
      )}
    </header>
  );
}
