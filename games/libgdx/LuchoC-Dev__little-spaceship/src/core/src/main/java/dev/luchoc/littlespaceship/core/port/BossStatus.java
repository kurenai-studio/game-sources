package dev.luchoc.littlespaceship.core.port;

/**
 * The boss's aggregate health, read-only, for the health bar that {@code
 * docs/design/04-hud-layout.md} shows only during the fight.
 *
 * <p>A snapshot, the same reasoning as {@link PlayerStatus}: values copied out the instant {@link
 * WorldView#bossStatus()} is called, nothing here is a live wrapper over a domain component.
 *
 * <p>{@code hp} and {@code hpMax} are the sum across every part — core, both pods, both arms — not
 * the core alone: {@code docs/design/06-boss-presentation.md} draws pods and arms as destructible in
 * their own right, and the bar has to shorten while any of them takes damage, not only the core.
 * {@code hpMax} stays fixed at the boss's starting total for the whole fight; {@code hp} falls both
 * when a part is hit and, at once, when a part dies and stops contributing anything.
 *
 * <p>Per-part detail — which part is charging, how far into its tell — is not here. It travels
 * through the ordinary sprite stream instead: the charging part's own {@code Sprite.frame} steps
 * through the tell's three beats and back to zero on fire, the same channel every other animated
 * entity in the game already uses. A second, parallel channel for exactly one entity would be the
 * kind of machinery this project avoids building without a second consumer to justify it.
 *
 * @param present whether the boss is currently on screen — spawned and not yet defeated — which is
 *     exactly when the health bar should be drawn
 * @param hp current combined hit points across every surviving part
 * @param hpMax the combined hit points the boss started the fight with
 */
public record BossStatus(boolean present, int hp, int hpMax) {

    /** The status reported before the boss has spawned, after it is defeated, or on a boss-less level. */
    public static final BossStatus NONE = new BossStatus(false, 0, 0);
}
