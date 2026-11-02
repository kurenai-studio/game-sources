package com.bossfight.entities;

import com.badlogic.gdx.math.MathUtils;
import com.bossfight.config.Constants;

public class Projectile {
    private static final float ACORN_OBSTACLE_WIDTH = Constants.BOSS_PROJECTILE_WIDTH + 12f;
    private static final float ACORN_OBSTACLE_HEIGHT = Constants.BOSS_PROJECTILE_HEIGHT + 15f;
    private static final float ACORN_OBSTACLE_GRAVITY = -900f;
    private static final float ACORN_OBSTACLE_LIFETIME = 6.80f;

    public enum Owner {
        PLAYER,
        BOSS
    }

    public enum Kind {
        PLAYER_BASIC,
        PLAYER_SPECIAL,
        BOSS_SEED,
        BOSS_ACORN,
        BOSS_ACORN_OBSTACLE,
        BOSS_POLLEN,
        BOSS_THORN,
        BOSS_PETAL_BOMB,
        BOSS_VINE_WARNING,
        BOSS_IMPACT_WARNING
    }

    private final Owner owner;
    private final Kind kind;
    private final Hitbox hitbox;
    private final float gravity;
    private final float lifetime;
    private final int damage;
    private final boolean removeOnHit;
    private boolean active = true;
    private float x;
    private float y;
    private float velocityX;
    private float velocityY;
    private float age;
    private boolean grounded;

    public static Projectile playerBasic(float x, float y, float velocityX) {
        return new Projectile(Owner.PLAYER, Kind.PLAYER_BASIC, x, y,
                Constants.PLAYER_PROJECTILE_WIDTH, Constants.PLAYER_PROJECTILE_HEIGHT,
                velocityX, 0f, Constants.PLAYER_PROJECTILE_DAMAGE, -1f, 0f, true);
    }

    public static Projectile playerSpecial(float x, float y, float velocityX) {
        return new Projectile(Owner.PLAYER, Kind.PLAYER_SPECIAL, x, y,
                Constants.PLAYER_SPECIAL_WIDTH, Constants.PLAYER_SPECIAL_HEIGHT,
                velocityX, 0f, Constants.PLAYER_SPECIAL_DAMAGE, -1f, 0f, true);
    }

    public static Projectile bossVineWarning(float x, float y, float width, float height, float lifetime) {
        return bossWarning(Kind.BOSS_VINE_WARNING, x, y, width, height, lifetime);
    }

    public static Projectile bossImpactWarning(float x, float y, float width, float height, float lifetime) {
        return bossWarning(Kind.BOSS_IMPACT_WARNING, x, y, width, height, lifetime);
    }

    private static Projectile bossWarning(Kind kind, float x, float y, float width, float height, float lifetime) {
        return new Projectile(Owner.BOSS, kind, x, y, width, height,
                0f, 0f, 0, lifetime, 0f, true);
    }

    public static Projectile bossThorn(float x, float y, float width, float height, float lifetime) {
        return new Projectile(Owner.BOSS, Kind.BOSS_THORN, x, y, width, height,
                0f, 0f, Constants.BOSS_PROJECTILE_DAMAGE, lifetime, 0f, false);
    }

    public static Projectile bossSeed(float x, float y, float width, float height, float velocityX, float velocityY,
                                      float gravity) {
        return bossProjectile(Kind.BOSS_SEED, x, y, width, height, velocityX, velocityY, gravity);
    }

    public static Projectile bossAcorn(float x, float y, float width, float height, float velocityX, float velocityY,
                                       float gravity) {
        return bossProjectile(Kind.BOSS_ACORN, x, y, width, height, velocityX, velocityY, gravity);
    }

    public static Projectile bossAcornObstacle(float originCenterX, float originCenterY,
                                               float landingCenterX, float travelTime) {
        float x = originCenterX - ACORN_OBSTACLE_WIDTH * 0.5f;
        float y = originCenterY - ACORN_OBSTACLE_HEIGHT * 0.5f;
        float velocityX = (landingCenterX - originCenterX) / travelTime;
        float displacementY = Constants.FLOOR_Y - y;
        float velocityY = (displacementY - 0.5f * ACORN_OBSTACLE_GRAVITY * travelTime * travelTime)
                / travelTime;
        return new Projectile(Owner.BOSS, Kind.BOSS_ACORN_OBSTACLE,
                x, y, ACORN_OBSTACLE_WIDTH, ACORN_OBSTACLE_HEIGHT,
                velocityX, velocityY, Constants.BOSS_PROJECTILE_DAMAGE,
                ACORN_OBSTACLE_LIFETIME, ACORN_OBSTACLE_GRAVITY, true);
    }

    public static Projectile bossPollen(float x, float y, float width, float height, float velocityX, float velocityY,
                                        float gravity) {
        return bossProjectile(Kind.BOSS_POLLEN, x, y, width, height, velocityX, velocityY, gravity);
    }

    public static Projectile bossPetalBomb(float x, float y, float width, float height, float velocityX,
                                           float velocityY, float gravity) {
        return bossProjectile(Kind.BOSS_PETAL_BOMB, x, y, width, height, velocityX, velocityY, gravity);
    }

    private static Projectile bossProjectile(Kind kind, float x, float y, float width, float height, float velocityX,
                                             float velocityY, float gravity) {
        return new Projectile(Owner.BOSS, kind, x, y, width, height,
                velocityX, velocityY, Constants.BOSS_PROJECTILE_DAMAGE, -1f, gravity, true);
    }

    private Projectile(Owner owner, Kind kind, float x, float y, float width, float height, float velocityX,
                       float velocityY, int damage, float lifetime, float gravity, boolean removeOnHit) {
        this.owner = owner;
        this.kind = kind;
        this.x = x;
        this.y = y;
        this.velocityX = velocityX;
        this.velocityY = velocityY;
        this.damage = damage;
        this.lifetime = lifetime;
        this.gravity = gravity;
        this.removeOnHit = removeOnHit;
        this.hitbox = new Hitbox(x, y, width, height);
    }

    public void update(float delta) {
        age += delta;
        if (!grounded) {
            velocityY += gravity * delta;
            x += velocityX * delta;
            y += velocityY * delta;
            landObstacleIfNeeded();
        }
        hitbox.setPosition(x, y);

        if (lifetime > 0f && age >= lifetime) {
            active = false;
        }
    }

    private void landObstacleIfNeeded() {
        if (kind != Kind.BOSS_ACORN_OBSTACLE || velocityY >= 0f || y > Constants.FLOOR_Y) {
            return;
        }

        y = Constants.FLOOR_Y;
        velocityX = 0f;
        velocityY = 0f;
        grounded = true;
    }

    public boolean isOutsideWorld() {
        return x < -100f
                || x > Constants.WORLD_WIDTH + 100f
                || y < -100f
                || y > Constants.WORLD_HEIGHT + 100f;
    }

    public boolean isActive() {
        return active;
    }

    public Owner getOwner() {
        return owner;
    }

    public Kind getKind() {
        return kind;
    }

    public Hitbox getHitbox() {
        return hitbox;
    }

    public int getDamage() {
        return damage;
    }

    public boolean isSpecial() {
        return kind == Kind.PLAYER_SPECIAL;
    }

    public boolean shouldRemoveOnHit() {
        return removeOnHit;
    }

    public float getX() {
        return x;
    }

    public float getY() {
        return y;
    }

    public float getCenterX() {
        return x + hitbox.getBounds().width * 0.5f;
    }

    public float getCenterY() {
        return y + hitbox.getBounds().height * 0.5f;
    }

    public float getVelocityX() {
        return velocityX;
    }

    public float getVelocityY() {
        return velocityY;
    }

    public float getWidth() {
        return hitbox.getBounds().width;
    }

    public float getHeight() {
        return hitbox.getBounds().height;
    }

    public float getAge() {
        return age;
    }

    public boolean isGrounded() {
        return grounded;
    }

    public float getWarningProgress() {
        if (lifetime <= 0f) {
            return 0f;
        }
        return MathUtils.clamp(age / lifetime, 0f, 1f);
    }
}
