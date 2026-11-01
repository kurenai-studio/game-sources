package dev.luchoc.littlespaceship.core.domain.event;

/**
 * An {@code ENEMY}-layer entity — a basic enemy, a tank, a carrier, or one of the boss's six parts —
 * was destroyed, wherever it died: ramming, a player projectile, a bomb, or the boss's own defeat.
 *
 * <p>The first concrete {@link GameEvent} this codebase has ever built. Named in {@code
 * 12-architecture.md}'s own event list from the start; deferred through every earlier phase for lack
 * of a real consumer — see {@code core-deferred-surface.md} — until the audio lane needed a trigger
 * for the explosion sound and found none: {@code CleanupSystem} destroyed things and nothing recorded
 * that it happened.
 *
 * <p>{@code x}/{@code y} is where the entity was the tick it died, in logical units, read before
 * {@code World.destroyEntity} strips its {@link
 * dev.luchoc.littlespaceship.core.domain.component.Transform}. That is the one thing a consumer
 * reacting to a death actually needs — where to play the sound, where to draw the explosion — so the
 * shape stays to exactly that, per the same discipline {@code content-pipeline-design.md} already
 * applied to every other content contract built ahead of a guess.
 *
 * @param x horizontal position the entity died at, in logical units
 * @param y vertical position the entity died at, in logical units, growing upward like {@code
 *     Transform}
 */
public record EnemyDestroyed(float x, float y) implements GameEvent {
}
