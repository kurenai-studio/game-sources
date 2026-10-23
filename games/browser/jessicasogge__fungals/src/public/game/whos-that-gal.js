// Who’s That Gal?: a quiz to tell which gal a fun fact is about. No score,
// just tries until you find her.
import { SPECIES } from './config.js';
import { factDeck, fillBlanks, withBlanks } from './guess.js';
import { shortSpeciesName, speciesName } from './italics.js';
import { pageReady, watchLoading } from './loading.js';
import { GALS, galTile } from './gals.js';
import { QUIZ_FACTS } from './quiz-facts.js';

// "Growing the colony…" while the next screen loads.
watchLoading();

const factEl = document.querySelector('.guess-fact');
const status = document.querySelector('.guess-status');
const next = document.querySelector('.next-fact');
const ASK = 'Who is this fact about? Tap her!';

// Every gal, in the same order every time, so it's easy to find her again.
const buttons = GALS.map((gal) => {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'gal-btn guess-btn';
  button.dataset.gal = gal.id;
  const name = document.createElement('span');
  name.textContent = gal.name;
  name.style.color = SPECIES[gal.id].color;
  // Her species, shortened (C. albicans), so facts about it can help too.
  const species = document.createElement('span');
  species.className = 'guess-species';
  species.append(...shortSpeciesName(SPECIES[gal.id].scientific));
  button.append(galTile(gal), name, species);
  button.addEventListener('click', () => guess(gal, button));
  return button;
});
document.querySelector('.guess-grid').append(...buttons);

const counter = document.querySelector('.guess-counter');
let deck = [];
let total = 0;
let current = null;

function showNext() {
  // Through every fact once, then shuffle them all again and count from 1.
  if (deck.length === 0) {
    deck = factDeck(GALS, QUIZ_FACTS);
    total = deck.length;
  }
  current = deck.pop();
  // How far through the facts you are (Fact 2 of 16), not a score.
  counter.textContent = `Fact ${total - deck.length} of ${total}`;
  factEl.replaceChildren(...withBlanks(current.fact, current.gal.name));
  status.textContent = ASK;
  next.hidden = true;
  for (const button of buttons) {
    button.disabled = false;
    button.classList.remove('right');
  }
}

function guess(gal, button) {
  if (gal.id !== current.gal.id) {
    status.textContent = `Not ${gal.name}. Try again!`;
    button.disabled = true;
    return;
  }
  fillBlanks(factEl, gal.name, SPECIES[gal.id].color);
  button.classList.add('right');
  for (const other of buttons) other.disabled = other !== button;
  status.replaceChildren(`Yes! It's ${gal.name}, `, ...speciesName(SPECIES[gal.id].scientific), '.');
  next.hidden = false;
  next.focus();
}

next.addEventListener('click', showNext);
showNext();

// All filled in: take the loading card away.
pageReady();
