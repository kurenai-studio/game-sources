/**
 * The composition root: the navigator, and the few pure pieces that span
 * packages.
 *
 * <p>{@link com.tomer.scoundrel.ScoundrelGame} is the LibGDX application. It
 * builds the shared resources and stores, switches screens, and owns what
 * outlives a screen: the music and the keys that work everywhere. It is the
 * one class here that touches LibGDX, so this package is not coverage-gated,
 * although its other classes are pure and tested:
 * {@link com.tomer.scoundrel.CrashLog} (uncaught crashes to
 * {@code ~/.scoundrel/crash.log}, never throws),
 * {@link com.tomer.scoundrel.Progress} (the full reset across runs,
 * achievements and the tutorial flag) and
 * {@link com.tomer.scoundrel.LaunchSwitch} (the developer switches).
 *
 * <p>Everything the game saves lives under {@code ~/.scoundrel/}.
 *
 * @see com.badlogic.gdx.Game
 */
package com.tomer.scoundrel;
