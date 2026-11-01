import { fireEvent, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { Phase, Result } from 'src/types/game';
import { type } from 'websfx';

import { Grid } from './Grid';

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

interface GridOverrides {
  gridSize?: number;
  pattern?: number[];
  selection?: number[];
  phase?: Phase;
  result?: Result | null;
  onToggle?: (index: number) => void;
}

function renderGrid(overrides: GridOverrides = {}) {
  const onToggle = overrides.onToggle ?? vi.fn();
  const props = {
    gridSize: 3,
    pattern: [0, 1, 2],
    selection: [] as number[],
    phase: 'input' as Phase,
    result: null as Result | null,
    onToggle,
    ...overrides,
  };

  const { rerender } = render(<Grid {...props} />);
  return { onToggle, rerender };
}

function cell(row: number, column: number): HTMLElement {
  return screen.getByRole('button', {
    name: `Row ${String(row)}, column ${String(column)}`,
  });
}

describe('Grid', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.clearAllMocks();
  });

  it('ticks when a hovering pointer enters a tile during input', () => {
    stubPointer(true);
    renderGrid({ phase: 'input' });

    fireEvent.mouseEnter(cell(2, 2));
    fireEvent.mouseEnter(cell(3, 3));
    expect(type).toHaveBeenCalledTimes(2);
  });

  it('stays silent on touch devices and outside input', () => {
    stubPointer(false);
    const { rerender } = renderGrid({ phase: 'input' });

    fireEvent.mouseEnter(cell(1, 1));
    expect(type).not.toHaveBeenCalled();

    rerender(
      <Grid
        gridSize={3}
        pattern={[0, 1, 2]}
        selection={[]}
        phase="showing"
        result={null}
        onToggle={vi.fn()}
      />,
    );
    fireEvent.mouseEnter(cell(1, 1));

    expect(type).not.toHaveBeenCalled();
  });

  it('stays silent when the browser has no pointer query', () => {
    renderGrid({ phase: 'input' });

    fireEvent.mouseEnter(cell(2, 2));

    expect(type).not.toHaveBeenCalled();
  });

  it('renders one cell per grid position', () => {
    renderGrid();

    expect(screen.getAllByRole('button')).toHaveLength(9);
    expect(screen.getByRole('group', { name: 'Memory matrix' })).toBeVisible();
  });

  it('labels cells with their row and column', () => {
    renderGrid();

    expect(cell(2, 3)).toBeInTheDocument();
    expect(cell(1, 1)).toBeInTheDocument();
  });

  it('toggles a cell on click', async () => {
    const user = userEvent.setup();
    const { onToggle } = renderGrid();

    await user.click(cell(2, 2));

    expect(onToggle).toHaveBeenCalledWith(4);
  });

  it('supports keyboard activation', async () => {
    const user = userEvent.setup();
    const { onToggle } = renderGrid();

    cell(1, 1).focus();
    await user.keyboard('{Enter}');

    expect(onToggle).toHaveBeenCalledWith(0);
  });

  it('locks cells outside the input phase', async () => {
    const user = userEvent.setup();
    const { onToggle } = renderGrid({ phase: 'showing' });

    expect(screen.getAllByRole('button')).toHaveLength(9);
    for (const button of screen.getAllByRole('button')) {
      expect(button).toBeDisabled();
    }

    await user.click(cell(1, 1));
    expect(onToggle).not.toHaveBeenCalled();
  });

  it('lights the pattern during the reveal', () => {
    renderGrid({ phase: 'showing', pattern: [0, 1, 2] });

    expect(cell(1, 1)).toHaveAttribute('data-state', 'lit');
    expect(cell(1, 2)).toHaveAttribute('data-state', 'lit');
    expect(cell(1, 3)).toHaveAttribute('data-state', 'lit');
    expect(cell(2, 1)).toHaveAttribute('data-state', 'neutral');
  });

  it('staggers the pop-in animation across lit cells', () => {
    renderGrid({ phase: 'showing', pattern: [0, 1, 2] });

    expect(cell(1, 1)).toHaveStyle({ animationDelay: '0ms' });
    expect(cell(1, 3)).toHaveStyle({ animationDelay: '80ms' });
    expect(cell(2, 1)).not.toHaveStyle({ animationDelay: '0ms' });
  });

  it('marks picked cells during input', () => {
    renderGrid({ phase: 'input', selection: [1, 4] });

    expect(cell(1, 2)).toHaveAttribute('aria-pressed', 'true');
    expect(cell(2, 2)).toHaveAttribute('aria-pressed', 'true');
    expect(cell(1, 1)).toHaveAttribute('aria-pressed', 'false');
    expect(cell(1, 2)).toHaveAttribute('data-state', 'selected');
    expect(cell(2, 1)).toHaveAttribute('data-state', 'neutral');
  });

  it('reveals the truth after a miss', () => {
    renderGrid({
      phase: 'feedback',
      result: 'wrong',
      pattern: [0, 1, 2],
      selection: [0, 1, 3],
    });

    expect(cell(1, 1)).toHaveAttribute('data-state', 'correct');
    expect(cell(1, 3)).toHaveAttribute('data-state', 'missed');
    expect(cell(2, 1)).toHaveAttribute('data-state', 'wrong');
    expect(cell(3, 3)).toHaveAttribute('data-state', 'neutral');
    expect(screen.getByText('✗')).toBeInTheDocument();
  });

  it('marks a missed tile with structure, not just a pale fill', () => {
    renderGrid({
      phase: 'feedback',
      result: 'wrong',
      pattern: [0, 1, 2],
      selection: [0, 1, 3],
    });

    const missed = cell(1, 3).className.split(' ');

    // The fill sits at ~1.05:1 against an untouched tile, so the dashed
    // 4px outline is what actually marks the cell.
    expect(missed).toContain('border-dashed');
    expect(missed).toContain('border-4');
    expect(missed).toContain('border-green-600');

    // A correct pick stays solid, so hollow-vs-solid survives without color.
    const correct = cell(1, 1).className.split(' ');
    expect(correct).not.toContain('border-dashed');
    expect(correct).toContain('bg-green-500');
  });

  it('shows all cells correct after a clean pick', () => {
    renderGrid({
      phase: 'feedback',
      result: 'correct',
      pattern: [0, 1, 2],
      selection: [0, 1, 2],
    });

    expect(cell(1, 1)).toHaveAttribute('data-state', 'correct');
    expect(cell(3, 3)).toHaveAttribute('data-state', 'neutral');
    expect(screen.queryByText('✗')).not.toBeInTheDocument();
  });

  it('reads as a tray that separates every tile', () => {
    renderGrid();

    const board = screen.getByRole('group').className.split(' ');
    expect(board).toContain('bg-slate-300');
    expect(board).toContain('dark:bg-slate-950');

    const tiles = cell(1, 1).className.split(' ');
    expect(tiles).toContain('bg-slate-100');
    // The tile edge must stay visible against the darker tray.
    expect(tiles).toContain('border-slate-400');
  });

  it('keeps cells square inside the board', () => {
    renderGrid({ gridSize: 4 });

    const grid = screen.getByRole('group');
    const classes = grid.className.split(' ');
    expect(classes).toContain('aspect-square');
    // No ad-hoc aspect ratios: the board is square and hugs the tiles.
    expect(classes.filter((name) => name.startsWith('aspect-['))).toHaveLength(
      0,
    );
    expect(classes).toContain('content-center');
    expect(grid.style.gridTemplateRows).toBe('repeat(4, auto)');
    expect(cell(1, 1).className.split(' ')).toContain('aspect-square');
  });

  it('adds pointer and hover affordances during input only', () => {
    const { rerender } = renderGrid({ phase: 'input' });

    const tokens = cell(1, 1).className.split(' ');
    expect(tokens).toContain('cursor-pointer');
    expect(tokens).toContain('hover:-translate-y-0.5');
    expect(tokens).toContain('bg-slate-100');

    // Tiles are disabled outside input, so they must not look clickable.
    rerender(
      <Grid
        gridSize={3}
        pattern={[0, 1, 2]}
        selection={[]}
        phase="showing"
        result={null}
        onToggle={vi.fn()}
      />,
    );

    const idle = cell(1, 1).className.split(' ');
    expect(idle).not.toContain('cursor-pointer');
    expect(idle).not.toContain('hover:-translate-y-0.5');
  });

  it('renders plain cells outside of play', () => {
    renderGrid({ phase: 'menu', pattern: [], selection: [] });

    expect(cell(1, 1)).toHaveAttribute('data-state', 'neutral');
    expect(cell(1, 1)).toHaveAttribute('aria-pressed', 'false');
  });

  it('shakes the grid on a wrong result only', () => {
    const { rerender } = renderGrid({
      phase: 'feedback',
      result: 'wrong',
    });

    const grid = screen.getByRole('group');
    expect(grid.className).toContain('animate-shake');

    rerender(
      <Grid
        gridSize={3}
        pattern={[0, 1, 2]}
        selection={[]}
        phase="feedback"
        result="correct"
        onToggle={vi.fn()}
      />,
    );
    expect(grid.className).not.toContain('animate-shake');
  });

  it('moves focus with the arrow keys', async () => {
    const user = userEvent.setup();
    renderGrid();

    cell(2, 2).focus();

    await user.keyboard('{ArrowRight}');
    expect(cell(2, 3)).toHaveFocus();

    await user.keyboard('{ArrowDown}');
    expect(cell(3, 3)).toHaveFocus();

    await user.keyboard('{ArrowLeft}');
    expect(cell(3, 2)).toHaveFocus();

    await user.keyboard('{ArrowUp}');
    expect(cell(2, 2)).toHaveFocus();
  });

  it('stops the arrow keys at the edges', async () => {
    const user = userEvent.setup();
    renderGrid();

    cell(1, 1).focus();

    await user.keyboard('{ArrowUp}');
    expect(cell(1, 1)).toHaveFocus();

    await user.keyboard('{ArrowLeft}');
    expect(cell(1, 1)).toHaveFocus();

    cell(3, 3).focus();
    await user.keyboard('{ArrowDown}');
    expect(cell(3, 3)).toHaveFocus();

    await user.keyboard('{ArrowRight}');
    expect(cell(3, 3)).toHaveFocus();
  });

  it('does not cross rows with horizontal arrows', async () => {
    const user = userEvent.setup();
    renderGrid();

    cell(2, 1).focus();

    await user.keyboard('{ArrowLeft}');
    expect(cell(2, 1)).toHaveFocus();
  });

  it('ignores keys that are not arrows', async () => {
    const user = userEvent.setup();
    const { onToggle } = renderGrid();

    cell(1, 1).focus();
    await user.keyboard('{Escape}');

    expect(cell(1, 1)).toHaveFocus();
    expect(onToggle).not.toHaveBeenCalled();
  });

  it('ignores key presses that do not originate from a cell', () => {
    renderGrid();

    const grid = screen.getByRole('group');
    fireEvent.keyDown(grid, { key: 'ArrowRight' });

    expect(cell(1, 1)).not.toHaveFocus();
  });
});
