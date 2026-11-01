#include "raylib.h"

#include "canvas.hpp"
#include "user_config.hpp"
#include "game_config.hpp"
#include "tetris.hpp"

// Helper function to handle delayed key repetition for smooth sliding
bool HandleKeyRepeat(int key) {
    // Statics retain their state across function calls for this specific key action
    static int active_key = -1;
    static float move_timer = 0.0f;
    static float repeat_timer = 0.0f;

    if (IsKeyPressed(key)) {
        active_key = key;
        move_timer = 0.0f;
        repeat_timer = 0.0f;
        return true; // Triggered immediately on press
    }

    if (IsKeyDown(key) && active_key == key) {
        float frame_time = GetFrameTime();
        move_timer += frame_time;

        if (move_timer >= INITIAL_DELAY) {
            repeat_timer += frame_time;
            if (repeat_timer >= MOVEMENT_SPEED) {
                repeat_timer = 0.0f; // Reset repeat ticker for the next interval
                return true;         // Triggered during hold repeat
            }
        }
    } else if (!IsKeyDown(active_key)) {
        // Reset if the key is released
        if (active_key == key) {
            active_key = -1;
        }
    }

    return false;
}

void DrawBlocksOnCanvas(const Canvas& canvas, const TetrisGrid &tetris){
    BeginCanvasMode(canvas);
    for (int i = GRID_WIDTH; i != GRID_SIZE; ++i){
        if (tetris.IsCellEmpty(i)){
            int row = i / GRID_WIDTH;
            int col = i % GRID_WIDTH;
            Rectangle block = {
                static_cast<float>(col * BLOCK_SIZE), 
                static_cast<float>((row - 1) * BLOCK_SIZE), 
                static_cast<float>(BLOCK_SIZE), 
                static_cast<float>(BLOCK_SIZE)
            };
            DrawRectangleRec(block, BLOCK_COLOR);
        }
    }
    EndCanvasMode();
}

int main(void){
    InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE);
    SetTargetFPS(GAME_FPS);
    TetrisGrid Tetris = TetrisGrid();
    int time_count = 1;
    int interval_count = 0;
    int speed = INITIAL_SPEED;

    while (!WindowShouldClose()){
        // Handle input
        if (IsKeyPressed(KEY_R) && !Tetris.IsGameOver()) {
            Tetris.Rotate();
        }        

        if (IsKeyPressed(KEY_ENTER) && Tetris.IsGameOver()) {
            Tetris = TetrisGrid();    
            time_count = 1;
            speed = INITIAL_SPEED;

        }
         if (HandleKeyRepeat(KEY_LEFT) && !Tetris.IsGameOver()) {
            Tetris.MovePivotLeft();
        }       
        if (HandleKeyRepeat(KEY_RIGHT) && !Tetris.IsGameOver()) {
            Tetris.MovePivotRight();
        }

        // Update game state
        if (time_count == speed && !Tetris.IsGameOver()) {
            Tetris.DoFallStep();
            time_count = 1;
        }

        if (HandleKeyRepeat(KEY_DOWN) && !Tetris.IsGameOver() && Tetris.IsTetromino()) {
            Tetris.DoFallStep();
            time_count = 1;
        }

        if (!Tetris.IsGameOver()) {
            ++interval_count;
            if (interval_count >= TIME_INTERVAL) {
                // Reduce speed value (faster drop) ensuring it doesn't drop below a safe minimum threshold (e.g., 2 frames)
                if (speed > SPEED_INCREASE + 1) {
                    speed -= SPEED_INCREASE;
                }
                interval_count = 0;
            }
        }

        // Render frame
        BeginDrawing();
        ClearBackground(WINDOW_COLOR);
        
        Canvas Tetris_Screen{
            { TETRIS_WINDOW_POSX, TETRIS_WINDOW_POSY, TETRIS_WINDOW_WIDTH, TETRIS_WINDOW_HEIGHT }, // Rectangle area
            TETRIS_WINDOW_COLOR, // Color color
            TETRIS_BORDER_THICK, // float border_thick
            TETRIS_BORDER_COLOR  // Color border_color
        };
        DrawCanvas(Tetris_Screen);
        DrawBlocksOnCanvas(Tetris_Screen, Tetris);

        Canvas Score_Screen{
            { SCORE_WINDOW_POSX, SCORE_WINDOW_POSY, SCORE_WINDOW_WIDTH, SCORE_WINDOW_HEIGHT }, // Rectangle area
            SCORE_WINDOW_COLOR,               // Color color
            SCORE_BORDER_THICK,                // float border_thick
            SCORE_BORDER_COLOR                // Color border_color
        };
        DrawCanvas(Score_Screen);
        
        BeginCanvasMode(Score_Screen);
            DrawText(TextFormat("Score: %d", Tetris.GetScore()), 10, 10, 20, WHITE);
        EndCanvasMode();

        EndDrawing();
        ++time_count;
    }

    CloseWindow();
    return 0;
}


