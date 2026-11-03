#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#include <cmocka.h>

#include "piece.h"

static void clear_board(void) {
    for (int r = 0; r < BOARD_HEIGHT; r++) {
        for (int c = 0; c < BOARD_WIDTH; c++) {
            board[r][c] = 0;
        }
    }
}

// I-piece rotation 0 has its filled row at SHAPE row 1 (cols 0-3). At py = -1
// the filled cells land on board row 0; at py = BOARD_HEIGHT - 1 they would
// land on row BOARD_HEIGHT, which is off the floor.
static void test_collision_floor(void **state) {
    (void)state;
    clear_board();
    assert_false(collision(PIECE_I, 0, 0, BOARD_HEIGHT - 2));
    assert_true(collision(PIECE_I, 0, 0, BOARD_HEIGHT - 1));
}

// I-piece spawn at x = -1 has a filled cell at column -1 (off the left wall).
// At x = BOARD_WIDTH - 3 the rightmost filled cell is at BOARD_WIDTH (off the
// right wall).
static void test_collision_walls(void **state) {
    (void)state;
    clear_board();
    assert_true(collision(PIECE_I, 0, -1, 0));
    assert_true(collision(PIECE_I, 0, BOARD_WIDTH - 3, 0));
}

// A pre-existing block at (5, 2) collides with the I-piece (filled row at
// SHAPE row 1) when the piece is positioned at py = 4.
static void test_collision_existing_block(void **state) {
    (void)state;
    clear_board();
    board[5][2] = 1;
    assert_true(collision(PIECE_I, 0, 0, 4));
    // The same piece one row higher does not collide.
    assert_false(collision(PIECE_I, 0, 0, 3));
}

// Cells with by < 0 (above the visible board) must not register as collisions.
static void test_collision_above_board_ok(void **state) {
    (void)state;
    clear_board();
    assert_false(collision(PIECE_O, 0, 4, -2));
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_collision_floor),
        cmocka_unit_test(test_collision_walls),
        cmocka_unit_test(test_collision_existing_block),
        cmocka_unit_test(test_collision_above_board_ok),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
