#ifndef MAIN_H_SNAKE
#define MAIN_H_SNAKE

#include "raylib.h"

/* --- DEBUG --- */
// #define DEBUG // Include debug code

#ifdef DEBUG

extern int logIsAppleInSnake;
extern double timeToGetApple;

#endif // DEBUG

/* Defines */

// Colors
#define CYAN_COLOR_S_HEX 0x58bcbc
#define BROWN_COLOR_S_HEX 0xbc8a58
#define DARK_MAMBA                                                             \
    (Color) { 139, 120, 143, 255 }
#define SOFT_RED                                                               \
    (Color) { 195, 89, 89, 255 }
#define SOFT_GREEN                                                             \
    (Color) { 135, 193, 155, 255 }
#define BANANA                                                                 \
    (Color) { 214, 222, 146, 255 }
#define SNAKE_HEAD_COLOR                                                       \
    (Color) { 197, 120, 180, 255 }
#define SNAKE_BODY_COLOR                                                       \
    (Color) { 136, 82, 125, 255 }
#define SNAKE_BACKGROUND_COLOR                                                 \
    (Color) { 47, 29, 62, 255 }

// Numeric values
#define MAX_FPS 60
#define SNAKE_SIZE                                                             \
    12.0f // screen height is divided by this to get snake block size
#define FIELD_SIZE                                                             \
    9 // has to be int, less than SNAKE_SIZE, multiplied by snake block size
#define SNAKE_SPEED 1.0f // time passed before snake moves in seconds
#define APPLE_SPEED 8.0f // time passed before new apple spawn in seconds
#define GET_APPLE_MAX_TRIES 100000 // max N of tries to get apple
#define APPLE_SPEED_FIRST 0.2f     // in seconds
#define INITIAL_GAME_STATE GAME_MENU

// String literals
#define TITLE (char *)"Snake"

// Game entities
typedef enum DIRECTION { UP, DOWN, LEFT, RIGHT } DIRECTION;

// Game states
typedef enum SnakeGameState {
    GAME_OVER,
    GAME_ON,
    GAME_MENU_SETTINGS,
    GAME_MENU,
    GAME_SCREEN_FILLED,
    GAME_SET_CONTROLS,
    GAME_EXIT
} SnakeGameState;

typedef struct SnakeBlock {
    Rectangle body;
    struct SnakeBlock *next;
} SnakeBlock;

typedef struct Snake {
    SnakeBlock *head;
    SnakeBlock *tail;
    DIRECTION direction : 3; // 0, 1, 2, 3 (four directions)
} Snake;

// Bit flags, actual flag is stored in GameData struct
typedef enum GameSettingsFlags {
    SET_SNAKE_SHOW_FPS = 0x00000001,
    SET_SNAKE_FULL_SCREEN = 0x00000002
} GameSettingsFlags;

typedef struct Controls {
    KeyboardKey snakeUp;
    KeyboardKey snakeDown;
    KeyboardKey snakeLeft;
    KeyboardKey snakeRight;
    KeyboardKey exitKeyFirst;
    KeyboardKey exitKeyLast;
    KeyboardKey *changedKey;
} Controls;

// raygui button
typedef struct ButtonSnake {
    Rectangle rec;
    char *name;
} ButtonSnake;

typedef struct GameMenu {
    ButtonSnake buttonGroup;
    ButtonSnake bPlay;
    ButtonSnake bSettings;
    ButtonSnake bExit;
    int fontSize;
} GameMenu;

typedef struct SettingsMenu {
    ButtonSnake group;
    ButtonSnake groupControls;
    ButtonSnake changeResolution;
    ButtonSnake changeResValues;
    ButtonSnake setSnakeUp;
    ButtonSnake setSnakeDown;
    ButtonSnake setSnakeRight;
    ButtonSnake setSnakeLeft;
    ButtonSnake checkFullScreen;
    ButtonSnake checkFPS;
    ButtonSnake save;
    int changeResBoxValue;
    bool changeResEditMode;
    bool checkFPSBool;
    bool checkFullScreenBool;
    int fontSize;
} SettingsMenu;

typedef struct GameData {
    char *gameOverMsg;
    char *alertMsg;
    float dtSnake;
    float dtApple;
    float blockSize;
    int maxBlocks;
    Rectangle gameField;
    Rectangle apple;
    SnakeBlock *snakeBlocks;
    Snake snakePlayer;
    Controls CONTROLS;
    bool appleActive;
    SnakeGameState GAME_STATE;
    bool **appleMatrix;
    unsigned int gameSettingsFlags;
    Texture2D snakeHeadTex;
    Texture2D snakeBodyTex;
    Texture2D appleTex;
    Sound fxMove;
    Sound dxApple;
    Sound fxLoss;
    unsigned short blocksCounter;
} GameData;

#endif // !MAIN_H_SNAKE
