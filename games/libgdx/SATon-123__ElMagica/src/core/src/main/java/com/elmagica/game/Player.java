package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

public class Player {
    public static final float SIZE = 60f;
    public static final float SPEED = 200f;
    public static final int MAX_HP = 20;
    public static final float SHOT_COOLDOWN = 0.5f;
    public static final float CAST_TIME = 0.22f;
    public static final float HURT_RADIUS = 20f;
    public boolean floorCleared;
    public float getMoveSpeed() { return speed * (floorCleared ? 1.8f : 1); }

    public float hurtX() { return x + SIZE / 2; }
    public float hurtY() { return y + SIZE / 2; }
    public float hitTime(float fromX, float fromY, float toX, float toY, float padding) {
        // Хитбокс круглый, прозрачные углы спрайта не считаем попаданием.
        float dx = toX - fromX, dy = toY - fromY;
        float ox = fromX - hurtX(), oy = fromY - hurtY();
        float radius = HURT_RADIUS + padding;
        float c = ox * ox + oy * oy - radius * radius;
        if (c <= 0) return 0;
        float a = dx * dx + dy * dy;
        if (a == 0) return Float.POSITIVE_INFINITY;
        float b = ox * dx + oy * dy;
        float discriminant = b * b - a * c;
        if (discriminant < 0) return Float.POSITIVE_INFINITY;
        float time = (-b - (float) Math.sqrt(discriminant)) / a;
        return time >= 0 && time <= 1 ? time : Float.POSITIVE_INFINITY;
    }
    public final ElementType element;
    public float x;
    public float y;
    private final Vector2 movement = new Vector2();
    private int hp = MAX_HP;
    private float shotTimer;
    private float animationTime;
    private float castTimer;
    private float hurtTimer;
    private boolean moving;
    public float aimAngle;
    public float speed = SPEED;
    public int maxHp = MAX_HP;
    public float baseDamage = 10;
    public float attackCooldown = SHOT_COOLDOWN;
    public float projectileSpeed = Projectile.SPEED;
    public float explosionRadius = 48;
    public int ricochets = 1;
    public int piercings = 2;
    public float knockback = 64;
    public float slowStrength = 0.5f;
    public float slowDuration = 0.6f;
    public float dodgeChance;
    private float dodgeTimer;
    public RoomLayout room;

    public Player(ElementType element) {
        this.element = element;
        enterFloor();
    }

    public void enterFloor() {
        floorCleared = false;
        // На новом этаже меняем позицию, ХП и апы сохраняем.
        x = ElMagicaGame.WORLD_WIDTH / 2f - SIZE / 2;
        y = ElMagicaGame.TILE_SIZE + 32;
    }

    public void move(float horizontal, float vertical, float delta) {
        if (!isAlive()) return;
        // Нормализуем, чтобы по диагонали не бегать быстрее.
        movement.set(horizontal, vertical).nor().scl(getMoveSpeed() * delta);
        moving = !movement.isZero();
        if (room != null) {
            Vector2 position = room.move(x, y, SIZE, movement.x, movement.y);
            moving = position.x != x || position.y != y;
            x = position.x; y = position.y;
            return;
        }
        x = MathUtils.clamp(x + movement.x, ElMagicaGame.TILE_SIZE,
            ElMagicaGame.WORLD_WIDTH - ElMagicaGame.TILE_SIZE - SIZE);
        y = MathUtils.clamp(y + movement.y, ElMagicaGame.TILE_SIZE,
            ElMagicaGame.WORLD_HEIGHT - ElMagicaGame.TILE_SIZE - SIZE);
    }

    public int getHp() { return hp; }
    public void updateShooting(float delta) {
        shotTimer = Math.max(0, shotTimer - delta);
        animationTime += delta;
        castTimer = Math.max(0, castTimer - delta);
        hurtTimer = Math.max(0, hurtTimer - delta);
        dodgeTimer = Math.max(0, dodgeTimer - delta);
    }

    public boolean canShoot() {
        return isAlive() && shotTimer <= 0;
    }

    public void shotFired() {
        // Отпускание кнопки не сбрасывает кд. Закликивание не поможет.
        shotTimer = attackCooldown;
        castTimer = CAST_TIME;
        GameAudio.play(GameAudio.Cue.SHOOT);
    }

    public boolean isAlive() { return hp > 0; }
    public boolean isMoving() { return moving; }
    public float getAnimationTime() { return animationTime; }
    public float getCastTimer() { return castTimer; }
    public float getHurtTimer() { return hurtTimer; }
    public float getDodgeTimer() { return dodgeTimer; }
    public void restoreHp() {
        // Хил за босса не должен воскрешать уже мёртвого мага.
        heal(maxHp);
    }
    public void heal(int amount) {
        if (!isAlive()) return;
        int before = hp; hp = Math.min(maxHp, hp + Math.max(0, amount));
        if (hp > before) CombatText.add("+" + (hp - before), CombatText.Kind.HEAL, x + SIZE / 2, y + SIZE + 42);
    }

    public void takeDamage(int damage) {
        takeDamage(damage, 2);
    }
    public void takeDamage(int damage, int matchup) {
        if (!isAlive() || damage <= 0) return;
        if (dodgeChance > 0 && MathUtils.randomBoolean(dodgeChance)) {
            dodgeTimer = 0.4f;
            GameAudio.play(GameAudio.Cue.DODGE);
            CombatText.add("Уклонение", CombatText.Kind.DODGE, x + SIZE / 2, y + SIZE + 42);
            return;
        }
        hp = Math.max(0, hp - damage);
        CombatText.add(Integer.toString(damage), CombatText.damageKind(matchup), x + SIZE / 2, y + SIZE + 42);
        GameAudio.play(hp == 0 ? GameAudio.Cue.DEATH : GameAudio.Cue.HURT);
        hurtTimer = 0.18f;
    }

    public int targetLimit(ElementType spell) {
        if (spell == ElementType.WATER) return piercings;
        if (spell == ElementType.AIR) return ricochets + 1;
        return 1;
    }
}
