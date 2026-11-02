/// <reference types="vitest/globals" />

import { act } from 'react';

declare global {
  var IS_REACT_ACT_ENVIRONMENT: boolean;
}

globalThis.IS_REACT_ACT_ENVIRONMENT = true;

// ink-testing-library doesn't wrap its operations in act(), so React warns about
// state updates happening outside of act() in every test. This mock patches
// render(), rerender(), and stdin.write() to automatically wrap them in act(),
// suppressing the warnings across all test files without needing per-test changes.
vi.mock('ink-testing-library', async (importOriginal) => {
  const mod = await importOriginal<typeof import('ink-testing-library')>();
  return {
    ...mod,
    render: (tree: React.ReactElement) => {
      let result!: ReturnType<typeof mod.render>;
      act(() => {
        result = mod.render(tree);
      });
      const originalRerender = result.rerender;
      result.rerender = (tree: React.ReactElement) => {
        act(() => {
          originalRerender(tree);
        });
      };
      const originalStdinWrite = result.stdin.write;
      result.stdin.write = (data: string) => {
        act(() => {
          originalStdinWrite(data);
        });
      };
      return result;
    },
  };
});
