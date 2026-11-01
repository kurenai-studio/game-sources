package com.tomer.scoundrel;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;

/**
 * Appends uncaught crashes to a local file under {@code ~/.scoundrel/} so a
 * tester can simply send it. A sibling of {@link com.tomer.scoundrel.runs.RunLog},
 * but deliberately robust: a crash reporter must never itself throw, so a failure
 * to write is swallowed and the crash still surfaces through the normal handler.
 * The path and clock are injected so the formatting, appending, and handler glue
 * are all unit tested; only installing it globally is left to the launcher.
 */
public final class CrashLog {

    private final Path file;

    /**
     * A log backed by one file, which need not exist yet.
     *
     * @param file where crashes are appended; the launcher uses {@code ~/.scoundrel/crash.log}
     */
    public CrashLog(Path file) {
        this.file = file;
    }

    /**
     * Appends one timestamped crash entry. Never throws — a failed write is given up on quietly.
     *
     * @param throwable the crash, with its cause chain
     * @param when      the moment to stamp the entry with
     */
    public void record(Throwable throwable, Instant when) {
        try {
            if (file.getParent() != null) {
                Files.createDirectories(file.getParent());
            }
            Files.writeString(file, format(throwable, when), StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (Exception ignored) {
            // A crash reporter that crashes is worse than useless — give up quietly.
        }
    }

    /**
     * A readable entry: a timestamped header and the full stack trace, cause chain included.
     *
     * @param throwable the crash
     * @param when      the moment for the header, printed as an ISO-8601 instant
     * @return the entry, ending in a line separator so entries stack cleanly
     * @see Throwable#printStackTrace(java.io.PrintWriter)
     */
    public static String format(Throwable throwable, Instant when) {
        StringWriter stack = new StringWriter();
        throwable.printStackTrace(new PrintWriter(stack));
        return "===== crash at " + when + " ====="
                + System.lineSeparator() + stack + System.lineSeparator();
    }

    /**
     * An uncaught-exception handler that records the crash then passes it on to
     * {@code chainTo} (the previous default handler), so recording is added
     * without swallowing the crash. The launcher installs the returned handler.
     *
     * @param chainTo the handler to pass the crash on to, or null to print its stack trace
     * @return a handler that records the crash, stamped with the current time, then chains
     * @see Thread#setDefaultUncaughtExceptionHandler(Thread.UncaughtExceptionHandler)
     */
    public Thread.UncaughtExceptionHandler asHandler(Thread.UncaughtExceptionHandler chainTo) {
        return (thread, throwable) -> {
            record(throwable, Instant.now());
            if (chainTo != null) {
                chainTo.uncaughtException(thread, throwable);
            } else {
                throwable.printStackTrace();
            }
        };
    }
}
