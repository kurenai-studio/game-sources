import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import Divider from './Divider.js';

describe('Divider', () => {
  test('renders a line of dashes matching stdout columns', () => {
    const { lastFrame } = render(<Divider />);
    const output = lastFrame()!;
    // ink-testing-library stdout has 100 columns.
    expect(output).toBe('─'.repeat(100));
  });
});
