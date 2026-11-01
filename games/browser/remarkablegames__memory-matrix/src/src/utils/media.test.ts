import { canHover } from './media';

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

describe('canHover', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('reports a hovering pointer', () => {
    stubMatchMedia(true);

    expect(canHover()).toBe(true);
  });

  it('reports a touch device', () => {
    stubMatchMedia(false);

    expect(canHover()).toBe(false);
  });

  it('reports no pointer when the browser has no media query support', () => {
    expect(canHover()).toBe(false);
  });
});
