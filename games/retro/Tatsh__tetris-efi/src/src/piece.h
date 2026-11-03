/**
 * @file piece.h
 * @brief Tetromino tables, playfield buffer, and collision testing.
 */
#ifndef TETRIS_PIECE_H
#define TETRIS_PIECE_H

#include <efi.h>

/** @brief Playfield width in cells. */
#define BOARD_WIDTH 10
/** @brief Playfield height in cells (logical and visible; no buffer rows). */
#define BOARD_HEIGHT 20
/** @brief Number of rows rendered on screen. Equal to @ref BOARD_HEIGHT. */
#define VISIBLE_ROWS BOARD_HEIGHT
/** @brief Number of distinct tetromino shapes (I, O, T, S, Z, J, L). */
#define NUM_PIECES 7
/** @brief Number of orientations per tetromino. */
#define NUM_ROTATIONS 4

/**
 * @brief Tetromino type indices used as the first dimension of @ref SHAPES and
 *        as the (offset-by-one) index into @ref TETRIS_COLORS.
 */
enum { PIECE_I, PIECE_O, PIECE_T, PIECE_S, PIECE_Z, PIECE_J, PIECE_L };

/**
 * @brief BGR0 colour palette for the seven tetrominoes plus an empty cell.
 *
 * Index 0 is black (empty cell). Indices 1-7 correspond to @ref PIECE_I
 * through @ref PIECE_L respectively (so @c TETRIS_COLORS[piece + 1]).
 */
extern const UINT32 TETRIS_COLORS[8];

/**
 * @brief Tetromino shape table indexed by [piece][rotation][row][column].
 *
 * Each rotation is a 4x4 grid where 1 marks a filled cell. See piece.c for the
 * specific orientations (Super Rotation System layout).
 */
extern const UINT8 SHAPES[NUM_PIECES][NUM_ROTATIONS][4][4];

/**
 * @brief Playfield matrix. Row 0 is the top, row @ref BOARD_HEIGHT - 1 the
 *        bottom. A value of 0 is an empty cell; values 1-7 are
 *        @c piece_type + 1.
 */
extern UINT8 board[BOARD_HEIGHT][BOARD_WIDTH];

/**
 * @brief Test whether a piece at the given position would collide.
 *
 * A collision occurs when any filled cell of the piece overlaps a wall, the
 * floor, or an already-filled board cell. Cells with @c by < 0 (above the
 * board) are not considered collisions.
 *
 * @param piece Piece type (one of the @c PIECE_* constants).
 * @param rot   Rotation index in [0, @ref NUM_ROTATIONS - 1].
 * @param px    Piece origin X in board cells.
 * @param py    Piece origin Y in board cells.
 * @return Non-zero on collision, zero if the piece fits.
 */
int collision(int piece, int rot, int px, int py);

#endif // TETRIS_PIECE_H
