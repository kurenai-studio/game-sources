package com.bossfight.effects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;
import com.bossfight.config.Constants;

public class ParticleSystem {
    private static final ParticleSpec DASH_GLOW = spec(0.34f, 0.92f, 1f, 0.85f, -18f, -120f);
    private static final ParticleSpec DASH_DUST = spec(0.66f, 0.52f, 0.34f, 0.56f, -24f, -280f);
    private static final ParticleSpec LANDING_DUST = spec(0.64f, 0.50f, 0.34f, 0.58f, -26f, -300f);
    private static final ParticleSpec BASIC_MUZZLE = spec(0.42f, 0.94f, 1f, 0.88f, -16f, -80f);
    private static final ParticleSpec SPECIAL_MUZZLE = spec(1f, 0.74f, 0.18f, 0.9f, -16f, -80f);
    private static final ParticleSpec BASIC_BOSS_HIT = spec(1f, 0.92f, 0.34f, 0.88f, -18f, -220f);
    private static final ParticleSpec SPECIAL_BOSS_HIT = spec(1f, 0.72f, 0.12f, 0.94f, -18f, -220f);
    private static final ParticleSpec BOSS_DEFEAT_FLASH = spec(1f, 0.98f, 0.9f, 0.92f, 0f, -360f);
    private static final ParticleSpec BOSS_DEFEAT_GOLD = spec(1f, 0.84f, 0.16f, 0.9f, -14f, -260f);
    private static final ParticleSpec BOSS_DEFEAT_ORANGE = spec(1f, 0.42f, 0.12f, 0.86f, -14f, -260f);
    private static final ParticleSpec PLAYER_DAMAGE = spec(1f, 0.2f, 0.18f, 0.92f, -20f, -300f);
    private static final ParticleSpec ARENA_PETAL = spec(1f, 0.72f, 0.42f, 0.58f, -0.8f, 0f);
    private static final ParticleSpec ARENA_ENRAGED_PETAL = spec(1f, 0.28f, 0.08f, 0.62f, -0.8f, 0f);
    private static final ParticleSpec BOSS_RAGE_RED = spec(1f, 0.18f, 0.04f, 0.9f, -10f, -260f);
    private static final ParticleSpec BOSS_RAGE_GOLD = spec(1f, 0.68f, 0.12f, 0.84f, -10f, -260f);

    private final Array<Particle> particles = new Array<>();

    public void update(float delta) {
        for (int i = particles.size - 1; i >= 0; i--) {
            Particle particle = particles.get(i);
            particle.life -= delta;
            if (particle.life <= 0f) {
                particles.removeIndex(i);
                continue;
            }

            particle.x += particle.velocityX * delta;
            particle.y += particle.velocityY * delta;
            particle.velocityY += particle.spec.gravity() * delta;
            particle.radius = Math.max(0f, particle.radius + particle.spec.radiusVelocity() * delta);
        }
    }

    public void render(ShapeRenderer shapeRenderer) {
        for (Particle particle : particles) {
            float alpha = MathUtils.clamp(particle.life / particle.maxLife, 0f, 1f);
            shapeRenderer.setColor(
                    particle.spec.color().r,
                    particle.spec.color().g,
                    particle.spec.color().b,
                    particle.spec.color().a * alpha
            );
            shapeRenderer.circle(particle.x, particle.y, particle.radius);
        }
    }

    public void clear() {
        particles.clear();
    }

    public void spawnDash(float x, float y, int direction) {
        for (int i = 0; i < 18; i++) {
            float speed = MathUtils.random(80f, 360f);
            float angle = MathUtils.random(-0.75f, 0.75f) + (direction > 0 ? MathUtils.PI : 0f);
            add(x, y + MathUtils.random(16f, 70f),
                    MathUtils.cos(angle) * speed,
                    MathUtils.sin(angle) * speed,
                    MathUtils.random(4f, 9f),
                    0.28f,
                    DASH_GLOW);
        }

        float footY = y - 38f;
        for (int i = 0; i < 12; i++) {
            float speed = MathUtils.random(70f, 230f);
            add(x - direction * MathUtils.random(10f, 28f),
                    footY + MathUtils.random(-2f, 8f),
                    -direction * speed,
                    MathUtils.random(18f, 78f),
                    MathUtils.random(3.5f, 7.5f),
                    MathUtils.random(0.18f, 0.32f),
                    DASH_DUST);
        }
    }

    public void spawnLandingDust(float x, float y) {
        for (int i = 0; i < 16; i++) {
            float direction = MathUtils.randomBoolean() ? 1f : -1f;
            float speed = MathUtils.random(38f, 170f);
            add(x + MathUtils.random(-20f, 20f),
                    y + MathUtils.random(-2f, 5f),
                    direction * speed,
                    MathUtils.random(18f, 92f),
                    MathUtils.random(3f, 8f),
                    MathUtils.random(0.22f, 0.38f),
                    LANDING_DUST);
        }
    }

    public void spawnMuzzle(float x, float y, int direction, boolean special) {
        ParticleSpec particleSpec = special ? SPECIAL_MUZZLE : BASIC_MUZZLE;
        int count = special ? 22 : 9;
        for (int i = 0; i < count; i++) {
            float baseAngle = direction >= 0 ? 0f : MathUtils.PI;
            float angle = baseAngle + MathUtils.random(-0.45f, 0.45f);
            float speed = MathUtils.random(80f, special ? 520f : 260f);
            add(x, y,
                    MathUtils.cos(angle) * speed,
                    MathUtils.sin(angle) * speed,
                    MathUtils.random(3f, special ? 10f : 6f),
                    special ? 0.34f : 0.18f,
                    particleSpec);
        }
    }

    public void spawnBossHit(float x, float y, boolean special) {
        ParticleSpec particleSpec = special ? SPECIAL_BOSS_HIT : BASIC_BOSS_HIT;
        int count = special ? 28 : 13;
        for (int i = 0; i < count; i++) {
            float angle = MathUtils.random(0f, MathUtils.PI2);
            float speed = MathUtils.random(70f, special ? 430f : 250f);
            add(x, y,
                    MathUtils.cos(angle) * speed,
                    MathUtils.sin(angle) * speed,
                    MathUtils.random(3f, special ? 10f : 7f),
                    special ? 0.42f : 0.25f,
                    particleSpec);
        }
    }

    public void spawnBossDefeatBurst(float centerX, float centerY) {
        float anchorX = centerX + MathUtils.random(-145f, 90f);
        float anchorY = centerY + MathUtils.random(-128f, 118f);

        for (int i = 0; i < 11; i++) {
            float angle = MathUtils.random(0f, MathUtils.PI2);
            float speed = MathUtils.random(55f, 230f);
            add(anchorX + MathUtils.random(-18f, 18f),
                    anchorY + MathUtils.random(-16f, 16f),
                    MathUtils.cos(angle) * speed,
                    MathUtils.sin(angle) * speed + MathUtils.random(30f, 140f),
                    MathUtils.random(7f, 16f),
                    MathUtils.random(0.34f, 0.58f),
                    BOSS_DEFEAT_FLASH.withRadiusVelocity(MathUtils.random(-18f, 8f)));
        }

        for (int i = 0; i < 12; i++) {
            float angle = MathUtils.random(0f, MathUtils.PI2);
            float speed = MathUtils.random(120f, 430f);
            ParticleSpec particleSpec = MathUtils.randomBoolean() ? BOSS_DEFEAT_GOLD : BOSS_DEFEAT_ORANGE;
            add(anchorX,
                    anchorY,
                    MathUtils.cos(angle) * speed,
                    MathUtils.sin(angle) * speed,
                    MathUtils.random(2.8f, 6.5f),
                    MathUtils.random(0.25f, 0.42f),
                    particleSpec);
        }
    }

    public void spawnPlayerDamage(float x, float y) {
        for (int i = 0; i < 18; i++) {
            float angle = MathUtils.random(0f, MathUtils.PI2);
            float speed = MathUtils.random(90f, 320f);
            add(x, y,
                    MathUtils.cos(angle) * speed,
                    MathUtils.sin(angle) * speed,
                    MathUtils.random(4f, 8f),
                    0.34f,
                    PLAYER_DAMAGE);
        }
    }

    public void spawnArenaPetal(boolean enraged) {
        ParticleSpec particleSpec = enraged && MathUtils.randomBoolean() ? ARENA_ENRAGED_PETAL : ARENA_PETAL;
        add(MathUtils.random(Constants.ARENA_LEFT, Constants.ARENA_RIGHT),
                Constants.WORLD_HEIGHT + 8f,
                MathUtils.random(-52f, 52f),
                MathUtils.random(-105f, -62f),
                MathUtils.random(2.5f, 5f),
                MathUtils.random(3.2f, 4.6f),
                particleSpec.withGravity(MathUtils.random(-24f, -8f)));
    }

    public void spawnBossRage(float x, float y) {
        for (int i = 0; i < 34; i++) {
            float angle = MathUtils.random(0f, MathUtils.PI2);
            float speed = MathUtils.random(90f, 410f);
            ParticleSpec particleSpec = MathUtils.randomBoolean() ? BOSS_RAGE_RED : BOSS_RAGE_GOLD;
            add(x, y,
                    MathUtils.cos(angle) * speed,
                    MathUtils.sin(angle) * speed + 90f,
                    MathUtils.random(3f, 8f),
                    MathUtils.random(0.45f, 0.78f),
                    particleSpec);
        }
    }

    private static ParticleSpec spec(float red, float green, float blue, float alpha,
                                     float radiusVelocity, float gravity) {
        return new ParticleSpec(new Color(red, green, blue, alpha), radiusVelocity, gravity);
    }

    private void add(float x, float y, float velocityX, float velocityY, float radius, float life,
                     ParticleSpec particleSpec) {
        particles.add(new Particle(x, y, velocityX, velocityY, radius, life, particleSpec));
    }

    private record ParticleSpec(Color color, float radiusVelocity, float gravity) {
        private ParticleSpec withRadiusVelocity(float value) {
            return new ParticleSpec(color, value, gravity);
        }

        private ParticleSpec withGravity(float value) {
            return new ParticleSpec(color, radiusVelocity, value);
        }
    }

    private static final class Particle {
        private final float maxLife;
        private final ParticleSpec spec;
        private float x;
        private float y;
        private float velocityX;
        private float velocityY;
        private float radius;
        private float life;

        private Particle(float x, float y, float velocityX, float velocityY, float radius, float life,
                         ParticleSpec spec) {
            this.x = x;
            this.y = y;
            this.velocityX = velocityX;
            this.velocityY = velocityY;
            this.radius = radius;
            this.life = life;
            this.maxLife = life;
            this.spec = spec;
        }
    }
}
