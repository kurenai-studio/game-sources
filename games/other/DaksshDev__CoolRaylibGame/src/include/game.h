#ifndef GAME_H
#define GAME_H

// Core game types and shared state.
// This header is intentionally small and beginner‑friendly:
// most logic lives in the .cpp files, while the structs here describe
// the data the whole game shares.

#include "raylib.h"
#include "raymath.h"

// Maze settings (Level 3)
#define MAZE_SIZE 21          // Maze grid is MAZE_SIZE x MAZE_SIZE cells
#define MAZE_TILE_SIZE 40     // Each cell is a MAZE_TILE_SIZE x MAZE_TILE_SIZE tile in pixels

// High‑level game phases. The Update/Render functions drive everything
// by switching on this enum.
typedef enum {
    TUTORIAL_MOVE_WINDOW,
    TUTORIAL_COMPLETE,
    TUTORIAL_RESIZE_WINDOW,
    TUTORIAL_RESIZE_COMPLETE,
    MAIN_MENU,
    LEVEL_1,
    LEVEL_2,
    LEVEL_3
} GamePhase;

typedef enum {
    RESIZE_NONE,
    RESIZE_RIGHT,
    RESIZE_BOTTOM,
    RESIZE_CORNER
} ResizeMode;

typedef struct {
    Vector2 position;
    Vector2 velocity;
    Vector2 acceleration;
    float size;
    float mass;
    float damping;
    bool visible;
} Cube;

typedef struct {
    Vector2 position;
    float size;
    bool visible;
} GreenCube;

typedef struct {
    Vector2 points[3];  // Triangle has 3 points
    bool active;
} Triangle;

typedef struct {
    Vector2 lastWindowPos;
    Vector2 windowVelocity;
    Vector2 lastWindowVelocity;
} WindowPhysics;

typedef struct {
    bool isDragging;
    Vector2 dragStartMouseScreen;
    Vector2 dragStartWindowPos;
} DragState;

typedef struct {
    bool isResizing;
    ResizeMode mode;
    Vector2 resizeStartMousePos;
    Vector2 resizeStartSize;
} ResizeState;

typedef struct {
    Rectangle bounds;
    const char* text;
    bool isHovered;
} Button;

typedef struct {
    Cube cube;
    GreenCube greenCube;
    Triangle triangles[5];  // Max 5 triangles per level
    int triangleCount;
    // Level 2 layout is based on the window size when you FIRST enter
    // the level. Restarts use the same dimensions so spikes don't jump
    // around if you resize between deaths.
    int level2LayoutWidth;
    int level2LayoutHeight;
    int maze[MAZE_SIZE][MAZE_SIZE];  // Level 3: 0 = wall, 1 = path. Outer border is always walls.
    WindowPhysics windowPhysics;
    DragState dragState;
    ResizeState resizeState;
    GamePhase phase;
    float phaseTimer;
    int titleBarHeight;
    int resizeHandleSize;
    float gravity;
    bool shouldClose;
    bool hasExistingGame;
    Button newGameButton;
    Button loadGameButton;
    bool levelComplete;
    bool gameOver;
    int currentLevel;
} GameState;

GameState InitGame();
void UpdateGame(GameState* state);
void RenderGame(GameState* state);

// Level helpers: these reset the important parts of GameState
// and are the only places that start a new level.
void StartLevel1(GameState* state);
void StartLevel2(GameState* state);
void StartLevel3(GameState* state);
void RestartLevel(GameState* state);

bool IsButtonClicked(Button* button, Vector2 mousePos);
bool CheckCubeTriangleCollision(Cube* cube, Triangle* triangle);

// Simple save system: only serialises the minimum state needed to
// resume at the main menu or inside a level.
bool SaveGame(const GameState* state);
bool LoadGame(GameState* state);
bool SaveFileExists();

// Level 3 (maze) helpers
void GenerateMaze(GameState* state);
void DrawMaze(const GameState* state);
bool WouldCubeOverlapWall(const GameState* state, Vector2 cubePosition);

#endif