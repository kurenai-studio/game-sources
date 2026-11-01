package dev.luchoc.littlespaceship.core.port;

/**
 * One entry of an {@link EnemyDefinition}'s component list: a name and a bag of parameters.
 *
 * <p>This is what makes "an enemy is a list of components, not a class" real. The core does not
 * know what a {@code "collider"} or a {@code "motion"} component is — it looks the name up in a
 * registry of factories and hands the factory this generic bag to read. Adding a new component type
 * to the game is one factory registration, never a change to this contract or to whoever parses the
 * JSON.
 *
 * <p>Every accessor is required and typed, and fails loudly, naming the component and the field, on
 * either a missing key or one present with the wrong type. That failure crosses into {@code game}'s
 * loader, which is the only place that also knows the file name — the two together are what the
 * content pipeline needs to point at the exact broken line instead of a
 * {@code NullPointerException} somewhere later.
 *
 * <p>An optional accessor existed for every type once and was removed because nothing called it and a
 * default silently produced the wrong game rule whenever a required field — {@code "fragile"}, for the
 * collider component — was simply omitted from content. {@link #numberOr(String, float)} is the one
 * exception, added back once {@code "firstShotDelay"} on the {@code "weapon"} component gave it a real
 * caller: unlike {@code "fragile"}, an absent {@code "firstShotDelay"} has an unambiguous, currently
 * correct meaning — fall back to the cooldown, the behaviour every archetype already had before this
 * field existed — so a default here preserves old content instead of misreading it.
 */
public interface ComponentSpec {

    /**
     * @return the component name this spec describes, such as {@code "motion"} or {@code "collider"}
     */
    String name();

    /**
     * Reads a required numeric field.
     *
     * @param key the field name
     * @return the value
     * @throws IllegalArgumentException if the field is missing or not numeric
     */
    float number(String key);

    /**
     * Reads an optional numeric field, falling back to {@code defaultValue} only when the key is
     * absent. A key present with the wrong type still fails loudly, the same as {@link #number(String)}
     * — "optional" means the field may be omitted, not that a malformed one is silently ignored.
     *
     * @param key the field name
     * @param defaultValue the value to use when the key is absent
     * @return the value, or {@code defaultValue} if the key is missing
     * @throws IllegalArgumentException if the field is present but not numeric
     */
    float numberOr(String key, float defaultValue);

    /**
     * Reads a required text field.
     *
     * @param key the field name
     * @return the value
     * @throws IllegalArgumentException if the field is missing or empty
     */
    String text(String key);

    /**
     * Reads a required boolean field.
     *
     * @param key the field name
     * @return the value
     * @throws IllegalArgumentException if the field is missing or not a boolean
     */
    boolean flag(String key);
}
