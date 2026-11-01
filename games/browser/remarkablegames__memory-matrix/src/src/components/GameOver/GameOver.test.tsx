import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { STORAGE_KEY } from 'src/utils/storage';
import { success } from 'websfx';

import { GameOver } from './GameOver';

vi.mock('websfx');

interface GameOverOverrides {
  mode?: 'classic' | 'timed';
  score?: number;
  reason?: 'mistake' | 'timeout';
}

function renderGameOver(overrides: GameOverOverrides = {}) {
  const onAgain = vi.fn();
  const onMenu = vi.fn();
  const props = {
    mode: 'classic' as const,
    score: 4,
    reason: 'mistake' as const,
    onAgain,
    onMenu,
    ...overrides,
  };

  render(<GameOver {...props} />);
  return { onAgain, onMenu };
}

function seedBest(classic: number, timed = 0): void {
  localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify({ best: { classic, timed }, volume: 0.5 }),
  );
}

describe('GameOver', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  it('shows the final score and best', () => {
    seedBest(10);

    renderGameOver({ score: 4 });

    expect(
      screen.getByRole('heading', { level: 1, name: 'Game Over' }),
    ).toBeInTheDocument();
    expect(screen.getByText('4')).toBeInTheDocument();
    expect(screen.getByText('Rounds cleared')).toBeInTheDocument();
    expect(screen.getByText('Best: 10')).toBeInTheDocument();
    expect(screen.queryByText('New record!')).not.toBeInTheDocument();
  });

  it('announces a new record with a fanfare', () => {
    renderGameOver({ score: 4 });

    expect(screen.getByText('New record!')).toBeInTheDocument();
    expect(screen.getByText('Best: 4')).toBeInTheDocument();
    expect(success).toHaveBeenCalled();

    const stored: unknown = JSON.parse(
      localStorage.getItem(STORAGE_KEY) ?? '{}',
    );
    expect(stored).toMatchObject({ best: { classic: 4, timed: 0 } });
  });

  it('honors reduced motion by skipping the confetti', () => {
    vi.stubGlobal('matchMedia', (query: string): MediaQueryList => ({
      matches: query.includes('reduced-motion'),
      media: query,
      onchange: null,
      addListener: () => undefined,
      removeListener: () => undefined,
      addEventListener: () => undefined,
      removeEventListener: () => undefined,
      dispatchEvent: () => false,
    }));

    renderGameOver({ score: 4 });

    expect(screen.getByText('New record!')).toBeInTheDocument();
    expect(
      document.querySelector('span[class*="animate-confetti"]'),
    ).toBeNull();
    vi.unstubAllGlobals();
  });

  it('reads the clock running out', () => {
    renderGameOver({ mode: 'timed', reason: 'timeout', score: 2 });

    expect(
      screen.getByRole('heading', { level: 1, name: /time's up/i }),
    ).toBeInTheDocument();
    expect(screen.getByText('2')).toBeInTheDocument();
  });

  it('labels the mode', () => {
    renderGameOver({ mode: 'timed' });

    expect(screen.getByText('Timed run')).toBeInTheDocument();
  });

  it('gives the primary button a readable, conflict-free palette', () => {
    renderGameOver();

    const tokens = screen
      .getByRole('button', { name: 'Play again' })
      .className.split(' ');

    expect(tokens).toContain('bg-sky-700');
    expect(tokens).toContain('text-white');

    // Tailwind resolves same-specificity utilities by stylesheet order, so a
    // button must never carry two colors for the same property.
    expect(tokens).not.toContain('bg-slate-50');
    expect(tokens).not.toContain('text-slate-700');
    expect(tokens).not.toContain('border-slate-300');
    expect(tokens).not.toContain('dark:bg-slate-800');
    expect(tokens).not.toContain('dark:text-slate-200');
  });

  it('restarts the run', async () => {
    const user = userEvent.setup();
    const { onAgain } = renderGameOver();

    await user.click(screen.getByRole('button', { name: 'Play again' }));

    expect(onAgain).toHaveBeenCalledOnce();
  });

  it('returns to the menu', async () => {
    const user = userEvent.setup();
    const { onMenu } = renderGameOver();

    await user.click(screen.getByRole('button', { name: 'Menu' }));

    expect(onMenu).toHaveBeenCalledOnce();
  });
});
