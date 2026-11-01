package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * One finished game, as persisted. Encoded as a single line of tab-separated
 * {@code key=value} pairs, first key {@code v} (the schema version). The
 * parser is deliberately tolerant — unknown keys are ignored, missing
 * counters default to 0, and a line it cannot understand yields empty rather
 * than throwing — so a corrupt or future-version line can never take the
 * game down; adding a field later is just a new key.
 *
 * @param seed             the shuffle seed, or null for a game dealt from an explicit order
 * @param rulesetId        the {@link com.tomer.scoundrel.rules.GameMode#id() mode id} it was
 *                         played in; non-blank, no whitespace
 * @param outcome          {@link Status#WON} or {@link Status#LOST}, never in progress
 * @param score            the final score; zero or negative for a loss
 * @param endedAt          when the game ended, as an instant (UTC in the file)
 * @param seconds          wall-clock seconds from the first deal to the end, 0 or more
 * @param monstersDefeated monsters fought, barehanded or with a weapon
 * @param damageTaken      total health lost to monsters
 * @param healthHealed     total health restored, after the cap
 * @param potionsDrunk     potions that healed (including those that healed 0 at the cap)
 * @param potionsWasted    potions taken past the turn's allowance
 * @param weaponsEquipped  weapons taken
 * @param roomsAvoided     rooms scooped to the bottom of the dungeon
 */
public record RunRecord(
        Long seed,
        String rulesetId,
        Status outcome,
        int score,
        Instant endedAt,
        long seconds,
        int monstersDefeated,
        int damageTaken,
        int healthHealed,
        int potionsDrunk,
        int potionsWasted,
        int weaponsEquipped,
        int roomsAvoided) {

    /** The schema version, written as {@code v}; a line with any other version is skipped. */
    static final int VERSION = 1;

    /**
     * Rejects a record that could not have come from a finished game.
     *
     * @throws IllegalArgumentException if {@code outcome} is not WON or LOST, {@code rulesetId}
     *                                  is null, blank or holds whitespace (it would break the
     *                                  line format), or {@code endedAt} is null
     */
    public RunRecord {
        if (outcome != Status.WON && outcome != Status.LOST) {
            throw new IllegalArgumentException("a recorded run must be WON or LOST, got " + outcome);
        }
        if (rulesetId == null || !rulesetId.matches("\\S+")) {
            throw new IllegalArgumentException("rulesetId must be non-blank without whitespace, got '" + rulesetId + "'");
        }
        if (endedAt == null) {
            throw new IllegalArgumentException("endedAt is required");
        }
    }

    /**
     * The single persisted line (no trailing newline).
     *
     * @return {@code v=1} then one tab-separated {@code key=value} per field; {@code seed} is
     *         left out when null. {@link #parse} reads it back to an equal record.
     */
    public String toLine() {
        StringBuilder sb = new StringBuilder();
        sb.append("v=").append(VERSION);
        if (seed != null) {
            sb.append("\tseed=").append(seed);
        }
        sb.append("\truleset=").append(rulesetId);
        sb.append("\toutcome=").append(outcome.name());
        sb.append("\tscore=").append(score);
        sb.append("\tended=").append(endedAt);
        sb.append("\tseconds=").append(seconds);
        sb.append("\tmonsters=").append(monstersDefeated);
        sb.append("\tdamage=").append(damageTaken);
        sb.append("\thealed=").append(healthHealed);
        sb.append("\tdrunk=").append(potionsDrunk);
        sb.append("\twasted=").append(potionsWasted);
        sb.append("\tequips=").append(weaponsEquipped);
        sb.append("\tavoids=").append(roomsAvoided);
        return sb.toString();
    }

    /**
     * Empty when the line is malformed or from an unknown schema version.
     *
     * @param line one line of the run log, with or without surrounding whitespace
     * @return the record, or empty; never throws, whatever the input
     */
    public static Optional<RunRecord> parse(String line) {
        try {
            Map<String, String> kv = new HashMap<>();
            for (String token : line.trim().split("\t")) {
                int eq = token.indexOf('=');
                if (eq > 0) {
                    kv.put(token.substring(0, eq), token.substring(eq + 1));
                }
            }
            if (Integer.parseInt(kv.get("v")) != VERSION) {
                return Optional.empty();
            }
            String seedText = kv.get("seed");
            return Optional.of(new RunRecord(
                    seedText == null ? null : Long.valueOf(seedText),
                    kv.getOrDefault("ruleset", "unknown"),
                    Status.valueOf(kv.get("outcome")),
                    Integer.parseInt(kv.get("score")),
                    Instant.parse(kv.get("ended")),
                    longOrZero(kv.get("seconds")),
                    intOrZero(kv.get("monsters")),
                    intOrZero(kv.get("damage")),
                    intOrZero(kv.get("healed")),
                    intOrZero(kv.get("drunk")),
                    intOrZero(kv.get("wasted")),
                    intOrZero(kv.get("equips")),
                    intOrZero(kv.get("avoids"))));
        } catch (RuntimeException e) {
            return Optional.empty();
        }
    }

    private static int intOrZero(String value) {
        return value == null ? 0 : Integer.parseInt(value);
    }

    private static long longOrZero(String value) {
        return value == null ? 0 : Long.parseLong(value);
    }
}
