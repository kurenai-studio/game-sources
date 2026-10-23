// Entry point for the petri dish page: find the gal and level picked in the
// URL and start the game with them:
//   petri-dish.html?pal=sasha&level=2
import { antifungalsFor, placeAntifungals } from './antifungal.js';
import { GAME, LEVELS, SPECIES } from './config.js';
import { playGame } from './game.js';
import { speciesName } from './italics.js';
import { playMold } from './mold.js';
import { pageReady, watchLoading } from './loading.js';
import { scatterNutrients } from './nutrients.js';
import { dishGal, GALS } from './gals.js';
import { watchInputMode } from './touch.js';

// Show touch or arrow-key directions, whichever fits the device.
watchInputMode();
// "Growing the colony…" while the next screen loads.
watchLoading();

// Every gal's drawing, hidden: yours is shown below.
document.querySelector('.gal-mover').append(...GALS.map(dishGal));

const params = new URLSearchParams(window.location.search);
// The address still says ?pal= (and the picker is still pal-picker.html) so
// links people shared from before the pals became gals keep working.
const choice = params.get('pal');
// Compare names rather than building a CSS selector from the address, so a
// mangled link (e.g. ?pal=sasha"]) can't crash the page.
const gal = [...document.querySelectorAll('.dish-gal')].find((el) => el.dataset.gal === choice);
// Level 1 unless the URL says otherwise.
const levelNumber = Math.min(Math.max(parseInt(params.get('level'), 10) || 1, 1), LEVELS.length);
const level = LEVELS[levelNumber - 1];

if (!gal) {
  // No gal (or an unknown one) in the URL: send them back to choose.
  window.location.replace('./pal-picker.html');
} else {
  start();
  // The dish is set up: take the loading card away.
  pageReady();
}

function start() {
  gal.removeAttribute('hidden');
  document.title = `FunGals | ${gal.dataset.name} | Level ${levelNumber}`;
  const species = SPECIES[gal.dataset.gal];
  // Her name and species above the dish.
  const title = document.querySelector('.gal-name');
  title.textContent = gal.dataset.name;
  title.style.color = species.color;
  document.querySelector('.species-name').replaceChildren(...speciesName(species.scientific));
  const disks = placeAntifungals(antifungalsFor(species.antifungals, level.disks));
  // A mold plays as a spore planting colonies, with fewer nutrients (each
  // one is a whole colony) and its own directions. Nutrient flecks keep
  // clear of the disks, but can turn up under a mold's colonies, where they
  // start new ones.
  const mold = species.kind === 'mold';
  const nutrients = scatterNutrients({ avoid: disks, count: mold ? GAME.MOLD_NUTRIENTS : GAME.YEAST_NUTRIENTS });
  for (const how of document.querySelectorAll('.how-to-play')) {
    how.hidden = how.classList.contains('for-mold') !== mold;
  }
  if (mold) {
    playMold(gal, species, nutrients, disks, { level: levelNumber, target: level.colonies });
  } else {
    playGame(gal, species, nutrients, disks, { level: levelNumber, target: level.target });
  }
}
