#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#include <cmocka.h>

#include <efi.h>

// efi_main isn't declared in any header; it's the EFI image entry point
// defined in src/main.c. Forward-declare it for the test driver.
EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable);

// efi_main calls three functions: InitializeLib, init_gop_highest_mode, and
// run_game. We wrap all three with `--wrap` so the test fully controls
// efi_main's external dependencies.

void __wrap_InitializeLib(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    (void)ImageHandle;
    (void)SystemTable;
}

EFI_STATUS __wrap_init_gop_highest_mode(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    check_expected_ptr(ImageHandle);
    check_expected_ptr(SystemTable);
    return mock_type(EFI_STATUS);
}

EFI_STATUS __wrap_run_game(void) {
    return mock_type(EFI_STATUS);
}

// When init_gop_highest_mode fails, efi_main must return that status without
// calling run_game.
static void test_efi_main_returns_init_failure(void **state) {
    (void)state;
    EFI_HANDLE handle = (EFI_HANDLE)0xCAFE;
    EFI_SYSTEM_TABLE *st = (EFI_SYSTEM_TABLE *)0xBABE;
    expect_value(__wrap_init_gop_highest_mode, ImageHandle, handle);
    expect_value(__wrap_init_gop_highest_mode, SystemTable, st);
    will_return(__wrap_init_gop_highest_mode, EFI_NOT_FOUND);
    // run_game must NOT be called; if it were, the test framework would fail
    // for an unexpected mock_type call.
    EFI_STATUS r = efi_main(handle, st);
    assert_int_equal(r, EFI_NOT_FOUND);
}

// On successful init, efi_main hands off to run_game and returns its status.
static void test_efi_main_runs_game_on_success(void **state) {
    (void)state;
    EFI_HANDLE handle = (EFI_HANDLE)0xDEAD;
    EFI_SYSTEM_TABLE *st = (EFI_SYSTEM_TABLE *)0xBEEF;
    expect_value(__wrap_init_gop_highest_mode, ImageHandle, handle);
    expect_value(__wrap_init_gop_highest_mode, SystemTable, st);
    will_return(__wrap_init_gop_highest_mode, EFI_SUCCESS);
    will_return(__wrap_run_game, EFI_SUCCESS);
    assert_int_equal(efi_main(handle, st), EFI_SUCCESS);
}

// efi_main propagates run_game's error status verbatim.
static void test_efi_main_propagates_run_game_error(void **state) {
    (void)state;
    expect_any(__wrap_init_gop_highest_mode, ImageHandle);
    expect_any(__wrap_init_gop_highest_mode, SystemTable);
    will_return(__wrap_init_gop_highest_mode, EFI_SUCCESS);
    will_return(__wrap_run_game, EFI_ABORTED);
    assert_int_equal(efi_main(NULL, NULL), EFI_ABORTED);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_efi_main_returns_init_failure),
        cmocka_unit_test(test_efi_main_runs_game_on_success),
        cmocka_unit_test(test_efi_main_propagates_run_game_error),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
