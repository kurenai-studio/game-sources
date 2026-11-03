import { describe, expect, it } from 'vitest';
import { DEFAULT_TUNING, cloneTuning } from '../src/config/tuning';
import { mediumFor } from '../src/sim/Medium';

/**
 * Slowblue: the Medium abstraction's one hard promise (DESIGN-ASCENT §13): water
 * resolves to the exact tuning fields act I always read, so the abstraction
 * cannot move a digit of the shipped game. The full proof is the unchanged water
 * sweep table; this is the unit-sized half.
 *
 * The second test is the ascent's own claim, and it is a claim about *feel*
 * rather than about a mechanic: air is the same simulation with the density taken
 * out. Lighter grip, longer-lived gusts, faster wings, cheaper to carry life in.
 * Nothing here says "and also there is lift", because there is not, and that is
 * the point of the file having been rewritten.
 */
describe('Medium', () => {
  it('water is the tuning, verbatim', () => {
    const t = cloneTuning(DEFAULT_TUNING);
    const m = mediumFor('water', t);
    expect(m.kind).toBe('water');
    expect(m.coupling).toBe(t.flowCoupling);
    expect(m.flowHalfLife).toBe(t.flowDecayHalfLife);
    expect(m.flowMaxSpeed).toBe(t.flowMaxSpeed);
    expect(m.migrationSpeed).toBe(t.migrationSpeed);
    expect(m.migrationForce).toBe(t.migrationForce);
    expect(m.inertiaPerAgent).toBe(t.inertiaPerAgent);
  });

  it('air grips less, holds a gust longer, and costs less to grow in', () => {
    const t = cloneTuning(DEFAULT_TUNING);
    const m = mediumFor('air', t);
    expect(m.kind).toBe('air');
    expect(m.coupling).toBe(t.airCoupling);
    expect(m.coupling).toBeLessThan(t.flowCoupling);
    // The one place air is the *more* generous medium: there is nothing up here
    // to dissipate a moving body of air, so a stroke outlives the hand.
    expect(m.flowHalfLife).toBeGreaterThan(t.flowDecayHalfLife);
    expect(m.flowMaxSpeed).toBeGreaterThan(t.flowMaxSpeed);
    // ...and *slower* unaided, which is the counter-intuitive half. A body of
    // life that makes way faster than the drift carrying the camera can never be
    // left behind, so nothing the player does would matter. See the note on
    // `airMigrationSpeed`: this is decision 37 one medium up.
    expect(m.migrationSpeed).toBeLessThan(t.migrationSpeed);
    // Added mass scales with the density of what you are dragging.
    expect(m.inertiaPerAgent).toBeLessThan(t.inertiaPerAgent);
    // ...and a bird that drops off the back is still flying.
    expect(m.stragglerMargin).toBeGreaterThan(mediumFor('water', t).stragglerMargin);
  });

  it('deposits momentum in both, until act IV lays potential', () => {
    const t = cloneTuning(DEFAULT_TUNING);
    expect(mediumFor('water', t).deposit).toBe('momentum');
    expect(mediumFor('air', t).deposit).toBe('momentum');
  });

  it('tracks live tuning edits, like the debug panel makes', () => {
    const t = cloneTuning(DEFAULT_TUNING);
    t.airCoupling = 2;
    t.airFlowHalfLife = 3;
    const m = mediumFor('air', t);
    expect(m.coupling).toBe(2);
    expect(m.flowHalfLife).toBe(3);
  });
});
