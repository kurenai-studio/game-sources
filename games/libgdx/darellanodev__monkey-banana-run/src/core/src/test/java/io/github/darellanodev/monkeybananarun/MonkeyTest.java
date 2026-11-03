package io.github.darellanodev.monkeybananarun;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class MonkeyTest {
    @Test
    void movingRightIncreasesX() {
        Monkey monkey = new Monkey();
        float initialX = monkey.getX();
        monkey.applyMovement(1f, 1);
        assertTrue(monkey.getX() > initialX);
    }

    @Test
    void noMovementKeepX() {
        Monkey monkey = new Monkey();
        float initialX = monkey.getX();
        monkey.applyMovement(1f, 0);
        assertEquals(monkey.getX(), initialX);
    }

    @Test
    void movingLeftFacesLeft() {
        Monkey monkey = new Monkey();
        monkey.applyMovement(1f, -1);
        assertFalse(monkey.isFacingRight());
    }

    @Test
    void removingLiveWhenHasThreeLivesResultsTwoLives() {
        // note: initial lives are 3
        Monkey monkey = new Monkey();
        monkey.removeLive();
        assertEquals(2, monkey.getLives());
    }

    @Test
    void removingLiveWhenZeroLivesResultZeroLives() {
        // note: initial lives are 3
        Monkey monkey = new Monkey();
        monkey.removeLive();
        monkey.removeLive();
        monkey.removeLive();
        monkey.removeLive();
        assertEquals(0, monkey.getLives());
    }

    @Test
    void hasLivesMethodShouldReturnTrueInitially() {
        // note: initial lives are 3
        Monkey monkey = new Monkey();
        assertTrue(monkey.hasLives());
    }

    @Test
    void hasLivesMethodShouldReturnFalseWhenZeroLives() {
        Monkey monkey = new Monkey();
        monkey.removeLive();
        monkey.removeLive();
        monkey.removeLive();
        assertFalse(monkey.hasLives());
    }
}
