package com.tomer.scoundrel.lwjgl3;

import com.badlogic.gdx.Graphics;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.tomer.scoundrel.CrashLog;
import com.tomer.scoundrel.LaunchSwitch;
import com.tomer.scoundrel.ScoundrelGame;

import java.nio.file.Path;

/**
 * Launches the desktop (LWJGL3) application: borderless-fullscreen at the
 * monitor's resolution, vsynced, with crashes recorded to disk. A thin launcher
 * by design — everything the game does lives in {@code core}.
 *
 * @see com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application
 * @see com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration
 */
public class Lwjgl3Launcher {

    /** Never constructed: the launcher is only run, through {@link #main}. */
    public Lwjgl3Launcher() {
    }

    /**
     * The entry point. Restarts the JVM first where the platform needs it (macOS,
     * and Linux on NVIDIA), then installs the crash log and opens the window.
     *
     * @param args ignored; switches come from system properties or the environment
     *             (see {@link com.tomer.scoundrel.LaunchSwitch})
     */
    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) return; // This handles macOS support and helps on Windows.
        installCrashLog();
        createApplication();
    }

    /**
     * Record any uncaught crash to {@code ~/.scoundrel/crash.log} (then let it
     * surface as usual), so a tester can just send that file. Same data dir as
     * the run log and achievements.
     */
    private static void installCrashLog() {
        CrashLog crashLog = new CrashLog(
                Path.of(System.getProperty("user.home"), ".scoundrel", "crash.log"));
        Thread.setDefaultUncaughtExceptionHandler(
                crashLog.asHandler(Thread.getDefaultUncaughtExceptionHandler()));
    }

    private static Lwjgl3Application createApplication() {
        return new Lwjgl3Application(new ScoundrelGame(), getDefaultConfiguration());
    }

    private static Lwjgl3ApplicationConfiguration getDefaultConfiguration() {
        Lwjgl3ApplicationConfiguration configuration = new Lwjgl3ApplicationConfiguration();
        configuration.setTitle("Scoundrel");
        //// Vsync limits the frames per second to what your hardware can display, and helps eliminate
        //// screen tearing. This setting doesn't always work on Linux, so the line after is a safeguard.
        configuration.useVsync(true);
        //// Limits FPS to the refresh rate of the currently active monitor, plus 1 to try to match fractional
        //// refresh rates. The Vsync setting above should limit the actual FPS to match the monitor.
        configuration.setForegroundFPS(Lwjgl3ApplicationConfiguration.getDisplayMode().refreshRate + 1);
        //// If you remove the above line and set Vsync to false, you can get unlimited FPS, which can be
        //// useful for testing performance, but can also be very stressful to some hardware.
        //// You may also need to configure GPU drivers to fully disable Vsync; this can cause screen tearing.

        // Launch borderless-fullscreen at the monitor's native resolution; F11 /
        // Alt+Enter toggles windowed (see ScoundrelGame, whose flag must agree with
        // this). PixelViewport snaps the 1280x720 design down to a half-step scale
        // and letterboxes the remainder, so every source pixel still lands on a
        // whole number of screen pixels whatever the monitor is.
        //
        // Verification is the one thing this costs: the driver's coordinates are
        // client pixels in a 1280x720 window, so drive the game to windowed with
        // F11 first (see .claude/skills/run-scoundrel/SKILL.md).
        Graphics.DisplayMode desktop = Lwjgl3ApplicationConfiguration.getDisplayMode();
        configuration.setDecorated(false);
        configuration.setWindowedMode(desktop.width, desktop.height);
        //// You can change these files; they are in lwjgl3/src/main/resources/ .
        //// They can also be loaded from the root of assets/ .
        configuration.setWindowIcon("libgdx128.png", "libgdx64.png", "libgdx48.png", "libgdx32.png", "libgdx16.png");

        // A machine with no audio device, on demand: SCOUNDREL_NO_AUDIO=1 (or
        // -Dscoundrel.no.audio=true) hands the game LibGDX's silent stand-in, which
        // is what the backend falls back to when it finds no device. The game must
        // run on it unchanged.
        configuration.disableAudio(LaunchSwitch.NO_AUDIO.isOn());

        //// This could improve compatibility with Windows machines with buggy OpenGL drivers, Macs
        //// with Apple Silicon that have to emulate compatibility with OpenGL anyway, and more.
        //// This uses the dependency `com.badlogicgames.gdx:gdx-lwjgl3-angle` to function.
        //// You would need to add this line to lwjgl3/build.gradle , below the dependency on `gdx-backend-lwjgl3`:
        ////     implementation "com.badlogicgames.gdx:gdx-lwjgl3-angle:$gdxVersion"
        //// You can choose to add the following line and the mentioned dependency if you want; they
        //// are not intended for games that use GL30 (which is compatibility with OpenGL ES 3.0).
        //// Know that it might not work well in some cases.
//        configuration.setOpenGLEmulation(Lwjgl3ApplicationConfiguration.GLEmulation.ANGLE_GLES20, 0, 0);

        return configuration;
    }
}
