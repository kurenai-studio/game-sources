#include "Game.h"
#include <iostream>

namespace SpaceShooter {

Game::Game()
    : currentState(GameState::MENU)
    , isRunning(false)
    , backgroundY1(0)
    , backgroundY2(-SCREEN_HEIGHT)
    , score(0)
    , wave(1)
{
    player = std::make_unique<Player>();
    bulletManager = std::make_unique<BulletManager>();
    enemyManager = std::make_unique<EnemyManager>();
    powerUpManager = std::make_unique<PowerUpManager>();
    explosionManager = std::make_unique<ExplosionManager>();
    backgroundTexture = nullptr;
}

Game::~Game()
{
    Shutdown();
}

bool Game::Initialize()
{
    std::cout << "Initializing Space Shooter..." << std::endl;

    // Initialize Raylib
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Space Shooter");
    SetTargetFPS(TARGET_FPS);

    // Disable automatic ESC key exit so we can handle it manually
    SetExitKey(0);

    // Initialize audio
    InitAudioDevice();

    // Load all assets
    ResourceManager* rm = ResourceManager::GetInstance();
    if(!rm->LoadAllAssets()) {
        std::cout << "Failed to load assets!" << std::endl;
        return false;
    }

    // Load audio
    AudioManager* audio = AudioManager::GetInstance();
    if(!audio->LoadAllAudio()) {
        std::cout << "Failed to load audio!" << std::endl;
        return false;
    }

    backgroundTexture = rm->GetTexture("background");

    // Initialize bullet manager
    bulletManager->Initialize();

    // Initialize enemy manager
    enemyManager->Initialize();

    // Set up scoring callback
    enemyManager->SetEnemyDestroyedCallback([this](int points) {
        std::cout << "[DEBUG] Enemy destroyed callback triggered with " << points << " points!" << std::endl;
        AddScore(points);
    });

    // Set up explosion callback
    enemyManager->SetEnemyExplodedCallback([this](Vec2 position) {
        if(explosionManager) {
            explosionManager->CreateExplosion(position);
        }
    });

    // Initialize power-up manager
    powerUpManager->Initialize();

    // Initialize explosion manager
    explosionManager->Initialize();

    // Load player textures after assets are loaded
    if(player) {
        player->LoadTextures();
    }

    isRunning = true;
    std::cout << "Game initialized successfully!" << std::endl;
    return true;
}

void Game::Run()
{
    while(isRunning && !WindowShouldClose()) {
        float deltaTime = GetFrameTime();
        Update(deltaTime);
        Draw();
    }
}

void Game::Shutdown()
{
    std::cout << "Shutting down game..." << std::endl;

    ResourceManager::DestroyInstance();
    AudioManager::DestroyInstance();
    CloseAudioDevice();
    CloseWindow();

    isRunning = false;
}

void Game::Update(float deltaTime)
{
    switch(currentState) {
        case GameState::MENU:
            UpdateMenu(deltaTime);
            break;
        case GameState::PLAYING:
            UpdateGame(deltaTime);
            break;
        case GameState::PAUSED:
            UpdatePause(deltaTime);
            break;
        case GameState::GAME_OVER:
            UpdateGameOver(deltaTime);
            break;
    }
}

void Game::Draw()
{
    BeginDrawing();
    ClearBackground(BLACK);

    switch(currentState) {
        case GameState::MENU: {
#ifdef _DEBUG
            static int menuDebugCount = 0;
            if(menuDebugCount++ < 3)
                std::cout << "Drawing MENU state" << std::endl;
#endif
            DrawMenu();
            break;
        }
        case GameState::PLAYING: {
#ifdef _DEBUG
            static int playDebugCount = 0;
            if(playDebugCount++ < 3)
                std::cout << "Drawing PLAYING state" << std::endl;
#endif
            DrawGame();
            break;
        }
        case GameState::PAUSED:
            DrawGame(); // Draw game in background
            DrawPause();
            break;
        case GameState::GAME_OVER:
            DrawGame(); // Draw game in background
            DrawGameOver();
            break;
    }

    EndDrawing();
}

void Game::UpdateMenu(float deltaTime)
{
    if(IsKeyPressed(KEY_ENTER) || IsKeyPressed(KEY_SPACE)) {
        StartNewGame();
    }

    if(IsKeyPressed(KEY_ESCAPE)) {
        isRunning = false;
    }
}

void Game::UpdateGame(float deltaTime)
{
    if(IsKeyPressed(KEY_ESCAPE)) {
        currentState = GameState::PAUSED;
        return;
    }

    // Switch background music with M key
    if(IsKeyPressed(KEY_M)) {
        AudioManager::GetInstance()->NextBackgroundTrack();
    }

    UpdateBackground(deltaTime);

    // Update audio
    AudioManager::GetInstance()->UpdateMusic();

    // Update player
    if(player && bulletManager) {
        player->Update(deltaTime, bulletManager.get());

        // Check if player is dead
        if(!player->IsActive()) {
            currentState = GameState::GAME_OVER;
            // Stop background music when player dies
            AudioManager::GetInstance()->StopBackgroundMusic();
        }
    }

    // Update bullets
    if(bulletManager) {
        bulletManager->Update(deltaTime);
    }

    // Check enemy bullet collisions with player
    if(bulletManager && player && player->IsActive()) {
        CheckEnemyBulletPlayerCollisions();
    }

    // Update enemies
    if(enemyManager && player && bulletManager) {
        enemyManager->Update(deltaTime, player.get(), bulletManager.get());
        // Update wave number from enemy manager
        wave = enemyManager->GetCurrentWave();
    }

    // Update power-ups
    if(powerUpManager && player) {
        powerUpManager->Update(deltaTime, player.get());
    }

    // Update explosions
    if(explosionManager) {
        explosionManager->Update(deltaTime);
    }
}

void Game::UpdatePause(float deltaTime)
{
    if(IsKeyPressed(KEY_ESCAPE)) {
        currentState = GameState::PLAYING;
    }

    if(IsKeyPressed(KEY_R)) {
        StartNewGame();
    }
}

void Game::UpdateGameOver(float deltaTime)
{
    if(IsKeyPressed(KEY_ENTER) || IsKeyPressed(KEY_SPACE)) {
        StartNewGame();
    }

    if(IsKeyPressed(KEY_ESCAPE)) {
        currentState = GameState::MENU;
    }
}

void Game::DrawMenu()
{
    DrawText("SPACE SHOOTER", SCREEN_WIDTH / 2 - 150, SCREEN_HEIGHT / 2 - 100, 40, WHITE);
    DrawText("Press ENTER to Start", SCREEN_WIDTH / 2 - 120, SCREEN_HEIGHT / 2 - 20, 20, GRAY);
    DrawText("Press ESC to Exit", SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 20, 20, GRAY);

    // Controls
    DrawText("Controls:", 50, SCREEN_HEIGHT / 2 + 80, 20, WHITE);
    DrawText("WASD/Arrows - Move", 50, SCREEN_HEIGHT / 2 + 110, 16, GRAY);
    DrawText("SPACE - Shoot", 50, SCREEN_HEIGHT / 2 + 130, 16, GRAY);
    DrawText("X - Supercharge Laser (2.8s warmup, 15s cooldown)", 50, SCREEN_HEIGHT / 2 + 150, 16,
             Color{255, 200, 100, 255});

    // Draw some stars for effect
    for(int i = 0; i < 50; i++) {
        int x = (i * 37) % SCREEN_WIDTH;
        int y = (i * 73) % SCREEN_HEIGHT;
        DrawPixel(x, y, WHITE);
    }
}

void Game::DrawGame()
{
    DrawBackground();

    // Draw player
    if(player) {
        player->Draw();
    }

    // Draw bullets
    if(bulletManager) {
        bulletManager->Draw();
    }

    // Draw enemies
    if(enemyManager) {
        enemyManager->Draw();
    }

    // Draw power-ups
    if(powerUpManager) {
        powerUpManager->Draw();
    }

    // Draw explosions
    if(explosionManager) {
        explosionManager->Draw();
    }

    // TODO: Draw effects, etc.

    DrawHUD();
}

void Game::DrawPause()
{
    // Semi-transparent overlay
    DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Color{0, 0, 0, 128});

    DrawText("PAUSED", SCREEN_WIDTH / 2 - 60, SCREEN_HEIGHT / 2 - 40, 30, WHITE);
    DrawText("Press ESC to Resume", SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2, 20, GRAY);
    DrawText("Press R to Restart", SCREEN_WIDTH / 2 - 90, SCREEN_HEIGHT / 2 + 30, 20, GRAY);
}

void Game::DrawGameOver()
{
    // Semi-transparent overlay
    DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Color{0, 0, 0, 128});

    DrawText("GAME OVER", SCREEN_WIDTH / 2 - 80, SCREEN_HEIGHT / 2 - 60, 30, RED);
    DrawText(TextFormat("Final Score: %d", score), SCREEN_WIDTH / 2 - 80, SCREEN_HEIGHT / 2 - 20, 20, WHITE);
    DrawText("Press ENTER to Restart", SCREEN_WIDTH / 2 - 110, SCREEN_HEIGHT / 2 + 20, 20, GRAY);
    DrawText("Press ESC for Main Menu", SCREEN_WIDTH / 2 - 110, SCREEN_HEIGHT / 2 + 50, 20, GRAY);
}

void Game::DrawHUD()
{
    // Draw health
    if(player) {
        Texture2D* heartTexture = ResourceManager::GetInstance()->GetTexture("heart");
        for(int i = 0; i < player->GetHealth(); i++) {
            if(heartTexture) {
                DrawTexture(*heartTexture, 10 + i * 35, 10, WHITE);
            } else {
                DrawRectangle(10 + i * 30, 10, 20, 20, RED);
            }
        }
    }

    // Draw score
    DrawText(TextFormat("Score: %d", score), SCREEN_WIDTH - 150, 10, 20, WHITE);
    DrawText(TextFormat("Wave: %d", wave), SCREEN_WIDTH - 150, 40, 20, WHITE);

    // Draw power-up status
    if(player && player->HasDoubleShot()) {
        DrawText("DOUBLE SHOT", 10, SCREEN_HEIGHT - 100, 16, YELLOW);
    }
    if(player && player->HasShield()) {
        DrawText("SHIELD", 10, SCREEN_HEIGHT - 80, 16, BLUE);
    }
    if(player && player->GetSpeedMultiplier() > 1.0f) {
        DrawText("SPEED BOOST", 10, SCREEN_HEIGHT - 60, 16, GREEN);
    }

    // Draw supercharge status
    if(player) {
        if(player->IsSuperchargeWarming()) {
            float warmupTime = player->GetSuperchargeWarmupTimer();
            DrawText(TextFormat("CANNON CHARGING... %.1fs", warmupTime), 10, SCREEN_HEIGHT - 40, 16,
                     Color{255, 200, 100, 255});
        } else if(player->IsSuperchargeActive()) {
            DrawText("SUPERCHARGE ACTIVE!", 10, SCREEN_HEIGHT - 40, 16, Color{255, 100, 100, 255});
        } else if(player->IsSuperchargeReady()) {
            DrawText("SUPERCHARGE READY! (Press X)", 10, SCREEN_HEIGHT - 40, 16, Color{100, 255, 100, 255});
        } else {
            float cooldown = player->GetSuperchargeCooldown();
            DrawText(TextFormat("Supercharge: %.1fs", cooldown), 10, SCREEN_HEIGHT - 40, 16, GRAY);
        }
    }
}

void Game::StartNewGame()
{
    ResetGame();
    currentState = GameState::PLAYING;

    // Start background music
    AudioManager::GetInstance()->StartBackgroundMusic();
}

void Game::AddScore(int points)
{
    score += points;
    std::cout << "[DEBUG] Score increased by " << points << ", total score: " << score << std::endl;
}

void Game::CheckEnemyBulletPlayerCollisions()
{
    if(!bulletManager || !player || !player->IsActive())
        return;

    // Get all enemy bullets
    std::vector<Bullet*> enemyBullets = bulletManager->GetEnemyBullets();
    Rectangle playerBounds = player->GetBounds();

    for(Bullet* bullet : enemyBullets) {
        if(!bullet || !bullet->IsActive())
            continue;

        Rectangle bulletBounds = bullet->GetBounds();

        // Check collision between enemy bullet and player
        if(CheckCollisionRecs(bulletBounds, playerBounds)) {
            // Damage the player
            player->TakeDamage(1);

            // Deactivate the bullet
            bullet->SetActive(false);

            std::cout << "[DEBUG] Enemy bullet hit player! Player health: " << player->GetHealth() << std::endl;
            break;
        }
    }
}

void Game::ResetGame()
{
    score = 0;
    wave = 1;

    if(player) {
        player->Reset();
    }

    if(bulletManager) {
        bulletManager->Clear();
    }

    if(enemyManager) {
        enemyManager->Reset();
    }

    if(powerUpManager) {
        powerUpManager->Reset();
    }

    if(explosionManager) {
        explosionManager->Clear();
    }
}

void Game::UpdateBackground(float deltaTime)
{
    const float scrollSpeed = 50.0f;

    backgroundY1 += scrollSpeed * deltaTime;
    backgroundY2 += scrollSpeed * deltaTime;

    // Reset background positions for seamless scrolling
    if(backgroundY1 >= SCREEN_HEIGHT) {
        backgroundY1 = backgroundY2 - SCREEN_HEIGHT;
    }
    if(backgroundY2 >= SCREEN_HEIGHT) {
        backgroundY2 = backgroundY1 - SCREEN_HEIGHT;
    }
}

void Game::DrawBackground()
{
    if(backgroundTexture) {
        DrawTexture(*backgroundTexture, 0, (int)backgroundY1, WHITE);
        DrawTexture(*backgroundTexture, 0, (int)backgroundY2, WHITE);
    } else {
        // Fallback: draw simple starfield
        for(int i = 0; i < 100; i++) {
            int x = (i * 37) % SCREEN_WIDTH;
            int y = ((i * 73) + (int)(GetTime() * 50)) % SCREEN_HEIGHT;
            DrawPixel(x, y, WHITE);
        }
    }
}
} // namespace SpaceShooter
