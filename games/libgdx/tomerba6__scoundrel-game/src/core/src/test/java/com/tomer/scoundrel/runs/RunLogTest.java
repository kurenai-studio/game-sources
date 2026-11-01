package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The run log file: appending, reading back tolerantly, and clearing to a backup. */
class RunLogTest {

    /** A fresh directory for each test, deleted afterwards. */
    @TempDir
    Path dir;

    private static RunRecord run(int score, String endedAt) {
        return new RunRecord(42L, "standard", score >= 0 ? Status.WON : Status.LOST,
                score, Instant.parse(endedAt), 60, 1, 2, 3, 4, 5, 6, 7);
    }

    /** Appending to a log in a missing directory creates the directories and the file. */
    @Test
    void appendCreatesMissingDirectoriesAndFile() {
        Path file = dir.resolve("nested").resolve("deeper").resolve("runs.log");
        RunLog log = new RunLog(file);
        RunRecord record = run(20, "2026-07-06T10:00:00Z");
        log.append(record);
        assertTrue(Files.exists(file));
        assertEquals(List.of(record), log.readAll());
    }

    /** Appended records read back in the order they were written. */
    @Test
    void appendsAccumulateInOrder() {
        RunLog log = new RunLog(dir.resolve("runs.log"));
        RunRecord first = run(5, "2026-07-06T10:00:00Z");
        RunRecord second = run(-12, "2026-07-06T11:00:00Z");
        RunRecord third = run(23, "2026-07-06T12:00:00Z");
        log.append(first);
        log.append(second);
        log.append(third);
        assertEquals(List.of(first, second, third), log.readAll());
    }

    /** A log that was never written reads as empty. */
    @Test
    void readingWithoutAFileIsEmpty() {
        assertEquals(List.of(), new RunLog(dir.resolve("never-written.log")).readAll());
    }

    /** Garbage and unknown-version lines are skipped, and the good records around them still read. */
    @Test
    void corruptLinesAreSkippedNotFatal() throws Exception {
        Path file = dir.resolve("runs.log");
        RunRecord good = run(20, "2026-07-06T10:00:00Z");
        RunRecord alsoGood = run(7, "2026-07-06T11:00:00Z");
        Files.writeString(file, good.toLine() + "\n### corrupted ###\nv=9\tfuture=stuff\n"
                + alsoGood.toLine() + "\n");
        assertEquals(List.of(good, alsoGood), new RunLog(file).readAll());
    }

    /** Appending where the directory cannot be created throws UncheckedIOException. */
    @Test
    void unwritableLocationThrowsUncheckedIOExceptionForTheCallerToHandle() throws Exception {
        // The log's parent "directory" is actually a file, so createDirectories fails.
        Path blocker = dir.resolve("blocker");
        Files.createFile(blocker);
        RunLog log = new RunLog(blocker.resolve("runs.log"));
        assertThrows(UncheckedIOException.class, () -> log.append(run(20, "2026-07-06T10:00:00Z")));
    }

    /** Blank and whitespace-only lines are skipped. */
    @Test
    void blankAndWhitespaceOnlyLinesAreSkipped() throws Exception {
        Path file = dir.resolve("runs.log");
        RunRecord a = run(5, "2026-07-06T10:00:00Z");
        RunRecord b = run(9, "2026-07-06T11:00:00Z");
        Files.writeString(file, a.toLine() + "\n\n   \n\t\n" + b.toLine() + "\n");
        assertEquals(List.of(a, b), new RunLog(file).readAll());
    }

    /** Reading a path that cannot be read, here a directory, throws UncheckedIOException. */
    @Test
    void readingAnUnreadablePathThrowsUncheckedIOException() throws Exception {
        // The "log" path is actually a directory, so readAllLines cannot read it.
        Path asDir = dir.resolve("runs.log");
        Files.createDirectory(asDir);
        assertThrows(UncheckedIOException.class, () -> new RunLog(asDir).readAll());
    }

    /** A log with both Unix and Windows line endings reads every record. */
    @Test
    void mixedLineEndingsFromAnotherOsReadFine() throws Exception {
        Path file = dir.resolve("runs.log");
        RunRecord unixWritten = run(5, "2026-07-06T10:00:00Z");
        RunRecord windowsWritten = run(9, "2026-07-06T11:00:00Z");
        Files.writeString(file, unixWritten.toLine() + "\n" + windowsWritten.toLine() + "\r\n");
        assertEquals(List.of(unixWritten, windowsWritten), new RunLog(file).readAll());
    }

    /** Clearing empties the log and keeps its records in {@code runs.log.bak}. */
    @Test
    void clearMovesTheLogAsideToARecoverableBackupAndEmptiesIt() {
        Path file = dir.resolve("runs.log");
        RunLog log = new RunLog(file);
        RunRecord record = run(20, "2026-07-06T10:00:00Z");
        log.append(record);
        log.clear();
        assertEquals(List.of(), log.readAll());
        Path backup = dir.resolve("runs.log.bak");
        assertTrue(Files.exists(backup), "a backup must be kept");
        assertEquals(List.of(record), new RunLog(backup).readAll());
    }

    /** Clearing a log that does not exist does nothing. */
    @Test
    void clearWithoutAFileIsANoOp() {
        RunLog log = new RunLog(dir.resolve("runs.log"));
        log.clear();
        assertEquals(List.of(), log.readAll());
    }

    /** A second clear replaces the previous backup. */
    @Test
    void clearOverwritesAnyPriorBackup() {
        RunLog log = new RunLog(dir.resolve("runs.log"));
        log.append(run(5, "2026-07-06T10:00:00Z"));
        log.clear();
        RunRecord later = run(9, "2026-07-07T10:00:00Z");
        log.append(later);
        log.clear();
        assertEquals(List.of(later), new RunLog(dir.resolve("runs.log.bak")).readAll());
    }
}
