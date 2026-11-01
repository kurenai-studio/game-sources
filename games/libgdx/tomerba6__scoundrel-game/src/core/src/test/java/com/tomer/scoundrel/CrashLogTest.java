package com.tomer.scoundrel;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The crash log: each entry's format, appending to the file, and the
 * uncaught-exception handler, none of which may throw.
 */
class CrashLogTest {

    private static final Instant WHEN = Instant.parse("2026-07-27T10:15:30Z");

    /** A fresh directory for each test, deleted afterwards. */
    @TempDir
    Path dir;

    /** An entry holds the timestamp, the exception's type and message, and its stack frames. */
    @Test
    void formatCarriesTheTimestampMessageAndStackTrace() {
        String text = CrashLog.format(new IllegalStateException("boom while dealing"), WHEN);
        assertTrue(text.contains("2026-07-27T10:15:30Z"), "has the timestamp");
        assertTrue(text.contains("IllegalStateException"), "has the exception type");
        assertTrue(text.contains("boom while dealing"), "has the message");
        assertTrue(text.contains("at com.tomer.scoundrel.CrashLogTest"), "has a stack frame");
    }

    /** An entry unrolls the cause chain, with each cause's message. */
    @Test
    void formatIncludesTheCauseChain() {
        Throwable wrapped = new RuntimeException("render failed",
                new NullPointerException("no room tile"));
        String text = CrashLog.format(wrapped, WHEN);
        assertTrue(text.contains("render failed"));
        assertTrue(text.contains("Caused by"), "the cause chain is unrolled");
        assertTrue(text.contains("no room tile"));
    }

    /** Recording creates the file and any missing directories, and each crash adds its own entry. */
    @Test
    void recordCreatesTheFileAndAppendsEachCrash() throws Exception {
        Path file = dir.resolve("nested").resolve("crash.log");
        CrashLog log = new CrashLog(file);
        log.record(new IllegalStateException("first"), WHEN);
        log.record(new IllegalArgumentException("second"), WHEN.plusSeconds(60));
        assertTrue(Files.exists(file));
        String contents = Files.readString(file);
        assertTrue(contents.contains("first") && contents.contains("second"));
        // Two entries, two headers.
        assertEquals(2, contents.split("===== crash at ", -1).length - 1);
    }

    /** Recording where the file cannot be written, here a directory, does not throw. */
    @Test
    void recordNeverThrowsEvenWhenItCannotWrite() throws Exception {
        // The "file" is a directory, so writing must fail — but record swallows it.
        Path asDir = dir.resolve("crash.log");
        Files.createDirectory(asDir);
        new CrashLog(asDir).record(new RuntimeException("boom"), WHEN); // must not throw
    }

    /** The handler records the crash, then passes it on to the previous handler. */
    @Test
    void asHandlerRecordsTheCrashThenPassesItOn() throws Exception {
        Path file = dir.resolve("crash.log");
        AtomicBoolean chained = new AtomicBoolean(false);
        Thread.UncaughtExceptionHandler handler = new CrashLog(file)
                .asHandler((thread, throwable) -> chained.set(true));

        handler.uncaughtException(Thread.currentThread(), new RuntimeException("kaboom"));

        assertTrue(Files.exists(file), "the crash was recorded");
        assertTrue(Files.readString(file).contains("kaboom"));
        assertTrue(chained.get(), "the previous handler still ran");
    }

    /** With no previous handler, the handler still records the crash. */
    @Test
    void asHandlerWithoutAPreviousHandlerStillRecords() throws Exception {
        Path file = dir.resolve("crash.log");
        new CrashLog(file).asHandler(null)
                .uncaughtException(Thread.currentThread(), new RuntimeException("solo"));
        assertTrue(Files.readString(file).contains("solo"));
        assertFalse(Files.exists(dir.resolve("nope")));
    }
}
