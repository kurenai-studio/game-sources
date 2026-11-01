package ai.visualdemo.cube;

import com.badlogic.gdx.math.Matrix4;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Queue;
import java.util.Random;
import java.util.Set;

/**
 * One of the 24 distinct orientations a cube can be rotated into, stored as an exact
 * row-major 3x3 rotation matrix (every entry is -1, 0, or 1). Composing rotations with plain
 * integer matrix multiplication - instead of floats or quaternions - means the state never
 * drifts, so checking "is this piece back in its correct orientation?" is a simple equality
 * check rather than an epsilon comparison.
 */
public final class Orientation {

    /** The un-rotated state. Also the "solved" state for both puzzle pieces - see TASK-BRIEF.md. */
    public static final Orientation IDENTITY = new Orientation(new int[] {
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
    });

    // A 90-degree turn about the X axis and about the Y axis. Any two of a cube's three
    // face-rotation generators produce the full 24-element rotation group, so these two are
    // enough to reach every orientation - confirmed by OrientationTest, not just assumed.
    private static final int[] ROTATE_X_POSITIVE = {
            1, 0, 0,
            0, 0, -1,
            0, 1, 0
    };
    private static final int[] ROTATE_X_NEGATIVE = {
            1, 0, 0,
            0, 0, 1,
            0, -1, 0
    };
    private static final int[] ROTATE_Y_POSITIVE = {
            0, 0, 1,
            0, 1, 0,
            -1, 0, 0
    };
    private static final int[] ROTATE_Y_NEGATIVE = {
            0, 0, -1,
            0, 1, 0,
            1, 0, 0
    };

    /** All 24 reachable orientations, computed once by exploring outward from IDENTITY. */
    private static final List<Orientation> ALL_ORIENTATIONS = buildAllOrientations();

    private final int[] matrix;

    private Orientation(int[] matrix) {
        this.matrix = matrix;
    }

    public boolean isIdentity() {
        return equals(IDENTITY);
    }

    /** Returns a new orientation, one 90-degree step further than this one. Never mutates this one. */
    public Orientation rotate(RotationDirection direction) {
        int[] generator;
        switch (direction) {
            case UP:
                generator = ROTATE_X_POSITIVE;
                break;
            case DOWN:
                generator = ROTATE_X_NEGATIVE;
                break;
            case LEFT:
                generator = ROTATE_Y_NEGATIVE;
                break;
            case RIGHT:
                generator = ROTATE_Y_POSITIVE;
                break;
            default:
                throw new IllegalArgumentException("Unknown direction: " + direction);
        }
        return new Orientation(multiply(generator, matrix));
    }

    /** Writes this orientation's rotation into the top-left 3x3 block of a libGDX matrix. */
    public void applyRotation(Matrix4 target) {
        float[] val = target.val;
        val[Matrix4.M00] = matrix[0];
        val[Matrix4.M01] = matrix[1];
        val[Matrix4.M02] = matrix[2];
        val[Matrix4.M10] = matrix[3];
        val[Matrix4.M11] = matrix[4];
        val[Matrix4.M12] = matrix[5];
        val[Matrix4.M20] = matrix[6];
        val[Matrix4.M21] = matrix[7];
        val[Matrix4.M22] = matrix[8];
    }

    /** Picks a uniformly random orientation that is NOT the solved one - used to start a fresh puzzle. */
    public static Orientation randomNonIdentity(Random random) {
        Orientation choice;
        do {
            choice = ALL_ORIENTATIONS.get(random.nextInt(ALL_ORIENTATIONS.size()));
        } while (choice.isIdentity());
        return choice;
    }

    /** How many distinct orientations exist - should always be 24 for a cube. */
    public static int orientationCount() {
        return ALL_ORIENTATIONS.size();
    }

    private static List<Orientation> buildAllOrientations() {
        Set<Orientation> found = new LinkedHashSet<Orientation>();
        Queue<Orientation> pending = new ArrayDeque<Orientation>();
        found.add(IDENTITY);
        pending.add(IDENTITY);

        while (!pending.isEmpty()) {
            Orientation current = pending.poll();
            for (RotationDirection direction : RotationDirection.values()) {
                Orientation next = current.rotate(direction);
                if (found.add(next)) {
                    pending.add(next);
                }
            }
        }
        return Collections.unmodifiableList(new ArrayList<Orientation>(found));
    }

    private static int[] multiply(int[] a, int[] b) {
        int[] result = new int[9];
        for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
                int sum = 0;
                for (int k = 0; k < 3; k++) {
                    sum += a[row * 3 + k] * b[k * 3 + col];
                }
                result[row * 3 + col] = sum;
            }
        }
        return result;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof Orientation)) {
            return false;
        }
        return Arrays.equals(matrix, ((Orientation) other).matrix);
    }

    @Override
    public int hashCode() {
        return Arrays.hashCode(matrix);
    }
}
