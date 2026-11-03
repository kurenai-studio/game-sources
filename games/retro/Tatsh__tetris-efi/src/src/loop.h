/**
 * @file loop.h
 * @brief Main game loop driving timer, input, and rendering.
 */
#ifndef TETRIS_LOOP_H
#define TETRIS_LOOP_H

#include <efi.h>

/**
 * @brief Run the Tetris game loop until the player quits.
 *
 * Creates a periodic UEFI timer, processes keystrokes, advances gravity and
 * lock-delay state, and re-renders each frame. Returns when the player chooses
 * to quit from the game-over screen, or on a fatal UEFI service failure.
 *
 * @return @c EFI_SUCCESS on a clean quit; an EFI error status if a UEFI
 *         service call (e.g. @c CreateEvent) failed during set-up.
 */
EFI_STATUS run_game(void);

#endif // TETRIS_LOOP_H
