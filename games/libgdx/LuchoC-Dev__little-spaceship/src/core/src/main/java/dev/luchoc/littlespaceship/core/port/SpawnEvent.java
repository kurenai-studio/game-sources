package dev.luchoc.littlespaceship.core.port;

/**
 * One timestamped spawn — the intensity curve in executable form. Used two ways today: as an entry
 * of the legacy, flat {@link WaveTimeline} ({@code at} since the level started), and as an entry of
 * a {@link WaveDefinition}'s {@link WaveDefinition#spawns()} ({@code at} since the wave itself
 * started). This type only ever means "a timestamped spawn" — which timeline's zero point {@code at}
 * counts from is entirely up to the container holding it, never to this record.
 *
 * @param at seconds since the start of whichever timeline this event belongs to, when this wave spawns
 * @param enemyId the {@link EnemyDefinition} to spawn
 * @param formationId the {@link FormationDefinition} that lays it out
 * @param atX the anchor's horizontal position, a fraction of the playfield width in {@code [0, 1]},
 *     0 at the left edge and 1 at the right
 * @param dropId the pickup this specific wave instance delivers, or {@code null}/empty for none —
 *     a designed drop is a property of the event, never of the archetype, per
 *     {@code 03-game-systems.md}
 * @param dropSlot which slot of the formation carries {@code dropId}, meaningless when {@link
 *     #hasDrop()} is false. Confirmed in {@code 08-decisions-and-open-items.md}, issue #23: a
 *     designed drop belongs to one specific enemy of a wave, never to every slot of its formation —
 *     a three-carrier wave with a drop hands out exactly one attachment, not three.
 * @param trajectoryId the {@link TrajectoryDefinition} this specific spawn follows, overriding the
 *     archetype's own default, or {@code null}/empty to use it unchanged — the binding
 *     {@code docs/plan/11c-movement-shapes/plan.md} decided on 27/08/2026: "the shape is chosen in
 *     the spawn event, with the archetype supplying the default". Not validated against
 *     {@code ContentSource} here, the same reason {@code enemyId} and {@code formationId} are not
 *     either — resolving it is {@code SpawnSystem}'s job, against content this record cannot see.
 */
public record SpawnEvent(
    float at, String enemyId, String formationId, float atX, String dropId, int dropSlot,
    String trajectoryId) {

    /**
     * Rejects a malformed event: a negative timestamp, a missing archetype or formation, an anchor
     * outside the playfield, or a negative slot index. Whether {@code dropSlot} actually names a
     * slot that exists is checked by {@code SpawnSystem}, against the formation it resolves — this
     * constructor has no access to that formation's slot count. Same for {@code trajectoryId}: an
     * unrecognised id fails once {@code SpawnSystem} resolves it against {@code ContentSource}, not
     * here.
     */
    public SpawnEvent {
        if (at < 0f || Float.isNaN(at) || Float.isInfinite(at)) {
            throw new IllegalArgumentException("a spawn event needs a finite, non-negative timestamp");
        }
        if (enemyId == null || enemyId.isEmpty()) {
            throw new IllegalArgumentException("a spawn event at " + at + "s needs an enemy id");
        }
        if (formationId == null || formationId.isEmpty()) {
            throw new IllegalArgumentException("a spawn event at " + at + "s needs a formation id");
        }
        if (atX < 0f || atX > 1f || Float.isNaN(atX)) {
            throw new IllegalArgumentException(
                "spawn event at " + at + "s has atX " + atX + ", outside [0, 1]");
        }
        if (dropSlot < 0) {
            throw new IllegalArgumentException(
                "spawn event at " + at + "s has a negative dropSlot " + dropSlot);
        }
    }

    /**
     * Convenience for the common case — a formation with only one slot, or a drop meant for its
     * first one — equivalent to {@code dropSlot} 0 and no trajectory override.
     *
     * @param at seconds since the level started, when this wave spawns
     * @param enemyId the {@link EnemyDefinition} to spawn
     * @param formationId the {@link FormationDefinition} that lays it out
     * @param atX the anchor's horizontal position
     * @param dropId the pickup this specific wave instance delivers, or {@code null}/empty for none
     */
    public SpawnEvent(float at, String enemyId, String formationId, float atX, String dropId) {
        this(at, enemyId, formationId, atX, dropId, 0, null);
    }

    /**
     * Convenience for a designed drop, without a trajectory override — the six-argument shape this
     * type had before {@code trajectoryId} was added, kept so every existing call site (across
     * {@code core}'s tests and {@code game}'s content loader) keeps compiling unchanged.
     *
     * @param at seconds since the level started, when this wave spawns
     * @param enemyId the {@link EnemyDefinition} to spawn
     * @param formationId the {@link FormationDefinition} that lays it out
     * @param atX the anchor's horizontal position
     * @param dropId the pickup this specific wave instance delivers, or {@code null}/empty for none
     * @param dropSlot which slot of the formation carries {@code dropId}
     */
    public SpawnEvent(float at, String enemyId, String formationId, float atX, String dropId, int dropSlot) {
        this(at, enemyId, formationId, atX, dropId, dropSlot, null);
    }

    /**
     * @return true when this instance is marked to drop something on defeat
     */
    public boolean hasDrop() {
        return dropId != null && !dropId.isEmpty();
    }

    /**
     * @return true when this instance overrides the archetype's own default movement shape
     */
    public boolean hasTrajectoryOverride() {
        return trajectoryId != null && !trajectoryId.isEmpty();
    }
}
