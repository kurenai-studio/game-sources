package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;

public final class EnemySpawner {
    public static final float MIN_PLAYER_DISTANCE = 2 * ElMagicaGame.TILE_SIZE;
    private EnemySpawner() {}

    public static boolean spawn(Enemy enemy, Player player, Array<Enemy> enemies) {
        // Сначала собираем свободные клетки, чтобы не крутить рандом вечно.
        Array<Integer> freeCells = new Array<>();
        for (int row = 1; row < ElMagicaGame.GRID_ROWS - 1; row++) {
            for (int column = 1; column < ElMagicaGame.GRID_COLUMNS - 1; column++) {
                float x = column * ElMagicaGame.TILE_SIZE + 2;
                float y = row * ElMagicaGame.TILE_SIZE + 2;
                float size = enemy.getSize();
                if (enemy.room != null && !enemy.room.canStand(x, y, size)) continue;
                if (x + size > ElMagicaGame.WORLD_WIDTH - ElMagicaGame.TILE_SIZE
                    || y + size > ElMagicaGame.WORLD_HEIGHT - ElMagicaGame.TILE_SIZE) continue;
                // Зазор считаем от краёв тел, а не от центров. Для босса тоже.
                float gapX = Math.max(0, Math.max(player.x - x - size, x - player.x - Player.SIZE));
                float gapY = Math.max(0, Math.max(player.y - y - size, y - player.y - Player.SIZE));
                if (gapX * gapX + gapY * gapY < MIN_PLAYER_DISTANCE * MIN_PLAYER_DISTANCE) continue;
                boolean occupied = false;
                for (Enemy other : enemies) {
                    if (other != enemy && other.isAlive()
                        && overlaps(x, y, size, other.x, other.y, other.getSize())) {
                        occupied = true;
                        break;
                    }
                }
                if (!occupied) freeCells.add(row * ElMagicaGame.GRID_COLUMNS + column);
            }
        }
        if (freeCells.isEmpty()) return false;
        int cell = freeCells.get(MathUtils.random(freeCells.size - 1));
        enemy.x = cell % ElMagicaGame.GRID_COLUMNS * ElMagicaGame.TILE_SIZE + 2;
        enemy.y = cell / ElMagicaGame.GRID_COLUMNS * ElMagicaGame.TILE_SIZE + 2;
        enemy.reset();
        return true;
    }

    private static boolean overlaps(float x, float y, float bodySize, float otherX, float otherY, float size) {
        // Оставляем зазор, чтобы мобы не спавнились впритык.
        return x < otherX + size + 32 && x + bodySize + 32 > otherX
            && y < otherY + size + 32 && y + bodySize + 32 > otherY;
    }
}
