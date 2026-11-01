package ai.visualdemo.cube;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.VertexAttributes.Usage;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;

public final class CubePuzzleFactory {
    private static final float CUBE = 1f;

    private CubePuzzleFactory() {}

    // Piece A: 13 cubes
    private static final int[][] PIECE_A = {
            {0,0,0},{0,1,0},{0,2,0},
            {0,0,1},{0,1,1},{0,2,1},
            {0,0,2},{0,1,2},{0,2,2},
            {1,0,0},{1,1,0},{1,1,1},{1,2,2}
    };

    // Piece B: remaining 14 cubes in a 3x3x3 cube
    private static final int[][] PIECE_B = {
            {1,0,1},{1,0,2},{1,1,2},{1,2,0},{1,2,1},
            {2,0,0},{2,0,1},{2,0,2},
            {2,1,0},{2,1,1},{2,1,2},
            {2,2,0},{2,2,1},{2,2,2}
    };

    public static Model createPieceA() {
        return createPieceModel(PIECE_A, new Color(0.05f, 0.32f, 0.90f, 1f));
    }

    public static Model createPieceB() {
        return createPieceModel(PIECE_B, new Color(1.0f, 0.42f, 0.05f, 1f));
    }

    public static Model createAssembledCube() {
        ModelBuilder builder = new ModelBuilder();
        builder.begin();

        addCubes(builder, PIECE_A, new Color(0.05f, 0.32f, 0.90f, 1f));
        addCubes(builder, PIECE_B, new Color(1.0f, 0.42f, 0.05f, 1f));

        return builder.end();
    }

    private static Model createPieceModel(int[][] voxels, Color color) {
        ModelBuilder builder = new ModelBuilder();
        builder.begin();
        addCubes(builder, voxels, color);
        return builder.end();
    }

    private static void addCubes(ModelBuilder builder, int[][] voxels, Color color) {
        Material material = new Material(ColorAttribute.createDiffuse(color));

        for (int i = 0; i < voxels.length; i++) {
            float x = voxels[i][0] - 1f;
            float y = voxels[i][1] - 1f;
            float z = voxels[i][2] - 1f;

            builder.node();
            builder.part(
                    "cube_" + i,
                    GL20.GL_TRIANGLES,
                    Usage.Position | Usage.Normal,
                    material
            ).box(
                    x * CUBE,
                    y * CUBE,
                    z * CUBE,
                    CUBE,
                    CUBE,
                    CUBE
            );
        }
    }
}
