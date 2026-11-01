import { enableSeamDrag, renderOverlayBricks } from '../src/overlay.js';

function mockResume(elements) {
  global.fetch = jest.fn().mockResolvedValue({
    ok: true,
    json: jest.fn().mockResolvedValue(elements),
  });
}

describe('start screen résumé', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="startOverlay">
        <div id="light" class="look-resume" data-mode="typeset"></div>
        <div id="dark" class="look-resume" data-mode="wall"></div>
      </div>`;
    document.documentElement.removeAttribute('data-theme');
    Object.defineProperty(window, 'innerWidth', { writable: true, value: 900 });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 700,
    });
  });

  test('does nothing without a start overlay', async () => {
    document.body.innerHTML = '';
    global.fetch = jest.fn();

    await renderOverlayBricks();

    expect(global.fetch).not.toHaveBeenCalled();
  });

  test('does nothing when the overlay has no look panes', async () => {
    document.body.innerHTML = '<div id="startOverlay"></div>';
    global.fetch = jest.fn();

    await renderOverlayBricks();

    expect(global.fetch).not.toHaveBeenCalled();
  });

  test('draws the résumé in both looks from a single request', async () => {
    mockResume([
      { tag: 'p', text: 'Nathan Zimmerman' },
      { tag: 'p', text: 'Raritan, NJ' },
    ]);

    await renderOverlayBricks();

    const light = document.getElementById('light');
    const dark = document.getElementById('dark');
    expect(global.fetch).toHaveBeenCalledTimes(1);
    expect(light.dataset.layout).toBe('typeset');
    expect(dark.dataset.layout).toBe('wall');
    expect(dark.querySelectorAll('.overlay-brick')).toHaveLength(4);
    // Only the typeset page carries a rule under the contact line, and its
    // pieces are bricks like the four words.
    const rule = light.querySelectorAll('.overlay-brick.brick--rule');
    expect(rule.length).toBeGreaterThan(0);
    expect(light.querySelectorAll('.overlay-brick')).toHaveLength(
      4 + rule.length
    );
    expect(dark.querySelectorAll('.brick--rule')).toHaveLength(0);
  });

  test('warns instead of failing when the résumé cannot be loaded', async () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
    global.fetch = jest.fn().mockRejectedValue(new Error('offline'));

    await expect(renderOverlayBricks()).resolves.toBeUndefined();

    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });
});

describe('start screen seam', () => {
  let overlay;

  const pointer = (
    type,
    { x = 0, pointerType = 'touch', target = overlay }
  ) => {
    const event = new Event(type, { bubbles: true });
    Object.assign(event, { clientX: x, pointerType });
    target.dispatchEvent(event);
  };
  const split = () => overlay.style.getPropertyValue('--split');

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="startOverlay">
        <button id="play">Play</button>
      </div>`;
    overlay = document.getElementById('startOverlay');
    overlay.getBoundingClientRect = () => ({ left: 0, width: 400 });
    enableSeamDrag();
  });

  test('a finger drags the seam, back and forth', () => {
    pointer('pointerdown', { x: 100 });
    expect(split()).toBe('25.0%');
    expect(overlay.classList.contains('is-dragging')).toBe(true);

    pointer('pointermove', { x: 300 });
    expect(split()).toBe('75.0%');

    pointer('pointermove', { x: 180 });
    expect(split()).toBe('45.0%');

    pointer('pointerup', {});
    expect(overlay.classList.contains('is-dragging')).toBe(false);
    expect(split()).toBe('45.0%');
  });

  test('the seam stops short of either edge', () => {
    pointer('pointermove', { x: 0, pointerType: 'pen' });
    expect(split()).toBe('12.0%');

    pointer('pointermove', { x: 400 });
    expect(split()).toBe('88.0%');

    pointer('pointercancel', {});
    expect(overlay.classList.contains('is-dragging')).toBe(false);
  });

  test('a mouse, a tap on a button, and a hidden overlay leave the seam alone', () => {
    pointer('pointermove', { x: 100, pointerType: 'mouse' });
    pointer('pointerdown', { x: 100, target: document.getElementById('play') });
    expect(split()).toBe('');

    overlay.classList.add('hidden');
    pointer('pointermove', { x: 100 });
    expect(split()).toBe('');
  });

  test('does nothing without an overlay or before it has a size', () => {
    overlay.getBoundingClientRect = () => ({ left: 0, width: 0 });
    pointer('pointermove', { x: 100 });
    expect(split()).toBe('');

    document.body.innerHTML = '';
    expect(() => enableSeamDrag()).not.toThrow();
  });
});
