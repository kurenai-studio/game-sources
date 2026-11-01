package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

public class Enemy {
    public static final int MAX_HP = 30;
    public static final float SIZE = 60f;
    public static final int BOSS_HP = 180;
    public static final float BOSS_SIZE = 124f;
    public static final float SPEED = 120f;
    public static final float JUMP_SPEED = 600f;
    public final ElementType element;
    public final ElementType secondElement;
    private int maxHp;
    private final float size;
    public float x;
    public float y;
    private int hp;
    private boolean jumping;
    private final Vector2 direction = new Vector2();
    private final Vector2 jumpTarget = new Vector2();
    public final BossCombat bossCombat;
    public final ShooterCombat shooterCombat;
    public final SnakeCombat snakeCombat;
    private float animationTime;
    private boolean moving;
    private float slowTimer;
    private float hurtTimer;
    private float slowStrength = 0.5f;
    private float difficulty;
    public RoomLayout room;
    private float pursuitSpeed = SPEED;
    private float touchTimer;

    public Enemy(ElementType element, int column, int row) {
        this(element, null, column, row);
    }

    public Enemy(ElementType element, ElementType secondElement, int column, int row) {
        this(element, secondElement, column, row, false, false);
    }

    public static Enemy shooter(ElementType element, int column, int row) {
        return new Enemy(element, null, column, row, true, false);
    }

    public static Enemy snake(ElementType element, int column, int row) {
        return new Enemy(element, null, column, row, false, true);
    }

    private Enemy(ElementType element, ElementType secondElement, int column, int row, boolean shooter, boolean snake) {
        if (element == secondElement) throw new IllegalArgumentException("Boss elements must differ");
        this.element = element;
        this.secondElement = secondElement;
        if (isBoss()) {
            maxHp = BOSS_HP;
            size = BOSS_SIZE;
        } else {
            maxHp = shooter ? 12 : snake ? 20 : MAX_HP;
            size = SIZE;
        }
        hp = maxHp;
        bossCombat = isBoss() ? new BossCombat(this) : null;
        shooterCombat = shooter ? new ShooterCombat(this) : null;
        snakeCombat = snake ? new SnakeCombat(this) : null;
        x = (column - 1) * ElMagicaGame.TILE_SIZE + 2;
        y = (row - 1) * ElMagicaGame.TILE_SIZE + 2;
    }

    public int getHp() { return hp; }
    public void scaleDifficulty(int stage) {
        scaleDifficulty(stage, 1);
    }
    public void scaleDifficulty(int stage, int floor) {
        // Враги крепнут и от этажей, и от побед над боссами.
        difficulty = stage + Math.max(0, floor - 1) * 0.2f;
        int baseHp = isBoss() ? BOSS_HP : isShooter() ? 12 : isSnake() ? 20 : MAX_HP;
        maxHp = Math.round(baseHp * (1 + difficulty * 0.08f));
        hp = maxHp;
    }
    public float speedScale() { return 1 + Math.min(2, difficulty * 0.03f); }
    public float attackRate() { return 1 + Math.min(2, difficulty * 0.03f); }
    public float rangeScale() { return 1 + Math.min(0.5f, difficulty * 0.02f); }
    public float slowScale() { return isSlowed() ? 1 - slowStrength : 1; }
    public int attackDamage(ElementType attack, ElementType target) {
        return scaleDamage(DamageSystem.damageToPlayer(attack, target));
    }
    public int contactDamage(ElementType target) {
        return scaleDamage(DamageSystem.damageToPlayer(this, target));
    }
    private int scaleDamage(int matchup) {
        int base = isBoss() ? 5 : isShooter() ? 4 : isSnake() ? 3 : 2;
        return Math.max(1, Math.round(matchup / 2f * base * (1 + difficulty * 0.05f)));
    }
    public int getMaxHp() { return maxHp; }
    public float getSize() { return size; }
    public boolean isBoss() { return secondElement != null; }
    public boolean isShooter() { return shooterCombat != null; }
    public boolean isSnake() { return snakeCombat != null; }
    public boolean isSlowed() { return slowTimer > 0; }
    public boolean isEnraged() { return isBoss() && hp <= maxHp / 2; }
    public float getHurtTimer() { return hurtTimer; }
    public String getLabel() {
        if (isBoss()) return getBossName() + " (" + element.label + "+" + secondElement.label + ")";
        if (isShooter()) return "Стрелок: " + element.label;
        if (isSnake()) return "Змея: " + element.label;
        return element.label;
    }
    public String getBossName() {
        boolean fire = element == ElementType.FIRE || secondElement == ElementType.FIRE;
        boolean water = element == ElementType.WATER || secondElement == ElementType.WATER;
        boolean earth = element == ElementType.EARTH || secondElement == ElementType.EARTH;
        if (fire && water) return "Паровой Чан";
        if (fire && earth) return "Лавовый Голем";
        if (fire) return "Огненный Вихрь";
        if (water && earth) return "Болотный Страж";
        if (water) return "Штормовой Дух";
        return "Песчаный Титан";
    }
    public boolean isAlive() { return hp > 0; }

    public void takeDamage(int damage) {
        takeDamage(damage, 10);
    }
    public void takeDamage(int damage, int matchup) {
        if (!isAlive() || damage <= 0) return;
        CombatText.add(Integer.toString(damage), CombatText.damageKind(matchup), x + size / 2, y + size + 42);
        hp = Math.max(0, hp - damage);
        hurtTimer = 0.15f;
        if (!isAlive() && bossCombat != null) bossCombat.clear();
        if (!isAlive() && shooterCombat != null) shooterCombat.clear();
        if (!isAlive() && snakeCombat != null) snakeCombat.clear();
    }

    public void update(float delta, Player player) {
        if (!isAlive() || !player.isAlive()) return;
        animationTime += delta;
        slowTimer = Math.max(0, slowTimer - delta);
        hurtTimer = Math.max(0, hurtTimer - delta);
        touchTimer = Math.max(0, touchTimer - delta);
        moving = false;
        if (snakeCombat != null) {
            float oldX = x, oldY = y;
            snakeCombat.update(delta, player);
            moving = x != oldX || y != oldY;
            return;
        }
        if (bossCombat != null) {
            bossCombat.update(delta, player, jumping);
            if (!player.isAlive() || bossCombat.isBusy()) return;
        }
        if (shooterCombat != null) {
            shooterCombat.update(delta, player, jumping);
            if (!player.isAlive() || shooterCombat.isAiming()) return;
        }
        if (jumping) {
            // На отскоке второй раз не кусаем.
            direction.set(jumpTarget).sub(x, y);
            float distance = direction.len();
            moving = distance > 0;
            float step = JUMP_SPEED * speedScale() * delta;
            if (distance <= step) {
                moveSolid(jumpTarget.x - x, jumpTarget.y - y);
                jumping = false;
            } else {
                direction.scl(step / distance);
                moveSolid(direction.x, direction.y);
            }
            return;
        }
        // На длинном кадре не проскакиваем мимо мага.
        direction.set(player.x + Player.SIZE / 2 - x - size / 2,
            player.y + Player.SIZE / 2 - y - size / 2);
        float distance = direction.len();
        boolean sight = room == null || room.motionTime(x, y, size, direction.x, direction.y) >= 1;
        if (room != null && !sight) direction.set(room.direction(x, y, size, player));
        float speed = SPEED * speedScale() * slowScale();
        if (isBoss()) {
            if (bossCombat.needsApproach(player)) pursuitSpeed = Math.min(Math.max(520, player.speed * 2.2f), pursuitSpeed + 220 * delta);
            else pursuitSpeed = SPEED;
            speed = pursuitSpeed * speedScale() * slowScale();
        }
        if (isShooter()) {
            speed = 90 * speedScale() * slowScale();
            if (sight && distance < 192) direction.scl(-1);
            else if (sight && distance < 320) direction.setZero();
        }
        if (distance > 0 && !direction.isZero()) {
            moving = delta > 0;
            direction.setLength(Math.min(speed * delta, direction.len()));
            if (room == null) { x += direction.x; y += direction.y; }
            else {
                Vector2 position = room.move(x, y, size, direction.x, direction.y);
                x = position.x; y = position.y;
            }
        }
        // Не даём тушке вылезти за карту.
        x = MathUtils.clamp(x, ElMagicaGame.TILE_SIZE, ElMagicaGame.WORLD_WIDTH - ElMagicaGame.TILE_SIZE - size);
        y = MathUtils.clamp(y, ElMagicaGame.TILE_SIZE, ElMagicaGame.WORLD_HEIGHT - ElMagicaGame.TILE_SIZE - size);
        if (touches(player) && touchTimer <= 0) {
            player.takeDamage(contactDamage(player.element), DamageSystem.damageToPlayer(this, player.element));
            touchTimer = 0.8f / attackRate();
            beginJump(player);
        }
    }

    public boolean isJumping() { return jumping; }
    public boolean isMoving() { return moving; }
    public float getAnimationTime() { return animationTime; }
    public void knockBack(Vector2 away, float distance) {
        knockBack(away, distance, 0.5f, 0.6f);
    }
    public void knockBack(Vector2 away, float distance, float strength, float duration) {
        if (isBoss()) distance *= 0.25f;
        moveSolid(away.x * distance, away.y * distance);
        slowTimer = duration;
        slowStrength = strength;
    }

    private void moveSolid(float dx, float dy) {
        float time = room == null ? 1 : room.motionTime(x, y, size, dx, dy);
        x = MathUtils.clamp(x + dx * time, 64, ElMagicaGame.WORLD_WIDTH - 64 - size);
        y = MathUtils.clamp(y + dy * time, 64, ElMagicaGame.WORLD_HEIGHT - 64 - size);
    }

    private boolean touches(Player player) {
        return Float.isFinite(player.hitTime(x + size / 2, y + size / 2, x + size / 2, y + size / 2, size / 2));
    }

    private void beginJump(Player player) {
        direction.set(x + size / 2 - player.x - Player.SIZE / 2,
            y + size / 2 - player.y - Player.SIZE / 2);
        if (direction.isZero(0.001f)) direction.set(1, 0);
        float awayAngle = direction.angleDeg();
        float distance = MathUtils.random(2, 3) * ElMagicaGame.TILE_SIZE;
        float bestAngle = Float.POSITIVE_INFINITY;
        // У стены ищем сторону, куда вообще можно отпрыгнуть.
        for (int angle = -180; angle <= 180; angle += 15) {
            float targetX = x + MathUtils.cosDeg(awayAngle + angle) * distance;
            float targetY = y + MathUtils.sinDeg(awayAngle + angle) * distance;
            if (targetX < ElMagicaGame.TILE_SIZE || targetY < ElMagicaGame.TILE_SIZE
                || targetX + size > ElMagicaGame.WORLD_WIDTH - ElMagicaGame.TILE_SIZE
                || targetY + size > ElMagicaGame.WORLD_HEIGHT - ElMagicaGame.TILE_SIZE) continue;
            if (room != null && room.motionTime(x, y, size, targetX - x, targetY - y) < 1) continue;
            if (Math.abs(angle) < bestAngle) {
                bestAngle = Math.abs(angle);
                jumpTarget.set(targetX, targetY);
            }
        }
        jumping = Float.isFinite(bestAngle);
    }

    public void reset() {
        hp = maxHp;
        jumping = false;
        animationTime = 0;
        moving = false;
        slowTimer = 0;
        hurtTimer = 0;
        touchTimer = 0;
        pursuitSpeed = SPEED;
        if (bossCombat != null) bossCombat.clear();
        if (shooterCombat != null) shooterCombat.clear();
        if (snakeCombat != null) snakeCombat.clear();
    }
}
