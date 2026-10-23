// Who’s That Gal? (whos-that-gal.html): fun facts from quiz-facts.js

import { withItalics } from './italics.js';

// Shuffled { gal, fact } pairs
export function factDeck(gals, facts, random = Math.random) {
  const deck = gals.flatMap((gal) => facts[gal.id].map((fact) => ({ gal, fact })));
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return deck;
}

// Placeholder for the gal's name
function blank(startsSentence) {
  const gap = document.createElement('span');
  gap.className = 'fact-blank';
  gap.textContent = startsSentence ? 'This gal' : 'this gal';
  return gap;
}

const SENTENCE_END = /(^|[.!?]["”]?\s+)["“]?$/;

// Format fact text with name blanks and italics
export function withBlanks(fact, name) {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const word = new RegExp(`\\b${escaped}\\b`);
  // Her name used as a describing word reads oddly as "this gal": "some
  // Candi strains" becomes "some strains of this gal", not "some this gal
  // strains".
  const reworded = fact.replace(new RegExp(`\\b${escaped} (strains|cells|types)\\b`, 'g'), `$1 of ${name}`);
  let before = ''; // the fact so far, to tell when a sentence starts
  return withItalics(reworded).flatMap((node) => {
    if (node.nodeType !== Node.TEXT_NODE) {
      before += node.textContent;
      return [node];
    }
    const nodes = [];
    node.textContent.split(word).forEach((part, i) => {
      if (i > 0) nodes.push(blank(SENTENCE_END.test(before)));
      if (part) nodes.push(document.createTextNode(part));
      before += (i > 0 ? name : '') + part;
    });
    return nodes;
  });
}

export function fillBlanks(element, name, color) {
  for (const gap of element.querySelectorAll('.fact-blank')) {
    gap.classList.add('filled');
    gap.style.color = color;
    gap.textContent = name;
  }
}
