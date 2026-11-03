import { describe, expect, it } from 'vitest';
import { chooseTransformTarget } from '../src/core/targetSelection.js';

describe('chooseTransformTarget', () => {
  it('selects the highlighted prop when it is eligible and in range', () => {
    const props = [
      { id: 'crate', distance: 2.6, highlighted: false, eligible: true },
      { id: 'barrel', distance: 3.4, highlighted: true, eligible: true },
    ];

    expect(chooseTransformTarget(props, 4)?.id).toBe('barrel');
  });

  it('falls back to the nearest eligible prop and rejects distant props', () => {
    const props = [
      { id: 'rock', distance: 4.5, highlighted: false, eligible: true },
      { id: 'crate', distance: 2.2, highlighted: false, eligible: true },
      { id: 'occupied', distance: 1, highlighted: false, eligible: false },
    ];

    expect(chooseTransformTarget(props, 3)?.id).toBe('crate');
    expect(chooseTransformTarget(props, 1)).toBeNull();
  });
});
