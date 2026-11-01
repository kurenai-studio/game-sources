package com.tomer.scoundrel.rules;

/**
 * Factory for the shipped rulesets: base Scoundrel and its difficulty variants.
 * Every variant keeps the standard 4-card-room turn shape and standard deck,
 * differing only in constants or a swapped strategy.
 */
public final class Rulesets {

    private Rulesets() {
    }

    /**
     * Base Scoundrel, exactly as the rules describe it.
     *
     * @return a new ruleset: 20 health and cap, rooms of 4 with 3 resolved, one potion a
     *         turn, the standard avoid rule, scoring and 44-card deck
     */
    public static Ruleset standard() {
        return new Ruleset(20, 20, 4, 3, 1,
                new StandardAvoidRule(), new StandardScoring(), new StandardDeck());
    }

    /**
     * Standard, but avoiding is never legal — every room must be faced.
     *
     * @return a new ruleset identical to {@link #standard()} but for {@link NeverAvoidRule}
     */
    public static Ruleset relentless() {
        return new Ruleset(20, 20, 4, 3, 1,
                new NeverAvoidRule(), new StandardScoring(), new StandardDeck());
    }

    /**
     * Standard rules on a thinner life: starting health and the heal cap are both 14.
     *
     * @return a new ruleset identical to {@link #standard()} but for the two health figures
     */
    public static Ruleset frail() {
        return new Ruleset(14, 14, 4, 3, 1,
                new StandardAvoidRule(), new StandardScoring(), new StandardDeck());
    }
}
