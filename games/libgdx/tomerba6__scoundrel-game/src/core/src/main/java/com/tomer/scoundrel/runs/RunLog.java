package com.tomer.scoundrel.runs;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;

/**
 * Append-only local history of finished runs, one {@link RunRecord} line
 * each. Append never rewrites existing data (a crash can at worst lose the
 * line in flight); reading tolerates a missing file and skips lines that
 * don't parse. The path is injected so tests use a temp directory and the
 * app decides the real location.
 */
public final class RunLog {

    private final Path file;

    /**
     * A log backed by one file, which need not exist yet.
     *
     * @param file where the history lives; the game uses {@code ~/.scoundrel/runs.log}
     */
    public RunLog(Path file) {
        this.file = file;
    }

    /**
     * Adds one finished run as a new line at the end, creating the file and its
     * directory on the first run.
     *
     * @param record the run to keep
     * @throws UncheckedIOException if the directory or the line cannot be written
     */
    public void append(RunRecord record) {
        try {
            if (file.getParent() != null) {
                Files.createDirectories(file.getParent());
            }
            Files.writeString(file, record.toLine() + System.lineSeparator(),
                    StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            throw new UncheckedIOException("could not append run to " + file, e);
        }
    }

    /**
     * Erases the history by moving the file aside to a {@code .bak} sibling
     * (overwriting any earlier backup), so an accidental reset stays
     * recoverable from disk; the game never restores it automatically. A no-op
     * when nothing has been written yet.
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
     * All parseable runs in file order; empty when no history exists yet.
     *
     * @return an unmodifiable list, oldest first; blank and unparseable lines are skipped
     * @throws UncheckedIOException if the file exists but cannot be read
     */
    public List<RunRecord> readAll() {
        if (!Files.exists(file)) {
            return List.of();
        }
        try {
            List<RunRecord> records = new ArrayList<>();
            for (String line : Files.readAllLines(file, StandardCharsets.UTF_8)) {
                if (!line.isBlank()) {
                    RunRecord.parse(line).ifPresent(records::add);
                }
            }
            return List.copyOf(records);
        } catch (IOException e) {
            throw new UncheckedIOException("could not read runs from " + file, e);
        }
    }
}
