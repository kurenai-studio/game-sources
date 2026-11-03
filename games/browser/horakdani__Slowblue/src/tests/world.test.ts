import { describe, expect, it } from 'vitest';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { World } from '../src/sim/World';
import { MIN_SHOAL } from '../src/sim/RunState';
import { contactRequirement } from '../src/sim/RescueSystem';
import { MAIN_FACTION } from '../src/sim/Agent';
import type { Section } from '../src/sim/ObstacleSystem';
import { makeAimBot } from './bot';
import { H, W } from './helpers';

/**
 * Slowblue: these tests drive *generated* water on purpose.
 *
 * They are about the World's own machinery - camera, pruning, spawning, splitting -
 * and that machinery has to hold for any course, so it is tested against the one
 * course nobody has hand-tuned. The authored campaign has its own two suites:
 * `tests/levels.test.ts` for its geometry and `tests/campaign.test.ts` for whether
 * a player can fly it.
 */
function makeWorld(seed = 42, agentCount = 60): World {
  return new World(W, H, seed, { ...DEFAULT_TUNING, agentCount }, false);
}

function fingerprint(world: World): number[] {
  const out: number[] = [];
  for (const a of world.swarm.agents) {
    if (!a.alive) continue;
    out.push(a.x, a.y, a.vx, a.vy, a.faction);
  }
  out.push(world.cameraY, world.run.score, world.run.lost, world.run.gates);
  return out;
}

/**
 * Every section the renderer would paint this frame, by id: the live course plus
 * the sections it has finished with that are still in shot. `Renderer` reads the
 * two lists in exactly this pair.
 */
function drawnSections(world: World): Map<number, Section> {
  const out = new Map<number, Section>();
  for (const s of world.obstacles.retired) out.set(s.id, s);
  for (const s of world.obstacles.sections) out.set(s.id, s);
  return out;
}

function drive(world: World, steps: number, stroke = true): void {
  for (let i = 0; i < steps; i++) {
    if (stroke && i % 20 === 0) {
      const y = world.screenToWorldY(H * 0.6);
      world.injectStroke(W * 0.3, y, W * 0.7, y - 20, 0.05);
    }
    world.step(1 / 60);
  }
}

describe('World lifecycle', () => {
  it('starts a run without any menu step and with a live shoal', () => {
    const world = makeWorld();
    expect(world.run.phase).toBe('running');
    expect(world.shoalCount).toBe(60);
    expect(world.obstacles.sections.length).toBeGreaterThan(0);
  });

  it('is deterministic for a given seed and input sequence', () => {
    const a = makeWorld(1234);
    const b = makeWorld(1234);
    drive(a, 240);
    drive(b, 240);
    expect(fingerprint(a)).toEqual(fingerprint(b));
  });

  it('produces different runs for different seeds', () => {
    const a = makeWorld(1);
    const b = makeWorld(2);
    drive(a, 180);
    drive(b, 180);
    expect(fingerprint(a)).not.toEqual(fingerprint(b));
  });

  it('advances the camera and never rewinds it', () => {
    const world = makeWorld();
    let prev = world.cameraY;
    for (let i = 0; i < 300; i++) {
      world.step(1 / 60);
      expect(world.cameraY).toBeLessThanOrEqual(prev + 1e-9);
      prev = world.cameraY;
    }
    expect(world.run.distance).toBeGreaterThan(100);
  });

  /**
   * The camera on the same clock as the fish.
   *
   * A frame is drawn somewhere *between* two simulation steps, and the shoal has
   * always been drawn there - `a.py + (a.y - a.py) * alpha`. The camera was drawn
   * at the step, so a frame that ran no step moved the whole course by nothing and
   * the next one moved it by double, while the shoal slid smoothly through it. It
   * takes no dropped frame to see: a display holding a clean 60 drifts against a
   * 1/60 accumulator either way, which is why this reads as an intermittent judder
   * on hardware whose frame times are fine.
   */
  it('draws the camera at the same moment as the fish', () => {
    const world = makeWorld();
    drive(world, 120);
    const before = world.cameraY;
    world.step(1 / 60);
    const after = world.cameraY;
    expect(after).not.toBeCloseTo(before, 6);

    // Alpha 0 is the step that just ended, alpha 1 the one the simulation is on,
    // and the frame in between is genuinely in between - not held, not doubled.
    world.setViewAlpha(0);
    expect(world.viewCameraY).toBeCloseTo(before, 9);
    world.setViewAlpha(1);
    expect(world.viewCameraY).toBeCloseTo(after, 9);
    world.setViewAlpha(0.5);
    expect(world.viewCameraY).toBeCloseTo((before + after) / 2, 9);
    // And the drawing's own converter goes with it, because a rock read through
    // the step's camera in a frame drawn on the interpolated one is the same
    // seam, one layer down.
    expect(world.viewY(0)).toBeCloseTo(-(before + after) / 2, 9);
  });

  it('keeps the frame out of the simulation: drawing changes nothing that is stepped', () => {
    // The reason `viewY` exists beside `worldToScreenY` rather than replacing it,
    // and the reason the drawn camera's catch-up is allowed to exist at all. A
    // render-time number that reaches a rule inside the step takes replay by seed
    // with it, and every sweep and probe in this repo rests on that.
    const plain = makeWorld(11);
    const drawn = makeWorld(11);
    for (let i = 0; i < 300; i++) {
      plain.step(1 / 60);
      drawn.step(1 / 60);
      drawn.advanceView((i % 7) / 7, 1 / 60);
    }
    expect(fingerprint(drawn)).toEqual(fingerprint(plain));
  });

  /**
   * The drawn camera closes on the simulated one; it never teleports to it.
   *
   * Measured over three real runs before this existed: the ordinary camera step is
   * 1.6 px and the worst single step was 99.7 px, because the centroid the follow
   * chases jumps whenever the fish at the back are lost and because a shoal
   * steered past the anchor puts the target in front of a camera that had drifted
   * ahead of it. Both land in one step. Reported from an iPad as the course
   * surging while the shoal is steered.
   */
  it('eases the drawn camera over a jump the simulated one takes in a single step', () => {
    const world = makeWorld();
    drive(world, 120);
    world.advanceView(1, 1 / 60);
    const settled = world.viewCameraY;
    expect(settled).toBeCloseTo(world.cameraY, 6);

    // A centroid discontinuity, by hand: what losing the back of the shoal does.
    const jump = 100 * world.direction;
    world.cameraY += jump;
    world.prevCameraY = world.cameraY;
    world.advanceView(1, 1 / 60);
    const moved = Math.abs(world.viewCameraY - settled);
    expect(moved).toBeGreaterThan(0);
    // A frame of drift is ~1.6px, so the ceiling is a few px - nowhere near 100.
    expect(moved).toBeLessThan(8);

    // ...and it is a lag, not a loss: the drawing arrives where the rules are.
    for (let i = 0; i < 120; i++) world.advanceView(1, 1 / 60);
    expect(world.viewCameraY).toBeCloseTo(world.cameraY, 6);
  });

  it('never eases into a jump the player is meant to see', () => {
    // A restart and a rotation both move the camera by hand, and easing into
    // either would draw the new frame sliding into place. `resize` is the one that
    // matters: the reframing exists to stop the shoal sliding down the glass, so
    // drawing it *as* a slide would undo it.
    const world = makeWorld();
    drive(world, 120);
    world.advanceView(1, 1 / 60);
    world.resize(H, W);
    world.advanceView(1, 1 / 60);
    expect(world.viewCameraY).toBeCloseTo(world.cameraY, 6);

    world.reset(11);
    world.advanceView(1, 1 / 60);
    expect(world.viewCameraY).toBeCloseTo(world.cameraY, 6);
  });

  it('loses individuals to rocks without ending the run', () => {
    const world = makeWorld(7);
    const blob = world.obstacles.activeBlobs[Math.floor(world.obstacles.activeBlobs.length / 2)]!;
    let moved = 0;
    for (const a of world.swarm.agents) {
      if (!a.alive || a.faction !== MAIN_FACTION || moved >= 5) continue;
      a.x = blob.x;
      a.y = blob.y;
      moved++;
    }
    world.step(1 / 60);
    expect(world.run.lost).toBe(5);
    expect(world.run.phase).toBe('running');
    expect(world.shoalCount).toBe(55);
  });

  it('ends the run when the shoal falls below the minimum', () => {
    const world = makeWorld(7);
    let kept = 0;
    for (const a of world.swarm.agents) {
      if (!a.alive) continue;
      if (kept < MIN_SHOAL - 1) kept++;
      else a.alive = false;
    }
    world.step(1 / 60);
    expect(world.run.phase).toBe('over');
    expect(world.run.reason).toBe('depleted');
  });

  it('ends the run when the shoal is swept off the back of the screen', () => {
    const world = makeWorld(7);
    world.tuning.migrationForce = 0;
    world.tuning.cruiseSpeed = 0;
    world.tuning.worldSpeed = 220;
    for (let i = 0; i < 60 * 8 && world.run.phase === 'running'; i++) world.step(1 / 60);
    expect(world.run.phase).toBe('over');
    expect(world.run.reason).toBe('sweptAway');
  });

  it('freezes run progress once the run is over', () => {
    const world = makeWorld(7);
    world.run.fail('depleted');
    const time = world.run.time;
    const camera = world.cameraY;
    for (let i = 0; i < 60; i++) world.step(1 / 60);
    expect(world.run.time).toBe(time);
    expect(world.cameraY).toBe(camera);
  });

  it('fully resets on restart, including seed replay', () => {
    const a = makeWorld(2024);
    drive(a, 200);
    const mid = fingerprint(a);
    a.reset(2024);
    expect(a.run.time).toBe(0);
    expect(a.run.lost).toBe(0);
    expect(a.run.gates).toBe(0);
    expect(a.run.score).toBe(0);
    expect(a.gestureCount).toBe(0);
    expect(a.hasInput).toBe(false);
    expect(a.wake.length).toBe(0);
    expect(a.field.meanSpeed()).toBe(0);
    expect(a.shoalCount).toBe(60);
    drive(a, 200);
    expect(fingerprint(a)).toEqual(mid);
  });

  it('counts a cleared section once the shoal crosses its line', () => {
    const world = makeWorld(7);
    const section = world.obstacles.sections[0]!;
    for (const a of world.swarm.agents) {
      if (!a.alive || a.faction !== MAIN_FACTION) continue;
      a.y = section.lineY - 100;
      a.x = W * 0.5;
    }
    world.step(1 / 60);
    expect(world.run.gates).toBe(1);
    expect(world.run.score).toBeGreaterThan(0);
    world.step(1 / 60);
    expect(world.run.gates).toBe(1);
  });

  it('credits a section whose geometry reaches back behind its own line', () => {
    // Regression: progress used to be counted after `obstacles.prune`, and a
    // narrows funnel reaches 240px behind its scoring line - further back than the
    // camera's prune line at the moment the shoal crosses. The section was dropped
    // in the same step that should have counted it, so clearing a funnel paid
    // nothing. Every archetype that extends backwards has to survive this.
    for (const kind of ['narrows', 'drift'] as const) {
      const world = makeWorld(7);
      world.obstacles.ensureAhead(-30000);
      const section = world.obstacles.sections.find((s) => s.kind === kind)!;
      for (const s of world.obstacles.sections) if (s.id < section.id) s.passed = true;
      world.cameraY = section.lineY - 60 - H * 0.62;
      for (const a of world.swarm.agents) {
        if (a.alive && a.faction === MAIN_FACTION) a.y = section.lineY - 60;
      }
      // The precondition that made this a bug: the old rule would have dropped this
      // section on this very step, because its rearmost blob is already behind the
      // prune line while its scoring line is still in front of the shoal.
      expect(section.maxY, kind).toBeGreaterThan(world.cameraY + H * 0.9);
      world.step(1 / 60);
      expect(world.run.gates, kind).toBe(1);
    }
  });

  it('lets every section swim off the bottom instead of blinking out', () => {
    // Regression: `obstacles.prune` deleted a section on `behindLine`, a tenth of a
    // screen *inside* the trailing edge, and it deleted it whole - so the geometry
    // either side of the scoring line went with it. A rock the water was still
    // carrying down vanished with a fifth of the frame under it. Nothing on the
    // course may be removed while the player can still see it; it has to leave.
    const world = makeWorld(11);
    const bot = makeAimBot({ strokeDt: 0.4 });
    let drawn = drawnSections(world);
    let left = 0;
    for (let i = 0; i < 60 * 60 && world.run.phase === 'running'; i++) {
      bot(world, 1 / 60);
      world.step(1 / 60);
      const now = drawnSections(world);
      for (const [id, section] of drawn) {
        if (now.has(id)) continue;
        left++;
        // It left the picture this step, so the last edge of it to go - `minY` on
        // a climb, radius included - has to be past the bottom of the screen.
        expect(section.minY - world.cameraY, `section ${id}`).toBeGreaterThan(H);
      }
      drawn = now;
    }
    // ...and enough of the course really did go by, so the loop proved something.
    expect(left).toBeGreaterThan(2);
  });

  it('emits events and drains them exactly once', () => {
    const world = makeWorld(7);
    const blob = world.obstacles.activeBlobs[0]!;
    const victim = world.swarm.agents.find((a) => a.alive)!;
    victim.x = blob.x;
    victim.y = blob.y;
    world.step(1 / 60);
    expect(world.takeEvents().some((e) => e.type === 'loss')).toBe(true);
    expect(world.takeEvents().length).toBe(0);
  });

  it('gives a rock section a pod in each side channel, far enough apart to matter', () => {
    const world = makeWorld(3);
    const rock = world.obstacles.sections.find((s) => s.kind === 'rock')!;
    expect(rock.podHints.length).toBe(2);
    const gap = Math.abs(rock.podHints[0]!.x - rock.podHints[1]!.x);
    // Wider than a healthy shoal: one body cannot hold both rings at once.
    expect(gap).toBeGreaterThan(W * 0.35);
  });

  it('spawns rescue pods once their section comes into range', () => {
    const world = makeWorld(3);
    // The first rock is close enough to seed its pods immediately.
    expect(world.rescue.pods.length).toBe(2);
    // Jump the camera to the first narrows; its pod must appear, further ahead.
    world.cameraY = -2500;
    world.step(1 / 60);
    const ahead = world.rescue.pods.filter((p) => p.y < -2000);
    expect(ahead.length).toBeGreaterThan(0);
    expect(world.swarm.aliveCount(ahead[0]!.id)).toBeGreaterThan(0);
  });

  it('scales the rescue commitment with shoal size', () => {
    // A bigger shoal must commit more of itself, so growth never makes pods cheaper.
    expect(contactRequirement(20, 0.28)).toBe(8);
    expect(contactRequirement(100, 0.28)).toBe(28);
    expect(contactRequirement(300, 0.28)).toBe(84);
  });

  /**
   * Places the shoal in two halves just behind a section's geometry - inside the
   * re-form window, outside anything solid. Returns the setter.
   */
  function placer(world: World, section: { maxY: number }): (spreadPx: number) => void {
    const agents = world.swarm.agents.filter((a) => a.alive && a.faction === MAIN_FACTION);
    return (spreadPx: number) => {
      agents.forEach((a, i) => {
        a.x = W * 0.5 + (i % 2 === 0 ? -spreadPx : spreadPx);
        a.y = section.maxY + 100;
        a.vx = 0;
        a.vy = 0;
      });
    };
  }

  it('credits a split only once it is brought back together', () => {
    const world = makeWorld(7, 60);
    // Only on an archetype with a central mass: a shoal torn apart on a funnel is
    // coming apart, not executing a tactic.
    const section = world.obstacles.sections.find((s) => s.kind === 'rock')!;
    const place = placer(world, section);
    // Torn in two on the section: split detected, but nothing credited yet.
    place(140);
    world.step(1 / 60);
    expect(world.run.reforms).toBe(0);
    // Back into one body: credited exactly once.
    place(20);
    world.step(1 / 60);
    expect(world.run.reforms).toBe(1);
    place(140);
    world.step(1 / 60);
    place(20);
    world.step(1 / 60);
    expect(world.run.reforms).toBe(1);
  });

  it('pays nothing for a shoal that came apart on a funnel', () => {
    const world = makeWorld(7, 60);
    world.obstacles.ensureAhead(-6000);
    const section = world.obstacles.sections.find((s) => s.kind === 'narrows')!;
    const place = placer(world, section);
    place(140);
    world.step(1 / 60);
    place(20);
    world.step(1 / 60);
    expect(world.run.reforms).toBe(0);
  });
});

describe('World hazards and depth', () => {
  /** Pushes the camera to a world Y and lets the world spawn whatever is due. */
  function jumpTo(world: World, cameraY: number): void {
    world.cameraY = cameraY;
    world.obstacles.ensureAhead(cameraY - H * 1.6);
    for (const a of world.swarm.agents) {
      if (a.alive && a.faction === MAIN_FACTION) a.y = cameraY + H * 0.6;
    }
    world.step(1 / 60);
  }

  it('spawns a section\'s standing currents and hunters with the section', () => {
    const world = makeWorld(5);
    world.obstacles.ensureAhead(-30000);
    const vortexSection = world.obstacles.sections.find((s) => s.kind === 'vortex')!;
    const hunterSection = world.obstacles.sections.find((s) => s.kind === 'predator')!;
    jumpTo(world, vortexSection.minY + H * 1.2);
    expect(world.currents.vortices.some((v) => v.sectionId === vortexSection.id)).toBe(true);
    jumpTo(world, hunterSection.minY + H * 1.2);
    expect(world.predators.predators.some((p) => p.sectionId === hunterSection.id)).toBe(true);
  });

  it('folds standing currents into the one water sampler the shoal feels', () => {
    const world = makeWorld(5);
    const out = { x: 0, y: 0 };
    world.currents.add({
      x: W * 0.5,
      y: 0,
      radius: 120,
      strength: 200,
      sectionId: 1,
      phase: 0,
    });
    world.water.sample(W * 0.5 + 60, 0, out);
    expect(Math.hypot(out.x, out.y)).toBeGreaterThan(100);
    // ...and the tuning knob turns the whole course's water off.
    world.tuning.vortexStrength = 0;
    world.water.sample(W * 0.5 + 60, 0, out);
    expect(Math.hypot(out.x, out.y)).toBeLessThan(80);
  });

  it('counts a hunter\'s kill as a loss, with its own event', () => {
    const world = makeWorld(9);
    const victim = world.swarm.agents.find((a) => a.alive && a.faction === MAIN_FACTION)!;
    const hunter = world.predators.spawn(victim.x, victim.y + 6, 16, 1, 0);
    hunter.cooldown = 0;
    world.step(1 / 60);
    const events = world.takeEvents();
    expect(events.some((e) => e.type === 'bite')).toBe(true);
    // A strike is flagged as the most severe kind of loss, for shake and audio.
    expect(events.some((e) => e.type === 'loss' && e.value === 2)).toBe(true);
    expect(world.run.lost).toBe(1);
  });

  it('drops hazards the camera has left behind', () => {
    const world = makeWorld(5);
    world.currents.add({ x: 10, y: 0, radius: 40, strength: 60, sectionId: 1, phase: 0 });
    world.predators.spawn(10, 0, 16, 1, 0);
    world.cameraY = -4000;
    world.step(1 / 60);
    expect(world.currents.vortices.length).toBe(0);
    expect(world.predators.predators.length).toBe(0);
  });

  it('reports the zone of the section ahead, not the one already cleared', () => {
    const world = makeWorld(5);
    expect(world.zone).toBe(0);
    world.obstacles.ensureAhead(-30000);
    for (const s of world.obstacles.sections) {
      if (s.id < 14) s.passed = true;
    }
    expect(world.zone).toBe(2);
  });

  it('announces a new zone exactly once, when its first section is cleared', () => {
    const world = makeWorld(5);
    world.obstacles.ensureAhead(-30000);
    const first = world.obstacles.sections.find((s) => s.zone === 1)!;
    for (const s of world.obstacles.sections) if (s.id < first.id) s.passed = true;
    for (const a of world.swarm.agents) {
      if (a.alive && a.faction === MAIN_FACTION) a.y = first.lineY - 100;
    }
    world.step(1 / 60);
    const events = world.takeEvents();
    expect(events.filter((e) => e.type === 'zone').length).toBe(1);
    expect(world.run.zone).toBe(1);
    world.step(1 / 60);
    expect(world.takeEvents().filter((e) => e.type === 'zone').length).toBe(0);
  });

  it('reports a broken streak so the player is told why the multiplier went', () => {
    const world = makeWorld(7);
    world.run.streak = 3;
    const blob = world.obstacles.activeBlobs[0]!;
    let moved = 0;
    for (const a of world.swarm.agents) {
      if (!a.alive || a.faction !== MAIN_FACTION || moved >= 6) continue;
      a.x = blob.x;
      a.y = blob.y;
      moved++;
    }
    world.step(1 / 60);
    expect(world.run.streak).toBe(0);
    expect(world.takeEvents().some((e) => e.type === 'streakBreak')).toBe(true);
  });

  it('clears hazards on reset so no run inherits the last one\'s water', () => {
    const world = makeWorld(5);
    world.currents.add({ x: 10, y: 0, radius: 40, strength: 60, sectionId: 1, phase: 0 });
    world.predators.spawn(10, 0, 16, 1, 0);
    world.reset(5);
    expect(world.currents.vortices.length).toBe(0);
    expect(world.predators.predators.length).toBe(0);
    expect(world.run.zone).toBe(0);
    expect(world.run.streak).toBe(0);
  });
});

describe('resize keeps a run intact', () => {
  it('rescales everything with an X so a rotation cannot wall the shoal', () => {
    const world = makeWorld(11);
    world.obstacles.ensureAhead(-4000);
    world.currents.add({
      x: W * 0.5,
      y: -500,
      radius: 100,
      strength: 90,
      sectionId: 1,
      phase: 0,
    });
    const hunter = world.predators.spawn(W * 0.8, -400, 16, 1, 0);
    const pod = world.rescue.pods[0]!;
    const before = {
      centroid: world.swarm.centroid().x / W,
      hunter: hunter.x / W,
      pod: pod.x / W,
      blob: world.obstacles.activeBlobs[0]!.x / W,
      vortex: world.currents.vortices[0]!.x / W,
    };

    const narrow = Math.round(W * 0.6);
    world.resize(narrow, H);

    expect(world.swarm.centroid().x / narrow).toBeCloseTo(before.centroid, 6);
    expect(hunter.x / narrow).toBeCloseTo(before.hunter, 6);
    expect(pod.x / narrow).toBeCloseTo(before.pod, 6);
    expect(world.obstacles.activeBlobs[0]!.x / narrow).toBeCloseTo(before.blob, 6);
    expect(world.currents.vortices[0]!.x / narrow).toBeCloseTo(before.vortex, 6);
    // ...and nobody ends up outside the new walls.
    for (const a of world.swarm.agents) {
      if (!a.alive) continue;
      expect(a.x).toBeGreaterThan(-1);
      expect(a.x).toBeLessThan(narrow + 1);
    }
  });

  it('keeps the run going and does not respawn the shoal', () => {
    const world = makeWorld(11);
    drive(world, 60);
    const count = world.shoalCount;
    world.resize(Math.round(W * 1.4), H);
    world.step(1 / 60);
    expect(world.shoalCount).toBe(count);
    expect(world.run.phase).toBe('running');
  });

  /**
   * The half of a rotation the two tests above never touch: they change the width
   * and hold the height, which is a Split View drag rather than a turn of the
   * device. Both of the numbers that decide what is still part of the run are
   * stated as fractions of the *height* - `behindLine` at 0.9 of the frame,
   * `buildLine` at 1.6 ahead - and the camera holds the shoal at `anchorFraction`
   * of it. Shorten the frame without moving the camera and the shoal slides down
   * the glass onto the line that ends things: measured on the shipped build at
   * 820x1180, one rotation to landscape put it at 0.90 of the frame.
   *
   * What that costs is not cosmetic. On that line the course retires around the
   * shoal - and a retired section is still drawn while it no longer collides or
   * steers, which is exactly "the rocks stopped affecting the shoal" as it was
   * reported from an iPad.
   */
  it('holds the shoal at the same place on the glass when the frame changes shape', () => {
    const world = makeWorld(11);
    drive(world, 240);
    const before = world.worldToScreenY(world.swarm.centroid(MAIN_FACTION).y) / world.height;
    const drawnBefore = drawnSections(world).size;
    const liveBefore = world.obstacles.sections.length;
    const podsBefore = world.rescue.pods.length;
    const shoalBefore = world.shoalCount;

    // The turn itself: the same glass, the other way up.
    world.resize(H, W);

    const after = world.worldToScreenY(world.swarm.centroid(MAIN_FACTION).y) / world.height;
    expect(after).toBeCloseTo(before, 6);
    // Nothing may leave the run for having been reframed: the course does not
    // retire, the rings do not drop off the back, and no straggler is culled.
    expect(world.obstacles.sections.length).toBe(liveBefore);
    expect(drawnSections(world).size).toBe(drawnBefore);
    expect(world.rescue.pods.length).toBe(podsBefore);
    world.step(1 / 60);
    expect(world.shoalCount).toBe(shoalBefore);
    expect(world.run.phase).toBe('running');
  });

  /**
   * A section is built long before it is entered, and it carries where its rings,
   * hunters, currents and wells go. Those coordinates used to be left at the old
   * width while the rocks beside them were rescaled, so a section built in one
   * shape and entered in another put its content somewhere else - and going from
   * wide to narrow puts it off the edge, where a *required* ring ends the dive by
   * being lost.
   */
  it('carries the hints beside the rocks, not just the rocks', () => {
    const world = makeWorld(11);
    world.obstacles.ensureAhead(-6000);
    const withPods = world.obstacles.sections.find((s) => s.podHints.length > 0);
    const withHunters = world.obstacles.sections.find((s) => s.hunterHints.length > 0);
    expect(withPods).toBeDefined();
    const podBefore = withPods!.podHints[0]!.x / W;
    const hunterBefore = withHunters ? withHunters.hunterHints[0]!.x / W : null;

    const narrow = Math.round(W * 0.6);
    world.resize(narrow, H);

    expect(withPods!.podHints[0]!.x / narrow).toBeCloseTo(podBefore, 6);
    if (withHunters && hunterBefore !== null) {
      expect(withHunters.hunterHints[0]!.x / narrow).toBeCloseTo(hunterBefore, 6);
    }
    // ...and every hint is inside the walls it will spawn against.
    for (const s of world.obstacles.sections) {
      for (const p of s.podHints) expect(p.x).toBeLessThanOrEqual(narrow);
      for (const h of s.hunterHints) expect(h.x).toBeLessThanOrEqual(narrow);
    }
  });
});

describe('growth costs manoeuvrability', () => {
  it('raises the mass factor as the shoal grows', () => {
    const world = makeWorld(5, 60);
    expect(world.massFactor).toBeCloseTo(1, 6);
    world.swarm.spawnShoal(60, W * 0.5, 0, 30);
    expect(world.massFactor).toBeGreaterThan(1.3);
  });

  it('makes a bigger shoal respond less to the same gesture', () => {
    const displacement = (extra: number): number => {
      const world = makeWorld(9, 60);
      if (extra > 0) world.swarm.spawnShoal(extra, W * 0.5, 0, 30);
      // Isolate the drag term: no swim, no boids, no course, and a gentle current
      // so nobody clips max speed (which would hide the mass difference).
      Object.assign(world.tuning, {
        worldSpeed: 0,
        migrationForce: 0,
        cruiseSpeed: 0,
        separation: 0,
        cohesion: 0,
        alignment: 0,
        noise: 0,
        flowStrength: 150,
      });
      for (const a of world.swarm.agents) {
        a.vx = 0;
        a.vy = 0;
      }
      const startX = world.swarm.centroid().x;
      const y = world.screenToWorldY(H * 0.62);
      world.injectStroke(W * 0.25, y, W * 0.75, y, 0.25);
      for (let i = 0; i < 60; i++) world.step(1 / 60);
      return world.swarm.centroid().x - startX;
    };
    const light = displacement(0);
    const heavy = displacement(120);
    expect(light).toBeGreaterThan(5);
    expect(heavy).toBeLessThan(light);
  });
});
