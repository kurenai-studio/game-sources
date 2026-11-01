/**
 * The guided first run: a scripted deck, narrated steps, the gating state
 * machine and the seen flag.
 *
 * <p>{@link com.tomer.scoundrel.tutorial.TutorialScript} holds a curated
 * 14-card dungeon, played on the standard ruleset through the engine's public
 * ordered-deck entry, and the beats that narrate it.
 * {@link com.tomer.scoundrel.tutorial.TutorialGuide} walks those beats and
 * says which move, if any, the player may make. The screen asks it and never
 * decides on its own. {@link com.tomer.scoundrel.tutorial.TutorialFlag}
 * remembers that the tutorial has been offered, so it is auto-offered only on
 * the first launch.
 *
 * <p>Pure Java with no LibGDX, and gated by the coverage check. The script is
 * proven by a headless engine playthrough, so a change to it that makes a step
 * illegal fails a test rather than stranding a player. The tutorial
 * <em>mode</em> (the overlay and the input gating) lives in the screens, not
 * here. A tutorial game is recorded nowhere.
 */
package com.tomer.scoundrel.tutorial;
