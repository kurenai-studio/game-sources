/**
 * @file render.h
 * @brief Framebuffer rendering primitives, GOP setup, and frame composition.
 */
#ifndef TETRIS_RENDER_H
#define TETRIS_RENDER_H

#include <efi.h>

/** @brief GOP horizontal resolution in pixels. */
extern UINTN screen_width;
/** @brief GOP vertical resolution in pixels. */
extern UINTN screen_height;
/**
 * @brief In-RAM back buffer (BGR0, packed `screen_width` stride).
 *
 * Allocated by @ref init_gop_highest_mode. All draw calls write here; @ref
 * present pushes the buffer to the display via a single GOP @c Blt.
 */
extern UINT32 *backbuffer;
/** @brief Block width in pixels (one tetromino cell). */
extern UINTN cell_w;
/** @brief Block height in pixels (one tetromino cell). */
extern UINTN cell_h;
/** @brief X coordinate of the playfield's top-left corner. */
extern UINTN board_origin_x;
/** @brief Y coordinate of the playfield's top-left corner. */
extern UINTN board_origin_y;

/**
 * @brief Fill an axis-aligned rectangle in the back buffer.
 *
 * Clipped to the screen bounds.
 *
 * @param x     Top-left X.
 * @param y     Top-left Y.
 * @param w     Width in pixels.
 * @param h     Height in pixels.
 * @param color BGR0 colour.
 */
void fill_rect(UINTN x, UINTN y, UINTN w, UINTN h, UINT32 color);

/**
 * @brief Push the back buffer to the GOP framebuffer in one Blt.
 *
 * Called once at the end of @ref render so each frame appears atomically.
 */
void present(void);

/**
 * @brief Draw one playfield cell.
 *
 * Coordinates are board cells, not pixels. The cell is drawn with a 1-pixel
 * inset so neighbouring cells visually separate.
 *
 * @param bx    Board column (0-based).
 * @param by    Board row (0-based; 0 = top).
 * @param color BGR0 colour.
 */
void draw_block(UINTN bx, UINTN by, UINT32 color);

/**
 * @brief Locate GOP, allocate the back buffer, compute layout metrics.
 *
 * Initialises @ref backbuffer, @ref screen_width, @ref screen_height,
 * @ref cell_w, @ref cell_h, @ref board_origin_x, @ref board_origin_y from
 * the firmware-current GOP mode.
 *
 * @param ImageHandle  EFI image handle (passed through from @c efi_main).
 * @param SystemTable  EFI system table (passed through from @c efi_main).
 * @return @c EFI_SUCCESS on success; an EFI error if GOP could not be found,
 *         set to a usable mode, or the back buffer could not be allocated.
 */
EFI_STATUS init_gop_highest_mode(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable);

/**
 * @brief Compose and present one frame.
 *
 * Reads game state from game.h globals and draws the entire frame: board,
 * ghost piece, current piece, hold/next previews, score, version/info,
 * controls hint, and the game-over overlay if applicable.
 */
void render(void);

#endif // TETRIS_RENDER_H
