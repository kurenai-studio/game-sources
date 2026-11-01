package com.tomer.scoundrel.achievements;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Append-only local latch of earned achievements, one
 * {@link UnlockedAchievement} line each — the sibling of
 * {@link com.tomer.scoundrel.runs.RunLog}. Append never rewrites existing data;
 * reading tolerates a missing file, skips lines that don't parse, and dedupes a
 * repeated id to its earliest earn (append order is chronological). The path is
 * injected so tests use a temp directory and the app decides the real location.
 */
public final class AchievementStore {

    private final Path file;

    /**
     * A store backed by one file, which need not exist yet.
     *
     * @param file where the latch lives; the game uses {@code ~/.scoundrel/achievements.log}
     */
    public AchievementStore(Path file) {
        this.file = file;
    }

    /**
     * Latches one achievement as a new line at the end, creating the file and its
     * directory on the first unlock. Appending an id that is already there is harmless:
     * reading keeps the earliest.
     *
     * @param unlocked the achievement and when it was earned
     * @throws UncheckedIOException if the directory or the line cannot be written
     */
    public void append(UnlockedAchievement unlocked) {
        try {
            if (file.getParent() != null) {
                Files.createDirectories(file.getParent());
            }
            Files.writeString(file, unlocked.toLine() + System.lineSeparator(),
                    StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            throw new UncheckedIOException("could not append achievement to " + file, e);
        }
    }

    /**
     * Erases the latch by moving the file aside to a {@code .bak} sibling
     * (overwriting any earlier backup), so an accidental reset stays
     * recoverable from disk; the game never restores it automatically. A no-op
     * when nothing has been unlocked yet.
     *
     * @throws UncheckedIOException if the file cannot be moved
     */
    public void clear() {
        try {
            if (Files.exists(file)) {
                Path backup = file.resolveSibling(file.getFileName().toString() + ".bak");
                Files.move(file, backup, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            throw new UncheckedIOException("could not clear " + file, e);
        }
    }

    /**
     * Every earned achievement, deduped by id, keeping the first line written for
     * each (its earliest earn, since unlocks are appended as they are won); empty
     * when none exist.
     *
     * @return an unmodifiable list in the order first written; unparseable lines are skipped
     * @throws UncheckedIOException if the file exists but cannot be read
     */
    public List<UnlockedAchievement> readAll() {
        if (!Files.exists(file)) {
            return List.of();
        }
        try {
            Map<String, UnlockedAchievement> byId = new LinkedHashMap<>();
            for (String line : Files.readAllLines(file, StandardCharsets.UTF_8)) {
                if (!line.isBlank()) {
                    UnlockedAchievement.parse(line)
                            .ifPresent(unlocked -> byId.putIfAbsent(unlocked.id(), unlocked));
                }
            }
            return List.copyOf(byId.values());
        } catch (IOException e) {
            throw new UncheckedIOException("could not read achievements from " + file, e);
        }
    }

    /**
     * The set of earned achievement ids — what {@link AchievementService} filters against.
     *
     * @return an unmodifiable set, read from the file on every call
     * @throws UncheckedIOException if the file exists but cannot be read
     */
    public Set<String> unlockedIds() {
        return readAll().stream().map(UnlockedAchievement::id)
                .collect(java.util.stream.Collectors.toUnmodifiableSet());
    }
}
