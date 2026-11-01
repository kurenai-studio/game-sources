import { render, screen } from '@testing-library/react';
import { START_TIME_MS, WARNING_MS } from 'src/utils/difficulty';

import { Hud } from './Hud';

describe('Hud', () => {
  it('shows the current round', () => {
    render(<Hud round={3} count={null} timeLeft={null} />);

    expect(screen.getByText('3')).toBeInTheDocument();
    expect(screen.getByText('Round')).toBeInTheDocument();
  });

  it('keeps the timer in the rightmost column as the count appears', () => {
    const { rerender } = render(
      <Hud round={2} count={null} timeLeft={30_000} />,
    );

    const row = () => screen.getByRole('timer').parentElement?.children;
    expect(row()).toHaveLength(3);

    rerender(<Hud round={2} count={5} timeLeft={30_000} />);

    expect(row()).toHaveLength(3);
    expect(row()?.[2]).toBe(screen.getByRole('timer'));
  });

  it('shows the bare target count during input', () => {
    render(<Hud round={1} count={5} timeLeft={null} />);

    expect(screen.getByText('5')).toBeInTheDocument();
    expect(screen.getByText('Recall 5 tiles')).toBeInTheDocument();
  });

  it('hides the count outside of input', () => {
    render(<Hud round={1} count={null} timeLeft={null} />);

    expect(screen.queryByText(/recall/i)).not.toBeInTheDocument();
    // The live region stays mounted so the count is announced when it lands.
    expect(screen.getByRole('status')).toBeEmptyDOMElement();
  });

  it('renders no clock in classic mode', () => {
    render(<Hud round={2} count={null} timeLeft={null} />);

    expect(screen.queryByRole('timer')).not.toBeInTheDocument();
    expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
  });

  it('renders the clock and remaining time in timed mode', () => {
    render(<Hud round={2} count={null} timeLeft={30_000} />);

    expect(screen.getByRole('timer')).toHaveTextContent('30s');

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-valuenow', '30');
    expect(bar).toHaveAttribute('aria-valuemax', '60');
  });

  it('rounds the clock up to the next second', () => {
    render(<Hud round={1} count={null} timeLeft={30_400} />);

    expect(screen.getByRole('timer')).toHaveTextContent('31s');
  });

  it('caps the bar when a bonus exceeds the starting clock', () => {
    render(<Hud round={1} count={null} timeLeft={START_TIME_MS + 9_000} />);

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-valuenow', '60');
    expect(bar.firstChild).toHaveStyle({ width: '100%' });
  });

  it('turns red when time is running out', () => {
    const { rerender } = render(
      <Hud round={1} count={null} timeLeft={WARNING_MS + 1_000} />,
    );

    expect(screen.getByRole('timer').className).not.toContain('text-red');
    expect(
      screen.getByRole('progressbar').querySelector('div')?.className,
    ).toContain('bg-sky-500');

    rerender(<Hud round={1} count={null} timeLeft={WARNING_MS} />);

    expect(screen.getByRole('timer').className).toContain('text-red-500');
    expect(
      screen.getByRole('progressbar').querySelector('div')?.className,
    ).toContain('bg-red-500');
  });
});
