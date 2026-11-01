package com.tomer.scoundrel.rules;

/**
 * A selectable difficulty: a stable {@code id} (persisted as the run's
 * {@code rulesetId}), player-facing text for the menu, the {@link Ruleset} it
 * plays with, and whether runs in it count toward achievements. Pure data — the
 * catalog of shipped modes is {@link GameModes}.
 *
 * @param id                 lowercase, no whitespace, and stable across releases: it is
 *                           written into every run record, so a renamed id leaves the old
 *                           runs under the old one (the ledger shows an unknown id raw)
 * @param title              the mode's name on the mode picker and the ledger
 * @param description        the mode picker's one-line summary, drawn upper-cased and
 *                           unwrapped, so it has to fit the panel as written
 * @param ruleset            the rules a run in this mode is played with
 * @param tracksAchievements whether a run in this mode can unlock achievements
 */
public record GameMode(
        String id,
        String title,
        String description,
        Ruleset ruleset,
        boolean tracksAchievements) {
}
