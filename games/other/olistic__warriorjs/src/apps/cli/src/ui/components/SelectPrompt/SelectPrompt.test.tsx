import { render } from 'ink-testing-library';
import { describe, expect, test, vi } from 'vitest';

import { waitForRender } from '../../../testing/index.js';
import SelectPrompt from './SelectPrompt.js';

const items = [
  { label: 'Option A', value: 'a' },
  { label: 'Option B', value: 'b' },
  { label: 'Option C', value: 'c' },
];

describe('SelectPrompt', () => {
  test('renders message and items', () => {
    const { lastFrame } = render(
      <SelectPrompt message="Pick one:" items={items} onSelect={vi.fn()} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Pick one:');
    expect(output).toContain('Option A');
    expect(output).toContain('Option B');
    expect(output).toContain('Option C');
  });

  test('first item is selected by default', () => {
    const { lastFrame } = render(<SelectPrompt message="Pick:" items={items} onSelect={vi.fn()} />);
    const output = lastFrame()!;
    expect(output).toContain('❯');
  });

  test('calls onSelect with value on enter', () => {
    const onSelect = vi.fn();
    const { stdin } = render(<SelectPrompt message="Pick:" items={items} onSelect={onSelect} />);
    stdin.write('\r');
    expect(onSelect).toHaveBeenCalledWith('a');
  });

  test('navigates down and selects second item', async () => {
    const onSelect = vi.fn();
    const { stdin } = render(<SelectPrompt message="Pick:" items={items} onSelect={onSelect} />);
    stdin.write('\x1B[B'); // down arrow
    await waitForRender();
    stdin.write('\r');
    expect(onSelect).toHaveBeenCalledWith('b');
  });

  test('wraps around when navigating past last item', async () => {
    const onSelect = vi.fn();
    const { stdin } = render(<SelectPrompt message="Pick:" items={items} onSelect={onSelect} />);
    stdin.write('\x1B[A'); // up arrow wraps to last
    await waitForRender();
    stdin.write('\r');
    expect(onSelect).toHaveBeenCalledWith('c');
  });

  test('shows submitted state after selection', async () => {
    const { stdin, lastFrame } = render(
      <SelectPrompt message="Pick:" items={items} onSelect={vi.fn()} />,
    );
    stdin.write('\r');
    await waitForRender();
    const output = lastFrame()!;
    expect(output).toContain('Pick:');
    expect(output).toContain('Option A');
    expect(output).not.toContain('❯');
  });

  test('renders without message', async () => {
    const { stdin, lastFrame } = render(
      <SelectPrompt message="" items={items} onSelect={vi.fn()} />,
    );
    stdin.write('\r');
    await waitForRender();
    const output = lastFrame()!;
    expect(output).toContain('Option A');
  });

  test('calls onCancel on escape', async () => {
    const onCancel = vi.fn();
    const { stdin } = render(
      <SelectPrompt message="Pick:" items={items} onSelect={vi.fn()} onCancel={onCancel} />,
    );
    stdin.write('\x1B');
    await waitForRender();
    expect(onCancel).toHaveBeenCalled();
  });

  test('supports separator items', () => {
    const itemsWithSep = [
      { label: 'Option A', value: 'a' },
      { separator: true as const },
      { label: 'Option B', value: 'b' },
    ];
    const { lastFrame } = render(
      <SelectPrompt message="Pick:" items={itemsWithSep} onSelect={vi.fn()} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('───');
  });

  test('respects initialIndex', () => {
    const onSelect = vi.fn();
    const { stdin } = render(
      <SelectPrompt message="Pick:" items={items} initialIndex={2} onSelect={onSelect} />,
    );
    stdin.write('\r');
    expect(onSelect).toHaveBeenCalledWith('c');
  });

  test('ignores input after submission', async () => {
    const onSelect = vi.fn();
    const { stdin } = render(<SelectPrompt message="Pick:" items={items} onSelect={onSelect} />);
    stdin.write('\r');
    await waitForRender();
    stdin.write('\x1B[B');
    await waitForRender();
    stdin.write('\r');
    expect(onSelect).toHaveBeenCalledTimes(1);
  });

  test('renders description below the label when provided', () => {
    const itemsWithDesc = [
      { label: 'Option A', value: 'a', description: 'Details about A' },
      { label: 'Option B', value: 'b' },
    ];
    const { lastFrame } = render(
      <SelectPrompt message="Pick:" items={itemsWithDesc} onSelect={vi.fn()} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Details about A');
    expect(output).toContain('Option A');
    expect(output).toContain('Option B');
  });

  test('does not render description line when not provided', () => {
    const { lastFrame } = render(<SelectPrompt message="Pick:" items={items} onSelect={vi.fn()} />);
    const lines = lastFrame()!.split('\n');
    // message + 3 items = 4 lines (no extra description lines)
    expect(lines).toHaveLength(4);
  });
});
