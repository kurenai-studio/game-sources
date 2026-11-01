package ai.visualdemo.cube;

/** One of the two puzzle pieces: which one it is, and its current orientation. */
public final class PuzzlePiece {

    /** 0 = piece A, the "upper" piece selected by default. 1 = piece B, the "lower" piece. */
    public final int index;

    private Orientation orientation;

    public PuzzlePiece(int index, Orientation orientation) {
        this.index = index;
        this.orientation = orientation;
    }

    public Orientation getOrientation() {
        return orientation;
    }

    public void setOrientation(Orientation orientation) {
        this.orientation = orientation;
    }

    public void rotate(RotationDirection direction) {
        orientation = orientation.rotate(direction);
    }

    public boolean isSolved() {
        return orientation.isIdentity();
    }
}
