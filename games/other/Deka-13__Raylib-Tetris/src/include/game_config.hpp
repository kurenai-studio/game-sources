#ifndef GAME_CONFIG_HPP
#define GAME_CONFIG_HPP

#include "user_config.hpp"

// INTERNAL: game internal rules and derived values. Players edit user_config.hpp instead.

// For Main Window Parameters
constexpr int MIN_WINDOW_WIDTH  = 800;
constexpr int MIN_WINDOW_HEIGHT = 600;
static_assert(WINDOW_WIDTH  >= MIN_WINDOW_WIDTH,  
              "Chosen WINDOW_WIDTH value is too small. See MIN_WINDOW_WIDTH in game_config.hpp");
static_assert(WINDOW_HEIGHT  >= MIN_WINDOW_HEIGHT,  
              "Chosen WINDOW_HEIGHT value is too small. See MIN_WINDOW_HEIGHT in game_config.hpp");
constexpr const char* WINDOW_TITLE = "TETRIS";

// For Tetris Window Parameters
constexpr int TETRIS_WINDOW_WIDTH = (GRID_WIDTH * BLOCK_SIZE);
constexpr int TETRIS_WINDOW_HEIGHT = (GRID_HEIGHT * BLOCK_SIZE);
static_assert(TETRIS_WINDOW_WIDTH  <= (WINDOW_WIDTH - TETRIS_BORDER_THICK * 2),  
              "Chosen BLOCK_SIZE value is too big: Tetris Window is wider than the Main Window.");
static_assert(TETRIS_WINDOW_HEIGHT  <= (WINDOW_HEIGHT - TETRIS_BORDER_THICK * 2),  
              "Chosen BLOCK_SIZE value is too big: Tetris Window is taller than the Main Window.");
static_assert(TETRIS_BORDER_THICK <= TETRIS_WINDOW_POSX  && 
                TETRIS_WINDOW_POSX <= (WINDOW_WIDTH - TETRIS_BORDER_THICK - TETRIS_WINDOW_WIDTH),  
              "Chosen TETRIS_WINDOW_POSX value does not allow to render Tetris Window properly inside Main Window.");
static_assert(TETRIS_BORDER_THICK <= TETRIS_WINDOW_POSY  && 
                TETRIS_WINDOW_POSY <= (WINDOW_HEIGHT - TETRIS_BORDER_THICK - TETRIS_WINDOW_HEIGHT),  
              "Chosen TETRIS_WINDOW_POSY value does not allow to render Tetris Window properly inside Main Window.");

// For Tetris Grid Parameters
constexpr int GRID_ROWS = (GRID_HEIGHT + 1);
constexpr int GRID_SIZE = (GRID_WIDTH * GRID_ROWS);

#endif // GAME_CONFIG_HPP
