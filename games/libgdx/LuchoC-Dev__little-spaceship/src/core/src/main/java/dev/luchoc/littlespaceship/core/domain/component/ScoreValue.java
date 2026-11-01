package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Points awarded for destroying this entity.
 *
 * <p>Attached by {@code SpawnSystem} from the archetype's {@code "scoreValue"} component spec.
 * Nothing reads it yet — a score system is phase 05's job — but the number has to live somewhere
 * from the moment an enemy is spawned, and content declares it per archetype exactly like
 * {@code 10-mvp-initial-values.md}'s score table does.
 */
public final class ScoreValue {

    /** Points this entity is worth. */
    public int points;

    /**
     * @param points points this entity is worth
     */
    public ScoreValue(int points) {
        this.points = points;
    }
}
