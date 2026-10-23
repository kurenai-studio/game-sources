#ifndef C_SNAKE_H
#define C_SNAKE_H

////Constants////

// Window constants
const int WINDOW_WIDTH = 200;
const int WINDOW_HEIGHT = 200;
const char* GAME_TITLE = "C-Snake";

// Snake constants
const int SNAKE_CELL_RADIUS = 4;
const int DEFAULT_SNAKE_CELL_DIFF = 4;
const int DEFAULT_SPEED = 4;
const int STARTING_SNAKE_LENGTH = 8;
const int MAX_SNAKE_LENGTH = 500;

// Snake color constants
const Color SNAKE_COLOR_0 = {.r =   0, .g = 240, .b = 140, .a = 255,};
const Color SNAKE_COLOR_1 = {.r = 140, .g =   0, .b = 240, .a = 255,};
const Color SNAKE_COLOR_2 = {.r = 240, .g = 140, .b =   0, .a = 255,};
const Color SNAKE_COLOR_DEAD = {.r = 140,  .g = 140, .b = 140, .a = 255,};

const int SNAKE_COLOR_OPTION_COUNT = 3;
const Color SNAKE_COLORS[] = {SNAKE_COLOR_0, SNAKE_COLOR_1, SNAKE_COLOR_2};

//Snake pattern constants
const int SNAKE_PATTERN_DISTINCT_COLORS = 6;
const int SNAKE_PATTERN_VARYSTEP_MULTIPLIER = 50;

// Fruit constants
const int FRUIT_RADIUS = 4;
const int FRUIT_SCORE = 1;

// Fruit color constants
const Color FRUIT_COLOR_0 = {.r = 220, .g = 20,  .b = 0,   .a = 255,};
const Color FRUIT_COLOR_1 = {.r = 120, .g = 220, .b = 160, .a = 255,};
const Color FRUIT_COLOR_2 = {.r = 240, .g = 160, .b = 40,  .a = 255,};

const int FRUIT_COLOR_OPTION_COUNT = 3;
const Color FRUIT_COLORS[] = {FRUIT_COLOR_0, FRUIT_COLOR_1, FRUIT_COLOR_2};

// Special fruit constants
const int SPECIAL_FRUIT_RADIUS = 8;
const int SPECIAL_FRUIT_SCORE = 10;
const int SPECIAL_FRUIT_ONE_IN_HOW_MANY_CHANCE = 1000;

// Special fruit color constants
const Color SPECIAL_FRUIT_COLOR_0 = {.r = 200, .g = 40,  .b = 200, .a = 255,};
const Color SPECIAL_FRUIT_COLOR_1 = {.r =  40, .g = 200, .b = 200, .a = 255,};
const Color SPECIAL_FRUIT_COLOR_2 = {.r = 200, .g = 200, .b = 40,  .a = 255,};

const int SPECIAL_FRUIT_COLOR_OPTION_COUNT = 3;
const Color SPECIAL_FRUIT_COLORS[] = {SPECIAL_FRUIT_COLOR_0, SPECIAL_FRUIT_COLOR_1, SPECIAL_FRUIT_COLOR_2};

// Score constants
const int MAX_SCORE_DIGITS = 3;
const int SCORE_FONT_SIZE = 100;
const Color SCORE_FONT_COLOR= {.r = 140,.g = 140,.b = 140,.a = 100,};

// Background Color constants
const Color BG_COLOR_0 = RAYWHITE;
const Color BG_COLOR_1 = DARKGRAY;
const Color BG_COLOR_2 = DARKPURPLE;

const int BG_COLOR_OPTION_COUNT = 3;
const Color BG_COLORS[] = {BG_COLOR_0, BG_COLOR_1, BG_COLOR_2};

///end Constants////

#endif