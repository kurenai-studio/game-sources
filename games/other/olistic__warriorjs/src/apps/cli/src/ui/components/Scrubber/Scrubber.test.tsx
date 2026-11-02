import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import Scrubber from './Scrubber.js';

describe('Scrubber', () => {
  test('renders turn position in playback mode', () => {
    const { lastFrame } = render(
      <Scrubber currentTurn={4} totalTurns={15} speed={1} mode="playback" isPlaying={true} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Turn 4/14');
    expect(output).toContain('[space] pause');
  });

  test('shows play hint when paused', () => {
    const { lastFrame } = render(
      <Scrubber currentTurn={4} totalTurns={15} speed={2} mode="playback" isPlaying={false} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('[space] play');
  });

  test('highlights active speed', () => {
    const { lastFrame } = render(
      <Scrubber currentTurn={0} totalTurns={10} speed={2} mode="playback" isPlaying={true} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('2x');
  });

  test('shows review mode controls', () => {
    const { lastFrame } = render(
      <Scrubber currentTurn={14} totalTurns={15} speed={1} mode="review" isPlaying={false} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('[←/→] step');
    expect(output).toContain('[esc] go back');
  });
});
