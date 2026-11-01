import {
  createBrickElement,
  createGhostElement,
  renderLayout,
} from '../src/brickDom.js';

const wallBrick = {
  x: 10,
  y: 20,
  width: 60,
  height: 24,
  text: 'Angular',
  kind: 'body',
  color: 0x2196f3,
  rowIndex: 3,
  colIndex: 5,
  wordIndex: 7,
};

const typeBrick = {
  x: 96,
  y: 40,
  width: 80,
  height: 19,
  text: 'PROJECTS',
  kind: 'heading',
  font: '600 11.5px Inter, sans-serif',
  letterSpacing: 1.38,
  rowIndex: 4,
  wordIndex: 2,
};

describe('brick DOM rendering', () => {
  test('createBrickElement positions a wall brick and passes its colour to CSS', () => {
    const element = createBrickElement(wallBrick);

    expect(element.className).toBe('overlay-brick brick--body');
    expect(element.textContent).toBe('Angular');
    expect(element.style.left).toBe('10px');
    expect(element.style.top).toBe('20px');
    expect(element.style.width).toBe('60px');
    expect(element.style.height).toBe('24px');
    expect(element.style.getPropertyValue('--brick-color')).toBe('#2196f3');
    expect(element.style.getPropertyValue('--row')).toBe('3');
    expect(element.style.getPropertyValue('--col')).toBe('5');
  });

  test('createBrickElement sets a typeset brick in its own type', () => {
    const element = createBrickElement(typeBrick);

    expect(element.classList.contains('brick--heading')).toBe(true);
    expect(element.style.letterSpacing).toBe('1.38px');
    expect(element.style.lineHeight).toBe('1');
    expect(element.style.getPropertyValue('--brick-color')).toBe('');
    expect(element.style.getPropertyValue('--col')).toBe('1');
  });

  test('createBrickElement works from position and text alone', () => {
    const element = createBrickElement({
      x: 0,
      y: 0,
      width: 10,
      height: 10,
      text: '',
    });

    expect(element.className).toBe('overlay-brick');
    expect(element.style.getPropertyValue('--row')).toBe('0');
  });

  test('createGhostElement keeps the word and its place, not its brick', () => {
    const ghost = createGhostElement(typeBrick);

    expect(ghost.className).toBe('brick-ghost brick--heading');
    expect(ghost.textContent).toBe('PROJECTS');
    expect(ghost.style.left).toBe('96px');
    expect(
      createGhostElement({ ...wallBrick, kind: undefined }).className
    ).toBe('brick-ghost');
  });

  test('renderLayout replaces the container and skips broken words', () => {
    const container = document.createElement('div');
    container.innerHTML = '<span>stale</span>';
    const onBrick = jest.fn();

    renderLayout(
      container,
      {
        mode: 'typeset',
        bricks: [typeBrick, { ...typeBrick, text: 'SKILLS', wordIndex: 9 }],
      },
      { onBrick, brokenWords: new Set([9]) }
    );

    expect(container.dataset.layout).toBe('typeset');
    expect(container.querySelector('span')).toBeNull();
    expect(container.querySelectorAll('.overlay-brick')).toHaveLength(1);
    expect(container.querySelector('.brick-ghost').textContent).toBe('SKILLS');
    expect(onBrick).toHaveBeenCalledTimes(1);
  });

  test('renderLayout leaves no trace of broken words on the wall', () => {
    const container = document.createElement('div');

    renderLayout(
      container,
      { mode: 'wall', bricks: [wallBrick] },
      { brokenWords: new Set([7]) }
    );
    expect(container.children).toHaveLength(0);

    renderLayout(container, { mode: 'wall', bricks: [wallBrick] });
    expect(container.querySelectorAll('.overlay-brick')).toHaveLength(1);
  });
});
