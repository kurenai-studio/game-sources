import { render } from '@testing-library/react';

import { Confetti } from './Confetti';

function stubMatchMedia(matches: boolean): void {
  vi.stubGlobal('matchMedia', (query: string): MediaQueryList => ({
    matches,
    media: query,
    onchange: null,
    addListener: () => undefined,
    removeListener: () => undefined,
    addEventListener: () => undefined,
    removeEventListener: () => undefined,
    dispatchEvent: () => false,
  }));
}

describe('Confetti', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('renders celebration pieces', () => {
    stubMatchMedia(false);

    const { container } = render(<Confetti />);

    const overlay = container.querySelector('[aria-hidden="true"]');
    expect(overlay).toBeInTheDocument();
    expect(overlay).toHaveClass('pointer-events-none', 'fixed');
    expect(container.querySelectorAll('span')).toHaveLength(24);
  });

  it('renders nothing when reduced motion is preferred', () => {
    stubMatchMedia(true);

    const { container } = render(<Confetti />);

    expect(container.querySelector('span')).not.toBeInTheDocument();
  });
});
