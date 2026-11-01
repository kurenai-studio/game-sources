#ifndef COMMON_H  
#define COMMON_H  

#include <stdio.h>
#include <stdlib.h>
#include <raylib.h>
#include <stdbool.h>
#include <math.h>
#include <rlgl.h>
#include <time.h>

// ---------------定数の定義--------------
#define FPS 120
    // MAP_COLS * TILE_SIZE == SCREEN_WIDTH
    // MAP_ROWS * TILE_SIZE == SCREEN_HEIGHT
#define SCREEN_WIDTH 1200
#define SCREEN_HEIGHT 900
#define TILE_SIZE 12
#define MAP_ROWS 75
#define MAP_COLS 100

#define MAX_BULLETS 256
#define BULLET_SIZE 2.0f 
#define BULLET_SPEED 1800.0f
#define NUM_BOT 5
#define NUM_SMOKE 3
#define SMOKE_SIZE 30.0f

#define PLAYER_SIZE 10.0f
#define ENEMY_SIZE 10.0f
#define HEAD_SIZE 5.0f
#define MOVE_SPEED 72.0f
#define ENEMY_MOVE_SPEED 24.0f
#define WEIGHT_SPEED 36.0f
#define FOV 103.0f
#define PLANT_DURATION 4.0f
#define DEFUSE_DURATION 4.0f
#define EXPLOSION_TIME 25.0f

#define COS45 0.7071f

//--------------構造体の定義-------------
typedef enum {
    STATE_MENU,
    STATE_1v5
} GameState;

typedef enum {
    EASY,
    NORMAL,
    HARD
} Difficulty;

typedef enum {
    APPROACHING,
    DEFUSING,
    GUARDING
} EnemyState;

typedef struct
{
    Vector2 position;
    float rotation;
    int health;
    int ammo;
    int magazine; // 予備マガジンの数
    int dash;
    int smoke;
    bool isDead;
    bool isPlanting;
    bool isPlanningSmoke;
    bool isInSmoke;
    bool isReloading;
} Player;

typedef struct
{
    Vector2 position;
    Vector2 speed;
    bool active;
    bool isEnemyBullet;
} Bullet;

typedef struct
{
    Vector2 position;
    int health;
    bool active;
    EnemyState state;
    float shootTimer; // 射撃タイマー（連射を防ぐ）
} Enemy;

typedef enum
{
    BOMB_CARRY,
    BOMB_PLANTING,
    BOMB_PLANTED,
    BOMB_EXPLODED,
    BOMB_DEFUSING,
    BOMB_DEFUSED
} BombState;

typedef struct {
    Vector2 position;
    BombState state;
    float explosionTimer;
    float defuseTimer;
    bool isDefused;
} Bomb;

typedef struct {
    Vector2 position;
    float timer;
    bool active;
} Smoke;

//-------------------関数の定義--------------------
bool DrawButton(Rectangle, const char *, Color);
void shuffleArray(Vector2 *, int);
void GetFovPoints(Player, int[MAP_ROWS][MAP_COLS], Vector2 *, Smoke[], int *);
void loadMap(Image, int[MAP_ROWS][MAP_COLS]);
void angleCalculate(Camera2D*, Player*, float*, Vector2*, Vector2);

void initCamera(Camera2D*, Player*);
void generateBullet(Player*, int*, Bullet[], float, bool, Sound, Sound);
void maintainBomb(Player*, Enemy[], Bomb*, bool, Sound, Sound, Sound, Sound, bool*, int map[MAP_ROWS][MAP_COLS], int distMap[MAP_ROWS][MAP_COLS], bool);
void moveBullet(Player*, Bullet[], Enemy[], int map[MAP_ROWS][MAP_COLS], int*, Sound, Sound, Sound, Sound, Sound, Difficulty);
void reload (Player*, double*, Sound);
void maintainSmoke(Player*, Smoke[NUM_SMOKE], Vector2, float*);
bool CanEnemySeePlayer(Vector2 enemyPos, Vector2 playerPos, int map[MAP_ROWS][MAP_COLS], Smoke[]);
void updateEnemyAI(Enemy*, Player*, Bullet[], int map[MAP_ROWS][MAP_COLS], int distMap[MAP_ROWS][MAP_COLS], Smoke[], Sound, Sound, bool*, float, float, int, Bomb*);
void CreateDistMap(Vector2, int map[MAP_ROWS][MAP_COLS], int distMap[MAP_ROWS][MAP_COLS]);
void DrawRetryButton(char*, char*, bool*, Difficulty);

// ---------------状態管理-----------------
extern GameState currentState;

//--------各シーンの関数プロトタイプ宣言-------
void UpdateMenu();
void DrawMenu(void);

void Init1v5(Difficulty);
void Update1v5(void);
void Draw1v5(void);
void Unload1v5(void);

#endif