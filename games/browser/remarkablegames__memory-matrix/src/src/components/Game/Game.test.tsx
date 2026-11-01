import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { GameState } from 'src/types/game';

import { Game } from './Game';

function makeState(overrides: Partial<GameState> = {}): GameState {
  return {
    phase: 'showing',
    mode: 'classic',
    round: 1,
    score: 0,
    gridSize: 3,
    pattern: [0, 1, 2],
    selection: [],
    result: null,
    timeLeft: null,
    reason: null,
    ...overrides,
  };
}

function renderGame(overrides: Partial<GameState> = {}) {
  const onToggle = vi.fn();
  render(<Game state={makeState(overrides)} onToggle={onToggle} />);
  return { onToggle };
}

describe('Game', () => {
  it('shows the hud and the grid', () => {
    renderGame();

    expect(screen.getByText('Round')).toBeInTheDocument();
    expect(screen.getAllByRole('button')).toHaveLength(9);
    expect(screen.getByRole('group', { name: 'Memory matrix' })).toBeVisible();
  });

  it('shows the target count during input only', () => {
    const { rerender } = render(
      <Game state={makeState()} onToggle={vi.fn()} />,
    );

    expect(screen.queryByText(/recall/i)).not.toBeInTheDocument();

    rerender(<Game state={makeState({ phase: 'input' })} onToggle={vi.fn()} />);
    expect(screen.getByText('Recall 3 tiles')).toBeInTheDocument();
  });

  it('forwards cell picks', async () => {
    const user = userEvent.setup();
    const { onToggle } = renderGame({ phase: 'input' });

    await user.click(screen.getByRole('button', { name: 'Row 2, column 2' }));

    expect(onToggle).toHaveBeenCalledWith(4);
  });

  it('does not accept picks during the reveal', async () => {
    const user = userEvent.setup();
    const { onToggle } = renderGame({ phase: 'showing' });

    await user.click(screen.getByRole('button', { name: 'Row 1, column 1' }));

    expect(onToggle).not.toHaveBeenCalled();
  });

  it('announces a correct pattern', () => {
    renderGame({ phase: 'feedback', result: 'correct' });

    expect(screen.getByText('Correct!')).toBeInTheDocument();
  });

  it('announces a wrong pattern', () => {
    renderGame({ phase: 'feedback', result: 'wrong' });

    expect(screen.getByText('Wrong!')).toBeInTheDocument();
  });

  it('runs no clock in classic mode', () => {
    renderGame({ mode: 'classic', timeLeft: null });

    expect(screen.queryByRole('timer')).not.toBeInTheDocument();
  });

  it('shows the clock in timed mode', () => {
    renderGame({ mode: 'timed', timeLeft: 42_000 });

    expect(screen.getByRole('timer')).toHaveTextContent('42s');
  });
});
