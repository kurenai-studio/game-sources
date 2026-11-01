package dev.luchoc.littlespaceship.core.domain.component;

/**
 * The player's firing state: how long until the next volley is allowed.
 *
 * <p>Shot level itself lives on {@link Player}, not here, because it survives a death exactly like
 * any other persistent power-up and {@link Player} is already where that kind of state lives.
 * {@code cooldownRemaining} is different: it is a per-tick timer with nothing to persist across a
 * death, so it earns its own component instead of crowding {@link Player} with a field only
 * {@code WeaponSystem} reads.
 */
public final class Weapon {

    /** Seconds left before the next volley can fire. Never negative once decayed. */
    public float cooldownRemaining;

    /**
     * Creates a weapon ready to fire immediately.
     */
    public Weapon() {
        this(0f);
    }

    /**
     * @param cooldownRemaining seconds left before the next volley can fire
     */
    public Weapon(float cooldownRemaining) {
        this.cooldownRemaining = cooldownRemaining;
    }
}
