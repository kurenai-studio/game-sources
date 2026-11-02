/**
 * Direct verification: use the REAL game modules (rng + slots.config) to check
 * the golden-spin paying-hit frequency outside the browser.
 */
import { STRIPS_GOLDEN, STRIPS_BASE } from '../src/game/config/slots.config';
import { evaluate, pickStop } from '../src/game/slots/rng';

const N = 100_000;
for (const kind of ['golden', 'base'] as const) {
  const strips = kind === 'golden' ? STRIPS_GOLDEN : STRIPS_BASE;
  let paying = 0;
  let jackpots = 0;
  let nearMiss = 0;
  const lens = strips.map((s) => s.length);
  for (let i = 0; i < N; i += 1) {
    const stops = strips.map((s) => pickStop(s));
    const o = evaluate(stops, strips, kind);
    if (o.baseWin > 0) paying += 1;
    if (o.jackpot) jackpots += 1;
    if (o.nearMiss) nearMiss += 1;
  }
  console.log(
    `${kind}: strips=${lens.join('/')} paying=${((paying / N) * 100).toFixed(2)}% ` +
      `jackpot=1 in ${(N / jackpots).toFixed(1)} nearMiss=${((nearMiss / N) * 100).toFixed(2)}%`
  );
}

// Print first trophy stop index per golden strip (for deterministic browser injection).
console.log(
  'golden trophy stops:',
  STRIPS_GOLDEN.map((s) => s.indexOf('trophy')).join('/')
);
