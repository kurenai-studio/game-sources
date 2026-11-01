import { act, fireEvent, render, screen } from '@testing-library/react';
import {
  FEEDBACK_CORRECT_MS,
  FEEDBACK_WRONG_MS,
  getRevealDuration,
  LOCK_IN_MS,
  START_TIME_MS,
  TICK_MS,
} from 'src/utils/difficulty';
import { STORAGE_KEY } from 'src/utils/storage';

import { App } from '.';

vi.mock('websfx');
vi.mock('src/utils/pattern', () => ({
  createPattern: vi.fn(() => [0, 1, 2]),
}));

const REVEAL = getRevealDuration(3);

function advance(ms: number): void {
  act(() => {
    vi.advanceTimersByTime(ms);
  });
}

function cell(name: string): HTMLElement {
  return screen.getByRole('button', { name });
}

function startClassic(): void {
  fireEvent.click(screen.getByRole('button', { name: /classic/i }));
  advance(REVEAL);
}

function pick(...names: string[]): void {
  for (const name of names) {
    fireEvent.click(cell(name));
  }
}

function expectLockedCells(): void {
  const buttons = screen.getAllByRole('button');
  expect(buttons).toHaveLength(9);
  for (const button of buttons) {
    expect(button).toBeDisabled();
  }
}

function miss(): void {
  pick('Row 1, column 1', 'Row 1, column 2', 'Row 2, column 1');
  advance(LOCK_IN_MS);
}

describe('App', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.clearAllMocks();
    localStorage.clear();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('suppresses double-tap zoom on the play surface', () => {
    const { container } = render(<App />);
    const main = container.querySelector('main');

    expect(main).toHaveClass('touch-manipulation');
    // Tight page padding keeps 7x7 tiles at or above 44pt on small phones.
    expect(main).toHaveClass('px-2');
  });

  it('keeps the sound toggle on every screen', () => {
    render(<App />);

    expect(
      screen.getByRole('heading', { level: 1, name: 'Memory Matrix' }),
    ).toBeInTheDocument();
    expect(screen.getByRole('switch', { name: 'Sound' })).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /classic/i }));

    expect(screen.getByRole('switch', { name: 'Sound' })).toBeInTheDocument();
  });

  it('clears a full classic round and advances', () => {
    render(<App />);

    fireEvent.click(screen.getByRole('button', { name: /classic/i }));
    expectLockedCells();

    advance(REVEAL);

    pick('Row 1, column 1', 'Row 1, column 2', 'Row 1, column 3');
    advance(LOCK_IN_MS);
    expect(screen.getByText('Correct!')).toBeInTheDocument();

    advance(FEEDBACK_CORRECT_MS);
    expect(screen.getByText('2')).toBeInTheDocument();
    expect(screen.queryByText('Recall 3 tiles')).not.toBeInTheDocument();
  });

  it('ends a classic run on a wrong pattern', () => {
    render(<App />);

    startClassic();
    miss();
    expect(screen.getByText('Wrong!')).toBeInTheDocument();

    advance(FEEDBACK_WRONG_MS);

    expect(
      screen.getByRole('heading', { level: 1, name: 'Game Over' }),
    ).toBeInTheDocument();
    expect(screen.getByText('0')).toBeInTheDocument();
    expect(screen.queryByText('New record!')).not.toBeInTheDocument();
  });

  it('runs the clock in timed mode', () => {
    render(<App />);

    fireEvent.click(screen.getByRole('button', { name: /timed/i }));

    expect(screen.getByRole('timer')).toHaveTextContent('60s');

    advance(TICK_MS * 10);

    expect(screen.getByRole('timer')).toHaveTextContent('59s');
    expect(START_TIME_MS).toBe(60_000);
  });

  it('persists a record after a finished run', () => {
    render(<App />);

    startClassic();
    pick('Row 1, column 1', 'Row 1, column 2', 'Row 1, column 3');
    advance(LOCK_IN_MS);
    advance(FEEDBACK_CORRECT_MS);

    advance(REVEAL);
    miss();
    advance(FEEDBACK_WRONG_MS);

    expect(screen.getByText('New record!')).toBeInTheDocument();
    expect(screen.getByText('Best: 1')).toBeInTheDocument();

    const stored: unknown = JSON.parse(
      localStorage.getItem(STORAGE_KEY) ?? '{}',
    );
    expect(stored).toMatchObject({ best: { classic: 1, timed: 0 } });
  });

  it('replays from game over', () => {
    render(<App />);

    startClassic();
    miss();
    advance(FEEDBACK_WRONG_MS);

    fireEvent.click(screen.getByRole('button', { name: 'Play again' }));

    expect(screen.getByText('Round')).toBeInTheDocument();
    expectLockedCells();
  });

  it('returns to the menu from game over', () => {
    render(<App />);

    startClassic();
    miss();
    advance(FEEDBACK_WRONG_MS);

    fireEvent.click(screen.getByRole('button', { name: 'Menu' }));

    expect(
      screen.getByRole('heading', { level: 1, name: 'Memory Matrix' }),
    ).toBeInTheDocument();
  });
});
