'use client';

/**
 * GOAL RUSH — how-to-play card (controls + table rules).
 */

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

const CONTROLS: Array<{ action: string; keys: string; touch: string }> = [
  { action: 'Left flipper', keys: 'Z / A / ←', touch: 'Tap ◀ button / left half' },
  { action: 'Right flipper', keys: 'M / L / →', touch: 'Tap ▶ button / right half' },
  { action: 'Launch (hold to charge)', keys: 'SPACE / ↓', touch: 'Hold the LAUNCH pill / lane' },
  { action: 'Nudge', keys: 'N / ↑', touch: 'Quick swipe' },
  { action: 'Gamepad', keys: 'LB / RB · A · X', touch: '—' },
];

const RULES: string[] = [
  '3 balls per game (extra balls at 2,500 / 6,000 / 12,000 credits). The goal mouth is the drain — a 9-second ball save forgives early drains.',
  'Full-power launches loop the dome, tear through the spinner lane and land on the left flipper — 5 spinner passes per ball earn a FREE SPIN.',
  'Spell G·O·A·L in the top rollover lanes to raise the multiplier (up to ×5) — it boosts EVERY award: bumpers, targets, slots, all of it.',
  'Shoot the SPIN saucer on the right orbit for a base spin; ANY PAIR on the payline already pays, triples pay big.',
  'Clear all four Golden Bank drop targets for a GOLDEN SPIN — trophy odds ×23 (jackpot ≈ 1 in 13).',
  'Hit all three pop bumpers within 3.5 s for a HAT-TRICK bonus. Every table event feeds the progressive pot — three trophies pay it all.',
];

export default function HowToPlay() {
  return (
    <Card className="border-white/10 bg-white/[0.03]">
      <CardHeader>
        <CardTitle className="text-base text-emerald-300">How to Play</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <table className="w-full table-fixed text-sm">
          <thead>
            <tr className="border-b border-white/10 text-left text-[11px] uppercase tracking-wide text-slate-400">
              <th className="pb-2">Action</th>
              <th className="pb-2">Keys</th>
              <th className="pb-2">Touch</th>
            </tr>
          </thead>
          <tbody>
            {CONTROLS.map((row) => (
              <tr key={row.action} className="border-b border-white/5 last:border-0">
                <td className="py-2 pr-2 align-top leading-snug text-slate-100">{row.action}</td>
                <td className="whitespace-nowrap py-2 pr-2 align-top font-mono text-xs text-amber-200">
                  {row.keys}
                </td>
                <td className="py-2 align-top text-xs leading-snug text-slate-400">{row.touch}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <ul className="space-y-2">
          {RULES.map((rule) => (
            <li key={rule} className="flex gap-2 text-xs leading-relaxed text-slate-300">
              <span className="mt-0.5 text-emerald-400" aria-hidden>
                ●
              </span>
              {rule}
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}
