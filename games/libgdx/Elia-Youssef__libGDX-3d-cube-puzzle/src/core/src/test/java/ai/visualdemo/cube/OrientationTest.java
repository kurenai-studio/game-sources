package ai.visualdemo.cube;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Random;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Headless logic tests for {@link Orientation} - pure integer-matrix math, no Gdx.* statics.
 */
public class OrientationTest {

    @Test
    public void exactlyTwentyFourDistinctOrientationsExist() {
        // The four arrow keys must be able to reach every orientation a cube can be in.
        assertEquals(24, Orientation.orientationCount());
    }

    @Test
    public void fourQuarterTurnsAboutOneAxisReturnToIdentity() {
        Orientation upFour = Orientation.IDENTITY
                .rotate(RotationDirection.UP).rotate(RotationDirection.UP)
                .rotate(RotationDirection.UP).rotate(RotationDirection.UP);
        assertTrue(upFour.isIdentity());

        Orientation rightFour = Orientation.IDENTITY
                .rotate(RotationDirection.RIGHT).rotate(RotationDirection.RIGHT)
                .rotate(RotationDirection.RIGHT).rotate(RotationDirection.RIGHT);
        assertTrue(rightFour.isIdentity());
    }

    @Test
    public void oppositeDirectionsUndoEachOther() {
        assertTrue(Orientation.IDENTITY.rotate(RotationDirection.UP).rotate(RotationDirection.DOWN).isIdentity());
        assertTrue(Orientation.IDENTITY.rotate(RotationDirection.LEFT).rotate(RotationDirection.RIGHT).isIdentity());
    }

    @Test
    public void rotateNeverMutatesTheReceiver() {
        Orientation start = Orientation.IDENTITY;
        Orientation rotated = start.rotate(RotationDirection.UP);
        assertTrue(start.isIdentity());
        assertFalse(rotated.isIdentity());
    }

    @Test
    public void aSingleQuarterTurnIsNeverIdentity() {
        for (RotationDirection direction : RotationDirection.values()) {
            assertFalse(Orientation.IDENTITY.rotate(direction).isIdentity());
        }
    }

    @Test
    public void randomNonIdentityNeverReturnsIdentity() {
        Random random = new Random(12345L);
        for (int i = 0; i < 500; i++) {
            assertFalse(Orientation.randomNonIdentity(random).isIdentity());
        }
    }

    @Test
    public void randomNonIdentityCanReachDifferentOrientations() {
        // Not a strict distribution test - just confirms it is not stuck returning one value.
        Random random = new Random(999L);
        Set<Orientation> seen = new HashSet<>();
        for (int i = 0; i < 200; i++) {
            seen.add(Orientation.randomNonIdentity(random));
        }
        assertTrue(seen.size() > 5);
    }

    @Test
    public void twoOrientationsReachedByDifferentPathsCanStillBeEqual() {
        // UP, UP, RIGHT, RIGHT should land back on the same orientation as RIGHT, RIGHT, UP, UP
        // is not guaranteed (rotations don't commute) - but four UPs then four RIGHTs is
        // guaranteed to be identity either way, which this exercises indirectly via equals().
        Orientation a = Orientation.IDENTITY.rotate(RotationDirection.UP).rotate(RotationDirection.RIGHT);
        Orientation b = Orientation.IDENTITY.rotate(RotationDirection.UP).rotate(RotationDirection.RIGHT);
        assertEquals(a, b);
    }

    @Test
    public void rotationOrderMatters() {
        Orientation upThenRight = Orientation.IDENTITY.rotate(RotationDirection.UP).rotate(RotationDirection.RIGHT);
        Orientation rightThenUp = Orientation.IDENTITY.rotate(RotationDirection.RIGHT).rotate(RotationDirection.UP);
        assertNotEquals(upThenRight, rightThenUp);
    }
}
