'use client';

/**
 * GOAL RUSH — paytable card.
 *
 * Mirrors the PAR sheet in src/game/config/slots.config.ts (single source of
 * truth — this component only renders it). Icons are inline SVGs matching
 * the in-canvas reel art.
 */

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  NOMINAL_SPIN_COST,
  SYMBOLS,
  SYMBOL_ORDER,
  TROPHY_GOLDEN_MULTIPLIER,
  type SymbolId,
} from '@/game/config/slots.config';

function SymbolIcon({ id }: { id: SymbolId }) {
  switch (id) {
    case 'ball':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <circle cx="12" cy="12" r="10" fill="#dbe4f5" stroke="#35f08b" strokeWidth="1.4" />
          <polygon points="12,8 15.8,10.8 14.3,15.2 9.7,15.2 8.2,10.8" fill="#101828" />
        </svg>
      );
    case 'boot':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <path
            d="M8 3c2-1 3 1 3 3l.4 8c3 .8 6 2 7 4.6.5 1.2-.6 2.4-2 2.4H7c-1.6 0-2.6-1.3-2.3-2.8L8 3z"
            fill="#ffc93c"
            stroke="#7a5510"
            strokeWidth="1"
          />
        </svg>
      );
    case 'glove':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <rect x="5" y="8" width="14" height="11" rx="3.4" fill="#1e9e5c" />
          <rect x="6" y="3" width="2.6" height="6" rx="1.3" fill="#7dffb9" />
          <rect x="9.8" y="2.4" width="2.6" height="6.6" rx="1.3" fill="#7dffb9" />
          <rect x="13.6" y="3" width="2.6" height="6" rx="1.3" fill="#7dffb9" />
          <rect x="17" y="7" width="3" height="6" rx="1.5" fill="#7dffb9" />
        </svg>
      );
    case 'jersey':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <path
            d="M9 3l3 1.4L15 3l5 3-1.6 3-1.4-1v13H7V8L5.6 9 4 6l5-3z"
            fill="#ff4d9d"
            stroke="#5e0f34"
            strokeWidth="1"
          />
          <text x="12" y="16.5" fontSize="7" fill="#fff" textAnchor="middle" fontWeight="bold">
            10
          </text>
        </svg>
      );
    case 'card':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <rect x="7" y="3.5" width="10" height="17" rx="1.6" fill="#ffe9a8" stroke="#8a6a14" strokeWidth="1" transform="rotate(-12 12 12)" />
        </svg>
      );
    case 'star':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <polygon
            points="12,2.5 14.9,8.6 21.5,9.4 16.6,14 17.9,20.6 12,17.3 6.1,20.6 7.4,14 2.5,9.4 9.1,8.6"
            fill="#b46bff"
          />
        </svg>
      );
    case 'whistle':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <rect x="2" y="8.5" width="11" height="5" rx="2.5" fill="#e7edf8" />
          <circle cx="15.5" cy="11.5" r="5.4" fill="#c6d2ea" />
          <circle cx="16.5" cy="12" r="1.8" fill="#101828" />
        </svg>
      );
    case 'trophy':
      return (
        <svg viewBox="0 0 24 24" className="h-7 w-7" aria-hidden>
          <path
            d="M7 3h10c0 6-2.5 8-5 8s-5-2-5-8z"
            fill="#ffc93c"
            stroke="#7a5510"
            strokeWidth="1"
          />
          <path d="M7 4H3.5c0 4 2 5.6 4.3 5.8M17 4h3.5c0 4-2 5.6-4.3 5.8" fill="none" stroke="#c8922a" strokeWidth="1.6" />
          <rect x="10.8" y="11" width="2.4" height="4" fill="#c8922a" />
          <rect x="8" y="15.5" width="8" height="3" rx="1" fill="#c8922a" />
        </svg>
      );
  }
}

export default function Paytable() {
  return (
    <Card className="border-white/10 bg-white/[0.03]">
      <CardHeader>
        <CardTitle className="text-base text-amber-300">★ Paytable — Stadium Slots</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <p className="text-xs leading-relaxed text-slate-300">
          Spins are earned on the table: <span className="text-emerald-300">SPIN saucer</span> (right
          orbit) and <span className="text-emerald-300">5 spinner passes</span> give a base spin,
          clearing the <span className="text-amber-300">Golden Bank</span> gives a{' '}
          <span className="text-amber-300">Golden Spin</span> where trophy odds are ×
          {TROPHY_GOLDEN_MULTIPLIER}. Pinball multiplier (spell G·O·A·L) boosts every line win.
        </p>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-white/10 text-left text-xs uppercase tracking-wide text-slate-400">
              <th className="pb-2">Symbol</th>
              <th className="pb-2 text-right">×3</th>
              <th className="pb-2 text-right">Any pair</th>
            </tr>
          </thead>
          <tbody>
            {[...SYMBOL_ORDER].reverse().map((id) => {
              const meta = SYMBOLS[id];
              return (
                <tr key={id} className="border-b border-white/5 last:border-0">
                  <td className="py-1.5">
                    <span className="flex items-center gap-2">
                      <SymbolIcon id={id} />
                      <span className="text-slate-100">{meta.name}</span>
                    </span>
                  </td>
                  <td className="py-1.5 text-right font-mono text-amber-200">
                    {meta.pay3 === 'JACKPOT' ? 'JACKPOT' : meta.pay3}
                  </td>
                  <td className="py-1.5 text-right font-mono text-emerald-300">{meta.pay2 || '—'}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
        <p className="text-[11px] leading-relaxed text-slate-400">
          Progressive jackpot starts at 500 credits and grows with every bumper, slingshot, spinner
          and target hit. RTP math vs the nominal {NOMINAL_SPIN_COST}-credit spin cost is documented
          in <span className="font-mono">docs/MATH.md</span>.
        </p>
      </CardContent>
    </Card>
  );
}
