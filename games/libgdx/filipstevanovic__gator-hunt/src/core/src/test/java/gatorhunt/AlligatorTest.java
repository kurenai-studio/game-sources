package gatorhunt;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AlligatorTest {

    @Test
    void movesLeftByItsSpeedEachUpdate() {
        Alligator alligator = new Alligator(100, 50, -5, 30, 140, 80, null);

        alligator.updatePosition(1f);

        assertEquals(95, alligator.x);
        assertEquals(50, alligator.y);
    }

    @Test
    void speedMultiplierScalesTheMove() {
        Alligator alligator = new Alligator(100, 50, -5, 30, 140, 80, null);

        alligator.updatePosition(1.4f);

        assertEquals(93, alligator.x); // 100 + round(-5 * 1.4) = 100 - 7
    }

    @Test
    void keepsThePointsItWasCreatedWith() {
        Alligator alligator = new Alligator(0, 0, -2, 40, 140, 80, null);

        assertEquals(40, alligator.points);
    }

    @Test
    void hasEscapedOnceFullyPastTheLeftEdge() {
        Alligator alligator = new Alligator(-139, 50, -5, 30, 140, 80, null);
        assertFalse(alligator.hasEscapedOffLeftEdge());

        alligator.x = -141;
        assertTrue(alligator.hasEscapedOffLeftEdge());
    }

    @Test
    void containsPointCoversItsFullScaledBounds() {
        Alligator alligator = new Alligator(100, 50, -5, 30, 140, 80, null);

        assertTrue(alligator.containsPoint(100, 50));
        assertTrue(alligator.containsPoint(239, 129));
        assertFalse(alligator.containsPoint(99, 50));
        assertFalse(alligator.containsPoint(240, 50));
        assertFalse(alligator.containsPoint(100, 130));
    }
}
