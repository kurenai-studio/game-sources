package com.bossfight.rendering;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Disposable;
import com.bossfight.config.Constants;
import com.bossfight.entities.Projectile;
import com.bossfight.gameplay.ProjectileSystem;

import java.util.EnumMap;

public final class ProjectileRenderer implements Disposable {
    private static final float IMPACT_SHADOW_MIN_WIDTH = 50f;
    private static final float IMPACT_SHADOW_MAX_WIDTH = 82f;
    private static final float IMPACT_SHADOW_MIN_HEIGHT = 13f;
    private static final float IMPACT_SHADOW_MAX_HEIGHT = 23f;
    private static final float POLLEN_IMPACT_SHADOW_MIN_FALL_SPEED = -160f;
    private static final TrailSpec SEED_TRAIL = new TrailSpec(46f, 34f, 2, 14f,
            1f, 0.42f, 0.18f, 0.16f);
    private static final TrailSpec ACORN_TRAIL = new TrailSpec(50f, 54f, 2, 14f,
            0.8f, 0.48f, 0.18f, 0.18f);
    private static final TrailSpec PETAL_BOMB_TRAIL = new TrailSpec(54f, 70f, 2, 18f,
            1f, 0.44f, 0.12f, 0.2f);

    private final ProjectileSystem projectiles;
    private final EnumMap<Projectile.Kind, Texture> textures = new EnumMap<>(Projectile.Kind.class);

    private record TrailSpec(
            float width,
            float height,
            int count,
            float spacing,
            float red,
            float green,
            float blue,
            float alpha
    ) {
    }

    public ProjectileRenderer(ProjectileSystem projectiles) {
        this.projectiles = projectiles;
        registerTexture(Projectile.Kind.PLAYER_BASIC, "sprites/projectiles/player_pea.png");
        registerTexture(Projectile.Kind.PLAYER_SPECIAL, "sprites/projectiles/player_special.png");
        registerTexture(Projectile.Kind.BOSS_SEED, "sprites/projectiles/boss_seed.png");
        registerTexture(Projectile.Kind.BOSS_ACORN, "sprites/projectiles/boss_acorn.png");
        registerTexture(Projectile.Kind.BOSS_ACORN_OBSTACLE, "sprites/projectiles/boss_acorn.png");
        registerTexture(Projectile.Kind.BOSS_POLLEN, "sprites/projectiles/boss_pollen.png");
        registerTexture(Projectile.Kind.BOSS_THORN, "sprites/projectiles/boss_thorn.png");
        registerTexture(Projectile.Kind.BOSS_PETAL_BOMB, "sprites/projectiles/boss_petal_bomb.png");
    }

    public void renderWarnings(ShapeRenderer shapeRenderer) {
        renderWarnings(shapeRenderer, projectiles.playerProjectiles());
        renderWarnings(shapeRenderer, projectiles.bossProjectiles());
    }

    public void renderSprites(SpriteBatch batch) {
        renderSprites(batch, projectiles.playerProjectiles());
        renderSprites(batch, projectiles.bossProjectiles());
    }

    @Override
    public void dispose() {
        textures.values().forEach(Texture::dispose);
    }

    private void registerTexture(Projectile.Kind kind, String path) {
        textures.put(kind, TextureLoader.loadLinear(path));
    }

    private Texture textureFor(Projectile.Kind kind) {
        Texture texture = textures.get(kind);
        if (texture == null) {
            throw new IllegalArgumentException("Nenhuma textura registrada para o tipo de projétil " + kind);
        }
        return texture;
    }

    private void renderSprites(SpriteBatch batch, Iterable<Projectile> projectileList) {
        for (Projectile projectile : projectileList) {
            switch (projectile.getKind()) {
                case PLAYER_BASIC -> drawTextureAt(batch, textureFor(projectile.getKind()),
                        projectile.getCenterX(),
                        projectile.getCenterY(),
                        58f + MathUtils.sin(projectile.getAge() * 15f) * 1.2f,
                        27f + MathUtils.sin(projectile.getAge() * 15f) * 0.6f,
                        MathUtils.sin(projectile.getAge() * 15f) * 2f,
                        projectile.getVelocityX() < 0f,
                        1f, 1f, 1f, 1f);
                case PLAYER_SPECIAL -> drawTextureAt(batch, textureFor(projectile.getKind()),
                        projectile.getCenterX(),
                        projectile.getCenterY(),
                        158f + MathUtils.sin(projectile.getAge() * 10f) * 4f,
                        139f + MathUtils.sin(projectile.getAge() * 10f) * 3.5f,
                        0f,
                        projectile.getVelocityX() < 0f,
                        1f, 1f, 1f, 1f);
                case BOSS_SEED -> drawTextureWithTrail(
                        batch, textureFor(projectile.getKind()), projectile, rotationFor(projectile), SEED_TRAIL);
                case BOSS_ACORN -> drawTextureWithTrail(
                        batch, textureFor(projectile.getKind()), projectile, rotationFor(projectile), ACORN_TRAIL);
                case BOSS_ACORN_OBSTACLE -> drawAcornObstacle(batch, projectile);
                case BOSS_POLLEN -> {
                    float pulse = MathUtils.sin(projectile.getAge() * 8f);
                    Texture texture = textureFor(projectile.getKind());
                    drawTextureAt(batch, texture, projectile.getCenterX(), projectile.getCenterY(),
                            72f + pulse * 5f, 72f - pulse * 3f,
                            projectile.getAge() * 48f, false, 0.7f, 0.32f, 1f, 0.22f);
                    drawTexture(batch, texture, projectile,
                            58f + MathUtils.sin(projectile.getAge() * 8f) * 4f,
                            58f + MathUtils.cos(projectile.getAge() * 8f) * 4f,
                            projectile.getAge() * 80f);
                }
                case BOSS_THORN -> {
                    if (isVerticalThorn(projectile)) {
                        drawThornPillar(batch, projectile);
                    } else {
                        drawThornLane(batch, projectile);
                    }
                }
                case BOSS_PETAL_BOMB -> drawTextureWithTrail(batch,
                        textureFor(projectile.getKind()), projectile,
                        MathUtils.sin(projectile.getAge() * 9f) * 12f, PETAL_BOMB_TRAIL);
                case BOSS_VINE_WARNING, BOSS_IMPACT_WARNING -> {
                }
            }
        }
        batch.setColor(Color.WHITE);
    }

    private void renderWarnings(ShapeRenderer shapeRenderer, Iterable<Projectile> projectileList) {
        for (Projectile projectile : projectileList) {
            if (projectile.getKind() == Projectile.Kind.BOSS_VINE_WARNING) {
                drawVineWarning(shapeRenderer, projectile);
            } else if (projectile.getKind() == Projectile.Kind.BOSS_IMPACT_WARNING) {
                drawPollenWarningShadow(shapeRenderer, projectile);
            } else if (projectile.getKind() == Projectile.Kind.BOSS_ACORN_OBSTACLE
                    && projectile.isGrounded()) {
                drawImpactShadow(shapeRenderer, projectile.getCenterX(), Constants.FLOOR_Y - 7f,
                        62f, 16f, 0.42f);
            } else if (isFallingImpactProjectile(projectile)) {
                drawFallingImpactShadow(shapeRenderer, projectile);
            }
        }
    }

    private void drawTexture(SpriteBatch batch, Texture texture, Projectile projectile,
                             float width, float height, float rotation) {
        drawTextureAt(batch, texture, projectile.getCenterX(), projectile.getCenterY(), width, height,
                rotation, false, 1f, 1f, 1f, 1f);
    }

    private void drawTextureWithTrail(SpriteBatch batch, Texture texture, Projectile projectile,
                                      float rotation, TrailSpec trail) {
        float velocityAngle = MathUtils.atan2(projectile.getVelocityY(), projectile.getVelocityX());
        float trailX = -MathUtils.cos(velocityAngle) * trail.spacing();
        float trailY = -MathUtils.sin(velocityAngle) * trail.spacing();

        for (int i = trail.count(); i >= 1; i--) {
            float progress = (float) i / (trail.count() + 1f);
            float scale = 1f + progress * 0.18f;
            drawTextureAt(batch, texture,
                    projectile.getCenterX() + trailX * i,
                    projectile.getCenterY() + trailY * i,
                    trail.width() * scale,
                    trail.height() * scale,
                    rotation - i * 5f,
                    false,
                    trail.red(), trail.green(), trail.blue(),
                    trail.alpha() * (1f - progress * 0.45f));
        }

        drawTextureAt(batch, texture, projectile.getCenterX(), projectile.getCenterY(),
                trail.width(), trail.height(), rotation, false, 1f, 1f, 1f, 1f);
    }

    private void drawAcornObstacle(SpriteBatch batch, Projectile projectile) {
        Texture texture = textureFor(projectile.getKind());
        if (!projectile.isGrounded()) {
            drawTextureWithTrail(batch, texture, projectile, rotationFor(projectile), ACORN_TRAIL);
            return;
        }

        float pulse = MathUtils.sin(projectile.getAge() * 7f);
        drawTextureAt(batch, texture,
                projectile.getCenterX(), projectile.getCenterY() + 7f,
                64f + pulse * 2f, 62f - pulse * 2f,
                pulse * 2.5f, false,
                1f, 0.88f, 0.68f, 1f);
    }

    private void drawTextureAt(SpriteBatch batch, Texture texture, float centerX, float centerY,
                               float width, float height, float rotation, boolean flipX,
                               float red, float green, float blue, float alpha) {
        float x = centerX - width * 0.5f;
        float y = centerY - height * 0.5f;
        batch.setColor(red, green, blue, alpha);
        batch.draw(texture,
                x, y,
                width * 0.5f, height * 0.5f,
                width, height,
                1f, 1f,
                rotation,
                0, 0,
                texture.getWidth(), texture.getHeight(),
                flipX, false);
    }

    private void drawThornLane(SpriteBatch batch, Projectile projectile) {
        float drawWidth = projectile.getWidth() + 48f;
        float drawHeight = Math.max(170f, projectile.getHeight() * 4.1f);
        float rise = MathUtils.sin(projectile.getAge() * 18f) * 3f;
        drawTextureAt(batch, textureFor(projectile.getKind()),
                projectile.getCenterX(), projectile.getCenterY() + rise,
                drawWidth, drawHeight, 0f, true,
                1f, 1f, 1f, 1f);
    }

    private void drawThornPillar(SpriteBatch batch, Projectile projectile) {
        float pulse = MathUtils.sin(projectile.getAge() * 19f);
        float drawWidth = Math.max(96f, projectile.getWidth() * 2.05f + pulse * 3f);
        float drawHeight = projectile.getHeight() + 92f;
        float centerY = projectile.getY() + drawHeight * 0.47f;

        drawTextureAt(batch, textureFor(projectile.getKind()),
                projectile.getCenterX(),
                centerY,
                drawHeight,
                drawWidth,
                90f,
                false,
                1f, 1f, 1f, 1f);
    }

    private void drawPollenWarningShadow(ShapeRenderer shapeRenderer, Projectile projectile) {
        float progress = projectile.getWarningProgress();
        float pulse = (MathUtils.sin(projectile.getAge() * 13f) + 1f) * 0.5f;
        float width = 56f + progress * 25f + pulse * 5f;
        float height = 15f + progress * 7f + pulse * 2f;
        float centerX = projectile.getCenterX();
        float y = Constants.FLOOR_Y - 7f;
        float alpha = MathUtils.clamp(0.22f + progress * 0.34f + pulse * 0.08f, 0f, 0.72f);

        drawImpactShadow(shapeRenderer, centerX, y, width, height, alpha);
    }

    private void drawVineWarning(ShapeRenderer shapeRenderer, Projectile projectile) {
        float progress = projectile.getWarningProgress();
        float pulse = (MathUtils.sin(projectile.getAge() * 16f) + 1f) * 0.5f;
        float alpha = MathUtils.clamp(0.16f + progress * 0.24f + pulse * 0.08f, 0f, 0.54f);
        float x = projectile.getX();
        float y = projectile.getY();
        float width = projectile.getWidth();
        float height = projectile.getHeight();
        boolean vertical = height > width;

        shapeRenderer.setColor(0.14f, 0.72f, 0.16f, alpha * 0.45f);
        shapeRenderer.rect(x, y, width, height);
        shapeRenderer.setColor(1f, 0.82f, 0.16f, MathUtils.clamp(alpha * 1.25f, 0f, 0.68f));
        if (vertical) {
            shapeRenderer.rect(x + width * 0.39f, y, width * 0.22f, height);
        } else {
            shapeRenderer.rect(x, y + height * 0.39f, width, height * 0.22f);
        }
        shapeRenderer.setColor(0.04f, 0.16f, 0.04f, alpha * 0.58f);
        if (vertical) {
            shapeRenderer.ellipse(x - width * 0.18f, Constants.FLOOR_Y - 9f, width * 1.36f, 24f);
        } else {
            shapeRenderer.rect(x, y - height * 0.18f, width, height * 0.28f);
        }
    }

    private void drawFallingImpactShadow(ShapeRenderer shapeRenderer, Projectile projectile) {
        float centerX = projectedImpactCenterX(projectile);
        float y = Constants.FLOOR_Y - 7f;
        float floorDistance = Math.max(0f, projectile.getY() - Constants.FLOOR_Y);
        float fallAreaHeight = Constants.WORLD_HEIGHT - Constants.FLOOR_Y;
        float proximity = 1f - MathUtils.clamp(floorDistance / fallAreaHeight, 0f, 1f);
        float pulse = (MathUtils.sin(projectile.getAge() * 14f) + 1f) * 0.5f;
        float width = MathUtils.lerp(IMPACT_SHADOW_MIN_WIDTH, IMPACT_SHADOW_MAX_WIDTH, proximity) + pulse * 4f;
        float height = MathUtils.lerp(IMPACT_SHADOW_MIN_HEIGHT, IMPACT_SHADOW_MAX_HEIGHT, proximity) + pulse * 1.5f;
        float alpha = MathUtils.clamp(0.16f + proximity * 0.36f + pulse * 0.06f, 0f, 0.64f);

        drawImpactShadow(shapeRenderer, centerX, y, width, height, alpha);
    }

    private void drawImpactShadow(ShapeRenderer shapeRenderer, float centerX, float y, float width, float height,
                                  float alpha) {
        shapeRenderer.setColor(0.04f, 0.018f, 0.01f, alpha * 0.62f);
        shapeRenderer.ellipse(centerX - width * 0.5f, y - 2f, width, height);
        shapeRenderer.setColor(0.82f, 0.28f, 0.08f, alpha * 0.22f);
        shapeRenderer.ellipse(centerX - width * 0.42f, y + 2f, width * 0.84f, height * 0.64f);
        shapeRenderer.setColor(1f, 0.78f, 0.22f, alpha * 0.16f);
        shapeRenderer.ellipse(centerX - width * 0.34f, y + 5f, width * 0.68f, height * 0.34f);
    }

    private float projectedImpactCenterX(Projectile projectile) {
        if (projectile.getVelocityY() >= -1f) {
            return projectile.getCenterX();
        }

        float timeToFloor = Math.max(0f,
                (projectile.getY() - Constants.FLOOR_Y) / -projectile.getVelocityY());
        float projectedX = projectile.getCenterX() + projectile.getVelocityX() * timeToFloor;
        return MathUtils.clamp(projectedX, Constants.ARENA_LEFT, Constants.ARENA_RIGHT);
    }

    private boolean isVerticalThorn(Projectile projectile) {
        return projectile.getHeight() > projectile.getWidth() * 2f;
    }

    private boolean isFallingImpactProjectile(Projectile projectile) {
        if (projectile.getVelocityY() >= -1f) {
            return false;
        }

        return projectile.getKind() == Projectile.Kind.BOSS_PETAL_BOMB
                || (projectile.getKind() == Projectile.Kind.BOSS_POLLEN
                && projectile.getVelocityY() <= POLLEN_IMPACT_SHADOW_MIN_FALL_SPEED);
    }

    private float rotationFor(Projectile projectile) {
        return MathUtils.atan2(projectile.getVelocityY(), projectile.getVelocityX()) * MathUtils.radiansToDegrees;
    }
}
