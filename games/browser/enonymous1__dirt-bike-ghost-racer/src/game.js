'use strict';
/* ==========================================================================
   Dirt Bike Ghost Racer — vanilla JavaScript + HTML5 Canvas
   Staff-review patch (review-only, NOT in the public export at 4f27ba1):
   fixes the form-field input hijack, centralises ramp geometry, names
   the inline magic numbers, adds JSDoc to the complex functions, caches
   the sky gradient and HUD writes, and adds an optional seeded RNG for
   deterministic tracks/tests. See REVIEW.md in this folder for the
   full findings and what was deliberately left for a follow-up.
   --------------------------------------------------------------------------
   Sections:
     1. Constants & state
     2. Input handling
     3. Track / obstacle generation  (Track class)
     4. Player physics              (Player class)
     5. Custom track editor         (click-to-place, save/load, import/export)
     6. Ghost races                 (record, playback, shareable JSON ghosts)
     7. Drawing — sprites are primitives here on purpose
     8. HUD
     9. Main game loop (requestAnimationFrame + delta time)

   SPRITE SWAP NOTE: every entity is drawn through one small function
   (drawBike, drawRider, drawObstacle). To use real sprite sheets later,
   replace the body of one of those functions with a drawImage() call
   using the same (screenX, screenY, angle, scale) arguments. Nothing
   else in the game needs to change.
   ========================================================================== */

// --------------------------------------------------------------------------
// 1. Constants & state
// --------------------------------------------------------------------------
const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');

const W = 800;                 // canvas internal resolution (do not change
const H = 600;                 // without also changing index.html)

const GRAVITY = 1500;          // px / s^2
const ACCEL_STANDARD = 520;    // Z key, px / s^2
const ACCEL_TURBO = 1050;      // X key, px / s^2
const MAX_SPEED_STANDARD = 380;
const MAX_SPEED_TURBO = 640;
const COAST_DECAY = 260;       // px / s lost when no accelerator is held
const AIR_DRAG = 25;           // px / s lost per second in the air
const LANDING_TOLERANCE = 0.38; // radians (~22 deg) of pitch error allowed
const TRACK_LENGTH = 12000;    // px from start line to finish line
const OVERHEAT_COOLDOWN = 3.0; // seconds stopped while the engine cools

// Heat is 0..100. Z builds slowly, X builds fast, coasting cools,
// a Cool Zone cools very fast, and 100 triggers OVERHEATED.
const HEAT_STANDARD = 7;
const HEAT_TURBO = 30;
const HEAT_COOL_IDLE = 14;
const HEAT_COOL_ZONE = 95;

const LANE_BASE_Y = [365, 415, 465, 515]; // ground line for each of 4 lanes
const LANE_SCALE = [0.85, 0.92, 1.0, 1.1]; // pseudo-3D: nearer lanes are bigger

// Named constants for values that were previously inline magic numbers.
// Each name says what the number is for, so changing gameplay tuning
// does not require hunting through physics, rendering, and editor code.
const CAMERA_OFFSET_X = 220; // player sits left-of-centre so the track ahead is visible
const PLAYER_START_X = 40;
const PLAYER_START_LANE = 3;
const CRASH_TUMBLE_X = 55; // how far ahead of the rider the bike lands on a crash
const CRASH_WALK_SPEED = 75; // px/s the rider walks back on their own
const CRASH_MASH_STEP = 16; // px gained per Z/X mash while crashed
const EDITOR_BUTTON_SCROLL = 400; // px per scroll-button click in the editor
const EDITOR_KEY_SCROLL_SPEED = 600; // px/s while holding Arrow Left/Right in the editor
const HEAT_WARM_AT = 40; // TEMP bar turns yellow at/above this
const HEAT_HOT_AT = 75; // TEMP bar turns red at/above this
const MAX_PITCH = 0.75; // radians of nose-up / nose-down the player can hold in the air
const PITCH_RATE = 1.9; // radians/s the pitch changes while holding Left/Right in the air
const AIR_PITCH_DRAG = 160; // extra px/s lost while holding nose-up in the air

const GameState = {
  TITLE_SCREEN: 'TITLE_SCREEN',
  PLAYING: 'PLAYING',
  CRASHED: 'CRASHED',
  OVERHEATED: 'OVERHEATED',
  FINISHED: 'FINISHED',
  EDITOR: 'EDITOR',
};
Object.freeze(GameState); // states are a closed set; a typo'd state should fail loudly, not silently create a new one

const game = {
  state: GameState.TITLE_SCREEN,
  lapTime: 0,
  finalTime: 0,
  cameraX: 0,
  overheatTimer: 0,
  editorCameraX: 0,
  ghostResult: null, // { beat, delta, opponentName, opponentTime } after a ghost race
};

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const lerp = (a, b, t) => a + (b - a) * t;
// Note: the old rand() helper was removed in this patch — Track.generate
// now uses its own rng() (Math.random or the seeded mulberry32), so rand()
// had no remaining callers and was dead code.

// --------------------------------------------------------------------------
// 2. Input handling
// --------------------------------------------------------------------------
// Keys are stored by e.code ("KeyZ", "ArrowUp", ...) so layout does not
// matter. justPressed is consumed once per frame; mashPending counts
// Z/X presses that happened while crashed, so mashing actually matters.
const input = {
  keys: new Set(),
  justPressed: new Set(),
  mashPending: 0,
};

function pressKey(code) {
  if (input.keys.has(code)) return; // ignore auto-repeat / held touch button
  input.keys.add(code);
  input.justPressed.add(code);
  if (game.state === GameState.CRASHED && (code === 'KeyZ' || code === 'KeyX')) {
    input.mashPending += 1;
  }
}

const HANDLED_CODES = new Set([
  'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight',
  'KeyZ', 'KeyX', 'Enter', 'KeyR', 'Space', 'KeyE', 'Escape',
]);

/**
 * Whether a key event came from a form field. The original code called
 * preventDefault() for every handled key, everywhere — so typing a space,
 * arrow, Z, or X in the track/ghost JSON textareas, the author name, or
 * the editor position field was hijacked by the game instead of editing
 * text. Form-field keys must reach the field, not the game.
 * @param {EventTarget|null} target The event target.
 * @returns {boolean} True when the user is typing in a form field.
 */
function isFormField(target) {
  if (!target || typeof target.tagName !== 'string') return false;
  const tag = target.tagName.toUpperCase();
  return tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || !!target.isContentEditable;
}

window.addEventListener('keydown', (e) => {
  if (!HANDLED_CODES.has(e.code)) return;
  if (isFormField(e.target)) return; // let the field handle its own keys
  e.preventDefault();
  pressKey(e.code);
});
// keyup is deliberately NOT guarded: if a game key was released while a
// form field had focus, the game must still forget it, or it stays stuck.
window.addEventListener('keyup', (e) => input.keys.delete(e.code));

// Touch buttons in index.html feed the exact same key state.
document.querySelectorAll('.touch button').forEach((btn) => {
  const code = btn.dataset.key;
  const down = (e) => { e.preventDefault(); pressKey(code); };
  const up = () => input.keys.delete(code);
  btn.addEventListener('pointerdown', down);
  btn.addEventListener('pointerup', up);
  btn.addEventListener('pointerleave', up);
  btn.addEventListener('pointercancel', up);
});

// --------------------------------------------------------------------------
// 3. Track / obstacle generation
// --------------------------------------------------------------------------
// Obstacle shapes (all widths in world px):
//   SMALL_RAMP: triangle, 90 wide, 42 tall, launches from its peak.
//   LARGE_RAMP: plateau (up-slope, flat top, down-slope), 190 wide,
//               55 tall, launches from the end of the flat top.
//   MUD:        flat puddle, slows drastically, never crashes.
//   COOL:       flat chevron zone, cools the engine fast, never crashes.
const ObstacleType = {
  SMALL_RAMP: 'SMALL_RAMP',
  LARGE_RAMP: 'LARGE_RAMP',
  MUD: 'MUD',
  COOL: 'COOL',
};

/**
 * Single source of truth for obstacle geometry. Before this patch the
 * large-ramp numbers (190 wide, 55 tall, 55 slope, 135 flat-end) were
 * repeated in obstacleDims, rampProfile, launchX, and drawObstacle, so
 * changing a ramp meant editing four places and hoping they stayed in
 * sync. Every geometry user below reads from here, and only here.
 * @type {Record<string, {width: number, height: number, slopeLen?: number, flatEnd?: number, peak?: number}>}
 */
const OBSTACLE_GEOMETRY = {
  SMALL_RAMP: { width: 90, height: 42, peak: 45 }, // peak = width / 2
  LARGE_RAMP: { width: 190, height: 55, slopeLen: 55, flatEnd: 135 },
  MUD: { width: 130, height: 0 },
  COOL: { width: 120, height: 0 },
};

/**
 * @param {string} type An ObstacleType value.
 * @returns {{width: number, height: number}} Width/height in world px.
 */
function obstacleDims(type) {
  const g = OBSTACLE_GEOMETRY[type];
  return g ? { width: g.width, height: g.height } : { width: 100, height: 0 };
}

/**
 * Height + ground-slope angle of a ramp at a local x inside the obstacle.
 * Slope angle is in screen space (negative = ground rising to the right,
 * which is also nose-up for the bike), so it can be compared directly
 * with the bike's rotation on landing.
 * @param {string} type An ObstacleType value.
 * @param {number} localX Distance into the obstacle, in world px.
 * @param {number} width Obstacle width, from obstacleDims.
 * @param {number} height Obstacle height, from obstacleDims.
 * @returns {{h: number, slope: number}} Height above the lane line and slope angle in radians.
 */
function rampProfile(type, localX, width, height) {
  if (type === ObstacleType.SMALL_RAMP) {
    const half = OBSTACLE_GEOMETRY.SMALL_RAMP.peak;
    if (localX < half) return { h: (localX / half) * height, slope: Math.atan2(-height, half) };
    return { h: ((width - localX) / half) * height, slope: Math.atan2(height, half) };
  }
  if (type === ObstacleType.LARGE_RAMP) {
    const { slopeLen, flatEnd } = OBSTACLE_GEOMETRY.LARGE_RAMP;
    if (localX < slopeLen) return { h: (localX / slopeLen) * height, slope: Math.atan2(-height, slopeLen) };
    if (localX < flatEnd) return { h: height, slope: 0 };
    const down = width - flatEnd;
    return { h: ((width - localX) / down) * height, slope: Math.atan2(height, down) };
  }
  return { h: 0, slope: 0 };
}

/**
 * Small deterministic RNG (mulberry32). Used only when a seed is passed
 * to Track.generate, so a track can be reproduced exactly in a test or
 * shared by seed. The default path (no seed) still uses Math.random, so
 * existing behaviour is unchanged.
 * @param {number} seed Any integer seed.
 * @returns {() => number} A function returning a float in [0, 1).
 */
function mulberry32(seed) {
  let a = seed >>> 0;
  return function mulberry32Next() {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

class Track {
  constructor() {
    this.obstacles = [];
    this.generate();
  }

  /**
   * Generate a track. Pass a seed for a deterministic track (same seed =
   * same obstacles, in the same lanes, in the same order); omit it for a
   * fresh random track, as the game does today.
   * @param {number} [seed] Optional integer seed for mulberry32.
   */
  generate(seed) {
    const rng = seed === undefined ? Math.random : mulberry32(seed);
    this.obstacles = [];
    let x = 900; // keep the start clean so the player can get up to speed
    let sinceCool = 0;
    while (x < TRACK_LENGTH - 900) {
      // Guarantee a Cool Zone reasonably often, otherwise pick randomly.
      let type;
      if (sinceCool > 2200) {
        type = ObstacleType.COOL;
      } else {
        const r = rng();
        if (r < 0.32) type = ObstacleType.SMALL_RAMP;
        else if (r < 0.52) type = ObstacleType.LARGE_RAMP;
        else if (r < 0.78) type = ObstacleType.MUD;
        else type = ObstacleType.COOL;
      }
      const { width } = obstacleDims(type);
      const lane = Math.floor(rng() * 4);
      this.obstacles.push({ x, lane, type, width });
      if (type === ObstacleType.COOL) sinceCool = 0; else sinceCool += width;
      const gap = 450 + rng() * 500;
      x += width + gap;
      sinceCool += gap;
    }
    this.obstacles.sort((a, b) => a.x - b.x);
  }

  /**
   * Ground line under a world x, for the lane nearest laneFloat.
   * This is O(n) over obstacles and is called a few times per frame; with
   * ~30–40 obstacles on a 12,000 px track that is cheap, and keeping it
   * simple beats an index until the track gets an order of magnitude longer.
   * @param {number} x World x in px.
   * @param {number} laneFloat Smooth lane (may be between lanes while switching).
   * @returns {{y: number, slope: number, obstacle: object|null}} Ground y,
   *   screen-space slope angle (0 on flat ground), and the obstacle there, if any.
   */
  groundAt(x, laneFloat) {
    const lane = clamp(Math.round(laneFloat), 0, 3);
    const base = baseYForLane(laneFloat);
    for (const ob of this.obstacles) {
      if (ob.lane !== lane) continue;
      if (x < ob.x || x > ob.x + ob.width) continue;
      const { height } = obstacleDims(ob.type);
      const p = rampProfile(ob.type, x - ob.x, ob.width, height);
      return { y: base - p.h, slope: p.slope, obstacle: ob };
    }
    return { y: base, slope: 0, obstacle: null };
  }

  /**
   * The world x where a ramp launches the bike, or null for flat types.
   * Small ramps launch from the peak; large ramps launch from the end of
   * the flat top, so the bike rides the plateau instead of jumping off it.
   * @param {{x: number, type: string}} ob An obstacle.
   * @returns {number|null} Launch x, or null.
   */
  launchX(ob) {
    if (ob.type === ObstacleType.SMALL_RAMP) return ob.x + OBSTACLE_GEOMETRY.SMALL_RAMP.peak;
    if (ob.type === ObstacleType.LARGE_RAMP) return ob.x + OBSTACLE_GEOMETRY.LARGE_RAMP.flatEnd;
    return null;
  }

  // Replace the track with a validated custom list (used by the editor).
  // Width is always recomputed from the type, so a hand-written JSON file
  // cannot smuggle in a mismatched width.
  setObstacles(list) {
    this.obstacles = list
      .map((ob) => ({ x: ob.x, lane: ob.lane, type: ob.type, width: obstacleDims(ob.type).width }))
      .sort((a, b) => a.x - b.x);
  }
}

// Smooth ground line while the player is between lanes.
function baseYForLane(laneFloat) {
  const f = clamp(laneFloat, 0, 3);
  const i = Math.min(2, Math.floor(f));
  return lerp(LANE_BASE_Y[i], LANE_BASE_Y[i + 1], f - i);
}
function scaleForLane(laneFloat) {
  const f = clamp(laneFloat, 0, 3);
  const i = Math.min(2, Math.floor(f));
  return lerp(LANE_SCALE[i], LANE_SCALE[i + 1], f - i);
}

// --------------------------------------------------------------------------
// 4. Player physics
// --------------------------------------------------------------------------
class Player {
  constructor() { this.reset(); }

  reset() {
    this.x = PLAYER_START_X;
    this.y = LANE_BASE_Y[PLAYER_START_LANE];
    this.vx = 0;
    this.vy = 0;
    this.laneFloat = PLAYER_START_LANE; // smooth visual lane; targetLane is the discrete one
    this.targetLane = PLAYER_START_LANE;
    this.angle = 0;       // screen-space rotation: negative = nose up
    this.grounded = true;
    this.wheelie = false;
    this.heat = 0;
    // Crash state: bike tumbles ahead, rider is left behind.
    this.crashBikeX = 0;
    this.crashRiderX = 0;
  }

  get speedMph() { return Math.round(Math.max(0, this.vx) * 0.15); }

  update(dt, track) {
    // --- Lane switching (edge-triggered, so holding the key doesn't spam)
    if (input.justPressed.has('ArrowUp')) this.targetLane = Math.max(0, this.targetLane - 1);
    if (input.justPressed.has('ArrowDown')) this.targetLane = Math.min(3, this.targetLane + 1);
    this.laneFloat += (this.targetLane - this.laneFloat) * Math.min(1, dt * 10);

    const accelerating = input.keys.has('KeyZ') || input.keys.has('KeyX');
    const turbo = input.keys.has('KeyX');
    const ground = track.groundAt(this.x, this.laneFloat);
    const onMud = this.grounded && ground.obstacle && ground.obstacle.type === ObstacleType.MUD;
    const onCool = this.grounded && ground.obstacle && ground.obstacle.type === ObstacleType.COOL;

    // --- Engine heat: Z slow, X fast, coasting cools, Cool Zone cools fast
    if (turbo) this.heat += HEAT_TURBO * dt;
    else if (input.keys.has('KeyZ')) this.heat += HEAT_STANDARD * dt;
    else this.heat -= HEAT_COOL_IDLE * dt;
    if (onCool) this.heat -= HEAT_COOL_ZONE * dt;
    this.heat = clamp(this.heat, 0, 100);

    if (this.heat >= 100) {
      game.state = GameState.OVERHEATED;
      game.overheatTimer = OVERHEAT_COOLDOWN;
      this.vx = 0;
      this.vy = 0;
      return;
    }

    // --- Horizontal speed, with mud as a hard cap
    if (turbo) this.vx += ACCEL_TURBO * dt;
    else if (input.keys.has('KeyZ')) this.vx += ACCEL_STANDARD * dt;
    else this.vx -= Math.sign(this.vx) * Math.min(Math.abs(this.vx), COAST_DECAY * dt);
    const cap = onMud ? 130 : (turbo ? MAX_SPEED_TURBO : MAX_SPEED_STANDARD);
    if (this.vx > cap) this.vx = Math.max(cap, this.vx - 900 * dt); // ease down to cap
    if (onMud) this.vx = Math.max(60, this.vx - 500 * dt);
    this.vx = Math.max(0, this.vx);

    const prevX = this.x;
    this.x += this.vx * dt;

    if (this.grounded) {
      // Wheelie: Left/Right on the ground lifts the front wheel (visual,
      // plus a tiny drag cost so it is a style choice, not free speed).
      this.wheelie = input.keys.has('ArrowLeft') || input.keys.has('ArrowRight');
      if (this.wheelie) this.vx = Math.max(0, this.vx - 30 * dt);
      this.angle = this.wheelie ? -0.42 : ground.slope;
      this.y = ground.y;

      // Ramp launch: crossing the crest/flat-end at speed sends us airborne.
      // Riding slowly over the same ramp just follows its profile instead.
      const ob = ground.obstacle;
      if (ob && (ob.type === ObstacleType.SMALL_RAMP || ob.type === ObstacleType.LARGE_RAMP)) {
        const lx = track.launchX(ob);
        if (lx !== null && prevX < lx && this.x >= lx && this.vx > 170) {
          this.grounded = false;
          const factor = ob.type === ObstacleType.SMALL_RAMP ? 0.42 : 0.52;
          this.vy = -this.vx * factor;
          this.angle = ob.type === ObstacleType.SMALL_RAMP ? -0.35 : -0.15;
        }
      }
    } else {
      // --- Airborne: Left = nose up (more drag, shorter jump),
      //     Right = nose down (less drag, longer jump).
      if (input.keys.has('ArrowLeft')) {
        this.angle = Math.max(-MAX_PITCH, this.angle - PITCH_RATE * dt);
        this.vx = Math.max(0, this.vx - AIR_PITCH_DRAG * dt);
      }
      if (input.keys.has('ArrowRight')) {
        this.angle = Math.min(MAX_PITCH, this.angle + PITCH_RATE * dt);
      }
      this.vx = Math.max(0, this.vx - AIR_DRAG * dt);
      this.vy += GRAVITY * dt;
      this.y += this.vy * dt;

      // Landing: the bike angle must match the ground angle.
      const landing = track.groundAt(this.x, this.laneFloat);
      if (this.y >= landing.y) {
        this.y = landing.y;
        this.vy = 0;
        if (Math.abs(this.angle - landing.slope) > LANDING_TOLERANCE) {
          this.crash(landing.y);
        } else {
          this.grounded = true;
          this.angle = landing.slope;
          this.vx *= 0.92; // small landing loss
        }
      }
    }

    // --- Finish line
    if (this.x >= TRACK_LENGTH) {
      this.x = TRACK_LENGTH;
      game.finalTime = game.lapTime;
      game.state = GameState.FINISHED;
    }
  }

  crash(groundY) {
    game.state = GameState.CRASHED;
    this.crashBikeX = this.x + CRASH_TUMBLE_X;
    this.crashRiderX = this.x - 10;
    this.grounded = true;
    this.vx = 0;
    this.vy = 0;
    this.y = groundY;
  }

  // Crashed: the rider walks back on their own, and every Z/X mash
  // jumps them forward, so mashing genuinely gets you going sooner.
  updateCrashed(dt) {
    this.crashRiderX += CRASH_WALK_SPEED * dt; // base walk
    if (input.mashPending > 0) {
      this.crashRiderX += input.mashPending * CRASH_MASH_STEP;
      input.mashPending = 0;
    }
    if (this.crashRiderX >= this.crashBikeX - 12) {
      this.x = this.crashBikeX;
      this.y = baseYForLane(this.laneFloat);
      this.vx = 0;
      this.angle = 0;
      game.state = GameState.PLAYING;
    }
  }
}

const track = new Track();
const player = new Player();

/**
 * Start a normal (ghost-free) race. A normal race is still recorded, so
 * it can become the new best ghost — see finishRecording. Ghost races
 * are deliberately separate (startGhostRace) because they must load the
 * ghost's stored track instead of generating or loading a custom track.
 * @param {boolean} [preferCustom=false] True when the Race Custom button was used.
 */
function startGame(preferCustom = false) {
  // Custom track wins when explicitly requested, or when the editor's
  // "use custom on Enter" checkbox is ticked and a custom track exists.
  // Otherwise every race is a fresh random track, as before.
  const useCustomEl = document.getElementById('use-custom');
  const wantCustom = preferCustom || (useCustomEl && useCustomEl.checked);
  if (wantCustom && customTrack.length > 0) track.setObstacles(customTrack);
  else track.generate();
  player.reset();
  game.lapTime = 0;
  game.finalTime = 0;
  game.cameraX = 0;
  game.ghostResult = null;
  racingGhost = null; // a normal race is ghost-free, but it is still recorded
  game.state = GameState.PLAYING;
  beginRecording();
}

// --------------------------------------------------------------------------
// 5. Custom track editor
// --------------------------------------------------------------------------
// A custom track is just a list of { x, lane, type } — the same shape the
// random generator produces. It lives apart from `track` so racing a
// random track never clobbers your edited track, and vice versa.
// It is persisted in localStorage on Save, and can be copied out as JSON
// (Export) or pasted back in (Import) to share it with another browser.
const CUSTOM_STORAGE_KEY = 'dirt-bike-ghost-racer-custom-track-v1';
let customTrack = []; // sorted by x; width is derived from type, never stored

const editorEls = {
  section: document.getElementById('track-editor'),
  type: document.getElementById('editor-type'),
  lane: document.getElementById('editor-lane'),
  x: document.getElementById('editor-x'),
  status: document.getElementById('editor-status'),
  list: document.getElementById('obstacle-list'),
  json: document.getElementById('track-json'),
};

const OBSTACLE_LABELS = {
  SMALL_RAMP: 'Small Ramp',
  LARGE_RAMP: 'Large Ramp (plateau)',
  MUD: 'Mud Puddle',
  COOL: 'Cool Zone',
};

const EXAMPLE_TRACK = [
  { x: 1000, lane: 3, type: 'SMALL_RAMP' },
  { x: 1500, lane: 3, type: 'MUD' },
  { x: 2100, lane: 2, type: 'LARGE_RAMP' },
  { x: 2800, lane: 1, type: 'COOL' },
  { x: 3400, lane: 3, type: 'SMALL_RAMP' },
  { x: 3900, lane: 3, type: 'SMALL_RAMP' },
  { x: 4600, lane: 0, type: 'LARGE_RAMP' },
  { x: 5400, lane: 2, type: 'MUD' },
  { x: 6100, lane: 2, type: 'COOL' },
  { x: 6800, lane: 3, type: 'LARGE_RAMP' },
  { x: 7700, lane: 1, type: 'SMALL_RAMP' },
  { x: 8400, lane: 1, type: 'MUD' },
  { x: 9200, lane: 3, type: 'COOL' },
  { x: 9900, lane: 2, type: 'SMALL_RAMP' },
  { x: 10600, lane: 3, type: 'LARGE_RAMP' },
];

function setEditorStatus(msg) {
  if (editorEls.status) editorEls.status.textContent = msg;
}

// Validate + normalise a raw list (from JSON, storage, or the example).
// Anything with a bad type, lane, or position is dropped, not crashed on.
function validateTrack(raw) {
  if (!Array.isArray(raw)) return [];
  const validTypes = new Set(Object.values(ObstacleType));
  return raw
    .filter((ob) => ob && validTypes.has(ob.type) && Number.isFinite(ob.x)
      && Number.isInteger(ob.lane) && ob.lane >= 0 && ob.lane <= 3)
    .map((ob) => ({
      x: Math.round(clamp(ob.x, 100, TRACK_LENGTH - 900)),
      lane: ob.lane,
      type: ob.type,
      width: obstacleDims(ob.type).width,
    }))
    .sort((a, b) => a.x - b.x);
}

function setCustomTrack(list, statusMsg) {
  customTrack = validateTrack(list);
  renderObstacleList();
  if (statusMsg) setEditorStatus(statusMsg);
}

function renderObstacleList() {
  if (!editorEls.list) return;
  editorEls.list.innerHTML = '';
  if (customTrack.length === 0) {
    setEditorStatus('No custom track yet. Add an obstacle to start one.');
    return;
  }
  customTrack.forEach((ob, i) => {
    const li = document.createElement('li');
    li.textContent = `${OBSTACLE_LABELS[ob.type]} — x=${ob.x}, Lane ${ob.lane + 1}`;
    const del = document.createElement('button');
    del.type = 'button';
    del.textContent = 'Delete';
    del.addEventListener('click', () => {
      customTrack.splice(i, 1);
      renderObstacleList();
      setEditorStatus(`Deleted obstacle. ${customTrack.length} left.`);
    });
    li.appendChild(del);
    editorEls.list.appendChild(li);
  });
  setEditorStatus(`${customTrack.length} obstacle(s) in your custom track. Save it in the browser or export it as JSON.`);
}

// Same-lane overlaps would break groundAt (it returns the first match),
// so the editor refuses them instead of silently producing a broken track.
function overlapsExisting(x, width, lane) {
  return customTrack.some((ob) => ob.lane === lane
    && x < ob.x + ob.width && x + width > ob.x);
}

function addCustomObstacle(type, lane, x, source) {
  const width = obstacleDims(type).width;
  const clampedX = Math.round(clamp(x, 100, TRACK_LENGTH - 900));
  if (overlapsExisting(clampedX, width, lane)) {
    setEditorStatus('Too close to an existing obstacle in that lane — move it along the track and try again.');
    return false;
  }
  customTrack.push({ x: clampedX, lane, type, width });
  customTrack.sort((a, b) => a.x - b.x);
  renderObstacleList();
  setEditorStatus(`Added ${OBSTACLE_LABELS[type]} at x=${clampedX}, Lane ${lane + 1} (${source}). ${customTrack.length} total.`);
  return true;
}

function enterEditor() {
  game.state = GameState.EDITOR;
  game.editorCameraX = 0;
  if (editorEls.section) editorEls.section.classList.add('active');
  renderObstacleList();
}

function exitEditor() {
  game.state = GameState.TITLE_SCREEN;
  if (editorEls.section) editorEls.section.classList.remove('active');
}

function laneFromScreenY(screenY) {
  let best = 0, bestDist = Infinity;
  LANE_BASE_Y.forEach((y, i) => {
    const d = Math.abs(y - screenY);
    if (d < bestDist) { bestDist = d; best = i; }
  });
  return best;
}

function canvasToWorld(e) {
  const rect = canvas.getBoundingClientRect();
  return {
    wx: game.editorCameraX + (e.clientX - rect.left) * (W / rect.width),
    wy: (e.clientY - rect.top) * (H / rect.height),
  };
}

// Click to place, right-click to delete — only while the editor is open,
// so normal racing clicks/taps do nothing unexpected.
canvas.addEventListener('click', (e) => {
  if (game.state !== GameState.EDITOR) return;
  const { wx, wy } = canvasToWorld(e);
  const type = editorEls.type ? editorEls.type.value : 'SMALL_RAMP';
  const lane = editorEls.lane && editorEls.lane.value !== 'auto'
    ? parseInt(editorEls.lane.value, 10) : laneFromScreenY(wy);
  addCustomObstacle(type, lane, wx - obstacleDims(type).width / 2, 'canvas click');
});

canvas.addEventListener('contextmenu', (e) => {
  if (game.state !== GameState.EDITOR) return;
  e.preventDefault();
  const { wx, wy } = canvasToWorld(e);
  const lane = laneFromScreenY(wy);
  const idx = customTrack.findIndex((ob) => ob.lane === lane
    && wx >= ob.x - 20 && wx <= ob.x + ob.width + 20);
  if (idx >= 0) {
    customTrack.splice(idx, 1);
    renderObstacleList();
    setEditorStatus('Deleted obstacle from the canvas.');
  }
});

canvas.addEventListener('wheel', (e) => {
  if (game.state !== GameState.EDITOR) return;
  e.preventDefault();
  game.editorCameraX = clamp(game.editorCameraX + e.deltaY, 0, TRACK_LENGTH - W);
}, { passive: false });

// Editor panel buttons. Each guards for a missing element so an older
// index.html (without the panel) still runs the game untouched.
function bindEditorButton(id, fn) {
  const el = document.getElementById(id);
  if (el) el.addEventListener('click', fn);
}
bindEditorButton('edit-track', enterEditor);
bindEditorButton('scroll-left', () => {
  game.editorCameraX = clamp(game.editorCameraX - EDITOR_BUTTON_SCROLL, 0, TRACK_LENGTH - W);
});
bindEditorButton('scroll-right', () => {
  game.editorCameraX = clamp(game.editorCameraX + EDITOR_BUTTON_SCROLL, 0, TRACK_LENGTH - W);
});
bindEditorButton('add-obstacle', () => {
  const type = editorEls.type ? editorEls.type.value : 'SMALL_RAMP';
  const lane = editorEls.lane ? parseInt(editorEls.lane.value, 10) : 3;
  const x = editorEls.x ? parseInt(editorEls.x.value, 10) : 1000;
  // The form's lane selector has an "auto" option too; default it to lane 4.
  addCustomObstacle(type, Number.isInteger(lane) ? lane : 3, Number.isFinite(x) ? x : 1000, 'form');
});
bindEditorButton('race-custom', () => {
  if (customTrack.length === 0) {
    setEditorStatus('Your custom track is empty — add an obstacle first, or load the example track.');
    return;
  }
  startGame(true);
});
bindEditorButton('race-random', () => startGame(false));
bindEditorButton('example-track', () => setCustomTrack(EXAMPLE_TRACK, 'Example track loaded. Race it, or edit it first.'));
bindEditorButton('clear-track', () => {
  customTrack = [];
  renderObstacleList();
});
bindEditorButton('save-track', () => {
  try {
    localStorage.setItem(CUSTOM_STORAGE_KEY, JSON.stringify(
      customTrack.map(({ x, lane, type }) => ({ x, lane, type }))));
    setEditorStatus(`Saved ${customTrack.length} obstacle(s) in this browser. It will load automatically next time.`);
  } catch (err) {
    setEditorStatus('Could not save in this browser (storage unavailable). Use Export to JSON instead.');
  }
});
bindEditorButton('export-track', () => {
  if (editorEls.json) {
    editorEls.json.value = JSON.stringify(
      customTrack.map(({ x, lane, type }) => ({ x, lane, type })), null, 2);
  }
  setEditorStatus('Exported to the JSON box below — copy it to share or back it up.');
});
bindEditorButton('import-track', () => {
  if (!editorEls.json) return;
  try {
    const parsed = JSON.parse(editorEls.json.value);
    const valid = validateTrack(parsed);
    if (valid.length === 0) {
      setEditorStatus('Nothing valid to import. Check the JSON shape: [{"x":1000,"lane":3,"type":"SMALL_RAMP"}]');
      return;
    }
    setCustomTrack(valid, `Imported ${valid.length} obstacle(s).`);
  } catch (err) {
    setEditorStatus('That JSON did not parse. Check for missing brackets or commas and try again.');
  }
});

// Restore a previously saved track on load, silently if there is none.
try {
  const saved = localStorage.getItem(CUSTOM_STORAGE_KEY);
  if (saved) setCustomTrack(JSON.parse(saved), null);
} catch (err) { /* corrupted storage: start empty, editor still works */ }
renderObstacleList();

// --------------------------------------------------------------------------
// 6. Ghost races — record, playback, and shareable ghosts
// --------------------------------------------------------------------------
// Why a ghost carries its track: a ghost is only meaningful on the exact
// track it ran on. A random track changes every race, so a ghost from a
// random race would jump over ramps that no longer exist. Ghost races
// therefore load the ghost's stored track (see startGhostRace), and a
// normal race is still recorded so it can become your next best ghost.
//
// Recording: one sample every 50 ms (20 Hz) of bike position, lane,
// angle, and crash/rider state. That is ~1,200 samples for a 60 s race —
// small enough for localStorage and for a JSON file you can send to a
// friend. Playback interpolates between the two samples bracketing the
// current lap time, so the ghost moves smoothly even though it was
// recorded at 20 Hz. The HUD delta compares times at the same position:
// how long the ghost took to reach where you are now, versus your time.
const GHOST_SAMPLE_INTERVAL = 0.05;
const BEST_GHOST_KEY = 'dirt-bike-ghost-racer-best-ghost-v1';
const RIVAL_GHOST_KEY = 'dirt-bike-ghost-racer-rival-ghost-v1';

let bestGhost = null;    // fastest run you have finished, auto-saved
let rivalGhost = null;   // imported friend's ghost, if any
let racingGhost = null;  // ghost currently being raced against, or null
let recordingSamples = [];
let recordingTimer = 0;
let recordingActive = false;
let recordingTrack = [];

const ghostEls = {
  opponent: document.getElementById('ghost-opponent'),
  author: document.getElementById('ghost-author'),
  status: document.getElementById('ghost-status'),
  info: document.getElementById('ghost-info'),
  json: document.getElementById('ghost-json'),
};

function hashTrack(obstacles) {
  // Small deterministic hash of the track, for display / debugging only.
  // Identity for racing comes from the stored track itself, not this hash.
  const s = obstacles.map((o) => `${o.x},${o.lane},${o.type}`).join(';');
  let h = 5381;
  for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) >>> 0;
  return h.toString(16);
}

function ghostAuthor() {
  const v = ghostEls.author ? ghostEls.author.value.trim() : '';
  return v || 'Player';
}

function playerBikeX() {
  return game.state === GameState.CRASHED ? player.crashBikeX : player.x;
}
function playerBikeY() {
  return game.state === GameState.CRASHED ? baseYForLane(player.laneFloat) : player.y;
}

function beginRecording() {
  recordingSamples = [];
  recordingTimer = 0;
  recordingActive = true;
  recordingTrack = track.obstacles.map(({ x, lane, type }) => ({ x, lane, type }));
  recordSample();
}

function recordSample() {
  recordingSamples.push({
    t: game.lapTime,
    x: playerBikeX(),
    y: playerBikeY(),
    lane: player.laneFloat,
    angle: game.state === GameState.CRASHED ? 0.25 : player.angle,
    crashed: game.state === GameState.CRASHED,
    riderX: game.state === GameState.CRASHED ? player.crashRiderX : null,
  });
}

function sampleRecording(dt) {
  if (!recordingActive) return;
  recordingTimer += dt;
  if (recordingTimer >= GHOST_SAMPLE_INTERVAL) {
    recordingTimer = 0;
    recordSample();
  }
}

/**
 * Validate a ghost from JSON / storage. A bad sample or track entry is
 * dropped; a ghost with no usable samples or no track is rejected whole,
 * so a corrupted share file can never start a broken race.
 * Why the track is stored, not just a track id: a ghost is only
 * meaningful on the exact track it ran on, and random tracks are not
 * reproducible from an id alone. Storing the track makes the ghost
 * self-contained and shareable as a single JSON file.
 * @param {unknown} raw Parsed JSON, or a value from localStorage.
 * @returns {object|null} Normalised ghost, or null when it cannot be trusted.
 */
function validateGhost(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const trackList = validateTrack(raw.track);
  if (trackList.length === 0 && !(raw.track && raw.track.length === 0)) {
    // A ghost with a non-empty but entirely invalid track is rejected.
    // (An empty track is allowed: it means a clean track with no obstacles.)
    if (raw.track && raw.track.length > 0) return null;
  }
  if (!Number.isFinite(raw.finishTime) || raw.finishTime <= 0) return null;
  if (!Array.isArray(raw.samples) || raw.samples.length < 2) return null;
  const samples = raw.samples
    .filter((s) => s && Number.isFinite(s.t) && Number.isFinite(s.x)
      && Number.isFinite(s.y) && Number.isFinite(s.lane) && Number.isFinite(s.angle))
    .map((s) => ({
      t: s.t, x: s.x, y: s.y, lane: clamp(s.lane, 0, 3), angle: s.angle,
      crashed: !!s.crashed, riderX: Number.isFinite(s.riderX) ? s.riderX : null,
    }))
    .sort((a, b) => a.t - b.t);
  if (samples.length < 2) return null;
  return {
    version: 1,
    name: typeof raw.name === 'string' && raw.name.trim() ? raw.name.trim().slice(0, 24) : 'Player',
    trackId: hashTrack(trackList),
    track: trackList.map(({ x, lane, type }) => ({ x, lane, type })),
    finishTime: raw.finishTime,
    samples,
  };
}

function finishRecording() {
  if (!recordingActive) return;
  recordingActive = false;
  recordSample(); // final sample at the finish line
  const ghost = {
    version: 1,
    name: ghostAuthor(),
    trackId: hashTrack(recordingTrack),
    track: recordingTrack,
    finishTime: game.finalTime,
    samples: recordingSamples,
  };
  if (racingGhost) {
    const delta = game.finalTime - racingGhost.finishTime;
    game.ghostResult = {
      beat: delta < 0,
      delta: Math.abs(delta),
      opponentName: racingGhost.name,
      opponentTime: racingGhost.finishTime,
    };
  }
  if (!bestGhost || ghost.finishTime < bestGhost.finishTime) {
    bestGhost = ghost;
    try { localStorage.setItem(BEST_GHOST_KEY, JSON.stringify(bestGhost)); } catch (err) { /* storage full/blocked: ghost still works this session */ }
    setGhostStatus(`New best ghost! ${formatTime(ghost.finishTime)} — saved in this browser. Export it to share it.`);
  } else if (racingGhost) {
    setGhostStatus(game.ghostResult.beat
      ? `You beat ${racingGhost.name} by ${game.ghostResult.delta.toFixed(2)}s!`
      : `Lost to ${racingGhost.name} by ${game.ghostResult.delta.toFixed(2)}s. Your best ghost is still ${formatTime(bestGhost.finishTime)}.`);
  }
  updateGhostInfo();
}

function startGhostRace() {
  const choice = ghostEls.opponent ? ghostEls.opponent.value : 'best';
  const ghost = choice === 'rival' ? rivalGhost : choice === 'best' ? bestGhost : null;
  if (!ghost) {
    setGhostStatus(choice === 'rival'
      ? 'No imported ghost yet — paste a ghost JSON below and import it first.'
      : 'No best ghost yet — finish a race first, then race your best ghost.');
    return;
  }
  track.setObstacles(ghost.track);
  racingGhost = ghost;
  player.reset();
  game.lapTime = 0;
  game.finalTime = 0;
  game.cameraX = 0;
  game.ghostResult = null;
  game.state = GameState.PLAYING;
  beginRecording();
  setGhostStatus(`Racing ${ghost.name}'s ghost (${formatTime(ghost.finishTime)}) on its original track.`);
}

function selectedGhostForExport() {
  const choice = ghostEls.opponent ? ghostEls.opponent.value : 'best';
  if (choice === 'rival') return rivalGhost;
  return bestGhost;
}

function setGhostStatus(msg) {
  if (ghostEls.status) ghostEls.status.textContent = msg;
}

function updateGhostInfo() {
  if (ghostEls.info) {
    ghostEls.info.textContent = `Best: ${bestGhost ? `${bestGhost.name} — ${formatTime(bestGhost.finishTime)}` : '—'}  •  Imported: ${rivalGhost ? `${rivalGhost.name} — ${formatTime(rivalGhost.finishTime)}` : '—'}`;
  }
  if (ghostEls.opponent) {
    const opts = ghostEls.opponent.options;
    if (opts[1]) opts[1].disabled = !bestGhost;
    if (opts[2]) opts[2].disabled = !rivalGhost;
    if (ghostEls.opponent.value === 'best' && !bestGhost) ghostEls.opponent.value = 'none';
    if (ghostEls.opponent.value === 'rival' && !rivalGhost) ghostEls.opponent.value = 'none';
  }
}

function bindGhostButton(id, fn) {
  const el = document.getElementById(id);
  if (el) el.addEventListener('click', fn);
}
bindGhostButton('race-ghost', startGhostRace);
bindGhostButton('clear-rival', () => {
  rivalGhost = null;
  try { localStorage.removeItem(RIVAL_GHOST_KEY); } catch (err) { /* ignore */ }
  updateGhostInfo();
  setGhostStatus('Imported ghost cleared.');
});
bindGhostButton('export-ghost', () => {
  const ghost = selectedGhostForExport();
  if (!ghost) {
    setGhostStatus('Nothing to export yet — finish a race to record your best ghost first.');
    return;
  }
  if (ghostEls.json) ghostEls.json.value = JSON.stringify(ghost, null, 2);
  setGhostStatus(`Exported ${ghost.name}'s ghost (${formatTime(ghost.finishTime)}) to the JSON box below — copy it and send it to a friend.`);
});
bindGhostButton('import-ghost', () => {
  if (!ghostEls.json) return;
  try {
    const ghost = validateGhost(JSON.parse(ghostEls.json.value));
    if (!ghost) {
      setGhostStatus('That ghost did not validate. It needs a track, a finish time, and at least 2 samples.');
      return;
    }
    rivalGhost = ghost;
    try { localStorage.setItem(RIVAL_GHOST_KEY, JSON.stringify(rivalGhost)); } catch (err) { /* ignore */ }
    if (ghostEls.opponent) ghostEls.opponent.value = 'rival';
    updateGhostInfo();
    setGhostStatus(`Imported ${ghost.name}'s ghost (${formatTime(ghost.finishTime)}). Press Race Ghost to race it.`);
  } catch (err) {
    setGhostStatus('That ghost JSON did not parse. Check for missing brackets or commas and try again.');
  }
});

// Restore saved ghosts on load; a corrupted entry is ignored, not fatal.
try {
  const savedBest = localStorage.getItem(BEST_GHOST_KEY);
  if (savedBest) bestGhost = validateGhost(JSON.parse(savedBest));
} catch (err) { bestGhost = null; }
try {
  const savedRival = localStorage.getItem(RIVAL_GHOST_KEY);
  if (savedRival) rivalGhost = validateGhost(JSON.parse(savedRival));
} catch (err) { rivalGhost = null; }
updateGhostInfo();

/**
 * Ghost playback: interpolate between the two samples bracketing time t.
 * Recording at 20 Hz keeps a 60 s ghost to ~1,200 samples (~100 KB JSON)
 * while interpolation keeps motion smooth; recording every frame would
 * triple the file for no visible gain.
 * @param {number} t Lap time in seconds.
 * @returns {object|null} Interpolated pose, or null when no ghost is racing.
 */
function ghostPoseAt(t) {
  if (!racingGhost || racingGhost.samples.length === 0) return null;
  const s = racingGhost.samples;
  if (t <= s[0].t) return s[0];
  if (t >= s[s.length - 1].t) return s[s.length - 1];
  let lo = 0, hi = s.length - 1;
  while (hi - lo > 1) {
    const mid = Math.floor((lo + hi) / 2);
    if (s[mid].t <= t) lo = mid; else hi = mid;
  }
  const a = s[lo], b = s[hi], f = (t - a.t) / Math.max(0.0001, b.t - a.t);
  return {
    t,
    x: lerp(a.x, b.x, f),
    y: lerp(a.y, b.y, f),
    lane: lerp(a.lane, b.lane, f),
    angle: lerp(a.angle, b.angle, f),
    crashed: b.crashed,
    riderX: a.riderX !== null && b.riderX !== null ? lerp(a.riderX, b.riderX, f) : b.riderX,
  };
}

/**
 * How long the ghost took to first reach position x. Used for the HUD
 * delta: your time minus the ghost's time at your position.
 * This is a linear scan, not a binary search, on purpose: x is not
 * strictly monotonic (during a crash the bike x stays still while time
 * advances), so "first time the ghost reached x" is the correct answer
 * and a binary search over x could return a later crossing.
 * @param {number} x World x in px.
 * @returns {number|null} Ghost time in seconds, or null when no ghost is racing.
 */
function ghostTimeAtX(x) {
  if (!racingGhost) return null;
  const s = racingGhost.samples;
  if (x <= s[0].x) return s[0].t;
  for (let i = 1; i < s.length; i++) {
    if (s[i].x >= x) {
      const a = s[i - 1], b = s[i];
      const f = b.x === a.x ? 0 : (x - a.x) / (b.x - a.x);
      return lerp(a.t, b.t, f);
    }
  }
  return racingGhost.finishTime;
}

// --------------------------------------------------------------------------
// 7. Drawing
// --------------------------------------------------------------------------
// SPRITE SWAP: replace any draw* body below with drawImage() and the rest
// of the game keeps working — callers only pass screen pos/angle/scale.
const PLAYER_RED = '#e11d2e';
const RAMP_BROWN = '#8b5a2b';
const MUD_BROWN = '#5d4037';
const TRACK_GREY = '#7a6a55';
const GRASS_GREEN = '#4caf50';

function drawBike(sx, sy, angle, scale, alpha = 1) {
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(sx, sy);
  ctx.rotate(angle);
  ctx.scale(scale, scale);
  // Wheels
  ctx.fillStyle = '#111';
  ctx.beginPath(); ctx.arc(-15, -9, 10, 0, Math.PI * 2); ctx.fill();
  ctx.beginPath(); ctx.arc(17, -9, 10, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#ddd';
  ctx.beginPath(); ctx.arc(-15, -9, 4, 0, Math.PI * 2); ctx.fill();
  ctx.beginPath(); ctx.arc(17, -9, 4, 0, Math.PI * 2); ctx.fill();
  // Frame + tank, in player red
  ctx.strokeStyle = PLAYER_RED;
  ctx.lineWidth = 4;
  ctx.beginPath();
  ctx.moveTo(-15, -9); ctx.lineTo(0, -24); ctx.lineTo(17, -9);
  ctx.moveTo(0, -24); ctx.lineTo(8, -24);
  ctx.stroke();
  ctx.fillStyle = PLAYER_RED;
  ctx.fillRect(-6, -30, 18, 8);
  // Rider: helmet + torso + leg, leaning slightly forward
  ctx.fillStyle = '#facc15'; // helmet
  ctx.beginPath(); ctx.arc(2, -40, 7, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#1d4ed8'; // jersey
  ctx.fillRect(-3, -34, 10, 12);
  ctx.strokeStyle = '#1d4ed8';
  ctx.lineWidth = 4;
  ctx.beginPath(); ctx.moveTo(0, -24); ctx.lineTo(-8, -12); ctx.stroke();
  ctx.restore();
}

function drawRiderRunning(sx, sy, scale, alpha = 1) {
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(sx, sy);
  ctx.scale(scale, scale);
  ctx.fillStyle = '#facc15';
  ctx.beginPath(); ctx.arc(0, -38, 7, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#1d4ed8';
  ctx.fillRect(-4, -32, 9, 13);
  ctx.strokeStyle = '#111';
  ctx.lineWidth = 4;
  const run = Math.sin(performance.now() / 90) * 8; // leg swing
  ctx.beginPath(); ctx.moveTo(0, -20); ctx.lineTo(6 + run * 0.4, -4); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(0, -20); ctx.lineTo(-6 - run * 0.4, -4); ctx.stroke();
  ctx.restore();
}

function drawObstacle(ob, cameraX) {
  const sx = ob.x - cameraX;
  if (sx < -240 || sx > W + 240) return; // cull off-screen obstacles
  const base = LANE_BASE_Y[ob.lane];
  const { width, height } = obstacleDims(ob.type);

  if (ob.type === ObstacleType.SMALL_RAMP || ob.type === ObstacleType.LARGE_RAMP) {
    ctx.fillStyle = RAMP_BROWN;
    ctx.strokeStyle = '#5d3a1a';
    ctx.lineWidth = 2;
    ctx.beginPath();
    if (ob.type === ObstacleType.SMALL_RAMP) {
      ctx.moveTo(sx, base); ctx.lineTo(sx + width / 2, base - height); ctx.lineTo(sx + width, base);
    } else {
      ctx.moveTo(sx, base); ctx.lineTo(sx + OBSTACLE_GEOMETRY.LARGE_RAMP.slopeLen, base - height);
      ctx.lineTo(sx + OBSTACLE_GEOMETRY.LARGE_RAMP.flatEnd, base - height); ctx.lineTo(sx + width, base);
    }
    ctx.closePath(); ctx.fill(); ctx.stroke();
    return;
  }
  if (ob.type === ObstacleType.MUD) {
    ctx.fillStyle = MUD_BROWN;
    ctx.beginPath(); ctx.ellipse(sx + width / 2, base - 3, width / 2, 7, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#4a2f24';
    ctx.beginPath(); ctx.ellipse(sx + width / 2, base - 3, width / 3, 4, 0, 0, Math.PI * 2); ctx.fill();
    return;
  }
  // COOL: blue chevrons pointing forward, sitting on the ground line.
  ctx.fillStyle = '#2196f3';
  for (let i = 0; i < 3; i++) {
    const cx = sx + 14 + i * 36;
    ctx.beginPath();
    ctx.moveTo(cx, base - 16); ctx.lineTo(cx + 16, base - 6); ctx.lineTo(cx, base + 2);
    ctx.lineTo(cx + 8, base - 6); ctx.closePath(); ctx.fill();
  }
}

let cachedSkyGradient = null; // canvas size is fixed, so the gradient never changes; creating it every frame was pure allocation churn
function drawBackground(cameraX) {
  if (!cachedSkyGradient) {
    cachedSkyGradient = ctx.createLinearGradient(0, 0, 0, 340);
    cachedSkyGradient.addColorStop(0, '#7ec8f7');
    cachedSkyGradient.addColorStop(1, '#bfe6ff');
  }
  ctx.fillStyle = cachedSkyGradient;
  ctx.fillRect(0, 0, W, 340);

  // Sun + slow parallax clouds
  ctx.fillStyle = '#fff7ad';
  ctx.beginPath(); ctx.arc(680, 70, 32, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = 'rgba(255,255,255,0.9)';
  for (let i = 0; i < 5; i++) {
    const cx = ((i * 340 - cameraX * 0.25) % 1700 + 1700) % 1700 - 100;
    const cy = 50 + i * 38;
    ctx.beginPath();
    ctx.arc(cx, cy, 22, 0, Math.PI * 2);
    ctx.arc(cx + 24, cy + 4, 18, 0, Math.PI * 2);
    ctx.arc(cx - 24, cy + 4, 18, 0, Math.PI * 2);
    ctx.fill();
  }
  // Distant green hills (parallax 0.5)
  ctx.fillStyle = '#66bb6a';
  for (let i = 0; i < 6; i++) {
    const hx = ((i * 420 - cameraX * 0.5) % 2520 + 2520) % 2520 - 200;
    ctx.beginPath(); ctx.arc(hx, 345, 130, Math.PI, 0); ctx.fill();
  }
  // Grass strip, then the dirt track with its 4 lane lines
  ctx.fillStyle = GRASS_GREEN;
  ctx.fillRect(0, 330, W, 30);
  ctx.fillStyle = TRACK_GREY;
  ctx.fillRect(0, 360, W, H - 360);
  ctx.strokeStyle = 'rgba(0,0,0,0.35)';
  ctx.setLineDash([18, 14]);
  ctx.lineWidth = 2;
  for (const y of LANE_BASE_Y) {
    ctx.beginPath(); ctx.moveTo(0, y + 8); ctx.lineTo(W, y + 8); ctx.stroke();
  }
  ctx.setLineDash([]);
}

function drawStartFinish(cameraX) {
  for (const fx of [0, TRACK_LENGTH]) {
    const sx = fx - cameraX;
    if (sx < -40 || sx > W + 40) continue;
    for (let y = 360, row = 0; y < H; y += 20, row++) {
      for (let col = 0; col < 2; col++) {
        ctx.fillStyle = (row + col) % 2 === 0 ? '#111' : '#fff';
        ctx.fillRect(sx + col * 20, y, 20, 20);
      }
    }
  }
}

function drawOverlay(title, lines) {
  ctx.fillStyle = 'rgba(0,0,0,0.55)';
  ctx.fillRect(0, 0, W, H);
  ctx.textAlign = 'center';
  ctx.fillStyle = '#ff3b30';
  ctx.font = 'bold 64px Arial';
  ctx.fillText(title, W / 2, 200);
  ctx.fillStyle = '#fff';
  ctx.font = '20px Arial';
  lines.forEach((line, i) => ctx.fillText(line, W / 2, 260 + i * 34));
  ctx.textAlign = 'left';
}

function render() {
  // Editor view: the custom track only, a lane label per lane, and a
  // banner — no bike, no title overlay hiding the track you are editing.
  if (game.state === GameState.EDITOR) {
    drawBackground(game.editorCameraX);
    drawStartFinish(game.editorCameraX);
    for (const ob of customTrack) drawObstacle(ob, game.editorCameraX);
    ctx.fillStyle = 'rgba(0,0,0,0.65)';
    ctx.fillRect(0, 0, W, 34);
    ctx.fillStyle = '#facc15';
    ctx.font = 'bold 17px Arial';
    ctx.textAlign = 'center';
    ctx.fillText(
      `TRACK EDITOR — camera x=${Math.round(game.editorCameraX)}  •  click to place  •  right-click to delete  •  Esc to exit`,
      W / 2, 22);
    ctx.textAlign = 'left';
    ctx.fillStyle = 'rgba(255,255,255,0.9)';
    ctx.font = '15px Arial';
    LANE_BASE_Y.forEach((y, i) => ctx.fillText(`Lane ${i + 1}`, 8, y - 6));
    return;
  }

  drawBackground(game.cameraX);
  drawStartFinish(game.cameraX);
  for (const ob of track.obstacles) drawObstacle(ob, game.cameraX);

  const scale = scaleForLane(player.laneFloat);
  const screenX = player.x - game.cameraX;

  // Ghost first, so the real bike draws on top of it. Translucent, and
  // labelled, so it never reads as a second player or an obstacle.
  if (racingGhost && game.state !== GameState.TITLE_SCREEN && game.state !== GameState.EDITOR) {
    const pose = ghostPoseAt(game.lapTime);
    if (pose) {
      const gsx = pose.x - game.cameraX;
      const gscale = scaleForLane(pose.lane);
      if (gsx > -120 && gsx < W + 120) {
        if (pose.crashed) {
          drawBike(gsx, baseYForLane(pose.lane), 0.25, gscale, 0.5);
          if (pose.riderX !== null) drawRiderRunning(pose.riderX - game.cameraX, baseYForLane(pose.lane), gscale, 0.5);
        } else {
          drawBike(gsx, pose.y, pose.angle, gscale, 0.5);
        }
        ctx.fillStyle = 'rgba(255,255,255,0.85)';
        ctx.font = 'bold 13px Arial';
        ctx.textAlign = 'center';
        ctx.fillText(`GHOST ${racingGhost.name}`, gsx, pose.y - 58 * gscale);
        ctx.textAlign = 'left';
      }
    }
  }

  if (game.state === GameState.CRASHED) {
    // Bike lying ahead, rider running back to it.
    drawBike(player.crashBikeX - game.cameraX, baseYForLane(player.laneFloat), 0.25, scale);
    drawRiderRunning(player.crashRiderX - game.cameraX, baseYForLane(player.laneFloat), scale);
  } else {
    drawBike(screenX, player.y, player.angle, scale);
  }

  if (game.state === GameState.TITLE_SCREEN) {
    drawOverlay('DIRT BIKE RACER', [
      'Arrow Up / Down: change lane',
      'Z: accelerate   X: turbo (watch TEMP!)',
      'Left / Right in air: pitch your landing',
      '',
      'Press Enter to start  •  Press E for the track editor',
    ]);
  } else if (game.state === GameState.CRASHED) {
    drawOverlay('CRASHED!', ['Mash Z / X to run back to your bike!']);
  } else if (game.state === GameState.OVERHEATED) {
    drawOverlay('OVERHEATED!', ['Engine cooling down... hold on.']);
  } else if (game.state === GameState.FINISHED) {
    const lines = [`Final time: ${formatTime(game.finalTime)}`];
    if (game.ghostResult) {
      lines.push(game.ghostResult.beat
        ? `You beat ${game.ghostResult.opponentName} by ${game.ghostResult.delta.toFixed(2)}s!`
        : `Lost to ${game.ghostResult.opponentName} by ${game.ghostResult.delta.toFixed(2)}s.`);
      lines.push(`Ghost time: ${formatTime(game.ghostResult.opponentTime)}`);
    }
    lines.push('', 'Press Enter or R to race again');
    drawOverlay('FINISHED!', lines);
  }
}

// --------------------------------------------------------------------------
// 8. HUD (DOM, updated once per frame)
// --------------------------------------------------------------------------
const hudTime = document.getElementById('hud-time');
const hudSpeed = document.getElementById('hud-speed');
const hudLane = document.getElementById('hud-lane');
const hudGhost = document.getElementById('hud-ghost');
const tempFill = document.getElementById('temp-fill');
const stateNote = document.getElementById('state-note');

function formatTime(t) {
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  const cs = Math.floor((t % 1) * 100);
  return `${m}:${String(s).padStart(2, '0')}.${String(cs).padStart(2, '0')}`;
}

// HUD writes are cached: the original code assigned every textContent and
// the TEMP width on every frame (60/s), even when nothing had changed.
// Assigning textContent still costs a DOM write, so only write on change.
const hudCache = {};
function setHudText(el, key, value) {
  if (!el || hudCache[key] === value) return;
  hudCache[key] = value;
  el.textContent = value;
}

function updateHUD() {
  setHudText(hudTime, 'time', formatTime(game.lapTime));
  setHudText(hudSpeed, 'speed', `${player.speedMph} mph`);
  setHudText(hudLane, 'lane', String(player.targetLane + 1));
  if (hudGhost) {
    let ghostText = '—';
    if (racingGhost && (game.state === GameState.PLAYING || game.state === GameState.CRASHED || game.state === GameState.OVERHEATED)) {
      const gt = ghostTimeAtX(playerBikeX());
      if (gt !== null) {
        const d = game.lapTime - gt;
        ghostText = d < -0.005 ? `Ahead ${Math.abs(d).toFixed(2)}s`
          : d > 0.005 ? `Behind ${d.toFixed(2)}s` : 'Even';
      }
    } else if (racingGhost && game.state === GameState.FINISHED && game.ghostResult) {
      ghostText = game.ghostResult.beat ? `Won by ${game.ghostResult.delta.toFixed(2)}s` : `Lost by ${game.ghostResult.delta.toFixed(2)}s`;
    }
    setHudText(hudGhost, 'ghost', ghostText);
  }
  const tempWidth = `${player.heat}%`;
  if (hudCache.temp !== tempWidth) { hudCache.temp = tempWidth; tempFill.style.width = tempWidth; }
  tempFill.classList.toggle('hot', player.heat >= HEAT_HOT_AT);
  tempFill.classList.toggle('warm', player.heat >= HEAT_WARM_AT && player.heat < HEAT_HOT_AT);
  stateNote.textContent = {
    [GameState.TITLE_SCREEN]: 'Press Enter to start  •  Press E for the track editor',
    [GameState.PLAYING]: 'Z = go  •  X = turbo  •  Land flat or crash!',
    [GameState.CRASHED]: 'Mash Z / X to run back to your bike!',
    [GameState.OVERHEATED]: 'Overheated — cooling down...',
    [GameState.FINISHED]: `Finished in ${formatTime(game.finalTime)} — press Enter or R to race again`,
    [GameState.EDITOR]: 'Track editor — click the canvas to place, right-click to delete, Esc to exit',
  }[game.state];
}

// --------------------------------------------------------------------------
// 9. Main game loop — delta time, clamped so a slow frame can't tunnel
//    the bike through a ramp or the finish line.
// --------------------------------------------------------------------------
function update(dt) {
  if (input.justPressed.has('Enter') || input.justPressed.has('Space') || input.justPressed.has('KeyR')) {
    if (game.state === GameState.TITLE_SCREEN || game.state === GameState.FINISHED) {
      startGame();
    }
  }
  if (input.justPressed.has('KeyE')) {
    if (game.state === GameState.TITLE_SCREEN || game.state === GameState.FINISHED) {
      enterEditor();
    }
  }
  if (input.justPressed.has('Escape') && game.state === GameState.EDITOR) {
    exitEditor();
  }
  if (game.state === GameState.EDITOR) {
    // Editor camera scroll; lane keys are not consumed here, so the
    // player does not also change lane when you leave the editor.
    if (input.keys.has('ArrowLeft')) game.editorCameraX = Math.max(0, game.editorCameraX - EDITOR_KEY_SCROLL_SPEED * dt);
    if (input.keys.has('ArrowRight')) game.editorCameraX = Math.min(TRACK_LENGTH - W, game.editorCameraX + EDITOR_KEY_SCROLL_SPEED * dt);
    return;
  }

  if (game.state === GameState.PLAYING) {
    game.lapTime += dt;
    player.update(dt, track);
    // Camera keeps the rider left-of-centre so you can see what's coming.
    game.cameraX = Math.max(0, player.x - CAMERA_OFFSET_X);
    sampleRecording(dt);
    if (game.state === GameState.FINISHED) finishRecording();
  } else if (game.state === GameState.CRASHED) {
    game.lapTime += dt; // crashes cost time — that is the penalty
    player.updateCrashed(dt);
    game.cameraX = Math.max(0, player.crashBikeX - CAMERA_OFFSET_X);
    sampleRecording(dt);
  } else if (game.state === GameState.OVERHEATED) {
    game.lapTime += dt;
    game.overheatTimer -= dt;
    player.heat = Math.max(0, player.heat - (100 / OVERHEAT_COOLDOWN) * dt);
    if (game.overheatTimer <= 0) {
      player.heat = 0;
      game.state = GameState.PLAYING;
    }
    sampleRecording(dt);
  }
}

let lastTime = performance.now();
function frame(now) {
  requestAnimationFrame(frame);
  const dt = Math.min((now - lastTime) / 1000, 0.033); // clamp to ~30fps steps
  lastTime = now;
  update(dt);
  render();
  updateHUD();
  // Consume per-frame input after the update that used it.
  input.justPressed.clear();
  if (game.state !== GameState.CRASHED) input.mashPending = 0;
}

requestAnimationFrame(frame);
