package dev.meowpow.boxbot.engine.spatial.grid;

public final class GridFixtures {

    private GridFixtures() {}

    public static GridPos origin() {
        return new GridPos(0, 0);
    }

    static Grid gridOf(String... rows) {
        int height = rows.length;
        int width = rows[0].length();
        var grid = new Grid(width, height);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                grid.setWalkable(x, y, rows[y].charAt(x) == '.');
            }
        }
        return grid;
    }
}
