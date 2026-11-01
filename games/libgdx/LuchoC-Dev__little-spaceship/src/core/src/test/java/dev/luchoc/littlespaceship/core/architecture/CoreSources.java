package dev.luchoc.littlespaceship.core.architecture;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

/**
 * The main sources of the core, read as text.
 *
 * <p>The architecture rules of this project are mechanical: no libGDX, no clock, no randomness that
 * is not seeded, no dependency pointing outwards. Checking them by reading the sources is blunt and
 * it works, and it catches the case that matters most, which is the line added in good faith that
 * breaks an invariant without breaking a single test.
 */
final class CoreSources {

    private CoreSources() {
    }

    /**
     * Reads every main source file of the core.
     *
     * @return one entry per file, with its path and its content
     */
    static List<SourceFile> all() {
        Path root = mainSourceRoot();
        List<SourceFile> files = new ArrayList<>();
        try (Stream<Path> paths = Files.walk(root)) {
            for (Path path : paths.filter(Files::isRegularFile).toList()) {
                if (!path.toString().endsWith(".java")) {
                    continue;
                }
                String content = Files.readString(path, StandardCharsets.UTF_8);
                String relative = root.relativize(path).toString()
                    .replace(java.io.File.separatorChar, '/');
                files.add(new SourceFile(relative, content));
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        if (files.isEmpty()) {
            throw new IllegalStateException("no source found under " + root.toAbsolutePath());
        }
        return files;
    }

    /**
     * Locates the source root whether the tests run from the module directory or from the
     * repository root, which is the difference between Gradle and some IDE run configurations.
     */
    private static Path mainSourceRoot() {
        Path fromModule = Path.of("src", "main", "java");
        if (Files.isDirectory(fromModule)) {
            return fromModule;
        }
        Path fromRepository = Path.of("core", "src", "main", "java");
        if (Files.isDirectory(fromRepository)) {
            return fromRepository;
        }
        throw new IllegalStateException(
            "the sources of core were not found from " + Path.of("").toAbsolutePath());
    }

    /**
     * One source file: where it lives and what it says.
     *
     * @param path path relative to the source root, with forward slashes
     * @param content the whole file
     */
    record SourceFile(String path, String content) {

        /**
         * @return the package this file declares
         */
        String packageName() {
            int slash = path.lastIndexOf('/');
            return slash < 0 ? "" : path.substring(0, slash).replace('/', '.');
        }

        /**
         * @return every type imported by this file
         */
        List<String> imports() {
            List<String> imports = new ArrayList<>();
            for (String line : content.split("\n")) {
                String trimmed = line.trim();
                if (!trimmed.startsWith("import ")) {
                    continue;
                }
                String imported = trimmed.substring("import ".length()).replace(";", "").trim();
                if (imported.startsWith("static ")) {
                    imported = imported.substring("static ".length()).trim();
                }
                imports.add(imported);
            }
            return imports;
        }
    }
}
