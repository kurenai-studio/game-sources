#include "Player.h"
#include "../systems/AudioManager.h"
#include "../systems/BulletManager.h"
#include "../systems/ResourceManager.h"
#include "Bullet.h"
#include <algorithm>
#include <iostream>

namespace SpaceShooter {

Player::Player()
    : Player(Vec2(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 60))
{
}

Player::Player(Vec2 startPos)
    : Entity(startPos)
{
    health = PLAYER_MAX_HEALTH;
    maxHealth = PLAYER_MAX_HEALTH;
    fireTimer = 0.0f;
    canShoot = true;

    // Initialize supercharge
    superchargeCooldownTimer = 0.0f;
    superchargeActiveTimer = 0.0f;
    superchargeWarmupTimer = 0.0f;
    isSuperchargeReady = true;
    isSuperchargeActive = false;
    isSuperchargeWarming = false;

    activePowerUp = PowerUpType::NONE;
    powerUpTimer = 0.0f;
    hasDoubleShot = false;
    hasShield = false;
    speedMultiplier = 1.0f;

    texture = nullptr;
}

void Player::Update(float deltaTime)
{
    if(!active)
        return;

    HandleInput(deltaTime);
    Move(deltaTime);

    if(fireTimer > 0) {
        fireTimer -= deltaTime;
        if(fireTimer <= 0) {
            canShoot = true;
        }
    }

    UpdatePowerUps(deltaTime);
    UpdateSupercharge(deltaTime);

    position.x = Clamp(position.x, 16, SCREEN_WIDTH - 16);
    position.y = Clamp(position.y, 16, SCREEN_HEIGHT - 16);
}

void Player::Update(float deltaTime, BulletManager* bulletManager)
{
    if(!active)
        return;

    HandleInput(deltaTime, bulletManager);
    Move(deltaTime);

    if(fireTimer > 0) {
        fireTimer -= deltaTime;
        if(fireTimer <= 0) {
            canShoot = true;
        }
    }

    UpdatePowerUps(deltaTime);
    UpdateSupercharge(deltaTime);

    position.x = Clamp(position.x, 16, SCREEN_WIDTH - 16);
    position.y = Clamp(position.y, 16, SCREEN_HEIGHT - 16);
}

void Player::Draw()
{
    if(!active) {
#ifdef _DEBUG
        static int debugCount = 0;
        if(debugCount++ < 5)
            std::cout << "Player not active!" << std::endl;
#endif
        return;
    }

    if(!texture) {
        texture = ResourceManager::GetInstance()->GetTexture("player");
        if(!texture) {
#ifdef _DEBUG
            static int debugCount2 = 0;
            if(debugCount2++ < 5)
                std::cout << "Player texture not available!" << std::endl;
#endif
            return;
        } else {
        }
    }

    Color tint = hasShield ? Color{255, 255, 255, 180} : WHITE;

    DrawTextureEx(*texture, Vector2{position.x - texture->width / 2, position.y - texture->height / 2}, rotation, 1.0f,
                  tint);
}

Rectangle Player::GetBounds() const
{
    if(!texture)
        return {position.x, position.y, 32, 32};

    return Rectangle{position.x - texture->width / 2, position.y - texture->height / 2, (float)texture->width,
                     (float)texture->height};
}

void Player::HandleInput(float deltaTime)
{
    Vec2 inputDirection(0, 0);

    // Movement input
    if(IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A)) {
        inputDirection.x -= 1.0f;
    }
    if(IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D)) {
        inputDirection.x += 1.0f;
    }
    if(IsKeyDown(KEY_UP) || IsKeyDown(KEY_W)) {
        inputDirection.y -= 1.0f;
    }
    if(IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S)) {
        inputDirection.y += 1.0f;
    }

    // Normalize diagonal movement
    if(inputDirection.Length() > 0) {
        inputDirection = inputDirection.Normalize();
        velocity = inputDirection * PLAYER_SPEED * speedMultiplier;
    } else {
        velocity = Vec2(0, 0);
    }
}

void Player::HandleInput(float deltaTime, BulletManager* bulletManager)
{
    Vec2 inputDirection(0, 0);

    // Movement input
    if(IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A)) {
        inputDirection.x -= 1.0f;
    }
    if(IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D)) {
        inputDirection.x += 1.0f;
    }
    if(IsKeyDown(KEY_UP) || IsKeyDown(KEY_W)) {
        inputDirection.y -= 1.0f;
    }
    if(IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S)) {
        inputDirection.y += 1.0f;
    }

    // Normalize diagonal movement
    if(inputDirection.Length() > 0) {
        inputDirection = inputDirection.Normalize();
        velocity = inputDirection * PLAYER_SPEED * speedMultiplier;
    } else {
        velocity = Vec2(0, 0);
    }

    // Shooting input
    bool shouldShoot = false;
    if(isSuperchargeActive) {
        shouldShoot = true;
    } else {
        shouldShoot = IsKeyDown(KEY_SPACE);
    }

    if(shouldShoot && canShoot && bulletManager) {
        Shoot(bulletManager);
    }

    if(IsKeyPressed(KEY_X) && isSuperchargeReady) {
        ActivateSupercharge();
    }
}

void Player::Shoot(BulletManager* bulletManager)
{
    if(!canShoot || !bulletManager)
        return;

    if(isSuperchargeWarming)
        return;

    canShoot = false;

    if(isSuperchargeActive) {
        fireTimer = SUPERCHARGE_FIRE_RATE;
    } else {
        fireTimer = PLAYER_FIRE_RATE;
    }

    BulletType bulletType = isSuperchargeActive ? BulletType::PLAYER_LASER : BulletType::PLAYER_NORMAL;

    AudioManager* audio = AudioManager::GetInstance();
    if(!isSuperchargeActive) {
        audio->PlaySound("shoot");
    }

    Vec2 bulletDirection(0, -1);

    if(hasDoubleShot) {
        // Create two bullets slightly offset
        Vec2 leftPos = position + Vec2(-8, -16);
        Vec2 rightPos = position + Vec2(8, -16);
        bulletManager->CreateBullet(leftPos, bulletDirection, bulletType);
        bulletManager->CreateBullet(rightPos, bulletDirection, bulletType);
    } else {
        // Single bullet
        Vec2 bulletPos = position + Vec2(0, -16);
        bulletManager->CreateBullet(bulletPos, bulletDirection, bulletType);
    }
}

void Player::TakeDamage(int damage)
{
    if(hasShield)
        return;

    health = std::max(0, health - damage);
    if(health <= 0) {
        active = false;
    }
}

void Player::ApplyPowerUp(PowerUpType type)
{
    activePowerUp = type;
    powerUpTimer = POWERUP_DURATION;

    switch(type) {
        case PowerUpType::DOUBLE_SHOT:
            hasDoubleShot = true;
            break;
        case PowerUpType::SHIELD:
            hasShield = true;
            break;
        case PowerUpType::SPEED_BOOST:
            speedMultiplier = 1.5f;
            break;
        default:
            break;
    }
}

void Player::UpdatePowerUps(float deltaTime)
{
    if(activePowerUp == PowerUpType::NONE)
        return;

    powerUpTimer -= deltaTime;
    if(powerUpTimer <= 0) {
        hasDoubleShot = false;
        hasShield = false;
        speedMultiplier = 1.0f;
        activePowerUp = PowerUpType::NONE;
    }
}

void Player::Reset()
{
    health = maxHealth;
    active = true;
    position = Vec2(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 60);
    velocity = Vec2(0, 0);

    activePowerUp = PowerUpType::NONE;
    powerUpTimer = 0.0f;
    hasDoubleShot = false;
    hasShield = false;
    speedMultiplier = 1.0f;

    fireTimer = 0.0f;
    canShoot = true;

    superchargeCooldownTimer = 0.0f;
    superchargeActiveTimer = 0.0f;
    superchargeWarmupTimer = 0.0f;
    isSuperchargeReady = true;
    isSuperchargeActive = false;
    isSuperchargeWarming = false;
}

void Player::ActivateSupercharge()
{
    if(!isSuperchargeReady)
        return;

    // Start warmup phase (cannon charging)
    isSuperchargeWarming = true;
    isSuperchargeActive = false; // still warming up
    isSuperchargeReady = false;
    superchargeWarmupTimer = SUPERCHARGE_WARMUP; // 2.79 seconds warmup
    superchargeCooldownTimer = SUPERCHARGE_COOLDOWN;

    // Play laser beam sound from the beginning (includes warmup sound)
    AudioManager::GetInstance()->PlayLaserBeam();
}

void Player::UpdateSupercharge(float deltaTime)
{
    // Update cooldown timer
    if(!isSuperchargeReady && !isSuperchargeWarming && !isSuperchargeActive && superchargeCooldownTimer > 0) {
        superchargeCooldownTimer -= deltaTime;
        if(superchargeCooldownTimer <= 0) {
            isSuperchargeReady = true;
        }
    }

    // Update warmup timer (cannon charging phase)
    if(isSuperchargeWarming && superchargeWarmupTimer > 0) {
        superchargeWarmupTimer -= deltaTime;
        if(superchargeWarmupTimer <= 0) {
            // Warmup complete, activate laser
            isSuperchargeWarming = false;
            isSuperchargeActive = true;
            // Set active timer to match audio duration (6.19s total - 2.79s warmup = 3.4s laser)
            superchargeActiveTimer = 3.4f; // Audio-based duration
        }
    }

    // Update active timer (actual laser firing)
    if(isSuperchargeActive && superchargeActiveTimer > 0) {
        superchargeActiveTimer -= deltaTime;
        if(superchargeActiveTimer <= 0) {
            isSuperchargeActive = false;
        }
    }
}

void Player::LoadTextures()
{
    texture = ResourceManager::GetInstance()->GetTexture("player");
}
} // namespace SpaceShooter
