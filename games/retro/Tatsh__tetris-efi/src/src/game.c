#include "game.h"

int current_piece;
int current_rot;
int current_x;
int current_y;
int next_piece;
int hold_piece;
int hold_used;
UINTN score;
int game_over;
UINTN lock_delay_ticks;
int lock_countdown;
int gravity_counter;

static UINTN rng_seed = 12345;

int next_random_piece(void) {
    rng_seed = rng_seed * 1103515245 + 12345;
    return (int)((rng_seed >> 16) % NUM_PIECES);
}

void lock_piece(void) {
    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            if (SHAPES[current_piece][current_rot][r][c]) {
                int by = current_y + r;
                int bx = current_x + c;
                if (by >= 0 && by < (int)BOARD_HEIGHT && bx >= 0 && bx < (int)BOARD_WIDTH) {
                    board[by][bx] = (UINT8)(current_piece + 1);
                }
            }
        }
    }
    hold_used = 0;
    // Clear lines
    for (int row = BOARD_HEIGHT - 1; row >= 0; row--) {
        int full = 1;
        for (int column = 0; column < BOARD_WIDTH; column++) {
            if (!board[row][column]) {
                full = 0;
                break;
            }
        }
        if (full) {
            for (int r = row; r > 0; r--) {
                for (int column = 0; column < BOARD_WIDTH; column++) {
                    board[r][column] = board[r - 1][column];
                }
            }
            for (int column = 0; column < BOARD_WIDTH; column++) {
                board[0][column] = 0;
            }
            score += 100;
            row++;
        }
    }
    current_piece = next_piece;
    next_piece = next_random_piece();
    current_rot = 0;
    current_x = 3;
    current_y = 0;
    if (collision(current_piece, current_rot, current_x, current_y)) {
        game_over = 1;
    }
    lock_countdown = -1;
    gravity_counter = 0;
}

void spawn_next(void) {
    current_piece = next_piece;
    next_piece = next_random_piece();
    current_rot = 0;
    current_x = 3;
    current_y = 0;
    if (collision(current_piece, current_rot, current_x, current_y)) {
        game_over = 1;
    }
}

void do_hold(void) {
    if (hold_used) {
        return;
    }
    if (hold_piece >= 0) {
        int tmp = hold_piece;
        hold_piece = current_piece;
        current_piece = tmp;
        current_rot = 0;
        current_x = 3;
        current_y = 0;
    } else {
        hold_piece = current_piece;
        spawn_next();
    }
    hold_used = 1;
    lock_countdown = -1;
}

void game_reset(void) {
    for (int r = 0; r < BOARD_HEIGHT; r++) {
        for (int c = 0; c < BOARD_WIDTH; c++) {
            board[r][c] = 0;
        }
    }
    score = 0;
    game_over = 0;
    hold_piece = -1;
    hold_used = 0;
    lock_countdown = -1;
    lock_delay_ticks = 0;
    gravity_counter = 0;
    next_piece = next_random_piece();
    spawn_next();
}
