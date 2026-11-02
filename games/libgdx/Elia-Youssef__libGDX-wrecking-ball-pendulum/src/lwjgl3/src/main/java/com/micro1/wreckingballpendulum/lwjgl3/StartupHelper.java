/*
 * Copyright 2020 damios (MIT-licensed helper shipped with libGDX project templates).
 * Restarts the JVM with -XstartOnFirstThread on macOS so LWJGL3/GLFW can open a window there.
 * On Windows and Linux startNewJvmIfRequired() is a no-op and returns false.
 */
package com.micro1.wreckingballpendulum.lwjgl3;

import org.lwjgl.system.macosx.LibC;
import org.lwjgl.system.macosx.ObjCRuntime;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.lang.management.ManagementFactory;
import java.util.ArrayList;

import static org.lwjgl.system.JNI.invokePPP;
import static org.lwjgl.system.macosx.ObjCRuntime.objc_getClass;
import static org.lwjgl.system.macosx.ObjCRuntime.sel_getUid;

/** Adds some utilities to ensure that the JVM was started with the {@code -XstartOnFirstThread} argument on macOS. */
public final class StartupHelper {

    private static final String JVM_RESTARTED_ARG = "jvmIsRestarted";

    private StartupHelper() {
        throw new UnsupportedOperationException();
    }

    /**
     * Starts a new JVM if the application was started on macOS without the {@code -XstartOnFirstThread}
     * argument. Returns whether a new JVM was started and thus no code should be executed.
     */
    public static boolean startNewJvmIfRequired(boolean redirectOutput) {
        String osName = System.getProperty("os.name").toLowerCase();
        if (!osName.contains("mac")) {
            if (osName.contains("windows")) {
                // Workaround for the libGDX console appearing on Windows when launched from some IDEs.
                System.setProperty("org.lwjgl.util.NoErrorContext", "true");
            }
            return false;
        }

        long objc_msgSend = ObjCRuntime.getLibrary().getFunctionAddress("objc_msgSend");
        long NSThread = objc_getClass("NSThread");
        long currentThread = invokePPP(NSThread, sel_getUid("currentThread"), objc_msgSend);
        boolean isMainThread = invokePPP(currentThread, sel_getUid("isMainThread"), objc_msgSend) != 0;
        if (isMainThread) {
            return false;
        }

        long pid = LibC.getpid();
        if ("true".equals(System.getProperty(JVM_RESTARTED_ARG))) {
            System.err.println(
                "There was a problem evaluating whether the JVM was started with the -XstartOnFirstThread argument.");
            return false;
        }

        ArrayList<String> jvmArgs = new ArrayList<>();
        String separator = System.getProperty("file.separator", "/");
        String javaExecPath = System.getProperty("java.home") + separator + "bin" + separator + "java";
        if (!(new File(javaExecPath)).exists()) {
            System.err.println(
                "A Java installation could not be found. If you are distributing this app with a bundled JRE, "
                    + "be sure to set the -XstartOnFirstThread argument manually!");
            return false;
        }

        jvmArgs.add(javaExecPath);
        jvmArgs.add("-XstartOnFirstThread");
        jvmArgs.add("-D" + JVM_RESTARTED_ARG + "=true");
        jvmArgs.addAll(ManagementFactory.getRuntimeMXBean().getInputArguments());
        jvmArgs.add("-cp");
        jvmArgs.add(System.getProperty("java.class.path"));
        String mainClass = System.getenv("JAVA_MAIN_CLASS_" + pid);
        if (mainClass == null) {
            StackTraceElement[] trace = Thread.currentThread().getStackTrace();
            if (trace.length > 0) {
                mainClass = trace[trace.length - 1].getClassName();
            } else {
                System.err.println("The main class could not be determined.");
                return false;
            }
        }
        jvmArgs.add(mainClass);

        try {
            if (!redirectOutput) {
                ProcessBuilder processBuilder = new ProcessBuilder(jvmArgs);
                processBuilder.start();
            } else {
                Process process = new ProcessBuilder(jvmArgs)
                    .redirectErrorStream(true).start();
                BufferedReader processOutput = new BufferedReader(new InputStreamReader(process.getInputStream()));
                String line;
                while ((line = processOutput.readLine()) != null) {
                    System.out.println(line);
                }
                process.waitFor();
            }
        } catch (Exception e) {
            System.err.println("There was a problem restarting the JVM");
            e.printStackTrace();
        }
        return true;
    }

    /** Starts a new JVM if required; redirects the child output to this process. */
    public static boolean startNewJvmIfRequired() {
        return startNewJvmIfRequired(true);
    }
}
