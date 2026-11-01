package com.tomer.scoundrel.achievements;

import com.tomer.scoundrel.model.Status;

import java.util.List;

/**
 * The shipped achievement catalog for base Scoundrel. Every rule reads only the
 * {@link AchievementContext}, so achievements observe the game entirely from
 * outside the engine. Thresholds are tuned to the standard ruleset (health cap
 * 20, weapons capped at 10); a variant with a different cap or deck would
 * revisit them. Adding an achievement is a new entry here — nothing else changes.
 */
public final class Achievements {

    private Achievements() {
    }

    private static final int HEALTH_CAP = 20;
    private static final int SEASONED_WINS = 10;
    private static final int MONSTER_HUNTER_KILLS = 1000;
    private static final int GIANT_VALUE = 13;        // King; Ace is 14
    private static final int SPEEDRUN_SECONDS = 80;
    // The mathematical floor: starting health (20) minus the total value of all
    // 26 monsters (2+..+14 = 104 per suit, ×2 = 208). Nothing can score lower.
    private static final int ROCK_BOTTOM_SCORE = -188;

    private static final List<Achievement> CATALOG = List.of(
            new Achievement("first_blood", "First Blood",
                    "Clear the dungeon for the first time.", false,
                    ctx -> ctx.run().outcome() == Status.WON && ctx.totals().wins() == 1),
            new Achievement("seasoned", "Seasoned",
                    "Clear the dungeon ten times.", false,
                    ctx -> ctx.totals().wins() >= SEASONED_WINS),
            new Achievement("monster_hunter", "Monster Hunter",
                    "Defeat a thousand monsters across all your runs.", false,
                    ctx -> ctx.totals().monstersDefeated() >= MONSTER_HUNTER_KILLS),
            new Achievement("giant_slayer", "Giant Slayer",
                    "Slay a King or Ace with your bare hands.", false,
                    ctx -> ctx.run().highestBarehandedKill() >= GIANT_VALUE),
            new Achievement("untarnished", "Untarnished",
                    "Win with your health untouched at the full twenty.", false,
                    ctx -> ctx.run().outcome() == Status.WON && ctx.run().finalHealth() == HEALTH_CAP),
            new Achievement("on_the_brink", "On the Brink",
                    "Win with exactly one health remaining.", false,
                    ctx -> ctx.run().outcome() == Status.WON && ctx.run().finalHealth() == 1),
            new Achievement("flawless_room", "Flawless Room",
                    "Clear a whole room of monsters without taking a scratch.", false,
                    ctx -> ctx.run().flawlessRoom()),
            new Achievement("blademaster", "Blademaster",
                    "Win without slaying a single monster bare-handed.", false,
                    ctx -> ctx.run().outcome() == Status.WON && ctx.run().barehandedKillCount() == 0),
            new Achievement("speedrunner", "Speedrunner",
                    "Clear the dungeon in under eighty seconds.", false,
                    ctx -> ctx.run().outcome() == Status.WON && ctx.run().seconds() < SPEEDRUN_SECONDS),
            new Achievement("rock_bottom", "Rock Bottom",
                    "Fall to the worst score the dungeon can inflict — minus one hundred "
                            + "and eighty-eight.", true,
                    ctx -> ctx.run().outcome() == Status.LOST && ctx.run().score() <= ROCK_BOTTOM_SCORE));

    /**
     * The whole catalog, in the order the trophies screen lists it.
     *
     * @return an unmodifiable list of the shipped achievements
     */
    public static List<Achievement> all() {
        return CATALOG;
    }
}
