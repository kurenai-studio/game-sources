export const FIELD_WIDTH = 900;
export const FIELD_HEIGHT = 560;
export const STAR_COUNT = 7;
export const HAZARD_COUNT = 5;
export const SHOT_LIMIT = 8;
export const MAX_SLING = 235;
export const MIN_SLING = 18;

const STAR_RADIUS = 18;
const DOCK_RADIUS = 32;
const SAFE_MARGIN = 54;

const FIELD_NAMES = [
  "Copper Ladder",
  "Mint Wake",
  "Signal Reef",
  "Amber Switch",
  "Velvet Relay",
  "Quartz Drift",
  "Solar Notch",
  "Prism Bend"
];

export function createDailyField(dateKey = shanghaiDateKey(new Date())) {
  const normalizedDate = normalizeDateKey(dateKey);
  const seed = seedFromString(`star-sling:${normalizedDate}`);

  for (let attempt = 0; attempt < 160; attempt += 1) {
    const rng = mulberry32(seed + attempt * 9973);
    const field = buildField({ rng, seed, attempt, dateKey: normalizedDate });
    const solved = simulatePlan(field, plannedTargets(field));

    if (
      solved.docked &&
      solved.collected.size === field.stars.length &&
      solved.shots.length <= SHOT_LIMIT &&
      solved.heat === 0
    ) {
      return {
        ...field,
        possibleScore: solved.score,
        par: solved.shots.length
      };
    }
  }

  throw new Error(`could not create a playable field for ${normalizedDate}`);
}

export function initialRunState(field) {
  return {
    active: false,
    done: false,
    docked: false,
    position: { ...field.launcher },
    score: 0,
    heat: 0,
    shots: [],
    collected: new Set(),
    message: "Press Start Round."
  };
}

export function startRun(field) {
  return {
    ...initialRunState(field),
    active: true,
    message: "Drag from the core and release."
  };
}

export function applySling(field, state, vector) {
  if (!state.active || state.done) return state;

  const length = magnitude(vector);
  if (length < MIN_SLING) {
    return {
      ...state,
      message: "Longer sling needed."
    };
  }

  const start = { ...state.position };
  const travel = Math.min(MAX_SLING, length);
  const unit = normalize(vector);
  const rawEnd = {
    x: start.x + unit.x * travel,
    y: start.y + unit.y * travel
  };
  const end = {
    x: clamp(rawEnd.x, SAFE_MARGIN, FIELD_WIDTH - SAFE_MARGIN),
    y: clamp(rawEnd.y, SAFE_MARGIN, FIELD_HEIGHT - SAFE_MARGIN)
  };
  const rimPenalty = distance(rawEnd, end) > 0.5 ? 85 : 0;
  const nextCollected = new Set(state.collected);
  const starsCollected = [];

  for (const star of field.stars) {
    if (nextCollected.has(star.id)) continue;
    const gap = distancePointToSegment(star, start, end);
    if (gap <= star.radius + 14) {
      nextCollected.add(star.id);
      starsCollected.push(star.id);
    }
  }

  const hazardHits = field.hazards.filter((hazard) => {
    return distancePointToSegment(hazard, start, end) <= hazard.radius + 7;
  });
  const nextHeat = Math.min(3, state.heat + hazardHits.length);
  const allStars = nextCollected.size === field.stars.length;
  const reachedDock = allStars && distancePointToSegment(field.dock, start, end) <= field.dock.radius + 18;
  const finalEnd = reachedDock ? { ...field.dock } : end;
  const nextShotNumber = state.shots.length + 1;
  const shot = {
    number: nextShotNumber,
    start,
    end: finalEnd,
    requestedEnd: end,
    vector: { x: unit.x * travel, y: unit.y * travel },
    length: Math.round(travel),
    starsCollected,
    hazardHits: hazardHits.map((hazard) => hazard.id),
    rimPenalty,
    docked: reachedDock
  };

  const shotScore =
    starsCollected.length * 235 +
    (reachedDock ? 780 : 0) +
    Math.round(travel / 3) +
    (starsCollected.length > 1 ? 95 : 0) -
    hazardHits.length * 170 -
    rimPenalty;
  const score = Math.max(0, state.score + shotScore);
  const done = reachedDock || nextHeat >= 3 || nextShotNumber >= SHOT_LIMIT;
  const message = buildMessage({ reachedDock, allStars, hazardHits, starsCollected, nextHeat, done });

  return {
    ...state,
    active: !done,
    done,
    docked: reachedDock,
    position: finalEnd,
    score,
    heat: nextHeat,
    shots: [...state.shots, shot],
    collected: nextCollected,
    message
  };
}

export function simulatePlan(field, targets) {
  let state = startRun(field);
  for (const target of targets) {
    if (state.done) break;
    state = applySling(field, state, {
      x: target.x - state.position.x,
      y: target.y - state.position.y
    });
  }
  return state;
}

export function plannedTargets(field) {
  return [...field.stars.map((star) => ({ x: star.x, y: star.y })), { x: field.dock.x, y: field.dock.y }];
}

export function projectedEndpoint(position, vector) {
  const length = magnitude(vector);
  if (length < MIN_SLING) return { ...position };
  const travel = Math.min(MAX_SLING, length);
  const unit = normalize(vector);
  return {
    x: clamp(position.x + unit.x * travel, SAFE_MARGIN, FIELD_WIDTH - SAFE_MARGIN),
    y: clamp(position.y + unit.y * travel, SAFE_MARGIN, FIELD_HEIGHT - SAFE_MARGIN)
  };
}

export function gradeFor(score, possibleScore) {
  const ratio = possibleScore > 0 ? score / possibleScore : 0;
  if (ratio >= 0.94) return "S";
  if (ratio >= 0.8) return "A";
  if (ratio >= 0.62) return "B";
  if (ratio >= 0.42) return "C";
  return "D";
}

export function formatShareResult({ dateKey, score, possibleScore, grade, docked, collectedCount, totalStars, shotsUsed }) {
  return [
    `Star Sling ${dateKey}`,
    `${grade} grade`,
    `${score}/${possibleScore} pts`,
    docked ? "docked" : "still drifting",
    `${collectedCount}/${totalStars} stars`,
    `${shotsUsed} shots`
  ].join(" - ");
}

export function shanghaiDateKey(date) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(date);
  const byType = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${byType.year}-${byType.month}-${byType.day}`;
}

export function normalizeDateKey(dateKey) {
  if (typeof dateKey === "string" && /^\d{4}-\d{2}-\d{2}$/.test(dateKey)) {
    return dateKey;
  }
  return shanghaiDateKey(new Date());
}

export function distance(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

export function distancePointToSegment(point, a, b) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lengthSq = dx * dx + dy * dy;
  if (lengthSq === 0) return distance(point, a);
  const t = clamp(((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSq, 0, 1);
  return distance(point, {
    x: a.x + dx * t,
    y: a.y + dy * t
  });
}

function buildField({ rng, seed, attempt, dateKey }) {
  const launcher = {
    x: 104,
    y: randomInt(rng, 330, 450)
  };
  const dock = {
    id: "dock",
    x: 792,
    y: randomInt(rng, 132, 410),
    radius: DOCK_RADIUS
  };
  const phase = rng() * Math.PI * 2;
  const points = [launcher];
  const stars = [];

  for (let index = 1; index <= STAR_COUNT; index += 1) {
    const t = index / (STAR_COUNT + 1);
    const x = lerp(launcher.x, dock.x, t) + randomFloat(rng, -18, 24);
    const wave =
      Math.sin(t * Math.PI * 2 + phase) * randomFloat(rng, 52, 78) +
      Math.sin(t * Math.PI * 3 + phase * 0.7) * 24;
    const y = clamp(lerp(launcher.y, dock.y, t) + wave + randomFloat(rng, -18, 18), 84, 484);
    const star = {
      id: `s${index}`,
      x: Math.round(x),
      y: Math.round(y),
      radius: STAR_RADIUS,
      value: 235
    };
    stars.push(star);
    points.push(star);
  }
  points.push(dock);

  const maxStep = Math.max(...points.slice(1).map((point, index) => distance(points[index], point)));
  const minStep = Math.min(...points.slice(1).map((point, index) => distance(points[index], point)));
  if (maxStep > MAX_SLING - 14 || minStep < 42) {
    return buildField({ rng: mulberry32(seed + attempt * 19937 + 31), seed, attempt: attempt + 1, dateKey });
  }

  const hazards = [];
  let hazardAttempts = 0;
  while (hazards.length < HAZARD_COUNT && hazardAttempts < 600) {
    hazardAttempts += 1;
    const hazard = {
      id: `h${hazards.length + 1}`,
      x: randomInt(rng, 188, 744),
      y: randomInt(rng, 92, 470),
      radius: randomInt(rng, 26, 39)
    };

    const awayFromSolution = points.slice(1).every((point, index) => {
      const previous = points[index];
      return distancePointToSegment(hazard, previous, point) > hazard.radius + 34;
    });
    const awayFromObjects = [...stars, dock, launcher, ...hazards].every((item) => {
      return distance(hazard, item) > hazard.radius + (item.radius || 24) + 26;
    });

    if (awayFromSolution && awayFromObjects) hazards.push(hazard);
  }

  return {
    dateKey,
    seed,
    name: FIELD_NAMES[Math.floor(rng() * FIELD_NAMES.length)],
    width: FIELD_WIDTH,
    height: FIELD_HEIGHT,
    launcher,
    dock,
    stars,
    hazards,
    shotLimit: SHOT_LIMIT,
    maxSling: MAX_SLING
  };
}

function buildMessage({ reachedDock, allStars, hazardHits, starsCollected, nextHeat, done }) {
  if (reachedDock) return "Docked with a full constellation.";
  if (nextHeat >= 3) return "Heat overload ended the round.";
  if (done) return allStars ? "Out of shots near the dock." : "Out of shots before docking.";
  if (hazardHits.length > 0) return "Red field hit. Heat rising.";
  if (starsCollected.length > 1) return "Clean multi-star sling.";
  if (starsCollected.length === 1) return "Star caught.";
  return "Line up the next sling.";
}

function seedFromString(value) {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function mulberry32(seed) {
  return function next() {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function normalize(vector) {
  const length = magnitude(vector);
  if (length === 0) return { x: 0, y: 0 };
  return { x: vector.x / length, y: vector.y / length };
}

function magnitude(vector) {
  return Math.hypot(vector.x, vector.y);
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function randomInt(rng, min, max) {
  return Math.floor(randomFloat(rng, min, max + 1));
}

function randomFloat(rng, min, max) {
  return min + (max - min) * rng();
}
