#include "game.h"
#include "input.h"
#include <math.h>
#include <ctime>
#include <cstring>

using namespace pwu;

// Forward decl
static void SpawnStar(Pool<StarItem, MAX_STARS>& pool, float x, float y);

// Wave generators (procedural SFX fallback)
// type: 0=sine  1=square  2=saw  3=triangle

Wave Game::GenWave(float freq, float duration, float decay, int type)
{
    const int sampleRate = 22050;
    const int frameCount = (int)(sampleRate * duration);
    Wave wave;
    wave.frameCount = frameCount;
    wave.sampleRate = sampleRate;
    wave.sampleSize = 16;
    wave.channels = 1;
    short* data = (short*)MemAlloc(frameCount * sizeof(short));
    if (!data) { wave.data = nullptr; return wave; }

    for (int i = 0; i < frameCount; i++)
    {
        float t = (float)i / sampleRate;
        float env = 1.0f - t / duration * decay;
        if (env < 0) env = 0;
        float phase = t * freq;
        float val = 0;
        switch (type)
        {
        case 0: val = (float)sin(phase * 2.0 * PI); break;
        case 1: val = (float)sin(phase * 2.0 * PI) > 0 ? 1.0f : -1.0f; break;
        case 2: val = 2.0f * (float)(phase - floor(phase + 0.5)); break;
        case 3: val = 2.0f * (float)fabs(2.0 * (phase - floor(phase + 0.5))) - 1.0f; break;
        }
        data[i] = (short)(val * env * 16000);
    }
    wave.data = data;
    return wave;
}

Sound Game::LoadProceduralSound(float freq, float duration, float decay, int type)
{
    Wave w = GenWave(freq, duration, decay, type);
    if (!w.data) { Sound s = { 0 }; return s; }
    Sound s = LoadSoundFromWave(w);
    UnloadWave(w);
    return s;
}

// ==================================================================
//  Init / Close
// ==================================================================

void Game::Init()
{
    InitWindow(SCREEN_W, SCREEN_H, "Plane War Ultimate");
    InitAudioDevice();
    SetTargetFPS(TARGET_FPS);

    LoadResources();
    ui.Init();
    LoadLeaderboard();
    SetMasterVolume(ui.volumeSetting);

    // Try loading external wave config, fall back to built-in
    waveManager.LoadFromJSON("resources/waves.json");

    player.Init();
    playerBullets.Init();
    bossBullets.Init();
    enemies.Init();
    particles.Init();
    powerups.Init();
    stars.Init();
    boss.active = false;
    bossDefeated = false;
}

void Game::LoadResources()
{
    // Load textures individually - each entity falls back to
    // procedural art independently if its own texture is missing.
    if (FileExists("resources/player.png"))
        playerTex = LoadTexture("resources/player.png");

    if (FileExists("resources/enemy.png"))
        enemyTex = LoadTexture("resources/enemy.png");

    if (FileExists("resources/background.png"))
        bgTex = LoadTexture("resources/background.png");

    // Sounds -- load from file OR generate procedurally
    if (FileExists("resources/shoot.wav"))
        shootSound = LoadSound("resources/shoot.wav");
    else
        shootSound = LoadProceduralSound(800, 0.08f, 0.7f, 1);

    if (FileExists("resources/explode.wav"))
        explodeSound = LoadSound("resources/explode.wav");
    else
        explodeSound = LoadProceduralSound(60, 0.35f, 0.9f, 0);

    if (FileExists("resources/sounds/misc/error.wav"))
        hurtSound = LoadSound("resources/sounds/misc/error.wav");
    else
        hurtSound = LoadProceduralSound(180, 0.25f, 0.8f, 2);

    if (FileExists("resources/sounds/powerups/1.wav"))
        powerupSound = LoadSound("resources/sounds/powerups/1.wav");
    else
        powerupSound = LoadProceduralSound(400, 0.18f, 0.5f, 0);

    if (FileExists("resources/sounds/misc/alarm.wav"))
        alarmSound = LoadSound("resources/sounds/misc/alarm.wav");
    else
        alarmSound = LoadProceduralSound(300, 0.5f, 0.4f, 1);

    // BGM - stream from file, or silence
    if (FileExists("resources/bgm.mp3"))
    {
        bgm   = LoadMusicStream("resources/bgm.mp3");
        bgmOk = true;
    }
    else if (FileExists("resources/bgm.ogg"))
    {
        bgm   = LoadMusicStream("resources/bgm.ogg");
        bgmOk = true;
    }
    else
    {
        bgmOk = false;
    }
}

void Game::Close()
{
    if (playerTex.id != 0) UnloadTexture(playerTex);
    if (enemyTex.id != 0)  UnloadTexture(enemyTex);
    if (bgTex.id != 0)     UnloadTexture(bgTex);
    UnloadSound(shootSound);
    UnloadSound(explodeSound);
    UnloadSound(hurtSound);
    UnloadSound(powerupSound);
    UnloadSound(alarmSound);
    if (bgmOk) UnloadMusicStream(bgm);
    CloseAudioDevice();
    CloseWindow();
}

// ==================================================================
//  High score persistence
// ==================================================================

void Game::LoadHighScore()
{
    FILE* f = fopen(HIGH_SCORE_FILE, "r");
    if (f)
    {
        fscanf_s(f, "%d %d", &highScore, &highLevel);
        fclose(f);
    }
    else
    {
        highScore = 0;
        highLevel = 0;
    }
}

void Game::SaveHighScore()
{
    FILE* f = fopen(HIGH_SCORE_FILE, "w");
    if (f)
    {
        fprintf(f, "%d %d\n", highScore, highLevel);
        fclose(f);
    }
}

// ==================================================================
//  Screen shake
// ==================================================================

void Game::TriggerShake(float intensity, float duration)
{
    if (intensity > shakeIntensity)
    {
        shakeIntensity = intensity;
        shakeTimer = duration;
    }
}

void Game::UpdateShake()
{
    if (shakeTimer > 0)
    {
        shakeTimer -= GetFrameTime() * 60.0f;
        if (shakeTimer <= 0)
            shakeIntensity = 0;
    }
}

// ==================================================================
//  Combo
// ==================================================================

void Game::UpdateCombo(bool enemyKilled)
{
    if (enemyKilled)
    {
        combo++;
        comboTimer = (float)COMBO_DECAY_FRAMES;
        if (combo > maxCombo) maxCombo = combo;
    }
}

// ==================================================================
//  State dispatch
// ==================================================================

void Game::Update()
{
    // Keep music stream fed
    if (bgmOk) UpdateMusicStream(bgm);

    // Global hotkeys
    if (Input::FullscreenToggle())
    {
        ToggleFullscreen();
    }
    if (Input::MuteToggle())
    {
        if (ui.volumeSetting > 0.01f)
            ui.volumeSetting = 0;
        else
            ui.volumeSetting = DEFAULT_VOLUME;
        SetMasterVolume(ui.volumeSetting);
    }

    switch (state)
    {
    case GameState::MENU:
        if (!ui.UpdateMenu(state))
            quitRequested = true;
        if (state == GameState::PLAYING && bgmOk)
        {
            StopMusicStream(bgm);
            PlayMusicStream(bgm);
        }
        break;

    case GameState::SETTINGS:
        ui.UpdateSettings(state, difficulty);
        break;

    case GameState::LEADERBOARD:
        if (Input::Back())
            state = GameState::MENU;
        break;

    case GameState::PLAYING:
        UpdatePlaying();
        break;

    case GameState::PAUSED:
    {
        GameState prevPause = state;
        ui.UpdatePaused(state);
        if (ui.pauseWantsRestart)
        {
            ui.pauseWantsRestart = false;
            RestartGame();
        }
        if (state == GameState::MENU && prevPause == GameState::PAUSED && bgmOk)
            StopMusicStream(bgm);
        break;
    }

    case GameState::GAMEOVER:
    {
        GameState prev = state;
        ui.UpdateGameOver(state);
        if (prev == GameState::GAMEOVER && state == GameState::PLAYING)
            RestartGame();
        if (state == GameState::MENU && bgmOk)
            StopMusicStream(bgm);
        break;
    }
    }
}

// ==================================================================
//  Playing
// ==================================================================

void Game::UpdatePlaying()
{
    if (Input::Pause())
    {
        state = GameState::PAUSED;
        ui.pauseSelection = 0;
        return;
    }

    // Boss death slow-motion
    if (bossDeathTimer > 0)
    {
        float dtFrames = GetFrameTime() * 60.0f;
        bossDeathTimer -= dtFrames;
        screenFlashAlpha *= (float)pow(0.88, dtFrames);

        float halfDeath = BOSS_DEATH_FRAMES / 2.0f;
        if (!bossDeathMidShakeDone && bossDeathTimer <= halfDeath)
        {
            bossDeathMidShakeDone = true;
            TriggerShake(SHAKE_BOSS_DEATH_INT * 1.5f, 30);
        }
    }

    float dtFrames = GetFrameTime() * 60.0f;
    gameTimer += GetFrameTime();   // seconds for display

    UpdateDifficulty();
    UpdateBackground();
    UpdateShake();

    player.Update(playerBullets, shootSound, totalShots,
                   laserX, laserActive, laserTimer);

    // Bomb key - same effect as bomb powerup
    if (Input::Bomb() && player.bombCount > 0)
    {
        player.bombCount--;
        // Clear all enemies
        for (int j = 0; j < MAX_ENEMIES; j++)
        {
            if (enemies.items[j].active)
            {
                float ex = enemies.items[j].x + enemies.items[j].GetSize() / 2.0f;
                float ey = enemies.items[j].y + enemies.items[j].GetSize() / 2.0f;
                CreateExplosion(particles, ex, ey);
                enemies.items[j].active = false;
                totalKills++;
                UpdateCombo(true);
                SpawnStar(stars, ex, ey);
            }
        }
        bossBullets.Clear();
        // Spawn shockwaves from player position
        float swx = player.x + PLAYER_SIZE / 2.0f;
        float swy = player.y + PLAYER_SIZE / 2.0f;
        for (int s = 0; s < MAX_SHOCKWAVES; s++)
        {
            shockwaves[s].x = swx; shockwaves[s].y = swy;
            shockwaves[s].radius = 10.0f; shockwaves[s].maxRadius = 300.0f + s * 60.0f;
            shockwaves[s].alpha = 1.0f - s * 0.2f; shockwaves[s].active = true;
        }
        if (boss.active)
        {
            boss.TakeDamage(); boss.TakeDamage(); boss.TakeDamage();
            CreateExplosion(particles, boss.x + BOSS_W / 2.0f, boss.y + BOSS_H / 2.0f);
            TriggerShake(SHAKE_EXPLOSION_INT, SHAKE_EXPLOSION_DUR);
            if (!boss.active)
            {
                score += (int)(BOSS_SCORE * scoreMultiplier); if (midBossActive) midBossActive = false; else bossDefeated = true; totalKills++;
                bossDeathTimer = (float)BOSS_DEATH_FRAMES; bossDeathMidShakeDone = false;
                screenFlashAlpha = 1.0f;
                CreateExplosion(particles, boss.x + BOSS_W / 2.0f, boss.y + BOSS_H / 2.0f);
                TriggerShake(SHAKE_BOSS_DEATH_INT, SHAKE_BOSS_DEATH_DUR);
            }
        }
        PlayGameSfx(explodeSound);
    }

    SpawnEnemies();

    UpdatePlayerBullets();
    UpdateBossBullets();

    // Combo decay
    if (comboTimer > 0)
    {
        comboTimer -= dtFrames;
        if (comboTimer <= 0) combo = 0;
    }

    for (int i = 0; i < MAX_ENEMIES; i++)
    {
        if (enemies.items[i].active)
        {
            enemies.items[i].Update(enemySpeed);
        }
    }

    // Mid-boss trigger (waves 3 and 7)
    int currentWaveNum = waveManager.CurrentWave();
    if ((currentWaveNum == 3 || currentWaveNum == 7) && !boss.active && !midBossActive)
    {
        midBossActive = true;
        boss.Init(1);  // Destroyer-type as mid-boss
        boss.hp = BOSS_HP / 3;
        PlayGameSfx(alarmSound);
    }

    // Boss wave trigger
    if (waveManager.BossTriggered() && !boss.active)
    {
        midBossActive = false;
        static int bossSeq = 0;
        boss.Init(bossSeq % 3);
        bossSeq++;
        boss.hp = (int)(BOSS_HP * GetBossHpMultiplier());
        bossDefeated = false;
        waveManager.ClearBossTrigger();
        PlayGameSfx(alarmSound);
    }

    if (boss.active)
    {
        boss.Update(bossBullets, player.x, player.y);
    }

    // Shockwave update
    for (int i = 0; i < MAX_SHOCKWAVES; i++)
    {
        if (shockwaves[i].active)
        {
            shockwaves[i].radius += 8.0f * dtFrames;
            shockwaves[i].alpha  -= 0.025f * dtFrames;
            if (shockwaves[i].radius >= shockwaves[i].maxRadius || shockwaves[i].alpha <= 0)
                shockwaves[i].active = false;
        }
    }

    // Star update - magnetic toward player
    float px = player.x + PLAYER_SIZE / 2.0f;
    float py = player.y + PLAYER_SIZE / 2.0f;
    for (int i = 0; i < MAX_STARS; i++)
    {
        if (stars.items[i].active)
        {
            float dx = px - stars.items[i].x;
            float dy = py - stars.items[i].y;
            float dist = sqrtf(dx * dx + dy * dy) + 1.0f;
            stars.items[i].x += dx / dist * 4.0f * dtFrames;
            stars.items[i].y += dy / dist * 4.0f * dtFrames;
            stars.items[i].life -= 0.01f * dtFrames;
            if (dist < 25.0f || stars.items[i].life <= 0)
            {
                stars.items[i].active = false;
                if (dist < 25.0f) { chain++; chainTimer = 120.0f; }
            }
        }
    }
    if (chainTimer > 0) { chainTimer -= dtFrames; if (chainTimer <= 0) chain = 0; }
    scoreMultiplier = 1.0f + (float)chain * 0.02f;
    if (scoreMultiplier > 5.0f) scoreMultiplier = 5.0f;
    if (grazeTimer > 0) grazeTimer -= dtFrames;

    UpdateParticles(particles);

    for (int i = 0; i < MAX_POWERUPS; i++)
    {
        if (powerups.items[i].active)
        {
            powerups.items[i].Update();
        }
    }

    CheckCollisions();

    // Extend check
    if (score >= nextExtendScore && player.hp > 0)
    {
        if (player.hp < PLAYER_MAX_HP) player.hp++;
        nextExtendScore += EXTEND_INTERVAL;
        PlayGameSfx(powerupSound);
        // Brief flash and message shown via HUD
    }

    if (player.hp <= 0)
    {
        int lvl = enemySpeed - INITIAL_ENEMY_SPEED;
        int acc = totalShots > 0 ? (int)((float)totalHits / totalShots * 100) : 0;
        AddToLeaderboard(score, (int)difficulty, waveManager.CurrentWave(),
                         totalKills, acc);
        player.bombCount = 3;  // refill on death

        state = GameState::GAMEOVER;
    }
}

void Game::RestartGame()
{
    score = 0;
    nextExtendScore = FIRST_EXTEND_SCORE;
    enemySpeed = INITIAL_ENEMY_SPEED;
    gameTimer = 0;
    difficultyAccum = 0;
    bgY = 0;
    bossDefeated = false;
    midBossActive = false;
    combo = 0;
    comboTimer = 0;
    maxCombo = 0;
    chain = 0; chainTimer = 0; scoreMultiplier = 1.0f;
    grazeCount = 0; grazeTimer = 0; totalGrazes = 0;
    totalShots = 0;
    totalHits = 0;
    totalKills = 0;
    shakeTimer = 0;
    shakeIntensity = 0;
    bossDeathTimer = 0;
    bossDeathMidShakeDone = false;
    screenFlashAlpha = 0;
    for (int i = 0; i < MAX_SHOCKWAVES; i++) shockwaves[i].active = false;

    player.Init();
    playerBullets.Clear();
    bossBullets.Clear();
    enemies.Clear();
    particles.Clear();
    powerups.Clear();
    stars.Clear();
    boss.active = false;
    waveManager.Restart();
}

// ==================================================================
//  Difficulty helpers
// ==================================================================

int Game::GetEnemySpeedCap() const
{
    switch (difficulty)
    {
    case Difficulty::EASY:    return ENEMY_SPEED_CAP_EASY;
    case Difficulty::NORMAL:  return ENEMY_SPEED_CAP_NORMAL;
    case Difficulty::HARD:    return ENEMY_SPEED_CAP_HARD;
    case Difficulty::LUNATIC: return ENEMY_SPEED_CAP_LUNATIC;
    default:                  return ENEMY_SPEED_CAP_NORMAL;
    }
}

float Game::GetBossHpMultiplier() const
{
    switch (difficulty)
    {
    case Difficulty::EASY:    return BOSS_HP_MULT_EASY;
    case Difficulty::NORMAL:  return BOSS_HP_MULT_NORMAL;
    case Difficulty::HARD:    return BOSS_HP_MULT_HARD;
    case Difficulty::LUNATIC: return BOSS_HP_MULT_LUNATIC;
    default:                  return BOSS_HP_MULT_NORMAL;
    }
}

int Game::GetSpawnRate() const
{
    switch (difficulty)
    {
    case Difficulty::EASY:    return SPAWN_RATE_EASY;
    case Difficulty::NORMAL:  return SPAWN_RATE_NORMAL;
    case Difficulty::HARD:    return SPAWN_RATE_HARD;
    case Difficulty::LUNATIC: return SPAWN_RATE_LUNATIC;
    default:                  return SPAWN_RATE_NORMAL;
    }
}

// ==================================================================
//  Sub-updates
// ==================================================================

void Game::UpdateBackground()
{
    bgY += BG_SCROLL_SPEED * GetFrameTime() * 60.0f;
    if (bgY >= SCREEN_H) bgY = 0;
}

void Game::UpdateDifficulty()
{
    const float difficultyPeriod = DIFFICULTY_INTERVAL / 60.0f;
    difficultyAccum += GetFrameTime();
    while (difficultyAccum >= difficultyPeriod)
    {
        difficultyAccum -= difficultyPeriod;
        if (enemySpeed < GetEnemySpeedCap())
            enemySpeed++;
    }
}

void Game::SpawnEnemies()
{
    // Count active enemies (including boss) for wave manager
    int alive = 0;
    for (int i = 0; i < MAX_ENEMIES; i++)
        if (enemies.items[i].active) alive++;
    if (boss.active) alive++;

    float dt = GetFrameTime();
    float sx, sy;
    EnemyKind kind;

    if (waveManager.ShouldSpawnNow(dt, alive, sx, sy, kind))
    {
        Enemy* e = enemies.Acquire();
        if (e)
        {
            int size = 0;
            switch (kind)
            {
            case EnemyKind::SMALL:  size = ENEMY_SMALL_SIZE;  break;
            case EnemyKind::MEDIUM: size = ENEMY_MEDIUM_SIZE; break;
            case EnemyKind::LARGE:  size = ENEMY_LARGE_SIZE;  break;
            }
            e->Init(kind, sx - size / 2.0f, sy);
        }
    }
}

void Game::UpdatePlayerBullets()
{
    float dtFrames = GetFrameTime() * 60.0f;
    for (int i = 0; i < MAX_BULLETS; i++)
    {
        if (playerBullets.items[i].active)
        {
            playerBullets.items[i].x += playerBullets.items[i].speedX * dtFrames;
            playerBullets.items[i].y += playerBullets.items[i].speedY * dtFrames;
            playerBullets.items[i].trailTimer++;

            if (playerBullets.items[i].y < -20 ||
                playerBullets.items[i].x < -20 ||
                playerBullets.items[i].x > SCREEN_W + 20)
            {
                playerBullets.items[i].active = false;
            }
        }
    }
}

void Game::UpdateBossBullets()
{
    float dtFrames = GetFrameTime() * 60.0f;
    for (int i = 0; i < MAX_BOSS_BULLETS; i++)
    {
        if (bossBullets.items[i].active)
        {
            bossBullets.items[i].x += bossBullets.items[i].speedX * dtFrames;
            bossBullets.items[i].y += bossBullets.items[i].speedY * dtFrames;
            bossBullets.items[i].trailTimer++;

            if (bossBullets.items[i].y > SCREEN_H + 20 ||
                bossBullets.items[i].x < -20 ||
                bossBullets.items[i].x > SCREEN_W + 20)
            {
                bossBullets.items[i].active = false;
            }
        }
    }
}

// ==================================================================
//  Collisions
// ==================================================================

void Game::CheckCollisions()
{
    Rectangle pb = player.GetBounds();

    // -- Laser vs enemies (piercing beam) ---
    if (laserActive)
    {
        Rectangle laserRect = { laserX - 6, -100, 12, (float)SCREEN_H + 200 };
        for (int j = 0; j < MAX_ENEMIES; j++)
        {
            if (!enemies.items[j].active) continue;
            if (CheckCollisionRecs(laserRect, enemies.items[j].GetBounds()))
            {
                bool killed = false;
                enemies.items[j].hp -= 3;  // heavy damage
                if (enemies.items[j].hp <= 0)
                {
                    enemies.items[j].active = false;
                    totalKills++;
                    int baseScore = enemies.items[j].GetScore();
                    float mult = 1.0f;
                    if (combo >= COMBO_DISPLAY_MIN)
                        mult = 1.0f + (combo - COMBO_DISPLAY_MIN + 1) * 0.1f;
                    score += (int)(baseScore * mult * scoreMultiplier);
                    killed = true;
                }
                float ex = enemies.items[j].x + enemies.items[j].GetSize() / 2.0f;
                float ey = enemies.items[j].y + enemies.items[j].GetSize() / 2.0f;
                CreateExplosion(particles, ex, ey);
                totalHits++;
                UpdateCombo(killed);
                if (killed) { TrySpawnPowerUp(powerups, ex, ey); SpawnStar(stars, ex, ey); }
            }
        }
        // Laser vs boss
        if (boss.active && CheckCollisionRecs(laserRect, boss.GetBounds()))
        {
            boss.TakeDamage(); boss.TakeDamage();
            CreateExplosion(particles, laserX, boss.y + BOSS_H / 2.0f);
            totalHits++;
            TriggerShake(SHAKE_EXPLOSION_INT, SHAKE_EXPLOSION_DUR);
            if (!boss.active)
            {
                score += (int)(BOSS_SCORE * scoreMultiplier); if (midBossActive) midBossActive = false; else bossDefeated = true;
                totalKills++; UpdateCombo(true);
                bossDeathTimer = (float)BOSS_DEATH_FRAMES; bossDeathMidShakeDone = false;
                screenFlashAlpha = 1.0f;
                CreateExplosion(particles, boss.x + BOSS_W / 2.0f, boss.y + BOSS_H / 2.0f);
                TriggerShake(SHAKE_BOSS_DEATH_INT, SHAKE_BOSS_DEATH_DUR);
            }
        }
    }

    // -- PowerUps ---------------------------

    for (int i = 0; i < MAX_POWERUPS; i++)
    {
        if (!powerups.items[i].active) continue;

        if (CheckCollisionRecs(pb, powerups.items[i].GetBounds()))
        {
            PowerUpKind kind = powerups.items[i].kind;
            powerups.items[i].active = false;

            switch (kind)
            {
            case PowerUpKind::HEAL:
                if (player.hp < PLAYER_MAX_HP) player.hp++;
                break;

            case PowerUpKind::TRIPLE:
                player.tripleTimer = (float)TRIPLE_SHOT_DURATION;
                break;

            case PowerUpKind::BOMB:
            {
                // Spawn shockwave rings from pickup position
                float swx = powerups.items[i].x;
                float swy = powerups.items[i].y;
                for (int s = 0; s < MAX_SHOCKWAVES; s++)
                {
                    if (!shockwaves[s].active)
                    {
                        shockwaves[s].x = swx;
                        shockwaves[s].y = swy;
                        shockwaves[s].radius = 10.0f;
                        shockwaves[s].maxRadius = 300.0f + s * 60.0f;
                        shockwaves[s].alpha = 1.0f - s * 0.2f;
                        shockwaves[s].active = true;
                    }
                }
                for (int j = 0; j < MAX_ENEMIES; j++)
                {
                    if (enemies.items[j].active)
                    {
                        float ex = enemies.items[j].x + enemies.items[j].GetSize() / 2.0f;
                        float ey = enemies.items[j].y + enemies.items[j].GetSize() / 2.0f;
                        CreateExplosion(particles, ex, ey);
                        enemies.items[j].active = false;
                        totalKills++;
                        UpdateCombo(true);
                        SpawnStar(stars, ex, ey);
                    }
                }
                bossBullets.Clear();
                if (boss.active)
                {
                    boss.TakeDamage(); boss.TakeDamage(); boss.TakeDamage();
                    CreateExplosion(particles, boss.x + BOSS_W / 2.0f, boss.y + BOSS_H / 2.0f);
                    TriggerShake(SHAKE_EXPLOSION_INT, SHAKE_EXPLOSION_DUR);
                    if (!boss.active)
                    {
                        score += (int)(BOSS_SCORE * scoreMultiplier);
                        bossDefeated = true;
                        totalKills++;
                        bossDeathTimer = (float)BOSS_DEATH_FRAMES;
                        bossDeathMidShakeDone = false;
                        screenFlashAlpha = 1.0f;
                        CreateExplosion(particles, boss.x + BOSS_W / 2.0f, boss.y + BOSS_H / 2.0f);
                        CreateExplosion(particles, boss.x + BOSS_W / 4.0f, boss.y + BOSS_H / 3.0f);
                        CreateExplosion(particles, boss.x + BOSS_W * 3.0f / 4.0f, boss.y + BOSS_H / 3.0f);
                        TriggerShake(SHAKE_BOSS_DEATH_INT, SHAKE_BOSS_DEATH_DUR);
                    }
                }
                PlayGameSfx(explodeSound);
                break;
            }  // end bomb scope
            }

            PlayGameSfx(powerupSound);
        }
    }

    // -- Player bullets vs enemies ----------

    for (int i = 0; i < MAX_BULLETS; i++)
    {
        if (!playerBullets.items[i].active) continue;

        Rectangle bb = {
            playerBullets.items[i].x - BULLET_GLOW_RADIUS,
            playerBullets.items[i].y - BULLET_GLOW_RADIUS,
            BULLET_GLOW_RADIUS * 2,
            BULLET_GLOW_RADIUS * 2
        };

        for (int j = 0; j < MAX_ENEMIES; j++)
        {
            if (!enemies.items[j].active) continue;

            // Spatial early-out
            if (fabsf(playerBullets.items[i].y - enemies.items[j].y) > 100.0f) continue;

            if (CheckCollisionRecs(bb, enemies.items[j].GetBounds()))
            {
                playerBullets.items[i].active = false;
                totalHits++;

                bool killed = false;
                enemies.items[j].hp--;
                if (enemies.items[j].hp <= 0)
                {
                    enemies.items[j].active = false;
                    totalKills++;
                    int baseScore = enemies.items[j].GetScore();
                    float mult = 1.0f;
                    if (combo >= COMBO_DISPLAY_MIN)
                        mult = 1.0f + (combo - COMBO_DISPLAY_MIN + 1) * 0.1f;
                    score += (int)(baseScore * mult * scoreMultiplier);
                    killed = true;
                }

                PlayGameSfx(explodeSound);

                float ex = enemies.items[j].x + enemies.items[j].GetSize() / 2.0f;
                float ey = enemies.items[j].y + enemies.items[j].GetSize() / 2.0f;
                CreateExplosion(particles, ex, ey);
                TriggerShake(SHAKE_EXPLOSION_INT, SHAKE_EXPLOSION_DUR);
                UpdateCombo(killed);

                if (killed)
                {
                    TrySpawnPowerUp(powerups, ex, ey);
                    SpawnStar(stars, ex, ey);
                }
                break;
            }
        }
    }

    // -- Player bullets vs boss -------------

    if (boss.active)
    {
        Rectangle bossBounds = boss.GetBounds();

        for (int i = 0; i < MAX_BULLETS; i++)
        {
            if (!playerBullets.items[i].active) continue;

            Rectangle bb = {
                playerBullets.items[i].x - BULLET_GLOW_RADIUS,
                playerBullets.items[i].y - BULLET_GLOW_RADIUS,
                BULLET_GLOW_RADIUS * 2,
                BULLET_GLOW_RADIUS * 2
            };

            if (CheckCollisionRecs(bb, bossBounds))
            {
                playerBullets.items[i].active = false;
                totalHits++;
                boss.TakeDamage();

                CreateExplosion(particles, playerBullets.items[i].x, playerBullets.items[i].y);
                PlayGameSfx(explodeSound);
                TriggerShake(SHAKE_EXPLOSION_INT, SHAKE_EXPLOSION_DUR);

                if (!boss.active)
                {
                    score += (int)(BOSS_SCORE * scoreMultiplier);
                    bossDefeated = true;
                    totalKills++;
                    UpdateCombo(true);
                    bossDeathTimer = (float)BOSS_DEATH_FRAMES;
                    bossDeathMidShakeDone = false;
                    screenFlashAlpha = 1.0f;
                    CreateExplosion(particles, boss.x + BOSS_W / 2.0f, boss.y + BOSS_H / 2.0f);
                    CreateExplosion(particles, boss.x + BOSS_W / 4.0f, boss.y + BOSS_H / 3.0f);
                    CreateExplosion(particles, boss.x + BOSS_W * 3.0f / 4.0f, boss.y + BOSS_H / 3.0f);
                    TriggerShake(SHAKE_BOSS_DEATH_INT, SHAKE_BOSS_DEATH_DUR);
                    TrySpawnPowerUp(powerups, boss.x + BOSS_W / 2.0f, boss.y + BOSS_H / 2.0f);
                    TrySpawnPowerUp(powerups, boss.x + BOSS_W / 4.0f, boss.y + BOSS_H / 2.0f);
                    TrySpawnPowerUp(powerups, boss.x + BOSS_W * 3.0f / 4.0f, boss.y + BOSS_H / 2.0f);
                }
            }
        }
    }

    // -- Player vs enemies ------------------

    if (!player.IsInvincible())
    {
        for (int i = 0; i < MAX_ENEMIES; i++)
        {
            if (!enemies.items[i].active) continue;
            if (fabsf(player.y - enemies.items[i].y) > 200.0f) continue;

            Rectangle eb = enemies.items[i].GetBounds();

            if (CheckCollisionRecs(pb, eb))
            {
                enemies.items[i].active = false;
                player.TakeDamage();

                float ex = enemies.items[i].x + enemies.items[i].GetSize() / 2.0f;
                float ey = enemies.items[i].y + enemies.items[i].GetSize() / 2.0f;
                CreateExplosion(particles, ex, ey);
                TriggerShake(SHAKE_DAMAGE_INT, SHAKE_DAMAGE_DUR);

                PlayGameSfx(hurtSound);
                if (player.hp <= 0) return;
            }
            else if (grazeTimer <= 0)
            {
                // Near-miss graze (within 30px of hitbox but not colliding)
                Rectangle nearBox = { pb.x - 15, pb.y - 15, pb.width + 30, pb.height + 30 };
                if (CheckCollisionRecs(nearBox, eb))
                {
                    grazeCount++; totalGrazes++;
                    score += (int)(10 * (grazeCount / 5 + 1) * scoreMultiplier);
                    grazeTimer = 15.0f;
                }
            }
        }

        // -- Player vs boss ------------------

        if (boss.active)
        {
            if (CheckCollisionRecs(pb, boss.GetBounds()))
            {
                player.TakeDamage();
                TriggerShake(SHAKE_DAMAGE_INT, SHAKE_DAMAGE_DUR);
                PlayGameSfx(hurtSound);
                if (player.hp <= 0) return;
            }
        }

        // -- Player vs boss bullets ----------

        for (int i = 0; i < MAX_BOSS_BULLETS; i++)
        {
            if (!bossBullets.items[i].active) continue;

            // Spatial early-out
            if (fabsf(player.y - bossBullets.items[i].y) > 200.0f) continue;

            Rectangle bb = {
                bossBullets.items[i].x - BULLET_GLOW_RADIUS,
                bossBullets.items[i].y - BULLET_GLOW_RADIUS,
                BULLET_GLOW_RADIUS * 2,
                BULLET_GLOW_RADIUS * 2
            };

            if (CheckCollisionRecs(pb, bb))
            {
                bossBullets.items[i].active = false;
                player.TakeDamage();
                CreateExplosion(particles, bossBullets.items[i].x, bossBullets.items[i].y);
                TriggerShake(SHAKE_DAMAGE_INT, SHAKE_DAMAGE_DUR);
                PlayGameSfx(hurtSound);
                if (player.hp <= 0) return;
            }
        }
    }
}

// ==================================================================
//  Draw
// ==================================================================

void Game::Draw()
{
    BeginDrawing();
    ClearBackground(BLACK);

    if (state == GameState::LEADERBOARD)
    {
        DrawLeaderboard();
    }
    else if (state == GameState::MENU || state == GameState::SETTINGS)
    {
        ui.DrawMenuBackground();

        if (state == GameState::MENU)
            ui.DrawMenu(highScore, highLevel);
        else
            ui.DrawSettings(difficulty);
    }
    else
    {
        // Scrolling background
        if (bgTex.id != 0)
        {
            DrawTexture(bgTex, 0, (int)bgY, WHITE);
            DrawTexture(bgTex, 0, (int)bgY - SCREEN_H, WHITE);
        }
        else
        {
            DrawStarfield();
        }

        // Screen shake offset
        float shakeX = 0, shakeY = 0;
        if (shakeTimer > 0)
        {
            float decay = shakeTimer / (shakeTimer + 5.0f);
            shakeX = GetRandomValue(-100, 100) / 100.0f * shakeIntensity * decay;
            shakeY = GetRandomValue(-100, 100) / 100.0f * shakeIntensity * decay;
        }

        Camera2D cam = { 0 };
        cam.offset = { shakeX, shakeY };
        cam.target = { 0, 0 };
        cam.rotation = 0;
        cam.zoom = 1.0f;

        BeginMode2D(cam);
        DrawGameLayer();
        EndMode2D();

        ui.DrawScreenFlash(screenFlashAlpha);

        int lvl = enemySpeed - INITIAL_ENEMY_SPEED;
        int tripleSecs = player.tripleTimer > 0
            ? (int)((player.tripleTimer + 59.0f) / 60.0f) : 0;
        ui.DrawHUD(score, player.hp, tripleSecs, totalKills, lvl,
                   waveManager.CurrentWave(), player.bombCount,
                   chain, scoreMultiplier, grazeCount, boss.active);

        if (boss.active)
            ui.DrawBossHPBar(boss.hp, BOSS_HP);

        ui.DrawComboPopup(combo, comboTimer);

        if (state == GameState::PAUSED)
            ui.DrawPauseOverlay();

        if (state == GameState::GAMEOVER)
            ui.DrawGameOverOverlay(score, highScore, highLevel,
                                   enemySpeed, totalKills, totalShots,
                                   totalHits, maxCombo, (int)gameTimer);
    }

    EndDrawing();
}

// -- Starfield (fallback when no background texture) ----------------

void Game::DrawStarfield() const
{
    for (int i = 0; i < STARFIELD_COUNT; i++)
    {
        DrawCircle(
            (int)ui.stars[i].x, (int)ui.stars[i].y,
            (int)ui.stars[i].size,
            Fade(WHITE, ui.stars[i].alpha)
        );
    }
}

// -- Game layer (shake-affected) -----------------------------------

void Game::DrawGameLayer()
{
    player.Draw(playerTex);

    // Laser beam
    if (laserActive)
    {
        float flicker = 0.8f + (float)fabs(sin(GetTime() * 40.0)) * 0.2f;
        // Outer glow
        DrawRectangle((int)(laserX - 8), -50, 16, SCREEN_H + 100, Fade(SKYBLUE, 0.2f * flicker));
        // Mid glow
        DrawRectangle((int)(laserX - 4), -50, 8, SCREEN_H + 100, Fade(BLUE, 0.5f * flicker));
        // Core
        DrawRectangle((int)(laserX - 1), -50, 2, SCREEN_H + 100, Fade(WHITE, 0.9f * flicker));
    }

    for (int i = 0; i < MAX_BULLETS; i++)
    {
        if (playerBullets.items[i].active)
        {
            ui.DrawBullet(playerBullets.items[i].x, playerBullets.items[i].y, GOLD);
        }
    }

    for (int i = 0; i < MAX_ENEMIES; i++)
    {
        if (enemies.items[i].active)
        {
            enemies.items[i].Draw(enemyTex);
        }
    }

    boss.Draw();

    for (int i = 0; i < MAX_BOSS_BULLETS; i++)
    {
        if (bossBullets.items[i].active)
        {
            ui.DrawBullet(bossBullets.items[i].x, bossBullets.items[i].y, RED);
        }
    }

    DrawParticles(particles);

    // Star items (gold coins)
    for (int i = 0; i < MAX_STARS; i++)
    {
        if (stars.items[i].active)
        {
            int sx = (int)stars.items[i].x, sy = (int)stars.items[i].y;
            float pulse = 1.0f + (float)sin(GetTime() * 8.0 + i) * 0.2f;
            DrawCircle(sx, sy, 4.0f * pulse, GOLD);
            DrawCircle(sx, sy, 2.0f * pulse, Fade(YELLOW, 0.8f));
        }
    }

    // Shockwave rings
    for (int i = 0; i < MAX_SHOCKWAVES; i++)
    {
        if (shockwaves[i].active)
        {
            float r  = shockwaves[i].radius;
            float a  = shockwaves[i].alpha;
            int   sx = (int)shockwaves[i].x;
            int   sy = (int)shockwaves[i].y;
            // Outer glow ring
            DrawRing({ (float)sx, (float)sy }, r - 6, r + 6, 0, 360, 64, Fade(SKYBLUE, a * 0.5f));
            // Inner bright ring
            DrawRing({ (float)sx, (float)sy }, r - 2, r + 2, 0, 360, 64, Fade(WHITE, a * 0.8f));
        }
    }

    for (int i = 0; i < MAX_POWERUPS; i++)
    {
        if (powerups.items[i].active)
        {
            powerups.items[i].Draw();
        }
    }
}

// ==================================================================
//  Audio helper
// ==================================================================

// Helper: spawn stars at position
static void SpawnStar(Pool<StarItem, MAX_STARS>& pool, float x, float y)
{
    StarItem* s = pool.Acquire();
    if (s) { s->x = x; s->y = y; s->life = 3.0f; }
}

void Game::PlayGameSfx(Sound& snd)
{
    SetSoundVolume(snd, ui.sfxVolume);
    PlaySound(snd);
}

// ==================================================================
//  Leaderboard
// ==================================================================

void Game::LoadLeaderboard()
{
    leaderboardCount = 0;
    FILE* f = fopen("leaderboard.dat", "r");
    if (!f) return;
    char line[128];
    while (leaderboardCount < LEADERBOARD_SIZE && fgets(line, sizeof(line), f))
    {
        Entry& e = leaderboard[leaderboardCount];
        char diffStr[16];
        if (sscanf_s(line, "%d %15s %d %d %d %19[^\n]",
                      &e.score, diffStr, (unsigned)sizeof(diffStr),
                      &e.wave, &e.kills, &e.accuracy, e.date, (unsigned)sizeof(e.date)) >= 5)
        {
            e.difficulty = (strcmp(diffStr, "EASY") == 0) ? 0 :
                           (strcmp(diffStr, "HARD") == 0) ? 2 :
                           (strcmp(diffStr, "LUNATIC") == 0) ? 3 : 1;
            leaderboardCount++;
        }
    }
    fclose(f);
    // Update high score from leaderboard
    highScore = leaderboardCount > 0 ? leaderboard[0].score : 0;
    highLevel = leaderboardCount > 0 ? leaderboard[0].wave : 0;
}

void Game::SaveLeaderboard()
{
    FILE* f = fopen("leaderboard.dat", "w");
    if (!f) return;
    const char* diffNames[] = { "EASY", "NORMAL", "HARD", "LUNATIC" };
    for (int i = 0; i < leaderboardCount; i++)
    {
        Entry& e = leaderboard[i];
        fprintf(f, "%d %s %d %d %d %s\n",
                e.score, diffNames[e.difficulty], e.wave, e.kills, e.accuracy, e.date);
    }
    fclose(f);
}

void Game::AddToLeaderboard(int score, int difficulty, int wave, int kills, int accuracy)
{
    // Build date string
    char dateBuf[20];
    time_t now = time(nullptr);
    struct tm t;
    localtime_s(&t, &now);
    strftime(dateBuf, sizeof(dateBuf), "%Y-%m-%d", &t);

    // Insert sorted by score descending
    Entry newEntry = { score, difficulty, wave, kills, accuracy };
    strcpy_s(newEntry.date, dateBuf);

    int pos = leaderboardCount;
    while (pos > 0 && leaderboard[pos - 1].score < score) pos--;

    if (leaderboardCount < LEADERBOARD_SIZE) leaderboardCount++;
    for (int i = leaderboardCount - 1; i > pos; i--)
        leaderboard[i] = leaderboard[i - 1];
    if (pos < LEADERBOARD_SIZE) leaderboard[pos] = newEntry;

    highScore = leaderboard[0].score;
    highLevel = leaderboard[0].wave;
    SaveLeaderboard();
}

void Game::DrawLeaderboard() const
{
    ClearBackground(BLACK);
    DrawText("LEADERBOARD", 240, 30, 40, GOLD);
    DrawLine(200, 75, 600, 75, Fade(GRAY, 0.4f));

    // Header
    DrawText("RANK  SCORE   DIFF      WAVE  KILLS  ACC   DATE",
             80, 95, 16, GRAY);

    const char* diffNames[] = { "EASY", "NORMAL", "HARD", "LUNATIC" };
    for (int i = 0; i < leaderboardCount; i++)
    {
        const Entry& e = leaderboard[i];
        int y = 120 + i * 38;
        Color c = (i == 0) ? GOLD : (i < 3) ? SKYBLUE : WHITE;

        DrawText(TextFormat("#%d", i + 1), 85, y, 22, c);
        DrawText(TextFormat("%d", e.score), 135, y, 22, c);
        DrawText(diffNames[e.difficulty], 240, y, 22, c);
        DrawText(TextFormat("%d", e.wave), 355, y, 22, c);
        DrawText(TextFormat("%d", e.kills), 430, y, 22, c);
        DrawText(TextFormat("%d%%", e.accuracy), 500, y, 22, c);
        DrawText(e.date, 565, y, 20, GRAY);
    }

    if (leaderboardCount == 0)
        DrawText("No entries yet - go play!", 220, 300, 24, GRAY);

    float blink = (float)fabs(sin(GetTime() * 3.0));
    DrawText("ESC to return", 310, 555, 20, Fade(YELLOW, 0.5f + blink * 0.5f));
}
