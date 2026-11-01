import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { STORAGE_KEY } from 'src/utils/storage';
import { configure } from 'websfx';

import { SoundToggle } from './SoundToggle';

vi.mock('websfx');

function seedSettings(volume: number, classic = 0, timed = 0): void {
  localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify({ best: { classic, timed }, volume }),
  );
}

describe('SoundToggle', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  it('applies the stored volume on mount', () => {
    seedSettings(0.25);

    render(<SoundToggle />);

    expect(configure).toHaveBeenCalledWith({ volume: 0.25 });
  });

  it('shows as on when sound is enabled', () => {
    seedSettings(1);

    render(<SoundToggle />);

    expect(screen.getByRole('switch', { name: 'Sound' })).toHaveAttribute(
      'aria-checked',
      'true',
    );
  });

  it('reflects a muted preference', () => {
    seedSettings(0);

    render(<SoundToggle />);

    expect(configure).toHaveBeenCalledWith({ volume: 0 });
    expect(screen.getByRole('switch', { name: 'Sound' })).toHaveAttribute(
      'aria-checked',
      'false',
    );
  });

  it('mutes and restores sound', async () => {
    const user = userEvent.setup();
    seedSettings(1);
    render(<SoundToggle />);

    const toggle = screen.getByRole('switch', { name: 'Sound' });

    await user.click(toggle);
    expect(toggle).toHaveAttribute('aria-checked', 'false');
    expect(configure).toHaveBeenLastCalledWith({ volume: 0 });

    await user.click(toggle);
    expect(toggle).toHaveAttribute('aria-checked', 'true');
    expect(configure).toHaveBeenLastCalledWith({ volume: 1 });
  });

  it('keeps best scores while toggling', async () => {
    const user = userEvent.setup();
    seedSettings(1, 7, 2);
    render(<SoundToggle />);

    await user.click(screen.getByRole('switch', { name: 'Sound' }));

    expect(JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '{}')).toMatchObject(
      { best: { classic: 7, timed: 2 }, volume: 0 },
    );
  });

  it('draws the icon without a label of its own', () => {
    seedSettings(1);
    const { container } = render(<SoundToggle />);

    const svg = container.querySelector('svg');
    expect(svg).toHaveAttribute('aria-hidden', 'true');
    expect(svg?.querySelectorAll('path')).toHaveLength(3);
  });
});
