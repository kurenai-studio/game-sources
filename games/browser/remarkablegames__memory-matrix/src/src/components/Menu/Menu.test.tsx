import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { STORAGE_KEY } from 'src/utils/storage';

import { Menu } from './Menu';

function seedSettings(best: { classic: number; timed: number }): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ best, volume: 0.5 }));
}

describe('Menu', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  it('renders the title and instructions', () => {
    render(<Menu onStart={vi.fn()} />);

    expect(
      screen.getByRole('heading', { level: 1, name: 'Memory Matrix' }),
    ).toBeInTheDocument();
    expect(screen.getByText('How to play')).toBeInTheDocument();
    expect(screen.getAllByRole('listitem')).toHaveLength(3);
  });

  it('shows the best score for each mode', () => {
    seedSettings({ classic: 12, timed: 9 });

    render(<Menu onStart={vi.fn()} />);

    expect(screen.getByText('Best: 12')).toBeInTheDocument();
    expect(screen.getByText('Best: 9')).toBeInTheDocument();
  });

  it('starts classic mode', async () => {
    const user = userEvent.setup();
    const onStart = vi.fn();

    render(<Menu onStart={onStart} />);
    await user.click(screen.getByRole('button', { name: /classic/i }));

    expect(onStart).toHaveBeenCalledWith('classic');
  });

  it('starts timed mode', async () => {
    const user = userEvent.setup();
    const onStart = vi.fn();

    render(<Menu onStart={onStart} />);
    await user.click(screen.getByRole('button', { name: /timed/i }));

    expect(onStart).toHaveBeenCalledWith('timed');
  });
});
