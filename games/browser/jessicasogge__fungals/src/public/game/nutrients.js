// Nutrient flecks: scattered over the agar, picked up when the gal or any of
// her offspring touches one, and replaced somewhere else a few seconds later.
// `avoid` lists areas to keep clear, like the antifungal disks, each as
// { fx, fy, r } in fractions of the dish radius. `count` is how many flecks
// are on the agar at a time.
export function scatterNutrients({ avoid = [], count = 10 } = {}) {
  const agar = document.querySelector('.agar');
  const COUNT = count;
  const RESPAWN_MS = 3000;
  const MIN_GAP = 0.12; // keep flecks from clumping, as a fraction of the radius

  // Positions are stored relative to the dish center, as fractions of the dish
  // radius (-1 to 1), so they stay put when the window is resized.
  const flecks = [];
  let stopped = false;

  const RETRY_MS = 500;
  // The strict gap is wider than any zone of inhibition; the relaxed one
  // isn't, so then a disk's zone (as wide as it will get) is added in.
  const zoneOf = (a, strict) => (strict ? 0 : (a.fullZone ?? a.zone ?? 0));

  // Pick a fleck spot away from the gal, other flecks, and `avoid`.
  // If crowded, only clear `avoid`; return null if no spot is found.
  function randomSpot(avoidX, avoidY) {
    for (const strict of [true, false]) {
      const gap = strict ? MIN_GAP : 0.01;
      for (let tries = 0; tries < 100; tries++) {
        // Uniform over the disk, kept away from the rim.
        const angle = Math.random() * Math.PI * 2;
        const distance = Math.sqrt(Math.random()) * 0.82;
        const fx = Math.cos(angle) * distance;
        const fy = Math.sin(angle) * distance;
        const clearOfGal = !strict || Math.hypot(fx - avoidX, fy - avoidY) > 0.3;
        const clearOfOthers = flecks.every((f) => Math.hypot(fx - f.fx, fy - f.fy) > (strict ? MIN_GAP : 0.05));
        const clearOfHazards = avoid.every((a) => Math.hypot(fx - a.fx, fy - a.fy) > a.r + gap + zoneOf(a, strict));
        if (clearOfGal && clearOfOthers && clearOfHazards) return { fx, fy };
      }
    }
    return null;
  }

  // Add a fleck, so there are always COUNT of them. If there's no room for
  // it right now, try again in a moment rather than losing it.
  function addFleck(avoidX, avoidY) {
    if (stopped) return;
    const spot = randomSpot(avoidX, avoidY);
    if (!spot) {
      setTimeout(() => addFleck(avoidX, avoidY), RETRY_MS);
      return;
    }
    const el = document.createElement('span');
    el.className = 'nutrient';
    // Its radius as a fraction of the dish radius, matching the CSS widths.
    const small = Math.random() < 0.4;
    if (small) el.classList.add('small');
    // A random color of the rainbow for each fleck.
    el.style.setProperty('--hue', Math.floor(Math.random() * 360));
    el.style.left = `${50 + spot.fx * 50}%`;
    el.style.top = `${50 + spot.fy * 50}%`;
    el.setAttribute('aria-hidden', 'true');
    agar.appendChild(el);
    flecks.push({ el, ...spot, r: small ? 0.015 : 0.022 });
  }

  // Gals start in the middle, so the first batch avoids the center.
  for (let i = 0; i < COUNT; i++) addFleck(0, 0);

  return {
    // Pick up every fleck touching a circle of radius `reach` at the given
    // spot (all values are fractions of the dish radius). Returns how many
    // were picked up. `eaten(fx, fy)` is called with where each one was.
    eatNear(bx, by, reach, eaten = () => {}) {
      let count = 0;
      for (let i = flecks.length - 1; i >= 0; i--) {
        const fleck = flecks[i];
        if (Math.hypot(fleck.fx - bx, fleck.fy - by) > reach + fleck.r) continue;
        flecks.splice(i, 1);
        fleck.el.classList.add('eaten');
        fleck.el.addEventListener('transitionend', () => fleck.el.remove(), { once: true });
        setTimeout(() => addFleck(bx, by), RESPAWN_MS);
        eaten(fleck.fx, fleck.fy);
        count++;
      }
      return count;
    },
    // Where every fleck is, as { fx, fy } in fractions of the dish radius.
    positions() {
      return flecks.map(({ fx, fy }) => ({ fx, fy }));
    },
    // No more new flecks once the game is over.
    stop() {
      stopped = true;
    },
  };
}
