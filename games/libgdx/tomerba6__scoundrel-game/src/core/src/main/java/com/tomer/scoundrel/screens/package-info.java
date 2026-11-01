/**
 * The screens: everything that draws the game or turns input into moves, and
 * the one layer that depends on LibGDX.
 *
 * <p>A screen does two things: it draws the current state, and it translates
 * a click or a key into a call on the engine. It holds no rule logic. What a
 * move does comes from {@code ScoundrelEngine}, and what it looked like comes
 * from the events the move returned. The five navigable screens extend
 * {@link com.tomer.scoundrel.screens.PixelScreen}, whose {@code render} is
 * final. A screen overrides its hooks, never the frame, because drawing after
 * navigating away would read disposed GL memory.
 *
 * <p>The art has hard rules, all enforced here. Everything is drawn in
 * immediate mode (no Scene2D) at 1:1 onto a 1280×720 surface, which
 * {@link com.tomer.scoundrel.screens.PixelViewport} scales to the window at a
 * multiple of 0.5. Textures are {@code Nearest}-filtered, and positions are
 * whole pixels. Animation time is floored onto
 * {@link com.tomer.scoundrel.screens.Frames}: nothing tweens and nothing
 * rotates, except the potion bottle, whose nearest-filtered rotation can't
 * invent a colour. Every colour drawn is on the eighty-colour
 * {@link com.tomer.scoundrel.screens.Ramps} or in
 * {@link com.tomer.scoundrel.screens.UiPalette}. The torchlit backdrop is the
 * one deliberate exception, and stays smooth.
 *
 * <p>The layout numbers and the colours drawn in code are measured off the
 * reference render in {@code art-reference/}, which is the visual target for
 * every screen.
 *
 * <p>Half the package is pure. The layout numbers ({@code CardArt},
 * {@code BoardArt}, {@code HudArt}, {@code ScreenArt}), the effect timelines
 * ({@code WeaponKill}, {@code Barehanded}, {@code PotionDrink} and the rest),
 * the formatters and the hit-testing were pulled out of the GL classes into
 * small helpers that take no GL context, and are unit-tested headlessly. The
 * GL classes that remain only place things and are verified by screenshot. The
 * package-private helpers are why this layer's Javadoc is checked at package
 * visibility.
 *
 * <p>The binding rules for working here are in the package's
 * {@code CLAUDE.md}. Every component is described in {@code docs/ui.md}.
 *
 * @see com.badlogic.gdx.Screen
 * @see com.badlogic.gdx.graphics.Texture.TextureFilter#Nearest
 * @see com.tomer.scoundrel.ScoundrelGame
 */
package com.tomer.scoundrel.screens;
