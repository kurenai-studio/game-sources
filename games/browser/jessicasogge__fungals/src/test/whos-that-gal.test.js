// @vitest-environment jsdom
// Who’s That Gal? shows a fact with "this gal" in place of her name, and a button for
// every gal. No score, just tries until you find her.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { SPECIES } from '../public/game/config.js';
import { factDeck } from '../public/game/guess.js';
import { GALS } from '../public/game/gals.js';
import { QUIZ_FACTS } from '../public/game/quiz-facts.js';

const page = readFileSync(resolve(process.cwd(), 'public/whos-that-gal.html'), 'utf8');

// The same deck the page shuffles, with Math.random pinned to 0 below. The
// page deals from the end.
const deck = factDeck(GALS, QUIZ_FACTS, () => 0);
const dealt = (n) => deck[deck.length - 1 - n];

async function open() {
  document.body.outerHTML = page.slice(page.indexOf('<body'), page.indexOf('</body>'));
  vi.resetModules();
  await import('../public/game/whos-that-gal.js');
}

const button = (id) => document.querySelector(`.guess-btn[data-gal="${id}"]`);
const status = () => document.querySelector('.guess-status').textContent;
const fact = () => document.querySelector('.guess-fact');
const next = () => document.querySelector('.next-fact');
const wrong = (gal) => GALS.find((other) => other.id !== gal.id);

beforeEach(() => vi.spyOn(Math, 'random').mockReturnValue(0));
afterEach(() => vi.restoreAllMocks());

describe('Who’s That Gal?', () => {
  it('offers every gal, in order', async () => {
    await open();
    const offered = [...document.querySelectorAll('.guess-btn')].map((b) => b.dataset.gal);
    expect(offered).toEqual(GALS.map((gal) => gal.id));
    expect(document.querySelector('.loading-overlay').hidden).toBe(true);
  });

  it("shows each gal's species, shortened, under her name", async () => {
    await open();
    expect(button('candi').querySelector('.guess-species').textContent).toBe('C. albicans');
    expect(button('candi').querySelector('.guess-species i').textContent).toBe('C. albicans');
    expect(button('sasha').querySelector('.guess-species').textContent).toBe('S. cerevisiae');
    for (const gal of GALS) expect(button(gal.id).querySelector('.guess-species').textContent).toMatch(/^[A-Z]\.\s\S+$/);
  });

  it('shows a fact with "this gal" in place of her name', async () => {
    await open();
    const { gal } = dealt(0);
    expect(fact().textContent).toMatch(/\b[Tt]his gal\b/);
    expect(fact().textContent).not.toContain(gal.name);
    expect(status()).toBe('Who is this fact about? Tap her!');
    expect(next().hidden).toBe(true);
  });

  it("counts how many facts you've seen, out of all of them", async () => {
    await open();
    const counter = () => document.querySelector('.guess-counter').textContent;
    expect(counter()).toBe(`Fact 1 of ${deck.length}`);
    button(dealt(0).gal.id).click();
    expect(counter()).toBe(`Fact 1 of ${deck.length}`); // no change for finding her
    next().click();
    expect(counter()).toBe(`Fact 2 of ${deck.length}`);
  });

  it('greys out a wrong guess so you can try again', async () => {
    await open();
    const other = wrong(dealt(0).gal);
    button(other.id).click();
    expect(status()).toBe(`Not ${other.name}. Try again!`);
    expect(button(other.id).disabled).toBe(true);
    expect(next().hidden).toBe(true);
  });

  it('fills in her name and species when you find her', async () => {
    await open();
    const { gal, fact: text } = dealt(0);
    button(gal.id).click();
    expect(fact().textContent).toContain(gal.name);
    expect(fact().textContent).not.toMatch(/\b[Tt]his gal\b/);
    expect(text).toContain(gal.name);
    expect(button(gal.id).classList).toContain('right');
    expect(status()).toBe(`Yes! It's ${gal.name}, ${SPECIES[gal.id].scientific.replaceAll('*', '')}.`);
    expect(document.querySelector('.guess-status i')).not.toBeNull();
    for (const other of GALS) expect(button(other.id).disabled).toBe(other.id !== gal.id);
    expect(next().hidden).toBe(false);
    expect(document.activeElement).toBe(next());
  });

  it("doesn't keep score", async () => {
    await open();
    expect(document.body.textContent).not.toMatch(/score|points|correct/i);
  });

  it('moves on to the next fact, with every gal back', async () => {
    await open();
    const first = dealt(0).gal;
    button(wrong(first).id).click();
    button(first.id).click();
    next().click();
    const { gal } = dealt(1);
    expect(fact().textContent).not.toContain(gal.name);
    expect(status()).toBe('Who is this fact about? Tap her!');
    expect(next().hidden).toBe(true);
    for (const other of GALS) {
      expect(button(other.id).disabled).toBe(false);
      expect(button(other.id).classList).not.toContain('right');
    }
  });

  it('shuffles every fact again once they have all been shown', async () => {
    await open();
    for (let i = 0; i < deck.length; i++) {
      button(dealt(i).gal.id).click();
      next().click();
    }
    // Back to the top of a fresh deck, counting from 1 again.
    expect(document.querySelector('.guess-counter').textContent).toBe(`Fact 1 of ${deck.length}`);
    const { gal } = dealt(0);
    expect(fact().textContent).toMatch(/\b[Tt]his gal\b/);
    button(gal.id).click();
    expect(next().hidden).toBe(false);
  });
});
