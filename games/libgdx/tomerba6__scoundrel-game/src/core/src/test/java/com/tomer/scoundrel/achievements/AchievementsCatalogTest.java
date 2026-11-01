package com.tomer.scoundrel.achievements;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.runs.RunRecord;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static com.tomer.scoundrel.achievements.AchievementsTestData.context;
import static com.tomer.scoundrel.achievements.AchievementsTestData.run;
import static com.tomer.scoundrel.achievements.AchievementsTestData.summary;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The ten achievements and the rule each is earned by. */
class AchievementsCatalogTest {

    private static Achievement byId(String id) {
        return Achievements.all().stream()
                .filter(a -> a.id().equals(id))
                .findFirst()
                .orElseThrow(() -> new AssertionError("no achievement with id " + id));
    }

    private static boolean earns(String id, AchievementContext context) {
        return byId(id).earnedBy(context);
    }

    /** The catalog holds ten achievements, each with a unique id, a title and a description. */
    @Test
    void catalogHasTenAchievementsWithUniqueIdsAndCopy() {
        List<Achievement> all = Achievements.all();
        assertEquals(10, all.size());
        Set<String> ids = new HashSet<>();
        for (Achievement a : all) {
            assertTrue(ids.add(a.id()), "duplicate id " + a.id());
            assertFalse(a.title().isBlank(), a.id() + " has a blank title");
            assertFalse(a.description().isBlank(), a.id() + " has a blank description");
        }
    }

    /** Rock Bottom is the only hidden achievement. */
    @Test
    void onlyRockBottomIsHidden() {
        for (Achievement a : Achievements.all()) {
            assertEquals(a.id().equals("rock_bottom"), a.hidden(), a.id());
        }
    }

    /** First Blood is earned by the first win only: not by a later win, and never by a loss. */
    @Test
    void firstBloodOnTheFirstClearOnly() {
        RunSummary won = summary(Status.WON, 15, 15, 200, 0, 3, false);
        assertTrue(earns("first_blood", context(won, run(Status.WON, 15, 20))));
        // A second win does not re-earn it.
        assertFalse(earns("first_blood",
                context(won, run(Status.WON, 10, 18), run(Status.WON, 15, 20))));
        // A loss never earns it, even with a prior win in the history.
        RunSummary lost = summary(Status.LOST, -30, 0, 100, 0, 1, false);
        assertFalse(earns("first_blood",
                context(lost, run(Status.WON, 10, 18), run(Status.LOST, -30, 5))));
    }

    /** Seasoned is earned at ten wins, not nine, and not by ten losses. */
    @Test
    void seasonedAtTenClears() {
        RunSummary any = summary(Status.WON, 10, 10, 60, 0, 0, false);
        assertTrue(earns("seasoned", context(any, winsOf(10))));
        assertFalse(earns("seasoned", context(any, winsOf(9))));
        // It is ten *clears*, not merely finished runs — ten losses do not count.
        assertFalse(earns("seasoned", context(any, runsOf(10))));
    }

    /** Monster Hunter is earned at a thousand monsters killed across all runs, not 999. */
    @Test
    void monsterHunterAtAThousandLifetimeKills() {
        RunSummary any = summary(Status.WON, 10, 10, 60, 0, 0, false);
        assertTrue(earns("monster_hunter",
                context(any, run(Status.WON, 10, 600), run(Status.LOST, -5, 400))));
        assertFalse(earns("monster_hunter",
                context(any, run(Status.WON, 10, 600), run(Status.LOST, -5, 399))));
    }

    /** Giant Slayer is earned by killing a King or an Ace bare-handed, even in a loss, but not a Queen. */
    @Test
    void giantSlayerForABareHandedKingOrAceEvenInALoss() {
        assertTrue(earns("giant_slayer", context(summary(Status.LOST, -40, 0, 60, 13, 1, false))));
        assertTrue(earns("giant_slayer", context(summary(Status.WON, 5, 5, 60, 14, 2, false))));
        assertFalse(earns("giant_slayer", context(summary(Status.WON, 5, 5, 60, 12, 1, false))));
    }

    /** Untarnished is earned by a win at 20 health, not 19. */
    @Test
    void untarnishedForAFullHealthWin() {
        assertTrue(earns("untarnished", context(summary(Status.WON, 20, 20, 60, 0, 0, false))));
        assertFalse(earns("untarnished", context(summary(Status.WON, 19, 19, 60, 0, 0, false))));
    }

    /** On the Brink is earned by a win at exactly 1 health, not 2. */
    @Test
    void onTheBrinkForAOneHealthWin() {
        assertTrue(earns("on_the_brink", context(summary(Status.WON, 1, 1, 60, 0, 0, false))));
        assertFalse(earns("on_the_brink", context(summary(Status.WON, 2, 2, 60, 0, 0, false))));
    }

    /** Flawless Room is earned by any run with a flawless room, a loss included. */
    @Test
    void flawlessRoomRegardlessOfOutcome() {
        assertTrue(earns("flawless_room", context(summary(Status.LOST, -10, 0, 60, 0, 0, true))));
        assertFalse(earns("flawless_room", context(summary(Status.WON, 10, 10, 60, 0, 0, false))));
    }

    /** Blademaster is earned by a win with no bare-handed kill; one such kill, or a loss, rules it out. */
    @Test
    void blademasterForAWinWithNoBareHandedKills() {
        assertTrue(earns("blademaster", context(summary(Status.WON, 8, 8, 120, 6, 0, false))));
        assertFalse(earns("blademaster", context(summary(Status.WON, 8, 8, 120, 6, 1, false))));
        assertFalse(earns("blademaster", context(summary(Status.LOST, -5, 0, 120, 0, 0, false))));
    }

    /**
     * Speedrunner is earned by a win in under 80 seconds: 79 earns it, and
     * neither 80 nor a fast loss does.
     */
    @Test
    void speedrunnerForAWinStrictlyUnderEightySeconds() {
        assertTrue(earns("speedrunner", context(summary(Status.WON, 10, 10, 79, 0, 0, false))));
        assertFalse(earns("speedrunner", context(summary(Status.WON, 10, 10, 80, 0, 0, false))));
        assertFalse(earns("speedrunner", context(summary(Status.LOST, -5, 0, 10, 0, 0, false))));
    }

    /** Rock Bottom is earned only by the lowest possible score, -188. */
    @Test
    void rockBottomOnlyAtTheAbsoluteFloor() {
        // -188 = 20 starting health - 208 total monster value; nothing can go lower.
        assertTrue(earns("rock_bottom", context(summary(Status.LOST, -188, 0, 60, 0, 0, false))));
        assertFalse(earns("rock_bottom", context(summary(Status.LOST, -187, 0, 60, 0, 0, false))));
        assertFalse(earns("rock_bottom", context(summary(Status.WON, 20, 20, 60, 0, 0, false))));
    }

    private static RunRecord[] runsOf(int count) {
        RunRecord[] runs = new RunRecord[count];
        for (int i = 0; i < count; i++) {
            runs[i] = run(Status.LOST, -5, 3);
        }
        return runs;
    }

    private static RunRecord[] winsOf(int count) {
        RunRecord[] runs = new RunRecord[count];
        for (int i = 0; i < count; i++) {
            runs[i] = run(Status.WON, 10, 3);
        }
        return runs;
    }
}
