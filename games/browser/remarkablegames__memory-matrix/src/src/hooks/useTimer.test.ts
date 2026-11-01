import { act, renderHook } from '@testing-library/react';
import { TICK_MS } from 'src/utils/difficulty';

import { useTimer } from './useTimer';

describe('useTimer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('dispatches a tick on every interval while active', () => {
    const dispatch = vi.fn();

    renderHook(() => {
      useTimer(true, dispatch);
    });

    act(() => {
      vi.advanceTimersByTime(TICK_MS * 3);
    });

    expect(dispatch).toHaveBeenCalledTimes(3);
    expect(dispatch).toHaveBeenCalledWith({ type: 'TICK' });
  });

  it('does not tick while inactive', () => {
    const dispatch = vi.fn();

    const { rerender } = renderHook(
      ({ active }: { active: boolean }) => {
        useTimer(active, dispatch);
      },
      { initialProps: { active: true } },
    );

    rerender({ active: false });

    act(() => {
      vi.advanceTimersByTime(TICK_MS * 5);
    });

    expect(dispatch).not.toHaveBeenCalled();
  });

  it('stops ticking on unmount', () => {
    const dispatch = vi.fn();

    const { unmount } = renderHook(() => {
      useTimer(true, dispatch);
    });
    unmount();

    act(() => {
      vi.advanceTimersByTime(TICK_MS * 5);
    });

    expect(dispatch).not.toHaveBeenCalled();
  });
});
