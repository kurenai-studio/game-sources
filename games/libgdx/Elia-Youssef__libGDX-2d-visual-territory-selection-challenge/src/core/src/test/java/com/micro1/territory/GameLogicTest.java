package com.micro1.territory;

import org.junit.Test;

import java.util.Random;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

/** Automated regression coverage run by the standard Gradle test lifecycle. */
public class GameLogicTest {

    private static final float EPSILON = 0.001f;

    @Test
    public void polygonsTileEveryRoundAndHaveTheExpectedUniqueLargestTerritory() {
        String[] expected = {"Blue", "Green", "Yellow", "Green"};
        Round[] rounds = Rounds.build();

        assertEquals(GameLogic.NUM_ROUNDS, rounds.length);
        for (int i = 0; i < rounds.length; i++) {
            Round round = rounds[i];
            assertEquals(expected[i], round.largest().colorName);

            float total = 0f;
            for (Territory territory : round.territories) {
                total += territory.area;
                if (territory != round.largest()) {
                    assertTrue(round.largest().area > territory.area);
                }
            }
            assertEquals(6000f, total, EPSILON);
            assertEquals(round.largest().area / 60f, round.largestPct, EPSILON);
        }
    }

    @Test
    public void hitDetectionHandlesConvexConcaveAndOutsidePoints() {
        Round[] rounds = Rounds.build();

        assertEquals(0, hit(rounds[0], 20f, 10f));
        assertEquals(3, hit(rounds[0], 75f, 45f));
        assertEquals(0, hit(rounds[2], 40f, 20f)); // concave territory 1 upper section
        assertEquals(2, hit(rounds[2], 15f, 50f));
        assertEquals(0, hit(rounds[3], 46f, 27f)); // Round 4, near the real raster junction
        assertEquals(1, hit(rounds[3], 52f, 30f));
        assertEquals(2, hit(rounds[3], 20f, 30f));
        assertEquals(3, hit(rounds[3], 50f, 50f));
        assertEquals(-1, hit(rounds[0], -0.1f, 30f));
        assertEquals(-1, hit(rounds[0], 100.1f, 30f));

        // All four rectangle corners and representative outer-edge points are selectable.
        assertTrue(hit(rounds[0], 0f, 0f) >= 0);
        assertTrue(hit(rounds[0], 100f, 0f) >= 0);
        assertTrue(hit(rounds[0], 0f, 60f) >= 0);
        assertTrue(hit(rounds[0], 100f, 60f) >= 0);
        assertTrue(hit(rounds[0], 0f, 30f) >= 0);
        assertTrue(hit(rounds[0], 50f, 0f) >= 0);
        assertTrue(hit(rounds[0], 100f, 30f) >= 0);
        assertTrue(hit(rounds[0], 50f, 60f) >= 0);
    }

    @Test
    public void inputsArePhaseGatedAndScoringOnlyRunsOnce() {
        GameLogic logic = new GameLogic(new Random(7));

        logic.clickCoord(75f, 45f);
        logic.pressNext();
        assertEquals(GamePhase.START, logic.phase());
        assertEquals(-1, logic.player().selection);

        logic.pressStart();
        logic.pressStart();
        assertEquals(GamePhase.COUNTDOWN, logic.phase());
        logic.update(3f);
        assertEquals(GamePhase.SELECT, logic.phase());

        logic.clickCoord(75f, 45f);
        assertEquals(3, logic.player().selection);
        logic.update(3f);
        assertEquals(GamePhase.RESULT, logic.phase());
        assertEquals(1, logic.player().roundScore);
        assertEquals(1, logic.player().totalScore);

        logic.update(20f);
        logic.pressStart();
        assertEquals(1, logic.player().totalScore);
        assertEquals(GamePhase.RESULT, logic.phase());
    }

    @Test
    public void longFrameConsumesTimerOvershootAcrossBothTimedPhases() {
        GameLogic logic = new GameLogic(new Random(5));
        logic.pressStart();

        logic.update(6f);

        assertEquals(GamePhase.RESULT, logic.phase());
        for (int i = 1; i < logic.competitors().length; i++) {
            assertTrue(logic.competitors()[i].selection >= 0);
            assertTrue(logic.competitors()[i].selection < 4);
        }
    }

    @Test
    public void allCompetitorsCanShareASelectionAndScore() {
        Random alwaysBlue = new Random() {
            @Override
            public int nextInt(int bound) {
                return 3;
            }
        };
        GameLogic logic = new GameLogic(alwaysBlue);
        logic.pressStart();
        logic.update(3f);
        logic.clickCoord(75f, 45f);
        logic.update(3f);

        for (Competitor competitor : logic.competitors()) {
            assertEquals(3, competitor.selection);
            assertEquals(1, competitor.roundScore);
            assertEquals(1, competitor.totalScore);
        }
    }

    @Test
    public void fourRoundsLeadToFinalAndAllTopScoreTiesAreWinners() {
        GameLogic logic = new GameLogic(new Random(9));
        logic.pressStart();
        for (int round = 0; round < GameLogic.NUM_ROUNDS; round++) {
            logic.update(6f);
            assertEquals(GamePhase.RESULT, logic.phase());
            if (round < GameLogic.NUM_ROUNDS - 1) {
                logic.pressNext();
                assertEquals(GamePhase.COUNTDOWN, logic.phase());
            }
        }
        logic.pressNext();
        assertEquals(GamePhase.FINAL, logic.phase());

        logic.debugConfigure(GamePhase.FINAL, 3, values(0), values(0), values(0));
        for (Competitor competitor : logic.competitors()) {
            assertTrue(logic.isWinner(competitor));
        }

        logic.debugConfigure(GamePhase.FINAL, 3, values(0), values(0), new int[]{2, 1, 2, 0});
        assertTrue(logic.isWinner(logic.competitors()[0]));
        assertTrue(logic.isWinner(logic.competitors()[2]));
        assertFalse(logic.isWinner(logic.competitors()[1]));
        assertEquals("You", logic.ranking()[0].name);
        assertEquals("CPU 2", logic.ranking()[1].name);
    }

    private static int hit(Round round, float x, float y) {
        for (Territory territory : round.territories) {
            if (Geometry.contains(territory.polygon, x, y)) {
                return territory.index;
            }
        }
        return -1;
    }

    private static int[] values(int value) {
        return new int[]{value, value, value, value};
    }
}
