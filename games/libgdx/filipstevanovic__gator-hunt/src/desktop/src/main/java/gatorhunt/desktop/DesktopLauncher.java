package gatorhunt.desktop;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;

import gatorhunt.GatorHuntGame;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class DesktopLauncher {

    /** Marks a JVM as already relaunched with -XstartOnFirstThread, so it never relaunches itself again. */
    private static final String RELAUNCHED_MARKER = "gatorhunt.relaunched";

    public static void main(String[] args) {
        if (relaunchedWithStartOnFirstThread()) {
            return;
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Gator Hunt");
        config.setFullscreenMode(Lwjgl3ApplicationConfiguration.getDisplayMode());
        config.useVsync(true);
        config.setForegroundFPS(70);

        new Lwjgl3Application(new GatorHuntGame(), config);
    }

    /**
     * LWJGL/GLFW requires macOS to run its event loop on the process's very
     * first thread, via the -XstartOnFirstThread JVM flag. That flag can
     * only be set at JVM startup, so whether it's already set depends
     * entirely on how this was launched: Gradle's desktop:run task adds it
     * (see desktop/build.gradle -- and also passes RELAUNCHED_MARKER, so
     * that path never relaunches), but an IDE's "run main()" action or a
     * plain "java -jar" doesn't.
     *
     * This used to check ManagementFactory.getRuntimeMXBean().getInputArguments()
     * for the flag before relaunching -- but that never actually saw it (the
     * native launcher consumes -XstartOnFirstThread before the JVM records
     * its own input arguments), so the check always failed and every launch
     * relaunched into a child that relaunched again, forever: caught in
     * testing as 868 stacked java processes and a window that never opened.
     * Rather than depend on detecting a flag that turns out not to be
     * detectable, this sets its own marker system property on the child it
     * spawns, and only ever relaunches when that marker is absent -- which
     * is true at most once, on the original process.
     *
     * @return true if this process relaunched and the caller should just return.
     */
    private static boolean relaunchedWithStartOnFirstThread() {
        if (!System.getProperty("os.name", "").toLowerCase().contains("mac")) {
            return false;
        }
        if (System.getProperty(RELAUNCHED_MARKER) != null) {
            return false;
        }

        String javaBin = System.getProperty("java.home") + File.separator + "bin" + File.separator + "java";
        List<String> command = new ArrayList<>();
        command.add(javaBin);
        command.add("-XstartOnFirstThread");
        command.add("-D" + RELAUNCHED_MARKER + "=true");
        command.add("-cp");
        command.add(System.getProperty("java.class.path"));
        command.add(DesktopLauncher.class.getName());

        try {
            Process process = new ProcessBuilder(command).inheritIO().start();
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                System.err.println("Relaunched process exited with code " + exitCode);
            }
        } catch (Exception e) {
            throw new IllegalStateException("Failed to relaunch with -XstartOnFirstThread", e);
        }
        return true;
    }
}
