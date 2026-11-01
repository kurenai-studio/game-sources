#include <raylib.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define TILE_SIZE 30
#define CHUNK_SIZE 32
#define WORLD_SIZE_X 300
#define WORLD_SIZE_Y 30
#define CHUNK_SIZE_PX (TILE_SIZE * CHUNK_SIZE)
#define WORLD_SIZE_PX_X (CHUNK_SIZE_PX * WORLD_SIZE_X)
#define WORLD_SIZE_PX_Y (CHUNK_SIZE_PX * WORLD_SIZE_Y)

#define PLATFORM_DESKTOP 1
#define PLATFORM_MOBILE 0


int Max(int a, int b) {
    if (a > b) return a;
    return b;
}

int Min(int a, int b) {
    if (a > b) return b;
    return a;
}

int Clampi(int value, int min, int max) {
    return Max(min, Min(value, max));
}

float Clampf(float value, float min, float max) {
    return fmaxf(min, fminf(value, max));
}

void ToggleTargetTileType(char *targetTileType) {
    if ((*targetTileType) == 0) {
        (*targetTileType) = 1;
        return;
    }
    if ((*targetTileType) == 1) {
        (*targetTileType) = 2;
        return;
    }
    (*targetTileType) = 0;
}

// World
typedef struct {
    int length;
    Rectangle *rects;
} Walls;

typedef struct {
    char tiles[CHUNK_SIZE][CHUNK_SIZE];
    int x;
    int y;
} Chunk;

typedef struct {
    Chunk chunks[WORLD_SIZE_X][WORLD_SIZE_Y];
} World;


Vector2 GetMousePosInWorld(Camera2D camera, float viewWidth, float viewHeight) {
    Vector2 mouseScreen = GetMousePosition();

    float scale = fminf((float)GetScreenWidth() / viewWidth, (float)GetScreenHeight() / viewHeight);

    float offsetX = ((float)GetScreenWidth() - (viewWidth * scale)) * 0.5f;
    float offsetY = ((float)GetScreenHeight() - (viewHeight * scale)) * 0.5f;

    Vector2 viewMouse;
    viewMouse.x = (mouseScreen.x - offsetX) / scale;
    viewMouse.y = (mouseScreen.y - offsetY) / scale;

    return GetScreenToWorld2D(viewMouse, camera);
}

char GetTile(World *world, int x, int y) {
    if (x < 0 || x >= WORLD_SIZE_X * CHUNK_SIZE || y < 0 || y >= WORLD_SIZE_Y * CHUNK_SIZE) return 0;

    int chunkX = x / CHUNK_SIZE;
    int chunkY = y / CHUNK_SIZE;
    int tileX = x % CHUNK_SIZE;
    int tileY = y % CHUNK_SIZE;

    return world->chunks[chunkX][chunkY].tiles[tileY][tileX];
}

void SetTile(World *world, int x, int y, char tileType) {
    if (x < 0 || x >= WORLD_SIZE_X * CHUNK_SIZE || y < 0 || y >= WORLD_SIZE_Y * CHUNK_SIZE) return;

    int chunkX = x / CHUNK_SIZE;
    int chunkY = y / CHUNK_SIZE;
    int tileX = x % CHUNK_SIZE;
    int tileY = y % CHUNK_SIZE;

    world->chunks[chunkX][chunkY].tiles[tileY][tileX] = tileType;
}

void FillWalls(World *world, Walls *walls, Rectangle area) {
    walls->length = 0;

    int startX = (int)floorf(area.x / TILE_SIZE) - 1;
    int endX = (int)floorf((area.x + area.width) / TILE_SIZE) + 1;

    int startY = (int)floorf(area.y / TILE_SIZE) - 1;
    int endY = (int)floorf((area.y + area.height) / TILE_SIZE) + 1;

    for (int y = startY; y <= endY; y++) {
        for (int x = startX; x <= endX; x++) {
            if (GetTile(world, x, y)) {
                walls->rects[walls->length++] = (Rectangle){
                        (float)(x * TILE_SIZE),
                        (float)(y * TILE_SIZE),
                        (float)TILE_SIZE,
                        (float)TILE_SIZE
                };
            }
        }
    }

    walls->rects[walls->length++] = (Rectangle){0.0f, -1.0f, WORLD_SIZE_PX_X, 1};
    walls->rects[walls->length++] = (Rectangle){-1.0f, 0.0f, 1, WORLD_SIZE_PX_Y};
    walls->rects[walls->length++] = (Rectangle){0.0f, WORLD_SIZE_PX_Y, WORLD_SIZE_PX_X, 1};
    walls->rects[walls->length++] = (Rectangle){WORLD_SIZE_PX_X, 0.0f, 1, WORLD_SIZE_PX_Y};
}

Chunk CreateTestChunk(int x, int y) {
    Chunk chunk;
    chunk.x = x;
    chunk.y = y;

    for (int cy = 0; cy < CHUNK_SIZE; cy++) {
        for (int cx = 0; cx < CHUNK_SIZE; cx++) {
            if (GetRandomValue(1, 10) == 1) {
                chunk.tiles[cy][cx] = 1;
            } else {
                chunk.tiles[cy][cx] = 0;
            }
        }
    }

    return chunk;
}

void DrawChunk(Chunk *chunk, Camera2D camera) {
    int chunkX = chunk->x * CHUNK_SIZE * TILE_SIZE;
    int chunkY = chunk->y * CHUNK_SIZE * TILE_SIZE;

    for (int y = 0; y < CHUNK_SIZE; y++) {
        for (int x = 0; x < CHUNK_SIZE; x++) {
            if (chunk->tiles[y][x] == 1) {
                int tileX = chunkX + (x * TILE_SIZE);
                int tileY = chunkY + (y * TILE_SIZE);

                DrawRectangle(
                        tileX - camera.target.x + camera.offset.x,
                        tileY - camera.target.y + camera.offset.y,
                        TILE_SIZE,
                        TILE_SIZE,
                        RAYWHITE
                );
            }
        }
    }
}

void InitWorld(World *world) {
    for (int y = 0; y < WORLD_SIZE_Y; y++) {
        for (int x = 0; x < WORLD_SIZE_X; x++) {
            world->chunks[x][y] = CreateTestChunk(x, y);
        }
    }
}

void DrawWorld(World *world, Camera2D camera) {
    int startX = (int) floorf((camera.target.x - camera.offset.x) / CHUNK_SIZE_PX);
    int endX   = (int) ceilf((camera.target.x + camera.offset.x) / CHUNK_SIZE_PX) + 1;

    int startY = (int) floorf((camera.target.y - camera.offset.y) / CHUNK_SIZE_PX);
    int endY   = (int) ceilf((camera.target.y + camera.offset.y) / CHUNK_SIZE_PX) + 1;

    startX = Clampi(startX, 0, WORLD_SIZE_X);
    endX   = Clampi(endX, 0, WORLD_SIZE_X);
    startY = Clampi(startY, 0, WORLD_SIZE_Y);
    endY   = Clampi(endY, 0, WORLD_SIZE_Y);

    for (int y = startY; y < endY; y++) {
        for (int x = startX; x < endX; x++) {
            DrawChunk(&(world->chunks[x][y]), camera);
        }
    }
}

// Saving
void SaveWorld(World *world, int *isWorldModified) {
    if (SaveFileData("world.sav", world, sizeof(World))) {
        (*isWorldModified) = 0;
    }
}

void LoadWorld(World *world) {
    int dataSize = 0;
    unsigned char *fileData = LoadFileData("world.sav", &dataSize);

    if (fileData != NULL && dataSize == sizeof(World)) {
        memcpy(world, fileData, sizeof(World));
        UnloadFileData(fileData);

        return;
    }

    if (fileData != NULL) UnloadFileData(fileData);

    InitWorld(world);
}

void Autosave(World *world, float *autosaveCount, int *isWorldModified, float dt) {
    if (!(*isWorldModified)) return;

    (*autosaveCount) -= dt;

    if ((*autosaveCount) > 0 && IsWindowFocused()) return;

    SaveWorld(world, isWorldModified);
    (*autosaveCount) = 60.0f;
}

// Player
typedef struct {
    Rectangle rect;
    Vector2 center;
    float vx;
    float vy;
    char jumps;
    char maxJumps;
} Player;

int GroundCheckPlayer(Player *p, World *world) {
    Rectangle rect = {p->rect.x, p->rect.y + p->rect.height, p->rect.width, 1.0f};

    Rectangle rects[64];
    Walls walls = {0, rects};
    FillWalls(world, &walls, rect);

    for (int i = 0; i < walls.length; i++) {
        if (CheckCollisionRecs(walls.rects[i], rect)) {
            return 1;
        }
    }
    return 0;
}

void DrawPlayer(Player *p, Camera2D camera) {
    Rectangle drawRect;
    drawRect.x = p->rect.x - camera.target.x + camera.offset.x;
    drawRect.y = p->rect.y - camera.target.y + camera.offset.y;
    drawRect.width = p->rect.width;
    drawRect.height = p->rect.height;

    DrawRectangleRec(drawRect, RED);
}

void MovePlayer(Player *p, World *world, float dt) {
    float maxFallingSpeed = 2000.0f;
    if (p->vy < maxFallingSpeed) {
        p->vy += 2200.0f * dt;
    }

    {
        p->rect.x += p->vx * dt;

        Rectangle rects[64];
        Walls wallsX = {0, rects};
        FillWalls(world, &wallsX, p->rect);

        for (int i = 0; i < wallsX.length; i++) {
            Rectangle wall = wallsX.rects[i];
            if (CheckCollisionRecs(p->rect, wall)) {
                if (p->vx > 0) {
                    p->vx = 0;
                    p->rect.x = wall.x - p->rect.width;
                }
                if (p->vx < 0) {
                    p->vx = 0;
                    p->rect.x = wall.x + wall.width;
                }
            }
        }
    }

    {
        p->rect.y += p->vy * dt;

        Rectangle rects[64];
        Walls wallsY = {0, rects};
        FillWalls(world, &wallsY, p->rect);

        for (int i = 0; i < wallsY.length; i++) {
            Rectangle wall = wallsY.rects[i];
            if (CheckCollisionRecs(p->rect, wall)) {
                if (p->vy > 0) {
                    p->vy = 0;
                    p->rect.y = wall.y - p->rect.height;
                }
                if (p->vy < 0) {
                    p->vy = 0;
                    p->rect.y = wall.y + wall.height;
                }
            }
        }
    }

    p->vx *= powf(0.0001f, dt);

    p->center.x = p->rect.x + p->rect.width * 0.5f;
    p->center.y = p->rect.y + p->rect.height * 0.5f;

    if (GroundCheckPlayer(p, world)) {
        p->jumps = 0;
        return;
    }
    p->jumps = Max(1, p->jumps);
}

int TooFarOfPlayer(Player *p, Vector2 position) {
    float dx = position.x - p->center.x;
    float dy = position.y - p->center.y;

    float distanceSquared = (dx * dx) + (dy * dy);
    float maxReachSquared = 65536;

    return distanceSquared > maxReachSquared;
}

int TouchesPlayer(Player *p, Vector2 position) {
    int tileX = (int)floorf(position.x / TILE_SIZE);
    int tileY = (int)floorf(position.y / TILE_SIZE);

    Rectangle tileRect = {
            (float)(tileX * TILE_SIZE),
            (float)(tileY * TILE_SIZE),
            (float)TILE_SIZE,
            (float)TILE_SIZE
    };

    return CheckCollisionRecs(p->rect, tileRect);
}

// Input
int WorldInteraction(World *world, Player *p, int *isWorldModified, Camera2D camera, float viewWidth, float viewHeight, char tileType) {
    if (tileType == 2) return 1;
    if (PLATFORM_MOBILE && !GetTouchPointCount()) return 1;
    if (PLATFORM_DESKTOP && !IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) return 1;

    Vector2 position = GetMousePosInWorld(camera, viewWidth, viewHeight);

    if (TooFarOfPlayer(p, position)) return 1;
    if (TouchesPlayer(p, position)) return 0;

    int tileX = (int)floorf(position.x / TILE_SIZE);
    int tileY = (int)floorf(position.y / TILE_SIZE);

    SetTile(world, tileX, tileY, tileType);
    (*isWorldModified) = 1;

    return 0;
}

void KeyboardInput(Player *p, char *targetTileType) {
    if ((IsKeyPressed(KEY_W) || IsKeyPressed(KEY_UP)) && p->jumps < p->maxJumps) {
        p->vy = -750.0f;
        p->jumps++;
    }

    int direction = (IsKeyDown(KEY_D) || IsKeyDown(KEY_RIGHT)) - (IsKeyDown(KEY_A) || IsKeyDown(KEY_LEFT));

    if (direction != 0) {
        p->vx = direction * 450.0f;
    }

    if (IsKeyDown(KEY_ZERO)) {
        (*targetTileType) = 0;
    }

    if (IsKeyDown(KEY_ONE)) {
        (*targetTileType) = 1;
    }

    if (IsKeyPressed(KEY_F11)) {
        ToggleFullscreen();
    }
}

void TouchInput(Player *p, char *targetTileType) {
    int screenWidth = GetScreenWidth();
    int screenHeight = GetScreenHeight();

    int touchCount = GetTouchPointCount();
    static int prevTouchCount = 0;

    int direction = 0;

    for (int i = 0; i < touchCount; i++) {
        Vector2 touchPos = GetTouchPosition(i);

        if (touchPos.x < screenWidth * 0.5f) {
            if (touchPos.x < screenWidth * 0.15f) {
                direction = -1;
            } else {
                direction = 1;
            }
        }
    }

    if (direction != 0) {
        p->vx = direction * 450.0f;
    }

    if (touchCount > prevTouchCount) {
        int startIdx = (prevTouchCount < 0) ? 0 : prevTouchCount;
        for (int i = startIdx; i < touchCount; i++) {
            Vector2 touchPos = GetTouchPosition(i);

            if (touchPos.x >= screenWidth * 0.5f) {
                if (touchPos.y < screenHeight * 0.5f) {
                    ToggleTargetTileType(targetTileType);
                } else if (p->jumps < p->maxJumps) {
                    p->vy = -750.0f;
                    p->jumps++;
                }
            }
        }
    }

    prevTouchCount = touchCount;
}

// Camera
void MoveCamera(Camera2D *camera, Player *p, float dt) {
    camera->target.x += (p->center.x - camera->target.x) * 10.0f * dt;
    camera->target.y += (p->center.y - camera->target.y) * 10.0f * dt;

    camera->target.x = Clampf(camera->target.x, camera->offset.x, WORLD_SIZE_PX_X - camera->offset.x);
    camera->target.y = Clampf(camera->target.y, camera->offset.y, WORLD_SIZE_PX_Y - camera->offset.y);
}

// main function
int main(void)
{
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);
    InitWindow(1280, 720, "Flying Blocks");

    float viewWidth = 1280;
    float viewHeight = 720;
    float invViewWidth = 1.0f / viewWidth;
    float invViewHeight = 1.0f / viewHeight;

    RenderTexture2D view = LoadRenderTexture(viewWidth, viewHeight);

    int MAX_FPS = 240;
    if (PLATFORM_MOBILE) MAX_FPS = 120;
    float dt = 1.0f / (float)MAX_FPS;
    float time = dt;

    // create

    int isWorldModified = 0;
    float autosaveCount = 10.0f;

    char targetTileType = 0;
    if (PLATFORM_MOBILE) targetTileType = 2;

    Player player = {{WORLD_SIZE_PX_X / 2.0f, WORLD_SIZE_PX_Y / 2.0f, 30.0f, 60.0f}};
    player.maxJumps = 2;
    player.jumps = 0;

    Camera2D camera;
    camera.target = (Vector2){player.rect.x, player.rect.y};
    camera.offset = (Vector2){viewWidth / 2.0f, viewHeight / 2.0f};
    camera.rotation = 0.0f;
    camera.zoom = 1.0f;

    World *world = (World*)malloc(sizeof(World));
    LoadWorld(world);


    // game loop
    while (!WindowShouldClose())
    {
        float frameTime = GetFrameTime();
        if (frameTime > 2.0f) frameTime = 0.25f;

        time += frameTime;

        Autosave(world, &autosaveCount, &isWorldModified, frameTime);

        // input

        int condition = WorldInteraction(world, &player, &isWorldModified, camera, viewWidth, viewHeight, targetTileType);

        if (condition) {
            if (PLATFORM_MOBILE) TouchInput(&player, &targetTileType);
        }

        if (PLATFORM_DESKTOP) KeyboardInput(&player, &targetTileType);


        while (time >= dt) {
            time -= dt;

            // move

            MovePlayer(&player, world, dt);
            MoveCamera(&camera, &player, dt);


        }

        float scale = (float) GetScreenWidth() * invViewWidth;
        if ((viewHeight * scale) > GetScreenHeight()) {
            scale = (float) GetScreenHeight() * invViewHeight;
        }

        // draw


        BeginTextureMode(view);
        ClearBackground(GRAY);

        DrawPlayer(&player, camera);
        DrawWorld(world, camera);

        switch (targetTileType) {
            case 0:
                DrawText("Destroy Mode", 8, 3, 20, BLUE);
                break;
            case 1:
                DrawText("Build Mode", 8, 3, 20, GREEN);
                break;
            case 2:
                DrawText("None", 8, 3, 20, PINK);
                break;
        }

        if (isWorldModified && autosaveCount < 2.0f) {
            DrawText("Saving World...", viewWidth - 145, 3, 20, PURPLE);
        }
        EndTextureMode();


        BeginDrawing();
        ClearBackground(BLACK);
        DrawTexturePro(
                view.texture,
                (Rectangle){0.0f, 0.0f, (float)view.texture.width, (float)-view.texture.height},
                (Rectangle){
                        ((float)GetScreenWidth() - ((float)viewWidth * scale)) * 0.5f,
                        ((float)GetScreenHeight() - ((float)viewHeight * scale)) * 0.5f,
                        (float)viewWidth * scale,
                        (float)viewHeight * scale
                },
                (Vector2){0.0f, 0.0f},
                0.0f,
                WHITE
        );
        EndDrawing();
    }

    SaveWorld(world, &isWorldModified);
    free(world);

    UnloadRenderTexture(view);
    CloseWindow();

    return 0;
}
