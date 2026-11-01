#include <stdint.h>
#include "raylib.h"

typedef struct {
    uint16_t board[16];
    uint32_t score;
} Game;
#define BOARD_AT(pGame, i, j) (pGame)->board[i * 4 + j]

#define SCALE 3
#define CELL_GAP  5  * SCALE
#define CELL_SIZE 40 * SCALE
#define WINDOW_WIDTH  CELL_GAP * 5 + CELL_SIZE * 4
#define WINDOW_HEIGHT CELL_GAP * 5 + CELL_SIZE * 4

int text_from_int(int32_t value, char result[32]) 
{
    char buffer[32];
    int is_negative = 0;
    int i = 0;

    // Handle zero explicitly
    if (value == 0) {
        result[0] = '0';
        result[1] = '\0';
        return 1;
    }

    // Handle negative values
    if (value < 0) {
        is_negative = 1;
        if (value == (int32_t)0x80000000) {
            const char *min_str = "-2147483648";
            for (int j = 0; min_str[j]; j++) {
                result[j] = min_str[j];
            }
            result[11] = '\0';
            return 11;
        }
        value = -value;
    }

    // Convert digits to characters (in reverse order)
    while (value != 0) {
        buffer[i++] = '0' + (value % 10);
        value /= 10;
    }

    if (is_negative) {
        buffer[i++] = '-';
    }

    // Reverse into result
    for (int j = 0; j < i; j++) {
        result[j] = buffer[i - j - 1];
    }
    result[i] = '\0';
    return i;
}

Color get_tile_color(uint16_t val) {
    switch(val) {
        case 2: return (Color){0xee, 0xe4, 0xda, 0xff};
        case 4: return (Color){0xed, 0xe0, 0xc8, 0xff};
        case 8: return (Color){0xf2, 0xb1, 0x79, 0xff};
        case 16: return (Color){0xf5, 0x95, 0x63, 0xff};
        case 32: return (Color){0xf6, 0x7c, 0x5f, 0xff};
        case 64: return (Color){0xf6, 0x5e, 0x3b, 0xff};
        case 128: return (Color){0xed, 0xcf, 0x72, 0xff};
        case 256: return (Color){0xed, 0xcc, 0x61, 0xff};
        case 512: return (Color){0xed, 0xc8, 0x50, 0xff};
        case 1024: return (Color){0xed, 0xc5, 0x3f, 0xff};
        case 2048: return (Color){0xed, 0xc2, 0x2e, 0xff};
        default: return (Color){0x3c, 0x3a, 0x32, 0xff};
    }
}

void draw_game(Game *game)
{
    char text[32] = {0};
    float font_size = (float)CELL_SIZE * 2 / 5;
    float y_offset = CELL_GAP;
    for(uint32_t i = 0; i < 4; ++i) {
        float x_offset = CELL_GAP;
        for(uint32_t j = 0; j < 4; ++j) {
            uint16_t value = BOARD_AT(game, i, j);
            Rectangle rec;
            rec.width  = CELL_SIZE;
            rec.height = CELL_SIZE;
            rec.x = j * CELL_SIZE + x_offset;
            rec.y = i * CELL_SIZE + y_offset;
            DrawRectangleRounded(rec, 0.2, 20, get_tile_color(value));
            if(value != 0) {
                int length = text_from_int(value, text);
                float text_width = MeasureText(text, font_size);
                float xoff = (CELL_SIZE - text_width) / 2;
                if(xoff <= 0) xoff = 0;
                DrawText(text, rec.x + xoff, rec.y + (CELL_SIZE - font_size) / 2, font_size, BLACK);
            }
            x_offset += CELL_GAP;
        }
        y_offset += CELL_GAP;
    }
}

void spawn_cell(Game *game)
{
    char empty[16] = {0};
    int n = 0;
    for (int i = 0; i < 16; ++i) {
        if (game->board[i] == 0) {
            empty[n++] = i;
        }
    }
    if (n == 0) return;
    int idx = empty[GetRandomValue(0, n - 1)];
    game->board[idx] = (GetRandomValue(0, 9) < 9) ? 2 : 4;
}

void handle_input(Game *game)
{
    bool moved = false;

    if(IsKeyPressed(KEY_W)) {
        for(int col = 0; col < 4; ++col) {
            uint16_t src[4] = {0};
            uint16_t dst[4] = {0};
            int srclen = 0;
            for(int row = 0; row < 4; ++row) {
                uint16_t val = BOARD_AT(game, row, col);
                if(val != 0) {
                    src[srclen++] = val;
                }
            }

            int dstlen = 0;
            for(int j = 0; j < srclen; ++j) {
                if(j + 1 < srclen && src[j] == src[j + 1]) {
                    dst[dstlen++] = src[j] * 2;
                    j += 1; // Skip the next iteration
                } else {
                    dst[dstlen++] = src[j];
                }
            }

            for(int row = 0; row < 4; ++row) {
                if(BOARD_AT(game, row, col) != dst[row]) {
                    moved = true;
                }
                BOARD_AT(game, row, col) = dst[row];
            }
        }
    } else if(IsKeyPressed(KEY_A)) {
        for(int row = 0; row < 4; ++row) {
            uint16_t src[4] = {0};
            uint16_t dst[4] = {0};
            int srclen = 0;
            for(int col = 0; col < 4; ++col) {
                uint16_t val = BOARD_AT(game, row, col);
                if(val != 0) {
                    src[srclen++] = val;
                }
            }

            int dstlen = 0;
            for(int j = 0; j < srclen; ++j) {
                if(j + 1 < srclen && src[j] == src[j + 1]) {
                    dst[dstlen++] = src[j] * 2;
                    j += 1; // Skip the next iteration
                } else {
                    dst[dstlen++] = src[j];
                }
            }

            for(int col= 0; col < 4; ++col) {
                if(BOARD_AT(game, row, col) == dst[col]) 
                    moved = true;
                BOARD_AT(game, row, col) = dst[col];
            }
        }
    } else if(IsKeyPressed(KEY_S)) {
        for(int col = 0; col < 4; ++col) {
            uint16_t src[4] = {0};
            uint16_t dst[4] = {0};
            int srclen = 0;
            for(int row = 3; row >= 0; row--) {
                uint16_t val = BOARD_AT(game, row, col);
                if(val != 0) {
                    src[srclen++] = val;
                }
            }

            int dstlen = 0;
            for(int j = 0; j < srclen; ++j) {
                if(j + 1 < srclen && src[j] == src[j + 1]) {
                    dst[dstlen++] = src[j] * 2;
                    j += 1; // Skip the next iteration
                } else {
                    dst[dstlen++] = src[j];
                }
            }

            for(int row = 3; row >= 0; row--) {
                if(BOARD_AT(game, row, col) == dst[3 - row]) 
                    moved = true;
                BOARD_AT(game, row, col) = dst[3 - row];
            }
        }
    } else if(IsKeyPressed(KEY_D)) {
        for(int row = 0; row < 4; ++row) {
            uint16_t src[4] = {0};
            uint16_t dst[4] = {0};
            int srclen = 0;
            for(int col = 3; col >= 0; col--) {
                uint16_t val = BOARD_AT(game, row, col);
                if(val != 0) {
                    src[srclen++] = val;
                }
            }

            int dstlen = 0;
            for(int j = 0; j < srclen; ++j) {
                if(j + 1 < srclen && src[j] == src[j + 1]) {
                    dst[dstlen++] = src[j] * 2;
                    j += 1; // Skip the next iteration
                } else {
                    dst[dstlen++] = src[j];
                }
            }

            for(int col = 3; col >= 0; col--) {
                if(BOARD_AT(game, row, col) != dst[3 - col]) {
                    moved = true;
                }
                BOARD_AT(game, row, col) = dst[3 - col];
            }
        }
    }

    if(moved) spawn_cell(game);
}

bool game_over(Game *game)
{
    for(int i = 0; i < 4; ++i) {
        for(int j = 0; j < 4; ++j) {
            uint16_t val = BOARD_AT(game, i, j);
            if(val == 0) return false;
            if (i < 3 && BOARD_AT(game, i, j) == BOARD_AT(game, i + 1, j)) return false;
            if (j < 3 && BOARD_AT(game, i, j) == BOARD_AT(game, i, j + 1)) return false;
        }
    }
    return true;
}

void reset_game(Game *game)
{
    for(int i = 0; i < 16; ++i) 
        game->board[i] = 0;
    spawn_cell(game);
}

uint32_t get_score(Game *game)
{
    uint32_t score = 0;
    for(int i = 0; i < 16; ++i) 
        score += game->board[i];
    return score;
}

int main(void)
{
    InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "2048");
    Game game = {0};
    reset_game(&game);
    bool is_playing = true;
    while(!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground((Color){ 0x7d, 0x60, 0x52, 0xff });
        if(!is_playing && IsKeyPressed(KEY_R)) {
            SetWindowTitle("2048");
            reset_game(&game);
        }
        if(is_playing) handle_input(&game);
        draw_game(&game);
        if(game_over(&game)) {
            is_playing = false;
            SetWindowTitle(TextFormat("Game over with total score of %d", get_score(&game)));
        }
        EndDrawing();
    }
    CloseWindow();
}
