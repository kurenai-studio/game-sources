package dev.luchoc.littlespaceship.core.port;

/**
 * The player's state, read-only, for whoever draws the HUD.
 *
 * <p>A snapshot and not a live wrapper over the domain: every field is copied out of {@code
 * World} the instant {@link WorldView#player()} is called, so nothing returned here can be walked
 * back into a mutable component the way a getter over {@code domain.component.Player} would allow.
 * A record is enough — unlike {@link WorldView} itself, there is no machinery to hide behind an
 * interface, only values, the same reasoning {@link SpriteId} already follows.
 *
 * @param lives lives remaining this run
 * @param bombs bomb charges available
 * @param weaponLevel current weapon upgrade level, base included
 * @param shieldActive whether the shield defensive layer is currently up
 * @param attachmentId the content id of the equipped attachment, or {@code ""} when none is equipped
 * @param invulnerabilitySource why the player currently ignores damage, {@link
 *     InvulnerabilitySource#NONE} when no grace period is active
 * @param invulnerabilityRemaining seconds of grace left, {@code 0} when no grace period is active
 * @param score points accumulated this run
 */
public record PlayerStatus(
    int lives,
    int bombs,
    int weaponLevel,
    boolean shieldActive,
    String attachmentId,
    InvulnerabilitySource invulnerabilitySource,
    float invulnerabilityRemaining,
    int score) {

    /**
     * Fills in the two fields that would otherwise be null: an empty attachment id and {@link
     * InvulnerabilitySource#NONE}, both meaning "not currently the case" rather than "unknown".
     */
    public PlayerStatus {
        if (attachmentId == null) {
            attachmentId = "";
        }
        if (invulnerabilitySource == null) {
            invulnerabilitySource = InvulnerabilitySource.NONE;
        }
    }

    /**
     * The status reported when no entity holds {@code Player} — never the case once a {@code
     * Simulation} has been constructed, since it spawns the player from tick zero, but a bare {@code
     * World} built directly by a test may have none yet.
     */
    public static final PlayerStatus NONE =
        new PlayerStatus(0, 0, 0, false, "", InvulnerabilitySource.NONE, 0f, 0);
}
