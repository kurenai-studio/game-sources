#!/usr/bin/env node
/**
 * Generate one markdown document per level from the content in `assets/data/`.
 *
 *     node tools/build-level-docs.js            # write docs/levels/<levelId>.md
 *     node tools/build-level-docs.js --check    # write nothing; exit 1 if anything would change
 *
 * The JSON is the source and the document is generated from it — phase 11d's decision, taken
 * because a document describing a level and a JSON defining it are two copies of one truth and one
 * of them always rots. `docs/plan/11d-per-level-document/document-contract.md` decides what the
 * document contains, section by section, and refuses the rest; this file implements exactly that
 * list. A section here the contract does not name is a bug in one of the two.
 *
 * No third-party dependency, per the precedent `docs/design/atlas/build-atlas.js` set: Node
 * built-ins only, so CI needs nothing installed.
 *
 * THE OUTPUT MUST BE A PURE FUNCTION OF THE CONTENT. `.github/workflows/ci.yml` regenerates and
 * fails if the working tree changes, which is the whole mechanism of the phase, and it dies the
 * moment the output carries anything the content does not determine. So: no timestamp, no git
 * hash, no version line, no absolute path, and every iteration over a collection is over an
 * explicitly ordered one. That is the constraint the contract's "Mechanical requirements" section
 * lists first, and the reason it lists it first.
 *
 * This is the second reader of the content after `game/adapter/content/JsonContentSource.java`, and
 * it deliberately does not reimplement that parser's validation — it resolves ids and dies on one it
 * cannot resolve. A document that printed a blank for a broken id would be a worse liar than a crash.
 */

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DATA = path.join(ROOT, 'assets', 'data');
const OUT_DIR = path.join(ROOT, 'docs', 'levels');

/**
 * Constants that live in `core/` rather than in `assets/data/`, each carrying the file it came from.
 * The document prints that file beside the value, because these are the one thing regenerating
 * cannot keep honest: the text is identical whether or not the Java still says this. Sections 9, 10,
 * 11 and 12 of the contract are where a reader has to be able to tell a fact from content from a
 * fact from code, and this is how.
 */
const CODE = {
  playfieldWidth: { value: 208, from: '`core/domain/system/MotionSystem.java:57`' },
  playfieldHeight: { value: 270, from: '`core/domain/system/SpawnSystem.java:92`' },
  safetyMargin: { value: 128, from: '`core/domain/system/LifetimeSystem.java:77`' },
  enemyProjectileRadius: { value: 2.0, from: '`core/domain/system/EnemyWeaponSystem.java:35`' },
  patterns: { value: ['straight-single'], from: '`core/domain/system/EnemyWeaponSystem.java:37,86`' },
  boss: {
    from: '`core/domain/system/BossSystem.java:74-89,140-151`',
    spreadVxRatios: [0.25, 0.45, 0.70],
    spreadVyRatio: -0.90,
    sweepVxRatios: [0.55, 0.75, 0.95],
    sweepVyRatio: -0.65,
    coreKeelRadius: 13.0,
    coreKeelOffsetY: -27.0,
    parts: 6,
  },
};

/**
 * The six drop kinds `PickupSystem` recognises, and what each does. There is no `drops.json`: these
 * are `public static final String` constants, and `SpawnSystem.requireRecognisedDrop` rejects
 * anything else the moment a wave carrying it spawns.
 */
const DROP_KINDS = [
  ['weapon-upgrade', "raises the player's shot level by one, up to `weaponLevels`"],
  ['shield', 'grants a shield, if the player does not already have one'],
  ['extra-life', 'one more life, up to `maxLives`'],
  ['bomb-recharge', 'one more bomb, up to `maxBombs`'],
  ['invulnerability', 'grace time set — not added — to `invulnerabilityPickupDuration`'],
  ['attachment', 'equips an attachment; the only kind that is content-driven, through `assets/data/attachments.json`'],
];
const DROP_KINDS_FROM = '`core/domain/system/PickupSystem.java:39-71`';

// ------------------------------------------------------------------------------------------------
// Reading

function die(message) {
  process.stderr.write(`build-level-docs: ${message}\n`);
  process.exit(2);
}

function readJson(name) {
  const file = path.join(DATA, name);
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (e) {
    return die(`cannot read ${path.relative(ROOT, file)}: ${e.message}`);
  }
}

function index(rows, kind) {
  const byId = new Map();
  for (const row of rows) {
    if (byId.has(row.id)) die(`two ${kind} share the id '${row.id}'`);
    byId.set(row.id, row);
  }
  return byId;
}

/** Resolving, not looking up: an id that does not resolve stops the generator. See the file header. */
function resolve(byId, id, kind, context) {
  const row = byId.get(id);
  if (row === undefined) {
    die(`${context || 'somewhere'}: no ${kind} with the id '${id}' exists in assets/data/`);
  }
  return row;
}

// ------------------------------------------------------------------------------------------------
// Trajectory resolution. `trajectories.json` mixes three authored kinds (`constant`, `arc`, `path`,
// the last in either `segments` or `waypoints` form) with two derivations (`mirrorOf`, `speedOf`)
// that name another entry instead of a `type`. `JsonContentSource` resolves all five into a uniform
// shape at load time — this section reproduces exactly that arithmetic, not a second definition of
// it, so a `path`'s document is generated from the same numbers `SpawnSystem` will actually fly.
//
// The result of resolving every id in the file is a `Map` from id to one of three uniform shapes:
//   { id, kind: 'constant', vx, vy }
//   { id, kind: 'arc', vx, vy, ay }
//   { id, kind: 'path', segments: [{vx, vy, duration}, ...], loopStart, loopCount }
// A `path`'s `segments` are already resolved velocities and durations regardless of whether the
// entry was authored with `segments` or `waypoints` — see `resolveWaypointsField`, which turns each
// leg into exactly the `PathSegment(vx, vy, duration)` `JsonContentSource.parseWaypoints` builds.
// Everywhere downstream that used to read `t.type` now reads `t.kind`, and `t.vx`/`t.vy`/`t.ay` stay
// meaningful only for `constant`/`arc` — a `path` has no single velocity, by construction.

/**
 * Parses one `trajectories.json` entry that carries a `type` (or defaults to `constant`) into its
 * uniform shape. Mirrors `JsonContentSource.parseTrajectory` — this file deliberately does not
 * reimplement its full validation (missing keys, playfield bounds on a waypoint, a non-positive
 * duration): a malformed entry is caught by the real loader long before this tool would see it in
 * CI, and duplicating that validation here is exactly the second-definition risk this task's plan
 * warns against. What this function must get right is the arithmetic, not the guardrails.
 */
function parseTrajectoryEntry(entry, id) {
  const type = entry.type || 'constant';
  if (type === 'constant') return { id, kind: 'constant', vx: entry.vx, vy: entry.vy };
  if (type === 'arc') return { id, kind: 'arc', vx: entry.vx, vy: entry.vy, ay: entry.ay };
  if (type === 'path') {
    const hasSegments = entry.segments !== undefined;
    const hasWaypoints = entry.waypoints !== undefined;
    if (hasSegments === hasWaypoints) {
      return die(`assets/data/trajectories.json: trajectory '${id}' must declare exactly one of `
        + `'segments' or 'waypoints', had ${hasSegments ? 'both' : 'neither'}`);
    }
    const segments = hasSegments
      ? resolveSegmentsField(entry.segments)
      : resolveWaypointsField(entry.waypoints, id);
    const loopStart = entry.loopStart !== undefined ? entry.loopStart : segments.length;
    const loopCount = entry.loopCount !== undefined ? entry.loopCount : 1;
    const result = { id, kind: 'path', segments, loopStart, loopCount };
    // Only a `waypoints`-authored path carries an authoring origin — `segments` is written as
    // deltas from wherever it is placed and has no absolute position to check against. `entryX` is
    // the first waypoint's `x`, the value `atX * 208` must equal for this path to land where it was
    // written for (see requiredAtXFor / the atX check in section 13).
    if (hasWaypoints) result.entryX = entry.waypoints[0].x;
    return result;
  }
  return die(`assets/data/trajectories.json: trajectory '${id}' has an unknown type '${type}'`);
}

/** A `path`'s `segments` array: a `{"wait": s}` shorthand becomes `{vx:0, vy:0, duration:s}`, exactly
 * as `JsonContentSource.parseSegments` translates it — a wait is a segment with no velocity, not a
 * distinct kind `core` ever sees. */
function resolveSegmentsField(segmentsValue) {
  return segmentsValue.map((seg) => (seg.wait !== undefined
    ? { vx: 0, vy: 0, duration: seg.wait }
    : { vx: seg.vx, vy: seg.vy, duration: seg.duration }));
}

/**
 * A `path`'s `waypoints` array, turned into the same `{vx, vy, duration}` legs `resolveSegmentsField`
 * produces — mirrors `JsonContentSource.parseWaypoints`: each leg's direction is `normalize(B - A)`
 * and its duration is `|B - A| / speed`. The first waypoint is the entry point and carries no leg of
 * its own; a `{"wait": s}` waypoint pauses without moving, same shorthand as `segments`.
 */
function resolveWaypointsField(waypointsValue, id) {
  const segments = [];
  let fromX = waypointsValue[0].x;
  let fromY = waypointsValue[0].y;
  for (let i = 1; i < waypointsValue.length; i++) {
    const point = waypointsValue[i];
    if (point.wait !== undefined) {
      segments.push({ vx: 0, vy: 0, duration: point.wait });
      continue;
    }
    const dx = point.x - fromX;
    const dy = point.y - fromY;
    const distance = Math.sqrt(dx * dx + dy * dy);
    const duration = distance / point.speed;
    segments.push({ vx: dx / duration, vy: dy / duration, duration });
    fromX = point.x;
    fromY = point.y;
  }
  return segments;
}

/**
 * Builds the mirror of an already-resolved trajectory: negate every horizontal component, keep every
 * vertical field and every duration or loop parameter. Mirrors `JsonContentSource.mirror`.
 *
 * **An absolute path's `entryX` mirrors too, and not by negation** — negating a coordinate is not
 * reflecting it. Mirroring reflects the whole path across the playfield's own centre, so the mirrored
 * entry point is `width - entryX`, the same reflection 11j's shipped mirror pairs already show:
 * `descend-and-turn-left`/`-right` sit at `atX 0.85`/`0.15`, and `0.85 + 0.15 = 1.00`. A path mirrored
 * from a relative (`segments`-authored) one carries no `entryX` and stays that way — there is nothing
 * absolute to reflect.
 */
function mirrorTrajectory(id, t) {
  if (t.kind === 'constant') return { id, kind: 'constant', vx: -t.vx, vy: t.vy };
  if (t.kind === 'arc') return { id, kind: 'arc', vx: -t.vx, vy: t.vy, ay: t.ay };
  const result = {
    id,
    kind: 'path',
    segments: t.segments.map((s) => ({ vx: -s.vx, vy: s.vy, duration: s.duration })),
    loopStart: t.loopStart,
    loopCount: t.loopCount,
  };
  if (t.entryX !== undefined) result.entryX = CODE.playfieldWidth.value - t.entryX;
  return result;
}

/**
 * Builds the same trajectory traversed `multiplier` times sooner: velocities scale by `multiplier`
 * and durations divide by it, except an `arc`'s `ay`, which takes the *square* of the multiplier —
 * `x = vx t`, `y = vy t + ay t²/2`, and substituting `t -> t/k` needs `k² · ay` to keep the same
 * parabola walked sooner. Mirrors `JsonContentSource.faster`; this is exactly the trap 11j's status
 * fragment names: a linear scale on `ay` produces a different, still-plausible-looking parabola.
 */
function fasterTrajectory(id, t, multiplier) {
  if (t.kind === 'constant') return { id, kind: 'constant', vx: t.vx * multiplier, vy: t.vy * multiplier };
  if (t.kind === 'arc') {
    return {
      id, kind: 'arc', vx: t.vx * multiplier, vy: t.vy * multiplier, ay: t.ay * multiplier * multiplier,
    };
  }
  const result = {
    id,
    kind: 'path',
    segments: t.segments.map((s) => (
      { vx: s.vx * multiplier, vy: s.vy * multiplier, duration: s.duration / multiplier })),
    loopStart: t.loopStart,
    loopCount: t.loopCount,
  };
  // Scaling speed does not move the entry point — same reasoning as leaving `ay`'s sign or a
  // `constant`'s direction alone, just for a field this function otherwise never touches.
  if (t.entryX !== undefined) result.entryX = t.entryX;
  return result;
}

/**
 * Resolves every id in `trajectories.json` into its uniform shape, in one pass regardless of
 * declaration order — a `mirrorOf`/`speedOf` may point at an entry written later in the file, or at
 * another derivation, exactly as `JsonContentSource.resolveDerived` allows. Lazy and memoised: each
 * id is resolved on first need and cached, with `resolving` as the in-progress chain so a cycle
 * (`a` mirrors `b` mirrors `a`) dies naming the chain instead of recursing forever.
 */
function resolveTrajectories(rawById) {
  const resolved = new Map();
  const resolving = [];

  function resolveOne(id) {
    if (resolved.has(id)) return resolved.get(id);
    const entry = rawById.get(id);
    if (entry === undefined) {
      return die(`assets/data/trajectories.json: trajectory derives from unknown trajectory '${id}'`);
    }
    if (resolving.includes(id)) {
      return die(`assets/data/trajectories.json: trajectory derivation cycle: `
        + `${resolving.join(' -> ')} -> ${id}`);
    }
    resolving.push(id);
    let built;
    if (entry.mirrorOf !== undefined) {
      built = mirrorTrajectory(id, resolveOne(entry.mirrorOf));
    } else if (entry.speedOf !== undefined) {
      built = fasterTrajectory(id, resolveOne(entry.speedOf), entry.multiplier);
    } else {
      built = parseTrajectoryEntry(entry, id);
    }
    resolving.pop();
    resolved.set(id, built);
    return built;
  }

  for (const id of rawById.keys()) resolveOne(id);
  return resolved;
}

// ------------------------------------------------------------------------------------------------
// Formatting. Fixed everywhere, so two runs on two Node versions produce the same bytes.

const s1 = (n) => n.toFixed(1);
const s2 = (n) => n.toFixed(2);
const padL = (text, width) => String(text).padStart(width);
const padR = (text, width) => String(text).padEnd(width);

function table(headers, rows) {
  const out = [`| ${headers.join(' | ')} |`, `|${headers.map(() => '---').join('|')}|`];
  for (const row of rows) out.push(`| ${row.join(' | ')} |`);
  return out.join('\n');
}

// ------------------------------------------------------------------------------------------------
// Derivation

/** One entity per formation slot, per `SpawnSystem.spawnWave`. */
function entitiesOf(spawn, formations) {
  return resolve(formations, spawn.formation, 'formation', `spawn '${spawn.spawn}'`).slots.length;
}

/**
 * The shape an entity actually flies: the spawn's own `trajectory` when it has one, otherwise the
 * archetype's `motion.trajectory`. The key is optional and overrides the default
 * (`core/port/SpawnEvent.java`, `core/domain/system/SpawnSystem.java`).
 */
function trajectoryOf(spawn, enemy) {
  if (spawn.trajectory) return { id: spawn.trajectory, override: true };
  const motion = enemy.components && enemy.components.motion;
  if (!motion || !motion.trajectory) {
    die(`archetype '${enemy.id}' has no motion.trajectory and no spawn overrides it`);
  }
  return { id: motion.trajectory, override: false };
}

/**
 * Absolute start and end of every placement, in level order. A `fixedDuration` wave's end is
 * arithmetic; a `cleared` wave's is not, and from the first one onwards every later time is a lower
 * bound rather than a value. The document must say which — this is the one place a generated
 * document could lie by rounding a decision away.
 */
function timeline(level, waves) {
  const rows = [];
  let cursor = 0;
  let exact = true;
  level.waves.forEach((placement, i) => {
    const wave = resolve(waves, placement.wave, 'wave', `placement ${i + 1} of the level`);
    const start = cursor + placement.offset;
    const fixed = wave.end.type === 'fixedDuration';
    const duration = fixed ? wave.end.seconds : null;
    const end = fixed ? start + duration : null;
    rows.push({ i, placement, wave, start, end, duration, exact });
    if (!fixed) exact = false;
    cursor = fixed ? end : start;
  });
  return { rows, exact };
}

/** Horizontal extent a spawn occupies, collider radius included. Nothing clamps this at runtime. */
function footprint(spawn, enemy, formations) {
  const formation = resolve(formations, spawn.formation, 'formation', `spawn '${spawn.spawn}'`);
  const radius = enemy.components.collider ? enemy.components.collider.radius : 0;
  const anchor = spawn.atX * CODE.playfieldWidth.value;
  let min = Infinity;
  let max = -Infinity;
  for (const slot of formation.slots) {
    min = Math.min(min, anchor + slot.offsetX - radius);
    max = Math.max(max, anchor + slot.offsetX + radius);
  }
  return { min, max, offScreen: min < 0 || max > CODE.playfieldWidth.value };
}

/**
 * How far a spawn's `atX * 208` may sit from an absolute path's authoring origin before it is a
 * misplacement rather than authoring noise. Issue #300.
 *
 * `atX` is authored to two decimals, so the closest it can land to a given `entryX` by rounding
 * alone is half of one hundredth of the playfield width: `208 * 0.005 = 1.04` screen units. Anything
 * past that is not rounding — it is a different number. `1.1` gives that a little headroom without
 * widening it enough to miss a real one-hundredth-of-`atX` mistake, which would be at least `2.08`
 * units away.
 */
const ATX_TOLERANCE_PX = 1.1;

/**
 * The `atX` an absolutely-authored `path` requires, or `null` for anything else — a `constant`, an
 * `arc`, or a `path` authored with `segments`, which is written as deltas from wherever it is placed
 * and has no absolute position to be checked against. `SpawnSystem.positionSpawned` puts the anchor
 * at `atX * 208` and an absolute path only ever adds deltas to that, so the entry waypoint's `x` is
 * the position the wave's `atX` must reproduce, not a position `core` itself reads.
 */
function requiredAtX(traj) {
  if (traj.kind !== 'path' || traj.entryX === undefined) return null;
  return traj.entryX / CODE.playfieldWidth.value;
}

/**
 * The extent an entity actually sweeps, not the one it starts at. Every shape with a non-zero `vx`
 * drifts out from under the spawn-instant figure — 11c's `veer-left`/`veer-right` (since replaced,
 * #328) were two trajectories built to do exactly that: a `veer-right` at `atX 0.85` printed in range
 * and spent its whole arc off screen. Found by task 4's read-back (#186, correction C3) by writing the
 * spawn and looking, which the spawn-instant check could not have found by reading.
 *
 * A `constant` sweeps `|vx| * screenTime`. An `arc` has the same `vx`, so it sweeps for as long as it
 * is anywhere near the playfield — bounded here by the flight down to the safety box, since
 * `LifetimeSystem` is what finally removes it.
 */
function sweptExtent(spawn, enemy, formations, trajectories) {
  const at = footprint(spawn, enemy, formations);
  const traj = resolve(trajectories, trajectoryOf(spawn, enemy).id, 'trajectory', `spawn '${spawn.spawn}'`);
  const radius = enemy.components.collider ? enemy.components.collider.radius : 0;
  const width = CODE.playfieldWidth.value;

  if (traj.kind === 'path') {
    const { seconds, minDrift, maxDrift } = pathSweep(traj, radius, at);
    const min = at.min + minDrift;
    const max = at.max + maxDrift;
    const span = max - min;
    const outside = Math.max(0, -min) + Math.max(0, max - width);
    return {
      min, max, seconds, drift: maxDrift, offScreen: min < 0 || max > width,
      outsideFraction: span === 0 ? 0 : Math.min(1, outside / span),
    };
  }

  const seconds = traj.kind === 'arc'
    ? arcPlayfieldTime(traj, radius)
    : screenTime(traj, radius);
  if (seconds === null || traj.vx === 0) return { ...at, min: at.min, max: at.max, seconds, drift: 0 };
  const drift = traj.vx * seconds;
  const min = Math.min(at.min, at.min + drift);
  const max = Math.max(at.max, at.max + drift);
  // How much of the sweep is spent outside the playfield, as a fraction of the whole sweep.
  const span = max - min;
  const outside = Math.max(0, -min) + Math.max(0, max - width);
  return { min, max, seconds, drift, offScreen: min < 0 || max > width,
    outsideFraction: span === 0 ? 0 : Math.min(1, outside / span) };
}

/**
 * Expands a resolved `path` into the finite leg sequence it actually flies: the prefix once, then
 * the `[loopStart, segments.length)` range repeated `loopCount` times in full — mirrors
 * `PathTrajectoryDefinition.segmentAt`'s own accounting, so the last leg of this list is always the
 * same leg `core` extrapolates forever once the authored time runs out (rule 3 guarantees it moves).
 */
function expandPathLegs(traj) {
  const legs = traj.segments.slice(0, traj.loopStart);
  const loopRange = traj.segments.slice(traj.loopStart);
  if (loopRange.length > 0) {
    for (let i = 0; i < traj.loopCount; i++) legs.push(...loopRange);
  }
  return legs;
}

/**
 * A compact, in-order description of a resolved `path`'s legs, for the "Movement shapes" table —
 * `vx`/`vy`/`ay` describe a single line or a single parabola and have nothing to print for a path,
 * whose legs are the closest equivalent. A leg inside the repeated range (`[loopStart,
 * segments.length)`) is bracketed, and the loop count is noted once at the end, so a reader can tell
 * "this plays once" from "this plays four times" without re-deriving `loopStart`/`loopCount`.
 */
function pathLegSummary(t) {
  const parts = t.segments.map((s, i) => {
    const isWait = s.vx === 0 && s.vy === 0;
    const body = isWait ? `wait ${s2(s.duration)}s` : `vx ${s1(s.vx)}, vy ${s1(s.vy)} for ${s2(s.duration)}s`;
    return i >= t.loopStart ? `[${body}]` : body;
  });
  let summary = parts.join(' → ');
  if (t.loopStart < t.segments.length) summary += ` (loop x${t.loopCount})`;
  return summary;
}

/**
 * Where a leg, held from `(d, h)` for up to `leg.duration`, first carries the entity past a
 * boundary — whichever of the four (top, bottom, left, right) happens soonest — or `null` if none of
 * them does within this leg. `d` is vertical displacement from the spawn point (negative is down,
 * matching `core`'s y-up convention); `h` is horizontal displacement from the spawn anchor. `at` is
 * the formation's footprint at the spawn instant (`footprint()`), so the horizontal check is against
 * the same `[0, width]` rectangle `LifetimeSystem.isFullyOffPlayfield` tests, not a single point.
 *
 * Bottom and top mirror `isFullyOffPlayfield`'s own thresholds exactly: bottom is `-(playfield height
 * + 2*radius)` below the spawn point (`y + radius < 0`, and the spawn sits `radius` above the top
 * edge, so the full drop is `height + 2*radius`); top is back at the spawn height itself (`d = 0`),
 * since the spawn point is already `radius` above the visible edge (`y - radius > height` there,
 * i.e. `d > 0`) — the same symmetry `arcPlayfieldTime`'s "up" root already uses. Left/right compare
 * the footprint's own edges against `0`/`width`, not a bare point, because a formation with slot
 * offsets is wider than its anchor.
 *
 * **The horizontal checks use the trailing edge of the footprint, not the leading one** — the edge
 * that clears the boundary *last*, matching `isFullyOffPlayfield`'s own "every pixel has left"
 * criterion (`x + radius < 0`, `x - radius > width`, both stated against the far side of the
 * circle from the direction of travel). Moving left (`vx < 0`), the footprint's rightmost edge
 * (`at.max`) is the one still on screen after the leftmost edge has already crossed `0`, so it is
 * `at.max + h` that must reach `0`. Moving right, symmetrically, it is the leftmost edge (`at.min`)
 * that lags behind and must reach `width`. Checking the near edge instead (`at.min` going left,
 * `at.max` going right) reports "first touches the boundary", not "fully gone" — issue #314.
 */
function crossLeg(leg, d, h, downTarget, at, width) {
  const candidates = [];
  if (leg.vy < 0 && d > downTarget) candidates.push((downTarget - d) / leg.vy);
  if (leg.vy > 0 && d < 0) candidates.push((0 - d) / leg.vy);
  if (leg.vx < 0 && at.max + h > 0) candidates.push((0 - (at.max + h)) / leg.vx);
  if (leg.vx > 0 && at.min + h < width) candidates.push((width - (at.min + h)) / leg.vx);
  const valid = candidates.filter((tau) => tau >= 0 && tau <= leg.duration + 1e-9);
  const hEnd = h + leg.vx * leg.duration;
  const dEnd = d + leg.vy * leg.duration;
  if (valid.length === 0) return { seconds: null, hEnd, dEnd };
  const tau = Math.min(...valid);
  return { seconds: tau, hEnd: h + leg.vx * tau, dEnd: d + leg.vy * tau };
}

/**
 * How long a resolved `path` spends inside the playfield, and the horizontal range it visits on the
 * way — the two things `constant` gets from `screenTime` and `arc` from `arcPlayfieldTime`, produced
 * here by walking the expanded leg list (`expandPathLegs`) instead of a closed form, since a path's
 * velocity is piecewise constant rather than a single line or a parabola.
 *
 * **Both axes are checked, not only the vertical one `screenTime`/`arcPlayfieldTime` use**, because a
 * path can end on a purely horizontal leg — `hold-the-line-and-exit`'s last leg is exactly this, a
 * slide to the right edge at `vy 0` that would otherwise never trip a vertical-only check and hang
 * this function forever (or divide by zero extrapolating a `vy` of 0). A `constant`/`arc` never needs
 * this because their own vy is never zero by the shapes the catalogue accepts; a `path`'s rule 3 only
 * guarantees *some* nonzero component on its last leg, so this function cannot assume which axis it
 * will be.
 *
 * If no leg in the finite, expanded list crosses a boundary, the last leg's velocity is held forever
 * — the same extrapolation `PathTrajectoryDefinition.segmentAt` performs past the authored duration —
 * and rule 3 guarantees that leg moves on at least one axis, so this always terminates.
 *
 * Returns the running horizontal min/max *displacement from the spawn anchor*, not an absolute
 * position: `sweptExtent` adds them to the spawn-instant footprint, exactly as it already does for
 * `constant`/`arc`'s single `drift` value — the difference here is a path's drift is not monotonic,
 * so both ends of the range are tracked rather than assumed to be the start and the final position.
 */
function pathSweep(traj, radius, at) {
  const legs = expandPathLegs(traj);
  const downTarget = -(CODE.playfieldHeight.value + 2 * radius);
  const width = CODE.playfieldWidth.value;
  let t = 0;
  let d = 0;
  let h = 0;
  let minH = 0;
  let maxH = 0;
  for (const leg of legs) {
    const result = crossLeg(leg, d, h, downTarget, at, width);
    minH = Math.min(minH, h, result.hEnd);
    maxH = Math.max(maxH, h, result.hEnd);
    if (result.seconds !== null) {
      return { seconds: t + result.seconds, minDrift: minH, maxDrift: maxH };
    }
    t += leg.duration;
    d = result.dEnd;
    h = result.hEnd;
  }
  // Every finite leg is spent: extrapolate the last one forever, exactly as core does.
  const last = legs[legs.length - 1];
  const candidates = [];
  if (last.vy < 0) candidates.push((downTarget - d) / last.vy);
  if (last.vy > 0) candidates.push((0 - d) / last.vy);
  if (last.vx < 0) candidates.push((0 - (at.max + h)) / last.vx);
  if (last.vx > 0) candidates.push((width - (at.min + h)) / last.vx);
  // Unreachable in practice: rule 3 (a path's last segment has nonzero velocity) guarantees at
  // least one candidate above. Falling through would mean rule 3 no longer holds for this content.
  const tau = candidates.length ? Math.min(...candidates) : 0;
  const hEnd = h + last.vx * tau;
  minH = Math.min(minH, hEnd);
  maxH = Math.max(maxH, hEnd);
  return { seconds: t + tau, minDrift: minH, maxDrift: maxH };
}

/**
 * How long an `arc` spends inside the playfield. It spawns its own radius above the top edge and
 * descends. What happens next depends on the sign of `ay` — `ArcTrajectoryDefinition`'s own javadoc
 * is explicit that all three are legitimate, and none is clamped or rejected here:
 *
 * - **`ay > 0`** turns at `-vy / ay` and climbs back. Two ways out, and the first one that happens is
 *   the answer: **down**, past the bottom edge — the positive root of `ay/2 t^2 + vy t + (270 + 2r) =
 *   0`, which has none when the apex is shallower than the playfield, i.e. when the shape turns before
 *   reaching the bottom; or **up**, back out of the top it came from, at `-2 vy / ay` by symmetry.
 * - **`ay < 0` steepens instead of turning** — `vy + ay*t` only grows more negative, so the shape never
 *   climbs back and the "up" root above is not a second exit, it is not an exit at all. The same
 *   quadratic's down root is still exactly the time it reaches the bottom (issue #322): with `a = ay/2
 *   < 0`, `-4a` is positive, so the discriminant `vy^2 - 4a*(270+2r)` is `vy^2` plus a positive term
 *   and is never negative — this shape always has a down root, and it is the only one that means
 *   anything.
 * - **`ay = 0` degenerates to a straight run at the fixed `vy`** — `ArcTrajectoryDefinition`'s own
 *   javadoc calls this "a coincidence of the maths, not a reason to route a constant shape through
 *   this record instead", so it is content the catalogue accepts rather than a mistake to flag here.
 *   The quadratic itself divides by zero (`a = 0`), so this is solved as the linear equation it
 *   actually is: `target / |vy|`, mirroring how `screenTime` already treats a `constant`'s `vy`
 *   direction-agnostically. `vy = 0` alongside it means the shape never moves at all, so there is no
 *   playfield time to give — `screenTime` returns `null` for that same case on a true `constant`.
 *
 * This is the window in which being off screen horizontally is what matters, which is why it is the
 * playfield rather than the safety box `LifetimeSystem` finally removes the entity at.
 */
function arcPlayfieldTime(traj, radius) {
  const target = CODE.playfieldHeight.value + 2 * radius;

  if (traj.ay === 0) return traj.vy === 0 ? null : target / Math.abs(traj.vy);

  const a = traj.ay / 2;
  const disc = traj.vy * traj.vy - 4 * a * target;

  if (traj.ay < 0) return (-traj.vy - Math.sqrt(disc)) / (2 * a);

  const up = (-2 * traj.vy) / traj.ay;
  if (disc >= 0) {
    const down = (-traj.vy - Math.sqrt(disc)) / (2 * a);
    if (down > 0) return Math.min(down, up);
  }
  return up;
}

/**
 * Screen time on a constant shape: the whole playfield plus the radius it spawns above the edge.
 * Returns `null` for anything that is not `constant` — `arc` because its speed varies and
 * `arcPlayfieldTime` is its own closed form, and `path` for the same reason `arc` already is: this
 * function is called with no spawn context (no `atX`, no formation), so it cannot know where a
 * path's horizontal legs would carry it off the sides, and a path's `vy` is not one number to divide
 * by. `pathSweep`, which does have that context, is `sweptExtent`'s own answer for a `path`.
 */
function screenTime(trajectory, radius) {
  if (trajectory.kind !== 'constant') return null;
  const vy = Math.abs(trajectory.vy);
  if (vy === 0) return null;
  return (CODE.playfieldHeight.value + radius) / vy;
}

// ------------------------------------------------------------------------------------------------
// The document. Fourteen sections, in the order the contract names them.

function buildLevel(levelFile, content) {
  const { level, waves, enemies, formations, trajectories, attachments, balance } = content;
  const levelId = path.basename(levelFile, '.json');
  const { rows, exact } = timeline(level, waves);
  const out = [];
  const w = (line = '') => out.push(line);

  // 1. Header and provenance ---------------------------------------------------------------------
  w(`# ${levelId}`);
  w();
  w('**This file is generated. Do not edit it by hand — CI will fail before your edit reaches anyone.**');
  w('`tools/build-level-docs.js` writes it from the content listed below, and `.github/workflows/ci.yml`');
  w('regenerates it on every push and fails if the result differs.');
  w();
  w('Generated from:');
  w();
  for (const name of [levelFile, 'waves.json', 'enemies.json', 'formations.json', 'trajectories.json',
    'attachments.json', 'balance.json']) {
    w(`- \`assets/data/${name}\``);
  }
  w();
  w('It carries no generation date, git hash or tool version on purpose: any of those would make the');
  w('check above fail on every run, which is how a mechanism becomes noise somebody switches off.');
  w();
  w('**A level file on its own is not playable.** `game/LittleSpaceshipGame.java:42` holds');
  w('`private static final String LEVEL_ID = "level-01";`, so which level runs is a code change in');
  w('`game/`, not a content change. A correct second level file loads and cannot be reached until that');
  w('line moves.');
  w();
  w('**What it does not carry is why any of this is the way it is.** JSON admits no comments, so');
  w('design intent has nowhere to live in the source and cannot be generated from it. The intent for');
  w('level 1 is in `docs/planning/04-campaign-and-levels.md`, and which wave serves which beat is in');
  w('`docs/plan/11c-movement-shapes/shape-catalogue.md` under "What points at what". The reasoning');
  w('behind the gap is section 14 of `docs/plan/11d-per-level-document/document-contract.md`.');
  w();

  // 0. The format ------------------------------------------------------------------------------
  // Added by #190, after task 4's read-back wrote a level-02.json from this document and it failed to
  // load: sections 1-14 print values and never keys. The key lists below are copied from
  // JsonContentSource's own requireOnlyKeys calls, and each names the line it came from — that is the
  // one thing regenerating cannot keep honest, the same weakness the CODE table at the top has.
  w('## The format');
  w();
  w('Every key, because the rest of this document prints values and would otherwise leave you guessing');
  w('them. The lists come from `game/adapter/content/JsonContentSource.java`, which **rejects any key');
  w('its schema does not name** — `requireOnlyKeys`, `:431` — so a key that is not below is a level');
  w('that fails to load rather than a key that is quietly ignored.');
  w();
  w('```jsonc');
  w('// assets/data/level-NN.json — requireOnlyKeys(root, "level file", ...) at :349');
  w('{');
  w('  "boss": { ... },        // optional; the block is below');
  w('  "waves": [              // ordered list of placements. An empty list is a level with no waves');
  w('    { "wave":   "l1-basic-intro",  // required, an id in waves.json');
  w('      "offset": 8.0 }              // required, seconds AFTER THE PREVIOUS PLACEMENT ENDS,');
  w('                                   // not from level start. NEGATIVE OVERLAPS the two:');
  w('                                   // -6.0 starts this one 6 s before the last one ends,');
  w('                                   // and overlap is the one lever in this format that');
  w('                                   // produces pressure nothing else can');
  w('  ]');
  w('  // "events" is also accepted at the top level: the pre-11b flat spawn list. Do not write one');
  w('}');
  w('```');
  w();
  w('```jsonc');
  w('// assets/data/waves.json — requireOnlyKeys(root, "wave file", "waves") at :253');
  w('{ "waves": [');
  w('  { "id":     "l1-basic-intro",   // required, and GLOBAL: waves.json is one shared file across');
  w(`                                  // every level, so an id collides with every other level's`);
  w('    "end":    { "type": "fixedDuration", "seconds": 27.5 },');
  w('                                  // required. Two kinds, and nothing else:');
  w('                                  //   {"type":"fixedDuration","seconds":N}  ends at N');
  w('                                  //   {"type":"cleared"}                    ends when every');
  w('                                  //     entity it spawned is gone. From the first cleared wave');
  w('                                  //     onwards every later time in this document is a lower');
  w('                                  //     bound rather than a value');
  w('    "spawns": [                   // required, and each entry is:');
  w(`      { "at":        0.0,         // required, seconds FROM THIS WAVE'S OWN START.`);
  w(`                                  //   A spawn past the wave's duration never fires`);
  w('        "spawn":     "enemy-basic",  // required, an id in enemies.json');
  w('        "formation": "single",       // required, an id in formations.json');
  w('        "atX":       0.5,            // required, 0..1 of the 208-wide playfield, applied to');
  w(`                                     //   the formation's CENTRE. Nothing clamps the result`);
  w(`        "trajectory": "dive",        // optional; omit to use the archetype's own default`);
  w('        "drop":       "weapon-upgrade",  // optional, one of the six kinds below');
  w(`        "dropSlot":   1 }            // optional, defaults to 0. Index into the formation's`);
  w('                                     //   slots; past the slot count is fatal at spawn time');
  w('    ] }');
  w('] }');
  w('```');
  w();
  w('The same wave id may be placed **any number of times**, in one level or in several. That is the');
  w('point of the split, and it means an edit to a wave lands on every placement of it — the "Placed');
  w('N times" line under each wave below is where to check.');
  w();
  w('```jsonc');
  w('// assets/data/trajectories.json — requireOnlyKeys at :184 and :188');
  w('{ "trajectories": [');
  w('  { "id": "slow-descent", "vx": 0, "vy": -18 },');
  w('                                  // no "type": a constant velocity, units per second, y up');
  w('  { "id": "strike-run", "type": "arc", "vx": 0, "vy": -110, "ay": 27 },');
  w('                                  // "type":"arc" adds "ay", and only then. It turns after');
  w('                                  //   -vy/ay seconds and bottoms out vy^2/(2*ay) below spawn');
  w('  { "id": "turn-out", "type": "path",');
  w('    "segments": [ { "vx": 0, "vy": -45, "duration": 3.0 },');
  w('                  { "wait": 1.0 },');
  w('                  { "vx": -55, "vy": 0, "duration": 6.0 } ] },');
  w('                                  // "segments": velocity held for a duration, leg after leg;');
  w('                                  //   {"wait": s} is a leg with no velocity. Optional "loopStart"');
  w('                                  //   / "loopCount" repeat a trailing range; the last leg (the');
  w('                                  //   last of the repeated range, if there is one) must move —');
  w('                                  //   a path that ends at rest is refused at load');
  w('  { "id": "hold-then-slide", "type": "path",');
  w('    "waypoints": [ { "x": 104, "y": 270 }, { "x": 104, "y": 190, "speed": 45 },');
  w('                   { "x": 208, "y": 190, "speed": 70 } ] },');
  w('                                  // "waypoints": destinations and a speed instead of a velocity');
  w('                                  //   and a duration — "segments" and "waypoints" are mutually');
  w('                                  //   exclusive on one entry. ABSOLUTE: the first waypoint is');
  w('                                  //   the authoring origin, not a position the engine reads —');
  w('                                  //   the wave placing this must use atX = (that x) / 208');
  w('  { "id": "cross-right", "mirrorOf": "cross-left" },');
  w('                                  // negates every horizontal component of "cross-left"');
  w('  { "id": "dive-fast", "speedOf": "dive", "multiplier": 1.5 }');
  w('                                  // the same shape traversed 1.5x sooner — velocities scale by');
  w('                                  //   the multiplier, and an arc\'s "ay" by its square');
  w('] }');
  w('```');
  w();
  w('```jsonc');
  w('// the "boss" block of a level file — requireOnlyKeys(value, "boss block", ...) at :402.');
  w('// Every key is required; the names are BossDefinition\'s accessors. Values for this level are');
  w('// in "The boss" below, with what each one does to the fight.');
  w('{ "id": "boss-l1", "entersAt": 302.0,');
  w('  "coreHealth": 1800, "podHealth": 500, "armHealth": 500,');
  w('  "corePoints": 1500, "podPoints": 500, "armPoints": 500,');
  w('  "entranceSpeed": 25.0, "combatY": 175.0, "patternCooldown": 0.7,');
  w('  "spreadProjectileSpeed": 95.0, "sweepProjectileSpeed": 140.0 }');
  w('```');
  w();
  w('`enemies.json` and `formations.json` have **no strict key check** — an unknown component key in an');
  w('archetype is rejected by `ComponentFactoryRegistry` instead, at spawn time. Their fields are in');
  w('the Roster and Formations sections below, printed per entry rather than as a schema.');
  w();

  // 2. At a glance -------------------------------------------------------------------------------
  const last = rows[rows.length - 1];
  const wavesEnd = last.end;
  const spawnEvents = rows.reduce((n, r) => n + r.wave.spawns.length, 0);
  let entities = 0;
  for (const row of rows) for (const sp of row.wave.spawns) entities += entitiesOf(sp, formations);
  const distinct = new Set(level.waves.map((p) => p.wave));

  w('## At a glance');
  w();
  const glance = [
    ['placements', String(level.waves.length)],
    ['distinct waves', String(distinct.size)],
    ['spawn events', String(spawnEvents)],
    ['entities spawned directly', String(entities)],
    ['the waves end at', exact ? `${s1(wavesEnd)} s` : 'unknowable — see below'],
  ];
  if (level.boss) {
    glance.push(['the boss enters at', `${s1(level.boss.entersAt)} s (${s1(level.boss.entersAt / 60)} min)`]);
    // The row stays when the chain is inexact rather than vanishing. Vanishing is what #190 found:
    // the one situation where this interaction is dangerous was the one the document went quiet in.
    glance.push(['gap between them', exact
      ? `${s1(level.boss.entersAt - wavesEnd)} s`
      : 'unknowable — the boss may enter over a running wave']);
  }
  w(table(['', ''], glance));
  w();
  if (exact) {
    w('**Every wave ends on `fixedDuration`, so every time below is exact arithmetic.** The moment one');
    w('wave uses `{"type": "cleared"}` (`core/port/WaveEndCondition.java`), every absolute time after');
    w('it becomes a lower bound, because a cleared wave ends when the player finishes it. This');
    w('document would then say so here rather than print numbers that look exact.');
  } else {
    w('**At least one wave ends on `cleared`, so the times below are lower bounds, not values.** A');
    w('cleared wave ends when the last entity it spawned is gone (`SpawnSystem.noEntityCarries`),');
    w('which is when the player finishes it. Every placement after the first `cleared` one starts no');
    w('earlier than the time printed and may start much later. Affected rows are marked `>=`.');
  }
  w();

  // 3. The pacing table --------------------------------------------------------------------------
  w('## The pacing table');
  w();
  w("One row per placement, in level order. **Density is entities per second of that placement's own");
  w('duration** — `entities / duration` — and it is one axis of difficulty, not a difficulty score.');
  w('`docs/planning/01-vision-and-scope.md` names eight axes at once; this is one. A slow carrier that');
  w('keeps producing children reads low here and plays hard.');
  w();
  const density = [];
  const pacing = [];
  for (const row of rows) {
    const ents = row.wave.spawns.reduce((n, sp) => n + entitiesOf(sp, formations), 0);
    const archetypes = [];
    const drops = [];
    for (const sp of row.wave.spawns) {
      if (!archetypes.includes(sp.spawn)) archetypes.push(sp.spawn);
      if (sp.drop) drops.push(sp.drop);
    }
    const d = row.duration === null ? null : ents / row.duration;
    density.push(d);
    const mark = row.exact ? '' : '>= ';
    pacing.push([
      String(row.i + 1),
      `\`${row.placement.wave}\``,
      s1(row.placement.offset),
      mark + s1(row.start),
      row.duration === null ? 'when cleared' : mark + s1(row.end),
      row.duration === null ? '`cleared`' : `${s1(row.duration)} s`,
      String(ents),
      d === null ? '—' : `${s2(d)}/s`,
      archetypes.map((a) => `\`${a}\``).join(' '),
      drops.length ? drops.map((x) => `\`${x}\``).join(' ') : '—',
    ]);
  }
  w(table(['#', 'wave', 'offset', 'start', 'end', 'lasts', 'entities', 'density', 'archetypes', 'drops'],
    pacing));
  w();

  // 4. The curve, as a bar -----------------------------------------------------------------------
  w('## The curve');
  w();
  w('The same numbers as a shape, because a column of numbers is not one. The bar is scaled to the');
  w("densest placement in this level, so it compares beats within a level and not between levels.");
  w();
  const peak = Math.max(...density.map((d) => d || 0), 0.0001);
  w('```');
  rows.forEach((row, i) => {
    const d = density[i];
    const bar = d === null ? '?' : '#'.repeat(Math.round((d / peak) * 40));
    w(`${padL(s1(row.start), 7)}  ${padR(row.placement.wave, 22)} ${padL(d === null ? '—' : s2(d), 5)}/s  ${bar}`);
  });
  w('```');
  w();

  // 5. Wave by wave ------------------------------------------------------------------------------
  w('## Wave by wave');
  w();
  w('Each wave this level places, once, in the order it first appears. **Placed at** lists every');
  w('absolute time the level starts it: a wave is reusable, so editing one for one beat edits every');
  w('placement of it, and nothing in `assets/data/waves.json` says so.');
  w();
  const seen = [];
  for (const row of rows) if (!seen.includes(row.placement.wave)) seen.push(row.placement.wave);
  for (const waveId of seen) {
    const wave = resolve(waves, waveId, 'wave', 'the wave-by-wave section');
    const placedAt = rows.filter((r) => r.placement.wave === waveId);
    w(`### \`${waveId}\``);
    w();
    w('**Ends:** ' + (wave.end.type === 'fixedDuration'
      ? `\`fixedDuration\`, ${s1(wave.end.seconds)} s`
      : `\`${wave.end.type}\` — when every entity it spawned is gone (\`SpawnSystem.noEntityCarries\`)`));
    w();
    w(`**Placed ${placedAt.length} time${placedAt.length === 1 ? '' : 's'}:** `
      + placedAt.map((r) => `#${r.i + 1} at ${r.exact ? '' : '>= '}${s1(r.start)} s`).join(', ')
      + (placedAt.length > 1 ? ' — **reused: an edit here lands on all of them.**' : ''));
    w();
    const spawnRows = [];
    for (const sp of wave.spawns) {
      const enemy = resolve(enemies, sp.spawn, 'archetype', `wave '${waveId}'`);
      const traj = trajectoryOf(sp, enemy);
      resolve(trajectories, traj.id, 'trajectory', `archetype '${enemy.id}' or a spawn in '${waveId}'`);
      const fp = footprint(sp, enemy, formations);
      const swept = sweptExtent(sp, enemy, formations, trajectories);
      const formation = resolve(formations, sp.formation, 'formation', `wave '${waveId}'`);
      spawnRows.push([
        s1(sp.at),
        `\`${sp.spawn}\``,
        `\`${sp.formation}\` (${formation.slots.length})`,
        s2(sp.atX),
        `\`${traj.id}\`${traj.override ? ' *(override)*' : ''}`,
        `${s1(fp.min)} .. ${s1(fp.max)}${fp.offScreen ? ' **off screen**' : ''}`,
        // "same" means the swept range coincides with the spawn-instant footprint on both ends —
        // checking `swept.drift` alone (a single number) was wrong for a `path`: two of its legs can
        // drift in opposite directions, so `minDrift` and `maxDrift` differ and a `drift` near zero
        // does not mean the range is unchanged (see this task's status fragment).
        Math.abs(swept.min - fp.min) < 0.05 && Math.abs(swept.max - fp.max) < 0.05
          ? 'same'
          : `${s1(swept.min)} .. ${s1(swept.max)}${swept.offScreen ? ' **leaves**' : ''}`,
        sp.drop ? `\`${sp.drop}\` slot ${sp.dropSlot === undefined ? 0 : sp.dropSlot}` : '—',
      ]);
    }
    w(table(['at', 'archetype', 'formation', 'atX', 'shape', 'x at spawn', 'x swept', 'drop'],
      spawnRows));
    w();
  }
  w("**`x at spawn`** is `atX * 208 + slot.offsetX`, plus and minus the archetype's collider radius");
  w('(`SpawnSystem.spawnWave`, `SpawnSystem.positionSpawned`). **Nothing clamps it** — a formation');
  w('whose extent leaves `0 .. 208` spawns partly off screen and nobody is told at runtime.');
  w();
  w('**`x swept` is where it goes**, and for any shape with a `vx` it is the column that matters. A');
  w('spawn-instant extent is a snapshot: any shape that drifts horizontally ends up somewhere else, and');
  w('one placed on the side it drifts towards can spend its whole flight off screen while still');
  w('reading in range at the spawn instant. `same` means the shape has no horizontal velocity and the');
  w('two are identical.');
  w();
  w("**`shape` is resolved, not copied.** A spawn's own `trajectory` key overrides the archetype's");
  w('`motion.trajectory` and is marked *(override)*; every other row is the archetype default.');
  w();

  // 6. Roster ------------------------------------------------------------------------------------
  const used = [];
  for (const row of rows) for (const sp of row.wave.spawns) if (!used.includes(sp.spawn)) used.push(sp.spawn);
  // A spawner archetype's children are in the level too, though no wave names them.
  for (const id of [...used]) {
    const spawner = resolve(enemies, id, 'archetype', 'the roster').components.spawner;
    if (spawner && !used.includes(spawner.enemyId)) used.push(spawner.enemyId);
  }

  w('## Roster');
  w();
  w('Every archetype this level spawns, plus any an archetype spawns itself. The derived columns are');
  w('the point: `rate 4.0` is a number, "one shot per pass" is what it means.');
  w();
  const roster = [];
  for (const id of used) {
    const e = resolve(enemies, id, 'archetype', 'the roster');
    const c = e.components;
    const radius = c.collider ? c.collider.radius : 0;
    const health = c.health ? c.health.points : null;
    const traj = resolve(trajectories, c.motion.trajectory, 'trajectory', `archetype '${id}'`);
    const time = screenTime(traj, radius);
    const variesLabel = `varies (${traj.kind})`;
    let shotsPerPass = '—';
    if (c.weapon) {
      if (time === null) shotsPerPass = variesLabel;
      else {
        const firing = time - c.weapon.firstShotDelay;
        shotsPerPass = firing < 0 ? '0' : String(1 + Math.floor(firing / c.weapon.rate));
      }
    }
    let children = '—';
    if (c.spawner) children = time === null ? variesLabel : String(Math.floor(time / c.spawner.interval));
    roster.push([
      `\`${id}\``,
      `\`${c.sprite.id}\``,
      s1(radius),
      c.collider && c.collider.fragile ? 'yes' : 'no',
      health === null ? 'none' : String(health),
      String(health === null ? 1 : Math.ceil(health / balance.weaponProjectileDamage)),
      c.scoreValue ? String(c.scoreValue.points) : '—',
      `\`${traj.id}\``,
      time === null ? variesLabel : `${s1(time)} s`,
      c.weapon
        ? `\`${c.weapon.pattern}\`, every ${s1(c.weapon.rate)} s from ${s1(c.weapon.firstShotDelay)} s, speed ${s1(c.weapon.speed)}`
        : 'none',
      shotsPerPass,
      c.spawner ? `\`${c.spawner.enemyId}\` every ${s1(c.spawner.interval)} s` : 'none',
      children,
      c.lifetime ? `${s1(c.lifetime.seconds)} s` : 'none',
    ]);
  }
  w(table(['archetype', 'sprite', 'radius', 'fragile', 'health', 'shots to kill', 'score',
    'default shape', 'screen time', 'weapon', 'shots per pass', 'spawner', 'children per pass',
    'lifetime'], roster));
  w();
  w(`**shots to kill** is \`ceil(health / weaponProjectileDamage)\` against \`weaponProjectileDamage ${balance.weaponProjectileDamage}\``);
  w('from `assets/data/balance.json`. An archetype with no `health` dies to one projectile — and so');
  w(`does one with \`health\` at or below ${balance.weaponProjectileDamage}, which is how a "slightly tougher" enemy becomes a`);
  w('no-op (`core/domain/system/DamageSystem.java`).');
  w();
  w(`**screen time** is \`(${CODE.playfieldHeight.value} + radius) / |vy|\`: the playfield height (${CODE.playfieldHeight.from}) plus the`);
  w('radius the entity spawns above the edge (`SpawnSystem.positionSpawned`). It is `varies` on an');
  w('`arc`, whose speed changes as it flies, and on a `path` for the same reason plus one more: this');
  w('table has no spawn to measure a `path` from, so it cannot say where a horizontal leg would carry');
  w('it off the sides. A `path`\'s real screen time, for the spawn it is actually placed at, is the');
  w('"x swept" column above.');
  w();
  w('**shots per pass** is `1 + floor((screen time - firstShotDelay) / rate)`, and it is the number');
  w('that matters: an archetype whose rate exceeds its screen time fires once whatever the rate says.');
  w('**children per pass** is `floor(screen time / interval)`.');
  w();
  w('**`lifetime` is printed even though nothing carries one.** `core/domain/system/LifetimeSystem.java`');
  w('reads an optional per-archetype `Lifetime`; the column says `none` rather than being omitted, so');
  w('the lever stays visible.');
  w();

  // 7. Movement shapes ---------------------------------------------------------------------------
  const shapeIds = [];
  for (const id of used) {
    const t = resolve(enemies, id, 'archetype', 'the shapes section').components.motion.trajectory;
    if (!shapeIds.includes(t)) shapeIds.push(t);
  }
  for (const row of rows) {
    for (const sp of row.wave.spawns) {
      if (sp.trajectory && !shapeIds.includes(sp.trajectory)) shapeIds.push(sp.trajectory);
    }
  }
  w('## Movement shapes this level uses');
  w();
  w('Only the shapes this level reaches. The full catalogue, including the eight shapes that were');
  w('refused and why, is `docs/plan/11c-movement-shapes/shape-catalogue.md`.');
  w();
  const shapeRows = [];
  let anyPath = false;
  for (const id of shapeIds) {
    const t = resolve(trajectories, id, 'trajectory', 'the shapes section');
    if (t.kind === 'path') {
      anyPath = true;
      shapeRows.push([`\`${id}\``, '`path`', '—', '—', '—', '—', '—', pathLegSummary(t)]);
      continue;
    }
    const arc = t.kind === 'arc';
    // A turn and an apex are properties of a shape that pulls out of its dive — true only for
    // `ay > 0`. `ay <= 0` never turns (it either steepens or holds a straight `vy` forever, issue
    // #322), so printing `-vy/ay` or `vy^2/(2*ay)` there would be a negative time or an inverted
    // apex: a number that looks plausible and is not, exactly the failure mode this table exists to
    // avoid. Say so in words instead.
    const turnsAfter = arc && t.ay > 0 ? `${s1(-t.vy / t.ay)} s`
      : arc ? 'no turn — never pulls out' : '—';
    const apexDepth = arc && t.ay > 0 ? `${s1((t.vy * t.vy) / (2 * t.ay))} below spawn`
      : arc ? 'no apex' : '—';
    shapeRows.push([
      `\`${id}\``,
      arc ? '`arc`' : '`constant`',
      s1(t.vx),
      s1(t.vy),
      arc ? s1(t.ay) : '—',
      turnsAfter,
      apexDepth,
      '—',
    ]);
  }
  w(table(['shape', 'kind', 'vx', 'vy', 'ay', 'turns after', 'apex depth', 'legs (path only)'], shapeRows));
  w();
  w('An `arc` turns at `-vy / ay` and bottoms out `vy² / (2·ay)` below where it spawned, evaluated in');
  w("closed form from the entity's own elapsed time (`core/port/ArcTrajectoryDefinition.java`).");
  w(`The player flies at \`playerStartY ${s1(balance.playerStartY)}\` in a ${CODE.playfieldHeight.value}-tall playfield, so a shape whose apex sits`);
  w('far above that band is scenery.');
  w();
  if (anyPath) {
    w('**A `path` has no single `vx`/`vy`/`ay`** — its legs are in the last column, in order, a leg in');
    w('brackets meaning it is inside the repeated range. `vx, vy for Ns` is a segment; `wait Ns` is the');
    w('`{"wait": s}` shorthand, a segment with no velocity. Every duration and velocity is already');
    w('resolved from whichever authoring form (`segments` or `waypoints`) the entry used — see');
    w('`docs/plan/11i-path-vocabulary/plan.md` and `docs/plan/11j-absolute-paths/plan.md`.');
    w();
  }

  // 8. Formations --------------------------------------------------------------------------------
  const formIds = [];
  const formArchetypes = new Map();
  for (const row of rows) {
    for (const sp of row.wave.spawns) {
      if (!formIds.includes(sp.formation)) formIds.push(sp.formation);
      if (!formArchetypes.has(sp.formation)) formArchetypes.set(sp.formation, []);
      const list = formArchetypes.get(sp.formation);
      if (!list.includes(sp.spawn)) list.push(sp.spawn);
    }
  }
  w('## Formations this level uses');
  w();
  const formRows = [];
  for (const id of formIds) {
    const f = resolve(formations, id, 'formation', 'the formations section');
    const xs = f.slots.map((s) => s.offsetX);
    const span = Math.max(...xs) - Math.min(...xs);
    formRows.push([
      `\`${id}\``,
      String(f.slots.length),
      f.slots.map((s) => `(${s.offsetX}, ${s.offsetY})`).join(' '),
      s1(span),
      formArchetypes.get(id).map((a) => {
        const r = resolve(enemies, a, 'archetype', 'the formations section').components.collider.radius;
        return `\`${a}\` ${s1(span + 2 * r)}`;
      }).join(', '),
    ]);
  }
  w(table(['formation', 'slots', 'offsets (x, y)', 'span', 'occupied width, per archetype'], formRows));
  w();
  w(`The playfield is ${CODE.playfieldWidth.value} units wide (${CODE.playfieldWidth.from}). Occupied width is what decides whether`);
  w('an `atX` is legal, and it is the arithmetic every new spawn needs.');
  w();
  w("**A slot's `offsetY` is a head start in pixels, not a delay in seconds** — the whole formation");
  w('clears the bottom edge together and the slot furthest back arrives later only because it has');
  w('further to travel (`SpawnSystem.positionSpawned`). So one formation is a stream on a slow shape');
  w('and a burst on a fast one:');
  w();
  const stagger = [];
  for (const id of formIds) {
    const f = resolve(formations, id, 'formation', 'the stagger table');
    const ys = f.slots.map((s) => s.offsetY);
    const spread = Math.max(...ys) - Math.min(...ys);
    if (spread === 0) continue;
    for (const a of formArchetypes.get(id)) {
      const t = resolve(trajectories,
        resolve(enemies, a, 'archetype', 'the stagger table').components.motion.trajectory,
        'trajectory', 'the stagger table');
      stagger.push([
        `\`${id}\``,
        `\`${a}\``,
        `\`${t.id}\``,
        String(spread),
        t.kind !== 'constant' ? `varies (${t.kind})` : `${s2(spread / Math.abs(t.vy))} s`,
      ]);
    }
  }
  if (stagger.length) {
    w(table(['formation', 'archetype', 'shape', 'y spread', 'first to last'], stagger));
  } else {
    w('No formation this level uses spreads its slots vertically, so nothing is staggered.');
  }
  w();

  // 9. Projectiles -------------------------------------------------------------------------------
  w('## Projectiles');
  w();
  const projectiles = [['the player', s1(balance.weaponProjectileSpeed),
    String(balance.weaponProjectileDamage), 'not in content']];
  for (const id of used) {
    const wp = resolve(enemies, id, 'archetype', 'the projectiles section').components.weapon;
    if (wp) projectiles.push([`\`${id}\``, s1(wp.speed), 'contact', s1(CODE.enemyProjectileRadius.value)]);
  }
  w(table(['fired by', 'speed', 'damage', 'radius'], projectiles));
  w();
  w(`The player fires every \`weaponFireCooldown ${s2(balance.weaponFireCooldown)}\` s across \`weaponLevels ${balance.weaponLevels}\` shot levels`);
  w('(`assets/data/balance.json`).');
  w();
  w(`**Not in \`assets/data/\`:** the enemy projectile's radius is \`${s1(CODE.enemyProjectileRadius.value)}\` in ${CODE.enemyProjectileRadius.from},`);
  w(`and \`${CODE.patterns.value.join('`, `')}\` is the **only** \`pattern\` string that system builds`);
  w(`(${CODE.patterns.from}). Any other value is content naming a shape nothing draws, and it throws the`);
  w('moment that enemy first fires. Those two sentences are quoted from code, and **regenerating this');
  w('document cannot keep them honest** — if those lines move, this text does not change.');
  w();

  // 10. Drops and rewards ------------------------------------------------------------------------
  w('## Drops and rewards');
  w();
  const dropRows = [];
  for (const row of rows) {
    for (const sp of row.wave.spawns) {
      if (!sp.drop) continue;
      dropRows.push([
        `${row.exact ? '' : '>= '}${s1(row.start + sp.at)}`,
        `\`${sp.drop}\``,
        `\`${row.placement.wave}\` (#${row.i + 1})`,
        `\`${sp.spawn}\` in \`${sp.formation}\`, slot ${sp.dropSlot === undefined ? 0 : sp.dropSlot}`,
      ]);
    }
  }
  if (dropRows.length) w(table(['at', 'kind', 'wave', 'carried by'], dropRows));
  else w('This level delivers no drops.');
  w();
  w('**A drop is delivered only if the player destroys the carrier.** `core/domain/system/LifetimeSystem.java`');
  w('strips `ScoreValue`, `Drop` and `Collider` from an enemy that leaves the screen, so a drop placed');
  w('on a fast, fragile archetype can be lost entirely.');
  w();
  w(`**The six kinds are code, not content** (${DROP_KINDS_FROM}). There is no \`drops.json\`, and`);
  w('`SpawnSystem.requireRecognisedDrop` rejects anything outside this closed set the moment a wave');
  w('carrying it spawns:');
  w();
  w(table(['kind', 'what it does'], DROP_KINDS.map(([k, d]) => [`\`${k}\``, d])));
  w();
  if (attachments.size) {
    w('Attachment durability, the one content-driven part: '
      + [...attachments.keys()].map((k) => `\`${k}\` ${attachments.get(k).durability}`).join(', ')
      + ' (`assets/data/attachments.json`).');
    w();
  }

  // 11. The boss ---------------------------------------------------------------------------------
  if (level.boss) {
    const b = level.boss;
    w('## The boss');
    w();
    w(table(['field', 'value'],
      Object.keys(b).map((k) => [`\`${k}\``, typeof b[k] === 'number' ? s1(b[k]) : String(b[k])])));
    w();
    const coreSpawnY = CODE.playfieldHeight.value + (CODE.boss.coreKeelRadius - CODE.boss.coreKeelOffsetY);
    w(table(['derived', 'value', 'how'], [
      ['entrance duration', `${s1((coreSpawnY - b.combatY) / b.entranceSpeed)} s`,
        `\`(${s1(coreSpawnY)} - combatY) / entranceSpeed\`, the core spawning at \`CORE_SPAWN_Y\``],
      ['health of the kill target', String(2 * b.coreHealth),
        "`2 x coreHealth` — `core-keel` carries the core's health independently"],
      ['health the bar shows', String(2 * b.coreHealth + 2 * b.podHealth + 2 * b.armHealth),
        `the sum across all ${CODE.boss.parts} parts, so killing pods shortens the bar without shortening the fight`],
    ]));
    w();
    w('**Where each ray goes**, from `combatY` and the fixed velocity ratios. `combatY` alone decides');
    w('whether this boss can hit anything, so the two columns that matter are which edge a ray leaves');
    w('through and how far it is from the boss when it crosses the height the player flies at.');
    w();
    // #192: this used to print "y at the side edge" for every ray and assert that all six leave
    // through a side, which is false — a ratio steeper than 45 degrees reaches the floor first, and
    // the column then gave a y below the playfield for a place the projectile never gets to. Which
    // edge a ray takes is derived here rather than assumed.
    const shots = [];
    const half = CODE.playfieldWidth.value / 2;
    for (const [name, ratios, vyRatio, speed] of [
      ['spread', CODE.boss.spreadVxRatios, CODE.boss.spreadVyRatio, b.spreadProjectileSpeed],
      ['sweep', CODE.boss.sweepVxRatios, CODE.boss.sweepVyRatio, b.sweepProjectileSpeed],
    ]) {
      for (const r of ratios) {
        const vx = r * speed;
        const vy = vyRatio * speed;
        const toSide = half / vx;
        const toFloor = b.combatY / Math.abs(vy);
        const atPlayer = vx * ((b.combatY - balance.playerStartY) / Math.abs(vy));
        shots.push([
          name,
          s2(r),
          s1(vx),
          s1(vy),
          toFloor < toSide ? `the floor, ${s1(toFloor)} s` : `a side, ${s1(toSide)} s`,
          atPlayer > half ? '**off the playfield already**' : s1(atPlayer),
        ]);
      }
    }
    w(table(['pattern', 'vx ratio', 'vx', 'vy', 'leaves through', `x from the boss at y ${s1(balance.playerStartY)}`],
      shots));
    w();
    w(`The ratios and \`CORE_SPAWN_Y\` are in ${CODE.boss.from}, not in content.`);
    w();
    w(`**The last column is the one to read.** It is how far to either side of the boss a ray has`);
    w(`travelled by the time it reaches \`playerStartY ${s1(balance.playerStartY)}\`, the height the player starts at, measured`);
    w('from the boss\'s own centre — so a ray whose figure is larger than the half-width, 104, has left');
    w('the playfield before it ever gets down there and threatens nobody. **A boss every one of whose');
    w('rays reads that way is unlosable, with no error anywhere.** Where the player actually stands is');
    w('theirs to choose; this document says only where the rays are.');
    w();
    w("**`entersAt` is absolute level time**, compared against `BossSystem`'s own clock, which is");
    w('independent of the wave chain. ' + (exact
      ? `The waves end at ${s1(wavesEnd)} s and the boss enters at ${s1(b.entersAt)} s: a ${s1(b.entersAt - wavesEnd)} s gap.`
      : 'Because at least one wave ends on `cleared`, that gap is unknowable and the boss can enter over a wave still running.'));
    w();
  }

  // 12. Designing against the player --------------------------------------------------------------
  w('## Designing against the player');
  w();
  w('The same for every level, repeated here so no lookup leaves this document.');
  w();
  const balRows = [
    ['playfield width', `${CODE.playfieldWidth.value} (${CODE.playfieldWidth.from})`],
    ['playfield height', `${CODE.playfieldHeight.value} (${CODE.playfieldHeight.from})`],
  ];
  for (const k of Object.keys(balance).sort()) balRows.push([`\`${k}\``, String(balance[k])]);
  w(table(['', 'value'], balRows));
  w();
  w('The two dimensions are fixed properties of the logical resolution rather than balance values,');
  w('which is why they live in code and everything under them lives in `assets/data/balance.json`.');
  w();

  // 13. Checks -------------------------------------------------------------------------------------
  w('## Checks');
  w();
  w('Every check below is a failure that is either silent at runtime or fatal only on the tick it');
  w('happens, and each one costs a run of `./gradlew :desktop:run` to find by hand. That is the part of');
  w('this document a generator can do and a human reliably will not.');
  w();
  // The list is printed whether or not anything fired. Without it a clean document says only "no
  // issues found", and a designer cannot tell which mistakes are caught from which still have to be
  // verified by hand — #190, correction C2, found by reading a clean one.
  w('**What was checked**, so you can tell what is still yours to verify:');
  w();
  for (const line of [
    'a spawn whose `at` is past its wave’s duration, which never fires',
    'a formation whose extent at the spawn instant leaves `0 .. 208`',
    '**a spawn whose swept extent is mostly outside `0 .. 208`**, which the spawn-instant extent cannot see',
    '**an absolutely-authored path (`waypoints`) placed at an `atX` that does not reproduce its entry waypoint**, within the rounding a two-decimal `atX` can introduce',
    'a `dropSlot` past its formation’s slot count',
    'a drop kind outside the six',
    'a `cleared` wave holding a shape that never leaves the playfield, so it can never end',
    'a negative `offset`, and what it overlaps',
    'a boss entering over a running wave, against a lower bound when the wave chain is inexact',
  ]) w(`- ${line}`);
  w();
  w('**Not checked, and still yours:** whether the level is any good. Density is not difficulty and');
  w('this project tunes balance by playing.');
  w();
  const findings = [];
  for (const row of rows) {
    const wave = row.wave;
    for (const sp of wave.spawns) {
      if (wave.end.type === 'fixedDuration' && sp.at > wave.end.seconds) {
        findings.push(`\`${wave.id}\`: a spawn at ${s1(sp.at)} s never fires — the wave ends at ${s1(wave.end.seconds)} s. \`SpawnSystem.spawnDue\` only advances the cursor while the wave is active.`);
      }
      const enemy = resolve(enemies, sp.spawn, 'archetype', 'the checks section');
      const t = resolve(trajectories, trajectoryOf(sp, enemy).id, 'trajectory', 'the checks section');
      const fp = footprint(sp, enemy, formations);
      if (fp.offScreen) {
        findings.push(`\`${wave.id}\`: \`${sp.spawn}\` in \`${sp.formation}\` at \`atX ${s2(sp.atX)}\` occupies ${s1(fp.min)} .. ${s1(fp.max)}, outside 0 .. ${CODE.playfieldWidth.value}. Nothing clamps it.`);
      }
      // Drift, not the snapshot above. A shape placed on the side it drifts towards prints in range
      // at the spawn instant and spends its whole flight off screen.
      const swept = sweptExtent(sp, enemy, formations, trajectories);
      if (swept.offScreen && swept.outsideFraction >= 0.5) {
        findings.push(`\`${wave.id}\`: \`${sp.spawn}\` in \`${sp.formation}\` at \`atX ${s2(sp.atX)}\` on \`${t.id}\` sweeps ${s1(swept.min)} .. ${s1(swept.max)} over ${s1(swept.seconds)} s in the playfield — about ${Math.round(swept.outsideFraction * 100)}% of that width is outside 0 .. ${CODE.playfieldWidth.value}. It reads in range at the spawn instant and is not.`);
      }
      // An absolutely-authored path's entry waypoint is a position in the playfield, not a delta
      // from wherever it is placed — #300. `atX` must reproduce it or the path flies somewhere other
      // than what its own coordinates describe.
      const needsAtX = requiredAtX(t);
      if (needsAtX !== null
        && Math.abs(sp.atX * CODE.playfieldWidth.value - t.entryX) > ATX_TOLERANCE_PX) {
        findings.push(`\`${wave.id}\`: \`${sp.spawn}\` on \`${t.id}\` is an absolutely-authored path whose entry waypoint sits at x ${s1(t.entryX)}, requiring \`atX ${s2(needsAtX)}\` — placed at \`atX ${s2(sp.atX)}\` instead.`);
      }
      const slots = resolve(formations, sp.formation, 'formation', 'the checks section').slots.length;
      if (sp.dropSlot !== undefined && sp.dropSlot >= slots) {
        findings.push(`\`${wave.id}\`: \`dropSlot ${sp.dropSlot}\` on \`${sp.formation}\`, which has ${slots} slot(s). Fatal at spawn time (\`SpawnSystem.requireSlotInRange\`).`);
      }
      if (sp.drop && !DROP_KINDS.some(([k]) => k === sp.drop)) {
        findings.push(`\`${wave.id}\`: drop kind \`${sp.drop}\` is outside the six ${DROP_KINDS_FROM} recognises. Fatal at spawn time.`);
      }
      if (wave.end.type === 'cleared') {
        // Only a `constant` with a non-negative vy can fail to leave: an `arc` turns and a `path`'s
        // rule 3 (its last leg has nonzero velocity) both guarantee an eventual exit, on one axis or
        // the other, in finite time.
        if (t.kind === 'constant' && t.vy >= 0) {
          findings.push(`\`${wave.id}\` is \`cleared\` and spawns \`${sp.spawn}\` on \`${t.id}\`, which never leaves the playfield unattended, so the wave can never end.`);
        }
      }
    }
    if (row.placement.offset < 0) {
      const previous = rows[row.i - 1];
      findings.push(`placement #${row.i + 1} \`${row.placement.wave}\` has \`offset ${s1(row.placement.offset)}\`, overlapping \`${previous ? previous.placement.wave : '(nothing)'}\` by ${s1(-row.placement.offset)} s. Overlap is the one thing in this format that produces pressure nothing else can, and it is the thing a reader misreads first.`);
    }
  }
  // Not guarded by `exact` any more. The chain being inexact is precisely when this matters, and
  // guarding on it switched the check off there — #190, correction C4. When the chain is inexact
  // `last.start` is a lower bound, so a boss below it overlaps unconditionally rather than possibly.
  if (level.boss) {
    const bound = exact ? wavesEnd : last.start;
    if (level.boss.entersAt < bound) {
      findings.push(exact
        ? `\`boss.entersAt ${s1(level.boss.entersAt)}\` is earlier than the last placement's end at ${s1(wavesEnd)} s, so the boss enters over a running wave. Legal, occasionally intended, never accidental.`
        : `\`boss.entersAt ${s1(level.boss.entersAt)}\` is earlier than the last placement can possibly start (${s1(bound)} s), and the chain is inexact because a wave ends on \`cleared\`, so the boss enters over a running wave **unconditionally** — not merely if the player is slow.`);
    } else if (!exact) {
      findings.push(`the wave chain is inexact — a wave ends on \`cleared\` — so \`boss.entersAt ${s1(level.boss.entersAt)}\` cannot be compared against the end of the waves. It is later than the earliest the last placement can start (${s1(bound)} s) and that is all this document can say. Whether the boss enters over a running wave depends on how fast the level is played.`);
    }
  }
  if (findings.length === 0) w('**No issues found.**');
  else for (const f of findings) w(`- ${f}`);
  w();

  // 14. The beat map -------------------------------------------------------------------------------
  w('## The beat map');
  w();
  w('**Not generated, and it cannot be.** Which of the fourteen beats of');
  w('`docs/planning/04-campaign-and-levels.md` a placement serves, and why it exists, is design intent,');
  w('and there is no field for it in `assets/data/`. JSON admits no comments; area G of');
  w('`docs/plan/10c-architecture-review/assessment.md` predicted this exactly as the price of');
  w('generating the document from the JSON, and section 14 of');
  w('`docs/plan/11d-per-level-document/document-contract.md` decided to pay it rather than guess.');
  w();
  w('The mapping exists, written by hand, in `docs/plan/11c-movement-shapes/shape-catalogue.md` under');
  w('"What points at what".');
  w();

  return { path: path.join(OUT_DIR, `${levelId}.md`), text: out.join('\n').replace(/\n+$/, '\n') };
}

// ------------------------------------------------------------------------------------------------

/**
 * One index across every level: which wave ids exist, and who places them.
 *
 * `assets/data/waves.json` is a single shared file with globally unique ids, and reuse across levels
 * is the reason phase 11b split waves from placements at all — but each level's document lists only
 * the waves that level places, so a designer could neither avoid an id collision nor find a reusable
 * wave without reading every other level's document. That is exactly the lookup outside the document
 * the contract's bar exists to remove. Found by task 4's read-back, #190, correction C5.
 *
 * Its own file, deliberately. The contract refuses a cross-level comparison *inside* a level's
 * document, because then every level's document changes when any level does; a separate file has no
 * such coupling.
 */
function buildWaveIndex(levels, content) {
  const { waves, enemies, formations } = content;
  const out = [];
  const w = (line = '') => out.push(line);

  w('# Every wave, and who places it');
  w();
  w('**This file is generated. Do not edit it by hand.** `tools/build-level-docs.js` writes it from');
  w('`assets/data/waves.json` and every `assets/data/level-NN.json`, and `.github/workflows/ci.yml`');
  w('fails if it drifts.');
  w();
  w('`waves.json` is **one shared file across every level** and its ids are global. A new wave needs an');
  w('id nothing here already uses, and a wave already here can be placed again instead of copied — an');
  w('edit to it then lands on every placement below.');
  w();
  const rows = [];
  // Ordered by the file, not by a map, so the output is stable.
  for (const wave of [...waves.values()]) {
    const entities = wave.spawns.reduce((n, sp) => n + entitiesOf(sp, formations), 0);
    const archetypes = [];
    for (const sp of wave.spawns) if (!archetypes.includes(sp.spawn)) archetypes.push(sp.spawn);
    const places = [];
    for (const { file, level } of levels) {
      const { rows: timeline_ } = timeline(level, waves);
      for (const r of timeline_) {
        if (r.placement.wave === wave.id) {
          places.push(`\`${path.basename(file, '.json')}\` #${r.i + 1} at ${r.exact ? '' : '>= '}${s1(r.start)} s`);
        }
      }
    }
    rows.push([
      `\`${wave.id}\``,
      wave.end.type === 'fixedDuration' ? `${s1(wave.end.seconds)} s` : '`cleared`',
      String(wave.spawns.length),
      String(entities),
      archetypes.map((a) => `\`${a}\``).join(' '),
      places.length ? places.join(', ') : '**unplaced**',
    ]);
  }
  w(table(['wave', 'lasts', 'spawns', 'entities', 'archetypes', 'placed by'], rows));
  w();
  w('**`unplaced`** is a wave no level uses. Not an error — `waves.json` is a library — but it is dead');
  w('content until something places it, and nothing else in the repository would tell you.');
  w();
  w('Archetypes come from `assets/data/enemies.json`'
    + ` (${enemies.size} of them) and formations from \`assets/data/formations.json\`.`);
  w('Each level\'s own document has the rest: the pacing, the roster, the checks.');
  w();
  return { path: path.join(OUT_DIR, 'waves.md'), text: out.join('\n').replace(/\n+$/, '\n') };
}

function main() {
  const check = process.argv.includes('--check');
  const content = {
    waves: index(readJson('waves.json').waves, 'waves'),
    enemies: index(readJson('enemies.json').enemies, 'archetypes'),
    formations: index(readJson('formations.json').formations, 'formations'),
    trajectories: resolveTrajectories(index(readJson('trajectories.json').trajectories, 'trajectories')),
    attachments: index(readJson('attachments.json').attachments, 'attachments'),
    balance: readJson('balance.json'),
  };

  const levelFiles = fs.readdirSync(DATA).filter((f) => /^level-\d+\.json$/.test(f)).sort();
  if (levelFiles.length === 0) die('no level-NN.json in assets/data/');

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const documents = levelFiles.map((file) =>
    buildLevel(file, Object.assign({}, content, { level: readJson(file) })));
  documents.push(buildWaveIndex(levelFiles.map((f) => ({ file: f, level: readJson(f) })), content));

  let stale = 0;
  for (const built of documents) {
    const relative = path.relative(ROOT, built.path).split(path.sep).join('/');
    const existing = fs.existsSync(built.path) ? fs.readFileSync(built.path, 'utf8') : null;
    if (existing === built.text) {
      process.stdout.write(`unchanged  ${relative}\n`);
      continue;
    }
    if (check) {
      stale += 1;
      process.stdout.write(`STALE      ${relative}\n`);
      continue;
    }
    fs.writeFileSync(built.path, built.text);
    process.stdout.write(`${existing === null ? 'written' : 'updated'}    ${relative}\n`);
  }
  if (check && stale > 0) {
    process.stderr.write(
      `\n${stale} level document(s) do not match assets/data/.\n\n`
      + 'The JSON is the source and the document is generated from it, so this means either the\n'
      + 'content changed without the document being regenerated, or the document was edited by\n'
      + 'hand. Either way, run:\n\n'
      + '    node tools/build-level-docs.js\n\n'
      + 'and commit the result.\n');
    process.exit(1);
  }
}

main();
