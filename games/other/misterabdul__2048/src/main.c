#include <math.h>
#include <raylib.h>
#include <stdbool.h>
#include <stdio.h>

#ifdef PLATFORM_WEB
#include <emscripten/emscripten.h>
#endif

#define RAYLIB_LOG_LEVEL LOG_ERROR

#define COLOR_CLEAR           CLITERAL(Color){90, 90, 90, 255}
#define COLOR_SCORE_TEXT      WHITE
#define COLOR_OVER_TEXT       WHITE
#define COLOR_OVER_BOX        CLITERAL(Color){80, 80, 80, 220}
#define COLOR_CONTAINER_BACK  GRAY
#define COLOR_CONTAINER_BOX   LIGHTGRAY
#define COLOR_TILE_TEXT_DARK  CLITERAL(Color){119, 110, 101, 255}
#define COLOR_TILE_TEXT_LIGHT CLITERAL(Color){249, 246, 242, 255}
#define COLOR_TILE_2          CLITERAL(Color){238, 228, 218, 255}
#define COLOR_TILE_4          CLITERAL(Color){237, 224, 200, 255}
#define COLOR_TILE_8          CLITERAL(Color){242, 177, 121, 255}
#define COLOR_TILE_16         CLITERAL(Color){245, 149, 99, 255}
#define COLOR_TILE_32         CLITERAL(Color){246, 124, 95, 255}
#define COLOR_TILE_64         CLITERAL(Color){246, 94, 59, 255}
#define COLOR_TILE_128        CLITERAL(Color){237, 207, 114, 255}
#define COLOR_TILE_256        CLITERAL(Color){237, 204, 97, 255}
#define COLOR_TILE_512        CLITERAL(Color){237, 200, 80, 255}
#define COLOR_TILE_1024       CLITERAL(Color){237, 197, 63, 255}
#define COLOR_TILE_2048       CLITERAL(Color){237, 194, 46, 255}
#define COLOR_TILE_4096       CLITERAL(Color){60, 58, 50, 255}

#define SCREEN_WIDTH         480
#define SCREEN_HEIGHT        854
#define SCREEN_ZOOM          1.0f
#define SCREEN_CAMERA_OFFSET 150.0f

#define SWIPE_RELEASE_THRESHOLD 50.0f
#define SWIPE_HOLD_THRESHOLD    70.0f

#define GAME_STARTING_TILE      2
#define GAME_SCORE_FONT_SIZE    40
#define GAME_SCORE_TEXT_PADDING 10
#define GAME_OVER_FONT_SIZE     30
#define GAME_OVER_BOX_WIDTH     300
#define GAME_OVER_BOX_HEIGHT    80
#define GAME_OVER_BOX_OFFSET    50.0f

#define BACKGROUND_SIDE 480

#define CONTAINER_TILE_SIDE 4

#define TILE_ITEM_SIZE       CONTAINER_TILE_SIDE* CONTAINER_TILE_SIDE + 1
#define TILE_MARGIN          10.0f
#define TILE_APPEAR_SPEED    30.0f
#define TILE_MOVE_SPEED      40.0f
#define TILE_DISAPPEAR_SPEED 60.0f
#define TILE_FONT_SIZE       30

typedef enum {
    INPUT_KEY_UP = 0,
    INPUT_KEY_LEFT = 1,
    INPUT_KEY_DOWN = 2,
    INPUT_KEY_RIGHT = 3,
    INPUT_KEY_NONE = 4,
} InputKey;

typedef enum {
    GAME_STATE_RESET = 0,
    GAME_STATE_IDLE = 1,
    GAME_STATE_ANIMATE = 2,
    GAME_STATE_OVER = 3,
} GameState;

typedef enum {
    TILE_STATE_UNUSED = 0,
    TILE_STATE_IDLE = 1,
    TILE_STATE_APPEAR = 2,
    TILE_STATE_MOVE = 3,
    TILE_STATE_DISAPPEAR = 4,
} TileState;

typedef enum {
    CONTAINER_MOVE_TILE_UP = 0,
    CONTAINER_MOVE_TILE_LEFT = 1,
    CONTAINER_MOVE_TILE_DOWN = 2,
    CONTAINER_MOVE_TILE_RIGHT = 3,
} ContainerMoveTileDirection;

typedef struct {
    TileState state;
    Rectangle animate;
    Rectangle move;
    Rectangle box;
    int number;
} Tile;

typedef struct {
    Rectangle boxes[CONTAINER_TILE_SIDE][CONTAINER_TILE_SIDE];
    Tile* tiles[CONTAINER_TILE_SIDE][CONTAINER_TILE_SIDE];
    bool marks[CONTAINER_TILE_SIDE][CONTAINER_TILE_SIDE];
    Rectangle background;
    float tileSide;
} Container;

typedef struct {
    int x;
    int y;
} ContainerTileVector;

typedef struct {
    Vector2 start;
    bool isDown;
} SwipeInput;

typedef struct {
    Camera2D camera;

    GameState state;

    Container container;
    Tile tiles[TILE_ITEM_SIZE];

    unsigned int score;

    Rectangle overBox;
    Rectangle restartBox;
} Game;

void GameInit(Game* game);
void GameReset(Game* game);
void GameProcessInput(Game* game, InputKey inputKey);
void GameUpdate(Game* game, float frameTime);
void GameWaitRestart(Game* game);
void GameDraw(Game* game);

void FrameUpdateDraw(void);

Game game;
SwipeInput swipeInput;

int main(void) {
    SetTraceLogLevel(RAYLIB_LOG_LEVEL);

    SetConfigFlags(FLAG_VSYNC_HINT);
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "2048");

    game = (Game){0};
    GameInit(&game);
    swipeInput = (SwipeInput){0};

#ifdef PLATFORM_WEB
    emscripten_set_main_loop(FrameUpdateDraw, 0, 1);
#else
    for (; !WindowShouldClose();) {
        FrameUpdateDraw();
    }
#endif

    CloseWindow();

    return 0;
}

InputKey InputKeyGet(void) {
    int pressedKey = GetKeyPressed();
    switch (pressedKey) {
        case KEY_UP:
            return INPUT_KEY_UP;
        case KEY_LEFT:
            return INPUT_KEY_LEFT;
        case KEY_DOWN:
            return INPUT_KEY_DOWN;
        case KEY_RIGHT:
            return INPUT_KEY_RIGHT;
    }

    if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
        swipeInput.start = GetMousePosition();
        swipeInput.isDown = true;
    } else if (swipeInput.isDown) {
        Vector2 end = GetMousePosition();
        float dx = end.x - swipeInput.start.x;
        float dy = end.y - swipeInput.start.y;
        float distance = sqrtf((dx * dx) + (dy * dy));

        float threshold = IsMouseButtonReleased(MOUSE_BUTTON_LEFT) ? SWIPE_RELEASE_THRESHOLD : SWIPE_HOLD_THRESHOLD;
        if (distance > threshold) {
            swipeInput.isDown = false;
            if (fabsf(dx) > fabsf(dy)) {
                return dx > 0 ? INPUT_KEY_RIGHT : INPUT_KEY_LEFT;
            } else {
                return dy > 0 ? INPUT_KEY_DOWN : INPUT_KEY_UP;
            }
        }
    }

    return INPUT_KEY_NONE;
}

bool InputRestartGet(Camera2D camera, Rectangle buttonBox) {
    int pressedKey = GetKeyPressed();
    if (pressedKey == KEY_SPACE) {
        return true;
    }

    if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
        Vector2 mousePos = GetScreenToWorld2D(GetMousePosition(), camera);
        if (CheckCollisionPointRec(mousePos, buttonBox)) {
            return true;
        }
    }

    return false;
}

void FrameUpdateDraw(void) {
    float frameTime = GetFrameTime();

    switch (game.state) {
        case GAME_STATE_RESET:
            GameReset(&game);
            break;
        case GAME_STATE_IDLE:
            GameProcessInput(&game, InputKeyGet());
            break;
        case GAME_STATE_ANIMATE:
            GameUpdate(&game, frameTime);
            break;
        case GAME_STATE_OVER:
            GameWaitRestart(&game);
            break;
        default:
            break;
    }

    BeginDrawing();
    {
        ClearBackground(COLOR_CLEAR);
        BeginMode2D(game.camera);
        {
            GameDraw(&game);
        }
        EndMode2D();
    }
    EndDrawing();
}

void DrawTextRec(Rectangle rec, const char* text, int fontSize, Color color) {
    if (rec.height < fontSize) {
        return;
    }

    int width = MeasureText(text, fontSize);
    int posX = rec.x + (rec.width / 2) - (width / 2);
    int posY = rec.y + (rec.height / 2) - (fontSize / 2);

    DrawText(text, posX, posY, fontSize, color);
}

void TilesDraw(Tile* tiles) {
    for (int i = 0; i < TILE_ITEM_SIZE; i++) {
        if (tiles[i].state == TILE_STATE_UNUSED) {
            continue;
        }

        Color color;
        switch (tiles[i].number) {
            default:
                color = COLOR_TILE_4096;
                break;
            case 2:
                color = COLOR_TILE_2;
                break;
            case 4:
                color = COLOR_TILE_4;
                break;
            case 8:
                color = COLOR_TILE_8;
                break;
            case 16:
                color = COLOR_TILE_16;
                break;
            case 32:
                color = COLOR_TILE_32;
                break;
            case 64:
                color = COLOR_TILE_64;
                break;
            case 128:
                color = COLOR_TILE_128;
                break;
            case 256:
                color = COLOR_TILE_256;
                break;
            case 512:
                color = COLOR_TILE_512;
                break;
            case 1024:
                color = COLOR_TILE_1024;
                break;
            case 2048:
                color = COLOR_TILE_2048;
                break;
        }
        DrawRectangleRec(tiles[i].box, color);

        char buff[12];
        sprintf(buff, "%u", tiles[i].number);
        if (tiles[i].number <= 4) {
            DrawTextRec(tiles[i].box, buff, TILE_FONT_SIZE, COLOR_TILE_TEXT_DARK);
        } else {
            DrawTextRec(tiles[i].box, buff, TILE_FONT_SIZE, COLOR_TILE_TEXT_LIGHT);
        }
    }
}

void TilesReset(Tile* tiles) {
    for (int i = 0; i < TILE_ITEM_SIZE; i++) {
        tiles[i] = (Tile){0};
    }
}

bool TilesAppear(Tile* tiles, float frameTime) {
    float fraction = (TILE_APPEAR_SPEED * frameTime);
    bool result = false;

    for (int i = 0; i < TILE_ITEM_SIZE; i++) {
        if (tiles[i].state != TILE_STATE_APPEAR) {
            continue;
        }

        result = true;
        float nextX = (tiles[i].animate.x - tiles[i].box.x) * fraction;
        float nextY = (tiles[i].animate.y - tiles[i].box.y) * fraction;
        float nextW = (tiles[i].animate.width - tiles[i].box.width) * fraction;
        float nextH = (tiles[i].animate.height - tiles[i].box.height) * fraction;
        if (fabsf(nextX) < 0.1f && fabsf(nextY) < 0.1f && fabsf(nextW) < 0.1f && fabsf(nextH) < 0.1f) {
            tiles[i].state = TILE_STATE_IDLE;
            tiles[i].box = tiles[i].animate;
        } else {
            tiles[i].box.x += nextX;
            tiles[i].box.y += nextY;
            tiles[i].box.width += nextW;
            tiles[i].box.height += nextH;
        }
    }

    return result;
}

bool TilesMove(Tile* tiles, float frameTime) {
    float fraction = (TILE_MOVE_SPEED * frameTime);
    bool result = false;

    for (int i = 0; i < TILE_ITEM_SIZE; i++) {
        if (tiles[i].state != TILE_STATE_MOVE) {
            continue;
        }

        result = true;
        float nextX = (tiles[i].move.x - tiles[i].box.x) * fraction;
        float nextY = (tiles[i].move.y - tiles[i].box.y) * fraction;
        if (fabsf(nextX) < 0.1f && fabsf(nextY) < 0.1f) {
            tiles[i].state = TILE_STATE_IDLE;
            tiles[i].box = tiles[i].move;
        } else {
            tiles[i].box.x += nextX;
            tiles[i].box.y += nextY;
        }
    }

    return result;
}

bool TilesDisappear(Tile* tiles, float frameTime) {
    float fraction = (TILE_APPEAR_SPEED * frameTime);
    bool result = false;

    for (int i = 0; i < TILE_ITEM_SIZE; i++) {
        if (tiles[i].state != TILE_STATE_DISAPPEAR) {
            continue;
        }

        result = true;
        float nextX = (tiles[i].animate.x - tiles[i].box.x) * fraction;
        float nextY = (tiles[i].animate.y - tiles[i].box.y) * fraction;
        float nextW = (tiles[i].animate.width - tiles[i].box.width) * fraction;
        float nextH = (tiles[i].animate.height - tiles[i].box.height) * fraction;
        if (fabsf(nextX) < 0.1f && fabsf(nextY) < 0.1f && fabsf(nextW) < 0.1f && fabsf(nextH) < 0.1f) {
            tiles[i].state = TILE_STATE_UNUSED;
        } else {
            tiles[i].box.x += nextX;
            tiles[i].box.y += nextY;
            tiles[i].box.width += nextW;
            tiles[i].box.height += nextH;
        }
    }

    return result;
}

Tile* TilesGetUnused(Tile* tiles) {
    for (int i = 0; i < TILE_ITEM_SIZE; i++) {
        if (tiles[i].state != TILE_STATE_UNUSED) {
            continue;
        }
        return &tiles[i];
    }

    return NULL;
}

void TileSetAppear(Tile* tile, Rectangle box) {
    tile->state = TILE_STATE_APPEAR;
    tile->animate = box;
    tile->box = (Rectangle){
        box.x + (box.width / 2.0f),
        box.y + (box.height / 2.0f),
        0.0f,
        0.0f,
    };
}

void TileSetMove(Tile* tile, Rectangle target) {
    tile->state = TILE_STATE_MOVE;
    tile->move = target;
}

void TileSetDisappear(Tile* tile) {
    tile->state = TILE_STATE_DISAPPEAR;
    tile->animate = (Rectangle){
        tile->box.x + (tile->box.width / 2.0f),
        tile->box.y + (tile->box.height / 2.0f),
        0.0f,
        0.0f,
    };
}

bool TileTryMerge(Tile* destination, Tile* source) {
    if (destination->number != source->number) {
        return false;
    }

    TileSetDisappear(source);
    destination->number *= 2;

    return true;
}

void ContainerDraw(Container* container) {
    DrawRectangleRec(container->background, COLOR_CONTAINER_BACK);
    for (int x = 0; x < CONTAINER_TILE_SIDE; x++) {
        for (int y = 0; y < CONTAINER_TILE_SIDE; y++) {
            DrawRectangleRec(container->boxes[x][y], COLOR_CONTAINER_BOX);
        }
    }
}

void ContainerReset(Container* container) {
    container->background = (Rectangle){0.0f, 0.0f, BACKGROUND_SIDE, BACKGROUND_SIDE};
    container->tileSide = (BACKGROUND_SIDE - TILE_MARGIN) / (float)CONTAINER_TILE_SIDE;
    for (int x = 0; x < CONTAINER_TILE_SIDE; x++) {
        for (int y = 0; y < CONTAINER_TILE_SIDE; y++) {
            container->tiles[x][y] = NULL;
            container->boxes[x][y] = (Rectangle){
                (x * container->tileSide) + TILE_MARGIN,
                (y * container->tileSide) + TILE_MARGIN,
                container->tileSide - TILE_MARGIN,
                container->tileSide - TILE_MARGIN,
            };
        }
    }
}

bool ContainerPlaceTile(Container* container, Tile* tile) {
    ContainerTileVector blanks[CONTAINER_TILE_SIDE * CONTAINER_TILE_SIDE];

    int blankCount = 0;
    for (int x = 0; x < CONTAINER_TILE_SIDE; x++) {
        for (int y = 0; y < CONTAINER_TILE_SIDE; y++) {
            if (container->tiles[x][y] != NULL) {
                continue;
            }
            blanks[blankCount++] = (ContainerTileVector){x, y};
        }
    }
    if (blankCount == 0) {
        return false;
    }

    ContainerTileVector blank = blanks[GetRandomValue(0, blankCount - 1)];
    container->tiles[blank.x][blank.y] = tile;
    TileSetAppear(tile, container->boxes[blank.x][blank.y]);
    return true;
}

bool ContainerCanMoveTiles(Container* container) {
    for (int x = 0; x < CONTAINER_TILE_SIDE; x++) {
        for (int y = 0; y < CONTAINER_TILE_SIDE; y++) {
            Tile* tile = container->tiles[x][y];
            if (tile == NULL) {
                return true;
            }
            if (x + 1 < CONTAINER_TILE_SIDE) {
                Tile* right = container->tiles[x + 1][y];
                if (right == NULL || right->number == tile->number) {
                    return true;
                }
            }
            if (y + 1 < CONTAINER_TILE_SIDE) {
                Tile* bottom = container->tiles[x][y + 1];
                if (bottom == NULL || bottom->number == tile->number) {
                    return true;
                }
            }
        }
    }

    return false;
}

int ContainerMoveTiles(Container* container, ContainerMoveTileDirection direction) {
    int totalScore = 0;
    bool moved = false;

    int dx = 0, dy = 0;
    switch (direction) {
        default:
            return -1;
        case CONTAINER_MOVE_TILE_UP:
            dy = -1;
            break;
        case CONTAINER_MOVE_TILE_LEFT:
            dx = -1;
            break;
        case CONTAINER_MOVE_TILE_DOWN:
            dy = 1;
            break;
        case CONTAINER_MOVE_TILE_RIGHT:
            dx = 1;
            break;
    }

    for (int x = 0; x < CONTAINER_TILE_SIDE; x++) {
        for (int y = 0; y < CONTAINER_TILE_SIDE; y++) {
            container->marks[x][y] = false;
        }
    }

    for (int i = 0; i < CONTAINER_TILE_SIDE; i++) {
        int x = dx == 1 ? (CONTAINER_TILE_SIDE - 1 - i) : i;
        for (int j = 0; j < CONTAINER_TILE_SIDE; j++) {
            int y = dy == 1 ? (CONTAINER_TILE_SIDE - 1 - j) : j;

            Tile* tile = container->tiles[x][y];
            if (tile == NULL) {
                continue;
            }

            for (int currX = x, currY = y;; currX += dx, currY += dy) {
                int nextX = currX + dx, nextY = currY + dy;
                if (nextX < 0 || nextX >= CONTAINER_TILE_SIDE || nextY < 0 || nextY >= CONTAINER_TILE_SIDE) {
                    break;
                }
                if (container->marks[nextX][nextY]) {
                    break;
                }

                Tile* next = container->tiles[nextX][nextY];
                if (next == NULL) {
                    TileSetMove(tile, container->boxes[nextX][nextY]);
                    container->tiles[nextX][nextY] = tile;
                    container->tiles[currX][currY] = NULL;
                    moved = true;
                    continue;
                }

                if (TileTryMerge(tile, next)) {
                    TileSetMove(tile, container->boxes[nextX][nextY]);
                    container->tiles[nextX][nextY] = tile;
                    container->tiles[currX][currY] = NULL;
                    container->marks[nextX][nextY] = true;
                    totalScore += tile->number;
                    moved = true;
                }
                break;
            }
        }
    }

    return moved ? totalScore : -1;
}

int ContainerProcessInput(Container* container, InputKey input) {
    switch (input) {
        default:
            break;
        case INPUT_KEY_UP:
            return ContainerMoveTiles(container, CONTAINER_MOVE_TILE_UP);
        case INPUT_KEY_LEFT:
            return ContainerMoveTiles(container, CONTAINER_MOVE_TILE_LEFT);
        case INPUT_KEY_DOWN:
            return ContainerMoveTiles(container, CONTAINER_MOVE_TILE_DOWN);
        case INPUT_KEY_RIGHT:
            return ContainerMoveTiles(container, CONTAINER_MOVE_TILE_RIGHT);
    }

    return -1;
}

void GameInit(Game* game) {
    game->camera = (Camera2D){0};
    game->camera.zoom = SCREEN_ZOOM;
    game->camera.offset = (Vector2){0.0f, SCREEN_CAMERA_OFFSET};
    game->camera.target = (Vector2){0.0f, 0.0f};

    game->overBox = (Rectangle){
        (SCREEN_WIDTH / 2.0f) - (GAME_OVER_BOX_WIDTH / 2.0f),
        (SCREEN_HEIGHT / 2.0f) - (GAME_OVER_BOX_HEIGHT / 2.0f) - (SCREEN_CAMERA_OFFSET + GAME_OVER_BOX_OFFSET),
        GAME_OVER_BOX_WIDTH,
        GAME_OVER_BOX_HEIGHT,
    };
    game->restartBox = (Rectangle){
        (SCREEN_WIDTH / 2.0f) - (GAME_OVER_BOX_WIDTH / 2.0f),
        (SCREEN_HEIGHT / 2.0f) - (GAME_OVER_BOX_HEIGHT / 2.0f) - (SCREEN_CAMERA_OFFSET - GAME_OVER_BOX_OFFSET),
        GAME_OVER_BOX_WIDTH,
        GAME_OVER_BOX_HEIGHT,
    };
}

void GameReset(Game* game) {
    ContainerReset(&game->container);
    TilesReset(game->tiles);

    for (int i = 0; i < GAME_STARTING_TILE; i++) {
        Tile* newTile = &game->tiles[i];
        newTile->number = GetRandomValue(1, 2) * 2;
        ContainerPlaceTile(&game->container, newTile);
    }
    game->state = GAME_STATE_ANIMATE;
    game->score = 0;
}

void GameUpdate(Game* game, float frameTime) {
    if (game->state != GAME_STATE_ANIMATE) {
        return;
    }

    GameState nextState = GAME_STATE_IDLE;
    if (TilesDisappear(game->tiles, frameTime)) {
        nextState = GAME_STATE_ANIMATE;
    }
    if (TilesMove(game->tiles, frameTime)) {
        nextState = GAME_STATE_ANIMATE;
    } else if (TilesAppear(game->tiles, frameTime)) {
        nextState = GAME_STATE_ANIMATE;
    }
    if (nextState == GAME_STATE_IDLE && !ContainerCanMoveTiles(&game->container)) {
        nextState = GAME_STATE_OVER;
    }

    game->state = nextState;
}

void GameProcessInput(Game* game, InputKey inputKey) {
    if (inputKey == INPUT_KEY_NONE) {
        return;
    }

    int score = ContainerProcessInput(&game->container, inputKey);
    if (score == -1) {
        return;
    }
    game->score += score;

    Tile* newTile = TilesGetUnused(game->tiles);
    newTile->number = GetRandomValue(1, 2) * 2;
    if (!ContainerPlaceTile(&game->container, newTile)) {
        game->state = GAME_STATE_OVER;
    }

    game->state = GAME_STATE_ANIMATE;
}

void GameWaitRestart(Game* game) {
    if (!InputRestartGet(game->camera, game->restartBox)) {
        return;
    }

    GameReset(game);
}

void GameDraw(Game* game) {
    ContainerDraw(&game->container);
    TilesDraw(game->tiles);

    char buff[32];
    sprintf(buff, "%d", game->score);
    int width = MeasureText(buff, GAME_SCORE_FONT_SIZE);
    int posX = SCREEN_WIDTH - (width + GAME_SCORE_TEXT_PADDING);
    int posY = -(GAME_SCORE_FONT_SIZE + GAME_SCORE_TEXT_PADDING);
    DrawText(buff, posX, posY, GAME_SCORE_FONT_SIZE, COLOR_SCORE_TEXT);

    if (game->state == GAME_STATE_OVER) {
        DrawRectangleRounded(game->overBox, 0.3f, 2, COLOR_OVER_BOX);
        DrawTextRec(game->overBox, "Game Over", GAME_OVER_FONT_SIZE, COLOR_OVER_TEXT);

        DrawRectangleRounded(game->restartBox, 0.3f, 2, COLOR_OVER_BOX);
        DrawTextRec(game->restartBox, "Restart", GAME_OVER_FONT_SIZE, COLOR_OVER_TEXT);
    }
}
