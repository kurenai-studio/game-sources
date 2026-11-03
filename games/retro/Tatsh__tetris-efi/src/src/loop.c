#include "loop.h"
#include "game.h"
#include "render.h"

#include <efilib.h>

EFI_STATUS run_game(void) {
    EFI_EVENT timer_event;
    EFI_STATUS status =
        uefi_call_wrapper(BS->CreateEvent, 5, EVT_TIMER, TPL_APPLICATION, NULL, NULL, &timer_event);
    if (EFI_ERROR(status)) {
        Print(L"Tetris: CreateEvent failed.\n");
        return status;
    }
    uefi_call_wrapper(BS->SetTimer, 3, timer_event, TimerPeriodic, TIMER_PERIOD_100NS);

    EFI_EVENT wait_events[2];
    wait_events[0] = ST->ConIn->WaitForKey;
    wait_events[1] = timer_event;
    UINTN index;

    game_reset();
    render();

    for (;;) {
        if (game_over) {
            render();
            for (;;) {
                status = uefi_call_wrapper(BS->WaitForEvent, 3, 1, &ST->ConIn->WaitForKey, &index);
                if (EFI_ERROR(status)) {
                    continue;
                }
                EFI_INPUT_KEY key;
                status = uefi_call_wrapper(ST->ConIn->ReadKeyStroke, 2, ST->ConIn, &key);
                if (EFI_ERROR(status)) {
                    continue;
                }
                if (key.UnicodeChar == L'n' || key.UnicodeChar == L'N') {
                    game_reset();
                    break;
                }
                if (key.UnicodeChar == L'q' || key.UnicodeChar == L'Q') {
                    return EFI_SUCCESS;
                }
            }
            continue;
        }

        status = uefi_call_wrapper(BS->WaitForEvent, 3, 2, wait_events, &index);
        if (EFI_ERROR(status)) {
            Print(L"Tetris: WaitForEvent error 0x%x\n", (unsigned)status);
            continue;
        }

        /*
         * Drain all pending keys this iteration. Avoids one-key-per-frame lag
         * when keystrokes outpace the 50 ms heartbeat.
         */
        EFI_INPUT_KEY key;
        while (uefi_call_wrapper(ST->ConIn->ReadKeyStroke, 2, ST->ConIn, &key) == EFI_SUCCESS) {
            UINT16 sc = key.ScanCode;
            CHAR16 u = key.UnicodeChar;
            if (sc == 0x04 || u == L'h' || u == L'H') {
                // Left arrow / h: move left
                if (!collision(current_piece, current_rot, current_x - 1, current_y)) {
                    current_x--;
                }
            } else if (sc == 0x03 || u == L'l' || u == L'L') {
                // Right arrow / l: move right
                if (!collision(current_piece, current_rot, current_x + 1, current_y)) {
                    current_x++;
                }
            } else if (sc == 0x02 || u == L'j' || u == L'J') {
                // Down arrow / j: soft drop
                if (!collision(current_piece, current_rot, current_x, current_y + 1)) {
                    current_y++;
                    score += 1;
                } else {
                    lock_countdown = (lock_countdown >= 0) ? lock_countdown : LOCK_DELAY_TICKS;
                }
            } else if (sc == 0x01 || u == L' ' || u == L'k' || u == L'K') {
                // Up arrow / Space / k: hard drop
                while (!collision(current_piece, current_rot, current_x, current_y + 1)) {
                    current_y++;
                    score += 2;
                }
                lock_piece();
            } else if (u == L'x' || u == L'X' || u == L's' || u == L'S') {
                // X / s: rotate clockwise
                int nr = (current_rot + 1) % NUM_ROTATIONS;
                if (!collision(current_piece, nr, current_x, current_y)) {
                    current_rot = nr;
                }
            } else if (u == L'z' || u == L'Z' || u == L'a' || u == L'A') {
                // Z / a: rotate counter-clockwise
                int nr = (current_rot + NUM_ROTATIONS - 1) % NUM_ROTATIONS;
                if (!collision(current_piece, nr, current_x, current_y)) {
                    current_rot = nr;
                }
            } else if (u == L'c' || u == L'C') {
                do_hold();
            }
        }

        /*
         * Timer fired this iteration if it was the wakeup OR remains signalled
         * after WaitForEvent returned a key. WaitForEvent consumes the signal
         * of the index it returned, so we cannot rely on CheckEvent alone.
         */
        int timer_fired =
            (index == 1) || (uefi_call_wrapper(BS->CheckEvent, 1, timer_event) == EFI_SUCCESS);
        if (timer_fired) {
            lock_delay_ticks++;
            int on_floor = collision(current_piece, current_rot, current_x, current_y + 1);
            if (on_floor) {
                /*
                 * Manage lock countdown every heartbeat (not gated by gravity) so
                 * a landed piece locks promptly, and so a piece that slid off the
                 * floor cancels its countdown immediately.
                 */
                if (lock_countdown < 0) {
                    lock_countdown = LOCK_DELAY_TICKS;
                }
                if (lock_countdown == 0) {
                    lock_piece();
                } else {
                    lock_countdown--;
                }
            } else {
                lock_countdown = -1;
                if (++gravity_counter >= GRAVITY_PERIOD_TICKS) {
                    gravity_counter = 0;
                    current_y++;
                }
            }
        }

        render();
    }
}
