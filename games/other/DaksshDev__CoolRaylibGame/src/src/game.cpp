#include "game.h"
#include "physics.h"
#include "ui.h"
#include <cmath>
#include <fstream>
#include <cstdlib>
#include <cstring>

// Create a default GameState.
// This is the main entry point for setting up the window, cube and UI.
GameState InitGame()
{
    GameState state = {};
    
    // Cube starts as a simple falling box; individual levels
    // can override these values later.
    state.cube.position = {400, 100};
    state.cube.velocity = {0, 0};
    state.cube.acceleration = {0, 0};
    state.cube.size = 50;
    state.cube.mass = 1.0f;
    state.cube.damping = 0.98f;
    state.cube.visible = true;
    
    // Initialize green cube
    state.greenCube.size = 50;
    state.greenCube.visible = false;
    
    // Initialize window physics (used for "shake" based movement)
    state.windowPhysics.lastWindowPos = GetWindowPosition();
    state.windowPhysics.windowVelocity = {0, 0};
    state.windowPhysics.lastWindowVelocity = {0, 0};
    
    // Initialize drag state
    state.dragState.isDragging = false;
    state.dragState.dragStartMouseScreen = {0, 0};
    state.dragState.dragStartWindowPos = {0, 0};
    
    // Initialize resize state
    state.resizeState.isResizing = false;
    state.resizeState.mode = RESIZE_NONE;
    state.resizeState.resizeStartMousePos = {0, 0};
    state.resizeState.resizeStartSize = {0, 0};
    
    // Game state defaults
    state.phase = TUTORIAL_MOVE_WINDOW;
    state.phaseTimer = 0;
    state.titleBarHeight = 35;
    state.resizeHandleSize = 10;
    state.gravity = 500;
    state.shouldClose = false;
    state.hasExistingGame = false;
    state.levelComplete = false;
    state.gameOver = false;
    state.currentLevel = 0;
    state.triangleCount = 0;
    state.level2LayoutWidth = 0;
    state.level2LayoutHeight = 0;
    
    // Initialize buttons
    state.newGameButton.text = "New Game";
    state.loadGameButton.text = "Load Game";
    
    // If save file exists, skip tutorial and go to main menu
    if (SaveFileExists())
    {
        state.hasExistingGame = true;
        state.phase = MAIN_MENU;
        int w = GetScreenWidth();
        int h = GetScreenHeight();
        state.newGameButton.bounds = {(float)w/2 - 100, (float)h/2 - 30, 200, 50};
        state.loadGameButton.bounds = {(float)w/2 - 100, (float)h/2 + 40, 200, 50};
    }
    
    return state;
}

// Level 1 – learn to resize the window and find the green cube.
void StartLevel1(GameState* state)
{
    state->phase = LEVEL_1;
    state->currentLevel = 1;
    state->cube.position = {400, 300};
    state->cube.velocity = {0, 0};
    state->cube.acceleration = {0, 0};
    state->cube.visible = true;
    state->levelComplete = false;
    state->gameOver = false;
    state->triangleCount = 0;
    
    // Green cube appears at bottom right when window is big enough
    int screenWidth = GetScreenWidth();
    int screenHeight = GetScreenHeight();
    state->greenCube.position = {(float)screenWidth - 80, (float)screenHeight - 80};
    state->greenCube.visible = false;  // Will appear when resized
}

// Level 2 – triangle hazards + hidden green cube.
void StartLevel2(GameState* state)
{
    state->phase = LEVEL_2;
    state->currentLevel = 2;
    state->cube.position = {100, 200};
    state->cube.velocity = {0, 0};
    state->cube.acceleration = {0, 0};
    state->cube.visible = true;
    state->levelComplete = false;
    state->gameOver = false;
    
    // Capture the window size the first time we enter Level 2.
    // Restarts reuse this size so triangle positions are stable
    // even if you resize the window between deaths.
    if (state->level2LayoutWidth == 0 || state->level2LayoutHeight == 0)
    {
        state->level2LayoutWidth = GetScreenWidth();
        state->level2LayoutHeight = GetScreenHeight();
    }
    
    int screenWidth = state->level2LayoutWidth;
    int screenHeight = state->level2LayoutHeight;
    
    // Setup triangles (spikes)
    state->triangleCount = 3;
    
    // Triangle 1 - bottom center spike
    state->triangles[0].points[0] = {(float)screenWidth/2 - 30, (float)screenHeight - 50};
    state->triangles[0].points[1] = {(float)screenWidth/2 + 30, (float)screenHeight - 50};
    state->triangles[0].points[2] = {(float)screenWidth/2, (float)screenHeight - 100};
    state->triangles[0].active = true;
    
    // Triangle 2 - left spike
    state->triangles[1].points[0] = {50, (float)screenHeight/2 - 30};
    state->triangles[1].points[1] = {50, (float)screenHeight/2 + 30};
    state->triangles[1].points[2] = {100, (float)screenHeight/2};
    state->triangles[1].active = true;
    
    // Triangle 3 - top spike
    state->triangles[2].points[0] = {(float)screenWidth/2 - 30, (float)state->titleBarHeight + 100};
    state->triangles[2].points[1] = {(float)screenWidth/2 + 30, (float)state->titleBarHeight + 100};
    state->triangles[2].points[2] = {(float)screenWidth/2, (float)state->titleBarHeight + 50};
    state->triangles[2].active = true;
    
    // Green cube hidden off screen (need to resize to find it)
    state->greenCube.position = {(float)screenWidth + 50, (float)screenHeight - 100};
    state->greenCube.visible = false;
}

// Level 3 – maze level driven entirely by window shake + gravity.
// The maze always looks the same thanks to a fixed RNG seed.
void StartLevel3(GameState* state)
{
    state->phase = LEVEL_3;
    state->currentLevel = 3;
    state->cube.velocity = {0, 0};
    state->cube.acceleration = {0, 0};
    state->cube.visible = true;
    state->levelComplete = false;
    state->gameOver = false;
    state->triangleCount = 0;
    
    GenerateMaze(state);
    
    float ts = (float)MAZE_TILE_SIZE;
    int th = state->titleBarHeight;
    state->cube.position = {ts, (float)th + ts};
    state->cube.size = (float)(MAZE_TILE_SIZE - 4);
    state->greenCube.position = {(float)(MAZE_SIZE - 2) * ts, (float)th + (MAZE_SIZE - 2) * ts};
    state->greenCube.size = (float)(MAZE_TILE_SIZE - 4);
    state->greenCube.visible = true;
}

// Restart the current level by calling the appropriate StartLevelX.
void RestartLevel(GameState* state)
{
    if (state->currentLevel == 1)
        StartLevel1(state);
    else if (state->currentLevel == 2)
        StartLevel2(state);
    else if (state->currentLevel == 3)
        StartLevel3(state);
}

// Depth‑first search maze carving using the
// classic "recursive backtracker" algorithm.
static void Carve(GameState* state, int row, int col)
{
    int* m = &state->maze[0][0];
    int w = MAZE_SIZE;
    int dr[] = {-2, 2, 0, 0};
    int dc[] = {0, 0, -2, 2};
    for (int i = 0; i < 4; i++)
    {
        int j = i + (rand() % (4 - i));
        int tdr = dr[i], tdc = dc[i];
        dr[i] = dr[j]; dc[i] = dc[j];
        dr[j] = tdr; dc[j] = tdc;
    }
    for (int i = 0; i < 4; i++)
    {
        int nr = row + dr[i], nc = col + dc[i];
        if (nr >= 1 && nr <= MAZE_SIZE - 2 && nc >= 1 && nc <= MAZE_SIZE - 2 && m[nr * w + nc] == 0)
        {
            m[(row + nr) / 2 * w + (col + nc) / 2] = 1;
            m[nr * w + nc] = 1;
            Carve(state, nr, nc);
        }
    }
}

// Fill the maze with walls and carve a reproducible
// layout using a fixed random seed.
void GenerateMaze(GameState* state)
{
    std::memset(&state->maze[0][0], 0, sizeof(state->maze));
    srand(1337);
    state->maze[1][1] = 1;
    Carve(state, 1, 1);
}

// Draw the maze as a simple grid of rectangles:
// walls = DARKGRAY, paths = BLACK.
void DrawMaze(const GameState* state)
{
    int th = state->titleBarHeight;
    int ts = MAZE_TILE_SIZE;
    for (int row = 0; row < MAZE_SIZE; row++)
    {
        for (int col = 0; col < MAZE_SIZE; col++)
        {
            int x = col * ts;
            int y = th + row * ts;
            Color c = state->maze[row][col] == 0 ? DARKGRAY : BLACK;
            DrawRectangle(x, y, ts, ts, c);
        }
    }
}

// Utility used by the Level 3 movement code:
// returns true if placing the cube's rectangle at
// cubePosition would overlap any wall tile.
bool WouldCubeOverlapWall(const GameState* state, Vector2 cubePosition)
{
    int ts = MAZE_TILE_SIZE;
    int th = state->titleBarHeight;
    float size = state->cube.size;
    int minCol = (int)(cubePosition.x / ts);
    int maxCol = (int)((cubePosition.x + size) / ts);
    int minRow = (int)((cubePosition.y - th) / ts);
    int maxRow = (int)((cubePosition.y + size - th) / ts);
    if (minCol < 0 || maxCol >= MAZE_SIZE || minRow < 0 || maxRow >= MAZE_SIZE)
        return true;
    for (int row = minRow; row <= maxRow; row++)
        for (int col = minCol; col <= maxCol; col++)
            if (state->maze[row][col] == 0)
                return true;
    return false;
}

bool CheckCubeTriangleCollision(Cube* cube, Triangle* triangle)
{
    // Simple AABB check first
    Rectangle cubeRect = {cube->position.x, cube->position.y, cube->size, cube->size};
    
    // Get triangle bounding box
    float minX = fmin(fmin(triangle->points[0].x, triangle->points[1].x), triangle->points[2].x);
    float maxX = fmax(fmax(triangle->points[0].x, triangle->points[1].x), triangle->points[2].x);
    float minY = fmin(fmin(triangle->points[0].y, triangle->points[1].y), triangle->points[2].y);
    float maxY = fmax(fmax(triangle->points[0].y, triangle->points[1].y), triangle->points[2].y);
    
    Rectangle triRect = {minX, minY, maxX - minX, maxY - minY};
    
    return CheckCollisionRecs(cubeRect, triRect);
}

bool IsButtonClicked(Button* button, Vector2 mousePos)
{
    button->isHovered = CheckCollisionPointRec(mousePos, button->bounds);
    return button->isHovered && IsMouseButtonPressed(MOUSE_LEFT_BUTTON);
}

// Main per‑frame update entry point.
// This wires together:
// - input (window drag/resize)
// - physics
// - phase/level specific logic
void UpdateGame(GameState* state)
{
    float dt = GetFrameTime();
    
    // Clamp delta time
    if (dt > 0.1f) dt = 0.016f;
    if (dt < 0.001f) dt = 0.016f;
    
    int screenWidth = GetScreenWidth();
    int screenHeight = GetScreenHeight();
    
    // Handle titlebar interaction
    if (state->phase != TUTORIAL_RESIZE_WINDOW && state->phase != TUTORIAL_RESIZE_COMPLETE)
    {
        HandleTitleBar(state, screenWidth);
    }
    
    // Handle resize
    HandleResize(state, screenWidth, screenHeight);
    
    // Handle different game phases
    if (state->phase == TUTORIAL_MOVE_WINDOW)
    {
        UpdatePhysics(state, dt, screenWidth, screenHeight);
        
        if (state->dragState.isDragging)
        {
            state->phase = TUTORIAL_COMPLETE;
            state->phaseTimer = 0;
            state->cube.visible = false;
        }
    }
    else if (state->phase == TUTORIAL_COMPLETE)
    {
        state->phaseTimer += dt;
        if (state->phaseTimer > 2.0f)
        {
            state->phase = TUTORIAL_RESIZE_WINDOW;
            state->phaseTimer = 0;
        }
    }
    else if (state->phase == TUTORIAL_RESIZE_WINDOW)
    {
        if (state->resizeState.isResizing)
        {
            state->phase = TUTORIAL_RESIZE_COMPLETE;
            state->phaseTimer = 0;
        }
    }
    else if (state->phase == TUTORIAL_RESIZE_COMPLETE)
    {
        state->phaseTimer += dt;
        if (state->phaseTimer > 2.0f)
        {
            state->phase = MAIN_MENU;
            state->newGameButton.bounds = {(float)screenWidth/2 - 100, (float)screenHeight/2 - 30, 200, 50};
            state->loadGameButton.bounds = {(float)screenWidth/2 - 100, (float)screenHeight/2 + 40, 200, 50};
        }
    }
    else if (state->phase == MAIN_MENU)
    {
        Vector2 mousePos = GetMousePosition();
        
        state->hasExistingGame = SaveFileExists();
        state->newGameButton.text = state->hasExistingGame ? "Continue" : "New Game";
        state->newGameButton.bounds = {(float)screenWidth/2 - 100, (float)screenHeight/2 - 30, 200, 50};
        state->loadGameButton.bounds = {(float)screenWidth/2 - 100, (float)screenHeight/2 + 40, 200, 50};
        
        if (IsButtonClicked(&state->newGameButton, mousePos))
        {
            if (state->hasExistingGame)
                LoadGame(state);
            else
                StartLevel1(state);
        }
        
        if (IsButtonClicked(&state->loadGameButton, mousePos))
        {
            LoadGame(state);
        }
    }
    else if (state->phase == LEVEL_1)
    {
        UpdatePhysics(state, dt, screenWidth, screenHeight);
        
        // Update green cube position when window resizes
        state->greenCube.position = {(float)screenWidth - 80, (float)screenHeight - 80};
        
        // Show green cube if window is big enough
        if (screenWidth >= 900 && screenHeight >= 700)
        {
            state->greenCube.visible = true;
        }
        else
        {
            state->greenCube.visible = false;
        }
        
        // Check collision with green cube
        if (state->greenCube.visible)
        {
            Rectangle cubeRect = {state->cube.position.x, state->cube.position.y, state->cube.size, state->cube.size};
            Rectangle greenRect = {state->greenCube.position.x, state->greenCube.position.y, 
                                   state->greenCube.size, state->greenCube.size};
            
            if (CheckCollisionRecs(cubeRect, greenRect) && !state->levelComplete)
            {
                state->levelComplete = true;
                state->phaseTimer = 0;
            }
        }
        
        // After win message, go to level 2
        if (state->levelComplete)
        {
            state->phaseTimer += dt;
            if (state->phaseTimer > 2.0f)
            {
                StartLevel2(state);
            }
        }
    }
    else if (state->phase == LEVEL_2)
    {
        UpdatePhysics(state, dt, screenWidth, screenHeight);
        
        // Update green cube to be off-screen initially
        if (!state->greenCube.visible && screenWidth >= 1000)
        {
            state->greenCube.visible = true;
            state->greenCube.position = {(float)screenWidth - 80, (float)screenHeight - 150};
        }
        
        // Check collision with triangles
        for (int i = 0; i < state->triangleCount; i++)
        {
            if (state->triangles[i].active && CheckCubeTriangleCollision(&state->cube, &state->triangles[i]))
            {
                state->gameOver = true;
                state->phaseTimer = 0;
            }
        }
        
        // Check collision with green cube
        if (state->greenCube.visible)
        {
            Rectangle cubeRect = {state->cube.position.x, state->cube.position.y, state->cube.size, state->cube.size};
            Rectangle greenRect = {state->greenCube.position.x, state->greenCube.position.y, 
                                   state->greenCube.size, state->greenCube.size};
            
            if (CheckCollisionRecs(cubeRect, greenRect) && !state->levelComplete)
            {
                state->levelComplete = true;
                state->phaseTimer = 0;
            }
        }
        
        // Handle game over
        if (state->gameOver)
        {
            state->phaseTimer += dt;
            if (state->phaseTimer > 2.0f)
            {
                RestartLevel(state);
            }
        }
        
        // Handle level complete
        if (state->levelComplete)
        {
            state->phaseTimer += dt;
            if (state->phaseTimer > 2.0f)
            {
                StartLevel3(state);
            }
        }
    }
    else if (state->phase == LEVEL_3)
    {
        int ts = MAZE_TILE_SIZE;
        int th = state->titleBarHeight;
        float mazeLeft = 0, mazeTop = (float)th;
        float mazeW = (float)(MAZE_SIZE * ts), mazeH = (float)(MAZE_SIZE * ts);
        float maxStep = (float)(ts / 2);

        Vector2 oldPosition = state->cube.position;

        UpdatePhysics(state, dt, screenWidth, screenHeight);

        state->cube.position.x = (state->cube.position.x < mazeLeft) ? mazeLeft : state->cube.position.x;
        state->cube.position.x = (state->cube.position.x + state->cube.size > mazeLeft + mazeW) ? (mazeLeft + mazeW - state->cube.size) : state->cube.position.x;
        state->cube.position.y = (state->cube.position.y < mazeTop) ? mazeTop : state->cube.position.y;
        state->cube.position.y = (state->cube.position.y + state->cube.size > mazeTop + mazeH) ? (mazeTop + mazeH - state->cube.size) : state->cube.position.y;

        float stepX = state->cube.position.x - oldPosition.x;
        float stepY = state->cube.position.y - oldPosition.y;
        if (stepX > maxStep) stepX = maxStep;
        if (stepX < -maxStep) stepX = -maxStep;
        if (stepY > maxStep) stepY = maxStep;
        if (stepY < -maxStep) stepY = -maxStep;

        Vector2 nextX = {oldPosition.x + stepX, oldPosition.y};
        if (!WouldCubeOverlapWall(state, nextX))
            state->cube.position.x = nextX.x;
        else
        {
            state->cube.position.x = oldPosition.x;
            state->cube.velocity.x = 0;
        }

        Vector2 nextY = {state->cube.position.x, oldPosition.y + stepY};
        if (!WouldCubeOverlapWall(state, nextY))
            state->cube.position.y = nextY.y;
        else
        {
            state->cube.position.y = oldPosition.y;
            state->cube.velocity.y = 0;
        }

        Rectangle cubeRect = {state->cube.position.x, state->cube.position.y, state->cube.size, state->cube.size};
        Rectangle greenRect = {state->greenCube.position.x, state->greenCube.position.y, state->greenCube.size, state->greenCube.size};
        if (CheckCollisionRecs(cubeRect, greenRect) && !state->levelComplete)
        {
            state->levelComplete = true;
            state->phaseTimer = 0;
        }
        if (state->levelComplete)
        {
            state->phaseTimer += dt;
            if (state->phaseTimer > 2.5f)
                state->shouldClose = true;
        }
    }
}

// Main per‑frame render entry point.
// Draws the custom title bar, then whatever content matches the phase.
void RenderGame(GameState* state)
{
    int screenWidth = GetScreenWidth();
    int screenHeight = GetScreenHeight();
    
    BeginDrawing();
    ClearBackground(BLACK);
    
    // Draw UI
    DrawTitleBar(state, screenWidth);
    
    // Draw based on phase
    if (state->phase == TUTORIAL_MOVE_WINDOW)
    {
        if (state->cube.visible)
        {
            DrawRectangle((int)state->cube.position.x, (int)state->cube.position.y, 
                          state->cube.size, state->cube.size, RED);
        }
        DrawText("Try to move the window", screenWidth / 2 - 100, screenHeight / 2, 20, LIGHTGRAY);
    }
    else if (state->phase == TUTORIAL_COMPLETE)
    {
        DrawText("Well done!", screenWidth / 2 - 60, screenHeight / 2, 30, GREEN);
    }
    else if (state->phase == TUTORIAL_RESIZE_WINDOW)
    {
        DrawText("Now try to resize the window!", screenWidth / 2 - 130, screenHeight / 2, 20, LIGHTGRAY);
        DrawText("Drag from the edges or corner", screenWidth / 2 - 120, screenHeight / 2 + 30, 16, GRAY);
        DrawResizeHandles(state, screenWidth, screenHeight);
    }
    else if (state->phase == TUTORIAL_RESIZE_COMPLETE)
    {
        DrawText("Awesome!", screenWidth / 2 - 50, screenHeight / 2, 30, GREEN);
    }
    else if (state->phase == MAIN_MENU)
    {
        DrawMainMenu(state, screenWidth, screenHeight);
    }
    else if (state->phase == LEVEL_1)
    {
        // Draw level number
        DrawText("Level 1", 10, state->titleBarHeight + 10, 20, WHITE);
        
        // Draw green cube if visible
        if (state->greenCube.visible)
        {
            DrawRectangle((int)state->greenCube.position.x, (int)state->greenCube.position.y, 
                          state->greenCube.size, state->greenCube.size, GREEN);
        }
        
        // Draw cube
        if (state->cube.visible)
        {
            DrawRectangle((int)state->cube.position.x, (int)state->cube.position.y, 
                          state->cube.size, state->cube.size, RED);
        }
        
        // Draw win message
        if (state->levelComplete)
        {
            DrawText("You Won!", screenWidth / 2 - 60, screenHeight / 2, 30, GREEN);
        }
        
        DrawResizeHandles(state, screenWidth, screenHeight);
    }
    else if (state->phase == LEVEL_2)
    {
        // Draw level number
        DrawText("Level 2", 10, state->titleBarHeight + 10, 20, WHITE);
        
        // Draw triangles (spikes)
        for (int i = 0; i < state->triangleCount; i++)
        {
            if (state->triangles[i].active)
            {
                DrawTriangle(state->triangles[i].points[0], 
                           state->triangles[i].points[1], 
                           state->triangles[i].points[2], RED);
                DrawTriangleLines(state->triangles[i].points[0], 
                                state->triangles[i].points[1], 
                                state->triangles[i].points[2], MAROON);
            }
        }
        
        // Draw green cube if visible
        if (state->greenCube.visible)
        {
            DrawRectangle((int)state->greenCube.position.x, (int)state->greenCube.position.y, 
                          state->greenCube.size, state->greenCube.size, GREEN);
        }
        
        // Draw cube
        if (state->cube.visible && !state->gameOver)
        {
            DrawRectangle((int)state->cube.position.x, (int)state->cube.position.y, 
                          state->cube.size, state->cube.size, BLUE);
        }
        
        // Draw messages
        if (state->gameOver)
        {
            DrawText("Game Over!", screenWidth / 2 - 70, screenHeight / 2, 30, RED);
        }
        
        if (state->levelComplete)
        {
            DrawText("You Won!", screenWidth / 2 - 60, screenHeight / 2, 30, GREEN);
        }
        
        DrawResizeHandles(state, screenWidth, screenHeight);
    }
    else if (state->phase == LEVEL_3)
    {
        DrawText("Level 3 - Compression", 10, state->titleBarHeight + 10, 20, WHITE);
        DrawMaze(state);
        DrawRectangle((int)state->greenCube.position.x + 2, (int)state->greenCube.position.y + 2,
                      (int)state->greenCube.size - 4, (int)state->greenCube.size - 4, GREEN);
        if (state->cube.visible)
        {
            DrawRectangle((int)state->cube.position.x + 2, (int)state->cube.position.y + 2,
                          (int)state->cube.size - 4, (int)state->cube.size - 4, RED);
        }
        if (state->levelComplete)
        {
            DrawText("THE END", screenWidth / 2 - 70, screenHeight / 2 - 20, 40, GOLD);
            DrawText("Thanks for playing!", screenWidth / 2 - 90, screenHeight / 2 + 30, 20, LIGHTGRAY);
        }
        DrawResizeHandles(state, screenWidth, screenHeight);
    }
    
    EndDrawing();
}

static const char* SAVE_FILENAME = "game.save";

bool SaveFileExists()
{
    std::ifstream f(SAVE_FILENAME);
    if (!f.is_open()) return false;
    // Must have valid content: at least phase number in valid range
    int phase = -1;
    f >> phase;
    bool valid = (phase >= (int)TUTORIAL_MOVE_WINDOW && phase <= (int)LEVEL_3);
    return valid;
}

// Persist enough state to resume the current run later.
// The format is intentionally simple: one value per line.
bool SaveGame(const GameState* state)
{
    std::ofstream f(SAVE_FILENAME);
    if (!f.is_open()) return false;
    
    f << (int)state->phase << "\n";
    f << state->currentLevel << "\n";
    f << state->cube.position.x << " " << state->cube.position.y << "\n";
    f << state->cube.velocity.x << " " << state->cube.velocity.y << "\n";
    f << state->cube.acceleration.x << " " << state->cube.acceleration.y << "\n";
    f << (state->cube.visible ? 1 : 0) << "\n";
    f << state->greenCube.position.x << " " << state->greenCube.position.y << "\n";
    f << (state->greenCube.visible ? 1 : 0) << "\n";
    f << (state->levelComplete ? 1 : 0) << " " << (state->gameOver ? 1 : 0) << "\n";
    f << state->triangleCount << "\n";
    
    for (int i = 0; i < state->triangleCount; i++)
    {
        const Triangle* t = &state->triangles[i];
        f << t->points[0].x << " " << t->points[0].y << " "
          << t->points[1].x << " " << t->points[1].y << " "
          << t->points[2].x << " " << t->points[2].y << " "
          << (t->active ? 1 : 0) << "\n";
    }
    
    f.close();
    return true;
}

bool LoadGame(GameState* state)
{
    std::ifstream f(SAVE_FILENAME);
    if (!f.is_open()) return false;
    
    int phase;
    f >> phase;
    if (phase < TUTORIAL_MOVE_WINDOW || phase > LEVEL_3) { f.close(); return false; }
    state->phase = (GamePhase)phase;
    
    f >> state->currentLevel;
    f >> state->cube.position.x >> state->cube.position.y;
    f >> state->cube.velocity.x >> state->cube.velocity.y;
    f >> state->cube.acceleration.x >> state->cube.acceleration.y;
    int v; f >> v; state->cube.visible = (v != 0);
    f >> state->greenCube.position.x >> state->greenCube.position.y;
    f >> v; state->greenCube.visible = (v != 0);
    f >> v; state->levelComplete = (v != 0);
    f >> v; state->gameOver = (v != 0);
    f >> state->triangleCount;
    
    for (int i = 0; i < state->triangleCount && i < 5; i++)
    {
        Triangle* t = &state->triangles[i];
        f >> t->points[0].x >> t->points[0].y >> t->points[1].x >> t->points[1].y
          >> t->points[2].x >> t->points[2].y >> v;
        t->active = (v != 0);
    }
    
    state->phaseTimer = 0;
    state->hasExistingGame = true;
    if (state->phase == LEVEL_3)
    {
        GenerateMaze(state);
        state->cube.size = (float)(MAZE_TILE_SIZE - 4);
        state->greenCube.size = (float)(MAZE_TILE_SIZE - 4);
        state->greenCube.visible = true;
    }
    f.close();
    return true;
}