import {
  calculateBrickLayout,
  classifyElements,
  getLayoutMode,
  hexToCss,
} from '../src/brickLayout.js';
import { COLORS } from '../src/constants.js';

const resume = [
  { tag: 'p', text: 'Nathan Zimmerman' },
  { tag: 'p', text: 'Raritan, NJ' },
  { tag: 'p', text: '610.955.6578' },
  { tag: 'p', text: 'WORK HISTORY' },
  { tag: 'p', text: 'Software Engineer II, Nelnet\t10/2023 – Present' },
  { tag: 'li', text: 'Built core features.' },
  { tag: 'p', text: 'SKILLS' },
  { tag: 'p', text: 'C#, .NET, Angular' },
];

function mockResume(elements = resume) {
  global.fetch = jest.fn().mockResolvedValue({
    ok: true,
    json: jest.fn().mockResolvedValue(elements),
  });
}

function setViewport(width, height) {
  Object.defineProperty(window, 'innerWidth', { writable: true, value: width });
  Object.defineProperty(window, 'innerHeight', {
    writable: true,
    value: height,
  });
}

describe('brick layout', () => {
  beforeEach(() => {
    document.documentElement.removeAttribute('data-theme');
    delete document.fonts;
    setViewport(1200, 900);
    mockResume();
  });

  test('classifyElements labels the parts of a résumé', () => {
    expect(classifyElements(resume).map((element) => element.kind)).toEqual([
      'name',
      'contact',
      'contact',
      'heading',
      'role',
      'bullet',
      'heading',
      'body',
    ]);
  });

  test('classifyElements tolerates entries without text', () => {
    expect(classifyElements([{ tag: 'p' }, null])).toEqual([
      { tag: 'p', text: '', kind: 'name' },
      { text: '', kind: 'contact' },
    ]);
  });

  test('the layout follows the document theme', () => {
    expect(getLayoutMode()).toBe('wall');

    document.documentElement.dataset.theme = 'dark';
    expect(getLayoutMode()).toBe('wall');

    document.documentElement.dataset.theme = 'light';
    expect(getLayoutMode()).toBe('typeset');
  });

  test('wall layout justifies rows and keeps each word findable', async () => {
    const { bricks, totalRows, mode } = await calculateBrickLayout();

    expect(mode).toBe('wall');
    expect(totalRows).toBe(bricks[bricks.length - 1].rowIndex + 1);
    expect(bricks[0]).toMatchObject({
      text: 'Nathan',
      kind: 'name',
      height: 24,
      wordIndex: 0,
      colIndex: 0,
      color: COLORS.BRICK_COLORS[0],
    });
    expect(bricks.map((brick) => brick.wordIndex)).toEqual(
      bricks.map((_, index) => index)
    );

    const last = bricks[bricks.length - 1];
    expect(last.isLastInRow).toBe(true);
    expect(last.x + last.width).toBeCloseTo(1200 - 10, 5);
  });

  test('wall layout numbers words it has no room to show', async () => {
    setViewport(260, 80);

    const { bricks } = await calculateBrickLayout({ mode: 'wall' });
    const full = classifyElements(resume)
      .flatMap((element) => element.text.split(/\s+/))
      .filter(Boolean);

    expect(bricks.length).toBeLessThan(full.length);
    bricks.forEach((brick) => {
      expect(full[brick.wordIndex]).toBe(brick.text);
    });
  });

  test('typeset layout is used for the Paper theme', async () => {
    document.documentElement.dataset.theme = 'light';

    const { bricks, totalRows, mode } = await calculateBrickLayout();

    expect(mode).toBe('typeset');
    expect(bricks[0]).toMatchObject({ text: 'Nathan', kind: 'name' });
    expect(bricks[0].font).toContain('px');
    expect(bricks.some((brick) => brick.kind === 'rule')).toBe(true);
    expect(bricks.filter((brick) => brick.kind === 'dot')).toHaveLength(1);
    expect(totalRows).toBeGreaterThan(4);
  });

  test('typeset layout measures with canvas metrics when they exist', async () => {
    const measureText = jest.fn((text) => ({ width: text.length * 7 }));
    const originalGetContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = jest.fn(() => ({ measureText }));

    const { bricks } = await calculateBrickLayout({ mode: 'typeset' });
    HTMLCanvasElement.prototype.getContext = originalGetContext;

    expect(measureText).toHaveBeenCalledWith('Nathan');
    expect(bricks[0].width).toBe('Nathan'.length * 7 + 4);
  });

  test('typeset layout waits for its fonts, and carries on if they fail', async () => {
    document.fonts = { load: jest.fn(() => Promise.resolve([])) };
    await calculateBrickLayout({ mode: 'typeset' });
    expect(document.fonts.load).toHaveBeenCalledTimes(3);

    document.fonts = { load: jest.fn(() => Promise.reject(new Error('no'))) };
    const { bricks } = await calculateBrickLayout({ mode: 'typeset' });
    expect(bricks.length).toBeGreaterThan(0);
  });

  test('a failed résumé request is reported', async () => {
    global.fetch = jest.fn().mockResolvedValue({ ok: false, status: 404 });

    await expect(calculateBrickLayout()).rejects.toThrow(
      'Failed to load resume data: 404'
    );
  });

  test('hexToCss pads short colour values', () => {
    expect(hexToCss(0x00ff00)).toBe('#00ff00');
  });
});
