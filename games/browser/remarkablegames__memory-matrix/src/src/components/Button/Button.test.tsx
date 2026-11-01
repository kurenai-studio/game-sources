import { fireEvent, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { click, hover } from 'websfx';

import { Button } from './Button';

vi.mock('websfx');

function stubPointer(matches: boolean): void {
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

describe('Button', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.clearAllMocks();
  });

  it('defaults to the secondary variant', () => {
    render(<Button>Menu</Button>);

    expect(screen.getByRole('button', { name: 'Menu' }).className).toContain(
      'bg-slate-50',
    );
  });

  it.each([
    ['primary', 'bg-sky-700'],
    ['secondary', 'border-slate-300'],
    ['mode', 'w-full'],
    ['icon', 'rounded-full'],
  ] as const)('renders the %s variant', (variant, token) => {
    render(<Button variant={variant}>Label</Button>);

    const tokens = screen.getByRole('button').className.split(' ');
    expect(tokens).toContain(token);
    expect(tokens).toContain('cursor-pointer');
  });

  it('merges extra classes', () => {
    render(<Button className="mt-4">Menu</Button>);

    expect(screen.getByRole('button').className.split(' ')).toContain('mt-4');
  });

  it('cues and forwards clicks', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Play again</Button>);

    await user.click(screen.getByRole('button'));

    expect(click).toHaveBeenCalledOnce();
    expect(onClick).toHaveBeenCalledOnce();
  });

  it('cues keyboard activation too', async () => {
    const user = userEvent.setup();
    render(<Button>Play again</Button>);

    await user.tab();
    await user.keyboard('{Enter}');

    expect(click).toHaveBeenCalledOnce();
  });

  it('cues hovers on pointer devices only', () => {
    stubPointer(true);
    const { rerender } = render(<Button>Menu</Button>);

    fireEvent.mouseEnter(screen.getByRole('button'));
    expect(hover).toHaveBeenCalledOnce();

    stubPointer(false);
    rerender(<Button>Menu</Button>);
    fireEvent.mouseEnter(screen.getByRole('button'));

    expect(hover).toHaveBeenCalledOnce();
  });

  it('passes through native button props', () => {
    render(
      <Button role="switch" aria-checked={false} disabled>
        Sound
      </Button>,
    );

    const button = screen.getByRole('switch', { name: 'Sound' });
    expect(button).toHaveAttribute('aria-checked', 'false');
    expect(button).toBeDisabled();
    expect(button).toHaveAttribute('type', 'button');
  });
});
