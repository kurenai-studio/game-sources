package dev.luchoc.littlespaceship.core.domain.event;

/**
 * Something that happened in the simulation and that the outside may want to react to.
 *
 * <p>Events only travel outwards. Inside the simulation systems call each other directly, because a
 * flow of rules that jumps through a bus is impossible to follow and to test. Towards presentation
 * they are the whole contract: audio, HUD, particles and camera shakes hook in here, and the core
 * never learns that any of them exist.
 *
 * <p>Every implementation must be immutable. What crosses a boundary cannot be modified by whoever
 * receives it.
 *
 * <p>The concrete events —an enemy destroyed, the player hit, a power-up taken— arrive with the
 * systems that emit them. Declaring them before anything can raise them would be inventing their
 * contents.
 */
public interface GameEvent {
}
