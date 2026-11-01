package ai.visualdemo.cube;

import java.util.Random;

/**
 * The whole puzzle: two pieces, a selection, a countdown timer, and the win/lose state
 * machine. Nothing in this class touches libGDX graphics or input, so it can be driven and
 * checked from a plain JUnit test with no GL context.
 *
 * Piece A (index 0) is "the upper piece", selected by default; piece B (index 1) is "the lower
 * piece". A piece is correctly oriented exactly when it is back at Orientation.IDENTITY - see
 * TASK-BRIEF.md, since CubePuzzleFactory.createAssembledCube() combines both pieces with no
 * extra rotation at all.
 */
public final class CubePuzzleWorld {

    public static final float START_SECONDS = 60f;
    public static final float ASSEMBLY_SECONDS = 1f;

    private final Random random;

    private final PuzzlePiece pieceA = new PuzzlePiece(0, Orientation.IDENTITY);
    private final PuzzlePiece pieceB = new PuzzlePiece(1, Orientation.IDENTITY);

    private int selectedIndex;
    private float timeRemaining;
    private float assemblingElapsed;
    private GameState state;

    public CubePuzzleWorld() {
        this(new Random());
    }

    public CubePuzzleWorld(Random random) {
        this.random = random;
        reset();
    }

    /** Starts a brand-new challenge: fresh timer, fresh random orientations, piece A selected. */
    public void reset() {
        selectedIndex = 0;
        timeRemaining = START_SECONDS;
        assemblingElapsed = 0f;
        state = GameState.PLAYING;
        pieceA.setOrientation(Orientation.randomNonIdentity(random));
        pieceB.setOrientation(Orientation.randomNonIdentity(random));
    }

    public void update(float delta) {
        switch (state) {
            case PLAYING:
                timeRemaining -= delta;
                if (timeRemaining <= 0f) {
                    timeRemaining = 0f;
                    state = GameState.LOST;
                }
                break;
            case ASSEMBLING:
                assemblingElapsed += delta;
                if (assemblingElapsed >= ASSEMBLY_SECONDS) {
                    assemblingElapsed = ASSEMBLY_SECONDS;
                    state = GameState.WON;
                }
                break;
            case WON:
            case LOST:
                // Frozen until reset() is called.
                break;
        }
    }

    /** Switches which piece the arrow keys affect. A no-op once the round is no longer PLAYING. */
    public void selectNext() {
        if (state != GameState.PLAYING) {
            return;
        }
        selectedIndex = 1 - selectedIndex;
    }

    /** Rotates only the selected piece. A no-op once the round is no longer PLAYING. */
    public void rotateSelected(RotationDirection direction) {
        if (state != GameState.PLAYING) {
            return;
        }
        selectedPiece().rotate(direction);
        if (pieceA.isSolved() && pieceB.isSolved()) {
            state = GameState.ASSEMBLING;
            assemblingElapsed = 0f;
        }
    }

    public PuzzlePiece selectedPiece() {
        return selectedIndex == 0 ? pieceA : pieceB;
    }

    public int getSelectedIndex() {
        return selectedIndex;
    }

    public PuzzlePiece getPieceA() {
        return pieceA;
    }

    public PuzzlePiece getPieceB() {
        return pieceB;
    }

    public GameState getState() {
        return state;
    }

    public float getTimeRemaining() {
        return timeRemaining;
    }

    /** 0 right when the join animation starts, 1 once it has fully played out. */
    public float getAssemblyProgress() {
        return Math.min(1f, assemblingElapsed / ASSEMBLY_SECONDS);
    }

    /**
     * QA-only: jumps straight to a named state without playing through it, so an offscreen
     * capture can grab a specific frame (e.g. the win overlay) deterministically. Never called
     * during normal play - see Lwjgl3Launcher's {@code --scenario} argument.
     */
    public void forceScenarioForQA(String scenario) {
        if (scenario == null) {
            return;
        }
        switch (scenario) {
            case "selectedB":
                selectedIndex = 1;
                break;
            case "assembling":
                pieceA.setOrientation(Orientation.IDENTITY);
                pieceB.setOrientation(Orientation.IDENTITY);
                state = GameState.ASSEMBLING;
                assemblingElapsed = ASSEMBLY_SECONDS * 0.5f;
                break;
            case "won":
                pieceA.setOrientation(Orientation.IDENTITY);
                pieceB.setOrientation(Orientation.IDENTITY);
                state = GameState.WON;
                assemblingElapsed = ASSEMBLY_SECONDS;
                break;
            case "lost":
                state = GameState.LOST;
                timeRemaining = 0f;
                break;
            default:
                break;
        }
    }
}
