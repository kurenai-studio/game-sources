package com.bossfight.entities;

import com.badlogic.gdx.math.MathUtils;
import com.bossfight.config.Constants;

public class Player {
    private static final float SHOOT_POSE_HOLD = Constants.PLAYER_SHOOT_COOLDOWN + 0.08f;
    private static final float SPECIAL_SHOOT_POSE_HOLD = 0.36f;
    private static final float SHOT_MUZZLE_Y_FACTOR = 0.70f;
    private static final float JUMP_BUFFER_DURATION = 0.11f;
    private static final float DASH_BUFFER_DURATION = 0.12f;

    private final Hitbox hitbox;
    private int health;
    private int facingDirection = 1;
    private float x;
    private float y;
    private float velocityY;
    private float shootCooldown;
    private float specialCooldown;
    private float specialEnergy;
    private float dashCooldown;
    private float dashTimer;
    private float invulnerabilityTimer;
    private float hurtFlashTimer;
    private float knockbackTimer;
    private float knockbackVelocityX;
    private float shootPoseTimer;
    private float specialPoseTimer;
    private float animationTime;
    private float jumpBufferTimer;
    private float dashBufferTimer;
    private int dashDirection = 1;
    private boolean dashStartedThisFrame;
    private boolean landedThisFrame;
    private boolean movingHorizontally;

    public Player() {
        x = Constants.PLAYER_START_X;
        y = Constants.PLAYER_START_Y;
        health = Constants.PLAYER_MAX_HEALTH;
        hitbox = new Hitbox(x, y, Constants.PLAYER_WIDTH, Constants.PLAYER_HEIGHT);
    }

    public void update(float delta, PlayerInput input) {
        dashStartedThisFrame = false;
        landedThisFrame = false;
        boolean wasGrounded = isOnGround();
        shootCooldown = Math.max(0f, shootCooldown - delta);
        specialCooldown = Math.max(0f, specialCooldown - delta);
        dashCooldown = Math.max(0f, dashCooldown - delta);
        invulnerabilityTimer = Math.max(0f, invulnerabilityTimer - delta);
        hurtFlashTimer = Math.max(0f, hurtFlashTimer - delta);
        shootPoseTimer = Math.max(0f, shootPoseTimer - delta);
        specialPoseTimer = Math.max(0f, specialPoseTimer - delta);
        jumpBufferTimer = Math.max(0f, jumpBufferTimer - delta);
        dashBufferTimer = Math.max(0f, dashBufferTimer - delta);
        queueBufferedInputs(input.jumpPressed(), input.dashPressed());
        animationTime += delta;
        movingHorizontally = dashTimer > 0f;

        if (dashTimer > 0f) {
            dashTimer -= delta;
            x += dashDirection * Constants.PLAYER_DASH_SPEED * delta;
        } else if (knockbackTimer > 0f) {
            knockbackTimer -= delta;
            x += knockbackVelocityX * delta;
            knockbackVelocityX *= 0.86f;
            updateJumpAndGravity(delta, false);
        } else {
            updateHorizontalMovement(delta, input.moveLeft(), input.moveRight());
            updateJumpAndGravity(delta, true);
            tryStartDash();
        }

        keepInsideArena();
        landedThisFrame = !wasGrounded && isOnGround();
        hitbox.setPosition(x, y);
    }

    public Projectile tryShoot() {
        if (shootCooldown > 0f) {
            return null;
        }

        shootCooldown = Constants.PLAYER_SHOOT_COOLDOWN;
        shootPoseTimer = SHOOT_POSE_HOLD;
        float projectileX = facingDirection > 0
                ? x + Constants.PLAYER_WIDTH
                : x - Constants.PLAYER_PROJECTILE_WIDTH;
        float projectileY = getShotOriginY(Constants.PLAYER_PROJECTILE_HEIGHT);
        float velocityX = facingDirection * Constants.PLAYER_PROJECTILE_SPEED;

        return Projectile.playerBasic(projectileX, projectileY, velocityX);
    }

    public Projectile tryShootSpecial() {
        if (specialCooldown > 0f || specialEnergy < Constants.PLAYER_SPECIAL_MAX) {
            return null;
        }

        specialEnergy = 0f;
        specialCooldown = Constants.PLAYER_SPECIAL_COOLDOWN;
        shootPoseTimer = 0f;
        specialPoseTimer = SPECIAL_SHOOT_POSE_HOLD;
        float projectileX = facingDirection > 0
                ? x + Constants.PLAYER_WIDTH
                : x - Constants.PLAYER_SPECIAL_WIDTH;
        float projectileY = getShotOriginY(Constants.PLAYER_SPECIAL_HEIGHT);
        float velocityX = facingDirection * Constants.PLAYER_SPECIAL_SPEED;

        return Projectile.playerSpecial(projectileX, projectileY, velocityX);
    }

    public boolean takeDamage(int amount, float sourceX) {
        if (isInvulnerableAfterHit() || dashTimer > 0f || health <= 0) {
            return false;
        }

        if (sourceX < getCenterX()) {
            facingDirection = -1;
        } else if (sourceX > getCenterX()) {
            facingDirection = 1;
        }

        health = Math.max(0, health - amount);
        invulnerabilityTimer = Constants.PLAYER_INVULNERABILITY_DURATION;
        hurtFlashTimer = 0.18f;
        knockbackTimer = 0.16f;
        knockbackVelocityX = sourceX < getCenterX() ? 360f : -360f;
        velocityY = Math.max(velocityY, 240f);
        return true;
    }

    public boolean isDead() {
        return health <= 0;
    }

    public float getCenterX() {
        return x + Constants.PLAYER_WIDTH * 0.5f;
    }

    public float getCenterY() {
        return y + Constants.PLAYER_HEIGHT * 0.5f;
    }

    public Hitbox getHitbox() {
        return hitbox;
    }

    public int getHealth() {
        return health;
    }

    public float getSpecialEnergyPercent() {
        return specialEnergy / Constants.PLAYER_SPECIAL_MAX;
    }

    public boolean isSpecialReady() {
        return specialEnergy >= Constants.PLAYER_SPECIAL_MAX && specialCooldown <= 0f;
    }

    public void addSpecialEnergy(float amount) {
        specialEnergy = Math.min(Constants.PLAYER_SPECIAL_MAX, specialEnergy + amount);
    }

    public boolean consumeDashStarted() {
        boolean started = dashStartedThisFrame;
        dashStartedThisFrame = false;
        return started;
    }

    public boolean consumeLanded() {
        boolean landed = landedThisFrame;
        landedThisFrame = false;
        return landed;
    }

    public int getFacingDirection() {
        return facingDirection;
    }

    public float getX() {
        return x;
    }

    public float getY() {
        return y;
    }

    public float getAnimationTime() {
        return animationTime;
    }

    public boolean isMovingHorizontally() {
        return movingHorizontally;
    }

    public boolean isGrounded() {
        return isOnGround();
    }

    public boolean isAirborne() {
        return !isOnGround();
    }

    public boolean isShootPoseActive() {
        return shootPoseTimer > 0f;
    }

    public boolean isSpecialPoseActive() {
        return specialPoseTimer > 0f;
    }

    public boolean isHurtPoseActive() {
        return hurtFlashTimer > 0f || knockbackTimer > 0f;
    }

    public boolean shouldRenderSprite() {
        return invulnerabilityTimer <= 0f || ((int) (invulnerabilityTimer * 18f) % 2 != 0);
    }

    public boolean isDashing() {
        return dashTimer > 0f;
    }

    public boolean isInvulnerableAfterHit() {
        return invulnerabilityTimer > 0f;
    }

    private void updateHorizontalMovement(float delta, boolean moveLeft, boolean moveRight) {
        float velocityX = 0f;

        if (moveLeft) {
            velocityX -= Constants.PLAYER_SPEED;
            facingDirection = -1;
        }
        if (moveRight) {
            velocityX += Constants.PLAYER_SPEED;
            facingDirection = 1;
        }

        x += velocityX * delta;
        movingHorizontally = velocityX != 0f;
    }

    private void queueBufferedInputs(boolean jumpPressed, boolean dashPressed) {
        if (jumpPressed) {
            jumpBufferTimer = JUMP_BUFFER_DURATION;
        }
        if (dashPressed) {
            dashBufferTimer = DASH_BUFFER_DURATION;
        }
    }

    private float getShotOriginY(float projectileHeight) {
        return y + Constants.PLAYER_HEIGHT * SHOT_MUZZLE_Y_FACTOR - projectileHeight * 0.5f;
    }

    private void updateJumpAndGravity(float delta, boolean allowBufferedJump) {
        if (allowBufferedJump && jumpBufferTimer > 0f && isOnGround()) {
            velocityY = Constants.PLAYER_JUMP_SPEED;
            jumpBufferTimer = 0f;
        }

        velocityY += Constants.GRAVITY * delta;
        y += velocityY * delta;
    }

    private void tryStartDash() {
        if (dashBufferTimer <= 0f || dashCooldown > 0f) {
            return;
        }

        dashTimer = Constants.PLAYER_DASH_DURATION;
        dashCooldown = Constants.PLAYER_DASH_COOLDOWN;
        dashDirection = facingDirection;
        dashStartedThisFrame = true;
        movingHorizontally = true;
        dashBufferTimer = 0f;
    }

    private void keepInsideArena() {
        x = MathUtils.clamp(x, Constants.ARENA_LEFT, Constants.ARENA_RIGHT - Constants.PLAYER_WIDTH);

        if (y < Constants.FLOOR_Y) {
            y = Constants.FLOOR_Y;
            velocityY = 0f;
        }
    }

    private boolean isOnGround() {
        return y <= Constants.FLOOR_Y + 0.1f;
    }
}
