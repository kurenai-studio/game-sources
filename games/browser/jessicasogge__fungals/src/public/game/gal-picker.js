// The gal picker: a card for each gal, with her picture, name and species;
// the whole card is the button that picks her. All the gals are shuffled into a new random
// order every visit, so no gal is always first or always on a later page,
// then split into pages of eight (PAGE_SIZE in gals.js), shown one at a time
// with Back and More gals buttons to move between them.
import { SPECIES } from './config.js';
import { speciesName } from './italics.js';
import { pageReady, watchLoading } from './loading.js';
import { inRandomOrder, GALS, galTile, pickerPages } from './gals.js';

// "Growing the colony…" while the next screen loads.
watchLoading();

// Every page is made up front and the ones not showing are hidden, so a page
// you come back to looks the same as when you left it.
const pages = pickerPages(inRandomOrder(GALS)).map((gals, i) => {
  const grid = document.createElement('div');
  grid.className = 'picker-grid';
  grid.dataset.page = String(i + 1);
  grid.append(...gals.map(card));
  return grid;
});
document.querySelector('.picker-pages').append(...pages);

const back = document.querySelector('.pager-back');
const more = document.querySelector('.pager-more');
let current = 0;

function showPage(index) {
  current = index;
  pages.forEach((grid, i) => {
    grid.hidden = i !== index;
  });
  back.hidden = index === 0;
  more.hidden = index === pages.length - 1;
  // With only one page there's nothing to page through.
  document.querySelector('.picker-pager').hidden = pages.length < 2;
}

back.addEventListener('click', () => {
  showPage(current - 1);
  // The Back button is gone on the first page, so keep the keyboard nearby.
  if (back.hidden) more.focus();
});
more.addEventListener('click', () => {
  showPage(current + 1);
  if (more.hidden) back.focus();
});
showPage(0);

function card(gal) {
  const link = document.createElement('a');
  link.className = 'gal-card';
  link.href = `./petri-dish.html?pal=${gal.id}`;
  link.setAttribute('aria-label', `Pick ${gal.name}`);

  const name = document.createElement('h2');
  name.textContent = gal.name;

  const species = document.createElement('p');
  species.className = 'species';
  species.append(...speciesName(SPECIES[gal.id].scientific));

  link.append(galTile(gal), name, species);
  return link;
}

// All filled in: take the loading card away.
pageReady();
