// Fumi (Aspergillus fumigatus): guide her spore to nutrients to start colonies.
// Colonies count immediately, spread in circles, and turn green as they sporulate.
// Start enough to win; disks/zones pop colonies and end the game on spore contact.
import { spreadZones, touchedDisk, touchesDisk, touchMessage } from './antifungal.js';
import { levelBanner } from './banner.js';
import { showPop } from './colony.js';
import { GAME, LEVELS } from './config.js';
import { showFact } from './facts.js';
import { arrowKeys } from './keyboard.js';
import { keepInDish } from './physics.js';
import { sporeBurst } from './spores.js';
import { steer, touchSteering } from './touch.js';
import { track } from './track.js';

// Colony radius after `seconds`, in dish radii; grows steadily to full size.
export function colonyRadius(seconds) {
  const t = Math.min(1, Math.max(0, seconds / GAME.COLONY_GROW_SECONDS));
  return GAME.COLONY_START + (GAME.COLONY_FULL - GAME.COLONY_START) * t;
}

// Colonies: `layer` draws them; `nutrients` seed new ones, even underneath.
// `colors` are the gal's palette; `spores` colors their centers.
// With `drops` (Ruby), each colony beads with red drops, one at a time, as
// it ripens. With `wrinkled` (Rosie), each colony gets wrinkly folds as it
// darkens (styles.css). Positions and sizes use fractions of the dish radius.
export const DROPS = [
  // Where each drop sits on the colony (percent across and down), and how
  // ripe the colony is when it appears.
  { x: 50, y: 35, at: 0.4 },
  { x: 63, y: 59, at: 0.65 },
  { x: 37, y: 59, at: 0.9 },
];

export function moldColonies({ layer, disks = [], nutrients, colors, drops = false, wrinkled = false }) {
  const colonies = [];

  function draw(colony) {
    const { el, fx, fy, r } = colony;
    el.style.left = `${50 + fx * 50}%`;
    el.style.top = `${50 + fy * 50}%`;
    el.style.width = `${r * 100}%`;
    // The greenish, sporing middle spreads out a little as it grows; the
    // rest stays white and fluffy.
    const ripe = Math.min(1, colony.age / GAME.COLONY_GROW_SECONDS);
    el.style.setProperty('--ripe', `${Math.round(ripe * 40)}%`);
    for (const drop of colony.drops) drop.el.classList.toggle('shown', ripe >= drop.at);
  }

  function remove(colony) {
    colonies.splice(colonies.indexOf(colony), 1);
  }

  const api = {
    colonies,
    // How many colonies there are: each counts as soon as it starts.
    count: () => colonies.length,

    // A spore germinates at (fx, fy) and starts a colony, even on top of
    // another one. Returns the new colony.
    plant(fx, fy) {
      const el = document.createElement('div');
      el.className = wrinkled ? 'colony wrinkled' : 'colony';
      el.setAttribute('aria-hidden', 'true');
      el.style.setProperty('--spores', colors.spores);
      // A slightly uneven edge, different for each colony.
      const wobble = () => `${47 + Math.random() * 6}%`;
      el.style.borderRadius =
        `${wobble()} ${wobble()} ${wobble()} ${wobble()} / ${wobble()} ${wobble()} ${wobble()} ${wobble()}`;
      const colony = { fx, fy, r: colonyRadius(0), age: 0, el, drops: [] };
      if (drops) {
        // Each colony's drops sit at their own turn around its middle.
        const turn = Math.random() * Math.PI * 2;
        const [cos, sin] = [Math.cos(turn), Math.sin(turn)];
        for (const { x, y, at } of DROPS) {
          const drop = document.createElement('span');
          drop.className = 'drop';
          drop.style.left = `${(50 + (x - 50) * cos - (y - 50) * sin).toFixed(1)}%`;
          drop.style.top = `${(50 + (x - 50) * sin + (y - 50) * cos).toFixed(1)}%`;
          drop.style.background = colors.drop;
          el.appendChild(drop);
          colony.drops.push({ el: drop, at });
        }
      }
      draw(colony);
      layer.appendChild(el);
      colonies.push(colony);
      return colony;
    },

    // Spread every colony for `seconds`. A full-size colony stays that size.
    // A nutrient fleck a colony reaches isn't wasted: it starts a new colony
    // centered exactly where the fleck was.
    grow(seconds) {
      for (const colony of [...colonies]) {
        if (colony.age < GAME.COLONY_GROW_SECONDS) {
          colony.age += seconds;
          colony.r = colonyRadius(colony.age);
          draw(colony);
        }
        nutrients.eatNear(colony.fx, colony.fy, colony.r, api.plant);
      }
    },

    // Any colony touching an antifungal disk or its zone dies: the whole
    // colony pops at once. `radius` is the dish radius in px, for the pop. Returns
    // how many died.
    killInZones(radius) {
      let died = 0;
      for (const colony of [...colonies]) {
        const circle = [colony.fx, colony.fy, colony.r];
        if (!disks.some((disk) => touchesDisk(disk, [circle], 1))) continue;
        remove(colony);
        died++;
        showPop(layer.parentElement, circle.map((v) => v * radius), colors.stroke);
        colony.el.classList.add('dying');
        const gone = () => colony.el.remove();
        colony.el.addEventListener('animationend', gone);
        setTimeout(gone, 1000); // in case the animation never runs
      }
      return died;
    },
  };
  return api;
}

// The player's spore: one little round cell, steered like any gal.
export function sporeGroup({ mover, agar }) {
  const spore = {
    mover,
    x: 0,
    y: 0,
    facing: 1,
    // Her circle, [x, y, r] in px from the dish center. The drawing's spikes
    // poke out a little past her round body, so she's a bit smaller than it.
    body: () => [[spore.x, spore.y, (mover.offsetWidth / 2) * 0.85]],
    // Keep her in the dish and move her drawing to where she is.
    place() {
      [spore.x, spore.y] = keepInDish(agar, spore.x, spore.y, mover.offsetWidth / 2);
      mover.style.transform = `translate(${spore.x}px, ${spore.y}px) scaleX(${spore.facing})`;
    },
  };
  return spore;
}

// "1 colony", "3 colonies".
const colonyCount = (n) => `${n} ${n === 1 ? 'colony' : 'colonies'}`;

// The mold game loop: like the yeast game (game.js), but you plant colonies
// instead of budding, and `target` is how many colonies win the level.
export function playMold(galEl, species, nutrients, disks, { level = 1, target = LEVELS[0].colonies } = {}) {
  const agar = document.querySelector('.agar');
  const counter = document.querySelector('.cell-count');
  const dishRadius = () => agar.clientWidth / 2;

  const playerMover = document.querySelector('.gal-mover');
  playerMover.classList.add('player', 'spore');
  const spore = sporeGroup({ mover: playerMover, agar });

  // The colonies grow on their own layer, under the spore and the disks,
  // clipped to the round dish so one by the rim doesn't spill over it.
  const layer = document.createElement('div');
  layer.className = 'colonies';
  agar.prepend(layer);
  const colonies = moldColonies({
    layer, disks, nutrients, colors: species.colors,
    drops: Boolean(species.drops), wrinkled: Boolean(species.wrinkled),
  });

  let finished = false;
  let lastTime = null;
  let elapsed = 0; // for how far the zones have spread, as in game.js
  const keys = arrowKeys();
  const touch = touchSteering(agar, agar.closest('.petri-dish') ?? agar);
  const banner = levelBanner(level);

  function updateCounter() {
    const shown = Math.min(colonies.count(), target);
    counter.textContent = `Level ${level} · ${shown} / ${colonyCount(target)}`;
  }

  function stop() {
    finished = true;
    keys.stop();
    touch.stop();
    nutrients.stop();
  }

  function step(time) {
    const seconds = lastTime === null ? 0 : Math.min(0.05, (time - lastTime) / 1000);
    lastTime = time;
    const radius = dishRadius();

    if (!finished) {
      elapsed += seconds;
      spreadZones(disks, elapsed);
      steer(spore, keys.direction(), touch.target(), GAME.SPORE_SPEED * radius * seconds,
        GAME.ARRIVE * radius, touch.drag(), GAME.DRAG_SPEED * radius * seconds);
      spore.place();

      const hit = touchedDisk(disks, spore.body(), radius);
      if (hit) {
        stop();
        playerMover.classList.add('killed');
        setTimeout(() => showGameOver(hit), 500);
      } else {
        // Landing on a nutrient: one of her spores germinates there, and the
        // colony grows out from exactly where the fleck was.
        const [[x, y, r]] = spore.body();
        nutrients.eatNear(x / radius, y / radius, r / radius, colonies.plant);
        colonies.killInZones(radius);
        if (colonies.count() >= target) {
          stop();
          sporeBurst(playerMover, { big: level === LEVELS.length });
          setTimeout(showWin, 400);
        }
      }
      updateCounter();
    }
    // Colonies keep spreading, even after the level ends.
    colonies.grow(seconds);

    requestAnimationFrame(step);
  }

  function showWin() {
    const name = galEl.dataset.name;
    const gal = galEl.dataset.gal;
    track(`level-complete/${gal}/level-${level}`, `${name} finished level ${level}`);
    if (level === LEVELS.length) track(`won-all-levels/${gal}`, `${name} beat every level`);
    showFact(gal, species);
    if (level < LEVELS.length) {
      banner.show(`Level ${level} complete!`, `You grew ${colonyCount(target)}!`,
        `Play level ${level + 1}`, { next: level + 1 });
    } else {
      banner.show('You won!', `You beat all ${LEVELS.length} levels with ${colonyCount(target)}!`,
        'Play again', { next: 1 });
    }
  }

  function showGameOver(disk) {
    showFact(galEl.dataset.gal, species);
    const { code, name } = disk.antifungal;
    track(`game-over/${galEl.dataset.gal}/level-${level}/${code}`,
      `${galEl.dataset.name} hit ${name} on level ${level}`);
    banner.show('Game over', touchMessage(galEl.dataset.name, disk), `Try level ${level} again`,
      { startOver: level > 1 });
  }

  spreadZones(disks, 0);
  for (const el of document.querySelectorAll('.target-colonies')) el.textContent = target;
  updateCounter();
  requestAnimationFrame(step);
}
