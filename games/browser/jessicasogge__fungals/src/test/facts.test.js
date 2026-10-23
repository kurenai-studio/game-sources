// @vitest-environment jsdom
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { SPECIES } from '../public/game/config.js';
import { hideFact, pickFact, showFact, writeFact } from '../public/game/facts.js';
import { plainText } from '../public/game/italics.js';

describe('every gal\'s facts', () => {
  it.each(Object.keys(SPECIES))('%s has at least 10 short, different facts', (gal) => {
    const { facts } = SPECIES[gal];
    expect(facts.length).toBeGreaterThanOrEqual(10);
    expect(new Set(facts).size).toBe(facts.length);
    const name = gal[0].toUpperCase() + gal.slice(1);
    for (const raw of facts) {
      // Italics markers come in pairs, around at least one word.
      expect(raw.split('*').length % 2, raw).toBe(1);
      expect(raw, raw).not.toMatch(/\*\s*\*/);
      const fact = plainText(raw); // as it reads on screen
      expect(fact.length, fact).toBeLessThanOrEqual(90); // fits the pop-up
      // Says whose fact it is, so it's clear in a race against another gal.
      expect(fact, fact).toContain(name);
      expect(fact, fact).toMatch(/^["A-Z0-9].*[.!"]$/); // a full sentence
      // Commas and other punctuation instead of dashes (hyphenated words,
      // like whip-like, are fine).
      expect(fact, fact).not.toMatch(/[\u2013\u2014]|\s-\s|\d-\d/);
    }
  });
});

describe('scientific names of other species', () => {
  // Every genus our gals' facts mention by its full name.
  const GENERA = /\b(Candida|Saccharomyces|Aspergillus|Penicillium) [a-z]+/g;

  it('are in italics wherever a fact names one', () => {
    for (const [gal, { facts }] of Object.entries(SPECIES)) {
      for (const fact of facts) {
        for (const [name] of fact.matchAll(GENERA)) expect(fact, `${gal}: ${fact}`).toContain(`*${name}*`);
      }
    }
  });

  it("puts Candi's cousin in italics", () => {
    const italic = SPECIES.candi.facts.flatMap((fact) => [...fact.matchAll(/\*([^*]+)\*/g)].map((m) => m[1]));
    expect(italic.sort()).toEqual(['Candida', 'Candida auris']);
  });
});

describe('writeFact', () => {
  it('writes the parts between asterisks in italics, and the rest as plain text', () => {
    const el = document.createElement('span');
    writeFact(el, "Candi's cousin *Candida auris* resists many antifungals.");
    expect(el.textContent).toBe("Candi's cousin Candida auris resists many antifungals.");
    expect([...el.querySelectorAll('i')].map((i) => i.textContent)).toEqual(['Candida auris']);
  });

  it('copes with italics at the start or end, and with none', () => {
    const el = document.createElement('span');
    writeFact(el, '*Saccharomyces* means sugar fungus.');
    expect(el.innerHTML).toBe('<i>Saccharomyces</i> means sugar fungus.');
    writeFact(el, 'Plain words.');
    expect(el.innerHTML).toBe('Plain words.');
  });

  it('never reads a fact as HTML', () => {
    const el = document.createElement('span');
    writeFact(el, 'A <b>bold</b> *<img src=x>* fact.');
    expect(el.querySelector('b, img')).toBeNull();
    expect(el.textContent).toBe('A <b>bold</b> <img src=x> fact.');
  });
});

describe('pickFact', () => {
  const facts = ['A.', 'B.', 'C.'];

  it('picks one of the facts', () => {
    expect(facts).toContain(pickFact(facts));
  });

  it('never repeats the last one when there are others', () => {
    for (let i = 0; i < 50; i++) expect(pickFact(facts, 'B.')).not.toBe('B.');
  });

  it('can pick any fact', () => {
    expect(pickFact(facts, null, () => 0)).toBe('A.');
    expect(pickFact(facts, null, () => 0.99)).toBe('C.');
  });

  it('copes with just one fact, or none', () => {
    expect(pickFact(['Only.'], 'Only.')).toBe('Only.');
    expect(pickFact([], null)).toBeNull();
    expect(pickFact(undefined, null)).toBeNull();
  });
});

describe('the pop-up line', () => {
  beforeEach(() => {
    sessionStorage.clear();
    document.body.innerHTML =
      '<p class="fun-fact" hidden><strong>Did you know?</strong> <span class="fun-fact-text"></span></p>';
  });
  const line = () => document.querySelector('.fun-fact');

  it('shows one of the gal\'s facts', () => {
    showFact('sasha', SPECIES.sasha);
    expect(line().hidden).toBe(false);
    expect(SPECIES.sasha.facts).toContain(line().querySelector('.fun-fact-text').textContent);
  });

  it('shows the names of other species in italics, without the asterisks', () => {
    const species = { facts: ["Candi's cousin *Candida auris* was first described in 2009."] };
    showFact('candi', species);
    const text = line().querySelector('.fun-fact-text');
    expect(text.querySelector('i').textContent).toBe('Candida auris');
    expect(text.textContent).not.toContain('*');
  });

  it('shows a different fact on the next win', () => {
    for (let i = 0; i < 20; i++) {
      showFact('candi', SPECIES.candi);
      const first = line().textContent;
      showFact('candi', SPECIES.candi);
      expect(line().textContent).not.toBe(first);
    }
  });

  it('still shows a fact when the browser blocks storage (like some private windows)', () => {
    const blocked = () => {
      throw new Error('storage is blocked');
    };
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(blocked);
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(blocked);
    try {
      expect(() => showFact('sasha', SPECIES.sasha)).not.toThrow();
      expect(line().hidden).toBe(false);
      expect(SPECIES.sasha.facts).toContain(line().querySelector('.fun-fact-text').textContent);
    } finally {
      vi.restoreAllMocks();
    }
  });

  it('does nothing on a page without the fact line', () => {
    document.body.innerHTML = '';
    expect(() => showFact('sasha', SPECIES.sasha)).not.toThrow();
    expect(() => hideFact()).not.toThrow();
  });

  it('stays hidden for a gal with no facts, and hides on a game over', () => {
    showFact('nobody', {});
    expect(line().hidden).toBe(true);
    showFact('sasha', SPECIES.sasha);
    hideFact();
    expect(line().hidden).toBe(true);
  });
});
