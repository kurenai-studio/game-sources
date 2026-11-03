#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <cmocka.h>

#include "game.h"
#include "render.h"

// render.c references several gnu-efi runtime symbols inside present() and init_gop_highest_mode().
// We wrap them with cmocka so each test fully controls the UEFI surface. The wraps fall back to
// returning 0 unless will_return supplies a value (so unrelated tests don't need to enqueue).
EFI_BOOT_SERVICES *BS;
EFI_SYSTEM_TABLE *ST;
static EFI_BOOT_SERVICES test_bs_storage;
static EFI_GRAPHICS_OUTPUT_PROTOCOL test_gop_storage;
static EFI_GRAPHICS_OUTPUT_PROTOCOL *test_gop = &test_gop_storage;
static EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE test_gop_mode_storage;
static EFI_GRAPHICS_OUTPUT_MODE_INFORMATION test_gop_mode_info;
static UINT32 test_pool_buffer[256 * 256];

UINTN __wrap_Print(IN const CHAR16 *fmt, ...) {
    (void)fmt;
    return 0;
}

void __wrap_InitializeLib(IN EFI_HANDLE ImageHandle, IN EFI_SYSTEM_TABLE *SystemTable) {
    (void)ImageHandle;
    (void)SystemTable;
}

UINT64 __wrap_efi_call2(void *fn, UINT64 a, UINT64 b) {
    (void)fn;
    (void)a;
    (void)b;
    // Simulates gop->SetMode 'starting' the protocol: a real UEFI sets gop->Mode here. The
    // pixel-format recovery path doesn't need this (Mode is already non-NULL) but the
    // gop->Mode == NULL recovery path does.
    if (test_gop_storage.Mode == NULL) {
        test_gop_storage.Mode = &test_gop_mode_storage;
    }
    return mock_type(UINT64);
}

UINT64 __wrap_efi_call3(void *fn, UINT64 a, UINT64 b, UINT64 c) {
    (void)fn;
    (void)a;
    (void)b;
    (void)c;
    // BS->LocateProtocol stores the protocol pointer at *c; BS->AllocatePool stores the buffer at
    // *c too. The 'kind' mock value tells us which.
    UINT64 kind = mock_type(UINT64);
    if (kind == 1) {
        // LocateProtocol: write test_gop into the user's pointer.
        EFI_GRAPHICS_OUTPUT_PROTOCOL **out = (EFI_GRAPHICS_OUTPUT_PROTOCOL **)c;
        *out = test_gop;
    } else if (kind == 2) {
        // AllocatePool: write our static buffer into the user's pointer.
        UINT32 **out = (UINT32 **)c;
        *out = test_pool_buffer;
    }
    return mock_type(UINT64);
}

UINT64 __wrap_efi_call4(void *fn, UINT64 a, UINT64 b, UINT64 c, UINT64 d) {
    (void)fn;
    (void)a;
    (void)b;
    (void)c;
    (void)d;
    return mock_type(UINT64);
}

UINT64 __wrap_efi_call10(void *fn,
                         UINT64 a,
                         UINT64 b,
                         UINT64 c,
                         UINT64 d,
                         UINT64 e,
                         UINT64 f,
                         UINT64 g,
                         UINT64 h,
                         UINT64 i,
                         UINT64 j) {
    (void)fn;
    (void)a;
    (void)b;
    (void)c;
    (void)d;
    (void)e;
    (void)f;
    (void)g;
    (void)h;
    (void)i;
    (void)j;
    return mock_type(UINT64);
}

#define TEST_W 64
#define TEST_H 48

static int reset_gop_state(void **state) {
    (void)state;
    test_gop_mode_info.HorizontalResolution = TEST_W;
    test_gop_mode_info.VerticalResolution = TEST_H;
    test_gop_mode_info.PixelFormat = PixelBlueGreenRedReserved8BitPerColor;
    test_gop_mode_info.PixelsPerScanLine = TEST_W;
    test_gop_mode_storage.MaxMode = 1;
    test_gop_mode_storage.Mode = 0;
    test_gop_mode_storage.Info = &test_gop_mode_info;
    test_gop_mode_storage.SizeOfInfo = sizeof(test_gop_mode_info);
    test_gop_mode_storage.FrameBufferBase = 0;
    test_gop_mode_storage.FrameBufferSize = 0;
    test_gop_storage.Mode = &test_gop_mode_storage;
    test_gop_storage.QueryMode = NULL;
    test_gop_storage.SetMode = NULL;
    test_gop_storage.Blt = NULL;
    BS = NULL;
    ST = NULL;
    backbuffer = NULL;
    return 0;
}

// fill_rect/draw_block tests use a manually-allocated backbuffer; no UEFI calls happen.

static int setup_framebuffer(void **state) {
    (void)state;
    screen_width = TEST_W;
    screen_height = TEST_H;
    backbuffer = calloc((size_t)(TEST_W * TEST_H), sizeof(UINT32));
    cell_w = 4;
    cell_h = 4;
    board_origin_x = 0;
    board_origin_y = 0;
    return backbuffer == NULL;
}

static int teardown_framebuffer(void **state) {
    (void)state;
    free(backbuffer);
    backbuffer = NULL;
    return 0;
}

static void test_fill_rect_basic(void **state) {
    (void)state;
    fill_rect(2, 2, 3, 3, 0xAABBCC);
    assert_int_equal(backbuffer[2 * TEST_W + 2], 0xAABBCC);
    assert_int_equal(backbuffer[4 * TEST_W + 4], 0xAABBCC);
    assert_int_equal(backbuffer[1 * TEST_W + 2], 0);
}

static void test_fill_rect_clips(void **state) {
    (void)state;
    fill_rect(TEST_W - 2, TEST_H - 2, 100, 100, 0xCAFE);
    assert_int_equal(backbuffer[(TEST_H - 1) * TEST_W + (TEST_W - 1)], 0xCAFE);
}

static void test_fill_rect_offscreen_noop(void **state) {
    (void)state;
    fill_rect(TEST_W, TEST_H, 5, 5, 0xDEAD);
    for (UINTN i = 0; i < (UINTN)(TEST_W * TEST_H); i++) {
        assert_int_equal(backbuffer[i], 0);
    }
}

static void test_draw_block_no_gap_when_small(void **state) {
    (void)state;
    draw_block(0, 0, 0xFF00FF);
    assert_int_equal(backbuffer[0 * TEST_W + 0], 0xFF00FF);
    assert_int_equal(backbuffer[3 * TEST_W + 3], 0xFF00FF);
}

static void test_draw_block_gap_when_large(void **state) {
    (void)state;
    cell_w = 6;
    cell_h = 6;
    draw_block(0, 0, 0x123456);
    assert_int_equal(backbuffer[0 * TEST_W + 0], 0);
    assert_int_equal(backbuffer[5 * TEST_W + 5], 0);
    assert_int_equal(backbuffer[1 * TEST_W + 1], 0x123456);
    assert_int_equal(backbuffer[4 * TEST_W + 4], 0x123456);
}

// present() blits the back buffer to the GOP framebuffer. We first run init_gop_highest_mode so
// render.c's static gop pointer is populated, then exercise present which uses gop->Blt.
static void test_present_calls_blt(void **state) {
    (void)state;
    BS = &test_bs_storage;
    reset_gop_state(state);
    BS = &test_bs_storage;
    will_return(__wrap_efi_call3, (UINT64)1);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call3, (UINT64)2);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    assert_int_equal(init_gop_highest_mode(NULL, NULL), EFI_SUCCESS);
    will_return(__wrap_efi_call10, (UINT64)EFI_SUCCESS);
    present();
}

// init_gop_highest_mode error paths.
static int setup_bs(void **state) {
    reset_gop_state(state);
    BS = &test_bs_storage;
    return 0;
}

// LocateProtocol failure must propagate.
static void test_init_gop_locate_failure(void **state) {
    (void)state;
    will_return(__wrap_efi_call3, (UINT64)0);             // kind = neither
    will_return(__wrap_efi_call3, (UINT64)EFI_NOT_FOUND); // status
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_NOT_FOUND);
}

// gop->Mode == NULL with QueryMode returning an unrecoverable error.
static void test_init_gop_query_mode_failure(void **state) {
    (void)state;
    test_gop_storage.Mode = NULL;
    will_return(__wrap_efi_call3, (UINT64)1); // LocateProtocol kind
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call4, (UINT64)EFI_DEVICE_ERROR); // QueryMode fails (not NOT_STARTED)
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_DEVICE_ERROR);
}

// QueryMode returns NOT_STARTED, SetMode then fails.
static void test_init_gop_set_mode_initial_failure(void **state) {
    (void)state;
    test_gop_storage.Mode = NULL;
    will_return(__wrap_efi_call3, (UINT64)1);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call4, (UINT64)EFI_NOT_STARTED);
    will_return(__wrap_efi_call2, (UINT64)EFI_DEVICE_ERROR);
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_DEVICE_ERROR);
}

// Unsupported pixel format triggers SetMode; SetMode failure must propagate.
static void test_init_gop_pixel_format_set_mode_failure(void **state) {
    (void)state;
    test_gop_mode_info.PixelFormat = PixelBitMask; // unsupported
    will_return(__wrap_efi_call3, (UINT64)1);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call2, (UINT64)EFI_UNSUPPORTED);
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_UNSUPPORTED);
}

// AllocatePool failure for the back buffer must propagate.
static void test_init_gop_allocate_pool_failure(void **state) {
    (void)state;
    will_return(__wrap_efi_call3, (UINT64)1);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call3, (UINT64)0);
    will_return(__wrap_efi_call3, (UINT64)EFI_OUT_OF_RESOURCES);
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_OUT_OF_RESOURCES);
}

// Successful init_gop_highest_mode on the happy path.
static void test_init_gop_success(void **state) {
    (void)state;
    will_return(__wrap_efi_call3, (UINT64)1); // LocateProtocol stores gop
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call3, (UINT64)2); // AllocatePool stores buffer
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_SUCCESS);
    // Layout was computed.
    assert_true(cell_w >= 8);
    assert_true(cell_h == cell_w);
    assert_true(backbuffer == test_pool_buffer);
}

// gop->Mode == NULL drives the QueryMode/SetMode recovery branch; the SetMode wrap supplies the
// side effect that sets Mode, mirroring real UEFI behaviour.
static void test_init_gop_query_recovers(void **state) {
    (void)state;
    test_gop_storage.Mode = NULL;
    will_return(__wrap_efi_call3, (UINT64)1);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call4, (UINT64)EFI_NOT_STARTED);
    will_return(__wrap_efi_call2, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call3, (UINT64)2);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_SUCCESS);
}

// Unsupported pixel format triggers SetMode; SetMode succeeding falls through to AllocatePool.
static void test_init_gop_pixel_format_recovers(void **state) {
    (void)state;
    test_gop_mode_info.PixelFormat = PixelBitMask;
    will_return(__wrap_efi_call3, (UINT64)1);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call2, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call3, (UINT64)2);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_SUCCESS);
}

// Tiny resolution forces cell_w below 8, exercising the floor branch.
static void test_init_gop_cell_floor(void **state) {
    (void)state;
    test_gop_mode_info.HorizontalResolution = 200;
    test_gop_mode_info.VerticalResolution = 200;
    will_return(__wrap_efi_call3, (UINT64)1);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    will_return(__wrap_efi_call3, (UINT64)2);
    will_return(__wrap_efi_call3, (UINT64)EFI_SUCCESS);
    EFI_STATUS s = init_gop_highest_mode(NULL, NULL);
    assert_int_equal(s, EFI_SUCCESS);
    assert_int_equal(cell_w, 8);
}

// render() composes the whole frame. Drive it through several game states to cover the branches:
// game-over overlay, hold-piece set, score > 0.
static int setup_for_render(void **state) {
    (void)state;
    screen_width = 1024;
    screen_height = 768;
    cell_w = 28;
    cell_h = 28;
    board_origin_x = 80 + 4 * cell_w;
    board_origin_y = 80;
    backbuffer = calloc(screen_width * screen_height, sizeof(UINT32));
    game_reset();
    return backbuffer == NULL;
}

static int teardown_for_render(void **state) {
    (void)state;
    free(backbuffer);
    backbuffer = NULL;
    return 0;
}

// Plain render: no hold, score 0, game running.
static void test_render_default_state(void **state) {
    (void)state;
    will_return(__wrap_efi_call10, (UINT64)EFI_SUCCESS);
    render();
}

// hold_piece set forces the hold-box render branch.
static void test_render_with_hold(void **state) {
    (void)state;
    hold_piece = PIECE_T;
    will_return(__wrap_efi_call10, (UINT64)EFI_SUCCESS);
    render();
}

// game_over set forces the overlay branch.
static void test_render_game_over(void **state) {
    (void)state;
    game_over = 1;
    will_return(__wrap_efi_call10, (UINT64)EFI_SUCCESS);
    render();
}

// Non-zero score forces the digit-decomposition branch (else-of-if-zero).
static void test_render_with_score(void **state) {
    (void)state;
    score = 12345;
    will_return(__wrap_efi_call10, (UINT64)EFI_SUCCESS);
    render();
}

// Narrow screen forces the next-box clamp (next_x runs off the right edge) and the controls
// shrink loop (text wider than screen).
static void test_render_narrow_screen(void **state) {
    (void)state;
    screen_width = 360;
    cell_w = 60;
    cell_h = 60;
    board_origin_x = 100;
    will_return(__wrap_efi_call10, (UINT64)EFI_SUCCESS);
    render();
}

// Tiny cell_w forces the font_scale, info_scale, and ctrl_scale floor branches.
static void test_render_tiny_cells(void **state) {
    (void)state;
    cell_w = 6;
    cell_h = 6;
    will_return(__wrap_efi_call10, (UINT64)EFI_SUCCESS);
    render();
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test_setup_teardown(
            test_fill_rect_basic, setup_framebuffer, teardown_framebuffer),
        cmocka_unit_test_setup_teardown(
            test_fill_rect_clips, setup_framebuffer, teardown_framebuffer),
        cmocka_unit_test_setup_teardown(
            test_fill_rect_offscreen_noop, setup_framebuffer, teardown_framebuffer),
        cmocka_unit_test_setup_teardown(
            test_draw_block_no_gap_when_small, setup_framebuffer, teardown_framebuffer),
        cmocka_unit_test_setup_teardown(
            test_draw_block_gap_when_large, setup_framebuffer, teardown_framebuffer),
        cmocka_unit_test_setup(test_present_calls_blt, reset_gop_state),
        cmocka_unit_test_setup(test_init_gop_locate_failure, setup_bs),
        cmocka_unit_test_setup(test_init_gop_query_mode_failure, setup_bs),
        cmocka_unit_test_setup(test_init_gop_set_mode_initial_failure, setup_bs),
        cmocka_unit_test_setup(test_init_gop_pixel_format_set_mode_failure, setup_bs),
        cmocka_unit_test_setup(test_init_gop_allocate_pool_failure, setup_bs),
        cmocka_unit_test_setup(test_init_gop_success, setup_bs),
        cmocka_unit_test_setup(test_init_gop_query_recovers, setup_bs),
        cmocka_unit_test_setup(test_init_gop_pixel_format_recovers, setup_bs),
        cmocka_unit_test_setup(test_init_gop_cell_floor, setup_bs),
        cmocka_unit_test_setup_teardown(
            test_render_default_state, setup_for_render, teardown_for_render),
        cmocka_unit_test_setup_teardown(
            test_render_with_hold, setup_for_render, teardown_for_render),
        cmocka_unit_test_setup_teardown(
            test_render_game_over, setup_for_render, teardown_for_render),
        cmocka_unit_test_setup_teardown(
            test_render_with_score, setup_for_render, teardown_for_render),
        cmocka_unit_test_setup_teardown(
            test_render_narrow_screen, setup_for_render, teardown_for_render),
        cmocka_unit_test_setup_teardown(
            test_render_tiny_cells, setup_for_render, teardown_for_render),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
