package com.micro1.monstercafe;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.EnumSet;
import java.util.Random;
import org.junit.jupiter.api.Test;

/** Headless tests for the scoring / happiness / win / loss / reset / randomness rules. No Gdx.* used. */
class CafeSessionTest {

    private static FoodType wrong(FoodType requested) {
        for (FoodType f : FoodType.values()) {
            if (f != requested) {
                return f;
            }
        }
        throw new IllegalStateException("need at least two food types");
    }

    @Test
    void startsAtZeroScoreFullHappinessPlayingWithAnActiveOrder() {
        CafeSession s = new CafeSession(new Random(1));
        assertEquals(0, s.getScore());
        assertEquals(100, s.getHappiness());
        assertTrue(s.isPlaying());
        assertNotNull(s.getCurrentMonster());
        assertNotNull(s.getRequestedFood());
    }

    @Test
    void correctServeAddsExactlyTenAndKeepsHappiness() {
        CafeSession s = new CafeSession(new Random(2));
        int happinessBefore = s.getHappiness();
        CafeSession.ServeResult r = s.serve(s.getRequestedFood());
        assertEquals(CafeSession.ServeResult.CORRECT, r);
        assertEquals(10, s.getScore());
        assertEquals(happinessBefore, s.getHappiness());
        assertTrue(s.isPlaying());
    }

    @Test
    void wrongServeSubtractsExactlyTwentyAndKeepsScore() {
        CafeSession s = new CafeSession(new Random(3));
        CafeSession.ServeResult r = s.serve(wrong(s.getRequestedFood()));
        assertEquals(CafeSession.ServeResult.WRONG, r);
        assertEquals(80, s.getHappiness());
        assertEquals(0, s.getScore());
        assertTrue(s.isPlaying());
    }

    @Test
    void tenCorrectServesReachExactlyOneHundredAndWin() {
        CafeSession s = new CafeSession(new Random(4));
        for (int i = 0; i < 9; i++) {
            CafeSession.ServeResult r = s.serve(s.getRequestedFood());
            assertEquals(CafeSession.ServeResult.CORRECT, r);
            assertEquals((i + 1) * 10, s.getScore());
            assertTrue(s.isPlaying());
        }
        CafeSession.ServeResult r = s.serve(s.getRequestedFood());
        assertEquals(CafeSession.ServeResult.WIN, r);
        assertEquals(100, s.getScore());
        assertTrue(s.isWon());
        assertFalse(s.isPlaying());
    }

    @Test
    void fiveWrongServesReachZeroHappinessAndLose() {
        CafeSession s = new CafeSession(new Random(5));
        for (int i = 0; i < 4; i++) {
            CafeSession.ServeResult r = s.serve(wrong(s.getRequestedFood()));
            assertEquals(CafeSession.ServeResult.WRONG, r);
            assertEquals(100 - (i + 1) * 20, s.getHappiness());
            assertEquals(0, s.getScore());
            assertTrue(s.isPlaying());
        }
        CafeSession.ServeResult r = s.serve(wrong(s.getRequestedFood()));
        assertEquals(CafeSession.ServeResult.LOSE, r);
        assertEquals(0, s.getHappiness());
        assertTrue(s.isLost());
        assertFalse(s.isPlaying());
    }

    @Test
    void servingIsIgnoredAfterWinningWithNoStateChange() {
        CafeSession s = new CafeSession(new Random(6));
        for (int i = 0; i < 10; i++) {
            s.serve(s.getRequestedFood());
        }
        assertTrue(s.isWon());
        assertEquals(CafeSession.ServeResult.IGNORED, s.serve(s.getRequestedFood()));
        assertEquals(CafeSession.ServeResult.IGNORED, s.serve(wrong(s.getRequestedFood())));
        assertEquals(100, s.getScore());
        assertTrue(s.isWon());
    }

    @Test
    void servingIsIgnoredAfterLosingWithNoStateChange() {
        CafeSession s = new CafeSession(new Random(7));
        for (int i = 0; i < 5; i++) {
            s.serve(wrong(s.getRequestedFood()));
        }
        assertTrue(s.isLost());
        assertEquals(CafeSession.ServeResult.IGNORED, s.serve(wrong(s.getRequestedFood())));
        assertEquals(CafeSession.ServeResult.IGNORED, s.serve(s.getRequestedFood()));
        assertEquals(0, s.getHappiness());
        assertTrue(s.isLost());
    }

    @Test
    void wrongServeKeepsTheSameMonsterAndOrder() {
        CafeSession s = new CafeSession(new Random(8));
        MonsterType monster = s.getCurrentMonster();
        FoodType order = s.getRequestedFood();
        s.serve(wrong(order));
        assertEquals(monster, s.getCurrentMonster());
        assertEquals(order, s.getRequestedFood());
    }

    @Test
    void restartResetsEveryGameplayVariable() {
        CafeSession s = new CafeSession(new Random(9));
        s.serve(wrong(s.getRequestedFood())); // happiness 80
        s.serve(s.getRequestedFood());        // score 10
        s.start();
        assertEquals(0, s.getScore());
        assertEquals(100, s.getHappiness());
        assertTrue(s.isPlaying());
        assertNotNull(s.getCurrentMonster());
        assertNotNull(s.getRequestedFood());
    }

    @Test
    void randomOrdersOnlyUseTheThreeMonstersAndThreeFoodsAndCoverAllOfThem() {
        CafeSession s = new CafeSession(new Random(123));
        EnumSet<MonsterType> monstersSeen = EnumSet.noneOf(MonsterType.class);
        EnumSet<FoodType> foodsSeen = EnumSet.noneOf(FoodType.class);
        for (int i = 0; i < 300; i++) {
            s.start();
            monstersSeen.add(s.getCurrentMonster()); // enum membership is guaranteed; this also guards nextInt bounds
            foodsSeen.add(s.getRequestedFood());
        }
        assertEquals(EnumSet.allOf(MonsterType.class), monstersSeen);
        assertEquals(EnumSet.allOf(FoodType.class), foodsSeen);
    }
}
