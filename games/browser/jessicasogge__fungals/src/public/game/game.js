// The classic game loop: steer with the arrow keys or by touch, grow a colony past the
// antifungal disks, and the level-complete, win or game-over pop-up.
import { spreadZones, touchedDisk, touchMessage } from './antifungal.js';
import { levelBanner } from './banner.js';
import { makeColony, moveGroups } from './colony.js';
import { GAME, LEVELS } from './config.js';
import { yeastGroup } from './yeast.js';
import { showFact } from './facts.js';
import { arrowKeys } from './keyboard.js';
import { sporeBurst } from './spores.js';
import { steer, touchSteering } from './touch.js';
import { track } from './track.js';

// `level` is which level this is (1 to 7) and `target` how many cells it
// takes to beat it.
export function playGame(galEl, species, nutrients, disks, { level = 1, target = LEVELS[0].target } = {}) {
  const agar = document.querySelector('.agar');
  const counter = document.querySelector('.cell-count');
  const dishRadius = () => agar.clientWidth / 2;

  // The player's gal leads the colony.
  const playerMover = document.querySelector('.gal-mover');
  playerMover.classList.add('player');
  const player = yeastGroup({ mover: playerMover, svg: galEl, species, isPlayer: true });
  const colony = makeColony({
    leader: player, nutrients, disks, dishRadius, target, color: species.color,
    onDivide: () => updateCounter(), onPop: () => updateCounter(),
  });

  let finished = false;
  let lastTime = null;
  // How long the level has been running, for how far the zones have spread.
  // Built from the same capped frame times as everything else, so the zones
  // don't jump ahead after the tab was hidden for a while.
  let elapsed = 0;
  const keys = arrowKeys();
  // Drag with a finger anywhere on the dish, rim included (or hold a mouse
  // button where to swim).
  const touch = touchSteering(agar, agar.closest('.petri-dish') ?? agar);

  // The level-complete, win or game-over pop-up and its buttons.
  const banner = levelBanner(level);

  function updateCounter() {
    const shown = Math.min(colony.cellCount(), target);
    counter.textContent = `Level ${level} · ${shown} / ${target} cells`;
  }

  function step(time) {
    const seconds = lastTime === null ? 0 : Math.min(0.05, (time - lastTime) / 1000);
    lastTime = time;
    const radius = dishRadius();

    // The drugs keep soaking outward until the level ends.
    if (!finished) {
      elapsed += seconds;
      spreadZones(disks, elapsed);
    }

    // Steer the player's gal.
    if (!finished) {
      steer(player, keys.direction(), touch.target(), GAME.SPEED * radius * seconds, GAME.ARRIVE * radius,
        touch.drag(), GAME.DRAG_SPEED * radius * seconds);
    }

    colony.tick(seconds);
    moveGroups(colony.groups, { agar, radius, seconds });
    // Offspring that wander into an antifungal zone pop.
    if (!finished) colony.popInZones(radius);

    // Touching any antifungal disk, or the zone of inhibition around it, is
    // game over.
    const hit = finished ? null : touchedDisk(disks, player.body(), radius);
    if (hit) {
      finished = true;
      keys.stop();
      touch.stop();
      nutrients.stop();
      playerMover.classList.add('killed');
      setTimeout(() => showGameOver(hit), 500);
    }

    if (!finished) {
      colony.eat(seconds, radius);

      if (colony.cellCount() >= target) {
        // Celebrate the moment the colony is big enough, and stop play so a
        // disk can't be touched after winning. The pop-up waits only until
        // the newest cell has finished sliding into place.
        finished = true;
        keys.stop();
        touch.stop();
        nutrients.stop();
        sporeBurst(playerMover, { big: level === LEVELS.length });
        setTimeout(showWin, Math.max(0, GAME.DIVIDE_MS - colony.sinceAnyDivision));
      } else {
        colony.divideLeader();
      }
    }

    requestAnimationFrame(step);
  }

  function showWin() {
    const name = galEl.dataset.name;
    const gal = galEl.dataset.gal;
    track(`level-complete/${gal}/level-${level}`, `${name} finished level ${level}`);
    if (level === LEVELS.length) track(`won-all-levels/${gal}`, `${name} beat every level`);
    showFact(gal, species);
    if (level < LEVELS.length) {
      banner.show(`Level ${level} complete!`, `You grew a colony of ${target} cells!`,
        `Play level ${level + 1}`, { next: level + 1 });
    } else {
      banner.show('You won!', `You beat all ${LEVELS.length} levels with a colony of ${target} cells!`,
        'Play again', { next: 1 });
    }
  }

  function showGameOver(disk) {
    showFact(galEl.dataset.gal, species);
    const { code, name } = disk.antifungal;
    track(`game-over/${galEl.dataset.gal}/level-${level}/${code}`,
      `${galEl.dataset.name} hit ${name} on level ${level}`);
    banner.show(
      'Game over',
      touchMessage(galEl.dataset.name, disk),
      `Try level ${level} again`,
      { startOver: level > 1 }, // on level 1 they'd do the same thing
    );
  }

  // The zones start small and spread from there (drawn before the first frame).
  spreadZones(disks, 0);

  // Keep the how-to-play target in step with the real one.
  for (const el of document.querySelectorAll('.target-cells')) el.textContent = target;
  updateCounter();
  requestAnimationFrame(step);
}
