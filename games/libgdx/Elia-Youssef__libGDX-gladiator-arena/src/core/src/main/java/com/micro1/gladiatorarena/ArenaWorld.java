package com.micro1.gladiatorarena;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.RandomXS128;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.Array;

/**
 * All arena-combat simulation and game-state rules, with no libGDX graphics/input dependency
 * (only pure math + collection types), so it can be exercised headlessly. {@code GameplayScreen}
 * is a thin render/input shell over this.
 *
 * Coordinate space: top-left origin, x right, y down. Entity-vs-entity collisions use AABB boxes
 * (Rectangle.overlaps); the arena boundary is the circle centred at (640,380) radius 320. All
 * timing is delta-time driven. The simulation splits into small package-visible steps
 * (movePlayer / advanceWaves / updateProjectiles / updateEnemies / checkEndConditions) so each
 * rule can be unit-tested in isolation and no update method issues a draw call.
 */
public class ArenaWorld {

    public enum State { PLAYING, WON, LOST }

    public static final float WIDTH = 1280f;
    public static final float HEIGHT = 720f;

    public static final float ARENA_CX = 640f;
    public static final float ARENA_CY = 380f;
    public static final float ARENA_R = 320f;

    public static final float PLAYER_RADIUS = 16f;   // 32px diameter
    public static final float ENEMY_RADIUS = 14f;    // 28px diameter
    public static final float PROJECTILE_RADIUS = 5f;

    public static final float PLAYER_HP = 100f;
    public static final float ENEMY_HP = 50f;
    public static final float PLAYER_SPEED = 220f;       // px/s
    public static final float ENEMY_BASE_SPEED = 55f;    // px/s at wave 1
    public static final float ENEMY_SPEED_STEP = 12f;    // px/s added per wave
    public static final float PROJECTILE_SPEED = 480f;   // px/s
    public static final float PROJECTILE_DAMAGE = 25f;
    public static final float CONTACT_DAMAGE = 10f;

    public static final int SCORE_PER_KILL = 10;
    public static final int WIN_SCORE = 500;
    public static final float WAVE_INTERVAL = 15f;

    private final RandomXS128 rng;
    private final Array<Enemy> enemies = new Array<Enemy>();
    private final Array<Projectile> projectiles = new Array<Projectile>();

    private float playerX;
    private float playerY;
    private float playerHp;
    private int score;
    private int wave;
    private float waveTimer;
    private float enemySpeed;
    private State state;

    private final Rectangle playerBounds = new Rectangle();

    public ArenaWorld() {
        this(new RandomXS128());
    }

    /** Seeded constructor for deterministic tests. */
    public ArenaWorld(long seed) {
        this(new RandomXS128(seed));
    }

    private ArenaWorld(RandomXS128 rng) {
        this.rng = rng;
        reset();
    }

    /** Full reset to the initial state; a fresh session behaves exactly like a first launch. */
    public void reset() {
        enemies.clear();
        projectiles.clear();
        playerX = ARENA_CX;
        playerY = ARENA_CY;
        playerHp = PLAYER_HP;
        score = 0;
        wave = 1;
        waveTimer = 0f;
        enemySpeed = ENEMY_BASE_SPEED;
        state = State.PLAYING;
        spawnWave(); // wave 1 enters immediately
    }

    /**
     * Advance one frame. {@code dirX/dirY} are the raw movement input in {-1,0,1} per axis
     * (normalised inside). Frozen on end states.
     */
    public void update(float dt, float dirX, float dirY) {
        if (state != State.PLAYING) {
            return;
        }
        movePlayer(dt, dirX, dirY);
        advanceWaves(dt);
        updateProjectiles(dt);
        updateEnemies(dt);
        checkEndConditions();
    }

    /** Fire a projectile from the player toward (targetX, targetY). Ignored on end states. */
    public void shoot(float targetX, float targetY) {
        if (state != State.PLAYING) {
            return;
        }
        float dx = targetX - playerX;
        float dy = targetY - playerY;
        float len = (float) Math.sqrt(dx * dx + dy * dy);
        if (len < 0.0001f) {
            return;
        }
        projectiles.add(new Projectile(playerX, playerY, dx / len * PROJECTILE_SPEED, dy / len * PROJECTILE_SPEED));
    }

    /** Smooth 8-way movement, then clamp the player inside the circular arena. */
    void movePlayer(float dt, float dirX, float dirY) {
        float len = (float) Math.sqrt(dirX * dirX + dirY * dirY);
        if (len > 0f) {
            playerX += dirX / len * PLAYER_SPEED * dt;
            playerY += dirY / len * PLAYER_SPEED * dt;
        }
        float ox = playerX - ARENA_CX;
        float oy = playerY - ARENA_CY;
        float dist = (float) Math.sqrt(ox * ox + oy * oy);
        float maxDist = ARENA_R - PLAYER_RADIUS;
        if (dist > maxDist && dist > 0f) {
            playerX = ARENA_CX + ox / dist * maxDist;
            playerY = ARENA_CY + oy / dist * maxDist;
        }
    }

    /** Wave 1 at start, then a larger, faster wave every 15 seconds. */
    void advanceWaves(float dt) {
        waveTimer += dt;
        while (waveTimer >= WAVE_INTERVAL) {
            waveTimer -= WAVE_INTERVAL;
            wave++;
            enemySpeed = ENEMY_BASE_SPEED + (wave - 1) * ENEMY_SPEED_STEP;
            spawnWave();
        }
    }

    private void spawnWave() {
        int count = 4 + wave * 3;
        for (int i = 0; i < count; i++) {
            float angle = rng.nextFloat() * MathUtils.PI2;
            enemies.add(new Enemy(ARENA_CX + MathUtils.cos(angle) * ARENA_R, ARENA_CY + MathUtils.sin(angle) * ARENA_R));
        }
    }

    /** Move projectiles, drop off-window ones, and resolve projectile-enemy hits (AABB). */
    void updateProjectiles(float dt) {
        for (int i = projectiles.size - 1; i >= 0; i--) {
            Projectile p = projectiles.get(i);
            p.x += p.vx * dt;
            p.y += p.vy * dt;

            if (p.x < 0f || p.x > WIDTH || p.y < 0f || p.y > HEIGHT) {
                projectiles.removeIndex(i);
                continue;
            }
            for (int j = enemies.size - 1; j >= 0; j--) {
                Enemy e = enemies.get(j);
                if (p.bounds().overlaps(e.bounds())) {
                    e.hp -= PROJECTILE_DAMAGE;
                    projectiles.removeIndex(i);
                    if (e.hp <= 0f) {
                        enemies.removeIndex(j);
                        score += SCORE_PER_KILL;
                    }
                    break;
                }
            }
        }
    }

    /** Move enemies toward the player, and resolve enemy-player contact (AABB). */
    void updateEnemies(float dt) {
        Rectangle pb = playerBounds();
        for (int i = enemies.size - 1; i >= 0; i--) {
            Enemy e = enemies.get(i);
            float dx = playerX - e.x;
            float dy = playerY - e.y;
            float len = (float) Math.sqrt(dx * dx + dy * dy);
            if (len > 0f) {
                e.x += dx / len * enemySpeed * dt;
                e.y += dy / len * enemySpeed * dt;
            }
            if (e.bounds().overlaps(pb)) {
                playerHp -= CONTACT_DAMAGE;
                enemies.removeIndex(i);
            }
        }
    }

    void checkEndConditions() {
        if (score >= WIN_SCORE) {
            state = State.WON;
        } else if (playerHp <= 0f) {
            state = State.LOST;
        }
    }

    private Rectangle playerBounds() {
        playerBounds.set(playerX - PLAYER_RADIUS, playerY - PLAYER_RADIUS, PLAYER_RADIUS * 2f, PLAYER_RADIUS * 2f);
        return playerBounds;
    }

    // Read-only views for the render layer / tests.
    public Array<Enemy> getEnemies() {
        return enemies;
    }

    public Array<Projectile> getProjectiles() {
        return projectiles;
    }

    public float getPlayerX() {
        return playerX;
    }

    public float getPlayerY() {
        return playerY;
    }

    public int getPlayerHp() {
        return (int) Math.max(0f, playerHp);
    }

    public int getScore() {
        return score;
    }

    public int getWave() {
        return wave;
    }

    public float getEnemySpeed() {
        return enemySpeed;
    }

    public State getState() {
        return state;
    }
}
