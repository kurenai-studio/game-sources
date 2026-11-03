/**
 * @file game.h
 * @brief Game state and pure-logic state mutators.
 *
 * State globals are exposed as @c extern so unit tests can inspect or mutate
 * them. Functions in this header do not call any UEFI services; the event
 * loop driver lives in loop.h.
 */
#ifndef TETRIS_GAME_H
#define TETRIS_GAME_H

#include <efi.h>

#include "piece.h"

/** @brief Heartbeat timer period in 100 ns units (50 ms). */
#define TIMER_PERIOD_100NS 500000
/** @brief Number of heartbeats per gravity step (~200 ms). */
#define GRAVITY_PERIOD_TICKS 4
/** @brief Number of heartbeats to lock a landed piece (~200 ms). */
#define LOCK_DELAY_TICKS 4

/** @brief Currently falling piece type (one of the @c PIECE_* constants). */
extern int current_piece;
/** @brief Rotation of the currently falling piece. */
extern int current_rot;
/** @brief X column of the falling piece's 4x4 origin. */
extern int current_x;
/** @brief Y row of the falling piece's 4x4 origin. */
extern int current_y;
/** @brief The next piece to spawn (preview). */
extern int next_piece;
/** @brief Held piece type, or -1 if no piece is held. */
extern int hold_piece;
/** @brief 1 if hold has already been used since the last lock; 0 otherwise. */
extern int hold_used;
/** @brief Cumulative score for the current game. */
extern UINTN score;
/** @brief Set to 1 when a new piece can no longer spawn. */
extern int game_over;
/** @brief Heartbeat counter (mainly diagnostic). */
extern UINTN lock_delay_ticks;
/** @brief Remaining ticks before the landed piece locks; -1 = inactive. */
extern int lock_countdown;
/** @brief Heartbeat counter for gravity (resets at @ref GRAVITY_PERIOD_TICKS). */
extern int gravity_counter;

/**
 * @brief Advance the linear-congruential RNG and return the next piece type.
 *
 * @return Index in [0, @ref NUM_PIECES - 1].
 */
int next_random_piece(void);

/**
 * @brief Commit the current piece into the board, clear full lines, spawn the
 *        next piece, and update score / game-over state.
 */
void lock_piece(void);

/**
 * @brief Advance @ref next_piece into @ref current_piece and roll a new
 *        @ref next_piece.
 *
 * Also marks @ref game_over if the new piece collides at spawn position.
 */
void spawn_next(void);

/**
 * @brief Apply the hold action.
 *
 * If a piece is already held, swap it with the current piece. Otherwise stash
 * the current piece into hold and bring out the next. Idempotent within a
 * single drop: subsequent calls before the next lock are no-ops.
 */
void do_hold(void);

/**
 * @brief Reset the playfield, scores, hold/next state, and rebuild the
 *        starting piece.
 */
void game_reset(void);

#endif // TETRIS_GAME_H
