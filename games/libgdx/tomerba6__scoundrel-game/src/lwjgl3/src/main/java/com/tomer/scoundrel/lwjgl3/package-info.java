/**
 * The desktop launcher: the only platform module, and a thin one.
 *
 * <p>{@link com.tomer.scoundrel.lwjgl3.Lwjgl3Launcher} configures the LWJGL3
 * window, installs the crash log and hands control to
 * {@link com.tomer.scoundrel.ScoundrelGame}. No game logic lives here: rules,
 * screens and persistence are all in {@code core}.
 * {@link com.tomer.scoundrel.lwjgl3.StartupHelper} is third-party code, kept as
 * it came, that restarts the JVM where LWJGL3 needs it.
 *
 * @see com.badlogic.gdx.backends.lwjgl3
 */
package com.tomer.scoundrel.lwjgl3;
