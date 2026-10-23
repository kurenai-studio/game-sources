// @vitest-environment jsdom
// The gals' drawings (gals.js), and the pages that draw them: the home page,
// the picker and the petri dish. The pages are loaded into
// jsdom, a simulated browser page.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { SPECIES } from '../public/game/config.js';
import { plainText } from '../public/game/italics.js';
import { dishGal, HOME_GALS, homeGal, inRandomOrder, PAGE_SIZE, galById, GALS, galTile, pickerPages } from '../public/game/gals.js';

// (jsdom changes import.meta.url to a web address, so find files from the project folder.)
const file = (name) => readFileSync(resolve(process.cwd(), 'public', name), 'utf8');
const css = file('styles.css');
const IDS = GALS.map((gal) => gal.id);

// Open `page` at `search` and run `script` on it.
async function open(page, script, search = '') {
  const html = file(page);
  vi.stubGlobal('location', { search, href: `http://localhost/${page}${search}`, replace: vi.fn() });
  document.body.outerHTML = html.slice(html.indexOf('<body'), html.indexOf('</body>'));
  vi.resetModules();
  await import(`../public/${script}`);
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('the gals', () => {
  it('are the same gals as in config.js, each once', () => {
    expect([...IDS].sort()).toEqual(Object.keys(SPECIES).sort());
    expect(new Set(IDS).size).toBe(IDS.length);
  });

  it('splits into pages of eight for the picker (a tidy four-by-two), with the rest on the last page', () => {
    expect(PAGE_SIZE).toBe(8);
    const pages = pickerPages();
    expect(pages).toHaveLength(Math.ceil(GALS.length / PAGE_SIZE));
    expect(pages.flat()).toEqual(GALS);
    expect(pickerPages(['a', 'b', 'c', 'd', 'e'], 2)).toEqual([['a', 'b'], ['c', 'd'], ['e']]);
    expect(pickerPages(['a', 'b'], 2)).toEqual([['a', 'b']]);
  });

  it.each(GALS)('$id has a name and a description', (gal) => {
    expect(gal.name).toMatch(/^[A-Z][a-z]+$/);
    // Her species is in the description, so a screen reader says what she is.
    expect(gal.looks).toContain(plainText(SPECIES[gal.id].scientific).split(' ')[0]);
  });

  it.each(GALS)("$id's idle animation and tile color are in styles.css", (gal) => {
    expect(css).toMatch(new RegExp(`\\n\\.${gal.motion} \\{[^}]*animation:`));
    expect(css).toMatch(new RegExp(`\\n\\.${gal.id} \\{[^}]*background:`));
  });

  it.each(GALS)('$id is framed for every page', (gal) => {
    expect(Object.keys(gal.frames).sort()).toEqual(['dish', 'home', 'picker']);
    for (const box of Object.values(gal.frames)) {
      // x y width height, and square, since every page shows her in a square.
      const [, , w, h] = box.split(' ').map(Number);
      expect(box).toMatch(/^-?[\d.]+ -?[\d.]+ [\d.]+ [\d.]+$/);
      expect(w).toBe(h);
    }
  });

  it.each(GALS)('$id has a face', (gal) => {
    expect(galTile(gal).querySelector('.face')).not.toBeNull();
  });

  it('are found by id, and nothing else is', () => {
    expect(galById('candi').name).toBe('Candi');
    expect(galById('toString')).toBeUndefined();
    expect(galById(null)).toBeUndefined();
  });
});

describe('her drawing', () => {
  const sasha = galById('sasha');

  it('is real SVG, not just text', () => {
    const svg = homeGal(sasha);
    expect(svg.namespaceURI).toBe('http://www.w3.org/2000/svg');
    expect(svg.querySelector('ellipse').namespaceURI).toBe('http://www.w3.org/2000/svg');
  });

  it('on the home page, animates and says who she is', () => {
    const svg = homeGal(sasha);
    expect(svg.getAttribute('viewBox')).toBe(sasha.frames.home);
    expect(svg.getAttribute('class')).toBe('gal squish');
    expect(svg.getAttribute('role')).toBe('img');
    expect(svg.getAttribute('aria-label')).toBe(`Sasha, ${sasha.looks}`);
  });

  it('on a tile, has her tile color and is hidden from screen readers', () => {
    const tile = galTile(sasha);
    expect(tile.className).toBe('gal-icon sasha');
    expect(tile.firstChild.getAttribute('viewBox')).toBe(sasha.frames.picker);
    expect(tile.firstChild.getAttribute('aria-hidden')).toBe('true');
  });

  it('in the dish, starts hidden and carries her id and name', () => {
    const svg = dishGal(sasha);
    expect(svg.getAttribute('viewBox')).toBe(sasha.frames.dish);
    expect(svg.getAttribute('class')).toBe('dish-gal squish');
    expect(svg.dataset).toMatchObject({ gal: 'sasha', name: 'Sasha' });
    expect(svg.hasAttribute('hidden')).toBe(true);
  });

  it("is a mold's spore in the dish, and her whole mold everywhere else", () => {
    const fumi = galById('fumi');
    // In the dish she's one round spore, with her face.
    const spore = dishGal(fumi);
    expect(spore.querySelector('.face')).not.toBeNull();
    expect(spore.querySelectorAll('circle[r="42"]')).toHaveLength(1);
    expect(spore.querySelector('rect')).toBeNull();
    // On the picker and home page, her stalk, head and chains of spores.
    for (const svg of [galTile(fumi).firstChild, homeGal(fumi)]) {
      expect(svg.querySelector('rect')).not.toBeNull();
      expect(svg.querySelectorAll('circle[r="7"]').length).toBeGreaterThan(10);
    }
  });
});

describe('moving parts', () => {
  // A gal with a bit of SVG animation, like a wiggling hypha.
  const wiggly = { ...galById('candi'), art: '<path d="M0 0 L1 1"><animate attributeName="d" values="M0 0 L1 1;M0 0 L1 2" /></path>' };
  afterEach(() => vi.unstubAllGlobals());

  it('move on the home page and in the dish', () => {
    vi.stubGlobal('matchMedia', () => ({ matches: false }));
    expect(homeGal(wiggly).querySelector('animate')).not.toBeNull();
    expect(dishGal(wiggly).querySelector('animate')).not.toBeNull();
  });

  it('hold still on the picker', () => {
    expect(galTile(wiggly).querySelector('animate')).toBeNull();
  });

  it('hold still for anyone who prefers less motion', () => {
    vi.stubGlobal('matchMedia', (query) => ({ matches: query.includes('reduce') }));
    expect(dishGal(wiggly).querySelector('animate')).toBeNull();
  });
});

describe('inRandomOrder', () => {
  it('keeps every gal, each once, and leaves GALS as it was', () => {
    const before = [...GALS];
    const order = inRandomOrder(GALS);
    expect(order).not.toBe(GALS);
    expect([...order].sort((a, b) => a.id.localeCompare(b.id))).toEqual(
      [...GALS].sort((a, b) => a.id.localeCompare(b.id)),
    );
    expect(GALS).toEqual(before);
  });

  it('can put any gal first', () => {
    // Over many shuffles, every gal leads at least once.
    const firsts = new Set();
    for (let i = 0; i < 500; i++) firsts.add(inRandomOrder(GALS)[0].id);
    expect(firsts.size).toBe(GALS.length);
  });

  it('follows the random numbers it is given', () => {
    expect(inRandomOrder(['a', 'b', 'c'], () => 0)).toEqual(['b', 'c', 'a']);
    expect(inRandomOrder(['a', 'b', 'c'], () => 0.99)).toEqual(['a', 'b', 'c']);
  });
});

describe('the pages', () => {
  afterEach(() => {
    vi.doUnmock('../public/game/gals.js');
    vi.restoreAllMocks();
  });

  it('home shows every gal in its row, in order', async () => {
    await open('index.html', 'script.js');
    const labels = [...document.querySelectorAll('.friends svg')].map((s) => s.getAttribute('aria-label'));
    expect(labels).toEqual(HOME_GALS.map((gal) => `${gal.name}, ${gal.looks}`));
    // Every gal, each once: the yeasts with Olive in the middle, then Fumi.
    expect(HOME_GALS.map((gal) => gal.id)).toEqual(['yara', 'penelope', 'sasha', 'rosie', 'candi', 'miri', 'peachy', 'neve', 'ruby', 'maizey', 'fumi', 'olive']);
    expect([...HOME_GALS].sort((a, b) => a.id.localeCompare(b.id))).toEqual(
      [...GALS].sort((a, b) => a.id.localeCompare(b.id)));
  });

  it('the picker has a card for every gal, each once, linking to her dish', async () => {
    await open('pal-picker.html', 'game/gal-picker.js');
    const cards = [...document.querySelectorAll('.gal-card')];
    const names = cards.map((c) => c.querySelector('h2').textContent);
    expect([...names].sort()).toEqual(GALS.map((gal) => gal.name).sort());
    for (const card of cards) {
      const { id, name } = GALS.find((gal) => gal.name === card.querySelector('h2').textContent);
      expect(card.querySelector('.gal-icon').classList).toContain(id);
      expect(card.querySelector('.species').textContent).toBe(plainText(SPECIES[id].scientific));
      expect(card.querySelector('.species i')).not.toBeNull(); // in italics
      // The whole card is the link that picks her, with no separate button.
      expect(card.tagName).toBe('A');
      expect(card.getAttribute('href')).toBe(`./petri-dish.html?pal=${id}`);
      expect(card.getAttribute('aria-label')).toBe(`Pick ${name}`);
      expect(card.querySelector('a, button, .pick-btn')).toBeNull();
    }
  });

  it('the picker shuffles all the gals together, then splits them into pages', async () => {
    // With Math.random always 0, the shuffle moves the first gal to the end.
    vi.spyOn(Math, 'random').mockReturnValue(0);
    await open('pal-picker.html', 'game/gal-picker.js');
    const grids = [...document.querySelectorAll('.picker-grid')];
    const names = grids.map((grid) => [...grid.querySelectorAll('.gal-card h2')].map((h) => h.textContent));
    expect(names).toEqual(pickerPages(inRandomOrder(GALS, () => 0)).map((page) => page.map((gal) => gal.name)));
    expect(names.flat().at(-1)).toBe(GALS[0].name);
  });

  it('the picker hides the pager while every gal fits on one page', async () => {
    // Pages big enough for everyone, so there's only one.
    vi.doMock('../public/game/gals.js', async (importActual) => {
      const real = await importActual();
      return { ...real, pickerPages: (gals) => real.pickerPages(gals, gals.length) };
    });
    await open('pal-picker.html', 'game/gal-picker.js');
    expect(document.querySelectorAll('.picker-grid')).toHaveLength(1);
    expect(document.querySelector('.picker-pager').hidden).toBe(true);
  });

  it('the picker shows one page at a time, with More gals and Back buttons between them', async () => {
    // One gal to a page, so there's more than one page to go through.
    vi.doMock('../public/game/gals.js', async (importActual) => {
      const real = await importActual();
      return { ...real, pickerPages: (gals) => real.pickerPages(gals, 1) };
    });
    await open('pal-picker.html', 'game/gal-picker.js');
    const grids = [...document.querySelectorAll('.picker-grid')];
    const back = document.querySelector('.pager-back');
    const more = document.querySelector('.pager-more');
    const showing = () => grids.filter((grid) => !grid.hidden).map((grid) => grid.dataset.page);
    expect(grids).toHaveLength(GALS.length);
    expect(document.querySelector('.picker-pager').hidden).toBe(false);

    // Opens on the first page, with only More gals to press.
    expect(showing()).toEqual(['1']);
    expect(back.hidden).toBe(true);
    expect(more.hidden).toBe(false);
    expect(more.tagName).toBe('BUTTON');

    // More gals all the way to the last page.
    for (let page = 2; page <= grids.length; page++) {
      more.click();
      expect(showing()).toEqual([String(page)]);
      expect(back.hidden).toBe(false);
    }
    expect(more.hidden).toBe(true);
    expect(document.activeElement).toBe(back); // the keyboard stays on the pager
    // Back to the first page.
    for (let page = grids.length - 1; page > 1; page--) back.click();
    back.click();
    expect(showing()).toEqual(['1']);
    expect(back.hidden).toBe(true);
    expect(document.activeElement).toBe(more);
  });

  it("keeps a short page's gals in the middle, and hides pages that aren't showing", () => {
    expect(css).toMatch(/\n\.picker-grid \{[^}]*justify-content: center;/);
    expect(css).toMatch(/\n\.picker-grid\[hidden\] \{\s*display: none;/);
  });

  it("the pages don't draw any gals by hand", () => {
    for (const page of ['index.html', 'pal-picker.html', 'petri-dish.html', 'whos-that-gal.html']) {
      expect(file(page), page).not.toContain('<svg');
    }
  });
});
