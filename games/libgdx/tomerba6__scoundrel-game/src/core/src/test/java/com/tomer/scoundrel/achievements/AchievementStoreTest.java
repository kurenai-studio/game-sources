package com.tomer.scoundrel.achievements;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The unlocked-achievements file: appending, reading back deduped and
 * tolerant, and clearing to a backup.
 */
class AchievementStoreTest {

    /** A fresh directory for each test, deleted afterwards. */
    @TempDir
    Path dir;

    private static UnlockedAchievement unlock(String id, String earnedAt) {
        return new UnlockedAchievement(id, Instant.parse(earnedAt));
    }

    /** Appending to a store in a missing directory creates the directories and the file. */
    @Test
    void appendCreatesMissingDirectoriesAndFile() {
        Path file = dir.resolve("nested").resolve("achievements.log");
        AchievementStore store = new AchievementStore(file);
        UnlockedAchievement earned = unlock("first_blood", "2026-07-10T10:00:00Z");
        store.append(earned);
        assertTrue(Files.exists(file));
        assertEquals(List.of(earned), store.readAll());
    }

    /** Unlocks read back in the order they were written, and their ids make the unlocked set. */
    @Test
    void appendsAccumulateInOrder() {
        AchievementStore store = new AchievementStore(dir.resolve("achievements.log"));
        UnlockedAchievement first = unlock("first_blood", "2026-07-10T10:00:00Z");
        UnlockedAchievement second = unlock("giant_slayer", "2026-07-10T10:05:00Z");
        store.append(first);
        store.append(second);
        assertEquals(List.of(first, second), store.readAll());
        assertEquals(Set.of("first_blood", "giant_slayer"), store.unlockedIds());
    }

    /** A store that was never written reads as empty, with nothing unlocked. */
    @Test
    void readingWithoutAFileIsEmpty() {
        AchievementStore store = new AchievementStore(dir.resolve("never-written.log"));
        assertEquals(List.of(), store.readAll());
        assertEquals(Set.of(), store.unlockedIds());
    }

    /** An id written twice reads back once, keeping the first earn written. */
    @Test
    void aRepeatedIdIsDedupedKeepingTheEarliestEarn() {
        AchievementStore store = new AchievementStore(dir.resolve("achievements.log"));
        UnlockedAchievement earliest = unlock("seasoned", "2026-07-10T10:00:00Z");
        store.append(earliest);
        store.append(unlock("seasoned", "2026-07-11T10:00:00Z"));
        assertEquals(List.of(earliest), store.readAll());
        assertEquals(Set.of("seasoned"), store.unlockedIds());
    }

    /** Garbage and unknown-version lines are skipped, and the good unlocks around them still read. */
    @Test
    void corruptLinesAreSkippedNotFatal() throws Exception {
        Path file = dir.resolve("achievements.log");
        UnlockedAchievement good = unlock("first_blood", "2026-07-10T10:00:00Z");
        UnlockedAchievement alsoGood = unlock("speedrunner", "2026-07-10T10:01:00Z");
        Files.writeString(file, good.toLine() + "\n### corrupted ###\nv=9\tfuture=stuff\n"
                + alsoGood.toLine() + "\n");
        assertEquals(List.of(good, alsoGood), new AchievementStore(file).readAll());
    }

    /** Appending where the directory cannot be created throws UncheckedIOException. */
    @Test
    void unwritableLocationThrowsUncheckedIOExceptionForTheCallerToHandle() throws Exception {
        Path blocker = dir.resolve("blocker");
        Files.createFile(blocker);
        AchievementStore store = new AchievementStore(blocker.resolve("achievements.log"));
        assertThrows(UncheckedIOException.class,
                () -> store.append(unlock("first_blood", "2026-07-10T10:00:00Z")));
    }

    /** Reading a path that cannot be read, here a directory, throws UncheckedIOException. */
    @Test
    void readingAnUnreadablePathThrowsUncheckedIOException() throws Exception {
        // The store path is actually a directory, so readAllLines cannot read it.
        Path asDir = dir.resolve("achievements.log");
        Files.createDirectory(asDir);
        assertThrows(UncheckedIOException.class, () -> new AchievementStore(asDir).readAll());
    }

    /** Clearing empties the store and keeps its unlocks in {@code achievements.log.bak}. */
    @Test
    void clearMovesTheLogAsideToARecoverableBackupAndEmptiesIt() {
        Path file = dir.resolve("achievements.log");
        AchievementStore store = new AchievementStore(file);
        UnlockedAchievement earned = unlock("first_blood", "2026-07-10T10:00:00Z");
        store.append(earned);
        store.clear();
        assertEquals(List.of(), store.readAll());
        assertEquals(Set.of(), store.unlockedIds());
        Path backup = dir.resolve("achievements.log.bak");
        assertTrue(Files.exists(backup), "a backup must be kept");
        assertEquals(List.of(earned), new AchievementStore(backup).readAll());
    }

    /** Clearing a store that does not exist does nothing. */
    @Test
    void clearWithoutAFileIsANoOp() {
        AchievementStore store = new AchievementStore(dir.resolve("achievements.log"));
        store.clear();
        assertEquals(List.of(), store.readAll());
    }

    /** A second clear replaces the previous backup. */
    @Test
    void clearOverwritesAnyPriorBackup() {
        AchievementStore store = new AchievementStore(dir.resolve("achievements.log"));
        store.append(unlock("first_blood", "2026-07-10T10:00:00Z"));
        store.clear();
        UnlockedAchievement later = unlock("speedrunner", "2026-07-11T10:00:00Z");
        store.append(later);
        store.clear();
        assertEquals(List.of(later),
                new AchievementStore(dir.resolve("achievements.log.bak")).readAll());
    }
}
