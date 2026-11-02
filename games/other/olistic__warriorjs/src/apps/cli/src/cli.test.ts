import { expect, test, vi } from 'vitest';

import { run } from './cli.js';
import Game from './Game.js';

vi.mock('ink', () => ({
  render: vi.fn(() => ({
    waitUntilExit: () => Promise.resolve(),
  })),
}));

vi.mock('./ui/components/App.js', () => ({
  default: vi.fn(),
}));

vi.mock('./Game.js', () => {
  const MockGame = vi.fn(function (this: any) {});
  return { default: MockGame, __esModule: true };
});

test('builds context and renders the app', async () => {
  const mockContext = { towers: [] };
  const mockBuildContext = vi.fn(() => mockContext);
  (Game as any).mockImplementation(function (this: any) {
    this.buildContext = mockBuildContext;
  });
  await run(['-d', '/path/to/game', '-l', '2', '-s']);
  expect(Game).toHaveBeenCalledWith('/path/to/game', 2, true);
  expect(mockBuildContext).toHaveBeenCalled();

  const { render } = await import('ink');
  expect(render).toHaveBeenCalled();
});
