package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.utils.JsonReader;
import com.badlogic.gdx.utils.JsonValue;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The named scenarios {@link TestMenuScreen} lists, discovered from {@code assets/data/test-*.json}
 * rather than hand-maintained here — issue #311. The list went from nine entries to fourteen across
 * phases 11h to 11j, each time by editing this file by hand alongside the content; #301 needed a
 * whole second pull request in this module to list five scenarios the content already shipped.
 * Adding a scenario is now purely a {@code level-designer} change: drop a {@code test-*.json} file
 * under {@code assets/data/} and it appears here on its own.
 *
 * <p><strong>Discovery reads {@link FileHandle#list()} on {@code Gdx.files.internal("data")}</strong>,
 * which {@code JsonContentSource}'s own javadoc calls out as having "no answer for the web target's
 * asset packaging". Read on purpose before writing this: {@code backend-web-1.6.1-sources.jar}'s
 * {@code MemoryFileStorage}/{@code InternalStorage} backs {@code FileType.Internal} with an
 * {@code OrderedMap} that only {@code Local} storage's {@code write} path ever populates — nothing in
 * that jar populates it for a preloaded internal asset, so {@code list()} on the web target most
 * likely returns nothing there, silently. This is accepted here because this class exists only in
 * the {@code -Ptests} build flavour, which today is a desktop concern: {@code
 * game/build.gradle.kts}'s {@code -Ptests} property has never been combined with a {@code :web}
 * build, on desktop {@link FileHandle#list()} is backed by a real {@code java.io.File#listFiles()}
 * and works exactly as needed, and this task's own acceptance criterion is that the {@code -Ptests}
 * build compiles, not that it runs correctly under TeaVM. If a future phase ever wants this flavour
 * on the web target, discovery needs to move to build time (a generated source, the way the level
 * documents are generated) rather than trusting this backend's {@code list()} at run time.
 *
 * <p><strong>#291's stack survives: newest first, ruled by the project owner on the ordering
 * question this class first answered with a plain alphabetical sort — that answer did not satisfy
 * #291 and was replaced.</strong> Nothing about a filesystem listing carries "when was this added" in
 * any form this project can read deterministically (file modification time resets to checkout time on
 * a fresh clone), so the signal is carried by the file name instead: a scenario meant to sort by
 * recency is named {@code test-NNN-<name>.json}, where {@code NNN} is a number chosen when the file is
 * authored and left with gaps so a later scenario can be inserted between two existing ones without
 * renaming anything. {@link #rankOf} reads that number back out, and {@link #discover} sorts
 * numbered scenarios by it, descending — the highest number, the most recently authored, first,
 * exactly as the old hand-ordered stack put its newest entry on top.
 *
 * <p><strong>A level id with no {@code NNN} in it is not dropped and not placed arbitrarily.</strong>
 * It carries no recency signal at all, so it cannot be interleaved with the numbered ones by any rule
 * that would not be inventing an answer this class has no basis for; instead every such scenario
 * sorts after every numbered one, and the unnumbered scenarios sort among themselves alphabetically by
 * level id, for the same determinism reason the numbered ones are read from the name rather than the
 * disk. {@code test-boss}, {@code test-wave-04}, {@code test-wave-09} and {@code test-wave-12} are
 * today's only examples — the batch phase 11h authored before this ordering convention existed —
 * and {@link TestScenariosTest} pins this exact case with real-shaped fixtures, not just a
 * hypothetical one.
 *
 * <p>Each {@link Scenario#levelId()} is a level file under {@code assets/data/} in the existing
 * format — {@code game/adapter/content/JsonContentSource.java} loads it exactly as it loads
 * {@code level-01}, by that id, from {@code <levelId>.json} in the data directory.
 *
 * <p><strong>The prefix of a label names the authoring form the scenario exercises</strong>, not the
 * word "path" generically: {@code LINE:} for a {@code constant} trajectory, {@code PATH:} for one
 * written as relative {@code "segments"}, {@code ABS:} for one written as absolute
 * {@code "waypoints"}, and {@code ARC:} for a curved one — the fourth kind #301 did not need to name
 * because no test scenario used it yet. #301 decided the prefix is worth keeping, because it is what
 * the project owner reads while choosing what to open; this class now derives it from the trajectory
 * the scenario's first overriding spawn actually places (reading {@code trajectories.json} and
 * {@code waves.json} directly, the same {@code JsonReader}/{@code JsonValue} way {@code
 * JsonContentSource} reads them, following {@code mirrorOf} and {@code speedOf} the same way it
 * does) rather than from the filename, which cannot say it and would need a new optional key in the
 * level schema to say it instead — the cheaper of the two ways out #311's plan text lays out, and the
 * one that keeps the label right by construction with no schema change. A scenario with no trajectory
 * override (an ordinary wave, or a boss with none) falls back to its id, and {@code "boss"} present
 * at the top of the level file is always labelled {@code BOSS} outright.
 *
 * <p><strong>{@link #labelFor} is deliberately lenient: it never throws.</strong> A malformed or
 * missing reference yields the generic id-derived label instead of failing the whole menu, because
 * the actual content is validated for real, loudly, by {@code JsonContentSource} the moment a
 * scenario is opened — this class only decides what to print on a button before that happens. The
 * same guarantee holds for {@link #rankOf}, for the same reason, even though it decides sort order
 * rather than label text and so has no {@code try/catch} of {@code labelFor}'s own: an oversized
 * {@code NNN} (more digits than {@code int} holds) is treated exactly like no number at all rather
 * than thrown, because one malformed file name must not crash {@link TestMenuScreen}'s constructor
 * for every scenario, not just cost the one file its recency rank.
 */
final class TestScenarios {

    private TestScenarios() {
    }

    /** One entry in the TESTS submenu: {@code levelId} is also the scenario's level file name. */
    record Scenario(String levelId, String label) {
    }

    private static final String PREFIX = "test-";

    /** {@code test-<digits>-<name>}: the digits are the recency rank, the rest is the display name. */
    private static final Pattern NUMBERED = Pattern.compile("^test-(\\d+)-(.+)$");

    /**
     * Discovers the scenario list against the real asset tree. A method, not a cached static field:
     * a static field's initializer runs the moment the class is loaded, which happens the moment
     * {@code TestScenariosTest} references {@link #discover} too — and {@link Gdx#files} does not
     * exist in that headless JUnit process, so an eager field would fail every test in this class
     * with an {@code ExceptionInInitializerError} regardless of which member it actually touches.
     */
    static List<Scenario> all() {
        return discover(Gdx.files.internal("data"));
    }

    /**
     * Discovers every {@code test-*.json} file directly under {@code dataDir} and builds one
     * {@link Scenario} per file, sorted by {@link Scenario#levelId()}. Package-private and taking
     * the directory as a parameter so a test can point it at a fixture directory instead of a real
     * libGDX asset tree.
     */
    static List<Scenario> discover(FileHandle dataDir) {
        List<Scenario> scenarios = new ArrayList<>();
        for (FileHandle file : dataDir.list(".json")) {
            String levelId = file.nameWithoutExtension();
            if (levelId.startsWith(PREFIX)) {
                scenarios.add(new Scenario(levelId, labelFor(dataDir, levelId)));
            }
        }
        scenarios.sort(TestScenarios::compareByRecency);
        return List.copyOf(scenarios);
    }

    /**
     * Numbered scenarios first, highest number (most recently authored) first; unnumbered scenarios
     * after every numbered one, and alphabetically among themselves — see this class's own javadoc
     * for why an unnumbered id cannot be interleaved with the numbered ones by any rule this class has
     * a basis for.
     */
    private static int compareByRecency(Scenario a, Scenario b) {
        Integer rankA = rankOf(a.levelId());
        Integer rankB = rankOf(b.levelId());
        if (rankA != null && rankB != null) {
            return Integer.compare(rankB, rankA);
        }
        if (rankA != null) {
            return -1;
        }
        if (rankB != null) {
            return 1;
        }
        return a.levelId().compareTo(b.levelId());
    }

    /**
     * The {@code NNN} in {@code test-NNN-<name>}, or {@code null} if {@code levelId} carries none —
     * including a number too large for {@code int}, treated exactly like no number at all rather than
     * thrown. {@link Pattern#compile}'s {@code \d+} bounds the digit count in no way, so a scenario
     * named e.g. {@code test-99999999999999999999-name.json} matches the pattern but overflows
     * {@link Integer#valueOf}; this decides sort order, not label text, so it has no {@code labelFor}
     * of its own to catch it, and a level-designer typo here must not take the whole menu down with
     * it — {@link #discover} has no guard around this call.
     */
    private static Integer rankOf(String levelId) {
        Matcher matcher = NUMBERED.matcher(levelId);
        if (!matcher.matches()) {
            return null;
        }
        try {
            return Integer.valueOf(matcher.group(1));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static String labelFor(FileHandle dataDir, String levelId) {
        String fallback = fallbackName(levelId);
        try {
            JsonValue level = new JsonReader().parse(dataDir.child(levelId + ".json"));
            if (level.has("boss")) {
                return "BOSS";
            }
            String trajectoryId = firstTrajectoryOverride(dataDir, level);
            if (trajectoryId == null) {
                return fallback;
            }
            String kind = kindOf(dataDir, trajectoryId);
            return kind == null ? fallback : kind + ": " + stripLeadingWord(fallback, kind);
        } catch (RuntimeException e) {
            // A label is cosmetic; the scenario's actual content is validated, loudly, by
            // JsonContentSource the moment it is opened. Falling back here never hides that.
            return fallback;
        }
    }

    /**
     * {@code "test-090-slide-descend"} becomes {@code "SLIDE DESCEND"} — the recency number is a
     * sorting key, not part of what the project owner reads on the button, so {@link #rankOf}'s own
     * pattern strips it before the rest of this method runs. {@code "test-boss"}, which carries no
     * number, is unaffected and simply loses its {@code "test-"} prefix as before.
     */
    private static String fallbackName(String levelId) {
        Matcher numbered = NUMBERED.matcher(levelId);
        String withoutPrefix = numbered.matches()
            ? numbered.group(2)
            : levelId.startsWith(PREFIX) ? levelId.substring(PREFIX.length()) : levelId;
        return withoutPrefix.replace('-', ' ').toUpperCase();
    }

    /** Drops a leading word equal to {@code kind} so {@code "PATH: PATH TURN"} reads {@code "PATH: TURN"}. */
    private static String stripLeadingWord(String name, String kind) {
        String withSpace = kind + " ";
        return name.startsWith(withSpace) ? name.substring(withSpace.length()) : name;
    }

    /**
     * The first spawn, across every wave the level places, that carries a {@code "trajectory"}
     * override — the same key {@code JsonContentSource#parseSpawnEvent} reads, optional there for the
     * same reason: most spawns fly their archetype's own default and only a scenario built to
     * exercise a specific shape overrides it.
     */
    private static String firstTrajectoryOverride(FileHandle dataDir, JsonValue level) {
        JsonValue placements = level.get("waves");
        if (placements == null) {
            return null;
        }
        Map<String, JsonValue> wavesById = wavesById(dataDir);
        for (JsonValue placement : placements) {
            String waveId = placement.getString("wave", null);
            if (waveId == null) {
                continue;
            }
            JsonValue wave = wavesById.get(waveId);
            if (wave == null) {
                continue;
            }
            JsonValue spawns = wave.get("spawns");
            if (spawns == null) {
                continue;
            }
            for (JsonValue spawn : spawns) {
                String trajectoryId = spawn.getString("trajectory", null);
                if (trajectoryId != null) {
                    return trajectoryId;
                }
            }
        }
        return null;
    }

    /**
     * {@code waves.json} is optional, exactly as it is for {@code JsonContentSource#loadWaves} — a
     * data directory without it (none exist today, but nothing here assumes one always will) simply
     * has no wave to look up, and every scenario falls back to its id-derived name.
     */
    private static Map<String, JsonValue> wavesById(FileHandle dataDir) {
        Map<String, JsonValue> byId = new HashMap<>();
        FileHandle file = dataDir.child("waves.json");
        if (!file.exists()) {
            return byId;
        }
        JsonValue root = new JsonReader().parse(file);
        JsonValue waves = root.get("waves");
        if (waves == null) {
            return byId;
        }
        for (JsonValue wave : waves) {
            byId.put(wave.getString("id"), wave);
        }
        return byId;
    }

    /**
     * {@code LINE}, {@code PATH}, {@code ABS} or {@code ARC}, following {@code "mirrorOf"} and
     * {@code "speedOf"} the same way {@code JsonContentSource#resolveDerived} does — a mirror or a
     * sped-up copy carries the same authoring form as whatever it derives from. {@code null} if
     * {@code trajectoryId} cannot be resolved to a real entry, including a cycle.
     */
    private static String kindOf(FileHandle dataDir, String trajectoryId) {
        Map<String, JsonValue> byId = trajectoriesById(dataDir);
        JsonValue entry = resolveRaw(byId, trajectoryId, new HashSet<>());
        if (entry == null) {
            return null;
        }
        String type = entry.getString("type", null);
        if ("arc".equals(type)) {
            return "ARC";
        }
        if ("path".equals(type)) {
            return entry.has("waypoints") ? "ABS" : "PATH";
        }
        return "LINE";
    }

    private static JsonValue resolveRaw(Map<String, JsonValue> byId, String id, Set<String> seen) {
        if (!seen.add(id)) {
            return null;
        }
        JsonValue entry = byId.get(id);
        if (entry == null) {
            return null;
        }
        if (entry.has("mirrorOf")) {
            return resolveRaw(byId, entry.getString("mirrorOf"), seen);
        }
        if (entry.has("speedOf")) {
            return resolveRaw(byId, entry.getString("speedOf"), seen);
        }
        return entry;
    }

    private static Map<String, JsonValue> trajectoriesById(FileHandle dataDir) {
        Map<String, JsonValue> byId = new HashMap<>();
        JsonValue root = new JsonReader().parse(dataDir.child("trajectories.json"));
        for (JsonValue entry : root.get("trajectories")) {
            byId.put(entry.getString("id"), entry);
        }
        return byId;
    }
}
