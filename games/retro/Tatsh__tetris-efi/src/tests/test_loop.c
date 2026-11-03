#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include <cmocka.h>

#include "game.h"
#include "loop.h"

// run_game uses BS, ST, Print, render, and the efi_call* family. Wrap each via cmocka so each
// loop iteration can be scripted from the test.

EFI_BOOT_SERVICES test_bs_storage;
EFI_BOOT_SERVICES *BS = &test_bs_storage;
EFI_SYSTEM_TABLE test_st_storage;
EFI_SYSTEM_TABLE *ST = &test_st_storage;
SIMPLE_INPUT_INTERFACE test_conin_storage;

UINTN __wrap_Print(IN const CHAR16 *fmt, ...) {
    (void)fmt;
    return 0;
}

// render() is wrapped to a no-op; tests script side effects by listing render call indices at
// which game_over should be set or the current piece parked on the floor. This lets a single
// test drive run_game through arbitrary state transitions without exposing internals.
static int g_render_calls = 0;
static int g_render_game_over_triggers[8];
static int g_render_game_over_count = 0;
static int g_render_park_triggers[8];
static int g_render_park_count = 0;

void __wrap_render(void) {
    int call = g_render_calls++;
    for (int i = 0; i < g_render_game_over_count; i++) {
        if (g_render_game_over_triggers[i] == call) {
            game_over = 1;
        }
    }
    for (int i = 0; i < g_render_park_count; i++) {
        if (g_render_park_triggers[i] == call) {
            current_piece = PIECE_O;
            current_rot = 0;
            current_x = 0;
            current_y = BOARD_HEIGHT - 2;
        }
    }
}

UINT64 __wrap_efi_call1(void *fn, UINT64 a) {
    (void)fn;
    (void)a;
    return mock_type(UINT64);
}

UINT64 __wrap_efi_call2(void *fn, UINT64 a, UINT64 b) {
    (void)fn;
    (void)a;
    EFI_INPUT_KEY *out = (EFI_INPUT_KEY *)b;
    EFI_INPUT_KEY *src = mock_ptr_type(EFI_INPUT_KEY *);
    if (out && src) {
        *out = *src;
    }
    return mock_type(UINT64);
}

UINT64 __wrap_efi_call3(void *fn, UINT64 a, UINT64 b, UINT64 c) {
    (void)fn;
    (void)a;
    (void)b;
    UINT64 kind = mock_type(UINT64);
    if (kind == 1) {
        UINTN *idx_out = (UINTN *)c;
        if (idx_out) {
            *idx_out = mock_type(UINT64);
        }
    }
    return mock_type(UINT64);
}

UINT64 __wrap_efi_call5(void *fn, UINT64 a, UINT64 b, UINT64 c, UINT64 d, UINT64 e) {
    (void)fn;
    (void)a;
    (void)b;
    (void)c;
    (void)d;
    (void)e;
    return mock_type(UINT64);
}

static int reset_state(void **state) {
    (void)state;
    test_st_storage.ConIn = &test_conin_storage;
    test_conin_storage.WaitForKey = NULL;
    test_conin_storage.ReadKeyStroke = NULL;
    test_conin_storage.Reset = NULL;
    g_render_calls = 0;
    g_render_game_over_count = 0;
    g_render_park_count = 0;
    return 0;
}

static void trigger_game_over_at(int call) {
    g_render_game_over_triggers[g_render_game_over_count++] = call;
}

static void park_piece_at(int call) {
    g_render_park_triggers[g_render_park_count++] = call;
}

// Helpers.
static EFI_INPUT_KEY g_key_buf[128];
static int g_key_buf_idx = 0;
static void wait_event(UINTN index, EFI_STATUS status) {
    will_return(__wrap_efi_call3, (UINT64)1); // WaitForEvent kind
    will_return(__wrap_efi_call3, (UINT64)index);
    will_return(__wrap_efi_call3, (UINT64)status);
}
static void set_timer_ok(void) {
    will_return(__wrap_efi_call3, (UINT64)0); // SetTimer kind
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
}
static void check_event(EFI_STATUS status) {
    will_return(__wrap_efi_call1, (UINT64)status);
}
static void key_ok(UINT16 sc, CHAR16 u) {
    g_key_buf[g_key_buf_idx].ScanCode = sc;
    g_key_buf[g_key_buf_idx].UnicodeChar = u;
    will_return(__wrap_efi_call2, &g_key_buf[g_key_buf_idx]);
    will_return(__wrap_efi_call2, (UINT64)EFI_SUCCESS);
    g_key_buf_idx++;
}
static void key_err(EFI_STATUS status) {
    will_return(__wrap_efi_call2, NULL);
    will_return(__wrap_efi_call2, (UINT64)status);
}

static void test_run_game_create_event_failure(void **state) {
    (void)state;
    will_return(__wrap_efi_call5, (UINT64)EFI_OUT_OF_RESOURCES);
    assert_int_equal(run_game(), EFI_OUT_OF_RESOURCES);
}

// Force game_over from the very first render so the outer loop enters the game-over branch
// immediately. Quit at the prompt with Q.
static void test_run_game_quits_at_game_over(void **state) {
    (void)state;
    g_key_buf_idx = 0;
    trigger_game_over_at(0);
    will_return(__wrap_efi_call5, (UINT64)EFI_SUCCESS);
    set_timer_ok();
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'Q');
    assert_int_equal(run_game(), EFI_SUCCESS);
}

// Cover the inner game-over loop's error branches and 'other key' continue path before quitting.
static void test_run_game_inner_loop_error_paths(void **state) {
    (void)state;
    g_key_buf_idx = 0;
    trigger_game_over_at(0);
    will_return(__wrap_efi_call5, (UINT64)EFI_SUCCESS);
    set_timer_ok();
    // Inner: WaitForEvent error → continue.
    wait_event(0, EFI_DEVICE_ERROR);
    // Inner: ReadKeyStroke error → continue.
    wait_event(0, EFI_SUCCESS);
    key_err(EFI_DEVICE_ERROR);
    // Inner: other key → continue (not N, not Q).
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'Z');
    // Inner: Q → return.
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'q');
    assert_int_equal(run_game(), EFI_SUCCESS);
}

// 'N' key restarts the game (game_reset clears game_over). We then re-trigger game_over after
// the next outer body iteration and quit.
static void test_run_game_new_game_then_quit(void **state) {
    (void)state;
    g_key_buf_idx = 0;
    // Render call sequence:
    //   #0 initial run_game render → trigger
    //   #1 game-over branch render in outer iter 1 (no trigger)
    //   #2 outer body render in iter 2 (game_over=0 since 'N' reset it) → trigger
    //   #3 game-over branch render in outer iter 3 (no trigger)
    trigger_game_over_at(0);
    trigger_game_over_at(2);
    will_return(__wrap_efi_call5, (UINT64)EFI_SUCCESS);
    set_timer_ok();
    // Outer iter 1 (game_over branch): inner 'N'.
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'N');
    // Outer iter 2 (body): WaitForEvent, drain (no keys), CheckEvent (no timer fired).
    wait_event(0, EFI_SUCCESS);
    key_err(EFI_NOT_READY);
    check_event(EFI_NOT_READY);
    // Outer iter 3 (game_over branch): Q.
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'q');
    assert_int_equal(run_game(), EFI_SUCCESS);
}

// Drive the outer body: WaitForEvent error, then a successful iteration with all key handlers
// drained, then a timer-fires-via-CheckEvent path, then quit.
static void test_run_game_outer_paths(void **state) {
    (void)state;
    g_key_buf_idx = 0;
    // Render call sequence:
    //   #0 initial
    //   (iter 1 hits WaitForEvent error → continue, no render)
    //   #1 end of iter 2 body
    //   #2 end of iter 3 body → trigger
    //   #3 game-over branch render in iter 4
    trigger_game_over_at(2);
    will_return(__wrap_efi_call5, (UINT64)EFI_SUCCESS);
    set_timer_ok();

    // Outer iter 1: WaitForEvent error → continue.
    wait_event(0, EFI_DEVICE_ERROR);

    // Outer iter 2: WaitForEvent success (key wakeup). Drain every key handler branch.
    // CheckEvent returns SUCCESS so the timer-fired branch also runs.
    wait_event(0, EFI_SUCCESS);
    key_ok(0x04, 0); // Left arrow
    key_ok(0x03, 0); // Right arrow
    key_ok(0, L'h'); // h
    key_ok(0, L'L'); // L
    key_ok(0x02, 0); // Down arrow
    key_ok(0, L'j'); // j
    key_ok(0, L' '); // Space
    key_ok(0, L'k'); // k
    key_ok(0, L'x'); // x
    key_ok(0, L's'); // s
    key_ok(0, L'z'); // z
    key_ok(0, L'a'); // a
    key_ok(0, L'c'); // c
    key_err(EFI_NOT_READY);
    check_event(EFI_SUCCESS); // timer also fired

    // Outer iter 3: timer wakeup (index=1). Drain returns NOT_READY. Timer fired via index==1
    // short-circuit (no CheckEvent call).
    wait_event(1, EFI_SUCCESS);
    key_err(EFI_NOT_READY);

    // Outer iter 4: game_over=1 → branch. Q.
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'q');

    assert_int_equal(run_game(), EFI_SUCCESS);
}

// Park the piece on the floor so timer ticks exercise on_floor branches: lock_countdown set
// (line 121-122), decrement (127), and trigger lock_piece (124-125). After the lock the new
// piece spawns at top so on_floor flips back to false; we then issue a Down-arrow soft drop with
// the piece re-parked on the floor to cover line 79.
static void test_run_game_lock_countdown_and_soft_drop_on_floor(void **state) {
    (void)state;
    g_key_buf_idx = 0;
    park_piece_at(0); // Park before iter 1.
    will_return(__wrap_efi_call5, (UINT64)EFI_SUCCESS);
    set_timer_ok();

    // Iter 1: timer wakeup, on_floor=true, lock_countdown was -1 → set to LOCK_DELAY_TICKS, then
    // decrement to LOCK_DELAY_TICKS - 1.
    wait_event(1, EFI_SUCCESS);
    key_err(EFI_NOT_READY);
    // Iter 2..LOCK_DELAY_TICKS: decrement until reaching 0.
    for (int i = 0; i < LOCK_DELAY_TICKS - 1; i++) {
        wait_event(1, EFI_SUCCESS);
        key_err(EFI_NOT_READY);
    }
    // Iter LOCK_DELAY_TICKS+1: lock_countdown == 0 → lock_piece.
    wait_event(1, EFI_SUCCESS);
    key_err(EFI_NOT_READY);

    // Re-park the piece for the soft-drop test. After lock_piece in the previous iter, render
    // call number is LOCK_DELAY_TICKS+1; the next render after that is LOCK_DELAY_TICKS+2.
    park_piece_at(LOCK_DELAY_TICKS + 1);

    // Iter (LOCK_DELAY_TICKS+2): WaitForEvent key wakeup, drain a Down arrow (on floor → line 79)
    // and a hard drop. CheckEvent returns NOT_READY.
    wait_event(0, EFI_SUCCESS);
    key_ok(0x02, 0); // Down arrow on floor → line 79
    key_err(EFI_NOT_READY);
    check_event(EFI_NOT_READY);

    trigger_game_over_at(LOCK_DELAY_TICKS + 2); // Render after the soft-drop iter.

    // Game-over inner: Q → return.
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'q');
    assert_int_equal(run_game(), EFI_SUCCESS);
}

// Drive enough timer iterations to advance gravity_counter past GRAVITY_PERIOD_TICKS (exercising
// the cur_y++ branch), then quit.
static void test_run_game_gravity_advances(void **state) {
    (void)state;
    g_key_buf_idx = 0;
    // GRAVITY_PERIOD_TICKS+1 timer iters cover the gravity_counter overflow branch. Trigger
    // game_over at the render call after the last of those iters.
    trigger_game_over_at(GRAVITY_PERIOD_TICKS + 1);
    will_return(__wrap_efi_call5, (UINT64)EFI_SUCCESS);
    set_timer_ok();
    for (int i = 0; i < GRAVITY_PERIOD_TICKS + 1; i++) {
        wait_event(1, EFI_SUCCESS);
        key_err(EFI_NOT_READY);
    }
    // Game-over inner: Q.
    wait_event(0, EFI_SUCCESS);
    key_ok(0, L'q');
    assert_int_equal(run_game(), EFI_SUCCESS);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test_setup(test_run_game_create_event_failure, reset_state),
        cmocka_unit_test_setup(test_run_game_quits_at_game_over, reset_state),
        cmocka_unit_test_setup(test_run_game_inner_loop_error_paths, reset_state),
        cmocka_unit_test_setup(test_run_game_new_game_then_quit, reset_state),
        cmocka_unit_test_setup(test_run_game_outer_paths, reset_state),
        cmocka_unit_test_setup(test_run_game_lock_countdown_and_soft_drop_on_floor, reset_state),
        cmocka_unit_test_setup(test_run_game_gravity_advances, reset_state),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
