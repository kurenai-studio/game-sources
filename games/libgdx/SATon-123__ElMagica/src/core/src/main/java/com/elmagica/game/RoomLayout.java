package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.Array;
import java.util.Arrays;

public class RoomLayout {
    public static final int TEMPLATE_COUNT = 15;
    public static final int OBSTACLE_VARIANTS = 8;
    private final boolean[][] blocked = new boolean[30][17];
    private final int[][] obstacleVariants = new int[30][17];
    private final int[][] distance = new int[30][17];
    private final int[] queue = new int[510];
    private int template = -1;
    private final Array<Rectangle> merchantObjects = new Array<>();
    public void addMerchantObjects() {
        merchantObjects.clear();
        merchantObjects.add(new Rectangle(Merchant.X - 52, Merchant.Y - 45, 104, 126));
        for (int i = 0; i < 3; i++) merchantObjects.add(new Rectangle(Merchant.itemX(i) - 37, Merchant.ITEM_Y - 47, 74, 99));
    }
    // Каждая четвёрка — x, y, ширина и высота блока укрытий в клетках.
    private static final int[][] TEMPLATES = {
        {5,4,8,2,17,10,8,2,5,9,2,5,23,3,2,5,9,9,4,2,17,5,4,2},
        {4,3,2,2,8,6,2,2,11,10,2,2,18,4,2,2,22,8,2,2,25,12,2,2},
        {3,5,8,1,19,5,8,1,5,10,7,1,18,10,7,1},
        {7,3,1,8,22,6,1,8,4,12,4,1,23,3,4,1},
        {4,4,3,2,10,4,2,2,18,4,2,2,23,4,3,2,4,10,3,2,10,10,2,2,18,10,2,2,23,10,3,2},
        {5,5,1,4,5,5,5,1,9,5,1,4,20,8,1,4,20,8,5,1,24,8,1,4},
        {3,3,2,2,25,3,2,2,3,12,2,2,25,12,2,2,8,7,2,2,20,7,2,2},
        {4,7,2,3,9,7,2,3,19,7,2,3,24,7,2,3},
        {4,4,4,2,9,9,3,2,18,5,3,2,22,11,4,2},
        {6,3,1,4,10,10,1,4,19,3,1,4,23,10,1,4,4,9,2,1,25,5,2,1},
        {5,3,3,5,5,10,3,4,10,6,3,5,17,6,3,5,22,3,3,5,22,10,3,4},
        {6,3,1,5,4,5,5,1,11,9,1,5,9,11,5,1,18,3,1,5,16,5,5,1,24,9,1,5,22,11,5,1},
        {3,4,8,2,19,4,8,2,7,10,6,2,17,10,6,2,5,8,2,4,24,8,2,4,10,7,3,1,17,7,3,1},
        {4,4,6,1,4,4,1,5,9,4,1,5,20,11,6,1,20,7,1,5,25,7,1,5},
        {4,3,1,1,9,4,1,1,12,7,1,1,7,10,1,1,3,13,1,1,11,13,1,1,18,3,1,1,25,4,1,1,21,7,1,1,18,11,1,1,24,12,1,1,27,9,1,1}
    };

    public RoomLayout() { prepare(-1, false, false); }
    public int getTemplate() { return template; }
    public void generate(boolean boss) {
        prepare(boss || MathUtils.randomBoolean(0.12f) ? -1 : MathUtils.random(TEMPLATE_COUNT - 1),
            MathUtils.randomBoolean(), MathUtils.randomBoolean());
    }
    public void prepare(int index, boolean flipX, boolean flipY) {
        merchantObjects.clear();
        if (index < -1 || index >= TEMPLATE_COUNT) throw new IllegalArgumentException("Unknown room template");
        template = index;
        for (int x = 0; x < 30; x++) {
            for (int y = 0; y < 17; y++) blocked[x][y] = x == 0 || y == 0 || x == 29 || y == 16;
        }
        if (index >= 0) {
            int[] cells = TEMPLATES[index];
            for (int i = 0; i < cells.length; i += 4) {
                for (int x = cells[i]; x < cells[i] + cells[i + 2]; x++) {
                    for (int y = cells[i + 1]; y < cells[i + 1] + cells[i + 3]; y++) {
                        int column = flipX ? 29 - x : x, row = flipY ? 16 - y : y;
                        // Не забиваем центральный проход и площадки у дверей.
                        if (column == 14 || column == 15) continue;
                        if (column >= 12 && column <= 17 && (row <= 3 || row >= 13)) continue;
                        blocked[column][row] = true;
                    }
                }
            }
        }
        if (!isConnected()) {
            // Если шаблон отрезал часть комнаты, лучше оставить этаж пустым.
            prepare(-1, false, false);
            return;
        }
        // Картинку укрытия выбираем один раз, чтобы она не менялась каждый кадр.
        for (int x = 0; x < 30; x++) for (int y = 0; y < 17; y++) {
            obstacleVariants[x][y] = isObstacle(x, y) ? MathUtils.random(OBSTACLE_VARIANTS - 1) : 0;
        }
    }
    public int getObstacleVariant(int x, int y) { return obstacleVariants[x][y]; }
    public boolean isBlocked(int x, int y) { return x < 0 || y < 0 || x >= 30 || y >= 17 || blocked[x][y]; }
    public boolean isObstacle(int x, int y) { return x > 0 && y > 0 && x < 29 && y < 16 && blocked[x][y]; }
    public boolean canStand(float x, float y, float size) {
        for (Rectangle object : merchantObjects) {
            if (x < object.x + object.width && x + size > object.x && y < object.y + object.height && y + size > object.y) return false;
        }
        for (int column = (int) Math.floor(x / 64); column <= (int) Math.floor((x + size - 0.01f) / 64); column++) {
            for (int row = (int) Math.floor(y / 64); row <= (int) Math.floor((y + size - 0.01f) / 64); row++) {
                if (isBlocked(column, row)) return false;
            }
        }
        return true;
    }
    public boolean isConnected() {
        flood(14, 1);
        for (int x = 1; x < 29; x++) {
            for (int y = 1; y < 16; y++) if (!blocked[x][y] && distance[x][y] < 0) return false;
        }
        return distance[14][15] >= 0;
    }
    public void updateNavigation(Player player) {
        flood((int) (player.x + 30) / 64, (int) (player.y + 30) / 64);
    }
    private void flood(int x, int y) {
        for (int[] row : distance) Arrays.fill(row, -1);
        if (isBlocked(x, y)) return;
        int head = 0, tail = 0;
        distance[x][y] = 0;
        queue[tail++] = y * 30 + x;
        while (head < tail) {
            int cell = queue[head++], column = cell % 30, row = cell / 30;
            for (int side = 0; side < 4; side++) {
                int nx = column + (side == 0 ? 1 : side == 1 ? -1 : 0);
                int ny = row + (side == 2 ? 1 : side == 3 ? -1 : 0);
                if (isBlocked(nx, ny) || distance[nx][ny] >= 0) continue;
                distance[nx][ny] = distance[column][row] + 1;
                queue[tail++] = ny * 30 + nx;
            }
        }
    }
    public Vector2 direction(float x, float y, float size, Player player) {
        float dx = player.x + 30 - x - size / 2, dy = player.y + 30 - y - size / 2;
        if (motionTime(x, y, size, dx, dy) >= 1) return new Vector2(dx, dy);
        int column = (int) (x + size / 2) / 64, row = (int) (y + size / 2) / 64;
        int best = distance[column][row], nextX = column, nextY = row;
        for (int side = 0; side < 4; side++) {
            int nx = column + (side == 0 ? 1 : side == 1 ? -1 : 0);
            int ny = row + (side == 2 ? 1 : side == 3 ? -1 : 0);
            if (isBlocked(nx, ny) || distance[nx][ny] < 0) continue;
            if (best < 0 || distance[nx][ny] < best) { best = distance[nx][ny]; nextX = nx; nextY = ny; }
        }
        return new Vector2(nextX * 64 + 32 - x - size / 2, nextY * 64 + 32 - y - size / 2);
    }
    public Vector2 move(float x, float y, float size, float dx, float dy) {
        float nextX = MathUtils.clamp(x + dx, 64, ElMagicaGame.WORLD_WIDTH - 64 - size);
        for (int column = 1; column < 29; column++) for (int row = 1; row < 16; row++) {
            if (!blocked[column][row] || y + size <= row * 64 || y >= row * 64 + 64) continue;
            if (dx > 0 && x + size <= column * 64 && nextX + size > column * 64) nextX = Math.min(nextX, column * 64 - size);
            if (dx < 0 && x >= column * 64 + 64 && nextX < column * 64 + 64) nextX = Math.max(nextX, column * 64 + 64);
        }
        float nextY = MathUtils.clamp(y + dy, 64, ElMagicaGame.WORLD_HEIGHT - 64 - size);
        for (Rectangle object : merchantObjects) {
            if (y + size <= object.y || y >= object.y + object.height) continue;
            if (dx > 0 && x + size <= object.x && nextX + size > object.x) nextX = Math.min(nextX, object.x - size);
            if (dx < 0 && x >= object.x + object.width && nextX < object.x + object.width) nextX = Math.max(nextX, object.x + object.width);
        }
        for (int column = 1; column < 29; column++) for (int row = 1; row < 16; row++) {
            if (!blocked[column][row] || nextX + size <= column * 64 || nextX >= column * 64 + 64) continue;
            if (dy > 0 && y + size <= row * 64 && nextY + size > row * 64) nextY = Math.min(nextY, row * 64 - size);
            if (dy < 0 && y >= row * 64 + 64 && nextY < row * 64 + 64) nextY = Math.max(nextY, row * 64 + 64);
        }
        for (Rectangle object : merchantObjects) {
            if (nextX + size <= object.x || nextX >= object.x + object.width) continue;
            if (dy > 0 && y + size <= object.y && nextY + size > object.y) nextY = Math.min(nextY, object.y - size);
            if (dy < 0 && y >= object.y + object.height && nextY < object.y + object.height) nextY = Math.max(nextY, object.y + object.height);
        }
        return new Vector2(nextX, nextY);
    }
    public float motionTime(float x, float y, float size, float dx, float dy) {
        return segmentTime(x, y, x + dx, y + dy, size, 0);
    }
    public float shotTime(Vector2 from, Vector2 to, float radius) {
        return segmentTime(from.x, from.y, to.x, to.y, radius, radius);
    }
    private float segmentTime(float fromX, float fromY, float toX, float toY, float before, float after) {
        float closest = 1;
        for (Rectangle object : merchantObjects) closest = Math.min(closest, objectHitTime(fromX, fromY, toX, toY, before, after, object));
        for (int x = 0; x < 30; x++) for (int y = 0; y < 17; y++) {
            if (!blocked[x][y]) continue;
            float enter = 0, exit = 1;
            boolean intersects = true;
            for (int axis = 0; axis < 2; axis++) {
                float start = axis == 0 ? fromX : fromY;
                float travel = axis == 0 ? toX - fromX : toY - fromY;
                float min = (axis == 0 ? x : y) * 64 - before + 0.001f;
                float max = (axis == 0 ? x : y) * 64 + 64 + after - 0.001f;
                if (Math.abs(travel) < 0.00001f) {
                    if (start < min || start > max) { intersects = false; break; }
                } else {
                    float a = (min - start) / travel, b = (max - start) / travel;
                    enter = Math.max(enter, Math.min(a, b)); exit = Math.min(exit, Math.max(a, b));
                    if (enter > exit) { intersects = false; break; }
                }
            }
            if (intersects && enter >= 0 && enter <= 1) closest = Math.min(closest, enter);
        }
        return closest;
    }
    private float objectHitTime(float fromX, float fromY, float toX, float toY, float before, float after, Rectangle object) {
        float enter = 0, exit = 1;
        for (int axis = 0; axis < 2; axis++) {
            float start = axis == 0 ? fromX : fromY, travel = axis == 0 ? toX - fromX : toY - fromY;
            float min = (axis == 0 ? object.x : object.y) - before + 0.001f;
            float max = (axis == 0 ? object.x + object.width : object.y + object.height) + after - 0.001f;
            if (Math.abs(travel) < 0.00001f) {
                if (start < min || start > max) return 1;
            } else {
                float a = (min - start) / travel, b = (max - start) / travel;
                enter = Math.max(enter, Math.min(a, b)); exit = Math.min(exit, Math.max(a, b));
                if (enter > exit) return 1;
            }
        }
        return enter;
    }
}
