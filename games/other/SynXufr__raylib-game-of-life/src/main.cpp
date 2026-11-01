#include <raylib.h>
#include <vector>

#include "sidebar.h"
#include "grid.h"

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------

int main() {
    // Initialization
    //------------------------------------------------------------------------------------
    const int GRID_WIDTH = 30;
    const int GRID_HEIGHT = 30;
    const int CELL_SIZE = 30;
    const int SIDEBAR_WIDTH = 120;

    InitWindow(GRID_WIDTH * CELL_SIZE + SIDEBAR_WIDTH, GRID_HEIGHT * CELL_SIZE, "Grid Visualization");

    SetTargetFPS(20);

    double simTimer = 0.0;
    double simInterval = 0.2; // = 5 simulation steps per second

    // Game State bool
    bool running = false;

    // Initialize Grid
    grid_t grid = initGrid(GRID_WIDTH, GRID_HEIGHT);
    //------------------------------------------------------------------------------------

    // Main Program Loop
    while (!WindowShouldClose()) {
        // Update Grid Here
        //------------------------------------------------------------------------------------
        Vector2 mousePos = GetMousePosition();

        if (!running) {
            // Convert mouse coordinates to grid coordinates
            int gridX = (static_cast<int>(mousePos.x) - SIDEBAR_WIDTH) / CELL_SIZE;
            int gridY = static_cast<int>(mousePos.y) / CELL_SIZE;

            // Make sure the mouse is inside the grid
            if (mousePos.x >= SIDEBAR_WIDTH &&
                gridX >= 0 &&
                gridX < GRID_WIDTH &&
                gridY >= 0 &&
                gridY < GRID_HEIGHT) {
                // If left mouse button is held down, set the cell to ALIVE
                if (IsMouseButtonDown(MOUSE_LEFT_BUTTON)) {
                    grid[gridY][gridX] = ALIVE;
                }

                // Optional: if right button held, erase the cell
                if (IsMouseButtonDown(MOUSE_RIGHT_BUTTON)) {
                    grid[gridY][gridX] = DEAD;
                }
            }
        }

        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
            if (CheckCollisionPointRec(mousePos, startStopBtn)) running = !running;
            if (CheckCollisionPointRec(mousePos, randomBtn)) fillGridRandom(grid);
        }

        //------------------------------------------------------------------------------------
        // Update Simulation
        //------------------------------------------------------------------------------------

        double dt = GetFrameTime();
        simTimer += dt;

        if (running && simTimer >= simInterval) {
            simTimer = 0.0;
            grid_t newGrid = grid;
            for (int y = 0; y < GRID_HEIGHT; ++y) {
                for (int x = 0; x < GRID_WIDTH; ++x) {
                    int aliveNeighbours = 0;
                    for (int dy = -1; dy <= 1; ++dy) {
                        for (int dx = -1; dx <= 1; ++dx) {
                            if (dx == 0 && dy == 0) continue;
                            int nx = x + dx;
                            int ny = y + dy;
                            if (nx >= 0 && nx < GRID_WIDTH && ny >= 0 && ny < GRID_HEIGHT) {
                                if (grid[ny][nx] == ALIVE) aliveNeighbours++;
                            }
                        }
                    }
                    if (grid[y][x] != DEAD) {
                        if (aliveNeighbours < 2 || aliveNeighbours > 3) newGrid[y][x] = DEAD;
                    } else {
                        if (aliveNeighbours == 3) newGrid[y][x] = ALIVE;
                    }
                }
            }
            grid = newGrid;
        }

        //------------------------------------------------------------------------------------
        // Draw Grid
        //------------------------------------------------------------------------------------
        BeginDrawing();
        ClearBackground(DARKGRAY);

        // Draw Sidebar
        DrawRectangle(0, 0, SIDEBAR_WIDTH, GRID_HEIGHT * CELL_SIZE, LIGHTGRAY);
        DrawRectangleRec(startStopBtn, running ? RED : GREEN);
        DrawText(running ? "Stop" : "Start", startStopBtn.x + 20, startStopBtn.y + 10, 20, WHITE);

        DrawRectangleRec(randomBtn, PURPLE);
        DrawText("Random", randomBtn.x + 20, randomBtn.y + 10, 20, WHITE);

        // Draw Grid
        for (int y = 0; y < GRID_HEIGHT; ++y) {
            for (int x = 0; x < GRID_WIDTH; ++x) {
                Color color = {};
                switch (grid[y][x]) {
                    case DEAD: color = BLACK;
                        break;
                    case ALIVE: color = LIGHTGRAY;
                        break;
                    case WALL: color = GRAY;
                }
                DrawRectangle(SIDEBAR_WIDTH + x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE - 1, CELL_SIZE - 1, color);
            }
        }
        EndDrawing();
        //------------------------------------------------------------------------------------
    }

    // De-Initialization
    //------------------------------------------------------------------------------------
    CloseWindow();
    //------------------------------------------------------------------------------------

    return 0;
}
