package dev.luchoc.littlespaceship.game.adapter.content;

import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.utils.JsonReader;
import com.badlogic.gdx.utils.JsonValue;
import dev.luchoc.littlespaceship.core.port.ArcTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.AttachmentDefinition;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.BossDefinition;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.EnemyDefinition;
import dev.luchoc.littlespaceship.core.port.FormationDefinition;
import dev.luchoc.littlespaceship.core.port.FormationSlot;
import dev.luchoc.littlespaceship.core.port.PathSegment;
import dev.luchoc.littlespaceship.core.port.PathTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleAttachmentDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleBossDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleEnemyDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleFormationDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleWaveDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleWaveTimeline;
import dev.luchoc.littlespaceship.core.port.SpawnEvent;
import dev.luchoc.littlespaceship.core.port.TrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.WaveDefinition;
import dev.luchoc.littlespaceship.core.port.WaveEndCondition;
import dev.luchoc.littlespaceship.core.port.WavePlacement;
import dev.luchoc.littlespaceship.core.port.WaveTimeline;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * The {@link ContentSource} the plan's phase 04 left to {@code game}: reads
 * {@code assets/data/*.json} with {@link JsonReader}/{@link JsonValue} — never the reflection-based
 * {@code Json} class, which would break the web build far from where the mistake was made — and
 * exposes the result as id-keyed lookups, built once at load time.
 *
 * <p>Every file is parsed eagerly in the constructor, so a malformed file fails at startup, not on
 * whichever tick first asks for the broken id. {@code core}'s own contracts already name the id or
 * the component field that is wrong ({@link ComponentSpec} accessors, {@link SimpleEnemyDefinition}
 * and friends); this class is the only place that also knows the file name, so every failure caught
 * here is rethrown with that name prefixed, which is what the acceptance criterion "names the file
 * and the offending id" actually needs end to end.
 */
public final class JsonContentSource implements ContentSource {

    /**
     * Width of the playfield, in logical units — duplicated from {@code
     * core.domain.system.MotionSystem#PLAYFIELD_WIDTH}, which {@code game} cannot import ({@code
     * core.domain} is not part of the contract this module depends on). Used only to validate an
     * absolute path's waypoints (phase 11j, issue #287) against the same rectangle {@code Transform}
     * lives in; {@link dev.luchoc.littlespaceship.game.screen.PlayScreen} already carries this literal
     * for the identical reason.
     */
    private static final float PLAYFIELD_WIDTH = 208f;

    /**
     * Height of the playfield, in logical units — duplicated from {@code
     * core.domain.system.SpawnSystem#PLAYFIELD_HEIGHT} for the same reason {@link #PLAYFIELD_WIDTH} is.
     */
    private static final float PLAYFIELD_HEIGHT = 270f;

    /**
     * The fixed step, in seconds — duplicated from {@code core.application.GameLoop#STEP} for the
     * same reason {@link #PLAYFIELD_WIDTH} is. Used only to quantise a formation slot's authored
     * {@code delaySeconds} to the nearest whole tick before it reaches {@link FormationSlot} — see
     * {@link #loadFormations} for why an un-quantised decimal cannot be trusted to reproduce the tick
     * count a designer actually typed, once {@code core} accumulates this same step onto it.
     */
    private static final float TICK_SECONDS = 1f / 60f;

    private final BalanceValues balance;
    private final Map<String, EnemyDefinition> enemies = new HashMap<>();
    private final Map<String, TrajectoryDefinition> trajectories = new HashMap<>();
    private final Map<String, FormationDefinition> formations = new HashMap<>();
    private final Map<String, WaveTimeline> timelines = new HashMap<>();
    private final Map<String, AttachmentDefinition> attachments = new HashMap<>();
    private final Map<String, BossDefinition> bosses = new HashMap<>();
    private final Map<String, WaveDefinition> waves = new HashMap<>();
    private final Map<String, List<WavePlacement>> placements = new HashMap<>();

    /**
     * Loads every content file under {@code dataDir}, plus the level named by {@code levelId} from
     * {@code <levelId>.json} in that same directory.
     *
     * <p>The id is a constructor parameter rather than a hardcoded constant, per this class's own
     * former javadoc naming exactly this as the thing a second level would need — {@code
     * game-presentation}'s handover of issue #87. Loading stays single-level and eager: nothing
     * here lists the directory to discover every {@code level-*.json} on disk, because {@link
     * FileHandle#list()} has no answer for the web target's asset packaging, and there is still only
     * one concrete level to load. Whoever calls this decides which one.
     *
     * @param dataDir the directory holding {@code balance.json}, {@code trajectories.json},
     *     {@code formations.json}, {@code enemies.json}, {@code attachments.json}, the optional
     *     {@code waves.json} and {@code <levelId>.json}
     * @param levelId the content id of the level to load; also the level file's name without the
     *     {@code .json} extension
     * @throws IllegalArgumentException if any file is missing or malformed, naming the file and
     *     whatever it could not resolve
     */
    public JsonContentSource(FileHandle dataDir, String levelId) {
        if (dataDir == null) {
            throw new IllegalArgumentException("the content source needs a data directory");
        }
        if (levelId == null || levelId.isEmpty()) {
            throw new IllegalArgumentException("the content source needs a level id");
        }
        JsonReader reader = new JsonReader();
        this.balance = loadBalance(reader, dataDir.child("balance.json"));
        loadTrajectories(reader, dataDir.child("trajectories.json"));
        loadFormations(reader, dataDir.child("formations.json"));
        loadEnemies(reader, dataDir.child("enemies.json"));
        loadAttachments(reader, dataDir.child("attachments.json"));
        loadWaves(reader, dataDir.child("waves.json"));
        loadLevel(reader, dataDir.child(levelId + ".json"), levelId);
    }

    @Override
    public BalanceValues balance() {
        return balance;
    }

    @Override
    public EnemyDefinition enemy(String id) {
        return require(enemies, id, "enemy");
    }

    @Override
    public TrajectoryDefinition trajectory(String id) {
        return require(trajectories, id, "trajectory");
    }

    @Override
    public FormationDefinition formation(String id) {
        return require(formations, id, "formation");
    }

    @Override
    public WaveTimeline timeline(String levelId) {
        return require(timelines, levelId, "level timeline");
    }

    @Override
    public AttachmentDefinition attachment(String id) {
        return require(attachments, id, "attachment");
    }

    @Override
    public WaveDefinition wave(String id) {
        return require(waves, id, "wave");
    }

    @Override
    public List<WavePlacement> placements(String levelId) {
        return require(placements, levelId, "level placements");
    }

    @Override
    public boolean hasBoss(String levelId) {
        return bosses.containsKey(levelId);
    }

    @Override
    public BossDefinition boss(String levelId) {
        return require(bosses, levelId, "level boss");
    }

    private static <T> T require(Map<String, T> registry, String id, String kind) {
        T value = registry.get(id);
        if (value == null) {
            throw new IllegalArgumentException("unknown " + kind + " id '" + id + "'");
        }
        return value;
    }

    private static BalanceValues loadBalance(JsonReader reader, FileHandle file) {
        return inFile(file, () -> JsonBalanceValues.from(reader.parse(file)));
    }

    /**
     * Reads {@code trajectories.json} in two passes so a <em>derived</em> entry — one that names
     * another trajectory instead of a {@code "type"} — can point at any other entry in the file
     * regardless of which one is written first. The first pass parses every entry that carries a
     * {@code "type"} (or defaults to {@code "constant"}) straight into {@link #trajectories}; the
     * second resolves every derived entry against that map, recursively, so a derivation of a
     * derivation works and a cycle or a dangling reference fails loudly instead of looping or leaving
     * an id unresolved.
     *
     * <p>There are two derivations and they share this machinery on purpose: {@code "mirrorOf"}
     * (issue #264) and {@code "speedOf"} (issue #296). Both take one existing trajectory and produce
     * another under a new id, so a faster mirror and a mirrored faster version are both expressible,
     * and a cycle through either kind is caught by the same chain check. See {@link #resolveDerived},
     * {@link #mirror} and {@link #faster} for the contracts themselves.
     */
    private void loadTrajectories(JsonReader reader, FileHandle file) {
        inFile(file, () -> {
            Map<String, JsonValue> derivedEntries = new HashMap<>();
            for (JsonValue entry : reader.parse(file).get("trajectories")) {
                String id = entry.getString("id");
                if (entry.has("mirrorOf")) {
                    requireOnlyKeys(entry, "trajectory '" + id + "'", "id", "mirrorOf");
                    derivedEntries.put(id, entry);
                } else if (entry.has("speedOf")) {
                    requireOnlyKeys(entry, "trajectory '" + id + "'", "id", "speedOf", "multiplier");
                    derivedEntries.put(id, entry);
                } else {
                    TrajectoryDefinition trajectory = parseTrajectory(entry);
                    trajectories.put(trajectory.id(), trajectory);
                }
            }
            for (String id : derivedEntries.keySet()) {
                resolveDerived(id, derivedEntries, new LinkedHashSet<>());
            }
            return null;
        });
    }

    /**
     * Resolves the trajectory named {@code id} to a fully built {@link TrajectoryDefinition},
     * recursively following {@code "mirrorOf"} and {@code "speedOf"} chains — a mirror may itself be
     * mirrored or sped up, since nothing about either mechanism cares whether the source it transforms
     * is an authored shape or another derivation. {@code resolving} is the chain of ids currently
     * being resolved, in encounter order: a
     * name reappearing in it is a cycle (e.g. {@code a} mirrors {@code b} mirrors {@code a}), reported
     * with the whole chain rather than just the repeated id, and a name that resolves to neither an
     * already-parsed trajectory nor a pending mirror entry is a reference to something that does not
     * exist in this file. Both fail loudly, at load, naming the trajectory id — this method's own
     * exceptions are the ones {@link #inFile} prefixes with the file's path.
     *
     * <p>Building the derived trajectory itself is composition over the already-public record
     * constructors — see {@link #mirror(String, TrajectoryDefinition)} and {@link #faster(String,
     * TrajectoryDefinition, float)} — exactly as {@code core-domain} argued on {@link
     * TrajectoryDefinition}'s own javadoc and demonstrated in {@code core}'s test: no new {@code core}
     * API, no fourth sealed kind.
     */
    private TrajectoryDefinition resolveDerived(
        String id, Map<String, JsonValue> derivedEntries, Set<String> resolving) {
        TrajectoryDefinition existing = trajectories.get(id);
        if (existing != null) {
            return existing;
        }
        if (!derivedEntries.containsKey(id)) {
            throw new IllegalArgumentException(
                "trajectory derives from unknown trajectory '" + id + "'");
        }
        if (!resolving.add(id)) {
            throw new IllegalArgumentException(
                "trajectory derivation cycle: " + String.join(" -> ", resolving) + " -> " + id);
        }
        JsonValue entry = derivedEntries.get(id);
        boolean isMirror = entry.has("mirrorOf");
        String sourceId = entry.getString(isMirror ? "mirrorOf" : "speedOf");
        TrajectoryDefinition original = resolveDerived(sourceId, derivedEntries, resolving);
        TrajectoryDefinition derived = isMirror
            ? mirror(id, original)
            : construct(id, () -> faster(id, original, requireMultiplier(entry, id)));
        trajectories.put(id, derived);
        resolving.remove(id);
        return derived;
    }

    /**
     * Reads and validates a {@code "speedOf"} entry's {@code "multiplier"}. It must be present,
     * finite and strictly positive: zero would divide every duration by zero, a negative one would
     * reverse the path rather than speed it up (that is {@code "mirrorOf"}'s job, and only for the
     * horizontal axis), and a non-finite one produces velocities {@code core} refuses anyway but far
     * from where the mistake was written. Every message names the trajectory id; {@link #inFile} adds
     * the file.
     */
    private static float requireMultiplier(JsonValue entry, String id) {
        if (!entry.has("multiplier")) {
            throw new IllegalArgumentException(
                "trajectory '" + id + "' needs a 'multiplier' alongside 'speedOf'");
        }
        float multiplier = entry.getFloat("multiplier");
        if (!(multiplier > 0f) || Float.isInfinite(multiplier)) {
            throw new IllegalArgumentException(
                "trajectory '" + id + "' has a speed multiplier that is not a finite positive "
                    + "number, was " + multiplier);
        }
        return multiplier;
    }

    /**
     * Builds the same trajectory traversed {@code multiplier} times sooner, under a new {@code id}:
     * <strong>the geometry is identical — same shape, same size — and only the traversal time
     * changes.</strong> That is the whole of what the project owner decided "faster" means on
     * 04/09/2026; the other meaning, velocities up alone, scales the shape and stays an authoring
     * consequence rather than a knob (plan 11j, and invariant 6).
     *
     * <p>The arithmetic, per kind, is the substitution {@code t -> multiplier * t} applied to each
     * kind's own closed form, so the traced curve is pointwise the same set of positions:
     *
     * <ul>
     *   <li>{@code constant}: velocities times {@code k}. The path is a ray from the spawn point; its
     *       direction is unchanged because both components scale by the same factor.
     *   <li>{@code arc}: velocities times {@code k}, {@code ay} times {@code k * k}. From
     *       {@code x = vx t}, {@code y = vy t + ay t² / 2}, the scaled arc at {@code t/k} gives
     *       {@code k·vx·(t/k) = vx·t} and {@code k·vy·(t/k) + k²·ay·(t/k)²/2 = vy·t + ay·t²/2} — the
     *       same parabola, walked sooner. This is why {@code ay} takes the square and the velocities
     *       do not.
     *   <li>{@code path}: every segment's velocities times {@code k} and its duration divided by
     *       {@code k}, so each leg's displacement {@code v·d} is unchanged and its direction with it.
     *       A {@code wait} (zero velocity) stays a wait and simply lasts less. {@code loopStart} and
     *       {@code loopCount} are copied untouched: a repeat is a range of the same legs, so the
     *       repeated geometry scales with them.
     * </ul>
     *
     * <p>Rule 3 is not weakened, and is not trusted either: the result goes back through {@link
     * PathTrajectoryDefinition}'s own constructor, so a last segment at rest is still refused —
     * multiplying a zero velocity by anything leaves it zero, so a path that ends at rest cannot be
     * laundered into a legal one by going through {@code "speedOf"}. Conversely an absurd multiplier
     * is refused by {@link PathSegment}, which checks both a segment's velocities and its duration —
     * and it is a velocity that gives way first: at any velocity worth authoring, {@code vy *
     * multiplier} overflows to infinity long before {@code duration / multiplier} could underflow to
     * exact zero. {@link #resolveDerived} wraps whichever failure fires with the derived id.
     */
    private static TrajectoryDefinition faster(
        String id, TrajectoryDefinition original, float multiplier) {
        if (original instanceof SimpleTrajectoryDefinition simple) {
            return new SimpleTrajectoryDefinition(
                id, simple.vx() * multiplier, simple.vy() * multiplier);
        }
        if (original instanceof ArcTrajectoryDefinition arc) {
            return new ArcTrajectoryDefinition(
                id, arc.vx() * multiplier, arc.vy() * multiplier, arc.ay() * multiplier * multiplier);
        }
        if (original instanceof PathTrajectoryDefinition path) {
            List<PathSegment> scaled = new ArrayList<>();
            for (PathSegment segment : path.segments()) {
                scaled.add(new PathSegment(
                    segment.vx() * multiplier,
                    segment.vy() * multiplier,
                    segment.duration() / multiplier));
            }
            return new PathTrajectoryDefinition(id, scaled, path.loopStart(), path.loopCount());
        }
        throw new IllegalStateException(
            "unreachable: TrajectoryDefinition is sealed to the three kinds handled above");
    }

    /**
     * Builds the mirror of {@code original} under a new {@code id}: negate every horizontal
     * component, keep every vertical field and every duration or loop parameter untouched, using each
     * kind's own public constructor. No new {@code core} type and no new {@code core} API — every
     * {@link TrajectoryDefinition} implementation is a record whose fields are already readable
     * through their accessors, which is the whole mechanism {@code core-domain} left for this loader
     * to compose.
     */
    private static TrajectoryDefinition mirror(String id, TrajectoryDefinition original) {
        if (original instanceof SimpleTrajectoryDefinition simple) {
            return new SimpleTrajectoryDefinition(id, -simple.vx(), simple.vy());
        }
        if (original instanceof ArcTrajectoryDefinition arc) {
            return new ArcTrajectoryDefinition(id, -arc.vx(), arc.vy(), arc.ay());
        }
        if (original instanceof PathTrajectoryDefinition path) {
            List<PathSegment> mirroredSegments = new ArrayList<>();
            for (PathSegment segment : path.segments()) {
                mirroredSegments.add(new PathSegment(-segment.vx(), segment.vy(), segment.duration()));
            }
            return new PathTrajectoryDefinition(
                id, mirroredSegments, path.loopStart(), path.loopCount());
        }
        throw new IllegalStateException(
            "unreachable: TrajectoryDefinition is sealed to the three kinds handled above");
    }

    /**
     * Parses one {@code trajectories.json} entry into the {@link TrajectoryDefinition} kind its
     * {@code "type"} names — {@code "constant"} (the default, so the four entries that shipped
     * before {@code "type"} existed still load unchanged), {@code "arc"} or {@code "path"}, the three
     * kinds {@code docs/plan/11c-movement-shapes/shape-catalogue.md} and phase 11i decide and {@link
     * TrajectoryDefinition} is sealed to. Any other value fails loudly naming both the trajectory id
     * and the bad type — deliberately not defaulted to {@code "constant"}, the same reasoning {@link
     * #parseEndCondition} already applies to a wave's end condition: a typo in {@code "type"} silently
     * loading as a different shape is a wrong game, not a crash, and this loader used to be exactly
     * that permissive by reading only {@code id}, {@code vx} and {@code vy} and ignoring everything
     * else. An entry naming {@code "mirrorOf"} instead of {@code "type"} never reaches this method —
     * {@link #loadTrajectories} routes it, like a {@code "speedOf"} entry, to {@link #resolveDerived} instead.
     */
    private static TrajectoryDefinition parseTrajectory(JsonValue entry) {
        String id = entry.getString("id");
        String type = entry.getString("type", "constant");
        if ("constant".equals(type)) {
            requireOnlyKeys(entry, "trajectory '" + id + "'", "id", "type", "vx", "vy");
            return construct(id, () ->
                new SimpleTrajectoryDefinition(id, entry.getFloat("vx"), entry.getFloat("vy")));
        }
        if ("arc".equals(type)) {
            requireOnlyKeys(entry, "trajectory '" + id + "'", "id", "type", "vx", "vy", "ay");
            return construct(id, () -> new ArcTrajectoryDefinition(
                id, entry.getFloat("vx"), entry.getFloat("vy"), entry.getFloat("ay")));
        }
        if ("path".equals(type)) {
            requireOnlyKeys(entry, "trajectory '" + id + "'",
                "id", "type", "segments", "waypoints", "loopStart", "loopCount");
            boolean hasSegments = entry.has("segments");
            boolean hasWaypoints = entry.has("waypoints");
            if (hasSegments == hasWaypoints) {
                throw new IllegalArgumentException(
                    "trajectory '" + id + "' must declare exactly one of 'segments' (relative — "
                        + "velocity and duration) or 'waypoints' (absolute — destination and speed), had "
                        + (hasSegments ? "both" : "neither"));
            }
            List<PathSegment> segments = hasSegments
                ? parseSegments(entry.get("segments"), id)
                : parseWaypoints(entry.get("waypoints"), id);
            int loopStart = entry.getInt("loopStart", segments.size());
            int loopCount = entry.getInt("loopCount", 1);
            return construct(id, () -> new PathTrajectoryDefinition(id, segments, loopStart, loopCount));
        }
        throw new IllegalArgumentException(
            "trajectory '" + id + "' has an unknown type '" + type + "'");
    }

    /**
     * Runs a {@link TrajectoryDefinition}'s public constructor and, if {@code core}'s own validation
     * rejects it (e.g. {@link PathTrajectoryDefinition}'s rule-3 check on a path that ends at rest),
     * rethrows with the trajectory id prefixed. {@code core}'s exceptions correctly know nothing of
     * ids or files — see {@code PathTrajectoryDefinition}'s own javadoc — so this is the other half
     * "fails at load, naming the file and the id" needs, symmetric with {@link #inFile} adding the
     * file name at the top of this class.
     */
    private static TrajectoryDefinition construct(String id, Loader<TrajectoryDefinition> loader) {
        try {
            return loader.load();
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("trajectory '" + id + "': " + e.getMessage(), e);
        }
    }

    /**
     * Parses a {@code "path"} trajectory's {@code "segments"} array into {@link PathSegment}s. A
     * segment is either {@code {vx, vy, duration}} or the {@code {"wait": seconds}} shorthand the
     * issue #259 comment offers — translated here to {@code PathSegment(0, 0, seconds)} since {@code
     * core} only ever sees the three-field record; a "wait" is a content-authoring convenience, not a
     * distinct kind. An "indefinite" wait or a "permanent" loop is simply a very large {@code
     * duration}/{@code loopCount} — a convention, not a key this loader treats specially.
     */
    private static List<PathSegment> parseSegments(JsonValue segmentsValue, String trajectoryId) {
        if (segmentsValue == null || segmentsValue.size == 0) {
            throw new IllegalArgumentException(
                "trajectory '" + trajectoryId + "' has no segments");
        }
        List<PathSegment> segments = new ArrayList<>();
        String context = "trajectory '" + trajectoryId + "' segment";
        for (JsonValue segment : segmentsValue) {
            if (segment.has("wait")) {
                requireOnlyKeys(segment, context, "wait");
                segments.add(new PathSegment(0f, 0f, segment.getFloat("wait")));
            } else {
                requireOnlyKeys(segment, context, "vx", "vy", "duration");
                if (!segment.has("vx") || !segment.has("vy") || !segment.has("duration")) {
                    throw new IllegalArgumentException(
                        context + " needs 'vx', 'vy' and 'duration' (or a 'wait' shorthand)");
                }
                segments.add(new PathSegment(
                    segment.getFloat("vx"), segment.getFloat("vy"), segment.getFloat("duration")));
            }
        }
        return segments;
    }

    /**
     * Parses a {@code "path"} trajectory's {@code "waypoints"} array into {@link PathSegment}s — the
     * absolute authoring syntax phase 11j adds, alongside {@code "segments"}, per the shape posted on
     * issue #287. {@code core} gains no new API for this: a leg between two consecutive waypoints is
     * turned into the exact same {@code PathSegment(vx, vy, duration)} a hand-written {@code "segments"}
     * entry would produce — {@code direction = normalize(B − A)}, {@code duration = |B − A| / speed} —
     * so mirroring, looping and rule 3 all keep working unchanged; this method only ever hands
     * already-built {@link PathSegment}s to the same {@link PathTrajectoryDefinition} constructor
     * {@link #parseSegments} does.
     *
     * <p><strong>The key is the tell.</strong> A path with a {@code "segments"} array is relative —
     * velocity held for a duration, exactly as {@code docs/plan/11c-movement-shapes/shape-catalogue.md}
     * built it; a path with a {@code "waypoints"} array is absolute — a point to reach and the speed to
     * reach it at. The two arrays are mutually exclusive on one entry (checked in {@link
     * #parseTrajectory} before this method is ever called), so nothing here reads as "a puzzle": there
     * is no segment where the two forms could be confused for one another, because they are two
     * different top-level keys, not two shapes of the same object.
     *
     * <p>{@code "waypoints"} is a list of points, first-to-last: the first element is the path's entry
     * point and carries only {@code {"x", "y"}} — nothing precedes it, so it has no speed to travel at.
     * Every element after it is either a destination, {@code {"x", "y", "speed"}} — the leg from the
     * previous point to this one, at this speed — or the {@code {"wait": seconds}} shorthand already
     * used by {@code "segments"}, which pauses at the current point without moving it. This is
     * literally "a segment written as a destination and a speed instead of a velocity and a duration",
     * per waypoint, chained: nothing here invents a whole-path coordinate system, it only lets each leg
     * be authored by where it ends rather than how fast and how long.
     *
     * <p><strong>Every coordinate is checked against the playfield</strong> — {@code [0,
     * PLAYFIELD_WIDTH]} horizontally, {@code [0, PLAYFIELD_HEIGHT]} vertically, the same rectangle
     * {@code Transform} lives in — because these numbers are meant to be read as "where it happens":
     * {@code y = PLAYFIELD_HEIGHT} is the top edge a unit becomes visible at, {@code x =
     * PLAYFIELD_WIDTH} is the right edge it leaves through. A path's own local origin (the first
     * waypoint) is what a wave's {@code atX} normally offsets — so these coordinates only mean what
     * they literally say when the wave placing this path uses {@code atX = 0}. That is the accepted
     * cost the project owner named: <strong>an absolutely-authored path can only happen in one
     * place.</strong> Nothing here enforces that at load time — {@code trajectories.json} and
     * {@code waves.json} are parsed independently, with no cross-reference from one to the other
     * anywhere in this class, and building one for this alone was judged out of proportion to what
     * this task asked for. A level using an absolute path at a nonzero {@code atX} is therefore a
     * silent placement bug, not a loud failure; flagging it mechanically is left to whoever authors
     * levels against this syntax (see this task's status fragment for the argument in full).
     *
     * <p>A destination equal to the point before it — the {@code distance == 0f} case below — is
     * refused rather than silently producing a zero-duration attempt (before {@code core} would ever
     * see it, since {@link PathSegment}'s own constructor forbids a non-positive duration): it is either
     * a wait spelled as a no-op move, or the divide-by-zero {@code duration = distance / speed} would
     * otherwise be. Ending an absolute path on a {@code "wait"} still reaches {@code core}'s own rule-3
     * refusal ("last segment must have nonzero velocity") exactly as a relative path does — tried
     * deliberately, see the status fragment — so the absolute form cannot express anything {@code core}
     * cannot already bound.
     */
    private static List<PathSegment> parseWaypoints(JsonValue waypointsValue, String trajectoryId) {
        if (waypointsValue == null || waypointsValue.size < 2) {
            throw new IllegalArgumentException(
                "trajectory '" + trajectoryId
                    + "' needs at least two waypoints (an entry point and a destination)");
        }
        String context = "trajectory '" + trajectoryId + "' waypoint";
        List<PathSegment> segments = new ArrayList<>();
        float fromX = 0f;
        float fromY = 0f;
        int index = 0;
        for (JsonValue point : waypointsValue) {
            if (index == 0) {
                requireOnlyKeys(point, context + " 0 (the entry point)", "x", "y");
                fromX = point.getFloat("x");
                fromY = point.getFloat("y");
                requirePlayfieldBounds(fromX, fromY, trajectoryId, index);
                index++;
                continue;
            }
            if (point.has("wait")) {
                requireOnlyKeys(point, context + " " + index, "wait");
                segments.add(new PathSegment(0f, 0f, point.getFloat("wait")));
                index++;
                continue;
            }
            requireOnlyKeys(point, context + " " + index, "x", "y", "speed");
            float toX = point.getFloat("x");
            float toY = point.getFloat("y");
            requirePlayfieldBounds(toX, toY, trajectoryId, index);
            float speed = point.getFloat("speed");
            if (speed <= 0f) {
                throw new IllegalArgumentException(
                    "trajectory '" + trajectoryId + "' waypoint " + index
                        + " has a non-positive speed, was " + speed);
            }
            float dx = toX - fromX;
            float dy = toY - fromY;
            float distance = (float) Math.sqrt(dx * dx + dy * dy);
            if (distance == 0f) {
                throw new IllegalArgumentException(
                    "trajectory '" + trajectoryId + "' waypoint " + index + " repeats the previous "
                        + "point (" + toX + ", " + toY + ") — write a {\"wait\": seconds} instead, or "
                        + "fix the coordinates");
            }
            float duration = distance / speed;
            segments.add(new PathSegment(dx / duration, dy / duration, duration));
            fromX = toX;
            fromY = toY;
            index++;
        }
        return segments;
    }

    /**
     * Rejects a waypoint coordinate outside the playfield rectangle. {@code PLAYFIELD_WIDTH} and
     * {@code PLAYFIELD_HEIGHT} are duplicated here rather than imported from {@code core}: {@code
     * MotionSystem}/{@code SpawnSystem} live in {@code core.domain}, which {@code game} never depends
     * on — {@code PlayScreen} already carries the same {@code 208f} literal for the same reason.
     */
    private static void requirePlayfieldBounds(float x, float y, String trajectoryId, int index) {
        if (x < 0f || x > PLAYFIELD_WIDTH || y < 0f || y > PLAYFIELD_HEIGHT) {
            throw new IllegalArgumentException(
                "trajectory '" + trajectoryId + "' waypoint " + index + " (" + x + ", " + y
                    + ") is outside the playfield — must be within [0, " + PLAYFIELD_WIDTH + "] x [0, "
                    + PLAYFIELD_HEIGHT + "]");
        }
    }

    /**
     * Reads {@code formations.json}. A slot's {@code "delaySeconds"} (issue #330/#334) is optional
     * and defaults to {@code 0} — every formation shipped before this issue has none, and must load
     * to the identical {@link FormationSlot} it always did.
     *
     * <p>A present value is quantised to the nearest whole tick, {@code Math.round(delaySeconds *
     * 60f) * TICK_SECONDS}, before it reaches {@link FormationSlot}. What that buys is that the
     * seconds a designer types are only ever a label for a tick count: {@code 0.3}, {@code 0.29} and
     * {@code 0.305} all mean eighteen ticks, and the ambiguity is resolved here, once, at load,
     * rather than in whatever arithmetic consumes it later.
     *
     * <p><b>Corrected 06/09/2026, issue #337.</b> This javadoc used to justify the quantisation by
     * describing how {@code core} crossed from waiting to moving — {@code SpawnSystem} backdating
     * {@code Trajectory.elapsed} to {@code -delaySeconds} in one assignment, {@code MotionSystem}
     * reaching zero by adding the step once per tick, and the two not agreeing bit-for-bit. **That
     * mechanism no longer exists**: #337 replaced the float crossing with an integer {@code
     * delayTicks} countdown, because quantising here did not save it — the mismatch was inside
     * {@code core} and a delayed slot still activated a tick early across a wide band of tick
     * counts. The quantisation above was right and needed no change, which is why this file's code
     * has an empty diff on that fix; only this explanation of it was stale. Kept in seconds rather
     * than a {@code "delayTicks"} key so it stays consistent with every other timestamp this content
     * authors in seconds ({@code SpawnEvent.at}, a pickup's {@code at}).
     */
    private void loadFormations(JsonReader reader, FileHandle file) {
        inFile(file, () -> {
            for (JsonValue entry : reader.parse(file).get("formations")) {
                String id = entry.getString("id");
                List<FormationSlot> slots = new ArrayList<>();
                for (JsonValue slot : entry.get("slots")) {
                    requireOnlyKeys(slot, "formation '" + id + "' slot", "offsetX", "offsetY",
                        "delaySeconds");
                    float rawDelaySeconds = slot.getFloat("delaySeconds", 0f);
                    float delaySeconds = Math.round(rawDelaySeconds * 60f) * TICK_SECONDS;
                    try {
                        slots.add(new FormationSlot(
                            slot.getFloat("offsetX"), slot.getFloat("offsetY"), delaySeconds));
                    } catch (IllegalArgumentException e) {
                        throw new IllegalArgumentException(
                            "formation '" + id + "': " + e.getMessage(), e);
                    }
                }
                FormationDefinition formation = new SimpleFormationDefinition(id, slots);
                formations.put(formation.id(), formation);
            }
            return null;
        });
    }

    private void loadEnemies(JsonReader reader, FileHandle file) {
        inFile(file, () -> {
            for (JsonValue entry : reader.parse(file).get("enemies")) {
                String id = entry.getString("id");
                JsonValue componentsValue = entry.get("components");
                if (componentsValue == null) {
                    throw new IllegalArgumentException("enemy '" + id + "' has no components");
                }
                EnemyDefinition enemy = new SimpleEnemyDefinition(
                    id, JsonComponentSpecs.parse(componentsValue));
                enemies.put(enemy.id(), enemy);
            }
            return null;
        });
    }

    private void loadAttachments(JsonReader reader, FileHandle file) {
        inFile(file, () -> {
            for (JsonValue entry : reader.parse(file).get("attachments")) {
                AttachmentDefinition attachment = new SimpleAttachmentDefinition(
                    entry.getString("id"), entry.getInt("durability"));
                attachments.put(attachment.id(), attachment);
            }
            return null;
        });
    }

    /**
     * Reads {@code waves.json}, the named-content file a level's {@code "waves"} block references by
     * id — beside {@code formations.json} and {@code trajectories.json}, per {@code
     * docs/planning/08-decisions-and-open-items.md}, "The 11 group, 27/08/2026". Optional: no level
     * shipped by this phase is required to use the wave format yet ({@code level-01.json} keeps its
     * flat {@code "events"} list until issue #114 migrates it), so a data directory without this file
     * loads with an empty wave registry rather than failing — the same reasoning {@link #loadLevel}
     * already applies to a level's optional {@code "boss"} block.
     */
    private void loadWaves(JsonReader reader, FileHandle file) {
        if (!file.exists()) {
            return;
        }
        inFile(file, () -> {
            JsonValue root = reader.parse(file);
            requireOnlyKeys(root, "wave file", "waves");
            JsonValue wavesValue = root.get("waves");
            if (wavesValue == null) {
                throw new IllegalArgumentException("wave file has no 'waves' array");
            }
            for (JsonValue entry : wavesValue) {
                requireOnlyKeys(entry, "wave", "id", "end", "spawns");
                String id = entry.getString("id");
                JsonValue spawnsValue = entry.get("spawns");
                if (spawnsValue == null) {
                    throw new IllegalArgumentException("wave '" + id + "' has no spawns");
                }
                List<SpawnEvent> spawns = new ArrayList<>();
                for (JsonValue spawnEntry : spawnsValue) {
                    spawns.add(parseSpawnEvent(spawnEntry, "wave '" + id + "' spawn"));
                }
                JsonValue endValue = entry.get("end");
                if (endValue == null) {
                    throw new IllegalArgumentException("wave '" + id + "' needs an end condition");
                }
                WaveEndCondition end = parseEndCondition(endValue, id);
                waves.put(id, new SimpleWaveDefinition(id, spawns, end));
            }
            return null;
        });
    }

    /**
     * Parses the {@code "end"} object of one {@code waves.json} entry into a {@link
     * WaveEndCondition}. {@code "type"} discriminates between the two sealed cases — {@code
     * "fixedDuration"}, which also needs {@code "seconds"}, and {@code "cleared"}, which needs
     * nothing else — and any other value is rejected rather than defaulted to {@link
     * WaveEndCondition.FixedDuration}: a wave that quietly became a fixed duration because of a typo
     * in {@code "type"} is exactly the silent pacing bug {@code docs/plan/11b-wave-system/plan.md}'s
     * "Watch out for" section warns against.
     */
    private static WaveEndCondition parseEndCondition(JsonValue endValue, String waveId) {
        String type = endValue.getString("type");
        if ("fixedDuration".equals(type)) {
            requireOnlyKeys(endValue, "wave '" + waveId + "' end condition", "type", "seconds");
            return new WaveEndCondition.FixedDuration(endValue.getFloat("seconds"));
        }
        if ("cleared".equals(type)) {
            requireOnlyKeys(endValue, "wave '" + waveId + "' end condition", "type");
            return new WaveEndCondition.Cleared();
        }
        throw new IllegalArgumentException(
            "wave '" + waveId + "' has an unknown end condition type '" + type + "'");
    }

    /**
     * @param entry one spawn's JSON object, shared by a level's legacy {@code "events"} list and a
     *     {@code waves.json} wave's {@code "spawns"} list — the two places {@link SpawnEvent} is
     *     read from, per its own javadoc on having no reference frame of its own
     * @param context named in any error this entry raises, so it reads "wave 'x' spawn" or
     *     "spawn event" depending on which list called it. {@code "trajectory"} is optional and, when
     *     absent, becomes {@code null} — {@link SpawnEvent#hasTrajectoryOverride()} reads that as "use
     *     the archetype's own default", exactly as before this key existed. An id that names no entry
     *     in {@code trajectories.json} is not checked here — this loader has no {@code ContentSource}
     *     to check it against yet, the same reason {@code enemyId}/{@code formationId} are not either
     *     — it fails loudly once {@code SpawnSystem} resolves it at spawn time, per {@code
     *     SpawnEvent}'s own javadoc on {@code trajectoryId}.
     */
    private static SpawnEvent parseSpawnEvent(JsonValue entry, String context) {
        requireOnlyKeys(entry, context,
            "at", "spawn", "formation", "atX", "drop", "dropSlot", "trajectory");
        return new SpawnEvent(
            entry.getFloat("at"),
            entry.getString("spawn"),
            entry.getString("formation"),
            entry.getFloat("atX"),
            entry.getString("drop", null),
            entry.getInt("dropSlot", 0),
            entry.getString("trajectory", null));
    }

    /**
     * Reads the level file's top-level blocks: the optional {@code "boss"} object and exactly one of
     * {@code "events"} (the legacy flat list, still {@code level-01.json}'s own shape until issue
     * #114 migrates it) or {@code "waves"} (an ordered list of {@link WavePlacement}s). Unlike the
     * flattening this class did before issue #112 merged, a {@code "waves"} block is stored as-is —
     * each placement's wave id resolved against {@link #waves} to fail loudly on a typo, but its
     * offset and its wave's own end condition left untouched — because {@code SpawnSystem} now reads
     * {@link ContentSource#wave(String)} and {@link ContentSource#placements(String)} directly and
     * does its own scheduling, including resolving a {@link WaveEndCondition.Cleared} wave at
     * runtime. Flattening here would have quietly reimplemented that scheduling a second time and
     * silently dropped {@code Cleared} support, which is exactly the mistake this rewrite undoes.
     * {@code hasBoss}/{@code boss} answer false/throw for a level whose file carries no {@code "boss"}
     * key at all — a legitimate case per {@link ContentSource}'s own contract — but any key on either
     * object this schema does not name fails loudly through {@link #requireOnlyKeys}, closing the gap
     * {@code level-designer} found: an unrecognised key used to load clean and silently leave the
     * level with no boss, which is worse than a parse error.
     */
    private void loadLevel(JsonReader reader, FileHandle file, String levelId) {
        inFile(file, () -> {
            JsonValue root = reader.parse(file);
            requireOnlyKeys(root, "level file", "boss", "events", "waves");
            JsonValue bossValue = root.get("boss");
            if (bossValue != null) {
                bosses.put(levelId, parseBoss(bossValue));
            }
            JsonValue eventsValue = root.get("events");
            JsonValue placementsValue = root.get("waves");
            if (eventsValue != null && placementsValue != null) {
                throw new IllegalArgumentException(
                    "level file has both 'events' and 'waves' — use exactly one");
            }
            if (eventsValue != null) {
                List<SpawnEvent> events = new ArrayList<>();
                for (JsonValue entry : eventsValue) {
                    events.add(parseSpawnEvent(entry, "spawn event"));
                }
                timelines.put(levelId, new SimpleWaveTimeline(events));
            } else if (placementsValue != null) {
                placements.put(levelId, parsePlacements(placementsValue));
            } else {
                throw new IllegalArgumentException("level file needs either 'events' or 'waves'");
            }
            return null;
        });
    }

    /**
     * Parses a level's {@code "waves"} block into the ordered {@link WavePlacement} list {@code
     * SpawnSystem} now reads through {@link ContentSource#placements(String)}. Each placement's
     * {@code "wave"} id is resolved against {@link #waves} here, at load time, so a typo fails
     * loudly naming the level and the id — the same "malformed content fails at startup" guarantee
     * every other lookup in this class already gives — rather than surfacing later as {@code
     * SpawnSystem} reaching {@link ContentSource#wave(String)}'s own failure with no file name
     * attached. Offsets and end conditions are left exactly as declared: this class no longer
     * schedules anything, it only hands {@code SpawnSystem} the declarations to schedule itself.
     */
    private List<WavePlacement> parsePlacements(JsonValue placementsValue) {
        List<WavePlacement> resolved = new ArrayList<>();
        for (JsonValue entry : placementsValue) {
            requireOnlyKeys(entry, "wave placement", "wave", "offset");
            WavePlacement placement = new WavePlacement(entry.getString("wave"), entry.getFloat("offset"));
            require(waves, placement.waveId(), "wave");
            resolved.add(placement);
        }
        return resolved;
    }


    /**
     * Parses the {@code "boss"} block, keys named exactly after {@link BossDefinition}'s accessors —
     * see {@code docs/plan/07-boss/status.md}'s "Notes for whoever comes next" for the field list.
     */
    private static BossDefinition parseBoss(JsonValue value) {
        requireOnlyKeys(value, "boss block",
            "id", "entersAt", "coreHealth", "podHealth", "armHealth",
            "corePoints", "podPoints", "armPoints",
            "entranceSpeed", "combatY", "patternCooldown",
            "spreadProjectileSpeed", "sweepProjectileSpeed");
        return new SimpleBossDefinition(
            value.getString("id"),
            value.getFloat("entersAt"),
            value.getInt("coreHealth"),
            value.getInt("podHealth"),
            value.getInt("armHealth"),
            value.getInt("corePoints"),
            value.getInt("podPoints"),
            value.getInt("armPoints"),
            value.getFloat("entranceSpeed"),
            value.getFloat("combatY"),
            value.getFloat("patternCooldown"),
            value.getFloat("spreadProjectileSpeed"),
            value.getFloat("sweepProjectileSpeed"));
    }

    /**
     * Rejects a key {@code value} carries that {@code allowedKeys} does not name. This is the other
     * half of "malformed content fails naming the file and the offending id": {@code core}'s own
     * constructors already reject a missing or invalid field, but nothing before this rejected an
     * unrecognised one — a typo'd or stale key used to load clean and silently do nothing, which for
     * a top-level block like {@code "boss"} means the level loads with no boss and can never be
     * completed, the worst kind of failure because nothing reports it.
     */
    private static void requireOnlyKeys(JsonValue value, String context, String... allowedKeys) {
        Set<String> allowed = new HashSet<>(Arrays.asList(allowedKeys));
        for (JsonValue child = value.child; child != null; child = child.next) {
            if (!allowed.contains(child.name)) {
                throw new IllegalArgumentException(
                    context + " has an unrecognised key '" + child.name + "'");
            }
        }
    }

    /**
     * Runs {@code loader} and, if it throws, rethrows with the file's path prefixed. {@code core}'s
     * own exceptions already name the id or field at fault — see this class's javadoc — so this is
     * the other half the acceptance criterion needs, and the only half {@code game} can supply.
     */
    private static <T> T inFile(FileHandle file, Loader<T> loader) {
        try {
            return loader.load();
        } catch (RuntimeException e) {
            throw new IllegalArgumentException(file.path() + ": " + e.getMessage(), e);
        }
    }

    /**
     * A throwing supplier scoped to this class, so {@link #inFile} does not need
     * {@code java.util.concurrent.Callable} for what is not concurrent code — this project treats
     * that package as TeaVM-hostile territory and avoids it even where a single method would be
     * harmless, per this agent's own memory on the subject.
     */
    @FunctionalInterface
    private interface Loader<T> {
        T load();
    }
}
