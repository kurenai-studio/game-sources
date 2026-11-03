/**
 * @file font.h
 * @brief 5x5 bitmap font lookup and text rendering.
 *
 * Glyphs are 5 pixels wide by 5 pixels tall. Each row of a glyph is encoded in
 * the low 5 bits of one byte (MSB = leftmost column). Rendering is done via
 * @ref draw_text which lays out characters at @p scale screen pixels per font
 * pixel, with a 1-font-pixel inter-glyph gap.
 */
#ifndef TETRIS_FONT_H
#define TETRIS_FONT_H

#include <efi.h>

/**
 * @brief Look up the 5-byte glyph for an Ascii character.
 *
 * @param c Ascii character. Supports digits, uppercase letters used by the
 *          UI, a subset of lowercase letters used in the info row, and the
 *          symbols @c '.', @c ':', @c '-', @c '/', @c '(', and @c ')'.
 * @return Pointer to the static 5-byte row table, or @c NULL if the character
 *         has no glyph (e.g. space, unknown punctuation).
 */
const UINT8 *glyph_for(char c);

/**
 * @brief Render a single 5x5 glyph at scale.
 *
 * Each set bit is drawn as a @p scale x @p scale square via @ref fill_rect.
 *
 * @param x     Top-left X pixel of the glyph cell.
 * @param y     Top-left Y pixel of the glyph cell.
 * @param scale Screen pixels per font pixel (1 = native 5x5).
 * @param rows  Five-byte glyph table (typically from @ref glyph_for).
 * @param color BGR0 colour to draw the set pixels in.
 */
void draw_char_5x5(UINTN x, UINTN y, UINTN scale, const UINT8 rows[5], UINT32 color);

/**
 * @brief Render an Ascii string left-to-right.
 *
 * Characters not in the font advance the cursor without drawing (acts like a
 * blank cell). Layout uses a 1-font-pixel gap between glyphs.
 *
 * @param x     Top-left X pixel where drawing begins.
 * @param y     Top-left Y pixel where drawing begins.
 * @param scale Screen pixels per font pixel.
 * @param s     Null-terminated Ascii string.
 * @param color BGR0 colour to draw glyphs in.
 */
void draw_text(UINTN x, UINTN y, UINTN scale, const char *s, UINT32 color);

/**
 * @brief Compute the rendered width in pixels of a string at @p scale.
 *
 * Includes inter-glyph gaps but excludes the trailing gap after the last
 * character.
 *
 * @param s     Null-terminated Ascii string.
 * @param scale Screen pixels per font pixel.
 * @return Width in screen pixels, or 0 for an empty string.
 */
UINTN text_width(const char *s, UINTN scale);

#endif // TETRIS_FONT_H
