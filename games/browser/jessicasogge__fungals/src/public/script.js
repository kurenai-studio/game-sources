// The home page: the row of gals, and the "Press Start to Play" button.
import { HOME_GALS, homeGal } from './game/gals.js';
import { goTo, watchLoading } from './game/loading.js';

// "Growing the colony…" while the next screen loads.
watchLoading();

const friends = document.querySelector('.friends');
friends?.append(...HOME_GALS.map(homeGal));

const startButton = document.querySelector('.start-btn');

if (startButton) {
  const label = startButton.textContent;

  startButton.addEventListener('click', () => {
    startButton.textContent = 'Opening picker...';
    startButton.disabled = true;

    setTimeout(() => {
      goTo('./pal-picker.html');
    }, 250);
  });

  // When you come back with the browser's Back button, the browser may show
  // this page exactly as it was left, still saying "Opening picker...".
  // Put the button back the way it started.
  window.addEventListener('pageshow', () => {
    startButton.textContent = label;
    startButton.disabled = false;
  });
}
