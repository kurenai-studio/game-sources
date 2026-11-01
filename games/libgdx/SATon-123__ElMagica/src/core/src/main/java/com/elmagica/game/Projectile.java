package com.elmagica.game;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class Projectile {
    public static final float SPEED = 600f;
    public static final float HALF_SIZE = 6f;
    public final ElementType element;
    public final Vector2 position;
    private final Vector2 velocity;
    private final Vector2 previous = new Vector2();
    private final Array<Enemy> hitEnemies = new Array<>();
    private float age;
    public float getAge() { return age; }

    public Projectile(float x, float y, Vector2 direction, ElementType element) {
        this(x, y, direction, element, SPEED);
    }

    public Projectile(float x, float y, Vector2 direction, ElementType element, float speed) {
        this.element = element;
        position = new Vector2(x, y);
        previous.set(position);
        velocity = new Vector2(direction).nor().scl(speed);
    }

    public void update(float delta) {
        age += delta;
        previous.set(position);
        position.mulAdd(velocity, delta);
    }

    public boolean outsideRoom() {
        return position.x - HALF_SIZE <= ElMagicaGame.TILE_SIZE
            || position.y - HALF_SIZE <= ElMagicaGame.TILE_SIZE
            || position.x + HALF_SIZE >= ElMagicaGame.WORLD_WIDTH - ElMagicaGame.TILE_SIZE
            || position.y + HALF_SIZE >= ElMagicaGame.WORLD_HEIGHT - ElMagicaGame.TILE_SIZE;
    }

    public float hitTime(Enemy enemy) {
        if (!enemy.isAlive() || hasHit(enemy)) return Float.POSITIVE_INFINITY;
        return hitBox(enemy.x, enemy.y, enemy.getSize());
    }

    public float hitTime(Player player) { return player.hitTime(previous.x, previous.y, position.x, position.y, HALF_SIZE); }
    public void markHit(Enemy enemy) { hitEnemies.add(enemy); }
    public boolean hasHit(Enemy enemy) { return hitEnemies.contains(enemy, true); }
    public int getHitCount() { return hitEnemies.size; }
    public Vector2 getDirection() { return new Vector2(velocity).nor(); }
    public Vector2 getPrevious() { return previous; }
    public float obstacleTime(RoomLayout room) { return room == null ? Float.POSITIVE_INFINITY : room.shotTime(previous, position, HALF_SIZE); }
    public void ricochet(Enemy from, Enemy to) {
        position.set(from.x + from.getSize() / 2, from.y + from.getSize() / 2);
        previous.set(position);
        float speed = velocity.len();
        velocity.set(to.x + to.getSize() / 2 - position.x, to.y + to.getSize() / 2 - position.y).nor().scl(speed);
    }

    private float hitBox(float x, float y, float size) {
        // Проверяем весь путь за кадр, иначе быстрый снаряд пролетит сквозь врага.
        float enter = 0;
        float exit = 1;
        for (int axis = 0; axis < 2; axis++) {
            float start = axis == 0 ? previous.x : previous.y;
            float travel = axis == 0 ? position.x - previous.x : position.y - previous.y;
            float min = (axis == 0 ? x : y) - HALF_SIZE;
            float max = min + size + HALF_SIZE * 2;
            if (travel == 0) {
                if (start < min || start > max) return Float.POSITIVE_INFINITY;
            } else {
                float first = (min - start) / travel;
                float last = (max - start) / travel;
                enter = Math.max(enter, Math.min(first, last));
                exit = Math.min(exit, Math.max(first, last));
                if (enter > exit) return Float.POSITIVE_INFINITY;
            }
        }
        return enter;
    }
}
