#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <raylib.h>
#include <stdbool.h>
#include <math.h>
#include <rlgl.h>
#include <time.h>

// 関数A. ボタンを表示する (メニュー画面に使う)
bool DrawButton(Rectangle rect, const char *text, Color baseColor)
{
    Vector2 mousePos = GetMousePosition();
    bool isOnButton = CheckCollisionPointRec(mousePos, rect);
    bool clicked = false;
    Color drawColor = baseColor;

    if (isOnButton) {
        drawColor = ColorBrightness(baseColor, 0.2f);
        if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) clicked = true;
    }

    DrawRectangleRec(rect,drawColor);
    DrawRectangleLinesEx(rect, 2, BLACK);
    int fontSize = 20;
    DrawText(text, rect.x + (rect.width - MeasureText(text, fontSize))/2, rect.y + (rect.height - fontSize)/2, fontSize, WHITE);

    return clicked;
}

// 関数B. 配列をシャッフルする．
void shuffleArray(Vector2 *array, int n)
{
    for (int i = n - 1; i > 0; i--) {
        int j = rand() % (i + 1); // 0からiでランダムな値

        Vector2 tmp = array[i]; // array[i]とarray[j]を入れ替え
        array[i] = array[j];
        array[j] = tmp;
    }
}

// 関数C. 視野内で見える範囲を計算する（障害物にぶつかる点の集合を保存)
void GetFovPoints(Player p, int map[MAP_ROWS][MAP_COLS], Vector2 *points, Smoke smokes[], int *fovCount)
{
    float startAngle = (p.rotation + 51.5f) * PI / 180.0f;
    int index = 0;
    points[index++] = p.position; // points[0]を初期化

    for (float a = 0; a <= FOV; a += 0.5f) {
        float angle = startAngle - a * PI / 180.0f;
        Vector2 dir = { cosf(angle), sinf(angle )}; // 現在のangleを向いている単位ベクトル
        Vector2 current = p.position;

        // 各rayに対してcurrentを壁に当たるまで進める（レイキャスト）
        for (float dist = 0; dist < 1000; dist += 5) {
            current.x = p.position.x + dir.x * dist;
            current.y = p.position.y + dir.y * dist; // 現在のangleの方向にcurrentをdistだけ動かす
            int tx = (int)(current.x / TILE_SIZE);
            int ty = (int)(current.y / TILE_SIZE);

            bool hit = false;

            if (0 <= tx && tx < MAP_COLS && 0 <= ty && ty < MAP_ROWS) {
                if (map[ty][tx] == 1 || map[ty][tx] == 9 || map[ty][tx] == 10 ) hit = true;
            }

            for (int i = 0; i< NUM_SMOKE; i++) {
                if (smokes[i].active && CheckCollisionPointCircle(current, smokes[i].position, 30.0)) {
                    hit = true;
                    break;
                }
            }

            if (hit) break;
        }
        points[index++] = current;
    }
    *fovCount = index;
}

// 関数D. マップの画像ファイルを読み込む
void loadMap(Image mapImage, int map[MAP_ROWS][MAP_COLS])
{
    for (int y = 0; y < MAP_ROWS; y++) {
        for (int x = 0; x < MAP_COLS; x++) {
            Color pixel = GetImageColor(mapImage, x, y);

            // 画素には誤差があるため幅を持たせている
            if (pixel.r < 10 && pixel.g < 10 && pixel.b < 10){ map[y][x] = 1; } // 壁 0x000000
            else if (177 < pixel.r && pixel.r < 197 && 177 < pixel.g && pixel.g < 197 && 177 < pixel.b && pixel.b < 197) { map[y][x] = 2; } // 砂 0xbbbbbb
            else if (pixel.r > 245 && pixel.g > 245 && pixel.b > 245) { map[y][x] = 3; } // 黒い石 0xffffff
            else if (pixel.r < 10 && pixel.g > 245 && pixel.b < 10) { map[y][x] = 4; } // スパイク設置場所(A) 0x00ff00
            else if (pixel.r < 10 && 58 < pixel.g && pixel.g < 78 && pixel.b < 10) { map[y][x] = 5; } // スパイク設置場所(B) 0x004400
            else if (177 < pixel.r && pixel.r < 197 && 177 < pixel.g && pixel.g < 197 && pixel.b > 245) { map[y][x] = 6; } // タイル（Aロング） 0xbbbbff
            else if (pixel.r > 245 && 177 < pixel.g && pixel.g < 197 && 177 < pixel.b && pixel.b < 197) { map[y][x] = 7; } // フッカー 0xffbbbb
            else if (177 < pixel.r && pixel.r < 197 && pixel.g > 245 && pixel.b > 245) { map[y][x] = 8; } // シャワー 0xbbffff
            else if (pixel.r > 245 && pixel.g > 245 && 177 < pixel.b && pixel.b < 197) { map[y][x] = 9; } // 障害物1 0xffffbb
            else if (pixel.r > 245 && 177 < pixel.g && pixel.g < 197 && pixel.b > 245) { map[y][x] = 10; } // 障害物2 0xffbbff
            else  { map[y][x] = 0; } // 読み取りエラー
        }
    }
}

// 関数E. カメラの位置とプレイヤーの角度計算
void angleCalculate(Camera2D *camera, Player *player, float *angleRad, Vector2 *LineOfSight, Vector2 mouseWorldPos) 
{
    camera->target = player->position;

    float dx = mouseWorldPos.x - player->position.x;
    float dy = mouseWorldPos.y - player->position.y;

    *angleRad = atan2f(dy, dx);
    player->rotation = *angleRad * (180.0f / PI);

    *LineOfSight = (Vector2){ player->position.x + 2000 * cos(*angleRad), player->position.y + 2000 * sin(*angleRad) }; // 射線を表す点
}

// 関数F. カメラの初期化．playerに合わせる．
void initCamera(Camera2D *camera, Player *player)
{
    camera->target = player->position;
    camera->offset = (Vector2){ SCREEN_WIDTH/2.0f, SCREEN_HEIGHT/2.0f };
    camera->rotation = 0.4f;
    camera->zoom = 1.7f;
}

// 関数G. 弾を発射する
void generateBullet(Player *player, int *shootCount, Bullet bullets[], float angleRad, bool isMoving, Sound shootSound, Sound shootSoundCopy)
{
    // shootCountは発射レートを制御するint

    float currentRad = angleRad;
    if (*shootCount == 0) { 
        // 射撃音再生
        if (player->ammo % 2 == 1) { PlaySound(shootSound); } // 連続的に再生するため，偶奇で再生するSoundをかえている（中身は同じ)
        else PlaySound(shootSoundCopy);
        (player->ammo)--;

        for (int i = 0; i < MAX_BULLETS; i++) {
            if (!bullets[i].active) {
                bullets[i].position = player->position;
                bullets[i].isEnemyBullet = false;

                if (isMoving) {
                    float val = ((float)rand() / (float)RAND_MAX) * 1.0f - 0.5f;
                    currentRad += val;
                }
                bullets[i].speed.x = cosf(currentRad) * BULLET_SPEED / FPS;
                bullets[i].speed.y = sinf(currentRad) * BULLET_SPEED / FPS;

                bullets[i].active = true;
                *shootCount = FPS / 9.8; // 発射レートが9.8回/秒になって欲しい
                break;
            }
        }
    }
}

// 関数H. 弾を移動させて衝突したら消す．死亡判定もここ
void moveBullet(Player *player, Bullet bullets[], Enemy enemies[], int map[MAP_ROWS][MAP_COLS], int* killCount, Sound kill1, Sound kill2, Sound kill3, Sound kill4, Sound kill5, Difficulty currentDiff)
{
    for (int i = 0; i < MAX_BULLETS; i++) {
        if (bullets[i].active) {
            // 移動
            bullets[i].position.x += bullets[i].speed.x;
            bullets[i].position.y += bullets[i].speed.y;

            // 壁に当たるかマップ外にでると消す
            float bulletX = bullets[i].position.x;
            float bulletY = bullets[i].position.y;
            int tileX_b = (int)(bulletX / TILE_SIZE);
            int tileY_b = (int)(bulletY / TILE_SIZE);
            if (bulletX < 0 || bulletX >= MAP_COLS * TILE_SIZE || bulletY < 0 || bulletY >= MAP_ROWS * TILE_SIZE || 
                (tileX_b >= 0 && tileX_b < MAP_COLS && tileY_b >= 0 && tileY_b < MAP_ROWS && 
                 (map[tileY_b][tileX_b] == 1 || map[tileY_b][tileX_b] == 9 || map[tileY_b][tileX_b] == 10))) {
                bullets[i].active = false;
                bullets[i].position.x = -1.0f;
                bullets[i].position.y = -1.0f;
                continue;
            }

            // 弾とプレイヤーの当たり判定（敵の弾の場合）
            if (bullets[i].isEnemyBullet && CheckCollisionCircles(bullets[i].position, BULLET_SIZE, player->position, PLAYER_SIZE)) {
                // 頭部に当たったかチェック
                Vector2 headPos = {player->position.x, player->position.y - 8.0f}; // プレイヤーの頭部位置
                if (CheckCollisionCircles(bullets[i].position, BULLET_SIZE, headPos, HEAD_SIZE)) {
                    if (currentDiff == EASY) { player->health -= 40; }
                    else { player->health -= 160; } // 頭部に当たった場合は160ダメージ(EASYはヘッドショットなし)
                } else {
                    player->health -= 40; // 通常は40ダメージ
                }

                if (player->health <= 0) {
                    player->health = 0;
                    player->isDead = true;
                }
                bullets[i].active = false;
                continue;
            }

            // 弾と敵の当たり判定（自分の弾）
            for (int j = 0; j < NUM_BOT; j++) {
                if (!bullets[i].isEnemyBullet && enemies[j].active && CheckCollisionCircles(bullets[i].position, BULLET_SIZE, enemies[j].position, ENEMY_SIZE)) {
                    
                    // 当たり判定用の座標を一時保存
                    Vector2 hitPos = bullets[i].position;
                    bullets[i].active = false; 

                    Vector2 headPos = {enemies[j].position.x, enemies[j].position.y - 8.0f}; 

                    if (CheckCollisionCircles(hitPos, BULLET_SIZE, headPos, HEAD_SIZE)) {
                        enemies[j].health -= 160; 
                    } else {
                        enemies[j].health -= 40;
                    }

                    // --- 死亡判定---
                    if (enemies[j].health <= 0) {
                        enemies[j].active = false;
                        enemies[j].position = (Vector2){-100.0f, -100.0f};
                        (*killCount)++;
                        
                        int soundIdx = ((*killCount - 1) % 5) + 1;

                        switch (soundIdx) {
                            case 1: PlaySound(kill1); break;
                            case 2: PlaySound(kill2); break;
                            case 3: PlaySound(kill3); break;
                            case 4: PlaySound(kill4); break;
                            case 5: PlaySound(kill5); break;
                        }
                    }
                    break; 
                }
            }
        }
    }
}

// 関数I. 敵がプレイヤーを見ているかチェック（レイキャストで壁に遮られていないか、スモーク内にいないか）
bool CanEnemySeePlayer(Vector2 enemyPos, Vector2 playerPos, int map[MAP_ROWS][MAP_COLS], Smoke smokes[])
{
    // スモークがアクティブで、敵がスモーク内にいる場合は視認不可
    for (int i = 0; i < NUM_SMOKE; i++) {
        if (smokes[i].active) {
            if (CheckCollisionPointCircle(enemyPos, smokes[i].position, SMOKE_SIZE)) {
                return false; // 敵がスモーク内にいる
            }
            // プレイヤーがスモーク内にいる場合も視認不可
            if (CheckCollisionPointCircle(playerPos, smokes[i].position, SMOKE_SIZE)) {
                return false; // プレイヤーがスモーク内にいる
            }
        }
    }
    
    float dx = playerPos.x - enemyPos.x;
    float dy = playerPos.y - enemyPos.y;

    float dist = sqrtf(dx * dx + dy * dy);
    if (dist < 5.0f) return true; // 非常に近い
    
    Vector2 dir = {dx / dist, dy / dist};
    float step = 5.0f;
    int steps = (int)(dist / step);
    
    // レイキャストを行う
    for (int i = 1; i < steps; i++) {
        Vector2 checkPos = {
            enemyPos.x + dir.x * step * i,
            enemyPos.y + dir.y * step * i
        };
        
        int tx = (int)(checkPos.x / TILE_SIZE);
        int ty = (int)(checkPos.y / TILE_SIZE);
        
        if (0 <= tx && tx < MAP_COLS && 0 <= ty && ty < MAP_ROWS) {
            if (map[ty][tx] == 1 || map[ty][tx] == 9 || map[ty][tx] == 10) {
                return false; // 壁に遮られている
            }
        }
        
        // スモークがレイキャストの経路上にある場合は視認不可
        for (int s = 0; s < NUM_SMOKE; s++) {
            if (smokes[s].active && CheckCollisionPointCircle(checkPos, smokes[s].position, SMOKE_SIZE)) {
                return false; // スモークに遮られている
            }
        }
    }
    
    return true; // 視認可能
}

// 関数J. 爆弾を管理する
void maintainBomb(Player *player, Enemy enemies[], Bomb *bomb, bool isPlantSite, Sound explosion, Sound plantSound1, Sound plantSound2, Sound defuseSound, 
                    bool *distMapCreated, int map[MAP_ROWS][MAP_COLS], int distMap[MAP_ROWS][MAP_COLS], bool existDefusing)
{
    if (bomb->state == BOMB_CARRY) {
        *distMapCreated = false;
        for (int i = 0; i < 5; i++) enemies[i].state = GUARDING;
        player->isPlanting = false;
        bomb->position = player->position;
        bomb->explosionTimer = 0.0f;

        if (IsKeyDown(KEY_F) && isPlantSite) {
            PlaySound(plantSound1);
            bomb->state = BOMB_PLANTING;
            player->isPlanting = true;
        }
    }
    else if (bomb->state == BOMB_PLANTING) {
        for (int i = 0; i < 5; i++) {
            enemies[i].state = APPROACHING;
        }
        if (!(*distMapCreated)) {
            CreateDistMap(bomb->position, map, distMap);
            *distMapCreated = true;
        }
        if (IsKeyReleased(KEY_F)) {
            bomb->state = BOMB_CARRY;
            bomb->explosionTimer = 0.0f;
        } else {
            bomb->explosionTimer += GetFrameTime();

            if (bomb->explosionTimer >= PLANT_DURATION) {
                // 設置完了音再生
                PlaySound(plantSound2);
                bomb->state = BOMB_PLANTED;
                bomb->explosionTimer = EXPLOSION_TIME;
                bomb->position = player->position;
            }
        }
    } else if (bomb->state == BOMB_PLANTED) {
        if (existDefusing) { bomb->state = BOMB_DEFUSING; }

        if (!(*distMapCreated)) {
            CreateDistMap(bomb->position, map, distMap);
            *distMapCreated = true;
        }

        player->isPlanting = false;
        bomb->explosionTimer -= GetFrameTime();
        if (bomb->explosionTimer <= 0) {
            // 爆発音再生
            PlaySound(explosion);
            bomb->state = BOMB_EXPLODED;
        }
    } else if (bomb->state == BOMB_DEFUSING) { 
        if (bomb->defuseTimer == 0.0f) PlaySound(defuseSound);
        bomb->defuseTimer += GetFrameTime();

        if (bomb->defuseTimer >= DEFUSE_DURATION) bomb->state = BOMB_DEFUSED;
        if (!existDefusing) {
            bomb->state = BOMB_PLANTED;
            bomb->defuseTimer = 0.0f;
        }
    } 
}

// 関数K. 敵のAI更新
void updateEnemyAI(Enemy *enemy, Player *player, Bullet bullets[], int map[MAP_ROWS][MAP_COLS], int distMap[MAP_ROWS][MAP_COLS], Smoke smokes[], Sound shootSound, Sound shootSoundCopy, bool *existDefusing, float spread, float shootDuration, int killCount, Bomb *bomb)
{
    static int shotCount = 0;
    if (shotCount >= 10) shotCount = 0;

    if (!enemy->active) return;

    bool canEnemySee = CanEnemySeePlayer(enemy->position, player->position, map, smokes);
    int ex = (int)(enemy->position.x / TILE_SIZE);
    int ey = (int)(enemy->position.y / TILE_SIZE);

    // ---- 状態遷移 ----
    switch (enemy->state) {
        case GUARDING:
            // 爆弾の位置でGUARDINGの敵は，プレイヤーが見えなくなったらDEFUSINGになる
            if (!canEnemySee && 0 <= distMap[ey][ex] && distMap[ey][ex] <= 1) {
                enemy->state = DEFUSING;
            }

            // プレイヤーが見えなくて，爆弾が設置中or設置後で，他に設置しているBOTがいなければ近づく
            if (!canEnemySee && bomb->state != BOMB_CARRY && !*existDefusing) {
                enemy->state = APPROACHING;
            }
            break;

        case APPROACHING:
            // 接近中にプレイヤーを視認したらGUARDINGに
            if (canEnemySee) {
                enemy->state = GUARDING;
            }
            // 接近中に他のBOTが解除していたらGUARDINGに
            if (*existDefusing) {
                enemy->state = GUARDING;
            }
            // 十分接近して爆弾との距離が1マスになったらDEFUSINGに
            if (0 <= distMap[ey][ex] && distMap[ey][ex] <= 1) {
                enemy->state = DEFUSING;
            }
            break;
        
        case DEFUSING:
            // 解除中のBOTが最後の一体であれば，敵を視認した時GUARDINGに
            if (canEnemySee && killCount == 4) {
                enemy->state = GUARDING;
            }
            break;
    }
    
    // ---- 各状態の処理 ----
    
    // 守備中はプレイヤーを見つけると射撃する
    if (enemy->state == GUARDING) {
        // 射撃タイマーを更新
        if (enemy->shootTimer > 0) {
            enemy->shootTimer -= GetFrameTime();
        }
        
        // プレイヤーを視認しているかチェック（スモーク内の敵は視認不可）
        if (canEnemySee) {
            // 視認している場合，射撃タイマーが0になったら撃つ
            if (enemy->shootTimer <= 0) {
                // 射撃音再生
                if (shotCount % 2 == 1) { PlaySound(shootSound); } // 連続的に再生するため，偶奇で再生するSoundをかえている（中身は同じ)
                else PlaySound(shootSoundCopy);
                shotCount++;

                // プレイヤーへの方向を計算
                float dx = player->position.x - enemy->position.x;
                float dy = player->position.y - enemy->position.y;
                float val = -spread + 2 * spread * ((float)rand() / (float)RAND_MAX);
                float angleRad = atan2f(dy, dx) + val;
                
                // 弾を生成
                for (int i = 0; i < MAX_BULLETS; i++) {
                    if (!bullets[i].active) {
                        bullets[i].position = enemy->position;
                        bullets[i].isEnemyBullet = true;
                        bullets[i].speed.x = cosf(angleRad) * BULLET_SPEED / FPS;
                        bullets[i].speed.y = sinf(angleRad) * BULLET_SPEED / FPS;
                        bullets[i].active = true;
                        
                        // 射撃タイマーをリセット　間隔: shootDuration
                        enemy->shootTimer = shootDuration;
                        break;
                    }
                }
            }
        }
    }

    // 爆弾を設置し始めると，近づいてくる
    if (enemy->state == APPROACHING) {
        int targetX = ex, targetY = ey;
        int minDist = (distMap[ey][ex] == -1) ? 9999 : distMap[ey][ex];

        int dx[] = {1, -1, 0, 0}, dy[] = {0, 0, 1, -1};
        for (int i = 0; i < 4; i++) {
            int nx = ex + dx[i], ny = ey + dy[i];
            if (nx >= 0 && nx < MAP_COLS && ny >= 0 && ny < MAP_ROWS && distMap[ny][nx] != -1) {
                if (distMap[ny][nx] < minDist) {
                    minDist = distMap[ny][nx]; // 最小の方向を選択
                    targetX = nx; targetY = ny;
                }
            }
        }

        // targetX, targetY に向かってゆっくり移動
        Vector2 worldTarget = { targetX * TILE_SIZE + TILE_SIZE/2.0f, targetY * TILE_SIZE + TILE_SIZE/2.0f };
        float moveAngle = atan2f(worldTarget.y - enemy->position.y, worldTarget.x - enemy->position.x);
        enemy->position.x += cosf(moveAngle) * ENEMY_MOVE_SPEED / FPS;
        enemy->position.y += sinf(moveAngle) * ENEMY_MOVE_SPEED / FPS;
    }

    if (enemy->state == DEFUSING) {
        *existDefusing = true;
    }
}

// 関数L．爆弾の座標を起点としてマップ全体の最小距離を計算する　幅優先探索を用いた
void CreateDistMap(Vector2 target, int map[MAP_ROWS][MAP_COLS], int distMap[MAP_ROWS][MAP_COLS]) {
    // 全ての場所を未到達（-1）にする
    for (int y = 0; y < MAP_ROWS; y++) {
        for (int x = 0; x < MAP_COLS; x++) distMap[y][x] = -1;
    }

    int startX = (int)(target.x / TILE_SIZE); // 爆弾の場所
    int startY = (int)(target.y / TILE_SIZE);
    
    int queueX[MAP_ROWS * MAP_COLS], queueY[MAP_ROWS * MAP_COLS];
    int head = 0, tail = 0;

    distMap[startY][startX] = 0;
    queueX[tail] = startX; queueY[tail++] = startY; // queueXorY[0] は爆弾の位置を表す

    while (head < tail) {
        int cx = queueX[head], cy = queueY[head++]; // headをすすめる
        int d = distMap[cy][cx];    // 考える地点の中心の，爆弾からの距離

        int dx[] = {1, -1, 0, 0}, dy[] = {0, 0, 1, -1};
        for (int i = 0; i < 4; i++) {
            int nx = cx + dx[i], ny = cy + dy[i];                           // これで前後左右全パターンになる
            if (nx >= 0 && nx < MAP_COLS && ny >= 0 && ny < MAP_ROWS &&     // 条件：マップの内側
                map[ny][nx] != 1 && map[ny][nx] != 9 && map[ny][nx] != 10 && // 条件：壁でない
                distMap[ny][nx] == -1) {                                       // 条件：まだ書き込まれていない
                distMap[ny][nx] = d + 1;
                queueX[tail] = nx; queueY[tail++] = ny;  // 列の末尾に追加（現在判定した4箇所を後々判定するということ）
            }
        }
    }
}

// 関数M. スモークを管理する
void maintainSmoke (Player *player, Smoke smokes[NUM_SMOKE], Vector2 mouseWorldPos, float *smokeFreezeTimer)
{
    // Eキーで「設置場所選びモード」を切り替え
    if (IsKeyPressed(KEY_E) && player->smoke > 0 && !player->isPlanting && !player->isReloading) {
        player->isPlanningSmoke = !player->isPlanningSmoke;
    }

    if (player->isPlanningSmoke) {
        // 設置モード中に左クリックで確定
        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
            for (int i = 0; i < NUM_SMOKE; i++) {
                if (!smokes[i].active) {
                    player->smoke--;
                    *smokeFreezeTimer = 0.5f;
                    smokes[i].position = mouseWorldPos;
                    smokes[i].active = true;
                    smokes[i].timer = 10.0f;
                    player->isPlanningSmoke = false; // モード終了
                    break;
                }
            }
        }
    }

    player->isInSmoke = false;
    for (int i = 0; i < NUM_SMOKE; i++) {
        // スモークのタイマー管理
        if (smokes[i].active) {
            smokes[i].timer -= GetFrameTime();
            if (smokes[i].timer <= 0) smokes[i].active = false;
        }

        // スモークに入っているかの管理
        if (smokes[i].active == true) {
            if (CheckCollisionPointCircle(player->position, smokes[i].position, SMOKE_SIZE)) {
            player->isInSmoke = true;
            }
        }
    }
    
}

// 関数N. 弾のリロードを管理する
void reload(Player *player, double *reloadTimer, Sound reloadSound) {
    if(IsKeyPressed(KEY_R) && player->magazine >= 1 && !player->isReloading && player->ammo < 25 && !player->isPlanningSmoke) {
        PlaySound(reloadSound);
        player->isReloading = true;
        *reloadTimer = 0.0f;
    }
    
    if (player->isReloading) {
        *reloadTimer += GetFrameTime();

        if (*reloadTimer > 3.0f) {
            player->ammo = 25;
            player->magazine--;
            player->isReloading = false;
            *reloadTimer = 0.0f;
        }
    }
}

// 関数O. リトライボタンを描画する
void DrawRetryButton(char *msg1, char *msg2, bool *isInitialized, Difficulty diff) {
    // 半透明の黒背景とカーソル表示
    DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Fade(BLACK, 0.8f));
    ShowCursor();

    int centerX = SCREEN_WIDTH / 2;
    int centerY = SCREEN_HEIGHT / 2;

    // 勝利or敗北メッセーじ
    int fontSizeTitle = 60;
    int titleWidth = MeasureText(msg1, fontSizeTitle);
    DrawText(msg1, centerX - titleWidth / 2, centerY - 150, fontSizeTitle, RED);

    // ボタンの共通設定
    int btnWidth = 280;
    int btnHeight = 60;
    int btnX = centerX - btnWidth / 2;

    // RETRY ボタン
    Rectangle retryRect = { btnX, centerY - 20, btnWidth, btnHeight };
    Vector2 mousePos = GetMousePosition();
    bool onRetry = CheckCollisionPointRec(mousePos, retryRect);
    Color retryColor = onRetry ? GRAY : DARKGRAY;

    if (onRetry && IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
        *isInitialized = false;
        Init1v5(diff); // 保存された難易度で再開
    }

    DrawRectangleRec(retryRect, retryColor);
    DrawRectangleLinesEx(retryRect, 2, WHITE);
    int msg2Width = MeasureText(msg2, 30);
    DrawText(msg2, retryRect.x + (btnWidth - msg2Width) / 2, retryRect.y + 15, 30, WHITE);

    // BACK TO MENU ボタン 
    Rectangle menuRect = { btnX, centerY + 60, btnWidth, btnHeight };
    bool onMenu = CheckCollisionPointRec(mousePos, menuRect);
    Color menuColor = onMenu ? GRAY : DARKGRAY;

    if (onMenu && IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
        *isInitialized = false;    // 次回プレイのためリセット
        currentState = STATE_MENU; // メニュー画面へ
    }

    DrawRectangleRec(menuRect, menuColor);
    DrawRectangleLinesEx(menuRect, 2, WHITE);
    int menuTxtWidth = MeasureText("BACK TO MENU", 30);
    DrawText("BACK TO MENU", menuRect.x + (btnWidth - menuTxtWidth) / 2, menuRect.y + 15, 30, WHITE);
}