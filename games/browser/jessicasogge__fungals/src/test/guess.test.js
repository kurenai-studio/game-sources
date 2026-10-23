// @vitest-environment jsdom
// Who’s That Gal? facts: shuffled into a deck, with "this gal" in place of the gal's name.
import { describe, expect, it } from 'vitest';
import { factDeck, fillBlanks, withBlanks } from '../public/game/guess.js';
import { GALS } from '../public/game/gals.js';
import { QUIZ_FACTS } from '../public/game/quiz-facts.js';

describe('the quiz facts', () => {
  // These are picked to point to one gal each, sometimes reworded from the
  // pop-up facts in config.js, so they're checked here on their own.
  it.each(GALS.map((gal) => [gal.name, gal.id]))('%s has quiz facts that each name her', (name, id) => {
    const facts = QUIZ_FACTS[id];
    expect(facts.length).toBeGreaterThan(0);
    expect(new Set(facts).size).toBe(facts.length);
    for (const fact of facts) {
      // Says whose it is, so "this gal" can take her name's place.
      expect(fact, fact).toMatch(new RegExp(`\\b${name}\\b`));
      expect(fact.split('*').length % 2, fact).toBe(1); // italics come in pairs
      expect(fact.replaceAll('*', ''), fact).toMatch(/^["A-Z0-9].*[.!"]$/); // a full sentence
    }
  });

  it('covers every gal in the game, and only them', () => {
    expect(Object.keys(QUIZ_FACTS).sort()).toEqual(GALS.map((gal) => gal.id).sort());
  });
});

describe('the deck of facts', () => {
  it('has every quiz fact about every gal, once each', () => {
    const deck = factDeck(GALS, QUIZ_FACTS);
    const all = GALS.flatMap((gal) => QUIZ_FACTS[gal.id].map((fact) => `${gal.id}: ${fact}`));
    expect(deck.map(({ gal, fact }) => `${gal.id}: ${fact}`).sort()).toEqual(all.sort());
  });

  it('is shuffled', () => {
    const order = (random) => factDeck(GALS, QUIZ_FACTS, random).map(({ fact }) => fact);
    expect(order(() => 0)).not.toEqual(order(() => 0.999));
  });
});

describe('swapping her name for "this gal"', () => {
  const shown = (fact, name) => {
    const p = document.createElement('p');
    p.append(...withBlanks(fact, name));
    return p;
  };

  it('swaps every mention of her, possessives too', () => {
    expect(shown("Candi's cells switch shapes, so Candi can spread.", 'Candi').textContent)
      .toBe("This gal's cells switch shapes, so this gal can spread.");
  });

  it('starts every sentence with a capital', () => {
    expect(shown('Sasha buds. Sasha bakes! "Sasha" is a name.', 'Sasha').textContent)
      .toBe('This gal buds. This gal bakes! "This gal" is a name.');
    expect(shown('In bread dough, Sasha makes bubbles.', 'Sasha').textContent)
      .toBe('In bread dough, this gal makes bubbles.');
  });

  it('is plain text, with no question mark', () => {
    const p = shown('Sasha buds.', 'Sasha');
    expect(p.querySelector('.fact-blank').textContent).toBe('This gal');
    expect(p.textContent).not.toContain('?');
  });

  it('only swaps whole words', () => {
    expect(shown('Candi is a Candida, and so is Candi\'s cousin.', 'Candi').textContent)
      .toBe("This gal is a Candida, and so is this gal's cousin.");
  });

  it('says "strains of this gal", not "this gal strains"', () => {
    expect(shown('Some Candi strains resist fluconazole, unlike most Sasha cells.', 'Candi').textContent)
      .toBe('Some strains of this gal resist fluconazole, unlike most Sasha cells.');
    expect(shown('Labs grow the Sasha types they need.', 'Sasha').textContent)
      .toBe('Labs grow the types of this gal they need.');
  });

  it('keeps other species in italics', () => {
    const p = shown("Candi's cousin *Candida auris* resists many drugs. Candi doesn't.", 'Candi');
    expect(p.textContent).toBe("This gal's cousin Candida auris resists many drugs. This gal doesn't.");
    expect(p.querySelector('i').textContent).toBe('Candida auris');
  });

  it.each(GALS.map((gal) => [gal.name, gal.id]))("never gives %s's name away", (name, id) => {
    for (const fact of QUIZ_FACTS[id]) {
      const text = shown(fact, name).textContent;
      expect(text, fact).not.toMatch(new RegExp(`\\b${name}\\b`));
      expect(text, fact).toMatch(/\b[Tt]his gal\b/);
      expect(text, fact).not.toMatch(/\bthis gal (strains|cells|types)\b/);
      expect(text, fact).toMatch(/^["A-Z0-9]/);
    }
  });
});

describe('filling the blanks', () => {
  it('puts her name in every blank, in her color', () => {
    const p = document.createElement('p');
    p.append(...withBlanks("Sasha's bubbles help Sasha bake.", 'Sasha'));
    fillBlanks(p, 'Sasha', '#15803d');
    expect(p.textContent).toBe("Sasha's bubbles help Sasha bake.");
    for (const gap of p.querySelectorAll('.fact-blank')) {
      expect(gap.classList).toContain('filled');
      expect(gap.style.color).toBe('rgb(21, 128, 61)');
    }
  });
});
