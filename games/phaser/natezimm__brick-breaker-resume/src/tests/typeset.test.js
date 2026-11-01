import { classifyElements } from '../src/brickLayout.js';
import {
  fitTypeset,
  getTypesetFontSpecs,
  layoutTypeset,
} from '../src/typeset.js';

// Every character is half its font size wide, so widths are easy to reason about.
const measure = (text, font) => {
  const size = parseFloat(/([\d.]+)px/.exec(font)[1]);
  return text.length * size * 0.5;
};

const resume = classifyElements([
  { tag: 'p', text: 'Nathan Zimmerman' },
  { tag: 'p', text: 'Raritan, NJ' },
  { tag: 'p', text: 'nathanzimmerman.com' },
  { tag: 'p', text: 'WORK HISTORY' },
  { tag: 'p', text: 'Software Engineer II, Nelnet\t10/2023 – Present' },
  { tag: 'li', text: 'Built core features for a billing platform.' },
  { tag: 'li', text: 'Designed enrollment workflows.' },
  { tag: 'p', text: 'SKILLS' },
  { tag: 'p', text: 'C#, .NET, Angular' },
]);

const wide = { width: 1200, height: 900, measure };
const narrow = { width: 360, height: 900, measure };

describe('typeset layout', () => {
  test('sets each part of the résumé in its own style, top to bottom', () => {
    const { bricks, totalRows, truncated } = layoutTypeset(resume, wide);

    expect(truncated).toBe(false);
    expect(bricks[0]).toMatchObject({ text: 'Nathan', kind: 'name' });
    const words = bricks.filter((brick) => typeof brick.wordIndex === 'number');
    expect(words.map((brick) => brick.wordIndex)).toEqual(
      words.map((_, index) => index)
    );

    const kinds = [...new Set(bricks.map((brick) => brick.kind))];
    expect(kinds).toEqual([
      'name',
      'contact',
      'rule',
      'heading',
      'role',
      'date',
      'dot',
      'bullet',
      'body',
    ]);

    const name = bricks.find((brick) => brick.kind === 'name');
    const body = bricks.find((brick) => brick.kind === 'body');
    expect(name.height).toBeGreaterThan(body.height);
    expect(name.font).toContain('Newsreader');
    expect(bricks.find((brick) => brick.kind === 'heading').letterSpacing).toBe(
      1.38
    );

    expect(totalRows).toBe(bricks[bricks.length - 1].rowIndex + 1);

    const ys = bricks.map((brick) => brick.y);
    expect([...ys].sort((a, b) => a - b)).toEqual(ys);
  });

  test('contact details share one line and dates sit at the right margin', () => {
    const { bricks } = layoutTypeset(resume, wide);

    const contact = bricks.filter((brick) => brick.kind === 'contact');
    expect(new Set(contact.map((brick) => brick.rowIndex)).size).toBe(1);

    const role = bricks.filter((brick) => brick.kind === 'role');
    const date = bricks.filter((brick) => brick.kind === 'date');
    expect(date[0].rowIndex).toBe(role[0].rowIndex);

    const lastDate = date[date.length - 1];
    const rightMargin = 1200 - 1200 * 0.06;
    expect(lastDate.x + lastDate.width).toBeCloseTo(rightMargin + 2, 1);
    expect(lastDate.isLastInRow).toBe(true);
    expect(role[role.length - 1].isLastInRow).toBe(false);
  });

  test('on a narrow column the date drops below the title and text wraps', () => {
    const { bricks } = layoutTypeset(resume, narrow);

    const role = bricks.filter((brick) => brick.kind === 'role');
    const date = bricks.filter((brick) => brick.kind === 'date');
    expect(date[0].rowIndex).toBeGreaterThan(role[role.length - 1].rowIndex);
    expect(date[0].x).toBeCloseTo(360 * 0.06 - 2, 1);

    const bullets = bricks.filter((brick) => brick.kind === 'bullet');
    expect(
      new Set(bullets.map((brick) => brick.rowIndex)).size
    ).toBeGreaterThan(2);
    bricks.forEach((brick) => {
      expect(brick.x + brick.width).toBeLessThanOrEqual(360);
    });
  });

  test('stops at the play area and still numbers the words it left out', () => {
    const { bricks, truncated } = layoutTypeset(resume, {
      width: 360,
      height: 240,
      measure,
    });

    expect(truncated).toBe(true);
    expect(bricks.length).toBeGreaterThan(0);
    bricks.forEach((brick) => {
      expect(brick.y + brick.height).toBeLessThanOrEqual(240 * 0.75);
    });

    const full = layoutTypeset(resume, narrow);
    const lastShown = bricks[bricks.length - 1];
    expect(typeof lastShown.wordIndex).toBe('number');
    expect(
      full.bricks.find((brick) => brick.wordIndex === lastShown.wordIndex).text
    ).toBe(lastShown.text);
  });

  test('the rule under the contact line is a row of thin bricks in play', () => {
    const { bricks } = layoutTypeset(resume, wide);
    const rule = bricks.filter((brick) => brick.kind === 'rule');
    const contact = bricks.filter((brick) => brick.kind === 'contact');
    const heading = bricks.find((brick) => brick.kind === 'heading');

    // 1200 wide leaves a 1056px column: ten pieces of about 110px.
    expect(rule).toHaveLength(10);
    expect(rule.map((brick) => brick.wordIndex)).toEqual(
      rule.map((_, piece) => `rule-${piece}`)
    );
    expect(rule[0].x).toBeCloseTo(1200 * 0.06, 5);
    expect(rule[9].x + rule[9].width).toBeCloseTo(1200 - 1200 * 0.06, 5);
    expect(rule[1].x - (rule[0].x + rule[0].width)).toBeCloseTo(2, 5);
    expect(rule[9].isLastInRow).toBe(true);

    // It has a row of its own, between the contact line and the first heading.
    expect(rule[0].rowIndex).toBe(contact[0].rowIndex + 1);
    expect(heading.rowIndex).toBe(rule[0].rowIndex + 1);
    expect(rule[0].y).toBeGreaterThan(contact[0].y + contact[0].height);
    expect(heading.y).toBeGreaterThan(rule[0].y + rule[0].height);
  });

  test('each bullet dot is a small brick ahead of its text', () => {
    const { bricks } = layoutTypeset(resume, wide);
    const dots = bricks.filter((brick) => brick.kind === 'dot');
    const bullets = bricks.filter((brick) => brick.kind === 'bullet');

    expect(dots.map((brick) => brick.wordIndex)).toEqual(['dot-0', 'dot-1']);
    expect(dots.every((brick) => brick.text === '•')).toBe(true);

    // The dot shares the first line of its bullet and stops short of the text.
    expect(dots[0].rowIndex).toBe(bullets[0].rowIndex);
    expect(dots[0].y).toBe(bullets[0].y);
    expect(dots[0].x).toBeCloseTo(1200 * 0.06, 5);
    expect(dots[0].x + dots[0].width).toBeLessThanOrEqual(bullets[0].x);
    expect(dots[0].font).toBe(bullets[0].font);
    expect(dots[1].y).toBeGreaterThan(dots[0].y);
  });

  test('a bullet below the play area gets no dot', () => {
    const heights = Array.from({ length: 120 }, (_, step) => 200 + step * 2);
    const cut = heights
      .map((height) => layoutTypeset(resume, { width: 1200, height, measure }))
      .find(
        (layout) =>
          layout.bricks.filter((brick) => brick.kind === 'dot').length === 1
      );

    expect(cut.truncated).toBe(true);
    expect(cut.bricks.find((brick) => brick.kind === 'dot').wordIndex).toBe(
      'dot-0'
    );
  });

  test('a rule with no room is left out', () => {
    const { bricks } = layoutTypeset(resume, {
      width: 1200,
      height: 130,
      measure,
    });

    expect(bricks.some((brick) => brick.kind === 'contact')).toBe(true);
    expect(bricks.some((brick) => brick.kind === 'rule')).toBe(false);
  });

  test('handles a résumé with no contact line or dates', () => {
    const { bricks } = layoutTypeset(
      classifyElements([
        { tag: 'p', text: 'Nathan Zimmerman' },
        { tag: 'p', text: 'PROJECTS' },
        { tag: 'p', text: 'Staff Engineer\t' },
        { tag: 'p', text: 'SKILLS' },
      ]),
      wide
    );

    expect(bricks.some((brick) => brick.kind === 'rule')).toBe(false);
    expect(bricks.some((brick) => brick.kind === 'dot')).toBe(false);
    expect(bricks.some((brick) => brick.kind === 'date')).toBe(false);
    expect(bricks.filter((brick) => brick.kind === 'heading')).toHaveLength(2);
  });

  test('fitTypeset shrinks the type on a wide screen until the page fits', () => {
    const tall = { width: 1200, height: 280, measure };
    const atFullSize = layoutTypeset(resume, tall);
    const fitted = fitTypeset(resume, tall);

    expect(atFullSize.truncated).toBe(true);
    expect(fitted.truncated).toBe(false);
    expect(fitted.scale).toBeLessThan(1);
    expect(fitted.bricks).toHaveLength(
      layoutTypeset(resume, wide).bricks.length
    );
  });

  test('fitTypeset never shrinks the type on a narrow screen', () => {
    const fitted = fitTypeset(resume, { width: 360, height: 240, measure });

    expect(fitted.scale).toBe(1);
    expect(fitted.truncated).toBe(true);
  });

  test('lists the font faces to load before measuring', () => {
    const specs = getTypesetFontSpecs();

    expect(specs).toHaveLength(3);
    expect(specs.some((spec) => spec.startsWith('italic'))).toBe(true);
  });
});
