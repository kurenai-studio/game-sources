#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <raylib.h>
#include <stdbool.h>
#include <math.h>
#include <rlgl.h>
#include <time.h>

// テクスチャ画像，音声ファイルなどを読み込む変数
static Texture2D box1, box2, box3, box4, hooker, sand, shower, stone, tile, wall; 
static Texture2D aimTex, playerTex, playerTex_walk, gunTex, currentPlayerTex, enemyTex, gunTex_enemy;
static Texture2D bombTex1, bombTex2, smokeTex, magazineTex, dashTex;
static Sound shootSound1, shootSoundCopy1, shootSound2, shootSoundCopy2, explosionSound;
static Sound stepSound1, blinkSound, plantSound1, plantSound2, noammoSound, reloadSound, defuseSound;
static Sound killSound1, killSound2, killSound3, killSound4, killSound5;

// 試合の状態を表す変数たち
static Difficulty currentDiff;

static Player player;
static Enemy enemies[5];
static Bullet bullets[MAX_BULLETS];
static Camera2D camera;
static Image mapImage;
static Bomb bomb;
static Smoke smokes[NUM_SMOKE];
static RenderTexture2D mask1, mask2, mask3;

static Vector2 points[512]; 
static Vector2 nextPos;
static Vector2 mouseWorldPos;
static Vector2 mouseScreenPos;
static Vector2 LineOfSight;

static float spread;
static float shootDuration;
static float currentSpeed;
static float fovRad;
static float angleRad;
static float walk_timer;
static float frameTime;
static float val1, val2, val3, val4;
static float smokeFreezeTimer;


static int fovCount;
static int map[MAP_ROWS][MAP_COLS];
static int distMap[MAP_ROWS][MAP_COLS];
static int tx, ty;
static int player_frame;
static int shootCount;
static int killCount;

static double dashStart;
static double angle, angle_enemy, angleRad_enemy;
static double reloadTimer;
static double sinceDash;

static bool isPlantSite;
static bool distMapCreated;
static bool existDefusing;
static bool gameFinished;
static bool isInitialized;
static bool resourcesLoaded;

static void LoadResources(void)
{
    // map画像の読み込み
    mapImage = LoadImage("resources/map/map_a.png");

    // textureの読み込み
    box1 = LoadTexture("resources/texture/box1.png");
    box2 = LoadTexture("resources/texture/box2.png");
    box3 = LoadTexture("resources/texture/box3.png");
    box4 = LoadTexture("resources/texture/box4.png");
    hooker = LoadTexture("resources/texture/hooker.png");
    sand = LoadTexture("resources/texture/sand.png");
    shower = LoadTexture("resources/texture/shower.png");
    stone = LoadTexture("resources/texture/stone.png");
    tile = LoadTexture("resources/texture/tile.png");
    wall = LoadTexture("resources/texture/wall.png");

    aimTex = LoadTexture("resources/texture/aim.png");
    playerTex = LoadTexture("resources/texture/player.png");
    playerTex_walk = LoadTexture("resources/texture/player_walk.png");
    gunTex = LoadTexture("resources/texture/gun.png");
    currentPlayerTex = playerTex;
    enemyTex = LoadTexture("resources/texture/enemy.png");
    gunTex_enemy = LoadTexture("resources/texture/gun_enemy.png");
    bombTex1 = LoadTexture("resources/texture/bomb1.png");
    bombTex2 = LoadTexture("resources/texture/bomb2.png");
    smokeTex = LoadTexture("resources/texture/smoke.png");
    magazineTex = LoadTexture("resources/texture/magazine.png");
    dashTex = LoadTexture("resources/texture/dash.png");

    // 音声の読み込み
    shootSound1 = LoadSound("resources/audio/shot1.wav");
    shootSoundCopy1 = LoadSoundAlias(shootSound1);
    shootSound2 = LoadSound("resources/audio/shot2.wav");
    shootSoundCopy2 = LoadSoundAlias(shootSound2);
    explosionSound = LoadSound("resources/audio/explosion.wav");
    stepSound1 = LoadSound("resources/audio/step1.wav");
    blinkSound  = LoadSound("resources/audio/blink.wav");
    plantSound1 = LoadSound("resources/audio/plant1.wav");
    plantSound2 = LoadSound("resources/audio/plant2.wav");
    noammoSound = LoadSound("resources/audio/noammo.wav");
    reloadSound = LoadSound("resources/audio/reload.wav");
    killSound1 = LoadSound("resources/audio/kill1.wav");
    killSound2 = LoadSound("resources/audio/kill2.wav");
    killSound3 = LoadSound("resources/audio/kill3.wav");
    killSound4 = LoadSound("resources/audio/kill4.wav");
    killSound5 = LoadSound("resources/audio/kill5.wav");
    defuseSound = LoadSound("resources/audio/defuse.wav");
}

void InitMatchState()
{
    // 難易度の調整（アビリティの数，弾の拡散率，敵の発射速度）
    switch (currentDiff) {
        case EASY: 
            player = (Player){ {611, 515}, 0.0f, 150, 25, 3, 3, 3, false, false, false, false, false};
            spread = 0.8f;
            shootDuration = 1.0f;
            break;
        case NORMAL:
            player = (Player){ {611, 515}, 0.0f, 150, 25, 2, 2, 2, false, false, false, false, false};
            spread = 0.3f;
            shootDuration = 0.5f;
            break;
        case HARD:
            player = (Player){ {611, 515}, 0.0f, 150, 25, 1, 1, 1, false, false, false, false, false};
            spread = 0.0f;
            shootDuration = 0.1f;
            break;
    }

    // enemyはじめの初期化（ランダムスポーン）
    static Vector2 candidates[15] = {
        {606.0f, 460.0f}, {610.0f, 348.0f}, {611.0f, 418.0f}, {816.0f, 336.0f}, {566.0f, 269.0f},
        {727.0f, 261.0f}, {963.0f, 291.0f}, {1002.0f, 131.0f}, {831.0f, 128.0f}, {744.0f, 131.0f},
        {682.0f, 140.0f}, {890.0f, 66.0f}, {968.0f, 64.0f}, {674.0f, 307.0f}, {676.0f, 407.0f}
    };
    shuffleArray(candidates, 15);
    for (int i = 0; i < 5; i++) {
        enemies[i] = (Enemy){candidates[i], 150, true, GUARDING, 0.0f};
    }

    for (int i = 0; i < MAX_BULLETS; i++) bullets[i] = (Bullet){(Vector2){-1.0f, -1.0f}, (Vector2){0.0f, 0.0f}, false, false};

    initCamera(&camera, &player);

    loadMap(mapImage, map);

    bomb = (Bomb){{0, 0}, BOMB_CARRY, 0.0f, 0.0f, false};

    for (int i = 0; i < NUM_SMOKE; i++) smokes[i] = (Smoke){ {0}, 0.0f, false};

    mask1 = LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT);
    mask2 = LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT);
    mask3 = LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT);

    nextPos = player.position;
    mouseWorldPos = (Vector2){0, 0};
    mouseScreenPos= (Vector2){0, 0};

    currentSpeed = MOVE_SPEED / FPS;
    fovRad = FOV * (PI / 100.0f);
    walk_timer = 0.0f;
    frameTime = 0.14f;
    val1 = 0.0f;
    val2 = 0.0f;
    val3 = 0.0f;
    val4 = 0.0f;
    smokeFreezeTimer = 0.0f;

    fovCount = 0;
    // distMapの初期化
    for (int y = 0; y < MAP_ROWS; y++) {
        for (int x = 0; x < MAP_COLS; x++) distMap[y][x] = -1;
    }
    tx = 0;
    ty = 0;
    player_frame = 0;
    shootCount = 25;
    killCount = 0;

    dashStart = 0.0;
    reloadTimer = 0.0f;
    sinceDash = 1.0f;

    distMapCreated = false;
    existDefusing = false;
    gameFinished = false;
    isInitialized = true;
    resourcesLoaded = true;
}

// 実際に呼び出される初期化関数
void Init1v5(Difficulty diff)
{
    // 難易度設定の更新
    currentDiff = diff;

    // カーソルを非表示にする．
    HideCursor();

    // randを使うための初期化
    srand((unsigned int)time(NULL));

    if (!isInitialized) { 
        // resourcesを読み込む
        if (!resourcesLoaded) {
            LoadResources();
            resourcesLoaded = true;
        }

        // 変数を初期化
        InitMatchState();
    }
}


void Update1v5(void)
{
    if (!isInitialized) Init1v5(currentDiff);
    
    // 死亡時は処理を停止
    if (player.isDead) return;
    
    mouseScreenPos = GetMousePosition();
    mouseWorldPos = GetScreenToWorld2D(mouseScreenPos, camera);

    // 1. カメラの位置とプレイヤーの角度計算
    angleCalculate(&camera, &player, &angleRad, &LineOfSight, mouseWorldPos);

    // 2. 視野を表現するための処理
    GetFovPoints(player, map, points, smokes, &fovCount); // 実行するとfovCountは計算された頂点に置き換わる

    // 3. 弾の管理
    // 3.1. 射撃すると → 弾生成 & 速度減少 & カメラブレる
    bool isMoving = false;
    val1 *= 0.9;
    val2 *= 0.9;
    if (shootCount > 0) shootCount--;
    if (IsMouseButtonDown(MOUSE_BUTTON_LEFT) && !player.isPlanting && !player.isPlanningSmoke && !player.isReloading && smokeFreezeTimer <= 0 && !gameFinished) {
        // 速度減少
        currentSpeed = MOVE_SPEED / FPS - WEIGHT_SPEED / FPS;
        // 弾生成
        if (IsKeyDown(KEY_W) || IsKeyDown(KEY_A) || IsKeyDown(KEY_S) || IsKeyDown(KEY_D)) {
            isMoving = true;
        }

        if (player.ammo > 0) { generateBullet(&player, &shootCount, bullets, angleRad, isMoving, shootSound1, shootSoundCopy1); }

        // カメラブレる
        val1 = -5.0f + 10.0f * ((float)rand() / (float)RAND_MAX);
        val2 = -5.0f + 10.0f * ((float)rand() / (float)RAND_MAX);
    } else if (player.isReloading && sinceDash >= 0.5f) {
        currentSpeed = MOVE_SPEED / FPS - WEIGHT_SPEED / FPS;
    } else {
        currentSpeed = MOVE_SPEED / FPS;
    }
    if (player.ammo > 0) {
        camera.offset.x = SCREEN_WIDTH / 2 + val1;
        camera.offset.y = SCREEN_HEIGHT / 2 + val2;
    }

    if (player.ammo <= 0 && IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && !player.isPlanting && !player.isPlanningSmoke && !player.isReloading && smokeFreezeTimer <= 0) {
        PlaySound(noammoSound);
    }

    // 3.2. 弾を動かす 死亡処理もここでする
    moveBullet(&player, bullets, enemies, map, &killCount, killSound1, killSound2, killSound3, killSound4, killSound5, currentDiff);
    
    // 3.3. リロード処理
    reload(&player, &reloadTimer, reloadSound);

    // 4. プレイヤーの管理

    // 4.1. 移動
    if (IsKeyPressed(KEY_LEFT_SHIFT) && player.dash > 0 && !gameFinished) { // ダッシュを使うとスピード激増
        PlaySound(blinkSound);
        dashStart = GetTime(); 
        player.dash--;
    }
    

    double tmp = currentSpeed;
    sinceDash = GetTime() - dashStart;
    if (sinceDash < 0.2) { currentSpeed *= 8;}
    else if (sinceDash > 0.2 && sinceDash < 0.4) { currentSpeed /= 8;}
    else if (sinceDash > 0.4) { currentSpeed = tmp; sinceDash = 1.0; }

    nextPos = player.position;
    if (!player.isPlanting && !gameFinished) {
        if (IsKeyDown(KEY_W) && !IsKeyDown(KEY_A) && !IsKeyDown(KEY_S) && !IsKeyDown(KEY_D)) { nextPos.y -= currentSpeed; }
        else if (!IsKeyDown(KEY_W) && IsKeyDown(KEY_A) && !IsKeyDown(KEY_S) && !IsKeyDown(KEY_D)) { nextPos.x -= currentSpeed; }
        else if (!IsKeyDown(KEY_W) && !IsKeyDown(KEY_A) && IsKeyDown(KEY_S) && !IsKeyDown(KEY_D)) { nextPos.y += currentSpeed; }
        else if (!IsKeyDown(KEY_W) && !IsKeyDown(KEY_A) && !IsKeyDown(KEY_S) && IsKeyDown(KEY_D)) { nextPos.x += currentSpeed; }
        else if (IsKeyDown(KEY_W) && IsKeyDown(KEY_A) && !IsKeyDown(KEY_S) && !IsKeyDown(KEY_D)) { nextPos.y -= COS45 * currentSpeed; nextPos.x -= COS45 * currentSpeed; } // 斜め移動は速度を調整
        else if (!IsKeyDown(KEY_W) && IsKeyDown(KEY_A) && IsKeyDown(KEY_S) && !IsKeyDown(KEY_D)) { nextPos.x -= COS45 * currentSpeed; nextPos.y += COS45 * currentSpeed; }
        else if (IsKeyDown(KEY_W) && !IsKeyDown(KEY_A) && !IsKeyDown(KEY_S) && IsKeyDown(KEY_D)) { nextPos.y -= COS45 * currentSpeed; nextPos.x += COS45 * currentSpeed; }
        else if (!IsKeyDown(KEY_W) && !IsKeyDown(KEY_A) && IsKeyDown(KEY_S) && IsKeyDown(KEY_D)) { nextPos.y += COS45 * currentSpeed; nextPos.x += COS45 * currentSpeed; }
    }

    

    Vector2 checkPoints[4] = {{nextPos.x + PLAYER_SIZE/2, nextPos.y + PLAYER_SIZE/2}, 
                                {nextPos.x + PLAYER_SIZE/2, nextPos.y - PLAYER_SIZE/2}, 
                                {nextPos.x - PLAYER_SIZE/2, nextPos.y + PLAYER_SIZE/2}, 
                                {nextPos.x - PLAYER_SIZE/2, nextPos.y - PLAYER_SIZE/2}};
    bool canMove = true;

    for (int i = 0; i < 4; i++) {
        int tileX = (int)(checkPoints[i].x / TILE_SIZE);
        int tileY = (int)(checkPoints[i].y / TILE_SIZE);
        if (0 <= tileX && tileX < MAP_COLS && 0 <= tileY && tileY < MAP_ROWS) {
            if (map[tileY][tileX] == 1 || map[tileY][tileX] == 9 || map[tileY][tileX] == 10) canMove = false;
        }
    }

    if (canMove) player.position = nextPos;

    // 移動中，テクスチャを切り替える
    if (!player.isPlanting && !gameFinished && (IsKeyDown(KEY_W) || IsKeyDown(KEY_A) || IsKeyDown(KEY_S) || IsKeyDown(KEY_D))) {
        walk_timer += GetFrameTime();
        if (walk_timer >= frameTime) {
            player_frame = (player_frame + 1) % 2; // 0と1をswap
            if (player_frame == 1) PlaySound(stepSound1);
            walk_timer = 0.0f;
        }
    } else {
        player_frame = 0;
    }

    // 4.2. 体力管理
    if (player.health <= 0) {
        player.isDead = true;
        player.health = 0;
    }
    

    // 5. 爆弾の管理
    val3 = -2.0f + 4.0f * ((float)rand() / (float)RAND_MAX);
    val4 = -2.0f + 4.0f * ((float)rand() / (float)RAND_MAX);
    tx = player.position.x / TILE_SIZE;
    ty = player.position.y / TILE_SIZE;
    if (map[ty][tx] == 4 || map[ty][tx] == 5) { isPlantSite = true; }
    else { isPlantSite = false; }

    maintainBomb(&player, enemies, &bomb, isPlantSite, explosionSound, plantSound1, plantSound2, defuseSound, &distMapCreated, map, distMap, existDefusing);
    
    // 6. 敵のAI更新（視認したら撃つ）
    existDefusing = false;
    for (int i = 0; i < 5; i++) {
        if (enemies[i].active) {
            updateEnemyAI(&enemies[i], &player, bullets, map, distMap, smokes, shootSound2, shootSoundCopy2, &existDefusing, spread, shootDuration, killCount, &bomb);
        }
    }

    // 7. スモークの管理
    maintainSmoke(&player, smokes, mouseWorldPos, &smokeFreezeTimer);
    if (smokeFreezeTimer > 0) smokeFreezeTimer -= GetFrameTime();
    

    // 8. マスクの管理（視野を実現）
    // -------------------------------視野内のエンティティを処理するマスク---------------------------------------
    BeginTextureMode(mask1);
        ClearBackground(BLANK);

        BeginMode2D(camera);

        rlColorMask(false, false, false, true);
        DrawTriangleFan(points, fovCount, (Color){255, 255, 255, 255}); // 視野の透明度情報だけ保存する
        rlColorMask(true, true, true, true);

        rlSetBlendFactors(RL_DST_ALPHA, RL_ZERO, RL_FUNC_ADD);
        rlSetBlendMode(BLEND_CUSTOM);
        // 明るいマップを表示
        for (int y = 0; y < MAP_ROWS; y++) {
            for (int x = 0; x < MAP_COLS; x++) {
                if(map[y][x] == 1) { DrawTexture(wall, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 2) { DrawTexture(sand, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 3) { DrawTexture(stone, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 4) { DrawTexture(stone, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 5) { DrawTexture(sand, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 6) { DrawTexture(tile, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 7) { DrawTexture(hooker, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 8) { DrawTexture(shower, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 9) { DrawTexture(box1, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else if (map[y][x] == 10) { DrawTexture(box2, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                else { printf("map format is incorrect.\n"); exit(1); }
            }
        }
        DrawRectangleLines(66 * TILE_SIZE, 13 * TILE_SIZE, 14 * TILE_SIZE, 9 * TILE_SIZE, WHITE);
        // DrawRectangleLines(21 * TILE_SIZE, 14 * TILE_SIZE, 13 * TILE_SIZE, 7 * TILE_SIZE, WHITE);
        DrawTexture(box3, 65 * TILE_SIZE, 19 * TILE_SIZE, GRAY);
        DrawTexture(box4, 73 * TILE_SIZE, 15 * TILE_SIZE, GRAY);

        // 視野内の弾を表示
        for (int i = 0; i < MAX_BULLETS; i++) {
            if (bullets[i].active) {
                Vector2 trailEnd = {
                    bullets[i].position.x - 2.0f * bullets[i].speed.x,
                    bullets[i].position.y - 2.0f * bullets[i].speed.y
                };
                DrawLineEx(bullets[i].position, trailEnd, 1.0f, Fade(GOLD, 0.5)); // 弾道のみ表示
            }
        }

        // 視野内の敵を表示
        for (int j = 0; j < 5; j++) {
            if (enemies[j].active) { 
                angleRad_enemy = atan2f(player.position.y - enemies[j].position.y, player.position.x - enemies[j].position.x);
                angle_enemy = angleRad_enemy * (180.0f / PI);

                rlSetBlendFactors(RL_DST_ALPHA, RL_ONE_MINUS_SRC_ALPHA, RL_FUNC_ADD);
                rlSetBlendMode(BLEND_CUSTOM);

                if (-90 <= angle_enemy && angle_enemy <= 90) {
                    DrawTexturePro(enemyTex, 
                                    (Rectangle){0, 0, 32.0f, 32.0f}, 
                                    (Rectangle){enemies[j].position.x - 16.0f, enemies[j].position.y - 16.0f, 32.0f, 32.0f}, 
                                    (Vector2){0.0f, 0.0f}, 
                                    0.0f, 
                                    WHITE
                                );

                    DrawTexturePro(gunTex_enemy, 
                                    (Rectangle){0, 0, 64.0f, 64.0f}, 
                                    (Rectangle){enemies[j].position.x, enemies[j].position.y + 3.5f, 32.0f, 32.0f}, 
                                    (Vector2){16.0f, 16.0f}, 
                                    angle_enemy, 
                                    WHITE);
                } else {
                    DrawTexturePro(enemyTex, 
                                    (Rectangle){0, 0, -32.0f, 32.0f}, 
                                    (Rectangle){enemies[j].position.x - 16.0f, enemies[j].position.y - 16.0f, 32.0f, 32.0f}, 
                                    (Vector2){0.0f, 0.0f}, 
                                    0.0f, 
                                    WHITE);

                    DrawTexturePro(gunTex_enemy, 
                                    (Rectangle){0, 0, 64.0f, -64.0f}, 
                                    (Rectangle){enemies[j].position.x, enemies[j].position.y + 3.5f, 32.0f, 32.0f}, 
                                    (Vector2){16.0f, 16.0f}, 
                                    angle_enemy, 
                                    WHITE);
                }

                // 敵のHPバー
                if (enemies[j].health != 150) {
                    DrawRectangle(enemies[j].position.x - 7.0f, enemies[j].position.y + 10.0f, 15, 2, BLACK); 
                    DrawRectangle(enemies[j].position.x - 7.3f, enemies[j].position.y + 9.7f, 15 * enemies[j].health / 150, 2, GREEN);
                }
            }
        }

        rlSetBlendMode(BLEND_ALPHA);

        EndMode2D();
    EndTextureMode();

    // --------------------------視野外を暗くするためのマスク-------------------------------------
    BeginTextureMode(mask2);
        // 画面全体を黒く表示する
        ClearBackground((Color){0, 0, 0, 50});

        // (カメラモードに)
        BeginMode2D(camera);

        // 視野内を切り抜いて完全に透明にする
        rlSetBlendFactors(RL_ZERO, RL_ONE_MINUS_SRC_ALPHA, RL_FUNC_ADD);
        rlSetBlendMode(BLEND_CUSTOM);
        DrawTriangleFan(points, fovCount, WHITE);

        rlSetBlendMode(BLEND_ALPHA);
        EndMode2D();
    EndTextureMode();

    // スモーク内では全てを暗くする
    // -------------mask3------------
    BeginTextureMode(mask3);
        ClearBackground((Color){0, 0, 0, 50});
    EndTextureMode();

}

void Draw1v5(void)
{
    ClearBackground(BLACK);
    // -----------カメラモードON--------------
    BeginMode2D(camera);
    // マップの表示
    for (int y = 0; y < MAP_ROWS; y++) {
                for (int x = 0; x < MAP_COLS; x++) {
                    if(map[y][x] == 1) { DrawTexture(wall, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 2) { DrawTexture(sand, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 3) { DrawTexture(stone, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 4) { DrawTexture(stone, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 5) { DrawTexture(sand, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 6) { DrawTexture(tile, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 7) { DrawTexture(hooker, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 8) { DrawTexture(shower, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 9) { DrawTexture(box1, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else if (map[y][x] == 10) { DrawTexture(box2, x * TILE_SIZE, y * TILE_SIZE, GRAY); }
                    else { printf("map format is incorrect.\n"); exit(1); }
                }
            }
            DrawRectangleLines(66 * TILE_SIZE, 13 * TILE_SIZE, 14 * TILE_SIZE, 9 * TILE_SIZE, WHITE);
            DrawTexture(box3, 65 * TILE_SIZE, 19 * TILE_SIZE, GRAY);
            DrawTexture(box4, 73 * TILE_SIZE, 15 * TILE_SIZE, GRAY);
    EndMode2D();
    //----------------OFF-----------------

    
    if (!player.isInSmoke) {
        // mask1の表示
        DrawTextureRec(
            mask1.texture, 
            (Rectangle){ 0, 0, (float)mask1.texture.width, (float)-mask1.texture.height },
            (Vector2){0, 0},
            WHITE
        );
        //mask2の表示
        DrawTextureRec(
            mask2.texture, 
            (Rectangle){ 0, 0, (float)mask2.texture.width, (float)-mask2.texture.height },
            (Vector2){0, 0},
            WHITE
        );
    } else {
        DrawTextureRec(
            mask3.texture, 
            (Rectangle){ 0, 0, (float)mask3.texture.width, (float)-mask3.texture.height },
            (Vector2){0, 0},
            WHITE
        );;
    }
    
    


    // -----------カメラモードON--------------
    BeginMode2D(camera);

    // 爆弾を表示
    if (bomb.state == BOMB_PLANTED || bomb.state == BOMB_DEFUSING) {
        if (bomb.explosionTimer > 5.0f) { 
            DrawTexture(bombTex1, bomb.position.x - 16.0f, bomb.position.y - 10.0f, WHITE); 
        } else { 
            DrawTexture(bombTex2, bomb.position.x - 16.0f + val3, bomb.position.y - 10.0f + val4, WHITE);
        }

        DrawRectangle(bomb.position.x - 7.0f, bomb.position.y + 10.0f, 15, 2, BLACK); 
        DrawRectangle(bomb.position.x - 7.3f, bomb.position.y + 9.7f, 15 * bomb.defuseTimer / 4, 2, BLUE);
    
    }

    // プレイヤーを表示
    if (!player.isDead) {
        angle = angleRad * 180 / PI;
        currentPlayerTex = (player_frame == 0) ? playerTex : playerTex_walk;
        if (-90 <= angle && angle <= 90) {
            DrawTexturePro(currentPlayerTex, 
                            (Rectangle){0, 0, 32.0f, 32.0f}, 
                            (Rectangle){player.position.x - 16.0f, player.position.y - 16.0f, 32.0f, 32.0f}, 
                            (Vector2){0.0f, 0.0f}, 
                            0.0f, 
                            WHITE);

            DrawTexturePro(gunTex, 
                        (Rectangle){0, 0, 64.0f, 64.0f}, 
                        (Rectangle){player.position.x, player.position.y + 3.5f, 32.0f, 32.0f}, 
                        (Vector2){16.0f, 16.0f}, 
                        angle, 
                        WHITE);

        } else {
            DrawTexturePro(currentPlayerTex, 
                            (Rectangle){0, 0, -32.0f, 32.0f}, 
                            (Rectangle){player.position.x - 16.0f, player.position.y - 16.0f, 32.0f, 32.0f}, 
                            (Vector2){0.0f, 0.0f}, 
                            0.0f, 
                            WHITE);

            DrawTexturePro(gunTex, 
                            (Rectangle){0, 0, 64.0f, -64.0f}, 
                            (Rectangle){player.position.x, player.position.y + 3.5f, 32.0f, 32.0f}, 
                            (Vector2){16.0f, 16.0f}, 
                            angle, 
                            WHITE);
        }
    }

    // スモークを表示
            if (player.isPlanningSmoke) {
                DrawCircleV(mouseWorldPos, 30.0f, Fade(BROWN, 0.2f));
                DrawCircleLinesV(mouseWorldPos, 30.0f, BLACK);
            }

            for (int i = 0; i < NUM_SMOKE; i++) {
                if (smokes[i].active) {
                // 徐々に消える演出（タイマーに合わせる）
                float alpha = (smokes[i].timer > 1.0f) ? 1.0f : (smokes[i].timer * 0.8f);
                DrawTexture(smokeTex, smokes[i].position.x - 32.0f, smokes[i].position.y - 32.0f,Fade(WHITE, alpha));
            }
            }

    EndMode2D();
    // ---------------OFF--------------------
    
    // カーソルの表示（死亡時は非表示）
    if (!player.isDead) {
        DrawTexture(aimTex, mouseScreenPos.x - 7, mouseScreenPos.y - 7, WHITE); // textureが15x15なので，中心を合わせるために-7
    }

    // プレイヤーの体力とマガジン数，アビリティの数表示
    DrawText(TextFormat("HP: %d/150", player.health), 10, 10, 20, WHITE);
    DrawRectangle(10, 35, 200, 15, BLACK);
    DrawRectangle(10, 35, 200 * player.health / 150, 15, (player.health > 75) ? GREEN : (player.health > 37) ? YELLOW : RED);
    DrawText(TextFormat("Ammo: %d/25", player.ammo), 150, 10, 20, WHITE);
    
    for (int i = 0; i < player.magazine; i++) DrawTexture(magazineTex, 350 + 40 * i, 10, WHITE);

    for (int i = 0; i < player.smoke; i++) {
        DrawTexturePro(smokeTex, 
                        (Rectangle){0.0f, 0.0f, 64.0f, 64.0f},
                        (Rectangle){350 + 40 * i, 50, 32.0f, 32.0f},
                        (Vector2){0.0f, 0.0f},
                        0.0f,
                        WHITE
                    );    
    }

    // --- リロード中UI ---
    if (player.isReloading && !player.isDead) {
        int barWidth = 100;
        int barHeight = 10;
        int posX = SCREEN_WIDTH/2 - barWidth/2;
        int posY = SCREEN_HEIGHT/2 + 50;

        DrawText("RELOADING...", posX, posY - 20, 20, BLACK);
        DrawRectangle(posX, posY, barWidth, barHeight, GRAY); 
        DrawRectangle(posX, posY, (int)(barWidth * (reloadTimer / 3.0f)), barHeight, YELLOW); 
    }

    for (int i = 0; i < player.dash; i++) DrawTexture(dashTex, 350 + 40 * i, 90, WHITE);

    // 死亡時のRETRYボタン
    if (player.isDead) {
        gameFinished = true;
        DrawRetryButton("YOU ARE DEAD...", "RETRY", &isInitialized, currentDiff);
    }

    // 爆破後のRETRYボタン（もしくは敵を全員倒す)
    if (bomb.state == BOMB_EXPLODED || killCount >= 5) {
        gameFinished = true;
        DrawRetryButton("YOU WIN!", "PLAY AGAIN?", &isInitialized, currentDiff);
    }

    // 解除後のRETRYボタン
    if (bomb.state == BOMB_DEFUSED) {
        gameFinished = true;
        DrawRetryButton("BOMB HAS BEEN DEFUSED...", "RETRY", &isInitialized, currentDiff);
    }

    // 爆弾設置UI（死亡時は非表示）
    if (!player.isDead) {
        if (bomb.state == BOMB_PLANTING) {
            DrawText("PLANTING...", SCREEN_WIDTH/2 - 50, SCREEN_HEIGHT/2 + 30, 20, BLACK);
            DrawRectangle(SCREEN_WIDTH/2 - 50, SCREEN_HEIGHT/2 + 50, 100, 10, GRAY);
            DrawRectangle(SCREEN_WIDTH/2 - 50, SCREEN_HEIGHT/2 + 50, (int)(100 * (bomb.explosionTimer / PLANT_DURATION)), 10, BLUE);
        }
        else if (bomb.state == BOMB_PLANTED || bomb.state == BOMB_DEFUSING) {
            DrawText(TextFormat("BOMB: %.2f", bomb.explosionTimer), SCREEN_WIDTH/2 - 60, 50, 30, RED);
        }
        else {
            int tileX = (int)(player.position.x / TILE_SIZE);
            int tileY = (int)(player.position.y / TILE_SIZE);
            if (tileX >= 0 && tileX < MAP_COLS && tileY >= 0 && tileY < MAP_ROWS) {
                if ((map[tileY][tileX] == 4 || map[tileY][tileX] == 5) && bomb.state == BOMB_CARRY && killCount < 5) {
                    DrawText("PRESS 'F' TO PLANT THE BOMB.",SCREEN_WIDTH / 2 - 170.0f, SCREEN_HEIGHT / 2 + 40.0f, 20, WHITE); 
                }
            }
        }
    }
}

void Unload1v5(void)
{
    if (isInitialized) {
        // 画像リソース
        UnloadImage(mapImage); // これを忘れるとメモリに残ります

        // テクスチャ
        UnloadTexture(box1); UnloadTexture(box2); UnloadTexture(box3); UnloadTexture(box4);
        UnloadTexture(hooker); UnloadTexture(sand); UnloadTexture(shower);
        UnloadTexture(stone); UnloadTexture(tile); UnloadTexture(wall);
        UnloadTexture(aimTex); UnloadTexture(playerTex); UnloadTexture(playerTex_walk);
        UnloadTexture(gunTex); UnloadTexture(enemyTex); UnloadTexture(gunTex_enemy);
        UnloadTexture(bombTex1); UnloadTexture(bombTex2); UnloadTexture(smokeTex);
        UnloadTexture(magazineTex); UnloadTexture(dashTex);

        // 音声
        UnloadSound(shootSound1); UnloadSoundAlias(shootSoundCopy1);
        UnloadSound(shootSound2); UnloadSoundAlias(shootSoundCopy2);
        UnloadSound(explosionSound); UnloadSound(stepSound1);
        UnloadSound(blinkSound); UnloadSound(plantSound1); UnloadSound(plantSound2);
        UnloadSound(noammoSound); UnloadSound(reloadSound); UnloadSound(defuseSound);
        UnloadSound(killSound1); UnloadSound(killSound2); UnloadSound(killSound3);
        UnloadSound(killSound4); UnloadSound(killSound5);

        // レンダーテクスチャ
        UnloadRenderTexture(mask1);
        UnloadRenderTexture(mask2);
        UnloadRenderTexture(mask3);

        isInitialized = false;
    }
}