#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#include <cmocka.h>

#include "game.h"
#include "piece.h"

// game_reset() should zero the playfield, reset score and game-over flag, and
// clear the held piece.
static void test_game_reset_initial_state(void **state) {
    (void)state;
    score = 9999;
    game_over = 1;
    hold_piece = PIECE_T;
    hold_used = 1;
    for (int r = 0; r < BOARD_HEIGHT; r++) {
        for (int c = 0; c < BOARD_WIDTH; c++) {
            board[r][c] = 1;
        }
    }

    game_reset();

    assert_int_equal(score, 0);
    assert_int_equal(game_over, 0);
    assert_int_equal(hold_piece, -1);
    assert_int_equal(hold_used, 0);
    for (int r = 0; r < BOARD_HEIGHT; r++) {
        for (int c = 0; c < BOARD_WIDTH; c++) {
            assert_int_equal(board[r][c], 0);
        }
    }
}

// next_random_piece must return values in [0, NUM_PIECES).
static void test_next_random_piece_in_range(void **state) {
    (void)state;
    for (int i = 0; i < 100; i++) {
        int p = next_random_piece();
        assert_in_range(p, 0, NUM_PIECES - 1);
    }
}

// lock_piece commits the falling piece into the board and spawns a new one.
static void test_lock_piece_commits_and_spawns(void **state) {
    (void)state;
    game_reset();

    // Force a known piece configuration.
    current_piece = PIECE_O;
    current_rot = 0;
    current_x = 0;
    current_y = BOARD_HEIGHT - 2;

    lock_piece();

    // The O-piece occupies SHAPE rows 0-1, cols 0-1, so board cells
    // (BOARD_HEIGHT - 2, 0..1) and (BOARD_HEIGHT - 1, 0..1) are filled.
    assert_int_equal(board[BOARD_HEIGHT - 2][0], PIECE_O + 1);
    assert_int_equal(board[BOARD_HEIGHT - 2][1], PIECE_O + 1);
    assert_int_equal(board[BOARD_HEIGHT - 1][0], PIECE_O + 1);
    assert_int_equal(board[BOARD_HEIGHT - 1][1], PIECE_O + 1);

    // Lock countdown reset, gravity counter reset, hold available again.
    assert_int_equal(lock_countdown, -1);
    assert_int_equal(gravity_counter, 0);
    assert_int_equal(hold_used, 0);

    // Spawn placed a new piece at the top of the board.
    assert_int_equal(current_y, 0);
    assert_int_equal(current_x, 3);
    assert_int_equal(current_rot, 0);
}

// do_hold with no held piece stashes the current and brings out the next.
static void test_do_hold_first_use(void **state) {
    (void)state;
    game_reset();
    int original_current = current_piece;
    do_hold();
    assert_int_equal(hold_piece, original_current);
    assert_int_equal(hold_used, 1);
}

// do_hold is a no-op while hold_used is set.
static void test_do_hold_locked_after_use(void **state) {
    (void)state;
    game_reset();
    do_hold();
    int after_first_hold = hold_piece;
    int current_before_second = current_piece;
    do_hold();
    assert_int_equal(hold_piece, after_first_hold);
    assert_int_equal(current_piece, current_before_second);
}

// do_hold with a held piece swaps it into play.
static void test_do_hold_swap(void **state) {
    (void)state;
    game_reset();
    int first_current = current_piece;
    do_hold(); // Stash first piece, bring out next.
    int second_current = current_piece;
    hold_used = 0; // Simulate a lock that re-enabled hold.
    do_hold();     // Swap: held first piece becomes current.
    assert_int_equal(current_piece, first_current);
    assert_int_equal(hold_piece, second_current);
}

// lock_piece must clear a fully filled row, shift everything above down by 1,
// and add 100 to the score.
static void test_lock_piece_clears_full_line(void **state) {
    (void)state;
    game_reset();
    UINTN base_score = score;
    // Fill the bottom row except column 0; then drop an O-piece into columns
    // 0-1 so locking it completes the row.
    for (int column = 1; column < BOARD_WIDTH; column++) {
        board[BOARD_HEIGHT - 1][column] = 1;
    }
    // Mark a sentinel two rows up so we can verify the row shift.
    board[BOARD_HEIGHT - 3][0] = 7;

    current_piece = PIECE_O;
    current_rot = 0;
    current_x = 0;
    current_y = BOARD_HEIGHT - 2;
    lock_piece();

    // The bottom row was cleared; the sentinel that was at row HEIGHT - 3
    // should now be at row HEIGHT - 2 (shifted down by one).
    assert_int_equal(board[BOARD_HEIGHT - 2][0], 7);
    // Score increased by 100 for the cleared line.
    assert_int_equal(score, base_score + 100);
}

// lock_piece sets game_over when the next piece cannot spawn. Block only the
// spawn columns (3-6) so the rows aren't full enough to be line-cleared.
static void test_lock_piece_triggers_game_over(void **state) {
    (void)state;
    game_reset();
    for (int column = 3; column <= 6; column++) {
        board[0][column] = 1;
        board[1][column] = 1;
    }
    current_piece = PIECE_O;
    current_rot = 0;
    current_x = 0;
    current_y = BOARD_HEIGHT - 2;
    lock_piece();
    assert_int_equal(game_over, 1);
}

// spawn_next sets game_over when the next piece collides at spawn. Same
// partial-fill trick to avoid line clears.
static void test_spawn_next_triggers_game_over(void **state) {
    (void)state;
    game_reset();
    for (int column = 3; column <= 6; column++) {
        board[0][column] = 1;
        board[1][column] = 1;
    }
    spawn_next();
    assert_int_equal(game_over, 1);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_game_reset_initial_state),
        cmocka_unit_test(test_next_random_piece_in_range),
        cmocka_unit_test(test_lock_piece_commits_and_spawns),
        cmocka_unit_test(test_do_hold_first_use),
        cmocka_unit_test(test_do_hold_locked_after_use),
        cmocka_unit_test(test_do_hold_swap),
        cmocka_unit_test(test_lock_piece_clears_full_line),
        cmocka_unit_test(test_lock_piece_triggers_game_over),
        cmocka_unit_test(test_spawn_next_triggers_game_over),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
