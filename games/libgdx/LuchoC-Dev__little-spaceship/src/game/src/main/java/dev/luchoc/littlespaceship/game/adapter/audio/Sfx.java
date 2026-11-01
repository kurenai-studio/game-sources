package dev.luchoc.littlespaceship.game.adapter.audio;

/**
 * One entry per one-shot sound {@link AudioSystem} can play, matching {@code
 * docs/planning/02-mvp-functional-spec.md}'s list — shots, impacts, explosions, power-ups, the
 * bomb and UI — one category each, not one sound per pickup kind or per enemy archetype. A player
 * hearing six distinct power-up chimes gains nothing a single one does not already give.
 *
 * <p>{@link #EXPLOSION} plays from {@link AudioDirector#emit}, triggered by {@code core}'s {@link
 * dev.luchoc.littlespaceship.core.domain.event.EnemyDestroyed}.
 */
public enum Sfx {

    /** The player's own shot leaving the ship. */
    SHOOT("shoot.wav"),

    /** The player absorbing a hit — by the shield, an attachment, or a life, per {@link
     * dev.luchoc.littlespaceship.core.port.InvulnerabilitySource}'s DAMAGE/RESPAWN transition. */
    IMPACT("impact.wav"),

    /** An enemy destroyed. See the class javadoc: wired but not yet triggered. */
    EXPLOSION("explosion.wav"),

    /** Any of the six pickup kinds {@code PickupSystem} resolves, collected. */
    POWERUP("powerup.wav"),

    /** The bomb triggered. */
    BOMB("bomb.wav"),

    /** A menu entry activated, by mouse click or keyboard. */
    UI_SELECT("ui-select.wav");

    private final String fileName;

    Sfx(String fileName) {
        this.fileName = fileName;
    }

    /** @return the file name under {@code assets/audio/sfx/}, matching {@code GenerateAudio}'s output */
    public String fileName() {
        return fileName;
    }
}
