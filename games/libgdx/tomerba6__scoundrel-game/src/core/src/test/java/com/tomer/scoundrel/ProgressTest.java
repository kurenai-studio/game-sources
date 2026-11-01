package com.tomer.scoundrel;

import com.tomer.scoundrel.achievements.AchievementStore;
import com.tomer.scoundrel.achievements.UnlockedAchievement;
import com.tomer.scoundrel.audio.AudioSettings;
import com.tomer.scoundrel.audio.AudioSettingsStore;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.runs.RunRecord;
import com.tomer.scoundrel.tutorial.TutorialFlag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

/** Erasing all progress: every store cleared together and recoverable, and the audio settings left alone. */
class ProgressTest {

    /** A fresh directory for each test, deleted afterwards. */
    @TempDir
    Path dir;

    private RunLog runLog() {
        return new RunLog(dir.resolve("runs.log"));
    }

    private AchievementStore achievements() {
        return new AchievementStore(dir.resolve("achievements.log"));
    }

    private TutorialFlag tutorial() {
        return new TutorialFlag(dir.resolve("tutorial.seen"));
    }

    /**
     * Erasing empties the runs, the achievements and the tutorial flag, and the
     * runs and achievements read back from their {@code .bak} files.
     */
    @Test
    void eraseAllWipesEveryStoreAndLeavesEachRecoverable() {
        RunLog runLog = runLog();
        AchievementStore achievements = achievements();
        TutorialFlag tutorial = tutorial();
        RunRecord record = new RunRecord(1L, "standard", Status.WON, 20,
                Instant.parse("2026-07-06T10:00:00Z"), 60, 5, 4, 3, 2, 1, 1, 0);
        UnlockedAchievement unlocked = new UnlockedAchievement("first_blood",
                Instant.parse("2026-07-06T10:00:00Z"));
        runLog.append(record);
        achievements.append(unlocked);
        tutorial.markSeen();

        Progress.eraseAll(runLog, achievements, tutorial);

        // Every store is emptied together...
        assertEquals(List.of(), runLog.readAll());
        assertEquals(Set.of(), achievements.unlockedIds());
        assertFalse(tutorial.isSeen(), "a full reset makes the player new again");
        // ...and each remains recoverable from its .bak sibling.
        assertEquals(List.of(record), new RunLog(dir.resolve("runs.log.bak")).readAll());
        assertEquals(List.of(unlocked),
                new AchievementStore(dir.resolve("achievements.log.bak")).readAll());
    }

    /** Erasing when nothing has been saved leaves every store empty and throws nothing. */
    @Test
    void eraseAllOnEmptyStoresIsANoOp() {
        RunLog runLog = runLog();
        AchievementStore achievements = achievements();
        TutorialFlag tutorial = tutorial();
        Progress.eraseAll(runLog, achievements, tutorial);
        assertEquals(List.of(), runLog.readAll());
        assertEquals(Set.of(), achievements.unlockedIds());
        assertFalse(tutorial.isSeen());
    }

    /** Erasing progress leaves the audio settings as they were, with no backup made of them. */
    @Test
    void eraseAllLeavesTheAudioSettingsAlone() {
        // Volume is a setting, not progress: a player who resets their record
        // has not asked for the music to come back on.
        AudioSettingsStore audio = new AudioSettingsStore(dir.resolve("audio.settings"));
        AudioSettings chosen = new AudioSettings(0, 1, true);
        audio.save(chosen);

        Progress.eraseAll(runLog(), achievements(), tutorial());

        assertEquals(chosen, audio.load());
        assertFalse(Files.exists(dir.resolve("audio.settings.bak")), "nothing was moved aside");
    }
}
