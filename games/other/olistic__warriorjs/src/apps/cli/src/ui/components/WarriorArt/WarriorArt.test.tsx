import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import WarriorArt from './WarriorArt.js';

describe('WarriorArt', () => {
  test('renders warrior art', () => {
    const { lastFrame } = render(<WarriorArt />);
    const output = lastFrame()!;
    expect(output.split('\n').length).toBeGreaterThan(1);
  });
});
