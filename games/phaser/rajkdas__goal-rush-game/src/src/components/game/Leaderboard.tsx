'use client';

/**
 * GOAL RUSH — leaderboard (Next.js API + Prisma) and the game-over dialog.
 *
 * The Phaser game communicates over the CustomEvent bridge
 * ('goalrush:gameover' → this dialog; 'goalrush:restart' → back to the
 * game), keeping canvas and React fully decoupled.
 */

import { useCallback, useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/hooks/use-toast';

interface ScoreRow {
  id: number;
  initials: string;
  credits: number;
  spins: number;
  createdAt: string;
}

interface GameOverDetail {
  credits: number;
  spins: number;
  best: number;
}

export default function Leaderboard() {
  const [rows, setRows] = useState<ScoreRow[] | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detail, setDetail] = useState<GameOverDetail | null>(null);
  const [initials, setInitials] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const { toast } = useToast();

  const refresh = useCallback(async () => {
    try {
      const res = await fetch('/api/leaderboard', { cache: 'no-store' });
      if (!res.ok) throw new Error(`status ${res.status}`);
      const data = (await res.json()) as { scores: ScoreRow[] };
      setRows(data.scores);
    } catch {
      setRows([]);
    }
  }, []);

  useEffect(() => {
    void refresh();
    const onGameOver = (e: Event): void => {
      const d = (e as CustomEvent<GameOverDetail>).detail;
      setDetail(d);
      setInitials('');
      setSubmitted(false);
      setDialogOpen(true);
    };
    window.addEventListener('goalrush:gameover', onGameOver);
    return () => window.removeEventListener('goalrush:gameover', onGameOver);
  }, [refresh]);

  const submit = async (): Promise<void> => {
    if (!detail || submitting) return;
    const clean = initials.trim().toUpperCase();
    if (!/^[A-Z0-9]{2,3}$/.test(clean)) {
      toast({
        title: 'Initials needed',
        description: 'Enter 2-3 letters or digits (e.g. ZL, MVP).',
        variant: 'destructive',
      });
      return;
    }
    setSubmitting(true);
    try {
      const res = await fetch('/api/leaderboard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ initials: clean, credits: detail.credits, spins: detail.spins }),
      });
      if (!res.ok) throw new Error(`status ${res.status}`);
      await refresh();
      setSubmitted(true);
      toast({ title: 'Score saved!', description: `${clean} — ${detail.credits.toLocaleString()} credits` });
    } catch {
      toast({
        title: 'Could not save score',
        description: 'The leaderboard service did not respond. Try again.',
        variant: 'destructive',
      });
    } finally {
      setSubmitting(false);
    }
  };

  const playAgain = (): void => {
    setDialogOpen(false);
    window.dispatchEvent(new CustomEvent('goalrush:restart'));
    void refresh();
  };

  return (
    <>
      <Card className="border-white/10 bg-white/[0.03]">
        <CardHeader>
          <CardTitle className="text-base text-pink-400">Hall of Fame</CardTitle>
          <CardDescription>Top 10 credit runs.</CardDescription>
        </CardHeader>
        <CardContent>
          {rows === null ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-8 w-full bg-white/10" />
              ))}
            </div>
          ) : rows.length === 0 ? (
            <p className="py-4 text-center text-sm text-slate-400">
              No entries yet — finish a game to claim the top spot.
            </p>
          ) : (
            <ol className="space-y-1">
              {rows.map((row, i) => (
                <li
                  key={row.id}
                  className="flex items-center gap-3 rounded-md px-2 py-1.5 text-sm odd:bg-white/[0.04]"
                >
                  <span
                    className={`w-6 text-center font-mono ${
                      i === 0 ? 'text-amber-300' : i === 1 ? 'text-slate-300' : i === 2 ? 'text-orange-400' : 'text-slate-400'
                    }`}
                  >
                    {i + 1}
                  </span>
                  <span className="font-mono font-semibold tracking-widest text-foreground">
                    {row.initials}
                  </span>
                  <span className="ml-auto font-mono text-emerald-300">
                    {row.credits.toLocaleString()}
                  </span>
                  <span className="w-14 text-right text-xs text-slate-400">
                    {row.spins} spins
                  </span>
                </li>
              ))}
            </ol>
          )}
        </CardContent>
      </Card>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="border-white/10 bg-[#0d1526] sm:max-w-sm">
          <DialogHeader>
            <DialogTitle className="text-amber-300">Full Time!</DialogTitle>
            <DialogDescription>
              {detail
                ? `${detail.credits.toLocaleString()} credits · ${detail.spins} slot spin${detail.spins === 1 ? '' : 's'} · best ${detail.best.toLocaleString()}`
                : ''}
            </DialogDescription>
          </DialogHeader>
          {!submitted ? (
            <div className="space-y-2 py-1">
              <label htmlFor="initials" className="text-xs uppercase tracking-wide text-slate-400">
                Initials for the Hall of Fame
              </label>
              <Input
                id="initials"
                value={initials}
                onChange={(e) => setInitials(e.target.value.toUpperCase().slice(0, 3))}
                placeholder="MVP"
                className="font-mono uppercase tracking-widest"
                autoComplete="off"
                maxLength={3}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') void submit();
                }}
              />
            </div>
          ) : (
            <p className="py-1 text-sm text-emerald-300">Saved to the leaderboard. One more run?</p>
          )}
          <DialogFooter className="gap-2 sm:justify-between">
            {!submitted ? (
              <>
                <Button variant="ghost" onClick={playAgain} className="text-muted-foreground">
                  Skip & play again
                </Button>
                <Button onClick={() => void submit()} disabled={submitting} className="bg-emerald-500 text-black hover:bg-emerald-400">
                  {submitting ? 'Saving…' : 'Save score'}
                </Button>
              </>
            ) : (
              <Button onClick={playAgain} className="w-full bg-pink-500 text-white hover:bg-pink-400">
                Play again
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
