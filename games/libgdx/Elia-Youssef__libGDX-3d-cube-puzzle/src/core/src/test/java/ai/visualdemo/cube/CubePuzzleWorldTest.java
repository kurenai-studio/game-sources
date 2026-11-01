package ai.visualdemo.cube;

import org.junit.jupiter.api.Test;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Random;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Headless logic tests for {@link CubePuzzleWorld} - no Gdx.* statics, no live window required.
 */
public class CubePuzzleWorldTest {

    @Test
    public void freshWorldStartsInTheSpecifiedInitialState() {
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(1L));

        assertEquals(GameState.PLAYING, world.getState());
        assertEquals(0, world.getSelectedIndex());
        assertEquals(CubePuzzleWorld.START_SECONDS, world.getTimeRemaining(), 0.001f);
        assertFalse(world.getPieceA().isSolved());
        assertFalse(world.getPieceB().isSolved());
    }

    @Test
    public void resetAlwaysProducesBothPiecesIncorrect() {
        // Rerolled many times with different seeds to guard against a rare unlucky draw.
        for (long seed = 0; seed < 200; seed++) {
            CubePuzzleWorld world = new CubePuzzleWorld(new Random(seed));
            world.reset();
            assertFalse(world.getPieceA().isSolved(), "piece A started solved with seed " + seed);
            assertFalse(world.getPieceB().isSolved(), "piece B started solved with seed " + seed);
        }
    }

    @Test
    public void rotatingOnlyAffectsTheSelectedPiece() {
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(2L));
        Orientation pieceBBefore = world.getPieceB().getOrientation();

        world.rotateSelected(RotationDirection.UP);

        assertEquals(pieceBBefore, world.getPieceB().getOrientation());
    }

    @Test
    public void tabTogglesSelectionBackAndForth() {
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(3L));
        assertEquals(0, world.getSelectedIndex());

        world.selectNext();
        assertEquals(1, world.getSelectedIndex());

        world.selectNext();
        assertEquals(0, world.getSelectedIndex());
    }

    @Test
    public void matchOnlyFiresWhenBothPiecesAreSimultaneouslyCorrect() {
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(4L));

        // Drive piece A directly to IDENTITY via whatever inverse rotation undoes its start.
        solvePiece(world, world.getPieceA());
        assertEquals(GameState.PLAYING, world.getState(), "should not win with only one piece correct");

        world.selectNext(); // now piece B is selected
        solvePiece(world, world.getPieceB());
        assertEquals(GameState.ASSEMBLING, world.getState(), "both pieces correct should start the join animation");
    }

    @Test
    public void assemblingAdvancesIntoWonAfterTheAnimationDuration() {
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(5L));
        solvePiece(world, world.getPieceA());
        world.selectNext();
        solvePiece(world, world.getPieceB());
        assertEquals(GameState.ASSEMBLING, world.getState());

        world.update(CubePuzzleWorld.ASSEMBLY_SECONDS / 2f);
        assertEquals(GameState.ASSEMBLING, world.getState(), "should not finish early");

        world.update(CubePuzzleWorld.ASSEMBLY_SECONDS);
        assertEquals(GameState.WON, world.getState());
    }

    @Test
    public void timerRunningOutEndsTheGameWithoutTouchingOrientations() {
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(6L));
        Orientation pieceABefore = world.getPieceA().getOrientation();
        Orientation pieceBBefore = world.getPieceB().getOrientation();

        world.update(CubePuzzleWorld.START_SECONDS + 1f);

        assertEquals(GameState.LOST, world.getState());
        assertEquals(0f, world.getTimeRemaining(), 0.001f);
        assertEquals(pieceABefore, world.getPieceA().getOrientation());
        assertEquals(pieceBBefore, world.getPieceB().getOrientation());
    }

    @Test
    public void inputIsFrozenOnceTheRoundIsOver() {
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(7L));
        world.update(CubePuzzleWorld.START_SECONDS + 1f);
        assertEquals(GameState.LOST, world.getState());

        Orientation pieceABefore = world.getPieceA().getOrientation();
        world.rotateSelected(RotationDirection.UP);
        world.selectNext();

        assertEquals(pieceABefore, world.getPieceA().getOrientation(), "rotation should be a no-op once LOST");
        assertEquals(0, world.getSelectedIndex(), "selection should be a no-op once LOST");
    }

    @Test
    public void resetWorksFromEveryState() {
        // From PLAYING (mid-game).
        CubePuzzleWorld world = new CubePuzzleWorld(new Random(8L));
        world.rotateSelected(RotationDirection.UP);
        world.reset();
        assertFreshState(world);

        // From ASSEMBLING.
        solvePiece(world, world.getPieceA());
        world.selectNext();
        solvePiece(world, world.getPieceB());
        assertEquals(GameState.ASSEMBLING, world.getState());
        world.reset();
        assertFreshState(world);

        // From WON.
        solvePiece(world, world.getPieceA());
        world.selectNext();
        solvePiece(world, world.getPieceB());
        world.update(CubePuzzleWorld.ASSEMBLY_SECONDS + 1f);
        assertEquals(GameState.WON, world.getState());
        world.reset();
        assertFreshState(world);

        // From LOST.
        world.update(CubePuzzleWorld.START_SECONDS + 1f);
        assertEquals(GameState.LOST, world.getState());
        world.reset();
        assertFreshState(world);
    }

    private static void assertFreshState(CubePuzzleWorld world) {
        assertEquals(GameState.PLAYING, world.getState());
        assertEquals(0, world.getSelectedIndex());
        assertEquals(CubePuzzleWorld.START_SECONDS, world.getTimeRemaining(), 0.001f);
    }

    /**
     * Rotates the given piece back to IDENTITY via real {@code rotateSelected} calls, however
     * many quarter-turns that takes. 3D rotations don't commute, so an arbitrary starting
     * orientation is not, in general, reachable by repeating a single direction (that only
     * cycles through that one generator's own subgroup) - the solving sequence is found with a
     * breadth-first search over Orientation itself, then replayed as real input.
     */
    private static void solvePiece(CubePuzzleWorld world, PuzzlePiece piece) {
        for (RotationDirection direction : findSolvingSequence(piece.getOrientation())) {
            world.rotateSelected(direction);
        }
    }

    private static List<RotationDirection> findSolvingSequence(Orientation start) {
        if (start.isIdentity()) {
            return Collections.emptyList();
        }
        Map<Orientation, Orientation> parent = new HashMap<>();
        Map<Orientation, RotationDirection> stepTaken = new HashMap<>();
        Set<Orientation> visited = new HashSet<>();
        Queue<Orientation> queue = new ArrayDeque<>();
        visited.add(start);
        queue.add(start);

        while (!queue.isEmpty()) {
            Orientation current = queue.poll();
            for (RotationDirection direction : RotationDirection.values()) {
                Orientation next = current.rotate(direction);
                if (!visited.add(next)) {
                    continue;
                }
                parent.put(next, current);
                stepTaken.put(next, direction);
                if (next.isIdentity()) {
                    return reconstructPath(next, start, parent, stepTaken);
                }
                queue.add(next);
            }
        }
        throw new IllegalStateException("no solving sequence found - the rotation group closure is broken");
    }

    private static List<RotationDirection> reconstructPath(Orientation target, Orientation start,
            Map<Orientation, Orientation> parent, Map<Orientation, RotationDirection> stepTaken) {
        List<RotationDirection> reversed = new ArrayList<>();
        Orientation walk = target;
        while (!walk.equals(start)) {
            reversed.add(stepTaken.get(walk));
            walk = parent.get(walk);
        }
        Collections.reverse(reversed);
        return reversed;
    }
}
