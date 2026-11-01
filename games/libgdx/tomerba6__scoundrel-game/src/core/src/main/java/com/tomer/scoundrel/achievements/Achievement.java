package com.tomer.scoundrel.achievements;

import java.util.function.Predicate;

/**
 * One achievement, authored in code as data: a stable {@code id} (the
 * persistence key), a player-facing {@code title} and {@code description},
 * whether it stays {@code hidden} until earned, and the {@code rule} that
 * decides — from a finished run and the full history — whether it is now
 * earned. New achievements are new entries in {@link Achievements}, with no
 * engine changes; the shape mirrors the data-driven card definitions.
 *
 * @param id          lowercase snake case, stable across releases; the key the unlock is
 *                    persisted under, so renaming one relocks it
 * @param title       the name shown on the trophies screen and the run-end panel
 * @param description one sentence saying what earns it
 * @param hidden      true to show it as {@code ???} on the trophies screen until earned
 * @param rule        decides, from a finished run and the history, whether it is earned;
 *                    must be pure and must not throw
 */
public record Achievement(String id, String title, String description, boolean hidden,
                          Predicate<AchievementContext> rule) {

    /**
     * Runs this achievement's rule.
     *
     * @param context the just-finished run and the history including it
     * @return whether the run (or the history it completes) earns this achievement
     */
    public boolean earnedBy(AchievementContext context) {
        return rule.test(context);
    }
}
