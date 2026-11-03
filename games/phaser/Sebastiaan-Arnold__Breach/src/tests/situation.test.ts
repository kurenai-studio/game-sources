import { describe, expect, it } from 'vitest';
import { rollSituation } from '../src/game/situation';
import { HARBOUR_LANE } from '../src/levels/street-crime/harbour-lane';
import { KESTREL_ROAD } from '../src/levels/street-crime/kestrel-road';

describe('situation roll', () => {
  const m = HARBOUR_LANE.mission!;
  const seq = (values: number[]) => { let i = 0; return () => values[i++ % values.length]; };

  it('keeps the hostile count within the briefed range and always includes the patroller', () => {
    for (let i = 0; i < 50; i++) {
      const s = rollSituation(m);
      expect(s.hostiles.length).toBeGreaterThanOrEqual(m.hostiles.min);
      expect(s.hostiles.length).toBeLessThanOrEqual(m.hostiles.max);
      expect(s.hostiles.some((h) => h.type === 'patroller')).toBe(true);
      expect(s.civilians.length).toBe(1);
    }
  });

  it("always includes a hostage's captor", () => {
    const k = KESTREL_ROAD.mission!;
    const captor = k.hostileSlots.find((h) => h.always)!;
    for (let i = 0; i < 50; i++) expect(rollSituation(k).hostiles).toContain(captor);
  });

  it('can exceed the range by one on unverified intel', () => {
    const s = rollSituation({ ...m, reliability: 'Unverified' }, seq([0.99, 0.1, 0.5]));
    expect(s.hostiles.length).toBe(m.hostiles.max + 1);
  });
});
