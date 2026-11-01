package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * Where the simulation gets the content it does not invent: balance values, enemy definitions,
 * trajectories, formations, waves and level timelines.
 *
 * <p>The core parses nothing. It declares what it needs and the adapter hands it over already
 * built, which is why a test can assemble content by hand without reading a single file and why
 * changing the content format touches no game rule.
 *
 * <p>Every lookup here should fail by naming the id it could not resolve, not by returning null or
 * letting a caller reach a {@code NullPointerException} later. The loader in {@code game} is the
 * only place that also knows the file name, so it wraps whatever this throws with that context.
 */
public interface ContentSource {

    /**
     * @return the balance values for this run, never null
     */
    BalanceValues balance();

    /**
     * @param id the archetype's content id
     * @return the enemy definition, never null
     * @throws IllegalArgumentException if no archetype has that id
     */
    EnemyDefinition enemy(String id);

    /**
     * @param id the trajectory's content id
     * @return the trajectory, never null
     * @throws IllegalArgumentException if no trajectory has that id
     */
    TrajectoryDefinition trajectory(String id);

    /**
     * @param id the formation's content id
     * @return the formation, never null
     * @throws IllegalArgumentException if no formation has that id
     */
    FormationDefinition formation(String id);

    /**
     * The flat, absolute-timestamp shape a level used to be authored in. Retired from the
     * simulation's own read path by issue #112: {@code SpawnSystem} now walks {@link
     * #placements(String)} and {@link #wave(String)} instead, never this. Stays abstract, unlike
     * {@link #wave(String)} and {@link #placements(String)}: both {@code game}'s
     * {@code JsonContentSource} and {@code core}'s own {@code TestContent} already implement it, so
     * defaulting it would only widen where a future {@link ContentSource} can silently resolve
     * nothing, with no implementer it is actually protecting. Deleted outright, along with {@link
     * WaveTimeline} and {@link SimpleWaveTimeline}, once {@code assets/data/level-01.json} migrates
     * to waves (issue #114) and nothing calls this any more.
     *
     * @param levelId the level's content id
     * @return the level's wave timeline, never null
     * @throws IllegalArgumentException if no level has that id
     */
    WaveTimeline timeline(String levelId);

    /**
     * @param id the attachment's content id
     * @return the attachment definition, never null
     * @throws IllegalArgumentException if no attachment has that id
     */
    AttachmentDefinition attachment(String id);

    /**
     * Looked up the same way an {@link #enemy(String)} or a {@link #formation(String)} is, which is
     * what lets the same wave id be placed twice in one level, or once in two different levels,
     * without copying its declaration.
     *
     * @param id the wave's content id
     * @return the wave definition, never null
     * @throws IllegalArgumentException if no wave has that id
     */
    WaveDefinition wave(String id);

    /**
     * A level's ordered sequence of {@link WavePlacement}s — issue #112's replacement for the flat,
     * absolute-timestamp {@link #timeline(String)}. {@code SpawnSystem} resolves each placement's
     * {@link WavePlacement#waveId()} through {@link #wave(String)}, so the same wave id can appear in
     * this list twice, or in two different levels' lists, without copying its declaration.
     *
     * @param levelId the level's content id
     * @return the level's placements, in the order they run, never null or empty
     * @throws IllegalArgumentException if no level has that id
     */
    List<WavePlacement> placements(String levelId);

    /**
     * Tells whether a level has a boss to fight, so {@code Simulation} can decide whether to run
     * {@code BossSystem} at all. A level without a boss is a legitimate case — not every future level
     * needs one — so absence here is not the kind of content bug {@link #boss(String)} itself fails
     * loudly on.
     *
     * @param levelId the level's content id
     * @return true when {@link #boss(String)} would succeed for this level
     */
    boolean hasBoss(String levelId);

    /**
     * @param levelId the level's content id
     * @return the level's boss definition, never null
     * @throws IllegalArgumentException if the level has no boss
     */
    BossDefinition boss(String levelId);
}
