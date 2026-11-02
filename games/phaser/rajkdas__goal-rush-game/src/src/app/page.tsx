import GameCanvas from '@/components/game/GameCanvas';
import HowToPlay from '@/components/game/HowToPlay';
import Leaderboard from '@/components/game/Leaderboard';
import Paytable from '@/components/game/Paytable';
import { Badge } from '@/components/ui/badge';

/**
 * GOAL RUSH — Pinball × Slots (landing + game shell).
 *
 * Mobile-first: the 9:16 machine renders full-width on phones with the
 * rule/paytable/leaderboard panels stacked below; on ≥lg screens the table
 * sits beside a sidebar. The dark stadium theme is applied via the wrapper
 * background class.
 */

const STACK = ['Phaser 3.90', 'Matter.js', 'Next.js 16', 'TypeScript', 'Prisma', '60 FPS'];

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col bg-[#070b14] text-slate-100">
      <header className="border-b border-white/5 bg-[#070b14]/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center gap-x-5 gap-y-2 px-4 py-4">
          <h1 className="text-xl font-black tracking-tight sm:text-2xl">
            <span className="text-emerald-400">GOAL</span>{' '}
            <span className="text-amber-300">RUSH</span>
            <span className="ml-3 align-middle text-xs font-semibold uppercase tracking-[0.25em] text-slate-400">
              Pinball × Slots
            </span>
          </h1>
          <div className="ml-auto hidden flex-wrap gap-1.5 md:flex">
            {STACK.map((tech) => (
              <Badge
                key={tech}
                variant="outline"
                className="border-emerald-400/25 bg-emerald-400/5 text-[11px] font-medium text-emerald-200/80"
              >
                {tech}
              </Badge>
            ))}
          </div>
        </div>
      </header>

      <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-6">
        <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_360px]">
          <section aria-label="Game" className="min-w-0">
            <GameCanvas />
            <p className="mt-3 text-center text-xs leading-relaxed text-slate-400">
              A real physics pinball table wired into a slot machine: hit targets to spin reels,
              stack multipliers, chase the progressive jackpot.
            </p>
          </section>

          <aside aria-label="Game info" className="min-w-0 space-y-5">
            <HowToPlay />
            <Paytable />
            <Leaderboard />
          </aside>
        </div>
      </main>

      <footer className="mt-auto border-t border-white/5 bg-[#05080f]">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-2 px-4 py-4 text-xs text-slate-400">
          <span>
            Neon-arcade soccer machine · physics by Matter.js · reels decided up-front by weighted
            RNG
          </span>
          <span className="font-mono">Phaser 3 · Next.js 16 · TypeScript</span>
        </div>
      </footer>
    </div>
  );
}
